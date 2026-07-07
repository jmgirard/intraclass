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
