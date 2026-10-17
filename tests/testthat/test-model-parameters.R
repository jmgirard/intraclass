# parameters::model_parameters() on icc() results (D-051) ----------------------
#
# The method is registered lazily (R/zzz.R), so every block needs parameters
# installed. The table is tidy() under easystats column names: the tests read
# each column back against its tidy() source rather than against fixed numbers,
# because the numbers themselves are pinned by the icc() oracle tests.

mp_twoway <- function() {
  icc(ratings, score, subject, rater, mc_samples = 500L, seed = 1)
}

mp_fits <- function() {
  list(
    twoway = mp_twoway(),
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

mp_printed <- function(x) {
  paste(
    utils::capture.output(print(parameters::model_parameters(x))),
    collapse = "\n"
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
  x <- mp_twoway()
  out <- mp_printed(x)
  expect_match(out, "Intraclass correlation coefficients", fixed = TRUE)
  expect_no_match(out, "Fixed Effects", fixed = TRUE)
})

test_that("the printed table hides all-NA columns and labels multilevel rows by level", {
  skip_if_not_installed("parameters")
  fits <- mp_fits()
  # Control: a column with values is shown. The two-way fit has a Type on
  # every row, so the word appears in the header.
  expect_match(mp_printed(fits$twoway), "Type", fixed = TRUE)
  # The one-way fit has Type, Level and Occasions all NA.
  oneway <- mp_printed(fits$oneway)
  expect_no_match(oneway, "Type", fixed = TRUE)
  expect_no_match(oneway, "Level", fixed = TRUE)
  expect_no_match(oneway, "Occasions", fixed = TRUE)
  # A multilevel fit: Parameter repeats across levels in the table, and the
  # printer moves Level into the label instead of a column.
  ml <- fits$multilevel
  expect_gt(anyDuplicated(parameters::model_parameters(ml)$Parameter), 0L)
  ml_out <- mp_printed(ml)
  expect_match(ml_out, "ICC(A,1) [subject]", fixed = TRUE)
  expect_match(ml_out, "ICC(A,1) [cluster]", fixed = TRUE)
  expect_no_match(ml_out, "Level", fixed = TRUE)
})

test_that("a ci other than the fitted level aborts; the fitted level passes through", {
  skip_if_not_installed("parameters")
  x <- mp_twoway()
  # Which failure: the level refusal from this method, named by its own
  # message, not an error raised inside parameters.
  refusal <- "must equal the confidence level of the fit"
  expect_error(
    parameters::model_parameters(x, ci = 0.90),
    class = "intraclass_error",
    regexp = "conf_level"
  )
  expect_error(
    parameters::model_parameters(x, ci = 0.90),
    class = "intraclass_error",
    regexp = refusal
  )
  # Any value other than the fit's level is an error, as ?icc says.
  expect_error(
    parameters::model_parameters(x, ci = "0.95"),
    class = "intraclass_error",
    regexp = refusal
  )
  expect_error(
    parameters::model_parameters(x, ci = c(0.95, 0.95)),
    class = "intraclass_error",
    regexp = refusal
  )
  expect_error(
    parameters::model_parameters(x, ci = NA_real_),
    class = "intraclass_error",
    regexp = refusal
  )
  expect_identical(
    parameters::model_parameters(x, ci = 0.95),
    parameters::model_parameters(x)
  )
  # The comparison has a tolerance, so a computed 0.95 is not refused.
  expect_identical(
    parameters::model_parameters(x, ci = 0.1 * 9.5),
    parameters::model_parameters(x)
  )
})
