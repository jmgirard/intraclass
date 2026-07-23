# M84 T5 — coverage validation sweep for the UNBALANCED one-way `npbootstrap`
# ICC(1) reducer.
#
# NON-EXPORTED research script (data-raw/). Runs the SHIPPED reducer
# (`npbootstrap_ci`, R/ci-npbootstrap.R) on unbalanced one-way data (a balanced
# k x n design with MCAR 0.1 deletion, matching ohyama2025's unbalanced design)
# over cells read from ohyama2025 Fig. 2 (NBOOT panel), at n_rep >= 2000, and writes
# `tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds`. The test
# `test-ci-npbootstrap-unbalanced-coverage.R` asserts the committed fixture against
# the Fig. 2 plot-read anchors within +-0.02 (AC4) and the GP6 few-clusters dip.
#
# Coverage only -- the interval needs no engine fit, so no glmmTMB refits (the REML
# point is not swept here; that is M75's BC6, balanced-only). Deterministic per-rep
# seeding. Heavy (~n_rep x cells x B ANOVA resamples). Run in the background:
#   M84_NREP=2000 Rscript data-raw/m84-npbootstrap-unbalanced-coverage.R
#
# ohyama2025 Fig. 2 NBOOT plot-read (unbalanced, MCAR 0.1, rho ~ 0.5, coverage circle):
#   (k=10, n=2) ~ 0.945   (k=25, n=5) ~ 0.935   (k=50, n=5) ~ 0.945  [near-nominal]
#   (k=10, n=10) ~ 0.90   [the few-clusters / many-raters dip the paper names, p.595]

suppressMessages(devtools::load_all(quiet = TRUE))

n_rep <- as.integer(Sys.getenv("M84_NREP", "2000"))
b_boot <- as.integer(Sys.getenv("M84_B", "999"))
conf <- 0.95
p_miss <- 0.10

# Balanced one-way DGP (sigma_a^2 + sigma_e^2 = 1 so ICC(1) = rho), then MCAR
# deletion w.p. p_miss. Returns a long data.frame, or NULL if the deleted design is
# degenerate (a subject wiped out to < 1 obs leaving < 3 subjects, or < 2 df within).
sim_unbalanced <- function(k, n, rho, seed) {
  set.seed(seed)
  a <- stats::rnorm(k, 0, sqrt(rho))
  subj <- rep(seq_len(k), each = n)
  score <- a[subj] + stats::rnorm(k * n, 0, sqrt(1 - rho))
  keep <- stats::runif(k * n) >= p_miss
  if (!any(keep)) {
    return(NULL)
  }
  subj <- subj[keep]
  score <- score[keep]
  tab <- table(subj)
  # Keep only subjects still present; require >= 3 subjects and within-df >= 2.
  present <- as.integer(names(tab))
  if (length(present) < 3L || (length(subj) - length(present)) < 2L) {
    return(NULL)
  }
  data.frame(
    subject = factor(subj, levels = present),
    score = score
  )
}

est_single <- list(icc_estimand(
  unit = "single",
  k_eff = NA_real_,
  oneway = TRUE
))

cells <- list(
  A_10_2 = list(
    k = 10,
    n = 2,
    rho = 0.5,
    base = 110000000L,
    anchor = 0.945,
    band = 0.02
  ),
  A_25_5 = list(
    k = 25,
    n = 5,
    rho = 0.5,
    base = 120000000L,
    anchor = 0.935,
    band = 0.02
  ),
  A_50_5 = list(
    k = 50,
    n = 5,
    rho = 0.5,
    base = 130000000L,
    anchor = 0.945,
    band = 0.02
  ),
  D_10_10 = list(
    k = 10,
    n = 10,
    rho = 0.5,
    base = 140000000L,
    anchor = 0.90,
    band = NA_real_
  )
)

run_cell <- function(nm, cl) {
  rho <- cl$rho
  cov1 <- lo_miss <- up_miss <- logical(0)
  w <- numeric(0)
  n_ok <- 0L
  t0 <- Sys.time()
  for (r in seq_len(n_rep)) {
    d <- sim_unbalanced(cl$k, cl$n, rho, seed = cl$base + r)
    if (is.null(d)) {
      next
    }
    iv <- tryCatch(
      npbootstrap_ci(
        d,
        est_single,
        conf_level = conf,
        boot_samples = b_boot,
        seed = cl$base + 3000000L + r
      ),
      # A resample with no within-subject variance (all-singleton draw) or zero
      # between variance aborts loudly; such a rep is not-ok, not a crash (M62 n_ok).
      intraclass_singular_fit = function(e) NULL
    )
    if (is.null(iv)) {
      next
    }
    n_ok <- n_ok + 1L
    lo <- iv[[1]]$conf.low
    hi <- iv[[1]]$conf.high
    cov1 <- c(cov1, lo <= rho && rho <= hi)
    lo_miss <- c(lo_miss, rho < lo)
    up_miss <- c(up_miss, rho > hi)
    w <- c(w, hi - lo)
    if (r %% 500L == 0L) {
      cat(sprintf(
        "  [%s] %d/%d n_ok=%d (%.1f min)\n",
        nm,
        r,
        n_rep,
        n_ok,
        as.numeric(Sys.time() - t0, units = "mins")
      ))
    }
  }
  list(
    cell = cl,
    name = nm,
    n_rep = n_rep,
    b_boot = b_boot,
    n_ok = n_ok,
    plot_read = cl$anchor,
    band = cl$band,
    coverage_icc1 = mean(cov1),
    lower_tail = mean(lo_miss),
    upper_tail = mean(up_miss),
    median_width = stats::median(w)
  )
}

results <- list()
for (nm in names(cells)) {
  cat(sprintf("== cell %s ==\n", nm))
  results[[nm]] <- run_cell(nm, cells[[nm]])
  saveRDS(
    results,
    "tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds"
  )
}

attr(results, "provenance") <- paste0(
  "M84 T5 unbalanced npbootstrap coverage sweep. generator: ",
  "data-raw/m84-npbootstrap-unbalanced-coverage.R; shipped reducer npbootstrap_ci(); ",
  "unbalanced one-way (balanced k x n + MCAR ",
  p_miss,
  "); n_rep=",
  n_rep,
  ", B=",
  b_boot,
  "; distinct per-cell seed bases + per-rep resample seeds; ",
  "coverage-only (no engine fit). Anchors: ohyama2025 Fig. 2 NBOOT plot-read. ",
  "Regenerate with that script."
)
saveRDS(
  results,
  "tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds"
)
cat(
  "DONE — wrote tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds\n"
)
