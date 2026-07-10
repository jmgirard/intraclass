# oracle-bayesian-incomplete-oneway.R
# ===========================================================================
# Provenance for O-Bayes-IOneway: the brms (Bayesian) engine +
# ci_method = "posterior" for INCOMPLETE/ragged SINGLE-LEVEL ONE-WAY ICCs
# (Milestone 33 Slice 1, ADR-043). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-oneway-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION THIS ORACLE ANSWERS (#1, the slice's one genuine unknown).
# Every mechanical piece is REUSED, oracle-pinned code: fit_brms_oneway()
# (M26 Slice 1, the two-component score ~ 1 + (1 | subject) fit under the
# half-t(4,0,1) SD prior), the M3/M6 harmonic-mean k_eff divisor (ADR-008),
# and the shipped brms_component_draws() / posterior_summary() reducers. The
# `!balanced` brms guard is merely narrowed (icc.R:1158) so the one-way path
# reaches that unchanged fit on ragged data. One-way is RANDOM -- each ICC is a
# RATIO of variance components, so there is no theta^2 finite-population
# functional and no M27/M28 2b moment correction (the M30 clean-push-forward
# regime, NOT the M31 fixed regime). What is NOT inherited from any shipped
# oracle is whether the percentile CREDIBLE interval COVERS nominally on RAGGED
# one-way data -- in particular the average-unit ICC(1, k_eff), whose error is
# divided by the harmonic-mean k_eff (an approximation on unequal per-subject
# rating counts). A CI method's oracle is COVERAGE (#1; M16/M23 precedent), so
# this script simulates it directly.
#
# DESIGN OF THE SIMULATION. Two cells share one one-way DGP (k = 5 ratings per
# subject at balance, well past the k = 2 caveat so any undercoverage is
# attributable to RAGGEDNESS, not small k):
#   * COMPLETE -- the full 30 x 5 one-way design. k_eff = k = 5; the incomplete
#     path must REDUCE to the shipped M26 Slice 1 behaviour (nominal coverage).
#     This is the reduction pin.
#   * RAGGED -- a FIXED incidence pattern with ~20% of the rating slots deleted
#     (same pattern every replication; only the scores are redrawn), giving a
#     constant k_eff < 5. Coverage of ICC(1) (no divisor) and ICC(1, k_eff)
#     (the divisor is exercised) are both tallied. If ragged coverage tracks the
#     complete cell -> ships clean; if it undercovers, the finding is REPORTED
#     honestly (#18) and a gated Fable review recommended (#19) -- NOT tuned away.
#   One-way has no subject x rater crossing to keep connected (raters are
#   interchangeable rating slots), so the incidence need only keep every subject
#   with >= 2 ratings (k_eff well-defined, no subject drops out).
#
# n_rep = 240 per cell + PER-REP DATA SEEDING (the M32 Slice 2 convention, ADR-042
# Amendment 2): at n_rep = 80 the ragged coverage pin false-alarms at ~0.7% per
# cell under a nominal estimator (a Monte-Carlo tail event, not a shortfall --
# data-raw/reviews/fable-review-m32-s2-response.md). At n_rep = 240 the coverage
# SE ~ sqrt(.95*.05/240) ~ .014, so a real shortfall is separable from noise.
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions to Estimate Variance Components for Interrater
#     Reliability Coefficients. Springer Proc. Math. & Stat. 322, 79-93.
#     doi:10.1007/978-3-030-43469-4_7. OSF: shkqm. (prior + half-t + MCMC recipe)
#   Shrout & Fleiss (1979) Case 1 / McGraw & Wong (1996) one-way random (estimand;
#     no new spec, reuses M6-oneway.md). The ragged extension is NOT in the source
#     (their study is balanced); the independent oracle for the ragged POINT is the
#     shipped glmmTMB/lme4 M6+M3 estimator (ADR-008), cross-checked in the test
#     file. This script pins COVERAGE.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_subjects <- 30L
k <- 5L
s2_s <- 0.5
s2_res <- 0.5 # population ICC(1) = 0.5, an INTERIOR ratio away from the boundary
n_rep <- 240L
base_seed <- 33100L
missing_frac <- 0.20 # fraction of the 30 x 5 rating slots deleted in the ragged cell

brm_args <- list(
  chains = 3L,
  iter = 1500L,
  warmup = 750L,
  cores = 3L,
  refresh = 0L
)

# The one-way component -> posterior-draw-column map (M26); passed to the shipped
# reducers (which take an explicit `spec`/`vars` since M24, ADR-034).
spec_ow <- c(
  subject = "sd_subject__Intercept",
  residual = "sigma"
)

pop_icc <- function(m) s2_s / (s2_s + s2_res / m)

# A FIXED ragged incidence over the 30 x 5 one-way grid (seeded once). One-way needs
# no connectedness (raters are interchangeable slots); require only that every subject
# keeps >= 2 ratings so k_eff is well-defined and no subject drops out. k_eff is read
# from the SHIPPED summarize_design() -- the exact divisor the icc() one-way path uses.
make_incidence <- function(seed) {
  full <- expand.grid(subject = seq_len(n_subjects), rater = seq_len(k))
  n_drop <- round(missing_frac * nrow(full))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    drop <- sample(nrow(full), n_drop)
    keep <- full[-drop, ]
    if (min(table(factor(keep$subject, levels = seq_len(n_subjects)))) >= 2L) {
      di <- intraclass:::summarize_design(data.frame(
        subject = factor(keep$subject, levels = seq_len(n_subjects)),
        rater = factor(keep$rater, levels = seq_len(k)),
        score = 0
      ))
      return(list(keep = keep, k_eff = di$k_eff, seed = seed))
    }
  }
}

inc <- make_incidence(base_seed)
k_eff_ragged <- inc$k_eff
message(sprintf(
  "Ragged incidence: %d of %d slots kept, k_eff = %.4f",
  nrow(inc$keep),
  n_subjects * k,
  k_eff_ragged
))

# One dataset from the one-way DGP (Y = mu_s + e), either the full grid ("complete")
# or restricted to the fixed ragged incidence ("ragged"). Rater identity is nominal
# (a rating slot); the fit ignores it (score ~ 1 + (1 | subject)). Scores redrawn per rep.
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
    score = mu_s[grid$subject] + e
  )
}

# Compile the Stan model ONCE (identical formula/prior across cells); every rep
# refits via update(recompile = FALSE), applying the SHIPPED reducers so this
# validates the exact recipe fit_brms_oneway() + posterior_summary() use.
message("Compiling the base Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | subject),
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> coverage of ICC(1) (no divisor) and ICC(1, k_eff) (the
# harmonic-mean divisor is exercised), MAP relative bias, and convergence. The
# per-design k_eff is k for the complete cell and the fixed ragged k_eff otherwise.
one_rep <- function(design, seed) {
  # Per-rep DATA seed (M32/Fable protocol): each rep's score draw is seeded from its
  # own `seed`, so cells are individually reproducible and EXTENDABLE (bumping n_rep
  # does not re-deal earlier reps). The fixed ragged incidence is drawn separately in
  # make_incidence() and is unaffected.
  set.seed(seed)
  d <- simulate(design)
  keff <- if (design == "complete") k else k_eff_ragged
  fit <- suppressWarnings(suppressMessages(stats::update(
    base_fit,
    newdata = d,
    seed = seed,
    recompile = FALSE,
    refresh = 0
  )))
  draws <- intraclass:::brms_component_draws(fit, spec_ow)
  est1 <- intraclass:::icc_estimand(
    unit = "single",
    k_eff = keff,
    oneway = TRUE
  )
  estk <- intraclass:::icc_estimand(
    unit = "average",
    k_eff = keff,
    oneway = TRUE
  )
  summ <- intraclass:::posterior_summary(
    draws,
    list(icc1 = est1, icck = estk),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ow))
  p1 <- pop_icc(1)
  pk <- pop_icc(keff)
  s1 <- summ$icc1
  sk <- summ$icck
  out <- data.frame(
    design = design,
    k_eff = keff,
    map_icc1 = s1$point,
    cover_icc1 = s1$conf.low <= p1 && p1 <= s1$conf.high,
    map_icck = sk$point,
    cover_icck = sk$conf.low <= pk && pk <= sk$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-incomplete-oneway-checkpoint.rds"
# Distinct per-cell seed streams so the two cells are independent and each rep is
# reproducible from base_seed + (cell offset) + r.
cell_offset <- c(complete = 0L, ragged = 100000L)
rows <- if (file.exists(ckpt)) readRDS(ckpt) else list()
done <- length(rows)
todo <- expand.grid(
  r = seq_len(n_rep),
  design = c("complete", "ragged"),
  stringsAsFactors = FALSE
)
todo <- todo[c("design", "r")]
todo <- todo[order(match(todo$design, c("complete", "ragged")), todo$r), ]
for (i in seq_len(nrow(todo))) {
  if (i <= done) {
    next
  }
  design <- todo$design[i]
  r <- todo$r[i]
  rows[[i]] <- one_rep(design, seed = base_seed + cell_offset[[design]] + r)
  if (i %% 20L == 0L) {
    saveRDS(rows, ckpt)
    message(sprintf("  ... %d / %d fits done", i, nrow(todo)))
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
      pop_icc1 = pop_icc(1),
      pop_icck = pop_icc(x$k_eff[1]),
      converged_frac = mean(x$converged),
      map_icc1_relbias = mean(x$map_icc1) / pop_icc(1) - 1,
      coverage_icc1 = mean(x$cover_icc1),
      map_icck_relbias = mean(x$map_icck) / pop_icc(x$k_eff[1]) - 1,
      coverage_icck = mean(x$cover_icck)
    )
  })
)
print(agg)

# --- Commit the reference (BEFORE the hard pins) ---------------------------
# Write the seeded output first, so the fixture reflects the TRUE run even if a pin
# trips (the honest-signal design, #4/#18; the M32 Slice 2 precedent).
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-oneway-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020),",
      "doi:10.1007/978-3-030-43469-4_7 (prior/MAP/percentile recipe);",
      "Shrout & Fleiss (1979) / McGraw & Wong (1996) Case 1 (estimand);",
      "ragged point cross-checked vs glmmTMB/lme4 M6+M3 (ADR-008)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_subjects = n_subjects,
      k = k,
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
unlink(ckpt)

# --- Validate: reduction + coverage (the pins) -----------------------------
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP in both cells (k = 5, past the caveat).
stopifnot(all(agg$converged_frac >= 0.90))

# (2) k_eff strictly shrinks under imbalance (the divisor is genuinely exercised).
stopifnot(rag$k_eff < k, rag$k_eff > 1)

# (3) REDUCTION: on complete data the incomplete path is the shipped M26 Slice 1
#     path (k_eff = k), so both units cover ~nominal -- the baseline the ragged cell
#     is judged against.
stopifnot(
  cmp$coverage_icc1 >= 0.90,
  cmp$coverage_icc1 <= 0.99,
  cmp$coverage_icck >= 0.90,
  cmp$coverage_icck <= 0.99
)

# (4) COVERAGE ON RAGGED DATA (the slice's one unknown). Written as an HONEST CHECK,
#     not a target: ragged coverage must track the complete cell and stay ~nominal for
#     BOTH units. One-way is random -> a clean variance-ratio push-forward (no 2b), so
#     no undercoverage is expected (the M30 regime). If this stops() fires, DO NOT relax
#     it: characterize the shortfall (#18) and recommend a gated Fable review (#19)
#     before shipping Slice 1.
stopifnot(
  rag$coverage_icc1 >= 0.90,
  rag$coverage_icc1 <= 0.99,
  rag$coverage_icck >= 0.90,
  rag$coverage_icck <= 0.99
)

# (5) MAP tracks the population (small negative skew allowed; MAP-below-REML, the
#     M23/M26 posture) in both cells and units.
stopifnot(
  abs(cmp$map_icc1_relbias) < 0.10,
  abs(rag$map_icc1_relbias) < 0.12
)

message("All O-Bayes-IOneway pins passed.")
