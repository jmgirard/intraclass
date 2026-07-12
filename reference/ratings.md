# Rater reliability example (Shrout & Fleiss, 1979)

The six-target, four-judge worked example from Shrout and Fleiss (1979),
in the long, one-rating-per-row format that
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
consumes. Every subject is rated by every rater (a complete, balanced
two-way design), so it is the reference case on which
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
returns the canonical coefficients `ICC(A,1)` = 0.290, `ICC(A,k)` =
0.620, `ICC(C,1)` = 0.715, and `ICC(C,k)` = 0.909.

## Usage

``` r
ratings
```

## Format

A data frame with 24 rows and 3 columns:

- subject:

  Factor with 6 levels: the target being rated (the object of
  measurement).

- rater:

  Factor with 4 levels: the judge providing the rating.

- score:

  Numeric rating.

## Source

Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: Uses in
assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.
The example in their Table 2.

## See also

[ratings_incomplete](https://jmgirard.github.io/intraclass/reference/ratings_incomplete.md)
for a connected incomplete variant.

## Examples

``` r
icc(ratings, score, subject, rater, seed = 2024)
#> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     estimate   95% CI
#>   ICC(A,1)     0.290   [0.050, 0.711]
#>   ICC(A,k)     0.620   [0.173, 0.908]
#> 
#> Variance components: subject 2.556, rater 5.244, residual 1.019
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```
