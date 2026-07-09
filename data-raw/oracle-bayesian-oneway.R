# oracle-bayesian-oneway.R
# ===========================================================================
# Provenance for O-Bayes-OW: the brms (Bayesian) engine + ci_method =
# "posterior" for the ONE-WAY random ICC (Milestone 26 Slice 1, ADR-036). Run
# to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-oneway-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output, validated
# here against the reported behavior of the sources below.
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). This is the one-way
# sibling of data-raw/oracle-bayesian.R (M23, two-way): the SAME shipped recipe
# (brms + half-t(4,0,1) SD prior + MAP/percentile reduction), on the ONE-WAY
# component structure (subject + confounded residual, NO rater term).
#
# ESTIMAND (sourced -- PRINCIPLES.md #1/#4; no new spec, reuses M6-oneway.md)
# ---------------------------------------------------------------------------
#   Shrout & Fleiss (1979) Case 1 / McGraw & Wong (1996) one-way random:
#     ICC(1)   = sigma^2_s / (sigma^2_s + sigma^2_res)
#     ICC(1,k) = sigma^2_s / (sigma^2_s + sigma^2_res / k)
#   Raters are interchangeable: the rater main effect + subject x rater
#   interaction are confounded into the single residual sigma^2_res.
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23)
# ---------------------------------------------------------------------------
#   ten Hove, Jorgensen & van der Ark (2020), Springer Proc. Math. & Stat. 322,
#   79-93, doi:10.1007/978-3-030-43469-4_7 (OSF shkqm): half-t(4, 0, 1) on every
#   random-effect SD (here the single sigma_s); MAP point (posterior mode, not
#   the EAP) + percentile 95% credible interval (their Sec. 4.2). The prior is
#   the engine's exact, fixed prior; the reducers here are the SHIPPED
#   brms_component_draws() / posterior_summary() / brms_convergence().
#
# DGP
# ---------------------------------------------------------------------------
#   Y_sr = mu + mu_s + e_sr,  mu = 0,  mu_s ~ N(0, sigma^2_s),
#   e_sr ~ N(0, sigma^2_res).  N = 30 subjects, sigma^2_s = sigma^2_res = 0.5
#   (population ICC(1) = 0.5, an INTERIOR ratio well away from the variance
#   boundary), k in {2, 5} ratings per subject.
#
#   OBSERVED BEHAVIOR (the pins; n_rep = 150, seed 20260). The a-priori guess
#   was that the one-way ICC, having NO rater variance near the boundary, would
#   be SPARED the two-way k = 2 bias. THE SEEDED RUN FALSIFIED THAT (#18 -- report
#   the run, not the prior): the one-way MAP of ICC(1) IS biased low at k = 2
#   (rel bias ~ -0.12), by the SAME skewed small-sample variance-ratio mechanism
#   as the two-way ICC(A,1) (the mode of the ICC draws sits below the truth when
#   each subject has few ratings). Coverage stays ~nominal at both k. We pin:
#     (1) High convergence at the half-t DGP across k (observed 100%).
#     (2) MAP of ICC(1) and ICC(1,k) ~unbiased at k = 5 (|rel bias| < .10;
#         observed -.008 / +.002).
#     (3) Percentile 95% credible-interval coverage ~nominal at k = 5 (observed
#         .94 both units).
#     (4) MAP of ICC(1) biased LOW at k = 2 and MORE biased than k = 5 (observed
#         -.118 vs -.008), coverage still ~nominal (observed .95) -- the one-way
#         ANALOG of the two-way k = 2 caveat, NOT the hoped-for exemption.
#   (Parallel-MCMC cross-run variation of a few tenths of a percent is ordinary
#   noise and leaves every pin intact, as the sibling oracle-bayesian.R notes.)
#
#   GUARDRAIL (#4): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori; tolerances absorb finite n_rep and the estimator, and are set to
#   bracket the observed seeded run -- NOT tuned to a target value.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subjects <- 30L
s2_s <- 0.5
s2_res <- 0.5
cells <- list(
  list(k = 2L),
  list(k = 5L)
)
n_rep <- 150L
base_seed <- 20260L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

# The one-way component -> posterior-draw-column map the engine uses (M26); passed to the
# shipped reducers (which take an explicit `spec`/`vars` since M24, ADR-034).
spec_ow <- c(
  subject = "sd_subject__Intercept",
  residual = "sigma"
)

pop_icc1 <- function() s2_s / (s2_s + s2_res)
pop_icck <- function(k) s2_s / (s2_s + s2_res / k)

# One dataset from the one-way DGP (long format, factors). Rater identity is nominal
# (a rating slot); the fit ignores it (score ~ 1 + (1 | subject)).
simulate_oneway <- function(k) {
  mu_s <- stats::rnorm(n_subjects, 0, sqrt(s2_s))
  grid <- expand.grid(
    subject = seq_len(n_subjects),
    rater = seq_len(k)
  )
  e <- stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  data.frame(
    subject = factor(grid$subject),
    rater = factor(grid$rater),
    score = mu_s[grid$subject] + e
  )
}

# Compile the Stan model ONCE (see oracle-bayesian.R for the amortization rationale);
# every rep re-samples via update(seed = ...) on fresh DGP data, applying the SHIPPED
# reduction functions -- so this validates the exact recipe fit_brms_oneway() uses.
message("Compiling the base Stan model once ...")
d0 <- simulate_oneway(cells[[1]]$k)
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | subject),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> the statistics we aggregate: MAP ICC(1) + ICC(1,k) and their
# percentile credible intervals (coverage of the population values), plus convergence.
one_rep <- function(k, seed) {
  d <- simulate_oneway(k)
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  draws <- intraclass:::brms_component_draws(fit, spec_ow)
  est1 <- intraclass:::icc_estimand(unit = "single", k_eff = k, oneway = TRUE)
  estk <- intraclass:::icc_estimand(unit = "average", k_eff = k, oneway = TRUE)
  summ <- intraclass:::posterior_summary(
    draws,
    list(est1, estk),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ow))
  p1 <- pop_icc1()
  pk <- pop_icck(k)
  out <- data.frame(
    k = k,
    pop_icc1 = p1,
    pop_icck = pk,
    map_icc1 = summ[[1]]$point,
    cover_icc1 = summ[[1]]$conf.low <= p1 && p1 <= summ[[1]]$conf.high,
    map_icck = summ[[2]]$point,
    cover_icck = summ[[2]]$conf.low <= pk && pk <= summ[[2]]$conf.high,
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
  message(sprintf("Cell k=%d: %d reps", cell$k, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(cell$k, seed = base_seed + r)
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to the per-cell reference statistics ------------------------
agg <- do.call(
  rbind,
  lapply(cells, function(cell) {
    x <- reps[reps$k == cell$k, ]
    data.frame(
      k = cell$k,
      n_rep = nrow(x),
      pop_icc1 = x$pop_icc1[1],
      pop_icck = x$pop_icck[1],
      converged_frac = mean(x$converged),
      map_icc1_relbias = mean(x$map_icc1) / x$pop_icc1[1] - 1,
      coverage_icc1 = mean(x$cover_icc1),
      map_icck_relbias = mean(x$map_icck) / x$pop_icck[1] - 1,
      coverage_icck = mean(x$cover_icck)
    )
  })
)
print(agg)

# --- Validate against the expected behavior (the pins) ---------------------
# Pins encode the QUALITATIVE one-way findings (a coverage oracle reproduces
# findings, not exact decimals). Tolerances bracket the observed seeded run and
# our INDEPENDENT reflected-KDE MAP; they are NOT tuned to a target (#4). The
# observed values are recorded in the test file's O-Bayes-OW assertions.
k5 <- agg[agg$k == 5L, ]
k2 <- agg[agg$k == 2L, ]

# (1) High convergence at the half-t DGP (interior variance ratio, both k).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) MAP of ICC(1) ~unbiased at k = 5 (|rel bias| < .10); ICC(1,k) likewise.
stopifnot(
  abs(k5$map_icc1_relbias) < 0.10,
  abs(k5$map_icck_relbias) < 0.10
)
# (3) Percentile 95% credible-interval coverage ~nominal at k = 5.
stopifnot(
  k5$coverage_icc1 >= 0.90,
  k5$coverage_icc1 <= 0.99,
  k5$coverage_icck >= 0.90,
  k5$coverage_icck <= 0.99
)
# (4) THE HONEST FINDING (#18): the one-way MAP of ICC(1) IS biased low at k = 2
#     and more so than at k = 5 -- the same skewed small-sample variance-ratio
#     mechanism as the two-way ICC(A,1) k = 2 caveat, NOT the a-priori exemption.
#     Coverage of the percentile interval stays ~nominal (the point moves, the
#     interval still brackets the truth). Mirrors oracle-bayesian.R's k = 2 pins.
stopifnot(
  k2$map_icc1_relbias < -0.05, # biased low at k = 2
  k2$map_icc1_relbias < k5$map_icc1_relbias, # more biased than k = 5
  k2$coverage_icc1 >= 0.88 # interval still ~covers
)

# --- Commit the reference --------------------------------------------------
out <- file.path("tests", "testthat", "fixtures", "bayesian-oneway-oracle.rds")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020),",
      "doi:10.1007/978-3-030-43469-4_7 (prior/MAP/percentile);",
      "Shrout & Fleiss (1979) / McGraw & Wong (1996) Case 1 (estimand)"
    ),
    generated = Sys.Date(),
    dgp = list(n_subjects = n_subjects, s2_s = s2_s, s2_res = s2_res),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
