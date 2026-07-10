# oracle-bayesian-nested-fixed.R
# ===========================================================================
# Provenance for O-Bayes-FNML: the brms (Bayesian) engine + ci_method =
# "posterior" for the NESTED (Design 2) FIXED-rater multilevel ICC
# (Milestone 27 Slice 2, ADR-037). The nested sibling of
# data-raw/oracle-bayesian-multilevel-fixed.R (M27 Slice 1, crossed).
# Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-nested-fixed-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# A CI method's oracle is COVERAGE (#1). This runs the SHIPPED recipe -- brms +
# half-t(4, 0, 1) on the (single) random-effect SD, the cell-mean fixed `rater`
# effect, theta^2_{r:c} read per posterior draw via the MOMENT-CORRECTED
# brms_theta2r_nested_draws() (the 2b correction, ADR-037 amendment / Fable
# review), injected as the `rater` row of the three-component `draws` -- on the
# nested Design-2 fixed fit fit_brms_nested_fixed():
#   score ~ 0 + rater + (1 | cluster:subject).
#
# THE 2b CORRECTION (Fable review, ADR-037 amendment; #1/#4/#18)
# ---------------------------------------------------------------------------
#   The raw per-draw push-forward of the per-cluster finite-population variance
#   sits at theta + 2b (b = tr(C Sigma_post)/(k-1) = sigma^2_res/n_s here): ONE b
#   for the push-forward inflation, ONE b for the plug-in bias of the center
#   (Sigma_post ~= V by Bernstein-von Mises). The shipped estimator subtracts 2b
#   per draw and floors only the per-cluster AVERAGE (per-cluster flooring gives
#   ZERO coverage at the theta^2 = 0 boundary -- Fable Q3/Q5). The RAW estimator
#   undercovers (coverage 0.86, MAP -.106, seed 20271) and its coverage -> 0 as
#   clusters accrue (an incidental-parameters pathology, not a small-sample
#   refinement -- Fable Sec. 1/3). This regenerated reference validates the
#   corrected estimator on the brms path across an INTERIOR and a BOUNDARY cell.
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses the M19 nested-fixed theta^2_{r:c})
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A per cluster, averaged over clusters (ten Hove et
#   al. 2022 Design 2, subject level). Raters are a FIXED per-cluster finite
#   population -- mu_{r:c} held fixed across replications. Subject-level agreement
#   error set {rater, residual}: ICC(A,1) = s2_sc / (s2_sc + theta^2_{r:c} + s2_res).
#
# THE PINS (O-Bayes-FNML), reported not tuned (#4/#18)
# ---------------------------------------------------------------------------
#   INTERIOR cell (theta^2_{r:c} > 0): (1) high convergence; (2) CONTAINMENT of
#   the glmmTMB M19 REML point ~nominal (the independent oracle); (3) percentile
#   coverage of the fixed-population ICC(A,1) ~nominal (Fable predicts ~0.95);
#   (4) MAP rel-bias small and REPORTED (~ -0.02, the residual mode-below-mean
#   skew, ADR-033). BOUNDARY cell (theta^2_{r:c} = 0): the average-floor keeps
#   coverage AT OR ABOVE nominal (conservative near the boundary -- the pin that
#   would FAIL under per-cluster flooring, #3). The fixture is written BEFORE the
#   hard assertions so a long run is never lost to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 20L
n_subj_per <- 5L
k <- 4L # raters per cluster (>= 2 for a finite-population variance)
s2_c <- 0.50 # between-cluster (absorbed by the cell-mean fit; nuisance)
s2_sc <- 1.00 # subject-in-cluster true score (subject-level signal)
s2_res <- 0.50 # residual (so b = s2_res / n_subj_per = 0.10 per cluster)
base_seed <- 20271L
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# FIXED per-cluster rater means for the INTERIOR cell: an n_clusters x k matrix
# drawn ONCE (seed 909) and row-centered, held fixed across replications.
set.seed(909L)
mu_rc_interior <- matrix(
  stats::rnorm(n_clusters * k, 0, sqrt(0.5)),
  n_clusters,
  k
)
mu_rc_interior <- mu_rc_interior - rowMeans(mu_rc_interior)
# BOUNDARY cell: all rater means equal within every cluster -> theta^2_{r:c} = 0.
mu_rc_boundary <- matrix(0, n_clusters, k)

cells <- list(
  list(name = "interior", mu_rc = mu_rc_interior, n_rep = 100L),
  list(name = "boundary", mu_rc = mu_rc_boundary, n_rep = 80L)
)

spec_nf <- c(
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)
est_a1 <- intraclass:::icc_estimand(
  type = "agreement",
  unit = "single",
  raters = "fixed",
  k_eff = k,
  multilevel = TRUE,
  level = "subject"
)

theta2_of <- function(mu_rc) {
  mean(apply(mu_rc, 1, function(m) sum(m^2) / (k - 1)))
}
pop_of <- function(theta2) s2_sc / (s2_sc + theta2 + s2_res)

# One nested Design-2 dataset with the given FIXED per-cluster rater means.
simulate_nested_fixed <- function(mu_rc) {
  grid <- expand.grid(
    s = seq_len(n_subj_per),
    rr = seq_len(k),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_s", grid$s)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  data.frame(
    cluster = factor(grid$cluster),
    subject = factor(sid),
    rater = factor(paste0(grid$cluster, "_r", grid$rr)),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_rc[cbind(grid$cluster, grid$rr)] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  )
}

# Compile the base model ONCE; refit per rep/cell via update(recompile = FALSE),
# running the SHIPPED reducers (brms_component_draws + brms_theta2r_nested_draws
# [moment-corrected] + posterior_summary), so this validates the exact recipe
# fit_brms_nested_fixed() uses.
message("Compiling the base nested fixed-rater Stan model once ...")
d0 <- simulate_nested_fixed(mu_rc_interior)
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

one_rep <- function(mu_rc, pop, seed) {
  d <- simulate_nested_fixed(mu_rc)
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
    cover = summ$conf.low <= pop && pop <= summ$conf.high,
    contains_reml = summ$conf.low <= reml_a1 && reml_a1 <= summ$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run (checkpointed) ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-nested-fixed-checkpoint.rds"
rows <- list()
for (cell in cells) {
  theta2 <- theta2_of(cell$mu_rc)
  pop <- pop_of(theta2)
  message(sprintf(
    "Cell %s: %d reps (theta^2_{r:c} = %.4f, pop ICC(A,1) = %.4f)",
    cell$name,
    cell$n_rep,
    theta2,
    pop
  ))
  set.seed(base_seed)
  cell_rows <- vector("list", cell$n_rep)
  for (r in seq_len(cell$n_rep)) {
    cell_rows[[r]] <- one_rep(cell$mu_rc, pop, seed = base_seed + r)
    if (r %% 20L == 0L) message(sprintf("  ... %d/%d", r, cell$n_rep))
  }
  cr <- do.call(rbind, cell_rows)
  rows[[cell$name]] <- data.frame(
    cell = cell$name,
    k = k,
    n_rep = nrow(cr),
    theta2_rc = theta2,
    pop_icc = pop,
    converged_frac = mean(cr$converged),
    map_icc_relbias = mean(cr$map_icc) / pop - 1,
    coverage_icc = mean(cr$cover),
    containment_reml = mean(cr$contains_reml)
  )
  saveRDS(do.call(rbind, rows), ckpt)
}
agg <- do.call(rbind, rows)
rownames(agg) <- NULL
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
      "McGraw & Wong (1996) Case 3A per cluster (fixed-rater theta^2_{r:c});",
      "Fable review 2026-07-09 (the 2b moment correction + average-floor)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      k = k,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_res = s2_res
    ),
    brm_args = brm_args,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
unlink(ckpt)

# --- Validate against the pins ---------------------------------------------
interior <- agg[agg$cell == "interior", ]
boundary <- agg[agg$cell == "boundary", ]
stopifnot(
  # (1) High convergence at the half-t DGP, both cells.
  all(agg$converged_frac >= 0.90),
  # (2) INTERIOR containment of the glmmTMB REML point ~nominal.
  interior$containment_reml >= 0.90,
  # (3) INTERIOR percentile coverage of the fixed-population ICC(A,1) ~nominal
  #     (the 2b correction restores it; RAW gave 0.86 -- Fable predicts ~0.95).
  interior$coverage_icc >= 0.90,
  interior$coverage_icc <= 0.99,
  # (4) BOUNDARY (theta^2_{r:c} = 0): the average-floor keeps coverage AT OR ABOVE
  #     nominal -- the pin per-cluster flooring would FAIL (coverage -> 0, #3).
  boundary$coverage_icc >= 0.90
)

message("All O-Bayes-FNML pins passed.")
