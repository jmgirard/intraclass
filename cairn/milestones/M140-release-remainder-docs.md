# M140: Release-remainder documentation corrections, and the recorded pre-submission check

- **Status:** review
- **Priority:** high
- **Depends on:** M138, M139
- **Driving RR:** —
- **Principles touched:** —
- **Branch:** `m140-release-remainder-docs`

## Goal

Correct the four false documentation claims descoped from M48 and re-run `R CMD check --as-cran`, recording that run's own platform in `cran-comments.md` so the submission record and the check that backs it name the same machine.

## Scope

**Surface tier: user-facing** — three of the four corrections are shipped documentation users read; `cran-comments.md` is a submission record, corrected here in the milestone that finds it (D-021) rather than promoted to one of its own.

**In:** (a) `cran-comments.md`'s local environment line, which names macOS 15 where this machine reports macOS 26.6.2 and the check header says `aarch64-apple-darwin23`; (b) the `n_o` NA condition in `man/icc.Rd` and `NEWS.md`, which names ragged replicates alone where the shipped rule also requires completeness in the design's own sense (`R/design.R:48-51`, `R/design.R:214-226`); (c) `NEWS.md:370-372` and D-037's enumeration, both of which give `d_study()` four report-all arguments its signature `(x, m, n_o, conf_level, mc_samples, seed)` does not have; (d) `R/d-study.R:125-126` and `man/d_study.Rd:65-66`, which say a projection *fills* `level`/`occasions` where the same page's own sections at `R/d-study.R:54-55` and `:75-78` correctly say the object *gains* them.

**Out:** the actual CRAN upload and the win-builder / R-hub runs — the maintainer's out-of-band acts (ADR-022); this milestone records their results in `cran-comments.md` if they are run before it closes, and leaves the scheduled-not-yet-run wording honest if they are not. Any change to what the package computes → its own milestone.

## Acceptance criteria

- [ ] AC1. `cran-comments.md` reports an `R CMD check --as-cran` run made during this milestone, and its stated platform, R version and date are read from that run's own session output rather than from any earlier record.
- [ ] AC2. Every line matched by `grep -rn "n_o\|occasion count" man/ NEWS.md R/ README.md vignettes/` that states when the occasion count is `NA` states the shipped rule — within-cell replicates present, equal per-cell counts, and completeness in the design's own sense (full subject-by-rater grid when crossed, block-complete when nested) — rather than naming ragged replicates alone.
- [ ] AC3. `NEWS.md`'s report-all sentence names, per function, arguments that function's own signature has; a `cairn/DECISIONS.md` entry supersedes D-037's `d_study()` enumeration and states what `d_study()`'s vector-valued arguments actually are.
- [ ] AC4. `R/d-study.R:125-126` and `man/d_study.Rd:65-66` say the projection object *gains* `level` and `occasions` where they apply and that `tidy()` carries them on every projection, agreeing with `R/d-study.R:54-55` and `:75-78`.
- [ ] AC5. `devtools::check()`'s raw `Status:` line reports 0 errors, 0 warnings, 0 notes; `devtools::test()` at `NOT_CRAN=true CI=true` reports FAIL 0; `spelling::spell_check_package()` against a detached worktree at the default branch flags no word this milestone introduced.

## Coverage

- AC1 → T5
- AC2 → T1
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5, T6

## Tasks

- [x] T1. Run the AC2 grep; rewrite each matched claim to the `replicates_uniform` rule, which is computed on two paths: the flat crossed one at `R/design.R:48-51` and the design-aware multilevel one at `R/design.R:214-226`. Known sites: `R/icc.R:681` / `man/icc.Rd:484-486`, `NEWS.md:356-358`.
- [x] T2. Rewrite `NEWS.md:370-372` so the "unaffected" sentence is scoped per function, `d_study()`'s vector-valued arguments being the mutually exclusive projection axes `m` and `n_o` (`R/d-study.R:205-218`).
- [x] T3. Append the D-entry superseding D-037's `d_study()` clause (`cairn/DECISIONS.md:1592-1594`), keeping D-036's routed-through-`validate_choice()` discriminator unchanged.
- [x] T4. Fix the "fills" sentence at `R/d-study.R:125-126`; re-roxygenize so `man/d_study.Rd:65-66` follows.
- [x] T5. `air format .`, the four `data-raw/` checkers with `--self-test`, then `R CMD check --as-cran` with `NOT_CRAN=false`; copy the platform, R version and date from that run's own output into `cran-comments.md:5-20`.
- [x] T6. Measure spelling against a detached worktree at the default branch, per the M128 lesson, rather than padding `inst/WORDLIST`.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on 3 of 4 drafted criteria. Fixed at the gate: AC1 rewritten to bind a check run this milestone makes, the drafted form having pinned an unobservable historical fact about the 2026-08-25 session; AC2's search roots widened and its promise narrowed to what the stated grep sweeps (bounded-promise, proxy domain). One finding rejected after checking the repo — the audit called AC4 vacuous, citing `R/d-study.R:54-55` and `:75-78`, but the false "fills" sentence is a different paragraph on the same page and is live at `R/d-study.R:125-126` and `man/d_study.Rd:65-66`; the page contradicts itself, so AC4 stands with the site named. One finding posed at the question gate (how to make the `cran-comments.md` criterion satisfiable).
- 2026-08-26: plan gate chose re-running `--as-cran` and recording that run's own platform over editing the version string in place, because nothing otherwise ties the recorded platform to the recorded 0/0/0 result and the `darwin23` token in the check header would stay inconsistent with it; falsified by the re-run reporting a different result than the recorded one, which would make the edit a separate question from the record.
- 2026-08-26: plan gate weighed no alternative on the three shipped-documentation corrections, each having one true statement to make.
- 2026-08-26: implement question gate — the submission record names both the platform string the check prints and the macOS release R reports; the DECISIONS correction is scoped to `d_study()` alone.
- 2026-08-26: T1. The AC2 grep matches 135 lines; the four stating an NA condition for the occasion count were rewritten to the shipped rule (`R/icc.R:687-691` and its `man/icc.Rd`, `NEWS.md:366-369`, `NEWS.md:374-376`, `R/icc-methods.R:391-393`), plus the same false claim in the `R/icc.R:2508` comment. The rule was measured, not recalled: on an 8x3 replicated design with one cell dropped and 2 ratings in every remaining cell, `glance()$n_o` is `NA` with `replicates` `TRUE`; the complete sibling reports 2. `devtools::test()` FAIL 0.
- 2026-08-26: T2, T3. `NEWS.md`'s "unaffected" sentence is now scoped per function — `icc()` keeps `type`/`unit`/`level`/`occasions`, `d_study()` names its two projection axes `m` and `n_o`, supplied one per call. D-040 supersedes D-037's `d_study()` enumeration only, leaving D-036's `validate_choice()` discriminator and D-037's `icc()`/`choose_icc()` clauses standing. The both-axes abort the NEWS sentence now asserts is pinned at `tests/testthat/test-d-study.R:1126-1129`; the axis behaviour was run, not recalled (`m = 1:4` sweeps m, `n_o = 1:3` sweeps occasions, both together abort `intraclass_unsupported`). `devtools::test()` FAIL 0.
- 2026-08-26: T4. `R/d-study.R:124-128` and its `man/d_study.Rd` now say a multilevel projection *gains* a `level` column and a replicate projection an `occasions` column, each where it applies, with `tidy()` carrying both on every projection — the same page's `:54-56` and `:75-79` wording. Derived by running both projections: a replicate projection's object carries `occasions` and a plain one does not, and `tidy()` returns `m, occasions, level, ...` on both, `NA` where undefined. The code landed in the previous commit (`git add -A` swept it in ahead of this line); nothing else changed for it here. `devtools::test()` FAIL 0.
- 2026-08-26: T6. `spelling::spell_check_package()` run twice — against a detached worktree at `origin/main` (42da692) and against this branch's tree. Both flag zero words, so this milestone introduces none; `inst/WORDLIST` was not touched. The check was shown able to fail: a planted misspelling in `NEWS.md` was flagged by name, then reverted.
- 2026-08-26: T5 minor amendment — the task said "the four `data-raw/` checkers with `--self-test`"; the repo has six checkers, five of which take `--self-test` (`data-raw/README.md`). Ran all six plus all five self-tests, a superset of what the task asked; all pass.
- 2026-08-26: T5. `R CMD check --as-cran` re-run on this branch with `NOT_CRAN=false`, `manual = TRUE`; raw `Status: OK` at `check.log:104`, and the printed summary agrees at 0 errors / 0 warnings / 0 notes (51m 8.7s). `cran-comments.md:7-9` and `:21-22` now carry that run's own header lines — R 4.6.1 (2026-06-24), platform `aarch64-apple-darwin23`, running under macOS Tahoe 26.6.2, current time 2026-08-27 01:15:09 UTC — replacing the 2026-08-25 date and the `macOS 15` line, which named a release this machine does not run. `air format .` clean; `devtools::test()` at `NOT_CRAN=true CI=true` FAIL 0 / PASS 8630 on the final tree.
