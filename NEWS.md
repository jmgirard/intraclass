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
  are supported. Projecting the occasion count itself, and projecting off a ragged
  replicate fit, remain unsupported.

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
  reminder suggests `brm_args = list(cores = ...)` for parallel sampling. Optional
  engines live in `Suggests`, so the base install stays light. The Bayesian engine
  also fits the **multilevel** designs at the subject level: the crossed Design 1
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
  the replicate count) — single-level two-way random, balanced.

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

## Data and documentation

* Datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout the docs.
* Vignettes: *Getting started*, *Choosing an ICC* (the decision framework, with a
  decision-tree diagram), and *Advanced* (incomplete and multilevel designs, the
  estimation engines, the plots, and `choose_icc()`).

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
