# Project status

- Milestone: M8 — nested-rater multilevel ICCs (Designs 2/3) — **done** (merged via
  PR #12 at ca2dcdb)
- Active task: — (next: retro + detail M9 — release polish)
- Last green CI: PR #12 (M8) full matrix green incl. Windows; merged to `main` at
  ca2dcdb
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Where we are

**Shipped M0–M8** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; and the multilevel estimator covers ten Hove et al. (2022)
Designs 1–3 (crossed and both nested-rater designs).

## Next action

**Retro + detail M9** (release polish) — currently a provisional one-liner (pkgdown
site, advanced vignette, CRAN submission prep). Per the process (#2, brief §7), run a
short M8 retro, then resolve M9 scope with the maintainer and write the DoD before
work. M9 is the last planned milestone; its remaining inputs are the ROADMAP
parking-lot items plus the M8 deferrals (incomplete-ML, fixed-ML, lme4-multilevel
parity) — decide which, if any, are in scope for a first release vs. post-CRAN.

Also parked and un-scheduled: the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`), and **one-way / general ICC(1) via SEM** (no faithful
sourced route — ADR-014). Both in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
