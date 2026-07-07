# Task board

Current-milestone task board. One owner-agent each; check off in the **same
commit** as the work (PRINCIPLES.md #16). Completed milestones' boards are
condensed to a single line once done.

## M0 — scaffolding — **done** (commit 0d81e34, pushed, CI green)

Green, well-tracked, empty-but-real package: skeleton (`DESCRIPTION`/`NAMESPACE`/
`R/` + `abort` layer), MIT license, README/NEWS/lifecycle, spell check; the
`project/` tracking system + seed docs; `.claude/` skills + `doc-polisher` agent;
CI matrix (check/coverage/lint/pkgdown/scheduled reference-values); air formatter
(ADR-004); public repo pushed, `check()` 0/0/0. See MILESTONES M0.

## M1 — two-way random, absolute agreement — **done** (commit 77e8ab0, CI green)

`icc()` for `ICC(A,1)`/`ICC(A,k)`: glmmTMB engine, boundary-aware MC CIs,
`print`/`summary`/`format`/`tidy`/`glance`, 5 oracles, vignette. See MILESTONES M1.

## M2 — consistency variants + fixed-vs-random raters — **done** (PR #1, merged at 334a48a, CI green)

`icc()` gains `type = "consistency"` (`ICC(C,1)`/`ICC(C,k)`) and
`raters = c("random","fixed")` (fixed = balanced-data label layer, SF `ICC(3,*)`,
warns). Classed warning layer; design + SF-equivalent in print/summary; oracles
SF 0.715/0.909, `psych` ICC3/ICC3k, fixed≡random equivalence (O4). See MILESTONES M2.

## M3 — imbalanced & incomplete designs — **done** (merged via PR #2 at 11ab1b2, full CI matrix green)

Ragged subject×rater designs (missing cells). Slice 0: estimand spec + ADR-008
(arc reordered by ADR-007; vignette → M4). Slice 1: `summarize_design()` (union-find
connectedness, `k_eff` harmonic-mean divisor, replicate guard) + incomplete
random-rater path; oracle O5 (lme4 cross-engine + MCAR simulation). Slice 2: real
fixed-effect fit (`+ rater`) — Case 3 consistency + Case 3A absolute agreement with
bias-corrected θ²_r + fixed-path MC-CI; oracle O6 (balanced reduction, lme4, 95% CI
coverage). Resolves the ADR-006 debt. See MILESTONES M3.

## M4 — "Choosing an ICC" flagship vignette — **done** (merged via PR #5 at 4d4b2ba, full CI matrix green)

Teaching milestone (ADR-009; no new estimator). Slice 1: `ratings` +
`ratings_incomplete` teaching datasets; the balanced-core "Choosing an ICC"
article (four decision axes on `data(ratings)`, McGraw–Wong ↔ Shrout–Fleiss
crosswalk); a dependency-free decision-tree SVG; `test-vignette-claims.R`. Slice 2:
the worked incomplete-design section (`k_eff`, connectedness abort, fixed ≢ random
on `ratings_incomplete`); subject-vs-cluster preview → M5; pkgdown `articles:`
grouping; getting-started/advanced refreshes; README overhaul; NEWS (missing M3 +
new M4). `devtools::check()` 0/0/0, 133 tests. See MILESTONES M4.

## M4.5 — D-study projection — **in progress** (branch `m4.5-d-study`, ADR-010)

Owner: main session (Opus). Ship the deferred D-study projection before M5.

- [x] Slice 1 — projection core. Generalized estimand `divisor`
      (`resolve_divisor()`); `icc_point()` drops `k`; numeric `unit` in `icc()`
      (`ICC(A,m)` rows, no SF label); fixed-agreement projection refused (#5);
      `x$mc` stores the fit internals; `mc_components()`/`mc_interval()` factored
      out; `d_study()` + `icc_dstudy` (`print`/`tidy`/`glance`). Oracles O-DS
      (Spearman–Brown, GT dependability, `psych` at `m = n_raters`, seeded sim);
      `data-raw/oracle-d-study.R`; estimand-spec `M4.5-d-study.md`; ADR-010.
- [x] Slice 2 — reliability curve + docs. `autoplot.icc_dstudy()` (ggplot2,
      lazily registered via `zzz.R`); `plot.icc_dstudy()`; NEWS; roxygen
      (experimental); `_pkgdown` reference group; `advanced.Rmd` D-study section +
      `test-vignette-claims.R` assertion.
- [ ] Green gate: `devtools::check()` 0/0/0; full CI matrix on the PR; merge.
