# Project status

- Milestone: M7 — SEM engine (`lavaan`) — **done** (merged via PR #11 at fe76f5c)
- Active task: — (next: retro + detail M8 — multilevel & incomplete-design extensions)
- Last green CI: PR #11 (M7) full matrix green; merged to `main` at fe76f5c
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Where we are

**Shipped M0–M7** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete, and glmmTMB, lme4, and lavaan are all selectable engines through the
M5.5 engine × design dispatch seam.

## Next action

**Retro + detail M8** (multilevel & incomplete-design extensions) — currently a
provisional one-liner. Per the process (#2, brief §7), run a short M7 retro, then
resolve scope with the maintainer and write the DoD (ADR + spec as needed) before
code. M8 groups the M5 spec §8 deferrals — the paper's Designs 2/3 (raters nested in
clusters/subjects), incomplete multilevel (reuse M3 `k_eff`/connectedness),
fixed-rater multilevel (reuse M3 real fixed-effect fit), and lme4 for the
fixed/multilevel fits (deferred out of M5.5). See [`MILESTONES.md`](MILESTONES.md) M8.

Also parked and un-scheduled: the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`), and **one-way / general ICC(1) via SEM** (no faithful
sourced route — ADR-014). Both in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
