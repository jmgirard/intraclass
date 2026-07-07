# Oracle O-IML: incomplete/unbalanced crossed (Design 1) multilevel ICCs, M9 -----
#
# M9 estimates the M5 Design-1 subject-level ICCs (raters crossed with clusters,
# ten Hove, Jorgensen & van der Ark 2022, Eq. 12 / Table 3 top-left) on RAGGED data
# (missing subject x rater cells), by generalizing the M3 connectedness + k_eff
# machinery onto the M5 five-component fit. No new estimand: the subject-level
# agreement error is {rater, residual} and consistency is {residual} -- sigma^2_cr
# (cluster x rater) is NOT in the subject-level error (spec M9 §3a, corrected against
# the shipped M5 icc_point() this session). No textbook worked example exists, so
# correctness rests on (PRINCIPLES.md #1): an lme4 cross-engine fit on the same
# ragged data, a seeded population-recovery simulation with MC-CI coverage,
# reductions to the pinned complete-M5 and flat-incomplete-M3 estimands, and an
# identifiability oracle for the §4b graph guards. Cluster-level IRR on incomplete
# data is deferred to M9 Slice 2. Provenance in
# data-raw/oracle-incomplete-multilevel.R.

# Balanced crossed Design-1 generator with known population components. Raters are
# CROSSED with clusters -> global rater labels (rater "1" is the same person in
# every cluster), which is what distinguishes Design 1 from the nested designs.
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

# MCAR cell deletion keeping raters bridging clusters (so it stays crossed).
ragged <- function(d, prop, seed) {
  set.seed(seed)
  d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
}

pick <- function(x, index, level = "subject") {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

# Independent lme4 five-component fit -> the §3a subject-level coefficients, using
# the CORRECT error sets (no sigma^2_cr in the subject error).
lme4_subject_iccs <- function(d, k_eff) {
  fit <- lme4::lmer(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE,
    control = lme4::lmerControl(check.conv.singular = "ignore")
  )
  vc <- as.data.frame(lme4::VarCorr(fit))
  g <- function(grp) vc$vcov[vc$grp == grp][1]
  vsc <- g("cluster:subject")
  vr <- g("rater")
  vres <- g("Residual")
  c(
    A1 = vsc / (vsc + vr + vres),
    Ak = vsc / (vsc + (vr + vres) / k_eff),
    C1 = vsc / (vsc + vres),
    Ck = vsc / (vsc + vres / k_eff)
  )
}

test_that("O-IML/lme4: ragged Design-1 subject ICCs match an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- ragged(
    sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707),
    prop = 0.15,
    seed = 7
  )
  xa <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    type = "agreement",
    unit = c("single", "average"),
    seed = 1
  )
  xc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    type = "consistency",
    unit = c("single", "average"),
    seed = 1
  )
  ref <- lme4_subject_iccs(d, xa$k_eff)
  expect_equal(pick(xa, "ICC(A,1)"), unname(ref["A1"]), tolerance = 1e-4)
  expect_equal(pick(xa, "ICC(A,k)"), unname(ref["Ak"]), tolerance = 1e-4)
  expect_equal(pick(xc, "ICC(C,1)"), unname(ref["C1"]), tolerance = 1e-4)
  expect_equal(pick(xc, "ICC(C,k)"), unname(ref["Ck"]), tolerance = 1e-4)
})

test_that("O-IML/reduction: complete data reproduces the balanced M5 numbers", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  # Complete crossed data must not touch the incomplete path (k_eff = k, balanced).
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    seed = 1
  )
  expect_true(x$design$balanced)
  expect_equal(x$k_eff, 4)
  ref <- lme4_subject_iccs(d, 4)
  expect_equal(pick(x, "ICC(A,1)"), unname(ref["A1"]), tolerance = 1e-4)
})

test_that("O-IML/reduction: a single cluster equals the flat M3 incomplete two-way", {
  skip_if_not_installed("glmmTMB")
  # With one cluster sigma^2_c -> 0 and sigma^2_cr folds into sigma^2_r, so the
  # multilevel Design-1 subject-level ICCs collapse to the M3 flat two-way ICCs on
  # the same ragged ratings (spec M9 §6, O-IML/reduction).
  d <- sim_design1(1, 12, 5, 0.0, 1.0, 0.5, 0.0, 0.6, seed = 4242)
  dr <- ragged(d, prop = 0.2, seed = 3)
  ml <- icc(
    dr,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    design = "crossed",
    type = "consistency",
    unit = c("single", "average"),
    seed = 1
  )
  flat <- icc(
    dr,
    score,
    subject,
    rater,
    type = "consistency",
    unit = c("single", "average"),
    seed = 1
  )
  expect_equal(
    pick(ml, "ICC(C,1)"),
    flat$estimates$estimate[1],
    tolerance = 1e-3
  )
  expect_equal(
    pick(ml, "ICC(C,k)"),
    flat$estimates$estimate[2],
    tolerance = 1e-3
  )
})

test_that("O-IML/sim: recovers known components and the MC interval covers", {
  skip_if_not_installed("glmmTMB")
  # Large seeded design so a single draw's point estimate is close to the
  # population ICC (recovery), and the boundary-aware MC interval covers it.
  vsc <- 1.0
  vr <- 0.5
  vres <- 0.6
  target_c1 <- vsc / (vsc + vres) # consistency population value (single) = 0.625
  d <- ragged(
    sim_design1(50, 12, 6, 0.8, vsc, vr, 0.3, vres, seed = 7),
    prop = 0.15,
    seed = 9
  )
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    type = "consistency",
    seed = 1
  )
  # Absolute recovery bound (expect_equal's tolerance is relative; sampling error
  # in one large draw is ~0.002 here, so 0.04 absolute is a safe, honest bound).
  expect_lt(abs(pick(x, "ICC(C,1)") - target_c1), 0.04)
  expect_gte(target_c1, x$estimates$conf.low[1])
  expect_lte(target_c1, x$estimates$conf.high[1])
})

# Identifiability oracle (spec M9 §4b) ------------------------------------------

test_that("O-IML/ident: within-cluster disconnection aborts (both types)", {
  skip_if_not_installed("glmmTMB")
  set.seed(1)
  # Cluster 1 splits into two unlinked subject x rater blocks; cluster 2 bridges.
  d <- rbind(
    expand.grid(subject = 1:2, rater = 1:2, cluster = 1),
    data.frame(subject = c(3, 3, 4, 4), rater = c(3, 4, 3, 4), cluster = 1),
    expand.grid(subject = 5:8, rater = 1:4, cluster = 2)
  )
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d$cluster <- factor(d$cluster)
  d$score <- stats::rnorm(nrow(d))
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      type = "consistency",
      seed = 1
    ),
    class = "intraclass_unidentified"
  )
})

test_that("O-IML/ident: cluster x rater disconnection gates agreement only", {
  skip_if_not_installed("glmmTMB")
  set.seed(1)
  # Raters 1,2 only in cluster 1; raters 3,4 only in cluster 2 -> cluster x rater
  # graph is disconnected. sigma^2_r cannot separate from sigma^2_cr (agreement
  # aborts) but the residual is fine (consistency proceeds).
  d <- rbind(
    expand.grid(subject = 1:4, rater = 1:2, cluster = 1),
    expand.grid(subject = 5:8, rater = 3:4, cluster = 2)
  )
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d$cluster <- factor(d$cluster)
  d$score <- stats::rnorm(nrow(d))
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      type = "agreement",
      seed = 1
    ),
    class = "intraclass_unidentified"
  )
  # Consistency proceeds: sigma^2_{s:c}/residual are identified. The crossed fit is
  # singular in the sigma^2_r/sigma^2_cr direction (they are confounded here), which
  # glmmTMB flags -- an honest boundary signal, irrelevant to consistency.
  expect_s3_class(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      type = "consistency",
      seed = 1
    )),
    "icc"
  )
})

# The `design` declaration and ragged-design guards (spec M9 §4a) ----------------

test_that("ambiguous ragged pattern aborts unless `design` is declared", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  # Confine rater 4 to cluster 1: some raters bridge, some do not -> ambiguous.
  da <- d[!(d$rater == "4" & d$cluster != "1"), , drop = FALSE]
  expect_error(
    icc(
      da,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      seed = 1
    ),
    class = "intraclass_unidentified"
  )
  # Declaring the design resolves it (raters 1-3 still bridge, so agreement is
  # identified here).
  expect_s3_class(
    icc(
      da,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      seed = 1
    ),
    "icc"
  )
})

test_that("`design` requires a cluster column and a valid value", {
  skip_if_not_installed("glmmTMB")
  d <- sim_design1(2, 6, 4, 0.0, 1.0, 0.5, 0.0, 0.6, seed = 5)
  expect_error(
    icc(d, score, subject, rater, design = "crossed", seed = 1),
    class = "intraclass_error"
  )
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nonsense",
      seed = 1
    ),
    class = "intraclass_error"
  )
})

test_that("cluster-level IRR on incomplete data is deferred (loud abort)", {
  skip_if_not_installed("glmmTMB")
  d <- ragged(
    sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707),
    prop = 0.15,
    seed = 7
  )
  # Default level includes "cluster"; on incomplete data that is not yet supported.
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, seed = 1),
    class = "intraclass_unsupported"
  )
})
