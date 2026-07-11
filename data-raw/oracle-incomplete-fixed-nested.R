# Oracle O-IFNML: frequentist INCOMPLETE/ragged fixed-rater NESTED (Design 2),
# subject-level single-rater ICC_s(A,1) -- recovery + MC-interval coverage (M36, ADR-046)
#
# Provenance for tests/testthat/test-icc-fixed-multilevel.R (PRINCIPLES.md #1, #3, #4,
# #12, #18). Reproducible, seeded, standalone (Rscript
# data-raw/oracle-incomplete-fixed-nested.R); writes the committed summary fixture
# tests/testthat/fixtures/incomplete-fixed-nested-oracle.rds the O-IFNML test asserts
# against. The feasibility-spike scripts data-raw/reviews/m36-feasibility-spike-*.R are
# the seed for this script.
#
# WHY (ADR-046): the balanced fixed-nested theta^2_{r:c} shipped as M19 Slice 2
# (theta2r_fixed_nested()); M36 lets it run on INCOMPLETE/ragged data (missing
# subject x rater cells and/or unequal per-cluster rater counts k_c) by generalizing the
# per-cluster Case-3A center/(k_c - 1) divisor to each cluster's own k_c. The point
# estimand is NON-CIRCULAR: theta^2_{r:c} is a DETERMINISTIC function of the specific
# fixed rater means (their per-cluster finite-population variance), so recovering it from
# ragged data is a genuine independent oracle -- cross-engine agreement (glmmTMB<->lme4)
# validates only the raw fit, not the authored correction, so recovery is load-bearing.
#
# Single-rater ICC_s(A,1) needs NO averaging divisor, so its population value
# vsc / (vsc + theta^2 + vres) is fixed and coverage is clean. The average ICC_s(A,k_eff)
# uses the per-subject harmonic k_eff (ratings/subject -- the M19 random-nested divisor,
# NOT the open per-cluster ICC(c,k) divisor, M9 §9); it is pinned by REDUCTION to flat M3
# fixed at a single cluster (below), so this coverage grid targets single-rater.
#
# Grid: two ragged regimes x {boundary theta^2 = 0, interior}. Coverage is of the FIXED
# population value -- raters are a fixed per-cluster finite population, so rater means are
# held fixed across replications; subjects, residuals, and the MISSINGNESS pattern are
# resampled per rep (per-rep seeding). n_rep = 240 ([[ragged-coverage-nrep-240]] -- the
# >= .88 pin false-alarms ~0.7%/cell at n_rep 80).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
})
devtools::load_all(quiet = TRUE)

vsc <- 1.0 # sigma^2_{s:c}
vres <- 0.5 # sigma^2_res
n_rep <- 240L
mc_n <- 3000L

# Ragged nested Design 2, raters FIXED. Each cluster c gets a centered rater-mean pattern
# scaled so its within-cluster finite-population variance is EXACTLY `theta2` (Case 3A per
# cluster) -- so theta^2_{r:c} (the mean over clusters) is exactly `theta2`; theta2 = 0
# puts every rater mean equal (the boundary). Cells are deleted with prob (1 - p_keep);
# subjects with < 2 remaining ratings are dropped (connectedness). Rater labels are
# cluster-unique => nested regardless of the numeric means.
sim_ragged_d2_fixed <- function(kc_vec, ns, theta2, p_keep, seed) {
  set.seed(seed)
  rows <- list()
  for (c in seq_along(kc_vec)) {
    k <- kc_vec[c]
    base <- seq_len(k) - (k + 1) / 2
    v0 <- sum(base^2) / (k - 1)
    rmean <- if (theta2 == 0) rep(0, k) else base * sqrt(theta2 / v0)
    for (s in seq_len(ns)) {
      sc <- stats::rnorm(1, 0, sqrt(vsc))
      for (r in seq_len(k)) {
        if (stats::runif(1) > p_keep) {
          next
        }
        rows[[length(rows) + 1L]] <- data.frame(
          cluster = c,
          subject = paste(c, s, sep = "_"),
          rater = paste(c, r, sep = "_"),
          score = 10 + rmean[r] + sc + stats::rnorm(1, 0, sqrt(vres))
        )
      }
    }
  }
  d <- do.call(rbind, rows)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  keep <- names(which(table(d$subject) >= 2L))
  d[d$subject %in% keep, , drop = FALSE]
}

# One grid cell: n_rep replications, fraction of 95% single-rater ICC(A,1) MC intervals
# containing the KNOWN population value (fits that error are discarded + counted, #18).
one_cell <- function(label, kc_vec, ns, theta2, p_keep, base_seed) {
  pop_icc <- vsc / (vsc + theta2 + vres)
  hits <- 0L
  nfit <- 0L
  nfail <- 0L
  bias_acc <- 0
  for (r in seq_len(n_rep)) {
    d <- sim_ragged_d2_fixed(kc_vec, ns, theta2, p_keep, seed = base_seed + r)
    x <- tryCatch(
      suppressWarnings(icc(
        d,
        score,
        subject,
        rater,
        cluster = cluster,
        raters = "fixed",
        design = "nested_in_clusters",
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
    bias_acc <- bias_acc + (row$estimate - pop_icc)
    if (pop_icc >= row$conf.low && pop_icc <= row$conf.high) {
      hits <- hits + 1L
    }
  }
  data.frame(
    label = label,
    kc = paste(kc_vec, collapse = ","),
    n_s = ns,
    theta2 = theta2,
    cell = if (theta2 == 0) "boundary" else "interior",
    pop_icc = pop_icc,
    coverage = hits / nfit,
    mean_bias = bias_acc / nfit,
    n_fit = nfit,
    n_fail = nfail
  )
}

# --- reduction pins (deterministic; the point estimand's independent ties) -------------
# (a) Ragged SINGLE-cluster fixed-nested == ragged flat M3 fixed, for BOTH single and
#     average (a single-cluster nested-fixed design IS a flat two-way fixed design). This
#     is the sourced McGraw-Wong Case 3A tie AND the pin for the averaged k_eff divisor.
#     icc() refuses a one-cluster design (needs >= 2 clusters), so -- exactly as the M19
#     O-FNML single-cluster reduction (M10 spec sec 4) -- this is checked at the FIT LEVEL:
#     fit_glmmtmb_nested_fixed() on one cluster, ICC composed by hand from its components
#     with the same per-subject k_eff, vs the shipped flat M3 fixed icc().
set.seed(7)
k1 <- 4L
ns1 <- 40L
d1 <- expand.grid(subject = seq_len(ns1), r = seq_len(k1))
d1 <- d1[stats::runif(nrow(d1)) < 0.75, ]
d1 <- d1[d1$subject %in% names(which(table(d1$subject) >= 2L)), ]
base <- seq_len(k1) - (k1 + 1) / 2
d1$score <- 10 +
  (base * 0.5)[d1$r] +
  stats::rnorm(ns1)[d1$subject] +
  stats::rnorm(nrow(d1), 0, 0.6)
d1$rater <- factor(paste0("r", d1$r))
flat <- suppressWarnings(icc(
  d1,
  score,
  subject,
  rater,
  raters = "fixed",
  unit = c("single", "average"),
  seed = 1
))
d1n <- d1
d1n$cluster <- factor(1L)
d1n$rater <- factor(paste0("1_", d1$r))
d1n$subject <- factor(d1$subject)
fit1 <- fit_glmmtmb_nested_fixed(d1n)
keff1 <- 1 / mean(1 / table(d1n$subject))
s2s1 <- fit1$components$subject
th1 <- fit1$components$rater
s2e1 <- fit1$components$residual
nest_single <- s2s1 / (s2s1 + th1 + s2e1)
nest_avg <- s2s1 / (s2s1 + (th1 + s2e1) / keff1)
red_single <- abs(
  flat$estimates$estimate[flat$estimates$index == "ICC(A,1)"] - nest_single
)
red_avg <- abs(
  flat$estimates$estimate[flat$estimates$index == "ICC(A,k)"] - nest_avg
)
cat(sprintf(
  "O-IFNML/reduction (ragged 1-cluster == flat M3): |single|=%.2e |average|=%.2e\n",
  red_single,
  red_avg
))
stopifnot(red_single < 1e-8, red_avg < 1e-8)

# (b) Cross-engine glmmTMB<->lme4 on a ragged unequal-k design (raw-fit tie, not the
#     correction). Tolerance is the ragged-data cross-engine level (M15), not 1e-4.
red_ce <- NA_real_
if (requireNamespace("lme4", quietly = TRUE)) {
  dce <- sim_ragged_d2_fixed(c(3L, 4L, 2L, 5L), 14L, 0.5, 0.8, seed = 4242)
  gg <- suppressWarnings(icc(
    dce,
    score,
    subject,
    rater,
    cluster = cluster,
    raters = "fixed",
    design = "nested_in_clusters",
    seed = 1
  ))
  ll <- tryCatch(
    suppressWarnings(icc(
      dce,
      score,
      subject,
      rater,
      cluster = cluster,
      raters = "fixed",
      design = "nested_in_clusters",
      engine = "lme4",
      seed = 1
    )),
    error = function(e) NULL
  )
  if (!is.null(ll)) {
    red_ce <- abs(
      gg$estimates$estimate[gg$estimates$index == "ICC(A,1)"] -
        ll$estimates$estimate[ll$estimates$index == "ICC(A,1)"]
    )
    cat(sprintf(
      "O-IFNML/cross-engine (ragged, glmmTMB<->lme4): |dICC(A,1)|=%.2e\n",
      red_ce
    ))
    stopifnot(red_ce < 1e-3)
  }
}

# --- recovery + coverage grid --------------------------------------------------------
cells <- list(
  list(label = "equal-k4", kc = rep(4L, 6L), ns = 8L, p = 0.75),
  list(label = "unequal-k", kc = c(2L, 3L, 4L, 5L, 4L, 3L), ns = 8L, p = 0.80)
)
results <- list()
i <- 0L
for (cc in cells) {
  for (theta2 in c(0, 0.5)) {
    i <- i + 1L
    res <- one_cell(
      cc$label,
      cc$kc,
      cc$ns,
      theta2,
      cc$p,
      base_seed = 360000L + i * 1000L
    )
    results[[i]] <- res
    cat(sprintf(
      "[%d/%d] %-9s kc=%-11s theta2=%.2f (%-8s) pop=%.4f cover=%.3f bias=%+.4f (n=%d fail=%d)\n",
      i,
      length(cells) * 2L,
      cc$label,
      res$kc,
      theta2,
      res$cell,
      res$pop_icc,
      res$coverage,
      res$mean_bias,
      res$n_fit,
      res$n_fail
    ))
    flush.console()
  }
}
out <- do.call(rbind, results)
out$n_rep <- n_rep
out$mc_n <- mc_n
attr(out, "reductions") <- c(
  single = red_single,
  average = red_avg,
  cross_engine = red_ce
)

cat("\n=== O-IFNML summary ===\n")
print(out[, c(
  "label",
  "kc",
  "theta2",
  "cell",
  "pop_icc",
  "coverage",
  "mean_bias",
  "n_fit"
)])

saveRDS(out, "tests/testthat/fixtures/incomplete-fixed-nested-oracle.rds")
cat("\nWrote tests/testthat/fixtures/incomplete-fixed-nested-oracle.rds\n")
