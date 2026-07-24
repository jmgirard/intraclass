# Changelog

## intraclass (development version)

### Breaking changes

- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) now
  reports **all defined error definitions by default.** The `type`
  argument is vectorized like `unit` and `level` and defaults to
  `c("agreement", "consistency")`, so a default two-way call returns
  `ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)`, and `ICC(C,k)` from a single fit —
  agreement vs. consistency is post-fit arithmetic on the same variance
  components, so the extra coefficients are free (this matters most for
  the expensive `brms` engine). Pass a single `type` to report just that
  coefficient. **No computed value changes** and every explicit
  `type = "agreement"` / `type = "consistency"` call is unaffected, but
  the **default** [`print()`](https://rdrr.io/r/base/print.html) /
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) output
  grows from two rows to four (grouped by error definition in
  [`print()`](https://rdrr.io/r/base/print.html)). Code that indexes
  default [`tidy()`](https://generics.r-lib.org/reference/tidy.html)
  rows by position should select by the `index` / `type` columns
  instead.
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  likewise projects **one reliability curve per error definition** the
  fitted `icc` reports, adding a `type` column to distinguish the
  curves; a single-type fit projects a single curve as before.
- A definition that is undefined for the design (consistency for a
  Design-3 nested-in-subjects fit, a fixed-rater absolute-agreement
  D-study projection, or absolute agreement when raters do not bridge
  clusters) is dropped with an informative message when reached via the
  default vector, and still aborts with a teaching error when requested
  explicitly.

### Minor improvements

- `ci_method = "npbootstrap"` now also covers **unbalanced one-way**
  designs (unequal ratings per subject) for both `unit = "single"`
  (ICC(1)) and `unit = "average"` (ICC(k)): the transform uses the ANOVA
  effective group size `n0` and the infinitesimal-jackknife SE its
  per-subject form (Ohyama 2025; Ukoumunne et al. 2003, Appendix A), and
  the ICC(k) interval is the exact Spearman-Brown image of the ICC(1)
  interval (its coverage is identical by construction, and stays
  well-defined unbalanced because the effective ratings per subject
  never exceed `n0`). On balanced data the result is unchanged. Only a
  numeric `unit` (a projection to a chosen number of raters) remains
  balanced-only — use `ci_method = "montecarlo"` for an unbalanced
  projection.

- New `ci_method = "npbootstrap"` for the **balanced one-way random**
  design: the non-parametric variance-stabilized **transformed
  bootstrap-*t*** of Ukoumunne et al. (2003). It resamples whole
  subjects (not the fitted model), so it is boundary robust — it returns
  an interval where the Monte-Carlo default aborts on near-zero-ICC data
  — and robust to non-normal subject effects. Validated against the
  paper’s exact Table I coverage. It is one-way only (aborts otherwise)
  and **not** a percentile bootstrap (the percentile and BCa variants
  under-cover and were deliberately not shipped). The `ICC(k)` interval
  is the exact Spearman-Brown image of the `ICC(1)` interval; endpoints
  are untruncated (following the source), so a near-boundary lower bound
  can be negative.

- New `ci_method = "searle"` and `ci_method = "burch"` for the
  **balanced one-way random** design: two **deterministic classical
  closed-form** intervals. `"searle"` is the exact-F pivot (Searle 1971;
  McGraw & Wong 1996, Table 7), exact under normality and narrowest on
  near-normal data; `"burch"` is the REML-based, kurtosis-adjusted
  interval of Burch (2011), wider but robust to non-normality and never
  under-covering. Like `"npbootstrap"` they are **boundary robust** — a
  finite interval where the Monte-Carlo default aborts on near-zero-ICC
  data — and one-way only (they abort otherwise). Being closed forms
  they take no `mc_samples`, `boot_samples`, or `seed` and report no
  standard error; the `ICC(k)` interval is the exact Spearman-Brown
  image of the `ICC(1)` interval, endpoints untruncated.

- New `ci_method = "mpl"` for the **balanced-complete two-way random**
  absolute-agreement `ICC(A,1)` (and `ICC(A,k)`): the **modified
  profile-likelihood** interval of Xiao & Liu (2013). Like the closed
  forms it is **boundary robust** — it returns a finite interval on
  every dataset, including the near-zero-ICC boundary where the
  Monte-Carlo default aborts — and takes no `mc_samples`,
  `boot_samples`, or `seed` and reports no standard error. It is a
  deliberately **conservative** opt-in (it over-covers and is wider than
  the Monte-Carlo interval at interior settings), so it is not the
  default. It applies only to the two-way random absolute-agreement
  design at `conf_level = 0.95` and aborts on any other design, on
  consistency, on fixed raters, and on unbalanced, incomplete, or
  within-cell-replicated data. The `ICC(A,k)` interval is the exact
  Spearman-Brown image of the `ICC(A,1)` interval. Its correction
  constant is calibrated by simulation and, for intraclass correlations
  below about 0.6, rests on that simulated coverage rather than an
  external benchmark.

- The `lavaan` (SEM) engine now fits the **crossed (Design 1)
  multilevel** design: `icc(..., engine = "lavaan", cluster = ...)`
  estimates the five-component decomposition (cluster,
  subject-in-cluster, rater, cluster-by-rater, residual) via a two-level
  structural-equation model and reports the subject- and cluster-level
  ICCs (plus the conflated diagnostic) with either the Monte-Carlo
  interval (the default) or the parametric bootstrap
  (`ci_method = "bootstrap"`), which simulates two-level datasets from
  the fitted moments and refits per resample (the parametric bootstrap
  needs complete, balanced data with equal cluster sizes). Random
  raters; cross-validated against the REML mixed-model engines
  (consistency ICCs agree essentially exactly; the documented ML-vs-REML
  and rater-mean small-sample differences shrink as clusters grow), and
  the bootstrap interval agrees with the Monte-Carlo interval within
  Monte-Carlo tolerance. Nested designs and within-cell replicates
  remain loud, classed refusals.

- The `lavaan` (SEM) engine now also fits the crossed (Design 1)
  multilevel design with **fixed raters** (`raters = "fixed"`) at both
  the subject and cluster levels, on complete, balanced data with equal
  cluster sizes. The rater term is the McGraw & Wong Case-3A
  finite-population variance read from the between-level rater
  intercepts; cross-validated against the `glmmTMB` fixed-rater
  multilevel fits (agreement asymptotic under the ML-vs-REML gap,
  consistency identical to the random-rater fit). Because lavaan’s
  random-rater estimate is the raw quadratic form, the fixed-rater ICC
  differs from the random-rater one by the finite-population correction,
  which the REML mixed-model engines do not carry into their random
  estimate. Monte-Carlo interval only — the fixed-rater parametric
  bootstrap is not yet available. Fixed-rater nested,
  within-cell-replicate, and incomplete/unbalanced multilevel SEM remain
  loud, classed refusals.

- The `lavaan` (SEM) engine now fits the crossed (Design 1) multilevel
  design with **random raters** on **incomplete** and **unbalanced**
  data, not only on complete, balanced data:
  `icc(..., engine = "lavaan", cluster = ...)` estimates around missing
  subject-by-rater cells by two-level full-information maximum
  likelihood and fits unequal cluster sizes natively. The subject- and
  cluster-level ICCs are cross-validated against the REML mixed-model
  engines (consistency near-exact; agreement within the documented
  index-class split), the averaged cluster-level ICC uses the same
  inverse-Simpson `k_c^eff` divisor, and the rater main-effect variance
  carries the documented small-sample inflation, which generalizes under
  unequal cluster sizes to use the harmonic mean of the per-cluster
  subject counts. The interval is Monte-Carlo only on incomplete or
  unbalanced data (the parametric bootstrap cannot reproduce a
  missingness pattern and its coverage is validated only on balanced
  data); balanced, complete data keeps the bootstrap. Fixed-rater
  incomplete/unbalanced multilevel SEM remains a loud, classed refusal.

- `tidy(icc(...))` and `tidy(d_study(...))` gain a `type` column.

- The conflated diagnostic (`level = "conflated"`) now also reports a
  **consistency** form (`type = "consistency"`), not just absolute
  agreement. It is the flat two-way consistency ICC read off the
  multilevel fit (dropping the rater main-effect variance, McGraw &
  Wong 1996) – the symmetric twin of the agreement Eq. 14 – so a default
  `level = "conflated"` call now reports both. Random raters, crossed
  Design 1, balanced or incomplete, across the `glmmTMB`, `lme4`, and
  `brms` engines. Like the cluster level it needs raters that bridge
  clusters; without bridging the conflated level is dropped (or aborts
  if it is the only level requested).

- The **averaged cluster-level ICC** (`level = "cluster"`,
  `unit = "average"`) now ships on **incomplete/ragged** multilevel data
  (crossed Design 1, random raters), where it previously aborted. The
  averaging divisor is the effective number of raters behind each
  cluster’s observed (cells-pooled) mean — the inverse-Simpson harmonic
  `k_c^eff`, reported on the fitted object and equal to the rater count
  on complete data. A rater-balanced cluster mean would have a different
  (higher) effective count. This ships for **every random-rater engine**
  — `glmmTMB`, `lme4`, and the Bayesian `brms` engine (which applies the
  same divisor to the posterior draws’ variance components, its credible
  interval covering the population value across the cluster-count axis).

- The
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  / [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods
  share a cohesive look: a clean theme, a colourblind-safe (Okabe–Ito)
  palette for the variance-component bars and the per-level multilevel
  panels, and direct value labels on the coefficient and component
  plots. The D-study reliability curve now draws **each projected curve
  as its own line** — one per error definition (absolute agreement
  vs. consistency) and, for replicate fits, per occasion setting — with
  a legend, instead of connecting the overlaid projections into a single
  zig-zag. `ggplot2` remains a `Suggests` dependency.

### Documentation

- The package comparison and “related work” documentation no longer
  presents `gtheory` as an alternative package to reach for: it was
  archived from CRAN in March 2025 and is not a dependency. The
  historical numerical agreement between the `lavaan` (SEM) engine and
  `gtheory` is retained as a cited reference.

## intraclass 0.1.0

First public release. **intraclass** estimates interrater-reliability
intraclass correlation coefficients (ICCs) within the
generalizability-theory framework using modern mixed-model
variance-component estimation (rather than the classical ANOVA
mean-squares approach), with boundary-aware Monte-Carlo confidence
intervals and guidance on choosing the right coefficient. Every
estimator is verified against independent oracles — published worked
examples, `psych`/ANOVA cross-checks, alternate engines, and seeded
simulations.

### Estimating ICCs

- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  computes the full interrater-reliability ICC family from a linear
  mixed model: absolute agreement vs. consistency (`type`), single
  vs. average (`unit`), random vs. fixed raters (`raters`), and one-way
  vs. two-way (`model`) designs — the classic Shrout & Fleiss / McGraw &
  Wong coefficients — each reported with a boundary-aware Monte-Carlo
  confidence interval and its Shrout & Fleiss equivalent.
- A second interval method, `ci_method = "bootstrap"`: a parametric
  bootstrap that simulates response vectors from the fitted model,
  refits, and takes percentile quantiles (`boot_samples` resamples). It
  does not rely on the asymptotic-normal covariance approximation the
  Monte-Carlo default uses, at the cost of a refit per resample.
  Available for every design the `"glmmTMB"`
  ([`simulate()`](https://rdrr.io/r/stats/simulate.html) + refit) and
  `"lme4"` (`bootMer`) engines fit — two-way random and fixed, one-way,
  and the multilevel designs — at both levels, and for the random
  two-way design the `"lavaan"` engine (which simulates from the fitted
  SEM’s implied moments and refits). For fixed raters the
  finite-population is recomputed directly from each refit.
- Imbalanced and **incomplete** (missing-cell) designs are handled
  directly by the mixed model: it uses the effective number of ratings
  `k_eff` (the harmonic mean of the per-subject counts) as the
  `ICC(*,k)` divisor and aborts loudly on a disconnected, unidentified
  design.
- **Multilevel** ICCs for subjects nested in clusters — pupils in
  classrooms, patients in clinics — following ten Hove, Jorgensen & van
  der Ark (2022). Supply a `cluster` column to get subject-level
  (within-cluster) and cluster-level (between-cluster) coefficients via
  `level`. Covers raters crossed with clusters (Design 1) or nested in
  clusters/subjects (Designs 2–3), complete or incomplete crossed data,
  and fixed raters at the subject level on **both balanced and
  incomplete** crossed data (the finite-population rater variance is
  read from the ragged rater-contrast fit, so it differs from the
  random-rater ICC under imbalance). Fixed raters are also supported at
  the **cluster** level for the crossed (Design 1) design on **balanced,
  complete** data — signal , error the finite-population plus the
  cluster-by-rater term — where the coefficient equals the random-rater
  cluster-level ICC. Fixed raters in the **nested** Design 2 (raters
  nested in clusters) are likewise supported at the subject level on
  **both balanced and incomplete/ragged** data — the finite-population
  rater variance is formed per cluster (each cluster’s own raters, with
  its own effective rater count on ragged data) and averaged over
  clusters. `level = "conflated"` reports the biased single-level ICC
  you would get by ignoring the clustering (ten Hove et al. 2022,
  Eq. 14) — a diagnostic contrast, flagged in
  [`print()`](https://rdrr.io/r/base/print.html) as not a recommended
  coefficient (absolute-agreement, crossed designs, balanced **or
  incomplete**).
- **Within-cell replicates**: when a subject-by-rater cell is rated more
  than once,
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) fits
  the two-way random model with a subject-by-rater interaction,
  separating the interaction variance (stable disagreement) from pure
  rating error instead of confounding them — and reports both. A new
  `occasions` argument averages over the replicates
  (`occasions = "average"`), giving the reliability of a rater’s
  mean-of-replicates score. Balanced, complete replicated two-way
  designs, random **or fixed** raters — with fixed raters the rater main
  effect is the finite-population (McGraw & Wong Case 3A), which equals
  the random on balanced data, so fixed reproduces the random
  coefficients. Within-cell replicates are also supported for
  **multilevel** designs — crossed Design 1 (a six-component fit) and
  nested Design 2 (five components) — adding a
  `(1 | cluster:subject:rater)` term so the highest-order residual
  splits into the interaction and pure error at the subject level.
  **Ragged** replicated two-way random data (unequal per-cell counts or
  missing cells) fits the single-occasion coefficients directly, as the
  replicate analogue of an incomplete design. (Design 3, the multilevel
  one-way, has no separable interaction to split; the occasion-averaged
  coefficient on ragged data is not yet supported.)
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  now projects the rater count off a **within-cell replicate** fit,
  returning one reliability curve per occasion setting (a new
  `occasions` column): the rater and interaction terms divide by the
  projected count `m`, pure error by `m * n_o`, so at `m` = the observed
  rater count each curve matches the fitted `ICC(*,k)`. Single-level
  two-way (fixed-rater consistency via Spearman-Brown; fixed absolute
  agreement refused) and multilevel (crossed Design 1 + nested Design 2
  — subject level across occasion settings, cluster level
  single-occasion) replicate fits are supported.
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  also projects the **occasion count** off a within-cell replicate fit —
  a new `n_o` argument (mutually exclusive with `m`) that holds the
  raters fixed and sweeps the number of occasions: “how reliable would
  each rater’s mean of `n_o` ratings be?”. Because occasion averaging
  cancels only pure error, the curve rises to a **finite ceiling below
  1** (not toward 1, as a rater projection does), and it is well-posed
  for **fixed absolute agreement** — the axis a rater projection cannot
  take. On a multilevel fit the subject level rises with `n_o` while the
  cluster level is flat (occasion-invariant). Projecting the occasion
  count off a **ragged** replicate fit remains unsupported (the
  occasion-averaged ragged divisor is an open modeling question).

### Engines

- Default **glmmTMB** engine (boundary-robust REML), with a selectable
  `engine = "lme4"` (via `merDeriv`) that covers every design glmmTMB
  does — two-way random and fixed raters, one-way, and the multilevel
  designs (crossed and nested) at both levels — on both balanced and
  incomplete/ragged data, agreeing with glmmTMB on both the point
  estimate and the Monte-Carlo interval (a ragged fit that lands on a
  variance-component boundary falls back to glmmTMB). A selectable
  `engine = "lavaan"` — an SEM common-factor generalizability model
  (Jorgensen 2021) whose absolute-agreement coefficient uses the
  indicator-mean rater-variance estimator — covers the two-way design
  with random or fixed raters, on both complete and **incomplete** data
  (missing cells estimated by full-information maximum likelihood), and
  both the Monte-Carlo and the parametric-bootstrap interval (bootstrap
  on complete data). For fixed raters the SEM agreement uses the McGraw
  & Wong Case-3A bias-corrected finite-population (the raw
  indicator-mean variance minus the mean sampling variance of the rater
  means), which equals the mixed-model estimate on balanced data. A
  selectable **`engine = "brms"`** — the first Bayesian engine — fits
  the two-way **random** model in Stan under a sourced half-*t*(4, 0, 1)
  prior on the random-effect standard deviations (ten Hove, Jorgensen &
  van der Ark 2020), reporting the posterior-mode (MAP) point estimate
  and a percentile **credible** interval via a new
  `ci_method = "posterior"` (the forced, Bayesian-only interval method).
  It covers the balanced, complete two-way random design (agreement and
  consistency, single and average); a `brm_args` list forwards
  sampler/backend options (e.g. `backend = "cmdstanr"`, `chains`,
  `iter`, `cores`) to
  [`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html).
  Chains sample sequentially on one core by default (matching brms); a
  periodic reminder suggests `brm_args = list(cores = ...)` for parallel
  sampling. Optional engines live in `Suggests`, so the base install
  stays light. The Bayesian engine also fits the **multilevel** designs
  at the subject level: the crossed Design 1 (five components, subject
  and cluster levels) and the nested Design 2 (raters nested in
  clusters, four components, subject level), each under the same sourced
  half-*t* prior with MAP + percentile credible intervals. Beyond the
  two-way random path it covers the single-level **one-way** random
  design (`model = "oneway"` — `ICC(1)`/`ICC(1,k)`) and **fixed** raters
  (`raters = "fixed"` — the McGraw & Wong finite-population read
  directly from the posterior of the rater effects), both balanced and
  complete. Fixed raters are also supported at the **multilevel**
  subject level, balanced — the crossed Design 1 and the nested Design 2
  — with / read per posterior draw and moment-corrected so the credible
  interval covers the fixed-population coefficient (a bias correction
  that matters when each cluster’s raters are estimated from few
  subjects, and is boundary-aware at zero rater variance). The Bayesian
  engine also reports the **conflated** diagnostic
  (`level = "conflated"`, the biased ignore-the-clustering ICC of ten
  Hove et al. 2022, Eq. 14): a variance-ratio push-forward composed off
  the same crossed five-component posterior draws, with the frequentist
  glmmTMB conflated point falling inside its credible interval. It also
  fits **within-cell replicates** (more than one rating per
  subject×rater cell): the residual splits into the subject×rater
  interaction and pure error, and `occasions = "average"` reports the
  reliability of the replicate mean (pure error divided per posterior
  draw by the replicate count) — single-level two-way, random **or
  fixed** raters (with fixed raters the rater slot carries the
  finite-population read per posterior draw, equal to on balanced data),
  and **multilevel** designs (crossed Design 1, six components; nested
  Design 2, five components; random raters, subject level), all
  balanced. Finally, the Bayesian engine now fits **incomplete/ragged**
  random-rater data (unequal or missing subject×rater cells) for the
  two-way single-level design and the crossed (Design 1) multilevel
  design (subject level, and the single-rater cluster `ICC(c,1)`; the
  averaged cluster `ICC(c,k)` is dropped with a note, as for the other
  engines): the model is fit on the observed cells and the same
  harmonic-mean `k_eff` divisor + connectedness identifiability used by
  the other engines are applied per posterior draw. Because random-rater
  ICCs are ratios of variance components, this needs no moment
  correction. The Bayesian engine also fits **incomplete/ragged
  fixed-rater** data for the two-way single-level design and the crossed
  (Design 1) fixed-rater **multilevel** design (subject level)
  (`raters = "fixed"`): the finite-population is read from the ragged
  rater-contrast posterior, and — because the rater means are then
  estimated from unequal cell counts — the moment correction that keeps
  the credible interval covering the fixed-population coefficient
  becomes active (it is negligible on balanced data). The Bayesian
  engine now also fits **incomplete/ragged nested** **random**-rater
  data at the subject level — Design 2 (raters nested in clusters) and
  Design 3 (raters nested in subjects, the multilevel one-way,
  agreement-only): the shipped nested fits are run on the observed cells
  with the same harmonic-mean `k_eff` divisor + connectedness /
  per-subject identifiability gates the other engines use, and — random
  raters being ratios of variance components — need no moment
  correction. The Bayesian engine now also fits **incomplete/ragged
  single-level one-way** data (`ICC(1)`/`ICC(1,k)`): the shipped one-way
  fit is run on the observed ratings with the same harmonic-mean `k_eff`
  divisor, a ratio of variance components needing no moment correction.
  The Bayesian engine also reports the **fixed-rater cluster level** for
  the crossed (Design 1) design on balanced data (`raters = "fixed"`,
  `level = "cluster"`): the between-cluster ICC is read off the same
  crossed fixed multilevel posterior draws (signal , error the
  finite-population plus the cluster-by-rater variance), a
  variance-ratio push-forward that equals the random-rater cluster-level
  ICC on balanced data — so it now returns **both** levels for balanced
  fixed raters, matching the `glmmTMB`/`lme4` engines. Finally, it fits
  **incomplete/ragged fixed-rater nested** (Design 2) data at the
  subject level: is read per posterior draw with the per-cluster moment
  correction applied to each cluster’s own rater count, so unequal
  per-cluster counts and the boundary (zero rater variance) are handled,
  and a seeded coverage reference confirms the credible interval covers
  at both moderate and high cluster counts. Incomplete
  within-cell-replicate and numeric-`unit` (D-study) Bayesian fits, and
  the incomplete/unbalanced fixed-rater *cluster* level (open for every
  engine), are planned for a future release.
- A new **`prior`** argument lets you override the sourced half-*t*(4,
  0, 1) prior for `engine = "brms"` with any prior object (from
  [`brms::set_prior()`](https://paulbuerkner.com/brms/reference/set_prior.html)
  /
  [`brms::prior()`](https://paulbuerkner.com/brms/reference/set_prior.html))
  — intended for prior-sensitivity, method-comparison, or simulation
  work. The default (`prior = NULL`) is unchanged and reproduces earlier
  results bit-for-bit. Supplying a custom prior is a deliberate
  deviation that **voids the package’s coverage guarantees** (which hold
  only for the sourced prior), so
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  emits a loud classed (`intraclass_custom_prior`) warning: a vague or
  flat SD prior can *worsen* small- boundary bias, since the half-*t* is
  weakly informative on purpose. The prior stays owned by the package
  elsewhere — it may not be set through `brm_args`.
- A new **`posterior_summary`** argument chooses how
  `ci_method = "posterior"` reduces the posterior draws to a credible
  interval: `"percentile"` (the default, unchanged) or `"hpdi"` (the
  highest-posterior-density interval — the narrowest interval covering
  the credible mass, computed with a dependency-free helper). Percentile
  stays the default because it is monotone-transformation invariant and
  degrades gracefully at the variance boundary, and percentile (not HPD)
  intervals give nominal coverage at small rater counts (ten Hove et
  al. 2020); the HPDI is offered for comparison, not as a strict
  upgrade, and no coverage is claimed for it. The printed header names
  the HPDI variant. Setting `posterior_summary` for a non-posterior
  interval method is an error.

### Choosing, projecting, and visualizing

- [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)
  — an interactive and programmatic decision helper that recommends
  which ICC to report, explains each choice, and emits the exact
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) call
  to run. It gives advice only; it does not fit.
- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  — projects a fitted ICC’s reliability to the mean of an arbitrary
  number of raters (a generalizability decision study), with an
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  reliability curve;
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)’s
  `unit` also accepts numbers for one-off projections. For a
  **multilevel** fit it projects the rater count at each level (subject
  and/or cluster), returning one curve per level (a `level` column;
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  facets by it); on **incomplete** data it projects the subject level
  (the cluster level is dropped with a note). The projection band
  follows the fit’s `ci_method`: a **bootstrap** fit reprojects its
  stored resamples, so at the observed rater count the band matches the
  fitted average-measure bootstrap interval exactly.
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  / [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  `icc` objects draw a coefficient forest plot and a variance-component
  decomposition;
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) /
  [`glance()`](https://generics.r-lib.org/reference/glance.html) give
  tidy summaries. Plotting needs `ggplot2` (a `Suggests` dependency).
- Console output is styled with **cli**:
  [`print()`](https://rdrr.io/r/base/print.html) /
  [`summary()`](https://rdrr.io/r/base/summary.html) show a rule header
  and an aligned coefficient table with the point estimate emphasized
  and the interval dimmed, and
  [`choose_icc()`](https://jmgirard.github.io/intraclass/reference/choose_icc.md)’s
  interactive walkthrough is a guided decision tree that displays your
  choices so far. Styling degrades to plain text wherever it is
  unavailable (knitr, CRAN, a non-interactive session), so printed
  values are unchanged.

### Data and documentation

- Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout
  the docs.
- Vignettes: *Getting started*, *Choosing an ICC* (the decision
  framework, with a decision-tree diagram), *Multilevel designs*
  (subject/cluster level, crossed and nested, complete and incomplete),
  *Estimation engines* (glmmTMB, lme4, lavaan, and the Bayesian brms
  engine with the `prior=` override), *Confidence-interval methods*
  (Monte-Carlo, bootstrap, and Bayesian `posterior` credible intervals
  with percentile/HPDI summaries), and *D-studies and within-cell
  replicates* (with the
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  plots).
- *Getting started* and *Choosing an ICC* were rewritten to be
  approachable to readers new to reliability: a from-scratch on-ramp
  (“what an ICC tells you”), plainer language for the confidence
  interval and the estimand vocabulary, and a new interpretation-band
  guide (poor / moderate / good / excellent, after Koo & Li 2016 and
  Cicchetti 1994) framed as conventions to read against the interval —
  not verdicts the package computes for you.
- A new *Glossary* article defines the recurring vocabulary — variance
  component, REML, credible vs. confidence interval, `k_eff`, the
  zero-variance boundary, and the rest — in one place that the other
  articles link into.
- A new *Comparison with other packages* article shows, with numbers
  computed live from the shipped datasets, that `intraclass` reproduces
  [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html) and
  [`irr::icc`](https://rdrr.io/pkg/irr/man/icc.html) across the McGraw &
  Wong family on balanced data (and that Gwet’s model-based `irrICC`
  agrees too), then where it goes further — incomplete and unbalanced
  data, multilevel subject/cluster reliability, boundary-aware
  intervals, and guidance on which coefficient to report.

### Robustness (pre-release code review)

- [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  now projects a **one-way** fit (a Spearman-Brown projection of
  `ICC(1)`) instead of erroring.
- A fixed-rater multilevel call
  (`icc(..., cluster =, raters = "fixed")`) now works with the default
  `level`, dropping the deferred cluster level to the subject level (as
  the nested-design path already did) rather than requiring an explicit
  `level = "subject"`.
- On incomplete crossed multilevel data, requesting an averaged
  cluster-level `ICC(c,k)` now drops just that (unsupported) row with a
  message and returns the subject-level and single-rater cluster
  results, instead of failing the whole call.
- An incomplete crossed multilevel design in which every subject is
  rated only once is now reported as unidentified rather than returning
  a spurious `ICC = 0.5`.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  prints a one-time note when a multilevel design is inferred to be
  crossed from shared rater labels, so a nested design with reused,
  cluster-relative labels is not silently treated as crossed.
- `mc_samples` and `seed` are validated with clear, classed errors;
  invalid values (e.g. `mc_samples = 0`/`1`, a fractional or non-numeric
  value) no longer produce a silent `NA` interval or a bare base-R
  error.
- A degenerate fit with no variance in any component now fails loudly
  instead of returning a `NaN` estimate, and an unstable fit whose
  Monte-Carlo draws overflow is reported rather than silently truncated.
- The Monte-Carlo confidence interval for **fixed-rater** designs is now
  moment-corrected so it stays calibrated. Previously the
  finite-population draws were displaced above the point estimate, which
  was harmless for crossed designs (rater means estimated from the whole
  sample) but materially **undercovered** for nested (Design 2) fixed
  raters as the number of clusters grew — down to ~37% coverage of a
  nominal-95% interval with many clusters and few subjects each, and the
  point estimate could even fall outside its own interval near the
  zero-rater-variance boundary. The draws are now re-centered on the
  point and floored as a per-draw average (so the interval remains
  boundary-aware and can reach ); the **point estimate is unchanged**
  away from the boundary. Coverage is verified nominal across raters,
  subjects-per-cluster, and cluster counts. Applies to the `"glmmTMB"`,
  `"lme4"`, and `"lavaan"` engines.
