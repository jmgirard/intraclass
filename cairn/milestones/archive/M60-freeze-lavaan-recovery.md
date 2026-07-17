# M60: Freeze the lavaan multilevel recovery sweep (done)

- done · normal · Principles GP5, GP6, GP7 · PR #64 (squash-merged 2026-07-17)

## Goal
Freeze the 100-refit lavaan `O-SEM-ML/recovery` sweep to a committed fixture
(cutting the test-suite tail file) with a mutation-verified live guard per frozen
pin so no discriminating power is lost.

## Outcome
- New seeded `data-raw/oracle-sem-multilevel-recovery.R` writes
  `fixtures/sem-multilevel-recovery-oracle.rds` (Cell B 60 + Cell D 40 refits,
  verbatim pop/seeds; provenance D-005 + ten Hove 2022; reproduces
  bit-identically). `O-SEM-ML/recovery` reads it — same pins/tolerances (GP5).
  File **137s → 63.8s** (−53%); last heavy live CI refit sweep (cluster + brms
  already frozen).
- Rigor preserved by two LIVE guards, both M51 mutation-verified red: Cell B →
  `O-SEM-ML/parity` (vs glmmTMB REML; `svw*1.1`→red); Cell D → new
  `O-SEM-ML/tau2-invariant` (`/(k-1)→/k`→red). Full suite FAIL 0 | PASS 1725; CI
  green incl. Windows.

## Key decisions
- Review (blame-history lens, scored 62) hardened the tau^2 guard from nc=25/k=6
  to **pilot cell B** (nc=40, k=5, ledger-verified differencing), tol 0.004→0.005,
  n_rep 3→4 — robust to cross-version/BLAS drift (M56).
