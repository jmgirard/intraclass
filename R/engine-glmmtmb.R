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
