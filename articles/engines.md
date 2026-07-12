# Estimation engines

``` r

library(intraclass)
```

Most of the time you never think about the engine: the default just
works, and every example in the other articles uses it. This article is
for when you want to know what that default is doing, or you have a
reason to switch. An
[**engine**](https://jmgirard.github.io/intraclass/articles/glossary.html#engine)
is the computational backend
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) uses
to estimate the [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component)
— chosen with the `engine` argument. Some engine choices are purely
computational — the same estimator, a different solver — while others
compute a genuinely different (though asymptotically equivalent:
converging to the same answer as the sample grows) estimator, or move to
a fully Bayesian fit. This article covers the mixed-model engines
(glmmTMB, lme4), the structural-equation engine (lavaan), and the
Bayesian engine (brms), and when the distinction matters. Any unfamiliar
term is defined in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).

## The mixed-model engines: glmmTMB and lme4

By default
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
the variance components with **glmmTMB**. You can instead request
**lme4** with `engine = "lme4"` for the random two-way design. Both are
[REML](https://jmgirard.github.io/intraclass/articles/glossary.html#reml)
mixed-model fits of the same model (REML — restricted maximum likelihood
— is the standard way to estimate variance components), so on a given
dataset they return the same coefficients to numerical tolerance — the
choice is about the fitting backend, not the estimand.

``` r

glmmtmb <- tidy(icc(ratings, score, subject, rater, engine = "glmmTMB", seed = 1))
lme4 <- tidy(icc(ratings, score, subject, rater, engine = "lme4", seed = 1))
data.frame(
  index = glmmtmb$index,
  glmmTMB = round(glmmtmb$estimate, 4),
  lme4 = round(lme4$estimate, 4)
)
#>      index glmmTMB   lme4
#> 1 ICC(A,1)  0.2898 0.2898
#> 2 ICC(A,k)  0.6201 0.6201
```

The two point estimates agree to well within rounding, and their
Monte-Carlo intervals coincide to about `0.01`: the lme4 interval is
built from the parameter covariance supplied by the **merDeriv**
package, transformed onto the same boundary-aware log-scale glmmTMB
uses. glmmTMB remains the recommended default — it is the one required
dependency and it is robust when a variance component sits exactly at
the [zero
boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary),
where the lme4 route cannot form an interval and directs you back to
glmmTMB. lme4 otherwise has full design parity with glmmTMB — the
fixed-rater and every multilevel design, on balanced **and**
incomplete/ragged data — degrading to glmmTMB only at that variance
boundary.

## A structural-equation engine (`lavaan`)

`engine = "lavaan"` fits the same design as a **structural equation
model** — a common-factor generalizability model in the sense of
Jorgensen (2021) — for the random two-way design. Unlike lme4, this is
not just a different backend for the *same* estimator: it matters which
coefficient you ask for.

``` r

axes <- expand.grid(
  type = c("agreement", "consistency"),
  unit = c("single", "average"),
  stringsAsFactors = FALSE
)
compare <- do.call(rbind, Map(function(type, unit) {
  g <- icc(ratings, score, subject, rater, type = type, unit = unit,
           engine = "glmmTMB", seed = 1)
  l <- icc(ratings, score, subject, rater, type = type, unit = unit,
           engine = "lavaan", seed = 1)
  data.frame(
    index = tidy(g)$index,
    glmmTMB = round(tidy(g)$estimate, 4),
    lavaan = round(tidy(l)$estimate, 4)
  )
}, axes$type, axes$unit))
compare[!duplicated(compare$index), ]
#>                 index glmmTMB lavaan
#> agreement    ICC(A,1)  0.2898 0.2843
#> consistency  ICC(C,1)  0.7148 0.7148
#> agreement1   ICC(A,k)  0.6201 0.6137
#> consistency1 ICC(C,k)  0.9093 0.9093
```

**Consistency** coefficients are a ratio of the subject and residual
variances, so the SEM returns them identically to the mixed model.
**Absolute agreement** is different. The SEM has no random rater effect
to estimate — a rater is a single column, so its effect lives in the
column *means*. Following Jorgensen (2021), the rater variance is
recovered from the mean structure as the variance of the estimated
indicator intercepts. This [**indicator-mean
estimator**](https://jmgirard.github.io/intraclass/articles/glossary.html#indicator-mean-estimator)
is a genuinely different estimator of the rater variance than the mixed
model’s random effect: the two are asymptotically equivalent and match
conventional generalizability-theory software (GENOVA, `gtheory`)
closely on real data \[Vispoel et al. 2022\], but on a small design they
differ by a modest amount — here `ICC(A,1)` is about `0.284` from lavaan
versus `0.290` from the mixed model, because the raw variance of only
four estimated rater means carries small-sample noise the mixed model
shrinks away.

Which is “right”? Neither is wrong — they are two defensible estimators
of the same population quantity. Use `"glmmTMB"` (the default) if you
want the mixed-model random-rater estimate and its wider,
generalize-to-new-raters interval; reach for `"lavaan"` if you are
working inside an SEM generalizability-theory workflow and want results
comparable to that literature. The SEM engine covers the random **and
fixed-rater** two-way design, on complete **and incomplete**
([FIML](https://jmgirard.github.io/intraclass/articles/glossary.html#fiml))
data — the parametric bootstrap is available on complete data,
Monte-Carlo throughout. One-way and multilevel designs are still
directed to the mixed-model engines.

## A Bayesian engine (`brms`)

`engine = "brms"` fits the variance components in a fully **Bayesian**
framework (Stan, via the **brms** package) — the approach ten Hove,
Jorgensen & van der Ark (2020) developed for interrater reliability.
Instead of a single REML point with a Monte-Carlo interval, it samples
the posterior of every variance component and reads the ICC off the
draws: the point estimate is the [posterior **mode**
(MAP)](https://jmgirard.github.io/intraclass/articles/glossary.html#posterior-mode-map)
and the interval is a **credible** interval (covered in
[*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.html#bayesian-credible-intervals-ci_method-posterior)).
Because it samples a Stan model, this engine is slower than the others
and needs the `brms` package (an optional `Suggests` dependency).

The examples below are shown with pre-computed output: fitting a Stan
model needs a toolchain not available when this site is built, so these
chunks are not evaluated at knit time.

``` r

bayes <- icc(ratings, score, subject, rater, engine = "brms", seed = 1)
bayes
```

    #> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
    #> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
    #> Engine: brms (MCMC) | CI: 95% posterior credible (4000 draws)
    #>
    #>   index     estimate   95% CI
    #>   ICC(A,1)     0.241   [0.066, 0.649]
    #>   ICC(A,k)     0.679   [0.221, 0.881]
    #>
    #> Variance components: subject 1.522, rater 2.653, residual 0.962
    #> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

The header names a **brms (MCMC)** engine and a **posterior credible**
interval, and `ci_method = "posterior"` is automatic. On this tiny
six-subject design the MAP `ICC(A,1)` (about `0.24`) sits a little below
the glmmTMB REML value (`0.29`): the MAP is the mode of a wide,
right-skewed posterior, which the small sample pulls down (ten Hove et
al. 2020 note this at small rater counts). Sampler settings — chains,
iterations, backend, parallel `cores` — pass through `brm_args`, e.g.
`brm_args = list(chains = 4, cores = 4)`.

### The prior, and overriding it

By default the engine places a weakly-informative **half-*t*(4, 0, 1)**
[prior](https://jmgirard.github.io/intraclass/articles/glossary.html#prior)
on every random-effect standard deviation — the *sourced* prior (ten
Hove et al. 2020, §3.3/§4.1) that every coverage result in this package
depends on. You can supply your own prior for prior-sensitivity or
method-comparison work with the `prior` argument (any brms prior
object), but
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) warns
loudly, because leaving the sourced prior **voids the coverage
guarantees** and a poorly chosen SD prior can *worsen* the small-sample
boundary behavior:

``` r

library(brms)
icc(ratings, score, subject, rater, engine = "brms",
  prior = set_prior("normal(0, 0.1)", class = "sd"), seed = 1)
#> Warning message:
#> Using a custom `prior` instead of the sourced half-t(4, 0, 1).
#> ! This VOIDS the package's coverage guarantees: the credible-interval coverage
#>   results (ten Hove et al. 2020) hold only for the sourced prior.
#> i A vague or flat SD prior can WORSEN small-`k` boundary bias -- the half-t is
#>   weakly informative on purpose (Principle #3's regime).
#> i Leave `prior` unset for the sourced default unless you are running
#>   prior-sensitivity or method-comparison work.
```

Here the deliberately over-tight `normal(0, 0.1)` prior squeezes every
standard deviation toward zero, collapsing the ICC to nearly nothing — a
vivid reminder that the prior is load-bearing, not a casual knob. Leave
`prior` unset unless you specifically intend to depart from the sourced
default. The brms engine covers the same design family as the
mixed-model engines (two-way random and fixed, one-way, and the
multilevel designs), on balanced and incomplete data.
