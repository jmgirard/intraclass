# Unbalanced one-way transformed bootstrap-t (M84, ohyama2025 §2.3 / eq. 3) -----
#
# Extends `ci_method = "npbootstrap"` to the UNBALANCED one-way ICC(1) (unequal
# n_i). The reducer is a single per-n_i path, so the balanced M75 result is a
# special case (n0 == n; C invariant across resamples). Oracles (MD-1):
#   AC2  reduces-to-balanced -- on equal n_i the reducer reproduces the committed
#        M75 prototype endpoints to <= 1e-10 (the M75 code is the oracle).
#   AC3  the unbalanced MoM point reproduces ohyama2025 §4 Example 2 (rho = 0.585)
#        via rho = (MSA - MSE)/(MSA + (n0 - 1)MSE) with the eq. 3 n0.
#   AC5  Form A -- the studentized pivot is theta = log(SSA) - log(SSE) (log F minus
#        the df-constant C), and n0 is ohyama eq. 3 (NOT the harmonic mean).
#   AC6  degenerate unbalanced input (SSA = 0 or SSE = 0) aborts loudly.
# Seeded throughout (#12).

# A reproducible unbalanced one-way dataset: 10 subjects, sizes cycling 2..5.
unbalanced_set <- function(seed = 11L, rho = 0.5) {
  set.seed(seed)
  k <- 10L
  n_i <- rep(c(2L, 3L, 4L, 5L), length.out = k)
  a <- stats::rnorm(k, 0, sqrt(rho))
  rows <- lapply(seq_len(k), function(i) {
    data.frame(
      subject = factor(i, levels = seq_len(k)),
      rater = factor(seq_len(n_i[i])),
      score = a[i] + stats::rnorm(n_i[i], 0, sqrt(1 - rho))
    )
  })
  do.call(rbind, rows)
}

test_that("npb_anova computes ohyama eq. 3 n0 (not the harmonic mean) and theta = logF - C (AC5)", {
  # A hand-checkable unbalanced group set: sizes 2, 3, 5.
  groups <- list(c(1, 3), c(2, 4, 6), c(0, 2, 4, 6, 8))
  a <- npb_anova(groups)

  n_i <- c(2, 3, 5)
  n_tot <- sum(n_i) # 10
  k <- 3
  # ohyama eq. 3: n0 = (N - sum(n_i^2)/N)/(k - 1); the harmonic mean is different.
  n0_eq3 <- (n_tot - sum(n_i^2) / n_tot) / (k - 1)
  harmonic <- k / sum(1 / n_i)
  expect_equal(a$n0, n0_eq3)
  expect_false(isTRUE(all.equal(n0_eq3, harmonic))) # eq. 3 != harmonic mean here

  # theta is the C-dropped pivot: log(SSA) - log(SSE) = log F - log{(N-k)/(k-1)}.
  c_term <- log((n_tot - k) / (k - 1))
  expect_equal(a$theta, a$logf - c_term)
})

test_that("npb_anova's n0 == n and theta == logF - C reduce correctly on balanced data (AC2/AC5)", {
  groups <- list(c(1, 3, 5), c(2, 2, 8), c(0, 3, 6), c(4, 5, 9)) # k = 4, n = 3
  a <- npb_anova(groups)
  expect_equal(a$n0, 3) # balanced n0 == group size
  c_term <- log((12 - 4) / (4 - 1))
  expect_equal(a$theta, a$logf - c_term)
})

test_that("the unbalanced MoM point reproduces ohyama Example 2 rho = 0.585 (AC3)", {
  # ohyama2025 §4 Example 2 (PaCO2, unbalanced): printed ANOVA table gives
  # MSA = 2.198, MSE = 0.272, n0 = 5.02 (eq. 3 effective size), rho = 0.585.
  msa <- 2.198
  mse <- 0.272
  n0 <- 5.02
  rho <- (msa - mse) / (msa + (n0 - 1) * mse)
  expect_equal(round(rho, 3), 0.585)

  # And npb_anova implements exactly this formula: rho == (F - 1)/(F + n0 - 1)
  # recomputed from its own returned log F and n0 (eq. 3).
  d <- unbalanced_set()
  a <- npb_anova(split(d$score, d$subject))
  f <- exp(a$logf)
  rho_recon <- (f - 1) / (f + a$n0 - 1)
  expect_equal(a$rho, rho_recon)
})

test_that("npbootstrap reduces to the balanced M75 prototype endpoints to 1e-10 (AC2)", {
  skip_if_not_installed("glmmTMB")
  # On equal n_i the per-n_i reducer must reproduce the committed M75 prototype
  # (the M75 code is the reduces-to-balanced oracle) far past 4 dp.
  oracle <- readRDS(test_path("fixtures", "npbootstrap-parity-oracle.rds"))
  for (e in oracle) {
    i1 <- tidy(icc(
      e$data,
      score,
      subject,
      rater,
      model = "oneway",
      unit = "single",
      ci_method = "npbootstrap",
      boot_samples = e$n_boot,
      seed = e$boot_seed
    ))
    i1 <- i1[i1$index == "ICC(1)", ]
    expect_equal(i1$conf.low, e$boott_icc1[1], tolerance = 1e-10)
    expect_equal(i1$conf.high, e$boott_icc1[2], tolerance = 1e-10)
  }
})

test_that("npbootstrap returns a well-formed, reproducible unbalanced ICC(1) interval (AC1)", {
  skip_if_not_installed("glmmTMB")
  d <- unbalanced_set()
  args <- list(
    d,
    quote(score),
    quote(subject),
    quote(rater),
    model = "oneway",
    unit = "single",
    ci_method = "npbootstrap",
    boot_samples = 299L,
    seed = 42
  )
  a <- tidy(do.call(icc, args))
  b <- tidy(do.call(icc, args))
  i1 <- a[a$index == "ICC(1)", ]
  expect_true(is.finite(i1$conf.low) && is.finite(i1$conf.high))
  expect_lt(i1$conf.low, i1$conf.high)
  expect_lte(i1$conf.high, 1)
  # Reproducible under the same seed (#12).
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)
})

test_that("npbootstrap covers a known unbalanced one-way population (O1 smoke)", {
  skip_if_not_installed("glmmTMB")
  d <- unbalanced_set(seed = 303L, rho = 0.5)
  i1 <- tidy(icc(
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
  i1 <- i1[i1$index == "ICC(1)", ]
  expect_lte(i1$conf.low, 0.5)
  expect_gte(i1$conf.high, 0.5)
})

test_that("npbootstrap aborts on a degenerate unbalanced design (AC6, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  # SSA = 0: all subject means equal (unbalanced sizes) -> log F = -Inf, so the
  # transform and its jackknife SE are undefined -- the one-way boundary the
  # reducer owns (SSE = 0, no within variance, is a data pathology the engine
  # point-fit rejects for every ci_method, upstream of this guard).
  d_ssa0 <- rbind(
    data.frame(subject = "1", rater = factor(1:2), score = c(0, 2)),
    data.frame(subject = "2", rater = factor(1:3), score = c(-1, 1, 3)),
    data.frame(subject = "3", rater = factor(1:4), score = c(-2, 0, 2, 4))
  )
  d_ssa0$subject <- factor(d_ssa0$subject)
  expect_error(
    icc(
      d_ssa0,
      score,
      subject,
      rater,
      model = "oneway",
      unit = "single",
      ci_method = "npbootstrap",
      seed = 1
    ),
    class = "intraclass_singular_fit"
  )
})

test_that("the reducer aborts classed on unbalanced SSE=0 and tiny-k resamples (AC6)", {
  # SSE = 0 (no within-subject variance), unbalanced: via icc() the engine point-fit
  # rejects it first, so exercise the reducer's own guard directly -- it is classed.
  est <- list(icc_estimand(unit = "single", k_eff = NA_real_, oneway = TRUE))
  d_sse0 <- data.frame(
    subject = factor(c(1, 1, 1, 2, 2, 3, 3, 3, 3)),
    score = c(1, 1, 1, 2, 2, 3, 3, 3, 3) # each subject constant -> SSE = 0
  )
  expect_error(
    npbootstrap_ci(d_sse0, est, boot_samples = 50L, seed = 1),
    class = "intraclass_singular_fit"
  )

  # Tiny unbalanced k: the observed fit is fine, but whole-subject resamples that
  # draw a degenerate set (SSA = 0 / SSE = 0) make t* non-finite -> classed abort.
  d_tiny <- data.frame(
    subject = factor(c(1, 1, 2, 2, 2, 3, 3)),
    score = c(1, 2, 4, 5, 6, 8, 9)
  )
  expect_error(
    npbootstrap_ci(d_tiny, est, boot_samples = 50L, seed = 1),
    class = "intraclass_singular_fit",
    regexp = "resamples were degenerate"
  )
})
