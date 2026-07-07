
<!-- README.md is generated from README.Rmd. Please edit that file -->

# intraclass

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

> \[!NOTE\] This package is in active development. The two-way designs
> are implemented: absolute-agreement and consistency ICCs, single and
> average, random and fixed raters, and imbalanced/incomplete
> (missing-cell) designs — each with boundary-aware Monte-Carlo
> intervals. A [*Choosing an
> ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.html)
> decision guide and D-study projection to other rater counts
> (`d_study()`) have shipped; multilevel designs are next. See
> `project/MILESTONES.md` for the roadmap.

## Installation

You can install the development version from
[GitHub](https://github.com/jmgirard/intraclass) with:

``` r
# install.packages("pak")
pak::pak("jmgirard/intraclass")
```

The base install is light — only `glmmTMB`, `cli`, `rlang`, and
`generics`. Optional Bayesian and SEM engines live in `Suggests`.

## Example

`ratings` is the classic Shrout & Fleiss (1979) example, shipped with
the package. The defaults give the two-way random, absolute-agreement
`ICC(A,1)` and `ICC(A,k)` with a reproducible Monte-Carlo interval:

``` r
library(intraclass)

icc(ratings, score, subject, rater, seed = 2024)
#> # Intraclass correlation: two-way random, absolute agreement
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(A,1)    0.290   [0.053, 0.715]
#>   ICC(A,k)    0.620   [0.182, 0.910]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```

Which coefficient you want — agreement vs. consistency, single
vs. average, fixed vs. random raters, complete vs. incomplete — is a
real modelling decision. The [*Choosing an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.html)
guide walks through it.

## Related work

Classical tools (`psych`, `irr`, `irrNA`, `irrICC`, `ICCDesign`) are
ANOVA / mean-squares based and mostly assume balanced data; model-based
tools (`performance::icc`, `gtheory`, `misty`) extract a
variance-partition coefficient but not the full interrater-reliability
ICC family, the error-variance framing, or a selection framework.
**intraclass** fills that gap with mixed-model estimation, Monte-Carlo
confidence intervals, and decision guidance (following ten Hove,
Jorgensen & van der Ark).
