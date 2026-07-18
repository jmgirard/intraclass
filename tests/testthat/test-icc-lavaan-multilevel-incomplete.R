# Oracle O-SEM-ML-INC: multilevel SEM (lavaan) on incomplete / unbalanced random
# crossed (Design 1) data, M58 -------------------------------------------------
#
# Extends the M54 crossed random-rater two-level CFA (D-005; the estimation-route
# parameterization of ten Hove, Jorgensen & van der Ark 2022 established by the
# committed pilot, cairn/references/sem-multilevel-pilot.md) to:
#   * INCOMPLETE subject x rater cells via two-level FIML (`missing = "fiml"`) --
#     the two-level analog of the single-level FIML path (M21);
#   * UNEQUAL cluster sizes (native to lavaan two-level).
# Oracle: the independent glmmTMB mixed-model engine (REML), on the SAME data, is
# the numeric reference (>= 2 independent estimation routes -- SEM vs GLMM). The
# index-class split (M49) budgets the ML-vs-REML gap: consistency ICCs are ratios
# and near-exact; agreement ICCs carry the small-sample tau^2 + ML-N-divisor
# terms. The tau^2 rater inflation follows the M58 HARMONIC-MEAN generalization
#   tau^2 = (sigma^2_cr + sigma^2_res / H) / N_c,  H = harmonic mean of m_c,
# pinned below as a discriminating invariant (it beats the size-weighted grand
# law). Provenance: all data seeded in-script; population + mapping trace to the
# pilot / D-005. Heavy design-time sweeps stay in the pilot; these are light live
# guards on the SHIPPED engine.

# Balanced Design-1 generator (mirrors the pilot's sim_multilevel; self-contained).
sim_ml_bal <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
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

# Unequal-cluster-size generator (per-cluster subject-count vector; complete
# crossing within each cluster). Mirrors the pilot's sim_multilevel_unequal.
sim_ml_uneq <- function(m, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  nc <- length(m)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d <- do.call(
    rbind,
    lapply(seq_len(nc), function(cc) {
      sc <- stats::rnorm(m[cc], 0, sqrt(vsc))
      ex <- expand.grid(subj = seq_len(m[cc]), rater = seq_len(k))
      ex$cluster <- cc
      ex$sc <- sc[ex$subj]
      ex
    })
  )
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

# MCAR-delete ~`frac` of the subject x rater cells, keeping every subject rated
# by >= 2 raters (connected). Seeded independently of the data draw.
punch_holes <- function(d, frac, seed) {
  set.seed(seed)
  di <- d[stats::runif(nrow(d)) >= frac, ]
  droplevels(di[
    di$subject %in% names(which(table(di$subject) >= 2)),
  ])
}

pick_ml <- function(x, index, level) {
  e <- x$estimates
  e$estimate[e$index == index & e$level == level]
}

test_that("incomplete random crossed multilevel lavaan agrees with glmmTMB (FIML)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml_bal(50, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 58201)
  di <- punch_holes(d, 0.15, seed = 58202)
  # ~15% deleted, so a strict subset of the complete grid -- genuinely incomplete.
  expect_lt(nrow(di), nrow(d))

  x_sem <- icc(
    di,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    seed = 1
  )
  x_tmb <- icc(di, score, subject, rater, cluster = cluster, seed = 1)

  # Both levels + all eight Table-3 coefficients present; MC interval (not
  # bootstrap -- resamples cannot reproduce the missingness pattern, MD-1).
  expect_setequal(unique(x_sem$estimates$level), c("subject", "cluster"))
  expect_equal(nrow(x_sem$estimates), 8L)
  expect_identical(x_sem$engine, "lavaan")
  expect_identical(x_sem$ci$method, "montecarlo")

  # The averaged-cluster ICC(c,k) uses the inverse-Simpson k_c^eff divisor
  # (M46/ADR-057) -- engine-agnostic, so identical to glmmTMB's and < k on
  # incomplete data.
  expect_equal(x_sem$k_c_eff, x_tmb$k_c_eff, tolerance = 1e-8)
  expect_true(x_sem$k_c_eff > 1 && x_sem$k_c_eff < 5)

  # Index-class split (M49): consistency ICCs near-exact; agreement carries the
  # tau^2 + ML-N-divisor terms (pilot Stage-3 budget: all ICCs |delta| <= .03).
  for (lv in c("subject", "cluster")) {
    for (idx in c("ICC(C,1)", "ICC(C,k)")) {
      expect_lt(abs(pick_ml(x_sem, idx, lv) - pick_ml(x_tmb, idx, lv)), 0.01)
    }
    for (idx in c("ICC(A,1)", "ICC(A,k)")) {
      expect_lt(abs(pick_ml(x_sem, idx, lv) - pick_ml(x_tmb, idx, lv)), 0.03)
    }
  }

  # Boundary-aware MC interval is finite and contains its point estimate.
  est <- x_sem$estimates
  expect_true(all(is.finite(c(est$conf.low, est$conf.high))))
  expect_true(all(est$conf.low <= est$estimate & est$estimate <= est$conf.high))
})

test_that("unequal cluster sizes: components track glmmTMB, MC interval ships", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # Complete crossing, unequal subjects/cluster (mild imbalance).
  d <- sim_ml_uneq(
    rep(c(6, 14), length.out = 60),
    5,
    0.4,
    1,
    0.16,
    0.16,
    0.5,
    seed = 58210
  )
  expect_gt(length(unique(as.integer(table(d$subject, d$cluster) > 0))), 0)

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

  expect_identical(x_sem$ci$method, "montecarlo") # MD-1: MC-only on unbalanced

  # Component parity: within components tight, between components within the ML
  # N-divisor gap (pilot Stage-4: < .05 relative on the cluster/subject-governed
  # components); rater carries tau^2 (SEM above REML).
  cs <- x_sem$components
  cr <- x_tmb$components
  for (comp in c("cluster", "subject", "cluster_rater", "residual")) {
    expect_lt(abs(cs[[comp]] - cr[[comp]]) / cr[[comp]], 0.05)
  }
  expect_gt(cs$rater, cr$rater) # raw SEM rater carries the tau^2 inflation

  # Consistency ICCs (ratios) near-exact across engines at both levels.
  for (lv in c("subject", "cluster")) {
    expect_lt(
      abs(pick_ml(x_sem, "ICC(C,1)", lv) - pick_ml(x_tmb, "ICC(C,1)", lv)),
      0.01
    )
  }
})

test_that("the tau^2 rater inflation follows the harmonic-mean law under imbalance", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  # Severe imbalance, k = 5, N_c = 60. The signed SEM-minus-REML rater parity IS
  # tau^2 (REML carries no inflation). Averaged over a few reps (per-dataset
  # parity is low-noise: both estimators see the same rater realization), it
  # matches the HARMONIC-mean law and STRICTLY beats the size-weighted grand law
  # -- a discriminating invariant (GP5/GP7): the law is the right one, not an
  # absorbed tolerance. The heavy 60-rep sweep lives in the pilot.
  m <- rep(c(4, 6, 20), length.out = 60)
  vcr <- 0.16
  vres <- 0.5
  nc <- length(m)
  h <- nc / sum(1 / m)
  tau2_harm <- (vcr + vres / h) / nc
  tau2_grand <- vcr * sum(m^2) / sum(m)^2 + vres / sum(m)

  parity <- vapply(
    seq_len(8),
    function(r) {
      d <- sim_ml_uneq(m, 5, 0.4, 1, 0.16, vcr, vres, seed = 58220 + r)
      cs <- icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        engine = "lavaan",
        seed = 1
      )$components
      cr <- icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        seed = 1
      )$components
      cs$rater - cr$rater
    },
    numeric(1)
  )
  mean_parity <- mean(parity)

  # (a) matches the harmonic law within a noise-margin tolerance (per-rep sd
  # ~ 3e-4; 8-rep SE ~ 1e-4; 1.5e-3 leaves cross-version/BLAS margin, M56/M60);
  expect_lt(abs(mean_parity - tau2_harm), 1.5e-3)
  # (b) STRICTLY closer to the harmonic law than to the size-weighted grand law
  # (the discriminating pin: harmonic .00396 vs grand .00485 here).
  expect_lt(abs(mean_parity - tau2_harm), abs(mean_parity - tau2_grand))
})

test_that("fixed and bootstrap-on-incomplete/unbalanced abort; connectedness gates", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml_bal(50, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 58230)
  di <- punch_holes(d, 0.15, seed = 58231)
  du <- sim_ml_uneq(
    rep(c(6, 14), length.out = 50),
    5,
    0.4,
    1,
    0.16,
    0.16,
    0.5,
    seed = 58232
  )

  # FIXED raters stay complete/balanced/equal-cluster-size only (a parked
  # candidate compounds FIML with the Case-3A correction) -- refused toward
  # glmmTMB. `suppressWarnings` mutes the fixed-rater inference-scope warning that
  # fires before the abort (repo convention).
  expect_error(
    suppressWarnings(icc(
      di,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )
  expect_error(
    suppressWarnings(icc(
      du,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )

  # Bootstrap is refused on incomplete AND unbalanced random data (MD-1): MC-only.
  expect_error(
    icc(
      di,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lavaan",
      ci_method = "bootstrap"
    ),
    class = "intraclass_unsupported"
  )
  expect_error(
    icc(
      du,
      score,
      subject,
      rater,
      cluster = cluster,
      engine = "lavaan",
      ci_method = "bootstrap"
    ),
    class = "intraclass_unsupported"
  )

  # The shared (engine-agnostic) connectedness guard still fires for lavaan: a
  # within-cluster-disconnected incomplete design is unidentified.
  dd <- d[as.integer(d$rater) != 5, ]
  dd <- dd[!(dd$subj <= 5 & as.integer(dd$rater) %in% c(3, 4)), ]
  dd <- droplevels(dd[!(dd$subj > 5 & as.integer(dd$rater) %in% c(1, 2)), ])
  expect_error(
    icc(dd, score, subject, rater, cluster = cluster, engine = "lavaan"),
    class = "intraclass_unidentified"
  )

  # Balanced/complete random KEEPS the M56 parametric bootstrap (unchanged).
  db <- sim_ml_bal(40, 10, 5, 0.4, 1, 0.16, 0.16, 0.5, seed = 58233)
  xb <- icc(
    db,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    ci_method = "bootstrap",
    seed = 1
  )
  expect_identical(xb$ci$method, "bootstrap")
})
