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
  # NB: incomplete/ragged fits now ship for brms at the TWO-WAY single level -- RANDOM
  # (M30 Slice 1, ADR-040) and FIXED-rater (M31 Slice 1, ADR-041; theta^2 under imbalance
  # via the 2b moment correction) -- plus CROSSED (Design 1) MULTILEVEL, RANDOM (M30 Slice 2)
  # and FIXED (M31 Slice 2, subject level), and NESTED Design 2 (raters nested in clusters,
  # M32 Slice 1) and Design 3 (raters nested in subjects, the multilevel one-way, M32 Slice 2)
  # RANDOM (ADR-042), and the SINGLE-LEVEL ONE-WAY (M33 Slice 1, ADR-043; a clean variance-ratio
  # push-forward, no theta^2) -- see the O-Bayes-Incomplete / O-Bayes-IFixed / O-Bayes-IML /
  # O-Bayes-IFML-fixed / O-Bayes-INML-clusters / O-Bayes-INML-subjects / O-Bayes-IOneway live +
  # fixture tests below. What stays deferred (and aborts BEFORE any fit, no Stan needed): incomplete
  # FIXED nested (Designs 2/3, no frequentist oracle) and incomplete within-cell REPLICATES. Each
  # must name the supported scope (#5/#8).
  d_inc <- d[-1, , drop = FALSE] # ragged two-way (one cell dropped)
  # incomplete FIXED-rater NESTED multilevel (Design 2, still deferred): raters nested in
  # clusters (cluster-unique labels), fixed, one cell dropped. (suppressWarnings: the
  # fixed-rater nudge fires before the abort.)
  dnf <- expand.grid(r_in_c = 1:2, s = 1:3, cluster = factor(1:2))
  dnf$subject <- factor(paste0(dnf$cluster, "_", dnf$s))
  dnf$rater <- factor(paste0(dnf$cluster, "_r", dnf$r_in_c))
  dnf$score <- as.numeric(seq_len(nrow(dnf)))
  dnf_inc <- dnf[-1, , drop = FALSE]
  expect_error(
    suppressWarnings(
      icc(
        dnf_inc,
        score,
        rater,
        subject = subject,
        cluster = cluster,
        raters = "fixed",
        engine = "brms"
      )
    ),
    class = "intraclass_unsupported"
  )
  # incomplete within-cell REPLICATES (still deferred): >1 rating per subject x rater cell, ragged.
  d_rep <- data.frame(
    subject = factor(c(1, 1, 1, 2, 2, 2, 3, 3)),
    rater = factor(c(1, 1, 2, 1, 2, 2, 1, 2)),
    score = c(1, 1.2, 2, 3, 3.5, 3.2, 2, 2.4)
  )
  expect_error(
    icc(d_rep, score, subject, rater, engine = "brms"),
    class = "intraclass_unsupported"
  )
  # NB: incomplete SINGLE-LEVEL one-way now ships for brms (M33 Slice 1) -- asserted supported by
  # the O-Bayes-IOneway live + fixture tests below.
  # NB: incomplete NESTED multilevel RANDOM now ships for brms -- Design 2 (M32 Slice 1) and
  # Design 3 (M32 Slice 2) -- asserted supported by the O-Bayes-INML-clusters / -subjects live +
  # fixture tests below. Incomplete FIXED nested stays deferred (dnf_inc above; no frequentist
  # oracle, all engines, ADR-029/ADR-042).
  # NB: fixed-rater MULTILEVEL now ships for brms -- single-level (M26 Slice 2), crossed
  # Design 1 (M27 Slice 1), and nested Design 2 (M27 Slice 2). Design 3 fixed stays refused
  # (by design, all engines -- no separable rater effect), asserted engine-agnostically in
  # test-icc-fixed-multilevel.R; the live O-Bayes-FML-agree / O-Bayes-FNML-agree fits below
  # assert the crossed and nested fixed paths are *supported*.
})

# M29 Slice 2 ships SINGLE-LEVEL two-way RANDOM within-cell replicates for brms (the live
# O-Bayes-Rep-agree fit below). The compound replicate corners -- fixed-rater replicates and
# multilevel replicates -- stay deferred (the Bayesian siblings of the M20 Slice 1/2
# frequentist deferrals) and abort loudly BEFORE any fit dispatch (no Stan needed).
test_that("brms refuses the fixed-rater and multilevel replicate corners", {
  set.seed(30)
  # Replicated single-level data: 2 ratings per subject x rater cell.
  base <- expand.grid(rep = 1:2, rater = factor(1:3), subject = factor(1:6))
  base$score <- rnorm(nrow(base))
  d <- base[, c("subject", "rater", "score")]
  # Fixed-rater replicates: deferred. (suppressWarnings: the fixed-rater nudge fires
  # before the abort; we assert the abort, not the nudge.)
  expect_error(
    suppressWarnings(
      icc(d, score, rater, subject = subject, raters = "fixed", engine = "brms")
    ),
    class = "intraclass_unsupported"
  )
  # Multilevel replicates: deferred. Well-formed crossed Design 1 with 2 ratings per
  # subject x rater cell (subjects nested in clusters, raters crossed).
  dm <- expand.grid(
    rep = 1:2,
    rater = factor(1:3),
    s = 1:3,
    cluster = factor(1:2)
  )
  dm$subject <- factor(paste0(dm$cluster, "_", dm$s))
  dm$score <- rnorm(nrow(dm))
  expect_error(
    icc(
      dm,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      engine = "brms"
    ),
    class = "intraclass_unsupported"
  )
})

# M24 (ADR-034) opened the CROSSED (Design 1) multilevel random path for brms; M25
# (ADR-035) adds both NESTED designs -- Design 2 (raters nested in clusters, Slice 1) and
# Design 3 (raters nested in subjects, Slice 2); M29 (ADR-039) adds the CONFLATED diagnostic
# (Eq. 14) off the crossed fit. All three multilevel designs plus the conflated level are now
# supported at the subject level for brms (the live O-Bayes-*-agree fits below assert the
# designs, O-Bayes-Conflated the conflated path). What stays refused for a conflated brms call
# is engine-agnostic and fires BEFORE any fit dispatch (no Stan needed): the consistency and
# fixed-rater conflated forms are not sourced / not defined by Eq. 14 (M17-conflated-icc.md).

test_that("brms refuses the consistency / fixed conflated forms (engine-agnostic)", {
  set.seed(12)
  crossed <- expand.grid(
    subject = 1:4,
    rater = factor(1:3),
    cluster = factor(1:3)
  )
  crossed$subject <- factor(paste0(crossed$cluster, "_", crossed$subject))
  crossed$score <- rnorm(nrow(crossed))
  # Consistency conflated is not sourced (ten Hove Eq. 14 is agreement-only).
  expect_error(
    icc(
      crossed,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      level = "conflated",
      type = "consistency",
      engine = "brms"
    ),
    class = "intraclass_unsupported"
  )
  # Fixed-rater conflated is not defined (Eq. 14 treats the rater as a variance component).
  expect_error(
    icc(
      crossed,
      score,
      rater,
      subject = subject,
      cluster = cluster,
      level = "conflated",
      raters = "fixed",
      engine = "brms"
    ),
    class = "intraclass_unsupported"
  )
})

# O-Eq14 (Bayesian wiring, no brms/Stan needed): the conflated ICC is a VARIANCE-RATIO
# push-forward that composes off the SAME five-component posterior draws as the subject/cluster
# levels -- signal = cluster + subject, error = rater + cluster_rater + residual (Eq. 14). We
# assert posterior_summary() reproduces the closed-form Eq. 14 identity per draw (independent of
# the estimator's own ICC arithmetic path) and that the conflated level is DISTINCT from the
# subject level. This is the O-Eq14 analog of the frequentist conflated oracle (M17 S1, §5).
test_that("O-Eq14: brms conflated composes off the five-component draws per Eq. 14", {
  set.seed(29)
  nd <- 4000L
  draws <- rbind(
    cluster = rgamma(nd, 3, 2),
    subject = rgamma(nd, 3, 2),
    rater = rgamma(nd, 1, 5),
    cluster_rater = rgamma(nd, 1, 8),
    residual = rgamma(nd, 4, 2)
  )
  k <- 5L
  conf <- icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    multilevel = TRUE,
    level = "conflated"
  )
  subj <- icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    multilevel = TRUE,
    level = "subject"
  )
  expect_identical(conf$signal, c("cluster", "subject"))
  expect_identical(conf$error, c("rater", "cluster_rater", "residual"))

  summ <- posterior_summary(draws, list(conflated = conf, subject = subj))
  # Closed-form Eq. 14 per draw (single rater), composed independently of icc_point().
  sig <- draws["cluster", ] + draws["subject", ]
  err <- draws["rater", ] + draws["cluster_rater", ] + draws["residual", ]
  hand <- sig / (sig + err)
  # The MAP is the mode of the ICC draws; recompute it the same way and match to ~1e-10.
  expect_equal(summ$conflated$point, posterior_mode(hand, lower = 0, upper = 1))
  expect_equal(
    unname(quantile(hand, 0.025)),
    summ$conflated$conf.low,
    tolerance = 1e-8
  )
  expect_equal(
    unname(quantile(hand, 0.975)),
    summ$conflated$conf.high,
    tolerance = 1e-8
  )
  # Conflated ∈ [0, 1], distinct from the subject level, and carries a CI (never a bare point).
  expect_gte(summ$conflated$point, 0)
  expect_lte(summ$conflated$point, 1)
  expect_false(isTRUE(all.equal(summ$conflated$point, summ$subject$point)))
  expect_true(
    is.finite(summ$conflated$conf.low) && is.finite(summ$conflated$conf.high)
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

# --- O-Bayes-Conflated: the committed conflated coverage reference (no brms needed, M29) ---
# The conflated (Eq. 14) sibling of the O-Bayes-ML reference. data-raw/
# oracle-bayesian-conflated.R runs a crossed Design-1 DGP with a LARGE between-cluster
# variance (so the conflated ICC clearly overstates the subject level) through the SHIPPED
# five-component fit read via the conflated estimand, and commits per-run coverage of the
# known Eq. 14 value, containment of the frequentist glmmTMB conflated point, and the
# distinctness gap vs the subject level. Fast, no fitting, runs on every CI job. Tolerances
# absorb the finite n_rep and the INDEPENDENT MAP estimator (#4/#18); the conflated inherits
# the cluster level's few-cluster sigma^2_c caveat, so COVERAGE (not the point) is the pin.

test_that("O-Bayes-Conflated: committed reference reproduces the conflated findings", {
  fixture <- test_path("fixtures", "bayesian-conflated-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-conflated.R to generate"
  )
  s <- readRDS(fixture)$stats

  # (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
  expect_gte(s$converged_frac, 0.90)

  # (2) The conflated credible interval COVERS the known Eq. 14 value ~nominally (the honest
  #     recovery check, M17 §5 O-population; the point may be biased by the few-cluster
  #     sigma^2_c, so coverage -- not the point -- is the pin).
  expect_gte(s$coverage_conflated, 0.90)
  expect_lte(s$coverage_conflated, 0.99)

  # (3) CONTAINMENT (O-Eq14/O-lme4 analog): the frequentist glmmTMB conflated point -- which
  #     composes the SAME Eq. 14 -- falls inside the brms credible interval for ~all reps; the
  #     two engines differ only by the prior (the M26 containment posture, not pointwise equality).
  expect_gte(s$containment_glmmtmb, 0.90)

  # (4) DISTINCTNESS: the conflated ICC sits visibly ABOVE the subject level (Eq. 14 folds the
  #     large between-cluster variance into the signal) -- the diagnostic's whole point.
  expect_gt(s$map_minus_subject, 0.05)
})

# --- O-Bayes-Incomplete: the committed ragged coverage reference (no brms needed, M30 S1) ---
# The incomplete/ragged sibling of the O-Bayes reference above. data-raw/
# oracle-bayesian-incomplete.R runs the ten Hove (2020) two-way random DGP at k = 5 in two
# cells -- a COMPLETE 30 x 5 grid (k_eff = k, the shipped M23 reduction) and a FIXED, connected
# RAGGED incidence (~20% cells deleted, constant k_eff < 5) -- through the SHIPPED
# fit-then-reduce recipe, and commits per-cell coverage of ICC(A,1) (no divisor) and
# ICC(A, k_eff) (the harmonic-mean divisor is exercised), MAP relative bias, and convergence.
# Fast, no fitting, runs on every CI job. The milestone's one genuine unknown is whether the
# percentile credible interval COVERS on ragged data (#1); the pin checks the ragged cell tracks
# the complete cell within Monte-Carlo error (SE(coverage) ~ .015 at n_rep = 200). If a real
# shortfall appears it is REPORTED (#18) and gates a Fable review (#19), never tuned away (#4).
test_that("O-Bayes-Incomplete: committed reference covers ragged two-way random data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor: k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells (k = 5, past the k = 2 caveat).
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete path IS the shipped M23 path (k_eff = k),
  #     so both units cover ~nominal -- the baseline the ragged cell is judged against.
  expect_gte(cmp$coverage_icc1, 0.90)
  expect_lte(cmp$coverage_icc1, 0.99)
  expect_gte(cmp$coverage_icck, 0.90)
  expect_lte(cmp$coverage_icck, 0.99)

  # (3) COVERAGE ON RAGGED DATA (the milestone's one unknown, #1/#18): ragged coverage tracks
  #     the complete cell within Monte-Carlo error, and stays ~nominal for BOTH the divisor-free
  #     ICC(A,1) and the k_eff-divided ICC(A, k_eff). A > ~.05 shortfall would be a real finding.
  expect_gte(rag$coverage_icc1, cmp$coverage_icc1 - 0.05)
  expect_gte(rag$coverage_icck, cmp$coverage_icck - 0.05)
  expect_gte(rag$coverage_icc1, 0.90)
  expect_gte(rag$coverage_icck, 0.90)

  # (4) MAP tracks the population in both cells (small negative skew, the M23/M26 posture).
  expect_lt(abs(cmp$map_icc1_relbias), 0.10)
  expect_lt(abs(rag$map_icc1_relbias), 0.12)
})

# --- O-Bayes-IML: the committed ragged crossed-multilevel coverage reference (M30 S2) ---
# The incomplete crossed (Design 1) MULTILEVEL sibling of O-Bayes-Incomplete. data-raw/
# oracle-bayesian-incomplete-multilevel.R runs the ten Hove (2022) five-component crossed DGP
# in a COMPLETE cell (k_eff = k, the M24 reduction) and a FIXED, connected RAGGED cell
# (~12% cells deleted, constant k_eff < 5) through the SHIPPED fit_brms_multilevel() +
# reduce recipe, and commits per-cell SUBJECT-level ICC(A,1) & ICC(A,k_eff) coverage (the
# k_eff divisor is exercised) plus the single-rater CLUSTER ICC(c,1) coverage. The averaged
# cluster ICC(c,k) is undefined on incomplete data (dropped-with-note), so it is not tallied.
# Fast, no fitting, runs on every CI job. Subject-level coverage is the pin; the cluster level
# inherits the M24 few-cluster caveat, so it is CHARACTERIZED (ragged tracks complete), not
# pinned nominal (#18).
test_that("O-Bayes-IML: committed reference covers ragged crossed multilevel random data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-ml-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-multilevel.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor: k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells.
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete path IS the shipped M24 path (k_eff = k),
  #     so subject-level coverage is ~nominal -- the baseline the ragged cell is judged against.
  expect_gte(cmp$coverage_subj1, 0.90)
  expect_lte(cmp$coverage_subj1, 0.99)
  expect_gte(cmp$coverage_subjk, 0.90)
  expect_lte(cmp$coverage_subjk, 0.99)

  # (3) SUBJECT-LEVEL COVERAGE ON RAGGED DATA (the Slice-2 unknown, #1/#18): ragged subject
  #     coverage tracks the complete cell within Monte-Carlo error and stays ~nominal for BOTH
  #     the divisor-free ICC(A,1) and the k_eff-divided ICC(A, k_eff).
  expect_gte(rag$coverage_subj1, cmp$coverage_subj1 - 0.06)
  expect_gte(rag$coverage_subjk, cmp$coverage_subjk - 0.06)
  expect_gte(rag$coverage_subj1, 0.88)
  expect_gte(rag$coverage_subjk, 0.88)

  # (4) CLUSTER ICC(c,1) is CHARACTERIZED, not pinned nominal (the M24 few-cluster caveat):
  #     ragged coverage tracks the complete cell. ICC(c,k) is dropped-with-note (not tallied).
  expect_gte(rag$coverage_clus1, cmp$coverage_clus1 - 0.06)

  # (5) Subject MAP tracks the population in both cells (small skew, the M23/M26 posture).
  expect_lt(abs(cmp$map_subj1_relbias), 0.10)
  expect_lt(abs(rag$map_subj1_relbias), 0.12)
})

# --- O-Bayes-INML-clusters: committed ragged NESTED D2 coverage reference (no brms, M32 S1) ---
# The incomplete/ragged NESTED Design-2 (raters nested in clusters) sibling of O-Bayes-IML
# (crossed) and the ragged extension of O-Bayes-NML (balanced nested). data-raw/
# oracle-bayesian-incomplete-nested.R runs the ten Hove (2022) four-component nested DGP in a
# COMPLETE cell (k_eff = k, the M25 Slice 1 reduction) and a FIXED, connected RAGGED cell
# (~12% cells deleted, constant k_eff < 5) through the SHIPPED fit_brms_nested_clusters() + reduce
# recipe, and commits per-cell SUBJECT-level ICC(A,1) & ICC(A,k_eff) coverage (the harmonic-mean
# k_eff divisor is exercised). Random raters -> a clean variance-ratio push-forward (NO theta^2
# functional, so NO 2b moment correction), so ~nominal coverage is expected (the M30 regime, not
# the M31 fixed regime). There is no cluster-level cell (nested designs define no cluster IRR).
# Fast, no fitting, runs on every CI job. If a real shortfall appears it is REPORTED (#18) and
# gates a Fable review (#19), never tuned away (#4).
test_that("O-Bayes-INML-clusters: committed reference covers ragged nested Design-2 random data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-nested-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-nested.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor: k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells.
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete path IS the shipped M25 Slice 1 nested path
  #     (k_eff = k), so subject-level coverage is ~nominal -- the baseline the ragged cell is
  #     judged against.
  expect_gte(cmp$coverage_a1, 0.90)
  expect_lte(cmp$coverage_a1, 0.99)
  expect_gte(cmp$coverage_ak, 0.90)
  expect_lte(cmp$coverage_ak, 0.99)

  # (3) COVERAGE ON RAGGED DATA (the milestone's one unknown, #1/#18): random raters give a clean
  #     variance-ratio push-forward (no 2b), so ragged coverage tracks the complete cell within
  #     Monte-Carlo error and stays ~nominal for BOTH the divisor-free ICC(A,1) and the
  #     k_eff-divided ICC(A, k_eff). A > ~.06 shortfall would be a real finding.
  expect_gte(rag$coverage_a1, cmp$coverage_a1 - 0.06)
  expect_gte(rag$coverage_ak, cmp$coverage_ak - 0.06)
  expect_gte(rag$coverage_a1, 0.88)
  expect_gte(rag$coverage_ak, 0.88)

  # (4) Subject MAP tracks the population in both cells (small skew, the M23/M25 posture).
  expect_lt(abs(cmp$relbias_a1), 0.10)
  expect_lt(abs(rag$relbias_a1), 0.12)
})

# --- O-Bayes-INML-subjects: committed ragged NESTED D3 coverage reference (no brms, M32 S2) ---
# The incomplete/ragged NESTED Design-3 (raters nested in subjects, the multilevel ONE-WAY,
# agreement-only) sibling of O-Bayes-INML-clusters. data-raw/oracle-bayesian-incomplete-nested-subjects.R
# runs the ten Hove (2022) three-component Design-3 DGP in a COMPLETE cell (k_eff = k, the M25
# Slice 2 reduction) and a FIXED, connected RAGGED cell (~12% cells deleted, constant k_eff < 5)
# through the SHIPPED fit_brms_nested_subjects() + reduce recipe, and commits per-cell SUBJECT-level
# one-way ICC(1) & ICC(k_eff) coverage (the harmonic-mean k_eff divisor is exercised). In Design 3
# the rater main effect is confounded into the residual, so there is no consistency coefficient and
# no cluster level. Random raters -> a clean variance-ratio push-forward (NO 2b), so ~nominal
# coverage is expected (the M30 regime). Fast, no fitting, runs on every CI job.
#
# HISTORY (#18): the FIRST committed run (n_rep 80) drew a ragged cell of .8625 -- a ~.002
# Monte-Carlo tail event that fired the ragged >= .88 pin. A gated Fable review (#19; ADR-042
# Amendment 2, data-raw/reviews/fable-review-m32-s2-response.md) re-ran the SAME incidence at
# n = 240 -> .9458, four fresh incidences -> .9500, and a 2,000-fit frequentist arm -> .9555, with
# a uniform PIT (the interval is calibrated). Verdict: NO estimator shortfall. The fixture was
# regenerated at n_rep = 240 + per-rep seeding (a precision upgrade, not tuning) and the pins below
# are UNCHANGED (ragged >= .88 was NOT loosened, #4). A regenerated ragged cell < .90 would reopen
# the review (~1e-5 under the verdict).
test_that("O-Bayes-INML-subjects: committed reference covers ragged nested Design-3 random data", {
  fixture <- test_path(
    "fixtures",
    "bayesian-incomplete-nested-subjects-oracle.rds"
  )
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-nested-subjects.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor: k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells.
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete path IS the shipped M25 Slice 2 nested path
  #     (k_eff = k), so subject-level coverage is ~nominal -- the baseline the ragged cell is
  #     judged against.
  expect_gte(cmp$coverage_a1, 0.90)
  expect_lte(cmp$coverage_a1, 0.99)
  expect_gte(cmp$coverage_ak, 0.90)
  expect_lte(cmp$coverage_ak, 0.99)

  # (3) COVERAGE ON RAGGED DATA (the milestone's one unknown, #1/#18): random raters give a clean
  #     variance-ratio push-forward (no 2b), so ragged coverage tracks the complete cell within
  #     Monte-Carlo error and stays ~nominal for BOTH the divisor-free ICC(1) and the
  #     k_eff-divided ICC(k_eff). A > ~.06 shortfall would be a real finding.
  expect_gte(rag$coverage_a1, cmp$coverage_a1 - 0.06)
  expect_gte(rag$coverage_ak, cmp$coverage_ak - 0.06)
  expect_gte(rag$coverage_a1, 0.88)
  expect_gte(rag$coverage_ak, 0.88)

  # (4) Subject MAP tracks the population in both cells (small skew, the M25 well-powered posture).
  expect_lt(abs(cmp$relbias_a1), 0.10)
  expect_lt(abs(rag$relbias_a1), 0.12)
})

# --- O-Bayes-IOneway: committed ragged SINGLE-LEVEL ONE-WAY coverage reference (no brms, M33 S1) ---
# The incomplete/ragged single-level ONE-WAY (Shrout & Fleiss Case 1) sibling of O-Bayes-Incomplete
# (two-way). data-raw/oracle-bayesian-incomplete-oneway.R runs the one-way DGP (Y = mu_s + e) in a
# COMPLETE cell (k_eff = k = 5, the M26 Slice 1 reduction) and a FIXED RAGGED cell (~20% of the
# rating slots deleted, constant k_eff < 5) through the SHIPPED fit_brms_oneway() + reduce recipe,
# and commits per-cell ICC(1) & ICC(1, k_eff) coverage (the harmonic-mean k_eff divisor is exercised
# on the average unit). One-way is RANDOM -> a clean variance-ratio push-forward (NO theta^2, NO 2b),
# so ~nominal coverage is expected (the M30 regime, not the M31 fixed regime). n_rep = 240 + per-rep
# seeding (the M32 Slice 2 convention, ADR-042 Amendment 2). Fast, no fitting, runs on every CI job.
test_that("O-Bayes-IOneway: committed reference covers ragged one-way random data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-oneway-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-oneway.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor: k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells (k = 5, past the k = 2 caveat).
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete path IS the shipped M26 Slice 1 one-way path
  #     (k_eff = k), so both units cover ~nominal -- the baseline the ragged cell is judged against.
  expect_gte(cmp$coverage_icc1, 0.90)
  expect_lte(cmp$coverage_icc1, 0.99)
  expect_gte(cmp$coverage_icck, 0.90)
  expect_lte(cmp$coverage_icck, 0.99)

  # (3) COVERAGE ON RAGGED DATA (the slice's one unknown, #1/#18): random raters give a clean
  #     variance-ratio push-forward (no 2b), so ragged coverage tracks the complete cell within
  #     Monte-Carlo error and stays ~nominal for BOTH the divisor-free ICC(1) and the k_eff-divided
  #     ICC(1, k_eff). A > ~.06 shortfall would be a real finding -> characterize honestly (#18) and
  #     recommend a gated Fable review (#19), do NOT loosen the pin (#4).
  expect_gte(rag$coverage_icc1, cmp$coverage_icc1 - 0.06)
  expect_gte(rag$coverage_icck, cmp$coverage_icck - 0.06)
  expect_gte(rag$coverage_icc1, 0.88)
  expect_gte(rag$coverage_icck, 0.88)

  # (4) MAP tracks the population in both cells (small negative skew, the M26 one-way posture).
  expect_lt(abs(cmp$map_icc1_relbias), 0.10)
  expect_lt(abs(rag$map_icc1_relbias), 0.12)
})

# --- O-Bayes-IFixed: committed ragged FIXED-rater coverage reference (no brms, M31 S1) ---
# The incomplete/ragged FIXED-rater sibling of O-Bayes-Incomplete (random) and O-Bayes-Fixed
# (balanced). data-raw/oracle-bayesian-incomplete-fixed.R runs the McGraw & Wong Case-3A fixed
# DGP (k = 5, fixed rater means) at ten Hove's half-t(4,0,1) prior in two cells -- a COMPLETE
# 30 x 5 grid (k_eff = k, b ~= 0, the shipped M26 reduction) and a FIXED, connected RAGGED
# incidence (~20% cells deleted, constant k_eff < 5, b != 0) -- through the SHIPPED
# brms_theta2r_draws() (the 2b + boundary-aware average-floor moment correction). The genuine
# unknown (#1): unlike the RANDOM incomplete path (a clean variance-ratio push-forward, M30),
# the fixed theta^2_r is a convex quadratic functional whose 2b correction goes LIVE at the
# single level for the FIRST time on ragged data (b != 0 once the rater means come from unequal
# cell counts; b ~= 0 balanced). The pin checks the ragged cell tracks the complete cell within
# Monte-Carlo error (SE(coverage) ~ .015 at n_rep = 200). A real shortfall is REPORTED (#18) and
# gates a Fable review (#19), never tuned away (#4). Fast, no fitting, runs on every CI job.
test_that("O-Bayes-IFixed: committed reference covers ragged two-way fixed-rater data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-fixed-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-fixed.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor AND activates the 2b correction (b != 0):
  # k_eff strictly below k = 5.
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells (k = 5, past the k = 2 caveat).
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete fixed path IS the shipped M26 fixed path
  #     (k_eff = k, b ~= 0), so both units cover ~nominal -- the baseline the ragged cell is
  #     judged against.
  expect_gte(cmp$coverage_icc1, 0.88)
  expect_lte(cmp$coverage_icc1, 0.99)
  expect_gte(cmp$coverage_icck, 0.88)
  expect_lte(cmp$coverage_icck, 0.99)

  # (3) COVERAGE ON RAGGED DATA (the milestone's one unknown, #1/#18): with the 2b moment
  #     correction LIVE single-level (b != 0), ragged coverage tracks the complete cell within
  #     Monte-Carlo error and stays ~nominal for BOTH the divisor-free ICC(A,1) and the
  #     k_eff-divided ICC(A, k_eff). A > ~.05 shortfall would be a real finding.
  expect_gte(rag$coverage_icc1, cmp$coverage_icc1 - 0.05)
  expect_gte(rag$coverage_icck, cmp$coverage_icck - 0.05)
  expect_gte(rag$coverage_icc1, 0.88)
  expect_gte(rag$coverage_icck, 0.88)

  # (4) MAP is biased low (the mode of the right-skewed ICC draws sits below the population
  #     plug-in, the M23/M26 posture) -- characterized, not asserted unbiased.
  expect_lt(cmp$map_icc1_relbias, 0.02)
  expect_lt(rag$map_icc1_relbias, 0.02)
})

# --- O-Bayes-IFML-fixed: committed ragged crossed FIXED multilevel coverage (no brms, M31 S2) ---
# The crossed (Design 1) MULTILEVEL FIXED-rater sibling of O-Bayes-IFixed (single-level fixed) and
# O-Bayes-IML (crossed multilevel random). data-raw/oracle-bayesian-incomplete-fixed-multilevel.R
# runs the ten Hove (2022) crossed five-component DGP with FIXED rater means (k = 5) in two cells --
# a COMPLETE grid (k_eff = k, b ~= 0, the shipped M27-Slice-1 reduction) and a FIXED, connected
# RAGGED incidence (~12% cells deleted, constant k_eff < 5, b != 0) -- through the SHIPPED
# fit_brms_multilevel_fixed() recipe (brms_theta2r_draws() with the 2b + average-floor moment
# correction). SUBJECT LEVEL ONLY (fixed cluster-level IRR is deferred for all engines). The
# unknown (#1): whether the percentile credible interval COVERS on ragged crossed data once the 2b
# correction is active in the multilevel fixed regime. The pin checks the ragged cell tracks the
# complete cell within Monte-Carlo error. A real shortfall is REPORTED (#18) and gates a Fable
# review (#19), never tuned away (#4). Fast, no fitting, runs on every CI job.
test_that("O-Bayes-IFML-fixed: committed reference covers ragged crossed fixed multilevel data", {
  fixture <- test_path("fixtures", "bayesian-incomplete-fixed-ml-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-incomplete-fixed-multilevel.R to generate"
  )
  s <- readRDS(fixture)$stats
  cmp <- s[s$design == "complete", ]
  rag <- s[s$design == "ragged", ]

  # The ragged cell exercises the k_eff divisor AND activates the 2b correction (b != 0).
  expect_lt(rag$k_eff, 5)
  expect_equal(cmp$k_eff, 5)

  # (1) High convergence at the half-t DGP in both cells.
  expect_gte(cmp$converged_frac, 0.90)
  expect_gte(rag$converged_frac, 0.90)

  # (2) REDUCTION: on complete data the incomplete fixed multilevel path IS the shipped M27-S1
  #     fixed path (k_eff = k, b ~= 0), so subject-level coverage is ~nominal.
  expect_gte(cmp$coverage_subj1, 0.88)
  expect_lte(cmp$coverage_subj1, 0.99)
  expect_gte(cmp$coverage_subjk, 0.88)
  expect_lte(cmp$coverage_subjk, 0.99)

  # (3) SUBJECT-LEVEL COVERAGE ON RAGGED DATA (the Slice-2 unknown, #1/#18): ragged subject
  #     coverage tracks the complete cell within Monte-Carlo error and stays ~nominal for BOTH
  #     the divisor-free ICC(A,1) and the k_eff-divided ICC(A, k_eff).
  expect_gte(rag$coverage_subj1, cmp$coverage_subj1 - 0.06)
  expect_gte(rag$coverage_subjk, cmp$coverage_subjk - 0.06)
  expect_gte(rag$coverage_subj1, 0.88)
  expect_gte(rag$coverage_subjk, 0.88)

  # (4) Subject MAP tracks the population in both cells (small skew, the M23/M26 posture).
  expect_lt(abs(cmp$map_subj1_relbias), 0.10)
  expect_lt(abs(rag$map_subj1_relbias), 0.12)
})

# O-Bayes-Rep wiring (no brms/Stan needed, M29 Slice 2): the within-cell-replicate ICC is a
# VARIANCE-RATIO push-forward that composes off the SAME four-component posterior draws as any
# two-way ICC -- signal = subject, error = rater + subject_rater + residual -- with the
# `occasions` averaging dividing PURE ERROR (not the interaction) by n_o PER DRAW. We assert
# posterior_summary() reproduces that closed form per draw and that the average-occasion ICC
# exceeds the single-occasion one draw-for-draw (occasion averaging reduces pure error).
test_that("O-Bayes-Rep-wiring: brms replicates compose the occasion divisor per draw", {
  set.seed(39)
  nd <- 4000L
  draws <- rbind(
    subject = rgamma(nd, 3, 2),
    rater = rgamma(nd, 1, 4),
    subject_rater = rgamma(nd, 1, 3),
    residual = rgamma(nd, 4, 2)
  )
  k <- 4L
  n_o <- 3L
  e_single <- icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    replicates = TRUE,
    occasions = "single",
    n_o = n_o
  )
  e_avg <- icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    replicates = TRUE,
    occasions = "average",
    n_o = n_o
  )
  expect_identical(e_avg$error, c("rater", "subject_rater", "residual"))
  # Only pure error (residual) is divided by n_o; the interaction is shared across replicates.
  expect_identical(e_avg$error_divisors, c(1, 1, n_o))

  summ <- posterior_summary(draws, list(single = e_single, average = e_avg))
  sig <- draws["subject", ]
  err_avg <- draws["rater", ] +
    draws["subject_rater", ] +
    draws["residual", ] / n_o
  hand_avg <- sig / (sig + err_avg)
  expect_equal(
    summ$average$point,
    posterior_mode(hand_avg, lower = 0, upper = 1)
  )
  expect_equal(
    unname(quantile(hand_avg, 0.975)),
    summ$average$conf.high,
    tolerance = 1e-8
  )
  # Occasion averaging raises reliability draw-for-draw.
  expect_gt(summ$average$point, summ$single$point)
})

# --- O-Bayes-Rep: the committed replicate coverage reference (no brms needed, M29 S2) ---
# data-raw/oracle-bayesian-replicates.R runs a two-way random DGP with within-cell replicates
# (N_s = 25, k = 4, n_o = 3) through the SHIPPED fit_brms_replicates() recipe and commits
# single- and average-occasion ICC(A,1) coverage, containment of the frequentist glmmTMB
# points (the M17 §6 reduction), and the average > single ordering. Fast, no fitting, runs on
# every CI job. Tolerances absorb the finite n_rep and the INDEPENDENT MAP estimator (#4/#18).

test_that("O-Bayes-Rep: committed reference reproduces the replicate findings", {
  fixture <- test_path("fixtures", "bayesian-replicates-oracle.rds")
  skip_if_not(
    file.exists(fixture),
    "run data-raw/oracle-bayesian-replicates.R to generate"
  )
  s <- readRDS(fixture)$stats

  # (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
  expect_gte(s$converged_frac, 0.90)

  # (2) The single- and average-occasion credible intervals COVER their known population
  #     values ~nominally (coverage -- not the point -- is the pin).
  expect_gte(s$coverage_single, 0.90)
  expect_lte(s$coverage_single, 0.99)
  expect_gte(s$coverage_average, 0.90)
  expect_lte(s$coverage_average, 0.99)

  # (3) CONTAINMENT (the M17 §6 reduction): the frequentist glmmTMB replicate points -- which
  #     compose the same variance ratio -- fall inside the brms credible intervals for ~all reps
  #     (the two engines differ only by the prior; the M26 containment posture).
  expect_gte(s$containment_single, 0.90)
  expect_gte(s$containment_average, 0.90)

  # (4) OCCASION AVERAGING: the average-occasion ICC sits above the single-occasion one in
  #     ~every rep (averaging n_o replicates reduces pure error).
  expect_gte(s$average_above_single, 0.95)
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

# --- Live brms fit: INCOMPLETE fixed-rater two-way, O-Bayes-IFixed-agree (M31 S1, ADR-041) ---
# The ragged sibling of the O-Bayes-Fixed-agree smoke test above. Gated OFF CI (a CI runner has
# brms but no Stan toolchain). The committed O-Bayes-IFixed fixture is the coverage oracle; this
# smoke test wires the theta^2_r-from-posterior fit end to end ON RAGGED DATA -- where the 2b
# moment correction goes LIVE single-level (b != 0) -- and pins CONTAINMENT of the independent
# glmmTMB M3 incomplete fixed point (no textbook value on ragged data; the REML fit is the oracle,
# ADR-008). The fixed MAP is the mode of the right-skewed ICC draws and legitimately sits near/below
# the REML plug-in (containment, not equality -- the ADR-036 posture, here on ragged data).
test_that("brms fits the ragged fixed-rater two-way ICC end to end (O-Bayes-IFixed-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A connected ragged two-way fixed-rater design (all k = 4 raters present, ~15% cells dropped).
  set.seed(4110)
  k <- 4L
  n <- 24L
  mu_r <- c(-0.6, -0.2, 0.2, 0.6)
  grid <- expand.grid(subject = seq_len(n), rater = seq_len(k))
  mu_s <- rnorm(n, 0, sqrt(0.5))
  e <- rnorm(nrow(grid), 0, sqrt(0.5))
  grid$score <- mu_s[grid$subject] + mu_r[grid$rater] + e
  drop <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L, 50L, 56L, 62L, 70L, 82L, 90L)
  d <- grid[-drop, , drop = FALSE]
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  # The design must be ragged (some cells missing) yet keep every rater.
  expect_lt(nrow(d), n * k)
  expect_equal(nlevels(d$rater), k)

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
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  # theta^2_r lives in the rater component slot (subject, rater, residual).
  expect_setequal(names(fa$components), c("subject", "rater", "residual"))

  ta <- tidy(fa)
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(ta$estimate >= 0 & ta$estimate <= 1))
  # Ragged -> the fixed and random agreement values genuinely differ (theta^2_r != sigma^2_r):
  # the low <= point <= high interval is well-formed and strictly inside [0, 1].
  expect_true(all(ta$conf.low <= ta$estimate & ta$estimate <= ta$conf.high))

  # CONTAINMENT: the glmmTMB M3 incomplete fixed point (the independent oracle) sits inside each
  # brms credible interval. suppressWarnings mutes the expected fixed-rater advisory.
  gf <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "glmmTMB",
    seed = 1
  )))
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(gf, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
})

# --- Live brms fit: INCOMPLETE crossed FIXED multilevel, O-Bayes-IFML-fixed-agree (M31 S2) ---
# The ragged crossed (Design 1) FIXED-rater multilevel sibling of O-Bayes-IFixed-agree (single
# level) and O-Bayes-ML-agree (random multilevel). Gated OFF CI. The committed O-Bayes-IFML-fixed
# fixture is the coverage oracle; this smoke test wires fit_brms_multilevel_fixed() end to end ON
# RAGGED DATA -- where the 2b moment correction goes live (b != 0) -- and pins CONTAINMENT of the
# independent glmmTMB M18 Slice 1 incomplete fixed point at the SUBJECT level (fixed cluster-level
# IRR is deferred for all engines, so only the subject rows are produced).
test_that("brms fits the ragged crossed fixed multilevel ICC end to end (O-Bayes-IFML-fixed-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A connected ragged crossed Design-1 fixed multilevel design (raters shared across clusters).
  set.seed(5120)
  n_clusters <- 8L
  n_sub <- 4L
  k <- 4L
  mu_r <- c(-0.6, -0.2, 0.2, 0.6)
  grid <- expand.grid(
    rater = seq_len(k),
    s = seq_len(n_sub),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_", grid$s)
  mu_c <- rnorm(n_clusters, 0, sqrt(0.5))
  mu_sc <- rnorm(length(unique(sid)), 0, sqrt(1.0))[as.integer(factor(sid))]
  mu_cr <- rnorm(n_clusters * k, 0, sqrt(0.16))[as.integer(interaction(
    grid$cluster,
    grid$rater
  ))]
  grid$score <- mu_c[grid$cluster] +
    mu_sc +
    mu_r[grid$rater] +
    mu_cr +
    rnorm(nrow(grid), 0, sqrt(0.5))
  grid$subject <- factor(sid)
  grid$rater <- factor(grid$rater)
  grid$cluster <- factor(grid$cluster)
  d <- grid[
    -seq(1L, nrow(grid), by = 9L),
    c("subject", "rater", "cluster", "score")
  ]
  expect_lt(nrow(d), n_clusters * n_sub * k) # ragged

  ba <- list(chains = 2, iter = 1000, refresh = 0)
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
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  ta <- tidy(fa)
  # Subject level only for fixed crossed multilevel (cluster-level fixed IRR is deferred).
  expect_setequal(unique(ta$level), "subject")
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(ta$estimate >= 0 & ta$estimate <= 1))

  # CONTAINMENT: the glmmTMB M18 Slice 1 incomplete fixed subject point sits inside each brms
  # credible interval. suppressWarnings mutes the expected fixed-rater advisory.
  gf <- suppressWarnings(tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    raters = "fixed",
    engine = "glmmTMB",
    seed = 1
  )))
  gf <- gf[gf$level == "subject", ]
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(gf, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
})

# --- Live brms fit: INCOMPLETE nested Design-2 random multilevel, O-Bayes-INML-clusters-agree (M32 S1) ---
# The ragged nested (Design 2, raters nested in clusters) RANDOM sibling of O-Bayes-IML-agree
# (crossed random) and O-Bayes-NML-agree (balanced nested). Gated OFF CI (a CI runner has the brms
# package but no Stan C++ toolchain). The committed O-Bayes-INML-clusters fixture is the coverage
# oracle; this smoke test wires fit_brms_nested_clusters() end to end ON RAGGED DATA and pins
# CONTAINMENT of the independent glmmTMB M19 incomplete nested random point at the SUBJECT level
# (nested designs define no cluster level). Random raters -> a clean variance-ratio push-forward,
# so no 2b moment correction is involved.
test_that("brms fits the ragged nested Design-2 random ICC end to end (O-Bayes-INML-clusters-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A connected ragged nested Design-2 design: each cluster has its OWN k raters (cluster-unique
  # labels), crossed with that cluster's subjects.
  set.seed(3210)
  n_clusters <- 8L
  n_sub <- 4L
  k <- 4L
  grid <- expand.grid(
    rr = seq_len(k),
    s = seq_len(n_sub),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_s", grid$s)
  rid <- paste0(grid$cluster, "_r", grid$rr) # rater nested in cluster
  mu_c <- rnorm(n_clusters, 0, sqrt(0.5))
  mu_sc <- rnorm(length(unique(sid)), 0, sqrt(1.0))[as.integer(factor(sid))]
  mu_rc <- rnorm(length(unique(rid)), 0, sqrt(0.16))[as.integer(factor(rid))]
  grid$score <- mu_c[grid$cluster] +
    mu_sc +
    mu_rc +
    rnorm(nrow(grid), 0, sqrt(0.5))
  grid$subject <- factor(sid)
  grid$rater <- factor(rid)
  grid$cluster <- factor(grid$cluster)
  d <- grid[
    -seq(1L, nrow(grid), by = 9L),
    c("subject", "rater", "cluster", "score")
  ]
  expect_lt(nrow(d), n_clusters * n_sub * k) # ragged

  ba <- list(chains = 2, iter = 1000, refresh = 0)
  fa <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  expect_identical(fa$design$ml_design, "nested_in_clusters")
  ta <- tidy(fa)
  # Subject level only (nested designs define no cluster-level IRR); agreement by default.
  expect_setequal(unique(ta$level), "subject")
  expect_setequal(ta$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(ta$estimate >= 0 & ta$estimate <= 1))

  # CONTAINMENT: the glmmTMB M19 incomplete nested random subject point sits inside each brms
  # credible interval.
  gf <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "glmmTMB",
    seed = 1
  ))
  gf <- gf[gf$level == "subject", ]
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(A,1)", "ICC(A,k)")) {
    reml <- by_index(gf, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
  }
})

# --- Live brms fit: INCOMPLETE nested Design-3 random multilevel one-way, O-Bayes-INML-subjects-agree (M32 S2) ---
# The ragged nested (Design 3, raters nested in subjects, the multilevel ONE-WAY) RANDOM sibling of
# O-Bayes-INML-clusters-agree (Design 2). Gated OFF CI. The committed O-Bayes-INML-subjects fixture
# is the coverage oracle; this smoke test wires fit_brms_nested_subjects() end to end ON RAGGED DATA
# and pins CONTAINMENT of the independent glmmTMB M19 incomplete nested random point at the SUBJECT
# level. Design 3 is agreement-only (rater confounded into residual), so the coefficients carry
# one-way ICC(1)/ICC(k) labels and there is no cluster level.
test_that("brms fits the ragged nested Design-3 random ICC end to end (O-Bayes-INML-subjects-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # A connected ragged nested Design-3 design: each subject has its OWN k raters (subject-unique
  # labels).
  set.seed(3220)
  n_clusters <- 8L
  n_sub <- 4L
  k <- 4L
  grid <- expand.grid(
    rr = seq_len(k),
    s = seq_len(n_sub),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_s", grid$s)
  rid <- paste0(sid, "_r", grid$rr) # rater nested in subject
  mu_c <- rnorm(n_clusters, 0, sqrt(0.5))
  mu_sc <- rnorm(length(unique(sid)), 0, sqrt(1.0))[as.integer(factor(sid))]
  mu_r <- rnorm(length(unique(rid)), 0, sqrt(0.16))[as.integer(factor(rid))]
  grid$score <- mu_c[grid$cluster] +
    mu_sc +
    mu_r +
    rnorm(nrow(grid), 0, sqrt(0.5))
  grid$subject <- factor(sid)
  grid$rater <- factor(rid)
  grid$cluster <- factor(grid$cluster)
  d <- grid[
    -seq(1L, nrow(grid), by = 9L),
    c("subject", "rater", "cluster", "score")
  ]
  expect_lt(nrow(d), n_clusters * n_sub * k) # ragged

  ba <- list(chains = 2, iter = 1000, refresh = 0)
  fa <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "brms",
    seed = 1,
    brm_args = ba
  ))
  expect_identical(fa$engine, "brms")
  expect_identical(fa$ci$method, "posterior")
  expect_identical(fa$design$ml_design, "nested_in_subjects")
  ta <- tidy(fa)
  # Subject level only, one-way labels (Design 3 is the multilevel one-way, agreement-only).
  expect_setequal(unique(ta$level), "subject")
  expect_setequal(ta$index, c("ICC(1)", "ICC(k)"))
  expect_true(all(ta$estimate >= 0 & ta$estimate <= 1))

  # CONTAINMENT: the glmmTMB M19 incomplete nested random subject point sits inside each brms
  # credible interval.
  gf <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "glmmTMB",
    seed = 1
  ))
  gf <- gf[gf$level == "subject", ]
  by_index <- function(x, i) x$estimate[x$index == i]
  for (i in c("ICC(1)", "ICC(k)")) {
    reml <- by_index(gf, i)
    expect_gte(reml, ta$conf.low[ta$index == i])
    expect_lte(reml, ta$conf.high[ta$index == i])
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

# --- Live brms fit: conflated diagnostic (Eq. 14), O-Bayes-Conflated-agree (M29 Slice 1) ---
# The conflated analogue of the crossed live test above: the SAME five-component fit read via
# the conflated estimand (signal cluster + subject, error rater + cluster_rater + residual).
# Confirms the guard-narrowing wired the full path (icc() -> fit_brms_multilevel() ->
# posterior_summary()) and pins O-Bayes-Conflated-agree: the glmmTMB REML conflated point sits
# inside the brms credible interval (containment), and the conflated ICC is visibly above the
# subject level (Eq. 14 folds the between-cluster variance into the signal). The numerical
# coverage oracle is the committed O-Bayes-Conflated fixture; this exercises the live wiring.
test_that("brms fits the conflated diagnostic end to end (O-Bayes-Conflated-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  # Crossed Design 1 with a LARGE between-cluster variance so the conflated ICC (which folds
  # sigma^2_c into the signal) clearly overstates the subject level. ~20 clusters so sigma^2_c
  # is identified.
  set.seed(2029)
  nc <- 20L
  ns <- 5L
  k <- 5L
  d <- expand.grid(
    s = seq_len(ns),
    rater = factor(seq_len(k)),
    cluster = factor(seq_len(nc))
  )
  d$subject <- factor(paste0(d$cluster, "_", d$s))
  d$score <- 2 +
    rnorm(nc, 0, sqrt(1.5))[as.integer(d$cluster)] +
    rnorm(nlevels(d$subject), 0, 1)[as.integer(d$subject)] +
    rnorm(k, 0, 0.4)[as.integer(d$rater)] +
    rnorm(nc * k, 0, 0.4)[as.integer(interaction(d$cluster, d$rater))] +
    rnorm(nrow(d), 0, sqrt(0.5))

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    level = c("subject", "conflated"),
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  # Structure: a conflated row alongside the subject row, a posterior credible interval, the
  # Bayesian engine label. Conflated carries NO Shrout & Fleiss label.
  expect_s3_class(fit, "icc")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_true("conflated" %in% td$level)
  cf <- td[td$level == "conflated" & td$index == "ICC(A,1)", ]
  sj <- td[td$level == "subject" & td$index == "ICC(A,1)", ]
  expect_true(is.na(cf$sf_index))
  # Every conflated row is a valid probability interval.
  expect_true(all(
    cf$conf.low >= 0 & cf$conf.high <= 1 & cf$conf.low <= cf$conf.high
  ))

  # O-Bayes-Conflated-agree: the glmmTMB REML conflated point (the same Eq. 14) sits inside
  # the brms credible interval (containment, the honest engine-agreement pin).
  g <- tidy(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    level = "conflated",
    engine = "glmmTMB"
  ))
  g1 <- g[g$index == "ICC(A,1)", ]
  expect_true(g1$estimate >= cf$conf.low && g1$estimate <= cf$conf.high)

  # Distinctness: the conflated ICC is visibly above the subject level (the diagnostic's point).
  expect_gt(cf$estimate, sj$estimate)

  # The header renders the conflated diagnostic under its own heading (never a peer level).
  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "Diagnostic contrast", fixed = TRUE)
})

# --- Live brms fit: within-cell replicates, O-Bayes-Rep-agree (M29 Slice 2) ---------------
# The replicate analogue of the two-way live test: the interaction fit splits the residual into
# sigma^2_sr and pure error, and `occasions = "average"` divides pure error by n_o per draw.
# Confirms icc() -> fit_brms_replicates() -> posterior_summary() end to end and pins
# O-Bayes-Rep-agree: the glmmTMB REML replicate points sit inside the brms credible intervals
# (the M17 §6 reduction), and the average-occasion ICC exceeds the single-occasion one.
test_that("brms fits within-cell replicates end to end (O-Bayes-Rep-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  set.seed(2030)
  ns <- 25L
  k <- 4L
  n_o <- 3L
  grid <- expand.grid(
    rep = seq_len(n_o),
    rater = factor(seq_len(k)),
    subject = factor(seq_len(ns))
  )
  grid$score <- 2 +
    rnorm(ns, 0, 1)[as.integer(grid$subject)] +
    rnorm(k, 0, 0.4)[as.integer(grid$rater)] +
    rnorm(ns * k, 0, sqrt(0.5))[as.integer(interaction(
      grid$subject,
      grid$rater
    ))] +
    rnorm(nrow(grid), 0, sqrt(0.7))
  d <- grid[, c("subject", "rater", "score")]

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    occasions = c("single", "average"),
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  # Structure: single- AND average-occasion rows (occasions 1 and n_o), a credible interval.
  expect_s3_class(fit, "icc")
  expect_identical(fit$ci$method, "posterior")
  expect_setequal(fit$estimates$occasions, c(1, n_o))
  td <- tidy(fit)
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  # O-Bayes-Rep-agree: the glmmTMB REML replicate points sit inside the brms credible intervals
  # (the M17 §6 reduction; the credible interval covers MLE, the honest engine-agreement pin).
  g <- icc(
    d,
    score,
    rater,
    subject = subject,
    occasions = c("single", "average"),
    engine = "glmmTMB"
  )
  key <- function(x) paste(x$index, x$occasions)
  ge <- g$estimates[order(key(g$estimates)), ]
  fe <- fit$estimates[order(key(fit$estimates)), ]
  expect_true(all(ge$estimate >= fe$conf.low & ge$estimate <= fe$conf.high))

  # Occasion averaging raises reliability: the average-occasion ICC(A,1) exceeds the
  # single-occasion one (pure error divided by n_o).
  a1 <- fit$estimates[fit$estimates$index == "ICC(A,1)", ]
  expect_gt(
    a1$estimate[a1$occasions == n_o],
    a1$estimate[a1$occasions == 1]
  )

  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: incomplete/ragged two-way random, O-Bayes-Incomplete-agree (M30 Slice 1) ---
# The ragged analogue of the two-way live test: a connected but unbalanced subject x rater
# design (unequal per-subject rating counts), so the harmonic-mean k_eff divisor (< k) drives
# the average-unit ICC. Confirms icc() -> fit_brms_twoway() on ragged data -> posterior_summary()
# with the k_eff divisor, end to end, and pins O-Bayes-Incomplete-agree: the glmmTMB REML M3
# points (the independent incomplete-data oracle, ADR-008) sit inside the brms credible intervals
# (containment, not equality -- the MAP-below-REML skew + prior gap, the M26/M29 posture).
test_that("brms fits incomplete/ragged two-way random data end to end (O-Bayes-Incomplete-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  set.seed(3010)
  ns <- 18L
  k <- 4L
  grid <- expand.grid(rater = factor(seq_len(k)), subject = factor(seq_len(ns)))
  grid$score <- 2 +
    rnorm(ns, 0, 1)[as.integer(grid$subject)] +
    rnorm(k, 0, 0.4)[as.integer(grid$rater)] +
    rnorm(nrow(grid), 0, sqrt(0.7))
  # Delete a connected-preserving set of cells so per-subject counts are unequal (k_eff < k).
  drop <- c(1L, 6L, 9L, 20L, 33L, 48L, 55L, 60L)
  d <- grid[-drop, c("subject", "rater", "score")]
  d$subject <- droplevels(d$subject)
  d$rater <- droplevels(d$rater)
  di <- summarize_design(d)
  expect_true(di$connected)
  expect_false(di$balanced)
  expect_lt(di$k_eff, k) # the harmonic-mean divisor is genuinely below k

  fit <- suppressWarnings(icc(
    d,
    score,
    rater,
    subject = subject,
    unit = c("single", "average"),
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  expect_s3_class(fit, "icc")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  # O-Bayes-Incomplete-agree: the glmmTMB REML M3 points sit inside the brms credible intervals
  # (the incomplete-data engine-agreement pin; the credible interval covers the MLE).
  g <- icc(
    d,
    score,
    rater,
    subject = subject,
    unit = c("single", "average"),
    engine = "glmmTMB"
  )
  ge <- g$estimates[order(g$estimates$index), ]
  fe <- fit$estimates[order(fit$estimates$index), ]
  expect_true(all(ge$estimate >= fe$conf.low & ge$estimate <= fe$conf.high))

  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: incomplete/ragged single-level one-way, O-Bayes-IOneway-agree (M33 Slice 1) ---
# The ragged one-way analogue of the O-Bayes-OW-agree live test: an unbalanced subjects x
# rating-slots design (unequal per-subject rating counts), so the harmonic-mean k_eff divisor (< k)
# drives the average-unit ICC(1, k). Confirms icc() -> fit_brms_oneway() on ragged data (the newly
# narrowed !balanced brms guard) -> posterior_summary() with k_eff, end to end, and pins
# O-Bayes-IOneway-agree: the glmmTMB/lme4 REML M6+M3 one-way points (the independent incomplete-data
# oracle, ADR-008) sit inside the brms credible intervals (containment, not equality -- the
# MAP-below-REML skew + prior gap, the M26 one-way posture).
test_that("brms fits incomplete/ragged one-way random data end to end (O-Bayes-IOneway-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  set.seed(3310)
  ns <- 20L
  k <- 5L
  grid <- expand.grid(rater = factor(seq_len(k)), subject = factor(seq_len(ns)))
  grid$score <- 1 +
    rnorm(ns, 0, 1)[as.integer(grid$subject)] +
    rnorm(nrow(grid), 0, sqrt(0.6))
  # Delete rating slots so per-subject counts are unequal (k_eff < k); one-way needs no
  # connectedness, only every subject keeping >= 2 ratings.
  drop <- c(2L, 7L, 13L, 26L, 41L, 55L, 68L, 74L, 90L, 96L)
  d <- grid[-drop, c("subject", "rater", "score")]
  d$subject <- droplevels(d$subject)
  d$rater <- droplevels(d$rater)
  di <- summarize_design(d)
  expect_false(di$balanced)
  expect_lt(di$k_eff, k) # the harmonic-mean divisor is genuinely below k
  expect_gt(di$k_eff, 1)

  fit <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    unit = c("single", "average"),
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  ))

  expect_s3_class(fit, "icc")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))

  # O-Bayes-IOneway-agree: the glmmTMB REML M6+M3 one-way points sit inside the brms credible
  # intervals (the incomplete-data engine-agreement pin; the credible interval covers the MLE).
  g <- icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    unit = c("single", "average"),
    engine = "glmmTMB"
  )
  ge <- g$estimates[order(g$estimates$index), ]
  fe <- fit$estimates[order(fit$estimates$index), ]
  expect_true(all(ge$estimate >= fe$conf.low & ge$estimate <= fe$conf.high))

  hdr <- paste(format(fit), collapse = "\n")
  expect_match(hdr, "brms (MCMC)", fixed = TRUE)
  expect_match(hdr, "posterior credible", fixed = TRUE)
})

# --- Live brms fit: incomplete/ragged crossed multilevel random, O-Bayes-IML-agree (M30 S2) ---
# The multilevel analogue of the ragged two-way live test: a ragged crossed (Design 1) design
# (subjects nested in clusters, raters crossed, unequal cells) fit with fit_brms_multilevel().
# Confirms icc() -> the five-component brms fit on ragged data -> posterior_summary() with the
# k_eff divisor, subject + cluster-ICC(c,1) rows (the averaged cluster ICC(c,k) dropped-with-note),
# and pins O-Bayes-IML-agree: the glmmTMB REML M9 points (the independent incomplete-multilevel
# oracle, ADR-018) sit inside the brms credible intervals (containment, not equality).
test_that("brms fits ragged crossed multilevel random data end to end (O-Bayes-IML-agree)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")
  skip_if_not_installed("glmmTMB")

  set.seed(3020)
  nc <- 4L
  nspc <- 5L
  k <- 4L
  base <- expand.grid(
    rater = seq_len(k),
    s = seq_len(nspc),
    cluster = seq_len(nc)
  )
  sid <- paste0(base$cluster, "_", base$s)
  base$subject <- sid
  base$score <- rnorm(nc, 0, 0.8)[base$cluster] +
    rnorm(nc * nspc, 0, 1)[as.integer(factor(sid))] +
    rnorm(k, 0, 0.4)[base$rater] +
    rnorm(nrow(base), 0, 0.6)
  base$subject <- factor(base$subject)
  base$rater <- factor(base$rater)
  base$cluster <- factor(base$cluster)
  # Drop a connectedness-preserving set of cells so per-subject counts are unequal.
  drop <- c(2L, 9L, 17L, 28L, 41L, 55L, 63L, 70L)
  d <- base[-drop, c("subject", "rater", "cluster", "score")]
  di <- summarize_design(d)
  expect_false(di$balanced)

  fit <- suppressWarnings(suppressMessages(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    level = c("subject", "cluster"),
    engine = "brms",
    seed = 2,
    brm_args = list(chains = 2, iter = 1200, refresh = 0)
  )))

  expect_s3_class(fit, "icc")
  expect_identical(fit$ci$method, "posterior")
  td <- tidy(fit)
  expect_true(all(
    td$conf.low >= 0 & td$conf.high <= 1 & td$conf.low <= td$conf.high
  ))
  # The averaged cluster-level ICC(c,k) is dropped on incomplete data: cluster rows are
  # single-rater only (ICC(A,1)/ICC(C,1)), never an average unit.
  clus <- fit$estimates[fit$estimates$level == "cluster", ]
  expect_true(nrow(clus) >= 1L)
  expect_false(any(grepl(",k)$", clus$index)))

  # O-Bayes-IML-agree: the glmmTMB REML M9 points sit inside the brms credible intervals.
  g <- suppressMessages(icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    level = c("subject", "cluster"),
    engine = "glmmTMB"
  ))
  key <- function(x) paste(x$level, x$index)
  gm <- g$estimates[match(key(fit$estimates), key(g$estimates)), ]
  expect_true(all(
    gm$estimate >= fit$estimates$conf.low &
      gm$estimate <= fit$estimates$conf.high,
    na.rm = TRUE
  ))

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
