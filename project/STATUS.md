# Project status

- Milestone: **M9 — incomplete/unbalanced multilevel ICCs, Design 1 (crossed)** —
  detailed and active (estimand-spec + ADR-018 written; M8 retro done)
- Active task: M9 Slice 2 — cluster-level IRR under imbalance + boundary matrix (next).
  Slice 1 (incomplete Design-1 subject level) done + committed on
  `m9-incomplete-multilevel`: 331 tests green, lintr/air clean
- Last green CI: PR #12 (M8) full matrix green incl. Windows; merged to `main` at
  ca2dcdb
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M9 detailed (ADR-018, spec, DoD board)

## Where we are

**Shipped M0–M8** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; and the multilevel estimator covers ten Hove et al. (2022)
Designs 1–3 (crossed and both nested-rater designs).

## Next action

**M9 Slice 2** — cluster-level IRR under imbalance + the boundary matrix (spec §6).
Lift the Slice-1 loud abort on incomplete cluster-level: report the M5 cluster-level
estimand (signal σ²_c, error {σ²_r, σ²_cr}) on ragged crossed data behind its own §4b
gate (σ²_c estimable + cluster×rater linkage), aborting to the subject level when
unmet; add the full boundary/guard snapshot matrix (§7) and the two-level reductions to
complete M5. Then Slice 3 (docs) closes M9.

Milestone arc after M9 (ADR-017): **M10** fixed-rater-ML → **M11** general
`autoplot()`/ggplot2 → **M12** `choose_icc()` → **M13** release polish.

Still deferred (not scheduled): **lme4 for the fixed/multilevel fits** (engine parity,
ADR-012 — glmmTMB covers these paths); the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`); **one-way / general ICC(1) via SEM** (no faithful sourced
route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
