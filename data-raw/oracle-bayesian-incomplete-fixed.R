# oracle-bayesian-incomplete-fixed.R
# ===========================================================================
# Provenance for O-Bayes-IFixed: the brms (Bayesian) engine +
# ci_method = "posterior" for INCOMPLETE/ragged two-way FIXED-rater ICCs
# (Milestone 31 Slice 1, ADR-041). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-fixed-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION THIS ORACLE ANSWERS (#1, the milestone's one genuine unknown).
# This is the FIXED-rater sibling of oracle-bayesian-incomplete.R (M30 S1,
# random). Unlike the random path -- where each ICC is a RATIO of variance
# components and the posterior push-forward is clean (no theta^2 functional) --
# the fixed-rater rater effect is the finite-population variance theta^2_r =
# mu' C mu / (k - 1), a CONVEX QUADRATIC functional of the k fixed rater means.
# The shipped brms_theta2r_moment_draws() corrects the per-draw push-forward by
# 2b, b = tr(C.Sigma_post)/(k - 1) (ADR-037/038; the gated-Fable resolution),
# and floors the group AVERAGE. On BALANCED single-level data the rater means
# come from the whole sample, so b ~= 0 and the correction is INVISIBLE (the
# M26 raw regime). On RAGGED data the rater means are estimated from UNEQUAL
# cell counts, so b != 0 FOR THE FIRST TIME IN THE SINGLE-LEVEL REGIME -- the 2b
# machinery goes live where it has never been exercised. What is NOT inherited
# from any shipped oracle is whether the percentile CREDIBLE interval COVERS
# nominally once b != 0 single-level. A CI method's oracle is COVERAGE (#1;
# M16/M23/M30 precedent), so this script simulates it directly, through the
# SHIPPED brms_theta2r_draws() (2b + average-floor), NOT a hand recipe.
#
# DESIGN OF THE SIMULATION. Two cells share one FIXED-rater DGP (k = 5, well
# past the k = 2 caveat, so any undercoverage is attributable to RAGGEDNESS +
# the newly-live 2b correction, not small k):
#   * COMPLETE -- the full 30 x 5 crossed design. k_eff = k = 5 and b ~= 0; the
#     incomplete path must REDUCE to the shipped M26 fixed behaviour (nominal
#     coverage). This is the reduction pin.
#   * RAGGED -- a FIXED, connected incidence pattern with ~20% of cells deleted
#     (same pattern every replication; only the scores are redrawn), giving a
#     constant k_eff < 5 AND b != 0. Coverage of the fixed-population ICC(A,1)
#     (no divisor) and ICC(A, k_eff) (the harmonic-mean divisor is exercised)
#     are both tallied. If ragged coverage tracks the complete cell -> ships
#     clean; if it undercovers, the finding is REPORTED honestly (#18) and a
#     gated Fable review recommended (#19) -- NOT tuned away (#4).
#
# ESTIMAND (sourced -- #1/#4; no new spec, reuses M3 Sec.6 / M10 Sec.2)
# ---------------------------------------------------------------------------
#   McGraw & Wong (1996) Case 3A fixed raters: theta^2_r = the finite-population
#   variance of the k FIXED rater means; ICC(A,1) = sigma^2_s / (sigma^2_s +
#   theta^2_r + sigma^2_res). The raters are a fixed finite population, so mu_rj
#   are FIXED across replications (not redrawn) -- coverage is of this fixed
#   population's ICC(A,m).
#
# PRIOR / POINT / INTERVAL (sourced, #12; unchanged from M23/M26)
# ---------------------------------------------------------------------------
#   ten Hove, Jorgensen & van der Ark (2020): half-t(4, 0, 1) on sigma_s (the
#   k - 1 rater contrasts keep brms's default flat prior); MAP point + percentile
#   95% credible interval. The ragged extension is NOT in the source (their study
#   is balanced); the independent oracle for the ragged POINT is the shipped
#   glmmTMB M3 fixed estimator (ADR-008), cross-checked in the test file. This
#   script pins COVERAGE.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subjects <- 30L
mu_r <- c(-0.6, -0.3, 0, 0.3, 0.6) # FIXED finite population of k = 5 rater means
k <- length(mu_r)
theta2_r <- sum((mu_r - mean(mu_r))^2) / (k - 1) # = 0.225
s2_s <- 0.5
s2_res <- 0.5
n_rep <- 200L
base_seed <- 31100L
missing_frac <- 0.20 # fraction of the 30 x 5 cells deleted in the ragged cell

brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

spec_sr <- c(subject = "sd_subject__Intercept", residual = "sigma")

# Fixed-population ICC at averaging count m (raters FIXED -> theta^2_r fixed).
pop_icc <- function(m) s2_s / (s2_s + (theta2_r + s2_res) / m)

# A FIXED, connected ragged incidence over the 30 x 5 grid (seeded once). Deleting
# cells at random can disconnect the subject x rater graph or drop a fixed rater;
# retry until summarize_design() reports connected and every subject/rater keeps
# >= 2 cells (so k_eff is well-defined and all k fixed raters stay in the design).
make_incidence <- function(seed) {
  full <- expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  n_drop <- round(missing_frac * nrow(full))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    drop <- sample(nrow(full), n_drop)
    keep <- full[-drop, ]
    ok_rows <- min(table(keep$subject)) >= 2L &&
      length(unique(keep$rater)) == k &&
      min(table(keep$rater)) >= 2L
    if (!ok_rows) {
      next
    }
    di <- intraclass:::summarize_design(data.frame(
      subject = factor(keep$subject, levels = seq_len(n_subjects)),
      rater = factor(keep$rater, levels = seq_len(k)),
      score = 0
    ))
    if (isTRUE(di$connected)) {
      return(list(keep = keep, k_eff = di$k_eff, seed = seed))
    }
  }
}

inc <- make_incidence(base_seed)
k_eff_ragged <- inc$k_eff
message(sprintf(
  "Ragged incidence: %d of %d cells kept, k_eff = %.4f",
  nrow(inc$keep),
  n_subjects * k,
  k_eff_ragged
))

# One dataset from the FIXED-rater DGP (Y = mu_s + mu_r[fixed] + e), either the
# full grid ("complete") or restricted to the fixed ragged incidence ("ragged").
# The rater means are FIXED; only mu_s and e are redrawn each replication.
simulate <- function(design) {
  mu_s <- stats::rnorm(n_subjects, 0, sqrt(s2_s))
  grid <- if (design == "complete") {
    expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  } else {
    inc$keep
  }
  e <- stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  data.frame(
    subject = factor(grid$subject, levels = seq_len(n_subjects)),
    rater = factor(grid$rater, levels = seq_len(k)),
    score = mu_s[grid$subject] + mu_r[grid$rater] + e
  )
}

# Compile the Stan model ONCE (identical formula/prior across cells); every rep
# refits via update(recompile = FALSE). Each rep applies the SHIPPED reducers --
# brms_theta2r_draws() (the 2b + average-floor moment correction) for the rater
# slot and brms_component_draws() for subject/residual -- so this validates the
# EXACT recipe fit_brms_fixed() uses, with 2b live on the ragged cell.
message("Compiling the base Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + rater + (1 | subject),
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> coverage of ICC(A,1) (no divisor) and ICC(A, k_eff) (the
# harmonic-mean divisor is exercised), MAP relative bias, and convergence. The
# per-design k_eff is k for the complete cell and the fixed ragged k_eff otherwise.
one_rep <- function(design, seed) {
  d <- simulate(design)
  keff <- if (design == "complete") k else k_eff_ragged
  fit <- suppressWarnings(suppressMessages(stats::update(
    base_fit,
    newdata = d,
    seed = seed,
    recompile = FALSE,
    refresh = 0
  )))
  # theta^2_r per draw through the SHIPPED moment correction (2b + average-floor).
  theta <- intraclass:::brms_theta2r_draws(fit, d)
  sr <- intraclass:::brms_component_draws(fit, spec_sr)
  draws <- rbind(
    subject = sr["subject", ],
    rater = theta,
    residual = sr["residual", ]
  )
  est1 <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "fixed",
    k_eff = keff
  )
  estk <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "average",
    raters = "fixed",
    k_eff = keff
  )
  s1 <- intraclass:::posterior_summary(draws, list(est1), 0.95)[[1]]
  sk <- intraclass:::posterior_summary(draws, list(estk), 0.95)[[1]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_sr))
  p1 <- pop_icc(1)
  pk <- pop_icc(keff)
  out <- data.frame(
    design = design,
    k_eff = keff,
    pop_icc1 = p1,
    pop_icck = pk,
    map_icc1 = s1$point,
    map_icck = sk$point,
    cover_icc1 = s1$conf.low <= p1 && p1 <= s1$conf.high,
    cover_icck = sk$conf.low <= pk && pk <= sk$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
set.seed(base_seed)
rows <- list()
for (design in c("complete", "ragged")) {
  message(sprintf("Cell '%s': %d reps", design, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(design, seed = base_seed + r)
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to per-cell reference statistics ----------------------------
agg <- do.call(
  rbind,
  lapply(c("complete", "ragged"), function(design) {
    x <- reps[reps$design == design, ]
    data.frame(
      design = design,
      k_eff = x$k_eff[1],
      n_rep = nrow(x),
      pop_icc1 = x$pop_icc1[1],
      pop_icck = x$pop_icck[1],
      theta2_r = theta2_r,
      converged_frac = mean(x$converged),
      map_icc1_relbias = mean(x$map_icc1) / x$pop_icc1[1] - 1,
      map_icck_relbias = mean(x$map_icck) / x$pop_icck[1] - 1,
      coverage_icc1 = mean(x$cover_icc1),
      coverage_icck = mean(x$cover_icck)
    )
  })
)
print(agg)

# --- Validate: reduction + coverage (the pins) -----------------------------
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP in both cells (k = 5, past the caveat).
stopifnot(all(agg$converged_frac >= 0.90))

# (2) REDUCTION: on complete data the incomplete path IS the shipped M26 fixed path
#     (k_eff = k, b ~= 0), so both units cover ~nominal -- the baseline the ragged
#     cell is judged against.
stopifnot(
  cmp$coverage_icc1 >= 0.88,
  cmp$coverage_icc1 <= 0.99,
  cmp$coverage_icck >= 0.88,
  cmp$coverage_icck <= 0.99
)

# (3) COVERAGE ON RAGGED DATA (the milestone's one unknown, where 2b goes live
#     single-level). Written as an HONEST CHECK, not a target: ragged coverage must
#     track the complete cell within Monte-Carlo error. SE(coverage) ~
#     sqrt(.95*.05/n_rep) ~ .015 at n_rep = 200, so a > ~0.05 shortfall vs. complete
#     is a real finding, not noise. If this stops() fires, DO NOT relax it:
#     characterize the shortfall (#18) and recommend a gated Fable review (#19)
#     before shipping Slice 1.
stopifnot(
  rag$coverage_icc1 >= cmp$coverage_icc1 - 0.05,
  rag$coverage_icck >= cmp$coverage_icck - 0.05,
  rag$coverage_icc1 >= 0.88,
  rag$coverage_icck >= 0.88
)

# (4) MAP is biased low (the mode of the right-skewed ICC draws sits below the
#     population plug-in, the M23/M26 posture) -- characterized, not asserted
#     unbiased. A small positive tolerance absorbs Monte-Carlo wobble.
stopifnot(
  cmp$map_icc1_relbias < 0.02,
  rag$map_icc1_relbias < 0.02
)

# --- Commit the reference --------------------------------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-fixed-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020),",
      "doi:10.1007/978-3-030-43469-4_7 (prior/MAP/percentile);",
      "McGraw & Wong (1996) Case 3A (fixed-rater finite-population theta^2_r);",
      "ragged extension pinned to glmmTMB M3 (ADR-008)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_subjects = n_subjects,
      k = k,
      mu_r = mu_r,
      theta2_r = theta2_r,
      s2_s = s2_s,
      s2_res = s2_res,
      missing_frac = missing_frac,
      k_eff_ragged = k_eff_ragged
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    stats = agg
  ),
  out
)
message("Wrote ", out)
