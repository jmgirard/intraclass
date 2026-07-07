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
# set, `unit` the averaging divisor, `raters` the design interpretation. Each
# entry names the signal component, the error components, and the labels.
#
#   * type   = "agreement" counts the rater main effect as error;
#              "consistency" drops it (M2 spec §2).
#   * raters = "random" (two-way random, Case 2) vs "fixed" (two-way mixed,
#              Case 3). On the BALANCED data this milestone targets, this is a
#              label/interpretation layer only: the point estimate and CI are
#              identical either way (M2 spec §3, ADR-006). It changes the design
#              phrase and the Shrout & Fleiss equivalent, not the arithmetic.
icc_estimand <- function(
  type = "agreement",
  unit = "single",
  raters = "random"
) {
  type <- rlang::arg_match(type, c("agreement", "consistency"))
  unit <- rlang::arg_match(unit, c("single", "average"))
  raters <- rlang::arg_match(raters, c("random", "fixed"))

  error <- switch(
    type,
    agreement = c("rater", "residual"),
    consistency = "residual"
  )

  letter <- switch(type, agreement = "A", consistency = "C")
  index <- switch(unit, single = "1", average = "k")
  label <- sprintf("ICC(%s,%s)", letter, index)

  list(
    label = label,
    sf_label = sf_label(type, raters, index),
    signal = "subject",
    error = error,
    unit = unit,
    type = type,
    raters = raters
  )
}

# Shrout & Fleiss (1979) equivalent label, or NA when there is no canonical SF
# form. SF named only two of the four two-way combinations: ICC(2,.) is
# two-way-random absolute agreement and ICC(3,.) is two-way-mixed consistency
# (M2 spec §5). The other two (consistency+random, agreement+fixed) are
# McGraw-Wong extensions with no SF label.
sf_label <- function(type, raters, index) {
  case <- if (type == "agreement" && raters == "random") {
    "2"
  } else if (type == "consistency" && raters == "fixed") {
    "3"
  } else {
    return(NA_character_)
  }
  sprintf("ICC(%s,%s)", case, index)
}

# Human-readable design phrase for the report header (M2 spec §5).
icc_design_phrase <- function(type, raters) {
  design <- switch(raters, random = "two-way random", fixed = "two-way mixed")
  error <- switch(type, agreement = "absolute agreement", consistency = type)
  sprintf("%s, %s", design, error)
}

# Compute a single ICC point value from named variance components and an estimand.
# `divisor` is 1 for a single rater and k (the number of raters) for the average
# of k raters; averaging over k raters divides every error component by k while
# leaving the signal untouched (estimand-spec §2).
icc_point <- function(components, estimand, k) {
  signal <- components[[estimand$signal]]
  # Element-wise across the error components, so this works for both the scalar
  # point estimate and a vector of Monte-Carlo draws (Reduce("+"), not sum(),
  # which would collapse the draws).
  error <- Reduce(`+`, components[estimand$error])
  divisor <- if (estimand$unit == "average") k else 1
  signal / (signal + error / divisor)
}
