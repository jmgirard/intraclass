# Project status

- Milestone: M4.5 — D-study projection (in progress; branch `m4.5-d-study`, ADR-010)
- Active task: D-study projection — Slices 1–2 implemented; local green gate + PR next
- Last green CI: PR #5 (M4) full matrix green (9/9); merged to `main` at 4d4b2ba
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## Next action

M4.5 (the deferred D-study projection, ADR-010) is being shipped as its own slice
before M5, on branch `m4.5-d-study`. Slice 1 (projection core): the estimand now
carries a resolved numeric `divisor` (`resolve_divisor()`); `icc()`'s `unit`
accepts numbers (`ICC(A,3)` rows); `d_study(x, m = …)` returns an `icc_dstudy`
table of Φ(m) reusing the stored fit (no refit; `x$mc`), drawing the MC sample
once and evaluating every `m`; fixed-rater absolute-agreement projection is
refused (#5). Oracles O-DS: Spearman–Brown, GT dependability, `psych` at
`m = n_raters`, seeded simulation (`data-raw/oracle-d-study.R`). Slice 2:
`autoplot.icc_dstudy()` (ggplot2, lazily registered via `zzz.R`),
`plot`/`print`/`tidy`/`glance`, NEWS, `_pkgdown` entry, and an `advanced.Rmd`
D-study section with a backing claims test. Estimand-spec `M4.5-d-study.md`.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).

**Next action:** finish the green gate (`devtools::check()` 0/0/0 local, full CI
matrix on the PR), open the M4.5 PR, then merge and begin **M5 — multilevel ICCs**
(subject-level vs. cluster-level, ten Hove 2021).
