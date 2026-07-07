# Incomplete & imbalanced designs -- connectedness + k_eff (M3 Slice 1) ----------
#
# Estimand + decisions: estimand-spec M3 §3 (connectedness), §5 / ADR-008 (k_eff).
# Oracle-first numeric checks (lme4 cross-check, seeded unbalanced simulation)
# live in the Slice 1 oracle task; this file covers the design logic and guards.

# A small, deliberately DISCONNECTED design: {S1,S2}x{J1,J2} and {S3,S4}x{J3,J4}
# form two components with no shared ratings, so sigma^2_s and sigma^2_r cannot be
# separated (M3 §3).
disconnected_design <- function() {
  data.frame(
    subject = factor(c("S1", "S1", "S2", "S2", "S3", "S3", "S4", "S4")),
    rater = factor(c("J1", "J2", "J1", "J2", "J3", "J4", "J3", "J4")),
    score = c(4, 5, 6, 5, 7, 8, 6, 7)
  )
}

test_that("summarize_design reports a balanced complete design", {
  info <- summarize_design(sf_ratings_long())
  expect_true(info$balanced)
  expect_true(info$connected)
  expect_false(info$has_replicates)
  expect_equal(info$n_cells, 24L)
  expect_equal(info$k_eff, 4) # all n_i = 4, so k_eff = k
})

test_that("summarize_design computes k_eff as the harmonic mean under imbalance", {
  d <- sf_ratings_long()
  # Drop two cells but keep every subject and rater linked (still connected).
  d2 <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2"),
  ]
  d2$subject <- droplevels(d2$subject)
  d2$rater <- droplevels(d2$rater)
  info <- summarize_design(d2)
  ni <- c(3, 3, 4, 4, 4, 4) # S1, S2 lost one rating each
  expect_false(info$balanced)
  expect_true(info$connected)
  expect_equal(info$n_cells, 22L)
  expect_equal(info$k_eff, 1 / mean(1 / ni))
})

test_that("a disconnected subject-by-rater design is detected", {
  expect_false(summarize_design(disconnected_design())$connected)
})

test_that("icc() aborts on a disconnected design (#5, unidentified)", {
  expect_error(
    icc(disconnected_design(), score, subject, rater),
    class = "intraclass_unidentified"
  )
})

test_that("icc() aborts on within-cell replicates (unsupported)", {
  d <- sf_ratings_long()
  dup <- rbind(d, d[d$subject == "S1" & d$rater == "J1", ])
  expect_error(
    icc(dup, score, subject, rater),
    class = "intraclass_unsupported"
  )
})

test_that("the incomplete-data code path reproduces the balanced oracle", {
  # On complete data k_eff == k, so the M1/M2 numbers must be unchanged.
  fit <- icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  expect_equal(icc_estimate(fit, "ICC(A,1)"), 0.290, tolerance = 1e-3)
  expect_equal(icc_estimate(fit, "ICC(A,k)"), 0.620, tolerance = 1e-3)
})

test_that("incomplete but connected data yields finite estimates in range", {
  d <- sf_ratings_long()
  d2 <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S3" & d$rater == "J4"),
  ]
  fit <- icc(
    d2,
    score,
    subject,
    rater,
    unit = c("single", "average"),
    seed = 1
  )
  est <- generics::tidy(fit)$estimate
  expect_true(all(is.finite(est)))
  expect_true(all(est >= 0 & est <= 1))
})

# --- Oracle O5: incomplete random-rater path (provenance data-raw/oracle-incomplete.R)

test_that("incomplete random-rater ICCs match an independent lme4 fit (O5)", {
  skip_if_not_installed("lme4")
  d <- sf_ratings_long()
  d2 <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2"),
  ]
  d2$subject <- droplevels(d2$subject)
  d2$rater <- droplevels(d2$rater)
  k_eff <- 1 / mean(1 / c(3, 3, 4, 4, 4, 4))

  # Independent REML implementation of the SAME ragged mixed model.
  m <- lme4::lmer(
    score ~ 1 + (1 | subject) + (1 | rater),
    data = d2,
    REML = TRUE
  )
  vc <- as.data.frame(lme4::VarCorr(m))
  v <- function(g) vc$vcov[vc$grp == g][1]
  s <- v("subject")
  r <- v("rater")
  e <- v("Residual")
  oracle <- c(
    "ICC(A,1)" = s / (s + r + e),
    "ICC(A,k)" = s / (s + (r + e) / k_eff),
    "ICC(C,1)" = s / (s + e),
    "ICC(C,k)" = s / (s + e / k_eff)
  )

  a <- generics::tidy(
    icc(d2, score, subject, rater, unit = c("single", "average"), seed = 1)
  )
  cc <- generics::tidy(icc(
    d2,
    score,
    subject,
    rater,
    type = "consistency",
    unit = c("single", "average"),
    seed = 1
  ))
  ours <- c(
    "ICC(A,1)" = a$estimate[1],
    "ICC(A,k)" = a$estimate[2],
    "ICC(C,1)" = cc$estimate[1],
    "ICC(C,k)" = cc$estimate[2]
  )
  expect_equal(ours, oracle[names(ours)], tolerance = 1e-4)
})

test_that("the incomplete estimator recovers known population components (O5)", {
  # Seeded MCAR-incomplete design; k = 30 raters so sigma^2_r is identified in a
  # single draw (few-rater sigma^2_r is honestly noisy, not a bug). #1, #3, #12.
  set.seed(20260706)
  ns <- 120L
  k <- 30L
  s2s <- 4
  s2r <- 1
  s2res <- 2
  subj <- rnorm(ns, 0, sqrt(s2s))
  rat <- rnorm(k, 0, sqrt(s2r))
  full <- expand.grid(subject = factor(seq_len(ns)), rater = factor(seq_len(k)))
  full$score <- 10 +
    subj[as.integer(full$subject)] +
    rat[as.integer(full$rater)] +
    rnorm(nrow(full), 0, sqrt(s2res))
  sim <- full[runif(nrow(full)) > 0.25, ] # ~25% MCAR deletion
  sim$subject <- droplevels(sim$subject)
  sim$rater <- droplevels(sim$rater)
  expect_false(summarize_design(sim)$balanced)
  expect_true(summarize_design(sim)$connected)

  tidy_a <- generics::tidy(icc(
    sim,
    score,
    subject,
    rater,
    type = "agreement",
    seed = 7
  ))
  tidy_c <- generics::tidy(icc(
    sim,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 7
  ))
  pop_a1 <- s2s / (s2s + s2r + s2res)
  pop_c1 <- s2s / (s2s + s2res)
  expect_equal(tidy_a$estimate[1], pop_a1, tolerance = 0.05)
  expect_equal(tidy_c$estimate[1], pop_c1, tolerance = 0.05)
  # Boundary-aware Monte-Carlo interval covers the population value (#3).
  expect_gte(pop_a1, tidy_a$conf.low[1])
  expect_lte(pop_a1, tidy_a$conf.high[1])
  expect_gte(pop_c1, tidy_c$conf.low[1])
  expect_lte(pop_c1, tidy_c$conf.high[1])
})

test_that("glance() surfaces completeness, cell count, and k_eff", {
  d <- sf_ratings_long()
  d2 <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2"),
  ]
  g <- generics::glance(icc(d2, score, subject, rater, seed = 1))
  expect_false(g$balanced)
  expect_equal(g$n_cells, 22L)
  expect_equal(g$k_eff, 1 / mean(1 / c(3, 3, 4, 4, 4, 4)))

  gb <- generics::glance(icc(
    sf_ratings_long(),
    score,
    subject,
    rater,
    seed = 1
  ))
  expect_true(gb$balanced)
  expect_equal(gb$k_eff, 4)
})

test_that("print surfaces incomplete design and the effective k", {
  d <- sf_ratings_long()
  d2 <- d[
    !(d$subject == "S1" & d$rater == "J1") &
      !(d$subject == "S2" & d$rater == "J2"),
  ]
  fit <- icc(d2, score, subject, rater, unit = c("single", "average"), seed = 1)
  expect_snapshot(print(fit), transform = mask_ci)
})

test_that("incomplete-design error messages are stable", {
  expect_snapshot(
    icc(disconnected_design(), score, subject, rater),
    error = TRUE
  )
  dup <- rbind(sf_ratings_long(), sf_ratings_long()[1, ])
  expect_snapshot(
    icc(dup, score, subject, rater),
    error = TRUE
  )
})
