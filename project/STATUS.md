# Project status

- Milestone: M3 — imbalanced & incomplete designs (in progress; estimand spec done)
- Active task: — (M3 Slice 1 next: connectedness guard + `k_eff` divisor for the
  incomplete random-rater path — run `/start-task`)
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

Slice 0 done: [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md)
written (connectedness rule; random + fixed Case 3/3A estimands; `k_eff` divisor;
balanced-reduction guard; oracle set O5/O6) and ADR-008 recorded. Docs-only, so no
code gate to run; last green CI unchanged (PR #1).

**Next action:** `/start-task` on M3 Slice 1 — `assert_connected_design()` +
balance detection (`abort_unidentified()` on a disconnected subject×rater graph),
wire it into `icc()`, and implement the `k_eff` (harmonic-mean) divisor for
`unit = "average"`. Oracle sourcing for unbalanced data is the gating risk
(seeded O5 simulation + lme4; `irrNA`/`gtheory` only where they compute the same
estimand); stop and recommend a Fable review if any coefficient can't be pinned by
≥2 oracles (PRINCIPLES.md #1, #19).
