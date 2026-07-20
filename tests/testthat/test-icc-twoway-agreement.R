# test-icc-twoway-agreement.R
# ===========================================================================
# Milestone 1 — two-way random-effects, ABSOLUTE AGREEMENT ICCs:
#   ICC(A,1) and ICC(A,k), estimated via a linear mixed model (lme4/glmmTMB).
#
# Written BEFORE the estimator exists (tdd-workflow: tests first). Until M1
# implements icc(), these tests will error/skip — that red state is the point.
#
# Oracle: Shrout & Fleiss (1979) worked example (see helper-shrout-fleiss.R),
# cross-checked against psych::ICC(). Two independent oracle types are used
# here (published paper value + independent implementation); a seeded
# simulation with known variance components is the third, added as its own
# test file in M1.
# ===========================================================================

# PROVISIONAL call to the not-yet-built API. Centralised so M1 can adjust the
# signature in ONE place without touching any oracle value. The unquoted column
# arguments assume tidy-eval; if M1 chooses string arguments instead, change
# them here only.
fit_sf_agreement <- function(seed = NULL) {
  # M0 scaffolding guard: the estimator lands in M1. Until `icc()` exists these
  # oracle tests SKIP (keeping CI green) rather than error; the guard removes
  # itself automatically the moment M1 defines `icc()`. Documented, time-bound
  # skip per PRINCIPLES.md #10. Do not touch the oracle values below.
  skip_if_not(
    exists("icc", mode = "function"),
    "icc() estimator is implemented in Milestone 1 (see project/MILESTONES.md)."
  )
  # `seed` is passed only where a deterministic Monte-Carlo CI is needed (e.g.
  # the print snapshot); the point-estimate oracles do not depend on it.
  icc(
    data = sf_ratings_long(),
    score = score,
    subject = subject,
    rater = rater,
    model = "twoway",
    type = "agreement", # absolute agreement (not consistency)
    unit = c("single", "average"), # -> ICC(A,1) and ICC(A,k)
    engine = "glmmTMB", # M1 default engine (ADR-002); lme4 is oracle-only
    conf_level = 0.95,
    seed = seed
  )
}

test_that("ICC(A,1) matches the published Shrout & Fleiss (1979) value", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf_agreement()
  est <- icc_estimate(fit, "ICC(A,1)")

  # SF Table 4 prints ICC(2,1) = .29 (two decimals); 0.290 is the
  # psych/DescTools reproduction (M72, D-008). Balanced data => the
  # mixed-model estimate should round to that 3-dp value exactly.
  expect_equal(round(est, 3), sf_oracle[["ICC(A,1)"]])
})

test_that("ICC(A,k) matches the published Shrout & Fleiss (1979) value", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf_agreement()
  est <- icc_estimate(fit, "ICC(A,k)")

  # SF Table 4 prints ICC(2,k) = .62 (two decimals); 0.620 is the
  # psych/DescTools reproduction (M72, D-008).
  expect_equal(round(est, 3), sf_oracle[["ICC(A,k)"]])
})

test_that("estimates agree with psych::ICC at full precision (balanced data)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("psych")

  fit <- fit_sf_agreement()

  # Independent implementation on the same matrix. psych labels the two-way
  # random, absolute-agreement forms ICC2 (single) and ICC2k (average).
  res <- psych::ICC(sf_ratings_wide())$results
  psych_a1 <- res$ICC[res$type == "ICC2"]
  psych_ak <- res$ICC[res$type == "ICC2k"]

  # Balanced data => REML components == ANOVA components => near-exact match.
  expect_equal(icc_estimate(fit, "ICC(A,1)"), psych_a1, tolerance = 1e-4)
  expect_equal(icc_estimate(fit, "ICC(A,k)"), psych_ak, tolerance = 1e-4)
})

test_that("tidy() output honours the estimator contract", {
  skip_if_not_installed("glmmTMB")

  fit <- fit_sf_agreement()
  td <- generics::tidy(fit)

  expect_s3_class(td, "tbl_df")
  expect_contains(names(td), c("index", "estimate", "conf.low", "conf.high"))
  expect_contains(td$index, c("ICC(A,1)", "ICC(A,k)"))

  # Every estimate finite and at or below the theoretical upper bound of 1.
  expect_true(all(is.finite(td$estimate)))
  expect_true(all(td$estimate <= 1))

  # A confidence interval must bracket its point estimate.
  expect_true(all(td$conf.low <= td$estimate))
  expect_true(all(td$estimate <= td$conf.high))
})

test_that("averaging raises reliability: ICC(A,k) > ICC(A,1)", {
  skip_if_not_installed("glmmTMB")

  # Oracle-independent invariant (Spearman-Brown): for a positive single-rater
  # ICC, the k-rater average is strictly larger. Cheap guard against a label
  # swap or a numerator/denominator mix-up that a single point oracle can miss.
  fit <- fit_sf_agreement()
  expect_gt(icc_estimate(fit, "ICC(A,k)"), icc_estimate(fit, "ICC(A,1)"))
})

test_that("print() output is stable", {
  skip_if_not_installed("glmmTMB")

  # Seeded for determinism (#12); the CI digits are masked because they vary at
  # ~1e-3 across platforms even when seeded (see helper-format.R). The point
  # estimates and variance components in the printout remain checked verbatim.
  fit <- fit_sf_agreement(seed = 1)
  expect_snapshot(print(fit), transform = mask_ci)
})
