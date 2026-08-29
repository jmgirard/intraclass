# Vignette claims (getting-started.Rmd) -----------------------------------
# The "Is this a good ICC?" section teaches that a point estimate should be read
# against its confidence interval, not a cutoff band, and illustrates it with the
# live `ratings` fit: ICC(A,k) lands in the "moderate" band yet its 95% interval
# spans from "poor" to "excellent". That is a numeric claim about the shipped
# example and the vignette's seed -- back it so the caveat is never illustrated by
# a stale interval (PRINCIPLES.md #1/#4). The interpretation bands (Koo & Li 2016;
# Cicchetti 1994) trace to `cairn/references/BIBLIOGRAPHY.md`.

test_that("getting-started.Rmd: the ICC(A,k) interval spans interpretation bands", {
  skip_if_not_installed("glmmTMB")

  # Uses the vignette's own seed: the interval is Monte-Carlo, so the band-spanning
  # illustration is seed-dependent (unlike the point-estimate claims below).
  ak <- tidy(icc(ratings, score, subject, rater, seed = 2024))[2, ]

  # Point estimate sits in Koo & Li's "moderate" band (0.50-0.75) ...
  expect_gte(ak$estimate, 0.50)
  expect_lte(ak$estimate, 0.75)
  # ... yet the 95% interval reaches "poor" (< 0.50) and "excellent" (> 0.90),
  # the concrete reason the article tells readers to judge the interval.
  expect_lt(ak$conf.low, 0.50)
  expect_gt(ak$conf.high, 0.90)
})

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
  i1 <- ow$estimate[ow$term == "ICC(1)"]
  expect_lte(i1, agr$estimate[agr$term == "ICC(A,1)"])
  expect_lte(
    agr$estimate[agr$term == "ICC(A,1)"],
    con$estimate[con$term == "ICC(C,1)"]
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
  fit <- icc(ratings, score, subject, rater, type = "agreement", seed = 1)
  proj <- d_study(fit, m = 1:8, seed = 1)

  at_k <- proj$estimate[proj$m == fit$n$raters]
  ick <- tidy(fit)$estimate[tidy(fit)$term == "ICC(A,k)"]
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
  fit <- icc(
    reps,
    score,
    subject,
    rater,
    type = "agreement",
    occasions = "average",
    seed = 1
  )
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
  ga1 <- ga$estimate[ga$term == "ICC(A,1)"]
  la1 <- la$estimate[la$term == "ICC(A,1)"]
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

# The "One projected value, without a projection object" section runs a numeric
# `unit` inline and states three things about it: the extra row is labeled
# `ICC(A,6)`; it is the same quantity `d_study()` projects, estimate AND interval;
# and asking for it under FIXED raters with `type = "agreement"` alone is refused
# rather than answered. Back all three on the shipped `ratings` data, naming the
# condition class the refusal signals (#1, #5).

test_that("d-studies-and-replicates.Rmd: a numeric `unit` adds the ICC(A,6) d_study row", {
  skip_if_not_installed("glmmTMB")

  inline <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    type = "agreement",
    unit = c("single", "average", 6),
    seed = 1
  ))

  # The article's own output: three rows, the third labeled ICC(A,6).
  expect_identical(inline$term, c("ICC(A,1)", "ICC(A,k)", "ICC(A,6)"))
  at_6 <- inline[inline$term == "ICC(A,6)", ]
  # The numeral the article prints for the ICC(A,6) row.
  expect_equal(round(at_6$estimate, 3), 0.710)

  # "the same quantity d_study() projects": same estimate and same interval, which
  # holds because both reducers run the fit's own seed.
  fit <- icc(ratings, score, subject, rater, type = "agreement", seed = 1)
  proj <- tidy(d_study(fit, m = 6, seed = 1))
  expect_equal(at_6$estimate, proj$estimate, tolerance = 1e-8)
  expect_equal(at_6$conf.low, proj$conf.low, tolerance = 1e-8)
  expect_equal(at_6$conf.high, proj$conf.high, tolerance = 1e-8)
})

test_that("d-studies-and-replicates.Rmd: fixed-rater agreement refuses a numeric `unit`", {
  skip_if_not_installed("glmmTMB")

  # The article's `error = TRUE` chunk. The refusal is classed, and it is raised
  # only when absolute agreement is the ONLY requested type.
  expect_error(
    icc(
      ratings,
      score,
      subject,
      rater,
      type = "agreement",
      raters = "fixed",
      unit = c("single", "average", 6),
      seed = 1
    ),
    class = "intraclass_unidentified"
  )

  # Both remedies the message names do return the projected row itself, not
  # merely a fit: `raters = "random"` keeps the agreement projection, and
  # `type = "consistency"` under fixed raters gives the consistency one.
  random_agr <- suppressWarnings(icc(
    ratings,
    score,
    subject,
    rater,
    type = "agreement",
    raters = "random",
    unit = c("single", "average", 6),
    seed = 1
  ))
  expect_true("ICC(A,6)" %in% tidy(random_agr)$term)
  fixed_con <- suppressWarnings(icc(
    ratings,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    unit = c("single", "average", 6),
    seed = 1
  ))
  expect_true("ICC(C,6)" %in% tidy(fixed_con)$term)

  # ... and the default (both types) drops the agreement projection with a
  # message rather than aborting, keeping the consistency one.
  expect_message(
    both <- suppressWarnings(icc(
      ratings,
      score,
      subject,
      rater,
      raters = "fixed",
      unit = c("single", "average", 6),
      seed = 1
    )),
    "Dropping the .*agreement.* D-study projection"
  )
  expect_true("ICC(C,6)" %in% tidy(both)$term)
  expect_false("ICC(A,6)" %in% tidy(both)$term)
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

test_that("multilevel-designs.Rmd: ragged `school` supports subject + cluster ICC(c,1) and ICC(c,k)", {
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

  # The averaged cluster ICC(c,k) on incomplete data now ships (M46): both types,
  # both units, in [0, 1], with the inverse-Simpson k_c^eff reported and below the
  # panel size.
  ck <- icc(
    school_ragged,
    score,
    subject = pupil,
    rater = rater,
    cluster = classroom,
    level = "cluster",
    type = c("agreement", "consistency"),
    unit = c("single", "average"),
    seed = 1
  )
  ce <- ck$estimates
  expect_setequal(
    ce$index,
    c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")
  )
  expect_true(all(ce$estimate >= 0 & ce$estimate <= 1))
  expect_true(!is.na(ck$k_c_eff) && ck$k_c_eff > 1 && ck$k_c_eff <= n_rater)
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

# The "Declaring the design when the labels are ambiguous" section runs the SAME
# `school` table three ways and claims the answers differ: inference reads the
# reused rater labels as crossed (Design 1, both levels), `design =
# "nested_in_clusters"` reads them as Design 2 (subject level only, a
# rater-within-cluster component), and `design = "nested_in_subjects"` reads them
# as Design 3 (agreement-only ICC(1)/ICC(k), rater confounded into the residual).
# It also claims a declaration matching what the labels already say changes
# nothing. Back all four (#1).

test_that("multilevel-designs.Rmd: a declared `design` overrides the labels' own reading", {
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
  args <- list(
    school,
    quote(score),
    subject = quote(pupil),
    rater = quote(rater),
    cluster = quote(classroom),
    type = "agreement",
    seed = 1
  )
  fit_as <- function(design = NULL) {
    do.call(icc, c(args, list(design = design)))
  }

  # Inference: the reused labels read as one panel rating everywhere (Design 1),
  # so both levels come back -- and icc() announces that reading rather than
  # taking it silently, which is what the article tells the reader to rely on.
  rlang::reset_message_verbosity("intraclass_crossed_ml_labels")
  expect_message(
    inferred <- fit_as(),
    "Treating raters with the same label in different clusters"
  )
  expect_identical(inferred$design$ml_design, "crossed")
  expect_setequal(unique(inferred$estimates$level), c("subject", "cluster"))

  # Declared Design 2: subject level only, and the rater term becomes a
  # rater-within-cluster component.
  d2 <- fit_as("nested_in_clusters")
  expect_identical(d2$design$ml_design, "nested_in_clusters")
  expect_setequal(unique(d2$estimates$level), "subject")
  # The article's claim is about the PRINTED label: one `rater:cluster` term in
  # place of the crossed fit's separate `rater` and `cluster:rater` terms.
  comp_line <- function(x) grep("Variance components", format(x), value = TRUE)
  expect_match(comp_line(d2), "rater:cluster")
  expect_no_match(comp_line(d2), "cluster:rater")
  expect_match(comp_line(inferred), "rater 0")
  expect_match(comp_line(inferred), "cluster:rater")
  # The numeral the article prints for this call.
  expect_equal(round(tidy(d2)$estimate[tidy(d2)$term == "ICC(A,1)"], 3), 0.429)

  # Declared Design 3: no rater term at all, agreement-only ICC(1)/ICC(k).
  d3 <- fit_as("nested_in_subjects")
  expect_identical(d3$design$ml_design, "nested_in_subjects")
  expect_setequal(d3$estimates$index, c("ICC(1)", "ICC(k)"))
  # ... and under Design 3 there is no rater term at all.
  expect_false("rater" %in% names(d3$components))
  expect_match(comp_line(d3), "residual .* \\(rater confounded\\)")
  # The numeral the article prints for this call.
  expect_equal(round(tidy(d3)$estimate[tidy(d3)$term == "ICC(1)"], 3), 0.412)

  # The three readings really are three different answers.
  a1 <- function(x) tidy(x)$estimate[1]
  expect_false(isTRUE(all.equal(a1(d2), a1(d3))))
  expect_false(isTRUE(all.equal(
    a1(d2),
    tidy(inferred)$estimate[tidy(inferred)$level == "subject"][1]
  )))

  # "Where the labels are already unique per rater ... passing the matching
  # `design` explicitly returns the very same fit." Both relabelled tables.
  school_d3 <- school
  school_d3$rater <- factor(paste(school_d3$pupil, school_d3$rater, sep = "_"))
  school_d2_lab <- school
  school_d2_lab$rater <- factor(
    paste(school_d2_lab$classroom, school_d2_lab$rater, sep = "_")
  )
  no_op <- function(data, design) {
    a <- args
    a[[1]] <- data
    expect_equal(
      tidy(do.call(icc, c(a, list(design = design)))),
      tidy(do.call(icc, a))
    )
  }
  no_op(school_d3, "nested_in_subjects")
  no_op(school_d2_lab, "nested_in_clusters")
})

# Vignette claims (comparison-with-other-packages.Rmd) --------------------
# The comparison article makes two load-bearing claims, both illustrated with
# numbers computed live from the shipped datasets, so both must hold on those
# datasets or the article teaches from stale figures (PRINCIPLES.md #1/#4):
#   (1) VALIDATION -- on the balanced `ratings` design `intraclass` reproduces
#       `psych::ICC` and `irr::icc` across the whole McGraw-Wong family to
#       numerical precision (a REML-vs-ANOVA-mean-squares gap, not error), and a
#       different-lineage model-based tool (`irrICC`, Gwet) agrees too; and
#   (2) DIFFERENTIATION -- on `ratings_incomplete` the classical tools must
#       listwise-delete down to a handful of subjects, while `intraclass` fits
#       every observed rating. These pin the relationships the article shows,
#       not exact coefficients (which the article computes live).

test_that("comparison.Rmd: intraclass reproduces psych and irr on balanced `ratings`", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("psych")
  skip_if_not_installed("irr")

  w <- reshape(
    ratings,
    idvar = "subject",
    timevar = "rater",
    direction = "wide"
  )
  w <- w[order(as.integer(as.character(w$subject))), ]
  wm <- as.matrix(w[, -1])

  ps <- psych::ICC(wm)$results
  psv <- stats::setNames(ps$ICC, ps$type)
  ic <- function(model, type, unit) {
    icc(
      ratings,
      subject = subject,
      rater = rater,
      score = score,
      model = model,
      type = type,
      unit = unit
    )$estimates$estimate[1]
  }

  rows <- list(
    c("oneway", "agreement", "single", "ICC1"),
    c("oneway", "agreement", "average", "ICC1k"),
    c("twoway", "agreement", "single", "ICC2"),
    c("twoway", "agreement", "average", "ICC2k"),
    c("twoway", "consistency", "single", "ICC3"),
    c("twoway", "consistency", "average", "ICC3k")
  )

  for (r in rows) {
    est <- ic(r[1], r[2], r[3])
    # Matches psych (the in-suite oracle) and irr to a REML-vs-ANOVA tolerance.
    expect_equal(est, unname(psv[r[4]]), tolerance = 1e-4)
    expect_equal(
      est,
      irr::icc(wm, model = r[1], type = r[2], unit = r[3])$value,
      tolerance = 1e-4
    )
  }
})

test_that("comparison.Rmd: irrICC (Gwet) agrees with intraclass ICC(A,1)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("irrICC")

  w <- reshape(
    ratings,
    idvar = "subject",
    timevar = "rater",
    direction = "wide"
  )
  w <- w[order(as.integer(as.character(w$subject))), ]
  gwet_frame <- data.frame(
    Target = as.integer(as.character(w$subject)),
    J1 = w$score.1,
    J2 = w$score.2,
    J3 = w$score.3,
    J4 = w$score.4
  )
  gwet_agree <- irrICC::icc2.inter.fn(gwet_frame)$icc2r
  a1 <- icc(
    ratings,
    subject = subject,
    rater = rater,
    score = score,
    model = "twoway",
    type = "agreement",
    unit = "single"
  )$estimates$estimate[1]

  expect_equal(gwet_agree, a1, tolerance = 1e-4)
})

test_that("comparison.Rmd: incomplete data collapses classical tools but not intraclass", {
  skip_if_not_installed("glmmTMB")

  w <- reshape(
    ratings_incomplete,
    idvar = "subject",
    timevar = "rater",
    direction = "wide"
  )
  w <- w[order(as.integer(as.character(w$subject))), ]
  wm <- as.matrix(w[, -1])

  # The article's differentiator: listwise deletion keeps far fewer subjects
  # than the study has, while intraclass uses all of them.
  surviving <- sum(stats::complete.cases(wm))
  expect_equal(surviving, 2L)

  fit_inc <- icc(
    ratings_incomplete,
    subject = subject,
    rater = rater,
    score = score,
    model = "twoway",
    type = "agreement",
    unit = "average"
  )
  expect_equal(fit_inc$n$subjects, 6L) # every subject retained
  expect_equal(fit_inc$n$obs, nrow(ratings_incomplete)) # every observed rating used
  # k_eff sits between one rating and the full complement of four raters.
  expect_gt(fit_inc$k_eff, 1)
  expect_lt(fit_inc$k_eff, 4)
})

# Vignette claims (interval-methods.Rmd) ----------------------------------
# The interval-methods article is the surface carrying every `ci_method` claim.
# Its study figures (the skew under-coverage cells, the searle/burch width
# ratios) are pinned against committed fixtures by `test-doc-skew-caveat.R`;
# what that file cannot see is whether the *behavioural* claims the article
# makes about the shipped API are true. Those are backed here, on the article's
# own data and at the article's own arguments (PRINCIPLES.md #1/#4).

test_that("interval-methods.Rmd: every coefficient carries an interval, never a bare number", {
  skip_if_not_installed("glmmTMB")

  # The opening claim (article lines 19-20): `icc()` reports an interval for
  # every coefficient it returns, whatever the method. Sweep the designs and
  # methods the article names as reachable.
  cases <- list(
    list(model = "twoway", type = "agreement", ci_method = "montecarlo"),
    list(model = "twoway", type = "consistency", ci_method = "montecarlo"),
    list(model = "oneway", type = "agreement", ci_method = "montecarlo"),
    list(model = "oneway", type = "agreement", ci_method = "searle"),
    list(model = "oneway", type = "agreement", ci_method = "burch")
  )
  for (cs in cases) {
    td <- tidy(icc(
      ratings,
      score,
      subject,
      rater,
      model = cs$model,
      type = cs$type,
      ci_method = cs$ci_method,
      unit = c("single", "average"),
      seed = 1
    ))
    expect_gt(nrow(td), 0L) # anti-vacuity: a zero-row tidy passes the sweep free
    expect_false(any(is.na(td$conf.low)), info = cs$ci_method)
    expect_false(any(is.na(td$conf.high)), info = cs$ci_method)
  }
})

test_that("interval-methods.Rmd: `ci_method` selects the interval, never the estimator", {
  skip_if_not_installed("glmmTMB")

  # Article line 249, read off the `ci-oneway-optin` chunk: all four columns
  # share one point estimate. Run the chunk's own calls.
  mc <- tidy(icc(ratings, score, subject, rater, model = "oneway", seed = 1))
  se <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "searle"
  ))
  bu <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "burch"
  ))
  np <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "npbootstrap",
    boot_samples = 199,
    seed = 1
  ))
  for (other in list(se, bu, np)) {
    expect_equal(other$estimate, mc$estimate, tolerance = 1e-8)
  }

  # And the article's reading of that chunk (line 249-252): the three opt-in
  # lower limits dip below zero on these data while the Monte-Carlo one does not.
  for (other in list(se, bu, np)) {
    expect_lt(min(other$conf.low), 0)
  }
  expect_gte(min(mc$conf.low), 0)
})

test_that("interval-methods.Rmd: exactly four opt-in methods, each fenced and classed", {
  skip_if_not_installed("glmmTMB")

  # Article line 113: "Four opt-in methods serve exactly that terrain". The
  # enumerator is the validator's own accepted set, not a hand list: an
  # unrecognized value aborts with the allowed values spelled out, so ask it.
  # This deliberately treats the abort's USER-FACING enumeration as the
  # contract, because that enumeration is exactly what a reader of the article
  # is told to expect (M130 return, F11). A reworded message that still names
  # the same four values passes; one that drops or adds a value fails, which is
  # the property under test.
  msg <- tryCatch(
    icc(ratings, score, subject, rater, ci_method = "not-a-method", seed = 1),
    error = conditionMessage
  )
  all_methods <- regmatches(msg, gregexpr('"[^"]+"', msg))[[1]]
  all_methods <- gsub('"', "", all_methods, fixed = TRUE)
  expect_gt(length(all_methods), 0L) # anti-vacuity: an empty set passes free
  optin <- setdiff(all_methods, c("montecarlo", "bootstrap", "posterior"))
  expect_setequal(optin, c("npbootstrap", "searle", "burch", "mpl"))
  expect_identical(length(optin), 4L)

  # Article line 114: each aborts with a classed error off its fence. The
  # two-way consistency design is off the fence of all four (the three one-way
  # methods refuse the two-way; `"mpl"` refuses consistency).
  # `"mpl"` warns before it aborts (it drops the undefined type first), so the
  # warning is muffled here; the assertion is about which failure is raised.
  for (m in optin) {
    expect_error(
      suppressWarnings(icc(
        ratings,
        score,
        subject,
        rater,
        model = "twoway",
        type = "consistency",
        ci_method = m,
        seed = 1
      )),
      class = "intraclass_unsupported",
      info = m
    )
  }
})

# A balanced, complete two-level Design-1 dataset (the multilevel path both
# mixed-model engines and the lavaan engine take). Mirrors the generator in
# `test-icc-lavaan-multilevel.R`; small, because only bootstrap AVAILABILITY is
# under test here, never the interval's smoothness.
vc_sim_multilevel <- function(nc, ns, k, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(0.4))
  rt <- stats::rnorm(k, 0, sqrt(0.16))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  d$sc <- stats::rnorm(nc * ns, 0, 1)[(d$cluster - 1) * ns + d$subj]
  d$cr <- stats::rnorm(nc * k, 0, sqrt(0.16))[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(0.5))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

test_that("interval-methods.Rmd: the bootstrap spans every design the mixed-model engines fit", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Article lines 67-68: "available for every design the `\"glmmTMB\"` and
  # `\"lme4\"` engines fit". A three-design probe on one dataset does not
  # establish a promise quantified over designs, and its silence is what let the
  # lavaan fence go unnoticed (M130 return, F1/F13). So the probe is a MATRIX
  # over the design axes `icc()` exposes -- model, type, rater mode, balance,
  # completeness, replicate averaging, and the two-level path -- run against
  # each mixed-model engine. A new axis that the bootstrap does not serve fails
  # here rather than in a reader's console.
  set.seed(7)
  g <- expand.grid(subject = 1:15, rater = 1:4, occ = 1:2)
  reps <- data.frame(
    subject = factor(g$subject),
    rater = factor(g$rater),
    score = 10 +
      stats::rnorm(15, sd = 1.2)[g$subject] +
      stats::rnorm(4, sd = 0.8)[g$rater] +
      stats::rnorm(nrow(g), sd = 0.7)
  )
  ml <- vc_sim_multilevel(20, 8, 4, seed = 20260716)

  designs <- list(
    list(nm = "oneway balanced", d = ratings, a = list(model = "oneway")),
    list(
      nm = "twoway agreement",
      d = ratings,
      a = list(model = "twoway", type = "agreement")
    ),
    list(
      nm = "twoway consistency",
      d = ratings,
      a = list(model = "twoway", type = "consistency")
    ),
    list(
      nm = "twoway fixed raters",
      d = ratings,
      a = list(model = "twoway", type = "agreement", raters = "fixed")
    ),
    list(
      nm = "oneway unbalanced",
      d = ratings_incomplete,
      a = list(model = "oneway")
    ),
    list(
      nm = "twoway incomplete",
      d = ratings_incomplete,
      a = list(model = "twoway", type = "agreement")
    ),
    list(nm = "replicate averaging", d = reps, a = list(occasions = "average")),
    list(nm = "two-level", d = ml, a = list(cluster = quote(cluster))),
    # The `level` and `design` axes: the comment above claims the matrix
    # sweeps the design axes `icc()` exposes, and these two were missing from
    # it (M130 return 2, O5).
    list(
      nm = "two-level cluster",
      d = ml,
      a = list(cluster = quote(cluster), level = "cluster")
    ),
    list(
      nm = "two-level declared crossed",
      d = ml,
      a = list(cluster = quote(cluster), design = "crossed")
    ),
    list(
      nm = "two-level declared nested in clusters",
      d = ml,
      a = list(cluster = quote(cluster), design = "nested_in_clusters")
    )
  )
  engines <- "glmmTMB"
  if (
    requireNamespace("lme4", quietly = TRUE) &&
      requireNamespace("merDeriv", quietly = TRUE)
  ) {
    engines <- c(engines, "lme4")
  }
  for (eng in engines) {
    for (d in designs) {
      args <- c(
        list(d$d, quote(score), quote(subject), quote(rater)),
        d$a,
        list(
          engine = eng,
          ci_method = "bootstrap",
          boot_samples = 19,
          seed = 1
        )
      )
      td <- suppressWarnings(tidy(do.call(icc, args)))
      lab <- paste(eng, d$nm)
      expect_gt(nrow(td), 0L)
      expect_true(all(td$method == "bootstrap"), info = lab)
      expect_false(any(is.na(td$conf.low)), info = lab)
    }
  }
})

test_that("interval-methods.Rmd: the lavaan bootstrap's fences are the ones the article names", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")
  skip_on_cran()

  # Article lines 68-72, as reworded on the M130 return (F1). The engine has two
  # bootstrap routes with DIFFERENT fences, and the article now states both:
  # single-level lavaan bootstraps complete data (either rater mode), while the
  # two-level route additionally needs balanced clusters and random raters --
  # `R/engine-lavaan.R:573-575` nulls `simulate_refit` on
  # `identical(raters, "fixed") || has_missing || unbalanced`, against `:770`
  # nulling it on `has_missing` alone. Each cell below is asserted in BOTH
  # directions: an available cell returns a real bootstrap (not the Monte-Carlo
  # interval under another name), a fenced cell raises
  # `intraclass_unsupported`, the classed refusal `?icc` documents.
  ml <- vc_sim_multilevel(20, 8, 4, seed = 20260716)
  lv <- function(d, ...) {
    suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      ...,
      engine = "lavaan",
      ci_method = "bootstrap",
      boot_samples = 19,
      seed = 1
    )))
  }

  # Available: single-level complete, at either rater mode.
  for (rm in c("random", "fixed")) {
    td <- lv(ratings, raters = rm)
    expect_gt(nrow(td), 0L) # anti-vacuity: a zero-row tidy passes both below free
    expect_true(all(td$method == "bootstrap"), info = rm)
    expect_false(any(is.na(td$conf.low)), info = rm)
  }
  # It is a real bootstrap: its endpoints differ from the Monte-Carlo ones.
  mc <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    engine = "lavaan",
    ci_method = "montecarlo",
    seed = 1
  ))
  expect_false(isTRUE(all.equal(lv(ratings)$conf.low, mc$conf.low)))

  # Available: two-level, balanced clusters, random raters.
  td_ml <- lv(ml, cluster = cluster)
  expect_gt(nrow(td_ml), 0L) # anti-vacuity, as above
  expect_true(all(td_ml$method == "bootstrap"))
  expect_false(any(is.na(td_ml$conf.low)))

  # Fenced, each way the article names, each classed. The three refusals carry
  # a BYTE-IDENTICAL message, so pinning the message cannot say which fence
  # fired; what identifies each one is that its cell differs from a cell
  # asserted to succeed above in exactly the one attribute the fence names
  # (the failure-identity rule; M130 return 2, O2).
  #
  # Completeness: `ratings_incomplete` against the complete `ratings` that
  # bootstraps at both rater modes above.
  expect_true(
    anyNA(ratings_incomplete$score) ||
      nrow(ratings_incomplete) <
        nlevels(factor(ratings_incomplete$subject)) *
          nlevels(factor(ratings_incomplete$rater))
  )
  expect_error(lv(ratings_incomplete), class = "intraclass_unsupported")
  # Rater mode: the same balanced `ml` that bootstraps at random raters above.
  expect_error(
    lv(ml, cluster = cluster, raters = "fixed"),
    class = "intraclass_unsupported"
  )
  # Balance: drop a whole SUBJECT, not three ratings. The earlier cell
  # `ml[-(1:3), ]` left cells-per-subject at 3-4 and so tripped the
  # completeness fence, never the balance one. Dropping subject "1_1" leaves
  # every remaining subject with all four raters -- the frame is COMPLETE and
  # only the cluster sizes differ (7 against 8), which is the fence the article
  # names, and the only attribute separating this cell from the passing
  # balanced one above.
  unb <- ml[ml$subject != "1_1", ]
  expect_setequal(unique(table(droplevels(unb$subject))), 4L)
  expect_setequal(
    sort(unique(tapply(
      unb$subject,
      unb$cluster,
      function(x) length(unique(x))
    ))),
    c(7L, 8L)
  )
  expect_error(
    lv(unb, cluster = cluster),
    class = "intraclass_unsupported"
  )
})

test_that("interval-methods.Rmd: `\"npbootstrap\"` is the only opt-in method that serves unbalanced one-way data", {
  skip_if_not_installed("glmmTMB")

  # Article line 122. `ratings_incomplete` is the shipped unbalanced dataset.
  np <- tidy(icc(
    ratings_incomplete,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "npbootstrap",
    boot_samples = 199,
    seed = 1
  ))
  expect_gt(nrow(np), 0L)
  expect_false(any(is.na(np$conf.low)))

  for (m in c("searle", "burch", "mpl")) {
    expect_error(
      icc(
        ratings_incomplete,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = m,
        seed = 1
      ),
      class = "intraclass_unsupported",
      info = m
    )
  }
})

test_that("interval-methods.Rmd: `\"npbootstrap\"` alone takes a seed, and any conf_level in (0, 1)", {
  skip_if_not_installed("glmmTMB")

  # Article lines 124-125. The three deterministic opt-ins are unmoved by the
  # seed; `"npbootstrap"` resamples, so it moves.
  one <- function(m, ...) {
    tidy(icc(
      ratings,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = m,
      ...
    ))$conf.low[1]
  }
  for (m in c("searle", "burch")) {
    expect_identical(one(m, seed = 1), one(m, seed = 99), info = m)
  }
  expect_false(identical(
    one("npbootstrap", boot_samples = 199, seed = 1),
    one("npbootstrap", boot_samples = 199, seed = 99)
  ))

  # "Any `conf_level` in (0, 1) is accepted", and the interval widens with it.
  # Article line 130 makes the same promise for `"searle"` and `"burch"`, so
  # all three closed-form-or-resampling opt-ins are swept, not just the one
  # (M130 return, F15).
  widths <- function(m, ...) {
    vapply(
      c(0.5, 0.8, 0.95, 0.995),
      function(cl) {
        args <- list(
          ratings,
          quote(score),
          quote(subject),
          quote(rater),
          model = "oneway",
          ci_method = m,
          conf_level = cl,
          unit = "single",
          ...
        )
        td <- tidy(do.call(icc, args))
        td$conf.high[1] - td$conf.low[1]
      },
      numeric(1)
    )
  }
  expect_true(all(
    diff(widths("npbootstrap", boot_samples = 199, seed = 1)) > 0
  ))
  for (m in c("searle", "burch")) {
    expect_true(all(diff(widths(m)) > 0), info = m)
  }
})

test_that("interval-methods.Rmd: the `ci-bootstrap` chunk's own comparison holds", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Article lines 44-65, run at the chunk's own arguments (999 resamples,
  # `seed = 1`) because the prose reads the table those arguments render.
  mc <- tidy(icc(ratings, score, subject, rater, seed = 1))
  bs <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 999,
    seed = 1
  ))

  # Same fit, so the point estimates are identical.
  expect_equal(bs$estimate, mc$estimate, tolerance = 1e-8)
  # The bootstrap's lower bounds run markedly lower on this six-subject design.
  expect_true(all(bs$conf.low < mc$conf.low))
  # Its upper bounds are close but not identical, and not uniformly higher --
  # the article says so because rounding them to the chunk's own two decimals
  # leaves ICC(A,k) as the one index whose UPPER bound coincides.
  expect_true(all(abs(bs$conf.high - mc$conf.high) < 0.05))
  # "They do not all fall on the same side" is a TWO-sided claim: neither
  # `all(>=)` nor `all(<=)` may hold. Asserting only the first left half the
  # sentence unbacked (M130 return 2, O4).
  expect_false(all(bs$conf.high >= mc$conf.high))
  expect_false(all(bs$conf.high <= mc$conf.high))
  rounded_equal <- round(bs$conf.high, 2) == round(mc$conf.high, 2)
  expect_identical(mc$term[rounded_equal], "ICC(A,k)")
  # And it is the upper bound alone, never the pair: at that same rendering
  # ICC(A,k)'s lower bounds do not agree. This is the claim the article got
  # wrong once (M130 return, F3) -- an assertion on the upper bounds alone
  # would pass with "the pair rounds alike" back in the prose.
  ak <- mc$term == "ICC(A,k)"
  expect_false(round(bs$conf.low[ak], 2) == round(mc$conf.low[ak], 2))
})

test_that("interval-methods.Rmd: the default under-covers silently -- no abort, no warning, no widening", {
  skip_if_not_installed("glmmTMB")

  # Article lines 76-80. The study's coverage figures are pinned against the
  # committed fixture by `test-doc-skew-caveat.R`; what is backed here is the
  # behavioural half the fixture cannot show -- that a skewed-subject-effect fit
  # returns quietly, so the shortfall is invisible in the interval itself.
  set.seed(130)
  n_s <- 50
  n_r <- 5
  subj <- rchisq(n_s, df = 1) # the study's worst-cell subject-effect family
  skewed <- data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = rep(subj, times = n_r) + rnorm(n_s * n_r)
  )
  expect_no_warning(
    fit <- icc(skewed, score, subject, rater, model = "oneway", seed = 1)
  )
  td <- tidy(fit)
  expect_false(any(is.na(td$conf.low)))
  # Not widened: the reported interval is the ordinary Monte-Carlo one, no
  # skew-driven inflation, so nothing in the output flags the shortfall. A bare
  # upper bound on the width does not discriminate an inflation (M130 return,
  # F6) -- the comparison is against a matched normal fit at the SAME geometry
  # and the same subject-effect variance (chi-square(1) has variance 2), where
  # any skew-triggered widening would show as the skewed interval running
  # wider. Measured: 0.180 skewed against 0.208 normal, so it runs narrower.
  expect_true(all(td$method == "montecarlo"))
  set.seed(131)
  matched <- data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = rep(rnorm(n_s, sd = sqrt(2)), times = n_r) + rnorm(n_s * n_r)
  )
  td_n <- tidy(icc(matched, score, subject, rater, model = "oneway", seed = 1))
  # "Matched" is load-bearing: comparing against a normal fit at some OTHER
  # subject-effect variance would compare two different designs, and the width
  # verdict is not monotone in that variance, so the mismatch would not show
  # up in the comparison itself. Assert the match (M130 return 2, T13: the
  # planted `sqrt(2)` -> `sqrt(0.2)` change survived the width comparison).
  # `tolerance` is RELATIVE here, testthat 3e's sense -- not an absolute 0.1.
  # Measured on this seed pair: 0.0844 relative difference at the matched
  # `sqrt(2)`, against 0.704 under the `sqrt(0.2)` plant, so the plant sits
  # an order of magnitude outside the bar (M130 review pass 3, P4).
  expect_equal(td_n$estimate[1], td$estimate[1], tolerance = 0.1)
  expect_lte(
    td$conf.high[1] - td$conf.low[1],
    td_n$conf.high[1] - td_n$conf.low[1]
  )
})

test_that("interval-methods.Rmd: `\"searle\"` and `\"burch\"` project through the same Spearman-Brown image", {
  skip_if_not_installed("glmmTMB")

  # Article line 131: both closed forms project ICC(k) -- AND a numeric `unit`
  # -- through the same map `"npbootstrap"` uses. Check the map itself on the
  # endpoints, which is what "the same image" means. The numeric-`unit` clause
  # went untested until the M130 return (F14), so `m = 7` -- a projection past
  # the four raters `ratings` carries -- is swept alongside `"average"`.
  sb <- function(p, k) k * p / (1 + (k - 1) * p)
  m_proj <- 7
  for (m in c("searle", "burch", "npbootstrap")) {
    args <- list(
      ratings,
      quote(score),
      quote(subject),
      quote(rater),
      model = "oneway",
      ci_method = m,
      unit = c("single", "average", m_proj)
    )
    if (m == "npbootstrap") {
      args <- c(args, list(boot_samples = 199, seed = 1))
    }
    td <- tidy(do.call(icc, args))
    single <- td[td$term == "ICC(1)", ]
    k <- 4 # `ratings` has four raters
    for (target in list(list("ICC(k)", k), list("ICC(7)", m_proj))) {
      img <- td[td$term == target[[1]], ]
      lab <- paste(m, target[[1]])
      expect_identical(nrow(img), 1L, info = lab)
      expect_equal(
        img$estimate,
        sb(single$estimate, target[[2]]),
        tolerance = 1e-8,
        info = lab
      )
      expect_equal(
        img$conf.low,
        sb(single$conf.low, target[[2]]),
        tolerance = 1e-8,
        info = lab
      )
      expect_equal(
        img$conf.high,
        sb(single$conf.high, target[[2]]),
        tolerance = 1e-8,
        info = lab
      )
    }
  }
})

test_that("interval-methods.Rmd: at zero between-subject variance `\"burch\"` aborts and `\"searle\"` does not", {
  skip_if_not_installed("glmmTMB")

  # Article lines 222-225, the stated asymmetry between the siblings (D-022).
  flat <- data.frame(
    subject = factor(rep(1:8, each = 4)),
    rater = factor(rep(1:4, times = 8)),
    score = rep(c(1, 2, 3, 4), times = 8) # identical profile for every subject
  )
  # The abort is classed `intraclass_singular_fit` -- but so are
  # `"montecarlo"`'s and `"npbootstrap"`'s on this same data, for entirely
  # different reasons (non-finite draws; a `-Inf` log F), so the class alone
  # does not say WHICH failure this is (M130 return, F8, the failure-identity
  # rule). The message is pinned too: burch's abort names the kurtosis term
  # dividing by `sqrt(MSA)`, which is the mechanism the article states.
  expect_error(
    icc(flat, score, subject, rater, model = "oneway", ci_method = "burch"),
    regexp = "divides by sqrt\\(MSA\\)",
    class = "intraclass_singular_fit"
  )
  # The discriminating control: `"searle"` does not merely avoid the abort, it
  # returns an interval. The call is the DEFAULT one, over both units, because
  # that is the call the article's reader makes and the two units answer
  # differently -- pinning `unit = "single"` here is what let the article claim
  # an attained minimum for a call that also prints `-Inf` (M130 return 2, O3).
  se <- tidy(icc(
    flat,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "searle"
  ))
  single <- se[se$term == "ICC(1)", ]
  avg <- se[se$term == "ICC(k)", ]
  expect_identical(nrow(single), 1L)
  expect_identical(nrow(avg), 1L)
  # Single-rater: the finite degenerate endpoints the exact-F form gives at
  # MSA = 0 -- both limits at -1/(k - 1) = -1/3 for these four raters.
  expect_false(is.na(single$conf.low))
  expect_false(is.na(single$conf.high))
  expect_equal(single$conf.low, -1 / 3, tolerance = 1e-8)
  expect_equal(single$conf.high, -1 / 3, tolerance = 1e-8)
  # Averaged: the Spearman-Brown image of -1/(k - 1) is the pole, so both
  # limits are -Inf. Not `NA`, not an abort -- the article says so.
  expect_identical(avg$conf.low, -Inf)
  expect_identical(avg$conf.high, -Inf)
})

# The article's own `ci-mpl` chunk data, rebuilt at its seed (`ratings` is too
# small for the MPL calibration grid). Shared by every test that needs it --
# one construction, so a change to the article's simulation cannot leave a copy
# stale in one test while another still passes. Callers that need the rater
# count read it off the frame rather than restating the 4.
vc_mpl_sim <- function() {
  set.seed(88)
  n_s <- 20
  n_r <- 4
  subj_eff <- rnorm(n_s, sd = sqrt(0.6))
  rater_eff <- rnorm(n_r, sd = sqrt(0.1))
  noise <- matrix(rnorm(n_s * n_r, sd = sqrt(0.2)), n_s, n_r)
  data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(
      outer(subj_eff, rep(1, n_r)) +
        outer(rep(1, n_s), rater_eff) +
        noise
    )
  )
}

test_that("interval-methods.Rmd: the `\"mpl\"` fences are the ones the article names", {
  skip_if_not_installed("glmmTMB")

  # Article lines 257-275, run on the article's own simulated design (the
  # `ci-mpl` chunk's data, rebuilt at its seed -- `ratings` is too small for
  # the calibration grid). One shared builder, so this test and the
  # per-`ci_method` fence pins below cannot drift apart (M133 review, B2).
  sim <- vc_mpl_sim()
  n_r <- nlevels(sim$rater)

  # On the fence: balanced, complete, two-way random absolute agreement.
  ml <- tidy(icc(
    sim,
    score,
    subject,
    rater,
    type = "agreement",
    ci_method = "mpl",
    unit = c("single", "average")
  ))
  expect_false(any(is.na(ml$conf.low)))

  # ICC(A,k) -- and ANY numeric-`unit` projection -- is the pole-safe
  # Spearman-Brown image of ICC(A,1) (line 270). The numeric-`unit` half went
  # untested until the M130 return (F14), so `m = 7` is swept with `"average"`.
  sb <- function(p, k) k * p / (1 + (k - 1) * p)
  a1 <- ml[ml$term == "ICC(A,1)", ]
  ak <- ml[ml$term == "ICC(A,k)", ]
  expect_equal(ak$conf.low, sb(a1$conf.low, n_r), tolerance = 1e-8)
  expect_equal(ak$conf.high, sb(a1$conf.high, n_r), tolerance = 1e-8)
  m_proj <- 7
  proj <- tidy(icc(
    sim,
    score,
    subject,
    rater,
    type = "agreement",
    ci_method = "mpl",
    unit = c("single", m_proj)
  ))
  pj <- proj[proj$term == "ICC(A,7)", ]
  expect_identical(nrow(pj), 1L)
  expect_equal(pj$conf.low, sb(a1$conf.low, m_proj), tolerance = 1e-8)
  expect_equal(pj$conf.high, sb(a1$conf.high, m_proj), tolerance = 1e-8)

  # "a deterministic closed form -- no resampling, no `seed`" (line 274). The
  # sibling test covers `"searle"` and `"burch"`; `"mpl"` is two-way, so it
  # cannot ride that one-way sweep and went unchecked (M130 return, F15).
  one <- function(sd) {
    tidy(icc(
      sim,
      score,
      subject,
      rater,
      type = "agreement",
      ci_method = "mpl",
      unit = "single",
      seed = sd
    ))$conf.low[1]
  }
  expect_identical(one(1), one(99))

  # Off the fence, each way the article names (line 263), classed each time.
  # The design fence and the rater-mode fence raise a BYTE-IDENTICAL message,
  # so pinning it cannot say which of the two fired (M130 return 2, O10). Both
  # are pinned to that shared message -- it is the design fence's message and
  # not some other refusal -- and each is then identified by differing from the
  # `sim` call asserted to RETURN an interval above in exactly one attribute:
  # here the model, below the rater mode. The unbalanced cell has a message of
  # its own and is pinned to it.
  fence_msg <- "available only for the two-way random"
  expect_error(
    icc(sim, score, subject, rater, model = "oneway", ci_method = "mpl"),
    regexp = fence_msg,
    class = "intraclass_unsupported"
  )
  # Warns before it aborts (the undefined type is dropped first); the message is
  # pinned too, so this asserts the consistency fence and not any refusal.
  expect_error(
    suppressWarnings(icc(
      sim,
      score,
      subject,
      rater,
      type = "consistency",
      ci_method = "mpl"
    )),
    regexp = "does not\\s+define a consistency",
    class = "intraclass_unsupported"
  )
  expect_error(
    suppressWarnings(icc(
      sim,
      score,
      subject,
      rater,
      type = "agreement",
      raters = "fixed",
      ci_method = "mpl"
    )),
    regexp = fence_msg,
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(
      sim[-1, ],
      score,
      subject,
      rater,
      type = "agreement",
      ci_method = "mpl"
    ),
    regexp = "requires balanced, complete two-way data",
    class = "intraclass_unsupported"
  )

  # `conf_level` is fenced to the three calibrated levels, never interpolated
  # between them (lines 266-267).
  for (cl in c(0.90, 0.95, 0.99)) {
    td <- tidy(icc(
      sim,
      score,
      subject,
      rater,
      type = "agreement",
      ci_method = "mpl",
      conf_level = cl,
      unit = "single"
    ))
    expect_false(is.na(td$conf.low), info = format(cl))
  }
  for (cl in c(0.925, 0.80, 0.995)) {
    expect_error(
      icc(
        sim,
        score,
        subject,
        rater,
        type = "agreement",
        ci_method = "mpl",
        conf_level = cl
      ),
      class = "intraclass_unsupported",
      info = format(cl)
    )
  }
})

# The article's study-restatement claims -----------------------------------
# The skew coverage figures and the searle/burch width ratios are pinned
# against the committed fixtures by `test-doc-skew-caveat.R`. These blocks
# cover the structural claims the article makes ABOUT those studies that no
# existing expectation asserts -- each read off the same committed fixtures, so
# a regenerated study reds the article's reading of it, not just its numerals.

test_that("interval-methods.Rmd: near-normal and uniform effects under-cover only where runs abort", {
  f <- utils::read.delim(
    testthat::test_path("fixtures", "skew-undercoverage.tsv"),
    stringsAsFactors = FALSE
  )
  mc <- f[f$source == "m113" & f$method == "mc", , drop = FALSE]
  benign <- mc[mc$dist %in% c("gaussian", "uniform"), , drop = FALSE]
  expect_gt(nrow(benign), 0L) # anti-vacuity

  # The article's claim: among the near-normal families, an under-covering cell
  # is always a high-abort cell -- so wherever the default almost always
  # returned an interval, those distributions were fine.
  quiet <- benign[benign$abort_rate <= 0.1, , drop = FALSE]
  expect_gt(nrow(quiet), 0L)
  expect_true(all(quiet$coverage_nonabort >= 0.93))
})

test_that("interval-methods.Rmd: two raters cover worse than five in every paired cell", {
  f <- utils::read.delim(
    testthat::test_path("fixtures", "skew-undercoverage.tsv"),
    stringsAsFactors = FALSE
  )
  # In this fixture `k` is the SUBJECT count and `n` the RATER count.
  mc <- f[f$source == "m113" & f$method == "mc", , drop = FALSE]
  two <- mc[mc$n == 2L, , drop = FALSE]
  five <- mc[mc$n == 5L, , drop = FALSE]
  shared <- intersect(
    paste(two$rho, two$k, two$dist, sep = "\r"),
    paste(five$rho, five$k, five$dist, sep = "\r")
  )
  expect_gt(length(shared), 0L) # anti-vacuity
  for (s in shared) {
    a <- two$coverage_nonabort[paste(two$rho, two$k, two$dist, sep = "\r") == s]
    b <- five$coverage_nonabort[
      paste(five$rho, five$k, five$dist, sep = "\r") == s
    ]
    expect_lt(a, b, label = paste("2-rater coverage at", s))
  }
  # And the article's reason it is not a recommendation: the 2-rater cells
  # abort far more often, so their failure is the visible kind. Restricted to
  # the SHARED cells, never the unstratified marginal (M130 return, F7): every
  # 2-rater cell sits at 10 subjects while the 5-rater cells span 10/30/50, and
  # article line 188 itself calls that confound out. Measured on the shared
  # cells: 0.269 against 0.177, so the claim survives the restriction.
  in_shared <- function(d) {
    paste(d$rho, d$k, d$dist, sep = "\r") %in% shared
  }
  expect_gt(
    mean(two$abort_rate[in_shared(two)]),
    mean(five$abort_rate[in_shared(five)])
  )
})

test_that("interval-methods.Rmd: the smaller grid carries only the two lowest true-ICC values", {
  w <- utils::read.delim(
    testthat::test_path("fixtures", "classical-width-by-cell.tsv"),
    stringsAsFactors = FALSE
  )
  small <- w[w$grid == "m76", , drop = FALSE]
  large <- w[w$grid == "m113", , drop = FALSE]
  # Article line 191 says "the smaller grid's 16 cells" in so many words, so
  # this row count IS a claim under test, not an incidental fixture pin: a
  # regenerated grid of a different size must red the article, not pass it.
  expect_identical(nrow(small), 16L)
  levels_large <- sort(unique(large$rho))
  expect_setequal(unique(small$rho), utils::head(levels_large, 2L))
  expect_gt(length(levels_large), 2L) # the larger grid really does reach further
})

test_that("interval-methods.Rmd: the between-grid gap is mostly design points, with a remainder", {
  w <- utils::read.delim(
    testthat::test_path("fixtures", "classical-width-by-cell.tsv"),
    stringsAsFactors = FALSE
  )
  key <- function(d) paste(d$rho, d$k, d$n, d$dist, sep = "\r")
  small <- w[w$grid == "m76", , drop = FALSE]
  large <- w[w$grid == "m113", , drop = FALSE]
  shared <- intersect(key(small), key(large))
  expect_identical(length(shared), nrow(small)) # the smaller grid is contained

  gap_pooled <- abs(stats::median(small$ratio) - stats::median(large$ratio))
  restricted <- large$ratio[key(large) %in% shared]
  gap_restricted <- abs(stats::median(small$ratio) - stats::median(restricted))

  # "Restricting the larger grid to the smaller one's design points closes most
  # of that gap" ...
  expect_lt(gap_restricted, gap_pooled / 2)
  # ... "and leaves a remainder": the gap does not merely fail to be zero, it
  # stays substantial. The floor is decades below the measured 0.005987 rather
  # than the bare `> 0` any floating-point difference satisfies, the same
  # realization-vs-property distinction the separation floor below draws
  # (M130 review pass 3, P7).
  expect_gt(gap_restricted, 1e-4)

  # "two separate simulations that mostly disagree at the design points they
  # share, agreeing closely at only a couple of them". Two things are claimed
  # and two are asserted: a COUPLE of cells agree to machine precision, and the
  # rest genuinely disagree rather than sitting at the edge of that threshold.
  # The earlier form pinned the realization instead -- a 1e-4 floor with about
  # 1.5e-5 of headroom, and an upper bound on the largest gap that the article
  # never claims (M130 return, F9). The separation floor is now decades below
  # the measured minimum, so it tests the qualitative split and not the run.
  d <- abs(
    small$ratio[match(shared, key(small))] -
      large$ratio[match(shared, key(large))]
  )
  # "A couple" is a small minority, not a pinned count: the earlier
  # `sum(d < 1e-9) == 2L` pinned the realization the same way the 1e-4 floor
  # did, which is what F9 named and the first repair left standing
  # (M130 return 2, O7).
  n_close <- sum(d < 1e-9)
  expect_gt(n_close, 0L)
  expect_lt(n_close, length(d) / 4)
  expect_gt(min(d[d >= 1e-9]), 1e-6)
})

# Every random-generator function called anywhere inside `expr` whose name
# matches `^r[a-z]+$`, namespace-qualified calls included (`stats::rnorm`
# resolves to "rnorm"). Mirrors the walker
# `data-raw/m116-classical-width-comparison.R` and
# `test-m118-both-components-dgp.R` use; kept local so this file's assertion
# does not depend on either of them loading. The name filter is a HEURISTIC,
# not a proof: `sample()` and `arima.sim()` are invisible to it, so a count of
# zero means "no `r*`-spelled draw", never "no draw at all"
# (M130 review pass 3, P8).
vc_rng_calls <- function(expr) {
  out <- character(0)
  walk <- function(e) {
    if (is.call(e)) {
      fn <- e[[1]]
      nm <- if (is.name(fn)) {
        as.character(fn)
      } else if (is.call(fn) && identical(as.character(fn[[1]]), "::")) {
        as.character(fn[[3]])
      } else {
        ""
      }
      # `rep`/`return` are not generators; the same two exclusions the M116
      # walker carries.
      if (grepl("^r[a-z]+$", nm) && !nm %in% c("rep", "return")) {
        out <<- c(out, nm)
      }
      for (i in seq_along(e)) {
        if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(expr)
  out
}

test_that("interval-methods.Rmd: the two subject-effect grids draw their errors from a normal", {
  # Article lines 207-208. This is a claim about the two generating scripts,
  # so it is asserted against their PARSED bodies -- the subject effect is the
  # only component that branches on `dist`, and every random draw in the error
  # term is `rnorm`. The earlier form grepped a `#` comment line in a TSV
  # header, which asserts what a header says rather than what the generator
  # does (M130 return, F2); a generator that changed its residual draw while
  # leaving its header alone passed it.
  scripts <- c("m76-coverage-sweep.R", "m111-fallback-sweep.R")
  paths <- vapply(
    scripts,
    function(f) testthat::test_path("..", "..", "data-raw", f),
    character(1)
  )
  # `data-raw/` is `.Rbuildignore`d, so this leg cannot run inside a built
  # package. That is structural for a claim ABOUT a generating script, and it
  # is the same fence `test-m118-both-components-dgp.R` sits behind. The
  # committed-fixture cross-check is its own unfenced block two tests below,
  # so the third-grid claim keeps one assertion inside a built package.
  skip_if_not(all(file.exists(paths)), "data-raw/ absent from a built package")

  for (path in paths) {
    gen <- NULL
    for (e in parse(path)) {
      if (
        is.call(e) &&
          is.name(e[[1]]) &&
          as.character(e[[1]]) %in% c("<-", "=") &&
          identical(as.character(e[[2]]), "gen_oneway")
      ) {
        gen <- e[[3]]
      }
    }
    expect_false(is.null(gen), label = paste("gen_oneway() found in", path))

    assigns <- Filter(
      function(e) {
        is.call(e) && is.name(e[[1]]) && as.character(e[[1]]) %in% c("<-", "=")
      },
      as.list(body(eval(gen)))
    )
    named <- function(nm) {
      hit <- Filter(function(e) identical(as.character(e[[2]]), nm), assigns)
      expect_identical(length(hit), 1L, label = paste(nm, "in", path))
      hit[[1]][[3]]
    }
    subject_rhs <- named("a")
    error_rhs <- named("vals")

    # The subject effect is the component that branches on `dist` ...
    expect_match(
      paste(deparse(subject_rhs), collapse = " "),
      "\\bdist\\b",
      info = path
    )
    # ... and the error term draws, and draws from a normal and nothing else.
    err_calls <- vc_rng_calls(error_rhs)
    expect_gt(length(err_calls), 0L)
    expect_setequal(unique(err_calls), "rnorm")
    # Nothing outside those two right-hand sides smuggles in a third
    # `r*`-spelled draw. The scan is over the WHOLE body, not only its
    # assignments: the earlier form could not see a draw inside a trailing bare
    # `data.frame(...)` return (M130 return 2, O11). It is bounded by the
    # walker's name filter, not exhaustive over every generator (P8).
    all_calls <- vc_rng_calls(body(eval(gen)))
    expect_identical(
      length(all_calls),
      length(c(vc_rng_calls(subject_rhs), err_calls)),
      label = paste("every draw accounted for in", path)
    )
  }
})

test_that("interval-methods.Rmd: the third grid draws both components from the family", {
  # The other half of article lines 207-212: the third grid is the one that
  # does otherwise. Asserted on the generator's PARSED body, like the leg
  # above. The earlier form grepped the committed fixture's `#` header, which
  # is the very shape F2 condemned -- it asserts what a header SAYS, and a
  # generator that reverted one component to a normal while leaving its header
  # alone passed it (M130 return 2, O6). The header line is checked too, but
  # only as a consistency cross-check against what the body does; the
  # structural fence with its own mutation harness behind it is
  # `test-m118-both-components-dgp.R`, which this mirrors rather than replaces.
  path <- testthat::test_path(
    "..",
    "..",
    "data-raw",
    "m118-width-reversal-sweep.R"
  )
  skip_if_not(file.exists(path), "data-raw/ absent from a built package")

  gen <- NULL
  for (e in parse(path)) {
    if (
      is.call(e) &&
        is.name(e[[1]]) &&
        as.character(e[[1]]) %in% c("<-", "=") &&
        identical(as.character(e[[2]]), "gen_oneway")
    ) {
      gen <- e[[3]]
    }
  }
  expect_false(is.null(gen))
  assigns <- Filter(
    function(e) {
      is.call(e) && is.name(e[[1]]) && as.character(e[[1]]) %in% c("<-", "=")
    },
    as.list(body(eval(gen)))
  )
  rhs <- function(nm) {
    hit <- Filter(function(e) identical(as.character(e[[2]]), nm), assigns)
    expect_identical(length(hit), 1L, label = nm)
    paste(deparse(hit[[1]][[3]]), collapse = " ")
  }
  # BOTH components go through the same family-valued draw, and neither names
  # a distribution of its own -- that is what "both components" means here.
  for (nm in c("a", "e")) {
    expect_match(rhs(nm), "draw_standard\\([^)]*\\bdist\\b", info = nm)
  }
  # And no `r*`-spelled draw anywhere in the body bypasses `draw_standard()`
  # -- the fence the local walker's name filter can carry, no wider.
  expect_length(vc_rng_calls(body(eval(gen))), 0L)
})

test_that("interval-methods.Rmd: the third grid's shipped fixture states both components", {
  # The one leg of the third-grid claim that runs inside a BUILT package. Both
  # blocks above are fenced behind `.Rbuildignore`d `data-raw/`, so while they
  # were fenced together article lines 207-212 had no shipped assertion at all
  # (M130 review pass 3, P3). This leg asserts what the committed fixture's
  # header SAYS -- weaker than the parsed-body fence above, which is why it is
  # a cross-check and not a replacement, and why it carries no `skip_if_not()`.
  res <- utils::head(
    readLines(
      testthat::test_path("fixtures", "width-reversal-by-cell.tsv"),
      warn = FALSE
    ),
    5L
  )
  expect_true(any(grepl("Both A_i and e_ij are drawn", res, fixed = TRUE)))
})

# --- The per-`ci_method` fence pins (M133) --------------------------------
# One pair of live calls per value of the `ci_method` choice vector -- the
# `validate_choice()` call for `ci_method` in `R/icc.R`, at `:714-726` when last
# read -- pinning where each method's fence sits: one call the method computes
# an interval for, asserted to return one, and one call it refuses, asserted to
# raise the classed abort. The pins are the deliverable; a fence moved without
# these reds is the thing they exist to catch.
#
# Failure identity (tracking-rules): each refused call is pinned to the message
# of the fence it is meant to fire, so a refusal arriving from some other guard
# cannot be read as the fence under test. Each also differs from a call
# asserted to succeed in exactly the one attribute that fence names; that
# contrast is what the `differs` field records. The field is documentation read
# back in `info=` on failure -- the pinned message is what enforces identity --
# except for the lavaan bootstrap, whose message is generic ("not yet available
# for this design/engine combination") and shared by every site that withholds a
# `simulate_refit` -- the pinned call reaches the single-level `has_missing`
# guard at `R/engine-lavaan.R:770`, not the multilevel triple at `:573-576`.
# There the contrast IS the identification, which is why that method carries its
# own control call rather than borrowing another's.

test_that("icc(): the supported call returns an interval, every frequentist ci_method", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")
  skip_on_cran()

  sim <- vc_mpl_sim()
  # One supported call per method, each with the coefficient family that call
  # produces and the interval method it is about. Both are asserted: a design
  # argument changed under a call moves the family, and a `ci_method` changed
  # under it moves the method, so neither can drift unnoticed.
  two_way <- c("ICC(A,1)", "ICC(A,k)", "ICC(C,1)", "ICC(C,k)")
  one_way <- c("ICC(1)", "ICC(k)")
  agreement <- c("ICC(A,1)", "ICC(A,k)")
  # `"posterior"` needs a Stan toolchain and is asserted in its own test below.
  supported <- list(
    montecarlo = list(
      indices = two_way,
      method = "montecarlo",
      call = function() {
        icc(ratings, score, subject, rater, seed = 1)
      }
    ),
    # Two calls: the mixed-model engine first, and the
    # lavaan-on-complete-data control the refused call below is contrasted
    # against (that fence's message is generic, so the contrast carries it).
    bootstrap = list(
      indices = two_way,
      method = "bootstrap",
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          ci_method = "bootstrap",
          boot_samples = 19,
          seed = 1
        )
      }
    ),
    `bootstrap (lavaan control)` = list(
      indices = two_way,
      method = "bootstrap",
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          engine = "lavaan",
          ci_method = "bootstrap",
          boot_samples = 19,
          seed = 1
        )
      }
    ),
    npbootstrap = list(
      indices = one_way,
      method = "npbootstrap",
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = "npbootstrap",
          boot_samples = 99,
          seed = 1
        )
      }
    ),
    searle = list(
      indices = one_way,
      method = "searle",
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = "searle"
        )
      }
    ),
    burch = list(
      indices = one_way,
      method = "burch",
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = "burch"
        )
      }
    ),
    mpl = list(
      indices = agreement,
      method = "mpl",
      call = function() {
        icc(sim, score, subject, rater, type = "agreement", ci_method = "mpl")
      }
    )
  )
  # Anti-vacuity by NAME, not by count: a bare length check passes on any seven
  # entries, and this list's seven are six methods plus a control. Ask the
  # validator for the accepted set -- the same enumerator the sibling test uses
  # -- and require every value to have a supported call here, `"posterior"`
  # excepted because its call is a live brms fit in its own test above.
  msg <- tryCatch(
    icc(ratings, score, subject, rater, ci_method = "not-a-method", seed = 1),
    error = conditionMessage
  )
  all_methods <- gsub(
    '"',
    "",
    regmatches(msg, gregexpr('"[^"]+"', msg))[[1]],
    fixed = TRUE
  )
  expect_gt(length(all_methods), 0L)
  expect_setequal(
    setdiff(names(supported), "bootstrap (lavaan control)"),
    setdiff(all_methods, "posterior")
  )

  for (nm in names(supported)) {
    entry <- supported[[nm]]
    td <- suppressWarnings(tidy(entry$call()))
    expect_gt(nrow(td), 0L)
    expect_false(any(is.na(td$conf.low)), info = nm)
    expect_false(any(is.na(td$conf.high)), info = nm)
    # The reported estimate lies within the reported bounds (which does not by
    # itself exclude a zero-width interval).
    expect_true(all(td$conf.low <= td$estimate), info = nm)
    expect_true(all(td$estimate <= td$conf.high), info = nm)
    # The coefficient family this supported call produces. `expect_setequal()`
    # takes no `info`, so this is the labelled form -- a failure has to name
    # which method moved, and what it returned instead.
    expect_true(
      setequal(td$term, entry$indices),
      info = paste0(nm, " -- got: ", paste(td$term, collapse = ", "))
    )
    # The method asked for is the method that produced the interval -- a silent
    # fallback to the Monte-Carlo default would make the pin vacuous.
    expect_true(all(td$method == entry$method), info = nm)
  }
})

test_that("icc(): the supported call returns a credible interval, ci_method = \"posterior\"", {
  # The one supported call that needs a Stan compiler. Gated exactly as every
  # other live brms fit in this package is (`test-icc-brms.R`): CI carries brms
  # but no toolchain, so this runs locally and is skipped there.
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("brms")

  # Tiny sampler -- the claim is that the Bayesian engine returns a
  # credible interval on its supported family, never that the interval is
  # well-sampled at this size. Sampling warnings on six subjects are expected.
  fit <- suppressWarnings(icc(
    ratings,
    score,
    subject,
    rater,
    type = "agreement",
    engine = "brms",
    seed = 1,
    brm_args = list(chains = 2, iter = 1000, refresh = 0)
  ))
  expect_identical(fit$ci$method, "posterior")

  td <- tidy(fit)
  expect_setequal(td$term, c("ICC(A,1)", "ICC(A,k)"))
  expect_false(any(is.na(td$conf.low)))
  expect_true(all(td$conf.low <= td$estimate & td$estimate <= td$conf.high))
})

test_that("icc(): the refused call aborts classed, every ci_method", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")
  skip_on_cran()

  sim <- vc_mpl_sim()
  # `ratings` is balanced and `ratings_incomplete` is not -- the one attribute
  # separating the `"searle"`/`"burch"` refusals from their supported calls,
  # and the completeness attribute separating the lavaan bootstrap's. Asserted,
  # never assumed, so a regenerated dataset cannot make those contrasts vacuous.
  expect_identical(length(unique(table(ratings$subject))), 1L)
  expect_gt(length(unique(table(ratings_incomplete$subject))), 1L)

  # method -> (call, the fence message it must fire, the attribute it differs
  # in from the supported call above).
  refused <- list(
    montecarlo = list(
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          engine = "brms",
          ci_method = "montecarlo"
        )
      },
      regexp = "requires `ci_method = \"posterior\"`",
      differs = "engine"
    ),
    bootstrap = list(
      call = function() {
        icc(
          ratings_incomplete,
          score,
          subject,
          rater,
          engine = "lavaan",
          ci_method = "bootstrap",
          boot_samples = 19,
          seed = 1
        )
      },
      regexp = "not yet available for this design/engine",
      differs = "data completeness"
    ),
    posterior = list(
      call = function() {
        icc(ratings, score, subject, rater, ci_method = "posterior", seed = 1)
      },
      regexp = "requires `engine = \"brms\"`",
      differs = "engine"
    ),
    npbootstrap = list(
      call = function() {
        icc(
          ratings,
          score,
          subject,
          rater,
          ci_method = "npbootstrap",
          boot_samples = 19,
          seed = 1
        )
      },
      regexp = "available only for the one-way random",
      differs = "model"
    ),
    searle = list(
      call = function() {
        icc(
          ratings_incomplete,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = "searle"
        )
      },
      regexp = "requires a balanced one-way design",
      differs = "data balance"
    ),
    burch = list(
      call = function() {
        icc(
          ratings_incomplete,
          score,
          subject,
          rater,
          model = "oneway",
          ci_method = "burch"
        )
      },
      regexp = "requires a balanced one-way design",
      differs = "data balance"
    ),
    mpl = list(
      call = function() {
        icc(sim, score, subject, rater, type = "consistency", ci_method = "mpl")
      },
      regexp = "does not\\s+define a consistency",
      differs = "type"
    )
  )
  # Anti-vacuity by NAME, as in the supported test: every accepted `ci_method`
  # value has a refused call here, none skipped. A bare count would pass on any
  # seven entries.
  msg <- tryCatch(
    icc(ratings, score, subject, rater, ci_method = "not-a-method", seed = 1),
    error = conditionMessage
  )
  all_methods <- gsub(
    '"',
    "",
    regmatches(msg, gregexpr('"[^"]+"', msg))[[1]],
    fixed = TRUE
  )
  expect_gt(length(all_methods), 0L)
  expect_setequal(names(refused), all_methods)

  for (nm in names(refused)) {
    expect_error(
      suppressWarnings(refused[[nm]]$call()),
      regexp = refused[[nm]]$regexp,
      class = "intraclass_unsupported",
      info = paste(nm, "-- differs in", refused[[nm]]$differs)
    )
  }
})

test_that("icc(): the second supported call runs, the ci_methods that admit one", {
  skip_if_not_installed("glmmTMB")
  skip_on_cran()

  # Three methods admit a second supported call, and the paired-call tests
  # above run only one call per side. These are the remainders (M133 review,
  # findings 3 and 9), each asserted on the surface rather than left as prose.
  sim <- vc_mpl_sim()

  # `"npbootstrap"`: a numeric `unit` projection is supported on BALANCED
  # one-way data and refused on unbalanced, which is the pair pinned here.
  # `ratings` is balanced and `ratings_incomplete` is not (asserted in the
  # refused test above), so the two calls differ in that attribute alone.
  np2 <- tidy(icc(
    ratings,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "npbootstrap",
    unit = 2,
    boot_samples = 99,
    seed = 1
  ))
  expect_setequal(np2$term, "ICC(2)")
  expect_true(all(np2$method == "npbootstrap"))
  expect_false(any(is.na(np2$conf.low)))
  expect_error(
    icc(
      ratings_incomplete,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "npbootstrap",
      unit = 2,
      boot_samples = 99,
      seed = 1
    ),
    regexp = "supports .*unit = .single",
    class = "intraclass_unsupported"
  )

  # `"mpl"`: a numeric `unit` projection of the agreement pair. The sibling
  # `"mpl"` fences test checks this projection against its Spearman-Brown
  # image; here the claim under test is only that the projection is reachable
  # -- it returns an interval by the method asked for.
  m7 <- tidy(icc(
    sim,
    score,
    subject,
    rater,
    type = "agreement",
    ci_method = "mpl",
    unit = c("single", "average", 7)
  ))
  expect_setequal(m7$term, c("ICC(A,1)", "ICC(A,k)", "ICC(A,7)"))
  expect_true(all(m7$method == "mpl"))
  expect_false(any(is.na(m7$conf.low)))

  # `"montecarlo"` has no second supported call to add here. Its brms refusal is
  # EXPLICIT-only -- an unset `ci_method` upgrades to `"posterior"` instead of
  # refusing -- and both halves are already pinned elsewhere: the explicit
  # refusal in the refused block above, the unset upgrade in `test-icc-brms.R`
  # ("engine = \"brms\" forces ci_method = \"posterior\" by default").
})

# --- M146: no doc surface writes `occasions` as a numeric argument -------------
# `occasions` takes the keywords `"single"` and `"average"`; `validate_occasions()`
# rejects a number. Prose that writes `occasions = 3` therefore mimics a call the
# package refuses, and reads as if the argument were the design's per-cell count
# (which is `glance()$n_o`, a different quantity -- D-044). Sweep the doc
# surfaces for that shape.
#
# The sweep runs over whitespace-COLLAPSED text, so a form wrapped across lines
# is caught too (`cairn/doctrine/doc-claim-pins.md`). All four path groups live
# in the source tree only, so the block skips under `R CMD check` -- the tier
# `test-vignette-transcripts.R` already uses for `vignettes/`.

occasions_numeric_re <- "occasions[[:space:]]*=[[:space:]]*[\"']?[0-9]"

test_that("no vignette, README, NEWS or roxygen prose writes occasions = <number>", {
  root <- testthat::test_path("..", "..")
  vig_dir <- file.path(root, "vignettes")
  r_dir <- file.path(root, "R")
  skip_if_not(
    dir.exists(vig_dir) && dir.exists(r_dir),
    "source tree not present (running against the built package)"
  )

  squash_file <- function(lines) {
    gsub("[[:space:]]+", " ", paste(lines, collapse = " "))
  }

  swept <- list()
  for (f in list.files(vig_dir, pattern = "\\.Rmd$", full.names = TRUE)) {
    swept[[paste0("vignettes/", basename(f))]] <-
      squash_file(readLines(f, warn = FALSE))
  }
  for (f in c("README.Rmd", "NEWS.md")) {
    p <- file.path(root, f)
    if (file.exists(p)) {
      swept[[f]] <- squash_file(readLines(p, warn = FALSE))
    }
  }
  # `R/`: the roxygen only. An internal comment is not a doc surface a user
  # reads, and code legitimately names the argument.
  for (f in list.files(r_dir, pattern = "\\.R$", full.names = TRUE)) {
    lines <- readLines(f, warn = FALSE)
    rox <- sub(
      "^[[:space:]]*#'[[:space:]]?",
      "",
      lines[grepl("^[[:space:]]*#'", lines)]
    )
    if (length(rox) > 0) {
      swept[[paste0("R/", basename(f))]] <- squash_file(rox)
    }
  }

  # Anti-vacuity: an empty sweep, or one whose globs matched nothing, would
  # satisfy the absence check for free. Both groups must be non-empty, and the
  # swept text must actually contain the word the pattern is about.
  expect_gt(sum(grepl("^vignettes/", names(swept))), 3L)
  expect_gt(sum(grepl("^R/", names(swept))), 3L)
  expect_true("NEWS.md" %in% names(swept))
  expect_true(any(grepl("occasions", unlist(swept), fixed = TRUE)))

  hits <- names(swept)[vapply(
    swept,
    function(txt) grepl(occasions_numeric_re, txt),
    logical(1)
  )]
  expect_identical(hits, character())
})

test_that("the occasions = <number> sweep sees the shapes it claims to", {
  # Discrimination: the pattern is asserted against each spelling directly, so
  # the sweep above is known to be more than a search for one literal string.
  squash <- function(x) gsub("[[:space:]]+", " ", paste(x, collapse = " "))
  caught <- c(
    "the rows (`occasions = 3` here) give",
    "the rows (`occasions=3` here) give",
    "the rows (`occasions =  3` here) give",
    "pass `occasions = \"3\"` to the call",
    squash(c("the rows (`occasions =", "3` here) give")) # wrapped across lines
  )
  for (s in caught) {
    expect_true(grepl(occasions_numeric_re, s))
  }
  # And is silent on the forms the vignettes legitimately use.
  passed <- c(
    "the rows whose `occasions` column reads 1",
    "`occasions` 3 here, the fitted per-cell replicate count",
    "occasions = c(\"single\", \"average\")",
    "the occasion count `n_o` at 3"
  )
  for (s in passed) {
    expect_false(grepl(occasions_numeric_re, s))
  }
})
