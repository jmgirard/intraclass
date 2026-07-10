# oracle-bayesian-incomplete-fixed-multilevel.R
# ===========================================================================
# Provenance for O-Bayes-IFML-fixed: the brms (Bayesian) engine + ci_method =
# "posterior" for INCOMPLETE/ragged CROSSED (Design 1) FIXED-rater multilevel
# ICCs at the SUBJECT level (Milestone 31 Slice 2, ADR-041). Run to regenerate
# the committed reference
# (tests/testthat/fixtures/bayesian-incomplete-fixed-ml-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION (#1). The crossed-multilevel FIXED-rater sibling of O-Bayes-IFixed
# (single-level fixed) and O-Bayes-IML (crossed-multilevel random). `engine =
# "brms"` + `raters = "fixed"` fits ragged crossed Design-1 multilevel data via
# the shipped M10/M27-S1 fit_brms_multilevel_fixed() five-component fit run on
# ragged data unchanged, with the McGraw & Wong Case-3A theta^2_r read per
# posterior draw (brms_theta2r_draws() -> the 2b moment correction + boundary
# average-floor, ADR-037/038) and the engine-agnostic M9 harmonic-mean k_eff
# divisor + crossed-multilevel connectedness (ADR-018) threaded per draw. As in
# Slice 1, the 2b correction goes LIVE on ragged data (the fixed rater means come
# from unequal cell counts, so b != 0). Scope is SUBJECT LEVEL ONLY -- fixed
# cluster-level IRR is deferred for all engines (M10 deferral), and the averaged
# cluster ICC(c,k) is undefined on incomplete data. The unknown is whether the
# percentile credible interval COVERS on ragged crossed data at the subject level
# (ICC(A,1) and the k_eff-divided ICC(A, k_eff)).
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data. Psychol. Methods. (Crossed Design 1,
#     five-component decomposition.)
#   McGraw & Wong (1996) Case 3A (fixed-rater finite-population theta^2_r).
#   The ragged extension is NOT in the source; the independent oracle for the
#   ragged point is the shipped glmmTMB M18-Slice-1 estimator (ADR-028),
#   cross-checked in the test file. This script pins COVERAGE.
# ===========================================================================

pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

# --- Config ----------------------------------------------------------------
n_clusters <- 15L
n_sub_per_cluster <- 4L
mu_r <- c(-0.6, -0.3, 0, 0.3, 0.6) # FIXED finite population of k = 5 rater means
k <- length(mu_r)
theta2_r <- sum((mu_r - mean(mu_r))^2) / (k - 1) # = 0.225
s2_c <- 0.50
s2_sc <- 1.00
s2_cr <- 0.16
s2_res <- 0.50
n_rep <- 100L
base_seed <- 31200L
missing_frac <- 0.12

brm_args <- list(
  chains = 3L,
  iter = 1200L,
  warmup = 600L,
  cores = 3L,
  refresh = 0L
)

# The four RANDOM components (theta^2_r is derived separately from the rater draws).
spec_ml <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  cluster_rater = "sd_cluster:rater__Intercept",
  residual = "sigma"
)

# Population SUBJECT-level ICCs (estimand-spec M5 §3 / M10 §2): the fixed subject-level
# agreement error set is {rater = theta^2_r, residual} -- sigma^2_cr is NOT in it (the M9
# catch) -- so ICC(A,1) = s2_sc / (s2_sc + theta^2_r + s2_res); ICC(A,m) divides the
# {theta^2_r, residual} error by m. Cluster-level fixed IRR is deferred (subject level only).
pop_subject <- function(m) s2_sc / (s2_sc + (theta2_r + s2_res) / m)

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
# subject x rater cells can break connectedness, so retry until a glmmTMB crossed
# multilevel FIXED fit of the subject level succeeds without a classed abort.
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
        suppressWarnings(intraclass::icc(
          d0,
          score,
          rater,
          subject = subject,
          cluster = cluster,
          raters = "fixed",
          engine = "glmmTMB"
        ))
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
  "Ragged crossed-ml fixed incidence: %d of %d cells kept, k_eff = %.4f",
  nrow(inc$keep),
  n_clusters * n_sub_per_cluster * k,
  k_eff_ragged
))

# One dataset from the crossed five-component FIXED-rater DGP (mu_r FIXED, not redrawn),
# complete grid or the fixed ragged incidence; the random effects + error redrawn each rep.
simulate <- function(design) {
  grid <- if (design == "complete") full_grid() else inc$keep
  sid <- paste0(grid$cluster, "_", grid$s)
  mu_c <- stats::rnorm(n_clusters, 0, sqrt(s2_c))
  mu_sc <- stats::rnorm(length(unique(sid)), 0, sqrt(s2_sc))
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

# Compile the five-component FIXED-rater model ONCE; every rep refits via update(recompile =
# FALSE), applying the SHIPPED reducers -- brms_theta2r_draws() (2b + average-floor) for the
# rater slot and brms_component_draws() for the four random components -- validating the exact
# recipe fit_brms_multilevel_fixed() uses, with 2b live on the ragged cell.
message("Compiling the base crossed multilevel fixed Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~
        1 +
        rater +
        (1 | cluster) +
        (1 | cluster:subject) +
        (1 | cluster:rater),
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> subject-level ICC(A,1) & ICC(A,k_eff) coverage + MAP relative bias +
# convergence. k_eff is k on the complete grid, the fixed ragged k_eff otherwise.
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
  # theta^2_r per draw through the SHIPPED moment correction (2b + average-floor); the four
  # random components off the standard spec; assemble the five-row `draws` in M5 order.
  theta <- intraclass:::brms_theta2r_draws(fit, d)
  rc <- intraclass:::brms_component_draws(fit, spec_ml)
  draws <- rbind(
    cluster = rc["cluster", ],
    subject = rc["subject", ],
    rater = theta,
    cluster_rater = rc["cluster_rater", ],
    residual = rc["residual", ]
  )
  est <- function(unit) {
    intraclass:::icc_estimand(
      type = "agreement",
      unit = unit,
      raters = "fixed",
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
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml))
  ps1 <- pop_subject(1)
  psk <- pop_subject(keff)
  out <- data.frame(
    design = design,
    k_eff = keff,
    pop_subj1 = ps1,
    pop_subjk = psk,
    map_subj1 = summ$subj1$point,
    map_subjk = summ$subjk$point,
    cover_subj1 = summ$subj1$conf.low <= ps1 && ps1 <= summ$subj1$conf.high,
    cover_subjk = summ$subjk$conf.low <= psk && psk <= summ$subjk$conf.high,
    converged = isTRUE(conv$rhat < 1.10) && isTRUE(conv$ess_bulk > 100)
  )
  rm(fit)
  gc(verbose = FALSE)
  out
}

# --- Run the simulation ----------------------------------------------------
ckpt <- "data-raw/.oracle-bayesian-incomplete-fixed-multilevel-checkpoint.rds"
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
      theta2_r = theta2_r,
      converged_frac = mean(x$converged),
      map_subj1_relbias = mean(x$map_subj1) / x$pop_subj1[1] - 1,
      map_subjk_relbias = mean(x$map_subjk) / x$pop_subjk[1] - 1,
      coverage_subj1 = mean(x$cover_subj1),
      coverage_subjk = mean(x$cover_subjk)
    )
  })
)
print(agg)

# --- Validate: reduction + coverage (the pins) -----------------------------
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP, both cells.
stopifnot(all(agg$converged_frac >= 0.90))

# (2) REDUCTION: on complete data the incomplete fixed path IS the shipped M27-S1 fixed path
#     (k_eff = k, b ~= 0), so subject-level coverage is ~nominal.
stopifnot(
  cmp$coverage_subj1 >= 0.88,
  cmp$coverage_subj1 <= 0.99,
  cmp$coverage_subjk >= 0.88,
  cmp$coverage_subjk <= 0.99
)

# (3) SUBJECT-LEVEL COVERAGE ON RAGGED DATA (the Slice-2 unknown, where 2b goes live in the
#     multilevel fixed regime, #1/#18): ragged subject coverage tracks the complete cell within
#     Monte-Carlo error and stays ~nominal for BOTH the divisor-free ICC(A,1) and the
#     k_eff-divided ICC(A, k_eff). If this fires, DO NOT relax it: report (#18) + recommend a
#     gated Fable review (#19).
stopifnot(
  rag$coverage_subj1 >= cmp$coverage_subj1 - 0.06,
  rag$coverage_subjk >= cmp$coverage_subjk - 0.06,
  rag$coverage_subj1 >= 0.88,
  rag$coverage_subjk >= 0.88
)

# (4) MAP tracks the population at the subject level (small skew, the M23/M26 posture).
stopifnot(
  abs(cmp$map_subj1_relbias) < 0.10,
  abs(rag$map_subj1_relbias) < 0.12
)

# --- Commit the reference --------------------------------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-fixed-ml-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2022) crossed Design 1;",
      "McGraw & Wong (1996) Case 3A (fixed-rater finite-population theta^2_r);",
      "ragged extension pinned to glmmTMB M18 Slice 1 (ADR-028)"
    ),
    generated = Sys.Date(),
    dgp = list(
      n_clusters = n_clusters,
      n_sub_per_cluster = n_sub_per_cluster,
      k = k,
      mu_r = mu_r,
      theta2_r = theta2_r,
      s2_c = s2_c,
      s2_sc = s2_sc,
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
