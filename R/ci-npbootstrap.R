# Non-parametric transformed bootstrap-t confidence intervals (one-way) --------
#
# The ukoumunne2003 variance-stabilized transformed bootstrap-t for the balanced
# one-way random ICC, exported as `ci_method = "npbootstrap"` (M75, D-006/D-010;
# GO/NO-GO in M62/RR01, the exported-API scope in RR02). Unlike the parametric
# `"bootstrap"` (which simulates FROM the fitted model and refits), this resamples
# whole subjects with replacement from the raw data -- no reliance on the fitted
# model being correct, and boundary-robust where the Monte-Carlo default aborts.
#
# Procedure (ukoumunne2003 §3-§4; ported from the RR01-verified prototype
# `data-raw/m62-npbootstrap-prototype.R`):
#   - resample WHOLE SUBJECTS with replacement (§3.1 strategy 1),
#   - point estimate rho = (MSA-MSE)/(MSA+(n-1)MSE) via one-way ANOVA MoM,
#   - variance-stabilizing transform f(rho) = log{[1+(n-1)rho]/(1-rho)} = log F
#     (eq. 6); note f(rho_hat) = log(MSA/MSE),
#   - infinitesimal-jackknife SE of log F (eq. 7) for the studentized interval,
#     avoiding a nested bootstrap,
#   - studentize on the log F scale, back-transform the endpoints to the ICC scale.
#
# Endpoints are UNTRUNCATED (ukoumunne §5.2; RR01 §5): confined only to the
# estimator's own support (-1/(n-1), 1) for ICC(1). The ICC(k) / `unit = "average"`
# interval is the exact monotone Spearman-Brown image of the ICC(1) interval
# (RR02 Q2): g(rho) = k*rho/(1+(k-1)rho) applied to the two final rho endpoints.
# Coverage is inherited as an exact event identity, so the ICC(k) interval needs
# no separate oracle -- only the identity cross-check (BC2) and the inherited-
# coverage assertion (BC3). The reported POINT for both estimands is the engine
# (REML) point computed upstream (BC5); the ANOVA MoM rho here is interval
# machinery only and is never surfaced as a point estimate.

# One-way ANOVA summary on a (possibly resampled) balanced set of subject groups.
# `groups` is a list of numeric vectors (one per subject, each length n). Returns
# the transform ingredients; a degenerate group set (SSA = 0 -> log F = -Inf, or
# SSE = 0 -> IJ SE undefined) is a caller-handled condition, flagged via a
# non-finite `logf` / zero `se_ij_logf` rather than aborting here (a resample may
# legitimately be degenerate; the observed data is guarded by the caller).
npb_anova <- function(groups) {
  k <- length(groups)
  n <- length(groups[[1]])
  ybar_i <- vapply(groups, mean, numeric(1))
  grand <- mean(unlist(groups))
  ssa <- n * sum((ybar_i - grand)^2) # between, df = k-1
  sse <- sum(vapply(groups, function(g) sum((g - mean(g))^2), numeric(1)))
  msa <- ssa / (k - 1)
  mse <- sse / (k * (n - 1))
  f <- msa / mse
  rho <- (msa - mse) / (msa + (n - 1) * mse) # = (F-1)/(F+n-1)
  logf <- log(f)
  # eq. 7: infinitesimal-jackknife SE of log F under resampling of subjects.
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
npb_logf_to_rho <- function(logf, n) {
  f <- exp(logf)
  (f - 1) / (f + n - 1)
}

# Spearman-Brown map rho (= ICC(1)) -> ICC(m) for an averaging divisor m; the
# one-way estimand's own reduction signal/(signal + error/m) in rho form. Monotone
# increasing on the estimator's support; m = 1 is the identity (ICC(1)).
npb_sb <- function(rho, m) {
  m * rho / (1 + (m - 1) * rho)
}

# Split the raw one-way data into per-subject score vectors, guarding a degenerate
# extraction loudly (#5/#8): a subject with no rows or a non-finite score would
# silently corrupt the ANOVA. Balance is guaranteed by the caller's dispatch guard.
npb_groups <- function(df, call = rlang::caller_env()) {
  groups <- split(df$score, df$subject)
  lens <- lengths(groups)
  if (any(lens == 0L) || anyNA(unlist(groups))) {
    abort_intraclass(
      c(
        "The one-way bootstrap could not extract complete subject rows.",
        i = "A subject had no observations or a missing score after grouping."
      ),
      class = "intraclass_unidentified",
      call = call
    )
  }
  groups
}

# The exported reducer. Resamples whole subjects, studentizes log F with the eq. 7
# IJ SE, back-transforms, and maps each estimand's rho endpoints through its
# averaging divisor. Returns a list (one per estimand) of
# `list(conf.low, conf.high, std.error)` -- the SAME shape mc_ci()/bootstrap_ci()
# return, so the dispatch consumes it identically. Seeded for reproducibility (#12)
# and RNG-neutral (#9) via with_rng_seed(); an unset seed uses the ambient stream.
npbootstrap_ci <- function(
  df,
  estimands,
  conf_level = 0.95,
  boot_samples = 999L,
  seed = NULL,
  call = rlang::caller_env()
) {
  groups <- npb_groups(df, call = call)
  k <- length(groups)
  obs <- npb_anova(groups)
  # The OBSERVED data must be non-degenerate: SSA = 0 (every subject mean equal ->
  # log F = -Inf) or SSE = 0 (no within-subject variance -> IJ SE undefined) leaves
  # the transform / studentization ill-posed. Fail loudly (#5/#8).
  if (!is.finite(obs$logf) || obs$se_ij_logf == 0) {
    abort_intraclass(
      c(
        "The one-way transformed bootstrap-t interval is undefined for this data.",
        i = "Between- or within-subject variance is exactly zero \\
             (log F = {.val {obs$logf}}), so the {.field log F} transform and its \\
             jackknife SE do not exist.",
        i = "Inspect the data or use {.code ci_method = \"montecarlo\"}."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  draw <- function() {
    rho_star <- numeric(boot_samples)
    t_star <- numeric(boot_samples)
    for (b in seq_len(boot_samples)) {
      idx <- sample.int(k, k, replace = TRUE)
      fit <- npb_anova(groups[idx])
      rho_star[b] <- fit$rho
      t_star[b] <- (fit$logf - obs$logf) / fit$se_ij_logf
    }
    list(rho_star = rho_star, t_star = t_star)
  }
  res <- if (is.null(seed)) draw() else with_rng_seed(seed, draw())

  # A degenerate resample (all resampled subject means equal -> log F = -Inf, or a
  # zero resample SE) makes t* non-finite; the studentized quantiles would then be
  # silent NaN. Negligibly rare at k >= 10, but an exported method fails loudly on
  # it rather than returning a quietly broken interval (#5/#8, AC5/RR01).
  n_bad <- sum(!is.finite(res$t_star))
  if (n_bad > 0L) {
    abort_intraclass(
      c(
        "The one-way transformed bootstrap-t interval could not be computed: \\
         {.val {n_bad}} of {.val {boot_samples}} resamples were degenerate \\
         (SSA = 0 or SE = 0).",
        i = "The design is too small to resample stably; use a larger design or \\
             {.code ci_method = \"montecarlo\"}."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  alpha <- 1 - conf_level
  tq <- stats::quantile(res$t_star, c(alpha / 2, 1 - alpha / 2), names = FALSE)
  # Studentized endpoints on the log F scale (quantile reversal), back-transformed
  # to rho = ICC(1). Untruncated (ukoumunne §5.2).
  lo_logf <- obs$logf - tq[2] * obs$se_ij_logf
  hi_logf <- obs$logf - tq[1] * obs$se_ij_logf
  rho_lo <- npb_logf_to_rho(lo_logf, obs$n)
  rho_hi <- npb_logf_to_rho(hi_logf, obs$n)

  # Each estimand maps the shared rho endpoints through its averaging divisor:
  # ICC(1) (divisor 1) is rho itself; ICC(k) (divisor k) is the monotone
  # Spearman-Brown image (RR02 Q2). std.error is the SD of the estimand's resampled
  # ICC values, the same disclosure mc_ci()/bootstrap_ci() make.
  lapply(estimands, function(est) {
    m <- est$divisor
    list(
      conf.low = npb_sb(rho_lo, m),
      conf.high = npb_sb(rho_hi, m),
      std.error = stats::sd(npb_sb(res$rho_star, m))
    )
  })
}
