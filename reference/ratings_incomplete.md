# Rater reliability example with missing cells

An incomplete variant of
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md):
rater 2 served as a pilot and scored only the first two subjects, so the
four cells for subjects 3-6 by rater 2 are absent (20 rows rather than
24). Missing cells are dropped rows, not `NA`s, matching the long format
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
expects.

## Usage

``` r
ratings_incomplete
```

## Format

A data frame with 20 rows and 3 columns, as in
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
(`subject`, `rater`, `score`).

## Source

Derived from
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md);
see `data-raw/make-ratings.R`. Underlying values from Shrout, P. E., &
Fleiss, J. L. (1979). Intraclass correlations: Uses in assessing rater
reliability. *Psychological Bulletin, 86*(2), 420-428.

## Details

The design is deliberately **ragged** – subjects 1-2 have all four
raters while subjects 3-6 have three – yet the observed subject-by-rater
graph remains a single **connected** component (raters 1, 3, and 4 rate
every subject), so the two-way ICC stays identified and
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) does
not abort (see the connectedness requirement in
[`vignette("choosing-an-icc")`](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)).

Because the per-subject rating counts differ, the averaging divisor for
`ICC(*,k)` is the effective number of ratings `k_eff` = 1 / mean(1 /
n_i) = 3.273 (the harmonic mean of the counts 4, 4, 3, 3, 3, 3), not an
integer. And unlike the balanced
[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md) –
where `raters = "fixed"` and `raters = "random"` give the same point
estimate – here the two genuinely differ. This dataset exists to
demonstrate those incomplete-design behaviors in the "Choosing an ICC"
article.

## See also

[ratings](https://jmgirard.github.io/intraclass/reference/ratings.md)
for the complete, balanced design.

## Examples

``` r
summary(icc(ratings_incomplete, score, subject, rater, seed = 2024))
#> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
#> Subjects: 6 | Raters: 4 (random) | Observations: 20 of 24 cells (incomplete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     estimate   95% CI
#>   ICC(A,1)     0.249   [0.038, 0.693]
#>   ICC(A,k)     0.521   [0.114, 0.881]
#> 
#> ICC(*,k) projects to an effective 3.27 raters (harmonic mean of ratings/subject).
#> Variance components: subject 2.281, rater 5.532, residual 1.344
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
#> 
#> Absolute agreement counts the rater main effect (systematic differences in rater level) as error.
#> A single rating per cell confounds the subject-by-rater interaction with
#> residual error.
```
