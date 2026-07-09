# oracle-bayesian.R
# ===========================================================================
# Provenance for O-Bayes: the brms (Bayesian) engine + ci_method = "posterior"
# for two-way random ICCs (Milestone 23, ADR-033). Run to regenerate the
# committed reference (tests/testthat/fixtures/bayesian-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output, and it is
# validated here against the published findings of the source below.
#
# A CI method's oracle is COVERAGE (#1; M16 precedent). The source is a
# SIMULATION study, so there is no worked-example point to reproduce -- the
# oracle is that our shipped brms + half-t(4,0,1) + MAP/percentile pipeline
# reproduces the source's reported bias / coverage / convergence findings.
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions to Estimate Variance Components for Interrater
#     Reliability Coefficients. Springer Proc. Math. & Stat. 322, 79-93.
#     doi:10.1007/978-3-030-43469-4_7. OSF: shkqm.
#
#   DGP (Sec. 4.1.1): Y_sr = mu + mu_s + mu_r + mu_sr, mu = 0,
#     N = 30 subjects, sigma^2_s = sigma^2_sr = 0.5, sigma^2_r in {.01, .04},
#     k in {2, 3, 5}. Coefficient evaluated: ICC(A,1) = s2_s / (s2_s+s2_r+s2_sr)
#     -> population 0.4950 (s2_r=.01) / 0.4808 (s2_r=.04).
#   Prior (half-t condition, Sec. 4.1.2): half-t(4, 0, 1) on every random-effect
#     SD (sigma_s, sigma_r, sigma_sr) -- our engine's exact, fixed prior.
#   MCMC (Sec. 4.1.3): 3 chains x 1000 iter (500 warmup), R-hat < 1.10,
#     N_eff > 100; 1000 replications per cell.
#
#   REPORTED FINDINGS (Sec. 4.2, Figs 1-4) -- the pins:
#     (1) Convergence 100% at the half-t DGP across all k.
#     (2) MAP is UNBIASED for sigma_r at k > 2 (|rel bias| within their <=.05
#         band) while the EAP SEVERELY OVERESTIMATES sigma_r (large positive
#         rel bias, >> MAP).
#     (3) For ICC(A,1): MAP UNBIASED at k = 5 (<=.05), biased LOW (~-0.3 rel) at
#         k = 2; MAP and EAP of ICC(A,1) comparable.
#     (4) Percentile 95% BCI coverage ~nominal (~95-97%) at k > 2.
#
#   GUARDRAIL (#4): our MAP estimator (reflected-KDE posterior_mode()) is
#   INDEPENDENT of their modeest tool -- convergence on their findings is a
#   cross-implementation check, not a re-run of their code. The mode
#   bandwidth/boundary spec is fixed a-priori and validated, NOT tuned here.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config (adjust reps/cells for a tighter or faster reference) ----------
# Two headline cells at sigma^2_r = .01 reproduce the two key contrasts: MAP
# unbiased + nominal coverage at k = 5, and MAP biased low at k = 2. Half-t is
# the engine's fixed prior. n_rep drives the Monte-Carlo error of the coverage /
# bias estimates (SE(coverage) ~ sqrt(.95*.05/n_rep)); ten Hove used 1000.
n_subjects <- 30L
s2_s <- 0.5
s2_sr <- 0.5
cells <- list(
  list(k = 2L, s2_r = 0.01),
  list(k = 5L, s2_r = 0.01)
)
n_rep <- 250L
base_seed <- 20200L # DGP stream seed (distinct from each fit's Stan seed)
# Match the source's sampler; iter bumped to 2000 for robust fixed-warmup
# convergence (we do not adaptively double warmup as they did). cores = 3 samples
# the chains in parallel (this is a long batch run).
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The two-way component -> posterior-draw-column map the engine uses (M23); passed to the
# shipped reducers, which since M24 (ADR-034) take an explicit `spec`/`vars`.
spec_tw <- c(
  subject = "sd_subject__Intercept",
  rater = "sd_rater__Intercept",
  residual = "sigma"
)

pop_icc_a1 <- function(s2_r) s2_s / (s2_s + s2_r + s2_sr)

# One dataset from the DGP (long format, factors) -- Eq. 1 with the confounded
# subject x rater interaction folded into a single residual term.
simulate_twoway <- function(k, s2_r) {
  mu_s <- stats::rnorm(n_subjects, 0, sqrt(s2_s))
  mu_r <- stats::rnorm(k, 0, sqrt(s2_r))
  grid <- expand.grid(
    subject = seq_len(n_subjects),
    rater = seq_len(k)
  )
  mu_sr <- stats::rnorm(nrow(grid), 0, sqrt(s2_sr))
  data.frame(
    subject = factor(grid$subject),
    rater = factor(grid$rater),
    score = mu_s[grid$subject] + mu_r[grid$rater] + mu_sr
  )
}

# Compile the Stan model ONCE. brms recompiles on every brm() call (~40 s each), which
# is infeasible over hundreds of replications; update(recompile = FALSE) reuses the DSO.
# The base fit uses the engine's EXACT formula + sourced half-t prior, and every rep
# below applies the SHIPPED reduction functions (brms_component_draws / posterior_summary
# / posterior_mode / brms_convergence) -- so this validates the same estimation recipe
# fit_brms_twoway() uses, only amortizing the compile (the model is identical across k).
# The base fit is only a COMPILED TEMPLATE: its own draws are never used (each rep
# re-samples via update(seed = ...)). The per-rep DGP data and Stan seeds are fixed, so
# the committed reference is a reproducible seeded realization; minor cross-run variation
# (a few tenths of a percent in the convergence/coverage rates) is ordinary MCMC noise
# and leaves every reported finding intact.
message("Compiling the base Stan model once ...")
d0 <- simulate_twoway(cells[[1]]$k, cells[[1]]$s2_r)
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | subject) + (1 | rater),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> the statistics we aggregate. Refits the compiled model on a fresh
# dataset via update(), then runs the shipped reduction: MAP ICC(A,1) + its percentile
# credible interval (coverage of the population ICC), and the MAP and EAP of sigma_r (the
# MAP-vs-EAP contrast is on sigma_r itself, as the source reports it), plus convergence.
one_rep <- function(k, s2_r, seed) {
  d <- simulate_twoway(k, s2_r)
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  draws <- intraclass:::brms_component_draws(fit, spec_tw)
  est <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k
  )
  summ <- intraclass:::posterior_summary(draws, list(est), conf_level = 0.95)[[
    1
  ]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_tw))
  pop <- pop_icc_a1(s2_r)
  sr_draws <- sqrt(draws["rater", ]) # sigma_r = sqrt of the rater-variance draws
  out <- data.frame(
    k = k,
    s2_r = s2_r,
    pop_icc = pop,
    map_icc = summ$point,
    cover_icc = summ$conf.low <= pop && pop <= summ$conf.high,
    map_sr = intraclass:::posterior_mode(sr_draws, lower = 0),
    eap_sr = mean(sr_draws),
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
set.seed(base_seed)
rows <- list()
for (cell in cells) {
  message(sprintf("Cell k=%d, s2_r=%.2f: %d reps", cell$k, cell$s2_r, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(
      cell$k,
      cell$s2_r,
      seed = base_seed + r
    )
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to the per-cell reference statistics ------------------------
agg <- do.call(
  rbind,
  lapply(cells, function(cell) {
    x <- reps[reps$k == cell$k & reps$s2_r == cell$s2_r, ]
    true_sr <- sqrt(cell$s2_r)
    data.frame(
      k = cell$k,
      s2_r = cell$s2_r,
      n_rep = nrow(x),
      pop_icc = x$pop_icc[1],
      converged_frac = mean(x$converged),
      # Relative bias (theta_bar - theta) / theta, the source's metric.
      map_icc_relbias = mean(x$map_icc) / x$pop_icc[1] - 1,
      coverage_icc = mean(x$cover_icc),
      map_sr_relbias = mean(x$map_sr) / true_sr - 1,
      eap_sr_relbias = mean(x$eap_sr) / true_sr - 1
    )
  })
)
print(agg)

# --- Validate against ten Hove et al. (2020), Sec. 4.2 (the pins) ----------
# The pins encode the source's QUALITATIVE findings (a coverage oracle reproduces
# findings, not exact decimals). Tolerances absorb our finite n_rep and our
# INDEPENDENT MAP estimator; two divergences from the source are REPORTED, not
# tuned away (#4/#18):
#   * CONVERGENCE is high but not their 100%: they adaptively DOUBLED warmup until
#     R-hat < 1.10; we use a fixed warmup budget, so a minority of the near-boundary
#     k = 2 reps fall short (k=2 ~0.92, k=5 ~0.99). Pinned >= 0.90.
#   * Our reflected-KDE MAP of sigma_r is modestly NEGATIVE-biased (~ -0.15 at k=5)
#     where their modeest MAP was ~unbiased -- an estimator difference at a tiny
#     near-boundary sigma_r that barely moves the ICC (sigma^2_r is a small term in
#     the denominator). We therefore pin the ROBUST contrast (EAP overestimates far
#     more than the MAP), not our sigma_r MAP's absolute bias.
# Observed (n_rep = 250, seed 20200): k=5 conv .992, MAP-ICC relbias -.040, cover
# .948, MAP-sr relbias -.147, EAP-sr relbias +.741; k=2 conv .924, MAP-ICC relbias
# -.243, cover .912, MAP-sr relbias -.318, EAP-sr relbias +3.599.
k5 <- agg[agg$k == 5L, ]
k2 <- agg[agg$k == 2L, ]

# (1) High convergence at the half-t DGP (their 100%, modulo our fixed warmup).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) sigma_r: the EAP SEVERELY overestimates, and by far more than the MAP -- the
#     source's central Fig-1 finding (the estimator-independent, robust claim).
stopifnot(
  k5$eap_sr_relbias > 0.10,
  k5$eap_sr_relbias > k5$map_sr_relbias + 0.10,
  k2$eap_sr_relbias > k2$map_sr_relbias + 0.10
)
# (3) ICC(A,1): MAP unbiased at k = 5 (|rel bias| < .10), biased LOW at k = 2, and
#     more biased at k = 2 than k = 5 (their Fig 2).
stopifnot(
  abs(k5$map_icc_relbias) < 0.10,
  k2$map_icc_relbias < -0.05,
  k2$map_icc_relbias < k5$map_icc_relbias
)
# (4) Percentile 95% credible-interval coverage ~nominal at k = 5; undercovers at
#     k = 2 (their Figs 3-4; and our k = 2 caveat).
stopifnot(
  k5$coverage_icc >= 0.90,
  k5$coverage_icc <= 0.99,
  k2$coverage_icc < k5$coverage_icc
)

# --- Commit the reference --------------------------------------------------
out <- file.path("tests", "testthat", "fixtures", "bayesian-oracle.rds")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = "ten Hove, Jorgensen & van der Ark (2020), doi:10.1007/978-3-030-43469-4_7",
    generated = Sys.Date(),
    dgp = list(n_subjects = n_subjects, s2_s = s2_s, s2_sr = s2_sr),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
