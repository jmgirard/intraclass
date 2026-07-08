# Estimand representation ------------------------------------------------------
#
# PRINCIPLES.md #2: name the estimand before computing it. An ICC is represented
# as (signal component, {error component set}, averaging divisor) so that the
# family's "knobs" are data, not code paths (estimand-spec §5):
#   * agreement vs. consistency = whether the rater main effect is in the error
#     set (agreement includes it; consistency drops it);
#   * single vs. average        = averaging divisor 1 vs. k.
# This keeps M2 (consistency, fixed raters) a change of the error set / divisor
# rather than a rewrite.
#
# Variance components are named on the estimable, single-rating scale used
# throughout M1 (estimand-spec §1): "subject" (signal, sigma^2_s), "rater"
# (sigma^2_r), "residual" (sigma^2_res = sigma^2_sr + sigma^2_e, confounded).

# An estimand, keyed by the McGraw & Wong (1996) label. `type` selects the error
# set, `unit` (with `k_eff`) the averaging divisor, `raters` the design
# interpretation. Each entry names the signal component, the error components,
# the resolved averaging divisor, and the labels.
#
#   * type   = "agreement" counts the rater main effect as error;
#              "consistency" drops it (M2 spec §2).
#   * unit   = "single" (divisor 1), "average" (divisor k_eff, the effective
#              number of ratings per subject), or a numeric `m` -- a D-study
#              projection to the mean of `m` raters (divisor m; ROADMAP). The
#              divisor is resolved here from `unit` + `k_eff` and stored so
#              `icc_point()` needs no design context.
#   * raters = "random" (two-way random, Case 2) vs "fixed" (two-way mixed,
#              Case 3). On BALANCED data this is a label/interpretation layer for
#              the point estimate (M2 spec §3, ADR-006); on incomplete data the
#              fixed fit genuinely differs (ADR-008). It changes the design
#              phrase and the Shrout & Fleiss equivalent.
#   * level  = (multilevel only, M5 spec §3) "subject" (within-cluster, signal
#              sigma^2_{s:c}) vs "cluster" (between-cluster, signal sigma^2_c). At
#              the cluster level the residual slot of the error set is the
#              cluster x rater term. Multilevel ICCs have no Shrout & Fleiss form.
icc_estimand <- function(
  type = "agreement",
  unit = "single",
  raters = "random",
  k_eff = NA_real_,
  level = "subject",
  multilevel = FALSE,
  oneway = FALSE
) {
  type <- rlang::arg_match(type, c("agreement", "consistency"))
  raters <- rlang::arg_match(raters, c("random", "fixed"))
  level <- rlang::arg_match(level, c("subject", "cluster", "conflated"))
  index <- unit_index(unit)

  if (oneway) {
    # One-way random (Shrout & Fleiss Case 1, M6 spec §2/§3): the fit has NO rater
    # term, so the single confounded residual is the whole error set and there is
    # no agreement/consistency choice. McGraw & Wong label these single-argument
    # ICC(1)/ICC(k)/ICC(m); the SF equivalent is ICC(1,1)/ICC(1,k).
    #
    # The MULTILEVEL one-way (ten Hove et al. 2022 Design 3, raters nested in
    # subjects; estimand-spec M8 §3b) shares this shape -- signal sigma^2_{s:c},
    # error the confounded residual sigma^2_{r:s:c}, agreement-only -- but carries
    # a subject `level` and has no Shrout & Fleiss form.
    return(list(
      label = sprintf("ICC(%s)", index),
      sf_label = if (multilevel) NA_character_ else oneway_sf_label(index),
      signal = "subject",
      error = "residual",
      unit = unit,
      divisor = resolve_divisor(unit, k_eff),
      type = NA_character_,
      raters = "random",
      level = if (multilevel) level else NA_character_
    ))
  }

  if (multilevel && level == "conflated") {
    # Conflated single-level ICC (ten Hove et al. 2022, Eq. 14; M17 Slice 1): the
    # biased coefficient obtained by *ignoring* the cluster structure. Between- and
    # within-cluster subject variance are both folded into the signal, and all
    # three rater-related terms into the error. Agreement-only (guarded upstream);
    # a diagnostic contrast, not a recommended coefficient (spec M17-conflated-icc.md).
    signal <- c("cluster", "subject")
    error <- c("rater", "cluster_rater", "residual")
    sf <- NA_character_
  } else if (multilevel) {
    # Multilevel Design 1 (ten Hove et al. 2022, Table 3): the signal is the
    # subject- or cluster-level true-score variance, and the "residual" of the
    # error set is sigma^2_res at the subject level but sigma^2_{cr} (cluster x
    # rater) at the cluster level. Subject-level error is structurally identical
    # to the single-level estimand (M5 §3a). No canonical SF label.
    signal <- switch(level, subject = "subject", cluster = "cluster")
    resid <- switch(level, subject = "residual", cluster = "cluster_rater")
    error <- switch(type, agreement = c("rater", resid), consistency = resid)
    sf <- NA_character_
  } else {
    signal <- "subject"
    error <- switch(
      type,
      agreement = c("rater", "residual"),
      consistency = "residual"
    )
    sf <- sf_label(type, raters, index)
  }

  letter <- switch(type, agreement = "A", consistency = "C")
  label <- sprintf("ICC(%s,%s)", letter, index)

  list(
    label = label,
    sf_label = sf,
    signal = signal,
    error = error,
    unit = unit,
    divisor = resolve_divisor(unit, k_eff),
    type = type,
    raters = raters,
    level = if (multilevel) level else NA_character_
  )
}

# The averaging divisor for a unit: 1 for a single rater, `k_eff` for the
# "average" of the observed design, or the number itself for a numeric D-study
# projection to the mean of `m` raters (estimand-spec §2; M4.5 D-study spec).
resolve_divisor <- function(unit, k_eff) {
  if (is.numeric(unit)) {
    return(unit)
  }
  switch(unit, single = 1, average = k_eff)
}

# The label index for a unit: "1", "k", or the projected count as a string.
# Whole-number projections print without a trailing ".0" (e.g. "3", not "3.0").
unit_index <- function(unit) {
  if (is.numeric(unit)) {
    return(format(unit, trim = TRUE))
  }
  switch(unit, single = "1", average = "k")
}

# Shrout & Fleiss (1979) equivalent label, or NA when there is no canonical SF
# form. SF named only two of the four two-way combinations: ICC(2,.) is
# two-way-random absolute agreement and ICC(3,.) is two-way-mixed consistency
# (M2 spec §5). The other two (consistency+random, agreement+fixed) are
# McGraw-Wong extensions with no SF label.
sf_label <- function(type, raters, index) {
  # Shrout & Fleiss named only the single (index "1") and average (index "k")
  # forms; a numeric D-study projection ICC(A,3) is a McGraw-Wong extension with
  # no canonical SF label.
  if (!index %in% c("1", "k")) {
    return(NA_character_)
  }
  case <- if (type == "agreement" && raters == "random") {
    "2"
  } else if (type == "consistency" && raters == "fixed") {
    "3"
  } else {
    return(NA_character_)
  }
  sprintf("ICC(%s,%s)", case, index)
}

# Shrout & Fleiss (1979) equivalent for a one-way coefficient: SF named the single
# form ICC(1,1) and the average ICC(1,k); a numeric D-study projection has no
# canonical SF label (M6 spec §6).
oneway_sf_label <- function(index) {
  switch(index, "1" = "ICC(1,1)", "k" = "ICC(1,k)", NA_character_)
}

# Human-readable design phrase for the report header (M2 spec §5; M6 spec §6).
icc_design_phrase <- function(type, raters, oneway = FALSE) {
  if (oneway) {
    return("one-way random")
  }
  design <- switch(raters, random = "two-way random", fixed = "two-way mixed")
  error <- switch(type, agreement = "absolute agreement", consistency = type)
  sprintf("%s, %s", design, error)
}

# The full human-readable design label for an `icc` object, multilevel-aware: the
# two-way/one-way phrase, prefixed with the inferred multilevel design (ten Hove
# et al. 2022; spec M8 §4) when present. Shared by `format.icc` (report header)
# and `autoplot.icc` (plot title) so the two never drift.
icc_design_label <- function(design) {
  ow <- identical(design$model, "oneway")
  phrase <- icc_design_phrase(design$type, design$raters, oneway = ow)
  if (!isTRUE(design$multilevel)) {
    return(phrase)
  }
  ml_label <- switch(
    design$ml_design,
    nested_in_clusters = "multilevel (raters nested in clusters)",
    nested_in_subjects = "multilevel (raters nested in subjects)",
    "multilevel"
  )
  # Design 3 (raters nested in subjects) is the multilevel one-way (agreement-only);
  # the two-way agreement/consistency phrase does not apply.
  if (identical(design$ml_design, "nested_in_subjects")) {
    paste(ml_label, "absolute agreement")
  } else {
    paste(ml_label, phrase)
  }
}

# Ordered (label, variance) view of a fitted object's variance components,
# honouring the design variants: one-way and Design 3 confound the rater into the
# residual (`confounded = TRUE`, no rater bar); Design 2's rater slot holds the
# rater-in-cluster variance (labelled "rater:cluster"); Design 1 adds cluster and
# cluster:rater terms. Shared by `format.icc` (prose) and `autoplot.icc`
# (`what = "components"` bars) so the labels and ordering never drift.
icc_components_view <- function(x) {
  vc <- x$components
  ml <- isTRUE(x$design$multilevel)
  ow <- identical(x$design$model, "oneway")
  spec <- if (ml && is.null(vc$rater)) {
    # Design 3 (raters nested in subjects): rater confounded into residual.
    list(
      label = c("cluster", "subject", "residual"),
      variance = c(vc$cluster, vc$subject, vc$residual),
      confounded = TRUE
    )
  } else if (ml && is.null(vc$cluster_rater)) {
    # Design 2 (raters nested in clusters): the rater slot holds sigma^2_{r:c}.
    list(
      label = c("cluster", "subject", "rater:cluster", "residual"),
      variance = c(vc$cluster, vc$subject, vc$rater, vc$residual),
      confounded = FALSE
    )
  } else if (ml) {
    list(
      label = c("cluster", "subject", "rater", "cluster:rater", "residual"),
      variance = c(
        vc$cluster,
        vc$subject,
        vc$rater,
        vc$cluster_rater,
        vc$residual
      ),
      confounded = FALSE
    )
  } else if (ow) {
    # One-way: no rater term; the residual confounds rater with error.
    list(
      label = c("subject", "residual"),
      variance = c(vc$subject, vc$residual),
      confounded = TRUE
    )
  } else {
    list(
      label = c("subject", "rater", "residual"),
      variance = c(vc$subject, vc$rater, vc$residual),
      confounded = FALSE
    )
  }
  spec
}

# Compute a single ICC point value from named variance components and an estimand.
# The estimand's resolved `divisor` (1 for a single rater, k_eff for the average,
# or m for a D-study projection) divides every error component while leaving the
# signal untouched (estimand-spec §2).
icc_point <- function(components, estimand) {
  # Signal and error are both component *sets* (Reduce("+"), not sum(), so a
  # vector of Monte-Carlo draws is summed element-wise, not collapsed). The signal
  # is a single component for every classic ICC, but the conflated ICC (Eq. 14, M17)
  # sums the cluster and within-cluster subject variances, so it is a set too.
  signal <- Reduce(`+`, components[estimand$signal])
  error <- Reduce(`+`, components[estimand$error])
  signal / (signal + error / estimand$divisor)
}
