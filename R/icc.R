#' Intraclass correlation coefficient for a two-way design
#'
#' Estimates interrater-reliability intraclass correlation coefficients (ICCs)
#' from a fitted linear mixed model, rather than from classical ANOVA mean
#' squares. `icc()` computes the two-way **absolute-agreement** (`ICC(A,*)`) or
#' **consistency** (`ICC(C,*)`) coefficients of McGraw & Wong (1996), for a
#' single rater (`ICC(*,1)`) or the mean of `k` raters (`ICC(*,k)`), treating the
#' raters as a random sample (Case 2) or as fixed (Case 3).
#'
#' @section Which ICC is this, and when should you use it?:
#' Three choices pin down the coefficient:
#' * **Agreement vs. consistency** (`type`). **Absolute agreement** treats
#'   systematic differences between raters (the rater main effect,
#'   \eqn{\sigma^2_r}) as error: use it when the actual value matters and raters
#'   must agree on the number (clinical scores, measurements). **Consistency**
#'   ignores a constant per-rater offset: use it when only relative standing
#'   matters. A large gap between the two signals big systematic differences in
#'   rater level -- a rating-procedure problem worth fixing.
#' * **Single vs. average** (`unit`). **`ICC(*,1)`** is the reliability of a
#'   *single* rater; **`ICC(*,k)`** is the reliability of the *mean* of your `k`
#'   raters. Report `ICC(*,k)` when the averaged score is what you will use.
#' * **Random vs. fixed raters** (`raters`). **Random** treats your raters as a
#'   sample you wish to generalize beyond -- the recommended default for
#'   interrater reliability. **Fixed** treats them as the only raters of interest
#'   and forgoes generalization; it is fit separately (raters as fixed effects),
#'   so on balanced data it matches the random point estimate but on incomplete
#'   data it genuinely differs. `icc()` warns when you choose it. Fixed-rater
#'   consistency is the classic Shrout & Fleiss `ICC(3,1)`.
#'
#' @section Estimand:
#' With a single rating per subject-by-rater cell, the subject-by-rater
#' interaction and pure error are not separately identified; only their sum, the
#' residual variance \eqn{\sigma^2_{res}}, is estimable. Absolute agreement counts
#' the rater main effect \eqn{\sigma^2_r} as error; consistency drops it:
#' \deqn{ICC(A,1) = \sigma^2_s / (\sigma^2_s + \sigma^2_r + \sigma^2_{res})}
#' \deqn{ICC(A,k) = \sigma^2_s / (\sigma^2_s + (\sigma^2_r + \sigma^2_{res}) / k)}
#' \deqn{ICC(C,1) = \sigma^2_s / (\sigma^2_s + \sigma^2_{res})}
#' \deqn{ICC(C,k) = \sigma^2_s / (\sigma^2_s + \sigma^2_{res} / k)}
#' where \eqn{\sigma^2_s} is the subject (signal) variance and `k` is the number
#' of raters.
#'
#' @section Multilevel designs (subject vs. cluster level):
#' When subjects are nested in higher-level clusters (pupils in classrooms,
#' patients in clinics), single-level ICCs conflate the levels and are biased
#' (ten Hove et al. 2022). Supplying `cluster` fits the five-component Design-1
#' model
#' \deqn{score \sim 1 + (1|cluster) + (1|cluster{:}subject) + (1|rater) + (1|cluster{:}rater)}
#' and reports two distinct reliabilities. The **subject level** (within-cluster)
#' asks how reliably raters distinguish subjects *within* a cluster: its signal is
#' the between-subject-within-cluster variance and cluster variance drops out. The
#' **cluster level** (between-cluster) asks how reliably raters distinguish cluster
#' means: its signal is the between-cluster variance and the rater-disagreement
#' error is the cluster-by-rater term. Choose the level that matches the decision
#' you will make (about a subject, or about a cluster). The agreement/consistency
#' and single/average choices above apply at each level.
#'
#' `level = "conflated"` reports the **biased single-level ICC** you would get by
#' *ignoring* the clustering (ten Hove et al. 2022, Eq. 14): between- and
#' within-cluster subject variance are both counted as signal, and the rater-related
#' terms as error. It is offered only as a **diagnostic contrast** -- to quantify how
#' much the nesting distorts reliability -- and is never a recommended coefficient;
#' `print()` flags it as such. It is the **flat two-way ICC** read off the multilevel
#' fit, so it comes in both `type` forms: absolute agreement (Eq. 14) and
#' **consistency** (which drops the rater main-effect variance, McGraw & Wong 1996).
#' It needs a crossed (Design 1) random-rater design and works on both balanced and
#' **incomplete** data (same `k_eff` divisor). Because it reads the cluster-by-rater
#' variance, it needs raters that bridge clusters; without bridging the conflated
#' level is dropped (like the cluster level). Request it alongside the correct levels,
#' e.g. `level = c("subject", "cluster", "conflated")`.
#'
#' The design is **inferred from the data** (ten Hove et al. 2022, Table 2). If
#' raters are crossed with clusters (each rater rates in every cluster) the
#' five-component model above is used (Design 1). Because the design is read from
#' the rater **labels**, a rater label that appears in more than one cluster is
#' taken to be the *same* rater (crossed). If your raters are cluster-specific but
#' share labels (e.g. "rater 1"/"rater 2" reused in every cluster -- a nested
#' design), give them cluster-unique labels or declare `design = "nested_in_clusters"`;
#' otherwise the design is treated as crossed and `icc()` prints a one-time note of
#' that assumption. If raters are **nested in
#' clusters** (each cluster has its own raters; Design 2) a four-component model is
#' fit, with the rater variance carried by the nested rater-within-cluster term. If
#' raters are **nested in subjects** (each subject has its own raters; Design 3) the
#' rater variance is confounded into the residual, giving a three-component
#' multilevel *one-way* model that reports agreement-only `ICC(1)`/`ICC(k)`. Both
#' nested designs define only the **subject** level -- a cluster-level ICC needs
#' raters crossed with clusters -- so `level` is restricted to `"subject"` for them.
#' Mixed patterns (some raters crossed, some nested) are not a supported design and
#' raise an error. The **crossed** design (Design 1) additionally supports
#' **incomplete** data -- subjects rated by different, overlapping rater subsets
#' (missing cells) -- computing the subject-level ICCs by REML with the averaging
#' divisor set to the effective number of ratings per subject (`k_eff`, the harmonic
#' mean), exactly as the single-level incomplete two-way ICC does. Identifiability is
#' checked first: each cluster's subject-by-rater layout must be connected, and for
#' absolute agreement raters must bridge clusters (otherwise the design is really
#' rater-nested). When missing cells make the crossed-vs-nested pattern ambiguous,
#' declare it with `design` (above). On incomplete data the **cluster** level is
#' reported (when raters bridge clusters) as both the single-rater `ICC(c,1)` and the
#' averaged `ICC(c,k)`: the average divides the cluster error by the effective number
#' of raters behind each cluster's observed (cells-pooled) mean, the inverse-Simpson
#' harmonic `k_c^eff` (reported as `k_c_eff`; equal to the rater count on complete
#' data). A rater-balanced cluster mean would have a different (higher) effective
#' count. This averaged cluster `ICC(c,k)` on incomplete data ships for every
#' random-rater engine -- `glmmTMB`, `lme4`, and `brms` (the divisor is applied to the
#' posterior draws' variance components exactly as for the frequentist fits). **Fixed
#' raters**
#' (`raters = "fixed"`) are supported for the crossed design at the **subject** level
#' on both balanced and **incomplete** data: the rater main effect becomes the
#' finite-population variance of the observed raters (McGraw & Wong Case 3A), so on
#' balanced data consistency is identical to the random-rater case and absolute
#' agreement differs only by that term; on incomplete data both types differ from
#' random (the finite-population variance is read from the ragged rater-contrast fit).
#' **Nested (Design 2) fixed raters** are likewise supported at the **subject** level on
#' both balanced and **incomplete** data (the finite-population rater variance is formed
#' **per cluster** -- each cluster's own raters -- and averaged over clusters; on ragged
#' data each cluster uses its own effective rater count). The fixed-rater **cluster**
#' level is supported for the crossed (Design 1) design on **balanced, complete** data
#' (signal \eqn{\sigma^2_c}, agreement error the finite-population \eqn{\theta^2_r} plus
#' the cluster-by-rater term \eqn{\sigma^2_{cr}}); on balanced data it equals the
#' random-rater cluster-level ICC. The Bayesian (`engine = "brms"`) fixed-rater
#' **cluster** level is likewise supported for the crossed (Design 1) design on
#' balanced, complete data, and the Bayesian incomplete/ragged fixed-rater **nested**
#' (Design 2) subject level is supported too. Incomplete/unbalanced fixed-rater
#' cluster-level estimation and Design-3 fixed raters (nested in subjects -- no
#' separable rater effect) remain for later milestones.
#'
#' @section Within-cell replicates:
#' When a subject-by-rater cell is rated **more than once** (within-cell
#' replicates), `icc()` fits the two-way random model **with a subject-by-rater
#' interaction**, `score ~ 1 + (1|subject) + (1|rater) + (1|subject:rater)`, which
#' splits the single-rating residual into the **interaction** \eqn{\sigma^2_{sr}}
#' (does a rater systematically rate a subject high or low -- stable disagreement?)
#' and **pure error** \eqn{\sigma^2_e} (rating noise). Both are reported. The
#' single-occasion ICCs are unchanged in value from a one-rating-per-cell analysis
#' (a single rating's error still includes the interaction), but the components are
#' no longer confounded, and `occasions = "average"` reports the reliability of the
#' mean of the replicates (which reduces \eqn{\sigma^2_e} but not
#' \eqn{\sigma^2_{sr}}). With `raters = "fixed"` the rater main effect becomes the
#' finite-population \eqn{\theta^2_r} (McGraw & Wong Case 3A, fit as
#' `score ~ 1 + rater + (1|subject) + (1|subject:rater)`); on balanced, complete data
#' \eqn{\theta^2_r = \sigma^2_r}, so fixed reproduces the random-rater coefficients.
#' **Multilevel** replicated designs add a `(1|cluster:subject:rater)` term (crossed
#' Design 1 and nested Design 2), splitting the highest-order residual at the subject
#' level. **Ragged** (unequal per-cell counts or missing cells) two-way random data
#' fits the **single-occasion** family directly (the replicate analogue of an
#' incomplete design); the occasion-averaged coefficient on ragged data is not yet
#' supported (there is no single effective occasion count to average over). One-way
#' replicates, fixed or multilevel ragged replicates, and `d_study()` projection off a
#' replicate fit are planned for later milestones.
#'
#' @section Confidence intervals:
#' Intervals are Monte-Carlo: parameters are drawn from the fitted covariance on
#' the model's internal (log) scale and back-transformed, so the interval is
#' boundary-aware near the common zero-rater-variance case where the delta method
#' fails. Pass `seed` for a reproducible interval.
#'
#' @param data A data frame with one rating per row.
#' @param score,subject,rater Columns of `data` (unquoted): the numeric rating,
#'   the subject (object of measurement), and the rater (judge).
#' @param cluster Optional column of `data` (unquoted) giving the higher-level
#'   unit each subject is nested in (e.g. classroom, clinic). Supplying it switches
#'   on the **multilevel** ICC (ten Hove et al. 2022): reliability is reported at
#'   the subject and/or cluster level (see `level` and the *Multilevel designs*
#'   section). Left `NULL` (the default) for an ordinary single-level two-way ICC.
#' @param model Design: `"twoway"` (the default; subjects crossed with a common
#'   set of raters) or `"oneway"` (each subject rated by a possibly different set
#'   of raters). Under `"oneway"` (Shrout & Fleiss Case 1) the raters are treated
#'   as **interchangeable** -- the `rater` column is used only to count the ratings
#'   per subject, its labels are ignored, and there is no rater main effect to
#'   model, so `type` does not apply and the coefficients are `ICC(1)` / `ICC(k)`.
#'   Fixed raters and a `cluster` (multilevel) structure are not defined for a
#'   one-way design.
#' @param type Error definition(s) (two-way only): `"agreement"` (absolute
#'   agreement) counts systematic rater differences as error; `"consistency"`
#'   ignores them. Like `unit` and `level`, `type` is **vectorized and defaults to
#'   both** (`c("agreement", "consistency")`), so a default call reports every
#'   defined formulation -- `ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)`, `ICC(C,k)` -- from
#'   the single fit (agreement vs. consistency is post-fit arithmetic on the same
#'   variance components, so the second definition is free). Pass a single value to
#'   report just that coefficient once you have named your estimand. A definition
#'   that is undefined for the design (e.g. `"consistency"` for a Design-3
#'   nested-in-subjects fit, or a fixed-rater agreement projection to a different
#'   rater count) is dropped with a message when reached via the default, and aborts
#'   with a teaching error when requested explicitly. Not applicable when
#'   `model = "oneway"`.
#' @param raters Rater sampling: `"random"` (the default; two-way random, Case 2)
#'   generalizes to a rater universe; `"fixed"` (two-way mixed, Case 3) treats the
#'   observed raters as the entire population and is fit with raters as fixed
#'   effects (`score ~ 1 + rater + (1 | subject)`). On balanced data the point
#'   estimate matches `"random"`; on incomplete data the two genuinely differ.
#'   Even when balanced, the interval differs for absolute agreement, because
#'   inference about fixed vs. random rater effects is not the same. Choosing
#'   `"fixed"` emits a warning, because random is the recommended default for
#'   interrater reliability.
#' @param unit The averaging unit(s): `"single"` (-> `ICC(*,1)`), `"average"`
#'   (-> `ICC(*,k)`), or a number `m` >= 1 for a D-study projection to the mean of
#'   `m` raters (-> `ICC(*,m)`), or any combination. See [d_study()] for projecting
#'   across a range of `m`. Projecting absolute agreement is not defined for fixed
#'   raters (see [d_study()]).
#' @param occasions For data with **within-cell replicates** (more than one rating
#'   per subject-by-rater cell), whether to average over them: `"single"` (the
#'   default -- the reliability of one rating) and/or `"average"` (the mean of the
#'   `n_o` replicates, which reduces pure error). `"average"` requires replicated
#'   data. See the *Within-cell replicates* section. Ignored with one rating per
#'   cell.
#' @param level For multilevel designs (a `cluster` column), which reliability to
#'   report: `"subject"` (within-cluster, distinguishing subjects) and/or
#'   `"cluster"` (between-cluster, distinguishing cluster means). Defaults to both.
#'   `"conflated"` may be added for the biased ignore-the-clustering ICC as a
#'   diagnostic contrast (agreement-only, complete crossed designs; see the
#'   *Multilevel designs* section). Ignored (and must be left at its default) when
#'   `cluster` is not supplied. Only `"subject"` is available when raters are nested
#'   in clusters.
#' @param design Multilevel design (with a `cluster` column): `NULL` (the default)
#'   infers it from the crossing pattern. On **incomplete** data missing cells can
#'   make the pattern ambiguous between a crossed and a nested design; declare it
#'   explicitly with `"crossed"`, `"nested_in_clusters"`, or `"nested_in_subjects"`
#'   to resolve the ambiguity. A declaration is validated against the data -- it
#'   cannot force a design the data cannot support (e.g. `"crossed"` still requires
#'   raters that bridge clusters to estimate absolute agreement).
#' @param engine Estimation engine: `"glmmTMB"` (default), `"lme4"`,
#'   `"lavaan"`, or `"brms"`. `"glmmTMB"` and `"lme4"` fit the variance components by REML and
#'   agree to within numerical tolerance on balanced data. `"lavaan"` fits the
#'   equivalent structural-equation (common-factor) generalizability model and
#'   recovers the rater main effect from the mean structure (Jorgensen 2021).
#'   **Consistency** ICCs from `"lavaan"` equal the mixed-model estimates exactly
#'   on balanced data; **absolute-agreement** ICCs use the SEM indicator-mean
#'   estimator of the rater variance, which is asymptotically equivalent to the
#'   mixed-model one and matches conventional generalizability-theory software on
#'   real data (Vispoel et al. 2022) but differs by a small-sample term on tiny
#'   designs (e.g. 0.284 vs 0.290 on the 6-subject example below). `"lme4"` covers
#'   every design `"glmmTMB"` does -- two-way (random or fixed raters), one-way, and
#'   the multilevel designs (crossed and nested) at both levels -- on both balanced
#'   and **incomplete/ragged** data. A ragged fit that lands exactly on a
#'   variance-component boundary falls back to `"glmmTMB"` (which stays finite via its
#'   log-SD parameterization) with a clear message. `"lavaan"`
#'   covers the two-way design with random or fixed raters (for fixed raters the
#'   agreement rater term is the McGraw & Wong Case-3A bias-corrected
#'   finite-population variance, which equals the mixed-model estimate on balanced
#'   data), on both complete and **incomplete** data (missing cells are estimated by
#'   full-information maximum likelihood; the parametric bootstrap is unavailable for
#'   incomplete SEM), and the crossed (Design 1) **multilevel** design at both
#'   levels (plus the conflated diagnostic) via a two-level SEM. With **random**
#'   raters the multilevel fit covers both complete/balanced data and
#'   **incomplete** (missing cells estimated by two-level full-information ML) or
#'   **unbalanced** (unequal cluster sizes) data; the interval is the Monte-Carlo
#'   interval (the default), or the parametric bootstrap (which simulates
#'   two-level datasets from the fitted moments and refits per resample) on
#'   balanced/complete data only -- incomplete or unbalanced data is Monte-Carlo
#'   only (resamples cannot reproduce a missingness pattern, and the bootstrap
#'   coverage is validated only on balanced data). With **fixed** raters the
#'   between-level rater intercepts give the Case-3A finite-population
#'   \eqn{\theta^2_r} at both levels (Monte-Carlo only; the fixed-rater bootstrap
#'   is not yet available), on complete, balanced data with equal cluster sizes
#'   only; because lavaan's
#'   random-rater term is the raw quadratic form, the fixed-rater ICC differs from
#'   the random-rater one by the finite-population correction (which the REML-based
#'   mixed-model engines do not carry into their random estimate). lavaan's
#'   two-level estimator is full-information ML
#'   (there is no REML analog), so with few clusters its cluster-level components
#'   sit slightly below the REML estimates and its absolute-agreement rater term
#'   slightly above (both differences shrink as clusters grow; consistency ICCs
#'   are ratios and agree with the mixed-model estimates essentially exactly).
#'   `"brms"` fits the **random**-rater model in a Bayesian
#'   framework (Stan, via \pkg{brms}) under a sourced half-*t*(4, 0, 1) prior on the
#'   random-effect SDs (ten Hove et al. 2020); the point estimate is the posterior
#'   mode (MAP) and the interval is a percentile **credible** interval
#'   (`ci_method = "posterior"`, forced). It covers, on **both balanced/complete and
#'   incomplete/ragged** data, the two-way random single-level design, the crossed
#'   (Design 1) **multilevel** random design (subject and cluster levels), the
#'   two-way **fixed-rater** single-level design (Case-3A finite-population
#'   \eqn{\theta^2_r}), the crossed (Design 1) multilevel **fixed-rater** design (subject
#'   level), and the nested **Design 2** (raters nested in clusters) and **Design 3** (raters
#'   nested in subjects, the multilevel one-way, agreement-only) *random* multilevel designs
#'   (subject level), and the single-level one-way random design; the nested Design 2
#'   *fixed-rater* multilevel design at the subject level on both balanced and
#'   incomplete/ragged data; and, on balanced/complete data only, the crossed Design 1
#'   *fixed-rater* **cluster** level, the conflated diagnostic, and within-cell replicates.
#'   Within-cell-replicate Bayesian fits and numeric-`unit` (D-study) projection are planned
#'   for later milestones. `"lme4"` requires the
#'   \pkg{lme4} and \pkg{merDeriv} packages; `"lavaan"` requires the \pkg{lavaan}
#'   package; `"brms"` requires the \pkg{brms} package (and a working Stan toolchain).
#' @param conf_level Confidence level for the interval (default `0.95`).
#' @param ci_method Interval method. `"montecarlo"` (default) simulates from the
#'   fitted parameter covariance on the engine's log scale (fast, boundary-aware).
#'   `"bootstrap"` is a parametric bootstrap: it simulates response vectors from the
#'   fitted model, refits, and takes percentile quantiles of the resampled
#'   coefficients. The bootstrap does not rely on the asymptotic-normal covariance
#'   approximation but is far slower (a refit per resample). It is available for
#'   every design the `"glmmTMB"` and `"lme4"` engines fit (via `glmmTMB`'s
#'   `simulate()` + refit and `lme4::bootMer` respectively) and, for the random
#'   two-way design and the crossed (Design 1) random-rater multilevel design, the
#'   `"lavaan"` engine (which simulates from the fitted SEM's implied moments and
#'   refits). As with the Monte-Carlo interval, the `"lme4"`
#'   engine defers a singular (boundary) fit to `"glmmTMB"` for either method.
#'   `"posterior"` is the percentile **credible** interval from the Bayesian
#'   engine's posterior draws; it is the forced default for, and available only with,
#'   `engine = "brms"` (and `"brms"` requires it) -- the other methods do not apply
#'   to a Bayesian fit, and `"posterior"` needs posterior draws no other engine
#'   produces.
#'   `"npbootstrap"` is the **non-parametric** transformed bootstrap-*t* of Ukoumunne
#'   et al. (2003), for the **one-way random design** (`model = "oneway"`; it aborts
#'   otherwise). It serves both `unit = "single"` (ICC(1)) and `unit = "average"`
#'   (ICC(k)) on **balanced and unbalanced** data (unequal ratings per subject) alike;
#'   on unbalanced data the effective group size becomes the ANOVA `n0` of Ohyama
#'   (2025). Only a numeric `unit` (a D-study projection to `m` raters) is restricted
#'   to balanced data -- unbalanced use `ci_method = "montecarlo"` for a projection.
#'   It resamples whole subjects
#'   with replacement (not from the fitted model), stabilizes the variance with the
#'   `log F` transform, studentizes with an infinitesimal-jackknife SE, and
#'   back-transforms the endpoints. It is **not** a percentile bootstrap -- the
#'   percentile and BCa variants were assessed and rejected (they under-cover at
#'   small rater counts); reach for it for its boundary robustness (an interval that
#'   exists where the Monte-Carlo default aborts) and non-normality robustness. See
#'   Details for the ICC(k), endpoint-support, and point-estimate conventions.
#'   `"searle"` and `"burch"` are two **deterministic classical closed-form**
#'   intervals, also **only for the balanced one-way random design** (they abort
#'   otherwise). Both give a finite interval on every dataset -- including the
#'   near-zero-ICC boundary where the Monte-Carlo default aborts -- and neither
#'   resamples, so `mc_samples`, `boot_samples`, and `seed` do not apply.
#'   `"searle"` is the exact-F pivot (Searle 1971; McGraw & Wong 1996, Table 7):
#'   **exact under normality**, best-calibrated and narrowest when the data are
#'   approximately normal. `"burch"` is the REML-based, kurtosis-adjusted interval
#'   of Burch (2011): wider, but robust to non-normality and never under-covering.
#'   Prefer `"searle"` for near-normal data and `"burch"` when heavy tails or
#'   non-normality are a concern.
#'   `"mpl"` is the **modified profile-likelihood** interval of Xiao & Liu (2013),
#'   **only for the balanced-complete two-way random absolute-agreement ICC(A,1)** (and
#'   ICC(A,k) via its Spearman-Brown image); it aborts on any other design, on
#'   consistency (ICC(C,.)) or fixed raters, on unbalanced or incomplete data, and on a
#'   numeric `unit`. It is a **deterministic closed form** (no resampling; `mc_samples`,
#'   `boot_samples`, and `seed` do not apply) that, like `"npbootstrap"`, returns an
#'   interval on **every** dataset -- including the near-zero-ICC boundary where the
#'   two-way Monte-Carlo default aborts -- and covers at or above nominal across the
#'   pre-registered grid where the incumbents can under-cover (assessed GO-for-opt-in in
#'   M87). It is deliberately **conservative** (it over-covers, and is wider than the
#'   Monte-Carlo interval at interior cells), so it is an opt-in, not the default.
#'   Two constraints follow from its calibration. It is available **only at
#'   `conf_level = 0.95`** (the level its correction constant is tabulated for; other
#'   levels abort). And its correction constant is calibrated by simulation over
#'   `rho in [0.05, 0.9]`, extending below Xiao & Liu's published `rho >= 0.6` fence
#'   into a near-boundary region that **carries no external oracle** -- there, the
#'   interval's calibration rests on the package's own simulated coverage. It assumes
#'   approximately Gaussian data (untested for non-normality).
#' @param mc_samples Number of Monte-Carlo draws for `ci_method = "montecarlo"`
#'   (default `10000`).
#' @param boot_samples Number of resamples for `ci_method = "bootstrap"` (the
#'   parametric bootstrap) and `"npbootstrap"` (the transformed bootstrap-*t*
#'   subject resamples); default `999`. Ignored when `ci_method = "montecarlo"`.
#' @param seed Optional integer seed for a reproducible interval (and, for
#'   `engine = "brms"`, the Stan sampler seed). The global RNG state is restored
#'   afterward.
#' @param brm_args A named list of extra arguments forwarded to [brms::brm()] when
#'   `engine = "brms"` (e.g. `backend`, `chains`, `iter`, `cores`, `control`). The
#'   default (rstan backend, brms defaults) needs none. By default brms samples the
#'   chains **sequentially on one core** (`cores = getOption("mc.cores", 1L)`); pass
#'   `brm_args = list(cores = 4)` (or set `options(mc.cores)`) to sample in parallel
#'   — the engine emits a periodic reminder to that effect while running
#'   sequentially. The model formula, data, the sourced half-*t* prior, and `seed`
#'   are owned by `intraclass` and may not be set here (the prior has its own
#'   `prior` argument); supplying them, or a non-empty `brm_args` with any other
#'   engine, is an error.
#' @param prior Optional custom prior for `engine = "brms"`, as a \pkg{brms} prior
#'   object (from [brms::set_prior()] / [brms::prior()]; combine several with `c()`).
#'   The default `NULL` uses the **sourced** half-*t*(4, 0, 1) prior on every
#'   random-effect SD (ten Hove, Jorgensen & van der Ark 2020), the prior every
#'   coverage result in this package depends on. Supplying a custom prior is a
#'   deliberate deviation — intended for prior-sensitivity, method-comparison, or
#'   simulation work — and **voids those coverage guarantees**; `icc()` warns
#'   loudly (a classed `intraclass_custom_prior` condition) because a vague or flat
#'   SD prior can *worsen* small-*k* boundary bias (the half-*t* is weakly
#'   informative on purpose). Ignored (must be `NULL`) for non-Bayesian engines.
#' @param posterior_summary How to summarize the posterior draws into a credible
#'   interval when `ci_method = "posterior"` (the Bayesian engine): `"percentile"`
#'   (the default — a two-sided percentile interval) or `"hpdi"` (the
#'   highest-posterior-density interval, the narrowest interval covering the
#'   credible mass). Percentile is the default because it is
#'   monotone-transformation invariant and degrades gracefully as the ICC
#'   approaches the variance boundary, and ten Hove, Jorgensen & van der Ark (2020)
#'   found percentile (not HPD) intervals give nominal coverage at small rater
#'   counts; the HPDI is offered for comparison, not as a strict upgrade (no
#'   coverage is claimed for it). Only the HPDI needs the posterior draws, so
#'   `posterior_summary = "hpdi"` requires `ci_method = "posterior"`; the other
#'   interval methods already report a percentile interval.
#'
#' @details
#' # The `"npbootstrap"` interval (one-way)
#'
#' For `unit = "average"` (the ICC(k), reliability of the mean of the *k* ratings)
#' the transformed bootstrap-*t* interval is the exact monotone **Spearman-Brown**
#' image of the single-rating ICC(1) interval,
#' `g(rho) = k_eff*rho / (1 + (k_eff-1)*rho)` applied to the two ICC(1) endpoints,
#' with `k_eff` the effective number of ratings per subject (the harmonic mean, `= k`
#' on balanced data). Because that map is strictly increasing on the attainable range,
#' the ICC(k) interval's coverage is **identical to the ICC(1) interval's, by
#' construction** -- it is not a separate approximation.
#'
#' On **unbalanced** data (unequal ratings per subject) the reducer uses the ANOVA
#' effective group size `n0 = (N - sum(n_i^2)/N) / (k - 1)` (Ohyama 2025) in the
#' `log F` transform, and studentizes `log(SSA) - log(SSE)` -- the pivot the
#' infinitesimal-jackknife SE is derived for (Ukoumunne et al. 2003, Appendix A),
#' which coincides with the balanced `log F` pivot when subjects are equally rated.
#' The Spearman-Brown map stays well-defined unbalanced because `k_eff <= n0` for
#' every one-way design, so its pole `-1/(k_eff-1)` sits at or below the ICC(1)
#' support boundary `-1/(n0-1)` and never falls inside the interval; coverage
#' inheritance therefore holds unbalanced exactly as it does balanced. A numeric
#' `unit` (D-study projection to `m` raters), by contrast, is balanced-only: a chosen
#' `m` may exceed `n0` and push the pole inside the support.
#'
#' Following Ukoumunne et al. (2003, §5.2), the endpoints are **not truncated** to
#' `[0, 1]`: they are confined only to the estimator's own support (approaching
#' `-1/(n0-1)` from above for ICC(1), and unbounded below for ICC(k)), so a
#' near-boundary lower endpoint can be negative -- markedly so for ICC(k). Leaving
#' them untruncated is what makes the coverage faithful to the published method. On
#' unbalanced data the reported ICC(k) `std.error` (the spread of the resampled
#' ICC(k) values) can likewise be large near the boundary, where a resample close to
#' the pole inflates the untruncated ICC(k) scale; this is a faithful disclosure, not
#' an error, and the coverage-bearing endpoints are unaffected.
#'
#' The reported **point estimate** is the engine (REML) point, exactly as for every
#' other `ci_method` -- `ci_method` selects the interval, not the estimator. At the
#' zero-between-variance boundary the point reads `0` while the untruncated interval
#' may extend below `0`; this is the normal picture for a boundary-respecting point
#' beside an honest interval, and it signals that the data are consistent with values
#' near and below zero.
#'
#' # The classical `"searle"` and `"burch"` intervals (balanced one-way)
#'
#' Both are deterministic closed forms from the one-way ANOVA. `"searle"` inverts the
#' exact-F pivot `F / (1 + n*lambda) ~ F(k-1, k(n-1))` (Searle 1971; the McGraw & Wong
#' 1996 Table 7 limits); it is exact under normality. `"burch"` builds
#' kurtosis-adjusted `log(1 + n*theta-hat)` limits (Burch 2011), so its width tracks
#' the data's tail weight -- wider but robust to non-normality, and never
#' under-covering. Both share the conventions above: the `unit = "average"` (ICC(k))
#' interval is the same exact monotone **Spearman-Brown** image of the ICC(1)
#' endpoints (so its coverage is identical by construction), endpoints are left
#' **untruncated** on the estimator's own support, and the reported **point** is the
#' engine (REML) point. Being closed forms they take no `mc_samples`, `boot_samples`,
#' or `seed`, and report no `std.error` (there is no sampling distribution). Their
#' value is a finite, well-calibrated interval on the near-zero-ICC boundary where the
#' Monte-Carlo default aborts.
#'
#' @return An `icc` object: a list with the estimate table, variance components,
#'   design, engine, interval settings, sample sizes, the fitted model, and the
#'   call. Use [tidy()][generics::tidy], [glance()][generics::glance], and the
#'   `print`/`summary` methods.
#'
#' @references
#' Burch, B. D. (2011). Confidence intervals for the intraclass correlation
#' coefficient based on the restricted maximum likelihood estimator.
#' *Journal of Statistical Computation and Simulation, 81*(9), 1101-1115.
#'
#' McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
#' correlation coefficients. *Psychological Methods, 1*(1), 30-46.
#'
#' Searle, S. R. (1971). *Linear Models*. Wiley.
#'
#' Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
#' assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.
#'
#' Ukoumunne, O. C., Davison, A. C., Gulliford, M. C., & Chinn, S. (2003).
#' Non-parametric bootstrap confidence intervals for the intraclass correlation
#' coefficient. *Statistics in Medicine, 22*(24), 3805-3821.
#'
#' ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#' reliability for multilevel data: A generalizability theory approach.
#' *Psychological Methods, 27*(4), 650-666.
#'
#' @examples
#' ratings <- data.frame(
#'   subject = factor(rep(1:6, 4)),
#'   rater = factor(rep(1:4, each = 6)),
#'   score = c(9, 6, 8, 7, 10, 6, 2, 1, 4, 1, 5, 2,
#'             5, 3, 6, 2, 6, 4, 8, 2, 8, 6, 9, 7)
#' )
#' icc(ratings, score, subject, rater, seed = 1)
#'
#' @export
icc <- function(
  data,
  score,
  subject,
  rater,
  cluster = NULL,
  model = "twoway",
  type = c("agreement", "consistency"),
  raters = c("random", "fixed"),
  unit = c("single", "average"),
  occasions = "single",
  level = c("subject", "cluster"),
  design = NULL,
  engine = "glmmTMB",
  conf_level = 0.95,
  ci_method = "montecarlo",
  mc_samples = 10000L,
  boot_samples = 999L,
  seed = NULL,
  brm_args = list(),
  prior = NULL,
  posterior_summary = c("percentile", "hpdi")
) {
  if (!is.data.frame(data)) {
    abort_intraclass("{.arg data} must be a data frame.")
  }

  # Capture whether the caller left `ci_method` at its default BEFORE validate_choice
  # reassigns it, so the Bayesian forced-default coupling can tell an unset `ci_method`
  # (auto-upgrade to "posterior" for a brms fit) from an explicit mismatch (abort).
  ci_method_default <- missing(ci_method)
  # Capture whether the caller left `type` at its default (both agreement and
  # consistency), so `ci_method = "mpl"` -- an absolute-agreement-only method -- can
  # narrow an unset `type` to "agreement" but reject an explicit consistency request.
  type_supplied <- !missing(type)

  # Dimensions not yet implemented fail loudly and point at where they are coming
  # (PRINCIPLES.md #5); implemented multi-value dimensions are arg-matched.
  model <- validate_choice(model, c("twoway", "oneway"), "model")
  oneway <- model == "oneway"
  engine <- validate_choice(
    engine,
    c("glmmTMB", "lme4", "lavaan", "brms"),
    "engine"
  )
  ci_method <- validate_choice(
    ci_method,
    c(
      "montecarlo",
      "bootstrap",
      "posterior",
      "npbootstrap",
      "searle",
      "burch",
      "mpl"
    ),
    "ci_method"
  )

  # Bayesian coupling (ADR-033): the brms engine and `ci_method = "posterior"` are
  # locked together -- a Bayesian fit reports a posterior CREDIBLE interval from its
  # MCMC draws, so it defaults to and requires "posterior", and "posterior" is
  # meaningless without the posterior draws only the brms engine produces. A brms fit
  # with `ci_method` left unset upgrades to "posterior"; explicit mismatches abort
  # loudly and teach the coupling (#5/#8). A selectable coupling (MC/bootstrap on a
  # Bayesian fit for method comparison) is parked (ADR-033).
  if (engine == "brms" && ci_method_default) {
    ci_method <- "posterior"
  }
  if (engine == "brms" && ci_method != "posterior") {
    abort_unsupported(c(
      "The {.pkg brms} (Bayesian) engine reports a posterior credible interval, so \\
       it requires {.code ci_method = \"posterior\"}.",
      i = "{.code \"montecarlo\"} and {.code \"bootstrap\"} do not apply to a \\
           Bayesian fit.",
      i = "Drop {.arg ci_method} -- it defaults to {.val posterior} for \\
           {.code engine = \"brms\"}."
    ))
  }
  if (ci_method == "posterior" && engine != "brms") {
    abort_unsupported(c(
      "{.code ci_method = \"posterior\"} requires {.code engine = \"brms\"}.",
      i = "The posterior credible interval is derived from MCMC draws, which only \\
           the Bayesian engine produces.",
      i = "Use {.code engine = \"brms\"}, or choose {.code ci_method = \"montecarlo\"} \\
           or {.code \"bootstrap\"}."
    ))
  }

  # `brm_args` is a brms-scoped passthrough to brms::brm() (ADR-033 amendment): the
  # backend and sampler knobs only. It is an error off the Bayesian engine, and it may
  # not override what `intraclass` owns -- the model formula, the data, the SOURCED
  # half-*t* prior (#12), or `seed` (which icc() threads to Stan). Guard both loudly
  # (#5/#8) so the engine can assume a clean list.
  if (!is.list(brm_args)) {
    abort_intraclass("{.arg brm_args} must be a list.")
  }
  if (length(brm_args) > 0L && engine != "brms") {
    abort_unsupported(c(
      "{.arg brm_args} only applies to {.code engine = \"brms\"}.",
      i = "It forwards arguments to {.fn brms::brm}; drop it for other engines."
    ))
  }
  reserved <- intersect(names(brm_args), c("formula", "data", "prior", "seed"))
  if (length(reserved) > 0L) {
    abort_intraclass(c(
      "{.arg brm_args} may not set {.val {reserved}}.",
      i = "The model formula, data, the sourced half-{.emph t} prior, and \\
           {.arg seed} are set by {.pkg intraclass}; pass only sampler/backend \\
           knobs (e.g. {.code backend}, {.code chains}, {.code iter}, {.code cores}).",
      i = if ("prior" %in% reserved) {
        "To use a custom prior, pass the {.arg prior} argument of {.fn icc}, not \\
         {.arg brm_args}."
      }
    ))
  }

  # User prior override (M34 Slice 1, ADR-044). `prior = NULL` keeps the SOURCED
  # half-*t*(4, 0, 1) SD prior (#12) -- the prior every coverage result depends on. A
  # non-NULL `prior` is a deliberate deviation (prior-sensitivity / method-comparison /
  # simulation work); it is brms-only, must be a brms prior object, and VOIDS the
  # coverage oracle. It is the ONE canonical override path (the `brm_args` guard above
  # still forbids setting `prior` there), injected into the engine's brm() call here and
  # announced by a loud classed footgun warning (#8). No coverage claim is made under a
  # custom prior (#4); the warning + docs carry the honesty (#18).
  if (!is.null(prior)) {
    if (engine != "brms") {
      abort_unsupported(c(
        "{.arg prior} only applies to {.code engine = \"brms\"}.",
        i = "The sourced half-{.emph t} prior is specific to the Bayesian engine; \\
             drop {.arg prior} for other engines."
      ))
    }
    if (!inherits(prior, "brmsprior")) {
      abort_intraclass(c(
        "{.arg prior} must be a {.pkg brms} prior object or {.code NULL}.",
        i = "Build one with {.fn brms::set_prior} or {.fn brms::prior}, e.g. \\
             {.code prior = brms::set_prior(\"student_t(4, 0, 1)\", class = \"sd\")}."
      ))
    }
    warn_intraclass(
      c(
        "Using a custom {.arg prior} instead of the sourced \\
         half-{.emph t}(4, 0, 1).",
        "!" = "This VOIDS the package's coverage guarantees: the credible-interval \\
               coverage results (ten Hove et al. 2020) hold only for the sourced \\
               prior.",
        i = "A vague or flat SD prior can WORSEN small-{.var k} boundary bias -- the \\
             half-{.emph t} is weakly informative on purpose (Principle #3's regime).",
        i = "Leave {.arg prior} unset for the sourced default unless you are running \\
             prior-sensitivity or method-comparison work."
      ),
      class = "intraclass_custom_prior"
    )
    brm_args$prior <- prior
  }

  # Posterior summary choice (M34 Slice 2, ADR-044): percentile (default) vs HPDI credible
  # interval. Only the HPDI needs the posterior draws (the brms path); the mc/bootstrap
  # methods already report a PERCENTILE interval, so an explicit "percentile" is harmless
  # everywhere and only "hpdi" off the posterior path is meaningless -- a teaching abort
  # (#5/#8). `ci_method` is already final here (the Bayesian forced-default upgrade ran above).
  posterior_summary <- validate_choice(
    posterior_summary,
    c("percentile", "hpdi"),
    "posterior_summary"
  )
  if (posterior_summary == "hpdi" && ci_method != "posterior") {
    abort_unsupported(c(
      "{.code posterior_summary = \"hpdi\"} requires {.code ci_method = \"posterior\"}.",
      i = "The HPDI is computed from the {.pkg brms} posterior draws; \\
           {.code \"montecarlo\"} and {.code \"bootstrap\"} report a percentile interval \\
           and produce no posterior to take an HPDI of.",
      i = "Use {.code engine = \"brms\"} (which defaults to {.code ci_method = \\
           \"posterior\"}), or drop {.arg posterior_summary}."
    ))
  }

  type <- validate_type(type)
  raters <- validate_choice(raters, c("random", "fixed"), "raters")
  unit <- validate_unit(unit)
  occasions <- validate_occasions(occasions)
  mc_samples <- validate_sample_count(mc_samples, "mc_samples")
  boot_samples <- validate_sample_count(boot_samples, "boot_samples")
  seed <- validate_seed(seed)

  # A `cluster` column switches on the multilevel path (subjects nested in
  # clusters, raters crossed -- ten Hove et al. 2022 Design 1; estimand-spec M5).
  # `level` selects the within-cluster (subject) and/or between-cluster estimand.
  cluster_v <- rlang::eval_tidy(rlang::enquo(cluster), data)
  multilevel <- !is.null(cluster_v)
  if (multilevel) {
    level <- validate_levels(level)
    design <- validate_design(design)
    # Numeric `unit` (a multilevel D-study projection) is deferred at every level.
    if (any(vapply(unit, is.numeric, logical(1)))) {
      abort_unsupported(c(
        "Numeric {.arg unit} (D-study projection) is not supported for \\
         multilevel ICCs yet.",
        i = "Use {.val single} or {.val average}; multilevel D-study projection \\
             is planned for a later milestone."
      ))
    }
  } else {
    # `level` and `design` only mean something once subjects are nested.
    if (!identical(level, c("subject", "cluster"))) {
      abort_intraclass(c(
        "{.arg level} requires a {.arg cluster} column.",
        i = "Supply {.arg cluster} for a multilevel ICC, or drop {.arg level}."
      ))
    }
    if (!is.null(design)) {
      abort_intraclass(c(
        "{.arg design} requires a {.arg cluster} column.",
        i = "The multilevel design only applies once subjects are nested in \\
             clusters; supply {.arg cluster}, or drop {.arg design}."
      ))
    }
  }

  # lme4 design coverage (ADR-012 / M14 ADR-023): lme4 covers the random two-way
  # (M5.5), one-way (M6), the balanced fixed-rater two-way (Slice 1), and the
  # balanced crossed (Design 1) random-rater multilevel (Slice 2) paths. The
  # design-specific lme4 refusals -- incomplete fixed-rater, and any multilevel that
  # is nested, fixed, or incomplete -- are raised below where `ml_design`, `raters`,
  # and balancedness are known, so they can name the exact unsupported case.

  # The lavaan (SEM) engine covers the two-way COMPLETE design -- random raters
  # (M7, ADR-014) and, since M21 Slice 1/2 (ADR-031), fixed raters (Case-3A
  # theta^2_r) and the parametric bootstrap -- and, since M54 (D-005), the
  # crossed (Design 1) random-rater multilevel design on complete/balanced
  # data via a two-level CFA. One-way SEM stays deferred (recorded, not
  # rediscovered; ADR-014): route it to a loud abort rather than a silent
  # glmmTMB fallback (PRINCIPLES.md #5). The multilevel-scope guards (nested,
  # fixed, replicates, incomplete/unbalanced) need `ml_design`, `raters`, and
  # balance, so they live further down, as does the incomplete-data guard.
  if (engine == "lavaan" && oneway) {
    abort_unsupported(c(
      "The {.pkg lavaan} engine does not support the one-way design.",
      i = "{.code engine = \"lavaan\"} is not available for one-way designs; \\
           use {.code engine = \"glmmTMB\"}.",
      i = "SEM for one-way designs is planned for a later milestone."
    ))
  }

  # The brms (Bayesian) engine covers the two-way random (M23) and fixed-rater (M26 Slice 2)
  # single-level paths, the crossed (Design 1) + nested (Designs 2/3) multilevel random paths
  # (M24/M25) plus crossed/nested-D2 fixed-rater multilevel (M27), the single-level one-way
  # random path (M26 Slice 1), the conflated diagnostic + within-cell replicates (M29), and
  # -- on incomplete/ragged data -- the two-way random/fixed + crossed multilevel random/fixed
  # (M30/M31), the nested Designs 2/3 random (M32), and the single-level one-way (M33 Slice 1,
  # ADR-043). The still-deferred Bayesian fits -- incomplete within-cell replicates, incomplete
  # fixed-NESTED (no frequentist oracle), and D-study numeric unit -- stay deferred (recorded,
  # not rediscovered); each routes to a loud, teaching abort rather than a silent glmmTMB
  # fallback (#5). The crossed-only multilevel + conflated refusals are raised once `ml_design`
  # is resolved (below), and the data-dependent ones (replicates, incomplete corners, numeric
  # unit) further down. One-way
  # multilevel / one-way fixed already abort for every engine just below.

  # One-way (M6 spec §5): raters are interchangeable, so fixed raters and the
  # multilevel design do not apply. Fail loudly rather than silently ignore them.
  if (oneway) {
    if (multilevel) {
      abort_unsupported(c(
        "A one-way ICC has no cluster structure.",
        i = "Drop {.arg cluster}, or use {.code model = \"twoway\"} for a \\
             multilevel ICC."
      ))
    }
    if (raters == "fixed") {
      abort_unsupported(c(
        "Fixed raters do not apply to a one-way ICC.",
        i = "One-way designs treat raters as interchangeable; use the default \\
             {.code raters = \"random\"}, or {.code model = \"twoway\"} for \\
             fixed raters."
      ))
    }
  }

  # A numeric unit is a D-study projection; fixed-rater absolute agreement cannot be
  # projected to a different rater count (theta^2_r is the finite-population variance
  # of exactly the observed raters -- M4.5 spec, PRINCIPLES.md #5). An explicit single
  # `type = "agreement"` aborts; under a multi-type request the agreement projection is
  # dropped and consistency reported (ADR-054 drop-vs-abort). `type` stays unreduced --
  # agreement is still defined for non-numeric units -- so the estimand cross-product
  # filters agreement only where the unit is numeric.
  if (raters == "fixed" && any(vapply(unit, is.numeric, logical(1)))) {
    if (identical(type, "agreement")) {
      abort_fixed_agr_projection("agreement", raters)
    }
    if ("agreement" %in% type) {
      cli::cli_inform(c(
        "!" = "Dropping the {.val agreement} D-study projection: absolute agreement \\
               cannot be projected to a different rater count for fixed raters. \\
               Reporting {.val consistency} for numeric units."
      ))
    }
  }

  # Fixed raters is well-posed but forgoes generalization; nudge toward random
  # (M2 spec §3, ADR-006). Warning, not error -- a valid number is still returned.
  # Skip the advisory when a fixed-rater conflated ICC is requested: that combination
  # aborts below (Eq. 14 is random-rater), so an advisory about a rejected path is noise.
  if (raters == "fixed" && !(multilevel && "conflated" %in% level)) {
    warn_fixed_raters()
  }
  if (
    !is.numeric(conf_level) ||
      length(conf_level) != 1L ||
      conf_level <= 0 ||
      conf_level >= 1
  ) {
    abort_intraclass("{.arg conf_level} must be a single number in (0, 1).")
  }

  # Capture the columns with tidy-eval and canonicalize to subject/rater/score.
  score_v <- rlang::eval_tidy(rlang::enquo(score), data)
  subject_v <- rlang::eval_tidy(rlang::enquo(subject), data)
  rater_v <- rlang::eval_tidy(rlang::enquo(rater), data)

  if (!is.numeric(score_v)) {
    abort_intraclass("{.arg score} must be a numeric column.")
  }
  # droplevels() so identifiability checks count observed raters/subjects, not
  # empty factor levels left over from subsetting.
  df <- data.frame(
    subject = droplevels(as.factor(subject_v)),
    rater = droplevels(as.factor(rater_v)),
    score = as.numeric(score_v)
  )
  if (multilevel) {
    df$cluster <- droplevels(as.factor(cluster_v))
  }

  n_subjects <- nlevels(df$subject)
  n_raters <- nlevels(df$rater)
  n_clusters <- if (multilevel) nlevels(df$cluster) else NA_integer_
  if (!oneway && n_raters < 2L) {
    abort_unidentified(c(
      "A two-way ICC needs at least 2 raters to separate the rater variance.",
      i = "{.arg rater} has {n_raters} level{?s}."
    ))
  }
  if (n_subjects < 2L) {
    abort_unidentified(c(
      "An ICC needs at least 2 subjects to estimate the signal variance.",
      i = "{.arg subject} has {n_subjects} level{?s}."
    ))
  }
  # One-way separates the subject variance from the residual only if some subject
  # is rated more than once (estimand-spec M6 §5); with one rating each they are
  # confounded (PRINCIPLES.md #5). Rater identity is otherwise ignored.
  if (oneway && nrow(df) <= n_subjects) {
    abort_unidentified(c(
      "A one-way ICC needs at least one subject rated more than once to \\
       separate the subject and residual variances.",
      i = "Every {.arg subject} was rated once; provide replicate ratings."
    ))
  }

  # Multilevel identifiability (estimand-spec M5 §7). Only >= 2 raters is inherited
  # from the paper; the cluster/subject-nesting guards below are standard
  # variance-component identifiability (not cited to ten Hove et al. 2022).
  if (multilevel) {
    if (n_clusters < 2L) {
      abort_unidentified(c(
        "A cluster-level ICC needs at least 2 clusters to estimate the \\
         between-cluster variance.",
        i = "{.arg cluster} has {n_clusters} level{?s}."
      ))
    }
    cluster_of <- table(df$subject, df$cluster) > 0L
    if (any(rowSums(cluster_of) > 1L)) {
      abort_unidentified(c(
        "Each subject must be nested in a single cluster.",
        i = "Some {.arg subject} levels appear in more than one {.arg cluster}; \\
             multilevel ICCs (M5) assume subjects nested in clusters."
      ))
    }
    if (max(colSums(cluster_of)) < 2L) {
      abort_unidentified(c(
        "The between-subject and between-cluster variances cannot be separated \\
         when every cluster holds a single subject.",
        i = "At least one {.arg cluster} must contain 2 or more subjects."
      ))
    }
  }

  # Which multilevel design is this (ten Hove et al. 2022, Table 2)? Inferred from
  # the crossing pattern (estimand-spec M8 §4) UNLESS the caller declares it via
  # `design` -- the escape hatch for ragged patterns that are ambiguous between
  # crossed and nested under missing cells (spec M9 §4a, ADR-018). A declared
  # design is validated against the data by the identifiability guards below, never
  # used to override a structural impossibility. Design 1 ("crossed") is the M5
  # five-component path; Designs 2/3 (nested raters) are subject-level only.
  ml_design <- if (!multilevel) {
    NA_character_
  } else if (!is.null(design)) {
    design
  } else {
    detect_multilevel_design(df)
  }

  # brms (Bayesian) multilevel scope (M24 crossed, ADR-034; M25 nested Designs 2/3,
  # ADR-035; M29 conflated, ADR-039): the crossed (Design 1) five-component fit (subject +
  # cluster + conflated levels), the nested Design 2 four-component fit and the nested
  # Design 3 three-component fit (both subject level) -- random, balanced/complete. Design 3
  # is agreement-only (the generic consistency-on-Design-3 abort below applies to every
  # engine). The conflated diagnostic (M29 Slice 1) reads Eq. 14 off the same crossed
  # five-component fit as a variance-ratio push-forward -- no new fit, no brms-specific
  # guard: the engine-agnostic conflated checks below (consistency / fixed / nested) apply
  # to brms too, and brms incomplete data is refused by the balance guard. Fixed /
  # incomplete / replicate / numeric unit brms are refused with the rest of the brms
  # deferrals further down.

  # Conflated single-level ICC (Eq. 14, M17 Slice 1): the biased ignore-clusters
  # coefficient off the crossed five-component fit. Agreement-only, random raters,
  # crossed Design 1 (estimand-spec M17-conflated-icc.md §3). These checks run
  # before the fixed/nested guards below (which drop non-subject levels) so an
  # explicit `level = "conflated"` gets a conflated-specific message, not a
  # cluster-level one. The complete-data restriction lives with the crossed
  # incomplete guards further down.
  if (multilevel && "conflated" %in% level) {
    # The conflated collapse reads as a flat two-way ICC (M45/ADR-056): both the
    # agreement form (Eq. 14, ten Hove et al. 2022) and the consistency form (the flat
    # two-way consistency ICC, dropping the rater main effect sigma^2_r; McGraw & Wong
    # 1996) ship -- so `type` flows through unfiltered here, exactly as at the
    # subject/cluster levels. Fixed raters and non-crossed designs still abort below.
    if (raters == "fixed") {
      abort_unsupported(c(
        "A fixed-rater conflated ICC is not available.",
        i = "Eq. 14 treats the rater effect as a variance component (random \\
             raters).",
        i = "Use {.code raters = \"random\"} with {.code level = \"conflated\"}."
      ))
    }
    if (ml_design != "crossed") {
      abort_inapplicable(c(
        "The conflated ICC needs raters crossed with clusters (Design 1).",
        i = "It collapses the crossed five-component decomposition; with nested \\
             raters that decomposition is not defined.",
        i = "Use {.code level = \"subject\"}, or cross the raters with clusters."
      ))
    }
  }

  # Fixed-rater multilevel scope (M10, ADR-019): the crossed (Design 1) design,
  # balanced, subject level only. Fixed-rater nested designs and the fixed-rater
  # cluster level are deferred -- fail loudly (#5) before the design/fit machinery
  # runs. The balanced check lives below with the rest of the crossed guards.
  if (multilevel && raters == "fixed") {
    # Design 3 (raters nested in subjects) is the multilevel one-way: the rater main
    # effect is confounded into residual (Eq. 11), so there is no separable rater to
    # treat as fixed -- fixed vs random is not meaningful (cf. one-way fixed, M6 §10).
    # A by-design abort, not a "later milestone" deferral (ADR-029 decision C).
    if (ml_design == "nested_in_subjects") {
      abort_unsupported(c(
        "Fixed raters are not defined when raters are nested within subjects.",
        i = "With each subject rated by its own raters (Design 3) the rater main \\
             effect is confounded into residual, so there is no rater effect to \\
             treat as fixed (ten Hove et al. 2022, p. 6).",
        i = "Use {.code raters = \"random\"} (the default)."
      ))
    }
    # Design 2 (raters nested in clusters) with fixed raters ships in M19 Slice 2
    # (balanced) and M36 (incomplete/ragged, ADR-046): theta^2_{r:c} (finite-population,
    # averaged over clusters) replaces the random sigma^2_{r:c} in the subject-level
    # rater slot. The incomplete case (mixed-model engines) uses the ragged per-cluster
    # Case-3A theta^2_{r:c} (generalized to unequal k_c) + the M9 k_eff/connectedness
    # machinery; the Bayesian engine stays deferred here (guarded below).
    # Cluster-level fixed raters ship for the CROSSED Design 1, balanced/complete: the
    # mixed-model engines (glmmTMB/lme4) via M37 (ADR-047, off the M10 fixed fit) and the
    # brms engine via M38 Cell 1 (ADR-048, off the shipped M27 fit_brms_multilevel_fixed()
    # five-component draws -- no new fit; the cluster-level {sigma^2_c | theta^2_r, sigma^2_cr}
    # push-forward reads the same draws as the M24 random cluster level, since icc_estimand()
    # keys the cluster error set on `level` not `raters`). M37's feasibility spike confirmed
    # EXACT reduction to the M5 random cluster-level ICC (theta^2_r == sigma^2_r AND sigma^2_cr
    # unbiased under fixing, both |d| ~ 1e-7), so no finite-population correction on the
    # interaction and, on brms, `b ~ 0` -- a variance-ratio push-forward. The engine-agnostic
    # balance gate below (with `balanced`) defers the INCOMPLETE/unbalanced cluster-fixed cell
    # for every engine (double-blocked: ten Hove's open small-k estimator + the M9 §9 ICC(c,k)
    # divisor), so brms incomplete fixed cluster falls through to it and aborts there, exactly
    # as glmmTMB/lme4 do -- no brms-specific cluster guard is needed here. (lavaan
    # fixed-rater multilevel is refused by the M54 lavaan scope guard below.)
    # Nested fixed designs (nested_in_clusters) have no cluster level; they fall
    # through to the generic nested guard below (~L805), which drops the default
    # "cluster" / aborts an explicit cluster request and runs the M8/M19/M36
    # identifiability. Crossed fixed at the subject level (M10/M18) is unaffected.
    # Incomplete/ragged fixed-rater nested Design 2 ships for the MIXED-MODEL engines
    # (M36, ADR-046) AND the brms engine (M38 Cell 2, ADR-048): the ragged per-cluster
    # Case-3A theta^2_{r:c} pairs with the M9 k_eff/connectedness machinery. The brms sibling
    # needs no new fit and no brms-specific guard: fit_brms_nested_fixed() fits
    # `score ~ 0 + rater + (1|cluster:subject)` unchanged on ragged data, and
    # brms_theta2r_nested_draws() -> brms_theta2r_moment_draws() already reads a per-cluster
    # k (nrow of each cluster's rater-mean matrix), so unequal k_c and the 2b-under-imbalance
    # moment correction (b != 0) fall out per cluster with the boundary-aware average-floor.
    # The engine-agnostic identifiability gates below (>= 2 raters/cluster, within-cluster
    # connectedness, >= 2 ratings/subject) and the pre-dispatch harmonic-mean k_eff divisor
    # protect the ragged fit for every engine. The per-subject k_eff averaging divisor is
    # well-defined (ratings/subject, the M19 random-nested divisor); it is NOT the open
    # per-cluster ICC(c,k) divisor (M9 §9). lavaan cannot fit here (fixed-rater
    # multilevel SEM is refused by the M54 lavaan scope guard below).
  }
  if (multilevel && ml_design != "crossed") {
    if (!("subject" %in% level)) {
      abort_unsupported(c(
        "Cluster-level IRR is not defined when raters are nested in clusters or \\
         subjects.",
        i = "A cluster-level ICC needs raters crossed with clusters (Design 1); \\
             with nested raters only the subject level is defined \\
             (ten Hove et al. 2022, p. 6).",
        i = "Use {.code level = \"subject\"}, or cross the raters with clusters."
      ))
    }
    # Nested designs define only the subject level; drop the default "cluster".
    level <- "subject"
    # Design 3 (raters nested in subjects) is the multilevel one-way: the rater
    # main effect is confounded into residual, so consistency is undefined -- only
    # absolute agreement ICC(1)/ICC(k) (ten Hove et al. 2022, p. 6; spec M8 §3b).
    if (ml_design == "nested_in_subjects" && "consistency" %in% type) {
      # Design 3 is agreement-only design-wide. An explicit single
      # `type = "consistency"` aborts; a multi-type request drops consistency for the
      # whole design and reports agreement (ADR-054 drop-vs-abort).
      if (identical(type, "consistency")) {
        abort_unsupported(c(
          "Consistency is not defined when raters are nested within subjects.",
          i = "With each subject rated by its own raters (Design 3) the rater main \\
               effect cannot be separated, so only absolute agreement is defined \\
               (ten Hove et al. 2022, p. 6).",
          i = "Use the default {.code type = \"agreement\"}."
        ))
      }
      cli::cli_inform(c(
        "!" = "Dropping {.val consistency}: not defined when raters are nested within \\
               subjects (Design 3) -- the rater main effect cannot be separated, so \\
               only absolute agreement is defined (ten Hove et al. 2022, p. 6)."
      ))
      type <- setdiff(type, "consistency")
    }
    # Nested-design identifiability (estimand-spec M8 §7). These gates hold on both
    # balanced (M8) and INCOMPLETE/ragged (M19 Slice 1, ADR-029) data: the fit
    # formulas are unchanged and the subject-level averaging divisor is the
    # harmonic-mean k_eff (ratings per subject), which reduces EXACTLY to the pinned
    # M3 two-way / M6 one-way incomplete divisor (oracle O-NML/incomplete: ragged
    # single-cluster Design 2 == ragged two-way for all four coefficients; ragged
    # Design 3 == ragged one-way). So M8's balance guard is lifted -- the gates below
    # are what identifiability actually requires, balanced or not (#1/#5/#18).
    if (ml_design == "nested_in_clusters") {
      # Design 2 needs >= 2 raters within a cluster to identify sigma^2_{r:c}
      # (estimand-spec M8 §7).
      if (max(colSums(table(df$rater, df$cluster) > 0L)) < 2L) {
        abort_unidentified(c(
          "The nested rater variance cannot be estimated when every cluster has \\
           a single rater.",
          i = "At least one {.arg cluster} must contain 2 or more raters."
        ))
      }
      # Within a cluster, Design 2 is a two-way subject x rater layout. On ragged
      # data separating sigma^2_{s:c} and sigma^2_{r:c} from residual needs each
      # cluster's observed subject x rater graph connected -- reuse the crossed
      # per-cluster check (its within-cluster part is design-agnostic). A no-op on
      # complete crossing (M8), where every within-cluster graph is fully connected.
      ident <- crossed_ml_identifiability(df)
      if (!ident$within_cluster_connected) {
        abort_unidentified(c(
          "The subject-by-rater design is disconnected within some cluster, so the \\
           subject and residual variances cannot be separated there.",
          i = "{cli::qty(ident$disconnected_clusters)}Affected cluster{?s}: \\
               {.val {ident$disconnected_clusters}}.",
          i = "Every subject and rater within a cluster must be linked through \\
               shared ratings."
        ))
      }
      # Connectedness admits a single-rating "star"; separating sigma^2_{s:c} from
      # residual also needs at least one subject rated more than once (else the fit
      # returns a spurious ICC; cf. the crossed guard, spec M9 §4b, #5/#18).
      if (all(as.integer(table(df$subject)) < 2L)) {
        abort_unidentified(c(
          "The subject and residual variances cannot be separated when every \\
           subject is rated only once.",
          i = "At least one {.arg subject} must be rated by 2 or more raters."
        ))
      }
    } else {
      # Design 3 needs >= 2 raters per subject to separate residual from subject --
      # the guard is per-subject, so it already covers ragged data (M19 Slice 1).
      if (min(as.integer(table(df$subject))) < 2L) {
        abort_unidentified(c(
          "The residual variance cannot be separated from the subject variance \\
           when a subject is rated only once.",
          i = "Each {.arg subject} must be rated by 2 or more raters."
        ))
      }
    }
  }

  # Design facts for a possibly-incomplete layout (estimand-spec M3 §3, §5). For
  # one-way the k_eff (harmonic mean of ratings/subject) is the only fact needed;
  # the cross-classified checks below (replicates, connectedness) do not apply --
  # rater identity is ignored, so multiple ratings per subject are the design, not
  # a violation (M6 spec §5).
  design_info <- summarize_design(df)
  replicates <- FALSE
  # A ragged/incomplete single-level replicate design (M20 Slice 3): the
  # single-occasion ICC family ships, but the occasion-averaged coefficient needs an
  # unvalidated effective-n_o divisor and is gated to research below.
  ragged_replicates <- FALSE
  # The occasion count per cell for the replicate path. `summarize_design()` reads the
  # flat subject x rater grid (correct for single-level and crossed designs); the
  # nested (block-diagonal) case overrides it below with a design-aware value.
  n_o_val <- design_info$n_o
  if (!oneway) {
    # Within-cell replicates (M17 Slice 3): more than one rating per subject x rater
    # cell splits the residual into the interaction sigma^2_sr and pure error
    # sigma^2_e, fit by adding (1|subject:rater). Fixed raters (M20 Slice 1) and
    # multilevel designs (M20 Slice 2) now flow through; ragged replicates stay
    # deferred (#5; estimand-spec M17-within-cell-replicates.md §7, ADR-030).
    if (design_info$has_replicates) {
      if (multilevel) {
        # Multilevel within-cell replicates (M20 Slice 2): crossed Design 1 and nested
        # Design 2, random raters, balanced/complete. The residual gains a
        # (1|cluster:subject:rater) interaction split from pure error.
        if (ml_design == "nested_in_subjects") {
          # Design 3 is the multilevel one-way: raters nested in subjects, rater
          # confounded into residual, so there is no subject-by-rater interaction to
          # split (cf. one-way replicates ⚫; ten Hove et al. 2022, p. 6). By design.
          abort_unsupported(c(
            "Within-cell replicates are not defined when raters are nested within \\
             subjects.",
            i = "Design 3 is the multilevel one-way (the rater effect is confounded \\
                 into residual), so there is no subject-by-rater interaction to split \\
                 from pure error.",
            i = "Aggregate to one rating per subject-by-rater cell."
          ))
        }
        if (raters == "fixed") {
          # Fixed-rater multilevel replicates are a deferred compound corner (as
          # incomplete x fixed nested was for M19); random ships first.
          abort_unsupported(c(
            "Within-cell replicates are not supported for fixed-rater multilevel \\
             designs yet.",
            i = "Multilevel replicates ship for random raters; the fixed-rater case \\
                 is planned for a later milestone.",
            i = "Use {.code raters = \"random\"} with replicated multilevel data."
          ))
        }
        if ("conflated" %in% level) {
          # The conflated (ignore-clusters) diagnostic on replicated data is deferred.
          abort_unsupported(c(
            "Within-cell replicates are not supported for the conflated ICC yet.",
            i = "The conflated diagnostic on replicated data is planned for a later \\
                 milestone.",
            i = "Use {.code level = \"subject\"} or {.code \"cluster\"} with \\
                 replicated data."
          ))
        }
        ml_rep <- multilevel_replicate_facts(df, ml_design)
        if (!ml_rep$uniform) {
          # Ragged / incomplete multilevel replicates are a deferred compound corner
          # (imbalance x replicates); this slice ships balanced/complete only.
          abort_unsupported(c(
            "Ragged or incomplete within-cell replicates are not supported for \\
             multilevel designs yet.",
            i = "This slice covers balanced, complete replicated multilevel designs \\
                 (every cell present and rated the same number of times).",
            i = "Provide an equal number of ratings in every cell, or aggregate to \\
                 one rating per cell."
          ))
        }
        n_o_val <- ml_rep$n_o
      } else if (!design_info$replicates_uniform) {
        # Ragged / incomplete single-level replicates (M20 Slice 3, ADR-030). The
        # single-occasion ICC family is the replicate analogue of M3: the shipped
        # interaction fit fits ragged data, the rater divisor is the harmonic-mean
        # k_eff (distinct raters per subject), and connectedness is gated below -- all
        # sourced/oracle-pinned. The occasion-AVERAGED coefficient is deferred to
        # research: with unequal per-cell rating counts the "mean of n_o replicates"
        # has no single scalar effective-n_o divisor (GT averaging weights are
        # per-cell), and no textbook/independent oracle pins one, so shipping a guessed
        # divisor would violate #1/#4. Gated at the occasions check below.
        if (raters == "fixed") {
          # Ragged x fixed replicates are a deferred compound corner (one imbalance
          # dimension at a time, ADR-030): fixed-rater replicates ship BALANCED only.
          abort_unsupported(c(
            "Ragged within-cell replicates are not supported for fixed raters yet.",
            i = "Fixed-rater replicates ship for balanced, complete data; the ragged \\
                 case is planned for a later milestone.",
            i = "Use {.code raters = \"random\"} for ragged replicated data, or \\
                 provide an equal number of ratings in every cell."
          ))
        }
        ragged_replicates <- TRUE
      }
      # Fixed-rater (M20 Slice 1), multilevel (M20 Slice 2), and ragged single-level
      # (M20 Slice 3) within-cell replicates now flow through: theta^2_r replaces
      # sigma^2_r for fixed raters, multilevel fits gain the (1|cluster:subject:rater)
      # split, and ragged random data fits the shipped interaction model directly.
      replicates <- TRUE
    }
    # Separating the subject and rater variances needs a connected design; a
    # disconnected layout confounds them and is not identified (#5; M3 §3). This is
    # a single-level check: nested multilevel designs are block-disconnected in the
    # subject x rater graph by construction, and their identifiability is handled by
    # the multilevel guards above, so skip it for them (spec M8 §2).
    if (!multilevel && !design_info$connected) {
      abort_unidentified(c(
        "The subject-by-rater design is disconnected, so the subject and rater \\
         variances cannot be separated.",
        i = "Every subject and rater must be linked through shared ratings (one \\
             connected design).",
        i = "For unlinked rater groups, a one-way ICC ({.code model = \"oneway\"}) \\
             or additional linking ratings are needed."
      ))
    }
    # Incomplete crossed (Design 1) multilevel identifiability (estimand-spec M9
    # §4b, ADR-018). The single-level connectedness check above is skipped for
    # multilevel data (its subject x rater graph is block-structured by cluster);
    # the multilevel graph conditions here take its place, gating different
    # coefficients. Complete crossed designs satisfy every condition, so this is a
    # no-op for the balanced M5/M8 path.
    if (
      multilevel &&
        ml_design == "crossed" &&
        !replicates &&
        !design_info$balanced
    ) {
      # `design_info$balanced` reads the flat subject x rater grid, which counts a
      # replicated cell as "incomplete"; multilevel replicates (M20 Slice 2) are gated
      # to balanced/complete in the guard block above, so skip this incomplete-crossed
      # block for them (the de-replicated design is complete).
      # Incomplete conflated ICC (M18 Slice 2, ADR-028): the conflated diagnostic
      # (Eq. 14) LUMPS sigma^2_r + sigma^2_cr + sigma^2_res into one error term and
      # sigma^2_c + sigma^2_{s:c} into one signal, so it is the flat two-way ICC read
      # off the five-component fit -- its divisor is the same flat k_eff (harmonic mean
      # of ratings per subject) and its identifiability requirement is exactly the flat
      # two-way one. The crossed-multilevel gates below enforce that on ragged data
      # (within-cluster connectedness + subjects rated > once for sigma^2_{s:c}; the
      # agreement rater-bridging gate matches the flat design being connected across
      # clusters), so the conflated path flows through them unchanged -- conservative
      # (it strictly needs only the r+cr SUM), which is safe for a never-recommended
      # contrast (#5). It tracks the flat incomplete two-way agreement icc() at the
      # population level, as on complete data (spec M17-conflated-icc.md §5/§6).
      # Incomplete fixed-rater crossed multilevel (M18 Slice 1, ADR-028): the
      # finite-population theta^2_r (Case 3A, via the shared theta2r_fixed()) is read
      # from the fitted rater-contrast vcov, which glmmTMB/lme4 estimate on ragged
      # data, and the subject-level error divisor is the same k_eff (harmonic mean of
      # ratings per subject) the random path uses -- exactly as the single-level M3
      # incomplete fixed path (ADR-008). The identifiability gates below apply to the
      # fixed path unchanged: they are conservative for fixed raters (theta^2_r from a
      # fixed contrast is more robustly identified than a random sigma^2_r), so a
      # design they admit is safely fixed-identified too. The cluster level stays
      # deferred for fixed raters (level already forced to "subject" above).
      ident <- crossed_ml_identifiability(df)
      # Within-cluster subject x rater connectedness separates sigma^2_{s:c} from
      # residual; gates every subject-level coefficient (incl. consistency).
      if (!ident$within_cluster_connected) {
        abort_unidentified(c(
          "The subject-by-rater design is disconnected within some cluster, so the \\
           subject and residual variances cannot be separated there.",
          i = "{cli::qty(ident$disconnected_clusters)}Affected cluster{?s}: \\
               {.val {ident$disconnected_clusters}}.",
          i = "Every subject and rater within a cluster must be linked through \\
               shared ratings."
        ))
      }
      # within_cluster_connected is satisfied by a single-rater "star" cluster
      # (one rater rating several subjects once each), which is nonetheless
      # connected. Separating sigma^2_{s:c} from residual ALSO needs at least one
      # subject rated more than once; when every subject is rated exactly once the
      # two are confounded and the fit returns a spurious ICC = 0.5, so gate every
      # subject-level coefficient here rather than report it (spec M9 §4b; #5/#18).
      if (all(as.integer(table(df$subject)) < 2L)) {
        abort_unidentified(c(
          "The subject and residual variances cannot be separated when every \\
           subject is rated only once.",
          i = "At least one subject must be rated by 2 or more raters for a \\
               subject-level interrater ICC to be identified."
        ))
      }
      # sigma^2_r (rater main effect -- in the AGREEMENT error, spec §3a) separates
      # from sigma^2_cr only if raters bridge clusters. When they do not, the design
      # is effectively rater-nested (Design 2) for agreement; consistency (error =
      # residual only) is unaffected, so gate agreement specifically (spec §4b).
      if (!ident$cluster_rater_connected && "agreement" %in% type) {
        # Agreement is unidentifiable design-wide here (sigma^2_r does not separate
        # from sigma^2_cr); consistency is unaffected. An explicit single
        # `type = "agreement"` aborts; a multi-type request drops agreement and
        # reports consistency (ADR-054 drop-vs-abort; the ADR-029 inform-and-drop
        # precedent applied to a data-driven, not by-design, undefined cell).
        if (identical(type, "agreement")) {
          abort_unidentified(c(
            "Raters do not bridge clusters, so the rater main-effect variance cannot \\
             be separated from the cluster-by-rater variance for absolute agreement.",
            i = "This design is effectively rater-nested (Design 2) for agreement.",
            i = "Use {.code type = \"consistency\"}, or provide raters crossed across \\
                 clusters."
          ))
        }
        cli::cli_inform(c(
          "!" = "Dropping {.val agreement}: raters do not bridge clusters, so the \\
                 rater main-effect variance cannot be separated from the \\
                 cluster-by-rater variance -- this design is effectively rater-nested \\
                 (Design 2) for agreement. Reporting {.val consistency}."
        ))
        type <- setdiff(type, "agreement")
      }
      # The conflated level reads sigma^2_cr (cluster:rater) in its error set for BOTH
      # types -- the Eq. 14 agreement error {r, cr, res} and the M45 consistency error
      # {cr, res} -- so, like the cluster level below, it is identified only when raters
      # bridge clusters (M18 §6a's conservative flat-design-connected posture). Consistency
      # survives non-bridging at the SUBJECT level (its error is residual only), but NOT at
      # the conflated level, where sigma^2_cr does not separate from sigma^2_r. Drop the
      # whole conflated level when raters do not bridge; abort if it is the sole explicit
      # level (drop-vs-abort, ADR-054/ADR-029).
      if ("conflated" %in% level && !ident$cluster_rater_connected) {
        if (identical(level, "conflated")) {
          abort_unidentified(c(
            "The conflated ICC needs raters that bridge clusters, but the \\
             cluster-by-rater design is disconnected here.",
            i = "It reads the cluster-by-rater variance off the crossed fit, which \\
                 is not identified without raters shared across clusters.",
            i = "Use {.code level = \"subject\"}, or provide raters crossed across \\
                 clusters."
          ))
        }
        cli::cli_inform(
          c(
            "!" = "Dropping the {.val conflated} level: raters do not bridge clusters, \\
                   so the cluster-by-rater variance it reads is not identified. \\
                   Reporting the correctly-partitioned levels."
          ),
          .frequency = "once",
          .frequency_id = "conflated-nonbridging"
        )
        level <- setdiff(level, "conflated")
      }
      # Cluster-level IRR on incomplete data (M9 Slice 2, ADR-018; averaged case M46,
      # ADR-057). The cluster-level error carries sigma^2_cr (both types) and sigma^2_r
      # (agreement), which are identified only when raters bridge clusters; otherwise
      # report just the subject level (M5 §7 posture). The averaged ICC(c,k) divisor
      # under imbalance -- an open modeling question at M9 -- is resolved by M46: the
      # inverse-Simpson harmonic k_c^eff (Fable-blessed, ADR-057 Am.1), threaded into
      # the cluster estimand below. So the bridging gate is the only cluster-level
      # guard here now; both ICC(c,1) and ICC(c,k) ship on incomplete data.
      if ("cluster" %in% level && !ident$cluster_rater_connected) {
        abort_unidentified(c(
          "Cluster-level IRR needs raters that bridge clusters, but the \\
           cluster-by-rater design is disconnected here.",
          i = "The cluster-by-rater variance (the cluster-level rater \\
               disagreement) cannot be estimated without raters shared across \\
               clusters.",
          i = "Use {.code level = \"subject\"}, or provide raters crossed across \\
               clusters."
        ))
      }
    }
  }
  # Balance: for one-way, every subject rated the same number of times; for
  # two-way, a complete crossed design with one rating per cell (M3).
  balanced <- if (oneway) {
    length(unique(as.integer(table(df$subject)))) == 1L
  } else if (replicates && !ragged_replicates) {
    # Uniform, complete replicated designs (single-level M17, or multilevel M20
    # Slice 2) are gated to balanced/complete in the guard block above
    # (summarize_design / multilevel_replicate_facts), so the de-replicated design is
    # balanced by construction -- every subject is rated by every (in-cluster) rater.
    # Ragged single-level replicates (M20 Slice 3) fall through to design_info$balanced
    # (FALSE), so they are reported as the incomplete designs they are.
    TRUE
  } else if (multilevel && ml_design != "crossed") {
    # Nested designs are block-diagonal in the subject x rater graph, so
    # design_info$balanced (a crossed notion) is wrong for them (spec M8 §2); use the
    # nested-specific check. Incomplete nested designs (M19 Slice 1) now fit -- report
    # honest balance so print/glance flag the ragged case (the averaging divisor is
    # k_eff either way, reducing to M3/M6 on ragged data).
    nested_design_balanced(df, ml_design)
  } else {
    design_info$balanced
  }

  # The transformed bootstrap-t (`ci_method = "npbootstrap"`, ukoumunne2003; M75,
  # D-006/D-010) and the two classical closed-form intervals (`"searle"` exact-F
  # and `"burch"` REML, M82/D-012) are all BALANCED ONE-WAY methods: a one-way
  # ANOVA decomposition on raw subject groups. An explicit request on any other
  # design aborts loudly rather than silently falling back (#5/#8). Unbalanced
  # support (per-subject n_i / harmonic n0) is deferred design work (candidates).
  if (ci_method %in% c("npbootstrap", "searle", "burch")) {
    if (!oneway) {
      abort_unsupported(c(
        "{.code ci_method = {.val {ci_method}}} is available only for the one-way \\
         random design ({.code model = \"oneway\"}).",
        i = "It is a one-way ICC interval method; use \\
             {.code ci_method = \"montecarlo\"} for two-way, cluster, or \\
             multilevel designs."
      ))
    }
    if (!balanced) {
      # npbootstrap ships the UNBALANCED one-way ICC(1) (M84, ohyama2025 eq. 3 /
      # §2.3) AND ICC(k)/average (M85, MD-1): the ICC(k) interval is the monotone
      # Spearman-Brown image g(rho) = k_eff*rho/(1 + (k_eff - 1)rho) of the ICC(1)
      # endpoints with the harmonic-mean k_eff divisor. This is pole-safe because
      # k_eff <= n0 for EVERY one-way design (MD-1, AM-GM on triples), so the SB pole
      # -1/(k_eff - 1) sits at or below the support boundary -1/(n0 - 1) and never
      # intrudes on the attainable rho -- coverage inheritance is an exact event
      # identity, unbalanced as balanced. A numeric `unit` (D-study projection to m
      # raters) is NOT pole-safe -- a user-chosen m > n0 pushes the SB pole inside the
      # support -- so it stays a deferred candidate. The classical closed forms
      # ("searle"/"burch", M82) stay balanced-only.
      if (ci_method != "npbootstrap") {
        abort_unsupported(c(
          "{.code ci_method = {.val {ci_method}}} requires a balanced one-way \\
           design (every subject rated the same number of times).",
          i = "Unbalanced support (per-subject {.var n_i}) is not yet implemented; \\
               use {.code ci_method = \"montecarlo\"}."
        ))
      }
      numeric_unit_requested <- any(vapply(unit, is.numeric, logical(1)))
      if (numeric_unit_requested) {
        abort_unsupported(c(
          "{.code ci_method = \"npbootstrap\"} on an unbalanced one-way design \\
           supports {.code unit = \"single\"} (ICC(1)) and {.code \"average\"} \\
           (ICC(k)) only.",
          i = "A numeric {.arg unit} (D-study projection to {.var m} raters) is not \\
               yet available unbalanced -- its Spearman-Brown pole is not guaranteed \\
               interior when {.var m} exceeds the effective size; use \\
               {.code unit = \"average\"}, or {.code ci_method = \"montecarlo\"} for \\
               a projection."
        ))
      }
    }
  }

  # The modified-profile-likelihood interval (`ci_method = "mpl"`, xiao2013; M88,
  # D-014/D-015) is the OPPOSITE fence to the one-way methods above: defined only for
  # the balanced-complete two-way RANDOM absolute-agreement ICC(A,1)/ICC(A,k), and only
  # at the default 95% two-sided level its kappa_m table is calibrated for. Every other
  # cell aborts loudly (#5/#8) rather than returning an uncalibrated interval.
  if (ci_method == "mpl") {
    # mpl is an absolute-agreement method. `type` defaults to both agreement and
    # consistency; narrow an UNSET type to agreement (mpl selects the agreement
    # estimand as it selects the interval), but an EXPLICIT consistency request is a
    # genuine conflict -- mpl has no ICC(C,.) interval -- so abort (#5).
    if ("consistency" %in% type) {
      if (type_supplied) {
        abort_unsupported(c(
          "{.code ci_method = \"mpl\"} is an absolute-agreement interval; it does \\
           not define a consistency (ICC(C,.)) interval.",
          i = "Use {.code type = \"agreement\"}, or \\
               {.code ci_method = \"montecarlo\"} for consistency."
        ))
      }
      type <- "agreement"
    }
    if (oneway || multilevel || raters != "random") {
      abort_unsupported(c(
        "{.code ci_method = \"mpl\"} is available only for the two-way random \\
         absolute-agreement ICC(A,1)/ICC(A,k).",
        i = "It is the modified-profile-likelihood interval for the two-way random \\
             design; use {.code model = \"twoway\"}, {.code raters = \"random\"}, \\
             or {.code ci_method = \"montecarlo\"}."
      ))
    }
    if (!balanced) {
      abort_unsupported(c(
        "{.code ci_method = \"mpl\"} requires balanced, complete two-way data.",
        i = "The likelihood assumes every subject x rater cell is observed; use \\
             {.code ci_method = \"montecarlo\"}."
      ))
    }
    if (any(vapply(unit, is.numeric, logical(1)))) {
      abort_unsupported(c(
        "{.code ci_method = \"mpl\"} supports {.code unit = \"single\"} (ICC(A,1)) \\
         and {.code \"average\"} (ICC(A,k)) only.",
        i = "A numeric {.arg unit} (D-study projection) is not yet calibrated for \\
             {.val mpl}; use {.code unit = \"average\"} or \\
             {.code ci_method = \"montecarlo\"}."
      ))
    }
    if (!isTRUE(all.equal(conf_level, 0.95))) {
      abort_unsupported(c(
        "{.code ci_method = \"mpl\"} is calibrated at {.code conf_level = 0.95} only.",
        i = "The kappa_m table is generated for the 95% two-sided interval; for \\
             another level use {.code ci_method = \"montecarlo\"}."
      ))
    }
  }

  # Cluster-level fixed raters ship for balanced/complete CROSSED Design 1 only
  # (M37, ADR-047; glmmTMB/lme4). Incomplete/unbalanced cluster-level fixed is
  # deferred -- double-blocked: ten Hove et al. (2022) flag the small-k estimator as
  # open AND the averaged ICC(c,k) effective-rater divisor is unresolved on incomplete
  # data (M9 §9). Now that `balanced` is known, refuse an explicit ragged cluster
  # request; drop the default "cluster" to the shipped subject level (M18). Subject
  # level and every balanced path are unaffected; brms/nested were handled upstream.
  if (
    multilevel &&
      raters == "fixed" &&
      ml_design == "crossed" &&
      !balanced &&
      "cluster" %in% level
  ) {
    if (!("subject" %in% level)) {
      abort_unsupported(c(
        "Cluster-level fixed-rater ICCs need balanced, complete data.",
        i = "Incomplete/unbalanced cluster-level fixed-rater estimation is an open \\
             research question (ten Hove et al. 2022, p. 6) and is deferred to a \\
             later milestone.",
        i = "Use complete data, {.code level = \"subject\"}, or \\
             {.code raters = \"random\"}."
      ))
    }
    level <- "subject"
  }

  # lavaan (SEM) reshapes to a wide subject-by-rater matrix; incomplete data leaves
  # missing cells, which fit_lavaan() estimates by full-information maximum likelihood
  # (FIML, M21 Slice 3, ADR-031). Disconnected designs are still rejected by the
  # engine-agnostic connectedness guard below (shared with the mixed-model engines).

  # lavaan (SEM) multilevel scope (M54, D-005; M58): the crossed (Design 1)
  # RANDOM-rater fit ships both levels + the conflated diagnostic on complete/
  # balanced AND incomplete (two-level FIML) / unbalanced (unequal cluster sizes)
  # data (M58), via the two-level CFA parameterization the pilot established
  # numerically (cairn/references/sem-multilevel-pilot.md). FIXED raters (M57)
  # stay complete/balanced/equal-cluster-size. Loud classed deferrals (#5)
  # remain: nested designs (no two-level CFA mapping for nested raters),
  # within-cell replicates, and fixed incomplete/unbalanced (the balance guard
  # below). The tau^2 rater-inflation law generalizes to the harmonic mean of
  # per-cluster subject counts under imbalance -- see fit_lavaan_multilevel().
  if (engine == "lavaan" && multilevel) {
    if (ml_design != "crossed") {
      abort_unsupported(c(
        "The {.pkg lavaan} engine supports only the crossed (Design 1) \\
         multilevel design.",
        i = "With raters nested in clusters or subjects there is no two-level \\
             SEM parameterization of the decomposition yet; use \\
             {.code engine = \"glmmTMB\"} (default) or {.code \"lme4\"}."
      ))
    }
    # Fixed raters (M57): the crossed + balanced/complete + equal-cluster-size
    # cell is admitted -- it falls through to the fixed-multilevel dispatch below,
    # which routes to fit_lavaan_multilevel(raters = "fixed"). Fixed NESTED is
    # caught by the crossed guard above, fixed REPLICATES by the guard below, and
    # fixed INCOMPLETE/UNBALANCED by the balance guard below -- each pointing at
    # glmmTMB. So no separate fixed abort is needed here.
    if (replicates) {
      abort_unsupported(c(
        "The {.pkg lavaan} (SEM) engine does not support within-cell \\
         replicates.",
        i = "Use {.code engine = \"glmmTMB\"} (default) or {.code \"lme4\"}."
      ))
    }
    # `cluster_of` (subject x cluster incidence) is computed by the multilevel
    # identifiability block above; unequal colSums = unequal cluster sizes.
    # RANDOM raters (M58) now admit incomplete (two-level FIML) and unbalanced
    # (unequal cluster sizes) crossed data -- the pilot established both routes
    # numerically (cairn/references/sem-multilevel-pilot.md; D-005). Connectedness
    # and identifiability are gated by the engine-agnostic crossed-multilevel
    # block above, shared with the mixed engines; a between-level Heywood aborts
    # loudly from inside fit_lavaan_multilevel(). FIXED raters stay
    # complete/balanced/equal-cluster-size only: the incomplete/unbalanced fixed
    # subject level compounds FIML with the Case-3A correction and is a parked
    # candidate (no oracle in scope), so it is refused here toward glmmTMB.
    if (
      identical(raters, "fixed") &&
        (!balanced || length(unique(colSums(cluster_of))) != 1L)
    ) {
      abort_unsupported(c(
        "The {.pkg lavaan} multilevel engine needs complete, balanced data \\
         with equal cluster sizes for fixed raters.",
        i = "Incomplete or unbalanced fixed-rater multilevel SEM is planned for \\
             a later milestone; use {.code engine = \"glmmTMB\"} (default) or \\
             {.code \"lme4\"}."
      ))
    }
  }

  # Fixed-rater lme4 (M14 Slice 1 balanced; M15 Slice 2 incomplete, ADR-024) covers
  # the two-way fixed-rater design on both balanced and ragged data: fit_lme4_fixed()
  # fits `score ~ 1 + rater + (1 | subject)` (missing cells are fine for lme4) and the
  # theta^2_r-under-imbalance correction is the shared, engine-agnostic theta2r_fixed()
  # fed lme4's own incomplete-data vcov -- so no balance guard is needed here. A ragged
  # design that drives a variance component to the boundary aborts toward glmmTMB from
  # inside fit_lme4_fixed() (intraclass_singular_fit), the intended graceful degrade.

  # Multilevel lme4 (M14 balanced; M15 Slice 3 incomplete, ADR-024) covers every
  # multilevel design glmmTMB does. On incomplete data only the crossed (Design 1)
  # RANDOM shape reaches here: incomplete nested (Designs 2/3) and incomplete
  # fixed-rater crossed multilevel already aborted above, for EVERY engine (the M8/M10
  # deferrals), so no lme4-specific guard is needed. fit_lme4_multilevel() fits the
  # ragged five-component model and lme4_ml_contract() reads merDeriv's incomplete-data
  # vcov; a ragged fit that hits the variance boundary aborts toward glmmTMB from
  # inside lme4_ml_contract() (intraclass_singular_fit), the intended graceful degrade.

  # Multilevel data uses a Design-1 (crossed, five-component) or Design-2 (raters
  # nested in clusters, four-component) fit per the inferred design; otherwise
  # fixed raters get their own fixed-effect fit (Case 3/3A) and random raters the
  # shared random-effects fit. The rest of the pipeline is identical -- each engine
  # returns named `components` the estimand indexes by signal/error (M8 §2, M5
  # §2/§3; M3 §6, ADR-008).
  # `occasions = "average"` averages the within-cell replicates, so it needs
  # replicated data -- there is nothing to average with one rating per cell (#5/#8).
  if (!replicates && !identical(occasions, "single")) {
    abort_intraclass(c(
      "{.code occasions = \"average\"} requires within-cell replicates.",
      i = "Provide multiple ratings per subject-by-rater cell, or use \\
           {.code occasions = \"single\"} (the default)."
    ))
  }
  # Occasion-averaged coefficient on RAGGED replicates (M20 Slice 3, ADR-030): with
  # unequal per-cell rating counts, the reliability of the mean of `n_o` replicates has
  # no single scalar effective-n_o divisor (the GT averaging weights are per-cell) and
  # no textbook/independent oracle pins one -- so it is deferred to research rather than
  # shipped with a guessed divisor (#1/#4). The single-occasion family fits fine.
  if (ragged_replicates && !identical(occasions, "single")) {
    abort_unsupported(c(
      "{.code occasions = \"average\"} is not supported for ragged (unequal or \\
       incomplete) within-cell replicates yet.",
      i = "The effective number of occasions behind an unevenly-replicated cell mean \\
           is an open modeling question with no validated divisor.",
      i = "Use {.code occasions = \"single\"} on ragged data, or provide an equal \\
           number of ratings in every cell for the occasion-averaged coefficient."
    ))
  }

  # brms (Bayesian) engine data-dependent scope (ADR-033): the remaining deferred
  # Bayesian follow-ons -- incomplete/ragged within-cell replicates, incomplete fixed-NESTED
  # (no frequentist oracle, upstream), and numeric-unit (D-study) projection -- are refused
  # loudly here, now that balance/replication and the resolved unit are known (#5/#8).
  # Single-level fixed raters (Case-3A theta^2_r) ship on both balanced (M26 Slice 2) and
  # incomplete/ragged (M31 Slice 1, ADR-041) data; single-level one-way ships balanced
  # (M26 Slice 1) and incomplete/ragged (M33 Slice 1, ADR-043). A soft k = 2 note surfaces
  # ten Hove et al. (2020)'s bias/undercoverage caveat (#13).
  if (engine == "brms") {
    # Fixed-rater multilevel brms covers crossed (Design 1, M27 Slice 1) and nested
    # (Design 2, M27 Slice 2) at the subject level, balanced/complete. Of the remaining
    # fixed-multilevel cases: Design 3 fixed (no separable rater effect) is refused
    # engine-agnostically upstream; cluster-level fixed now SHIPS for glmmTMB/lme4 on
    # balanced crossed data (M37, ADR-047) but the brms sibling stays deferred -- refused
    # by the brms cluster-level fixed guard upstream (~L765). Incomplete fixed-NESTED
    # now ships for the mixed-model engines (M36, ADR-046) but stays deferred for brms; it
    # is refused by a brms-specific guard upstream (~L785). Incomplete crossed fixed
    # MULTILEVEL is caught by the `!balanced` brms guard below (M31 Slice 2). So no
    # brms-specific fixed guard is needed here.
    # Within-cell replicates ship for brms at the single level -- two-way random (M29 Slice 2)
    # and fixed-rater (M33 Slice 2) -- and at the MULTILEVEL level -- crossed Design 1
    # (six-component) + nested Design 2 (five-component), random raters (M33 Slice 3,
    # ADR-043; fit_brms_{ml,nested}_replicates). The still-deferred multilevel-replicate corners
    # (Design 3 by design, fixed-rater, conflated, and ragged multilevel replicates) are refused
    # ENGINE-AGNOSTICALLY upstream (~L807), so no brms-specific replicate guard is needed here.
    if (!balanced) {
      # M30 (ADR-040): incomplete/ragged RANDOM-rater fits ship -- two-way single level +
      # crossed (Design 1) multilevel. M31 (ADR-041): incomplete/ragged FIXED-rater fits ship
      # too -- SINGLE-LEVEL two-way (Slice 1, fit_brms_fixed) and CROSSED (Design 1) MULTILEVEL
      # subject level (Slice 2, fit_brms_multilevel_fixed). Both run unchanged on ragged data --
      # the k rater means (b_Intercept + treatment contrasts) feed brms_theta2r_draws(), which
      # reads theta^2_r per draw through the shipped 2b moment correction + boundary-aware
      # average-floor (ADR-037/038). That correction goes LIVE for the first time on ragged
      # fixed data: b = tr(C.Sigma_post)/(k - 1) != 0 once the rater means are estimated from
      # unequal cell counts (b ~= 0 on balanced data, where the means come from the whole
      # sample -- the M26/M27-S1 raw-push-forward regime). The M3 k_eff (harmonic-mean divisor),
      # single-level connectedness guard (~L887) and crossed-multilevel identifiability
      # gates (~L903) are engine-agnostic and run pre-dispatch, so they protect brms.
      # M47 (ADR-058): the averaged cluster-level ICC(c,k) on ragged data now ships for
      # brms too (the inverse-Simpson k_c^eff applied to the posterior draws' components,
      # a variance-ratio push-forward -- no theta^2, no 2b), so no engine special-case
      # remains; the incomplete FIXED cluster cell is still refused upstream (all engines).
      # M32 (ADR-042): incomplete/ragged NESTED RANDOM ships
      # too -- Design 2 (raters nested in clusters, Slice 1, fit_brms_nested_clusters) and Design 3
      # (raters nested in subjects, the multilevel one-way, Slice 2, fit_brms_nested_subjects).
      # Random raters make each ICC a ratio of variance components (no theta^2 functional), so this
      # is a clean posterior push-forward -- the M30 regime, NOT the M31 fixed regime: the 2b moment
      # correction never engages, and the shipped M25 nested fits run unchanged on ragged data,
      # protected by the same engine-agnostic pre-dispatch k_eff/connectedness above. M33 (ADR-043,
      # Slice 1): incomplete/ragged SINGLE-LEVEL ONE-WAY ships too -- fit_brms_oneway() (M26 Slice 1)
      # runs unchanged, the two-component score ~ 1 + (1 | subject) fit composing ICC(1)/ICC(1,k) as a
      # ratio of variance components (no theta^2 functional -- the M30 regime, no 2b) with the M3/M6
      # harmonic-mean k_eff divisor threaded pre-dispatch (design_info$k_eff, ~L1409). The one
      # still-deferred incomplete corner is refused with a case-naming message (#5/#8): within-cell
      # REPLICATES (the fixed/multilevel Bayesian replicate siblings ship balanced first, M33 Slices
      # 2/3; ragged replicates stay 🟣 research, ADR-030). (Incomplete fixed-NESTED now has a
      # frequentist oracle and ships for the mixed-model engines (M36, ADR-046), but the brms sibling
      # is deferred -- refused by a brms-specific guard upstream ~L785 -- so only random nested reaches
      # here.)
      if (replicates) {
        abort_unsupported(c(
          "The {.pkg brms} engine supports incomplete/ragged data only for the \\
           two-way single-level (random or fixed), single-level one-way, crossed \\
           (Design 1) multilevel (random or fixed), and nested Design 2/3 (random) \\
           designs so far.",
          i = "Incomplete Bayesian within-cell replicate ICCs are planned for a later \\
               milestone; use {.code engine = \"glmmTMB\"} (default) or {.code \"lme4\"} \\
               for incomplete data."
        ))
      }
    }
    if (any(vapply(unit, is.numeric, logical(1)))) {
      abort_unsupported(c(
        "Numeric {.arg unit} (a D-study projection) is not supported for the \\
         {.pkg brms} engine yet.",
        i = "Use {.val single} or {.val average}; Bayesian D-study projection is \\
             planned for a later milestone."
      ))
    }
    if (n_raters == 2L) {
      # The caveat applies to the one-way ICC(1) too (M26 S1): the O-Bayes-OW oracle found
      # the one-way MAP biased low at k = 2 (~-13% rel bias) by the SAME skewed small-sample
      # variance-ratio mechanism as the two-way ICC(A,1) -- so the note fires for every brms
      # k = 2 path, not just two-way (#18: the a-priori "one-way is spared" guess did not hold).
      cli::cli_inform(c(
        "!" = "With only {.val {2L}} raters (k = 2), the Bayesian ICC point and \\
               interval can be biased and undercover.",
        i = "ten Hove et al. (2020) found the MAP unbiased and the percentile \\
             credible interval nominal only at k > 2."
      ))
    }
  }

  engine_fit <- if (multilevel && replicates) {
    # Multilevel within-cell replicates (M20 Slice 2): add (1|cluster:subject:rater) to
    # the M5 crossed (Design 1, six-component) / M8 nested (Design 2, five-component)
    # fit, splitting the residual into the interaction and pure error. Design 3
    # (one-way), fixed raters, conflated, and ragged data are aborted upstream; random,
    # balanced/complete only.
    if (ml_design == "nested_in_clusters") {
      if (engine == "brms") {
        # Nested Design 2 replicates, Bayesian (M33 Slice 3, ADR-043): the M8
        # four-component fit + (1|cluster:subject:rater) split; random raters -> a
        # variance-ratio push-forward, no theta^2. Subject level only.
        fit_brms_nested_replicates(df, seed = seed, brm_args = brm_args)
      } else if (engine == "lme4") {
        fit_lme4_nested_replicates(df)
      } else {
        fit_glmmtmb_nested_replicates(df)
      }
    } else if (engine == "brms") {
      # Crossed Design 1 replicates, Bayesian (M33 Slice 3, ADR-043): the M5
      # five-component fit + (1|cluster:subject:rater) split (six components); random
      # raters -> a variance-ratio push-forward, no theta^2.
      fit_brms_ml_replicates(df, seed = seed, brm_args = brm_args)
    } else if (engine == "lme4") {
      fit_lme4_ml_replicates(df)
    } else {
      fit_glmmtmb_ml_replicates(df)
    }
  } else if (multilevel) {
    # lme4 (M14) mirrors every balanced multilevel glmmTMB fit; the guards above
    # confine the lme4 branches to the balanced/complete case.
    if (ml_design == "nested_in_clusters") {
      if (raters == "fixed") {
        # Design 2 with raters fixed -- theta^2_{r:c} (finite-population, averaged over
        # clusters) in the rater slot (M19 Slice 2). Balanced/complete only, guarded
        # above. Design 3 fixed aborted by design (no separable rater effect).
        if (engine == "brms") {
          # Design 2 fixed raters, Bayesian (M27 Slice 2, ADR-037): score ~ 0 + rater +
          # (1|cluster:subject) with theta^2_{r:c} read raw per posterior draw into the
          # rater `draws` row. Subject level only; MAP + percentile credible interval.
          fit_brms_nested_fixed(df, seed = seed, brm_args = brm_args)
        } else if (engine == "lme4") {
          fit_lme4_nested_fixed(df)
        } else {
          fit_glmmtmb_nested_fixed(df)
        }
      } else if (engine == "brms") {
        # Design 2 (raters nested in clusters), Bayesian (M25 Slice 1, ADR-035): the M8
        # four-component fit under the half-t(4, 0, 1) SD prior; the MAP point and the
        # percentile credible interval come from posterior_summary() off the `draws`
        # contract, exactly as the crossed Design-1 brms path. Nested Design 3, fixed,
        # conflated, incomplete, and replicate brms fits are refused upstream (#5).
        fit_brms_nested_clusters(df, seed = seed, brm_args = brm_args)
      } else if (engine == "lme4") {
        fit_lme4_nested_clusters(df)
      } else {
        fit_glmmtmb_nested_clusters(df)
      }
    } else if (ml_design == "nested_in_subjects") {
      if (engine == "brms") {
        # Design 3 (raters nested in subjects), Bayesian (M25 Slice 2, ADR-035): the M8
        # three-component multilevel one-way fit under the half-t(4, 0, 1) SD prior;
        # agreement-only (consistency aborted upstream). MAP + percentile credible interval
        # off the `draws` contract, as the other brms multilevel paths.
        fit_brms_nested_subjects(df, seed = seed, brm_args = brm_args)
      } else if (engine == "lme4") {
        fit_lme4_nested_subjects(df)
      } else {
        fit_glmmtmb_nested_subjects(df)
      }
    } else if (raters == "fixed") {
      # Crossed (Design 1) with raters as fixed effects -- theta^2_r in the rater
      # slot. Subject level (M10) and, on balanced data, the cluster level (M37,
      # ADR-047) both read off this one fit; the estimand map keys the cluster error
      # set {theta^2_r, sigma^2_cr} on `level`, not `raters`. Fixed-rater nested and
      # incomplete cluster-level are guarded above.
      if (engine == "brms") {
        # Crossed (Design 1) fixed raters, Bayesian (M27 Slice 1, ADR-037): the M10
        # five-component fit with a fixed `rater` effect under the half-t(4, 0, 1) SD
        # prior; theta^2_r read raw per posterior draw into the rater `draws` row. MAP +
        # percentile credible interval off the shared contract. Nested (Design 2) fixed
        # brms is refused upstream (M27 Slice 2 follow-on, #5).
        fit_brms_multilevel_fixed(df, seed = seed, brm_args = brm_args)
      } else if (engine == "lme4") {
        fit_lme4_multilevel_fixed(df)
      } else if (engine == "lavaan") {
        # Crossed (Design 1) fixed raters via the two-level SEM (M57): the same
        # two-level CFA as the random path, read with the Case-3A finite-population
        # correction on the between-level rater intercepts. Both levels + the
        # conflated diagnostic read off this one fit; complete/balanced, equal
        # cluster sizes only (fixed nested / replicate / incomplete aborted
        # upstream). MC-only -- the bootstrap factory is random-only (M56).
        fit_lavaan_multilevel(df, raters = "fixed")
      } else {
        fit_glmmtmb_multilevel_fixed(df)
      }
    } else if (engine == "brms") {
      # Crossed (Design 1) random raters, Bayesian (M24 Slice 1, ADR-034): the M5
      # five-component fit under the half-t(4, 0, 1) SD prior; the point (MAP) and the
      # percentile credible interval come from posterior_summary() off the `draws`
      # contract. Also serves the conflated diagnostic (M29 Slice 1, ADR-039): Eq. 14
      # composes off these same five components (signal cluster + subject, error rater +
      # cluster_rater + residual) per posterior draw. Nested, fixed, incomplete, and
      # replicate brms fits are refused upstream (#5).
      fit_brms_multilevel(df, seed = seed, brm_args = brm_args)
    } else if (engine == "lme4") {
      # Crossed (Design 1) random raters via lme4 (M14 Slice 2).
      fit_lme4_multilevel(df)
    } else if (engine == "lavaan") {
      # Crossed (Design 1) random raters via the two-level SEM (M54, D-005):
      # the five-component two-level CFA the pilot established. Complete/balanced,
      # incomplete (two-level FIML), or unbalanced (unequal cluster sizes) --
      # random raters only; fixed and nested aborted upstream. Serves both levels
      # + the conflated diagnostic off the same fit, as the mixed-model engines.
      fit_lavaan_multilevel(df)
    } else {
      fit_glmmtmb_multilevel(df)
    }
  } else if (oneway) {
    # One-way random (M6). brms (M26 Slice 1, ADR-036): the two-component
    # score ~ 1 + (1 | subject) fit under the half-t(4, 0, 1) SD prior; MAP + percentile
    # credible interval off the `draws` contract, as the other brms paths. Runs unchanged on
    # incomplete/ragged data (M33 Slice 1, ADR-043) -- the M3/M6 harmonic-mean k_eff divisor
    # threads pre-dispatch (design_info$k_eff), a variance-ratio push-forward (no theta^2, no
    # 2b -- the M30 regime). Fixed / numeric-unit brms one-way are refused upstream (#5).
    if (engine == "brms") {
      fit_brms_oneway(df, seed = seed, brm_args = brm_args)
    } else if (engine == "lme4") {
      fit_lme4_oneway(df)
    } else {
      fit_glmmtmb_oneway(df)
    }
  } else if (raters == "fixed") {
    if (replicates) {
      # Fixed-rater within-cell replicates (M20 Slice 1): the interaction fit with
      # raters fixed -- theta^2_r in the rater slot (fit_*_replicates_fixed). lavaan
      # replicates already aborted upstream; balanced/complete single-level only. brms
      # (M33 Slice 2, ADR-043) reads theta^2_r per posterior draw (2b ~ 0 on balanced
      # replicated data); the multilevel replicate corner is refused upstream.
      if (engine == "brms") {
        fit_brms_replicates_fixed(df, seed = seed, brm_args = brm_args)
      } else if (engine == "lme4") {
        fit_lme4_replicates_fixed(df)
      } else {
        fit_glmmtmb_replicates_fixed(df)
      }
    } else if (engine == "lme4") {
      fit_lme4_fixed(df)
    } else if (engine == "lavaan") {
      # Fixed-rater two-way SEM (M21 Slice 2, ADR-031): the same one-factor fit, with
      # the rater intercepts read as the Case-3A bias-corrected finite-population
      # theta^2_r instead of the raw random-rater sigma^2_r.
      fit_lavaan(df, raters = "fixed")
    } else if (engine == "brms") {
      # Fixed-rater two-way Bayesian (M26 Slice 2, ADR-036): score ~ 1 + rater +
      # (1 | subject) with raters as population-level fixed effects; theta^2_r (Case-3A
      # finite-population variance of the k rater means) is read PER POSTERIOR DRAW from the
      # rater fixed-effect draws, raw (no frequentist bias correction -- the posterior
      # integrates the parameter uncertainty the correction subtracts; oracle-pinned vs
      # glmmTMB fixed). MAP + percentile credible interval off the `draws` contract.
      fit_brms_fixed(df, seed = seed, brm_args = brm_args)
    } else {
      fit_glmmtmb_fixed(df)
    }
  } else if (replicates) {
    # Within-cell replicates (M17 Slice 3): the interaction fit (subject, rater,
    # subject_rater, residual). The SEM engine has no replicate path.
    if (engine == "lavaan") {
      abort_unsupported(c(
        "The {.pkg lavaan} (SEM) engine does not support within-cell replicates.",
        i = "Use {.code engine = \"glmmTMB\"} (default) or {.code \"lme4\"}."
      ))
    }
    if (engine == "lme4") {
      fit_lme4_replicates(df)
    } else if (engine == "brms") {
      # Two-way random replicates, Bayesian (M29 Slice 2, ADR-039): the same
      # interaction fit under the half-t(4, 0, 1) SD prior; the residual splits into
      # sigma^2_sr (subject:rater) and pure error, and `occasions` averaging divides
      # pure error by n_o PER DRAW (posterior_summary -> icc_point). Fixed / multilevel /
      # incomplete replicate brms are refused upstream (#5).
      fit_brms_replicates(df, seed = seed, brm_args = brm_args)
    } else {
      fit_glmmtmb_replicates(df)
    }
  } else if (engine == "lme4") {
    fit_lme4(df)
  } else if (engine == "lavaan") {
    fit_lavaan(df)
  } else if (engine == "brms") {
    fit_brms_twoway(df, seed = seed, brm_args = brm_args)
  } else {
    fit_glmmtmb(df)
  }
  # Averaging divisor: the effective number of ratings per subject (harmonic
  # mean), which is k on balanced data (ADR-008; M3 §5). "single" uses 1; a
  # numeric unit projects to that many raters. Resolved per estimand.
  k <- design_info$k_eff
  estimands <- if (multilevel && ml_design == "nested_in_subjects") {
    # Design 3 is the multilevel one-way (agreement-only): ICC(1)/ICC(k), signal
    # sigma^2_{s:c}, error the confounded residual (spec M8 §3b).
    lapply(unit, function(u) {
      icc_estimand(
        unit = u,
        k_eff = k,
        oneway = TRUE,
        multilevel = TRUE,
        level = "subject"
      )
    })
  } else if (multilevel) {
    # Cross-product type x level x unit (x occasions for replicates); type outer so
    # rows group by error definition (ADR-054 print grouping), then level (M5 §3). For
    # Design 2, `level` is already restricted to "subject" (nested designs). With
    # replicates the rater divisor counts DISTINCT raters (replicates must not inflate
    # it, M17 §4).
    k_ml <- if (replicates) design_info$k_eff_raters else k
    # Averaged cluster-level ICC(c,k) divisor under imbalance (M46, ADR-057): the
    # inverse-Simpson harmonic k_c^eff, the effective raters behind each cluster's
    # observed cell-pooled mean. Only the crossed design has a cluster level; on
    # balanced/complete data it equals the rater count k (so balanced numbers are
    # unchanged -- number-invariance). Fable-blessed as exact for both types (Am.1).
    k_c_eff <- if (ml_design == "crossed") cluster_k_eff(df) else NA_real_
    # The averaged cluster-level ICC(c,k) on incomplete data now ships for ALL
    # random-rater engines -- glmmTMB/lme4 (M46, ADR-057) AND brms (M47, ADR-058):
    # the inverse-Simpson k_c^eff is engine-agnostic (applied post-fit to the five
    # components / posterior draws), a variance-ratio push-forward validated against
    # the frequentist M46 oracle (O-Bayes-cluster-ck). No engine special-case remains
    # here; the incomplete FIXED cluster cell is still refused upstream (all engines,
    # the balance gate above), so this crossed random branch is safely engine-uniform.
    unlist(
      lapply(type, function(ty) {
        unlist(
          lapply(level, function(lv) {
            # The cluster level averages over raters with the per-cluster inverse-Simpson
            # divisor k_c^eff (M46); the subject level uses the per-subject k_eff (M9 §5).
            k_lv <- if (lv == "cluster") k_c_eff else k_ml
            units_lv <- agr_projection_units(unit, ty, raters)
            # Occasion averaging (M20 Slice 2) reduces only pure error, which is not in
            # the cluster-level error set, so it is a no-op there -- emit single-occasion
            # cluster rows only. Non-replicate paths carry a single "single" occasion.
            occs_lv <- if (replicates && lv == "subject") {
              occasions
            } else {
              "single"
            }
            unlist(
              lapply(units_lv, function(u) {
                lapply(occs_lv, function(o) {
                  icc_estimand(
                    type = ty,
                    unit = u,
                    raters = raters,
                    k_eff = k_lv,
                    level = lv,
                    multilevel = TRUE,
                    replicates = replicates,
                    occasions = o,
                    n_o = n_o_val
                  )
                })
              }),
              recursive = FALSE
            )
          }),
          recursive = FALSE
        )
      }),
      recursive = FALSE
    )
  } else if (oneway) {
    lapply(unit, function(u) icc_estimand(unit = u, k_eff = k, oneway = TRUE))
  } else if (replicates) {
    # Within-cell replicates (M17 Slice 3): cross type x unit x occasions (type outer
    # for print grouping, ADR-054). The rater divisor counts DISTINCT raters (replicates
    # must not inflate it, §4); `occasions` averages pure error over the n_o replicates.
    unlist(
      lapply(type, function(ty) {
        unlist(
          lapply(agr_projection_units(unit, ty, raters), function(u) {
            lapply(occasions, function(o) {
              icc_estimand(
                type = ty,
                unit = u,
                raters = raters,
                k_eff = design_info$k_eff_raters,
                replicates = TRUE,
                occasions = o,
                n_o = design_info$n_o
              )
            })
          }),
          recursive = FALSE
        )
      }),
      recursive = FALSE
    )
  } else {
    # Two-way single level: cross type x unit (type outer for print grouping, ADR-054).
    unlist(
      lapply(type, function(ty) {
        lapply(
          agr_projection_units(unit, ty, raters),
          function(u) {
            icc_estimand(type = ty, unit = u, raters = raters, k_eff = k)
          }
        )
      }),
      recursive = FALSE
    )
  }

  # Bayesian branch (ADR-033): the MAP point and the percentile credible interval come
  # from the SAME posterior draws, because the mode is not transform-invariant
  # (MAP(ICC) != icc_point(MAP components)) -- so the point is the mode of each
  # estimand's posterior ICC-draw vector, computed alongside its interval by
  # posterior_summary(). The other engines take the shared icc_point()/mc/bootstrap path
  # unchanged. `points` is extracted from the summary so the downstream `estimates`
  # frame is built identically for every method.
  if (ci_method == "posterior") {
    # `posterior_summary(...)` here is the internal reducer (function-call position); the
    # like-named `posterior_summary` variable is the validated user choice, passed as
    # `interval_type` (percentile vs HPDI, M34 Slice 2).
    intervals <- posterior_summary(
      engine_fit$draws,
      estimands,
      conf_level = conf_level,
      interval_type = posterior_summary
    )
    points <- vapply(intervals, `[[`, numeric(1), "point")
  } else {
    points <- vapply(
      estimands,
      function(e) icc_point(engine_fit$components, e),
      numeric(1)
    )
    intervals <- if (ci_method == "bootstrap") {
      bootstrap_ci(
        engine_fit,
        estimands,
        conf_level = conf_level,
        boot_samples = boot_samples,
        seed = seed
      )
    } else if (ci_method == "npbootstrap") {
      # Non-parametric transformed bootstrap-t: resamples the RAW one-way data
      # (not the fitted model), so it takes `df` rather than `engine_fit`. The
      # POINT stays the engine (REML) point computed above (BC5); only the
      # interval differs. Guarded to balanced one-way upstream.
      npbootstrap_ci(
        df,
        estimands,
        conf_level = conf_level,
        boot_samples = boot_samples,
        seed = seed
      )
    } else if (ci_method == "searle") {
      # Classical exact-F closed form on the RAW one-way data (M82/D-012); the
      # POINT stays the engine (REML) point above (BC5), only the interval
      # differs. Deterministic -- no draws/seed. Guarded to balanced one-way.
      searle_ci(df, estimands, conf_level = conf_level)
    } else if (ci_method == "burch") {
      # Classical Burch (2011) REML closed form on the RAW one-way data
      # (M82/D-012); same conventions as "searle" (engine point, deterministic).
      burch_ci(df, estimands, conf_level = conf_level)
    } else if (ci_method == "mpl") {
      # Modified profile likelihood on the RAW two-way data (xiao2013; M88,
      # D-014/D-015); the POINT stays the engine (REML) point above (BC5), only the
      # interval differs. Deterministic -- kappa_m looked up, no draws. Guarded to the
      # balanced two-way random absolute-agreement cell + conf_level 0.95 upstream.
      mpl_ci(df, estimands, conf_level = conf_level)
    } else {
      mc_ci(
        engine_fit,
        estimands,
        conf_level = conf_level,
        mc_samples = mc_samples,
        seed = seed
      )
    }
  }
  # icc_point is signal / (signal + error); it is NaN only when the signal AND
  # every error component are estimated at exactly zero (a degenerate boundary with
  # no variance anywhere), which glmmTMB can hit on pathological data. Report it
  # loudly rather than return a silent NaN estimate (PRINCIPLES.md #5).
  if (anyNA(points)) {
    abort_unidentified(c(
      "The ICC is undefined: the signal and every error variance component were \\
       estimated at exactly zero.",
      i = "This degenerate boundary (no between- or within-group variance) leaves \\
           the variance ratio 0/0; inspect the data or the fitted model."
    ))
  }
  # A bootstrap fit carries its kept resample components so d_study() can project a
  # bootstrap band by reprojecting each resample across `m` (M18 Slice 4, ADR-028).
  # NULL for a Monte-Carlo fit, which reprojects from `mc` (vcov) instead.
  boot_components <- attr(intervals, "components")

  estimates <- data.frame(
    index = vapply(estimands, `[[`, character(1), "label"),
    type = vapply(estimands, `[[`, character(1), "type"),
    level = vapply(estimands, `[[`, character(1), "level"),
    sf_index = vapply(estimands, `[[`, character(1), "sf_label"),
    estimate = points,
    std.error = vapply(intervals, `[[`, numeric(1), "std.error"),
    conf.low = vapply(intervals, `[[`, numeric(1), "conf.low"),
    conf.high = vapply(intervals, `[[`, numeric(1), "conf.high"),
    stringsAsFactors = FALSE
  )
  # Within-cell replicates add an `occasions` column (the n_o behind each row),
  # disambiguating the shared index label as the multilevel `level` column does.
  if (replicates) {
    estimates$occasions <- vapply(estimands, `[[`, numeric(1), "occasions")
  }

  structure(
    list(
      estimates = estimates,
      components = engine_fit$components,
      design = list(
        model = model,
        type = if (oneway) NA_character_ else type,
        raters = raters,
        balanced = balanced,
        multilevel = multilevel,
        ml_design = if (multilevel) ml_design else NA_character_,
        levels = if (multilevel) level else NULL,
        replicates = replicates,
        n_o = if (replicates) design_info$n_o else NA_integer_
      ),
      # The replicate path averages over distinct raters (k_eff_raters), not total
      # ratings, so report that divisor (estimand-spec M17-within-cell-replicates §4).
      k_eff = if (replicates) design_info$k_eff_raters else design_info$k_eff,
      # Cluster-level averaging divisor (inverse-Simpson harmonic; M46, ADR-057) --
      # NA unless a crossed multilevel design with a cluster level was reported.
      k_c_eff = if (
        multilevel && ml_design == "crossed" && "cluster" %in% level
      ) {
        cluster_k_eff(df)
      } else {
        NA_real_
      },
      engine = engine_fit$engine,
      ci = list(
        method = ci_method,
        conf_level = conf_level,
        # `samples` is the number of draws behind the reported interval: MC draws for
        # "montecarlo", refits for "bootstrap" (ADR-025), subject resamples for
        # "npbootstrap" (M75), post-warmup posterior draws for "posterior" (ADR-033).
        # The classical closed forms ("searle"/"burch", M82) are deterministic --
        # no draws -- so `samples` is NA.
        samples = if (ci_method %in% c("bootstrap", "npbootstrap")) {
          boot_samples
        } else if (ci_method == "posterior") {
          ncol(engine_fit$draws)
        } else if (ci_method %in% c("searle", "burch", "mpl")) {
          NA_integer_
        } else {
          mc_samples
        },
        seed = seed,
        # How the posterior draws were summarized into the credible interval
        # ("percentile" or "hpdi", M34 Slice 2); NA for the non-Bayesian methods, which
        # do not produce a posterior. Surfaced in the printed header + glance().
        posterior_summary = if (ci_method == "posterior") {
          posterior_summary
        } else {
          NA_character_
        },
        # Bayesian MCMC convergence diagnostics (brms only; NULL for the other engines,
        # which are not sampled) -- read by the O-Bayes oracle and available to users.
        rhat = engine_fit$convergence$rhat,
        ess_bulk = engine_fit$convergence$ess_bulk
      ),
      n = list(
        subjects = n_subjects,
        raters = n_raters,
        clusters = n_clusters,
        obs = nrow(df),
        cells = design_info$n_cells
      ),
      fit = engine_fit$fit,
      # Everything a downstream D-study projection needs to reuse this fit with
      # no refit: the fitted parameters, their joint covariance, and the map back
      # to variance components, all on the engine's internal scale (ROADMAP;
      # d_study()). Kept alongside `fit` rather than recomputed from it.
      mc = list(
        estimate = engine_fit$estimate,
        vcov = engine_fit$vcov,
        to_components = engine_fit$to_components
      ),
      # Bootstrap resample components (named list of per-resample vectors) for a
      # bootstrap fit; NULL otherwise. d_study() reprojects these across `m` to
      # produce a bootstrap band coherent with the fit's interval (M18 Slice 4).
      boot = if (is.null(boot_components)) {
        NULL
      } else {
        list(components = boot_components)
      },
      call = match.call()
    ),
    class = "icc"
  )
}

# Validate a scalar argument against the single currently-supported value, with a
# teaching message for the not-yet-implemented alternatives (PRINCIPLES.md #5).
require_supported <- function(
  value,
  supported,
  arg,
  planned,
  call = rlang::caller_env()
) {
  if (length(value) != 1L || !identical(as.character(value), supported)) {
    abort_unsupported(
      c(
        "{.arg {arg}} must be {.val {supported}} in this release.",
        i = "Support for {planned} is planned for a later milestone.",
        x = "You supplied {.val {value}}."
      ),
      call = call
    )
  }
  value
}

# Match a scalar argument against its supported set, raising a classed intraclass
# error (PRINCIPLES.md #8) rather than rlang::arg_match's un-classed one. Accepts
# the default vector (takes the first element) or a single supplied value.
validate_choice <- function(value, choices, arg, call = rlang::caller_env()) {
  if (identical(value, choices)) {
    return(choices[[1L]])
  }
  if (!is.character(value) || length(value) != 1L || !value %in% choices) {
    abort_intraclass(
      "{.arg {arg}} must be one of {.val {choices}}.",
      call = call
    )
  }
  value
}

# Validate a resample count (`mc_samples` or `boot_samples`): a single whole number
# >= 2. Left unvalidated, a 0 yields a silent all-NA interval, a 1 a zero-width
# interval with NA std.error, and a fractional value silently recycles the draw
# matrix -- all violating fail-loudly (PRINCIPLES.md #5) and the classed-error
# contract (#8). The floor of 2 is the minimum for which a two-sided quantile and a
# standard deviation are defined (a meaningful interval needs far more; the defaults
# are 10000 Monte-Carlo draws / 999 bootstrap resamples).
validate_sample_count <- function(
  value,
  arg = "mc_samples",
  call = rlang::caller_env()
) {
  if (
    !is.numeric(value) ||
      length(value) != 1L ||
      !is.finite(value) ||
      value < 2 ||
      value != round(value)
  ) {
    abort_intraclass(
      c(
        "{.arg {arg}} must be a single whole number >= 2.",
        x = "Supplied: {.val {value}}."
      ),
      call = call
    )
  }
  as.integer(value)
}

# Validate `seed`: NULL (use the ambient RNG) or a single whole number. Left
# unvalidated, a non-integer or string seed throws a bare base-R error from
# set.seed() rather than a classed intraclass condition (PRINCIPLES.md #8).
validate_seed <- function(seed, call = rlang::caller_env()) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      !is.finite(seed) ||
      seed != round(seed)
  ) {
    abort_intraclass(
      c(
        "{.arg seed} must be {.code NULL} or a single whole number.",
        x = "Supplied: {.val {seed}}."
      ),
      call = call
    )
  }
  as.integer(seed)
}

# Validate the `occasions` averaging argument (within-cell replicates, M17 Slice 3):
# one or both of {"single", "average"}. "average" (mean of the within-cell
# replicates) is honoured only on replicated data; the guard for that lives in
# icc() where the design is known. Returns the requested occasions, de-duplicated.
validate_occasions <- function(occasions, call = rlang::caller_env()) {
  choices <- c("single", "average")
  if (
    !is.character(occasions) ||
      length(occasions) < 1L ||
      !all(occasions %in% choices)
  ) {
    abort_intraclass(
      "{.arg occasions} must be one or both of {.val {choices}}.",
      call = call
    )
  }
  unique(occasions)
}

# Validate the `type` (error-definition) argument. Vectorizable exactly like `unit`
# and `level` (ADR-054): one or both of {"agreement", "consistency"}, defaulting to
# both, so a default two-way call reports all four formulations (A1/Ak/C1/Ck) from
# one fit. `type` never reaches an engine -- agreement vs. consistency is post-fit
# arithmetic on the same variance components (McGraw & Wong 1996) -- so the second
# type costs a microsecond atop a fit that may take minutes (brms). Returns the
# requested types, de-duplicated, preserving the requested order. `length(type)`
# drives the drop-vs-abort policy in icc(): a single named type aborts on an
# undefined cell (#5), a multi-type request drops it with a cli_inform (ADR-029).
validate_type <- function(type, call = rlang::caller_env()) {
  choices <- c("agreement", "consistency")
  if (!is.character(type) || length(type) < 1L || !all(type %in% choices)) {
    abort_intraclass(
      "{.arg type} must be one or both of {.val {choices}}.",
      call = call
    )
  }
  unique(type)
}

# The units for which error definition `ty` is defined in the estimand cross-product:
# fixed-rater absolute agreement cannot be projected to a numeric (D-study) rater
# count (theta^2_r is the finite-population variance of the observed raters, M4.5), so
# a fixed-rater agreement cell drops numeric units. Consistency and random-rater
# agreement keep every unit. (The user was informed of any such drop in icc().)
agr_projection_units <- function(units, ty, raters) {
  if (ty == "agreement" && raters == "fixed") {
    Filter(function(u) !is.numeric(u), units)
  } else {
    units
  }
}

# Validate the multilevel `level` argument: the default (both correct levels) or a
# subset of {"subject", "cluster"} (M5), optionally with "conflated" -- the biased
# ignore-clusters diagnostic (Eq. 14, M17). Returns the requested levels,
# de-duplicated, preserving the requested order.
validate_levels <- function(level, call = rlang::caller_env()) {
  choices <- c("subject", "cluster", "conflated")
  if (!is.character(level) || length(level) < 1L || !all(level %in% choices)) {
    abort_intraclass(
      "{.arg level} must be one or more of {.val {choices}}.",
      call = call
    )
  }
  unique(level)
}

# Validate the optional multilevel `design` declaration (estimand-spec M9 §4a). The
# default `NULL` means "infer from the crossing pattern" (M8 behaviour); a non-NULL
# value asserts the design when missing cells make the pattern ambiguous between
# crossed and nested. Accepts the vocabulary of detect_multilevel_design().
validate_design <- function(design, call = rlang::caller_env()) {
  if (is.null(design)) {
    return(NULL)
  }
  choices <- c("crossed", "nested_in_clusters", "nested_in_subjects")
  if (!is.character(design) || length(design) != 1L || !design %in% choices) {
    abort_intraclass(
      c(
        "{.arg design} must be {.code NULL} (infer) or one of {.val {choices}}.",
        i = "Declare {.arg design} only to resolve a ragged pattern that is \\
             ambiguous between a crossed and a nested design (spec M9)."
      ),
      call = call
    )
  }
  design
}

# `unit` selects the averaging divisor: the keywords "single" (-> ICC(*,1)) and
# "average" (-> ICC(*,k)), or a number `m` >= 1 for a D-study projection to the
# mean of `m` raters (-> ICC(*,m); ROADMAP, M4.5 spec). Because c("single", 3)
# coerces to character in R, numeric projections may arrive as strings ("3");
# each element is normalized to "single"/"average" or a numeric. Returns a list
# (elements are mixed character/numeric), de-duplicated with order preserved.
validate_unit <- function(unit, call = rlang::caller_env()) {
  if (length(unit) < 1L) {
    abort_intraclass(
      "{.arg unit} must name at least one averaging unit.",
      call = call
    )
  }
  unique(lapply(unit, normalize_unit, call = call))
}

normalize_unit <- function(u, call = rlang::caller_env()) {
  if (is.character(u) && length(u) == 1L && u %in% c("single", "average")) {
    return(u)
  }
  num <- suppressWarnings(as.numeric(u))
  if (length(num) == 1L && is.finite(num) && num >= 1) {
    return(num)
  }
  abort_intraclass(
    c(
      "{.arg unit} must be {.val single}, {.val average}, or a number \\
       {.val {'>= 1'}} (a D-study projection to the mean of that many raters).",
      x = "You supplied {.val {u}}."
    ),
    call = call
  )
}

# A D-study projection of ABSOLUTE agreement to a rater count other than the
# design's own is ill-posed for FIXED raters: theta^2_r is the finite-population
# variance of exactly the observed raters, so there is no "average of m freshly
# sampled raters" to project to (PRINCIPLES.md #5; M4.5 spec). Consistency (the
# rater term drops out) and random-rater agreement project freely.
abort_fixed_agr_projection <- function(
  type,
  raters,
  call = rlang::caller_env()
) {
  if (raters == "fixed" && type == "agreement") {
    abort_unidentified(
      c(
        "Projecting absolute agreement to a different number of raters is not \\
         defined for {.val fixed} raters.",
        i = "With fixed raters the rater term is the finite-population variance \\
             of exactly the raters you observed, so there is no 'average of m \\
             freshly sampled raters' to project to.",
        i = "Use {.code raters = \"random\"} to project absolute agreement, or \\
             {.code type = \"consistency\"} for a fixed-rater D-study."
      ),
      call = call
    )
  }
}
