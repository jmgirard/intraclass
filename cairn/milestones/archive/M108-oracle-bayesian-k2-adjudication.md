# M108: Adjudicate the oracle-bayesian.R k=2 convergence divergence

**Status:** done (2026-08-07, PR #117 https://github.com/jmgirard/intraclass/pull/117)

**Goal:** Execute the D-024 escalation decision for the `oracle-bayesian.R` `diverged-escalated` ledger row: adaptive warmup, regenerated fixture, recorded adjudication.

**Outcome:** `data-raw/oracle-bayesian.R` doubles warmup adaptively per rep
(≤ 3 doublings, `iter = warmup + 1000`) — k=2 `converged_frac` .864 → 1.000 —
and its base-template stage is seeded: `update()` refit draws depend on the
template fit, so every pre-M108 run was an unreproducible realization (the
.864/.904/.924 spread). Fixture re-baselined at n_rep 500, 4/4 pins; harness
verdict `reproduced`, max_abs_delta 0. ORACLES.md O-Bayes refreshed; the 19
sibling `oracle-bayesian-*.R` scripts share the pattern (M109 inherits D-025).

**Decisions:** D-025 (the adjudication; executes D-024 clauses 3–4). Gated
amendment 2026-08-07: template seeding + n_rep 250 → 500, maintainer-chosen
over 250-only, pin-softening, and pause.

**Review:** 3 lenses → scorer, 14 candidates; actioned F1 (88, disambiguation
note on the local D-025 vs the cairn plugin's id) and F4 (82, attempt-0
sampler-budget disclosure restored), both fixed on-branch; 3 voluntary sub-80
comment fixes. CI caught the pre-existing `roadmap-terminal-rows` ledger
staleness from M107's rotation (fixed; rotated again with this archive in the
same commit). No LESSONS line — D-025 owns the template-seeding finding, and
the terminal-rows sync is checker-enforced.
