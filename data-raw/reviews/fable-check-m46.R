# fable-check-m46.R — Fable review checks for the M46 cluster ICC(c,k) divisor
# (brief: fable-review-m46-cluster-ck-divisor-brief.md; spike:
# m46-cluster-ck-divisor-spike.R). Seeded, deterministic, standalone-runnable.
# Results: fable-check-m46-results.rds.
#
# The spike's mc_truth draws a_c = sum_r w rr and b_c = sum_r w crv with the SAME
# cell weights that define m_c^IS, so its <0.003 agreement re-expresses the L1
# algebra (brief Q3). These checks break that circle three ways:
#
# (CHK-A) SCORE-BASED, w-FREE error measurement. On a fixed ragged design, draw
#   paired replicates of the rater-side components — fresh raters + cr + residual
#   for AGREEMENT; shared rater mains, fresh cr + residual for the component-based
#   CONSISTENCY — score every observed cell, and form each cluster's PLAIN observed
#   cell mean (mean over its cells; no weights appear anywhere in the measurement).
#   Half the mean squared replicate difference estimates the per-cluster error
#   variance; cluster/subject effects cancel exactly in the difference, and the
#   only leakage left is the uncontroversial iid-mean term vres/n_cells (cell mean)
#   or (1/m^2) sum_r vres/n_cr (rater-balanced mean), subtracted analytically.
#   Compared per cluster to L1: (vr+vcr)/m_c^IS and vcr/m_c^IS.
# (CHK-A2) The SAME draws also form each cluster's RATER-BALANCED mean (average
#   each rater's within-cluster mean, then average over the distinct raters) and
#   compare to (vr+vcr)/m_c^distinct — if both scores match their own divisor,
#   the cell-mean-vs-rater-balanced question (brief Q1) is a target CHOICE that no
#   simulation can adjudicate, and each divisor is exact for its own target.
# (CHK-A3) Score-based RELATIVE error: per replicate, the cross-cluster sample
#   variance of the (error-only) observed cell means. On ragged data with
#   heterogeneous weight profiles this exceeds the component-based consistency
#   error by ~ vr * sum_r (w_cr - wbar_r)^2 — rater mains no longer cancel in the
#   observed ordering. Compared to the exact expectation tr(H V H)/(C-1) with
#   V = vr W W' + vcr diag(sum w^2) + diag(leak). This quantifies what the
#   component-based ICC_c(C, k) does NOT describe on ragged data.
# (CHK-B) SHIP-PATH: full five-component data on the same fixed design, glmmTMB
#   five-component REML fit, plug-in Phi/rho at the inverse-Simpson harmonic
#   k_c^eff from the ESTIMATED components, vs the CHK-A empirical truth.
#
# Designs: the spike's C4 (structured MAR, heterogeneous m_c — exercises the
# harmonic aggregation) and C6 (extreme within-cluster weight imbalance — maximal
# IS-vs-distinct separation), regenerated with the spike's own seeds.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})

# ---- design generators: copied verbatim from m46-cluster-ck-divisor-spike.R so
# the same seeds reproduce the same cell patterns ----
sim_design1 <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rr[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  attr(d, "cl") <- cl
  d
}
ragged_structured <- function(d, seed) {
  set.seed(seed)
  k <- nlevels(d$rater)
  nc <- nlevels(d$cluster)
  keep_idx <- logical(nrow(d))
  for (c in seq_len(nc)) {
    mc <- sample(2:k, 1)
    rk <- sample(seq_len(k), mc)
    in_c <- d$cluster == levels(d$cluster)[c] & as.integer(d$rater) %in% rk
    idx <- which(in_c)
    drop_frac <- runif(1, 0, 0.35)
    dropped <- sample(idx, floor(drop_frac * length(idx)))
    keep_idx[setdiff(idx, dropped)] <- TRUE
  }
  keep <- d[keep_idx, , drop = FALSE]
  ok <- names(which(vapply(
    split(keep$rater, keep$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  keep[keep$cluster %in% ok, , drop = FALSE]
}
extreme_imbalance <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  d <- sim_design1(nc, ns, k, vc, vsc, vr, vcr, vres, seed)
  set.seed(seed + 1)
  keep <- logical(nrow(d))
  for (c in levels(d$cluster)) {
    in_c <- which(d$cluster == c)
    dom <- sample(seq_len(k), 1)
    for (i in in_c) {
      r <- as.integer(d$rater[i])
      if (r == dom) {
        keep[i] <- TRUE
      } else {
        keep[i] <- (d$subj[i] %% ceiling(ns / 3)) == (r %% ceiling(ns / 3))
      }
    }
  }
  kept <- d[keep, , drop = FALSE]
  ok <- names(which(vapply(
    split(kept$rater, kept$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  kept[kept$cluster %in% ok, , drop = FALSE]
}
harm <- function(x) 1 / mean(1 / x)

# ---- CHK-A / A2 / A3: score-based, w-free error measurement ----
measure_errors <- function(d, vr, vcr, vres, R = 6000, seed = 4601) {
  set.seed(seed)
  d$cluster <- droplevels(d$cluster)
  cl_ix <- as.integer(d$cluster)
  nc <- max(cl_ix)
  r_ix <- as.integer(d$rater)
  k <- nlevels(d$rater)
  n_cells <- tabulate(cl_ix, nc)
  cr_id <- (cl_ix - 1L) * k + r_ix
  n_cr <- tabulate(cr_id, nc * k)
  present_ids <- sort(unique(cr_id))
  cluster_of <- (present_ids - 1L) %/% k + 1L
  n_of <- n_cr[present_ids]
  m_dist <- tabulate(cluster_of, nc)
  # cell weights per cluster (ANALYTIC leg only; the measurement never uses these)
  W <- matrix(0, nc, k)
  W[cbind(cluster_of, ((present_ids - 1L) %% k) + 1L)] <- n_of
  W <- W / rowSums(W)
  m_is <- 1 / rowSums(W^2)
  # residual leakage of each score (iid-mean algebra, no divisor content)
  leak_cell <- vres / n_cells
  leak_bal <- as.numeric(rowsum(vres / n_of, cluster_of)) / m_dist^2

  cell_mean <- function(y) as.numeric(rowsum(y, cl_ix)) / n_cells
  bal_mean <- function(y) {
    crm <- as.numeric(rowsum(y, cr_id)) / n_of
    as.numeric(rowsum(crm, cluster_of)) / m_dist
  }
  agree_cell <- consis_cell <- agree_bal <- numeric(nc)
  relvar_score <- 0
  for (g in seq_len(R)) {
    rr1 <- stats::rnorm(k, 0, sqrt(vr))
    rr2 <- stats::rnorm(k, 0, sqrt(vr))
    cr1 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    cr2 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    cr3 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    y1 <- rr1[r_ix] +
      cr1[cbind(cl_ix, r_ix)] +
      stats::rnorm(length(cl_ix), 0, sqrt(vres))
    y2 <- rr2[r_ix] +
      cr2[cbind(cl_ix, r_ix)] +
      stats::rnorm(length(cl_ix), 0, sqrt(vres))
    y3 <- rr1[r_ix] +
      cr3[cbind(cl_ix, r_ix)] +
      stats::rnorm(length(cl_ix), 0, sqrt(vres))
    m1 <- cell_mean(y1)
    agree_cell <- agree_cell + (m1 - cell_mean(y2))^2 / 2
    consis_cell <- consis_cell + (m1 - cell_mean(y3))^2 / 2
    agree_bal <- agree_bal + (bal_mean(y1) - bal_mean(y2))^2 / 2
    relvar_score <- relvar_score + stats::var(m1)
  }
  # exact expectation of the score-based cross-cluster sample variance (CHK-A3):
  # E[var_c(m1)] = tr(HVH)/(C-1), V = vr WW' + vcr diag(sum w^2) + diag(leak)
  V <- vr * tcrossprod(W) + diag(vcr * rowSums(W^2) + leak_cell, nc)
  H <- diag(nc) - matrix(1 / nc, nc, nc)
  relvar_expect <- sum(diag(H %*% V %*% H)) / (nc - 1)
  list(
    nc = nc,
    m_is = m_is,
    m_dist = m_dist,
    k_is = harm(m_is),
    k_dist = harm(m_dist),
    meas_agree_cell = agree_cell / R - leak_cell,
    meas_consis_cell = consis_cell / R - leak_cell,
    meas_agree_bal = agree_bal / R - leak_bal,
    pred_agree_cell = (vr + vcr) / m_is,
    pred_consis_cell = vcr / m_is,
    pred_agree_bal = (vr + vcr) / m_dist,
    relvar_score_meas = relvar_score / R,
    relvar_score_expect = relvar_expect,
    # what the component-based consistency error calls the relative error:
    relvar_component = mean(vcr / m_is) + mean(leak_cell)
  )
}

report_A <- function(label, ma, vc) {
  dev <- function(meas, pred) max(abs(meas - pred) / pred)
  cat(sprintf("\n== CHK-A %s ==\n", label))
  cat(sprintf(
    "  k_IS=%.3f k_distinct=%.3f (C=%d)\n",
    ma$k_is,
    ma$k_dist,
    ma$nc
  ))
  cat(sprintf(
    "  per-cluster max rel dev, CELL mean:   agreement %.3f  consistency %.3f\n",
    dev(ma$meas_agree_cell, ma$pred_agree_cell),
    dev(ma$meas_consis_cell, ma$pred_consis_cell)
  ))
  cat(sprintf(
    "  per-cluster max rel dev, BALANCED mean: agreement %.3f  [vs (vr+vcr)/m_distinct]\n",
    dev(ma$meas_agree_bal, ma$pred_agree_bal)
  ))
  phi_emp <- vc / (vc + mean(ma$meas_agree_cell))
  rho_emp <- vc / (vc + mean(ma$meas_consis_cell))
  phi_bal <- vc / (vc + mean(ma$meas_agree_bal))
  cat(sprintf(
    "  empirical Phi(cell)=%.4f vs plug-in Phi(k_IS)=%.4f | empirical Phi(balanced)=%.4f vs Phi(k_distinct)=%.4f\n",
    phi_emp,
    vc / (vc + (0.5 + 0.3) / ma$k_is), # printed for the base components below
    phi_bal,
    vc / (vc + (0.5 + 0.3) / ma$k_dist)
  ))
  cat(sprintf(
    "  empirical rho(cell)=%.4f vs plug-in rho(k_IS)=%.4f\n",
    rho_emp,
    vc / (vc + 0.3 / ma$k_is)
  ))
  cat(sprintf(
    "  CHK-A3 score-based relative error: measured %.4f  exact-expect %.4f  component-based %.4f\n",
    ma$relvar_score_meas,
    ma$relvar_score_expect,
    ma$relvar_component
  ))
  invisible(list(phi_emp = phi_emp, rho_emp = rho_emp, phi_bal = phi_bal))
}

# ---- CHK-B: ship path — glmmTMB REML fit + plug-in at k_IS ----
rescore <- function(d, vc, vsc, vr, vcr, vres) {
  d$cluster <- droplevels(d$cluster)
  d$subject <- droplevels(d$subject)
  nc <- nlevels(d$cluster)
  k <- nlevels(d$rater)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  sc <- stats::rnorm(nlevels(d$subject), 0, sqrt(vsc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d$score <- 10 +
    cl[as.integer(d$cluster)] +
    sc[as.integer(d$subject)] +
    rr[as.integer(d$rater)] +
    crv[cbind(as.integer(d$cluster), as.integer(d$rater))] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d
}
ship_path <- function(d, vc, vsc, vr, vcr, vres, k_is, n_fit, seed) {
  set.seed(seed)
  phis <- rhos <- rep(NA_real_, n_fit)
  for (i in seq_len(n_fit)) {
    di <- rescore(d, vc, vsc, vr, vcr, vres)
    fit <- suppressWarnings(glmmTMB::glmmTMB(
      score ~ 1 +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | rater) +
        (1 | cluster:rater),
      data = di,
      REML = TRUE
    ))
    vcs <- glmmTMB::VarCorr(fit)$cond
    v <- vapply(vcs, \(x) attr(x, "stddev")^2, numeric(1))
    vch <- v[["cluster"]]
    vrh <- v[["rater"]]
    vcrh <- v[["cluster:rater"]]
    phis[i] <- vch / (vch + (vrh + vcrh) / k_is)
    rhos[i] <- vch / (vch + vcrh / k_is)
  }
  c(phi = mean(phis), rho = mean(rhos), phi_sd = sd(phis), rho_sd = sd(rhos))
}

# ---- run: base components, spike designs C4 and C6 ----
vc <- 1.0
vsc <- 0.8
vr <- 0.5
vcr <- 0.3
vres <- 0.6
cat("Components: vc=1.0 vsc=0.8 vr=0.5 vcr=0.3 vres=0.6 (spike base set)\n")

d_c4 <- ragged_structured(
  sim_design1(60, 40, 8, vc, vsc, vr, vcr, vres, 2026071204),
  21
)
d_c6 <- extreme_imbalance(60, 30, 6, vc, vsc, vr, vcr, vres, 2026071206)

ma_c4 <- measure_errors(d_c4, vr, vcr, vres, R = 6000, seed = 4604)
emp_c4 <- report_A("C4 structured MAR (heterogeneous m_c)", ma_c4, vc)
ma_c6 <- measure_errors(d_c6, vr, vcr, vres, R = 6000, seed = 4606)
emp_c6 <- report_A("C6 extreme weight imbalance", ma_c6, vc)

cat(
  "\n== CHK-B ship path (glmmTMB REML five-component fit, plug-in at k_IS) ==\n"
)
sp_c6 <- ship_path(
  d_c6,
  vc,
  vsc,
  vr,
  vcr,
  vres,
  ma_c6$k_is,
  n_fit = 120,
  seed = 606
)
cat(sprintf(
  "  C6: mean fitted Phi(k_IS)=%.4f (sd %.3f) vs empirical %.4f | rho=%.4f (sd %.3f) vs %.4f  [n_fit=120]\n",
  sp_c6["phi"],
  sp_c6["phi_sd"],
  emp_c6$phi_emp,
  sp_c6["rho"],
  sp_c6["rho_sd"],
  emp_c6$rho_emp
))
sp_c4 <- ship_path(
  d_c4,
  vc,
  vsc,
  vr,
  vcr,
  vres,
  ma_c4$k_is,
  n_fit = 50,
  seed = 604
)
cat(sprintf(
  "  C4: mean fitted Phi(k_IS)=%.4f (sd %.3f) vs empirical %.4f | rho=%.4f (sd %.3f) vs %.4f  [n_fit=50]\n",
  sp_c4["phi"],
  sp_c4["phi_sd"],
  emp_c4$phi_emp,
  sp_c4["rho"],
  sp_c4["rho_sd"],
  emp_c4$rho_emp
))

saveRDS(
  list(
    c4 = ma_c4,
    c6 = ma_c6,
    emp_c4 = emp_c4,
    emp_c6 = emp_c6,
    ship_c6 = sp_c6,
    ship_c4 = sp_c4
  ),
  file.path("data-raw", "reviews", "fable-check-m46-results.rds")
)
cat("\n[saved] data-raw/reviews/fable-check-m46-results.rds\n")
