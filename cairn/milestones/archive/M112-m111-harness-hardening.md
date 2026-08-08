# M112: Harden the M111 fallback-sweep harness

**Status:** done (2026-08-08, PR #122 https://github.com/jmgirard/intraclass/pull/122)

**Goal:** Close the M111 harness's three recorded defects — silent lost-worker cell drop,
abort-classification conflation, mis-implemented near-miss — without touching the committed evidence.

**Outcome:** `m111-fallback-sweep.R` gains `assert_sweep_results()`, a completeness guard over the
parallel map run before any fixture write, covering the killed-`mclapply`-worker NULL shape a
`try-error` check misses; and an explicit ok/abort status from `mc_ci()` that the MC leg's `aborted`
is set from, so only the classed `intraclass_singular_fit` counts (classical legs keep their
finiteness flag, F1's comparator). `m111-fallback-verdict.R` gains `near_miss_below()`, the frozen
failing-side window, for F2 and newly F3; both take env-var path overrides. Counts corrected to F2
SEARLE 4 / Burch 5 (was 1/4, passing side) and F3 SEARLE 1 / Burch 0; fixtures byte-identical, no
verdict altered. `m112-harness-demo.R` runs a mutated and a clean case per guard.

**Decisions:** F1 and F5 take no near-miss count (F1's threshold argued a count rather than a rate;
F5 binds on three statistics with no single referent), and the failing-side count is vacuous whenever
the tie-break is live — every contributing cell is a failing cell. Milestone-local, no D-entry.

**Review:** Three-lens fan-out + scorer: 13 findings, all sub-80 (highest 60), actioned list empty.
H-1/M-4 (checkpoints keyed on cell id alone can serve an old grid past every guard) → candidate row;
M-2 (55) holds the F1 rationale above wrong (100% is a rate) — shipped as recorded. One lesson captured
(`mclapply`'s NULL slot); none retired, the stalest pruned for the cap (D-009 now owns it).
