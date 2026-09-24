# Project reliability to other numbers of raters

**\[experimental\]**

Projects the reliability of a fitted
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) to the
mean of `m` raters, for any `m`. It reuses the fit's variance
components, each a share of the total variation traced to one source.
This is a generalizability-theory **decision study** (D-study), which
projects the fitted variance components to other rater or
[occasion](https://jmgirard.github.io/intraclass/articles/glossary.html#occasion-within-cell-replicate)
counts. It answers "how reliable would the mean of `m` raters be?" and,
read as a curve, "how many raters do I need?". The point estimate and
its interval reuse the fit stored on `x`, and no model is refit. The
interval is boundary-aware, since an estimate can land exactly at zero.
The band follows the fit's `ci_method`. A Monte-Carlo fit has an
interval built by drawing parameter values from the fitted model's
uncertainty. It reprojects one draw from the parameter covariance across
every `m`. A **bootstrap** fit, which refits the model on simulated data
many times, reprojects its stored resamples. So on a bootstrap fit, at
`m` = the observed rater count the band matches the fitted `ICC(*,k)`
interval exactly.

## Usage

``` r
autoplot.icc_dstudy(object, ...)

# S3 method for class 'icc_dstudy'
plot(x, ...)

d_study(
  x,
  m = NULL,
  n_o = NULL,
  conf_level = NULL,
  mc_samples = NULL,
  seed = NULL
)

# S3 method for class 'icc_dstudy'
format(x, ...)

# S3 method for class 'icc_dstudy'
print(x, ...)

# S3 method for class 'icc_dstudy'
tidy(x, ...)

# S3 method for class 'icc_dstudy'
glance(x, ...)
```

## Arguments

- object:

  An `icc_dstudy` object (the
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)/[`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  argument).

- ...:

  Unused. Present so the method signature matches the generic.

- x:

  An `icc` object returned by
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md).

- m:

  Numeric vector of rater counts to project to (each \\\ge 1\\).
  Defaults to `1:(2 * n_raters)`, a curve from one rater to twice the
  observed count. Mutually exclusive with `n_o`.

- n_o:

  Numeric vector of occasion (within-cell replicate) counts to project
  to (each \\\ge 1\\), holding raters at the observed count. This is a
  D-study on the **occasion** facet of a within-cell replicate fit.
  Mutually exclusive with `m`, and supplying both aborts. `NULL` (the
  default) projects the rater count `m` instead.

- conf_level, mc_samples, seed:

  Interval settings. Each defaults to the value stored on `x`, so a
  seeded fit yields a reproducible projection. Override to change the
  confidence level, the number of Monte-Carlo draws, or the seed.

## Value

`d_study()` returns an `icc_dstudy` object: a tibble with one row per
projected point. Its columns are `m`, `index` (e.g. `"ICC(A,3)"`),
`type`, `estimate`, `std.error`, `conf.low`, and `conf.high`, and it
carries the design and interval settings as attributes.
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) names that
coefficient column `term`, following the broom glossary. The object
keeps `index`. If the fitted `icc` reports both error definitions (the
default), `d_study()` projects **one reliability curve per definition**,
distinguished by the `type` column. A single-type fit projects a single
curve. A multilevel projection gains a `level` column (one curve per
level), and a replicate projection an `occasions` column, each where it
applies. [`tidy()`](https://generics.r-lib.org/reference/tidy.html)
carries both columns on every projection, `NA` where the fit does not
define them. Read the projection with
[`tidy()`](https://generics.r-lib.org/reference/tidy.html): the object's
own layout is internal, and only the tidied columns are a stable
contract.

The methods documented on this page return the objects below.

- `tidy.icc_dstudy()`: a tibble with one row per projected point. Its
  columns, in this order, are `m`, `occasions`, `level`, `term`, `type`,
  `estimate`, `std.error`, `conf.low`, `conf.high`, `conf.level`,
  `method`. `term` is the projected ICC index, named for the broom
  glossary. Every column is present on every projection. `occasions`
  reports the per-cell occasion count the row is projected at, which may
  be non-integer, and which divides pure error, so a row whose error set
  carries no pure-error term does not move with it. On a rater
  projection the column takes every distinct occasion value the fit's
  own `tidy()$occasions` column carries, and the cluster rows of a
  multilevel projection take the smallest of those. On an occasion
  projection every row takes the swept `n_o`, cluster rows included,
  whose curve is flat across it. `occasions` is `NA` outside a replicate
  projection. `level` is `NA` outside a multilevel one, and `type` where
  the design defines no error definition.

- `glance.icc_dstudy()`: a one-row tibble of projection-level summaries.
  It carries the distinct projected rater counts `m` and their range,
  the error definition(s), the rater treatment, the observed rater
  count, and the interval settings. The rater treatment is `NA` on a
  projection of a fit that estimates no separable rater main effect. One
  such fit is `model = "oneway"`, whose raters are interchangeable and
  carry no facet. The other is `design = "nested_in_subjects"`, whose
  rater effect is confounded into the residual. The count and range are
  held at the observed rater count when the sweep is over occasions, so
  they are not a row count.

- `format.icc_dstudy()`: a character vector holding the printed
  projection table, one line per element.

- `print.icc_dstudy()`: the `icc_dstudy` object invisibly, having
  emitted that table.

- `autoplot.icc_dstudy()`: a `ggplot` object holding the reliability
  curve, faceted by level for a multilevel projection.

- `plot.icc_dstudy()`: the `icc_dstudy` object invisibly, having drawn
  that curve.

`tidy.icc_dstudy()` and `glance.icc_dstudy()` implement the
[tidy()](https://generics.r-lib.org/reference/tidy.html) and
[glance()](https://generics.r-lib.org/reference/glance.html) generics.

## Projection is extrapolation

Projecting to an `m` you did not run is an **extrapolation**. Its
trustworthiness depends on how well the variance components are pinned
down. The rater variance \\\sigma^2_r\\ matters most, since it is
estimated from only as many raters as you observed. With few raters that
estimate is noisy, so the projected interval is honestly wide. The
Monte-Carlo interval widens automatically, recomputing \\\Phi(m)\\ on
every draw rather than pretending a single plugged-in value. `m` is the
number of raters and is normally an integer, though non-integer values
are permitted.

Projection is defined for random raters, under both error definitions.
Those are agreement, where raters give the same score, and consistency,
where raters agree apart from a constant offset per rater. It is also
defined for fixed-rater **consistency**, fixed meaning the observed
raters are the whole population of interest. In a two-way design each
rater is tracked across the subjects they score. The **one-way** model,
where raters are not tracked, is defined too, as a Spearman-Brown
projection of `ICC(1)`. Projection is **not** defined for fixed-rater
absolute agreement. There the rater term is the finite-population
variance, the spread of just the observed raters. So there is no
"average of `m` freshly sampled raters" to project to. `d_study()`
aborts in that case (use `raters = "random"`).

## Multilevel projections

For a multilevel fit (a `cluster` column), `d_study()` projects the
rater count `m` for each correctly-partitioned level on the object.
Those are the **subject** and/or **cluster** level, where the subject
level is reliability within a cluster, and the cluster level is
reliability of cluster means. It returns one reliability curve per
level, and the returned object gains a `level` column that
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
facets by. [`tidy()`](https://generics.r-lib.org/reference/tidy.html)
carries that column on every projection, `NA` where the fit is not
multilevel. This is the paper-sanctioned rater projection (ten Hove et
al. 2022). Here `m` is the number of raters per cluster. The
cluster-level coefficient does **not** average over subjects, so there
is no "subjects per cluster" projection. That is a sample-size question,
not a reliability one. Nested designs project the subject level only.
The conflated diagnostic (`level = "conflated"`), the single-level ICC
that ignores clustering, is not projected. On **incomplete** data the
**subject** level projects, because projection moves only the divisor.
On that same data the **cluster** level is dropped with a note.
Projecting `m` raters there is the averaged `ICC(c,k)` case, whose
ragged divisor is an open modeling question.

## Within-cell replicate fits

A replicate is one of several ratings by the same rater of the same
subject. In a within-cell replicate fit (more than one rating per
subject-by-rater cell) the residual splits into the subject-by-rater
interaction and pure error. On such a fit `d_study()` can project
**either** axis (one per call):

- the **rater count `m`** (the default), holding the occasion count
  fixed. The rater and interaction terms divide by `m`, and pure error
  by `m` times the curve's own occasion setting. The returned object
  gains an `occasions` column, one reliability curve per distinct value
  that column holds on the fit. A single-occasion setting divides pure
  error by `m` alone, an occasion-averaged one by `m` times the fitted
  occasion count. At `m` = the observed rater count each curve matches
  the fitted `ICC(*,k)` for its own level and occasion setting, where
  the fit reports one. Where the fit reports a cluster level, its
  `occasions` column also carries that level's placeholder 1. The
  placeholder is there because that error set has no pure error to
  average. So such a fit made with `occasions = "average"` alone still
  projects a subject curve at 1, which the fit itself does not report.
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) carries
  that column on every projection, `NA` where the fit has no replicates.

- the **swept occasion count `n_o`** (supply the `n_o` argument),
  holding raters at the observed count. Pure error divides by `m * n_o`
  while the rater and interaction terms are unchanged. Because occasion
  averaging rescales **only pure error**, this curve is well-posed for
  random **and** fixed raters. That includes fixed absolute agreement,
  which the rater projection refuses, since occasions are a random facet
  however the raters are treated. Where the swept `n_o` equals the
  fitted occasion count it matches the fitted `ICC(*,k)`.

**The occasion curve has a finite ceiling.** As `n_o` grows it
approaches `sigma^2_s / (sigma^2_s + (sigma^2_r + sigma^2_sr) / m)`,
**not** 1. Averaging more occasions washes out only pure measurement
error, never the rater or subject-by-rater variance. Read it as "how
much does re-rating help?", which plateaus, unlike adding raters.

Take a multilevel replicate fit (crossed Design 1 or nested Design 2).
On such a fit, a **rater** projection moves the subject level across
occasion settings and the cluster level single-occasion. An **occasion**
projection moves the subject level across `n_o` and returns the cluster
level as a **flat** curve. The cluster-level error set
(`{rater, cluster:rater}`) has no pure-error term, so averaging
occasions cannot change it, and `d_study()` notes this. **Ragged**
replicate fits are refused for either axis (the occasion-averaged ragged
divisor is an open modeling question).

## References

Brennan, R. L. (2001). *Generalizability Theory*. Springer.

## See also

[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md), which
also accepts a numeric `unit` for one-off projections.

## Examples

``` r
fit_ag <- icc(ratings, score, subject, rater, type = "agreement", seed = 1)
ggplot2::autoplot(d_study(fit_ag, m = 1:12)) # the D-study reliability curve

fit <- icc(ratings, score, subject, rater, seed = 1)
d_study(fit, m = 1:8)
#> # D-study projection: two-way random, absolute agreement & consistency
#> Observed raters: 4 | CI: 95% montecarlo (10000 draws)
#>          type  m  estimate          95% CI
#>     agreement  1     0.290  [0.050, 0.712]
#>     agreement  2     0.449  [0.095, 0.831]
#>     agreement  3     0.550  [0.136, 0.881]
#>     agreement  4     0.620  [0.173, 0.908]
#>     agreement  5     0.671  [0.207, 0.925]
#>     agreement  6     0.710  [0.239, 0.937]
#>     agreement  7     0.741  [0.268, 0.945]
#>     agreement  8     0.765  [0.295, 0.952]
#>   consistency  1     0.715  [0.335, 0.925]
#>   consistency  2     0.834  [0.502, 0.961]
#>   consistency  3     0.883  [0.601, 0.974]
#>   consistency  4     0.909  [0.668, 0.980]
#>   consistency  5     0.926  [0.716, 0.984]
#>   consistency  6     0.938  [0.751, 0.987]
#>   consistency  7     0.946  [0.779, 0.989]
#>   consistency  8     0.953  [0.801, 0.990]
```
