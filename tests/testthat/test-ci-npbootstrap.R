# Non-parametric transformed bootstrap-t ci_method (M75, ukoumunne2003) --------
#
# `ci_method = "npbootstrap"` is the exported balanced one-way transformed
# bootstrap-t (D-006 GO, exported-API scope D-010/RR02). Oracles for a CI *method*
# are coverage and cross-method agreement, not a point value (#1):
#   AC2  parity — the exported reducer reproduces the RR01-verified prototype's
#        transformed bootstrap-t endpoints to >= 4 dp (committed fixture).
#   BC2  identity — the ICC(k) interval is the exact Spearman-Brown image of the
#        ICC(1) interval, i.e. equals 1 - exp(-logF endpoint) (k_eff = n guard).
# Seeded throughout (#12); the heavy n_rep >= 2000 coverage sweep lives in
# data-raw and is asserted from its committed fixture in test-ci-npbootstrap-coverage.R.

# An unbalanced one-way dataset (subject 1 rated 3x, the rest 4x).
unbalanced_oneway <- function() {
  d <- expand.grid(
    subject = factor(seq_len(8)),
    rater = factor(seq_len(4))
  )
  d$score <- 10 + as.integer(d$subject) + stats::rnorm(nrow(d))
  d[!(d$subject == "1" & d$rater == "4"), ]
}

test_that("npbootstrap returns a well-formed ICC(1) interval on balanced one-way (AC1)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  fit <- icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "npbootstrap",
    boot_samples = 199L,
    seed = 1
  )
  td <- tidy(fit)

  expect_identical(fit$ci$method, "npbootstrap")
  expect_identical(fit$ci$samples, 199L)
  i1 <- td[td$index == "ICC(1)", ]
  expect_true(is.finite(i1$conf.low) && is.finite(i1$conf.high))
  expect_lt(i1$conf.low, i1$conf.high)
  expect_lte(i1$conf.high, 1)
})

test_that("npbootstrap aborts on a non-one-way design (AC1, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, ci_method = "npbootstrap"),
    class = "intraclass_unsupported"
  )
})

test_that("npbootstrap aborts on an unbalanced one-way design (AC1, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  set.seed(1)
  d <- unbalanced_oneway()
  expect_error(
    icc(d, score, subject, rater, model = "oneway", ci_method = "npbootstrap"),
    class = "intraclass_unsupported"
  )
})

test_that("npbootstrap reproduces the RR01-verified prototype endpoints (AC2 parity)", {
  skip_if_not_installed("glmmTMB")

  oracle <- readRDS(test_path("fixtures", "npbootstrap-parity-oracle.rds"))
  for (e in oracle) {
    fit <- icc(
      e$data,
      score,
      subject,
      rater,
      model = "oneway",
      unit = "single",
      ci_method = "npbootstrap",
      boot_samples = e$n_boot,
      seed = e$boot_seed
    )
    i1 <- tidy(fit)
    i1 <- i1[i1$index == "ICC(1)", ]
    # The exported reducer ports the same procedure with the same resample stream,
    # so it reproduces the prototype's endpoints far past 4 dp (identical up to
    # floating-point). Assert the >= 4 dp bar AC2 states.
    expect_equal(i1$conf.low, e$boott_icc1[1], tolerance = 1e-4)
    expect_equal(i1$conf.high, e$boott_icc1[2], tolerance = 1e-4)
  }
})

test_that("npbootstrap ICC(k) is the exact Spearman-Brown image of ICC(1) (BC2 identity)", {
  skip_if_not_installed("glmmTMB")

  oracle <- readRDS(test_path("fixtures", "npbootstrap-parity-oracle.rds"))
  for (e in oracle) {
    n <- e$cell$n
    td <- tidy(icc(
      e$data,
      score,
      subject,
      rater,
      model = "oneway",
      unit = c("single", "average"),
      ci_method = "npbootstrap",
      boot_samples = e$n_boot,
      seed = e$boot_seed
    ))
    i1 <- td[td$index == "ICC(1)", ]
    ik <- td[td$index == "ICC(k)", ]
    # The ICC(k) endpoint must equal 1 - exp(-logF) computed from the ICC(1) rho
    # endpoint, where logF uses the GROUP SIZE n. This is an exact identity only
    # when the averaging divisor k_eff equals n -- so it doubles as a k_eff = n
    # design-consistency guard on the dispatch (RR02 BC2, beyond-brief 3).
    logf_from_rho <- function(rho) log((1 + (n - 1) * rho) / (1 - rho))
    expect_equal(
      ik$conf.low,
      1 - exp(-logf_from_rho(i1$conf.low)),
      tolerance = 1e-10
    )
    expect_equal(
      ik$conf.high,
      1 - exp(-logf_from_rho(i1$conf.high)),
      tolerance = 1e-10
    )
    # Monotone map -> ordered, and ICC(k) >= ICC(1) for positive endpoints.
    expect_lte(ik$conf.low, ik$conf.high)
  }
})

test_that("npbootstrap aborts on a degenerate (zero between-variance) design (AC5, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  # Every subject shares the same mean (SSA = 0 -> log F = -Inf): the transform and
  # its jackknife SE are undefined.
  d <- data.frame(
    subject = factor(rep(seq_len(6), each = 2)),
    rater = factor(rep(seq_len(2), times = 6)),
    score = rep(c(1, 2), times = 6)
  )
  expect_error(
    icc(d, score, subject, rater, model = "oneway", ci_method = "npbootstrap", seed = 1),
    class = "intraclass_singular_fit"
  )
})

test_that("npbootstrap is reproducible and RNG-neutral (#9/#12)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  args <- list(
    d,
    quote(score),
    quote(subject),
    quote(rater),
    model = "oneway",
    ci_method = "npbootstrap",
    boot_samples = 199L,
    seed = 99
  )
  a <- tidy(do.call(icc, args))
  b <- tidy(do.call(icc, args))
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)

  # The seeded interval leaves the global RNG stream untouched (#9).
  set.seed(7)
  before <- .Random.seed
  icc(d, score, subject, rater, model = "oneway", ci_method = "npbootstrap", boot_samples = 99L, seed = 123)
  expect_identical(.Random.seed, before)
})

test_that("npbootstrap covers a known one-way population (O1 smoke)", {
  skip_if_not_installed("glmmTMB")

  # A seeded interior one-way dataset with a known rho; the interval should bracket
  # it. A single-dataset smoke, not the coverage sweep (that is the data-raw job).
  set.seed(2027)
  k <- 40L
  n <- 6L
  rho <- 0.5
  a <- stats::rnorm(k, 0, sqrt(rho))
  d <- data.frame(
    subject = factor(rep(seq_len(k), each = n)),
    rater = factor(rep(seq_len(n), times = k)),
    score = rep(a, each = n) + stats::rnorm(k * n, 0, sqrt(1 - rho))
  )
  td <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    unit = "single",
    ci_method = "npbootstrap",
    boot_samples = 999L,
    seed = 1
  ))
  i1 <- td[td$index == "ICC(1)", ]
  expect_lte(i1$conf.low, rho)
  expect_gte(i1$conf.high, rho)
})
