# Project status

- Milestone: M3 — imbalanced & incomplete designs (done; local gate green, pending PR CI + merge)
- Active task: — (M3 complete on branch `m3-incomplete-designs`; open PR, merge on green CI, then plan M4)
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

M3 complete (all three slices). Slice 2 shipped the real fixed-effect fit path
(`score ~ 1 + rater + (1 | subject)`) for `raters = "fixed"`, resolving the ADR-006
debt: Case 3 consistency (σ²_s/σ²_res) and Case 3A absolute agreement with the
bias-corrected θ²_r (finite-population variance of the k rater means), returned in
the "rater" slot so `icc_point`/`mc_ci` are unchanged; per-draw θ²_r + clamp for the
CI; corrected `raters` roxygen note. Verified by O6: balanced reduction (fixed →
0.290/0.620/0.715/0.909, θ²_r = σ²_r = 5.2444), lme4 fixed-fit cross-engine on
incomplete data (< 1e-4), and a 300-rep coverage simulation with known fixed effects
(bias −0.005, interval coverage 0.950/0.947 at 95%). No Fable review needed.

Local gate green: tests 118/0/0; `check` 0 errors / 0 warnings / 1 NOTE
(CRAN-incoming feasibility — pre-existing, unrelated); lint 0; coverage 93.8%
(uncovered lines are defensive engine/error branches). Last green CI still PR #1;
M3 lives on branch `m3-incomplete-designs` (4 commits: plan, spec, Slice 1,
Slice 2), **not yet merged**.

Workflow (maintainer preference, this session): milestone work goes on a
`m<N>-<slug>` branch and merges via PR, not direct commits to `main`.

**Next action:** open a PR from `m3-incomplete-designs`, confirm the full CI
matrix is green, and merge. Then reconcile the "pending PR CI + merge" markers
(STATUS "Last green CI", MILESTONES M3, TASKS M3) to the merged state in one
commit (PRINCIPLES.md #16). After that, `/start-task` begins M4 (the flagship
"Choosing an ICC" vignette).
