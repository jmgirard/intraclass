# M109: Re-run the 19 remaining oracle-bayesian-*.R scripts through the harness

**Status:** done (2026-08-08, PR #118 https://github.com/jmgirard/intraclass/pull/118)

**Goal:** Close the PRINCIPLES.md #12 reproducibility gap for the 19 remaining
live-Stan Bayesian oracle scripts via the M107 harness under D-024.

**Outcome:** All 19 `data-raw/oracle-bayesian-*.R` scripts re-ran through
`data-raw/rerun-oracle.R`: 11 `reproduced` (max_abs_delta 0), 8
`drift-within-noise` (worst 3.26e-02), every pin passing — zero escalations,
so no adjudications; the M108/D-025 seeded-template remedy generalized. The
two non-`stopifnot` scripts' pin outcomes live in their ledger notes
(cluster-ck `check()` 5/5, incomplete-fixed-nested `in_band` 4/4, all PASS).
Fixtures tree unchanged vs main. Sweep ≈12.5 h vs the 4–10 h estimate; one
batch interrupted by a concurrent glmmTMB reinstall (re-ran clean, same 1.1.14).

**Decisions:** none promoted. Work-log dispositions: the plan-gate wall-clock
falsifier fired and the four-batch decision stands (anchor future sweeps per
design family, not per fit count); ledger-notes chosen over harness extension
for non-`stopifnot` pins (plan gate).

**Review:** 3 lenses + scorer on PR #118: 11 findings, none reached the 80
action threshold — all logged (top: F8 66, F6 62; F6 dispositioned in the work
log). Gates green: cairn_validate, check() 0/0/0, 6116 tests. Post-merge:
extended the M107 LESSONS sizing line (anchor-per-family + mid-run reinstall).
