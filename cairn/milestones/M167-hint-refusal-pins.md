<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M167: The boundary hint's verification counts a refused interval as unusable on glmmTMB and lme4, pinned by tests

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** internal — tests and a test helper only; no package code changes   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m167-hint-refusal-pins   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Tests pin that `boundary_method_usable()` judges a Monte-Carlo or bootstrap candidate unusable when the equal-limits refusal fires on a glmmTMB or lme4 engine.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Items (b) and (c) of "M158 review follow-ups on the glmmTMB boundary path", and item (b) of "M162 review follow-ups on the engine re-raise".
- Tests in `tests/testthat/test-boundary-abort-hint.R` for `boundary_method_usable()` (`R/boundary-hint.R:204`) with `method = "montecarlo"` and `"bootstrap"`, on engine objects named glmmTMB and lme4 whose draws give one interval with equal limits.
- A label of its own in `bh_site()` (`tests/testthat/test-boundary-abort-hint.R:91`) for the zero-width refusal's message, so the M93 sweep names that abort rather than reading it as "other".
- A probe of item (b)'s unconfirmed half: whether a bootstrap refusal's hint can name `"montecarlo"` while the Monte-Carlo interval on the same fit is nearly collapsed. A confirmed case becomes a candidate row; no package code changes here.

**Out:**
- Items (a), (e) and (f) of the M158 row → M165; item (d) → M166.
- Items (a) and (c) of the M162 row, which stay in that row.
- Any change to which methods the hint names. A confirmed near-collapse case goes to a candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: On the T1 stub engines, whose every draw gives `subject = residual = 1` (single-rating one-way ICC 0.5), with the one estimand `icc_estimand(oneway = TRUE)`, `boundary_method_usable()` returns `FALSE` for each of `method = "montecarlo"` and `"bootstrap"` on the stub whose `engine` is `"glmmTMB"` and on the one whose `engine` is `"lme4"`. The same four calls with `refuse_zero_width()` replaced by a function that returns its intervals unchanged return `TRUE`.
- [x] AC2: `devtools::test()` passes with WARN 0. `lintr::lint_package()` reports nothing, and `air format --check .` passes.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1, T2, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Add the AC1 tests. Build the engine objects as stubs in the shape `mc_ci()` and `bootstrap_ci()` read (`estimate`, `vcov`, `to_components`, `simulate_refit`, `engine`), as `ui_mc_stub()` and `ui_boot_stub()` in `test-unresolved-interval.R` do, with components that put the single-rating ICC at 0.5. Replace `refuse_zero_width()` in the namespace for the control (LESSONS, M164). Confirm that the `FALSE` case reaches the refusal: with the refusal left in place, call `mc_ci()` and `bootstrap_ci()` directly on the same stubs and assert the class `intraclass_zero_width_interval` (failure-identity rule).
- [x] T2: Add a label for the zero-width refusal to `bh_site()`, matched on a phrase of the message `refuse_zero_width()` renders. Assert that `bh_site()` gives that label for the message of a real refusal raised from the T1 stubs, and still gives `"other"` for an unrelated message. Add the label to the M93 sweep's "never reached" assertions beside `"C"` and `"other"`.
- [x] T3: Probe item (b)'s second half in a scratch script. Search for data on which `ci_method = "bootstrap"` on a glmmTMB or lme4 fit aborts with `intraclass_zero_width_interval` and the hint names `"montecarlo"`, then print that Monte-Carlo interval with `sprintf("%.17g", x)` (LESSONS, M162). Record the search and its result in a work-log line. If a case is found, add a candidate row with the data and the interval (search-first).
- [x] T4: Run `devtools::test()` and read WARN 0 (LESSONS, M150). Run `lintr::lint_package()` over `tests/` (LESSONS, M141) and `air format --check .`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — part of the split of the [high] candidate row "M158 review follow-ups on the glmmTMB boundary path" (see M165's work log for the split).
- 2026-10-18: plan chose to record a confirmed near-collapse case as a candidate row over changing which methods the hint names here, because the case is unconfirmed and the change would reach users; falsified by a T3 case that a user can reach.
- 2026-10-18: criteria audit (reduced mode, fresh Opus reader, probe in scratch) returned 3 findings. Fixed: (1) AC1 narrowed to the T1 stubs and the one estimand. Answered: (2) AC2 keeps `lintr::lint_package()` over the whole package, since CI's lint job runs it and main is lint-clean; (3) T2's `bh_site()` label is a test-helper property, so it maps to AC2 and takes no criterion of its own. Probe: zero `vcov` and constant `simulate_refit` reach the refusal on both engines and both methods, the 25-resample screen included; [0.5, 0.5] passes `boundary_interval_usable()` at n0 = 3.
- 2026-10-18: lessons surfaced: M164 (namespace replacement), M141 (lint covers `tests/`), M162, M150.
- 2026-10-19: implement started; branch `m167-hint-refusal-pins` cut from origin/main at 54ec3a9.
- 2026-10-19: implementation choice: one stub `hr_stub(engine)` carries both the Monte-Carlo and bootstrap fields (zero `vcov`, constant `simulate_refit`), and the tests sit in a new section at the end of `test-boundary-abort-hint.R`.
- 2026-10-19: T1 done. On both engines `mc_ci()` and `bootstrap_ci()` abort with `intraclass_zero_width_interval` on the stubs; `boundary_method_usable()` returns FALSE for both methods, and TRUE with `refuse_zero_width()` mocked to return its intervals. Test file: FAIL 0, WARN 0, PASS 1343.
- 2026-10-19: T2 done. `bh_site()` labels the refusal `"Z"`, matched on "lower and upper limits are equal"; the label test reads `"Z"` from real refusals of both reducers on both engines and `"other"` for an unrelated message, and the M93 sweep asserts `"Z"` is never reached. Plant: the pre-T2 `bh_site()` gives `"other"` on the same refusal message. Test file: FAIL 0, WARN 0, PASS 1357.
- 2026-10-19: T3 done, no case found, so no candidate row. Two scratch probes ran `icc(ci_method = "bootstrap", boot_samples = 50, seed = 1)` on 144 engine-by-data cases: (1) 96 cases, glmmTMB and lme4, one-way and two-way, on permuted equal-mean data, 1-3 integers, and near-flat data (noise SD 1e-6, 1e-9), sizes 6x3 and 10x4, seeds 1-3; (2) 48 one-way cases on near-flat data with noise SD 1e-7, 3e-8, 1e-8, 3e-9, sizes 6x3, 10x4, 20x3, seeds 1-2. None aborted with `intraclass_zero_width_interval`. The aborts were lme4's singular-fit refusal, the engine re-raise (D-053), and the refits-converged guard; lme4 near-flat intervals that returned had limits that differ, for example [0.99999999999998357, 0.999999999999999].
- 2026-10-19: T4 done. `devtools::test()`: FAIL 0, WARN 0, SKIP 2, PASS 11362. `lintr::lint_package()`: 0 lints. `air format --check .`: clean.
- 2026-10-19: claim audit: not owed — internal tier.
- 2026-10-19: implement complete; status set to review.
- 2026-10-19: step-7 approval: m167-hint-refusal-pins approved for merge

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review

- AC1 evidence (2026-10-19, fresh scratch script independent of the test file, at 3e01215): stubs with zero `vcov`, `to_components` and `simulate_refit` giving subject = residual = 1 (point ICC printed 0.5), estimand `icc_estimand(oneway = TRUE)`, n0 = 3. With the refusal in place, `boundary_method_usable()` returned FALSE for montecarlo and bootstrap on glmmTMB and on lme4 (4 of 4). With `refuse_zero_width()` replaced by a pass-through via `testthat::with_mocked_bindings()`, the same four calls returned TRUE (4 of 4). PASS.
- AC2 evidence (2026-10-19, at 1d13757, after the review fixes): `devtools::test()` FAIL 0, WARN 0, SKIP 2, PASS 11362. `lintr::lint_package()` 0 lints. `air format --check .` clean. PASS.
- Consistency gate (2026-10-19): `cairn_validate.py` all checks passed (exit 0); no principle changed, so `cairn_impact` skipped; `devtools::document()` left no diff; `pkgdown::check_pkgdown()` no problems; `devtools::check()` at 1d13757 0 errors, 0 warnings, 0 notes; README and NEWS untouched (internal tier, no user-visible change, so no NEWS entry owed); no new top-level files.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the mock of `refuse_zero_width()` drops the real defaults for `call` and `hint` — fix now, fixed 1d13757
- diff-bug #2: the FALSE assertions and the TRUE control sit in separate `test_that()` blocks, so the first block's causal name rests on the second — fix now (control folded into the first block), fixed 1d13757
- diff-bug #3: the `bh_site()` test's `bootstrap_ci()` call omits `seed = 1` — fix now, fixed 1d13757
- diff-bug #4: `expect_false("Z" %in% …)` repeats what `expect_setequal` enforces — reject, planned change (T2 asks for the assertion; it names the failure)
- diff-bug #5: the class checks on the stubs appear in two tests — reject, style
- diff-bug #6: ROADMAP rows "M158 review follow-ups on the glmmTMB boundary path" and "M162 review follow-ups on the engine re-raise" still list the pinned items — reject, planned change (step-9 hygiene graduates or narrows them)
- diff-bug #7: AC2 is unticked — reject, false (review ticks it against its own evidence)
- diff-bug #8: no test pins that a stub under a non-gated engine stays usable — reject, false (`test-glmmtmb-false-zero.R:428` pins a lavaan fit's equal limits as reported, not refused)
- blame-history #1: the file header still names three CI-stage sites; also no D-entry records that the refusal carries the hint, and no real-data case of it is on record — fix now (header), follow-up (rest) to new row "Equal-limits refusal unseen on real fits", fixed 1d13757
- blame-history #2: the open half of M158 item (b) could be dropped — reject, planned change (the plan files a row only for a confirmed case; T3's null result is in the work log)
- blame-history #3: the sweep comment "A or B" omits Z — fix now, fixed 1d13757
- blame-history #4: the Z phrase straddles a source line continuation — reject, false (the label test reads "Z" from real rendered refusals, so a break fails loudly; diff-bug probed cli widths 20 to 200)
- prior-review #1: the near-collapse half of M158 item (b) is probed, not pinned — reject, planned change (Scope: probe only)
- prior-review #2: `expect_false()` passes on any error, since `boundary_method_usable()` swallows errors — fix now (same fix as diff-bug #2; identity asserted beside it), fixed 1d13757
- prior-review #3: the identity checks run 50 resamples while the usability path screens at 25 — reject, false (the stub's refits are constant at any count, and the control flip shows the cause)
- prior-review #4: the missing seed — fix now (same as diff-bug #3), fixed 1d13757
- prior-review #5: engine loops do not label failures — reject, style
- ripple #1: the header count of sites is stale — fix now (same as blame-history #1), fixed 1d13757
- ripple #2: ROADMAP M158 row items (b), (c) stale — reject, planned change (step-9 hygiene)
- ripple #3: ROADMAP M162 row item (b) stale — reject, planned change (step-9 hygiene)
- ripple #4: the sweep comment omits Z — fix now (same as blame-history #3), fixed 1d13757
