# Vignette transcript pins (M129) ---------------------------------------------
#
# Four output blocks in the vignettes are HAND-PASTED rather than knitted: the
# brms chunks carry `eval = FALSE` because fitting a Stan model needs a
# toolchain the pkgdown/knit environment lacks (the M52 offline-fixture
# constraint; data-raw/README.md). Nothing reproduced them, so a stale
# transcript could ship -- a reader copies the call, runs it, and gets different
# numbers from the ones the article shows.
#
# This file closes that. It re-renders the committed fits with the package's
# CURRENT print method and requires each vignette's pasted blocks to match, IN
# ORDER, so a change to print formatting -- header wording, column layout,
# digits -- reds here even though no Stan toolchain is involved.
#
# WHY ORDERED, PER FILE: the percentile transcript legitimately appears twice
# (engines.Rmd's `brms` chunk and interval-methods.Rmd's `posterior` chunk are
# the same call). Matching blocks as an unordered set would let someone swap
# interval-methods.Rmd's percentile and HPDI blocks with the suite still green,
# leaving HPDI numbers under a percentile call. Position is part of the claim.
#
# WHAT IT DOES NOT CATCH: the stored draws are frozen. A change in what the brms
# engine COMPUTES is caught only when data-raw/oracle-bayesian-vignette.R is
# re-run, which is the standing limit of the offline-fixture tier, not a gap
# this file introduces (data-raw/README.md). Nor is the `Warning message:`
# banner derived from anything -- it is R's console framing, a literal in both
# the vignette and the expectation below.
#
# THE ENUMERATION IS THE TEST'S OWN. Rather than trust a hand-list of block
# locations, the extractor finds every maximal run of `#>`-prefixed lines in
# every vignette source -- knitr output never appears in a .Rmd SOURCE, so every
# such run is hand-pasted by construction. A new unpinned block therefore fails
# here instead of being silently skipped (the M118 hand-list lesson).

fixture <- readRDS(testthat::test_path(
  "fixtures",
  "bayesian-vignette-oracle.rds"
))

# The vignette SOURCES live in the source tree only. `R CMD check` runs the
# suite against the installed package, where `../../vignettes` does not exist,
# so this file skips there -- the same tier `test-brms-oracle-map.R` uses for
# `data-raw/`. It therefore bites on every local `devtools::test()` run, at the
# review gate, and in the coverage job (which runs from source), but NOT inside
# the CI `R CMD check` job.
vignette_dir <- testthat::test_path("..", "..", "vignettes")

skip_without_vignette_sources <- function() {
  testthat::skip_if_not(
    dir.exists(vignette_dir),
    "vignettes/ not present (running against the built package)"
  )
}

# Every maximal run of consecutive `#>` lines in a vignette source, with the
# comment prefix stripped, in document order.
pasted_blocks <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  is_out <- grepl("^[[:space:]]*#>", lines)
  if (!any(is_out)) {
    return(list())
  }
  run <- cumsum(!is_out)[is_out]
  unname(split(sub("^[[:space:]]*#>[[:space:]]?", "", lines[is_out]), run))
}

# `print.icc()` emits through cli, which writes to its own output connection --
# `utils::capture.output()` returns character(0) for it. `cli::cli_fmt()` captures
# the real print() path, so this pins what a user actually sees. The fixture
# carries the cli rendering mode its transcripts were produced under (width,
# Unicode glyphs, colour); testthat's default mode is ASCII, so rendering
# without these would compare "──" against "--".
render_under_fixture_options <- function(x) {
  withr::with_options(fixture$render_options, cli::cli_fmt(print(x)))
}

# The expected blocks of each vignette, in the order they appear. A vignette
# absent from this map must contain no pasted blocks at all.
expected_by_file <- function() {
  percentile <- render_under_fixture_options(fixture$fits$percentile)
  hpdi <- render_under_fixture_options(fixture$fits$hpdi)
  # "Warning message:" is R's own console banner, not package output; it is a
  # literal here and in the article, derived from nothing.
  custom_prior <- c("Warning message:", fixture$custom_prior_warning)

  list(
    # `brms` chunk, then `brms-prior` chunk.
    "engines.Rmd" = list(percentile, custom_prior),
    # `posterior` chunk, then `posterior-hpdi` chunk.
    "interval-methods.Rmd" = list(percentile, hpdi)
  )
}

test_that("each vignette's pasted blocks match their transcripts, in order", {
  skip_without_vignette_sources()
  skip_if_not_installed("withr")

  # Recursive and case-blind, to match the domain AC2's own grep sweeps: a
  # `vignettes/children/*.Rmd` or a precompiled `*.Rmd.orig` carrying a pasted
  # block must not escape by living somewhere `list.files()` did not look.
  files <- list.files(vignette_dir, pattern = "\\.[Rr]md$", recursive = TRUE)
  expect_gt(length(files), 0)

  expected <- expected_by_file()

  # Every expected article is present -- a transcript deleted from the vignettes
  # fails here rather than leaving this file pinning nothing.
  expect_true(all(names(expected) %in% files))

  for (f in files) {
    want <- expected[[f]]
    if (is.null(want)) {
      want <- list()
    }
    expect_identical(
      pasted_blocks(file.path(vignette_dir, f)),
      want,
      label = paste("pasted blocks in", f)
    )
  }
})

test_that("the fixture's custom-prior warning is still what the package emits", {
  # The stored warning is a RENDER, so it could drift from the cli_warn() call
  # that produces it without any test noticing. Re-capture it live -- the
  # warning fires in icc()'s argument handling, before the Stan fit is built, so
  # unwinding out of the handler needs no toolchain (M129 plan gate).
  skip_if_not_installed("brms")
  skip_if_not_installed("withr")

  sentinel <- "m129: captured the prior warning, unwinding before the fit"
  cond <- NULL

  # cli formats a condition's message when the condition is CREATED, so the
  # render options must wrap the icc() call -- rendering an already-built
  # condition under them changes nothing, and testthat's own cli mode is ASCII.
  withr::with_options(fixture$render_options, {
    tryCatch(
      withCallingHandlers(
        icc(
          ratings,
          score,
          subject,
          rater,
          engine = "brms",
          prior = brms::set_prior("normal(0, 0.1)", class = "sd"),
          seed = fixture$seed
        ),
        intraclass_custom_prior = function(w) {
          cond <<- w
          stop(sentinel, call. = FALSE)
        }
      ),
      # Re-raise anything that is not our own unwind. Swallowing every error
      # would turn a renamed warning class into a silent live Stan compile whose
      # real failure is reported as "cond is NULL".
      error = function(e) {
        if (!identical(conditionMessage(e), sentinel)) {
          stop(e)
        }
      }
    )
  })

  expect_false(is.null(cond))
  expect_identical(class(cond), fixture$custom_prior_classes)

  live <- strsplit(rlang::cnd_message(cond), "\n", fixed = TRUE)[[1]]

  # Compare the WORDS, not the wrap column. cli formats a message inline and
  # lets rlang wrap it for display afterwards (the M93 lesson), so where the
  # line breaks fall depends on the rendering context -- testthat's differs from
  # a console's even with the same width option set. Neither this check nor the
  # vignette-vs-fixture comparison above pins the wrap against the LIVE
  # renderer: both frozen artifacts agree, so a cli change to the wrap column or
  # to continuation indentation would go unnoticed here.
  normalize_ws <- function(x) {
    gsub("[[:space:]]+", " ", trimws(paste(x, collapse = " ")))
  }
  expect_identical(
    normalize_ws(live),
    normalize_ws(fixture$custom_prior_warning)
  )
})
