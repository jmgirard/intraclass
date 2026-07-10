# oracle-bayesian-incomplete-nested-subjects.R
# ===========================================================================
# Provenance for O-Bayes-INML-subjects: the brms (Bayesian) engine + ci_method =
# "posterior" for INCOMPLETE/ragged NESTED Design 3 (raters nested in subjects,
# the multilevel ONE-WAY, agreement-only) RANDOM ICCs at the SUBJECT level
# (Milestone 32 Slice 2, ADR-042). The Design-3 sibling of
# data-raw/oracle-bayesian-incomplete-nested.R (Slice 1, Design 2) and the ragged
# extension of the Design-3 cell in data-raw/oracle-bayesian-nested.R (M25). Run
# to regenerate tests/testthat/fixtures/bayesian-incomplete-nested-subjects-oracle.rds
# asserted in tests/testthat/test-icc-brms.R. Seeded (#12); no fabricated values (#4).
#
# WHAT IS NEW vs M25 (nested, balanced) / Slice 1 (Design 2, ragged): nothing in the
# fit -- the M8 three-component multilevel one-way fit `fit_brms_nested_subjects()`
# runs UNCHANGED on ragged data. The only mechanical piece is REUSED, oracle-pinned
# code: the M3/M9 harmonic-mean k_eff (ratings per subject) + the per-subject >= 2
# raters identifiability gate run PRE-DISPATCH (engine-agnostic, icc.R:723-777).
# Random raters -> the subject ICC is a RATIO of variance components (no theta^2
# functional), so this is a CLEAN push-forward -- the M30 regime, no 2b correction.
#
# In Design 3 the rater main effect is CONFOUNDED into the residual (ten Hove 2022
# p. 6): the population residual is sigma^2_r + sigma^2_res and the subject-level
# coefficient is the multilevel ONE-WAY ICC (agreement-only, no consistency).
# There is no cluster-level cell (nested designs define no cluster IRR).
#
# The ragged extension is NOT in the source; the independent oracle for the ragged
# POINT is the shipped glmmTMB M19 incomplete nested random estimator (ADR-029),
# cross-checked by CONTAINMENT in the live test (O-Bayes-INML-subjects-agree).
#
# SOURCE (sourced -- #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing
#     Hyperprior Distributions ... Springer Proc. Math. & Stat. 322, 79-93.
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data. Psychological Methods, 27(4), 650-666.
#     Design-3 subject-level estimand (Eq. 11, Table 3 right); estimand-spec
#     M8-nested-multilevel.md; k_eff under imbalance from M9/M3.
#
# DGP (this run): N_c = 20 clusters, N_s = 5 subjects/cluster, k = 5 raters/subject
#     s2_c   = 0.50   (between-cluster; a fitted NUISANCE -- no cluster ICC)
#     s2_sc  = 1.00   (subject-in-cluster true score; the SIGNAL)
#     s2_r   = 0.16   (rater variance, CONFOUNDED into residual for Design 3)
#     s2_res = 0.50   (highest-order residual)
#   Design 3 subject level (the multilevel one-way, agreement-only):
#     ICC_s(1)     = s2_sc / (s2_sc + s2_r + s2_res)
#     ICC_s(k_eff) = s2_sc / (s2_sc + (s2_r + s2_res) / k_eff)
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
# n_rep = 240 per cell (upgraded from 80 after the M32 Slice 2 gated Fable review,
# 2026-07-10): at n_rep = 80 the ragged >= .88 pin false-alarms at ~0.7% per cell under a
# nominal method, and the first committed run drew a ~.002 tail (ragged 69/80 = .8625) that
# did NOT replicate -- Fable re-ran the SAME incidence at n = 240 -> coverage .9458, and a
# 2,000-fit frequentist arm on the same incidence -> .9555 (see
# data-raw/reviews/fable-review-m32-s2-response.md, ADR-042 amendment). At n_rep = 240 the
# same pin false-alarms at ~1e-5. Per-rep seeding (below) makes cells extendable/reproducible.
n_rep <- 240L
base_seed <- 32200L
brm_args <- list(
  chains = 3L,
  iter = 2000L,
  warmup = 1000L,
  cores = 3L,
  refresh = 0L
)

# Design 3 has NO rater term (rater folded into residual); three components.
spec_d3 <- c(
  cluster = "sd_cluster__Intercept",
  subject = "sd_cluster:subject__Intercept",
  residual = "sigma"
)

# Population SUBJECT-level one-way ICC per unit from the DGP components.
pop_subject <- function(kk) s2_sc / (s2_sc + (s2_r + s2_res) / kk)

# Full grid: each subject has its OWN k raters (nested in subject).
full_grid <- function() {
  expand.grid(
    rr = seq_len(k),
    s = seq_len(n_subj_per),
    cluster = seq_len(n_clusters)
  )
}

# A FIXED, connected ragged incidence (seeded once). Deleting cells can drop a
# subject below 2 raters (Design 3 identifiability), so retry until a glmmTMB nested
# Design-3 fit succeeds without a classed abort; then read k_eff from the shipped
# design summary.
make_incidence <- function(seed) {
  g <- full_grid()
  n_drop <- round(missing_frac * nrow(g))
  repeat {
    seed <- seed + 1L
    set.seed(seed)
    keep <- g[-sample(nrow(g), n_drop), ]
    sid <- paste0(keep$cluster, "_s", keep$s)
    rid <- paste0(sid, "_r", keep$rr) # rater nested in subject
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
  "Ragged nested-D3 incidence: %d of %d cells kept, k_eff = %.4f",
  nrow(inc$keep),
  n_clusters * n_subj_per * k,
  k_eff_ragged
))

# One dataset from the Design-3 DGP, complete grid or the fixed ragged incidence;
# rater variance enters the confounded residual draw.
simulate <- function(design) {
  grid <- if (design == "complete") full_grid() else inc$keep
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

# Compile the three-component Design-3 model ONCE; every rep refits via
# update(recompile = FALSE) -- validating the exact recipe fit_brms_nested_subjects()
# uses.
message("Compiling the base nested Design-3 Stan model once ...")
base_fit <- do.call(
  brms::brm,
  c(
    list(
      formula = score ~ 1 + (1 | cluster) + (1 | cluster:subject),
      data = simulate("complete"),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

# One replication -> subject-level one-way ICC(1) & ICC(k_eff) coverage + MAP
# relative bias + convergence. k_eff is k on the complete grid, the fixed ragged
# k_eff otherwise. Design 3 is agreement-only, so the estimand carries oneway = TRUE.
one_rep <- function(design, seed) {
  # Per-rep DATA seed (Fable protocol #1): each rep's score draw is seeded from its own
  # `seed`, so cells are individually reproducible and EXTENDABLE (bumping n_rep does not
  # re-deal earlier reps -- unlike a single continuous stream seeded once). The fixed ragged
  # incidence is drawn separately in make_incidence() and is unaffected.
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
  draws <- intraclass:::brms_component_draws(fit, spec_d3)
  est <- function(unit) {
    intraclass:::icc_estimand(
      type = "agreement",
      unit = unit,
      raters = "random",
      k_eff = keff,
      multilevel = TRUE,
      level = "subject",
      oneway = TRUE
    )
  }
  summ <- intraclass:::posterior_summary(
    draws,
    list(subj1 = est("single"), subjk = est("average")),
    conf_level = 0.95
  )
  conv <- intraclass:::brms_convergence(fit, vars = unname(spec_d3))
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
ckpt <- "data-raw/.oracle-bayesian-incomplete-nested-subjects-checkpoint.rds"
# Distinct per-cell seed streams (Fable protocol #1) so the two cells are independent and
# each rep is reproducible from base_seed + (cell offset) + r.
cell_offset <- c(complete = 0L, ragged = 100000L)
rows <- list()
for (design in c("complete", "ragged")) {
  message(sprintf("Cell %s: %d reps", design, n_rep))
  for (r in seq_len(n_rep)) {
    rows[[length(rows) + 1L]] <- one_rep(
      design,
      seed = base_seed + cell_offset[[design]] + r
    )
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

# --- Commit the reference (BEFORE the hard pins) ---------------------------
out <- file.path(
  "tests",
  "testthat",
  "fixtures",
  "bayesian-incomplete-nested-subjects-oracle.rds"
)
dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
saveRDS(
  list(
    source = paste(
      "ten Hove, Jorgensen & van der Ark (2020) [prior/recipe] +",
      "(2022) Psychological Methods 27(4):650-666 [nested D3 estimand];",
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
cmp <- agg[agg$design == "complete", ]
rag <- agg[agg$design == "ragged", ]

# (1) High convergence at the half-t DGP (fixed-warmup budget, so >= 0.90 not 100%).
stopifnot(all(agg$converged_frac >= 0.90))
# (2) k_eff strictly shrinks under imbalance.
stopifnot(rag$k_eff < k, rag$k_eff > 1)
# (3) THE ONE UNKNOWN (#18): ragged subject-level coverage tracks complete and
#     stays ~nominal for BOTH ICC(1) and ICC(k_eff) -- random raters give a clean
#     variance-ratio push-forward (no 2b), so no undercoverage is expected. The
#     nested SUBJECT level is well-powered (100 subjects), so ~unbiased (M25 finding).
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

message("All O-Bayes-INML-subjects pins passed.")
