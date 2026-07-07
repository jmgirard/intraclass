# Advanced: imbalanced & multilevel designs

## Beyond the balanced case

This article covers where the mixed-model approach earns its keep:

- **Multilevel ICCs** — subject-level vs. cluster-level coefficients
  (below).
- **Engine choice** — linear mixed models vs. SEM vs. Bayesian, and when
  each matters (a forthcoming milestone).
- **Confidence-interval methods** — Monte-Carlo (the default) and its
  alternatives, especially near the zero-rater-variance boundary.

Incomplete and imbalanced designs are already supported; the [*Choosing
an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)
article works through a connected incomplete design, the effective
number of raters `k_eff`, and why fixed and random raters diverge once
cells are missing.

## How many raters do I need? A D-study

`ICC(*,1)` is the reliability of a *single* rater and `ICC(*,k)` the
reliability of the mean of the `k` raters you actually used. A
**decision (D-) study** asks a forward-looking question: *how reliable
would the mean of some other number of raters `m` be?* In
generalizability theory the absolute-agreement ICC is the dependability
coefficient, and projecting it to `m` raters is just a change of the
averaging divisor,

``` math
\Phi(m) = \frac{\sigma^2_s}{\sigma^2_s + (\sigma^2_r + \sigma^2_{res}) / m},
```

so
[`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
reuses the fit you already have — no refitting.

``` r

library(intraclass)

fit <- icc(ratings, score, subject, rater, seed = 1)
proj <- d_study(fit, m = 1:8)
proj
#> # D-study projection: two-way random, absolute agreement
#> Observed raters: 4 | CI: 95% montecarlo (10000 draws)
#>       m  estimate   95% CI
#>       1     0.290   [0.050, 0.712]
#>       2     0.449   [0.095, 0.831]
#>       3     0.550   [0.136, 0.881]
#>       4     0.620   [0.173, 0.908]
#>       5     0.671   [0.207, 0.925]
#>       6     0.710   [0.239, 0.937]
#>       7     0.741   [0.268, 0.945]
#>       8     0.765   [0.295, 0.952]
```

Reliability climbs with more raters but with diminishing returns, and
the projection is anchored to what you observed: at `m = 4` (the number
of raters in `ratings`) `Φ(m)` is exactly the `ICC(A,k)` you would get
from [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
directly. For a one-off value you can also ask
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) for it
inline with a numeric `unit`, e.g. `unit = c("single", "average", 6)`.

Read as a curve, this is the classic “how many raters?” picture — plot
it with
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
(which needs **ggplot2**):

``` r

library(ggplot2)
autoplot(d_study(fit, m = 1:12))
```

![Projected reliability rising with the number of raters, with a
Monte-Carlo interval
band.](advanced_files/figure-html/dstudy-plot-1.png)

**Projection is extrapolation.** The rater variance $`\sigma^2_r`$ is
estimated from only as many raters as you observed, so projecting far
beyond that design leans hard on that estimate. The Monte-Carlo interval
widens honestly to reflect this rather than pretending to a precision it
lacks — and projecting absolute agreement is refused for *fixed* raters,
where there is no wider rater universe to generalize to (use
`raters = "random"`).

## Multilevel ICCs: subject vs. cluster level

Everything above treats the **subject** as the object of measurement.
But subjects are often nested in higher-level **clusters** — pupils in
classrooms, patients in clinics — and then “reliability” splits in two:

- **Subject level** (within-cluster): how reliably do raters distinguish
  *subjects within a cluster*?
- **Cluster level** (between-cluster): how reliably do raters
  distinguish *cluster means*?

Ignoring the nesting *conflates* these and biases both (ten Hove,
Jorgensen & van der Ark, 2022). Passing a `cluster` column to
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
the multilevel model and reports each level separately.

Consider pupils nested in classrooms, each pupil rated by the same panel
of raters. We simulate a design with substantial classroom-level signal
but modest within-classroom differences:

``` r

library(intraclass)

set.seed(2025)
n_class <- 16
n_pupil <- 5
n_rater <- 4
grid <- expand.grid(
  pupil = seq_len(n_pupil),
  classroom = seq_len(n_class),
  rater = seq_len(n_rater)
)
class_effect <- rnorm(n_class, sd = 1.3)[grid$classroom]
pupil_effect <- rnorm(n_class * n_pupil, sd = 0.6)[
  (grid$classroom - 1) * n_pupil + grid$pupil
]
rater_effect <- rnorm(n_rater, sd = 0.4)[grid$rater]
school <- data.frame(
  classroom = factor(grid$classroom),
  pupil = factor(paste(grid$classroom, grid$pupil, sep = "_")),
  rater = factor(grid$rater),
  score = 10 + class_effect + pupil_effect + rater_effect +
    rnorm(nrow(grid), sd = 0.7)
)
```

``` r

icc(school, score, subject = pupil, rater = rater, cluster = classroom, seed = 1)
#> # Intraclass correlation: multilevel two-way random, absolute agreement
#> Subjects: 80 in 16 clusters | Raters: 4 (random) | Observations: 320
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(A,1)    0.431   [0.249, 0.561]
#>   subject  ICC(A,k)    0.751   [0.571, 0.836]
#>   cluster  ICC(A,1)    0.880   [0.000, 0.972]
#>   cluster  ICC(A,k)    0.967   [0.000, 0.993]
#> Variance components: cluster 0.998, subject 0.461, rater 0.136, cluster:rater 0.000, residual 0.473
```

Both levels come back in one call. Here the **cluster-level** ICC is the
higher of the two: raters agree more about which *classrooms* score high
than about which *pupils within a classroom* do — exactly the pattern
you would expect when most of the true variation lives between
classrooms. Which number you report depends on the decision you will
make: a classroom-level intervention cares about the cluster-level
reliability, a pupil-level one about the subject level. Request just one
with `level = "subject"` or `level = "cluster"`.

Multilevel support currently covers **crossed random raters on balanced
data** (agreement/consistency and single/average apply at each level).
Raters nested within clusters, incomplete multilevel designs, and fixed
raters are planned for later milestones.

## Choosing an estimation engine

By default
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
the variance components with **glmmTMB**. You can instead request
**lme4** with `engine = "lme4"` for the random two-way design. Both are
REML mixed-model fits of the same model, so on a given dataset they
return the same coefficients to numerical tolerance — the choice is
about the fitting backend, not the estimand.

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
the zero boundary, where the lme4 route cannot form an interval and
directs you back to glmmTMB. lme4 for fixed-rater and multilevel designs
is planned for a later milestone.
