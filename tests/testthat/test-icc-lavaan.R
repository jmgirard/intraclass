# O-SEM — lavaan as a selectable SEM engine (M7 / ADR-014) --------------------
# lavaan fits the generalizability model as a common-factor SEM (Jorgensen 2021).
# Two oracle regimes, because absolute agreement is a DIFFERENT estimator than the
# mixed model (see below), while consistency is not:
#
#   * CONSISTENCY is a ratio sigma^2_s / (sigma^2_s + sigma^2_res), so lavaan must
#     equal glmmTMB exactly on balanced data (and reproduce the published SF
#     ICC(3,*) values). Pinned to ~1e-4.
#   * ABSOLUTE AGREEMENT recovers sigma^2_r from the mean structure as the raw
#     variance of the indicator intercepts, sigma^2_r = sum(nu^2)/(k-1) (Jorgensen
#     2021, Eq. 6; Vispoel, Hong, Lee & Xu 2022, Eq. 4). This is asymptotically
#     equivalent to the mixed-model random-effect variance but omits its
#     "- sigma^2_res / n" term, so on the 6-subject SF data it differs by a
#     small-sample amount (0.284 vs 0.290). It is oracled by (a) the EXACT Eq. 6
#     formula, (b) LARGE-N convergence to the population and to glmmTMB, not by the
#     mixed-model number. Vispoel et al. (2022) validate the estimator against
#     GENOVA/gtheory/SAS/SPSS on real data (agreement <= .005 on D-coefficients).

lavaan_axes <- list(
  c(type = "consistency", unit = "single"),
  c(type = "consistency", unit = "average")
)

test_that("lavaan consistency matches glmmTMB to 1e-4 (O-SEM consistency)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sf_ratings_long()
  for (ax in lavaan_axes) {
    g <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "glmmTMB",
      seed = 1
    ))
    l <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = ax[["type"]],
      unit = ax[["unit"]],
      engine = "lavaan",
      seed = 1
    ))
    expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
  }
})

test_that("lavaan reproduces the published Shrout & Fleiss consistency values", {
  skip_if_not_installed("lavaan")

  d <- sf_ratings_long()
  c1 <- tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = "single",
    engine = "lavaan",
    seed = 1
  ))
  ck <- tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = "average",
    engine = "lavaan",
    seed = 1
  ))
  expect_equal(
    c1$estimate[c1$index == "ICC(C,1)"],
    sf_oracle_all[["ICC(C,1)"]],
    tolerance = 1e-3
  )
  expect_equal(
    ck$estimate[ck$index == "ICC(C,k)"],
    sf_oracle_all[["ICC(C,k)"]],
    tolerance = 1e-3
  )
})

test_that("lavaan agreement implements Jorgensen (2021) Eq. 6 exactly", {
  skip_if_not_installed("lavaan")

  # The rater variance component must equal the RAW variance of the k rater means,
  # sum((mean_j - grand)^2) / (k - 1), computed independently from the data (no
  # bias correction -- Jorgensen 2021 Eq. 6; Vispoel et al. 2022 Eq. 4).
  d <- sf_ratings_long()
  fit <- icc(d, score, subject, rater, engine = "lavaan", seed = 1)
  k <- fit$n$raters
  rmeans <- tapply(d$score, d$rater, mean)
  sigma2_r <- sum((rmeans - mean(rmeans))^2) / (k - 1)
  expect_equal(fit$components$rater, as.numeric(sigma2_r), tolerance = 1e-6)

  # The resulting SF-data agreement coefficients are the SEM estimator's values
  # (0.284 / 0.614), NOT the mixed-model 0.290 / 0.620 -- a documented small-sample
  # difference (regression pin so it cannot drift).
  a <- tidy(icc(
    d,
    score,
    subject,
    rater,
    unit = c("single", "average"),
    engine = "lavaan",
    seed = 1
  ))
  expect_equal(a$estimate[a$index == "ICC(A,1)"], 0.2843, tolerance = 1e-3)
  expect_equal(a$estimate[a$index == "ICC(A,k)"], 0.6137, tolerance = 1e-3)
})

test_that("lavaan agreement converges to glmmTMB and the population at large N", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # The SEM indicator-mean estimator and the mixed-model random-effect estimator
  # are asymptotically equivalent (Vispoel et al. 2022). With many subjects the
  # small-sample gap vanishes: lavaan ~= glmmTMB ~= the known population ICC.
  set.seed(2024)
  n <- 250L
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

  lav <- tidy(icc(grid, score, subject, rater, engine = "lavaan", seed = 1))
  tmb <- tidy(icc(grid, score, subject, rater, engine = "glmmTMB", seed = 1))
  pop_a1 <- v_s / (v_s + v_r + v_res)

  la1 <- lav$estimate[lav$index == "ICC(A,1)"]
  ta1 <- tmb$estimate[tmb$index == "ICC(A,1)"]
  expect_equal(la1, ta1, tolerance = 0.02) # engines agree at large N
  expect_equal(la1, pop_a1, tolerance = 0.05) # and recover the population
})

test_that("lavaan Monte-Carlo interval matches glmmTMB (O-SEM interval)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # Consistency: lavaan CI ~= glmmTMB RANDOM CI (same ratio estimand). Agreement:
  # lavaan CI ~= glmmTMB FIXED CI, because the SEM recovers the rater effect from a
  # finite set of intercepts (Case 3A inference), not a random-effect variance.
  # Absolute gap, not relative (M5.5 Windows lesson).
  d <- sf_ratings_long()
  for (u in c("single", "average")) {
    lc <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "consistency",
      unit = u,
      engine = "lavaan",
      seed = 1,
      mc_samples = 20000L
    ))
    gc <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "consistency",
      unit = u,
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    ))
    expect_lt(max(abs(lc$conf.low - gc$conf.low)), 0.02)
    expect_lt(max(abs(lc$conf.high - gc$conf.high)), 0.02)

    la <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      engine = "lavaan",
      seed = 1,
      mc_samples = 20000L
    ))
    gf <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      raters = "fixed",
      engine = "glmmTMB",
      seed = 1,
      mc_samples = 20000L
    )))
    expect_lt(max(abs(la$conf.low - gf$conf.low)), 0.02)
    expect_lt(max(abs(la$conf.high - gf$conf.high)), 0.02)
  }
})

test_that("lavaan interval is finite and inside [0, 1]", {
  skip_if_not_installed("lavaan")

  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    engine = "lavaan",
    seed = 1
  )
  ci <- fit$estimates
  expect_true(all(is.finite(ci$conf.low) & is.finite(ci$conf.high)))
  expect_true(all(ci$conf.low >= 0 & ci$conf.high <= 1))
})

test_that("lavaan aborts loudly on a degenerate (boundary) fit (#5/#8)", {
  skip_if_not_installed("lavaan")

  # Perfectly correlated raters (every rater gives each subject the same score)
  # give a non-positive-definite sample covariance, which lavaan cannot fit. The
  # failure is converted to a classed intraclass condition pointing at glmmTMB,
  # rather than lavaan's raw un-classed error (#8).
  d <- data.frame(
    subject = factor(rep(1:6, 4)),
    rater = factor(rep(1:4, each = 6)),
    score = rep(c(3, 5, 7, 2, 9, 4), 4)
  )
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      engine = "lavaan",
      seed = 1
    )),
    class = "intraclass_singular_fit"
  )
})

test_that("lavaan is refused for one-way designs", {
  skip_if_not_installed("lavaan")

  # (Fixed raters and incomplete/FIML data are now supported -- M21 Slices
  # 2/3 -- and the crossed multilevel design since M54; its scope guards are
  # pinned in test-icc-lavaan-multilevel.R. One-way stays out, ADR-014.)
  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, model = "oneway", engine = "lavaan"),
    class = "intraclass_unsupported"
  )
})

test_that("the icc object reports the lavaan engine", {
  skip_if_not_installed("lavaan")

  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    engine = "lavaan",
    seed = 1
  )
  expect_equal(fit$engine, "lavaan")
  expect_equal(glance(fit)$engine, "lavaan")
})

test_that("lavaan print() output is stable", {
  skip_if_not_installed("lavaan")

  # As with the glmmTMB/lme4 print snapshots, the CI digits are masked (they vary
  # at ~1e-3 across platforms even when seeded); the engine line and point
  # estimates are checked verbatim.
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    seed = 1,
    engine = "lavaan"
  )
  expect_snapshot(print(fit), transform = mask_ci)
})

# O-FSEM -- fixed-rater SEM (M21 Slice 2, ADR-031) -----------------------------
# Oracle-first catch (ADR-031): M7's RANDOM agreement estimator already reads the
# rater variance from a finite set of indicator intercepts (raw = sum(nu^2)/(k-1)),
# so does fixed-rater SEM agreement coincide with it, or need a distinct theta^2_r?
# Resolved by oracle: fixed raters take the McGraw & Wong Case-3A bias-corrected
# finite-population theta^2_r = max(0, raw - bias) -- a DISTINCT estimator (raw minus
# the mean sampling variance of the intercepts). On balanced data it equals BOTH
# glmmTMB's Case-3A fixed theta^2_r AND its random sigma^2_r (the M10 balanced
# fixed==random identity), so lavaan's fixed agreement recovers the mixed-model value
# the raw estimator (0.284 on SF) does not. Consistency omits the rater term, so it is
# identical to the random case.

test_that("fixed-rater SEM agreement is the Case-3A theta^2_r, distinct from raw", {
  skip_if_not_installed("lavaan")

  d <- sf_ratings_long()
  raw <- icc(
    d,
    score,
    subject,
    rater,
    raters = "random",
    engine = "lavaan",
    seed = 1
  )
  fix <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "lavaan",
    seed = 1
  ))

  # The fixed rater component is the raw one minus a positive bias (Case-3A
  # correction), so it is strictly smaller -- NOT a relabel of the raw estimator.
  expect_lt(fix$components$rater, raw$components$rater)
  expect_gt(fix$components$rater, 0)

  # Hence a HIGHER agreement ICC than the raw random-SEM value (smaller sigma^2_r).
  fa <- tidy(fix)
  ra <- tidy(raw)
  expect_gt(
    fa$estimate[fa$index == "ICC(A,1)"],
    ra$estimate[ra$index == "ICC(A,1)"]
  )
})

test_that("balanced fixed-rater SEM reduces to glmmTMB fixed AND random (O-FSEM)", {
  skip_if_not_installed("lavaan")
  skip_if_not_installed("glmmTMB")

  # Primary oracle: on balanced data the SEM Case-3A theta^2_r equals both the mixed
  # model's fixed theta^2_r (Case 3A) and its random sigma^2_r (M10 identity). Small
  # SF data -> a small-sample gap between the SEM observed-information bias and the
  # REML bias, so a modest tolerance; large N tightens it below.
  d <- sf_ratings_long()
  for (u in c("single", "average")) {
    lav <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      raters = "fixed",
      engine = "lavaan",
      seed = 1
    )))
    gf <- suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      raters = "fixed",
      engine = "glmmTMB",
      seed = 1
    )))
    gr <- tidy(icc(
      d,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      raters = "random",
      engine = "glmmTMB",
      seed = 1
    ))
    idx <- if (u == "single") "ICC(A,1)" else "ICC(A,k)"
    # SF is tiny (6 subjects), so the SEM observed-information bias and the REML bias
    # leave a documented ~1e-3 absolute gap (relative ~4e-3); the large-N test below
    # is the tight (1e-3) convergence pin. Honest small-sample tolerance, not tuned.
    expect_equal(
      lav$estimate[lav$index == idx],
      gf$estimate[gf$index == idx],
      tolerance = 1e-2
    )
    expect_equal(
      lav$estimate[lav$index == idx],
      gr$estimate[gr$index == idx],
      tolerance = 1e-2
    )
  }
})

test_that("fixed-rater SEM converges to glmmTMB fixed at large N (O-FSEM)", {
  skip_if_not_installed("lavaan")
  skip_if_not_installed("glmmTMB")

  set.seed(214)
  n <- 120L
  k <- 6L
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  grid <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    rat[as.integer(grid$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))

  lav <- suppressWarnings(tidy(icc(
    grid,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "lavaan",
    seed = 1
  )))
  gf <- suppressWarnings(tidy(icc(
    grid,
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "glmmTMB",
    seed = 1
  )))
  # Bias -> 0 as the intercepts stabilise, so the estimators agree tightly.
  expect_equal(
    lav$estimate[lav$index == "ICC(A,1)"],
    gf$estimate[gf$index == "ICC(A,1)"],
    tolerance = 1e-3
  )
})

test_that("fixed-rater SEM consistency is identical to the random case", {
  skip_if_not_installed("lavaan")

  # Consistency drops the rater term from the error set, so the fixed/random choice
  # is a no-op: identical point AND interval (same fit, same estimand).
  d <- sf_ratings_long()
  fx <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    engine = "lavaan",
    seed = 1
  )))
  rn <- tidy(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "random",
    engine = "lavaan",
    seed = 1
  ))
  expect_equal(fx$estimate, rn$estimate, tolerance = 1e-10)
  expect_equal(fx$conf.low, rn$conf.low, tolerance = 1e-10)
  expect_equal(fx$conf.high, rn$conf.high, tolerance = 1e-10)
})

test_that("fixed-rater SEM interval is finite, in [0, 1], and brackets the estimate", {
  skip_if_not_installed("lavaan")

  fit <- suppressWarnings(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    raters = "fixed",
    engine = "lavaan",
    seed = 1
  ))
  ci <- fit$estimates
  expect_true(all(is.finite(ci$conf.low) & is.finite(ci$conf.high)))
  expect_true(all(ci$conf.low >= 0 & ci$conf.high <= 1))
  expect_true(all(ci$conf.low <= ci$estimate & ci$estimate <= ci$conf.high))
})

test_that("fixed-rater SEM also serves the parametric bootstrap (Slice 1 x Slice 2)", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  set.seed(216)
  n <- 40L
  k <- 6L
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
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 99L, # structural serves-the-bootstrap check; B arbitrary (M78)
    seed = 1
  )))
  expect_true(all(is.finite(bs$conf.low) & is.finite(bs$conf.high)))
  expect_true(all(bs$conf.low <= bs$estimate & bs$estimate <= bs$conf.high))
  expect_true(all(bs$conf.high <= 1))
})

# O-FIML -- incomplete/ragged SEM via FIML (M21 Slice 3, ADR-031) ---------------
# On incomplete data lavaan estimates by full-information maximum likelihood
# (missing = "fiml"). Oracles (glmmTMB the independent engine, as M7; ADR-031
# attempt-then-degrade -> SHIPS, no degrade -- FIML pins on moderate ragged data):
#   * CONSISTENCY is an estimator-invariant ratio -> a tight cross-engine pin even
#     on ragged data (asymptotically exact; small N-vs-(N-1) residual only).
#   * AGREEMENT via the SEM indicator-mean estimator vs glmmTMB REML random differs
#     by the SAME small-sample bias as complete data (raw omits the "- res/n" term),
#     shrinking with n -- a looser but honest cross-engine pin, NOT a FIML artifact.
#   * The parametric bootstrap is gated on incomplete data (resamples cannot
#     reproduce the missingness pattern): ci_method = "bootstrap" aborts loudly.

# Deterministic connected ragged two-way design: a full n x k grid with a scattered
# subset of cells removed (every 8th), leaving every subject and rater present and the
# subject-by-rater graph connected.
ragged_twoway <- function(n = 50L, k = 6L, seed = 11L) {
  set.seed(seed)
  subj <- stats::rnorm(n, 0, 2)
  rat <- stats::rnorm(k, 0, 1)
  g <- expand.grid(subject = factor(seq_len(n)), rater = factor(seq_len(k)))
  g$score <- 10 +
    subj[as.integer(g$subject)] +
    rat[as.integer(g$rater)] +
    stats::rnorm(n * k, 0, sqrt(2))
  g[seq_len(nrow(g)) %% 8L != 0L, ]
}

test_that("incomplete lavaan fits via FIML and matches glmmTMB consistency (O-FIML)", {
  skip_if_not_installed("lavaan")
  skip_if_not_installed("glmmTMB")

  gg <- ragged_twoway()
  expect_false(nrow(gg) == nlevels(gg$subject) * nlevels(gg$rater)) # genuinely ragged
  for (u in c("single", "average")) {
    lav <- tidy(icc(
      gg,
      score,
      subject,
      rater,
      type = "consistency",
      unit = u,
      engine = "lavaan",
      seed = 1
    ))
    tmb <- tidy(icc(
      gg,
      score,
      subject,
      rater,
      type = "consistency",
      unit = u,
      engine = "glmmTMB",
      seed = 1
    ))
    idx <- if (u == "single") "ICC(C,1)" else "ICC(C,k)"
    expect_equal(
      lav$estimate[lav$index == idx],
      tmb$estimate[tmb$index == idx],
      tolerance = 8e-3
    )
  }
})

test_that("incomplete lavaan agreement matches glmmTMB via FIML (O-FIML)", {
  skip_if_not_installed("lavaan")
  skip_if_not_installed("glmmTMB")

  # The gap is the SEM raw-estimator small-sample bias (same kind as complete data),
  # shrinking with n -- an honest cross-engine tolerance, not tuned to pass (#1, #4).
  gg <- ragged_twoway()
  for (u in c("single", "average")) {
    lav <- tidy(icc(
      gg,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      engine = "lavaan",
      seed = 1
    ))
    tmb <- tidy(icc(
      gg,
      score,
      subject,
      rater,
      type = "agreement",
      unit = u,
      engine = "glmmTMB",
      seed = 1
    ))
    idx <- if (u == "single") "ICC(A,1)" else "ICC(A,k)"
    expect_equal(
      lav$estimate[lav$index == idx],
      tmb$estimate[tmb$index == idx],
      tolerance = 1.5e-2
    )
  }
})

test_that("incomplete lavaan recovers the population at large N (O-FIML)", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  v_s <- 4
  v_r <- 1
  v_res <- 2
  gg <- ragged_twoway(n = 300L, k = 6L, seed = 99L)
  # Rebuild scores with the known variance components (ragged_twoway used 2/1/2 with a
  # different seed); regenerate here so the population targets are exact.
  set.seed(99)
  n <- nlevels(gg$subject)
  k <- nlevels(gg$rater)
  subj <- stats::rnorm(n, 0, sqrt(v_s))
  rat <- stats::rnorm(k, 0, sqrt(v_r))
  gg$score <- 10 +
    subj[as.integer(gg$subject)] +
    rat[as.integer(gg$rater)] +
    stats::rnorm(nrow(gg), 0, sqrt(v_res))

  lav <- tidy(icc(
    gg,
    score,
    subject,
    rater,
    unit = "single",
    type = c("consistency"),
    engine = "lavaan",
    seed = 1
  ))
  pop_c1 <- v_s / (v_s + v_res)
  expect_equal(lav$estimate[lav$index == "ICC(C,1)"], pop_c1, tolerance = 0.05)
})

test_that("incomplete lavaan interval is finite, in [0, 1], and brackets the estimate", {
  skip_if_not_installed("lavaan")

  fit <- icc(
    ragged_twoway(),
    score,
    subject,
    rater,
    engine = "lavaan",
    seed = 1
  )
  ci <- fit$estimates
  expect_true(all(is.finite(ci$conf.low) & is.finite(ci$conf.high)))
  expect_true(all(ci$conf.low >= 0 & ci$conf.high <= 1))
  expect_true(all(ci$conf.low <= ci$estimate & ci$estimate <= ci$conf.high))
})

test_that("incomplete lavaan bootstrap aborts loudly (Monte-Carlo only)", {
  skip_if_not_installed("lavaan")

  # Parametric resamples from the implied moments cannot reproduce the missingness
  # pattern, so bootstrap is refused for incomplete SEM -> the bootstrap_ci NULL guard.
  expect_error(
    icc(
      ragged_twoway(),
      score,
      subject,
      rater,
      engine = "lavaan",
      ci_method = "bootstrap",
      boot_samples = 99L,
      seed = 1
    ),
    class = "intraclass_unsupported"
  )
})

test_that("a disconnected incomplete design still aborts for lavaan", {
  skip_if_not_installed("lavaan")

  # Two rater groups that never share a subject -> disconnected; the engine-agnostic
  # connectedness guard (M3) rejects it before any lavaan fit (#5).
  d <- data.frame(
    subject = factor(c(1, 1, 2, 2, 3, 3, 4, 4)),
    rater = factor(c(1, 2, 1, 2, 3, 4, 3, 4)),
    score = c(5, 6, 4, 5, 7, 8, 6, 7)
  )
  expect_error(
    icc(d, score, subject, rater, engine = "lavaan"),
    class = "intraclass_unidentified"
  )
})
