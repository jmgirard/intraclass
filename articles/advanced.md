# Advanced: imbalanced & multilevel designs

## Beyond the balanced case

This article will cover where the mixed-model approach earns its keep:

- **Multilevel ICCs** — subject-level vs. cluster-level coefficients.
- **Engine choice** — linear mixed models vs. SEM vs. Bayesian, and when
  each matters.
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

> The multilevel and alternative-engine material below is a placeholder,
> filled in from **Milestone 5** onward (`project/MILESTONES.md`).
