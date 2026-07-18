# lavaan (SEM) engine (selectable optional engine, M7 / ADR-014) ---------------
#
# Promotes lavaan to a selectable `engine = "lavaan"` for the random two-way path,
# via the generalizability-theory-as-SEM formulation of Jorgensen (2021). Returns
# the SAME six-field engine contract as fit_glmmtmb() -- `components`, `estimate`,
# `vcov`, `to_components` -- so icc_point()/mc_ci()/d_study() are unchanged.
#
# THE SEM PARAMETERIZATION (estimand mapping, ADR-014). lavaan wants WIDE data
# (one row per subject, one column per rater), so the long `icc()` frame is
# reshaped. The two-way model  score_ij = mu + s_i + r_j + e_ij  maps to a
# one-factor CFA with the subject as a common factor loading 1 on every
# rater-indicator and a single shared indicator residual variance:
#     subj =~ 1*v1 + ... + 1*vk        (factor variance  = sigma^2_s)
#     v1 ~~ ev*v1 ; ... ; vk ~~ ev*vk  (equal residuals  = sigma^2_res)
# CONSISTENCY reads sigma^2_s / (sigma^2_s + sigma^2_res) straight off the
# covariance structure -- a ratio, so it equals the mixed-model estimate exactly
# on balanced data (oracle: lavaan == glmmTMB to ~1e-4).
#
# ABSOLUTE AGREEMENT needs the rater main effect, which in this single-group
# layout lives ONLY in the means: a rater is one column, so its effect is a
# constant offset (an indicator intercept), not a covariance. Jorgensen's (2021)
# insight is that sigma^2_r can be recovered from the mean structure as a defined
# parameter WITHOUT a transposed-data-matrix SEM: with the item intercepts
# effects-coded to sum to zero (so the factor mean equals the grand mean and each
# intercept nu_j is the rater effect mu_j - mu), the rater variance component is
# the sample variance of those intercepts (Jorgensen 2021, Eq. 6; Vispoel, Hong,
# Lee & Xu 2022, Eq. 4):
#
#     sigma^2_r = sum_j (nu_j)^2 / (k - 1).                       [raw, NO bias correction]
#
# This is a DIFFERENT estimator of sigma^2_r than the mixed model's random-effect
# variance: it is the raw variance of the k estimated rater means, so it omits the
# ANOVA/REML "- sigma^2_res / n_subjects" term. The two are asymptotically
# equivalent and match GENOVA / lme4 / the archived `gtheory` package to ~1e-3 on real (large-N) data
# (Vispoel et al. 2022, Table 3: they agree to <= .001 on G-coefs, <= .005 on
# D-coefs), but on a small design the SEM value differs by O(1 / n_subjects). On
# the 6-subject Shrout & Fleiss data lavaan gives ICC(A,1) = 0.284 vs the
# mixed-model 0.290 -- a documented small-sample difference, NOT a bug (an earlier
# draft "corrected" this with an unsourced bias term; removed, ADR-014). The
# agreement oracle is therefore the exact Eq. 6 formula plus a large-N convergence
# check, not the mixed-model number (data-raw/oracle-sem.R).
#
# CONFIDENCE INTERVALS. Jorgensen (2021) obtains a Monte-Carlo CI for the defined
# parameters (corroborating ADR-003); we reuse the package's existing MC path. The
# variance components sigma^2_s / sigma^2_res are put on the log-SD scale (as
# glmmTMB/lme4 do) so draws back-transform strictly positive (#3); the intercepts
# stay on their natural scale and feed sigma^2_r = sum(nu^2)/(k-1) per draw (a
# non-negative quadratic form, so no clamping). A Heywood case (a non-positive
# variance at the point estimate) cannot be log-transformed and aborts loudly,
# pointing at the boundary-robust glmmTMB engine (#5/#8) -- the lavaan analog of
# the lme4 singular-fit guard (ADR-012).
#
# ESTIMATION. `likelihood = "wishart"` (the N-1 sample covariance) is used so the
# variance components match the package's REML mixed-model spine (and the
# classical published values) on balanced data; ML's N divisor would shrink them
# and break the consistency oracle. On large N the choice is immaterial (Vispoel
# et al. 2022).
#
# `data` must already be canonicalized to columns `subject`, `rater`, `score`
# (factors for the first two) and COMPLETE/BALANCED (guarded in icc()); incomplete
# SEM (FIML) is deferred (ADR-014).
#
# BOOTSTRAP (M21 Slice 1, ADR-031). Beyond the Monte-Carlo default, the SEM engine
# also serves `ci_method = "bootstrap"` through the M16 `simulate_refit` contract
# (ADR-025): a PARAMETRIC bootstrap that simulates wide datasets from the fitted
# model's implied moments, refits the same one-factor model to each, and recomputes
# the ICC per resample (cf. glmmtmb_simulate_refit / lme4_bootmer_refit). This is the
# lavaan analog of the lme4 bootMer path; no new estimand, no new argument.
#
# FIXED RATERS (M21 Slice 2, ADR-031). The SEM FIT is identical for random and fixed
# raters -- in this layout the rater effects always live in the mean structure as the
# k indicator intercepts nu_j (there is no random rater term to drop). Only the rater
# COMPONENT read off the fit differs, exactly as in the mixed model (M2/M3/M10):
#   * RANDOM raters -> the raw indicator-mean variance sigma^2_r = sum(nu^2)/(k-1)
#     (Jorgensen 2021 Eq. 6), which overstates the finite-rater variance by the mean
#     sampling variance of the estimated means (the omitted "- sigma^2_res/n" term).
#   * FIXED raters -> the McGraw & Wong Case-3A bias-corrected finite-population
#     theta^2_r = max(0, raw - bias), bias = tr(center %*% V_nu)/(k-1), with V_nu the
#     covariance block of the intercepts from lavaan's vcov(). This is theta2r_fixed()'s
#     correction with the IDENTITY contrast, because the SEM intercepts ARE the k rater
#     means (the mixed model needs rater_mean_contrast() to reconstruct them from
#     treatment-coded betas). On BALANCED data theta^2_r equals BOTH glmmTMB's Case-3A
#     fixed theta^2_r AND its random sigma^2_r (the M10 balanced fixed==random identity),
#     so lavaan's fixed agreement recovers the mixed-model value the raw estimator does
#     not (SF ICC(A,1): raw 0.284 -> corrected ~0.290). Consistency is a ratio that omits
#     the rater term, so it is identical to the random case. The MC/bootstrap draws apply
#     the same correction per draw/refit (constant `bias` for MC, per-refit for the
#     bootstrap -- cf. fit_glmmtmb_fixed()).

# Pull the three variance components (subject, rater, residual) from a fitted lavaan
# two-way model, given `k`, the effects-coding recentring matrix `center`, and whether
# raters are random or fixed. Returns NULL on a Heywood boundary (a non-positive
# subject or residual variance): the point-estimate path (fit_lavaan) turns that into a
# classed abort (#5/#8), while the bootstrap factory treats it as an invalid resample
# (NA-filled, subject to the discard policy). For RANDOM raters the rater slot is the
# raw indicator-mean variance sum(nu^2)/(k-1) (Jorgensen 2021 Eq. 6, a non-negative
# quadratic form). For FIXED raters it is the Case-3A bias-corrected finite-population
# theta^2_r = max(0, raw - bias) -- see fit_lavaan()'s FIXED RATERS note.
lavaan_components <- function(fit, k, center, raters = "random") {
  co <- lavaan::coef(fit)
  cn <- names(co)
  sv <- unname(co[[which(cn == "sv")[1]]])
  ev <- unname(co[[which(cn == "ev")[1]]])
  if (!is.finite(sv) || !is.finite(ev) || sv <= 0 || ev <= 0) {
    return(NULL)
  }
  nu_i <- which(grepl("~1$", cn))
  nu <- unname(co[nu_i])
  raw <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)
  sigma2_r <- if (identical(raters, "fixed")) {
    v_nu <- as.matrix(lavaan::vcov(fit))[nu_i, nu_i, drop = FALSE]
    max(0, raw - sum(diag(center %*% v_nu)) / (k - 1))
  } else {
    raw
  }
  c(subject = sv, rater = sigma2_r, residual = ev)
}

# Parametric-bootstrap factory for the lavaan engine (M21 Slice 1, ADR-031). Closes
# over the fitted SEM's implied mean/covariance and subject count; each call
# simulates `boot_samples` wide datasets, refits the SAME model string with the SAME
# estimation options, and returns a (component x resample) matrix on the shared
# component names -- the `simulate_refit(boot_samples, seed)` contract bootstrap_ci()
# consumes. A refit that errors, does not converge, or lands on a Heywood boundary is
# NA-filled and dropped upstream by the discard policy (#5/#8). Seeded via
# with_rng_seed() so the global RNG stream is left untouched (#9, #12).
lavaan_simulate_refit <- function(fit, model, k, center, raters = "random") {
  inds <- paste0("v", seq_len(k))
  na_out <- c(subject = NA_real_, rater = NA_real_, residual = NA_real_)
  implied <- lavaan::lavInspect(fit, "implied")
  mu <- stats::setNames(as.numeric(implied$mean[inds]), inds)
  covariance <- implied$cov[inds, inds, drop = FALSE]
  n_subjects <- lavaan::lavInspect(fit, "nobs")
  function(boot_samples, seed = NULL) {
    run <- function() {
      refit_one <- function(i) {
        # rmvn() returns parameters x draws (k x n_subjects); transpose to the wide
        # one-row-per-subject layout lavaan wants.
        wide_df <- as.data.frame(t(rmvn(n_subjects, mu, covariance)))
        names(wide_df) <- inds
        refit <- tryCatch(
          suppressWarnings(lavaan::lavaan(
            model,
            data = wide_df,
            meanstructure = TRUE,
            int.ov.free = TRUE,
            int.lv.free = FALSE,
            likelihood = "wishart",
            information = "observed"
          )),
          error = function(e) NULL
        )
        if (is.null(refit) || !lavaan::lavInspect(refit, "converged")) {
          return(na_out)
        }
        out <- lavaan_components(refit, k, center, raters)
        if (is.null(out) || anyNA(out) || any(!is.finite(out))) na_out else out
      }
      vapply(seq_len(boot_samples), refit_one, na_out)
    }
    if (is.null(seed)) run() else with_rng_seed(seed, run())
  }
}

# The two-level CFA model string for k rater-indicators (M54): within = subject
# factor (svw, unit loadings) + equal within residuals (evw); between = cluster
# factor (svb, unit loadings) + equal between residuals (evb) + free indicator
# intercepts (the rater main effects; within intercepts stay fixed at 0). Shared
# by the point fit and the M56 bootstrap refit so both fit the identical model.
lavaan_multilevel_model <- function(k) {
  inds <- paste0("v", seq_len(k))
  loadings <- paste(sprintf("1*%s", inds), collapse = " + ")
  paste(
    "level: 1",
    sprintf("subj =~ %s", loadings),
    paste(sprintf("%s ~~ evw*%s", inds, inds), collapse = "\n"),
    "subj ~~ svw*subj",
    "level: 2",
    sprintf("clus =~ %s", loadings),
    paste(sprintf("%s ~~ evb*%s", inds, inds), collapse = "\n"),
    "clus ~~ svb*clus",
    paste(sprintf("%s ~ 1", inds), collapse = "\n"),
    sep = "\n"
  )
}

# Pull the five variance components (cluster, subject-in-cluster, rater,
# cluster-by-rater, residual) from a fitted two-level lavaan model, given `k` and
# the effects-coding recentring matrix `center`. RANDOM raters only (M56 scope):
# the rater slot is the raw grand-mean-centred quadratic form on the between-level
# intercepts (Jorgensen 2021 Eq. 6), carrying the documented tau^2 inflation.
# Returns NULL on a between- or within-level Heywood boundary (a non-positive
# variance): the point-estimate path (fit_lavaan_multilevel) turns that into a
# classed abort (#5/#8), while the bootstrap factory treats it as an invalid
# resample (NA-filled, subject to the discard policy). The point path computes the
# same components inline for its Jacobian/estimate block; this reader is the
# refit's independent, boundary-safe path (cf. lavaan_components for single level).
lavaan_multilevel_components <- function(fit, k, center) {
  co <- lavaan::coef(fit)
  cn <- names(co)
  svw <- unname(co[[which(cn == "svw")[1]]])
  evw <- unname(co[[which(cn == "evw")[1]]])
  svb <- unname(co[[which(cn == "svb")[1]]])
  evb <- unname(co[[which(cn == "evb")[1]]])
  if (
    !is.finite(svw) ||
      !is.finite(evw) ||
      !is.finite(svb) ||
      !is.finite(evb) ||
      svw <= 0 ||
      evw <= 0 ||
      svb <= 0 ||
      evb <= 0
  ) {
    return(NULL)
  }
  nu <- unname(co[which(grepl("~1\\.l2$", cn))])
  sigma2_r <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)
  c(
    cluster = svb,
    subject = svw,
    rater = sigma2_r,
    cluster_rater = evb,
    residual = evw
  )
}

# Parametric-bootstrap factory for the two-level lavaan engine (M56). Closes over
# the fitted model's implied two-level generating moments -- reconstructed from the
# five components rather than lavInspect(): a cluster's k column-means are
# MVN(nu, svb*11' + diag(evb)) (the between factor + between residuals + rater
# intercepts) and a subject's within-cluster deviations are MVN(0, svw*11' +
# diag(evw)) (the within factor + within residuals) -- and the per-cluster subject
# counts. Each call simulates `boot_samples` wide two-level datasets (cluster draws
# broadcast over their subjects + within draws), refits the SAME two-level model
# with the SAME options, and returns the (component x resample) matrix on the five
# shared component names -- the `simulate_refit(boot_samples, seed)` contract
# bootstrap_ci() consumes. A refit that errors, does not converge, or lands on a
# between-level Heywood boundary is NA-filled and dropped upstream by the discard
# policy (#5/#8). Seeded via with_rng_seed() so the global RNG stream is left
# untouched (#9/#12). Random raters only; incomplete/unbalanced data keeps
# simulate_refit = NULL upstream (resamples cannot reproduce a missingness pattern).
lavaan_ml_simulate_refit <- function(
  model,
  k,
  center,
  nu,
  svw,
  evw,
  svb,
  evb,
  cluster_sizes
) {
  inds <- paste0("v", seq_len(k))
  na_out <- stats::setNames(
    rep(NA_real_, 5L),
    c("cluster", "subject", "rater", "cluster_rater", "residual")
  )
  ones <- matrix(1, k, k)
  cov_between <- svb * ones + diag(evb, k, k)
  cov_within <- svw * ones + diag(evw, k, k)
  mu_between <- stats::setNames(nu, inds)
  mu_within <- stats::setNames(rep(0, k), inds)
  n_clusters <- length(cluster_sizes)
  n_total <- sum(cluster_sizes)
  cluster_id <- factor(rep(seq_len(n_clusters), times = cluster_sizes))
  cluster_ix <- as.integer(cluster_id)
  function(boot_samples, seed = NULL) {
    run <- function() {
      refit_one <- function(i) {
        # Cluster means (k x N_c) broadcast to each subject; within deviations
        # (k x N_total) added on top -> the two-level DGP. Transpose to the wide
        # one-row-per-subject layout lavaan wants.
        b <- rmvn(n_clusters, mu_between, cov_between)
        w <- rmvn(n_total, mu_within, cov_within)
        obs <- w + b[, cluster_ix, drop = FALSE]
        wide_df <- as.data.frame(t(obs))
        names(wide_df) <- inds
        wide_df$cluster <- cluster_id
        refit <- tryCatch(
          suppressWarnings(lavaan::lavaan(
            model,
            data = wide_df,
            cluster = "cluster"
          )),
          error = function(e) NULL
        )
        if (is.null(refit) || !lavaan::lavInspect(refit, "converged")) {
          return(na_out)
        }
        out <- lavaan_multilevel_components(refit, k, center)
        if (is.null(out) || anyNA(out) || any(!is.finite(out))) na_out else out
      }
      vapply(seq_len(boot_samples), refit_one, na_out)
    }
    if (is.null(seed)) run() else with_rng_seed(seed, run())
  }
}

# MULTILEVEL (M54, D-005). The crossed (Design 1) multilevel decomposition of
# ten Hove, Jorgensen & van der Ark (2022, Eq. 7) -- sigma^2_c + sigma^2_{s:c} +
# sigma^2_r + sigma^2_{cr} + sigma^2_{(s:c)r} -- maps onto a TWO-LEVEL CFA
# (lavaan `cluster =`), the estimation-route parameterization the M53 pilot
# established numerically (D-005; cairn/references/sem-multilevel-pilot.md;
# data-raw/pilot-sem-multilevel.R): per rater-column j,
#   within  level: subject factor (loading 1)  = sigma^2_{s:c};
#                  equal indicator residuals    = sigma^2_{(s:c)r};
#   between level: cluster factor (loading 1)   = sigma^2_c;
#                  equal indicator residuals    = sigma^2_{cr};
#                  free indicator intercepts    -> sigma^2_r via the same
#                  grand-mean-centred quadratic form as the single-level
#                  engine (Jorgensen 2021 Eq. 6) -- a rater's main effect is a
#                  constant column offset, constant within clusters, so it
#                  lives in the BETWEEN mean structure (within intercepts 0).
#
# TAU^2 INFLATION (the multilevel analog of the "-sigma^2_res/n" note above).
# The raw quadratic-form rater estimator here carries a DETERMINISTIC
# structural inflation:
#     E[nu' C nu / (k - 1)] = sigma^2_r + tau^2,
#     tau^2 = (sigma^2_cr + sigma^2_{(s:c)r} / n_s) / N_c    (equal cluster sizes),
# the mean sampling variance of the k estimated rater means over N_c clusters
# of n_s subjects. Under UNEQUAL cluster sizes (M58) it generalizes by replacing
# n_s with the HARMONIC MEAN H of the per-cluster subject counts m_c:
#     tau^2 = (sigma^2_cr + sigma^2_{(s:c)r} / H) / N_c,   H = N_c / sum(1 / m_c),
# reducing exactly to the balanced form when all m_c are equal. (lavaan's
# between-level mean structure weights clusters EQUALLY, not by size, so the
# size-weighted "grand" form sigma^2_cr*sum(m^2)/N^2 + sigma^2_res/N is wrong --
# the pilot pins the harmonic form and that it beats the grand form under
# imbalance.) REML does not carry it, so the signed SEM-minus-REML rater parity
# IS tau^2 (pilot: match <= 1e-4 across geometries, balanced and unbalanced).
# Raw by design, exactly as the single-level estimator (ADR-014): documented,
# predictable, never absorbed into a widened tolerance (GP5) -- rater parity
# tests are CENTRED on tau^2, never zero (a zero-centred pin breaks structurally
# at small N_c, e.g. N_c = 10, n_s = 5 -> tau^2 ~ .026).
#
# ESTIMATION. lavaan's two-level estimator is full-information ML only -- no
# `likelihood = "wishart"` (N-1) analog -- so the between-level components
# carry ML's N-divisor shrinkage relative to the REML spine at small N_c
# (pilot: cluster-axis parity .025 -> .0025 as N_c grows 20 -> 200);
# consistency ICCs are ratios and absorb it (near-exact, M49 index-class
# split). RANDOM raters cover complete/balanced AND incomplete/unbalanced data
# (M58): a missing subject x rater cell is estimated by FIML (`missing =
# "fiml"`, set only when the wide frame has NA cells), and unequal cluster sizes
# fit natively; icc() guards connectedness and the crossed-random scope. A
# between-level Heywood (negative variance -- the boundary lavaan reaches where
# glmmTMB smoothly hits ~0, D-004) aborts loudly toward glmmTMB, as the
# single-level guard does. The MC interval reuses the shared machinery via the
# same six-field contract: log-SD scale for the four variances, natural scale
# for the between intercepts feeding the quadratic form per draw. On incomplete
# or unbalanced data the interval is MC-only (simulate_refit = NULL, MD-1).
#
# FIXED RATERS (M57). `raters = "fixed"` reads the SAME two-level fit: the
# between-level intercepts nu_j carry the rater main effects, so the rater slot
# becomes the McGraw & Wong Case-3A finite-population theta^2_r = max(0, raw -
# bias), bias = tr(C V_nu)/(k-1) on the between-intercept vcov block (the
# identity contrast of the single-level fixed path). The per-draw correction is
# the shared theta2r_moment_draws() with bias != 0 (2b + average-floor, GP7);
# random raters keep bias = 0. Consistency ICCs omit the rater term, so they are
# identical to the random-rater case; agreement ICCs (which count theta^2_r as
# error) differ from the raw random estimator by exactly `bias` = the documented
# tau^2 finite-population correction, matching glmmTMB fixed asymptotically (GP5:
# the gap is documented, never absorbed into a widened tolerance). Fixed is
# MC-only: the M56 bootstrap factory is random-only internally, so simulate_refit
# stays NULL for fixed (bootstrap deferred to a candidate). FIXED is crossed
# (Design 1), balanced/complete, equal cluster sizes only -- fixed
# incomplete/unbalanced stays refused upstream in icc() (a parked candidate),
# unlike the RANDOM path which now admits it (M58). The parametric bootstrap
# (M56) serves balanced/complete random raters only; nested designs, replicates,
# fixed incomplete/unbalanced, and fixed nested are refused upstream in icc().
fit_lavaan_multilevel <- function(
  data,
  raters = "random",
  call = rlang::caller_env()
) {
  rlang::check_installed("lavaan", reason = "to fit the ICC model with lavaan.")

  k <- nlevels(data$rater)
  inds <- paste0("v", seq_len(k))
  nu_slots <- paste0("nu", seq_len(k))

  # Long -> wide: one row per subject (columns v1..vk), plus its cluster id.
  # A MISSING subject x rater cell is left as NA (tapply's fill); on incomplete
  # data `missing = "fiml"` estimates around it (M58, the two-level analog of the
  # single-level fit_lavaan() FIML path). Unequal cluster sizes fit natively --
  # nothing in the extraction changes. icc() guards connectedness and the
  # random-crossed scope; the balance guard now admits incomplete/unbalanced
  # random data (M58) but still refuses fixed, nested, and replicate designs.
  wide <- tapply(data$score, list(data$subject, data$rater), function(x) x[[1]])
  wide_df <- as.data.frame(wide)
  names(wide_df) <- inds
  wide_df$cluster <- data$cluster[
    match(rownames(wide), as.character(data$subject))
  ]
  has_missing <- anyNA(wide)

  # The two-level model (pilot ml_sem_model): within = subject factor (svw) +
  # equal residuals (evw); between = cluster factor (svb) + equal residuals
  # (evb) + free intercepts (the rater main effects; within intercepts stay
  # fixed at 0 -- the mean structure lives between clusters). Shared with the
  # bootstrap factory (M56), which refits this same string per resample.
  model <- lavaan_multilevel_model(k)

  # `missing = "fiml"` ONLY on incomplete data -- complete/balanced fits keep
  # lavaan's default so M54/M57 results stay byte-identical (the single-level
  # path makes the same conditional choice).
  fit_args <- list(model = model, data = wide_df, cluster = "cluster")
  if (has_missing) {
    fit_args$missing <- "fiml"
  }

  fit <- tryCatch(
    withCallingHandlers(
      do.call(lavaan::lavaan, fit_args),
      warning = function(w) {
        cli::cli_warn(c(
          "The {.pkg lavaan} engine reported a fitting warning.",
          i = conditionMessage(w)
        ))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      emsg <- conditionMessage(e)
      abort_intraclass(
        c(
          "The {.pkg lavaan} engine could not fit the two-level SEM (a \\
           degenerate or boundary design).",
          i = "{emsg}",
          i = "Use {.code engine = \"glmmTMB\"}, which is boundary-robust here."
        ),
        class = "intraclass_singular_fit",
        call = call,
        .envir = rlang::current_env()
      )
    }
  )

  if (!lavaan::lavInspect(fit, "converged")) {
    abort_intraclass(
      c(
        "The {.pkg lavaan} engine did not converge.",
        i = "Use {.code engine = \"glmmTMB\"}, or check the design."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }

  co <- lavaan::coef(fit)
  vcov_raw <- as.matrix(lavaan::vcov(fit))
  cn <- names(co)
  svw <- unname(co[[which(cn == "svw")[1]]])
  evw <- unname(co[[which(cn == "evw")[1]]])
  svb <- unname(co[[which(cn == "svb")[1]]])
  evb <- unname(co[[which(cn == "evb")[1]]])
  # Between-level intercepts are suffixed ".l2" in two-level coef() names.
  nu_i <- which(grepl("~1\\.l2$", cn))
  nu <- unname(co[nu_i])

  # Heywood / boundary guard (#3/#5, D-004): lavaan's unconstrained ML can
  # return a NEGATIVE between-level variance where the mixed-model engines
  # smoothly reach ~0 (log-SD scale). No log-SD transform exists for it, so no
  # boundary-aware interval can be formed -- fail loudly toward glmmTMB.
  if (svw <= 0 || evw <= 0 || svb <= 0 || evb <= 0) {
    abort_intraclass(
      c(
        "The {.pkg lavaan} engine returned a non-positive variance (a Heywood \\
         case), so a boundary-aware Monte-Carlo interval cannot be formed.",
        i = "Use {.code engine = \"glmmTMB\"}, which is boundary-robust here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  # sigma^2_r: the grand-mean-centred quadratic form on the between-level
  # intercepts (Jorgensen 2021 Eq. 6). For RANDOM raters bias = 0 -- the tau^2
  # inflation is the documented raw-estimator property (header note), not a bias
  # to subtract. For FIXED raters (M57) the rater slot is instead the McGraw &
  # Wong Case-3A bias-corrected finite-population theta^2_r = max(0, raw - bias),
  # with `bias` the identity-contrast trace of the BETWEEN-intercept vcov block
  # (the same correction the single-level fit_lavaan() fixed path applies; here
  # the between-level intercepts carry the rater main effects). On balanced data
  # this recovers the mixed-model value glmmTMB fixed reports (M10/M37), which
  # the raw random estimator does NOT (it is inflated by tau^2 -- exactly the gap
  # `bias` removes).
  center <- diag(k) - matrix(1 / k, k, k)
  raw <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)
  bias <- if (identical(raters, "fixed")) {
    sum(diag(center %*% vcov_raw[nu_i, nu_i, drop = FALSE])) / (k - 1)
  } else {
    0
  }
  sigma2_r <- max(0, raw - bias)

  components <- list(
    cluster = svb,
    subject = svw,
    rater = sigma2_r,
    cluster_rater = evb,
    residual = evw
  )

  # Internal MC scale (cf. fit_lavaan): log-SD for the four variances,
  # identity for the k between intercepts. Equality-labelled parameters
  # appear once per constrained indicator in coef()/vcov(); take the first.
  raw_idx <- c(
    which(cn == "svw")[1],
    which(cn == "evw")[1],
    which(cn == "svb")[1],
    which(cn == "evb")[1],
    nu_i
  )
  vcov_sub <- vcov_raw[raw_idx, raw_idx, drop = FALSE]
  slots <- c("subject", "residual", "cluster", "cluster_rater", nu_slots)
  jac <- diag(c(
    1 / (2 * svw),
    1 / (2 * evw),
    1 / (2 * svb),
    1 / (2 * evb),
    rep(1, k)
  ))
  vcov_log <- jac %*% vcov_sub %*% t(jac)
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(
    c(log(sqrt(svw)), log(sqrt(evw)), log(sqrt(svb)), log(sqrt(evb)), nu),
    slots
  )

  # Back-transform internal-scale draws to the five components. The rater draws
  # reuse the shared moment helper: for RANDOM raters `bias` = 0, reducing to the
  # raw quadratic form pmax(0, nu' C nu / (k - 1)) per draw; for FIXED raters
  # `bias` > 0, so the draws are 2b-recentered + average-floored (M28/ADR-038,
  # GP7) exactly as the single-level fixed path. The between-intercept vcov block
  # that generates the draws is the same block `bias` is computed from.
  to_components <- function(par) {
    means <- par[nu_slots, , drop = FALSE]
    list(
      cluster = exp(2 * par["cluster", ]),
      subject = exp(2 * par["subject", ]),
      rater = theta2r_moment_draws(list(means), list(bias), center, k),
      cluster_rater = exp(2 * par["cluster_rater", ]),
      residual = exp(2 * par["residual", ])
    )
  }

  # Per-cluster subject counts drive the two-level bootstrap DGP (equal on the
  # balanced/complete cell; a vector on unequal cluster sizes -- M58).
  cluster_sizes <- as.integer(table(wide_df$cluster))
  unbalanced <- length(unique(cluster_sizes)) != 1L

  list(
    fit = fit,
    engine = "lavaan",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    # Two-level parametric bootstrap (M56): simulate wide two-level datasets from
    # this fit's implied within/between moments (rebuilt from the five components),
    # refit the same model, recompute both-level ICCs per resample. simulate_refit
    # = NULL routes ci_method = "bootstrap" to a loud abort, leaving the MC interval
    # as the sole method. It is NULL for:
    #   - FIXED raters (M57 gate): the M56 factory is random-only internally
    #     (lavaan_multilevel_components reads the raw sigma^2_r);
    #   - INCOMPLETE data: resamples cannot reproduce the missingness pattern
    #     (single-level FIML precedent, ADR-031);
    #   - UNEQUAL cluster sizes (M58/MD-1): the factory accepts a cluster_sizes
    #     vector, but the two-level bootstrap coverage was validated on balanced
    #     data only (M56) and no unbalanced coverage oracle is in scope --
    #     oracle-first (#1), so MC-only until one exists (a parked candidate).
    # Balanced/complete RANDOM keeps the M56 bootstrap unchanged.
    simulate_refit = if (
      identical(raters, "fixed") || has_missing || unbalanced
    ) {
      NULL
    } else {
      lavaan_ml_simulate_refit(
        model,
        k,
        center,
        nu,
        svw,
        evw,
        svb,
        evb,
        cluster_sizes
      )
    }
  )
}

fit_lavaan <- function(data, raters = "random", call = rlang::caller_env()) {
  rlang::check_installed("lavaan", reason = "to fit the ICC model with lavaan.")

  k <- nlevels(data$rater)
  inds <- paste0("v", seq_len(k))
  nu_slots <- paste0("nu", seq_len(k))

  # Long -> wide: rows = subjects, columns = raters. At most one rating per cell (the
  # two-way design has no within-cell replicates), so each present cell is a single
  # value; a MISSING subject x rater cell is left as NA (tapply's fill), which FIML
  # estimates around (M21 Slice 3). `has_missing` selects the estimator below.
  wide <- tapply(data$score, list(data$subject, data$rater), function(x) x[[1]])
  wide_df <- as.data.frame(wide)
  names(wide_df) <- inds
  has_missing <- anyNA(wide_df)

  # Unit loadings + one shared residual variance = the two-way random model.
  loadings <- paste(sprintf("1*%s", inds), collapse = " + ")
  residuals <- paste(sprintf("%s ~~ ev*%s", inds, inds), collapse = "\n")
  model <- paste(
    sprintf("subj =~ %s", loadings),
    residuals,
    "subj ~~ sv*subj",
    sep = "\n"
  )

  # A degenerate/boundary design (e.g. perfectly correlated raters -> a non
  # positive-definite sample covariance) makes lavaan raise its own un-classed
  # error before we can inspect the fit. Convert any such failure into a classed
  # intraclass condition pointing at the boundary-robust engine (#5/#8), so the
  # whole error surface stays classed and actionable.
  # Estimator: on COMPLETE data the N-1 wishart likelihood matches the REML
  # mixed-model spine and the classical published values (M7). On INCOMPLETE data
  # there is no complete sample covariance, so estimate by FIML (`missing = "fiml"`,
  # which uses casewise ML); the small-sample N-vs-(N-1) difference is immaterial
  # asymptotically, and the consistency ratio absorbs most of it (M21 Slice 3).
  fit_args <- list(
    model = model,
    data = wide_df,
    meanstructure = TRUE,
    int.ov.free = TRUE,
    int.lv.free = FALSE,
    information = "observed"
  )
  if (has_missing) {
    fit_args$missing <- "fiml"
  } else {
    fit_args$likelihood <- "wishart"
  }
  fit <- tryCatch(
    withCallingHandlers(
      do.call(lavaan::lavaan, fit_args),
      warning = function(w) {
        # Surface fit trouble through cli, non-fatal, matching the other engines.
        cli::cli_warn(c(
          "The {.pkg lavaan} engine reported a fitting warning.",
          i = conditionMessage(w)
        ))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      emsg <- conditionMessage(e)
      abort_intraclass(
        c(
          "The {.pkg lavaan} engine could not fit the SEM (a degenerate or \\
           boundary design).",
          i = "{emsg}",
          i = "Use {.code engine = \"glmmTMB\"}, which is boundary-robust here."
        ),
        class = "intraclass_singular_fit",
        call = call,
        .envir = rlang::current_env()
      )
    }
  )

  if (!lavaan::lavInspect(fit, "converged")) {
    abort_intraclass(
      c(
        "The {.pkg lavaan} engine did not converge.",
        i = "Use {.code engine = \"glmmTMB\"}, or check the design."
      ),
      class = "intraclass_engine_error",
      call = call
    )
  }

  co <- lavaan::coef(fit)
  vcov_raw <- as.matrix(lavaan::vcov(fit))
  cn <- names(co)
  sv <- unname(co[[which(cn == "sv")[1]]])
  ev <- unname(co[[which(cn == "ev")[1]]])
  nu_i <- which(grepl("~1$", cn))
  nu <- unname(co[nu_i])

  # Heywood / boundary guard (#3/#5): a non-positive variance cannot be put on the
  # log-SD scale, so no boundary-aware interval can be formed. Fail loudly and
  # point at the boundary-robust engine, rather than clamp and return a bogus CI.
  if (sv <= 0 || ev <= 0) {
    abort_intraclass(
      c(
        "The {.pkg lavaan} engine returned a non-positive variance (a Heywood \\
         case), so a boundary-aware Monte-Carlo interval cannot be formed.",
        i = "Use {.code engine = \"glmmTMB\"}, which is boundary-robust here."
      ),
      class = "intraclass_singular_fit",
      call = call
    )
  }

  # `center = I - J/k` recenters the intercepts to deviations from the grand mean
  # (identification-invariant). `raw` is the variance of the effects-coded rater
  # intercepts (Jorgensen 2021 Eq. 6; Vispoel et al. 2022 Eq. 4) -- the RANDOM-rater
  # sigma^2_r, a non-negative quadratic form. For FIXED raters the rater slot is
  # instead the Case-3A bias-corrected theta^2_r = max(0, raw - bias); `bias` is the
  # mean sampling variance of the centred intercepts, constant across MC draws (the
  # header's FIXED RATERS note; cf. theta2r_fixed() with the identity contrast).
  center <- diag(k) - matrix(1 / k, k, k)
  raw <- as.numeric(t(nu) %*% center %*% nu) / (k - 1)
  bias <- if (identical(raters, "fixed")) {
    sum(diag(center %*% vcov_raw[nu_i, nu_i, drop = FALSE])) / (k - 1)
  } else {
    0
  }
  sigma2_r <- max(0, raw - bias)

  components <- list(
    subject = sv,
    rater = sigma2_r,
    residual = ev
  )

  # Delta-transform the covariance to the internal scale for the Monte-Carlo CI:
  # log-SD for the two variances (d log(sd)/d var = 1 / (2 var)), identity for the
  # intercepts (they carry sigma^2_r through the mean structure). `ev` appears k
  # times in coef()/vcov() (one per equality-constrained residual), all identical;
  # take the first. Keep the block ordered (sv, ev, intercepts). Under the
  # saturated mean structure the mean and covariance parameters are asymptotically
  # orthogonal, so the cross-block is ~0.
  raw_idx <- c(which(cn == "sv")[1], which(cn == "ev")[1], nu_i)
  vcov_sub <- vcov_raw[raw_idx, raw_idx, drop = FALSE]
  slots <- c("subject", "residual", nu_slots)
  jac <- diag(c(1 / (2 * sv), 1 / (2 * ev), rep(1, k)))
  vcov_log <- jac %*% vcov_sub %*% t(jac)
  dimnames(vcov_log) <- list(slots, slots)
  estimate <- stats::setNames(c(log(sqrt(sv)), log(sqrt(ev)), nu), slots)

  # Back-transform a matrix of internal-scale draws (rows = parameters named as
  # `slots`, columns = MC draws) to variance components. subject/residual via
  # exp(2 * draw); rater via the shared moment helper (one group). For FIXED raters
  # `bias` > 0, so the draws are 2b-recentered + floored (M28, ADR-038); for RANDOM
  # raters `bias` = 0, so it reduces to the raw Jorgensen 2021 Eq. 6 estimator
  # pmax(0, sum(nu^2)/(k-1)) exactly -- unchanged (cf. fit_glmmtmb_fixed()).
  to_components <- function(par) {
    means <- par[nu_slots, , drop = FALSE]
    list(
      subject = exp(2 * par["subject", ]),
      rater = theta2r_moment_draws(list(means), list(bias), center, k),
      residual = exp(2 * par["residual", ])
    )
  }

  list(
    fit = fit,
    engine = "lavaan",
    components = components,
    estimate = estimate,
    vcov = vcov_log,
    to_components = to_components,
    # Parametric-bootstrap contract (M21 Slice 1, ADR-031): simulate from this fit's
    # implied moments -> refit -> recompute the ICC (with the fixed-rater correction
    # recomputed per refit when raters == "fixed") per resample. Reuses `center`/`k`.
    # Gated for INCOMPLETE data (M21 Slice 3): resampling complete rows from the
    # implied moments would not reproduce the observed missingness pattern, so the
    # bootstrap would silently overstate the information; ci_method = "bootstrap" then
    # aborts loudly toward the Monte-Carlo interval (bootstrap_ci()'s NULL guard).
    simulate_refit = if (has_missing) {
      NULL
    } else {
      lavaan_simulate_refit(fit, model, k, center, raters)
    }
  )
}
