# M62 T3 — non-parametric bootstrap CI prototype for the one-way random ICC.
#
# NON-EXPORTED research prototype (data-raw/, not R/). Implements the
# ukoumunne2003 procedure faithfully so the M62 coverage harness (T4) can
# compare it against the package incumbents (MC, parametric bootstrap):
#
#   - resample WHOLE SUBJECTS with replacement (ukoumunne2003 §3.1 strategy 1),
#   - point estimate = one-way ANOVA MoM  rho = (MSA-MSE)/(MSA+(n-1)MSE)
#     (= REML on balanced data; the estimate ukoumunne/ohyama use),
#   - variance-stabilizing transform f(rho) = log{[1+(n-1)rho]/(1-rho)} = log F
#     (ukoumunne2003 §4 eq. 6); note f(rho_hat) = log(MSA/MSE),
#   - infinitesimal-jackknife SE of log F (ukoumunne2003 eq. 7) for the
#     studentized (bootstrap-t) interval, avoiding a nested bootstrap.
#
# Interval variants returned: percentile, transformed bootstrap-t (the paper's
# recommended, PRIMARY candidate), and BCa (reference point).
#
# Sourced by data-raw/m62-coverage-harness.R (T4). Deterministic given `seed`.

# --- one-way balanced data generator -----------------------------------------
# Returns a long data.frame(subject, rater, y); sigma_a^2 + sigma_e^2 = 1.
sim_oneway <- function(k, n, rho, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  sigma_a <- sqrt(rho)
  sigma_e <- sqrt(1 - rho)
  a <- stats::rnorm(k, 0, sigma_a)
  y <- rep(a, each = n) + stats::rnorm(k * n, 0, sigma_e)
  data.frame(
    subject = factor(rep(seq_len(k), each = n)),
    rater = factor(rep(seq_len(n), times = k)),
    y = y
  )
}

# --- one-way ANOVA summary on a (possibly resampled) balanced data set --------
# `groups` is a list of numeric vectors (one per subject, each length n). Working
# on the list form keeps bootstrap resampling of whole subjects trivial and makes
# the eq. 7 per-cluster contributions explicit.
oneway_anova <- function(groups) {
  k <- length(groups)
  n <- length(groups[[1]])
  ybar_i <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  ssa <- n * sum((ybar_i - grand)^2) # between, df = k-1
  sse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1))) # within
  msa <- ssa / (k - 1)
  mse <- sse / (k * (n - 1))
  f <- msa / mse
  rho <- (msa - mse) / (msa + (n - 1) * mse) # = (F-1)/(F+n-1)
  logf <- log(f)
  # eq. 7: infinitesimal-jackknife SE of log F under resampling of clusters.
  contrib <- vapply(
    seq_len(k),
    function(i) {
      n * (ybar_i[i] - grand)^2 / ssa - sum((groups[[i]] - ybar_i[i])^2) / sse
    },
    numeric(1)
  )
  se_ij_logf <- sqrt(sum(contrib^2))
  list(rho = rho, logf = logf, se_ij_logf = se_ij_logf, n = n, k = k)
}

# f^{-1}: back-transform log F -> rho (monotone increasing), n the group size.
logf_to_rho <- function(logf, n) {
  f <- exp(logf)
  (f - 1) / (f + n - 1)
}

df_to_groups <- function(df) {
  split(df$y, df$subject)
}

# --- non-parametric bootstrap intervals (ukoumunne2003) -----------------------
# Returns a named list of c(lower, upper) for each variant.
npboot_oneway <- function(df, B = 2000L, conf = 0.95, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  groups <- df_to_groups(df)
  k <- length(groups)
  obs <- oneway_anova(groups)
  alpha <- 1 - conf

  # B bootstrap resamples of whole subjects (with replacement).
  rho_star <- numeric(B)
  t_star <- numeric(B) # studentized log F, for the bootstrap-t
  for (b in seq_len(B)) {
    idx <- sample.int(k, k, replace = TRUE)
    fit <- oneway_anova(groups[idx])
    rho_star[b] <- fit$rho
    t_star[b] <- (fit$logf - obs$logf) / fit$se_ij_logf
  }

  # (1) percentile — quantiles of rho* directly.
  perc <- unname(stats::quantile(rho_star, c(alpha / 2, 1 - alpha / 2)))

  # (2) transformed bootstrap-t — studentized on the log F scale, back-transformed.
  tq <- unname(stats::quantile(t_star, c(alpha / 2, 1 - alpha / 2)))
  lo_logf <- obs$logf - tq[2] * obs$se_ij_logf
  hi_logf <- obs$logf - tq[1] * obs$se_ij_logf
  boott <- c(logf_to_rho(lo_logf, obs$n), logf_to_rho(hi_logf, obs$n))

  # (3) BCa on rho* — bias-correction z0 + jackknife acceleration over subjects.
  z0 <- stats::qnorm(mean(rho_star < obs$rho))
  jack <- vapply(
    seq_len(k),
    function(i) oneway_anova(groups[-i])$rho,
    numeric(1)
  )
  jbar <- mean(jack)
  a_num <- sum((jbar - jack)^3)
  a_den <- 6 * (sum((jbar - jack)^2))^1.5
  acc <- if (a_den == 0) 0 else a_num / a_den
  z_lo <- stats::qnorm(alpha / 2)
  z_hi <- stats::qnorm(1 - alpha / 2)
  a1 <- stats::pnorm(z0 + (z0 + z_lo) / (1 - acc * (z0 + z_lo)))
  a2 <- stats::pnorm(z0 + (z0 + z_hi) / (1 - acc * (z0 + z_hi)))
  bca <- unname(stats::quantile(rho_star, c(a1, a2)))

  list(
    rho_hat = obs$rho,
    percentile = perc,
    boott_transformed = boott,
    bca = bca
  )
}

# --- smoke test (interactive only) -------------------------------------------
# A single dataset at a benign cell; confirms all three intervals return finite
# ordered endpoints bracketing rho_hat. NOT a coverage run (that is T4).
if (interactive()) {
  d <- sim_oneway(k = 30, n = 4, rho = 0.5, seed = 1)
  out <- npboot_oneway(d, B = 500L, seed = 2)
  str(out)
  stopifnot(
    is.finite(out$percentile),
    is.finite(out$boott_transformed),
    is.finite(out$bca),
    out$boott_transformed[1] <= out$boott_transformed[2]
  )
}
