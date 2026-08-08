# M114 T4 — held-out generalization battery for the warn-trigger assessment.
#
# 10 cells, ids 65–74, n_rep = 1000, per the frozen spec
# (cairn/references/mc-skew-warn-trigger.md § Held-out battery, committed
# BEFORE this script existed — GP5/GP6): lognormal + laplace (families off
# the M111 grid) and gaussian (protected-side generalization), at
# (k, n) ∈ {(20, 3), (50, 5)} — (20, 3) is off the M111 geometry set. Seeds
# id * 1000000L + rep (disjoint from M111 ids 1–64); MC leg seed
# base + 100000L — the M111 scheme. Appends per-rep rows (MC-leg coverage +
# trigger statistics) to data-raw/m114-warn-trigger-stats.tsv, after the
# derivation script has written the M111 half.
#
# NON-EXPORTED research harness; assessment only. M112-hardened idioms: the
# abort flag is set ONLY from the classed intraclass_singular_fit status
# (never finiteness), and mclapply results are checked for NULL/non-df slots
# (a killed worker yields NULL and rbind would silently drop it — M112
# lesson). No checkpoint cache: the run is ~minutes, and a cache keyed on
# anything less than the full cell spec is the M112-review staleness trap.
#
# Run (foreground, ~3–5 min at 4 workers; check for concurrent R sessions
# first — M107/M109 lessons):
#   Rscript data-raw/m114-heldout-sweep.R

suppressMessages(devtools::load_all(quiet = TRUE))
source("data-raw/m114-trigger-stats.R")

stats_path <- "data-raw/m114-warn-trigger-stats.tsv"
n_workers <- 4L

# ---- data generation ---------------------------------------------------------
# Cluster effect shaped, errors normal (the M76 convention the M111 grid
# follows); a_i located/scaled to mean 0, variance rho.
#   lognormal — LN(0, 0.5^2), centered and scaled (skewed, heavy right tail)
#   laplace   — difference of two exponentials (symmetric, excess kurtosis 3)
gen_heldout <- function(k, n, rho, dist, seed) {
  set.seed(seed)
  sd_a <- sqrt(rho)
  sd_e <- sqrt(1 - rho)
  a <- switch(
    dist,
    gaussian = stats::rnorm(k, 0, sd_a),
    lognormal = {
      x <- stats::rlnorm(k, meanlog = 0, sdlog = 0.5)
      mu <- exp(0.125) # E[LN(0, .25)] = exp(sdlog^2/2)
      sdx <- sqrt((exp(0.25) - 1) * exp(0.25))
      (x - mu) * sd_a / sdx
    },
    laplace = (stats::rexp(k) - stats::rexp(k)) * sd_a / sqrt(2),
    stop("unknown dist: ", dist)
  )
  vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)
  data.frame(
    subject = rep(seq_len(k), each = n),
    rater = rep(seq_len(n), times = k),
    score = vals
  )
}

# ---- MC default extractor (M111 shape; status-based abort, M112 T2) ---------
mc_ci <- function(d, seed) {
  tryCatch(
    {
      td <- generics::tidy(icc(
        d,
        score,
        subject,
        rater,
        model = "oneway",
        ci_method = "montecarlo",
        mc_samples = 10000L,
        seed = seed
      ))
      i1 <- td[td$index == "ICC(1)", ]
      list(status = "ok", lower = i1$conf.low, upper = i1$conf.high)
    },
    intraclass_singular_fit = function(e) {
      list(status = "abort", lower = NA_real_, upper = NA_real_)
    }
  )
}

# ---- frozen grid: ids 65–74 --------------------------------------------------
build_heldout_cells <- function(n_rep = 1000L) {
  kn_levels <- list(c(k = 20, n = 3), c(k = 50, n = 5))
  cells <- list()
  cid <- 64L
  for (dist in c("lognormal", "laplace")) {
    for (rho in c(0.30, 0.60)) {
      for (kn in kn_levels) {
        cid <- cid + 1L
        cells[[length(cells) + 1L]] <- list(
          id = cid,
          rho = rho,
          k = kn[["k"]],
          n = kn[["n"]],
          dist = dist,
          n_rep = n_rep
        )
      }
    }
  }
  for (kn in kn_levels) {
    cid <- cid + 1L
    cells[[length(cells) + 1L]] <- list(
      id = cid,
      rho = 0.30,
      k = kn[["k"]],
      n = kn[["n"]],
      dist = "gaussian",
      n_rep = n_rep
    )
  }
  stopifnot(vapply(cells, `[[`, integer(1), "id") == 65:74)
  cells
}

run_cell <- function(cell) {
  n_rep <- cell$n_rep
  kap_bc <- gam <- rep(NA_real_, n_rep)
  defined <- aborted <- covered <- logical(n_rep)
  for (r in seq_len(n_rep)) {
    base <- cell$id * 1000000L + r
    d <- gen_heldout(cell$k, cell$n, cell$rho, cell$dist, seed = base)
    mc <- mc_ci(d, seed = base + 100000L)
    ab <- identical(mc$status, "abort")
    if (!ab && (!is.finite(mc$lower) || !is.finite(mc$upper))) {
      stop(
        "mc leg returned a non-finite interval without signalling ",
        "intraclass_singular_fit (cell ",
        cell$id,
        ", rep ",
        r,
        ")"
      )
    }
    aborted[r] <- ab
    covered[r] <- !ab && mc$lower <= cell$rho && cell$rho <= mc$upper
    st <- trigger_stats(d, cell$k, cell$n)
    defined[r] <- st$defined
    kap_bc[r] <- st$kappa_bc
    gam[r] <- st$gamma
  }
  data.frame(
    cell = cell$id,
    rho = cell$rho,
    k = cell$k,
    n = cell$n,
    dist = cell$dist,
    rep = seq_len(n_rep),
    source = "heldout",
    mc_aborted = aborted,
    mc_covered = covered,
    stat_defined = defined,
    kappa_bc = kap_bc,
    gamma = gam,
    stringsAsFactors = FALSE
  )
}

cells <- build_heldout_cells()
results <- parallel::mclapply(cells, run_cell, mc.cores = n_workers)

# M112 lesson: a killed worker is a NULL slot, not a try-error; never rbind
# past it silently.
bad <- !vapply(results, is.data.frame, logical(1))
if (any(bad)) {
  stop(
    "cells returned no data frame (killed worker?): ",
    paste(vapply(cells[bad], `[[`, integer(1), "id"), collapse = ", ")
  )
}
heldout <- do.call(rbind, results)
stopifnot(nrow(heldout) == 10L * 1000L)

# ---- append to the derived table (m111 half must already exist) -------------
existing <- read.delim(stats_path, stringsAsFactors = FALSE)
stopifnot(
  identical(unique(existing$source), "m111"),
  nrow(existing) == 128000L
)
out <- heldout
out$rho <- sprintf("%.2f", out$rho)
out$kappa_bc <- stats_fmt(out$kappa_bc)
out$gamma <- stats_fmt(out$gamma)
# existing was read back (numerics reparsed); rewrite it from its committed
# bytes instead: append raw lines, never round-trip the m111 half.
con <- file(stats_path, open = "at")
writeLines(
  do.call(paste, c(unname(as.list(out)), sep = "\t")),
  con
)
close(con)
message("appended ", nrow(out), " heldout rows to ", stats_path)

# per-cell quick summary for the log
agg <- do.call(
  rbind,
  lapply(split(heldout, heldout$cell), function(g) {
    na <- !g$mc_aborted
    data.frame(
      cell = g$cell[1],
      dist = g$dist[1],
      rho = g$rho[1],
      k = g$k[1],
      n = g$n[1],
      abort_rate = mean(g$mc_aborted),
      nonabort_coverage = mean(g$mc_covered[na])
    )
  })
)
print(agg, row.names = FALSE)
