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
