# Pilot: two-level SEM (lavaan) route to the Design-1 multilevel components ----
#
# M53 estimand/oracle pass (D-005). Establishes numerically whether a two-level
# CFA (lavaan `cluster =`) recovers the ten Hove, Jorgensen & van der Ark (2022,
# Psychological Methods 27(4):650-666) Design-1 five-component decomposition —
# the faithfulness evidence D-005 requires before any engine implementation.
# Mapping + tolerances rationale: cairn/references/sem-multilevel-pilot.md.
#
# Stage 1 (T3): one balanced dataset — five components + all eight Table-3 ICCs
#   from the two-level lavaan fit vs a REML glmmTMB fit; reduction check at
#   sigma^2_c = sigma^2_cr = 0 vs the shipped single-level lavaan engine.
# Stage 2 (T4): known-population recovery over 4 cells — A-C sweep the cluster
#   axis, D (k = 25) sweeps sigma^2_r's own axis (GP6/GP5 correction; see the
#   milestone Decisions) — per-rep seeds; glmmTMB parity deltas on the first
#   25 reps per cell; MC-interval feasibility probe on the Stage-1 fit.
#
# Seeded and reproducible (#4/#12); checkpoint saved BEFORE the stopifnot pins
# (M47/M52 lessons): data-raw/.oracle-pilot-sem-multilevel-checkpoint.rds.
# Expected runtime ~20-25 min (cells C and D are the bulk).

suppressPackageStartupMessages({
  stopifnot(requireNamespace("lavaan", quietly = TRUE))
  stopifnot(requireNamespace("glmmTMB", quietly = TRUE))
  stopifnot(requireNamespace("intraclass", quietly = TRUE))
})

# Balanced Design-1 generator with known population components (mirrors
# data-raw/oracle-multilevel.R's sim_multilevel; kept self-contained).
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

# Long -> wide (one row per subject, columns v1..vk + cluster id).
to_wide <- function(d) {
  k <- nlevels(d$rater)
  wide <- tapply(d$score, list(d$subject, d$rater), function(x) x[[1]])
  out <- as.data.frame(wide)
  names(out) <- paste0("v", seq_len(k))
  out$cluster <- d$cluster[match(rownames(wide), as.character(d$subject))]
  out
}

# The two-level CFA: within = subject factor (svw) + equal residuals (evw);
# between = cluster factor (svb) + equal residuals (evb) + free intercepts
# (rater main effects; grand-mean-centred quadratic form -> sigma^2_r).
ml_sem_model <- function(k) {
  inds <- paste0("v", seq_len(k))
  loadings <- paste(sprintf("1*%s", inds), collapse = " + ")
  paste(
    "level: 1",
    sprintf("subj =~ %s", loadings),
    paste(sprintf("%s ~~ evw*%s", inds, inds), collapse = "\n"),
    "subj ~~ svw*subj",
    "level: 2",
    sprintf("clus =~ %s", loadings),
    paste(sprintf("%s ~~ evb*%s", inds, inds), collapse = "\n"),
    "clus ~~ svb*clus",
    paste(sprintf("%s ~ 1", inds), collapse = "\n"),
    sep = "\n"
  )
}

# Fit + extract the five components from the two-level SEM. Returns NULL on
# non-convergence; negative between-level variances (Heywood) are returned
# as-is so callers can record incidence.
fit_ml_sem <- function(wide, k) {
  fit <- tryCatch(
    suppressWarnings(lavaan::lavaan(
      ml_sem_model(k),
      data = wide,
      cluster = "cluster"
    )),
    error = function(e) NULL
  )
  if (is.null(fit) || !lavaan::lavInspect(fit, "converged")) {
    return(NULL)
  }
  co <- lavaan::coef(fit)
  cn <- names(co)
  # Between-level intercepts are suffixed ".l2" in two-level coef() names.
  nu_i <- which(grepl("~1\\.l2$", cn))
  nu <- unname(co[nu_i])
  center <- diag(k) - matrix(1 / k, k, k)
  list(
    fit = fit,
    components = c(
      cluster = unname(co[[which(cn == "svb")[1]]]),
      subject = unname(co[[which(cn == "svw")[1]]]),
      rater = as.numeric(t(nu) %*% center %*% nu) / (k - 1),
      cluster_rater = unname(co[[which(cn == "evb")[1]]]),
      residual = unname(co[[which(cn == "evw")[1]]])
    ),
    nu_i = nu_i
  )
}

# REML glmmTMB fit of the same decomposition (the package's spine).
fit_reml <- function(d) {
  fit <- glmmTMB::glmmTMB(
    score ~ 1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  )
  vc <- glmmTMB::VarCorr(fit)$cond
  c(
    cluster = unname(attr(vc$cluster, "stddev"))^2,
    subject = unname(attr(vc$`cluster:subject`, "stddev"))^2,
    rater = unname(attr(vc$rater, "stddev"))^2,
    cluster_rater = unname(attr(vc$`cluster:rater`, "stddev"))^2,
    residual = attr(vc, "sc")^2
  )
}

# All eight Table-3 Design-1 ICCs (spec M5-multilevel.md section 3) from a
# named five-component vector; divisor k = rater count (single k_div = 1).
iccs_from_components <- function(comp, k) {
  icc_pt <- function(signal, error, k_div) signal / (signal + error / k_div)
  out <- c()
  for (unit_k in c(single = 1, average = k)) {
    out <- c(
      out,
      s_agr = icc_pt(comp["subject"], comp["rater"] + comp["residual"], unit_k),
      s_con = icc_pt(comp["subject"], comp["residual"], unit_k),
      c_agr = icc_pt(
        comp["cluster"],
        comp["rater"] + comp["cluster_rater"],
        unit_k
      ),
      c_con = icc_pt(comp["cluster"], comp["cluster_rater"], unit_k)
    )
  }
  names(out) <- paste(
    rep(c("s_agr", "s_con", "c_agr", "c_con"), 2),
    rep(c("1", "k"), each = 4),
    sep = "_"
  )
  out
}

checkpoint <- list()
ckpt_path <- file.path(
  "data-raw",
  ".oracle-pilot-sem-multilevel-checkpoint.rds"
)

# --- Stage 1: single balanced dataset, components + ICCs vs glmmTMB ----------

pop1 <- c(vc = 0.4, vsc = 1, vr = 0.16, vcr = 0.16, vres = 0.5)
d1 <- sim_multilevel(
  40,
  10,
  5,
  pop1["vc"],
  pop1["vsc"],
  pop1["vr"],
  pop1["vcr"],
  pop1["vres"],
  seed = 20260716
)
sem1 <- fit_ml_sem(to_wide(d1), k = 5)
stopifnot(!is.null(sem1))
reml1 <- fit_reml(d1)
icc_sem1 <- iccs_from_components(sem1$components, k = 5)
icc_reml1 <- iccs_from_components(reml1, k = 5)
checkpoint$stage1 <- list(
  sem = sem1$components,
  reml = reml1,
  icc_sem = icc_sem1,
  icc_reml = icc_reml1
)
cat("Stage 1 components (SEM / REML):\n")
print(round(rbind(sem = sem1$components, reml = reml1), 4))
cat("Stage 1 ICCs (SEM / REML):\n")
print(round(rbind(sem = icc_sem1, reml = icc_reml1), 4))

# --- Stage 1b: reduction check (zero cluster variances) ----------------------

d0 <- sim_multilevel(50, 8, 4, 0, 1, 0.2, 0, 0.6, seed = 20260717)
sem0 <- fit_ml_sem(to_wide(d0), k = 4)
stopifnot(!is.null(sem0))
# Shipped single-level engine on the same ratings, ignoring cluster.
sl <- intraclass::icc(
  d0,
  score = score,
  subject = subject,
  rater = rater,
  unit = "single",
  engine = "lavaan"
)$estimates
red_sem <- iccs_from_components(sem0$components, k = 4)
sl_agr <- sl$estimate[sl$index == "ICC(A,1)"]
sl_con <- sl$estimate[sl$index == "ICC(C,1)"]
# Guard the extraction: numeric(0) here would make the reduction pins below
# evaluate over logical(0) and pass vacuously (review F2) -- fail loudly
# instead if icc()'s estimates-table labels ever change.
stopifnot(length(sl_agr) == 1, length(sl_con) == 1)
checkpoint$reduction <- list(
  sem_components = sem0$components,
  sem_s_agr_1 = unname(red_sem["s_agr_1"]),
  sem_s_con_1 = unname(red_sem["s_con_1"]),
  single_level_agr = sl_agr,
  single_level_con = sl_con
)
cat("Reduction: two-level subject-level vs shipped single-level lavaan:\n")
print(checkpoint$reduction[-1])

# --- Stage 2: known-population recovery sweep (GP6 cluster axis) -------------

# Cells A-C sweep the cluster axis (GP6) for the four cluster/subject-governed
# components. Cell D sweeps k — the axis that actually governs sigma^2_r
# (df = k - 1): the rater component's bias can only be tested tightly where k
# is large (milestone Decisions, 2026-07-16 GP5 correction).
cells <- list(
  A = list(n_c = 20, n_s = 10, k = 3, n_rep = 100),
  B = list(n_c = 40, n_s = 10, k = 5, n_rep = 100),
  C = list(n_c = 200, n_s = 10, k = 5, n_rep = 100),
  D = list(n_c = 30, n_s = 8, k = 25, n_rep = 150)
)
pop2 <- c(vc = 0.4, vsc = 1, vr = 0.16, vcr = 0.16, vres = 0.5)
n_parity <- 25

recover_cell <- function(cell, cell_name) {
  n_rep <- cell$n_rep
  comp_mat <- matrix(NA_real_, n_rep, 5)
  colnames(comp_mat) <- c(
    "cluster",
    "subject",
    "rater",
    "cluster_rater",
    "residual"
  )
  parity <- matrix(NA_real_, n_parity, 5)
  colnames(parity) <- colnames(comp_mat)
  n_fail <- 0L
  n_heywood <- 0L
  for (r in seq_len(n_rep)) {
    d <- sim_multilevel(
      cell$n_c,
      cell$n_s,
      cell$k,
      pop2["vc"],
      pop2["vsc"],
      pop2["vr"],
      pop2["vcr"],
      pop2["vres"],
      seed = 53000 + 1000 * match(cell_name, names(cells)) + r
    )
    sem <- fit_ml_sem(to_wide(d), cell$k)
    if (is.null(sem)) {
      n_fail <- n_fail + 1L
      next
    }
    if (any(sem$components[c("cluster", "cluster_rater")] < 0)) {
      n_heywood <- n_heywood + 1L
    }
    comp_mat[r, ] <- sem$components
    if (r <= n_parity) {
      parity[r, ] <- sem$components - fit_reml(d)
    }
  }
  list(
    mean_est = colMeans(comp_mat, na.rm = TRUE),
    rel_bias = colMeans(comp_mat, na.rm = TRUE) /
      c(pop2["vc"], pop2["vsc"], pop2["vr"], pop2["vcr"], pop2["vres"]) -
      1,
    mean_abs_parity = colMeans(abs(parity), na.rm = TRUE),
    # Signed mean parity: the rater slot's SEM-above-REML offset is the
    # structural tau^2 inflation (see the tau2 law at the pins), so the sign
    # carries the information the absolute value hides.
    mean_parity = colMeans(parity, na.rm = TRUE),
    n_fail = n_fail,
    n_heywood = n_heywood
  )
}

for (nm in names(cells)) {
  cat(sprintf(
    "Stage 2 cell %s (n_c=%d, n_s=%d, k=%d)...\n",
    nm,
    cells[[nm]]$n_c,
    cells[[nm]]$n_s,
    cells[[nm]]$k
  ))
  checkpoint[[paste0("cell_", nm)]] <- recover_cell(cells[[nm]], nm)
  print(lapply(checkpoint[[paste0("cell_", nm)]], function(x) round(x, 4)))
}

# --- Stage 2b: MC-interval feasibility probe on the Stage-1 fit --------------

fit <- sem1$fit
co <- lavaan::coef(fit)
cn <- names(co)
k <- 5
idx <- c(
  which(cn == "svw")[1],
  which(cn == "evw")[1],
  which(cn == "svb")[1],
  which(cn == "evb")[1],
  sem1$nu_i
)
est <- co[idx]
vc_raw <- as.matrix(lavaan::vcov(fit))[idx, idx]
# log-SD scale for the four variances (boundary-aware draws back-transform
# strictly positive, PRINCIPLES.md #3), identity for the intercepts.
jac <- diag(c(
  1 / (2 * est[1]),
  1 / (2 * est[2]),
  1 / (2 * est[3]),
  1 / (2 * est[4]),
  rep(1, k)
))
vc_log <- jac %*% vc_raw %*% t(jac)
est_log <- c(log(sqrt(est[1:4])), est[-(1:4)])
set.seed(20260718)
ch <- chol(vc_log)
draws <- matrix(stats::rnorm(4000 * length(est_log)), 4000) %*%
  ch +
  matrix(est_log, 4000, length(est_log), byrow = TRUE)
center <- diag(k) - matrix(1 / k, k, k)
per_draw <- apply(draws, 1, function(p) {
  compd <- c(
    cluster = exp(2 * p[3]),
    subject = exp(2 * p[1]),
    rater = as.numeric(t(p[5:9]) %*% center %*% p[5:9]) / (k - 1),
    cluster_rater = exp(2 * p[4]),
    residual = exp(2 * p[2])
  )
  iccs_from_components(compd, k)[c("s_agr_1", "c_agr_1")]
})
mc_ci <- apply(per_draw, 1, stats::quantile, probs = c(0.025, 0.975))
checkpoint$mc_probe <- list(
  ci = mc_ci,
  point = icc_sem1[c("s_agr_1", "c_agr_1")],
  finite = all(is.finite(per_draw)),
  contained = all(
    icc_sem1[c("s_agr_1", "c_agr_1")] >= mc_ci["2.5%", ] &
      icc_sem1[c("s_agr_1", "c_agr_1")] <= mc_ci["97.5%", ]
  )
)
cat("MC probe (95% intervals, both levels):\n")
print(round(mc_ci, 4))

# --- Checkpoint BEFORE pins (M47/M52 lessons) --------------------------------

saveRDS(checkpoint, ckpt_path)
cat("Checkpoint saved:", ckpt_path, "\n")

# --- Pins (tolerances per the synthesis note; GP5: never widened post hoc) ---

# Stage 1: within components tight; between components budget ML-vs-REML.
stopifnot(
  abs(sem1$components["subject"] - reml1["subject"]) / reml1["subject"] < 0.02,
  abs(sem1$components["residual"] - reml1["residual"]) / reml1["residual"] <
    0.02,
  abs(sem1$components["cluster"] - reml1["cluster"]) / reml1["cluster"] < 0.06,
  abs(sem1$components["cluster_rater"] - reml1["cluster_rater"]) /
    reml1["cluster_rater"] <
    0.06,
  abs(sem1$components["rater"] - reml1["rater"]) < 0.05
)
# Stage 1 ICCs: consistency tight, agreement looser (M49 index-class split).
stopifnot(
  all(
    abs(
      icc_sem1[c("s_con_1", "s_con_k")] -
        icc_reml1[c("s_con_1", "s_con_k")]
    ) <
      0.01
  ),
  all(abs(icc_sem1 - icc_reml1) < 0.03)
)
# Reduction: subject-level two-level ICCs ~= shipped single-level engine.
stopifnot(
  abs(
    checkpoint$reduction$sem_s_agr_1 - checkpoint$reduction$single_level_agr
  ) <
    0.02,
  abs(
    checkpoint$reduction$sem_s_con_1 - checkpoint$reduction$single_level_con
  ) <
    0.02
)
# Stage 2 pins are split per the milestone GP5 correction (2026-07-16) and
# re-centred per review finding F1 (2026-07-16): the four cluster/subject-
# governed components are pinned on the cluster axis (.10 small cells, .05 at
# N_c = 200). The rater slot's raw quadratic-form estimator carries a
# DETERMINISTIC structural inflation
#     E[nu' C nu / (k - 1)] = sigma^2_r + tau^2,
#     tau^2 = (sigma^2_cr + sigma^2_res / n_s) / N_c
# — the multilevel generalization of the single-level raw estimator's omitted
# "- sigma^2_res/n" sampling-variance term (R/engine-lavaan.R header; raw by
# design, ADR-014). REML does not carry it, so the signed SEM-minus-REML rater
# parity IS tau^2 (matches to <= 1e-4 across the B/C/D geometries). sigma^2_r
# is therefore pinned by (a) the tau^2 law itself — signed mean parity within
# .005 of the predicted tau^2, an invariant-type check — and (b) a bias
# tolerance CENTRED ON the predicted inflation tau^2/sigma^2_r at its own
# noise floor, 3 * sqrt(2/(k-1)) / sqrt(n_rep), tight on its own axis
# (cell D).
cs_comp <- c("cluster", "subject", "cluster_rater", "residual")
rater_tol <- function(cell) 3 * sqrt(2 / (cell$k - 1)) / sqrt(cell$n_rep)
tau2 <- function(cell) {
  unname((pop2["vcr"] + pop2["vres"] / cell$n_s) / cell$n_c)
}
for (nm in c("A", "B")) {
  stopifnot(all(
    abs(checkpoint[[paste0("cell_", nm)]]$rel_bias[cs_comp]) < 0.10
  ))
}
stopifnot(
  all(abs(checkpoint$cell_C$rel_bias[cs_comp]) < 0.05),
  all(abs(checkpoint$cell_D$rel_bias[cs_comp]) < 0.10)
)
for (nm in names(cells)) {
  ck <- checkpoint[[paste0("cell_", nm)]]
  infl <- tau2(cells[[nm]]) / unname(pop2["vr"])
  stopifnot(
    abs(ck$rel_bias["rater"] - infl) < rater_tol(cells[[nm]]),
    abs(ck$mean_parity["rater"] - tau2(cells[[nm]])) < 0.005,
    ck$n_fail == 0
  )
}
stopifnot(
  all(
    checkpoint$cell_C$mean_abs_parity <=
      checkpoint$cell_A$mean_abs_parity + 1e-6
  )
)
# MC probe: finite draws, both intervals contain their point estimates.
stopifnot(checkpoint$mc_probe$finite, checkpoint$mc_probe$contained)

cat("PILOT PASS: all pins hold.\n")
