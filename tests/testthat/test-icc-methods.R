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

# M43/ADR-053 number-invariance oracle: the cli restyle changes only presentation,
# so every value the printed report shows must equal the object's tidy()/glance()
# value at the displayed precision. Compares print vs tidy on the SAME fit, so it
# is robust to cross-platform MC-CI jitter (both read fit$estimates).
test_that("printed numbers equal tidy()/glance() to displayed precision (M43)", {
  skip_if_not_installed("glmmTMB")
  d3 <- function(v) formatC(v, format = "f", digits = 3)

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  lines <- cli::ansi_strip(format(fit)) # defensive: no ANSI in the comparison
  td <- tidy(fit)
  for (i in seq_len(nrow(td))) {
    # the coefficient's data row is the one carrying its label AND a "[" CI (the
    # Shrout & Fleiss note also names the label but has no bracket).
    row <- lines[
      grepl(td$index[i], lines, fixed = TRUE) &
        grepl("[", lines, fixed = TRUE)
    ]
    expect_length(row, 1L)
    expect_true(grepl(d3(td$estimate[i]), row, fixed = TRUE))
    expect_true(grepl(
      sprintf("[%s, %s]", d3(td$conf.low[i]), d3(td$conf.high[i])),
      row,
      fixed = TRUE
    ))
  }

  g <- glance(fit)
  comp_line <- lines[grepl("Variance components:", lines, fixed = TRUE)]
  expect_length(comp_line, 1L)
  for (v in c(g$var_subject, g$var_rater, g$var_residual)) {
    expect_true(grepl(d3(v), comp_line, fixed = TRUE))
  }

  # The k_eff projection note (incomplete data) shows glance()'s k_eff at 2 dp.
  inc <- icc(ratings_incomplete, score, subject, rater, seed = 1)
  inc_lines <- cli::ansi_strip(format(inc))
  keff_line <- inc_lines[grepl("effective", inc_lines, fixed = TRUE)]
  expect_length(keff_line, 1L)
  expect_true(grepl(
    formatC(glance(inc)$k_eff, format = "f", digits = 2),
    keff_line,
    fixed = TRUE
  ))
})
