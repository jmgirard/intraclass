# Simulated multilevel ratings with missing cells

Simulated data, not a real study.
[school](https://jmgirard.github.io/intraclass/reference/school.md) with
a fifth of its rows removed at random, so 256 of the 320 ratings remain.
Missing cells are dropped rows, not `NA`s. Every rater still scores
pupils in every classroom, so both ICC levels stay identified. The
"Multilevel designs" article uses it to show a ragged multilevel design.

## Usage

``` r
school_incomplete
```

## Format

A data frame with 256 rows and 4 columns, as in
[school](https://jmgirard.github.io/intraclass/reference/school.md)
(`classroom`, `pupil`, `rater`, `score`).

## Source

Derived from
[school](https://jmgirard.github.io/intraclass/reference/school.md) by
`data-raw/make-vignette-data.R` with `set.seed(11)`, which picks the 64
rows to drop.

## See also

[school](https://jmgirard.github.io/intraclass/reference/school.md) for
the complete design.

## Examples

``` r
str(school_incomplete)
#> 'data.frame':    256 obs. of  4 variables:
#>  $ classroom: Factor w/ 16 levels "1","2","3","4",..: 1 1 1 1 1 2 2 2 2 3 ...
#>  $ pupil    : Factor w/ 80 levels "1_1","1_2","1_3",..: 1 2 3 4 5 7 8 9 10 11 ...
#>  $ rater    : Factor w/ 4 levels "1","2","3","4": 1 1 1 1 1 1 1 1 1 1 ...
#>  $ score    : num  10.5 10.1 10 11.7 9 ...
```
