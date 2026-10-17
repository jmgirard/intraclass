# parameters::model_parameters() on icc() results (D-051) ----------------------
#
# The method is registered lazily (R/zzz.R), so every block needs parameters
# installed. The table is tidy() under easystats column names: the tests read
# each column back against its tidy() source rather than against fixed numbers,
# because the numbers themselves are pinned by the icc() oracle tests.

mp_fits <- function() {
  list(
    twoway = icc(ratings, score, subject, rater, mc_samples = 500L, seed = 1),
    oneway = icc(
      ratings,
      score,
      subject,
      rater,
      model = "oneway",
      mc_samples = 500L,
      seed = 1
    ),
    multilevel = icc(
      school,
      score,
      pupil,
      rater,
      cluster = classroom,
      mc_samples = 500L,
      seed = 1
    ),
    replicates = icc(
      ratings_replicates,
      score,
      subject,
      rater,
      mc_samples = 500L,
      seed = 1
    )
  )
}

mp_columns <- c(
  "Parameter",
  "Type",
  "Level",
  "Occasions",
  "SF_Index",
  "Coefficient",
  "SE",
  "CI",
  "CI_low",
  "CI_high",
  "Method"
)

test_that("model_parameters() returns a parameters table with the easystats columns", {
  skip_if_not_installed("parameters")
  for (nm in names(fits <- mp_fits())) {
    x <- fits[[nm]]
    mp <- parameters::model_parameters(x)
    expect_identical(
      class(mp)[1:2],
      c("parameters_model", "see_parameters_model"),
      label = nm
    )
    expect_s3_class(mp, "data.frame")
    expect_setequal(names(mp), mp_columns)
    expect_identical(names(mp)[1], "Parameter", label = nm)
    expect_identical(nrow(mp), nrow(tidy(x)), label = nm)
  }
})

test_that("each model_parameters() column is its tidy() source column", {
  skip_if_not_installed("parameters")
  source_of <- c(
    Parameter = "term",
    Type = "type",
    Level = "level",
    Occasions = "occasions",
    SF_Index = "sf_index",
    Coefficient = "estimate",
    SE = "std.error",
    CI = "conf.level",
    CI_low = "conf.low",
    CI_high = "conf.high",
    Method = "method"
  )
  for (nm in names(fits <- mp_fits())) {
    x <- fits[[nm]]
    mp <- parameters::model_parameters(x)
    td <- tidy(x)
    for (col in names(source_of)) {
      expect_identical(
        mp[[col]],
        td[[source_of[[col]]]],
        label = paste(nm, col)
      )
    }
  }
})

test_that("the printed table carries an ICC title, not the Fixed Effects heading", {
  skip_if_not_installed("parameters")
  x <- mp_fits()$twoway
  out <- paste(
    utils::capture.output(print(parameters::model_parameters(x))),
    collapse = "\n"
  )
  expect_match(out, "Intraclass correlation coefficients", fixed = TRUE)
  expect_no_match(out, "Fixed Effects", fixed = TRUE)
})

test_that("a ci other than the fitted level aborts; the fitted level passes through", {
  skip_if_not_installed("parameters")
  x <- mp_fits()$twoway
  cnd <- expect_error(
    parameters::model_parameters(x, ci = 0.90),
    class = "intraclass_error",
    regexp = "conf_level"
  )
  # Which failure: the level refusal, not an error from inside parameters.
  expect_s3_class(cnd, "intraclass_ci_level")
  expect_identical(
    parameters::model_parameters(x, ci = 0.95),
    parameters::model_parameters(x)
  )
})
