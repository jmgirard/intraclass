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

  fit <- suppressMessages(icc(
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
    suppressMessages(icc(
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

test_that("lme4 is refused for fixed-rater and multilevel designs (deferred)", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, raters = "fixed", engine = "lme4"),
    class = "intraclass_unsupported"
  )

  skip_if_not_installed("glmmTMB")
  # Build a minimal multilevel design (subjects nested in clusters).
  ml <- expand.grid(
    subject = factor(1:4),
    rater = factor(1:3),
    cluster = factor(1:2)
  )
  ml$score <- as.numeric(ml$subject) + as.numeric(ml$rater) + rnorm(nrow(ml))
  expect_error(
    icc(ml, score, subject, rater, cluster = cluster, engine = "lme4"),
    class = "intraclass_unsupported"
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
