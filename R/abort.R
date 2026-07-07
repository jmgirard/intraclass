# Internal condition layer -----------------------------------------------------
#
# PRINCIPLES.md #8: all errors are raised with `rlang::abort()` carrying a
# classed condition and an actionable, `cli`-formatted message. No bare
# `stop()`/`warning()`. Every classed error subclasses "intraclass_error" so
# callers can catch the whole family with `tryCatch(intraclass_error = ...)`.
#
# PRINCIPLES.md #5: ill-posed designs fail loudly through this layer (e.g.
# `abort_unidentified()`), never by silently returning a plausible number.

#' Abort with a classed intraclass condition
#'
#' @param message A character vector; formatted with [cli::cli_abort()] styling
#'   (supports `{.arg }`, `{.val }`, etc.). Use a named vector for bullets.
#' @param class Character. Condition subclass(es), prepended to
#'   `"intraclass_error"`.
#' @param ... Passed to [cli::cli_abort()] (e.g. `call`, data to store on the
#'   condition).
#' @keywords internal
#' @noRd
abort_intraclass <- function(message,
                             class = NULL,
                             ...,
                             call = rlang::caller_env()) {
  cli::cli_abort(
    message,
    class = c(class, "intraclass_error"),
    ...,
    call = call
  )
}

#' Abort because a requested ICC is not identified by the supplied design
#'
#' The dedicated error for PRINCIPLES.md #5.
#'
#' @param message Character vector describing what could not be separated.
#' @keywords internal
#' @noRd
abort_unidentified <- function(message, ..., call = rlang::caller_env()) {
  abort_intraclass(
    message,
    class = "intraclass_unidentified",
    ...,
    call = call
  )
}
