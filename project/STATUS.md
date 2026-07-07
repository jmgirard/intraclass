# Project status

- Milestone: **M12 — `choose_icc()` interactive decision helper** — ACTIVE (detailed by
  ADR-021 this session; DoD board in [`MILESTONES.md`](MILESTONES.md)). M11 shipped (PR #15).
- Active task: **M12 Slice 2** — guarded interactive Q&A shell + M4-vignette pointer.
  Slice 1 (programmatic core + `icc_recommendation` object + 62 tests) DONE on branch
  `m12-choose-icc` (full suite 464/0/0, lintr clean; not yet committed).
- Last green CI: PR #15 (M11) full matrix green incl. Windows and R-devel; merged to
  `main` at 3368299
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M12 Slice 1 shipped locally (choose_icc core)

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

**Build M12 Slice 2** on `m12-choose-icc`: the guarded interactive Q&A shell over the
Slice-1 resolver — ask only the outstanding axes one at a time via `cli`, only when
`rlang::is_interactive()`, in the vignette's order (model first); collect answers then
call `resolve_icc_recommendation()`. Test the collection logic via an **injected
responder** (no live readline in CI) and assert the shell is skipped when
`is_interactive()` is `FALSE`. Then add the short `choosing-an-icc.Rmd` pointer ("or let
the package choose: `choose_icc()`") with a non-interactive runnable example; `air
format`; `lintr`; installed-package test (`NOT_CRAN=true`); then PR → CI → merge. See
ADR-021 + the M12 DoD board in [`MILESTONES.md`](MILESTONES.md).

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
