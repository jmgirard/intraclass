# Project status

- Milestone: M8 — nested-rater multilevel ICCs (Designs 2/3) — **in progress**
  (ADR-016; Slice 1)
- Active task: **M8 all three slices code+docs complete, green locally** (Designs 2
  & 3 inferred from crossing pattern; O-NML/lme4 + sim + reductions to two-way and
  M6 one-way; advanced.Rmd nested subsection + vignette-claims; full suite 313 pass /
  0 fail; `air`-clean; vignette knits). Next: **push `m8-nested-multilevel` + open
  the PR** for the full CI matrix (incl. Windows — watch the absolute-vs-relative
  interval-tolerance lesson). Spec:
  [`M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md).
- Last green CI: PR #11 (M7) full matrix green; merged to `main` at fe76f5c
- Blockers: — (paper obtained; Designs 2/3 equations transcribed into the spec)
- Slice-1 API resolved (maintainer): design 1/2/3 **inferred from the crossing
  pattern**, ambiguous → loud abort, detected design surfaced in print/glance (spec §4).
- Updated: 2026-07-07 by main session (Opus)

## Where we are

**Shipped M0–M7** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete, and glmmTMB, lme4, and lavaan are all selectable engines through the
M5.5 engine × design dispatch seam.

## Next action

**Start M8 Slice 1 — Design 2 (raters nested in clusters)** on a
`m8-nested-multilevel` branch (`/start-task`). The estimand-spec
[`M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md) is written and
scope is locked (ADR-016): Designs 2/3, **subject-level only** (cluster level
undefined for nested designs), Design 3 **agreement-only**; six coefficients total.
Slice 1 = the four-component Design-2 fit (`score ~ 1 + (1|cluster) +
(1|cluster:subject) + (1|cluster:rater)`, our translation — oracle-pinned first),
design detection (§4), the §3a map, and O-NML oracles (lme4 + sim + reduction to
two-way). One Slice-1-start API decision to settle: how the design (1/2/3) is
detected — inferred from the crossing pattern vs. an explicit `design` argument (§4).
Incomplete-ML, fixed-ML, and lme4-multilevel parity remain deferred (MILESTONES M8).

Also parked and un-scheduled: the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`), and **one-way / general ICC(1) via SEM** (no faithful
sourced route — ADR-014). Both in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
