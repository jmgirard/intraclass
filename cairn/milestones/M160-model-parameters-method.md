# M160: easystats model_parameters method for icc() results

- **Status:** review
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

- [x] AC1: With parameters installed, `parameters::model_parameters(x)` on an `icc()` result `x` returns an object whose class vector begins with `"parameters_model", "see_parameters_model"` and inherits `"data.frame"`, whose set of column names is exactly `Parameter`, `Type`, `Level`, `Occasions`, `SF_Index`, `Coefficient`, `SE`, `CI`, `CI_low`, `CI_high`, `Method`, with `Parameter` as the first column, and which has one row per row of `tidy(x)`. A test in `tests/testthat/test-model-parameters.R` asserts all three on four fits: a two-way fit on `ratings`, a one-way fit on `ratings`, a multilevel fit on `school`, and a within-cell replicate fit on `ratings_replicates`.
- [x] AC2: On the same four fits, the test asserts with `identical()` that each column equals its `tidy(x)` source column: `Parameter` = `term`, `Type` = `type`, `Level` = `level`, `Occasions` = `occasions`, `SF_Index` = `sf_index`, `Coefficient` = `estimate`, `SE` = `std.error`, `CI` = `conf.level`, `CI_low` = `conf.low`, `CI_high` = `conf.high`, `Method` = `method`.
- [x] AC3: On the two-way fit, a test asserts that the printed output of `print(parameters::model_parameters(x))` contains the text `Intraclass correlation coefficients` and does not contain `Fixed Effects`.
- [x] AC4: For a numeric scalar `v`, `parameters::model_parameters(x, ci = v)` aborts when `isTRUE(all.equal(v, conf_level))` is `FALSE` for the fit's confidence level, with a condition that inherits `intraclass_error` and whose message contains `conf_level`; when it is `TRUE`, the call returns a table identical to the one with no `ci`. A test asserts both on the two-way fit with `v = 0.90` (through `expect_error(class = "intraclass_error", regexp = "conf_level")`) and with `v = 0.95`.
- [x] AC5: `DESCRIPTION` lists `parameters` under `Suggests:` and under neither `Imports:` nor `Depends:`. `NAMESPACE` holds no `import(parameters)` or `importFrom(parameters` line. `.onLoad()` in `R/zzz.R` calls `s3_register("parameters::model_parameters", "intraclass_icc")`. Every `test_that()` block in `tests/testthat/test-model-parameters.R` calls `skip_if_not_installed("parameters")` before any parameters call, and `grep -lE 'parameters::|library\(parameters|requireNamespace\("parameters"' tests/testthat/*.R` lists no other file.
- [x] AC6: The `?icc` help page documents `model_parameters()` and the column mapping of AC2. `NEWS.md` has a bullet for the method under the development-version heading. `devtools::document()` leaves no diff, and `pkgdown::check_pkgdown()` passes.
- [x] AC7: On the review commit, `devtools::test()` passes with no failures and `devtools::check()` reports 0 errors and 0 warnings.

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
- [x] T4: Run `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()`; fix what they report.

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
- 2026-10-17: T4: first `devtools::check()` at d0042f1 gave 1 error, 0 warnings, 0 notes: the spelling test flagged "easystats" (in NEWS and ?icc); added it to `inst/WORDLIST`, and `spelling::spell_check_package()` then found no errors. Check re-run pending.
- 2026-10-17: T4 done: `devtools::check()` at 01831ae reports 0 errors, 0 warnings, 0 notes. Status set to review.
- 2026-10-17: step-7 approval: m160-model-parameters-method approved for merge

## Decisions

## Review

Review pass 1 (2026-10-17), on 8f575cb. Copilot round off (no header line in `cairn/PROFILE.md`).

- AC1 evidence: `devtools::test(filter = "model-parameters")` on 8f575cb, block 1 ran 20 expectations, 0 failed, 0 skipped, 0 errors; it asserts `class(mp)[1:2]`, `expect_s3_class(mp, "data.frame")`, `expect_setequal` on the 11 names, `names(mp)[1] == "Parameter"`, and `nrow(mp) == nrow(tidy(x))` on the two-way, one-way, multilevel (`school`) and replicate (`ratings_replicates`) fits (5 × 4 = 20). Before the method existed, all 4 blocks failed with parameters' "class not supported" error (work log, 2026-10-17 checkpoint).
- AC2 evidence: same run, block 2 ran 44 expectations (11 columns × 4 fits), 0 failed; each is `expect_identical(mp[[col]], td[[source]])` over the mapping AC2 names.
- AC3 evidence: same run, block 3 ran 2 expectations, 0 failed: the captured print of the two-way table matches `Intraclass correlation coefficients` and does not match `Fixed Effects` (both `fixed = TRUE`). The claim auditor confirmed that removing the `title` attribute brings "Fixed Effects" back, so the test discriminates.
- AC4 evidence: same run, block 4 ran 3 expectations, 0 failed: `expect_error(model_parameters(x, ci = 0.90), class = "intraclass_error", regexp = "conf_level")`, the caught condition is also `intraclass_ci_level`, and `model_parameters(x, ci = 0.95)` is `identical()` to `model_parameters(x)`. The comparison in R/icc-methods.R uses `isTRUE(all.equal(ci, level))`.
- AC5 evidence: on 8f575cb, `parameters` appears in DESCRIPTION's `Suggests:` block (line 13 of that block) and 0 times in the `Imports:` and `Depends:` blocks; `grep -c parameters NAMESPACE` is 0; R/zzz.R:20 is `s3_register("parameters::model_parameters", "intraclass_icc")` inside `.onLoad()`; each of the 4 `test_that()` blocks opens with `skip_if_not_installed("parameters")`; the AC5 `grep -lE` over `tests/testthat/*.R` lists only `test-model-parameters.R`.
- AC6 evidence: on 8f575cb, man/icc.Rd:557-567 documents `model_parameters.intraclass_icc()` with the 11-pair mapping of AC2, and the `ci` argument has its own entry; NEWS.md line 3 is the method's bullet under line 1 `# intraclass (development version)`; `devtools::document()` left `git status` empty; `pkgdown::check_pkgdown()` reported "No problems found".

spawned: diff-bug, blame-history, prior-review

- diff-bug #1: `Parameter` repeats across levels on a multilevel fit, so `see`'s plot overlays the subject and cluster intervals with no legend — follow-up (candidate row "easystats tools beyond model_parameters on icc() results", item a); the doc-side half fixed now: `?icc` says `Parameter` repeats across levels and is read with `Level`, and a test pins the repeat.
- diff-bug #2: `compare_parameters()` crashes on two `icc()` results and prints a `$fit` `(Intercept)` row for one — follow-up (same row, item b); outside the milestone, which promises `model_parameters()` only.
- diff-bug #3: `insight::standardize_names(style = "broom")` maps `Level` to `value` — follow-up (same row, item c).
- diff-bug #4: the refusal's own class `intraclass_ci_level` names an argument, where argument checks such as `validate_conf_level()` use bare `intraclass_error` — fix now: subclass dropped; the test names the failure by its message.
- diff-bug #5: `?icc`'s Arguments list moved `model` and the new `ci` ahead of `data` — fix now: the method moves to `R/model-parameters.R`, which collates after `R/icc.R`, so `icc()`'s arguments keep signature order and `ci` comes last.
- diff-bug #6: other easystats arguments (`bootstrap`, `standardize`, …) are ignored silently — reject (planned change): Scope Out says so.
- diff-bug #7: blocks 3 and 4 each build all four fits to use one — fix now: a `mp_twoway()` helper.
- diff-bug #8: no test for a non-numeric, vector or `NA` `ci`, or for the tolerance — fix now: four expectations added (`"0.95"`, `c(0.95, 0.95)`, `NA_real_` refused; `0.1 * 9.5` accepted).
- diff-bug #9: `format_table()` and `export_table()` keep the all-`NA` columns — reject (false): `?icc` scopes the hiding to the printed table.
- blame-history #1: the supported-surface sentence lists the new table implicitly, and the paragraph omits `summary()`/`print()` — reject (false): the paragraph's first sentence names "the methods below", which include `summary()` and `print()`, and the table's membership follows D-051.
- blame-history #2: `@param model` now carries two meanings — reject (planned change): the parameters generic fixes the argument name, and one Rd page holds one entry per name; the added sentence states the second meaning.
- blame-history #3: the printer claims (all-`NA` columns hidden, `Level` in the label) have no test, and `?icc` is silent on column order — fix now: a printer test block (with a two-way control that shows a filled column) and the sentence "Their order is not, except that `Parameter` is always the first column".
- blame-history #4: the `R/zzz.R` header names only `autoplot.intraclass_dstudy()` — fix now: it names both autoplot methods.
- blame-history #5 to #8: method export, NEWS placement, WORDLIST order, DESCRIPTION order — no finding (noted).
- prior-review #1: unpinned `?icc` printer claims — fix now (same fix as blame-history #3).
- prior-review #2: column names pinned by `expect_setequal`, not exact order — reject (planned change): AC1 asserts the set by design (D-038, D-051).
- prior-review #3: "easystats" has no gloss in NEWS — fix now: NEWS and `?icc` say it is the family of packages that parameters belongs to.
- prior-review #4: `(D-051)` in code comments — reject (style): the repo's code comments cite record ids throughout, and M157's rule covers messages users see.
- prior-review #5: `@param model` placement — reject (false): the reviewer found no dangling referent, and the reorder it noted is fixed by diff-bug #5.
- fix-now commit b728822 holds every fix-now item above; the method now lives in `R/model-parameters.R` rather than T2's `R/icc-methods.R`, with no change to what it does.
- Re-verification on b728822 (the fix-now commit): AC1 block 20 expectations, AC2 block 44, AC3 block 2, all 0 failed; AC4 block (now block 5) 7 expectations, 0 failed, including `expect_error(model_parameters(x, ci = 0.90), class = "intraclass_error", regexp = "conf_level")` and the `ci = 0.95` `identical()` pass-through (the `intraclass_ci_level` subclass named in the AC4 evidence line above is gone; AC4 never required it); the new printer block 4 ran 8 expectations, 0 failed. AC5: all 5 `test_that()` blocks open with `skip_if_not_installed("parameters")`, the grep lists only the new test file, R/zzz.R:20 holds the registration, NAMESPACE has 0 mentions. AC6: man/icc.Rd:558 holds the method bullet with the mapping and :480 the `ci` entry; `devtools::document()` left no diff; `check_pkgdown()` "No problems found".
- Consistency gate on b728822: `cairn_validate.py` all checks passed; `devtools::document()` no diff; README.Rmd not touched, so README.md stays in sync; `pkgdown::check_pkgdown()` no problems; NEWS.md has the bullet; the two new files are under `R/` and `tests/`, so no `.Rbuildignore` entry is owed; `air format --check .` clean. No DESIGN principle changed, so `cairn_impact.py` is skipped. `devtools::check()` and the full suite run separately for AC7.
- AC7 evidence: on b728822, the review commit's code (`git diff --name-only b728822 HEAD -- . ':!cairn/'` lists 0 files): `devtools::test()` printed no "Failed" section, with 4 skips (2 for vignettes not installed, 2 where glmmTMB's point fit dies on the reducer frames); `devtools::check()` reported 0 errors, 0 warnings, 0 notes in 14m 21s.

