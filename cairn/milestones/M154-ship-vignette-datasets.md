# M154: Ship the vignettes' simulated datasets from `data-raw/`

- **Status:** in-progress
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

- [ ] AC1: Running `Rscript data-raw/make-vignette-data.R` and then loading the four shipped objects from `data/` gives objects `identical()` to the ones the script built in that run, and `devtools::test()` is clean, so the vignette figures the suite pins are unchanged.
- [ ] AC2: The four chunks named in Scope and `README.Rmd`'s `multilevel` chunk load a shipped dataset and build no data. As evidence, `grep -nE 'set\.seed\(|rnorm\(|sample\(' vignettes/*.Rmd README.Rmd` returns no line.
- [ ] AC3: Each of the four datasets has a roxygen page in `R/data.R` whose description says the data are simulated and names `data-raw/make-vignette-data.R` and the seed, with `@format` and an `@examples` call, and a row under `_pkgdown.yml`'s Datasets section. `pkgdown::check_pkgdown()` passes and `devtools::check()` reports 0 errors, 0 warnings and no undocumented-dataset NOTE.
- [ ] AC4: Every `set.seed(2025)`, `set.seed(11)` and `set.seed(88)` site in `tests/testthat/test-vignette-claims.R` is gone (`grep -cE 'set\.seed\((2025|11|88)\)'` prints 0). The tests that held them read the shipped objects and pass.
- [ ] AC5: After `pkgdown::build_site()`, the built HTML of the four edited articles and of `index.html` contains no unrendered inline code (`grep -l '`r ' docs/articles/*.html docs/index.html` returns no file), and no vignette, README or roxygen text names a milestone number.

## Coverage

- AC1 → T1, T4
- AC2 → T3, T5
- AC3 → T2, T6
- AC4 → T4
- AC5 → T3, T5, T6

## Tasks

- [ ] T1: Write `data-raw/make-vignette-data.R` with four seeded builders (seeds 2025, 11, 88 as the chunks use them), following `data-raw/make-ratings.R`. Before editing any vignette, run each source chunk's code at HEAD and assert `identical()` against the script's objects. Save with `usethis::use_data()` and commit the `.rda` files.
- [ ] T2: Add four roxygen pages to `R/data.R` (simulated, generator, seed, design sizes, `@seealso` links), four `_pkgdown.yml` rows, `devtools::document()`.
- [ ] T3: Rewrite the four vignette chunks and their prose (`multilevel-designs.Rmd` lines 55-58, 232 and the inline `n_rater` at 244; `d-studies-and-replicates.Rmd` line 168; `interval-methods.Rmd` lines 355-356, all at `a400774`) to load the shipped data under the new names.
- [ ] T4: Replace the inline rebuilds in `test-vignette-claims.R` (`school` at five sites, `school_ragged`, `vc_mpl_sim()`) with the shipped objects. `devtools::test()` clean.
- [ ] T5: Switch `README.Rmd`'s `multilevel` chunk to `school`, `devtools::build_readme()`.
- [ ] T6: `NEWS.md` entry under Documentation, `devtools::check()`, `pkgdown::check_pkgdown()`, `pkgdown::build_site()` and the AC5 grep.

## Work log

- 2026-09-16: created by /milestone-plan. Criteria audit ran in full mode ([O] reader, 17 findings): line lists and old-commit identity moved to tasks, the simulated-data property and the unrendered-inline check added, NEWS criteria folded into the consistency gate. Absorbs the candidate row "The `school` fixture is rebuilt verbatim five times in `test-vignette-claims.R`" (lineage M132 review [O] 11).
- 2026-09-16: plan gate chose shipping `school_incomplete` as a dataset over keeping the seeded one-line `sample()` drop in the article because the goal removes every simulation from the articles; falsified by a reader needing to see how a ragged design is made.
- 2026-09-16: plan gate chose switching the README to the shipped `school` over leaving its own simulation because two `school` objects with different values would sit in the docs; falsified by a README reader missing the simulation code.

## Decisions

## Review
