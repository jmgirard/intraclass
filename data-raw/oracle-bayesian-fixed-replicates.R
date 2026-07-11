# oracle-bayesian-fixed-replicates.R
# ===========================================================================
# Provenance for O-Bayes-FRep: the brms (Bayesian) engine + ci_method =
# "posterior" for FIXED-rater WITHIN-CELL REPLICATE ICCs (Milestone 33 Slice 2,
# ADR-043). The fixed-rater sibling of O-Bayes-Rep (M29 Slice 2, random
# replicates) and the Bayesian sibling of the frequentist M20 Slice 1
# (fit_glmmtmb_replicates_fixed). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-fixed-replicates-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4).
#
# ENGINE/INTERVAL PARITY, NOT NEW ESTIMAND WORK. The estimand is the shipped M20
# Slice 1 fixed-rater replicate coefficient: the M17 residual split
# (sigma^2_res -> sigma^2_sr + sigma^2_e via (1 | subject:rater)) with the rater
# slot carrying the Case-3A finite-population theta^2_r instead of sigma^2_r.
# M33 gives it the brms engine (fit_brms_replicates_fixed), reading theta^2_r per
# posterior draw from the rater fixed-effect draws (the shared brms_theta2r_draws;
# the 2b moment correction is ~0 on BALANCED replicated data -- the M26/M27-S1
# regime, not the ragged M31 regime). `occasions` divides only pure error by n_o.
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses M17-within-cell-replicates.md +
# M10 §2 / M3 §6 for theta^2_r)
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A fixed raters: the rater effect is the
#   finite-population variance of the k FIXED rater means
#     theta^2_r = sum_j (mu_rj - mu_r_bar)^2 / (k - 1),
#   and the single-/average-occasion fixed-rater ICC(A,1) are
#     single  = s2_s / (s2_s + theta^2_r + s2_sr + s2_e)
#     average = s2_s / (s2_s + theta^2_r + s2_sr + s2_e / n_o).
#   Because the raters are a fixed finite population, mu_rj are FIXED across
#   replications (not redrawn, as in oracle-bayesian-fixed.R) -- coverage is of
#   this fixed-population ICC(A,1).
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23/M26/M29)
# ---------------------------------------------------------------------------
#   ten Hove, Jorgensen & van der Ark (2020): half-t(4,0,1) on the random-effect
#   SDs (sigma_s, sigma_sr; the k - 1 rater contrasts keep brms's default flat
#   prior); MAP point + percentile 95% credible interval; RAW theta^2_r per draw
#   (no frequentist bias correction -- the posterior integrates the parameter
#   uncertainty; ADR-036).
#
# DGP (this run): single-level two-way FIXED-rater with within-cell replicates,
#   N_s = 25 subjects, k = 4 FIXED raters, n_o = 3 replicates per cell, with
#     s2_s  = 1.00   (subject true score)
#     mu_r  = c(-0.6, -0.2, 0.2, 0.6)  (FIXED rater means; theta^2_r = 0.8/3 = 0.2667)
#     s2_sr = 0.50   (subject x rater interaction)
#     s2_e  = 0.70   (pure error; reduced by occasion averaging)
#   pop single  = 1.0 / (1.0 + 0.2667 + 0.5 + 0.7)    = 0.4054
#   pop average = 1.0 / (1.0 + 0.2667 + 0.5 + 0.7/3)  = 0.5000
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori; small-sample MAP skew (mode below the plug-in) is REPORTED, not
#   tuned. The honest recovery check is INTERVAL COVERAGE + CONTAINMENT of the
#   glmmTMB fixed point. The fixture is written BEFORE the hard pins.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subj <- 25L
k <- 4L
n_o <- 3L
s2_s <- 1.00
mu_r <- c(-0.6, -0.2, 0.2, 0.6) # FIXED finite population of k = 4 rater means
s2_sr <- 0.50
s2_e <- 0.70
theta2_r <- sum((mu_r - mean(mu_r))^2) / (k - 1) # 0.8 / 3 = 0.26667
n_rep <- 80L
base_seed <- 33200L
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The RANDOM components of the fixed-rater replicate fit -> draw-column map
# (fit_brms_replicates_fixed uses {subject, subject_rater, residual}; theta^2_r is
# read separately from the rater fixed-effect draws and injected into the rater slot).
spec_frep <- c(
  subject = "sd_subject__Intercept",
  subject_rater = "sd_subject:rater__Intercept",
  residual = "sigma"
)

pop_single <- s2_s / (s2_s + theta2_r + s2_sr + s2_e)
pop_average <- s2_s / (s2_s + theta2_r + s2_sr + s2_e / n_o)

# One replicated dataset with FIXED rater means (long format, factors); >1 rating per
# subject x rater cell. Subjects, interactions, and pure error are redrawn each rep;
# the k rater means are the fixed finite population.
simulate_fixed_replicates <- function() {
  grid <- expand.grid(
    rep = seq_len(n_o),
    rater = seq_len(k),
    subject = seq_len(n_subj)
  )
  mu_s <- stats::rnorm(n_subj, 0, sqrt(s2_s))
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

# Compile the Stan model ONCE (score ~ 1 + rater + (1|subject) + (1|subject:rater), the
# fixed-rater replicate formula); every rep refits via update(recompile = FALSE) and runs
# the SHIPPED reducers + theta^2_r push-forward, so this validates the exact recipe
# fit_brms_replicates_fixed() uses.
message("Compiling the base fixed-replicate Stan model once ...")
d0 <- simulate_fixed_replicates()
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + rater + (1 | subject) + (1 | subject:rater),
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
    raters = "fixed",
    k_eff = k,
    replicates = TRUE,
    occasions = occ,
    n_o = n_o
  )
}
single_est <- est_occ("single")
average_est <- est_occ("average")

# One replication -> single/average fixed-rater ICC(A,1) MAP + credible interval
# (coverage of the FIXED-population value), the glmmTMB fixed points (containment), and
# convergence. Assembles the {subject, rater=theta^2_r, subject_rater, residual} draws
# exactly as fit_brms_replicates_fixed() does, reusing the ONE compiled model.
one_rep <- function(seed) {
  d <- simulate_fixed_replicates()
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  rand <- intraclass:::brms_component_draws(fit, spec_frep)
  theta <- intraclass:::brms_theta2r_draws(fit, d)
  draws <- rbind(
    subject = rand["subject", ],
    rater = theta,
    subject_rater = rand["subject_rater", ],
    residual = rand["residual", ]
  )
  summ <- intraclass:::posterior_summary(
    draws,
    list(single = single_est, average = average_est),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_frep))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  g <- suppressWarnings(suppressMessages(
    intraclass::icc(
      d,
      score = score,
      subject = subject,
      rater = rater,
      raters = "fixed",
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
ckpt <- "data-raw/.oracle-bayesian-fixed-replicates-checkpoint.rds"
rows <- if (file.exists(ckpt)) readRDS(ckpt) else vector("list", n_rep)
for (r in seq_len(n_rep)) {
  if (!is.null(rows[[r]])) {
    next
  }
  rows[[r]] <- one_rep(seed = base_seed + r)
  if (r %% 10L == 0L) {
    message(sprintf("  ... %d/%d reps", r, n_rep))
    saveRDS(rows, ckpt)
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to the reference statistics ---------------------------------
agg <- data.frame(
  k = k,
  n_o = n_o,
  n_rep = nrow(reps),
  theta2_r = theta2_r,
  pop_single = pop_single,
  pop_average = pop_average,
  converged_frac = mean(reps$converged),
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
  "bayesian-fixed-replicates-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe];",
      "McGraw & Wong (1996) Case 3A [theta^2_r]; GT two-facet replicate",
      "decomposition [M17-within-cell-replicates.md]; glmmTMB M20 Slice 1 [point]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_subj = n_subj,
      k = k,
      n_o = n_o,
      s2_s = s2_s,
      mu_r = mu_r,
      theta2_r = theta2_r,
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
unlink(ckpt)

# --- Validate against the qualitative findings (the pins) ------------------
# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
stopifnot(agg$converged_frac >= 0.90)
# (2) Coverage of the FIXED-population single/average ICC(A,1) ~nominal (the pin is
#     coverage, not the point). On balanced replicated data the 2b moment correction
#     is ~0, so no undercoverage from the theta^2 functional is expected.
stopifnot(
  agg$coverage_single >= 0.90,
  agg$coverage_single <= 0.99,
  agg$coverage_average >= 0.90,
  agg$coverage_average <= 0.99
)
# (3) CONTAINMENT / REDUCTION (M20 §6): the frequentist glmmTMB fixed replicate points
#     fall inside the brms credible intervals for ~all reps (the two engines differ only
#     by the prior; the M26/M29 containment posture, not pointwise equality). On balanced
#     data theta^2_r == sigma^2_r, so this is also the fixed==random reduction.
stopifnot(
  agg$containment_single >= 0.90,
  agg$containment_average >= 0.90
)
# (4) OCCASION AVERAGING: the average-occasion ICC is ABOVE the single-occasion one in
#     ~every rep (averaging n_o replicates reduces pure error).
stopifnot(agg$average_above_single >= 0.95)

message("All O-Bayes-FRep pins passed.")
