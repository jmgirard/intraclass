# M83: Repair rotted `skip_on_ci` brms test expectations + pin explicit `type=`/`level=`

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Restore `tests/testthat/test-icc-brms.R` to green under a live-Stan run and pin its fits' `type=`/`level=` explicitly so a future default change can no longer silently rot them.

## Scope

**In:** repairing every stale assertion in `tests/testthat/test-icc-brms.R` — the `skip_on_ci` live-Stan blocks whose expectations predate two default changes: M44/ADR-054 (a no-`type` `icc()` now returns all four formulations) and M37/ADR-047 (fixed multilevel returns extra levels). Where a block's `index`/`level` assertion depends on the package default, pin the fit's `type=`/`level=` explicitly so the expectation encodes intent, not the current default.

**Out:** any change to runtime code under `R/` — this is test-only (a runtime change would make it a different milestone). Un-skipping these on CI → not attempted (CI has no Stan toolchain; the `skip_on_ci` gate stays). One-way blocks that assert `ICC(1)/ICC(k)` without `type=` → left as-is where a live run confirms them green (one-way rejects `type=`, so there is nothing to pin).

## Acceptance criteria

- [ ] AC1 — A baseline live-Stan run of `test-icc-brms.R` at `NOT_CRAN=true` (unset `CI`) enumerates every failing block; that recorded failure list is now green after the fix.
- [ ] AC2 — Every two-way/crossed brms `icc()` fit whose block asserts a specific `index`/`level` set passes an explicit `type=` (and `level=` where multilevel); no such assertion is left depending on the package default. Evidence: a committed audit ledger (work-log) listing each `icc(` call in the file and its `type=`/`level=` disposition.
- [ ] AC3 — Full-file `test-icc-brms.R` is green under a live-Stan run (`NOT_CRAN=true`, `CI` unset); and `Rscript -e 'devtools::test()'` is clean under CI parity (`NOT_CRAN=true CI=true`, the `skip_on_ci` blocks skipped, everything else green).
- [ ] AC4 — The diff is confined to `tests/testthat/test-icc-brms.R`; `git diff --stat` shows no file under `R/` changed.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T4
- AC4 → T2, T3

## Tasks

- [ ] T1 — Live-Stan baseline: run `test-icc-brms.R` at `NOT_CRAN=true` (unset `CI`), capture every failing block (line + expected vs actual `index`/`level`), and record the failure list as a work-log ledger. Confirms the rot is real and bounds the fix.
- [ ] T2 — Fix each failing block: add explicit `type=` (and `level=` where multilevel) to the `icc()` call to encode the block's intended formulation, and update the `index`/`level` expectation to match. Sweep both rot causes (M44 `type`-default; M37 level-expansion).
- [ ] T3 — Audit ledger: enumerate every `icc(` call in the file; for each two-way/crossed fit still relying on a default `type=`/`level=` (even if currently green), pin it explicitly so no latent default-dependence remains. One-way fits (which reject `type=`) noted as exempt. Commit the ledger as work-log evidence.
- [ ] T4 — Verify: full-file `test-icc-brms.R` green under live Stan (`NOT_CRAN=true`); then `devtools::test()` clean under CI parity (`NOT_CRAN=true CI=true`); confirm `git diff --stat` touches only the test file.

## Work log

- 2026-07-23: created by /milestone-plan.

## Decisions

## Review
