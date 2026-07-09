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
#' within-cluster subject variance are both counted as signal, and all three
#' rater-related terms as error. It is offered only as a **diagnostic contrast** --
#' to quantify how much the nesting distorts reliability -- and is never a
#' recommended coefficient; `print()` flags it as such. It is absolute-agreement
#' only (Eq. 14 has no consistency form) and needs a crossed (Design 1) random-rater
#' design; it works on both balanced and **incomplete** data (on ragged data it is the
#' flat two-way ICC read off the multilevel fit, with the same `k_eff` divisor).
#' Request it alongside the correct levels, e.g.
#' `level = c("subject", "cluster", "conflated")`.
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
#' reported as the single-rater `ICC(c,1)` (when raters bridge clusters); the averaged
#' cluster-level `ICC(c,k)` on incomplete data is not yet supported (its effective
#' number of raters per cluster is still being validated). If an averaged unit is
#' requested for the cluster level on incomplete data, that row is dropped (with a
#' message) rather than failing the whole call, so the subject-level averages and the
#' single-rater cluster ICC are still returned. **Fixed raters**
#' (`raters = "fixed"`) are supported for the crossed design at the **subject** level
#' on both balanced and **incomplete** data: the rater main effect becomes the
#' finite-population variance of the observed raters (McGraw & Wong Case 3A), so on
#' balanced data consistency is identical to the random-rater case and absolute
#' agreement differs only by that term; on incomplete data both types differ from
#' random (the finite-population variance is read from the ragged rater-contrast fit).
#' Incomplete *nested* designs, nested fixed-rater designs, and the fixed-rater cluster
#' level remain for later milestones. Nested designs still require balanced, complete
#' data.
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
#' @param type Error definition (two-way only): `"agreement"` (absolute agreement,
#'   the default) counts systematic rater differences as error; `"consistency"`
#'   ignores them. Not applicable when `model = "oneway"`.
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
#'   incomplete SEM). `"brms"` fits the **random**-rater model in a Bayesian
#'   framework (Stan, via \pkg{brms}) under a sourced half-*t*(4, 0, 1) prior on the
#'   random-effect SDs (ten Hove et al. 2020); the point estimate is the posterior
#'   mode (MAP) and the interval is a percentile **credible** interval
#'   (`ci_method = "posterior"`, forced). It covers the balanced, complete two-way
#'   random design, the crossed (Design 1) **multilevel** random design (subject and
#'   cluster levels), and the nested Design 2 (raters nested in clusters) multilevel
#'   random design (subject level); fixed raters, one-way, nested Design 3,
#'   incomplete multilevel, and within-cell-replicate Bayesian fits are planned for later
#'   milestones. `"lme4"` requires the
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
#'   two-way design, the `"lavaan"` engine (which simulates from the fitted SEM's
#'   implied moments and refits). As with the Monte-Carlo interval, the `"lme4"`
#'   engine defers a singular (boundary) fit to `"glmmTMB"` for either method.
#'   `"posterior"` is the percentile **credible** interval from the Bayesian
#'   engine's posterior draws; it is the forced default for, and available only with,
#'   `engine = "brms"` (and `"brms"` requires it) -- the other methods do not apply
#'   to a Bayesian fit, and `"posterior"` needs posterior draws no other engine
#'   produces.
#' @param mc_samples Number of Monte-Carlo draws for `ci_method = "montecarlo"`
#'   (default `10000`).
#' @param boot_samples Number of resamples for `ci_method = "bootstrap"` (default
#'   `999`). Ignored when `ci_method = "montecarlo"`.
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
#'   are owned by `intraclass` and may not be set here; supplying them, or a
#'   non-empty `brm_args` with any other engine, is an error.
#'
#' @return An `icc` object: a list with the estimate table, variance components,
#'   design, engine, interval settings, sample sizes, the fitted model, and the
#'   call. Use [tidy()][generics::tidy], [glance()][generics::glance], and the
#'   `print`/`summary` methods.
#'
#' @references
#' McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
#' correlation coefficients. *Psychological Methods, 1*(1), 30-46.
#'
#' Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
#' assessing rater reliability. *Psychological Bulletin, 86*(2), 420-428.
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
  brm_args = list()
) {
  if (!is.data.frame(data)) {
    abort_intraclass("{.arg data} must be a data frame.")
  }

  # Capture whether the caller left `ci_method` at its default BEFORE validate_choice
  # reassigns it, so the Bayesian forced-default coupling can tell an unset `ci_method`
  # (auto-upgrade to "posterior" for a brms fit) from an explicit mismatch (abort).
  ci_method_default <- missing(ci_method)

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
    c("montecarlo", "bootstrap", "posterior"),
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
           knobs (e.g. {.code backend}, {.code chains}, {.code iter}, {.code cores})."
    ))
  }

  type <- validate_choice(type, c("agreement", "consistency"), "type")
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
  # theta^2_r) and the parametric bootstrap. One-way, multilevel, and incomplete SEM
  # stay deferred (recorded, not rediscovered); route them to a loud abort rather
  # than a silent glmmTMB fallback (PRINCIPLES.md #5). The incomplete-data guard
  # needs the design summary and lives further down.
  if (engine == "lavaan" && (multilevel || oneway)) {
    design <- if (multilevel) "multilevel" else "one-way"
    abort_unsupported(c(
      "The {.pkg lavaan} engine supports only the two-way design so far.",
      i = "{.code engine = \"lavaan\"} is not available for {design} designs; \\
           use {.code engine = \"glmmTMB\"}.",
      i = "SEM for one-way and multilevel designs is planned for a later milestone."
    ))
  }

  # The brms (Bayesian) engine covers the two-way random path (M23, ADR-033) and the
  # crossed (Design 1) multilevel random path (M24, ADR-034), balanced/complete, single
  # replicate. One-way, nested multilevel, fixed-rater, incomplete, within-cell-replicate,
  # and D-study Bayesian fits are deferred follow-ons (recorded, not rediscovered); route
  # each to a loud, teaching abort rather than a silent glmmTMB fallback (#5). ONE-WAY is
  # the only structural refusal knowable here (before `ml_design`); the crossed-only
  # multilevel + conflated refusals are raised once `ml_design` is resolved (below), and
  # the data-dependent ones (fixed, incomplete, replicates, numeric unit) further down.
  if (engine == "brms" && oneway) {
    abort_unsupported(c(
      "The {.pkg brms} engine does not support one-way designs yet.",
      i = "{.code engine = \"brms\"} covers the two-way random and crossed multilevel \\
           designs; use {.code engine = \"glmmTMB\"} for one-way.",
      i = "Bayesian one-way ICCs are planned for a later milestone."
    ))
  }

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

  # A numeric unit is a D-study projection; guard the one ill-posed combination
  # (fixed raters + absolute agreement) before fitting (PRINCIPLES.md #5).
  if (any(vapply(unit, is.numeric, logical(1)))) {
    abort_fixed_agr_projection(type, raters)
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

  # brms (Bayesian) multilevel scope (M24 crossed, ADR-034; M25 Slice 1 nested Design 2,
  # ADR-035): the crossed (Design 1) five-component fit (subject + cluster levels) and the
  # nested Design 2 four-component fit (subject level) -- agreement/consistency, random,
  # balanced/complete. Nested Design 3 (M25 Slice 2) and the conflated diagnostic are the
  # remaining deferred Bayesian multilevel follow-ons -- refuse loudly now that `ml_design`
  # is resolved, BEFORE the generic conflated/nested guards below would emit a non-brms
  # message (#5/#8). Fixed / incomplete / replicate / numeric unit brms are refused with the
  # rest of the brms deferrals further down.
  if (engine == "brms" && multilevel) {
    if (ml_design == "nested_in_subjects") {
      abort_unsupported(c(
        "The {.pkg brms} engine does not support Design 3 (raters nested in \\
         subjects) yet.",
        i = "Bayesian nested Design 3 is a planned follow-on (its own thin slice); \\
             use {.code engine = \"glmmTMB\"} for it.",
        i = "Designs 1 (crossed) and 2 (raters nested in clusters) are supported."
      ))
    }
    if ("conflated" %in% level) {
      abort_unsupported(c(
        "The {.pkg brms} engine does not support the conflated ICC yet.",
        i = "The Bayesian conflated diagnostic is a planned follow-on; use \\
             {.code engine = \"glmmTMB\"}.",
        i = "Use {.code level = \"subject\"} or {.code \"cluster\"}."
      ))
    }
  }

  # Conflated single-level ICC (Eq. 14, M17 Slice 1): the biased ignore-clusters
  # coefficient off the crossed five-component fit. Agreement-only, random raters,
  # crossed Design 1 (estimand-spec M17-conflated-icc.md §3). These checks run
  # before the fixed/nested guards below (which drop non-subject levels) so an
  # explicit `level = "conflated"` gets a conflated-specific message, not a
  # cluster-level one. The complete-data restriction lives with the crossed
  # incomplete guards further down.
  if (multilevel && "conflated" %in% level) {
    if (type == "consistency") {
      abort_unsupported(c(
        "A consistency conflated ICC is not available.",
        i = "ten Hove et al. (2022) Eq. 14 is the absolute-agreement conflated \\
             ICC; a consistency form is not sourced (see the ROADMAP).",
        i = "Use {.code type = \"agreement\"} with {.code level = \"conflated\"}."
      ))
    }
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
    # Design 2 (raters nested in clusters) with fixed raters ships in M19 Slice 2:
    # theta^2_{r:c} (finite-population, averaged over clusters) replaces the random
    # sigma^2_{r:c} in the subject-level rater slot. Balanced/complete only -- the
    # incomplete fixed-nested corner (k_eff x per-cluster theta^2 interaction) is
    # deferred (ADR-029); guarded with the other fixed-nested checks below.
    if (!("subject" %in% level)) {
      abort_unsupported(c(
        "Fixed-rater multilevel ICCs are available at the subject level only.",
        i = "The cluster-level fixed-rater estimand is planned for a later \\
             milestone.",
        i = "Use {.code level = \"subject\"} with {.code raters = \"fixed\"}."
      ))
    }
    # The default `level` includes "cluster", whose fixed-rater estimand is
    # deferred; drop it and report the subject level so the natural call
    # `icc(..., raters = "fixed")` works (mirrors the nested-design branch below,
    # which drops "cluster" the same way). An explicit cluster-only request
    # aborted just above.
    level <- "subject"
    # Fixed-rater Design 2 (nested) is balanced/complete only this slice: the
    # incomplete case pairs the M3 k_eff divisor with the per-cluster theta^2_{r:c}
    # bias correction under imbalance -- two interacting corrections needing their own
    # oracle (as M10 was to M9). Defer loudly rather than use an unvalidated divisor
    # (#5; ADR-029 -- "balanced first"). Random-rater incomplete nested (Slice 1) is
    # unaffected; the crossed fixed incomplete path (M18 Slice 1) still applies.
    if (
      ml_design == "nested_in_clusters" &&
        !nested_design_balanced(df, ml_design)
    ) {
      abort_unsupported(c(
        "Incomplete fixed-rater nested multilevel designs are not supported yet.",
        i = "This slice ships balanced, complete fixed-rater nested (Design 2) data; \\
             the incomplete case is planned for a later milestone.",
        i = "Use {.code raters = \"random\"} for incomplete nested data, or provide \\
             a balanced design."
      ))
    }
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
    if (ml_design == "nested_in_subjects" && type == "consistency") {
      abort_unsupported(c(
        "Consistency is not defined when raters are nested within subjects.",
        i = "With each subject rated by its own raters (Design 3) the rater main \\
             effect cannot be separated, so only absolute agreement is defined \\
             (ten Hove et al. 2022, p. 6).",
        i = "Use the default {.code type = \"agreement\"}."
      ))
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
      if (type == "agreement" && !ident$cluster_rater_connected) {
        abort_unidentified(c(
          "Raters do not bridge clusters, so the rater main-effect variance cannot \\
           be separated from the cluster-by-rater variance for absolute agreement.",
          i = "This design is effectively rater-nested (Design 2) for agreement.",
          i = "Use {.code type = \"consistency\"}, or provide raters crossed across \\
               clusters."
        ))
      }
      # Cluster-level IRR on incomplete data (M9 Slice 2, ADR-018). The cluster-level
      # error carries sigma^2_cr (both types) and sigma^2_r (agreement), which are
      # identified only when raters bridge clusters; otherwise report just the subject
      # level (M5 §7 posture). The averaging divisor ICC(c,k) under imbalance is a
      # separate modeling question with no textbook oracle -- the effective number of
      # raters behind a ragged cluster mean is per-cluster, not the per-subject k_eff
      # -- so only the single-rater ICC(c,1) is offered on incomplete data here (#1).
      if ("cluster" %in% level) {
        if (!ident$cluster_rater_connected) {
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
        is_single <- vapply(unit, identical, logical(1), "single")
        # Averaged cluster-level ICC(c,k) under imbalance is unsupported, but the
        # single-rater ICC(c,1) and the subject-level rows are well-defined. Rather
        # than reject the whole call (an all-or-nothing refusal when a partial
        # result is available), drop only the averaged cluster rows below (grid
        # build) and note it once. Abort only when nothing is computable: the
        # cluster level is the sole level requested AND no single unit was asked for.
        if (!all(is_single)) {
          if (!("subject" %in% level) && !any(is_single)) {
            abort_unsupported(c(
              "Averaged cluster-level ICCs (ICC(c,k)) on incomplete data are not \\
               supported yet.",
              i = "The effective number of raters behind a ragged cluster mean is \\
                   a modeling choice still being validated; on incomplete data \\
                   only the single-rater {.code unit = \"single\"} cluster ICC is \\
                   available.",
              i = "Use {.code unit = \"single\"} for the cluster level, or \\
                   {.code level = \"subject\"} for the average."
            ))
          }
          cli::cli_inform(
            c(
              i = "Averaged cluster-level ICCs (ICC(c,k)) are not available on \\
                   incomplete data; reporting the single-rater cluster ICC(c,1) \\
                   only. Subject-level averages are unaffected.",
              i = "The effective rater count behind a ragged cluster mean is a \\
                   modeling choice still being validated."
            ),
            .frequency = "once",
            .frequency_id = "intraclass_icc_ck_incomplete"
          )
        }
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

  # lavaan (SEM) reshapes to a wide subject-by-rater matrix; incomplete data leaves
  # missing cells, which fit_lavaan() estimates by full-information maximum likelihood
  # (FIML, M21 Slice 3, ADR-031). Disconnected designs are still rejected by the
  # engine-agnostic connectedness guard below (shared with the mixed-model engines).

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

  # brms (Bayesian) engine data-dependent scope (ADR-033): fixed raters (Case-3A
  # theta^2_r), incomplete/ragged data, within-cell replicates, and numeric-unit
  # (D-study) projection are deferred Bayesian follow-ons. Refuse loudly here, now that
  # balance/replication and the resolved unit are known (#5/#8). A soft k = 2 note
  # surfaces ten Hove et al. (2020)'s bias/undercoverage caveat (#13).
  if (engine == "brms") {
    if (raters == "fixed") {
      abort_unsupported(c(
        "The {.pkg brms} engine supports only random raters so far.",
        i = "Bayesian fixed-rater (finite-population) ICCs are planned for a later \\
             milestone; use {.code engine = \"glmmTMB\"} for fixed raters.",
        i = "Use {.code raters = \"random\"}."
      ))
    }
    if (replicates) {
      abort_unsupported(c(
        "The {.pkg brms} engine does not support within-cell replicates yet.",
        i = "Use {.code engine = \"glmmTMB\"} (default) or {.code \"lme4\"} for \\
             replicated data."
      ))
    }
    if (!balanced) {
      abort_unsupported(c(
        "The {.pkg brms} engine supports only balanced, complete data so far.",
        i = "Bayesian incomplete/ragged ICCs are planned for a later milestone; use \\
             {.code engine = \"glmmTMB\"} for incomplete data."
      ))
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
      if (engine == "lme4") {
        fit_lme4_nested_replicates(df)
      } else {
        fit_glmmtmb_nested_replicates(df)
      }
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
        if (engine == "lme4") {
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
      if (engine == "lme4") {
        fit_lme4_nested_subjects(df)
      } else {
        fit_glmmtmb_nested_subjects(df)
      }
    } else if (raters == "fixed") {
      # Crossed (Design 1) with raters as fixed effects -- theta^2_r in the rater
      # slot (M10). Fixed-rater nested/incomplete/cluster-level are guarded above.
      if (engine == "lme4") {
        fit_lme4_multilevel_fixed(df)
      } else {
        fit_glmmtmb_multilevel_fixed(df)
      }
    } else if (engine == "brms") {
      # Crossed (Design 1) random raters, Bayesian (M24 Slice 1, ADR-034): the M5
      # five-component fit under the half-t(4, 0, 1) SD prior; the point (MAP) and the
      # percentile credible interval come from posterior_summary() off the `draws`
      # contract. Nested, fixed, conflated, incomplete, and replicate brms fits are
      # refused upstream (#5).
      fit_brms_multilevel(df, seed = seed, brm_args = brm_args)
    } else if (engine == "lme4") {
      # Crossed (Design 1) random raters via lme4 (M14 Slice 2).
      fit_lme4_multilevel(df)
    } else {
      fit_glmmtmb_multilevel(df)
    }
  } else if (oneway) {
    if (engine == "lme4") fit_lme4_oneway(df) else fit_glmmtmb_oneway(df)
  } else if (raters == "fixed") {
    if (replicates) {
      # Fixed-rater within-cell replicates (M20 Slice 1): the interaction fit with
      # raters fixed -- theta^2_r in the rater slot (fit_*_replicates_fixed). lavaan
      # replicates already aborted upstream; balanced/complete single-level only.
      if (engine == "lme4") {
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
    # Cross-product level x unit (x occasions for replicates); level outer so rows
    # group by level (M5 §3). For Design 2, `level` is already restricted to "subject"
    # (nested designs). With replicates the rater divisor counts DISTINCT raters
    # (replicates must not inflate it, M17 §4).
    k_ml <- if (replicates) design_info$k_eff_raters else k
    unlist(
      lapply(level, function(lv) {
        # Averaged cluster-level ICC(c,k) is undefined on incomplete data (the
        # effective per-cluster rater count is unresolved); keep only the
        # single-rater cluster ICC(c,1). The user was informed above. Subject-level
        # units, and every unit on balanced data, are unaffected.
        units_lv <- if (lv == "cluster" && !balanced) {
          Filter(function(u) identical(u, "single"), unit)
        } else {
          unit
        }
        # Occasion averaging (M20 Slice 2) reduces only pure error, which is not in the
        # cluster-level error set, so it is a no-op there -- emit single-occasion
        # cluster rows only. Non-replicate paths carry a single "single" occasion.
        occs_lv <- if (replicates && lv == "subject") occasions else "single"
        unlist(
          lapply(units_lv, function(u) {
            lapply(occs_lv, function(o) {
              icc_estimand(
                type = type,
                unit = u,
                raters = raters,
                k_eff = k_ml,
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
  } else if (oneway) {
    lapply(unit, function(u) icc_estimand(unit = u, k_eff = k, oneway = TRUE))
  } else if (replicates) {
    # Within-cell replicates (M17 Slice 3): cross unit x occasions (unit outer). The
    # rater divisor counts DISTINCT raters (replicates must not inflate it, §4);
    # `occasions` averages pure error over the n_o within-cell replicates.
    unlist(
      lapply(unit, function(u) {
        lapply(occasions, function(o) {
          icc_estimand(
            type = type,
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
  } else {
    lapply(
      unit,
      function(u) {
        icc_estimand(type = type, unit = u, raters = raters, k_eff = k)
      }
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
    intervals <- posterior_summary(
      engine_fit$draws,
      estimands,
      conf_level = conf_level
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
      engine = engine_fit$engine,
      ci = list(
        method = ci_method,
        conf_level = conf_level,
        # `samples` is the number of draws behind the reported interval: MC draws for
        # "montecarlo", refits for "bootstrap" (ADR-025), post-warmup posterior draws
        # for "posterior" (ADR-033).
        samples = if (ci_method == "bootstrap") {
          boot_samples
        } else if (ci_method == "posterior") {
          ncol(engine_fit$draws)
        } else {
          mc_samples
        },
        seed = seed,
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
