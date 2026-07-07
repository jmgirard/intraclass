# D-study reliability curve ----------------------------------------------------
#
# The classic D-study picture: projected reliability Φ(m) against the number of
# raters m, with a Monte-Carlo interval band -- "how many raters do I need?".
# ggplot2 is a Suggests dependency, so the method is guarded by
# `check_installed()` and registered lazily in zzz.R (light-install path).

#' @rdname d_study
#' @param object An `icc_dstudy` object (the `autoplot()`/`plot()` argument).
#' @importFrom rlang .data
# S3 method for ggplot2::autoplot (a Suggests generic), lazily registered in
# zzz.R; lintr does not see it as an S3 method (not a NAMESPACE export), so the
# `generic.class` dot trips object_name_linter -- suppressed here, not renamed.
# nolint start: object_name_linter.
autoplot.icc_dstudy <- function(object, ...) {
  # nolint end
  rlang::check_installed(
    "ggplot2",
    reason = "to plot a D-study reliability curve."
  )
  df <- object[order(object$m), , drop = FALSE]
  ci_pct <- format(100 * attr(object, "conf.level"), trim = TRUE)
  phrase <- icc_design_phrase(
    attr(object, "icc_type"),
    attr(object, "icc_raters")
  )

  ggplot2::ggplot(df, ggplot2::aes(x = .data$m, y = .data$estimate)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
      alpha = 0.15
    ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(
      x = "Number of raters (m)",
      y = "Reliability",
      title = sprintf("D-study projection: %s", phrase),
      subtitle = sprintf(
        "Projected reliability with %s%% Monte-Carlo interval",
        ci_pct
      )
    )
}

#' @rdname d_study
#' @export
plot.icc_dstudy <- function(x, ...) {
  print(autoplot.icc_dstudy(x, ...))
  invisible(x)
}

# Plots for a fitted `icc` object -----------------------------------------------
#
# Two views of a fitted estimator, selected by `what` (M11, ADR-020): the
# coefficient forest plot (each estimated index as a point + Monte-Carlo CI band)
# and the variance-component decomposition (Slice 2). Like the D-study curve,
# ggplot2 is a Suggests dependency, so the method is `check_installed()`-guarded
# and registered lazily in zzz.R (light-install path).

#' @rdname icc
#' @param what Which plot to draw: `"coefficients"` (the default) for a forest
#'   plot of each ICC index with its Monte-Carlo confidence interval, or
#'   `"components"` for the variance-component decomposition.
#' @examplesIf rlang::is_installed(c("ggplot2", "glmmTMB"))
#' fit <- icc(ratings, score, subject, rater, unit = c("single", "average"), seed = 1)
#' ggplot2::autoplot(fit)
#' @importFrom rlang .data
# S3 method for ggplot2::autoplot (a Suggests generic), lazily registered in
# zzz.R; see the icc_dstudy note above for why object_name_linter is suppressed.
# nolint start: object_name_linter.
autoplot.icc <- function(object, what = c("coefficients", "components"), ...) {
  # nolint end
  rlang::check_installed("ggplot2", reason = "to plot an {.cls icc} object.")
  what <- validate_choice(what, c("coefficients", "components"), "what")
  switch(
    what,
    coefficients = autoplot_icc_coefficients(object),
    components = autoplot_icc_components(object)
  )
}

# The coefficient forest plot: one row per estimated index, point estimate with a
# horizontal Monte-Carlo CI band. Multilevel objects carry the same index at more
# than one level (subject/cluster), so they are faceted by level.
autoplot_icc_coefficients <- function(object) {
  e <- object$estimates
  ml <- isTRUE(object$design$multilevel)
  ci_pct <- format(100 * object$ci$conf_level, trim = TRUE)

  df <- data.frame(
    index = factor(e$index, levels = rev(unique(e$index))),
    level = e$level,
    estimate = e$estimate,
    conf.low = e$conf.low,
    conf.high = e$conf.high,
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$estimate, y = .data$index)) +
    ggplot2::geom_linerange(
      ggplot2::aes(xmin = .data$conf.low, xmax = .data$conf.high)
    ) +
    ggplot2::geom_point() +
    ggplot2::coord_cartesian(xlim = c(0, 1)) +
    ggplot2::labs(
      x = "ICC estimate",
      y = NULL,
      title = sprintf(
        "Intraclass correlations: %s",
        icc_design_label(object$design)
      ),
      subtitle = sprintf(
        "Point estimate with %s%% Monte-Carlo interval",
        ci_pct
      )
    )
  if (ml) {
    # The same index label appears once per level; free the y scale so each facet
    # shows only its own rows (cluster level has fewer than subject level).
    p <- p +
      ggplot2::facet_wrap(
        ggplot2::vars(.data$level),
        ncol = 1,
        scales = "free_y"
      )
  }
  p
}

# The variance-component decomposition (M11 Slice 2). Stubbed here so `what` is a
# real, validated argument from Slice 1; the implementation lands in Slice 2.
autoplot_icc_components <- function(object) {
  abort_unsupported(c(
    "{.code what = \"components\"} is not implemented yet.",
    i = "The variance-component decomposition plot ships in M11 Slice 2.",
    i = "Use {.code what = \"coefficients\"} for the coefficient forest plot."
  ))
}

#' @rdname icc
#' @export
plot.icc <- function(x, ...) {
  print(autoplot.icc(x, ...))
  invisible(x)
}
