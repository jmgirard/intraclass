# Within-cell replicates (M17 Slice 3) -----------------------------------------
#
# Multiple ratings per subject x rater cell split the residual into the
# interaction sigma^2_sr and pure error sigma^2_e, fit by
#   score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater).
# A new `occasions` knob averages over the replicates (estimand-spec
# M17-within-cell-replicates.md). Oracles (PRINCIPLES.md #1): the balanced
# two-way-with-replication ANOVA mean squares (method of moments, independent of
# REML), an independent lme4 fit, and a seeded simulation. No gtheory dependency.

# Balanced two-way random design with `no` exchangeable replicates per cell.
sim_replicates <- function(ns, nr, no, vs, vr, vsr, ve, seed) {
  set.seed(seed)
  s <- stats::rnorm(ns, 0, sqrt(vs))
  r <- stats::rnorm(nr, 0, sqrt(vr))
  grid <- expand.grid(
    subject = seq_len(ns),
    rater = seq_len(nr),
    occ = seq_len(no)
  )
  srv <- stats::rnorm(ns * nr, 0, sqrt(vsr))
  grid$sr <- srv[(grid$rater - 1) * ns + grid$subject]
  grid$score <- 10 +
    s[grid$subject] +
    r[grid$rater] +
    grid$sr +
    stats::rnorm(nrow(grid), 0, sqrt(ve))
  grid$subject <- factor(grid$subject)
  grid$rater <- factor(grid$rater)
  grid
}

# Method-of-moments components from the balanced two-way ANOVA with replication.
anova_components <- function(d, no, ns, nr) {
  m <- stats::aov(score ~ subject * rater, data = d)
  tab <- summary(m)[[1]]
  ms <- tab[, "Mean Sq"]
  names(ms) <- trimws(rownames(tab))
  ms_s <- ms[["subject"]]
  ms_r <- ms[["rater"]]
  ms_sr <- ms[["subject:rater"]]
  ms_e <- ms[["Residuals"]]
  c(
    subject = (ms_s - ms_sr) / (no * nr),
    rater = (ms_r - ms_sr) / (no * ns),
    subject_rater = (ms_sr - ms_e) / no,
    residual = ms_e
  )
}

pick_occ <- function(x, index, occ) {
  e <- x$estimates
  e$estimate[e$index == index & e$occasions == occ]
}

test_that("O-ANOVA: replicate components and ICCs match the two-way ANOVA (MoM)", {
  skip_if_not_installed("glmmTMB")
  ns <- 20
  nr <- 4
  no <- 3
  d <- sim_replicates(ns, nr, no, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  x <- icc(
    d,
    score,
    subject,
    rater,
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  cmp <- anova_components(d, no, ns, nr)
  # Components (REML == ANOVA MoM on balanced data).
  expect_equal(x$components$subject, cmp[["subject"]], tolerance = 1e-4)
  expect_equal(x$components$rater, cmp[["rater"]], tolerance = 1e-4)
  expect_equal(
    x$components$subject_rater,
    cmp[["subject_rater"]],
    tolerance = 1e-4
  )
  expect_equal(x$components$residual, cmp[["residual"]], tolerance = 1e-4)

  vs <- cmp[["subject"]]
  vr <- cmp[["rater"]]
  vsr <- cmp[["subject_rater"]]
  ve <- cmp[["residual"]]
  # Single-occasion ICC family (agreement).
  expect_equal(
    pick_occ(x, "ICC(A,1)", 1),
    vs / (vs + vr + vsr + ve),
    tolerance = 1e-4
  )
  expect_equal(
    pick_occ(x, "ICC(A,k)", 1),
    vs / (vs + (vr + vsr + ve) / nr),
    tolerance = 1e-4
  )
  # Occasion-averaged (n_o occasions): only pure error is divided by n_o.
  expect_equal(
    pick_occ(x, "ICC(A,k)", no),
    vs / (vs + (vr + vsr) / nr + ve / (nr * no)),
    tolerance = 1e-4
  )
  expect_equal(
    pick_occ(x, "ICC(A,1)", no),
    vs / (vs + vr + vsr + ve / no),
    tolerance = 1e-4
  )

  # Consistency drops the rater main effect from the error set.
  xc <- icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  expect_equal(
    pick_occ(xc, "ICC(C,1)", 1),
    vs / (vs + vsr + ve),
    tolerance = 1e-4
  )
  expect_equal(
    pick_occ(xc, "ICC(C,k)", no),
    vs / (vs + vsr / nr + ve / (nr * no)),
    tolerance = 1e-4
  )
})

test_that("O-lme4: replicate fit matches an independent lme4 interaction fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  d <- sim_replicates(20, 4, 3, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  x <- icc(d, score, subject, rater, seed = 1)
  m <- lme4::lmer(
    score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater),
    data = d,
    REML = TRUE
  )
  vc <- lme4::VarCorr(m)
  expect_equal(x$components$subject, as.numeric(vc$subject), tolerance = 1e-4)
  expect_equal(x$components$rater, as.numeric(vc$rater), tolerance = 1e-4)
  expect_equal(
    x$components$subject_rater,
    as.numeric(vc[["subject:rater"]]),
    tolerance = 1e-4
  )
  expect_equal(x$components$residual, stats::sigma(m)^2, tolerance = 1e-4)
})

test_that("O-sim: known replicate components recovered and covered", {
  skip_if_not_installed("glmmTMB")
  vs <- 1.2
  vr <- 0.7
  vsr <- 0.4
  ve <- 0.5
  nr <- 5
  no <- 4
  d <- sim_replicates(40, nr, no, vs, vr, vsr, ve, seed = 424242)
  x <- icc(
    d,
    score,
    subject,
    rater,
    occasions = c("single", "average"),
    seed = 20260708
  )
  expect_lt(abs(x$components$subject_rater - vsr), 0.15)
  expect_lt(abs(x$components$residual - ve), 0.05)
  pop_a1 <- vs / (vs + vr + vsr + ve)
  row <- x$estimates[
    x$estimates$index == "ICC(A,1)" & x$estimates$occasions == 1,
  ]
  expect_lt(abs(row$estimate - pop_a1), 0.1)
  expect_true(row$conf.low <= pop_a1 && pop_a1 <= row$conf.high)
})

test_that("occasion averaging raises reliability by cutting pure error", {
  skip_if_not_installed("glmmTMB")
  no <- 3
  d <- sim_replicates(20, 4, no, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  x <- icc(
    d,
    score,
    subject,
    rater,
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  # Averaging over occasions divides only sigma^2_e, so it can only raise (never
  # lower) reliability at the same rater unit -- and strictly so when sigma^2_e > 0.
  expect_gt(pick_occ(x, "ICC(A,k)", no), pick_occ(x, "ICC(A,k)", 1))
  expect_gt(pick_occ(x, "ICC(A,1)", no), pick_occ(x, "ICC(A,1)", 1))
  # The single-occasion single-rater ICC is the reliability of ONE rating: its error
  # is the full sigma^2_r + sigma^2_sr + sigma^2_e (nothing averaged away).
  vc <- x$components
  s <- vc$subject
  err <- vc$rater + vc$subject_rater + vc$residual
  expect_equal(pick_occ(x, "ICC(A,1)", 1), s / (s + err), tolerance = 1e-6)
})

test_that("replicates surface the interaction component and an occasions column", {
  skip_if_not_installed("glmmTMB")
  d <- sim_replicates(15, 4, 2, 1.2, 0.7, 0.4, 0.5, seed = 7)
  x <- icc(
    d,
    score,
    subject,
    rater,
    occasions = c("single", "average"),
    seed = 1
  )
  expect_true(!is.null(x$components$subject_rater))
  expect_true("occasions" %in% names(x$estimates))
  expect_setequal(unique(x$estimates$occasions), c(1, 2))
  lines <- format(x)
  expect_true(any(grepl("subject:rater", lines)))
  # A non-replicated fit is unchanged: no occasions column, no interaction.
  y <- icc(ratings, score, subject, rater, seed = 1)
  expect_false("occasions" %in% names(y$estimates))
  expect_null(y$components$subject_rater)
})

test_that("replicate scope guards fail loudly (#5, #8)", {
  skip_if_not_installed("glmmTMB")
  d <- sim_replicates(15, 4, 2, 1.2, 0.7, 0.4, 0.5, seed = 7)
  # occasions = "average" needs replicated data.
  expect_error(
    icc(ratings, score, subject, rater, occasions = "average"),
    class = "intraclass_error"
  )
  # Ragged replicates (unequal per cell) are deferred.
  ragged <- d[-1, ]
  expect_error(
    icc(ragged, score, subject, rater),
    class = "intraclass_unsupported"
  )
  # Fixed-rater replicates are deferred. (The fixed-rater advisory fires before the
  # abort, as it does for any fixed-rater rejection; suppress it here.)
  expect_error(
    suppressWarnings(icc(d, score, subject, rater, raters = "fixed")),
    class = "intraclass_unsupported"
  )
})

test_that("both ci_methods work for replicated designs", {
  skip_if_not_installed("glmmTMB")
  d <- sim_replicates(15, 4, 2, 1.2, 0.7, 0.4, 0.5, seed = 7)
  b <- icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 50,
    occasions = c("single", "average"),
    seed = 1
  )
  expect_true(all(b$estimates$conf.low <= b$estimates$estimate))
  expect_true(all(b$estimates$estimate <= b$estimates$conf.high))
  expect_identical(b$ci$method, "bootstrap")
})
