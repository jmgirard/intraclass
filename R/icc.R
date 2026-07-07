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
#'   and forgoes generalization; on balanced data it gives the same number and
#'   `icc()` warns when you choose it. Fixed-rater consistency is the classic
#'   Shrout & Fleiss `ICC(3,1)`.
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
#'   observed raters as the entire population. On balanced data the point estimate
#'   and interval are identical either way -- `"fixed"` changes only the reported
#'   design and interpretation -- and choosing it emits a warning, because random
#'   is the recommended default for interrater reliability.
#' @param unit One or both of `"single"` (-> `ICC(*,1)`) and `"average"`
#'   (-> `ICC(*,k)`).
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

  engine_fit <- fit_glmmtmb(df)
  estimands <- lapply(
    unit,
    function(u) icc_estimand(type = type, unit = u, raters = raters)
  )
  # Averaging divisor: the effective number of ratings per subject (harmonic
  # mean), which is k on balanced data (ADR-008; M3 §5). ICC(*,1) ignores it.
  k <- design_info$k_eff

  points <- vapply(
    estimands,
    function(e) icc_point(engine_fit$components, e, k),
    numeric(1)
  )
  intervals <- mc_ci(
    engine_fit,
    estimands,
    k,
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

validate_unit <- function(unit, call = rlang::caller_env()) {
  valid <- c("single", "average")
  if (!is.character(unit) || length(unit) < 1L || !all(unit %in% valid)) {
    abort_intraclass(
      "{.arg unit} must be one or both of {.val {valid}}.",
      call = call
    )
  }
  unique(unit)
}
