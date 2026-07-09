# oracle-bayesian-fixed.R
# ===========================================================================
# Provenance for O-Bayes-Fixed: the brms (Bayesian) engine + ci_method =
# "posterior" for the FIXED-rater two-way ICC (Milestone 26 Slice 2, ADR-036).
# Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-fixed-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). This is the
# fixed-rater sibling of data-raw/oracle-bayesian.R (M23, random): the SAME
# shipped recipe (brms + half-t(4,0,1) prior on sigma_s + MAP/percentile), on
# the FIXED-rater fit score ~ 1 + rater + (1 | subject), with theta^2_r read per
# posterior draw from the rater fixed-effect draws (fit_brms_fixed()).
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses M3 §6 / M10 §2)
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A fixed raters: the rater effect is the
#   finite-population variance of the k FIXED rater means
#     theta^2_r = sum_j (mu_rj - mu_r_bar)^2 / (k - 1),
#   and ICC(A,1) = sigma^2_s / (sigma^2_s + theta^2_r + sigma^2_res). Because the
#   raters are a fixed finite population, mu_rj are FIXED across replications (not
#   redrawn) -- coverage is of this fixed-population ICC(A,1).
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23)
# ---------------------------------------------------------------------------
#   ten Hove, Jorgensen & van der Ark (2020): half-t(4, 0, 1) on random-effect
#   SDs (here sigma_s only; the k - 1 rater contrasts keep brms's default flat
#   prior); MAP point + percentile 95% credible interval. RAW theta^2_r per draw
#   (NO frequentist bias correction -- the posterior integrates the parameter
#   uncertainty theta2r_fixed()'s correction subtracts; ADR-036 oracle-first
#   resolution, confirmed: the correction moves MAP ICC(A,1) by ~0.002).
#
# DGP
# ---------------------------------------------------------------------------
#   Y_sr = mu_s + mu_rj + e,  mu_s ~ N(0, sigma^2_s), e ~ N(0, sigma^2_res),
#   mu_rj FIXED = c(-0.6, -0.2, 0.2, 0.6) (k = 4, theta^2_r = 0.8/3 = 0.2667),
#   N = 30 subjects, sigma^2_s = sigma^2_res = 0.5. Population fixed-rater
#   ICC(A,1) = 0.5 / (0.5 + 0.2667 + 0.5) = 0.3947.
#
#   OBSERVED BEHAVIOR (the pins). The MAP of ICC(A,1) is the mode of the
#   right-skewed ICC draws, so it sits BELOW the REML/population plug-in (the
#   standard MAP-below-plug-in skew, ADR-033) -- reported, not tuned. Coverage of
#   the fixed-population ICC(A,1) by the percentile interval is the calibrated
#   quantity, expected ~nominal. We pin (#18):
#     (1) High convergence at the half-t DGP.
#     (2) Percentile 95% credible-interval coverage of the fixed-population
#         ICC(A,1) ~nominal.
#     (3) The MAP is biased low (the skew) -- characterized, not asserted unbiased.
#   Tolerances bracket the observed seeded run; NOT tuned to a target (#4).
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subjects <- 30L
s2_s <- 0.5
s2_res <- 0.5
mu_r <- c(-0.6, -0.2, 0.2, 0.6) # FIXED finite population of k = 4 rater means
k <- length(mu_r)
theta2_r <- sum((mu_r - mean(mu_r))^2) / (k - 1)
pop_icc_a1 <- s2_s / (s2_s + theta2_r + s2_res)
n_rep <- 200L
base_seed <- 20261L
brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

# One dataset from the fixed-rater DGP (the rater means are FIXED, not redrawn).
simulate_fixed <- function() {
  mu_s <- stats::rnorm(n_subjects, 0, sqrt(s2_s))
  grid <- expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  e <- stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  data.frame(
    subject = factor(grid$subject),
    rater = factor(grid$rater),
    score = mu_s[grid$subject] + mu_r[grid$rater] + e
  )
}

# The subject/residual component -> draw-column map (theta^2_r is derived separately below).
spec_sr <- c(subject = "sd_subject__Intercept", residual = "sigma")
b_cols <- c("b_Intercept", paste0("b_rater", 2:k))
contrast <- intraclass:::rater_mean_contrast(k)
center <- diag(k) - matrix(1 / k, k, k)

# Compile the Stan model ONCE (brms recompiles per brm() call ~40 s; update(recompile =
# FALSE) reuses the DSO -- see oracle-bayesian.R). The reduction below REPLICATES the shipped
# fit_brms_fixed() recipe (raw theta^2_r per draw from the b_ rater draws, injected as the
# `rater` row, then posterior_summary of the fixed agreement estimand), so this validates the
# exact shipped estimator while amortizing the compile.
message("Compiling the base Stan model once ...")
d0 <- simulate_fixed()
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + rater + (1 | subject),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

est_a1 <- intraclass:::icc_estimand(
  type = "agreement",
  unit = "single",
  raters = "fixed",
  k_eff = k
)

# One replication -> MAP ICC(A,1) + its percentile credible interval (coverage of the
# fixed-population value), plus convergence.
one_rep <- function(seed) {
  d <- simulate_fixed()
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  dm <- as.matrix(fit)
  sr <- intraclass:::brms_component_draws(fit, spec_sr)
  beta <- t(dm[, b_cols, drop = FALSE])
  mu <- contrast %*% beta
  theta <- pmax(0, colSums(mu * (center %*% mu)) / (k - 1))
  draws <- rbind(
    subject = sr["subject", ],
    rater = theta,
    residual = sr["residual", ]
  )
  summ <- intraclass:::posterior_summary(
    draws,
    list(est_a1),
    conf_level = 0.95
  )[[1]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_sr))
  out <- data.frame(
    map_icc = summ$point,
    cover = summ$conf.low <= pop_icc_a1 && pop_icc_a1 <= summ$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run -------------------------------------------------------------------
set.seed(base_seed)
rows <- vector("list", n_rep)
message(sprintf(
  "Fixed-rater coverage: %d reps (pop ICC(A,1) = %.4f)",
  n_rep,
  pop_icc_a1
))
for (r in seq_len(n_rep)) {
  rows[[r]] <- one_rep(seed = base_seed + r)
}
reps <- do.call(rbind, rows)

agg <- data.frame(
  k = k,
  n_rep = nrow(reps),
  pop_icc = pop_icc_a1,
  theta2_r = theta2_r,
  converged_frac = mean(reps$converged),
  map_icc_relbias = mean(reps$map_icc) / pop_icc_a1 - 1,
  coverage_icc = mean(reps$cover)
)
print(agg)

# --- Validate (the pins) ---------------------------------------------------
stopifnot(
  # (1) High convergence at the half-t DGP.
  agg$converged_frac >= 0.90,
  # (2) Percentile 95% credible-interval coverage of the fixed-population ICC(A,1)
  #     ~nominal.
  agg$coverage_icc >= 0.88,
  agg$coverage_icc <= 0.99,
  # (3) The MAP is biased low (the right-skewed-ICC-draws mode sits below the
  #     population plug-in) -- characterized, not asserted unbiased.
  agg$map_icc_relbias < 0
)

# --- Commit ----------------------------------------------------------------
out <- file.path("tests", "testthat", "fixtures", "bayesian-fixed-oracle.rds")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020),",
      "doi:10.1007/978-3-030-43469-4_7 (prior/MAP/percentile);",
      "McGraw & Wong (1996) Case 3A (fixed-rater finite-population theta^2_r)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_subjects = n_subjects,
      s2_s = s2_s,
      s2_res = s2_res,
      mu_r = mu_r,
      theta2_r = theta2_r
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
