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
  fit <- icc(ratings, score, subject, rater, type = "agreement", seed = 1)
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
    list(nm = "two-level", d = ml, a = list(cluster = quote(cluster)))
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
  expect_true(all(td_ml$method == "bootstrap"))
  expect_false(any(is.na(td_ml$conf.low)))

  # Fenced, each way the article names, each classed.
  expect_error(lv(ratings_incomplete), class = "intraclass_unsupported")
  expect_error(
    lv(ml, cluster = cluster, raters = "fixed"),
    class = "intraclass_unsupported"
  )
  expect_error(
    lv(ml[-(1:3), ], cluster = cluster),
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
  lo <- vapply(
    c(0.5, 0.8, 0.95, 0.995),
    function(cl) {
      td <- tidy(icc(
        ratings,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "npbootstrap",
        conf_level = cl,
        boot_samples = 199,
        seed = 1
      ))
      td$conf.high[1] - td$conf.low[1]
    },
    numeric(1)
  )
  expect_true(all(diff(lo) > 0))
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
  expect_false(all(bs$conf.high >= mc$conf.high))
  rounded_equal <- round(bs$conf.high, 2) == round(mc$conf.high, 2)
  expect_identical(mc$index[rounded_equal], "ICC(A,k)")
  # And it is the upper bound alone, never the pair: at that same rendering
  # ICC(A,k)'s lower bounds do not agree. This is the claim the article got
  # wrong once (M130 return, F3) -- an assertion on the upper bounds alone
  # would pass with "the pair rounds alike" back in the prose.
  ak <- mc$index == "ICC(A,k)"
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
  # skew-driven inflation, so nothing in the output flags the shortfall.
  expect_true(all(td$method == "montecarlo"))
  expect_lt(td$conf.high[1] - td$conf.low[1], 0.5)
})

test_that("interval-methods.Rmd: `\"searle\"` and `\"burch\"` project through the same Spearman-Brown image", {
  skip_if_not_installed("glmmTMB")

  # Article line 140: both closed forms project ICC(k) -- and a numeric `unit` --
  # through the same map `"npbootstrap"` uses. Check the map itself on the
  # endpoints, which is what "the same image" means.
  sb <- function(p, k) k * p / (1 + (k - 1) * p)
  for (m in c("searle", "burch", "npbootstrap")) {
    args <- list(
      ratings,
      quote(score),
      quote(subject),
      quote(rater),
      model = "oneway",
      ci_method = m,
      unit = c("single", "average")
    )
    if (m == "npbootstrap") {
      args <- c(args, list(boot_samples = 199, seed = 1))
    }
    td <- tidy(do.call(icc, args))
    single <- td[td$index == "ICC(1)", ]
    average <- td[td$index == "ICC(k)", ]
    k <- 4 # `ratings` has four raters
    expect_equal(average$estimate, sb(single$estimate, k), tolerance = 1e-8)
    expect_equal(average$conf.low, sb(single$conf.low, k), tolerance = 1e-8)
    expect_equal(average$conf.high, sb(single$conf.high, k), tolerance = 1e-8)
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
  # The abort is classed `intraclass_singular_fit` -- the kurtosis
  # standardization divides by a between-subject variance of exactly zero.
  expect_error(
    icc(flat, score, subject, rater, model = "oneway", ci_method = "burch"),
    class = "intraclass_singular_fit"
  )
  se <- tidy(icc(
    flat,
    score,
    subject,
    rater,
    model = "oneway",
    ci_method = "searle",
    unit = "single"
  ))
  expect_false(is.na(se$conf.low))
  expect_false(is.na(se$conf.high))
})

test_that("interval-methods.Rmd: the `\"mpl\"` fences are the ones the article names", {
  skip_if_not_installed("glmmTMB")

  # Article lines 257-275, run on the article's own simulated design (the
  # `ci-mpl` chunk's data, rebuilt at its seed -- `ratings` is too small for
  # the calibration grid).
  set.seed(88)
  n_s <- 20
  n_r <- 4
  subj_eff <- rnorm(n_s, sd = sqrt(0.6))
  rater_eff <- rnorm(n_r, sd = sqrt(0.1))
  noise <- matrix(rnorm(n_s * n_r, sd = sqrt(0.2)), n_s, n_r)
  sim <- data.frame(
    subject = factor(rep(seq_len(n_s), times = n_r)),
    rater = factor(rep(seq_len(n_r), each = n_s)),
    score = as.numeric(
      outer(subj_eff, rep(1, n_r)) +
        outer(rep(1, n_s), rater_eff) +
        noise
    )
  )

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

  # ICC(A,k) is the pole-safe Spearman-Brown image of ICC(A,1) (line 262).
  sb <- function(p, k) k * p / (1 + (k - 1) * p)
  a1 <- ml[ml$index == "ICC(A,1)", ]
  ak <- ml[ml$index == "ICC(A,k)", ]
  expect_equal(ak$conf.low, sb(a1$conf.low, n_r), tolerance = 1e-8)
  expect_equal(ak$conf.high, sb(a1$conf.high, n_r), tolerance = 1e-8)

  # Off the fence, each way the article names (line 263), classed each time.
  expect_error(
    icc(sim, score, subject, rater, model = "oneway", ci_method = "mpl"),
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
  cell <- paste(mc$rho, mc$k, mc$dist, sep = "\r")
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
  # abort far more often, so their failure is the visible kind.
  expect_gt(mean(two$abort_rate), mean(five$abort_rate))
})

test_that("interval-methods.Rmd: the smaller grid carries only the two lowest true-ICC values", {
  w <- utils::read.delim(
    testthat::test_path("fixtures", "classical-width-by-cell.tsv"),
    stringsAsFactors = FALSE
  )
  small <- w[w$grid == "m76", , drop = FALSE]
  large <- w[w$grid == "m113", , drop = FALSE]
  expect_identical(nrow(small), 16L) # the article's "16 cells"
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
  # ... "and leaves a remainder": the gap does not vanish.
  expect_gt(gap_restricted, 0)

  # "two separate simulations that mostly disagree at the design points they
  # share, agreeing closely at only a couple of them": exactly two of the
  # sixteen shared cells agree to within 1e-9 (they are the same underlying
  # run); the other fourteen differ by between 1e-4 and 8.3e-3.
  d <- abs(
    small$ratio[match(shared, key(small))] -
      large$ratio[match(shared, key(large))]
  )
  expect_identical(sum(d < 1e-9), 2L)
  expect_gt(min(d[d >= 1e-9]), 1e-4)
  expect_lt(max(d), 0.01)
})

test_that("interval-methods.Rmd: the two subject-effect grids draw their errors from a normal", {
  # The article's line about what the grids vary is a claim about the
  # generating scripts, which the M116 generator asserts against their source
  # before it writes the comparison table's header.
  tsv <- testthat::test_path(
    "..",
    "..",
    "data-raw",
    "m116-classical-width-comparison.tsv"
  )
  skip_if_not(file.exists(tsv), "data-raw/ absent from a built package")
  head_lines <- utils::head(readLines(tsv, warn = FALSE), 40L)
  dgp <- grep("^#", head_lines, value = TRUE)
  expect_true(
    any(grepl("SUBJECT EFFECT", dgp, fixed = TRUE)) &&
      any(grepl("error always from", dgp, fixed = TRUE))
  )
  # The third grid is the one that does otherwise, and says so in its own header.
  res <- utils::head(
    readLines(
      testthat::test_path("fixtures", "width-reversal-by-cell.tsv"),
      warn = FALSE
    ),
    5L
  )
  expect_true(any(grepl("Both A_i and e_ij are drawn", res, fixed = TRUE)))
})
