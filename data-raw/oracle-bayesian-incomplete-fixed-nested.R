# Oracle O-Bayes-IFNML: BAYESIAN (brms) INCOMPLETE/ragged fixed-rater NESTED (Design 2),
# subject-level single-rater ICC_s(A,1) -- credible-interval coverage (M38 Cell 2, ADR-048)
#
# Provenance for tests/testthat/test-icc-brms.R (PRINCIPLES.md #1, #3, #4, #18). Reproducible,
# seeded, standalone (Rscript data-raw/oracle-bayesian-incomplete-fixed-nested.R); writes the
# committed summary fixture tests/testthat/fixtures/bayesian-incomplete-fixed-nested-oracle.rds
# the O-Bayes-IFNML test asserts against. Live Stan fits -> the fixture, NOT the sim, is what CI
# checks ([[brms-live-fit-skip-on-ci]]).
#
# WHY (ADR-048): this is the BAYESIAN sibling of the frequentist M36 O-IFNML
# (data-raw/oracle-incomplete-fixed-nested.R). Cell 2's genuine risk is the 2b-under-imbalance
# moment correction going NESTED-brms for the first time (`b != 0` on ragged data). The
# frequentist M36 2b interval covered nominally; this oracle tests whether the brms credible
# interval -- which reads theta^2_{r:c} per posterior draw via brms_theta2r_nested_draws() ->
# brms_theta2r_moment_draws() (the SAME per-cluster 2b + boundary-aware average-floor) -- also
# covers. THE DECISION GATE (ADR-048): nominal (interior + boundary in the pre-registered band)
# -> Cell 2 ships; under-covers -> STOP, no pin-loosening (#4), no tuning, no Fable -> ship
# Cell 1 only and re-plan Cell 2.
#
# NON-CIRCULAR truth: theta^2_{r:c} is a DETERMINISTIC function of the specific fixed per-cluster
# rater means (their within-cluster finite-population variance, averaged over clusters), so the
# single-rater population value vsc / (vsc + theta2 + vres) is fixed and recovering its coverage
# from ragged data is a genuine independent oracle. Raters are a FIXED finite population -> the
# rater means are held fixed across replications; subjects, residuals, and the MISSINGNESS
# pattern are resampled per rep (per-rep seeding, the M36 convention). n_rep = 240
# ([[ragged-coverage-nrep-240]] -- the >= .88 pin false-alarms ~0.7%/cell at n_rep 80).
#
# CLUSTER-COUNT AXIS ([[coverage-oracle-cluster-count-axis]]): the incidental-parameters failure
# mode of a per-cluster finite-population correction is invisible at few clusters, so the grid
# includes a HIGH-C_n cell (C_n = 80) alongside a moderate one.

suppressPackageStartupMessages({
  stopifnot(
    requireNamespace("glmmTMB", quietly = TRUE),
    requireNamespace("brms", quietly = TRUE)
  )
})
devtools::load_all(quiet = TRUE)
library(brms)

# --- Config ----------------------------------------------------------------
vsc <- 1.0 # sigma^2_{s:c}
vres <- 0.5 # sigma^2_res
n_rep <- 240L
base_seed <- 38200L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# Design 2 fixed: theta^2_{r:c} lives in the `rater` slot (the finite-population variance of
# each cluster's fixed rater means), read per draw off `0 + rater`; subject + residual come off
# the standard spec. The subject-level agreement error set is {rater, residual} (M8 §3a).
spec_sr <- c(
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)

# Ragged nested Design 2, raters FIXED (M36 sim_ragged_d2_fixed). Each cluster c gets a centered
# rater-mean pattern scaled so its within-cluster finite-population variance is EXACTLY `theta2`
# (Case 3A per cluster) -- so theta^2_{r:c} (the mean over clusters) is exactly `theta2`;
# theta2 = 0 puts every rater mean equal (the boundary). Cells are deleted with prob
# (1 - p_keep); subjects with < 2 remaining ratings are dropped (connectedness). Rater labels
# are cluster-unique => nested regardless of the numeric means.
sim_ragged_d2_fixed <- function(kc_vec, ns, theta2, p_keep, seed) {
  set.seed(seed)
  rows <- list()
  for (c in seq_along(kc_vec)) {
    k <- kc_vec[c]
    base <- seq_len(k) - (k + 1) / 2
    v0 <- sum(base^2) / (k - 1)
    rmean <- if (theta2 == 0) rep(0, k) else base * sqrt(theta2 / v0)
    for (s in seq_len(ns)) {
      sc <- stats::rnorm(1, 0, sqrt(vsc))
      for (r in seq_len(k)) {
        if (stats::runif(1) > p_keep) {
          next
        }
        rows[[length(rows) + 1L]] <- data.frame(
          cluster = c,
          subject = paste(c, s, sep = "_"),
          rater = paste(c, r, sep = "_"),
          score = 10 + rmean[r] + sc + stats::rnorm(1, 0, sqrt(vres))
        )
      }
    }
  }
  d <- do.call(rbind, rows)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  keep <- names(which(table(d$subject) >= 2L))
  d[d$subject %in% keep, , drop = FALSE]
}

# The fixed rater labels are the SAME finite population across reps (c_r for c clusters,
# r raters), so the `0 + rater` design matrix columns are stable and update(recompile = FALSE)
# is valid. A rater can only vanish if all its cells are dropped; p_keep is set so that is
# vanishingly unlikely, and a rep whose fit errors is discarded + counted (#18).

# The subject-level single-rater ICC(A,1) draws from a fitted brms nested-fixed model, via the
# SHIPPED reducers -- exactly the fit_brms_nested_fixed() recipe.
one_rep_summary <- function(fit, d) {
  base_draws <- intraclass:::brms_component_draws(fit, spec_sr)
  theta_draws <- intraclass:::brms_theta2r_nested_draws(fit, d)
  draws <- rbind(
    subject = base_draws["subject", ],
    rater = theta_draws,
    residual = base_draws["residual", ]
  )
  est1 <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "fixed",
    k_eff = 1,
    multilevel = TRUE,
    level = "subject"
  )
  s <- intraclass:::posterior_summary(
    draws,
    list(a1 = est1),
    conf_level = 0.95
  )$a1
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_sr))
  list(
    point = s$point,
    lo = s$conf.low,
    hi = s$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
}

# One grid cell: n_rep reps, fraction of 95% single-rater ICC(A,1) credible intervals containing
# the KNOWN population value. Fits that error are discarded + counted (#18).
one_cell <- function(label, base_fit, kc_vec, ns, theta2, p_keep, base_seed) {
  pop_icc <- vsc / (vsc + theta2 + vres)
  hits <- 0L
  nfit <- 0L
  nfail <- 0L
  bias_acc <- 0
  for (r in seq_len(n_rep)) {
    d <- sim_ragged_d2_fixed(kc_vec, ns, theta2, p_keep, seed = base_seed + r)
    ok <- tryCatch(
      {
        fit <- suppressWarnings(suppressMessages(stats::update(
          base_fit,
          newdata = d,
          seed = base_seed + r,
          recompile = FALSE,
          refresh = 0
        )))
        s <- one_rep_summary(fit, d)
        rm(fit)
        gc(verbose = FALSE)
        s
      },
      error = function(e) NULL
    )
    if (is.null(ok)) {
      nfail <- nfail + 1L
      next
    }
    nfit <- nfit + 1L
    if (ok$lo <= pop_icc && pop_icc <= ok$hi) {
      hits <- hits + 1L
    }
    bias_acc <- bias_acc + (ok$point - pop_icc)
  }
  message(sprintf(
    "  cell %-18s C_n=%d theta2=%.2f  cover=%.4f  nfit=%d nfail=%d",
    label,
    length(kc_vec),
    theta2,
    hits / nfit,
    nfit,
    nfail
  ))
  data.frame(
    cell = label,
    n_clusters = length(kc_vec),
    theta2 = theta2,
    pop_icc = pop_icc,
    n_rep = nfit,
    n_fail = nfail,
    coverage_a1 = hits / nfit,
    mean_bias = bias_acc / nfit
  )
}

# --- Grid ------------------------------------------------------------------
# 4 cells crossing {moderate C_n=20, HIGH C_n=80} x {interior theta2 > 0, boundary theta2 = 0}.
# Unequal per-cluster k_c (3 or 4) exercises the ragged 2b path; ns subjects per cluster; ~15%
# cells dropped. The HIGH-C_n cell is the incidental-parameters probe.
cells <- list(
  list(label = "mod_interior", nc = 20L, ns = 6L, theta2 = 0.30, p_keep = 0.85),
  list(label = "mod_boundary", nc = 20L, ns = 6L, theta2 = 0.00, p_keep = 0.85),
  list(
    label = "high_interior",
    nc = 80L,
    ns = 4L,
    theta2 = 0.30,
    p_keep = 0.85
  ),
  list(label = "high_boundary", nc = 80L, ns = 4L, theta2 = 0.00, p_keep = 0.85)
)
kc_of <- function(nc) rep_len(c(3L, 4L), nc) # unequal k_c

# --- Compile the nested-fixed Stan model ONCE ------------------------------
# The template dataset must contain the FULL fixed rater population for the largest cell so the
# `0 + rater` design has every column; each rep's update() supplies a subset with the same levels.
message("Compiling the base nested-fixed Design-2 Stan model once ...")
template <- sim_ragged_d2_fixed(
  kc_of(80L),
  ns = 4L,
  theta2 = 0.30,
  p_keep = 1.0,
  seed = base_seed
)
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 0 + rater + (1 | cluster:subject),
      data = template,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# --- Run -------------------------------------------------------------------
# ~960 hierarchical refits (4 cells x 240). Checkpoint after each cell (gitignored) so a crash in
# the aggregation tail never forces re-sampling.
ckpt <- "data-raw/.oracle-bayesian-incomplete-fixed-nested-checkpoint.rds"
done <- if (file.exists(ckpt)) readRDS(ckpt) else list()
for (cl in cells) {
  if (!is.null(done[[cl$label]])) {
    message(sprintf("Cell %s: cached", cl$label))
    next
  }
  message(sprintf("Cell %s: %d reps", cl$label, n_rep))
  done[[cl$label]] <- one_cell(
    cl$label,
    base_fit,
    kc_of(cl$nc),
    cl$ns,
    cl$theta2,
    cl$p_keep,
    base_seed = base_seed
  )
  saveRDS(done, ckpt)
}
summary_df <- do.call(rbind, done[vapply(cells, `[[`, "", "label")])
rownames(summary_df) <- NULL

saveRDS(
  list(
    summary = summary_df,
    config = list(
      vsc = vsc,
      vres = vres,
      n_rep = n_rep,
      base_seed = base_seed,
      brm_args = brm_args,
      generated = Sys.time()
    )
  ),
  "tests/testthat/fixtures/bayesian-incomplete-fixed-nested-oracle.rds"
)

print(summary_df)

# --- The gate (ADR-048) ----------------------------------------------------
# QUALITATIVE pins (a coverage oracle reproduces behaviour, not decimals); the pre-registered
# band is [.90, .99] with |bias| small, matching the frequentist M36 O-IFNML and the M32/M30
# Bayesian nested oracles. Interior AND boundary (theta2 = 0), at BOTH cluster counts, must land
# in band -- a HIGH-C_n shortfall is the incidental-parameters signature (#18). Under-coverage is
# STOP-and-replan (ADR-048): no pin loosening (#4), no tuning, no Fable.
message("\n--- O-Bayes-IFNML gate ---")
in_band <- with(summary_df, coverage_a1 >= 0.90 & coverage_a1 <= 0.99)
for (i in seq_len(nrow(summary_df))) {
  message(sprintf(
    "  %-14s coverage=%.4f  bias=%+.4f  %s",
    summary_df$cell[i],
    summary_df$coverage_a1[i],
    summary_df$mean_bias[i],
    if (in_band[i]) "PASS" else "FAIL -> STOP-AND-REPLAN"
  ))
}
message(sprintf(
  "\nVERDICT: %s",
  if (all(in_band)) {
    "NOMINAL -> Cell 2 ships"
  } else {
    "UNDER-COVERS -> STOP, ship Cell 1 only, re-plan Cell 2 (ADR-048)"
  }
))
