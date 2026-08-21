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
# CURRENT print method and requires the vignette text to match verbatim, so a
# change to print formatting -- header wording, column layout, digits -- reds
# here even though no Stan toolchain is involved.
#
# WHAT IT DOES NOT CATCH: the stored draws are frozen. A change in what the brms
# engine COMPUTES is caught only when data-raw/oracle-bayesian-vignette.R is
# re-run, which is the standing limit of the offline-fixture tier, not a gap
# this file introduces (data-raw/README.md).
#
# THE ENUMERATION IS THE TEST'S OWN. Rather than trust a hand-list of block
# locations, the extractor below finds every maximal run of `#>`-prefixed lines
# in vignettes/*.Rmd -- knitr output never appears in a .Rmd SOURCE, so every
# such run is hand-pasted by construction. A new unpinned block therefore fails
# here instead of being silently skipped (the M118 hand-list lesson).

fixture <- readRDS(testthat::test_path("fixtures", "bayesian-vignette-oracle.rds"))

vignette_dir <- testthat::test_path("..", "..", "vignettes")

# Every maximal run of consecutive `#>` lines in a vignette source, with the
# comment prefix stripped. Returns a list of character vectors.
pasted_blocks <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  is_out <- grepl("^[[:space:]]*#>", lines)
  if (!any(is_out)) {
    return(list())
  }
  run <- cumsum(!is_out)[is_out]
  split(sub("^[[:space:]]*#>[[:space:]]?", "", lines[is_out]), run)
}

# The fixture carries the cli rendering mode its transcripts were produced
# under -- width, Unicode glyphs, colour. testthat's default cli mode is ASCII,
# so rendering without these compares "──" against "--".
# `print.icc()` emits through cli, which writes to its own output connection --
# `utils::capture.output()` returns character(0) for it. `cli::cli_fmt()` captures
# the real print() path, so this pins what a user actually sees.
render_under_fixture_options <- function(x) {
  withr::with_options(fixture$render_options, cli::cli_fmt(print(x)))
}

# The expected transcripts, each named for the block it pins.
expected_transcripts <- function() {
  list(
    "engines.Rmd / interval-methods.Rmd: percentile credible interval" =
      render_under_fixture_options(fixture$fits$percentile),
    "interval-methods.Rmd: HPDI credible interval" =
      render_under_fixture_options(fixture$fits$hpdi),
    "engines.Rmd: the custom-prior warning" =
      c("Warning message:", fixture$custom_prior_warning)
  )
}

test_that("every hand-pasted vignette block matches a rendered transcript", {
  skip_if_not_installed("withr")

  vignettes <- list.files(vignette_dir, pattern = "\\.Rmd$", full.names = TRUE)
  expect_gt(length(vignettes), 0)

  blocks <- unlist(lapply(vignettes, pasted_blocks), recursive = FALSE)
  expected <- expected_transcripts()

  # Direction 1: every pasted block in the vignettes is one of the expected
  # transcripts. A newly pasted, unpinned block fails here.
  for (b in blocks) {
    expect_true(
      any(vapply(expected, identical, logical(1), y = b)),
      label = paste0(
        "pasted block starting \"", b[[1]], "\" matches no rendered transcript"
      )
    )
  }

  # Direction 2: every expected transcript is actually present in a vignette.
  # A transcript deleted from the article fails here rather than silently
  # leaving this file pinning nothing.
  for (nm in names(expected)) {
    expect_true(
      any(vapply(blocks, identical, logical(1), y = expected[[nm]])),
      label = paste0("expected transcript absent from the vignettes: ", nm)
    )
  }
})

test_that("the percentile transcript appears in both articles that show it", {
  # engines.Rmd's `brms` chunk and interval-methods.Rmd's `posterior` chunk are
  # the SAME call, so they must show the same output; a correction applied to
  # one and not the other is the failure this pins.
  percentile <- render_under_fixture_options(fixture$fits$percentile)
  for (f in c("engines.Rmd", "interval-methods.Rmd")) {
    blocks <- pasted_blocks(file.path(vignette_dir, f))
    expect_true(
      any(vapply(blocks, identical, logical(1), y = percentile)),
      label = paste("percentile transcript missing from", f)
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

  # cli formats a condition's message when the condition is CREATED, so the
  # render options must wrap the icc() call -- rendering an already-built
  # condition under them changes nothing, and testthat's own cli mode is ASCII.
  cond <- NULL
  withr::with_options(fixture$render_options, {
    tryCatch(
      withCallingHandlers(
        icc(
          ratings, score, subject, rater,
          engine = "brms",
          prior = brms::set_prior("normal(0, 0.1)", class = "sd"),
          seed = fixture$seed
        ),
        intraclass_custom_prior = function(w) {
          cond <<- w
          stop("captured; unwinding before the fit", call. = FALSE)
        }
      ),
      error = function(e) NULL
    )
  })

  expect_false(is.null(cond))
  expect_identical(class(cond), fixture$custom_prior_classes)

  live <- strsplit(rlang::cnd_message(cond), "\n", fixed = TRUE)[[1]]

  # Compare the WORDS, not the wrap column. cli formats a message inline and
  # lets rlang wrap it for display afterwards (the M93 lesson), so where the
  # line breaks fall depends on the rendering context -- testthat's differs from
  # a console's even with the same width option set. The wrap is pinned exactly
  # where it matters, in the vignette-vs-fixture comparison above; here the job
  # is to catch the message TEXT drifting away from the block the article shows.
  normalize_ws <- function(x) {
    gsub("[[:space:]]+", " ", trimws(paste(x, collapse = " ")))
  }
  expect_identical(normalize_ws(live), normalize_ws(fixture$custom_prior_warning))
})
