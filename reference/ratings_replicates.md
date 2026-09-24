# Simulated ratings with three ratings per subject-rater cell

Simulated data, not a real study. Twenty subjects are each scored by the
same four raters, and each rater scores each subject three times. The
repeated ratings let
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
separate the subject-by-rater interaction (standard deviation 0.6) from
pure error (0.7). The "D-studies and replicates" article uses it.

## Usage

``` r
ratings_replicates
```

## Format

A data frame with 240 rows and 3 columns:

- subject:

  Factor with 20 levels: the target being rated.

- rater:

  Factor with 4 levels: the rater.

- score:

  Numeric rating. Each subject-rater pair appears three times.

## Source

Simulated by `data-raw/make-vignette-data.R` with `set.seed(2025)`. The
score is 10 plus a subject effect, a rater effect, a subject-by-rater
effect, and noise, with standard deviations 1.1, 0.8, 0.6, and 0.7.

## See also

[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
for a design with one rating per cell.

## Examples

``` r
str(ratings_replicates)
#> 'data.frame':    240 obs. of  3 variables:
#>  $ subject: Factor w/ 20 levels "1","2","3","4",..: 1 2 3 4 5 6 7 8 9 10 ...
#>  $ rater  : Factor w/ 4 levels "1","2","3","4": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ score  : num  9.49 9.01 9.22 12.28 10.22 ...
icc(ratings_replicates, score, subject, rater, type = "agreement",
  occasions = c("single", "average"), seed = 1)
#> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
#> Subjects: 20 | Raters: 4 (random) | 80 cells x 3 replicates (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     occasions estimate   95% CI
#>   ICC(A,1)          1    0.263   [0.079, 0.492]
#>   ICC(A,1)          3    0.300   [0.085, 0.561]
#>   ICC(A,k)          1    0.588   [0.256, 0.795]
#>   ICC(A,k)          3    0.631   [0.270, 0.837]
#> 
#> Variance components: subject 0.631, rater 0.901, subject:rater 0.428, residual 0.443
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```
