# M37 Slice 1 feasibility spike (POINT): fixed-rater CLUSTER-level ICC, crossed
# Design 1, balanced/complete. Question the spike settles (M37 spec §4a, ADR-047):
#
#   At the SUBJECT level (M10) the cluster x rater term sigma^2_cr is NOT in the error
#   set, so fixing raters was clean (theta^2_r = sigma^2_r on balanced data, so
#   fixed == random exactly). At the CLUSTER level sigma^2_cr IS the error term
#   (M5 §3b / ten Hove 2022 Eq. 13: error {rater, cluster_rater}). So: is the standard
#   RANDOM (1|cluster:rater) variance the correct FIXED-rater cluster-level interaction
#   error, or does the interaction need a finite-population treatment (as the main
#   effect does)?
#
#   Outcome A -- the provisional map sigma^2_c / (sigma^2_c + theta^2_r + sigma^2_cr)
#     reduces to the shipped M5 random cluster-level ICC on balanced data AND recovers
#     a non-circular finite-population truth. Ship with a reduction oracle, no Fable.
#   Outcome B -- reduction fails / recovery biased: sigma^2_cr needs a finite-population
#     correction. Derive it + fire the pre-authorized gated Fable review (#19).
#
# NON-CIRCULARITY (#1): the truth uses theta^2_r = the finite-population variance of the
# KNOWN fixed rater effects rho (a deterministic function of the design, NOT a sampled
# parameter); sigma^2_c and sigma^2_cr are the KNOWN generating variances. Recovery of
# that truth from the fitted components is a genuine independent oracle.
#
# Reuses the SHIPPED fit machinery (fit_glmmtmb_multilevel_fixed / _multilevel) via
# load_all -- only the cluster-level READ (arithmetic on components) is new. No shipping
# code is written in this slice.

suppressMessages({
  library(glmmTMB)
  library(lme4)
  devtools::load_all(".", quiet = TRUE)
})

# ---- finite-population truth for the k KNOWN fixed rater effects ----
# theta^2_r = var of the realized rater means, (k-1) denominator (Case 3A population).
theta2_true <- function(rho) sum((rho - mean(rho))^2) / (length(rho) - 1)

# cluster-level ICCs from a component set (agreement uses theta^2_r/sigma^2_r + cr;
# consistency uses cr only -- M5 §3b map, unchanged).
cluster_iccs <- function(s2c, rater, s2cr, k) {
  c(
    A1 = s2c / (s2c + rater + s2cr),
    Ak = s2c / (s2c + (rater + s2cr) / k),
    C1 = s2c / (s2c + s2cr),
    Ck = s2c / (s2c + s2cr / k)
  )
}

# ---- DGP: balanced crossed Design 1, raters FIXED ----
sim_one <- function(seed, Nc, ns, rho, s2c, s2s, s2cr, s2e) {
  set.seed(seed)
  k <- length(rho)
  cl <- gl(Nc, ns * k, labels = paste0("c", seq_len(Nc)))
  sub <- factor(rep(rep(seq_len(ns), each = k), times = Nc))
  rat <- factor(rep(seq_len(k), times = Nc * ns), labels = paste0("r", seq_len(k)))
  c_eff <- rnorm(Nc, 0, sqrt(s2c))[as.integer(cl)]
  s_eff <- rnorm(Nc * ns, 0, sqrt(s2s))[as.integer(interaction(cl, sub, drop = TRUE))]
  cr_eff <- rnorm(Nc * k, 0, sqrt(s2cr))[as.integer(interaction(cl, rat, drop = TRUE))]
  y <- 10 + c_eff + s_eff + rho[as.integer(rat)] + cr_eff + rnorm(Nc * ns * k, 0, sqrt(s2e))
  df <- data.frame(subject = sub, rater = rat, cluster = cl, score = y)

  ff <- tryCatch(fit_glmmtmb_multilevel_fixed(df), error = function(e) NULL)
  rf <- tryCatch(fit_glmmtmb_multilevel(df), error = function(e) NULL)
  if (is.null(ff) || is.null(rf)) {
    return(NULL)
  }
  cf <- ff$components
  cr <- rf$components

  fixed <- cluster_iccs(cf$cluster, cf$rater, cf$cluster_rater, k)
  random <- cluster_iccs(cr$cluster, cr$rater, cr$cluster_rater, k)
  truth <- cluster_iccs(s2c, theta2_true(rho), s2cr, k)

  c(
    fixed_A1 = fixed[["A1"]], fixed_Ak = fixed[["Ak"]],
    fixed_C1 = fixed[["C1"]], fixed_Ck = fixed[["Ck"]],
    reduce_A1 = fixed[["A1"]] - random[["A1"]], # fixed vs M5 random (should be ~0 balanced)
    reduce_Ak = fixed[["Ak"]] - random[["Ak"]],
    biasT_A1 = fixed[["A1"]] - truth[["A1"]], # fixed vs finite-population truth
    biasT_Ak = fixed[["Ak"]] - truth[["Ak"]],
    s2cr_fixed = cf$cluster_rater, s2cr_random = cr$cluster_rater, # does fixing bias cr?
    theta2 = cf$rater, sigma2r = cr$rater, # theta^2_r vs sigma^2_r (M3 §6 identity)
    s2c_hat = cf$cluster,
    truth_A1 = truth[["A1"]], truth_Ak = truth[["Ak"]]
  )
}

run_regime <- function(label, n_rep, Nc, ns, rho, s2c, s2s, s2cr, s2e, seed0) {
  m <- do.call(rbind, Filter(Negate(is.null), lapply(
    seq_len(n_rep),
    function(i) sim_one(seed0 + i, Nc, ns, rho, s2c, s2s, s2cr, s2e)
  )))
  mean_c <- function(col) mean(m[, col])
  cat(sprintf(
    "\n[%s]  Nc=%d ns=%d k=%d  reps=%d\n", label, Nc, ns, length(rho), nrow(m)
  ))
  cat(sprintf(
    "  truth: theta2_r=%.4f  ICC_c(A,1)=%.4f  ICC_c(A,k)=%.4f\n",
    theta2_true(rho), mean_c("truth_A1"), mean_c("truth_Ak")
  ))
  cat(sprintf(
    "  REDUCTION fixed-vs-M5random  |A1|=%.2e  |Ak|=%.2e   (Outcome A wants ~0)\n",
    mean(abs(m[, "reduce_A1"])), mean(abs(m[, "reduce_Ak"]))
  ))
  cat(sprintf(
    "  theta2_r=%.4f vs sigma2_r=%.4f (|d|=%.2e)   s2cr fixed=%.4f random=%.4f (|d|=%.2e)\n",
    mean_c("theta2"), mean_c("sigma2r"), abs(mean_c("theta2") - mean_c("sigma2r")),
    mean_c("s2cr_fixed"), mean_c("s2cr_random"),
    abs(mean_c("s2cr_fixed") - mean_c("s2cr_random"))
  ))
  cat(sprintf(
    "  RECOVERY bias vs truth  A1=%+.4f  Ak=%+.4f   s2c_hat=%.4f (true %.4f)\n",
    mean_c("biasT_A1"), mean_c("biasT_Ak"), mean_c("s2c_hat"), s2c
  ))
  invisible(m)
}

# Fixed rater effects (k=4): a real finite population, theta^2_r ~ 0.417.
rho4 <- c(-0.8, -0.2, 0.3, 0.7)

cat("=== M37 point spike: fixed-rater cluster-level ICC (balanced crossed D1) ===\n")
cat(sprintf("rho = (%s); theta^2_r(true) = %.4f\n", paste(rho4, collapse = ", "), theta2_true(rho4)))

# Interior regimes: sweep cluster count (few-cluster efficiency + the incidental axis).
run_regime("interior C_n=20", 300, Nc = 20, ns = 6, rho4, s2c = 0.60, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37000)
run_regime("interior C_n=80", 300, Nc = 80, ns = 6, rho4, s2c = 0.60, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37100)
# Boundary regime: sigma^2_c = 0 (clusters do not differ) -> ICC_c = 0 (#3).
run_regime("boundary  C_n=80", 300, Nc = 80, ns = 6, rho4, s2c = 0.00, s2s = 0.80, s2cr = 0.25, s2e = 1.0, seed0 = 37200)

# VERDICT -- OUTCOME A. Reduction fixed-vs-M5random |A1|,|Ak| ~ 1e-6 in ALL regimes;
# theta^2_r == sigma^2_r (|d| ~ 1e-7, the M3 §6 identity) AND -- the open question --
# s2cr_fixed == s2cr_random (|d| ~ 1e-7): fixing the rater main effect does NOT bias the
# (1|cluster:rater) interaction, so the RANDOM sigma^2_cr IS the correct fixed-rater
# cluster-level error term. Recovery of the non-circular finite-population truth is
# unbiased at C_n=80 (A1 +0.0001, Ak -0.0029); the C_n=20 (-0.024/-0.035) and boundary
# (+0.025/+0.082, s2c_hat floored ~0.018) biases are the standard few-cluster / variance-
# floor effects, not an sigma^2_cr-treatment failure. => Ship with a REDUCTION oracle
# (balanced fixed == M5 random cluster-level) + lme4 cross-engine + seeded recovery; the
# pre-authorized gated Fable review (ADR-047) does NOT fire.
cat("\n=== VERDICT: Outcome A -- reduction exact, recovery clean; no Fable (see comment) ===\n")
