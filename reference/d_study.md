# Project reliability to other numbers of raters (a D-study)

**\[experimental\]**

Projects the reliability of a fitted
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) to the
mean of an arbitrary number of raters `m`. This is a
generalizability-theory **decision (D-) study**, answering "how reliable
would the mean of `m` raters be?" and, read as a curve, "how many raters
do I need?". The point estimate and its boundary-aware interval reuse
the fit stored on `x`, and no model is refit. The band follows the fit's
`ci_method`. A Monte-Carlo fit reprojects one draw from the parameter
covariance across every `m`. A **bootstrap** fit reprojects its stored
resamples, so at `m` = the observed rater count the band matches the
fitted `ICC(*,k)` interval exactly.

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

  Unused, for method consistency.

- x:

  An `icc` object returned by
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md).

- m:

  Numeric vector of rater counts to project to (each \\\ge 1\\).
  Defaults to `1:(2 * n_raters)`, a curve from a single rater to twice
  the observed count. Mutually exclusive with `n_o`.

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
projected point and columns `m`, `index` (e.g. `"ICC(A,3)"`), `type`,
`estimate`, `std.error`, `conf.low`, and `conf.high`, carrying the
design and interval settings as attributes. If the fitted `icc` reports
both error definitions (the default), `d_study()` projects **one
reliability curve per definition** and
[`tidy()`](https://generics.r-lib.org/reference/tidy.html) surfaces a
`type` column to distinguish them. A single-type fit projects a single
curve. A multilevel projection adds a `level` column (one curve per
level), and a replicate projection an `occasions` column.

The methods documented on this page return:

- `tidy.icc_dstudy()`: a tibble with one row per projected point. Its
  columns are `m`, `index`, `estimate`, `std.error`, `conf.low`,
  `conf.high`, `conf.level`, and `method`. It gains a `type` column when
  both error definitions are projected, a `level` column for a
  multilevel projection, and an `occasions` column for a replicate
  projection. The conditional columns are inserted after `index`
  (`type`) and after `m` (`level`, `occasions`), so the list above is
  not a column order.

- `glance.icc_dstudy()`: a one-row tibble of projection-level summaries.
  It carries the distinct projected rater counts `m` and their range,
  the error definition(s), the rater treatment, the observed rater
  count, and the interval settings. The count and range are held at the
  observed rater count when the sweep is over occasions, so they are not
  a row count.

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
down, especially the rater variance \\\sigma^2_r\\, which is estimated
from only as many raters as you observed. With few raters that estimate
is noisy, so the projected interval is honestly wide. The Monte-Carlo
interval widens automatically, recomputing \\\Phi(m)\\ on every draw
rather than pretending a single plugged-in value. `m` is the number of
raters and is normally an integer, though non-integer values are
permitted.

Projection is defined for random raters (both agreement and
consistency), for fixed-rater **consistency**, and for the **one-way**
model (a Spearman-Brown projection of `ICC(1)`). It is **not** defined
for fixed-rater absolute agreement. There the rater term is the
finite-population variance of exactly the raters you observed, so there
is no "average of `m` freshly sampled raters" to project to. `d_study()`
aborts in that case (use `raters = "random"`).

## Multilevel projections

For a multilevel fit (a `cluster` column), `d_study()` projects the
rater count `m` for each correctly-partitioned level on the object,
meaning the **subject** and/or **cluster** level. It returns one
reliability curve per level, and the result gains a `level` column that
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
facets by. This is the paper-sanctioned rater projection (ten Hove et
al. 2022). Here `m` is the number of raters per cluster, and the
cluster-level coefficient does **not** average over subjects, so there
is no "subjects per cluster" projection. That is a sample-size question,
not a reliability one. Nested designs project the subject level only.
The conflated diagnostic (`level = "conflated"`) is not projected. On
**incomplete** data the **subject** level projects, because projection
moves only the divisor. On that same data the **cluster** level is
dropped with a note: projecting `m` raters is the averaged `ICC(c,k)`
case, whose ragged divisor is an open modeling question (M9).

## Within-cell replicate fits

For a within-cell replicate fit (more than one rating per
subject-by-rater cell, where the residual splits into the
subject-by-rater interaction and pure error), `d_study()` can project
**either** axis (one per call):

- the **rater count `m`** (the default), holding the number of occasions
  `n_o` at the fitted value: the rater and interaction terms divide by
  `m`, pure error by `m * n_o`. The result gains an `occasions` column,
  one reliability curve per occasion setting on the fit (`"single"`
  and/or `"average"`), so at `m` = the observed rater count each curve
  matches the fitted `ICC(*,k)`.

- the **occasion count `n_o`** (supply the `n_o` argument), holding
  raters at the observed count: pure error divides by `m * n_o` while
  the rater and interaction terms are unchanged. Because occasion
  averaging rescales **only pure error**, this curve is well-posed for
  random **and** fixed raters. That includes fixed absolute agreement,
  which the rater projection refuses, since occasions are a random facet
  however the raters are treated. At `n_o` = the fitted occasion count
  it matches the fitted `ICC(*,k)`.

**The occasion curve has a finite ceiling.** As `n_o` grows it
approaches `sigma^2_s / (sigma^2_s + (sigma^2_r + sigma^2_sr) / m)`,
**not** 1. Averaging more occasions washes out only pure measurement
error, never the rater or subject-by-rater variance. Read it as "how
much does re-rating help?", which plateaus, unlike adding raters.

For a multilevel replicate fit (crossed Design 1 or nested Design 2), a
**rater** projection moves the subject level across occasion settings
and the cluster level single-occasion. An **occasion** projection moves
the subject level across `n_o` and returns the cluster level as a
**flat** curve. The cluster-level error set (`{rater, cluster:rater}`)
has no pure-error term, so averaging occasions cannot change it, and
`d_study()` notes this. **Ragged** replicate fits are refused for either
axis (the occasion-averaged ragged divisor is an open modeling
question).

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
#>     agreement  1     0.290  [0.050, 0.706]
#>     agreement  2     0.449  [0.096, 0.828]
#>     agreement  3     0.550  [0.137, 0.878]
#>     agreement  4     0.620  [0.175, 0.906]
#>     agreement  5     0.671  [0.210, 0.923]
#>     agreement  6     0.710  [0.241, 0.935]
#>     agreement  7     0.741  [0.271, 0.944]
#>     agreement  8     0.765  [0.298, 0.950]
#>   consistency  1     0.715  [0.339, 0.924]
#>   consistency  2     0.834  [0.507, 0.961]
#>   consistency  3     0.883  [0.606, 0.973]
#>   consistency  4     0.909  [0.672, 0.980]
#>   consistency  5     0.926  [0.720, 0.984]
#>   consistency  6     0.938  [0.755, 0.987]
#>   consistency  7     0.946  [0.782, 0.988]
#>   consistency  8     0.953  [0.804, 0.990]
```
