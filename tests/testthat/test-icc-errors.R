# Error paths — fail loudly on ill-posed or unsupported requests (#5, #8) -------

test_that("options that are valid but not yet implemented abort with a pointer", {
  d <- sf_ratings_long()

  # model = "oneway" is now supported (M6); an unknown model still aborts.
  expect_error(
    icc(d, score, subject, rater, model = "nested"),
    class = "intraclass_error"
  )
  # lme4/lavaan/brms are now selectable engines (M5.5/M7/M23); an unknown engine
  # still aborts as an invalid choice.
  expect_error(
    icc(d, score, subject, rater, engine = "nonesuch"),
    class = "intraclass_error"
  )
  # "montecarlo" and "bootstrap" are the interval methods (M16, ADR-025); an
  # unknown ci_method aborts as an invalid choice, like an unknown engine.
  expect_error(
    icc(d, score, subject, rater, ci_method = "delta"),
    class = "intraclass_error"
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
    icc(d, score, subject, rater, model = "nested"),
    error = TRUE
  )
  expect_snapshot(
    icc(d[d$rater == "J1", ], score, subject, rater),
    error = TRUE
  )
})

# Degenerate INPUT and degenerate DATA (M105) ----------------------------------
#
# Two failure families that reached the user raw rather than classed. A
# non-finite `score` flowed into whichever engine was selected and surfaced that
# engine's own `simpleError` -- a different message per engine, none of them
# catchable by class (#8). And `ci_method = "burch"` on data with no
# between-subject variance divided by `sqrt(MSA) = 0` in `burch_kappa_hat()`,
# producing NaN endpoints that either crashed the Spearman-Brown pole guard
# (`unit = "average"`) or shipped as a silent NaN interval (`unit = "single"`)
# -- a reported non-interval, which #3 and #5 both refuse.

test_that("a non-finite score aborts classed on every model and engine", {
  d <- sf_ratings_long()
  # The enumeration IS the domain this criterion quantifies over (M105 AC1):
  # every pair the loop runs, every non-finite value the loop injects.
  models <- c("oneway", "twoway")
  engines <- c("glmmTMB", "lme4")
  bad_values <- list(`Inf` = Inf, `-Inf` = -Inf, `NaN` = NaN)

  for (model in models) {
    for (engine in engines) {
      for (label in names(bad_values)) {
        spoiled <- d
        spoiled$score[[4L]] <- bad_values[[label]]
        expect_error(
          icc(spoiled, score, subject, rater, model = model, engine = engine),
          class = "intraclass_error",
          info = paste(model, engine, label)
        )
      }
    }
  }
})

test_that("the non-finite abort names the column and the offending rows", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  d <- sf_ratings_long()
  d$score[[2L]] <- Inf
  d$score[[7L]] <- NaN
  cnd <- rlang::catch_cnd(icc(d, score, subject, rater), classes = "error")
  rendered <- cli::format_message(conditionMessage(cnd))
  expect_match(rendered, "score", fixed = TRUE)
  # Match the POSITIONS as a phrase, not the bare digits: the message also
  # carries the count (2), so `expect_match(rendered, "2")` alone would be
  # satisfied by the count and would still pass if the first row position were
  # reported wrongly.
  expect_match(rendered, "rows 2 and 7", fixed = TRUE)
})

test_that("NA scores are dropped with a suppressible classed warning", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  d <- sf_ratings_long()
  dropped <- d
  # Two ratings that did not happen. Removing them leaves every subject rated by
  # more than one rater and the subject x rater graph connected, so the remainder
  # is an ordinary incomplete design the package already fits.
  dropped$score[c(2L, 7L)] <- NA_real_
  absent <- d[-c(2L, 7L), ]

  expect_warning(
    icc(dropped, score, subject, rater),
    class = "intraclass_dropped_rows"
  )

  # The default interval is Monte-Carlo, so both calls are seeded: an unseeded
  # pair would differ on the endpoints for reasons that have nothing to do with
  # how the missing ratings were spelled.
  from_na <- suppressWarnings(icc(dropped, score, subject, rater, seed = 1L))
  from_absent <- icc(absent, score, subject, rater, seed = 1L)
  # Dropping a row and never supplying it must be the same analysis, to the bit.
  expect_identical(
    generics::tidy(from_na)$estimate,
    generics::tidy(from_absent)$estimate
  )
  expect_identical(
    generics::tidy(from_na)$conf.low,
    generics::tidy(from_absent)$conf.low
  )
  expect_identical(
    generics::tidy(from_na)$conf.high,
    generics::tidy(from_absent)$conf.high
  )
})

test_that("dropping NA scores leaves exactly the methods the design supports", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Before M105 an NA-scored row counted as an observed cell, so this design read
  # as BALANCED to every design fence while no reducer could actually use it.
  # With the row dropped it is a genuinely unbalanced one-way design, and the
  # fences now say so: the two balanced-only classical methods are refused up
  # front rather than aborting deep inside their extractors, and `npbootstrap`,
  # which supports unbalanced one-way data, works.
  set.seed(11)
  d <- data.frame(
    subject = rep(1:20, each = 3),
    rater = rep(1:3, times = 20),
    score = round(stats::rnorm(60), 1)
  )
  d$score[[5L]] <- NA_real_

  call_with <- function(method) {
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = method,
      seed = 1L
    ))
  }

  # The enumeration IS the domain this clause quantifies over (M105 AC2).
  for (method in c("searle", "burch")) {
    expect_error(
      call_with(method),
      class = "intraclass_unsupported",
      info = method
    )
  }
  for (method in c("npbootstrap", "montecarlo")) {
    tidied <- generics::tidy(call_with(method))
    expect_true(is.finite(tidied$conf.low[[1L]]), info = method)
    expect_true(is.finite(tidied$conf.high[[1L]]), info = method)
  }
})
