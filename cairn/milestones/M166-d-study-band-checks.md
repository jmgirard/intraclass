<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M166: d_study() bands from glmmTMB and lme4 fits are refused or warned on by each curve's single-rating coefficient

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP7, GP9   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — `d_study()` gains an abort and a warning that users see and catch by class   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

On a glmmTMB or lme4 fit, `d_study()` reads each projected curve's single-rating coefficient from the band's own draws, refuses the band when that coefficient's limits are exactly equal, and warns when its lower limit lies within 1e-12 of 1.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** Item (d) of "M158 review follow-ups on the glmmTMB boundary path" and item (c) of "M163 review follow-ups on the near-1 warning".
- In `d_study()` (`R/d-study.R:533-549`), after the band intervals are built, gated to fits whose `engine` is glmmTMB or lme4, whatever the fit's `ci_method`. For each distinct type and level among the band's rows, the single-rating coefficient is the estimand at one rater, and at one occasion where the fit has replicates. Its interval is computed from the same draws as the band: the Monte-Carlo components or the stored bootstrap components.
- If any such interval has two finite and exactly equal limits, `d_study()` aborts with `intraclass_zero_width_interval`, which also carries `intraclass_singular_fit`, as `icc()` does (D-049, D-053).
- Otherwise, if any such interval has a finite lower limit greater than 1 − 1e-12, `d_study()` returns its result and signals one `intraclass_unresolved_interval` warning, which also carries `intraclass_warning`. Its message names each single-rating coefficient that fired it, with the level and occasion count as `unresolved_row_name()` gives them.
- A projected row whose own limits are equal only through rounding near 1, at a very large `m`, is reported with no abort and no warning when its curve's single-rating limits differ.
- Records: D-058 (this plan commit), the DESIGN.md Monte-Carlo and Bootstrap rows of the Boundary-fit policy, `?d_study`, a development NEWS entry, and the code comments at the band.

**Out:**
- Items (a), (e) and (f) of the M158 row → M165; items (b) and (c) → M167.
- Per-row checks on the projected rows themselves, which would refuse rounded [1, 1] rows of ordinary data at very large `m` (plan probe).
- The lavaan and brms engines, which `icc()`'s checks also leave out (D-053, D-054).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: When every band draw is replaced by one fitted draw's components, with nonzero total variance, `d_study()` aborts with `intraclass_zero_width_interval`, also `intraclass_singular_fit`, on each of these fits, all with `seed = 1`: glmmTMB and lme4 fits of `scale_two_way(11)` under `ci_method = "montecarlo"`, and under `"bootstrap"` with `boot_samples = 30`, called with `m = c(1, 2)`; a multilevel glmmTMB Monte-Carlo fit of `school`, called with `m = c(1, 2)`; and an lme4 Monte-Carlo replicate fit of `ratings_replicates`, called with `n_o = 1:3`. Each of these calls with the draws left as fitted returns an `intraclass_dstudy` result. A lavaan fit under `ci_method = "montecarlo"` whose band draws are made constant in the same way returns a result.
- [ ] AC2: On glmmTMB and lme4 fits of `scale_two_way(11)` under `ci_method = "montecarlo"` with `seed = 1` and `mc_samples = 500`, `d_study(fit, m = c(1, 1e20), seed = 1, mc_samples = 500)` returns a result with at least one row at `m = 1e20` whose `conf.low` and `conf.high` both equal 1 exactly, and it signals no `intraclass_unresolved_interval` warning.
- [ ] AC3: `d_study(fit, m = c(1, 2), seed = 1, mc_samples = 500)` signals exactly one `intraclass_unresolved_interval` warning on each fit of a named set on which `icc()` with the same `seed`, `mc_samples = 500` and `boot_samples = 30` signals that warning: the lme4 Monte-Carlo fits of M163's near-flat one-way frame, exactly additive frame, and 20-subject, 3-rater frame with rater noise SD 1e-7; the glmmTMB Monte-Carlo fit of that 20-by-3 frame; and the lme4 bootstrap fit of the exactly additive frame. Its message, rendered with `cli::format_message()`, names each single-rating coefficient whose lower limit exceeds 1 − 1e-12 and says it is the single-rating coefficient behind the projected curves. On the noisy lme4 Monte-Carlo fit, `d_study(fit, m = c(2, 3), seed = 1, mc_samples = 500)` also signals one such warning, naming ICC(C,1). `d_study(fit, m = c(1, 2), seed = 1, mc_samples = 500)` returns with no such warning on the AC2 fits, and on M164's frames with noise SD 1e-6 (the 20-by-3 frame and the replicate frame) on both engines under both methods with `mc_samples = 500` and `boot_samples = 30`.
- [ ] AC4: For each call of AC2 and AC3 that returns, the `estimate`, `std.error`, `conf.low` and `conf.high` columns equal, printed with `sprintf("%.17g", x)`, the values the same call returns on the code of the plan commit, recorded in T1.
- [ ] AC5: `?d_study` and a development entry of `NEWS.md` say that on glmmTMB and lme4 fits, `d_study()` reads each curve's single-rating coefficient from the band's draws, refuses the band when that coefficient's limits are exactly equal, and warns when its lower limit lies within 1e-12 of 1.
- [ ] AC6: `devtools::document()` leaves no diff, and `devtools::test()` passes with WARN 0. The raw Status line of `devtools::check()` shows no ERROR, WARNING or NOTE. `lintr::lint_package()` reports nothing, and `air format --check .` passes. Every `python3 data-raw/` step of `.github/workflows/lint.yaml` passes.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T1, T2, T3
- AC5 → T4
- AC6 → T4, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Add `tests/testthat/test-dstudy-band-checks.R` with the AC1 to AC4 tests. Make band draws constant with `fit$mc$vcov <- 0 * fit$mc$vcov` for a Monte-Carlo band, or by setting each `boot$components` vector to one draw whose total variance is nonzero (audit probe: lme4's first resample gave [0, 0]); confirm by the abort's class that the refusal, and not another guard, fired (failure-identity rule). Before the change, run every AC2 and AC3 call on main and record its four columns at `%.17g` in the test file (LESSONS, M162). Run the tests on the unchanged code and record which fail. Also run one glmmTMB `ci_method = "mpl"` fit with constant draws, since the gate reads the engine and not the `ci_method`. Keep `skip_on_cran()` on the fitting tests.
- [ ] T2: In `d_study()`, build the single-rating estimand per distinct type and level, compute its interval from the band's components, and call `refuse_zero_width()` on those intervals with the fit's engine. Write the header comment at the band to state the rule and cite D-058 (GP7).
- [ ] T3: Add the warning. Reuse `warn_unresolved_interval()` if its message can name the single-rating coefficients as such, or add a sibling helper with its own message. The message says the coefficient is the single-rating coefficient behind the projected curves and keeps the `intraclass_unresolved_interval` silencing line.
- [ ] T4: Write the `?d_study` text and the NEWS entry, then run `devtools::document()`. Update the DESIGN.md Monte-Carlo and Bootstrap rows to state the `d_study()` rule and cite D-058, without saying that the `d_study()` warning names its rows. If a changed roxygen sentence has a `data-raw/mpl-doc-claims.tsv` trigger word, add or update its row and count fields with `awk -F'\t'` (LESSONS, M153, M130). Run the `data-raw/` checkers with and without `--self-test`.
- [ ] T5: Run `devtools::test()` and read WARN 0 (LESSONS, M150). Run `devtools::check()` and read the raw Status line (LESSONS, M127). Run `lintr::lint_package()`, `air format --check .`, and the `python3 data-raw/` steps of `.github/workflows/lint.yaml`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — a behavior change to running code with a design decision, from the [high] candidate row "M158 review follow-ups on the glmmTMB boundary path".
- 2026-10-18: question set: how `d_study()` checks its bands — read each curve's single-rating coefficient from the band's draws, ahead of the row's promotion condition, at the user's choice.
- 2026-10-18: plan probe (scratch, `scale_two_way(11)`, seed 1, mc_samples 500): on glmmTMB and lme4 Monte-Carlo fits, rows at m = 1e18 and 1e20 have both limits exactly 1 while the single-rating lower limits are 0.0067 to 0.0191; `d_study(m = c(1, 2))` reproduces `icc()`'s intervals at the same seed.
- 2026-10-18: plan chose reading the single-rating coefficient over icc()'s per-row rules, because per-row rules refuse the rounded [1, 1] rows of ordinary data at very large m; falsified by degenerate data whose projected rows have equal limits while the single-rating limits differ.
- 2026-10-18: plan chose gating on the engine over gating on the fit's `ci_method`, because a fit of any `ci_method` on glmmTMB or lme4 gets a Monte-Carlo band from the same draws; falsified by none found.
- 2026-10-18: criteria audit (full mode, fresh Opus reader, probes in scratch) returned 10 findings. Fixed: (1) constant draws with nonzero total variance, lavaan under montecarlo; (2) multilevel and occasion-axis replicate fits added to AC1; (4) near-flat one-way lme4 fit added to AC3; (5) lme4 bootstrap positive and M164's 1e-6 frames as near-bound negatives added to AC3; (6) AC3 pins a call with no m = 1 row and the message's single-rating wording, and D-058 answers D-056's reason; (7) AC4 compares with recorded values of the plan-commit code, not a mocked run; (8) one mpl fit added to T1 as a test, not a criterion. No finding on AC2, AC5 or AC6. D-056's rejection is scoped to `icc()`; no standing decision forbids the rule.
- 2026-10-18: lessons surfaced: M162 (`%.17g`), M163 (probe every row before a bound near 1), M164 (namespace replacement), M130 and M163 (lint.yaml checkers), M153, M150, M127. No dependency change and no outward action beyond the merge-gate PR.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
