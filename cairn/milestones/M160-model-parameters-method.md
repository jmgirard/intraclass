# M160: easystats model_parameters method for icc() results

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** user-facing — a new method that users call on `icc()` results
- **Branch/PR:** m160-model-parameters-method

## Goal

`parameters::model_parameters()` on an `icc()` result returns its estimates as an easystats parameters table, with `parameters` an optional dependency only.

## Scope

**In:** `model_parameters.intraclass_icc()`, built from `tidy()` with easystats column names, given the class `c("parameters_model", "see_parameters_model", "data.frame")` and a `title` attribute so the parameters printer shows an ICC title. It is registered lazily in `.onLoad()` through the vendored `s3_register()`, as `autoplot()` is. `parameters` joins `Suggests:` (D-051). A numeric `ci` that differs from the fitted confidence level aborts classed, because the table cannot recompute an interval at another level. Documented on `?icc`, with a NEWS bullet.

**Out:** a method for `d_study()` results → candidate row "d_study model_parameters method". Other easystats arguments (`ci_method`, `bootstrap`, `standardize`, `ci = NULL`) are passed through `...` and ignored, with no promise either way; a user report that one is ignored silently promotes it as a new candidate row. A `performance` or `see` method → not planned.

## Acceptance criteria

- [ ] AC1: With parameters installed, `parameters::model_parameters(x)` on an `icc()` result `x` returns an object whose class vector begins with `"parameters_model", "see_parameters_model"` and inherits `"data.frame"`, whose set of column names is exactly `Parameter`, `Type`, `Level`, `Occasions`, `SF_Index`, `Coefficient`, `SE`, `CI`, `CI_low`, `CI_high`, `Method`, with `Parameter` as the first column, and which has one row per row of `tidy(x)`. A test in `tests/testthat/test-model-parameters.R` asserts all three on four fits: a two-way fit on `ratings`, a one-way fit on `ratings`, a multilevel fit on `school`, and a within-cell replicate fit on `ratings_replicates`.
- [ ] AC2: On the same four fits, the test asserts with `identical()` that each column equals its `tidy(x)` source column: `Parameter` = `term`, `Type` = `type`, `Level` = `level`, `Occasions` = `occasions`, `SF_Index` = `sf_index`, `Coefficient` = `estimate`, `SE` = `std.error`, `CI` = `conf.level`, `CI_low` = `conf.low`, `CI_high` = `conf.high`, `Method` = `method`.
- [ ] AC3: On the two-way fit, a test asserts that the printed output of `print(parameters::model_parameters(x))` contains the text `Intraclass correlation coefficients` and does not contain `Fixed Effects`.
- [ ] AC4: For a numeric scalar `v`, `parameters::model_parameters(x, ci = v)` aborts when `isTRUE(all.equal(v, conf_level))` is `FALSE` for the fit's confidence level, with a condition that inherits `intraclass_error` and whose message contains `conf_level`; when it is `TRUE`, the call returns a table identical to the one with no `ci`. A test asserts both on the two-way fit with `v = 0.90` (through `expect_error(class = "intraclass_error", regexp = "conf_level")`) and with `v = 0.95`.
- [ ] AC5: `DESCRIPTION` lists `parameters` under `Suggests:` and under neither `Imports:` nor `Depends:`. `NAMESPACE` holds no `import(parameters)` or `importFrom(parameters` line. `.onLoad()` in `R/zzz.R` calls `s3_register("parameters::model_parameters", "intraclass_icc")`. Every `test_that()` block in `tests/testthat/test-model-parameters.R` calls `skip_if_not_installed("parameters")` before any parameters call, and `grep -lE 'parameters::|library\(parameters|requireNamespace\("parameters"' tests/testthat/*.R` lists no other file.
- [ ] AC6: The `?icc` help page documents `model_parameters()` and the column mapping of AC2. `NEWS.md` has a bullet for the method under the development-version heading. `devtools::document()` leaves no diff, and `pkgdown::check_pkgdown()` passes.
- [ ] AC7: On the review commit, `devtools::test()` passes with no failures and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T1, T2
- AC6 → T3
- AC7 → T4

## Tasks

- [x] T1: Write `tests/testthat/test-model-parameters.R` first (AC1 to AC5): the four fits, the column set and row count, the `identical()` mapping, the printed title, and the `ci` abort and pass-through. Each `test_that()` block opens with `skip_if_not_installed("parameters")`. Seed the Monte-Carlo fits with `seed =`, never the global seed.
- [x] T2: Add `model_parameters.intraclass_icc(model, ...)` to `R/icc-methods.R` beside `tidy.intraclass_icc()` (~line 370): rename the `tidy()` columns, return a base data frame, set the class and `attr(, "title")`. Read `ci` from `...`; compare it with `model$ci$conf_level` by `all.equal()` and abort through `abort_intraclass()` with a message that names `icc(conf_level = )`. Register it in `.onLoad()` in `R/zzz.R` beside the two `autoplot` lines. Add `parameters` to `Suggests:` in alphabetical order.
- [x] T3: Document the method with `@rdname icc` and no `@export`, as `autoplot.intraclass_icc()` is: what it returns, the column mapping, and the `ci` rule. Name `model_parameters()` in the "Estimating an ICC" description in `_pkgdown.yml`. Add the NEWS bullet. Run `devtools::document()`.
- [ ] T4: Run `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()`; fix what they report.

## Work log

- 2026-10-16: created by /milestone-plan.
- 2026-10-16: tier check: milestone — a new user-facing S3 method and a dependency change.
- 2026-10-16: collision sweep: absorbed candidate row "easystats model_parameters method"; its precondition M159 is done. D-035 (public surface), D-038 (column order not contract) and D-050 (class prefix) read; D-051 extends D-035's surface to this table. GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-16: question set: may parameters join Suggests — yes, Suggests only (D-051).
- 2026-10-16: question set: which result types — icc() results only; d_study() becomes a candidate row.
- 2026-10-16: question set: which columns — all tidy() columns, renamed to easystats names.
- 2026-10-16: criteria audit (full mode, fresh Opus reader): AC1 fixed column order, narrowed to the name set with Parameter first (D-038); AC4 open domain and exact comparison, narrowed to a numeric scalar with an all.equal() tolerance and a pinned class and regexp; AC5 grep would read _snaps/ and missed library() and requireNamespace() forms, narrowed to tests/testthat/*.R with a wider pattern; AC5 no D-entry for the dependency, answered by D-051 in the plan commit; AC7 tied to the review commit. AC2, AC3 and AC6 had no finding.
- 2026-10-16: plan gate chose lazy registration through s3_register() in .onLoad() over a roxygen `@exportS3Method parameters::model_parameters` NAMESPACE entry, because autoplot already uses the first and one mechanism is easier to read; falsified by a check NOTE or a load failure from s3_register() under parameters.
- 2026-10-16: plan gate chose to abort on a numeric ci that differs from the fitted level over ignoring it, because #5 says a request the result cannot honor fails loudly; falsified by a user report that easystats tooling passes ci by default and so cannot call the method.
- 2026-10-16: plan gate chose a fixed title "Intraclass correlation coefficients" over a design-specific title from format(), because the printer's header line is short and the design is in the table rows; falsified by a user reading two printed tables as the same design.
- 2026-10-16: started on branch m160-model-parameters-method, cut from main at fcc8403.
- 2026-10-16: implementation choice: `ci` is a named argument (default NULL) rather than read from `...`, so it is documented on ?icc; a non-numeric or non-scalar `ci` also aborts. The refusal takes its own subclass `intraclass_ci_level` under `intraclass_error`, and the test pins both.
- 2026-10-16: implementation choice: the method's first argument is `model`, as the parameters generic requires, so ?icc's existing `model` entry gains one sentence for this method instead of a second entry.
- 2026-10-17: checkpoint (T1 to T3 written, boxes open): the new test file failed 4 of 4 blocks before the method existed (parameters' own "class not supported" error) and passes 68 expectations after it; the full suite is still running. NEWS hits from the simple-english lint are in older bullets that the candidate row "Older NEWS.md bullets over 25 words (R2)" covers, so they stay.
- 2026-10-17: claim audit: 21 claims read, 3 corrected — R/icc.R (the printer also folds Level into the Parameter label; the supported-surface paragraph named two tables while listing three), NEWS.md (Method was missing from the column list); a stale coverage comment in R/zzz.R also fixed; the same reader re-read all four once and found each holds.
- 2026-10-17: T1 to T3 done: full `devtools::test()` at 2dfe47e passed with no failures and 4 skips (vignettes not installed; glmmTMB point fit dies on two reducer frames), and `pkgdown::check_pkgdown()` found no problems.

## Decisions
