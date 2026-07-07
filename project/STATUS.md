# Project status

- Milestone: M4.5 — D-study projection (done; merged via PR #6, full CI matrix green)
- Active task: — (next: plan M5 — multilevel ICCs)
- Last green CI: PR #6 (M4.5) full matrix green (9/9); merged to `main` at 9be03a0
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Next action

M4.5 shipped and merged (PR #6, `9be03a0`, full CI matrix green — 9/9). It is the
deferred D-study projection (ADR-010), shipped as its own slice before M5. Slice 1
(projection core): the estimand carries a resolved numeric `divisor`
(`resolve_divisor()`); `icc()`'s `unit` accepts numbers (`ICC(A,3)` rows);
`d_study(x, m = …)` returns an `icc_dstudy` table of Φ(m) reusing the stored fit
(no refit; `x$mc`), drawing the MC sample once and evaluating every `m`; fixed-rater
absolute-agreement projection is refused (#5). Oracles O-DS: Spearman–Brown, GT
dependability, `psych` at `m = n_raters`, seeded simulation
(`data-raw/oracle-d-study.R`). Slice 2: `autoplot.icc_dstudy()` (ggplot2, lazily
registered via `zzz.R` for oldrel), `plot`/`print`/`tidy`/`glance`, NEWS, `_pkgdown`
entry, and an `advanced.Rmd` D-study section with a backing claims test.
Estimand-spec `M4.5-d-study.md`. `devtools::check()` 0/0/0.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).

**Next action:** `/start-task` begins **M5 — multilevel ICCs** (subject-level vs.
cluster-level, ten Hove 2021). Detail M5's Definition of Done at its start
(founding brief §7).
