# Oracle O-cluster-ck: averaged cluster-level ICC(c,k) on incomplete/ragged crossed
# (Design 1) multilevel data (M46, ADR-057; Fable-blessed, ADR-057 Amendment 1) ----
#
# Provenance for tests/testthat/test-icc-incomplete-multilevel.R (PRINCIPLES.md
# #1, #4). Reproducible, seeded, standalone (Rscript data-raw/oracle-cluster-ck-incomplete.R);
# every reference relationship is re-derived here with stopifnot() tolerances, by
# deliberately-dumb code INDEPENDENT of icc() (the tests then check icc() against it).
#
# M46 lifts the M9 abort on the averaged cluster-level ICC(c,k) under imbalance. The
# fit and the cluster error sets are unchanged (M5/M9 §3b): signal sigma^2_c;
# agreement error {sigma^2_r, sigma^2_cr}, consistency {sigma^2_cr}. The only new
# object is the divisor:
#
#   k_c^eff = 1 / mean_c(1 / m_c^IS),   m_c^IS = 1 / sum_r w_{c,r}^2,
#   w_{c,r} = (observed cells of rater r in cluster c) / (observed cells in cluster c)
#
# (the inverse-Simpson effective rater count behind each cluster's observed cell-pooled
# mean; = rater count on balanced data). No textbook worked example exists, so the
# >= 2 independent oracles are:
#   O-cluster-score  (CHK-A): a SCORE-based, weight-free empirical reliability (paired
#     fresh-rater replicates; plain cluster cell means; no w in the measurement) that the
#     inverse-Simpson plug-in Phi/rho recovers -- breaks the T1 spike's circularity.
#   O-cluster-fit    (CHK-B): the ship-path glmmTMB five-component REML fit + plug-in at
#     k_c^eff from ESTIMATED components recovers the same empirical truth.
#   O-cluster-lme4:  lme4 reproduces the five components on the same ragged data < 1e-4.
#   O-cluster-reduction: complete data -> k_c^eff = k exactly and the coefficient equals
#     the balanced M5 Design-1 ICC(c,k).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("lme4", quietly = TRUE))
})

# ---- the divisor, re-implemented independently of R/design.R ----
cluster_k_eff_ref <- function(d) {
  per <- tapply(seq_len(nrow(d)), d$cluster, function(ix) {
    w <- as.numeric(table(droplevels(d$rater[ix])))
    w <- w / sum(w)
    1 / sum(w^2)
  })
  1 / mean(1 / per)
}

# ---- crossed Design-1 generator (global raters, five components) ----
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
# extreme within-cluster weight imbalance: m_c^IS << distinct count (separates
# inverse-Simpson from distinct-count; the C6 spike design).
extreme_imbalance <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  d <- sim_design1(nc, ns, k, vc, vsc, vr, vcr, vres, seed)
  set.seed(seed + 1)
  keep <- logical(nrow(d))
  for (c in levels(d$cluster)) {
    in_c <- which(d$cluster == c)
    dom <- sample(seq_len(k), 1)
    for (i in in_c) {
      r <- as.integer(d$rater[i])
      keep[i] <- r == dom ||
        (d$subj[i] %% ceiling(ns / 3)) == (r %% ceiling(ns / 3))
    }
  }
  kept <- d[keep, , drop = FALSE]
  ok <- names(which(vapply(
    split(kept$rater, kept$cluster),
    \(rs) length(unique(rs)) >= 2,
    logical(1)
  )))
  droplevels(kept[kept$cluster %in% ok, , drop = FALSE])
}

# ---- O-cluster-score (CHK-A): weight-free empirical reliability ----
# On a fixed ragged design, draw PAIRED replicates of the rater-side components and
# form each cluster's PLAIN observed cell mean (no weights in the measurement). Half
# the mean squared replicate difference estimates the per-cluster error variance;
# cluster/subject effects cancel in the difference; only the iid-mean leakage
# vres/n_cells remains, subtracted analytically. Agreement: fresh raters + cr per
# replicate. Consistency: shared rater mains, fresh cr.
measure_reliability <- function(d, vc, vr, vcr, vres, R = 6000, seed = 4601) {
  set.seed(seed)
  cl_ix <- as.integer(d$cluster)
  nc <- max(cl_ix)
  r_ix <- as.integer(d$rater)
  k <- nlevels(d$rater)
  n_cells <- tabulate(cl_ix, nc)
  leak <- vres / n_cells
  cell_mean <- function(y) as.numeric(rowsum(y, cl_ix)) / n_cells
  agree <- consis <- numeric(nc)
  for (g in seq_len(R)) {
    rr1 <- stats::rnorm(k, 0, sqrt(vr))
    rr2 <- stats::rnorm(k, 0, sqrt(vr))
    cr1 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    cr2 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    cr3 <- matrix(stats::rnorm(nc * k, 0, sqrt(vcr)), nc, k)
    e1 <- stats::rnorm(length(cl_ix), 0, sqrt(vres))
    y1 <- rr1[r_ix] + cr1[cbind(cl_ix, r_ix)] + e1
    y2 <- rr2[r_ix] +
      cr2[cbind(cl_ix, r_ix)] +
      stats::rnorm(length(cl_ix), 0, sqrt(vres))
    y3 <- rr1[r_ix] +
      cr3[cbind(cl_ix, r_ix)] +
      stats::rnorm(length(cl_ix), 0, sqrt(vres))
    m1 <- cell_mean(y1)
    agree <- agree + (m1 - cell_mean(y2))^2 / 2
    consis <- consis + (m1 - cell_mean(y3))^2 / 2
  }
  abs_err <- mean(agree / R - leak) # mean per-cluster absolute (agreement) error
  rel_err <- mean(consis / R - leak) # mean per-cluster relative (consistency) error
  c(
    Phi = vc / (vc + abs_err),
    rho = vc / (vc + rel_err),
    abs_err = abs_err,
    rel_err = rel_err
  )
}

# ---- component extraction (five-component REML) ----
comp <- function(d, engine) {
  form <- score ~ 1 +
    (1 | cluster) +
    (1 | cluster:subject) +
    (1 | rater) +
    (1 | cluster:rater)
  if (engine == "glmmTMB") {
    m <- glmmTMB::glmmTMB(form, data = d, REML = TRUE)
    vc <- glmmTMB::VarCorr(m)$cond
    g <- function(nm) as.numeric(attr(vc[[nm]], "stddev"))^2
    c(
      vc = g("cluster"),
      vr = g("rater"),
      vcr = g("cluster:rater"),
      vres = stats::sigma(m)^2
    )
  } else {
    m <- lme4::lmer(
      form,
      data = d,
      REML = TRUE,
      control = lme4::lmerControl(check.conv.singular = "ignore")
    )
    v <- as.data.frame(lme4::VarCorr(m))
    g <- function(grp) v$vcov[v$grp == grp][1]
    c(
      vc = g("cluster"),
      vr = g("rater"),
      vcr = g("cluster:rater"),
      vres = v$vcov[v$grp == "Residual"]
    )
  }
}
cluster_iccs <- function(cm, k) {
  c(
    Ak = cm[["vc"]] / (cm[["vc"]] + (cm[["vr"]] + cm[["vcr"]]) / k),
    Ck = cm[["vc"]] / (cm[["vc"]] + cm[["vcr"]] / k)
  )
}

vc <- 1.0
vsc <- 0.8
vr <- 0.5
vcr <- 0.3
vres <- 0.6
cat("Components: vc=1.0 vsc=0.8 vr=0.5 vcr=0.3 vres=0.6\n")

# --- O-cluster-score (CHK-A): inverse-Simpson plug-in recovers the weight-free truth
d_c6 <- extreme_imbalance(60, 30, 6, vc, vsc, vr, vcr, vres, 2026071206)
k_is <- cluster_k_eff_ref(d_c6)
truth <- measure_reliability(d_c6, vc, vr, vcr, vres, R = 6000, seed = 4606)
plug <- c(
  Phi = vc / (vc + (vr + vcr) / k_is),
  rho = vc / (vc + vcr / k_is)
)
cat(sprintf(
  "\nO-cluster-score (C6 extreme imbalance, k_IS=%.3f): empirical Phi=%.4f rho=%.4f | plug-in Phi=%.4f rho=%.4f\n",
  k_is,
  truth[["Phi"]],
  truth[["rho"]],
  plug[["Phi"]],
  plug[["rho"]]
))
stopifnot(abs(plug[["Phi"]] - truth[["Phi"]]) < 0.01)
stopifnot(abs(plug[["rho"]] - truth[["rho"]]) < 0.01)
# and the distinct-count harmonic is REFUTED here (over-states, the T1 finding)
k_dist_c6 <- 6 # every cluster keeps all 6 raters, unevenly weighted
stopifnot(vc / (vc + (vr + vcr) / k_dist_c6) - truth[["Phi"]] > 0.1)
cat(
  "  distinct-count harmonic refuted (over-states Phi by >0.1); inverse-Simpson recovers.\n"
)

# --- O-cluster-fit (CHK-B): ship-path fit + plug-in recovers the same truth
set.seed(606)
n_fit <- 40
sp <- t(vapply(
  seq_len(n_fit),
  function(i) {
    di <- d_c6
    cl <- stats::rnorm(nlevels(di$cluster), 0, sqrt(vc))
    scv <- stats::rnorm(nlevels(di$subject), 0, sqrt(vsc))
    rr <- stats::rnorm(nlevels(di$rater), 0, sqrt(vr))
    crv <- matrix(
      stats::rnorm(nlevels(di$cluster) * nlevels(di$rater), 0, sqrt(vcr)),
      nlevels(di$cluster),
      nlevels(di$rater)
    )
    di$score <- 10 +
      cl[as.integer(di$cluster)] +
      scv[as.integer(di$subject)] +
      rr[as.integer(di$rater)] +
      crv[cbind(as.integer(di$cluster), as.integer(di$rater))] +
      stats::rnorm(nrow(di), 0, sqrt(vres))
    cluster_iccs(comp(di, "glmmTMB"), k_is)
  },
  numeric(2)
))
cat(sprintf(
  "O-cluster-fit (C6, n_fit=%d): mean fitted Phi=%.4f rho=%.4f vs empirical Phi=%.4f rho=%.4f\n",
  n_fit,
  mean(sp[, "Ak"]),
  mean(sp[, "Ck"]),
  truth[["Phi"]],
  truth[["rho"]]
))
stopifnot(abs(mean(sp[, "Ak"]) - truth[["Phi"]]) < 0.03)
stopifnot(abs(mean(sp[, "Ck"]) - truth[["rho"]]) < 0.03)

# --- O-cluster-lme4: cross-engine five components on ragged data < 1e-4
d_rag <- sim_design1(10, 6, 5, vc, vsc, vr, vcr, vres, 20260712)
d_rag <- droplevels(d_rag[-sample(nrow(d_rag), round(0.15 * nrow(d_rag))), ])
kg <- cluster_k_eff_ref(d_rag)
ig <- cluster_iccs(comp(d_rag, "glmmTMB"), kg)
il <- cluster_iccs(comp(d_rag, "lme4"), kg)
cat(sprintf(
  "\nO-cluster-lme4 (ragged, k_c^eff=%.3f): glmmTMB vs lme4 max |diff| = %.2e\n",
  kg,
  max(abs(ig - il))
))
stopifnot(max(abs(ig - il)) < 1e-4)

# --- O-cluster-reduction: complete data -> k_c^eff = k exactly
d_full <- sim_design1(8, 6, 5, vc, vsc, vr, vcr, vres, 909)
stopifnot(abs(cluster_k_eff_ref(d_full) - 5) < 1e-9)
cat(
  "\nO-cluster-reduction: complete data k_c^eff = 5 (= rater count) exactly.\n"
)

cat(
  "\nAll O-cluster-ck (incomplete averaged cluster-level ICC(c,k)) oracle checks passed.\n"
)
