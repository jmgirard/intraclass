# A glmmTMB variance stuck at zero: the second start (M158, D-048) --------------
#
# glmmTMB's own start puts every log-SD at 0 (an SD of 1). On scores multiplied by
# 1000 that start can stall the optimizer at a false optimum with the subject
# variance at 0, which icc() printed as ICC 0.000 [0.000, 0.000] (the user report
# behind PR #176). PR #176 replaced that start with a data-scaled one
# (glmmtmb_start()). These tests plant the old start again by masking
# glmmtmb_start() to return NULL, so they check the second start on its own:
# a fit that leaves an SD below 1e-2 of sd(score) is refit once from another start
# and the second fit is kept only when its REML objective is lower by more than
# 1e-6, or when only its objective is finite (D-049).
#
# Two oracles: the lme4 engine (a different optimizer on the same REML criterion)
# and scale invariance (the same fit on the unscaled scores).

fz_seeds <- 1:40
fz_scale <- 1000

# The three models of the grid, as icc() arguments and as the glmmTMB formula
# the engine fits for them.
fz_models <- list(
  fixed = list(
    args = list(raters = "fixed", type = "agreement"),
    formula = score ~ 1 + rater + (1 | subject)
  ),
  random = list(
    args = list(),
    formula = score ~ 1 + (1 | subject) + (1 | rater)
  ),
  oneway = list(
    args = list(model = "oneway"),
    formula = score ~ 1 + (1 | subject)
  )
)

fz_first_icc <- function(d, args, engine = "glmmTMB") {
  fit <- suppressMessages(suppressWarnings(do.call(
    icc,
    c(
      list(d, quote(score), subject = quote(subject), rater = quote(rater)),
      args,
      list(engine = engine, mc_samples = 200L, seed = 1)
    )
  )))
  stats::setNames(fit$estimates$estimate[1], fit$estimates$index[1])
}

# The lme4 oracle. On a singular (boundary) fit the lme4 engine refuses with
# `intraclass_singular_fit` and reports no ICC, so that seed has no oracle value
# and falls outside the grid's domain (NA). Any other error still fails the test.
fz_lme4_icc <- function(d, args) {
  tryCatch(
    fz_first_icc(d, args, engine = "lme4"),
    intraclass_singular_fit = function(e) NA_real_
  )
}

# The first ICC of each model -- ICC(A,1) for the two two-way models, ICC(1)
# one-way -- read from the engine fit's variance components, so that no interval
# is computed (on a false zero icc() can abort at the interval stage, or report
# an interval of near-zero width).
# Each is the subject component over the sum of all components.
fz_engines <- list(
  fixed = function(d) fit_glmmtmb_fixed(d),
  random = function(d) fit_glmmtmb(d),
  oneway = function(d) fit_glmmtmb_oneway(d)
)

fz_engine_icc <- function(d, m) {
  comp <- suppressMessages(suppressWarnings(fz_engines[[m]](d)$components))
  comp$subject / sum(unlist(comp))
}

# Both engines' REML objectives on the same scale: glmmTMB's minimized
# `fit$fit$objective` and lme4's `REMLcrit() / 2` (measured to agree to 10
# decimals on the fixed-rater model, M158 T2).
fz_objectives <- function(d, m) {
  f <- fz_models[[m]]$formula
  g <- suppressMessages(suppressWarnings(fit_glmmtmb_ml_model(f, d)))
  l <- suppressMessages(suppressWarnings(lme4::lmer(f, data = d, REML = TRUE)))
  c(glmmTMB = g$fit$objective, lme4 = lme4::REMLcrit(l) / 2)
}

test_that("the second start reaches the REML optimum on a planted false zero (AC1)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_on_cran()
  local_mocked_bindings(glmmtmb_start = function(formula, data) NULL)

  for (m in names(fz_models)) {
    in_domain <- 0L
    for (seed in fz_seeds) {
      small <- scale_two_way(seed)
      big <- transform(small, score = score * fz_scale)
      ref <- fz_lme4_icc(big, fz_models[[m]]$args)
      if (!isTRUE(ref > 0.01)) {
        next
      }
      in_domain <- in_domain + 1L
      got <- fz_first_icc(big, fz_models[[m]]$args)
      unscaled <- fz_first_icc(small, fz_models[[m]]$args)
      info <- paste0("model ", m, ", seed ", seed)
      expect_identical(names(got), names(ref), info = info)
      # Absolute 1e-4 against lme4; where a variance sits at the boundary the
      # likelihood is flat and the two optimizers stop up to 1.3e-4 apart (random
      # raters, seed 5), so 1e-3 is accepted only where both objectives agree.
      gap <- abs(unname(got) - unname(ref))
      if (gap >= 1e-4) {
        obj <- fz_objectives(big, m)
        expect_lt(abs(obj[["glmmTMB"]] - obj[["lme4"]]), 1e-6, label = info)
        expect_lt(gap, 1e-3, label = info)
      }
      expect_lt(abs(unname(got) - unname(unscaled)), 1e-5, label = info)
    }
    expect_gt(in_domain, 0L, label = paste("in-domain seeds, model", m))
  }
})

test_that("with the second start disabled, the planted frame reaches the false zero (AC1 control)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_on_cran()
  local_mocked_bindings(
    glmmtmb_start = function(formula, data) NULL,
    glmmtmb_retry_start = function(fit, data) NULL
  )

  for (m in names(fz_models)) {
    reached <- vapply(
      fz_seeds,
      function(seed) {
        big <- transform(scale_two_way(seed), score = score * fz_scale)
        ref <- fz_lme4_icc(big, fz_models[[m]]$args)
        isTRUE(ref > 0.01) && fz_engine_icc(big, m) < 1e-6
      },
      logical(1)
    )
    expect_true(any(reached), label = paste("false zero reached, model", m))
  }
})

test_that("the kept fit's REML objective never exceeds the first fit's (AC2)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()
  local_mocked_bindings(glmmtmb_start = function(formula, data) NULL)

  second_won <- FALSE
  for (m in names(fz_models)) {
    for (seed in fz_seeds) {
      big <- transform(scale_two_way(seed), score = score * fz_scale)
      f <- fz_models[[m]]$formula
      first <- suppressWarnings(glmmtmb_reml(f, big))
      kept <- suppressMessages(suppressWarnings(fit_glmmtmb_ml_model(f, big)))
      info <- paste0("model ", m, ", seed ", seed)
      expect_lte(kept$fit$objective, first$fit$objective, label = info)
      if (kept$fit$objective < first$fit$objective - 1e-6) {
        second_won <- TRUE
      }
    }
  }
  expect_true(second_won)
})

test_that("a second fit that raises an error leaves the first fit in place (AC2)", {
  skip_if_not_installed("glmmTMB")
  local_mocked_bindings(
    glmmtmb_start = function(formula, data) NULL,
    glmmtmb_second_fit = function(formula, data, start) stop("planted failure")
  )

  # Seed 3 is a fixed-rater seed where the first fit stalls at zero, so the
  # second start fires (plan probe, 2026-10-06).
  big <- transform(scale_two_way(3L), score = score * fz_scale)
  f <- fz_models$fixed$formula
  first <- suppressWarnings(glmmtmb_reml(f, big))
  kept <- suppressMessages(suppressWarnings(fit_glmmtmb_ml_model(f, big)))
  expect_false(is.null(glmmtmb_retry_start(first, big)))
  expect_identical(kept$fit$objective, first$fit$objective)
  expect_identical(kept$fit$par, first$fit$par)
})

# Which fit is kept, at the seams: the first and second fits are stubs that carry
# only an objective and a label, so the keep rule is read with no optimizer.
fz_keep <- function(o1, o2) {
  local_mocked_bindings(
    glmmtmb_reml = function(formula, data) {
      list(fit = list(objective = o1), which = "first")
    },
    glmmtmb_retry_start = function(fit, data) list(),
    glmmtmb_second_fit = function(formula, data, start) {
      list(fit = list(objective = o2), which = "second")
    }
  )
  fit_glmmtmb_ml_model(score ~ 1, data.frame(score = 1:3))$which
}

test_that("the second fit is kept only past the 1e-6 margin, or over a non-finite first fit (AC2)", {
  expect_identical(fz_keep(100, 100 - 5e-7), "first")
  expect_identical(fz_keep(100, 100 - 2e-6), "second")
  expect_identical(fz_keep(100, 100 + 1), "first")
  expect_identical(fz_keep(100, NaN), "first")
  expect_identical(fz_keep(NaN, 100), "second")
  expect_identical(fz_keep(NaN, NaN), "first")
})

test_that("a first fit that warns and then errors signals its warning before the error (AC2)", {
  local_mocked_bindings(
    glmmtmb_reml = function(formula, data) {
      warning("planted warning")
      stop("planted failure")
    }
  )
  seen <- character(0)
  messages <- character(0)
  cnd <- tryCatch(
    withCallingHandlers(
      fit_glmmtmb_ml_model(score ~ 1, data.frame(score = 1:3)),
      warning = function(w) {
        seen <<- c(seen, "warning")
        messages <<- c(messages, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      seen <<- c(seen, "error")
      e
    }
  )
  expect_identical(seen, c("warning", "error"))
  expect_match(messages, "planted warning", fixed = TRUE)
  expect_match(conditionMessage(cnd), "planted failure", fixed = TRUE)
})

test_that("a first fit's error reaches the caller from inside the fit, unchanged (M158 review)", {
  local_mocked_bindings(
    glmmtmb_reml = function(formula, data) stop("planted failure")
  )
  # The caller's handler sees the stack at the original signal: the failing fit
  # is still on it, as it was before the second start existed.
  in_fit <- FALSE
  cnd <- tryCatch(
    withCallingHandlers(
      fit_glmmtmb_ml_model(score ~ 1, data.frame(score = 1:3)),
      error = function(e) {
        calls <- vapply(sys.calls(), function(x) deparse(x)[1], character(1))
        in_fit <<- any(grepl("^glmmtmb_reml\\(", calls))
      }
    ),
    error = function(e) e
  )
  expect_true(in_fit)
  expect_s3_class(cnd, "simpleError")
  expect_identical(conditionMessage(cnd), "planted failure")
})

test_that("a fitting warning that contains braces reaches the user verbatim (M158 review)", {
  expect_warning(
    glmmtmb_warn(list(simpleWarning("bad {brace} in a message"))),
    "bad {brace} in a message",
    fixed = TRUE
  )
})

test_that("the second start holds only finite values when a fixed effect is not finite (AC2)", {
  first <- list(
    fit = list(par = NULL),
    obj = list(
      env = list(
        parList = function(par) {
          list(beta = c(NaN, 1), theta = -50, betadisp = 0)
        }
      )
    )
  )
  start <- glmmtmb_retry_start(first, data.frame(score = c(1, 4, 9)))
  expect_false(is.null(start))
  expect_true(all(is.finite(unlist(start))))
})

# The refusal of equal limits (D-048, D-049) -------------------------------------
#
# Fired at the reducers with stub engines (GP9): `mc_ci()` and `bootstrap_ci()`
# each get draws on six components, where `wide` = subject / (subject +
# residual) varies across draws, `flat` = c / (c + z) is 1 on every draw, so its
# two limits are equal, and `tiny` = t / (t + u) is 1 - u with u spread over
# [0, 1e-10], so its interval is about 1e-10 wide. Two estimands, one with equal
# limits, check that the guard reads every reported interval; `tiny` checks that
# a narrow interval whose limits differ is reported.
fz_wide <- list(
  signal = "subject",
  error = "residual",
  error_divisors = list(1)
)
fz_flat <- list(signal = "c", error = "z", error_divisors = list(1))
fz_tiny <- list(signal = "t", error = "u", error_divisors = list(1))

fz_mc_stub <- function(engine) {
  list(
    engine = engine,
    estimate = c(a = 0, b = 0),
    vcov = diag(1, 2),
    to_components = function(par) {
      n <- ncol(par)
      list(
        subject = exp(par[1, ]),
        residual = exp(par[2, ]),
        c = rep(1, n),
        z = rep(0, n),
        t = rep(1, n),
        u = 1e-10 * stats::pnorm(par[1, ])
      )
    }
  )
}

fz_boot_stub <- function(engine) {
  list(
    engine = engine,
    simulate_refit = function(n, seed = NULL) {
      rbind(
        subject = seq(1, 2, length.out = n),
        residual = seq(2, 1, length.out = n),
        c = rep(1, n),
        z = rep(0, n),
        t = rep(1, n),
        u = seq(0, 1e-10, length.out = n)
      )
    }
  )
}

# A width that is above 0 and below the bound D-049 withdrew.
fz_expect_tiny <- function(iv) {
  width <- iv$conf.high - iv$conf.low
  expect_gt(width, 0)
  expect_lt(width, sqrt(.Machine$double.eps))
}

test_that("mc_ci() refuses equal limits on a glmmTMB fit only (AC3)", {
  expect_error(
    mc_ci(
      fz_mc_stub("glmmTMB"),
      list(fz_wide, fz_flat),
      mc_samples = 200L,
      seed = 1
    ),
    class = "intraclass_zero_width_interval"
  )
  cnd <- rlang::catch_cnd(mc_ci(
    fz_mc_stub("glmmTMB"),
    list(fz_wide, fz_flat),
    mc_samples = 200L,
    seed = 1
  ))
  expect_s3_class(cnd, "intraclass_singular_fit")
  # The message states what failed, never a cause the guard has not checked, and
  # says nothing about draws, which a bootstrap interval does not have.
  msg <- cli::ansi_strip(cli::format_message(conditionMessage(cnd)))
  expect_match(msg, "lower and upper limits are equal", fixed = TRUE)
  expect_false(grepl("draw", msg, fixed = TRUE))

  # The same equal limits on an lme4 fit are reported, not refused.
  out <- mc_ci(
    fz_mc_stub("lme4"),
    list(fz_wide, fz_flat),
    mc_samples = 200L,
    seed = 1
  )
  expect_identical(out[[2]]$conf.high - out[[2]]$conf.low, 0)
  # A glmmTMB interval about 1e-10 wide is reported, beside a wide one.
  ok <- mc_ci(
    fz_mc_stub("glmmTMB"),
    list(fz_wide, fz_tiny),
    mc_samples = 200L,
    seed = 1
  )
  expect_gt(ok[[1]]$conf.high - ok[[1]]$conf.low, 0.1)
  fz_expect_tiny(ok[[2]])
})

test_that("bootstrap_ci() refuses equal limits on a glmmTMB fit only (AC3)", {
  expect_error(
    bootstrap_ci(
      fz_boot_stub("glmmTMB"),
      list(fz_wide, fz_flat),
      boot_samples = 50L,
      call = rlang::current_env()
    ),
    class = "intraclass_zero_width_interval"
  )
  cnd <- rlang::catch_cnd(bootstrap_ci(
    fz_boot_stub("glmmTMB"),
    list(fz_wide, fz_flat),
    boot_samples = 50L,
    call = rlang::current_env()
  ))
  expect_s3_class(cnd, "intraclass_singular_fit")

  out <- bootstrap_ci(
    fz_boot_stub("lme4"),
    list(fz_wide, fz_flat),
    boot_samples = 50L
  )
  expect_identical(out[[2]]$conf.high - out[[2]]$conf.low, 0)
  ok <- bootstrap_ci(
    fz_boot_stub("glmmTMB"),
    list(fz_wide, fz_tiny),
    boot_samples = 50L
  )
  expect_gt(ok[[1]]$conf.high - ok[[1]]$conf.low, 0.1)
  fz_expect_tiny(ok[[2]])
})

# Near-perfect agreement: 20 subjects, 3 raters, rater error SD 1e-5. Some of
# its intervals near ICC 1 are narrower than sqrt(.Machine$double.eps) (the
# consistency ones under Monte Carlo, all four under bootstrap, M158 claim
# audit), but their limits differ, so neither method refuses them (M158 review pass 1, diff-bug
# #1). Another abort here is a platform fact, not this rule (GP9), so only the
# zero-width class is asserted; the widths or the class seen go in the info.
test_that("icc() does not refuse tight intervals of near-perfect agreement (AC3)", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()
  d <- with_rng_seed(1, {
    g <- expand.grid(subject = factor(1:20), rater = factor(1:3))
    g$score <- stats::rnorm(20)[g$subject] + stats::rnorm(nrow(g), 0, 1e-5)
    g
  })
  for (method in c("montecarlo", "bootstrap")) {
    res <- tryCatch(
      suppressMessages(suppressWarnings(icc(
        d,
        score,
        subject = subject,
        rater = rater,
        ci_method = method,
        mc_samples = 500L,
        boot_samples = 50L,
        seed = 1
      ))),
      error = function(e) e
    )
    seen <- if (inherits(res, "error")) {
      class(res)[1]
    } else {
      format(res$estimates$conf.high - res$estimates$conf.low, digits = 3)
    }
    expect_false(
      inherits(res, "intraclass_zero_width_interval"),
      info = paste0(method, ": ", paste(seen, collapse = " "))
    )
  }
})

# The overflow abort's remedy names no engine the call already used (M158) ------

fz_overflow_message <- function(engine) {
  cnd <- rlang::catch_cnd(
    mc_interval(
      list(subject = c(1, Inf), residual = c(1, 1)),
      icc_estimand(unit = "single", k_eff = 3, oneway = TRUE),
      engine = list(engine = engine)
    ),
    classes = "intraclass_singular_fit"
  )
  expect_false(is.null(cnd))
  cli::ansi_strip(cli::format_message(conditionMessage(cnd)))
}

test_that("the overflow abort tells only a non-glmmTMB caller to refit with glmmTMB (AC5)", {
  glmmtmb <- fz_overflow_message("glmmTMB")
  lme4 <- fz_overflow_message("lme4")
  expect_match(glmmtmb, "draws were non-finite", fixed = TRUE)
  expect_false(grepl("glmmTMB", glmmtmb, fixed = TRUE))
  expect_match(lme4, "engine = \"glmmTMB\"", fixed = TRUE)
})
