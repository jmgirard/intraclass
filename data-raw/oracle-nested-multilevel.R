# Oracle O-NML: nested-rater multilevel ICCs (Designs 2/3) ---------------------
#
# Provenance for tests/testthat/test-icc-nested-multilevel.R (PRINCIPLES.md #1,
# #4, #12). Reproducible and seeded; nothing hardcoded — this script regenerates
# every reference value with stopifnot() tolerance checks.
#
# Source: ten Hove, Jorgensen & van der Ark (2022, Psychological Methods
# 27(4):650-666). Design 2 = raters nested within clusters (Eqs. 8-9, Table 3
# subject-level middle column); Design 3 = raters nested within subjects and
# clusters (Eqs. 10-11, right column). Cluster-level IRR is undefined for both
# (paper p. 6); Design 3 is agreement-only (rater variance confounded into
# residual). SLICE 1 covers Design 2; the Design 3 block is added in Slice 2.
#
# As with O-ML (Design 1), the nested-multilevel IRR estimand has no
# Shrout-Fleiss-style textbook worked example, so the >= 2 independent oracles are
# (1) an lme4 cross-engine fit of the identical model and (2) a seeded simulation
# with known population components; a third check ties Design 2 back to the pinned
# two-way estimand (single-cluster reduction).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

# ==============================================================================
# Design 2: raters nested within clusters (Eqs. 8-9)
# ==============================================================================
#
# Y_{(sr):c} = mu + mu_c + mu_{s:c} + mu_{r:c} + mu_{(sr):c}                (Eq. 8)
# sigma^2 = sigma^2_c + sigma^2_{s:c} + sigma^2_{r:c} + sigma^2_{(sr):c}    (Eq. 9)
#
# Each cluster has its OWN raters (rater labels unique per cluster), and within a
# cluster raters are crossed with subjects. Fit (our translation of Eq. 8):
#   score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)
# mapping cluster:rater -> the r:c ("rater") component and residual -> (sr):c.

sim_design2 <- function(
  n_clusters,
  n_subjects,
  n_raters,
  vc,
  vsc,
  vrc,
  vres,
  seed
) {
  set.seed(seed)
  cl <- stats::rnorm(n_clusters, 0, sqrt(vc))
  d <- expand.grid(
    subj = seq_len(n_subjects),
    rater = seq_len(n_raters),
    cluster = seq_len(n_clusters)
  )
  scv <- stats::rnorm(n_clusters * n_subjects, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * n_subjects + d$subj]
  # rater nested in cluster: a fresh set of raters per cluster
  rcv <- stats::rnorm(n_clusters * n_raters, 0, sqrt(vrc))
  d$rc <- rcv[(d$cluster - 1) * n_raters + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    d$rc +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  # rater labels unique per cluster (nesting): rater "c_r"
  d$rater <- factor(paste(d$cluster, d$rater, sep = "_"))
  d
}

model2 <- score ~ 1 +
  (1 | cluster) +
  (1 | cluster:subject) +
  (1 | cluster:rater)

comp2_glmmtmb <- function(d) {
  m <- glmmTMB::glmmTMB(model2, data = d, REML = TRUE)
  vc <- glmmTMB::VarCorr(m)$cond
  c(
    cluster = as.numeric(attr(vc$cluster, "stddev"))^2,
    subject = as.numeric(attr(vc[["cluster:subject"]], "stddev"))^2,
    rater = as.numeric(attr(vc[["cluster:rater"]], "stddev"))^2, # = sigma^2_{r:c}
    residual = stats::sigma(m)^2 # = sigma^2_{(sr):c}
  )
}

comp2_lme4 <- function(d) {
  m <- lme4::lmer(model2, data = d, REML = TRUE)
  vc <- lme4::VarCorr(m)
  c(
    cluster = as.numeric(vc$cluster),
    subject = as.numeric(vc[["cluster:subject"]]),
    rater = as.numeric(vc[["cluster:rater"]]),
    residual = stats::sigma(m)^2
  )
}

# Subject-level ICCs, ten Hove Table 3 (subject level, "raters nested in
# clusters"): signal sigma^2_{s:c}; NO cluster-related variance. `u` = divisor.
iccs2 <- function(x, u) {
  c(
    A1 = x[["subject"]] / (x[["subject"]] + x[["rater"]] + x[["residual"]]),
    Ak = x[["subject"]] /
      (x[["subject"]] + (x[["rater"]] + x[["residual"]]) / u),
    C1 = x[["subject"]] / (x[["subject"]] + x[["residual"]]),
    Ck = x[["subject"]] / (x[["subject"]] + x[["residual"]] / u)
  )
}

# --- O-NML/lme4: glmmTMB vs lme4 cross-engine (balanced Design 2) --------------
d1 <- sim_design2(30, 8, 6, 1.0, 1.2, 0.7, 0.5, seed = 20260707)
g <- comp2_glmmtmb(d1)
l <- comp2_lme4(d1)
stopifnot(max(abs(g - l)) < 1e-4)
ig <- iccs2(g, 6)
il <- iccs2(l, 6)
stopifnot(max(abs(ig - il)) < 1e-4)
cat(
  "O-NML/lme4 (Design 2): components agree to",
  signif(max(abs(g - l)), 3),
  "\n"
)
cat("O-NML/lme4 (Design 2): ICCs agree to", signif(max(abs(ig - il)), 3), "\n")
cat("Reference Design-2 subject-level ICCs (glmmTMB, seed 20260707):\n")
print(round(ig, 5))
stopifnot(
  ig[["Ak"]] >= ig[["A1"]],
  ig[["Ck"]] >= ig[["C1"]],
  ig[["C1"]] >= ig[["A1"]],
  all(ig >= 0 & ig <= 1)
)

# --- O-NML/sim: recovery of known population components (Design 2) -------------
pop <- c(cluster = 1.0, subject = 1.2, rater = 0.7, residual = 0.5)
k2 <- 20
pop_iccs <- iccs2(pop, k2)
d2 <- sim_design2(40, 5, k2, 1.0, 1.2, 0.7, 0.5, seed = 424242)
g2 <- comp2_glmmtmb(d2)
i2 <- iccs2(g2, k2)
cat(
  "\nO-NML/sim (Design 2): population A1 =",
  round(pop_iccs[["A1"]], 3),
  " recovered =",
  round(i2[["A1"]], 3),
  "\n"
)
stopifnot(abs(i2[["A1"]] - pop_iccs[["A1"]]) < 0.05)

# --- O-NML/reduction: single-cluster Design 2 == two-way (Eqs. reduce) ---------
# With one cluster, cluster:subject == subject and cluster:rater == rater, so the
# Design-2 components (dropping the degenerate cluster term) must equal an ordinary
# two-way fit on the same ratings, to < 1e-4. Ties D2's error-set structure to the
# pinned M1/M2 two-way estimand without asserting textbook numbers.
d3 <- sim_design2(1, 8, 6, 0, 1.2, 0.7, 0.5, seed = 99)
m_d2 <- glmmTMB::glmmTMB(
  score ~ 1 + (1 | cluster:subject) + (1 | cluster:rater),
  data = d3,
  REML = TRUE
)
vd <- glmmTMB::VarCorr(m_d2)$cond
d2_sub <- as.numeric(attr(vd[["cluster:subject"]], "stddev"))^2
d2_rat <- as.numeric(attr(vd[["cluster:rater"]], "stddev"))^2
d2_res <- stats::sigma(m_d2)^2
m_tw <- glmmTMB::glmmTMB(
  score ~ 1 + (1 | subject) + (1 | rater),
  data = d3,
  REML = TRUE
)
vt <- glmmTMB::VarCorr(m_tw)$cond
tw_sub <- as.numeric(attr(vt$subject, "stddev"))^2
tw_rat <- as.numeric(attr(vt$rater, "stddev"))^2
tw_res <- stats::sigma(m_tw)^2
d2_a1 <- d2_sub / (d2_sub + d2_rat + d2_res)
tw_a1 <- tw_sub / (tw_sub + tw_rat + tw_res)
cat(
  "\nO-NML/reduction (Design 2): single-cluster D2 A1 =",
  round(d2_a1, 5),
  " two-way A1 =",
  round(tw_a1, 5),
  "\n"
)
stopifnot(abs(d2_a1 - tw_a1) < 1e-4)

cat("\nAll O-NML Design-2 oracle checks passed.\n")

# ==============================================================================
# Design 3: raters nested within subjects and clusters (Eqs. 10-11)
# ==============================================================================
#
# Y_{r:s:c} = mu + mu_c + mu_{s:c} + mu_{r:s:c}                            (Eq. 10)
# sigma^2 = sigma^2_c + sigma^2_{s:c} + sigma^2_{r:s:c}                    (Eq. 11)
#
# Each subject has its OWN raters (rater labels unique per subject). The rater
# variance is confounded into residual, so this is the multilevel one-way design:
# AGREEMENT ONLY, no consistency (paper p. 6). Fit (our translation of Eq. 10):
#   score ~ 1 + (1|cluster) + (1|cluster:subject)
# with residual = sigma^2_{r:s:c}.

sim_design3 <- function(n_clusters, n_subjects, n_raters, vc, vsc, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(n_clusters, 0, sqrt(vc))
  d <- expand.grid(
    rep = seq_len(n_raters),
    subj = seq_len(n_subjects),
    cluster = seq_len(n_clusters)
  )
  scv <- stats::rnorm(n_clusters * n_subjects, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * n_subjects + d$subj]
  d$score <- 10 + cl[d$cluster] + d$sc + stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  # raters nested in subjects: label unique per (cluster, subject)
  d$rater <- factor(paste(d$cluster, d$subj, d$rep, sep = "_"))
  d
}

model3 <- score ~ 1 + (1 | cluster) + (1 | cluster:subject)

comp3_glmmtmb <- function(d) {
  m <- glmmTMB::glmmTMB(model3, data = d, REML = TRUE)
  vc <- glmmTMB::VarCorr(m)$cond
  c(
    cluster = as.numeric(attr(vc$cluster, "stddev"))^2,
    subject = as.numeric(attr(vc[["cluster:subject"]], "stddev"))^2,
    residual = stats::sigma(m)^2 # = sigma^2_{r:s:c} (rater confounded)
  )
}

comp3_lme4 <- function(d) {
  m <- lme4::lmer(model3, data = d, REML = TRUE)
  vc <- lme4::VarCorr(m)
  c(
    cluster = as.numeric(vc$cluster),
    subject = as.numeric(vc[["cluster:subject"]]),
    residual = stats::sigma(m)^2
  )
}

# Subject-level ICCs, ten Hove Table 3 (subject level, "raters nested in
# subjects"): agreement-only ICC_s(1)/ICC_s(k); signal sigma^2_{s:c}.
iccs3 <- function(x, u) {
  c(
    I1 = x[["subject"]] / (x[["subject"]] + x[["residual"]]),
    Ik = x[["subject"]] / (x[["subject"]] + x[["residual"]] / u)
  )
}

# --- O-NML/lme4: glmmTMB vs lme4 cross-engine (balanced Design 3) --------------
e1 <- sim_design3(30, 8, 6, 1.0, 1.2, 0.5, seed = 20260707)
g3 <- comp3_glmmtmb(e1)
l3 <- comp3_lme4(e1)
stopifnot(max(abs(g3 - l3)) < 1e-4)
jg <- iccs3(g3, 6)
jl <- iccs3(l3, 6)
stopifnot(max(abs(jg - jl)) < 1e-4)
cat(
  "\nO-NML/lme4 (Design 3): components agree to",
  signif(max(abs(g3 - l3)), 3),
  "\n"
)
cat("Reference Design-3 subject-level ICCs (glmmTMB, seed 20260707):\n")
print(round(jg, 5))
stopifnot(jg[["Ik"]] >= jg[["I1"]], all(jg >= 0 & jg <= 1))

# --- O-NML/sim: recovery of known population components (Design 3) -------------
pop3 <- c(subject = 1.2, residual = 0.5)
k3 <- 20
pop3_iccs <- iccs3(pop3, k3)
e2 <- sim_design3(40, 5, k3, 1.0, 1.2, 0.5, seed = 424242)
h3 <- comp3_glmmtmb(e2)
j2 <- iccs3(h3, k3)
cat(
  "\nO-NML/sim (Design 3): population I1 =",
  round(pop3_iccs[["I1"]], 3),
  " recovered =",
  round(j2[["I1"]], 3),
  "\n"
)
stopifnot(abs(j2[["I1"]] - pop3_iccs[["I1"]]) < 0.05)

# --- O-NML/reduction: Design 3 == M6 one-way (zero cluster variance) -----------
# With sigma^2_c = 0 and many clusters, Design 3 (raters nested in subjects) IS a
# single-level one-way design once cluster is ignored: rater identity is not
# modelled, so the subject-level ICC_s(1) must match a one-way fit
# score ~ 1 + (1|subject) on the same ratings, to < 1e-2. Ties Design 3 to the
# pinned M6 one-way estimand.
# Enough clusters/subjects that the estimated sigma^2_c settles near its true 0
# (finite samples otherwise absorb a little subject variance into cluster).
e3 <- sim_design3(50, 20, 6, 0, 1.2, 0.5, seed = 99)
h3r <- comp3_glmmtmb(e3)
d3_i1 <- h3r[["subject"]] / (h3r[["subject"]] + h3r[["residual"]])
m_ow <- glmmTMB::glmmTMB(score ~ 1 + (1 | subject), data = e3, REML = TRUE)
ow_sub <- as.numeric(attr(glmmTMB::VarCorr(m_ow)$cond$subject, "stddev"))^2
ow_res <- stats::sigma(m_ow)^2
ow_i1 <- ow_sub / (ow_sub + ow_res)
cat(
  "\nO-NML/reduction (Design 3): D3 I1 =",
  round(d3_i1, 5),
  " one-way ICC(1) =",
  round(ow_i1, 5),
  "\n"
)
stopifnot(abs(d3_i1 - ow_i1) < 1e-2)

cat("\nAll O-NML Design-2 and Design-3 oracle checks passed.\n")
