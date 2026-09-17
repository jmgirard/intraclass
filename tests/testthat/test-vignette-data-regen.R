# The four simulated teaching datasets (`school`, `school_incomplete`,
# `ratings_replicates`, `ratings_twoway`) ship as `data/*.rda` built by
# `data-raw/make-vignette-data.R`. Until M154 the vignette-claims tests rebuilt
# them inline at their seeds, which pinned the generator implicitly. This test
# keeps that pin: it evaluates the script's builders in a fresh environment,
# skipping only the `usethis::use_data()` call that writes `data/`, and checks
# each object against the shipped one (M154 review, [O] 2).

regen_script <- file.path(
  testthat::test_path(),
  "..",
  "..",
  "data-raw",
  "make-vignette-data.R"
)

regen_objects <- function(path) {
  env <- new.env(parent = globalenv())
  exprs <- parse(path, keep.source = FALSE)
  for (e in exprs) {
    # Matched by name, not by a `pkg::fun` symbol, so R CMD check does not
    # read the test as depending on the package that writes `data/`.
    is_use_data <- is.call(e) &&
      grepl("use_data", paste(deparse(e[[1]]), collapse = ""), fixed = TRUE)
    if (!is_use_data) {
      eval(e, envir = env)
    }
  }
  env
}

test_that("data-raw/make-vignette-data.R regenerates the shipped datasets", {
  skip_if_not(
    file.exists(regen_script),
    "data-raw/ not present (built package)"
  )
  env <- regen_objects(regen_script)

  expect_identical(env$school, intraclass::school)
  expect_identical(env$school_incomplete, intraclass::school_incomplete)
  expect_identical(env$ratings_replicates, intraclass::ratings_replicates)
  expect_identical(env$ratings_twoway, intraclass::ratings_twoway)
})
