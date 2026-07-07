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
