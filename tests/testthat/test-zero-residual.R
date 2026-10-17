# Two-way data whose residual is exactly zero (D-053) --------------------------
#
# Scores that vary only by rater, or that are exactly a subject value plus a
# rater value, leave the residual variance at zero while scores still vary
# within subjects, so D-052's input check does not refuse them. On such data
# the glmmTMB and lme4 engines raised their own errors, which carry no package
# class. icc() now re-raises those as `intraclass_singular_fit`. Each call of
# the grid must return a result or abort with that class.

zr_frame <- function(n, k, shape) {
  d <- expand.grid(subject = seq_len(n), rater = seq_len(k))
  rater_value <- seq(0, 1, length.out = k)[d$rater]
  # Fixed subject values with no RNG, distinct for every n used here.
  subject_value <- round(2 * sin(seq_len(n)), 3)[d$subject]
  data.frame(
    subject = factor(d$subject),
    rater = factor(d$rater),
    score = rater_value + if (shape == "additive") subject_value else 0
  )
}

zr_grid <- function() {
  expand.grid(
    n = c(3L, 5L, 12L),
    k = c(2L, 3L, 5L),
    shape = c("rater", "additive"),
    engine = c("glmmTMB", "lme4"),
    ci_method = c("montecarlo", "bootstrap"),
    stringsAsFactors = FALSE
  )
}

# The outcome of one call: "result", the class vector of an error, or NULL when
# the call neither returned a result nor raised an error.
zr_outcome <- function(row) {
  d <- zr_frame(row$n, row$k, row$shape)
  res <- tryCatch(
    suppressWarnings(suppressMessages(icc(
      d,
      score = score,
      subject = subject,
      rater = rater,
      engine = row$engine,
      ci_method = row$ci_method,
      mc_samples = 500L,
      boot_samples = 30L,
      seed = 1
    ))),
    error = function(e) e
  )
  if (inherits(res, "intraclass_icc")) {
    "result"
  } else if (inherits(res, "error")) {
    res
  } else {
    NULL
  }
}

test_that("zero-residual two-way data return a result or a classed singular-fit abort (AC1)", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  grid <- zr_grid()
  expect_identical(nrow(grid), 72L)
  bad <- character(0)
  n_abort <- 0L
  for (i in seq_len(nrow(grid))) {
    row <- grid[i, ]
    out <- zr_outcome(row)
    label <- sprintf(
      "n=%d k=%d %s %s %s",
      row$n,
      row$k,
      row$shape,
      row$engine,
      row$ci_method
    )
    if (identical(out, "result")) {
      next
    }
    if (inherits(out, "intraclass_singular_fit")) {
      n_abort <- n_abort + 1L
      next
    }
    if (is.null(out)) {
      bad <- c(bad, paste0(label, ": no result and no error"))
      next
    }
    bad <- c(
      bad,
      sprintf(
        "%s: <%s> %s",
        label,
        paste(class(out), collapse = "/"),
        conditionMessage(out)
      )
    )
  }
  expect(
    length(bad) == 0L,
    paste(c("Unclassed outcomes:", bad), collapse = "\n")
  )
  # The grid reaches the degenerate path, so the check above is not vacuous.
  expect_gt(n_abort, 0L)
})

# The re-raise at the engine dispatch (AC2) ------------------------------------
#
# Each engine function is replaced by a stub that raises a given error, so the
# tests check the handler, not whether a real fit fails.

# An error in the shape of lme4's C++ exceptions: not an rlang error.
zr_cpp_error <- function(msg) {
  structure(
    class = c("Rcpp::exception", "C++Error", "error", "condition"),
    list(message = msg, call = NULL)
  )
}

zr_call <- function(engine, model = "twoway") {
  rlang::catch_cnd(
    suppressWarnings(icc(
      sf_ratings_long(),
      score = score,
      subject = subject,
      rater = rater,
      model = model,
      engine = engine,
      mc_samples = 200L,
      seed = 1
    )),
    classes = "error"
  )
}

test_that("an unclassed engine error is re-raised as a singular fit (AC2)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # One glmmTMB function on the two-way branch, one lme4 function on the
  # one-way branch; each raises a base simpleError and a C++-style error.
  cases <- list(
    list(engine = "glmmTMB", model = "twoway", fn = "fit_glmmtmb"),
    list(engine = "lme4", model = "oneway", fn = "fit_lme4_oneway")
  )
  for (case in cases) {
    errors <- list(
      simpleError(paste(case$engine, "stub simple failure")),
      zr_cpp_error(paste(case$engine, "stub C++ failure"))
    )
    for (err in errors) {
      stub <- rlang::set_names(list(function(...) stop(err)), case$fn)
      cnd <- local({
        rlang::inject(local_mocked_bindings(!!!stub))
        zr_call(case$engine, case$model)
      })
      expect_s3_class(cnd, "intraclass_singular_fit")
      expect_s3_class(cnd, "intraclass_error")
      expect_identical(cnd$parent, err)
      msg <- cli::ansi_strip(conditionMessage(cnd))
      expect_match(
        msg,
        paste("The", case$engine, "engine could not fit"),
        fixed = TRUE
      )
      expect_match(msg, conditionMessage(err), fixed = TRUE)
    }
  }
})

test_that("classed errors and other engines pass the re-raise unchanged (AC2)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  # A package error from an engine function keeps its own class.
  local({
    local_mocked_bindings(
      fit_glmmtmb = function(...) {
        abort_unidentified("stub unidentified design")
      }
    )
    cnd <- zr_call("glmmTMB")
    expect_s3_class(cnd, "intraclass_unidentified")
    expect_false(inherits(cnd, "intraclass_singular_fit"))
    expect_null(cnd$parent)
  })
  # An rlang error, such as a missing optional package, keeps its own class.
  local({
    local_mocked_bindings(
      fit_lme4 = function(...) {
        rlang::abort("stub missing package", class = "zr_stub_rlang_error")
      }
    )
    cnd <- zr_call("lme4")
    expect_s3_class(cnd, "zr_stub_rlang_error")
    expect_false(inherits(cnd, "intraclass_singular_fit"))
  })
  # The lavaan engine is outside the handler: its plain error is not re-raised.
  local({
    err <- simpleError("lavaan stub failure")
    local_mocked_bindings(fit_lavaan = function(...) stop(err))
    cnd <- zr_call("lavaan")
    expect_identical(class(cnd), class(err))
    expect_identical(conditionMessage(cnd), "lavaan stub failure")
  })
})
