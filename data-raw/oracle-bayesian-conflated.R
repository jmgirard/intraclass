# oracle-bayesian-conflated.R
# ===========================================================================
# Provenance for O-Bayes-Conflated: the brms (Bayesian) engine + ci_method =
# "posterior" for the CONFLATED single-level diagnostic ICC (ten Hove et al.
# 2022, Eq. 14) off the CROSSED (Design 1) five-component fit (Milestone 29
# Slice 1, ADR-039). The Bayesian sibling of the frequentist conflated oracle
# (M17 Slice 1, data-raw/oracle-multilevel.R) and a thin companion to
# data-raw/oracle-bayesian-multilevel.R (M24) -- the SAME five-component brms
# fit, read through the conflated estimand (signal = cluster + subject, error =
# rater + cluster_rater + residual). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-conflated-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4) -- the
# reference is this script's own seeded output.
#
# ENGINE/INTERVAL PARITY, NOT NEW ESTIMAND WORK. The conflated coefficient is
# the shipped M17 Eq. 14 diagnostic; M29 gives it the brms engine. It is a
# VARIANCE-RATIO push-forward (like every random-rater Bayesian coefficient), so
# NONE of the theta^2 finite-population moment correction (M27/M28) applies -- the
# conflated ICC composes off the posterior draws exactly as the subject/cluster
# levels do (posterior_summary() -> icc_point()).
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). The source DGP is a
# simulation, so there is no worked-example point to reproduce -- the oracle is
# that the shipped brms + half-t(4,0,1) + MAP/percentile pipeline, read through
# the conflated estimand, (a) covers the known population Eq. 14 value, (b)
# CONTAINS the frequentist glmmTMB conflated point in its credible interval
# (glmmTMB the independent engine; the O-population/O-lme4 analogs of M17 §5),
# and (c) reports a conflated ICC visibly DISTINCT from the subject level (the
# diagnostic's whole purpose -- it folds between-cluster variance into the
# signal, so it overstates the within-cluster reliability).
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93. The
#     half-t(4,0,1)-on-every-SD prior + MAP/percentile recipe (Sec. 4.1-4.2).
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data: A generalizability theory approach.
#     Psychological Methods, 27(4), 650-666. Eq. 14 (the conflated single-level
#     ICC that ignores clustering); the crossed Design-1 decomposition (Eqs.
#     7/12, Table 3) it is read from. Estimand-spec M17-conflated-icc.md.
#
# DGP (this run): crossed Design 1, N_c = 20 clusters, N_s = 5 subjects/cluster,
#   with a LARGE between-cluster variance so the conflated ICC clearly overstates
#   the subject level (Eq. 14 folds sigma^2_c into the signal):
#     sigma^2_c   = 1.50   (between-cluster true score; the conflation source)
#     sigma^2_s:c = 1.00   (subject-in-cluster true score)
#     sigma^2_r   = 0.16   (rater main effect)
#     sigma^2_cr  = 0.16   (cluster x rater)
#     sigma^2_res = 0.50   (confounded highest-order residual)
#   One well-conditioned cell, k = 5. Population values (Eq. 14 vs subject-level
#   Eq. 12, single rater):
#     conflated = (s2_c + s2_sc) / (s2_c + s2_sc + s2_r + s2_cr + s2_res)
#     subject   = s2_sc / (s2_sc + s2_r + s2_res)
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori. The conflated inherits the cluster level's few-cluster caveat
#   (sigma^2_c estimated from 20 clusters), so any MAP bias is REPORTED, not
#   tuned; the honest recovery check is INTERVAL COVERAGE (M17 §5 O-population).
#   The fixture is written BEFORE the hard assertions so a long run is never lost.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 20L
n_subj_per <- 5L
s2_c <- 1.50
s2_sc <- 1.00
s2_r <- 0.16
s2_cr <- 0.16
s2_res <- 0.50
k <- 5L
n_rep <- 80L
base_seed <- 20290L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The five-component -> posterior-draw-column map fit_brms_multilevel() uses.
spec_ml <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  rater = "sd_rater__Intercept",
  cluster_rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# Population values from the DGP components.
pop_conflated <- (s2_c + s2_sc) / (s2_c + s2_sc + s2_r + s2_cr + s2_res)
pop_subject <- s2_sc / (s2_sc + s2_r + s2_res)

# One dataset from the crossed Design-1 DGP (long format, factors).
simulate_multilevel <- function(k) {
  grid <- expand.grid(
    s = seq_len(n_subj_per),
    rater = seq_len(k),
    cluster = seq_len(n_clusters)
  )
  sid <- paste0(grid$cluster, "_", grid$s)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  mu_r <- stats::rnorm(k, 0, sqrt(s2_r))
  mu_cr <- stats::rnorm(n_clusters * k, 0, sqrt(s2_cr))
  data.frame(
    cluster = factor(grid$cluster),
    subject = factor(sid),
    rater = factor(grid$rater),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_r[grid$rater] +
      mu_cr[as.integer(interaction(grid$cluster, grid$rater))] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  )
}

# Compile the Stan model ONCE; every rep refits via update(recompile = FALSE) and
# runs the SHIPPED reducers (brms_component_draws / posterior_summary), so this
# validates the exact recipe the conflated brms path uses.
message("Compiling the base multilevel Stan model once ...")
d0 <- simulate_multilevel(k)
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~
        1 +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | rater) +
        (1 | cluster:rater),
      data = d0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

conflated_est <- intraclass:::icc_estimand(
  type = "agreement",
  unit = "single",
  raters = "random",
  k_eff = k,
  multilevel = TRUE,
  level = "conflated"
)
subject_est <- intraclass:::icc_estimand(
  type = "agreement",
  unit = "single",
  raters = "random",
  k_eff = k,
  multilevel = TRUE,
  level = "subject"
)

# One replication -> the per-rep conflated statistics. Refits on a fresh dataset,
# reads the conflated MAP + percentile credible interval (coverage of the known
# Eq. 14 value), the subject-level MAP (the distinctness contrast), the glmmTMB
# conflated point (containment), and convergence.
one_rep <- function(seed) {
  d <- simulate_multilevel(k)
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base_fit,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  draws <- intraclass:::brms_component_draws(fit, spec_ml)
  summ <- intraclass:::posterior_summary(
    draws,
    list(conflated = conflated_est, subject = subject_est),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  # Independent engine (glmmTMB) conflated point on the same data (M17 path).
  gt <- suppressWarnings(suppressMessages(
    intraclass::icc(
      d,
      score = score,
      subject = subject,
      rater = rater,
      cluster = cluster,
      type = "agreement",
      raters = "random",
      level = "conflated",
      engine = "glmmTMB"
    )
  ))
  gt_conflated <- gt$estimates$estimate[1]
  cc <- summ$conflated
  rm(fit)
  gc(verbose = FALSE)
  data.frame(
    conf_map = cc$point,
    conf_lo = cc$conf.low,
    conf_hi = cc$conf.high,
    subj_map = summ$subject$point,
    gt_conflated = gt_conflated,
    cover_pop = cc$conf.low <= pop_conflated && pop_conflated <= cc$conf.high,
    contain_gt = cc$conf.low <= gt_conflated && gt_conflated <= cc$conf.high,
    converged = converged
  )
}

# --- Run the simulation ----------------------------------------------------
# ~80 hierarchical refits + a cheap glmmTMB fit each. Checkpoint after each rep so
# a crash in the tail never forces re-sampling.
ckpt <- "data-raw/.oracle-bayesian-conflated-checkpoint.rds"
set.seed(base_seed)
rows <- vector("list", n_rep)
for (r in seq_len(n_rep)) {
  rows[[r]] <- one_rep(seed = base_seed + r)
  if (r %% 10L == 0L) {
    message(sprintf("  ... %d/%d reps", r, n_rep))
    saveRDS(do.call(rbind, rows[seq_len(r)]), ckpt)
  }
}
reps <- do.call(rbind, rows)

# --- Aggregate to the reference statistics ---------------------------------
agg <- data.frame(
  k = k,
  n_rep = nrow(reps),
  pop_conflated = pop_conflated,
  pop_subject = pop_subject,
  converged_frac = mean(reps$converged),
  conf_map_mean = mean(reps$conf_map),
  conf_map_relbias = mean(reps$conf_map) / pop_conflated - 1,
  subj_map_mean = mean(reps$subj_map),
  coverage_conflated = mean(reps$cover_pop),
  containment_glmmtmb = mean(reps$contain_gt),
  map_minus_subject = mean(reps$conf_map - reps$subj_map)
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-conflated-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 Eq. 14 [conflated estimand/DGP]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      k = k,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_r = s2_r,
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

# --- Validate against the source's qualitative findings (the pins) ---------
# QUALITATIVE pins (a coverage oracle reproduces behaviour, not decimals);
# tolerances absorb finite n_rep and the INDEPENDENT MAP estimator (#4/#18).
# Observed values are filled into the test after the run (honest, not tuned).

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90).
stopifnot(agg$converged_frac >= 0.90)
# (2) The conflated credible interval COVERS the known Eq. 14 value ~nominally
#     (the honest recovery check, M17 §5 O-population; the point may be biased by
#     the few-cluster sigma^2_c, so coverage -- not the point -- is the pin).
stopifnot(
  agg$coverage_conflated >= 0.90,
  agg$coverage_conflated <= 0.99
)
# (3) CONTAINMENT: the frequentist glmmTMB conflated point falls inside the brms
#     credible interval for ~all reps (the O-lme4/O-Eq14 analog -- the two engines
#     compose the SAME Eq. 14, differing only by prior; M26 containment posture).
stopifnot(agg$containment_glmmtmb >= 0.90)
# (4) DISTINCTNESS: the conflated ICC is visibly ABOVE the subject level (Eq. 14
#     folds the large between-cluster variance into the signal). The population
#     gap is pop_conflated - pop_subject; the sample MAP gap stays clearly
#     positive despite any few-cluster bias.
stopifnot(agg$map_minus_subject > 0.05)

message("All O-Bayes-Conflated pins passed.")
