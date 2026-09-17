# M155: Comparison tables as hidden `gt` chunks

- **Status:** in-progress
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

- [ ] AC1: `DESCRIPTION` lists `gt` under `Suggests:`, and every chunk in `vignettes/*.Rmd` whose body contains `gt::` has `requireNamespace("gt", quietly = TRUE)` in its header's `eval` option. Evidence: for each `gt::` hit of `grep -n 'gt::' vignettes/*.Rmd`, the enclosing chunk header is quoted in the Review section.
- [ ] AC2: Each of the eleven chunks named in Scope renders its table from a chunk with `echo = FALSE` that calls `gt::gt()`, and for the eight demonstration chunks the echoed call precedes it. Evidence: the eleven chunk headers and the `gt::gt()` line of each, quoted in the Review section.
- [ ] AC3: `grep -n 'kable' vignettes/*.Rmd` returns no line, and none of the eleven chunks prints a bare data frame or named vector as its table.
- [ ] AC4: Each of the eleven tables carries a title (`gt::tab_header()`), plain-word column headings (`gt::cols_label()`) and formatted numerics (`gt::fmt_number()`), and every number the adjoining prose quotes matches the table to the digits shown.
- [ ] AC5: After `pkgdown::build_site()`, each of the eleven tables is present in the built `docs/articles/` HTML as a `gt` table (`grep -c 'gt_table' docs/articles/<article>.html` returns at least the number of tables in that article), `python3 data-raw/check-vignette-render-warnings.py` passes on `docs/`, `devtools::check()` reports 0 errors and 0 warnings, and `devtools::test()` is clean.

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
- [ ] T4: `interval-methods.Rmd`: split the three chunks and style the tables. Keep `ci-mpl`'s echoed call on the shipped `ratings_twoway`.
- [ ] T5: Read every number the prose quotes beside a table against the rendered digits; `NEWS.md` entry; `devtools::check()`, `devtools::test()`, `pkgdown::build_site()`, the AC5 greps and the render-warnings checker.

## Work log

- 2026-09-16: created by /milestone-plan. Criteria audit ran in full mode ([O] reader): the chunk-parsing check script was cut under D-021, line numbers dropped for labels, the split rule narrowed to chunks holding a demonstration call, the style rule bound to the rendered tables and the quoted prose figures, the built-site presence check added against a vacuous pass.
- 2026-09-16: plan gate chose `gt` in Suggests with an `eval` guard and no fallback over a kable fallback because CRAN and CI install Suggests and two renderings would drift; falsified by a reader building the articles without `gt` and missing a table.
- 2026-09-16: plan chose greps plus built-site inspection over a committed chunk-options checker because D-021 bars a new checker over the repo's own docs; falsified by a wrong shipped number traced to a chunk option.
- 2026-09-16: implement started on `m155-gt-comparison-tables`; question gate skipped, nothing left open (the dependency gate ran at plan, D-046).
- 2026-09-16: T1 done: `gt` added to `Suggests:`. `check-standard.yaml` and `pkgdown.yaml` call `setup-r-dependencies@v2` with no `dependencies:` override, so both install Suggests.
- 2026-09-16: T2 done: five comparison-article tables in `gt` (table chunks `irricc-table`, `incomplete-intraclass-table` follow their echoed calls). `validation-gap` is `include = FALSE` with `eval = exists("comparison")`. If `gt` is absent, the chunk skips. Minor fix under AC4: two sentences said the tools match to five decimals or are identical, but the built table shows 0.28977 against 0.28976 (published site too). Both now say "within 0.00001" (largest gap 7.2e-06).
- 2026-09-16: T3 done: `engine-table`, `lavaan-table` and `incomplete-fixed-table` (one table, grouped by rater framing) follow their echoed calls. The built table shows fixed-rater consistency intervals wider than random ones (ICC(C,1) 0.218 to 0.906 against 0.228 to 0.906), so the "random interval is the wider" sentence now names the agreement coefficients only. The engines prose figures (0.284, 0.290) match the 4-decimal table.

## Decisions

- 2026-09-16: `gt` joins `Suggests:` with an `eval` guard and no fallback. The cross-cutting record is D-046.

## Review
