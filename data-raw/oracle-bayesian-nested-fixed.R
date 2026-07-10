# oracle-bayesian-nested-fixed.R
# ===========================================================================
# Provenance for O-Bayes-FNML: the brms (Bayesian) engine + ci_method =
# "posterior" for the NESTED (Design 2) FIXED-rater multilevel ICC
# (Milestone 27 Slice 2, ADR-037). The nested sibling of
# data-raw/oracle-bayesian-multilevel-fixed.R (M27 Slice 1, crossed) and the
# fixed-rater sibling of data-raw/oracle-bayesian-nested.R (M25, nested random).
# Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-nested-fixed-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). This runs the
# SHIPPED recipe -- brms + half-t(4, 0, 1) on the (single) random-effect SD, the
# cell-mean fixed `rater` effect, theta^2_{r:c} read RAW per posterior draw
# (brms_theta2r_nested_draws), injected as the `rater` row of the three-component
# `draws` -- on the nested Design-2 fixed fit fit_brms_nested_fixed():
#   score ~ 0 + rater + (1 | cluster:subject).
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses the M19 nested-fixed theta^2_{r:c})
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A per cluster, averaged over clusters (ten Hove
#   et al. 2022 Design 2, subject level): the rater effect is the WITHIN-cluster
#   finite-population variance of each cluster's k FIXED rater means, averaged
#   over clusters,
#     theta^2_{r:c} = mean_c [ sum_j (mu_{r:c,j} - mu_bar_c)^2 / (k - 1) ].
#   The SUBJECT-level agreement error set is {rater, residual} (M8 §3a), so
#     ICC(A,1) = sigma^2_{s:c} / (sigma^2_{s:c} + theta^2_{r:c} + sigma^2_res).
#   Raters are a FIXED per-cluster finite population -- mu_{r:c} are held fixed
#   across replications (not redrawn) -- coverage is of this fixed value.
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23-M26)
# ---------------------------------------------------------------------------
#   ten Hove et al. (2020): half-t(4, 0, 1) on the random-effect SD (here
#   sigma_{s:c}; the rater cell means keep brms's default flat prior); MAP +
#   percentile 95% credible interval. RAW theta^2_{r:c} per draw (NO frequentist
#   per-cluster bias correction -- the posterior integrates the parameter
#   uncertainty; ADR-037 oracle-first resolution).
#
# THE PINS (O-Bayes-FNML), reported not tuned (#4/#18)
# ---------------------------------------------------------------------------
#   (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
#   (2) CONTAINMENT (the primary fixed-rater oracle): the glmmTMB M19 nested
#       fixed subject-level ICC(A,1) sits INSIDE the brms percentile credible
#       interval ~nominally often (glmmTMB the independent REML oracle). Unlike
#       the CROSSED design, fixed != random even balanced (per-cluster finite
#       population; the M19 catch), so containment -- not the balanced fixed ~
#       random identity -- is the correct pin.
#   (3) Percentile coverage of the fixed-population subject-level ICC(A,1)
#       ~nominal.
#   (4) The MAP relative bias is REPORTED (characterized, not asserted).
#   The fixture is written BEFORE the hard assertions so a long run is never lost
#   to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 20L
n_subj_per <- 5L
k <- 4L # raters per cluster (>= 2 for a finite-population variance)
s2_c <- 0.50 # between-cluster (absorbed by the cell-mean fit; nuisance)
s2_sc <- 1.00 # subject-in-cluster true score (subject-level signal)
s2_res <- 0.50 # residual
# FIXED per-cluster rater means: an n_clusters x k matrix drawn ONCE (seed 909)
# and held fixed across replications, so theta^2_{r:c} is a fixed finite-population
# quantity (not redrawn).
set.seed(909L)
mu_rc <- matrix(stats::rnorm(n_clusters * k, 0, sqrt(0.5)), n_clusters, k)
# Center each cluster's means (identifiability: the cluster main effect is a
# separate nuisance; only the within-cluster spread is theta^2_{r:c}).
mu_rc <- mu_rc - rowMeans(mu_rc)
theta2_rc <- mean(apply(mu_rc, 1, function(m) sum(m^2) / (k - 1)))
pop_subject_a1 <- s2_sc / (s2_sc + theta2_rc + s2_res)
n_rep <- 100L
base_seed <- 20271L
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The two random components -> draw-column map (theta^2_{r:c} is derived separately).
spec_nf <- c(
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)

# One nested Design-2 dataset with FIXED per-cluster rater means (mu_rc held fixed).
simulate_nested_fixed <- function() {
  grid <- expand.grid(
    s = seq_len(n_subj_per),
    rr = seq_len(k),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_s", grid$s)
  rid <- paste0(grid$cluster, "_r", grid$rr) # rater nested in cluster
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  data.frame(
    cluster = factor(grid$cluster),
    subject = factor(sid),
    rater = factor(rid),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_rc[cbind(grid$cluster, grid$rr)] + # FIXED per-cluster rater means
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

# Compile the base nested fixed-rater model ONCE; every rep refits via
# update(recompile = FALSE) and runs the SHIPPED reducers (brms_component_draws +
# brms_theta2r_nested_draws + posterior_summary), validating the exact recipe
# fit_brms_nested_fixed() uses while amortizing the compile.
message("Compiling the base nested fixed-rater Stan model once ...")
d0 <- simulate_nested_fixed()
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 0 + rater + (1 | cluster:subject),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

one_rep <- function(seed) {
  d <- simulate_nested_fixed()
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  base2 <- intraclass:::brms_component_draws(fit, spec_nf)
  theta <- intraclass:::brms_theta2r_nested_draws(fit, d)
  draws <- rbind(
    subject = base2["subject", ],
    rater = theta,
    residual = base2["residual", ]
  )
  summ <- intraclass:::posterior_summary(draws, list(est_a1))[[1]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_nf))

  # glmmTMB M19 nested fixed subject-level ICC(A,1) -- the independent REML oracle
  # for the CONTAINMENT pin.
  g <- suppressWarnings(intraclass::tidy(intraclass::icc(
    d,
    score,
    subject,
    rater,
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

# --- Run (checkpointed) ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-nested-fixed-checkpoint.rds"
set.seed(base_seed)
rows <- vector("list", n_rep)
message(sprintf(
  "Nested fixed-rater coverage: %d reps (pop subject ICC(A,1) = %.4f, theta^2_{r:c} = %.4f)",
  n_rep,
  pop_subject_a1,
  theta2_rc
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
  theta2_rc = theta2_rc,
  converged_frac = mean(reps$converged),
  map_icc_relbias = mean(reps$map_icc) / pop_subject_a1 - 1,
  coverage_icc = mean(reps$cover),
  containment_reml = mean(reps$contains_reml)
)
print(agg)

# --- Commit the reference (BEFORE the hard pins) ---------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-nested-fixed-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [nested Design-2 estimands/DGP];",
      "McGraw & Wong (1996) Case 3A per cluster (fixed-rater theta^2_{r:c})"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      k = k,
      mu_rc = mu_rc,
      theta2_rc = theta2_rc,
      s2_c = s2_c,
      s2_sc = s2_sc,
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
unlink(ckpt)

# --- Validate against the pins ---------------------------------------------
stopifnot(
  # (1) High convergence at the half-t DGP.
  agg$converged_frac >= 0.90,
  # (2) CONTAINMENT (the primary fixed-rater oracle): the glmmTMB REML point sits
  #     inside the brms credible interval ~nominally often.
  agg$containment_reml >= 0.90,
  # (3) Percentile coverage of the fixed-population subject-level ICC(A,1) ~nominal.
  agg$coverage_icc >= 0.88,
  agg$coverage_icc <= 0.99
)

message("All O-Bayes-FNML pins passed.")
