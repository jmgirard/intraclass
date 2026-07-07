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
- `autoplot()` / `ggplot2` methods for variance-component and CI visualization
  (the reliability-curve case shipped for `d_study()` in M4.5; general
  variance-component / CI plots remain open).
- Design/power helpers (how many raters/subjects for a target CI width).
- Categorical/ordinal ratings (GLMM engines) beyond the Gaussian LMM.
- Bootstrap and profile-likelihood CIs as alternatives to Monte-Carlo, for
  method comparison.
- A `choose_icc()` interactive decision helper mirroring the flagship vignette.
- Benchmark suite vs. `psych`/`gtheory`/`irrICC` across designs.
- One-way random ICC(1)/ICC(1,k) via the **SEM (lavaan) engine** — deferred out of
  M7 (ADR-014). The SEM-GT literature (Jorgensen 2021; Vispoel et al. 2022; Lee &
  Vispoel 2024) covers crossed facet designs only; a wide-column parallel model
  gives consistency (not one-way), and an equal-intercept approximation is unsourced
  and inexact (0.157 vs 0.166 on SF). Needs a sourced method (or a multilevel/
  random-intercept SEM, which would just re-implement the mixed-model engines)
  before it ships.

## Proposals under discussion (open design questions)

These are **decision points, not decided directions** — recorded so the design
is deliberate when scheduled. Resolve the chosen shape at the milestone's start.

*None open right now.* (Resolved proposals are recorded as ADRs and move to
[`MILESTONES.md`](MILESTONES.md) when scheduled.)

### Resolved

- **D-study projection — reliability at an arbitrary number of raters *m*.**
  Scheduled and shipped as **M4.5** (its own slice before M5). The chosen shape was
  all three exposures together: numeric `unit` in `icc()` (`ICC(A,m)` rows) as sugar
  for one-off *m*, a downstream `d_study(x, m = …)` table reusing the stored fit (no
  refit), and an `autoplot()`/`plot()` reliability curve. Rationale, the
  fixed-rater-agreement refusal, and the oracle set (O-DS: Spearman–Brown, GT
  dependability, `psych` at `m = n_raters`, seeded sim) are in **ADR-010** and
  [`estimand-specs/M4.5-d-study.md`](estimand-specs/M4.5-d-study.md). Subject-count
  projection remains parked (M4.5 spec §6).
- **One-way random ICC(1)/ICC(1,k) (raters not crossed).** Promoted from this
  parking lot to **M6** (the next milestone) by **ADR-013** — the last member of the
  classic Shrout–Fleiss family, with its oracle already staged in `sf_oracle_all`
  (0.166 / 0.443). Detail its DoD + estimand-spec at milestone start.
- **Multilevel & incomplete-design extensions.** The M5 spec §8 deferrals (Designs
  2/3, incomplete multilevel, fixed-rater multilevel) plus lme4 for the
  fixed/multilevel fits are grouped into **M8** by **ADR-013**. Not detailed until
  that milestone starts.
- **Optional engines — SEM leads over Bayesian.** **M7** was detailed by **ADR-014**:
  it ships the **SEM/lavaan** engine first (two-way + one-way random), because lavaan
  reuses the existing Monte-Carlo CI path (no new `ci_method`), installs light (no
  Stan compilation), and is pinnable to a textbook oracle (Jorgensen 2021, which also
  argues for MC CIs). The **Bayesian** backend (rstanarm preferred over brms; a new
  `ci_method = "posterior"` for credible intervals; half-*t* hyperpriors, ten Hove et
  al. 2020) and incomplete/fixed/multilevel SEM are **deferred** to a later slice or
  follow-on milestone — scheduled at that point, not pre-designed here.
