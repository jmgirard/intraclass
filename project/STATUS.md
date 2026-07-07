# Project status

- Milestone: M2 — consistency variants + fixed-vs-random raters (done; merged to
  `main` via PR #1)
- Active task: — (awaiting go-ahead to plan M3)
- Last green CI: PR #1 full matrix green (9 checks) on 9c85c0b; merged to `main`
  at 334a48a
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M2 shipped: `icc()` now supports `type = "consistency"` (`ICC(C,1)`/`ICC(C,k)`)
and `raters = c("random", "fixed")` — fixed raters a balanced-data label layer
over the shared fit (two-way mixed, SF `ICC(3,*)`) with a loud classed
`intraclass_fixed_raters` warning. Verified against SF 0.715/0.909, `psych`
ICC3/ICC3k, and the fixed≡random equivalence (O4). PR #1 merged at 334a48a; a
docs-only reconciliation commit follows to close the "pending push" markers.

**Next (M3, provisional):** imbalanced & incomplete designs + the flagship
"Choosing an ICC" vignette. M3 inherits the load-bearing debt from ADR-006: the
fixed-raters label layer is **balanced-data only** and must be revisited with a
real fixed-effect fit path (or a balanced-design guard) once incomplete data
arrives. Await a short M2 retro + sign-off before planning M3 (founding brief §7).
