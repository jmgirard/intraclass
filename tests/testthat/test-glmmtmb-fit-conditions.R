# Which glmmTMB fit's warnings and messages reach the user (M165) -------------
#
# `fit_glmmtmb_ml_model()` can run two fits: the first, and a second start when
# the first leaves an SD near zero (D-048). Only the fit it keeps describes the
# result, so only that fit's warnings and messages are passed on. A first fit
# that fails shows what it held, then its error, except that under
# `options(warn = 2)` or above its held warnings are not replayed, so the fit's
# own error is the error the user gets.

# A stub fit that signals two warnings and two messages, one of each with a
# brace, then returns. `tag` makes each fit's texts distinct.
fc_stub <- function(tag, objective) {
  function(...) {
    warning(sprintf("%s warning one", tag))
    message(sprintf("%s message one", tag))
    warning(sprintf("%s warning {two}", tag))
    message(sprintf("%s message {two}", tag))
    list(fit = list(objective = objective), sdr = list(pdHess = TRUE))
  }
}

fc_texts <- function(tag) {
  sprintf(
    c("%s warning one", "%s message one", "%s warning {two}", "%s message {two}"),
    tag
  )
}

# Run the fit with both seams stubbed and return every warning and message
# text that reached the caller, in order.
fc_seen <- function(o1, o2) {
  local_mocked_bindings(
    glmmtmb_reml = fc_stub("first", o1),
    glmmtmb_retry_start = function(fit, data) list(),
    glmmtmb_second_fit = fc_stub("second", o2)
  )
  seen <- character(0)
  withCallingHandlers(
    fit_glmmtmb_ml_model(score ~ 1, data.frame(score = 1:3)),
    warning = function(w) {
      seen <<- c(seen, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      seen <<- c(seen, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  seen
}

fc_count <- function(seen, text) {
  sum(vapply(seen, grepl, logical(1), pattern = text, fixed = TRUE))
}

test_that("only the kept fit's warnings and messages reach the user (M165 AC3)", {
  cases <- list(
    list(o2 = 100 - 1e-3, kept = "second", dropped = "first"),
    list(o2 = 100 + 1, kept = "first", dropped = "second")
  )
  for (case in cases) {
    seen <- fc_seen(100, case$o2)
    for (text in fc_texts(case$kept)) {
      expect_identical(fc_count(seen, text), 1L, info = text)
    }
    for (text in fc_texts(case$dropped)) {
      expect_identical(fc_count(seen, text), 0L, info = text)
    }
  }
})

test_that("a failed first fit shows its held message and warning before its error (M165 AC3)", {
  local_mocked_bindings(
    glmmtmb_reml = function(formula, data) {
      message("planted message")
      warning("planted warning")
      stop("planted failure")
    }
  )
  withr::local_options(warn = 0)
  seen <- character(0)
  cnd <- tryCatch(
    withCallingHandlers(
      fit_glmmtmb_ml_model(score ~ 1, data.frame(score = 1:3)),
      warning = function(w) {
        seen <<- c(seen, conditionMessage(w))
        invokeRestart("muffleWarning")
      },
      message = function(m) {
        seen <<- c(seen, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) e
  )
  expect_identical(fc_count(seen, "planted message"), 1L)
  expect_identical(fc_count(seen, "planted warning"), 1L)
  expect_identical(conditionMessage(cnd), "planted failure")
})

# icc() on a first fit that warns and then fails. Records every warning,
# message and error that reaches a handler around icc(). Warnings are muffled
# only when `muffle` is TRUE: under warn = 2 a muffled warning could not turn
# into the error, which is the behavior under test.
fc_icc <- function(warn, muffle) {
  local_mocked_bindings(
    glmmtmb_reml = function(formula, data) {
      warning("planted WTEXT")
      stop("planted failure")
    }
  )
  withr::local_options(warn = warn)
  seen <- character(0)
  cnd <- tryCatch(
    withCallingHandlers(
      icc(scale_two_way(11L), score, subject, rater, seed = 1),
      warning = function(w) {
        seen <<- c(seen, conditionMessage(w))
        if (muffle) invokeRestart("muffleWarning")
      },
      message = function(m) {
        seen <<- c(seen, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) e
  )
  list(cnd = cnd, seen = seen)
}

test_that("under warn = 2 or 3, a failed first fit's own error is the error (M165 AC4)", {
  skip_if_not_installed("glmmTMB")
  for (warn in c(2, 3)) {
    out <- fc_icc(warn, muffle = FALSE)
    info <- paste("warn =", warn)
    expect_s3_class(out$cnd, "intraclass_singular_fit")
    expect_identical(conditionMessage(out$cnd$parent), "planted failure")
    expect_identical(fc_count(out$seen, "planted WTEXT"), 0L, info = info)
    expect_false(grepl("planted WTEXT", conditionMessage(out$cnd), fixed = TRUE))
  }
})

test_that("under warn = 0 or 1, the held warning shows once before the same error (M165 AC4)", {
  skip_if_not_installed("glmmTMB")
  for (warn in c(0, 1)) {
    out <- fc_icc(warn, muffle = TRUE)
    info <- paste("warn =", warn)
    expect_s3_class(out$cnd, "intraclass_singular_fit")
    expect_identical(conditionMessage(out$cnd$parent), "planted failure")
    expect_identical(fc_count(out$seen, "planted WTEXT"), 1L, info = info)
  }
})
