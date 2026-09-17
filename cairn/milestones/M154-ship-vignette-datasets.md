# M154: Ship the vignettes' simulated datasets from `data-raw/`

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP8
- **Resolves:** —
- **Surface tier:** user-facing — four new exported datasets and edited articles.
- **Branch/PR:** m154-ship-vignette-datasets

## Goal

Move every data simulation out of the articles and the README into one seeded `data-raw/` script whose output ships as package datasets.

## Scope

**In:** a seeded `data-raw/make-vignette-data.R` that builds `school`, `school_incomplete`, `ratings_replicates` and `ratings_twoway` and saves them with `usethis::use_data()`. The four objects reproduce, value for value, what the `ml-data`, `ml-incomplete-data` (`multilevel-designs.Rmd`), `replicates-data` (`d-studies-and-replicates.Rmd`) and `ci-mpl` (`interval-methods.Rmd`) chunks build at `a400774`. Roxygen pages in `R/data.R`, rows in `_pkgdown.yml`, the four chunks and their adjoining prose rewritten to load the shipped data, `README.Rmd`'s `multilevel` chunk switched to `school`, the inline `n_rater` reference resolved, the `test-vignette-claims.R` rebuilds replaced by the shipped objects, a `NEWS.md` entry.

**Out:** hiding table chunks and `gt` rendering → M155. The static Markdown tables in `interval-methods.Rmd` and `choosing-an-icc.Rmd` stay as they are (no R code produces them). The README's example values change to the article's `school` at the user's choice (plan gate 2026-09-16).

## Acceptance criteria

- [x] AC1: Running `Rscript data-raw/make-vignette-data.R` and then loading the four shipped objects from `data/` gives objects `identical()` to the ones the script built in that run, and `devtools::test()` is clean, so the vignette figures the suite pins are unchanged.
- [x] AC2: The four chunks named in Scope and `README.Rmd`'s `multilevel` chunk load a shipped dataset and build no data. As evidence, `grep -nE 'set\.seed\(|rnorm\(|sample\(' vignettes/*.Rmd README.Rmd` returns no line.
- [x] AC3: Each of the four datasets has a roxygen page in `R/data.R` whose description says the data are simulated and names `data-raw/make-vignette-data.R` and the seed, with `@format` and an `@examples` call, and a row under `_pkgdown.yml`'s Datasets section. `pkgdown::check_pkgdown()` passes and `devtools::check()` reports 0 errors, 0 warnings and no undocumented-dataset NOTE.
- [x] AC4: Every `set.seed(2025)`, `set.seed(11)` and `set.seed(88)` site in `tests/testthat/test-vignette-claims.R` is gone (`grep -cE 'set\.seed\((2025|11|88)\)'` prints 0). The tests that held them read the shipped objects and pass.
- [x] AC5: After `pkgdown::build_site()`, the built HTML of the four edited articles and of `index.html` contains no unrendered inline code (`grep -l '`r ' docs/articles/*.html docs/index.html` returns no file), and no vignette, README or roxygen text names a milestone number.

## Coverage

- AC1 → T1, T4
- AC2 → T3, T5
- AC3 → T2, T6
- AC4 → T4
- AC5 → T3, T5, T6

## Tasks

- [x] T1: Write `data-raw/make-vignette-data.R` with four seeded builders (seeds 2025, 11, 88 as the chunks use them), following `data-raw/make-ratings.R`. Before editing any vignette, run each source chunk's code at HEAD and assert `identical()` against the script's objects. Save with `usethis::use_data()` and commit the `.rda` files.
- [x] T2: Add four roxygen pages to `R/data.R` (simulated, generator, seed, design sizes, `@seealso` links), four `_pkgdown.yml` rows, `devtools::document()`.
- [x] T3: Rewrite the four vignette chunks and their prose (`multilevel-designs.Rmd` lines 55-58, 232 and the inline `n_rater` at 244; `d-studies-and-replicates.Rmd` line 168; `interval-methods.Rmd` lines 355-356, all at `a400774`) to load the shipped data under the new names.
- [x] T4: Replace the inline rebuilds in `test-vignette-claims.R` (`school` at five sites, `school_ragged`, `vc_mpl_sim()`) with the shipped objects. `devtools::test()` clean.
- [x] T5: Switch `README.Rmd`'s `multilevel` chunk to `school`, `devtools::build_readme()`.
- [x] T6: `NEWS.md` entry under Documentation, `devtools::check()`, `pkgdown::check_pkgdown()`, `pkgdown::build_site()` and the AC5 grep.

## Work log

- 2026-09-16: created by /milestone-plan. Criteria audit ran in full mode ([O] reader, 17 findings): line lists and old-commit identity moved to tasks, the simulated-data property and the unrendered-inline check added, NEWS criteria folded into the consistency gate. Absorbs the candidate row "The `school` fixture is rebuilt verbatim five times in `test-vignette-claims.R`" (lineage M132 review [O] 11).
- 2026-09-16: plan gate chose shipping `school_incomplete` as a dataset over keeping the seeded one-line `sample()` drop in the article because the goal removes every simulation from the articles; falsified by a reader needing to see how a ragged design is made.
- 2026-09-16: plan gate chose switching the README to the shipped `school` over leaving its own simulation because two `school` objects with different values would sit in the docs; falsified by a README reader missing the simulation code.

- 2026-09-16: implement started on `m154-ship-vignette-datasets`; question gate skipped, the plan gate settled names, README and fallback. T1 done: `data-raw/make-vignette-data.R` written, the four chunks run at HEAD `identical()` to the script's objects (320, 256, 240, 80 rows), `.rda` files built with `usethis::use_data()`.
- 2026-09-16: T2 done: four roxygen pages in `R/data.R`, four `_pkgdown.yml` rows, `document()` wrote the four `.Rd` files, `pkgdown::check_pkgdown()` clean; the `importFrom` layout drift in `NAMESPACE` reverted (local roxygen2 older than `Config/roxygen2/version`, LESSONS M151).
- 2026-09-16: T3 done: the four chunks now load `school`, `school_incomplete`, `ratings_replicates`, `ratings_twoway`; the inline rater count reads `nlevels(school$rater)`; the three articles knit into the scratchpad with no unrendered inline code; the ruler reports 0 sentences over 25 words added.
- 2026-09-16: T4 done: the five `school` rebuilds, the `school_ragged` pair and `vc_mpl_sim()` in `test-vignette-claims.R` now read the shipped objects; seed grep prints 0; full `devtools::test()` clean, one pre-existing skip (vignettes not installed).
- 2026-09-16: T5 done: README `multilevel` chunk loads `school`, `build_readme()` run, regenerated figure PNGs reverted (unchanged content). The README's multilevel figures change (cluster ICC(C,1) now 1.000 with interval [0.000, 1.000], a boundary cell) since the README used a different simulation before.
- 2026-09-16: claim audit: 23 claims read, 1 corrected — R/data.R, vignettes/multilevel-designs.Rmd, vignettes/d-studies-and-replicates.Rmd, vignettes/interval-methods.Rmd, README.md, tests/testthat/test-vignette-claims.R, NEWS.md (the NEWS bullet now says the README's multilevel figures change).
- 2026-09-16: T6 done: first `devtools::check()` failed on the spelling test (`sd` in the new dataset prose), fixed by writing "standard deviation"; second `devtools::check()` 0 errors, 0 warnings, 0 notes; `pkgdown::check_pkgdown()` clean; `pkgdown::build_site()` rendered every article, no unrendered inline code, `check-vignette-render-warnings.py` OK; milestone-number grep empty. Status set to review.

## Decisions

## Review

- 2026-09-16 review start. The default branch did not move after the branch was cut (`git log HEAD..origin/main` is empty). No PR exists yet.
- AC2 evidence: `grep -nE 'set\.seed\(|rnorm\(|sample\(' vignettes/*.Rmd README.Rmd` returns no line. In the diff, the five named chunks call `str()`, `nrow()` or `icc()` on the shipped objects and build no data. PASS.
- AC5 evidence: `pkgdown::build_site()` exit 0 with nine article pages built. `grep -l '`r ' docs/articles/*.html docs/index.html` returns no file. `grep -nE '\bM[0-9]{2,3}\b' vignettes/*.Rmd README.Rmd README.md man/*.Rd` is empty. The two roxygen hits in `R/abort.R` predate the branch (blame 2026-08-05) and are unchanged. `check-vignette-render-warnings.py` OK. PASS.
- Gate fix: `air format --check .` failed on `data-raw/make-vignette-data.R` ([O] finding 1). Formatted it and re-ran the identity check, all four objects still `identical()` to the shipped files. Committed on the branch.
- AC1 evidence: `data-raw/make-vignette-data.R` sourced into a fresh environment, then each object loaded from `data/`. All four `identical()` TRUE (320, 256, 240, 80 rows), and `git status` shows `data/` unchanged after the run. Full `devtools::test()`: FAIL 0, WARN 0, SKIP 2, PASS 9620. PASS.
- AC4 evidence: `grep -cE 'set\.seed\((2025|11|88)\)' tests/testthat/test-vignette-claims.R` prints 0. That file run alone under the summary reporter shows every test passing and no skip, so the two suite skips lie in other files. PASS.
- AC3 evidence: `R/data.R` carries four pages, each opening "Simulated data, not a real study", each `@source` naming `data-raw/make-vignette-data.R` and its seed, each with `@format` and `@examples`. The four rows sit under Datasets in `_pkgdown.yml`. `pkgdown::check_pkgdown()`: no problems found. `devtools::check(document = FALSE)`: 0 errors, 0 warnings, 0 notes (18 min). PASS.
- Consistency gate: `cairn_validate.py` all checks passed. No DESIGN principle changed, `cairn_impact` skipped. `devtools::document()` diffs only the `NAMESPACE` `importFrom` layout (local roxygen2 8.0.0 against 8.1.0, LESSONS M151), reverted. README.md and README.Rmd last changed in the same commit, and `README.md` has no unrendered inline code. NEWS entry present, no milestone number. `data-raw` and `docs` are in `.Rbuildignore`. `air format --check .` clean after the gate fix. Driving RR none, no projection to record.
- Independent review, three lenses. [S] blame-history: no contradiction of a past milestone or D-entry, one flag (README boundary cell, same as [O] 3). [S] prior-review: no prior-review evidence of regression. The M132 [O]-11 candidate row this milestone absorbs is fixed by the diff, and the GitHub probe returned 0 inline review comments. [O] diff-bug, eleven findings, ranked:
  - [O] 1 `data-raw/make-vignette-data.R` fails `air format --check`, CI red. Fixed at the gate (line above).
  - [O] 2 No test checks that the script regenerates the shipped `.rda` files after the inline rebuilds left the suite.
  - [O] 3 README multilevel example now shows cluster ICC(C,1) = 1.000 with interval [0.000, 1.000], a boundary cell (also the [S] flag).
  - [O] 4 The three new `@examples` are wrapped in `\donttest{}` though each runs under 0.3 s, so `check()` never runs them.
  - [O] 5 The NEWS bullet has one 40-word sentence and sits in the top block, not under Documentation as T6 named.
  - [O] 6 `multilevel-designs.Rmd:231` reads `nlevels(school$rater)` in the paragraph about `school_incomplete`. Same number, wrong referent.
  - [O] 7 "see `?school` for how it is built" points at a script that `.Rbuildignore` keeps out of the installed package.
  - [O] 8 `school_incomplete` keeps gappy row names from the row drop.
  - [O] 9 Two vignette code lines exceed 100 characters (`d-studies-and-replicates.Rmd:173`, `:205`).
  - [O] 10 `intraclass::` prefixes on the datasets inside the package's own tests, unlike the rest of the suite.
  - [O] 11 `vc_mpl_sim()` is a one-line accessor whose name still says "sim".
- Triage at the gate (2026-09-16), merge approved with fix-now items: 1 fixed (above). 2 fix now: `tests/testthat/test-vignette-data-regen.R` evaluates the script's builders in a fresh environment, skipping the `use_data()` call, and checks the four objects `identical()` to the shipped ones. Shown to fail on a planted 1e-9 change. 3 fix now: one sentence after the README `multilevel` chunk names the boundary and points at the article. 4 fix now: the three `\donttest{}` wrappers dropped, examples run in 0.14, 0.21 and 0.04 s. 6 fix now: the inline count reads `nlevels(school_incomplete$rater)`, renders 4. 5, 9, 10, 11 rejected: style items with no user-facing effect, not chosen at the gate. 7 rejected: same convention as `ratings_incomplete`, script in the GitHub repo. 8 rejected: cosmetic, and the fix changes the shipped object.
- Review-found defect (from fix 2): the builder was locale-dependent. `factor(paste(classroom, pupil, sep = "_"))` sorted its levels under the session collation, so the script reproduced `school` and `school_incomplete` only under en_US, not under C (testthat's setting). Measured effect of explicit build-order levels on every README and article estimate and interval: 0. Re-approval asked and given 2026-09-16 for setting explicit levels and rebuilding the two `.rda` files. Rebuilt, and the script now reproduces all four objects under both C and en_US collation. The other two datasets were never affected.
- Re-verification after the fixes. AC1: full `devtools::test()` FAIL 0, WARN 0, SKIP 2, PASS 9624 (the four new expectations included), and `data/` is unchanged after a script run. AC2: unchanged files. AC4: the vignette-claims file passes. AC5: `pkgdown::build_site()` exit 0, the inline-code grep and the milestone grep both empty, the render-warnings checker OK, the README note present in `docs/index.html`. AC3: the first re-check reported one WARNING, an undeclared `usethis` test dependency from a `usethis::use_data` symbol in the new test. Matched by name instead, the check re-run pending.
