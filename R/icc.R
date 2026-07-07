#' Intraclass correlation coefficient for a two-way random design
#'
#' Estimates interrater-reliability intraclass correlation coefficients (ICCs)
#' from a fitted linear mixed model, rather than from classical ANOVA mean
#' squares. In this release `icc()` computes the **two-way random,
#' absolute-agreement** coefficients `ICC(A,1)` and `ICC(A,k)` (McGraw & Wong
#' 1996), equivalent to Shrout & Fleiss (1979) `ICC(2,1)` and `ICC(2,k)`.
#'
#' @section Which ICC is this, and when should you use it?:
#' This is the **two-way random, absolute-agreement** ICC.
#' * **Absolute agreement** treats systematic differences between raters (the
#'   rater main effect, \eqn{\sigma^2_r}) as error: use it when the actual value
#'   matters and raters must agree on the number (clinical scores, measurements).
#'   Its sibling, *consistency*, ignores a constant rater offset and is not yet
#'   implemented.
#' * **`ICC(A,1)`** is the reliability of a *single* randomly chosen rater;
#'   **`ICC(A,k)`** is the reliability of the *mean* of your `k` raters. Report
#'   `ICC(A,k)` when the averaged score is what you will actually use.
#' * **Two-way random** means both subjects and raters are random samples you
#'   wish to generalize beyond.
#'
#' A large gap between consistency and absolute agreement signals big systematic
#' differences in rater level -- a rating-procedure problem worth fixing.
#'
#' @section Estimand:
#' With a single rating per subject-by-rater cell, the subject-by-rater
#' interaction and pure error are not separately identified; only their sum, the
#' residual variance \eqn{\sigma^2_{res}}, is estimable. The coefficients are
#' \deqn{ICC(A,1) = \sigma^2_s / (\sigma^2_s + \sigma^2_r + \sigma^2_{res})}
#' \deqn{ICC(A,k) = \sigma^2_s / (\sigma^2_s + (\sigma^2_r + \sigma^2_{res}) / k)}
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
#' @param type Error definition. Only `"agreement"` (absolute agreement) is
#'   currently supported; `"consistency"` is planned.
#' @param unit One or both of `"single"` (-> `ICC(A,1)`) and `"average"`
#'   (-> `ICC(A,k)`).
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
  type = "agreement",
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

  # Only one point in each dimension is implemented this release; everything else
  # fails loudly and points at where it is coming (PRINCIPLES.md #5).
  require_supported(model, "twoway", "model", "designs beyond two-way")
  require_supported(type, "agreement", "type", "consistency ICCs")
  require_supported(engine, "glmmTMB", "engine", "engines beyond glmmTMB")
  require_supported(
    ci_method,
    "montecarlo",
    "ci_method",
    "interval methods beyond Monte-Carlo"
  )

  unit <- validate_unit(unit)
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

  engine_fit <- fit_glmmtmb(df)
  estimands <- lapply(unit, function(u) icc_estimand(type = type, unit = u))
  k <- n_raters

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
      design = list(model = model, type = type),
      engine = engine_fit$engine,
      ci = list(
        method = ci_method,
        conf_level = conf_level,
        samples = mc_samples,
        seed = seed
      ),
      n = list(subjects = n_subjects, raters = n_raters, obs = nrow(df)),
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
