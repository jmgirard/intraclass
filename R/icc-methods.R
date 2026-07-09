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
  ow <- identical(x$design$model, "oneway")
  # Multilevel-aware design phrase, shared with autoplot.icc (spec M8 §4).
  phrase <- icc_design_label(x$design)
  header <- sprintf("# Intraclass correlation: %s", phrase)
  cell_total <- x$n$subjects * x$n$raters
  completeness <- if (x$design$balanced) "complete" else "incomplete"
  meta1 <- if (ml) {
    # Completeness is meaningful for the crossed (Design 1) design, where cells can
    # be missing; nested designs are always balanced/complete (guarded, M8).
    sprintf(
      "Subjects: %d in %d clusters | Raters: %d (%s) | Observations: %d (%s)",
      x$n$subjects,
      x$n$clusters,
      x$n$raters,
      x$design$raters,
      x$n$obs,
      completeness
    )
  } else if (ow) {
    # One-way: raters are interchangeable, so report ratings per subject (k_eff,
    # the averaging divisor) rather than a subject x rater cell grid (M6 spec §5).
    k_desc <- if (x$design$balanced) {
      format(x$k_eff, trim = TRUE)
    } else {
      formatC(x$k_eff, format = "f", digits = 2)
    }
    sprintf(
      "Subjects: %d | Ratings: %d (%s per subject, %s) | raters interchangeable",
      x$n$subjects,
      x$n$obs,
      k_desc,
      if (x$design$balanced) "balanced" else "unbalanced"
    )
  } else if (isTRUE(x$design$replicates)) {
    # Within-cell replicates: report the per-cell rating count (n_o) so the cell
    # grid does not hide the extra ratings that identify pure error.
    sprintf(
      "Subjects: %d | Raters: %d (%s) | %d cells x %d replicates (%s)",
      x$n$subjects,
      x$n$raters,
      x$design$raters,
      x$n$cells,
      x$design$n_o,
      completeness
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
  # glmmTMB/lme4 fit by REML; the lavaan SEM engine fits by ML (Wishart N-1); the
  # brms Bayesian engine samples the posterior by MCMC (Stan).
  estimator <- switch(x$engine, lavaan = "ML", brms = "MCMC", "REML")
  # The Bayesian "posterior" method is a CREDIBLE interval; the others are confidence
  # intervals. Surface that in the header (ci$method stays the raw token, ADR-033).
  ci_label <- if (identical(x$ci$method, "posterior")) {
    "posterior credible"
  } else {
    x$ci$method
  }
  meta2 <- sprintf(
    "Engine: %s (%s) | CI: %s%% %s (%d draws)",
    x$engine,
    estimator,
    ci_pct,
    ci_label,
    x$ci$samples
  )

  e <- x$estimates
  rep <- isTRUE(x$design$replicates)
  # Multilevel prints a `level` column, because the same index label (e.g.
  # ICC(A,1)) appears once per level (subject / cluster); single-level is
  # unchanged (M5 §3). Within-cell replicates likewise print an `occasions`
  # column (the n_o averaged), so a shared index disambiguates by occasion count.
  if (ml) {
    rows <- sprintf(
      "  %-10s %-9s %7s   [%s, %s]",
      e$level,
      e$index,
      formatC(e$estimate, format = "f", digits = 3),
      formatC(e$conf.low, format = "f", digits = 3),
      formatC(e$conf.high, format = "f", digits = 3)
    )
    table <- c(
      sprintf(
        "  %-10s %-9s %7s   %s",
        "level",
        "index",
        "estimate",
        paste0(ci_pct, "% CI")
      ),
      rows
    )
  } else if (rep) {
    rows <- sprintf(
      "  %-9s %9s %7s   [%s, %s]",
      e$index,
      format(e$occasions, trim = TRUE),
      formatC(e$estimate, format = "f", digits = 3),
      formatC(e$conf.low, format = "f", digits = 3),
      formatC(e$conf.high, format = "f", digits = 3)
    )
    table <- c(
      sprintf(
        "  %-9s %9s %7s   %s",
        "index",
        "occasions",
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
  keff_note <- if (!x$design$balanced && any(grepl("k\\)$", e$index))) {
    sprintf(
      "ICC(*,k) projects to an effective %s raters (harmonic mean of ratings/subject).",
      formatC(x$k_eff, format = "f", digits = 2)
    )
  }

  # The conflated level is the biased single-level ICC (Eq. 14): a diagnostic
  # contrast quantifying how much ignoring the clustering distorts reliability,
  # never a recommended coefficient (estimand-spec M17-conflated-icc.md §4).
  conflated_note <- if (ml && "conflated" %in% e$level) {
    c(
      "Diagnostic contrast: the 'conflated' level ignores the cluster structure",
      "(ten Hove et al. 2022, Eq. 14) -- it shows the bias from a single-level",
      "analysis and is NOT a recommended coefficient; report subject/cluster."
    )
  }

  # Shared with autoplot.icc (what = "components") so labels/ordering never drift.
  view <- icc_components_view(x)
  d3 <- function(v) formatC(v, format = "f", digits = 3)
  body <- paste(
    sprintf("%s %s", view$label, d3(view$variance)),
    collapse = ", "
  )
  # Design 3 and one-way fold the rater into the residual (spec M8 §2b, M6 §2).
  suffix <- if (isTRUE(view$confounded)) " (rater confounded)" else ""
  comps <- sprintf("Variance components: %s%s", body, suffix)

  c(
    header,
    meta1,
    meta2,
    "",
    table,
    "",
    keff_note,
    comps,
    sf_note,
    conflated_note
  )
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
  notes <- if (identical(object$design$model, "oneway")) {
    c(
      "One-way random: each subject is rated by a possibly different set of",
      "interchangeable raters, so systematic rater differences cannot be",
      "separated and are absorbed into the residual (a conservative ICC)."
    )
  } else {
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
    cell_note <- if (isTRUE(object$design$replicates)) {
      c(
        "Within-cell replicates separate the subject-by-rater interaction from",
        "pure error; occasion averaging reduces pure error only."
      )
    } else {
      c(
        "A single rating per cell confounds the subject-by-rater interaction with",
        "residual error."
      )
    }
    c(paste(type_note, effect), cell_note)
  }
  cli::cli_verbatim(c("", notes))
  invisible(object)
}

#' @rdname icc
#' @export
tidy.icc <- function(x, ...) {
  out <- tibble::tibble(
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
  # Within-cell replicates carry the occasion count averaged into each coefficient.
  if (isTRUE(x$design$replicates)) {
    out <- tibble::add_column(
      out,
      occasions = x$estimates$occasions,
      .after = "index"
    )
  }
  out
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
    ml_design = if (isTRUE(x$design$multilevel)) {
      x$design$ml_design
    } else {
      NA_character_
    },
    k_eff = x$k_eff,
    var_cluster = or_na(x$components$cluster),
    var_subject = x$components$subject,
    var_rater = or_na(x$components$rater),
    var_cluster_rater = or_na(x$components$cluster_rater),
    var_residual = x$components$residual,
    engine = x$engine,
    ci_method = x$ci$method,
    conf.level = x$ci$conf_level
  )
}
