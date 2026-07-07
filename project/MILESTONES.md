# Milestones

Ordered milestones with Definition of Done and status. **M1 is fully specified;
M2–M6 are provisional** one-liners, detailed only at the start of their milestone
after a short retro on the previous one (founding brief §7). The arc is a
hypothesis, not a contract — reorders get a [`DECISIONS.md`](DECISIONS.md) entry.

Definition of Done references are to `CLAUDE_CODE_KICKOFF.md` §8.

---

## M0: Scaffolding
- Goal: A green, well-tracked, empty-but-real package that others can build on.
- Definition of Done:
  - [x] Package skeleton (`DESCRIPTION`, `NAMESPACE`, `R/`, license, README, NEWS).
  - [x] `project/` tracking system populated (this file + siblings).
  - [x] `.claude/` skills (`status`, `start-task`, `finish-task`, `verify-estimator`,
        `new-estimator`, `add-decision`) and the `doc-polisher` (Sonnet) agent.
  - [x] CI workflows (R-CMD-check matrix, coverage, lint, pkgdown, scheduled
        reference-values) + pkgdown config; stub site builds.
  - [x] Lean `CLAUDE.md` pointing at `project/` and the routing policy.
  - [x] `devtools::check()` clean (0 errors / 0 warnings; notes justified).
  - [x] Public `jmgirard/intraclass` repo created; first push; CI green.
  - [x] air formatter + CI format check (ADR-004).
- Status: done (commit 0d81e34) — pending maintainer sign-off

## M1: Two-way random, absolute agreement — `ICC(A,1)` / `ICC(A,k)`
- Goal: One estimator working end-to-end (fit → estimate → MC CI → print/tidy →
  tested → documented → CI green), proving the whole pipeline before widening.
- Estimand: see [`estimand-specs/M1-twoway-random-agreement.md`](estimand-specs/M1-twoway-random-agreement.md).
  ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_res); ICC(A,k) = σ²_s / (σ²_s + (σ²_r + σ²_res)/k).
- Definition of Done (per-estimator bar, §8):
  - [x] Public `icc()` API per the seed test signature; classed `icc` object.
  - [x] glmmTMB engine (only selectable engine in M1); lme4 oracle-only (ADR-005).
  - [x] Boundary-aware Monte-Carlo CIs from `vcov(fit, full = TRUE)` (ADR-003).
  - [x] `print` / `summary` / `format` / `tidy` / `glance` methods.
  - [x] Oracle tests — ≥2 independent types, actually 5:
        (a) Shrout & Fleiss (1979) worked values ICC(A,1)=0.290, ICC(A,k)=0.620;
        (b) `psych::ICC` on the balanced case to 1e-4;
        (c) package-independent ANOVA mean-squares (base `aov`);
        (d) seeded simulation with known population variance components;
        (e) lme4-vs-glmmTMB cross-check.
  - [x] Boundary/error-path tests; `cli` messaging + classed errors; print snapshot.
  - [x] Roxygen "which ICC / when" note incl. the single-rating identifiability caveat.
  - [x] *Getting started* vignette knits.
  - [x] `REFERENCES.md` + `DECISIONS.md` updated; coverage 94% (statistical paths
        100%); `devtools::check()` 0/0/0 locally. Full CI matrix confirmed on push.
- Status: done (local) — pending push + maintainer sign-off

## M2: Consistency variants + fixed-vs-random raters *(provisional)*
- Goal: `ICC(C,1)`/`ICC(C,k)`; fixed vs. random rater handling; generalize the
  estimand/selection abstraction (signal, error set, divisor).
- Status: provisional

## M3: Imbalanced & incomplete designs *(provisional)*
- Goal: missing rater×subject cells; the flagship "Choosing an ICC" vignette.
- Status: provisional

## M4: Multilevel ICCs *(provisional)*
- Goal: subject-level vs. cluster-level ICCs (ten Hove 2021).
- Status: provisional

## M5: Optional engines behind `Suggests` *(provisional)*
- Goal: Bayesian (`brms`/`rstanarm`) and/or SEM (`lavaan`) backends behind a
  shared interface, gated by `rlang::check_installed()`.
- Status: provisional

## M6: Release polish *(provisional)*
- Goal: pkgdown site, advanced vignette, CRAN submission prep.
- Status: provisional
