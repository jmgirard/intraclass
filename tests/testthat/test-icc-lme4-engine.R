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

test_that("lme4 is refused for multilevel designs (deferred, M14 Slices 2/3)", {
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

test_that("lme4 refuses incomplete data for fixed raters (deferred, M14)", {
  skip_if_not_installed("lme4")

  # Balanced fixed-rater lme4 is supported (below); the incomplete fixed-rater
  # theta^2_r-under-imbalance path stays with glmmTMB (ADR-023). A single dropped
  # cell makes the design unbalanced -> loud abort toward glmmTMB.
  d <- sf_ratings_long()
  d_incomplete <- d[-1, ]
  expect_error(
    suppressWarnings(icc(
      d_incomplete,
      score,
      subject,
      rater,
      raters = "fixed",
      engine = "lme4"
    )),
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
