# Project reliability to other numbers of raters (a D-study)

**\[experimental\]**

Projects the reliability of a fitted
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) to the
mean of an arbitrary number of raters `m` – a generalizability-theory
**decision (D-) study**, answering "how reliable would the mean of `m`
raters be?" and, read as a curve, "how many raters do I need?". The
point estimate and its boundary-aware Monte-Carlo interval reuse the fit
stored on `x`; no model is refit.

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
`conf.high`, carrying the design and interval settings as attributes.
Use [tidy()](https://generics.r-lib.org/reference/tidy.html),
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
#>       m  estimate   95% CI
#>       1     0.290   [0.050, 0.706]
#>       2     0.449   [0.096, 0.828]
#>       3     0.550   [0.137, 0.878]
#>       4     0.620   [0.175, 0.906]
#>       5     0.671   [0.210, 0.923]
#>       6     0.710   [0.241, 0.935]
#>       7     0.741   [0.271, 0.944]
#>       8     0.765   [0.298, 0.950]
```
