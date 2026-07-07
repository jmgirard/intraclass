# Intraclass correlation coefficient for a two-way design

Estimates interrater-reliability intraclass correlation coefficients
(ICCs) from a fitted linear mixed model, rather than from classical
ANOVA mean squares. `icc()` computes the two-way **absolute-agreement**
(`ICC(A,*)`) or **consistency** (`ICC(C,*)`) coefficients of McGraw &
Wong (1996), for a single rater (`ICC(*,1)`) or the mean of `k` raters
(`ICC(*,k)`), treating the raters as a random sample (Case 2) or as
fixed (Case 3).

## Usage

``` r
# S3 method for class 'icc'
format(x, ...)

# S3 method for class 'icc'
print(x, ...)

# S3 method for class 'icc'
summary(object, ...)

# S3 method for class 'icc'
tidy(x, ...)

# S3 method for class 'icc'
glance(x, ...)

icc(
  data,
  score,
  subject,
  rater,
  cluster = NULL,
  model = "twoway",
  type = c("agreement", "consistency"),
  raters = c("random", "fixed"),
  unit = c("single", "average"),
  level = c("subject", "cluster"),
  engine = "glmmTMB",
  conf_level = 0.95,
  ci_method = "montecarlo",
  mc_samples = 10000L,
  seed = NULL
)
```

## Arguments

- x, object:

  An `icc` object.

- ...:

  Unused, for method consistency.

- data:

  A data frame with one rating per row.

- score, subject, rater:

  Columns of `data` (unquoted): the numeric rating, the subject (object
  of measurement), and the rater (judge).

- cluster:

  Optional column of `data` (unquoted) giving the higher-level unit each
  subject is nested in (e.g. classroom, clinic). Supplying it switches
  on the **multilevel** ICC (ten Hove et al. 2022): reliability is
  reported at the subject and/or cluster level (see `level` and the
  *Multilevel designs* section). Left `NULL` (the default) for an
  ordinary single-level two-way ICC.

- model:

  Design. Only `"twoway"` is currently supported.

- type:

  Error definition: `"agreement"` (absolute agreement, the default)
  counts systematic rater differences as error; `"consistency"` ignores
  them.

- raters:

  Rater sampling: `"random"` (the default; two-way random, Case 2)
  generalizes to a rater universe; `"fixed"` (two-way mixed, Case 3)
  treats the observed raters as the entire population and is fit with
  raters as fixed effects (`score ~ 1 + rater + (1 | subject)`). On
  balanced data the point estimate matches `"random"`; on incomplete
  data the two genuinely differ. Even when balanced, the interval
  differs for absolute agreement, because inference about fixed vs.
  random rater effects is not the same. Choosing `"fixed"` emits a
  warning, because random is the recommended default for interrater
  reliability.

- unit:

  The averaging unit(s): `"single"` (-\> `ICC(*,1)`), `"average"` (-\>
  `ICC(*,k)`), or a number `m` \>= 1 for a D-study projection to the
  mean of `m` raters (-\> `ICC(*,m)`), or any combination. See
  [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  for projecting across a range of `m`. Projecting absolute agreement is
  not defined for fixed raters (see
  [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)).

- level:

  For multilevel designs (a `cluster` column), which reliability to
  report: `"subject"` (within-cluster, distinguishing subjects) and/or
  `"cluster"` (between-cluster, distinguishing cluster means). Defaults
  to both. Ignored (and must be left at its default) when `cluster` is
  not supplied.

- engine:

  Estimation engine: `"glmmTMB"` (default) or `"lme4"`. Both fit the
  variance components by REML and agree to within numerical tolerance on
  balanced data. `"lme4"` currently covers only the random two-way
  design (`raters = "random"`, no `cluster`) and requires the lme4 and
  merDeriv packages.

- conf_level:

  Confidence level for the interval (default `0.95`).

- ci_method:

  Interval method. Only `"montecarlo"` is currently supported.

- mc_samples:

  Number of Monte-Carlo draws for the interval.

- seed:

  Optional integer seed for a reproducible interval. The global RNG
  state is restored afterward.

## Value

An `icc` object: a list with the estimate table, variance components,
design, engine, interval settings, sample sizes, the fitted model, and
the call. Use [tidy()](https://generics.r-lib.org/reference/tidy.html),
[glance()](https://generics.r-lib.org/reference/glance.html), and the
`print`/`summary` methods.

## Which ICC is this, and when should you use it?

Three choices pin down the coefficient:

- **Agreement vs. consistency** (`type`). **Absolute agreement** treats
  systematic differences between raters (the rater main effect,
  \\\sigma^2_r\\) as error: use it when the actual value matters and
  raters must agree on the number (clinical scores, measurements).
  **Consistency** ignores a constant per-rater offset: use it when only
  relative standing matters. A large gap between the two signals big
  systematic differences in rater level – a rating-procedure problem
  worth fixing.

- **Single vs. average** (`unit`). **`ICC(*,1)`** is the reliability of
  a *single* rater; **`ICC(*,k)`** is the reliability of the *mean* of
  your `k` raters. Report `ICC(*,k)` when the averaged score is what you
  will use.

- **Random vs. fixed raters** (`raters`). **Random** treats your raters
  as a sample you wish to generalize beyond – the recommended default
  for interrater reliability. **Fixed** treats them as the only raters
  of interest and forgoes generalization; it is fit separately (raters
  as fixed effects), so on balanced data it matches the random point
  estimate but on incomplete data it genuinely differs. `icc()` warns
  when you choose it. Fixed-rater consistency is the classic Shrout &
  Fleiss `ICC(3,1)`.

## Estimand

With a single rating per subject-by-rater cell, the subject-by-rater
interaction and pure error are not separately identified; only their
sum, the residual variance \\\sigma^2\_{res}\\, is estimable. Absolute
agreement counts the rater main effect \\\sigma^2_r\\ as error;
consistency drops it: \$\$ICC(A,1) = \sigma^2_s / (\sigma^2_s +
\sigma^2_r + \sigma^2\_{res})\$\$ \$\$ICC(A,k) = \sigma^2_s /
(\sigma^2_s + (\sigma^2_r + \sigma^2\_{res}) / k)\$\$ \$\$ICC(C,1) =
\sigma^2_s / (\sigma^2_s + \sigma^2\_{res})\$\$ \$\$ICC(C,k) =
\sigma^2_s / (\sigma^2_s + \sigma^2\_{res} / k)\$\$ where \\\sigma^2_s\\
is the subject (signal) variance and `k` is the number of raters.

## Multilevel designs (subject vs. cluster level)

When subjects are nested in higher-level clusters (pupils in classrooms,
patients in clinics), single-level ICCs conflate the levels and are
biased (ten Hove et al. 2022). Supplying `cluster` fits the
five-component Design-1 model \$\$score \sim 1 + (1\|cluster) +
(1\|cluster{:}subject) + (1\|rater) + (1\|cluster{:}rater)\$\$ and
reports two distinct reliabilities. The **subject level**
(within-cluster) asks how reliably raters distinguish subjects *within*
a cluster: its signal is the between-subject-within-cluster variance and
cluster variance drops out. The **cluster level** (between-cluster) asks
how reliably raters distinguish cluster means: its signal is the
between-cluster variance and the rater-disagreement error is the
cluster-by-rater term. Choose the level that matches the decision you
will make (about a subject, or about a cluster). Multilevel support (M5)
covers crossed random raters on balanced data; the agreement/consistency
and single/average choices above apply at each level.

## Confidence intervals

Intervals are Monte-Carlo: parameters are drawn from the fitted
covariance on the model's internal (log) scale and back-transformed, so
the interval is boundary-aware near the common zero-rater-variance case
where the delta method fails. Pass `seed` for a reproducible interval.

## References

McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some
intraclass correlation coefficients. *Psychological Methods, 1*(1),
30-46.

Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.

ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
reliability for multilevel data: A generalizability theory approach.
*Psychological Methods, 27*(4), 650-666.

## Examples

``` r
ratings <- data.frame(
  subject = factor(rep(1:6, 4)),
  rater = factor(rep(1:4, each = 6)),
  score = c(9, 6, 8, 7, 10, 6, 2, 1, 4, 1, 5, 2,
            5, 3, 6, 2, 6, 4, 8, 2, 8, 6, 9, 7)
)
icc(ratings, score, subject, rater, seed = 1)
#> # Intraclass correlation: two-way random, absolute agreement
#> Subjects: 6 | Raters: 4 (random) | Observations: 24 of 24 cells (complete)
#> Engine: glmmTMB (REML) | CI: 95% montecarlo (10000 draws)
#>   index     estimate   95% CI
#>   ICC(A,1)    0.290   [0.050, 0.712]
#>   ICC(A,k)    0.620   [0.173, 0.908]
#> Variance components: subject 2.556, rater 5.244, residual 1.019
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1), ICC(A,k) = ICC(2,k)
```
