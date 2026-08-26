# M140: Release-remainder documentation corrections, and the recorded pre-submission check

- **Status:** planned
- **Priority:** high
- **Depends on:** M138, M139
- **Driving RR:** —
- **Principles touched:** —

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

- [ ] T1. Run the AC2 grep; rewrite each matched claim to the `replicates_uniform` rule, which is computed on two paths: the flat crossed one at `R/design.R:48-51` and the design-aware multilevel one at `R/design.R:214-226`. Known sites: `R/icc.R:681` / `man/icc.Rd:484-486`, `NEWS.md:356-358`.
- [ ] T2. Rewrite `NEWS.md:370-372` so the "unaffected" sentence is scoped per function, `d_study()`'s vector-valued arguments being the mutually exclusive projection axes `m` and `n_o` (`R/d-study.R:205-218`).
- [ ] T3. Append the D-entry superseding D-037's `d_study()` clause (`cairn/DECISIONS.md:1592-1594`), keeping D-036's routed-through-`validate_choice()` discriminator unchanged.
- [ ] T4. Fix the "fills" sentence at `R/d-study.R:125-126`; re-roxygenize so `man/d_study.Rd:65-66` follows.
- [ ] T5. `air format .`, the four `data-raw/` checkers with `--self-test`, then `R CMD check --as-cran` with `NOT_CRAN=false`; copy the platform, R version and date from that run's own output into `cran-comments.md:5-20`.
- [ ] T6. Measure spelling against a detached worktree at the default branch, per the M128 lesson, rather than padding `inst/WORDLIST`.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on 3 of 4 drafted criteria. Fixed at the gate: AC1 rewritten to bind a check run this milestone makes, the drafted form having pinned an unobservable historical fact about the 2026-08-25 session; AC2's search roots widened and its promise narrowed to what the stated grep sweeps (bounded-promise, proxy domain). One finding rejected after checking the repo — the audit called AC4 vacuous, citing `R/d-study.R:54-55` and `:75-78`, but the false "fills" sentence is a different paragraph on the same page and is live at `R/d-study.R:125-126` and `man/d_study.Rd:65-66`; the page contradicts itself, so AC4 stands with the site named. One finding posed at the question gate (how to make the `cran-comments.md` criterion satisfiable).
- 2026-08-26: plan gate chose re-running `--as-cran` and recording that run's own platform over editing the version string in place, because nothing otherwise ties the recorded platform to the recorded 0/0/0 result and the `darwin23` token in the check header would stay inconsistent with it; falsified by the re-run reporting a different result than the recorded one, which would make the edit a separate question from the record.
- 2026-08-26: plan gate weighed no alternative on the three shipped-documentation corrections, each having one true statement to make.
