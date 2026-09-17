# M155: Comparison tables as hidden `gt` chunks

- **Status:** review
- **Priority:** normal
- **Depends on:** M154
- **Driving RR:** —
- **Principles touched:** GP8
- **Resolves:** —
- **Surface tier:** user-facing — article rendering and a new Suggests dependency.
- **Branch/PR:** `m155-gt-comparison-tables`

## Goal

Hide the vignette chunks that exist only to assemble a comparison table and render those tables with `gt`.

## Scope

**In:** `gt` added to `Suggests:` (D-046). Eleven chunks, named by label: `comparison-with-other-packages.Rmd` `validation`, `irricc`, `incomplete-show`, `incomplete-classical`, `incomplete-intraclass`; `engines.Rmd` `engine`, `lavaan`; `interval-methods.Rmd` `ci-bootstrap`, `ci-oneway-optin`, `ci-mpl`; `choosing-an-icc.Rmd` `incomplete-fixed`. Where a chunk holds the first demonstration of an argument (`irricc`, `incomplete-intraclass`, `engine`, `lavaan`, `ci-bootstrap`, `ci-oneway-optin`, `ci-mpl`, `incomplete-fixed`), the demonstration call stays echoed and the table assembly moves to a following `echo = FALSE` chunk. Where it does not (`validation`, `incomplete-show`, `incomplete-classical`), the whole chunk becomes `echo = FALSE`. `validation-gap` becomes `include = FALSE`. Every `gt` chunk carries `requireNamespace("gt", quietly = TRUE)` in its `eval` option. A `NEWS.md` entry.

**Out:** a kable fallback when `gt` is absent (declined at the plan gate 2026-09-16). The static Markdown tables (Koo and Li thresholds, width ratios, the naming crosswalk, the capability matrix) stay Markdown: no R code produces them. Any checker script over chunk options: barred by D-021, evidence is by grep and by the built site.

## Acceptance criteria

- [x] AC1: `DESCRIPTION` lists `gt` under `Suggests:`, and every chunk in `vignettes/*.Rmd` whose body contains `gt::` has `requireNamespace("gt", quietly = TRUE)` in its header's `eval` option. Evidence: for each `gt::` hit of `grep -n 'gt::' vignettes/*.Rmd`, the enclosing chunk header is quoted in the Review section.
- [x] AC2: Each of the eleven chunks named in Scope renders its table from a chunk with `echo = FALSE` that calls `gt::gt()`, and for the eight demonstration chunks the echoed call precedes it. Evidence: the eleven chunk headers and the `gt::gt()` line of each, quoted in the Review section.
- [x] AC3: `grep -n 'kable' vignettes/*.Rmd` returns no line, and none of the eleven chunks prints a bare data frame or named vector as its table.
- [x] AC4: Each of the eleven tables carries a title (`gt::tab_header()`), plain-word column headings (`gt::cols_label()`) and formatted numerics (`gt::fmt_number()`), and every number the adjoining prose quotes matches the table to the digits shown.
- [x] AC5: After `pkgdown::build_site()`, each of the eleven tables is present in the built `docs/articles/` HTML as a `gt` table (`grep -c 'gt_table' docs/articles/<article>.html` returns at least the number of tables in that article), `python3 data-raw/check-vignette-render-warnings.py` passes on `docs/`, `devtools::check()` reports 0 errors and 0 warnings, and `devtools::test()` is clean.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T2, T3, T4
- AC3 → T2, T3, T4
- AC4 → T2, T3, T4, T5
- AC5 → T5

## Tasks

- [x] T1: Add `gt` to `Suggests:`, confirm `setup-r-dependencies` installs it in the check and pkgdown jobs (it installs Suggests by default, LESSONS M139), write the D-046 cross-reference into the milestone-local Decisions.
- [x] T2: `comparison-with-other-packages.Rmd`: split or hide the five chunks, `validation-gap` to `include = FALSE`, style each `gt` table (title, plain headings, `fmt_number`).
- [x] T3: `engines.Rmd` and `choosing-an-icc.Rmd`: split the three chunks and style the tables.
- [x] T4: `interval-methods.Rmd`: split the three chunks and style the tables. Keep `ci-mpl`'s echoed call on the shipped `ratings_twoway`.
- [x] T5: Read every number the prose quotes beside a table against the rendered digits; `NEWS.md` entry; `devtools::check()`, `devtools::test()`, `pkgdown::build_site()`, the AC5 greps and the render-warnings checker.

## Work log

- 2026-09-16: created by /milestone-plan. Criteria audit ran in full mode ([O] reader): the chunk-parsing check script was cut under D-021, line numbers dropped for labels, the split rule narrowed to chunks holding a demonstration call, the style rule bound to the rendered tables and the quoted prose figures, the built-site presence check added against a vacuous pass.
- 2026-09-16: plan gate chose `gt` in Suggests with an `eval` guard and no fallback over a kable fallback because CRAN and CI install Suggests and two renderings would drift; falsified by a reader building the articles without `gt` and missing a table.
- 2026-09-16: plan chose greps plus built-site inspection over a committed chunk-options checker because D-021 bars a new checker over the repo's own docs; falsified by a wrong shipped number traced to a chunk option.
- 2026-09-16: implement started on `m155-gt-comparison-tables`; question gate skipped, nothing left open (the dependency gate ran at plan, D-046).
- 2026-09-16: T1 done: `gt` added to `Suggests:`. `check-standard.yaml` and `pkgdown.yaml` call `setup-r-dependencies@v2` with no `dependencies:` override, so both install Suggests.
- 2026-09-16: T2 done: five comparison-article tables in `gt` (table chunks `irricc-table`, `incomplete-intraclass-table` follow their echoed calls). `validation-gap` is `include = FALSE` with `eval = exists("comparison")`. If `gt` is absent, the chunk skips. Minor fix under AC4: two sentences said the tools match to five decimals or are identical, but the built table shows 0.28977 against 0.28976 (published site too). Both now say "within 0.00001" (largest gap 7.2e-06).
- 2026-09-16: T3 done: `engine-table`, `lavaan-table` and `incomplete-fixed-table` (one table, grouped by rater framing) follow their echoed calls. The built table shows fixed-rater consistency intervals wider than random ones (ICC(C,1) 0.218 to 0.906 against 0.228 to 0.906). The "random interval is the wider" sentence now names the agreement coefficients only. The engines prose figures (0.284, 0.290) match the 4-decimal table.
- 2026-09-16: T4 done: `ci-bootstrap-table`, `ci-oneway-optin-table` and `ci-mpl-table` build each interval from two `fmt_number()` columns joined by `cols_merge()`. `ci-mpl` stays on `ratings_twoway`. The prose claims beside the three tables match the built digits. The local build needed the branch installed first (`R CMD INSTALL .`), because the installed copy predated `ratings_twoway`.
- 2026-09-16: T5 done: NEWS entry. `devtools::test()` FAIL 0, WARN 0, SKIP 2, PASS 9624. `pkgdown::build_site()` exit 0. `gt_table` grep counts per article are 20, 8, 12 and 4, against 5, 2, 3 and 1 tables. The render-warnings checker passes. `devtools::check()` gives 0 errors, 0 warnings and 0 notes.
- claim audit: 24 claims read, 2 corrected — NEWS.md, vignettes/comparison-with-other-packages.Rmd, vignettes/choosing-an-icc.Rmd, vignettes/engines.Rmd, vignettes/interval-methods.Rmd, DESCRIPTION
- 2026-09-16: the two corrected NEWS sentences are the hidden `validation` fits and the incomplete-data interval claim, now scoped to the *Choosing an ICC* example. The same reader re-read both, and both hold. Status set to review.

## Decisions

- 2026-09-16: `gt` joins `Suggests:` with an `eval` guard and no fallback. The cross-cutting record is D-046.

## Review

Evidence is from 2026-09-16 on `m155-gt-comparison-tables` at `b0da66d`. The merge base is `origin/main` (`8d3da7c`), so no sync merge was needed.

- AC1: `DESCRIPTION` Suggests has `gt,` (line 34). `grep -n 'gt::' vignettes/*.Rmd` returns 55 hits in 11 chunks. The enclosing headers are `validation` (`eval = have_psych && have_irr && requireNamespace("gt", quietly = TRUE)`), `irricc-table` (`have_irr_icc && requireNamespace("gt", quietly = TRUE)`), `incomplete-show`, `incomplete-classical`, `incomplete-intraclass-table`, `incomplete-fixed-table` (each `eval = requireNamespace("gt", quietly = TRUE)`), `engine-table` (lme4 and merDeriv guards `&& requireNamespace("gt", quietly = TRUE)`), `lavaan-table` (lavaan guard `&& requireNamespace("gt", quietly = TRUE)`), `ci-bootstrap-table`, `ci-oneway-optin-table`, `ci-mpl-table` (each glmmTMB guard `&& requireNamespace("gt", quietly = TRUE)`). No `gt::` line sits outside these chunks.
- AC2: All eleven table chunks carry `echo = FALSE` and call `gt::gt()`. The whole-chunk cases are `validation` (header line 63, `gt::gt(comparison)` line 92), `incomplete-show` (155, `gt::gt(wide_incomplete)` 160) and `incomplete-classical` (177, `gt::gt()` 185). The split cases pair an echoed call with a later table chunk. They are `irricc` 121 then `irricc-table` 134 (`gt::gt()` 139), `incomplete-intraclass` 198 then 204 (211), `engine` 51 then 56 (58), `lavaan` 87 then 92 (94), `incomplete-fixed` 184 then 191 (`gt::gt(groupname_col = "raters")` 197), `ci-bootstrap` 66 then 73 (79), `ci-oneway-optin` 308 then 321 (329), and `ci-mpl` 392 then 397 (403). None of the eight echoed chunks sets `echo = FALSE`.
- AC3: `grep -n 'kable' vignettes/*.Rmd` exits 1 with no output. In the branch diff, the eight echoed chunks end on an assignment. Each of the eleven table chunks ends in a `gt::` pipe. The built HTML holds no bare data-frame or vector printout at any table site.
- AC4: Each of the eleven chunks calls `gt::tab_header()`, `gt::cols_label()` and `gt::fmt_number()` (grep above). The built tables show a title row, plain headings and fixed decimals. Prose figures read against the built digits all match. The comparison gap prints `7.2e-06` (0.28977 against 0.28976). The lavaan prose quotes `0.284` and `0.290` (table 0.2843 and 0.2898). Bootstrap lower bounds are lower in all four rows, and both ICC(A,k) upper bounds read 0.91. Searle and Burch lower limits are below zero, and Burch is narrower. The mpl interval is wider in both rows. In *Choosing an ICC*, the random agreement intervals are wider and the consistency intervals differ by 0.014 at most. The incomplete-data table shows 6 subjects, 20 ratings and ICC(A,k) 0.521. Prose claims without numbers are reviewer findings, triaged below.
- AC5: After `R CMD INSTALL .`, `pkgdown::build_site()` exits 0. `grep -c 'gt_table'` gives 20, 8, 12 and 4 for the comparison, engines, interval-methods and choosing articles, against 5, 2, 3 and 1 tables. A parse of the built HTML finds exactly those counts of `table gt_table` elements. `python3 data-raw/check-vignette-render-warnings.py docs` prints OK and exits 0. `devtools::check()` reports Status OK with 0 errors, 0 warnings and 0 notes. `devtools::test()` reports FAIL 0, WARN 0, SKIP 2, PASS 9624.

Consistency gate:
- `cairn_validate.py` exits 0. No DESIGN principle changed, so `cairn_impact` is skipped.
- `devtools::document()` rewrites the `importFrom(generics, ...)` layout in `NAMESPACE`. The branch touches no `R/`, `man/` or `NAMESPACE` file. The cause is local roxygen2 8.0.0 against `Config/roxygen2/version: 8.1.0` (LESSONS M151). The file was restored.
- `pkgdown::check_pkgdown()` finds no problems. `air format --check .` exits 0. The branch does not touch README. NEWS has an entry with no milestone number. There are no new top-level files.
- CI checkers: `check-mpl-doc-claims.py`, `check-reference-observations.py`, `enumerate-generalizing-claims.py --check` and the self-tests of those three and the render-warnings checker exit 0. `check-record-claims.py` fails on `record-claims.tsv:6` (`roadmap-terminal-rows` expects M153, M152, M151, but ROADMAP has M154, M153, M152), and its self-test fails with it. The same failure reds the `lint` workflow on `origin/main` at `8d3da7c`. The M154 done pass rotated the rows without the ledger row.

Reviewers: [O] diff-bug found 10 findings. [S] blame-history found 1, the same as O3. [S] prior-review found no regression and no PR review threads. Ranked findings with proposed dispositions:
- O1 `comparison-with-other-packages.Rmd:119`: irrICC `icc2r` "reproduces" `ICC(A,1)`, but the table shows 0.28977 against 0.28976. Proposed: fix now.
- O2 `NEWS.md:27-30`: "Three sentences are corrected" misses O1 and the added consistency sentence. Proposed: fix now with O1.
- O3/S1 `comparison-with-other-packages.Rmd:110`: without `gt`, the psych and irr fits are skipped too, and the inline fallback prints an uncomputed "<1e-5". Proposed: follow-up.
- O4: without `gt`, four prose passages point at tables that do not render. Proposed: follow-up with O3.
- O5 `comparison-with-other-packages.Rmd:28-30`: psych and irr calls are now hidden. Proposed: reject, because Scope hides `validation` whole and the sentence stays true.
- O6 `comparison-with-other-packages.Rmd:103`: `exists()` can find stale objects in an interactive session. Proposed: reject, because builds run in a fresh session.
- O7 `engines.Rmd:63-64`: the prose `0.01` interval figure is not in the table. Proposed: reject, because the line predates the branch and quotes no table number.
- O8 `choosing-an-icc.Rmd:209-213`: "fixing the raters removes it" conflicts with the wider fixed consistency intervals. Proposed: fix now, because the branch edited this paragraph.
- O9 `NEWS.md:26`: one line wraps at about 88 characters. Proposed: fix now with O2.
- O10 interval tables: `fmt_number` prints a Unicode minus. Proposed: reject, because it is `gt` display behavior.
- G1 (gate, pre-existing): `record-claims.tsv:6` is stale on `origin/main`, so PR CI will be red. Proposed: fix now on the branch.
