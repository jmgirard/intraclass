# Statistical-corner guards (M51 / GP7) ---------------------------------------
#
# One consolidated home for the "load-bearing subtlety" guards, mirroring M50's
# `test-boundary-policy.R`. GP7 (DESIGN.md): a correct-but-non-obvious statistical
# corner ships with a guard test that fails on the plausible "simplification" plus
# an in-place comment naming its ADR/D-entry, so a future contributor cannot
# silently simplify it into wrongness. These tests PIN existing behavior; M51
# changed none of it.
#
# The M51 audit (inventory in the milestone work log) kept six corners. Two were
# UNGUARDED and are pinned here; four are ALREADY guarded by live tests and are
# cross-referenced so the audit reads as a whole:
#   A. Fixed-rater 2b moment family    -- UNGUARDED -> pinned below (tests 1-4)
#   D. Ragged coverage n_rep >= 240    -- UNGUARDED for the fixed-nested fixture
#                                         -> pinned below (test 5)
#   B. brms MAP = mode of ICC draws (ADR-033) -- guarded: test-icc-brms.R:386-387
#      (non-Stan live recompute; MAP(ICC) != icc_point(MAP components)).
#   C. SEM fixed-agreement Case-3A (M21)      -- guarded: test-icc-lavaan.R:320,357
#      (corrected theta^2_r distinct from raw; reduces to glmmTMB fixed+random).
#   E. Cluster-count sweep axis (GP6, ADR-046) -- guarded: O-NFI `by_cn(80, .)` in
#      test-icc-fixed-multilevel.R requires the high-C_n cell in the grid.
#   F. Incomplete-agreement handling          -- guarded: test-icc-incomplete.R:97,147
#      (live lme4 parity + known-population recovery, O5).

# --- A. Fixed-rater theta^2_r 2b moment correction + average-floor ------------
#
# The finite-population fixed-rater variance push-forward subtracts 2b (NOT 1b)
# per draw and floors the AVERAGE over groups/clusters (NOT each group). ADR-037
# (brms) / ADR-038 (frequentist), gated Fable review #19. Two plausible
# simplifications a future contributor might make, each SILENTLY wrong:
#   (i)  `- 2 * b` -> `- b` (1b): undercovers at the boundary, worse as clusters
#        accrue (the incidental-parameters collapse; O-NFI history).
#   (ii) floor each group then average, instead of averaging then flooring:
#        per-group flooring cannot reach theta^2 = 0, so ZERO boundary coverage.
# The shipped value below (0.4725) differs from the 1b value (0.7475) and the
# per-group-floor value (0.75), so either simplification turns these tests red.

# Centering matrix C = I - J/k for k = 2 (the quadratic form mu' C mu / (k-1)).
corner_center2 <- diag(2) - matrix(1 / 2, 2, 2)

test_that("theta2r_moment_draws subtracts 2b, not 1b (frequentist, ADR-038)", {
  # Group A means (1, -1): raw q = 2. Group B means (0.2, -0.1): raw q = 0.045.
  m_a <- matrix(c(1, -1), nrow = 2)
  m_b <- matrix(c(0.2, -0.1), nrow = 2)
  b_a <- 0.25
  b_b <- 0.30

  # Shipped: mean(2 - 2*0.25, 0.045 - 2*0.30) = mean(1.5, -0.555) = 0.4725, then
  # floored (average is positive, so unchanged). Hand-computed, independent of the
  # implementation.
  expect_equal(
    theta2r_moment_draws(list(m_a, m_b), list(b_a, b_b), corner_center2, 2L),
    0.4725
  )
  # 1b would give mean(1.75, -0.255) = 0.7475 -- a DIFFERENT number, so `- b`
  # instead of `- 2 * b` fails the assertion above.
  expect_false(isTRUE(all.equal(0.4725, 0.7475)))
})

test_that("theta2r_moment_draws floors the average, not each group (ADR-038 / #3)", {
  m_a <- matrix(c(1, -1), nrow = 2) # q - 2b = 1.5  (positive)
  m_b <- matrix(c(0.2, -0.1), nrow = 2) # q - 2b = -0.555 (negative)

  # Averaging FIRST keeps the negative group, so the average is 0.4725. Per-group
  # flooring would zero group B first -> mean(1.5, 0) = 0.75. The shipped 0.4725
  # proves the negative group survives into the average.
  expect_equal(
    theta2r_moment_draws(list(m_a, m_b), list(0.25, 0.30), corner_center2, 2L),
    0.4725
  )
  # The floor DOES engage on the average: two negative groups -> exactly 0, so the
  # interval can reach the boundary theta^2 = 0 (never below).
  expect_identical(
    theta2r_moment_draws(list(m_b, m_b), list(0.30, 0.30), corner_center2, 2L),
    0
  )
})

test_that("theta2r_nested_draws applies 2b + average-floor per cluster (ADR-046)", {
  # The generalized unequal-k nested helper: rows of beta_draws are rater coeffs,
  # grouped by cluster via th$cluster_idx, each with its own center/k/bias. Build
  # two equal-k clusters matching the flat-helper fixture so the value is the same
  # 0.4725 -- pinning that the nested path also subtracts 2b and floors the average.
  beta <- matrix(c(1, -1, 0.2, -0.1), ncol = 1)
  th <- list(
    cluster_idx = list(1:2, 3:4),
    center = list(corner_center2, corner_center2),
    k = list(2L, 2L),
    bias = list(0.25, 0.30)
  )
  expect_equal(as.numeric(theta2r_nested_draws(beta, th)), 0.4725)
})

test_that("brms_theta2r_moment_draws subtracts 2b + floors the average (ADR-037)", {
  # brms estimates b EMPIRICALLY from the draw covariance, so this needs >1 draw.
  # Two groups, 2 raters, 3 draws each; means chosen so group 2's corrected value
  # is negative while the average is positive (the floor discriminator).
  m1 <- matrix(c(1.0, -1.0, 1.2, -1.1, 0.9, -0.8), nrow = 2)
  m2 <- matrix(c(0.10, -0.05, 0.20, -0.15, 0.00, 0.05), nrow = 2)

  # Independent dumb recompute of the SAME 2b/average-floor formula (invariant
  # oracle): if the shipped code drops to 1b or floors per-group, it diverges.
  per <- function(m, mult, floor_each) {
    k <- nrow(m)
    cc <- diag(k) - matrix(1 / k, k, k)
    q <- colSums(m * (cc %*% m)) / (k - 1)
    b <- sum(diag(cc %*% stats::cov(t(m)))) / (k - 1)
    v <- q - mult * b
    if (floor_each) pmax(0, v) else v
  }
  expected_2b_avgfloor <- pmax(0, (per(m1, 2, FALSE) + per(m2, 2, FALSE)) / 2)
  got <- brms_theta2r_moment_draws(list(m1, m2))
  expect_equal(got, expected_2b_avgfloor)

  # And the guard is DISCRIMINATING: the 1b and per-group-floor variants give
  # different numbers, so a simplification to either would fail the equality above.
  one_b <- pmax(0, (per(m1, 1, FALSE) + per(m2, 1, FALSE)) / 2)
  per_group <- (per(m1, 2, TRUE) + per(m2, 2, TRUE)) / 2
  expect_false(isTRUE(all.equal(got, one_b)))
  expect_false(isTRUE(all.equal(got, per_group)))
})

# --- D. Ragged coverage oracle precision: n_rep >= 240 + per-rep seeding ------
#
# GP5 (DESIGN.md; canonical ADR-042 Amdt 2): a coverage claim on ragged data uses
# n_rep >= 240 with per-rep seeding, not 80 -- the .88 pin false-alarms ~0.7%/cell
# at n_rep = 80 (a tail event, [[ragged-coverage-nrep-240]]). The incomplete-
# MULTILEVEL fixture already pins this (test-icc-incomplete-multilevel.R:563); the
# incomplete-FIXED-NESTED coverage fixture did not, so regenerating it at a smaller
# n_rep would silently loosen the O-IFNML coverage guard. Pin the committed
# fixture's replication count so that can't happen unnoticed.

test_that("incomplete-fixed-nested coverage fixture keeps n_rep >= 240 (GP5)", {
  o <- readRDS(test_path("fixtures", "incomplete-fixed-nested-oracle.rds"))
  expect_true("n_rep" %in% names(o))
  expect_gte(min(o$n_rep), 240L)
})
