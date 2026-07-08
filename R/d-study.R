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
#' interval reuse the fit stored on `x`; no model is refit. The band follows the
#' fit's `ci_method`: a Monte-Carlo fit reprojects one draw from the parameter
#' covariance across every `m`, while a **bootstrap** fit reprojects its stored
#' resamples (so at `m` = the observed rater count the band matches the fitted
#' `ICC(*,k)` interval exactly).
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
#' Projection is defined for random raters (both agreement and consistency), for
#' fixed-rater **consistency**, and for the **one-way** model (a Spearman-Brown
#' projection of `ICC(1)`). It is **not** defined for fixed-rater absolute
#' agreement: there the rater term is the finite-population variance of exactly the
#' raters you observed, so there is no "average of `m` freshly sampled raters" to
#' project to, and `d_study()` aborts (use `raters = "random"`).
#'
#' @section Multilevel projections:
#' For a multilevel fit (a `cluster` column), `d_study()` projects the rater count
#' `m` for each correctly-partitioned level on the object — the **subject** and/or
#' **cluster** level — returning one reliability curve per level (the result gains
#' a `level` column, and `autoplot()` facets by it). This is the paper-sanctioned
#' rater projection (ten Hove et al. 2022): `m` is the number of raters per cluster,
#' and the cluster-level coefficient does **not** average over subjects, so there is
#' no "subjects per cluster" projection — that is a sample-size question, not a
#' reliability one. Nested designs project the subject level only. The conflated
#' diagnostic (`level = "conflated"`) is not projected. On **incomplete** data the
#' **subject** level projects (projection moves only the divisor); the **cluster**
#' level is dropped with a note, because projecting `m` raters is the averaged
#' `ICC(c,k)` case whose ragged divisor is an open modeling question (M9).
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
#'   `conf.high`, carrying the design and interval settings as attributes. A
#'   multilevel projection adds a `level` column (one curve per level). Use
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
  # Within-cell replicate fits (M17 Slice 3; M20 Slices 1-2) split the residual into
  # the interaction sigma^2_sr and pure error sigma^2_e. A rater-count projection off
  # such a fit would need the per-component error divisors (the interaction divides by
  # raters, pure error by raters x occasions), which the projection estimand here does
  # not carry -- and an occasion projection is a separate deferred facet (M17 §7).
  # Rather than silently drop the interaction from the error set, refuse loudly (#1/#5).
  if (isTRUE(x$design$replicates)) {
    abort_unsupported(c(
      "D-study projection is not supported for within-cell replicate fits yet.",
      i = "Projecting the rater (or occasion) count off a replicate fit needs the \\
           per-component error divisors, which is planned for a later milestone.",
      i = "Refit with one rating per subject-by-rater cell to project rater counts."
    ))
  }
  type <- x$design$type
  raters <- x$design$raters
  oneway <- identical(x$design$model, "oneway")
  multilevel <- isTRUE(x$design$multilevel)
  # Design 3 (raters nested in subjects) is the multilevel one-way: no rater term,
  # agreement-only ICC(m) (estimand-spec M8 §3b), so it projects like a one-way fit
  # but carries a subject `level`.
  ml_oneway <- identical(x$design$ml_design, "nested_in_subjects")

  # Multilevel rater-count projection (M17 Slice 2, estimand-spec M4.5 §7): project
  # `m` for each correctly-partitioned level on the fit. Complete data only -- the
  # cluster-level ICC(c,k) divisor under imbalance is the open M9 question (§7.2).
  proj_levels <- NULL
  if (multilevel) {
    # The conflated diagnostic (Eq. 14, M17 Slice 1) is a bias contrast, not a
    # decision-study target, so it is not projected (spec M4.5 §7.2).
    proj_levels <- setdiff(x$design$levels, "conflated")
    # Incomplete multilevel projection (M18 Slice 3, ADR-028): the SUBJECT level
    # projects on ragged data -- projection moves only the averaging divisor `m`, and
    # the subject estimand's error divisor IS `m` (not `k_eff`), so the ragged-fit
    # components suffice and the M9 subject-level identifiability already held at fit
    # time. The CLUSTER level stays bounded: projecting `m` raters is precisely the
    # averaged ICC(c,k) case, whose per-cluster effective-rater divisor under imbalance
    # is the open M9 question (spec M4.5 §7.2, M9 §9). Drop it with a note (mirroring
    # icc()'s cluster-on-incomplete posture) and abort only if nothing is left.
    if (!isTRUE(x$design$balanced) && "cluster" %in% proj_levels) {
      if (!("subject" %in% proj_levels)) {
        abort_unsupported(c(
          "Cluster-level D-study projection is not supported on incomplete data.",
          i = "The per-cluster effective-rater divisor behind a ragged cluster mean \\
               is an open modeling question (M9); only the subject level projects on \\
               incomplete data.",
          i = "Refit with {.code level = \"subject\"} for an incomplete multilevel \\
               D-study."
        ))
      }
      cli::cli_inform(
        c(
          i = "Cluster-level D-study projection is not available on incomplete data \\
               (the ragged ICC(c,k) divisor is unresolved); projecting the subject \\
               level only.",
          i = "Subject-level projection is unaffected."
        ),
        .frequency = "once",
        .frequency_id = "intraclass_dstudy_cluster_incomplete"
      )
      proj_levels <- setdiff(proj_levels, "cluster")
    }
    if (length(proj_levels) == 0L) {
      abort_unsupported(c(
        "The conflated ICC is a diagnostic contrast and is not projected.",
        i = "Refit with {.code level = \"subject\"} and/or {.code \"cluster\"} to \\
             project a multilevel D-study."
      ))
    }
  }
  # A one-way fit has no rater term (`type` is NA); its projection is the one-way
  # ICC(m) (signal subject, error residual, divisor m) -- the same estimand the
  # sibling path `icc(..., model = "oneway", unit = m)` computes. Route to it rather
  # than fall through to the two-way `icc_estimand()`, which would arg-match NA and
  # crash with an unclassed error. Fixed-rater absolute agreement cannot be
  # projected (single- or multi-level); the guard is a no-op for random/consistency
  # and for the one-way designs (which have no fixed raters).
  if (!oneway && !ml_oneway) {
    abort_fixed_agr_projection(type, raters)
  }

  if (is.null(m)) {
    m <- seq_len(2L * x$n$raters)
  }
  m <- validate_m(m)
  if (is.null(conf_level)) {
    conf_level <- x$ci$conf_level
  }
  if (is.null(mc_samples)) {
    # `mc_samples` sizes the Monte-Carlo band only (a bootstrap fit reprojects its
    # stored resamples instead -- M18 Slice 4, below). Reuse the parent's MC draw
    # count when it too was Monte-Carlo; otherwise fall back to the default (ADR-025).
    mc_samples <- if (identical(x$ci$method, "montecarlo")) {
      x$ci$samples
    } else {
      10000L
    }
  }
  if (is.null(seed)) {
    seed <- x$ci$seed
  }

  # One estimand per projected coefficient. Single-level: one per `m`. Multilevel:
  # the cross-product level x m (level outer, so rows group by level as in icc()).
  make_estimand <- function(mm, lv) {
    if (ml_oneway) {
      icc_estimand(unit = mm, oneway = TRUE, multilevel = TRUE, level = lv)
    } else if (multilevel) {
      icc_estimand(
        type = type,
        unit = mm,
        raters = raters,
        multilevel = TRUE,
        level = lv
      )
    } else if (oneway) {
      icc_estimand(unit = mm, oneway = TRUE)
    } else {
      icc_estimand(type = type, unit = mm, raters = raters)
    }
  }
  if (multilevel) {
    grid <- expand.grid(
      m = m,
      level = proj_levels,
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
    grid <- grid[order(match(grid$level, proj_levels), grid$m), , drop = FALSE]
    row_m <- grid$m
    row_level <- grid$level
  } else {
    row_m <- m
    row_level <- NULL
  }
  # Single-level: `level` is NA and ignored by the estimand builder (recycled).
  levels_arg <- if (is.null(row_level)) NA_character_ else row_level
  estimands <- Map(make_estimand, row_m, levels_arg)
  points <- vapply(
    estimands,
    function(e) icc_point(x$components, e),
    numeric(1)
  )
  # The projection band follows the fitted object's `ci_method` (M18 Slice 4,
  # ADR-028). A bootstrap fit reprojects its stored resample components across every
  # `m` (reusing the SAME resamples that produced the reported interval, so the band
  # is coherent with it and needs no re-draw or seed). A Monte-Carlo fit draws one
  # sample from the parameter covariance, reused across every m (and level). An older
  # bootstrap object without a `boot` slot falls back to the Monte-Carlo band.
  boot_band <- identical(x$ci$method, "bootstrap") && !is.null(x$boot)
  if (boot_band) {
    bc <- x$boot$components
    intervals <- lapply(
      estimands,
      function(e) two_sided_interval(icc_point(bc, e), conf_level)
    )
  } else {
    components <- mc_components(x$mc, mc_samples = mc_samples, seed = seed)
    intervals <- lapply(
      estimands,
      function(e) mc_interval(components, e, conf_level)
    )
  }

  tbl <- tibble::tibble(
    m = row_m,
    index = vapply(estimands, `[[`, character(1), "label"),
    estimate = points,
    std.error = vapply(intervals, `[[`, numeric(1), "std.error"),
    conf.low = vapply(intervals, `[[`, numeric(1), "conf.low"),
    conf.high = vapply(intervals, `[[`, numeric(1), "conf.high")
  )
  # Multilevel projects one curve per level, so a `level` column disambiguates the
  # shared index label (e.g. ICC(A,3) at subject vs. cluster).
  if (multilevel) {
    tbl <- tibble::add_column(tbl, level = row_level, .after = "m")
  }

  structure(
    tbl,
    class = c("icc_dstudy", class(tbl)),
    icc_type = type,
    icc_raters = raters,
    icc_design_label = icc_design_label(x$design),
    multilevel = multilevel,
    conf.level = conf_level,
    # The projection band follows the fit's `ci_method` (M18 Slice 4): a bootstrap
    # fit gets a bootstrap-reprojected band, otherwise Monte-Carlo (ADR-025/028).
    method = if (boot_band) "bootstrap" else "montecarlo",
    samples = if (boot_band) length(x$boot$components[[1L]]) else mc_samples,
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
  # icc_design_label is multilevel-aware; older objects fall back to the phrase.
  label <- attr(x, "icc_design_label")
  if (is.null(label)) {
    label <- icc_design_phrase(attr(x, "icc_type"), attr(x, "icc_raters"))
  }
  header <- sprintf("# D-study projection: %s", label)
  meta <- sprintf(
    "Observed raters: %d | CI: %s%% %s (%d draws)",
    attr(x, "k_observed"),
    ci_pct,
    attr(x, "method"),
    attr(x, "samples")
  )
  # Multilevel projects one curve per level, so a level column disambiguates the m
  # rows (the same index label appears at subject and cluster).
  if (isTRUE(attr(x, "multilevel"))) {
    rows <- sprintf(
      "  %-8s %5s  %8s   [%s, %s]",
      x$level,
      format(x$m, trim = TRUE),
      formatC(x$estimate, format = "f", digits = 3),
      formatC(x$conf.low, format = "f", digits = 3),
      formatC(x$conf.high, format = "f", digits = 3)
    )
    table <- c(
      sprintf(
        "  %-8s %5s  %8s   %s",
        "level",
        "m",
        "estimate",
        paste0(ci_pct, "% CI")
      ),
      rows
    )
  } else {
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
  }
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
  out <- tibble::tibble(
    m = x$m,
    index = x$index,
    estimate = x$estimate,
    std.error = x$std.error,
    conf.low = x$conf.low,
    conf.high = x$conf.high,
    conf.level = attr(x, "conf.level"),
    method = attr(x, "method")
  )
  # Carry the level column for a multilevel projection (subject/cluster curves).
  if (isTRUE(attr(x, "multilevel"))) {
    out <- tibble::add_column(out, level = x$level, .after = "m")
  }
  out
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
