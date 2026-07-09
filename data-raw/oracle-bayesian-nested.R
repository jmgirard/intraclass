# oracle-bayesian-nested.R
# ===========================================================================
# Provenance for O-Bayes-NML: the brms (Bayesian) engine + ci_method =
# "posterior" for the NESTED-rater MULTILEVEL ICCs -- Design 2 (raters nested
# in clusters) and Design 3 (raters nested in subjects) at the SUBJECT level
# (Milestone 25, ADR-035). The nested companion to
# data-raw/oracle-bayesian-multilevel.R (M24, crossed Design 1) and
# data-raw/oracle-bayesian.R (M23, two-way). Run to regenerate the committed
# reference (tests/testthat/fixtures/bayesian-nested-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4) --
# the reference is this script's own seeded output, validated here against the
# source's reported qualitative findings.
#
# A CI method's oracle is COVERAGE (#1; M16/M23/M24 precedent). The source is a
# SIMULATION study, so there is no worked-example point to reproduce -- the
# oracle is that our shipped brms + half-t(4,0,1) + MAP/percentile pipeline,
# extended to the M8 nested fits, reproduces the source's reported bias /
# coverage / convergence behaviour at the SUBJECT level. Unlike the crossed M24
# oracle there is NO cluster-level cell (nested designs define no cluster-level
# IRR -- ten Hove 2022 p. 6), so the few-cluster caveat that dogged M24's
# cluster level is not exposed here: sigma^2_c is a fitted NUISANCE.
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93. The
#     half-t(4,0,1)-on-every-SD prior + MAP/percentile recipe (Sec. 4.1-4.2).
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data: A generalizability theory approach.
#     Psychological Methods, 27(4), 650-666. The nested Design 2/3 subject-level
#     estimands (Eqs. 8-11, Table 3 middle/right); the multilevel simulation
#     regime transcribed in estimand-spec M8-nested-multilevel.md Sec. 5.
#
# DGP (this run): N_c = 20 clusters, N_s = 5 subjects/cluster, with
#     sigma^2_c   = 0.50   (between-cluster true score; nuisance -- no cluster ICC)
#     sigma^2_s:c = 1.00   (subject-in-cluster true score; the SIGNAL)
#     sigma^2_r   = 0.16   (rater variance: r:c for Design 2, folded into
#                           residual for Design 3)
#     sigma^2_res = 0.50   (highest-order residual)
#   Design 2 (k raters/cluster, crossed with that cluster's subjects):
#     ICC_s(A,1) = s2_sc/(s2_sc + s2_rc + s2_res) with s2_rc = sigma^2_r.
#   Design 3 (k raters/subject, one-way): rater variance is CONFOUNDED into the
#     residual, so the population residual is sigma^2_r + sigma^2_res and
#     ICC_s(1) = s2_sc/(s2_sc + s2_r + s2_res). Agreement-only (no consistency).
#   Cells: Design 2 at k = 5 (the two-way analog, well-conditioned); Design 3 at
#     k = 5 and k = 2 (the one-way; k = 2 probes the few-rater end -- though at the
#     well-powered subject level it stays ~unbiased, the honest M25 finding).
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori and INDEPENDENT of the source's modeest tool. Divergences are
#   REPORTED, not tuned away. The fixture is written BEFORE the hard assertions so
#   a long run is never lost to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config (adjust reps/DGP for a tighter or faster reference) ------------
n_clusters <- 20L
n_subj_per <- 5L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16
s2_res <- 0.50
# Each cell names a design and a rater count. Design 2 = raters nested in
# clusters (four components); Design 3 = raters nested in subjects (three
# components, one-way).
cells <- list(
  list(design = "nested_in_clusters", k = 5L), # two-way analog
  list(design = "nested_in_subjects", k = 5L), # one-way, well-conditioned
  list(design = "nested_in_subjects", k = 2L) # one-way, boundary
)
n_rep <- 80L
base_seed <- 20250L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# Component -> posterior-draw-column maps per design (ADR-035). Design 2 puts
# sigma^2_{r:c} in the INTERNAL `rater` slot (cluster:rater term, no separable
# cluster_rater); Design 3 has no rater term at all (rater folded into residual).
spec_d2 <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)
spec_d3 <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)

# Population SUBJECT-level ICC(.,1) per design from the DGP components.
pop_a1 <- list(
  nested_in_clusters = s2_sc / (s2_sc + s2_r + s2_res),
  nested_in_subjects = s2_sc / (s2_sc + s2_r + s2_res)
)

# One dataset from each nested DGP (long format, factors). Design 2: raters
# nested in clusters (cluster-unique rater labels), crossed with subjects.
# Design 3: raters nested in subjects (subject-unique rater labels), rater
# variance folded into the residual draw.
simulate_nested <- function(design, k) {
  if (design == "nested_in_clusters") {
    grid <- expand.grid(
      s = seq_len(n_subj_per),
      rr = seq_len(k),
      cluster = seq_len(n_clusters)
    )
    sid <- paste0(grid$cluster, "_s", grid$s)
    rid <- paste0(grid$cluster, "_r", grid$rr) # rater nested in cluster
    mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
    mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
    mu_rc <- stats::rnorm(length(unique(rid)), 0, sqrt(s2_r))
    data.frame(
      cluster = factor(grid$cluster),
      subject = factor(sid),
      rater = factor(rid),
      score = mu_c[grid$cluster] +
        mu_sc[as.integer(factor(sid))] +
        mu_rc[as.integer(factor(rid))] +
        stats::rnorm(nrow(grid), 0, sqrt(s2_res))
    )
  } else {
    # Design 3: each subject has its OWN k raters; rater main effect is
    # inseparable from error, so it enters the single confounded residual.
    grid <- expand.grid(
      rr = seq_len(k),
      s = seq_len(n_subj_per),
      cluster = seq_len(n_clusters)
    )
    sid <- paste0(grid$cluster, "_s", grid$s)
    rid <- paste0(sid, "_r", grid$rr) # rater nested in subject
    mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
    mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
    mu_r <- stats::rnorm(length(unique(rid)), 0, sqrt(s2_r))
    data.frame(
      cluster = factor(grid$cluster),
      subject = factor(sid),
      rater = factor(rid),
      score = mu_c[grid$cluster] +
        mu_sc[as.integer(factor(sid))] +
        mu_r[as.integer(factor(rid))] +
        stats::rnorm(nrow(grid), 0, sqrt(s2_res))
    )
  }
}

# Compile each design's Stan model ONCE; every rep refits via update(recompile =
# FALSE) and runs the SHIPPED reducers (brms_component_draws / posterior_summary /
# posterior_mode / brms_convergence), so this validates the exact recipe
# fit_brms_nested_clusters() / fit_brms_nested_subjects() use.
message("Compiling the base nested Stan models once ...")
d2_0 <- simulate_nested("nested_in_clusters", 5L)
base_d2 <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | cluster:rater),
      data = d2_0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)
d3_0 <- simulate_nested("nested_in_subjects", 5L)
base_d3 <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | cluster) + (1 | cluster:subject),
      data = d3_0,
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> the subject-level statistics we aggregate. Refits on a fresh
# dataset via update(), then reads the SUBJECT-level agreement ICC(.,1) MAP + its
# percentile credible interval (coverage of the population value), plus convergence.
one_rep <- function(design, k, seed) {
  d <- simulate_nested(design, k)
  base <- if (design == "nested_in_clusters") base_d2 else base_d3
  spec <- if (design == "nested_in_clusters") spec_d2 else spec_d3
  fit <- suppressWarnings(suppressMessages(
    stats::update(
      base,
      newdata = d,
      seed = seed,
      recompile = FALSE,
      refresh = 0
    )
  ))
  draws <- intraclass:::brms_component_draws(fit, spec)
  # Design 3 is the multilevel one-way (agreement-only), so its estimand carries
  # oneway = TRUE; Design 2 is the two-way analog at the subject level.
  est <- intraclass:::icc_estimand(
    type = "agreement",
    unit = "single",
    raters = "random",
    k_eff = k,
    multilevel = TRUE,
    level = "subject",
    oneway = (design == "nested_in_subjects")
  )
  summ <- intraclass:::posterior_summary(
    draws,
    list(subject = est),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  s <- summ$subject
  pop <- pop_a1[[design]]
  out <- data.frame(
    design = design,
    k = k,
    pop_icc = pop,
    map_icc = s$point,
    cover_icc = s$conf.low <= pop && pop <= s$conf.high,
    converged = converged
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
# ~240 hierarchical refits. Checkpoint the raw per-rep rows after each cell
# (gitignored, removed on success) so a crash in the aggregation tail never forces
# re-sampling -- recover with
# readRDS("data-raw/.oracle-bayesian-nested-checkpoint.rds").
ckpt <- "data-raw/.oracle-bayesian-nested-checkpoint.rds"
set.seed(base_seed)
rows <- list()
for (cell in cells) {
  message(sprintf("Cell %s k=%d: %d reps", cell$design, cell$k, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(
      cell$design,
      cell$k,
      seed = base_seed + r
    )
  }
  saveRDS(do.call(rbind, rows), ckpt)
}
reps <- do.call(rbind, rows)

# --- Aggregate to per-(design x k) reference statistics --------------------
agg <- do.call(
  rbind,
  lapply(cells, function(cell) {
    x <- reps[reps$design == cell$design & reps$k == cell$k, ]
    data.frame(
      design = cell$design,
      k = cell$k,
      n_rep = nrow(x),
      pop_icc = x$pop_icc[1],
      converged_frac = mean(x$converged),
      map_icc_relbias = mean(x$map_icc) / x$pop_icc[1] - 1,
      coverage_icc = mean(x$cover_icc)
    )
  })
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path("tests", "testthat", "fixtures", "bayesian-nested-oracle.rds")
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [nested estimands/DGP]"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_r = s2_r,
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
# tolerances absorb our finite n_rep and our INDEPENDENT MAP estimator (#4/#18).
d2 <- function(kk) agg[agg$design == "nested_in_clusters" & agg$k == kk, ]
d3 <- function(kk) agg[agg$design == "nested_in_subjects" & agg$k == kk, ]

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90 not 100%).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) Design 2 subject level (the two-way analog): MAP ~ unbiased and percentile
#     coverage ~nominal at k = 5 (ten Hove 2022 MCMC ~ MLE, subject level).
stopifnot(
  abs(d2(5L)$map_icc_relbias) < 0.10,
  d2(5L)$coverage_icc >= 0.90,
  d2(5L)$coverage_icc <= 0.99
)
# (3) Design 3 subject level (the multilevel one-way): MAP ~ unbiased and coverage
#     ~nominal at BOTH k = 5 and k = 2. Observed (seed 20250, n_rep 80):
#       D3 k=5: conv 1.00, MAP rel-bias +.002, coverage .950
#       D3 k=2: conv 1.00, MAP rel-bias +.006, coverage .963
#     THE HONEST FINDING (#18): unlike the CROSSED cluster level (M24, N_c = 20,
#     MAP biased low), the nested SUBJECT level is well-powered (100 subjects) and
#     stays ~unbiased even at k = 2 -- there is no boundary-prone cluster estimand
#     exposed (nested designs define no cluster ICC). We do NOT assert the M24-style
#     "k = 2 more biased low" ordering here: it is a cluster-level / two-way-N=30
#     property that simply does not appear at this well-powered subject level (both
#     |rel-bias| are < .01). Pinning only what the run actually shows (#4).
stopifnot(
  abs(d3(5L)$map_icc_relbias) < 0.10,
  d3(5L)$coverage_icc >= 0.90,
  d3(5L)$coverage_icc <= 0.99,
  abs(d3(2L)$map_icc_relbias) < 0.10,
  d3(2L)$coverage_icc >= 0.90,
  d3(2L)$coverage_icc <= 0.99
)

message("All O-Bayes-NML pins passed.")
