# brms (Bayesian) engine (selectable optional engine, M23 / ADR-033) -----------
#
# Promotes brms to a selectable `engine = "brms"` for the random two-way path -- the
# first Bayesian engine, opening the cross-cutting carryover deferred at M7 (ADR-014).
# Returns the SAME six-field engine contract as fit_glmmtmb() -- `components`,
# `estimate`, `vcov`, `to_components` -- PLUS one new field, `draws`: a
# (component x posterior-draw) matrix of the variance components on the natural
# variance scale. The Bayesian branch in icc() derives BOTH the point (MAP) and the
# interval (percentile credible) from `draws`, because the posterior mode is not
# transform-invariant (MAP(ICC) != icc_point(MAP components)) so the ICC point must be
# the mode of the ICC-draw vector, not icc_point() of the modal components (ADR-033).
#
# THE MODEL AND PRIOR (sourced, #12). The two-way crossed random model
#   score_ij = mu + s_i + r_j + e_ij ,  s ~ N(0, sigma^2_s), r ~ N(0, sigma^2_r),
# with the interaction confounded into the residual (the M1/M2 family, single
# replicate; ten Hove, Jorgensen & van der Ark 2020 Eq. 1-3), is fit as
#   score ~ 1 + (1 | subject) + (1 | rater)
# under a HALF-t(4, 0, 1) prior on EVERY random-effect SD --
#   set_prior("student_t(4, 0, 1)", class = "sd")
# (brms positive-truncates SD-class priors, so student_t becomes the half-t). df = 4
# is ten Hove 2020's deliberate choice for variance parameters near the zero boundary
# (Gelman 2019; §3.3/§4.1) -- exactly Principle #3's regime. The prior is FIXED and
# sourced: it is NOT user-overridable in M23 (#12), and `brm_args` may not set it (guarded
# in icc()). The residual SD (`sigma`) keeps brms's default weakly-informative prior, as
# ten Hove's parameterization folds the interaction into it.
#
# POINT ESTIMATE = MAP, NOT EAP. ten Hove 2020 §4.2 (Figs 1-5) shows the posterior mode
# (MAP) is unbiased for sigma_r and ICC(A,1) at k > 2, while the posterior mean (EAP)
# severely OVERESTIMATES sigma_r. So the point comes from posterior_mode() of the ICC
# draws (R/ci-posterior.R), never the mean. The `components` slot below is filled with the
# boundary-aware modes of the per-component variance draws (for the variance-decomposition
# display / d_study reuse) to keep the whole object MAP-consistent, but the headline ICC
# point does not read it -- it reads `draws`.
#
# INTERVAL = PERCENTILE CREDIBLE. ten Hove 2020 §4.2 finds percentile BCIs (not HPDIs)
# give nominal coverage at k > 2, so the interval reuses the M16 percentile reduction
# (two_sided_interval()) verbatim on the ICC draws -- a CREDIBLE interval, labelled as
# such in print/tidy (icc()'s Bayesian branch sets ci$method = "posterior").
#
# `estimate`/`vcov`/`to_components` are filled on the internal log-SD scale (mean and
# covariance of the log-SD posterior draws) purely for CONTRACT COMPLETENESS so the
# object is well-formed for the shared downstream paths (e.g. a normal-approx `mc` slot);
# the reported point and interval never use them for a Bayesian fit -- `draws` is
# authoritative. `data` must already be canonicalized to columns `subject`, `rater`,
# `score` (factors for the first two) and COMPLETE/BALANCED (two-way random only in M23;
# guarded in icc()).
#
# BACKEND (ADR-033 amendment). The rstan backend is the default (CRAN-clean); the user may
# override the backend -- and any other brm() knob (chains/iter/cores/control) -- through
# the brms-scoped `brm_args` passthrough forwarded here. Nothing in this engine branches on
# the backend: brm() returns a `brmsfit` and every extraction below is backend-agnostic.
# `brm_args` may NOT set `formula`/`data`/`prior`/`seed` (this engine owns them); icc()
# guards those before dispatch.

# Long -> the component posterior draw matrix. Pulls the post-warmup SD draws for the
# subject and rater random effects and the residual SD from the fitted `brmsfit` (column
# names `sd_subject__Intercept`, `sd_rater__Intercept`, `sigma`), squares them to the
# variance scale, and stacks them as rows named to match `components`. Every draw is
# strictly positive (SDs), so the matrix is boundary-aware by construction -- no clamping,
# no log round-trip (ADR-033: natural variance scale).
brms_component_draws <- function(fit, call = rlang::caller_env()) {
  dm <- as.matrix(fit)
  need <- c("sd_subject__Intercept", "sd_rater__Intercept", "sigma")
  missing <- setdiff(need, colnames(dm))
  if (length(missing) > 0L) {
    abort_intraclass(
      c(
        "Could not read the {.pkg brms} posterior draws.",
        i = "Expected columns {.val {missing}} were not in the draw matrix."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  rbind(
    subject = dm[, "sd_subject__Intercept"]^2,
    rater = dm[, "sd_rater__Intercept"]^2,
    residual = dm[, "sigma"]^2
  )
}

fit_brms_twoway <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  rlang::check_installed(
    "brms",
    reason = "to fit the ICC model with brms (the Bayesian engine)."
  )

  # We own the model, data, sourced prior (#12), and seed; `brm_args` supplies only the
  # backend and sampler knobs (chains/iter/cores/control/...). The collision guard lives
  # in icc() (a classed, teaching abort) so this engine can assume `brm_args` is clean.
  base_args <- list(
    formula = stats::as.formula("score ~ 1 + (1 | subject) + (1 | rater)"),
    data = data,
    prior = brms::set_prior("student_t(4, 0, 1)", class = "sd"),
    refresh = 0
  )
  if (!is.null(seed)) {
    base_args$seed <- seed
  }

  fit <- withCallingHandlers(
    do.call(brms::brm, c(base_args, brm_args)),
    warning = function(w) {
      # Surface fit trouble through cli, non-fatal, matching the other engines (#8).
      cli::cli_warn(c(
        "The {.pkg brms} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  draws <- brms_component_draws(fit, call = call)

  # `components` = the boundary-aware MODE of each variance component's draws (keeps the
  # whole object MAP-consistent for the decomposition display; the headline ICC point does
  # not read this -- it reads `draws`). posterior_mode() serves [0, Inf) components here and
  # [0, 1] ICCs downstream via its `lower`/`upper` bounds (R/ci-posterior.R).
  components <- list(
    subject = posterior_mode(draws["subject", ], lower = 0),
    rater = posterior_mode(draws["rater", ], lower = 0),
    residual = posterior_mode(draws["residual", ], lower = 0)
  )

  # Contract-completeness `mc` slot on the internal log-SD scale (mean + covariance of the
  # log-SD draws). Never used for the reported Bayesian point/interval (`draws` is
  # authoritative); kept so the object is well-formed for the shared downstream paths.
  log_sd <- log(sqrt(draws))
  slots <- rownames(draws)
  estimate <- stats::setNames(rowMeans(log_sd), slots)
  vcov <- stats::cov(t(log_sd))
  dimnames(vcov) <- list(slots, slots)
  to_components <- function(par) {
    list(
      subject = exp(2 * par["subject", ]),
      rater = exp(2 * par["rater", ]),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "brms",
    components = components,
    estimate = estimate,
    vcov = vcov,
    to_components = to_components,
    # The new contract field (ADR-033): the posterior component draws the Bayesian branch
    # reduces to a MAP point + percentile credible interval (R/ci-posterior.R). A
    # non-Bayesian engine leaves this NULL and takes the icc_point()/mc_ci() path.
    draws = draws
  )
}
