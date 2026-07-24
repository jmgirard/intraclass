# data-raw/m88-mpl-kappa-table.R
#
# M88 T3: generate the precomputed kappa_m table shipped as internal package data
# (R/sysdata.rda) behind ci_method = "mpl". kappa_m is the modified-profile-likelihood
# correction constant (xiao2013) that makes the two-way random ICC(A,1) interval cover
# at nominal; it is per-(R, S) geometry and has NO external oracle below rho = 0.6
# (D-014 condition (i)) -- established by simulated coverage only, using M86's
# validated calibration machinery (data-raw/m86-mpl-lib.R).
#
# Method (M87 T2's exact procedure, data-raw/m87-mpl-kappa-recalibration.R, applied
# per geometry over a full grid):
#   kappa_m(R, S) = max{ kappa_corr(rho, delta) : rho in [0.05,0.9], delta in 2^(-1:4) }
# at alpha = 0.05, two-sided (the package default conf_level for mpl).
#   1. Scan the (rho, delta) grid at n_mc_scan to LOCATE the maximum.
#   2. Re-evaluate kappa_corr at the TOP-3 scan cells at the larger n_mc_final and take
#      their max. The MC grid-MAX over all 60 cells is upward-biased (max of 60 noisy
#      estimates, M86 winner's-curse lesson); re-evaluating only the top-3 candidates
#      removes that bias while staying robust to scan noise in the argmax LOCATION --
#      which genuinely varies with geometry (a coarse probe found the argmax at the
#      (0.05,16) corner for R in {3,5} but elsewhere for R = 2 and R = 10, so the
#      corner is NOT assumable and the location must be found, not fixed).
#
# Cross-check (built-in oracle): the four geometries this grid shares with M87's
# committed recalibration -- (3,10),(3,20),(3,50),(5,20) -- reproduce
# data-raw/m87-kappa-recalibration.rds within MC tolerance.
#
# Run (background; ~2-2.5 h):
#   Rscript data-raw/m88-mpl-kappa-table.R
# Writes data-raw/m88-kappa-table.rds (seeded; provenance in `meta`) and R/sysdata.rda
# via usethis::use_data(kappa_m_table, internal = TRUE, overwrite = TRUE).

source("data-raw/m86-mpl-lib.R")

seed <- 20260723L
alpha_pass <- 0.05 # 95% two-sided (the package default conf_level for mpl)
n_mc_scan <- 1500L # locate the argmax (matches M87 T2)
n_mc_final <- 6000L # bias-corrected re-evaluation at the top candidates (matches M87)
top_k <- 3L # re-evaluate the top-k scan cells; kappa_m = max of them

# The shipped grid. R = every integer 2..10 (a user's rater count is ON a node -- only
# S is interpolated, T4); S spans small-to-large reliability studies (dense where
# kappa_m changes fastest).
r_grid <- 2:10
s_grid <- c(10L, 15L, 20L, 30L, 50L, 100L)

# The (rho, delta) calibration grid: extended rho spans the near-zero boundary the
# published kappa_m never saw; delta_j = 2^j, j = -1..4 -> {0.5,1,2,4,8,16} (xiao2013).
rho_grid <- c(0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
delta_grid <- 2^(-1:4)

kappa_m_one <- function(n_r, n_s, seed_g) {
  set.seed(seed_g)
  grid <- expand.grid(rho = rho_grid, delta = delta_grid)
  grid$kc_scan <- mapply(
    function(rho, delta) {
      mpl_kappa_corr(
        rho,
        delta,
        n_r,
        n_s,
        alpha = alpha_pass,
        side = "two",
        n_mc = n_mc_scan
      )
    },
    grid$rho,
    grid$delta
  )
  top <- grid[order(grid$kc_scan, decreasing = TRUE)[seq_len(top_k)], ]
  set.seed(seed_g + 1L)
  top$kc_final <- mapply(
    function(rho, delta) {
      mpl_kappa_corr(
        rho,
        delta,
        n_r,
        n_s,
        alpha = alpha_pass,
        side = "two",
        n_mc = n_mc_final
      )
    },
    top$rho,
    top$delta
  )
  best <- top[which.max(top$kc_final), ]
  list(
    n_r = n_r,
    n_s = n_s,
    kappa_m = best$kc_final,
    argmax = c(rho = best$rho, delta = best$delta),
    top = top[, c("rho", "delta", "kc_scan", "kc_final")]
  )
}

cat(sprintf(
  "== M88 T3: kappa_m over rho in [%.2f,%.2f] x delta {%s}, alpha=%.2f two-sided ==\n",
  min(rho_grid),
  max(rho_grid),
  paste(delta_grid, collapse = ","),
  alpha_pass
))
nodes <- expand.grid(n_r = r_grid, n_s = s_grid)
nodes <- nodes[order(nodes$n_r, nodes$n_s), ]
nodes$kappa_m <- NA_real_
nodes$argmax_rho <- NA_real_
nodes$argmax_delta <- NA_real_
details <- list()
for (i in seq_len(nrow(nodes))) {
  res <- kappa_m_one(nodes$n_r[i], nodes$n_s[i], seed_g = seed + 17L * i)
  nodes$kappa_m[i] <- res$kappa_m
  nodes$argmax_rho[i] <- res$argmax[["rho"]]
  nodes$argmax_delta[i] <- res$argmax[["delta"]]
  details[[sprintf("%d-%d", res$n_r, res$n_s)]] <- res$top
  saveRDS(
    list(nodes = nodes, details = details, done = i, of = nrow(nodes)),
    "data-raw/m88-kappa-table.rds"
  ) # incremental checkpoint
  cat(sprintf(
    "  (R=%2d,S=%3d): kappa_m = %.3f at argmax (rho=%.2f, delta=%g)  [%d/%d]\n",
    res$n_r,
    res$n_s,
    res$kappa_m,
    res$argmax[["rho"]],
    res$argmax[["delta"]],
    i,
    nrow(nodes)
  ))
}

# --- Cross-check against M87's committed recalibration ----------------------
cat(
  "\n== Cross-check: shared geometries vs M87 committed kappa_m (tol 0.15) ==\n"
)
m87 <- readRDS("data-raw/m87-kappa-recalibration.rds")$results
tol_x <- 0.15 # two independent MC pipelines (top-3-max here vs single-argmax at M87)
xcheck <- list()
for (key in intersect(names(m87), sprintf("%d-%d", nodes$n_r, nodes$n_s))) {
  gg <- as.integer(strsplit(key, "-", fixed = TRUE)[[1]])
  ours <- nodes$kappa_m[nodes$n_r == gg[1] & nodes$n_s == gg[2]]
  theirs <- m87[[key]]$kappa_m
  pass <- abs(ours - theirs) <= tol_x
  xcheck[[key]] <- list(ours = ours, m87 = theirs, pass = pass)
  cat(sprintf(
    "  %s: ours %.3f  M87 %.3f  |diff| %.3f  %s\n",
    key,
    ours,
    theirs,
    abs(ours - theirs),
    if (pass) "PASS" else "FAIL"
  ))
}
xcheck_all_pass <- length(xcheck) > 0 &&
  all(vapply(xcheck, function(x) x$pass, logical(1)))

# --- Commit the table + provenance ------------------------------------------
kappa_m_table <- nodes[, c("n_r", "n_s", "kappa_m")]
rownames(kappa_m_table) <- NULL

validation <- list(
  kappa_m_table = kappa_m_table,
  nodes = nodes,
  details = details,
  xcheck = xcheck,
  xcheck_all_pass = xcheck_all_pass,
  meta = list(
    source = "xiao2013 kappa_m recalibrated over extended rho, via data-raw/m86-mpl-lib.R",
    generator = "data-raw/m88-mpl-kappa-table.R",
    alpha_pass = alpha_pass,
    rho_grid = rho_grid,
    delta_grid = delta_grid,
    r_grid = r_grid,
    s_grid = s_grid,
    n_mc_scan = n_mc_scan,
    n_mc_final = n_mc_final,
    top_k = top_k,
    seed = seed,
    date = "2026-07-23"
  )
)
saveRDS(validation, "data-raw/m88-kappa-table.rds")
usethis::use_data(kappa_m_table, internal = TRUE, overwrite = TRUE)

cat(sprintf(
  "\nM87 cross-check: %s\nsaved data-raw/m88-kappa-table.rds + R/sysdata.rda\n",
  if (xcheck_all_pass) "ALL PASS" else "SOME FAIL"
))
