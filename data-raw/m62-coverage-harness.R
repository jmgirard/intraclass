# M62 T4 — coverage/width harness: non-parametric bootstrap vs the package
# incumbents (MC default + parametric bootstrap) on the one-way random ICC.
#
# NON-EXPORTED research script (data-raw/). Deterministic (per-rep seeding).
# Writes an incremental results fixture so a crash never loses completed cells.
# Heavy: the parametric-bootstrap incumbent is ~3.8 s/dataset (B=199) — run in
# the background. Read by the synthesis note (T5): npbootstrap-oneway-comparison.md.
#
# Params (right-sized 2026-07-17; see the synthesis note pre-registration + the
# prospective n_rep amendment): n_rep=1000 (coverage SE ≈ 0.7 pp), incumbent
# parametric-bootstrap B=199, prototype B=2000. All methods share the SAME
# simulated datasets per cell (paired). Estimand: ICC(1) = ρ.

suppressMessages(devtools::load_all(quiet = TRUE))
source("data-raw/m62-npbootstrap-prototype.R")

CONF <- 0.95
N_REP <- as.integer(Sys.getenv("M62_NREP", "1000"))
B_PROTO <- as.integer(Sys.getenv("M62_BPROTO", "2000"))
B_BOOT <- 199L
SMOKE <- nzchar(Sys.getenv("M62_SMOKE")) # first comparison + first oracle cell only
OUT <- if (SMOKE) {
  "data-raw/m62-coverage-smoke.rds"
} else {
  "data-raw/m62-coverage-results.rds"
}

comparison_cells <- list(
  C1 = list(k = 30, n = 4, rho = 0.50),
  C2 = list(k = 30, n = 4, rho = 0.05),
  C3 = list(k = 12, n = 4, rho = 0.50),
  C4 = list(k = 12, n = 4, rho = 0.05)
)
# Oracle-check cells (prototype only) — reproduce ukoumunne2003 Fig. 2 at n=10.
oracle_cells <- list(
  U10 = list(k = 10, n = 10, rho = 0.05),
  U30 = list(k = 30, n = 10, rho = 0.05),
  U50 = list(k = 50, n = 10, rho = 0.05)
)

# ICC(1) endpoints from an icc() call; NA triple on any abort/failure.
icc_ci <- function(d, method, boot = NULL) {
  out <- tryCatch(
    {
      args <- list(
        d,
        quote(y),
        quote(subject),
        quote(rater),
        model = "oneway",
        ci_method = method,
        seed = 1L
      )
      if (!is.null(boot)) {
        args$boot_samples <- boot
      }
      td <- suppressWarnings(tidy(do.call(icc, args)))
      row <- td[td$index == "ICC(1)", ]
      c(row$conf.low, row$conf.high)
    },
    error = function(e) c(NA_real_, NA_real_)
  )
  out
}

covered <- function(ci, truth) {
  if (anyNA(ci)) {
    return(NA)
  }
  ci[1] <= truth && truth <= ci[2]
}
width <- function(ci) if (anyNA(ci)) NA_real_ else ci[2] - ci[1]

run_cell <- function(name, cell, incumbents) {
  k <- cell$k
  n <- cell$n
  rho <- cell$rho
  seed_base <- 10000L * utf8ToInt(substr(name, 1, 1))[1] + k + n
  methods <- if (incumbents) {
    c("mc", "pboot", "perc", "boott", "bca")
  } else {
    c("perc", "boott", "bca")
  }
  cov <- matrix(NA, N_REP, length(methods), dimnames = list(NULL, methods))
  wid <- matrix(
    NA_real_,
    N_REP,
    length(methods),
    dimnames = list(NULL, methods)
  )
  t0 <- Sys.time()
  for (r in seq_len(N_REP)) {
    seed <- seed_base + r
    d <- sim_oneway(k, n, rho, seed = seed)
    p <- npboot_oneway(d, B = B_PROTO, seed = seed * 7L + 1L)
    for (v in c("perc", "boott", "bca")) {
      ci <- switch(
        v,
        perc = p$percentile,
        boott = p$boott_transformed,
        bca = p$bca
      )
      cov[r, v] <- covered(ci, rho)
      wid[r, v] <- width(ci)
    }
    if (incumbents) {
      mc <- icc_ci(d, "montecarlo")
      pb <- icc_ci(d, "bootstrap", boot = B_BOOT)
      cov[r, "mc"] <- covered(mc, rho)
      wid[r, "mc"] <- width(mc)
      cov[r, "pboot"] <- covered(pb, rho)
      wid[r, "pboot"] <- width(pb)
    }
    if (r %% 100L == 0L) {
      cat(sprintf(
        "  [%s] %d/%d  (%.1f min elapsed)\n",
        name,
        r,
        N_REP,
        as.numeric(Sys.time() - t0, units = "mins")
      ))
    }
  }
  list(
    cell = cell,
    name = name,
    methods = methods,
    coverage = colMeans(cov, na.rm = TRUE),
    n_ok = colSums(!is.na(cov)),
    median_width = apply(wid, 2, stats::median, na.rm = TRUE)
  )
}

if (SMOKE) {
  comparison_cells <- comparison_cells[1]
  oracle_cells <- oracle_cells[1]
}

results <- list()
for (nm in names(comparison_cells)) {
  cat(sprintf("== comparison cell %s ==\n", nm))
  results[[nm]] <- run_cell(nm, comparison_cells[[nm]], incumbents = TRUE)
  saveRDS(results, OUT) # incremental checkpoint
}
for (nm in names(oracle_cells)) {
  cat(sprintf("== oracle-check cell %s ==\n", nm))
  results[[nm]] <- run_cell(nm, oracle_cells[[nm]], incumbents = FALSE)
  saveRDS(results, OUT)
}
cat("DONE — wrote", OUT, "\n")
