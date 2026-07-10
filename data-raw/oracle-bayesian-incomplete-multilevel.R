# oracle-bayesian-incomplete-multilevel.R
# ===========================================================================
# Provenance for O-Bayes-IML: the brms (Bayesian) engine + ci_method =
# "posterior" for INCOMPLETE/ragged CROSSED (Design 1) multilevel RANDOM ICCs
# (Milestone 30 Slice 2, ADR-040). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-ml-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION (#1). The multilevel sibling of O-Bayes-Incomplete. Every
# mechanical piece is REUSED, oracle-pinned code: the M9 harmonic-mean k_eff
# divisor + crossed multilevel connectedness (ADR-018), the shipped M5/M24
# five-component fit `fit_brms_multilevel()` run on ragged data, the half-t
# prior + MAP/percentile reduction. Random raters make each ICC a RATIO of
# variance components -- no theta^2 functional, so no 2b moment correction (the
# M29/Slice-1 clean-push-forward regime). The unknown is whether the percentile
# credible interval COVERS on RAGGED crossed data at the SUBJECT level
# (ICC(A,1) and the k_eff-divided ICC(A, k_eff)). The averaged cluster-level
# ICC(c,k) is undefined on incomplete data (the open per-cluster divisor,
# M9 §9) and is dropped-with-note; only the single-rater cluster ICC(c,1) is
# reported. The cluster level inherits the M24 few-cluster caveat (MAP biased
# low at small N_c), so its coverage is CHARACTERIZED (ragged tracks complete),
# not pinned nominal -- the honest posture (#18).
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data: A generalizability theory approach.
#     Psychol. Methods. (Crossed Design 1, five-component decomposition.)
#   The ragged extension is NOT in the source; the independent oracle for the
#   ragged point is the shipped glmmTMB M9 estimator (ADR-018), cross-checked in
#   the test file. This script pins COVERAGE.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 15L
n_sub_per_cluster <- 4L
k <- 5L
s2_c <- 0.50
s2_sc <- 1.00
s2_r <- 0.16
s2_cr <- 0.16
s2_res <- 0.50
n_rep <- 100L
base_seed <- 30200L
missing_frac <- 0.12

brm_args <- list(
  chains = 3L,
  iter = 1200L,
  warmup = 600L,
  cores = 3L,
  refresh = 0L
)

spec_ml <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  rater = "sd_rater__Intercept",
  cluster_rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# Population ICCs from the DGP components (estimand-spec M5-multilevel.md §3):
#   subject-level agreement error set is {rater, residual} -- sigma^2_cr is NOT in it
#   (the M9 oracle-first catch), so ICC(A,1) = s2_sc/(s2_sc + s2_r + s2_res);
#   ICC(A,m) divides the {rater, residual} error by m.
#   cluster-level ICC(c,1) = s2_c/(s2_c + s2_r + s2_cr).
pop_subject <- function(m) s2_sc / (s2_sc + (s2_r + s2_res) / m)
pop_cluster1 <- s2_c / (s2_c + s2_r + s2_cr)

# The full crossed-Design-1 grid (subjects nested in clusters, raters crossed).
full_grid <- function() {
  g <- expand.grid(
    rater = seq_len(k),
    s = seq_len(n_sub_per_cluster),
    cluster = seq_len(n_clusters)
  )
  g$subject <- paste0(g$cluster, "_", g$s)
  g
}

# A FIXED, connected ragged incidence over the crossed grid (seeded once). Deleting
# subject x rater cells can break within-cluster / cluster-rater connectedness, so retry
# until a glmmTMB crossed multilevel fit of BOTH levels succeeds without a classed abort.
make_incidence <- function(seed) {
  g <- full_grid()
  n_drop <- round(missing_frac * nrow(g))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    keep <- g[-sample(nrow(g), n_drop), ]
    d0 <- data.frame(
      subject = factor(keep$subject),
      rater = factor(keep$rater),
      cluster = factor(keep$cluster),
      score = stats::rnorm(nrow(keep))
    )
    ok <- tryCatch(
      {
        intraclass::icc(
          d0,
          score,
          rater,
          subject = subject,
          cluster = cluster,
          level = c("subject", "cluster"),
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
  "Ragged crossed-ml incidence: %d of %d cells kept, k_eff = %.4f",
  nrow(inc$keep),
  n_clusters * n_sub_per_cluster * k,
  k_eff_ragged
))

# One dataset from the crossed five-component DGP, complete grid or the fixed ragged
# incidence; scores redrawn each replication.
simulate <- function(design) {
  grid <- if (design == "complete") full_grid() else inc$keep
  sid <- paste0(grid$cluster, "_", grid$s)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
  mu_r <- stats::rnorm(k, 0, sqrt(s2_r))
  mu_cr <- stats::rnorm(n_clusters * k, 0, sqrt(s2_cr))
  data.frame(
    subject = factor(sid),
    rater = factor(grid$rater),
    cluster = factor(grid$cluster),
    score = mu_c[grid$cluster] +
      mu_sc[as.integer(factor(sid))] +
      mu_r[grid$rater] +
      mu_cr[as.integer(interaction(grid$cluster, grid$rater))] +
      stats::rnorm(nrow(grid), 0, sqrt(s2_res))
  )
}

# Compile the five-component model ONCE; every rep refits via update(recompile = FALSE),
# applying the SHIPPED reducers -- validating the exact recipe fit_brms_multilevel() uses.
message("Compiling the base crossed multilevel Stan model once ...")
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
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> subject-level ICC(A,1) & ICC(A,k_eff) and cluster-level ICC(c,1)
# coverage + MAP relative bias + convergence. k_eff is k on the complete grid, the fixed
# ragged k_eff otherwise.
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
  draws <- intraclass:::brms_component_draws(fit, spec_ml)
  est <- function(unit, lv) {
    intraclass:::icc_estimand(
      type = "agreement",
      unit = unit,
      raters = "random",
      k_eff = keff,
      multilevel = TRUE,
      level = lv
    )
  }
  summ <- intraclass:::posterior_summary(
    draws,
    list(
      subj1 = est("single", "subject"),
      subjk = est("average", "subject"),
      clus1 = est("single", "cluster")
    ),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml))
  ps1 <- pop_subject(1)
  psk <- pop_subject(keff)
  pc1 <- pop_cluster1
  out <- data.frame(
    design = design,
    k_eff = keff,
    pop_subj1 = ps1,
    pop_subjk = psk,
    pop_clus1 = pc1,
    map_subj1 = summ$subj1$point,
    map_subjk = summ$subjk$point,
    map_clus1 = summ$clus1$point,
    cover_subj1 = summ$subj1$conf.low <= ps1 && ps1 <= summ$subj1$conf.high,
    cover_subjk = summ$subjk$conf.low <= psk && psk <= summ$subjk$conf.high,
    cover_clus1 = summ$clus1$conf.low <= pc1 && pc1 <= summ$clus1$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-incomplete-multilevel-checkpoint.rds"
set.seed(base_seed)
rows <- list()
for (design in c("complete", "ragged")) {
  message(sprintf("Cell '%s': %d reps", design, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(design, seed = base_seed + r)
  }
  saveRDS(do.call(rbind, rows), ckpt)
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
      pop_subj1 = x$pop_subj1[1],
      pop_subjk = x$pop_subjk[1],
      pop_clus1 = x$pop_clus1[1],
      converged_frac = mean(x$converged),
      map_subj1_relbias = mean(x$map_subj1) / x$pop_subj1[1] - 1,
      map_subjk_relbias = mean(x$map_subjk) / x$pop_subjk[1] - 1,
      map_clus1_relbias = mean(x$map_clus1) / x$pop_clus1[1] - 1,
      coverage_subj1 = mean(x$cover_subj1),
      coverage_subjk = mean(x$cover_subjk),
      coverage_clus1 = mean(x$cover_clus1)
    )
  })
)
print(agg)

# --- Validate: reduction + coverage (the pins) -----------------------------
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP, both cells.
stopifnot(all(agg$converged_frac >= 0.90))

# (2) REDUCTION: on complete data the incomplete path IS the shipped M24 path (k_eff = k),
#     so subject-level coverage is ~nominal.
stopifnot(
  cmp$coverage_subj1 >= 0.90,
  cmp$coverage_subj1 <= 0.99,
  cmp$coverage_subjk >= 0.90,
  cmp$coverage_subjk <= 0.99
)

# (3) SUBJECT-LEVEL COVERAGE ON RAGGED DATA (the milestone's Slice-2 unknown, #1/#18):
#     ragged subject coverage tracks the complete cell within Monte-Carlo error and stays
#     ~nominal for BOTH the divisor-free ICC(A,1) and the k_eff-divided ICC(A, k_eff).
#     If this fires, DO NOT relax it: report (#18) + recommend a gated Fable review (#19).
stopifnot(
  rag$coverage_subj1 >= cmp$coverage_subj1 - 0.06,
  rag$coverage_subjk >= cmp$coverage_subjk - 0.06,
  rag$coverage_subj1 >= 0.88,
  rag$coverage_subjk >= 0.88
)

# (4) CLUSTER LEVEL is CHARACTERIZED, not pinned nominal (the M24 few-cluster caveat, #18):
#     ragged ICC(c,1) coverage tracks the complete cell (both may sit below nominal at this
#     N_c). The cluster ICC(c,k) is undefined on incomplete data -- dropped-with-note, so it
#     is NOT tallied here (only ICC(c,1)).
stopifnot(rag$coverage_clus1 >= cmp$coverage_clus1 - 0.06)

# (5) MAP tracks the population at the subject level (small skew, the M23/M26 posture).
stopifnot(
  abs(cmp$map_subj1_relbias) < 0.10,
  abs(rag$map_subj1_relbias) < 0.12
)

# --- Commit the reference --------------------------------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-ml-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = "ten Hove, Jorgensen & van der Ark (2022) crossed Design 1; ragged extension pinned to glmmTMB M9 (ADR-018)",
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_sub_per_cluster = n_sub_per_cluster,
      k = k,
      s2_c = s2_c,
      s2_sc = s2_sc,
      s2_r = s2_r,
      s2_cr = s2_cr,
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
unlink(ckpt)
message("Wrote ", out)
