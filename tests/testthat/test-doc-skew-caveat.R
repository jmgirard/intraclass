# The documented skew/kurtosis under-coverage caveat, held to its measurement.
#
# `?icc`, `vignettes/interval-methods.Rmd` and NEWS all state figures for the
# Monte-Carlo default's coverage under skewed / heavy-tailed subject effects,
# and withdraw an earlier claim that `ci_method = "burch"` never under-covers.
# Every one of those figures was measured by M113 / M114 and is carried by the
# committed fixture below. These tests read the INSTALLED package -- the help
# database, the shipped vignette source, the installed NEWS -- so the pin runs
# under `R CMD check`, where the source tree and `data-raw/` are absent.
#
# The fixture's own provenance is checked separately, and only where the source
# tree exists (see the last block).

fixture_path <- testthat::test_path("fixtures", "skew-undercoverage.tsv")

skew_fixture <- function() {
  utils::read.delim(fixture_path, stringsAsFactors = FALSE)
}

# The cells the caveat is about: the Monte-Carlo default under-covering for a
# reason that is NOT selection by aborting. Defined here once, so every
# assertion below and the documented prose share one definition.
low_abort_failures <- function(f) {
  g <- f[f$source == "m113" & f$method == "mc", , drop = FALSE]
  g[g$abort_rate <= 0.1 & g$coverage_nonabort < 0.93, , drop = FALSE]
}

test_that("the caveat's cells are the ones the fixture measures as failing", {
  f <- skew_fixture()
  failing <- low_abort_failures(f)

  # Anti-vacuity: a filter that matched nothing would satisfy every paired
  # assertion below for free.
  expect_gt(nrow(failing), 0L)
  expect_identical(nrow(failing), 10L)

  worst <- failing[which.min(failing$coverage_nonabort), ]
  expect_identical(worst$dist, "chisq1")
  expect_equal(worst$rho, 0.6)
  expect_equal(worst$k, 50L)
  expect_equal(worst$n, 5L)
  expect_equal(worst$coverage_nonabort, 0.6725)
})

test_that("both classical opt-ins also under-cover in every one of those cells", {
  # This is what licenses the caveat's claim that switching to a closed form
  # is not a remedy. It is a claim about `searle` and `burch` ONLY -- the
  # other `ci_method` values were never run on this grid.
  f <- skew_fixture()
  failing <- low_abort_failures(f)

  for (i in seq_len(nrow(failing))) {
    cell <- failing[i, ]
    for (other in c("searle", "burch")) {
      row <- f[
        f$source == "m113" &
          f$method == other &
          f$rho == cell$rho &
          f$k == cell$k &
          f$n == cell$n &
          f$dist == cell$dist,
        ,
        drop = FALSE
      ]
      expect_identical(nrow(row), 1L)
      expect_lt(row$coverage_uncond, 0.93)
    }
  }
})

test_that("burch's worst measured cell is the one the corrected docs name", {
  f <- skew_fixture()
  b <- f[f$source == "m113" & f$method == "burch", , drop = FALSE]
  worst <- b[which.min(b$coverage_uncond), ]

  expect_equal(worst$coverage_uncond, 0.6655)
  expect_equal(worst$rho, 0.6)
  expect_equal(worst$k, 30L)
  expect_equal(worst$n, 5L)
  expect_identical(worst$dist, "chisq1")
})

# Fixture provenance ----------------------------------------------------------
#
# Source-tree only: `data-raw/` is `.Rbuildignore`d, so the built package has
# the fixture but not the two artifacts it derives from. The pins above are the
# ones that must run everywhere; this one guards against a hand-edited fixture
# and runs wherever the sources exist.

data_raw_dir <- testthat::test_path("..", "..", "data-raw")

test_that("the fixture re-derives from its M113/M114 sources", {
  skip_if_not(dir.exists(data_raw_dir), "data-raw/ not present (built package)")

  m113 <- utils::read.delim(
    file.path(data_raw_dir, "m113-skew-response-coverage.tsv"),
    stringsAsFactors = FALSE
  )
  f <- skew_fixture()
  grid <- f[f$source == "m113", , drop = FALSE]

  expect_identical(nrow(grid), nrow(m113))

  # Row-for-row against the source, keyed rather than positionally, so a
  # reordering of either file cannot hide a changed value.
  key <- function(d) paste(d$rho, d$k, d$n, d$dist, d$method, sep = "\r")
  src <- m113[match(key(grid), key(m113)), , drop = FALSE]
  expect_false(anyNA(src$rho))
  expect_equal(grid$coverage_uncond, src$coverage_uncond)
  expect_equal(grid$coverage_nonabort, src$coverage_nonabort)
  expect_equal(grid$abort_rate, src$n_abort / src$n_rep)

  # The held-out leg is counted from per-rep rows, so it is re-counted here.
  stats <- utils::read.delim(
    file.path(data_raw_dir, "m114-warn-trigger-stats.tsv"),
    stringsAsFactors = FALSE
  )
  heldout <- stats[stats$source == "heldout", , drop = FALSE]
  held <- f[f$source == "m114-heldout", , drop = FALSE]
  expect_gt(nrow(held), 0L)

  for (i in seq_len(nrow(held))) {
    cell <- held[i, ]
    reps <- heldout[
      heldout$rho == cell$rho &
        heldout$k == cell$k &
        heldout$n == cell$n &
        heldout$dist == cell$dist,
      ,
      drop = FALSE
    ]
    expect_identical(nrow(reps), as.integer(cell$n_rep))
    aborted <- reps$mc_aborted %in% c("TRUE", TRUE)
    covered <- reps$mc_covered %in% c("TRUE", TRUE)
    expect_equal(cell$abort_rate, sum(aborted) / nrow(reps))
    expect_equal(cell$coverage_nonabort, sum(covered[!aborted]) / sum(!aborted))
  }
})

test_that("every fixture value round-trips through the committed text", {
  skip_if_not(dir.exists(data_raw_dir), "data-raw/ not present (built package)")

  # The generator writes with the default `write.table` formatting; if that
  # ever loses precision the figures the docs quote stop being the measured
  # ones. Assert the round trip rather than assuming it.
  f <- skew_fixture()
  tmp <- withr::local_tempfile(fileext = ".tsv")
  utils::write.table(f, tmp, sep = "\t", quote = FALSE, row.names = FALSE)
  expect_equal(utils::read.delim(tmp, stringsAsFactors = FALSE), f)
})
