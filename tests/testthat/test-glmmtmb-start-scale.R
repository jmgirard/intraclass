# glmmTMB starting values on large-scale scores --------------------------------
#
# glmmTMB starts every log-SD at 0 (an SD of 1). On scores whose spread is far
# from 1 -- e.g. heartbeat intervals in milliseconds -- the default start can
# leave the optimizer at a false optimum with a subject variance of 0, which
# icc() then printed as ICC 0.000 [0.000, 0.000]. Two oracles pin the fix:
# an ICC is unchanged when every score is multiplied by a constant, so a fit on
# `score * 100` must match the fit on `score`; and the lme4 engine (a different
# optimizer) must reach the same REML estimate.

scale_two_way <- function(seed = 11L, n_s = 17L, n_r = 2L) {
  set.seed(seed)
  grid <- expand.grid(
    subject = factor(seq_len(n_s)),
    rater = factor(letters[seq_len(n_r)])
  )
  subj <- stats::rnorm(n_s, 0, 0.65)
  rater <- seq(-0.3, 0.3, length.out = n_r)
  grid$score <- 6 + subj[as.integer(grid$subject)] +
    rater[as.integer(grid$rater)] + stats::rnorm(nrow(grid), 0, 0.9)
  grid
}

scale_multilevel <- function(seed = 13L, n_c = 6L, n_s = 5L, n_r = 3L) {
  set.seed(seed)
  grid <- expand.grid(
    s = seq_len(n_s),
    cluster = factor(seq_len(n_c)),
    rater = factor(letters[seq_len(n_r)])
  )
  grid$subject <- factor(paste(grid$cluster, grid$s, sep = "_"))
  clus <- stats::rnorm(n_c, 0, 0.6)
  subj <- stats::rnorm(nlevels(grid$subject), 0, 0.6)
  grid$score <- 6 + clus[as.integer(grid$cluster)] +
    subj[as.integer(grid$subject)] + stats::rnorm(nrow(grid), 0, 0.8)
  grid
}

icc_quiet <- function(...) {
  suppressMessages(suppressWarnings(icc(..., seed = 1)))
}

estimates <- function(x) stats::setNames(x$estimates$estimate, x$estimates$index)

test_that("two-way random glmmTMB ICCs do not depend on the score scale", {
  skip_if_not_installed("glmmTMB")
  d <- scale_two_way()
  big <- transform(d, score = score * 100)

  small_fit <- icc_quiet(d, score, subject = subject, rater = rater)
  big_fit <- icc_quiet(big, score, subject = subject, rater = rater)

  # The false optimum put the subject variance at 0; the true one does not.
  expect_gt(big_fit$components$subject, 1)
  expect_equal(estimates(big_fit), estimates(small_fit), tolerance = 1e-4)
  expect_equal(
    big_fit$components$subject,
    small_fit$components$subject * 100^2,
    tolerance = 1e-4
  )
})

test_that("two-way random glmmTMB matches lme4's REML fit on large-scale scores", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  big <- transform(scale_two_way(), score = score * 100)

  ref <- lme4::lmer(score ~ 1 + (1 | subject) + (1 | rater), data = big, REML = TRUE)
  ref_subject <- as.data.frame(lme4::VarCorr(ref))$vcov[
    as.data.frame(lme4::VarCorr(ref))$grp == "subject"
  ]

  fit <- icc_quiet(big, score, subject = subject, rater = rater)
  expect_equal(fit$components$subject, ref_subject, tolerance = 1e-4)
})

test_that("fixed-rater and one-way glmmTMB ICCs do not depend on the score scale", {
  skip_if_not_installed("glmmTMB")
  d <- scale_two_way()
  big <- transform(d, score = score * 100)

  for (args in list(list(raters = "fixed"), list(model = "oneway"))) {
    small_fit <- do.call(
      icc_quiet,
      c(list(d, quote(score), subject = quote(subject), rater = quote(rater)), args)
    )
    big_fit <- do.call(
      icc_quiet,
      c(list(big, quote(score), subject = quote(subject), rater = quote(rater)), args)
    )
    expect_gt(big_fit$components$subject, 1)
    expect_equal(estimates(big_fit), estimates(small_fit), tolerance = 1e-4)
  }
})

test_that("multilevel glmmTMB ICCs do not depend on the score scale", {
  skip_if_not_installed("glmmTMB")
  d <- scale_multilevel()
  big <- transform(d, score = score * 100)

  small_fit <- icc_quiet(
    d, score, subject = subject, rater = rater, cluster = cluster,
    level = c("subject", "cluster")
  )
  big_fit <- icc_quiet(
    big, score, subject = subject, rater = rater, cluster = cluster,
    level = c("subject", "cluster")
  )
  # The rater variance sits near 0 here, a flat direction of the likelihood, so
  # the two optimizer runs stop slightly apart: looser tolerance than above.
  expect_gt(big_fit$components$subject, 1)
  expect_equal(estimates(big_fit), estimates(small_fit), tolerance = 1e-3)
})
