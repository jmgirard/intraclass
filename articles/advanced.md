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
#>       1     0.290   [0.050, 0.706]
#>       2     0.449   [0.096, 0.828]
#>       3     0.550   [0.137, 0.878]
#>       4     0.620   [0.175, 0.906]
#>       5     0.671   [0.210, 0.923]
#>       6     0.710   [0.241, 0.935]
#>       7     0.741   [0.271, 0.944]
#>       8     0.765   [0.298, 0.950]
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
#> Subjects: 80 in 16 clusters | Raters: 4 (random) | Observations: 320 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(A,1)    0.431   [0.251, 0.561]
#>   subject  ICC(A,k)    0.751   [0.573, 0.836]
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

### When raters are nested

The classroom example above has every rater rate every pupil in every
classroom, so raters are **crossed** with clusters (ten Hove et al.’s
Design 1). Two other layouts are common, and
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
**infers which one you have** from the data — you never declare it:

- **Raters nested in clusters** (Design 2): each classroom has its *own*
  panel of raters. There is then no between-cluster reliability to
  report — a cluster-level ICC needs the *same* raters spanning clusters
  — so [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  returns the subject level only.
- **Raters nested in subjects** (Design 3): each pupil is rated by their
  *own* raters. Now systematic rater differences cannot be separated
  from residual error at all, so this is a multilevel *one-way* design:
  it reports agreement-only `ICC(1)` / `ICC(k)`, the clustered analogue
  of `model = "oneway"`.

Take the same classrooms but give each one its own raters (Design 2):

``` r

school_d2 <- school
school_d2$rater <- factor(paste(school_d2$classroom, school_d2$rater, sep = "_"))
icc(school_d2, score, subject = pupil, rater = rater, cluster = classroom, seed = 1)
#> # Intraclass correlation: multilevel (raters nested in clusters) two-way random, absolute agreement
#> Subjects: 80 in 16 clusters | Raters: 64 (random) | Observations: 320 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(A,1)    0.429   [0.310, 0.549]
#>   subject  ICC(A,k)    0.751   [0.642, 0.830]
#> Variance components: cluster 0.966, subject 0.458, rater:cluster 0.128, residual 0.481
```

The header now reads *raters nested in clusters* and only the subject
level comes back. If instead each *pupil* has their own raters, the
design is a multilevel one-way (Design 3):

``` r

school_d3 <- school
school_d3$rater <- factor(paste(school_d3$pupil, school_d3$rater, sep = "_"))
icc(school_d3, score, subject = pupil, rater = rater, cluster = classroom, seed = 1)
#> # Intraclass correlation: multilevel (raters nested in subjects) absolute agreement
#> Subjects: 80 in 16 clusters | Raters: 320 (random) | Observations: 320 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(1)      0.412   [0.290, 0.546]
#>   subject  ICC(k)      0.737   [0.621, 0.828]
#> Variance components: cluster 0.998, subject 0.426, residual 0.609 (rater confounded)
```

Here the coefficients are labelled `ICC(1)` / `ICC(k)` and `type` no
longer applies — with each pupil’s raters unique, there is no rater main
effect to keep in or drop from the error term. A layout that is neither
cleanly crossed nor cleanly nested (some raters shared across clusters,
some not) raises an informative error rather than guessing at a model.

### Incomplete (ragged) multilevel designs

Just as in the single-level case ([*Beyond the balanced
case*](#beyond-the-balanced-case)), the **crossed** design (Design 1)
does not need every pupil rated by every rater. The mixed model
estimates the variance components from whatever cells are present, so a
ragged classroom design is handled directly. Drop a fifth of the ratings
from the `school` data at random:

``` r

set.seed(11)
school_ragged <- school[-sample(nrow(school), round(0.2 * nrow(school))), ]
```

At the **subject** level both agreement and consistency come back, and —
exactly as in the single-level incomplete case — `ICC(*,k)` averages
over the *effective* number of ratings per pupil (`k_eff`, the harmonic
mean), which is below the full panel size of 4:

``` r

icc(school_ragged, score, subject = pupil, rater = rater, cluster = classroom,
  level = "subject", seed = 1)
#> # Intraclass correlation: multilevel two-way random, absolute agreement
#> Subjects: 80 in 16 clusters | Raters: 4 (random) | Observations: 256 (incomplete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(A,1)    0.413   [0.233, 0.557]
#>   subject  ICC(A,k)    0.673   [0.471, 0.787]
#> ICC(*,k) projects to an effective 2.93 raters (harmonic mean of ratings/subject).
#> Variance components: cluster 1.026, subject 0.409, rater 0.125, cluster:rater 0.000, residual 0.457
```

The header now reads *incomplete*, and the report names the effective
`k` so the divisor is never a black box.

At the **cluster** level, the single-rater `ICC(c,1)` is available on
ragged data (it needs no averaging divisor). Request it with
`unit = "single"`:

``` r

icc(school_ragged, score, subject = pupil, rater = rater, cluster = classroom,
  level = "cluster", type = "consistency", unit = "single", seed = 1)
#> # Intraclass correlation: multilevel two-way random, consistency
#> Subjects: 80 in 16 clusters | Raters: 4 (random) | Observations: 256 (incomplete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   cluster  ICC(C,1)    1.000   [0.000, 1.000]
#> Variance components: cluster 1.026, subject 0.409, rater 0.125, cluster:rater 0.000, residual 0.457
```

Two things are deliberately fenced off on incomplete data, each with a
clear error rather than a silently wrong number. The **averaged**
cluster-level `ICC(c,k)` is not yet supported: the effective number of
raters behind a ragged *cluster* mean is a per-cluster quantity still
being validated, distinct from the per-pupil `k_eff`. And when missing
cells make the crossing pattern **ambiguous** — some raters happen to
appear in only one classroom, so the design could be read as crossed
*or* nested —
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) does
not guess; you resolve it by declaring `design = "crossed"` (validated
against the data), or the abort points you at the nested reading.

### Fixed raters in a multilevel design

The multilevel examples so far treat raters as a **random** sample — the
recommended default, which generalizes beyond the raters you happened to
use. When the observed raters *are* the entire population of interest (a
fixed panel of examiners, say), pass `raters = "fixed"` at the
**subject** level. As in the single-level case, the rater main effect is
then the finite-population variance of *these* raters (McGraw & Wong’s
Case 3A) rather than a random-sample variance:

``` r

icc(school, score, subject = pupil, rater = rater, cluster = classroom,
  raters = "fixed", level = "subject")
#> Warning: Modeling raters as fixed restricts inference to exactly these raters; you
#> cannot generalize to other raters.
#> ℹ For interrater reliability, the two-way random model (`raters = "random"`) is
#>   the recommended default (ten Hove et al. 2024; McGraw & Wong 1996, Case 2).
#> ℹ Use "fixed" only when these are the entire population of raters you will ever
#>   use.
#> # Intraclass correlation: multilevel two-way mixed, absolute agreement
#> Subjects: 80 in 16 clusters | Raters: 4 (fixed) | Observations: 320 (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   level    index     estimate   95% CI
#>   subject  ICC(A,1)    0.431   [0.318, 0.552]
#>   subject  ICC(A,k)    0.751   [0.651, 0.831]
#> Variance components: cluster 0.998, subject 0.461, rater 0.136, cluster:rater 0.000, residual 0.473
```

On this balanced design the fixed-rater subject-level coefficients match
the random-rater ones: **consistency** never uses the rater term, so it
is identical either way, and **absolute agreement** coincides because
the finite-population rater variance equals the random-sample estimate
when the design is balanced. The two genuinely diverge only on
incomplete data — which, for fixed-rater multilevel designs, is planned
for a later milestone.

Multilevel support currently covers **random** raters on: crossed
designs (Design 1), complete or **incomplete**, at the subject level and
— for `ICC(c,1)` — the cluster level; and nested designs (Designs 2 and
3, subject level), complete data. **Fixed** raters are supported for the
complete crossed design at the subject level. The averaged cluster-level
`ICC(c,k)` on incomplete data, incomplete nested designs, and incomplete
or nested fixed-rater designs are planned for later milestones.

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

### A structural-equation engine (`lavaan`)

`engine = "lavaan"` fits the same design as a **structural equation
model** — a common-factor generalizability model in the sense of
Jorgensen (2021) — for the complete, balanced random two-way design.
Unlike lme4, this is not just a different backend for the *same*
estimator: it matters which coefficient you ask for.

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
indicator intercepts. This **indicator-mean estimator** is a genuinely
different estimator of the rater variance than the mixed model’s random
effect: the two are asymptotically equivalent and match conventional
generalizability-theory software (GENOVA, `gtheory`) closely on real
data \[Vispoel et al. 2022\], but on a small design they differ by a
modest amount — here `ICC(A,1)` is about `0.284` from lavaan versus
`0.290` from the mixed model, because the raw variance of only four
estimated rater means carries small-sample noise the mixed model shrinks
away.

Which is “right”? Neither is wrong — they are two defensible estimators
of the same population quantity. Use `"glmmTMB"` (the default) if you
want the mixed-model random-rater estimate and its wider,
generalize-to-new-raters interval; reach for `"lavaan"` if you are
working inside an SEM generalizability-theory workflow and want results
comparable to that literature. The SEM engine currently covers the
complete, balanced random two-way design; one-way, fixed-rater,
multilevel, and incomplete designs are directed to the mixed-model
engines.
