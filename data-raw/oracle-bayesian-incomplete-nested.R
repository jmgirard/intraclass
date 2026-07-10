# oracle-bayesian-incomplete-nested.R
# ===========================================================================
# Provenance for O-Bayes-INML-clusters: the brms (Bayesian) engine + ci_method =
# "posterior" for INCOMPLETE/ragged NESTED Design 2 (raters nested in clusters)
# RANDOM ICCs at the SUBJECT level (Milestone 32 Slice 1, ADR-042). The nested
# sibling of data-raw/oracle-bayesian-incomplete-multilevel.R (M30, crossed
# Design 1) and the ragged extension of data-raw/oracle-bayesian-nested.R (M25,
# balanced nested). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-nested-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4) -- the
# reference is this script's own seeded output.
#
# WHAT IS NEW vs M25 (nested, balanced) / M30 (crossed, ragged): nothing in the
# fit -- the M8 four-component nested Design-2 fit `fit_brms_nested_clusters()`
# runs UNCHANGED on ragged data. The only mechanical piece is REUSED, oracle-
# pinned code: the M3/M9 harmonic-mean k_eff (ratings per subject) + within-
# cluster connectedness gates run PRE-DISPATCH (engine-agnostic, icc.R:723-777),
# so they thread through the posterior push-forward exactly as for glmmTMB. Random
# raters -> the subject ICC is a RATIO of variance components (no theta^2 finite-
# population functional), so this is a CLEAN push-forward -- the M30 regime, NOT
# the M31 fixed regime: the 2b moment correction never engages.
#
# A CI method's oracle is COVERAGE (#1; M16/M23-M30 precedent). The source is a
# SIMULATION study, so there is no worked-example point to reproduce -- the oracle
# is that the shipped brms + half-t(4,0,1) + MAP/percentile pipeline, on RAGGED
# nested Design-2 data through k_eff, covers the population subject-level ICC
# ~nominally, tracking the complete-data cell. There is no cluster-level cell
# (nested designs define NO cluster-level IRR -- ten Hove 2022 p. 6).
#
# The ragged extension is NOT in the source; the independent oracle for the ragged
# POINT is the shipped glmmTMB M19 incomplete nested random estimator (ADR-029),
# cross-checked by CONTAINMENT in the live test (O-Bayes-INML-clusters-agree).
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93. The
#     half-t(4,0,1)-on-every-SD prior + MAP/percentile recipe (Sec. 4.1-4.2).
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data. Psychological Methods, 27(4), 650-666. The
#     nested Design-2 subject-level estimands (Eqs. 8-11, Table 3 middle);
#     estimand-spec M8-nested-multilevel.md; k_eff under imbalance from M9/M3.
#
# DGP (this run): N_c = 20 clusters, N_s = 5 subjects/cluster, k = 5 raters/cluster
#     s2_c   = 0.50   (between-cluster; a fitted NUISANCE -- no cluster ICC)
#     s2_sc  = 1.00   (subject-in-cluster true score; the SIGNAL)
#     s2_r   = 0.16   (rater-in-cluster variance, s2_{r:c})
#     s2_res = 0.50   (highest-order residual)
#   Design 2 subject level (the two-way analog within a cluster):
#     ICC_s(A,1)      = s2_sc / (s2_sc + s2_rc + s2_res),  s2_rc = s2_r
#     ICC_s(A,k_eff)  = s2_sc / (s2_sc + (s2_rc + s2_res) / k_eff)
#   Cells: complete (k = 5) and a FIXED ~12%-missing ragged incidence (k_eff < 5).
#
# GUARDRAIL (#4/#18): the MAP estimator (reflected-KDE posterior_mode()) is fixed
#   a-priori. Divergences are REPORTED, not tuned away. The fixture is written
#   BEFORE the hard assertions so a long run is never lost to a marginal pin.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 20L
n_subj_per <- 5L
k <- 5L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16
s2_res <- 0.50
missing_frac <- 0.12
n_rep <- 80L
base_seed <- 32100L # DGP stream seed (distinct from each fit's Stan seed)
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# Design 2 puts s2_{r:c} in the INTERNAL `rater` slot (cluster:rater term); no
# separable cluster_rater term (M25 spec_d2).
spec_d2 <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# Population SUBJECT-level ICC per unit from the DGP components.
pop_subject <- function(kk) s2_sc / (s2_sc + (s2_r + s2_res) / kk)

# Full crossed-within-cluster grid: each cluster has its own k raters and N_s
# subjects, fully crossed within the cluster (raters nested in clusters).
full_grid <- function() {
  expand.grid(
    s = seq_len(n_subj_per),
    rr = seq_len(k),
    cluster = seq_len(n_clusters)
  )
}

# A FIXED, connected ragged incidence (seeded once). Deleting subject x rater
# cells can break within-cluster connectedness or drop a cluster below 2 raters /
# 2 subjects, so retry until a glmmTMB nested Design-2 fit succeeds without a
# classed abort; then read k_eff from the shipped design summary.
make_incidence <- function(seed) {
  g <- full_grid()
  n_drop <- round(missing_frac * nrow(g))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    keep <- g[-sample(nrow(g), n_drop), ]
    sid <- paste0(keep$cluster, "_s", keep$s)
    rid <- paste0(keep$cluster, "_r", keep$rr)
    d0 <- data.frame(
      cluster = factor(keep$cluster),
      subject = factor(sid),
      rater = factor(rid),
      score = stats::rnorm(nrow(keep))
    )
    ok <- tryCatch(
      {
        intraclass::icc(
          d0,
          score,
          subject,
          rater,
          cluster = cluster,
          engine = "glmmTMB"
        )
        TRUE
      },
      error = function(e) FALSE
    )
    if (ok) {
      di <- intraclass:::summarize_design(d0)
      return(list(keep = keep, k_eff = di$k_eff, seed = seed))
    }
  }
}

inc <- make_incidence(base_seed)
k_eff_ragged <- inc$k_eff
message(sprintf(
  "Ragged nested-D2 incidence: %d of %d cells kept, k_eff = %.4f",
  nrow(inc$keep),
  n_clusters * n_subj_per * k,
  k_eff_ragged
))

# One dataset from the nested Design-2 DGP, complete grid or the fixed ragged
# incidence; scores redrawn each replication.
simulate <- function(design) {
  grid <- if (design == "complete") full_grid() else inc$keep
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
}

# Compile the four-component nested model ONCE; every rep refits via
# update(recompile = FALSE), applying the SHIPPED reducers -- validating the exact
# recipe fit_brms_nested_clusters() uses.
message("Compiling the base nested Design-2 Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~
        1 +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | cluster:rater),
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> subject-level ICC(A,1) & ICC(A,k_eff) coverage + MAP relative
# bias + convergence. k_eff is k on the complete grid, the fixed ragged k_eff otherwise.
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
  draws <- intraclass:::brms_component_draws(fit, spec_d2)
  est <- function(unit) {
    intraclass:::icc_estimand(
      type = "agreement",
      unit = unit,
      raters = "random",
      k_eff = keff,
      multilevel = TRUE,
      level = "subject"
    )
  }
  summ <- intraclass:::posterior_summary(
    draws,
    list(subj1 = est("single"), subjk = est("average")),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_d2))
  converged <- isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  p1 <- pop_subject(1)
  pk <- pop_subject(keff)
  s1 <- summ$subj1
  sk <- summ$subjk
  out <- data.frame(
    design = design,
    k_eff = keff,
    map_a1 = s1$point,
    cover_a1 = s1$conf.low <= p1 && p1 <= s1$conf.high,
    map_ak = sk$point,
    cover_ak = sk$conf.low <= pk && pk <= sk$conf.high,
    converged = converged
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
# ~160 hierarchical refits. Checkpoint after each cell (gitignored) so a crash in
# the aggregation tail never forces re-sampling.
ckpt <- "data-raw/.oracle-bayesian-incomplete-nested-checkpoint.rds"
set.seed(base_seed)
rows <- list()
for (design in c("complete", "ragged")) {
  message(sprintf("Cell %s: %d reps", design, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(design, seed = base_seed + r)
  }
  saveRDS(do.call(rbind, rows), ckpt)
}
reps <- do.call(rbind, rows)

# --- Aggregate to per-design reference statistics --------------------------
agg <- do.call(
  rbind,
  lapply(c("complete", "ragged"), function(design) {
    x <- reps[reps$design == design, ]
    data.frame(
      design = design,
      k_eff = x$k_eff[1],
      n_rep = nrow(x),
      pop_a1 = pop_subject(1),
      pop_ak = pop_subject(x$k_eff[1]),
      converged_frac = mean(x$converged),
      relbias_a1 = mean(x$map_a1) / pop_subject(1) - 1,
      coverage_a1 = mean(x$cover_a1),
      relbias_ak = mean(x$map_ak) / pop_subject(x$k_eff[1]) - 1,
      coverage_ak = mean(x$cover_ak)
    )
  })
)
print(agg)

# --- Commit the reference (BEFORE the hard pins, so a long run is not lost) --
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-nested-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [nested D2 estimand];",
      "ragged point cross-checked vs glmmTMB M19 (ADR-029)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_subj_per = n_subj_per,
      k = k,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_r = s2_r,
      s2_res = s2_res,
      missing_frac = missing_frac
    ),
    brm_args = brm_args,
    n_rep = n_rep,
    base_seed = base_seed,
    k_eff_ragged = k_eff_ragged,
    stats = agg
  ),
  out
)
message("Wrote ", out)
unlink(ckpt)

# --- Validate against the qualitative findings (the pins) ------------------
# QUALITATIVE pins (a coverage oracle reproduces behaviour, not decimals);
# tolerances absorb finite n_rep and our INDEPENDENT MAP estimator (#4/#18).
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90 not 100%).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) k_eff strictly shrinks under imbalance (the harmonic-mean divisor bites).
stopifnot(rag$k_eff < k, rag$k_eff > 1)
# (3) THE ONE UNKNOWN (#18): ragged subject-level coverage tracks complete and
#     stays ~nominal for BOTH ICC(A,1) and ICC(A,k_eff) -- random raters give a
#     clean variance-ratio push-forward (no 2b), so no undercoverage is expected.
stopifnot(
  cmp$coverage_a1 >= 0.90,
  cmp$coverage_a1 <= 0.99,
  rag$coverage_a1 >= 0.90,
  rag$coverage_a1 <= 0.99,
  cmp$coverage_ak >= 0.90,
  cmp$coverage_ak <= 0.99,
  rag$coverage_ak >= 0.90,
  rag$coverage_ak <= 0.99
)

message("All O-Bayes-INML-clusters pins passed.")
