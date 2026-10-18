# The warning on intervals near 1 (D-054, D-056) -------------------------------
#
# On a glmmTMB or lme4 fit, `mc_ci()` and `bootstrap_ci()` warn with class
# `intraclass_unresolved_interval` when the lower limit of an interval they
# return is above 1 - 1e-12/d, where d is the largest error divisor of the
# interval's estimand, and return the intervals unchanged. Fired at the
# reducers with stub engines (GP9), on the stub shapes of
# test-glmmtmb-false-zero.R. Each component pair below gives one interval:
# `wide` varies across draws; `near` and `near2` are 1 - u with u spread over
# [0, 1e-13], so their lower limits lie within 1e-13 of 1; `inner` is 1 - w
# with w spread over [4e-13, 5e-13], so its lower limit lies between 1e-13 and
# 1e-12 from 1; `mid` is 1 - v with v spread over [2e-12, 2.5e-12], so its
# lower limit lies just below 1 - 1e-12; `flat` is 1 on every draw, so its two
# limits are equal. The averaged stubs take the divisors of real estimands:
# `x3n` spread over [1.5e-12, 1.8e-12] and divided by 3 puts a lower limit
# between 1 - 1e-12 and 1 - 1e-12/3; `x3w` spread over [3e-13, 6e-13] puts
# one above 1 - 1e-12/3 when divided by 3, and above 1 - 1e-12/6 when divided
# by 6; `e6n` spread over
# [1.32e-12, 1.68e-12] and divided by 6 puts one between 1 - 1e-12/3 and
# 1 - 1e-12/6.

ui_estimand <- function(signal, error, label = "ICC(A,1)") {
  list(signal = signal, error = error, error_divisors = list(1), label = label)
}
ui_wide <- ui_estimand("subject", "residual", "ICC(C,1)")
ui_near <- ui_estimand("t", "u")
ui_near2 <- ui_estimand("t", "u2", "ICC(C,k)")
ui_inner <- ui_estimand("t", "w")
ui_mid <- ui_estimand("t", "v")
ui_flat <- ui_estimand("t", "z")

# A production estimand with its signal and error read from stub components,
# so its divisors, label, level and occasions are the ones `icc()` uses.
ui_remap <- function(est, signal, error) {
  est$signal <- signal
  est$error <- error
  est
}
# One-way ICC(k) over 3 ratings: error divisor 3.
ui_d3 <- icc_estimand(unit = "average", k_eff = 3, oneway = TRUE)
ui_d3_inner <- ui_remap(ui_d3, "t", "x3n")
ui_d3_near <- ui_remap(ui_d3, "t", "x3w")
# Two-way ICC(A,k) over 3 raters and 2 occasions: error divisors 3, 3 and 6.
ui_d6 <- icc_estimand(
  type = "agreement",
  unit = "average",
  k_eff = 3,
  replicates = TRUE,
  occasions = "average",
  n_o = 2
)
ui_d6_inner <- ui_remap(ui_d6, "t", c("z", "z", "e6n"))
ui_d6_near <- ui_remap(ui_d6, "t", c("z", "z", "x3w"))
# Two rows that share the label ICC(A,1): by level, and by occasion count.
ui_ml <- function(level, error) {
  ui_remap(
    icc_estimand(type = "agreement", multilevel = TRUE, level = level),
    "t",
    error
  )
}
ui_occ <- function(occasions, error) {
  ui_remap(
    icc_estimand(type = "agreement", replicates = TRUE, occasions = occasions),
    "t",
    error
  )
}

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
        w = 4e-13 + 1e-13 * stats::pnorm(par[1, ]),
        v = 2e-12 + 5e-13 * stats::pnorm(par[1, ]),
        z = rep(0, n),
        x3n = 1.5e-12 + 3e-13 * stats::pnorm(par[1, ]),
        x3w = 3e-13 + 3e-13 * stats::pnorm(par[1, ]),
        e6n = 1.32e-12 + 3.6e-13 * stats::pnorm(par[1, ]),
        big = 1 + exp(par[2, ])
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
        w = seq(4e-13, 5e-13, length.out = n),
        v = seq(2e-12, 2.5e-12, length.out = n),
        z = rep(0, n),
        x3n = seq(1.5e-12, 1.8e-12, length.out = n),
        x3w = seq(3e-13, 6e-13, length.out = n),
        e6n = seq(1.32e-12, 1.68e-12, length.out = n),
        big = seq(1, 3, length.out = n)
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

test_that("a near-1 interval on glmmTMB and lme4 fits warns once and is reported (D-054, D-056 AC1, AC3)", {
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
      # The value is the one returned with the helper replaced by one that
      # returns its input and signals nothing.
      local({
        local_mocked_bindings(
          warn_unresolved_interval = function(intervals, estimands, engine) {
            invisible(intervals)
          }
        )
        bare <- ui_run(fn, engine, list(ui_wide, ui_near))
        expect_length(bare$warnings, 0L)
        expect_identical(out$value, bare$value, info = info)
      })
      msg <- ui_message(out$warnings[[1]])
      expect_match(
        msg,
        "1 interval has a lower limit near 1: ICC(A,1).",
        fixed = TRUE
      )
      expect_no_match(msg, "ICC(C,1)", fixed = TRUE)
      expect_match(
        msg,
        "divided by the number of ratings, or effective ratings, it averages",
        fixed = TRUE
      )
      expect_match(msg, "almost no residual variation", fixed = TRUE)
      expect_match(msg, "intraclass_unresolved_interval", fixed = TRUE)
    }
  }
})

test_that("two near-1 intervals after a wide one give one warning that counts and names both (D-054, D-056 AC1, AC3)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      out <- ui_run(fn, engine, list(ui_wide, ui_near, ui_near2))
      expect_length(out$warnings, 1L)
      expect_gt(out$value[[3]]$conf.low, 1 - 1e-12)
      msg <- ui_message(out$warnings[[1]])
      expect_match(
        msg,
        "2 intervals have a lower limit near 1: ICC(A,1) and ICC(C,k).",
        fixed = TRUE
      )
      expect_no_match(msg, "ICC(C,1)", fixed = TRUE)
    }
  }
})

# The bound divided by d (D-056) ------------------------------------------------

test_that("the stubs take the error divisors of real estimands (D-056 AC1)", {
  expect_identical(ui_d3$error_divisors, 3)
  expect_identical(ui_d6$error_divisors, c(3, 3, 6))
})

# Runs one reducer on a wide interval and `est`, and checks that the lower
# limit of `est` lies inside (lo, hi), at least 1e-15 from each end, and that
# the call warned `warned` times.
ui_band <- function(est, lo, hi, warned) {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      info <- paste(engine, fn)
      out <- ui_run(fn, engine, list(ui_wide, est))
      low <- out$value[[2]]$conf.low
      expect_gt(low, lo + 1e-15, label = info)
      expect_lt(low, hi - 1e-15, label = info)
      expect_length(out$warnings, warned)
      # The value is the one returned with the helper replaced by one that
      # returns its input and signals nothing.
      local({
        local_mocked_bindings(
          warn_unresolved_interval = function(intervals, estimands, engine) {
            invisible(intervals)
          }
        )
        expect_identical(
          ui_run(fn, engine, list(ui_wide, est))$value,
          out$value,
          info = info
        )
      })
    }
  }
}

test_that("with d = 3, a lower limit between 1 - 1e-12 and 1 - 1e-12/3 does not warn (D-056 AC1)", {
  ui_band(ui_d3_inner, 1 - 1e-12, 1 - 1e-12 / 3, 0L)
})

test_that("with d = 3, a lower limit above 1 - 1e-12/3 warns (D-056 AC1)", {
  ui_band(ui_d3_near, 1 - 1e-12 / 3, 1, 1L)
})

test_that("with divisors 3, 3 and 6, a lower limit between 1 - 1e-12/3 and 1 - 1e-12/6 does not warn (D-056 AC1)", {
  ui_band(ui_d6_inner, 1 - 1e-12 / 3, 1 - 1e-12 / 6, 0L)
})

test_that("with divisors 3, 3 and 6, a lower limit above 1 - 1e-12/6 warns (D-056 AC1)", {
  ui_band(ui_d6_near, 1 - 1e-12 / 6, 1, 1L)
})

test_that("the message tells a firing row from a non-firing row of the same label (D-056 AC3)", {
  pairs <- list(
    level = list(
      fire = ui_ml("cluster", c("z", "u")),
      quiet = ui_ml("subject", c("z", "big")),
      fire_name = "ICC(A,1) at the cluster level",
      quiet_name = "ICC(A,1) at the subject level"
    ),
    occasions = list(
      fire = ui_occ(2, c("z", "z", "u")),
      quiet = ui_occ(1, c("z", "z", "big")),
      fire_name = "ICC(A,1) over 2 occasions",
      quiet_name = "ICC(A,1) over 1 occasion"
    )
  )
  for (p in pairs) {
    expect_identical(p$fire$label, p$quiet$label)
    for (engine in c("glmmTMB", "lme4")) {
      for (fn in c("mc", "boot")) {
        out <- ui_run(fn, engine, list(p$quiet, p$fire))
        expect_length(out$warnings, 1L)
        msg <- ui_message(out$warnings[[1]])
        expect_match(msg, p$fire_name, fixed = TRUE)
        expect_no_match(msg, p$quiet_name, fixed = TRUE)
      }
    }
  }
})

test_that("a lower limit between 1e-13 and 1e-12 from 1 warns (D-054 AC1)", {
  for (engine in c("glmmTMB", "lme4")) {
    for (fn in c("mc", "boot")) {
      out <- ui_run(fn, engine, list(ui_wide, ui_inner))
      expect_length(out$warnings, 1L)
      # The case sits inside the bound, away from 1.
      expect_gt(out$value[[2]]$conf.low, 1 - 1e-12)
      expect_lt(out$value[[2]]$conf.low, 1 - 1e-13)
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

# Through icc() (D-054, D-056 AC2) ----------------------------------------------
#
# Whether a fit on these frames returns a result or aborts depends on the engine
# and the platform (GP9), so each call asserts the rule: an abort carries
# `intraclass_singular_fit`, and a result warns exactly when one of its tidy()
# lower limits lies above 1 - 1e-12/d, d as `ui_row_d()` gives it. The floors
# over each grid keep the rule from passing on aborts alone.

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
    near_flat = list(data = near_flat, args = list(model = "oneway"), k = 3),
    additive = list(data = additive, args = list(model = "twoway"), k = 2),
    noisy = list(data = noisy, args = list(model = "twoway"), k = 3)
  )
}

# Two frames the engines resolve: rater noise SD 1e-6, and the same noise on 2
# occasions per cell. At the settings of `ui_icc()`, no row lies within
# 1e-12/d of 1, and on some calls an average row lies within 1e-12 of 1: every
# call on the first frame, glmmTMB bootstrap on the second (D-056, M164 work
# log).
ui_frames_resolved <- function() {
  noisy6 <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-6)
    g
  })
  replicated6 <- with_rng_seed(1, {
    g <- expand.grid(
      subject = factor(1:20),
      rater = factor(1:3),
      occasion = 1:2
    )
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-6)
    g
  })
  list(
    noisy6 = list(data = noisy6, args = list(model = "twoway"), k = 3),
    replicated6 = list(
      data = replicated6,
      args = list(occasions = c("single", "average")),
      k = 3
    )
  )
}

# The d of each `tidy()` row: the frame's rater count for an average-rater row,
# times the row's occasion count where it has one.
ui_row_d <- function(tidied, k) {
  d <- ifelse(grepl("k)", tidied$term, fixed = TRUE), k, 1)
  d * ifelse(is.na(tidied$occasions), 1, tidied$occasions)
}

# One icc() call. Returns the result or the error, and the number of
# `intraclass_unresolved_interval` warnings it signaled. Other warnings and
# messages are muffled.
ui_icc <- function(frame, engine, method) {
  n_warned <- 0L
  res <- tryCatch(
    withCallingHandlers(
      rlang::inject(icc(
        frame$data,
        score,
        subject = subject,
        rater = rater,
        !!!frame$args,
        engine = engine,
        ci_method = method,
        mc_samples = 500L,
        boot_samples = 30L,
        seed = 1
      )),
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

# Runs every frame of `frames` on both engines under both methods and asserts
# the rule on each call. Returns, per call that returned a result, whether it
# warned and whether a row lay between 1 - 1e-12 and 1 - 1e-12/d.
ui_grid <- function(frames) {
  seen <- list()
  for (nm in names(frames)) {
    for (engine in c("glmmTMB", "lme4")) {
      for (method in c("montecarlo", "bootstrap")) {
        info <- paste(nm, engine, method)
        out <- ui_icc(frames[[nm]], engine, method)
        if (inherits(out$result, "error")) {
          expect_s3_class(out$result, "intraclass_singular_fit")
          expect_identical(out$n_warned, 0L, info = info)
          next
        }
        expect_s3_class(out$result, "intraclass_icc")
        tidied <- tidy(out$result)
        lower <- tidied$conf.low
        bound <- 1e-12 / ui_row_d(tidied, frames[[nm]]$k)
        near <- any(is.finite(lower) & lower > 1 - bound)
        expect_identical(out$n_warned, as.integer(near), info = info)
        seen[[info]] <- c(
          warned = out$n_warned > 0L,
          between = any(lower > 1 - 1e-12 & lower <= 1 - bound)
        )
      }
    }
  }
  seen
}

test_that("icc() warns exactly when a row lies within 1e-12/d of 1 (D-054, D-056 AC2)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  seen <- ui_grid(ui_frames())
  # The rule is not met by aborts alone: some call warns.
  expect_true(any(vapply(seen, `[[`, logical(1), "warned")))
})

test_that("rows within 1e-12 of 1 but not within 1e-12/d give no warning on resolved data (D-056 AC2)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  seen <- ui_grid(ui_frames_resolved())
  # Some call reaches the case the scaled bound exists for: a row between
  # 1 - 1e-12 and 1 - 1e-12/d, with no warning.
  expect_true(any(vapply(
    seen,
    function(s) s[["between"]] && !s[["warned"]],
    logical(1)
  )))
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
      # A result came back, so the count below is not met by an abort.
      expect_s3_class(out$result, "intraclass_icc")
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
