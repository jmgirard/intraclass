# D-study projection -----------------------------------------------------------
#
# A generalizability-theory decision (D-) study projects the reliability
# coefficient to the mean of an arbitrary number of raters `m`, other than the
# number observed. Because the absolute-agreement ICC is the dependability
# coefficient Phi and
#
#     Phi(m) = sigma^2_s / (sigma^2_s + (sigma^2_r + sigma^2_res) / m),
#
# projection is only a change of the averaging DIVISOR in the existing
# (signal, {error set}, divisor) estimand -- not new machinery (ROADMAP; M4.5
# spec). `d_study()` reuses the stored fit and its parameter covariance (no
# refit), drawing the Monte-Carlo sample ONCE and evaluating every `m` against
# the same draws so the reliability curve and its interval band are coherent.

#' Project reliability to other numbers of raters (a D-study)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Projects the reliability of a fitted [icc()] to the mean of an arbitrary
#' number of raters `m` -- a generalizability-theory **decision (D-) study**,
#' answering "how reliable would the mean of `m` raters be?" and, read as a
#' curve, "how many raters do I need?". The point estimate and its boundary-aware
#' Monte-Carlo interval reuse the fit stored on `x`; no model is refit.
#'
#' @section Projection is extrapolation:
#' Projecting to an `m` you did not run is an **extrapolation**, and its
#' trustworthiness depends on how well the variance components -- especially the
#' rater variance \eqn{\sigma^2_r}, estimated from only as many raters as you
#' observed -- are pinned down. With few raters that estimate is noisy, so the
#' projected interval is honestly wide; the Monte-Carlo interval widens
#' automatically (it recomputes \eqn{\Phi(m)} on every draw) rather than
#' pretending a single plugged-in value. `m` is the number of raters and is
#' normally an integer, though non-integer values are permitted.
#'
#' Projection is defined for random raters (both agreement and consistency) and
#' for fixed-rater **consistency**. It is **not** defined for fixed-rater
#' absolute agreement: there the rater term is the finite-population variance of
#' exactly the raters you observed, so there is no "average of `m` freshly
#' sampled raters" to project to, and `d_study()` aborts (use
#' `raters = "random"`).
#'
#' @param x An `icc` object returned by [icc()].
#' @param m Numeric vector of rater counts to project to (each \eqn{\ge 1}).
#'   Defaults to `1:(2 * n_raters)`, a curve from a single rater to twice the
#'   observed count.
#' @param conf_level,mc_samples,seed Interval settings. Each defaults to the
#'   value stored on `x` (so a seeded fit yields a reproducible projection);
#'   override to change the confidence level, the number of Monte-Carlo draws, or
#'   the seed.
#'
#' @return An `icc_dstudy` object: a tibble with one row per `m` and columns
#'   `m`, `index` (e.g. `"ICC(A,3)"`), `estimate`, `std.error`, `conf.low`, and
#'   `conf.high`, carrying the design and interval settings as attributes. Use
#'   [tidy()][generics::tidy], [glance()][generics::glance], and
#'   `autoplot()` (the reliability curve).
#'
#' @references
#' Brennan, R. L. (2001). *Generalizability Theory*. Springer.
#'
#' @examples
#' fit <- icc(ratings, score, subject, rater, seed = 1)
#' d_study(fit, m = 1:8)
#'
#' @seealso [icc()], which also accepts a numeric `unit` for one-off projections.
#' @export
d_study <- function(
  x,
  m = NULL,
  conf_level = NULL,
  mc_samples = NULL,
  seed = NULL
) {
  if (!inherits(x, "icc")) {
    abort_intraclass("{.arg x} must be an {.cls icc} object from {.fn icc}.")
  }
  type <- x$design$type
  raters <- x$design$raters
  # Same ill-posed combination guarded by icc()'s numeric-unit path (M4.5 spec).
  abort_fixed_agr_projection(type, raters)

  if (is.null(m)) {
    m <- seq_len(2L * x$n$raters)
  }
  m <- validate_m(m)
  if (is.null(conf_level)) {
    conf_level <- x$ci$conf_level
  }
  if (is.null(mc_samples)) {
    mc_samples <- x$ci$samples
  }
  if (is.null(seed)) {
    seed <- x$ci$seed
  }

  estimands <- lapply(
    m,
    function(mm) icc_estimand(type = type, unit = mm, raters = raters)
  )
  points <- vapply(
    estimands,
    function(e) icc_point(x$components, e),
    numeric(1)
  )
  # One Monte-Carlo sample, reused across every m (coherent curve + band).
  components <- mc_components(x$mc, mc_samples = mc_samples, seed = seed)
  intervals <- lapply(
    estimands,
    function(e) mc_interval(components, e, conf_level)
  )

  tbl <- tibble::tibble(
    m = m,
    index = vapply(estimands, `[[`, character(1), "label"),
    estimate = points,
    std.error = vapply(intervals, `[[`, numeric(1), "std.error"),
    conf.low = vapply(intervals, `[[`, numeric(1), "conf.low"),
    conf.high = vapply(intervals, `[[`, numeric(1), "conf.high")
  )

  structure(
    tbl,
    class = c("icc_dstudy", class(tbl)),
    icc_type = type,
    icc_raters = raters,
    conf.level = conf_level,
    method = x$ci$method,
    samples = mc_samples,
    k_observed = x$n$raters,
    k_eff = x$k_eff
  )
}

# Validate the projected rater counts: a non-empty numeric vector, all finite and
# >= 1 (you cannot average fewer than one rater). Non-integer m is allowed (the
# effective k_eff is itself non-integer under imbalance).
validate_m <- function(m, call = rlang::caller_env()) {
  if (!is.numeric(m) || length(m) < 1L || anyNA(m) || any(!is.finite(m))) {
    abort_intraclass(
      "{.arg m} must be a non-empty numeric vector of rater counts.",
      call = call
    )
  }
  if (any(m < 1)) {
    abort_intraclass(
      c(
        "{.arg m} must be at least 1 (the mean of at least one rater).",
        x = "Smallest value supplied: {.val {min(m)}}."
      ),
      call = call
    )
  }
  m
}

# Methods ----------------------------------------------------------------------

#' @rdname d_study
#' @param ... Unused, for method consistency.
#' @export
format.icc_dstudy <- function(x, ...) {
  ci_pct <- format(100 * attr(x, "conf.level"), trim = TRUE)
  header <- sprintf(
    "# D-study projection: %s",
    icc_design_phrase(attr(x, "icc_type"), attr(x, "icc_raters"))
  )
  meta <- sprintf(
    "Observed raters: %d | CI: %s%% %s (%d draws)",
    attr(x, "k_observed"),
    ci_pct,
    attr(x, "method"),
    attr(x, "samples")
  )
  rows <- sprintf(
    "  %5s  %8s   [%s, %s]",
    format(x$m, trim = TRUE),
    formatC(x$estimate, format = "f", digits = 3),
    formatC(x$conf.low, format = "f", digits = 3),
    formatC(x$conf.high, format = "f", digits = 3)
  )
  table <- c(
    sprintf("  %5s  %8s   %s", "m", "estimate", paste0(ci_pct, "% CI")),
    rows
  )
  c(header, meta, "", table)
}

#' @rdname d_study
#' @export
print.icc_dstudy <- function(x, ...) {
  cli::cli_verbatim(format(x, ...))
  invisible(x)
}

#' @rdname d_study
#' @export
tidy.icc_dstudy <- function(x, ...) {
  tibble::tibble(
    m = x$m,
    index = x$index,
    estimate = x$estimate,
    std.error = x$std.error,
    conf.low = x$conf.low,
    conf.high = x$conf.high,
    conf.level = attr(x, "conf.level"),
    method = attr(x, "method")
  )
}

#' @rdname d_study
#' @export
glance.icc_dstudy <- function(x, ...) {
  tibble::tibble(
    n_m = nrow(x),
    m_min = min(x$m),
    m_max = max(x$m),
    type = attr(x, "icc_type"),
    raters = attr(x, "icc_raters"),
    k_observed = attr(x, "k_observed"),
    conf.level = attr(x, "conf.level"),
    method = attr(x, "method"),
    mc_samples = attr(x, "samples")
  )
}
