# Regression tests for the pre-CRAN code-review findings ------------------------
#
# Each block pins a fix from the max-effort statistical-core review. Numbered to
# match the review's finding list. Correctness fixes are behaviour changes and are
# pinned here so they cannot silently regress (PRINCIPLES.md #1/#5/#8).

# A small balanced crossed (Design 1) multilevel dataset.
review_ml_crossed <- function(nc = 4L, ns = 4L, k = 3L, seed = 2L) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, 1.2)
  sc <- stats::rnorm(nc * ns, 0, 1.0)
  rat <- stats::rnorm(k, 0, 1)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  d$score <- 10 +
    cl[d$cluster] +
    sc[(d$cluster - 1) * ns + d$subj] +
    rat[d$rater] +
    stats::rnorm(nrow(d), 0, 1)
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# Finding 2 -- d_study() on a one-way fit -------------------------------------
test_that("d_study() projects a one-way fit instead of crashing (review #2)", {
  skip_if_not_installed("glmmTMB")
  f <- icc(ratings, score, subject, rater, model = "oneway", seed = 1)
  ds <- d_study(f, m = c(1, 4, 8))
  expect_s3_class(ds, "icc_dstudy")
  expect_identical(ds$index, c("ICC(1)", "ICC(4)", "ICC(8)"))
  # At m = 1 the projection is the one-way single-rater ICC(1); the curve rises.
  icc1 <- icc(
    ratings,
    score,
    subject,
    rater,
    model = "oneway",
    unit = "single",
    seed = 1
  )$estimates$estimate
  expect_equal(ds$estimate[ds$m == 1], icc1, tolerance = 1e-6)
  expect_true(all(diff(ds$estimate) > 0))
})

# Finding 3 -- fixed-rater multilevel default call ----------------------------
test_that("fixed-rater multilevel default call needs no explicit level (review #3)", {
  skip_if_not_installed("glmmTMB")
  d <- review_ml_crossed()
  # Default `level = c("subject", "cluster")`: on balanced crossed data BOTH levels ship
  # for fixed raters -- subject (M10) and cluster (M37, ADR-047) -- so the natural call
  # returns both. (Incomplete/unbalanced still drops the cluster level to subject.)
  fit <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    seed = 1
  ))
  expect_s3_class(fit, "icc")
  expect_setequal(unique(fit$estimates$level), c("subject", "cluster"))
  # An explicit cluster-only request now SUCCEEDS on balanced data (M37); it equals the
  # random-rater cluster-level ICC (O-FCL/reduction in test-icc-fixed-multilevel.R).
  cl_only <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    level = "cluster",
    seed = 1
  ))
  expect_identical(unique(cl_only$estimates$level), "cluster")
})

# Finding 4 -- unidentified subject/residual split ----------------------------
test_that("incomplete crossed multilevel aborts when every subject is rated once (review #4)", {
  skip_if_not_installed("glmmTMB")
  # 3 clusters, each a single rater rating 2 subjects once -> within-cluster
  # connected (a star) but sigma^2_{s:c} is confounded with residual. Previously
  # returned a spurious ICC = 0.5; now a loud identifiability abort.
  d <- data.frame(
    cluster = factor(rep(1:3, each = 2)),
    subject = factor(paste0("c", rep(1:3, each = 2), "_s", rep(1:2, 3))),
    rater = factor(rep(1:3, each = 2)),
    score = stats::rnorm(6)
  )
  expect_error(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      type = "consistency",
      seed = 1
    ),
    class = "intraclass_unidentified"
  )
})

# Finding 6 -- mc_samples / seed validation -----------------------------------
test_that("mc_samples is validated with a classed error (review #6)", {
  skip_if_not_installed("glmmTMB")
  for (bad in list(0, 1, 1.5, -3, NA_real_, c(10, 20), "x")) {
    expect_error(
      icc(ratings, score, subject, rater, mc_samples = bad),
      class = "intraclass_error"
    )
  }
})

test_that("seed is validated with a classed error (review #6)", {
  skip_if_not_installed("glmmTMB")
  for (bad in list(1.5, "x", c(1, 2))) {
    expect_error(
      icc(ratings, score, subject, rater, seed = bad),
      class = "intraclass_error"
    )
  }
  # NULL (ambient RNG) and a whole number are accepted.
  expect_s3_class(icc(ratings, score, subject, rater, seed = NULL), "icc")
  expect_s3_class(icc(ratings, score, subject, rater, seed = 7), "icc")
})

# Finding 1 -- crossed detection surfaces the reused-label assumption ---------
test_that("auto-detected crossed multilevel notes the shared-label assumption (review #1)", {
  skip_if_not_installed("glmmTMB")
  withr::local_options(rlib_message_verbosity = "verbose")
  d <- review_ml_crossed()
  # Auto-detection (no `design =`) informs that same-labelled raters across
  # clusters are treated as the same raters.
  expect_message(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      level = "subject",
      seed = 1
    ),
    "same raters"
  )
  # Declaring `design` explicitly skips detection and its message.
  expect_no_message(
    icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "crossed",
      level = "subject",
      seed = 1
    )
  )
})
