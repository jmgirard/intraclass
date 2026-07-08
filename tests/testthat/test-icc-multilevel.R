# Oracle O-ML: multilevel ICCs (subject- & cluster-level), M5 -------------------
#
# Design 1 of ten Hove, Jorgensen & van der Ark (2022, Table 3): subjects nested
# in clusters, raters crossed with both. Provenance (seeded reference values and
# the standalone stopifnot checks) in data-raw/oracle-multilevel.R. No textbook
# worked example exists for this estimand (as with O5), so correctness rests on
# an lme4 cross-engine fit, a seeded population-recovery simulation, and a
# reduction to the pinned single-level numbers (PRINCIPLES.md #1).

# Balanced Design-1 generator with known population components.
sim_multilevel <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# Pull one coefficient out of the estimates table by index + level.
pick <- function(x, index, level) {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

test_that("O-ML/lme4: multilevel ICCs match an independent lme4 fit (<1e-4)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  m <- lme4::lmer(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  cl <- as.numeric(vc$cluster)
  sc <- as.numeric(vc[["cluster:subject"]])
  ra <- as.numeric(vc$rater)
  cr <- as.numeric(vc[["cluster:rater"]])
  re <- stats::sigma(m)^2
  k <- 6

  expect_equal(
    pick(x, "ICC(A,1)", "subject"),
    sc / (sc + ra + re),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,k)", "subject"),
    sc / (sc + (ra + re) / k),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,1)", "cluster"),
    cl / (cl + ra + cr),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,k)", "cluster"),
    cl / (cl + (ra + cr) / k),
    tolerance = 1e-4
  )

  # Consistency variants read the same fit (residual -> cluster_rater at cluster).
  xc <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )
  expect_equal(
    pick(xc, "ICC(C,1)", "subject"),
    sc / (sc + re),
    tolerance = 1e-4
  )
  expect_equal(
    pick(xc, "ICC(C,1)", "cluster"),
    cl / (cl + cr),
    tolerance = 1e-4
  )
})

test_that("O-ML/sim: known population ICCs are recovered and covered", {
  skip_if_not_installed("glmmTMB")
  k <- 20
  pop <- c(
    cluster = 1.0,
    subject = 1.2,
    rater = 0.7,
    cluster_rater = 0.16,
    residual = 0.5
  )
  pop_subj_a1 <- pop[["subject"]] /
    (pop[["subject"]] + pop[["rater"]] + pop[["residual"]])
  pop_clus_a1 <- pop[["cluster"]] /
    (pop[["cluster"]] + pop[["rater"]] + pop[["cluster_rater"]])
  d <- sim_multilevel(40, 5, k, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 424242)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 20260707)

  # Absolute recovery tolerance (expect_equal's `tolerance` is relative).
  expect_lt(abs(pick(x, "ICC(A,1)", "subject") - pop_subj_a1), 0.05)
  expect_lt(abs(pick(x, "ICC(A,1)", "cluster") - pop_clus_a1), 0.05)

  # The boundary-aware Monte-Carlo interval covers both population values.
  e <- x$estimates
  sub <- e[e$index == "ICC(A,1)" & e$level == "subject", ]
  clu <- e[e$index == "ICC(A,1)" & e$level == "cluster", ]
  expect_true(sub$conf.low <= pop_subj_a1 && pop_subj_a1 <= sub$conf.high)
  expect_true(clu$conf.low <= pop_clus_a1 && pop_clus_a1 <= clu$conf.high)
})

test_that("O-ML/reduction: subject level is the single-level estimand", {
  # Algebraic: the subject-level (signal, error set) equals the single-level one.
  ml <- icc_estimand(type = "agreement", level = "subject", multilevel = TRUE)
  sl <- icc_estimand(type = "agreement")
  expect_identical(ml$signal, sl$signal)
  expect_identical(ml$error, sl$error)
  mlc <- icc_estimand(
    type = "consistency",
    level = "subject",
    multilevel = TRUE
  )
  slc <- icc_estimand(type = "consistency")
  expect_identical(mlc$error, slc$error)
})

test_that("O-ML/reduction: zero cluster variance reduces to single-level", {
  skip_if_not_installed("glmmTMB")
  # sigma^2_c = sigma^2_cr = 0, many clusters: subject-level ICC matches a
  # single-level two-way fit on the same ratings (M5 spec §5). No exact-SF claim.
  d <- sim_multilevel(40, 8, 6, 0, 1.2, 0.7, 0, 0.5, seed = 99)
  x_ml <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    seed = 1
  )
  x_sl <- icc(d, score, subject, rater, seed = 1)
  expect_equal(
    pick(x_ml, "ICC(A,1)", "subject"),
    x_sl$estimates$estimate[x_sl$estimates$index == "ICC(A,1)"],
    tolerance = 1e-2
  )
})

test_that("multilevel invariants and object shape", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  x <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  e <- x$estimates
  # Both levels returned by default; a level column disambiguates them.
  expect_setequal(unique(e$level), c("subject", "cluster"))
  expect_true(all(e$estimate >= 0 & e$estimate <= 1))
  # Average >= single at each level (Spearman-Brown direction).
  expect_gte(pick(x, "ICC(A,k)", "subject"), pick(x, "ICC(A,1)", "subject"))
  expect_gte(pick(x, "ICC(A,k)", "cluster"), pick(x, "ICC(A,1)", "cluster"))
  # Multilevel ICCs carry no Shrout & Fleiss label.
  expect_true(all(is.na(e$sf_index)))
  expect_true(x$design$multilevel)
  expect_identical(x$n$clusters, 20L)

  # A single requested level returns only that level.
  xs <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    seed = 1
  )
  expect_setequal(unique(xs$estimates$level), "cluster")
})

test_that("multilevel identifiability and scope guards fail loudly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)

  # < 2 clusters.
  d1 <- d[d$cluster == "1", ]
  expect_error(
    icc(d1, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # cluster 1:1 with subject (one subject per cluster) -> unidentified.
  d2 <- d[d$subj == 1, ]
  expect_error(
    icc(d2, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # a subject that spans two clusters breaks the nesting assumption.
  d3 <- d
  d3$subject <- factor(d3$subj) # ids reused across clusters
  expect_error(
    icc(d3, score, subject, rater, cluster = cluster),
    class = "intraclass_unidentified"
  )
  # Numeric unit (a multilevel D-study projection) is out of scope. Fixed-rater
  # multilevel is now supported at the subject level (M10, test-icc-fixed-multilevel.R).
  expect_error(
    icc(d, score, subject, rater, cluster = cluster, unit = c("single", 3)),
    class = "intraclass_unsupported"
  )
  # level without a cluster column is a usage error.
  expect_error(
    icc(ratings, score, subject, rater, level = "cluster"),
    class = "intraclass_error"
  )
})

# Oracle O-conflated: conflated single-level ICC (Eq. 14, M17 Slice 1) ----------
#
# `level = "conflated"` collapses the multilevel structure -- the biased
# single-level ICC a naive analyst gets by ignoring clusters (ten Hove et al.
# 2022, Eq. 14): signal sigma^2_c + sigma^2_{s:c}, error the three rater-related
# terms. Shipped as a diagnostic contrast, agreement-only (estimand-spec
# M17-conflated-icc.md). Oracles: an independent lme4 fit, the closed-form Eq. 14
# on the reported components, and population recovery (which coincides with the
# flat single-level ICC that ignores clustering).

test_that("O-conflated/lme4: conflated ICC = Eq. 14 from an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    seed = 1
  )
  m <- lme4::lmer(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  cl <- as.numeric(vc$cluster)
  sc <- as.numeric(vc[["cluster:subject"]])
  ra <- as.numeric(vc$rater)
  cr <- as.numeric(vc[["cluster:rater"]])
  re <- stats::sigma(m)^2
  k <- 6
  sig <- cl + sc
  err <- ra + cr + re
  expect_equal(
    pick(x, "ICC(A,1)", "conflated"),
    sig / (sig + err),
    tolerance = 1e-4
  )
  expect_equal(
    pick(x, "ICC(A,k)", "conflated"),
    sig / (sig + err / k),
    tolerance = 1e-4
  )
})

test_that("O-conflated/Eq14: estimate = closed-form Eq. 14 on the reported components", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    seed = 1
  )
  vc <- x$components
  sig <- vc$cluster + vc$subject
  err <- vc$rater + vc$cluster_rater + vc$residual
  k <- x$k_eff
  expect_equal(
    pick(x, "ICC(A,1)", "conflated"),
    sig / (sig + err),
    tolerance = 1e-10
  )
  expect_equal(
    pick(x, "ICC(A,k)", "conflated"),
    sig / (sig + err / k),
    tolerance = 1e-10
  )
})

test_that("O-conflated/population: recovers the known conflated reliability (~ flat ICC)", {
  skip_if_not_installed("glmmTMB")
  vc <- 1.0
  vsc <- 1.2
  vr <- 0.7
  vcr <- 0.16
  vres <- 0.5
  d <- sim_multilevel(40, 20, 6, vc, vsc, vr, vcr, vres, seed = 424242)
  pop1 <- (vc + vsc) / ((vc + vsc) + vr + vcr + vres)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    seed = 1
  )
  # sigma^2_c is estimated from only 40 clusters, so the point estimate is noisy;
  # the honest recovery check is that the boundary-aware MC interval covers the
  # known population value (as in O-ML/sim), with a generous point sanity floor.
  expect_lt(abs(pick(x, "ICC(A,1)", "conflated") - pop1), 0.1)
  row <- x$estimates[
    x$estimates$index == "ICC(A,1)" & x$estimates$level == "conflated",
  ]
  expect_true(row$conf.low <= pop1 && pop1 <= row$conf.high)
  # "Conflated" means ignoring the cluster level: on the same data it tracks the
  # flat single-level agreement ICC (a different fit, hence a loose agreement).
  flat <- icc(d, score, subject, rater, seed = 1)
  flat1 <- flat$estimates$estimate[flat$estimates$index == "ICC(A,1)"]
  expect_equal(pick(x, "ICC(A,1)", "conflated"), flat1, tolerance = 0.02)
})

test_that("conflated ICC stays inside [0, 1] and average >= single", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    seed = 1
  )
  a1 <- pick(x, "ICC(A,1)", "conflated")
  ak <- pick(x, "ICC(A,k)", "conflated")
  expect_true(a1 >= 0 && a1 <= 1)
  expect_true(ak >= a1)
  # A conflated row carries no Shrout & Fleiss label (no single-level SF form).
  row <- x$estimates[
    x$estimates$level == "conflated" & x$estimates$index == "ICC(A,1)",
  ]
  expect_true(is.na(row$sf_index))
})

test_that("conflated can be requested alongside the correctly-partitioned levels", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = c("subject", "cluster", "conflated"),
    seed = 1
  )
  expect_true(all(c("subject", "cluster", "conflated") %in% x$estimates$level))
  # The conflated (ignore-clusters) value sits between/around the two correct
  # levels, never silently replacing them.
  expect_length(pick(x, "ICC(A,1)", "conflated"), 1)
})

test_that("conflated ICC is agreement-only and needs a crossed random design", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  # (Incomplete data is no longer refused -- M18 Slice 2 ships it; see the O-conflated
  # incomplete section below. Consistency/fixed/no-cluster stay classed aborts.)
  # Consistency-conflated is not in the paper: parked, not shipped.
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "conflated",
      type = "consistency"
    ),
    class = "intraclass_unsupported"
  )
  # Fixed raters: Eq. 14 is a random-rater formula.
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "conflated",
      raters = "fixed"
    ),
    class = "intraclass_unsupported"
  )
  # Conflated without a cluster column is a usage error (nothing to conflate).
  expect_error(
    icc(ratings, score, subject, rater, level = "conflated"),
    class = "intraclass_error"
  )
})

test_that("conflated ICC is labeled a diagnostic contrast in print and tidy", {
  skip_if_not_installed("glmmTMB")
  d <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = c("subject", "cluster", "conflated"),
    seed = 1
  )
  lines <- format(x)
  # The report flags it as a diagnostic contrast, not a recommended coefficient.
  expect_true(any(grepl("[Dd]iagnostic contrast", lines)))
  expect_true(any(grepl("NOT a recommended", lines)))
  expect_true(any(grepl("conflated", lines)))
  # tidy() carries the conflated row, explicitly labeled in the level column.
  td <- tidy(x)
  expect_true("conflated" %in% td$level)
  # A plain subject/cluster fit prints no conflated note.
  y <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  expect_false(any(grepl("[Dd]iagnostic contrast", format(y))))
})

# Oracle O-conflated (INCOMPLETE): conflated ICC on ragged data, M18 Slice 2 ------
#
# M18 Slice 2 (ADR-028) opens the question M17-conflated-icc.md §6 left closed:
# whether Eq. 14 is well-posed on ragged multilevel data. It is. The conflated ICC
# LUMPS sigma^2_r + sigma^2_cr + sigma^2_res into one error and sigma^2_c +
# sigma^2_{s:c} into one signal, so it is the flat two-way ICC read off the
# five-component fit, with the same flat k_eff (harmonic mean of ratings per subject)
# divisor the subject level uses. On ragged data it (a) equals the closed-form Eq. 14
# on the reported components (exact), (b) agrees cross-engine < 1e-4, and (c) tracks
# the flat incomplete two-way agreement icc() (cluster dropped) at the population
# level -- the same operational meaning as complete data (spec §5) -- while staying
# visibly biased away from the correctly-partitioned subject level. Maintainer posture
# (ADR-028) was attempt-then-degrade; the oracle held, so it ships (no reclassification).

ragged_ml <- function(d, prop, seed) {
  set.seed(seed)
  d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
}

test_that("O-conflated/incomplete Eq14: ragged conflated = closed-form Eq. 14 on components", {
  skip_if_not_installed("glmmTMB")
  d <- ragged_ml(
    sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    seed = 1
  )
  vc <- x$components
  sig <- vc$cluster + vc$subject
  err <- vc$rater + vc$cluster_rater + vc$residual
  k <- x$k_eff
  expect_equal(
    pick(x, "ICC(A,1)", "conflated"),
    sig / (sig + err),
    tolerance = 1e-10
  )
  expect_equal(
    pick(x, "ICC(A,k)", "conflated"),
    sig / (sig + err / k),
    tolerance = 1e-10
  )
  # The divisor is the flat harmonic mean of ratings per subject (< the balanced k = 6).
  expect_lt(k, 6)
})

test_that("O-conflated/incomplete lme4: ragged conflated agrees cross-engine", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- ragged_ml(
    sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  xg <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    seed = 1
  )
  xl <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    unit = c("single", "average"),
    engine = "lme4",
    seed = 1
  )
  expect_equal(
    pick(xg, "ICC(A,1)", "conflated"),
    pick(xl, "ICC(A,1)", "conflated"),
    tolerance = 1e-4
  )
  expect_equal(
    pick(xg, "ICC(A,k)", "conflated"),
    pick(xl, "ICC(A,k)", "conflated"),
    tolerance = 1e-4
  )
})

test_that("O-conflated/incomplete: tracks the flat two-way ICC, stays biased vs subject", {
  skip_if_not_installed("glmmTMB")
  d <- ragged_ml(
    sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = c("subject", "conflated"),
    unit = c("single", "average"),
    seed = 1
  )
  # "Conflated" = ignore clusters: on the same ragged data it tracks the flat two-way
  # agreement icc() (a different fit, hence a loose population-level agreement).
  flat <- icc(d, score, subject, rater, seed = 1)$estimates
  flat1 <- flat$estimate[flat$index == "ICC(A,1)"]
  expect_equal(pick(x, "ICC(A,1)", "conflated"), flat1, tolerance = 0.02)
  # The whole point of the diagnostic: it stays visibly biased away from the
  # correctly-partitioned subject level on ragged data too.
  expect_gt(
    abs(pick(x, "ICC(A,1)", "conflated") - pick(x, "ICC(A,1)", "subject")),
    0.02
  )
  # Still a valid coefficient with a boundary-aware interval; average >= single.
  a1 <- pick(x, "ICC(A,1)", "conflated")
  ak <- pick(x, "ICC(A,k)", "conflated")
  expect_true(a1 >= 0 && a1 <= 1 && ak >= a1)
  row <- x$estimates[
    x$estimates$level == "conflated" & x$estimates$index == "ICC(A,1)",
  ]
  expect_true(is.finite(row$conf.low) && is.finite(row$conf.high))
})
