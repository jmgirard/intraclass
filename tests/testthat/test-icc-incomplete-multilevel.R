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
  # multilevel Design-1 subject-level consistency collapses to the M3 flat two-way
  # consistency on the same ragged ratings (spec M9 §6, O-IML/reduction). A one-cluster
  # design is intentionally refused by `icc()` (a multilevel ICC needs >= 2 clusters),
  # so the reduction is checked at the fit level: the five-component multilevel model
  # and the flat two-way model, both fit directly, must give the same sigma^2_s and
  # sigma^2_res. (The seeded data-raw script pins this too.)
  dr <- ragged(
    sim_design1(1, 12, 5, 0.0, 1.0, 0.5, 0.0, 0.6, seed = 4242),
    prop = 0.2,
    seed = 3
  )
  ml <- glmmTMB::glmmTMB(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = dr,
    REML = TRUE
  )
  mlvc <- glmmTMB::VarCorr(ml)$cond
  ml_sc <- as.numeric(attr(mlvc[["cluster:subject"]], "stddev"))^2
  ml_res <- stats::sigma(ml)^2

  flat <- glmmTMB::glmmTMB(
    score ~ 1 + (1 | subject) + (1 | rater),
    data = dr,
    REML = TRUE
  )
  fvc <- glmmTMB::VarCorr(flat)$cond
  f_s <- as.numeric(attr(fvc[["subject"]], "stddev"))^2
  f_res <- stats::sigma(flat)^2

  # Consistency = sigma^2_s / (sigma^2_s + sigma^2_res) matches between the two fits.
  expect_equal(
    ml_sc / (ml_sc + ml_res),
    f_s / (f_s + f_res),
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

# Cluster level on incomplete data (M9 Slice 2) --------------------------------
#
# Only the SINGLE-rater ICC(c,1) is offered on ragged data (signal sigma^2_c, error
# {sigma^2_r, sigma^2_cr} for agreement / {sigma^2_cr} for consistency; spec M5 §3b).
# The averaging divisor ICC(c,k) under imbalance (effective raters PER CLUSTER, not
# the per-subject k_eff) is a modeling choice with no textbook oracle and is deferred
# (ADR-018). Cluster-level IRR needs raters bridging clusters to identify sigma^2_cr.

cluster_single_iccs <- function(d) {
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
  cc <- g("cluster")
  cr <- g("cluster:rater")
  rr <- g("rater")
  c(A1 = cc / (cc + rr + cr), C1 = cc / (cc + cr))
}

test_that("O-IML/lme4: ragged cluster-level ICC(c,1) matches an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- ragged(
    sim_design1(20, 8, 5, 1.5, 0.8, 0.5, 0.4, 0.6, seed = 7),
    prop = 0.2,
    seed = 9
  )
  xa <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    type = "agreement",
    unit = "single",
    seed = 1
  )
  xc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    type = "consistency",
    unit = "single",
    seed = 1
  )
  ref <- cluster_single_iccs(d)
  expect_equal(
    pick(xa, "ICC(A,1)", "cluster"),
    unname(ref["A1"]),
    tolerance = 1e-4
  )
  expect_equal(
    pick(xc, "ICC(C,1)", "cluster"),
    unname(ref["C1"]),
    tolerance = 1e-4
  )
})

test_that("O-IML/reduction: complete data reproduces M5 at BOTH levels", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
  # Complete data keeps both levels and both units (the balanced M5 path).
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  expect_true(x$design$balanced)
  expect_setequal(unique(x$estimates$level), c("subject", "cluster"))
  ref <- cluster_single_iccs(d)
  expect_equal(
    pick(x, "ICC(A,1)", "cluster"),
    unname(ref["A1"]),
    tolerance = 1e-4
  )
})

test_that("cluster-level ICC(c,k) on incomplete data is dropped, not all-or-nothing (#9)", {
  skip_if_not_installed("glmmTMB")
  d <- ragged(
    sim_design1(20, 8, 5, 1.5, 0.8, 0.5, 0.4, 0.6, seed = 7),
    prop = 0.2,
    seed = 9
  )
  # Cluster level ONLY + averaged unit ONLY: nothing is computable -> loud abort
  # (the averaged cluster divisor under imbalance is deferred, spec M9 §3b).
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "cluster",
      unit = "average",
      seed = 1
    ),
    class = "intraclass_unsupported"
  )
  # Default call (both levels, both units): rather than reject the whole call, the
  # averaged CLUSTER row is dropped (with a one-time message) while the subject-level
  # rows (incl. the average) and the single-rater cluster ICC(c,1) are returned -- a
  # partial result, not an abort (#9). The message uses .frequency = "once", so force
  # verbose verbosity to observe it regardless of test ordering.
  withr::local_options(rlib_message_verbosity = "verbose")
  expect_message(
    fit <- icc(d, score, subject, rater, cluster = cluster, seed = 1),
    "Averaged cluster-level"
  )
  expect_s3_class(fit, "icc")
  e <- fit$estimates
  # Subject level keeps both single and average; cluster level keeps only single.
  # The default reports both error definitions (ADR-054), so each level carries its
  # agreement and consistency rows; the averaged cluster ICC(c,k) is the only drop.
  expect_setequal(
    e$index[e$level == "subject"],
    c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")
  )
  expect_setequal(e$index[e$level == "cluster"], c("ICC(A,1)", "ICC(C,1)"))
})

test_that("cluster-level IRR aborts to subject when raters do not bridge clusters", {
  skip_if_not_installed("glmmTMB")
  set.seed(1)
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
      level = "cluster",
      type = "consistency",
      unit = "single",
      seed = 1
    ),
    class = "intraclass_unidentified"
  )
})

test_that("print surfaces the incomplete multilevel design and effective k", {
  skip_if_not_installed("glmmTMB")
  d <- ragged(
    sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707),
    prop = 0.15,
    seed = 7
  )
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    seed = 1
  )
  # Assert the DETERMINISTIC surfaced strings rather than snapshotting the full
  # report -- the multilevel fit's variance components (hence the estimates and MC
  # interval) can differ at the last printed digit across BLAS/platforms, but the
  # design word and the effective-k note are computed from cell counts and are
  # platform-stable. k_eff = harmonic mean of the per-subject rating counts = 3.24.
  out <- cli::cli_fmt(print(x))
  expect_match(out, "Observations: \\d+ \\(incomplete\\)", all = FALSE)
  expect_match(out, "effective 3.24 raters", all = FALSE)
  expect_match(out, "multilevel two-way random", all = FALSE)
})
