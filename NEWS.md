# intraclass 0.1.0

First public release. **intraclass** estimates interrater-reliability intraclass
correlation coefficients (ICCs) within the generalizability-theory framework using
modern mixed-model variance-component estimation (rather than the classical ANOVA
mean-squares approach), with boundary-aware Monte-Carlo confidence intervals and
guidance on choosing the right coefficient. Every estimator is verified against
independent oracles: published worked examples, `psych` and ANOVA cross-checks,
alternate engines, and seeded simulations. The package requires R 4.5.0 or newer,
a constraint imposed by its dependency chain rather than by its own code.

## Estimating ICCs

* `icc()` computes the interrater-reliability ICC family from a linear mixed
  model: absolute agreement or consistency (`type`), single or average (`unit`),
  random or fixed raters (`raters`), and one-way or two-way (`model`) designs.
  These are the classic Shrout & Fleiss and McGraw & Wong coefficients, each with
  a boundary-aware confidence interval.
* Every coefficient the design defines is reported by default, so a two-way call
  returns `ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)` and `ICC(C,k)` from a single fit.
  Agreement and consistency are post-fit arithmetic on the same variance
  components, so the extra coefficients are free. Pass a single `type` to report
  just that one.
* A definition the design leaves undefined is dropped with a message when it is
  reached through the default vector, and aborts with a teaching error when you
  ask for it by name.
* Imbalanced and **incomplete** (missing-cell) designs are fitted directly by the
  mixed model, which uses the harmonic-mean effective rating count `k_eff` as the
  `ICC(*,k)` divisor and aborts on a disconnected, unidentified design. Rows whose
  `score` is `NA` are dropped with a suppressible `intraclass_dropped_rows`
  warning, so a missing rating and an absent row give the same answer.
* **Multilevel** ICCs for subjects nested in clusters, such as pupils in
  classrooms or patients in clinics, follow ten Hove, Jorgensen & van der Ark
  (2022). Supply a `cluster` column to get subject-level and cluster-level
  coefficients through `level`, for raters crossed with clusters or nested in
  clusters or subjects, on complete or incomplete data.
* `level = "conflated"` reports the biased single-level coefficient you would get
  by ignoring the clustering, as a diagnostic contrast rather than a
  recommendation. The *Multilevel designs* article walks through the fences.
* When a subject-by-rater cell is rated more than once, `icc()` fits a
  subject-by-rater interaction and reports stable disagreement separately from
  pure rating error, instead of confounding the two. An `occasions` argument
  averages over the replicates, giving the reliability of a rater's mean score.
  The *D-studies and within-cell replicates* article covers both.

## Confidence intervals

* The default is a **boundary-aware Monte-Carlo interval** (`ci_method =
  "montecarlo"`), drawn from the fitted model's asymptotic parameter covariance.
  One coverage limitation is worth knowing before you quote it. When the subject
  effects are strongly skewed or heavy-tailed it under-covers, worst 0.6725 at
  chi-square(1) subject effects with a true ICC of 0.6, 50 subjects and 5 raters.
* Such runs neither abort nor warn, so `?icc`, the *Confidence-interval methods*
  article and the glossary all carry the caveat.
* `ci_method = "bootstrap"` is a parametric bootstrap: it simulates from the
  fitted model, refits `boot_samples` times, and takes percentile quantiles. It
  drops the asymptotic-normal approximation the default relies on, at the cost of
  a refit per resample. It covers every design the `"glmmTMB"` and `"lme4"`
  engines fit, plus the random two-way design under `"lavaan"`.
* `ci_method = "npbootstrap"` is the non-parametric variance-stabilized
  transformed bootstrap-*t* of Ukoumunne et al. (2003), for the **one-way random**
  design only. It resamples whole subjects rather than the fitted model, so it is
  boundary robust and robust to non-normal subject effects, and it is validated
  against the paper's own exact coverage table. Balanced and unbalanced data are
  both covered.
* `ci_method = "searle"` and `ci_method = "burch"` are **deterministic
  closed-form** intervals for the balanced one-way random design. `"searle"` is
  the exact-F pivot (Searle 1971; McGraw & Wong 1996), exact under normality, and
  `"burch"` is the REML-based kurtosis-adjusted interval of Burch (2011).
* Neither closed form is a remedy for heavy tails: `"burch"` under-covers on
  strongly skewed subject effects about as badly as the default (worst 0.6655).
  `"searle"` landed closer to nominal coverage in most cells of every family
  measured, which is why it is the one to prefer. Both are boundary robust and
  take no `mc_samples`, `boot_samples` or `seed`.
* Which of the two closed forms gives the **narrower** interval is conditional.
  On both grids that vary only the subject effect, `"burch"` is the narrower of
  the two in 16 of 16 cells of the smaller grid and 59 of 64 cells of the larger grid.
* That width margin holds much the same up to a true ICC of 0.3 rather than shrinking as the true ICC rises (on the larger grid; the smaller grid's margin does shrink across its levels). The `"burch"` width advantage then collapses to near parity at a true ICC of 0.6, on the one grid reaching that value. It also shrinks steadily as the subject count grows, measured at 5 raters.
* What `"burch"` does against `"searle"` also depends on the residual, and the three grids measure that: the two grids that vary only the subject effect put it narrower nearly everywhere, while the third, which draws the residual from the same family as the subject effect, puts it wider at every symmetric heavy-tailed family measured (a median width ratio of 1.2963 at t(5) with 100 subjects) and narrower at every lighter-tailed one, the normal included.
* Neither interval is described as reliably the tighter one. The
  *Confidence-interval methods* article tabulates every cut.
* `ci_method = "mpl"` is the **modified profile-likelihood** interval of Xiao &
  Liu (2013), for the balanced-complete two-way random absolute-agreement
  `ICC(A,1)` and `ICC(A,k)`. It is boundary robust and deterministic, and it is a
  deliberately conservative opt-in rather than the default, since it over-covers
  at interior settings. It applies at `conf_level` 0.90, 0.95 or 0.99 and aborts
  on every other design or level.
* The MPL interval is not equal-tailed, so a limit is not a one-sided bound at
  half the complementary level. At 0.99 with very few raters it can be
  near-vacuous, with a median width of 0.905 at 2 raters and 40 subjects.
* The `ci_method = "mpl"` documentation states the interpolation evidence behind
  off-node subject counts. The correction constant is calibrated at subject-count
  nodes and linearly interpolated between them. The interpolated path is
  coverage-validated at each supported confidence level, at the default 0.95 by
  three off-node cells, each clearing its pre-registered coverage floor. The
  documentation also says what that validation does not establish (interpolated
  values are validated at a handful of geometries, not calibrated, and the
  interval's asymmetry direction is not uniform across rater counts). Every
  universal or negative claim this documentation makes about the validated cells
  is settled mechanically, in CI, against the committed coverage fixture
  (`data-raw/check-mpl-doc-claims.py`).
* When an interval method aborts on degenerate data, the error **names another
  `ci_method` that works**, verified by running it on your data first. A method is
  named only when every endpoint it returns is finite, ordered and inside the
  coefficient's range, so the suggestion is a call already shown to succeed.
* Projecting a one-way interval to a numeric `unit` crosses a Spearman-Brown pole
  when the requested `m` is large relative to the ratings per subject. `"searle"`,
  `"burch"` and `"npbootstrap"` fail there with a classed error naming the pole
  and pointing at `ci_method = "montecarlo"`, which projects correctly.

## Engines and tooling

* The default engine is **glmmTMB** (boundary-robust REML). A selectable
  `engine = "lme4"`, by way of `merDeriv`, covers every design glmmTMB does, on
  balanced and on incomplete data, agreeing with it on the point estimate and on
  the Monte-Carlo interval. The *Estimation engines* article compares them.
* A selectable `engine = "lavaan"` fits an SEM common-factor generalizability
  model (Jorgensen 2021) for the two-way and crossed multilevel designs, with
  missing cells estimated by full information maximum likelihood and every result
  cross-validated against the REML engines. Nested designs and within-cell
  replicates are loud refusals.
* A selectable `engine = "brms"` is the first **Bayesian** engine, fitting in Stan
  under a sourced half-*t*(4, 0, 1) prior on the random-effect standard deviations
  (ten Hove, Jorgensen & van der Ark 2020). It reports the posterior-mode point
  estimate and a percentile credible interval through `ci_method = "posterior"`.
  A `brm_args` list forwards sampler and backend options to `brms::brm()`.
* A `prior` argument overrides the sourced prior with any \pkg{brms} prior object.
  The package's coverage results hold only for the sourced prior, so supplying
  your own raises a classed `intraclass_custom_prior` warning. A
  `posterior_summary` argument chooses between `"percentile"` and `"hpdi"`.
* `brms`, `lavaan` and `merDeriv` live in `Suggests`, so a plain install fetches
  none of the three. `glmmTMB` is the only engine a plain install leaves ready to
  use.
* `choose_icc()` is an interactive and programmatic decision helper: it recommends
  which ICC to report, explains each choice, and emits the exact `icc()` call to
  run. It gives advice only, and does not fit.
* `d_study()` projects a fitted ICC's reliability to the mean of any number of
  raters, the generalizability decision study, with an `autoplot()` reliability
  curve. An `n_o` argument sweeps the occasion count instead, rising to a finite
  ceiling below 1 because occasion averaging cancels only pure error.
* `autoplot()` and `plot()` methods draw a coefficient forest plot, a
  variance-component decomposition, and the D-study reliability curve, on a
  colourblind-safe (Okabe and Ito) palette. Console output is styled with **cli**
  and degrades to plain text wherever styling is unavailable.
* `tidy()` and `glance()` give tidy summaries of a fit or a projection, with the
  coefficient column named `term` after the broom glossary. Every identifier
  column is present on every fit, `NA` where the design does not define it, so two
  tidied fits row-bind.
* `glance()` reports `var_subject_rater` and `n_o` beside `var_residual`, and its
  `raters` and `replicates` columns say how to read the variance columns beside
  them. Sampler diagnostics `rhat` and `ess_bulk` come with the engines that
  sample.
* `?icc` states which parts of the returned object are safe to depend on: the
  documented methods, plus `$fit` and `$call`. The rest is internal.
* Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant) run through the docs.
* Seven articles ship with the package: *Getting started*, *Choosing an ICC*,
  *Multilevel designs*, *Estimation engines*, *Confidence-interval methods*,
  *D-studies and within-cell replicates*, and a *Glossary*. A *Comparison with
  other packages* article shows, with numbers computed live, that `intraclass`
  reproduces `psych::ICC` and `irr::icc` across the McGraw & Wong family.
* *Getting started* and *Choosing an ICC* are written for readers new to
  reliability. Their interpretation-band guide (after Koo & Li 2016 and Cicchetti
  1994) is framed as conventions to read against the interval, not as verdicts the
  package computes for you.

## When a call fails

* A degenerate fit with no variance in any component fails loudly instead of
  returning a `NaN` estimate, and an unstable fit whose Monte-Carlo draws overflow
  is reported rather than silently truncated.
* `icc()` rejects a non-finite `score` (`Inf`, `-Inf`, `NaN`) with a classed error
  naming the column and the offending rows, rather than passing it to the fitting
  engine and surfacing that engine's own unclassed message.
* Interval settings are validated with classed errors: `mc_samples`,
  `boot_samples`, `conf_level` and `seed` in `icc()`, and `mc_samples`,
  `conf_level` and `seed` in `d_study()`. An invalid value produces neither a
  silent `NA` interval nor a bare base-R error.
* A choice argument takes **exactly one value**. Passing several, the full set of
  allowed values included, aborts with a classed error instead of quietly using
  the first. Arguments that genuinely take several values are unaffected, and
  `?icc` says which those are.
* An incomplete crossed multilevel design in which every subject is rated only
  once is reported as unidentified, rather than returning a spurious `ICC = 0.5`.
  Requesting an averaged cluster-level `ICC(c,k)` where it is unsupported drops
  just that row with a message and returns the rest.
* `icc()` prints a one-time note when a multilevel design is inferred to be
  crossed from shared rater labels, so a nested design with reused labels is not
  silently treated as crossed. The `design` argument is how you override that
  inference.
* Error messages report the quantities that failed a check rather than asserting a
  cause, so what they say holds on every dataset that reaches them.
* The Monte-Carlo interval for **fixed-rater** designs is moment-corrected so it
  stays calibrated. Without the correction it materially under-covers for nested
  fixed raters as the cluster count grows. Coverage is verified nominal across
  raters, subjects per cluster and cluster counts.
