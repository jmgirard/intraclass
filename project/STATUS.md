# Project status

- Milestone: M4 — "Choosing an ICC" flagship vignette (planned; spec in MILESTONES M4, ADR-009)
- Active task: M4 Slice 1 — teaching dataset done (`ratings` + `ratings_incomplete` shipped); next: balanced-core article + diagram
- Last green CI: PR #2 (M3) full matrix green; merged to `main` at 11ab1b2
- Blockers: —
- Updated: 2026-07-06 by main session (Opus)

## Next action

M4 is planned (this session, after the M3 retro; founding brief §7). It is the
flagship "Choosing an ICC" teaching article, demonstrated on the now-shipped M3
code. Scope pinned by **ADR-009**: vignette-only (the `choose_icc()` helper stays
in ROADMAP) **plus a shipped teaching dataset** (`ratings` + `ratings_incomplete`);
a dependency-free static-SVG decision diagram; the README brought current. No new
estimator, no new estimand spec. Two CI-green slices (see MILESTONES M4 / TASKS M4):
Slice 1 = dataset + balanced-core article + diagram + claims test; Slice 2 =
incomplete-design section + subject/cluster preview + pkgdown wiring + README
refresh + close-out. Teaching discipline: every displayed coefficient is computed
by `icc()` at knit time with a fixed seed (#4, #12), and the asserted numeric
relationships are backed by `test-vignette-claims.R` (#1).

Workflow: milestone work ships on a `m<N>-<slug>` branch (here `m4-<slug>`) and
merges via PR, not direct commits to `main` (see the `milestone-branches-and-prs`
memory; the `finish-task` skill was updated to match in PR #3).

**Next action:** `/start-task` begins **M4 Slice 1** — the first task is
`data-raw/make-ratings.R` building the `ratings` and `ratings_incomplete` teaching
datasets (PRINCIPLES #12 deterministic/sourced), then the balanced-core article.
