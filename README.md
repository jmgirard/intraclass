
<!-- README.md is generated from README.Rmd. Please edit that file -->

# intraclass <img src="man/figures/logo.png" align="right" height="139" alt="intraclass hex logo" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/jmgirard/intraclass/actions/workflows/check-standard.yaml/badge.svg)](https://github.com/jmgirard/intraclass/actions/workflows/check-standard.yaml)
[![Codecov test
coverage](https://codecov.io/gh/jmgirard/intraclass/graph/badge.svg)](https://app.codecov.io/gh/jmgirard/intraclass)
<!-- badges: end -->

**intraclass** computes interrater-reliability **intraclass correlation
coefficients (ICCs)** within the generalizability-theory framework,
using **modern variance-component estimation** (linear mixed models)
rather than the classical ANOVA / mean-squares approach.

It aims to (1) fit variance components with modern engines, (2) compute
the *correct* ICC for a stated design with proper (boundary-aware
Monte-Carlo) interval estimation, (3) handle imbalanced, incomplete, and
multilevel designs, and (4) help you decide **which ICC to choose, and
why** — the docs and website are a place to learn ICC best practice, not
just call functions.

> \[!NOTE\] This package is approaching its first release. The full
> interrater-reliability ICC family is implemented — one-way and two-way
> designs (absolute agreement vs. consistency, single vs. average,
> random vs. fixed raters), imbalanced, incomplete (missing-cell) and
> multilevel data — each with boundary-aware Monte-Carlo intervals, on
> any of four engines: `glmmTMB`, `lme4`, `brms` (Bayesian) and `lavaan`
> (SEM).

## Installation

You can install the development version from
[GitHub](https://github.com/jmgirard/intraclass) with:

``` r
# install.packages("pak")
pak::pak("jmgirard/intraclass")
```

intraclass declares `cli`, `generics`, `glmmTMB`, `lifecycle`, `rlang`,
and `tibble` as its non-base `Imports:`. What an installation retrieves
is the full dependency closure of those declarations, which is
considerably larger. One member of that closure is worth naming:
`glmmTMB` lists `lme4` in its own `Imports:`, so the `lme4` package is
already on your library path after a plain install, whatever its
`Suggests:` placement here implies. Having the package is not the same
as having the engine, though — `engine = "lme4"` also needs `merDeriv`,
which every lme4 fit checks for on entry whatever interval method you
ask for. `merDeriv` does not arrive: it sits in this package’s
`Suggests:`, as do `brms` (Bayesian) and `lavaan` (SEM), so a plain
install fetches none of the three — though asking for `merDeriv` brings
`lavaan` along, because `merDeriv` names it in its own `Depends:`.
`glmmTMB` is the only engine a plain install leaves you ready to use.

## Example

`ratings` is the classic Shrout & Fleiss (1979) example, shipped with
the package. With the defaults a single two-way random fit reports every
defined formulation — absolute agreement and consistency, single-rater
and average — grouped by error definition, each with a reproducible
Monte-Carlo interval:

``` r
library(intraclass)

fit <- icc(ratings, score, subject, rater, seed = 2024)
fit
#> ── Intraclass correlation: two-way random, absolute agreement & consistency ────
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   index     estimate   95% CI
#>   Absolute agreement
#>   ICC(A,1)     0.290   [0.053, 0.714]
#>   ICC(A,k)     0.620   [0.183, 0.909]
#>   Consistency
#>   ICC(C,1)     0.715   [0.334, 0.924]
#>   ICC(C,k)     0.909   [0.667, 0.980]
#> 
#> Variance components: subject 2.556, rater 5.244, residual 1.019
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```

`autoplot()` draws the same fit as a forest plot (it needs **ggplot2**):

``` r
library(ggplot2)

autoplot(fit)
```

<img src="man/figures/README-plot-coefficients-1.png" alt="Forest plot of the four coefficients from the ratings fit: ICC(A,1), ICC(A,k), ICC(C,1) and ICC(C,k), each a labelled point with a horizontal Monte-Carlo interval, and the average-rater coefficients further to the right than their single-rater counterparts." width="100%" />

Which coefficient you want — agreement vs. consistency, single
vs. average, fixed vs. random raters, complete vs. incomplete — is a
real modeling decision, and each is an argument to `icc()`. Not sure
which to report? `choose_icc()` walks the [*Choosing an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.html)
decision tree and hands back the coefficient, the reasoning, and the
exact call to run — no data or fitting required:

``` r
choose_icc(model = "twoway", type = "consistency", unit = "average", raters = "random")
#> ── Recommended ICC ─────────────────────────────────────────────────────────────
#> Design: two-way random, consistency
#> 
#> Recommendation: ICC(C,k)
#> 
#> Why:
#>   - Crossed (two-way): the same raters judge every subject.
#>   - Consistency: only the rank order must match; a constant per-rater offset is forgiven.
#>   - Average: you will act on the mean of your raters.
#>   - Random raters: a sample you generalize beyond, to the rater universe they were drawn from.
#> 
#> Run this on your data:
#>   icc(data, score, subject, rater, type = "consistency", unit = "average")
#> 
#> Notes:
#>   - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.
```

For **multilevel** data — subjects nested in clusters (pupils in
classrooms, patients in clinics) — pass a `cluster` column and `icc()`
reports subject-level and cluster-level reliability separately:

``` r
set.seed(1)
grid <- expand.grid(pupil = 1:5, classroom = 1:12, rater = 1:4)
grid$score <- with(grid,
  10 + rnorm(12, sd = 1.2)[classroom] +
    rnorm(60, sd = 0.6)[(classroom - 1) * 5 + pupil] +
    rnorm(4, sd = 0.4)[rater] + rnorm(nrow(grid), sd = 0.7))
school <- data.frame(
  pupil = factor(paste(grid$classroom, grid$pupil, sep = "_")),
  classroom = factor(grid$classroom),
  rater = factor(grid$rater),
  score = grid$score)

icc(school, score, subject = pupil, rater = rater, cluster = classroom, seed = 2024)
#> ℹ Treating raters with the same label in different clusters as the same raters
#>   (crossed with clusters, Design 1).
#> ℹ If each cluster has its own raters, give them cluster-unique labels or pass
#>   `design = "nested_in_clusters"`.
#> ── Intraclass correlation: multilevel two-way random, absolute agreement & consi
#> Subjects: 60 in 12 clusters | Raters: 4 (random) | Observations: 240 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#> 
#>   level      index     estimate   95% CI
#>   Absolute agreement
#>   subject    ICC(A,1)     0.322   [0.162, 0.484]
#>   subject    ICC(A,k)     0.655   [0.436, 0.790]
#>   cluster    ICC(A,1)     0.870   [0.005, 0.973]
#>   cluster    ICC(A,k)     0.964   [0.018, 0.993]
#>   Consistency
#>   subject    ICC(C,1)     0.383   [0.245, 0.544]
#>   subject    ICC(C,k)     0.713   [0.565, 0.827]
#>   cluster    ICC(C,1)     0.995   [0.005, 1.000]
#>   cluster    ICC(C,k)     0.999   [0.018, 1.000]
#> 
#> Variance components: cluster 1.036, subject 0.305, rater 0.150, cluster:rater 0.005, residual 0.492
#> 
#> This message is displayed once per session.
```

## How many raters do you need?

`d_study()` projects the variance components of a fit to other rater
counts, carrying the interval with them — so you can ask what
reliability two raters would buy, or ten, before collecting the data:

``` r
autoplot(d_study(fit, m = 1:10))
```

<img src="man/figures/README-plot-dstudy-1.png" alt="Projected reliability against the number of raters, from 1 to 10, as two rising curves with Monte-Carlo interval bands: consistency above, absolute agreement below, both climbing steeply from one to four raters and flattening after that." width="100%" />

## Learn more

- [*Getting
  started*](https://jmgirard.github.io/intraclass/articles/getting-started.html)
  — the guided tour
- [*Choosing an
  ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.html)
  — the decision guide behind `choose_icc()`
- [*Multilevel
  designs*](https://jmgirard.github.io/intraclass/articles/multilevel-designs.html)
  — incomplete and nested multilevel data
- [*Estimation
  engines*](https://jmgirard.github.io/intraclass/articles/engines.html)
  — what each engine buys you
- [*Confidence-interval
  methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.html)
  — the `ci_method` menu
- [*D-studies and
  replicates*](https://jmgirard.github.io/intraclass/articles/d-studies-and-replicates.html)
  — projection and within-cell replicates
- [*Comparison with other
  packages*](https://jmgirard.github.io/intraclass/articles/comparison-with-other-packages.html)
  — how the numbers line up
- [*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.html)
  — the vocabulary in one place

## Related work

| Approach | Packages | What you get |
|----|----|----|
| Classical ANOVA / mean squares | `psych`, `irr`, `irrNA`, `irrICC`, `ICCDesign` | The ICC family from mean squares, mostly assuming balanced data |
| Model-based variance partition | `performance::icc`, `misty` | A variance-partition coefficient from a fitted model — not the full interrater-reliability family, the error-variance framing, or a selection framework |
| **intraclass** | — | Mixed-model estimation of the full family, boundary-aware Monte-Carlo intervals, and decision guidance |

The decision guidance follows ten Hove, Jorgensen & van der Ark.
