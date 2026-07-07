# Real fixed-effect fit path -- two-way mixed, Case 3 / 3A (M3 Slice 2) ----------
#
# raters = "fixed" is fit separately: score ~ 1 + rater + (1 | subject), resolving
# the ADR-006 debt (on incomplete data the balanced label layer is invalid).
# Estimand + decisions: estimand-spec M3 §6, ADR-008. Oracle O6 provenance:
# data-raw/oracle-fixed-incomplete.R.

fixed_icc <- function(
  data,
  type = "agreement",
  unit = c("single", "average"),
  seed = NULL
) {
  suppressWarnings(icc(
    data,
    score,
    subject,
    rater,
    raters = "fixed",
    type = type,
    unit = unit,
    seed = seed
  ))
}

test_that("fixed fit reproduces the published SF values on balanced data (O6)", {
  skip_if_not_installed("glmmTMB")
  fa <- fixed_icc(sf_ratings_long(), "agreement")
  fc <- fixed_icc(sf_ratings_long(), "consistency")
  expect_equal(round(icc_estimate(fa, "ICC(A,1)"), 3), 0.290)
  expect_equal(round(icc_estimate(fa, "ICC(A,k)"), 3), 0.620)
  expect_equal(round(icc_estimate(fc, "ICC(C,1)"), 3), 0.715)
  expect_equal(round(icc_estimate(fc, "ICC(C,k)"), 3), 0.909)
  # Bias-corrected theta^2_r equals the random-fit sigma^2_r (5.2444): this is
  # why fixed == random on balanced data (ADR-008 extends O4).
  expect_equal(fa$components$rater, 5.24444, tolerance = 1e-3)
})

test_that("fixed fit matches an independent lme4 fixed fit on incomplete data (O6)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sf_ratings_long()
  inc <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2"),
  ]
  inc$subject <- droplevels(inc$subject)
  inc$rater <- droplevels(inc$rater)
  k <- nlevels(inc$rater)

  m <- lme4::lmer(score ~ 1 + rater + (1 | subject), data = inc, REML = TRUE)
  vc <- as.data.frame(lme4::VarCorr(m))
  s <- vc$vcov[vc$grp == "subject"][1]
  e <- vc$vcov[vc$grp == "Residual"][1]
  # theta^2_r from lme4 fixed effects via the same bias-corrected formula.
  contrast <- rater_mean_contrast(k)
  center <- diag(k) - matrix(1 / k, k, k)
  v_means <- contrast %*% as.matrix(stats::vcov(m)) %*% t(contrast)
  mu <- as.numeric(contrast %*% lme4::fixef(m))
  theta2 <- max(
    0,
    (as.numeric(t(mu) %*% center %*% mu) - sum(diag(center %*% v_means))) /
      (k - 1)
  )
  expect_equal(
    icc_estimate(fixed_icc(inc, "consistency"), "ICC(C,1)"),
    s / (s + e),
    tolerance = 1e-4
  )
  expect_equal(
    icc_estimate(fixed_icc(inc, "agreement"), "ICC(A,1)"),
    s / (s + e + theta2),
    tolerance = 1e-4
  )
})

test_that("fixed and random raters differ on incomplete data (ADR-006 debt closed)", {
  skip_if_not_installed("glmmTMB")
  d <- sf_ratings_long()
  # Drop 4 of 24 cells (still connected): the M2 spec §6 divergence example.
  inc <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2") &
      !(d$subject == "S3" & d$rater == "J3") &
      !(d$subject == "S4" & d$rater == "J4"),
  ]
  inc$subject <- droplevels(inc$subject)
  inc$rater <- droplevels(inc$rater)
  rnd <- icc(inc, score, subject, rater, type = "consistency")
  fix <- fixed_icc(inc, "consistency")
  # Random-rater partial pooling shifts sigma^2_s, so the ICCs genuinely differ
  # (a shared-fit label layer would give exactly equal values -- the old bug).
  expect_gt(
    abs(icc_estimate(rnd, "ICC(C,1)") - icc_estimate(fix, "ICC(C,1)")),
    1e-3
  )
})

test_that("the fixed estimator recovers known components with known rater effects (O6)", {
  # Single-seed recovery + interval coverage; the 300-rep coverage validation is
  # in data-raw/oracle-fixed-incomplete.R. #1, #3, #12.
  set.seed(4242)
  ns <- 80L
  k <- 12L
  s2s <- 4
  s2res <- 2
  alpha <- seq(-3, 3, length.out = k) # KNOWN fixed rater effects
  theta2_true <- sum((alpha - mean(alpha))^2) / (k - 1)
  pop_a1 <- s2s / (s2s + s2res + theta2_true)
  pop_c1 <- s2s / (s2s + s2res)
  subj <- rnorm(ns, 0, sqrt(s2s))
  grid <- expand.grid(subject = factor(seq_len(ns)), rater = factor(seq_len(k)))
  grid$score <- 10 +
    subj[as.integer(grid$subject)] +
    alpha[as.integer(grid$rater)] +
    rnorm(nrow(grid), 0, sqrt(s2res))
  sim <- grid[runif(nrow(grid)) > 0.20, ]
  sim$subject <- droplevels(sim$subject)
  sim$rater <- droplevels(sim$rater)

  ta <- generics::tidy(fixed_icc(sim, "agreement", unit = "single", seed = 5))
  tc <- generics::tidy(fixed_icc(sim, "consistency", unit = "single", seed = 5))
  # The calibrated property is interval COVERAGE -- validated at nominal 95% over
  # 300 reps in data-raw/oracle-fixed-incomplete.R. A single draw's point is noisy
  # (theta^2_r and sigma^2_s from finite raters/subjects), so it is only checked
  # to a sane band; exact point recovery is pinned by the balanced reduction and
  # the lme4 cross-check above.
  expect_gte(pop_a1, ta$conf.low)
  expect_lte(pop_a1, ta$conf.high)
  expect_gte(pop_c1, tc$conf.low)
  expect_lte(pop_c1, tc$conf.high)
  expect_lt(abs(ta$estimate - pop_a1), 0.10)
  expect_lt(abs(tc$estimate - pop_c1), 0.10)
})
