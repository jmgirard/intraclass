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
  pooled_pct_vignette = "about 6% narrower",
  # And M117's own first pass withdrew a third claim, at its review: that the
  # margin shrinks in the true ICC. It does not -- the M113 medians are 0.9485,
  # 0.9470 and 0.9475 at 0.05, 0.1 and 0.3, so the margin PEAKS at 0.1 and the
  # shape is flat-then-collapse. Both phrasings had zero hits on the corrected
  # surfaces and at least one on the pre-correction tree (c63a5fd).
  shrinks_in_rho = "shrinks as either grows",
  widest_few_subjects = "at a low true ICC with few subjects"
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
  # "Is there a source tree?" is not "did the walk find anything?". Under
  # `covr` the suite runs against a BUILT package in a temp dir that carries
  # `NEWS.md` but no `R/*.R` and no `vignettes/` -- a partial tree, where the
  # walk returns exactly one surface and every anti-vacuity floor below then
  # FAILS instead of skipping. That reddened the coverage job on this branch
  # while `R CMD check` stayed green, because only covr runs from that layout.
  # Gate on the files the leg exists to read. `data-raw/` stood here first and
  # is `.Rbuildignore`d, which also skips the leg in an unpacked source tarball
  # where `R/*.R` and `vignettes/` ARE present and should be swept.
  if (!length(list.files(file.path(root, "R"), pattern = "\\.R$"))) {
    return(list())
  }
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
    squash(gsub("^\\s*#+'?\\s?", "", readLines(p, warn = FALSE)))
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
#
# `k_at_n5` is the subject-count cut HOLDING the rater count at 5. It is the cut
# the docs quote, because the marginal one is confounded: k = 10 is the only
# subject count carrying n = 2, so its marginal median mixes two rater counts
# while k = 30 and k = 50 carry n = 5 alone. That is the same design fact this
# file already uses to refuse a rater-count claim, one level down.
width_cut <- function(w, grid, fac) {
  x <- w[w$grid == grid, , drop = FALSE]
  if (identical(fac, "k_at_n5")) {
    return(list(x = x[x$n == 5, , drop = FALSE], col = "k"))
  }
  list(x = x, col = fac)
}

width_level_medians <- function(w, grid, fac) {
  cut <- width_cut(w, grid, fac)
  levels_seen <- sort(unique(cut$x[[cut$col]]))
  out <- vapply(
    levels_seen,
    function(lv) round(stats::median(cut$x$ratio[cut$x[[cut$col]] == lv]), 4),
    numeric(1)
  )
  stats::setNames(out, format(levels_seen))
}

# The "narrower in N of M" counts the article's tables quote, per level.
width_level_counts <- function(w, grid, fac) {
  cut <- width_cut(w, grid, fac)
  levels_seen <- sort(unique(cut$x[[cut$col]]))
  out <- lapply(levels_seen, function(lv) {
    rows <- cut$x[cut$x[[cut$col]] == lv, , drop = FALSE]
    c(
      narrower = sum(rows$burch_narrower %in% c(TRUE, "TRUE")),
      cells = nrow(rows)
    )
  })
  stats::setNames(out, format(levels_seen))
}

# A "width sentence" is one naming burch alongside width vocabulary. The set is
# decided by the AC5 sweep plus this filter -- never by a list of sections
# someone remembered writing, which is how the two pre-existing numeral anchors
# (`@section Confidence intervals:` and `### When the default under-covers`)
# came to cover none of the width sites at all.
width_vocab <- "narrow|wider|widening|width|tighter|tightest|broader|shorter"

# Sentence splitting, with abbreviations protected. Splitting naively on
# "(?<=[.!?]) " cuts `eq. 6/13/15/16/17` and `Ch. 9 Table 9.14` in half, which
# strands the numerals in a fragment where the citation shape can no longer
# recognize them -- they then read as unchecked figures.
width_abbrevs <- c("eq", "Ch", "no", "vs", "cf", "e.g", "i.e", "Fig", "p")

width_split <- function(text) {
  masked <- text
  for (a in width_abbrevs) {
    masked <- gsub(
      paste0("\\b", gsub(".", "\\.", a, fixed = TRUE), "\\. "),
      paste0(a, "<dot> "),
      masked,
      perl = TRUE
    )
  }
  parts <- unlist(strsplit(masked, "(?<=[.!?]) ", perl = TRUE))
  gsub("<dot>", ".", parts, fixed = TRUE)
}

width_sentences <- function(text) {
  sents <- width_split(text)
  sents[
    grepl("burch", sents, ignore.case = TRUE) &
      grepl(width_vocab, sents, ignore.case = TRUE)
  ]
}

# Two legs, and both matter. The SOURCE leg reaches internal comments that never
# reach a built package; the INSTALLED leg is the only one that exists under
# `R CMD check`, where `R/`, `vignettes/` and `NEWS.md` are all absent. A pin
# that runs on the source tree alone skips in CI and pins nothing there -- the
# M115 lesson, which the first M117 pass repeated on every new block.
width_legs <- function() {
  legs <- list(
    installed = installed_doc_surfaces(),
    source = source_doc_surfaces()
  )
  legs[vapply(legs, length, integer(1)) > 0L]
}

width_surfaces_leg <- function(surfaces) {
  out <- lapply(surfaces, width_sentences)
  out[vapply(out, length, integer(1)) > 0L]
}

# The files each leg is known to carry a width statement in, measured by the AC5
# sweep (T4). Floors, not exact counts: a new surface may join, but a leg
# quietly falling below what it reached is a narrowing no assertion would
# otherwise catch.
# The source leg's floor is AC5's retired-path list, not a second hand list
# beside it: `legacy_source_paths` is defined above and is the one the criterion
# names. A second copy is exactly the stale-site shape this file warns about.

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
  sents <- width_split(text)
  hit <- which(
    grepl("burch", sents, ignore.case = TRUE) &
      grepl(width_vocab, sents, ignore.case = TRUE)
  )
  if (!length(hit)) {
    return(character(0))
  }
  idx <- sort(unique(pmax(1L, pmin(length(sents), c(hit - 1L, hit, hit + 1L)))))
  crosses_heading <- grepl("#{2,} ", sents[idx]) & !(idx %in% hit)
  keep <- idx[!crosses_heading]
  if (!length(keep)) {
    return(list())
  }
  # One file can carry several width statements far apart -- `@param ci_method`
  # and `@details` in the same roxygen block, three separate NEWS bullets. A
  # per-FILE check lets a good statement cover a weakened one: reverting the
  # conditional clause from `@param` reddened nothing, because `@details` still
  # satisfied the file. So the unit is the contiguous RUN of sentences, which is
  # the statement.
  lapply(split(keep, cumsum(c(1L, diff(keep) != 1L))), function(r) sents[r])
}

width_neighbourhoods_leg <- function(surfaces) {
  out <- list()
  for (nm in names(surfaces)) {
    runs <- width_neighbourhood(surfaces[[nm]])
    for (i in seq_along(runs)) {
      out[[paste0(nm, " #", i)]] <- runs[[i]]
    }
  }
  out
}

# Which runs must state how the ratio moves. A run that names the MARGIN or the
# ADVANTAGE is making a claim about its size, and a claim about its size that
# does not say what the size depends on is the defect this milestone exists to
# remove. A run merely mentioning the pair beside a width word -- a NEWS bullet
# pointing at the correction, the article's paragraph on Burch's own
# kurtosis-conditional ordering -- asserts no margin and is not held to it.
# The three directional clauses, stated verbatim at every site that asserts a
# margin. Keyword-proximity markers stood here and could not tell a claim from
# its reverse: "grows far past parity at 0.6" matched `icc_parity` exactly as
# "collapses to near parity" did, and a paraphrase of the withdrawn rho claim
# matched `icc_shape` on the retained word "holds". A verbatim template can be
# checked, and its levels come from the fixture rather than from the author.
width_templates <- function(w) {
  rho_levels <- sort(unique(w$rho[w$grid == "m113"]))
  parity <- max(rho_levels)
  flat_top <- max(rho_levels[rho_levels < parity])
  c(
    flat = paste0(
      "holds much the same up to a true ICC of ",
      format(flat_top),
      " rather than shrinking as the true ICC rises"
    ),
    parity = paste0(
      "collapses to near parity at a true ICC of ",
      format(parity),
      ", on the one grid reaching that value"
    ),
    subjects = paste(
      "shrinks steadily as the subject count grows,",
      "measured at 5 raters"
    )
  )
}

# How many margin-asserting statements each surface carries, measured by the
# sweep at this commit. A per-FILE floor of one let `?icc`'s `@param` block be
# gutted while `@details` kept the file satisfied; these are per-surface counts,
# so losing either reds.
width_expected_runs <- c(
  "R/icc.R" = 2L,
  "R/boundary-hint.R" = 1L,
  "R/ci-classical.R" = 1L,
  "vignettes/interval-methods.Rmd" = 1L,
  "vignettes/glossary.Rmd" = 1L,
  "NEWS.md" = 1L,
  "Rd:icc.Rd" = 2L,
  "vignette:interval-methods.Rmd" = 1L,
  "vignette:glossary.Rmd" = 1L
)

width_asserts_margin <- function(run) {
  grepl("margin|advantage", paste(run, collapse = " "), ignore.case = TRUE)
}

width_claim_runs <- function(surfaces) {
  runs <- width_neighbourhoods_leg(surfaces)
  runs[vapply(runs, width_asserts_margin, logical(1))]
}

# Numerals in a width sentence that are not measurements: citation years, the
# source's own table numbers, the nominal level, and small integers used as
# counts of things other than cells.
width_numeral_allowlist <- c(
  0, # structural zeros: MSE = 0, "divides by zero", the near-zero boundary
  1, # parity itself, and "no. 1"-style bare units
  5, # the fixed rater count the subject-count cut is measured at
  95,
  0.95 # the nominal level, as a percentage and as a proportion
)

# --- figure-to-level ASSOCIATION ----------------------------------------------
#
# The first M117 pass pinned figures by MEMBERSHIP: every numeral had to appear
# somewhere in a flat pool of measured values. That accepts any real figure in
# any position, so `| 0.6 | 0.9971 |` -> `| 0.6 | 0.9769 |` passes -- the docs
# would state a true figure against the wrong level and nothing reds. What
# follows pins the PAIR instead: which level a figure is stated against, not
# merely that the figure exists.
#
# Two shapes carry a pair, and every stated figure must be in one of them:
#   - a markdown table row in the article, under a header naming its factor;
#   - the canonical prose forms "<ratio> at a true ICC of <level>" and
#     "<ratio> at <level> subjects".
# A ratio-shaped numeral in neither shape is a free-standing figure and fails.

# The article, installed copy preferred (it is what ships and what `R CMD check`
# sees); source tree only as the dev-session fallback.
article_lines <- function() {
  vig <- system.file("doc", "interval-methods.Rmd", package = "intraclass")
  if (!nzchar(vig)) {
    vig <- testthat::test_path("..", "..", "vignettes", "interval-methods.Rmd")
  }
  if (!file.exists(vig)) {
    return(character(0))
  }
  readLines(vig, warn = FALSE)
}

# Table rows, keyed to the factor their header names. The factor resets at any
# non-table line, so a row can never inherit a header from an earlier table.
width_table_claims <- function(lines) {
  out <- list()
  orphans <- character(0)
  fac <- NA_character_
  for (ln in lines) {
    if (grepl("^\\|\\s*true ICC\\b", ln)) {
      fac <- "rho"
      next
    }
    if (grepl("^\\|\\s*subjects\\b", ln)) {
      fac <- "k_at_n5"
      next
    }
    if (!grepl("^\\|", ln)) {
      fac <- NA_character_
      next
    }
    if (grepl("^\\|[-:| ]+\\|$", ln)) {
      next
    }
    m <- regmatches(
      ln,
      regexec(
        "^\\|\\s*([0-9.]+)\\s*\\|\\s*([0-9.]+)\\s*\\|\\s*([0-9]+) of ([0-9]+)",
        ln
      )
    )[[1]]
    if (!length(m) || is.na(fac)) {
      # A ratio-bearing table row NOTHING consumes is a figure no checker
      # verifies: a data row under an unrecognized header (fac is NA), or a
      # malformed row the shape regex rejects (review return #3). Refused via
      # the orphans attribute rather than skipped.
      if (grepl(width_ratio_token, ln, perl = TRUE)) {
        orphans <- c(orphans, ln)
      }
      next
    }
    out[[length(out) + 1L]] <- list(
      factor = fac,
      level = as.numeric(m[2]),
      ratio = as.numeric(m[3]),
      narrower = as.integer(m[4]),
      cells = as.integer(m[5])
    )
  }
  attr(out, "orphans") <- orphans
  out
}

# A ratio-shaped numeral: the band the width ratios live in. Deliberately
# narrower than "any 4-decimal number" so a coverage figure in a neighbouring
# clause is not mistaken for a width figure.
width_ratio_token <- "(?<![0-9.])(0\\.[89][0-9]{3}|1\\.0[0-9]{3})(?![0-9])"

width_prose_pairs <- function(text) {
  shapes <- list(
    list(
      factor = "rho",
      re = paste0("(", width_ratio_token, ")", " at a true ICC of ([0-9.]+)")
    ),
    list(
      factor = "k_at_n5",
      re = paste0("(", width_ratio_token, ")", " at ([0-9]+) subjects")
    )
  )
  out <- list()
  for (sh in shapes) {
    m <- gregexpr(sh$re, text, perl = TRUE)
    for (hit in regmatches(text, m)[[1]]) {
      parts <- regmatches(hit, regexec(sh$re, hit, perl = TRUE))[[1]]
      out[[length(out) + 1L]] <- list(
        factor = sh$factor,
        ratio = as.numeric(parts[2]),
        level = as.numeric(parts[length(parts)])
      )
    }
  }
  out
}

# Markdown table rows are pinned by `width_table_claims()`; strip them before
# looking for prose figures so a table cell is not also read as a loose numeral.
# A whole run of table cells, not one cell at a time: `\\|[^|]*\\|` matches
# non-overlappingly, so on `| a | b | c |` it takes `| a |` and then `| c |` and
# leaves `b` behind as loose prose -- which is how three of the article's seven
# table figures first read as free-standing.
#
# But not the greedy chain either: `\\|(?:[^|]*\\|)+` matched from a surface's
# FIRST pipe to its LAST, erasing the prose between two tables before any scan
# ran (review return #3) -- `[^|]*` consumes a paragraph as happily as a cell.
# So the stripper walks pipe-delimited segments and blanks only maximal runs of
# two or more CELL-shaped segments: short (<= 60 chars) and sentence-free (no
# terminal punctuation followed by space). Prose between tables fails both and
# survives to be scanned. Boundary (claimed-classes header): a short,
# punctuation-free fragment sitting between two pipes is stripped as a cell.
width_strip_tables <- function(text) {
  pipes <- gregexpr("|", text, fixed = TRUE)[[1]]
  if (pipes[1] == -1L || length(pipes) < 3L) {
    return(text)
  }
  seg <- substring(text, head(pipes, -1L) + 1L, tail(pipes, -1L) - 1L)
  cellish <- nchar(seg) <= 60L & !grepl("[.!?] ", seg)
  run_id <- cumsum(c(TRUE, diff(cellish) != 0L))
  for (r in unique(run_id[cellish])) {
    idx <- which(run_id == r & cellish)
    if (length(idx) < 2L) {
      next
    }
    from <- pipes[idx[1]]
    to <- pipes[idx[length(idx)] + 1L]
    substr(text, from, to) <- strrep(" ", to - from + 1L)
  }
  text
}

# --- canonical shapes: the check refuses what it cannot verify ----------------
#
# Two rounds of review found the same shape of hole. The pin promised to check
# every figure the docs state, over free prose; each round closed the mutations
# that round had found and left the next one open -- `five cells` -> `nine
# cells`, `64-cell` -> `32-cell`, `four distribution families` -> `six`, a
# pooled ratio in a sentence that simply omits the word `burch`.
#
# So the promise is inverted (AC2, amended). A figure may be stated only in one
# of the CANONICAL SHAPES below, each of which carries a checker against the
# recomputed fixture; a figure-shaped token outside every shape FAILS rather
# than passing unchecked. The author's options become "write it canonically" or
# "allowlist it as a non-measurement" -- both explicit, neither silent.
#
# CLAIMED CLASSES (AC2, re-cut 2026-08-13). What this file checks -- and all
# it claims to check:
#   - the canonical shapes in `width_canonical_shapes()` and the verbatim
#     templates in `width_templates()`, each against the recomputed fixture;
#   - markdown table rows under a recognized header (association-pinned), with
#     unconsumed ratio-bearing rows refused as orphans;
#   - surface-wide: 4-decimal ratio-band tokens outside every shape, and
#     percent-ish tokens in width-vocabulary sentences, refused;
#   - in width neighbourhoods: digit figures outside the allowlist, and spelled
#     cardinals (up to two non-stopword qualifiers) before a measure noun,
#     refused.
# NOT claimed -- tokens outside these classes are not checked here, by design
# (the narrowed AC2 promise; review is the net for them): figures equal to an
# allowlisted value (0, 1, 5, 95, 0.95); percent figures at a nominal level
# (90/95/99) or 100; spelled forms beyond the cardinal list or carrying three
# or more qualifiers; figures in sentences with no width vocabulary; short
# punctuation-free fragments between pipes, which strip as table cells
# (`width_strip_tables`).
#
# `re` is matched over the squashed surface text; group 1..n feed `ok`, which
# recomputes from the fixture and returns TRUE when the stated figure is right.
width_canonical_shapes <- function(w) {
  rho_levels <- sort(unique(w$rho[w$grid == "m113"]))
  parity <- max(rho_levels)
  flat_top <- max(rho_levels[rho_levels < parity])
  med <- function(g, fac) width_level_medians(w, g, fac)
  cnt <- function(g, fac) width_level_counts(w, g, fac)
  near <- function(a, b) length(b) == 1L && abs(a - b) < 1e-9
  lvl_of <- function(m, x) {
    i <- which(abs(as.numeric(names(m)) - x) < 1e-9)
    if (length(i) == 1L) m[[i]] else numeric(0)
  }
  list(
    # <ratio> at a true ICC of <level> -- per-rho figures are M113's alone (AC4)
    ratio_rho = list(
      re = paste0("(", width_ratio_token, ") at a true ICC of ([0-9.]+)"),
      ok = function(p) {
        near(as.numeric(p[2]), lvl_of(med("m113", "rho"), as.numeric(p[4])))
      }
    ),
    # <ratio> at <level> subjects -- either grid may supply it; the completeness
    # block below is what stops one grid's figure standing in for the other's
    ratio_k = list(
      re = paste0("(", width_ratio_token, ") at ([0-9]+) subjects"),
      ok = function(p) {
        any(vapply(
          c("m113", "m76"),
          function(g) {
            near(as.numeric(p[2]), lvl_of(med(g, "k_at_n5"), as.numeric(p[4])))
          },
          logical(1)
        ))
      }
    ),
    # <count> of <total> cells of the <grid> grid -- the grid is part of the
    # shape, so a real total attributed to the wrong grid fails
    grid_total = list(
      re = "([0-9]+) of ([0-9]+) cells of the (larger|smaller) grid",
      ok = function(p) {
        sizes <- vapply(split(w, w$grid), nrow, integer(1))
        g <- names(sizes)[
          if (identical(p[4], "larger")) {
            which.max(sizes)
          } else {
            which.min(sizes)
          }
        ]
        rows <- w[w$grid == g, , drop = FALSE]
        as.integer(p[2]) == sum(rows$burch_narrower %in% c(TRUE, "TRUE")) &&
          as.integer(p[3]) == nrow(rows)
      }
    ),
    families = list(
      re = "([A-Za-z]+|[0-9]+) distribution families",
      ok = function(p) {
        width_num_value(p[2]) == length(unique(w$dist[w$grid == "m113"]))
      }
    ),
    # which level carries the largest margin -- the article states it, so it
    # is checked rather than left as an unbacked aside
    argmax = list(
      re = "the largest margin is at a true ICC of ([0-9.]+)",
      ok = function(p) {
        m <- med("m113", "rho")
        low <- m[as.numeric(names(m)) < parity]
        near(as.numeric(p[2]), as.numeric(names(low)[which.min(low)]))
      }
    ),
    # the two canonical level references the directional templates carry
    tmpl_flat = list(
      re = paste0(
        "holds much the same up to a true ICC of ([0-9.]+) rather than ",
        "shrinking as the true ICC rises"
      ),
      ok = function(p) near(as.numeric(p[2]), flat_top)
    ),
    tmpl_parity = list(
      re = "collapses to near parity at a true ICC of ([0-9.]+)",
      ok = function(p) near(as.numeric(p[2]), parity)
    ),
    # "the two grids" is a figure too: it says how many grids there are
    n_grids = list(
      re = "the (two) grids",
      ok = function(p) {
        width_cardinal_value(p[2]) == length(unique(w$grid))
      }
    ),
    # Source citations are not repo measurements. This shape verifies nothing --
    # it exists so a citation's numerals are CONSUMED rather than allowlisted as
    # bare integers, which would let a real figure of the same value through.
    citation = list(
      re = "Ch\\. [0-9]+|Tables? [0-9.]+|eq\\.? [0-9/]+|\\((19|20)[0-9]{2}\\)|\\b(1971|1996|2011)\\b",
      ok = function(p) TRUE
    ),
    # the one grid that reaches the parity level -- a claim about the design,
    # and the hedge three sites were missing
    one_grid = list(
      re = "on the one grid reaching that value",
      ok = function(p) {
        sum(vapply(
          unique(w$grid),
          function(g) any(w$rho[w$grid == g] == parity),
          logical(1)
        )) ==
          1L
      }
    ),
    # "the larger grid's 64 cells" / "the smaller grid's 16 cells"
    grid_size = list(
      re = "(larger|smaller) grid's ([0-9]+) cells",
      ok = function(p) {
        sizes <- vapply(
          split(w, w$grid),
          nrow,
          integer(1)
        )
        want <- if (identical(p[2], "larger")) max(sizes) else min(sizes)
        as.integer(p[3]) == want
      }
    ),
    worst_coverage = list(
      re = "worst ([0-9.]+)",
      ok = function(p) {
        f <- skew_fixture()
        v <- as.numeric(p[2])
        any(abs(c(f$coverage_uncond, f$coverage_nonabort) - v) < 1e-9)
      }
    ),
    # bare level references, consumed only after the templates above have taken
    # theirs, so a level named outside a template still has to be a real level
    rho_level = list(
      re = "a true ICC of ([0-9.]+)",
      ok = function(p) as.numeric(p[2]) %in% w$rho
    ),
    k_level = list(
      re = "([0-9]+) subjects",
      ok = function(p) as.integer(p[2]) %in% w$k
    ),
    # per-level narrower counts stated in prose rather than in a table row
    level_count = list(
      re = "([0-9]+) of ([0-9]+) cells at ([0-9.]+) subjects",
      ok = function(p) {
        cts <- cnt("m113", "k_at_n5")
        i <- which(abs(as.numeric(names(cts)) - as.numeric(p[4])) < 1e-9)
        length(i) == 1L &&
          as.integer(p[2]) == cts[[i]][["narrower"]] &&
          as.integer(p[3]) == cts[[i]][["cells"]]
      }
    )
  )
}

width_cardinals <- c(
  one = 1,
  two = 2,
  three = 3,
  four = 4,
  five = 5,
  six = 6,
  seven = 7,
  eight = 8,
  nine = 9,
  ten = 10,
  eleven = 11,
  twelve = 12,
  thirteen = 13,
  fourteen = 14,
  fifteen = 15,
  sixteen = 16,
  seventeen = 17,
  eighteen = 18,
  nineteen = 19,
  twenty = 20,
  thirty = 30,
  forty = 40,
  fifty = 50,
  sixty = 60,
  hundred = 100
)

width_cardinal_value <- function(x) {
  # Unknown words return NA rather than erroring, so a shape that matched a
  # non-cardinal word ("further distribution families") FAILS its `ok` check
  # instead of crashing the scan.
  if (tolower(x) %in% names(width_cardinals)) {
    unname(width_cardinals[[tolower(x)]])
  } else {
    NA_real_
  }
}

# A figure written either way. Spelled cardinals are how `five cells` -> `nine
# cells` slipped a digits-only net.
width_num_value <- function(x) {
  if (grepl("^[0-9]+$", x)) as.integer(x) else width_cardinal_value(x)
}

# Nouns that make a preceding number a MEASUREMENT rather than ordinary English.
# "the narrower of the two" is prose; "five cells" is a figure. Restricting the
# spelled-numeral rule to this list is what keeps it from reddening on every
# sentence containing the word "one".
width_measure_nouns <- paste0(
  "cells?|subjects?|raters?|grids?|families|",
  "distribution families|values?|levels?|percentage points?|sweeps?"
)

# Replace every canonical match with a placeholder and report which shapes
# matched, so the residue can be scanned for figures nothing checks.
width_consume <- function(text, shapes) {
  claims <- list()
  for (nm in names(shapes)) {
    sh <- shapes[[nm]]
    hits <- regmatches(text, gregexpr(sh$re, text, perl = TRUE))[[1]]
    for (h in hits) {
      parts <- regmatches(h, regexec(sh$re, h, perl = TRUE))[[1]]
      claims[[length(claims) + 1L]] <- list(
        shape = nm,
        text = h,
        ok = isTRUE(sh$ok(parts))
      )
    }
    text <- gsub(sh$re, " <figure> ", text, perl = TRUE)
  }
  list(residue = text, claims = claims)
}

# --- the three refusal scans, as callable helpers -------------------------
#
# Named functions rather than test-body code so the mutation harness
# (data-raw/m117-width-pin-mutations.R, prose leg) runs the SAME scans the
# suite runs -- a duplicated scanner would drift apart from the one it claims
# to exercise.

# Spelled cardinals before a measure noun, allowing up to two qualifying
# words ("four ADDITIONAL distribution families" slipped the adjacent-only
# net at review return #3); stopwords excluded so "one of the grids" stays
# prose.
width_spelled_re <- function() {
  paste0(
    "\\b(",
    paste(names(width_cardinals), collapse = "|"),
    ")(?:[ -](?!of\\b|the\\b|and\\b|or\\b|in\\b|to\\b|a\\b)[a-z]+){0,2}[ -](",
    width_measure_nouns,
    ")\\b"
  )
}

# Unchecked figures inside one width neighbourhood run: spelled figures the
# cardinal net catches, and digit tokens outside the allowlist, after every
# canonical shape and table row is consumed.
width_unchecked_figures <- function(run_text, shapes) {
  got <- width_consume(width_strip_tables(run_text), shapes)
  residue <- gsub(
    "[A-Za-z][A-Za-z._-]*[0-9]+[A-Za-z0-9._-]*",
    " ",
    got$residue
  )
  spilled <- unlist(regmatches(
    residue,
    gregexpr(width_spelled_re(), residue, perl = TRUE, ignore.case = TRUE)
  ))
  numerals <- unlist(regmatches(
    residue,
    gregexpr("[0-9]+(\\.[0-9]+)?", residue)
  ))
  numerals <- numerals[
    !vapply(
      numerals,
      function(tok) any(abs(width_numeral_allowlist - as.numeric(tok)) < 1e-9),
      logical(1)
    )
  ]
  list(
    claims = got$claims,
    spelled = spilled,
    numerals = numerals
  )
}

# Ratio-band tokens no canonical shape consumes, surface-wide (a pooled ratio
# needs no method name to mislead).
width_loose_ratios <- function(surface_text, shapes) {
  residue <- width_consume(
    width_strip_tables(surface_text),
    shapes[c("ratio_rho", "ratio_k")]
  )$residue
  unlist(regmatches(
    residue,
    gregexpr(width_ratio_token, residue, perl = TRUE)
  ))
}

# Percent figures in width-vocabulary sentences, surface-wide. A digit-%
# whose number is a nominal level (90/95/99) or 100 is not a width
# measurement; the percent WORDS are refused unconditionally.
width_pct_violations <- function(surface_text) {
  pct <- "[0-9](\\.[0-9]+)?\\s*%|\\b(per ?cent|percentage points?)\\b"
  sents <- width_split(surface_text)
  widthy <- sents[grepl(width_vocab, sents, ignore.case = TRUE)]
  bad <- widthy[grepl(pct, widthy, ignore.case = TRUE, perl = TRUE)]
  bad <- bad[vapply(
    bad,
    function(s) {
      hits <- regmatches(
        s,
        gregexpr("[0-9]+(\\.[0-9]+)?(?=\\s*%)", s, perl = TRUE)
      )[[1]]
      words <- grepl(
        "\\b(per ?cent|percentage points?)\\b",
        s,
        ignore.case = TRUE,
        perl = TRUE
      )
      words || any(!as.numeric(hits) %in% c(90, 95, 99, 100))
    },
    logical(1)
  )]
  list(bad = bad, scanned = length(widthy))
}

# Does a stated (factor, level, ratio) match the recomputed median? Per-rho
# figures must come from M113 alone (AC4); the subject-count cut is stated for
# both grids, so either may supply the match.
width_pair_matches <- function(w, pair) {
  grids <- if (identical(pair$factor, "rho")) "m113" else c("m113", "m76")
  for (g in grids) {
    med <- width_level_medians(w, g, pair$factor)
    i <- which(abs(as.numeric(names(med)) - pair$level) < 1e-9)
    if (length(i) == 1L && abs(med[[i]] - pair$ratio) < 1e-9) {
      return(TRUE)
    }
  }
  FALSE
}

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
  by_k <- width_level_medians(w, "m113", "k_at_n5")

  expect_identical(names(by_rho), c("0.05", "0.10", "0.30", "0.60"))
  expect_identical(names(by_k), c("10", "30", "50"))

  # 1. The advantage is FLAT and clear of parity below rho = 0.6, then gone.
  #    Flat, not shrinking: the three sub-0.6 medians span under half a
  #    percentage point and do not decrease in order. Four doc sites said
  #    "shrinks as either grows"; on these very figures the margin GROWS from
  #    0.05 to 0.1, and this is the assertion that reds if it comes back.
  low <- by_rho[c("0.05", "0.10", "0.30")]
  expect_true(all(low < 0.96))
  expect_lt(diff(range(low)), 0.005)
  expect_false(all(diff(low) > 0))
  expect_gt(by_rho[["0.60"]], 0.99)
  expect_lt(by_rho[["0.60"]], 1)

  # 2. It shrinks monotonically in the subject count, on BOTH grids -- which is
  #    what lets the docs state that direction without naming a grid. The cut
  #    holds the rater count at 5; the marginal cut is confounded (below).
  expect_true(all(diff(by_k) > 0))
  expect_true(all(diff(width_level_medians(w, "m76", "k_at_n5")) > 0))

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

  # And the consequence for the SUBJECT-count figures, which is what sends the
  # docs to the 5-rater cut: the marginal and stratified medians are the same
  # row wherever a subject count carries n = 5 alone, and differ at k = 10.
  # A marginal k = 10 figure would therefore be reporting the rater count.
  for (g in c("m76", "m113")) {
    marginal <- width_level_medians(w, g, "k")
    fixed <- width_level_medians(w, g, "k_at_n5")
    expect_equal(unname(marginal[c("30", "50")]), unname(fixed[c("30", "50")]))
    expect_gt(abs(marginal[["10"]] - fixed[["10"]]), 0.01)
  }
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

  # And the specific gap the docs now name. Three surfaces attributed the
  # rho = 0.6 parity finding to "the two grids"; only one grid reaches that
  # value, so the smaller one cannot have shown it. This is the fact that
  # licenses "on the one grid reaching that value".
  expect_false(any(w$rho[w$grid == "m76"] == 0.6))
  expect_true(any(w$rho[w$grid == "m113"] == 0.6))
})

test_that("the article's width tables state the median for the level named", {
  # The association pin. Every row is checked against the median RECOMPUTED for
  # that row's own level, so swapping two rows' figures reds even though both
  # figures are real.
  lines <- article_lines()
  skip_if(
    !length(lines),
    "the article is neither installed nor in a source tree"
  )
  claims <- width_table_claims(lines)
  expect_identical(
    length(attr(claims, "orphans")),
    0L,
    info = paste(
      "ratio-bearing table row(s) no checker consumes:",
      paste(attr(claims, "orphans"), collapse = " // ")
    )
  )
  fac_of <- vapply(claims, function(cl) cl$factor, character(1))

  # Anti-vacuity and completeness in one: the article states every level of both
  # factors, so a dropped row reds here rather than silently narrowing the pin.
  expect_identical(sum(fac_of == "rho"), 4L)
  expect_identical(sum(fac_of == "k_at_n5"), 3L)

  w <- width_fixture()
  for (cl in claims) {
    med <- width_level_medians(w, "m113", cl$factor)
    cnt <- width_level_counts(w, "m113", cl$factor)
    i <- which(abs(as.numeric(names(med)) - cl$level) < 1e-9)
    where <- paste0(cl$factor, " = ", cl$level)
    expect_identical(length(i), 1L, info = where)
    expect_equal(cl$ratio, unname(med[[i]]), info = where)
    expect_identical(cl$narrower, unname(cnt[[i]][["narrower"]]), info = where)
    expect_identical(cl$cells, unname(cnt[[i]][["cells"]]), info = where)
  }
})

test_that("the article states the smaller grid's subject-count medians too", {
  # The pair check accepts either grid, because "0.9646 at 30 subjects" names no
  # grid and both are legitimately quoted. That leaves one hole: swapping the
  # smaller grid's figure for the larger grid's at the same level would pass.
  # Completeness closes it -- all three of the smaller grid's 5-rater medians
  # must be stated, so a substituted one goes missing here.
  lines <- article_lines()
  skip_if(
    !length(lines),
    "the article is neither installed nor in a source tree"
  )
  text <- squash(lines)
  med <- width_level_medians(width_fixture(), "m76", "k_at_n5")
  for (lv in names(med)) {
    expect_match(
      text,
      paste0(format(med[[lv]], nsmall = 4), " at ", lv, " subjects"),
      fixed = TRUE,
      info = paste("the smaller grid's median at", lv, "subjects is not stated")
    )
  }
})

test_that("every canonical width figure matches the recomputed value", {
  w <- width_fixture()
  shapes <- width_canonical_shapes(w)
  legs <- width_legs()
  expect_gt(length(legs), 0L)
  seen <- 0L

  for (leg in names(legs)) {
    runs <- width_neighbourhoods_leg(legs[[leg]])
    for (nm in names(runs)) {
      got <- width_consume(
        width_strip_tables(paste(runs[[nm]], collapse = " ")),
        shapes
      )
      for (cl in got$claims) {
        expect_true(
          cl$ok,
          info = paste0(leg, "/", nm, ": '", cl$text, "' (", cl$shape, ")")
        )
        seen <- seen + 1L
      }
    }
  }
  # Anti-vacuity: the shapes must actually be matching. Floor is the count the
  # article alone carries, so a surface dropping out cannot take the pin with
  # it unnoticed.
  expect_gte(seen, 10L)
})

test_that("no width statement carries a figure nothing checks", {
  # The inversion AC2 asks for. After every canonical shape and every table row
  # is consumed, whatever numeral is left in a width statement is a figure no
  # checker has verified -- so it fails here rather than shipping unchecked.
  w <- width_fixture()
  shapes <- width_canonical_shapes(w)
  legs <- width_legs()
  expect_gt(length(legs), 0L)

  for (leg in names(legs)) {
    runs <- width_neighbourhoods_leg(legs[[leg]])
    for (nm in names(runs)) {
      found <- width_unchecked_figures(
        paste(runs[[nm]], collapse = " "),
        shapes
      )
      expect_identical(
        length(found$spelled),
        0L,
        info = paste0(
          leg,
          "/",
          nm,
          ": unchecked spelled figure(s) ",
          paste(found$spelled, collapse = ", ")
        )
      )
      expect_identical(
        length(found$numerals),
        0L,
        info = paste0(
          leg,
          "/",
          nm,
          ": figure(s) in no canonical shape and not allowlisted: ",
          paste(found$numerals, collapse = ", ")
        )
      )
    }
  }
})

test_that("every ratio-shaped figure on a swept surface is bound to a level", {
  # Surface-wide, NOT scoped to sentences naming a method: a grid-wide pooled
  # ratio escaped the previous pin simply by omitting the word `burch`
  # (AC4). A ratio-shaped token that no canonical shape and no table row
  # consumes is by construction not bound to any level.
  w <- width_fixture()
  # `width_loose_ratios` consumes only the two ratio-bearing shapes: the rest
  # are level and count shapes whose patterns legitimately match unrelated
  # help text elsewhere on a surface, and consuming those would say nothing
  # about a loose ratio.
  shapes <- width_canonical_shapes(w)
  legs <- width_legs()
  expect_gt(length(legs), 0L)

  for (leg in names(legs)) {
    for (nm in names(legs[[leg]])) {
      loose <- width_loose_ratios(legs[[leg]][[nm]], shapes)
      expect_identical(
        length(loose),
        0L,
        info = paste0(
          leg,
          "/",
          nm,
          ": ratio(s) stated with no level attached -- ",
          paste(loose, collapse = ", ")
        )
      )
    }
  }
})

test_that("no width sentence carries a percentage figure", {
  # The ancestral defect form: "about 6% / about 4% narrower" was the pooled
  # percentage M116 withdrew, and a NEW pooled percentage ("about 5% narrower
  # overall") is ratio-shaped to a reader while matching no ratio token and no
  # canonical shape. No shape states a width percentage, so any percent-ish
  # token in a sentence carrying width vocabulary is a figure nothing checks --
  # refused outright, surface-wide (a pooled figure needs no method name).
  # A percent FIGURE, not any percent sign: Rd comment lines open with `%`,
  # and sprintf/formatC code carries `%s` and `width = 8` in the same
  # "sentence", so a bare `%` net reds on machinery. Nominal levels and
  # knitr's `out.width = "100%"` are likewise not width measurements; see
  # `width_pct_violations` for the exact boundary.
  legs <- width_legs()
  expect_gt(length(legs), 0L)
  seen <- 0L
  for (leg in names(legs)) {
    for (nm in names(legs[[leg]])) {
      got <- width_pct_violations(legs[[leg]][[nm]])
      seen <- seen + got$scanned
      expect_identical(
        length(got$bad),
        0L,
        info = paste0(
          leg,
          "/",
          nm,
          ": percentage figure in a width sentence -- ",
          paste(got$bad, collapse = " // ")
        )
      )
    }
  }
  # Anti-vacuity: the width sentences were actually found and scanned.
  expect_gte(seen, 10L)
})

test_that("every width statement names the shape in ICC and in subject count", {
  # AC3, enforced by canonical clause rather than by keyword proximity. A
  # statement that asserts a margin must carry all three clauses verbatim, so a
  # reversal, a paraphrase, or a dropped grid hedge each red.
  w <- width_fixture()
  templates <- width_templates(w)
  legs <- width_legs()
  expect_gt(length(legs), 0L)

  for (leg in names(legs)) {
    runs <- width_claim_runs(legs[[leg]])
    surfaces <- unique(sub(" #[0-9]+$", "", names(runs)))
    for (e in names(width_expected_runs)) {
      if (!e %in% names(legs[[leg]])) {
        next
      }
      expect_true(
        sum(startsWith(names(runs), paste0(e, " #"))) >=
          width_expected_runs[[e]],
        info = paste(leg, e, "lost a width margin statement")
      )
    }
    expect_gt(length(surfaces), 0L)

    for (nm in names(runs)) {
      text <- paste(runs[[nm]], collapse = " ")
      for (tm in names(templates)) {
        expect_true(
          grepl(templates[[tm]], text, fixed = TRUE),
          info = paste0(leg, "/", nm, ": no verbatim '", tm, "' clause")
        )
      }
    }
  }
})

test_that("no width statement makes a rater-count claim", {
  # Two rules with two scopes, because they fail differently.
  #
  # The FORBIDDEN patterns are specific enough to run over every width
  # statement: a rater-count comparison, a quoted rater level the design
  # confounds, or an affirmative "no rater effect" finding the design cannot
  # support. (`no rater` used to be a LICENSING marker, which let "there is no
  # rater effect on the width margin" pass as though it were a disclaimer.)
  #
  # The LICENSED requirement -- any rater mention must name the fixed stratum
  # or say the contrast is confounded -- runs only over statements that assert
  # a margin. Over every width statement it reddens on the article's MPL
  # paragraph, whose "fixed raters" is about the design a method serves and has
  # nothing to do with width.
  forbidden <- paste0(
    "\\b(2|two|10|ten|20|twenty)[- ]raters?\\b",
    "|no rater[- a-z]*(effect|dependence|sensitivity|influence)",
    "|raters? than"
  )
  licensed <- "5[- ]raters?|5-rater|confound|not separable"

  legs <- width_legs()
  expect_gt(length(legs), 0L)
  for (leg in names(legs)) {
    for (nm in names(width_neighbourhoods_leg(legs[[leg]]))) {
      for (s in width_neighbourhoods_leg(legs[[leg]])[[nm]]) {
        expect_false(
          grepl(forbidden, s, ignore.case = TRUE, perl = TRUE),
          info = paste0(leg, "/", nm, ": states a rater-count width effect")
        )
      }
    }
    for (nm in names(width_claim_runs(legs[[leg]]))) {
      for (s in width_claim_runs(legs[[leg]])[[nm]]) {
        if (grepl("rater", s, ignore.case = TRUE)) {
          expect_match(
            s,
            licensed,
            ignore.case = TRUE,
            perl = TRUE,
            info = paste0(leg, "/", nm, ": unlicensed rater mention")
          )
        }
      }
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
