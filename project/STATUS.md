# Project status

- Milestone: **M10 — fixed-rater multilevel ICCs** — next (provisional; not yet
  detailed). M9 shipped (PR #13).
- Active task: — (next: retro + detail M10 — fixed-rater multilevel)
- Last green CI: PR #13 (M9) full matrix green incl. Windows; merged to `main` at
  073a51e
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M9 merged + `project/` reconciled

## Where we are

**Shipped M0–M9** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); and the crossed design now also handles **incomplete
(ragged)** data (subject level + cluster-level `ICC(c,1)`) with a declared-`design`
disambiguation and oracle-pinned identifiability guards.

## Next action

**Retro + detail M10** (fixed-rater multilevel ICCs). Per the process (#2, brief §7),
run a short M9 retro, then resolve M10 scope with the maintainer and write the estimand-
spec + DoD before code. M10 reuses the **M3 real fixed-effect fit path** (ADR-008) on
the multilevel fit — the multilevel-completion pair with M9 (ADR-017). Ships on a
`m10-*` branch, merges via PR (`milestone-branches-and-prs`).

Carry into the M9 retro: the CI-red lesson — **verify against the installed package,
not just `devtools::load_all`** (`verify-against-installed-package` memory), and don't
snapshot multilevel-fit prints (platform-fragile MC-CI).

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
