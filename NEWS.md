# intraclass (development version)

## Breaking changes

* `icc()` now reports **all defined error definitions by default.** The `type`
  argument is vectorized like `unit` and `level` and defaults to
  `c("agreement", "consistency")`, so a default two-way call returns `ICC(A,1)`,
  `ICC(A,k)`, `ICC(C,1)`, and `ICC(C,k)` from a single fit — agreement vs.
  consistency is post-fit arithmetic on the same variance components, so the extra
  coefficients are free (this matters most for the expensive `brms` engine). Pass a
  single `type` to report just that coefficient. **No computed value changes** and
  every explicit `type = "agreement"` / `type = "consistency"` call is unaffected,
  but the **default** `print()` / `tidy()` output grows from two rows to four
  (grouped by error definition in `print()`). Code that indexes default `tidy()`
  rows by position should select by the `index` / `type` columns instead.
* `d_study()` likewise projects **one reliability curve per error definition** the
  fitted `icc` reports, adding a `type` column to distinguish the curves; a
  single-type fit projects a single curve as before.
* A definition that is undefined for the design (consistency for a Design-3
  nested-in-subjects fit, a fixed-rater absolute-agreement D-study projection, or
  absolute agreement when raters do not bridge clusters) is dropped with an
  informative message when reached via the default vector, and still aborts with a
  teaching error when requested explicitly.

* `icc()` now **drops rows whose `score` is `NA`** and analyzes the rest as an
  incomplete design, warning with the suppressible `intraclass_dropped_rows`
  class. Such a frame previously fit without complaint and then failed further
  down, when the interval was computed. A missing rating and an absent row now
  give the same answer. One consequence is worth knowing: a dropped row no
  longer counts toward the design, so a frame
  that looked balanced because of it is now correctly seen as unbalanced —
  `ci_method = "searle"` and `"burch"` are refused on it (they require balance),
  while `"npbootstrap"` becomes available.

* `ci_method = "burch"` now aborts with the classed `intraclass_singular_fit`
  condition when the between-subject mean square is exactly zero, where it
  previously reported an interval of `NaN` to `NaN` (or failed with an unclassed
  error, depending on `unit`). The Burch width depends on a kurtosis term that
  divides by that mean square, so it has no value there. Data that is constant
  throughout already aborted, via the guard both classical methods share.

## Minor improvements

* `?icc` and the *Confidence-interval methods* article now document a coverage
  limitation of the default Monte-Carlo interval: when the subject effects are
  strongly skewed or heavy-tailed, it under-covers, worst 0.6725 at
  chi-square(1) subject effects with a true ICC of 0.6, 50 subjects and 5
  raters. The runs concerned do not abort or warn, so the caveat is where a
  user meets it: the help page, the article, and the glossary entry for the
  method.
* **Correction.** Earlier releases described `ci_method = "burch"` as immune to
  under-coverage and recommended it when heavy tails were a concern; the
  message printed when the default aborts said the same. A simulation study
  measured `"burch"` under-covering on strongly skewed subject effects about as
  badly as the default (worst 0.6655), so that claim and that recommendation
  are withdrawn from the help page, the article, and the runtime message.
  `"searle"` landed closer to nominal coverage in most cells of every
  distribution family measured; what `"burch"` retains is dipping below the
  nominal level in fewer cells overall.
* **Correction.** Earlier releases ranked the two classical intervals by width —
  presenting `ci_method = "burch"` as the broader of the pair and
  `ci_method = "searle"` as the tightest available on near-normal data — in the
  help page, the article, the glossary, the runtime message and this file. Both
  grids that vary only the subject effect say otherwise: `"burch"` is the narrower of the
  two in 16 of 16 cells of the smaller grid and 59 of 64 cells of the larger
  grid, with no distribution family reversing it on its median. That margin is
  **conditional**, and the documentation now says so rather than quoting one
  pooled figure — but not in the direction one might guess: `"burch"`'s width
  margin holds much the same up to a true ICC of 0.3 rather than shrinking as the true ICC rises
  (on the larger grid; the smaller grid's margin does shrink across its levels),
  then collapses to near parity at a true ICC of 0.6, on the one grid reaching that value,
  where every cell favouring `"searle"` sits, and it shrinks steadily as the subject count grows, measured at 5 raters. That is
  the only rater count present at every subject count, so an unstratified
  subject-count figure would be confounded. The article tabulates both cuts. No
  source supports the withdrawn wording either — Burch (2011)
  compares against this same exact-F interval and reports a
  *kurtosis-conditional* ordering, shorter for light-tailed data and wider for
  symmetric heavy-tailed data where the errors are non-normal too. His length
  comparison uses symmetric families throughout, so it
  settles nothing about skewed data either way.
  A third grid now measures that case.
  What `"burch"` does against `"searle"` depends on what the residual is
  drawn from, and the three grids now measure that:
  the two grids that vary only the subject effect put it narrower
  nearly everywhere, while the third, which draws the residual from
  the same family as the subject effect, puts it wider at every
  symmetric heavy-tailed family measured (a median width ratio of
  1.2963 at t(5) with 100 subjects) and narrower at every lighter-tailed one,
  the normal included. The claim is withdrawn everywhere it appeared; neither interval is
  described as reliably the tighter one, and the coverage-based preference for
  `"searle"` is unchanged.
* `icc()` now rejects a non-finite `score` (`Inf`, `-Inf`, `NaN`) with a classed
  error naming the column and the offending rows, instead of passing it to the
  fitting engine and surfacing that engine's own unclassed message.
* When an interval method aborts on degenerate data, the error now names another
  `ci_method` that works — verified by running it on your data first, so the
  suggestion is a call that was just shown to succeed rather than a guess. The
  default Monte-Carlo interval already did this for the methods fenced to your
  design, and can now reach `"bootstrap"` as well; the `"bootstrap"`,
  `"searle"`, `"burch"` and `"npbootstrap"` intervals gain the behaviour
  outright. It matters most on
  data with no between-subject variance, where `"bootstrap"` is usually the only
  method that returns anything usable and previous versions said only "inspect
  the data". Where nothing works, nothing is named and the message keeps its own
  wording — with one change: the abort for degenerate resamples no longer
  carries a fixed `ci_method = "montecarlo"` suggestion, because that method is
  now named there only when a trial run confirms it on your data. No message
  ever suggests the method you just asked for. When a suggestion names
  `ci_method = "bootstrap"` it also names the `boot_samples` the trial ran at,
  and — when you set no seed of your own — the `seed` it used, so the call you
  are given is exactly the call that was checked. If you did set a seed, the
  trial ran under yours and the message points back at it rather than naming
  another one.

* `ci_method = "mpl"` now distinguishes a confidence limit truly at the `[0, 1]`
  boundary from a numerical failure. A boundary endpoint is reported only when
  the profile deviance shows the confidence set reaching that boundary; a
  degenerate fit (near-zero error variance — e.g. raters in perfect or
  near-perfect agreement, where the old code silently reported the vacuous
  interval `[0, 1]`) or a failed root search now raises a classed
  `intraclass_engine_error` instead. Intervals on data with a well-defined
  likelihood are unchanged.

* The `ci_method = "mpl"` documentation now states the interpolation evidence
  behind off-node subject counts: the correction constant is calibrated at
  subject-count nodes and linearly interpolated between them, and the
  interpolated path is coverage-validated at each supported confidence level —
  at the default 0.95 by three off-node cells, each clearing its pre-registered
  coverage floor. The documentation also says what that validation does not
  establish (interpolated values are validated at a handful of geometries, not
  calibrated, and the interval's asymmetry direction is not uniform across rater
  counts). Every universal or negative claim this documentation makes about the
  validated cells is settled mechanically, in CI, against the committed coverage
  fixture (`data-raw/check-mpl-doc-claims.py`).

* When the default Monte-Carlo interval cannot be computed near the variance
  boundary, the error now **names an interval method that works on your data**
  instead of only suggesting a refit. It does this by running each method your
  design allows and looking at the interval that comes back: a method is named only
  when every endpoint it reports is finite, correctly ordered, and inside the
  coefficient's range. A balanced one-way fit can be pointed at the deterministic
  closed forms `ci_method = "searle"` and `"burch"` (with a word on what each is
  good for), a two-way random absolute-agreement fit at `"mpl"`, and an unbalanced
  one-way fit at `ci_method = "npbootstrap"` — the one interval method available
  there.

  Because the check runs the method rather than reasoning about your design, it
  falls silent in every case where the method would not in fact help — fixed
  raters, multilevel, within-cell replicates, consistency,
  a `conf_level` or a subject/rater count outside the calibrated set,
  degenerate data, or a projection to so many raters that a method's
  projection formula breaks down. (Missing scores were once in that list too;
  they are not any more, because such rows are now dropped and the remaining
  design is one some methods genuinely serve.) The two closed forms are asked separately, so
  where one breaks down and the other does not, only the one that works is named.

  `"npbootstrap"` resamples, so its trial run is evidence about one run rather
  than about your data. The hint therefore runs it under your call's own
  `boot_samples` and the `seed` your
  own call set, so the run it verified is the run you would reproduce — and when
  no seed was set, it verifies under a fixed seed and the message tells you which
  `seed =` value reproduces that verified interval (an unseeded retry draws fresh
  resamples and can fail on a small design). The trial run never touches the
  random-number stream your session goes on to use.

  The interval methods themselves, and what the default does, are unchanged. This
  adds guidance to an existing error and never silently substitutes one method for
  another: the call still fails, and still returns no interval.

* `ci_method = "npbootstrap"` now also covers **unbalanced one-way** designs
  (unequal ratings per subject) for both `unit = "single"` (ICC(1)) and
  `unit = "average"` (ICC(k)): the transform uses the ANOVA effective group size
  `n0` and the infinitesimal-jackknife SE its per-subject form (Ohyama 2025;
  Ukoumunne et al. 2003, Appendix A), and the ICC(k) interval is the exact
  Spearman-Brown image of the ICC(1) interval (its coverage is identical by
  construction, and stays well-defined unbalanced because the effective ratings per
  subject never exceed `n0`). On balanced data the result is unchanged. Only a
  numeric `unit` (a projection to a chosen number of raters) remains balanced-only —
  use `ci_method = "montecarlo"` for an unbalanced projection.

* New `ci_method = "npbootstrap"` for the **balanced one-way random** design: the
  non-parametric variance-stabilized **transformed bootstrap-*t*** of Ukoumunne et
  al. (2003). It resamples whole subjects (not the fitted model), so it is boundary
  robust — it returns an interval where the Monte-Carlo default aborts on
  near-zero-ICC data — and robust to non-normal subject effects. Validated against
  the paper's exact Table I coverage. It is one-way only (aborts otherwise) and
  **not** a percentile bootstrap (the percentile and BCa variants under-cover and
  were deliberately not shipped). The `ICC(k)` interval is the exact Spearman-Brown
  image of the `ICC(1)` interval; endpoints are untruncated (following the source),
  so a near-boundary lower bound can be negative.

* New `ci_method = "searle"` and `ci_method = "burch"` for the **balanced one-way
  random** design: two **deterministic classical closed-form** intervals. `"searle"`
  is the exact-F pivot (Searle 1971, Table 9.14; McGraw & Wong 1996, Table 7),
  exact under normality; `"burch"` is the REML-based, kurtosis-adjusted interval
  of Burch (2011), below-nominal in fewer cells (but see the corrections above —
  it is not a remedy for heavy tails, and it is not the wider of the two).
  Like `"npbootstrap"` they are **boundary robust** — a finite
  interval where the Monte-Carlo default aborts on near-zero-ICC data — and one-way
  only (they abort otherwise). Being closed forms they take no `mc_samples`,
  `boot_samples`, or `seed` and report no standard error; the `ICC(k)` interval is
  the exact Spearman-Brown image of the `ICC(1)` interval, endpoints untruncated.

* New `ci_method = "mpl"` for the **balanced-complete two-way random**
  absolute-agreement `ICC(A,1)` (and `ICC(A,k)`): the **modified profile-likelihood**
  interval of Xiao & Liu (2013). Like the closed forms it is **boundary robust** — it
  returns a finite interval at the near-zero-ICC boundary
  where the Monte-Carlo default aborts (a degenerate fit or a failed root search
  raises a classed error rather than a fabricated boundary value) — and takes no `mc_samples`, `boot_samples`, or
  `seed` and reports no standard error. It is a deliberately **conservative** opt-in
  (it over-covers and is wider than the Monte-Carlo interval at interior settings), so
  it is not the default. It applies only to the two-way random absolute-agreement
  design, at `conf_level` 0.90, 0.95, or 0.99, and aborts on any other design or
  level, on consistency, on fixed raters, and on unbalanced, incomplete, or
  within-cell-replicated data. The
  averaged `ICC(A,k)` interval, and a numeric `unit` (a D-study projection `ICC(A,m)`
  to the mean of `m` raters, for any `m >= 1`), are the exact Spearman-Brown image of
  the `ICC(A,1)` interval. Its correction constant is calibrated by simulation
  separately for each supported level — it is never interpolated between levels, which
  is why other levels abort rather than approximating one — and for intraclass
  correlations below about 0.6, and at 0.99 throughout, rests on that simulated
  coverage rather than an external benchmark. Two properties to know before quoting a
  limit: the two-sided interval is **not equal-tailed** (where rater variance is large
  relative to error and subjects are many, non-coverage is almost all on one side), so
  a limit is not a one-sided bound at half the complementary level; and at 0.99 with
  very few raters it can be near-vacuous (median width 0.905 at 2 raters and 40
  subjects), which is the cost of a deep tail on little rater information.

* The `lavaan` (SEM) engine now fits the **crossed (Design 1) multilevel** design:
  `icc(..., engine = "lavaan", cluster = ...)` estimates the five-component
  decomposition (cluster, subject-in-cluster, rater, cluster-by-rater, residual)
  via a two-level structural-equation model and reports the subject- and
  cluster-level ICCs (plus the conflated diagnostic) with either the Monte-Carlo
  interval (the default) or the parametric bootstrap (`ci_method = "bootstrap"`),
  which simulates two-level datasets from the fitted moments and refits per
  resample (the parametric bootstrap needs complete, balanced data with equal
  cluster sizes). Random raters; cross-validated against the REML mixed-model
  engines (consistency ICCs agree essentially exactly; the documented ML-vs-REML
  and rater-mean small-sample differences shrink as clusters grow), and the
  bootstrap interval agrees with the Monte-Carlo interval within Monte-Carlo
  tolerance. Nested designs and within-cell replicates remain loud, classed
  refusals.
* The `lavaan` (SEM) engine now also fits the crossed (Design 1) multilevel
  design with **fixed raters** (`raters = "fixed"`) at both the subject and
  cluster levels, on complete, balanced data with equal cluster sizes. The rater
  term is the McGraw & Wong Case-3A finite-population variance read from the
  between-level rater intercepts; cross-validated against the `glmmTMB`
  fixed-rater multilevel fits (agreement asymptotic under the ML-vs-REML gap,
  consistency identical to the random-rater fit). Because lavaan's random-rater
  estimate is the raw quadratic form, the fixed-rater ICC differs from the
  random-rater one by the finite-population correction, which the REML mixed-model
  engines do not carry into their random estimate. Monte-Carlo interval only — the
  fixed-rater parametric bootstrap is not yet available. Fixed-rater nested,
  within-cell-replicate, and incomplete/unbalanced multilevel SEM remain loud,
  classed refusals.
* The `lavaan` (SEM) engine now fits the crossed (Design 1) multilevel design
  with **random raters** on **incomplete** and **unbalanced** data, not only on
  complete, balanced data: `icc(..., engine = "lavaan", cluster = ...)` estimates
  around missing subject-by-rater cells by two-level full-information maximum
  likelihood and fits unequal cluster sizes natively. The subject- and
  cluster-level ICCs are cross-validated against the REML mixed-model engines
  (consistency near-exact; agreement within the documented index-class split),
  the averaged cluster-level ICC uses the same inverse-Simpson `k_c^eff` divisor,
  and the rater main-effect variance carries the documented small-sample
  inflation, which generalizes under unequal cluster sizes to use the harmonic
  mean of the per-cluster subject counts. The interval is Monte-Carlo only on
  incomplete or unbalanced data (the parametric bootstrap cannot reproduce a
  missingness pattern and its coverage is validated only on balanced data);
  balanced, complete data keeps the bootstrap. Fixed-rater incomplete/unbalanced
  multilevel SEM remains a loud, classed refusal.
* `tidy(icc(...))` and `tidy(d_study(...))` gain a `type` column.
* The conflated diagnostic (`level = "conflated"`) now also reports a **consistency**
  form (`type = "consistency"`), not just absolute agreement. It is the flat two-way
  consistency ICC read off the multilevel fit (dropping the rater main-effect
  variance, McGraw & Wong 1996) -- the symmetric twin of the agreement Eq. 14 -- so a
  default `level = "conflated"` call now reports both. Random raters, crossed Design 1,
  balanced or incomplete, across the `glmmTMB`, `lme4`, and `brms` engines. Like the
  cluster level it needs raters that bridge clusters; without bridging the conflated
  level is dropped (or aborts if it is the only level requested).
* The **averaged cluster-level ICC** (`level = "cluster"`, `unit = "average"`) now ships
  on **incomplete/ragged** multilevel data (crossed Design 1, random raters), where it
  previously aborted. The averaging divisor is the effective number of raters behind each
  cluster's observed (cells-pooled) mean — the inverse-Simpson harmonic `k_c^eff`, reported
  on the fitted object and equal to the rater count on complete data. A rater-balanced
  cluster mean would have a different (higher) effective count. This ships for **every
  random-rater engine** — `glmmTMB`, `lme4`, and the Bayesian `brms` engine (which applies
  the same divisor to the posterior draws' variance components, its credible interval
  covering the population value across the cluster-count axis).
* The `autoplot()` / `plot()` methods share a cohesive look: a clean theme, a
  colourblind-safe (Okabe–Ito) palette for the variance-component bars and the per-level
  multilevel panels, and direct value labels on the coefficient and component plots. The
  D-study reliability curve now draws **each projected curve as its own line** — one per
  error definition (absolute agreement vs. consistency) and, for replicate fits, per
  occasion setting — with a legend, instead of connecting the overlaid projections into a
  single zig-zag. `ggplot2` remains a `Suggests` dependency.

## Bug fixes

* `engine = "lme4"` now explains the `merDeriv` requirement as what it is:
  every lme4 fit checks for `merDeriv` on entry, before any interval method is
  chosen, because that is where the parameter covariance comes from. The
  previous message attributed the requirement to one interval method, which
  got it wrong for anyone who had asked for a different one.

* Three error messages raised on degenerate data told you to retry with
  `ci_method = "montecarlo"` on data where that method also fails. In the worst
  case the advice pointed **away** from a method that works: when every subject
  has the same score profile, `ci_method = "npbootstrap"` would suggest
  `"montecarlo"`, which also errors, while `ci_method = "bootstrap"` returns a
  usable interval on that same data. A seeded sweep of each error's own trigger
  condition measured every available method against it; the messages raised by
  `"bootstrap"`, `"searle"`, `"burch"` and `"npbootstrap"` on degenerate data now
  name another method only where it was measured to work there. The one message
  whose suggestion the sweep confirmed keeps it.

* The error raised by `ci_method = "npbootstrap"` on degenerate observed data
  stated that between- or within-subject variance was exactly zero. That was
  false for one of the two conditions it guards: the interval is also undefined
  when the jackknife standard error is zero, which happens on data whose
  variances are both perfectly healthy — the message then reported a finite
  `log F` inside a sentence claiming zero variance. These messages now report the
  quantities that failed the check rather than asserting a cause, so what they
  say holds on every dataset that reaches them. The errors' conditions, classes
  and opening lines are unchanged.

* Projecting a one-way interval to a numeric `unit` (a D-study projection to `m`
  raters) could return a confidence interval lying **entirely above 1** — outside
  the ICC's range, sometimes with the limits reversed, and not containing its own
  point estimate — with no error. It affected `ci_method = "searle"`, `"burch"`,
  and `"npbootstrap"` on balanced one-way data whenever the requested `m` was large
  relative to the number of ratings per subject and the lower confidence limit fell
  low enough: the Spearman-Brown projection has a pole that such a limit crosses,
  flipping the sign of the result. Reaching it needed no unusual data — the
  package's own `sf_ratings` example hits it at `unit = 10`. These projections now
  fail with a classed error naming the pole and pointing at
  `ci_method = "montecarlo"`, which projects them correctly. Projections that do
  not cross the pole are unchanged, including every `unit = "single"` and
  `unit = "average"` result.

## Documentation

* The *Getting started*, *Choosing an ICC*, and *Glossary* articles have been
  rewritten for readability: long sentences split, and dashes standing in for a
  colon or a full stop replaced. Nothing about what the package computes or
  reports changed, and every claim the pass touched was checked against the text
  it replaced.

* The *Multilevel designs* article now **runs** the `design` argument instead of
  only naming it. The same simulated classroom table is fitted three ways — the
  crossed reading `icc()` infers from the reused rater labels, then
  `design = "nested_in_clusters"` and `design = "nested_in_subjects"` — so the
  three different answers, and the fact that only you know which is right, are
  visible on the page. The article had said you reach for `design` when missing
  cells make the crossing pattern ambiguous; it also settles what repeated rater
  labels mean on complete data, which is what `icc()`'s own message recommends it
  for, and the article now says so.

* The *D-studies and within-cell replicates* article now runs the numeric `unit`
  projection it previously mentioned only in passing, showing the `ICC(A,6)` row
  it adds to a coefficient table and that the row matches `d_study()` at
  `m = 6` in both estimate and interval. Beside it the article shows the error
  raised when absolute agreement is projected for fixed raters, and the two
  remedies that message names.

* The `?icc`, `?d_study`, and `?choose_icc` help pages now say what each
  documented method returns. Every one of those pages documents a function
  together with its `format()`, `print()`, and (as applicable) `summary()`,
  `tidy()`, `glance()`, `autoplot()`, and `plot()` methods, but their *Value*
  sections described only the object the main function returns; each now lists
  the main function and every method sharing the page, naming the method in
  full. What these functions return is unchanged.

* `?icc`'s example now calls the shipped `ratings` dataset directly, and shows
  its first rows so the long, one-rating-per-row layout `icc()` expects is
  visible on the page. The example previously rebuilt an identical data frame by
  hand under the same name, shadowing the shipped object for the rest of the
  page.

* The *Estimation engines* and *Confidence-interval methods* articles show the
  `brms` engine's output in pre-computed blocks, because knitting them would need
  a Stan toolchain. Those blocks are now generated from a committed fit and
  checked against it, so they cannot drift from what the engine really prints.
  Two bullet glyphs in the custom-prior warning are corrected to the characters
  `icc()` actually emits, and the engines article now says that a design this
  small may also report sampler divergences, which the shown output omits.
* The README now shows what the plots look like: the `autoplot()` forest plot of
  a default `icc()` fit, and a `d_study()` reliability curve projecting that fit
  to other rater counts. Both figures carry alt text. The front page also gains a
  *Learn more* index of the articles and a *Related work* comparison table.
* The `?icc` documentation of the classical closed forms no longer claims that
  `"searle"` and `"burch"` give a finite interval on every dataset: on data with
  no between-subject variance at all, `"burch"` aborts with a classed error (its
  kurtosis standardization divides by zero there) while `"searle"` still returns
  an interval — the asymmetry the vignette already states. For the single-rater
  coefficient that interval is the attained minimum; the averaged projection
  carries that minimum through the Spearman-Brown pole and reports `-Inf`, which
  a default call prints beside it.
* The `?icc` reference entry for Burch (2011) now cites the correct article —
  "Assessing the performance of normal-based and REML-based confidence intervals
  for the intraclass correlation coefficient", *Computational Statistics and Data
  Analysis*, 55, 1018–1028 — matching the glossary's already-corrected entry.
* The *Confidence-interval methods* vignette now covers the four opt-in
  `ci_method` values — `"npbootstrap"`, `"searle"`, `"burch"`, and `"mpl"` —
  with each method's design fence, determinism, `conf_level` set, `unit`
  behavior, and when to reach for it over the default, plus live-evaluated
  comparisons and new glossary entries for all four. The universal and
  negative claims in the vignette's MPL subsection are swept by the same
  mechanical claim-checker that already guards the `?icc` MPL documentation.
* The package comparison and "related work" documentation no longer presents
  `gtheory` as an alternative package to reach for: it was archived from CRAN in
  March 2025 and is not a dependency. The historical numerical agreement between
  the `lavaan` (SEM) engine and `gtheory` is retained as a cited reference.
* `ci_method = "bootstrap"` now documents what its interval and its point estimate
  do at the zero-between-subject-variance boundary: because the point comes from
  the model fit and the endpoints from quantiles of the refits, the reported lower
  limit can sit just *above* the reported point. Both numbers are zero to any
  reading where that happens, and **no reported value changed** — a committed
  sweep records the measurement the documentation cites.
* The README no longer describes the Bayesian engine as forthcoming: `engine =
  "brms"` ships, with `ci_method = "posterior"`, `posterior_summary`, and
  `prior`/`brm_args` arguments, and it now appears in the README's list of
  estimation engines alongside `glmmTMB`, `lme4`, and `lavaan`. The README's
  base-install list was also two packages short, and described what an
  installation retrieves rather than what the package declares; it now names
  every non-base entry of the `Imports:` field (`lifecycle` and `tibble` were
  missing).
* The README's *Installation* section and the *Estimation engines* article now
  name the dependency the declared `Imports:` field does not reveal: `glmmTMB`
  lists `lme4` in its own `Imports:`, so the `lme4` package is on the library
  path after a plain install. Both surfaces also say what that does **not** buy
  you — `engine = "lme4"` additionally needs `merDeriv`, which every lme4 fit
  checks for on entry whatever interval method is asked for, and `merDeriv`
  stays in `Suggests:`. `glmmTMB` is the only engine a plain install leaves
  ready to use.
* The *Multilevel designs* vignette no longer says the multilevel design is
  never declared by the user. `icc()` infers it from the crossing pattern on
  complete data, but when missing cells leave that pattern ambiguous the
  `design` argument is how you resolve it — as the same vignette's section on
  incomplete data already explained.
* The *Getting started* vignette now shows `summary()` on a fitted `icc`. It
  reprints the report and appends interpretive notes — for the default two-way
  fit shown there, one per error definition reported plus one on what a single
  rating per cell cannot separate — output no vignette displayed before.
* The *D-studies and within-cell replicates* vignette now shows a projection as
  data: `tidy()` on a `d_study()` result — where `m`, the rater-count column, is
  the one column it carries that `tidy()` on the fit does not — `glance()` on the
  same projection, and `d_study()`'s own `conf_level`, `mc_samples`, and `seed`
  settings, which take the fit's values whenever the fit carries them and can be
  overridden per call. It also describes the `plot()` wrapper for `autoplot()`.
* `autoplot()` on a `d_study()` result now carries a runnable example on
  `?d_study`, matching the one `autoplot()` on an `icc` fit already had.
* The *Confidence-interval methods* article's quantified claims are now backed
  by tests, and reading it through found three of them wrong. It said the
  Monte-Carlo and parametric-bootstrap upper bounds in its side-by-side table
  coincide, where at the table's own two decimals only ICC(A,k)'s round alike,
  and the bootstrap's upper bounds do not all fall on the same side of the
  Monte-Carlo ones. It said the `"lavaan"` engine offers Monte-Carlo
  intervals only, where that engine bootstraps complete data, and a multilevel
  lavaan fit needs balanced clusters and random raters besides. And it described
  `"searle"` at zero between-subject variance as returning its attained minimum,
  which is true of the single-rater coefficient and not of the averaged
  projection (above). All three are corrected. A link to the glossary's
  *Confidence interval vs. credible interval* entry pointed at an anchor the
  built site does not emit and is fixed, and the terms *consistency*, *REML* and
  *variance component* are now linked to their glossary definitions where the
  article first uses them.

# intraclass 0.1.0

First public release. **intraclass** estimates interrater-reliability intraclass
correlation coefficients (ICCs) within the generalizability-theory framework using
modern mixed-model variance-component estimation (rather than the classical ANOVA
mean-squares approach), with boundary-aware Monte-Carlo confidence intervals and
guidance on choosing the right coefficient. Every estimator is verified against
independent oracles — published worked examples, `psych`/ANOVA cross-checks,
alternate engines, and seeded simulations.

## Estimating ICCs

* `icc()` computes the full interrater-reliability ICC family from a linear mixed
  model: absolute agreement vs. consistency (`type`), single vs. average (`unit`),
  random vs. fixed raters (`raters`), and one-way vs. two-way (`model`) designs —
  the classic Shrout & Fleiss / McGraw & Wong coefficients — each reported with a
  boundary-aware Monte-Carlo confidence interval and its Shrout & Fleiss equivalent.
* A second interval method, `ci_method = "bootstrap"`: a parametric bootstrap that
  simulates response vectors from the fitted model, refits, and takes percentile
  quantiles (`boot_samples` resamples). It does not rely on the asymptotic-normal
  covariance approximation the Monte-Carlo default uses, at the cost of a refit per
  resample. Available for every design the `"glmmTMB"` (`simulate()` + refit) and
  `"lme4"` (`bootMer`) engines fit — two-way random and fixed, one-way, and the
  multilevel designs — at both levels, and for the random two-way design the
  `"lavaan"` engine (which simulates from the fitted SEM's implied moments and
  refits). For fixed raters the finite-population \eqn{\theta^2_r} is recomputed
  directly from each refit.
* Imbalanced and **incomplete** (missing-cell) designs are handled directly by the
  mixed model: it uses the effective number of ratings `k_eff` (the harmonic mean of
  the per-subject counts) as the `ICC(*,k)` divisor and aborts loudly on a
  disconnected, unidentified design.
* **Multilevel** ICCs for subjects nested in clusters — pupils in classrooms,
  patients in clinics — following ten Hove, Jorgensen & van der Ark (2022). Supply a
  `cluster` column to get subject-level (within-cluster) and cluster-level
  (between-cluster) coefficients via `level`. Covers raters crossed with clusters
  (Design 1) or nested in clusters/subjects (Designs 2–3), complete or incomplete
  crossed data, and fixed raters at the subject level on **both balanced and
  incomplete** crossed data (the finite-population rater variance is read from the
  ragged rater-contrast fit, so it differs from the random-rater ICC under imbalance).
  Fixed raters are also supported at the **cluster** level for the crossed (Design 1)
  design on **balanced, complete** data — signal \eqn{\sigma^2_c}, error the
  finite-population \eqn{\theta^2_r} plus the cluster-by-rater term — where the
  coefficient equals the random-rater cluster-level ICC.
  Fixed raters in the **nested** Design 2 (raters nested in clusters) are likewise
  supported at the subject level on **both balanced and incomplete/ragged** data — the
  finite-population rater variance is formed per cluster (each cluster's own raters,
  with its own effective rater count on ragged data) and averaged over clusters.
  `level = "conflated"` reports the biased single-level ICC you would get by ignoring
  the clustering (ten Hove et al. 2022, Eq. 14) — a diagnostic contrast, flagged in
  `print()` as not a recommended coefficient (absolute-agreement, crossed designs,
  balanced **or incomplete**).
* **Within-cell replicates**: when a subject-by-rater cell is rated more than once,
  `icc()` fits the two-way random model with a subject-by-rater interaction,
  separating the interaction variance (stable disagreement) from pure rating error
  instead of confounding them — and reports both. A new `occasions` argument averages
  over the replicates (`occasions = "average"`), giving the reliability of a rater's
  mean-of-replicates score. Balanced, complete replicated two-way designs, random
  **or fixed** raters — with fixed raters the rater main effect is the
  finite-population \eqn{\theta^2_r} (McGraw & Wong Case 3A), which equals the random
  \eqn{\sigma^2_r} on balanced data, so fixed reproduces the random coefficients.
  Within-cell replicates are also supported for **multilevel** designs — crossed
  Design 1 (a six-component fit) and nested Design 2 (five components) — adding a
  `(1 | cluster:subject:rater)` term so the highest-order residual splits into the
  interaction and pure error at the subject level. **Ragged** replicated two-way
  random data (unequal per-cell counts or missing cells) fits the single-occasion
  coefficients directly, as the replicate analogue of an incomplete design. (Design 3,
  the multilevel one-way, has no separable interaction to split; the occasion-averaged
  coefficient on ragged data is not yet supported.)
* `d_study()` now projects the rater count off a **within-cell replicate** fit,
  returning one reliability curve per occasion setting (a new `occasions` column): the
  rater and interaction terms divide by the projected count `m`, pure error by
  `m * n_o`, so at `m` = the observed rater count each curve matches the fitted
  `ICC(*,k)`. Single-level two-way (fixed-rater consistency via Spearman-Brown; fixed
  absolute agreement refused) and multilevel (crossed Design 1 + nested Design 2 —
  subject level across occasion settings, cluster level single-occasion) replicate fits
  are supported.
* `d_study()` also projects the **occasion count** off a within-cell replicate fit — a
  new `n_o` argument (mutually exclusive with `m`) that holds the raters fixed and
  sweeps the number of occasions: "how reliable would each rater's mean of `n_o` ratings
  be?". Because occasion averaging cancels only pure error, the curve rises to a
  **finite ceiling below 1** (not toward 1, as a rater projection does), and it is
  well-posed for **fixed absolute agreement** — the axis a rater projection cannot take.
  On a multilevel fit the subject level rises with `n_o` while the cluster level is flat
  (occasion-invariant). Projecting the occasion count off a **ragged** replicate fit
  remains unsupported (the occasion-averaged ragged divisor is an open modeling
  question).

## Engines

* Default **glmmTMB** engine (boundary-robust REML), with a selectable
  `engine = "lme4"` (via `merDeriv`) that covers every design glmmTMB does — two-way
  random and fixed raters, one-way, and the multilevel designs (crossed and nested)
  at both levels — on both balanced and incomplete/ragged data, agreeing with glmmTMB
  on both the point estimate and the Monte-Carlo interval (a ragged fit that lands on
  a variance-component boundary falls back to glmmTMB). A selectable
  `engine = "lavaan"` — an
  SEM common-factor generalizability model (Jorgensen 2021) whose absolute-agreement
  coefficient uses the indicator-mean rater-variance estimator — covers the two-way
  design with random or fixed raters, on both complete and **incomplete** data
  (missing cells estimated by full-information maximum likelihood), and both the
  Monte-Carlo and the parametric-bootstrap interval (bootstrap on complete data). For
  fixed raters the SEM agreement uses the McGraw & Wong Case-3A bias-corrected
  finite-population \eqn{\theta^2_r} (the raw indicator-mean variance minus the mean
  sampling variance of the rater means), which equals the mixed-model estimate on
  balanced data. A selectable **`engine = "brms"`** — the first Bayesian engine —
  fits the two-way **random** model in Stan under a sourced half-*t*(4, 0, 1) prior
  on the random-effect standard deviations (ten Hove, Jorgensen & van der Ark 2020),
  reporting the posterior-mode (MAP) point estimate and a percentile **credible**
  interval via a new `ci_method = "posterior"` (the forced, Bayesian-only interval
  method). It covers the balanced, complete two-way random design (agreement and
  consistency, single and average); a `brm_args` list forwards sampler/backend
  options (e.g. `backend = "cmdstanr"`, `chains`, `iter`, `cores`) to `brms::brm()`.
  Chains sample sequentially on one core by default (matching brms); a periodic
  reminder suggests `brm_args = list(cores = ...)` for parallel sampling. `brms`,
  `lavaan` and `merDeriv` live in `Suggests`, so a plain install fetches none of the
  three (asking for `merDeriv` also brings `lavaan`, which it needs). `lme4` itself
  arrives regardless, as a dependency of `glmmTMB`, but the lme4 engine also needs
  `merDeriv`, so it too waits on a further install. The Bayesian engine also fits
  the **multilevel** designs at the subject level: the crossed Design 1
  (five components, subject and cluster levels) and the nested Design 2 (raters
  nested in clusters, four components, subject level), each under the same sourced
  half-*t* prior with MAP + percentile credible intervals. Beyond the two-way random
  path it covers the single-level **one-way** random design (`model = "oneway"` —
  `ICC(1)`/`ICC(1,k)`) and **fixed** raters (`raters = "fixed"` — the McGraw & Wong
  finite-population \eqn{\theta^2_r} read directly from the posterior of the rater
  effects), both balanced and complete. Fixed raters are also supported at the
  **multilevel** subject level, balanced — the crossed Design 1 and the nested
  Design 2 — with \eqn{\theta^2_r} / \eqn{\theta^2_{r:c}} read per posterior draw and
  moment-corrected so the credible interval covers the fixed-population coefficient
  (a bias correction that matters when each cluster's raters are estimated from few
  subjects, and is boundary-aware at zero rater variance). The Bayesian engine also
  reports the **conflated** diagnostic (`level = "conflated"`, the biased
  ignore-the-clustering ICC of ten Hove et al. 2022, Eq. 14): a variance-ratio
  push-forward composed off the same crossed five-component posterior draws, with the
  frequentist glmmTMB conflated point falling inside its credible interval. It also fits
  **within-cell replicates** (more than one rating per subject×rater cell): the residual
  splits into the subject×rater interaction and pure error, and `occasions = "average"`
  reports the reliability of the replicate mean (pure error divided per posterior draw by
  the replicate count) — single-level two-way, random **or fixed** raters (with fixed
  raters the rater slot carries the finite-population \eqn{\theta^2_r} read per posterior
  draw, equal to \eqn{\sigma^2_r} on balanced data), and **multilevel** designs (crossed
  Design 1, six components; nested Design 2, five components; random raters, subject level),
  all balanced. Finally, the Bayesian
  engine now fits **incomplete/ragged** random-rater data (unequal or missing
  subject×rater cells) for the two-way single-level design and the crossed (Design 1)
  multilevel design (subject level, and the single-rater cluster `ICC(c,1)`; the averaged
  cluster `ICC(c,k)` is dropped with a note, as for the other engines): the model is fit
  on the observed cells and the same harmonic-mean `k_eff` divisor + connectedness
  identifiability used by the other engines are applied per posterior draw. Because
  random-rater ICCs are ratios of variance components, this needs no moment correction.
  The Bayesian engine also fits **incomplete/ragged fixed-rater** data for the two-way
  single-level design and the crossed (Design 1) fixed-rater **multilevel** design (subject
  level) (`raters = "fixed"`): the finite-population \eqn{\theta^2_r} is read from the ragged
  rater-contrast posterior, and — because the rater means are then estimated from unequal
  cell counts — the moment correction that keeps the credible interval covering the
  fixed-population coefficient becomes active (it is negligible on balanced data). The
  Bayesian engine now also fits **incomplete/ragged nested** **random**-rater data at the
  subject level — Design 2 (raters nested in clusters) and Design 3 (raters nested in subjects,
  the multilevel one-way, agreement-only): the shipped nested fits are run on the observed cells
  with the same harmonic-mean `k_eff` divisor + connectedness / per-subject identifiability gates
  the other engines use, and — random raters being ratios of variance components — need no moment
  correction. The Bayesian engine now also fits **incomplete/ragged single-level one-way** data
  (`ICC(1)`/`ICC(1,k)`): the shipped one-way fit is run on the observed ratings with the same
  harmonic-mean `k_eff` divisor, a ratio of variance components needing no moment correction.
  The Bayesian engine also reports the **fixed-rater cluster level** for the crossed (Design 1)
  design on balanced data (`raters = "fixed"`, `level = "cluster"`): the between-cluster ICC is
  read off the same crossed fixed multilevel posterior draws (signal \eqn{\sigma^2_c}, error the
  finite-population \eqn{\theta^2_r} plus the cluster-by-rater variance), a variance-ratio
  push-forward that equals the random-rater cluster-level ICC on balanced data — so it now
  returns **both** levels for balanced fixed raters, matching the `glmmTMB`/`lme4` engines.
  Finally, it fits **incomplete/ragged fixed-rater nested** (Design 2) data at the subject level:
  \eqn{\theta^2_{r:c}} is read per posterior draw with the per-cluster moment correction applied
  to each cluster's own rater count, so unequal per-cluster counts and the boundary (zero rater
  variance) are handled, and a seeded coverage reference confirms the credible interval covers at
  both moderate and high cluster counts. Incomplete within-cell-replicate and numeric-`unit`
  (D-study) Bayesian fits, and the incomplete/unbalanced fixed-rater *cluster* level (open for
  every engine), are planned for a future release.
* A new **`prior`** argument lets you override the sourced half-*t*(4, 0, 1) prior for
  `engine = "brms"` with any \pkg{brms} prior object (from `brms::set_prior()` /
  `brms::prior()`) — intended for prior-sensitivity, method-comparison, or simulation work.
  The default (`prior = NULL`) is unchanged and reproduces earlier results bit-for-bit.
  Supplying a custom prior is a deliberate deviation that **voids the package's coverage
  guarantees** (which hold only for the sourced prior), so `icc()` emits a loud classed
  (`intraclass_custom_prior`) warning: a vague or flat SD prior can *worsen* small-\eqn{k}
  boundary bias, since the half-*t* is weakly informative on purpose. The prior stays
  owned by the package elsewhere — it may not be set through `brm_args`.
* A new **`posterior_summary`** argument chooses how `ci_method = "posterior"` reduces the
  posterior draws to a credible interval: `"percentile"` (the default, unchanged) or
  `"hpdi"` (the highest-posterior-density interval — the narrowest interval covering the
  credible mass, computed with a dependency-free helper). Percentile stays the default
  because it is monotone-transformation invariant and degrades gracefully at the variance
  boundary, and percentile (not HPD) intervals give nominal coverage at small rater counts
  (ten Hove et al. 2020); the HPDI is offered for comparison, not as a strict upgrade, and
  no coverage is claimed for it. The printed header names the HPDI variant. Setting
  `posterior_summary` for a non-posterior interval method is an error.

## Choosing, projecting, and visualizing

* `choose_icc()` — an interactive and programmatic decision helper that recommends
  which ICC to report, explains each choice, and emits the exact `icc()` call to run.
  It gives advice only; it does not fit.
* `d_study()` — projects a fitted ICC's reliability to the mean of an arbitrary number
  of raters (a generalizability decision study), with an `autoplot()` reliability
  curve; `icc()`'s `unit` also accepts numbers for one-off projections. For a
  **multilevel** fit it projects the rater count at each level (subject and/or
  cluster), returning one curve per level (a `level` column; `autoplot()` facets by
  it); on **incomplete** data it projects the subject level (the cluster level is
  dropped with a note). The projection band follows the fit's `ci_method`: a
  **bootstrap** fit reprojects its stored resamples, so at the observed rater count the
  band matches the fitted average-measure bootstrap interval exactly.
* `autoplot()` / `plot()` methods for `icc` objects draw a coefficient forest plot
  and a variance-component decomposition; `tidy()` / `glance()` give tidy summaries.
  Plotting needs `ggplot2` (a `Suggests` dependency).
* Console output is styled with **cli**: `print()` / `summary()` show a rule header and
  an aligned coefficient table with the point estimate emphasized and the interval
  dimmed, and `choose_icc()`'s interactive walkthrough is a guided decision tree that
  displays your choices so far. Styling degrades to plain text wherever it is
  unavailable (knitr, CRAN, a non-interactive session), so printed values are unchanged.

## Data and documentation

* Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout the docs.
* Vignettes: *Getting started*, *Choosing an ICC* (the decision framework, with a
  decision-tree diagram), *Multilevel designs* (subject/cluster level, crossed and
  nested, complete and incomplete), *Estimation engines* (glmmTMB, lme4, lavaan, and
  the Bayesian brms engine with the `prior=` override), *Confidence-interval methods*
  (Monte-Carlo, bootstrap, and Bayesian `posterior` credible intervals with
  percentile/HPDI summaries), and *D-studies and within-cell replicates* (with the
  `autoplot()` plots).
* *Getting started* and *Choosing an ICC* were rewritten to be approachable to
  readers new to reliability: a from-scratch on-ramp ("what an ICC tells you"),
  plainer language for the confidence interval and the estimand vocabulary, and a
  new interpretation-band guide (poor / moderate / good / excellent, after Koo & Li
  2016 and Cicchetti 1994) framed as conventions to read against the interval —
  not verdicts the package computes for you.
* A new *Glossary* article defines the recurring vocabulary — variance component,
  REML, credible vs. confidence interval, `k_eff`, the zero-variance boundary, and
  the rest — in one place that the other articles link into.
* A new *Comparison with other packages* article shows, with numbers computed live
  from the shipped datasets, that `intraclass` reproduces `psych::ICC` and
  `irr::icc` across the McGraw & Wong family on balanced data (and that Gwet's
  model-based `irrICC` agrees too), then where it goes further — incomplete and
  unbalanced data, multilevel subject/cluster reliability, boundary-aware intervals,
  and guidance on which coefficient to report.

## Robustness (pre-release code review)

* `d_study()` now projects a **one-way** fit (a Spearman-Brown projection of `ICC(1)`)
  instead of erroring.
* A fixed-rater multilevel call (`icc(..., cluster =, raters = "fixed")`) now works with
  the default `level`, dropping the deferred cluster level to the subject level (as the
  nested-design path already did) rather than requiring an explicit `level = "subject"`.
* On incomplete crossed multilevel data, requesting an averaged cluster-level `ICC(c,k)`
  now drops just that (unsupported) row with a message and returns the subject-level and
  single-rater cluster results, instead of failing the whole call.
* An incomplete crossed multilevel design in which every subject is rated only once is
  now reported as unidentified rather than returning a spurious `ICC = 0.5`.
* `icc()` prints a one-time note when a multilevel design is inferred to be crossed from
  shared rater labels, so a nested design with reused, cluster-relative labels is not
  silently treated as crossed.
* `mc_samples` and `seed` are validated with clear, classed errors; invalid values
  (e.g. `mc_samples = 0`/`1`, a fractional or non-numeric value) no longer produce a
  silent `NA` interval or a bare base-R error.
* A degenerate fit with no variance in any component now fails loudly instead of
  returning a `NaN` estimate, and an unstable fit whose Monte-Carlo draws overflow is
  reported rather than silently truncated.
* The Monte-Carlo confidence interval for **fixed-rater** designs is now moment-corrected
  so it stays calibrated. Previously the finite-population \eqn{\theta^2_r} draws were
  displaced above the point estimate, which was harmless for crossed designs (rater means
  estimated from the whole sample) but materially **undercovered** for nested (Design 2)
  fixed raters as the number of clusters grew — down to ~37% coverage of a nominal-95%
  interval with many clusters and few subjects each, and the point estimate could even
  fall outside its own interval near the zero-rater-variance boundary. The draws are now
  re-centered on the point and floored as a per-draw average (so the interval remains
  boundary-aware and can reach \eqn{\theta^2_r = 0}); the **point estimate is unchanged**
  away from the boundary. Coverage is verified nominal across raters, subjects-per-cluster,
  and cluster counts. Applies to the `"glmmTMB"`, `"lme4"`, and `"lavaan"` engines.
