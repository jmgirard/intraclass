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

# Long -> the component posterior draw matrix. `spec` is a named character vector mapping
# each internal component name to its `brmsfit` draw column -- for the two-way random model
# c(subject = "sd_subject__Intercept", rater = "sd_rater__Intercept", residual = "sigma"),
# and for the crossed (Design 1) multilevel model the five-component map (M24, ADR-034;
# see fit_brms_multilevel). Pulls the post-warmup SD draws for those columns, squares them
# to the variance scale, and stacks them as rows named by `names(spec)` to match
# `components`. Every draw is strictly positive (SDs), so the matrix is boundary-aware by
# construction -- no clamping, no log round-trip (ADR-033: natural variance scale).
brms_component_draws <- function(fit, spec, call = rlang::caller_env()) {
  dm <- as.matrix(fit)
  missing <- setdiff(unname(spec), colnames(dm))
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
  draws <- do.call(rbind, lapply(spec, function(col) dm[, col]^2))
  rownames(draws) <- names(spec)
  draws
}

# Backend-agnostic MCMC convergence diagnostics on the variance-component parameters
# (M23 Slice 2, ADR-033; generalized to the multilevel component set in M24, ADR-034).
# `vars` is the vector of SD/sigma draw columns to check (the values of the component
# `spec`). Returns the max potential-scale-reduction factor (R-hat) and the min bulk
# effective sample size over those parameters -- ten Hove et al. (2020) §4.1.3 checked
# exactly these (R-hat < 1.10, N_eff > 100). Uses `posterior` (a hard brms dependency, so
# always present behind check_installed("brms")), which reads both rstan and cmdstanr fits.
# Never fatal: if the diagnostics cannot be read it returns NAs, and the caller degrades to
# no convergence warning.
brms_convergence <- function(fit, vars) {
  tryCatch(
    {
      draws <- posterior::subset_draws(
        posterior::as_draws(fit),
        variable = vars
      )
      s <- posterior::summarise_draws(draws, "rhat", "ess_bulk")
      list(
        rhat = max(s$rhat, na.rm = TRUE),
        ess_bulk = min(s$ess_bulk, na.rm = TRUE)
      )
    },
    error = function(e) list(rhat = NA_real_, ess_bulk = NA_real_)
  )
}

# Nudge toward parallel sampling when several chains will run sequentially (M23). brms
# defaults to `cores = getOption("mc.cores", 1L)`, so out of the box the chains run
# one-at-a-time on a single core -- often the slowest part of a fit. We keep that default
# (matching brms; no surprise CPU grab) but, when >1 chain will run on 1 core, emit a
# periodic reminder that the user can parallelize via the `brm_args` passthrough. Rate
# limited by rlang's "regularly" cadence (at most once every 8 hours, NOT per fit), and
# skipped entirely when the user already sets `cores > 1` or runs a single chain.
brms_maybe_cores_note <- function(brm_args) {
  n_chains <- if (is.null(brm_args$chains)) 4L else brm_args$chains
  n_cores <- if (is.null(brm_args$cores)) {
    getOption("mc.cores", 1L)
  } else {
    brm_args$cores
  }
  if (n_cores <= 1L && n_chains > 1L) {
    cli::cli_inform(
      c(
        "i" = "The {.pkg brms} engine is sampling {n_chains} chains sequentially on \\
               one core (often the slowest part of the fit).",
        ">" = "Pass {.code brm_args = list(cores = {n_chains})} (or set \\
               {.code options(mc.cores)}) to sample chains in parallel."
      ),
      .frequency = "regularly",
      .frequency_id = "intraclass_brms_cores"
    )
  }
  invisible(NULL)
}

# Shared brms fit body for every Bayesian design (M23 two-way; M24 crossed multilevel,
# ADR-034). `formula` is the model and `spec` the component -> draw-column map (see
# brms_component_draws); everything else -- the sourced half-t(4, 0, 1) SD prior, the
# `brm_args` passthrough, the parallel-cores nudge, the warning handler, the convergence
# check, and the six-field contract + `draws` -- is design-agnostic and lives here so the
# two-way and multilevel paths cannot drift. The engine owns the model, data, sourced prior
# (#12), and seed; `brm_args` supplies only backend/sampler knobs (chains/iter/cores/...).
# The collision guard lives in icc() (a classed, teaching abort) so this can assume `brm_args`
# is clean.
fit_brms_common <- function(
  formula,
  spec,
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  rlang::check_installed(
    "brms",
    reason = "to fit the ICC model with brms (the Bayesian engine)."
  )

  base_args <- list(
    formula = formula,
    data = data,
    prior = brms::set_prior("student_t(4, 0, 1)", class = "sd"),
    refresh = 0
  )
  if (!is.null(seed)) {
    base_args$seed <- seed
  }

  # Periodic parallel-sampling reminder before the (possibly slow) sequential fit.
  brms_maybe_cores_note(brm_args)

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

  # Convergence diagnostics (Slice 2): warn loudly on weak MCMC mixing (#8) -- a single
  # non-converged fit still returns (the user got a posterior), but the interval is not
  # trustworthy until it converges. ten Hove et al. (2020) doubled warmup until R-hat <
  # 1.10; we surface the caveat and point at the sampler knobs rather than silently
  # refit. The stats are also stored on the contract so the O-Bayes oracle can tally the
  # convergence rate across replications.
  conv <- brms_convergence(fit, vars = unname(spec))
  if (isTRUE(conv$rhat >= 1.10) || isTRUE(conv$ess_bulk < 100)) {
    warn_intraclass(
      c(
        "The {.pkg brms} fit shows weak MCMC convergence (max R-hat \\
         {.val {round(conv$rhat, 3)}}, min bulk-ESS {.val {round(conv$ess_bulk)}}).",
        i = "Draw more/longer chains via {.arg brm_args} (e.g. {.code iter}, \\
             {.code chains}, {.code warmup}); ten Hove et al. (2020) used R-hat < 1.10 \\
             and bulk-ESS > 100.",
        i = "Treat the credible interval with caution until the chains converge."
      ),
      class = "intraclass_brms_convergence"
    )
  }

  draws <- brms_component_draws(fit, spec = spec, call = call)

  # `components` = the boundary-aware MODE of each variance component's draws (keeps the
  # whole object MAP-consistent for the decomposition display; the headline ICC point does
  # not read this -- it reads `draws`). posterior_mode() serves [0, Inf) components here and
  # [0, 1] ICCs downstream via its `lower`/`upper` bounds (R/ci-posterior.R).
  slots <- rownames(draws)
  components <- stats::setNames(
    lapply(slots, function(s) posterior_mode(draws[s, ], lower = 0)),
    slots
  )

  # Contract-completeness `mc` slot on the internal log-SD scale (mean + covariance of the
  # log-SD draws). Never used for the reported Bayesian point/interval (`draws` is
  # authoritative); kept so the object is well-formed for the shared downstream paths.
  log_sd <- log(sqrt(draws))
  estimate <- stats::setNames(rowMeans(log_sd), slots)
  vcov <- stats::cov(t(log_sd))
  dimnames(vcov) <- list(slots, slots)
  to_components <- function(par) {
    stats::setNames(lapply(slots, function(s) exp(2 * par[s, ])), slots)
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
    draws = draws,
    # MCMC convergence diagnostics (max R-hat, min bulk-ESS) for the O-Bayes oracle and
    # programmatic access; NULL for non-Bayesian engines.
    convergence = conv
  )
}

# Two-way random Bayesian fit (M23, ADR-033): score ~ 1 + (1 | subject) + (1 | rater),
# three components (subject, rater, residual). `data` must be canonicalized to columns
# `subject`, `rater`, `score` (factors for the first two) and COMPLETE/BALANCED (two-way
# random only in M23; guarded in icc()).
fit_brms_twoway <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  fit_brms_common(
    formula = stats::as.formula("score ~ 1 + (1 | subject) + (1 | rater)"),
    spec = c(
      subject = "sd_subject__Intercept",
      rater = "sd_rater__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )
}

# One-way random Bayesian fit (M26 Slice 1, ADR-036): the Shrout & Fleiss Case-1 model
#   score ~ 1 + (1 | subject)
# under the SAME sourced half-t(4, 0, 1) prior on the (single) random-effect SD (unchanged
# from M23-M25; ten Hove, Jorgensen & van der Ark 2020 §3.3/§4.1's specification, which
# generalizes verbatim). A STRICT SUBSET of fit_brms_twoway(): rater identity is not
# modeled (raters are interchangeable, M6 spec §2), so there is NO (1 | rater) term and the
# rater main effect + subject x rater interaction are both confounded into the residual
# sigma^2_res. Two components map to the M6 internal names:
#   subject  = sigma^2_s   <- sd_subject__Intercept
#   residual = sigma^2_res <- sigma                     (rater + interaction confounded in)
# The subject-level ICC reads {subject | residual} -- the same shape the shipped Design-3
# brms path (M25) already composes -- so brms_component_draws() / posterior_summary() map
# ICC(1)/ICC(1,k) off the `draws` contract unchanged. `data` must be canonicalized to
# columns `subject`, `rater`, `score` (factors for the first two) and BALANCED/COMPLETE,
# one-way random (guarded in icc(): fixed / multilevel / incomplete / replicate / numeric
# unit refused). The one-way identifiability guard (a subject rated more than once) fires
# in icc() before dispatch.
fit_brms_oneway <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  fit_brms_common(
    formula = stats::as.formula("score ~ 1 + (1 | subject)"),
    spec = c(
      subject = "sd_subject__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )
}

# Fixed-rater two-way Bayesian fit (M26 Slice 2, ADR-036): the McGraw & Wong Case-3
# theta^2_r per posterior draw from a fixed-rater brms fit's population-level rater
# contrasts -- shared by the single-level fit_brms_fixed (M26) and the crossed-multilevel
# fit_brms_multilevel_fixed (M27). Treatment coding: b_Intercept + the k - 1 non-reference
# rater contrasts, mapped to the k level means by the shared rater_mean_contrast().
# center = I - J/k removes the grand mean; the quadratic form is a finite-population
# variance (>= 0), so RAW -- no frequentist bias term is subtracted (a POSTERIOR already
# integrates the parameter uncertainty theta2r_fixed()'s `- bias` removes from a point
# estimate; ADR-036/037, #1/#18).
brms_theta2r_draws <- function(fit, data, call = rlang::caller_env()) {
  k <- nlevels(data$rater)
  dm <- as.matrix(fit)
  b_cols <- c("b_Intercept", paste0("b_rater", levels(data$rater)[-1L]))
  missing <- setdiff(b_cols, colnames(dm))
  if (length(missing) > 0L) {
    abort_intraclass(
      c(
        "Could not read the {.pkg brms} fixed-rater posterior draws.",
        i = "Expected columns {.val {missing}} were not in the draw matrix."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  beta_draws <- t(dm[, b_cols, drop = FALSE]) # rows = coefficients, cols = draws
  contrast <- rater_mean_contrast(k)
  center <- diag(k) - matrix(1 / k, k, k)
  mu_draws <- contrast %*% beta_draws # k rater means x draws
  theta_draws <- colSums(mu_draws * (center %*% mu_draws)) / (k - 1)
  pmax(0, theta_draws)
}

# theta^2_{r:c} per posterior draw for a NESTED (Design 2) fixed-rater brms fit
# (M27 Slice 2, ADR-037). Raters are nested in clusters, fit as cell means via
# `score ~ 0 + rater + (1 | cluster:subject)`, so each rater level has its own
# population-level coefficient b_rater<label> and belongs to exactly one cluster.
# theta^2_{r:c} is the WITHIN-cluster finite-population variance of each cluster's k
# rater means, AVERAGED over clusters (McGraw & Wong Case 3A per cluster, the
# frequentist theta2r_fixed_nested()). RAW per draw -- no per-cluster bias correction
# subtracted: a POSTERIOR already integrates the parameter uncertainty the frequentist
# `- bias` removes from a point estimate (ADR-037 oracle-first resolution, #1/#18). The
# per-cluster raw variance is a proper draw from theta^2_{r:c}'s posterior; averaging
# over clusters is linear. Unlike the CROSSED design (brms_theta2r_draws), fixed != random
# even balanced (per-cluster finite population; the M19 catch), so the oracle is
# CONTAINMENT of the glmmTMB REML point, not equality.
brms_theta2r_nested_draws <- function(fit, data, call = rlang::caller_env()) {
  lvls <- levels(data$rater)
  b_cols <- paste0("b_rater", lvls)
  dm <- as.matrix(fit)
  missing <- setdiff(b_cols, colnames(dm))
  if (length(missing) > 0L) {
    abort_intraclass(
      c(
        "Could not read the {.pkg brms} fixed-rater nested posterior draws.",
        i = "Expected columns {.val {missing}} were not in the draw matrix."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  beta_draws <- t(dm[, b_cols, drop = FALSE]) # rows = rater cell means (lvls order)
  # Each rater level sits in exactly one cluster; group the cell-mean rows by cluster.
  cluster_of <- nested_rater_clusters(data, paste0("rater", lvls))
  cluster_idx <- split(seq_along(lvls), cluster_of)
  ks <- lengths(cluster_idx)
  k <- ks[[1L]] # equal per cluster (balanced; guarded upstream)
  center <- diag(k) - matrix(1 / k, k, k)
  per <- lapply(cluster_idx, function(ix) {
    m <- beta_draws[ix, , drop = FALSE]
    pmax(0, colSums(m * (center %*% m)) / (k - 1)) # RAW, no bias
  })
  Reduce(`+`, per) / length(per)
}

# model with raters as POPULATION-LEVEL fixed effects
#   score ~ 1 + rater + (1 | subject)
# The sourced half-t(4, 0, 1) prior applies to the (single) random-effect SD, sigma_s
# (ten Hove et al. 2020 puts the prior on random-effect SDs); the k - 1 rater contrasts
# carry brms's default (flat) population-level prior -- there is no rater SD to shrink.
# subject = sigma^2_s <- sd_subject__Intercept and residual = sigma^2_res <- sigma come off
# the standard spec via fit_brms_common(); the rater slot carries theta^2_r, the Case-3A
# finite-population variance of the k fixed rater means (estimand-spec M3 §6 / M10 §2),
# computed PER POSTERIOR DRAW from the rater fixed-effect draws and injected as the `rater`
# row of `draws`.
#
# RAW, NO FREQUENTIST BIAS CORRECTION (oracle-first resolution, ADR-036). theta2r_fixed()
# subtracts the mean sampling variance of the beta-hat rater means (`raw - bias`) because a
# POINT estimate from one fit's beta-hat overstates the finite-population variance by the
# estimator's sampling variance. A POSTERIOR already integrates that parameter uncertainty,
# so the raw per-draw finite-population variance is a proper draw from the posterior of
# theta^2_r -- applying the frequentist correction would double-count. Confirmed at build
# (O-Bayes-Fixed): the bias correction moves MAP ICC(A,1) by ~0.002 (negligible), and the
# raw MAP tracks glmmTMB fixed within the standard MAP-below-REML skew (the mode of the
# right-skewed ICC draws sits below the REML plug-in, ADR-033) -- so the oracle is
# CONTAINMENT (glmmTMB fixed inside the credible interval), not pointwise equality. The
# balanced `fixed == random` identity (exact under REML/FIML in M10/M21) holds only
# APPROXIMATELY here (flat prior on rater effects vs half-t on sigma_r) -- characterized, not
# asserted (#18). `data` must be canonicalized to columns `subject`, `rater`, `score` and
# BALANCED/COMPLETE, two-way fixed raters (guarded in icc(): multilevel / incomplete /
# replicate / numeric unit refused).
fit_brms_fixed <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  base <- fit_brms_common(
    formula = stats::as.formula("score ~ 1 + rater + (1 | subject)"),
    spec = c(
      subject = "sd_subject__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )

  # theta^2_r per posterior draw from the rater fixed-effect draws (shared helper, also
  # used by the crossed-multilevel fixed fit in M27).
  theta_draws <- brms_theta2r_draws(base$fit, data, call = call)

  # Inject the rater row (subject, rater, residual order) and its component mode; the
  # Bayesian path reads `draws` for both point and interval (ADR-033), so the log-SD
  # `estimate`/`vcov` contract-completeness slots (subject/residual only) are left untouched.
  base$draws <- rbind(
    subject = base$draws["subject", ],
    rater = theta_draws,
    residual = base$draws["residual", ]
  )
  base$components <- list(
    subject = base$components$subject,
    rater = posterior_mode(theta_draws, lower = 0),
    residual = base$components$residual
  )
  base
}

# Crossed (Design 1) multilevel Bayesian fit (M24 Slice 1, ADR-034): the M5 five-component
# model
#   score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)
# under the SAME sourced half-t(4, 0, 1) prior on EVERY random-effect SD -- literally ten
# Hove, Jorgensen & van der Ark (2020) §3.3/§4.1's specification for this model, the source
# estimator (the frequentist M5 had no worked posterior to match, so the Bayesian path is
# the MORE faithful one). Five components map to the M5 internal names (estimand-spec
# M5-multilevel.md §2):
#   cluster       = sigma^2_c        <- sd_cluster__Intercept
#   subject       = sigma^2_{s:c}    <- sd_cluster:subject__Intercept  (subject in cluster)
#   rater         = sigma^2_r        <- sd_rater__Intercept
#   cluster_rater = sigma^2_{cr}     <- sd_cluster:rater__Intercept
#   residual      = sigma^2_{(s:c)r} <- sigma
# The subject- and cluster-level signal/error maps (M5 §3) are the shipped, engine-agnostic
# estimand machinery in icc(); posterior_summary() composes each ICC's draw vector from
# these five rows exactly as the frequentist path composes it from icc_point(). `data` must
# be canonicalized to columns `subject`, `rater`, `cluster`, `score` and COMPLETE/BALANCED,
# crossed random raters (guarded in icc(): nested / fixed / conflated / incomplete refused).
fit_brms_multilevel <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  fit_brms_common(
    formula = stats::as.formula(
      "score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)"
    ),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      rater = "sd_rater__Intercept",
      cluster_rater = "sd_cluster:rater__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )
}

# Crossed (Design 1) FIXED-rater multilevel Bayesian fit (M27 Slice 1, ADR-037): the M10
# five-component model with raters as POPULATION-LEVEL fixed effects
#   score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)
# -- the brms sibling of fit_glmmtmb_multilevel_fixed() (M10) and of the crossed-random
# fit_brms_multilevel() (M24) with the (1 | rater) random-rater main effect replaced by a
# fixed `rater` effect. The sourced half-t(4, 0, 1) prior applies to the random-effect SDs
# only (sd_cluster, sd_cluster:subject, sd_cluster:rater); the k - 1 rater contrasts carry
# brms's default (flat) population-level prior. Four random components come off the standard
# spec; the rater slot carries theta^2_r, the Case-3A finite-population variance of the k
# fixed rater means (estimand-spec M10 §2), computed PER POSTERIOR DRAW (RAW, no bias
# correction -- see brms_theta2r_draws) and injected as the `rater` row so the `draws`
# contract is the SAME five rows fit_brms_multilevel() produces:
#   cluster       = sigma^2_c     <- sd_cluster__Intercept
#   subject       = sigma^2_{s:c} <- sd_cluster:subject__Intercept
#   rater         = theta^2_r     <- posterior push-forward of the fixed rater means
#   cluster_rater = sigma^2_{cr}  <- sd_cluster:rater__Intercept
#   residual      = sigma^2_res   <- sigma
# The shipped M5/M10 subject-level error-set map ({rater, cluster_rater, residual} for
# agreement, {cluster_rater, residual} for consistency) and posterior_summary() compose each
# ICC off these five rows unchanged. On balanced data theta^2_r ~= sigma^2_r, so the
# subject-level ICCs track the random-rater M24 ones -- but only APPROXIMATELY under the
# prior (flat on rater effects vs half-t on sigma_r), so the oracle is CONTAINMENT (glmmTMB
# fixed inside the credible interval), not pointwise equality (O-Bayes-FML, #18). `data` must
# be canonicalized to columns `subject`, `rater`, `cluster`, `score` and COMPLETE/BALANCED,
# crossed fixed raters, subject level (guarded in icc(): nested / cluster-level / Design-3
# fixed / conflated / incomplete / replicate refused).
fit_brms_multilevel_fixed <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  base <- fit_brms_common(
    formula = stats::as.formula(
      "score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)"
    ),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      cluster_rater = "sd_cluster:rater__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )

  theta_draws <- brms_theta2r_draws(base$fit, data, call = call)

  # Inject the rater row in the M5 five-row order (cluster, subject, rater, cluster_rater,
  # residual) and its component mode; the Bayesian path reads `draws` for both point and
  # interval (ADR-033), so the log-SD estimate/vcov contract slots are left untouched.
  base$draws <- rbind(
    cluster = base$draws["cluster", ],
    subject = base$draws["subject", ],
    rater = theta_draws,
    cluster_rater = base$draws["cluster_rater", ],
    residual = base$draws["residual", ]
  )
  base$components <- list(
    cluster = base$components$cluster,
    subject = base$components$subject,
    rater = posterior_mode(theta_draws, lower = 0),
    cluster_rater = base$components$cluster_rater,
    residual = base$components$residual
  )
  base
}

# Nested Design 2 (raters nested in clusters) multilevel Bayesian fit (M25 Slice 1,
# ADR-035): the M8 four-component model
#   score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)
# under the SAME sourced half-t(4, 0, 1) prior on every random-effect SD (unchanged from
# M23/M24 -- ten Hove, Jorgensen & van der Ark 2020 §3.3/§4.1's specification, which
# generalizes verbatim). Raters are nested in clusters, so there is NO (1 | rater) main
# effect: the rater-in-cluster variance sigma^2_{r:c} lives in the (1 | cluster:rater)
# term and lands in the INTERNAL `rater` slot (not `cluster_rater`) -- Design 2 has no
# separable cluster x rater interaction (sigma^2_cr is confounded away when raters are
# nested; estimand-spec M8 §2a). That naming keeps the brms component set structurally
# identical to the shipped glmmTMB Design-2 contract (fit_glmmtmb_nested_clusters), so the
# shipped subject-level error-set map {rater, residual} / {residual} (estimand.R,
# M8 §3a), the components view, and the reductions all apply unchanged. Four components
# map to the M8 internal names:
#   cluster  = sigma^2_c        <- sd_cluster__Intercept        (nuisance; no cluster ICC)
#   subject  = sigma^2_{s:c}    <- sd_cluster:subject__Intercept (subject in cluster; signal)
#   rater    = sigma^2_{r:c}    <- sd_cluster:rater__Intercept   (rater in cluster)
#   residual = sigma^2_{(sr):c} <- sigma
# `data` must be canonicalized to columns `subject`, `rater`, `cluster`, `score` and
# COMPLETE/BALANCED, nested Design 2 random raters (guarded in icc(): crossed dispatches
# to fit_brms_multilevel; Design 3 / fixed / conflated / incomplete / replicate refused).
fit_brms_nested_clusters <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  fit_brms_common(
    formula = stats::as.formula(
      "score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)"
    ),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      rater = "sd_cluster:rater__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )
}

# Nested Design 3 (raters nested in subjects and clusters) multilevel Bayesian fit (M25
# Slice 2, ADR-035): the M8 three-component model
#   score ~ 1 + (1 | cluster) + (1 | cluster:subject)
# under the SAME sourced half-t(4, 0, 1) prior on every random-effect SD (unchanged from
# M23/M24). Each subject has its OWN raters, so the rater main effect is fully confounded
# into the residual sigma^2_{r:s:c} -- there is NO (1 | rater) and NO (1 | cluster:rater)
# term. This is the MULTILEVEL ONE-WAY design (cf. M6): rater variance is inseparable from
# residual, so consistency is undefined and only agreement ICCs are reported
# (estimand-spec M8 §2b/§3b; the type = "consistency" abort lives in icc()). Three
# components map to the M8 internal names:
#   cluster  = sigma^2_c       <- sd_cluster__Intercept        (nuisance; no cluster ICC)
#   subject  = sigma^2_{s:c}   <- sd_cluster:subject__Intercept (subject in cluster; signal)
#   residual = sigma^2_{r:s:c} <- sigma                         (rater confounded into error)
# The subject-level ICC reads {subject | residual}, the same shape as the M6 one-way, so
# the shipped agnostic posterior_summary() path composes it unchanged. `data` must be
# canonicalized to columns `subject`, `rater`, `cluster`, `score` and COMPLETE/BALANCED,
# nested Design 3 (guarded in icc(): crossed / Design 2 dispatch elsewhere; fixed /
# consistency / incomplete / replicate refused).
fit_brms_nested_subjects <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  fit_brms_common(
    formula = stats::as.formula(
      "score ~ 1 + (1 | cluster) + (1 | cluster:subject)"
    ),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )
}

# Nested Design 2 (raters nested in clusters) FIXED-rater multilevel Bayesian fit (M27
# Slice 2, ADR-037): the M19 Slice 2 model with raters as cell-mean fixed effects
#   score ~ 0 + rater + (1 | cluster:subject)
# -- the brms sibling of fit_glmmtmb_nested_fixed(). Nested rater labels are cluster-
# specific, so `0 + rater` gives each (cluster, rater) its own mean directly, absorbing the
# cluster main effect (irrelevant to the subject level, the only level nested designs
# define). The half-t(4, 0, 1) prior applies to the single random-effect SD
# (sd_cluster:subject); the rater cell means keep brms's default flat prior. Two random
# components come off the standard spec; the rater slot carries theta^2_{r:c}, the
# within-cluster finite-population rater variance averaged over clusters (estimand as M19
# Slice 2 / theta2r_fixed_nested), read RAW per posterior draw (brms_theta2r_nested_draws)
# and injected as the `rater` row so the `draws` contract is the SAME three rows the
# glmmTMB nested-fixed fit produces:
#   subject  = sigma^2_{s:c} <- sd_cluster:subject__Intercept
#   rater    = theta^2_{r:c} <- posterior push-forward of the per-cluster rater means
#   residual = sigma^2_res   <- sigma
# There is NO `cluster` / `cluster_rater` component (the cell-mean fit absorbs the cluster
# main effect; nested Design 2 has no separable cluster x rater term). The shipped M8 §3a
# subject-level error-set map ({rater, residual} for agreement, {residual} for consistency)
# composes each ICC unchanged. Unlike the CROSSED design (M27 Slice 1), fixed != random even
# on balanced data (per-cluster finite population; the M19 catch), so the oracle is
# CONTAINMENT of the glmmTMB REML point, not equality (O-Bayes-FNML, #18). `data` must be
# canonicalized to columns `subject`, `rater`, `cluster`, `score` and COMPLETE/BALANCED,
# nested Design 2 fixed raters, subject level (guarded in icc(): crossed dispatches to
# fit_brms_multilevel_fixed; Design 3 fixed / cluster-level / consistency-where-undefined /
# incomplete / replicate refused).
fit_brms_nested_fixed <- function(
  data,
  seed = NULL,
  brm_args = list(),
  call = rlang::caller_env()
) {
  base <- fit_brms_common(
    formula = stats::as.formula("score ~ 0 + rater + (1 | cluster:subject)"),
    spec = c(
      subject = "sd_cluster:subject__Intercept",
      residual = "sigma"
    ),
    data = data,
    seed = seed,
    brm_args = brm_args,
    call = call
  )

  theta_draws <- brms_theta2r_nested_draws(base$fit, data, call = call)

  # Inject the rater row in the {subject, rater, residual} order the nested subject-level
  # map expects; the Bayesian path reads `draws` for both point and interval (ADR-033).
  base$draws <- rbind(
    subject = base$draws["subject", ],
    rater = theta_draws,
    residual = base$draws["residual", ]
  )
  base$components <- list(
    subject = base$components$subject,
    rater = posterior_mode(theta_draws, lower = 0),
    residual = base$components$residual
  )
  base
}
