# intraclass 0.1.0

First public release.

**intraclass** estimates interrater-reliability intraclass correlation
coefficients (ICCs) within the generalizability-theory framework. Variance
components come from a linear mixed model rather than from classical ANOVA
mean squares. A point estimate is never reported without an interval, and
`ci_method` selects which interval that is. The package requires R 4.5.0 or
newer.

## What ships

* `icc()` fits the model and reports the ICC family the design defines:
  absolute agreement or consistency (`type`), single or average (`unit`),
  random or fixed raters (`raters`), one-way or two-way (`model`). See
  *Getting started* and `?icc`.
* `d_study()` projects a fitted reliability to other numbers of raters (`m`)
  or occasions (`n_o`), with a `plot()` and `ggplot2::autoplot()` curve.
  *D-studies and within-cell replicates* gives the designs each projection
  supports and where it refuses.
* `choose_icc()` recommends which coefficient to report, explains the
  reasoning, and prints the `icc()` call to run. It gives advice only. See
  *Choosing an ICC*.
* `tidy()` and `glance()` return tidy summaries of a fit or a projection.
  `print()`, `format()`, `summary()`, `plot()` and `ggplot2::autoplot()`
  methods are provided for both classes.
* Datasets `ratings` and `ratings_incomplete`, used throughout the
  documentation.
* Eight articles: *Getting started*, *Choosing an ICC*, *Multilevel designs*,
  *Estimation engines*, *Confidence-interval methods*, *D-studies and
  within-cell replicates*, *Glossary*, and *Comparison with other packages*.

## Engines

* The default engine is **glmmTMB**, the package's only hard engine
  dependency. Selectable `engine = "lme4"` (by way of **merDeriv**),
  `engine = "lavaan"` and `engine = "brms"` live in `Suggests`, so a plain
  install fetches none of them. Which designs each engine covers, and where it
  refuses, is documented in *Estimation engines* and `?icc`.

## Confidence intervals

* `ci_method` selects the interval: `"montecarlo"` (the default),
  `"bootstrap"`, `"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`, and
  `"posterior"` under **brms**. Each method states the designs it applies to
  and aborts with a classed error elsewhere. *Confidence-interval methods*
  compares them; `?icc` gives the per-method conditions.
* Interval coverage was studied by simulation before release, and the
  limitations those studies found are documented rather than smoothed over.
  The Monte-Carlo default under-covers when the subject effects are strongly
  skewed or heavy-tailed, worst 0.6725 at chi-square(1) subject effects with a
  true ICC of 0.6, 50 subjects and 5 raters. `"burch"` is no remedy there
  (worst 0.6655).
* Which of the two closed forms gives the **narrower** interval is conditional.
  On both grids that vary only the subject effect, `"burch"` is the narrower of
  the two in 16 of 16 cells of the smaller grid and 59 of 64 cells of the larger grid.
* That width margin holds much the same up to a true ICC of 0.3 rather than shrinking as the true ICC rises (on the larger grid; the smaller grid's margin does shrink across its levels). The `"burch"` width advantage then collapses to near parity at a true ICC of 0.6, on the one grid reaching that value. It also shrinks steadily as the subject count grows, measured at 5 raters.
* What `"burch"` does against `"searle"` also depends on the residual, and the three grids measure that: the two grids that vary only the subject effect put it narrower nearly everywhere, while the third, which draws the residual from the same family as the subject effect, puts it wider at every symmetric heavy-tailed family measured (a median width ratio of 1.2963 at t(5) with 100 subjects) and narrower at every lighter-tailed one, the normal included.
* The `ci_method = "mpl"` documentation states the interpolation evidence behind
  off-node subject counts. The correction constant is calibrated at subject-count
  nodes and linearly interpolated between them. The interpolated path is
  coverage-validated at each supported confidence level, at the default 0.95 by
  three off-node cells, each clearing its pre-registered coverage floor. The
  documentation also says what that validation does not establish (interpolated
  values are validated at a handful of geometries, not calibrated, and the
  interval's asymmetry direction is not uniform across rater counts). Every
  universal or negative claim this documentation makes about the validated cells
  is settled mechanically, in CI, against the committed coverage fixture
  (`data-raw/check-mpl-doc-claims.py`).

## When a call fails

* Errors are classed and name the quantities that failed the check, rather
  than asserting a cause. Where an interval method aborts on degenerate data,
  the error names another `ci_method` only after running it on your data and
  confirming it returns a usable interval.
