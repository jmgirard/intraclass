<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M162: Raw glmmTMB and lme4 errors reach the caller as intraclass_singular_fit, and lme4 refuses equal interval limits

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — it changes which conditions `icc()` raises and which lme4 intervals it reports   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m162-zero-residual-classed-errors   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

On the glmmTMB and lme4 engines, a fit that cannot support an interval ends in the package's `intraclass_singular_fit` condition, never in an engine error without a package class.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** One handler around the engine dispatch in `icc()` (`R/icc.R`, the `engine_fit <-` block). On the glmmTMB and lme4 engines, it re-raises an error that is not an rlang error as `intraclass_singular_fit`. The new error keeps the engine's message in its text and the original condition as its parent. Its message does not point a glmmTMB user at glmmTMB. The equal-limits refusal in `refuse_zero_width()` (`R/ci-montecarlo.R:175`) extends from glmmTMB fits to lme4 fits, with no width bound. The records are D-053, NEWS, the code comments that call the refusal glmmTMB-only, and the DESIGN.md Boundary-fit policy rows for lme4 and for the Monte-Carlo and Bootstrap methods.

**Out:**
- An input-side refusal of zero-residual data before any fit. The plan gate chose the engine-side approach (work log).
- lme4 intervals that print as [1, 1] on near-flat or exactly additive data. Their limits are not exactly equal, so they stay reported (D-049, D-053). They stay in the candidate rows "two-way data with zero residual" and "M161 review follow-ups on the flat-scores refusal" (a).
- The lavaan and brms engines on zero-residual data. They were not probed, and they stay in the row "two-way data with zero residual".
- Raw errors raised outside an engine function, for example in an interval function. None appeared on the AC1 grid. A raw error found there becomes a candidate row.
- Equal limits in `d_study()` intervals. They stay in item (d) of the row "M158 review follow-ups on the glmmTMB boundary path".
- Items (b) to (d) of "M161 review follow-ups on the flat-scores refusal". They stay in that row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: A new `tests/testthat/test-zero-residual.R` runs a grid of 72 `icc()` calls. The frames are two-way crossed, with 3, 5 or 12 subjects and 2, 3 or 5 raters. Their scores vary only by rater, or are exactly a subject value plus a rater value. Each frame is fitted on the glmmTMB and lme4 engines under `ci_method = "montecarlo"` and `"bootstrap"`. Every call returns a result, or aborts with a condition that inherits `intraclass_singular_fit`. The test asserts the class of each abort, so an error without that class fails it.
- [ ] AC2: On the glmmTMB and lme4 engines, an error that a dispatched engine function raises reaches the caller as `intraclass_singular_fit` when it is not an rlang error. The new error's parent is the original condition, and its message names the engine and contains the original message. Tests stub one glmmTMB and one lme4 engine function on different dispatch branches. Each stub raises a `simpleError` and an error of a non-rlang class such as `Rcpp::exception`. Controls show that an `intraclass_error` and an rlang error from a stubbed engine function pass unchanged. A plain error from a stubbed lavaan engine function also passes unchanged.
- [ ] AC3: On an lme4 fit under `ci_method = "montecarlo"` or `"bootstrap"`, an interval with two finite and exactly equal limits aborts with class `intraclass_zero_width_interval`. That condition also carries `intraclass_singular_fit`. An lme4 interval whose limits differ, also one about 1e-10 wide, is reported. A lavaan interval with equal limits is reported. The stubbed fits in `tests/testthat/test-glmmtmb-false-zero.R` test each of these under both methods. Their pin of an equal-limits lme4 interval as reported becomes a pin of the refusal.
- [ ] AC4: The development section of `NEWS.md` has one entry with two statements. Errors raised inside the glmmTMB and lme4 engines now reach the caller as `intraclass_singular_fit`. An lme4 interval whose two limits are exactly equal is now refused, as on glmmTMB. The entry does not say that an interval printed as [1, 1] is refused.
- [ ] AC5: The `verify` slot of `cairn/PROFILE.md` is clean. `devtools::document()` and `devtools::test()` pass, and the raw Status line of `devtools::check()` shows no ERROR, WARNING or NOTE.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write `test-zero-residual.R` with the AC1 grid. Fix the subject values by a seed, keep `mc_samples` and `boot_samples` small, and add `skip_on_cran()`. Run it on main and record which calls end in an error without a package class.
- [x] T2: Wrap the `engine_fit <-` dispatch in `icc()` in one handler, active for `engine` "glmmTMB" and "lme4" only. Keep the engine warnings that reach the user before the error. Write the message with cli. For lme4 it can point at glmmTMB, and for glmmTMB it points at the data. Add the AC2 tests, rendering messages with `cli::format_message()` (LESSONS, M93).
- [x] T3: Extend the gate in `refuse_zero_width()` to lme4 and update its header comment. Turn the lme4 pin at `test-glmmtmb-false-zero.R:362` into a refusal pin, and add the AC3 controls under both methods.
- [x] T4: Write the NEWS entry. Update the DESIGN.md Boundary-fit policy rows (lme4 fit-time, Monte-Carlo, Bootstrap) and the classed-deferral bullet to cite D-053. If the `test-boundary-policy.R` pins for those rows name the old behavior, update them.
- [x] T5: Run `devtools::document()`, `devtools::test()` and `devtools::check()`, and read the raw Status line. Run `lintr::lint_package()` too, since CI lints `tests/` (LESSONS, M141).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-17: created by /milestone-plan.
- 2026-10-17: tier check: not run — work named at the question set.
- 2026-10-17: question set: what to work on — zero-residual data (rows "two-way data with zero residual" and "M161 review follow-ups on the flat-scores refusal" (a)).
- 2026-10-17: question set: approach — extend the equal-limits refusal to lme4 and re-raise raw engine errors with the singular-fit class.
- 2026-10-17: plan probe on main, 36 frame and method pairs per engine (the AC1 grid): lme4 ended in a raw error in 30 ("Downdated VtV is not positive definite", "objective in x0 returns NA"), glmmTMB in 10 ("'a' is computationally singular", "LU factorization of .gCMatrix failed", "leading principal minor of order 5 is zero"). The rest ended in `intraclass_singular_fit`.
- 2026-10-17: criteria audit (full mode, fresh Opus reader) returned 6 findings. (1) lme4 [1, 1] limits are not exactly equal, so the end-to-end refusal test could not pass: put to the user (next line). (2) The goal claimed every zero-residual call aborts while the grid admits results: goal narrowed. (3) glmmTMB raw errors also come from `vcov(full = TRUE)` after the fit: the handler moved to the `icc()` dispatch. (4) The second start was not the only error-discarding site, and a glmmTMB message must not point at glmmTMB: AC2 rewritten around the dispatch, message rule added. (5) The lme4 refusal pin lost the outside-engine control: lavaan and 1e-10-wide controls added. (6) The 8×3 additive lme4 control failed on 4 of 5 seeds: cut, its role taken by AC3's controls.
- 2026-10-17: probe after the audit: on M161's near-flat one-way frame, lme4 limits were 0.99999999999998235 and 0.99999999999999911 (Monte-Carlo), not equal. Stop chip: the user chose to keep both parts and leave such intervals reported.
- 2026-10-17: plan gate chose one handler at the `icc()` dispatch over handlers at each `lme4::lmer()` and `glmmTMB::glmmTMB()` call because covariance-step errors also escape; falsified by a raw error on the AC1 grid raised outside an engine function.
- 2026-10-17: plan gate chose the class `intraclass_singular_fit` over `intraclass_engine_error` because the handler cannot tell a degenerate-data failure from another without matching text (D-022), and callers of degenerate data already catch the first (D-052); falsified by a user report of a non-degenerate failure labeled singular.
- 2026-10-17: plan gate chose "not an rlang error" as the re-raise filter over a list of pass-through classes because package and rlang errors are all rlang errors and engine errors are not; falsified by a glmmTMB or lme4 error that is an rlang error.
- 2026-10-17: collisions: D-022 quoted and not superseded (its objection was a wrapper matching text). D-048's glmmTMB-only gate superseded by D-053. D-052's Untouched clause names this data. Candidate rows absorbed in part: "two-way data with zero residual", "M161 review follow-ups on the flat-scores refusal". GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-17: lessons surfaced: M93 (render messages with `cli::format_message()`), M141 (CI lints `tests/`), M150 (`expect_warning()` takes one warning). No dependency change and no outward action beyond the merge-gate PR.
- 2026-10-17: started /milestone-implement on branch m162-zero-residual-classed-errors.
- 2026-10-17: T1: `test-zero-residual.R` written. On the unchanged code it fails with 28 of 72 calls unclassed (glmmTMB 10: LU factorization, 'a' is computationally singular; lme4 18: Downdated VtV), about 55 s. Subject values come from `round(2 * sin(i), 3)`, so the test draws no random numbers. Box left open until T2 makes it pass.
- 2026-10-17: T1, T2 done. `reraise_engine_error()` in `R/abort.R` wraps the `engine_fit` dispatch in `icc()` (the block's re-indent is most of the `R/icc.R` diff). It is a calling handler, so errors an engine function catches itself never reach it. One message for both engines names the engine and points at the data, not at glmmTMB, since glmmTMB also fails on this data; the engine's error is the parent, which `conditionMessage()` shows as "Caused by error". Grid test passes (72 calls). With the handler replaced by a pass-through, the grid test and the re-raise test failed (17 failures) and the pass-through controls stayed green. Full suite: 5 failures, all in `test-glmmtmb-false-zero.R`, which T3 had already edited while the suite ran on the pre-T3 code; the rest passed (10398).
- 2026-10-17: T3 code in: `refuse_zero_width()` now gates on glmmTMB and lme4 (`isTRUE(%in%)`, so an engine list with no `$engine` still passes). The two stubbed interval tests loop over both engines for the refusal and the 1e-10-wide control, and use a lavaan stub for the equal-limits control. Six affected test files pass (2161). Box left open until the full suite at T5.
- 2026-10-17: T4 records in: NEWS entry at the top of the development section; DESIGN.md Boundary-fit policy classed-deferral bullet, glmmTMB and lme4 fit-time rows, and Monte-Carlo and Bootstrap rows cite D-053. `test-boundary-policy.R` pins no text from those rows and no behavior that changed, so it is untouched. The simple-english hook reports 15 hits on NEWS.md, the same count as on main, none in the new entry (candidate row "Older NEWS bullets over 25 words"). Reference checkers, `air format --check` and `lintr::lint_package()` clean. Box left open until T5.
- 2026-10-17: claim audit: 31 claims read, 5 corrected — R/abort.R, tests/testthat/test-zero-residual.R, NEWS.md. (1) The roxygen block said the calling handler is why caught errors never reach it and why warnings "come first"; reworded to what the handler does (keeps engine frames, raises the warnings first). (2) "lavaan re-raises its own errors" narrowed to its `lavaan()` fit. (3) The handler covers errors anywhere in the engine function, the covariance read included; roxygen, the user message ("failed on these data", was "could not fit the model") and the DESIGN.md rows say so. (4) The NEWS entry named the fit only; it now names the covariance read too. (5) A test comment called the error object a class vector, and the non-vacuity check counted aborts that predate the change; it now counts aborts with a parent. A first T5 run was stopped before it finished so that it runs on the corrected code.
- 2026-10-17: T3, T4, T5 done at 22cd1f2. `devtools::document()` changed no file. `devtools::test()`: FAIL 0, WARN 0, SKIP 2, PASS 10408. `devtools::check()` raw Status line: OK (0 errors, 0 warnings, 0 notes). Status set to review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Pass 1, 2026-10-17. Route (d): no PR, Copilot round off, main not moved since the branch was cut (merge base 12508b6).

spawned: diff-bug, blame-history, prior-review

Findings (20), with dispositions:
- diff-bug #1: under `options(warn = 2)`, an allocation failure, or a package bug, a non-rlang error inside a glmmTMB or lme4 engine function is relabeled `intraclass_singular_fit` with a message about the data — follow-up, row "M162 review follow-ups on the engine re-raise" (a). Not load-bearing: the parent keeps the original, and D-053 records the bug case.
- diff-bug #2: NEWS said "an engine error without a package class", but the filter is "not an rlang error" — fix now, fixed e14bff3 (NEWS: "an engine error that does not come from rlang").
- diff-bug #3: `test-abort-remedy-truthfulness.R` comment still called glmmTMB's LU error unclassed — fix now, fixed e14bff3.
- diff-bug #4: the AC1 grid checks outcomes and a re-raise count, not which cells re-raise — reject, planned change: AC1 admits results by design, and pinning per-cell outcomes is platform-dependent (GP9).
- diff-bug #5: the handler keys on the `engine` argument, not on the function dispatched — reject, false: the reviewer found no reachable path where a lavaan or brms call reaches a glmmTMB or lme4 function (fences at `R/icc.R` 1056, 1912 and the replicate fence).
- diff-bug #6: no test pins that the boundary hint drops a method when the lme4 equal-limits refusal fires — follow-up, row "M162 review follow-ups on the engine re-raise" (b).
- diff-bug #7: the re-raised error has no opt-in `ci_method` bullet — reject, false: every alternative method also needs the engine point estimate, so none applies.
- diff-bug #8: `d_study()` does not refuse equal limits — follow-up, already item (d) of row "M158 review follow-ups on the glmmTMB boundary path" (Scope Out).
- diff-bug #9: `?icc` did not document the re-raise — fix now, fixed e14bff3 (`score` parameter text, `man/icc.Rd` regenerated).
- blame-history #1: the `glmmtmb_capture()` comment said a first-fit error propagates unchanged, with no word on the new re-raise — fix now, fixed e14bff3 (comment names `reraise_engine_error()` and D-053).
- blame-history #2: D-053 does not say why the lme4 `isSingular` guard misses equal-limit fits — reject, planned change: the extension was the user's plan-gate choice. `isSingular` tests the random-effect parameters, not the residual, as the DESIGN.md lme4 row states.
- blame-history #3: the `refuse_zero_width()` comment that lme4 [1, 1] limits differ in the last digits is unverified — reject, false: measured at plan time (work log: 0.99999999999998235 against 0.99999999999999911), and confirmed by the claim audit.
- blame-history #4: the roxygen block's backtrace claim — reject, noted: the reviewer found it consistent, and it asks for nothing.
- blame-history #5: the DESIGN.md classed-deferral bullet's data-pointing message is not in a D-entry — reject, planned change: T4 called for the DESIGN.md update, and D-053 records the class and parent.
- blame-history #6: the boundary hint side effect is unrecorded — follow-up, same row (b) as diff-bug #6.
- blame-history #7: D-053 reads D-022 by its stated reason — reject, planned change: recorded at the plan gate (work log, D-053).
- prior-review #1: the message bullet ran 29 words, past the 25-word rule for condition text (M156) — fix now, fixed e14bff3 (split into two bullets).
- prior-review #2: the `refuse_zero_width()` bullet names flat data, which D-052 now refuses upstream — follow-up, row "M162 review follow-ups on the engine re-raise" (c). The line is unmodified by this diff.
- prior-review #3: the AC2 test read `conditionMessage()` without `cli::format_message()` (M93 lesson) — fix now, fixed e14bff3 (renders with `format_message()` and asserts no backslash).
- prior-review #4: NEWS names one design family as the source — reject, false: the sentence reports where the errors were observed, with "for example", and claims no condition.

Verify re-run after the fix-now commit e14bff3: `devtools::test()` FAIL 0, WARN 0, SKIP 2, PASS 10414. `pkgdown::check_pkgdown()`: no problems. `devtools::check()` Status: 1 ERROR, from `tests/spelling.R`: "Potential spelling errors: rlang", a word the e14bff3 fixes added to `?icc` and NEWS in plain prose. Fixed by setting it as code in both, not by a WORDLIST entry (LESSONS, M127). `spelling::spell_check_package()` then found no errors. Check re-run pending.
