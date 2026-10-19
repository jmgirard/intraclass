# M168: The engine re-raise passes converted warnings and stack overflows unchanged

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — changes which error class `icc()` callers receive and the text of two error messages
- **Branch/PR:** m168-engine-reraise-passthrough

## Goal

On the glmmTMB and lme4 engines, `icc()` stops labeling as a singular fit the engine errors that R itself marks as something else, and its error messages say only what the package knows.

## Scope

**In:** `reraise_engine_error()` (`R/abort.R:216`) passes two kinds of error unchanged. The first is an error that R converts from a warning under `options(warn = 2)` or above. The second is an error of R's class `stackOverflowError`. Neither check reads message text from an engine (D-022's reason). The first line of the re-raised message changes from "The <engine> engine failed on these data." to "The <engine> engine stopped with an error." A variance component that the data cannot identify stays in the message as one possible cause. The equal-limits refusal of `refuse_zero_width()` (`R/ci-montecarlo.R:195`) drops its clause "for example for scores that do not vary within subjects". D-052 refuses such data before any fit, so the clause names data that cannot reach this message. Since M166, the band refusal of `d_study()` shows the same bullet. The milestone also edits `?icc` (`score`), the development NEWS bullet on the re-raise, and the DESIGN.md Classed-deferral line. D-059 supersedes D-053's re-raise rule in part.

**Out:** An allocation failure and a bug in package code stay re-raised as `intraclass_singular_fit`. R gives both a plain `simpleError`, so only message text can tell them apart (D-053 Consequences). This milestone graduates the row "M162 review follow-ups on the engine re-raise". The lavaan and brms engines stay outside the re-raise (row "two-way data with zero residual"). Real-data cases of the equal-limits refusal stay with the row "Equal-limits refusal unseen on real fits".

## Acceptance criteria

- [ ] AC1: Under `options(warn = 2)`, a warning planted at either of two sites reaches the caller of `icc()` as R's own converted error, not as `intraclass_singular_fit`. The two sites are the glmmTMB fit, whose held warnings are replayed through cli, and `lme4::lmer()` inside `fit_lme4()`, whose warning handler passes them on through cli. A test in `tests/testthat/test-zero-residual.R` plants one warning at each site, with no braces in its text. At `warn = 2`, it asserts that the class of the caller's error is `c("simpleError", "error", "condition")`, that its message starts with `gettext("(converted from warning) ", domain = "R")`, and that it contains the planted text. At `warn = 0`, on data where no SD falls below `glmmtmb_zero_sd`, the same call returns a result and signals exactly one warning whose message contains the planted text.
- [ ] AC2: An error that inherits R's class `stackOverflowError` and reaches the glmmTMB or lme4 engine dispatch of `icc()` reaches the caller as the same condition object, not as `intraclass_singular_fit`. An error that an engine function catches itself, such as in the glmmTMB second start, is out of scope. On each engine, a stub engine function signals a condition of class `c("expressionStackOverflowError", "stackOverflowError", "error", "condition")`, and a second stub one of class `c("CStackOverflowError", "stackOverflowError", "error", "condition")`. The test asserts that the caller's condition is `identical()` to the planted one.
- [ ] AC3: An engine error that is not an rlang error, does not inherit `stackOverflowError`, and is not R's conversion of a warning is still re-raised as `intraclass_singular_fit`, with that error as its parent. Tests show this on each engine at `warn = 0` and at `warn = 2` with no warning before the error. A further test runs at `warn = 2` with a warning that a handler around `icc()` muffles, followed by a stub engine error with a `NULL` call, and that error is still re-raised. The re-raise and pass-through tests in `test-zero-residual.R` and the warn tests in `test-glmmtmb-fit-conditions.R` pass. What they assert does not change, except the first-line text that AC4 replaces.
- [ ] AC4: Rendered with `cli::format_message()`, the first line of the re-raised message reads "The glmmTMB engine stopped with an error." or "The lme4 engine stopped with an error.". A later bullet names a variance component that the data cannot identify as one possible cause. The existing re-raise test of `test-zero-residual.R` asserts both.
- [ ] AC5: Rendered with `cli::format_message()`, the equal-limits refusal on a glmmTMB or lme4 fit no longer contains "do not vary within subjects". It still contains "Inspect the data and the fitted variances". Tests assert both for the refusal raised by `icc()` (`test-glmmtmb-false-zero.R`) and by `d_study()` (`test-dstudy-band-checks.R`).
- [ ] AC6: `?icc` (the `score` argument) and the development NEWS bullet on the re-raise say that two kinds of error pass unchanged: an error that R converts from a warning under `options(warn = 2)`, and an error of class `stackOverflowError`. They also say that other engine errors that are not rlang errors are still re-raised. An AC1, AC2 or AC3 test asserts each of these claims.
- [ ] AC7: `devtools::test()` reports 0 failures and 0 warnings. The raw Status line of `devtools::check()` reads OK, or each NOTE has a stated reason. `devtools::document()` leaves no diff. `air format --check .` and `lintr::lint_package()` are clean. Each `data-raw/check-*` script exits 0 on the repo.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: Write the failing tests first in `tests/testthat/test-zero-residual.R`. These are the converted-warning plants on both engines at `warn = 2` and `warn = 0` (AC1), the stack-overflow stub (AC2), and the re-raise with no warning at both `warn` levels (AC3). Plant the glmmTMB warning in `glmmtmb_reml()` (LESSONS M164 for replacing a binding after `load_all()`) and the lme4 warning with `local_mocked_bindings(lmer = ..., .package = "lme4")`. Add the muffled-warning case of AC3. Make sure that each new test fails on main for its own reason (failure-identity rule).
- [ ] T2: In `reraise_engine_error()` (`R/abort.R:216`), add a calling `warning` handler. When `getOption("warn") >= 2`, it records the warning. The error handler returns without a re-raise only when the error message is identical to R's translated template applied to the recorded warning's message, `sprintf(gettext("(converted from warning) %s", domain = "R"), conditionMessage(w))`, and the error has the warning's call. A cli warning carries a `NULL` call, so the call alone does not tell the conversion from a later error. The template is R's text, not an engine's (D-022). The error handler also returns when the error inherits `stackOverflowError`. Update the roxygen block above the function. Run the M165 warn tests and the 72-call grid.
- [ ] T3: Reword the re-raised message. The first line is "The {.pkg {engine}} engine stopped with an error.", and one bullet keeps the unidentifiable variance component as one possible cause. Check each sentence with `data-raw/condition-text-profile.R` and `cairn/doctrine/prose-style.md`. Extend the existing re-raise test for AC4.
- [ ] T4: Delete the "for example" clause from the third bullet of `refuse_zero_width()` (`R/ci-montecarlo.R:195`). Add the AC5 assertions to the existing equal-limits tests in `test-glmmtmb-false-zero.R` and `test-dstudy-band-checks.R`. Run `test-boundary-abort-hint.R` again, because it pins the site of this refusal.
- [ ] T5: Edit `?icc` (`R/icc.R:231`) and the development NEWS bullet that begins "On the glmmTMB and lme4 engines, an engine error that does not come from `rlang`". Add no new bullet. Run `devtools::document()`. In DESIGN.md, update the Classed-deferral line (`cairn/DESIGN.md:229`) and the glmmTMB and lme4 rows of the Boundary-fit policy to cite D-059. If a `?icc` sentence carries a trigger word, add its row to `data-raw/mpl-doc-claims.tsv` (LESSONS M130).
- [ ] T6: Run the AC7 gate.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: milestone — it changes which error class `icc()` callers receive and supersedes part of D-053.
- 2026-10-19: absorbed candidate row "M162 review follow-ups on the engine re-raise", parts (a) and (c); (b) was closed by M167. The row's promotion conditions (a user report for (a), the next edit to the message for (c)) had not held; the user invoked the plan by name.
- 2026-10-19: collision sweep: D-053 is superseded in part by D-059 (plan commit). Rows "two-way data with zero residual" and "Equal-limits refusal unseen on real fits" are distinct scopes, cross-referenced in Out. M162 (done) shipped the re-raise; this extends it.
- 2026-10-19: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-19: plan probe (R 4.6.1): with a warning planted in `fit_glmmtmb()` under `warn = 2`, `icc()` raised `intraclass_singular_fit` "The glmmTMB engine failed on these data", parent a `simpleError` "(converted from warning) …". Memory-limit errors are plain `simpleError`; stack overflows carry `stackOverflowError`.
- 2026-10-19: lessons harvested: M93 (render with `format_message()`), M150 (`expect_warning()` consumes one warning), M164 (planting after `load_all()`), M130 (`mpl-doc-claims.tsv` rows for `?icc`), M141 (lint covers tests).
- 2026-10-19: criteria audit (full mode, fresh Opus reader): 13 findings. Fixed: AC3 now excepts the first line AC4 replaces (1), names the errors it covers (2), and adds a muffled-warning case (3); T2 makes R's template check required (3); AC2 is scoped to errors reaching the dispatch, plants both stack-overflow subclasses, and asserts `identical()` (4, 5); AC1 asserts class and template prefix (6), names its two plant sites, and fixes the `warn = 0` clause to the kept fit (7); AC6 binds claims to tests, not a writing act (10); AC7 names the `data-raw/check-*` scripts and drops `--self-test` (11). Answered: PRINCIPLES #8 gets its exception in D-059; the Principles slot holds DESIGN ids only, so it stays GP1 (12). Clean: AC4, AC5, tier (8, 9, 13).
- 2026-10-19: question set: pass-through scope — converted warnings and stack overflows (recommended); message wording — reword the first line (recommended).
- 2026-10-19: plan gate chose detecting a converted warning by R's translated template plus the warning's call over the call alone, because a cli warning has a `NULL` call and a muffled warning then lets a later `NULL`-call error pass; falsified by an R version whose conversion text differs from `gettext("(converted from warning) %s", domain = "R")`.
- 2026-10-19: plan gate chose passing converted warnings through unchanged over re-raising them under a new class, because warn = 2 asks for R's own conversion; falsified by a user asking to catch that error by a package class.
- 2026-10-19: plan gate chose deleting the "for example" clause of the equal-limits message over a new example, because no real-data case of the refusal is on record (M167); falsified by a reproducible real fit that reaches the refusal.

- 2026-10-19: T1: new tests in `test-zero-residual.R` red on main for their own reason: at warn = 2 both engines raise `intraclass_singular_fit` where R's `simpleError` is asserted (AC1), and all four stack-overflow stubs come back wrapped (AC2). The warn = 0 controls and the AC3 re-raise cases pass on main. The test asserts the prefix with `gettext("(converted from warning) ", domain = "R")` as AC1 words it; testthat runs in the C locale, where it equals R's template prefix.
- 2026-10-19: T2: `reraise_engine_error()` records warnings at warn >= 2 and passes an error that `is_converted_warning()` matches (same call, R's translated template) or that inherits `stackOverflowError`. AC1, AC2, AC3 tests, the 72-call grid (NOT_CRAN) and `test-glmmtmb-fit-conditions.R` pass. Planted a call-only `is_converted_warning()`: the AC3 muffled-warning case went red on both engines, so the test tells the two rules apart. Box left open until the full suite runs after T4.

## Decisions

## Review
