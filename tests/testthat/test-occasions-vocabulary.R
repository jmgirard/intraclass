# The occasion vocabulary, held to the quantity each surface reports.
#
# `tidy()$occasions` is the per-rater occasion divisor a row's coefficient
# applies to pure error, while `glance()$n_o` is the observed per-cell occasion
# count of the fitted design. The two are near-identical names for different
# quantities (D-044), so the reference manual has to say which is which. Every
# sentence pinned below was DERIVED from the measured grid in M146 T15, never
# composed per design family: that shape falsified this criterion twice
# (`LESSONS.md:47`). These tests read the RENDERED help pages, not `R/*.R`, so
# the pin runs under `R CMD check`, where the sources are absent; `man_pages()`
# below collects every rendered surface that is present, so a source-tree run
# cannot pass on a stale installed copy.
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

test_that("?icc says occasions is the per-rater occasion divisor, not a ratings count", {
  pages <- man_pages("icc.Rd")

  # Anti-vacuity: every `expect_says()` below would be trivially false, and
  # every absence check trivially true, against an empty page.
  for (nm in names(pages)) {
    expect_gt(nchar(pages[[nm]]), 1000L)
  }
  expect_says(pages, "tidy.icc(): a tibble")

  expect_says(
    pages,
    paste0(
      "occasions reports the per-rater occasion divisor that row's ",
      "coefficient applies to pure error"
    )
  )

  # The value rule, stated as the condition the code guarantees. The 1 case
  # covers both families that reach it without enumerating design families:
  # a single-occasion row, and a row whose error set holds no pure error.
  expect_says(
    pages,
    paste0(
      "On a fit that splits within-cell replicates it reads 1 wherever the ",
      "row averages no occasions. That covers every single-occasion row, and ",
      "every row whose error set carries no pure-error term to average"
    )
  )
  expect_says(
    pages,
    "It reads the fitted per-cell occasion count where the row does average"
  )
  expect_says(pages, "On a fit that splits none it is NA")

  # The denial that failed review twice when it was stated the other way round.
  expect_says(
    pages,
    paste0(
      "It is not in general the number of ratings the coefficient averages, ",
      "because it counts occasions per rater: an occasion-averaged ICC(*,k) ",
      "row averages k raters at that occasion count each"
    )
  )

  # The contrast, and specifically that `n_o` is named as the OTHER quantity,
  # with its own NA case deferred to the bullet that states D-041's condition
  # rather than re-glossed here.
  expect_says(
    pages,
    paste0(
      "glance() reports a different quantity as n_o, the observed per-cell ",
      "occasion count of the fitted design. n_o is itself NA under the ",
      "condition the glance.icc() bullet below states, which a ragged ",
      "replicate design meets while occasions still reads 1"
    )
  )

  # The falsified wording must not come back: it is false on every ICC(*,k)
  # row, and `single-rating` collides with the house term single-occasion.
  expect_silent_on(
    pages,
    "the number of ratings averaged into that row's coefficient"
  )
  expect_silent_on(pages, "1 for a single-rating coefficient")
})

test_that("?d_study states the projection's own occasions rule and no glance() contrast", {
  pages <- man_pages("d_study.Rd")

  for (nm in names(pages)) {
    expect_gt(nchar(pages[[nm]]), 1000L)
  }
  expect_says(pages, "tidy.icc_dstudy(): a tibble")

  # The projection's `occasions` is the count the row is projected at. It can
  # be non-integer (M138), and it divides pure error, so a row with no
  # pure-error term does not move with it.
  expect_says(
    pages,
    paste0(
      "occasions reports the per-cell occasion count the row is projected ",
      "at, which may be non-integer, and which divides pure error, so a row ",
      "whose error set carries no pure-error term does not move with it"
    )
  )

  # What the column takes on each axis, and on the cluster rows of each.
  expect_says(
    pages,
    paste0(
      "On a rater projection the column takes every distinct occasion value ",
      "the fit's own tidy()$occasions column carries, and the cluster rows ",
      "of a multilevel projection take the smallest of those"
    )
  )
  expect_says(
    pages,
    paste0(
      "On an occasion projection every row takes the swept n_o, cluster rows ",
      "included, whose curve is flat across it"
    )
  )
  expect_says(pages, "occasions is NA outside a replicate projection")

  # Neither the falsified ?icc sentence nor its predecessor may be copied here.
  expect_silent_on(
    pages,
    "the number of ratings averaged into that row's coefficient"
  )
  expect_silent_on(
    pages,
    "the number of ratings averaged into the row's coefficient"
  )
  expect_silent_on(pages, "the setting held fixed on a rater projection")

  # `glance.icc_dstudy()` carries no `n_o` column, so the contrast ?icc draws
  # has no referent on this page and must not be copied onto it. `n_o` itself
  # is all over the page as the swept argument, so the absence check names the
  # contrast phrase, never the symbol.
  expect_silent_on(pages, "reports a different quantity as n_o")
})
