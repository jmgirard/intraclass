# M158: glmmTMB fits retry a variance stuck at zero, and a zero-width interval is refused

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP1, GP7, GP9
- **Resolves:** —
- **Surface tier:** user-facing — it changes what `icc()` returns or refuses on the default engine
- **Branch/PR:** m158-glmmtmb-false-zero

## Goal

A default-engine fit under `ci_method = "montecarlo"` or `"bootstrap"` never reports an interval narrower than `sqrt(.Machine$double.eps)`. A glmmTMB fit with a variance at numerical zero is refit from a second start, and `icc()` refuses an interval that is still that narrow.

## Scope

**In:** A second-start refit in the shared glmmTMB fit path (`fit_glmmtmb_ml_model()` in `R/engine-glmmtmb.R`). It fires when the fit leaves a random-effect or residual SD near zero, and it keeps the fit with the lower REML objective. A classed refusal (`intraclass_singular_fit`) of a zero-width interval on a glmmTMB fit under `ci_method = "montecarlo"` or `"bootstrap"`. A rewrite under GP9 of the degenerate-data test in `tests/testthat/test-boundary-abort-hint.R`, which is red on `main` since `9ea6d9a`. The Monte-Carlo overflow abort's hint, which tells a glmmTMB user to refit with `engine = "glmmTMB"`. One decision entry that supersedes D-004's glmmTMB and Monte-Carlo cells, the matching `DESIGN.md § Boundary-fit policy` rows, and one NEWS bullet.

**Out:** The second start inside bootstrap refits (`glmmtmb_simulate_refit()`). Under D-004 a refit at the boundary stays a kept draw. If a run shows a false zero inside a refit, it becomes a candidate row. An automatic cross-check against the lme4 engine. It runs a second engine inside the default path, which is close to the fallback that D-026 refused. A user report of a false zero that the second start does not fix brings the cross-check back as a question. The student's reported data, which the user chose not to re-run at the plan gate. The other engines: lme4 and lavaan share `mc_ci()` and `bootstrap_ci()`, but the refusal is gated to glmmTMB fits, and AC3 asserts that an lme4 fit is not refused. The other `ci_method` values, because they compute their own intervals.

## Acceptance criteria

- [ ] AC1: On a planted false optimum, the default engine reaches the REML optimum. `tests/testthat/test-glmmtmb-false-zero.R` masks `glmmtmb_start()` to return `NULL`, which restores glmmTMB's own start (the behavior before PR #176). It uses the 17-subject, 2-rater frame of `scale_two_way()` with the scores multiplied by 1000, for seeds 1 to 40. It fits three models: `raters = "fixed"` with `type = "agreement"`, random raters, and `model = "oneway"`. Take every seed and model where the lme4 engine reports the first ICC above 0.01. There the glmmTMB fit reports that ICC within 1e-4 of the lme4 engine. It also reports it within 1e-5 of the glmmTMB fit on the unscaled scores. On the fixed-rater model, at least one seed has lme4 above 0.01 and a glmmTMB ICC(A,1) below 1e-6 when the second start is also disabled.
- [ ] AC2: The second start never makes a fit worse. For every fit in AC1's grid, the REML objective of the fit that `icc()` keeps is at most the objective of the first fit. The grid includes at least one fit where the second start fires and its fit is kept. If the second fit raises an error, `icc()` keeps the first fit. The same test file asserts all three.
- [ ] AC3: A zero-width interval is refused on glmmTMB fits only. Take a glmmTMB fit under `ci_method = "montecarlo"` or `"bootstrap"`. If `conf.high - conf.low` for any reported estimand is below `sqrt(.Machine$double.eps)`, `icc()` aborts with a condition of class `intraclass_zero_width_interval`, which also carries class `intraclass_singular_fit`, and returns no result. One reducer-level test for the Monte-Carlo reducer and one for the bootstrap reducer fire the guard with a collapsed interval (GP9). The same reducer tests show that an lme4 fit with the same collapsed interval is not refused. Through `icc()`, every AC1 fixed-rater seed that reaches the defect with the second start disabled raises `intraclass_zero_width_interval`.
- [ ] AC4: On the 3-subject frame with zero within-subject variance in `test-boundary-abort-hint.R`, `icc(..., model = "oneway", ci_method = "bootstrap")` raises an error and returns no result. That test asserts this without naming the site that raises it. It is green on every R-CMD-check job of the PR head, which includes Ubuntu release, a job where run 37163465757 failed.
- [ ] AC5: The Monte-Carlo overflow abort names no engine the call already used. A test fires the overflow reducer directly with overflowing draws, once tagged as a glmmTMB fit and once as an lme4 fit. Rendered with `cli::format_message()`, the glmmTMB message does not contain "glmmTMB", and the lme4 message still suggests `engine = "glmmTMB"`.
- [ ] AC6: A new D-entry in `cairn/DECISIONS.md` supersedes D-004's glmmTMB fit-time cell and its Monte-Carlo and Bootstrap interval-time cells. `DESIGN.md § Boundary-fit policy` cites the entry in all three rows, and the code comment at the second start names it (GP7). `NEWS.md` gains one Bug fixes bullet, and the tests of AC1, AC3, AC4 or AC5 assert each of its claims.
- [ ] AC7: `devtools::test()` reports FAIL 0 and WARN 0. The raw Status line of `devtools::check()` reads OK. Every CI check on the PR head is green.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks

- [x] T1: Write `tests/testthat/test-glmmtmb-false-zero.R` first. It holds the AC1 grid with `glmmtmb_start()` masked, the lme4 and unscaled oracles, and the planted-defect control. Make sure that it is red on `main` before T2.
- [ ] T2: Add the second start to `fit_glmmtmb_ml_model()` in `R/engine-glmmtmb.R`. It fires on any random-effect or residual SD below a stated fraction of `sd(score)`. Its start does not route through `glmmtmb_start()`. Keep the fit with the lower `fit$fit$objective`, and route its warnings through the existing cli handler. A code comment names the new D-entry (GP7). Add the AC2 assertion.
- [ ] T3: Add the zero-width refusal where the Monte-Carlo and bootstrap intervals are reduced (`R/ci-montecarlo.R`, `R/ci-bootstrap.R`), gated to glmmTMB fits. Raise it with class `c("intraclass_zero_width_interval", "intraclass_singular_fit")`. Build its hint through the existing boundary-hint path, which names a method only after it runs (D-018). Add the two reducer-level tests, the lme4 control, and the `icc()`-level test of AC3.
- [ ] T4: Rewrite the degenerate-data test in `test-boundary-abort-hint.R` under GP9. It asserts that `icc()` raises an error and returns nothing, not which site raises it. Keep its loop over the other methods.
- [ ] T5: Make the "Refit with `engine = \"glmmTMB\"`" line of the Monte-Carlo overflow abort engine-aware (`R/ci-montecarlo.R:143`), passing the engine name into `mc_interval()`. Add the AC5 test, which calls `mc_interval()` directly (GP9).
- [ ] T6: Write the D-entry, the three `DESIGN.md § Boundary-fit policy` rows, and the NEWS bullet.
- [ ] T7: Run `devtools::document()`, `devtools::test()`, `devtools::check()` (read the raw Status line), `air format .`, and `lintr::lint_package()`.

## Work log

- 2026-10-06: created by /milestone-plan. Promoted from the candidate row "glmmTMB can report a false zero ICC with a zero-width interval" (user report, 2026-10-03). Absorbs the candidate row "The degenerate-data bootstrap test gives different outcomes on the same code". Both rows graduate at this milestone's post-merge hygiene.
- 2026-10-06: plan probes on `main` (`9ea6d9a`). 120 two-rater fixed fits at scale 1 and 1000 matched lme4 within 2.4e-5. 40 frames with no subject variance either aborted classed (non-finite Monte-Carlo draws) or returned an interval of nonzero width. With `glmmtmb_start()` masked to `NULL`, 34 of 80 large-scale fits printed ICC(A,1) 0.000 [0.000, 0.000]. 19 of those 34 raised no glmmTMB warning, so a Hessian warning cannot be the detector.
- 2026-10-06: R-CMD-check run 37163465757 on `main` (`9ea6d9a`) failed the degenerate-data test on Ubuntu release and oldrel-1. There `icc()` returned ICC 1 [1, 1] with residual variance 1.7e-33.
- 2026-10-06: the plan folds the overflow abort's hint (T5) into this milestone. The user meets that message at the same boundary, and D-029 lets a user-facing message correction plan normally.
- 2026-10-06: criteria audit (full mode, fresh Opus reader) returned 11 findings, all fixed by narrowing. AC4 named six PR jobs, but a PR runs three (`check-standard.yaml`), so it now binds the PR head's jobs. AC7 now also supersedes D-004's Bootstrap cell. AC1's control now sits inside the asserted domain, and AC1 adds random-rater and one-way models. AC3 now uses its own subclass, tests both reducers, adds an lme4 control, and binds every defect seed. AC6 no longer accepts an abort where lme4 finds a nonzero ICC. AC2 now requires one fit where the second start wins and keeps the first fit on an error. AC5 now fires the reducer directly and checks the lme4 rendering. The Goal is narrowed to the two methods and the width bound. Scope now says lme4 and lavaan share the reducers. AC7 now binds the code comment and AC5's test.
- 2026-10-06: plan kept one milestone at 8 criteria, over the split tripwire of about 7. The retry and the refusal share one D-entry and one NEWS bullet, and the refusal fixes the red `main` test, so a split ships two superseding entries for one policy change.
- 2026-10-06: question set: retry or refuse — retry from a second start, then refuse a zero-width interval. Re-run the student's two task files — no, synthetic data only, so the real-data criterion and its task were removed and the criteria renumbered. Fold in the red degenerate-data test — yes.
- 2026-10-06: plan gate chose a second start plus a zero-width refusal over refusal alone, because refusal alone gives an abort where the REML optimum exists; falsified by a planted false zero that the second start does not move off zero while lme4 reports above 0.01.
- 2026-10-06: plan chose the second start over an automatic lme4 cross-check, because the cross-check runs a second engine inside the default path, close to the fallback D-026 refused; falsified by a user-reported false zero that the second start leaves in place.
- 2026-10-06: T1 done. `test-glmmtmb-false-zero.R` holds the AC1 grid, the AC1 control and two AC2 tests, and all four fail on the unchanged code. `scale_two_way()` moved to the new `helper-glmmtmb-frames.R` so both test files share it. The second start's seams are named `glmmtmb_retry_start()` and `glmmtmb_second_fit()`, so a test can disable the retry or plant a failure in it.

## Decisions

## Review
