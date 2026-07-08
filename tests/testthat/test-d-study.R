# test-d-study.R
# ===========================================================================
# D-study projection -- Phi(m), reliability at other numbers of raters, and
# the numeric-`unit` sugar in icc().
#
# The projection is a change of the averaging divisor in the (signal,
# {error set}, divisor) estimand (ROADMAP; M4.5 spec). It has clean ANALYTIC
# oracles (PRINCIPLES.md #1), so we lean on them rather than another package:
#
#   O-SB   consistency projection is the Spearman-Brown prophecy formula
#          applied to ICC(C,1):  Phi_C(m) = m*rho / (1 + (m-1)*rho).
#   O-GT   agreement projection is the GT dependability form from the known
#          components:  Phi_A(m) = s / (s + (r + res)/m).
#   O-psych  at m = n_raters the projection must equal icc()'s own average-
#          measure estimate, which equals psych::ICC (a THIRD, independent
#          implementation) on the balanced Shrout & Fleiss data.
#   O-sim  a seeded simulation recovers the population Phi(m).
#
# All values trace to a source or a seeded computation (PRINCIPLES.md #4); the
# committed data-raw/oracle-d-study.R regenerates the simulation oracle.
# ===========================================================================

# Analytic oracles (independent of the estimator's own arithmetic).
sb_project <- function(rho1, m) m * rho1 / (1 + (m - 1) * rho1)
gt_project <- function(s, r, res, m) s / (s + (r + res) / m)

fit_ds <- function(type = "agreement", raters = "random") {
  suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    type = type,
    raters = raters,
    unit = c("single", "average"),
    seed = 1
  ))
}

test_that("consistency projection matches the Spearman-Brown formula (O-SB)", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_ds(type = "consistency")
  rho1 <- icc_estimate(fit, "ICC(C,1)")
  d <- d_study(fit, m = c(1, 2, 3, 5, 10, 20))

  expect_equal(d$estimate, sb_project(rho1, d$m), tolerance = 1e-8)
})

test_that("agreement projection matches the GT dependability form (O-GT)", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_ds(type = "agreement")
  vc <- fit$components
  d <- d_study(fit, m = c(1, 2, 4, 7, 15))

  expect_equal(
    d$estimate,
    gt_project(vc$subject, vc$rater, vc$residual, d$m),
    tolerance = 1e-8
  )
})

test_that("projecting to the observed count reproduces ICC(*,k) (O-psych)", {
  skip_if_not_installed("glmmTMB")

  # n_raters = 4 on the balanced SF data, so k_eff = 4 and Phi(4) must equal the
  # average-measure estimate icc() reports directly.
  for (ty in c("agreement", "consistency")) {
    fit <- fit_ds(type = ty)
    k <- fit$n$raters
    at_k <- d_study(fit, m = k)$estimate
    avg <- icc_estimate(fit, if (ty == "agreement") "ICC(A,k)" else "ICC(C,k)")
    expect_equal(at_k, avg, tolerance = 1e-8)
  }
})

test_that("projection agrees with psych::ICC average-measure (O-psych)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("psych")

  # Third, fully independent implementation. psych's average-measure ICC is the
  # projection to m = n_raters.
  res <- psych::ICC(sf_ratings_wide())$results

  agr <- d_study(fit_ds("agreement"), m = 4)$estimate
  con <- d_study(fit_ds("consistency"), m = 4)$estimate
  expect_equal(agr, res$ICC[res$type == "ICC2k"], tolerance = 1e-4)
  expect_equal(con, res$ICC[res$type == "ICC3k"], tolerance = 1e-4)
})

test_that("numeric unit in icc() equals the d_study projection at that m", {
  skip_if_not_installed("glmmTMB")

  x <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average", 3, 7),
    seed = 1
  ))
  td <- tidy(x)
  # The projected rows carry the ICC(A,m) label and no Shrout & Fleiss form.
  expect_true(all(c("ICC(A,3)", "ICC(A,7)") %in% td$index))
  expect_true(all(is.na(td$sf_index[td$index %in% c("ICC(A,3)", "ICC(A,7)")])))

  d <- d_study(
    icc(sf_ratings_long(), score, subject, rater, seed = 1),
    m = c(3, 7)
  )
  expect_equal(
    td$estimate[match(c("ICC(A,3)", "ICC(A,7)"), td$index)],
    d$estimate,
    tolerance = 1e-8
  )
})

test_that("the projected curve is increasing in m and bounded in [0, 1]", {
  skip_if_not_installed("glmmTMB")

  d <- d_study(fit_ds("agreement"), m = 1:12)
  expect_true(all(diff(d$estimate) > 0)) # more raters -> more reliable
  expect_true(all(d$estimate >= 0 & d$estimate <= 1))
  # Boundary-aware MC interval: finite, ordered, inside [0, 1].
  expect_true(all(is.finite(d$conf.low) & is.finite(d$conf.high)))
  expect_true(all(d$conf.low <= d$estimate & d$estimate <= d$conf.high))
  expect_true(all(d$conf.low >= 0 & d$conf.high <= 1))
})

test_that("few-rater projection gives honestly wider intervals than many-rater", {
  skip_if_not_installed("glmmTMB")

  # sigma^2_r is estimated from only n_raters raters, so extrapolating far beyond
  # the observed design carries more uncertainty per unit of estimate. The point
  # is that the interval does not pretend to certainty it lacks: the SE stays
  # substantial across the curve.
  d <- d_study(fit_ds("agreement"), m = c(1, 50))
  expect_true(all(d$std.error > 0.05))
})

test_that("a seeded projection is reproducible and RNG-neutral (#9, #12)", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_ds("agreement")
  a <- d_study(fit, m = 1:5, seed = 42)
  b <- d_study(fit, m = 1:5, seed = 42)
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)

  set.seed(7)
  before <- .Random.seed
  d_study(fit, m = 1:5, seed = 123)
  expect_identical(.Random.seed, before)
})

test_that("fixed-rater absolute agreement projection is refused (#5)", {
  skip_if_not_installed("glmmTMB")

  fixed_agr <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    type = "agreement",
    raters = "fixed",
    seed = 1
  ))
  expect_error(d_study(fixed_agr, m = 1:5), class = "intraclass_unidentified")
  # And the numeric-unit path in icc() refuses it up front.
  expect_error(
    icc(
      sf_ratings_long(),
      score,
      subject,
      rater,
      type = "agreement",
      raters = "fixed",
      unit = 3
    ),
    class = "intraclass_unidentified"
  )
  # Fixed-rater CONSISTENCY projects fine (Spearman-Brown on ICC(3,1)).
  fixed_con <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    seed = 1
  ))
  dc <- d_study(fixed_con, m = 1:5)
  expect_equal(
    dc$estimate,
    sb_project(icc_estimate(fixed_con, "ICC(C,1)"), 1:5),
    tolerance = 1e-8
  )
})

test_that("d_study validates its inputs (#5, #8)", {
  skip_if_not_installed("glmmTMB")

  expect_error(d_study("not an icc"), class = "intraclass_error")
  fit <- fit_ds("agreement")
  expect_error(d_study(fit, m = 0), class = "intraclass_error")
  expect_error(d_study(fit, m = c(2, NA)), class = "intraclass_error")
  expect_error(d_study(fit, m = "three"), class = "intraclass_error")
})

test_that("the recovered population Phi(m) is covered by the interval (O-sim)", {
  skip_if_not_installed("glmmTMB")

  # Seeded simulation with known components (mirrors O3). The projection to a
  # design NOT run (m = 12 from k = 6 observed) must recover the population value
  # and cover it. Regenerated by data-raw/oracle-d-study.R.
  set.seed(2025)
  n <- 120L
  k <- 6L
  v_s <- 4
  v_r <- 1
  v_res <- 2

  subj <- stats::rnorm(n, 0, sqrt(v_s))
  rat <- stats::rnorm(k, 0, sqrt(v_r))
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(v_res))

  fit <- icc(grid, score, subject, rater, seed = 1)
  d <- d_study(fit, m = c(6, 12), seed = 1)

  pop <- gt_project(v_s, v_r, v_res, c(6, 12))
  expect_equal(d$estimate, pop, tolerance = 0.05)
  expect_true(all(d$conf.low <= pop & pop <= d$conf.high))
})

# Multilevel rater-count projection (M17 Slice 2) -------------------------------
#
# d_study() projects the rater count m for the subject-level (Eq. 12) and
# cluster-level (Eq. 13) multilevel ICCs -- a divisor change on the M5 estimand
# (estimand-spec M4.5 §7). Oracles: reduction to icc()'s ICC(*,k) at m = observed
# k per level, an independent lme4 five-component fit, and population recovery.

sim_ml_ds <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
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

test_that("multilevel d_study projects both levels with a level column", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  fit <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  ds <- d_study(fit, m = 1:8)
  expect_true("level" %in% names(ds))
  expect_setequal(unique(ds$level), c("subject", "cluster"))
  expect_identical(nrow(ds), 16L) # 8 m x 2 levels
  # Bounded and monotone increasing in m within each level.
  for (lv in c("subject", "cluster")) {
    sub <- ds[ds$level == lv, ]
    sub <- sub[order(sub$m), ]
    expect_true(all(sub$estimate >= 0 & sub$estimate <= 1))
    expect_true(all(diff(sub$estimate) >= -1e-9))
  }
})

test_that("O-ML-reduction: at m = observed k, projection equals icc() ICC(*,k) per level", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    unit = c("single", "average"),
    seed = 1
  )
  ds <- d_study(fit, m = 6)
  e <- fit$estimates
  for (lv in c("subject", "cluster")) {
    proj <- ds$estimate[ds$level == lv & ds$m == 6]
    icc_ak <- e$estimate[e$index == "ICC(A,k)" & e$level == lv]
    expect_equal(proj, icc_ak, tolerance = 1e-6)
  }
})

test_that("O-ML-lme4: multilevel projection matches an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  fit <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  ds <- d_study(fit, m = c(3, 10))
  m <- lme4::lmer(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  sc <- as.numeric(vc[["cluster:subject"]])
  cl <- as.numeric(vc$cluster)
  ra <- as.numeric(vc$rater)
  cr <- as.numeric(vc[["cluster:rater"]])
  re <- stats::sigma(m)^2
  for (mm in c(3, 10)) {
    subj <- ds$estimate[ds$level == "subject" & ds$m == mm]
    clus <- ds$estimate[ds$level == "cluster" & ds$m == mm]
    expect_equal(subj, sc / (sc + (ra + re) / mm), tolerance = 1e-4)
    expect_equal(clus, cl / (cl + (ra + cr) / mm), tolerance = 1e-4)
  }
})

test_that("O-ML-sim: population Phi(m) recovered and covered at an m not run", {
  skip_if_not_installed("glmmTMB")
  vc <- 1.0
  vsc <- 1.2
  vr <- 0.7
  vcr <- 0.16
  vres <- 0.5
  d <- sim_ml_ds(40, 10, 6, vc, vsc, vr, vcr, vres, seed = 424242)
  fit <- icc(d, score, subject, rater, cluster = cluster, seed = 20260707)
  ds <- d_study(fit, m = 12)
  # Project subject and cluster to m = 12 (not the observed 6).
  pop_subj <- vsc / (vsc + (vr + vres) / 12)
  pop_clus <- vc / (vc + (vr + vcr) / 12)
  s <- ds[ds$level == "subject" & ds$m == 12, ]
  c_ <- ds[ds$level == "cluster" & ds$m == 12, ]
  expect_lt(abs(s$estimate - pop_subj), 0.05)
  expect_true(s$conf.low <= pop_subj && pop_subj <= s$conf.high)
  expect_true(c_$conf.low <= pop_clus && pop_clus <= c_$conf.high)
})

test_that("multilevel consistency projection is Spearman-Brown of ICC(C,1) per level", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    type = "consistency",
    seed = 1
  )
  ds <- d_study(fit, m = 1:6)
  e <- fit$estimates
  for (lv in c("subject", "cluster")) {
    rho1 <- e$estimate[e$index == "ICC(C,1)" & e$level == lv]
    for (mm in c(2, 4)) {
      proj <- ds$estimate[ds$level == lv & ds$m == mm]
      expect_equal(proj, sb_project(rho1, mm), tolerance = 1e-4)
    }
  }
})

test_that("multilevel d_study scope guards (#5, #8)", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  # Incomplete multilevel: the subject level now projects (M18 Slice 3); the cluster
  # level is dropped with a note (its ragged ICC(c,k) divisor is the open M9 question).
  d_missing <- d[!(d$cluster == "1" & d$rater == "1"), ]
  fit_inc <- icc(d_missing, score, subject, rater, cluster = cluster, seed = 1)
  ds_inc <- suppressMessages(d_study(fit_inc, m = 1:4))
  expect_setequal(unique(ds_inc$level), "subject")
  # A conflated-only fit has nothing to project.
  fit_conf <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    seed = 1
  )
  expect_error(d_study(fit_conf, m = 1:4), class = "intraclass_unsupported")
  # The conflated diagnostic is skipped when requested alongside real levels.
  fit_all <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = c("subject", "cluster", "conflated"),
    seed = 1
  )
  ds <- d_study(fit_all, m = 1:4)
  expect_false("conflated" %in% ds$level)
  expect_setequal(unique(ds$level), c("subject", "cluster"))
})

test_that("nested multilevel projects the subject level only", {
  skip_if_not_installed("glmmTMB")
  # Design 2: raters nested in clusters (cluster-unique rater labels).
  d <- sim_ml_ds(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  fit <- suppressMessages(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nested_in_clusters",
      seed = 1
    )
  )
  ds <- d_study(fit, m = 1:5)
  expect_setequal(unique(ds$level), "subject")
})

test_that("multilevel d_study print/tidy/format carry the level column", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  ds <- d_study(
    icc(d, score, subject, rater, cluster = cluster, seed = 1),
    m = 1:4
  )
  lines <- format(ds)
  expect_true(any(grepl("multilevel", lines)))
  expect_true(any(grepl("level", lines)))
  expect_invisible(print(ds))
  td <- tidy(ds)
  expect_true("level" %in% names(td))
  expect_setequal(unique(td$level), c("subject", "cluster"))
  g <- glance(ds)
  expect_identical(nrow(g), 1L)
})

# Oracle O-IDS: INCOMPLETE subject-level multilevel d_study(), M18 Slice 3 --------
#
# M18 Slice 3 (ADR-028) lifts the balanced-only d_study() guard for the SUBJECT level:
# projection moves only the averaging divisor `m`, and the subject estimand's error
# divisor is `m` itself (not k_eff), so the ragged M9 five-component fit's components
# project unchanged. The CLUSTER level stays bounded -- projecting `m` raters is the
# averaged ICC(c,k) case, whose per-cluster divisor under imbalance is the open M9
# question (spec M4.5 §7.2, M9 §9) -- so it is dropped with a note (or aborts when it
# is the only level). Oracles: reduction to the fitted subject ICC(A,k) at m = k_eff,
# an independent lme4 fit, and the monotone/[0,1] invariants, all on ragged data.

ragged_ds <- function(d, prop, seed) {
  set.seed(seed)
  d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
}

test_that("O-IDS/reduction: ragged subject projection at m = k_eff equals fitted ICC(A,k)", {
  skip_if_not_installed("glmmTMB")
  d <- ragged_ds(
    sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    unit = c("single", "average"),
    seed = 1
  )
  expect_false(isTRUE(fit$design$balanced))
  keff <- fit$k_eff
  ds <- suppressMessages(d_study(fit, m = keff))
  proj <- ds$estimate[ds$level == "subject"]
  fitted_ak <- fit$estimates$estimate[
    fit$estimates$index == "ICC(A,k)" & fit$estimates$level == "subject"
  ]
  expect_equal(proj, fitted_ak, tolerance = 1e-6)
})

test_that("O-IDS: ragged subject curve projects, is monotone in [0, 1], cluster dropped", {
  skip_if_not_installed("glmmTMB")
  d <- ragged_ds(
    sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  fit <- icc(d, score, subject, rater, cluster = cluster, seed = 1)
  # The default subject+cluster fit drops the cluster level with a one-time note. The
  # note uses .frequency = "once", so force verbose verbosity to observe it regardless
  # of test ordering.
  withr::local_options(rlib_message_verbosity = "verbose")
  expect_message(
    ds <- d_study(fit, m = 1:10),
    "subject level only"
  )
  expect_setequal(unique(ds$level), "subject")
  ds <- ds[order(ds$m), ]
  expect_true(all(ds$estimate >= 0 & ds$estimate <= 1))
  expect_true(all(diff(ds$estimate) >= -1e-9))
  # A boundary-aware interval is present at every m (never a bare point, #3).
  expect_true(all(is.finite(ds$conf.low) & is.finite(ds$conf.high)))
})

test_that("O-IDS/lme4: ragged subject projection matches an independent lme4 fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- ragged_ds(
    sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  dg <- suppressMessages(
    d_study(
      icc(d, score, subject, rater, cluster = cluster, seed = 1),
      m = c(3, 8)
    )
  )
  dl <- suppressMessages(suppressWarnings(
    d_study(
      icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        engine = "lme4",
        seed = 1
      ),
      m = c(3, 8)
    )
  ))
  expect_equal(
    dg$estimate[dg$level == "subject"],
    dl$estimate[dl$level == "subject"],
    tolerance = 1e-4
  )
})

test_that("O-IDS: cluster-only incomplete fit refuses projection (bounded, #5)", {
  skip_if_not_installed("glmmTMB")
  d <- ragged_ds(
    sim_ml_ds(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260708),
    0.18,
    20260708
  )
  fit_c <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    seed = 1
  )
  expect_error(d_study(fit_c, m = 1:4), class = "intraclass_unsupported")
})

# Oracle O-Boot-DS: bootstrap-projected d_study() bands, M18 Slice 4 -------------
#
# M18 Slice 4 (ADR-025 deferral, ADR-028): the d_study() band follows the fit's
# `ci_method`. A bootstrap fit stores its kept resample components on `x$boot`;
# d_study() reprojects each resample across `m` (moving only the divisor) and takes
# percentile bands -- reusing the SAME resamples that produced the fit's interval, so
# at `m = k_eff` the band coincides with the fitted ICC(*,k) bootstrap interval
# (the primary, exact coherence oracle). It is package-wide (two-way, multilevel,
# incomplete), keyed off `ci_method`, with no new argument. The band's own oracle is
# coverage/agreement (a CI method, #1): it agrees with the MC band on interior cases
# and diverges predictably at the boundary (the M16 O2 pattern, #18).

test_that("O-Boot-DS/coherence: at m = k_eff the bootstrap band equals the fit interval", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  fb <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    ci_method = "bootstrap",
    boot_samples = 499,
    seed = 1
  ))
  # Balanced SF data: k_eff = n_raters = 4, so the projection to m = 4 IS ICC(A,k).
  ds <- d_study(fb, m = fb$n$raters)
  fit_ak <- fb$estimates[fb$estimates$index == "ICC(A,k)", ]
  expect_equal(ds$conf.low, fit_ak$conf.low, tolerance = 1e-9)
  expect_equal(ds$conf.high, fit_ak$conf.high, tolerance = 1e-9)
  # The band is labelled bootstrap and carries the resample count.
  expect_identical(attr(ds, "method"), "bootstrap")
  expect_identical(attr(ds, "samples"), 499L)
})

test_that("O-Boot-DS: a Monte-Carlo fit still gets a Monte-Carlo band (no regression)", {
  skip_if_not_installed("glmmTMB")
  fm <- fit_ds("agreement")
  ds <- d_study(fm, m = c(1, 4, 8))
  expect_identical(attr(ds, "method"), "montecarlo")
})

test_that("O-Boot-DS: the bootstrap band is deterministic, monotone, and in [0, 1]", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  fb <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 499,
    seed = 1
  ))
  # No re-draw or seed: the band is fixed by the stored resamples, so repeat calls
  # are identical (unlike the MC band, which re-draws).
  a <- d_study(fb, m = 1:6)
  b <- d_study(fb, m = 1:6)
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)
  a <- a[order(a$m), ]
  expect_true(all(diff(a$estimate) > 0))
  expect_true(all(a$estimate >= 0 & a$estimate <= 1))
  expect_true(all(a$conf.low >= 0 & a$conf.high <= 1))
})

test_that("O-Boot-DS/O2: bootstrap band agrees with the MC band on an interior case", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  # Many subjects, well-separated components -> both methods are far from the
  # boundary and the bands nearly coincide (they diverge only at the boundary, #18).
  set.seed(99)
  ns <- 40L
  k <- 6L
  subj <- stats::rnorm(ns, 0, sqrt(4))
  rat <- stats::rnorm(k, 0, sqrt(0.6))
  d <- expand.grid(subject = seq_len(ns), rater = seq_len(k))
  d$score <- 10 +
    subj[d$subject] +
    rat[d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(1.2))
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  fb <- icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 999,
    seed = 1
  )
  fm <- icc(d, score, subject, rater, seed = 1)
  for (m in c(2, 4, 12)) {
    db <- d_study(fb, m = m)
    dm <- d_study(fm, m = m)
    expect_equal(db$conf.low, dm$conf.low, tolerance = 0.02)
    expect_equal(db$conf.high, dm$conf.high, tolerance = 0.02)
  }
})

test_that("O-Boot-DS: multilevel and incomplete-subject bootstrap bands project", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  d <- sim_ml_ds(20, 8, 5, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 7)
  # Multilevel bootstrap fit: a bootstrap band per projected level.
  fb <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    ci_method = "bootstrap",
    boot_samples = 199,
    seed = 1
  )
  ds <- d_study(fb, m = c(1, 5, 10))
  expect_identical(attr(ds, "method"), "bootstrap")
  expect_setequal(unique(ds$level), c("subject", "cluster"))
  # Slice 3 x Slice 4: an incomplete multilevel bootstrap fit projects the subject
  # level with a bootstrap band.
  di <- ragged_ds(d, 0.15, 7)
  fbi <- icc(
    di,
    score,
    subject,
    rater,
    cluster = cluster,
    ci_method = "bootstrap",
    boot_samples = 199,
    seed = 1
  )
  dsi <- suppressMessages(d_study(fbi, m = c(1, 5, 10)))
  expect_identical(attr(dsi, "method"), "bootstrap")
  expect_setequal(unique(dsi$level), "subject")
  expect_true(all(is.finite(dsi$conf.low) & is.finite(dsi$conf.high)))
})

test_that("d_study refuses within-cell replicate fits (M20; #1/#5)", {
  skip_if_not_installed("glmmTMB")
  # A replicate fit splits the residual into interaction + pure error; projecting
  # rater counts off it would silently drop the interaction from the error set, so
  # d_study() must refuse rather than miscompute (occasion/replicate projection is a
  # deferred facet, M17 §7).
  set.seed(1)
  ns <- 12
  nr <- 4
  no <- 2
  s <- stats::rnorm(ns, 0, sqrt(1.2))
  r <- stats::rnorm(nr, 0, sqrt(0.7))
  g <- expand.grid(
    subject = seq_len(ns),
    rater = seq_len(nr),
    occ = seq_len(no)
  )
  srv <- stats::rnorm(ns * nr, 0, sqrt(0.4))
  g$sr <- srv[(g$rater - 1) * ns + g$subject]
  g$score <- 10 +
    s[g$subject] +
    r[g$rater] +
    g$sr +
    stats::rnorm(nrow(g), 0, sqrt(0.5))
  g$subject <- factor(g$subject)
  g$rater <- factor(g$rater)
  x <- icc(g, score, subject, rater, seed = 1)
  expect_error(d_study(x, m = 1:3), class = "intraclass_unsupported")
})
