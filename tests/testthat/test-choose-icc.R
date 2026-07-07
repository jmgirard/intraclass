# M12 (ADR-021): choose_icc() decision helper -----------------------------------
#
# No new estimand, so PRINCIPLES.md #1 is numerically N/A. Correctness rests on:
#  (a) a ROUND-TRIP ORACLE -- the emitted icc() call, run on data, produces
#      exactly the coefficient rows (level + index + Shrout-Fleiss label) the
#      recommendation claims. The helper cannot recommend a call that disagrees
#      with icc();
#  (b) the McGraw-Wong <-> Shrout-Fleiss crosswalk labels matching the
#      "Choosing an ICC" vignette table verbatim;
#  (c) ill-posed / underspecified selections failing loudly (#5, classed).

# Balanced Design-1 multilevel fixture (as in test-icc-multilevel.R): columns
# score, subject, rater, cluster -- the names the emitted multilevel call uses.
sim_ml_choose <- function(seed = 11) {
  set.seed(seed)
  nc <- 6
  ns <- 4
  k <- 3
  cl <- stats::rnorm(nc, 0, 1)
  rt <- stats::rnorm(k, 0, 0.6)
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, 1.2)
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, 0.5)
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, 1)
  data.frame(
    score = d$score,
    subject = factor(paste(d$cluster, d$subj, sep = "_")),
    rater = factor(d$rater),
    cluster = factor(d$cluster)
  )
}

# Run the icc() call string a recommendation emits, on the supplied data. The
# call references `data` positionally with NSE column names score/subject/rater
# (/cluster), which the fixtures provide.
run_emitted_call <- function(rec, data) {
  suppressWarnings(eval(
    parse(text = rec$call)[[1L]],
    envir = list(data = data)
  ))
}

# --- (a) round-trip oracle: two-way, every valid axis combination -------------

test_that("emitted two-way call reproduces the recommended coefficient rows", {
  grid <- expand.grid(
    type = c("agreement", "consistency"),
    unit = c("single", "average", "both"),
    raters = c("random", "fixed"),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(grid))) {
    rec <- choose_icc(
      type = grid$type[i],
      unit = grid$unit[i],
      raters = grid$raters[i]
    )
    fit <- run_emitted_call(rec, ratings)
    est <- fit$estimates
    # The recommended index labels are exactly those the fit computes.
    expect_setequal(rec$rows$index, est$index)
    # And the Shrout-Fleiss labels align index-for-index with the fit.
    ord_rec <- rec$rows[order(rec$rows$index), ]
    ord_est <- est[order(est$index), ]
    expect_equal(ord_rec$sf_index, ord_est$sf_index)
  }
})

test_that("emitted one-way call reproduces the recommended coefficient rows", {
  for (u in c("single", "average", "both")) {
    rec <- choose_icc(model = "oneway", unit = u)
    fit <- run_emitted_call(rec, ratings)
    expect_setequal(rec$rows$index, fit$estimates$index)
    ord_rec <- rec$rows[order(rec$rows$index), ]
    ord_est <- fit$estimates[order(fit$estimates$index), ]
    expect_equal(ord_rec$sf_index, ord_est$sf_index)
  }
})

test_that("emitted multilevel call reproduces the recommended (level, index) rows", {
  skip_on_cran()
  ml <- sim_ml_choose()
  rec <- choose_icc(
    type = "agreement",
    unit = "both",
    raters = "random",
    multilevel = TRUE,
    level = "both"
  )
  fit <- run_emitted_call(rec, ml)
  key_rec <- paste(rec$rows$level, rec$rows$index)
  key_est <- paste(fit$estimates$level, fit$estimates$index)
  expect_setequal(key_rec, key_est)
})

# --- (b) the McGraw-Wong <-> Shrout-Fleiss crosswalk (vignette table) ----------

test_that("the recommended labels match the vignette crosswalk verbatim", {
  # agreement x random -> ICC(A,1)/ICC(A,k) = SF ICC(2,1)/ICC(2,k)
  ar <- choose_icc(type = "agreement", unit = "both", raters = "random")$rows
  expect_equal(ar$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_equal(ar$sf_index, c("ICC(2,1)", "ICC(2,k)"))

  # consistency x fixed -> ICC(C,1)/ICC(C,k) = SF ICC(3,1)/ICC(3,k)
  cf <- choose_icc(type = "consistency", unit = "both", raters = "fixed")$rows
  expect_equal(cf$index, c("ICC(C,1)", "ICC(C,k)"))
  expect_equal(cf$sf_index, c("ICC(3,1)", "ICC(3,k)"))

  # the two off-diagonal forms are McGraw-Wong-only: no SF label.
  cr <- choose_icc(type = "consistency", unit = "both", raters = "random")$rows
  expect_equal(cr$index, c("ICC(C,1)", "ICC(C,k)"))
  expect_true(all(is.na(cr$sf_index)))

  af <- choose_icc(type = "agreement", unit = "both", raters = "fixed")$rows
  expect_equal(af$index, c("ICC(A,1)", "ICC(A,k)"))
  expect_true(all(is.na(af$sf_index)))

  # one-way -> ICC(1)/ICC(k) = SF ICC(1,1)/ICC(1,k)
  ow <- choose_icc(model = "oneway", unit = "both")$rows
  expect_equal(ow$index, c("ICC(1)", "ICC(k)"))
  expect_equal(ow$sf_index, c("ICC(1,1)", "ICC(1,k)"))
})

# --- emitted call strings are the minimal, copy-pasteable forms ---------------

test_that("emitted calls show only the non-default arguments", {
  expect_equal(
    choose_icc(type = "agreement", unit = "both", raters = "random")$call,
    "icc(data, score, subject, rater)"
  )
  expect_equal(
    choose_icc(type = "consistency", unit = "single", raters = "fixed")$call,
    'icc(data, score, subject, rater, type = "consistency", raters = "fixed", unit = "single")'
  )
  expect_equal(
    choose_icc(model = "oneway", unit = "average")$call,
    'icc(data, score, subject, rater, model = "oneway", unit = "average")'
  )
  expect_equal(
    choose_icc(
      type = "agreement",
      unit = "both",
      raters = "random",
      multilevel = TRUE,
      level = "cluster"
    )$call,
    'icc(data, score, subject, rater, cluster, level = "cluster")'
  )
})

# --- (c) applicability and underspecification aborts (#5, classed) ------------

test_that("axes that do not apply to the chosen design are rejected", {
  expect_error(
    choose_icc(model = "oneway", unit = "single", type = "agreement"),
    class = "intraclass_inapplicable"
  )
  expect_error(
    choose_icc(model = "oneway", unit = "single", raters = "fixed"),
    class = "intraclass_inapplicable"
  )
  expect_error(
    choose_icc(model = "oneway", unit = "single", multilevel = TRUE),
    class = "intraclass_inapplicable"
  )
  # level without a multilevel design
  expect_error(
    choose_icc(
      type = "agreement",
      unit = "single",
      raters = "random",
      level = "cluster"
    ),
    class = "intraclass_inapplicable"
  )
})

test_that("unanswered coefficient-selecting decisions abort loudly", {
  expect_error(
    choose_icc(unit = "single", raters = "random"),
    class = "intraclass_underspecified"
  )
  expect_error(
    choose_icc(type = "agreement", unit = "single"),
    class = "intraclass_underspecified"
  )
  expect_error(
    choose_icc(type = "agreement", raters = "random"),
    class = "intraclass_underspecified"
  )
  # multilevel without a level answer
  expect_error(
    choose_icc(
      type = "agreement",
      unit = "single",
      raters = "random",
      multilevel = TRUE
    ),
    class = "intraclass_underspecified"
  )
})

test_that("invalid answer values abort with a classed intraclass error", {
  expect_error(
    choose_icc(type = "sometimes", unit = "single", raters = "random"),
    class = "intraclass_error"
  )
  expect_error(
    choose_icc(type = "agreement", unit = "occasionally", raters = "random"),
    class = "intraclass_error"
  )
  expect_error(
    choose_icc(type = "agreement", unit = "single", raters = "maybe"),
    class = "intraclass_error"
  )
  expect_error(
    choose_icc(
      type = "agreement",
      unit = "single",
      raters = "random",
      multilevel = "yes"
    ),
    class = "intraclass_error"
  )
})

# --- object + print -----------------------------------------------------------

test_that("choose_icc() returns a printable icc_recommendation", {
  rec <- choose_icc(type = "agreement", unit = "single", raters = "random")
  expect_s3_class(rec, "icc_recommendation")
  out <- format(rec)
  expect_true(any(grepl("Recommended ICC", out)))
  expect_true(any(grepl("icc(data, score, subject, rater", out, fixed = TRUE)))
  expect_true(any(grepl("ICC(A,1)", out, fixed = TRUE)))
  expect_invisible(print(rec))
})
