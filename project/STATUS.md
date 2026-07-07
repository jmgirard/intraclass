# Project status

- Milestone: **M11 — general `autoplot()` / `plot()` methods for `icc` objects** —
  **active** (detailed by ADR-020). M10 shipped (PR #14).
- Active task: **M11 milestone gate** (open a PR from `m11-autoplot-icc`; full CI matrix
  incl. Windows + pkgdown). Both slices done + green: Slice 1 (coefficient forest plot,
  committed `4810a8a`) and Slice 2 (variance-component decomposition, uncommitted). 402
  tests, lint clean, installed-package dispatch verified. See the M11 DoD board.
- Last green CI: PR #14 (M10) full matrix green incl. Windows; merged to `main` at
  9f799d2
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M11 Slices 1 & 2 implemented, green
  (402 tests), on branch `m11-autoplot-icc`. Slice 1 committed (`4810a8a`), Slice 2
  uncommitted. Next: commit Slice 2 + open the M11 PR.

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

**M11 milestone gate — open the PR.** Both slices are done and green on branch
`m11-autoplot-icc`: Slice 1 (coefficient forest plot, committed `4810a8a`) and Slice 2
(variance-component decomposition, `what = "components"`, uncommitted). Next: commit
Slice 2, push `m11-autoplot-icc`, open a PR, and confirm the full CI matrix (incl.
Windows, installed-package test with `NOT_CRAN=true`) + pkgdown are green before merge
(`milestone-branches-and-prs`). Post-merge, reconcile `project/` on `main`.

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
