# M160: easystats model_parameters method for icc() results

**Status:** done (2026-10-17, PR #179 https://github.com/jmgirard/intraclass/pull/179)

**Goal:** `parameters::model_parameters()` on an `icc()` result returns its estimates as an easystats parameters table, with `parameters` an optional dependency only.

**Outcome:** `model_parameters.intraclass_icc(model, ci = NULL, ...)` in `R/model-parameters.R` returns `tidy()` as a base data frame of class `c("parameters_model", "see_parameters_model", "data.frame")`.
Its columns are `Parameter`, `Type`, `Level`, `Occasions`, `SF_Index`, `Coefficient`, `SE`, `CI`, `CI_low`, `CI_high` and `Method`. Each is a renamed `tidy()` column, with `Parameter` first.
A `title` attribute ("Intraclass correlation coefficients") replaces the printer's "Fixed Effects" heading.
A `ci` other than the fit's level aborts as a plain `intraclass_error`, compared with `all.equal()`. Non-numeric, vector and `NA` values abort too.
`.onLoad()` registers the method through `s3_register()`, beside `autoplot`. `parameters` joined `Suggests:` only.
The method sits in its own file so that its roxygen block collates after `icc()`'s, which keeps `?icc`'s arguments in signature order.
A `nolint` block suppresses `object_name_linter` and `object_length_linter`, as in `R/autoplot.R`.
`?icc`, NEWS, `_pkgdown.yml` and `inst/WORDLIST` (easystats) were updated. `tests/testthat/test-model-parameters.R` has 5 blocks that skip without parameters.

**Decisions:** D-051 (parameters in Suggests only; the table's column names join D-035's public surface, and their order is not contract apart from `Parameter` first).

**Review:** The claim audit read 21 claims and corrected 3.
The three-lens fan-out found 22 items: 8 fixed in `b728822`, 3 sent to the new candidate row "easystats tools beyond model_parameters on icc() results", 7 rejected, and 4 noted.
Fixes: the method moved to its own file, the `intraclass_ci_level` subclass was dropped, tests were added for `ci` values and printed-table claims, `?icc` states column order and repeated `Parameter`, "easystats" got a gloss, fewer test fits, and the zzz.R header was fixed.
The first `devtools::check()` failed on the spelling of "easystats". On `b728822` check gave 0 errors, 0 warnings and 0 notes, and `devtools::test()` had 0 failures.
On the PR, the lint job failed on the method name. After the `nolint` fix in `0809cdf`, all 11 checks passed.
No lesson was added, because LESSONS.md has no byte room.
