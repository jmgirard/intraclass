# Getting started

``` r

library(intraclass)
```

## What an ICC tells you

Suppose several raters each score the same set of things — essays,
patients, video clips — and you want to know whether the scores can be
*trusted*. If two raters watch the same clip, will they land on the same
number? If you swapped in a different rater, would the result hold up?
That is a question about **interrater reliability**, and an **intraclass
correlation coefficient (ICC)** is the number that answers it.

An ICC runs from 0 to 1 and reports **the share of the variation in
scores that reflects real differences between the things being rated**,
rather than disagreement or noise between raters. Near 1, almost all the
spread in scores is genuine subject-to-subject difference and the raters
barely disagree — the ratings are highly reliable. Near 0, the raters
are effectively adding noise, and a score tells you more about who
happened to rate it than about the subject.

`intraclass` estimates that number by fitting a **mixed model** (it
separates subject variation from rater variation as [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component)),
rather than from the classical ANOVA mean-squares formulas older tools
use. The two agree on clean, balanced data but the model-based approach
also handles missing ratings, multiple designs, and honest confidence
intervals — see
[*Engines*](https://jmgirard.github.io/intraclass/articles/engines.md)
for the machinery. This article walks the whole pipeline on a small
example: **fit → estimate → interpret**. (New to any of the terms as
they come up? The
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md)
defines each one in a sentence.)

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
with the data and the three columns (unquoted). With the defaults a
single **two-way random** fit reports every defined formulation —
absolute agreement and consistency, each for a single rater and for the
average of your raters: `ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)`, `ICC(C,k)`
(the next sections unpack these labels). They are grouped by error
definition in the printout. We set a `seed` so the confidence interval
is reproducible.

``` r

fit <- icc(ratings, score, subject, rater, seed = 2024)
fit
#> ── Intraclass correlation: two-way random, absolute agreement & consistency ────
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     estimate   95% CI
#>   Absolute agreement
#>   ICC(A,1)     0.290   [0.050, 0.711]
#>   ICC(A,k)     0.620   [0.173, 0.908]
#>   Consistency
#>   ICC(C,1)     0.715   [0.340, 0.926]
#>   ICC(C,k)     0.909   [0.673, 0.980]
#> 
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
#> # A tibble: 4 × 10
#>   index    type  level sf_index estimate std.error conf.low conf.high conf.level
#>   <chr>    <chr> <chr> <chr>       <dbl>     <dbl>    <dbl>     <dbl>      <dbl>
#> 1 ICC(A,1) agre… NA    ICC(2,1)    0.290    0.180    0.0498     0.711       0.95
#> 2 ICC(A,k) agre… NA    ICC(2,k)    0.620    0.201    0.173      0.908       0.95
#> 3 ICC(C,1) cons… NA    NA          0.715    0.155    0.340      0.926       0.95
#> 4 ICC(C,k) cons… NA    NA          0.909    0.0809   0.673      0.980       0.95
#> # ℹ 1 more variable: method <chr>

glance(fit)
#> # A tibble: 1 × 18
#>   n_subjects n_raters n_clusters n_obs n_cells balanced multilevel ml_design
#>        <int>    <int>      <int> <int>   <int> <lgl>    <lgl>      <chr>    
#> 1          6        4         NA    24      24 TRUE     FALSE      NA       
#> # ℹ 10 more variables: k_eff <dbl>, k_c_eff <dbl>, var_cluster <dbl>,
#> #   var_subject <dbl>, var_rater <dbl>, var_cluster_rater <dbl>,
#> #   var_residual <dbl>, engine <chr>, ci_method <chr>, conf.level <dbl>
```

## Interpret

**Single vs. the average of several raters.** `ICC(A,1)` = 0.29 is the
reliability of a *single* rater — how much you can trust one person’s
score. `ICC(A,k)` = 0.62 is the reliability of the *mean* of all 4
raters. Averaging cancels out independent rater noise, so the mean is
always more reliable than one rater alone (this is the
**Spearman–Brown** relationship: more raters, higher reliability, with
diminishing returns). Report `ICC(A,k)` when the averaged score is what
you will actually use, and `ICC(A,1)` when downstream users see one
rater’s judgment.

**Absolute agreement vs. rank order.** These are **absolute-agreement**
coefficients: if one rater scores consistently higher than another, that
systematic gap counts as error. Here the raters differ sharply in
average level, which is why the agreement ICC is low — a signal that the
rating procedure has a level problem worth fixing. (If you only care
that raters *rank* subjects the same way, ask for *consistency* instead
— see below.)

### Is this a good ICC?

There is no universal cutoff, but two widely cited rules of thumb give a
rough vocabulary. **Koo & Li (2016)** propose:

| ICC       | Label     |
|-----------|-----------|
| \< 0.50   | poor      |
| 0.50–0.75 | moderate  |
| 0.75–0.90 | good      |
| \> 0.90   | excellent |

An older scheme, **Cicchetti (1994)**, draws its lines a little
differently (\< 0.40 poor, 0.40–0.59 fair, 0.60–0.74 good, 0.75–1.00
excellent). Treat these as conventions, not laws: the bar that matters
depends on the stakes of your decision, and on *which* ICC you are
reading (an agreement and a consistency coefficient on the same data are
not comparable to the same cutoff).

Most important — and this is Koo & Li’s own recommendation — **judge the
confidence interval, not just the point estimate.** Here the four-rater
mean `ICC(A,k)` = 0.62 reads as “moderate,” but its 95% interval runs
from 0.17 to 0.91 — from “poor” all the way to “excellent.” With only
six subjects, the data simply cannot pin the reliability down to one
band. That is why
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) never
returns a point estimate without an interval, and never labels a result
for you: the honest summary is the whole interval.

### About the confidence interval

The interval
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
reports is a [**Monte-Carlo**
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval),
and it is
[**boundary-aware**](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary).
In plain terms: instead of relying on a textbook formula that misbehaves
when a variance is near zero (a common situation — raters who barely
differ push the rater variance to its zero boundary),
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
simulates many plausible parameter sets from the fitted model and reads
the interval off the resulting spread of ICCs. This keeps the interval
well-behaved right at that boundary. The [*Interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md)
article covers how it works and the alternatives (a parametric
bootstrap, and Bayesian credible intervals).

## Consistency instead of agreement

If a constant per-rater offset is acceptable — you care only that raters
*rank* subjects the same way, not that they land on the same number —
ask for **consistency** with `type = "consistency"`. It drops the rater
main effect from the error, so it is never smaller than the agreement
coefficient:

``` r

icc(ratings, score, subject, rater, type = "consistency", seed = 2024)
#> ── Intraclass correlation: two-way random, consistency ─────────────────────────
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     estimate   95% CI
#>   ICC(C,1)     0.715   [0.340, 0.926]
#>   ICC(C,k)     0.909   [0.673, 0.980]
#> 
#> Variance components: subject 2.556, rater 5.244, residual 1.019
```

The gap between the two (here `ICC(C,1)` = 0.71 vs. `ICC(A,1)` = 0.29)
is a direct read-out of how much systematic rater-level difference is
present.

By default raters are treated as **random** — a sample you want to
generalize beyond, so that your reliability claim covers raters you did
not use. If your raters are the entire population of interest you can
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
walks that decision step by step.

## References

Cicchetti, D. V. (1994). Guidelines, criteria, and rules of thumb for
evaluating normed and standardized assessment instruments in psychology.
*Psychological Assessment, 6*(4), 284–290.

Koo, T. K., & Li, M. Y. (2016). A guideline of selecting and reporting
intraclass correlation coefficients for reliability research. *Journal
of Chiropractic Medicine, 15*(2), 155–163.

Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: Uses in
assessing rater reliability. *Psychological Bulletin, 86*(2), 420–428.
