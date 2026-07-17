# Oracle O-SEM-ML-FIXED: fixed-rater multilevel SEM (lavaan) engine, M57 --------
#
# `engine = "lavaan"` + `cluster` + `raters = "fixed"`: the SAME two-level CFA
# the random path fits (M54, D-005), read with the McGraw & Wong (1996) Case-3A
# finite-population correction on the between-level rater intercepts nu_j. The
# rater slot becomes theta^2_r = max(0, raw - bias), bias = tr(C V_nu)/(k-1) the
# identity-contrast trace of the between-intercept vcov block -- exactly the
# correction the single-level fit_lavaan() fixed path applies. Correctness rests
# on (PRINCIPLES.md #1):
#   * cross-engine agreement parity with the frequentist fixed oracles --
#     glmmTMB fixed multilevel subject (M10/ADR-019) and cluster (M37/ADR-047),
#     ten Hove et al. (2022) Eq. 7 -- within the M49/M54 index-class-split
#     agreement tolerance (asymptotic under the ML-vs-REML gap);
#   * the consistency identity: fixing omits the rater term from the error set
#     (estimand.R), so lavaan fixed consistency EQUALS lavaan random consistency
#     exactly at both levels;
#   * the finite-population law as a GP7 invariant: because lavaan's RANDOM rater
#     estimate is the raw tau^2-inflated quadratic form (ADR-014), the fixed
#     theta^2_r sits BELOW it by exactly `bias` = the tau^2 correction -- so the
#     lavaan fixed cluster ICC does NOT equal lavaan's own random cluster ICC
#     (unlike glmmTMB, whose REML random gives the M37 balanced theta^2_r==sigma^2_r
#     identity). The gap is documented, never absorbed into a widened tolerance
#     (GP5), and shrinks as N_c grows;
#   * a direct deterministic guard (hand-computed, not a coverage sim -- M51):
#     the point uses the 1b correction (raw - bias) and the per-draw push-forward
#     the 2b + average-floor correction (M28/ADR-038), via the shared
#     theta2r_moment_draws() with bias != 0.
#
# Fixed is MC-only (the M56 bootstrap factory is random-only internally; the
# fixed bootstrap is a deferred candidate). Crossed (Design 1), balanced/complete,
# equal cluster sizes only -- fixed nested / replicate / incomplete abort loudly.

# Balanced Design-1 generator with known population components (self-contained;
# mirrors data-raw/pilot-sem-multilevel.R's sim_multilevel and the M54 test).
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

test_that("O-SEM-ML-FIXED/parity: lavaan fixed matches glmmTMB fixed (agreement)", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(40, 5, 5, 1, 1.5, 0.4, 0.3, 1, seed = 42)
  lf <- suppressWarnings(icc(
    d, score, subject, rater,
    cluster = cluster, engine = "lavaan", raters = "fixed", seed = 1
  ))
  lr <- icc(
    d, score, subject, rater,
    cluster = cluster, engine = "lavaan", raters = "random", seed = 1
  )
  tf <- suppressWarnings(icc(
    d, score, subject, rater,
    cluster = cluster, engine = "glmmTMB", raters = "fixed", seed = 1
  ))

  # Eight Table-3 coefficients at both levels, engine tag intact.
  expect_setequal(unique(lf$estimates$level), c("subject", "cluster"))
  expect_equal(nrow(lf$estimates), 8L)
  expect_identical(lf$engine, "lavaan")

  # AC1/AC2 agreement: the fixed rater term counts as error, so agreement ICCs
  # carry theta^2_r; lavaan fixed agrees with glmmTMB fixed at BOTH levels within
  # the index-class-split agreement tolerance (asymptotic ML-vs-REML gap, M54).
  for (lv in c("subject", "cluster")) {
    for (idx in c("ICC(A,1)", "ICC(A,k)")) {
      expect_lt(abs(pick_ml(lf, idx, lv) - pick_ml(tf, idx, lv)), 0.01)
    }
  }

  # AC1/AC2 consistency identity: consistency drops the rater term, so lavaan
  # FIXED consistency equals lavaan RANDOM consistency EXACTLY at both levels
  # (same fit, rater omitted) -- the "identical to the random-rater case" claim.
  for (lv in c("subject", "cluster")) {
    for (idx in c("ICC(C,1)", "ICC(C,k)")) {
      expect_equal(pick_ml(lf, idx, lv), pick_ml(lr, idx, lv))
    }
  }

  # AC2 finite-population gap: at the cluster level (agreement counts the rater
  # term) lavaan fixed does NOT equal lavaan random -- fixing removes the tau^2
  # inflation, so fixed agreement sits ABOVE random agreement (less error), a
  # strictly positive, documented gap (GP5). glmmTMB shows no such gap (M37).
  expect_gt(
    pick_ml(lf, "ICC(A,1)", "cluster") - pick_ml(lr, "ICC(A,1)", "cluster"),
    0
  )
})

test_that("O-SEM-ML-FIXED/GP7: point uses 1b, draws use 2b + floor; gap == bias", {
  skip_on_cran()
  skip_if_not_installed("lavaan")

  # Direct deterministic guard on the fit function (M51: hand-computed, not a
  # coverage sim). Inputs chosen so the correct value differs NUMERICALLY from
  # each plausible simplification: bias > 0 (crossed, but the between rater means
  # are estimated over only N_c clusters, so bias is non-trivial), which
  # discriminates 1b/2b (differ by bias) and bias/no-bias (differ by bias).
  d <- sim_ml(40, 5, 5, 1, 1.5, 0.4, 0.3, 1, seed = 42)
  res <- fit_lavaan_multilevel(d, raters = "fixed")
  rnd <- fit_lavaan_multilevel(d, raters = "random")

  co <- lavaan::coef(res$fit)
  vc <- as.matrix(lavaan::vcov(res$fit))
  cn <- names(co)
  k <- 5L
  nu_i <- which(grepl("~1\\.l2$", cn))
  nu <- unname(co[nu_i])
  center <- diag(k) - matrix(1 / k, k, k)
  raw <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)
  bias <- sum(diag(center %*% vc[nu_i, nu_i, drop = FALSE])) / (k - 1)

  # The correction is a real, positive de-bias (not a no-op).
  expect_gt(bias, 0)

  # AC3: the POINT rater slot is the 1b Case-3A correction max(0, raw - bias).
  expect_equal(res$components$rater, max(0, raw - bias))

  # AC2/AC3 deterministic gap: lavaan RANDOM reports the raw tau^2-inflated
  # sigma^2_r; the fixed theta^2_r sits below it by EXACTLY `bias` (same fit).
  expect_equal(rnd$components$rater - res$components$rater, bias)

  # AC3: the per-draw push-forward uses the 2b correction (one b undoes the
  # Gaussian push-forward, one removes the plug-in bias). Evaluated at the point
  # mean the single draw is max(0, raw - 2*bias), NOT the 1b point -- this fails
  # if the draw path were 1b or fed bias = 0.
  draw_at_point <- res$to_components(as.matrix(res$estimate))$rater
  expect_equal(unname(draw_at_point), max(0, raw - 2 * bias))

  # AC3: reach-zero flooring (#3, D-004). All-equal drawn intercepts -> centred
  # to 0 -> raw draw 0 -> 0 - 2*bias < 0 -> floored to EXACTLY 0.
  par_flat <- res$estimate
  par_flat[paste0("nu", seq_len(k))] <- 5
  draw_flat <- res$to_components(as.matrix(par_flat))$rater
  expect_equal(unname(draw_flat), 0)
})

test_that("O-SEM-ML-FIXED: fixed lavaan aborts on nested / replicate / incomplete", {
  skip_on_cran()
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lavaan")

  d <- sim_ml(12, 6, 4, 0.4, 1, 0.16, 0.16, 0.5, seed = 20260717)

  # AC4: fixed NESTED -- the crossed-only two-level CFA guard fires first.
  dn <- d
  dn$rater <- factor(paste(dn$cluster, dn$rater, sep = "_"))
  expect_error(
    suppressWarnings(icc(
      dn, score, subject, rater,
      cluster = cluster,
      design = "nested_in_clusters", raters = "fixed", engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )

  # AC4: fixed WITHIN-CELL REPLICATES -- no SEM replicate parameterization.
  dr <- rbind(d, d)
  expect_error(
    suppressWarnings(icc(
      dr, score, subject, rater,
      cluster = cluster, raters = "fixed", engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )

  # AC4: fixed INCOMPLETE -- a missing subject x rater cell.
  di <- d[-3, ]
  expect_error(
    suppressWarnings(icc(
      di, score, subject, rater,
      cluster = cluster, raters = "fixed", engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )

  # AC4: fixed UNBALANCED -- complete grid, unequal subjects per cluster.
  du <- d[!(d$cluster == "1" & d$subj > 3), ]
  expect_error(
    suppressWarnings(icc(
      du, score, subject, rater,
      cluster = cluster, raters = "fixed", engine = "lavaan"
    )),
    class = "intraclass_unsupported"
  )
})
