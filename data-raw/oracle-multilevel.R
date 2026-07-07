# Oracle O-ML: multilevel ICCs (subject- & cluster-level) ----------------------
#
# Provenance for the values asserted in tests/testthat/test-icc-multilevel.R
# (PRINCIPLES.md #1, #4, #12). Reproducible and seeded; nothing hardcoded — this
# script regenerates every reference value with stopifnot() tolerance checks.
#
# Design 1 of ten Hove, Jorgensen & van der Ark (2022, Psychological Methods
# 27(4):650-666, Table 3): subjects nested in clusters, raters crossed with both.
# Model  score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) + (1|cluster:rater)
# giving components sigma^2_c / sigma^2_{s:c} / sigma^2_r / sigma^2_{cr} / sigma^2_res.
#
# The multilevel IRR estimand has no Shrout & Fleiss-style textbook worked
# example (as with the incomplete-design oracle O5), so the >= 2 independent
# oracles are (1) an lme4 cross-engine fit of the identical model and (2) a
# seeded simulation with known population components. A third check ties the
# subject level back to the pinned single-level numbers.

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

# Balanced Design-1 generator with known population components.
sim_multilevel <- function(
  n_clusters,
  n_subjects,
  n_raters,
  vc,
  vsc,
  vr,
  vcr,
  vres,
  seed
) {
  set.seed(seed)
  cl <- stats::rnorm(n_clusters, 0, sqrt(vc))
  rt <- stats::rnorm(n_raters, 0, sqrt(vr))
  d <- expand.grid(
    subj = seq_len(n_subjects),
    cluster = seq_len(n_clusters),
    rater = seq_len(n_raters)
  )
  scv <- stats::rnorm(n_clusters * n_subjects, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * n_subjects + d$subj]
  crv <- stats::rnorm(n_clusters * n_raters, 0, sqrt(vcr))
  d$cr <- crv[(d$cluster - 1) * n_raters + d$rater]
  d$score <- 10 +
    cl[d$cluster] +
    d$sc +
    rt[d$rater] +
    d$cr +
    stats::rnorm(nrow(d), 0, sqrt(vres))
  d$cluster <- factor(d$cluster)
  d$rater <- factor(d$rater)
  d$subject <- factor(paste(d$cluster, d$subj, sep = "_"))
  d
}

model <- score ~
  1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)

components_glmmtmb <- function(d) {
  m <- glmmTMB::glmmTMB(model, data = d, REML = TRUE)
  vc <- glmmTMB::VarCorr(m)$cond
  c(
    cluster = as.numeric(attr(vc$cluster, "stddev"))^2,
    subject = as.numeric(attr(vc[["cluster:subject"]], "stddev"))^2,
    rater = as.numeric(attr(vc$rater, "stddev"))^2,
    cluster_rater = as.numeric(attr(vc[["cluster:rater"]], "stddev"))^2,
    residual = stats::sigma(m)^2
  )
}

components_lme4 <- function(d) {
  m <- lme4::lmer(model, data = d, REML = TRUE)
  vc <- lme4::VarCorr(m)
  c(
    cluster = as.numeric(vc$cluster),
    subject = as.numeric(vc[["cluster:subject"]]),
    rater = as.numeric(vc$rater),
    cluster_rater = as.numeric(vc[["cluster:rater"]]),
    residual = stats::sigma(m)^2
  )
}

# The four (level x type) coefficients at averaging divisor u (1 = single,
# n_raters = average), read straight from ten Hove Table 3, Design 1.
iccs <- function(x, u) {
  c(
    subject_A1 = x[["subject"]] /
      (x[["subject"]] + x[["rater"]] + x[["residual"]]),
    subject_Ak = x[["subject"]] /
      (x[["subject"]] + (x[["rater"]] + x[["residual"]]) / u),
    subject_C1 = x[["subject"]] / (x[["subject"]] + x[["residual"]]),
    subject_Ck = x[["subject"]] / (x[["subject"]] + x[["residual"]] / u),
    cluster_A1 = x[["cluster"]] /
      (x[["cluster"]] + x[["rater"]] + x[["cluster_rater"]]),
    cluster_Ak = x[["cluster"]] /
      (x[["cluster"]] + (x[["rater"]] + x[["cluster_rater"]]) / u),
    cluster_C1 = x[["cluster"]] / (x[["cluster"]] + x[["cluster_rater"]]),
    cluster_Ck = x[["cluster"]] / (x[["cluster"]] + x[["cluster_rater"]] / u)
  )
}

# --- Oracle 1: glmmTMB vs lme4 cross-engine (same model, balanced data) -------
d1 <- sim_multilevel(30, 10, 6, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 20260707)
g <- components_glmmtmb(d1)
l <- components_lme4(d1)
stopifnot(max(abs(g - l)) < 1e-4)
ig <- iccs(g, 6)
il <- iccs(l, 6)
stopifnot(max(abs(ig - il)) < 1e-4)
cat("O-ML/lme4: components agree to", signif(max(abs(g - l)), 3), "\n")
cat("O-ML/lme4: ICCs agree to", signif(max(abs(ig - il)), 3), "\n")
cat("Reference ICCs (glmmTMB, seed 20260707):\n")
print(round(ig, 5))

# Monotonic / range invariants (ten Hove Table 3 relationships).
stopifnot(
  ig[["subject_Ak"]] >= ig[["subject_A1"]],
  ig[["cluster_Ak"]] >= ig[["cluster_A1"]],
  ig[["subject_C1"]] >= ig[["subject_A1"]],
  ig[["cluster_C1"]] >= ig[["cluster_A1"]],
  all(ig >= 0 & ig <= 1)
)

# --- Oracle 2: recovery of known population components -------------------------
# Enough clusters (40) and raters (20) that sigma^2_c and the noisy sigma^2_r are
# identified in a single draw (cf. O5's k = 30 rationale). Population subject- and
# cluster-level ICC(A,1) from the true components are recovered within 0.05.
pop <- c(
  cluster = 1.0,
  subject = 1.2,
  rater = 0.7,
  cluster_rater = 0.16,
  residual = 0.5
)
k2 <- 20
pop_iccs <- iccs(pop, k2)
d2 <- sim_multilevel(40, 5, k2, 1.0, 1.2, 0.7, 0.16, 0.5, seed = 424242)
g2 <- components_glmmtmb(d2)
i2 <- iccs(g2, k2)
cat(
  "\nO-ML/sim: population subject_A1 =",
  round(pop_iccs[["subject_A1"]], 3),
  " recovered =",
  round(i2[["subject_A1"]], 3),
  "\n"
)
cat(
  "O-ML/sim: population cluster_A1 =",
  round(pop_iccs[["cluster_A1"]], 3),
  " recovered =",
  round(i2[["cluster_A1"]], 3),
  "\n"
)
stopifnot(
  abs(i2[["subject_A1"]] - pop_iccs[["subject_A1"]]) < 0.05,
  abs(i2[["cluster_A1"]] - pop_iccs[["cluster_A1"]]) < 0.05
)

# --- Oracle 3: single-level reduction (zero cluster variance) ------------------
# With sigma^2_c = sigma^2_cr = 0 and many clusters, the subject-level ICC must
# match a single-level two-way fit on the same ratings (spec M5 §5). Ties M5 to
# the pinned single-level oracle without asserting exact SF numbers.
d3 <- sim_multilevel(40, 8, 6, 0, 1.2, 0.7, 0, 0.5, seed = 99)
g3 <- components_glmmtmb(d3)
single <- glmmTMB::glmmTMB(
  score ~ 1 + (1 | subject) + (1 | rater),
  data = d3,
  REML = TRUE
)
vs <- glmmTMB::VarCorr(single)$cond
s_sub <- as.numeric(attr(vs$subject, "stddev"))^2
s_rat <- as.numeric(attr(vs$rater, "stddev"))^2
s_res <- stats::sigma(single)^2
ml_subject_a1 <- g3[["subject"]] /
  (g3[["subject"]] + g3[["rater"]] + g3[["residual"]])
sl_a1 <- s_sub / (s_sub + s_rat + s_res)
cat(
  "\nO-ML/reduction: multilevel subject_A1 =",
  round(ml_subject_a1, 4),
  " single-level A1 =",
  round(sl_a1, 4),
  "\n"
)
stopifnot(abs(ml_subject_a1 - sl_a1) < 1e-2)

cat("\nAll O-ML oracle checks passed.\n")
