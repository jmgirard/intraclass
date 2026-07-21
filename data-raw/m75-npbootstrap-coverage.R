# M75 T4 — coverage/width validation sweep for the exported `npbootstrap` reducer.
#
# NON-EXPORTED research script (data-raw/). Runs the SHIPPED reducer
# (`npbootstrap_ci`, R/ci-npbootstrap.R) over the M62 comparison cells C1-C4 and
# the ukoumunne2003 Table I oracle cells U10/U30/U50 at n_rep >= 2000, and writes
# `tests/testthat/fixtures/npbootstrap-coverage-oracle.rds`. The test
# `test-ci-npbootstrap-coverage.R` asserts the committed fixture against the
# Table I anchors (AC3), the tail-balance + width disclosure (AC4), the rep-by-rep
# ICC(k)=ICC(1) inheritance (BC3), and the point-outside-interval bound (BC6).
#
# Heavy (~n_rep x 7 cells x B ANOVA resamples). Deterministic per-rep seeding.
# B (resamples) defaults to 999 -- the package's `boot_samples` default, and coverage
# over n_rep >= 2000 reps is insensitive to B beyond ~1000. Run in the background:
#   M75_NREP=2000 Rscript data-raw/m75-npbootstrap-coverage.R
#
# REML shortcut (BC5/BC6): for a BALANCED one-way random design the glmmTMB REML
# point equals max(0, ANOVA-MoM rho) exactly (sigma^2_a truncated at 0), so the
# reported point is computed analytically here rather than by 14000 live fits.
# `test-ci-npbootstrap.R` verifies icc() reports exactly this point end-to-end.

suppressMessages(devtools::load_all(quiet = TRUE))

n_rep <- as.integer(Sys.getenv("M75_NREP", "2000"))
b_boot <- as.integer(Sys.getenv("M75_B", "999"))
conf <- 0.95

# Balanced one-way DGP, sigma_a^2 + sigma_e^2 = 1 so ICC(1) = rho exactly.
sim_oneway <- function(k, n, rho, seed) {
  set.seed(seed)
  a <- stats::rnorm(k, 0, sqrt(rho))
  y <- rep(a, each = n) + stats::rnorm(k * n, 0, sqrt(1 - rho))
  data.frame(
    subject = factor(rep(seq_len(k), each = n)),
    rater = factor(rep(seq_len(n), times = k)),
    score = y
  )
}

# Analytic balanced one-way REML point = max(0, MoM rho) (see header).
reml_point_oneway <- function(df) {
  groups <- split(df$score, df$subject)
  k <- length(groups)
  n <- length(groups[[1]])
  ybar <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  ssa <- n * sum((ybar - grand)^2)
  sse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1)))
  msa <- ssa / (k - 1)
  mse <- sse / (k * (n - 1))
  max(0, (msa - mse) / (msa + (n - 1) * mse))
}

sb <- function(rho, m) m * rho / (1 + (m - 1) * rho)

# Distinct, well-separated per-cell seed bases (RR01 finding 1: the M62 harness
# collided because its base used only the cell name's first letter).
cells <- list(
  C1 = list(k = 30, n = 4, rho = 0.50, base = 10000000L),
  C2 = list(k = 30, n = 4, rho = 0.05, base = 20000000L),
  C3 = list(k = 12, n = 4, rho = 0.50, base = 30000000L),
  C4 = list(k = 12, n = 4, rho = 0.05, base = 40000000L),
  U10 = list(k = 10, n = 10, rho = 0.05, base = 50000000L),
  U30 = list(k = 30, n = 10, rho = 0.05, base = 60000000L),
  U50 = list(k = 50, n = 10, rho = 0.05, base = 70000000L)
)

est_single <- icc_estimand(unit = "single", k_eff = NA_real_, oneway = TRUE)

run_cell <- function(nm, cl) {
  k <- cl$k
  n <- cl$n
  rho <- cl$rho
  icck_true <- sb(rho, n)
  # ICC(k) estimand carries divisor = n (balanced one-way ratings per subject).
  est_avg <- icc_estimand(unit = "average", k_eff = n, oneway = TRUE)
  ests <- list(est_single, est_avg)

  cov1 <- covk <- lo_miss <- up_miss <- pt_out <- logical(n_rep)
  w_trunc <- w_untrunc <- numeric(n_rep)
  t0 <- Sys.time()
  for (r in seq_len(n_rep)) {
    d <- sim_oneway(k, n, rho, seed = cl$base + r)
    ivs <- npbootstrap_ci(
      d,
      ests,
      conf_level = conf,
      boot_samples = b_boot,
      seed = cl$base + 3000000L + r # distinct per-rep resample stream (RR01 finding 2)
    )
    lo1 <- ivs[[1]]$conf.low
    hi1 <- ivs[[1]]$conf.high
    lok <- ivs[[2]]$conf.low
    hik <- ivs[[2]]$conf.high
    cov1[r] <- lo1 <= rho && rho <= hi1
    covk[r] <- lok <= icck_true && icck_true <= hik
    lo_miss[r] <- rho < lo1
    up_miss[r] <- rho > hi1
    w_untrunc[r] <- hi1 - lo1
    w_trunc[r] <- min(1, max(0, hi1)) - min(1, max(0, lo1))
    pt <- reml_point_oneway(d)
    pt_out[r] <- pt < lo1 || pt > hi1
    if (r %% 250L == 0L) {
      cat(sprintf(
        "  [%s] %d/%d (%.1f min)\n",
        nm,
        r,
        n_rep,
        as.numeric(Sys.time() - t0, units = "mins")
      ))
    }
  }
  # BC3: the ICC(k) interval is the exact monotone image of the ICC(1) interval,
  # so the coverage indicators must agree REP-BY-REP. Any disagreement is an
  # implementation bug (a broken map / wrong divisor), not sampling noise -> halt.
  n_disagree <- sum(cov1 != covk)
  if (n_disagree > 0L) {
    stop(sprintf(
      "[%s] BC3 violated: ICC(k) and ICC(1) coverage disagree on %d of %d reps.",
      nm,
      n_disagree,
      n_rep
    ))
  }
  list(
    cell = cl,
    name = nm,
    n_rep = n_rep,
    b_boot = b_boot,
    icck_true = icck_true,
    coverage_icc1 = mean(cov1),
    coverage_icck = mean(covk),
    n_disagree_icc1_icck = n_disagree,
    lower_tail = mean(lo_miss),
    upper_tail = mean(up_miss),
    median_width_untrunc = stats::median(w_untrunc),
    median_width_trunc = stats::median(w_trunc),
    point_outside_rate = mean(pt_out)
  )
}

results <- list()
for (nm in names(cells)) {
  cat(sprintf("== cell %s ==\n", nm))
  results[[nm]] <- run_cell(nm, cells[[nm]])
  saveRDS(results, "tests/testthat/fixtures/npbootstrap-coverage-oracle.rds") # checkpoint
}

attr(results, "provenance") <- paste0(
  "M75 T4 npbootstrap coverage sweep. generator: ",
  "data-raw/m75-npbootstrap-coverage.R; shipped reducer npbootstrap_ci(); ",
  "n_rep=", n_rep, ", B=", b_boot, "; distinct per-cell seed bases + per-rep ",
  "resample seeds; REML point = max(0, MoM) analytic (balanced one-way). ",
  "Regenerate with that script."
)
saveRDS(results, "tests/testthat/fixtures/npbootstrap-coverage-oracle.rds")
cat("DONE — wrote tests/testthat/fixtures/npbootstrap-coverage-oracle.rds\n")
