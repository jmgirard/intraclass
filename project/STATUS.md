# Project status

- Milestone: M3 — imbalanced & incomplete designs (in progress; Slices 0–1 done)
- Active task: — (M3 Slice 2 next: real fixed-effect fit path — run `/start-task`)
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

Slice 1 done: incomplete random-rater path shipped and oracle-verified.
`R/design.R` (`summarize_design()`: union-find connectedness, `k_eff`, replicate
detection); `icc()` guards (`abort_unidentified` disconnected, `abort_unsupported`
replicates); `k_eff` divisor; `print`/`glance` completeness + `k_eff`. Verified by
O5 (lme4 cross-engine on incomplete data < 1e-4; seeded MCAR simulation recovers
components, CIs cover) + balanced reduction. Local gate green: tests 104/0/0,
`check` 0 errors / 0 warnings / 1 NOTE (CRAN-incoming feasibility — new submission /
dev version / pkgdown URL 404; pre-existing, unrelated), lint 0, coverage 95.7%
(`design.R` 100%). Not yet pushed.

**Next action:** `/start-task` on M3 Slice 2 — real fixed-effect fit path
(`score ~ 1 + rater + (1 | subject)`) for `raters = "fixed"`: fixed-raters error
set (consistency = residual; agreement + θ²_r, Case 3A), branch on `design$raters`,
fixed-path MC-CI sampler, corrected `raters` roxygen note. Oracle-pin θ²_r in Slice 2
(psych/lme4 fixed fit + balanced reduction, O6); stop + recommend Fable if unpinnable
(PRINCIPLES.md #1, #19).
