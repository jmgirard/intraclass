# intraclass

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

> \[!NOTE\] This package is in early development. The first estimator —
> two-way random, absolute-agreement `ICC(A,1)` / `ICC(A,k)` — is the
> current milestone (M1). See `project/MILESTONES.md` for the roadmap.

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

``` r

library(intraclass)
## The icc() interface lands in Milestone 1:
## icc(data, score, subject, rater, type = "agreement", unit = c("single", "average"))
```

## Related work

Classical tools (`psych`, `irr`, `irrNA`, `irrICC`, `ICCDesign`) are
ANOVA / mean-squares based and mostly assume balanced data; model-based
tools (`performance::icc`, `gtheory`, `misty`) extract a
variance-partition coefficient but not the full interrater-reliability
ICC family, the error-variance framing, or a selection framework.
**intraclass** fills that gap with mixed-model estimation, Monte-Carlo
confidence intervals, and decision guidance (following ten Hove,
Jorgensen & van der Ark).
