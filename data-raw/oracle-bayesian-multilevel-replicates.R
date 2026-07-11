# oracle-bayesian-multilevel-replicates.R
# ===========================================================================
# Provenance for O-Bayes-MLRep: the brms (Bayesian) engine + ci_method =
# "posterior" for MULTILEVEL WITHIN-CELL REPLICATE ICCs (Milestone 33 Slice 3,
# ADR-043). The multilevel sibling of O-Bayes-Rep (M29, single-level random
# replicates) and the Bayesian sibling of the frequentist M20 Slice 2
# (fit_glmmtmb_{ml,nested}_replicates). Covers BOTH replicate multilevel designs:
# crossed Design 1 (six-component) and nested Design 2 (five-component), random
# raters, subject level. Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-multilevel-replicates-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4).
#
# ENGINE/INTERVAL PARITY, NOT NEW ESTIMAND WORK. The estimand is the shipped M20
# Slice 2 multilevel replicate coefficient: the M5/M8 multilevel fit with a
# (1 | cluster:subject:rater) term splitting the subject-level residual into the
# interaction sigma^2_{csr} ("subject_rater") and pure error sigma^2_e
# ("residual"); occasion averaging divides only pure error by n_o. M33 gives it
# the brms engine (fit_brms_ml_replicates / fit_brms_nested_replicates). Random
# raters -> a VARIANCE-RATIO push-forward (no theta^2 functional, no 2b), so the
# ICC composes off the posterior draws exactly as the frequentist estimand.
#
# ESTIMAND (subject-level agreement, ten Hove et al. 2022 Table 3 + M17 split;
# estimand.R, the SHIPPED error set = {rater, subject_rater, residual}, EXCLUDING
# cluster_rater, which is a cluster-level phenomenon):
#   crossed D1  single  = s2_sc / (s2_sc + s2_r  + s2_sr + s2_e)
#               average = s2_sc / (s2_sc + s2_r  + s2_sr + s2_e / n_o)
#   nested  D2  single  = s2_sc / (s2_sc + s2_rc + s2_sr + s2_e)   (rater = sigma^2_{r:c})
#               average = s2_sc / (s2_sc + s2_rc + s2_sr + s2_e / n_o)
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23-M29): half-t(4,0,1)
# on every random-effect SD; MAP point + percentile 95% credible interval.
#
# A CI method's oracle is COVERAGE (#1). The oracle is that the shipped brms +
# half-t + MAP/percentile pipeline, read through the multilevel replicate
# estimand, (a) covers the known subject-level single/average population values,
# (b) CONTAINS the frequentist glmmTMB replicate points (the M20 §6 reduction),
# and (c) reports average > single (occasion averaging reduces pure error).
#
# GUARDRAIL (#4/#18): the MAP estimator is fixed a-priori; small-sample MAP skew
# is REPORTED, not tuned. The fixture is written BEFORE the hard pins.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 15L
n_subj_per <- 4L
k <- 3L
n_o <- 2L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16 # crossed D1 rater main effect / nested D2 rater-in-cluster sigma^2_{r:c}
s2_cr <- 0.16 # crossed D1 cluster x rater (a cluster-level term; not subject-level error)
s2_sr <- 0.40 # subject x rater interaction sigma^2_{csr}
s2_e <- 0.50 # pure error (reduced by occasion averaging)
n_rep <- 80L
base_seed <- 33300L
brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

# Subject-level agreement ICC(A,1): error = {rater, subject_rater, residual}.
pop_single <- s2_sc / (s2_sc + s2_r + s2_sr + s2_e)
pop_average <- s2_sc / (s2_sc + s2_r + s2_sr + s2_e / n_o)

# Per-design formula, component -> draw-column spec, and simulator. The subject-level
# population value is the SAME for both designs (s2_r == s2_rc here), so the two designs
# share pop_single / pop_average; only the fit structure differs.
designs <- list(
  crossed = list(
    formula = score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater) +
      (1 | cluster:subject:rater),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      rater = "sd_rater__Intercept",
      cluster_rater = "sd_cluster:rater__Intercept",
      subject_rater = "sd_cluster:subject:rater__Intercept",
      residual = "sigma"
    )
  ),
  nested = list(
    formula = score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | cluster:rater) +
      (1 | cluster:subject:rater),
    spec = c(
      cluster = "sd_cluster__Intercept",
      subject = "sd_cluster:subject__Intercept",
      rater = "sd_cluster:rater__Intercept",
      subject_rater = "sd_cluster:subject:rater__Intercept",
      residual = "sigma"
    )
  )
)

# One replicated multilevel dataset. `design` selects crossed (raters shared across clusters)
# vs nested (cluster-unique raters); the subject-level DGP variance is identical.
simulate <- function(design) {
  grid <- expand.grid(
    rep = seq_len(n_o),
    r = seq_len(k),
    s = seq_len(n_subj_per),
    cluster = seq_len(n_clusters)
  )
  sid <- interaction(grid$cluster, grid$s, drop = TRUE)
  rid <- if (design == "crossed") {
    factor(grid$r) # raters shared across clusters
  } else {
    interaction(grid$cluster, grid$r, drop = TRUE) # raters nested in clusters
  }
  crid <- interaction(grid$cluster, grid$r, drop = TRUE)
  csrid <- interaction(grid$cluster, grid$s, grid$r, drop = TRUE)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(nlevels(sid), 0, sqrt(s2_sc))
  mu_r <- stats::rnorm(nlevels(rid), 0, sqrt(s2_r))
  mu_cr <- stats::rnorm(nlevels(crid), 0, sqrt(s2_cr))
  mu_csr <- stats::rnorm(nlevels(csrid), 0, sqrt(s2_sr))
  # Crossed D1 has a separate cluster:rater term; nested D2 folds sigma^2_{r:c} into the
  # rater slot (rid IS cluster:rater), so it omits the extra mu_cr to keep s2_rc = s2_r.
  cr_effect <- if (design == "crossed") mu_cr[crid] else 0
  score <- mu_c[grid$cluster] +
    mu_sc[sid] +
    mu_r[rid] +
    cr_effect +
    mu_csr[csrid] +
    stats::rnorm(nrow(grid), 0, sqrt(s2_e))
  data.frame(
    subject = factor(paste0(grid$cluster, "_", grid$s)),
    rater = if (design == "crossed") {
      factor(grid$r)
    } else {
      factor(paste0(grid$cluster, "_r", grid$r))
    },
    cluster = factor(grid$cluster),
    score = score
  )
}

est_occ <- function(occ) {
  intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    multilevel = TRUE,
    level = "subject",
    replicates = TRUE,
    occasions = occ,
    n_o = n_o
  )
}
single_est <- est_occ("single")
average_est <- est_occ("average")

# One replication for a given design (reusing that design's ONE compiled model).
one_rep <- function(design, base_fit, spec, seed) {
  set.seed(seed)
  d <- simulate(design)
  fit <- suppressWarnings(suppressMessages(stats::update(
    base_fit,
    newdata = d,
    seed = seed,
    recompile = FALSE,
    refresh = 0
  )))
  draws <- intraclass:::brms_component_draws(fit, spec)
  summ <- intraclass:::posterior_summary(
    draws,
    list(single = single_est, average = average_est),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  # The containment oracle needs only the glmmTMB POINT, not its Monte-Carlo interval
  # (which can overflow on an unstable small-multilevel fit). Compute the point directly
  # from the shipped glmmTMB replicate fit's components via icc_point(), bypassing mc_ci().
  gfit <- suppressWarnings(suppressMessages(
    if (design == "crossed") {
      intraclass:::fit_glmmtmb_ml_replicates(d)
    } else {
      intraclass:::fit_glmmtmb_nested_replicates(d)
    }
  ))
  gt_single <- intraclass:::icc_point(gfit$components, single_est)
  gt_average <- intraclass:::icc_point(gfit$components, average_est)
  sc <- summ$single
  ac <- summ$average
  rm(fit)
  gc(verbose = FALSE)
  data.frame(
    design = design,
    single_map = sc$point,
    average_map = ac$point,
    cover_single = sc$conf.low <= pop_single && pop_single <= sc$conf.high,
    cover_average = ac$conf.low <= pop_average && pop_average <= ac$conf.high,
    contain_single = sc$conf.low <= gt_single && gt_single <= sc$conf.high,
    contain_average = ac$conf.low <= gt_average && gt_average <= ac$conf.high,
    average_gt_single = ac$point > sc$point,
    converged = converged
  )
}

# --- Run the simulation (compile once per design) --------------------------
ckpt <- "data-raw/.oracle-bayesian-multilevel-replicates-checkpoint.rds"
rows <- if (file.exists(ckpt)) readRDS(ckpt) else list()
cell_offset <- c(crossed = 0L, nested = 100000L)
for (dn in c("crossed", "nested")) {
  message(sprintf("Compiling the %s base model once ...", dn))
  base_fit <- do.call(
    brms::brm,
    c(
      list(
        formula = designs[[dn]]$formula,
        data = simulate(dn),
        prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
      ),
      brm_args
    )
  )
  for (r in seq_len(n_rep)) {
    key <- paste0(dn, "_", r)
    if (!is.null(rows[[key]])) {
      next
    }
    rows[[key]] <- one_rep(
      dn,
      base_fit,
      designs[[dn]]$spec,
      seed = base_seed + cell_offset[[dn]] + r
    )
    if (r %% 10L == 0L) {
      message(sprintf("  [%s] ... %d/%d reps", dn, r, n_rep))
      saveRDS(rows, ckpt)
    }
  }
  rm(base_fit)
  gc(verbose = FALSE)
}
reps <- do.call(rbind, rows)

# --- Aggregate to per-design reference statistics --------------------------
agg <- do.call(
  rbind,
  lapply(c("crossed", "nested"), function(dn) {
    x <- reps[reps$design == dn, ]
    data.frame(
      design = dn,
      k = k,
      n_o = n_o,
      n_rep = nrow(x),
      pop_single = pop_single,
      pop_average = pop_average,
      converged_frac = mean(x$converged),
      single_map_relbias = mean(x$single_map) / pop_single - 1,
      average_map_relbias = mean(x$average_map) / pop_average - 1,
      coverage_single = mean(x$cover_single),
      coverage_average = mean(x$cover_average),
      containment_single = mean(x$contain_single),
      containment_average = mean(x$contain_average),
      average_above_single = mean(x$average_gt_single)
    )
  })
)
print(agg)

# --- Commit the reference (BEFORE the hard pins) ---------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-multilevel-replicates-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] + (2022)",
      "Table 3 [multilevel estimand]; GT two-facet replicate decomposition",
      "[M17-within-cell-replicates.md]; glmmTMB M20 Slice 2 [point]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      k = k,
      n_o = n_o,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_r = s2_r,
      s2_cr = s2_cr,
      s2_sr = s2_sr,
      s2_e = s2_e
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
unlink(ckpt)

# --- Validate against the qualitative findings (the pins) ------------------
for (dn in c("crossed", "nested")) {
  a <- agg[agg$design == dn, ]
  # (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
  stopifnot(a$converged_frac >= 0.90)
  # (2) Subject-level single/average credible intervals COVER the known population values
  #     ~nominally (variance-ratio push-forward -> no theta^2 undercoverage expected).
  stopifnot(
    a$coverage_single >= 0.90,
    a$coverage_single <= 0.99,
    a$coverage_average >= 0.90,
    a$coverage_average <= 0.99
  )
  # (3) CONTAINMENT (M20 §6 reduction): the frequentist glmmTMB replicate points fall inside
  #     the brms credible intervals for ~all reps.
  stopifnot(
    a$containment_single >= 0.90,
    a$containment_average >= 0.90
  )
  # (4) OCCASION AVERAGING: average-occasion ICC above single-occasion in ~every rep.
  stopifnot(a$average_above_single >= 0.95)
}

message("All O-Bayes-MLRep pins passed.")
