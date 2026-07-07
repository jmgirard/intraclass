# Project status

- Milestone: M2 — consistency variants + fixed-vs-random raters (built locally,
  all gates green; on branch `m2-consistency`, pending push + PR CI)
- Active task: — (next: push branch, open PR, confirm CI green)
- Last green CI: 77e8ab0 (M1; the M2 branch is not yet pushed)
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M2 is implemented on branch `m2-consistency` and passes the full local gate:
71 tests (0 fail/skip), `devtools::check()` 0/0/0, 0 lints, `air` clean, coverage
94.8% (statistical paths 100%). `icc()` now takes `type = "consistency"` →
`ICC(C,1)`/`ICC(C,k)` and `raters = c("random", "fixed")`; fixed raters is a
labelling layer over the shared fit (two-way mixed, SF `ICC(3,*)`) with a loud
classed `intraclass_fixed_raters` warning. Oracles: SF 0.715/0.909, `psych`
ICC3/ICC3k (1e-4), and the fixed≡random equivalence (O4;
`data-raw/oracle-fixed-vs-random.R`).

**Next:** push `m2-consistency`, open a PR (first commit `13fb915` already carries
the planning + skill fixes), confirm the full CI matrix is green, then reconcile
`STATUS.md` "Last green CI" and the MILESTONES/TASKS "pending push" markers (the
`finish-task` post-push step).
