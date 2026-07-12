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

test_that("still-deferred fixed-rater multilevel cases abort loudly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 5)
  # Balanced crossed CLUSTER level is no longer deferred -- it ships for glmmTMB/lme4 in
  # M37 (ADR-047; its oracles are the O-FCL section below) and for brms in M38 Cell 1
  # (ADR-048; the live O-Bayes-FCL fit in test-icc-brms.R). The remaining deferred
  # cluster-fixed cell is INCOMPLETE/unbalanced data for every engine (double-blocked:
  # ten Hove's open small-k estimator + the M9 §9 ICC(c,k) divisor); the brms incomplete
  # boundary is asserted in test-icc-brms.R.
  di <- d[-(1:12), ] # incomplete crossed (missing cells)
  expect_error(
    suppressWarnings(icc(
      di,
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
  # (Fixed-rater NESTED Design 2 is no longer deferred -- it ships in M19 Slice 2
  # (ADR-029); Design 3 fixed stays by-design undefined. Both are covered in the
  # "fixed nested scope guards" test below.)
  # (Incomplete / unbalanced fixed CROSSED multilevel SUBJECT level is no longer
  # deferred -- it ships in M18 Slice 1 (ADR-028); its oracles are the O-IFML section.)
})

# Oracle O-FCL: fixed-rater CLUSTER-level ICC (crossed Design 1, balanced), M37 --------
#
# M37 (ADR-047) reads the CLUSTER level off the same M10 fixed fit: signal sigma^2_c,
# agreement error {theta^2_r, sigma^2_cr}, consistency {sigma^2_cr}, divisor k (M5 §3b
# map with theta^2_r in the rater slot). No new fit, no new estimand concept -- the
# estimand map keys the error set on `level`, not `raters`. The feasibility spike settled
# the one open question (M10 §7): fixing the rater main effect does NOT bias the
# (1|cluster:rater) interaction, so the RANDOM sigma^2_cr is the correct fixed-rater
# cluster-level error, and the coefficient reduces to the M5 random cluster-level ICC
# EXACTLY on balanced data. Correctness (#1): the PRIMARY reduction to the pinned M5
# random cluster-level estimand, an lme4 cross-engine fit, and a committed NON-CIRCULAR
# seeded recovery (theta^2_r is a deterministic function of the fixed rater means).
# Provenance: data-raw/oracle-fixed-cluster-level.R + the spike scripts.

fixed_cluster <- function(
  d,
  type,
  unit = c("single", "average"),
  engine = "glmmTMB"
) {
  suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    raters = "fixed",
    type = type,
    unit = unit,
    engine = engine,
    seed = 1
  ))
}
random_cluster <- function(d, type, unit = c("single", "average")) {
  icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    raters = "random",
    type = type,
    unit = unit,
    seed = 1
  )
}

test_that("O-FCL/reduction (PRIMARY): balanced fixed == random M5 CLUSTER level", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(12, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  fa <- fixed_cluster(d, "agreement")
  ra <- random_cluster(d, "agreement")
  fc <- fixed_cluster(d, "consistency")
  rc <- random_cluster(d, "consistency")
  # Absolute agreement: theta^2_r == sigma^2_r on balanced data AND sigma^2_cr is
  # unbiased under fixing (spike), so single AND average match random at the cluster level.
  expect_equal(
    pick(fa, "ICC(A,1)", "cluster"),
    pick(ra, "ICC(A,1)", "cluster"),
    tolerance = 1e-4
  )
  expect_equal(
    pick(fa, "ICC(A,k)", "cluster"),
    pick(ra, "ICC(A,k)", "cluster"),
    tolerance = 1e-4
  )
  # Consistency uses only sigma^2_cr (no rater main effect), so fixed == random exactly.
  expect_equal(
    pick(fc, "ICC(C,1)", "cluster"),
    pick(rc, "ICC(C,1)", "cluster"),
    tolerance = 1e-6
  )
  expect_equal(
    pick(fc, "ICC(C,k)", "cluster"),
    pick(rc, "ICC(C,k)", "cluster"),
    tolerance = 1e-6
  )
})

test_that("O-FCL/lme4: fixed cluster-level ICCs match the lme4 cross-engine (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design1(12, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  xg <- fixed_cluster(d, "agreement")
  xl <- fixed_cluster(d, "agreement", engine = "lme4")
  merged <- merge(
    xg$estimates[xg$estimates$level == "cluster", c("index", "estimate")],
    xl$estimates[xl$estimates$level == "cluster", c("index", "estimate")],
    by = "index"
  )
  expect_lt(max(abs(merged$estimate.x - merged$estimate.y)), 1e-4)
})

test_that("O-FCL: cluster consistency == random; agreement differs only by theta^2_r", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 77)
  fc <- fixed_cluster(d, "consistency", unit = "single")
  rc <- random_cluster(d, "consistency", unit = "single")
  # Cluster consistency error is {cluster_rater} -- never the rater main effect.
  expect_equal(
    pick(fc, "ICC(C,1)", "cluster"),
    pick(rc, "ICC(C,1)", "cluster"),
    tolerance = 1e-6
  )
  fa <- fixed_cluster(d, "agreement", unit = "single")
  expect_true("rater" %in% names(fa$components))
  expect_gte(fa$components$rater, 0) # theta^2_r clamped at 0 (boundary-aware)
})

test_that("O-FCL: balanced fixed returns BOTH levels by default; print surfaces cluster", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(10, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 5)
  x <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    seed = 1
  ))
  expect_setequal(unique(x$estimates$level), c("subject", "cluster"))
  expect_identical(x$design$raters, "fixed")
  out <- paste(format(x), collapse = "\n")
  expect_match(out, "cluster")
})

test_that("O-FCL/recovery: committed fixture -- interior calibrated + unbiased, boundary parity", {
  o <- readRDS(test_path("fixtures", "fixed-cluster-level-oracle.rds"))
  int <- o[o$cell == "interior", ]
  # Interior recovery of the KNOWN finite-population cluster-level value is nominal
  # (MC SE ~1.4 pts at n_rep = 240; a .90 floor clears noise) and unbiased at adequate
  # cluster count (the C_n = 20 cell is few-cluster-noisier but still covers).
  expect_gt(min(int$coverage), 0.90)
  expect_lt(max(abs(int$mean_bias)), 0.05)
  # The reduction to the M5 random cluster-level (balanced fixed == random, point) and
  # the lme4 cross-engine tie committed with the fixture stayed exact.
  red <- attr(o, "reductions")
  expect_lt(red[["reduction"]], 1e-4)
  if (!is.na(red[["cross_engine"]])) {
    expect_lt(red[["cross_engine"]], 1e-4)
  }
  # BOUNDARY (sigma^2_c = 0): the cluster-signal-zero interval under-covers, but
  # IDENTICALLY for fixed and M5-random -- a pre-existing shared property, NOT an M37
  # defect (spike boundary-parity). Assert PARITY, not nominal (#18).
  b <- o[o$cell == "boundary", ]
  expect_lt(abs(b$coverage - b$coverage_random), 0.06)
})

# Oracle O-IFML: INCOMPLETE fixed-rater crossed multilevel (Design 1), M18 Slice 1 --
#
# M18 Slice 1 (ADR-028) lifts the balanced-only guard on the fixed-rater crossed
# multilevel fit: the finite-population theta^2_r (Case 3A, via the shared
# theta2r_fixed()) is read from the fitted rater-contrast vcov -- which glmmTMB/lme4
# estimate on ragged data -- and the subject-level error divisor stays the same k_eff
# (harmonic mean of ratings per subject) the random path uses. No new estimand; this
# is the M10 estimand on ragged data (as M3 is to M1/M2). No textbook worked example,
# so correctness rests on (PRINCIPLES.md #1): an independent lme4 cross-engine fit on
# an interior ragged design, a seeded-sim recovery, and the characterization -- shared
# with the single-level M3 fixed path -- that on ragged data fixed genuinely differs
# from random (theta^2_r != sigma^2_r under imbalance). The balanced fixed == random
# reduction is the O-FML/reduction test above (k_eff == k there). Provenance: seeded
# generators in this file (sim_design1 + ragged), no committed constants.

ragged <- function(d, n, seed) {
  set.seed(seed)
  d[-sample(nrow(d), n), , drop = FALSE]
}

test_that("O-IFML/lme4: ragged fixed subject ICCs match an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  # An interior ragged design (lme4 stays off the variance boundary here).
  d <- ragged(sim_design1(12, 6, 5, 1.0, 0.9, 0.5, 0.3, 0.8, seed = 202), 24, 1)
  x <- fixed_ml(d, "agreement")
  m <- lme4::lmer(
    score ~ 1 +
      rater +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | cluster:rater),
    data = d,
    control = lme4::lmerControl(check.conv.singular = "ignore")
  )
  vc <- as.data.frame(lme4::VarCorr(m))
  g <- function(t) vc$vcov[vc$grp == t]
  # Random components (signal + residual + cluster x rater) match an independent lme4
  # fit; theta^2_r is a fixed-effect quantity checked via the reductions/characterization.
  expect_equal(x$components$subject, g("cluster:subject"), tolerance = 1e-4)
  expect_equal(x$components$residual, g("Residual"), tolerance = 1e-4)
  expect_equal(x$components$cluster_rater, g("cluster:rater"), tolerance = 1e-4)
  # End-to-end: the intraclass lme4 engine reproduces the glmmTMB ICCs on ragged data.
  xl <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "agreement",
    raters = "fixed",
    level = "subject",
    engine = "lme4",
    seed = 1
  ))
  expect_equal(x$estimates$estimate, xl$estimates$estimate, tolerance = 1e-4)
})

test_that("O-IFML: on ragged data fixed genuinely differs from random", {
  skip_if_not_installed("glmmTMB")
  d <- ragged(sim_design1(12, 6, 5, 1.0, 0.9, 0.5, 0.3, 0.8, seed = 202), 24, 1)
  fa <- fixed_ml(d, "agreement")
  ra <- random_ml(d, "agreement")
  # theta^2_r != sigma^2_r under imbalance, so the agreement ICCs no longer coincide
  # (they are equal to numerical tolerance only on balanced data -- O-FML/reduction).
  expect_false(isTRUE(all.equal(
    pick(fa, "ICC(A,1)"),
    pick(ra, "ICC(A,1)"),
    tolerance = 1e-6
  )))
  # Still a valid coefficient in [0, 1] with theta^2_r clamped at the boundary.
  expect_gte(pick(fa, "ICC(A,1)"), 0)
  expect_lte(pick(fa, "ICC(A,1)"), 1)
  expect_gte(fa$components$rater, 0)
})

test_that("O-IFML/sim: recovers the known subject-level consistency ICC on ragged data", {
  skip_if_not_installed("glmmTMB")
  vsc <- 1.2
  vres <- 0.5
  d <- ragged(
    sim_design1(40, 12, 6, 1.0, vsc, 0.6, 0.2, vres, seed = 20260708),
    round(0.15 * (40 * 12 * 6)),
    11
  )
  x <- fixed_ml(d, "consistency")
  target_c1 <- vsc / (vsc + vres)
  expect_lt(abs(pick(x, "ICC(C,1)") - target_c1), 0.04)
  expect_gte(target_c1, x$estimates$conf.low[1])
  expect_lte(target_c1, x$estimates$conf.high[1])
})

test_that("O-IFML: a ragged fixed design that goes singular defers lme4 to glmmTMB", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  # A small design with zero cluster x rater variance driven ragged lands lme4 on the
  # variance boundary (merDeriv covariance singular); the shipped intraclass_singular_fit
  # handoff (M15) fires for the fixed path too, and glmmTMB still fits (#5/#18).
  d <- ragged(sim_design1(6, 4, 4, 1.0, 0.8, 0.5, 0.0, 0.6, seed = 32), 28, 32)
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      engine = "lme4",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
  expect_s3_class(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      engine = "glmmTMB",
      seed = 1
    )),
    "icc"
  )
})

test_that("O-IFML: incomplete fixed identifiability guards still fire", {
  skip_if_not_installed("glmmTMB")
  # The conservative crossed-multilevel identifiability gates (spec M9 §4b) apply to
  # the fixed path unchanged. A design where every subject is rated only once cannot
  # separate the subject and residual variances -> abort, not a spurious ICC.
  d <- sim_design1(8, 6, 4, 1.0, 0.9, 0.5, 0.3, 0.8, seed = 77)
  d1 <- d[!duplicated(d$subject), , drop = FALSE] # one rating per subject
  expect_error(
    suppressWarnings(icc(
      d1,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      level = "subject",
      seed = 1
    )),
    class = "intraclass_unidentified"
  )
})

# Fixed-rater NESTED multilevel (Design 2), M19 Slice 2 (ADR-029) --------------
#
# Raters nested in clusters, treated as fixed: each cluster's k raters are its own
# finite population, so the rater slot carries theta^2_{r:c} = the mean over clusters
# of the within-cluster bias-corrected finite-population variance (McGraw & Wong Case
# 3A per cluster). Unlike the crossed design (M10), fixed != random even on balanced
# data (per-cluster finite population), so the pins are the per-cluster reduction to
# the flat M3 fixed theta^2_r, the single-cluster reduction, cross-engine, and
# consistency == random. Provenance in data-raw/oracle-fixed-multilevel.R.

# Balanced Design-2 generator (raters nested in clusters -> cluster-unique labels).
sim_design2 <- function(nc, ns, k, vc, vsc, vrc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  rcv <- stats::rnorm(nc * k, 0, sqrt(vrc))
  d$rc <- rcv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    d$rc +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

test_that("fixed nested Design 2 is detected: subject-level, theta^2_{r:c} slot", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)
  x <- suppressWarnings(
    icc(d, score, subject, rater, cluster = cluster, raters = "fixed", seed = 1)
  )
  expect_identical(x$design$ml_design, "nested_in_clusters")
  expect_identical(x$design$raters, "fixed")
  expect_setequal(unique(x$estimates$level), "subject")
  # No sigma^2_c (the cell-mean fit absorbs the cluster main effect); rater slot holds
  # theta^2_{r:c}; no cluster:rater term.
  expect_null(x$components$cluster)
  expect_null(x$components$cluster_rater)
  expect_true(is.numeric(x$components$rater))
  expect_true(all(x$estimates$estimate >= 0 & x$estimates$estimate <= 1))
  out <- paste(format(x), collapse = "\n")
  expect_match(out, "raters nested in clusters")
  expect_match(out, "rater:cluster")
})

test_that("O-FNML/reduction: theta^2_{r:c} is the per-cluster flat M3 fixed average", {
  skip_if_not_installed("glmmTMB")
  # The PRIMARY pin: the nested fixed rater variance equals the mean over clusters of
  # the flat two-way fixed theta^2_r fit on each cluster's data alone (McGraw & Wong
  # Case 3A per cluster) -- tying it to the pinned M3 fixed estimand.
  d <- sim_design2(15, 8, 5, 1.0, 1.2, 0.7, 0.5, seed = 20260709)
  x <- suppressWarnings(
    icc(d, score, subject, rater, cluster = cluster, raters = "fixed", seed = 1)
  )
  per_cluster <- vapply(
    levels(d$cluster),
    function(cl) {
      sub <- droplevels(d[d$cluster == cl, ])
      xf <- suppressWarnings(icc(
        sub,
        score,
        subject,
        rater,
        raters = "fixed",
        seed = 1
      ))
      xf$components$rater
    },
    numeric(1)
  )
  expect_equal(x$components$rater, mean(per_cluster), tolerance = 1e-4)
})

test_that("O-FNML/single-cluster: fixed-nested components reduce to flat M3 fixed", {
  skip_if_not_installed("glmmTMB")
  # icc() refuses a single cluster, so the reduction is checked at the fit level: with
  # one cluster the fixed-nested components equal the flat M3 fixed ones exactly.
  d1 <- sim_design2(1, 15, 6, 0, 1.2, 0.7, 0.5, seed = 99)
  cn <- fit_glmmtmb_nested_fixed(d1)$components
  cf <- fit_glmmtmb_fixed(d1)$components
  expect_equal(cn$rater, cf$rater, tolerance = 1e-6)
  expect_equal(cn$subject, cf$subject, tolerance = 1e-6)
  expect_equal(cn$residual, cf$residual, tolerance = 1e-6)
})

test_that("fixed nested: consistency == random, agreement differs (finite population)", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 2)
  xf <- suppressWarnings(
    icc(d, score, subject, rater, cluster = cluster, raters = "fixed", seed = 1)
  )
  xfc <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    type = "consistency",
    seed = 1
  ))
  xr <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  xrc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )
  # Consistency never uses the rater term -> identical to random.
  expect_equal(pick(xfc, "ICC(C,1)"), pick(xrc, "ICC(C,1)"), tolerance = 1e-4)
  expect_equal(pick(xfc, "ICC(C,k)"), pick(xrc, "ICC(C,k)"), tolerance = 1e-4)
  # Agreement uses theta^2_{r:c} != sigma^2_{r:c}: fixed and random need NOT coincide
  # even on balanced nested data (this seed differs; the M10 crossed identity does not
  # carry over). Just require a valid, finite coefficient.
  expect_true(pick(xf, "ICC(A,1)") > 0 && pick(xf, "ICC(A,1)") < 1)
})

test_that("O-FNML/lme4: fixed-nested matches lme4 cross-engine (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  d <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)
  xg <- suppressWarnings(
    icc(d, score, subject, rater, cluster = cluster, raters = "fixed", seed = 1)
  )
  xl <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    engine = "lme4",
    seed = 1
  ))
  merged <- merge(
    xg$estimates[c("index", "estimate")],
    xl$estimates[c("index", "estimate")],
    by = "index"
  )
  expect_lt(max(abs(merged$estimate.x - merged$estimate.y)), 1e-4)
})

test_that("fixed nested scope guards fail loudly (decision C + deferral)", {
  skip_if_not_installed("glmmTMB")
  # Design 3 (raters nested in subjects) fixed is by-design undefined: no separable
  # rater effect (multilevel one-way, cf. M6 fixed one-way).
  set.seed(3)
  d3 <- expand.grid(rep = 1:4, subj = 1:6, cluster = 1:15)
  d3$score <- stats::rnorm(nrow(d3))
  d3$cluster <- factor(d3$cluster)
  d3$subject <- factor(paste(d3$cluster, d3$subj, sep = "_"))
  d3$rater <- factor(paste(d3$cluster, d3$subj, d3$rep, sep = "_"))
  expect_error(
    suppressWarnings(
      icc(d3, score, subject, rater, cluster = cluster, raters = "fixed")
    ),
    class = "intraclass_unsupported"
  )
  # Incomplete fixed nested (Design 2) now SHIPS for the mixed-model engines (M36,
  # ADR-046); the Bayesian engine stays deferred (refused with a case-naming message).
  d2 <- sim_design2(20, 6, 4, 1.0, 1.2, 0.7, 0.5, seed = 7)
  d2i <- d2[-(1:3), ]
  fit_i <- suppressWarnings(icc(
    d2i,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    design = "nested_in_clusters",
    unit = c("single", "average"),
    seed = 1
  ))
  # The default now reports both error definitions (ADR-054): fixed-nested agreement
  # (the M36/M38 theta^2_{r:c} path) plus consistency, which drops the rater term and
  # so reduces to the random-nested consistency (oracle-backed; the M2/M10 identity).
  expect_setequal(
    fit_i$estimates$index,
    c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")
  )
  expect_true(all(is.finite(fit_i$estimates$estimate)))
  # brms incomplete/ragged fixed-nested (Design 2) now ships too (M38 Cell 2, ADR-048); the
  # Bayesian path is exercised by the live O-Bayes-IFNML-agree fit in test-icc-brms.R.
})

# O-NFI: frequentist nested-fixed theta^2_{r:c} MC-INTERVAL coverage (M28, ADR-038) -
#
# A CI method's oracle is coverage (#1). The committed fixture
# (fixtures/nested-fixed-interval-oracle.rds) is a seeded coverage sim over the Fable
# Q6 grid, regenerated by data-raw/oracle-nested-fixed-interval.R (#4).
#
# History (#18): M28 Slice 1 pinned the SHIPPED (1b, per-cluster-floor) interval
# UNDERCOVERING -- boundary coverage .95/.86/.57 as C_n = 5/20/80, worst cell ~.37 (the
# ADR-037 corollary confirmed). M28 Slice 2 (gated Fable review #19) replaced it with the
# moment-corrected `theta2r_moment_draws()` (subtract 2b, floor the per-draw AVERAGE); the
# fixture below is the POST-FIX confirmation. The frequentist POINT keeps its 1b
# correction (O-FNML above) but its floor also moved to the average, so it no longer
# falls outside its own interval at the boundary (checked live in O-NFI/point).
test_that("O-NFI: moment-corrected nested-fixed MC interval is calibrated across the grid", {
  o <- readRDS(test_path("fixtures", "nested-fixed-interval-oracle.rds"))
  by_cn <- function(cn, cell) {
    mean(o$coverage[o$C_n == cn & o$cell == cell])
  }

  # Nominal everywhere -- no cell materially undercovers (MC SE ~2.2 pts at n_rep=100,
  # so a floor of .88 clears noise while catching any real shortfall).
  expect_gt(min(o$coverage), 0.87)
  expect_gt(mean(o$coverage), 0.93)

  # The incidental-parameters collapse is GONE: boundary coverage no longer decays with
  # cluster count (pre-fix .95 -> .86 -> .57; post-fix all ~nominal). This is the
  # regression guard for the Slice 2 fix.
  expect_gt(by_cn(80, "boundary"), 0.90)
  expect_gt(by_cn(20, "boundary"), 0.90)
  expect_gt(by_cn(5, "boundary"), 0.90)

  # The worst pre-fix cell (C_n=80, n_s=3, theta^2=0; was ~.37) is now nominal.
  worst <- o$coverage[o$C_n == 80 & o$n_s == 3 & o$cell == "boundary"]
  expect_true(all(worst > 0.88))

  # Boundary is boundary-aware (#3) -- calibrated-to-mildly-conservative, not under.
  expect_gt(mean(o$coverage[o$cell == "boundary"]), 0.92)
})

test_that("O-NFI/point: nested-fixed point recovers theta^2 and stays inside its own CI", {
  skip_if_not_installed("glmmTMB")
  sim_nfp <- function(nc, ns, k, theta2, seed) {
    base <- seq_len(k) - (k + 1) / 2
    rmean <- if (theta2 == 0) {
      rep(0, k)
    } else {
      base * sqrt(theta2 / (sum(base^2) / (k - 1)))
    }
    set.seed(seed)
    d <- expand.grid(
      subj = seq_len(ns),
      rater = seq_len(k),
      cluster = seq_len(nc)
    )
    scv <- stats::rnorm(nc * ns)
    d$sc <- scv[(d$cluster - 1) * ns + d$subj]
    d$score <- 10 + rmean[d$rater] + d$sc + stats::rnorm(nrow(d), 0, sqrt(0.5))
    d$cluster <- factor(d$cluster)
    d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
    d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
    d
  }

  # The point (theta2r_fixed_nested()$point) keeps its 1b bias correction -- unchanged
  # from M19 away from the boundary -- and recovers a known fixed theta^2_{r:c}.
  cn <- fit_glmmtmb_nested_fixed(sim_nfp(20, 6, 4, 0.66, 4242))$components
  expect_gt(cn$rater, 0.45)
  expect_lt(cn$rater, 0.85)

  # Fable review finding (ADR-038 amendment, section 3): with the average floor, the
  # point sits INSIDE its own 95% interval at the boundary -- pre-fix (per-cluster floor)
  # it fell outside in up to ~40% of boundary reps at many clusters. A short live check
  # on a boundary cell (theta^2 = 0) confirms containment is high.
  inside <- 0L
  n <- 0L
  for (r in seq_len(15)) {
    d <- sim_nfp(30, 3, 4, 0, 96000 + r)
    x <- tryCatch(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        seed = 96000 + r,
        mc_samples = 3000L
      )),
      error = function(e) NULL
    )
    if (is.null(x)) {
      next
    }
    row <- x$estimates[
      x$estimates$index == "ICC(A,1)" & x$estimates$level == "subject",
    ]
    n <- n + 1L
    if (row$estimate >= row$conf.low && row$estimate <= row$conf.high) {
      inside <- inside + 1L
    }
  }
  expect_gt(inside / n, 0.85)
})

# O-IFNML: INCOMPLETE/ragged fixed-rater nested (Design 2) single-rater ICC_s(A,1)
# (M36, ADR-046) --------------------------------------------------------------------
#
# The point estimand is NON-CIRCULAR: theta^2_{r:c} is a deterministic function of the
# fixed rater means, so recovering a KNOWN finite-population value from ragged data is a
# genuine independent oracle (cross-engine validates only the raw fit, not the authored
# ragged per-cluster Case-3A correction -- both engines run the same formula). The
# committed fixture (fixtures/incomplete-fixed-nested-oracle.rds) is a seeded single-rater
# coverage sim over {equal-k, unequal-k} x {boundary theta^2 = 0, interior} at n_s = 8,
# PLUS two Fable-review sentinels (fable-review-m36-...-response.md, 2026-07-11): a
# CLUSTER-COUNT boundary cell (C_n = 80 -- a permanent guard for the M27/M28
# incidental-parameters class the ~6-cluster grid could not detect) and a LOW-INFORMATION
# interior cell (n_s = 4 -- so the |bias| pin certifies the correction's SIZE: at n_s = 8 a
# 2b over-correction hides inside .03, at n_s = 4 it is +.037, outside). n_rep = 240
# ([[ragged-coverage-nrep-240]]), regenerated by data-raw/oracle-incomplete-fixed-nested.R
# (#4). Single-rater needs no averaging divisor, so its population value is fixed and
# coverage is clean; the averaged coefficient rides the single-cluster reduction to flat
# M3 (checked live below), using the per-subject k_eff (the M19 random-nested divisor, NOT
# the open per-cluster ICC(c,k) divisor).
test_that("O-IFNML: ragged fixed-nested single-rater MC interval is calibrated + unbiased", {
  o <- readRDS(test_path("fixtures", "incomplete-fixed-nested-oracle.rds"))

  # Nominal everywhere (MC SE ~1.4 pts at n_rep=240; a .90 floor clears noise). The
  # ragged 2b-under-imbalance interaction ADR-046 flagged as the risk resolves nominal.
  expect_gt(min(o$coverage), 0.90)
  expect_gt(mean(o$coverage), 0.93)

  # Boundary theta^2_{r:c} = 0 (the M28 danger zone) is boundary-aware (#3), not under.
  expect_gt(min(o$coverage[o$cell == "boundary"]), 0.90)

  # CLUSTER-COUNT SENTINEL (Fable Q2): boundary coverage at C_n = 80 does NOT decay -- the
  # M28 incidental-parameters collapse (.95/.86/.57 as clusters accrued) is absent under
  # the ragged 2b + average-floor. This cell is the permanent regression guard.
  expect_gt(o$coverage[o$label == "sentinel-Cn80"], 0.90)

  # Point recovers the known finite-population truth: |bias| small in every cell (the
  # non-circular recovery oracle). The n_s = 4 certification cell makes this pin ACTIVE
  # against a 2b over-correction (which would sit at +.037 there, Fable Q4/Q5).
  expect_lt(max(abs(o$mean_bias)), 0.03)

  # The reduction pins committed with the fixture stayed exact (single-cluster == flat M3)
  # and cross-engine agreed on ragged data.
  red <- attr(o, "reductions")
  expect_lt(red[["single"]], 1e-8)
  expect_lt(red[["average"]], 1e-8)
  if (!is.na(red[["cross_engine"]])) {
    expect_lt(red[["cross_engine"]], 1e-3)
  }
})

test_that("O-IFNML/reduction: ragged 1-cluster fixed-nested == flat M3; cross-engine agrees", {
  skip_if_not_installed("glmmTMB")
  # A single-cluster nested-fixed design IS a flat two-way fixed design (M3). icc() refuses
  # one cluster, so -- as the M19 single-cluster reduction -- this is checked at the fit
  # level, composing ICC by hand from the components with the same per-subject k_eff.
  set.seed(7)
  k1 <- 4L
  ns1 <- 40L
  d1 <- expand.grid(subject = seq_len(ns1), r = seq_len(k1))
  d1 <- d1[stats::runif(nrow(d1)) < 0.75, ]
  d1 <- d1[d1$subject %in% names(which(table(d1$subject) >= 2L)), ]
  base <- seq_len(k1) - (k1 + 1) / 2
  d1$score <- 10 +
    (base * 0.5)[d1$r] +
    stats::rnorm(ns1)[d1$subject] +
    stats::rnorm(nrow(d1), 0, 0.6)
  d1$rater <- factor(paste0("r", d1$r))
  flat <- suppressWarnings(icc(
    d1,
    score,
    subject,
    rater,
    raters = "fixed",
    unit = c("single", "average"),
    seed = 1
  ))
  d1n <- d1
  d1n$cluster <- factor(1L)
  d1n$rater <- factor(paste0("1_", d1$r))
  d1n$subject <- factor(d1$subject)
  fit1 <- fit_glmmtmb_nested_fixed(d1n)
  keff1 <- 1 / mean(1 / table(d1n$subject))
  s2s <- fit1$components$subject
  th <- fit1$components$rater
  s2e <- fit1$components$residual
  expect_lt(
    abs(
      flat$estimates$estimate[flat$estimates$index == "ICC(A,1)"] -
        s2s / (s2s + th + s2e)
    ),
    1e-8
  )
  expect_lt(
    abs(
      flat$estimates$estimate[flat$estimates$index == "ICC(A,k)"] -
        s2s / (s2s + (th + s2e) / keff1)
    ),
    1e-8
  )

  # Cross-engine on ragged unequal-k data (raw-fit tie; ragged tolerance, cf. M15).
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  set.seed(11)
  d <- expand.grid(subj = 1:14, r = 1:5, cl = 1:4)
  d <- d[d$r <= c(3, 4, 2, 5)[d$cl], ]
  d <- d[stats::runif(nrow(d)) < 0.8, ]
  d$cluster <- factor(d$cl)
  d$subject <- factor(paste(d$cl, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cl, d$r, sep = "_"))
  d$score <- 10 +
    (d$r - 2) * 0.4 +
    stats::rnorm(56)[interaction(d$cl, d$subj, drop = TRUE)] +
    stats::rnorm(nrow(d), 0, 0.6)
  d <- d[d$subject %in% names(which(table(d$subject) >= 2L)), ]
  gg <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    design = "nested_in_clusters",
    seed = 1
  ))
  ll <- tryCatch(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      design = "nested_in_clusters",
      engine = "lme4",
      seed = 1
    )),
    error = function(e) NULL
  )
  skip_if(
    is.null(ll),
    "lme4 deferred to glmmTMB on this ragged design (singular fit)"
  )
  expect_lt(
    abs(
      gg$estimates$estimate[gg$estimates$index == "ICC(A,1)"] -
        ll$estimates$estimate[ll$estimates$index == "ICC(A,1)"]
    ),
    1e-3
  )
})
