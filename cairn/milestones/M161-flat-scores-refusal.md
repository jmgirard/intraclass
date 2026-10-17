# M161: Data whose scores do not vary within any subject are refused classed before any fit

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP9
- **Resolves:** —
- **Surface tier:** user-facing — `icc()` refuses data it used to pass to the engines
- **Branch/PR:** m161-flat-scores-refusal

## Goal

`icc()` refuses data in which no subject's scores vary with a classed `intraclass_singular_fit` condition, raised before any model is fitted, on every engine.

## Scope

**In:** an input check in `icc()` in `R/icc.R`. It runs after the missing-score drop and the identifiability guards (about lines 1160 to 1240) and before the first fit. It fires when at least one subject has two or more non-missing scores and no subject has two different scores. The comparison is exact, with no tolerance, on the D-022 precedent. The abort goes through `abort_intraclass(class = "intraclass_singular_fit")` and names `score` (D-052). The degenerate blocks of `test-boundary-abort-hint.R` change to match. `?icc`, NEWS and the DESIGN.md Boundary-fit policy record the refusal.

**Out:** two-way data whose residual is exactly zero while scores vary within subjects. Examples are scores that vary only by rater and scores that are exactly additive in subject and rater. That remainder goes to the new candidate row "two-way data with zero residual". Zero-width lme4 intervals on other data stay with that row. The axes `raters`, `unit`, `level` and incomplete layouts are not swept by the test grid, and no criterion promises them.

## Acceptance criteria

- [ ] AC1: A test in `tests/testthat/test-flat-scores.R` builds six flat frames. In a flat frame, every subject's non-missing scores are equal. F1 crosses 10 subjects with 3 raters, and each score equals its subject's index. F2 is the F1 layout with every score equal to 4. F3 is the 3-subject, 2-rater frame of `test-boundary-abort-hint.R`, with scores `rep(c(1, 5, 9), each = 2)`. F4 holds 4 clusters of 3 subjects, crossed with 3 raters, and each score equals its subject's index. F5 is the F1 layout with 2 ratings in each subject-rater cell, and each score equals its subject's index. F6 is F1 with the score in row 2 set to `NA`. A frame's control is the same frame with subject 1's non-missing scores replaced by 1, 2, 3, … in row order. The test replaces `glmmTMB::glmmTMB()`, `lme4::lmer()`, `lavaan::lavaan()` and `brms::brm()` with stubs that record each call and then abort. A combination of `engine`, `model` (`"oneway"` or `"twoway"`) and `ci_method` is admitted for a frame if its control call reaches a stub. On each admitted combination of each frame, `icc()` on the flat frame raises a condition that inherits `intraclass_singular_fit` and `intraclass_error`, and it reaches no stub.
- [ ] AC2: Two frames close to flat are not refused. One is F1 with the score in row 1 raised by `1e-12`. The other is F1's control frame. On each frame, a test calls `icc()` with default arguments for `model = "oneway"` and `"twoway"` with the glmmTMB stub in place. All four calls reach the stub.
- [ ] AC3: On F1 and F2, a test calls `icc()` with default arguments and with `model = "oneway"`. In all four calls, the refusal's `conditionMessage()` contains the text `` `score` ``, with its backticks.
- [ ] AC4: The `?icc` help page states the rule of AC1 in words. `icc()` refuses, with `intraclass_singular_fit` and before it fits a model, data in which at least one subject has two or more scores and no subject has two different scores. `NEWS.md` has a bullet under the development-version heading that says so. The bullet also says that a one-way lme4 fit no longer returns ICC 1 with the interval [1, 1] on data whose scores differ between subjects but not within any subject. `devtools::document()` leaves no diff.
- [ ] AC5: On the review commit, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings. `air format --check .` passes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T4
- AC5 → T3, T5

## Tasks

- [x] T1: Write `tests/testthat/test-flat-scores.R` first, for AC1 to AC3. Build the six frames and their controls. Stub the four fitting functions with `local_mocked_bindings(.package = )`. Each stub records its call in a local environment and then aborts with a sentinel class. Admission reads the record, never the condition, because `fit_lavaan()` re-raises any error as `intraclass_singular_fit` (`R/engine-lavaan.R:642`, `:411`) and `mpl` and brms signal messages. Loop over the 56 combinations per frame and pass F4 its `cluster`. Skip an engine whose package is not installed. As a guard on an empty domain, assert that each frame admits at least one combination for each engine it runs. Run the file on `main` first and see AC1 fail.
- [x] T2: Add the check to `icc()` in `R/icc.R` after the identifiability guards and before the first fit. Count non-missing scores per subject and distinct values per subject. Abort when some subject has two or more scores and every subject has at most one distinct value. Use `abort_intraclass(class = "intraclass_singular_fit")`, with a message that names `{.arg score}`, says why no model can be fitted, and gives one remedy. Add a GP7 comment that cites D-052 and the exact-comparison choice.
- [x] T3: Update `tests/testthat/test-boundary-abort-hint.R`. The block at about line 246 now meets one outcome on every platform, so assert `intraclass_singular_fit` where it says the class is deliberately not asserted. Correct the comments at about lines 912 to 946 that describe raw point-fit errors on flat data. Keep the reducer-level tests of `classical_guard_observed()` as they are (GP9). Run the file.
- [x] T4: Document the rule on `?icc` in `R/icc.R`, beside the missing-score text at about line 221. Add the NEWS bullet. Add an input-side line to the Boundary-fit policy in `cairn/DESIGN.md`, citing D-052, as D-022 did. Run `devtools::document()`.
- [ ] T5: Run `devtools::test()`, `devtools::check()`, `air format --check .` and `lintr::lint_package()`. Fix what they report.

## Work log

- 2026-10-17: created by /milestone-plan.
- 2026-10-17: tier check: not run — work named at the question set.
- 2026-10-17: question set: what to work on — candidate row "Data with no variation within subjects ends in an unclassed glmmTMB error".
- 2026-10-17: question set: build now or plan only — build now, through implement and review to the merge question.
- 2026-10-17: collision sweep: absorbed the candidate row above. D-022 (input-side refusals), D-049 (zero-width glmmTMB intervals refused) and D-004's Boundary-fit policy read. D-052 extends D-022. GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-17: probe at plan time with `load_all()` on `main`, default `ci_method`. On scores equal within subjects, glmmTMB one-way raised the raw "LU factorization" error on the 3-subject frame. On every score equal, glmmTMB one-way raised "NA/NaN gradient evaluation" and lme4 raised a raw error on both models. lme4 one-way returned ICC 1 [1, 1] on the 10-subject frame. Other paths raised `intraclass_singular_fit`.
- 2026-10-17: probe at plan time: on two-way scores that vary only by rater, glmmTMB raised the raw "'a' is computationally singular" error. On exactly additive scores, lme4 two-way reported consistency ICC 1 [1, 1]. Both go to the new candidate row "two-way data with zero residual".
- 2026-10-17: plan gate chose an input check on within-subject variation over a check on each model's residual, because the first is one rule for every model, engine and design, and the second differs by design shape and would refuse lme4's finite two-way answer on additive data. Falsified by a user frame in which scores vary within subjects and a model still ends in a raw engine error.
- 2026-10-17: plan gate chose the class `intraclass_singular_fit` over a new class, because the Monte-Carlo, classical and lme4 paths already raised it on most such data, so callers who catch it keep working. Falsified by a user who needs to tell this refusal apart from a boundary deferral by class.
- 2026-10-17: criteria audit (full mode, fresh Opus reader) returned nine findings. Admission by "no condition other than the sentinel" failed for lavaan, whose wrapper re-raises the stub's error, and for `mpl` and brms, which signal messages. Fixed by admission on a recorded stub call, with "reaches no stub" in the promise. The 56-combination count and the per-engine non-empty assertion bound the instrument, so they moved to T1. The probes missed the rule's edges, so F6 (a missing score) and the `1e-12` control in AC2 were added. AC2's `ci_method`-word check held for any input-side message, so it was dropped, and AC3 now pins `` `score` `` with backticks. The real-fit control criterion was fragile, because its rater variance sat on the boundary and lme4 passed by tolerance, so it was dropped. The full suite in AC5 covers ordinary data. The `?icc` and NEWS wording was wider than the rule and wrong for lme4 on all-equal scores, so it was narrowed to the rule's words. No criterion required D-052 or the DESIGN.md row, so D-052 lands in the plan commit and the row is in T4. AC5 had no finding.
- 2026-10-17: decided toward the narrower promise: `raters`, `unit`, `level` and incomplete layouts stay out of the test grid, recorded under Out, instead of a wider grid.
- 2026-10-17: implement started on branch m161-flat-scores-refusal, cut from main at 4caf231.
- 2026-10-17: T1 minor amendment: the empty-domain guard expects every stubbed engine on each frame except lavaan on F5, because the lavaan engine refuses within-cell replicates with `intraclass_unsupported` on every combination.
- 2026-10-17: T2 placed the check just before the engine-fit dispatch in `icc()`, after every argument and design fence, so an unsupported combination on flat data still reports the fence. `test-flat-scores.R` was red on main (flat frames reached a fit) and is green with the check.
- 2026-10-17: checkpoint, half-done: T1 to T4 written, not ticked. The full `devtools::test()` run is in progress, so no task is checked off yet.
- 2026-10-17: verify: full `devtools::test()` at b6296ca's code had no failures. `test-boundary-abort-hint.R` after the T3 edit: 0 failed, 0 errors, 0 warnings, 0 skipped. `air format --check .` clean, `lintr::lint_package()` 0 lints. T1 to T4 ticked. NEWS long-sentence count stays at 12 by `data-raw/prose-profile.py --limit 25`.
- 2026-10-17: claim audit: 30 claims read, 3 corrected — R/icc.R, tests/testthat/test-flat-scores.R. A hedged fourth claim in tests/testthat/test-boundary-abort-hint.R was narrowed too. The same reader re-read all four once, and all hold.
- 2026-10-17: correction of the T2 line above: the check runs after the argument fences and most design fences, not after every fence. The lavaan replicate fence and the fences inside the CI functions come later, so on flat data those combinations now get `intraclass_singular_fit` where main gave `intraclass_unsupported` (claim audit probe: F5 lavaan two-way montecarlo and bootstrap, F3 glmmTMB two-way mpl).

## Decisions
