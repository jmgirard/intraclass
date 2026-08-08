# M111: Fallback-on-abort default assessment — GO/NO-GO (composite MC → classical)

**Status:** done (2026-08-08, PR #120 https://github.com/jmgirard/intraclass/pull/120)

**Goal:** Decide, against a pre-registered frozen criterion, whether the one-way default should return a classical fallback interval where the MC default aborts — assessment only, no exported code.

**Outcome:** NO-GO for both arms (D-026); the status-quo abort stands, now on evidence. Frozen F1–F6 criteria page `cairn/references/fallback-on-abort-comparison.md` committed before any sweep artifact; 64-cell sweep (ρ ≤ 0.60 × 4 designs × gaussian/t5/uniform/chisq1 per burch2011 Table 2, extracted into the source note) at n_rep = 2000 via `data-raw/m111-fallback-sweep.R` (4-worker mclapply, 36 min) → fixture `m111-fallback-results.rds` + rule ledger `m111-fallback-rules.rds` (`m111-fallback-verdict.R`, incl. Clopper–Pearson conditional-on-abort rule + conditional tails). Decisive finding: the abort is informative — at informative designs the fallback misses upper-tail (cond. coverage 0.00–0.49); at low-information cells Burch covers 1.000 but nothing can tell the cases apart. Two candidate rows added: the MC default's skew under-coverage (0.673–0.676 at ρ=0.60 k≥30 chisq1, 0 aborts) and m111-harness hardening. Corrected in passing: the stale roadmap-terminal-rows record-claim expectation M110's rotation missed.

**Decisions:** D-026 (cross-cutting NO-GO; reopening evidence class stated). Milestone-local: verdict decided in-session per the plan-gate ip-touching choice, basis corrected at review (D2) with the conclusion standing on F3.

**Review:** One defect return (AC4's per-cell conditional table + insufficient list were missing from the page). Fan-out: prior-review clean; 5 actioned findings all fixed on-branch — D2 90 (near-miss statistic was F2 near-passes, not failure margins), D7 88 (conditional tails unimplemented + inverted claim), D1 85 (off-boundary rationale overgeneralized; rescoped to design informativeness), D3 80 (vacuous F1 assertion), D9 80 (understated n=2 range); 13 logged sub-80 (factual slips fixed, 2 latent harness gaps → candidate row).
