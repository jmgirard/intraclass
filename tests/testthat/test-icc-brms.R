# brms (Bayesian) engine + ci_method = "posterior" — Slice 1 wiring (M23/ADR-033)
#
# Slice 1 is ENGINE + INTERVAL-METHOD WIRING; the coverage oracle (O-Bayes) is Slice 2.
# So the tests here split in two:
#   * The COUPLING and SCOPE aborts, and the posterior_mode()/posterior_summary()
#     reducers, need NO brms install (they fire/run before check_installed("brms")) and
#     run on every CI job.
#   * A single LIVE brms fit (skip_if_not_installed + skip_on_cran, tiny chains/iter)
#     exercises the real Stan wiring: draw extraction, the "posterior" branch end to end,
#     the credible-interval labelling, and a loose MAP ~ REML sanity check (a preview of
#     the Slice-2 O-Bayes-agree oracle, not the coverage oracle itself).
#
# We do NOT snapshot the printed MCMC fit: the reported point/interval are functions of
# posterior draws that can drift across brms/Stan versions, so a numeric snapshot is
# brittle. The print/tidy assertions target the DETERMINISTIC structure instead (the
# engine + "posterior credible" label, the row set, ci$method), matching the house
# guidance against snapshotting fitted-model prints.

# --- Coupling: engine <-> ci_method are locked together (no brms needed) -------

test_that("ci_method = \"posterior\" requires engine = \"brms\"", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, ci_method = "posterior"),
    class = "intraclass_unsupported"
  )
})

test_that("engine = \"brms\" rejects non-posterior ci_method", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, engine = "brms", ci_method = "montecarlo"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, engine = "brms", ci_method = "bootstrap"),
    class = "intraclass_unsupported"
  )
})

test_that("engine = \"brms\" forces ci_method = \"posterior\" by default", {
  # The forced default is applied before any fit, so we can observe it via the
  # downstream check_installed abort's ABSENCE of a ci_method complaint: with brms
  # installed the fit proceeds; without it, the ONLY error is the missing package,
  # never a ci_method mismatch. Assert the coupling logic directly through the message.
  d <- sf_ratings_long()
  err <- tryCatch(
    icc(d, score, subject, rater, engine = "brms"),
    condition = function(e) e
  )
  # Either it fit (brms present) or it aborted on the missing package -- never on the
  # ci_method (the default upgraded to "posterior" silently).
  if (inherits(err, "icc")) {
    expect_identical(err$ci$method, "posterior")
  } else {
    expect_false(grepl("ci_method", conditionMessage(err)))
  }
})

# --- brm_args passthrough guards (no brms needed) ------------------------------

test_that("brm_args only applies to engine = \"brms\"", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, brm_args = list(chains = 2)),
    class = "intraclass_unsupported"
  )
})

test_that("brm_args may not override the model, prior, data, or seed", {
  d <- sf_ratings_long()
  for (key in c("formula", "data", "prior", "seed")) {
    args <- list(d, quote(score), quote(subject), quote(rater), engine = "brms")
    args$brm_args <- stats::setNames(list("x"), key)
    expect_error(
      do.call(icc, args),
      class = "intraclass_error"
    )
  }
})

test_that("brm_args must be a list", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, engine = "brms", brm_args = "chains"),
    class = "intraclass_error"
  )
})

# --- brms scope: two-way random, balanced/complete only (no brms needed) -------
# These fire before the fit, so they assert the deferral boundary without Stan.

test_that("brms refuses the deferred designs with a teaching abort", {
  d <- sf_ratings_long()
  # NB: one-way (M26 Slice 1) and single-level fixed raters (M26 Slice 2) are now SUPPORTED
  # -- see the O-Bayes-OW / O-Bayes-Fixed tests below. What stays deferred:
  # numeric unit (D-study projection)
  expect_error(
    icc(d, score, subject, rater, unit = 6, engine = "brms"),
    class = "intraclass_unsupported"
  )
  # incomplete data
  d_inc <- d[-1, , drop = FALSE]
  expect_error(
    icc(d_inc, score, subject, rater, engine = "brms"),
    class = "intraclass_unsupported"
  )
  # NB: fixed-rater MULTILEVEL now ships for brms -- single-level (M26 Slice 2), crossed
  # Design 1 (M27 Slice 1), and nested Design 2 (M27 Slice 2). Design 3 fixed stays refused
  # (by design, all engines -- no separable rater effect), asserted engine-agnostically in
  # test-icc-fixed-multilevel.R; the live O-Bayes-FML-agree / O-Bayes-FNML-agree fits below
  # assert the crossed and nested fixed paths are *supported*.
})

# M24 (ADR-034) opened the CROSSED (Design 1) multilevel random path for brms; M25
# (ADR-035) adds both NESTED designs -- Design 2 (raters nested in clusters, Slice 1) and
# Design 3 (raters nested in subjects, Slice 2). All three multilevel designs are now
# supported at the subject level, so the conflated diagnostic is the only remaining
# deferred brms multilevel path (that all three designs are *supported* is asserted by the
# live O-Bayes-ML-agree / O-Bayes-NML-agree fits below; Design 3's consistency abort is
# checked in its live test).

test_that("brms refuses the conflated diagnostic (deferred Bayesian follow-on)", {
  set.seed(12)
  crossed <- expand.grid(
    subject = 1:4,
    rater = factor(1:3),
    cluster = factor(1:3)
  )
  crossed$subject <- factor(paste0(crossed$cluster, "_", crossed$subject))
  crossed$score <- rnorm(nrow(crossed))
  expect_error(
    icc(
      crossed,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      level = "conflated",
      engine = "brms"
    ),
    class = "intraclass_unsupported"
  )
})

test_that("brms surfaces the k = 2 bias caveat as a soft note", {
  # The note is emitted BEFORE fit dispatch. Intercept it and abort the call the instant
  # it fires, so the assertion holds whether or not brms is installed and no (slow, noisy)
  # Stan fit is ever run.
  d2 <- sf_ratings_long()
  d2 <- d2[d2$rater %in% c("J1", "J2"), , drop = FALSE]
  d2$rater <- droplevels(d2$rater)
  saw_note <- FALSE
  tryCatch(
    withCallingHandlers(
      icc(d2, score, subject, rater, engine = "brms"),
      message = function(m) {
        if (grepl("k = 2", conditionMessage(m), fixed = TRUE)) {
          saw_note <<- TRUE
          stop("stop-after-note")
        }
      }
    ),
    error = function(e) invisible(NULL)
  )
  expect_true(saw_note)
})

# --- Parallel-sampling nudge (no brms needed) ---------------------------------

test_that("a sequential multi-chain brms fit nudges toward cores > 1", {
  # rlib_message_verbosity = "verbose" forces rlang's .frequency messages to show every
  # time, so the periodic nudge is deterministic in the test.
  withr::local_options(rlib_message_verbosity = "verbose")
  withr::local_options(mc.cores = 1L)
  # >1 chain on 1 core -> nudge.
  expect_message(
    brms_maybe_cores_note(list(chains = 4L)),
    regexp = "sequentially"
  )
  # Already parallel, or a single chain -> no nudge.
  expect_no_message(brms_maybe_cores_note(list(chains = 4L, cores = 4L)))
  expect_no_message(brms_maybe_cores_note(list(chains = 1L)))
})

# --- posterior_mode(): boundary-aware mode of a draw vector (no brms needed) ---

test_that("posterior_mode recovers a known interior mode", {
  set.seed(1)
  # Beta(8, 2) has mode (a-1)/(a+b-2) = 7/8 = 0.875 on [0, 1].
  expect_equal(
    posterior_mode(rbeta(20000, 8, 2), lower = 0, upper = 1),
    0.875,
    tolerance = 0.03
  )
  # Gamma(3, 2) has mode (a-1)/rate = 2/2 = 1 on [0, Inf).
  expect_equal(
    posterior_mode(rgamma(20000, 3, 2), lower = 0),
    1,
    tolerance = 0.05
  )
})

test_that("posterior_mode handles a boundary pile-up and degenerate draws", {
  set.seed(2)
  # Half-normal-ish mass piled at 0 (a variance component near the boundary): the
  # reflected KDE should place the mode at/near 0, not smear it negative.
  v <- abs(rnorm(20000, 0, 0.2))
  m <- posterior_mode(v, lower = 0)
  expect_gte(m, 0)
  expect_lt(m, 0.1)
  # All-equal draws: no density to smooth -> return the common value, not an error.
  expect_equal(posterior_mode(rep(0.4, 100), lower = 0, upper = 1), 0.4)
  # A single draw / empty input degrade gracefully.
  expect_equal(posterior_mode(0.3), 0.3)
  expect_true(is.na(posterior_mode(numeric(0))))
})

# --- posterior_summary(): reduce a draw matrix to point + credible interval ----

test_that("posterior_summary returns a MAP point inside its percentile interval", {
  set.seed(3)
  n <- 4000
  # A plausible two-way posterior: subject/rater/residual variance draws.
  draws <- rbind(
    subject = rgamma(n, 5, 5),
    rater = rgamma(n, 2, 8),
    residual = rgamma(n, 6, 6)
  )
  ests <- list(
    icc_estimand(
      type = "agreement",
      unit = "single",
      raters = "random",
      k_eff = 4
    ),
    icc_estimand(
      type = "consistency",
      unit = "average",
      raters = "random",
      k_eff = 4
    )
  )
  summ <- posterior_summary(draws, ests, conf_level = 0.95)
  expect_length(summ, 2)
  for (s in summ) {
    expect_true(all(
      c("point", "conf.low", "conf.high", "std.error") %in% names(s)
    ))
    expect_gte(s$point, s$conf.low)
    expect_lte(s$point, s$conf.high)
    expect_gte(s$conf.low, 0)
    expect_lte(s$conf.high, 1)
  }
})

# --- O-Bayes: the committed coverage/bias reference (no brms needed) -----------
# The heavy simulation lives in data-raw/oracle-bayesian.R (compile once, update() per
# rep); it reproduces ten Hove et al. (2020)'s DGP through the SHIPPED reduction and
# commits the per-cell bias/coverage/convergence statistics. Here we re-assert that the
# committed reference exhibits the source's reported qualitative findings (§4.2, Figs
# 1-4) -- fast, no fitting, so it runs on every CI job. The tolerances are widened from
# the source's exact bands to absorb our finite n_rep and our INDEPENDENT MAP estimator
# (#4/#18): a coverage oracle reproduces the qualitative findings, and any quantitative
# divergence from the source's own tool is a reported finding, not tuned away.

test_that("O-Bayes: committed reference reproduces ten Hove (2020) findings", {
  fixture <- test_path("fixtures", "bayesian-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian.R to generate"
  )
  ref <- readRDS(fixture)
  s <- ref$stats
  k5 <- s[s$k == 5L, ]
  k2 <- s[s$k == 2L, ]

  # (1) High convergence at the half-t DGP -- their finding was 100%, but they
  #     adaptively doubled warmup; we use a fixed budget, so a minority of the
  #     near-boundary k = 2 reps fall short (a reported divergence, #4/#18).
  expect_true(all(s$converged_frac >= 0.90))

  # (2) sigma_r: the EAP SEVERELY overestimates while the MAP is far less biased
  #     (their Fig 1). We pin the robust, estimator-independent contrast (EAP >> MAP),
  #     not our reflected-KDE MAP's absolute bias (which is modestly negative here --
  #     an independent-estimator divergence that barely moves the ICC).
  expect_gt(k5$eap_sr_relbias, 0.10)
  expect_gt(k5$eap_sr_relbias, k5$map_sr_relbias + 0.10)
  expect_gt(k2$eap_sr_relbias, k2$map_sr_relbias + 0.10)

  # (3) ICC(A,1): MAP unbiased at k = 5, biased low at k = 2, worse at k = 2 (Fig 2).
  expect_lt(abs(k5$map_icc_relbias), 0.10)
  expect_lt(k2$map_icc_relbias, -0.05)
  expect_lt(k2$map_icc_relbias, k5$map_icc_relbias)

  # (4) Percentile 95% credible-interval coverage ~nominal at k = 5; undercovers at
  #     k = 2 (their Figs 3-4; and our k = 2 caveat).
  expect_gte(k5$coverage_icc, 0.90)
  expect_lte(k5$coverage_icc, 0.99)
  expect_lt(k2$coverage_icc, k5$coverage_icc)
})

# --- O-Bayes-ML: the committed multilevel coverage reference (no brms needed, M24) ---
# The multilevel companion to the two-way O-Bayes reference above. data-raw/
# oracle-bayesian-multilevel.R runs ten Hove's crossed Design-1 DGP (N_c = 20) through the
# SHIPPED five-component reduction and commits per-(cell x level) coverage/bias/convergence.
# Here we re-assert the source's qualitative findings -- fast, no fitting, runs on every CI
# job. Tolerances absorb our finite n_rep and INDEPENDENT MAP estimator (#4/#18).

test_that("O-Bayes-ML: committed reference reproduces the multilevel findings", {
  fixture <- test_path("fixtures", "bayesian-ml-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-multilevel.R to generate"
  )
  s <- readRDS(fixture)$stats
  subj <- function(kk) s[s$k == kk & s$level == "subject", ]
  clus <- function(kk) s[s$k == kk & s$level == "cluster", ]

  # (1) High convergence at the half-t DGP across cells (fixed-warmup budget).
  expect_true(all(s$converged_frac >= 0.90))

  # (2) SUBJECT level (de-confounded two-way analog): MAP ~ unbiased and percentile
  #     coverage ~nominal at k = 5 (ten Hove 2022's MCMC ~ MLE, subject level).
  expect_lt(abs(subj(5L)$map_icc_relbias), 0.10)
  expect_gte(subj(5L)$coverage_icc, 0.90)
  expect_lte(subj(5L)$coverage_icc, 0.99)

  # (3) k = 2 at the subject level: the MAP is biased more LOW than at k = 5 (ten Hove's
  #     k = 2 MAP-low finding), while subject-level coverage stays ~nominal at both k -- the
  #     subject level here has 100 subjects, so it is well-powered even at k = 2 and the
  #     undercoverage the two-way N = 30 case showed does not strongly appear.
  expect_lt(subj(2L)$map_icc_relbias, subj(5L)$map_icc_relbias)
  expect_gte(subj(2L)$coverage_icc, 0.90)

  # (4) CLUSTER level, few-cluster caveat (the honest M24 finding): at N_c = 20 the
  #     single-rater cluster MAP is biased LOW vs the subject level (a diffuse near-boundary
  #     sigma^2_c posterior -> the mode of the cluster ICC draws sits below the population).
  expect_lt(clus(5L)$map_icc_relbias, subj(5L)$map_icc_relbias - 0.05)
})

# --- O-Bayes-NML: the committed nested coverage reference (no brms needed, M25) -------
# The nested companion to the crossed O-Bayes-ML reference above. data-raw/
# oracle-bayesian-nested.R runs ten Hove's nested DGP (Design 2 = raters nested in
# clusters, Design 3 = raters nested in subjects; N_c = 20) through the SHIPPED nested
# reductions and commits per-(design x k) SUBJECT-level coverage/bias/convergence. There is
# NO cluster-level cell (nested designs define no cluster IRR), so the M24 few-cluster
# caveat is not exposed. Fast, no fitting, runs on every CI job.

test_that("O-Bayes-NML: committed reference reproduces the nested findings", {
  fixture <- test_path("fixtures", "bayesian-nested-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-nested.R to generate"
  )
  s <- readRDS(fixture)$stats
  d2 <- function(kk) s[s$design == "nested_in_clusters" & s$k == kk, ]
  d3 <- function(kk) s[s$design == "nested_in_subjects" & s$k == kk, ]

  # (1) High convergence at the half-t DGP across cells (fixed-warmup budget).
  expect_true(all(s$converged_frac >= 0.90))

  # (2) Design 2 subject level (the two-way analog): MAP ~ unbiased and percentile coverage
  #     ~nominal at k = 5 (ten Hove 2022 MCMC ~ MLE, subject level).
  expect_lt(abs(d2(5L)$map_icc_relbias), 0.10)
  expect_gte(d2(5L)$coverage_icc, 0.90)
  expect_lte(d2(5L)$coverage_icc, 0.99)

  # (3) Design 3 subject level (the multilevel one-way): MAP ~ unbiased and coverage
  #     ~nominal at BOTH k = 5 and k = 2. THE HONEST FINDING (#18): unlike the crossed
  #     CLUSTER level (M24, MAP biased low at few clusters), the nested SUBJECT level is
  #     well-powered (100 subjects) and stays ~unbiased even at k = 2 -- no boundary-prone
  #     cluster estimand is exposed (nested designs define no cluster ICC). We do NOT import
  #     M24's "k = 2 more biased low" ordering: it does not appear here (both |rel-bias| < .01).
  expect_lt(abs(d3(5L)$map_icc_relbias), 0.10)
  expect_gte(d3(5L)$coverage_icc, 0.90)
  expect_lte(d3(5L)$coverage_icc, 0.99)
  expect_lt(abs(d3(2L)$map_icc_relbias), 0.10)
  expect_gte(d3(2L)$coverage_icc, 0.90)
  expect_lte(d3(2L)$coverage_icc, 0.99)
})

# --- O-Bayes-OW: the committed one-way coverage reference (no brms needed, M26 S1) ---
# The one-way sibling of the O-Bayes / O-Bayes-ML references above. data-raw/
# oracle-bayesian-oneway.R runs a one-way DGP (N = 30, sigma^2_s = sigma^2_res = 0.5 ->
# population ICC(1) = 0.5, an INTERIOR ratio; k in {2, 5}) through the SHIPPED one-way
# reduction (brms_component_draws / posterior_summary on the subject+residual draws) and
# commits per-k coverage/bias/convergence for ICC(1) and ICC(1,k). Fast, no fitting, runs on
# every CI job. THE HONEST FINDING (#18): the a-priori guess -- that the one-way ICC, lacking
# a near-boundary rater variance, would be SPARED the two-way k = 2 bias -- was FALSIFIED by
# the seeded run. The one-way MAP of ICC(1) is biased low at k = 2 (~-13%), the same skewed
# small-sample variance-ratio mechanism as the two-way ICC(A,1); coverage stays ~nominal.
# Observed (n_rep = 150, seed 20260): k = 5 conv 1.00, MAP ICC(1) rel-bias -.008, cover .94,
# ICC(1,k) rel-bias +.002, cover .94; k = 2 conv 1.00, MAP ICC(1) rel-bias -.118, cover .95.

test_that("O-Bayes-OW: committed reference reproduces the one-way findings", {
  fixture <- test_path("fixtures", "bayesian-oneway-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-oneway.R to generate"
  )
  s <- readRDS(fixture)$stats
  k5 <- s[s$k == 5L, ]
  k2 <- s[s$k == 2L, ]

  # (1) High convergence at the half-t DGP across k (interior variance ratio).
  expect_true(all(s$converged_frac >= 0.90))

  # (2) MAP of ICC(1) and ICC(1,k) ~unbiased at k = 5 (|rel bias| < .10).
  expect_lt(abs(k5$map_icc1_relbias), 0.10)
  expect_lt(abs(k5$map_icck_relbias), 0.10)

  # (3) Percentile 95% credible-interval coverage ~nominal at k = 5, both units.
  expect_gte(k5$coverage_icc1, 0.90)
  expect_lte(k5$coverage_icc1, 0.99)
  expect_gte(k5$coverage_icck, 0.90)
  expect_lte(k5$coverage_icck, 0.99)

  # (4) THE HONEST FINDING (#18): the one-way MAP of ICC(1) IS biased low at k = 2 and more
  #     so than at k = 5 -- the one-way analog of the two-way k = 2 caveat, not the a-priori
  #     exemption. Coverage stays ~nominal (the point moves, the interval still brackets).
  expect_lt(k2$map_icc1_relbias, -0.05)
  expect_lt(k2$map_icc1_relbias, k5$map_icc1_relbias)
  expect_gte(k2$coverage_icc1, 0.88)
})

# --- O-Bayes-Fixed: the committed fixed-rater coverage reference (no brms, M26 S2) ---
# The fixed-rater sibling of O-Bayes. data-raw/oracle-bayesian-fixed.R runs a FIXED-rater DGP
# (k = 4 fixed rater means, theta^2_r = 0.2667, N = 30, sigma^2_s = sigma^2_res = 0.5 ->
# population ICC(A,1) = 0.3947) through the SHIPPED fit_brms_fixed() (raw theta^2_r per draw)
# and commits coverage/bias/convergence for ICC(A,1). Fast, no fitting, runs on every CI job.
# Coverage of the fixed-population ICC(A,1) is the calibrated quantity; the MAP is biased low
# by the right-skewed-ICC-draws mode (the standard MAP-below-plug-in skew, ADR-033), reported.
# Observed (n_rep = 200, seed 20261): convergence 1.00, MAP ICC(A,1) rel-bias -.050, coverage .935.

test_that("O-Bayes-Fixed: committed reference reproduces the fixed-rater findings", {
  fixture <- test_path("fixtures", "bayesian-fixed-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-fixed.R to generate"
  )
  s <- readRDS(fixture)$stats

  # (1) High convergence at the half-t DGP.
  expect_gte(s$converged_frac, 0.90)

  # (2) Percentile 95% credible-interval coverage of the fixed-population ICC(A,1) ~nominal.
  expect_gte(s$coverage_icc, 0.88)
  expect_lte(s$coverage_icc, 0.99)

  # (3) The MAP is biased low (the skew) -- characterized, not asserted unbiased (#18).
  expect_lt(s$map_icc_relbias, 0)
})

# --- O-Bayes-FML: the committed crossed FIXED-rater coverage reference (no brms, M27 S1) ---
# The crossed multilevel fixed-rater sibling of O-Bayes-Fixed (single-level) and O-Bayes-ML
# (crossed random). data-raw/oracle-bayesian-multilevel-fixed.R runs a crossed Design-1 DGP
# with FIXED rater means (k = 4, theta^2_r = 0.2667) through the SHIPPED
# fit_brms_multilevel_fixed() recipe (raw theta^2_r per draw injected into the five-component
# `draws`), and commits convergence / CONTAINMENT / coverage / bias for the subject-level
# ICC(A,1). Fast, no fitting, runs on every CI job. The PRIMARY fixed-rater oracle is
# CONTAINMENT -- the glmmTMB M10 REML point inside the brms credible interval -- NOT equality:
# under the prior the balanced fixed ~ random identity holds only approximately (#18). The MAP
# is biased low by the right-skewed-ICC-draws mode (ADR-033), reported. Observed (n_rep = 100,
# seed 20270): see the committed fixture's stats.

test_that("O-Bayes-FML: committed reference reproduces the crossed fixed-rater findings", {
  fixture <- test_path("fixtures", "bayesian-multilevel-fixed-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-multilevel-fixed.R to generate"
  )
  s <- readRDS(fixture)$stats

  # (1) High convergence at the half-t DGP.
  expect_gte(s$converged_frac, 0.90)

  # (2) CONTAINMENT (the primary fixed-rater oracle): the glmmTMB M10 REML subject-level
  #     ICC(A,1) sits inside the brms credible interval ~nominally often. Equality is the
  #     WRONG oracle -- the balanced fixed ~ random identity holds only approximately under
  #     the prior (flat on rater effects vs half-t on the SDs), so we pin containment (#18).
  expect_gte(s$containment_reml, 0.90)

  # (3) Percentile 95% credible-interval coverage of the fixed-population subject-level
  #     ICC(A,1) ~nominal.
  expect_gte(s$coverage_icc, 0.90)
  expect_lte(s$coverage_icc, 0.99)

  # (4) The MAP is ~unbiased -- in the crossed regime the 2b moment correction is ~0, so it
  #     roughly cancels the small mode-below-mean skew; |rel-bias| stays within a few percent
  #     of either sign (characterized, not asserted to a direction, #18).
  expect_lt(abs(s$map_icc_relbias), 0.05)
})

# --- O-Bayes-FNML: the committed nested FIXED-rater coverage reference (no brms, M27 S2) ---
# The nested Design-2 sibling of O-Bayes-FML (crossed). data-raw/oracle-bayesian-nested-fixed.R
# runs a nested Design-2 DGP with FIXED per-cluster rater means through the SHIPPED
# fit_brms_nested_fixed() recipe -- theta^2_{r:c} per draw via the MOMENT-CORRECTED (2b)
# brms_theta2r_nested_draws() with the boundary-aware average-floor (Fable review, ADR-037
# amendment) -- and commits convergence / CONTAINMENT / coverage / bias for the subject-level
# ICC(A,1) across an INTERIOR and a BOUNDARY (theta^2_{r:c} = 0) cell. Fast, no fitting, runs on
# every CI job. History (#18): the RAW push-forward undercovered (interior coverage 0.86, MAP
# -.106) and its coverage -> 0 as clusters accrue; the 2b correction restores nominal coverage.

test_that("O-Bayes-FNML: committed reference reproduces the nested fixed-rater findings", {
  fixture <- test_path("fixtures", "bayesian-nested-fixed-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-nested-fixed.R to generate"
  )
  s <- readRDS(fixture)$stats
  interior <- s[s$cell == "interior", ]
  boundary <- s[s$cell == "boundary", ]

  # (1) High convergence at the half-t DGP, both cells.
  expect_true(all(s$converged_frac >= 0.90))

  # (2) INTERIOR CONTAINMENT (the primary fixed-rater oracle): the glmmTMB M19 REML nested
  #     subject-level ICC(A,1) sits inside the brms credible interval ~nominally often. Fixed !=
  #     random even balanced for nested, so this -- not an identity -- is the pin (#18).
  expect_gte(interior$containment_reml, 0.90)

  # (3) INTERIOR coverage of the fixed-population ICC(A,1) ~nominal -- the 2b moment correction
  #     restores what the RAW push-forward lost (0.86 -> ~0.95, Fable's derived prediction).
  expect_gte(interior$coverage_icc, 0.90)
  expect_lte(interior$coverage_icc, 0.99)

  # (4) BOUNDARY (theta^2_{r:c} = 0): the AVERAGE-floor keeps coverage at or above nominal --
  #     the pin that per-cluster flooring would FAIL (coverage -> 0 at the boundary, #3). The
  #     interior MAP is only mildly low (the residual mode-below-mean skew, ADR-033), reported.
  expect_gte(boundary$coverage_icc, 0.90)
  expect_gt(interior$map_icc_relbias, -0.06)
})

# --- O-Bayes-ML-reduction: subject level composes like two-way (no brms needed) ---
# The subject-level (within-cluster) agreement estimand has signal sigma^2_{s:c} and error
# {rater, residual} -- structurally IDENTICAL to the single-level two-way estimand (M5 §3a;
# M5 O-ML/reduction (a)). So posterior_summary() of a five-row draw matrix at level
# "subject" must equal posterior_summary() of the same subject/rater/residual rows under a
# plain two-way estimand, regardless of the cluster / cluster_rater rows. This pins the
# Bayesian subject-level reduction deterministically, without a Stan fit.

test_that("O-Bayes-ML-reduction: subject-level equals the two-way composition", {
  set.seed(7)
  n <- 4000
  sub <- rgamma(n, 5, 5)
  rat <- rgamma(n, 2, 8)
  res <- rgamma(n, 6, 6)
  ml_draws <- rbind(
    cluster = rgamma(n, 3, 4), # present but must NOT enter the subject-level error set
    subject = sub,
    rater = rat,
    cluster_rater = rgamma(n, 2, 6), # ditto
    residual = res
  )
  tw_draws <- rbind(subject = sub, rater = rat, residual = res)

  for (u in c("single", "average")) {
    ml_est <- icc_estimand(
      type = "agreement",
      unit = u,
      raters = "random",
      k_eff = 4,
      multilevel = TRUE,
      level = "subject"
    )
    tw_est <- icc_estimand(
      type = "agreement",
      unit = u,
      raters = "random",
      k_eff = 4
    )
    ml <- posterior_summary(ml_draws, list(ml_est))[[1]]
    tw <- posterior_summary(tw_draws, list(tw_est))[[1]]
    expect_equal(ml$point, tw$point)
    expect_equal(ml$conf.low, tw$conf.low)
    expect_equal(ml$conf.high, tw$conf.high)
  }
})

# --- Live brms fit: the full pipeline (needs brms + a Stan toolchain) ----------
# This is the ONE test that compiles + samples a real Stan model. It is gated OFF CI:
# a CI runner may have the brms *package* without a working Stan C++ toolchain (Boost/BH,
# compiler), so brms::brm() errors at compile time (`Boost not found`) rather than
# skipping -- and Stan compilation is slow/fragile across the matrix regardless. On CI the
# wiring is covered by the committed O-Bayes fixture (no fitting) plus every non-fitting
# test above; this live smoke test runs locally, where the toolchain is present.

test_that("brms fits the two-way random ICC end to end (O-Bayes-agree sanity)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  # Tiny sampler for a fast wiring check (NOT the coverage oracle -- that is Slice 2's
  # committed reference). Seeded via `seed` -> Stan. Sampling warnings on this 6-subject
  # design (low ESS at tiny iter) are expected and irrelevant to the wiring, so muffle.
  fit <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1000, refresh = 0)
  ))

  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  # samples = post-warmup draws = chains * (iter/2) = 2 * 500.
  expect_identical(fit$ci$samples, 1000L)

  # A default call reports the agreement family (single + average); consistency is a
  # separate call. Both rows must be finite probabilities with the point in its interval.
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(td$estimate >= 0 & td$estimate <= 1))
  expect_true(all(td$conf.low <= td$estimate & td$estimate <= td$conf.high))

  # Wiring sanity (a preview of Slice-2's O-Bayes-agree, not the oracle): the glmmTMB
  # REML point falls inside the brms credible interval. NOTE we do NOT assert MAP ~ REML
  # pointwise -- the MAP is the mode of the ICC DRAWS, not icc_point() of the modal
  # components (MAP(ICC) != icc_point(MAP components), ADR-033), so on a wide skewed
  # n = 6 posterior it legitimately sits below the REML plug-in.
  g <- tidy(icc(d, score, subject, rater, engine = "glmmTMB", seed = 1))
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(g, i)
    expect_gte(reml, td$conf.low[td$index == i])
    expect_lte(reml, td$conf.high[td$index == i])
  }

  # The header reports a Bayesian (MCMC) engine and a CREDIBLE interval (format() is the
  # deterministic source print.icc renders verbatim).
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: one-way random, O-Bayes-OW-agree (M26 Slice 1, ADR-036) ---
# The one-way analogue of the two-way live test above, on the Shrout & Fleiss (1979) Case-1
# data. Gated OFF CI (a CI runner has brms but no Stan toolchain). The numerical coverage
# oracle (O-Bayes-OW) is the committed fixture above; this smoke test wires the two-component
# one-way fit end to end and pins the REDUCTION to the SF anchor: the glmmTMB one-way REML
# point equals the published ICC(1) = 0.166 / ICC(1,k) = 0.443, and it falls inside the brms
# credible interval (MAP-consistent, ten Hove 2022 MCMC ~ MLE; lme4 the second REML oracle).

test_that("brms fits the one-way random ICC end to end (O-Bayes-OW-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  # Tiny sampler for a fast wiring check (NOT the coverage oracle). Sampling warnings on this
  # 6-subject design (low ESS at tiny iter) are expected and irrelevant to the wiring.
  fit <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1000, refresh = 0)
  ))

  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  expect_identical(fit$ci$samples, 1000L)

  # A one-way call reports the single-argument family ICC(1) / ICC(1,k) -- NO agreement/
  # consistency split (raters are interchangeable).
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(1)", "ICC(k)"))
  expect_true(all(td$estimate >= 0 & td$estimate <= 1))
  # The interval is well-ordered and on [0, 1]. We do NOT assert the point lies inside its
  # own credible interval here: on this tiny (n = 6) one-way posterior the MAP piles at the
  # boundary (mode ~ 0) and can sit just BELOW the 2.5% percentile bound -- the mode of the
  # ICC draws is not a percentile, so a boundary MAP legitimately falls outside its own
  # percentile interval (ADR-033; the interval-vs-REML containment is checked below).
  expect_true(all(td$conf.low >= 0 & td$conf.high <= 1))
  expect_true(all(td$conf.low <= td$conf.high))

  # REDUCTION to the SF anchor + O-Bayes-OW-agree: the glmmTMB one-way REML point equals the
  # published SF values and sits inside the brms credible interval (as the two-way live test;
  # we do NOT assert MAP ~ REML pointwise -- the MAP is the mode of the ICC DRAWS, which on a
  # wide skewed n = 6 posterior legitimately sits below the REML plug-in).
  g <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    engine = "glmmTMB",
    seed = 1
  ))
  by_index <- function(x, i) x$estimate[x$index == i]
  expect_equal(by_index(g, "ICC(1)"), 0.166, tolerance = 5e-3)
  expect_equal(by_index(g, "ICC(k)"), 0.443, tolerance = 5e-3)
  for (i in c("ICC(1)", "ICC(k)")) {
    reml <- by_index(g, i)
    expect_gte(reml, td$conf.low[td$index == i])
    expect_lte(reml, td$conf.high[td$index == i])
  }

  # lme4 the second independent REML oracle, when present.
  if (requireNamespace("lme4", quietly = TRUE)) {
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      engine = "lme4",
      seed = 1
    ))
    expect_equal(by_index(l, "ICC(1)"), by_index(g, "ICC(1)"), tolerance = 1e-3)
  }

  # The header reports a Bayesian (MCMC) engine and a CREDIBLE interval.
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: fixed-rater two-way, O-Bayes-Fixed-agree (M26 Slice 2, ADR-036) ---
# The fixed-rater analogue of the two-way live test, on the Shrout & Fleiss (1979) data.
# Gated OFF CI (a CI runner has brms but no Stan toolchain). The committed O-Bayes-Fixed
# fixture is the coverage oracle; this smoke test wires the theta^2_r-from-posterior fit end
# to end and pins the SF reduction: with raters FIXED and balanced data, glmmTMB agreement =
# the two-way random values (SF ICC2 = 0.290 / 0.620, the M10 identity) and glmmTMB
# consistency = SF ICC3 (0.715 / 0.909); each glmmTMB point sits inside the brms credible
# interval (MAP-consistent, containment -- the fixed MAP is the mode of the right-skewed ICC
# draws, which legitimately sits below the REML plug-in, ADR-036).

test_that("brms fits the fixed-rater two-way ICC end to end (O-Bayes-Fixed-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  ba <- list(chains = 2, iter = 1000, refresh = 0)
  fa <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  fc <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  # theta^2_r lives in the rater component slot (subject, rater, residual).
  expect_setequal(names(fa$components), c("subject", "rater", "residual"))

  ta <- tidy(fa)
  tc <- tidy(fc)
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_setequal(tc$index, c("ICC(C,1)", "ICC(C,k)"))
  expect_true(all(
    c(ta$estimate, tc$estimate) >= 0 & c(ta$estimate, tc$estimate) <= 1
  ))

  # SF reduction + containment. glmmTMB fixed: balanced agreement = SF ICC2 (= random, M10
  # identity); consistency = SF ICC3. suppressWarnings mutes the expected fixed-rater advisory.
  gf <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "glmmTMB",
    seed = 1
  )))
  gc <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    engine = "glmmTMB",
    seed = 1
  )))
  by_index <- function(x, i) x$estimate[x$index == i]
  expect_equal(by_index(gf, "ICC(A,1)"), 0.290, tolerance = 5e-3)
  expect_equal(by_index(gf, "ICC(A,k)"), 0.620, tolerance = 5e-3)
  expect_equal(by_index(gc, "ICC(C,1)"), 0.715, tolerance = 5e-3)
  expect_equal(by_index(gc, "ICC(C,k)"), 0.909, tolerance = 5e-3)
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(gf, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
  for (i in c("ICC(C,1)", "ICC(C,k)")) {
    reml <- by_index(gc, i)
    expect_gte(reml, tc$conf.low[tc$index == i])
    expect_lte(reml, tc$conf.high[tc$index == i])
  }
})

# --- Live brms fit: crossed (Design 1) multilevel, O-Bayes-ML-agree (M24 Slice 1) ---
# The Bayesian analogue of the two-way live test above, on ten Hove's flagship design.
# Gated OFF CI for the same reason (a CI runner has the brms package but no Stan C++
# toolchain). The numerical coverage oracle (O-Bayes-ML-coverage) + the sigma^2_c -> 0
# reduction-to-M23 pin are Slice 2's committed fixture; this smoke test wires the
# five-component fit end to end and pins O-Bayes-ML-agree: the MAP tracks the M5 glmmTMB
# REML point (ten Hove 2022: MCMC ~ MLE), with lme4 the second independent REML oracle.

test_that("brms fits the crossed multilevel ICC end to end (O-Bayes-ML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A balanced crossed Design-1 dataset (subjects nested in clusters, raters crossed).
  # ~20 clusters, matching ten Hove et al. (2020)'s DGP (N_c in {20, 40}) so sigma^2_c --
  # and hence the CLUSTER-level ICC -- is identified: at few clusters the cluster-level
  # posterior piles at the boundary and the MAP legitimately collapses toward 0 (ten Hove's
  # few-cluster caveat), which would swamp the agreement check.
  set.seed(2024)
  nc <- 20L
  ns <- 4L
  k <- 3L
  d <- expand.grid(
    s = seq_len(ns),
    rater = factor(seq_len(k)),
    cluster = factor(seq_len(nc))
  )
  d$subject <- factor(paste0(d$cluster, "_", d$s))
  d$score <- 2 +
    rnorm(nc, 0, 0.6)[as.integer(d$cluster)] +
    rnorm(nlevels(d$subject), 0, 1)[as.integer(d$subject)] +
    rnorm(k, 0, 0.4)[as.integer(d$rater)] +
    rnorm(nc * k, 0, 0.3)[as.integer(interaction(d$cluster, d$rater))] +
    rnorm(nrow(d), 0, 0.7)

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  # Structure: the five-component fit yields subject- AND cluster-level rows, a
  # posterior credible interval, and the Bayesian engine label.
  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_setequal(td$level, c("subject", "cluster"))
  # Every row is a valid probability interval. We do NOT assert the MAP point lies inside
  # its own percentile interval: the point (mode of the ICC draws) and the interval
  # (percentiles) come from DIFFERENT reductions of the same posterior (ADR-033), so on a
  # skewed near-boundary component they can legitimately diverge.
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  key <- function(x) paste(x$index, x$level)
  g <- tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "glmmTMB"
  ))
  g <- g[order(key(g)), ]
  td <- td[order(key(td)), ]

  # O-Bayes-ML-agree, robust form (mirrors the two-way live test): the glmmTMB REML point
  # sits inside the brms credible interval for EVERY row -- the credible interval covers
  # MLE, the honest engine-agreement pin. We do NOT assert MAP ~ REML pointwise at every
  # level: the MAP is the mode of the ICC DRAWS (not icc_point() of the modal components,
  # ADR-033), so on a skewed near-boundary component -- notably the single-rater CLUSTER
  # ICC at ~20 clusters, ten Hove's few-cluster caveat -- it legitimately sits below the
  # REML plug-in. That bias is a Slice-2 coverage question (committed fixture), not a wiring
  # failure.
  expect_true(all(g$estimate >= td$conf.low & g$estimate <= td$conf.high))
  # Pointwise MCMC ~ MLE where the estimand is well-identified: the de-confounded SUBJECT
  # level (the two-way analog; ten Hove 2022's MCMC ~ MLE regime).
  subj <- td$level == "subject"
  expect_equal(td$estimate[subj], g$estimate[subj], tolerance = 0.08)

  # The SECOND independent REML oracle (lme4) must concur with glmmTMB -- both fit the
  # identical five-component model (M5 O-ML/lme4). Its multilevel CI needs merDeriv, so run
  # the concurrence only when both are present rather than skip the whole agree oracle.
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    l <- tidy(icc(
      d,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      engine = "lme4"
    ))
    l <- l[order(key(l)), ]
    expect_equal(l$estimate, g$estimate, tolerance = 1e-2)
  }

  # The header renders the Bayesian engine + a credible interval, grouped by level.
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: crossed (Design 1) FIXED raters, O-Bayes-FML-agree (M27 Slice 1) ---
# The fixed-rater analogue of the crossed live test above: raters as a fixed population-level
# effect, theta^2_r read raw per posterior draw into the rater slot of the five-component
# `draws`. SUBJECT LEVEL ONLY (the cluster-level fixed estimand is deferred; the engine-
# agnostic guard forces level = "subject"). Gated OFF CI (brms present, Stan toolchain
# absent). The numerical coverage/containment oracle is O-Bayes-FML's committed fixture; this
# smoke test wires the fit end to end and pins O-Bayes-FML-agree: the glmmTMB M10 REML point
# sits INSIDE the brms credible interval (containment, not equality -- the balanced fixed ~
# random identity holds only approximately under the prior, #18), for both agreement and
# consistency, with lme4 the second independent REML oracle.

test_that("brms fits the crossed fixed-rater multilevel ICC end to end (O-Bayes-FML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A balanced crossed Design-1 dataset (~20 clusters, as the random live test) with FIXED
  # rater means, so theta^2_r is a genuine finite-population variance.
  set.seed(2027)
  nc <- 20L
  ns <- 4L
  mu_r <- c(-0.6, 0, 0.6) # k = 3 fixed rater means
  k <- length(mu_r)
  d <- expand.grid(
    s = seq_len(ns),
    rater = factor(seq_len(k)),
    cluster = factor(seq_len(nc))
  )
  d$subject <- factor(paste0(d$cluster, "_", d$s))
  d$score <- 2 +
    rnorm(nc, 0, 0.6)[as.integer(d$cluster)] +
    rnorm(nlevels(d$subject), 0, 1)[as.integer(d$subject)] +
    mu_r[as.integer(d$rater)] +
    rnorm(nc * k, 0, 0.3)[as.integer(interaction(d$cluster, d$rater))] +
    rnorm(nrow(d), 0, 0.7)

  ba <- list(chains = 2, iter = 1200, refresh = 0)
  fa <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  fc <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    type = "consistency",
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))

  # Structure: the five-component fixed fit yields SUBJECT-level rows only, a posterior
  # credible interval, the Bayesian engine label, and theta^2_r in the rater slot.
  expect_s3_class(fa, "icc")
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  expect_setequal(
    names(fa$components),
    c("cluster", "subject", "rater", "cluster_rater", "residual")
  )
  ta <- tidy(fa)
  tc <- tidy(fc)
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_setequal(tc$index, c("ICC(C,1)", "ICC(C,k)"))
  expect_setequal(ta$level, "subject")
  expect_true(all(
    c(ta$estimate, tc$estimate) >= 0 &
      c(ta$estimate, tc$estimate) <= 1
  ))
  expect_true(all(ta$conf.low <= ta$estimate & ta$estimate <= ta$conf.high))

  # O-Bayes-FML-agree (containment): the glmmTMB M10 crossed fixed REML point sits inside the
  # brms credible interval for every subject-level row (agreement AND consistency). This is
  # the honest engine-agreement pin -- NOT pointwise equality, since the flat rater-effect
  # prior vs half-t on the SDs perturbs the balanced fixed ~ random identity (#18).
  ga <- suppressWarnings(tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    raters = "fixed",
    engine = "glmmTMB"
  )))
  gcons <- suppressWarnings(tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    type = "consistency",
    raters = "fixed",
    engine = "glmmTMB"
  )))
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(ga, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
  for (i in c("ICC(C,1)", "ICC(C,k)")) {
    reml <- by_index(gcons, i)
    expect_gte(reml, tc$conf.low[tc$index == i])
    expect_lte(reml, tc$conf.high[tc$index == i])
  }
  # Pointwise MCMC ~ MLE at the well-identified subject level (ten Hove 2022's MCMC ~ MLE
  # regime; ~80 subjects, so well-powered even at k = 3).
  expect_equal(
    by_index(ta, "ICC(A,1)"),
    by_index(ga, "ICC(A,1)"),
    tolerance = 0.08
  )

  # The SECOND independent REML oracle (lme4) must concur with glmmTMB on the same M10
  # five-component fixed fit; run only when both engines (+ merDeriv) are present.
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    la <- suppressWarnings(tidy(icc(
      d,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      raters = "fixed",
      engine = "lme4"
    )))
    expect_equal(
      by_index(la, "ICC(A,1)"),
      by_index(ga, "ICC(A,1)"),
      tolerance = 1e-2
    )
  }

  # The header renders the Bayesian engine + a credible interval.
  hdr <- paste(format(fa), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: nested Design 2 FIXED raters, O-Bayes-FNML-agree (M27 Slice 2) ---
# The nested-rater analogue of the crossed fixed live test above: raters nested in clusters
# (Design 2), fixed as cell means, theta^2_{r:c} read raw per posterior draw into the rater
# slot of the three-component `draws` (NO cluster / cluster_rater component). SUBJECT LEVEL
# ONLY. Gated OFF CI (brms present, Stan toolchain absent). Pins O-Bayes-FNML-agree: the
# glmmTMB M19 nested-fixed REML point sits INSIDE the brms credible interval (containment --
# and for NESTED designs there is no fixed ~ random identity to lean on, since fixed != random
# even balanced, the M19 catch, #18), for agreement and consistency, lme4 the second oracle.

test_that("brms fits the nested fixed-rater multilevel ICC end to end (O-Bayes-FNML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # Balanced nested Design-2 dataset: raters nested in clusters (cluster-unique labels),
  # crossed with subjects; ~14 clusters so the per-cluster finite population is well-sampled.
  set.seed(2072)
  nc <- 14L
  ns <- 5L
  k <- 3L
  d <- expand.grid(subj = seq_len(ns), rr = seq_len(k), cluster = seq_len(nc))
  cl <- rnorm(nc, 0, 0.7)
  sc <- rnorm(nc * ns, 0, 1.0)
  mu_rc <- rnorm(nc * k, 0, 0.7) # per-cluster fixed rater spread
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    mu_rc[(d$cluster - 1) * k + d$rr] +
    rnorm(nrow(d), 0, 0.5)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rr, sep = "_"))

  ba <- list(chains = 2, iter = 1200, refresh = 0)
  fa <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  fc <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    raters = "fixed",
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))

  # Structure: nested fixed yields SUBJECT-level rows only, with theta^2_{r:c} in the rater
  # slot and NO cluster / cluster_rater component (the cell-mean fit absorbs the cluster).
  expect_s3_class(fa, "icc")
  expect_identical(fa$engine, "brms")
  expect_identical(fa$design$ml_design, "nested_in_clusters")
  expect_setequal(names(fa$components), c("subject", "rater", "residual"))
  ta <- tidy(fa)
  tc <- tidy(fc)
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_setequal(tc$index, c("ICC(C,1)", "ICC(C,k)"))
  expect_setequal(ta$level, "subject")
  expect_true(all(
    c(ta$estimate, tc$estimate) >= 0 & c(ta$estimate, tc$estimate) <= 1
  ))

  # O-Bayes-FNML-agree (containment): the glmmTMB M19 nested fixed REML point sits inside the
  # brms credible interval for every subject-level row (agreement AND consistency). Containment
  # is the pin -- there is NO balanced fixed ~ random identity for nested designs (#18).
  ga <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    engine = "glmmTMB"
  )))
  gcons <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    raters = "fixed",
    engine = "glmmTMB"
  )))
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(ga, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
  for (i in c("ICC(C,1)", "ICC(C,k)")) {
    reml <- by_index(gcons, i)
    expect_gte(reml, tc$conf.low[tc$index == i])
    expect_lte(reml, tc$conf.high[tc$index == i])
  }
  # Pointwise MCMC ~ MLE at the well-identified subject level (~70 subjects).
  expect_equal(
    by_index(ta, "ICC(A,1)"),
    by_index(ga, "ICC(A,1)"),
    tolerance = 0.08
  )

  # The SECOND independent REML oracle (lme4) must concur with glmmTMB on the same M19
  # nested-fixed fit; run only when both engines (+ merDeriv) are present.
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    la <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      engine = "lme4"
    )))
    expect_equal(
      by_index(la, "ICC(A,1)"),
      by_index(ga, "ICC(A,1)"),
      tolerance = 1e-2
    )
  }

  # The header renders the Bayesian engine + a credible interval.
  hdr <- paste(format(fa), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: nested Design 2, O-Bayes-NML-agree (M25 Slice 1, ADR-035) --------
# The nested-rater analogue of the crossed live test above: raters nested in clusters
# (Design 2, four components), so the fit is SUBJECT LEVEL ONLY (cluster-level IRR is
# undefined for nested raters -- ten Hove 2022 p. 6). Gated OFF CI (brms present, Stan
# toolchain absent). Pins O-Bayes-NML-agree: the MAP tracks the M8 glmmTMB REML point
# (ten Hove 2022: MCMC ~ MLE), with lme4 the second independent REML oracle. The
# few-cluster MAP-low caveat that dogged M24's cluster level does NOT apply here --
# sigma^2_c is a fitted nuisance, not a reported estimand.

test_that("brms fits the nested Design 2 ICC end to end (O-Bayes-NML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # Balanced Design 2: subjects nested in clusters, raters NESTED in clusters (each
  # cluster has its own raters, crossed with that cluster's subjects). Cluster-unique
  # rater labels make the nesting explicit. ~16 clusters so sigma^2_{r:c} is well
  # identified across clusters.
  set.seed(2025)
  nc <- 16L
  ns <- 4L
  k <- 3L
  d <- expand.grid(
    s = seq_len(ns),
    rr = seq_len(k),
    cluster = factor(seq_len(nc))
  )
  d$subject <- factor(paste0(d$cluster, "_s", d$s))
  d$rater <- factor(paste0(d$cluster, "_r", d$rr)) # rater nested in cluster
  d$score <- 2 +
    rnorm(nc, 0, 0.6)[as.integer(d$cluster)] +
    rnorm(nlevels(d$subject), 0, 1)[as.integer(d$subject)] +
    rnorm(nlevels(d$rater), 0, 0.4)[as.integer(d$rater)] +
    rnorm(nrow(d), 0, 0.7)

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  # Structure: Design 2 is SUBJECT LEVEL ONLY (no cluster-level row), a posterior
  # credible interval, the Bayesian engine label, and the nested-design report.
  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_setequal(td$level, "subject")
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  key <- function(x) paste(x$index, x$level)
  g <- tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "glmmTMB"
  ))
  g <- g[order(key(g)), ]
  td <- td[order(key(td)), ]

  # O-Bayes-NML-agree: the M8 glmmTMB REML point sits inside the brms credible interval
  # for every (subject-level) row -- the credible interval covers MLE. And because the
  # subject level is well-identified for Design 2 (the two-way analog, no boundary-prone
  # cluster ICC), the MAP tracks REML pointwise within tolerance (ten Hove 2022 MCMC ~ MLE).
  expect_true(all(g$estimate >= td$conf.low & g$estimate <= td$conf.high))
  expect_equal(td$estimate, g$estimate, tolerance = 0.08)

  # The SECOND independent REML oracle (lme4) must concur with glmmTMB -- both fit the
  # identical four-component Design-2 model (M8 O-NML/lme4). Its multilevel CI needs
  # merDeriv, so run the concurrence only when both are present.
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    l <- tidy(icc(
      d,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      engine = "lme4"
    ))
    l <- l[order(key(l)), ]
    expect_equal(l$estimate, g$estimate, tolerance = 1e-2)
  }

  # The header renders the Bayesian engine + a credible interval and names the nested design.
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
  expect_match(hdr, "nested", fixed = TRUE)
})

# --- Live brms fit: nested Design 3, O-Bayes-NML-agree (M25 Slice 2, ADR-035) --------
# Raters nested in SUBJECTS (Design 3, three components) -- the MULTILEVEL ONE-WAY design
# (agreement-only): the rater main effect is confounded into the residual, so only
# ICC(1)/ICC(k) are defined and consistency aborts. Subject level only. Gated OFF CI.
# Pins O-Bayes-NML-agree: the MAP tracks the M8 glmmTMB REML point, lme4 the second REML
# oracle. Also pins O-Bayes-NML-reduction (Design 3 IS a multilevel one-way): with the
# cluster variance negligible, the Design-3 subject ICC matches the flat M6 one-way ICC
# on the same ratings (ten Hove 2022: Design 3 = multilevel one-way).

test_that("brms fits the nested Design 3 ICC end to end (O-Bayes-NML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # Balanced Design 3: subjects nested in clusters, raters NESTED in subjects (each
  # subject has its own raters). Subject-unique rater labels make the nesting explicit.
  set.seed(2026)
  nc <- 14L
  ns <- 4L
  k <- 3L
  d <- expand.grid(
    rr = seq_len(k),
    s = seq_len(ns),
    cluster = factor(seq_len(nc))
  )
  d$subject <- factor(paste0(d$cluster, "_s", d$s))
  d$rater <- factor(paste0(d$subject, "_r", d$rr)) # rater nested in subject
  d$score <- 2 +
    rnorm(nc, 0, 0.5)[as.integer(d$cluster)] +
    rnorm(nlevels(d$subject), 0, 1)[as.integer(d$subject)] +
    rnorm(nlevels(d$rater), 0, 0.4)[as.integer(d$rater)] +
    rnorm(nrow(d), 0, 0.7)

  # Consistency is undefined for Design 3 (no separable rater effect) -- a classed abort,
  # engine-agnostic, reached before the fit.
  expect_error(
    icc(
      d,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      engine = "brms",
      type = "consistency"
    ),
    class = "intraclass_unsupported"
  )

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  # Structure: the multilevel one-way yields ICC(1)/ICC(k) (no A/C letter), subject level
  # only, a posterior credible interval, and the Bayesian engine label.
  expect_s3_class(fit, "icc")
  expect_identical(fit$engine, "brms")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_setequal(td$index, c("ICC(1)", "ICC(k)"))
  expect_setequal(td$level, "subject")
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  key <- function(x) paste(x$index, x$level)
  g <- tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "glmmTMB"
  ))
  g <- g[order(key(g)), ]
  td <- td[order(key(td)), ]

  # O-Bayes-NML-agree (Design 3): the M8 glmmTMB REML point sits inside the brms credible
  # interval, and the MAP tracks REML pointwise (subject level well-identified: 56 subjects).
  expect_true(all(g$estimate >= td$conf.low & g$estimate <= td$conf.high))
  expect_equal(td$estimate, g$estimate, tolerance = 0.08)

  # Second independent REML oracle (lme4), when merDeriv is present.
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    l <- tidy(icc(
      d,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      engine = "lme4"
    ))
    l <- l[order(key(l)), ]
    expect_equal(l$estimate, g$estimate, tolerance = 1e-2)
  }

  # O-Bayes-NML-reduction: Design 3 IS the multilevel one-way. As sigma^2_c -> 0 (M8
  # O-NML/reduction; ten Hove 2022 p. 6), the Design-3 subject ICC equals the flat M6
  # one-way ICC on the same ratings (cluster ignored) -- the estimand identity that names
  # Design 3 a multilevel one-way. Pinned on a NEGLIGIBLE-cluster dataset (with real
  # sigma^2_c the flat one-way absorbs the between-cluster variance into the subject slot
  # and the two diverge). Cheap REML fits (no extra Stan compile); the brms path shares
  # the same estimand map, verified against these fits by the agree pin above.
  set.seed(99)
  d0 <- expand.grid(
    rr = seq_len(k),
    s = seq_len(ns),
    cluster = factor(seq_len(nc))
  )
  d0$subject <- factor(paste0(d0$cluster, "_s", d0$s))
  d0$rater <- factor(paste0(d0$subject, "_r", d0$rr))
  d0$score <- 2 + # sigma^2_c = 0 (no cluster term in the DGP)
    rnorm(nlevels(d0$subject), 0, 1)[as.integer(d0$subject)] +
    rnorm(nlevels(d0$rater), 0, 0.4)[as.integer(d0$rater)] +
    rnorm(nrow(d0), 0, 0.7)
  g0 <- tidy(icc(
    d0,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    engine = "glmmTMB"
  ))
  g0 <- g0[order(g0$index), ]
  ow <- tidy(icc(
    d0,
    score,
    subject,
    rater,
    engine = "glmmTMB",
    model = "oneway"
  ))
  ow <- ow[order(ow$index), ]
  expect_equal(g0$estimate, ow$estimate, tolerance = 0.02)

  # The header names the nested (raters nested in subjects) design + a credible interval.
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
  expect_match(hdr, "nested", fixed = TRUE)
})
