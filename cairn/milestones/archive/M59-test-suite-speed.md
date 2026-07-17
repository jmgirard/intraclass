# M59: Test-suite speed — rigor-invariant levers (done)

- done · normal · Principles GP5, GP6, GP7 · PR #63 (squash-merged 2026-07-17)

## Goal
Cut testthat wall-clock via rigor-invariant levers without loosening any oracle
tolerance, coverage claim, or failure-axis sweep.

## Outcome
- `Config/testthat/parallel: true` + `start-first` (3 fat files) — the headline:
  415 s serial → ~205–233 s parallel (8 cores, uncontended).
- Right-sized only STRUCTURAL `boot_samples` to B=99 (ci-bootstrap ×5, d-study
  ×4 + literals); serial ci-bootstrap 125→114 s, d-study 90→59 s. Every O1/O2
  oracle count left load-bearing; `mc_samples` untouched (cheap draws).
- Memoized d-study `fit_ds`; skip-gating audit clean.
- No product code changed. FAIL 0 / PASS 1724 unchanged; no
  `tolerance`/`mc_samples`/`n_rep`/`240` changed (AC3 vacuous, AC4 intact); M51
  mutation-checks red (AC5); `check()` 0/0/0; three-lens review 0 findings.

## Key findings
- Fat-file cost is DISTINCT random-rep coverage/recovery sims, not duplication —
  freezing them to `.rds` is the deferred lever-b candidate. Parallelism, not
  right-sizing, moved the needle. M57/M58 should follow these conventions.
