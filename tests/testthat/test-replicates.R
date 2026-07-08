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
  # Ragged random single-occasion replicates now fit (M20 Slice 3); the
  # occasion-AVERAGED coefficient stays deferred to research (no validated effective-n_o
  # divisor). See the O-RagRep block below for the full ragged oracles.
  ragged <- d[-1, ]
  expect_s3_class(suppressMessages(icc(ragged, score, subject, rater)), "icc")
  expect_error(
    suppressMessages(icc(ragged, score, subject, rater, occasions = "average")),
    class = "intraclass_unsupported"
  )
  # Ragged x fixed replicates stay deferred (compound imbalance -- fixed replicates
  # ship balanced only, ADR-030). The fixed-rater advisory fires before the abort.
  expect_error(
    suppressWarnings(icc(ragged, score, subject, rater, raters = "fixed")),
    class = "intraclass_unsupported"
  )
  # Multilevel x fixed replicates stay deferred (multilevel replicates are M20
  # Slice 2; the multilevel guard fires first, for random and fixed alike).
  dc <- d
  dc$cluster <- factor(ifelse(as.integer(dc$subject) <= 8, "a", "b"))
  expect_error(
    suppressWarnings(
      icc(dc, score, subject, rater, cluster = cluster, raters = "fixed")
    ),
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

# Fixed-rater within-cell replicates (M20 Slice 1, ADR-030) --------------------
#
# The two-way interaction model with raters FIXED:
#   score ~ 1 + rater + (1 | subject) + (1 | subject:rater).
# The rater main effect becomes the bias-corrected finite-population theta^2_r
# (McGraw & Wong Case 3A, shared theta2r_fixed()); the estimand map and occasion
# divisor are unchanged from the random path. Oracles O-FRep (#1): exact balanced
# fixed == random (the M10 single-level crossed identity), consistency == random,
# reduction to the single-occasion fixed fit via cell-mean aggregation, glmmTMB ==
# lme4 cross-engine, the balanced fixed ANOVA mean squares, and seeded recovery.

test_that("O-FRep: balanced fixed == random replicate coefficients (theta2r=sigma2r)", {
  skip_if_not_installed("glmmTMB")
  ns <- 20
  nr <- 4
  no <- 3
  d <- sim_replicates(ns, nr, no, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  args <- list(
    d,
    quote(score),
    quote(subject),
    quote(rater),
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  xr <- do.call(icc, args)
  xf <- suppressWarnings(do.call(icc, c(args, raters = "fixed")))

  # theta^2_r (rater slot) equals the random sigma^2_r on balanced data; the other
  # components are the balanced fixed==random REML identity.
  expect_equal(xf$components$rater, xr$components$rater, tolerance = 1e-4)
  expect_equal(xf$components$subject, xr$components$subject, tolerance = 1e-4)
  expect_equal(
    xf$components$subject_rater,
    xr$components$subject_rater,
    tolerance = 1e-4
  )
  expect_equal(xf$components$residual, xr$components$residual, tolerance = 1e-4)

  # Every agreement coefficient (single/average rater x single/average occasion)
  # matches the random-rater fit exactly (up to optimizer tolerance).
  expect_identical(
    paste(xf$estimates$index, xf$estimates$occasions),
    paste(xr$estimates$index, xr$estimates$occasions)
  )
  expect_equal(xf$estimates$estimate, xr$estimates$estimate, tolerance = 1e-4)
})

test_that("O-FRep: fixed consistency == random consistency exactly", {
  skip_if_not_installed("glmmTMB")
  d <- sim_replicates(20, 4, 3, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  cr <- icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  cf <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    type = "consistency",
    raters = "fixed",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  ))
  # Consistency drops the rater slot, so raters = "fixed"/"random" differ only via
  # the (balanced-identical) subject/interaction/error components.
  expect_equal(cf$estimates$estimate, cr$estimates$estimate, tolerance = 1e-6)
})

test_that("O-FRep: theta2r reduces to the single-occasion fixed fit (cell means)", {
  skip_if_not_installed("glmmTMB")
  no <- 3
  d <- sim_replicates(20, 4, no, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  xf <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    seed = 1
  ))

  # Aggregating replicates to cell means gives the single-occasion two-way fixed fit
  # (M3/M10). The rater means -- hence theta^2_r -- and the subject variance are
  # unchanged; the cell-mean residual is the interaction plus averaged pure error.
  agg <- stats::aggregate(score ~ subject + rater, data = d, FUN = mean)
  xa <- suppressWarnings(icc(
    agg,
    score,
    subject,
    rater,
    raters = "fixed",
    seed = 1
  ))
  expect_equal(xf$components$rater, xa$components$rater, tolerance = 1e-4)
  expect_equal(xf$components$subject, xa$components$subject, tolerance = 1e-4)
  expect_equal(
    xa$components$residual,
    xf$components$subject_rater + xf$components$residual / no,
    tolerance = 1e-4
  )
})

test_that("O-FRep: balanced fixed replicate == two-way-with-replication ANOVA", {
  skip_if_not_installed("glmmTMB")
  ns <- 20
  nr <- 4
  no <- 3
  d <- sim_replicates(ns, nr, no, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  xf <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  ))
  cmp <- anova_components(d, no, ns, nr)
  vs <- cmp[["subject"]]
  # On balanced data the finite-population theta^2_r equals the ANOVA rater
  # component (MS_r - MS_sr)/(no*ns), the independent method-of-moments value.
  vr <- cmp[["rater"]]
  vsr <- cmp[["subject_rater"]]
  ve <- cmp[["residual"]]
  expect_equal(xf$components$rater, vr, tolerance = 1e-4)
  expect_equal(
    pick_occ(xf, "ICC(A,k)", no),
    vs / (vs + (vr + vsr) / nr + ve / (nr * no)),
    tolerance = 1e-4
  )
})

test_that("O-FRep: fixed replicate glmmTMB == lme4 cross-engine", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  d <- sim_replicates(20, 4, 3, 1.2, 0.7, 0.4, 0.5, seed = 20260708)
  args <- list(
    d,
    quote(score),
    quote(subject),
    quote(rater),
    raters = "fixed",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  )
  g <- suppressWarnings(do.call(icc, args))
  l <- suppressWarnings(do.call(icc, c(args, engine = "lme4")))
  expect_equal(g$components$rater, l$components$rater, tolerance = 1e-4)
  expect_equal(g$estimates$estimate, l$estimates$estimate, tolerance = 1e-4)
})

test_that("O-FRep: fixed replicate SF labels and seeded recovery", {
  skip_if_not_installed("glmmTMB")
  vs <- 1.2
  vr <- 0.7
  vsr <- 0.4
  ve <- 0.5
  nr <- 5
  no <- 4
  d <- sim_replicates(40, nr, no, vs, vr, vsr, ve, seed = 424242)

  # Agreement: no Shrout & Fleiss form for fixed raters (McGraw & Wong extension).
  a <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    unit = c("single", "average"),
    seed = 1
  ))
  expect_true(all(is.na(a$estimates$sf_index)))

  # Consistency: SF ICC(3,.) at a single occasion; averaged occasions have no SF form.
  cc <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    type = "consistency",
    unit = c("single", "average"),
    occasions = c("single", "average"),
    seed = 1
  ))
  single <- cc$estimates[cc$estimates$occasions == 1, ]
  averaged <- cc$estimates[cc$estimates$occasions == no, ]
  expect_setequal(single$sf_index, c("ICC(3,1)", "ICC(3,k)"))
  expect_true(all(is.na(averaged$sf_index)))

  # Seeded recovery of theta^2_r (finite-population; near sigma^2_r here) and the
  # population single-rating agreement ICC, covered by the Monte-Carlo interval.
  expect_lt(abs(a$components$rater - vr), 0.4)
  pop_a1 <- vs / (vs + vr + vsr + ve)
  row <- a$estimates[a$estimates$index == "ICC(A,1)", ]
  expect_lt(abs(row$estimate - pop_a1), 0.1)
  expect_true(row$conf.low <= pop_a1 && pop_a1 <= row$conf.high)
})

test_that("O-FRep: both ci_methods work for fixed replicated designs", {
  skip_if_not_installed("glmmTMB")
  d <- sim_replicates(15, 4, 2, 1.2, 0.7, 0.4, 0.5, seed = 7)
  b <- suppressWarnings(icc(
    d,
    score,
    subject,
    rater,
    raters = "fixed",
    ci_method = "bootstrap",
    boot_samples = 50,
    occasions = c("single", "average"),
    seed = 1
  ))
  expect_true(all(b$estimates$conf.low <= b$estimates$estimate))
  expect_true(all(b$estimates$estimate <= b$estimates$conf.high))
  expect_identical(b$ci$method, "bootstrap")
})

# Ragged / incomplete within-cell replicates (M20 Slice 3, ADR-030) --------------
#
# The replicate analogue of M3: two-way random, single-level data with unequal
# per-cell rating counts and/or missing cells. The SINGLE-OCCASION ICC family ships
# (the shipped interaction fit tolerates ragged data, the rater divisor is the
# harmonic-mean k_eff over distinct raters per subject, and connectedness is gated).
# The occasion-AVERAGED coefficient is deferred to research: with unequal per-cell
# counts there is no single scalar effective-n_o divisor and no independent oracle to
# pin one (#1/#4). Oracles O-RagRep: a glmmTMB<->lme4 cross-engine fit and seeded
# population recovery with Monte-Carlo coverage.

# Ragged replicate generator. `incomplete = TRUE` also drops whole cells (missing
# subject x rater combinations), otherwise crossing is complete with unequal counts.
sim_ragged_rep <- function(ns, nr, vs, vr, vsr, ve, seed, incomplete = FALSE) {
  set.seed(seed)
  base <- expand.grid(subject = seq_len(ns), rater = seq_len(nr))
  cnt <- sample(1:3, nrow(base), replace = TRUE)
  if (incomplete) {
    cnt[sample(nrow(base), max(1L, floor(nrow(base) * 0.1)))] <- 0L
  }
  base <- base[cnt > 0, , drop = FALSE]
  cnt <- cnt[cnt > 0]
  rows <- base[rep(seq_len(nrow(base)), cnt), , drop = FALSE]
  s <- stats::rnorm(ns, 0, sqrt(vs))
  r <- stats::rnorm(nr, 0, sqrt(vr))
  sr <- stats::rnorm(ns * nr, 0, sqrt(vsr))
  rows$score <- 10 +
    s[rows$subject] +
    r[rows$rater] +
    sr[(rows$rater - 1) * ns + rows$subject] +
    stats::rnorm(nrow(rows), 0, sqrt(ve))
  rows$subject <- factor(rows$subject)
  rows$rater <- factor(rows$rater)
  rows
}

test_that("O-RagRep/lme4: ragged single-occasion replicates agree cross-engine", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  d <- sim_ragged_rep(20, 4, 1.2, 0.7, 0.4, 0.5, seed = 1)
  args <- list(
    d,
    quote(score),
    quote(subject),
    quote(rater),
    unit = c("single", "average"),
    seed = 1
  )
  g <- suppressMessages(do.call(icc, args))
  l <- suppressMessages(do.call(icc, c(args, engine = "lme4")))
  # A ragged design is reported as incomplete; the interaction is still surfaced.
  expect_false(g$design$balanced)
  expect_false(is.null(g$components$subject_rater))
  expect_equal(unlist(g$components), unlist(l$components), tolerance = 1e-3)
  expect_equal(g$estimates$estimate, l$estimates$estimate, tolerance = 1e-3)
  # ICC(A,1) is the reliability of one rating computed from the components.
  vc <- g$components
  expect_equal(
    pick_occ(g, "ICC(A,1)", 1),
    vc$subject / (vc$subject + vc$rater + vc$subject_rater + vc$residual),
    tolerance = 1e-6
  )
})

test_that("O-RagRep: complete-crossing ragged counts keep k_eff = n_raters", {
  skip_if_not_installed("glmmTMB")
  # Unequal replicate counts but every cell present: every subject still sees all
  # raters, so the ICC(*,k) divisor is the full rater count (k_eff over DISTINCT
  # raters, not inflated by replicates -- M17 §4).
  d <- sim_ragged_rep(15, 4, 1.2, 0.7, 0.4, 0.5, seed = 3)
  x <- suppressMessages(icc(
    d,
    score,
    subject,
    rater,
    unit = "average",
    seed = 1
  ))
  vc <- x$components
  ak <- vc$subject /
    (vc$subject + (vc$rater + vc$subject_rater + vc$residual) / 4)
  expect_equal(pick_occ(x, "ICC(A,k)", 1), ak, tolerance = 1e-6)
})

test_that("O-RagRep: incomplete crossing with replicates fits at the subject level", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("merDeriv")
  d <- sim_ragged_rep(24, 4, 1.2, 0.7, 0.4, 0.5, seed = 5, incomplete = TRUE)
  g <- suppressMessages(icc(d, score, subject, rater, seed = 1))
  l <- suppressMessages(icc(
    d,
    score,
    subject,
    rater,
    engine = "lme4",
    seed = 1
  ))
  expect_false(g$design$balanced)
  a1 <- pick_occ(g, "ICC(A,1)", 1)
  expect_true(a1 >= 0 && a1 <= 1)
  expect_equal(a1, pick_occ(l, "ICC(A,1)", 1), tolerance = 1e-3)
})

test_that("O-RagRep/sim: known ragged replicate components recovered and covered", {
  skip_if_not_installed("glmmTMB")
  vs <- 1.2
  vr <- 0.7
  vsr <- 0.4
  ve <- 0.5
  d <- sim_ragged_rep(50, 5, vs, vr, vsr, ve, seed = 20260708)
  x <- suppressMessages(icc(d, score, subject, rater, seed = 20260708))
  expect_lt(abs(x$components$residual - ve), 0.1)
  pop_a1 <- vs / (vs + vr + vsr + ve)
  row <- x$estimates[x$estimates$index == "ICC(A,1)", ]
  expect_lt(abs(row$estimate - pop_a1), 0.12)
  expect_true(row$conf.low <= pop_a1 && pop_a1 <= row$conf.high)
})

test_that("O-RagRep: ragged replicate scope guards fail loudly (#5, #8)", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ragged_rep(20, 4, 1.2, 0.7, 0.4, 0.5, seed = 1)
  # Occasion averaging on ragged data is deferred to research (no validated divisor).
  expect_error(
    icc(d, score, subject, rater, occasions = "average"),
    class = "intraclass_unsupported"
  )
  # Ragged x fixed replicates are a deferred compound corner.
  expect_error(
    suppressWarnings(icc(d, score, subject, rater, raters = "fixed")),
    class = "intraclass_unsupported"
  )
})

test_that("O-RagRep: both ci_methods work for ragged single-occasion replicates", {
  skip_if_not_installed("glmmTMB")
  d <- sim_ragged_rep(18, 4, 1.2, 0.7, 0.4, 0.5, seed = 2)
  b <- suppressMessages(icc(
    d,
    score,
    subject,
    rater,
    ci_method = "bootstrap",
    boot_samples = 40,
    seed = 1
  ))
  expect_true(all(b$estimates$conf.low <= b$estimates$estimate))
  expect_true(all(b$estimates$estimate <= b$estimates$conf.high))
  expect_identical(b$ci$method, "bootstrap")
})

test_that("a non-finite parameter covariance fails loudly, not via eigen (#5/#8)", {
  # A degenerate/over-parameterized fit (e.g. a ragged replicate design with too few
  # replicated cells to identify the interaction) can hand the Monte-Carlo sampler a
  # covariance with Inf/NaN entries. `eigen()` would crash with an unclassed error, so
  # rmvn() must abort with a classed intraclass_singular_fit instead. Tested directly
  # on the sampler (glmmTMB convergence on such designs is environment-dependent, so a
  # data-driven trigger would be flaky).
  cov_inf <- matrix(c(1, 0, 0, Inf), 2, 2)
  expect_error(
    intraclass:::rmvn(10, c(0, 0), cov_inf),
    class = "intraclass_singular_fit"
  )
  cov_na <- matrix(c(1, NA, NA, 1), 2, 2)
  expect_error(
    intraclass:::rmvn(10, c(0, 0), cov_na),
    class = "intraclass_singular_fit"
  )
})
