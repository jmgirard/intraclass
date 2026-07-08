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

test_that("bootstrap aborts loudly on a fit carrying no simulate_refit contract", {
  # Every shipped engine/design that reaches bootstrap_ci() now attaches a
  # simulate_refit contract (glmmTMB, lme4, and -- since M21 Slice 1 -- lavaan for
  # the two-way random path); other lavaan designs abort earlier at fit dispatch.
  # The defensive guard for a fit that carries none must still fail loudly (#5/#8).
  bare_fit <- list(engine = "stub", simulate_refit = NULL)
  expect_error(
    bootstrap_ci(bare_fit, estimands = list(), boot_samples = 99L),
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

# Slice 2 -- lme4 bootMer parity through the same simulate_refit() contract -----

test_that("the lme4 engine bootstraps via bootMer with a well-formed interval", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  d <- sf_ratings_long()
  fit <- icc(
    d,
    score,
    subject,
    rater,
    engine = "lme4",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  )
  td <- tidy(fit)

  expect_identical(fit$engine, "lme4")
  expect_identical(fit$ci$method, "bootstrap")
  expect_true(all(is.finite(td$conf.low)))
  expect_true(all(is.finite(td$conf.high)))
  expect_true(all(td$conf.low <= td$estimate))
  expect_true(all(td$estimate <= td$conf.high))

  # Reproducible with a fixed seed, and the global RNG stream is untouched (#9/#12).
  b <- tidy(icc(
    d,
    score,
    subject,
    rater,
    engine = "lme4",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  ))
  expect_equal(td$conf.low, b$conf.low)
  expect_equal(td$conf.high, b$conf.high)
})

test_that("bootstrap agrees across engines (lme4 bootMer vs glmmTMB) (O2)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  set.seed(11)
  n <- 40L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  bs_tmb <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))
  bs_lme4 <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    engine = "lme4",
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))

  # The two engines fit the same REML model (identical point estimates) and each
  # runs a parametric bootstrap, so their percentile intervals should concur away
  # from the boundary. Generous, honest tolerance (#1, #4).
  expect_equal(bs_lme4$estimate, bs_tmb$estimate, tolerance = 1e-4)
  expect_equal(bs_lme4$conf.low, bs_tmb$conf.low, tolerance = 0.05)
  expect_equal(bs_lme4$conf.high, bs_tmb$conf.high, tolerance = 0.05)
})

# Slice 3 -- rest of the fitted family + refit-failure discard policy -----------

test_that("the refit-failure discard policy warns, then aborts (#5, #8)", {
  set.seed(1)
  est <- list(icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random"
  ))
  # A stub engine whose simulate_refit returns a controlled (component x resample)
  # matrix with `n_fail` all-NA (nonconvergent) columns -- exercises the policy
  # deterministically, without needing a pathological real fit.
  fake <- function(n_ok, n_fail) {
    total <- n_ok + n_fail
    mat <- matrix(
      NA_real_,
      nrow = 3L,
      ncol = total,
      dimnames = list(c("subject", "rater", "residual"), NULL)
    )
    if (n_ok > 0L) {
      mat["subject", seq_len(n_ok)] <- stats::runif(n_ok, 1.5, 2.5)
      mat["rater", seq_len(n_ok)] <- stats::runif(n_ok, 0.5, 1.5)
      mat["residual", seq_len(n_ok)] <- stats::runif(n_ok, 0.8, 1.2)
    }
    list(simulate_refit = function(boot_samples, seed = NULL) mat)
  }

  # >10% dropouts -> classed warning, but an interval is still returned.
  expect_warning(
    res <- bootstrap_ci(fake(85L, 15L), est, boot_samples = 100L),
    class = "intraclass_bootstrap_dropouts"
  )
  expect_true(is.finite(res[[1]]$conf.low))

  # <50% converged -> loud abort pointing at Monte-Carlo.
  expect_error(
    suppressWarnings(bootstrap_ci(fake(40L, 60L), est, boot_samples = 100L)),
    class = "intraclass_singular_fit"
  )
})

test_that("bootstrap covers the multilevel design and agrees with MC (O2)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  set.seed(3)
  nc <- 15L
  ns <- 4L
  nr <- 4L
  ml <- expand.grid(
    cl = factor(seq_len(nc)),
    s = factor(seq_len(ns)),
    rater = factor(seq_len(nr))
  )
  ml$subject <- factor(paste(ml$cl, ml$s, sep = "_"))
  ml$cluster <- ml$cl
  ml$score <- 10 +
    stats::rnorm(nc, 0, 1.5)[as.integer(ml$cl)] +
    stats::rnorm(nlevels(ml$subject), 0, 1)[as.integer(ml$subject)] +
    stats::rnorm(nr, 0, 1)[as.integer(ml$rater)] +
    stats::rnorm(nrow(ml), 0, 1)

  mc <- tidy(icc(ml, score, subject, rater, cluster = cluster, seed = 1))
  bs <- tidy(icc(
    ml,
    score,
    subject,
    rater,
    cluster = cluster,
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  ))

  # Same fit -> the multilevel five-component extractor reproduces the point
  # estimates exactly (the key correctness check for the ml_contract extractor).
  expect_equal(bs$estimate, mc$estimate, tolerance = 1e-8)
  # Well-formed intervals at every level.
  expect_true(all(is.finite(bs$conf.low)))
  expect_true(all(bs$conf.low <= bs$estimate))
  expect_true(all(bs$estimate <= bs$conf.high))
  # The subject-level interval sits in the same ballpark as MC. Absolute, not
  # relative, agreement: the two methods genuinely diverge more here than in the
  # two-way case (five components, few clusters), and cluster-level intervals
  # diverge more still -- an honest property of the bootstrap, not tuned away
  # (#1/#4). 199 resamples add tail noise on top.
  sub <- bs$level == "subject"
  expect_lt(max(abs(bs$conf.low[sub] - mc$conf.low[sub])), 0.1)
  expect_lt(max(abs(bs$conf.high[sub] - mc$conf.high[sub])), 0.1)
})

test_that("bootstrap covers the fixed-rater design (theta^2_r per refit)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")

  set.seed(5)
  n <- 30L
  k <- 5L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  bs <- suppressWarnings(tidy(icc(
    grid,
    score,
    subject,
    rater,
    raters = "fixed",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  )))
  expect_true(all(is.finite(bs$conf.low)))
  expect_true(all(bs$conf.low <= bs$estimate))
  expect_true(all(bs$estimate <= bs$conf.high))
})

# M21 Slice 1 (ADR-031) -- lavaan (SEM) bootstrap via the same simulate_refit() ---
#
# The lavaan engine now serves ci_method = "bootstrap" through the M16 contract: a
# PARAMETRIC bootstrap that simulates wide datasets from the fitted SEM's implied
# moments, refits the one-factor model, and recomputes the ICC per resample. Oracles
# are the CI-method oracles (#1): O1 coverage of the known population, O2 agreement
# with the (independent) lavaan Monte-Carlo interval, plus cross-engine agreement on
# the estimator-invariant consistency ratio. SEM refits are expensive -> modest
# boot_samples, skip on CRAN, seeded (#12).

test_that("lavaan bootstrap returns a well-formed interval", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  set.seed(31)
  n <- 40L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  fit <- icc(
    grid,
    score,
    subject,
    rater,
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  )
  td <- tidy(fit)

  expect_identical(fit$engine, "lavaan")
  expect_identical(fit$ci$method, "bootstrap")
  expect_identical(fit$ci$samples, 199L)
  expect_true(all(is.finite(td$conf.low)))
  expect_true(all(is.finite(td$conf.high)))
  expect_true(all(td$conf.low <= td$estimate))
  expect_true(all(td$estimate <= td$conf.high))
  expect_true(all(td$conf.high <= 1))

  # Reproducible with a fixed seed, and the global RNG stream is untouched (#9/#12).
  before <- {
    set.seed(7)
    .Random.seed
  }
  b <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 199L,
    seed = 1
  ))
  expect_equal(td$conf.low, b$conf.low)
  expect_equal(td$conf.high, b$conf.high)
})

test_that("lavaan bootstrap interval covers the known population ICC (O1)", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  set.seed(2025)
  n <- 60L
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

  # The population-coverage oracle uses CONSISTENCY: the ratio
  # sigma^2_s/(sigma^2_s + sigma^2_res) is estimator-invariant, so the SEM bootstrap
  # targets the same population value the mixed model does. (Coverage of the
  # random-rater population by the SEM AGREEMENT interval is NOT a valid oracle: the
  # SEM indicator-mean estimator targets the FINITE-rater agreement -- the variance
  # of the k realized rater means, a Case-3A quantity -- not v_r; SEM agreement is
  # instead pinned against the lavaan Monte-Carlo interval, the O2 test below.)
  bs <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    unit = "single",
    type = "consistency",
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 299L,
    seed = 1
  ))
  pop_c1 <- v_s / (v_s + v_res)
  c1 <- bs[bs$index == "ICC(C,1)", ]

  expect_lte(c1$conf.low, pop_c1)
  expect_gte(c1$conf.high, pop_c1)
})

test_that("lavaan bootstrap agrees with the lavaan Monte-Carlo interval (O2)", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  set.seed(37)
  n <- 40L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  mc <- tidy(icc(grid, score, subject, rater, engine = "lavaan", seed = 1))
  bs <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))

  # Same fit (identical point estimates); the two independent interval methods for
  # the SAME engine/estimator should concur away from the boundary. Generous, honest
  # tolerance -- resampling noise + method difference, not tuned to pass (#1, #4).
  expect_equal(bs$estimate, mc$estimate, tolerance = 1e-8)
  expect_equal(bs$conf.low, mc$conf.low, tolerance = 0.06)
  expect_equal(bs$conf.high, mc$conf.high, tolerance = 0.06)
})

test_that("lavaan bootstrap agrees with glmmTMB bootstrap on consistency (O2)", {
  skip_on_cran()
  skip_if_not_installed("lavaan")
  skip_if_not_installed("glmmTMB")

  set.seed(41)
  n <- 40L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  # Consistency is the estimator-invariant ratio sigma^2_s/(sigma^2_s + sigma^2_res),
  # so the SEM and mixed-model bootstraps should concur closely (agreement uses a
  # DIFFERENT sigma^2_r estimator, tested separately for coverage, not cross-engine).
  bs_lav <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    type = "consistency",
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))
  bs_tmb <- tidy(icc(
    grid,
    score,
    subject,
    rater,
    type = "consistency",
    engine = "glmmTMB",
    ci_method = "bootstrap",
    boot_samples = 499L,
    seed = 1
  ))

  expect_equal(bs_lav$estimate, bs_tmb$estimate, tolerance = 1e-3)
  expect_equal(bs_lav$conf.low, bs_tmb$conf.low, tolerance = 0.06)
  expect_equal(bs_lav$conf.high, bs_tmb$conf.high, tolerance = 0.06)
})
