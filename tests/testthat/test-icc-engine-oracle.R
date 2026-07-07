# Cross-engine oracle — lme4 as an independent implementation ------------------
# ADR-002: in M1 lme4 is oracle-only. Fit the same model with lme4 directly and
# confirm the glmmTMB engine's point estimates agree to tight tolerance. On
# balanced data both REML fits recover the same variance components, so a loose
# match here would be a bug, not a tolerance to relax (PRINCIPLES.md #1).

test_that("glmmTMB point estimates match lme4 (independent engine oracle)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")

  d <- sf_ratings_long()
  k <- nlevels(d$rater)

  m <- lme4::lmer(
    score ~ 1 + (1 | subject) + (1 | rater),
    data = d,
    REML = TRUE
  )
  vc <- as.data.frame(lme4::VarCorr(m))
  vs <- vc$vcov[vc$grp == "subject"]
  vr <- vc$vcov[vc$grp == "rater"]
  vres <- vc$vcov[vc$grp == "Residual"]

  lme4_a1 <- vs / (vs + vr + vres)
  lme4_ak <- vs / (vs + (vr + vres) / k)

  td <- tidy(icc(d, score, subject, rater, seed = 1))
  expect_equal(td$estimate[td$index == "ICC(A,1)"], lme4_a1, tolerance = 1e-4)
  expect_equal(td$estimate[td$index == "ICC(A,k)"], lme4_ak, tolerance = 1e-4)
})
