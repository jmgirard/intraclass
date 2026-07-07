# Project status

- Milestone: **M12 — `choose_icc()` interactive decision helper** — next (provisional;
  not yet detailed). M11 shipped (PR #15).
- Active task: — (next: retro + detail M12 — the interactive ICC-selection helper)
- Last green CI: PR #15 (M11) full matrix green incl. Windows and R-devel; merged to
  `main` at 3368299
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M11 merged + `project/` reconciled

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

**Retro + detail M12** (`choose_icc()` interactive decision helper). Per the process
(#2, brief §7), run a short M11 retro, then resolve M12 scope with the maintainer and
write the DoD before code. M12 is a **teaching/API helper** (no new estimand) mirroring
the M4 flagship vignette's agreement/consistency × single/average × fixed/random ×
complete/incomplete decision tree. Ships on a `m12-*` branch, merges via PR
(`milestone-branches-and-prs`).

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
