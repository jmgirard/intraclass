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

# The outcome of one call: "result", the error object, or NULL when the call
# neither returned a result nor raised an error.
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
  n_reraised <- 0L
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
      # Only the engine-error re-raise sets a parent here; the older deferrals
      # (the lme4 singular-fit guard, the interval-time aborts) do not.
      if (!is.null(out$parent)) {
        n_reraised <- n_reraised + 1L
      }
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
  # The grid reaches the re-raise, so the check above is not vacuous.
  expect_gt(n_reraised, 0L)
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
      # Rendered as the user sees it (LESSONS, M93); the parent's message is
      # part of the rendered chain.
      msg <- cli::ansi_strip(cli::format_message(conditionMessage(cnd)))
      expect_false(grepl("\\", msg, fixed = TRUE))
      # The first line names the engine and no cause; a later bullet names one
      # possible cause (M168 AC4). `format_message()` joins the bullets into
      # one line, so the header is read as the start of the render, and as the
      # first line of the message that rlang prints.
      header <- paste("The", case$engine, "engine stopped with an error.")
      expect_true(startsWith(msg, paste0(header, " ")))
      expect_match(
        substring(msg, nchar(header) + 1L),
        "possible cause is a variance component that the data cannot identify",
        fixed = TRUE
      )
      expect_identical(
        strsplit(conditionMessage(cnd), "\n", fixed = TRUE)[[1]][1],
        header
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

# What the re-raise passes unchanged (D-059) ----------------------------------
#
# Under `options(warn = 2)` R turns a warning into a `simpleError`, and a deep
# recursion ends in an error of class `stackOverflowError`. Neither says
# anything about the data, so `reraise_engine_error()` passes both unchanged.

# icc() on the Shrout-Fleiss data at a given `warn` level. Every warning that
# reaches a handler around icc() is recorded. It is muffled only below
# `warn = 2`: a muffled warning is never converted, and the conversion is what
# the warn = 2 test reads. Returns the error, or NULL, and the recorded warning
# messages.
zr_warn_call <- function(engine, warn) {
  withr::local_options(warn = warn)
  seen <- character(0)
  cnd <- tryCatch(
    withCallingHandlers(
      {
        icc(
          sf_ratings_long(),
          score = score,
          subject = subject,
          rater = rater,
          engine = engine,
          mc_samples = 200L,
          seed = 1
        )
        NULL
      },
      warning = function(w) {
        seen <<- c(seen, conditionMessage(w))
        if (warn < 2) invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  list(cnd = cnd, seen = seen)
}

# The prefix R puts on a warning it converts, in the session's language.
zr_converted_prefix <- function() {
  gettext("(converted from warning) ", domain = "R")
}

test_that("under warn = 2, a fitting warning reaches the caller as R's converted error (M168 AC1)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  planted <- "planted engine warning"
  # glmmTMB holds the fit's warnings back and replays them through cli; lme4
  # passes them on through cli from the handler in `fit_lme4()`. Each plant
  # sits in the fit that the engine keeps. Each plant lasts for its own engine's
  # iteration only (`env`).
  reml <- glmmtmb_reml
  lmer <- lme4::lmer
  plants <- list(
    glmmTMB = function(env) {
      local_mocked_bindings(
        glmmtmb_reml = function(formula, data) {
          warning(planted)
          reml(formula, data)
        },
        .env = env
      )
    },
    lme4 = function(env) {
      local_mocked_bindings(
        lmer = function(...) {
          warning(planted)
          lmer(...)
        },
        .package = "lme4",
        .env = env
      )
    }
  )
  for (engine in names(plants)) {
    local({
      plants[[engine]](environment())
      out <- zr_warn_call(engine, warn = 2)
      expect_identical(
        class(out$cnd),
        c("simpleError", "error", "condition"),
        info = engine
      )
      msg <- conditionMessage(out$cnd)
      expect_true(startsWith(msg, zr_converted_prefix()), info = engine)
      expect_match(msg, planted, fixed = TRUE, info = engine)
      # Control: at warn = 0 the same call returns a result and signals the
      # planted warning once.
      out <- zr_warn_call(engine, warn = 0)
      expect_null(out$cnd, info = engine)
      expect_identical(
        sum(grepl(planted, out$seen, fixed = TRUE)),
        1L,
        info = engine
      )
    })
  }
})

test_that("a stack-overflow error passes the re-raise unchanged (M168 AC2)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  overflows <- list(
    structure(
      class = c(
        "expressionStackOverflowError",
        "stackOverflowError",
        "error",
        "condition"
      ),
      list(message = "stub expression overflow", call = NULL)
    ),
    structure(
      class = c(
        "CStackOverflowError",
        "stackOverflowError",
        "error",
        "condition"
      ),
      list(message = "stub C stack overflow", call = NULL)
    )
  )
  cases <- list(
    list(engine = "glmmTMB", fn = "fit_glmmtmb"),
    list(engine = "lme4", fn = "fit_lme4")
  )
  for (case in cases) {
    for (err in overflows) {
      stub <- rlang::set_names(list(function(...) stop(err)), case$fn)
      cnd <- local({
        rlang::inject(local_mocked_bindings(!!!stub))
        zr_call(case$engine)
      })
      expect_identical(cnd, err)
    }
  }
})

test_that("other engine errors are still re-raised under warn = 0 and warn = 2 (M168 AC3)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  cases <- list(
    list(engine = "glmmTMB", fn = "fit_glmmtmb"),
    list(engine = "lme4", fn = "fit_lme4")
  )
  for (case in cases) {
    # No warning before the error.
    for (warn in c(0, 2)) {
      err <- simpleError(paste(case$engine, "stub failure"))
      stub <- rlang::set_names(list(function(...) stop(err)), case$fn)
      cnd <- local({
        rlang::inject(local_mocked_bindings(!!!stub))
        withr::local_options(warn = warn)
        zr_call(case$engine)
      })
      info <- paste(case$engine, "warn =", warn)
      expect_s3_class(cnd, "intraclass_singular_fit")
      expect_identical(cnd$parent, err, info = info)
    }
    # A warning with a NULL call that the caller's handler muffles is never
    # converted, so the error after it, also with a NULL call, is not R's
    # conversion and is still re-raised.
    err <- zr_cpp_error(paste(case$engine, "stub failure after a warning"))
    stub <- rlang::set_names(
      list(function(...) {
        rlang::warn("stub warning with no call")
        stop(err)
      }),
      case$fn
    )
    cnd <- local({
      rlang::inject(local_mocked_bindings(!!!stub))
      withr::local_options(warn = 2)
      zr_call(case$engine)
    })
    expect_s3_class(cnd, "intraclass_singular_fit")
    expect_identical(cnd$parent, err, info = case$engine)

    # An error whose message is R's conversion text for the muffled warning,
    # but whose call differs from the warning's, is still re-raised.
    err <- simpleError(
      sprintf(
        gettext("(converted from warning) %s", domain = "R"),
        "stub warning with no call"
      ),
      call = quote(zr_other_call())
    )
    stub <- rlang::set_names(
      list(function(...) {
        rlang::warn("stub warning with no call")
        stop(err)
      }),
      case$fn
    )
    cnd <- local({
      rlang::inject(local_mocked_bindings(!!!stub))
      withr::local_options(warn = 2)
      zr_call(case$engine)
    })
    expect_s3_class(cnd, "intraclass_singular_fit")
    expect_identical(cnd$parent, err, info = case$engine)

    # R shortens the converted text of a warning longer than
    # `getOption("warning.length")` bytes, so that conversion is re-raised.
    long <- strrep("a", getOption("warning.length") + 100L)
    stub <- rlang::set_names(
      list(function(...) warning(long)),
      case$fn
    )
    out <- local({
      rlang::inject(local_mocked_bindings(!!!stub))
      zr_warn_call(case$engine, warn = 2)
    })
    expect_s3_class(out$cnd, "intraclass_singular_fit")
    expect_identical(
      class(out$cnd$parent),
      c("simpleError", "error", "condition")
    )
    expect_true(
      startsWith(conditionMessage(out$cnd$parent), zr_converted_prefix()),
      info = case$engine
    )
  }
})
