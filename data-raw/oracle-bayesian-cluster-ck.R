# oracle-bayesian-cluster-ck.R
# ===========================================================================
# Provenance for O-Bayes-cluster-ck: the brms (Bayesian) engine +
# ci_method = "posterior" for the AVERAGED CLUSTER-LEVEL ICC(c,k) on
# INCOMPLETE/ragged CROSSED (Design 1) multilevel RANDOM data (Milestone 47,
# ADR-058). Run to regenerate the committed reference
# (tests/testthat/fixtures/bayesian-cluster-ck-oracle.rds) asserted in
# tests/testthat/test-icc-brms.R. Seeded (PRINCIPLES.md #12); no fabricated
# values (#4) -- the reference is this script's own seeded output.
#
# THE QUESTION (#1/#12). M46 (ADR-057) shipped the averaged cluster-level
# ICC(c,k) on ragged data with the Fable-blessed inverse-Simpson harmonic
# k_c^eff for glmmTMB/lme4, and validated the boundary-aware MC-interval
# COVERAGE (data-raw/oracle-cluster-ck-coverage.R). M47 folds the divisor into
# the brms engine: random raters make each ICC a RATIO of variance components
# read off the posterior draws -- no theta^2 functional, so no 2b moment
# correction (the M30/Slice-2 clean-push-forward regime); k_c^eff is a
# deterministic, draw-independent DESIGN constant (ADR-057 Am.1 Q4). The
# UNKNOWN is whether the percentile CREDIBLE interval COVERS the population
# cluster ICC(c,k) at nominal rate on ragged data, and how the M24 few-cluster
# caveat (the cluster variance is hard at small N_c) resolves along the
# cluster-count axis. The frequentist M46 point/interval is the independent
# oracle; the live test pins CONTAINMENT (glmmTMB M46 inside the brms CI).
#
# THE SWEEP (ADR-058 AC4). k_c^eff is a DESIGN property, so the population
# target is defined PER REALIZED DESIGN: each cell's ragged pattern is FROZEN
# across reps (the M36 pattern); only the components are resampled per rep
# (per-rep seeding). Cells: a COMPLETE reduction cell (k_c^eff = k, the M24
# baseline), a low-C_n ragged cell, and a HIGH-C_n ragged cell
# ([[coverage-oracle-cluster-count-axis]] -- the few-cluster caveat is
# invisible at few clusters and resolves as N_c grows). n_rep = 240
# ([[ragged-coverage-nrep-240]] -- the >= .88 pin false-alarms ~0.7%/cell at
# n_rep 80). Each rep is a live Stan refit via update(recompile = FALSE) off a
# single compile; slow -> run offline, commit the small summary fixture.
#
# SOURCE (sourced -- PRINCIPLES.md #1/#4)
# ---------------------------------------------------------------------------
#   ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
#     reliability for multilevel data. Psychol. Methods. (Crossed Design 1.)
#   The ragged cluster ICC(c,k) divisor is NOT in the source; the independent
#   oracle is the shipped glmmTMB M46 estimator (ADR-057, Fable-blessed),
#   cross-checked live in the test file. This script pins COVERAGE.
# ===========================================================================

suppressPackageStartupMessages({
  stopifnot(requireNamespace("brms", quietly = TRUE))
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})
pkgload::load_all(".", quiet = TRUE, export_all = FALSE)
library(brms)

n_rep <- if (nzchar(Sys.getenv("M47_NREP"))) {
  as.integer(Sys.getenv("M47_NREP"))
} else {
  240L
}

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

# Known DGP components (interior; the cluster signal is estimable at N_c >= 15).
vc <- 0.60
vsc <- 1.00
vr <- 0.20
vcr <- 0.20
vres <- 0.50

# inverse-Simpson harmonic k_c^eff, re-derived inline (matching R/design.R's
# cluster_k_eff and data-raw/oracle-cluster-ck-coverage.R). The same k_c^eff enters
# BOTH the population target and the CI-side estimand, so it cancels -- coverage
# validity does not rest on this divisor (itself Fable-blessed in M46, ADR-057 Am.1);
# what the oracle tests is the posterior push-forward + interval, against a truth
# built from the KNOWN DGP components (vc/vr/vcr), which is genuinely fit-independent.
k_c_eff_ref <- function(d) {
  per <- tapply(seq_len(nrow(d)), d$cluster, function(ix) {
    w <- as.numeric(table(droplevels(d$rater[ix])))
    w <- w / sum(w)
    1 / sum(w^2)
  })
  1 / mean(1 / per)
}

# A FROZEN ragged/complete cluster x subject x rater layout ("score" filled per
# rep). MCAR deletion at `prop` (0 -> complete). Keep only clusters with >= 2
# raters (bridging is required for the cluster-level agreement estimand).
make_design <- function(nc, nspc, k, prop, seed) {
  set.seed(seed)
  g <- expand.grid(rater = seq_len(k), s = seq_len(nspc), cluster = seq_len(nc))
  if (prop > 0) {
    g <- g[-sample(nrow(g), round(prop * nrow(g))), , drop = FALSE]
  }
  g$cluster <- factor(g$cluster)
  g$subject <- factor(paste(g$cluster, g$s, sep = "_"))
  g$rater <- factor(g$rater)
  ok <- names(which(vapply(
    split(g$rater, g$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  droplevels(g[g$cluster %in% ok, , drop = FALSE])
}

# Fill `score` from the known components on a frozen design.
rescore <- function(d) {
  nc <- nlevels(d$cluster)
  k <- nlevels(d$rater)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  scv <- stats::rnorm(nlevels(d$subject), 0, sqrt(vsc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d$score <- 10 +
    cl[as.integer(d$cluster)] +
    scv[as.integer(d$subject)] +
    rr[as.integer(d$rater)] +
    crv[cbind(as.integer(d$cluster), as.integer(d$rater))] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d
}

# cluster-level ICC(c,k) estimands (agreement + consistency) at k = k_c^eff.
clus_ests <- function(kce) {
  list(
    ckA = intraclass:::icc_estimand(
      type = "agreement",
      unit = "average",
      raters = "random",
      k_eff = kce,
      multilevel = TRUE,
      level = "cluster"
    ),
    ckC = intraclass:::icc_estimand(
      type = "consistency",
      unit = "average",
      raters = "random",
      k_eff = kce,
      multilevel = TRUE,
      level = "cluster"
    )
  )
}

# Compile the five-component model ONCE on the largest design; every rep refits
# via update(recompile = FALSE).
cells <- list(
  list(
    label = "complete",
    c_n = 15L,
    nc = 15L,
    nspc = 4L,
    k = 5L,
    prop = 0.00,
    seed = 47001L
  ),
  list(
    label = "ragged low-C_n",
    c_n = 15L,
    nc = 15L,
    nspc = 4L,
    k = 5L,
    prop = 0.15,
    seed = 47002L
  ),
  list(
    label = "ragged high-C_n",
    c_n = 45L,
    nc = 45L,
    nspc = 4L,
    k = 5L,
    prop = 0.15,
    seed = 47003L
  )
)

message("Compiling the base crossed multilevel Stan model once ...")
base_design <- make_design(45L, 4L, 5L, 0.15, 47003L)
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
      data = rescore(base_design),
      prior = brms::set_prior("student_t(4, 0, 1)", class = "sd")
    ),
    brm_args
  )
)

run_cell <- function(cell) {
  d <- make_design(cell$nc, cell$nspc, cell$k, cell$prop, cell$seed)
  kce <- k_c_eff_ref(d)
  pop <- c(
    A = vc / (vc + (vr + vcr) / kce),
    C = vc / (vc + vcr / kce)
  )
  ests <- clus_ests(kce)
  hit_a <- hit_c <- nfit <- conv <- 0L
  map_a <- map_c <- 0
  for (r in seq_len(n_rep)) {
    set.seed(cell$seed * 10L + r)
    di <- rescore(d)
    fit <- tryCatch(
      suppressWarnings(suppressMessages(stats::update(
        base_fit,
        newdata = di,
        seed = cell$seed + r,
        recompile = FALSE,
        refresh = 0
      ))),
      error = function(e) NULL
    )
    if (is.null(fit)) {
      next
    }
    draws <- intraclass:::brms_component_draws(fit, spec_ml)
    summ <- intraclass:::posterior_summary(draws, ests, conf_level = 0.95)
    cv <- intraclass:::brms_convergence(fit, vars = unname(spec_ml))
    nfit <- nfit + 1L
    conv <- conv +
      as.integer(isTRUE(cv$rhat < 1.10) && isTRUE(cv$ess_bulk > 100))
    map_a <- map_a + summ$ckA$point
    map_c <- map_c + summ$ckC$point
    if (pop[["A"]] >= summ$ckA$conf.low && pop[["A"]] <= summ$ckA$conf.high) {
      hit_a <- hit_a + 1L
    }
    if (pop[["C"]] >= summ$ckC$conf.low && pop[["C"]] <= summ$ckC$conf.high) {
      hit_c <- hit_c + 1L
    }
    rm(fit)
    gc(verbose = FALSE)
  }
  cat(sprintf(
    "[%-16s] C_n=%-3d k_c^eff=%.2f popA=%.3f popC=%.3f coverA=%.3f coverC=%.3f mapA=%.3f conv=%.2f (n=%d)\n",
    cell$label,
    cell$c_n,
    kce,
    pop[["A"]],
    pop[["C"]],
    hit_a / nfit,
    hit_c / nfit,
    map_a / nfit,
    conv / nfit,
    nfit
  ))
  data.frame(
    cell = cell$label,
    C_n = cell$c_n,
    complete = cell$prop == 0,
    k_c_eff = kce,
    pop_A = pop[["A"]],
    pop_C = pop[["C"]],
    coverage_A = hit_a / nfit,
    coverage_C = hit_c / nfit,
    map_A_relbias = (map_a / nfit) / pop[["A"]] - 1,
    map_C_relbias = (map_c / nfit) / pop[["C"]] - 1,
    converged_frac = conv / nfit,
    n_fit = nfit
  )
}

cat(sprintf("n_rep=%d\n", n_rep))
ckpt <- "data-raw/.oracle-bayesian-cluster-ck-checkpoint.rds"
rows <- list()
for (cell in cells) {
  message(sprintf("Cell '%s': %d reps", cell$label, n_rep))
  rows[[length(rows) + 1L]] <- run_cell(cell)
  saveRDS(do.call(rbind, rows), ckpt)
}
agg <- do.call(rbind, rows)
agg$n_rep <- n_rep
print(agg)

# --- Commit the reference FIRST (a live run is expensive; never discard it) --
# The committed test asserts the pins; this script prints them so a poor cell is
# visible (#18), but the fixture is written regardless of the pin outcome.
if (n_rep >= 240L) {
  out <- file.path(
    "tests",
    "testthat",
    "fixtures",
    "bayesian-cluster-ck-oracle.rds"
  )
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  saveRDS(
    list(
      source = "ten Hove, Jorgensen & van der Ark (2022) crossed Design 1; ragged cluster ICC(c,k) pinned to glmmTMB M46 (ADR-057)",
      generated = Sys.Date(),
      dgp = list(vc = vc, vsc = vsc, vr = vr, vcr = vcr, vres = vres),
      brm_args = brm_args,
      n_rep = n_rep,
      stats = agg
    ),
    out
  )
  unlink(ckpt)
  cat("\n[saved]", out, "\n")
} else {
  cat(
    "\n[smoke] n_rep < 240 -> fixture NOT written (set M47_NREP=240 for the committed run)\n"
  )
}

# --- Report the pins (mirrors the committed test) --------------------------
cmp <- agg[agg$complete, ]
rlo <- agg[agg$cell == "ragged low-C_n", ]
rhi <- agg[agg$cell == "ragged high-C_n", ]
check <- function(name, ok) {
  cat(sprintf("  [%s] %s\n", if (isTRUE(ok)) "PASS" else "FAIL", name))
  isTRUE(ok)
}
cat("\n--- pins ---\n")
ok <- c(
  # k_c^eff exercises the divisor on ragged data, equals k on complete data.
  check(
    "k_c^eff = k on complete, < k on ragged",
    isTRUE(all.equal(cmp$k_c_eff, 5)) && rlo$k_c_eff < 5 && rhi$k_c_eff < 5
  ),
  # High convergence at the half-t DGP.
  check("convergence >= 0.85 in every cell", all(agg$converged_frac >= 0.85)),
  # REDUCTION: complete-data cluster ICC(c,k) coverage is ~nominal (the baseline).
  check(
    "reduction: complete coverage >= 0.88 (A & C)",
    cmp$coverage_A >= 0.88 && cmp$coverage_C >= 0.88
  ),
  # RAGGED coverage tracks complete within MC error and firms toward nominal as
  # N_c grows (the M24 few-cluster caveat resolves). A real shortfall is REPORTED
  # (#18) and gates a Fable review (#19, ADR-058 conditional escalation), never tuned (#4).
  check(
    "ragged low-C_n coverage >= complete - 0.08",
    rlo$coverage_A >= cmp$coverage_A - 0.08
  ),
  check(
    "ragged high-C_n coverage >= 0.88 (A & C)",
    rhi$coverage_A >= 0.88 && rhi$coverage_C >= 0.88
  )
)
cat(sprintf(
  "\nmin coverage: A=%.3f C=%.3f | high-C_n coverA=%.3f | ALL PINS %s\n",
  min(agg$coverage_A),
  min(agg$coverage_C),
  rhi$coverage_A,
  if (all(ok)) {
    "PASS"
  } else {
    "*** SOME FAIL -- inspect before shipping (#18/#19) ***"
  }
))
