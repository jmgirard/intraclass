# Roadmap

Long-range vision and a parking lot for out-of-scope ideas. Nothing here is
scheduled; scheduling happens by promoting an item into
[`MILESTONES.md`](MILESTONES.md). Keeps PRINCIPLES.md #17 (no scope creep)
honest: new ideas land here, not in the current milestone.

## Vision

A coherent, well-tested R package that (1) fits variance components with modern
engines, (2) computes the *correct* ICC for a stated design with proper interval
estimation, (3) handles imbalanced / incomplete / multilevel designs, and (4)
teaches the user which ICC to choose and why. The package **and its pkgdown site**
are a first-class place to learn ICC best practices — every estimator's docs and
every vignette explains the estimand, assumptions, and tradeoffs behind each knob.

The differentiator vs. prior art: classical tools (`psych`, `irr`, `irrNA`,
`irrICC`, `ICCDesign`) are ANOVA/mean-squares based and mostly assume balanced
data; model-based tools (`performance::icc`, `gtheory`, `misty`) extract a
variance-partition coefficient but not the full interrater-reliability ICC family,
the error-variance framing, or a selection framework. This package fills that gap
with mixed-model estimation and Monte-Carlo CIs (ten Hove, Jorgensen & van der
Ark).

## Parking lot (unscheduled proposals)

- Replicate ratings within cell → split σ²_sr from σ²_e via `(1 | subject:rater)`.
- Design/power helpers (how many raters/subjects for a target CI width).
- Categorical/ordinal ratings (GLMM engines) beyond the Gaussian LMM.
- Bootstrap and profile-likelihood CIs as alternatives to Monte-Carlo, for
  method comparison. Includes the **parametric-bootstrap `ci_method`** (bootMer)
  deferred out of M14/M15.
- Benchmark suite vs. `psych`/`gtheory`/`irrICC` across designs.
- **Three-facet `d_study()`** projecting subject-per-cluster counts for the
  multilevel designs (today's `d_study()` projects rater count only) — deferred
  repeatedly out of M5/M8/M9/M14/M15.
- **Conflated single-level ICC (Eq. 14, ten Hove et al. 2022)** exposed as a
  selectable coefficient — the single-number summary that collapses the
  multilevel variance partition; deferred out of M5/M8/M9/M14/M15.
- **lme4 engine edge cases** beyond the shipped M14/M15 parity: a boundary-robust
  lme4 interval for singular fits (glmmTMB covers this today via the
  degrade-to-glmmTMB handoff), and merDeriv edge cases beyond the currently fitted
  models.
- One-way random ICC(1)/ICC(1,k) via the **SEM (lavaan) engine** — deferred out of
  M7 (ADR-014). The SEM-GT literature (Jorgensen 2021; Vispoel et al. 2022; Lee &
  Vispoel 2024) covers crossed facet designs only; a wide-column parallel model
  gives consistency (not one-way), and an equal-intercept approximation is unsourced
  and inexact (0.157 vs 0.166 on SF). Needs a sourced method (or a multilevel/
  random-intercept SEM, which would just re-implement the mixed-model engines)
  before it ships.
- **Bayesian engine** (`brms`/`rstanarm`) behind `Suggests`, with a new
  `ci_method = "posterior"` (credible intervals from native posterior draws) and
  half-*t* hyperpriors (ten Hove, Jorgensen & van der Ark 2020). Deferred out of M7
  (ADR-014); `rstanarm` preferred over `brms` for CI-install sanity (precompiled
  Stan, no toolchain). The engine × design dispatch seam (M5.5/M7) is ready for it.

## Proposals under discussion (open design questions)

These are **decision points, not decided directions** — recorded so the design
is deliberate when scheduled. Resolve the chosen shape at the milestone's start.

*None open right now.* (This file is **future-only**, ADR-015: once a proposal is
scheduled it moves to [`MILESTONES.md`](MILESTONES.md); once shipped its entry here
is removed — shipped work lives in `MILESTONES.md`, not re-narrated here.)
