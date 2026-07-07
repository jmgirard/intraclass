# Vignette claims (choosing-an-icc.Rmd) -----------------------------------
# The flagship "Choosing an ICC" article makes comparative statements in prose
# ("consistency is never smaller than agreement", "ICC(*,k) is always the larger
# number", "on this balanced design the fixed and random point estimates
# coincide"). Those claims must hold numerically on the shipped `ratings`
# dataset the article uses, so no teaching statement is unbacked
# (PRINCIPLES.md #1). Point estimates are seed-independent (the seed only fixes
# the Monte-Carlo interval); a seed is set purely for determinism.

test_that("consistency is never smaller than agreement on `ratings`", {
  skip_if_not_installed("glmmTMB")

  agr <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  con <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))

  # Row 1 = single ICC(*,1), row 2 = average ICC(*,k).
  expect_lte(agr$estimate[1], con$estimate[1])
  expect_lte(agr$estimate[2], con$estimate[2])
})

test_that("the average coefficient is never smaller than the single", {
  skip_if_not_installed("glmmTMB")

  agr <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  con <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))

  expect_gte(agr$estimate[2], agr$estimate[1])
  expect_gte(con$estimate[2], con$estimate[1])
})

test_that("fixed and random point estimates coincide on balanced `ratings`", {
  skip_if_not_installed("glmmTMB")

  rnd <- tidy(icc(ratings, score, subject, rater, raters = "random", seed = 1))
  fix <- suppressWarnings(
    tidy(icc(ratings, score, subject, rater, raters = "fixed", seed = 1))
  )

  expect_equal(rnd$estimate, fix$estimate, tolerance = 1e-4)
})

# --- incomplete-design claims (section 4) --------------------------------

test_that("`ratings_incomplete` averages over a non-integer effective k", {
  skip_if_not_installed("glmmTMB")

  g <- glance(icc(ratings_incomplete, score, subject, rater, seed = 1))
  expect_false(g$balanced)
  # Harmonic mean of {4, 4, 3, 3, 3, 3} = 3.2727..., strictly between 3 and 4.
  expect_gt(g$k_eff, 3)
  expect_lt(g$k_eff, 4)
})

test_that("fixed and random diverge on incomplete data", {
  skip_if_not_installed("glmmTMB")

  rnd <- tidy(icc(
    ratings_incomplete,
    score,
    subject,
    rater,
    raters = "random",
    seed = 1
  ))
  fix <- suppressWarnings(tidy(icc(
    ratings_incomplete,
    score,
    subject,
    rater,
    raters = "fixed",
    seed = 1
  )))

  # Unlike the balanced case, the point estimates are no longer identical.
  expect_false(isTRUE(all.equal(rnd$estimate, fix$estimate, tolerance = 1e-4)))
})

# --- advanced-article D-study claims -------------------------------------

test_that("the D-study projection anchors to ICC(A,k) at m = n_raters", {
  skip_if_not_installed("glmmTMB")

  # The advanced article states Phi(m) at m = 4 (the raters in `ratings`) equals
  # the ICC(A,k) icc() reports directly. Point estimates are seed-independent.
  fit <- icc(ratings, score, subject, rater, seed = 1)
  proj <- d_study(fit, m = 1:8, seed = 1)

  at_k <- proj$estimate[proj$m == fit$n$raters]
  ick <- tidy(fit)$estimate[tidy(fit)$index == "ICC(A,k)"]
  expect_equal(at_k, ick, tolerance = 1e-8)

  # And the "diminishing returns" curve is monotone increasing.
  expect_true(all(diff(proj$estimate) > 0))
})

test_that("a disconnected design is rejected, not guessed at", {
  skip_if_not_installed("glmmTMB")

  disconnected <- data.frame(
    subject = factor(c(1, 1, 2, 2, 3, 3, 4, 4)),
    rater = factor(c(1, 2, 1, 2, 3, 4, 3, 4)),
    score = c(5, 6, 4, 5, 7, 8, 6, 7)
  )
  expect_error(
    icc(disconnected, score, subject, rater),
    class = "intraclass_unidentified"
  )
})
