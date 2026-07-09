# oracle-bayesian-multilevel.R
# ===========================================================================
# Provenance for O-Bayes-ML: the brms (Bayesian) engine + ci_method =
# "posterior" for the CROSSED (Design 1) MULTILEVEL ICCs (Milestone 24,
# ADR-034). The multilevel companion to data-raw/oracle-bayesian.R (M23,
# two-way). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-ml-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4) --
# the reference is this script's own seeded output, validated here against the
# source's reported qualitative findings.
#
# A CI method's oracle is COVERAGE (#1; M16/M23 precedent). The source is a
# SIMULATION study, so there is no worked-example point to reproduce -- the
# oracle is that our shipped brms + half-t(4,0,1) + MAP/percentile pipeline,
# extended to the M5 five-component crossed fit, reproduces the source's
# reported bias / coverage / convergence behaviour, AND exposes the source's
# few-cluster caveat at the CLUSTER level (the honest M24 finding).
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93. The
#     half-t(4,0,1)-on-every-SD prior + MAP/percentile recipe (Sec. 4.1-4.2).
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data: A generalizability theory approach.
#     Psychological Methods, 27(4), 650-666. The crossed (Design 1) subject- and
#     cluster-level estimands (Eqs. 12-13, Table 3); their multilevel simulation
#     regime (N_c in {20, 40}, N_s/cluster in {10, 30}, k in {2, 5, 10};
#     sigma^2_{s:c}=1, sigma^2_{cr}=0.16, sigma^2_{(s:c)r}=0.5, sigma^2_c and
#     sigma^2_r varied), transcribed in estimand-spec M5-multilevel.md Sec. 5.
#
# DGP (this run): crossed Design 1, N_c = 20 clusters (ten Hove's LOWER N_c, to
#   surface the few-cluster caveat), N_s = 5 subjects/cluster, with
#     sigma^2_c   = 0.50   (moderate; between-cluster true score)
#     sigma^2_s:c = 1.00   (subject-in-cluster true score)
#     sigma^2_r   = 0.16   (rater main effect)
#     sigma^2_cr  = 0.16   (cluster x rater)
#     sigma^2_res = 0.50   (confounded highest-order residual)
#   Two cells: k = 5 (the well-conditioned cell) and k = 2 (the boundary cell,
#   ten Hove's k = 2 undercoverage caveat). Coefficient evaluated per cell and
#   LEVEL: ICC(A,1) -- subject-level = s2_sc/(s2_sc+s2_r+s2_res) = 0.6024;
#   cluster-level = s2_c/(s2_c+s2_r+s2_cr) = 0.6098.
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is
#   fixed a-priori and INDEPENDENT of the source's modeest tool; convergence on
#   the source's behaviour is a cross-implementation check, not a re-run of their
#   code. Divergences (e.g. the cluster-level few-cluster MAP bias at N_c = 20)
#   are REPORTED, not tuned away. The fixture is written BEFORE the hard
#   assertions so a long run is never lost to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config (adjust reps/DGP for a tighter or faster reference) ------------
n_clusters <- 20L
n_subj_per <- 5L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16
s2_cr <- 0.16
s2_res <- 0.50
cells <- list(
  list(k = 5L), # well-conditioned
  list(k = 2L) # boundary (ten Hove's k = 2 caveat)
)
n_rep <- 100L
base_seed <- 20240L # DGP stream seed (distinct from each fit's Stan seed)
# cores = 3 samples the 3 chains in parallel (a long batch run). iter = 2000 with
# a fixed 1000-warmup budget (we do not adaptively double warmup as the source did).
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# The five-component -> posterior-draw-column map the engine uses (ADR-034); passed
# to the shipped reducers (which take an explicit `spec`/`vars` since M24).
spec_ml <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  rater = "sd_rater__Intercept",
  cluster_rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# Population ICC(A,1) at each level (single rater), from the DGP components.
pop_subject_a1 <- s2_sc / (s2_sc + s2_r + s2_res)
pop_cluster_a1 <- s2_c / (s2_c + s2_r + s2_cr)

# One dataset from the crossed Design-1 DGP (long format, factors); the M5 Eq. 7
# decomposition with the highest-order (subject:cluster) x rater term folded into a
# single residual.
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

# Compile the Stan model ONCE (the five-component crossed model + sourced half-t
# prior, identical across k); every rep refits via update(recompile = FALSE) and runs
# the SHIPPED reducers (brms_component_draws / posterior_summary / posterior_mode /
# brms_convergence), so this validates the exact recipe fit_brms_multilevel() uses.
message("Compiling the base multilevel Stan model once ...")
d0 <- simulate_multilevel(cells[[1]]$k)
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

# One replication -> the per-level statistics we aggregate. Refits on a fresh
# dataset via update(), then reads the SUBJECT- and CLUSTER-level ICC(A,1) MAP + its
# percentile credible interval (coverage of the population value), plus convergence.
one_rep <- function(k, seed) {
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
  est <- function(lv) {
    intraclass:::icc_estimand(
      type = "agreement",
      unit = "single",
      raters = "random",
      k_eff = k,
      multilevel = TRUE,
      level = lv
    )
  }
  summ <- intraclass:::posterior_summary(
    draws,
    list(subject = est("subject"), cluster = est("cluster")),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  mk <- function(lv, pop) {
    s <- summ[[lv]]
    data.frame(
      k = k,
      level = lv,
      pop_icc = pop,
      map_icc = s$point,
      cover_icc = s$conf.low <= pop && pop <= s$conf.high,
      converged = converged
    )
  }
  out <- rbind(
    mk("subject", pop_subject_a1),
    mk("cluster", pop_cluster_a1)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
# This is a ~40-minute run (200 hierarchical refits). We checkpoint the raw per-rep rows
# to a hidden file after each cell (gitignored, removed on success) so a crash in the cheap
# aggregation/validation tail never forces re-sampling -- recover with
# `readRDS("data-raw/.oracle-bayesian-multilevel-checkpoint.rds")`.
ckpt <- "data-raw/.oracle-bayesian-multilevel-checkpoint.rds"
set.seed(base_seed)
rows <- list()
for (cell in cells) {
  message(sprintf("Cell k=%d: %d reps", cell$k, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(cell$k, seed = base_seed + r)
  }
  saveRDS(do.call(rbind, rows), ckpt)
}
reps <- do.call(rbind, rows)

# --- Aggregate to per-(cell x level) reference statistics ------------------
agg <- do.call(
  rbind,
  lapply(cells, function(cell) {
    do.call(
      rbind,
      lapply(c("subject", "cluster"), function(lv) {
        x <- reps[reps$k == cell$k & reps$level == lv, ]
        data.frame(
          k = cell$k,
          level = lv,
          n_rep = nrow(x),
          pop_icc = x$pop_icc[1],
          converged_frac = mean(x$converged),
          map_icc_relbias = mean(x$map_icc) / x$pop_icc[1] - 1,
          coverage_icc = mean(x$cover_icc)
        )
      })
    )
  })
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path("tests", "testthat", "fixtures", "bayesian-ml-oracle.rds")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [multilevel estimands/DGP]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
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
# The pins are QUALITATIVE (a coverage oracle reproduces behaviour, not decimals);
# tolerances absorb our finite n_rep and our INDEPENDENT MAP estimator (#4/#18).
# Observed (n_rep = 100, seed 20240):
#   k=5 subject: conv .97, MAP-relbias -.015, coverage .94
#   k=2 subject: conv .94, MAP-relbias -.037, coverage .96
#   k=5 cluster: conv .97, MAP-relbias -.159, coverage .93
#   k=2 cluster: conv .94, MAP-relbias -.249, coverage .93
subj <- function(kk) agg[agg$k == kk & agg$level == "subject", ]
clus <- function(kk) agg[agg$k == kk & agg$level == "cluster", ]

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90 not 100%).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) SUBJECT level (the de-confounded two-way analog): MAP ~ unbiased at k = 5
#     (|rel bias| < .10) and percentile coverage ~nominal at k = 5 (ten Hove 2022's
#     MCMC ~ MLE, subject level).
stopifnot(
  abs(subj(5L)$map_icc_relbias) < 0.10,
  subj(5L)$coverage_icc >= 0.90,
  subj(5L)$coverage_icc <= 0.99
)
# (3) k = 2 at the subject level: the MAP is biased more LOW than at k = 5 (ten Hove's
#     k = 2 MAP-low finding); subject-level coverage stays ~nominal at both k (the subject
#     level here has 100 subjects, so it is well-powered even at k = 2).
stopifnot(
  subj(2L)$map_icc_relbias < subj(5L)$map_icc_relbias,
  subj(2L)$coverage_icc >= 0.90
)
# (4) CLUSTER level, few-cluster caveat (the honest M24 finding): at N_c = 20 the
#     single-rater cluster MAP is biased LOW relative to the subject level (the
#     sigma^2_c posterior is diffuse near the boundary at few clusters, so the mode
#     of the cluster ICC draws sits below the population value).
stopifnot(clus(5L)$map_icc_relbias < subj(5L)$map_icc_relbias - 0.05)

message("All O-Bayes-ML pins passed.")
