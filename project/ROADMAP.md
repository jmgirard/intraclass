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

- One-way random ICC(1)/ICC(k) (raters not crossed).
- Replicate ratings within cell → split σ²_sr from σ²_e via `(1 | subject:rater)`.
- `autoplot()` / `ggplot2` methods for variance-component and CI visualization.
- Design/power helpers (how many raters/subjects for a target CI width).
- Categorical/ordinal ratings (GLMM engines) beyond the Gaussian LMM.
- Bootstrap and profile-likelihood CIs as alternatives to Monte-Carlo, for
  method comparison.
- A `choose_icc()` interactive decision helper mirroring the flagship vignette.
- Benchmark suite vs. `psych`/`gtheory`/`irrICC` across designs.
