# Classical boundary-robust one-way ci_methods "searle" + "burch" (M82) ---------
#
# Exported opt-in classical one-way ICC intervals (D-012 GO-for-opt-in; assessed
# in M76). Oracle O-Classical-OW: each interval CORE reproduces >= 2 independent
# published worked examples (ohyama2025 §4 + burch2011 §4), migrated here from the
# M76 prototype's `stopifnot` (data-raw/m76-classical-oneway-prototype.R). Plus the
# two self-checks (mcgraw1996 Table 7 algebraic identity; Burch eq.13/14/15
# kurtosis-pipeline self-consistency), the balanced-one-way guards, engine-point
# (BC5) parity, and the ICC(k) Spearman-Brown identity (AC4).

# ---- AC1: published-example oracles, SEARLE exact-F --------------------------

test_that("SEARLE core reproduces the ohyama2025 Ex.1 PMOC oracle (AC1)", {
  # ohyama2025 §4 Ex.1 PMOC, balanced k=30 n=2 (Table 2, p. 599): between df 29
  # MS 185.43, within df 30 MS 22.17; printed SEARLE (0.600, 0.891). The ~0.001
  # residual is the paper's integer-SS rounding (flagged in ohyama2025.md).
  ex1 <- searle_endpoints(msa = 185.43, mse = 22.17, df1 = 29, df2 = 30, n = 2)
  # Absolute-difference oracle bounds (as the M76 prototype asserts them).
  expect_lt(abs(ex1[["lower"]] - 0.600), 0.002)
  expect_lt(abs(ex1[["upper"]] - 0.891), 0.002)
})

test_that("SEARLE core reproduces the burch2011 §4 arsenic oracle (AC1, 2nd source)", {
  # burch2011 sec 4 arsenic, a=28 labs b=4 reps (Table 3, p. 1027). burch2011
  # eq. 3 (normal-based) is algebraically the SEARLE pivot, so its printed
  # (0.81, 0.94) is a second independent published SEARLE oracle.
  sa <- searle_endpoints(773.33 / 27, 76.88 / 84, df1 = 27, df2 = 84, n = 4)
  expect_lt(abs(sa[["lower"]] - 0.81), 0.005)
  expect_lt(abs(sa[["upper"]] - 0.94), 0.005)
})

# ---- AC1: published-example oracles, Burch REML ------------------------------

test_that("Burch core reproduces the ohyama2025 Ex.1 PMOC REML oracle (AC1)", {
  # ohyama2025 §4 Ex.1 PMOC REML: prints bias-corrected kurtosis -0.277,
  # g(kappa) = -0.515, REML CI (0.620, 0.885). Check g() and the eq.17 core.
  expect_lt(abs(burch_g(-0.277) - (-0.515)), 0.001)
  reml_ex1 <- burch_reml_endpoints(185.43, 22.17, k = 30, n = 2, g_val = -0.515)
  expect_lt(abs(reml_ex1[["lower"]] - 0.620), 0.002)
  expect_lt(abs(reml_ex1[["upper"]] - 0.885), 0.002)
})

test_that("Burch core reproduces the burch2011 §4 arsenic REML oracle (AC1, 2nd source)", {
  msa_ars <- 773.33 / 27
  mse_ars <- 76.88 / 84
  theta_ars <- (msa_ars / mse_ars - 1) / 4
  expect_lt(abs(theta_ars - 7.57), 0.01) # paper's printed theta-hat
  expect_lt(abs(theta_ars / (1 + theta_ars) - 0.88), 0.005) # rho-hat
  reml_ars <- burch_reml_endpoints(
    msa_ars,
    mse_ars,
    k = 28,
    n = 4,
    g_val = 7.75
  )
  expect_lt(abs(reml_ars[["lower"]] - 0.73), 0.005)
  expect_lt(abs(reml_ars[["upper"]] - 0.95), 0.005)
})

# ---- AC2: self-checks --------------------------------------------------------

test_that("SEARLE equals the mcgraw1996 Table 7 F-form algebraically (AC2)", {
  # mcgraw1996 Table 7 ICC(1) limits: (F_L-1)/(F_L+n0-1), (F_U-1)/(F_U+n0-1)
  # with F_L = F/F*(df1,df2), F_U = F*F*(df2,df1) (df SWAPPED between limits) --
  # an independent construction that must equal the SEARLE pivot to machine eps.
  f_obs <- 185.43 / 22.17
  fl <- f_obs / stats::qf(0.975, 29, 30)
  fu <- f_obs * stats::qf(0.975, 30, 29)
  mcgraw <- c((fl - 1) / (fl + 1), (fu - 1) / (fu + 1)) # n0 = 2
  ex1 <- searle_endpoints(185.43, 22.17, df1 = 29, df2 = 30, n = 2)
  expect_equal(unname(mcgraw), unname(ex1), tolerance = 1e-9)
})

test_that("Burch kurtosis pipeline is self-consistent under normality (AC2)", {
  # eq.13 raw-data kurtosis has E(kappa-hat) = eq.14 under normality, and the
  # bias-corrected E(kappa-hat-hat) = 0 by construction -- a two-equation internal
  # cross-check over normal balanced datasets (caught the M76 eq.14 cube bug).
  set.seed(76)
  kk <- 25L
  nn <- 5L
  nrep <- 2000L
  kh <- numeric(nrep)
  kbc <- numeric(nrep)
  for (r in seq_len(nrep)) {
    a_i <- stats::rnorm(kk, 0, 1) # rho = 0.5 (sigma_a = sigma_e = 1)
    y <- rep(a_i, each = nn) + stats::rnorm(kk * nn, 0, 1)
    groups <- split(y, rep(seq_len(kk), each = nn))
    ybar_i <- vapply(groups, mean, numeric(1))
    grand <- mean(y)
    msa <- nn * sum((ybar_i - grand)^2) / (kk - 1)
    mse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1))) /
      (kk * (nn - 1))
    kh[r] <- burch_kappa_hat(groups, msa, mse)
    kbc[r] <- burch_kappa_bc(kh[r], kk, nn)
  }
  e_kappa_normal <- 3 * burch_p_term(kk, nn) / (kk^2 * nn^2) - 3
  expect_equal(mean(kh), e_kappa_normal, tolerance = 0.04)
  expect_equal(mean(kbc), 0, tolerance = 0.04)
})

# ---- AC5 + AC1: end-to-end dispatch ------------------------------------------

test_that("searle/burch report the engine REML point and a finite interval (AC1, AC5)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  mc <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "montecarlo",
    seed = 1
  ))
  mc1 <- mc[mc$index == "ICC(1)", ]

  for (m in c("searle", "burch")) {
    fit <- icc(d, score, subject, rater, model = "oneway", ci_method = m)
    td <- tidy(fit)
    i1 <- td[td$index == "ICC(1)", ]
    # Method + deterministic metadata (BC5 analog): closed form, no draws, no SE.
    expect_identical(fit$ci$method, m)
    expect_true(is.na(fit$ci$samples))
    expect_true(is.na(i1$std.error))
    # The POINT is the shared engine (REML) point, identical to montecarlo.
    expect_equal(i1$estimate, mc1$estimate, tolerance = 1e-8)
    # A finite, ordered interval on data where it must exist.
    expect_true(is.finite(i1$conf.low) && is.finite(i1$conf.high))
    expect_lt(i1$conf.low, i1$conf.high)
    expect_lte(i1$conf.high, 1)
  }
})

# ---- AC3: balanced-one-way guards --------------------------------------------

test_that("searle/burch abort on a non-one-way design (AC3, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  for (m in c("searle", "burch")) {
    expect_error(
      icc(d, score, subject, rater, ci_method = m),
      class = "intraclass_unsupported"
    )
  }
})

test_that("searle/burch abort on an unbalanced one-way design (AC3, #5/#8)", {
  skip_if_not_installed("glmmTMB")

  set.seed(1)
  d <- expand.grid(subject = factor(seq_len(8)), rater = factor(seq_len(4)))
  d$score <- 10 + as.integer(d$subject) + stats::rnorm(nrow(d))
  d <- d[!(d$subject == "1" & d$rater == "4"), ] # subject 1 rated 3x
  for (m in c("searle", "burch")) {
    expect_error(
      icc(d, score, subject, rater, model = "oneway", ci_method = m),
      class = "intraclass_unsupported"
    )
  }
})

# ---- AC4: ICC(k) is the Spearman-Brown image, equal to the direct F-form -----

test_that("searle ICC(k) endpoints equal the direct classical ICC(k) F-form (AC4)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  n <- 4L # sf_ratings_long is balanced 4-rater
  td <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    unit = c("single", "average"),
    ci_method = "searle"
  ))
  i1 <- td[td$index == "ICC(1)", ]
  ik <- td[td$index == "ICC(k)", ]
  # The SB image of the ICC(1) rho endpoint must equal the direct ICC(k) F-form
  # 1 - 1/g, where g is recovered from the ICC(1) endpoint rho via g = 1 + n*rho/(1-rho)
  # (invert rho(g) = (g-1)/(g+n-1)). Both the SB map and the direct form are exact.
  g_of_rho <- function(rho) 1 + n * rho / (1 - rho)
  expect_equal(ik$conf.low, 1 - 1 / g_of_rho(i1$conf.low), tolerance = 1e-9)
  expect_equal(ik$conf.high, 1 - 1 / g_of_rho(i1$conf.high), tolerance = 1e-9)
})

test_that("burch ICC(k) endpoints equal the direct averaged-reliability form (AC4)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  n <- 4L
  td <- tidy(icc(
    d,
    score,
    subject,
    rater,
    model = "oneway",
    unit = c("single", "average"),
    ci_method = "burch"
  ))
  i1 <- td[td$index == "ICC(1)", ]
  ik <- td[td$index == "ICC(k)", ]
  # Burch's ICC(1) endpoint is rho(theta) = theta/(1+theta); ICC(k) = n*theta/(1+n*theta)
  # = 1 - 1/(1+n*theta). Recover theta from the ICC(1) endpoint (theta = rho/(1-rho))
  # and confirm the SB-mapped ICC(k) equals that direct form.
  theta_of_rho <- function(rho) rho / (1 - rho)
  direct <- function(rho) {
    th <- theta_of_rho(rho)
    1 - 1 / (1 + n * th)
  }
  expect_equal(ik$conf.low, direct(i1$conf.low), tolerance = 1e-9)
  expect_equal(ik$conf.high, direct(i1$conf.high), tolerance = 1e-9)
})
