# Project status

- Milestone: M4 — "Choosing an ICC" flagship vignette (Slices 1–2 complete locally; PR open)
- Active task: M4 milestone close — `devtools::check()` 0/0/0, 133 tests pass; PR open, awaiting CI + merge
- Last green CI: PR #2 (M3) full matrix green; merged to `main` at 11ab1b2
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M4 (ADR-009) is built and green locally. Slice 1 shipped the `ratings` /
`ratings_incomplete` teaching datasets, the balanced-core "Choosing an ICC"
article, the dependency-free decision-tree SVG, and `test-vignette-claims.R`.
Slice 2 added the incomplete-design section (`k_eff`, connectedness abort,
fixed ≢ random on `ratings_incomplete`), the subject-vs-cluster preview pointing
at M5, the pkgdown `articles:` grouping, the getting-started/advanced refreshes,
and the README overhaul (stale M1 NOTE → current; runnable `icc()` example;
missing M3 + new M4 NEWS entries). `devtools::check()` 0/0/0, 133 tests pass,
`air`/`lintr` clean.

Three commits on `m4-choosing-icc` (`d585d90` plan/ADR-009, `e122708` datasets,
`585e27e` balanced core, plus this close-out). Milestone work merges via PR
(`milestone-branches-and-prs` memory), so `main` is untouched.

**Next action:** push `m4-choosing-icc` and open the PR; once the full CI matrix
is green, merge and reconcile M4 status to done (record the merge SHA here). Then
M5 (multilevel ICCs) is next — detail its DoD at its start after a short M4 retro.
