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

# Parametric-bootstrap factory shared by every lme4 fit shape (ADR-025, M16): lme4's
# native lme4::bootMer is the purpose-built simulate()+refit loop -- it simulates
# from the fit, refits, and applies `extract(refit) -> named numeric components` to
# each refit. Returns the shared (component x resample) matrix `bootstrap_ci()`
# consumes. A refit that collapses to a singular (boundary) fit still yields a valid
# draw with a component at 0 (KEPT, matching the MC boundary policy and the glmmTMB
# path); only a genuine refit failure is NA-filled by bootMer and dropped upstream.
# merDeriv is not needed for the bootstrap (no covariance is formed), but the lme4
# fits require it up front for the Monte-Carlo default; that requirement is unchanged.
# Seeded via with_rng_seed() for RNG hygiene (#9, #12).
lme4_bootmer_refit <- function(fit, extract) {
  function(boot_samples, seed = NULL) {
    run <- function() {
      boot <- suppressWarnings(suppressMessages(lme4::bootMer(
        fit,
        FUN = extract,
        nsim = boot_samples,
        type = "parametric"
      )))
      t(boot$t)
    }
    if (is.null(seed)) run() else with_rng_seed(seed, run())
  }
}

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
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  vc <- lme4::VarCorr(fit)
  sd_subject <- as.numeric(attr(vc$subject, "stddev"))
  sd_rater <- as.numeric(attr(vc$rater, "stddev"))
  sd_res <- as.numeric(stats::sigma(fit))
  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      rater = as.numeric(attr(fvc$rater, "stddev"))^2,
      residual = as.numeric(stats::sigma(f))^2
    )
  }
  components <- as.list(extract(fit))

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

  # Parametric-bootstrap support (ADR-025, M16): lme4's native lme4::bootMer is the
  # purpose-built analogue of the glmmTMB simulate()+refit loop -- it simulates from
  # the fit, refits, and applies FUN to each refit. FUN returns the variance
  # components, so a refit that collapses to a singular (boundary) fit still yields
  # a valid draw with a component at 0 (KEPT, matching the MC boundary policy and the
  # glmmTMB bootstrap path); only a genuine refit failure becomes NA (bootMer fills
  # it), dropped upstream. Returns the shared (component x resample) matrix.
  # Note: merDeriv is not needed for the bootstrap (no covariance is formed), but
  # fit_lme4() requires it up front for the Monte-Carlo default; that requirement is
  # unchanged here. Seeded via with_rng_seed() for RNG hygiene (#9, #12).
  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}

# One-way lme4 engine (M6; raters not crossed) ---------------------------------
#
# The one-way counterpart of fit_glmmtmb_oneway(): `score ~ 1 + (1 | subject)`
# with NO rater term, only `subject` and `residual` components. Same merDeriv ->
# log-SD delta transform and singular-fit guard as fit_lme4(); see that function's
# header for the rationale (ADR-012).

fit_lme4_oneway <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the ICC model with lme4.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )

  fit <- withCallingHandlers(
    lme4::lmer(
      score ~ 1 + (1 | subject),
      data = data,
      REML = TRUE
    ),
    warning = function(w) {
      cli::cli_warn(c(
        "The {.pkg lme4} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  vc <- lme4::VarCorr(fit)
  sd_subject <- as.numeric(attr(vc$subject, "stddev"))
  sd_res <- as.numeric(stats::sigma(fit))
  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      residual = as.numeric(stats::sigma(f))^2
    )
  }
  components <- as.list(extract(fit))

  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)
  idx <- c(
    intercept = which(nm_sd == "(Intercept)"),
    subject = grep("subject", nm_sd),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != 3L || anyNA(idx)) {
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

  jac <- diag(c(1, 1 / sd_subject, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)

  slots <- c("(Intercept)", "subject", "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(
      as.numeric(lme4::fixef(fit)[["(Intercept)"]]),
      log(sd_subject),
      log(sd_res)
    ),
    slots
  )

  to_components <- function(par) {
    list(
      subject = exp(2 * par["subject", ]),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}

# Fixed-rater lme4 engine (two-way, Case 3/3A, subject level, balanced; M14) ----
#
# The lme4 counterpart of fit_glmmtmb_fixed(): raters enter as FIXED effects, so
# the rater main effect is the bias-corrected finite-population theta^2_r (McGraw &
# Wong 1996 Case 3A) rather than a random sigma^2_r. Fits
#
#   score ~ 1 + rater + (1 | subject)
#
# by REML and returns the SAME six-field engine contract as fit_glmmtmb_fixed(), so
# icc_point()/mc_ci()/d_study() are unchanged -- a second engine, not a new estimand
# (ADR-023; cf. the random two-way fit_lme4()). The theta^2_r machinery is the
# shared, engine-agnostic theta2r_fixed() (fed lme4's own fixef()/vcov() here), so
# the estimand cannot drift from the glmmTMB engine.
#
# The one new piece vs. fit_lme4() is that the fixed rater coefficients participate
# in the Monte-Carlo CI: theta^2_r is recomputed from the fixed-effect beta draws
# each iteration (as in fit_glmmtmb_fixed). merDeriv's full covariance supplies the
# JOINT covariance of (betas, subject SD, residual SD). We delta-transform ONLY the
# two SD terms to the log-SD scale (Jacobian 1/sd) and leave the betas on their
# natural scale (Jacobian 1), matching glmmTMB's vcov(fit, full = TRUE): betas
# natural, variance parameters on log-SD (ADR-012/ADR-003). Balanced AND incomplete
# data (M15 Slice 2, ADR-024): nothing here assumes balance -- lmer fits the ragged
# design and theta2r_fixed() reads lme4's incomplete-data vcov, so the
# theta^2_r-under-imbalance correction is automatic; a ragged fit that hits the
# variance boundary aborts toward glmmTMB via the isSingular() guard above.
fit_lme4_fixed <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the ICC model with lme4.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  k <- nlevels(data$rater)

  fit <- withCallingHandlers(
    lme4::lmer(
      score ~ 1 + rater + (1 | subject),
      data = data,
      REML = TRUE
    ),
    warning = function(w) {
      cli::cli_warn(c(
        "The {.pkg lme4} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )

  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  vc <- lme4::VarCorr(fit)
  sd_subject <- as.numeric(attr(vc$subject, "stddev"))
  sd_res <- as.numeric(stats::sigma(fit))
  beta <- lme4::fixef(fit)
  th <- theta2r_fixed(beta, stats::vcov(fit), k)

  # Bootstrap recomputes theta^2_r directly from each refit's rater betas (ADR-023).
  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    fth <- theta2r_fixed(lme4::fixef(f), stats::vcov(f), k)
    c(
      subject = as.numeric(attr(fvc$subject, "stddev"))^2,
      rater = fth$point,
      residual = as.numeric(stats::sigma(f))^2
    )
  }
  components <- as.list(extract(fit))

  # merDeriv's SD-scale joint covariance of (betas, subject SD, residual SD). The
  # fixed-effect columns are named exactly as fixef(fit) (verified: "(Intercept)",
  # "raterJ2", ...); the subject SD is "cov_subject.(Intercept)" and the residual
  # SD is "residual". Fixed effects contain neither "subject" nor "residual", so the
  # SD columns are unambiguous.
  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)
  beta_nm <- names(beta)
  idx <- c(
    match(beta_nm, nm_sd),
    subject = grep("subject", nm_sd),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != length(beta_nm) + 2L || anyNA(idx)) {
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

  # Delta-transform SD-scale -> log-SD scale: identity for every fixed effect (kept
  # natural, as glmmTMB does) and 1/sd for each of the two SD terms, so exp(2 * draw)
  # is strictly positive (boundary-aware, #3) and the beta draws stay on the scale
  # theta2r_fixed()'s contrast expects.
  jac <- diag(c(rep(1, length(beta_nm)), 1 / sd_subject, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)

  slots <- c(beta_nm, "subject", "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(as.numeric(beta), log(sd_subject), log(sd_res)),
    slots
  )

  # Per draw: reconstruct the k rater means from the fixed-effect beta draws, apply
  # the SAME bias-corrected theta^2_r (bias is constant), clamp at 0 -- identical to
  # fit_glmmtmb_fixed()'s to_components(). subject/residual back-transform from log-SD.
  to_components <- function(par) {
    means <- th$contrast %*% par[beta_nm, , drop = FALSE]
    raw_draws <- colSums(means * (th$center %*% means)) / (k - 1)
    list(
      subject = exp(2 * par["subject", ]),
      rater = pmax(0, raw_draws - th$bias),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}

# Multilevel lme4 engines (M14 Slice 2/3, ADR-023) -----------------------------
#
# The lme4 counterparts of the glmmTMB multilevel fits: the same random-effects
# models (ten Hove et al. 2022 Designs 1-3), fit by REML, returning the SAME
# six-field engine contract as glmmtmb_ml_contract() so the estimand map and
# icc_point()/mc_ci() are unchanged. As with fit_lme4()/fit_lme4_fixed(), merDeriv
# supplies the joint covariance of the variance-component SDs (which base lme4 does
# not expose) and we delta-transform every SD to glmmTMB's log-SD scale so MC draws
# back-transform to non-negative variances at the boundary (ADR-012/003). Only the
# Design-1 crossed random path ships in Slice 2; Designs 2/3 and multilevel-fixed
# follow in Slice 3, reusing this machinery.

fit_lme4_ml_model <- function(formula, data) {
  withCallingHandlers(
    lme4::lmer(formula, data = data, REML = TRUE),
    warning = function(w) {
      cli::cli_warn(c(
        "The {.pkg lme4} engine reported a fitting warning.",
        i = conditionMessage(w)
      ))
      invokeRestart("muffleWarning")
    }
  )
}

# Build the six-field engine contract from a fitted multilevel lme4 model. `groups`
# maps component-slot name -> lme4 grouping-factor name (the VarCorr / merDeriv
# label; the residual slot is always appended) -- the same interface as
# glmmtmb_ml_contract(), so multilevel designs differ only in `groups`. merDeriv
# names each random-effect SD column "cov_<group>.(Intercept)"; we align by EXACT
# name (not grep) because interaction groups nest as substrings (e.g. "rater" is a
# substring of "cluster:rater").
lme4_ml_contract <- function(fit, groups, call = rlang::caller_env()) {
  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  vc <- lme4::VarCorr(fit)
  sd_of <- function(g) as.numeric(attr(vc[[g]], "stddev"))
  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    out <- vapply(
      groups,
      function(g) as.numeric(attr(fvc[[g]], "stddev"))^2,
      numeric(1)
    )
    c(out, residual = as.numeric(stats::sigma(f))^2)
  }
  components <- as.list(extract(fit))

  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)
  col_of <- function(g) {
    i <- which(nm_sd == sprintf("cov_%s.(Intercept)", g))
    if (length(i) == 1L) i else NA_integer_
  }
  idx <- c(
    intercept = which(nm_sd == "(Intercept)"),
    vapply(groups, col_of, integer(1)),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != length(groups) + 2L || anyNA(idx)) {
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

  sds <- vapply(groups, sd_of, numeric(1))
  sd_res <- as.numeric(stats::sigma(fit))
  # Intercept on its natural scale (Jacobian 1); every SD on log-SD (Jacobian 1/sd).
  jac <- diag(c(1, 1 / sds, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)

  slots <- c("(Intercept)", names(groups), "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(as.numeric(lme4::fixef(fit)[["(Intercept)"]]), log(sds), log(sd_res)),
    slots
  )

  comp_slots <- c(names(groups), "residual")
  to_components <- function(par) {
    stats::setNames(
      lapply(comp_slots, function(s) exp(2 * par[s, ])),
      comp_slots
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}

# Within-cell replicates -- the two-way random model with a subject x rater
# interaction (estimand-spec M17-within-cell-replicates.md); the lme4 counterpart of
# fit_glmmtmb_replicates(). Four components (subject, rater, subject_rater, residual)
# through the shared multilevel contract; a singular boundary fit defers to glmmTMB.
fit_lme4_replicates <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the replicate ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  fit <- fit_lme4_ml_model(
    score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater),
    data
  )
  lme4_ml_contract(
    fit,
    groups = list(
      subject = "subject",
      rater = "rater",
      subject_rater = "subject:rater"
    ),
    call = call
  )
}

# Design 1 -- raters crossed with clusters (estimand-spec M5); the lme4 counterpart
# of fit_glmmtmb_multilevel(). Five components (cluster, subject-in-cluster, rater,
# cluster x rater, residual). Balanced/complete crossed random only in Slice 2.
fit_lme4_multilevel <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the multilevel ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  fit <- fit_lme4_ml_model(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data
  )
  lme4_ml_contract(
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

# Design 2 -- raters nested within clusters (estimand-spec M8 §2a); the lme4
# counterpart of fit_glmmtmb_nested_clusters(). Four components: no (1|rater) main
# effect (rater identity lives inside cluster:rater), so the "rater" slot carries
# sigma^2_{r:c} and the residual is sigma^2_{(sr):c}. Only `groups` differs from
# Design 1 (spec M8 §3a); the estimand map is unchanged. Subject level only.
fit_lme4_nested_clusters <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the multilevel ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  fit <- fit_lme4_ml_model(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater),
    data
  )
  lme4_ml_contract(
    fit,
    groups = list(
      cluster = "cluster",
      subject = "cluster:subject",
      rater = "cluster:rater" # sigma^2_{r:c}
    ),
    call = call
  )
}

# Design 3 -- raters nested within subjects and clusters (estimand-spec M8 §2b); the
# lme4 counterpart of fit_glmmtmb_nested_subjects(). Three components (cluster,
# subject, residual) and NO rater term -- the multilevel one-way design
# (agreement-only): the rater variance is fully confounded into sigma^2_{r:s:c}.
fit_lme4_nested_subjects <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the multilevel ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  fit <- fit_lme4_ml_model(
    score ~ 1 + (1 | cluster) + (1 | cluster:subject),
    data
  )
  lme4_ml_contract(
    fit,
    groups = list(
      cluster = "cluster",
      subject = "cluster:subject"
    ),
    call = call
  )
}

# Fixed-rater multilevel lme4 engine (Design 1 crossed, balanced; estimand-spec
# M10). The lme4 counterpart of fit_glmmtmb_multilevel_fixed(): combines the M5
# Design-1 random structure with the M3 fixed-rater treatment -- raters enter as
# FIXED effects, so the rater main effect is the bias-corrected finite-population
# theta^2_r (Case 3A, via the shared theta2r_fixed()) carried in the "rater" slot;
# the cluster x rater interaction stays random. Fits
#
#   score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)
#
# This is the multilevel generalization of fit_lme4_fixed() (multiple random groups)
# and, equivalently, the fixed-rater generalization of lme4_ml_contract() (a theta^2_r
# rater slot recomputed from the beta draws) -- so it is written explicitly rather
# than routed through either. The subject-level estimand map and icc_point()/mc_ci()
# are unchanged (only theta^2_r vs sigma^2_r fills the rater slot). On balanced data
# theta^2_r == sigma^2_r, so the subject-level ICCs equal the random-rater ones.
fit_lme4_multilevel_fixed <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the multilevel ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  k <- nlevels(data$rater)
  fit <- fit_lme4_ml_model(
    score ~
      1 +
      rater +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | cluster:rater),
    data
  )
  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  # Random slots (cluster, subject-in-cluster, cluster x rater); theta^2_r and the
  # residual are appended so the subject-level map reads {subject | rater, residual}.
  groups <- list(
    cluster = "cluster",
    subject = "cluster:subject",
    cluster_rater = "cluster:rater"
  )
  vc <- lme4::VarCorr(fit)
  sd_of <- function(g) as.numeric(attr(vc[[g]], "stddev"))
  sds <- vapply(groups, sd_of, numeric(1))
  sd_res <- as.numeric(stats::sigma(fit))
  beta <- lme4::fixef(fit)
  th <- theta2r_fixed(beta, stats::vcov(fit), k)

  # Bootstrap extractor: random slots plus theta^2_r from each refit's rater betas.
  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    fth <- theta2r_fixed(lme4::fixef(f), stats::vcov(f), k)
    out <- vapply(
      groups,
      function(g) as.numeric(attr(fvc[[g]], "stddev"))^2,
      numeric(1)
    )
    c(out, rater = fth$point, residual = as.numeric(stats::sigma(f))^2)
  }
  components <- as.list(extract(fit))

  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)
  beta_nm <- names(beta)
  col_of <- function(g) {
    i <- which(nm_sd == sprintf("cov_%s.(Intercept)", g))
    if (length(i) == 1L) i else NA_integer_
  }
  idx <- c(
    match(beta_nm, nm_sd),
    vapply(groups, col_of, integer(1)),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != length(beta_nm) + length(groups) + 1L || anyNA(idx)) {
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

  # Identity block for every fixed effect (kept natural, so the beta draws stay on
  # the scale theta2r_fixed()'s contrast expects); 1/sd for each SD term (log-SD).
  jac <- diag(c(rep(1, length(beta_nm)), 1 / sds, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)

  slots <- c(beta_nm, names(groups), "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(as.numeric(beta), log(sds), log(sd_res)),
    slots
  )

  # Random components back-transform from log-SD; theta^2_r is recomputed from the
  # rater beta draws with the constant bias correction (as in fit_lme4_fixed()).
  to_components <- function(par) {
    means <- th$contrast %*% par[beta_nm, , drop = FALSE]
    raw_draws <- colSums(means * (th$center %*% means)) / (k - 1)
    c(
      stats::setNames(
        lapply(names(groups), function(s) exp(2 * par[s, ])),
        names(groups)
      ),
      list(
        rater = pmax(0, raw_draws - th$bias),
        residual = exp(2 * par["residual", ])
      )
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}

# Fixed-rater Design 2 (raters nested in clusters) lme4 engine (M19 Slice 2, ADR-029);
# the lme4 counterpart of fit_glmmtmb_nested_fixed(). Raters are a fixed finite
# population within each cluster, so the rater slot carries the bias-corrected
# theta^2_{r:c} (theta2r_fixed_nested(), averaged over clusters) via the cell-mean
# parameterization
#
#   score ~ 0 + rater + (1 | cluster:subject)
#
# (nested rater labels give each cluster its own cell means, absorbing the cluster main
# effect). One random group (subject-in-cluster) + residual; merDeriv supplies their
# SD-scale covariance, delta-transformed to log-SD, while the fixed cell means keep the
# natural scale theta2r_fixed_nested() expects. As in glmmTMB, fixed != random even on
# balanced data (per-cluster finite population). Balanced/complete only (guarded in
# icc()); a singular boundary fit defers to glmmTMB as elsewhere (ADR-012).
fit_lme4_nested_fixed <- function(data, call = rlang::caller_env()) {
  rlang::check_installed("lme4", reason = "to fit the multilevel ICC model.")
  rlang::check_installed(
    "merDeriv",
    reason = "to compute lme4 Monte-Carlo confidence intervals."
  )
  fit <- fit_lme4_ml_model(score ~ 0 + rater + (1 | cluster:subject), data)
  if (lme4::isSingular(fit)) {
    abort_intraclass(
      c(
        "The {.pkg lme4} engine cannot return an interval for a singular \\
         (boundary) fit.",
        i = "A variance component was estimated at exactly zero; the \\
             {.pkg lme4} engine defers boundary fits to the boundary-robust \\
             default (its {.pkg merDeriv} covariance is singular there, and a \\
             bootstrap resamples degenerately).",
        i = "Use {.code engine = \"glmmTMB\"} (for either {.arg ci_method}), \\
             which stays finite here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  beta <- lme4::fixef(fit)
  cluster_of <- nested_rater_clusters(data, names(beta))
  th <- theta2r_fixed_nested(beta, stats::vcov(fit), cluster_of)
  sd_subject <- as.numeric(
    attr(lme4::VarCorr(fit)[["cluster:subject"]], "stddev")
  )
  sd_res <- as.numeric(stats::sigma(fit))

  extract <- function(f) {
    fvc <- lme4::VarCorr(f)
    fth <- theta2r_fixed_nested(lme4::fixef(f), stats::vcov(f), cluster_of)
    c(
      subject = as.numeric(attr(fvc[["cluster:subject"]], "stddev"))^2,
      rater = fth$point,
      residual = as.numeric(stats::sigma(f))^2
    )
  }
  components <- as.list(extract(fit))

  vcov_sd <- as.matrix(merDeriv::vcov.lmerMod(fit, full = TRUE, ranpar = "sd"))
  nm_sd <- colnames(vcov_sd)
  beta_nm <- names(beta)
  idx <- c(
    match(beta_nm, nm_sd),
    subject = which(nm_sd == "cov_cluster:subject.(Intercept)"),
    residual = which(nm_sd == "residual")
  )
  if (length(idx) != length(beta_nm) + 2L || anyNA(idx)) {
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

  # Identity for the fixed cell means (kept natural for theta2r_fixed_nested()); 1/sd
  # for the subject SD and residual (log-SD scale, ADR-002/003).
  jac <- diag(c(rep(1, length(beta_nm)), 1 / sd_subject, 1 / sd_res))
  vcov_log <- jac %*% vcov_sd %*% t(jac)
  slots <- c(beta_nm, "subject", "residual")
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(as.numeric(beta), log(sd_subject), log(sd_res)),
    slots
  )

  to_components <- function(par) {
    list(
      subject = exp(2 * par["subject", ]),
      rater = theta2r_nested_draws(par[beta_nm, , drop = FALSE], th),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "lme4",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    simulate_refit = lme4_bootmer_refit(fit, extract)
  )
}
