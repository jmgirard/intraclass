# Fable M36 review harness — does ragged fixed-nested boundary coverage decay with
# CLUSTER COUNT (the M28 incidental-parameters pathology under the ragged 2b)? (Q2)
#
# The shipped M36 O-IFNML grid used only ~6 clusters. M28 found the PRE-fix interval
# looked fine at few clusters (.95 at C_n=5) but collapsed as clusters accrued
# (.86/.57 at C_n=20/80). This harness sweeps C_n through the SHIPPED icc() path on
# RAGGED data, at the boundary (theta^2=0) and interior, for equal- and unequal-k_c.
# Coverage is of the FIXED population ICC(A,1) (raters fixed across reps; subjects,
# residuals, missingness resampled).
#
# FABLE-EXTENDED (review of 2026-07-11, fable-review-m36-incomplete-fixed-nested-
# response.md): n_rep raised 120 -> 500 (above the >= 240 verdict bar,
# [[ragged-coverage-nrep-240]]); four regimes x C_n in {5, 20, 80} x {boundary,
# interior}:
#   A equal-k4  n_s=4 p=0.8   — the preliminary sweep's regime, now at n_rep 500
#   B mixed-k   c(2,3,4,5) n_s=4 p=0.8 — unequal k_c incl. k_c=2 clusters (Q2's ask)
#   C equal-k4  n_s=4 p=0.65  — heavy missingness (ragged V_c stress, k_c erodes)
#   D mixed-k   n_s=3 p=0.8   — strongest incidental-parameters stress (b ~ 0.2);
#                               some reps abort (a k_c=2 cluster losing a rater is
#                               refused by design) — counted in n_fail, reported.
# Extra metrics per cell: mean point bias, mean interval width, one-sided miss split
# (miss_low = pop below the interval, the displacement signature), and containment
# of the point in its own CI (the M28 §3 pathology). Reps parallelized with mclapply
# (per-rep seeds -> schedule-independent reproducibility).
#
# Run: Rscript data-raw/reviews/fable-check-m36.R
# Writes: data-raw/reviews/fable-check-m36-results.rds

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))

VSC <- 1.0
VRES <- 0.5
N_REP <- 500L
MC_N <- 3000L
CORES <- max(1L, min(6L, parallel::detectCores() - 2L))

sim_ragged_d2_fixed <- function(kc_vec, ns, theta2, p_keep, seed) {
  set.seed(seed)
  rows <- list()
  for (c in seq_along(kc_vec)) {
    k <- kc_vec[c]
    base <- seq_len(k) - (k + 1) / 2
    v0 <- sum(base^2) / (k - 1)
    rmean <- if (theta2 == 0) rep(0, k) else base * sqrt(theta2 / v0)
    for (s in seq_len(ns)) {
      sc <- stats::rnorm(1, 0, sqrt(VSC))
      for (r in seq_len(k)) {
        if (stats::runif(1) > p_keep) {
          next
        }
        rows[[length(rows) + 1L]] <- data.frame(
          cluster = c,
          subject = paste(c, s, sep = "_"),
          rater = paste(c, r, sep = "_"),
          score = 10 + rmean[r] + sc + stats::rnorm(1, 0, sqrt(VRES))
        )
      }
    }
  }
  d <- do.call(rbind, rows)
  d$cluster <- factor(d$cluster)
  d$subject <- factor(d$subject)
  d$rater <- factor(d$rater)
  d[d$subject %in% names(which(table(d$subject) >= 2L)), , drop = FALSE]
}

one_rep <- function(r, kc_vec, ns, theta2, p_keep, base_seed, pop) {
  d <- sim_ragged_d2_fixed(kc_vec, ns, theta2, p_keep, base_seed + r)
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
      mc_samples = MC_N
    )),
    error = function(e) NULL
  )
  if (is.null(x)) {
    return(NULL)
  }
  row <- x$estimates[
    x$estimates$index == "ICC(A,1)" & x$estimates$level == "subject",
  ]
  c(
    hit = as.integer(pop >= row$conf.low && pop <= row$conf.high),
    miss_low = as.integer(pop < row$conf.low),
    miss_high = as.integer(pop > row$conf.high),
    bias = row$estimate - pop,
    width = row$conf.high - row$conf.low,
    contain = as.integer(
      row$estimate >= row$conf.low && row$estimate <= row$conf.high
    )
  )
}

one_cell <- function(regime, kc_of_c, cn, ns, theta2, p_keep, base_seed) {
  kc_vec <- rep_len(kc_of_c, cn) # recycle the k_c pattern to `cn` clusters
  pop <- VSC / (VSC + theta2 + VRES)
  reps <- parallel::mclapply(
    seq_len(N_REP),
    one_rep,
    kc_vec = kc_vec,
    ns = ns,
    theta2 = theta2,
    p_keep = p_keep,
    base_seed = base_seed,
    pop = pop,
    mc.cores = CORES
  )
  ok <- !vapply(reps, is.null, logical(1))
  m <- do.call(rbind, reps[ok])
  data.frame(
    regime = regime,
    kc = paste(kc_of_c, collapse = ","),
    n_s = ns,
    p_keep = p_keep,
    cn = cn,
    theta2 = theta2,
    cell = if (theta2 == 0) "boundary" else "interior",
    coverage = mean(m[, "hit"]),
    miss_low = mean(m[, "miss_low"]),
    miss_high = mean(m[, "miss_high"]),
    mean_bias = mean(m[, "bias"]),
    mean_width = mean(m[, "width"]),
    containment = mean(m[, "contain"]),
    n_fit = sum(ok),
    n_fail = sum(!ok)
  )
}

regimes <- list(
  list(regime = "A equal-k4", kc = 4L, ns = 4L, p = 0.8),
  list(regime = "B mixed-k", kc = c(2L, 3L, 4L, 5L), ns = 4L, p = 0.8),
  list(regime = "C equal-k4 heavy-miss", kc = 4L, ns = 4L, p = 0.65),
  list(regime = "D mixed-k ns3", kc = c(2L, 3L, 4L, 5L), ns = 3L, p = 0.8)
)

res <- list()
i <- 0L
for (rg in regimes) {
  for (cn in c(5L, 20L, 80L)) {
    for (theta2 in c(0, 0.5)) {
      i <- i + 1L
      r <- one_cell(
        rg$regime,
        rg$kc,
        cn,
        rg$ns,
        theta2,
        rg$p,
        base_seed = 360000L + i * 1000L
      )
      res[[i]] <- r
      cat(sprintf(
        "%-22s C_n=%2d theta2=%.2f (%-8s) cover=%.3f (lo=%.3f hi=%.3f) bias=%+.4f width=%.3f contain=%.3f n=%d fail=%d\n",
        rg$regime,
        cn,
        theta2,
        r$cell,
        r$coverage,
        r$miss_low,
        r$miss_high,
        r$mean_bias,
        r$mean_width,
        r$containment,
        r$n_fit,
        r$n_fail
      ))
      flush.console()
      out <- do.call(rbind, res)
      out$n_rep <- N_REP
      out$mc_n <- MC_N
      saveRDS(out, "data-raw/reviews/fable-check-m36-results.rds")
    }
  }
}

cat("\n=== boundary coverage vs cluster count (the Q2 check) ===\n")
print(out[
  out$cell == "boundary",
  c("regime", "cn", "coverage", "miss_low", "miss_high", "n_fit", "n_fail")
])
cat("\n=== interior ===\n")
print(out[
  out$cell == "interior",
  c("regime", "cn", "coverage", "miss_low", "miss_high", "mean_bias", "n_fit")
])
