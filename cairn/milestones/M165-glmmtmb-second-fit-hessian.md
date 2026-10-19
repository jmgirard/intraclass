<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M165: The glmmTMB second start never trades a positive-definite fit for one that is not, and passes on only the kept fit's conditions

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — changes which glmmTMB fit `icc()` reports and which engine messages and warnings users see   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m165-glmmtmb-second-fit-hessian   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

`fit_glmmtmb_ml_model()` reports what the kept fit says: a second fit whose Hessian is not positive definite never replaces a first fit whose Hessian is, and only the kept fit's warnings and messages reach the user.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Items (a), (e) and (f) of the candidate row "M158 review follow-ups on the glmmTMB boundary path".
- (a) The kept-fit rule of `glmmtmb_second_wins()` (`R/engine-glmmtmb.R:333`) also reads each fit's `sdr$pdHess`. When both REML objectives are finite, the second fit replaces the first only when it is lower by more than 1e-6 and either the second's `pdHess` is `TRUE` or the first's is not `TRUE`. When only the second objective is finite, the second fit is kept, as now (D-049). Records: D-057 (this plan commit), the DESIGN.md glmmTMB row of the Boundary-fit policy, the development NEWS entry on the second start, and the code comments that state the kept-fit rule.
- (e) `glmmtmb_capture()` holds back messages as it holds back warnings, so a discarded fit's messages do not reach the user, and the kept fit's messages are passed on through cli. A failed first fit's held messages are shown before its error, as its held warnings are. When `getOption("warn") >= 2` and the first fit fails, its held warnings are not replayed, so the first fit's own error is the error the user gets.
- (f) Test hygiene, no criterion: `scale_two_way()` in `tests/testthat/helper-glmmtmb-frames.R` draws under a local seed and leaves the global random-number state as it found it.

**Out:**
- Items (b), (c) and (d) of the same row: (d) → M166, (b) and (c) → M167.
- The relabel of a converted warning as `intraclass_singular_fit` under `options(warn = 2)` on a kept fit. It stays in item (a) of "M162 review follow-ups on the engine re-raise".
- The bootstrap refits of `glmmtmb_simulate_refit()`, which already drop a refit whose Hessian is not positive definite.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: With both REML objectives finite, the kept-fit rule keeps the second fit in exactly these cells of the table first-fit `pdHess` × second-fit `pdHess` × objective gap: the gap is 1e-3 (the second lower) and either the second's `pdHess` is `TRUE` or the first's is not `TRUE`. At a gap of 1e-7 it keeps the first fit in every cell. The table's `pdHess` values are `TRUE`, `FALSE`, `NA` and `NULL`, in either fit's slot, at both gaps. With only the second objective finite, the second fit is kept for each of the same `pdHess` pairs. With only the first finite, the first fit is kept.
- [ ] AC2: `fit_glmmtmb_ml_model()` follows the rule on real fits. The first fit is the object passed to a replacement of `glmmtmb_retry_start()` that always returns a start, and its `sdr$pdHess` is `TRUE` (asserted). With `glmmtmb_second_fit()` replaced so that it returns a copy of that first fit with `$fit$objective` lowered by 1e-3 and `sdr$pdHess` set to `FALSE`, the returned fit is `identical()` to the first fit. With the copy's `sdr$pdHess` set to `TRUE` instead, the returned fit is `identical()` to the copy.
- [ ] AC3: When both fits return a value, each fit's warnings and messages reach the user only if that fit is kept. With the first and second fits replaced by functions that each signal two warnings and two messages of distinct text, one text of each kind containing `{`, and then return a fit, a call in which the second fit is kept signals each of the second fit's four texts exactly once and none of the first fit's. A call in which the first fit is kept signals each of the first fit's four texts exactly once and none of the second fit's. When the first fit signals one warning and one message and then an error under `options(warn = 0)`, the message text and the warning text each reach the user once before the error.
- [ ] AC4: With the first fit replaced by a function that signals one warning and then an error, `icc()` under `options(warn = 2)` and under `options(warn = 3)` aborts with `intraclass_singular_fit` whose parent's message equals the first fit's error message. No warning, message or error that reaches a handler established around `icc()` carries the warning's text; the test records warnings without muffling them. Under `options(warn = 0)` and `options(warn = 1)` the same call signals the warning's text once and then aborts with the same class and parent message.
- [ ] AC5: The development entry of `NEWS.md` on the second start says that a second fit whose Hessian is not positive definite does not replace a first fit whose Hessian is.
- [ ] AC6: `devtools::document()` leaves no diff, and `devtools::test()` passes with WARN 0. The raw Status line of `devtools::check()` shows no ERROR, WARNING or NOTE. `lintr::lint_package()` reports nothing, and `air format --check .` passes. Every `python3 data-raw/` step of `.github/workflows/lint.yaml` passes.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T3
- AC5 → T5
- AC6 → T4, T5, T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: In `tests/testthat/test-glmmtmb-false-zero.R`, add the AC1 table against the kept-fit predicate, and the AC2 real-fit pair with `testthat::local_mocked_bindings()`. Build the first fit from `scale_two_way()` scores and catch it inside the `glmmtmb_retry_start()` replacement, since two separate glmmTMB fits of the same data are not `identical()` (audit probe). Run them on the unchanged code and record in a work-log line which fail (the plan expects the 1e-3 cells with the first `TRUE` and the second not `TRUE`, and the AC2 `FALSE` case, to fail).
- [x] T2: Change `glmmtmb_second_wins()` (`R/engine-glmmtmb.R:333`) to take both fits, or their objectives and `pdHess` values, and apply the Scope's rule. Update its caller in `fit_glmmtmb_ml_model()` (`:349`). Rewrite the comments that state the kept-fit rule (`:327-332`, `:340-346`, and the block at `:245-262`) to state the Hessian condition and cite D-057 (GP7).
- [x] T3: Write the AC3 and AC4 tests first, then change `glmmtmb_capture()` (`:304`) to hold messages as it holds warnings, and pass the kept fit's messages on through cli (PRINCIPLES.md #8). Pass message text as a value, as `glmmtmb_warn()` does, so braces are not read as cli markup. In the `on_error` path, show held messages, and skip the warning replay when `getOption("warn") >= 2`. Rewrite the `glmmtmb_capture()` header comment to say both. Capture the AC4 `warn = 0` and `warn = 1` warnings in the test so the suite stays at WARN 0.
- [x] T4: Change `scale_two_way()` to draw inside `with_rng_seed(seed, ...)` or `withr::with_seed()` (`withr` is already in Suggests). Add tests that `.Random.seed` is `identical()` after a call when one was set, and still absent when none existed, and that seeds 1, 11 and 40 give the frames the old body gave. Confirm `test-glmmtmb-start-scale.R` and `test-glmmtmb-false-zero.R` pass unchanged.
- [x] T5: Edit the NEWS entry on the second start (`NEWS.md:87`) and the DESIGN.md glmmTMB row of the Boundary-fit policy to state the Hessian condition, citing D-057 in DESIGN.md. If a `?icc` sentence changes, update its `data-raw/mpl-doc-claims.tsv` row and count its fields with `awk -F'\t'` (LESSONS, M153). Run the `data-raw/` checkers with and without `--self-test`, as CI's lint job does (LESSONS, M130).
- [x] T6: Run `devtools::test()` and read WARN 0 (LESSONS, M150). Run `devtools::check()` and read the raw Status line (LESSONS, M127). Run `lintr::lint_package()`, `air format --check .`, and the `python3 data-raw/` steps of `.github/workflows/lint.yaml`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — a behavior change to running code with a design decision, from the [high] candidate row "M158 review follow-ups on the glmmTMB boundary path".
- 2026-10-18: question set: fit choice when the second fit fails the Hessian check and the first passes — keep the passing fit. warn = 2 with a failed first fit — the fit's own error. Both ahead of the row's promotion conditions, at the user's choice.
- 2026-10-18: plan split the M158 row: items (a), (e), (f) here; (d) → M166; (b), (c) → M167; all three planned now, no dependencies, because the three touch disjoint files and over 10 tasks together.
- 2026-10-18: plan chose "never trade a passing Hessian for a failing one" over "prefer the passing Hessian whatever the objective", because the second also keeps a higher-objective fit over the REML optimum; falsified by a reported case where a lower-objective first fit that fails the check aborts while a passing second fit matches lme4.
- 2026-10-18: plan chose to leave the only-second-finite cell on D-049's rule, because applying the Hessian condition there would keep a first fit whose objective is not finite, which D-048 and D-049 never allowed (audit finding 2).
- 2026-10-18: plan chose to skip the warning replay under warn >= 2 over replaying it, because the replayed warning hides the fit's own error and is then relabeled; falsified by a user report that needs the held warning as the error under warn = 2.
- 2026-10-18: criteria audit (full mode, fresh Opus reader, probes in scratch) returned 11 findings. Fixed: (1) NA/NULL in either slot; (2) only-second-finite kept on D-049's rule, AC1 states both directions; (3) the first fit is the object the retry-start replacement receives; (4) first-fit pdHess asserted; (5) AC3 scoped to both fits returning, failed first fit's messages settled; (6) two warnings and two messages, one with a brace; (7) AC4 reworded to handlers around icc() with unmuffled recording; (8) warn = 1 and 3 added; (9) item (f) moved from a criterion to T4 as test hygiene. No finding on AC5 or AC6 (former AC6, AC7). No IP or D-entry conflict once D-057 lands.
- 2026-10-18: collisions: D-048 and D-049 (kept-fit rule, "the second fit replaces the first only when it is lower by more than 1e-6") superseded in part by D-057 in this commit. Candidate rows "M158 review follow-ups on the glmmTMB boundary path" (absorbed in full across M165-M167), "M162 review follow-ups on the engine re-raise" (item (b) → M167; (a), (c) stay) and "M163 review follow-ups on the near-1 warning" (item (c) → M166). GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-18: lessons surfaced: M164 (replace a function in the namespace and in package:intraclass), M150 (WARN 0), M127 (raw Status line), M130 and M163 (lint.yaml checkers), M153 (TSV fields). No dependency change and no outward action beyond the merge-gate PR.
- 2026-10-18: implement started on branch m165-glmmtmb-second-fit-hessian, cut from main at b55567d.
- 2026-10-18: T1: AC1 table and AC2 real-fit pair added to `test-glmmtmb-false-zero.R`; on the unchanged code four failed, as planned: the 1e-3 cells with the first `TRUE` and the second `FALSE`, `NA` or `NULL`, and the AC2 `FALSE` case.
- 2026-10-18: T2: `glmmtmb_second_wins()` now takes both fits and applies D-057; comments cite D-057. `test-glmmtmb-false-zero.R` passes with NOT_CRAN=true; full-suite run pending.
- 2026-10-18: checkpoint, T3 half-done: `glmmtmb_capture()` holds messages and `glmmtmb_replay()` / `glmmtmb_replay_failed()` replace `glmmtmb_warn()`; new `test-glmmtmb-fit-conditions.R` failed 10 times on the T2 code as planned; the old `glmmtmb_warn()` brace test still needs its rename, held until the running suite ends. DESIGN.md glmmTMB row updated for D-057.
- 2026-10-18: T1-T2 verified: full `devtools::test()` on the T2 code, no failures and no warnings section.
- 2026-10-18: T3: brace test renamed to `glmmtmb_replay()`; `test-glmmtmb-fit-conditions.R` (33 expectations) and `test-glmmtmb-false-zero.R` pass with NOT_CRAN=true. Messages are replayed through `cli::cli_inform()` under "The glmmTMB engine reported a message.", in signal order with the warnings.
- 2026-10-18: T4: `scale_two_way()` draws under `with_rng_seed()` through `scale_two_way_draw()`; new seed-state and same-frame test in `test-glmmtmb-start-scale.R` passes.
- 2026-10-18: T5: NEWS second-start entry states the Hessian condition and that only the kept fit's warnings and messages are shown; no `?icc` sentence changed, so no `mpl-doc-claims.tsv` row; all eight `python3 data-raw/` lint.yaml steps exit 0; `air format --check .` passes, `lintr::lint_package()` 0 lints, `devtools::document()` no diff. The simple-english hook's NEWS.md counts are the same before and after the edit (15), all older bullets (parked row "Older NEWS bullets over 25 words").
- 2026-10-18: T6 suite: full `devtools::test()` on 7a83dbd, no failures and no warnings section; `test-glmmtmb-fit-conditions.R` ran in it.
- 2026-10-18: claim audit: 44 claims read, 8 corrected — NEWS.md, R/engine-glmmtmb.R, test-glmmtmb-fit-conditions.R, test-glmmtmb-false-zero.R, helper-glmmtmb-frames.R. Corrections: finite-objective condition in NEWS and two test names; "needs that Hessian" → draws usually overflow (probe: 3 fits with pdHess FALSE gave finite indefinite covariances, the interval aborted at the non-finite-draws guard); "before its error" → signalled before (R prints warn = 0 warnings after), with a signal-order assertion added to the AC3 failed-fit test; "non-fatal unless warn >= 2"; the warn = 2 sentence in NEWS; the helper's third user. Re-read once by the same reader: all 8 hold. D-057's Context sentence and heading corrected by D-057 Amendment 1 (one history correction for this milestone).
- 2026-10-18: the first `devtools::check()` run started before the claim fixes and was stopped; check re-run on the final code.
- 2026-10-18: T6: `devtools::check()` on 2053075, raw Status line "Status: OK" (0 errors, 0 warnings, 0 notes). Status → review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
