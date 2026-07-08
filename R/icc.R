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
#' The design is **inferred from the data** (ten Hove et al. 2022, Table 2). If
#' raters are crossed with clusters (each rater rates in every cluster) the
#' five-component model above is used (Design 1). If raters are **nested in
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
#' number of raters per cluster is still being validated). **Fixed raters**
#' (`raters = "fixed"`) are supported for the crossed design at the **subject** level
#' on balanced, complete data: the rater main effect becomes the finite-population
#' variance of the observed raters (McGraw & Wong Case 3A), so consistency is identical
#' to the random-rater case and absolute agreement differs only by that term.
#' Incomplete *nested* designs, incomplete or nested fixed-rater designs, and the
#' fixed-rater cluster level remain for later milestones. Nested designs still require
#' balanced, complete data.
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
#' @param level For multilevel designs (a `cluster` column), which reliability to
#'   report: `"subject"` (within-cluster, distinguishing subjects) and/or
#'   `"cluster"` (between-cluster, distinguishing cluster means). Defaults to both.
#'   Ignored (and must be left at its default) when `cluster` is not supplied. Only
#'   `"subject"` is available when raters are nested in clusters (see the
#'   *Multilevel designs* section).
#' @param design Multilevel design (with a `cluster` column): `NULL` (the default)
#'   infers it from the crossing pattern. On **incomplete** data missing cells can
#'   make the pattern ambiguous between a crossed and a nested design; declare it
#'   explicitly with `"crossed"`, `"nested_in_clusters"`, or `"nested_in_subjects"`
#'   to resolve the ambiguity. A declaration is validated against the data -- it
#'   cannot force a design the data cannot support (e.g. `"crossed"` still requires
#'   raters that bridge clusters to estimate absolute agreement).
#' @param engine Estimation engine: `"glmmTMB"` (default), `"lme4"`, or
#'   `"lavaan"`. `"glmmTMB"` and `"lme4"` fit the variance components by REML and
#'   agree to within numerical tolerance on balanced data. `"lavaan"` fits the
#'   equivalent structural-equation (common-factor) generalizability model and
#'   recovers the rater main effect from the mean structure (Jorgensen 2021).
#'   **Consistency** ICCs from `"lavaan"` equal the mixed-model estimates exactly
#'   on balanced data; **absolute-agreement** ICCs use the SEM indicator-mean
#'   estimator of the rater variance, which is asymptotically equivalent to the
#'   mixed-model one and matches conventional generalizability-theory software on
#'   real data (Vispoel et al. 2022) but differs by a small-sample term on tiny
#'   designs (e.g. 0.284 vs 0.290 on the 6-subject example below). `"lme4"` covers
#'   the two-way (`raters = "random"` or, on complete/balanced data, `"fixed"`) and
#'   one-way designs, but not multilevel designs (a `cluster` column); `"lavaan"`
#'   currently covers only the random two-way design and additionally requires
#'   complete, balanced data. `"lme4"` requires the \pkg{lme4} and \pkg{merDeriv}
#'   packages; `"lavaan"` requires the \pkg{lavaan} package.
#' @param conf_level Confidence level for the interval (default `0.95`).
#' @param ci_method Interval method. Only `"montecarlo"` is currently supported.
#' @param mc_samples Number of Monte-Carlo draws for the interval.
#' @param seed Optional integer seed for a reproducible interval. The global RNG
#'   state is restored afterward.
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
  level = c("subject", "cluster"),
  design = NULL,
  engine = "glmmTMB",
  conf_level = 0.95,
  ci_method = "montecarlo",
  mc_samples = 10000L,
  seed = NULL
) {
  if (!is.data.frame(data)) {
    abort_intraclass("{.arg data} must be a data frame.")
  }

  # Dimensions not yet implemented fail loudly and point at where they are coming
  # (PRINCIPLES.md #5); implemented multi-value dimensions are arg-matched.
  model <- validate_choice(model, c("twoway", "oneway"), "model")
  oneway <- model == "oneway"
  engine <- validate_choice(engine, c("glmmTMB", "lme4", "lavaan"), "engine")
  require_supported(
    ci_method,
    "montecarlo",
    "ci_method",
    "interval methods beyond Monte-Carlo"
  )

  type <- validate_choice(type, c("agreement", "consistency"), "type")
  raters <- validate_choice(raters, c("random", "fixed"), "raters")
  unit <- validate_unit(unit)

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
  # (M5.5), one-way (M6), and the balanced fixed-rater two-way (M14 Slice 1) paths.
  # Multilevel lme4 is still deferred (M14 Slices 2/3), and the incomplete
  # fixed-rater lme4 path is refused below where balancedness is known. Route the
  # deferred multilevel request to a loud abort (PRINCIPLES.md #5) rather than
  # silently falling back to glmmTMB.
  if (engine == "lme4" && multilevel) {
    abort_unsupported(c(
      "The {.pkg lme4} engine does not support multilevel designs yet.",
      i = "{.code engine = \"lme4\"} is not available for multilevel designs; \\
           use {.code engine = \"glmmTMB\"}.",
      i = "lme4 for the multilevel fits is planned for a later milestone."
    ))
  }

  # M7 Slice 1 (ADR-014): the lavaan (SEM) engine covers the random two-way
  # COMPLETE design only. Fixed-rater, one-way, multilevel, and incomplete SEM are
  # deferred (recorded, not rediscovered); route them to a loud abort rather than
  # a silent glmmTMB fallback (PRINCIPLES.md #5). The incomplete-data guard needs
  # the design summary and lives further down.
  if (engine == "lavaan" && (multilevel || raters == "fixed" || oneway)) {
    design <- if (multilevel) {
      "multilevel"
    } else if (oneway) {
      "one-way"
    } else {
      "fixed-rater"
    }
    abort_unsupported(c(
      "The {.pkg lavaan} engine supports only the random two-way design so far.",
      i = "{.code engine = \"lavaan\"} is not available for {design} designs; \\
           use {.code engine = \"glmmTMB\"}.",
      i = "SEM for fixed, one-way, and multilevel designs is planned for a \\
           later milestone."
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
  if (raters == "fixed") {
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

  # Fixed-rater multilevel scope (M10, ADR-019): the crossed (Design 1) design,
  # balanced, subject level only. Fixed-rater nested designs and the fixed-rater
  # cluster level are deferred -- fail loudly (#5) before the design/fit machinery
  # runs. The balanced check lives below with the rest of the crossed guards.
  if (multilevel && raters == "fixed") {
    if (ml_design != "crossed") {
      abort_unsupported(c(
        "Fixed raters are only supported for the crossed multilevel design \\
         (Design 1).",
        i = "This design has raters nested in clusters or subjects; fixed-rater \\
             nested multilevel is planned for a later milestone.",
        i = "Use {.code raters = \"random\"}, or cross the raters with clusters."
      ))
    }
    if ("cluster" %in% level) {
      abort_unsupported(c(
        "Fixed-rater multilevel ICCs are available at the subject level only.",
        i = "The cluster-level fixed-rater estimand is planned for a later \\
             milestone.",
        i = "Use {.code level = \"subject\"} with {.code raters = \"fixed\"}."
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
    } else {
      # Design 3 needs >= 2 raters per subject to separate residual from subject.
      if (min(as.integer(table(df$subject))) < 2L) {
        abort_unidentified(c(
          "The residual variance cannot be separated from the subject variance \\
           when a subject is rated only once.",
          i = "Each {.arg subject} must be rated by 2 or more raters."
        ))
      }
    }
    # M8 covers balanced/complete nested designs; incomplete nested multilevel is
    # deferred (spec §8) -- fail loudly rather than use an unvalidated k_eff (#5).
    if (!nested_design_balanced(df, ml_design)) {
      abort_unsupported(c(
        "Incomplete or unbalanced nested multilevel designs are not supported yet.",
        i = "This milestone (M8) covers balanced, complete nested designs; \\
             incomplete nested multilevel is planned for a later slice.",
        x = "Provide a balanced design with equally sized clusters."
      ))
    }
  }

  # Design facts for a possibly-incomplete layout (estimand-spec M3 §3, §5). For
  # one-way the k_eff (harmonic mean of ratings/subject) is the only fact needed;
  # the cross-classified checks below (replicates, connectedness) do not apply --
  # rater identity is ignored, so multiple ratings per subject are the design, not
  # a violation (M6 spec §5).
  design_info <- summarize_design(df)
  if (!oneway) {
    # One rating per observed cell is the M3 estimand; replicates would change it
    # (split the interaction from pure error) and are a later milestone (#5, #17).
    if (design_info$has_replicates) {
      abort_unsupported(c(
        "Some subject-by-rater cells have more than one rating.",
        i = "Within-cell replicates (splitting the subject-by-rater interaction \\
             from pure error) are planned for a later milestone.",
        x = "Provide one rating per subject-by-rater cell."
      ))
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
    if (multilevel && ml_design == "crossed" && !design_info$balanced) {
      # Fixed-rater multilevel is balanced/complete only in M10 (theta^2_r under
      # imbalance is deferred, spec §3/§7); fail loudly before fitting (#5).
      if (raters == "fixed") {
        abort_unsupported(c(
          "Incomplete or unbalanced fixed-rater multilevel designs are not \\
           supported yet.",
          i = "Fixed-rater multilevel (M10) covers balanced, complete crossed \\
               designs; incomplete fixed-rater multilevel is planned for a later \\
               milestone.",
          i = "Use {.code raters = \"random\"} for incomplete multilevel data."
        ))
      }
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
        if (!all(vapply(unit, identical, logical(1), "single"))) {
          abort_unsupported(c(
            "Averaged cluster-level ICCs (ICC(c,k)) on incomplete data are not \\
             supported yet.",
            i = "The effective number of raters behind a ragged cluster mean is a \\
                 modeling choice still being validated; on incomplete data only the \\
                 single-rater {.code unit = \"single\"} cluster ICC is available.",
            i = "Use {.code unit = \"single\"} for the cluster level, or \\
                 {.code level = \"subject\"} for the average."
          ))
        }
      }
    }
  }
  # Balance: for one-way, every subject rated the same number of times; for
  # two-way, a complete crossed design with one rating per cell (M3).
  balanced <- if (oneway) {
    length(unique(as.integer(table(df$subject)))) == 1L
  } else if (multilevel && ml_design != "crossed") {
    # Only balanced/complete nested designs reach here (guarded above); the
    # subject x rater graph is block-diagonal, so design_info$balanced is not the
    # right notion for them (spec M8 §2).
    TRUE
  } else {
    design_info$balanced
  }

  # lavaan (SEM) reshapes to a complete subject-by-rater matrix, so an incomplete
  # (unbalanced) two-way design has no wide layout to fit. Incomplete-design SEM
  # (FIML) is deferred (ADR-014); fail loudly toward the engine that handles it.
  if (engine == "lavaan" && !balanced) {
    abort_unsupported(c(
      "The {.pkg lavaan} engine requires a complete, balanced two-way design.",
      i = "Incomplete-design SEM (FIML) is planned for a later milestone; use \\
           {.code engine = \"glmmTMB\"} for incomplete data."
    ))
  }

  # Fixed-rater lme4 (M14 Slice 1, ADR-023) covers the BALANCED two-way design
  # only; the incomplete fixed-rater theta^2_r-under-imbalance path stays with
  # glmmTMB (deferred). Fail loudly rather than silently switching engines (#5).
  if (engine == "lme4" && raters == "fixed" && !balanced) {
    abort_unsupported(c(
      "The {.pkg lme4} engine requires a complete, balanced design for fixed \\
       raters.",
      i = "Incomplete fixed-rater lme4 is planned for a later milestone; use \\
           {.code engine = \"glmmTMB\"} for incomplete data."
    ))
  }

  # Multilevel data uses a Design-1 (crossed, five-component) or Design-2 (raters
  # nested in clusters, four-component) fit per the inferred design; otherwise
  # fixed raters get their own fixed-effect fit (Case 3/3A) and random raters the
  # shared random-effects fit. The rest of the pipeline is identical -- each engine
  # returns named `components` the estimand indexes by signal/error (M8 §2, M5
  # §2/§3; M3 §6, ADR-008).
  engine_fit <- if (multilevel) {
    if (ml_design == "nested_in_clusters") {
      fit_glmmtmb_nested_clusters(df)
    } else if (ml_design == "nested_in_subjects") {
      fit_glmmtmb_nested_subjects(df)
    } else if (raters == "fixed") {
      # Crossed (Design 1) with raters as fixed effects -- theta^2_r in the rater
      # slot (M10). Fixed-rater nested/incomplete/cluster-level are guarded above.
      fit_glmmtmb_multilevel_fixed(df)
    } else {
      fit_glmmtmb_multilevel(df)
    }
  } else if (oneway) {
    if (engine == "lme4") fit_lme4_oneway(df) else fit_glmmtmb_oneway(df)
  } else if (raters == "fixed") {
    if (engine == "lme4") fit_lme4_fixed(df) else fit_glmmtmb_fixed(df)
  } else if (engine == "lme4") {
    fit_lme4(df)
  } else if (engine == "lavaan") {
    fit_lavaan(df)
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
    # Cross-product level x unit; level outer so rows group by level (M5 §3). For
    # Design 2, `level` is already restricted to "subject" (nested designs).
    unlist(
      lapply(level, function(lv) {
        lapply(unit, function(u) {
          icc_estimand(
            type = type,
            unit = u,
            raters = raters,
            k_eff = k,
            level = lv,
            multilevel = TRUE
          )
        })
      }),
      recursive = FALSE
    )
  } else if (oneway) {
    lapply(unit, function(u) icc_estimand(unit = u, k_eff = k, oneway = TRUE))
  } else {
    lapply(
      unit,
      function(u) {
        icc_estimand(type = type, unit = u, raters = raters, k_eff = k)
      }
    )
  }

  points <- vapply(
    estimands,
    function(e) icc_point(engine_fit$components, e),
    numeric(1)
  )
  intervals <- mc_ci(
    engine_fit,
    estimands,
    conf_level = conf_level,
    mc_samples = mc_samples,
    seed = seed
  )

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
        levels = if (multilevel) level else NULL
      ),
      k_eff = design_info$k_eff,
      engine = engine_fit$engine,
      ci = list(
        method = ci_method,
        conf_level = conf_level,
        samples = mc_samples,
        seed = seed
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

# Validate the multilevel `level` argument: the default (both) or a subset of
# {"subject", "cluster"} (M5). Returns the requested levels, de-duplicated,
# preserving the requested order.
validate_levels <- function(level, call = rlang::caller_env()) {
  choices <- c("subject", "cluster")
  if (!is.character(level) || length(level) < 1L || !all(level %in% choices)) {
    abort_intraclass(
      "{.arg level} must be one or both of {.val {choices}}.",
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
