# Estimation engines

``` r

library(intraclass)
```

Most of the time you never think about the
[**engine**](https://jmgirard.github.io/intraclass/articles/glossary.html#engine),
the software that does the fitting. The default just works, and every
example in the other articles uses it. This article is for when you want
to know what that default is doing, or you have a reason to switch. The
`engine` argument of
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
chooses the engine. The engine estimates the [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component),
each a share of the total variation traced to one source. Some engine
choices are purely computational: the same estimator, a different
solver. Others compute a different estimator of the same
[estimand](https://jmgirard.github.io/intraclass/articles/glossary.html#estimand),
the true quantity you are trying to estimate. Those estimators are
asymptotically equivalent: each converges to the same answer as the
sample grows. A third kind of choice moves to a fully Bayesian fit. This
article covers the mixed-model engines (glmmTMB, lme4), the
structural-equation engine (lavaan), and the Bayesian engine (brms). It
also says when the distinction matters. Any unfamiliar term is defined
in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).

## The mixed-model engines: glmmTMB and lme4

By default
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
the variance components with **glmmTMB**. You can instead request
**lme4** with `engine = "lme4"` for the random two-way design, where the
subjects share one set of raters. The lme4 package itself arrives with
the installation, because glmmTMB names lme4 in its own `Imports:`. But
the engine needs one piece more: **merDeriv**. It supplies the parameter
covariance behind the default [Monte-Carlo
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval),
an interval built by simulating from the fitted model. Every lme4 fit
checks for merDeriv on entry, whatever interval method you ask for.
merDeriv sits in `Suggests:` and is fetched only on request. So a plain
install leaves you with the lme4 package but not the lme4 engine. Both
engines are
[REML](https://jmgirard.github.io/intraclass/articles/glossary.html#reml)
mixed-model fits of the same model. REML, restricted maximum likelihood,
is a way to estimate variances that corrects maximum likelihood’s
downward bias. On a given dataset the two engines therefore return the
same coefficients to numerical tolerance. The choice is about the
fitting backend, not the estimand.

``` r

glmmtmb <- tidy(icc(ratings, score, subject, rater, engine = "glmmTMB", seed = 1))
lme4 <- tidy(icc(ratings, score, subject, rater, engine = "lme4", seed = 1))
```

| Point estimates on the ratings data by engine |         |        |
|-----------------------------------------------|---------|--------|
| Coefficient                                   | glmmTMB | lme4   |
| ICC(A,1)                                      | 0.2898  | 0.2898 |
| ICC(A,k)                                      | 0.6201  | 0.6201 |
| ICC(C,1)                                      | 0.7148  | 0.7148 |
| ICC(C,k)                                      | 0.9093  | 0.9093 |

The two point estimates agree to well within rounding, and their
Monte-Carlo intervals coincide to about `0.01`. The lme4 interval is
built from the parameter covariance the **merDeriv** package supplies.
It is transformed onto the same log scale glmmTMB uses, which is
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary):
an estimate can land exactly at zero, and the interval still behaves.
glmmTMB remains the recommended default. It is the engine this package
declares in `Imports:`, and it is robust when a variance component sits
exactly at that zero boundary. At the boundary the lme4 route cannot
form an interval, and directs you back to glmmTMB. lme4 otherwise has
full design parity with glmmTMB. It covers the fixed-rater design, where
the observed raters are the whole population of interest, and every
multilevel design. It does so on balanced **and** incomplete or ragged
data. It degrades to glmmTMB only at that variance boundary.

## A structural-equation engine (`lavaan`)

`engine = "lavaan"` fits the same design as a **structural equation
model** (SEM), for the random two-way design. The model is a
common-factor generalizability model in the sense of Jorgensen (2021).
Unlike lme4, this is not only a different backend for the *same*
estimator. It matters which coefficient you ask for.

``` r

glmmtmb <- tidy(icc(ratings, score, subject, rater, engine = "glmmTMB", seed = 1))
lavaan <- tidy(icc(ratings, score, subject, rater, engine = "lavaan", seed = 1))
```

| Point estimates on the ratings data: mixed model and SEM |  |  |
|----|----|----|
| Coefficient | glmmTMB (mixed model) | lavaan (SEM) |
| ICC(A,1) | 0.2898 | 0.2843 |
| ICC(A,k) | 0.6201 | 0.6137 |
| ICC(C,1) | 0.7148 | 0.7148 |
| ICC(C,k) | 0.9093 | 0.9093 |

**Consistency** coefficients, where raters agree apart from a constant
offset per rater, are a ratio of the subject and residual variances. So
the SEM returns them identically to the mixed model. **Absolute
agreement**, where raters give the same score, is different. The SEM has
no random rater effect to estimate. A rater is a single column, so its
effect lives in the column *means*. Following Jorgensen (2021), the
rater variance is recovered from the mean structure as the variance of
the estimated indicator intercepts. This [**indicator-mean
estimator**](https://jmgirard.github.io/intraclass/articles/glossary.html#indicator-mean-estimator)
reads the rater variance from the estimated column means. It is a
different estimator of the rater variance than the mixed model’s random
effect. The two are asymptotically equivalent: they converge to the same
answer as the sample grows. They match conventional
generalizability-theory software (GENOVA, and formerly the `gtheory`
package) closely on real data \[Vispoel et al. 2022\]. But on a small
design they differ by a modest amount. Here `ICC(A,1)` is about `0.284`
from lavaan versus `0.290` from the mixed model. The gap here comes from
the raw variance of only four estimated rater means. That variance
carries small-sample noise the mixed model shrinks away.

Which is “right”? Neither is wrong: they are two defensible estimators
of the same population quantity. Use `"glmmTMB"` (the default) if you
want the mixed-model random-rater estimate and its wider,
generalize-to-new-raters interval. Reach for `"lavaan"` if you work
inside an SEM generalizability-theory workflow and want results
comparable to that literature. The SEM engine covers the random **and
fixed-rater** two-way design. It covers complete **and incomplete**
data, the latter by
[FIML](https://jmgirard.github.io/intraclass/articles/glossary.html#fiml),
which uses every observed value rather than dropping incomplete cases.
The [parametric
bootstrap](https://jmgirard.github.io/intraclass/articles/glossary.html#parametric-bootstrap),
which refits the model on simulated data many times, is available on
complete data, and Monte-Carlo throughout. It also covers the crossed
(Design 1) **multilevel** design as a two-level SEM. That fit reports
the subject-level ICC and the
[cluster-level](https://jmgirard.github.io/intraclass/articles/glossary.html#subject-level-vs--cluster-level)
ICC, which says how reliably raters distinguish cluster means, off one
five-component fit. That route takes random raters, on balanced data and
on incomplete or unbalanced data alike, and gives a Monte-Carlo
interval. Two-level SEM estimation is full-information ML with no REML
analog. So with few clusters its cluster-level components sit slightly
below the REML estimates, and its agreement rater term slightly above.
Both are documented differences that shrink as the cluster count grows.
Consistency ICCs agree essentially exactly. One-way designs are still
directed to the mixed-model engines.

## A Bayesian engine (`brms`)

`engine = "brms"` fits the variance components in a fully **Bayesian**
framework (Stan, via the **brms** package). This is the approach ten
Hove, Jorgensen & van der Ark (2020) developed for interrater
reliability. Instead of a single REML point with a Monte-Carlo interval,
it samples the posterior of every variance component and reads the ICC
off the draws. The point estimate is the [posterior **mode**
(MAP)](https://jmgirard.github.io/intraclass/articles/glossary.html#posterior-mode-map),
the peak of the posterior distribution. The interval is a [**credible**
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#confidence-interval-vs--credible-interval),
which holds a chosen share, usually 95%, of the posterior probability.
The [*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.html#bayesian-credible-intervals-ci_method-posterior)
article covers it. Because it samples a Stan model, this engine is
slower than the others. It also needs the `brms` package, an optional
`Suggests` dependency. And it places a
[prior](https://jmgirard.github.io/intraclass/articles/glossary.html#prior),
the distribution placed on a parameter before seeing the data, on each
random-effect standard deviation. The last section of this article
covers that prior.

The examples below are shown with pre-computed output. Fitting a Stan
model needs a toolchain not available when this site is built, so these
chunks are not evaluated at knit time. What they show is
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)’s own
printed output. On a design this small the sampler may also report
divergent transitions. Whether it does depends on the seed and the
platform, so those warnings are not reproduced here.

``` r

bayes <- icc(ratings, score, subject, rater, engine = "brms", type = "agreement", seed = 1)
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
six-subject design the MAP `ICC(A,1)` is about `0.24`, a little below
the glmmTMB REML value of `0.29`. The MAP is the mode of a wide,
right-skewed posterior, which the small sample pulls down. That pull is
what ten Hove et al. (2020) note at small rater counts. Sampler settings
pass through `brm_args`: chains, iterations, backend, and parallel
`cores`, as in `brm_args = list(chains = 4, cores = 4)`.

### The prior, and overriding it

By default the engine places a weakly-informative **half-*t*(4, 0, 1)**
prior on every random-effect standard deviation. That is the *sourced*
prior (ten Hove et al. 2020, §3.3/§4.1), and every coverage result in
this package depends on it. You can supply your own prior for
prior-sensitivity or method-comparison work with the `prior` argument,
which takes any brms prior object. But
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) warns
loudly. Leaving the sourced prior **voids the coverage guarantees**, and
a poorly chosen SD prior can *worsen* the small-sample boundary
behavior:

``` r

library(brms)
icc(ratings, score, subject, rater, engine = "brms",
  prior = set_prior("normal(0, 0.1)", class = "sd"), seed = 1)
#> Warning message:
#> Using a custom `prior` instead of the sourced half-t(4, 0, 1).
#> ! This VOIDS the package's coverage guarantees: the credible-interval coverage
#>   results (ten Hove et al. 2020) hold only for the sourced prior.
#> ℹ A vague or flat SD prior can WORSEN small-`k` boundary bias. The half-t is
#>   weakly informative on purpose (Principle #3's regime).
#> ℹ Leave `prior` unset for the sourced default unless you are running
#>   prior-sensitivity or method-comparison work.
```

Here the deliberately over-tight `normal(0, 0.1)` prior squeezes every
standard deviation toward zero. The ICC collapses to nearly nothing. It
is a vivid reminder that the prior is load-bearing, not a casual knob.
Leave `prior` unset unless you specifically intend to depart from the
sourced default. The brms engine covers the same design family as the
mixed-model engines: two-way random and fixed, one-way, and the
multilevel designs. It does so on balanced and incomplete data.
