# M159 (D-050): result classes carry the `intraclass_` prefix ----------------
#
# performance::icc() returns class "icc" and registers print.icc and
# as.data.frame.icc. Attached after intraclass, it replaced intraclass's print
# method, and a printed result showed only its header. The result classes now
# carry a prefix that only intraclass uses, so no method another package
# registers on "icc" can reach them.

test_that("icc(), choose_icc() and d_study() return the prefixed classes", {
  skip_if_not_installed("glmmTMB")

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  expect_identical(class(fit), "intraclass_icc")

  rec <- choose_icc(type = "agreement", unit = "single", raters = "random")
  expect_identical(class(rec), "intraclass_recommendation")

  d <- d_study(fit, m = c(1, 2, 4))
  expect_identical(class(d)[[1]], "intraclass_dstudy")
  expect_false(any(c("icc", "icc_dstudy", "icc_recommendation") %in% class(d)))
})

# Register `method` for `generic` on class "icc" in the table of `envir`, and
# restore that table's previous entry when the calling test ends.
register_foreign_icc_method <- function(generic, method, envir, frame) {
  table <- get(".__S3MethodsTable__.", envir = envir)
  name <- paste0(generic, ".icc")
  had <- exists(name, envir = table, inherits = FALSE)
  old <- if (had) get(name, envir = table, inherits = FALSE)
  registerS3method(generic, "icc", method, envir = envir)
  withr::defer(
    {
      rm(list = name, envir = table)
      if (had) assign(name, old, envir = table)
    },
    envir = frame
  )
}

test_that("methods another package registers on \"icc\" do not reach a result", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("withr")

  fit <- icc(sf_ratings_long(), score, subject, rater, seed = 1)
  before <- list(
    format = format(fit),
    tidy = tidy(fit),
    glance = glance(fit),
    print = cli::cli_fmt(print(fit))
  )

  marker <- "foreign icc method"
  foreign <- function(x, ...) marker
  frame <- environment()
  for (generic in c("print", "format", "summary")) {
    register_foreign_icc_method(generic, foreign, baseenv(), frame)
  }
  for (generic in c("tidy", "glance")) {
    register_foreign_icc_method(
      generic,
      foreign,
      asNamespace("generics"),
      frame
    )
  }

  print_value <- NULL
  printed <- cli::cli_fmt(print_value <- print(fit))
  summary_value <- NULL
  cli::cli_fmt(summary_value <- summary(fit))

  expect_false(identical(print_value, marker))
  expect_false(identical(summary_value, marker))
  expect_false(identical(format(fit), marker))
  expect_false(identical(tidy(fit), marker))
  expect_false(identical(glance(fit), marker))

  expect_identical(format(fit), before$format)
  expect_identical(tidy(fit), before$tidy)
  expect_identical(glance(fit), before$glance)
  expect_identical(printed, before$print)
})
