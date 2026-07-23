# M84 T5 / M85 T4 — coverage validation sweep for the UNBALANCED one-way
# `npbootstrap` ICC(1) reducer, extended with the ICC(k) coverage-inheritance column.
#
# NON-EXPORTED research script (data-raw/). Runs the SHIPPED reducer
# (`npbootstrap_ci`, R/ci-npbootstrap.R) on unbalanced one-way data (a balanced
# k x n design with MCAR 0.1 deletion, matching ohyama2025's unbalanced design)
# over cells read from ohyama2025 Fig. 2 (NBOOT panel), at n_rep >= 2000, and writes
# `tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds`. The test
# `test-ci-npbootstrap-unbalanced-coverage.R` asserts the committed fixture against
# the Fig. 2 plot-read anchors within +-0.02 (AC4) and the GP6 few-clusters dip.
#
# M85 T4/AC2: each rep now also computes the ICC(k)/`unit = "average"` interval (the
# monotone Spearman-Brown image with the design's harmonic-mean k_eff) and records
# `coverage_icck` (truth = k_eff*rho/(1 + (k_eff - 1)rho)) and `n_discrepant` (reps
# whose ICC(k) coverage indicator differs from the ICC(1) indicator). Coverage
# inheritance is an EXACT event identity (MD-1: k_eff <= n0, so the SB pole never
# intrudes), so `n_discrepant` must be 0 and `coverage_icck == coverage_icc1` to the
# rep -- a full-sweep mechanical confirmation of the identity the ICC(k) claim relies
# on. The ICC(1) columns are unchanged by this extension (shared rho endpoints).
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

est_single <- icc_estimand(
  unit = "single",
  k_eff = NA_real_,
  oneway = TRUE
)

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
  cov1 <- covk <- lo_miss <- up_miss <- logical(0)
  w <- numeric(0)
  n_ok <- 0L
  n_discrepant <- 0L
  t0 <- Sys.time()
  for (r in seq_len(n_rep)) {
    d <- sim_unbalanced(cl$k, cl$n, rho, seed = cl$base + r)
    if (is.null(d)) {
      next
    }
    # k_eff (harmonic mean of ratings/subject) is the ICC(k) averaging divisor for
    # this deleted design; build both estimands so the ICC(1) and ICC(k) intervals
    # share one resample stream (only the SB divisor differs).
    k_eff <- 1 / mean(1 / as.integer(table(d$subject)))
    ests <- list(
      est_single,
      icc_estimand(unit = "average", k_eff = k_eff, oneway = TRUE)
    )
    iv <- tryCatch(
      npbootstrap_ci(
        d,
        ests,
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
    cov1_r <- lo <= rho && rho <= hi
    # ICC(k): truth = the SB image of rho with the same k_eff; coverage must inherit
    # the ICC(1) indicator exactly (event identity, tolerance 0).
    truth_k <- npb_sb(rho, k_eff)
    covk_r <- iv[[2]]$conf.low <= truth_k && truth_k <= iv[[2]]$conf.high
    if (!identical(cov1_r, covk_r)) {
      n_discrepant <- n_discrepant + 1L
    }
    cov1 <- c(cov1, cov1_r)
    covk <- c(covk, covk_r)
    lo_miss <- c(lo_miss, rho < lo)
    up_miss <- c(up_miss, rho > hi)
    w <- c(w, hi - lo)
    if (r %% 500L == 0L) {
      cat(sprintf(
        "  [%s] %d/%d n_ok=%d discrepant=%d (%.1f min)\n",
        nm,
        r,
        n_rep,
        n_ok,
        n_discrepant,
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
    coverage_icck = mean(covk),
    n_discrepant = n_discrepant,
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
  "M84 T5 unbalanced npbootstrap coverage sweep, M85 T4 ICC(k) column. generator: ",
  "data-raw/m84-npbootstrap-unbalanced-coverage.R; shipped reducer npbootstrap_ci(); ",
  "unbalanced one-way (balanced k x n + MCAR ",
  p_miss,
  "); n_rep=",
  n_rep,
  ", B=",
  b_boot,
  "; distinct per-cell seed bases + per-rep resample seeds; ",
  "coverage-only (no engine fit). ICC(1) anchors: ohyama2025 Fig. 2 NBOOT plot-read. ",
  "ICC(k) column: coverage_icck + n_discrepant (rep-by-rep event identity vs ICC(1), ",
  "must be 0; MD-1). Regenerate with that script."
)
saveRDS(
  results,
  "tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds"
)
cat(
  "DONE — wrote tests/testthat/fixtures/npbootstrap-unbalanced-coverage-oracle.rds\n"
)
