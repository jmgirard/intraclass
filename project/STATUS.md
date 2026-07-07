# Project status

- Milestone: M3 — imbalanced & incomplete designs (planned; not started)
- Active task: — (M3 Slice 0: write the estimand spec — run `/start-task`)
- Last green CI: PR #1 full matrix green (9 checks) on 9c85c0b; merged to `main`
  at 334a48a
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M3 is planned and the arc reordered (ADR-007): M3 is the **statistical core only**
— imbalanced/incomplete designs (random raters) + resolving the ADR-006 fixed-raters
debt via a **real fixed-effect fit path**. The flagship "Choosing an ICC" vignette
is now its own milestone (M4); prior M4–M6 renumber to M5–M7. Two internal CI-green
slices; board in [`TASKS.md`](TASKS.md), Definition of Done in
[`MILESTONES.md`](MILESTONES.md), full plan `moonlit-mixing-pinwheel`.

**Next action:** `/start-task` on M3 Slice 0 — write
`project/estimand-specs/M3-incomplete-designs.md` (identifiability/connectedness
rule; random + fixed Case 3/3A estimands; balanced-reduction guard) and **pin the
`ICC(*,k)` divisor convention under imbalance** with citations, recording it as
ADR-008. Spec before code (PRINCIPLES.md #2). The oracle sourcing for unbalanced
data is the gating risk (`irrNA`/`gtheory` availability + seeded simulation); stop
and recommend a Fable review if any coefficient can't be pinned by ≥2 oracles.
