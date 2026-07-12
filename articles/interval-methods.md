# Confidence-interval methods

``` r

library(intraclass)
```

A point estimate on its own can mislead — with a handful of subjects the
same ICC could be “poor” or “excellent” and you would not know it. So
every [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
coefficient comes with an interval, never a bare number, and the
`ci_method` argument selects how that interval is built. This article
covers the two frequentist methods — Monte-Carlo and the parametric
bootstrap — and the Bayesian
[**credible**](https://jmgirard.github.io/intraclass/articles/glossary.html#credible-interval)
interval that comes with the brms engine, and when they diverge. (Terms
are defined in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).)

## Monte-Carlo and the parametric bootstrap

Every interval elsewhere in these articles has been the default
[**Monte-Carlo**
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval):
it draws from the fitted parameter covariance on the engine’s log scale
and back-transforms, which is fast and
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary).
A second method, a [**parametric
bootstrap**](https://jmgirard.github.io/intraclass/articles/glossary.html#parametric-bootstrap)
(`ci_method = "bootstrap"`), instead simulates response vectors from the
fitted model, refits, and takes percentile quantiles of the resampled
coefficients. It does not lean on the asymptotic-normal covariance
approximation (the assumption that the estimates are normally
distributed around the truth, which frays in small samples) — at the
cost of a full refit per resample, so it is far slower.

``` r

mc <- tidy(icc(ratings, score, subject, rater, seed = 1))
bs <- tidy(icc(ratings, score, subject, rater,
  ci_method = "bootstrap", boot_samples = 999, seed = 1
))
data.frame(
  index = mc$index,
  estimate = round(mc$estimate, 3),
  mc = sprintf("[%.2f, %.2f]", mc$conf.low, mc$conf.high),
  bootstrap = sprintf("[%.2f, %.2f]", bs$conf.low, bs$conf.high)
)
#>      index estimate           mc    bootstrap
#> 1 ICC(A,1)     0.29 [0.05, 0.71] [0.02, 0.72]
#> 2 ICC(A,k)     0.62 [0.17, 0.91] [0.09, 0.91]
```

The point estimates are identical (same fit) and the upper bounds
coincide; the bootstrap’s lower bounds run a little lower here, because
this is a very small design (six subjects) and the bootstrap’s lower
tail is noisier than the covariance-based Monte-Carlo draw. The two
methods can diverge more where the asymptotics are strained — near the
zero-variance boundary, and for the multilevel designs (more variance
components, often few clusters), where the bootstrap’s cluster-level
interval in particular carries more resampling noise. The bootstrap is
available for every design the `"glmmTMB"` and `"lme4"` engines fit;
`"lavaan"` supports Monte-Carlo only. Raise `boot_samples` (default
`999`) for a smoother interval at proportionally more cost.

## Bayesian credible intervals (`ci_method = "posterior"`)

When the fit is Bayesian (`engine = "brms"`, see [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#a-bayesian-engine-brms)),
the interval is neither a Monte-Carlo nor a bootstrap *confidence*
interval but a **credible** interval read directly off the posterior
draws of the ICC — a [different kind of
statement](https://jmgirard.github.io/intraclass/articles/glossary.html#confidence-interval-vs.-credible-interval)
about where the ICC lies. `ci_method = "posterior"` is automatic — and
required — for that engine.

As in the engines article, the brms chunks below are shown with
pre-computed output (fitting a Stan model needs a toolchain not
available when this site is built), so they are not evaluated at knit
time.

``` r

icc(ratings, score, subject, rater, engine = "brms", seed = 1)
```

    #> # Intraclass correlation: two-way random, absolute agreement
    #> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
    #> Engine: brms (MCMC) | CI: 95% posterior credible (4000 draws)
    #>   index     estimate   95% CI
    #>   ICC(A,1)    0.241   [0.066, 0.649]
    #>   ICC(A,k)    0.679   [0.221, 0.881]
    #> Variance components: subject 1.522, rater 2.653, residual 0.962
    #> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

The point estimate is the [posterior mode
(MAP)](https://jmgirard.github.io/intraclass/articles/glossary.html#posterior-mode-map)
and the default interval is a **percentile** credible interval — the
lower `2.5%` and upper `97.5%` quantiles of the ICC draws. Percentile is
the default because it is invariant to how the ICC is parameterized and
degrades gracefully as a variance component approaches zero (ten Hove et
al. 2020, §4.2, find it nominal at more than two raters).

### Highest-posterior-density intervals

For comparison you can ask for a **highest-posterior-density interval**
(HPDI) — the *narrowest* interval containing 95% of the posterior mass —
with `posterior_summary = "hpdi"`:

``` r

icc(ratings, score, subject, rater, engine = "brms",
  posterior_summary = "hpdi", seed = 1)
```

    #> # Intraclass correlation: two-way random, absolute agreement
    #> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
    #> Engine: brms (MCMC) | CI: 95% posterior credible (HPDI) (4000 draws)
    #>   index     estimate   95% CI
    #>   ICC(A,1)    0.241   [0.040, 0.601]
    #>   ICC(A,k)    0.679   [0.256, 0.904]
    #> Variance components: subject 1.522, rater 2.653, residual 0.962
    #> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

The header now flags `(HPDI)`, and on the same draws the interval is no
wider than the percentile one — that is what “narrowest” means. Here
`ICC(A,1)` is `[0.04, 0.60]` against the percentile `[0.07, 0.65]`; the
point estimate (the MAP) is unchanged. Percentile stays the default,
because HPDI is not transform-invariant and can behave less well at the
variance boundary — it is offered for comparison, not as an upgrade.
