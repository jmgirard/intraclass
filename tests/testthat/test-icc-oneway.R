# O-OW -- one-way random ICC(1) / ICC(k) (M6) ---------------------------------
# Shrout & Fleiss (1979) Case 1: `model = "oneway"` fits `score ~ 1 + (1|subject)`
# (no rater term), so the residual confounds the rater main effect with error.
# The estimand + all oracles were verified live before code (estimand-spec
# M6-oneway.md §7); the published SF values (0.166 / 0.443) are already staged in
# helper-shrout-fleiss.R::sf_oracle_all. Tolerances reflect genuine numerical
# agreement, not tuning to pass (PRINCIPLES.md #1).

test_that("one-way reproduces the published Shrout & Fleiss values (O-OW textbook)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  ow <- tidy(icc(d, score, subject, rater, model = "oneway", seed = 1))
  i1 <- ow$estimate[ow$index == "ICC(1)"]
  ik <- ow$estimate[ow$index == "ICC(k)"]
  # SF Table 4 prints 2 d.p. (.17 / .44); 0.166 / 0.443 are the psych/DescTools
  # reproductions and round to those (M72, D-008). Assert the ABSOLUTE gap so
  # the last-place rounding is not read as a relative-tolerance failure
  # (M5.5 lesson).
  expect_lt(abs(i1 - sf_oracle_all[["ICC(1)"]]), 1e-3)
  expect_lt(abs(ik - sf_oracle_all[["ICC(k)"]]), 1e-3)
})

test_that("one-way matches psych::ICC ICC1/ICC1k (O-OW independent package)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("psych")

  w <- sf_ratings_wide()
  p <- psych::ICC(w)$results
  psych_1 <- p$ICC[p$type == "ICC1"]
  psych_k <- p$ICC[p$type == "ICC1k"]

  ow <- tidy(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  ))
  expect_equal(ow$estimate[ow$index == "ICC(1)"], psych_1, tolerance = 1e-4)
  expect_equal(ow$estimate[ow$index == "ICC(k)"], psych_k, tolerance = 1e-4)
})

test_that("one-way matches package-independent ANOVA mean squares (O-OW)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  k <- nlevels(d$rater)
  a <- stats::anova(stats::aov(score ~ subject, data = d))
  msb <- a["subject", "Mean Sq"]
  msw <- a["Residuals", "Mean Sq"]
  anova_1 <- (msb - msw) / (msb + (k - 1) * msw)
  anova_k <- (msb - msw) / msb

  ow <- tidy(icc(d, score, subject, rater, model = "oneway", seed = 1))
  expect_equal(ow$estimate[ow$index == "ICC(1)"], anova_1, tolerance = 1e-4)
  expect_equal(ow$estimate[ow$index == "ICC(k)"], anova_k, tolerance = 1e-4)
})

test_that("one-way glmmTMB and lme4 engines agree (O-OW cross-engine)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  g <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    engine = "glmmTMB",
    seed = 1
  ))
  l <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    engine = "lme4",
    seed = 1
  ))
  expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
  # Intervals coincide (same log-SD scale via merDeriv); absolute gap (M5.5 lesson).
  expect_lt(max(abs(l$conf.low - g$conf.low)), 0.02)
  expect_lt(max(abs(l$conf.high - g$conf.high)), 0.02)
})

test_that("one-way recovers known population ICCs with covering intervals (O-OW sim)", {
  skip_if_not_installed("glmmTMB")

  # Draw from a known one-way model: subject signal + a single confounded within-
  # subject error (no separate rater effect). Recover ICC(1)/ICC(1,k).
  set.seed(2024)
  n <- 120L
  k <- 6L
  v_s <- 4
  v_res <- 6
  subj <- stats::rnorm(n, 0, sqrt(v_s))
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    stats::rnorm(n * k, 0, sqrt(v_res))

  td <- tidy(icc(grid, score, subject, rater, model = "oneway", seed = 1))
  pop_1 <- v_s / (v_s + v_res)
  pop_k <- v_s / (v_s + v_res / k)
  i1 <- td[td$index == "ICC(1)", ]
  ik <- td[td$index == "ICC(k)", ]

  expect_equal(i1$estimate, pop_1, tolerance = 0.05)
  expect_equal(ik$estimate, pop_k, tolerance = 0.05)
  expect_lte(i1$conf.low, pop_1)
  expect_gte(i1$conf.high, pop_1)
  expect_lte(ik$conf.low, pop_k)
  expect_gte(ik$conf.high, pop_k)
})

test_that("one-way ICC(1) is the conservative coefficient vs two-way on `ratings`", {
  skip_if_not_installed("glmmTMB")

  # The confounded residual makes ICC(1) <= ICC(A,1) <= ICC(C,1) when raters differ
  # systematically (SF: 0.166 <= 0.290 <= 0.715). A teaching invariant (M6 §9).
  ow <- tidy(icc(ratings, score, subject, rater, model = "oneway", seed = 1))
  a <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  cons <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))
  expect_lte(
    ow$estimate[ow$index == "ICC(1)"],
    a$estimate[a$index == "ICC(A,1)"]
  )
  expect_lte(
    a$estimate[a$index == "ICC(A,1)"],
    cons$estimate[cons$index == "ICC(C,1)"]
  )
})

test_that("one-way supports numeric unit (D-study projection)", {
  skip_if_not_installed("glmmTMB")

  # ICC(1,m) = sigma^2_s / (sigma^2_s + sigma^2_res / m), from resolve_divisor().
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  )
  vc <- glance(fit)
  m <- 6
  expected <- vc$var_subject / (vc$var_subject + vc$var_residual / m)

  proj <- tidy(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    unit = m,
    seed = 1
  ))
  expect_equal(proj$index, "ICC(6)")
  expect_equal(proj$estimate, expected, tolerance = 1e-6)
})

test_that("one-way glance reports subject/residual and NA rater", {
  skip_if_not_installed("glmmTMB")

  g <- glance(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  ))
  expect_false(is.na(g$var_subject))
  expect_false(is.na(g$var_residual))
  expect_true(is.na(g$var_rater))
})

test_that("one-way fails loudly on ill-posed requests (#5)", {
  skip_if_not_installed("glmmTMB")
  d <- sf_ratings_long()

  # Fixed raters do not apply to a one-way design.
  expect_error(
    icc(d, score, subject, rater, model = "oneway", raters = "fixed"),
    class = "intraclass_unsupported"
  )
  # A cluster (multilevel) structure does not apply.
  d$cl <- factor(rep(c("a", "b"), length.out = nrow(d)))
  expect_error(
    icc(d, score, subject, rater, cluster = cl, model = "oneway"),
    class = "intraclass_unsupported"
  )
  # One rating per subject cannot separate subject from residual variance.
  single <- d[d$rater == "J1", ]
  expect_error(
    icc(single, score, subject, rater, model = "oneway"),
    class = "intraclass_unidentified"
  )
})

test_that("one-way print() output is stable", {
  skip_if_not_installed("glmmTMB")

  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    model = "oneway",
    seed = 1
  )
  expect_snapshot(print(fit), transform = mask_ci)
})
