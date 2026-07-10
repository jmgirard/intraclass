# oracle-bayesian-incomplete.R
# ===========================================================================
# Provenance for O-Bayes-Incomplete: the brms (Bayesian) engine +
# ci_method = "posterior" for INCOMPLETE/ragged two-way random ICCs
# (Milestone 30 Slice 1, ADR-040). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION THIS ORACLE ANSWERS (#1, the milestone's one genuine unknown).
# Every mechanical piece of the incomplete path is REUSED, oracle-pinned code:
# the M3 harmonic-mean k_eff divisor + connectedness (ADR-008), the M23 brms
# fit + half-t(4,0,1) prior + MAP/percentile reduction. Random raters make each
# ICC a RATIO of variance components -- no theta^2 finite-population functional,
# so no M27/M28 2b moment correction (the M29 clean-push-forward regime). What
# is NOT inherited from any shipped oracle is whether the percentile CREDIBLE
# interval COVERS nominally on RAGGED data -- in particular the average-unit
# ICC(A, k_eff), whose error is divided by the harmonic-mean k_eff (an
# approximation on unequal per-subject rating counts). A CI method's oracle is
# COVERAGE (#1; M16/M23 precedent), so this script simulates it directly.
#
# DESIGN OF THE SIMULATION. Two cells share one DGP (ten Hove 2020 Sec. 4.1.1,
# k = 5, well past the k = 2 caveat so any undercoverage is attributable to
# RAGGEDNESS, not small k):
#   * COMPLETE -- the full 30 x 5 crossed design. k_eff = k = 5; the incomplete
#     path must REDUCE to the shipped M23 behaviour (nominal coverage). This is
#     the reduction pin.
#   * RAGGED -- a FIXED, connected incidence pattern with ~20% of cells deleted
#     (same pattern every replication; only the scores are redrawn), giving a
#     constant k_eff < 5. The coverage of ICC(A,1) (no divisor) and
#     ICC(A, k_eff) (the divisor is exercised) are both tallied. If ragged
#     coverage tracks the complete cell -> ships clean; if it undercovers, the
#     finding is REPORTED honestly (#18) and a gated Fable review recommended
#     (#19) -- NOT tuned away.
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions to Estimate Variance Components for Interrater
#     Reliability Coefficients. Springer Proc. Math. & Stat. 322, 79-93.
#     doi:10.1007/978-3-030-43469-4_7. OSF: shkqm. (DGP + half-t prior + MCMC.)
#   The ragged extension is NOT in the source (their study is balanced); the
#   independent oracle for the ragged point is the shipped glmmTMB M3 estimator
#   (ADR-008), cross-checked in the test file. This script pins COVERAGE.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subjects <- 30L
k <- 5L
s2_s <- 0.5
s2_sr <- 0.5
s2_r <- 0.04 # a small but non-zero rater variance (the source's harder cell)
n_rep <- 200L
base_seed <- 30100L
missing_frac <- 0.20 # fraction of the 30 x 5 cells deleted in the ragged cell

brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

spec_tw <- c(
  subject = "sd_subject__Intercept",
  rater = "sd_rater__Intercept",
  residual = "sigma"
)

pop_icc <- function(m) s2_s / (s2_s + (s2_r + s2_sr) / m)

# A FIXED, connected ragged incidence pattern over the 30 x 5 grid (seeded once).
# Deleting cells at random can disconnect the subject x rater graph; retry until
# summarize_design() reports connected and every subject/rater keeps >= 2 cells
# (so k_eff is well-defined and no rater/subject drops out).
make_incidence <- function(seed) {
  full <- expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  n_drop <- round(missing_frac * nrow(full))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    drop <- sample(nrow(full), n_drop)
    keep <- full[-drop, ]
    ok_rows <- min(table(keep$subject)) >= 2L && min(table(keep$rater)) >= 2L
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

# One dataset from the DGP, either the full grid ("complete") or restricted to
# the fixed ragged incidence ("ragged"). Scores are redrawn every replication.
simulate <- function(design) {
  mu_s <- stats::rnorm(n_subjects, 0, sqrt(s2_s))
  mu_r <- stats::rnorm(k, 0, sqrt(s2_r))
  grid <- if (design == "complete") {
    expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  } else {
    inc$keep
  }
  mu_sr <- stats::rnorm(nrow(grid), 0, sqrt(s2_sr))
  data.frame(
    subject = factor(grid$subject, levels = seq_len(n_subjects)),
    rater = factor(grid$rater, levels = seq_len(k)),
    score = mu_s[grid$subject] + mu_r[grid$rater] + mu_sr
  )
}

# Compile the Stan model ONCE (identical formula/prior across cells); every rep
# refits via update(recompile = FALSE), applying the SHIPPED reducers so this
# validates the exact recipe fit_brms_twoway() + posterior_summary() use.
message("Compiling the base Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | subject) + (1 | rater),
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
  draws <- intraclass:::brms_component_draws(fit, spec_tw)
  est1 <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = keff
  )
  estk <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "average",
    raters = "random",
    k_eff = keff
  )
  s1 <- intraclass:::posterior_summary(draws, list(est1), 0.95)[[1]]
  sk <- intraclass:::posterior_summary(draws, list(estk), 0.95)[[1]]
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_tw))
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

# (2) REDUCTION: on complete data the incomplete path is the shipped M23 path
#     (k_eff = k), so both units cover ~nominal -- the baseline the ragged cell
#     is judged against.
stopifnot(
  cmp$coverage_icc1 >= 0.90,
  cmp$coverage_icc1 <= 0.99,
  cmp$coverage_icck >= 0.90,
  cmp$coverage_icck <= 0.99
)

# (3) COVERAGE ON RAGGED DATA (the milestone's one unknown). The pin is written
#     as an HONEST CHECK, not a target: ragged coverage must track the complete
#     cell within Monte-Carlo error. SE(coverage) ~ sqrt(.95*.05/n_rep) ~ .015 at
#     n_rep = 200, so a >~0.05 shortfall vs. complete is a real finding, not noise.
#     If this stops() fires, DO NOT relax it: characterize the shortfall (#18) and
#     recommend a gated Fable review (#19) before shipping Slice 1.
stopifnot(
  rag$coverage_icc1 >= cmp$coverage_icc1 - 0.05,
  rag$coverage_icck >= cmp$coverage_icck - 0.05,
  rag$coverage_icc1 >= 0.90,
  rag$coverage_icck >= 0.90
)

# (4) MAP tracks the population (small negative skew allowed; MAP-below-REML, the
#     M23/M26 posture) in both cells.
stopifnot(
  abs(cmp$map_icc1_relbias) < 0.10,
  abs(rag$map_icc1_relbias) < 0.12
)

# --- Commit the reference --------------------------------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = "ten Hove, Jorgensen & van der Ark (2020), doi:10.1007/978-3-030-43469-4_7; ragged extension pinned to glmmTMB M3 (ADR-008)",
    generated = Sys.Date(),
    dgp = list(
      n_subjects = n_subjects,
      k = k,
      s2_s = s2_s,
      s2_r = s2_r,
      s2_sr = s2_sr,
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
