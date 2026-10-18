# The warning on intervals within 1e-12 of 1 (D-054) --------------------------
#
# On a glmmTMB or lme4 fit, `mc_ci()` and `bootstrap_ci()` warn with class
# `intraclass_unresolved_interval` when the lower limit of an interval they
# return is above 1 - 1e-12, and return the intervals unchanged. Fired at the
# reducers with stub engines (GP9), on the stub shapes of
# test-glmmtmb-false-zero.R. Each component pair below gives one interval:
# `wide` varies across draws; `near` and `near2` are 1 - u with u spread over
# [0, 1e-13], so their lower limits lie within 1e-13 of 1; `mid` is 1 - v with
# v spread over [2e-12, 2.5e-12], so its lower limit lies just below
# 1 - 1e-12; `flat` is 1 on every draw, so its two limits are equal.

ui_estimand <- function(signal, error) {
  list(signal = signal, error = error, error_divisors = list(1))
}
ui_wide <- ui_estimand("subject", "residual")
ui_near <- ui_estimand("t", "u")
ui_near2 <- ui_estimand("t", "u2")
ui_mid <- ui_estimand("t", "v")
ui_flat <- ui_estimand("t", "z")

ui_mc_stub <- function(engine) {
  list(
    engine = engine,
    estimate = c(a = 0, b = 0),
    vcov = diag(1, 2),
    to_components = function(par) {
      n <- ncol(par)
      list(
        subject = exp(par[1, ]),
        residual = exp(par[2, ]),
        t = rep(1, n),
        u = 1e-13 * stats::pnorm(par[1, ]),
        u2 = 1e-13 * stats::pnorm(par[2, ]),
        v = 2e-12 + 5e-13 * stats::pnorm(par[1, ]),
        z = rep(0, n)
      )
    }
  )
}

ui_boot_stub <- function(engine) {
  list(
    engine = engine,
    simulate_refit = function(n, seed = NULL) {
      rbind(
        subject = seq(1, 2, length.out = n),
        residual = seq(2, 1, length.out = n),
        t = rep(1, n),
        u = seq(0, 1e-13, length.out = n),
        u2 = seq(1e-13, 0, length.out = n),
        v = seq(2e-12, 2.5e-12, length.out = n),
        z = rep(0, n)
      )
    }
  )
}

ui_call <- function(fn, engine, estimands) {
  if (fn == "mc") {
    mc_ci(ui_mc_stub(engine), estimands, mc_samples = 200L, seed = 1)
  } else {
    bootstrap_ci(ui_boot_stub(engine), estimands, boot_samples = 50L)
  }
}

# Runs one reducer on a stub. Returns its value and every
# `intraclass_unresolved_interval` warning it signaled, each muffled.
ui_run <- function(fn, engine, estimands) {
  seen <- list()
  value <- withCallingHandlers(
    ui_call(fn, engine, estimands),
    intraclass_unresolved_interval = function(w) {
      seen[[length(seen) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = seen)
}

ui_message <- function(w) {
  cli::ansi_strip(cli::format_message(conditionMessage(w)))
}

test_that("a near-1 interval on glmmTMB and lme4 fits warns once and is reported (D-054 AC1, AC3)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      info <- paste(engine, fn)
      out <- ui_run(fn, engine, list(ui_wide, ui_near))
      expect_length(out$warnings, 1L)
      expect_s3_class(out$warnings[[1]], "intraclass_unresolved_interval")
      expect_s3_class(out$warnings[[1]], "intraclass_warning")
      # The near-1 interval is the one that fired it, and it is reported.
      expect_gt(out$value[[2]]$conf.low, 1 - 1e-12)
      expect_lt(out$value[[2]]$conf.low, out$value[[2]]$conf.high)
      # The value is the one returned with every warning muffled.
      muffled <- suppressWarnings(ui_run(fn, engine, list(ui_wide, ui_near)))
      expect_identical(out$value, muffled$value, info = info)
      msg <- ui_message(out$warnings[[1]])
      expect_match(msg, "1 interval has a lower limit within 1e-12 of 1")
      expect_match(msg, "almost no residual variation", fixed = TRUE)
      expect_match(msg, "intraclass_unresolved_interval", fixed = TRUE)
    }
  }
})

test_that("two near-1 intervals after a wide one give one warning that counts both (D-054 AC1, AC3)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      out <- ui_run(fn, engine, list(ui_wide, ui_near, ui_near2))
      expect_length(out$warnings, 1L)
      expect_gt(out$value[[3]]$conf.low, 1 - 1e-12)
      expect_match(
        ui_message(out$warnings[[1]]),
        "2 intervals have a lower limit within 1e-12 of 1"
      )
    }
  }
})

test_that("a lower limit just below 1 - 1e-12 does not warn (D-054 AC1)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      out <- ui_run(fn, engine, list(ui_wide, ui_mid))
      expect_length(out$warnings, 0L)
      # The control sits near the bound, on its far side.
      expect_lte(out$value[[2]]$conf.low, 1 - 1e-12)
      expect_gt(out$value[[2]]$conf.low, 1 - 1e-11)
    }
  }
})

test_that("a near-1 interval on a lavaan fit does not warn (D-054 AC1)", {
  for (fn in c("mc", "boot")) {
    out <- ui_run(fn, "lavaan", list(ui_wide, ui_near))
    expect_length(out$warnings, 0L)
    expect_gt(out$value[[2]]$conf.low, 1 - 1e-12)
  }
})

# Through icc() (D-054 AC2) -----------------------------------------------------
#
# Whether a fit on these frames returns a result or aborts depends on the engine
# and the platform (GP9), so each call asserts the rule: an abort carries
# `intraclass_singular_fit`, and a result warns exactly when one of its tidy()
# lower limits lies above 1 - 1e-12. The floor of one warning over the grid
# keeps the rule from passing on aborts alone.

ui_frames <- function() {
  # M161's near-flat frame: each score its subject's index, 1e-12 added to one.
  near_flat <- expand.grid(rater = 1:3, subject = 1:10)
  near_flat <- data.frame(
    subject = factor(near_flat$subject),
    rater = factor(near_flat$rater),
    score = as.numeric(near_flat$subject)
  )
  near_flat$score[1] <- near_flat$score[1] + 1e-12
  # The exactly additive frame of test-zero-residual.R, 3 subjects, 2 raters.
  g <- expand.grid(subject = 1:3, rater = 1:2)
  additive <- data.frame(
    subject = factor(g$subject),
    rater = factor(g$rater),
    score = seq(0, 1, length.out = 2)[g$rater] +
      round(2 * sin(1:3), 3)[g$subject]
  )
  # Rater noise with SD 1e-7 of a unit score spread.
  noisy <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-7)
    g
  })
  list(
    near_flat = list(data = near_flat, model = "oneway"),
    additive = list(data = additive, model = "twoway"),
    noisy = list(data = noisy, model = "twoway")
  )
}

# One icc() call. Returns the result or the error, and the number of
# `intraclass_unresolved_interval` warnings it signaled. Other warnings and
# messages are muffled.
ui_icc <- function(frame, engine, method) {
  n_warned <- 0L
  res <- tryCatch(
    withCallingHandlers(
      icc(
        frame$data,
        score,
        subject = subject,
        rater = rater,
        model = frame$model,
        engine = engine,
        ci_method = method,
        mc_samples = 500L,
        boot_samples = 30L,
        seed = 1
      ),
      warning = function(w) {
        if (inherits(w, "intraclass_unresolved_interval")) {
          n_warned <<- n_warned + 1L
        }
        invokeRestart("muffleWarning")
      },
      message = function(m) invokeRestart("muffleMessage")
    ),
    error = function(e) e
  )
  list(result = res, n_warned = n_warned)
}

test_that("icc() warns on a near-1 interval exactly when one is reported (D-054 AC2)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  frames <- ui_frames()
  warned <- 0L
  for (nm in names(frames)) {
    for (engine in c("glmmTMB", "lme4")) {
      for (method in c("montecarlo", "bootstrap")) {
        info <- paste(nm, engine, method)
        out <- ui_icc(frames[[nm]], engine, method)
        if (inherits(out$result, "error")) {
          expect_s3_class(out$result, "intraclass_singular_fit")
          expect_identical(out$n_warned, 0L, info = info)
        } else {
          expect_s3_class(out$result, "intraclass_icc")
          lower <- tidy(out$result)$conf.low
          near <- any(is.finite(lower) & lower > 1 - 1e-12)
          expect_identical(out$n_warned, as.integer(near), info = info)
          warned <- warned + out$n_warned
        }
      }
    }
  }
  expect_gte(warned, 1L)
})

# The near-perfect-agreement frame of test-glmmtmb-false-zero.R (rater noise SD
# 1e-5), built the same way. Its intervals near 1 are correct and their lower
# limits lie between about 5e-11 and 2e-10 from 1, outside 1e-12, so no call
# warns.
test_that("rater noise of 1e-5 gives no near-1 warning on either engine (D-054 AC2)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  d <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-5)
    g
  })
  frame <- list(data = d, model = "twoway")
  for (engine in c("glmmTMB", "lme4")) {
    for (method in c("montecarlo", "bootstrap")) {
      out <- ui_icc(frame, engine, method)
      expect_identical(out$n_warned, 0L, info = paste(engine, method))
    }
  }
})

test_that("equal limits abort before any near-1 warning (D-054 AC1)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      # The first of the two conditions signaled is caught, so a warning
      # signaled before the abort would be the one caught here.
      cnd <- rlang::catch_cnd(
        ui_call(fn, engine, list(ui_wide, ui_near, ui_flat)),
        classes = c("error", "intraclass_unresolved_interval")
      )
      expect_s3_class(cnd, "intraclass_zero_width_interval")
    }
  }
})
