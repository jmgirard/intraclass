# data-raw/m90-mpl-coverage-sweep.R
#
# M90 T3 (RR03/D-017): coverage sweep validating the recalibrated kappa_m tables
# (data-raw/m90-kappa-tables.rds, from T2) at conf_level 0.90 and 0.99, against the
# frozen pre-registration in cairn/references/mpl-twoway-random-comparison.md.
# MPL-only -- the incumbent "not worse" comparison is settled method-level at D-014.
#
# Binding criteria enforced here:
#   BC4  n_rep >= 2000 per cell at 0.99 (coverage MC-SE <= 0.0032 at the 0.98 floor);
#        >= 1000 at 0.90. Verdict reports an exact Clopper-Pearson 95% CI per cell.
#   BC5  Decisive cells C1-C5 (M87) PLUS C6=(3,100,d4,r.60), C7=(2,15,d1,r.05),
#        C8=(3,20,d1,r.02, the sub-grid-floor rho).
#   BC6  Per cell: miss-below/miss-above, median + p90 width, P(lower=0),
#        P(upper>=0.999), vacuous fraction (both clamps).
# The GO/NO-GO floors (BC3: >=0.88 at 0.90, >=0.98 at 0.99) are APPLIED in T4
# (data-raw/m90-mpl-verdict.R); this script only MEASURES (GP5).
#
# Run (background; ~1-2 h -- deterministic MPL interval, ~ms/rep):
#   Rscript data-raw/m90-mpl-coverage-sweep.R
# Smoke: M90_SMOKE=1 Rscript ... (fewer reps, both levels, all cells).
# Writes data-raw/m90-coverage-sweep.rds (raw per-rep coverage + per-cell summary).

source("data-raw/m86-mpl-lib.R")

smoke <- Sys.getenv("M90_SMOKE") == "1"
tbl_path <- "data-raw/m90-kappa-tables.rds"
out_path <- "data-raw/m90-coverage-sweep.rds"

if (!file.exists(tbl_path)) {
  stop(
    "kappa_m fixture not found: run data-raw/m90-mpl-kappa-tables.R (T2) first.",
    call. = FALSE
  )
}
fx <- readRDS(tbl_path)

# kappa_m lookup mirroring R/ci-mpl.R mpl_kappa_lookup: exact R node, linear-in-S
# interpolation. All sweep cells sit on s_grid nodes, so this reduces to a direct
# lookup, but the interpolation path is kept for faithfulness.
kappa_lookup <- function(level, n_r, n_s) {
  t <- fx$tables[[level]]
  col <- t[t$n_r == n_r, c("n_s", "kappa_m")]
  if (nrow(col) == 0) {
    stop(sprintf("no kappa_m for R=%d at level %s", n_r, level))
  }
  col <- col[order(col$n_s), ]
  stats::approx(col$n_s, col$kappa_m, xout = n_s, method = "linear", rule = 1)$y
}

# Frozen decisive cells (BC5). id, R, S, delta, rho.
cells <- data.frame(
  id = c("C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"),
  n_r = c(3L, 3L, 3L, 3L, 5L, 3L, 2L, 3L),
  n_s = c(20L, 20L, 10L, 50L, 20L, 100L, 15L, 20L),
  delta = c(1.0, 1.0, 1.0, 4.0, 1.0, 4.0, 1.0, 1.0),
  rho = c(0.60, 0.05, 0.05, 0.60, 0.75, 0.60, 0.05, 0.02),
  stringsAsFactors = FALSE
)

levels <- list(
  list(name = "0.90", conf = 0.90, alpha = 0.10, n_rep = 1000L),
  list(name = "0.99", conf = 0.99, alpha = 0.01, n_rep = 2000L)
)
if (smoke) {
  cells <- cells[cells$id %in% c("C1", "C2", "C8"), ]
  for (i in seq_along(levels)) {
    levels[[i]]$n_rep <- 60L
  }
}

eps_lo <- 1e-6 # lower endpoint counts as clamped-to-0
eps_hi <- 0.999 # upper endpoint counts as clamped-to-1

summ <- list()
raw <- list()
fail_log <- mpl_failure_log()
for (lv in levels) {
  for (ci in seq_len(nrow(cells))) {
    cc <- cells[ci, ]
    key <- sprintf("%s:%s", lv$name, cc$id)
    km <- kappa_lookup(lv$name, cc$n_r, cc$n_s)
    lo <- up <- numeric(lv$n_rep)
    for (r in seq_len(lv$n_rep)) {
      set.seed(
        20260724L + 100000L * match(lv$name, c("0.90", "0.99")) + 1000L * ci + r
      )
      y <- mpl_simulate(cc$rho, cc$delta, cc$n_r, cc$n_s)
      ms <- mpl_anova(y)
      iv <- mpl_interval_counted(
        ms,
        kappa = km,
        alpha = lv$alpha,
        side = "two",
        log = fail_log,
        cell = key,
        rep_i = r
      )
      lo[r] <- unname(iv["lower"])
      up[r] <- unname(iv["upper"])
    }
    # M96: a failed fit is recorded, never scored -- abort (naming the cell)
    # before any summary stat or fixture write can see an NA endpoint.
    mpl_assert_no_failures(fail_log, out_path)
    covered <- (lo <= cc$rho) & (cc$rho <= up)
    miss_below <- cc$rho < lo # true rho below interval
    miss_above <- cc$rho > up
    width <- up - lo
    x <- sum(covered)
    cp <- stats::binom.test(x, lv$n_rep)$conf.int
    row <- data.frame(
      level = lv$name,
      conf = lv$conf,
      id = cc$id,
      n_r = cc$n_r,
      n_s = cc$n_s,
      delta = cc$delta,
      rho = cc$rho,
      kappa_m = km,
      n_rep = lv$n_rep,
      coverage = mean(covered),
      cp_lo = cp[1],
      cp_hi = cp[2],
      miss_below = sum(miss_below),
      miss_above = sum(miss_above),
      width_med = stats::median(width),
      width_p90 = stats::quantile(width, 0.90, names = FALSE),
      p_lower0 = mean(lo <= eps_lo),
      p_upper1 = mean(up >= eps_hi),
      vacuous = mean(lo <= eps_lo & up >= eps_hi),
      failures = mpl_cell_failures(fail_log, key),
      stringsAsFactors = FALSE
    )
    summ[[key]] <- row
    raw[[key]] <- data.frame(
      lower = lo,
      upper = up,
      covered = covered
    )
    cat(sprintf(
      "  %s %s (R=%d,S=%3d,d=%g,rho=%.2f) km=%.3f: cov=%.4f [%.4f,%.4f] miss -/+ %d/%d  w50=%.3f\n",
      lv$name,
      cc$id,
      cc$n_r,
      cc$n_s,
      cc$delta,
      cc$rho,
      km,
      row$coverage,
      row$cp_lo,
      row$cp_hi,
      row$miss_below,
      row$miss_above,
      row$width_med
    ))
    saveRDS(
      list(
        summary = do.call(rbind, summ),
        raw = raw,
        cells = cells,
        done = key
      ),
      out_path
    )
  }
}

summary_df <- do.call(rbind, summ)
rownames(summary_df) <- NULL
# M96 (AC3): total failures across cells must be zero before the fixture is
# written -- a run with any failure produces no fixture at all.
mpl_assert_no_failures(fail_log, out_path)
stopifnot(sum(summary_df$failures) == 0L)
saveRDS(
  list(
    summary = summary_df,
    raw = raw,
    cells = cells,
    meta = list(
      generator = "data-raw/m90-mpl-coverage-sweep.R",
      kappa_source = tbl_path,
      levels = lapply(levels, function(x) {
        x[c("name", "conf", "alpha", "n_rep")]
      }),
      seed_base = 20260724L,
      smoke = smoke,
      date = "2026-07-24"
    )
  ),
  out_path
)
cat(sprintf("\nsaved %s%s\n", out_path, if (smoke) "  (SMOKE)" else ""))
