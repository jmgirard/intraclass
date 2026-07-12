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
  # The swept axis (M39): the occasion projection plots reliability against `n_o`
  # (raters held at k_eff), the default rater projection against `m`. Older objects
  # (pre-M39) have no `axis` attribute and default to the rater axis.
  occasion_axis <- identical(attr(object, "axis"), "occasions")
  x_col <- if (occasion_axis) "occasions" else "m"
  x_lab <- if (occasion_axis) {
    "Number of occasions (n_o)"
  } else {
    "Number of raters (m)"
  }
  df <- object[order(object[[x_col]]), , drop = FALSE]
  ci_pct <- format(100 * attr(object, "conf.level"), trim = TRUE)
  # icc_design_label is multilevel-aware; older objects fall back to the phrase.
  label <- attr(object, "icc_design_label")
  if (is.null(label)) {
    label <- icc_design_phrase(
      attr(object, "icc_type"),
      attr(object, "icc_raters")
    )
  }

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = .data[[x_col]], y = .data$estimate)
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$conf.low, ymax = .data$conf.high),
      alpha = 0.15
    ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(
      x = x_lab,
      y = "Reliability",
      title = sprintf("D-study projection: %s", label),
      subtitle = sprintf(
        "Projected reliability with %s%% Monte-Carlo interval",
        ci_pct
      )
    )
  # A multilevel projection has one curve per level; facet so the subject- and
  # cluster-level curves are not overplotted (mirrors autoplot.icc).
  if (isTRUE(attr(object, "multilevel"))) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$level))
  }
  p
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
#' ggplot2::autoplot(fit) # coefficient forest plot (the default)
#' ggplot2::autoplot(fit, what = "components") # variance-component decomposition
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

# The variance-component decomposition: one bar per estimated variance component,
# in the model's natural order (cluster -> subject -> rater -> cluster:rater ->
# residual, subset to the design). Shares `icc_components_view()` with the printed
# report, so the bars and the "Variance components:" line always agree.
autoplot_icc_components <- function(object) {
  view <- icc_components_view(object)
  df <- data.frame(
    component = factor(view$label, levels = view$label),
    variance = view$variance,
    stringsAsFactors = FALSE
  )
  subtitle <- if (isTRUE(view$confounded)) {
    "Rater variance is confounded into the residual"
  }

  ggplot2::ggplot(df, ggplot2::aes(x = .data$component, y = .data$variance)) +
    ggplot2::geom_col() +
    ggplot2::labs(
      x = NULL,
      y = "Variance",
      title = sprintf(
        "Variance components: %s",
        icc_design_label(object$design)
      ),
      subtitle = subtitle
    )
}

#' @rdname icc
#' @export
plot.icc <- function(x, ...) {
  print(autoplot.icc(x, ...))
  invisible(x)
}
