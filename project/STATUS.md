# Project status

- Milestone: **M12 — `choose_icc()` interactive decision helper** — ACTIVE (detailed by
  ADR-021 this session; DoD board in [`MILESTONES.md`](MILESTONES.md)). M11 shipped (PR #15).
- Active task: **M12 ship** — Slices 1 & 2 DONE on branch `m12-choose-icc`
  (`choose_icc()` core + guarded interactive shell + M4-vignette pointer, 76 helper
  tests). Installed-package suite 478/0/0, lintr clean, vignette knits. Remaining: push
  branch → PR → full CI matrix → merge → reconcile `project/` on `main`.
- Last green CI: PR #15 (M11) full matrix green incl. Windows and R-devel; merged to
  `main` at 3368299
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M12 Slices 1 & 2 done locally; ready for PR

## Where we are

**Shipped M0–M11** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); the crossed design handles **incomplete (ragged)**
data (subject level + cluster-level `ICC(c,1)`) with a declared-`design` disambiguation
and oracle-pinned identifiability guards (M9); and the crossed design also supports
**fixed raters** at the subject level, balanced (M10). The multilevel family is now
crossed × {complete, incomplete} × {random, fixed} at the subject level. Every fitted
`icc` object now has `autoplot()`/`plot()` methods — a coefficient forest plot and a
variance-component decomposition (M11).

## Next action

**Ship M12**: push `m12-choose-icc`, open the PR, and get the full CI matrix (incl.
Windows + R-devel) green; then merge and reconcile `project/` on `main` (finish-task
policy — direct commit, no CI job reads `project/`). Both slices are code-complete and
green locally (installed-package suite 478/0/0). See ADR-021 + the M12 DoD board in
[`MILESTONES.md`](MILESTONES.md).

Milestone arc after M12 (ADR-017): **M13** release polish (pkgdown, advanced vignette,
CRAN prep).

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
