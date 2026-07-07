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

## M5 — multilevel ICCs (subject- vs. cluster-level) — **done** (merged via PR #8 at 87b4588, full CI matrix green)

Multilevel ICCs for subjects nested in clusters (ten Hove et al. 2022, Design 1;
ADR-011). Slice 1 (estimator, `0089d9a`): `icc()` `cluster` selector + `unit`-style
`level` knob; `fit_glmmtmb_multilevel()` five-component fit; subject- and
cluster-level signal/error maps off one fit (scalar `icc_point()` unchanged);
identifiability guards; `print`/`tidy`/`glance` surface `level`/`n_clusters`;
`d_study()` aborts on multilevel; oracles O-ML (lme4 <1e-4, seeded recovery + MC
coverage, single-level reduction). Slice 2 (docs): advanced.Rmd multilevel section,
choosing-an-icc.Rmd citation fix, NEWS, roxygen, vignette-claims invariant. Also the
citation audit (ADR-002/003 → ten Hove 2025). `devtools::check()` 0/0/0, 188 tests.
See MILESTONES M5.

## M5.5 — lme4 as a selectable engine — **done** (merged via PR #9 at edd9d88, full CI matrix green)

Promote lme4 from oracle-only to a selectable `engine = "lme4"` for the random
two-way path — the pre-M6 interface slice (resolves the ADR-005 deferral, builds the
engine × design dispatch seam). `fit_lme4()` returns the shared six-field contract on
a boundary-safe (log-SD) scale; MC `vcov` via **merDeriv** (delta-transformed);
singular fit aborts `intraclass_singular_fit`. Oracles O-LME (point ≡ glmmTMB ≤1e-4;
interval ≈ ≤9.4e-3; boundary; seeded-sim coverage). ADR-012. See MILESTONES M5.5.

## M6 — one-way random ICC(1)/ICC(k) — **done** (merged via PR #10 at eb7102d, full CI matrix green)

Last member of the classic SF family (Case 1): `model = "oneway"` fits
`score ~ 1 + (1 | subject)` (no rater term) → `ICC(1)`/`ICC(1,k)` (+ numeric-unit
`ICC(m)`). First milestone to change the fitted model. `fit_glmmtmb_oneway()` +
`fit_lme4_oneway()` (six-field contract, no rater); `icc_point`/`resolve_divisor`/
`mc_ci` reused; rater identity ignored (defines `k`); `type` n/a, `fixed`/`cluster`
abort. Oracles O-OW (SF 0.166/0.443; `psych` ICC1/ICC1k; one-way ANOVA; glmmTMB↔lme4;
seeded sim). Estimand-spec `M6-oneway.md`; choosing-an-icc "are the raters crossed?"
section. `devtools::check()` 0/0/0, tests 247/0/0. See MILESTONES M6.

---

## M7 — SEM engine (lavaan) — **planning done** (scope fixed by ADR-014; Slice 1 next)

Promote lavaan (SEM / common-factor GT) to a selectable `engine = "lavaan"` for the
two-way and one-way random paths — the "optional engines" milestone, SEM first
(Bayesian deferred, ADR-014). No new estimand, no estimand-spec (engine for existing
estimands). Two CI-green slices. See MILESTONES M7.

### Slice 1 — lavaan two-way random
- [ ] `R/engine-lavaan.R::fit_lavaan()` — reshape long → wide; one-factor SEM
      (consistency σ²_s/(σ²_s+σ²_res); absolute agreement + rater-intercept
      mean-structure spread, Jorgensen 2021); returns the shared six-field contract.
- [ ] `vcov(fit)` feeds the existing `montecarlo` path (no new `ci_method`);
      `to_components` boundary-safe at zero-variance/Heywood (#3), boundary oracle;
      Heywood/singular fit aborts loudly (classed → glmmTMB).
- [ ] Dispatch seam gains lavaan × {twoway} rows; `check_installed("lavaan")`;
      lavaan → `Suggests`; guards `raters="fixed"`/`cluster`/incomplete + lavaan →
      `abort_unsupported()` (deferred, recorded).
- [ ] Oracles O-SEM: Jorgensen worked example; point ≡ glmmTMB on `ratings` (≤1e-3);
      `psych` ICC2/ICC3; **interval** ≈ glmmTMB MC CI (absolute gap); seeded sim.
      `data-raw/oracle-sem.R`; `test-icc-lavaan.R`.

### Slice 2 — lavaan one-way random + docs
- [ ] `model = "oneway"` + lavaan: parallel one-factor model over k exchangeable
      columns → `ICC(1)`/`ICC(1,k)` (+ numeric-unit `ICC(m)` free via
      `resolve_divisor()`). Oracles: SF 0.166/0.443 + `psych` ICC1/ICC1k +
      cross-engine + sim.
- [ ] `print`/`glance` surface `engine = "lavaan"` + snapshot; roxygen `@param
      engine` adds lavaan; NEWS; `advanced.Rmd` SEM-engine section + claims-test
      line; REFERENCES O-SEM + Jorgensen 2021 + lavaan rows.
- [ ] `devtools::check()` 0/0/0; `air`/`lintr` clean; full CI matrix on the PR
      (`m7-sem-engine`).
