# Fable M36 review harness 2 — the DERIVATION questions (Q1) and the oracle's
# certification power (Q4). Companion to fable-check-m36.R (the Q2 coverage sweep);
# see fable-review-m36-incomplete-fixed-nested-response.md.
#
# Part 1 (Q1): the 2b construction rests on two identities. On a FIXED ragged design
# (missingness pattern held constant, scores resampled):
#   (i)  push-forward:  E_draw[q_c(beta*)] = q_c(beta_hat_c) + b_hat_c, b_hat from the
#        SAME engine vcov that generates the draws. Exact for ANY covariance (Gaussian
#        quadratic form), so raggedness cannot break it — verified numerically, along
#        with its premise that the beta block of vcov(full = TRUE) equals vcov()$cond.
#   (ii) plug-in:       E_sim[q_c(beta_hat_c)] = q_c(mu_c) + tr(C_c V_true_c)/(k_c-1),
#        with V_true the TRUE sampling covariance of beta_hat. Exact in Gaussian theory
#        for any V; what raggedness changes is only whether the engine's b_hat_c
#        estimates tr(C_c V_true_c)/(k_c-1) well. Measured here four ways:
#          b_gls   tr(C V_gls)/(k-1),  V_gls = (X' Sigma^-1 X)^-1 at the true sigma^2
#          b_emp   same trace on the EMPIRICAL covariance of beta_hat over n_sim fits
#          b_hat   the engine's shipped per-cluster bias (mean over fits)
#          b_naive the no-leakage diagonal analog sum(diag(C D))/(k-1),
#                  D = diag(sigma^2_res / n_rc) — what a balanced-closed-form mindset
#                  would compute; differs from b_gls under raggedness (the subject-mean
#                  leakage the brief flags), which is why b MUST be read from vcov.
#        Net interval-center displacement per cluster = b_emp - mean(b_hat): the
#        residual the 2b construction leaves behind (the M28 collapse needs this to be
#        a non-vanishing systematic constant; consistency of vcov drives it to 0).
#
# Part 2 (Q4): certification power of the O-IFNML recovery oracle (|bias| < .03 pin).
# On the oracle's own regimes, compute the ICC(A,1) point under three corrections —
# 0b (raw), 1b (shipped), 2b (over) — from the SAME fits. The oracle certifies the
# correction iff 0b/2b land outside the pin while 1b lands inside.
#
# Run: Rscript data-raw/reviews/fable-check-m36-identities.R

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))

VSC <- 1.0
VRES <- 0.5
CORES <- max(1L, min(6L, parallel::detectCores() - 2L))

# --- fixed ragged design (pattern frozen; scores resampled per rep) -------------------
make_design <- function(kc_vec, ns, p_keep, seed) {
  set.seed(seed)
  rows <- list()
  for (c in seq_along(kc_vec)) {
    for (s in seq_len(ns)) {
      for (r in seq_len(kc_vec[c])) {
        if (stats::runif(1) > p_keep) {
          next
        }
        rows[[length(rows) + 1L]] <- data.frame(
          cluster = c,
          subject = paste(c, s, sep = "_"),
          rater = paste(c, r, sep = "_"),
          r_in_c = r
        )
      }
    }
  }
  d <- do.call(rbind, rows)
  d <- d[d$subject %in% names(which(table(d$subject) >= 2L)), , drop = FALSE]
  # drop raters that lost every observation, then re-check k_c >= 2
  d <- d[d$rater %in% names(which(table(d$rater) >= 1L)), , drop = FALSE]
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  droplevels(d)
}

rater_means <- function(d, theta2) {
  # centered pattern per cluster scaled to finite-population variance = theta2
  mu <- numeric(nlevels(d$rater))
  names(mu) <- levels(d$rater)
  for (cl in levels(d$cluster)) {
    rl <- levels(droplevels(d$rater[d$cluster == cl]))
    k <- length(rl)
    base <- seq_len(k) - (k + 1) / 2
    v0 <- sum(base^2) / (k - 1)
    mu[rl] <- if (theta2 == 0) 0 else base * sqrt(theta2 / v0)
  }
  mu
}

sim_scores <- function(d, mu, seed) {
  set.seed(seed)
  sc <- stats::rnorm(nlevels(d$subject), 0, sqrt(VSC))
  names(sc) <- levels(d$subject)
  10 +
    mu[as.character(d$rater)] +
    sc[as.character(d$subject)] +
    stats::rnorm(nrow(d), 0, sqrt(VRES))
}

fit_pieces <- function(d) {
  fit <- fit_glmmtmb_ml_model(score ~ 0 + rater + (1 | cluster:subject), d)
  beta <- glmmTMB::fixef(fit)$cond
  cluster_of <- nested_rater_clusters(d, names(beta))
  th <- theta2r_fixed_nested(beta, stats::vcov(fit)$cond, cluster_of)
  per_raw <- vapply(
    seq_along(th$cluster_idx),
    function(j) {
      m <- beta[th$cluster_idx[[j]]]
      as.numeric(t(m) %*% th$center[[j]] %*% m) / (th$k[[j]] - 1)
    },
    numeric(1)
  )
  vc <- glmmTMB::VarCorr(fit)$cond
  list(
    fit = fit,
    beta = beta,
    th = th,
    per_raw = per_raw,
    s2s = as.numeric(attr(vc[["cluster:subject"]], "stddev"))^2,
    s2e = stats::sigma(fit)^2
  )
}

# =============================== Part 1: Q1 ==========================================
cat("=== Part 1 (Q1): the two identities on a fixed ragged design ===\n")
THETA2 <- 0.5
d <- make_design(c(2L, 3L, 4L, 5L, 4L, 3L), ns = 6L, p_keep = 0.75, seed = 11)
mu <- rater_means(d, THETA2)
stopifnot(min(table(d$cluster[!duplicated(d$rater)])) >= 2)

# exact GLS covariance of beta_hat at the TRUE sigma^2
X <- stats::model.matrix(~ 0 + rater, d)
Zs <- stats::model.matrix(~ 0 + subject, d)
Sigma <- VSC * tcrossprod(Zs) + VRES * diag(nrow(d))
V_gls <- solve(t(X) %*% solve(Sigma) %*% X)
colnames(V_gls) <- rownames(V_gls) <- colnames(X)

cl_of_beta <- nested_rater_clusters(d, colnames(X))
cluster_idx <- split(seq_len(ncol(X)), cl_of_beta)
ks <- lengths(cluster_idx)
centers <- lapply(ks, function(k) diag(k) - matrix(1 / k, k, k))
tr_b <- function(V) {
  vapply(
    seq_along(cluster_idx),
    function(j) {
      ix <- cluster_idx[[j]]
      sum(diag(centers[[j]] %*% V[ix, ix, drop = FALSE])) / (ks[[j]] - 1)
    },
    numeric(1)
  )
}
b_gls <- tr_b(V_gls)
# the no-leakage diagonal analog (per-rater sampling variance only)
n_rc <- table(d$rater)[colnames(X) |> sub("^rater", "", x = _)]
b_naive <- vapply(
  seq_along(cluster_idx),
  function(j) {
    ix <- cluster_idx[[j]]
    D <- diag(VRES / as.numeric(n_rc[ix]), ks[[j]])
    sum(diag(centers[[j]] %*% D)) / (ks[[j]] - 1)
  },
  numeric(1)
)

N_SIM <- 1000L
sims <- parallel::mclapply(
  seq_len(N_SIM),
  function(r) {
    dd <- d
    dd$score <- sim_scores(d, mu, seed = 5000 + r)
    p <- fit_pieces(dd)
    list(beta = p$beta[colnames(X)], b_hat = p$th$bias, per_raw = p$per_raw)
  },
  mc.cores = CORES
)
B <- do.call(rbind, lapply(sims, `[[`, "beta"))
b_emp <- tr_b(stats::cov(B))
b_hat_mean <- colMeans(do.call(rbind, lapply(sims, `[[`, "b_hat")))
mu_beta <- mu[sub("^rater", "", colnames(X))] # fixef names carry the "rater" prefix
q_mu <- vapply(
  seq_along(cluster_idx),
  function(j) {
    m <- mu_beta[cluster_idx[[j]]]
    as.numeric(t(m) %*% centers[[j]] %*% m) / (ks[[j]] - 1)
  },
  numeric(1)
)
raw_mean <- colMeans(do.call(rbind, lapply(sims, `[[`, "per_raw")))

tab <- data.frame(
  cluster = names(cluster_idx),
  k_c = as.integer(ks),
  plug_in_inflation = raw_mean - q_mu, # E[q(beta_hat)] - q(mu), empirical
  b_gls = b_gls,
  b_emp = b_emp,
  b_hat = b_hat_mean,
  b_naive = b_naive
)
print(tab, digits = 3)
cat(sprintf(
  "\nleakage (b_gls vs b_naive): max rel diff = %.1f%%  (the balanced closed form is dead)\n",
  100 * max(abs(b_gls - b_naive) / b_gls)
))
cat(sprintf(
  "identity (ii): max |plug-in inflation - b_gls| = %.4f (MC SE ~ %.4f)\n",
  max(abs(tab$plug_in_inflation - tab$b_gls)),
  max(apply(do.call(rbind, lapply(sims, `[[`, "per_raw")), 2, sd)) / sqrt(N_SIM)
))
cat(sprintf(
  "engine adequacy: mean_c(b_hat - b_emp) = %+.4f  (net center displacement, vs mean b %.4f)\n",
  mean(b_hat_mean - b_emp),
  mean(b_emp)
))

# identity (i): push-forward on one fit, and its premise (vcov blocks agree)
dd <- d
dd$score <- sim_scores(d, mu, seed = 4321)
p1 <- fit_pieces(dd)
vfull <- stats::vcov(p1$fit, full = TRUE)
vcond <- as.matrix(stats::vcov(p1$fit)$cond)
bn <- p1$th$beta_names
cat(sprintf(
  "premise: max |vcov(full)[beta,beta] - vcov()$cond| = %.2e\n",
  max(abs(vfull[bn, bn] - vcond[bn, bn]))
))
set.seed(99)
ND <- 200000L
ch <- chol(vcond[bn, bn])
draws <- matrix(p1$beta[bn], ND, length(bn), byrow = TRUE) +
  matrix(stats::rnorm(ND * length(bn)), ND) %*% ch
qd <- vapply(
  seq_along(p1$th$cluster_idx),
  function(j) {
    m <- draws[, p1$th$cluster_idx[[j]], drop = FALSE]
    mean(rowSums((m %*% p1$th$center[[j]]) * m)) / (p1$th$k[[j]] - 1)
  },
  numeric(1)
)
cat(sprintf(
  "identity (i): max |E_draw[q] - q(beta_hat) - b_hat| = %.5f (draw SE ~ 1e-3)\n",
  max(abs(qd - p1$per_raw - p1$th$bias))
))

# =============================== Part 2: Q4 ==========================================
cat(
  "\n=== Part 2 (Q4): certification power of the recovery oracle (|bias| < .03) ===\n"
)
N_REP <- 500L
q4_cell <- function(label, kc_vec, ns, p_keep, theta2, base_seed) {
  pop <- VSC / (VSC + theta2 + VRES)
  reps <- parallel::mclapply(
    seq_len(N_REP),
    function(r) {
      set.seed(base_seed + r)
      dd <- make_design(kc_vec, ns, p_keep, seed = base_seed + r)
      dd$score <- sim_scores(
        dd,
        rater_means(dd, theta2),
        seed = base_seed + r + 1L
      )
      p <- tryCatch(fit_pieces(dd), error = function(e) NULL)
      if (is.null(p)) {
        return(NULL)
      }
      icc_of <- function(nb) {
        th2 <- max(0, mean(p$per_raw - nb * p$th$bias))
        p$s2s / (p$s2s + th2 + p$s2e)
      }
      c(b0 = icc_of(0) - pop, b1 = icc_of(1) - pop, b2 = icc_of(2) - pop)
    },
    mc.cores = CORES
  )
  m <- do.call(rbind, reps[!vapply(reps, is.null, logical(1))])
  data.frame(
    cell = label,
    theta2 = theta2,
    bias_0b = mean(m[, "b0"]),
    bias_1b = mean(m[, "b1"]),
    bias_2b = mean(m[, "b2"]),
    mc_se = max(apply(m, 2, sd)) / sqrt(nrow(m)),
    n_fit = nrow(m)
  )
}
q4 <- rbind(
  q4_cell("equal-k4 ns8 p.75", rep(4L, 6L), 8L, 0.75, 0.5, 70000L),
  q4_cell("equal-k4 ns8 p.75", rep(4L, 6L), 8L, 0.75, 0, 71000L),
  q4_cell(
    "unequal-k ns8 p.80",
    c(2L, 3L, 4L, 5L, 4L, 3L),
    8L,
    0.80,
    0.5,
    72000L
  ),
  q4_cell("unequal-k ns8 p.80", c(2L, 3L, 4L, 5L, 4L, 3L), 8L, 0.80, 0, 73000L),
  q4_cell(
    "unequal-k ns4 p.80",
    c(2L, 3L, 4L, 5L, 4L, 3L),
    4L,
    0.80,
    0.5,
    74000L
  )
)
print(q4, digits = 3)
cat(
  "\noracle pin is |bias| < .03: the correction is certified iff 0b (and 2b) breach it\nwhile 1b does not.\n"
)

saveRDS(
  list(q1 = tab, q4 = q4),
  "data-raw/reviews/fable-check-m36-identities-results.rds"
)
cat("\nWrote data-raw/reviews/fable-check-m36-identities-results.rds\n")
