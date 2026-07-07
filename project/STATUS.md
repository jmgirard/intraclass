# Project status

- Milestone: M3 — imbalanced & incomplete designs (done; merged via PR #2, full CI matrix green)
- Active task: — (next: plan M4 — the flagship "Choosing an ICC" vignette)
- Last green CI: PR #2 (M3) full matrix green; merged to `main` at 11ab1b2
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M3 shipped and merged (PR #2): incomplete/imbalanced two-way designs. Slice 1 —
`summarize_design()` (union-find connectedness, `k_eff` harmonic-mean divisor,
within-cell replicate guard) + the incomplete random-rater path (oracle O5: lme4
cross-engine on incomplete data + seeded MCAR simulation). Slice 2 — the real
fixed-effect fit (`score ~ 1 + rater + (1 | subject)`) resolving the ADR-006 debt:
Case 3 consistency and Case 3A absolute agreement with the bias-corrected θ²_r
(returned in the "rater" slot so `icc_point`/`mc_ci` are unchanged); oracle O6
(balanced reduction 0.290/0.620/0.715/0.909, lme4 cross-engine, 95% CI coverage).
Decisions: ADR-007 (arc reorder), ADR-008 (connectedness, `k_eff`, fixed real-fit).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR, not
direct commits to `main` (see the `milestone-branches-and-prs` memory; the
`finish-task` skill was updated to match in PR #3).

**Next action:** `/start-task` begins **M4 — the flagship "Choosing an ICC"
vignette** (the decision framework across agreement/consistency, single/average,
fixed/random, complete/incomplete, demonstrated on the M3 code). Detail M4's
Definition of Done at its start after a short M3 retro (founding brief §7).
