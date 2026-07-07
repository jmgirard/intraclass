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

test_that("lavaan is refused for fixed, one-way, multilevel, and incomplete designs", {
  skip_if_not_installed("lavaan")

  d <- sf_ratings_long()
  expect_error(
    icc(d, score, subject, rater, raters = "fixed", engine = "lavaan"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, model = "oneway", engine = "lavaan"),
    class = "intraclass_unsupported"
  )

  # Incomplete: drop one cell so the design is unbalanced.
  di <- d[-1, ]
  expect_error(
    icc(di, score, subject, rater, engine = "lavaan"),
    class = "intraclass_unsupported"
  )

  ml <- expand.grid(
    subject = factor(1:4),
    rater = factor(1:3),
    cluster = factor(1:2)
  )
  ml$score <- as.numeric(ml$subject) + as.numeric(ml$rater) + rnorm(nrow(ml))
  expect_error(
    icc(ml, score, subject, rater, cluster = cluster, engine = "lavaan"),
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
