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

# Line-leading markup is stripped BEFORE the join, never after. A markdown
# blockquote is the case that got past M123's first pass: the README's
# withdrawn Bayesian-roadmap sentence lives inside a `> [!NOTE]` callout and
# wraps as `> ... A Bayesian engine` / `> is on the roadmap`, so joining first
# leaves the marker mid-sentence -- `... A Bayesian engine > is on the roadmap
# ...` -- against which every pattern below returned FALSE while the sentence
# was plainly there. Same failure mode as the roxygen `#'` prefix the source
# leg already strips, one markup character later.
strip_blockquote <- function(lines) {
  gsub("^[[:space:]]*>+[[:space:]]?", "", lines)
}

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
  widest_few_subjects = "at a low true ICC with few subjects",
  # M119 withdrew a fourth claim: that no grid this package has measured varies
  # the residual, so Burch's own reversal is untested here. M118 built exactly
  # that grid and the reversal reproduced (its fixture is
  # `fixtures/width-reversal-by-cell.tsv`), so every phrasing of "neither grid
  # tests it" is now false rather than merely bounded. Each pattern below was
  # checked to have zero hits across the corrected surfaces and at least one on
  # the pre-correction tree (c0a7500).
  residual_neither_tests = "which neither grid tests",
  residual_neither_varies = "which neither grid varies",
  residual_not_cover = "a case those grids do not cover",
  residual_do_not_vary = "which those grids do not vary",
  residual_vary_only = "Both grids vary only the subject effect",
  residual_subject_only = "measured it only in the subject-effect-only case",
  residual_draw_only = "both grids draw only the",
  # M123 withdrew four CAPABILITY claims -- statements the docs made that the
  # package's own code falsifies. They join this vector rather than start a
  # second one: D-029 asks for an extension of the instrument M115-M119 each
  # appended into, and a numeric pattern simply does not match README prose, so
  # "the domain differs" buys nothing but a fork.
  #
  # What this set promises is exactly the spellings listed and nothing wider. A
  # recall-fixed list of phrasings is the shape M118 watched lose four rounds
  # running, each to a spelling the previous round had not imagined, so no
  # criterion here quantifies over "any future rewording". The guarantee is: a
  # maintainer restoring one of THESE sentences, at any surface either walk
  # reaches and however the line wraps -- blockquote included -- reds.
  #
  # (1) The brms engine has shipped -- `R/engine-brms.R`, `engine = "brms"` in
  # `icc()`'s validated set, `ci_method = "posterior"` -- but the README kept
  # promising it as future work. Three spellings: the one that actually
  # shipped, plus two a plausible re-edit would reach for.
  bayes_roadmap = "Bayesian engine is on the roadmap",
  bayes_planned = "Bayesian engine is planned",
  bayes_not_yet = "Bayesian engine is not yet",
  # (2) The engine enumeration that omitted brms. Matched with the connective
  # so it cannot fire on a legitimate two-engine sentence elsewhere. Backticked
  # AND bare, because `rd_flat()` is `rapply(as.character)` over the parsed Rd
  # and discards `\code{}`: the flattened help database carries no backticks at
  # all (measured across the whole flattened help database: 0 backticks on all
  # seven pages, against 846 in `R/icc.R`), so a backticked-only pattern is
  # inert on `Rd:*` -- and under `R CMD check` the source leg returns `list()`,
  # leaving the installed leg the only leg. That leg reads `Rd:*` AND `NEWS.md`,
  # `README.md` and the installed vignettes, which a comment here once denied.
  # Two false comments have stood in this spot: one claiming no surface renders
  # these sentences without their markup, one claiming `Rd:*` is the only class
  # running under check. Both cost a review return.
  engines_omit_brms = "(`glmmTMB`, `lme4`) or an SEM engine",
  engines_omit_brms_bare = "(glmmTMB, lme4) or an SEM engine",
  # (3) The base-install list naming four of the six non-base Imports. Same
  # backticked/bare pair for the same reason. The alphabetised variant that
  # stood here is gone: it encoded a PACKAGE SET rather than a falsehood, so
  # dropping `lifecycle` or `tibble` from `Imports:` would have made the
  # CORRECTED sentence match and be reported as a withdrawn claim.
  install_four_marked = "only `glmmTMB`, `cli`, `rlang`, and `generics`",
  install_four_bare = "only glmmTMB, cli, rlang, and generics",
  # (4) The multilevel design claim, contradicted by the shipped `design`
  # argument and by the same vignette's own later section. Anchored to the
  # clause it shipped in: a bare "you never declare it" is four words of
  # ordinary English swept over all of `R/` including internal comments, and
  # would red on a future true sentence about any other inferred argument.
  design_never_declare = "from the data — you never declare it",
  design_never_declare_alt = "you never declare the design",
  # M123's fifth and sixth CLAIMS (its tenth and eleventh spellings), added at
  # its second review return: prose
  # attributing the declared dependency list to what an installation
  # RETRIEVES. Both shipped on this branch. Installing the package pulls the
  # whole recursive closure of the six declared Imports -- `glmmTMB` alone
  # brings `lme4` -- so "the install pulls" over a six-name list is false, and
  # naming one further arrival beside the word "light" understates it. The
  # second spelling deliberately takes only the singular clause: the statement
  # that `glmmTMB` imports `lme4` is TRUE, and pinning that would report a true
  # sentence as a withdrawn claim.
  install_pulls_news = "package the install pulls",
  install_arrives_readme = "so that one arrives with the default engine",
  # M126's three claims (its twelfth through sixteenth spellings). All three
  # described the install's FOOTPRINT from the `Suggests:` placement alone,
  # which is what `glmmTMB`'s own `Imports: lme4` falsifies: an installation
  # retrieves lme4 whatever this package declares, so "does not require them"
  # and "stays light" both understate it, and glmmTMB is not "the one required
  # dependency" in any sense a reader checking their library would recognise.
  #
  # The first two are anchored THROUGH the adjacent `Suggests` token, in a
  # backticked and a bare form, for the reason the M123 pairs above exist:
  # `Rd:*` flattening discards `\code{}` markup, so a backticked-only pattern
  # is inert there. The bare clauses on their own are too short to anchor --
  # "so the base install stays light" is ordinary English that a future TRUE
  # sentence about some other package could carry.
  #
  # The third takes no pair: its shipped sentence carried no markup at all, so
  # a backticked form would be byte-identical to the bare one. It is anchored
  # through "the recommended default" for the same reason -- "it is the one
  # required dependency" alone is six words that a true sentence about a
  # genuinely single-dependency package would trip.
  #
  # All five are named `install_*` so the mutation harness's two-way name check
  # (`data-raw/m123-capability-claim-mutations.R`) binds them without widening
  # its own recall-fixed prefix list.
  install_not_required_marked = "in `Suggests`, so intraclass does not require them",
  install_not_required_bare = "in Suggests, so intraclass does not require them",
  install_light_marked = "live in `Suggests`, so the base install stays light",
  install_light_bare = "live in Suggests, so the base install stays light",
  install_one_required_dep = "the recommended default \u2014 it is the one required dependency"
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
        strip_blockquote(readLines(v, warn = FALSE))
      )
    }
  }

  news <- system.file("NEWS.md", package = "intraclass")
  if (nzchar(news)) {
    out[["NEWS.md"]] <- squash(strip_blockquote(readLines(news, warn = FALSE)))
  }

  # M123: `README.md` ships in the tarball (it is not `.Rbuildignore`d) and is
  # the pkgdown home page, so it is a user-facing surface on the installed side
  # too, not only in the source tree.
  readme <- system.file("README.md", package = "intraclass")
  if (nzchar(readme)) {
    out[["README.md"]] <- squash(
      strip_blockquote(readLines(readme, warn = FALSE))
    )
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
    file.path(root, "NEWS.md"),
    # M123: both READMEs. `README.Rmd` is the SOURCE a maintainer edits and is
    # `.Rbuildignore`d, so the installed leg can never see it -- a claim
    # restored there and left un-knitted would pass every other check until the
    # next `devtools::build_readme()` republished it. `README.md` is swept on
    # both legs because it ships in the tarball AND is the pkgdown home page.
    file.path(root, "README.Rmd"),
    file.path(root, "README.md")
  )
  paths <- paths[file.exists(paths)]
  out <- lapply(paths, function(p) {
    # Roxygen/comment prefix first, then the blockquote marker: a roxygen line
    # can itself carry one (`#' > note`), never the reverse.
    lines <- gsub("^\\s*#+'?\\s?", "", readLines(p, warn = FALSE))
    squash(strip_blockquote(lines))
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
  # The names are hard-coded ON PURPOSE. M123 briefly derived them from the
  # `vignettes/*.Rmd` glob, which reads as a widening but is a narrowing: under
  # `R CMD check` the root is `<pkg>.Rcheck`, which carries no `vignettes/`, so
  # the glob came back empty and the whole block skipped -- in the one layout
  # CI runs. A hard list needs no source tree and cannot go vacuous. Deriving
  # the list from the installed side instead (so a renamed vignette is caught)
  # is deferred to the candidate row carrying the pin's reachability apparatus.
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

test_that("the source walk reads every README surface the layout carries", {
  # Anti-vacuity for the two surfaces M123 added: every
  # `expect_false(grepl(...))` passes on an empty string (M116), so the sweep
  # must be shown to have READ them before its silence means anything.
  #
  # Asserted PER FILE against what is on disk, not as a flat membership pair.
  # `README.Rmd` is `.Rbuildignore`d, so an unpacked source tarball carries
  # `R/` and `vignettes/` (the leg runs) but no `README.Rmd` -- where a bare
  # `all(c("README.Rmd", "README.md") %in% ...)` FAILS rather than skips. CI
  # never caught that: `R CMD check` runs from `.Rcheck` with no `R/` at all.
  root <- testthat::test_path("..", "..")
  surfaces <- source_doc_surfaces()
  skip_if(length(surfaces) == 0L, "source tree not present")

  on_disk <- c("README.Rmd", "README.md")
  on_disk <- on_disk[file.exists(file.path(root, on_disk))]
  # A layout carrying neither README is not a layout this leg can vacuously
  # pass in: `README.md` ships in the tarball, so at least one is always there.
  expect_gt(length(on_disk), 0L)
  expect_true(all(on_disk %in% names(surfaces)))
  expect_true(all(nzchar(unlist(surfaces[on_disk]))))

  for (nm in on_disk) {
    expect_no_withdrawn_claim(surfaces[[nm]], nm)
  }
})

test_that("the installed walk reads README.md when the package is installed", {
  # `README.md` is not `.Rbuildignore`d, so a real install carries it.
  #
  # This block does NOT skip under `load_all`, and a comment here once said it
  # did. `pkgload`'s `system.file()` shim falls back to the package ROOT, so
  # `system.file("README.md")` returns the source file and this leg re-reads
  # what the source leg already swept -- the M116 shadowing, one file over.
  # Measured: under `load_all` it resolves to the checkout, under a real
  # install to the library tree. So a dev-session pass here says nothing about
  # the installed leg; only `test_dir(load_package = "installed")` does, which
  # is what M123's evidence runs and what its harness plants against.
  readme <- system.file("README.md", package = "intraclass")
  skip_if(!nzchar(readme), "README.md not resolvable")
  surfaces <- installed_doc_surfaces()
  expect_true("README.md" %in% names(surfaces))
  expect_true(nzchar(surfaces[["README.md"]]))
  expect_no_withdrawn_claim(surfaces[["README.md"]], "README.md")
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

# M118's third grid, the one that draws BOTH components from the cell's family.
# The two fixtures are never merged: they measure different data-generating
# rules and their columns differ (this one is a per-cell summary carrying
# `median_ratio`, the M117 one a per-cell ratio). Everything M119 states about
# the residual reads from this file; everything M117 states about the margin
# reads from the other.
residual_fixture_path <- testthat::test_path(
  "fixtures",
  "width-reversal-by-cell.tsv"
)

residual_fixture <- function() {
  utils::read.delim(
    residual_fixture_path,
    comment.char = "#",
    stringsAsFactors = FALSE
  )
}

# The decision block of M118's grid: Burch's own Fig. 2 design (`n = 5`,
# `rho = 0.5`, k = 10(10)100) over his six symmetric Table 2 families. The
# other two blocks are validation and comparison and support no doc claim.
residual_fig2 <- function(r) r[r$block == "fig2", , drop = FALSE]

# How a family is written in prose, mapped to the fixture's own `dist` label. A
# prose name outside this map fails its shape rather than matching nothing:
# an unmapped name would otherwise leave the figure beside it unconsumed, which
# the unchecked-figure scan then reports -- but reporting a stray numeral says
# nothing about the family the claim named, and naming the family is the point.
residual_family_labels <- function() {
  list(
    "uniform" = "uniform",
    "powexp" = "powexp",
    "normal" = "gaussian",
    "t(10)" = "t10",
    "Laplace" = "laplace",
    "t(5)" = "t5"
  )
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
#
# `hits` is the sentence predicate deciding which sentences seed a run. The
# default is the width one; M119's residual walk passes its own and reuses the
# window, the heading bound and the contiguous-run split unchanged, so the two
# walks cannot drift apart in how they cut a statement out of a surface.
width_hits <- function(sents) {
  grepl("burch", sents, ignore.case = TRUE) &
    grepl(width_vocab, sents, ignore.case = TRUE)
}

width_neighbourhood <- function(text, hits = width_hits) {
  sents <- width_split(text)
  hit <- which(hits(sents))
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

width_neighbourhoods_leg <- function(surfaces, hits = width_hits) {
  out <- list()
  for (nm in names(surfaces)) {
    runs <- width_neighbourhood(surfaces[[nm]], hits)
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
    # The grid hedge is part of the template (AC9): the flat shape is the
    # larger grid's; the smaller grid's margin DOES shrink across its levels
    # (direction pinned by "the flat clause's grid hedge..." below), so the
    # un-hedged clause was false of one of the two grids it read as
    # describing.
    flat = paste0(
      "holds much the same up to a true ICC of ",
      format(flat_top),
      " rather than shrinking as the true ICC rises",
      " (on the larger grid; the smaller grid's margin does shrink",
      " across its levels)"
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
#     templates in `width_templates()`, each against the recomputed fixture,
#     with every reported claim's ok verdict enforced SURFACE-WIDE (round 5)
#     except the two bare level shapes noted in the not-claimed list;
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
# (`width_strip_tables`); bare level references (`rho_level`/`k_level`)
# OUTSIDE width neighbourhoods — they consume as aids surface-wide, but their
# membership verdicts are enforced only beside a width claim, since a bare
# level in unrelated prose is not a width figure.
#
# `re` is matched over the squashed surface text; group 1..n feed `ok`, which
# recomputes from the fixture and returns TRUE when the stated figure is right.
width_canonical_shapes <- function(w, r = residual_fixture()) {
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
    # M119: a median ratio from the BOTH-components grid, at the family and
    # subject count it names. Consumed before `k_level` below, so the "100
    # subjects" inside it is never re-read as a bare M117 level reference --
    # 100 is not a subject count either committed M117 grid carries. The family
    # is matched through `residual_family_labels`, so a real figure attributed
    # to the wrong family fails rather than passing on the number alone.
    ratio_family = list(
      re = paste0(
        "a median width ratio of ([0-9]\\.[0-9]{4}) at ",
        "([A-Za-z]+\\([0-9]+\\)|[A-Za-z]+) with ([0-9]+) subjects"
      ),
      ok = function(p) {
        fam <- residual_family_labels()[[p[3]]]
        if (is.null(fam)) {
          return(FALSE)
        }
        f <- residual_fig2(r)
        cell <- f[f$dist == fam & f$k == as.integer(p[4]), , drop = FALSE]
        nrow(cell) == 1L &&
          abs(round(cell$median_ratio, 4) - as.numeric(p[2])) < 1e-9
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
    # which level carries the largest margin -- true at the level-median cut,
    # contradicted cell by cell (11 of 16 paired cells put it at the bottom
    # level), so the claim must STATE ITS CUT: the qualified form is checked
    # against the medians, and the bare form fails outright rather than
    # passing via the loose level shapes below (AC9). `argmax_cut` is
    # consumed first, so `argmax_bare` sees only unqualified statements.
    argmax_cut = list(
      re = "by level medians the largest margin is at a true ICC of ([0-9.]+)",
      ok = function(p) {
        m <- med("m113", "rho")
        low <- m[as.numeric(names(m)) < parity]
        near(as.numeric(p[2]), as.numeric(names(low)[which.min(low)]))
      }
    ),
    argmax_bare = list(
      re = "largest margin is at a true ICC of ([0-9.]+)",
      ok = function(p) FALSE
    ),
    # the paired-cell contradiction beside the cut-qualified claim: within the
    # larger grid, pair its two lowest-rho levels' cells on (k, n, dist) and
    # count where the margin is larger at the bottom level
    paired_cells = list(
      re = "in ([0-9]+) of ([0-9]+) paired cells",
      ok = function(p) {
        lv <- sort(unique(w$rho[w$grid == "m113"]))[1:2]
        a <- w[w$grid == "m113" & w$rho == lv[1], ]
        b <- w[w$grid == "m113" & w$rho == lv[2], ]
        key <- function(d) paste(d$k, d$n, d$dist)
        a <- a[order(key(a)), ]
        b <- b[order(key(b)), ]
        identical(key(a), key(b)) &&
          as.integer(p[2]) == sum(a$ratio < b$ratio) &&
          as.integer(p[3]) == nrow(a)
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
    # "the two grids" is a figure too: it says how many grids there are. M119
    # adds the third: "two" still means the pair that varies only the subject
    # effect (the M117 fixture's own `grid` column), and "three" means those
    # plus M118's both-components grid. That grid is ONE grid in three blocks --
    # its blocks share a data-generating rule and differ only in design points --
    # so it counts once, and the count is conditioned on its fixture actually
    # carrying rows rather than being asserted as a literal.
    n_grids = list(
      re = "the (two|three) grids",
      ok = function(p) {
        subject_only <- length(unique(w$grid))
        want <- if (identical(p[2], "two")) {
          subject_only
        } else {
          subject_only + as.integer(nrow(residual_fig2(r)) > 0L)
        }
        width_cardinal_value(p[2]) == want
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
    shapes[c("ratio_rho", "ratio_k", "ratio_family")]
  )$residue
  unlist(regmatches(
    residue,
    gregexpr(width_ratio_token, residue, perl = TRUE)
  ))
}

# Surface-wide enforcement of the ordered scan's reported claims (AC2, round
# 5): every claim's ok verdict is enforced wherever on the surface it sits — a
# false canonical-form figure outside a width neighbourhood was consumed
# unchecked before (review round 4, F1). The two bare level shapes are the
# exception: they still consume as aids, but a bare level reference in
# unrelated prose is not a width figure ("100 subjects" in the article), so
# their membership verdicts are enforced only inside width neighbourhoods.
width_surface_claim_failures <- function(surface_text, shapes) {
  got <- width_consume(width_strip_tables(surface_text), shapes)
  bad <- Filter(
    function(cl) !cl$ok && !cl$shape %in% c("rho_level", "k_level"),
    got$claims
  )
  out <- vapply(
    bad,
    function(cl) paste0(cl$text, " (", cl$shape, ")"),
    character(1)
  )
  attr(out, "n_claims") <- length(got$claims)
  out
}

# The rater rules, as one callable: forbidden patterns over every width
# neighbourhood sentence, the licensed requirement over margin-asserting runs
# (scopes per the rater test's own rationale).
width_rater_violations <- function(surface_text) {
  forbidden <- paste0(
    "\\b(2|two|10|ten|20|twenty)[- ]raters?\\b",
    "|no rater[- a-z]*(effect|dependence|sensitivity|influence)",
    "|raters? than"
  )
  licensed <- "5[- ]raters?|5-rater|confound|not separable"
  bad <- character(0)
  runs <- width_neighbourhood(surface_text)
  for (run in runs) {
    for (s in run) {
      if (grepl(forbidden, s, ignore.case = TRUE, perl = TRUE)) {
        bad <- c(bad, paste0("forbidden rater claim: ", s))
      }
    }
    if (width_asserts_margin(run)) {
      for (s in run) {
        if (
          grepl("rater", s, ignore.case = TRUE) &&
            !grepl(licensed, s, ignore.case = TRUE, perl = TRUE)
        ) {
          bad <- c(bad, paste0("unlicensed rater mention: ", s))
        }
      }
    }
  }
  bad
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

test_that("the flat clause's grid hedge matches the per-grid recomputation", {
  # AC9. The hedged template says the larger grid's sub-parity margin holds
  # much the same while the smaller grid's does shrink. Both facts recomputed
  # from the per-cell rows: the larger grid's sub-parity medians sit within
  # tolerance of one another, and the smaller grid's median ratio RISES from
  # its lower to its upper level -- its margin shrinking, the other way.
  w <- width_fixture()
  m113 <- width_level_medians(w, "m113", "rho")
  parity <- max(as.numeric(names(m113)))
  sub <- m113[as.numeric(names(m113)) < parity]
  expect_lt(max(sub) - min(sub), 0.005)
  m76 <- width_level_medians(w, "m76", "rho")
  o <- order(as.numeric(names(m76)))
  expect_lt(m76[[o[1]]], m76[[o[2]]])
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

test_that("every reported canonical claim is enforced surface-wide", {
  # AC2 (round 5): the ordered scan's reported claims are enforced on their
  # ok verdicts wherever they sit, not only inside width neighbourhoods —
  # review round 4's F1 placed a false canonical-form figure ("0.8123 at a
  # true ICC of 0.3") outside every neighbourhood and the suite stayed green.
  w <- width_fixture()
  shapes <- width_canonical_shapes(w)
  legs <- width_legs()
  expect_gt(length(legs), 0L)
  seen <- 0L
  for (leg in names(legs)) {
    for (nm in names(legs[[leg]])) {
      fails <- width_surface_claim_failures(legs[[leg]][[nm]], shapes)
      seen <- seen + attr(fails, "n_claims")
      expect_identical(
        length(fails),
        0L,
        info = paste0(leg, "/", nm, ": ", paste(fails, collapse = " // "))
      )
    }
  }
  # Anti-vacuity: the article alone reports 20+ claims, so a scan finding far
  # fewer has stopped matching, not gone clean.
  expect_gte(seen, 30L)
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
  # Both rules live in `width_rater_violations()` so the mutation harness runs
  # the same scan this test does (one definition, no drift).
  legs <- width_legs()
  expect_gt(length(legs), 0L)
  for (leg in names(legs)) {
    for (nm in names(legs[[leg]])) {
      bad <- width_rater_violations(legs[[leg]][[nm]])
      expect_identical(
        length(bad),
        0L,
        info = paste0(leg, "/", nm, ": ", paste(bad, collapse = " // "))
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

# --- M119: what the three grids jointly measure about the residual ------------
#
# For three milestones the shipped prose bounded Burch's own reversal claim by
# saying no grid this package has measured varies the residual. M118 built that
# grid -- both `A_i` and `e_ij` drawn from the cell's family, located and scaled
# per burch2011 sec 3 -- and the reversal reproduced at 10 of 10 subject counts
# on both limbs (D-030). So the bound is not merely stale: the sentences that
# state it are false.
#
# The site set is decided by a WALK, exactly as the M117 blocks above decide
# theirs, and for the same reason: a list of paths recorded in the milestone
# file ships a stale site the moment a surface is added. The walk reuses
# `width_neighbourhood()` with its own sentence predicate, so the two cannot
# drift apart in how a statement is cut out of a surface.
#
# A RESIDUAL sentence names a measured GRID beside the variance component that
# grid draws from. That pairing is what makes a sentence a claim about which
# component the measured grids vary. The two obvious predicates both fail: a
# sentence naming Burch beside the word "error" reaches the abort-remedy prose
# ("it names a method only after running it", "honest disclosure, not an
# error"), which mentions `"burch"` and has nothing to do with any grid, and
# "residual" alone reaches the variance-component glossary. Requiring the grid
# AND the component is what cuts the set down to the sentences that make the
# claim -- 6 source statements and their mirrors, measured by the walk below.
#
# The component is the RESIDUAL specifically, never the subject effect: every
# grid here varies the subject effect, so a sentence naming it makes no claim
# about what distinguishes them. Seeding on it as well split the NEWS bullet in
# two, the second seed being a corrected M117 scope clause ("Both grids that
# vary only the subject effect say otherwise") that asserts nothing about the
# residual and is not this milestone's to reword.
residual_vocab <- "residual|error term|errors\\b"

residual_hits <- function(sents) {
  grepl("\\bgrids?\\b", sents, ignore.case = TRUE, perl = TRUE) &
    grepl(residual_vocab, sents, ignore.case = TRUE, perl = TRUE)
}

# The seed predicate above is deliberately loose about context, and on its own
# it reaches two vignettes' `expand.grid()` code chunks, which sit in the same
# squashed "sentence" as the word `residual` and assert nothing about any
# measured grid. So a run is kept only if the STATEMENT names Burch somewhere in
# it. Naming him is what makes a grid one of the measured ones here.
#
# The burch test is at run level and not at sentence level on purpose: the
# article states the design fact and attributes the reversal in two adjacent
# sentences, and neither carries both halves.
residual_runs_leg <- function(surfaces) {
  runs <- width_neighbourhoods_leg(surfaces, residual_hits)
  Filter(
    function(run) any(grepl("burch", run, ignore.case = TRUE)),
    runs
  )
}

# How many residual statements each surface carries, measured by the walk at
# this commit. Floors, not exact counts, on the M117 rationale: a new surface
# may join, but a surface quietly dropping its statement is a narrowing no
# other assertion would catch. `R/icc.R` carries two (the `@param ci_method`
# block and the `@details` block) and its Rd mirror carries them both.
residual_expected_runs <- c(
  "R/icc.R" = 2L,
  "R/ci-classical.R" = 1L,
  "vignettes/interval-methods.Rmd" = 1L,
  "vignettes/glossary.Rmd" = 1L,
  "NEWS.md" = 1L,
  "Rd:icc.Rd" = 2L,
  "vignette:interval-methods.Rmd" = 1L,
  "vignette:glossary.Rmd" = 1L
)

# The one clause every residual statement carries verbatim. Its shape follows
# `width_templates()` for the same reason M117 chose a verbatim template over
# keyword proximity: "the residual matters" and "the residual does not matter"
# share every keyword, so only the literal text can tell a claim from its
# reverse. Its figure and its subject count come from the fixture, not from the
# author, and the `ratio_family` canonical shape re-checks them where they sit.
#
# No method name and no backticks: the clause ships into roxygen, an Rd
# rendering of the same roxygen, two vignettes and NEWS, which mark up code
# spans differently, and `rd_flat()` flattens the Rd markup away. M117's
# templates avoid both for the same reason.
residual_template <- function(r) {
  f <- residual_fig2(r)
  k_top <- max(f$k)
  cell <- f[f$dist == "t5" & f$k == k_top, , drop = FALSE]
  stopifnot(nrow(cell) == 1L)
  c(
    residual = paste0(
      "the two grids that vary only the subject effect put it narrower ",
      "nearly everywhere, while the third, which draws the residual from ",
      "the same family as the subject effect, puts it wider at every ",
      "symmetric heavy-tailed family measured (a median width ratio of ",
      format(round(cell$median_ratio, 4), nsmall = 4),
      " at t(5) with ",
      format(k_top),
      " subjects) and narrower at every lighter-tailed one, the normal ",
      "included"
    )
  )
}

# M117's margin figures are true of the two subject-effect-only grids and false
# of M118's, so a surface naming "the two grids" now has to say WHICH two. The
# scope clause is required verbatim and in the same sentence -- not adjacent to
# the phrase, because `?icc` reads "on the two grids this package has measured
# that vary only the subject effect", and not by keyword, because "the two grids
# that hold the residual Gaussian" says the same thing in words no fixture can
# be checked against. A paraphrase of a scope is how a scope quietly widens.
#
# Three phrasings name the pair across the surfaces ("the two grids", "both
# grids", "both measured grids"), so the scan takes all three: policing only the
# one `?icc` happens to use would leave the NEWS bullet and the `ci-classical.R`
# header free to widen silently. Two scope markers are accepted because the
# surfaces write the scope two ways, and both are verbatim.
residual_scope_clauses <- c(
  "that vary only the subject effect",
  "subject-effect-only"
)

residual_pair_names <- "the two grids|both (measured |committed )?grids"

residual_scope_violations <- function(surface_text) {
  sents <- width_split(surface_text)
  named <- grepl(residual_pair_names, sents, ignore.case = TRUE, perl = TRUE)
  scoped <- Reduce(
    `|`,
    lapply(residual_scope_clauses, function(cl) grepl(cl, sents, fixed = TRUE))
  )
  bad <- sents[named & !scoped]
  list(bad = substr(bad, 1, 160), scanned = sum(named))
}

test_that("no surface names the two grids without saying which two", {
  legs <- width_legs()
  expect_gt(length(legs), 0L)
  seen <- 0L
  for (leg in names(legs)) {
    for (nm in names(legs[[leg]])) {
      got <- residual_scope_violations(legs[[leg]][[nm]])
      seen <- seen + got$scanned
      expect_identical(
        length(got$bad),
        0L,
        info = paste0(leg, "/", nm, ": ", paste(got$bad, collapse = " // "))
      )
    }
  }
  # Anti-vacuity: the phrase is actually present and was actually scanned.
  expect_gte(seen, 4L)
})

test_that("every residual statement the walk finds states what three grids measure", {
  r <- residual_fixture()
  templates <- residual_template(r)
  legs <- width_legs()
  expect_gt(length(legs), 0L)

  for (leg in names(legs)) {
    runs <- residual_runs_leg(legs[[leg]])
    for (e in names(residual_expected_runs)) {
      if (!e %in% names(legs[[leg]])) {
        next
      }
      expect_true(
        sum(startsWith(names(runs), paste0(e, " #"))) >=
          residual_expected_runs[[e]],
        info = paste(leg, e, "lost a residual statement")
      )
    }
    # Anti-vacuity: the walk found statements at all on this leg.
    expect_gt(length(runs), 0L)

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

test_that("the residual clause's direction is what the third grid measures", {
  # AC2's consistency leg for the qualitative half of the clause. "Wider at
  # every symmetric heavy-tailed family measured" and "narrower at every
  # lighter-tailed one, the normal included" are recomputed here from the
  # decision block rather than read off the reference page, so a regenerated
  # fixture that moved a family across 1 reds the clause it no longer supports.
  f <- residual_fig2(residual_fixture())
  heavy <- c("t10", "laplace", "t5")
  lighter <- c("uniform", "powexp", "gaussian")
  expect_setequal(unique(f$dist), c(heavy, lighter))
  # The block is Burch's Fig. 2 design: every family measured at every one of
  # its subject counts, so "every family measured" is not a selective read.
  expect_identical(
    unname(table(f$dist)[heavy]),
    unname(table(f$dist)[lighter])
  )
  for (d in heavy) {
    expect_true(
      all(f$median_ratio[f$dist == d] > 1),
      info = paste("heavy-tailed family not wider throughout:", d)
    )
  }
  for (d in lighter) {
    expect_true(
      all(f$median_ratio[f$dist == d] < 1),
      info = paste("lighter-tailed family not narrower throughout:", d)
    )
  }
})

test_that("the residual clause's figure is the fixture cell it names", {
  # The `ratio_family` shape is what enforces this wherever the clause sits;
  # this test pins the shape itself, so a shape that stopped matching (or
  # started matching everything) cannot leave the surface checks vacuously
  # green. A right number at the wrong family and a wrong number at the right
  # family must both fail.
  r <- residual_fixture()
  shapes <- width_canonical_shapes(width_fixture(), r)
  sh <- shapes$ratio_family
  parts <- function(s) regmatches(s, regexec(sh$re, s, perl = TRUE))[[1]]

  true_cell <- "a median width ratio of 1.2963 at t(5) with 100 subjects"
  # full match plus the shape's three groups: ratio, family, subject count.
  expect_length(parts(true_cell), 4L)
  expect_true(sh$ok(parts(true_cell)))
  # t(5)'s figure attributed to Laplace, whose k = 100 median is 1.2998.
  expect_false(sh$ok(parts(
    "a median width ratio of 1.2963 at Laplace with 100 subjects"
  )))
  # The right family at a subject count whose median is a different number.
  expect_false(sh$ok(parts(
    "a median width ratio of 1.2963 at t(5) with 10 subjects"
  )))
  # A family name the prose-to-fixture map does not carry.
  expect_false(sh$ok(parts(
    "a median width ratio of 1.2963 at Cauchy with 100 subjects"
  )))
})

test_that("a dependency list on any swept surface is attributed to Imports", {
  # M123 AC2. Two of this milestone's three returns were the same shape: a
  # sentence listing the package's dependencies, correct in its membership and
  # wrong about what the list MEANS -- "installed only if you ask for them",
  # then "every non-base package the install pulls". Installing this package
  # retrieves the whole recursive closure of its Imports, not the six names it
  # declares, so a bare list reads as a claim about the install and is false.
  #
  # The rule: any sentence naming three or more of the non-base Imports must
  # name exactly that set AND carry `Imports` or `non-base`, so the list is
  # anchored to what the package DECLARES. Case-sensitive on purpose -- the
  # sentence this criterion was written against read "imports only", lowercase,
  # and a case-folding test would have passed it untouched.
  #
  # `R/*.R` is excluded: its squashed text is source code, not prose. Three
  # engine files collapse to blobs naming `glmmTMB`, `cli` and `rlang` inside
  # one function body, and the only way to satisfy the rule there would be to
  # plant a dependency list into a fitting function.
  # The `Imports:` field is read from the INSTALLED metadata first. Under
  # `R CMD check` the tests run from `.Rcheck/tests/testthat`, where
  # `../../DESCRIPTION` does not exist -- the package sits at
  # `.Rcheck/intraclass/`. Reading the source path unconditionally errored the
  # whole check, green everywhere else; `packageDescription()` resolves in
  # every layout that has the package loaded at all.
  imports_field <- tryCatch(
    utils::packageDescription("intraclass")$Imports,
    error = function(e) NULL
  )
  if (is.null(imports_field) || is.na(imports_field)) {
    src <- testthat::test_path("..", "..", "DESCRIPTION")
    if (file.exists(src)) imports_field <- read.dcf(src, "Imports")[1, 1]
  }
  skip_if(
    is.null(imports_field) || is.na(imports_field),
    "no Imports field reachable in this layout"
  )
  imports <- trimws(strsplit(imports_field, ",")[[1]])
  imports <- sub("[[:space:]]*\\(.*", "", imports)
  non_base <- sort(setdiff(
    imports,
    rownames(installed.packages(priority = "base"))
  ))

  surfaces <- c(source_doc_surfaces(), installed_doc_surfaces())
  surfaces <- surfaces[!grepl("^R/.*\\.R$", names(surfaces))]
  skip_if(length(surfaces) == 0L, "no swept surfaces in this layout")

  hits <- list()
  for (nm in names(surfaces)) {
    for (sent in width_split(surfaces[[nm]])) {
      named <- non_base[vapply(
        non_base,
        function(p) grepl(p, sent, fixed = TRUE),
        logical(1)
      )]
      if (length(named) >= 3L) {
        hits[[length(hits) + 1L]] <- list(
          where = nm,
          sent = sent,
          named = named
        )
      }
    }
  }

  # Anti-vacuity: the rule is worthless if it enumerates nothing. The README's
  # install sentence is always one such sentence, on both legs.
  expect_gt(length(hits), 0L)

  for (h in hits) {
    expect_identical(
      h$named,
      non_base,
      info = paste0(
        "dependency list in ",
        h$where,
        " is not exactly the non-base Imports set"
      )
    )
    expect_true(
      grepl("Imports", h$sent, fixed = TRUE) ||
        grepl("non-base", h$sent, fixed = TRUE),
      info = paste0(
        "dependency list in ",
        h$where,
        " names no field -- it reads as a claim about what the install ",
        "retrieves rather than what the package declares"
      )
    )
  }
})
