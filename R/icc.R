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
#' @section Confidence intervals:
#' Intervals are Monte-Carlo: parameters are drawn from the fitted covariance on
#' the model's internal (log) scale and back-transformed, so the interval is
#' boundary-aware near the common zero-rater-variance case where the delta method
#' fails. Pass `seed` for a reproducible interval.
#'
#' @param data A data frame with one rating per row.
#' @param score,subject,rater Columns of `data` (unquoted): the numeric rating,
#'   the subject (object of measurement), and the rater (judge).
#' @param model Design. Only `"twoway"` is currently supported.
#' @param type Error definition: `"agreement"` (absolute agreement, the default)
#'   counts systematic rater differences as error; `"consistency"` ignores them.
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
#' @param engine Estimation engine. Only `"glmmTMB"` is currently supported.
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
  model = "twoway",
  type = c("agreement", "consistency"),
  raters = c("random", "fixed"),
  unit = c("single", "average"),
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
  require_supported(model, "twoway", "model", "designs beyond two-way")
  require_supported(engine, "glmmTMB", "engine", "engines beyond glmmTMB")
  require_supported(
    ci_method,
    "montecarlo",
    "ci_method",
    "interval methods beyond Monte-Carlo"
  )

  type <- validate_choice(type, c("agreement", "consistency"), "type")
  raters <- validate_choice(raters, c("random", "fixed"), "raters")
  unit <- validate_unit(unit)

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

  n_subjects <- nlevels(df$subject)
  n_raters <- nlevels(df$rater)
  if (n_raters < 2L) {
    abort_unidentified(c(
      "A two-way ICC needs at least 2 raters to separate the rater variance.",
      i = "{.arg rater} has {n_raters} level{?s}."
    ))
  }
  if (n_subjects < 2L) {
    abort_unidentified(c(
      "A two-way ICC needs at least 2 subjects to estimate the signal variance.",
      i = "{.arg subject} has {n_subjects} level{?s}."
    ))
  }

  # Design facts for a possibly-incomplete layout (estimand-spec M3 §3, §5).
  design_info <- summarize_design(df)
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
  # disconnected layout confounds them and is not identified (#5; M3 §3).
  if (!design_info$connected) {
    abort_unidentified(c(
      "The subject-by-rater design is disconnected, so the subject and rater \\
       variances cannot be separated.",
      i = "Every subject and rater must be linked through shared ratings (one \\
           connected design).",
      i = "For unlinked rater groups, a one-way ICC (planned) or additional \\
           linking ratings are needed."
    ))
  }

  # Fixed raters get their own fixed-effect fit (Case 3/3A); random raters use
  # the shared random-effects fit. The rest of the pipeline is identical -- the
  # fixed engine returns theta^2_r in the "rater" slot (M3 §6, ADR-008).
  engine_fit <- if (raters == "fixed") {
    fit_glmmtmb_fixed(df)
  } else {
    fit_glmmtmb(df)
  }
  # Averaging divisor: the effective number of ratings per subject (harmonic
  # mean), which is k on balanced data (ADR-008; M3 §5). "single" uses 1; a
  # numeric unit projects to that many raters. Resolved per estimand.
  k <- design_info$k_eff
  estimands <- lapply(
    unit,
    function(u) icc_estimand(type = type, unit = u, raters = raters, k_eff = k)
  )

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
        type = type,
        raters = raters,
        balanced = design_info$balanced
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
