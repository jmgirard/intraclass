# Oracle O-FCL: frequentist fixed-rater CLUSTER-level ICC, crossed Design 1,
# balanced/complete -- reduction + recovery + MC-interval coverage (M37, ADR-047)
#
# Provenance for tests/testthat/test-icc-fixed-multilevel.R (PRINCIPLES.md #1, #3, #4,
# #12, #18). Reproducible, seeded, standalone (Rscript
# data-raw/oracle-fixed-cluster-level.R); writes the committed summary fixture
# tests/testthat/fixtures/fixed-cluster-level-oracle.rds the O-FCL test asserts against.
# The feasibility-spike scripts data-raw/reviews/m37-feasibility-spike-*.R are the seed.
#
# WHY (ADR-047): M10 shipped the fixed-rater SUBJECT level; M37 reads the CLUSTER level
# off the same fit -- signal sigma^2_c, agreement error {theta^2_r, sigma^2_cr},
# consistency {sigma^2_cr}, divisor k (M5 §3b map with theta^2_r in the rater slot). The
# feasibility spike settled the one open question (M10 §7): fixing the rater main effect
# does NOT bias the (1|cluster:rater) interaction, so the RANDOM sigma^2_cr is the correct
# fixed-rater cluster-level error (no finite-population correction), and the coefficient
# reduces to the shipped M5 random cluster-level ICC EXACTLY on balanced data.
#
# The recovery oracle is NON-CIRCULAR: theta^2_r is a DETERMINISTIC function of the k
# fixed rater means (their finite-population variance), so recovering the known cluster-
# level population value from data is a genuine independent oracle. n_rep = 240
# ([[ragged-coverage-nrep-240]]).
#
# BOUNDARY (sigma^2_c = 0): the cluster-level ICC is a ratio floored at 0 in its numerator
# with no moment correction for the SIGNAL variance, so it under-covers at the boundary --
# but IDENTICALLY for fixed and M5-random (the spike's boundary-parity finding). So the
# boundary cell records BOTH coverages and the oracle asserts PARITY (|fixed - random|
# small), not nominal. Improving cluster-signal-zero coverage is a cross-cutting
# candidate follow-up (M5/M9/M37), out of M37 scope (#18).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})
devtools::load_all(quiet = TRUE)

vsc <- 0.80 # sigma^2_{s:c} (nuisance at the cluster level)
vcr <- 0.25 # sigma^2_cr (the cluster-level interaction error)
vres <- 1.0 # sigma^2_res
rho <- c(-0.8, -0.2, 0.3, 0.7) # k=4 FIXED rater means
theta2 <- sum((rho - mean(rho))^2) / (length(rho) - 1) # = 0.42 (Case 3A population)
n_rep <- 240L
mc_n <- 3000L

# Balanced crossed Design 1, raters FIXED (global labels), cluster-unique subjects.
sim_d1_fixed <- function(nc, ns, vc, seed) {
  set.seed(seed)
  k <- length(rho)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  clv <- stats::rnorm(nc, 0, sqrt(vc))
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d$score <- 10 +
    clv[d$cluster] +
    scv[(d$cluster - 1) * ns + d$subj] +
    rho[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  d
}

cluster_a1 <- function(x) {
  e <- x$estimates
  e$estimate[e$index == "ICC(A,1)" & e$level == "cluster"]
}
cluster_a1_ci <- function(x) {
  e <- x$estimates
  e[e$index == "ICC(A,1)" & e$level == "cluster", c("conf.low", "conf.high")]
}

# One interior recovery cell: coverage + bias of the FIXED cluster-level ICC(A,1).
one_cell <- function(label, nc, vc, base_seed) {
  pop <- vc / (vc + theta2 + vcr)
  hits <- 0L
  nfit <- 0L
  nfail <- 0L
  bias_acc <- 0
  for (r in seq_len(n_rep)) {
    d <- sim_d1_fixed(nc, 6L, vc, seed = base_seed + r)
    x <- tryCatch(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        level = "cluster",
        seed = base_seed + r,
        mc_samples = mc_n
      )),
      error = function(e) NULL
    )
    if (is.null(x)) {
      nfail <- nfail + 1L
      next
    }
    ci <- cluster_a1_ci(x)
    nfit <- nfit + 1L
    bias_acc <- bias_acc + (cluster_a1(x) - pop)
    if (pop >= ci$conf.low && pop <= ci$conf.high) {
      hits <- hits + 1L
    }
  }
  data.frame(
    label = label,
    n_c = nc,
    cell = "interior",
    pop_icc = pop,
    coverage = hits / nfit,
    coverage_random = NA_real_,
    mean_bias = bias_acc / nfit,
    n_fit = nfit,
    n_fail = nfail
  )
}

# Boundary cell (sigma^2_c = 0 -> pop ICC = 0): record BOTH fixed and M5-random coverage.
boundary_cell <- function(nc, base_seed) {
  pop <- 0
  hf <- hr <- 0L
  nfit <- 0L
  for (r in seq_len(n_rep)) {
    d <- sim_d1_fixed(nc, 6L, 0, seed = base_seed + r)
    xf <- tryCatch(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        level = "cluster",
        seed = base_seed + r,
        mc_samples = mc_n
      )),
      error = function(e) NULL
    )
    xr <- tryCatch(
      icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "random",
        level = "cluster",
        seed = base_seed + r,
        mc_samples = mc_n
      ),
      error = function(e) NULL
    )
    if (is.null(xf) || is.null(xr)) {
      next
    }
    nfit <- nfit + 1L
    cf <- cluster_a1_ci(xf)
    cr <- cluster_a1_ci(xr)
    if (pop >= cf$conf.low && pop <= cf$conf.high) {
      hf <- hf + 1L
    }
    if (pop >= cr$conf.low && pop <= cr$conf.high) hr <- hr + 1L
  }
  data.frame(
    label = "boundary-Cn80",
    n_c = nc,
    cell = "boundary",
    pop_icc = pop,
    coverage = hf / nfit,
    coverage_random = hr / nfit,
    mean_bias = NA_real_,
    n_fit = nfit,
    n_fail = n_rep - nfit
  )
}

# --- reduction pin: balanced fixed cluster-level == M5 random cluster-level (point) ----
dred <- sim_d1_fixed(40L, 6L, 0.6, seed = 37010)
fr <- suppressWarnings(icc(
  dred,
  score,
  subject,
  rater,
  cluster = cluster,
  raters = "fixed",
  level = "cluster",
  seed = 1
))
rr <- icc(
  dred,
  score,
  subject,
  rater,
  cluster = cluster,
  raters = "random",
  level = "cluster",
  seed = 1
)
m <- merge(
  fr$estimates[fr$estimates$level == "cluster", c("index", "estimate")],
  rr$estimates[rr$estimates$level == "cluster", c("index", "estimate")],
  by = "index"
)
red_reduction <- max(abs(m$estimate.x - m$estimate.y))
cat(sprintf(
  "O-FCL/reduction (balanced fixed == M5 random cluster, point): |dICC|=%.2e\n",
  red_reduction
))
stopifnot(red_reduction < 1e-4)

# --- cross-engine glmmTMB<->lme4 (balanced, point) -------------------------------------
red_ce <- NA_real_
if (requireNamespace("lme4", quietly = TRUE)) {
  fl <- suppressWarnings(icc(
    dred,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    level = "cluster",
    engine = "lme4",
    seed = 1
  ))
  ml <- merge(
    fr$estimates[fr$estimates$level == "cluster", c("index", "estimate")],
    fl$estimates[fl$estimates$level == "cluster", c("index", "estimate")],
    by = "index"
  )
  red_ce <- max(abs(ml$estimate.x - ml$estimate.y))
  cat(sprintf(
    "O-FCL/cross-engine (glmmTMB<->lme4, cluster point): |dICC|=%.2e\n",
    red_ce
  ))
  stopifnot(red_ce < 1e-4)
}

# --- recovery + coverage grid ----------------------------------------------------------
results <- list(
  one_cell("interior-Cn20", 20L, 0.6, base_seed = 370100L),
  one_cell("interior-Cn80", 80L, 0.6, base_seed = 370200L),
  boundary_cell(80L, base_seed = 370300L)
)
out <- do.call(rbind, results)
out$n_rep <- n_rep
out$mc_n <- mc_n
out$theta2 <- theta2
attr(out, "reductions") <- c(reduction = red_reduction, cross_engine = red_ce)

cat("\n=== O-FCL summary ===\n")
print(out[, c(
  "label",
  "n_c",
  "cell",
  "pop_icc",
  "coverage",
  "coverage_random",
  "mean_bias",
  "n_fit"
)])
cat(sprintf(
  "\nboundary parity |fixed - random| = %.3f (records the shared cluster-signal-zero loss)\n",
  abs(
    out$coverage[out$cell == "boundary"] -
      out$coverage_random[out$cell == "boundary"]
  )
))

saveRDS(out, "tests/testthat/fixtures/fixed-cluster-level-oracle.rds")
cat("\nWrote tests/testthat/fixtures/fixed-cluster-level-oracle.rds\n")
