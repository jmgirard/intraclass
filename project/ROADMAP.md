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

## Proposals under discussion (open design questions)

These are **decision points, not decided directions** — recorded so the design
is deliberate when scheduled. Resolve the chosen shape at the milestone's start.

### D-study projection — reliability at an arbitrary number of raters *k*

**Motivation.** In generalizability theory a D-study projects the coefficient to a
number of raters *m* other than the number observed. The absolute-agreement ICC is
already the dependability coefficient Φ, and Φ(*m*) =
σ²_s / (σ²_s + (σ²_r + σ²_res)/*m*), so this is a change of the averaging divisor
in the existing `(signal, {error set}, divisor)` representation — not new
machinery. The Monte-Carlo CI handles any *m* naturally (recompute Φ(*m*) per
draw), which is an advantage over the delta method and honestly widens the
interval when σ²_r is estimated from few raters. Candidate home: M2 (where the
estimand abstraction generalizes) or a small dedicated milestone.

**Open design question — how to expose it.** At least three shapes, not mutually
exclusive:

1. **Numeric `unit` in `icc()`.** Let `unit` accept numbers, so `"single"` ≡ 1,
   `"average"` ≡ observed count, and `unit = c("single", 3, 10)` adds `ICC(A,3)`,
   `ICC(A,10)` rows. Inline, minimal surface; good for a few specific *m*.
2. **A downstream function you pipe an `icc` result into** — e.g.
   `project_raters(fit, k = 1:20)` / `d_study(fit, ...)` — returning a tidy table
   of Φ(*k*) with CIs across a *range* of *k*. Better for scanning many *k* and
   keeps `icc()`'s surface small; reuses the stored fit/covariance so no refit.
3. **A reliability-curve plot** — an `autoplot()`/`plot()` (or the piped
   function's companion) drawing Φ(*k*) with a CI band vs. *k*: the classic
   D-study curve for "how many raters do I need?".

Leaning: (2) + (3) together read most naturally (a projection *is* a separate
question from "what is my ICC"), with (1) as optional sugar for one-off *m*. But
this is explicitly unresolved.

**Must-haves when built (whichever shape).** An analytic oracle via the
Spearman–Brown / GT relationship to `ICC(A,1)` (PRINCIPLES.md #1); a teaching note
that projection is extrapolation whose trust depends on how well σ²_r is estimated
(few raters ⇒ wide, honest intervals); integer-*k* guidance. Relates to the
existing "design/power helpers" and `autoplot()` parking-lot items.
