# Glossary

A plain-language reference for the terms that recur across these
articles. Each entry defines the idea once; the other articles link here
rather than re-explaining it. Terms are listed alphabetically. Nothing
here is new — it is the vocabulary the [*Getting
started*](https://jmgirard.github.io/intraclass/articles/getting-started.md)
and [*Choosing an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)
guides use, gathered in one place.

## Absolute agreement

One of the two `type`s of ICC. Absolute agreement asks whether raters
give the *same* score — two raters who rank subjects identically but sit
a full point apart do **not** agree in this sense. It counts systematic
rater differences (the rater variance) as error. Contrast
**consistency**. In generalizability theory the absolute-agreement ICC
is the **dependability coefficient**.

## Average-unit ICC — `ICC(*,k)`

The reliability of the **mean** of `k` raters, rather than of one rater.
Averaging cancels part of the error, so `ICC(*,k)` is always at least as
high as the single-rater `ICC(*,1)`. The `k` is the number of raters
whose average you will actually use; on incomplete data it becomes the
**effective number of ratings**. See **single-unit ICC** for its
counterpart.

## Confidence interval vs. credible interval

A **confidence interval** (the frequentist engines’ output) is a range
built so that, across many hypothetical repetitions of the study, 95% of
such ranges would contain the true ICC. A **credible interval** (the
Bayesian `brms` engine’s output) is a range that holds 95% of the
posterior probability — you can say directly “there is a 95% chance the
ICC lies in here, given the data and the prior.” They answer subtly
different questions; see [*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md).

## Conflated ICC

The single-level ICC you would get by **ignoring** a clustering
structure (pupils in classrooms, patients in clinics) — ten Hove et
al.’s (2022) Equation 14. It folds the between-cluster and
within-cluster variation into one “true score” and is biased for both
the subject-level and cluster-level questions.
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) can
report it (`level = "conflated"`) purely as a **diagnostic contrast** to
show the cost of ignoring the structure; it is never a number to report.
See [*Multilevel
designs*](https://jmgirard.github.io/intraclass/articles/multilevel-designs.html#how-much-does-ignoring-the-nesting-cost-the-conflated-icc).

## Connectedness (identification)

A design is **connected** when the raters and subjects are linked
tightly enough that the model can separate a subject effect from a rater
effect. With enough missing cells a design can split into disconnected
islands, and then the variance components are not **identified** — no
method can estimate them.
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) checks
this and aborts loudly rather than return a number that isn’t estimable.

## Consistency

The other `type` of ICC. Consistency asks whether raters *rank* subjects
the same way, forgiving a constant offset between raters — two raters
who agree on the ordering but differ by a fixed point still count as
perfectly consistent. It leaves the rater main effect out of the error
term. Contrast **absolute agreement**.

## Credible interval

See **confidence interval vs. credible interval**.

## Dependability coefficient

The generalizability-theory name for the **absolute-agreement** ICC,
written . Projecting it to a different number of raters (a **D-study**)
is a change of the averaging divisor. See [*D-studies and within-cell
replicates*](https://jmgirard.github.io/intraclass/articles/d-studies-and-replicates.md).

## D-study (decision study)

A forward-looking projection: given the variance components you already
estimated, *how reliable would the mean of some other number of raters
(or occasions) be?* It reuses the existing fit — no refitting — and
answers “how many raters do I need?”. See [*D-studies and within-cell
replicates*](https://jmgirard.github.io/intraclass/articles/d-studies-and-replicates.md).

## Effective number of ratings — `k_eff`

On **incomplete** data, subjects are rated different numbers of times,
so there is no single “`k`” to average over. `k_eff` is the **harmonic
mean** of the per-subject rating counts, and it is the divisor
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) uses
for `ICC(*,k)` on ragged data. It is always at or below the full panel
size, and the report names it so the divisor is never a black box.

## Engine

The computational backend
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) uses
to estimate the variance components, chosen with the `engine` argument:
**glmmTMB** (the default mixed model), **lme4** (an alternate
mixed-model solver), **lavaan** (a structural-equation formulation), or
**brms** (a Bayesian fit). Some engines are just a different solver for
the same estimator; others compute a genuinely different, though
asymptotically equivalent, estimator. See [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.md).

## Estimand

The true quantity you are trying to estimate — the target the ICC is
aiming at. The word matters because “the ICC” is not one number:
agreement and consistency, single and average, subject level and cluster
level are *different estimands*, and picking the coefficient is really
picking which one answers your question. See [*Choosing an
ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md).

## FIML

**Full-information maximum likelihood** — the technique the **lavaan**
(SEM) engine uses to fit **incomplete** data: rather than dropping cases
with missing cells, it uses every observed value to estimate the model.
See [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#a-structural-equation-engine-lavaan).

## Finite-population rater variance — `θ²_r`

When raters are treated as **fixed** (the observed raters *are* the
whole population of interest), the “rater variance” is the spread of
just those raters, computed as a bias-corrected finite-population
quantity (McGraw & Wong’s Case 3A) rather than an estimate of a wider
rater universe. On balanced data it equals the random-rater variance;
under imbalance it differs. See **fixed vs. random raters**.

## Fixed vs. random raters

The `raters` argument. **Random** raters (the recommended default) treat
the raters you used as a sample from a larger pool, so the reliability
generalizes to *new* raters drawn from that pool. **Fixed** raters treat
the observed raters as the entire population of interest, so the
reliability speaks only to *these* raters. The choice changes the rater
term from a random-sample variance to the **finite-population rater
variance**.

## Harmonic mean

An average that leans toward the smaller values: the reciprocal of the
mean of the reciprocals. It is the right average for the **effective
number of ratings** because reliability depends on the *rate* of
information per subject, which the harmonic mean captures.

## Indicator-mean estimator

How the **lavaan** (SEM) engine recovers the rater variance for
**absolute agreement**: since a rater is a single column with no random
effect, its variance is read from the spread of the estimated column
(indicator) means (Jorgensen 2021). It is a genuinely different — though
asymptotically equivalent — estimator than the mixed model’s random
effect, and can differ modestly on small designs. See [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#a-structural-equation-engine-lavaan).

## Monte-Carlo interval

The default confidence-interval method (`ci_method = "montecarlo"`). It
draws many parameter vectors from the fitted model’s estimated
covariance, on a scale that respects the zero-variance boundary,
recomputes the ICC for each draw, and takes the 2.5% and 97.5%
quantiles. Fast and boundary-aware. See [*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md).

## One-way vs. two-way

The `model` argument. A **two-way** design has every subject rated by
the *same* raters, so a rater main effect can be estimated and either
counted as error (agreement) or set aside (consistency). A **one-way**
design has each subject rated by possibly *different* raters, so rater
identity is not modeled and only an agreement-style `ICC(1)` / `ICC(k)`
is defined.

## Parametric bootstrap

An alternative confidence-interval method (`ci_method = "bootstrap"`):
simulate new response vectors from the fitted model, refit each one, and
take percentile quantiles of the recomputed ICCs. It does not rely on
the asymptotic-normal approximation the Monte-Carlo method uses, at the
cost of a full refit per resample. See [*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md).

## Posterior mode (MAP)

The point estimate the Bayesian **brms** engine reports: the peak (mode)
of the posterior distribution of the ICC — the *maximum a posteriori*
value. On a small, right-skewed posterior it can sit below the
mixed-model REML estimate. Its interval is a **credible** interval. See
[*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#a-bayesian-engine-brms).

## Prior

In the Bayesian **brms** engine, the distribution placed on each
variance component *before* seeing the data — here a weakly-informative
half-*t*(4, 0, 1) on every standard deviation (ten Hove et al. 2020),
the sourced prior every coverage result depends on. Overriding it
(`prior =`) voids those guarantees, so
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) warns.
See [*Estimation
engines*](https://jmgirard.github.io/intraclass/articles/engines.html#the-prior-and-overriding-it).

## REML

**Restricted maximum likelihood** — the standard method the mixed-model
engines (glmmTMB, lme4) use to estimate variance components. It corrects
the downward bias that ordinary maximum likelihood has when estimating
variances, which matters for the small samples common in reliability
studies.

## Single-unit ICC — `ICC(*,1)`

The reliability of a **single** rater’s score. Its counterpart, the
**average-unit ICC** `ICC(*,k)`, is the reliability of the mean of `k`
raters and is always at least as high.

## Subject level vs. cluster level

In a **multilevel** design (subjects nested in clusters — pupils in
classrooms), two reliabilities are defined. The **subject level** asks
how reliably raters distinguish subjects *within* a cluster; the
**cluster level** asks how reliably they distinguish *cluster means*.
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
reports both from one fit. See [*Multilevel
designs*](https://jmgirard.github.io/intraclass/articles/multilevel-designs.html#subject-level-vs.-cluster-level).

## Variance component

A share of the total variation in the scores traced to one source — how
much comes from real differences between **subjects**, from some
**raters** scoring higher than others, from the **subject-by-rater**
interaction, and from residual **error**. Every ICC is a ratio built
from these components: signal variance over signal-plus-error variance.

## Zero-variance boundary

A variance component cannot be negative, so its estimate can land
*exactly* at zero — the edge of the allowed range. Ordinary interval
formulas misbehave there (they can run below zero or collapse). The
Monte-Carlo default is **boundary-aware**: it works on a scale where
zero is reachable without breaking, which is one reason glmmTMB is the
recommended engine. See [*Confidence-interval
methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md).

## References

Jorgensen, T. D. (2021). How to estimate absolute-error components in
structural equation models of generalizability theory. *Psych, 3*(2),
113–133.

ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). On the
usefulness of interrater reliability coefficients. In M. Wiberg et
al. (Eds.), *Quantitative Psychology* (pp. 67–75). Springer.

ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
reliability for multilevel data: A generalizability theory approach.
*Psychological Methods, 27*(4), 650–666.
