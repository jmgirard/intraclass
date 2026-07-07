# Intraclass correlation coefficient for a two-way random design

Estimates interrater-reliability intraclass correlation coefficients
(ICCs) from a fitted linear mixed model, rather than from classical
ANOVA mean squares. In this release `icc()` computes the **two-way
random, absolute-agreement** coefficients `ICC(A,1)` and `ICC(A,k)`
(McGraw & Wong 1996), equivalent to Shrout & Fleiss (1979) `ICC(2,1)`
and `ICC(2,k)`.

## Usage

``` r
# S3 method for class 'icc'
format(x, ...)

# S3 method for class 'icc'
print(x, ...)

# S3 method for class 'icc'
summary(object, ...)

# S3 method for class 'icc'
tidy(x, ...)

# S3 method for class 'icc'
glance(x, ...)

icc(
  data,
  score,
  subject,
  rater,
  model = "twoway",
  type = "agreement",
  unit = c("single", "average"),
  engine = "glmmTMB",
  conf_level = 0.95,
  ci_method = "montecarlo",
  mc_samples = 10000L,
  seed = NULL
)
```

## Arguments

- x, object:

  An `icc` object.

- ...:

  Unused, for method consistency.

- data:

  A data frame with one rating per row.

- score, subject, rater:

  Columns of `data` (unquoted): the numeric rating, the subject (object
  of measurement), and the rater (judge).

- model:

  Design. Only `"twoway"` is currently supported.

- type:

  Error definition. Only `"agreement"` (absolute agreement) is currently
  supported; `"consistency"` is planned.

- unit:

  One or both of `"single"` (-\> `ICC(A,1)`) and `"average"` (-\>
  `ICC(A,k)`).

- engine:

  Estimation engine. Only `"glmmTMB"` is currently supported.

- conf_level:

  Confidence level for the interval (default `0.95`).

- ci_method:

  Interval method. Only `"montecarlo"` is currently supported.

- mc_samples:

  Number of Monte-Carlo draws for the interval.

- seed:

  Optional integer seed for a reproducible interval. The global RNG
  state is restored afterward.

## Value

An `icc` object: a list with the estimate table, variance components,
design, engine, interval settings, sample sizes, the fitted model, and
the call. Use [tidy()](https://generics.r-lib.org/reference/tidy.html),
[glance()](https://generics.r-lib.org/reference/glance.html), and the
`print`/`summary` methods.

## Which ICC is this, and when should you use it?

This is the **two-way random, absolute-agreement** ICC.

- **Absolute agreement** treats systematic differences between raters
  (the rater main effect, \\\sigma^2_r\\) as error: use it when the
  actual value matters and raters must agree on the number (clinical
  scores, measurements). Its sibling, *consistency*, ignores a constant
  rater offset and is not yet implemented.

- **`ICC(A,1)`** is the reliability of a *single* randomly chosen rater;
  **`ICC(A,k)`** is the reliability of the *mean* of your `k` raters.
  Report `ICC(A,k)` when the averaged score is what you will actually
  use.

- **Two-way random** means both subjects and raters are random samples
  you wish to generalize beyond.

A large gap between consistency and absolute agreement signals big
systematic differences in rater level – a rating-procedure problem worth
fixing.

## Estimand

With a single rating per subject-by-rater cell, the subject-by-rater
interaction and pure error are not separately identified; only their
sum, the residual variance \\\sigma^2\_{res}\\, is estimable. The
coefficients are \$\$ICC(A,1) = \sigma^2_s / (\sigma^2_s + \sigma^2_r +
\sigma^2\_{res})\$\$ \$\$ICC(A,k) = \sigma^2_s / (\sigma^2_s +
(\sigma^2_r + \sigma^2\_{res}) / k)\$\$ where \\\sigma^2_s\\ is the
subject (signal) variance and `k` is the number of raters.

## Confidence intervals

Intervals are Monte-Carlo: parameters are drawn from the fitted
covariance on the model's internal (log) scale and back-transformed, so
the interval is boundary-aware near the common zero-rater-variance case
where the delta method fails. Pass `seed` for a reproducible interval.

## References

McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some
intraclass correlation coefficients. *Psychological Methods, 1*(1),
30-46.

Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.

## Examples

``` r
ratings <- data.frame(
  subject = factor(rep(1:6, 4)),
  rater = factor(rep(1:4, each = 6)),
  score = c(9, 6, 8, 7, 10, 6, 2, 1, 4, 1, 5, 2,
            5, 3, 6, 2, 6, 4, 8, 2, 8, 6, 9, 7)
)
icc(ratings, score, subject, rater, seed = 1)
#> # Intraclass correlation: two-way random, absolute agreement
#> Subjects: 6 | Raters: 4 (random) | Observations: 24
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(A,1)    0.290   [0.050, 0.712]
#>   ICC(A,k)    0.620   [0.173, 0.908]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
```
