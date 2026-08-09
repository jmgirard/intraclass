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

# The documented surfaces, read from the INSTALLED package ---------------------
#
# Everything below runs wherever the package is installed, `R CMD check`
# included -- the point of reading the help database rather than `R/icc.R`.

rd_flat <- function(x) {
  paste(rapply(list(x), as.character, how = "unlist"), collapse = "")
}

# The installed help database is the surface that matters -- it is what a user
# reads and what ships -- but it does not exist under `devtools::load_all()`,
# where the package is loaded from source and `Rd_db()` errors rather than
# returning nothing. Fall back to the source `man/icc.Rd` there, so the same
# assertions run in a dev session; under `R CMD check` the first branch is the
# one taken, and a build with neither is a failure, never a skip.
icc_rd <- function() {
  installed <- tryCatch(tools::Rd_db("intraclass"), error = function(e) NULL)
  if (!is.null(installed) && "icc.Rd" %in% names(installed)) {
    return(installed[["icc.Rd"]])
  }
  source_rd <- testthat::test_path("..", "..", "man", "icc.Rd")
  expect_true(file.exists(source_rd))
  tools::parse_Rd(source_rd)
}

# The `@section Confidence intervals:` block, and only it: the section is
# located by its own title, so neighbouring sections can never widen the scope.
caveat_section <- function() {
  found <- NULL
  for (el in icc_rd()) {
    if (!identical(attr(el, "Rd_tag"), "\\section")) {
      next
    }
    if (grepl("Confidence intervals", rd_flat(el[[1]]), fixed = TRUE)) {
      found <- rd_flat(el[[2]])
    }
  }
  found
}

# Numerals that are not measurements: confidence levels and the like. Every
# other number in the caveat must come from the fixture.
caveat_numeral_allowlist <- c(0.95, 1)

test_that("the caveat names the distributional condition it is about", {
  sec <- caveat_section()
  expect_false(is.null(sec))
  expect_match(sec, "skew", ignore.case = TRUE)
  expect_match(sec, "heavy[ -]tailed", ignore.case = TRUE)
})

test_that("every numeral in the caveat is a measured value or allowlisted", {
  sec <- caveat_section()
  f <- skew_fixture()

  measured <- unique(c(
    f$rho,
    f$k,
    f$n,
    f$n_rep,
    f$abort_rate,
    f$coverage_uncond,
    f$coverage_nonabort,
    caveat_numeral_allowlist
  ))

  numerals <- regmatches(sec, gregexpr("[0-9]+(\\.[0-9]+)?", sec))[[1]]
  # Anti-vacuity: an empty match set would pass the loop below for free, and
  # a caveat with no figures is not the one AC1 asks for.
  expect_gt(length(numerals), 0L)

  for (tok in numerals) {
    value <- as.numeric(tok)
    expect_true(
      any(abs(measured - value) < 1e-9),
      info = paste0("numeral '", tok, "' in the caveat is not a measured value")
    )
  }
})

test_that("the caveat quotes only methods the fixture measured", {
  sec <- caveat_section()
  # `"mc"` is the fixture's key for the exported string `"montecarlo"`; the
  # caveat names the string a user types.
  allowed <- c("montecarlo", "searle", "burch")

  quoted <- regmatches(sec, gregexpr('"[^"]+"', sec))[[1]]
  quoted <- gsub('"', "", quoted, fixed = TRUE)
  expect_gt(length(quoted), 0L)
  expect_true(all(quoted %in% allowed), info = paste(quoted, collapse = ", "))

  # And the fixture really does carry those three, so the allowlist is not a
  # free-standing hand list.
  f <- skew_fixture()
  expect_setequal(unique(f$method), c("mc", "searle", "burch"))
})

# The withdrawn claim wraps across lines in roxygen and in the rendered Rd, so
# a line-based grep or a `fixed = TRUE` match sees nothing while the sentence
# is plainly there -- that is how it survived in a sixth site through a whole
# implementation pass. Every absence check below runs over whitespace-collapsed
# text for that reason, and there are no carve-outs: the NEWS correction bullet
# is worded so it need not quote the phrase it withdraws.
squash <- function(x) gsub("[[:space:]]+", " ", paste(x, collapse = " "))

# Two withdrawn claims, not one. M115 withdrew "burch never under-covers"; M116
# withdrew the width ranking that shipped beside it -- `"burch"` presented as the
# broader interval and `"searle"` as the tightest on near-normal data -- which
# both measured grids contradict (data-raw/m116-classical-width-comparison.tsv).
#
# The width patterns are deliberately multi-word. A bare "narrowest" would red on
# the vignette's HPDI paragraph, which legitimately calls that interval the
# narrowest containing 95% of the posterior mass; a bare "wider" would red on
# "the wider M113 grid" and on Burch's own kurtosis-conditional statement, which
# the corrected prose reports. Each pattern below was checked to have zero hits
# across the corrected tree and at least one on the pre-correction tree.
claim_patterns <- c(
  never_undercover = "never under-cover",
  searle_narrowest_conj = "and narrowest",
  searle_narrowest_news = "narrowest on near-normal",
  searle_narrowest_hint = "narrowest)",
  burch_wider_conj = "wider, and",
  burch_wider_news = "wider and below-nominal"
)

expect_no_withdrawn_claim <- function(text, where) {
  for (nm in names(claim_patterns)) {
    testthat::expect_false(
      grepl(claim_patterns[[nm]], text, fixed = TRUE),
      info = paste0("withdrawn claim '", nm, "' still present in ", where)
    )
  }
}

test_that("no installed surface still carries a withdrawn claim", {
  expect_no_withdrawn_claim(squash(rd_flat(icc_rd())), "the installed help")

  news <- system.file("NEWS.md", package = "intraclass")
  expect_true(nzchar(news))
  expect_no_withdrawn_claim(
    squash(readLines(news, warn = FALSE)),
    "the installed NEWS"
  )

  # Resolve both vignettes BEFORE skipping: `skip_if()` aborts the whole
  # `test_that` block, not the loop iteration, so skipping inside the loop would
  # leave glossary.Rmd unchecked whenever interval-methods.Rmd is the one
  # missing. Skip only when NEITHER is installed; a partial install is a real
  # failure of this leg, not a reason to stop looking.
  vigs <- vapply(
    c("interval-methods.Rmd", "glossary.Rmd"),
    function(v) system.file("doc", v, package = "intraclass"),
    character(1)
  )
  skip_if(
    !any(nzchar(vigs)),
    "vignettes not installed (install with build_vignettes)"
  )
  for (v in names(vigs)) {
    expect_true(nzchar(vigs[[v]]), info = paste(v, "is not installed"))
    if (!nzchar(vigs[[v]])) {
      next
    }
    lines <- readLines(vigs[[v]], warn = FALSE)
    # Anti-vacuity: an empty file would satisfy every pattern silently.
    expect_gt(length(lines), 0L)
    expect_no_withdrawn_claim(squash(lines), v)
  }
})

test_that("no source file still claims it either, however the line wraps", {
  # Source-tree leg: catches the claim in files that never reach the installed
  # package (an internal comment) and in roxygen before it is rendered.
  root <- testthat::test_path("..", "..")
  paths <- file.path(
    root,
    c(
      "R/icc.R",
      "R/boundary-hint.R",
      "R/ci-classical.R",
      "vignettes/interval-methods.Rmd",
      "vignettes/glossary.Rmd",
      "NEWS.md"
    )
  )
  skip_if_not(all(file.exists(paths)), "source tree not present")

  for (path in paths) {
    text <- squash(gsub("^#'?", "", readLines(path, warn = FALSE)))
    expect_no_withdrawn_claim(text, basename(path))
  }
})

test_that("the caveat names the worst cell the fixture actually records", {
  # Attribution, not just membership: the numeral test alone would accept any
  # fixture value in any position, so a caveat quoting a real number against
  # the wrong cell would pass. This pins the prose to the row the fixture says
  # is worst.
  sec <- squash(caveat_section())
  failing <- low_abort_failures(skew_fixture())
  worst <- failing[which.min(failing$coverage_nonabort), ]

  # Substring matching is not enough here: "0.6" occurs inside "0.6725" and
  # "5" inside "0.95" and "50", so an unanchored check passes against prose
  # naming the wrong cell entirely. Every token below is matched on its own
  # numeric boundaries, and the distribution is matched by the name the prose
  # uses for it.
  num <- function(x) paste0("(?<![0-9.])", x, "(?![0-9])")
  dist_prose <- c(
    chisq1 = "chi-square\\(1\\)",
    lognormal = "lognormal",
    laplace = "Laplace",
    t5 = "t\\(5\\)",
    gaussian = "normal",
    uniform = "uniform"
  )

  expect_match(sec, num(format(worst$coverage_nonabort)), perl = TRUE)
  expect_match(sec, num(format(worst$rho)), perl = TRUE)
  expect_match(sec, num(as.character(worst$k)), perl = TRUE)
  expect_match(sec, num(as.character(worst$n)), perl = TRUE)
  expect_match(sec, dist_prose[[worst$dist]])
})

test_that("the installed help and vignette name burch's measured worst cell", {
  f <- skew_fixture()
  b <- f[f$source == "m113" & f$method == "burch", , drop = FALSE]
  worst <- format(min(b$coverage_uncond))

  expect_true(grepl(worst, rd_flat(icc_rd()), fixed = TRUE))

  vig <- system.file("doc", "interval-methods.Rmd", package = "intraclass")
  skip_if(
    !nzchar(vig),
    "vignettes not installed (install with build_vignettes)"
  )
  expect_true(any(grepl(worst, readLines(vig, warn = FALSE), fixed = TRUE)))
})

test_that("every numeral in the vignette's caveat section is a measured value", {
  # Same bar as the help page's block, applied to the article's own section.
  # Source-tree fallback keeps this meaningful in a dev session, where the
  # vignette is not installed; under `R CMD check` the shipped copy is read.
  vig <- system.file("doc", "interval-methods.Rmd", package = "intraclass")
  if (!nzchar(vig)) {
    vig <- testthat::test_path("..", "..", "vignettes", "interval-methods.Rmd")
    skip_if_not(file.exists(vig), "vignette not installed and no source tree")
  }
  lines <- readLines(vig, warn = FALSE)

  start <- grep("^### When the default under-covers", lines)
  expect_identical(length(start), 1L)
  rest <- lines[seq(start + 1L, length(lines))]
  ends <- grep("^#{2,3} ", rest)
  section <- paste(
    if (length(ends)) rest[seq_len(ends[1] - 1L)] else rest,
    collapse = " "
  )

  f <- skew_fixture()
  measured <- unique(c(
    f$rho,
    f$k,
    f$n,
    f$n_rep,
    f$abort_rate,
    f$coverage_uncond,
    f$coverage_nonabort,
    caveat_numeral_allowlist,
    95 # the nominal level, written as a percentage in prose
  ))

  numerals <- regmatches(section, gregexpr("[0-9]+(\\.[0-9]+)?", section))[[1]]
  expect_gt(length(numerals), 0L)
  for (tok in numerals) {
    expect_true(
      any(abs(measured - as.numeric(tok)) < 1e-9),
      info = paste0("numeral '", tok, "' in the vignette is not measured")
    )
  }
})

test_that("the replacement searle/burch comparison holds on the fixture", {
  # `@param ci_method` now makes two comparative claims in place of the
  # withdrawn one. They are ledgered `out` in `data-raw/mpl-doc-claims.tsv`
  # naming this test as what settles them, so they are pinned rather than
  # merely reworded -- the failure mode that produced the original claim.
  f <- skew_fixture()
  g <- f[f$source == "m113", , drop = FALSE]
  key <- function(d) paste(d$rho, d$k, d$n, d$dist, sep = "\r")

  # Claim 1: searle lands closer to nominal in most cells of EVERY family.
  for (d in unique(g$dist)) {
    sub <- g[g$dist == d, , drop = FALSE]
    s <- sub[sub$method == "searle", , drop = FALSE]
    b <- sub[sub$method == "burch", , drop = FALSE]
    b <- b[match(key(s), key(b)), , drop = FALSE]
    expect_false(anyNA(b$rho))
    searle_closer <- sum(
      abs(s$coverage_uncond - 0.95) < abs(b$coverage_uncond - 0.95)
    )
    expect_gt(searle_closer, nrow(s) / 2)
  }

  # Claim 2: burch dips below the nominal level in fewer cells overall.
  below <- function(m) {
    sum(g$method == m & g$coverage_uncond < 0.93)
  }
  expect_lt(below("burch"), below("searle"))
})

test_that("the runtime hint carries neither withdrawn claim", {
  # The blurb the user meets when the default aborts. `usable` is stubbed so
  # the bullet renders without running a method on data -- the text is what is
  # under test here, not the verification machinery around it.
  bullets <- boundary_fenced_hint(
    usable = function(method) TRUE,
    contrast = "the default",
    oneway = TRUE,
    multilevel = FALSE,
    replicates = FALSE,
    raters = 5L,
    balanced = TRUE,
    type = "agreement",
    type_supplied = FALSE,
    unit = list("single")
  )
  rendered <- gsub(
    "[[:space:]]+",
    " ",
    cli::ansi_strip(cli::format_message(bullets))
  )

  expect_match(rendered, "burch", fixed = TRUE)
  expect_match(rendered, "searle", fixed = TRUE)
  expect_no_withdrawn_claim(rendered, "the runtime hint")
  # It names the exception rather than merely dropping the claim.
  expect_match(rendered, "heavy", ignore.case = TRUE)
  # And it ranks the pair on calibration, never on width (M116): the hint is
  # where a user picks a method, so a width ranking here is the one that would
  # actually mislead. Both bullets must render for this to mean anything.
  expect_false(grepl("narrow", rendered, ignore.case = TRUE))
  expect_false(grepl("wider", rendered, ignore.case = TRUE))
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
    # `coverage_uncond` is the column that differs from `coverage_nonabort` at
    # the held-out (20, 3) cells, so leaving it unchecked would let a hand edit
    # there pass provenance.
    expect_equal(cell$coverage_uncond, sum(covered & !aborted) / nrow(reps))
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
