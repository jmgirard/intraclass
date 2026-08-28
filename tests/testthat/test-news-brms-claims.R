# The release notes' *Engines* section states three facts about the brms
# engine, and each is a claim about engine behaviour rather than a description
# of one. So each gets a pin: deleting the fact reds, rewording it in the same
# terms does not.
#
# The surface read is the INSTALLED `NEWS.md` -- the copy that ships and the
# only one that exists under `R CMD check`, where the source tree is absent.
# `NEWS.md` is installed into the package root, so `system.file()` finds it.
#
# The claims are stated in the roxygen these patterns were derived from:
# `R/icc.R` `@details` (the posterior mode and the percentile credible
# interval) and `@param prior` (the sourced prior, and what a custom one
# costs). The pin is one-sided on purpose -- it holds the notes to the roxygen,
# and the roxygen has its own tests.

news_engines_text <- function() {
  path <- system.file("NEWS.md", package = "intraclass")
  testthat::skip_if(!nzchar(path), "NEWS.md not installed")
  lines <- readLines(path, warn = FALSE)
  start <- grep("^## Engines[[:space:]]*$", lines)
  testthat::expect_length(start, 1L)
  rest <- lines[seq(start + 1L, length(lines))]
  ends <- grep("^## ", rest)
  stop_at <- if (length(ends)) ends[[1]] - 1L else length(rest)
  gsub("[[:space:]]+", " ", paste(rest[seq_len(stop_at)], collapse = " "))
}

# Tolerant of markup and of wording between the load-bearing terms, so ordinary
# copy-editing does not re-key the pin, but the terms themselves must be there.
news_brms_claims <- c(
  sourced_prior = paste0(
    "half-\\*?t\\*?\\(4, 0, 1\\) prior on every random-effect ",
    "standard deviation"
  ),
  posterior_summary = paste0(
    "posterior mode.*percentile \\*{0,2}credible\\*{0,2} interval"
  ),
  custom_prior_voids = paste0(
    "custom .?prior.?.*warns.*coverage results.*no longer apply"
  )
)

test_that("the release notes state the three brms engine facts", {
  txt <- news_engines_text()

  # Anti-vacuity, stated independently of the three claims: the section was
  # found, is non-empty, and carries the engine sentence that is not one of
  # them. Without this a section slice that silently emptied would pass every
  # `expect_false` below and fail every `expect_true` for the wrong reason.
  expect_gt(nchar(txt), 200L)
  expect_match(txt, "The default engine is \\*\\*glmmTMB\\*\\*")

  for (nm in names(news_brms_claims)) {
    expect_match(
      txt,
      news_brms_claims[[nm]],
      info = paste0("brms claim '", nm, "' missing from NEWS.md *Engines*")
    )
  }
})
