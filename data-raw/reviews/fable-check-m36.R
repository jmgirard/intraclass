# Fable M36 review harness — does ragged fixed-nested boundary coverage decay with
# CLUSTER COUNT (the M28 incidental-parameters pathology under the ragged 2b)? (Q2)
#
# The shipped M36 O-IFNML grid used only ~6 clusters. M28 found the PRE-fix interval
# looked fine at few clusters (.95 at C_n=5) but collapsed as clusters accrued
# (.86/.57 at C_n=20/80). This harness sweeps C_n through the SHIPPED icc() path on
# RAGGED data, at the boundary (theta^2=0) and interior, for equal- and unequal-k_c.
# Coverage is of the FIXED population ICC(A,1) (raters fixed across reps; subjects,
# residuals, missingness resampled). Fable: extend n_rep to >= 240, add k_c regimes,
# and (Q1) compare the 2b interval to a recompute-per-refit bootstrap.
#
# Run: Rscript data-raw/reviews/fable-check-m36.R   (n_rep below; scale up for a verdict)

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))

VSC <- 1.0
VRES <- 0.5
N_REP <- 120L # preliminary; raise to >= 240 for a committed verdict
MC_N <- 3000L

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

one_cell <- function(kc_of_c, cn, ns, theta2, p_keep, base_seed) {
  kc_vec <- rep_len(kc_of_c, cn) # recycle the k_c pattern to `cn` clusters
  pop <- VSC / (VSC + theta2 + VRES)
  hit <- 0L
  nfit <- 0L
  for (r in seq_len(N_REP)) {
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
      next
    }
    row <- x$estimates[
      x$estimates$index == "ICC(A,1)" & x$estimates$level == "subject",
    ]
    nfit <- nfit + 1L
    if (pop >= row$conf.low && pop <= row$conf.high) hit <- hit + 1L
  }
  data.frame(
    cn = cn,
    theta2 = theta2,
    cell = if (theta2 == 0) "boundary" else "interior",
    coverage = hit / nfit,
    n_fit = nfit
  )
}

# equal k_c = 4, ns = 4 (so per-cluster info is modest -> the M28 regime), sweep C_n
res <- list()
i <- 0L
for (cn in c(5L, 20L, 80L)) {
  for (theta2 in c(0, 0.5)) {
    i <- i + 1L
    r <- one_cell(4L, cn, 4L, theta2, 0.8, base_seed = 360000L + i * 1000L)
    res[[i]] <- r
    cat(sprintf(
      "C_n=%2d  theta2=%.2f (%-8s)  coverage=%.3f (n=%d)\n",
      cn,
      theta2,
      r$cell,
      r$coverage,
      r$n_fit
    ))
    flush.console()
  }
}
out <- do.call(rbind, res)
cat("\n=== boundary coverage vs cluster count (the Q2 check) ===\n")
print(out[out$cell == "boundary", c("cn", "coverage", "n_fit")])
