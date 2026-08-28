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

# Two surfaces can carry the page, and neither alone is trustworthy on its own:
# `tools::Rd_db("intraclass")` reads whatever copy `find.package()` resolves --
# under `R CMD check` that is the branch, but from a source tree it can be an
# older library copy, so a pin read only from there can pass on docs the branch
# does not ship. The source `man/*.Rd` is the branch's own rendered page but is
# absent from `<pkg>.Rcheck`, the layout CI runs. So collect every surface that
# is present and assert on ALL of them, requiring at least one; a build with
# neither is a failure, never a skip.
man_pages <- function(file) {
  out <- list()
  source_rd <- testthat::test_path("..", "..", "man", file)
  if (file.exists(source_rd)) {
    out[["man/"]] <- squash_ws(rd_flat_text(tools::parse_Rd(source_rd)))
  }
  installed <- tryCatch(tools::Rd_db("intraclass"), error = function(e) NULL)
  if (!is.null(installed) && file %in% names(installed)) {
    out[["Rd_db()"]] <- squash_ws(rd_flat_text(installed[[file]]))
  }
  expect_gt(length(out), 0L)
  out
}

# Assert one claim across every surface `man_pages()` found, naming the surface
# in the failure so a stale library copy is distinguishable from a branch
# regression.
expect_says <- function(pages, pattern) {
  for (nm in names(pages)) {
    expect_true(grepl(pattern, pages[[nm]], fixed = TRUE), info = nm)
  }
}

expect_silent_on <- function(pages, pattern) {
  for (nm in names(pages)) {
    expect_false(grepl(pattern, pages[[nm]], fixed = TRUE), info = nm)
  }
}

test_that("?icc says tidy()'s occasions counts ratings averaged, not occasions observed", {
  pages <- man_pages("icc.Rd")

  # Anti-vacuity: every `expect_says()` below would be trivially false, and
  # every absence check trivially true, against an empty page.
  for (nm in names(pages)) {
    expect_gt(nchar(pages[[nm]]), 1000L)
  }
  expect_says(pages, "tidy.icc(): a tibble")

  expect_says(
    pages,
    "occasions reports the number of ratings averaged into that row's coefficient"
  )
  expect_says(pages, "1 for a single-rating coefficient")
  expect_says(
    pages,
    "the fitted per-cell replicate count for an occasion-averaged one"
  )
  expect_says(pages, "NA when the design has no within-cell replicates")

  # The contrast, and specifically that `n_o` is named as the OTHER quantity.
  expect_says(
    pages,
    paste0(
      "a different quantity from the one glance() reports as n_o, ",
      "which is the observed per-cell occasion count of the fitted design"
    )
  )

  # `n_o`'s own NA case, which is where the two columns visibly diverge: a
  # ragged replicate fit reads `n_o` NA and `occasions` 1.
  expect_says(
    pages,
    paste0(
      "n_o is itself NA on a design that defines no single such count, ",
      "a ragged replicate design among them, where occasions still reads 1"
    )
  )
})

test_that("?d_study states the projection's own occasions meaning and no glance() contrast", {
  pages <- man_pages("d_study.Rd")

  for (nm in names(pages)) {
    expect_gt(nchar(pages[[nm]]), 1000L)
  }
  expect_says(pages, "tidy.icc_dstudy(): a tibble")

  # The projection's `occasions` is the count the row is projected at, which is
  # the averaging divisor only where occasion averaging applies -- not on the
  # cluster rows of a multilevel projection, whose curve is flat.
  expect_says(
    pages,
    paste0(
      "occasions reports the per-cell occasion count that row is projected ",
      "at: the setting held fixed on a rater projection, the swept count on ",
      "an occasion projection"
    )
  )
  expect_says(
    pages,
    paste0(
      "the number of ratings averaged into the row's coefficient wherever ",
      "occasion averaging applies"
    )
  )
  expect_says(
    pages,
    paste0(
      "does not apply to the cluster rows of a multilevel projection: that ",
      "error set has no pure-error term, so the cluster curve is flat across ",
      "the column"
    )
  )
  expect_says(pages, "occasions is NA outside a replicate projection")

  # The unqualified ?icc sentence must not be copied here: it is false on those
  # cluster rows.
  expect_silent_on(
    pages,
    "occasions reports the number of ratings averaged into that row's coefficient"
  )

  # `glance.icc_dstudy()` carries no `n_o` column, so the contrast ?icc draws
  # has no referent on this page and must not be copied onto it. `n_o` itself
  # is all over the page as the swept argument, so the absence check names the
  # contrast phrase, never the symbol.
  expect_silent_on(pages, "reports as n_o")
})
