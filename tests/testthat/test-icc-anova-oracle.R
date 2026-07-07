# O2 — package-independent ANOVA mean-squares oracle -------------------------
# The third, most independent oracle (REFERENCES.md O2): derive the variance
# components from base-R ANOVA mean squares via the method-of-moments identities
# (estimand-spec §4), not from another ICC package, and confirm the mixed-model
# engine reproduces them (and the resulting ICCs) on balanced data. Everything is
# computed in R and reproducible; no value is hardcoded (PRINCIPLES.md #4).

test_that("engine variance components match ANOVA method-of-moments (O2)", {
  skip_if_not_installed("glmmTMB")

  d <- sf_ratings_long()
  n <- nlevels(d$subject)
  k <- nlevels(d$rater)

  # Two-way ANOVA mean squares (base stats, independent of the mixed model).
  ms <- summary(stats::aov(score ~ subject + rater, data = d))[[1]][, "Mean Sq"]
  bms <- ms[[1]] # between subjects
  jms <- ms[[2]] # between raters
  ems <- ms[[3]] # residual

  # Method-of-moments components (estimand-spec §4).
  vs <- (bms - ems) / k
  vr <- (jms - ems) / n
  vres <- ems

  g <- glance(icc(d, score, subject, rater, seed = 1))
  expect_equal(g$var_subject, vs, tolerance = 1e-4)
  expect_equal(g$var_rater, vr, tolerance = 1e-4)
  expect_equal(g$var_residual, vres, tolerance = 1e-4)

  # And the ICCs derived from those components match the reported ones.
  a1 <- vs / (vs + vr + vres)
  ak <- vs / (vs + (vr + vres) / k)
  td <- tidy(icc(d, score, subject, rater, seed = 1))
  expect_equal(td$estimate[td$index == "ICC(A,1)"], a1, tolerance = 1e-4)
  expect_equal(td$estimate[td$index == "ICC(A,k)"], ak, tolerance = 1e-4)
})
