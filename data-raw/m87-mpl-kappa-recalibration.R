# data-raw/m87-mpl-kappa-recalibration.R
#
# M87 T2: recalibrate the modified-profile-likelihood correction constant kappa_m
# over the EXTENDED range rho in [0.05, 0.9] for each (R, S) geometry used by the
# M87 comparison sweep, using M86's validated calibration machinery
# (data-raw/m86-mpl-lib.R). xiao2013's published kappa_m are maxima over rho >= 0.6
# only (the rho_L = 0.6 fence, xiao2013.md) and are NOT transferable to the
# near-zero boundary this pass targets, so kappa_m must be regenerated here.
#
# NOT package code. A committed, seeded prototype for the M87 GO/NO-GO pass; no
# `R/` surface. Pre-registration: cairn/references/mpl-twoway-random-comparison.md.
#
# kappa_m = max{ kappa_corr(rho, delta) : rho in [0.05,0.9], delta in {0.5..16} }
# at the pass nominal (alpha = 0.05, two-sided). Because the MC grid-MAX is an
# upward-biased estimator of a maximum (max of noisy per-cell estimates), kappa_m
# is reported as kappa_corr evaluated at the identified grid ARGMAX corner with a
# larger n_mc (M86's bias correction). A coarse grid scan LOCATES the argmax; it
# is expected at the (rho_min, delta_U) corner (per M86) but VERIFIED here, since
# the sub-0.6 region carries no external oracle.
#
# Continuity anchor at the fence (AC2): for the two geometries that overlap M86's
# validated Table 3 set -- (3,10) and (3,50) -- kappa_corr(rho=0.6, delta=16) is
# recomputed at alpha = 0.10 (M86's only published anchor is the 90% two-sided
# table) and must match M86's validated values (0.32, 0.67) within +/- 0.10.
#
# Run (background; ~30-45 min):
#   Rscript data-raw/m87-mpl-kappa-recalibration.R
# Writes data-raw/m87-kappa-recalibration.rds (seeded; provenance in `meta`).

source("data-raw/m86-mpl-lib.R")

out_path <- "data-raw/m87-kappa-recalibration.rds"
seed <- 20260723L
alpha_pass <- 0.05 # 95% two-sided (the M87 nominal)
n_mc_scan <- 1500L # locate the argmax
n_mc_final <- 6000L # kappa_m = kappa_corr at the argmax corner (bias-corrected)
tol_fence <- 0.10 # AC2 continuity tolerance

# The four distinct (R, S) geometries in the frozen M87 cell grid (C1/C2 share
# (3,20); C3 (3,10); C4 (3,50); C5 (5,20)).
geometries <- list(
  c(n_r = 3L, n_s = 20L),
  c(n_r = 3L, n_s = 10L),
  c(n_r = 3L, n_s = 50L),
  c(n_r = 5L, n_s = 20L)
)

# Extended rho grid (spans the boundary the published kappa_m never saw) and the
# xiao2013 delta grid (Eq. 12-13: delta_j = 2^j, j = -1..4 -> {0.5,1,2,4,8,16}).
rho_grid <- c(0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90)
delta_grid <- 2^(-1:4)

# M86's validated published-region two-sided kappa_m (alpha = 0.10), for the
# fence-continuity anchor on the overlapping geometries.
m86_fence <- list("3-10" = 0.32, "3-50" = 0.67)

recalibrate_one <- function(n_r, n_s, seed_g) {
  set.seed(seed_g)
  grid <- expand.grid(rho = rho_grid, delta = delta_grid)
  grid$kappa_corr <- mapply(
    function(rho, delta) {
      mpl_kappa_corr(
        rho,
        delta,
        n_r,
        n_s,
        alpha = alpha_pass,
        side = "two",
        n_mc = n_mc_scan
      )
    },
    grid$rho,
    grid$delta
  )
  amax <- grid[which.max(grid$kappa_corr), c("rho", "delta")]
  # Bias-corrected kappa_m: kappa_corr at the argmax corner, larger n_mc.
  set.seed(seed_g + 1L)
  kappa_m <- mpl_kappa_corr(
    amax$rho,
    amax$delta,
    n_r,
    n_s,
    alpha = alpha_pass,
    side = "two",
    n_mc = n_mc_final
  )
  # For context: the published-region max (rho >= 0.6) from the SAME scan grid,
  # so the extended-vs-published inflation is visible.
  pub_region <- grid[grid$rho >= 0.6, ]
  kappa_m_pub_region <- max(pub_region$kappa_corr)
  list(
    n_r = n_r,
    n_s = n_s,
    grid = grid,
    argmax = amax,
    kappa_m = kappa_m,
    kappa_m_pubregion_scan = kappa_m_pub_region
  )
}

cat(sprintf(
  "== M87 T2 kappa_m recalibration over rho in [%.2f, %.2f], alpha = %.2f ==\n",
  min(rho_grid),
  max(rho_grid),
  alpha_pass
))

results <- list()
for (i in seq_along(geometries)) {
  g <- geometries[[i]]
  res <- recalibrate_one(g[["n_r"]], g[["n_s"]], seed_g = seed + 10L * i)
  results[[sprintf("%d-%d", g[["n_r"]], g[["n_s"]])]] <- res
  cat(sprintf(
    "  (R=%d,S=%d): kappa_m = %.3f at argmax (rho=%.2f, delta=%g); pub-region(>=.6) scan max = %.3f\n",
    res$n_r,
    res$n_s,
    res$kappa_m,
    res$argmax$rho,
    res$argmax$delta,
    res$kappa_m_pubregion_scan
  ))
  # Incremental checkpoint so an interrupted run keeps completed geometries.
  saveRDS(list(results = results, done = i, of = length(geometries)), out_path)
}

# --- Continuity anchor at the fence (AC2) ----------------------------------
cat(
  "\n== Fence continuity anchor: kappa_corr(rho=0.6, delta=16, alpha=0.10) vs M86 ==\n"
)
fence <- list()
for (key in names(m86_fence)) {
  gg <- as.integer(strsplit(key, "-", fixed = TRUE)[[1]])
  set.seed(seed + 500L + sum(gg))
  kc <- mpl_kappa_corr(
    0.6,
    16,
    gg[1],
    gg[2],
    alpha = 0.10,
    side = "two",
    n_mc = n_mc_final
  )
  pass <- abs(kc - m86_fence[[key]]) <= tol_fence
  fence[[key]] <- list(
    n_r = gg[1],
    n_s = gg[2],
    kappa_corr = kc,
    m86 = m86_fence[[key]],
    pass = pass
  )
  cat(sprintf(
    "  (R=%d,S=%d): kappa_corr = %.3f  (M86 = %.2f, |diff| = %.3f, tol %.2f)  %s\n",
    gg[1],
    gg[2],
    kc,
    m86_fence[[key]],
    abs(kc - m86_fence[[key]]),
    tol_fence,
    if (pass) "PASS" else "FAIL"
  ))
}
fence_all_pass <- all(vapply(fence, function(x) x$pass, logical(1)))

validation <- list(
  results = results,
  fence = fence,
  fence_all_pass = fence_all_pass,
  meta = list(
    source = "recalibration of xiao2013 kappa_m over extended rho, via data-raw/m86-mpl-lib.R",
    generator = "data-raw/m87-mpl-kappa-recalibration.R",
    alpha_pass = alpha_pass,
    rho_grid = rho_grid,
    delta_grid = delta_grid,
    n_mc_scan = n_mc_scan,
    n_mc_final = n_mc_final,
    seed = seed,
    date = "2026-07-23"
  )
)
saveRDS(validation, out_path)
cat(sprintf(
  "\nFence continuity (AC2): %s\nsaved %s\n",
  if (fence_all_pass) "ALL PASS" else "SOME FAIL",
  out_path
))
