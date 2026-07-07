# Oracle O-IML: incomplete/unbalanced crossed (Design 1) multilevel ICCs --------
#
# Provenance for tests/testthat/test-icc-incomplete-multilevel.R (PRINCIPLES.md
# #1, #4, #12). Reproducible and seeded; nothing hardcoded -- this script
# regenerates every reference relationship with stopifnot() tolerance checks and
# is runnable standalone (Rscript data-raw/oracle-incomplete-multilevel.R).
#
# M9 estimates the M5 Design-1 subject-level ICCs (raters crossed with clusters,
# ten Hove, Jorgensen & van der Ark 2022, Eq. 12 / Table 3 top-left) on RAGGED
# data (missing subject x rater cells), reusing the M3 k_eff harmonic-mean divisor
# and a connectedness identifiability guard. It is NOT a new estimand: the
# subject-level agreement error is {rater, residual} and consistency is {residual}
# -- sigma^2_cr (cluster x rater) does NOT enter the subject-level error, because a
# cluster x rater effect shifts every subject in a cluster equally and so cannot
# change within-cluster subject discrimination. (An early draft wrongly included
# sigma^2_cr; corrected against the shipped M5 icc_point() and this cross-engine
# check before any code -- #1.)
#
# No Shrout-Fleiss-style textbook worked example exists, so the >= 2 independent
# oracles are (1) an lme4 cross-engine fit of the identical five-component model on
# the same ragged data, (2) a seeded simulation with known population components,
# plus reductions to the pinned complete-M5 and flat-incomplete-M3 estimands.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

# Balanced crossed Design-1 generator with known population components. Raters are
# CROSSED with clusters -> GLOBAL rater labels (rater "1" is the same person in
# every cluster). Fit (our translation of Eq. 7, oracle-pinned in M5):
#   score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) + (1|cluster:rater)
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

ragged <- function(d, prop, seed) {
  set.seed(seed)
  d[-sample(nrow(d), round(prop * nrow(d))), , drop = FALSE]
}

# k_eff = harmonic mean of per-subject rating counts (M3 §5, ADR-008).
k_eff_of <- function(d) {
  n_i <- as.integer(table(d$subject))
  1 / mean(1 / n_i)
}

# Subject-level ICCs from fitted components, CORRECT error sets (no sigma^2_cr).
subject_iccs <- function(vsc, vr, vres, k_eff) {
  c(
    A1 = vsc / (vsc + vr + vres),
    Ak = vsc / (vsc + (vr + vres) / k_eff),
    C1 = vsc / (vsc + vres),
    Ck = vsc / (vsc + vres / k_eff)
  )
}

comp_glmmtmb <- function(d) {
  m <- glmmTMB::glmmTMB(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- glmmTMB::VarCorr(m)$cond
  sd2 <- function(nm) as.numeric(attr(vc[[nm]], "stddev"))^2
  c(
    vsc = sd2("cluster:subject"),
    vr = sd2("rater"),
    vres = stats::sigma(m)^2
  )
}

comp_lme4 <- function(d) {
  m <- lme4::lmer(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE,
    control = lme4::lmerControl(check.conv.singular = "ignore")
  )
  v <- as.data.frame(lme4::VarCorr(m))
  g <- function(grp) v$vcov[v$grp == grp][1]
  c(vsc = g("cluster:subject"), vr = g("rater"), vres = g("Residual"))
}

# --- O-IML/lme4: ragged Design-1 subject ICCs, glmmTMB vs lme4 (< 1e-4) ---------
d <- ragged(
  sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707),
  0.15,
  7
)
ke <- k_eff_of(d)
cg <- comp_glmmtmb(d)
cl <- comp_lme4(d)
ig <- subject_iccs(cg[["vsc"]], cg[["vr"]], cg[["vres"]], ke)
il <- subject_iccs(cl[["vsc"]], cl[["vr"]], cl[["vres"]], ke)
cat("O-IML/lme4 (ragged): glmmTMB vs lme4 subject ICCs\n")
print(round(rbind(glmmTMB = ig, lme4 = il), 6))
stopifnot(max(abs(ig - il)) < 1e-4)

# --- O-IML/reduction -> complete M5: k_eff = k, balanced -----------------------
dc <- sim_design1(6, 5, 4, 1.0, 0.8, 0.5, 0.3, 0.6, seed = 20260707)
stopifnot(abs(k_eff_of(dc) - 4) < 1e-9)
cgc <- comp_glmmtmb(dc)
clc <- comp_lme4(dc)
stopifnot(
  max(abs(
    subject_iccs(cgc[["vsc"]], cgc[["vr"]], cgc[["vres"]], 4) -
      subject_iccs(clc[["vsc"]], clc[["vr"]], clc[["vres"]], 4)
  )) <
    1e-4
)
cat("\nO-IML/reduction (complete): balanced, k_eff = 4, glmmTMB == lme4.\n")

# --- O-IML/reduction -> flat M3: a single cluster == flat two-way ---------------
# With one cluster sigma^2_c -> 0 and sigma^2_cr folds into sigma^2_r; the
# multilevel consistency ICCs (which use only sigma^2_{s:c} and residual) equal the
# flat two-way consistency ICCs on the same ragged ratings.
d1 <- ragged(
  sim_design1(1, 12, 5, 0.0, 1.0, 0.5, 0.0, 0.6, seed = 4242),
  0.2,
  3
)
kf <- k_eff_of(d1)
cm <- comp_glmmtmb(d1)
mlc <- c(
  C1 = cm[["vsc"]] / (cm[["vsc"]] + cm[["vres"]]),
  Ck = cm[["vsc"]] / (cm[["vsc"]] + cm[["vres"]] / kf)
)
flat <- glmmTMB::glmmTMB(
  score ~ 1 + (1 | subject) + (1 | rater),
  data = d1,
  REML = TRUE
)
fvc <- glmmTMB::VarCorr(flat)$cond
fs <- as.numeric(attr(fvc[["subject"]], "stddev"))^2
fres <- stats::sigma(flat)^2
flatc <- c(C1 = fs / (fs + fres), Ck = fs / (fs + fres / kf))
cat(
  "\nO-IML/reduction (single cluster): multilevel vs flat two-way consistency\n"
)
print(round(rbind(multilevel = mlc, flat = flatc), 6))
stopifnot(max(abs(mlc - flatc)) < 1e-3)

# --- O-IML/sim: recover the known population consistency ICC --------------------
vsc <- 1.0
vres <- 0.6
target_c1 <- vsc / (vsc + vres) # = 0.625
ds <- ragged(
  sim_design1(50, 12, 6, 0.8, vsc, 0.5, 0.3, vres, seed = 7),
  0.15,
  9
)
cs <- comp_glmmtmb(ds)
sim_c1 <- cs[["vsc"]] / (cs[["vsc"]] + cs[["vres"]])
cat(sprintf(
  "\nO-IML/sim: population C1 = %.4f, recovered = %.4f\n",
  target_c1,
  sim_c1
))
stopifnot(abs(sim_c1 - target_c1) < 0.04)

cat("\nAll O-IML (incomplete crossed Design-1) oracle checks passed.\n")
