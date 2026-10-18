<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M164: The near-1 interval warning reads each row against 1e-12 divided by the ratings it averages, and names its rows

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — `icc()` changes which results carry a warning that users see and catch by class   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m164-near-one-bound-per-row   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

On glmmTMB and lme4 Monte-Carlo and bootstrap intervals, the near-1 warning reads a row that averages d ratings against the bound 1e-12/d.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** `warn_unresolved_interval()` in `R/ci-montecarlo.R` takes the estimands from its two callers, `mc_ci()` and `bootstrap_ci()`. For each interval it reads d, the largest error divisor of that estimand. That is 1 for a single rating and the number of raters averaged for an average-rater row. Where the row also averages occasions, d includes the occasion count. The helper compares the lower limit with 1 − 1e-12/d. Its message names each row that fired it by coefficient label. The name adds the level for a multilevel row and the occasion count for a replicate row. Records: D-056, the existing development NEWS entry on this warning, and the `ci_method` entry of `?icc`. Also the code comments that state the bound, the DESIGN.md Monte-Carlo and Bootstrap rows, and the `data-raw/mpl-doc-claims.tsv` row for each changed `?icc` sentence.

**Out:**
- The 1e-12 bound for single-rating rows. It stays as D-054 set it, with D-054's own conditions to reopen it.
- `d_study()` projection bands. They stay in item (c) of "M163 review follow-ups on the near-1 warning" and item (d) of "M158 review follow-ups on the glmmTMB boundary path".
- SEARLE and Burch intervals of exactly [1, 1]. They stay in the row "Classical intervals exactly [1, 1] on near-flat data".
- The lavaan and brms engines. They stay in the row "two-way data with zero residual".

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: On a glmmTMB or lme4 fit, `mc_ci()` and `bootstrap_ci()` read each interval they return against 1 − 1e-12/d. Here d is the largest error divisor of that interval's estimand. If at least one finite lower limit is greater than its 1 − 1e-12/d, the function signals exactly one warning of class `intraclass_unresolved_interval`. That warning also carries `intraclass_warning`. If every lower limit is at most its 1 − 1e-12/d, the function signals no warning of that class. On a lavaan fit it signals none. The return value is `identical()` to the value returned with `warn_unresolved_interval()` replaced by a function that returns its intervals unchanged. If one interval has exactly equal limits, the call aborts with `intraclass_zero_width_interval` and signals no warning of that class. Each of these holds on both engines under both functions in the following cases. With d = 1, a lower limit on each side of 1 − 1e-12. With d = 3, a lower limit between 1 − 1e-12 and 1 − 1e-12/3 gives no warning, and one above 1 − 1e-12/3 gives the warning. With error divisors 3, 3 and 6, a lower limit between 1 − 1e-12/3 and 1 − 1e-12/6 gives no warning, and one above 1 − 1e-12/6 gives the warning. Two firing intervals give one warning. A lavaan fit, and an equal-limits interval beside a firing one, are the other two cases. The divisors of the d = 3 case and the (3, 3, 6) case come from `icc_estimand()`.
- [ ] AC2: A grid of `icc()` calls runs on the glmmTMB and lme4 engines under `ci_method = "montecarlo"` and `"bootstrap"`, with `mc_samples = 500`, `boot_samples = 30` and `seed = 1`. It runs five frames. Three are M163's: the near-flat frame with `model = "oneway"`, the exactly additive frame with `model = "twoway"`, and the frame of 20 subjects and 3 raters with rater noise SD 1e-7. The fourth is that 20-by-3 frame with rater noise SD 1e-6, built under `with_rng_seed(1, ...)`. The fifth has 20 subjects, 3 raters and 2 occasions per cell with noise SD 1e-6 on every score. It is called with `occasions = c("single", "average")`. Each call either aborts with `intraclass_singular_fit` or returns an `intraclass_icc` result. If one of its `tidy()` rows has a lower limit greater than 1 − 1e-12/d, a returned result signals exactly one `intraclass_unresolved_interval` warning. Otherwise it signals none. Here d is the frame's rater count for an average-rater row and 1 for a single-rater row. It is multiplied by the row's `occasions` value where that value is not `NA`. At least one call on M163's three frames returns a result with the warning. At least one call on the fourth or fifth frame returns a result with no warning and a row whose lower limit lies between 1 − 1e-12 and 1 − 1e-12/d. The 20-subject frame with rater noise SD 1e-5 still gives no warning of the class.
- [ ] AC3: The warning's message, rendered with `cli::format_message()`, gives the right count of intervals for a count of 1 and for a count of 2. It names each row that fired the warning by its coefficient label. The name adds the level for a multilevel row and the occasion count for a replicate row. Two cases show this, each with a firing row and a non-firing row that share a label. In one they differ only by level, and in the other only by occasion count. In each case the full name of the firing row appears and the full name of the non-firing row does not. The message says that for a row that averages ratings, the bound 1e-12 is divided by the number of ratings, or effective ratings, it averages. It still says that data with almost no residual variation can give such an interval. It still names the class `intraclass_unresolved_interval` as the way to silence the warning.
- [ ] AC4: The development entry of `NEWS.md` on the `intraclass_unresolved_interval` warning says three things. The bound is 1e-12 for a single-rating row. It is 1e-12 divided by the number of ratings averaged for a row that averages ratings. The warning names its rows. The `ci_method` entry of `?icc` says the same. Neither still says that average-rater rows get the warning at larger noise.
- [ ] AC5: `devtools::document()` leaves no diff, and `devtools::test()` passes with WARN 0. The raw Status line of `devtools::check()` shows no ERROR, WARNING or NOTE. `lintr::lint_package()` reports nothing, and `air format --check .` passes. Every `python3 data-raw/` step of `.github/workflows/lint.yaml` passes.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T1, T2
- AC4 → T4
- AC5 → T4, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Extend `tests/testthat/test-unresolved-interval.R`. Give the stub estimands a `label`, and where a case needs them, `level` and `occasions`. Build the divisors of the d = 3 and (3, 3, 6) stubs from `icc_estimand()` calls: one-way average with `k_eff = 3`, and two-way replicates with `occasions = "average"` and `n_o = 2`. Place each stub's lower limit at least 1e-15 inside its band, and assert that it sits there (audit probe: rounding near 3e-13 is about 5e-17). Add the AC3 message tests, with the two shared-label pairs built from `icc_estimand()` (subject and cluster level; occasions 1 and 2). Render with `cli::format_message()` (LESSONS, M93). Update the mocked `warn_unresolved_interval()` signature in the first test. Run the tests on the unchanged code and record which ones fail.
- [ ] T2: Change `warn_unresolved_interval()` (`R/ci-montecarlo.R:229`) to take the estimands. It reads d as `max(unlist(est$error_divisors))`. Pass the estimands from `mc_ci()` (`R/ci-montecarlo.R:286`) and `bootstrap_ci()` (`R/ci-bootstrap.R:98`). Build the row names from each estimand's `label`, `level` and `occasions`. Rewrite the helper's header comment to state the scaled bound and cite D-056 (GP7). Do the same for the comments at `R/ci-montecarlo.R:176` and `R/ci-bootstrap.R:95`.
- [ ] T3: Update the `icc()` grid test of `test-unresolved-interval.R` to the AC2 rule, with d from each row's `term` suffix, the frame's rater count and the row's `occasions`. Add the fourth and fifth frames. Before writing their checks, print each row's lower limit with `sprintf("%.17g", x)` at the test's settings (LESSONS, M162), and record the gaps in a work-log line. Keep `skip_on_cran()`. Assert the rule on each call and keep the floors over the grid, not a result per call (GP9).
- [ ] T4: Edit the existing development NEWS entry and the `?icc` `ci_method` text, then run `devtools::document()`. Update the DESIGN.md Monte-Carlo and Bootstrap rows to state the scaled bound and cite D-056. Update the `data-raw/mpl-doc-claims.tsv` row for each changed `?icc` sentence, or add one, and count its fields with `awk -F'\t'` (LESSONS, M153). Run the `data-raw/` checkers with and without `--self-test`, as CI's lint job does (LESSONS, M130).
- [ ] T5: Run `devtools::test()` and read WARN 0 (LESSONS, M150). Run `devtools::check()` and read the raw Status line (LESSONS, M127). Run `lintr::lint_package()`, `air format --check .`, and the `python3 data-raw/` steps of `.github/workflows/lint.yaml`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: what to work on — the average-rater false warning (item (a) of "M163 review follow-ups on the near-1 warning"), chosen ahead of its promotion condition (a user report) at the user's choice. Row names in the message — yes (item (b) of the same row).
- 2026-10-18: plan probe (scratch script, 20 subjects, 3 raters, rater noise SD 1e-6, seed 1, mc_samples 2000, boot_samples 50): all four engine-by-method calls warn today. 1 − lower is 5.4e-13 to 6.5e-13 on ICC(C,k) and 1.6e-12 to 2.0e-12 on ICC(C,1); the inverse Spearman-Brown of each average row's lower limit equals its single row's gap.
- 2026-10-18: plan chose d = the largest error divisor over the rater divisor alone, because pure error in an occasion-averaged row is also divided by the occasion count, so the rater divisor leaves that row's false warning in place; falsified by degenerate replicate data whose occasion-averaged row lies further than 1e-12/d from 1 while its single row lies within 1e-12.
- 2026-10-18: plan chose dividing the bound over recomputing each row's single-rating coefficient from the draws, because the recompute warns on a coefficient the call may not report and needs the draws passed to the helper; falsified by a row whose scaled gap and single-rating gap disagree across the bound on real data.
- 2026-10-18: plan chose scaling every row over reading only single-rating rows, because `unit = "average"` alone reports no single row; falsified by none found.
- 2026-10-18: collisions: D-054 (rule) and D-055 ("Rejected for M163: scaling the bound by each row's averaging divisor … It is a candidate row") quoted and superseded in part by D-056 in this commit, since D-004 requires an entry for a Boundary-fit policy change. M163 (done) is the work this extends. Candidate row "M163 review follow-ups on the near-1 warning" absorbed in part (items (a) and (b)); item (c) stays. GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-18: criteria audit (full mode, fresh Opus reader, probes in scratch) returned 13 findings. Fixed: (2) fourth frame pinned to `with_rng_seed(1, ...)`, 500/30, seed 1; (3) fourth frame asserted as rule plus floor, not four results; (4) AC2 wording; (5) replicate frame added to AC2, d times `occasions`; (6) stub divisors from `icc_estimand()`, 1e-15 band margin in T1; (7) identity compared with a no-op helper, not a muffled warning; (8) AC1 names its cases; (9) AC3 shared-label pairs for level and occasions; (10) "or effective ratings"; (12) AC5 names the lint, air and lint.yaml checker steps. Answered: (1) D-056 lands in this plan commit, a record and not a deliverable, so no criterion binds it; (11) DESIGN.md rows are a tracking record, kept in T4, and the ledger row is covered by AC5's checker steps. (13) no IP conflict. Audit probe at the test's settings: fourth frame single-row gaps 1.64e-12 to 2.07e-12 and average-row gaps 5.48e-13 to 6.91e-13; replicate frame glmmTMB bootstrap separates the old and new rule.
- 2026-10-18: lessons surfaced: M163 (probe every `tidy()` row before setting a bound near 1), M162 (`sprintf("%.17g")`), M130 and M163 (`?icc` sentence changes need `mpl-doc-claims.tsv` rows; run the lint.yaml checkers), M153 (TSV field counts), M93, M150, M127, M141. No dependency change and no outward action beyond the merge-gate PR.
- 2026-10-18: implement started on branch m164-near-one-bound-per-row, cut from main at 3e3383d.
- 2026-10-18: T1: on the unchanged code the two no-warning band tests fail 4 checks each (the old rule warns) and the message tests fail 20 checks; the two warning-band tests pass, as they must under the old rule too.
- 2026-10-18: T2 choice: a row name is the label plus " at the <level> level" and " over <n> occasion(s)"; the message reads "<n> intervals have a lower limit near 1: <rows>." with a bullet stating the bound, the rows joined by cli's vector collapse.
- 2026-10-18: T3 probe at the test's settings (500/30, seed 1): noise-1e-6 frame single-row gaps 1.64e-12 (glmmTMB bootstrap) to 2.07e-12 (lme4 Monte-Carlo), average-row gaps 5.48e-13 to 6.91e-13, no call warns; replicate frame Monte-Carlo lower limits 0 on both engines, glmmTMB bootstrap ICC(A,1) over 2 occasions 9.67e-13 from 1 (d = 2, 1.93 times its bound, no warning), lme4 bootstrap gaps 5.4e-12 to 3.2e-11.
- 2026-10-18: T3 discrimination: a planted d = 1 rule reds 3 tests (14 checks), a planted rater-divisor rule reds 2 tests (5 checks), the replicate frame among them.
- 2026-10-18: T4: the new `?icc` sentences need no `mpl-doc-claims.tsv` row (checker 0 failures). Found main's lint job red since 9162da9: `data-raw/record-claims.tsv` row roadmap-terminal-rows still expected M162, M161, M160 after the M163 done pass; rotated to M163, M162, M161 here, since AC5 needs every lint step. M164's done pass must rotate it again. The Edit tool dropped a tab on that row (10 fields); fixed to 11 (LESSONS, M153).
- 2026-10-18: checkpoint: T1–T4 written, `test-unresolved-interval.R` 15 of 15 green, lintr 0, air clean, lint.yaml checkers green; tasks stay unchecked until the full `devtools::test()` and `devtools::check()` run (T5) is green.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
