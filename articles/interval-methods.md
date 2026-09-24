# Confidence-interval methods

``` r

library(intraclass)
```

A point estimate on its own can mislead. With a handful of subjects the
same ICC could be “poor” or “excellent” and you would not know it. So
every [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
coefficient comes with an interval, never a bare number, and the
`ci_method` argument selects how that interval is built. This article
covers the default [**Monte-Carlo**
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval),
built by drawing parameter values from the fitted model’s uncertainty.
It also covers the [parametric
bootstrap](https://jmgirard.github.io/intraclass/articles/glossary.html#parametric-bootstrap),
which refits the model on simulated data many times. It then covers the
[four opt-in methods](#the-opt-in-boundary-robust-methods) for the
near-[boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary)
terrain the default struggles on, where an estimate can land exactly at
zero. The first is the [transformed
bootstrap-*t*](https://jmgirard.github.io/intraclass/articles/glossary.html#transformed-bootstrap-t)
(`"npbootstrap"`), which resamples whole subjects and studentizes. The
second is the
[exact-F](https://jmgirard.github.io/intraclass/articles/glossary.html#exact-f-interval)
closed form (`"searle"`), a closed-form interval that assumes normal
data. The third is the
[Burch](https://jmgirard.github.io/intraclass/articles/glossary.html#burch-interval)
closed form (`"burch"`), a closed-form interval with a kurtosis
adjustment. The fourth is the [modified profile
likelihood](https://jmgirard.github.io/intraclass/articles/glossary.html#modified-profile-likelihood)
(`"mpl"`), which profiles the likelihood in the ICC with a small-sample
correction. It is the two-way counterpart, for the design where each
rater is tracked across the subjects they score. It serves only that
design’s balanced, complete, random case with absolute
[agreement](https://jmgirard.github.io/intraclass/articles/glossary.html#absolute-agreement),
where raters give the same score. Last is the Bayesian [**credible**
interval](https://jmgirard.github.io/intraclass/articles/glossary.html#credible-interval),
which holds the share of the posterior probability that the confidence
level sets. That interval comes with the brms
[engine](https://jmgirard.github.io/intraclass/articles/glossary.html#engine),
the software that does the fitting. Terms are defined in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).

## Monte-Carlo and the parametric bootstrap

The Monte-Carlo interval is the default. Use it unless it aborts near
the zero boundary. There, an opt-in method below serves on the design it
is fenced to, and the abort message names one where it can. The
parametric bootstrap is for when you distrust the normal approximation
the default rests on and can afford a full refit per resample. The rest
of this section says what each does and where the two diverge.

Every interval elsewhere in these articles has been the default
Monte-Carlo interval. It draws from the fitted parameter covariance on
the engine’s log scale and back-transforms. That is fast and
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary).
A second method, the parametric bootstrap (`ci_method = "bootstrap"`),
instead simulates response vectors from the fitted model, refits, and
takes percentile quantiles of the resampled coefficients. It does not
lean on the asymptotic-normal covariance approximation, which frays in
small samples. That approximation is the assumption that the estimates
are normally distributed around the truth. The bootstrap costs a full
refit per resample, so it is far slower.

``` r

mc <- tidy(icc(ratings, score, subject, rater, seed = 1))
bs <- tidy(icc(ratings, score, subject, rater,
  ci_method = "bootstrap", boot_samples = 999, seed = 1
))
```

| Monte-Carlo and bootstrap 95% intervals on the ratings data |  |  |  |
|----|----|----|----|
| Coefficient | Estimate | Monte-Carlo | Parametric bootstrap |
| ICC(A,1) | 0.290 | \[0.05, 0.71\] | \[0.02, 0.72\] |
| ICC(A,k) | 0.620 | \[0.17, 0.91\] | \[0.09, 0.91\] |
| ICC(C,1) | 0.715 | \[0.33, 0.93\] | \[0.15, 0.90\] |
| ICC(C,k) | 0.909 | \[0.67, 0.98\] | \[0.41, 0.97\] |

The point estimates are identical (same fit). The bootstrap’s lower
bounds run markedly lower. This is a very small design (six subjects),
and the bootstrap’s lower tail is noisier than the covariance-based
Monte-Carlo draw. Its upper bounds sit close to the Monte-Carlo ones,
close enough that ICC(A,k)’s two upper bounds round alike above. But
they are not identical, and they do not all fall on the same side. The
two methods can diverge more where the asymptotics are strained. One
such place is near the [zero-variance
boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary).
Another is the multilevel designs, which carry more [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component),
each a share of the total variation traced to one source, and often few
clusters. In the multilevel case the subject level is reliability within
a cluster, and the cluster level is reliability of cluster means. There
the bootstrap’s
[cluster-level](https://jmgirard.github.io/intraclass/articles/glossary.html#subject-level-vs--cluster-level)
interval in particular carries more resampling noise. The bootstrap is
available for every design the `"glmmTMB"` and `"lme4"` engines fit. The
`"lavaan"` engine bootstraps complete data, and a multilevel lavaan fit
needs balanced clusters and random raters besides. Anywhere off those
fences lavaan is Monte-Carlo only. Resamples cannot reproduce a
missingness pattern. The two-level factory reads the raw rater component
and is random-only. And the two-level bootstrap was validated on
balanced clusters. Raise `boot_samples` (default `999`) for a smoother
interval at proportionally more cost.

### When the default under-covers

The boundary is not the default’s only weak spot, and the other one is
easier to miss because nothing about the output looks wrong. The
Monte-Carlo draw assumes the fitted parameters are approximately
normally distributed around the truth. That assumption is about the
*estimates*, not the ratings. But it degrades when the **subject
effects** are strongly skewed or heavy-tailed. Then a nominal 95%
interval covers considerably less often than 95% of the time.

A one-way simulation study measured this across four subject-effect
distributions. Where the default produced an interval at all, coverage
fell to 0.6725 at its worst. That worst cell had chi-square(1) subject
effects, a true ICC of 0.6, 50 subjects and 5 raters. Those runs did not
abort, warn, or widen, so the shortfall is invisible in the interval
itself.

Two patterns in that study are worth carrying away, and one tempting
reading of it is wrong. At 5 raters per subject, coverage falls as the
subject count rises, once the true ICC is moderate or high. The largest
designs are the exposed ones, not the smallest. And near-normal or
uniform subject effects under-covered only in cells where many runs
aborted. Wherever the default almost always returned an interval, those
distributions were fine. The wrong reading is that fewer raters is
safer. In every cell where both were measured, 2 raters covered worse
than 5. What changes is that a larger share of the 2-rater runs abort
outright. An abort is a visible failure rather than a quiet one.

The held-out battery agrees where the geometry matches. Lognormal and
Laplace subject effects covered 0.825 and 0.84 at that same 50-subject,
5-rater geometry. Their 20-subject, 3-rater cells came out near nominal.

The natural reaction, switching to a closed form, does not help. In
every cell where the default under-covered without also aborting often,
`"searle"` and `"burch"` under-covered as well, usually by more.
`"burch"`, the one this article used to recommend for heavy tails,
bottoms out at 0.6655. The remaining methods were never run on that
study, so this article recommends none of them in its place.

What to do instead is ordinary statistical hygiene rather than a package
setting. Look at the distribution of the subject means before trusting a
narrow interval. Report the variance components alongside the
coefficient. And treat an interval on visibly skewed data as optimistic
about its own precision.

## The opt-in boundary-robust methods

Near the [zero-variance
boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary)
the Monte-Carlo default can fail to produce an interval. When it aborts,
its message names an alternative method where one serves your data. It
chooses that method by running the candidates on your own data rather
than by consulting a table. So in practice you rarely need to pick one
from scratch. This section is for when you do. Four opt-in methods serve
exactly that terrain. Each is fenced to a specific design and aborts
with a classed error anywhere else.

### The transformed bootstrap-*t* (`ci_method = "npbootstrap"`)

This is one method for a one-way random design when the Monte-Carlo
default aborts near the boundary. It also serves when you doubt that the
subject effects are normal. It is the one opt-in method that handles
unbalanced one-way data. The cost is resampling time, and a seed to pin.

The non-parametric [**transformed
bootstrap-*t***](https://jmgirard.github.io/intraclass/articles/glossary.html#transformed-bootstrap-t)
of Ukoumunne et al. (2003) serves the **one-way random design**
(`model = "oneway"`), on balanced and unbalanced data alike. Of the four
opt-in methods it is the only one that serves unbalanced one-way data.
It resamples whole subjects with replacement rather than simulating from
the fitted model. So it is the only opt-in method that takes a `seed`
(and `boot_samples`). Pin both for a reproducible interval. Any
`conf_level` in `(0, 1)` is accepted. `unit = "average"`, the ICC(k), is
the exact monotone Spearman-Brown image of the ICC(1) endpoints. So its
coverage is inherited by construction, balanced or not. A numeric `unit`
is a
[D-study](https://jmgirard.github.io/intraclass/articles/glossary.html#d-study-decision-study)
projection, which projects the fitted variance components to other rater
or
[occasion](https://jmgirard.github.io/intraclass/articles/glossary.html#occasion-within-cell-replicate)
counts. Here it projects to the mean of `m` raters. That projection is
restricted to balanced data. Reach for this method for boundary
robustness, an interval that exists where the Monte-Carlo default
aborts. Reach for it too for robustness to non-normal subject effects.
Its endpoints are deliberately left untruncated on the estimator’s own
support (Ukoumunne et al. 2003, §5.2). So a near-boundary lower limit
can be negative. That is honest disclosure, not an error.

### The classical closed forms (`ci_method = "searle"` and `"burch"`)

These two are for a balanced one-way random design when the Monte-Carlo
default aborts near a zero ICC. Prefer `"searle"`. It is exact under
normality, and in the skew study it landed closer to nominal coverage in
most cells. `"burch"` adjusts for the tails of your data, but that
adjustment is not a remedy for heavy tails. On strongly skewed subject
effects `"burch"` under-covers about as badly as the default.

Two deterministic classical intervals serve the **balanced one-way
random design**. They are closed forms with no resampling, so
`mc_samples`, `boot_samples`, and `seed` do not apply and no `std.error`
is reported. Any `conf_level` in `(0, 1)` is accepted. Both project
ICC(k) through the same Spearman-Brown image as `"npbootstrap"`, and a
numeric `unit` with it. The [**exact-F
interval**](https://jmgirard.github.io/intraclass/articles/glossary.html#exact-f-interval)
(`"searle"`; Searle 1971, the McGraw & Wong 1996 Table 7 limits) is
exact under normality. It is best-calibrated when the data are
approximately normal. The [**Burch
interval**](https://jmgirard.github.io/intraclass/articles/glossary.html#burch-interval)
(`"burch"`; Burch 2011) is
[REML](https://jmgirard.github.io/intraclass/articles/glossary.html#reml)-based
and kurtosis-adjusted. REML, restricted maximum likelihood, is a way to
estimate variances that corrects maximum likelihood’s downward bias.
`"burch"`’s width tracks the data’s tail weight, which buys it some
robustness to mild non-normality. It is not, however, a remedy for heavy
tails. On strongly skewed subject effects it under-covers about as badly
as the default (see [When the default
under-covers](#when-the-default-under-covers)).

**Which is the tighter interval?** Neither, reliably, and the margin
between them is not constant. The larger grid’s 64 cells span four
distribution families. There `"burch"` is the *narrower* of the two in
59 of 64 cells of the larger grid. How much narrower depends on where in
the design you look. Below, the median width ratio is `"burch"`’s width
over `"searle"`’s. A value under 1 means `"burch"` is narrower, and 1
means they are the same width.

| true ICC | median width ratio | `"burch"` narrower |
|---------:|-------------------:|-------------------:|
|     0.05 |             0.9485 |           16 of 16 |
|      0.1 |             0.9470 |           16 of 16 |
|      0.3 |             0.9475 |           16 of 16 |
|      0.6 |             0.9971 |           11 of 16 |

| subjects (at 5 raters) | median width ratio | `"burch"` narrower |
|-----------------------:|-------------------:|-------------------:|
|                     10 |             0.9154 |           15 of 16 |
|                     30 |             0.9646 |           15 of 16 |
|                     50 |             0.9769 |           13 of 16 |

Two things to read off. The first is the pattern along the true ICC.
`"burch"`’s width advantage holds much the same up to a true ICC of 0.3
rather than shrinking as the true ICC rises (on the larger grid; the
smaller grid’s margin does shrink across its levels). On the larger
grid, measured by level medians the largest margin is at a true ICC of
0.1, not at the bottom of the range. Cell by cell, though, `"burch"`’s
width margin is the larger one at the bottom level in 11 of 16 paired
cells. The advantage then collapses to near parity at a true ICC of 0.6,
on the one grid reaching that value. Every cell favouring `"searle"`
sits at that level on that grid. The second pattern is along the subject
count: there `"burch"`’s width margin shrinks steadily as the subject
count grows, measured at 5 raters. That is the cut the second table
takes. That cut is at 5 raters because 10 subjects is the only subject
count in either grid where the rater count varies. An unstratified row
there would be confounded with the rater count. The smaller grid’s 16
cells carry only the two lowest true-ICC values. So that sweep cannot
show the first pattern, but it shows the second in the same direction.
`"burch"` runs narrower there by a median width ratio of 0.9017 at 10
subjects, 0.9611 at 30 subjects and 0.9775 at 50 subjects.

A pooled figure over both grids that vary only the subject effect would
hide all of this, and it would invite a second misreading. The smaller
grid’s design points are a subset of the larger one’s. So much of the
gap between their pooled medians is which true-ICC values each grid
covers, rather than a disagreement between two bodies of evidence. But
only much of it. Restricting the larger grid to the smaller one’s design
points closes most of that gap and leaves a remainder. The two are
separate simulations that mostly disagree at the design points they
share, agreeing closely at only a couple of them. A pooled between-grid
comparison is not a clean contrast in either direction. So nothing above
is one.

Both of the grids above draw the **subject effects** alone from the
non-normal family. They always draw the errors from a normal, and that
is not an incidental detail. Burch’s own expected-length comparison is
against this very exact-F interval, and it is kurtosis-conditional. He
finds his interval shorter for light-tailed data but *wider* for
symmetric heavy-tailed data. He measures with the subject effects and
the errors alike drawn from the studied family. A third grid now
measures that residual case here. What `"burch"` does against `"searle"`
depends on what the residual is drawn from. Read together, the three
grids measure that: the two grids that vary only the subject effect put
it narrower nearly everywhere, while the third, which draws the residual
from the same family as the subject effect, puts it wider at every
symmetric heavy-tailed family measured (a median width ratio of 1.2963
at t(5) with 100 subjects) and narrower at every lighter-tailed one, the
normal included. So the honest summary is that the ordering depends on
the data, on what the residual is drawn from most of all. You should not
pick between them on width.

Prefer `"searle"`: across every distribution family in that skew study
it landed closer to nominal coverage in most cells, heavy-tailed ones
included. What `"burch"` buys is dipping below the nominal level in
fewer cells overall. That is a more limited kind of steadiness than its
kurtosis adjustment suggests. Their value over the default is a finite,
well-calibrated interval at the near-zero-ICC boundary where the
Monte-Carlo default aborts. One asymmetry between the siblings: on data
with *no* between-subject variance at all, `"burch"` aborts while
`"searle"` still returns an interval. The Burch abort happens because
its kurtosis standardization divides by zero there. Read that `"searle"`
interval carefully. The single-rater coefficient, the reliability of one
rater’s score, gets the attained minimum. The averaged projection
carries that minimum through the Spearman-Brown pole to negative
infinity, which a default call prints beside it.

``` r

mc <- tidy(icc(ratings, score, subject, rater, model = "oneway", seed = 1))
se <- tidy(icc(ratings, score, subject, rater,
  model = "oneway", ci_method = "searle"
))
bu <- tidy(icc(ratings, score, subject, rater,
  model = "oneway", ci_method = "burch"
))
np <- tidy(icc(ratings, score, subject, rater,
  model = "oneway", ci_method = "npbootstrap", boot_samples = 199, seed = 1
))
```

| One-way 95% intervals on the ratings data by method |  |  |  |  |  |
|----|----|----|----|----|----|
| Coefficient | Estimate | Monte-Carlo | Searle | Burch | Nonparametric bootstrap |
| ICC(1) | 0.166 | \[0.01, 0.83\] | \[−0.13, 0.72\] | \[−0.13, 0.56\] | \[−0.05, 0.89\] |
| ICC(k) | 0.443 | \[0.03, 0.95\] | \[−0.88, 0.91\] | \[−0.90, 0.84\] | \[−0.26, 0.97\] |

All four columns share the same point estimate: `ci_method` selects the
interval, never the estimator. The visible difference is at the lower
end. The three opt-in methods’ lower limits dip below zero, because
their endpoints are left untruncated on the estimator’s own support. The
Monte-Carlo interval stays inside the range. And the Burch adjustment is
empirical, not a one-way widening. Here it comes out *narrower* than the
exact-F interval, because its width tracks the tail weight these
particular data actually show. That is the same direction the grids
above measure.

### The modified profile likelihood (`ci_method = "mpl"`)

This is the method for a balanced, complete two-way random design with
absolute agreement, where raters give the same score. Reach for it when
the Monte-Carlo default aborts near a zero ICC. It is conservative by
design: it gives a wider interval than the default at ordinary interior
cells. Expect a cautious interval when you use it.

The [**modified profile-likelihood
interval**](https://jmgirard.github.io/intraclass/articles/glossary.html#modified-profile-likelihood)
of Xiao & Liu (2013) is the two-way counterpart. It serves the
**balanced, complete two-way random absolute-agreement** ICC(A,1), where
raters give the same score. ICC(A,k) and any numeric-`unit` projection
are its pole-safe Spearman-Brown image. It aborts on any other design.
That includes
[consistency](https://jmgirard.github.io/intraclass/articles/glossary.html#consistency),
where raters agree apart from a constant offset per rater. It includes
[fixed](https://jmgirard.github.io/intraclass/articles/glossary.html#fixed-vs--random-raters)
raters, where the observed raters are the whole population of interest.
And it includes unbalanced or incomplete data. It is a deterministic
closed form: no resampling, no `seed`. Its calibration fixes two fences.
`conf_level` must be 0.90, 0.95, or 0.99, since each level carries its
own calibrated correction constant, never interpolated between levels.
The calibration grid spans 2–10 raters and 10–100 subjects. Like
`"npbootstrap"`, it returns an interval at the near-zero-ICC boundary
where the two-way Monte-Carlo default aborts. It is deliberately
conservative: it over-covers and is wider than the Monte-Carlo interval
at interior cells. So it is an opt-in and not the default. Two reporting
caveats come from
[`?icc`](https://jmgirard.github.io/intraclass/reference/icc.md). The
two-sided interval is not equal-tailed, so a limit must not be read as a
one-sided bound at half the complementary level. Separately, at
`conf_level = 0.99` with two raters the interval can be near-vacuous.

The shipped `ratings` data are too small for the calibration grid (six
subjects). So the demonstration uses the shipped `ratings_twoway` data
instead. They are a simulated balanced two-way design with 20 subjects
and 4 raters (see
[`?ratings_twoway`](https://jmgirard.github.io/intraclass/reference/ratings_twoway.md)):

``` r

mc2 <- tidy(icc(ratings_twoway, score, subject, rater, type = "agreement", seed = 1))
ml <- tidy(icc(ratings_twoway, score, subject, rater, type = "agreement", ci_method = "mpl"))
```

| Monte-Carlo and modified profile-likelihood 95% intervals on ratings_twoway |  |  |  |
|----|----|----|----|
| Coefficient | Estimate | Monte-Carlo | Modified profile likelihood |
| ICC(A,1) | 0.709 | \[0.48, 0.84\] | \[0.42, 0.87\] |
| ICC(A,k) | 0.907 | \[0.78, 0.96\] | \[0.75, 0.96\] |

The two point estimates agree, from the same REML fit. The `"mpl"`
interval is the wider of the pair at this comfortably interior cell.
That is the conservatism described above, visible on ordinary data.

## Bayesian credible intervals (`ci_method = "posterior"`)

This interval comes with the brms engine, and it is the interval to use
when you fit with that engine. `ci_method = "posterior"` is automatic
there, and required. You choose it by choosing the engine, not the other
way round.

When the fit is Bayesian (`engine = "brms"`, see [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#a-bayesian-engine-brms)),
the interval is neither a Monte-Carlo nor a bootstrap *confidence*
interval. It is a **credible** interval read directly off the posterior
draws of the ICC, a [different kind of
statement](https://jmgirard.github.io/intraclass/articles/glossary.html#confidence-interval-vs--credible-interval)
about where the ICC lies.

As in the engines article, the brms chunks below are shown with
pre-computed output, so they are not evaluated at knit time. Fitting a
Stan model needs a toolchain not available when this site is built.

``` r

icc(ratings, score, subject, rater, engine = "brms", type = "agreement", seed = 1)
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

The point estimate is the [posterior mode
(MAP)](https://jmgirard.github.io/intraclass/articles/glossary.html#posterior-mode-map),
the peak of the posterior distribution. The default interval is a
**percentile** credible interval: the lower `2.5%` and upper `97.5%`
quantiles of the ICC draws. Percentile is the default because it is
invariant to how the ICC is parameterized. It also degrades gracefully
as a variance component approaches zero (ten Hove et al. 2020, §4.2).
They find it nominal at more than two raters.

### Highest-posterior-density intervals

For comparison you can ask for a **highest-posterior-density interval**
(HPDI), the *narrowest* interval containing 95% of the posterior mass.
Request it with `posterior_summary = "hpdi"`:

``` r

icc(ratings, score, subject, rater, engine = "brms",
  type = "agreement", posterior_summary = "hpdi", seed = 1)
```

    #> ── Intraclass correlation: two-way random, absolute agreement ──────────────────
    #> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
    #> Engine: brms (MCMC) | CI: 95% posterior credible (HPDI) (4000 draws)
    #>
    #>   index     estimate   95% CI
    #>   ICC(A,1)     0.241   [0.040, 0.601]
    #>   ICC(A,k)     0.679   [0.256, 0.904]
    #>
    #> Variance components: subject 1.522, rater 2.653, residual 0.962
    #> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)

The header now flags `(HPDI)`, and on the same draws the interval is no
wider than the percentile one. That is what “narrowest” means. Here
`ICC(A,1)` is `[0.04, 0.60]` against the percentile `[0.07, 0.65]`, and
the point estimate (the MAP) is unchanged. Percentile stays the default,
because HPDI is not transform-invariant and can behave less well at the
variance boundary. It is offered for comparison, not as an upgrade.
