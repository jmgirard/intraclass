# S3 methods for `icc` objects -------------------------------------------------
#
# PRINCIPLES.md #7: explicit tidy generics. print/summary/format plus tidy/glance
# via the generics package. All user-facing text goes through cli (#8).

# cli inline styling for the printed report (M43/ADR-053). Each helper degrades
# to plain text when the console has no colour -- cli detects `num_colors == 1`
# (knitr, CRAN, a non-tty pipe, and testthat's `local_reproducible_output()`), so
# the printed *values* are byte-identical with or without styling; only emphasis
# is added. `style_bold`/`style_dim` return their input unchanged in that mode.

# A section-header rule, e.g. "-- Intraclass correlation: ... ----" when plain.
icc_rule <- function(title) {
  as.character(cli::rule(left = cli::style_bold(title)))
}

# Emphasize the point estimate; de-emphasize secondary text (CI, meta, notes).
icc_emph <- function(x) cli::style_bold(x)
icc_mute <- function(x) cli::style_dim(x)

# The full-word error-definition heading used to group the coefficient table by
# `type` when a call reports both agreement and consistency (the default; ADR-054).
icc_type_heading <- function(type) {
  switch(
    type,
    agreement = "Absolute agreement",
    consistency = "Consistency",
    type
  )
}

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
  header <- icc_rule(sprintf("Intraclass correlation: %s", phrase))
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
  # intervals. Surface that in the header (ci$method stays the raw token, ADR-033), and name
  # the HPDI variant when chosen (posterior_summary = "hpdi", M34 Slice 2, ADR-044).
  ci_label <- if (identical(x$ci$method, "posterior")) {
    if (identical(x$ci$posterior_summary, "hpdi")) {
      "posterior credible (HPDI)"
    } else {
      "posterior credible"
    }
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
  ci_hdr <- paste0(ci_pct, "% CI")
  # Column-aligned coefficient table. Cells are padded to fixed *plain* widths
  # first; then the estimate is emphasized (bold) and the CI de-emphasized (dim)
  # -- styling wraps already-padded text, so the columns line up identically with
  # or without colour (M43/ADR-053). The `[low, high]` bracket form is kept
  # verbatim so the snapshot CI mask still matches (tests/testthat/helper-format.R).
  fmt3 <- function(v) formatC(v, format = "f", digits = 3)
  est_col <- icc_emph(formatC(fmt3(e$estimate), width = 8))
  ci_col <- icc_mute(sprintf("[%s, %s]", fmt3(e$conf.low), fmt3(e$conf.high)))
  idx_col <- formatC(e$index, flag = "-", width = 9)
  # Multilevel prints a `level` column, because the same index label (e.g.
  # ICC(A,1)) appears once per level (subject / cluster); single-level is
  # unchanged (M5 §3). Within-cell replicates likewise print an `occasions`
  # column (the n_o averaged), so a shared index disambiguates by occasion count.
  if (ml) {
    head <- paste0(
      "  ",
      formatC("level", flag = "-", width = 10),
      " ",
      formatC("index", flag = "-", width = 9),
      " ",
      formatC("estimate", width = 8),
      "   ",
      ci_hdr
    )
    rows <- paste0(
      "  ",
      formatC(e$level, flag = "-", width = 10),
      " ",
      idx_col,
      " ",
      est_col,
      "   ",
      ci_col
    )
  } else if (rep) {
    head <- paste0(
      "  ",
      formatC("index", flag = "-", width = 9),
      " ",
      formatC("occasions", width = 9),
      " ",
      formatC("estimate", width = 8),
      "   ",
      ci_hdr
    )
    rows <- paste0(
      "  ",
      idx_col,
      " ",
      formatC(format(e$occasions, trim = TRUE), width = 9),
      " ",
      est_col,
      "   ",
      ci_col
    )
  } else {
    head <- paste0(
      "  ",
      formatC("index", flag = "-", width = 9),
      " ",
      formatC("estimate", width = 8),
      "   ",
      ci_hdr
    )
    rows <- paste0("  ", idx_col, " ", est_col, "   ", ci_col)
  }
  # When a call reports more than one error definition (the default four-formulation
  # table, ADR-054), group the rows under bold type headings ("Absolute agreement" /
  # "Consistency"); the rows are already type-major from the estimand cross-product.
  # A single-type call (or one-way, where `type` is NA) prints one ungrouped block --
  # byte-identical to before this milestone (number/shape invariance).
  types_present <- unique(e$type[!is.na(e$type)])
  table <- if (length(types_present) >= 2) {
    groups <- lapply(types_present, function(ty) {
      c(icc_emph(paste0("  ", icc_type_heading(ty))), rows[e$type == ty])
    })
    c(icc_mute(head), unlist(groups))
  } else {
    c(icc_mute(head), rows)
  }

  # Surface the Shrout & Fleiss equivalent for the forms that have one
  # (agreement+random -> ICC(2,.); consistency+fixed -> ICC(3,.)); M2 spec §5.
  has_sf <- !is.na(e$sf_index)
  sf_note <- if (any(has_sf)) {
    icc_mute(sprintf(
      "Shrout & Fleiss equivalent: %s",
      paste(e$index[has_sf], e$sf_index[has_sf], sep = " = ", collapse = ", ")
    ))
  }

  # On incomplete data ICC(*,k) is a projection to the effective number of
  # ratings per subject (harmonic mean, k_eff); surface it so the divisor is not
  # a black box (M3 spec §5, ADR-008). Silent on balanced data (k_eff == k).
  keff_note <- if (
    !x$design$balanced && any(grepl("k\\)$", e$index) & !(e$level %in% "cluster"))
  ) {
    icc_mute(sprintf(
      "ICC(*,k) projects to an effective %s raters (harmonic mean of ratings/subject).",
      formatC(x$k_eff, format = "f", digits = 2)
    ))
  }

  # The averaged cluster-level ICC(c,k) on incomplete data divides by a distinct,
  # per-cluster divisor -- the inverse-Simpson harmonic k_c^eff, the effective raters
  # behind each cluster's observed (cells-pooled) mean (M46, ADR-057). Surface it
  # separately so it is not confused with the subject-level k_eff. Silent on balanced
  # data (k_c^eff == rater count) and when no cluster average is reported.
  kceff_note <- if (
    !x$design$balanced &&
      !is.null(x$k_c_eff) &&
      !is.na(x$k_c_eff) &&
      any(grepl("k\\)$", e$index) & e$level == "cluster")
  ) {
    icc_mute(sprintf(
      "Cluster ICC(c,k) averages over an effective %s raters (inverse-Simpson k_c^eff).",
      formatC(x$k_c_eff, format = "f", digits = 2)
    ))
  }

  # The conflated level is the biased single-level ICC (Eq. 14): a diagnostic
  # contrast quantifying how much ignoring the clustering distorts reliability,
  # never a recommended coefficient (estimand-spec M17-conflated-icc.md §4).
  conflated_note <- if (ml && "conflated" %in% e$level) {
    icc_mute(c(
      "Diagnostic contrast: the 'conflated' level ignores the cluster structure",
      "(ten Hove et al. 2022, Eq. 14) -- it shows the bias from a single-level",
      "analysis and is NOT a recommended coefficient; report subject/cluster."
    ))
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
  comps <- icc_mute(sprintf("Variance components: %s%s", body, suffix))

  c(
    header,
    icc_mute(meta1),
    icc_mute(meta2),
    "",
    table,
    "",
    keff_note,
    kceff_note,
    comps,
    sf_note,
    conflated_note
  )
}

#' @rdname icc
#' @export
print.icc <- function(x, ...) {
  # Join to one string so the blank-line section separators in format() survive:
  # cli_verbatim() drops empty vector elements but honours embedded "\n" (M43).
  cli::cli_verbatim(paste(format(x, ...), collapse = "\n"))
  invisible(x)
}

#' @rdname icc
#' @export
summary.icc <- function(object, ...) {
  notes <- if (identical(object$design$model, "oneway")) {
    c(
      "One-way random: each subject is rated by a possibly different set of",
      "interchangeable raters, so systematic rater differences cannot be",
      "separated and are absorbed into the residual (a conservative ICC)."
    )
  } else {
    # One interpretive note per error definition present (both, for the default
    # four-formulation report; ADR-054). The two-line split per type is preserved so a
    # single-type summary is byte-identical to before this milestone.
    type_line <- function(ty) {
      if (ty == "agreement") {
        paste(
          "Absolute agreement counts the rater main effect (systematic differences in",
          "rater level) as error."
        )
      } else {
        paste(
          "Consistency ignores the rater main effect (systematic differences in",
          "rater level); only relative standing counts."
        )
      }
    }
    types_present <- unique(object$design$type[!is.na(object$design$type)])
    type_notes <- vapply(types_present, type_line, character(1))
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
    c(type_notes, cell_note)
  }
  # The report (format) plus a blank line plus the interpretive notes, emitted as
  # one string so the section blanks render (see print.icc).
  cli::cli_verbatim(paste(c(format(object, ...), "", notes), collapse = "\n"))
  invisible(object)
}

#' @rdname icc
#' @export
tidy.icc <- function(x, ...) {
  out <- tibble::tibble(
    index = x$estimates$index,
    type = x$estimates$type,
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
    k_c_eff = or_na(x$k_c_eff),
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
