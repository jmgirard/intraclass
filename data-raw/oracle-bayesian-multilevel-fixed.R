# oracle-bayesian-multilevel-fixed.R
# ===========================================================================
# Provenance for O-Bayes-FML: the brms (Bayesian) engine + ci_method =
# "posterior" for the CROSSED (Design 1) FIXED-rater multilevel ICC
# (Milestone 27 Slice 1, ADR-037). The fixed-rater sibling of
# data-raw/oracle-bayesian-multilevel.R (M24, crossed random) and the
# multilevel sibling of data-raw/oracle-bayesian-fixed.R (M26, single-level
# fixed). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-multilevel-fixed-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). This runs the
# SHIPPED recipe -- brms + half-t(4, 0, 1) on the random-effect SDs, the fixed
# `rater` effect, theta^2_r read RAW per posterior draw (brms_theta2r_draws),
# injected as the `rater` row of the M5 five-component `draws`, MAP/percentile --
# on the crossed Design-1 fixed-rater fit fit_brms_multilevel_fixed().
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses M10 §2)
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A fixed raters placed in the M5 crossed
#   subject-level decomposition (ten Hove et al. 2022, Design 1): the rater
#   effect is the finite-population variance of the k FIXED rater means
#     theta^2_r = sum_j (mu_rj - mu_r_bar)^2 / (k - 1),
#   and the SUBJECT-level agreement error set is {rater, residual} (sigma^2_cr
#   is NOT in the subject-level error -- the M9 oracle-first catch; matches
#   O-Bayes-ML-reduction). So the subject-level fixed ICC(A,1) is
#     sigma^2_{s:c} / (sigma^2_{s:c} + theta^2_r + sigma^2_res).
#   Because the raters are a fixed finite population, mu_rj are FIXED across
#   replications (not redrawn) -- coverage is of this fixed-population value.
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23/M24/M26)
# ---------------------------------------------------------------------------
#   ten Hove, Jorgensen & van der Ark (2020): half-t(4, 0, 1) on the
#   random-effect SDs (here sigma_c, sigma_{s:c}, sigma_{cr}; the k - 1 rater
#   contrasts keep brms's default flat prior); MAP point + percentile 95%
#   credible interval. RAW theta^2_r per draw (NO frequentist bias correction --
#   the posterior integrates the parameter uncertainty theta2r_fixed()'s
#   correction subtracts; ADR-036/037 oracle-first resolution).
#
# THE PINS (O-Bayes-FML), reported not tuned (#4/#18)
# ---------------------------------------------------------------------------
#   (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
#   (2) CONTAINMENT (the primary fixed-rater oracle): the glmmTMB M10 fixed
#       subject-level ICC(A,1) sits INSIDE the brms percentile credible interval
#       ~nominally often (glmmTMB the independent REML oracle). Equality is the
#       WRONG oracle here: brms puts a flat prior on the rater effects but half-t
#       on the random-effect SDs, so the balanced fixed ~ random identity (exact
#       under REML in M10) holds only APPROXIMATELY -- containment, not equality.
#   (3) Percentile coverage of the fixed-population subject-level ICC(A,1)
#       ~nominal.
#   (4) The MAP is biased low (the mode of the right-skewed ICC draws sits below
#       the plug-in, ADR-033) -- characterized, not asserted unbiased.
#   The fixture is written BEFORE the hard assertions so a long run is never lost
#   to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 20L
n_subj_per <- 5L
mu_r <- c(-0.6, -0.2, 0.2, 0.6) # FIXED finite population of k = 4 rater means
k <- length(mu_r)
theta2_r <- sum((mu_r - mean(mu_r))^2) / (k - 1) # = 0.2667
s2_c <- 0.50 # between-cluster (nuisance for the subject level)
s2_sc <- 1.00 # subject-in-cluster true score (subject-level signal)
s2_cr <- 0.16 # cluster x rater (nuisance for the subject level)
s2_res <- 0.50 # highest-order residual
# Subject-level agreement error set is {rater, residual} (M9 catch); cluster and
# cluster_rater do NOT enter the subject-level ICC.
pop_subject_a1 <- s2_sc / (s2_sc + theta2_r + s2_res)
n_rep <- 100L
base_seed <- 20270L
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The four random components -> draw-column map (theta^2_r is derived separately).
spec_ml_fixed <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  cluster_rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# One crossed Design-1 dataset with FIXED rater means (mu_r not redrawn).
simulate_multilevel_fixed <- function() {
  grid <- expand.grid(
    s = seq_len(n_subj_per),
    rater = seq_len(k),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_", grid$s)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  mu_cr <- stats::rnorm(n_clusters * k, 0, sqrt(s2_cr))
  data.frame(
    cluster = factor(grid$cluster),
    subject = factor(sid),
    rater = factor(grid$rater),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_r[grid$rater] + # FIXED rater means
      mu_cr[as.integer(interaction(grid$cluster, grid$rater))] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  )
}

est_a1 <- intraclass:::icc_estimand(
  type = "agreement",
  unit = "single",
  raters = "fixed",
  k_eff = k,
  multilevel = TRUE,
  level = "subject"
)

# Compile the base fixed-rater crossed model ONCE; every rep refits via
# update(recompile = FALSE) and runs the SHIPPED reducers (brms_component_draws +
# brms_theta2r_draws + posterior_summary), so this validates the exact recipe
# fit_brms_multilevel_fixed() uses while amortizing the ~40 s compile.
message("Compiling the base crossed fixed-rater Stan model once ...")
d0 <- simulate_multilevel_fixed()
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~
        1 +
        rater +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | cluster:rater),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> MAP subject-level ICC(A,1) + its percentile credible interval
# (coverage of the fixed-population value + containment of the glmmTMB REML point),
# plus convergence.
one_rep <- function(seed) {
  d <- simulate_multilevel_fixed()
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  base4 <- intraclass:::brms_component_draws(fit, spec_ml_fixed)
  theta <- intraclass:::brms_theta2r_draws(fit, d)
  draws <- rbind(
    cluster = base4["cluster", ],
    subject = base4["subject", ],
    rater = theta,
    cluster_rater = base4["cluster_rater", ],
    residual = base4["residual", ]
  )
  summ <- intraclass:::posterior_summary(draws, list(est_a1))[[1]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml_fixed))

  # glmmTMB M10 crossed fixed subject-level ICC(A,1) -- the independent REML oracle
  # for the CONTAINMENT pin.
  g <- suppressWarnings(intraclass::tidy(intraclass::icc(
    d,
    score,
    rater,
    subject = subject,
    cluster = cluster,
    raters = "fixed",
    engine = "glmmTMB"
  )))
  reml_a1 <- g$estimate[g$index == "ICC(A,1)" & g$level == "subject"]

  out <- data.frame(
    map_icc = summ$point,
    cover = summ$conf.low <= pop_subject_a1 && pop_subject_a1 <= summ$conf.high,
    contains_reml = summ$conf.low <= reml_a1 && reml_a1 <= summ$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run (checkpointed; a long hierarchical batch) -------------------------
ckpt <- "data-raw/.oracle-bayesian-multilevel-fixed-checkpoint.rds"
set.seed(base_seed)
rows <- vector("list", n_rep)
message(sprintf(
  "Crossed fixed-rater coverage: %d reps (pop subject ICC(A,1) = %.4f, theta^2_r = %.4f)",
  n_rep,
  pop_subject_a1,
  theta2_r
))
for (r in seq_len(n_rep)) {
  rows[[r]] <- one_rep(seed = base_seed + r)
  if (r %% 10L == 0L) {
    saveRDS(do.call(rbind, rows[seq_len(r)]), ckpt)
    message(sprintf("  ... %d/%d reps", r, n_rep))
  }
}
reps <- do.call(rbind, rows)

agg <- data.frame(
  k = k,
  n_rep = nrow(reps),
  pop_icc = pop_subject_a1,
  theta2_r = theta2_r,
  converged_frac = mean(reps$converged),
  map_icc_relbias = mean(reps$map_icc) / pop_subject_a1 - 1,
  coverage_icc = mean(reps$cover),
  containment_reml = mean(reps$contains_reml)
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-multilevel-fixed-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [crossed Design-1 estimands/DGP];",
      "McGraw & Wong (1996) Case 3A (fixed-rater finite-population theta^2_r)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      mu_r = mu_r,
      theta2_r = theta2_r,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_cr = s2_cr,
      s2_res = s2_res
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
unlink(ckpt) # raw reps safely aggregated into the committed fixture

# --- Validate against the pins ---------------------------------------------
stopifnot(
  # (1) High convergence at the half-t DGP.
  agg$converged_frac >= 0.90,
  # (2) CONTAINMENT (the primary fixed-rater oracle): the glmmTMB REML point sits
  #     inside the brms credible interval ~nominally often.
  agg$containment_reml >= 0.90,
  # (3) Percentile coverage of the fixed-population subject-level ICC(A,1) ~nominal.
  agg$coverage_icc >= 0.88,
  agg$coverage_icc <= 0.99,
  # (4) The MAP is biased low (the right-skewed-ICC-draws mode sits below the
  #     population plug-in) -- characterized, not asserted unbiased.
  agg$map_icc_relbias < 0
)

message("All O-Bayes-FML pins passed.")
