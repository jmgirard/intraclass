# Data whose scores do not vary within any subject (D-052) ---------------------
#
# icc() refuses such data with `intraclass_singular_fit` before any model is
# fitted. "Before any fit" is checked by replacing the four engines' fitting
# functions with stubs that record each call and then abort: a refusal that
# reaches no stub was raised before a fit. Which argument combinations are in
# the domain is decided per frame by a control frame of the same layout, in
# which subject 1's scores vary: a combination whose control call reaches a stub
# gets as far as a fit, so on the flat frame it must be refused instead.
# Admission reads the stub record, never the condition, because fit_lavaan()
# re-raises any error from lavaan::lavaan() as `intraclass_singular_fit`, and
# the mpl and brms paths signal messages on the way.

fs_engines <- c("glmmTMB", "lme4", "lavaan", "brms")
fs_ci_methods <- c(
  "montecarlo",
  "bootstrap",
  "posterior",
  "npbootstrap",
  "searle",
  "burch",
  "mpl"
)

# A crossed subject x rater frame with `reps` ratings per cell, each score equal
# to its subject's index.
fs_crossed <- function(n_subjects = 10L, n_raters = 3L, reps = 1L) {
  d <- expand.grid(
    rep = seq_len(reps),
    rater = seq_len(n_raters),
    subject = seq_len(n_subjects)
  )
  data.frame(
    subject = factor(d$subject),
    rater = factor(d$rater),
    score = as.numeric(d$subject)
  )
}

fs_frames <- function() {
  f1 <- fs_crossed()
  f2 <- f1
  f2$score <- rep(4, nrow(f2))
  # The frame of the degenerate-data block in test-boundary-abort-hint.R.
  f3 <- data.frame(
    subject = factor(rep(1:3, each = 2)),
    rater = factor(rep(1:2, times = 3)),
    score = rep(c(1, 5, 9), each = 2)
  )
  # 4 clusters of 3 subjects, crossed with 3 raters.
  f4 <- fs_crossed(n_subjects = 12L)
  f4$cluster <- factor((as.integer(f4$subject) - 1L) %/% 3L + 1L)
  f5 <- fs_crossed(reps = 2L)
  # Flat after the missing-score drop.
  f6 <- f1
  f6$score[2] <- NA
  list(F1 = f1, F2 = f2, F3 = f3, F4 = f4, F5 = f5, F6 = f6)
}

# The same frame with subject 1's non-missing scores replaced by 1, 2, 3, ...
fs_control <- function(d) {
  rows <- which(d$subject == levels(d$subject)[1] & !is.na(d$score))
  d$score[rows] <- seq_along(rows)
  d
}

# Replaces the fitting function of each installed engine with a stub that
# records the call in `record` and then aborts. Returns the engines it stubbed.
fs_local_stubs <- function(record, env = parent.frame()) {
  stub <- function(...) {
    record$calls <- record$calls + 1L
    rlang::abort("stub fit reached", class = "fs_stub_fit")
  }
  fits <- c(glmmTMB = "glmmTMB", lme4 = "lmer", lavaan = "lavaan", brms = "brm")
  stubbed <- character(0)
  for (pkg in names(fits)) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      bindings <- rlang::set_names(list(stub), fits[[pkg]])
      rlang::inject(local_mocked_bindings(
        !!!bindings,
        .package = pkg,
        .env = env
      ))
      stubbed <- c(stubbed, pkg)
    }
  }
  stubbed
}

# Calls icc() once and reports whether a stub was reached and which error, if
# any, ended the call.
fs_call <- function(d, record, ...) {
  record$calls <- 0L
  args <- list(...)
  if ("cluster" %in% names(d)) {
    args$cluster <- quote(cluster)
  }
  err <- tryCatch(
    {
      suppressWarnings(suppressMessages(rlang::inject(icc(
        d,
        score,
        subject,
        rater,
        !!!args,
        mc_samples = 200L,
        boot_samples = 20L,
        seed = 1
      ))))
      NULL
    },
    error = function(e) e
  )
  list(reached = record$calls > 0L, error = err)
}

test_that("flat data are refused classed, before any fit, wherever a fit would run (AC1)", {
  skip_on_cran() # about 440 icc() calls, each ended by a stub or a guard
  record <- new.env()
  stubbed <- fs_local_stubs(record)
  frames <- fs_frames()
  for (nm in names(frames)) {
    flat <- frames[[nm]]
    control <- fs_control(flat)
    admitted <- character(0)
    for (engine in stubbed) {
      for (model in c("oneway", "twoway")) {
        for (ci_method in fs_ci_methods) {
          ctrl <- fs_call(
            control,
            record,
            engine = engine,
            model = model,
            ci_method = ci_method
          )
          if (!ctrl$reached) {
            next
          }
          admitted <- c(admitted, engine)
          res <- fs_call(
            flat,
            record,
            engine = engine,
            model = model,
            ci_method = ci_method
          )
          lab <- paste(nm, engine, model, ci_method)
          expect_false(res$reached, label = paste(lab, "reached a fit"))
          expect_true(
            inherits(res$error, "intraclass_singular_fit") &&
              inherits(res$error, "intraclass_error"),
            label = paste(lab, "raised", class(res$error)[1])
          )
        }
      }
    }
    # The domain is not empty: every engine this run stubbed reaches a fit on
    # each control frame for at least one combination. The one exception is
    # lavaan on F5, which reaches no fit: its two-way montecarlo and bootstrap
    # calls are refused for within-cell replicates, and every other combination
    # by a one-way or `ci_method` scope fence.
    expected <- if (nm == "F5") setdiff(stubbed, "lavaan") else stubbed
    expect_setequal(unique(admitted), expected)
  }
})

test_that("frames close to flat still reach a fit (AC2)", {
  skip_if_not_installed("glmmTMB")
  record <- new.env()
  local_mocked_bindings(
    glmmTMB = function(...) {
      record$calls <- record$calls + 1L
      rlang::abort("stub fit reached", class = "fs_stub_fit")
    },
    .package = "glmmTMB"
  )
  near <- fs_frames()$F1
  near$score[1] <- near$score[1] + 1e-12
  for (d in list(near, fs_control(fs_frames()$F1))) {
    for (model in c("oneway", "twoway")) {
      res <- fs_call(d, record, model = model)
      expect_true(res$reached, label = paste(model, "reached the glmmTMB fit"))
      expect_s3_class(res$error, "fs_stub_fit")
    }
  }
})

test_that("the refusal names the score argument (AC3)", {
  frames <- fs_frames()
  for (nm in c("F1", "F2")) {
    for (model in c("twoway", "oneway")) {
      err <- tryCatch(
        suppressWarnings(
          icc(frames[[nm]], score, subject, rater, model = model, seed = 1)
        ),
        error = function(e) e
      )
      expect_s3_class(err, "intraclass_singular_fit")
      expect_true(
        grepl("`score`", conditionMessage(err), fixed = TRUE),
        label = paste(nm, model, "message names `score`")
      )
    }
  }
})
