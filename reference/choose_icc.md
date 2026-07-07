# Recommend an ICC and the call that computes it

`choose_icc()` walks the decision tree of the *Choosing an ICC* vignette
and returns a recommendation object naming the coefficient(s) to report
and the exact
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
that computes them. It does **not** fit a model: there is no `data`
argument. Copy the emitted call and run it on your data.

## Usage

``` r
choose_icc(
  model = NULL,
  type = NULL,
  unit = NULL,
  raters = NULL,
  multilevel = NULL,
  level = NULL
)

# S3 method for class 'icc_recommendation'
format(x, ...)

# S3 method for class 'icc_recommendation'
print(x, ...)
```

## Arguments

- model:

  `"twoway"` (crossed: the same raters judge every subject) or
  `"oneway"` (raters are interchangeable across subjects). Defaults to
  `"twoway"`. Under `"oneway"` the `type` and `raters` choices do not
  exist (there is no rater term), and supplying them is an error.

- type:

  `"agreement"` (the value itself must match; systematic rater offsets
  count as error) or `"consistency"` (only rank order matters; a
  constant per-rater offset is forgiven). Required for a two-way design.

- unit:

  `"single"` (you will act on one rater's score), `"average"` (the mean
  of your raters), or `"both"`. Required.

- raters:

  `"random"` (a sample you generalize beyond – the recommended default
  for interrater reliability) or `"fixed"` (exactly these judges, no
  generalization). Required for a two-way design.

- multilevel:

  `TRUE` if subjects are nested in higher-level clusters (pupils in
  classrooms, patients in clinics), else `FALSE` (the default).

- level:

  For a multilevel design, `"subject"` (within-cluster reliability),
  `"cluster"` (between-cluster reliability), or `"both"`. Required when
  `multilevel = TRUE`.

- x:

  An `icc_recommendation` object.

- ...:

  Unused, for method consistency.

## Value

An `icc_recommendation` object (a list) with a
[`print()`](https://rdrr.io/r/base/print.html) method. It carries the
recommended coefficient rows (`$rows`), the exact
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
as a string (`$call`), the per-decision rationale (`$rationale`), and
any notes (`$notes`).

## Details

Supply the decisions as arguments to get advice programmatically; call
`choose_icc()` with the relevant answers omitted in an interactive
session to be asked the outstanding questions one at a time.

The two structural facts about your design – whether the raters are
crossed (`model`) and whether subjects are nested in clusters
(`multilevel`) – default to the common case (a crossed, non-multilevel
two-way design), matching
[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md). The
choices that actually select the coefficient (`type`, `unit`, `raters`,
and `level` when multilevel) have no silent default: in a
non-interactive session, leaving one unanswered is an error naming the
unanswered decision (rather than quietly picking one for you).

## See also

[`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md), and
[`vignette("choosing-an-icc")`](https://jmgirard.github.io/intraclass/articles/choosing-an-icc.md)
for the full decision tree.

## Examples

``` r
# Two-way absolute agreement, single rater, random raters (Shrout & Fleiss
# ICC(2,1)): the two structural defaults (crossed, non-multilevel) are implied.
choose_icc(type = "agreement", unit = "single", raters = "random")
#> # Recommended ICC
#> Design: two-way random, absolute agreement
#> Recommendation: ICC(A,1)
#> Shrout & Fleiss equivalent: ICC(A,1) = ICC(2,1)
#> Why:
#>   - Crossed (two-way): the same raters judge every subject.
#>   - Absolute agreement: the value itself must match; a systematic difference between raters counts as error.
#>   - Single rater: you will act on one rater's score.
#>   - Random raters: a sample you generalize beyond, to the rater universe they were drawn from.
#> Run this on your data:
#>   icc(data, score, subject, rater, unit = "single")
#> Notes:
#>   - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.

# Consistency of the average of fixed raters -- McGraw & Wong ICC(C,k):
choose_icc(type = "consistency", unit = "average", raters = "fixed")
#> # Recommended ICC
#> Design: two-way mixed, consistency
#> Recommendation: ICC(C,k)
#> Shrout & Fleiss equivalent: ICC(C,k) = ICC(3,k)
#> Why:
#>   - Crossed (two-way): the same raters judge every subject.
#>   - Consistency: only the rank order must match; a constant per-rater offset is forgiven.
#>   - Average: you will act on the mean of your raters.
#>   - Fixed raters: exactly these judges; the coefficient does not generalize past them.
#> Run this on your data:
#>   icc(data, score, subject, rater, type = "consistency", raters = "fixed", unit = "average")
#> Notes:
#>   - Random raters is the recommended default for interrater reliability; use fixed only when these are the entire population of raters you will ever use.
#>   - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.

# A one-way design (interchangeable raters): type/raters do not apply.
choose_icc(model = "oneway", unit = "single")
#> # Recommended ICC
#> Design: one-way random
#> Recommendation: ICC(1)
#> Shrout & Fleiss equivalent: ICC(1) = ICC(1,1)
#> Why:
#>   - One-way: raters are interchangeable across subjects, so systematic rater differences are absorbed into error -- the most conservative ICC.
#>   - Single rater: you will act on one rater's score.
#> Run this on your data:
#>   icc(data, score, subject, rater, model = "oneway", unit = "single")
#> Notes:
#>   - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.

# A multilevel design, both levels:
choose_icc(type = "agreement", unit = "single", raters = "random",
  multilevel = TRUE, level = "both")
#> # Recommended ICC
#> Design: multilevel, two-way random, absolute agreement
#> Recommendation:
#>   subject: ICC(A,1)
#>   cluster: ICC(A,1)
#> Why:
#>   - Crossed (two-way): the same raters judge every subject.
#>   - Absolute agreement: the value itself must match; a systematic difference between raters counts as error.
#>   - Single rater: you will act on one rater's score.
#>   - Random raters: a sample you generalize beyond, to the rater universe they were drawn from.
#>   - Both levels: within-cluster (subject) and between-cluster (cluster) reliability side by side.
#> Run this on your data:
#>   icc(data, score, subject, rater, cluster, unit = "single")
#> Notes:
#>   - Complete vs. incomplete is automatic: icc() uses whatever ratings are present and projects ICC(*,k) to the effective number of ratings (k_eff). The design must stay connected, or icc() fails loudly.
#>   - See vignette("advanced") for a worked multilevel example.
```
