# Feasibility spike (C1) part 2: does the boundary-aware MC interval COVER (#3)?
# Reuses the DGP; builds the MC interval faithfully -- per-cluster 2b moment correction
# (M28/ADR-038) generalized to unequal k_c, average-then-floor.
suppressMessages(library(glmmTMB))

sim_one <- function(seed, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep) {
  set.seed(seed); rows <- list()
  for (c in seq_len(Nc)) for (s in seq_len(ns)) {
    us <- rnorm(1, 0, sqrt(s2s))
    for (r in seq_len(kc_vec[c])) {
      if (runif(1) > p_keep) next
      rows[[length(rows) + 1]] <- data.frame(cluster = c,
        subject = paste0("c", c, "s", s), rater = paste0("c", c, "r", r),
        score = gamma[c] + rmeans_list[[c]][r] + us + rnorm(1, 0, sqrt(s2e)))
    }
  }
  d <- do.call(rbind, rows)
  d$rater <- factor(d$rater); d$cs <- factor(paste0(d$cluster, ":", d$subject))
  d[d$cs %in% names(which(table(d$cs) >= 2)), , drop = FALSE]
}
true_theta2 <- function(rl) mean(vapply(rl, function(m) sum((m-mean(m))^2)/(length(m)-1), numeric(1)))

# point theta^2 (1b) + MC interval (per-cluster 2b, average-floor)
estimate_with_ci <- function(d, ndraw = 2000) {
  f <- glmmTMB(score ~ 0 + rater + (1 | cs), data = d, REML = TRUE)
  beta <- fixef(f)$cond; k <- length(beta)
  V <- as.matrix(vcov(f, full = TRUE)); nm <- colnames(V)
  b_ix <- seq_len(k); disp_ix <- which(nm == "disp~(Intercept)"); th_ix <- grep("^theta", nm)
  vb <- V[b_ix, b_ix, drop = FALSE]
  cluster_of <- sub("^rater(c[0-9]+)r[0-9]+$", "\\1", names(beta))
  idx <- split(b_ix, cluster_of)
  ctr  <- lapply(idx, function(ix) { kc <- length(ix); diag(kc) - matrix(1/kc, kc, kc) })
  kc   <- lengths(idx)
  bias <- Map(function(ix, C, kk) sum(diag(C %*% vb[ix, ix, drop = FALSE]))/(kk-1), idx, ctr, kc)
  # point: 1b-corrected, average-floored
  raw  <- Map(function(ix, C, kk) as.numeric(t(beta[ix]) %*% C %*% beta[ix])/(kk-1), idx, ctr, kc)
  s2s <- exp(2 * getME(f, "theta")); s2e <- sigma(f)^2
  th_pt <- max(0, mean(unlist(raw) - unlist(bias)))
  icc_pt <- s2s / (s2s + th_pt + s2e)
  # draws
  L <- t(chol(V)); par <- c(beta, V_disp = NA); mu <- c(beta, log(sigma(f)), getME(f, "theta"))
  Z <- matrix(rnorm(length(mu) * ndraw), length(mu), ndraw)
  draws <- mu + L %*% Z
  bmat <- draws[b_ix, , drop = FALSE]
  # per-cluster 2b push-forward, average, floor
  per <- Map(function(ix, C, kk, bg) {
    m <- bmat[ix, , drop = FALSE]
    colSums(m * (C %*% m))/(kk-1) - 2*bg
  }, idx, ctr, kc, bias)
  th_draw <- pmax(0, Reduce(`+`, per) / length(per))
  s2s_d <- exp(2 * draws[th_ix, ]); s2e_d <- exp(2 * draws[disp_ix, ])
  icc_d <- s2s_d / (s2s_d + th_draw + s2e_d)
  ci <- quantile(icc_d, c(.025, .975), names = FALSE)
  list(icc = icc_pt, theta2 = th_pt, ci = ci)
}

run_cov <- function(label, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep, R) {
  th_true <- true_theta2(rmeans_list); icc_true <- s2s/(s2s+th_true+s2e)
  res <- t(vapply(seq_len(R), function(i) {
    d <- sim_one(2000 + i, Nc, kc_vec, ns, s2s, s2e, rmeans_list, gamma, p_keep)
    e <- tryCatch(estimate_with_ci(d), error = function(err) NULL)
    if (is.null(e)) return(c(cov = NA, contain = NA, lo = NA, hi = NA, icc = NA))
    c(cov = as.numeric(e$ci[1] <= icc_true && icc_true <= e$ci[2]),
      contain = as.numeric(e$ci[1] <= e$icc && e$icc <= e$ci[2]),
      lo = e$ci[1], hi = e$ci[2], icc = e$icc)
  }, numeric(5)))
  ok <- !is.na(res[,"cov"])
  cat(sprintf("\n== %s ==\n  ICC_true=%.4f  R=%d\n", label, icc_true, sum(ok)))
  cat(sprintf("  95%% MC-CI coverage of truth = %.3f  (target ~0.95)\n", mean(res[ok,"cov"])))
  cat(sprintf("  point-in-own-CI containment = %.3f\n", mean(res[ok,"contain"])))
  cat(sprintf("  mean CI width = %.3f\n", mean(res[ok,"hi"] - res[ok,"lo"])))
}

# Interior regime B (unequal k_c) + a BOUNDARY regime (theta^2 = 0, all rater means equal)
set.seed(7); kcB <- sample(c(2,3,4,5), 8, replace = TRUE)
rmeansB <- lapply(kcB, function(kc) seq(0, 1.2, length.out = kc)); gammaB <- rnorm(8,0,1)
run_cov(sprintf("B interior: unequal k_c=%s", paste(kcB, collapse=",")),
        Nc=8, kc_vec=kcB, ns=12, s2s=1.0, s2e=0.5, rmeans_list=rmeansB, gamma=gammaB, p_keep=0.80, R=250)

rmeans0 <- lapply(kcB, function(kc) rep(0, kc))   # theta^2 = 0 exactly (the M28 danger zone)
run_cov("C boundary: theta^2_{r:c}=0 (equal rater means)",
        Nc=8, kc_vec=kcB, ns=12, s2s=1.0, s2e=0.5, rmeans_list=rmeans0, gamma=gammaB, p_keep=0.80, R=250)
