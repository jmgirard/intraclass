# The exported contract fixed at v0.1.0 (D-035, RR04) ---------------------------
#
# Two clauses, each pinned here:
#   1. A vector-valued default in `icc()`'s signature means "report every value"
#      and nothing else. A choice argument takes exactly one value; passing
#      several -- the full choice list included -- aborts classed rather than
#      quietly selecting the first (PRINCIPLES.md #5/#8).
#   2. Every identifier column of `tidy()` output is present on every fit, NA
#      where the design does not define it, so two tidied fits row-bind and a
#      later extension fills cells instead of changing the schema. `glance()`
#      names the replicate split rather than letting `var_residual` change
#      meaning silently.

# A balanced two-way design with two ratings per subject x rater cell: the one
# shape where `occasions`, `n_o` and `var_subject_rater` are defined, so it is
# the control that shows the NA columns below are NA by design, not by accident.
replicate_frame <- function(seed = 4) {
  set.seed(seed)
  grid <- expand.grid(
    subject = seq_len(8L),
    rater = seq_len(3L),
    occ = seq_len(2L)
  )
  s <- stats::rnorm(8L, 0, 2)
  r <- stats::rnorm(3L, 0, 1)
  sr <- stats::rnorm(24L, 0, 0.5)
  grid$score <- 10 +
    s[grid$subject] +
    r[grid$rater] +
    sr[(grid$rater - 1L) * 8L + grid$subject] +
    stats::rnorm(nrow(grid), 0, 1)
  grid$subject <- factor(grid$subject)
  grid$rater <- factor(grid$rater)
  grid
}

# 1. Choice arguments take exactly one value ------------------------------------

test_that("a multi-valued choice argument aborts classed, never collapses", {
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      raters = c("random", "fixed"),
      seed = 1
    ),
    class = "intraclass_error"
  )
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      posterior_summary = c("percentile", "hpdi"),
      seed = 1
    ),
    class = "intraclass_error"
  )
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      model = c("twoway", "oneway"),
      seed = 1
    ),
    class = "intraclass_error"
  )
})

test_that("the scalar defaults still fit, and each choice is still accepted", {
  # The passing control: the abort above is about arity, not about the values.
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_s3_class(fit, "icc")
  expect_identical(fit$design$raters, "random")
  expect_identical(
    suppressWarnings(
      icc(ratings, score, subject, rater, raters = "fixed", seed = 1)
    )$design$raters,
    "fixed"
  )
})

test_that("autoplot's `what` is a choice argument on the same terms", {
  skip_if_not_installed("ggplot2")
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_error(
    ggplot2::autoplot(fit, what = c("coefficients", "components")),
    class = "intraclass_error"
  )
  expect_s3_class(ggplot2::autoplot(fit), "ggplot")
  expect_s3_class(ggplot2::autoplot(fit, what = "components"), "ggplot")
})

# 2. A stable tidy/glance schema ------------------------------------------------

test_that("tidy.icc names the coefficient column `term` and always carries `occasions`", {
  td <- tidy(icc(ratings, score, subject, rater, seed = 1))
  expect_identical(
    names(td),
    c(
      "term",
      "occasions",
      "type",
      "level",
      "sf_index",
      "estimate",
      "std.error",
      "conf.low",
      "conf.high",
      "conf.level",
      "method"
    )
  )
  expect_true(all(is.na(td$occasions)))
  expect_true(all(grepl("^ICC\\(", td$term)))
})

test_that("a replicate fit fills `occasions`, and the two schemas row-bind", {
  rep_fit <- icc(replicate_frame(), score, subject, rater, seed = 1)
  td_rep <- tidy(rep_fit)
  td_plain <- tidy(icc(ratings, score, subject, rater, seed = 1))
  expect_identical(names(td_rep), names(td_plain))
  expect_false(any(is.na(td_rep$occasions)))
  bound <- rbind(td_rep, td_plain)
  expect_identical(nrow(bound), nrow(td_rep) + nrow(td_plain))
})

test_that("tidy.icc_dstudy always carries `occasions`, `level` and `type`", {
  fit <- icc(ratings, score, subject, rater, seed = 1)
  td <- tidy(d_study(fit, m = 2:4))
  expect_identical(
    names(td),
    c(
      "m",
      "occasions",
      "level",
      "term",
      "type",
      "estimate",
      "std.error",
      "conf.low",
      "conf.high",
      "conf.level",
      "method"
    )
  )
  # Not multilevel and not replicated: those two are NA, `type` is not.
  expect_true(all(is.na(td$occasions)))
  expect_true(all(is.na(td$level)))
  expect_false(any(is.na(td$type)))
})

test_that("glance.icc names the replicate split instead of shifting var_residual", {
  gl <- glance(icc(ratings, score, subject, rater, seed = 1))
  expect_true(all(
    c("var_subject_rater", "n_o", "rhat", "ess_bulk") %in% names(gl)
  ))
  # No replicates and no sampler: each of the four is NA, and `var_residual`
  # is the only error term the fit has.
  expect_true(is.na(gl$var_subject_rater))
  expect_true(is.na(gl$n_o))
  expect_true(is.na(gl$rhat))
  expect_true(is.na(gl$ess_bulk))
  expect_false(is.na(gl$var_residual))

  gl_rep <- glance(
    icc(replicate_frame(), score, subject, rater, seed = 1)
  )
  # With replicates both are reported, so which quantity `var_residual` holds
  # is readable from the row rather than inferred.
  expect_false(is.na(gl_rep$var_subject_rater))
  expect_identical(gl_rep$n_o, 2L)
})

# 3. d_study validates its interval settings ------------------------------------

test_that("d_study aborts classed on an out-of-range conf_level or sample count", {
  fit <- icc(ratings, score, subject, rater, seed = 1)
  expect_error(
    d_study(fit, m = 2:4, conf_level = 95),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, conf_level = c(0.9, 0.95)),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, mc_samples = 0),
    class = "intraclass_error"
  )
  expect_error(
    d_study(fit, m = 2:4, mc_samples = 10.5),
    class = "intraclass_error"
  )
  # The passing control: a valid pair still projects, and the level lands in
  # the reported column rather than merely being accepted.
  ok <- tidy(d_study(fit, m = 2:4, conf_level = 0.9, mc_samples = 500L))
  expect_true(all(ok$conf.level == 0.9))
})
