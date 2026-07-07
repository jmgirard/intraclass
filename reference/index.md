# Package index

## Choosing a coefficient

An interactive decision helper that recommends which ICC to report and
emits the exact
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
that computes it — no fitting, teaching-first.

- [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  [`format(`*`<icc_recommendation>`*`)`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  [`print(`*`<icc_recommendation>`*`)`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  : Recommend an ICC and the call that computes it

## Estimating an ICC

The workhorse. Fit variance components with a modern mixed model and
compute the intraclass correlation for a stated design: absolute
agreement vs. consistency, single vs. average, fixed vs. random raters,
one-way vs. two-way, multilevel (subject vs. cluster level, crossed or
nested), and incomplete (ragged) data — all with boundary-aware
Monte-Carlo confidence intervals. The
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
`autoplot()` (coefficient forest / variance-component decomposition) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods are
documented on this page.

- [`autoplot.icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`plot(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`format(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`print(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`summary(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`tidy(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`glance(`*`<icc>`*`)`](https://jmgirard.github.io/intraclass/reference/icc.md)
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) :
  Intraclass correlation coefficient for a two-way design

## Decision (D-) studies

Project a fitted ICC’s reliability to other numbers of raters and plot
the curve, plus its
[`tidy()`](https://generics.r-lib.org/reference/tidy.html)/[`glance()`](https://generics.r-lib.org/reference/glance.html)/`autoplot()`/[`plot()`](https://rdrr.io/r/graphics/plot.default.html)
methods.

- [`autoplot.icc_dstudy()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`plot(`*`<icc_dstudy>`*`)`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`format(`*`<icc_dstudy>`*`)`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`print(`*`<icc_dstudy>`*`)`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`tidy(`*`<icc_dstudy>`*`)`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  [`glance(`*`<icc_dstudy>`*`)`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  **\[experimental\]** : Project reliability to other numbers of raters
  (a D-study)

## Tidy methods

Broom generics re-exported so
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`glance()`](https://generics.r-lib.org/reference/glance.html) resolve
without attaching the generics package.

- [`reexports`](https://jmgirard.github.io/intraclass/reference/reexports.md)
  [`tidy`](https://jmgirard.github.io/intraclass/reference/reexports.md)
  [`glance`](https://jmgirard.github.io/intraclass/reference/reexports.md)
  : Objects exported from other packages

## Datasets

Worked rater-reliability examples used across the docs and vignettes.

- [`ratings`](https://jmgirard.github.io/intraclass/reference/ratings.md)
  : Rater reliability example (Shrout & Fleiss, 1979)
- [`ratings_incomplete`](https://jmgirard.github.io/intraclass/reference/ratings_incomplete.md)
  : Rater reliability example with missing cells

## Package overview

- [`intraclass`](https://jmgirard.github.io/intraclass/reference/intraclass-package.md)
  [`intraclass-package`](https://jmgirard.github.io/intraclass/reference/intraclass-package.md)
  : intraclass: Modern Intraclass Correlation Coefficients
