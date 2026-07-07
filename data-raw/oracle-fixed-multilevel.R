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
