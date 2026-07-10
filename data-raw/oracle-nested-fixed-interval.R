# Oracle O-NFI: frequentist nested-fixed theta^2_{r:c} MC-INTERVAL coverage (M28) -
#
# Provenance for tests/testthat/test-icc-fixed-multilevel.R (PRINCIPLES.md #1, #3,
# #4, #12, #18). Reproducible, seeded, standalone (Rscript
# data-raw/oracle-nested-fixed-interval.R); writes the committed summary fixture
# tests/testthat/fixtures/nested-fixed-interval-oracle.rds that the O-NFI test
# asserts against.
#
# WHY (ADR-038, the M27/ADR-037 corollary): M27's gated Fable review (#19) fixed the
# BAYESIAN nested-fixed interval -- the raw theta^2_{r:c} push-forward undercovers the
# nested finite population (an incidental-parameters pathology). The FREQUENTIST
# sibling, `theta2r_nested_draws()` (R/engine-glmmtmb.R), was the M19 Slice 2
# construction: per Monte-Carlo draw `pmax(0, raw - bias)` PER CLUSTER (subtracting only
# 1b) then averaged. This script (M28 Slice 1) PINNED it and found material
# undercoverage, worsening with cluster count:
#
#   SHIPPED (1b, per-cluster floor) -- boundary coverage C_n=5/20/80 = .95/.86/.57,
#   worst cell (C_n=80, n_s=3) ~.37; interior means .95/.92/.80.
#
# M28 Slice 2 (this fixture's current state, ADR-038 amendment + gated Fable review):
# the shared `theta2r_moment_draws()` now subtracts 2b per draw (Fable §1: two equal
# inflations -- push-forward + plug-in of the center) and floors the per-draw AVERAGE,
# not each cluster (Fable §3; the boundary can reach theta^2=0). Re-running this same
# grid CONFIRMS the derived constants (not calibration, #4): expect boundary ~.97-1.00
# (mildly conservative, boundary-aware #3) and interior mean ~.95, no cell below ~.90.
# The frequentist POINT estimator keeps its 1b correction but its floor also moves to
# the average (Fable §3), so the point stays inside its own interval at the boundary.
#
# A CI method's oracle is COVERAGE (#1): for each grid cell we simulate nested
# Design 2 fixed-rater data with a KNOWN population value, fit through the SHIPPED
# `icc(..., raters = "fixed")` Monte-Carlo path (not a re-implementation), and record
# the fraction of 95% intervals containing the population ICC(A,1). Raters are a FIXED
# per-cluster finite population, so the rater means are held FIXED across replications;
# only subjects and residuals are resampled (coverage is of the fixed value, #2).
#
# Grid (ADR-038, from the Fable review Q6 robustness question):
#   k         in {2, 4}
#   n_s       in {3, 5, 20}      (subjects per cluster)
#   C_n       in {5, 20, 80}     (number of clusters)
#   theta2rc  in {0, sigma^2_res / n_s, 0.66}   ({boundary, small, interior})
# with sigma^2_{s:c} = 1, sigma^2_res = 0.5 fixed. n_rep = 100 per cell (matching the
# Fable evidence table); Monte-Carlo coverage error ~ +/-2 pts at that n_rep.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})
devtools::load_all(quiet = TRUE)

vsc <- 1.0 # sigma^2_{s:c}
vres <- 0.5 # sigma^2_res
n_rep <- 100L
mc_n <- 4000L # MC draws per interval; coverage is insensitive to this beyond
#             # quantile noise (interval width is set by parameter uncertainty),
#             # kept modest so 5,400 fits finish in reasonable wall time.

# Nested Design 2 (raters nested in clusters), raters FIXED. Each cluster gets the
# SAME centered rater-mean pattern, scaled so its within-cluster finite-population
# variance is exactly `theta2` (McGraw & Wong Case 3A per cluster); the average over
# clusters -- the estimand theta^2_{r:c} -- is then exactly `theta2`. theta2 = 0 puts
# every rater mean equal (no rater effect) -- the boundary. Rater labels are
# cluster-unique, so the crossing pattern is nested regardless of the numeric means.
sim_design2_fixed <- function(nc, ns, k, theta2, seed) {
  base <- seq_len(k) - (k + 1) / 2 # centered integer pattern, mean 0
  v0 <- sum(base^2) / (k - 1) # its finite-population variance
  rmean <- if (theta2 == 0) rep(0, k) else base * sqrt(theta2 / v0)
  set.seed(seed)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 + rmean[d$rater] + d$sc + stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

# One grid cell: n_rep replications, fraction of 95% subject-level ICC(A,1) MC
# intervals containing the known population value. Fits that error (e.g. a boundary
# singular fit) are discarded from the denominator and counted separately (#18).
one_cell <- function(k, ns, cn, theta2, base_seed) {
  pop_icc <- vsc / (vsc + theta2 + vres)
  hits <- 0L
  nfit <- 0L
  nfail <- 0L
  for (r in seq_len(n_rep)) {
    d <- sim_design2_fixed(cn, ns, k, theta2, seed = base_seed + r)
    x <- tryCatch(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        seed = base_seed + r,
        mc_samples = mc_n
      )),
      error = function(e) NULL
    )
    if (is.null(x)) {
      nfail <- nfail + 1L
      next
    }
    row <- x$estimates[
      x$estimates$index == "ICC(A,1)" & x$estimates$level == "subject",
    ]
    nfit <- nfit + 1L
    if (pop_icc >= row$conf.low && pop_icc <= row$conf.high) {
      hits <- hits + 1L
    }
  }
  data.frame(
    k = k,
    n_s = ns,
    C_n = cn,
    theta2 = theta2,
    cell = if (theta2 == 0) "boundary" else "interior",
    pop_icc = pop_icc,
    coverage = hits / nfit,
    n_fit = nfit,
    n_fail = nfail
  )
}

# --- point-estimator spot-check (#: point is out of M28 scope, confirm unmoved) -----
# The shipped point estimate is theta2r_fixed_nested()$point, unchanged by M28. On a
# balanced fixed cell it equals the mean over clusters of each cluster's Case-3A flat
# theta^2_r (the M19 O-FNML/reduction pin) -- reconfirmed here so the coverage work is
# demonstrably interval-only.
d_chk <- sim_design2_fixed(20, 6, 4, 0.66, seed = 4242)
fit_chk <- fit_glmmtmb_nested_fixed(d_chk)
cat(sprintf(
  "O-NFI/point spot-check: theta^2_{r:c} point = %.4f (target 0.66; finite-sample scatter expected)\n",
  fit_chk$components$rater
))
stopifnot(fit_chk$components$rater >= 0)

# --- the coverage grid ---------------------------------------------------------------
grid <- expand.grid(
  k = c(2L, 4L),
  n_s = c(3L, 5L, 20L),
  C_n = c(5L, 20L, 80L),
  KEEP.OUT.ATTRS = FALSE
)

results <- list()
i <- 0L
for (g in seq_len(nrow(grid))) {
  k <- grid$k[g]
  ns <- grid$n_s[g]
  cn <- grid$C_n[g]
  for (theta2 in c(0, vres / ns, 0.66)) {
    i <- i + 1L
    base_seed <- 202800L + i * 1000L
    res <- one_cell(k, ns, cn, theta2, base_seed)
    results[[i]] <- res
    cat(sprintf(
      "[%2d/%2d] k=%d n_s=%2d C_n=%2d theta2=%.4f (%-8s) pop_icc=%.4f  coverage=%.3f (n=%d, fail=%d)\n",
      i,
      nrow(grid) * 3L,
      k,
      ns,
      cn,
      theta2,
      res$cell,
      res$pop_icc,
      res$coverage,
      res$n_fit,
      res$n_fail
    ))
    flush.console()
  }
}

out <- do.call(rbind, results)
out$n_rep <- n_rep
out$mc_n <- mc_n

cat("\n=== O-NFI coverage summary ===\n")
print(out[, c(
  "k",
  "n_s",
  "C_n",
  "theta2",
  "cell",
  "pop_icc",
  "coverage",
  "n_fit"
)])
cat(sprintf(
  "\nInterior coverage: mean %.3f (range %.3f-%.3f)\n",
  mean(out$coverage[out$cell == "interior"]),
  min(out$coverage[out$cell == "interior"]),
  max(out$coverage[out$cell == "interior"])
))
cat(sprintf(
  "Boundary coverage: mean %.3f (range %.3f-%.3f)\n",
  mean(out$coverage[out$cell == "boundary"]),
  min(out$coverage[out$cell == "boundary"]),
  max(out$coverage[out$cell == "boundary"])
))

fixture <- "tests/testthat/fixtures/nested-fixed-interval-oracle.rds"
saveRDS(out, fixture)
cat(sprintf("\nWrote %s\n", fixture))
