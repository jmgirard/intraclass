# Changelog

## intraclass 0.1.0

First public release. **intraclass** estimates interrater-reliability
intraclass correlation coefficients (ICCs) within the
generalizability-theory framework using modern mixed-model
variance-component estimation (rather than the classical ANOVA
mean-squares approach), with boundary-aware Monte-Carlo confidence
intervals and guidance on choosing the right coefficient. Every
estimator is verified against independent oracles — published worked
examples, `psych`/ANOVA cross-checks, alternate engines, and seeded
simulations.

### Estimating ICCs

- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  computes the full interrater-reliability ICC family from a linear
  mixed model: absolute agreement vs. consistency (`type`), single
  vs. average (`unit`), random vs. fixed raters (`raters`), and one-way
  vs. two-way (`model`) designs — the classic Shrout & Fleiss / McGraw &
  Wong coefficients — each reported with a boundary-aware Monte-Carlo
  confidence interval and its Shrout & Fleiss equivalent.
- Imbalanced and **incomplete** (missing-cell) designs are handled
  directly by the mixed model: it uses the effective number of ratings
  `k_eff` (the harmonic mean of the per-subject counts) as the
  `ICC(*,k)` divisor and aborts loudly on a disconnected, unidentified
  design.
- **Multilevel** ICCs for subjects nested in clusters — pupils in
  classrooms, patients in clinics — following ten Hove, Jorgensen & van
  der Ark (2022). Supply a `cluster` column to get subject-level
  (within-cluster) and cluster-level (between-cluster) coefficients via
  `level`. Covers raters crossed with clusters (Design 1) or nested in
  clusters/subjects (Designs 2–3), complete or incomplete crossed data,
  and fixed raters at the subject level.

### Engines

- Default **glmmTMB** engine (boundary-robust REML), with a selectable
  `engine = "lme4"` (via `merDeriv`) that covers every design glmmTMB
  does — two-way random and fixed raters, one-way, and the multilevel
  designs (crossed and nested) at both levels — on complete, balanced
  data, agreeing with glmmTMB on both the point estimate and the
  Monte-Carlo interval. A selectable `engine = "lavaan"` — an SEM
  common-factor generalizability model (Jorgensen 2021) whose
  absolute-agreement coefficient uses the indicator-mean rater-variance
  estimator — covers the random two-way design. Optional engines live in
  `Suggests`, so the base install stays light.

### Choosing, projecting, and visualizing

- [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  — an interactive and programmatic decision helper that recommends
  which ICC to report, explains each choice, and emits the exact
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
  to run. It gives advice only; it does not fit.
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  — projects a fitted ICC’s reliability to the mean of an arbitrary
  number of raters (a generalizability decision study), with an
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  reliability curve;
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)’s
  `unit` also accepts numbers for one-off projections.
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  / [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  `icc` objects draw a coefficient forest plot and a variance-component
  decomposition;
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) /
  [`glance()`](https://generics.r-lib.org/reference/glance.html) give
  tidy summaries. Plotting needs `ggplot2` (a `Suggests` dependency).

### Data and documentation

- Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout
  the docs.
- Vignettes: *Getting started*, *Choosing an ICC* (the decision
  framework, with a decision-tree diagram), and *Advanced* (incomplete
  and multilevel designs, the estimation engines, the plots, and
  [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)).
