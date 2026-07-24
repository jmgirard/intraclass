# Exported profile-likelihood ci_method "mpl" -- two-way random ICC(A,1) (M88) ---
#
# Opt-in modified-profile-likelihood interval (xiao2013; D-015, GO-for-opt-in per
# D-014). Oracle O-MPL: the DETERMINISTIC interval core reproduces the xiao2013
# Example 1 worked example (p. 2255). The MC coverage/kappa_m Tables 3/4/6/7 are the
# committed M86 offline harness (data-raw/m86-mpl-validate.R) -- inherently MC, a fast
# suite cannot re-run them (M88 AC1, gate-amended).

# ---- AC1: xiao2013 Example 1 deterministic oracle ----------------------------

test_that("MPL core reproduces the xiao2013 Example 1 worked example (AC1)", {
  # Ex.1 (p. 2255) reports only the summary estimates (rho_hat = 0.8987,
  # delta = sigma^2_r/sigma^2_e = 1.26) for R = 4 raters, S = 10 subjects, not the
  # raw teeth data, so the (sms, rms, ems) ratios are reconstructed as the ANOVA
  # layout whose joint MLE equals that (rho_hat, delta). This pins the MLE POINT;
  # the interval is then an independent deviance-root computation, so a matching
  # interval tests the likelihood's shape, not the reconstruction (as M86 did).
  invert_ms <- function(rho, delta, n_r, n_s) {
    rho_r <- delta * (1 - rho) / (1 + delta)
    grad_sq <- function(par) {
      ms <- list(
        sms = exp(par[1]),
        rms = exp(par[2]),
        ems = 1,
        n_r = n_r,
        n_s = n_s
      )
      h <- 1e-6
      g1 <- (mpl_neg2l(rho + h, rho_r, ms) - mpl_neg2l(rho - h, rho_r, ms)) /
        (2 * h)
      g2 <- (mpl_neg2l(rho, rho_r + h, ms) - mpl_neg2l(rho, rho_r - h, ms)) /
        (2 * h)
      g1^2 + g2^2
    }
    sol <- stats::optim(
      c(log(80), log(14)),
      grad_sq,
      control = list(reltol = 1e-14, maxit = 8000)
    )
    list(
      sms = exp(sol$par[1]),
      rms = exp(sol$par[2]),
      ems = 1,
      n_r = n_r,
      n_s = n_s
    )
  }

  ex1_ms <- invert_ms(rho = 0.8987, delta = 1.26, n_r = 4, n_s = 10)
  ci <- mpl_interval(ex1_ms, kappa = 0, alpha = 0.10, side = "two")
  lower_1s <- mpl_interval(ex1_ms, kappa = 0, alpha = 0.05, side = "lower")[[
    "lower"
  ]]

  # Published (xiao2013 Ex. 1): rho_hat 0.8987; naive-PL 90% two-sided
  # (0.7120, 0.9598); 95% one-sided lower 0.7120. The point is pinned by the
  # reconstruction (a sanity check, not an independent test); the UPPER bound is an
  # independent deviance-root computation and reproduces to < 5e-3. The LOWER bound
  # reproduces only to ~0.012: the reconstruction inputs (rho_hat, delta) are 4-/3-
  # sig-fig rounded in the paper, and an S = 10 lower bound is rounding-sensitive, so
  # it is NOT forced to the printed digit (#4). M86 likewise treated Ex.1 as a
  # non-gated spot check; the tight oracle evidence is the MC Tables 3/4/6/7 (offline).
  expect_lt(abs(ci[["rho_hat"]] - 0.8987), 1e-3)
  expect_lt(abs(ci[["upper"]] - 0.9598), 5e-3)
  expect_lt(abs(ci[["lower"]] - 0.7120), 1.5e-2)
  expect_lt(abs(lower_1s - 0.7120), 1.5e-2)
  # The two-sided lower and the 95% one-sided lower coincide here (xiao2013's shared
  # critical value, Ex. 1): both use the 90% two-sided lower crit.
  expect_equal(ci[["lower"]], lower_1s, tolerance = 1e-6)
})

# ---- Deterministic interval machinery structural checks ----------------------

test_that("MPL two-sided interval is ordered and brackets the MLE (AC1)", {
  # A concrete balanced complete matrix; the two-sided interval must satisfy
  # lower <= rho_hat <= upper with both endpoints in [0, 1].
  set.seed(88)
  s <- stats::rnorm(20, sd = sqrt(0.7))
  r <- stats::rnorm(4, sd = sqrt(0.1))
  y <- outer(s, rep(1, 4)) +
    outer(rep(1, 20), r) +
    matrix(stats::rnorm(80, sd = sqrt(0.2)), 20, 4)
  ci <- mpl_interval(mpl_anova(y), kappa = 0.3, alpha = 0.05, side = "two")
  expect_gte(ci[["lower"]], 0)
  expect_lte(ci[["upper"]], 1)
  expect_lte(ci[["lower"]], ci[["rho_hat"]])
  expect_lte(ci[["rho_hat"]], ci[["upper"]])
})

test_that("mpl_matrix reshapes complete long data and aborts on a missing cell", {
  df <- expand.grid(subject = factor(1:6), rater = factor(1:3))
  df$score <- as.numeric(df$subject) + stats::rnorm(nrow(df))
  y <- mpl_matrix(df)
  expect_equal(dim(y), c(6L, 3L))

  df_gap <- df[!(df$subject == "1" & df$rater == "3"), ]
  expect_error(mpl_matrix(df_gap), class = "intraclass_unidentified")
})

# ---- Shared fixture: a balanced complete two-way random dataset --------------
# S subjects x R raters, absolute-agreement components (sigma^2_s, sigma^2_r,
# sigma^2_e). S is kept in the shipped kappa_m grid [10, 100] so the lookup resolves.
mpl_twoway_long <- function(
  n_s = 20,
  n_r = 4,
  s2s = 0.6,
  s2r = 0.1,
  s2e = 0.2,
  seed = 88
) {
  set.seed(seed)
  s <- stats::rnorm(n_s, sd = sqrt(s2s))
  r <- stats::rnorm(n_r, sd = sqrt(s2r))
  y <- outer(s, rep(1, n_r)) +
    outer(rep(1, n_s), r) +
    matrix(stats::rnorm(n_s * n_r, sd = sqrt(s2e)), n_s, n_r)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(y)
  )
}

# ---- AC2 + AC5: end-to-end dispatch ------------------------------------------

test_that("mpl reports the engine REML point + deterministic metadata (AC2)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long()
  mc <- tidy(icc(d, score, subject, rater, ci_method = "montecarlo", seed = 1))
  mc1 <- mc[mc$index == "ICC(A,1)", ]

  fit <- icc(d, score, subject, rater, ci_method = "mpl")
  td <- tidy(fit)
  i1 <- td[td$index == "ICC(A,1)", ]

  # Deterministic closed form: raw token "mpl", no draws, no SE (D-015).
  expect_identical(fit$ci$method, "mpl")
  expect_true(is.na(fit$ci$samples))
  expect_true(is.na(i1$std.error))
  # The POINT is the shared engine (REML) point, identical to montecarlo (BC5).
  expect_equal(i1$estimate, mc1$estimate, tolerance = 1e-8)
  # A finite, ordered interval in [0, 1].
  expect_true(is.finite(i1$conf.low) && is.finite(i1$conf.high))
  expect_lt(i1$conf.low, i1$conf.high)
  expect_gte(i1$conf.low, 0)
  expect_lte(i1$conf.high, 1)
  # print() names the interval (AC2). Assert on the formatted header vector
  # directly -- cli renders it to a styled/wrapped stream expect_output misses.
  expect_true(any(grepl(
    "modified profile likelihood",
    cli::ansi_strip(format(fit)),
    fixed = TRUE
  )))
})

test_that("mpl returns an interval where the two-way MC default aborts (AC5)", {
  skip_if_not_installed("glmmTMB")

  # A near-zero-rho boundary cell (sigma^2_s ~ 0): the two-way random MC default aborts
  # on a sizeable fraction of such datasets (intraclass_singular_fit; D-014 AC4). mpl
  # returns an interval on 100% of them -- the residual value D-014 ships it for. Find
  # one dataset (in the kappa_m grid) where MC aborts and assert mpl does not.
  aborted <- FALSE
  for (sd in 1:40) {
    d <- mpl_twoway_long(
      n_s = 20,
      n_r = 3,
      s2s = 1e-4,
      s2r = 0.3,
      s2e = 0.6,
      seed = sd
    )
    mc <- tryCatch(
      icc(d, score, subject, rater, ci_method = "montecarlo", seed = 1),
      intraclass_singular_fit = function(e) "aborted"
    )
    if (identical(mc, "aborted")) {
      aborted <- TRUE
      fit <- icc(d, score, subject, rater, ci_method = "mpl")
      i1 <- tidy(fit)[tidy(fit)$index == "ICC(A,1)", ]
      expect_true(is.finite(i1$conf.low) && is.finite(i1$conf.high))
      break
    }
  }
  skip_if_not(aborted, "no MC abort found in the seed sweep (boundary luck)")
})

# ---- AC3: ICC(A,k) is the exact Spearman-Brown image of ICC(A,1) -------------

test_that("mpl ICC(A,k) is the exact Spearman-Brown image of ICC(A,1), divisor R (AC3)", {
  skip_if_not_installed("glmmTMB")

  n_r <- 4L
  d <- mpl_twoway_long(n_s = 20, n_r = n_r)
  td <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = c("single", "average"),
    ci_method = "mpl"
  ))
  i1 <- td[td$index == "ICC(A,1)", ]
  ik <- td[td$index == "ICC(A,k)", ]
  # xiao2013's MPL has no independent ICC(A,k) construction (inheritance, not an anchor
  # -- the D-013 Burch precedent; a "direct" side built by inverting the package's own
  # ICC(A,1) endpoint would be tautological, M82 lesson). The verifiable property is the
  # exact monotone Spearman-Brown image with divisor R: for two-way RANDOM absolute
  # agreement, ICC(A,k) = k*rho/(1+(k-1)rho) with rho = ICC(A,1) (McGraw & Wong 1996
  # Table 4). Recompute the SB map INDEPENDENTLY (not via the package's npb_sb) so a
  # wrong divisor would break the equality.
  sb <- function(rho, m) m * rho / (1 + (m - 1) * rho)
  expect_equal(ik$conf.low, sb(i1$conf.low, n_r), tolerance = 1e-9)
  expect_equal(ik$conf.high, sb(i1$conf.high, n_r), tolerance = 1e-9)
  # Mutation proof: a wrong divisor (R+1) does NOT reproduce the shipped endpoints.
  expect_false(isTRUE(all.equal(ik$conf.high, sb(i1$conf.high, n_r + 1))))
})

# ---- AC4: the two-way-random-agreement fence + off-grid abort ----------------

test_that("mpl aborts outside the two-way random absolute-agreement cell (AC4)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long()
  # one-way, consistency, fixed raters, numeric unit, non-0.95 level all abort.
  expect_error(
    icc(d, score, subject, rater, model = "oneway", ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, type = "consistency", ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
  # raters = "fixed" also emits the fixed-rater advisory warning before the abort;
  # suppress it so the expected abort is what the test asserts on.
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      ci_method = "mpl"
    )),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, unit = 2, ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, ci_method = "mpl", conf_level = 0.90),
    class = "intraclass_unsupported"
  )
})

test_that("mpl aborts on an unbalanced design and off the kappa_m grid (AC4)", {
  skip_if_not_installed("glmmTMB")

  # Incomplete two-way (a dropped cell) -> not balanced -> abort.
  d <- mpl_twoway_long()
  d_gap <- d[!(d$subject == "1" & d$rater == "2"), ]
  expect_error(
    icc(d_gap, score, subject, rater, ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
  # Balanced two-way but S = 6 subjects -- below the kappa_m grid's min (10). The fence
  # passes; the lookup aborts rather than extrapolating an uncalibrated kappa_m (#5).
  d_small <- mpl_twoway_long(n_s = 6, n_r = 4)
  expect_error(
    icc(d_small, score, subject, rater, ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
})

test_that("mpl aborts on a within-cell-replicated two-way design (AC4)", {
  skip_if_not_installed("glmmTMB")

  # Uniform within-cell replicates keep balanced == TRUE, but the interval assumes one
  # rating per subject x rater cell (the M17/M20 replicate estimand is out of scope);
  # mpl_matrix would silently collapse replicates to cell means, so the fence must
  # abort rather than return a mis-calibrated interval (#5).
  set.seed(1)
  d <- expand.grid(subject = factor(1:15), rater = factor(1:3), rep = 1:4)
  s <- stats::rnorm(15, sd = sqrt(0.6))
  r <- stats::rnorm(3, sd = sqrt(0.1))
  d$score <- s[d$subject] + r[d$rater] + stats::rnorm(nrow(d), sd = sqrt(1.2))
  expect_error(
    icc(d, score, subject, rater, ci_method = "mpl"),
    class = "intraclass_unsupported"
  )
})

test_that("mpl informs when it drops consistency from a defaulted type (AC4)", {
  skip_if_not_installed("glmmTMB")

  # The default type is c("agreement", "consistency"); mpl narrows it to agreement but
  # must SAY SO (ADR-054/ADR-029 drop-vs-abort convention), like every other
  # default-vector narrowing in icc().
  d <- mpl_twoway_long()
  expect_message(
    icc(d, score, subject, rater, ci_method = "mpl"),
    "Dropping.*consistency"
  )
})
