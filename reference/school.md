# Simulated multilevel ratings: pupils nested in classrooms

Simulated data, not a real study. Sixteen classrooms hold five pupils
each, and the same four raters score every pupil. The classroom standard
deviation (1.3) is larger than the pupil one within a classroom (0.6),
so the cluster-level ICC comes out above the subject-level ICC. The
"Multilevel designs" article and the README use it.

## Usage

``` r
school
```

## Format

A data frame with 320 rows and 4 columns:

- classroom:

  Factor with 16 levels: the cluster.

- pupil:

  Factor with 80 levels: the subject, labeled `classroom_pupil`.

- rater:

  Factor with 4 levels: the rater.

- score:

  Numeric rating.

## Source

Simulated by `data-raw/make-vignette-data.R` with `set.seed(2025)`. The
score is 10 plus a classroom effect, a pupil effect, a rater effect, and
noise (standard deviation 0.7), all normal draws.

## See also

[school_incomplete](https://jmgirard.github.io/intraclass/reference/school_incomplete.md)
for the same design with a fifth of the ratings removed.

## Examples

``` r
str(school)
#> 'data.frame':    320 obs. of  4 variables:
#>  $ classroom: Factor w/ 16 levels "1","2","3","4",..: 1 1 1 1 1 2 2 2 2 2 ...
#>  $ pupil    : Factor w/ 80 levels "1_1","1_2","1_3",..: 1 2 3 4 5 6 7 8 9 10 ...
#>  $ rater    : Factor w/ 4 levels "1","2","3","4": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ score    : num  10.5 10.1 10 11.7 9 ...
icc(school, score, subject = pupil, rater = rater, cluster = classroom,
  type = "agreement", seed = 1)
#> ℹ Treating raters with the same label in different clusters as the same raters
#>   (crossed with clusters, Design 1).
#> ℹ If each cluster has its own raters, give them cluster-unique labels or pass
#>   `design = "nested_in_clusters"`.
#> This message is displayed once per session.
#> ── Intraclass correlation: multilevel two-way random, absolute agreement ───────
#> Subjects: 80 in 16 clusters | Raters: 4 (random) | Observations: 320 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   level      index     estimate   95% CI
#>   subject    ICC(A,1)     0.431   [0.254, 0.561]
#>   subject    ICC(A,k)     0.751   [0.576, 0.836]
#>   cluster    ICC(A,1)     0.880   [0.000, 0.972]
#>   cluster    ICC(A,k)     0.967   [0.000, 0.993]
#> 
#> Variance components: cluster 0.998, subject 0.461, rater 0.136, cluster:rater 0.000, residual 0.473
```
