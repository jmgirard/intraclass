# test-icc-consistency.R
# ===========================================================================
# Milestone 2 — two-way CONSISTENCY ICCs ICC(C,1)/ICC(C,k) and the
# fixed-vs-random rater distinction.
#
# Consistency drops the rater main effect from the error set (M2 spec §2).
# Fixed vs. random raters is a label/interpretation layer over the shared fit:
# on the balanced Shrout & Fleiss data the point estimate and CI are identical
# (M2 spec §3, ADR-006), verified directly below.
#
# Oracles: Shrout & Fleiss (1979) published ICC(3,*) values (helper), the
# independent psych::ICC() implementation (ICC3/ICC3k), and the fixed==random
# equivalence check that encodes the ADR-006 decision.
# ===========================================================================

fit_sf <- function(type = "consistency", raters = "random", seed = NULL) {
  suppressWarnings(icc(
    data = sf_ratings_long(),
    score = score,
    subject = subject,
    rater = rater,
    type = type,
    raters = raters,
    unit = c("single", "average"),
    seed = seed
  ))
}

test_that("ICC(C,1)/ICC(C,k) match the published Shrout & Fleiss values", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf()
  # Published ICC(3,1) = 0.715, ICC(3,k) = 0.909 (three decimals). Balanced
  # data => the mixed-model estimate rounds to the published value exactly.
  expect_equal(
    round(icc_estimate(fit, "ICC(C,1)"), 3),
    sf_oracle_all[["ICC(C,1)"]]
  )
  expect_equal(
    round(icc_estimate(fit, "ICC(C,k)"), 3),
    sf_oracle_all[["ICC(C,k)"]]
  )
})

test_that("consistency estimates agree with psych::ICC (balanced data)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("psych")

  fit <- fit_sf()
  res <- psych::ICC(sf_ratings_wide())$results
  # psych labels the consistency forms ICC3 (single) and ICC3k (average).
  psych_c1 <- res$ICC[res$type == "ICC3"]
  psych_ck <- res$ICC[res$type == "ICC3k"]

  expect_equal(icc_estimate(fit, "ICC(C,1)"), psych_c1, tolerance = 1e-4)
  expect_equal(icc_estimate(fit, "ICC(C,k)"), psych_ck, tolerance = 1e-4)
})

test_that("averaging raises reliability: ICC(C,k) > ICC(C,1)", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf()
  expect_gt(icc_estimate(fit, "ICC(C,k)"), icc_estimate(fit, "ICC(C,1)"))
})

test_that("consistency >= agreement, with equality only if rater variance is 0", {
  skip_if_not_installed("glmmTMB")

  # Oracle-independent invariant: consistency drops the rater main effect from
  # the error, so ICC(C,*) >= ICC(A,*); strict here since the SF raters differ
  # sharply in level (sigma^2_r large).
  agr <- fit_sf(type = "agreement")
  con <- fit_sf(type = "consistency")
  expect_gt(icc_estimate(con, "ICC(C,1)"), icc_estimate(agr, "ICC(A,1)"))
  expect_gt(icc_estimate(con, "ICC(C,k)"), icc_estimate(agr, "ICC(A,k)"))
})

test_that("fixed and random raters give identical estimates and CIs (balanced)", {
  skip_if_not_installed("glmmTMB")

  # Encodes ADR-006: on balanced data raters = "fixed" is a label layer over the
  # same fit, so point estimates and the seeded Monte-Carlo interval must match
  # random exactly (not merely to tolerance).
  for (ty in c("agreement", "consistency")) {
    rnd <- tidy(fit_sf(type = ty, raters = "random", seed = 42))
    fix <- tidy(fit_sf(type = ty, raters = "fixed", seed = 42))
    expect_equal(rnd$estimate, fix$estimate)
    expect_equal(rnd$conf.low, fix$conf.low)
    expect_equal(rnd$conf.high, fix$conf.high)
  }
})

test_that("raters = 'fixed' warns; 'random' is silent", {
  skip_if_not_installed("glmmTMB")

  expect_warning(
    icc(sf_ratings_long(), score, subject, rater, raters = "fixed", seed = 1),
    class = "intraclass_fixed_raters"
  )
  expect_no_warning(
    icc(sf_ratings_long(), score, subject, rater, raters = "random", seed = 1)
  )
})

test_that("fixed raters relabel the design without changing the number", {
  skip_if_not_installed("glmmTMB")

  fix <- fit_sf(type = "consistency", raters = "fixed", seed = 1)
  # Shrout & Fleiss equivalent for fixed-rater consistency is ICC(3,*).
  td <- tidy(fix)
  expect_identical(td$sf_index, c("ICC(3,1)", "ICC(3,k)"))
  expect_true(any(grepl("two-way mixed, consistency", format(fix))))
})

test_that("consistency print output is stable", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf(type = "consistency", raters = "fixed", seed = 1)
  expect_snapshot(print(fit), transform = mask_ci)
})
