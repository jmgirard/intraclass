# Project status

- Milestone: **M11 — general `autoplot()` / ggplot2 methods** — next (provisional; not
  yet detailed). M10 shipped (PR #14).
- Active task: — (next: retro + detail M11 — general variance-component / CI plots)
- Last green CI: PR #14 (M10) full matrix green incl. Windows; merged to `main` at
  9f799d2
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M10 merged + `project/` reconciled

## Where we are

**Shipped M0–M9** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); the crossed design handles **incomplete (ragged)**
data (subject level + cluster-level `ICC(c,1)`) with a declared-`design` disambiguation
and oracle-pinned identifiability guards (M9); and the crossed design also supports
**fixed raters** at the subject level, balanced (M10). The multilevel family is now
crossed × {complete, incomplete} × {random, fixed} at the subject level.

## Next action

**Retro + detail M11** (general `autoplot()` / ggplot2 methods). Per the process (#2,
brief §7), run a short M10 retro, then resolve M11 scope with the maintainer and write
the DoD before code. M11 is a **change of pace from estimator work**: a visualization
layer over the shipped coefficients (**no new estimand**), generalizing the M4.5
`d_study()` reliability curve to variance-component and CI plots. Ships on a `m11-*`
branch, merges via PR (`milestone-branches-and-prs`).

Milestone arc after M11 (ADR-017): **M12** `choose_icc()` → **M13** release polish.

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
