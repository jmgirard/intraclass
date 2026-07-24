# data-raw/m87-mpl-comparison-sweep.R
#
# M87 T3: paired coverage/width comparison sweep for the two-way random
# ICC(A,1). On the SAME seeded datasets per cell, runs four interval methods:
#
#   - MPL  (modified profile likelihood, kappa = kappa_m recalibrated over the
#           extended range rho in [0.05,0.9] by data-raw/m87-mpl-kappa-recalibration.R
#           -> data-raw/m87-kappa-recalibration.rds) -- the CANDIDATE,
#   - naive PL (kappa = 0) -- the reference,
#   - MC default (ci_method = "montecarlo", glmmTMB REML)   -- incumbent 1,
#   - parametric bootstrap (ci_method = "bootstrap")        -- incumbent 2.
#
# NON-EXPORTED research harness (data-raw/, not R/); GO/NO-GO assessment only,
# ships no exported code (the D-006 / M62 shape). The full "not worse" criterion
# is PRE-REGISTERED (frozen, dated) in
# cairn/references/mpl-twoway-random-comparison.md BEFORE this run (GP5); this
# script only MEASURES, it applies no verdict (that is T4).
#
# Nominal 95% two-sided. The cheap methods (MPL, naive PL, MC) run at n_rep;
# the parametric bootstrap -- infeasibly slow (~5 s/dataset at B=199) -- runs on
# the first n_rep_pb PAIRED reps of each cell (the M76 precedent). MC coverage is
# CONDITIONAL on non-abort; the sigma^2_s->0 boundary abort (classed
# intraclass_singular_fit) rate and n_ok are recorded per cell (AC4).
#
# Run in the background (est. ~4-6 h; the parametric-bootstrap refits dominate):
#   Rscript data-raw/m87-mpl-comparison-sweep.R
# Writes an incremental per-cell checkpoint + final results to
# data-raw/m87-sweep-results.rds (raw per-rep rows + per-cell summary).

suppressMessages(devtools::load_all(quiet = TRUE))
source("data-raw/m86-mpl-lib.R")

kappa_path <- "data-raw/m87-kappa-recalibration.rds"
out_path <- "data-raw/m87-sweep-results.rds"

if (!file.exists(kappa_path)) {
  stop(
    "kappa_m fixture not found: run data-raw/m87-mpl-kappa-recalibration.R (T2) first.",
    call. = FALSE
  )
}
kappa_recal <- readRDS(kappa_path)
kappa_m_for <- function(n_r, n_s) {
  key <- sprintf("%d-%d", n_r, n_s)
  res <- kappa_recal$results[[key]]
  if (is.null(res)) {
    stop(sprintf("no recalibrated kappa_m for geometry %s", key), call. = FALSE)
  }
  res$kappa_m
}

conf <- 0.95
alpha <- 1 - conf

# --- data generation --------------------------------------------------------
# One balanced two-way random dataset (xiao2013 Eq. 1) as an n_s x n_r matrix,
# fully determined by `seed` so every method sees the SAME data (paired).
sim_matrix <- function(n_r, n_s, rho, delta, seed) {
  set.seed(seed)
  mpl_simulate(rho, delta, n_r, n_s) # n_s rows (subjects) x n_r cols (raters)
}
# Long form for the package engine: columns subject, rater, score.
matrix_to_long <- function(y) {
  n_s <- nrow(y)
  n_r <- ncol(y)
  data.frame(
    subject = rep(seq_len(n_s), times = n_r),
    rater = rep(seq_len(n_r), each = n_s),
    score = as.vector(y)
  )
}

# --- per-method interval extractors -----------------------------------------
# MPL / naive PL from the ANOVA layout (never abort -- closed root-find).
pl_ci <- function(y, kappa) {
  ms <- mpl_anova(y)
  iv <- tryCatch(
    mpl_interval(ms, kappa = kappa, alpha = alpha, side = "two"),
    error = function(e) {
      c(lower = NA_real_, upper = NA_real_, rho_hat = NA_real_)
    }
  )
  c(lower = unname(iv["lower"]), upper = unname(iv["upper"]))
}

# Package incumbents via icc() -> tidy ICC(A,1). The classed boundary abort
# (intraclass_singular_fit) is caught and recorded as NA (an abort), never
# silently coerced; any OTHER error is recorded separately so one bad fit cannot
# kill the background run.
safe_icc <- function(fn) {
  tryCatch(
    {
      td <- generics::tidy(fn())
      a1 <- td[td$index == "ICC(A,1)", ]
      c(lower = a1$conf.low, upper = a1$conf.high, aborted = 0, errored = 0)
    },
    intraclass_singular_fit = function(e) {
      c(lower = NA_real_, upper = NA_real_, aborted = 1, errored = 0)
    },
    error = function(e) {
      c(lower = NA_real_, upper = NA_real_, aborted = 0, errored = 1)
    }
  )
}
mc_ci <- function(d, seed) {
  safe_icc(function() {
    suppressWarnings(suppressMessages(icc(
      d,
      score,
      subject,
      rater,
      model = "twoway",
      type = "agreement",
      raters = "random",
      unit = "single",
      ci_method = "montecarlo",
      conf_level = conf,
      mc_samples = 10000L,
      seed = seed
    )))
  })
}
pb_ci <- function(d, seed) {
  safe_icc(function() {
    suppressWarnings(suppressMessages(icc(
      d,
      score,
      subject,
      rater,
      model = "twoway",
      type = "agreement",
      raters = "random",
      unit = "single",
      ci_method = "bootstrap",
      conf_level = conf,
      boot_samples = 199L,
      seed = seed
    )))
  })
}

# --- frozen cell grid (pre-registration) ------------------------------------
build_cells <- function(n_rep = 1000L, n_rep_pb = 500L) {
  spec <- list(
    list(id = "C1", n_r = 3L, n_s = 20L, delta = 1.0, rho = 0.60),
    list(id = "C2", n_r = 3L, n_s = 20L, delta = 1.0, rho = 0.05),
    list(id = "C3", n_r = 3L, n_s = 10L, delta = 1.0, rho = 0.05),
    list(id = "C4", n_r = 3L, n_s = 50L, delta = 4.0, rho = 0.60),
    list(id = "C5", n_r = 5L, n_s = 20L, delta = 1.0, rho = 0.75)
  )
  lapply(seq_along(spec), function(i) {
    c(spec[[i]], list(idx = i, n_rep = n_rep, n_rep_pb = n_rep_pb))
  })
}

# --- one replicate: all methods on ONE paired dataset -----------------------
one_rep <- function(cell, rep, kappa_m) {
  base <- cell$idx * 1000000L + rep
  y <- sim_matrix(cell$n_r, cell$n_s, cell$rho, cell$delta, seed = base)
  d <- matrix_to_long(y)

  cis <- list(
    mpl = c(pl_ci(y, kappa_m), aborted = 0, errored = 0),
    pl = c(pl_ci(y, 0), aborted = 0, errored = 0),
    mc = mc_ci(d, seed = base + 100000L)
  )
  if (rep <= cell$n_rep_pb) {
    cis$pboot <- pb_ci(d, seed = base + 200000L)
  }

  rows <- lapply(names(cis), function(m) {
    ci <- cis[[m]]
    lo <- unname(ci["lower"])
    hi <- unname(ci["upper"])
    aborted <- isTRUE(ci["aborted"] == 1) || !is.finite(lo) || !is.finite(hi)
    data.frame(
      cell = cell$id,
      n_r = cell$n_r,
      n_s = cell$n_s,
      delta = cell$delta,
      rho = cell$rho,
      rep = rep,
      method = m,
      lower = lo,
      upper = hi,
      aborted = aborted,
      errored = isTRUE(ci["errored"] == 1),
      covered = !aborted && lo <= cell$rho && cell$rho <= hi,
      width = if (aborted) NA_real_ else hi - lo,
      lo_miss = !aborted && cell$rho < lo,
      hi_miss = !aborted && cell$rho > hi,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

summarize_sweep <- function(raw) {
  agg <- do.call(
    rbind,
    lapply(
      split(raw, list(raw$cell, raw$method), drop = TRUE),
      function(g) {
        ok <- g[!g$aborted, ]
        data.frame(
          cell = g$cell[1],
          n_r = g$n_r[1],
          n_s = g$n_s[1],
          delta = g$delta[1],
          rho = g$rho[1],
          method = g$method[1],
          n_run = nrow(g),
          n_ok = nrow(ok),
          abort_rate = mean(g$aborted),
          errored = sum(g$errored),
          coverage = if (nrow(ok)) mean(ok$covered) else NA_real_,
          lo_miss = if (nrow(ok)) mean(ok$lo_miss) else NA_real_,
          hi_miss = if (nrow(ok)) mean(ok$hi_miss) else NA_real_,
          median_width = if (nrow(ok)) stats::median(ok$width) else NA_real_,
          stringsAsFactors = FALSE
        )
      }
    )
  )
  rownames(agg) <- NULL
  agg[order(agg$cell, agg$method), ]
}

run_sweep <- function(cells, out_path) {
  all_rows <- list()
  t0 <- Sys.time()
  for (cell in cells) {
    kappa_m <- kappa_m_for(cell$n_r, cell$n_s)
    cell_rows <- vector("list", cell$n_rep)
    for (rep in seq_len(cell$n_rep)) {
      cell_rows[[rep]] <- one_rep(cell, rep, kappa_m)
    }
    all_rows[[cell$idx]] <- do.call(rbind, cell_rows)
    saveRDS(
      list(
        rows = do.call(rbind, all_rows),
        done = cell$idx,
        of = length(cells)
      ),
      out_path
    )
    el <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
    cat(sprintf(
      "cell %s done (R=%d S=%d delta=%g rho=%.2f kappa_m=%.3f): %.1f min elapsed\n",
      cell$id,
      cell$n_r,
      cell$n_s,
      cell$delta,
      cell$rho,
      kappa_m,
      el
    ))
  }
  raw <- do.call(rbind, all_rows)
  agg <- summarize_sweep(raw)
  saveRDS(
    list(
      raw = raw,
      summary = agg,
      kappa_m = vapply(
        cells,
        function(c) kappa_m_for(c$n_r, c$n_s),
        numeric(1)
      ),
      meta = list(
        generated = Sys.time(),
        conf_level = conf,
        n_rep = cells[[1]]$n_rep,
        n_rep_pb = cells[[1]]$n_rep_pb,
        boot_samples = 199L,
        mc_samples = 10000L,
        criterion = "pre-registered in cairn/references/mpl-twoway-random-comparison.md",
        note = "GO/NO-GO assessment only; no exported code (D-006/M62 shape)."
      )
    ),
    out_path
  )
  agg
}

if (sys.nframe() == 0L) {
  cells <- build_cells()
  agg <- run_sweep(cells, out_path)
  cat("\nSweep complete. Summary:\n")
  print(
    agg[, c(
      "cell",
      "n_r",
      "n_s",
      "delta",
      "rho",
      "method",
      "n_ok",
      "abort_rate",
      "coverage",
      "lo_miss",
      "hi_miss",
      "median_width"
    )],
    row.names = FALSE
  )
}
