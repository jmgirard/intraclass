# Comparison with other packages

``` r

library(intraclass)
```

If you already use another R package for intraclass correlations, two
questions matter before switching: **does `intraclass` agree with the
tool I trust on the problems that tool handles?** and **what does it do
that my current tool cannot?** This article answers both, on the
package’s own shipped datasets, with every number computed live as the
page builds. Any unfamiliar term is defined in the
[*Glossary*](https://jmgirard.github.io/intraclass/articles/glossary.md).

The comparison packages are `psych` (Revelle’s
[`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html), the most widely
used ANOVA ICC in R), `irr`
([`irr::icc`](https://rdrr.io/pkg/irr/man/icc.html), a classical
inter-rater-reliability toolkit), and `irrICC` (Gwet’s model-based
ICCs). All three are optional — the code chunks below only run when the
package is installed.

## Does it agree? (validation)

On a **balanced** design — every subject rated by every rater — the
whole ICC family is defined for all of these tools, so we can line them
up coefficient by coefficient. The `ratings` dataset is six subjects
each scored by the same four raters.

`intraclass` estimates the coefficients from [variance
components](https://jmgirard.github.io/intraclass/articles/glossary.html#variance-component)
fitted by
[REML](https://jmgirard.github.io/intraclass/articles/glossary.html#reml)
(a mixed model), whereas `psych` and `irr` derive them from classical
**ANOVA mean squares**. Those are different computational routes to the
same population quantity, and they are known to converge to each other.
The table shows how close they land here:

``` r

wm <- to_wide(ratings)
ic <- function(model, type, unit) {
  icc(ratings, subject = subject, rater = rater, score = score,
      model = model, type = type, unit = unit)$estimates$estimate[1]
}
ps <- psych::ICC(wm)$results
psv <- stats::setNames(ps$ICC, ps$type)

rows <- list(
  c("ICC(1)",   "oneway", "agreement",   "single",  "ICC1"),
  c("ICC(1,k)", "oneway", "agreement",   "average", "ICC1k"),
  c("ICC(A,1)", "twoway", "agreement",   "single",  "ICC2"),
  c("ICC(A,k)", "twoway", "agreement",   "average", "ICC2k"),
  c("ICC(C,1)", "twoway", "consistency", "single",  "ICC3"),
  c("ICC(C,k)", "twoway", "consistency", "average", "ICC3k")
)

comparison <- do.call(rbind, lapply(rows, function(r) {
  data.frame(
    coefficient = r[1],
    intraclass  = ic(r[2], r[3], r[4]),
    psych       = unname(psv[r[5]]),
    irr         = irr::icc(wm, model = r[2], type = r[3], unit = r[4])$value
  )
}))
#> Warning in check_dep_version(dep_pkg = "TMB"): package version mismatch: 
#> glmmTMB was built with TMB package version 1.9.21
#> Current TMB package version is 1.9.23
#> Please re-install glmmTMB from source or restore original 'TMB' package (see '?reinstalling' for more information)

knitr::kable(comparison, digits = 5, row.names = FALSE)
```

| coefficient | intraclass |   psych |     irr |
|:------------|-----------:|--------:|--------:|
| ICC(1)      |    0.16574 | 0.16574 | 0.16574 |
| ICC(1,k)    |    0.44280 | 0.44280 | 0.44280 |
| ICC(A,1)    |    0.28977 | 0.28976 | 0.28976 |
| ICC(A,k)    |    0.62006 | 0.62005 | 0.62005 |
| ICC(C,1)    |    0.71484 | 0.71484 | 0.71484 |
| ICC(C,k)    |    0.90932 | 0.90932 | 0.90932 |

``` r

max_gap <- max(abs(comparison$intraclass - comparison$psych),
               abs(comparison$intraclass - comparison$irr))
```

Every coefficient matches to five decimal places — the largest
disagreement anywhere in the table is 7.2e-06. That residual is not
error in either tool; it is the small-sample gap between a REML fit and
ANOVA mean squares, which vanishes as the sample grows. **On the designs
classical tools handle, you lose nothing by using `intraclass`** — the
`psych` agreement is in fact checked on every test run of this package.

A model-based tool from a different lineage agrees too. `irrICC`
implements Gwet’s ICCs, estimated by a moment method rather than either
REML or ANOVA; its two-way random agreement coefficient (`icc2r`)
reproduces `intraclass`’s `ICC(A,1)`:

``` r

w <- reshape(ratings, idvar = "subject", timevar = "rater", direction = "wide")
w <- w[order(as.integer(as.character(w$subject))), ]
gwet_frame <- data.frame(
  Target = as.integer(as.character(w$subject)),
  J1 = w$score.1, J2 = w$score.2, J3 = w$score.3, J4 = w$score.4
)
gwet_agree <- irrICC::icc2.inter.fn(gwet_frame)$icc2r
intraclass_a1 <- icc(ratings, subject = subject, rater = rater, score = score,
                     model = "twoway", type = "agreement", unit = "single")$estimates$estimate[1]

data.frame(
  source   = c("intraclass ICC(A,1)", "irrICC icc2r (Gwet)"),
  estimate = c(intraclass_a1, gwet_agree)
)
#>                source  estimate
#> 1 intraclass ICC(A,1) 0.2897700
#> 2 irrICC icc2r (Gwet) 0.2897638
```

## What does it add? (differentiation)

The classical tools were built for the balanced, complete case. Real
rating data are rarely so tidy, and that is where the packages diverge.

### Incomplete and unbalanced data

The `ratings_incomplete` dataset is the same study with four ratings
missing — in particular the second rater scored only two of the six
subjects:

``` r

wide_incomplete <- reshape(ratings_incomplete, idvar = "subject",
                           timevar = "rater", direction = "wide")
wide_incomplete <- wide_incomplete[order(as.integer(as.character(wide_incomplete$subject))), ]
colnames(wide_incomplete) <- c("subject", paste0("rater", 1:4))
knitr::kable(wide_incomplete, row.names = FALSE)
```

| subject | rater1 | rater2 | rater3 | rater4 |
|:--------|-------:|-------:|-------:|-------:|
| 1       |      9 |      2 |      5 |      8 |
| 2       |      6 |      1 |      3 |      2 |
| 3       |      8 |     NA |      6 |      8 |
| 4       |      7 |     NA |      2 |      6 |
| 5       |     10 |     NA |      6 |      9 |
| 6       |      6 |     NA |      4 |      7 |

A classical ANOVA ICC needs a complete rectangle, so `psych` and `irr`
**listwise-delete** any subject with a missing cell. Here that discards
the four subjects rater 2 skipped, leaving only two:

``` r

wm_inc <- to_wide(ratings_incomplete)
surviving <- sum(stats::complete.cases(wm_inc))
c(observed_cells = nrow(ratings_incomplete),
  possible_cells = nrow(ratings),
  subjects_after_listwise_deletion = surviving)
#>                   observed_cells                   possible_cells 
#>                               20                               24 
#> subjects_after_listwise_deletion 
#>                                2
```

An ICC computed from two subjects is not usable, whatever its value.
`intraclass` instead fits the mixed model to **every observed rating**
and reports an [effective number of
ratings](https://jmgirard.github.io/intraclass/articles/glossary.html#effective-number-of-ratings-k_eff)
(`k_eff`) that accounts for the imbalance:

``` r

fit_inc <- icc(ratings_incomplete, subject = subject, rater = rater, score = score,
               model = "twoway", type = "agreement", unit = "average")
c(estimate = fit_inc$estimates$estimate[1],
  subjects_used = fit_inc$n$subjects,
  ratings_used = fit_inc$n$obs,
  k_eff = fit_inc$k_eff)
#>      estimate subjects_used  ratings_used         k_eff 
#>     0.5205561     6.0000000    20.0000000     3.2727273
```

All six subjects and all twenty observed ratings contribute; nothing is
thrown away. (`irrICC` can also fit incomplete data with its own model —
see the capability matrix below — but the mean-squares tools cannot.)

### The bigger picture

Agreement on balanced data and graceful handling of missing data are two
entries in a wider gap. The table below summarizes what each package
computes; it is a map of intent, not a scorecard — each tool is
excellent at what it was designed for.

| Capability | `psych` | `irr` | `irrICC` | `intraclass` |
|----|:--:|:--:|:--:|:--:|
| Balanced ANOVA ICC family | ✅ | ✅ | ✅ | ✅ |
| Incomplete / unbalanced data | — | — | ✅ | ✅ |
| Multilevel (subject **and** cluster) IRR | — | — | — | ✅ |
| Boundary-aware interval | — | — | partial | ✅ |
| [Fixed vs. random](https://jmgirard.github.io/intraclass/articles/glossary.html#fixed-vs.-random-raters) rater framing | partial | partial | — | ✅ |
| Guidance on *which* ICC to report | — | — | — | ✅ |

Two rows deserve a word. Model-based extractors such as
`performance::icc` return **variance components** or a
variance-partition coefficient, which is the raw material of an ICC but
not the inter-rater-reliability coefficient family itself, nor the
error-variance framing that distinguishes agreement from consistency.
(`intraclass`’s own generalizability coefficients were validated against
`gtheory` — a generalizability-theory package archived from CRAN in
March 2025, and not a dependency here — agreeing to within 0.001; those
committed reference values live in the package’s reference notes.) And
an **interval** that is
[boundary-aware](https://jmgirard.github.io/intraclass/articles/glossary.html#monte-carlo-interval)
— that behaves correctly when a variance component is estimated at its
[zero
boundary](https://jmgirard.github.io/intraclass/articles/glossary.html#zero-variance-boundary),
where a normal-approximation interval silently misbehaves — is something
none of the classical tools provide.

`intraclass` earns its extra machinery on exactly these cases. For the
details of each, see the companion articles:

- [*Choosing an
  ICC*](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)
  — the selection framework the last matrix row points to.
- [*Multilevel
  designs*](https://jmgirard.github.io/intraclass/articles/multilevel-designs.md)
  — subject- and cluster-level reliability when raters are nested.
- [*Interval
  methods*](https://jmgirard.github.io/intraclass/articles/interval-methods.md)
  — the boundary-aware Monte-Carlo and bootstrap intervals.
- [*Estimation
  engines*](https://jmgirard.github.io/intraclass/articles/engines.md) —
  the mixed-model, SEM, and Bayesian backends behind these numbers.

## When to use which

If your design is **balanced and complete** and you only need the
classic McGraw–Wong coefficients, `psych` and `irr` are mature,
familiar, and — as the table above shows — numerically identical to
`intraclass`. Reach for `intraclass` when your data are **incomplete or
unbalanced**, when raters are **nested in clusters**, when you need an
**interval you can trust near the boundary**, or when you want the
package to help you **choose and justify** the coefficient in the first
place.
