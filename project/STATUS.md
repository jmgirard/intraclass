# Project status

- Milestone: M2 — consistency variants + fixed-vs-random raters (planned; spec +
  ADR-006 written, awaiting go-ahead to build)
- Active task: — (next: `icc_estimand()` consistency error set + `raters` dimension)
- Last green CI: 77e8ab0 (all 5 workflows green: R-CMD-check matrix, coverage,
  lint, format, pkgdown)
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M2 is planned and specced. Scope confirmed with the maintainer: **lean** slice —
consistency `ICC(C,1)`/`ICC(C,k)` (drop the rater main effect from the error set)
plus a `raters = random|fixed` dimension handled as a **label/interpretation layer**
over the shared M1 fit. The fixed≡random equivalence was verified live for REML on
balanced data (glmmTMB + lme4 + `psych`; identical σ²_s/σ²_res, ΔICC ~1e-5) and
shown to **break under imbalance** (ΔICC(C,1) ≈ 0.01) — so M3 must revisit fixed
raters (ADR-006). Fixed raters is opt-in with a loud classed
`intraclass_fixed_raters` best-practice warning; lme4-selectable-engine and D-study
projection are deferred to their own slices.

Written this session: [`estimand-specs/M2-consistency-and-fixed.md`](estimand-specs/M2-consistency-and-fixed.md),
ADR-006, detailed M2 DoD in [`MILESTONES.md`](MILESTONES.md), and the M2 task board
in [`TASKS.md`](TASKS.md). **Next:** on go-ahead, build the M2 board top-down
starting with `icc_estimand()` (consistency error set + `raters` labeling
dimension). No code or commit yet.
