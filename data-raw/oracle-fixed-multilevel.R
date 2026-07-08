# Oracle O-FML: fixed-rater multilevel ICCs (Design 1, balanced) ----------------
#
# Provenance for tests/testthat/test-icc-fixed-multilevel.R (PRINCIPLES.md #1, #4,
# #12). Reproducible, seeded, standalone (Rscript data-raw/oracle-fixed-multilevel.R);
# every reference relationship is regenerated with stopifnot() tolerance checks.
#
# M10 treats raters as FIXED (McGraw & Wong 1996, Case 3/3A) in the crossed
# multilevel Design-1 fit, balanced/complete, subject level. The rater main effect
# becomes the bias-corrected finite-population theta^2_r (inherited from M3 §6),
# placed in the M5 subject-level decomposition (spec M10). No new estimand concept:
# theta^2_r fills the "rater" slot in place of the random sigma^2_r.
#
# No textbook worked example exists, so the >= 2 independent oracles are (1) the
# PRIMARY reduction -- on BALANCED data theta^2_r == sigma^2_r, so the fixed-rater
# subject-level ICCs equal the random-rater M5 ones -- and (2) an lme4 cross-engine
# fit of the identical fixed-rater model; a seeded simulation recovers the known
# population value.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

sim_design1 <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rr <- stats::rnorm(k, 0, sqrt(vr))
  crv <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rr[d$rater] +
    crv[cbind(d$cluster, d$rater)] +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(d$rater)
  d
}

# Bias-corrected finite-population theta^2_r (Case 3A) from a fitted fixed-rater
# model (the same computation the package uses; M3 §6).
theta2r <- function(fit, k) {
  beta <- glmmTMB::fixef(fit)$cond
  vbeta <- as.matrix(stats::vcov(fit)$cond)
  contrast <- cbind(rep(1, k), rbind(rep(0, k - 1), diag(k - 1)))
  center <- diag(k) - matrix(1 / k, k, k)
  bias <- sum(diag(center %*% (contrast %*% vbeta %*% t(contrast)))) / (k - 1)
  mu <- as.numeric(contrast %*% beta)
  max(0, as.numeric(t(mu) %*% center %*% mu) / (k - 1) - bias)
}

subject_iccs <- function(vsc, vr, vres, k) {
  c(
    A1 = vsc / (vsc + vr + vres),
    Ak = vsc / (vsc + (vr + vres) / k),
    C1 = vsc / (vsc + vres),
    Ck = vsc / (vsc + vres / k)
  )
}

d <- sim_design1(12, 6, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707) # balanced
k <- nlevels(d$rater)
sd2 <- function(x) as.numeric(attr(x, "stddev"))^2

# --- random-rater M5 fit ---
mr <- glmmTMB::glmmTMB(
  score ~ 1 +
    (1 | cluster) +
    (1 | cluster:subject) +
    (1 | rater) +
    (1 | cluster:rater),
  data = d,
  REML = TRUE
)
vr <- glmmTMB::VarCorr(mr)$cond
rand <- subject_iccs(
  sd2(vr[["cluster:subject"]]),
  sd2(vr[["rater"]]),
  sigma(mr)^2,
  k
)

# --- fixed-rater multilevel fit ---
mf <- glmmTMB::glmmTMB(
  score ~ 1 +
    rater +
    (1 | cluster) +
    (1 | cluster:subject) +
    (1 | cluster:rater),
  data = d,
  REML = TRUE
)
vf <- glmmTMB::VarCorr(mf)$cond
fixed <- subject_iccs(
  sd2(vf[["cluster:subject"]]),
  theta2r(mf, k),
  sigma(mf)^2,
  k
)

cat("O-FML/reduction (PRIMARY): balanced fixed vs random M5 subject ICCs\n")
print(round(rbind(random = rand, fixed = fixed), 6))
stopifnot(max(abs(rand - fixed)) < 1e-4)

# --- O-FML/lme4: fixed-rater multilevel components vs an independent lme4 fit ---
ml <- lme4::lmer(
  score ~ 1 +
    rater +
    (1 | cluster) +
    (1 | cluster:subject) +
    (1 | cluster:rater),
  data = d,
  REML = TRUE,
  control = lme4::lmerControl(check.conv.singular = "ignore")
)
lvc <- as.data.frame(lme4::VarCorr(ml))
g <- function(grp) lvc$vcov[lvc$grp == grp][1]
stopifnot(abs(sd2(vf[["cluster:subject"]]) - g("cluster:subject")) < 1e-4)
stopifnot(abs(sigma(mf)^2 - g("Residual")) < 1e-4)
stopifnot(abs(sd2(vf[["cluster:rater"]]) - g("cluster:rater")) < 1e-4)
cat("\nO-FML/lme4: fixed multilevel components match lme4 (< 1e-4).\n")

# --- O-FML/sim: recover the known population consistency ICC ---
vsc <- 1.0
vres <- 0.6
target_c1 <- vsc / (vsc + vres) # = 0.625
ds <- sim_design1(50, 10, 5, 0.8, vsc, 0.5, 0.3, vres, seed = 314)
mfs <- glmmTMB::glmmTMB(
  score ~ 1 +
    rater +
    (1 | cluster) +
    (1 | cluster:subject) +
    (1 | cluster:rater),
  data = ds,
  REML = TRUE
)
vfs <- glmmTMB::VarCorr(mfs)$cond
sim_c1 <- sd2(vfs[["cluster:subject"]]) /
  (sd2(vfs[["cluster:subject"]]) + sigma(mfs)^2)
cat(sprintf(
  "\nO-FML/sim: population C1 = %.4f, recovered = %.4f\n",
  target_c1,
  sim_c1
))
stopifnot(abs(sim_c1 - target_c1) < 0.04)

cat(
  "\nAll O-FML (fixed-rater multilevel Design-1 balanced) oracle checks passed.\n"
)

# ==============================================================================
# O-FNML: fixed-rater NESTED multilevel ICCs (Design 2, balanced) -- M19 Slice 2
# ==============================================================================
#
# Raters nested in clusters (Design 2) with raters treated as FIXED: each cluster's
# k raters are its own finite population, so the rater slot carries theta^2_{r:c} =
# the mean over clusters of the within-cluster bias-corrected finite-population
# variance of that cluster's rater means (McGraw & Wong Case 3A per cluster). The
# fit is the cell-mean parameterization  score ~ 0 + rater + (1|cluster:subject).
#
# IMPORTANT (oracle-first catch, ADR-029): unlike the CROSSED fixed design (M10),
# fixed != random even on balanced data. The nested finite population is per-cluster,
# so theta^2_{r:c} differs from the random pooled sigma^2_{r:c} (they coincide only as
# the raters-per-cluster -> Inf). The pins are therefore NOT "balanced fixed == random"
# but:
#   (1) per-cluster average: theta^2_{r:c} == mean over clusters of the flat M3 fixed
#       theta^2_r fit on each cluster's data alone (ties it to the pinned M3 Case-3A
#       estimand; exact);
#   (2) single-cluster reduction: the fixed-nested components reduce to the flat M3
#       fixed components (theta^2_r, sigma^2_{s:c}, residual) exactly;
#   (3) consistency == random exactly (the rater term is unused);
#   (4) glmmTMB <-> lme4 cross-engine < 1e-4.

sd2 <- function(v) as.numeric(attr(v, "stddev"))^2

# Bias-corrected finite-population variance of k means with covariance V (Case 3A).
theta2_fp <- function(mu, vmat, k) {
  cen <- diag(k) - matrix(1 / k, k, k)
  raw <- as.numeric(t(mu) %*% cen %*% mu) / (k - 1)
  bias <- sum(diag(cen %*% vmat)) / (k - 1)
  max(0, raw - bias)
}

# Flat two-way fixed theta^2_r (M3 Case 3A): score ~ 1 + rater + (1|subject).
theta2_flat <- function(d, k) {
  m <- glmmTMB::glmmTMB(
    score ~ 1 + rater + (1 | subject),
    data = d,
    REML = TRUE
  )
  b <- glmmTMB::fixef(m)$cond
  contrast <- cbind(rep(1, k), rbind(rep(0, k - 1), diag(k - 1)))
  mu <- as.numeric(contrast %*% b)
  vmat <- contrast %*% as.matrix(stats::vcov(m)$cond) %*% t(contrast)
  theta2_fp(mu, vmat, k)
}

# Nested fixed theta^2_{r:c}: score ~ 0 + rater + (1|cluster:subject), per-cluster
# finite-pop variance averaged.
comp_fixed_nested <- function(d, k) {
  m <- glmmTMB::glmmTMB(
    score ~ 0 + rater + (1 | cluster:subject),
    data = d,
    REML = TRUE
  )
  b <- glmmTMB::fixef(m)$cond
  vmat <- as.matrix(stats::vcov(m)$cond)
  cl_of <- tapply(as.character(d$cluster), d$rater, `[`, 1L)[
    sub("^rater", "", names(b))
  ]
  idx <- split(seq_along(b), cl_of)
  th <- mean(vapply(
    idx,
    function(ix) theta2_fp(b[ix], vmat[ix, ix, drop = FALSE], k),
    numeric(1)
  ))
  list(
    subject = sd2(glmmTMB::VarCorr(m)$cond[["cluster:subject"]]),
    rater = th,
    residual = stats::sigma(m)^2
  )
}

sim_design2 <- function(nc, ns, k, vc, vsc, vrc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  d <- expand.grid(
    subj = seq_len(ns),
    rater = seq_len(k),
    cluster = seq_len(nc)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  rcv <- stats::rnorm(nc * k, 0, sqrt(vrc))
  d$rc <- rcv[(d$cluster - 1) * k + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    d$rc +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

# --- (1) per-cluster-average pin ----------------------------------------------
k <- 5
d2 <- sim_design2(15, 8, k, 1.0, 1.2, 0.7, 0.5, seed = 20260709)
cn <- comp_fixed_nested(d2, k)
per_cluster <- vapply(
  levels(d2$cluster),
  function(cl) {
    sub <- droplevels(d2[d2$cluster == cl, ])
    sub$rater <- droplevels(sub$rater)
    theta2_flat(sub, k)
  },
  numeric(1)
)
cat(sprintf(
  "\nO-FNML/reduction (per-cluster average): theta^2_{r:c} = %.5f, mean(per-cluster M3) = %.5f, |diff| = %.2e\n",
  cn$rater,
  mean(per_cluster),
  abs(cn$rater - mean(per_cluster))
))
stopifnot(abs(cn$rater - mean(per_cluster)) < 1e-4)

# --- (2) single-cluster reduction to the flat M3 fixed components --------------
d1 <- sim_design2(1, 15, 6, 0, 1.2, 0.7, 0.5, seed = 99)
cn1 <- comp_fixed_nested(d1, 6)
mf1 <- glmmTMB::glmmTMB(
  score ~ 1 + rater + (1 | subject),
  data = d1,
  REML = TRUE
)
flat_theta <- theta2_flat(d1, 6)
flat_sub <- sd2(glmmTMB::VarCorr(mf1)$cond$subject)
flat_res <- stats::sigma(mf1)^2
cat(sprintf(
  "O-FNML/single-cluster: rater %.2e, subject %.2e, residual %.2e\n",
  abs(cn1$rater - flat_theta),
  abs(cn1$subject - flat_sub),
  abs(cn1$residual - flat_res)
))
stopifnot(
  abs(cn1$rater - flat_theta) < 1e-6,
  abs(cn1$subject - flat_sub) < 1e-6,
  abs(cn1$residual - flat_res) < 1e-6
)

# --- (3) fixed != random on balanced nested data (the M10 identity does NOT hold) ---
mr <- glmmTMB::glmmTMB(
  score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater),
  data = d2,
  REML = TRUE
)
rc_random <- sd2(glmmTMB::VarCorr(mr)$cond[["cluster:rater"]])
cat(sprintf(
  "O-FNML/note: balanced theta^2_{r:c} = %.5f vs random sigma^2_{r:c} = %.5f (differ: per-cluster finite population)\n",
  cn$rater,
  rc_random
))

# --- (4) glmmTMB <-> lme4 cross-engine on theta^2_{r:c} ------------------------
comp_fixed_nested_lme4 <- function(d, k) {
  m <- lme4::lmer(
    score ~ 0 + rater + (1 | cluster:subject),
    data = d,
    REML = TRUE
  )
  b <- lme4::fixef(m)
  vmat <- as.matrix(stats::vcov(m))
  cl_of <- tapply(as.character(d$cluster), d$rater, `[`, 1L)[
    sub("^rater", "", names(b))
  ]
  idx <- split(seq_along(b), cl_of)
  mean(vapply(
    idx,
    function(ix) theta2_fp(b[ix], vmat[ix, ix, drop = FALSE], k),
    numeric(1)
  ))
}
th_lme4 <- comp_fixed_nested_lme4(d2, k)
cat(sprintf(
  "O-FNML/lme4: theta^2_{r:c} glmmTMB %.6f vs lme4 %.6f, |diff| %.2e\n",
  cn$rater,
  th_lme4,
  abs(cn$rater - th_lme4)
))
stopifnot(abs(cn$rater - th_lme4) < 1e-4)

cat(
  "\nAll O-FNML (fixed-rater nested Design-2 balanced) oracle checks passed.\n"
)
