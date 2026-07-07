# Getting started

``` r

library(intraclass)
```

`intraclass` estimates interrater-reliability intraclass correlation
coefficients (ICCs) from a mixed model rather than from classical ANOVA
mean squares. This article walks the full pipeline on a small, balanced
example: **fit → ICC → interpret**.

## The data

We use the classic Shrout & Fleiss (1979) example, shipped with the
package as `ratings`: 6 subjects each rated by the same 4 raters, one
rating per cell. `intraclass` wants **long** format — one rating per
row, with columns for the subject, the rater, and the score.

``` r

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
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(A,1)    0.290   [0.050, 0.711]
#>   ICC(A,k)    0.620   [0.173, 0.908]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```

## Read the result with the tidy verbs

[`tidy()`](https://generics.r-lib.org/reference/tidy.html) returns one
row per coefficient, with the estimate and confidence interval;
[`glance()`](https://generics.r-lib.org/reference/glance.html) returns a
one-row model summary including the variance components.

``` r

tidy(fit)
#> # A tibble: 2 × 9
#>   index   level sf_index estimate std.error conf.low conf.high conf.level method
#>   <chr>   <chr> <chr>       <dbl>     <dbl>    <dbl>     <dbl>      <dbl> <chr> 
#> 1 ICC(A,… NA    ICC(2,1)    0.290     0.180   0.0498     0.711       0.95 monte…
#> 2 ICC(A,… NA    ICC(2,k)    0.620     0.201   0.173      0.908       0.95 monte…

glance(fit)
#> # A tibble: 1 × 17
#>   n_subjects n_raters n_clusters n_obs n_cells balanced multilevel ml_design
#>        <int>    <int>      <int> <int>   <int> <lgl>    <lgl>      <chr>    
#> 1          6        4         NA    24      24 TRUE     FALSE      NA       
#> # ℹ 9 more variables: k_eff <dbl>, var_cluster <dbl>, var_subject <dbl>,
#> #   var_rater <dbl>, var_cluster_rater <dbl>, var_residual <dbl>, engine <chr>,
#> #   ci_method <chr>, conf.level <dbl>
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

## Consistency instead of agreement

If a constant per-rater offset is acceptable — you care only that raters
*rank* subjects the same way, not that they land on the same number —
ask for **consistency** with `type = "consistency"`. It drops the rater
main effect from the error, so it is never smaller than the agreement
coefficient:

``` r

icc(ratings, score, subject, rater, type = "consistency", seed = 2024)
#> # Intraclass correlation: two-way random, consistency
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(C,1)    0.715   [0.340, 0.926]
#>   ICC(C,k)    0.909   [0.673, 0.980]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
```

The gap between the two (here `ICC(C,1)` ≈ 0.72 vs. `ICC(A,1)` ≈ 0.29)
is a direct read-out of how much systematic rater-level difference is
present.

By default raters are treated as **random** (a sample you generalize
beyond). If your raters are the entire population of interest you can
pass `raters = "fixed"` (the classic `ICC(3,1)`), but
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) will
warn: random is the recommended default for interrater reliability, and
on balanced data the number is identical anyway.

## Which ICC do I want?

Whether the raters are crossed (the same set judges everyone) or
interchangeable (`model = "oneway"`), absolute agreement
vs. consistency, single vs. average, fixed vs. random raters, complete
vs. incomplete designs — these choices define *which* ICC is correct for
your study. The [*Choosing an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)
article
([`vignette("choosing-an-icc")`](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md))
covers that decision in depth.
