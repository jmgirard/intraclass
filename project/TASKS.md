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

## M4.5 — D-study projection — **done** (merged via PR #6 at 9be03a0, full CI matrix green)

D-study projection shipped before M5 (ADR-010). Slice 1: generalized estimand
`divisor` (`resolve_divisor()`); `icc_point()` drops `k`; numeric `unit` in `icc()`
(`ICC(A,m)` rows, no SF label); fixed-agreement projection refused (#5); `x$mc`
stores the fit internals; `mc_components()`/`mc_interval()` factored out;
`d_study()` + `icc_dstudy` (`print`/`tidy`/`glance`); oracles O-DS (Spearman–Brown,
GT dependability, `psych` at `m = n_raters`, seeded sim); `data-raw/oracle-d-study.R`;
estimand-spec `M4.5-d-study.md`. Slice 2: `autoplot.icc_dstudy()` (ggplot2, lazily
registered via `zzz.R`); `plot.icc_dstudy()`; NEWS; `_pkgdown`; `advanced.Rmd`
section + claims test. `devtools::check()` 0/0/0. See MILESTONES M4.5.

## M5 — multilevel ICCs (subject- vs. cluster-level) — **planned** (DoD detailed; ADR-011)

Subject-level (within-cluster) + cluster-level (between-cluster) IRR ICCs for
subjects nested in clusters (ten Hove 2022, Design 1). Scope: raters crossed
with clusters, balanced, random raters; `cluster` selector + `unit`-style `level`
knob (both levels by default). Equations pinned from Table 3 (spec §3). Ships on
`m5-multilevel` via PR.

- [ ] **Slice 1 — subject-level (within-cluster).** `cluster` (tidy-eval, default
      `NULL`) + `level` (validated/iterated like `unit`) args; glmmTMB five-component
      Design-1 fit `~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) +
      (1|cluster:rater)` + component extraction; identifiability guards (spec §7);
      subject-level signal/error map (spec §3a; scalar `icc_point()` reused);
      `print`/`tidy`/`glance` surface `level` + `n_clusters`; oracles O-ML (lme4 +
      sim + single-level reduction). CI-green.
- [ ] **Slice 2 — cluster-level (between-cluster) + docs.** Cluster-level
      signal/error map (spec §3b: signal σ²_c, error {rater, cluster_rater}) off the
      **same fit** (no divisor change); MC-CI verified; O-ML extended to
      cluster-level. Conflated-ICC teaching contrast (Eq. 14); fill `advanced.Rmd`
      multilevel section; `choosing-an-icc.Rmd` "fifth choice" → worked example;
      `test-vignette-claims.R` invariants; NEWS; `_pkgdown`. `devtools::check()`
      0/0/0; full CI matrix green on the PR. See MILESTONES M5.
