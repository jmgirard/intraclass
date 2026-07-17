# M53: Multilevel SEM (lavaan) — estimand/oracle pass (done 2026-07-16)

**Goal:** establish whether a two-level lavaan CFA faithfully estimates the
ten Hove (2022) Design-1 five-component decomposition. **Outcome: GO.**
PR: https://github.com/jmgirard/intraclass/pull/59 (squash 4f68093).

- Source hunt: no primary source composes two-level SEM with GT-IRR →
  maintainer disposition **D-005** (IP1-fenced estimation-route
  parameterization, M5 precedent; ip-touching gate).
- Evidence: `data-raw/pilot-sem-multilevel.R` (seeded; ledger + results in
  `cairn/references/sem-multilevel-pilot.md`) — REML component parity
  (consistency ICCs exact; cluster-axis gap shrinking .025→.0025), reduction
  to the shipped single-level engine (<.02), 4-cell recovery (cluster axis +
  k axis; 450 fits, 0 failures), MC-interval feasibility at both levels.
- Key statistical result beyond the plan: the raw quadratic-form σ²_r
  estimator carries deterministic inflation E = σ²_r + τ², τ² = (σ²_cr +
  σ²_res/n_s)/N_c (multilevel analog of the single-level engine's documented
  "−σ²_res/n" term) — found by the review's diff-bug lens (scored 95),
  verified to ≤1e-4, pinned as an invariant-type law; engine milestone must
  centre rater-parity tests on τ², never zero.
- Process: one GP5 pin correction (run-1 rater pin was a 0.71σ coin flip;
  pins split by governing axis, k=25 cell added, prospective + documented).
- Follow-on: the engine implementation (`engine="lavaan"` + `cluster`) is a
  schedulable ROADMAP candidate; M48 dependency satisfied.
