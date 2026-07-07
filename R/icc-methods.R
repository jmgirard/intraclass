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
  ml <- isTRUE(x$design$multilevel)
  phrase <- icc_design_phrase(x$design$type, x$design$raters)
  if (ml) {
    phrase <- paste("multilevel", phrase)
  }
  header <- sprintf("# Intraclass correlation: %s", phrase)
  cell_total <- x$n$subjects * x$n$raters
  completeness <- if (x$design$balanced) "complete" else "incomplete"
  meta1 <- if (ml) {
    sprintf(
      "Subjects: %d in %d clusters | Raters: %d (%s) | Observations: %d",
      x$n$subjects,
      x$n$clusters,
      x$n$raters,
      x$design$raters,
      x$n$obs
    )
  } else {
    sprintf(
      "Subjects: %d | Raters: %d (%s) | Observations: %d of %d cells (%s)",
      x$n$subjects,
      x$n$raters,
      x$design$raters,
      x$n$cells,
      cell_total,
      completeness
    )
  }
  meta2 <- sprintf(
    "Engine: %s (REML) | CI: %s%% %s (%d draws)",
    x$engine,
    ci_pct,
    x$ci$method,
    x$ci$samples
  )

  e <- x$estimates
  # Multilevel prints a `level` column, because the same index label (e.g.
  # ICC(A,1)) appears once per level (subject / cluster); single-level is
  # unchanged (M5 §3).
  if (ml) {
    rows <- sprintf(
      "  %-8s %-9s %7s   [%s, %s]",
      e$level,
      e$index,
      formatC(e$estimate, format = "f", digits = 3),
      formatC(e$conf.low, format = "f", digits = 3),
      formatC(e$conf.high, format = "f", digits = 3)
    )
    table <- c(
      sprintf(
        "  %-8s %-9s %7s   %s",
        "level",
        "index",
        "estimate",
        paste0(ci_pct, "% CI")
      ),
      rows
    )
  } else {
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
  }

  # Surface the Shrout & Fleiss equivalent for the forms that have one
  # (agreement+random -> ICC(2,.); consistency+fixed -> ICC(3,.)); M2 spec §5.
  has_sf <- !is.na(e$sf_index)
  sf_note <- if (any(has_sf)) {
    sprintf(
      "Shrout & Fleiss equivalent: %s",
      paste(e$index[has_sf], e$sf_index[has_sf], sep = " = ", collapse = ", ")
    )
  }

  # On incomplete data ICC(*,k) is a projection to the effective number of
  # ratings per subject (harmonic mean, k_eff); surface it so the divisor is not
  # a black box (M3 spec §5, ADR-008). Silent on balanced data (k_eff == k).
  keff_note <- if (!x$design$balanced && any(grepl(",k)$", e$index))) {
    sprintf(
      "ICC(*,k) projects to an effective %s raters (harmonic mean of ratings/subject).",
      formatC(x$k_eff, format = "f", digits = 2)
    )
  }

  vc <- x$components
  d3 <- function(v) formatC(v, format = "f", digits = 3)
  comps <- if (ml) {
    sprintf(
      paste(
        "Variance components: cluster %s, subject %s, rater %s,",
        "cluster:rater %s, residual %s"
      ),
      d3(vc$cluster),
      d3(vc$subject),
      d3(vc$rater),
      d3(vc$cluster_rater),
      d3(vc$residual)
    )
  } else {
    sprintf(
      "Variance components: subject %s, rater %s, residual %s",
      d3(vc$subject),
      d3(vc$rater),
      d3(vc$residual)
    )
  }

  c(header, meta1, meta2, "", table, "", keff_note, comps, sf_note)
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
  type_note <- if (object$design$type == "agreement") {
    "Absolute agreement counts the rater main effect (systematic differences in"
  } else {
    "Consistency ignores the rater main effect (systematic differences in"
  }
  effect <- if (object$design$type == "agreement") {
    "rater level) as error."
  } else {
    "rater level); only relative standing counts."
  }
  cli::cli_verbatim(c(
    "",
    paste(type_note, effect),
    "A single rating per cell confounds the subject-by-rater interaction with",
    "residual error."
  ))
  invisible(object)
}

#' @rdname icc
#' @export
tidy.icc <- function(x, ...) {
  tibble::tibble(
    index = x$estimates$index,
    level = x$estimates$level,
    sf_index = x$estimates$sf_index,
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
  or_na <- function(v) if (is.null(v)) NA_real_ else v
  tibble::tibble(
    n_subjects = x$n$subjects,
    n_raters = x$n$raters,
    n_clusters = x$n$clusters,
    n_obs = x$n$obs,
    n_cells = x$n$cells,
    balanced = x$design$balanced,
    multilevel = isTRUE(x$design$multilevel),
    k_eff = x$k_eff,
    var_cluster = or_na(x$components$cluster),
    var_subject = x$components$subject,
    var_rater = x$components$rater,
    var_cluster_rater = or_na(x$components$cluster_rater),
    var_residual = x$components$residual,
    engine = x$engine,
    ci_method = x$ci$method,
    conf.level = x$ci$conf_level
  )
}
