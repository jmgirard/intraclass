# Project status

- Milestone: **M9 — incomplete/unbalanced multilevel ICCs, Design 1 (crossed)** —
  detailed and active (estimand-spec + ADR-018 written; M8 retro done)
- Active task: M9 — open the PR. All three slices done on `m9-incomplete-multilevel`
  (subject level + cluster `ICC(c,1)` on ragged crossed data + docs); `ICC(c,k)`-
  incomplete deferred (spec §3b). Local suite green; needs the full R-CMD-check matrix
  (incl. Windows) via PR to close the milestone
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

**Open the M9 PR** (`milestone-branches-and-prs`): push `m9-incomplete-multilevel`
and open a PR to `main` so the full `R-CMD-check` matrix (incl. Windows) + lint +
pkgdown run. On green, merge and reconcile `project/` (compress M9 to a summary,
preserve its deferred list; set STATUS to M10). All three slices are committed and
locally green.

Deferred within M9 (recorded): averaged cluster-level `ICC(c,k)` on incomplete data —
the per-cluster effective-rater divisor is an open modeling question (spec §3b), a
candidate for a simulation-oracle study or Fable review post-M9.

Milestone arc after M9 (ADR-017): **M10** fixed-rater-ML → **M11** general
`autoplot()`/ggplot2 → **M12** `choose_icc()` → **M13** release polish.

Still deferred (not scheduled): **lme4 for the fixed/multilevel fits** (engine parity,
ADR-012 — glmmTMB covers these paths); the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`); **one-way / general ICC(1) via SEM** (no faithful sourced
route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
