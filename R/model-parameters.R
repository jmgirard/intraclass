# parameters::model_parameters() method for icc() results ---------------------
#
# S3 method for parameters::model_parameters (a Suggests generic), lazily
# registered in R/zzz.R like autoplot, so parameters is never required (D-051).
# It lives in its own file so that its roxygen block collates after icc()'s:
# the merged `?icc` page then keeps icc()'s arguments in signature order, with
# `ci` after them.

#' @param ci For `model_parameters()`: `NULL` (the default) or the fit's own
#'   confidence level. The table reports the interval the fit computed, so any
#'   other value is an error. Fit again with `icc(conf_level = )` for another
#'   level.
#' @rdname icc
# lintr does not see this as an S3 method (not a NAMESPACE export), so the
# `generic.class` dot and the method's length trip two name linters --
# suppressed here, not renamed, as for autoplot (R/autoplot.R).
# nolint start: object_name_linter, object_length_linter.
model_parameters.intraclass_icc <- function(model, ci = NULL, ...) {
  # nolint end
  # The table reports the interval the fit already computed. An interval at
  # another level needs a new fit, so a different `ci` fails loudly (#5) rather
  # than returning limits at a level the caller did not ask for.
  level <- model$ci$conf_level
  if (
    !is.null(ci) &&
      !(is.numeric(ci) && length(ci) == 1L && isTRUE(all.equal(ci, level)))
  ) {
    abort_intraclass(
      c(
        "{.arg ci} must equal the confidence level of the fit ({level}).",
        "i" = "Fit again with {.code icc(conf_level = )} for another level."
      )
    )
  }
  td <- tidy.intraclass_icc(model)
  out <- data.frame(
    Parameter = td$term,
    Type = td$type,
    Level = td$level,
    Occasions = td$occasions,
    SF_Index = td$sf_index,
    Coefficient = td$estimate,
    SE = td$std.error,
    CI = td$conf.level,
    CI_low = td$conf.low,
    CI_high = td$conf.high,
    Method = td$method,
    stringsAsFactors = FALSE
  )
  # Without a title, the parameters printer heads the table "Fixed Effects".
  attr(out, "title") <- "Intraclass correlation coefficients"
  attr(out, "ci") <- level
  class(out) <- c("parameters_model", "see_parameters_model", "data.frame")
  out
}
