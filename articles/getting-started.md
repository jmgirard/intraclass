# Getting started

``` r

library(intraclass)
```

`intraclass` estimates interrater-reliability intraclass correlation
coefficients (ICCs) from a mixed model rather than from classical ANOVA
mean squares. This article walks the full pipeline on a small, balanced
example: **fit → ICC → interpret**.

## The data

We use the classic Shrout & Fleiss (1979) example: 6 subjects each rated
by the same 4 raters, one rating per cell. `intraclass` wants **long**
format — one rating per row.

``` r

ratings <- data.frame(
  subject = factor(rep(1:6, times = 4)),
  rater = factor(rep(1:4, each = 6)),
  score = c(
    9, 6, 8, 7, 10, 6, # rater 1
    2, 1, 4, 1, 5, 2, # rater 2
    5, 3, 6, 2, 6, 4, # rater 3
    8, 2, 8, 6, 9, 7 # rater 4
  )
)
head(ratings)
#>   subject rater score
#> 1       1     1     9
#> 2       2     1     6
#> 3       3     1     8
#> 4       4     1     7
#> 5       5     1    10
#> 6       6     1     6
```

## Fit

Call [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
with the data and the three columns (unquoted). The defaults give the
**two-way random, absolute-agreement** coefficients `ICC(A,1)` and
`ICC(A,k)`. We set a `seed` so the Monte-Carlo confidence interval is
reproducible.

``` r

fit <- icc(ratings, score, subject, rater, seed = 2024)
fit
#> # Intraclass correlation: two-way random, absolute agreement
#> Subjects: 6 | Raters: 4 (random) | Observations: 24
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(A,1)    0.290   [0.050, 0.713]
#>   ICC(A,k)    0.620   [0.173, 0.909]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
```

## Read the result with the tidy verbs

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns one
row per coefficient, with the estimate and confidence interval;
[`glance()`](https://generics.r-lib.org/reference/glance.html) returns a
one-row model summary including the variance components.

``` r

tidy(fit)
#> # A tibble: 2 × 7
#>   index    estimate std.error conf.low conf.high conf.level method    
#>   <chr>       <dbl>     <dbl>    <dbl>     <dbl>      <dbl> <chr>     
#> 1 ICC(A,1)    0.290     0.180   0.0498     0.713       0.95 montecarlo
#> 2 ICC(A,k)    0.620     0.201   0.173      0.909       0.95 montecarlo

glance(fit)
#> # A tibble: 1 × 9
#>   n_subjects n_raters n_obs var_subject var_rater var_residual engine  ci_method
#>        <int>    <int> <int>       <dbl>     <dbl>        <dbl> <chr>   <chr>    
#> 1          6        4    24        2.56      5.24         1.02 glmmTMB montecar…
#> # ℹ 1 more variable: conf.level <dbl>
```

## Interpret

- **`ICC(A,1)` ≈ 0.29** is the reliability of a *single* rater;
  **`ICC(A,k)` ≈ 0.62** is the reliability of the *mean* of the 4
  raters. Averaging raises reliability (Spearman–Brown), so report
  `ICC(A,k)` when the averaged score is what you will actually use.
- These are **absolute-agreement** coefficients: systematic differences
  in rater level (some raters scoring higher than others) count as
  error. Here the raters differ sharply in average level, which is why
  the agreement ICC is much lower than a consistency ICC would be — a
  signal that the rating procedure has a level problem worth fixing.
- The **confidence interval** is Monte-Carlo and boundary-aware: it is
  simulated from the fitted parameter covariance on the model’s internal
  scale, so it behaves near the common zero-rater-variance boundary
  where the delta method fails.

## Which ICC do I want?

Absolute agreement vs. consistency, single vs. average, fixed vs. random
raters, complete vs. incomplete designs — these choices define *which*
ICC is correct for your study. A dedicated “Choosing an ICC” article
covers that decision in depth.
