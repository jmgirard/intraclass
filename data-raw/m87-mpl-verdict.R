# data-raw/m87-mpl-verdict.R
#
# M87 T4: apply the PRE-REGISTERED "not worse" criterion (frozen in
# cairn/references/mpl-twoway-random-comparison.md BEFORE any run -- GP5) to the
# comparison-sweep results (data-raw/m87-sweep-results.rds, produced by
# data-raw/m87-mpl-comparison-sweep.R), tabulate coverage/width per cell, name the
# deciding cells, and state the GO/NO-GO verdict.
#
# NOT package code. Deterministic given the committed sweep fixture; applies the
# criterion, invents nothing. The criterion was frozen before the data (GP5): this
# script only evaluates it.
#
# Criterion (verbatim from the pre-registration). MPL is the candidate. MPL is
# "not worse" at a cell iff BOTH:
#   (1) empirical coverage >= 0.93  (nominal 0.95 - 2 pp);
#   (2) MPL coverage >= min(MC, parametric-bootstrap coverage) - 0.01.
# Overall GO iff MPL is "not worse" at EVERY cell (C2/C3 decisive). Tiebreaker:
# smaller median width among methods clearing (1)+(2). MC coverage is conditional
# on non-abort; the abort share is carried into the verdict framing.
#
# Run:  Rscript data-raw/m87-mpl-verdict.R

sweep_path <- "data-raw/m87-sweep-results.rds"
if (!file.exists(sweep_path)) {
  stop(
    "sweep results not found: run data-raw/m87-mpl-comparison-sweep.R (T3) first.",
    call. = FALSE
  )
}
sweep <- readRDS(sweep_path)
agg <- sweep$summary

cov_floor <- 0.93 # criterion (1)
incumbent_slack <- 0.01 # criterion (2)

cells <- unique(agg$cell)
per_cell <- do.call(
  rbind,
  lapply(cells, function(cid) {
    g <- agg[agg$cell == cid, ]
    getm <- function(m, col) {
      v <- g[[col]][g$method == m]
      if (length(v)) v else NA_real_
    }
    mpl_cov <- getm("mpl", "coverage")
    mc_cov <- getm("mc", "coverage")
    pb_cov <- getm("pboot", "coverage")
    min_incumbent <- min(c(mc_cov, pb_cov), na.rm = TRUE)
    c1 <- isTRUE(mpl_cov >= cov_floor)
    c2 <- isTRUE(mpl_cov >= min_incumbent - incumbent_slack)
    data.frame(
      cell = cid,
      rho = g$rho[1],
      n_r = g$n_r[1],
      n_s = g$n_s[1],
      mpl_cov = mpl_cov,
      pl_cov = getm("pl", "coverage"),
      mc_cov = mc_cov,
      mc_abort = getm("mc", "abort_rate"),
      pb_cov = pb_cov,
      min_incumbent = min_incumbent,
      mpl_width = getm("mpl", "median_width"),
      mc_width = getm("mc", "median_width"),
      pb_width = getm("pboot", "median_width"),
      crit1_near_nominal = c1,
      crit2_not_below_incumbent = c2,
      not_worse = c1 && c2,
      stringsAsFactors = FALSE
    )
  })
)
rownames(per_cell) <- NULL

decisive <- c("C2", "C3") # near-zero boundary + few-subjects corner (GP6)
overall_go <- all(per_cell$not_worse)
failing <- per_cell$cell[!per_cell$not_worse]

cat("== M87 T4 verdict: 'not worse' criterion applied cell-by-cell ==\n")
cat(sprintf(
  "   floor(1) coverage >= %.2f ; slack(2) MPL >= min(incumbents) - %.2f\n\n",
  cov_floor,
  incumbent_slack
))
print(
  per_cell[, c(
    "cell",
    "rho",
    "n_r",
    "n_s",
    "mpl_cov",
    "mc_cov",
    "mc_abort",
    "pb_cov",
    "min_incumbent",
    "crit1_near_nominal",
    "crit2_not_below_incumbent",
    "not_worse"
  )],
  row.names = FALSE
)
cat("\n-- median widths (tiebreaker) --\n")
print(
  per_cell[, c("cell", "rho", "mpl_width", "mc_width", "pb_width")],
  row.names = FALSE
)

cat(sprintf(
  "\nVERDICT: %s\n",
  if (overall_go) "GO (MPL not worse at every cell)" else "NO-GO"
))
if (!overall_go) {
  cat(sprintf(
    "  deciding (failing) cells: %s%s\n",
    paste(failing, collapse = ", "),
    if (any(failing %in% decisive)) {
      sprintf(
        "  [includes pre-designated decisive cell(s): %s]",
        paste(intersect(failing, decisive), collapse = ", ")
      )
    } else {
      ""
    }
  ))
}

saveRDS(
  list(
    per_cell = per_cell,
    overall_go = overall_go,
    failing_cells = failing,
    decisive_cells = decisive,
    criterion = list(cov_floor = cov_floor, incumbent_slack = incumbent_slack),
    kappa_m = sweep$kappa_m,
    sweep_meta = sweep$meta
  ),
  "data-raw/m87-verdict.rds"
)
cat("\nsaved data-raw/m87-verdict.rds\n")
