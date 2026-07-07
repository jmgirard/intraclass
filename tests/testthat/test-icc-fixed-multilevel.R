# Oracle O-FML: fixed-rater multilevel ICCs (Design 1, balanced), M10 -----------
#
# M10 treats raters as FIXED (McGraw & Wong Case 3/3A) in the crossed multilevel
# Design-1 fit, balanced/complete, subject level. The rater main effect becomes the
# bias-corrected finite-population theta^2_r (inherited from M3 §6) placed in the M5
# subject-level decomposition (spec M10). No new estimand concept: theta^2_r fills
# the "rater" slot in place of the random sigma^2_r, so icc_point()/mc_ci() are
# unchanged. No textbook worked example exists for fixed-rater multilevel, so
# correctness rests on (PRINCIPLES.md #1): the PRIMARY reduction to the pinned
# random-rater M5 estimand (on balanced data fixed == random), a single-cluster
# reduction to the M3 fixed path, an lme4 cross-engine fit, and a seeded-sim
# recovery. Provenance in data-raw/oracle-fixed-multilevel.R.

# Balanced crossed Design-1 generator with known population components (raters
# CROSSED with clusters -> global rater labels).
sim_design1 <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rr[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  d
}

pick <- function(x, index, level = "subject") {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

fixed_ml <- function(d, type, unit = c("single", "average")) {
  suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    raters = "fixed",
    type = type,
    unit = unit,
    seed = 1
  ))
}
random_ml <- function(d, type, unit = c("single", "average")) {
  icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    raters = "random",
    type = type,
    unit = unit,
    seed = 1
  )
}

test_that("O-FML/reduction (PRIMARY): balanced fixed == random M5 subject level", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(12, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  fa <- fixed_ml(d, "agreement")
  ra <- random_ml(d, "agreement")
  fc <- fixed_ml(d, "consistency")
  rc <- random_ml(d, "consistency")
  # Absolute agreement: theta^2_r == sigma^2_r on balanced data, so single AND
  # average match the random-rater M5 coefficients.
  expect_equal(pick(fa, "ICC(A,1)"), pick(ra, "ICC(A,1)"), tolerance = 1e-4)
  expect_equal(pick(fa, "ICC(A,k)"), pick(ra, "ICC(A,k)"), tolerance = 1e-4)
  # Consistency never uses the rater term, so fixed and random are identical.
  expect_equal(pick(fc, "ICC(C,1)"), pick(rc, "ICC(C,1)"), tolerance = 1e-4)
  expect_equal(pick(fc, "ICC(C,k)"), pick(rc, "ICC(C,k)"), tolerance = 1e-4)
})

test_that("O-FML/reduction: single-cluster signal/residual match the M3 flat fixed fit", {
  skip_if_not_installed("glmmTMB")
  # With one cluster the fixed multilevel model's SIGNAL (sigma^2_{s:c}) and RESIDUAL
  # reduce to M3's flat fixed fit (score ~ 1 + rater + (1|subject)). theta^2_r does
  # NOT reduce at one cluster: the (1|cluster:rater) term collapses to (1|rater) and
  # absorbs the rater variation that the fixed effect otherwise carries (a degenerate
  # single-cluster artifact, not the >= 2-cluster estimand). A one-cluster design is
  # refused by icc(), so this is checked at the fit level.
  d <- sim_design1(1, 16, 5, 0.0, 1.0, 0.6, 0.0, 0.6, seed = 909)
  ml <- fit_glmmtmb_multilevel_fixed(d)
  flat <- fit_glmmtmb_fixed(d)
  expect_equal(ml$components$subject, flat$components$subject, tolerance = 1e-3)
  expect_equal(
    ml$components$residual,
    flat$components$residual,
    tolerance = 1e-3
  )
})

test_that("O-FML/lme4: fixed multilevel components match an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design1(12, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  x <- fixed_ml(d, "consistency", unit = "single")
  m <- lme4::lmer(
    score ~ 1 +
      rater +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE,
    control = lme4::lmerControl(check.conv.singular = "ignore")
  )
  vc <- as.data.frame(lme4::VarCorr(m))
  g <- function(grp) vc$vcov[vc$grp == grp][1]
  # Random components (signal + residual) match lme4; theta^2_r is a fixed-effect
  # quantity checked via the reductions above.
  expect_equal(x$components$subject, g("cluster:subject"), tolerance = 1e-4)
  expect_equal(x$components$residual, g("Residual"), tolerance = 1e-4)
  expect_equal(x$components$cluster_rater, g("cluster:rater"), tolerance = 1e-4)
})

test_that("O-FML/sim: recovers the known subject-level consistency ICC", {
  skip_if_not_installed("glmmTMB")
  vsc <- 1.0
  vres <- 0.6
  target_c1 <- vsc / (vsc + vres) # = 0.625
  d <- sim_design1(50, 10, 5, 0.8, vsc, 0.5, 0.3, vres, seed = 314)
  x <- fixed_ml(d, "consistency", unit = "single")
  expect_lt(abs(pick(x, "ICC(C,1)") - target_c1), 0.04)
  expect_gte(target_c1, x$estimates$conf.low[1])
  expect_lte(target_c1, x$estimates$conf.high[1])
})

test_that("consistency is identical to random; agreement differs only by theta^2_r", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 77)
  # On balanced data the two are equal; the point of the test is that consistency
  # uses no rater term at all (so it is exactly random) while agreement routes
  # through theta^2_r (equal here, but a distinct code path).
  fc <- fixed_ml(d, "consistency", unit = "single")
  rc <- random_ml(d, "consistency", unit = "single")
  expect_equal(pick(fc, "ICC(C,1)"), pick(rc, "ICC(C,1)"), tolerance = 1e-6)
  fa <- fixed_ml(d, "agreement", unit = "single")
  expect_true("rater" %in% names(fa$components))
  expect_gte(fa$components$rater, 0) # theta^2_r clamped at 0 (boundary-aware)
})

# Scope guards (spec M10 §3/§7) -------------------------------------------------

test_that("fixed-rater multilevel warns, and reports at the subject level", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 5)
  expect_warning(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      seed = 1
    ),
    class = "intraclass_fixed_raters"
  )
  x <- fixed_ml(d, "agreement", unit = "single")
  expect_true(x$design$multilevel)
  expect_identical(x$design$raters, "fixed")
  expect_identical(unique(x$estimates$level), "subject")
})

test_that("deferred fixed-rater multilevel cases abort loudly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 5)
  # Cluster level (subject-only in M10).
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "cluster",
      seed = 1
    )),
    class = "intraclass_unsupported"
  )
  # Nested design with fixed raters.
  dn <- d
  dn$rater <- factor(paste(dn$cluster, dn$rater, sep = "_"))
  expect_error(
    suppressWarnings(icc(
      dn,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      seed = 1
    )),
    class = "intraclass_unsupported"
  )
  # Incomplete / unbalanced fixed multilevel.
  set.seed(3)
  di <- d[-sample(nrow(d), 20), ]
  expect_error(
    suppressWarnings(icc(
      di,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      seed = 1
    )),
    class = "intraclass_unsupported"
  )
})
