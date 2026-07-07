# Project status

- Milestone: **M10 — fixed-rater multilevel ICCs, Design 1 (crossed) balanced, subject
  level** — detailed and active (estimand-spec + ADR-019 written; M9 retro done)
- Active task: M10 — open the PR. Both slices done on `m10-fixed-multilevel`
  (fixed-rater multilevel subject-level `ICC`, balanced crossed + docs); needs the full
  R-CMD-check matrix (incl. Windows) via PR to close the milestone
- Last green CI: PR #13 (M9) full matrix green incl. Windows; merged to `main` at
  073a51e
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M10 detailed (ADR-019, spec, DoD board)

## Where we are

**Shipped M0–M9** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); and the crossed design now also handles **incomplete
(ragged)** data (subject level + cluster-level `ICC(c,1)`) with a declared-`design`
disambiguation and oracle-pinned identifiability guards.

## Next action

**Open the M10 PR** (`milestone-branches-and-prs`): push `m10-fixed-multilevel` and open
a PR to `main` so the full `R-CMD-check` matrix (incl. Windows) + lint + pkgdown run.
Already verified green against the **installed** package (`NOT_CRAN=true`). On green:
merge and reconcile `project/` (compress M10 to a summary, preserve its deferred list;
set STATUS to M11).

Milestone arc after M10 (ADR-017): **M11** general `autoplot()`/ggplot2 → **M12**
`choose_icc()` → **M13** release polish.

Open deferral from M9 (recorded): averaged cluster-level `ICC(c,k)` on incomplete data
— the per-cluster effective-rater divisor is an open modeling question (spec §3b), a
candidate for a simulation-oracle study or Fable review.

Still deferred (not scheduled): **lme4 for the fixed/multilevel fits** (engine parity,
ADR-012 — glmmTMB covers these paths); the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`); **one-way / general ICC(1) via SEM** (no faithful sourced
route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
