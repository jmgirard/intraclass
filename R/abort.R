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
#' @param message A character vector, formatted with [cli::cli_abort()] styling
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
#' `cli::cli_warn()` with a classed condition (PRINCIPLES.md #8, no bare
#' `warning()`). Every classed warning subclasses `"intraclass_warning"`, so a
#' caller can silence the family with `withCallingHandlers()` or
#' `suppressWarnings()`, or match a specific subclass.
#'
#' @param message A character vector, formatted with [cli::cli_warn()] styling.
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

#' Warn that fixed raters forgo generalization, and random is best practice
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
       raters. You cannot generalize to other raters.",
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

#' Warn that rows with a missing score were dropped before fitting
#'
#' Fired when `icc()` removes rows whose `score` is `NA` (M105, D-022). A missing
#' score is a rating that did not happen, which is the incomplete design this
#' package already fits. So this is well-posed and returns a valid number,
#' making it a warning rather than an `abort_*()` (PRINCIPLES.md #5 governs
#' ill-posed designs). Classed `intraclass_dropped_rows` so a user working with
#' routinely-incomplete data can suppress this one warning by class without
#' silencing the rest, exactly as `warn_fixed_raters()` allows.
#'
#' @param n_dropped Integer count of removed rows.
#' @keywords internal
#' @noRd
warn_dropped_rows <- function(n_dropped, .envir = rlang::caller_env()) {
  warn_intraclass(
    c(
      "Dropped {.val {n_dropped}} row{?s} with a missing {.arg score}.",
      i = "The remaining ratings are analyzed as an incomplete design.",
      i = "Remove {cli::qty(n_dropped)}{?that row/those rows} yourself to \\
           silence this, or suppress the {.cls intraclass_dropped_rows} \\
           warning class."
    ),
    class = "intraclass_dropped_rows",
    .envir = environment()
  )
}

#' Abort because a decision axis does not apply to the chosen design
#'
#' Used by `choose_icc()` (M12, ADR-021): e.g. a `type`/`raters` answer supplied
#' for a one-way design, where there is no rater term to reason about. The axis is
#' not merely unimplemented (`abort_unsupported()`) nor a design-identifiability
#' failure (`abort_unidentified()`). It is meaningless for this design, so the
#' answer is rejected rather than silently ignored (PRINCIPLES.md #5). Classed
#' `intraclass_inapplicable`.
#'
#' @param message Character vector naming the inapplicable axis.
#' @keywords internal
#' @noRd
abort_inapplicable <- function(
  message,
  ...,
  call = rlang::caller_env(),
  .envir = rlang::caller_env()
) {
  abort_intraclass(
    message,
    class = "intraclass_inapplicable",
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

#' Re-raise an unclassed glmmTMB or lme4 engine error as a singular fit
#'
#' Evaluates `expr`, the engine dispatch of `icc()`. On the glmmTMB and lme4
#' engines, an error that is not an rlang error, raised anywhere in the engine
#' function, is re-raised as `intraclass_singular_fit`, with the original error
#' as its parent (D-053). Examples are lme4's C++ exceptions from the optimizer
#' and base `solve()` failures inside glmmTMB's `sdreport()`, and also errors
#' after the fit, such as reading the parameter covariance. The interval step
#' runs later, outside this handler. The package's and rlang's own errors, for
#' example the classed deferrals and a missing optional package, pass
#' unchanged. The handler matches no engine message text (D-022). An error that
#' an engine function catches itself, such as a failed second start, never
#' reaches it. As a calling handler it keeps the engine frames in the
#' backtrace, and warnings raised before the error are still raised before the
#' re-raised error. The lavaan engine re-raises errors from its own `lavaan()`
#' fit as a classed error, and brms is not covered.
#'
#' Two kinds of error say nothing about the data and pass unchanged (D-059).
#' The first is R's conversion of a warning under `options(warn = 2)` or above.
#' The handler records each warning it sees at that level, and an error whose
#' message is R's translated conversion text for the recorded warning, with the
#' warning's call, is that conversion. The text is R's, not an engine's. The
#' call alone does not tell it apart: a cli warning has a `NULL` call, and a
#' warning that a caller's handler muffles is never converted. The second is an
#' error of R's class `stackOverflowError`. An allocation failure and a bug in
#' package code are still re-raised, because R gives them a plain `simpleError`.
#'
#' @param engine The `engine` argument of `icc()`.
#' @param expr The engine dispatch, evaluated lazily.
#' @keywords internal
#' @noRd
reraise_engine_error <- function(engine, expr, call = rlang::caller_env()) {
  if (!engine %in% c("glmmTMB", "lme4")) {
    return(expr)
  }
  warned <- NULL
  withCallingHandlers(
    expr,
    warning = function(w) {
      if (getOption("warn") >= 2) {
        warned <<- w
      }
    },
    error = function(e) {
      if (
        inherits(e, c("rlang_error", "stackOverflowError")) ||
          is_converted_warning(e, warned)
      ) {
        return()
      }
      abort_intraclass(
        c(
          "The {.pkg {engine}} engine failed on these data.",
          i = "A variance component that the data cannot identify can cause \\
               this.",
          i = "Examples are scores that vary only by rater, and scores that \\
               are exactly a subject value plus a rater value.",
          i = "Inspect the data and check that {.arg score}, \\
               {.arg subject} and {.arg rater} name the intended columns."
        ),
        class = "intraclass_singular_fit",
        parent = e,
        call = call
      )
    }
  )
}

# Whether `e` is R's conversion of the warning `w` under `options(warn = 2)`:
# the same call, and the message R's own translated template gives (D-059).
is_converted_warning <- function(e, w) {
  if (is.null(w) || !identical(conditionCall(e), conditionCall(w))) {
    return(FALSE)
  }
  converted <- sprintf(
    gettext("(converted from warning) %s", domain = "R"),
    conditionMessage(w)
  )
  identical(conditionMessage(e), converted)
}
