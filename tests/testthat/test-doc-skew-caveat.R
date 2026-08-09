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

# The source-tree `data-raw/` dir, absent from a built package. Defined here
# rather than beside the provenance blocks at the foot of the file: a later
# definition is not in scope for the earlier width-fixture block that also
# guards on it.
data_raw_dir <- testthat::test_path("..", "..", "data-raw")

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
  burch_wider_news = "wider and below-nominal",
  # M117 withdrew the POOLED width figure that M116's correction put in place.
  # It was true of each grid as a whole and false of most of it: the margin
  # runs from about a fourteenth at 10 subjects to parity at a true ICC of 0.6,
  # so one number per grid told a reader nothing they could use. Both patterns
  # were checked to have zero hits across the corrected surfaces and one hit
  # each on the pre-correction tree (641f036).
  pooled_pct_param = "about 6% and about 4%",
  pooled_pct_vignette = "about 6% narrower"
)

expect_no_withdrawn_claim <- function(text, where) {
  for (nm in names(claim_patterns)) {
    testthat::expect_false(
      grepl(claim_patterns[[nm]], text, fixed = TRUE),
      info = paste0("withdrawn claim '", nm, "' still present in ", where)
    )
  }
}

# The site set is decided by a WALK, never by a remembered list (M117). Six
# hand-listed paths stood here through M115 and M116; a hand list is the shape
# that ships a stale site the moment a surface is added, because nothing
# reminds anyone to extend it. Both legs below enumerate their own domain, and
# each asserts that the walk still reaches every path the old list named -- so
# widening the sweep cannot silently narrow it.
legacy_source_paths <- c(
  "R/icc.R",
  "R/boundary-hint.R",
  "R/ci-classical.R",
  "vignettes/interval-methods.Rmd",
  "vignettes/glossary.Rmd",
  "NEWS.md"
)

# Every documentation surface the INSTALLED package carries: the whole Rd
# database (not just icc.Rd), every installed vignette, the installed NEWS.
installed_doc_surfaces <- function() {
  out <- list()
  db <- tryCatch(tools::Rd_db("intraclass"), error = function(e) NULL)
  if (is.null(db)) {
    # `load_all` has no Rd database; parse the source Rd instead, which is the
    # same content pre-install. Under `R CMD check` the branch above is taken.
    man <- list.files(
      testthat::test_path("..", "..", "man"),
      pattern = "\\.Rd$",
      full.names = TRUE
    )
    db <- stats::setNames(lapply(man, tools::parse_Rd), basename(man))
  }
  for (nm in names(db)) {
    out[[paste0("Rd:", nm)]] <- squash(rd_flat(db[[nm]]))
  }

  doc_dir <- system.file("doc", package = "intraclass")
  if (nzchar(doc_dir)) {
    vigs <- list.files(doc_dir, pattern = "\\.(Rmd|md)$", full.names = TRUE)
    for (v in vigs) {
      out[[paste0("vignette:", basename(v))]] <- squash(
        readLines(v, warn = FALSE)
      )
    }
  }

  news <- system.file("NEWS.md", package = "intraclass")
  if (nzchar(news)) {
    out[["NEWS.md"]] <- squash(readLines(news, warn = FALSE))
  }
  out
}

# Every documentation-bearing file in the SOURCE tree: all of R/ (roxygen and
# internal comments alike), all of vignettes/, and NEWS.md.
source_doc_surfaces <- function() {
  root <- testthat::test_path("..", "..")
  paths <- c(
    list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE),
    list.files(
      file.path(root, "vignettes"),
      pattern = "\\.Rmd$",
      full.names = TRUE
    ),
    file.path(root, "NEWS.md")
  )
  paths <- paths[file.exists(paths)]
  out <- lapply(paths, function(p) {
    squash(gsub("^#'?", "", readLines(p, warn = FALSE)))
  })
  stats::setNames(out, sub(paste0("^", root, "/"), "", paths))
}

test_that("no installed surface still carries a withdrawn claim", {
  surfaces <- installed_doc_surfaces()

  # Anti-vacuity, three ways: the walk found surfaces at all, it found the
  # help page the claims actually lived in, and no surface is an empty string
  # (every `expect_false(grepl(...))` passes on one).
  expect_gt(length(surfaces), 0L)
  expect_true("Rd:icc.Rd" %in% names(surfaces))
  expect_true(all(nzchar(unlist(surfaces))))

  # Sweep everything the walk found FIRST. A `skip_if` aborts the whole
  # `test_that`, not one assertion (M116), so a vignette-presence skip placed
  # above this loop would take the Rd and NEWS checks down with it -- which is
  # exactly what the dev-session run does when vignettes are not installed.
  for (nm in names(surfaces)) {
    expect_no_withdrawn_claim(surfaces[[nm]], nm)
  }
})

test_that("the installed surfaces include both vignettes", {
  # Separated from the sweep above so its skip cannot suppress that sweep. A
  # PARTIAL install is a real failure here, not a reason to stop looking; only
  # a build with no vignettes at all skips.
  vig_names <- grep("^vignette:", names(installed_doc_surfaces()), value = TRUE)
  skip_if(
    length(vig_names) == 0L,
    "vignettes not installed (install with build_vignettes)"
  )
  for (v in c("interval-methods.Rmd", "glossary.Rmd")) {
    expect_true(paste0("vignette:", v) %in% vig_names, info = v)
  }
})

test_that("no source file still claims it either, however the line wraps", {
  # Source-tree leg: catches the claim in files that never reach the installed
  # package (an internal comment) and in roxygen before it is rendered.
  surfaces <- source_doc_surfaces()
  skip_if(length(surfaces) == 0L, "source tree not present")

  # The walk must still reach everything the retired hand list named, and must
  # reach strictly more than it did -- otherwise "widened" would be a claim no
  # one checks.
  expect_true(all(legacy_source_paths %in% names(surfaces)))
  expect_gt(length(surfaces), length(legacy_source_paths))
  expect_true(all(nzchar(unlist(surfaces))))

  for (nm in names(surfaces)) {
    expect_no_withdrawn_claim(surfaces[[nm]], nm)
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

# --- M117: the burch/searle width relationship, stated conditionally ----------
# The docs used to state one pooled figure per grid ("about 6% and about 4%
# narrower"). It hid two dependences: the advantage shrinks in the true ICC and
# in the subject count, reaching parity at rho = 0.6 where every reversing cell
# sits. These blocks hold the replacement prose to the fixture.
width_fixture_path <- testthat::test_path(
  "fixtures",
  "classical-width-by-cell.tsv"
)

width_fixture <- function() {
  utils::read.delim(width_fixture_path, stringsAsFactors = FALSE)
}

# Recomputed here from the per-cell rows, never read from the generator's own
# summary block: the point is that the docs' figures survive an independent
# derivation, not that two files agree.
width_level_medians <- function(w, grid, fac) {
  x <- w[w$grid == grid, , drop = FALSE]
  levels_seen <- sort(unique(x[[fac]]))
  out <- vapply(
    levels_seen,
    function(lv) round(stats::median(x$ratio[x[[fac]] == lv]), 4),
    numeric(1)
  )
  stats::setNames(out, format(levels_seen))
}

# A "width sentence" is one naming burch alongside width vocabulary. The set is
# decided by the AC5 sweep plus this filter -- never by a list of sections
# someone remembered writing, which is how the two pre-existing numeral anchors
# (`@section Confidence intervals:` and `### When the default under-covers`)
# came to cover none of the width sites at all.
width_vocab <- "narrow|wider|widening|width|tighter|tightest|broader|shorter"

width_sentences <- function(text) {
  sents <- unlist(strsplit(text, "(?<=[.!?]) ", perl = TRUE))
  sents[
    grepl("burch", sents, ignore.case = TRUE) &
      grepl(width_vocab, sents, ignore.case = TRUE)
  ]
}

width_surfaces <- function() {
  out <- lapply(source_doc_surfaces(), width_sentences)
  out[vapply(out, length, integer(1)) > 0L]
}

# A width STATEMENT is usually more than the one sentence naming the method: the
# condition attaches in the next sentence, which repeats neither "burch" nor a
# width word, and a forbidden rater figure would land there too. So the two
# checks about what the passage says run over each width sentence plus its
# immediate neighbours. The numeral check deliberately does NOT use this window
# -- neighbouring sentences carry coverage figures and citations belonging to
# other claims, which have their own pins.
#
# Neighbours are bounded by markdown headings: without that, the window walks
# out of the classical-intervals section and into the MPL one, whose "fixed
# raters" is about the design a method serves, not about width.
width_neighbourhood <- function(text) {
  sents <- unlist(strsplit(text, "(?<=[.!?]) ", perl = TRUE))
  hit <- which(
    grepl("burch", sents, ignore.case = TRUE) &
      grepl(width_vocab, sents, ignore.case = TRUE)
  )
  if (!length(hit)) {
    return(character(0))
  }
  idx <- sort(unique(pmax(1L, pmin(length(sents), c(hit - 1L, hit, hit + 1L)))))
  crosses_heading <- grepl("#{2,} ", sents[idx]) & !(idx %in% hit)
  sents[idx[!crosses_heading]]
}

width_neighbourhoods <- function() {
  out <- lapply(source_doc_surfaces(), width_neighbourhood)
  out[vapply(out, length, integer(1)) > 0L]
}

# Numerals in a width sentence that are not measurements: citation years, the
# source's own table numbers, the nominal level, and small integers used as
# counts of things other than cells.
width_numeral_allowlist <- c(
  1, # "in every cell", "no. 1" style bare units, and the parity value itself
  2, # "the two grids"
  1971, # Searle (1971)
  1996, # McGraw & Wong (1996)
  2011, # Burch (2011)
  9.14, # Searle's Table 9.14
  7, # McGraw & Wong's Table 7
  95,
  0.95 # the nominal level, as a percentage and as a proportion
)

test_that("the width fixture re-derives from the data-raw comparison", {
  skip_if_not(dir.exists(data_raw_dir), "data-raw/ not present (built package)")

  # The data-raw file carries three stacked blocks with three different
  # headers, and `read.delim` would take the first one it meets and then choke
  # on the wider rows below. Slice the per-cell block by its own header line.
  lines <- readLines(
    file.path(data_raw_dir, "m116-classical-width-comparison.tsv"),
    warn = FALSE
  )
  start <- grep("^grid\trho\tk\tn\tdist\t", lines)
  expect_identical(length(start), 1L)
  block <- lines[seq(start, length(lines))]
  block <- block[nzchar(block) & !startsWith(block, "#")]
  src <- utils::read.delim(
    text = paste(block, collapse = "\n"),
    stringsAsFactors = FALSE
  )

  w <- width_fixture()
  expect_identical(nrow(w), 80L)
  expect_identical(sort(unique(w$grid)), c("m113", "m76"))

  # Keyed rather than positional, so a reordering of either file cannot hide a
  # changed value.
  key <- function(d) paste(d$grid, d$rho, d$k, d$n, d$dist, sep = "\r")
  expect_identical(nrow(src), nrow(w))
  matched <- src[match(key(w), key(src)), , drop = FALSE]
  expect_false(anyNA(matched$grid))
  expect_equal(matched$ratio, w$ratio)
  expect_equal(matched$burch_width, w$burch_width)
  expect_equal(matched$searle_width, w$searle_width)
  expect_identical(matched$burch_narrower, w$burch_narrower)
})

test_that("the width figures the docs state are recomputed from the cells", {
  w <- width_fixture()

  # The M113 grid is the one the docs derive from: the only grid varying rho.
  by_rho <- width_level_medians(w, "m113", "rho")
  by_k <- width_level_medians(w, "m113", "k")

  expect_identical(names(by_rho), c("0.05", "0.10", "0.30", "0.60"))
  expect_identical(names(by_k), c("10", "30", "50"))

  # 1. The advantage is flat and clear of parity below rho = 0.6, then gone.
  expect_true(all(by_rho[c("0.05", "0.10", "0.30")] < 0.96))
  expect_gt(by_rho[["0.60"]], 0.99)
  expect_lt(by_rho[["0.60"]], 1)

  # 2. It shrinks monotonically in the subject count, on BOTH grids -- which is
  #    what lets the docs state that direction without naming a grid.
  expect_true(all(diff(by_k) > 0))
  expect_true(all(diff(width_level_medians(w, "m76", "k")) > 0))

  # 3. Every reversing cell sits at rho = 0.6.
  expect_true(all(w$rho[!(w$burch_narrower %in% c(TRUE, "TRUE"))] == 0.6))
})

test_that("the rater count is confounded with the subject count, marginally", {
  # This is what licenses the docs stating no rater-count width effect. It is a
  # claim about the MARGINAL contrast only: n = 2 never occurs away from
  # k = 10, so the n = 5 margin is the only one carrying k in {30, 50}. At
  # fixed k the contrast IS separable and points the other way, which is
  # precisely why a marginal per-n figure would mislead.
  w <- width_fixture()
  expect_true(all(w$k[w$n == 2] == 10))
  expect_true(all(c(2, 5) %in% unique(w$n)))
  expect_gt(sum(w$n == 2), 0L)
})

test_that("M76's design is contained in M113's on (rho, k, n)", {
  # The containment that made a pooled per-grid figure read as a between-grid
  # difference when it was really M113's extra rho levels.
  w <- width_fixture()
  combos <- function(g) {
    x <- w[w$grid == g, c("rho", "k", "n")]
    sort(unique(paste(x$rho, x$k, x$n, sep = "|")))
  }
  expect_true(all(combos("m76") %in% combos("m113")))
  expect_gt(length(combos("m113")), length(combos("m76")))
})

test_that("every width statement names the true ICC and the subject count", {
  # Over the neighbourhood, not the bare claim sentence: the condition reads
  # better as its own sentence, and requiring it inside the sentence naming the
  # method would be a demand about prose style, not about what is stated.
  surfaces <- width_neighbourhoods()
  # Anti-vacuity: the sweep must actually find width statements, or every
  # assertion below passes over an empty set.
  skip_if(length(surfaces) == 0L, "source tree not present")
  expect_gte(length(surfaces), 5L)

  for (nm in names(surfaces)) {
    text <- paste(surfaces[[nm]], collapse = " ")
    expect_match(
      text,
      "true ICC|ICC of|rho",
      ignore.case = TRUE,
      info = paste(
        nm,
        "states a width relationship without conditioning on ICC"
      )
    )
    expect_match(
      text,
      "subject",
      ignore.case = TRUE,
      info = paste(nm, "states a width relationship without naming subjects")
    )
  }
})

test_that("no width statement mentions the rater count", {
  # A sufficient condition, deliberately stronger than "states no rater-count
  # width effect": a sentence that never says "rater" cannot state one. The
  # stronger form is what is decidable -- and the marginal figure it forbids is
  # the one the design confounds.
  surfaces <- width_neighbourhoods()
  skip_if(length(surfaces) == 0L, "source tree not present")

  for (nm in names(surfaces)) {
    for (s in surfaces[[nm]]) {
      expect_false(
        grepl("rater", s, ignore.case = TRUE),
        info = paste0(nm, ": width sentence mentions raters -- '", s, "'")
      )
    }
  }
})

test_that("every numeral in a width statement is a measured value", {
  w <- width_fixture()
  surfaces <- width_surfaces()
  skip_if(length(surfaces) == 0L, "source tree not present")

  measured <- unique(c(
    unlist(lapply(c("m76", "m113"), function(g) {
      c(
        width_level_medians(w, g, "rho"),
        width_level_medians(w, g, "k"),
        unique(w$rho[w$grid == g]),
        unique(w$k[w$grid == g]),
        # cell and reversal counts the prose is allowed to quote
        sum(w$grid == g),
        sum(w$grid == g & w$burch_narrower %in% c(TRUE, "TRUE")),
        sum(w$grid == g & !(w$burch_narrower %in% c(TRUE, "TRUE"))),
        # per-level and per-family cell counts, and the "narrower in N of M"
        # counts the tables quote
        unlist(lapply(c("dist", "rho", "k", "n"), function(fac) {
          parts <- split(w[w$grid == g, ], w[[fac]][w$grid == g])
          c(
            vapply(parts, nrow, numeric(1)),
            vapply(
              parts,
              function(x) sum(x$burch_narrower %in% c(TRUE, "TRUE")),
              numeric(1)
            )
          )
        }))
      )
    })),
    width_numeral_allowlist
  ))

  for (nm in names(surfaces)) {
    # Identifiers are not figures: milestone ids (M76, M117), fixture filenames
    # (m116-classical-width-comparison.tsv), distribution labels (t5, chisq1).
    # Strip any token whose digits are glued to letters, rather than
    # allowlisting each -- an allowlist would grow forever and would also
    # allowlist the bare integer everywhere else it appeared. Case-insensitive
    # by construction: the lowercase filename form slipped an `\\bM[0-9]+\\b`
    # rule and shipped `116` as an unmeasured figure.
    text <- gsub(
      "[A-Za-z][A-Za-z._-]*[0-9]+[A-Za-z0-9._-]*",
      " ",
      surfaces[[nm]]
    )
    numerals <- unlist(regmatches(
      text,
      gregexpr("[0-9]+(\\.[0-9]+)?", text)
    ))
    for (tok in numerals) {
      expect_true(
        any(abs(measured - as.numeric(tok)) < 1e-9),
        info = paste0(nm, ": numeral '", tok, "' is not a measured value")
      )
    }
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
