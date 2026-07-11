# Feasibility spike (C1): incomplete/ragged fixed-rater NESTED (Design 2), single-rater
# ICC_s(A,1). Question: can a first-principles per-cluster Case-3A theta^2_{r:c},
# generalized to unequal cluster rater counts, recover a KNOWN finite-population truth
# under ragged (missing-cell) data -- and does its MC interval cover?
#
# Oracle is non-circular: theta^2_{r:c} truth is a DETERMINISTIC function of the fixed
# rater effects (variance of the specific realized rater means), not a sampled parameter.
suppressMessages({library(glmmTMB); library(lme4)})

# ---- generalized ragged per-cluster Case-3A theta^2_{r:c} (the candidate estimator) ----
# beta: named cell-mean fixed effects of `score ~ 0 + rater_nested`; vbeta their cov;
# cluster_of: cluster label per coefficient. Unequal k_c allowed (the generalization).
theta2r_nested_ragged <- function(beta, vbeta, cluster_of) {
  vbeta <- as.matrix(vbeta)
  idx <- split(seq_along(beta), cluster_of)
  per <- vapply(idx, function(ix) {
    kc <- length(ix)
    if (kc < 2L) return(c(raw = NA_real_, bias = NA_real_))
    center <- diag(kc) - matrix(1 / kc, kc, kc)
    mu <- beta[ix]
    raw  <- as.numeric(t(mu) %*% center %*% mu) / (kc - 1)
    bias <- sum(diag(center %*% vbeta[ix, ix, drop = FALSE])) / (kc - 1)
    c(raw = raw, bias = bias)
  }, numeric(2))
  max(0, mean(per["raw", ] - per["bias", ]))  # floor the AVERAGE (M28 posture)
}

# true finite-population theta^2_{r:c} for KNOWN per-cluster rater means
true_theta2 <- function(rmeans_list) {
  mean(vapply(rmeans_list, function(m) {
    kc <- length(m); sum((m - mean(m))^2) / (kc - 1)
  }, numeric(1)))
}

# ---- DGP: Design 2, raters nested in clusters, ragged cells ----
sim_one <- function(seed, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep) {
  set.seed(seed)
  rows <- list()
  for (c in seq_len(Nc)) {
    kc <- kc_vec[c]
    for (s in seq_len(ns)) {
      us <- rnorm(1, 0, sqrt(s2s))                 # subject-in-cluster random effect
      for (r in seq_len(kc)) {
        if (runif(1) > p_keep) next                # ragged: drop cell
        y <- gamma[c] + rmeans_list[[c]][r] + us + rnorm(1, 0, sqrt(s2e))
        rows[[length(rows) + 1]] <- data.frame(
          cluster = c, subject = paste0("c", c, "s", s),
          rater = paste0("c", c, "r", r), score = y
        )
      }
    }
  }
  d <- do.call(rbind, rows)
  d$rater <- factor(d$rater); d$cs <- factor(paste0(d$cluster, ":", d$subject))
  # enforce connectedness: every subject rated by >= 2 raters
  ok <- names(which(table(d$cs) >= 2))
  d[d$cs %in% ok, , drop = FALSE]
}

fit_and_estimate <- function(d, engine = "glmmTMB") {
  if (engine == "glmmTMB") {
    f <- glmmTMB(score ~ 0 + rater + (1 | cs), data = d, REML = TRUE)
    beta <- fixef(f)$cond; vb <- as.matrix(vcov(f)$cond)
    s2s <- as.numeric(attr(VarCorr(f)$cond[["cs"]], "stddev"))^2
    s2e <- sigma(f)^2
  } else {
    f <- lmer(score ~ 0 + rater + (1 | cs), data = d, REML = TRUE,
              control = lmerControl(check.conv.singular = "ignore"))
    beta <- fixef(f); vb <- as.matrix(vcov(f))
    vc <- as.data.frame(VarCorr(f))
    s2s <- vc$vcov[vc$grp == "cs"]; s2e <- vc$vcov[vc$grp == "Residual"]
  }
  cluster_of <- sub("^rater(c[0-9]+)r[0-9]+$", "\\1", names(beta))
  th <- theta2r_nested_ragged(beta, vb, cluster_of)
  icc <- s2s / (s2s + th + s2e)
  list(theta2 = th, s2s = s2s, s2e = s2e, icc = icc)
}

# ---- run: bias + cross-engine, two ragged regimes ----
run_bias <- function(label, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep, R) {
  th_true <- true_theta2(rmeans_list)
  icc_true <- s2s / (s2s + th_true + s2e)
  est <- t(vapply(seq_len(R), function(i) {
    d <- sim_one(1000 + i, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep)
    g <- fit_and_estimate(d, "glmmTMB")
    l <- tryCatch(fit_and_estimate(d, "lme4"), error = function(e) list(icc = NA, theta2 = NA))
    c(icc = g$icc, theta2 = g$theta2, s2s = g$s2s, s2e = g$s2e,
      icc_lme4 = l$icc, dtheta = abs(g$theta2 - l$theta2))
  }, numeric(6)))
  cat(sprintf("\n== %s ==\n", label))
  cat(sprintf("  truth: theta2_{r:c}=%.4f  sigma2_s=%.3f  sigma2_e=%.3f  ICC(A,1)=%.4f\n",
              th_true, s2s, s2e, icc_true))
  cat(sprintf("  est  : theta2=%.4f (bias %+.4f)  sigma2_s=%.3f  sigma2_e=%.3f\n",
              mean(est[,"theta2"]), mean(est[,"theta2"]) - th_true,
              mean(est[,"s2s"]), mean(est[,"s2e"])))
  cat(sprintf("  ICC  : mean=%.4f  bias=%+.4f  (rel %+.1f%%)  sd=%.4f  R=%d\n",
              mean(est[,"icc"]), mean(est[,"icc"]) - icc_true,
              100*(mean(est[,"icc"]) - icc_true)/icc_true, sd(est[,"icc"]), nrow(est)))
  cat(sprintf("  cross-engine |dICC| max=%.2e mean theta2 diff=%.2e\n",
              max(abs(est[,"icc"] - est[,"icc_lme4"]), na.rm = TRUE),
              mean(est[,"dtheta"], na.rm = TRUE)))
  invisible(est)
}

# Regime A: equal k_c = 4, ragged cells (missing subject x rater)
rmeansA <- lapply(1:8, function(c) c(0, 0.4, 0.8, 1.2))        # within-cluster spread fixed
gammaA  <- rnorm(8, 0, 1)                                       # cluster main effects (should cancel)
run_bias("A: equal k_c=4, 25% cells missing", Nc=8, kc_vec=rep(4,8), ns=12,
         s2s=1.0, s2e=0.5, rmeans_list=rmeansA, gamma=gammaA, p_keep=0.75, R=300)

# Regime B: UNEQUAL k_c across clusters (the true generalization test)
set.seed(7)
kcB <- sample(c(2,3,4,5), 8, replace = TRUE)
rmeansB <- lapply(kcB, function(kc) seq(0, 1.2, length.out = kc))
gammaB  <- rnorm(8, 0, 1)
run_bias(sprintf("B: unequal k_c=%s, 20%% cells missing", paste(kcB, collapse=",")),
         Nc=8, kc_vec=kcB, ns=12, s2s=1.0, s2e=0.5,
         rmeans_list=rmeansB, gamma=gammaB, p_keep=0.80, R=300)
