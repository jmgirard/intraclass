# O3 — seeded simulation with known population variance components ------------
# Draw data from a known (sigma^2_s, sigma^2_r, sigma^2_res), fit, and confirm the
# estimator recovers the population ICCs and that the Monte-Carlo interval covers
# them. Seeded for reproducibility (PRINCIPLES.md #12); tolerances reflect genuine
# single-sample sampling error, not tuning to pass (PRINCIPLES.md #1, #4).

test_that("recovers known population ICCs from simulated data (O3)", {
  skip_if_not_installed("glmmTMB")

  set.seed(2024)
  n <- 100L # subjects
  k <- 8L # raters
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
  td <- tidy(fit)

  pop_a1 <- v_s / (v_s + v_r + v_res)
  pop_ak <- v_s / (v_s + (v_r + v_res) / k)

  a1 <- td[td$index == "ICC(A,1)", ]
  ak <- td[td$index == "ICC(A,k)", ]

  # Point estimates near the population values (generous, honest tolerance).
  expect_equal(a1$estimate, pop_a1, tolerance = 0.05)
  expect_equal(ak$estimate, pop_ak, tolerance = 0.05)

  # The Monte-Carlo interval covers the population value (the inferential claim).
  expect_lte(a1$conf.low, pop_a1)
  expect_gte(a1$conf.high, pop_a1)
  expect_lte(ak$conf.low, pop_ak)
  expect_gte(ak$conf.high, pop_ak)
})

test_that("a fixed seed makes the Monte-Carlo interval reproducible (#12)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  a <- tidy(icc(d, score, subject, rater, seed = 99))
  b <- tidy(icc(d, score, subject, rater, seed = 99))
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)

  # And it leaves the global RNG stream untouched (PRINCIPLES.md #9).
  set.seed(7)
  before <- .Random.seed
  icc(d, score, subject, rater, seed = 123)
  expect_identical(.Random.seed, before)
})
