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
  - [x] Full CI matrix confirmed green on PR #1 (all 9 checks); merged to `main`.
- Deferred to their own slices (not M2): lme4 as a *selectable* engine + bootstrap
  CI (supersedes ADR-005's "defer to M2"); D-study projection to arbitrary k.
- Status: done (merged to `main` via PR #1 at 334a48a; full CI matrix green)

## M3: Imbalanced & incomplete designs
- Goal: correct ICCs from the mixed model on **ragged** subject×rater designs
  (missing cells) — the package's core differentiator vs. ANOVA/balanced-only
  tools. **Statistical core only:** the flagship "Choosing an ICC" vignette is
  promoted to its own milestone (M4 below) so it can demonstrate the
  complete-vs-incomplete decision on working code (ADR-007). Resolves the ADR-006
  fixed-raters debt with a **real fixed-effect fit path**.
- Estimand: see [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md)
  (to be written first, PRINCIPLES.md #2). Builds on M1/M2; the fit already handles
  imbalance, so the additions are identifiability guards, the fixed-effect fit path
  + its CI variant, the `ICC(*,k)` divisor rule under imbalance, and unbalanced-data
  oracles.
- Definition of Done (per-estimator bar, §8) — two internal slices, each CI-green:
  - [ ] **Slice 1 — incomplete random raters (default path).** Connectedness /
        identifiability guard (`abort_unidentified()` on a disconnected
        subject–rater graph, PRINCIPLES.md #5); balance detection; `unit`
        divisor rule per the spec; `ICC(*,1)` always well-posed. `mc_ci()`
        unchanged for the random path.
  - [ ] **Slice 2 — real fixed-effect fit path** (`score ~ 1 + rater +
        (1 | subject)`) for `raters = "fixed"`, returning correct (and genuinely
        different) estimates on incomplete data; agreement error set gains the
        rater fixed-effect spread (McGraw–Wong Case 3A); a fixed-path MC-CI sampler.
        Balanced data still reduces to the M2 numbers (extends O4). `raters` roxygen
        note corrected (no longer claims random≡fixed unconditionally).
  - [ ] Oracles per path — ≥2 independent types: seeded unbalanced simulation
        (primary), lme4 cross-check, `irrNA`/`gtheory` on incomplete data, and the
        balanced-reduction regression (full SF data still returns
        0.290/0.620/0.715/0.909). New `REFERENCES.md` oracle rows. **Stop and
        recommend (not auto-run) a Fable review if any coefficient can't be pinned
        by ≥2 oracles** (PRINCIPLES.md #19).
  - [ ] `print`/`summary`/`glance` surface balanced-vs-incomplete, n_obs/n_cells,
        and (if incomplete) the divisor convention; snapshots updated.
  - [ ] Roxygen "which ICC / when" extended to complete-vs-incomplete and the fixed
        real-fit; `DECISIONS.md` ADR-008 (fixed real-fit path + divisor convention);
        `devtools::check()` 0/0/0 locally; full CI matrix green.
- Deferred out of M3 (recorded so they aren't rediscovered): the flagship vignette
  (M4); replicate ratings within a cell; one-way designs; lme4 as a *selectable*
  engine; D-study projection API (ROADMAP).
- Status: in progress (arc reordered by ADR-007; estimand spec + ADR-008 done,
  Slice 0; Slices 1–2 pending)

## M4: "Choosing an ICC" flagship vignette *(provisional)*
- Goal: the decision-framework teaching article (agreement vs. consistency, single
  vs. average, fixed vs. random, complete vs. incomplete), demonstrated on the M3
  code; optionally the `choose_icc()` decision helper (ROADMAP). Split out of the
  old M3 by ADR-007.
- Status: provisional

## M5: Multilevel ICCs *(provisional)*
- Goal: subject-level vs. cluster-level ICCs (ten Hove 2021). *(was M4)*
- Status: provisional

## M6: Optional engines behind `Suggests` *(provisional)*
- Goal: Bayesian (`brms`/`rstanarm`) and/or SEM (`lavaan`) backends behind a
  shared interface, gated by `rlang::check_installed()`. *(was M5)*
- Status: provisional

## M7: Release polish *(provisional)*
- Goal: pkgdown site, advanced vignette, CRAN submission prep. *(was M6)*
- Status: provisional
