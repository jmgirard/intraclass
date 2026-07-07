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

# The set of estimands M1 can produce, keyed by the McGraw & Wong (1996) label.
# `unit` selects among these; `type` selects the error set. Each entry names the
# signal component, the error components, and how the averaging divisor is formed.
icc_estimand <- function(type = "agreement", unit = "single") {
  type <- rlang::arg_match(type, "agreement")
  unit <- rlang::arg_match(unit, c("single", "average"))

  # Absolute agreement counts the rater main effect as error; consistency (M2)
  # would drop "rater" here.
  error <- switch(type, agreement = c("rater", "residual"))

  label <- switch(unit, single = "ICC(A,1)", average = "ICC(A,k)")

  list(
    label = label,
    signal = "subject",
    error = error,
    unit = unit,
    type = type
  )
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
