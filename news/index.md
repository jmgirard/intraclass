# Changelog

## intraclass 0.1.0

First public release.

**intraclass** estimates interrater-reliability intraclass correlation
coefficients (ICCs) within the generalizability-theory framework.
Variance components come from a linear mixed model rather than from
classical ANOVA mean squares. A point estimate is never reported without
an interval, and `ci_method` selects which interval that is. The package
requires R 4.5.0 or newer.

### What ships

- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
  the model and reports the ICC family the design defines: absolute
  agreement or consistency (`type`), single or average (`unit`), random
  or fixed raters (`raters`), one-way or two-way (`model`). See *Getting
  started* and
  [`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md).
- Data need not form a complete, balanced grid. There is support for
  imbalanced, incomplete, and multilevel (nested) designs: unequal
  ratings per subject, missing ratings, and subjects nested in a
  higher-level unit such as a classroom or clinic. A `cluster` column on
  a two-way design switches on the multilevel ICC, adding a cluster
  level when the same raters span every cluster. See *Multilevel
  designs: subject and cluster level* and
  [`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md) for
  the layouts and where it refuses.
- Rating a subject-by-rater cell more than once gives a within-cell
  replicate design. On a two-way random design
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  splits the single-rating residual into a subject-by-rater interaction
  and pure error, and `occasions` reports the reliability of one rating
  or, on balanced replicates, of the mean. See *D-studies and
  within-cell replicates* and
  [`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md) for
  the designs replicates support and where they refuse.
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  projects a fitted reliability to other numbers of raters (`m`) or
  occasions (`n_o`), with a
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and
  [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  curve. *D-studies and within-cell replicates* gives the designs each
  projection supports and where it refuses.
- [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  recommends which coefficient to report, explains the reasoning, and
  prints the
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
  to run. It gives advice only. See *Choosing an ICC*.
- [`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
  [`glance()`](https://generics.r-lib.org/reference/glance.html) return
  tidy summaries of a fit or a projection.
  [`print()`](https://rdrr.io/r/base/print.html),
  [`format()`](https://rdrr.io/r/base/format.html),
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and
  [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods are provided for both classes, and
  [`summary()`](https://rdrr.io/r/base/summary.html) for an
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fit.
  `ggplot2` is a `Suggests` dependency.
- Datasets `ratings` and `ratings_incomplete`, used throughout the
  documentation.
- Eight articles: *Getting started*, *Choosing an ICC*, *Multilevel
  designs: subject and cluster level*, *Estimation engines*,
  *Confidence-interval methods*, *D-studies and within-cell replicates*,
  *Glossary*, and *Comparison with other packages*.

### Engines

- The default engine is **glmmTMB**, the package’s only hard engine
  dependency. `engine = "lme4"`, `engine = "lavaan"` and
  `engine = "brms"` are selectable. Which designs each engine covers,
  and where it refuses, is documented in *Estimation engines* and
  [`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md).
- The `lme4` package itself is already on your library path after a
  plain install, because `glmmTMB` lists it in its own `Imports`, but
  the lme4 engine also needs **merDeriv**, which does not arrive.
  `merDeriv`, `lavaan` and `brms` sit in this package’s `Suggests`, and
  a plain install fetches none of the three.

### Confidence intervals

- `ci_method` selects the interval: `"montecarlo"` (the default),
  `"bootstrap"`, `"npbootstrap"`, `"searle"`, `"burch"`, `"mpl"`, and
  `"posterior"` under **brms**. Where a method does not apply to the
  design, the call aborts with a classed error. *Confidence-interval
  methods* compares them;
  [`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md) gives
  the per-method conditions.
- Interval coverage was studied by simulation before release, and the
  limitations those studies found are documented rather than smoothed
  over. The Monte-Carlo default under-covers when the subject effects
  are strongly skewed or heavy-tailed, worst 0.6725 at chi-square(1)
  subject effects with a true ICC of 0.6, 50 subjects and 5 raters.
  `"burch"` is no remedy there (worst 0.6655).
- Which of the two closed forms gives the **narrower** interval is
  conditional. On both grids that vary only the subject effect,
  `"burch"` is the narrower of the two in 16 of 16 cells of the smaller
  grid and 59 of 64 cells of the larger grid.
- That width margin holds much the same up to a true ICC of 0.3 rather
  than shrinking as the true ICC rises (on the larger grid; the smaller
  grid’s margin does shrink across its levels). The `"burch"` width
  advantage then collapses to near parity at a true ICC of 0.6, on the
  one grid reaching that value. It also shrinks steadily as the subject
  count grows, measured at 5 raters.
- What `"burch"` does against `"searle"` also depends on the residual,
  and the three grids measure that: the two grids that vary only the
  subject effect put it narrower nearly everywhere, while the third,
  which draws the residual from the same family as the subject effect,
  puts it wider at every symmetric heavy-tailed family measured (a
  median width ratio of 1.2963 at t(5) with 100 subjects) and narrower
  at every lighter-tailed one, the normal included.
- The `ci_method = "mpl"` documentation states the interpolation
  evidence behind off-node subject counts. The correction constant is
  calibrated at subject-count nodes and linearly interpolated between
  them. The interpolated path is coverage-validated at each supported
  confidence level, at the default 0.95 by three off-node cells, each
  clearing its pre-registered coverage floor. The documentation also
  says what that validation does not establish (interpolated values are
  validated at a handful of geometries, not calibrated, and the
  interval’s asymmetry direction is not uniform across rater counts).
  Every universal or negative claim this documentation makes about the
  validated cells is settled mechanically, in CI, against the committed
  coverage fixture (`data-raw/check-mpl-doc-claims.py`).

### When a call fails

- Errors are classed and name the quantities that failed the check,
  rather than asserting a cause. Where an interval method aborts on
  degenerate data, the error names another `ci_method` only after
  running it on your data and confirming it returns a usable interval.
