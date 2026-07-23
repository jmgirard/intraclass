# M83: Repair rotted `skip_on_ci` brms test expectations + pin explicit `type=`/`level=`

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** m83-repair-rotted-brms-test-expectations · https://github.com/jmgirard/intraclass/pull/90

## Goal

Restore `tests/testthat/test-icc-brms.R` to green under a live-Stan run and pin its fits' `type=`/`level=` explicitly so a future default change can no longer silently rot them.

## Scope

**In:** repairing every stale assertion in `tests/testthat/test-icc-brms.R` — the `skip_on_ci` live-Stan blocks whose expectations predate two default changes: M44/ADR-054 (a no-`type` `icc()` now returns all four formulations) and M37/ADR-047 (fixed multilevel returns extra levels). Where a block's `index`/`level` assertion depends on the package default, pin the fit's `type=`/`level=` explicitly so the expectation encodes intent, not the current default.

**Out:** any change to runtime code under `R/` — this is test-only (a runtime change would make it a different milestone). Un-skipping these on CI → not attempted (CI has no Stan toolchain; the `skip_on_ci` gate stays). One-way blocks that assert `ICC(1)/ICC(k)` without `type=` → left as-is where a live run confirms them green (one-way rejects `type=`, so there is nothing to pin).

## Acceptance criteria

- [x] AC1 — A baseline live-Stan run of `test-icc-brms.R` at `NOT_CRAN=true` (unset `CI`) enumerates every failing block; that recorded failure list is now green after the fix.
- [x] AC2 — Every two-way/crossed brms `icc()` fit whose block asserts a specific `index`/`level` set passes an explicit `type=` (and `level=` where multilevel); no such assertion is left depending on the package default. Evidence: a committed audit ledger (work-log) listing each `icc(` call in the file and its `type=`/`level=` disposition.
- [x] AC3 — Full-file `test-icc-brms.R` is green under a live-Stan run (`NOT_CRAN=true`, `CI` unset); and `Rscript -e 'devtools::test()'` is clean under CI parity (`NOT_CRAN=true CI=true`, the `skip_on_ci` blocks skipped, everything else green).
- [x] AC4 — The diff is confined to `tests/testthat/test-icc-brms.R`; `git diff --stat` shows no file under `R/` changed.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T4
- AC4 → T2, T3

## Tasks

- [x] T1 — Live-Stan baseline: run `test-icc-brms.R` at `NOT_CRAN=true` (unset `CI`), capture every failing block (line + expected vs actual `index`/`level`), and record the failure list as a work-log ledger. Confirms the rot is real and bounds the fix.
- [x] T2 — Fix each failing block: add explicit `type=` (and `level=` where multilevel) to the `icc()` call to encode the block's intended formulation, and update the `index`/`level` expectation to match. Sweep both rot causes (M44 `type`-default; M37 level-expansion).
- [x] T3 — Audit ledger: enumerate every `icc(` call in the file; for each two-way/crossed fit still relying on a default `type=`/`level=` (even if currently green), pin it explicitly so no latent default-dependence remains. One-way fits (which reject `type=`) noted as exempt. Commit the ledger as work-log evidence.
- [x] T4 — Verify: full-file `test-icc-brms.R` green under live Stan (`NOT_CRAN=true`); then `devtools::test()` clean under CI parity (`NOT_CRAN=true CI=true`); confirm `git diff --stat` touches only the test file.

## Work log

- 2026-07-23: created by /milestone-plan.
- 2026-07-23: T1 live-Stan baseline (`NOT_CRAN=true`, `CI` unset) — 11 blocks failed, all A-only `index` assertions from no-`type` fits now returning all four formulations (M44/ADR-054); O-Bayes-FML-agree additionally failed on `level` (subject vs subject+cluster, M38) + cascading containment. Enumerated in scratchpad baseline log.
- 2026-07-23: T2 fix — added `type = "agreement"` to the 11 rot fits; O-Bayes-FML-agree `fa`/`fc` additionally pinned `level = "subject"` (design returns both levels since M38); 4 stale "default"/"brms subject-only" comments corrected. Diff confined to `tests/testthat/test-icc-brms.R` (21 ins / 8 del).
- 2026-07-23: T3 audit — 45 brms fits: 15 now type-pinned (2 also `level`-pinned), 2 `model="oneway"` exempt, 28 no-type all error-path/argument-validation, non-index diagnostic/replicate/prior, or nested-random/multilevel-one-way (ICC(1)/ICC(k), no A/C). No latent type-default-dependence in any index/level shape assertion.
- 2026-07-23: T4 verify (1st full run) — 3 residual failures: restricting the primary brms fits to agreement exposed whole-vector `estimate` comparisons in O-Bayes-ML-agree/FCL/NML-agree against glmmTMB/lme4/brms-random references still at all-four. Pinned those 6 reference fits to `type = "agreement"` (merDeriv present, so the lme4 legs run). Re-running full verify.
- 2026-07-23: T4 verify (2nd full run) GREEN — live Stan `test-icc-brms.R` 67 blocks, 0 failed/0 errored/0 skipped. CI-parity `devtools::test()` (`CI=true`) 478 blocks, 0 failed/0 errored, 23 skipped (the `skip_on_ci` brms blocks), 2 pre-existing glmmTMB convergence warnings. Branch diff vs `origin/main` confined to `tests/testthat/test-icc-brms.R` + this file; no `R/` change. Status → review.

## Decisions

## Review

**Consistency gate (2026-07-23).** `cairn_validate` exit 0 (all checks pass; 323 advisories, no FAIL). `devtools::document()` — no diff. No `IPn`/`GPn` change → `cairn_impact` skipped.

**AC evidence (fresh, this session, post-fix):**
- AC1 — Baseline live-Stan run (`NOT_CRAN=true`, `CI` unset) enumerated 11 failing blocks (all A-only `index` from no-`type` fits now returning all four; O-Bayes-FML additionally on `level`). Second full run after the fix: 67 blocks, 0 failed / 0 errored / 0 skipped.
- AC2 — T3 audit: 45 brms fits — 15 type-pinned (2 also `level`-pinned), 2 `model="oneway"` exempt (no A/C distinction), 28 no-type all either error-path/argument-validation, non-index diagnostic/replicate/prior, or nested-random/multilevel-one-way (ICC(1)/ICC(k)). No index/level shape assertion depends on the package default. Ledger in the work log.
- AC3 — Live-Stan `test-icc-brms.R`: 67/0/0. CI-parity `devtools::test()` (`NOT_CRAN=true CI=true`): 478 blocks, 0 failed / 0 errored, 23 skipped (the `skip_on_ci` brms blocks), 2 pre-existing glmmTMB convergence warnings.
- AC4 — `git diff --name-only origin/main...HEAD`: `tests/testthat/test-icc-brms.R` + two tracking files; 0 files under `R/`. Code diff 27 ins / 8 del, test file only.

**Three-lens review + scorer (2026-07-23).** Diff-bug [O], blame-history [S], prior-review [S]; scorer [S]. Two findings, both scored ≥80, both fixed on-branch (comment-only, no test behavior change):
- F1 (diff-bug, scored 90) — a fifth stale "agreement by default" comment (`:2048`, O-Bayes-INML-clusters-agree) missed by the T2 sweep; its fit is now explicitly `type="agreement"`, so the comment could mislead a maintainer into deleting the pin and reintroducing the rot. Fixed → "agreement via explicit `type`".
- F2 (blame-history, scored 85) — the O-Bayes-FML containment comment (`:3110`) cited "(M37/M38, ADR-047)"; ADR-047 is the frequentist glmmTMB change (M37), the brms both-levels behavior is M38/ADR-048 (confirmed `legacy/DECISIONS.md:4049`, `ORACLES.md:1696`). Fixed → "glmmTMB M37 ADR-047 / brms M38 ADR-048".
- Prior-review lens: no prior-review evidence on the touched file (GitHub comment surface empty; no archived `## Review` pinned these assertions); the diff fulfills the M82 rot-discovery lesson rather than regressing it. No finding.
