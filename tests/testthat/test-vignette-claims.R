# Vignette claims (choosing-an-icc.Rmd) -----------------------------------
# The flagship "Choosing an ICC" article makes comparative statements in prose
# ("consistency is never smaller than agreement", "ICC(*,k) is always the larger
# number", "on this balanced design the fixed and random point estimates
# coincide"). Those claims must hold numerically on the shipped `ratings`
# dataset the article uses, so no teaching statement is unbacked
# (PRINCIPLES.md #1). Point estimates are seed-independent (the seed only fixes
# the Monte-Carlo interval); a seed is set purely for determinism.

test_that("consistency is never smaller than agreement on `ratings`", {
  skip_if_not_installed("glmmTMB")

  agr <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  con <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))

  # Row 1 = single ICC(*,1), row 2 = average ICC(*,k).
  expect_lte(agr$estimate[1], con$estimate[1])
  expect_lte(agr$estimate[2], con$estimate[2])
})

test_that("choosing-an-icc.Rmd: one-way ICC(1) is the most conservative on `ratings`", {
  skip_if_not_installed("glmmTMB")

  # The article's `model` section states one-way ICC(1) sits below the two-way
  # ICC(A,1) and ICC(C,1), because one-way absorbs the rater effect the two-way
  # coefficients separate. Back the claim numerically (#1).
  ow <- tidy(icc(ratings, score, subject, rater, model = "oneway", seed = 1))
  agr <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  con <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))
  i1 <- ow$estimate[ow$index == "ICC(1)"]
  expect_lte(i1, agr$estimate[agr$index == "ICC(A,1)"])
  expect_lte(
    agr$estimate[agr$index == "ICC(A,1)"],
    con$estimate[con$index == "ICC(C,1)"]
  )
})

test_that("the average coefficient is never smaller than the single", {
  skip_if_not_installed("glmmTMB")

  agr <- tidy(icc(ratings, score, subject, rater, type = "agreement", seed = 1))
  con <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    seed = 1
  ))

  expect_gte(agr$estimate[2], agr$estimate[1])
  expect_gte(con$estimate[2], con$estimate[1])
})

test_that("fixed and random point estimates coincide on balanced `ratings`", {
  skip_if_not_installed("glmmTMB")

  rnd <- tidy(icc(ratings, score, subject, rater, raters = "random", seed = 1))
  fix <- suppressWarnings(
    tidy(icc(ratings, score, subject, rater, raters = "fixed", seed = 1))
  )

  expect_equal(rnd$estimate, fix$estimate, tolerance = 1e-4)
})

# --- incomplete-design claims (section 4) --------------------------------

test_that("`ratings_incomplete` averages over a non-integer effective k", {
  skip_if_not_installed("glmmTMB")

  g <- glance(icc(ratings_incomplete, score, subject, rater, seed = 1))
  expect_false(g$balanced)
  # Harmonic mean of {4, 4, 3, 3, 3, 3} = 3.2727..., strictly between 3 and 4.
  expect_gt(g$k_eff, 3)
  expect_lt(g$k_eff, 4)
})

test_that("fixed and random diverge on incomplete data", {
  skip_if_not_installed("glmmTMB")

  rnd <- tidy(icc(
    ratings_incomplete,
    score,
    subject,
    rater,
    raters = "random",
    seed = 1
  ))
  fix <- suppressWarnings(tidy(icc(
    ratings_incomplete,
    score,
    subject,
    rater,
    raters = "fixed",
    seed = 1
  )))

  # Unlike the balanced case, the point estimates are no longer identical.
  expect_false(isTRUE(all.equal(rnd$estimate, fix$estimate, tolerance = 1e-4)))
})

# --- advanced-article D-study claims -------------------------------------

test_that("the D-study projection anchors to ICC(A,k) at m = n_raters", {
  skip_if_not_installed("glmmTMB")

  # The advanced article states Phi(m) at m = 4 (the raters in `ratings`) equals
  # the ICC(A,k) icc() reports directly. Point estimates are seed-independent.
  fit <- icc(ratings, score, subject, rater, seed = 1)
  proj <- d_study(fit, m = 1:8, seed = 1)

  at_k <- proj$estimate[proj$m == fit$n$raters]
  ick <- tidy(fit)$estimate[tidy(fit)$index == "ICC(A,k)"]
  expect_equal(at_k, ick, tolerance = 1e-8)

  # And the "diminishing returns" curve is monotone increasing.
  expect_true(all(diff(proj$estimate) > 0))
})

test_that("a disconnected design is rejected, not guessed at", {
  skip_if_not_installed("glmmTMB")

  disconnected <- data.frame(
    subject = factor(c(1, 1, 2, 2, 3, 3, 4, 4)),
    rater = factor(c(1, 2, 1, 2, 3, 4, 3, 4)),
    score = c(5, 6, 4, 5, 7, 8, 6, 7)
  )
  expect_error(
    icc(disconnected, score, subject, rater),
    class = "intraclass_unidentified"
  )
})

# Engine-choice claim (advanced.Rmd) --------------------------------------
# The advanced article states the lme4 and glmmTMB engines return the same
# coefficients to within rounding on `ratings`. Back the claim numerically (#1).

test_that("advanced.Rmd: lme4 and glmmTMB engines agree on `ratings`", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  g <- tidy(icc(ratings, score, subject, rater, engine = "glmmTMB", seed = 1))
  l <- tidy(icc(ratings, score, subject, rater, engine = "lme4", seed = 1))
  expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
})

# Multilevel claims (advanced.Rmd) ----------------------------------------
# The advanced article's multilevel example asserts that on the simulated
# `school` design the cluster-level ICC is the larger of the two levels. Rebuild
# the exact seeded dataset the vignette uses and check the claim holds (#1).

test_that("advanced.Rmd: cluster-level ICC exceeds subject-level on `school`", {
  skip_if_not_installed("glmmTMB")

  set.seed(2025)
  n_class <- 16
  n_pupil <- 5
  n_rater <- 4
  grid <- expand.grid(
    pupil = seq_len(n_pupil),
    classroom = seq_len(n_class),
    rater = seq_len(n_rater)
  )
  class_effect <- rnorm(n_class, sd = 1.3)[grid$classroom]
  pupil_effect <- rnorm(n_class * n_pupil, sd = 0.6)[
    (grid$classroom - 1) * n_pupil + grid$pupil
  ]
  rater_effect <- rnorm(n_rater, sd = 0.4)[grid$rater]
  school <- data.frame(
    classroom = factor(grid$classroom),
    pupil = factor(paste(grid$classroom, grid$pupil, sep = "_")),
    rater = factor(grid$rater),
    score = 10 +
      class_effect +
      pupil_effect +
      rater_effect +
      rnorm(nrow(grid), sd = 0.7)
  )

  e <- icc(
    school,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    seed = 1
  )$estimates
  cluster_a1 <- e$estimate[e$index == "ICC(A,1)" & e$level == "cluster"]
  subject_a1 <- e$estimate[e$index == "ICC(A,1)" & e$level == "subject"]
  expect_gt(cluster_a1, subject_a1)

  # Average >= single at each level (asserted generally in the article).
  for (lv in c("subject", "cluster")) {
    single <- e$estimate[e$index == "ICC(A,1)" & e$level == lv]
    average <- e$estimate[e$index == "ICC(A,k)" & e$level == lv]
    expect_gte(average, single)
  }
})
