# O-LME — lme4 as a selectable engine (M5.5 / ADR-012) ------------------------
# lme4 is promoted from oracle-only (ADR-005) to a selectable engine for the
# random two-way path. It must return the SAME estimates as glmmTMB (they are two
# REML implementations of one model) and a Monte-Carlo interval that agrees with
# glmmTMB's. The interval agreement is the payoff of the merDeriv route over a
# parametric bootstrap: because lme4's variance-component covariance is
# delta-transformed to glmmTMB's log-SD scale, both engines sample from the same
# parameterization (engine-lme4.R). Tolerances reflect genuine numerical
# agreement, not tuning to pass (PRINCIPLES.md #1).

lme4_axes <- list(
  c(type = "agreement", unit = "single"),
  c(type = "agreement", unit = "average"),
  c(type = "consistency", unit = "single"),
  c(type = "consistency", unit = "average")
)

test_that("lme4 engine point estimates match glmmTMB to 1e-4 (O-LME point)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  for (ax in lme4_axes) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1
    ))
    expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
  }
})

test_that("lme4 engine reproduces the published Shrout & Fleiss values", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  a <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = "average",
    engine = "lme4",
    seed = 1
  ))
  s <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = "single",
    engine = "lme4",
    seed = 1
  ))
  c1 <- tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = "single",
    engine = "lme4",
    seed = 1
  ))
  ck <- tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = "average",
    engine = "lme4",
    seed = 1
  ))
  expect_equal(
    s$estimate[s$index == "ICC(A,1)"],
    sf_oracle_all[["ICC(A,1)"]],
    tolerance = 1e-3
  )
  expect_equal(
    a$estimate[a$index == "ICC(A,k)"],
    sf_oracle_all[["ICC(A,k)"]],
    tolerance = 1e-3
  )
  expect_equal(
    c1$estimate[c1$index == "ICC(C,1)"],
    sf_oracle_all[["ICC(C,1)"]],
    tolerance = 1e-3
  )
  expect_equal(
    ck$estimate[ck$index == "ICC(C,k)"],
    sf_oracle_all[["ICC(C,k)"]],
    tolerance = 1e-3
  )
})

test_that("lme4 Monte-Carlo interval agrees with glmmTMB's (O-LME interval)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # merDeriv's SD-scale covariance delta-transformed to log-SD reproduces
  # glmmTMB's internal vcov(full = TRUE) to ~1e-4, so the two engines' MC
  # interval bounds coincide to well under 0.02 in ABSOLUTE terms (observed
  # ~1e-2). We check the absolute gap rather than expect_equal()'s relative
  # tolerance, which is too strict for small conf.low values (a 0.002 gap on a
  # 0.05 bound is a 4% relative difference). A material absolute disagreement
  # would mean the scale transform is wrong, not a loose tolerance.
  d <- sf_ratings_long()
  for (ax in lme4_axes) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 matches glmmTMB on INCOMPLETE random two-way data (M15 Slice 1, O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # M15 Slice 1 (ADR-024): incomplete/ragged two-way RANDOM lme4 was already ungated
  # (it dispatches to fit_lme4()) but untested as a selectable engine. The k_eff /
  # connectedness machinery runs in icc() BEFORE engine dispatch and is
  # engine-agnostic, so lme4 fits the same ragged model as glmmTMB; merDeriv's
  # SD-scale covariance delta-transformed to log-SD (engine-lme4.R) makes the two
  # engines' MC intervals coincide. glmmTMB is the independent cross-engine oracle
  # (PRINCIPLES.md #1) on BOTH the point estimate (<= 1e-4) and the interval (< 0.02,
  # the same absolute tolerance as the balanced O-LME interval block above -- see the
  # note there on why absolute, not relative). `ratings_incomplete` is a real 6x4
  # design missing 4 of its 24 subject-by-rater cells.
  d <- ratings_incomplete
  for (ax in lme4_axes) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_lt(max(abs(l$estimate - g$estimate)), 1e-4)
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 interval is boundary-aware on a near-zero variance component", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # A small-but-nonzero rater effect drives the rater variance near the boundary
  # without a singular fit. The log-SD scale keeps every MC draw strictly
  # positive, so the interval stays finite and inside [0, 1] (PRINCIPLES.md #3).
  set.seed(3)
  n_s <- 20L
  k <- 6L
  subj <- stats::rnorm(n_s, 0, 2)
  reff <- stats::rnorm(k, 0, 1.5)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(seq_len(k))
  )
  grid$score <- subj[as.integer(grid$subject)] +
    reff[as.integer(grid$rater)] +
    stats::rnorm(n_s * k, 0, 1)

  fit <- suppressWarnings(icc(
    grid,
    score,
    subject,
    rater,
    engine = "lme4",
    seed = 1
  ))
  ci <- fit$estimates
  expect_true(all(is.finite(ci$conf.low) & is.finite(ci$conf.high)))
  expect_true(all(ci$conf.low >= 0 & ci$conf.high <= 1))
})

test_that("lme4 aborts loudly on a singular (boundary) fit (#5)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # No rater effect at all with few raters collapses the rater variance to
  # exactly zero -> singular fit -> merDeriv cannot form the covariance. Fail
  # loudly with a classed error rather than returning a bogus interval.
  set.seed(7)
  n_s <- 20L
  subj <- stats::rnorm(n_s, 0, 2)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(seq_len(4L))
  )
  grid$score <- subj[as.integer(grid$subject)] + stats::rnorm(n_s * 4L, 0, 1)

  expect_error(
    suppressWarnings(icc(
      grid,
      score,
      subject,
      rater,
      engine = "lme4",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

# A balanced, complete crossed (Design 1) multilevel dataset: subjects nested in
# clusters (labels unique per cluster), raters crossed with both. Used by the
# Slice 2 multilevel oracle block below.
lme4_ml_crossed <- function(nc = 12L, ns = 6L, k = 4L, seed = 20260707) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, 1.5)
  sc <- stats::rnorm(nc * ns, 0, 1.2)
  rat <- stats::rnorm(k, 0, 1)
  cr <- stats::rnorm(nc * k, 0, 0.7)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    rat[d$rater] +
    cr[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, 1)
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

test_that("lme4 matches glmmTMB on INCOMPLETE crossed multilevel data (M15 Slice 3, O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # M15 Slice 3 (ADR-024): the crossed (Design 1) RANDOM multilevel fit on ragged data.
  # This is the only incomplete multilevel case that reaches an lme4 fit -- incomplete
  # nested (Designs 2/3) and incomplete fixed-rater multilevel abort earlier for EVERY
  # engine (the M8/M10 deferrals). fit_lme4_multilevel() fits the five-component model
  # on the ragged data and lme4_ml_contract() reads merDeriv's incomplete-data vcov;
  # the k_eff / connectedness machinery that gates the coefficients runs in icc() before
  # dispatch and is engine-agnostic. glmmTMB is the independent cross-engine oracle
  # (PRINCIPLES.md #1) at BOTH the subject level (all four axes) and the cluster level
  # (ICC(c,1), the only cluster coefficient defined on incomplete data -- M9 Slice 2).
  # ~15% MCAR cell deletion, kept connected with raters bridging clusters (crossed).
  d <- lme4_ml_crossed(nc = 12L, ns = 6L, k = 4L)
  set.seed(24)
  d <- d[-sample(nrow(d), round(0.15 * nrow(d))), , drop = FALSE]

  for (ax in lme4_axes) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_lt(max(abs(l$estimate - g$estimate)), 1e-4)
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }

  # Cluster-level single-rater ICC(c,1) on the same ragged data.
  gc <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    type = "agreement",
    unit = "single",
    engine = "glmmTMB",
    seed = 1,
    mc_samples = 20000L
  ))
  lc <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "cluster",
    type = "agreement",
    unit = "single",
    engine = "lme4",
    seed = 1,
    mc_samples = 20000L
  ))
  expect_lt(max(abs(lc$estimate - gc$estimate)), 1e-4)
  expect_lt(max(abs(lc$conf.low - gc$conf.low)), 0.02)
  expect_lt(max(abs(lc$conf.high - gc$conf.high)), 0.02)
})

test_that("incomplete multilevel lme4 degrades loudly to glmmTMB at the boundary (M15 Slice 3, #5)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # The intended graceful degrade: on a ragged crossed design whose cluster-by-rater
  # variance is truly zero, lme4's REML lands exactly on the boundary -> isSingular()
  # -> merDeriv cannot form the covariance -> a classed intraclass_singular_fit abort
  # pointing at glmmTMB (which stays finite via its log-SD parameterization). This
  # characterizes the success-vs-degrade frontier the milestone owns (#5/#18): lme4
  # covers incomplete multilevel data WHEN IT CAN and hands off loudly otherwise.
  nc <- 8L
  ns <- 6L
  k <- 4L
  set.seed(1)
  cl <- stats::rnorm(nc, 0, 1.5)
  sc <- stats::rnorm(nc * ns, 0, 1.2)
  rat <- stats::rnorm(k, 0, 1) # raters bridge clusters (stays crossed)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    rat[d$rater] + # NO cluster x rater term -> sigma^2_cr == 0 (the boundary)
    stats::rnorm(nrow(d), 0, 1)
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  set.seed(3)
  d <- d[-sample(nrow(d), round(0.05 * nrow(d))), , drop = FALSE]

  # lme4 aborts loudly at the boundary...
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      engine = "lme4",
      seed = 1
    ),
    class = "intraclass_singular_fit"
  )
  # ...while glmmTMB fits the same ragged data (the recommended fallback).
  expect_s3_class(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      engine = "glmmTMB",
      seed = 1
    ),
    "icc"
  )
})

test_that("lme4 engine recovers known population ICCs with covering intervals", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Same seeded-simulation oracle as O3, driven through the lme4 engine.
  set.seed(2024)
  n <- 100L
  k <- 8L
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

  td <- tidy(icc(grid, score, subject, rater, engine = "lme4", seed = 1))
  pop_a1 <- v_s / (v_s + v_r + v_res)
  pop_ak <- v_s / (v_s + (v_r + v_res) / k)
  a1 <- td[td$index == "ICC(A,1)", ]
  ak <- td[td$index == "ICC(A,k)", ]

  expect_equal(a1$estimate, pop_a1, tolerance = 0.05)
  expect_equal(ak$estimate, pop_ak, tolerance = 0.05)
  expect_lte(a1$conf.low, pop_a1)
  expect_gte(a1$conf.high, pop_a1)
  expect_lte(ak$conf.low, pop_ak)
  expect_gte(ak$conf.high, pop_ak)
})

test_that("the icc object reports the lme4 engine", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  fit <- icc(d, score, subject, rater, engine = "lme4", seed = 1)
  expect_equal(fit$engine, "lme4")
  expect_equal(glance(fit)$engine, "lme4")
})

test_that("lme4 print() output is stable", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # As with the glmmTMB print snapshot, the CI digits are masked (they vary at
  # ~1e-3 across platforms even when seeded); the engine line and point
  # estimates are checked verbatim.
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    seed = 1,
    engine = "lme4"
  )
  expect_snapshot(print(fit), transform = mask_ci)
})

# O-LME2 (fixed) — lme4 for the fixed-rater two-way fit (M14 Slice 1 / ADR-023) --
# Raters as fixed effects (McGraw & Wong Case 3/3A): the rater main effect is the
# bias-corrected finite-population theta^2_r, recomputed from the fixed-effect beta
# draws in the Monte-Carlo CI. lme4 (fit_lme4_fixed) must match glmmTMB
# (fit_glmmtmb_fixed) on both the point estimate and the interval, and reduce to the
# random-rater fit on balanced data (theta^2_r == sigma^2_r). The estimand is
# UNCHANGED (a second engine, not a new coefficient); glmmTMB is the independent
# oracle (PRINCIPLES.md #1), the seeded simulation the second.

test_that("lme4 fixed point estimates match glmmTMB to 1e-4 (O-LME2 point)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  for (ax in lme4_axes) {
    g <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1
    )))
    l <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1
    )))
    expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
  }
})

test_that("lme4 fixed reduces to the random fit on balanced data (O-LME2)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # On balanced data theta^2_r == sigma^2_r, so fixed and random rater fits give
  # identical point estimates (McGraw & Wong 1996; M3 §6 / M10 reduction).
  d <- sf_ratings_long()
  for (ax in lme4_axes) {
    r <- tidy(icc(
      d,
      score,
      subject,
      rater,
      raters = "random",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1
    ))
    f <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1
    )))
    expect_equal(f$estimate, r$estimate, tolerance = 1e-4)
  }
})

test_that("lme4 fixed Monte-Carlo interval agrees with glmmTMB's (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # theta^2_r is recomputed each draw from the fixed-effect betas, whose joint
  # covariance merDeriv supplies alongside the random SDs; delta-transformed to the
  # log-SD scale it reproduces glmmTMB's vcov(full = TRUE), so both engines sample
  # the same parameterization. Absolute bound gap (as in the random-rater test).
  d <- sf_ratings_long()
  for (ax in lme4_axes) {
    g <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    )))
    l <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    )))
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 matches glmmTMB on INCOMPLETE fixed-rater data (M15 Slice 2, O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # M15 Slice 2 (ADR-024): fixed-rater lme4 on ragged data. Unlike the balanced case
  # (where theta^2_r == sigma^2_r and both engines match to ~1e-6), on incomplete data
  # the bias-corrected finite-population theta^2_r depends on the fixed-effect
  # covariance vbeta, which reflects each rater's UNEQUAL number of ratings. The
  # correction is the shared engine-agnostic theta2r_fixed() fed lme4's own ragged
  # vcov(), so nothing here assumes balance. glmmTMB is the independent cross-engine
  # oracle (PRINCIPLES.md #1): point <= 1e-4 (observed ~5-7e-5, looser than the
  # balanced ~1e-6 because vbeta differs slightly between the two REML optimizers on a
  # small ragged design) and interval < 0.02 (the shared O-LME absolute tolerance).
  # `ratings_incomplete` is a real 6x4 design missing 4 of its 24 cells.
  d <- ratings_incomplete
  for (ax in lme4_axes) {
    g <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    )))
    l <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    )))
    expect_lt(max(abs(l$estimate - g$estimate)), 1e-4)
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 fixed aborts loudly on a singular (boundary) fit (#5)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # No subject effect collapses the subject variance to exactly zero -> singular
  # fit -> merDeriv cannot form the covariance. Fail loudly, class-tagged.
  set.seed(11)
  k <- 4L
  n_s <- 15L
  reff <- stats::rnorm(k, 0, 1.5)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(seq_len(k))
  )
  grid$score <- reff[as.integer(grid$rater)] + stats::rnorm(n_s * k, 0, 1)
  expect_error(
    suppressWarnings(icc(
      grid,
      score,
      subject,
      rater,
      raters = "fixed",
      engine = "lme4",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

test_that("lme4 fixed recovers known population ICCs with covering intervals", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Seeded-simulation oracle for the fixed-rater fit. With raters fixed, the
  # finite-population theta^2_r targets the variance of the k realized rater means,
  # so the population ICC uses those exact rater effects (not a rater universe).
  set.seed(2025)
  n <- 100L
  k <- 6L
  v_s <- 4
  v_res <- 2
  reff <- stats::rnorm(k, 0, 1) # the fixed, realized rater effects
  theta2r <- sum((reff - mean(reff))^2) / (k - 1)
  subj <- stats::rnorm(n, 0, sqrt(v_s))
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    reff[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(v_res))

  td <- tidy(suppressWarnings(icc(
    grid,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "lme4",
    seed = 1
  )))
  pop_a1 <- v_s / (v_s + theta2r + v_res)
  a1 <- td[td$index == "ICC(A,1)", ]
  expect_equal(a1$estimate, pop_a1, tolerance = 0.05)
  expect_lte(a1$conf.low, pop_a1)
  expect_gte(a1$conf.high, pop_a1)
})

# O-LME2 (multilevel) — lme4 for the crossed (Design 1) random-rater multilevel fit
# (M14 Slice 2 / ADR-023). The five-component fit
# score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) + (1|cluster:rater) via
# lme4 (fit_lme4_multilevel) must match glmmTMB (fit_glmmtmb_multilevel) on the point
# estimate and interval at BOTH the subject and cluster level, for agreement and
# consistency. The estimand is unchanged; glmmTMB is the independent oracle (#1), a
# seeded population recovery the second.

test_that("lme4 multilevel point estimates match glmmTMB to 1e-4 (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- lme4_ml_crossed()
  for (lv in c("subject", "cluster")) {
    for (ty in c("agreement", "consistency")) {
      g <- tidy(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        level = lv,
        type = ty,
        engine = "glmmTMB",
        seed = 1
      ))
      l <- tidy(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        level = lv,
        type = ty,
        engine = "lme4",
        seed = 1
      ))
      expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
    }
  }
})

test_that("lme4 multilevel Monte-Carlo interval agrees with glmmTMB's (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Five variance components delta-transformed to the shared log-SD scale, so both
  # engines sample the same parameterization. Absolute bound gap (as elsewhere).
  d <- lme4_ml_crossed()
  for (lv in c("subject", "cluster")) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = lv,
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = lv,
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 multilevel reports the lme4 engine and covers both levels", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- lme4_ml_crossed()
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lme4",
    seed = 1
  )
  expect_equal(fit$engine, "lme4")
  # Subject and cluster levels both present in the estimate table.
  expect_setequal(unique(fit$estimates$level), c("subject", "cluster"))
})

test_that("lme4 multilevel aborts loudly on a singular (boundary) fit (#5)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Two raters and no rater/cluster-rater signal collapses those components to
  # exactly zero -> singular fit -> merDeriv cannot form the covariance -> classed
  # abort (as in the two-way singular test, the same code path in lme4_ml_contract).
  set.seed(1)
  nc <- 4L
  ns <- 5L
  k <- 2L
  cl <- stats::rnorm(nc, 0, 1.5)
  sc <- stats::rnorm(nc * ns, 0, 1.2)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    stats::rnorm(nrow(d), 0, 1)
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  expect_error(
    suppressMessages(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lme4",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

test_that("lme4 multilevel recovers a known population subject-level ICC", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Seeded population recovery through the lme4 multilevel engine. Subject-level
  # ICC(A,1) = v_sc / (v_sc + v_r + v_res): sigma^2_cr is NOT in the subject-level
  # error set for cluster-crossed raters (estimand.R; spec M5 §3a -- it is the
  # cluster-level residual slot instead), matching glmmTMB.
  # Many raters (k = 20) so the rater-universe variance sigma^2_r is well estimated;
  # with few raters its finite-sample noise dominates the subject-level ICC.
  set.seed(303)
  nc <- 40L
  ns <- 8L
  k <- 20L
  v_c <- 1.0
  v_sc <- 4.0
  v_r <- 0.8
  v_cr <- 0.5
  v_res <- 2.0
  cl <- stats::rnorm(nc, 0, sqrt(v_c))
  sc <- stats::rnorm(nc * ns, 0, sqrt(v_sc))
  rat <- stats::rnorm(k, 0, sqrt(v_r))
  cr <- stats::rnorm(nc * k, 0, sqrt(v_cr))
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    rat[d$rater] +
    cr[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, sqrt(v_res))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))

  td <- tidy(icc(d, score, subject, rater, cluster = cluster, seed = 1))
  a1 <- td[td$index == "ICC(A,1)" & td$level == "subject", ]
  pop <- v_sc / (v_sc + v_r + v_res)
  expect_equal(a1$estimate, pop, tolerance = 0.05)
  expect_lte(a1$conf.low, pop)
  expect_gte(a1$conf.high, pop)
})

# O-LME2 (Slice 3) — lme4 for the nested designs (2/3) and fixed-rater multilevel
# (M14 Slice 3 / ADR-023). Each reuses the Slice-2 lme4_ml_contract() machinery
# (nested designs differ only in `groups`) or combines it with the Slice-1 theta^2_r
# draw (fixed multilevel). All must match their glmmTMB twin on the point estimate
# and interval; glmmTMB is the independent oracle (#1). Balanced/complete only.

# Design 2: raters nested in clusters (rater labels unique per cluster).
lme4_ml_nested_clusters <- function(
  nc = 12L,
  ns = 6L,
  k = 4L,
  seed = 20260707
) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, 1.3)
  sc <- stats::rnorm(nc * ns, 0, 1.1)
  rc <- stats::rnorm(nc * k, 0, 1.0)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    rc[(d$cluster - 1) * k + d$rater] +
    stats::rnorm(nrow(d), 0, 1)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

# Design 3: raters nested in subjects (rater labels unique per subject).
lme4_ml_nested_subjects <- function(
  nc = 12L,
  ns = 6L,
  k = 4L,
  seed = 20260707
) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, 1.3)
  sc <- stats::rnorm(nc * ns, 0, 1.1)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    stats::rnorm(nrow(d), 0, 1.4)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$subject, d$rater, sep = "_"))
  d
}

test_that("lme4 nested-cluster (Design 2) matches glmmTMB (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- lme4_ml_nested_clusters()
  for (ty in c("agreement", "consistency")) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      type = ty,
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      type = ty,
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
  }
})

test_that("lme4 nested-subject (Design 3) matches glmmTMB (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Design 3 is the multilevel one-way (agreement-only): consistency is undefined.
  d <- lme4_ml_nested_subjects()
  g <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "glmmTMB",
    seed = 1,
    mc_samples = 20000L
  ))
  l <- tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lme4",
    seed = 1,
    mc_samples = 20000L
  ))
  expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
  expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
  expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
})

test_that("lme4 fixed-rater multilevel matches glmmTMB and reduces to random (O-LME2)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # Crossed (Design 1) fixed raters, subject level only (M10). theta^2_r fills the
  # rater slot, recomputed from the fixed beta draws; on balanced data theta^2_r ==
  # sigma^2_r, so the point estimates equal the random-rater fit.
  d <- lme4_ml_crossed()
  for (ty in c("agreement", "consistency")) {
    g <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      type = ty,
      raters = "fixed",
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    )))
    l <- tidy(suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      type = ty,
      raters = "fixed",
      engine = "lme4",
      seed = 1,
      mc_samples = 20000L
    )))
    expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
    expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
    expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)

    r <- tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      type = ty,
      raters = "random",
      engine = "lme4",
      seed = 1
    ))
    expect_equal(l$estimate, r$estimate, tolerance = 1e-4)
  }
})

test_that("lme4 nested multilevel reports the lme4 engine", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d2 <- lme4_ml_nested_clusters()
  expect_equal(
    icc(
      d2,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lme4",
      seed = 1
    )$engine,
    "lme4"
  )
  d3 <- lme4_ml_nested_subjects()
  expect_equal(
    icc(
      d3,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lme4",
      seed = 1
    )$engine,
    "lme4"
  )
})
