# M76 T4/T5 — coverage / width / tail sweep for the one-way random ICC.
#
# Compares the two classical boundary-robust intervals (SEARLE exact-F, Burch
# 2011 REML; prototyped + oracle-validated in T3) against the package incumbents
# (MC default, parametric bootstrap, npbootstrap transformed bootstrap-t) on a
# pre-registered grid. NON-EXPORTED research harness (data-raw/, not R/); GO/NO-GO
# assessment only, ships no exported code (D-006 shape).
#
# The full GO/NO-GO criterion is PRE-REGISTERED (frozen, dated) in
# cairn/references/classical-oneway-comparison.md BEFORE this run (GP5). This
# script only measures; it applies no verdict.
#
# Run in the background (~5 h; the parametric-bootstrap refits dominate):
#   Rscript data-raw/m76-coverage-sweep.R
# Writes an incremental per-cell checkpoint and a final results fixture to
# data-raw/m76-sweep-results.rds (accumulated raw per-rep rows + per-cell summary).

suppressMessages(devtools::load_all(quiet = TRUE))
# Defines searle_f_ci_balanced() and burch_reml_ci_balanced(); sourcing skips the
# file's `if (sys.nframe() == 0L)` oracle block.
source("data-raw/m76-classical-oneway-prototype.R")

out_path <- "data-raw/m76-sweep-results.rds"

# ---- data generation ---------------------------------------------------------
# Balanced one-way: subject effect a_i ~ dist (variance rho), error e_ij ~
# N(0, 1-rho); ICC = rho for both distributions. The non-normal cell makes the
# CLUSTER effect leptokurtic (GP6): scaled t(5), kurtosis ~6, errors stay normal.
gen_oneway <- function(k, n, rho, dist, seed) {
  set.seed(seed)
  sd_a <- sqrt(rho)
  sd_e <- sqrt(1 - rho)
  a <- if (dist == "gaussian") {
    stats::rnorm(k, 0, sd_a)
  } else {
    stats::rt(k, df = 5) * sd_a / sqrt(5 / 3) # scale t(5) to variance rho
  }
  vals <- rep(a, each = n) + stats::rnorm(k * n, 0, sd_e)
  data.frame(
    subject = rep(seq_len(k), each = n),
    rater = rep(seq_len(n), times = k),
    score = vals,
    y = vals # alias consumed by the prototype functions
  )
}

# ---- per-method interval extractors -----------------------------------------
# Classical prototypes never abort (closed-form): c(lower, upper) always finite.
# The incumbents can abort on a boundary/singular fit (intraclass_singular_fit);
# caught and recorded as NA (an abort), never silently coerced.
safe_icc <- function(fn) {
  tryCatch(
    {
      td <- generics::tidy(fn())
      i1 <- td[td$index == "ICC(1)", ]
      c(lower = i1$conf.low, upper = i1$conf.high)
    },
    intraclass_singular_fit = function(e) c(lower = NA_real_, upper = NA_real_)
  )
}

mc_ci <- function(d, seed) {
  safe_icc(function() {
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "montecarlo",
      mc_samples = 10000L,
      seed = seed
    )
  })
}
np_ci <- function(d, seed) {
  safe_icc(function() {
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "npbootstrap",
      boot_samples = 999L,
      seed = seed
    )
  })
}
pb_ci <- function(d, seed) {
  safe_icc(function() {
    icc(
      d,
      score,
      subject,
      rater,
      model = "oneway",
      ci_method = "bootstrap",
      boot_samples = 299L,
      seed = seed
    )
  })
}

# ---- pre-registered grid (16 cells) -----------------------------------------
# rho in {0.05, 0.10} x (k,n) in {(10,5),(30,5),(50,5),(10,2)} x {gaussian, t5}.
# Cheap methods (searle, burch, mc, np) at n_rep = 2000. Parametric bootstrap is
# infeasible at that scale (~19 s/dataset) so it runs ONLY at the two near-zero
# corner cells (rho=0.05, k=10, n=5; gaussian + t5) at n_rep = 500, boot = 299.
build_cells <- function(n_rep = 2000L, n_rep_pb = 500L) {
  kn_levels <- list(
    c(k = 10, n = 5),
    c(k = 30, n = 5),
    c(k = 50, n = 5),
    c(k = 10, n = 2)
  )
  cells <- list()
  cid <- 0L
  for (rho in c(0.05, 0.10)) {
    for (kn in kn_levels) {
      for (dist in c("gaussian", "t5")) {
        cid <- cid + 1L
        run_pb <- (rho == 0.05 && kn[["k"]] == 10 && kn[["n"]] == 5)
        cells[[cid]] <- list(
          id = cid,
          rho = rho,
          k = kn[["k"]],
          n = kn[["n"]],
          dist = dist,
          n_rep = n_rep,
          run_pb = run_pb,
          n_rep_pb = n_rep_pb
        )
      }
    }
  }
  cells
}

# ---- sweep -------------------------------------------------------------------
one_rep <- function(cell, rep) {
  base <- cell$id * 1000000L + rep
  d <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed = base)
  methods <- list(
    searle = searle_f_ci_balanced(d),
    burch = burch_reml_ci_balanced(d),
    mc = mc_ci(d, seed = base + 100000L),
    np = np_ci(d, seed = base + 200000L)
  )
  if (cell$run_pb && rep <= cell$n_rep_pb) {
    methods$pb <- pb_ci(d, seed = base + 300000L)
  }
  rows <- lapply(names(methods), function(m) {
    ci <- methods[[m]]
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

summarize_sweep <- function(raw) {
  agg <- do.call(
    rbind,
    lapply(
      split(raw, list(raw$cell, raw$method), drop = TRUE),
      function(g) {
        ok <- g[!g$aborted, ]
        data.frame(
          cell = g$cell[1],
          rho = g$rho[1],
          k = g$k[1],
          n = g$n[1],
          dist = g$dist[1],
          method = g$method[1],
          n_run = nrow(g),
          n_ok = nrow(ok),
          abort_rate = mean(g$aborted),
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
  agg
}

run_sweep <- function(cells, out_path) {
  all_rows <- list()
  t0 <- Sys.time()
  for (cell in cells) {
    cell_rows <- vector("list", cell$n_rep)
    for (rep in seq_len(cell$n_rep)) {
      cell_rows[[rep]] <- one_rep(cell, rep)
    }
    all_rows[[cell$id]] <- do.call(rbind, cell_rows)
    # Incremental checkpoint so an interrupted run keeps completed cells.
    saveRDS(
      list(rows = do.call(rbind, all_rows), done = cell$id, of = length(cells)),
      out_path
    )
    el <- round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1)
    cat(sprintf(
      "cell %2d/%d done: rho=%.2f k=%d n=%d %-8s (%.1f min elapsed)\n",
      cell$id,
      length(cells),
      cell$rho,
      cell$k,
      cell$n,
      cell$dist,
      el
    ))
  }
  raw <- do.call(rbind, all_rows)
  agg <- summarize_sweep(raw)
  saveRDS(
    list(
      raw = raw,
      summary = agg,
      meta = list(
        generated = Sys.time(),
        criterion = "pre-registered in cairn/references/classical-oneway-comparison.md",
        note = "GO/NO-GO assessment only; no exported code (D-006 shape)."
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
    agg[
      order(agg$cell),
      c(
        "rho",
        "k",
        "n",
        "dist",
        "method",
        "n_ok",
        "abort_rate",
        "coverage",
        "lo_miss",
        "hi_miss",
        "median_width"
      )
    ],
    row.names = FALSE
  )
}
