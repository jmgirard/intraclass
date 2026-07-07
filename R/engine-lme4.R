# lme4 engine (selectable alternate engine, M5.5 / ADR-012) --------------------
#
# Promotes lme4 from oracle-only (ADR-005) to a selectable `engine = "lme4"` for
# the default random two-way path. Fits the same model by REML and returns the
# SAME six-field engine contract as fit_glmmtmb() -- `components`, `estimate`,
# `vcov`, `to_components` -- so icc_point()/mc_ci()/d_study() are unchanged. This
# is a second engine, not a new estimand (M5.5; no estimand-spec, cf. M4).
#
# The Monte-Carlo CI (ADR-003) samples the fitted parameters on an internal scale
# whose back-transform is boundary-aware. glmmTMB gets this for free from its
# log-SD parameterization; base lme4 does not expose the joint covariance of the
# variance-component parameters at all (ADR-002). merDeriv (a Suggests dep)
# supplies it, but on the variance/SD scale, where MC draws could cross zero. So
# we take merDeriv's SD-scale covariance and delta-transform it to the LOG-SD
# scale (Jacobian d log(sd)/d sd = 1/sd), matching glmmTMB's parameterization
# exactly. Verified live on the Shrout & Fleiss (1979) data: the transformed
# log-SD covariance reproduces glmmTMB's `vcov(fit, full = TRUE)` to ~1e-4 in
# every entry -- which is why the lme4 MC CI matches the glmmTMB MC CI to ~1e-2
# (oracle O-LME, the payoff of merDeriv over a parametric bootstrap).
#
# `data` must already be canonicalized to columns `subject`, `rater`, `score`
# (factors for the first two), as with the glmmTMB engine.

fit_lme4 <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the ICC model with lme4.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )

  fit <- withCallingHandlers(
    lme4::lmer(
      score ~ 1 + (1 | subject) + (1 | rater),
      data = data,
      REML = TRUE
    ),
    warning = function(w) {
      # Surface fit trouble through cli, but keep it non-fatal (PRINCIPLES.md #8),
      # matching the glmmTMB engine.
      cli::cli_warn(c(
        "The {.pkg lme4} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  # Boundary asymmetry vs. glmmTMB (ADR-012): when a variance component collapses
  # to exactly zero, lme4 returns a singular fit and merDeriv's information matrix
  # is singular, so no Monte-Carlo covariance can be formed. glmmTMB's log-SD
  # parameterization pushes the same boundary to -Inf smoothly and stays finite.
  # Fail loudly (PRINCIPLES.md #5/#8) and point at the engine that handles it,
  # rather than returning an interval merDeriv cannot support.
  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot form a Monte-Carlo interval for a \\
         singular (boundary) fit.",
        i = "A variance component was estimated at exactly zero, so \\
             {.pkg merDeriv} cannot compute the parameter covariance.",
        i = "Use {.code engine = \"glmmTMB\"}, which is boundary-robust here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  vc <- lme4::VarCorr(fit)
  sd_subject <- as.numeric(attr(vc$subject, "stddev"))
  sd_rater <- as.numeric(attr(vc$rater, "stddev"))
  sd_res <- as.numeric(stats::sigma(fit))
  components <- list(
    subject = sd_subject^2,
    rater = sd_rater^2,
    residual = sd_res^2
  )

  # merDeriv's SD-scale joint covariance of (intercept, sd_subject, sd_rater,
  # sd_residual). Call the method directly (it is exported) so dispatch does not
  # depend on merDeriv being attached.
  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)

  # Map merDeriv's columns to our named slots by NAME (grouping-factor order is
  # not guaranteed): "cov_<group>.(Intercept)" for the random-effect SDs and
  # "residual" for the residual SD; the fixed intercept is the remaining column.
  idx <- c(
    intercept = which(nm_sd == "(Intercept)"),
    subject = grep("subject", nm_sd),
    rater = grep("rater", nm_sd),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != 4L || anyNA(idx)) {
    abort_intraclass(
      c(
        "Could not align the {.pkg merDeriv} covariance to the model terms.",
        i = "Columns returned: {.val {nm_sd}}."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  vcov_sd <- vcov_sd[idx, idx, drop = FALSE]

  # Delta-transform SD-scale -> log-SD scale: for the intercept the Jacobian is 1
  # (kept on its natural scale, and orthogonal to the variance terms); for each SD
  # term it is 1/sd. This puts every variance parameter on the same log-SD scale
  # as glmmTMB, so exp(2 * draw) is strictly positive (boundary-aware, #3).
  jac <- diag(c(1, 1 / sd_subject, 1 / sd_rater, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)

  slots <- c("(Intercept)", "subject", "rater", "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(
      as.numeric(lme4::fixef(fit)[["(Intercept)"]]),
      log(sd_subject),
      log(sd_rater),
      log(sd_res)
    ),
    slots
  )

  # Back-transform a matrix of log-SD draws (rows = parameters named as `slots`,
  # columns = MC draws) to variance components -- identical form to fit_glmmtmb().
  to_components <- function(par) {
    list(
      subject = exp(2 * par["subject", ]),
      rater = exp(2 * par["rater", ]),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components
  )
}
