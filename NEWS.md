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
  boundary-aware confidence interval and its Shrout & Fleiss equivalent.
* **Every defined error definition is reported by default.** `type` is vectorized
  like `unit` and `level` and defaults to `c("agreement", "consistency")`, so a
  default two-way call returns `ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)` and `ICC(C,k)`
  from a single fit — agreement vs. consistency is post-fit arithmetic on the same
  variance components, so the extra coefficients are free (which matters most for
  the expensive `brms` engine). Pass a single `type` to report just that
  coefficient. A definition that is undefined for the design (consistency for a
  Design-3 nested-in-subjects fit, a fixed-rater absolute-agreement D-study
  projection, or absolute agreement when raters do not bridge clusters) is dropped
  with an informative message when reached through the default vector, and aborts
  with a teaching error when requested explicitly.
* Imbalanced and **incomplete** (missing-cell) designs are handled directly by the
  mixed model: it uses the effective number of ratings `k_eff` (the harmonic mean of
  the per-subject counts) as the `ICC(*,k)` divisor and aborts loudly on a
  disconnected, unidentified design. Rows whose `score` is `NA` are dropped and the
  rest analyzed as an incomplete design, with a suppressible
  `intraclass_dropped_rows` warning, so a missing rating and an absent row give the
  same answer. A frame that looked balanced only because of such rows is correctly
  seen as unbalanced.
* `icc()` rejects a non-finite `score` (`Inf`, `-Inf`, `NaN`) with a classed error
  naming the column and the offending rows, rather than passing it to the fitting
  engine and surfacing that engine's own unclassed message.
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
  `print()` as not a recommended coefficient — in **both** `type` forms: absolute
  agreement (Eq. 14) and its symmetric consistency twin, the flat two-way consistency
  ICC read off the multilevel fit (crossed designs, balanced or incomplete, across the
  `glmmTMB`, `lme4` and `brms` engines). Like the cluster level it needs raters that
  bridge clusters; without bridging the conflated level is dropped, or aborts if it is
  the only level requested.
* The **averaged cluster-level ICC** (`level = "cluster"`, `unit = "average"`) ships on
  **incomplete/ragged** multilevel data as well as complete (crossed Design 1, random
  raters). The averaging divisor is the effective number of raters behind each
  cluster's observed (cells-pooled) mean — the inverse-Simpson harmonic `k_c^eff`,
  reported on the fitted object and equal to the rater count on complete data. A
  rater-balanced cluster mean would have a different (higher) effective count. Every
  random-rater engine carries it: `glmmTMB`, `lme4`, and the Bayesian `brms` engine,
  which applies the same divisor to the posterior draws' variance components.
* **Within-cell replicates**: when a subject-by-rater cell is rated more than once,
  `icc()` fits the two-way random model with a subject-by-rater interaction,
  separating the interaction variance (stable disagreement) from pure rating error
  instead of confounding them — and reports both. An `occasions` argument averages
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

## Confidence intervals

* The default is a **boundary-aware Monte-Carlo interval** (`ci_method =
  "montecarlo"`), drawn from the fitted model's asymptotic parameter covariance.
  One coverage limitation is worth knowing before you quote it: when the subject
  effects are strongly skewed or heavy-tailed it under-covers, worst 0.6725 at
  chi-square(1) subject effects with a true ICC of 0.6, 50 subjects and 5 raters.
  Such runs neither abort nor warn, so `?icc`, the *Confidence-interval methods*
  article and the glossary all carry the caveat.
* `ci_method = "bootstrap"`: a parametric bootstrap that simulates response vectors
  from the fitted model, refits, and takes percentile quantiles (`boot_samples`
  resamples). It does not rely on the asymptotic-normal covariance approximation the
  Monte-Carlo default uses, at the cost of a refit per resample. Available for every
  design the `"glmmTMB"` (`simulate()` + refit) and `"lme4"` (`bootMer`) engines fit —
  two-way random and fixed, one-way, and the multilevel designs — at both levels, and
  for the random two-way design the `"lavaan"` engine (which simulates from the fitted
  SEM's implied moments and refits). For fixed raters the finite-population
  \eqn{\theta^2_r} is recomputed directly from each refit. At the
  zero-between-subject-variance boundary the reported lower limit can sit just *above*
  the reported point estimate, because the point comes from the model fit and the
  endpoints from quantiles of the refits; both numbers are zero to any reading where
  that happens, and a committed sweep records the measurement.
* `ci_method = "npbootstrap"` for the **one-way random** design: the non-parametric
  variance-stabilized **transformed bootstrap-*t*** of Ukoumunne et al. (2003). It
  resamples whole subjects rather than the fitted model, so it is boundary robust —
  it returns an interval where the Monte-Carlo default aborts on near-zero-ICC data —
  and robust to non-normal subject effects. Validated against the paper's exact
  Table I coverage. It is one-way only (aborts otherwise) and **not** a percentile
  bootstrap (the percentile and BCa variants under-cover and were deliberately not
  shipped). **Unbalanced** one-way designs (unequal ratings per subject) are covered
  for both `unit = "single"` and `unit = "average"`: the transform uses the ANOVA
  effective group size `n0` and the infinitesimal-jackknife SE its per-subject form
  (Ohyama 2025; Ukoumunne et al. 2003, Appendix A). Only a numeric `unit` (a
  projection to a chosen number of raters) is balanced-only — use `"montecarlo"` for
  an unbalanced projection.
* `ci_method = "searle"` and `ci_method = "burch"` for the **balanced one-way random**
  design: two **deterministic classical closed-form** intervals. `"searle"` is the
  exact-F pivot (Searle 1971, Table 9.14; McGraw & Wong 1996, Table 7), exact under
  normality; `"burch"` is the REML-based, kurtosis-adjusted interval of Burch (2011),
  which dips below the nominal level in fewer cells. One thing `"burch"` is **not**:
  a remedy for heavy tails — a simulation study measured it under-covering on strongly
  skewed subject effects about as badly as the default (worst 0.6655). `"searle"`
  landed closer to nominal coverage in most cells of every distribution family
  measured, which is the basis for preferring it. Like
  `"npbootstrap"` both are boundary robust and one-way only. Being closed forms they
  take no `mc_samples`, `boot_samples` or `seed` and report no standard error. On data
  with no between-subject variance at all, `"burch"` aborts with the classed
  `intraclass_singular_fit` condition (its kurtosis term divides by the between-subject
  mean square) while `"searle"` still returns an interval.
* Which of the two classical closed forms gives the **narrower** interval is
  conditional, and the documentation says so rather than quoting one pooled figure.
  On both grids that vary only the subject effect, `"burch"` is the narrower of the
  two in 16 of 16 cells of the smaller grid and 59 of 64 cells of the larger grid, with no
  distribution family reversing it on its median. That margin holds much the same up to a true ICC of 0.3 rather than shrinking as the true ICC rises (on the larger grid; the smaller grid's margin does shrink across its levels), then collapses to near parity at a true ICC of 0.6, on the one grid reaching that value, where every cell favouring `"searle"` sits, and it shrinks steadily as the subject count grows, measured at 5 raters. That is the only rater count present at every subject count, so an unstratified subject-count figure would be confounded. The *Confidence-interval methods* article tabulates both cuts.
  What `"burch"` does against `"searle"` also depends on what the residual is drawn
  from, and the three grids measure that:
  the two grids that vary only the subject effect put it narrower nearly everywhere, while the third, which draws the residual from the same family as the subject effect, puts it wider at every symmetric heavy-tailed family measured (a median width ratio of 1.2963 at t(5) with 100 subjects) and narrower at every lighter-tailed one, the normal included.
  Burch (2011) compares against this same exact-F interval and reports a
  *kurtosis-conditional* ordering, shorter for light-tailed data and wider for
  symmetric heavy-tailed data where the errors are non-normal too; his length
  comparison uses symmetric families throughout, so it settles nothing about skewed
  data either way. Neither interval is described as reliably the tighter one, and the
  coverage-based preference for `"searle"` stands.
* `ci_method = "mpl"` for the **balanced-complete two-way random** absolute-agreement
  `ICC(A,1)` (and `ICC(A,k)`): the **modified profile-likelihood** interval of Xiao &
  Liu (2013). Like the closed forms it is boundary robust — it returns a finite
  interval at the near-zero-ICC boundary where the Monte-Carlo default aborts — and
  takes no `mc_samples`, `boot_samples` or `seed` and reports no standard error. It is
  a deliberately **conservative** opt-in (it over-covers and is wider than the
  Monte-Carlo interval at interior settings), so it is not the default. It applies only
  to the two-way random absolute-agreement design, at `conf_level` 0.90, 0.95 or 0.99,
  and aborts on any other design or level, on consistency, on fixed raters, and on
  unbalanced, incomplete or within-cell-replicated data. A boundary endpoint is
  reported only when the profile deviance shows the confidence set reaching that
  boundary; a degenerate fit or a failed root search raises a classed
  `intraclass_engine_error` rather than a fabricated boundary value. The averaged
  `ICC(A,k)` interval, and a numeric `unit`, are the exact Spearman-Brown image of the
  `ICC(A,1)` interval. Its correction constant is calibrated by simulation separately
  for each supported level — never interpolated between levels, which is why other
  levels abort rather than approximating one. Two properties to know before quoting a limit: the two-sided
  interval is **not equal-tailed** (where rater variance is large relative to error and
  subjects are many, non-coverage is almost all on one side), so a limit is not a
  one-sided bound at half the complementary level; and at 0.99 with very few raters it
  can be near-vacuous (median width 0.905 at 2 raters and 40 subjects), the cost of a
  deep tail on little rater information.
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
* `ci_method = "posterior"` is the Bayesian engine's forced interval method; see
  *Engines* below.
* **When an interval method aborts on degenerate data, the error names another
  `ci_method` that works** — verified by running it on your data first, so the
  suggestion is a call that was just shown to succeed rather than a guess. A method is
  named only when every endpoint it reports is finite, correctly ordered and inside the
  coefficient's range. A balanced one-way fit can be pointed at `"searle"` and
  `"burch"`, a two-way random absolute-agreement fit at `"mpl"`, an unbalanced one-way
  fit at `"npbootstrap"`, and the default can reach `"bootstrap"` — which matters most
  on data with no between-subject variance, where `"bootstrap"` is often the only
  method that returns anything usable. Because the check runs the method rather than
  reasoning about the design, it falls silent wherever the method would not in fact
  help: fixed raters, multilevel, within-cell replicates, consistency, a `conf_level`
  or a subject/rater count outside a calibrated set, degenerate data, or a projection
  so large that a method's projection formula breaks down. Where nothing works, nothing
  is named; no message ever suggests the method you just asked for. A suggestion naming
  `"bootstrap"` or `"npbootstrap"` also names the `boot_samples` the trial ran at, and —
  when you set no seed of your own — the `seed` it used, so the call you are handed is
  exactly the call that was checked. The trial run never touches the random-number
  stream your session goes on to use. This adds guidance to an existing error and never
  substitutes one method for another: the call still fails, and still returns no
  interval.
* Projecting a one-way interval to a numeric `unit` crosses a Spearman-Brown pole when
  the requested `m` is large relative to the ratings per subject and the lower limit
  falls low enough. `"searle"`, `"burch"` and `"npbootstrap"` fail there with a classed
  error naming the pole and pointing at `ci_method = "montecarlo"`, which projects
  correctly, rather than returning an interval lying entirely above 1.

## Engines

* Default **glmmTMB** engine (boundary-robust REML), with a selectable
  `engine = "lme4"` (via `merDeriv`) that covers every design glmmTMB does — two-way
  random and fixed raters, one-way, and the multilevel designs (crossed and nested)
  at both levels — on both balanced and incomplete/ragged data, agreeing with glmmTMB
  on both the point estimate and the Monte-Carlo interval (a ragged fit that lands on
  a variance-component boundary falls back to glmmTMB). Every lme4 fit checks for
  `merDeriv` on entry, before any interval method is chosen, because that is where the
  parameter covariance comes from.
* A selectable `engine = "lavaan"` — an SEM common-factor generalizability model
  (Jorgensen 2021) whose absolute-agreement coefficient uses the indicator-mean
  rater-variance estimator — covers the two-way design with random or fixed raters, on
  both complete and **incomplete** data (missing cells estimated by full-information
  maximum likelihood), and both the Monte-Carlo and the parametric-bootstrap interval
  (bootstrap on complete data). For fixed raters the SEM agreement uses the McGraw &
  Wong Case-3A bias-corrected finite-population \eqn{\theta^2_r} (the raw indicator-mean
  variance minus the mean sampling variance of the rater means), which equals the
  mixed-model estimate on balanced data. The SEM engine also fits the **crossed
  (Design 1) multilevel** design: the five-component decomposition (cluster,
  subject-in-cluster, rater, cluster-by-rater, residual) via a two-level structural
  equation model, reporting the subject- and cluster-level ICCs plus the conflated
  diagnostic, with the Monte-Carlo interval or the parametric bootstrap (which
  simulates two-level datasets from the fitted moments and refits per resample, and
  needs complete, balanced data with equal cluster sizes). It covers **random** raters
  on incomplete and unbalanced data too — estimating around missing subject-by-rater
  cells by two-level FIML and fitting unequal cluster sizes natively, Monte-Carlo
  interval only there — and **fixed** raters at both levels on complete, balanced data
  with equal cluster sizes, where the rater term is the Case-3A finite-population
  variance read from the between-level rater intercepts (Monte-Carlo interval only).
  All of it is cross-validated against the REML mixed-model engines: consistency ICCs
  agree essentially exactly, and the documented ML-vs-REML and rater-mean small-sample
  differences shrink as clusters grow. Nested designs, within-cell replicates, and
  fixed-rater incomplete/unbalanced multilevel SEM remain loud, classed refusals.
* A selectable **`engine = "brms"`** — the first Bayesian engine — fits in Stan under a
  sourced half-*t*(4, 0, 1) prior on the random-effect standard deviations (ten Hove,
  Jorgensen & van der Ark 2020), reporting the posterior-mode (MAP) point estimate and a
  percentile **credible** interval via `ci_method = "posterior"` (the forced,
  Bayesian-only interval method). A `brm_args` list forwards sampler/backend options
  (e.g. `backend = "cmdstanr"`, `chains`, `iter`, `cores`) to `brms::brm()`; chains
  sample sequentially on one core by default, matching brms, and a periodic reminder
  suggests `brm_args = list(cores = ...)` for parallel sampling. Its coverage: the
  two-way random design (agreement and consistency, single and average) and the
  single-level **one-way** random design; **fixed** raters, with the McGraw & Wong
  finite-population \eqn{\theta^2_r} read directly from the posterior of the rater
  effects; the **multilevel** designs at the subject level — crossed Design 1 (five
  components, subject and cluster levels) and nested Design 2 (four components) — for
  random and for fixed raters, the latter with \eqn{\theta^2_r} / \eqn{\theta^2_{r:c}}
  read per posterior draw and moment-corrected so the credible interval covers the
  fixed-population coefficient (a correction that matters when each cluster's raters are
  estimated from few subjects, and is boundary-aware at zero rater variance), plus the
  **fixed-rater cluster level** for the crossed design on balanced data; the
  **conflated** diagnostic, a variance-ratio push-forward composed off the same crossed
  five-component draws, with the frequentist glmmTMB conflated point falling inside its
  credible interval; **within-cell replicates**, where the residual splits into the
  subject-by-rater interaction and pure error and `occasions = "average"` divides pure
  error per posterior draw by the replicate count (single-level two-way, random or fixed
  raters, and the multilevel crossed and nested designs, all balanced); and
  **incomplete/ragged** data for the two-way single-level design, the crossed (Design 1)
  multilevel design (subject level, and the single-rater cluster `ICC(c,1)`; the averaged
  cluster `ICC(c,k)` is dropped with a note, as for the other engines), the nested
  Designs 2 and 3, and the single-level one-way design,
  fit on the observed cells with the same harmonic-mean `k_eff` divisor and connectedness
  gates the other engines use — random-rater ICCs being ratios of variance components,
  these need no moment correction, while the ragged **fixed**-rater cases do carry it,
  the rater means being estimated from unequal cell counts. Incomplete within-cell-replicate
  and numeric-`unit` Bayesian fits, and the incomplete/unbalanced fixed-rater *cluster*
  level (open for every engine), are planned for a future release.
* A **`prior`** argument overrides the sourced half-*t*(4, 0, 1) prior with any
  \pkg{brms} prior object (from `brms::set_prior()` / `brms::prior()`) — intended for
  prior-sensitivity, method-comparison or simulation work. The default (`prior = NULL`)
  is unchanged. Supplying a custom prior is a deliberate deviation that **voids the
  package's coverage guarantees** (which hold only for the sourced prior), so `icc()`
  emits a loud classed (`intraclass_custom_prior`) warning: a vague or flat SD prior can
  *worsen* small-\eqn{k} boundary bias, since the half-*t* is weakly informative on
  purpose. The prior may not be set through `brm_args`.
* A **`posterior_summary`** argument chooses how `ci_method = "posterior"` reduces the
  draws to a credible interval: `"percentile"` (the default) or `"hpdi"` (the
  highest-posterior-density interval, the narrowest interval covering the credible mass,
  computed with a dependency-free helper). Percentile is the default because it is
  monotone-transformation invariant, degrades gracefully at the variance boundary, and
  gives nominal coverage at small rater counts where HPD does not (ten Hove et al. 2020);
  the HPDI is offered for comparison, not as a strict upgrade, and no coverage is claimed
  for it. The printed header names the HPDI variant. Setting `posterior_summary` for a
  non-posterior interval method is an error.
* `brms`, `lavaan` and `merDeriv` live in `Suggests`, so a plain install fetches none of
  the three (asking for `merDeriv` also brings `lavaan`, which it needs). `lme4` itself
  arrives regardless, as a dependency of `glmmTMB`, but `engine = "lme4"` also needs
  `merDeriv`, so it too waits on a further install. `glmmTMB` is the only engine a plain
  install leaves ready to use.

## Choosing, projecting, and visualizing

* `choose_icc()` — an interactive and programmatic decision helper that recommends
  which ICC to report, explains each choice, and emits the exact `icc()` call to run.
  It gives advice only; it does not fit.
* `d_study()` — projects a fitted ICC's reliability to the mean of an arbitrary number
  of raters (a generalizability decision study), with an `autoplot()` reliability
  curve; `icc()`'s `unit` also accepts numbers for one-off projections. It projects one
  curve per error definition the fit reports, and for a **multilevel** fit one per level
  (subject and/or cluster; `autoplot()` facets by it); on **incomplete** data it projects
  the subject level, dropping the cluster level with a note. A **one-way** fit projects
  by Spearman-Brown. The projection band follows the fit's `ci_method`: a **bootstrap**
  fit reprojects its stored resamples, so at the observed rater count the band matches
  the fitted average-measure bootstrap interval exactly.
* `d_study()` projects the rater count off a **within-cell replicate** fit, returning one
  reliability curve per occasion setting: the rater and interaction terms divide by the
  projected count `m`, pure error by `m * n_o`, so at `m` = the observed rater count each
  curve matches the fitted `ICC(*,k)`. Single-level two-way (fixed-rater consistency via
  Spearman-Brown; fixed absolute agreement refused) and multilevel replicate fits are
  supported.
* `d_study()` also projects the **occasion count** off a within-cell replicate fit — an
  `n_o` argument, mutually exclusive with `m`, that holds the raters fixed and sweeps the
  number of occasions: "how reliable would each rater's mean of `n_o` ratings be?".
  Because occasion averaging cancels only pure error, the curve rises to a **finite
  ceiling below 1**, and it is well-posed for **fixed absolute agreement** — the axis a
  rater projection cannot take. On a multilevel fit the subject level rises with `n_o`
  while the cluster level is flat. Projecting the occasion count off a **ragged** replicate
  fit is unsupported (the occasion-averaged ragged divisor is an open modeling question).
* `autoplot()` / `plot()` methods for `icc` objects draw a coefficient forest plot and a
  variance-component decomposition. They share a cohesive look: a clean theme, a
  colourblind-safe (Okabe–Ito) palette for the component bars and the per-level multilevel
  panels, and direct value labels. The D-study reliability curve draws **each projected
  curve as its own line** — one per error definition and, for replicate fits, per occasion
  setting — with a legend. `ggplot2` is a `Suggests` dependency.
* Console output is styled with **cli**: `print()` / `summary()` show a rule header and
  an aligned coefficient table with the point estimate emphasized and the interval
  dimmed, and `choose_icc()`'s interactive walkthrough is a guided decision tree that
  displays your choices so far. Styling degrades to plain text wherever it is
  unavailable (knitr, CRAN, a non-interactive session), so printed values are unchanged.

## Reading a fit

* `tidy()` and `glance()` give tidy summaries of a fit or a projection. `tidy()` names its
  coefficient-identifying column **`term`**, following the broom glossary the re-exported
  generic belongs to, so tools that key on `term` pick the labels up without a manual
  rename. **Every identifier column is present on every fit**, `NA` where the design does
  not define it — `occasions`, and for a projection `level` and `type` as well — so two
  tidied fits row-bind and a later added column cannot change an existing call's schema.
  `occasions` is a double column on every fit and every projection, so its type does not
  shift with the design either, and a `d_study()` occasion sweep at a non-integer count
  reports that count instead of rounding it.
* `glance()` reports `var_subject_rater` and `n_o` alongside `var_residual`, so a
  replicate fit no longer changes what `var_residual` means without saying so: the
  interaction term is named, and `n_o` gives the occasion count it was split at.
  `var_subject_rater` is `NA` without within-cell replicates, and `n_o` is `NA` there
  too and on ragged replicates, where cells hold different numbers of ratings and no
  single count applies. Two design columns say how to read the variance columns beside
  them: `raters` gives the rater treatment the fit used, so `var_rater` can be told
  apart as a random-rater variance or a fixed-rater finite-population term, and is `NA`
  on a one-way fit, whose interchangeable raters have no facet and whose rater variance
  is folded into `var_residual`; `replicates` says whether the design holds more than
  one rating per subject-by-rater cell, which `n_o` alone cannot, being `NA` on a ragged
  replicate design as well as on an unreplicated one.
  `glance()` also reports the sampler diagnostics `rhat` and `ess_bulk`, `NA` for the
  engines that do not sample. Every column is present on every fit, so two glanced fits
  row-bind exactly as two tidied ones do.
* `?icc` states which parts of the returned object are safe to depend on: the documented
  methods, plus `$fit` and `$call`. The rest of the list is internal and may change
  without a deprecation cycle.
* A choice argument takes **exactly one value**. Passing several — the full set of allowed
  values included — aborts with a classed error instead of quietly using the first. This
  covers `raters`, `posterior_summary`, `model`, `engine`, `ci_method`, `autoplot()`'s
  `what`, and every question `choose_icc()` asks (`model`, `unit`, `type`, `raters`,
  `level`), the chooser taking one answer per question. In `icc()` and `d_study()` the
  arguments that genuinely take several values are unaffected: `type`, `unit` and `level`,
  which default to reporting every value, and `occasions`, which defaults to one but still
  accepts both. Note the same names mean different things in the chooser, where they are
  answers rather than axes: `choose_icc(type = c("agreement", "consistency"))` now aborts
  where it used to recommend a single coefficient for agreement.

## Data and documentation

* Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout the docs.
* Vignettes: *Getting started*, *Choosing an ICC* (the decision framework, with a
  decision-tree diagram), *Multilevel designs* (subject/cluster level, crossed and
  nested, complete and incomplete), *Estimation engines* (glmmTMB, lme4, lavaan, and
  the Bayesian brms engine with the `prior=` override), *Confidence-interval methods*
  (every shipped `ci_method`, with each method's design fence, determinism,
  `conf_level` set, `unit` behavior, and when to reach for it over the default), and
  *D-studies and within-cell replicates*.
* A *Glossary* article defines the recurring vocabulary — variance component, REML,
  credible vs. confidence interval, `k_eff`, the zero-variance boundary, and the rest —
  in one place that the other articles link into.
* A *Comparison with other packages* article shows, with numbers computed live
  from the shipped datasets, that `intraclass` reproduces `psych::ICC` and
  `irr::icc` across the McGraw & Wong family on balanced data (and that Gwet's
  model-based `irrICC` agrees too), then where it goes further — incomplete and
  unbalanced data, multilevel subject/cluster reliability, boundary-aware intervals,
  and guidance on which coefficient to report.
* *Getting started* and *Choosing an ICC* are written to be approachable to readers new
  to reliability: a from-scratch on-ramp ("what an ICC tells you"), plain language for
  the confidence interval and the estimand vocabulary, and an interpretation-band guide
  (poor / moderate / good / excellent, after Koo & Li 2016 and Cicchetti 1994) framed as
  conventions to read against the interval — not verdicts the package computes for you.
* The quantified claims in the articles and help pages are backed by tests, and the
  universal and negative claims in the MPL documentation are swept by a mechanical
  claim-checker in CI against the committed coverage fixture. The `brms` output shown in
  the articles is generated from a committed fit and checked against it, because knitting
  those blocks would need a Stan toolchain.

## Failing loudly

* A degenerate fit with no variance in any component fails loudly instead of returning a
  `NaN` estimate, and an unstable fit whose Monte-Carlo draws overflow is reported rather
  than silently truncated.
* Interval settings are validated with classed errors: `mc_samples`, `boot_samples`,
  `conf_level` and `seed` in `icc()`, and `mc_samples`, `conf_level` and `seed` in
  `d_study()`, which takes no `boot_samples`. Invalid values (`mc_samples = 0`/`1`, a
  fractional or non-numeric value, a confidence level outside (0, 1), a seed that is not
  a single whole number) produce neither a silent `NA` interval nor a bare base-R
  error.
* An incomplete crossed multilevel design in which every subject is rated only once is
  reported as unidentified rather than returning a spurious `ICC = 0.5`.
* On incomplete crossed multilevel data, requesting an averaged cluster-level `ICC(c,k)`
  where it is unsupported drops just that row with a message and returns the rest, instead
  of failing the whole call. A fixed-rater multilevel call works with the default `level`,
  dropping the deferred cluster level to the subject level.
* `icc()` prints a one-time note when a multilevel design is inferred to be crossed from
  shared rater labels, so a nested design with reused, cluster-relative labels is not
  silently treated as crossed. The `design` argument is how you override that inference —
  both when the labels do not mean what the crossing pattern implies and when missing
  cells leave the pattern genuinely ambiguous.
* Error messages report the quantities that failed a check rather than asserting a cause,
  so what they say holds on every dataset that reaches them.
* The Monte-Carlo confidence interval for **fixed-rater** designs is moment-corrected so
  it stays calibrated. Without it the finite-population \eqn{\theta^2_r} draws sit above
  the point estimate, which is harmless for crossed designs (rater means estimated from
  the whole sample) but materially undercovers for nested (Design 2) fixed raters as the
  number of clusters grows — down to ~37% coverage of a nominal-95% interval with many
  clusters and few subjects each — and can put the point estimate outside its own interval
  near the zero-rater-variance boundary. The draws are re-centered on the point and
  floored as a per-draw average, so the interval remains boundary-aware and can reach
  \eqn{\theta^2_r = 0}. Coverage is verified nominal across raters, subjects-per-cluster
  and cluster counts, for the `"glmmTMB"`, `"lme4"` and `"lavaan"` engines.
