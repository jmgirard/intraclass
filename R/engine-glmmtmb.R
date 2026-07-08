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

# Parametric-bootstrap factory shared by every glmmTMB fit shape (ADR-025, M16):
# given a fitted model and an `extract(fit) -> named numeric vector of variance
# components` closure, build the `simulate_refit(boot_samples, seed)` contract that
# `bootstrap_ci()` consumes. The refit formula and data are recovered from the fit
# (`formula(fit)` + `fit$frame`), which round-trips exactly for every shape here
# (two-way, one-way, fixed-rater, and the multilevel designs incl. interaction
# terms), so one factory serves all of them. A refit that errors or whose Hessian is
# not positive-definite is NA-filled (dropped upstream); a refit on the variance
# boundary (a component at 0) is a valid draw and kept, matching the MC boundary
# policy (ADR-003). Seeded via with_rng_seed() so the global RNG is left untouched
# (PRINCIPLES.md #9, #12).
glmmtmb_simulate_refit <- function(fit, extract) {
  na_out <- extract(fit)
  na_out[] <- NA_real_
  form <- stats::formula(fit)
  base_data <- fit$frame
  function(boot_samples, seed = NULL) {
    run <- function() {
      sims <- stats::simulate(fit, nsim = boot_samples)
      refit_one <- function(y) {
        boot_data <- base_data
        boot_data$score <- y
        refit <- tryCatch(
          suppressWarnings(glmmTMB::glmmTMB(
            form,
            data = boot_data,
            REML = TRUE
          )),
          error = function(e) NULL
        )
        if (is.null(refit) || !isTRUE(refit$sdr$pdHess)) {
          return(na_out)
        }
        out <- tryCatch(extract(refit), error = function(e) na_out)
        if (anyNA(out) || any(!is.finite(out))) na_out else out
      }
      vapply(sims, refit_one, na_out)
    }
    if (is.null(seed)) run() else with_rng_seed(seed, run())
  }
}

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
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      rater = as.numeric(attr(fvc$rater, "stddev"))^2,
      residual = stats::sigma(f)^2
    )
  }
  components <- as.list(extract(fit))

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
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}

# One-way engine (raters not crossed; Shrout & Fleiss Case 1) -------------------
#
# M6 (estimand-spec M6-oneway.md): fits the one-way random-effects model
#
#     score ~ 1 + (1 | subject)          -- NO rater term
#
# so the residual confounds the rater main effect with pure error (sigma^2_res =
# sigma^2_r + sigma^2_e). Returns the same six-field contract as fit_glmmtmb()
# with only `subject` and `residual` components; icc_point()/mc_ci() are unchanged
# (the error set is just {residual}). Same log-SD internal scale as fit_glmmtmb().

fit_glmmtmb_oneway <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the ICC model.")

  fit <- withCallingHandlers(
    glmmTMB::glmmTMB(
      score ~ 1 + (1 | subject),
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
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      residual = stats::sigma(f)^2
    )
  }
  components <- as.list(extract(fit))

  vcov_full <- stats::vcov(fit, full = TRUE)
  nm <- colnames(vcov_full)
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  estimate[["(Intercept)"]] <- as.numeric(glmmTMB::fixef(fit)$cond[[
    "(Intercept)"
  ]])
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  estimate[grep("subject", nm)] <- log(as.numeric(attr(vc$subject, "stddev")))

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

  si <- grep("subject", nm)
  di <- which(nm == "disp~(Intercept)")
  to_components <- function(par) {
    list(
      subject = exp(2 * par[si, ]),
      residual = exp(2 * par[di, ])
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}

# Multilevel engine (subjects nested in clusters, raters crossed) ---------------
#
# Design 1 of ten Hove, Jorgensen & van der Ark (2022): raters crossed with both
# subjects and clusters (estimand-spec M5 §2). Fits the five-component model
#
#     score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) + (1|cluster:rater)
#
# returning components named on the estimand's scale:
#   cluster       = sigma^2_c        (between-cluster true score)
#   subject       = sigma^2_{s:c}    (between-subject-within-cluster true score)
#   rater         = sigma^2_r        (rater main effect)
#   cluster_rater = sigma^2_{cr}     (cluster x rater)
#   residual      = sigma^2_{(s:c)r} (confounded highest-order term)
#
# The subject-level ICC reads {subject | rater, residual}; the cluster-level ICC
# reads {cluster | rater, cluster_rater} (M5 §3) -- so icc_point()/mc_ci() are
# UNCHANGED, they just index different named components per the estimand's level.
# `cluster:subject` nesting is used (not a bare subject id) so subject labels need
# not be globally unique. Each grouping factor's internal log-SD lives at the
# parameter "theta_1|<group>.1" (verified against VarCorr); residual at
# "disp~(Intercept)" -- the same log-SD scale as fit_glmmtmb() (ADR-002/003).

# Fit a multilevel glmmTMB model (REML), routing convergence warnings through cli
# (PRINCIPLES.md #8). Shared by every multilevel design (D1/D2/...).
fit_glmmtmb_ml_model <- function(formula, data) {
  withCallingHandlers(
    glmmTMB::glmmTMB(formula, data = data, REML = TRUE),
    warning = function(w) {
      cli::cli_warn(c(
        "The {.pkg glmmTMB} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )
}

# Build the six-field engine contract from a fitted multilevel glmmTMB model.
# `groups` maps component-slot name -> glmmTMB grouping-factor name (the residual
# slot is always appended). Every variance component and Monte-Carlo draw stays on
# glmmTMB's internal log-SD scale (theta_1|<group>.1; residual at
# "disp~(Intercept)"), so draws back-transform to non-negative variances at the
# near-zero boundary (ADR-002/003). One code path for all multilevel designs; each
# design differs only in `groups`.
glmmtmb_ml_contract <- function(fit, groups, call = rlang::caller_env()) {
  vc <- glmmTMB::VarCorr(fit)$cond
  sd_of <- function(g) as.numeric(attr(vc[[g]], "stddev"))
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    out <- vapply(
      groups,
      function(g) as.numeric(attr(fvc[[g]], "stddev"))^2,
      numeric(1)
    )
    c(out, residual = stats::sigma(f)^2)
  }
  components <- as.list(extract(fit))

  vcov_full <- stats::vcov(fit, full = TRUE)
  # `colnames()` here is itself a named vector (cond/disp/theta1...); strip those
  # names so `which()` returns clean positions for the component index map below.
  nm <- unname(colnames(vcov_full))
  theta <- function(g) sprintf("theta_1|%s.1", g)
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  estimate[["(Intercept)"]] <- as.numeric(
    glmmTMB::fixef(fit)$cond[["(Intercept)"]]
  )
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  for (g in unlist(groups, use.names = FALSE)) {
    estimate[[theta(g)]] <- log(sd_of(g))
  }

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

  idx <- c(
    lapply(groups, function(g) which(nm == theta(g))),
    list(residual = which(nm == "disp~(Intercept)"))
  )
  to_components <- function(par) {
    lapply(idx, function(i) exp(2 * par[i, ]))
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}

# Within-cell replicates -- the two-way random model with a subject x rater
# interaction (estimand-spec M17-within-cell-replicates.md §1). Reuses the generic
# multilevel contract: four components (subject, rater, subject_rater, and the pure
# within-cell residual), each on glmmTMB's internal log-SD scale, with the shared
# Monte-Carlo and simulate/refit machinery.
fit_glmmtmb_replicates <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the replicate ICC model.")
  fit <- fit_glmmtmb_ml_model(
    score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater),
    data
  )
  glmmtmb_ml_contract(
    fit,
    groups = list(
      subject = "subject",
      rater = "rater",
      subject_rater = "subject:rater"
    ),
    call = call
  )
}

# Design 1 -- raters crossed with clusters (estimand-spec M5).
fit_glmmtmb_multilevel <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the multilevel ICC model.")
  fit <- fit_glmmtmb_ml_model(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data
  )
  glmmtmb_ml_contract(
    fit,
    groups = list(
      cluster = "cluster",
      subject = "cluster:subject",
      rater = "rater",
      cluster_rater = "cluster:rater"
    ),
    call = call
  )
}

# Design 2 -- raters nested within clusters (estimand-spec M8 §2a; ten Hove et al.
# 2022 Eqs. 8-9). Four components: the rater main effect and cluster x rater
# collapse into r:c, carried in the "rater" slot; the highest-order term is the
# residual (sr):c. There is NO (1|rater) main-effect term -- rater identity lives
# inside cluster:rater (raters nested). Fits
#
#     score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)
#
# Only Design-2's `groups` differs from Design 1; the subject-level estimand map
# (icc_estimand) is UNCHANGED -- "rater" now holds sigma^2_{r:c} and "residual"
# sigma^2_{(sr):c} (estimand-spec M8 §3a). Cluster level is undefined (paper p. 6).
fit_glmmtmb_nested_clusters <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the multilevel ICC model.")
  fit <- fit_glmmtmb_ml_model(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater),
    data
  )
  glmmtmb_ml_contract(
    fit,
    groups = list(
      cluster = "cluster",
      subject = "cluster:subject",
      rater = "cluster:rater" # sigma^2_{r:c}
    ),
    call = call
  )
}

# Design 3 -- raters nested within subjects and clusters (estimand-spec M8 §2b;
# ten Hove et al. 2022 Eqs. 10-11). Each subject has its own raters, so the rater
# variance is fully confounded into the residual sigma^2_{r:s:c}: three components
# (cluster, subject, residual) and NO rater term -- the multilevel one-way design
# (agreement-only). Fits
#
#     score ~ 1 + (1|cluster) + (1|cluster:subject)
#
# The subject-level ICC reads {subject | residual} (spec M8 §3b), the same shape
# as the M6 one-way, so icc_point()/mc_ci() are unchanged.
fit_glmmtmb_nested_subjects <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the multilevel ICC model.")
  fit <- fit_glmmtmb_ml_model(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject),
    data
  )
  glmmtmb_ml_contract(
    fit,
    groups = list(
      cluster = "cluster",
      subject = "cluster:subject"
    ),
    call = call
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

# Bias-corrected finite-population variance of the k fixed rater level means
# (McGraw & Wong 1996, Case 3A; estimand-spec M3 §6 / M10 §2). Shared by the flat
# (fit_glmmtmb_fixed) and multilevel (fit_glmmtmb_multilevel_fixed) fixed engines --
# and, via the same interface, the lme4 fixed engines (M14) -- so it is
# ENGINE-AGNOSTIC: the caller supplies the fixed-effect estimates `beta` and their
# covariance `vbeta` (glmmTMB: `fixef(fit)$cond` / `vcov(fit)$cond`; lme4:
# `fixef(fit)` / `vcov(fit)`), and this helper knows nothing about the fitting
# engine. Raters enter as fixed effects, so the rater main effect is theta^2_r
# rather than a random sigma^2_r. Returns the point estimate plus the fixed pieces
# (contrast, centering, bias, and the fixed-effect names) the Monte-Carlo sampler
# reuses to recompute theta^2_r from the beta draws each iteration. `center = I -
# J/k` removes the grand mean; `bias` subtracts the mean sampling variance of the
# centered means. On BALANCED data the corrected theta^2_r equals the random-fit
# sigma^2_r (M3 §6, verified on SF; M10's balanced fixed == random reduction).
#
# Note on the interval (deliberate, not a defect): the Monte-Carlo sampler recomputes
# `max(0, raw_draws - bias)` each draw with this same constant `bias`, but the drawn
# rater means carry their own sampling variance, so E[raw_draws] = raw + bias and the
# theta^2_r DRAWS center on `raw`, i.e. `bias` above the bias-corrected point. The
# fixed-rater point estimate is therefore not the exact median of its own interval
# (unlike the log-SD components). This is the percentile bootstrap faithfully
# reproducing the estimator's bias correction; coverage of the true theta^2_r stays
# nominal (M3 O6 coverage sim: 0.950/0.947), and `bias` is small relative to the
# sampling SE, so the effect is minor. Recentering would need a pivotal interval and
# its own oracle re-validation (a separate decision), so it is left as documented.
theta2r_fixed <- function(beta, vbeta, k, call = rlang::caller_env()) {
  # Defensive: the k x k contrast needs exactly k fixed-effect coefficients
  # (intercept + k-1 rater contrasts). icc() droplevels() its factors, so a
  # rater-count/beta mismatch (e.g. an unused rater level) is unreachable via the
  # public API, but guard it as a classed error rather than a bare non-conformable
  # crash if an internal caller ever violates it (PRINCIPLES.md #8).
  if (length(beta) != k) {
    abort_intraclass(
      c(
        "The fixed-effect coefficient vector does not match the rater count.",
        i = "Expected {.val {k}} coefficients (intercept + {.val {k - 1}} rater \\
             contrasts) but received {.val {length(beta)}}."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  vbeta <- as.matrix(vbeta)
  contrast <- rater_mean_contrast(k)
  center <- diag(k) - matrix(1 / k, k, k)
  v_means <- contrast %*% vbeta %*% t(contrast)
  bias <- sum(diag(center %*% v_means)) / (k - 1)
  mu <- as.numeric(contrast %*% beta)
  raw <- as.numeric(t(mu) %*% center %*% mu) / (k - 1)
  list(
    point = max(0, raw - bias),
    contrast = contrast,
    center = center,
    bias = bias,
    beta_names = names(beta)
  )
}

# Fixed-rater theta^2 for a NESTED (Design 2) design (M19 Slice 2, ADR-029). Raters
# are nested in clusters -- there is no single common rater set -- so theta^2_{r:c} is
# the WITHIN-cluster bias-corrected finite-population variance of each cluster's k
# rater means (McGraw & Wong Case 3A, as theta2r_fixed()), AVERAGED over clusters.
# Pooling all raters would conflate between-cluster rater location (confounded with
# the cluster main effect) with the within-cluster spread, so the variance is formed
# per cluster then averaged. On balanced data it equals the random-fit sigma^2_{r:c}
# (verified reduction, M8 §3a). ENGINE-AGNOSTIC: `beta`/`vbeta` are the cell-mean
# fixed effects of `score ~ 0 + rater` (nested rater labels) and their covariance;
# `cluster_of` maps each coefficient to its cluster. Returns the point plus the
# per-cluster pieces (center, index groups, bias) the Monte-Carlo sampler reuses to
# recompute theta^2_{r:c} from the beta draws.
theta2r_fixed_nested <- function(
  beta,
  vbeta,
  cluster_of,
  call = rlang::caller_env()
) {
  vbeta <- as.matrix(vbeta)
  cluster_idx <- split(seq_along(beta), cluster_of)
  ks <- lengths(cluster_idx)
  if (length(unique(ks)) != 1L) {
    abort_intraclass(
      c(
        "Every cluster must contribute the same number of rater means for the \\
         fixed-rater nested variance.",
        i = "Cluster rater counts found: {.val {sort(unique(ks))}}."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }
  k <- ks[[1L]]
  center <- diag(k) - matrix(1 / k, k, k)
  per_bias <- vapply(
    cluster_idx,
    function(ix) sum(diag(center %*% vbeta[ix, ix, drop = FALSE])) / (k - 1),
    numeric(1)
  )
  per_raw <- vapply(
    cluster_idx,
    function(ix) {
      mu <- beta[ix]
      as.numeric(t(mu) %*% center %*% mu) / (k - 1)
    },
    numeric(1)
  )
  list(
    point = mean(pmax(0, per_raw - per_bias)),
    center = center,
    cluster_idx = cluster_idx,
    bias = per_bias,
    beta_names = names(beta),
    k = k
  )
}

# Recompute theta^2_{r:c} for a matrix of beta draws (rows = the nested rater cell
# means in `th$beta_names` order, columns = draws), reusing the per-cluster center
# and bias from theta2r_fixed_nested(). Shared by the glmmTMB and lme4 fixed-nested
# `to_components`. As in the flat fixed path (theta2r_fixed()'s note), the drawn means
# carry their own sampling variance, so per cluster the raw draw centers `bias` above
# the point; averaging over clusters is linear, so the same holds for the mean.
theta2r_nested_draws <- function(beta_draws, th) {
  k <- th$k
  per <- Map(
    function(ix, b) {
      m <- beta_draws[ix, , drop = FALSE]
      raw <- colSums(m * (th$center %*% m)) / (k - 1)
      pmax(0, raw - b)
    },
    th$cluster_idx,
    th$bias
  )
  Reduce(`+`, per) / length(per)
}

# Cluster label for each fixed rater coefficient of `score ~ 0 + rater` (names
# "rater<level>"); raters are nested, so each rater level sits in exactly one cluster.
nested_rater_clusters <- function(data, beta_names) {
  map <- tapply(as.character(data$cluster), data$rater, `[`, 1L)
  unname(map[sub("^rater", "", beta_names)])
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
  th <- theta2r_fixed(beta, stats::vcov(fit)$cond, k)

  # The bootstrap recomputes theta^2_r directly from each refit's rater betas (a
  # bias-corrected finite-population quantity, ADR-023) -- more direct than the MC
  # path, which reconstructs it from the beta draws.
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    fth <- theta2r_fixed(glmmTMB::fixef(f)$cond, stats::vcov(f)$cond, k)
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      rater = fth$point,
      residual = stats::sigma(f)^2
    )
  }
  components <- as.list(extract(fit))

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
    means <- th$contrast %*% par[bi, , drop = FALSE]
    raw_draws <- colSums(means * (th$center %*% means)) / (k - 1)
    list(
      subject = exp(2 * par[si, ]),
      rater = pmax(0, raw_draws - th$bias),
      residual = exp(2 * par[di, ])
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}

# Fixed-rater multilevel engine (Design 1 crossed, balanced) -- estimand-spec M10.
# Combines the M5 Design-1 multilevel random structure with the M3 fixed-rater
# treatment: raters enter as FIXED effects, so the rater main effect becomes the
# bias-corrected finite-population theta^2_r (Case 3A, via theta2r_fixed()) carried
# in the "rater" component slot; the cluster x rater interaction stays RANDOM
# (random cluster x fixed rater, the standard mixed-model convention). Fits
#
#   score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)
#
# The subject-level estimand map and icc_point()/mc_ci() are UNCHANGED (only
# theta^2_r vs sigma^2_r fills the rater slot). On balanced data theta^2_r ==
# sigma^2_r, so the subject-level ICCs equal the random-rater M5 ones (oracle
# O-FML/reduction). Cluster-level IRR with fixed raters is deferred (spec M10 §7).
fit_glmmtmb_multilevel_fixed <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("glmmTMB", reason = "to fit the multilevel ICC model.")
  k <- nlevels(data$rater)
  fit <- fit_glmmtmb_ml_model(
    score ~
      1 +
      rater +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | cluster:rater),
    data
  )
  th <- theta2r_fixed(glmmTMB::fixef(fit)$cond, stats::vcov(fit)$cond, k)

  vc <- glmmTMB::VarCorr(fit)$cond
  sd_of <- function(g) as.numeric(attr(vc[[g]], "stddev"))
  # Random slots (cluster, subject-in-cluster, cluster x rater); theta^2_r and the
  # residual are appended so the subject-level map reads {subject | rater, residual}.
  groups <- c(
    cluster = "cluster",
    subject = "cluster:subject",
    cluster_rater = "cluster:rater"
  )
  # Bootstrap extractor: the random slots from VarCorr plus theta^2_r recomputed from
  # each refit's rater betas (ADR-023), the same {subject | rater, residual} map.
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    fth <- theta2r_fixed(glmmTMB::fixef(f)$cond, stats::vcov(f)$cond, k)
    out <- vapply(
      groups,
      function(g) as.numeric(attr(fvc[[g]], "stddev"))^2,
      numeric(1)
    )
    c(out, rater = fth$point, residual = stats::sigma(f)^2)
  }
  components <- as.list(extract(fit))

  vcov_full <- stats::vcov(fit, full = TRUE)
  nm <- unname(colnames(vcov_full))
  theta <- function(g) sprintf("theta_1|%s.1", g)
  beta <- glmmTMB::fixef(fit)$cond
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  # Fixed effects (intercept + rater contrasts) on the natural scale; grouping-
  # factor SDs and the residual on glmmTMB's internal log-SD scale (ADR-002/003).
  estimate[th$beta_names] <- as.numeric(beta)
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  for (g in groups) {
    estimate[[theta(g)]] <- log(sd_of(g))
  }

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

  bi <- match(th$beta_names, nm)
  di <- which(nm == "disp~(Intercept)")
  ridx <- lapply(groups, function(g) which(nm == theta(g)))
  to_components <- function(par) {
    # Random components back-transform from log-SD; theta^2_r is recomputed from the
    # rater beta draws with the constant bias correction (as in fit_glmmtmb_fixed).
    means <- th$contrast %*% par[bi, , drop = FALSE]
    raw_draws <- colSums(means * (th$center %*% means)) / (k - 1)
    c(
      lapply(ridx, function(i) exp(2 * par[i, ])),
      list(
        rater = pmax(0, raw_draws - th$bias),
        residual = exp(2 * par[di, ])
      )
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}

# Design 2 (raters nested in clusters) with raters FIXED (M19 Slice 2, ADR-029). The
# fixed-rater analog of fit_glmmtmb_nested_clusters(): raters are a fixed finite
# population within each cluster, so the rater slot carries the bias-corrected
# theta^2_{r:c} (theta2r_fixed_nested(), averaged over clusters) rather than the random
# sigma^2_{r:c}. Because nested rater labels are cluster-specific, the cell-mean
# parameterization
#
#     score ~ 0 + rater + (1 | cluster:subject)
#
# gives each (cluster, rater) its own mean directly (absorbing the cluster main effect
# -- irrelevant to the subject level, which is all nested designs define). Components
# {subject | rater = theta^2_{r:c}, residual}; the subject-level estimand map and
# icc_point()/mc_ci() are unchanged (M8 §3a).
#
# Unlike the CROSSED fixed design (M10), fixed != random even on balanced data: the
# nested finite population is per-cluster (each cluster's own k raters), so theta^2_{r:c}
# = mean over clusters of the within-cluster finite-population variance, which differs
# from the random pooled sigma^2_{r:c} (they coincide only as k per cluster -> Inf).
# theta^2_{r:c} is pinned instead by reduction to the flat M3 fixed theta^2_r fit
# per cluster then averaged (oracle O-FNML/reduction), and by the single-cluster
# reduction to M3. Balanced/complete only (incomplete fixed-nested deferred, ADR-029).
fit_glmmtmb_nested_fixed <- function(
  data,
  call = rlang::caller_env()
) {
  rlang::check_installed("glmmTMB", reason = "to fit the multilevel ICC model.")
  fit <- fit_glmmtmb_ml_model(
    score ~ 0 + rater + (1 | cluster:subject),
    data
  )
  beta <- glmmTMB::fixef(fit)$cond
  cluster_of <- nested_rater_clusters(data, names(beta))
  th <- theta2r_fixed_nested(beta, stats::vcov(fit)$cond, cluster_of)

  # Bootstrap extractor: subject-in-cluster and residual from VarCorr plus
  # theta^2_{r:c} recomputed from each refit's rater cell means, the same
  # {subject | rater, residual} map.
  extract <- function(f) {
    fvc <- glmmTMB::VarCorr(f)$cond
    fth <- theta2r_fixed_nested(
      glmmTMB::fixef(f)$cond,
      stats::vcov(f)$cond,
      cluster_of
    )
    c(
      subject = as.numeric(attr(fvc[["cluster:subject"]], "stddev"))^2,
      rater = fth$point,
      residual = stats::sigma(f)^2
    )
  }
  components <- as.list(extract(fit))

  vcov_full <- stats::vcov(fit, full = TRUE)
  nm <- unname(colnames(vcov_full))
  sd_subject <- as.numeric(
    attr(glmmTMB::VarCorr(fit)$cond[["cluster:subject"]], "stddev")
  )
  estimate <- stats::setNames(rep(NA_real_, length(nm)), nm)
  # Fixed rater cell means on the natural scale; the subject-in-cluster SD and the
  # residual on glmmTMB's internal log-SD scale (ADR-002/003).
  estimate[th$beta_names] <- as.numeric(beta)
  estimate[["disp~(Intercept)"]] <- log(stats::sigma(fit))
  estimate[["theta_1|cluster:subject.1"]] <- log(sd_subject)

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

  bi <- match(th$beta_names, nm)
  di <- which(nm == "disp~(Intercept)")
  si <- which(nm == "theta_1|cluster:subject.1")
  to_components <- function(par) {
    list(
      subject = exp(2 * par[si, ]),
      rater = theta2r_nested_draws(par[bi, , drop = FALSE], th),
      residual = exp(2 * par[di, ])
    )
  }

  list(
    fit = fit,
    engine = "glmmTMB",
    components = components,
    estimate = estimate,
    vcov = vcov_full,
    to_components = to_components,
    simulate_refit = glmmtmb_simulate_refit(fit, extract)
  )
}
