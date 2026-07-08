# Parametric-bootstrap ci_method (ADR-025, M16 Slice 1) ------------------------
#
# Oracles for a CI *method* are about coverage and cross-method agreement, not a
# point value (PRINCIPLES.md #1):
#   O1  a seeded simulation whose bootstrap interval covers the KNOWN population ICC
#   O2  agreement with the independent Monte-Carlo interval on well-conditioned data
# Bootstrap refits are expensive (a full glmmTMB fit per resample), so these use
# modest `boot_samples` and skip on CRAN. Seeded throughout (#12).

test_that("bootstrap returns a well-formed interval around the estimate", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  fit <- icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  )
  td <- tidy(fit)

  expect_identical(fit$ci$method, "bootstrap")
  expect_identical(fit$ci$samples, 199L)
  # Every reported interval brackets its point estimate and is finite (#3).
  expect_true(all(is.finite(td$conf.low)))
  expect_true(all(is.finite(td$conf.high)))
  expect_true(all(td$conf.low <= td$estimate))
  expect_true(all(td$estimate <= td$conf.high))
  # ICCs stay in [-, 1]; the upper bound cannot exceed 1.
  expect_true(all(td$conf.high <= 1))
})

test_that("bootstrap interval covers a known population ICC (O1)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  set.seed(2024)
  n <- 40L # subjects
  k <- 6L # raters
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

  fit <- icc(
    grid,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 299L,
    seed = 1
  )
  td <- tidy(fit)

  pop_a1 <- v_s / (v_s + v_r + v_res)
  pop_ak <- v_s / (v_s + (v_r + v_res) / k)
  a1 <- td[td$index == "ICC(A,1)", ]
  ak <- td[td$index == "ICC(A,k)", ]

  expect_lte(a1$conf.low, pop_a1)
  expect_gte(a1$conf.high, pop_a1)
  expect_lte(ak$conf.low, pop_ak)
  expect_gte(ak$conf.high, pop_ak)
})

test_that("bootstrap agrees with the Monte-Carlo interval on interior data (O2)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  set.seed(7)
  n <- 40L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  mc <- tidy(icc(grid, score, subject, rater, seed = 1))
  bs <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))

  # Point estimates are identical (same fit); the two interval methods should
  # concur closely away from the boundary. Independent methods + resampling noise
  # -> a generous, honest tolerance, not tuned to pass (#1, #4).
  expect_equal(bs$estimate, mc$estimate, tolerance = 1e-8)
  expect_equal(bs$conf.low, mc$conf.low, tolerance = 0.06)
  expect_equal(bs$conf.high, mc$conf.high, tolerance = 0.06)
})

test_that("a fixed seed makes the bootstrap interval reproducible (#12)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  a <- tidy(icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 99L,
    seed = 99
  ))
  b <- tidy(icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 99L,
    seed = 99
  ))
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)

  # And it leaves the global RNG stream untouched (PRINCIPLES.md #9).
  set.seed(7)
  before <- .Random.seed
  icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 99L,
    seed = 123
  )
  expect_identical(.Random.seed, before)
})

test_that("bootstrap aborts loudly on a design it does not yet cover", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  # The one-way engine fit carries no simulate_refit contract yet (Slice 1 covers
  # the two-way random glmmTMB fit only); ask for it and fail loudly (#5).
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "bootstrap",
      boot_samples = 99L,
      seed = 1
    ),
    class = "intraclass_unsupported"
  )
})

test_that("boot_samples is validated like a resample count (#5, #8)", {
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, ci_method = "bootstrap", boot_samples = 1),
    class = "intraclass_error"
  )
  expect_error(
    icc(d, score, subject, rater, ci_method = "bootstrap", boot_samples = 10.5),
    class = "intraclass_error"
  )
})
