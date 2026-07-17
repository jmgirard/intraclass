# Oracle O-SEM-ML: multilevel SEM (lavaan) engine, M54 -------------------------
#
# `engine = "lavaan"` + `cluster`: the two-level CFA parameterization of the
# ten Hove, Jorgensen & van der Ark (2022) Design-1 five-component
# decomposition -- an IP1-fenced estimation route whose faithfulness was
# established numerically by the M53 pilot (D-005;
# cairn/references/sem-multilevel-pilot.md; data-raw/pilot-sem-multilevel.R,
# checkpoint committed). Correctness rests on (PRINCIPLES.md #1):
#   * glmmTMB REML cross-engine parity on the pilot Stage-1 geometry --
#     consistency ICCs near-exact, agreement asymptotic (M49 index-class
#     split), component deltas within the pilot's documented ML-vs-REML +
#     tau^2 budgets;
#   * a seeded population-recovery sweep with pins split by the axis that
#     governs each component's sampling noise and sized at the noise floor
#     3*sqrt(2/df)/sqrt(n_rep) (GP5);
#   * the tau^2 rater-inflation law pinned as an invariant (GP7): the SEM
#     raw quadratic-form rater estimator carries the DETERMINISTIC inflation
#     E = sigma^2_r + tau^2, tau^2 = (sigma^2_cr + sigma^2_res/n_s)/N_c (the
#     multilevel analog of the single-level engine's omitted "-sigma^2_res/n"
#     term), so the signed SEM-minus-REML rater parity IS tau^2 -- rater pins
#     are centred on tau^2, never zero (a zero-centred pin breaks
#     structurally at small N_c, where multilevel users live);
#   * a reduction to the shipped single-level lavaan engine at
#     sigma^2_c = sigma^2_cr = 0.

# Balanced Design-1 generator with known population components (mirrors
# data-raw/pilot-sem-multilevel.R's sim_multilevel; self-contained).
sim_ml <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# Pull one coefficient out of the estimates table by index + level.
pick_ml <- function(x, index, level) {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

# REML five-component reference fit (the package's spine, via glmmTMB).
reml_components <- function(d) {
  fit <- suppressWarnings(glmmTMB::glmmTMB(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  ))
  vc <- glmmTMB::VarCorr(fit)$cond
  c(
    cluster = unname(attr(vc$cluster, "stddev"))^2,
    subject = unname(attr(vc$`cluster:subject`, "stddev"))^2,
    rater = unname(attr(vc$rater, "stddev"))^2,
    cluster_rater = unname(attr(vc$`cluster:rater`, "stddev"))^2,
    residual = attr(vc, "sc")^2
  )
}

test_that("O-SEM-ML/parity: lavaan matches glmmTMB REML on the pilot geometry", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # The pilot's Stage-1 dataset (same population + seed), so the deltas below
  # trace to the committed pilot evidence.
  d <- sim_ml(40, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260716)
  x_sem <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    seed = 1
  )
  x_tmb <- icc(d, score, subject, rater, cluster = cluster, seed = 1)

  # All eight Table-3 coefficients present at both levels.
  expect_setequal(unique(x_sem$estimates$level), c("subject", "cluster"))
  expect_equal(nrow(x_sem$estimates), 8L)
  expect_identical(x_sem$engine, "lavaan")

  # Index-class split (M49): consistency ICCs are ratios that absorb the ML
  # N-divisor, near-exact (pilot: identical to 4 dp); agreement carries the
  # small-sample tau^2 + ML-vs-REML terms (pilot: |delta| <= .008 here).
  for (lv in c("subject", "cluster")) {
    for (idx in c("ICC(C,1)", "ICC(C,k)")) {
      expect_lt(abs(pick_ml(x_sem, idx, lv) - pick_ml(x_tmb, idx, lv)), 1e-3)
    }
    for (idx in c("ICC(A,1)", "ICC(A,k)")) {
      expect_lt(abs(pick_ml(x_sem, idx, lv) - pick_ml(x_tmb, idx, lv)), 0.01)
    }
  }

  # Component parity within the pilot's Stage-1 budgets: within components
  # tight (< .02 rel); between components carry the ML N-divisor (< .06 rel);
  # rater carries tau^2 (< .05 abs).
  cs <- x_sem$components
  cr <- reml_components(d)
  expect_lt(abs(cs$subject - cr["subject"]) / cr["subject"], 0.02)
  expect_lt(abs(cs$residual - cr["residual"]) / cr["residual"], 0.02)
  expect_lt(abs(cs$cluster - cr["cluster"]) / cr["cluster"], 0.06)
  expect_lt(
    abs(cs$cluster_rater - cr["cluster_rater"]) / cr["cluster_rater"],
    0.06
  )
  expect_lt(abs(cs$rater - cr["rater"]), 0.05)
})

test_that("O-SEM-ML/reduction: zero cluster variances reduce to the single-level engine", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # sigma^2_c = sigma^2_cr = 0 (the pilot's Stage-1b population): the
  # two-level subject-level ICCs must match the shipped single-level lavaan
  # engine on the same ratings, ignoring cluster (pilot pin: < .02). The seed
  # is chosen so the between-level ML draw stays positive -- at a TRUE zero,
  # lavaan lands on a negative (Heywood) between variance about half the time
  # and the engine then aborts BY DESIGN (D-004; the Heywood test below pins
  # that posture on this same population). `level = "subject"` keeps the
  # near-boundary cluster-level draws out of the MC composition.
  d0 <- sim_ml(50, 8, 4, 0, 1, 0.2, 0, 0.6, seed = 20260724)
  x_ml <- icc(
    d0,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    engine = "lavaan",
    seed = 1
  )
  x_sl <- icc(d0, score, subject, rater, engine = "lavaan", seed = 1)
  sl <- x_sl$estimates

  expect_lt(
    abs(
      pick_ml(x_ml, "ICC(A,1)", "subject") -
        sl$estimate[sl$index == "ICC(A,1)"]
    ),
    0.02
  )
  expect_lt(
    abs(
      pick_ml(x_ml, "ICC(C,1)", "subject") -
        sl$estimate[sl$index == "ICC(C,1)"]
    ),
    0.02
  )
})

test_that("O-SEM-ML/conflated: the Eq. 14 diagnostic composes off the lavaan fit", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(40, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260716)
  x_sem <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    engine = "lavaan",
    seed = 1
  )
  x_tmb <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "conflated",
    seed = 1
  )
  e_sem <- x_sem$estimates
  e_tmb <- x_tmb$estimates
  expect_true(all(e_sem$level == "conflated"))
  expect_equal(nrow(e_sem), 4L)
  # The conflated collapse mixes within (near-exact) and between (ML-shrunk +
  # tau^2) components; sized from the same Stage-1 budgets as the parity test.
  for (i in seq_len(nrow(e_sem))) {
    expect_lt(abs(e_sem$estimate[i] - e_tmb$estimate[i]), 0.01)
  }
})

test_that("O-SEM-ML/recovery: known-population recovery, pins split by governing axis", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")
  skip_on_cran()

  pop <- c(vc = 0.4, vsc = 1, vr = 0.16, vcr = 0.16, vres = 0.5)

  # Cell B (pilot geometry): N_c = 40, n_s = 10, k = 5 -- pins the four
  # cluster/subject-governed components on the cluster axis. n_rep = 60 sets
  # the cluster-component noise floor at 3*sqrt(2/39)/sqrt(60) ~= .088 < .10.
  n_rep_b <- 60L
  comp_b <- matrix(NA_real_, n_rep_b, 5)
  colnames(comp_b) <- c(
    "cluster",
    "subject",
    "rater",
    "cluster_rater",
    "residual"
  )
  for (r in seq_len(n_rep_b)) {
    d <- sim_ml(
      40,
      10,
      5,
      pop["vc"],
      pop["vsc"],
      pop["vr"],
      pop["vcr"],
      pop["vres"],
      seed = 54000 + r
    )
    fit <- icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lavaan",
      # mc_samples floor: the point components are all this cell asserts.
      mc_samples = 500L,
      seed = 1
    )
    comp_b[r, ] <- unlist(fit$components)[colnames(comp_b)]
  }
  rel_bias_b <- colMeans(comp_b) /
    c(pop["vc"], pop["vsc"], pop["vr"], pop["vcr"], pop["vres"]) -
    1
  for (nm in c("cluster", "subject", "cluster_rater", "residual")) {
    expect_lt(abs(rel_bias_b[[nm]]), 0.10)
  }

  # Cell D (the tight-k cell): N_c = 30, n_s = 8, k = 25 -- the ONLY cell that
  # can pin sigma^2_r tightly (its noise is governed by df = k - 1, not N_c).
  # Pins: (a) rel bias centred on the predicted structural inflation
  # tau^2/sigma^2_r at the k-axis noise floor 3*sqrt(2/24)/sqrt(n_rep); (b) the
  # tau^2 law itself as an invariant (GP7, D-005 / sem-multilevel-pilot):
  # signed mean SEM-minus-REML rater parity within .005 of predicted tau^2
  # (differencing on the SAME data cancels the shared sampling noise, so ~20
  # parity reps resolve it; pilot: match <= 1e-4 at n_parity = 25).
  n_rep_d <- 40L
  n_parity <- 20L
  rater_d <- numeric(n_rep_d)
  parity_d <- numeric(n_parity)
  for (r in seq_len(n_rep_d)) {
    d <- sim_ml(
      30,
      8,
      25,
      pop["vc"],
      pop["vsc"],
      pop["vr"],
      pop["vcr"],
      pop["vres"],
      seed = 55000 + r
    )
    fit <- icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lavaan",
      mc_samples = 500L,
      seed = 1
    )
    rater_d[r] <- fit$components$rater
    if (r <= n_parity) {
      parity_d[r] <- fit$components$rater - reml_components(d)[["rater"]]
    }
  }
  tau2_d <- unname((pop["vcr"] + pop["vres"] / 8) / 30)
  infl_d <- tau2_d / unname(pop["vr"])
  tol_d <- 3 * sqrt(2 / 24) / sqrt(n_rep_d)
  expect_lt(abs(mean(rater_d) / pop[["vr"]] - 1 - infl_d), tol_d)
  # GP7 invariant: the tau^2 law (source comment in R/engine-lavaan.R cites
  # D-005 + the pilot ledger).
  expect_lt(abs(mean(parity_d) - tau2_d), 0.005)
})

test_that("O-SEM-ML/mc: montecarlo intervals at both levels are finite, bracketing, and parity-close", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(40, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260716)
  x_sem <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    seed = 7
  )
  x_tmb <- icc(d, score, subject, rater, cluster = cluster, seed = 7)
  e_sem <- x_sem$estimates
  e_tmb <- x_tmb$estimates

  # Boundary-aware feasibility (#3): finite endpoints in [0, 1] bracketing the
  # point estimate, at BOTH levels (the pilot's MC probe, now on the shipped
  # path).
  expect_true(all(is.finite(e_sem$conf.low) & is.finite(e_sem$conf.high)))
  expect_true(all(e_sem$conf.low >= 0 & e_sem$conf.high <= 1))
  expect_true(all(
    e_sem$conf.low <= e_sem$estimate & e_sem$estimate <= e_sem$conf.high
  ))

  # Endpoint parity vs the glmmTMB montecarlo interval on the same data and
  # seed (index-class split, M49): both engines feed the SAME mc machinery, so
  # endpoint deltas carry only the estimate/vcov differences. Pins sized from
  # a documented calibration run at this geometry (M54 T4): consistency
  # endpoints agree to <= .0033 (pin .01); agreement endpoints inherit the
  # ESTABLISHED single-level engine difference -- sigma^2_r enters the draws
  # as a quadratic form of k normals (df = k - 1), whose right tail is heavier
  # than glmmTMB's log-normal rater draw, pushing the agreement LOWER endpoint
  # down (observed here: lower <= .095, upper <= .038; the shipped
  # single-level engine shows the same signature on comparable data, lower
  # ~ .12 -- an engine property, not an M54 artifact).
  key <- paste(e_sem$index, e_sem$level)
  stopifnot(identical(key, paste(e_tmb$index, e_tmb$level)))
  is_c <- grepl("\\(C", e_sem$index)
  expect_lt(max(abs(e_sem$conf.low - e_tmb$conf.low)[is_c]), 0.01)
  expect_lt(max(abs(e_sem$conf.high - e_tmb$conf.high)[is_c]), 0.01)
  expect_lt(max(abs(e_sem$conf.low - e_tmb$conf.low)[!is_c]), 0.15)
  expect_lt(max(abs(e_sem$conf.high - e_tmb$conf.high)[!is_c]), 0.06)

  # The same six-field contract serves d_study() reprojection unchanged
  # (both levels, MC intervals) -- smoke, not an oracle.
  expect_s3_class(d_study(x_sem, m = c(3, 8)), "icc_dstudy")
})

test_that("multilevel lavaan out-of-scope combinations abort with classed conditions", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(12, 6, 4, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260716)

  # Fixed raters: deferred to the lavaan-siblings candidate (M54 Out).
  expect_error(
    suppressWarnings(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )

  # Nested designs (2/3): the two-level CFA mapping is crossed-only (M54 Out).
  dn <- d
  dn$rater <- factor(paste(dn$cluster, dn$rater, sep = "_"))
  expect_error(
    icc(
      dn,
      score,
      subject,
      rater,
      cluster = cluster,
      design = "nested_in_clusters",
      engine = "lavaan"
    ),
    class = "intraclass_unsupported"
  )

  # Incomplete data: the pilot's oracle evidence is complete-data only.
  di <- d[-3, ]
  expect_error(
    icc(di, score, subject, rater, cluster = cluster, engine = "lavaan"),
    class = "intraclass_unsupported"
  )

  # Unbalanced cluster sizes: complete flat grid, unequal subjects/cluster --
  # outside the pilot's evidence (equal n_s enters the tau^2 law).
  du <- d[!(d$cluster == "1" & d$subj > 3), ]
  expect_error(
    icc(du, score, subject, rater, cluster = cluster, engine = "lavaan"),
    class = "intraclass_unsupported"
  )

  # Within-cell replicates: no SEM replicate parameterization (M54 Out).
  dr <- rbind(d, d)
  expect_error(
    icc(dr, score, subject, rater, cluster = cluster, engine = "lavaan"),
    class = "intraclass_unsupported"
  )
  # (The multilevel SEM bootstrap is no longer out of scope -- M56 ships it for
  # the balanced random-rater cell; see the O-SEM-ML-BOOT tests below.)
})

test_that("a between-level Heywood fit aborts toward glmmTMB (boundary reached)", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # Zero cluster AND cluster:rater population variance puts the between level
  # on the boundary; lavaan's unconstrained ML goes negative (Heywood) where
  # glmmTMB smoothly reaches ~0 (D-004: classed deferral toward the
  # boundary-robust engine). Same population as the reduction test above;
  # this seed is one where the between-level ML draw IS negative (boundary
  # REACHED, not just near -- most seeds at this population are).
  db <- sim_ml(50, 8, 4, 0, 1, 0.2, 0, 0.6, seed = 20260718)
  expect_error(
    icc(db, score, subject, rater, cluster = cluster, engine = "lavaan"),
    class = "intraclass_singular_fit"
  )
  # The fixture genuinely sits at the boundary: the boundary-robust reference
  # engine estimates (essentially) zero cluster variance on the same data.
  # `level = "subject"` keeps the boundary cluster draws out of the reference
  # MC composition (which would otherwise abort at interval time, D-004).
  x_tmb <- suppressWarnings(icc(
    db,
    score,
    subject,
    rater,
    cluster = cluster,
    level = "subject",
    seed = 1
  ))
  expect_lt(x_tmb$components$cluster, 0.01)
})

test_that("multilevel lavaan print output is stable", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(40, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260716)
  x <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    seed = 1
  )
  expect_snapshot(print(x), transform = mask_ci)
})

# O-SEM-ML-BOOT: two-level parametric bootstrap CI (M56) ------------------------
#
# `ci_method = "bootstrap"` for the shipped crossed (Design 1) random-rater
# balanced multilevel lavaan fit: simulate wide two-level datasets from the
# fit's implied within/between moments (rebuilt from the five components),
# refit the same two-level CFA per resample, recompute both-level ICCs. The
# oracle is CROSS-METHOD (PRINCIPLES.md #1/#3): the bootstrap interval must
# agree with the default Monte-Carlo interval within a documented tolerance,
# split by index class (subject tight, cluster looser -- the ML/REML +
# few-cluster width the M49/M54 split anticipates). A failed/Heywood resample
# is NA-filled and dropped by the shared bootstrap_ci() discard policy.

test_that("multilevel lavaan bootstrap agrees with the Monte-Carlo interval", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  d <- sim_ml(40, 10, 5, 0.5, 1, 0.3, 0.2, 0.5, seed = 42)
  mc <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    ci_method = "montecarlo",
    mc_samples = 4000L,
    seed = 7
  )))
  bs <- suppressWarnings(tidy(icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    ci_method = "bootstrap",
    boot_samples = 299L,
    seed = 7
  )))

  # Structural sanity at both levels: finite, estimate contained, bounded by 1.
  expect_true(all(is.finite(bs$conf.low) & is.finite(bs$conf.high)))
  expect_true(all(bs$conf.low <= bs$estimate & bs$estimate <= bs$conf.high))
  expect_true(all(bs$conf.high <= 1))

  # Cross-method endpoint agreement, split by index class (M49/M54). Subject
  # ICCs are tight; the cluster level is wider (few clusters + ML/REML) so its
  # cross-method tolerance is looser. Observed max |Delta|: subject ~.01,
  # cluster ~.016 at these settings -- the pins carry ~3x headroom for
  # cross-platform lavaan drift, still far inside a meaningful oracle.
  dlo <- abs(mc$conf.low - bs$conf.low)
  dhi <- abs(mc$conf.high - bs$conf.high)
  subj <- mc$level == "subject"
  clus <- mc$level == "cluster"
  expect_lt(max(dlo[subj], dhi[subj]), 0.04)
  expect_lt(max(dlo[clus], dhi[clus]), 0.07)
})

test_that("the two-level bootstrap refit NA-fills failed/Heywood resamples", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  # A tiny between-cluster variance with few clusters drives many refits to a
  # between-level Heywood boundary -> the refit returns the all-NA sentinel, so
  # bootstrap_ci()'s `colSums(is.na) == 0` discard test drops exactly those
  # resamples. Direct factory test (deterministic, robust across seeds; M51
  # lesson: pin the contract, not a stochastic coverage sim).
  k <- 3L
  center <- diag(k) - matrix(1 / k, k, k)
  model <- lavaan_multilevel_model(k)
  fac <- lavaan_ml_simulate_refit(
    model,
    k,
    center,
    nu = c(0, 0.3, -0.3),
    svw = 1,
    evw = 0.5,
    svb = 1e-3,
    evb = 0.05,
    cluster_sizes = rep(4L, 8L)
  )
  draws <- suppressWarnings(fac(40L, seed = 1))

  expect_equal(
    rownames(draws),
    c("cluster", "subject", "rater", "cluster_rater", "residual")
  )
  na_per_col <- colSums(is.na(draws))
  # A dropped resample is ENTIRELY NA (not partial) -- bootstrap_ci keys the
  # discard on a fully-clean column, so a partial-NA column would be a bug.
  expect_true(all(na_per_col %in% c(0L, k + 2L)))
  expect_true(any(na_per_col == 0L)) # some valid resamples survive
  expect_true(any(na_per_col > 0L)) # some fail -> discard path exercised
  ok <- draws[, na_per_col == 0L, drop = FALSE]
  expect_true(all(
    ok[c("cluster", "subject", "cluster_rater", "residual"), ] > 0
  ))
  expect_true(all(ok["rater", ] >= 0))
})

test_that("multilevel lavaan bootstrap is reproducible and RNG-hygienic", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  d <- sim_ml(30, 8, 4, 0.5, 1, 0.3, 0.2, 0.5, seed = 11)
  run <- function() {
    suppressWarnings(tidy(icc(
      d,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lavaan",
      ci_method = "bootstrap",
      boot_samples = 99L,
      seed = 7
    )))
  }

  # Same seed -> identical interval.
  a <- run()
  b <- run()
  expect_equal(a$conf.low, b$conf.low)
  expect_equal(a$conf.high, b$conf.high)

  # The global RNG stream is left untouched across the seeded call (#9/#12).
  set.seed(123)
  before <- .Random.seed
  invisible(run())
  expect_identical(before, .Random.seed)
})
