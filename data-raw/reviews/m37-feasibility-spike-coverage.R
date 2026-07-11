# M37 Slice 1 feasibility spike (COVERAGE): fixed-rater CLUSTER-level ICC, crossed
# Design 1, balanced/complete. Companion to m37-feasibility-spike-point.R.
#
# The point spike settled the estimand question -> OUTCOME A: the fixed cluster-level
# ICC sigma^2_c / (sigma^2_c + theta^2_r + sigma^2_cr) reduces to the M5 random
# cluster-level ICC on balanced data (theta^2_r == sigma^2_r AND s2cr unbiased under
# fixing, both |d| ~ 1e-7) and recovers the non-circular finite-population truth
# (unbiased at C_n=80). This script confirms the boundary-aware MC INTERVAL (#3)
# covers that truth interior AND at the boundary sigma^2_c = 0 (where the point is
# floored positive), reusing the SHIPPED fixed-rater sampler (mc_components ->
# to_components, the M10/M28 2b moment-corrected rater draws). n_rep >= 240
# ([[ragged-coverage-nrep-240]]).

suppressMessages({
  library(glmmTMB)
  devtools::load_all(".", quiet = TRUE)
})

theta2_true <- function(rho) sum((rho - mean(rho))^2) / (length(rho) - 1)

cluster_truth <- function(s2c, rho, s2cr, k) {
  th <- theta2_true(rho)
  c(
    A1 = s2c / (s2c + th + s2cr),
    Ak = s2c / (s2c + (th + s2cr) / k),
    C1 = s2c / (s2c + s2cr),
    Ck = s2c / (s2c + s2cr / k)
  )
}

sim_df <- function(seed, Nc, ns, rho, s2c, s2s, s2cr, s2e) {
  set.seed(seed)
  k <- length(rho)
  cl <- gl(Nc, ns * k, labels = paste0("c", seq_len(Nc)))
  sub <- factor(rep(rep(seq_len(ns), each = k), times = Nc))
  rat <- factor(rep(seq_len(k), times = Nc * ns), labels = paste0("r", seq_len(k)))
  c_eff <- rnorm(Nc, 0, sqrt(s2c))[as.integer(cl)]
  s_eff <- rnorm(Nc * ns, 0, sqrt(s2s))[as.integer(interaction(cl, sub, drop = TRUE))]
  cr_eff <- rnorm(Nc * k, 0, sqrt(s2cr))[as.integer(interaction(cl, rat, drop = TRUE))]
  y <- 10 + c_eff + s_eff + rho[as.integer(rat)] + cr_eff + rnorm(Nc * ns * k, 0, sqrt(s2e))
  data.frame(subject = sub, rater = rat, cluster = cl, score = y)
}

# per-draw cluster-level ICCs from the shipped component DRAWS (to_components output).
cluster_icc_draws <- function(cd, k) {
  s2c <- cd$cluster
  rater <- cd$rater
  s2cr <- cd$cluster_rater
  list(
    A1 = s2c / (s2c + rater + s2cr),
    Ak = s2c / (s2c + (rater + s2cr) / k),
    C1 = s2c / (s2c + s2cr),
    Ck = s2c / (s2c + s2cr / k)
  )
}

covered <- function(vals, tru, conf = 0.95) {
  a <- 1 - conf
  q <- stats::quantile(vals[is.finite(vals)], c(a / 2, 1 - a / 2), names = FALSE)
  tru >= q[[1]] && tru <= q[[2]]
}

run_regime <- function(label, n_rep, Nc, ns, rho, s2c, s2s, s2cr, s2e, seed0, mc = 4000L) {
  k <- length(rho)
  tru <- cluster_truth(s2c, rho, s2cr, k)
  hit <- matrix(0L, nrow = 0, ncol = 4, dimnames = list(NULL, c("A1", "Ak", "C1", "Ck")))
  for (i in seq_len(n_rep)) {
    df <- sim_df(seed0 + i, Nc, ns, rho, s2c, s2s, s2cr, s2e)
    ff <- tryCatch(fit_glmmtmb_multilevel_fixed(df), error = function(e) NULL)
    if (is.null(ff)) next
    cd <- mc_components(ff, mc_samples = mc, seed = seed0 + i)
    d <- cluster_icc_draws(cd, k)
    hit <- rbind(hit, c(
      A1 = covered(d$A1, tru[["A1"]]),
      Ak = covered(d$Ak, tru[["Ak"]]),
      C1 = covered(d$C1, tru[["C1"]]),
      Ck = covered(d$Ck, tru[["Ck"]])
    ))
  }
  cov <- colMeans(hit)
  cat(sprintf(
    "[%s] Nc=%d reps=%d  truth A1=%.3f Ak=%.3f | coverage A1=%.3f Ak=%.3f C1=%.3f Ck=%.3f\n",
    label, Nc, nrow(hit), tru[["A1"]], tru[["Ak"]], cov[["A1"]], cov[["Ak"]], cov[["C1"]], cov[["Ck"]]
  ))
  invisible(cov)
}

rho4 <- c(-0.8, -0.2, 0.3, 0.7)
cat("=== M37 coverage spike: fixed-rater cluster-level MC interval (95%) ===\n")
run_regime("interior C_n=20", 240, Nc = 20, ns = 6, rho4, s2c = 0.60, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37500)
run_regime("interior C_n=80", 240, Nc = 80, ns = 6, rho4, s2c = 0.60, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37600)
run_regime("boundary  C_n=80", 240, Nc = 80, ns = 6, rho4, s2c = 0.00, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37700)

# RESULT: interior C_n=20 0.992 (conservative, wide few-cluster intervals); interior
# C_n=80 0.963 (nominal); boundary sigma^2_c=0 0.550. The boundary value is NOT an M37
# defect -- m37-feasibility-spike-boundary-parity.R shows the shipped M5 RANDOM
# cluster-level interval gives the IDENTICAL 0.550 on the same data (M37 reduces to M5
# exactly). It is the pre-existing cluster-signal-at-zero coverage loss (ratio floored
# at 0, no moment correction for the SIGNAL variance) shared by M5/M9/M37. M37 ships at
# exact parity with M5; the boundary claim is PARITY (fixed == random), not "nominal".
cat("\n=== Outcome A: interior nominal; sigma^2_c=0 boundary == M5 (parity, not a defect) ===\n")
