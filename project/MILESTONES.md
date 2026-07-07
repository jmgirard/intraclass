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
- Status: done (commit 0d81e34, pushed, CI green)

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
- Status: done (code at 77e8ab0, pushed, full CI matrix green; marked done in 37f59c0)

## M2: Consistency variants + fixed-vs-random raters
- Goal: add `ICC(C,1)`/`ICC(C,k)` and a `raters = random|fixed` interpretation
  dimension, generalizing the estimand abstraction — **no new fit, no new CI
  machinery**. Balanced/complete data only (incomplete designs are M3).
- Estimand: see [`estimand-specs/M2-consistency-and-fixed.md`](estimand-specs/M2-consistency-and-fixed.md).
  Consistency drops the rater main effect from the error set:
  ICC(C,1) = σ²_s / (σ²_s + σ²_res); ICC(C,k) = σ²_s / (σ²_s + σ²_res / k).
  Fixed vs. random raters is a **label/interpretation layer** over the shared
  random-effects fit — verified numerically identical on balanced data (ADR-006).
- Definition of Done (per-estimator bar, §8):
  - [x] `type = "consistency"` unlocked → `ICC(C,1)`/`ICC(C,k)`; `unit` unchanged.
  - [x] New public arg `raters = c("random", "fixed")` (default `"random"`);
        `"fixed"` opt-in, returns valid estimates via the shared fit.
  - [x] Estimand abstraction generalized: consistency error set {residual} + a
        `raters`/design dimension used for labeling only. `icc_point()`/`mc_ci()`
        unchanged (consistency omits the rater draw per the existing error set).
  - [x] Classed warning layer (`warn_intraclass()`, PRINCIPLES.md #8) + a loud
        `intraclass_fixed_raters` best-practice warning when `raters = "fixed"`.
  - [x] `print`/`summary`/`format` surface the design (two-way random vs mixed)
        and the Shrout–Fleiss equivalent (ICC(2,·) vs ICC(3,·)); snapshots updated.
  - [x] Boundary-aware Monte-Carlo CIs verified for consistency (rater term absent
        per draw); `raters="fixed"` CI equals `raters="random"` CI (balanced).
  - [x] Oracle tests — ≥2 independent types (5, per M1):
        (a) Shrout & Fleiss ICC(C,1)=0.715, ICC(C,k)=0.909;
        (b) `psych::ICC` ICC3/ICC3k on balanced data to 1e-4;
        (c) package-independent ANOVA mean-squares (existing helper);
        (d) lme4 cross-check;
        (e) fixed≡random point/CI equivalence on balanced data (encodes ADR-006).
  - [x] Warning-path tests: `expect_warning(class="intraclass_fixed_raters")` for
        `"fixed"`; `"random"` silent; warning-text snapshot.
  - [x] Roxygen "which ICC / when" extended to consistency and fixed-vs-random,
        stating random is recommended and fixed forgoes generalization; *Getting
        started* vignette gains a consistency-vs-agreement note.
  - [x] `REFERENCES.md` (O1 rows C1/Ck promoted to asserted; new O4 fixed≡random
        oracle) + `DECISIONS.md` (ADR-006) updated; coverage 94.8% (statistical
        paths 100%); `devtools::check()` 0/0/0 locally.
  - [ ] Full CI matrix confirmed green on push (PR).
- Deferred to their own slices (not M2): lme4 as a *selectable* engine + bootstrap
  CI (supersedes ADR-005's "defer to M2"); D-study projection to arbitrary k.
- Status: done (local; all gates green) — pending push + CI

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
