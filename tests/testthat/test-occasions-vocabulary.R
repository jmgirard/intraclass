# The occasion vocabulary, held to the quantity each surface reports.
#
# `tidy()$occasions` is the averaging divisor -- how many ratings went into
# that row's coefficient -- while `glance()$n_o` is the observed per-cell
# occasion count of the fitted design. The two are near-identical names for
# different quantities (D-044), so the reference manual has to say which is
# which. These tests read the INSTALLED help database, not `R/*.R`, so the pin
# runs under `R CMD check`, where the sources are absent.
#
# Every pattern below is matched over whitespace-collapsed text and spelled
# WITHOUT backticks: `rd_flat()` is `rapply(as.character)` over the parsed Rd
# and discards `\code{}` markup, so a backticked pattern is inert here
# (`cairn/doctrine/doc-claim-pins.md`).

rd_flat_text <- function(x) {
  paste(rapply(list(x), as.character, how = "unlist"), collapse = "")
}

squash_ws <- function(x) gsub("[[:space:]]+", " ", paste(x, collapse = " "))

# The installed help database is what a user reads and what ships. It does not
# exist under `devtools::load_all()`, where `Rd_db()` errors rather than
# returning nothing, so fall back to the source `man/*.Rd` -- the same content
# pre-install. Under `R CMD check` the first branch is taken, and a build with
# neither is a failure, never a skip.
man_page <- function(file) {
  installed <- tryCatch(tools::Rd_db("intraclass"), error = function(e) NULL)
  if (!is.null(installed) && file %in% names(installed)) {
    return(squash_ws(rd_flat_text(installed[[file]])))
  }
  source_rd <- testthat::test_path("..", "..", "man", file)
  expect_true(file.exists(source_rd))
  squash_ws(rd_flat_text(tools::parse_Rd(source_rd)))
}

test_that("?icc says tidy()'s occasions counts ratings averaged, not occasions observed", {
  text <- man_page("icc.Rd")

  # Anti-vacuity: every `expect_true(grepl(...))` below would be trivially
  # false, and every absence check trivially true, against an empty page.
  expect_gt(nchar(text), 1000L)
  expect_true(grepl("tidy.icc(): a tibble", text, fixed = TRUE))

  expect_true(grepl(
    "occasions reports the number of ratings averaged into that row's coefficient",
    text,
    fixed = TRUE
  ))
  expect_true(grepl("1 for a single-rating coefficient", text, fixed = TRUE))
  expect_true(grepl(
    "the fitted per-cell replicate count for an occasion-averaged one",
    text,
    fixed = TRUE
  ))
  expect_true(grepl(
    "NA when the design has no within-cell replicates",
    text,
    fixed = TRUE
  ))

  # The contrast, and specifically that `n_o` is named as the OTHER quantity.
  expect_true(grepl(
    paste0(
      "a different quantity from the one glance() reports as n_o, ",
      "which is the observed per-cell occasion count of the fitted design"
    ),
    text,
    fixed = TRUE
  ))
})

test_that("?d_study states the projection's own occasions meaning and no glance() contrast", {
  text <- man_page("d_study.Rd")

  expect_gt(nchar(text), 1000L)
  expect_true(grepl("tidy.icc_dstudy(): a tibble", text, fixed = TRUE))

  expect_true(grepl(
    paste0(
      "occasions reports the number of ratings averaged into that row's ",
      "coefficient, and is NA outside a replicate projection"
    ),
    text,
    fixed = TRUE
  ))

  # `glance.icc_dstudy()` carries no `n_o` column, so the contrast ?icc draws
  # has no referent on this page and must not be copied onto it. `n_o` itself
  # is all over the page as the swept argument, so the absence check names the
  # contrast phrase, never the symbol.
  expect_false(grepl("reports as n_o", text, fixed = TRUE))
})
