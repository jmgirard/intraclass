# Internal condition layer -----------------------------------------------------
#
# PRINCIPLES.md #8: all errors are raised with `rlang::abort()` carrying a
# classed condition and an actionable, `cli`-formatted message. No bare
# `stop()`/`warning()`. Every classed error subclasses "intraclass_error" so
# callers can catch the whole family with `tryCatch(intraclass_error = ...)`.
#
# PRINCIPLES.md #5: ill-posed designs fail loudly through this layer (e.g.
# `abort_unidentified()`), never by silently returning a plausible number.
#
# `.envir` is threaded through so cli interpolates message variables (e.g.
# `{arg}`) in the frame that built the message, even when a wrapper forwards it.

#' Abort with a classed intraclass condition
#'
#' @param message A character vector; formatted with [cli::cli_abort()] styling
#'   (supports `{.arg }`, `{.val }`, etc.). Use a named vector for bullets.
#' @param class Character. Condition subclass(es), prepended to
#'   `"intraclass_error"`.
#' @param ... Passed to [cli::cli_abort()].
#' @param call,.envir The environment for the reported call and for message
#'   interpolation.
#' @keywords internal
#' @noRd
abort_intraclass <- function(
  message,
  class = NULL,
  ...,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  cli::cli_abort(
    message,
    class = c(class, "intraclass_error"),
    ...,
    call = call,
    .envir = .envir
  )
}

#' Abort because a requested ICC is not identified by the supplied design
#'
#' The dedicated error for PRINCIPLES.md #5.
#'
#' @param message Character vector describing what could not be separated.
#' @keywords internal
#' @noRd
abort_unidentified <- function(
  message,
  ...,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  abort_intraclass(
    message,
    class = "intraclass_unidentified",
    ...,
    call = call,
    .envir = .envir
  )
}

#' Abort because a requested option is valid but not yet implemented
#'
#' Distinct from `abort_unidentified()` (which is about the *design*): this marks
#' a knob whose value is planned for a later milestone, so users get a forward
#' pointer rather than a silent wrong path (PRINCIPLES.md #5, #17).
#'
#' @param message Character vector naming the unsupported option.
#' @keywords internal
#' @noRd
abort_unsupported <- function(
  message,
  ...,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  abort_intraclass(
    message,
    class = "intraclass_unsupported",
    ...,
    call = call,
    .envir = .envir
  )
}
