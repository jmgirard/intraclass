# The d_study() band checks (D-058) ---------------------------------------------
#
# On a glmmTMB or lme4 fit, whatever its `ci_method`, `d_study()` reads each
# curve's single-rating coefficient (one rater, and one occasion on a replicate
# fit) from the same draws as the band. It aborts with
# `intraclass_zero_width_interval` when that coefficient's limits are finite
# and exactly equal, and otherwise warns with `intraclass_unresolved_interval`
# when its lower limit lies within 1e-12 of 1. A projected row's own limits are
# not checked, so a row equal only through rounding near 1 fires neither.
#
# Fits use seed 1, 500 Monte-Carlo draws and 30 bootstrap refits. The near-1
# frames are those of helper-near-one-frames.R (M163, M164), and the ordinary
# frame is `scale_two_way(11)` of helper-glmmtmb-frames.R.

# Reads `CI` as `testthat::skip_on_ci()` does.
bc_on_ci <- function() isTRUE(as.logical(Sys.getenv("CI", "false")))

# Runs `expr`. Returns its value or its error, and every
# `intraclass_unresolved_interval` warning it signaled. Other warnings and all
# messages are muffled.
bc_run <- function(expr) {
  seen <- list()
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        if (inherits(w, "intraclass_unresolved_interval")) {
          seen[[length(seen) + 1L]] <<- w
        }
        invokeRestart("muffleWarning")
      },
      message = function(m) invokeRestart("muffleMessage")
    ),
    error = function(e) e
  )
  list(value = value, warnings = seen)
}

bc_frames <- function() {
  c(
    list(scale = list(data = scale_two_way(11), args = list(), k = 2)),
    ui_frames(),
    ui_frames_resolved()
  )
}

# One icc() fit of a frame of `bc_frames()`, run through `bc_run()`. Fits are
# kept in `bc_cache`, so each is made once per file.
bc_cache <- new.env(parent = emptyenv())
bc_icc <- function(frame, engine, method) {
  key <- paste(frame, engine, method)
  if (is.null(bc_cache[[key]])) {
    fr <- bc_frames()[[frame]]
    bc_cache[[key]] <- bc_run(rlang::inject(icc(
      fr$data,
      score,
      subject = subject,
      rater = rater,
      !!!fr$args,
      engine = engine,
      ci_method = method,
      mc_samples = 500L,
      boot_samples = 30L,
      seed = 1
    )))
  }
  bc_cache[[key]]
}

bc_d_study <- function(fit, ...) {
  bc_run(d_study(fit, ..., seed = 1, mc_samples = 500))
}

# The fit with every band draw replaced by one fitted draw: a zero parameter
# covariance for a Monte-Carlo band, or every stored bootstrap resample set to
# the first whose total variance is nonzero.
bc_constant <- function(fit) {
  if (identical(fit$ci$method, "bootstrap")) {
    bc <- fit$boot$components
    j <- which(Reduce(`+`, bc) > 0)[1]
    fit$boot$components <- lapply(bc, function(v) rep(v[[j]], length(v)))
  } else {
    fit$mc$vcov <- 0 * fit$mc$vcov
  }
  fit
}

bc_message <- function(w) {
  cli::ansi_strip(cli::format_message(conditionMessage(w)))
}

# The call id `bc_recorded` uses.
bc_id <- function(frame, engine, method, m) {
  sprintf("%s %s %s m=%s", frame, engine, method, paste(m, collapse = ","))
}

# Constant draws are refused (D-058 AC1) ----------------------------------------

test_that("constant band draws on glmmTMB and lme4 fits abort, and the fitted draws return (D-058 AC1)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  q <- function(expr) suppressMessages(suppressWarnings(expr))
  cases <- list(
    tmb_mc = list(fit = bc_icc("scale", "glmmTMB", "montecarlo")$value),
    lme4_mc = list(fit = bc_icc("scale", "lme4", "montecarlo")$value),
    tmb_boot = list(fit = bc_icc("scale", "glmmTMB", "bootstrap")$value),
    lme4_boot = list(fit = bc_icc("scale", "lme4", "bootstrap")$value),
    tmb_school = list(
      fit = q(icc(
        school,
        score,
        pupil,
        rater,
        cluster = classroom,
        engine = "glmmTMB",
        mc_samples = 500L,
        seed = 1
      ))
    ),
    lme4_replicates = list(
      fit = q(icc(
        ratings_replicates,
        score,
        subject,
        rater,
        engine = "lme4",
        mc_samples = 500L,
        seed = 1
      )),
      args = list(n_o = 1:3)
    ),
    # The gate reads the engine, not the `ci_method`: an MPL fit's band is a
    # Monte-Carlo band from the same draws (T1).
    tmb_mpl = list(
      fit = q(icc(
        scale_two_way(11),
        score,
        subject,
        rater,
        engine = "glmmTMB",
        ci_method = "mpl",
        seed = 1
      ))
    )
  )
  for (nm in names(cases)) {
    fit <- cases[[nm]]$fit
    args <- cases[[nm]]$args %||% list(m = c(1, 2))
    expect_s3_class(fit, "intraclass_icc")
    fitted <- do.call(bc_d_study, c(list(fit), args))
    expect_s3_class(fitted$value, "intraclass_dstudy")
    constant <- bc_constant(fit)
    if (identical(fit$ci$method, "bootstrap")) {
      # Every resample now holds the same components, with nonzero total.
      for (v in constant$boot$components) {
        expect_identical(length(unique(v)), 1L, info = nm)
      }
      expect_gt(sum(vapply(constant$boot$components, `[[`, numeric(1), 1L)), 0)
    } else {
      expect_true(all(constant$mc$vcov == 0), info = nm)
    }
    err <- do.call(bc_d_study, c(list(constant), args))$value
    # The refusal fired, read by class and by its d_study() bullet, so no other
    # guard stands in for it.
    expect_s3_class(err, "intraclass_zero_width_interval")
    expect_s3_class(err, "intraclass_singular_fit")
    expect_match(
      bc_message(err),
      "single-rating coefficient behind the projected curves",
      fixed = TRUE
    )
    # The refusal names no example of the data that cause it; the one it gave
    # is refused before any fit (D-052, M168 AC5).
    expect_no_match(
      bc_message(err),
      "do not vary within subjects",
      fixed = TRUE
    )
    expect_match(
      bc_message(err),
      "Inspect the data and the fitted variances",
      fixed = TRUE
    )
  }
})

test_that("constant band draws on a lavaan fit are reported (D-058 AC1)", {
  skip_if_not_installed("lavaan")
  skip_on_cran()
  fit <- suppressMessages(suppressWarnings(icc(
    scale_two_way(11),
    score,
    subject,
    rater,
    engine = "lavaan",
    ci_method = "montecarlo",
    mc_samples = 500L,
    seed = 1
  )))
  expect_s3_class(fit, "intraclass_icc")
  out <- bc_d_study(bc_constant(fit), m = c(1, 2))
  expect_s3_class(out$value, "intraclass_dstudy")
  # The band's limits are equal, so the gate, not the draws, let it through.
  expect_true(all(out$value$conf.low == out$value$conf.high))
})

# Rounded [1, 1] rows are reported (D-058 AC2) ----------------------------------

test_that("rows rounded to [1, 1] at m = 1e20 are reported with no warning when the single-rating limits differ (D-058 AC2)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  for (engine in c("glmmTMB", "lme4")) {
    fit <- bc_icc("scale", engine, "montecarlo")$value
    expect_s3_class(fit, "intraclass_icc")
    out <- bc_d_study(fit, m = c(1, 1e20))
    expect_s3_class(out$value, "intraclass_dstudy")
    expect_length(out$warnings, 0L)
    far <- out$value[out$value$m == 1e20, ]
    expect_true(any(far$conf.low == 1 & far$conf.high == 1), info = engine)
    # The single-rating rows behind the curves are far from [1, 1].
    one <- out$value[out$value$m == 1, ]
    expect_true(all(one$conf.low < 0.1 & one$conf.low < one$conf.high))
  }
})

# The near-1 warning (D-058 AC3) ------------------------------------------------

# The single-rating rows of an icc() fit whose lower limit lies within 1e-12
# of 1, read from `tidy()`. The fit's single-rating intervals come from the
# same draws as the band at the same seed, so these are the coefficients the
# warning must name.
bc_near_single <- function(fit) {
  td <- tidy(fit)
  single <- td$term %in%
    c("ICC(A,1)", "ICC(C,1)", "ICC(1)") &
    (is.na(td$occasions) | td$occasions == 1)
  near <- single & is.finite(td$conf.low) & 1 - td$conf.low < 1e-12
  list(near = td$term[near], far = td$term[single & !near])
}

test_that("a near-1 single-rating coefficient gives one warning that names it (D-058 AC3)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  cases <- list(
    list("near_flat", "lme4", "montecarlo", c(1, 2)),
    list("additive", "lme4", "montecarlo", c(1, 2)),
    list("noisy", "lme4", "montecarlo", c(1, 2)),
    list("noisy", "glmmTMB", "montecarlo", c(1, 2)),
    list("additive", "lme4", "bootstrap", c(1, 2)),
    # No m = 1 row: the warning still names the coefficient behind the curve.
    list("noisy", "lme4", "montecarlo", c(2, 3))
  )
  for (cs in cases) {
    info <- do.call(bc_id, cs)
    fitted <- bc_icc(cs[[1]], cs[[2]], cs[[3]])
    # On another platform the engines can resolve or refuse this frame, so
    # the named-set floor is read here only (GP9); the rule below holds
    # everywhere.
    if (bc_on_ci() && inherits(fitted$value, "error")) {
      expect_s3_class(fitted$value, "intraclass_singular_fit")
      next
    }
    expect_s3_class(fitted$value, "intraclass_icc")
    if (!bc_on_ci()) {
      expect_length(fitted$warnings, 1L)
    }
    names <- bc_near_single(fitted$value)
    if (!bc_on_ci()) {
      expect_gt(length(names$near), 0L)
    }
    out <- bc_d_study(fitted$value, m = cs[[4]])
    expect_s3_class(out$value, "intraclass_dstudy")
    expect_length(out$warnings, as.integer(length(names$near) > 0L))
    for (w in out$warnings) {
      expect_s3_class(w, "intraclass_unresolved_interval")
      expect_s3_class(w, "intraclass_warning")
      msg <- bc_message(w)
      for (nm in names$near) {
        expect_match(msg, nm, fixed = TRUE, info = info)
      }
      for (nm in names$far) {
        expect_no_match(msg, nm, fixed = TRUE, info = info)
      }
      expect_match(
        msg,
        "single-rating coefficient behind the projected curves",
        fixed = TRUE
      )
      expect_match(msg, "intraclass_unresolved_interval", fixed = TRUE)
    }
  }
  # The noisy lme4 fit names ICC(C,1) on a call with no m = 1 row.
  out <- bc_d_study(bc_icc("noisy", "lme4", "montecarlo")$value, m = c(2, 3))
  if (!bc_on_ci() || length(out$warnings) > 0L) {
    expect_length(out$warnings, 1L)
    expect_match(bc_message(out$warnings[[1]]), "ICC(C,1)", fixed = TRUE)
    expect_false(any(out$value$m == 1))
  }
})

test_that("resolved and ordinary fits give no d_study() warning (D-058 AC3)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  cases <- list(
    list("scale", "glmmTMB", "montecarlo"),
    list("scale", "lme4", "montecarlo")
  )
  for (frame in c("noisy6", "replicated6")) {
    for (engine in c("glmmTMB", "lme4")) {
      for (method in c("montecarlo", "bootstrap")) {
        cases[[length(cases) + 1L]] <- list(frame, engine, method)
      }
    }
  }
  for (cs in cases) {
    info <- do.call(bc_id, c(cs, list(c(1, 2))))
    fitted <- bc_icc(cs[[1]], cs[[2]], cs[[3]])
    if (bc_on_ci() && inherits(fitted$value, "error")) {
      expect_s3_class(fitted$value, "intraclass_singular_fit")
      next
    }
    expect_s3_class(fitted$value, "intraclass_icc")
    out <- bc_d_study(fitted$value, m = c(1, 2))
    expect_s3_class(out$value, "intraclass_dstudy")
    expect_length(out$warnings, 0L)
  }
})

test_that("the band warning names every near coefficient and skips lavaan fits (D-058 AC3)", {
  # Two single-rating coefficients, one per level, both within 1e-12 of 1,
  # and a third far from 1.
  ests <- lapply(c("subject", "cluster"), function(lv) {
    icc_estimand(type = "agreement", multilevel = TRUE, level = lv)
  })
  ests[[3]] <- icc_estimand(type = "consistency")
  near <- list(conf.low = 1 - 1e-13, conf.high = 1)
  far <- list(conf.low = 0.2, conf.high = 0.9)
  ivs <- list(near, near, far)
  out <- bc_run(warn_unresolved_band(ivs, ests, list(engine = "lme4")))
  expect_length(out$warnings, 1L)
  expect_match(
    bc_message(out$warnings[[1]]),
    "2 single-rating coefficients behind the projected curves have lower limits near 1: ICC(A,1) at the subject level and ICC(A,1) at the cluster level.",
    fixed = TRUE
  )
  expect_match(
    bc_message(out$warnings[[1]]),
    "can give such intervals",
    fixed = TRUE
  )
  expect_no_match(bc_message(out$warnings[[1]]), "ICC(C,1)", fixed = TRUE)
  expect_length(
    bc_run(warn_unresolved_band(ivs, ests, list(engine = "lavaan")))$warnings,
    0L
  )
})

# The coefficients the checks read, captured from `check_band_single_rating()`:
# one per type and level, at one rater and one occasion, whatever the axis or
# the occasion settings of the band. Constant draws cannot tell these apart,
# so the estimands are read directly (M166 review).
bc_read <- function(fit, ...) {
  seen <- NULL
  local_mocked_bindings(
    check_band_single_rating = function(intervals, estimands, engine, ...) {
      seen <<- estimands
      invisible(intervals)
    }
  )
  suppressMessages(d_study(fit, ..., seed = 1, mc_samples = 200))
  seen
}

test_that("the checks read each curve's coefficient at one rater and one occasion (D-058 AC1, AC3)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  q <- function(expr) suppressMessages(suppressWarnings(expr))
  reps <- q(icc(
    ratings_replicates,
    score,
    subject,
    rater,
    engine = "lme4",
    occasions = c("single", "average"),
    mc_samples = 200L,
    seed = 1
  ))
  # The band carries curves over 1 and over the fitted occasion count.
  expect_gt(length(unique(reps$estimates$occasions)), 1L)
  for (args in list(list(m = c(1, 2)), list(n_o = 1:3))) {
    read <- do.call(bc_read, c(list(reps), args))
    expect_setequal(
      vapply(read, `[[`, character(1), "label"),
      c("ICC(A,1)", "ICC(C,1)")
    )
    for (e in read) {
      expect_identical(e$occasions, 1)
      expect_true(all(unlist(e$error_divisors) == 1))
    }
  }
  school_fit <- q(icc(
    school,
    score,
    pupil,
    rater,
    cluster = classroom,
    engine = "glmmTMB",
    mc_samples = 200L,
    seed = 1
  ))
  read <- bc_read(school_fit, m = c(2, 3))
  names <- vapply(read, unresolved_row_name, character(1))
  expect_setequal(
    names,
    c(
      "ICC(A,1) at the subject level",
      "ICC(A,1) at the cluster level",
      "ICC(C,1) at the subject level",
      "ICC(C,1) at the cluster level"
    )
  )
  # A lavaan fit builds none, so its band is computed as before.
  lav <- q(icc(
    scale_two_way(11),
    score,
    subject,
    rater,
    engine = "lavaan",
    mc_samples = 200L,
    seed = 1
  ))
  expect_length(bc_read(lav, m = c(1, 2)), 0L)
})

test_that("the refusal names the coefficients whose limits are equal (M166 review)", {
  ests <- lapply(c("subject", "cluster"), function(lv) {
    icc_estimand(type = "agreement", multilevel = TRUE, level = lv)
  })
  ivs <- list(
    list(conf.low = 0.2, conf.high = 0.9),
    list(conf.low = 0.5, conf.high = 0.5)
  )
  err <- rlang::catch_cnd(
    check_band_single_rating(ivs, ests, "glmmTMB"),
    classes = "error"
  )
  expect_s3_class(err, "intraclass_zero_width_interval")
  msg <- bc_message(err)
  expect_match(msg, "as the band: ICC(A,1) at the cluster level.", fixed = TRUE)
  expect_no_match(msg, "subject level", fixed = TRUE)
})

# No reported number changes (D-058 AC4) ----------------------------------------

# The four columns of each AC2 and AC3 call that returns, at `%.17g`, as the
# code of the plan commit (b55567d) returned them on macOS (aarch64), R 4.6.1,
# 2026-10-19. Each row is the term, then `estimate`, `std.error`, `conf.low`
# and `conf.high`, in the order `tidy()` gives the rows. Main at 908532f gave
# the same strings.
bc_recorded <- list(
  "scale glmmTMB montecarlo m=1,1e+20" = c(
    "ICC(A,1) 0.1612652118394001 0.18852928347524039 0.0066544248189275654 0.66702609987457873",
    "ICC(A,1e+20) 1 0 1 1",
    "ICC(C,1) 0.22027824711073071 0.22497665729687027 0.015604289175423242 0.80374374094136303",
    "ICC(C,1e+20) 1 0 1 1"
  ),
  "scale lme4 montecarlo m=1,1e+20" = c(
    "ICC(A,1) 0.16126524064576883 0.20033979594508625 0.0085490129104330882 0.72384793335555941",
    "ICC(A,1e+20) 1 0 1 1",
    "ICC(C,1) 0.22027823962619086 0.23193254318481094 0.019117017334350464 0.83448377179399991",
    "ICC(C,1e+20) 1 0 1 1"
  ),
  "scale glmmTMB montecarlo m=1,2" = c(
    "ICC(A,1) 0.1612652118394001 0.18852928347524039 0.0066544248189275654 0.66702609987457873",
    "ICC(A,2) 0.27774053712323316 0.23086594884136952 0.013220842331612741 0.80022233470183257",
    "ICC(C,1) 0.22027824711073071 0.22497665729687027 0.015604289175423242 0.80374374094136303",
    "ICC(C,2) 0.36102953999595827 0.25436338482946313 0.030725013593349958 0.89119133288278574"
  ),
  "scale lme4 montecarlo m=1,2" = c(
    "ICC(A,1) 0.16126524064576883 0.20033979594508625 0.0085490129104330882 0.72384793335555941",
    "ICC(A,2) 0.27774057984563583 0.24077119342741932 0.016953091000061933 0.83977267154574031",
    "ICC(C,1) 0.22027823962619086 0.23193254318481094 0.019117017334350464 0.83448377179399991",
    "ICC(C,2) 0.36102952994338228 0.25800007537456515 0.037516534024336252 0.90971933212173339"
  ),
  "near_flat lme4 montecarlo m=1,2" = c(
    "ICC(1) 0.99999999999999223 6.0765919260966603e-15 0.99999999999997435 0.99999999999999711",
    "ICC(2) 0.99999999999999611 3.0398169061324796e-15 0.99999999999998723 0.99999999999999856"
  ),
  "additive lme4 montecarlo m=1,2" = c(
    "ICC(A,1) 0.41682220274968229 0.29594373069545538 0.015780244344451591 0.96288061225614829",
    "ICC(A,2) 0.588390274998146 0.29762553436159789 0.031070157239036136 0.98108649800689873",
    "ICC(C,1) 0.99999999999999456 3.8625990618945307e-14 0.99999999999990219 0.99999999999999956",
    "ICC(C,2) 0.99999999999999722 1.9312249158890168e-14 0.99999999999995115 0.99999999999999978"
  ),
  "noisy lme4 montecarlo m=1,2" = c(
    "ICC(A,1) 0.99999999999999101 0.50048153169173737 0 0.99999999999999478",
    "ICC(A,2) 0.99999999999999545 0.50048357061190529 0 0.99999999999999734",
    "ICC(C,1) 0.99999999999999101 4.250361371024599e-15 0.99999999999997935 0.99999999999999556",
    "ICC(C,2) 0.99999999999999545 2.1182696524863883e-15 0.99999999999998979 0.99999999999999778"
  ),
  "noisy lme4 montecarlo m=2,3" = c(
    "ICC(A,2) 0.99999999999999545 0.50048357061190529 0 0.99999999999999734",
    "ICC(A,3) 0.99999999999999689 0.50048182237453342 0 0.99999999999999822",
    "ICC(C,2) 0.99999999999999545 2.1182696524863883e-15 0.99999999999998979 0.99999999999999778",
    "ICC(C,3) 0.99999999999999689 1.4183002317100776e-15 0.99999999999999312 0.99999999999999856"
  ),
  "noisy glmmTMB montecarlo m=1,2" = c(
    "ICC(A,1) 0.99999999999999112 0.48834232003188505 4.7716671560305225e-134 0.99999999999999245",
    "ICC(A,2) 0.99999999999999545 0.48843434361372995 9.5433343120610449e-134 0.99999999999999623",
    "ICC(C,1) 0.99999999999999112 9.5497236285999133e-16 0.99999999999998901 0.99999999999999267",
    "ICC(C,2) 0.99999999999999545 4.8373078338088866e-16 0.99999999999999445 0.99999999999999634"
  ),
  "additive lme4 bootstrap m=1,2" = c(
    "ICC(A,1) 0.41682220274968229 0.31019603829073122 0.089000673516302017 0.98887916566406919",
    "ICC(A,2) 0.588390274998146 0.27153407057739654 0.16340036764038887 0.99440597321124458",
    "ICC(C,1) 0.99999999999999456 1.0175210677049728e-14 0.9999999999999627 0.99999999999999556",
    "ICC(C,2) 0.99999999999999722 5.0957215375730477e-15 0.99999999999998135 0.99999999999999778"
  ),
  "noisy6 glmmTMB montecarlo m=1,2" = c(
    "ICC(A,1) 0.9999999999990935 0.49971188589522575 0 0.9999999999995286",
    "ICC(A,2) 0.9999999999995467 0.49967373442654667 0 0.99999999999976441",
    "ICC(C,1) 0.9999999999990935 4.1979813823491021e-13 0.99999999999814104 0.9999999999996001",
    "ICC(C,2) 0.9999999999995467 2.0990309553312043e-13 0.99999999999907041 0.99999999999980016"
  ),
  "noisy6 glmmTMB bootstrap m=1,2" = c(
    "ICC(A,1) 0.9999999999990935 3.0738607336567728e-13 0.99999999999835643 0.99999999999947553",
    "ICC(A,2) 0.9999999999995467 1.5369774783689196e-13 0.99999999999917821 0.99999999999973777",
    "ICC(C,1) 0.9999999999990935 3.112399960056829e-13 0.99999999999835654 0.99999999999950429",
    "ICC(C,2) 0.9999999999995467 1.5560715973375282e-13 0.99999999999917832 0.9999999999997522"
  ),
  "noisy6 lme4 montecarlo m=1,2" = c(
    "ICC(A,1) 0.99999999999910227 0.50046928553623427 0 0.99999999999948841",
    "ICC(A,2) 0.99999999999955114 0.50046682036048884 0 0.9999999999997442",
    "ICC(C,1) 0.99999999999910227 4.2981972978624259e-13 0.99999999999792788 0.99999999999957423",
    "ICC(C,2) 0.99999999999955114 2.1491338624792083e-13 0.99999999999896394 0.99999999999978706"
  ),
  "noisy6 lme4 bootstrap m=1,2" = c(
    "ICC(A,1) 0.99999999999910227 4.0457247454015435e-13 0.99999999999811018 0.99999999999947087",
    "ICC(A,2) 0.99999999999955114 2.0226896432875609e-13 0.9999999999990552 0.99999999999973543",
    "ICC(C,1) 0.99999999999910227 4.0446689291038983e-13 0.99999999999811051 0.99999999999947098",
    "ICC(C,2) 0.99999999999955114 2.0221927449888915e-13 0.99999999999905542 0.99999999999973554"
  ),
  "replicated6 glmmTMB montecarlo m=1,2" = c(
    "ICC(A,1) 0.99999999999916234 0.48548429210776661 0 0.999999999999718",
    "ICC(A,2) 0.99999999999958122 0.48554840475174271 0 0.999999999999859",
    "ICC(A,1) 0.99999999999957956 0.48548429210793315 0 0.999999999999859",
    "ICC(A,2) 0.99999999999978983 0.48554840475182798 0 0.9999999999999295",
    "ICC(C,1) 0.99999999999916234 0.44420103878662559 4.8964148401552999e-39 0.99999999999975686",
    "ICC(C,2) 0.99999999999958122 0.44262809563330574 9.7928296803105997e-39 0.99999999999987832",
    "ICC(C,1) 0.99999999999957956 0.44420103878678319 4.8964148401552999e-39 0.99999999999987832",
    "ICC(C,2) 0.99999999999978983 0.44262809563338429 9.7928296803105997e-39 0.99999999999993916"
  ),
  "replicated6 glmmTMB bootstrap m=1,2" = c(
    "ICC(A,1) 0.99999999999916234 3.1379762962713155e-13 0.99999999999829359 0.99999999999939448",
    "ICC(A,2) 0.99999999999958122 1.5691793806830471e-13 0.99999999999914668 0.99999999999969713",
    "ICC(A,1) 0.99999999999957956 1.8582642522022077e-13 0.999999999999033 0.99999999999968581",
    "ICC(A,2) 0.99999999999978983 9.2929985331685842e-14 0.99999999999951639 0.9999999999998429",
    "ICC(C,1) 0.99999999999916234 3.1403995765606761e-13 0.99999999999829381 0.99999999999939471",
    "ICC(C,2) 0.99999999999958122 1.5704920181810981e-13 0.9999999999991469 0.99999999999969713",
    "ICC(C,1) 0.99999999999957956 1.8603791929104541e-13 0.99999999999903333 0.99999999999968581",
    "ICC(C,2) 0.99999999999978983 9.3015404810122295e-14 0.99999999999951661 0.9999999999998429"
  ),
  "replicated6 lme4 montecarlo m=1,2" = c(
    "ICC(A,1) 0.9999999999797472 0.43797216285793833 0 0.99999999998508504",
    "ICC(A,2) 0.99999999998987366 0.43797217646607417 0 0.99999999999254263",
    "ICC(A,1) 0.99999999998987366 0.43797216286345503 0 0.99999999999254263",
    "ICC(A,2) 0.99999999999493694 0.43797217646883252 0 0.99999999999627132",
    "ICC(C,1) 0.99999999997974742 0.49905319693020767 0 0.99999999998757116",
    "ICC(C,2) 0.99999999998987366 0.4990532043693201 0 0.99999999999378564",
    "ICC(C,1) 0.99999999998987366 0.49905319693642336 0 0.99999999999378564",
    "ICC(C,2) 0.99999999999493694 0.49905320437242479 0 0.99999999999689271"
  ),
  "replicated6 lme4 bootstrap m=1,2" = c(
    "ICC(A,1) 0.9999999999797472 6.5412821644273654e-12 0.9999999999676179 0.99999999998842193",
    "ICC(A,2) 0.99999999998987366 3.2706445384840679e-12 0.99999999998380895 0.99999999999421108",
    "ICC(A,1) 0.99999999998987366 3.2706445384840679e-12 0.99999999998380895 0.99999999999421108",
    "ICC(A,2) 0.99999999999493694 1.6353381692444154e-12 0.99999999999190436 0.99999999999710565",
    "ICC(C,1) 0.99999999997974742 6.5412709920795084e-12 0.9999999999676179 0.99999999998842193",
    "ICC(C,2) 0.99999999998987366 3.2706406389568822e-12 0.99999999998380895 0.99999999999421108",
    "ICC(C,1) 0.99999999998987366 3.270640467222674e-12 0.99999999998380895 0.99999999999421108",
    "ICC(C,2) 0.99999999999493694 1.6353274430535719e-12 0.99999999999190436 0.99999999999710565"
  )
)

bc_row_strings <- function(x) {
  td <- tidy(x)
  sprintf(
    "%s %s %s %s %s",
    td$term,
    sprintf("%.17g", td$estimate),
    sprintf("%.17g", td$std.error),
    sprintf("%.17g", td$conf.low),
    sprintf("%.17g", td$conf.high)
  )
}

# The calls of `bc_recorded`, parsed back from their ids.
bc_recorded_calls <- function() {
  lapply(names(bc_recorded), function(id) {
    parts <- strsplit(id, " ", fixed = TRUE)[[1]]
    list(
      id = id,
      frame = parts[[1]],
      engine = parts[[2]],
      method = parts[[3]],
      m = as.numeric(strsplit(sub("^m=", "", parts[[4]]), ",")[[1]])
    )
  })
}

test_that("the 18 recorded call ids round-trip through bc_id() (D-058 AC4)", {
  # The ids round-trip through `bc_id()`, so the parsed calls are the
  # recorded ones.
  for (cl in bc_recorded_calls()) {
    expect_identical(bc_id(cl$frame, cl$engine, cl$method, cl$m), cl$id)
  }
  expect_length(bc_recorded, 18L)
})

test_that("d_study() returns the recorded values of the plan commit (D-058 AC4)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  # Recorded on one platform: the engines' last digits differ across
  # platforms, so the comparison runs off CI. The test below runs on CI too.
  skip_on_ci()
  for (cl in bc_recorded_calls()) {
    fit <- bc_icc(cl$frame, cl$engine, cl$method)$value
    expect_s3_class(fit, "intraclass_icc")
    out <- bc_d_study(fit, m = cl$m)
    expect_s3_class(out$value, "intraclass_dstudy")
    expect_identical(
      bc_row_strings(out$value),
      bc_recorded[[cl$id]],
      info = cl$id
    )
  }
})

test_that("d_study() returns what it returns with the band checks removed (D-058 AC4)", {
  skip_if_not_installed("lme4")
  skip_on_cran()
  compared <- 0L
  for (cl in bc_recorded_calls()) {
    fit <- bc_icc(cl$frame, cl$engine, cl$method)$value
    # Another platform's engines can refuse a near-degenerate frame (GP9).
    if (inherits(fit, "error")) {
      expect_s3_class(fit, "intraclass_singular_fit")
      next
    }
    checked <- bc_d_study(fit, m = cl$m)$value
    expect_s3_class(checked, "intraclass_dstudy")
    stub_calls <- 0L
    bare <- local({
      local_mocked_bindings(
        check_band_single_rating = function(...) {
          stub_calls <<- stub_calls + 1L
          invisible(NULL)
        }
      )
      bc_d_study(fit, m = cl$m)$value
    })
    # The stub replaced the checks, so `bare` is the band without them.
    expect_identical(stub_calls, 1L, info = cl$id)
    expect_identical(checked, bare, info = cl$id)
    compared <- compared + 1L
  }
  # The comparison is not met by skipped calls alone.
  expect_gt(compared, 0L)
})
