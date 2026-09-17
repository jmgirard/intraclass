# Simulated balanced two-way ratings, twenty subjects by four raters

Simulated data, not a real study. Twenty subjects are each scored once
by the same four raters. The variance components are 0.6 (subject), 0.1
(rater), and 0.2 (residual), so the population `ICC(A,1)` is 0.667. The
design is large enough for `ci_method = "mpl"`, which the six-subject
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
data are not. The "Interval methods" article uses it.

## Usage

``` r
ratings_twoway
```

## Format

A data frame with 80 rows and 3 columns, as in
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
(`subject`, `rater`, `score`).

## Source

Simulated by `data-raw/make-vignette-data.R` with `set.seed(88)`. The
score is a subject effect plus a rater effect plus noise, all normal
draws with the variances above.

## See also

[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
for the Shrout and Fleiss worked example.

## Examples

``` r
str(ratings_twoway)
#> 'data.frame':    80 obs. of  3 variables:
#>  $ subject: Factor w/ 20 levels "1","2","3","4",..: 1 2 3 4 5 6 7 8 9 10 ...
#>  $ rater  : Factor w/ 4 levels "1","2","3","4": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ score  : num  0.307 0.2 1.613 -1.985 0.283 ...
icc(ratings_twoway, score, subject, rater, type = "agreement",
  ci_method = "mpl")
#> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
#> Subjects: 20 | Raters: 4 (random) | Observations: 80 of 80 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% modified profile likelihood (closed form)
#> 
#>   index     estimate   95% CI
#>   ICC(A,1)     0.709   [0.425, 0.865]
#>   ICC(A,k)     0.907   [0.747, 0.963]
#> 
#> Variance components: subject 0.652, rater 0.042, residual 0.226
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```
