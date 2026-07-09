# Project reliability to other numbers of raters (a D-study)

**\[experimental\]**

Projects the reliability of a fitted
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) to the
mean of an arbitrary number of raters `m` – a generalizability-theory
**decision (D-) study**, answering "how reliable would the mean of `m`
raters be?" and, read as a curve, "how many raters do I need?". The
point estimate and its boundary-aware interval reuse the fit stored on
`x`; no model is refit. The band follows the fit's `ci_method`: a
Monte-Carlo fit reprojects one draw from the parameter covariance across
every `m`, while a **bootstrap** fit reprojects its stored resamples (so
at `m` = the observed rater count the band matches the fitted `ICC(*,k)`
interval exactly).

## Usage

``` r
autoplot.icc_dstudy(object, ...)

# S3 method for class 'icc_dstudy'
plot(x, ...)

d_study(x, m = NULL, conf_level = NULL, mc_samples = NULL, seed = NULL)

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
  `autoplot()`/[`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  argument).

- ...:

  Unused, for method consistency.

- x:

  An `icc` object returned by
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md).

- m:

  Numeric vector of rater counts to project to (each \\\ge 1\\).
  Defaults to `1:(2 * n_raters)`, a curve from a single rater to twice
  the observed count.

- conf_level, mc_samples, seed:

  Interval settings. Each defaults to the value stored on `x` (so a
  seeded fit yields a reproducible projection); override to change the
  confidence level, the number of Monte-Carlo draws, or the seed.

## Value

An `icc_dstudy` object: a tibble with one row per `m` and columns `m`,
`index` (e.g. `"ICC(A,3)"`), `estimate`, `std.error`, `conf.low`, and
`conf.high`, carrying the design and interval settings as attributes. A
multilevel projection adds a `level` column (one curve per level). Use
[tidy()](https://generics.r-lib.org/reference/tidy.html),
[glance()](https://generics.r-lib.org/reference/glance.html), and
`autoplot()` (the reliability curve).

## Projection is extrapolation

Projecting to an `m` you did not run is an **extrapolation**, and its
trustworthiness depends on how well the variance components – especially
the rater variance \\\sigma^2_r\\, estimated from only as many raters as
you observed – are pinned down. With few raters that estimate is noisy,
so the projected interval is honestly wide; the Monte-Carlo interval
widens automatically (it recomputes \\\Phi(m)\\ on every draw) rather
than pretending a single plugged-in value. `m` is the number of raters
and is normally an integer, though non-integer values are permitted.

Projection is defined for random raters (both agreement and
consistency), for fixed-rater **consistency**, and for the **one-way**
model (a Spearman-Brown projection of `ICC(1)`). It is **not** defined
for fixed-rater absolute agreement: there the rater term is the
finite-population variance of exactly the raters you observed, so there
is no "average of `m` freshly sampled raters" to project to, and
`d_study()` aborts (use `raters = "random"`).

## Multilevel projections

For a multilevel fit (a `cluster` column), `d_study()` projects the
rater count `m` for each correctly-partitioned level on the object — the
**subject** and/or **cluster** level — returning one reliability curve
per level (the result gains a `level` column, and `autoplot()` facets by
it). This is the paper-sanctioned rater projection (ten Hove et al.
2022): `m` is the number of raters per cluster, and the cluster-level
coefficient does **not** average over subjects, so there is no "subjects
per cluster" projection — that is a sample-size question, not a
reliability one. Nested designs project the subject level only. The
conflated diagnostic (`level = "conflated"`) is not projected. On
**incomplete** data the **subject** level projects (projection moves
only the divisor); the **cluster** level is dropped with a note, because
projecting `m` raters is the averaged `ICC(c,k)` case whose ragged
divisor is an open modeling question (M9).

## Within-cell replicate fits

For a within-cell replicate fit (more than one rating per
subject-by-rater cell, where the residual splits into the
subject-by-rater interaction and pure error), `d_study()` projects the
**rater count `m`**, holding the number of occasions `n_o` at the fitted
value: the rater and interaction terms divide by `m`, pure error by
`m * n_o`. The result gains an `occasions` column, one reliability curve
per occasion setting on the fit (`occasions = "single"` and/or
`"average"`), so at `m` = the observed rater count each curve matches
the fitted `ICC(*,k)` for that setting. Multilevel replicate fits
project the subject level across occasion settings and the cluster level
single-occasion (occasion averaging touches only pure error, which is
not in the cluster-level error set). Projecting the occasion count
itself is not yet supported; **ragged** replicate fits are refused (the
occasion-averaged ragged divisor is an open modeling question).

## References

Brennan, R. L. (2001). *Generalizability Theory*. Springer.

## See also

[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md), which
also accepts a numeric `unit` for one-off projections.

## Examples

``` r
fit <- icc(ratings, score, subject, rater, seed = 1)
d_study(fit, m = 1:8)
#> # D-study projection: two-way random, absolute agreement
#> Observed raters: 4 | CI: 95% montecarlo (10000 draws)
#>   m  estimate          95% CI
#>   1     0.290  [0.050, 0.712]
#>   2     0.449  [0.095, 0.831]
#>   3     0.550  [0.136, 0.881]
#>   4     0.620  [0.173, 0.908]
#>   5     0.671  [0.207, 0.925]
#>   6     0.710  [0.239, 0.937]
#>   7     0.741  [0.268, 0.945]
#>   8     0.765  [0.295, 0.952]
```
