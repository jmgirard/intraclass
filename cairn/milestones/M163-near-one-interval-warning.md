<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M163: glmmTMB and lme4 intervals whose lower limit lies within 1e-12 of 1 come with a classed warning

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — `icc()` gains a warning that users see and can catch by class   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m163-near-one-interval-warning   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

A glmmTMB or lme4 Monte-Carlo or bootstrap interval whose lower limit lies within 1e-12 of 1 is still reported, and `icc()` tells the user, through a classed warning, that data with almost no residual variation can give such an interval.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** A helper beside `refuse_zero_width()` in `R/ci-montecarlo.R`, called by `mc_ci()` and `bootstrap_ci()` after the equal-limits refusal. On a glmmTMB or lme4 fit, when the lower limit of at least one interval is finite and greater than 1 − 1e-12, it signals one `intraclass_unresolved_interval` warning through `warn_intraclass()` and returns the intervals unchanged. The hint check in `boundary_method_usable()` already muffles warnings, so the warning reaches the user only from the dispatched method. Records: D-054, a NEWS entry, the `ci_method` entry of `?icc`, the header comment of `refuse_zero_width()`, and the DESIGN.md Boundary-fit policy rows for Monte-Carlo and Bootstrap.

**Out:**
- A refusal of these intervals, or any width bound. The user chose the warning at the plan gate, and D-049's exact-equality rule stands.
- SEARLE and Burch intervals of exactly [1, 1] on near-flat data, found by the plan probe, and the other `ci_method` values. They go to the new candidate row "Classical intervals exactly [1, 1] on near-flat data".
- The lavaan and brms engines. They stay in item (b) of the row "two-way data with zero residual".
- `d_study()` intervals. Their interval rule stays in item (d) of the row "M158 review follow-ups on the glmmTMB boundary path".
- Items (b) to (d) of "M161 review follow-ups on the flat-scores refusal". They stay in that row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: On a glmmTMB or lme4 fit, when the lower limit of at least one interval that `mc_ci()` or `bootstrap_ci()` returns is finite and greater than 1 − 1e-12, the function signals exactly one warning of class `intraclass_unresolved_interval`, which also carries `intraclass_warning`. Its return value is `identical()` to the one it gives with that warning muffled. It signals no warning of that class when every lower limit is at most 1 − 1e-12, or on a lavaan fit. When one interval has exactly equal limits, the call aborts with `intraclass_zero_width_interval` and signals no warning of the new class, also when another interval of the same call lies within 1e-12 of 1. The stubbed fits that T1 lists show each of these on both engines under both functions.
- [ ] AC2: On a grid of `icc()` calls, each call either aborts with `intraclass_singular_fit` or returns an `intraclass_icc` result. A returned result comes with the warning exactly when the lower limit of one of its `tidy()` rows is greater than 1 − 1e-12, and at least one call of the grid returns a result with the warning. The grid runs each frame below on the glmmTMB and lme4 engines under `ci_method = "montecarlo"` and `"bootstrap"`, with `seed = 1`. (a) M161's near-flat frame with `model = "oneway"`: 10 subjects and 3 raters, each score its subject's index, with 1e-12 added to one score. (b) The exactly additive frame of `tests/testthat/test-zero-residual.R` with 3 subjects and 2 raters, with `model = "twoway"`. (c) 20 subjects and 3 raters with rater noise SD 1e-7, drawn under a fixed seed, with `model = "twoway"`. The 20-subject frame with rater noise SD 1e-5 in `tests/testthat/test-glmmtmb-false-zero.R` signals no warning of the new class on either engine under either method.
- [ ] AC3: The warning's message, rendered with `cli::format_message()`, says how many intervals have a lower limit within 1e-12 of 1, and gives the right count when that is 1 and when it is 2. It says that data with almost no residual variation can give such an interval, so its width may reflect rounding rather than the data. It names the class `intraclass_unresolved_interval` as the way to silence the warning.
- [ ] AC4: The development section of `NEWS.md` has one entry saying that a glmmTMB or lme4 Monte-Carlo or bootstrap interval whose lower limit lies within 1e-12 of 1 is now reported with an `intraclass_unresolved_interval` warning. The `ci_method` entry of `?icc` says the same.
- [ ] AC5: The `verify` slot of `cairn/PROFILE.md` is clean. `devtools::document()` and `devtools::test()` pass, and the raw Status line of `devtools::check()` shows no ERROR, WARNING or NOTE.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Write the AC1 and AC3 tests in a new `tests/testthat/test-unresolved-interval.R`, reusing the stub shapes of `test-glmmtmb-false-zero.R:297-332` for glmmTMB, lme4 and lavaan under both functions. Stubs: one near-1 interval (a component spread over [0, 1e-13]); two near-1 intervals after a wide one (one warning, count 2); a lower limit near 1 − 2e-12 (no warning); an equal-limits interval beside a near-1 one (abort, no warning). Match the warning by class, since a bootstrap stub can also raise `intraclass_bootstrap_dropouts`. Render messages with `cli::format_message()` (LESSONS, M93). Run them on the unchanged code and record that they fail.
- [ ] T2: Add the helper beside `refuse_zero_width()` and call it from `mc_ci()` (`R/ci-montecarlo.R:238`) and `bootstrap_ci()` (`R/ci-bootstrap.R:96`) after the refusal, with a comment naming D-054 (GP7). The helper takes no `hint`, since forcing that promise runs the hint trials. Name the 1e-12 bound once. Update the header comment of `refuse_zero_width()`, which says such lme4 intervals "are reported".
- [ ] T3: Write the AC2 test. Assert the rule on each call and keep the anti-vacuity check a floor of one warning over the grid, not a count per platform (GP9). Add `skip_on_cran()` and keep `mc_samples` and `boot_samples` small. Run the 1e-5 test in `test-glmmtmb-false-zero.R` on both engines and add the no-warning check.
- [ ] T4: Write the NEWS entry and the `?icc` text, then run `devtools::document()`. Update the DESIGN.md Monte-Carlo and Bootstrap rows to name the warning and cite D-054. If a `test-boundary-policy.R` pin names those rows' old text, update it.
- [ ] T5: Run `devtools::test()` and read WARN 0 (LESSONS, M150). Run `devtools::check()` and read the raw Status line (LESSONS, M127). Run `lintr::lint_package()` and `air format --check .`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: what to work on — lme4 [1, 1] intervals (item (a) of rows "two-way data with zero residual" and "M161 review follow-ups on the flat-scores refusal"). Hand-off — plan and implement.
- 2026-10-18: plan probe (scratch scripts, lme4 Monte-Carlo, seed 1): near-flat one-way frame gave ICC(1) 1 − 7.8e-15, limits 1 − 2.5e-14 and 1 − 2.5e-15; exactly additive two-way frames gave ICC(C,1) and ICC(C,k) lower limits from 1 − 9.2e-14 to 1 − 1.2e-14, and valid ICC(A) intervals such as 0.42 [0.02, 0.95] (3 subjects, 2 raters).
- 2026-10-18: plan probe, 20 subjects and 3 raters with rater noise SD s: lme4 and glmmTMB both resolve s = 1e-7 (1 − ICC 9e-15, width 1.5e-14 to 1.7e-14), s = 1e-6 (1 − ICC 9e-13, width 1.6e-12) and s = 1e-5; s = 1e-8 and below abort with `intraclass_singular_fit`. At s = 1e-7 SEARLE exact-F gives 1 − lower 1.9e-14 against Monte-Carlo 2.1e-14, so those narrow intervals are correct.
- 2026-10-18: second question round, posed because the first round chose the work and the probe showed the planned refusal would also refuse correct intervals: approach — warn, do not refuse.
- 2026-10-18: plan gate chose a warning over a refusal below a width because no width or fitted residual tells degenerate data from data with noise 1e-7 (probes above); falsified by a fit statistic that separates the two.
- 2026-10-18: plan chose the bound 1e-12 on the lower limit because degenerate data put it within 1e-13 of 1 and s = 1e-6 data put it about 2e-12 from 1; falsified by degenerate data on some platform with a lower limit further than 1e-12 from 1.
- 2026-10-18: plan chose the warning inside `mc_ci()` and `bootstrap_ci()` over one in `icc()` because the equal-limits refusal already sits there and `boundary_method_usable()` muffles warnings from its trial runs (`R/boundary-hint.R:288-302`); falsified by the warning reaching a user from a hint trial run.
- 2026-10-18: plan probe found SEARLE and Burch report exactly [1, 1] on the near-flat frame on glmmTMB and lme4; out of scope, new candidate row.
- 2026-10-18: collisions: D-049 and D-053 quoted ("any width bound refuses some correct interval near 1"); not superseded, since nothing is refused. D-053's Consequences sentence on [1, 1] intervals is annotated by D-054. D-004 requires an entry for the Boundary-fit policy change. Candidate rows absorbed in part: "two-way data with zero residual", "M161 review follow-ups on the flat-scores refusal". GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 7 findings and 1 note, all fixed. Its run: every glmmTMB call on the near-flat and additive frames aborts, and lme4 aborts on the near-flat frame under `model = "twoway"`. (1) AC3 and the Goal claimed degenerate data "give the same output", false where glmmTMB aborts: narrowed to "can give such an interval". (2) AC2 named no model: set per frame. (3) AC2 reached glmmTMB only through aborts: frame (c), noise SD 1e-7, added, and the 1e-5 control runs on both engines. (4) AC1's abort control could not fail, and nothing tested the count or the bound's near side: stubs added in T1. (5) "Exactly one warning" read as any class, and "the same intervals" had no reference: worded by class and `identical()` to the muffled call. (6) AC1 and AC2 bound the test's structure: restated as behavior, layout moved to T1 and T3. (7) Note: a helper that took `hint` would run the hint trials: T2 says it takes none. Also noted: `d_study()` calls neither function, so the warning appears at most once per `icc()` call.
- 2026-10-18: lessons surfaced: M162 (print raw numbers with `sprintf("%.17g")`), M93 (`cli::format_message()`), M150 (`expect_warning()` takes one warning; read WARN 0), M141 (CI lints `tests/`), M127 (raw Status line). No dependency change and no outward action beyond the merge-gate PR.
- 2026-10-18: started /milestone-implement on branch m163-near-one-interval-warning.
- 2026-10-18: T1: `test-unresolved-interval.R` stub tests written. On the unchanged code the two warning tests fail and the three controls pass. A planted swap of the refusal and the warning in `mc_ci()` fails the abort-order test on both engines.
- 2026-10-18: T2: `warn_unresolved_interval()` and `unresolved_interval_bound` added beside `refuse_zero_width()`, called after it in `mc_ci()` and `bootstrap_ci()`; it takes no `hint`. Message: "{n} interval{?s} {?has/have} a lower limit within 1e-12 of 1", then the rounding bullet and the class to suppress. Stub tests pass.
- 2026-10-18: T3: grid test added to `test-unresolved-interval.R`, and the 1e-5 control there on both engines, with the frame built as in `test-glmmtmb-false-zero.R` rather than editing that glmmTMB file's test. Local outcomes: 7 of 12 calls return a result and all 7 warn (lme4 on all three frames under both methods, glmmTMB Monte-Carlo on the noise 1e-7 frame); 5 abort with `intraclass_singular_fit`. With the helper made a no-op, the grid test fails 8 times.
- 2026-10-18: T4: NEWS entry, `?icc` `ci_method` text (`devtools::document()` rewrote `man/icc.Rd`), DESIGN.md Monte-Carlo and Bootstrap rows cite D-054. `test-boundary-policy.R` pins no text of those rows. NEWS lint count back to main's 15 after replacing "may". `air format .` and `lintr` on the changed files clean.
- 2026-10-18: claim audit: 44 claims read, 2 corrected — NEWS.md, tests/testthat/test-unresolved-interval.R. (1) NEWS gave the additive example as if for both engines, but glmmTMB aborts on it: scoped to lme4. (2) The 1e-5 frame's lower limits lie 5e-11 to 2e-10 from 1, not "about 1e-10". Borderline note taken: NEWS and `?icc` now say a correct interval from noise of about 1e-7 also gets the warning, and the code comment cites the SEARLE agreement. The reader's re-read found all corrections accurate.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
