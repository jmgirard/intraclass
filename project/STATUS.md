# Project status

- Milestone: **M11 — general `autoplot()` / `plot()` methods for `icc` objects** —
  **active** (detailed by ADR-020). M10 shipped (PR #14).
- Active task: **M11 Slice 2 — variance-component decomposition** (`autoplot.icc(what =
  "components")`). Slice 1 (coefficient forest plot) is **done + green** (397 tests, lint
  clean, installed-package dispatch verified); not yet committed. See the M11 DoD board
  in `MILESTONES.md`.
- Last green CI: PR #14 (M10) full matrix green incl. Windows; merged to `main` at
  9f799d2
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M11 scoped (ADR-020) + DoD written;
  Slice 1 (coefficient forest plot) implemented, green (397 tests), on branch
  `m11-autoplot-icc` (uncommitted). Slice 2 next.

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

**M11 Slice 2 — variance-component decomposition.** Slice 1 (coefficient forest plot)
is done and green on branch `m11-autoplot-icc` (uncommitted — awaiting the go-ahead to
commit). Slice 2 implements the `what = "components"` branch of `autoplot.icc()` —
replacing the interim `abort_unsupported` stub in `autoplot_icc_components()` — a bar of
the `$components` slots (subject/rater/residual, plus cluster + cluster:rater for
multilevel), honouring the design variants `format.icc` already handles (one-way's
confounded rater, Design 2's `rater:cluster`, Design 3's absent rater/cluster:rater).
Build-data tests assert bar heights == `$components` across two-way/one-way/Design 1/
nested. Then the whole-M11 gate (full CI matrix incl. Windows, pkgdown) + PR.

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
