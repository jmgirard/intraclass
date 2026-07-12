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

# --- D-study claims (d-studies-and-replicates.Rmd) -----------------------

test_that("the D-study projection anchors to ICC(A,k) at m = n_raters", {
  skip_if_not_installed("glmmTMB")

  # The D-studies article states Phi(m) at m = 4 (the raters in `ratings`) equals
  # the ICC(A,k) icc() reports directly. Point estimates are seed-independent.
  fit <- icc(ratings, score, subject, rater, seed = 1)
  proj <- d_study(fit, m = 1:8, seed = 1)

  at_k <- proj$estimate[proj$m == fit$n$raters]
  ick <- tidy(fit)$estimate[tidy(fit)$index == "ICC(A,k)"]
  expect_equal(at_k, ick, tolerance = 1e-8)

  # And the "diminishing returns" curve is monotone increasing.
  expect_true(all(diff(proj$estimate) > 0))
})

test_that("the occasion D-study rises to a ceiling below 1 and lifts fixed agreement", {
  skip_if_not_installed("glmmTMB")

  # The article claims (a) d_study(n_o = ...) climbs to a finite ceiling below 1
  # (occasion averaging cancels only pure error), and (b) fixed absolute agreement
  # PROJECTS on the occasion axis (unlike the rater axis). Back both numerically (#1).
  set.seed(20260711)
  grid <- expand.grid(subject = 1:24, rater = 1:4, occ = 1:3)
  subj <- rnorm(24, sd = 1.2)[grid$subject]
  rtr <- rnorm(4, sd = 0.8)[grid$rater]
  sr <- rnorm(24 * 4, sd = 0.6)[(grid$rater - 1) * 24 + grid$subject]
  reps <- data.frame(
    subject = factor(grid$subject),
    rater = factor(grid$rater),
    score = 10 + subj + rtr + sr + rnorm(nrow(grid), sd = 0.7)
  )
  fit <- icc(reps, score, subject, rater, occasions = "average", seed = 1)
  k <- fit$k_eff
  vc <- fit$components
  ceiling <- vc$subject / (vc$subject + (vc$rater + vc$subject_rater) / k)
  proj <- d_study(fit, n_o = 1:30, seed = 1)
  expect_true(all(diff(proj$estimate) > 0)) # rising
  expect_true(all(proj$estimate < ceiling)) # bounded by the ceiling
  expect_lt(ceiling, 1) # the ceiling is below 1

  # Fixed absolute agreement is refused on the rater axis but projects on n_o.
  fixed <- suppressWarnings(
    icc(
      reps,
      score,
      subject,
      rater,
      raters = "fixed",
      type = "agreement",
      occasions = "average",
      seed = 1
    )
  )
  expect_error(d_study(fixed, m = 1:4), class = "intraclass_unidentified")
  expect_s3_class(d_study(fixed, n_o = 1:4), "icc_dstudy")
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

# Engine-choice claim (engines.Rmd) ---------------------------------------
# The engines article states the lme4 and glmmTMB engines return the same
# coefficients to within rounding on `ratings`. Back the claim numerically (#1).

test_that("engines.Rmd: lme4 and glmmTMB engines agree on `ratings`", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")

  g <- tidy(icc(ratings, score, subject, rater, engine = "glmmTMB", seed = 1))
  l <- tidy(icc(ratings, score, subject, rater, engine = "lme4", seed = 1))
  expect_equal(l$estimate, g$estimate, tolerance = 1e-4)
})

test_that("engines.Rmd: lavaan matches glmmTMB on consistency, differs slightly on agreement", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # The SEM subsection claims (a) consistency is identical between engines (a ratio),
  # and (b) absolute agreement differs by a small-sample amount, with lavaan's
  # indicator-mean estimate a little lower than glmmTMB's on this 6-subject design
  # (0.284 vs 0.290). Back both claims numerically (#1).
  gc <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    engine = "glmmTMB",
    seed = 1
  ))
  lc <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    engine = "lavaan",
    seed = 1
  ))
  expect_equal(lc$estimate, gc$estimate, tolerance = 1e-3)

  ga <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "agreement",
    engine = "glmmTMB",
    seed = 1
  ))
  la <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "agreement",
    engine = "lavaan",
    seed = 1
  ))
  ga1 <- ga$estimate[ga$index == "ICC(A,1)"]
  la1 <- la$estimate[la$index == "ICC(A,1)"]
  expect_lt(la1, ga1) # lavaan indicator-mean agreement is slightly lower here
  expect_lt(abs(la1 - ga1), 0.02) # but close (asymptotically equivalent)
})

# Plotting claim (d-studies-and-replicates.Rmd) ---------------------------
# The "Visualizing a fit" section's variance-component plot claims the rater
# component is the largest on `ratings`, which is why absolute agreement -- the
# only coefficient that charges between-rater differences as error -- is so much
# lower than the averaged/consistency coefficients. Back the claim numerically (#1).

test_that("d-studies-and-replicates.Rmd: the rater component dominates on `ratings`", {
  skip_if_not_installed("glmmTMB")

  comp <- icc(ratings, score, subject, rater, seed = 1)$components
  expect_gt(comp$rater, comp$subject)
  expect_gt(comp$rater, comp$residual)
})

# Multilevel claims (multilevel-designs.Rmd) ------------------------------
# The multilevel-designs article's example asserts that on the simulated
# `school` design the cluster-level ICC is the larger of the two levels. Rebuild
# the exact seeded dataset the vignette uses and check the claim holds (#1).

test_that("multilevel-designs.Rmd: cluster-level ICC exceeds subject-level on `school`", {
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

  # The conflated-ICC subsection claims the biased ignore-the-clustering value
  # lands between the two correct levels and matches neither (M17 Slice 1).
  ec <- icc(
    school,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    level = "conflated",
    seed = 1
  )$estimates
  conflated_a1 <- ec$estimate[ec$index == "ICC(A,1)" & ec$level == "conflated"]
  expect_gt(conflated_a1, subject_a1)
  expect_lt(conflated_a1, cluster_a1)
})

# The article's incomplete-multilevel subsection drops a fifth of the `school`
# ratings and claims: the subject level still returns, ICC(*,k) uses an effective
# k below the panel size, the single-rater cluster ICC(c,1) is available, and the
# averaged cluster ICC(c,k) on incomplete data is refused. Back each claim (#1).

test_that("multilevel-designs.Rmd: ragged `school` supports subject + cluster ICC(c,1)", {
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
  set.seed(11)
  school_ragged <- school[-sample(nrow(school), round(0.2 * nrow(school))), ]

  sub <- icc(
    school_ragged,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    level = "subject",
    seed = 1
  )
  # Ragged design is flagged incomplete, and the effective k is strictly between 1
  # and the full panel size (harmonic mean of unequal per-pupil counts).
  expect_false(sub$design$balanced)
  expect_gt(sub$k_eff, 1)
  expect_lt(sub$k_eff, n_rater)
  # Average >= single at the subject level.
  se <- sub$estimates
  expect_gte(
    se$estimate[se$index == "ICC(A,k)"],
    se$estimate[se$index == "ICC(A,1)"]
  )

  # Single-rater cluster ICC(c,1) is available and in [0, 1].
  clu <- icc(
    school_ragged,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    level = "cluster",
    type = "consistency",
    unit = "single",
    seed = 1
  )
  c1 <- clu$estimates$estimate[clu$estimates$index == "ICC(C,1)"]
  expect_true(c1 >= 0 && c1 <= 1)

  # The averaged cluster ICC(c,k) on incomplete data is refused, not guessed.
  expect_error(
    icc(
      school_ragged,
      score,
      subject = pupil,
      rater = rater,
      cluster = classroom,
      level = "cluster",
      unit = "average",
      seed = 1
    ),
    class = "intraclass_unsupported"
  )
})

# The article's fixed-rater subsection claims that on the balanced `school` design
# the fixed-rater subject-level ICCs match the random-rater ones (consistency
# identical, absolute agreement coinciding on balanced data). Back the claim (#1).

test_that("multilevel-designs.Rmd: balanced fixed-rater `school` matches random at the subject level", {
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
  sub <- function(x, index) {
    x$estimates$estimate[x$estimates$index == index]
  }
  fx <- suppressWarnings(icc(
    school,
    score,
    pupil,
    rater,
    cluster = classroom,
    level = "subject",
    raters = "fixed",
    type = "agreement",
    unit = c("single", "average"),
    seed = 1
  ))
  rn <- icc(
    school,
    score,
    pupil,
    rater,
    cluster = classroom,
    level = "subject",
    raters = "random",
    type = "agreement",
    unit = c("single", "average"),
    seed = 1
  )
  expect_equal(sub(fx, "ICC(A,1)"), sub(rn, "ICC(A,1)"), tolerance = 1e-4)
  expect_equal(sub(fx, "ICC(A,k)"), sub(rn, "ICC(A,k)"), tolerance = 1e-4)

  # The article now also states fixed matches random AT THE CLUSTER LEVEL on balanced
  # data (M37, ADR-047) -- the same finite-population rater term equals the random σ²_r
  # and the cluster-by-rater interaction is unchanged. Back that claim too (#1).
  fxc <- suppressWarnings(icc(
    school,
    score,
    pupil,
    rater,
    cluster = classroom,
    level = "cluster",
    raters = "fixed",
    type = "agreement",
    unit = c("single", "average"),
    seed = 1
  ))
  rnc <- icc(
    school,
    score,
    pupil,
    rater,
    cluster = classroom,
    level = "cluster",
    raters = "random",
    type = "agreement",
    unit = c("single", "average"),
    seed = 1
  )
  expect_equal(sub(fxc, "ICC(A,1)"), sub(rnc, "ICC(A,1)"), tolerance = 1e-4)
  expect_equal(sub(fxc, "ICC(A,k)"), sub(rnc, "ICC(A,k)"), tolerance = 1e-4)
})

# The article's nested-design examples relabel `school`: giving each classroom its
# own raters (Design 2) or each pupil their own raters (Design 3). Check the prose
# claims -- the design is inferred, nested designs report the subject level only,
# and Design 3 is the agreement-only one-way (labels ICC(1)/ICC(k)) -- hold (#1).

test_that("multilevel-designs.Rmd: nested relabels of `school` infer Designs 2 and 3", {
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

  # Design 2: each classroom has its own raters -> subject level only.
  school_d2 <- school
  school_d2$rater <- factor(
    paste(school_d2$classroom, school_d2$rater, sep = "_")
  )
  x2 <- icc(
    school_d2,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    seed = 1
  )
  expect_identical(x2$design$ml_design, "nested_in_clusters")
  expect_setequal(unique(x2$estimates$level), "subject")

  # Design 3: each pupil has their own raters -> multilevel one-way, ICC(1)/ICC(k).
  school_d3 <- school
  school_d3$rater <- factor(paste(school_d3$pupil, school_d3$rater, sep = "_"))
  x3 <- icc(
    school_d3,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    seed = 1
  )
  expect_identical(x3$design$ml_design, "nested_in_subjects")
  expect_setequal(x3$estimates$index, c("ICC(1)", "ICC(k)"))
})
