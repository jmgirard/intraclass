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

#' Warn with a classed intraclass condition
#'
#' The warning counterpart of `abort_intraclass()`: all warnings go through
#' `cli::cli_warn()` with a classed condition (PRINCIPLES.md #8 — no bare
#' `warning()`). Every classed warning subclasses `"intraclass_warning"`, so a
#' caller can silence the family with `withCallingHandlers()` / `suppressWarnings()`
#' or match a specific subclass.
#'
#' @param message A character vector; formatted with [cli::cli_warn()] styling.
#' @param class Character. Condition subclass(es), prepended to
#'   `"intraclass_warning"`.
#' @param ... Passed to [cli::cli_warn()].
#' @param .envir The environment for message interpolation.
#' @keywords internal
#' @noRd
warn_intraclass <- function(
  message,
  class = NULL,
  ...,
  .envir = rlang::caller_env()
) {
  cli::cli_warn(
    message,
    class = c(class, "intraclass_warning"),
    ...,
    .envir = .envir
  )
}

#' Warn that fixed raters forgo generalization; random is best practice
#'
#' Fired when `raters = "fixed"` is chosen. Fixed raters is well-posed (a valid
#' number is still returned), so this is a warning, not an `abort_*()`
#' (PRINCIPLES.md #5 governs ill-posed designs). Classed `intraclass_fixed_raters`
#' so a genuine fixed-rater user can suppress it by class (M2 spec §3, ADR-006).
#'
#' @keywords internal
#' @noRd
warn_fixed_raters <- function(.envir = rlang::caller_env()) {
  warn_intraclass(
    c(
      "Modeling raters as {.strong fixed} restricts inference to exactly these \\
       raters; you cannot generalize to other raters.",
      i = "For interrater reliability, the two-way {.strong random} model \\
           ({.code raters = \"random\"}) is the recommended default \\
           (ten Hove et al. 2024; McGraw & Wong 1996, Case 2).",
      i = "Use {.val fixed} only when these are the entire population of raters \\
           you will ever use."
    ),
    class = "intraclass_fixed_raters",
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
