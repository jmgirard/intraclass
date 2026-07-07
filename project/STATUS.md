# Project status

- Milestone: M4 — "Choosing an ICC" flagship vignette (done; merged via PR #5, full CI matrix green)
- Active task: — (next: plan M5 — multilevel ICCs, after a short M4 retro)
- Last green CI: PR #5 (M4) full matrix green (9/9); merged to `main` at 4d4b2ba
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Next action

M4 shipped and merged (PR #5, `4d4b2ba`, full CI matrix green — 9/9). It is the
flagship "Choosing an ICC" teaching article (ADR-009), demonstrated on the M3
code. Slice 1: the `ratings` / `ratings_incomplete` teaching datasets, the
balanced-core article, the dependency-free decision-tree SVG, and
`test-vignette-claims.R`. Slice 2: the incomplete-design section (`k_eff`,
connectedness abort, fixed ≢ random on `ratings_incomplete`), the
subject-vs-cluster preview pointing at M5, the pkgdown `articles:` grouping, the
getting-started/advanced refreshes, and the README overhaul (runnable `icc()`
example; previously-missing M3 + new M4 NEWS entries). `devtools::check()` 0/0/0,
133 tests.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).

**Next action:** `/start-task` begins **M5 — multilevel ICCs** (subject-level vs.
cluster-level, ten Hove 2021). Detail M5's Definition of Done at its start after a
short M4 retro (founding brief §7).
