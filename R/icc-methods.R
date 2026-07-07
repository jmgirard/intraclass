# S3 methods for `icc` objects -------------------------------------------------
#
# PRINCIPLES.md #7: explicit tidy generics. print/summary/format plus tidy/glance
# via the generics package. All user-facing text goes through cli (#8).

#' @rdname icc
#' @param x,object An `icc` object.
#' @param ... Unused, for method consistency.
#' @export
format.icc <- function(x, ...) {
  ci_pct <- format(100 * x$ci$conf_level, trim = TRUE)
  header <- sprintf(
    "# Intraclass correlation: two-way random, %s",
    if (x$design$type == "agreement") "absolute agreement" else x$design$type
  )
  meta1 <- sprintf(
    "Subjects: %d | Raters: %d (random) | Observations: %d",
    x$n$subjects,
    x$n$raters,
    x$n$obs
  )
  meta2 <- sprintf(
    "Engine: %s (REML) | CI: %s%% %s (%d draws)",
    x$engine,
    ci_pct,
    x$ci$method,
    x$ci$samples
  )

  e <- x$estimates
  rows <- sprintf(
    "  %-9s %7s   [%s, %s]",
    e$index,
    formatC(e$estimate, format = "f", digits = 3),
    formatC(e$conf.low, format = "f", digits = 3),
    formatC(e$conf.high, format = "f", digits = 3)
  )
  table <- c(
    sprintf("  %-9s %7s   %s", "index", "estimate", paste0(ci_pct, "% CI")),
    rows
  )

  vc <- x$components
  comps <- sprintf(
    "Variance components: subject %s, rater %s, residual %s",
    formatC(vc$subject, format = "f", digits = 3),
    formatC(vc$rater, format = "f", digits = 3),
    formatC(vc$residual, format = "f", digits = 3)
  )

  c(header, meta1, meta2, "", table, "", comps)
}

#' @rdname icc
#' @export
print.icc <- function(x, ...) {
  cli::cli_verbatim(format(x, ...))
  invisible(x)
}

#' @rdname icc
#' @export
summary.icc <- function(object, ...) {
  cli::cli_verbatim(format(object, ...))
  cli::cli_verbatim(c(
    "",
    "Absolute agreement counts the rater main effect as error; a single rating",
    "per cell confounds the subject-by-rater interaction with residual error."
  ))
  invisible(object)
}

#' @rdname icc
#' @export
tidy.icc <- function(x, ...) {
  tibble::tibble(
    index = x$estimates$index,
    estimate = x$estimates$estimate,
    std.error = x$estimates$std.error,
    conf.low = x$estimates$conf.low,
    conf.high = x$estimates$conf.high,
    conf.level = x$ci$conf_level,
    method = x$ci$method
  )
}

#' @rdname icc
#' @export
glance.icc <- function(x, ...) {
  tibble::tibble(
    n_subjects = x$n$subjects,
    n_raters = x$n$raters,
    n_obs = x$n$obs,
    var_subject = x$components$subject,
    var_rater = x$components$rater,
    var_residual = x$components$residual,
    engine = x$engine,
    ci_method = x$ci$method,
    conf.level = x$ci$conf_level
  )
}
