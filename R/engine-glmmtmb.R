# glmmTMB engine ---------------------------------------------------------------
#
# Fits the two-way random-effects model by REML and returns everything the point
# estimate and the Monte-Carlo CI need:
#   * components  - named variance components on the estimable scale
#                   (subject = sigma^2_s, rater = sigma^2_r, residual = sigma^2_res)
#   * estimate    - the fitted parameters on glmmTMB's internal scale, aligned to
#   * vcov        - the joint parameter covariance `vcov(fit, full = TRUE)`
#   * to_components - maps an internal-scale parameter vector back to the named
#                     variance components (ADR-002/003).
#
# glmmTMB carries variances on a log-SD / log-dispersion scale, so the internal
# parameters are unconstrained and MC draws back-transform to strictly positive
# variances -- the boundary-aware behavior PRINCIPLES.md #3 requires. Mapping,
# verified against `VarCorr()`: sigma^2 = exp(2 * theta) for each random-effect
# SD and sigma^2_res = exp(2 * dispersion).
#
# `data` must already be canonicalized to columns `subject`, `rater`, `score`
# (factors for the first two), so the fitted parameter names are always
# "theta_1|subject.1", "theta_1|rater.1", and "disp~(Intercept)".

fit_glmmtmb <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the ICC model.")

  fit <- withCallingHandlers(
    glmmTMB::glmmTMB(
      score ~ 1 + (1 | subject) + (1 | rater),
      data = data,
      REML = TRUE
    ),
    warning = function(w) {
      # Surface fit trouble through cli, but keep it non-fatal (PRINCIPLES.md #8).
      cli::cli_warn(c(
        "The {.pkg glmmTMB} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  vc <- glmmTMB::VarCorr(fit)$cond
  components <- list(
    subject = as.numeric(attr(vc$subject, "stddev"))^2,
    rater = as.numeric(attr(vc$rater, "stddev"))^2,
    residual = stats::sigma(fit)^2
  )

  # Joint covariance and the point estimates on the SAME internal scale/order.
  vcov_full <- stats::vcov(fit, full = TRUE)
  nm <- colnames(vcov_full)
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  estimate[["(Intercept)"]] <- as.numeric(glmmTMB::fixef(fit)$cond[[
    "(Intercept)"
  ]])
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  estimate[grep("subject", nm)] <- log(as.numeric(attr(vc$subject, "stddev")))
  estimate[grep("rater", nm)] <- log(as.numeric(attr(vc$rater, "stddev")))

  if (anyNA(estimate)) {
    abort_intraclass(
      c(
        "Could not align the {.pkg glmmTMB} parameter vector to its covariance.",
        i = "Unmatched parameters: {.val {nm[is.na(estimate)]}}."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }

  # Back-transform a matrix of internal-scale draws (rows = parameters aligned to
  # `nm`, columns = MC draws) to variance components, vectorized over draws.
  si <- grep("subject", nm)
  ri <- grep("rater", nm)
  di <- which(nm == "disp~(Intercept)")
  to_components <- function(par) {
    list(
      subject = exp(2 * par[si, ]),
      rater = exp(2 * par[ri, ]),
      residual = exp(2 * par[di, ])
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components
  )
}

# Fixed-rater engine (two-way mixed, McGraw & Wong Case 3 / 3A) ------------------
#
# Resolves the ADR-006 debt: on incomplete data the balanced-only "fixed ==
# random" label layer is invalid, so `raters = "fixed"` gets its OWN fit with
# raters as fixed effects (estimand-spec M3 §6):
#
#     score ~ 1 + rater + (1 | subject)
#
# There is no sigma^2_r. For ABSOLUTE agreement the rater error term is
# theta^2_r, the finite-population variance of the k rater level means (Case 3A).
# Estimated from the fitted fixed effects it needs a BIAS CORRECTION: the raw
# variance of the estimated rater means overstates the true spread by their
# sampling variance, exactly mirroring the ANOVA (MSC - MSE)/n term. On balanced
# data the corrected theta^2_r equals the random-fit sigma^2_r (verified: SF
# 5.2444), so fixed reproduces random and the four SF coefficients (extends O4).
# CONSISTENCY drops the rater term entirely (sigma^2_s / sigma^2_res).
#
# theta^2_r is returned in the "rater" component slot, so icc_estimand() /
# icc_point() / mc_ci() are UNCHANGED: the agreement error set is still
# {rater, residual} and consistency {residual}; only what fills the "rater" slot
# differs from the random engine (theta^2_r vs sigma^2_r).

# Contrast mapping the treatment-coded fixed effects (intercept + k-1 rater
# contrasts) to the k rater level means, so theta^2_r is coding-invariant.
rater_mean_contrast <- function(k) {
  cbind(rep(1, k), rbind(rep(0, k - 1), diag(k - 1)))
}

fit_glmmtmb_fixed <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the ICC model.")
  k <- nlevels(data$rater)

  fit <- withCallingHandlers(
    glmmTMB::glmmTMB(
      score ~ 1 + rater + (1 | subject),
      data = data,
      REML = TRUE
    ),
    warning = function(w) {
      cli::cli_warn(c(
        "The {.pkg glmmTMB} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  vc <- glmmTMB::VarCorr(fit)$cond
  sd_subject <- as.numeric(attr(vc$subject, "stddev"))
  beta <- glmmTMB::fixef(fit)$cond
  vbeta <- as.matrix(stats::vcov(fit)$cond)

  # theta^2_r point estimate: bias-corrected finite-population variance of the k
  # rater level means (Case 3A). center = I - J/k removes the grand mean; the
  # bias term subtracts the mean sampling variance of the centered means.
  contrast <- rater_mean_contrast(k)
  center <- diag(k) - matrix(1 / k, k, k)
  v_means <- contrast %*% vbeta %*% t(contrast)
  bias <- sum(diag(center %*% v_means)) / (k - 1)
  mu <- as.numeric(contrast %*% beta)
  raw <- as.numeric(t(mu) %*% center %*% mu) / (k - 1)

  components <- list(
    subject = sd_subject^2,
    rater = max(0, raw - bias),
    residual = stats::sigma(fit)^2
  )

  # Joint covariance + point estimates on the internal scale for the MC CI. The
  # fixed-effect betas are on the natural (identity) scale; the subject SD and
  # dispersion are on the log scale.
  vcov_full <- stats::vcov(fit, full = TRUE)
  nm <- colnames(vcov_full)
  beta_nm <- names(beta)
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  estimate[beta_nm] <- as.numeric(beta)
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  estimate[grep("subject", nm)] <- log(sd_subject)

  if (anyNA(estimate)) {
    abort_intraclass(
      c(
        "Could not align the {.pkg glmmTMB} parameter vector to its covariance.",
        i = "Unmatched parameters: {.val {nm[is.na(estimate)]}}."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }

  bi <- match(beta_nm, nm)
  di <- which(nm == "disp~(Intercept)")
  si <- grep("subject", nm)
  to_components <- function(par) {
    # Per draw: reconstruct the k rater means, apply the SAME bias-corrected
    # theta^2_r (bias is constant -- v_means is fixed), clamp at 0 (boundary).
    means <- contrast %*% par[bi, , drop = FALSE]
    raw_draws <- colSums(means * (center %*% means)) / (k - 1)
    list(
      subject = exp(2 * par[si, ]),
      rater = pmax(0, raw_draws - bias),
      residual = exp(2 * par[di, ])
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components
  )
}
