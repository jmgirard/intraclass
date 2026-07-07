# S3 method contracts ----------------------------------------------------------

test_that("glance() reports one row of design and component summaries", {
  skip_if_not_installed("glmmTMB")

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  g <- glance(fit)

  expect_s3_class(g, "tbl_df")
  expect_identical(nrow(g), 1L)
  expect_contains(
    names(g),
    c(
      "n_subjects",
      "n_raters",
      "n_obs",
      "var_subject",
      "var_rater",
      "var_residual",
      "engine",
      "ci_method",
      "conf.level"
    )
  )
  expect_identical(g$n_subjects, 6L)
  expect_identical(g$n_raters, 4L)
  expect_identical(g$n_obs, 24L)
  expect_identical(g$engine, "glmmTMB")
})

test_that("format() returns character lines and print() returns invisibly", {
  skip_if_not_installed("glmmTMB")

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  lines <- format(fit)
  expect_type(lines, "character")
  expect_true(any(grepl("absolute agreement", lines)))
  expect_true(any(grepl("ICC(A,1)", lines, fixed = TRUE)))

  expect_invisible(print(fit))
})

test_that("summary() prints the report plus interpretive notes", {
  skip_if_not_installed("glmmTMB")

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  expect_snapshot(summary(fit), transform = mask_ci)
})
