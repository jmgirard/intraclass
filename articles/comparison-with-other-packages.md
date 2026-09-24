# Comparison with other packages

``` r

library(intraclass)
```

If you already use another R package for intraclass correlations, two
questions matter before switching. **Does `intraclass` agree with the
tool I trust on the problems that tool handles?** And **what does it do
that my current tool cannot?** This article answers both, on the
package’s own shipped datasets. Every number is computed live as the
page builds. Any unfamiliar term is defined in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).

The comparison packages are `psych`, `irr`, and `irrICC`. `psych` is a
general package for psychological measurement, and its
[`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html) is the most
widely used ANOVA ICC among R users. `irr` is a classical
inter-rater-reliability toolkit, and its
[`irr::icc`](https://rdrr.io/pkg/irr/man/icc.html) computes the same
ANOVA family. `irrICC` implements Gwet’s model-based ICCs. All three are
optional: the code chunks below only run when the package is installed.

## Does it agree? (validation)

On a **balanced** design, every subject is rated by every rater. There
the whole ICC family is defined for all of these tools, so we can line
them up coefficient by coefficient. The `ratings` dataset is six
subjects each scored by the same four raters. That is a two-way design:
each rater is tracked across the subjects they score.

`intraclass` estimates the coefficients from [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component),
each a share of the total variation traced to one source. It fits them
by
[REML](https://jmgirard.github.io/intraclass/articles/glossary.html#reml)
in a mixed model. REML, restricted maximum likelihood, is a way to
estimate variances that corrects maximum likelihood’s downward bias.
`psych` and `irr` instead derive the coefficients from classical **ANOVA
mean squares**. Those are different computational routes to the same
population quantity, and they are known to converge to each other. The
table shows how close they land here:

| The ICC family on the balanced ratings data |  |  |  |
|----|----|----|----|
| Coefficient | intraclass (REML) | psych (ANOVA) | irr (ANOVA) |
| ICC(1) | 0.16574 | 0.16574 | 0.16574 |
| ICC(1,k) | 0.44280 | 0.44280 | 0.44280 |
| ICC(A,1) | 0.28977 | 0.28976 | 0.28976 |
| ICC(A,k) | 0.62006 | 0.62005 | 0.62005 |
| ICC(C,1) | 0.71484 | 0.71484 | 0.71484 |
| ICC(C,k) | 0.90932 | 0.90932 | 0.90932 |

Every coefficient agrees to within 0.00001, so no two tools differ by
more than one in the fifth decimal place. The largest disagreement
anywhere in the table is 7.2e-06. That residual is not error in either
tool. It is the small-sample gap between a REML fit and ANOVA mean
squares, which vanishes as the sample grows. **On the designs classical
tools handle, you lose nothing by using `intraclass`.** The match with
`psych` is in fact checked on every test run of this package.

A model-based tool from a different lineage agrees too. `irrICC`
implements Gwet’s ICCs, estimated by a moment method rather than either
REML or ANOVA. Its two-way random absolute-agreement coefficient
(`icc2r`), for which raters give the same score, agrees with
`intraclass`’s `ICC(A,1)` to within 0.00001:

``` r

w <- reshape(ratings, idvar = "subject", timevar = "rater", direction = "wide")
w <- w[order(as.integer(as.character(w$subject))), ]
gwet_frame <- data.frame(
  Target = as.integer(as.character(w$subject)),
  J1 = w$score.1, J2 = w$score.2, J3 = w$score.3, J4 = w$score.4
)
gwet_agree <- irrICC::icc2.inter.fn(gwet_frame)$icc2r
intraclass_a1 <- with(tidy(icc(ratings, subject = subject, rater = rater, score = score,
                              model = "twoway", type = "agreement",
                              unit = "single")), estimate[term == "ICC(A,1)"])
```

| Single-rater absolute agreement on the ratings data |          |
|-----------------------------------------------------|----------|
| Package and coefficient                             | Estimate |
| intraclass ICC(A,1)                                 | 0.28977  |
| irrICC icc2r (Gwet)                                 | 0.28976  |

## What does it add? (differentiation)

The classical tools were built for the balanced, complete case. Real
rating data are rarely so tidy, and that is where the packages diverge.

### Incomplete and unbalanced data

The `ratings_incomplete` dataset is the same study with four ratings
missing. In particular, the second rater scored only two of the six
subjects:

| Scores in ratings_incomplete, one row per subject |  |  |  |  |
|----|----|----|----|----|
| Subject | Rater 1 | Rater 2 | Rater 3 | Rater 4 |
| 1 | 9 | 2 | 5 | 8 |
| 2 | 6 | 1 | 3 | 2 |
| 3 | 8 | not rated | 6 | 8 |
| 4 | 7 | not rated | 2 | 6 |
| 5 | 10 | not rated | 6 | 9 |
| 6 | 6 | not rated | 4 | 7 |

A classical ANOVA ICC needs a complete rectangle, so `psych` and `irr`
**listwise-delete** any subject with a missing cell. Here that discards
the four subjects rater 2 skipped, leaving only two:

| What listwise deletion leaves of ratings_incomplete |       |
|-----------------------------------------------------|-------|
| Quantity                                            | Count |
| Observed ratings                                    | 20    |
| Possible ratings                                    | 24    |
| Subjects left after listwise deletion               | 2     |

An ICC computed from two subjects is not usable, whatever its value.
`intraclass` instead fits the mixed model to **every observed rating**.
It reports an [effective number of
ratings](https://jmgirard.github.io/intraclass/articles/glossary.html#effective-number-of-ratings-k_eff)
(`k_eff`): the harmonic mean of the per-subject rating counts, an
average that leans toward the smaller values. That count accounts for
the imbalance:

``` r

fit_inc <- icc(ratings_incomplete, subject = subject, rater = rater, score = score,
               model = "twoway", type = "agreement", unit = "average")
gl_inc <- glance(fit_inc)
```

| intraclass on ratings_incomplete    |       |
|-------------------------------------|-------|
| Quantity                            | Value |
| ICC(A,k) estimate                   | 0.521 |
| Subjects used                       | 6     |
| Ratings used                        | 20    |
| Effective number of ratings (k_eff) | 3.273 |

All six subjects and all twenty observed ratings contribute, and nothing
is thrown away. `irrICC` can also fit incomplete data with its own
model, as the capability matrix below shows. The mean-squares tools
cannot.

### The bigger picture

Agreement on balanced data and graceful handling of missing data are two
entries in a wider gap. The table below summarizes what each package
computes. It is a guide to intent, not a scorecard: each tool is
excellent at what it was designed for. Two terms in it need a gloss.
Raters are
[fixed](https://jmgirard.github.io/intraclass/articles/glossary.html#fixed-vs--random-raters)
when the observed raters are the whole population of interest. An
interval is
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary)
when an estimate can land exactly at zero and the interval still
behaves.

| Capability | `psych` | `irr` | `irrICC` | `intraclass` |
|----|:--:|:--:|:--:|:--:|
| Balanced ANOVA ICC family | ✅ | ✅ | ✅ | ✅ |
| Incomplete / unbalanced data | no | no | ✅ | ✅ |
| Multilevel (subject **and** cluster) IRR | no | no | no | ✅ |
| Boundary-aware interval | no | no | partial | ✅ |
| [Fixed vs. random](https://jmgirard.github.io/intraclass/articles/glossary.html#fixed-vs--random-raters) rater framing | partial | partial | no | ✅ |
| Guidance on *which* ICC to report | no | no | no | ✅ |

Two rows deserve a word. Model-based extractors such as
`performance::icc` return **variance components** or a
variance-partition coefficient. That is the raw material of an ICC, but
not the inter-rater-reliability coefficient family itself. Nor is it the
error-variance framing that distinguishes agreement from consistency,
where raters agree apart from a constant offset per rater.
`intraclass`’s own generalizability coefficients were validated against
`gtheory`, agreeing to within 0.001. `gtheory` is a
generalizability-theory package archived from CRAN in March 2025, and is
not a dependency here. Those committed reference values live in the
package’s reference notes. And an **interval** that is
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval)
is something none of the classical tools provide. Such an interval
behaves correctly when a variance component is estimated at its [zero
boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary),
where a normal-approximation interval silently misbehaves.

`intraclass` earns its extra machinery on exactly these cases. For the
details of each, see the companion articles:

- [*Choosing an
  ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md):
  the selection framework the last matrix row points to.
- [*Multilevel
  designs*](https://jmgirard.github.io/intraclass/articles/multilevel-designs.md):
  subjects nested in clusters, where the subject level is reliability
  within a cluster, and the cluster level is reliability of cluster
  means.
- [*Interval
  methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md):
  the Monte-Carlo interval, built by drawing parameter values from the
  fitted model’s uncertainty. The article also covers the bootstrap,
  which refits the model on simulated data many times.
- [*Estimation
  engines*](https://jmgirard.github.io/intraclass/articles/engines.md):
  the engine, the software that does the fitting, in its mixed-model,
  SEM, and Bayesian forms.

## When to use which

If your design is **balanced and complete** and you only need the
classic McGraw–Wong coefficients, `psych` and `irr` are mature and
familiar. As the table above shows, they agree with `intraclass` there
to within 0.00001. Reach for `intraclass` when your data are
**incomplete or unbalanced**, or when raters are **nested in clusters**.
Reach for it too when you need an **interval you can trust near the
boundary**. And reach for it when you want the package to help you
**choose and justify** the coefficient in the first place.
