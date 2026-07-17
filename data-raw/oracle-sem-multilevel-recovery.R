# Oracle O-SEM-ML/recovery: known-population recovery of the multilevel SEM
# (lavaan) Design-1 five-component decomposition (M54, D-005) ------------------
#
# Provenance for tests/testthat/test-icc-lavaan-multilevel.R (PRINCIPLES.md #1,
# GP5, GP6, GP7). Reproducible, seeded, standalone
# (Rscript data-raw/oracle-sem-multilevel-recovery.R); writes the committed
# summary fixture tests/testthat/fixtures/sem-multilevel-recovery-oracle.rds the
# recovery test asserts against. Frozen at M60 (was 100 live lavaan two-level
# refits, ~90-110s and the test-suite tail); the estimator's discriminating
# power is preserved by the LIVE guards O-SEM-ML/parity (Cell B) and the
# tau^2-invariant guard (Cell D) in the same test file.
#
# Estimand + faithfulness: the two-level CFA route to ten Hove, Jorgensen & van
# der Ark (2022) Design-1 (Eqs. 6-7/12-13), an IP1-fenced parameterization
# established numerically by the M53 pilot (D-005;
# cairn/references/sem-multilevel-pilot.md; data-raw/pilot-sem-multilevel.R).
#
# Two cells, each pinning the components its geometry resolves:
#   * Cell B (N_c=40, n_s=10, k=5): the four cluster/subject-governed components
#     recovered unbiased; noise floor 3*sqrt(2/39)/sqrt(60) ~= .088 < .10.
#   * Cell D (N_c=30, n_s=8, k=25): the ONLY cell that pins sigma^2_r tightly
#     (its noise is governed by df=k-1). Rater rel-bias centred on the predicted
#     structural inflation tau^2/sigma^2_r; the tau^2 law itself pinned as an
#     invariant via same-data SEM-minus-REML differencing (cancels shared noise).

suppressPackageStartupMessages({
  stopifnot(
    requireNamespace("glmmTMB", quietly = TRUE),
    requireNamespace("lavaan", quietly = TRUE)
  )
})
devtools::load_all(quiet = TRUE)

# --- self-contained references (mirror the test-file helpers) ----------------

# Balanced Design-1 generator with known population components.
sim_ml <- function(nc, ns, k, vc, vsc, vr, vcr, vres, seed) {
  set.seed(seed)
  cl <- stats::rnorm(nc, 0, sqrt(vc))
  rt <- stats::rnorm(k, 0, sqrt(vr))
  d <- expand.grid(
    subj = seq_len(ns),
    cluster = seq_len(nc),
    rater = seq_len(k)
  )
  scv <- stats::rnorm(nc * ns, 0, sqrt(vsc))
  d$sc <- scv[(d$cluster - 1) * ns + d$subj]
  crv <- stats::rnorm(nc * k, 0, sqrt(vcr))
  d$cr <- crv[(d$cluster - 1) * k + d$rater]
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

# REML five-component reference fit (the package's spine, via glmmTMB).
reml_components <- function(d) {
  fit <- suppressWarnings(glmmTMB::glmmTMB(
    score ~
      1 +
      (1 | cluster) +
      (1 | cluster:subject) +
      (1 | rater) +
      (1 | cluster:rater),
    data = d,
    REML = TRUE
  ))
  vc <- glmmTMB::VarCorr(fit)$cond
  c(
    cluster = unname(attr(vc$cluster, "stddev"))^2,
    subject = unname(attr(vc$`cluster:subject`, "stddev"))^2,
    rater = unname(attr(vc$rater, "stddev"))^2,
    cluster_rater = unname(attr(vc$`cluster:rater`, "stddev"))^2,
    residual = attr(vc, "sc")^2
  )
}

pop <- c(vc = 0.4, vsc = 1, vr = 0.16, vcr = 0.16, vres = 0.5)
mc_samples <- 500L # point-component floor: the recovery cells assert components only.

# --- Cell B: four-component unbiasedness (60 refits) --------------------------
n_rep_b <- 60L
comp_b <- matrix(NA_real_, n_rep_b, 5)
colnames(comp_b) <- c(
  "cluster",
  "subject",
  "rater",
  "cluster_rater",
  "residual"
)
for (r in seq_len(n_rep_b)) {
  d <- sim_ml(
    40,
    10,
    5,
    pop["vc"],
    pop["vsc"],
    pop["vr"],
    pop["vcr"],
    pop["vres"],
    seed = 54000 + r
  )
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    mc_samples = mc_samples,
    seed = 1
  )
  comp_b[r, ] <- unlist(fit$components)[colnames(comp_b)]
}
rel_bias_b <- colMeans(comp_b) /
  c(pop["vc"], pop["vsc"], pop["vr"], pop["vcr"], pop["vres"]) -
  1
names(rel_bias_b) <- colnames(comp_b)

# --- Cell D: tight-k rater recovery + tau^2 law (40 refits) -------------------
n_rep_d <- 40L
n_parity <- 20L
rater_d <- numeric(n_rep_d)
parity_d <- numeric(n_parity)
for (r in seq_len(n_rep_d)) {
  d <- sim_ml(
    30,
    8,
    25,
    pop["vc"],
    pop["vsc"],
    pop["vr"],
    pop["vcr"],
    pop["vres"],
    seed = 55000 + r
  )
  fit <- icc(
    d,
    score,
    subject,
    rater,
    cluster = cluster,
    engine = "lavaan",
    mc_samples = mc_samples,
    seed = 1
  )
  rater_d[r] <- fit$components$rater
  if (r <= n_parity) {
    parity_d[r] <- fit$components$rater - reml_components(d)[["rater"]]
  }
}

# Deterministic predicted values (pure functions of pop + Cell D geometry).
tau2_d <- unname((pop["vcr"] + pop["vres"] / 8) / 30)
infl_d <- tau2_d / unname(pop["vr"])
tol_d <- 3 * sqrt(2 / 24) / sqrt(n_rep_d)

out <- list(
  cell_b = list(rel_bias = rel_bias_b),
  cell_d = list(
    mean_rater = mean(rater_d),
    mean_parity = mean(parity_d),
    tau2 = tau2_d,
    infl = infl_d,
    tol = tol_d
  ),
  meta = list(
    pop = pop,
    geom_b = c(N_c = 40L, n_s = 10L, k = 5L),
    geom_d = c(N_c = 30L, n_s = 8L, k = 25L),
    n_rep_b = n_rep_b,
    n_rep_d = n_rep_d,
    n_parity = n_parity,
    mc_samples = mc_samples,
    seed_base_b = 54000L,
    seed_base_d = 55000L,
    generated = as.character(Sys.Date()),
    r_version = R.version.string,
    lavaan_version = as.character(utils::packageVersion("lavaan")),
    glmmTMB_version = as.character(utils::packageVersion("glmmTMB"))
  )
)

saveRDS(out, "tests/testthat/fixtures/sem-multilevel-recovery-oracle.rds")
cat("\n[saved] tests/testthat/fixtures/sem-multilevel-recovery-oracle.rds\n")
cat(sprintf(
  "Cell B max |rel_bias| (cluster/subject/cluster_rater/residual): %.4f\n",
  max(abs(rel_bias_b[c("cluster", "subject", "cluster_rater", "residual")]))
))
cat(sprintf(
  "Cell D rater rel-bias %.4f (predicted infl %.4f, tol %.4f) | parity %.5f (tau^2 %.5f)\n",
  mean(rater_d) / pop[["vr"]] - 1,
  infl_d,
  tol_d,
  mean(parity_d),
  tau2_d
))
