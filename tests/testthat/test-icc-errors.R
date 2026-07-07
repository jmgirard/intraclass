# Error paths — fail loudly on ill-posed or unsupported requests (#5, #8) -------

test_that("options that are valid but not yet implemented abort with a pointer", {
  d <- sf_ratings_long()

  expect_error(
    icc(d, score, subject, rater, model = "oneway"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, engine = "lme4"),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(d, score, subject, rater, ci_method = "delta"),
    class = "intraclass_unsupported"
  )
})

test_that("ill-posed designs abort as unidentified", {
  d <- sf_ratings_long()

  one_rater <- d[d$rater == "J1", ]
  expect_error(
    icc(one_rater, score, subject, rater),
    class = "intraclass_unidentified"
  )

  one_subject <- d[d$subject == "S1", ]
  expect_error(
    icc(one_subject, score, subject, rater),
    class = "intraclass_unidentified"
  )
})

test_that("malformed input aborts with a classed intraclass error", {
  d <- sf_ratings_long()

  expect_error(
    icc("not a data frame", score, subject, rater),
    class = "intraclass_error"
  )

  d_chr <- d
  d_chr$score <- as.character(d_chr$score)
  expect_error(
    icc(d_chr, score, subject, rater),
    class = "intraclass_error"
  )

  expect_error(
    icc(d, score, subject, rater, conf_level = 1.5),
    class = "intraclass_error"
  )
})

test_that("invalid choices for supported dimensions abort as classed errors", {
  d <- sf_ratings_long()

  expect_error(
    icc(d, score, subject, rater, type = "bogus"),
    class = "intraclass_error"
  )
  expect_error(
    icc(d, score, subject, rater, raters = "bogus"),
    class = "intraclass_error"
  )
})

test_that("error messages are stable and actionable", {
  d <- sf_ratings_long()
  expect_snapshot(
    icc(d, score, subject, rater, model = "oneway"),
    error = TRUE
  )
  expect_snapshot(
    icc(d[d$rater == "J1", ], score, subject, rater),
    error = TRUE
  )
})
