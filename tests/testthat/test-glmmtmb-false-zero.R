# A glmmTMB variance stuck at zero: the second start (M158, D-048) --------------
#
# glmmTMB's own start puts every log-SD at 0 (an SD of 1). On scores multiplied by
# 1000 that start can stall the optimizer at a false optimum with the subject
# variance at 0, which icc() printed as ICC 0.000 [0.000, 0.000] (the user report
# behind PR #176). PR #176 replaced that start with a data-scaled one
# (glmmtmb_start()). These tests plant the old start again by masking
# glmmtmb_start() to return NULL, so they check the second start on its own:
# a fit that leaves a variance at numerical zero is refit once from another start
# and the fit with the lower REML objective is kept.
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

# ICC(A,1) of the fixed-rater engine fit, read from its variance components so
# that no interval is computed (the zero-width refusal would stop icc()).
fz_fixed_icc_a1 <- function(d) {
  comp <- suppressMessages(suppressWarnings(fit_glmmtmb_fixed(d)$components))
  comp$subject / (comp$subject + comp$rater + comp$residual)
}

test_that("the second start reaches the REML optimum on a planted false zero (AC1)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_on_cran()
  local_mocked_bindings(glmmtmb_start = function(formula, data) NULL)

  for (m in names(fz_models)) {
    for (seed in fz_seeds) {
      small <- scale_two_way(seed)
      big <- transform(small, score = score * fz_scale)
      ref <- fz_first_icc(big, fz_models[[m]]$args, engine = "lme4")
      if (!(ref > 0.01)) {
        next
      }
      got <- fz_first_icc(big, fz_models[[m]]$args)
      unscaled <- fz_first_icc(small, fz_models[[m]]$args)
      info <- paste0("model ", m, ", seed ", seed)
      expect_identical(names(got), names(ref), info = info)
      expect_equal(unname(got), unname(ref), tolerance = 1e-4, info = info)
      expect_equal(unname(got), unname(unscaled), tolerance = 1e-5, info = info)
    }
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

  reached <- vapply(
    fz_seeds,
    function(seed) {
      big <- transform(scale_two_way(seed), score = score * fz_scale)
      ref <- fz_first_icc(big, fz_models$fixed$args, engine = "lme4")
      ref > 0.01 && fz_fixed_icc_a1(big) < 1e-6
    },
    logical(1)
  )
  expect_true(any(reached))
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
