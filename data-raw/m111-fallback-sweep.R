# M111 T3/T4 — fallback-on-abort composite sweep for the one-way random ICC.
#
# Measures the COMPOSITE procedure — the MC default where it converges, a
# classical closed-form interval (SEARLE exact-F / Burch 2011 REML, the M76
# prototypes) where the MC default aborts classed intraclass_singular_fit —
# on the pre-registered 64-cell grid. NON-EXPORTED research harness (data-raw/,
# not R/); GO/NO-GO assessment only, ships no exported code (D-006 shape).
#
# The full GO/NO-GO criterion is PRE-REGISTERED (frozen, dated) in
# cairn/references/fallback-on-abort-comparison.md BEFORE this run (GP5). This
# script only measures; it applies no verdict. Computing the classical interval
# on an abort rep here is the D-018-licensed diagnostic use: nothing reaches a
# user, and the package's own abort behavior is untouched.
#
# Run in the background (measured 36 min at 4 workers on an M-series Mac;
# check for concurrent R sessions and live R.INSTALL processes first —
# M107/M109 lessons):
#   Rscript data-raw/m111-fallback-sweep.R
# Parallel over cells (parallel::mclapply, 4 workers — plan gate 2026-08-08;
# per-cell seed streams are independent, so results are worker-count-invariant).
# Each finished cell writes data-raw/m111-fallback-checkpoints/cell-NN.rds
# (uncommitted; a re-run resumes past completed cells); the final fixture is
# data-raw/m111-fallback-results.rds (raw per-rep rows + per-cell summary +
# platform metadata).

suppressMessages(devtools::load_all(quiet = TRUE))
# Defines searle_f_ci_balanced() and burch_reml_ci_balanced(); sourcing skips
# the file's `if (sys.nframe() == 0L)` oracle block.
source("data-raw/m76-classical-oneway-prototype.R")

out_path <- "data-raw/m111-fallback-results.rds"
ckpt_dir <- "data-raw/m111-fallback-checkpoints"
n_workers <- 4L

# ---- data generation ---------------------------------------------------------
# Balanced one-way: subject effect a_i ~ dist (variance rho), error e_ij ~
# N(0, 1-rho); ICC = rho for every distribution. The non-normal arms shape the
# CLUSTER effect (errors stay normal — GP6, the M76 convention), located and
# scaled to mean 0 / variance rho per burch2011 §3 (p. 1022):
#   t5     — scaled t(5), kurtosis 6.0 (Table 2)
#   uniform — scaled Uniform(0,1), kurtosis -1.2 (platykurtic)
#   chisq1 — scaled chi-square(1), kurtosis 12.0 (skewed; a_i = sd_a*(x-1)/sqrt(2))
gen_oneway <- function(k, n, rho, dist, seed) {
  set.seed(seed)
  sd_a <- sqrt(rho)
  sd_e <- sqrt(1 - rho)
  a <- switch(
    dist,
    gaussian = stats::rnorm(k, 0, sd_a),
    t5 = stats::rt(k, df = 5) * sd_a / sqrt(5 / 3),
    uniform = (stats::runif(k) - 0.5) * sd_a / sqrt(1 / 12),
    chisq1 = (stats::rchisq(k, df = 1) - 1) * sd_a / sqrt(2),
    stop("unknown dist: ", dist)
  )
  vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)
  data.frame(
    subject = rep(seq_len(k), each = n),
    rater = rep(seq_len(n), times = k),
    score = vals,
    y = vals # alias consumed by the prototype functions
  )
}

# ---- MC default extractor ----------------------------------------------------
# The abort caught here is the classed condition the fallback exists to
# replace; anything else propagates (never silently coerced).
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
      c(lower = i1$conf.low, upper = i1$conf.high)
    },
    intraclass_singular_fit = function(e) c(lower = NA_real_, upper = NA_real_)
  )
}

# ---- pre-registered grid (64 cells) -----------------------------------------
# rho in {0.05, 0.10, 0.30, 0.60} x (k,n) in {(10,5),(30,5),(50,5),(10,2)}
# x {gaussian, t5, uniform, chisq1}; n_rep = 2000 per cell.
build_cells <- function(n_rep = 2000L) {
  kn_levels <- list(
    c(k = 10, n = 5),
    c(k = 30, n = 5),
    c(k = 50, n = 5),
    c(k = 10, n = 2)
  )
  cells <- list()
  cid <- 0L
  for (rho in c(0.05, 0.10, 0.30, 0.60)) {
    for (kn in kn_levels) {
      for (dist in c("gaussian", "t5", "uniform", "chisq1")) {
        cid <- cid + 1L
        cells[[cid]] <- list(
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
  cells
}

# ---- per-rep measurement -----------------------------------------------------
# One row per rep x method. mc rows carry the abort indicator; searle/burch
# rows are the always-finite classical legs on the SAME dataset. Composite
# arms are derived at summary time (mc where it converged, the classical leg
# where it aborted), so the raw fixture preserves every leg separately.
one_rep <- function(cell, rep) {
  base <- cell$id * 1000000L + rep
  d <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed = base)
  legs <- list(
    mc = mc_ci(d, seed = base + 100000L),
    searle = searle_f_ci_balanced(d),
    burch = burch_reml_ci_balanced(d)
  )
  rows <- lapply(names(legs), function(m) {
    ci <- legs[[m]]
    lo <- ci[["lower"]]
    hi <- ci[["upper"]]
    aborted <- !is.finite(lo) || !is.finite(hi)
    data.frame(
      cell = cell$id,
      rho = cell$rho,
      k = cell$k,
      n = cell$n,
      dist = cell$dist,
      rep = rep,
      method = m,
      lower = lo,
      upper = hi,
      aborted = aborted,
      covered = !aborted && lo <= cell$rho && cell$rho <= hi,
      width = if (aborted) NA_real_ else hi - lo,
      lo_miss = !aborted && cell$rho < lo,
      hi_miss = !aborted && cell$rho > hi,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

# ---- composite derivation + summary -----------------------------------------
# Wide per-rep table: one row per rep carrying every leg, plus the two derived
# composite arms (fallback fires exactly where the mc leg aborted).
widen_reps <- function(raw) {
  mc <- raw[raw$method == "mc", ]
  se <- raw[raw$method == "searle", ]
  bu <- raw[raw$method == "burch", ]
  key <- function(g) paste(g$cell, g$rep)
  stopifnot(identical(key(mc), key(se)), identical(key(mc), key(bu)))
  data.frame(
    cell = mc$cell,
    rho = mc$rho,
    k = mc$k,
    n = mc$n,
    dist = mc$dist,
    rep = mc$rep,
    mc_aborted = mc$aborted,
    mc_covered = mc$covered,
    mc_width = mc$width,
    searle_covered = se$covered,
    searle_width = se$width,
    searle_lo_miss = se$lo_miss,
    searle_hi_miss = se$hi_miss,
    burch_covered = bu$covered,
    burch_width = bu$width,
    burch_lo_miss = bu$lo_miss,
    burch_hi_miss = bu$hi_miss,
    comp_searle_covered = ifelse(mc$aborted, se$covered, mc$covered),
    comp_searle_lo_miss = ifelse(mc$aborted, se$lo_miss, mc$lo_miss),
    comp_searle_hi_miss = ifelse(mc$aborted, se$hi_miss, mc$hi_miss),
    comp_burch_covered = ifelse(mc$aborted, bu$covered, mc$covered),
    comp_burch_lo_miss = ifelse(mc$aborted, bu$lo_miss, mc$lo_miss),
    comp_burch_hi_miss = ifelse(mc$aborted, bu$hi_miss, mc$hi_miss),
    stringsAsFactors = FALSE
  )
}

summarize_sweep <- function(wide) {
  agg <- do.call(
    rbind,
    lapply(split(wide, wide$cell), function(g) {
      ab <- g[g$mc_aborted, ]
      ok <- g[!g$mc_aborted, ]
      data.frame(
        cell = g$cell[1],
        rho = g$rho[1],
        k = g$k[1],
        n = g$n[1],
        dist = g$dist[1],
        n_rep = nrow(g),
        n_abort = nrow(ab),
        mc_abort_rate = mean(g$mc_aborted),
        comp_searle_coverage = mean(g$comp_searle_covered),
        comp_searle_lo_miss = mean(g$comp_searle_lo_miss),
        comp_searle_hi_miss = mean(g$comp_searle_hi_miss),
        comp_burch_coverage = mean(g$comp_burch_covered),
        comp_burch_lo_miss = mean(g$comp_burch_lo_miss),
        comp_burch_hi_miss = mean(g$comp_burch_hi_miss),
        cond_searle_coverage = if (nrow(ab)) {
          mean(ab$searle_covered)
        } else {
          NA_real_
        },
        cond_burch_coverage = if (nrow(ab)) {
          mean(ab$burch_covered)
        } else {
          NA_real_
        },
        cond_searle_med_width = if (nrow(ab)) {
          stats::median(ab$searle_width)
        } else {
          NA_real_
        },
        cond_burch_med_width = if (nrow(ab)) {
          stats::median(ab$burch_width)
        } else {
          NA_real_
        },
        mc_med_width_ok = if (nrow(ok)) {
          stats::median(ok$mc_width)
        } else {
          NA_real_
        },
        stringsAsFactors = FALSE
      )
    })
  )
  rownames(agg) <- NULL
  agg
}

# ---- sweep (parallel over cells, per-cell checkpoints) -----------------------
run_cell <- function(cell) {
  ckpt <- file.path(ckpt_dir, sprintf("cell-%02d.rds", cell$id))
  if (file.exists(ckpt)) {
    return(readRDS(ckpt))
  }
  t0 <- Sys.time()
  cell_rows <- vector("list", cell$n_rep)
  for (rep in seq_len(cell$n_rep)) {
    cell_rows[[rep]] <- one_rep(cell, rep)
  }
  res <- do.call(rbind, cell_rows)
  saveRDS(res, ckpt)
  el <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
  cat(sprintf(
    "cell %2d/64 done: rho=%.2f k=%d n=%d %-8s (%.1f min)\n",
    cell$id,
    cell$rho,
    cell$k,
    cell$n,
    cell$dist,
    el
  ))
  res
}

if (sys.nframe() == 0L) {
  dir.create(ckpt_dir, showWarnings = FALSE)
  cells <- build_cells()
  results <- parallel::mclapply(cells, run_cell, mc.cores = n_workers)
  failed <- vapply(results, inherits, logical(1), what = "try-error")
  stopifnot(!any(failed))
  raw <- do.call(rbind, results)
  wide <- widen_reps(raw)
  agg <- summarize_sweep(wide)
  saveRDS(
    list(
      raw = raw,
      wide = wide,
      summary = agg,
      meta = list(
        generated = Sys.time(),
        platform = list(
          r_version = R.version.string,
          sysname = Sys.info()[["sysname"]],
          machine = Sys.info()[["machine"]]
        ),
        n_workers = n_workers,
        criterion = "pre-registered in cairn/references/fallback-on-abort-comparison.md",
        note = paste(
          "GO/NO-GO assessment only; no exported code (D-006 shape).",
          "Abort split is platform-dependent (M84/M105 lesson): this fixture",
          "pins the composite on the platform above."
        )
      )
    ),
    out_path
  )
  cat("\nSweep complete. Summary:\n")
  print(agg[order(agg$cell), ], row.names = FALSE)
}
