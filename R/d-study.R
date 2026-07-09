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
#' @section Within-cell replicate fits:
#' For a within-cell replicate fit (more than one rating per subject-by-rater cell,
#' where the residual splits into the subject-by-rater interaction and pure error),
#' `d_study()` projects the **rater count `m`**, holding the number of occasions
#' `n_o` at the fitted value: the rater and interaction terms divide by `m`, pure
#' error by `m * n_o`. The result gains an `occasions` column, one reliability curve
#' per occasion setting on the fit (`occasions = "single"` and/or `"average"`), so at
#' `m` = the observed rater count each curve matches the fitted `ICC(*,k)` for that
#' setting. Multilevel replicate fits project the subject level across occasion
#' settings and the cluster level single-occasion (occasion averaging touches only
#' pure error, which is not in the cluster-level error set). Projecting the occasion
#' count itself is not yet supported; **ragged** replicate fits are refused (the
#' occasion-averaged ragged divisor is an open modeling question).
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
  type <- x$design$type
  raters <- x$design$raters
  oneway <- identical(x$design$model, "oneway")
  multilevel <- isTRUE(x$design$multilevel)
  # Within-cell replicate fits (M17 Slice 3; M20) split the residual into the
  # interaction sigma^2_sr and pure error sigma^2_e, so the projected error set needs
  # PER-COMPONENT divisors: the rater and interaction terms divide by the projected
  # rater count `m`, pure error by `m * n_o`. The estimand already carries
  # `error_divisors` (M17, `icc_estimand()`), so projection is just that divisor change
  # applied at a numeric `unit = m` -- no new machinery (M22, ADR-032). The occasion
  # count `n_o` is held at the fitted value; an occasion projection is a separate
  # deferred facet (M17 §7). Two compound corners stay deferred (#5): a MULTILEVEL
  # replicate fit is projected by Slice 2 (guarded here in Slice 1), and a RAGGED
  # replicate fit needs an effective-n_o divisor that is itself open research
  # (M20/ADR-030) -- refuse loudly rather than project a guessed divisor (#4).
  replicates <- isTRUE(x$design$replicates)
  if (replicates && !isTRUE(x$design$balanced)) {
    abort_unsupported(c(
      "D-study projection is not supported off a ragged within-cell replicate fit.",
      i = "Projecting the mean of unequal per-cell replicate counts needs an \\
           effective-n_o divisor that is an open modeling question (M20; ADR-030).",
      i = "Refit with balanced, complete replicated data to project rater counts."
    ))
  }
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
  make_estimand <- function(mm, lv, oc) {
    if (ml_oneway) {
      icc_estimand(unit = mm, oneway = TRUE, multilevel = TRUE, level = lv)
    } else if (multilevel) {
      # A multilevel replicate fit (M22 Slice 2) projects the subject level across each
      # occasion setting (`oc` rescales pure error); the cluster error set has no
      # pure-error term, so it is projected single-occasion (oc = 1, a no-op there).
      icc_estimand(
        type = type,
        unit = mm,
        raters = raters,
        multilevel = TRUE,
        level = lv,
        replicates = replicates,
        occasions = if (replicates) oc else "single"
      )
    } else if (oneway) {
      icc_estimand(unit = mm, oneway = TRUE)
    } else {
      # A replicate fit projects at each occasion setting on the fit; `oc` is the
      # numeric occasion divisor (1 or n_o), which rescales only pure error (M22).
      icc_estimand(
        type = type,
        unit = mm,
        raters = raters,
        replicates = replicates,
        occasions = if (replicates) oc else "single"
      )
    }
  }
  # A replicate fit projects one curve per distinct occasion setting it carries (pure
  # error is divided by `m * n_o`); a non-replicate fit carries a single NA placeholder.
  proj_occ <- if (replicates) sort(unique(x$estimates$occasions)) else NA_real_
  if (multilevel) {
    # Level x occasions x m. Occasion averaging rescales pure error, which lives in the
    # SUBJECT error set only (the cluster error set is cluster:rater), so the cluster
    # level is projected single-occasion (M22 Slice 2, mirroring icc()). A non-replicate
    # multilevel fit carries a single NA placeholder occasion.
    grid <- do.call(
      rbind,
      lapply(proj_levels, function(lv) {
        occ_lv <- if (!replicates) {
          NA_real_
        } else if (lv == "subject") {
          proj_occ
        } else {
          min(proj_occ)
        }
        expand.grid(
          m = m,
          level = lv,
          occ = occ_lv,
          KEEP.OUT.ATTRS = FALSE,
          stringsAsFactors = FALSE
        )
      })
    )
    ord <- if (replicates) {
      order(match(grid$level, proj_levels), grid$occ, grid$m)
    } else {
      order(match(grid$level, proj_levels), grid$m)
    }
    grid <- grid[ord, , drop = FALSE]
    row_m <- grid$m
    row_level <- grid$level
    row_occ <- if (replicates) grid$occ else NULL
  } else if (replicates) {
    grid <- expand.grid(
      m = m,
      occ = proj_occ,
      KEEP.OUT.ATTRS = FALSE,
      stringsAsFactors = FALSE
    )
    grid <- grid[order(grid$occ, grid$m), , drop = FALSE]
    row_m <- grid$m
    row_occ <- grid$occ
    row_level <- NULL
  } else {
    row_m <- m
    row_level <- NULL
    row_occ <- NULL
  }
  # Single-level/non-replicate: `level`/`occ` are NA and recycled/ignored by the
  # estimand builder.
  levels_arg <- if (is.null(row_level)) NA_character_ else row_level
  occ_arg <- if (is.null(row_occ)) NA_real_ else row_occ
  estimands <- Map(make_estimand, row_m, levels_arg, occ_arg)
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
  # shared index label (e.g. ICC(A,3) at subject vs. cluster). A replicate fit projects
  # one curve per occasion setting, so an `occasions` column disambiguates likewise (M22).
  if (multilevel) {
    tbl <- tibble::add_column(tbl, level = row_level, .after = "m")
  }
  if (replicates) {
    tbl <- tibble::add_column(tbl, occasions = row_occ, .after = "m")
  }

  structure(
    tbl,
    class = c("icc_dstudy", class(tbl)),
    icc_type = type,
    icc_raters = raters,
    icc_design_label = icc_design_label(x$design),
    multilevel = multilevel,
    replicates = replicates,
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
  # Assemble the display table one column at a time so the optional descriptor columns
  # compose: multilevel projects one curve per `level` (subject/cluster), a replicate
  # fit one curve per `occasions` setting, and a multilevel replicate fit both (M22).
  cols <- list()
  heads <- character()
  if (isTRUE(attr(x, "multilevel"))) {
    cols <- c(cols, list(as.character(x$level)))
    heads <- c(heads, "level")
  }
  if (isTRUE(attr(x, "replicates"))) {
    cols <- c(cols, list(format(x$occasions, trim = TRUE)))
    heads <- c(heads, "occ")
  }
  cols <- c(
    cols,
    list(
      format(x$m, trim = TRUE),
      formatC(x$estimate, format = "f", digits = 3),
      sprintf(
        "[%s, %s]",
        formatC(x$conf.low, format = "f", digits = 3),
        formatC(x$conf.high, format = "f", digits = 3)
      )
    )
  )
  heads <- c(heads, "m", "estimate", paste0(ci_pct, "% CI"))
  # Right-align each column to the wider of its header and its cells.
  widths <- vapply(
    seq_along(cols),
    function(j) max(nchar(heads[[j]]), nchar(cols[[j]])),
    integer(1)
  )
  row_line <- function(vals) {
    padded <- vapply(
      seq_along(vals),
      function(j) formatC(vals[[j]], width = widths[[j]]),
      character(1)
    )
    paste0("  ", paste(padded, collapse = "  "))
  }
  body <- vapply(
    seq_len(nrow(x)),
    function(i) row_line(vapply(cols, `[[`, character(1), i)),
    character(1)
  )
  c(header, meta, "", row_line(heads), body)
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
  # Carry the level column for a multilevel projection (subject/cluster curves) and the
  # occasions column for a replicate projection (one curve per occasion setting, M22).
  if (isTRUE(attr(x, "multilevel"))) {
    out <- tibble::add_column(out, level = x$level, .after = "m")
  }
  if (isTRUE(attr(x, "replicates"))) {
    out <- tibble::add_column(out, occasions = x$occasions, .after = "m")
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
