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
  # returned an interval on 100% of them in the D-014 sweep -- the residual value it
  # ships for (since M99 a genuine root-finding failure aborts classed instead, a
  # branch unreachable on such data). Find one dataset (in the kappa_m grid) where
  # MC aborts and assert mpl does not.
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

# ---- M89: numeric unit ICC(A,m) is the pole-safe SB image --------------------

test_that("mpl numeric unit ICC(A,m) is the exact Spearman-Brown image of ICC(A,1) (M89 AC1/AC2)", {
  skip_if_not_installed("glmmTMB")

  n_r <- 4L
  d <- mpl_twoway_long(n_s = 20, n_r = n_r)
  # A numeric `unit = m` is a D-study projection ICC(A,m): reliability of the mean of m
  # raters freshly sampled from the same population. For two-way RANDOM absolute
  # agreement it is the exact Spearman-Brown image ICC(A,m) = m*rho/(1+(m-1)rho) with
  # rho = ICC(A,1) (McGraw & Wong 1996 Table 4) -- pole-safe for ANY m >= 1, because the
  # SB pole rho = -1/(m-1) is negative while the MPL endpoints lie in [0, 1] (M89,
  # D-016). Recompute the SB map INDEPENDENTLY of the package's npb_sb so a wrong
  # divisor would break the equality (M82 anti-tautology lesson).
  sb <- function(rho, m) m * rho / (1 + (m - 1) * rho)
  i1 <- tidy(icc(d, score, subject, rater, ci_method = "mpl"))
  i1 <- i1[i1$index == "ICC(A,1)", ]

  for (m in c(1, 2, 3.5, n_r, 8)) {
    label <- paste0("ICC(A,", format(m, trim = TRUE), ")")
    im <- tidy(icc(d, score, subject, rater, unit = m, ci_method = "mpl"))
    im <- im[im$index == label, ]
    expect_equal(nrow(im), 1L)
    expect_equal(im$conf.low, sb(i1$conf.low, m), tolerance = 1e-9)
    expect_equal(im$conf.high, sb(i1$conf.high, m), tolerance = 1e-9)
    # Pole-safe: finite, ordered, inside [0, 1] for every m.
    expect_gte(im$conf.low, 0)
    expect_lte(im$conf.high, 1)
    expect_lte(im$conf.low, im$conf.high)
  }

  # m = 1 reduces to ICC(A,1) exactly; m = R matches unit = "average" (both divisor R).
  m1 <- tidy(icc(d, score, subject, rater, unit = 1, ci_method = "mpl"))
  m1 <- m1[m1$index == "ICC(A,1)", ]
  expect_equal(m1$conf.low, i1$conf.low, tolerance = 1e-12)
  expect_equal(m1$conf.high, i1$conf.high, tolerance = 1e-12)
  avg <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = "average",
    ci_method = "mpl"
  ))
  avg <- avg[avg$index == "ICC(A,k)", ]
  imr <- tidy(icc(d, score, subject, rater, unit = n_r, ci_method = "mpl"))
  imr <- imr[imr$index == "ICC(A,4)", ]
  expect_equal(imr$conf.low, avg$conf.low, tolerance = 1e-12)
  expect_equal(imr$conf.high, avg$conf.high, tolerance = 1e-12)

  # Mutation proof: the shipped m = 2 endpoint is NOT reproduced by a wrong divisor, so
  # the equalities above test the divisor, not a tautology.
  i2 <- tidy(icc(d, score, subject, rater, unit = 2, ci_method = "mpl"))
  i2 <- i2[i2$index == "ICC(A,2)", ]
  expect_false(isTRUE(all.equal(i2$conf.high, sb(i1$conf.high, 3))))
})

test_that("mpl numeric unit reports the engine ICC(A,m) point, deterministic + monotone (M89 AC3)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long(n_s = 20, n_r = 4)
  # The reported point is the shared engine (glmmTMB REML) ICC(A,m) point, identical to
  # what montecarlo reports for the same numeric unit (BC5); metadata is deterministic
  # (no draws, no SE), mirroring ICC(A,1)/ICC(A,k).
  mc <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = 6,
    ci_method = "montecarlo",
    seed = 1
  ))
  mc6 <- mc[mc$index == "ICC(A,6)", ]
  fit <- icc(d, score, subject, rater, unit = 6, ci_method = "mpl")
  i6 <- tidy(fit)[tidy(fit)$index == "ICC(A,6)", ]
  expect_equal(i6$estimate, mc6$estimate, tolerance = 1e-8)
  expect_true(is.na(fit$ci$samples))
  expect_true(is.na(i6$std.error))

  # conf.low is monotone increasing in m at fixed data (SB increases in m on [0, 1]).
  lows <- vapply(
    c(1, 2, 4, 8, 20),
    function(m) {
      tm <- tidy(icc(d, score, subject, rater, unit = m, ci_method = "mpl"))
      tm$conf.low[tm$index == paste0("ICC(A,", m, ")")]
    },
    numeric(1)
  )
  expect_false(is.unsorted(lows))

  # Vectorized units resolve together in one call.
  tv <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = c("single", "average", 6),
    ci_method = "mpl"
  ))
  expect_setequal(tv$index, c("ICC(A,1)", "ICC(A,k)", "ICC(A,6)"))
})

# ---- AC4: the two-way-random-agreement fence + off-grid abort ----------------

test_that("mpl aborts outside the two-way random absolute-agreement cell (AC4)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long()
  # one-way, consistency, fixed raters, non-0.95 level all abort. (A numeric unit is
  # NOT here -- since M89 it is a supported pole-safe SB projection, tested below.)
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
  # A numeric unit under FIXED raters stays unsupported: absolute-agreement projection
  # to m freshly sampled raters is ill-posed with a finite rater population (#5).
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      raters = "fixed",
      unit = 2,
      ci_method = "mpl"
    )),
    class = "intraclass_unsupported"
  )
  # conf_level 0.90 / 0.95 / 0.99 are calibrated and supported since M91; an
  # UNcalibrated level still aborts (covered in the M91 block below).
})

# ---- M91: conf_level 0.90 / 0.99 ---------------------------------------------
# The kappa_m table carries one calibrated slice per level (0.95 from M88/D-015;
# 0.90 and 0.99 recalibrated + coverage-validated in M90 under D-017), so
# conf_level KEYS the correction as well as setting alpha. Coverage itself is
# established offline (M90's sweep + M91's interpolated-S cells D1-D4); the tests
# here pin the table -> endpoint wiring, the inheritance identity, the fence, and
# the absence of a 0.95 regression.

test_that("mpl at conf_level 0.90/0.99 uses that level's calibrated kappa_m (M91 AC1)", {
  skip_if_not_installed("glmmTMB")

  n_s <- 20L
  n_r <- 4L
  d <- mpl_twoway_long(n_s = n_s, n_r = n_r)
  ms <- mpl_anova(mpl_matrix(d))

  for (cl in c(0.90, 0.95, 0.99)) {
    # kappa_m read straight from the shipped table's slice for this (R, S, level) --
    # an ON-node geometry, so no interpolation is involved in the expectation.
    slice <- kappa_m_table[
      kappa_m_table$n_r == n_r &
        kappa_m_table$n_s == n_s &
        abs(kappa_m_table$conf_level - cl) < 1e-8,
    ]
    expect_equal(nrow(slice), 1L)
    want <- mpl_interval(
      ms,
      kappa = slice$kappa_m,
      alpha = 1 - cl,
      side = "two"
    )

    got <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      ci_method = "mpl",
      conf_level = cl
    )))
    got <- got[got$index == "ICC(A,1)", ]
    expect_equal(got$conf.low, unname(want[["lower"]]), tolerance = 1e-10)
    expect_equal(got$conf.high, unname(want[["upper"]]), tolerance = 1e-10)
    # Deterministic at every level (D-015): no draws, no SE.
    expect_true(is.na(got$std.error))
  }
})

test_that("mpl kappa_m and interval width are strictly ordered in conf_level (M91 AC1)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long(n_s = 20L, n_r = 4L)
  ends <- lapply(c(0.90, 0.95, 0.99), function(cl) {
    a <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      ci_method = "mpl",
      conf_level = cl
    )))
    a[a$index == "ICC(A,1)", c("conf.low", "conf.high")]
  })

  # A deeper level is a strictly wider interval and strictly nests the shallower
  # ones. This is a property of the deviance-quantile machinery and holds whatever
  # kappa_m is: a wrong-slice lookup that returned, say, the 0.95 constant at 0.99
  # would still nest, so this is a sanity property, NOT the wiring test above.
  expect_lt(ends[[2]]$conf.low, ends[[1]]$conf.low)
  expect_gt(ends[[2]]$conf.high, ends[[1]]$conf.high)
  expect_lt(ends[[3]]$conf.low, ends[[2]]$conf.low)
  expect_gt(ends[[3]]$conf.high, ends[[2]]$conf.high)
})

test_that("mpl ICC(A,k)/ICC(A,m) inherit the new levels via Spearman-Brown (M91 AC2)", {
  skip_if_not_installed("glmmTMB")

  n_r <- 4L
  d <- mpl_twoway_long(n_s = 20L, n_r = n_r)
  # Recompute the SB map INDEPENDENTLY of the package's npb_sb, so a wrong divisor
  # breaks the equality (M82 anti-tautology lesson) -- as the M89 block does at 0.95.
  sb <- function(rho, m) m * rho / (1 + (m - 1) * rho)

  for (cl in c(0.90, 0.99)) {
    i1 <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      ci_method = "mpl",
      conf_level = cl
    )))
    i1 <- i1[i1$index == "ICC(A,1)", ]

    for (m in c(2, 3.5, n_r, 8)) {
      label <- paste0("ICC(A,", format(m, trim = TRUE), ")")
      im <- suppressWarnings(tidy(icc(
        d,
        score,
        subject,
        rater,
        unit = m,
        ci_method = "mpl",
        conf_level = cl
      )))
      im <- im[im$index == label, ]
      expect_equal(nrow(im), 1L)
      expect_equal(im$conf.low, sb(i1$conf.low, m), tolerance = 1e-9)
      expect_equal(im$conf.high, sb(i1$conf.high, m), tolerance = 1e-9)
      # Mutation guard: the SB image at the WRONG divisor must differ, so the
      # equality above is testing the divisor and not just monotonicity.
      expect_false(isTRUE(all.equal(im$conf.low, sb(i1$conf.low, m + 1))))
      expect_gte(im$conf.low, 0)
      expect_lte(im$conf.high, 1)
    }
  }
})

test_that("mpl aborts on an uncalibrated conf_level, naming the supported set (M91 AC3)", {
  skip_if_not_installed("glmmTMB")

  d <- mpl_twoway_long()
  # A level between calibrated ones, a shallower one, and a DEEPER one: kappa_m is
  # calibrated at its own deviance quantile and is not interpolated in alpha, and
  # D-017 authorizes no level deeper than 0.99 (kappa_corr is still rising at
  # alpha = 0.005 in the boundary cells).
  for (cl in c(0.80, 0.975, 0.995, 0.999)) {
    expect_error(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        ci_method = "mpl",
        conf_level = cl
      )),
      class = "intraclass_unsupported"
    )
  }
  # The message names the supported set, so a user can act on it (#8).
  err <- tryCatch(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      ci_method = "mpl",
      conf_level = 0.975
    )),
    intraclass_unsupported = function(e) conditionMessage(e)
  )
  expect_match(err, "0\\.90")
  expect_match(err, "0\\.95")
  expect_match(err, "0\\.99")
})

test_that("the shipped kappa_m table keeps M88's 0.95 slice unchanged (M91 AC4)", {
  # The 0.95 slice is copied VERBATIM from M88's committed calibration
  # (data-raw/m88-kappa-table.rds via data-raw/m91-mpl-kappa-sysdata.R) -- M91
  # re-keys the table, it does not recalibrate any level.
  expect_named(
    kappa_m_table,
    c("n_r", "n_s", "conf_level", "kappa_m"),
    ignore.order = TRUE
  )
  # Every level shares one (R, S) grid: 2..10 raters x 6 subject nodes.
  grids <- lapply(
    split(kappa_m_table, kappa_m_table$conf_level),
    function(d) sort(paste(d$n_r, d$n_s, sep = "-"))
  )
  expect_length(unique(grids), 1L)
  expect_equal(sort(unique(kappa_m_table$conf_level)), c(0.90, 0.95, 0.99))
  expect_true(all(is.finite(kappa_m_table$kappa_m)))
  expect_true(all(kappa_m_table$kappa_m >= 0))

  # Spot-pin four 0.95 nodes against M88's shipped values (recorded pre-M91).
  km95 <- function(n_r, n_s) {
    kappa_m_table$kappa_m[
      kappa_m_table$n_r == n_r &
        kappa_m_table$n_s == n_s &
        abs(kappa_m_table$conf_level - 0.95) < 1e-8
    ]
  }
  expect_equal(km95(2L, 10L), 0.8155326, tolerance = 1e-6)
  expect_equal(km95(2L, 100L), 1.6245186, tolerance = 1e-6)
  expect_equal(km95(4L, 20L), 0.4348870, tolerance = 1e-6)
  expect_equal(km95(10L, 50L), 0.1176505, tolerance = 1e-6)
})

test_that("mpl at conf_level 0.95 reproduces the pre-M91 endpoints (M91 AC4)", {
  skip_if_not_installed("glmmTMB")

  # Endpoint no-regression. These literals were recorded from the shipped package
  # BEFORE the table was re-keyed (M91 T3), on the fixture below at its default
  # geometry (S = 20, R = 4) and at the off-node S = 25 that exercises the
  # interpolation path -- so a wrong slice, a wrong interpolation, or a changed
  # 0.95 value all break this test.
  d <- mpl_twoway_long()
  a <- suppressWarnings(tidy(icc(d, score, subject, rater, ci_method = "mpl")))
  a1 <- a[a$index == "ICC(A,1)", ]
  ak <- a[a$index == "ICC(A,k)", ]
  expect_equal(a1$conf.low, 0.42467599012062407, tolerance = 1e-12)
  expect_equal(a1$conf.high, 0.86530180057602046, tolerance = 1e-12)
  expect_equal(ak$conf.low, 0.74700222803863625, tolerance = 1e-12)
  expect_equal(ak$conf.high, 0.96254122832062028, tolerance = 1e-12)

  u2 <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = 2,
    ci_method = "mpl"
  )))
  u2 <- u2[u2$index == "ICC(A,2)", ]
  expect_equal(u2$conf.low, 0.5961720321891123, tolerance = 1e-12)
  expect_equal(u2$conf.high, 0.92778745006176289, tolerance = 1e-12)

  # Off-node S = 25: linear-in-S interpolation inside the 0.95 slice.
  d25 <- mpl_twoway_long(n_s = 25L)
  a25 <- suppressWarnings(tidy(icc(
    d25,
    score,
    subject,
    rater,
    ci_method = "mpl"
  )))
  a25 <- a25[a25$index == "ICC(A,1)", ]
  expect_equal(a25$conf.low, 0.47848269350346301, tolerance = 1e-12)
  expect_equal(a25$conf.high, 0.89826274702687159, tolerance = 1e-12)
})

test_that("mpl_kappa_lookup interpolates within a level, never across levels (M91 AC1)", {
  # S is interpolated inside the level's own slice: the value at an off-node S must
  # be the chord between ITS level's bracketing nodes, and must not coincide with a
  # neighbouring level's value (which is what a slice mix-up would produce).
  for (cl in c(0.90, 0.95, 0.99)) {
    slice <- kappa_m_table[abs(kappa_m_table$conf_level - cl) < 1e-8, ]
    node20 <- slice$kappa_m[slice$n_r == 3L & slice$n_s == 20L]
    node30 <- slice$kappa_m[slice$n_r == 3L & slice$n_s == 30L]
    expect_equal(
      mpl_kappa_lookup(3L, 25L, conf_level = cl),
      mean(c(node20, node30)),
      tolerance = 1e-12
    )
  }
  # The three levels give three different constants at the same geometry.
  got <- vapply(
    c(0.90, 0.95, 0.99),
    function(cl) mpl_kappa_lookup(3L, 25L, conf_level = cl),
    numeric(1)
  )
  expect_length(unique(got), 3L)
  # A defensive internal guard: an uncalibrated level aborts here too, so a direct
  # internal call cannot silently select an empty slice.
  expect_error(
    mpl_kappa_lookup(3L, 25L, conf_level = 0.975),
    class = "intraclass_unsupported"
  )
})

test_that("the 0.95 off-node kappa_m values M92 coverage-validated are what ships (M92 AC5)", {
  # GP7. M92 measured coverage at conf_level 0.95 at three off-node S geometries
  # (cairn/references/mpl-twoway-random-comparison.md § M92; the seeded sweep is
  # data-raw/m92-mpl-095-interp-sweep.R -> data-raw/m92-interp-sweep.rds). The
  # evidence is only load-bearing while the runtime keeps producing the SAME
  # constant the sweep fed to mpl_interval(): the sweep reimplements the lookup
  # rule offline, so a change to either the shipped 0.95 slice or to
  # mpl_kappa_lookup's interpolation would silently detach the code from its own
  # coverage evidence. These literals are the kappa_m column of that fixture.
  #
  # This is the "no shortfall" branch of § M92's pre-registered consequence: every
  # cell cleared its 0.93 floor under the SHIPPED linear-in-S rule, so the
  # bracket-max rule is NOT adopted and the lookup is unchanged. A future shortfall
  # at some other geometry would flip that; this test pins what was actually
  # validated, not the rule in the abstract.
  #
  # The per-cell coverage figures live in the fixture and in § M92 of the note.
  # kappa_m is safe to pin because it is table-derived and does not move when the
  # sweep is re-run -- which is exactly why it, and not a coverage figure, is what a
  # test may pin.
  expect_equal(
    mpl_kappa_lookup(3L, 25L, conf_level = 0.95),
    0.7089067,
    tolerance = 1e-6
  )
  expect_equal(
    mpl_kappa_lookup(10L, 40L, conf_level = 0.95),
    0.1517143,
    tolerance = 1e-6
  )
  expect_equal(
    mpl_kappa_lookup(2L, 40L, conf_level = 0.95),
    1.3663359,
    tolerance = 1e-6
  )

  # Each is genuinely the interpolated chord, not a node value -- if any of these
  # S became a grid node the cells would stop probing interpolation at all, which
  # is exactly the gap M92 exists to close (M91 finding F1).
  s_nodes <- sort(unique(kappa_m_table$n_s))
  expect_false(any(c(25L, 40L) %in% s_nodes))

  # A NON-midpoint geometry, because all three swept S above are exact bracket
  # midpoints (25 = mid(20,30); 40 = mid(30,50)) and so equal the MEAN of their
  # bracketing nodes. Pinning midpoints alone cannot tell linear interpolation from
  # any bracket-symmetric rule: swapping stats::approx for mean(bracket) would leave
  # every literal above green while changing every non-midpoint production lookup
  # (M92 review finding F5, scored 62). S = 22 sits 1/5 of the way across the 20->30
  # bracket, so the two rules separate by ~0.046 here.
  slice95 <- kappa_m_table[abs(kappa_m_table$conf_level - 0.95) < 1e-8, ]
  n20 <- slice95$kappa_m[slice95$n_r == 3L & slice95$n_s == 20L]
  n30 <- slice95$kappa_m[slice95$n_r == 3L & slice95$n_s == 30L]
  expect_equal(
    mpl_kappa_lookup(3L, 22L, conf_level = 0.95),
    0.6624794,
    tolerance = 1e-6
  )
  expect_equal(
    mpl_kappa_lookup(3L, 22L, conf_level = 0.95),
    n20 + (22 - 20) / (30 - 20) * (n30 - n20),
    tolerance = 1e-12
  )
  expect_false(isTRUE(all.equal(
    mpl_kappa_lookup(3L, 22L, conf_level = 0.95),
    mean(c(n20, n30))
  )))
})

test_that("the shipped kappa_m table matches its whole-table fixture, every cell (M95 AC2)", {
  # GP7. Whole-table pin: any change to ANY cell of the shipped kappa_m_table --
  # a perturbed value, an added node, a dropped node, at any level -- must red
  # this test, so the table every MPL coverage claim rests on cannot silently
  # detach from its calibration runs. The table's CONTENTS are owned by
  # D-015/D-017: a legitimate change goes through recalibration, then the
  # fixture is regenerated (data-raw/m95-kappa-fixture.R). The spot pins above
  # leave most cells un-literal -- M92's pass-6 mutation (finding P6-1)
  # perturbed the 152 unpinned cells by +0.5 and this file stayed green
  # (FAIL 0 / PASS 172); this test closes that gap. The fixture is generated
  # from the COMMITTED CALIBRATION fixtures, never from R/sysdata.rda, so
  # agreement here ties the shipped table to the calibration evidence rather
  # than to a copy of the thing it checks.
  fixture <- utils::read.table(
    test_path("fixtures", "kappa-m-table.txt"),
    header = TRUE,
    sep = "\t",
    comment.char = "#",
    colClasses = c("integer", "integer", "numeric", "character", "character")
  )
  # The kappa_m column is a C99 hex float: the double's bits verbatim, immune
  # to the 1-ulp decimal-parse drift the generator measured under %.17g.
  fixture$kappa_m <- as.numeric(fixture$kappa_m)

  shipped <- kappa_m_table[
    order(kappa_m_table$conf_level, kappa_m_table$n_r, kappa_m_table$n_s),
  ]
  rownames(shipped) <- NULL

  # Key set, compared as sets: an added or dropped (n_r, n_s, conf_level) node
  # fails as loudly as a changed value.
  key <- function(d) sort(sprintf("%d|%d|%.2f", d$n_r, d$n_s, d$conf_level))
  expect_identical(key(shipped), key(fixture))

  # Values: identical(), never a tolerance, with both sides in the fixture's
  # own (conf_level, n_r, n_s) order.
  expect_identical(shipped$n_r, fixture$n_r)
  expect_identical(shipped$n_s, fixture$n_s)
  expect_identical(shipped$conf_level, fixture$conf_level)
  expect_identical(shipped$kappa_m, fixture$kappa_m)
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

# ---- M99: a boundary endpoint is evidence-based; a root failure aborts -------
# Boundary vs failure (M99 AC1/AC2, D-019). A sanity guard aborts when the
# deviance reference is degenerate at rho_hat (reachable with real data:
# perfect rater agreement / near-zero error MS -- tested below, no mock).
# Past the guard, a side has a deviance crossing iff f at its outer bracket
# edge is >= 0 (or non-finite); only the no-crossing case may return the
# boundary endpoint, and a crossing-indicated root-finding failure aborts
# classed instead of silently reporting 0/1. Past the guard that failure
# branch needs the mocked seam (mpl_uniroot): a sane finite bracket cannot
# make uniroot error with real data.

test_that("mpl boundary endpoints come from the sign test, not a swallowed error (M99)", {
  # Near-zero-rho boundary cell: the profile deviance at eps never reaches the
  # critical value (no crossing), so lower = 0 IS the limit and must be returned
  # by the explicit no-crossing branch, on both the two-sided and one-sided paths.
  d <- mpl_twoway_long(
    n_s = 20,
    n_r = 3,
    s2s = 1e-4,
    s2r = 0.3,
    s2e = 0.6,
    seed = 7
  )
  ms <- mpl_anova(mpl_matrix(d))
  ci <- mpl_interval(ms, kappa = 0.5, alpha = 0.05, side = "two")
  expect_identical(ci[["lower"]], 0)
  expect_gt(ci[["upper"]], 0)
  expect_lte(ci[["upper"]], 1)
  # One-sided path, with root-finding mocked to fail: lower = 0 must still be
  # returned, proving the no-crossing short-circuit precedes the seam (the
  # one-sided call computes no upper limit, so the mock must never fire).
  local_mocked_bindings(
    mpl_uniroot = function(...) stop("must not be called")
  )
  lo <- mpl_interval(ms, kappa = 0.5, alpha = 0.025, side = "lower")
  expect_identical(lo[["lower"]], 0)
})

test_that("a crossing-indicated root-finding failure aborts classed, per side (M99)", {
  # Interior data: both sides have deviance crossings, so a root-finding failure
  # here is a genuine numerical failure. Force one through the seam per side;
  # the result must be the classed abort with the MPL-specific message, never a
  # fabricated boundary endpoint.
  d <- mpl_twoway_long()
  ms <- mpl_anova(mpl_matrix(d))
  # Lower side: unconditional failure trips on the first (lower) root call.
  local_mocked_bindings(
    mpl_uniroot = function(...) stop("synthetic root failure")
  )
  expect_error(
    mpl_interval(ms, kappa = 0.3, alpha = 0.05, side = "two"),
    regexp = "lower limit could not be located",
    class = "intraclass_engine_error"
  )
  expect_error(
    mpl_interval(ms, kappa = 0.3, alpha = 0.05, side = "lower"),
    class = "intraclass_engine_error"
  )
  # Upper side: a side-aware mock returns a real root for the lower bracket
  # (its interval ends at rho_hat < 1 - eps) and fails only on the upper one,
  # so execution reaches side_root(1 - eps, ...) and its "upper" label.
  local_mocked_bindings(
    mpl_uniroot = function(f, interval) {
      if (interval[2] > 0.99) {
        stop("synthetic upper root failure")
      }
      stats::uniroot(f, interval, tol = 1e-10)$root
    }
  )
  expect_error(
    mpl_interval(ms, kappa = 0.3, alpha = 0.05, side = "two"),
    regexp = "upper limit could not be located",
    class = "intraclass_engine_error"
  )
})

test_that("a degenerate fit aborts with a fit diagnosis, without any mock (M99)", {
  # Perfect rater agreement: every rater gives the subject's own score, so the
  # error MS is ~0, the likelihood is unbounded, and mpl_fit()'s joint minimum
  # disagrees with the profile -- f(rho_hat) >> 0, the broken-reference state
  # the sanity guard exists to catch (review finding F1/F2: pre-M99 this
  # returned the vacuous fabricated interval [0, 1]).
  y <- matrix(rep(seq_len(20), times = 3), nrow = 20, ncol = 3)
  ms <- mpl_anova(y)
  expect_error(
    mpl_interval(ms, kappa = 0.6, alpha = 0.05, side = "two"),
    regexp = "degenerate at its own maximum-likelihood estimate",
    class = "intraclass_engine_error"
  )
})
