# oracle-bayesian-replicates.R
# ===========================================================================
# Provenance for O-Bayes-Rep: the brms (Bayesian) engine + ci_method =
# "posterior" for the WITHIN-CELL REPLICATE ICCs (Milestone 29 Slice 2,
# ADR-039). The Bayesian sibling of the frequentist replicate oracle (M17 Slice
# 3, data-raw/oracle-multilevel.R / test-replicates.R). Run to regenerate the
# committed reference (tests/testthat/fixtures/bayesian-replicates-oracle.rds)
# asserted in tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values
# (#4) -- the reference is this script's own seeded output.
#
# ENGINE/INTERVAL PARITY, NOT NEW ESTIMAND WORK. The within-cell-replicate
# coefficient is the shipped M17 estimand (residual split sigma^2_res ->
# sigma^2_sr + sigma^2_e via (1 | subject:rater); `occasions` averages pure error
# over n_o). M29 gives it the brms engine. It is a VARIANCE-RATIO push-forward
# (like every random-rater Bayesian coefficient), so NONE of the theta^2
# finite-population moment correction (M27/M28) applies -- the ICC (and its
# `occasions` per-component divisor) composes off the posterior draws exactly as
# the frequentist estimand does (posterior_summary() -> icc_point()).
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). The oracle is that the
# shipped brms + half-t(4,0,1) + MAP/percentile pipeline, read through the
# replicate estimand, (a) covers the known single- and average-occasion
# population values, (b) CONTAINS the frequentist glmmTMB replicate points in its
# credible intervals (glmmTMB the independent engine; the M17 §6 reduction), and
# (c) reports the average-occasion ICC ABOVE the single-occasion one (occasion
# averaging reduces pure error -> higher reliability of the replicate mean).
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93. The
#     half-t(4,0,1)-on-every-SD prior + MAP/percentile recipe (Sec. 4.1-4.2).
#   Generalizability theory (Cronbach et al. 1972; Brennan 2001): the two-facet
#     (rater x occasion) decomposition and the reliability of a mean over n_o
#     replicates. Estimand-spec M17-within-cell-replicates.md §1-2.
#
# DGP (this run): single-level two-way random with within-cell replicates,
#   N_s = 25 subjects, k = 4 raters, n_o = 3 replicates per cell, with
#     sigma^2_s  = 1.00   (subject true score)
#     sigma^2_r  = 0.16   (rater main effect)
#     sigma^2_sr = 0.50   (subject x rater interaction)
#     sigma^2_e  = 0.70   (pure error; reduced by occasion averaging)
#   Population ICC(A,1):
#     single  = s2_s / (s2_s + s2_r + s2_sr + s2_e)
#     average = s2_s / (s2_s + s2_r + s2_sr + s2_e / n_o)
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori. Any small-sample MAP bias is REPORTED, not tuned; the honest
#   recovery check is INTERVAL COVERAGE. The fixture is written BEFORE the hard
#   assertions so a long run is never lost.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subj <- 25L
k <- 4L
n_o <- 3L
s2_s <- 1.00
s2_r <- 0.16
s2_sr <- 0.50
s2_e <- 0.70
n_rep <- 80L
base_seed <- 20291L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The four-component -> posterior-draw-column map fit_brms_replicates() uses.
spec_rep <- c(
  subject = "sd_subject__Intercept",
  rater = "sd_rater__Intercept",
  subject_rater = "sd_subject:rater__Intercept",
  residual = "sigma"
)

# Population ICC(A,1) at each occasion setting.
pop_single <- s2_s / (s2_s + s2_r + s2_sr + s2_e)
pop_average <- s2_s / (s2_s + s2_r + s2_sr + s2_e / n_o)

# One replicated dataset (long format, factors); >1 rating per subject x rater cell.
simulate_replicates <- function() {
  grid <- expand.grid(
    rep = seq_len(n_o),
    rater = seq_len(k),
    subject = seq_len(n_subj)
  )
  mu_s <- stats::rnorm(n_subj, 0, sqrt(s2_s))
  mu_r <- stats::rnorm(k, 0, sqrt(s2_r))
  mu_sr <- stats::rnorm(n_subj * k, 0, sqrt(s2_sr))
  data.frame(
    subject = factor(grid$subject),
    rater = factor(grid$rater),
    score = mu_s[grid$subject] +
      mu_r[grid$rater] +
      mu_sr[as.integer(interaction(grid$subject, grid$rater))] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_e))
  )
}

# Compile the Stan model ONCE; every rep refits via update(recompile = FALSE) and
# runs the SHIPPED reducers, so this validates the exact recipe fit_brms_replicates()
# uses.
message("Compiling the base replicate Stan model once ...")
d0 <- simulate_replicates()
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

est_occ <- function(occ) {
  intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    replicates = TRUE,
    occasions = occ,
    n_o = n_o
  )
}
single_est <- est_occ("single")
average_est <- est_occ("average")

# One replication -> the per-rep single/average statistics. Refits on a fresh
# dataset, reads the single- and average-occasion ICC(A,1) MAP + credible interval
# (coverage of the population value), the glmmTMB points (containment), convergence.
one_rep <- function(seed) {
  d <- simulate_replicates()
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  draws <- intraclass:::brms_component_draws(fit, spec_rep)
  summ <- intraclass:::posterior_summary(
    draws,
    list(single = single_est, average = average_est),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_rep))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  g <- suppressWarnings(suppressMessages(
    intraclass::icc(
      d,
      score = score,
      subject = subject,
      rater = rater,
      occasions = c("single", "average"),
      engine = "glmmTMB"
    )
  ))
  gt <- g$estimates
  gt_single <- gt$estimate[gt$index == "ICC(A,1)" & gt$occasions == 1L]
  gt_average <- gt$estimate[gt$index == "ICC(A,1)" & gt$occasions == n_o]
  sc <- summ$single
  ac <- summ$average
  rm(fit)
  gc(verbose = FALSE)
  data.frame(
    single_map = sc$point,
    average_map = ac$point,
    cover_single = sc$conf.low <= pop_single && pop_single <= sc$conf.high,
    cover_average = ac$conf.low <= pop_average && pop_average <= ac$conf.high,
    contain_single = sc$conf.low <= gt_single && gt_single <= sc$conf.high,
    contain_average = ac$conf.low <= gt_average && gt_average <= ac$conf.high,
    average_gt_single = ac$point > sc$point,
    converged = converged
  )
}

# --- Run the simulation ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-replicates-checkpoint.rds"
set.seed(base_seed)
rows <- vector("list", n_rep)
for (r in seq_len(n_rep)) {
  rows[[r]] <- one_rep(seed = base_seed + r)
  if (r %% 10L == 0L) {
    message(sprintf("  ... %d/%d reps", r, n_rep))
    saveRDS(do.call(rbind, rows[seq_len(r)]), ckpt)
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to the reference statistics ---------------------------------
agg <- data.frame(
  k = k,
  n_o = n_o,
  n_rep = nrow(reps),
  pop_single = pop_single,
  pop_average = pop_average,
  converged_frac = mean(reps$converged),
  single_map_mean = mean(reps$single_map),
  average_map_mean = mean(reps$average_map),
  single_map_relbias = mean(reps$single_map) / pop_single - 1,
  average_map_relbias = mean(reps$average_map) / pop_average - 1,
  coverage_single = mean(reps$cover_single),
  coverage_average = mean(reps$cover_average),
  containment_single = mean(reps$contain_single),
  containment_average = mean(reps$contain_average),
  average_above_single = mean(reps$average_gt_single)
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-replicates-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "generalizability theory two-facet replicate decomposition",
      "[M17-within-cell-replicates.md]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_subj = n_subj,
      k = k,
      n_o = n_o,
      s2_s = s2_s,
      s2_r = s2_r,
      s2_sr = s2_sr,
      s2_e = s2_e
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
unlink(ckpt) # raw reps safely aggregated into the committed fixture

# --- Validate against the qualitative findings (the pins) ------------------
# QUALITATIVE pins (a coverage oracle reproduces behaviour, not decimals);
# tolerances absorb finite n_rep and the INDEPENDENT MAP estimator (#4/#18).

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
stopifnot(agg$converged_frac >= 0.90)
# (2) The single- and average-occasion credible intervals COVER their known
#     population values ~nominally (coverage -- not the point -- is the pin).
stopifnot(
  agg$coverage_single >= 0.90,
  agg$coverage_single <= 0.99,
  agg$coverage_average >= 0.90,
  agg$coverage_average <= 0.99
)
# (3) CONTAINMENT (the M17 §6 reduction): the frequentist glmmTMB replicate points
#     fall inside the brms credible intervals for ~all reps (the two engines differ
#     only by the prior; the M26 containment posture, not pointwise equality).
stopifnot(
  agg$containment_single >= 0.90,
  agg$containment_average >= 0.90
)
# (4) OCCASION AVERAGING: the average-occasion ICC is ABOVE the single-occasion one
#     in ~every rep (averaging n_o replicates reduces pure error).
stopifnot(agg$average_above_single >= 0.95)

message("All O-Bayes-Rep pins passed.")
