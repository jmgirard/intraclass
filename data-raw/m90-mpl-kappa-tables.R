# data-raw/m90-mpl-kappa-tables.R
#
# M90 T2 (RR03/D-017): generate kappa_m tables at conf_level 0.90 (alpha = 0.10)
# and 0.99 (alpha = 0.01) for ci_method = "mpl", extending the shipped 0.95 table
# (data-raw/m88-mpl-kappa-table.R). Same from-scratch machinery (m86-mpl-lib.R),
# same scan -> top-k bias-corrected grid-max, parametrized by alpha per level. This
# script writes FIXTURES ONLY (data-raw/m90-kappa-tables.rds); wiring into
# R/sysdata.rda is M91's job (this milestone ships no exported code).
#
# Binding criteria enforced here (verbatim in cairn/milestones/M90-...md):
#   BC1  Before any alpha=0.01 production run, the alpha-parametrized pipeline at
#        alpha=0.10 over rho in [0.6,0.9] x delta=2^(-1..4), n_mc >= 6000,
#        reproduces the six PUBLISHED two-sided kappa_m -- 0.32/0.52/0.67 at
#        (3,10/25/50) and 0.13/0.23/0.33 at (5,10/25/50) -- each within +-0.10.
#        S=25 is off the shipped s_grid and is evaluated explicitly.
#   BC2  alpha=0.01 generator uses n_mc_scan >= 3000, top_k >= 5, n_mc_final >=
#        12000; records a bootstrap SE of the final kappa_hat_m for one geometry
#        per R in {2,3,10}, each <= 0.05. (alpha=0.10 keeps M88 sizes 1500/3/6000.)
#
# Run (background; ~7-8 h total -- alpha=0.10 ~2.5 h at M88 sizes, alpha=0.01
# ~5 h at 2.2x the fits):
#   Rscript data-raw/m90-mpl-kappa-tables.R
# Smoke run (fast, correctness only -- shrinks grids + n_mc, still exercises BC1/BC2
# logic and the kappa_corr_draws == mpl_kappa_corr equivalence assertion):
#   M90_SMOKE=1 Rscript data-raw/m90-mpl-kappa-tables.R
# Writes data-raw/m90-kappa-tables.rds (seeded; provenance + BC1/BC2 status in meta),
# incrementally checkpointed.

source("data-raw/m86-mpl-lib.R")

smoke <- Sys.getenv("M90_SMOKE") == "1"
seed <- 20260724L

# --- kappa_corr returning the stat draws (for the BC2 bootstrap SE) -----------
# Byte-identical formula to mpl_kappa_corr() in m86-mpl-lib.R, but also returns the
# stat vector so the argmax cell's kappa_m SE can be bootstrapped without re-running
# the MC (BC2). A smoke assertion below verifies kappa == mpl_kappa_corr() at a
# shared seed, so this stays a faithful mirror of the oracle-validated function.
kappa_corr_draws <- function(rho, delta, n_r, n_s, alpha, side = "two", n_mc) {
  chi <- if (side == "two") qchisq(1 - alpha, 1) else qchisq(1 - 2 * alpha, 1)
  stat <- numeric(n_mc)
  for (i in seq_len(n_mc)) {
    ms <- mpl_anova(mpl_simulate(rho, delta, n_r, n_s))
    fit <- mpl_fit(ms)
    d <- mpl_deviance(rho, ms, neg2l_min = fit$neg2l_min)
    stat[i] <- if (side == "two") {
      d
    } else {
      sign(fit$rho_hat - rho) * sqrt(max(d, 0))
    }
  }
  qhat <- stats::quantile(stat, probs = 1 - alpha, names = FALSE)
  scaled <- if (side == "two") qhat else qhat^2
  list(kappa = as.numeric(scaled / chi - 1), stat = stat)
}

# Bootstrap SE of kappa_hat_m: resample the argmax cell's deviance draws (BC2).
boot_se_kappa <- function(stat, alpha, side = "two", b = 500L, seed_b = 1L) {
  chi <- if (side == "two") qchisq(1 - alpha, 1) else qchisq(1 - 2 * alpha, 1)
  set.seed(seed_b)
  ks <- replicate(b, {
    s <- sample(stat, replace = TRUE)
    q <- stats::quantile(s, probs = 1 - alpha, names = FALSE)
    (if (side == "two") q else q^2) / chi - 1
  })
  stats::sd(ks)
}

# Grid-max kappa_m at one (R,S), parametrized by alpha + MC sizes (mirrors
# m88's kappa_m_one; final step uses kappa_corr_draws to retain the sample).
kappa_m_one <- function(
  n_r,
  n_s,
  alpha,
  n_mc_scan,
  top_k,
  n_mc_final,
  rho_grid,
  delta_grid,
  seed_g,
  want_se = FALSE
) {
  set.seed(seed_g)
  grid <- expand.grid(rho = rho_grid, delta = delta_grid)
  grid$kc_scan <- mapply(
    function(rho, delta) {
      mpl_kappa_corr(rho, delta, n_r, n_s, alpha = alpha, side = "two", n_mc = n_mc_scan)
    },
    grid$rho,
    grid$delta
  )
  top <- grid[order(grid$kc_scan, decreasing = TRUE)[seq_len(top_k)], ]
  set.seed(seed_g + 1L)
  fin <- lapply(seq_len(nrow(top)), function(j) {
    kappa_corr_draws(top$rho[j], top$delta[j], n_r, n_s, alpha = alpha, n_mc = n_mc_final)
  })
  top$kc_final <- vapply(fin, function(x) x$kappa, numeric(1))
  bi <- which.max(top$kc_final)
  se <- if (want_se) {
    boot_se_kappa(fin[[bi]]$stat, alpha, seed_b = seed_g + 2L)
  } else {
    NA_real_
  }
  list(
    n_r = n_r,
    n_s = n_s,
    kappa_m = top$kc_final[bi],
    argmax = c(rho = top$rho[bi], delta = top$delta[bi]),
    se_boot = se,
    top = top[, c("rho", "delta", "kc_scan", "kc_final")]
  )
}

# --- Level definitions --------------------------------------------------------
delta_grid <- 2^(-1:4)
rho_grid_prod <- c(0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
r_grid <- 2:10
s_grid <- c(10L, 15L, 20L, 30L, 50L, 100L)
# One representative geometry per R in {2,3,10} carries a BC2 bootstrap SE.
se_nodes <- list(c(2L, 10L), c(3L, 50L), c(10L, 20L))

levels <- list(
  list(name = "0.90", conf = 0.90, alpha = 0.10, scan = 1500L, top_k = 3L, final = 6000L),
  list(name = "0.99", conf = 0.99, alpha = 0.01, scan = 3000L, top_k = 5L, final = 12000L)
)

if (smoke) {
  rho_grid_prod <- c(0.05, 0.30, 0.60)
  delta_grid <- c(1, 16)
  r_grid <- c(2L, 3L)
  s_grid <- c(10L, 50L)
  se_nodes <- list(c(2L, 10L), c(3L, 50L))
  for (i in seq_along(levels)) {
    levels[[i]]$scan <- 60L
    levels[[i]]$final <- 120L
    levels[[i]]$top_k <- 2L
  }
}

out_path <- "data-raw/m90-kappa-tables.rds"

# --- Smoke equivalence assertion: kappa_corr_draws == mpl_kappa_corr ----------
set.seed(999L)
a <- mpl_kappa_corr(0.6, 16, 3, 50, alpha = 0.10, side = "two", n_mc = if (smoke) 200L else 2000L)
set.seed(999L)
b <- kappa_corr_draws(0.6, 16, 3, 50, alpha = 0.10, n_mc = if (smoke) 200L else 2000L)$kappa
stopifnot(isTRUE(all.equal(a, b)))
cat(sprintf("equivalence check kappa_corr_draws == mpl_kappa_corr: OK (%.5f)\n", b))

# --- BC1 precondition: reproduce xiao2013's published alpha=0.10 kappa_m ------
cat("\n== BC1: reproduce published two-sided kappa_m at alpha=0.10 (rho in [0.6,0.9]) ==\n")
published <- data.frame(
  n_r = c(3L, 3L, 3L, 5L, 5L, 5L),
  n_s = c(10L, 25L, 50L, 10L, 25L, 50L),
  kappa_pub = c(0.32, 0.52, 0.67, 0.13, 0.23, 0.33)
)
rho_pub <- c(0.6, 0.7, 0.8, 0.9)
bc1_nmc <- if (smoke) 400L else 6000L
bc1_topk <- if (smoke) 2L else 5L
published$kappa_hat <- NA_real_
for (i in seq_len(nrow(published))) {
  res <- kappa_m_one(
    published$n_r[i], published$n_s[i],
    alpha = 0.10, n_mc_scan = bc1_nmc, top_k = bc1_topk, n_mc_final = bc1_nmc,
    rho_grid = rho_pub, delta_grid = delta_grid, seed_g = seed + 101L * i
  )
  published$kappa_hat[i] <- res$kappa_m
  cat(sprintf(
    "  (R=%d,S=%2d): kappa_hat %.3f  published %.2f  |diff| %.3f  %s\n",
    published$n_r[i], published$n_s[i], res$kappa_m, published$kappa_pub[i],
    abs(res$kappa_m - published$kappa_pub[i]),
    if (abs(res$kappa_m - published$kappa_pub[i]) <= 0.10) "PASS" else "FAIL"
  ))
}
published$pass <- abs(published$kappa_hat - published$kappa_pub) <= 0.10
bc1_pass <- all(published$pass)
cat(sprintf("BC1: %s (%d/%d within +-0.10)\n", if (bc1_pass) "PASS" else "FAIL",
  sum(published$pass), nrow(published)))
if (!bc1_pass && !smoke) {
  stop("BC1 precondition FAILED -- not proceeding to alpha=0.01 production (RR03/BC1).")
}

# --- Production tables per level ----------------------------------------------
nodes_all <- expand.grid(n_r = r_grid, n_s = s_grid)
nodes_all <- nodes_all[order(nodes_all$n_r, nodes_all$n_s), ]
is_se_node <- function(r, s) any(vapply(se_nodes, function(z) z[1] == r && z[2] == s, logical(1)))

tables <- list()
details <- list()
for (lv in levels) {
  cat(sprintf("\n== production: conf_level %s (alpha=%.2f), scan=%d top_k=%d final=%d ==\n",
    lv$name, lv$alpha, lv$scan, lv$top_k, lv$final))
  nd <- nodes_all
  nd$kappa_m <- NA_real_
  nd$argmax_rho <- NA_real_
  nd$argmax_delta <- NA_real_
  nd$se_boot <- NA_real_
  for (i in seq_len(nrow(nd))) {
    want_se <- is_se_node(nd$n_r[i], nd$n_s[i])
    res <- kappa_m_one(
      nd$n_r[i], nd$n_s[i],
      alpha = lv$alpha, n_mc_scan = lv$scan, top_k = lv$top_k, n_mc_final = lv$final,
      rho_grid = rho_grid_prod, delta_grid = delta_grid,
      seed_g = seed + 17L * i + 1000L * match(lv$name, vapply(levels, function(x) x$name, "")),
      want_se = want_se
    )
    nd$kappa_m[i] <- res$kappa_m
    nd$argmax_rho[i] <- res$argmax[["rho"]]
    nd$argmax_delta[i] <- res$argmax[["delta"]]
    nd$se_boot[i] <- res$se_boot
    details[[sprintf("%s:%d-%d", lv$name, nd$n_r[i], nd$n_s[i])]] <- res$top
    cat(sprintf("  (R=%2d,S=%3d): kappa_m %.3f at (rho=%.2f,delta=%g)%s  [%d/%d]\n",
      nd$n_r[i], nd$n_s[i], res$kappa_m, res$argmax_rho[i], res$argmax_delta[i],
      if (want_se) sprintf(" SE=%.3f", res$se_boot) else "", i, nrow(nd)))
    tables[[lv$name]] <- nd
    saveRDS(list(tables = tables, details = details, published = published,
      done = list(level = lv$name, i = i, of = nrow(nd))), out_path)
  }
}

# --- BC2 SE gate --------------------------------------------------------------
cat("\n== BC2: bootstrap SE of final kappa_hat_m at one geometry per R in {2,3,10} ==\n")
se99 <- tables[["0.99"]]
se99 <- se99[!is.na(se99$se_boot), c("n_r", "n_s", "kappa_m", "se_boot")]
for (i in seq_len(nrow(se99))) {
  cat(sprintf("  (R=%2d,S=%3d): kappa_m %.3f  SE %.4f  %s\n",
    se99$n_r[i], se99$n_s[i], se99$kappa_m[i], se99$se_boot[i],
    if (se99$se_boot[i] <= 0.05) "PASS" else "FAIL"))
}
bc2_pass <- all(se99$se_boot <= 0.05)
cat(sprintf("BC2: %s\n", if (bc2_pass) "PASS" else "FAIL (increase n_mc_final)"))

# --- Commit fixtures (NO sysdata.rda -- that is M91) --------------------------
saveRDS(
  list(
    tables = tables,
    details = details,
    published = published,
    bc1_pass = bc1_pass,
    bc2 = se99,
    bc2_pass = bc2_pass,
    meta = list(
      generator = "data-raw/m90-mpl-kappa-tables.R",
      source = "xiao2013 kappa_m recalibrated per alpha via data-raw/m86-mpl-lib.R (RR03/D-017)",
      levels = lapply(levels, function(x) x[c("name", "conf", "alpha", "scan", "top_k", "final")]),
      rho_grid = rho_grid_prod, delta_grid = delta_grid,
      r_grid = r_grid, s_grid = s_grid, se_nodes = se_nodes,
      seed = seed, smoke = smoke, date = "2026-07-24"
    )
  ),
  out_path
)
cat(sprintf("\nsaved %s  (BC1 %s, BC2 %s%s)\n", out_path,
  if (bc1_pass) "PASS" else "FAIL", if (bc2_pass) "PASS" else "FAIL",
  if (smoke) "; SMOKE run -- not production fixtures" else ""))
