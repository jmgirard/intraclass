# data-raw/m91-mpl-interp-sweep.R
#
# M91 T2: the interpolated-S confirmation sweep pre-registered (and committed,
# GP5) in cairn/references/mpl-twoway-random-comparison.md § M91 pre-registration.
#
# Why it exists. M90 validated coverage for conf_level 0.90/0.99 at eight cells
# that ALL sit on s_grid nodes {10,15,20,30,50,100}, so mpl_kappa_lookup's
# linear-in-S interpolation -- the path a user hits at any subject count between
# nodes -- carried no coverage evidence at any level, the shipped 0.95 included.
# The calibrated kappa_m is also non-monotone in S at all three levels, so the
# shipped "linear interpolation under-estimates kappa_m, hence conservative"
# reasoning does not hold; the interpolated constant needs its own check.
#
# Frozen cells and floors (from the committed pre-registration -- this script
# APPLIES a bar already on disk in an earlier commit, it does not set one):
#   D1 (R=3, S=25, d=4, rho=.60) @ 0.90  floor >= 0.88  n_rep 1000
#   D2 (R=3, S=25, d=4, rho=.60) @ 0.99  floor >= 0.98  n_rep 2000
#   D3 (R=2, S=40, d=4, rho=.60) @ 0.99  floor >= 0.98  n_rep 2000
#   D4 (R=3, S=20, d=1, rho=.02) @ 0.95  floor >= 0.93  n_rep 1000
# S=25 lies between the 20 and 30 nodes; S=40 between 30 and 50, spanning the
# largest absolute dip in the whole corpus (-0.154, from kappa_m 0.970 to 0.816 at
# R=2 @ 0.99) -- big enough for an interpolation error to move an endpoint, unlike
# the majority of dips, which sit where kappa_m is under 0.30. D4 is M90's
# C8 geometry at the SHIPPED level, making the sub-grid-floor rho posture
# uniform across levels (absorbs the RR03 rec-#9 candidate row).
#
# kappa_m is taken through the interpolation rule UNDER TEST (exact linear-in-S,
# mirroring R/ci-mpl.R mpl_kappa_lookup), never a directly-evaluated value: the
# interpolated constant is the object of the test.
#
# Run (~10-15 min; the MPL interval is a deterministic closed form, ~ms/rep):
#   Rscript data-raw/m91-mpl-interp-sweep.R
# Smoke: M91_SMOKE=1 Rscript ... (few reps, all cells).
# Writes data-raw/m91-interp-sweep.rds (per-rep endpoints + per-cell summary +
# the applied verdict; seeded, provenance in `meta`).

source("data-raw/m86-mpl-lib.R")

smoke <- Sys.getenv("M91_SMOKE") == "1"
out_path <- "data-raw/m91-interp-sweep.rds"
tbl_new <- "data-raw/m90-kappa-tables.rds" # 0.90 / 0.99 (M90)
tbl_095 <- "data-raw/m88-kappa-table.rds" # 0.95 (M88, the shipped slice)

for (p in c(tbl_new, tbl_095)) {
  if (!file.exists(p)) {
    stop(sprintf("kappa_m fixture not found: %s", p), call. = FALSE)
  }
}

fx_new <- readRDS(tbl_new)
fx_095 <- readRDS(tbl_095)

# Per-level kappa_m tables, assembled exactly as M91 T3 assembles R/sysdata.rda:
# 0.95 verbatim from the M88 fixture, 0.90/0.99 from the M90 fixture.
kappa_tables <- list(
  "0.90" = fx_new$tables[["0.90"]][, c("n_r", "n_s", "kappa_m")],
  "0.95" = fx_095$kappa_m_table[, c("n_r", "n_s", "kappa_m")],
  "0.99" = fx_new$tables[["0.99"]][, c("n_r", "n_s", "kappa_m")]
)

# The interpolation rule under test: exact R node, linear in S, no extrapolation.
kappa_lookup <- function(level, n_r, n_s) {
  tbl <- kappa_tables[[level]]
  col <- tbl[tbl$n_r == n_r, c("n_s", "kappa_m")]
  if (nrow(col) == 0L) {
    stop(sprintf("no kappa_m for R=%d at level %s", n_r, level), call. = FALSE)
  }
  col <- col[order(col$n_s), ]
  stats::approx(col$n_s, col$kappa_m, xout = n_s, method = "linear", rule = 1)$y
}

# Frozen cells (pre-registration § M91). Each carries its own level and floor.
cells <- data.frame(
  id = c("D1", "D2", "D3", "D4"),
  level = c("0.90", "0.99", "0.99", "0.95"),
  conf = c(0.90, 0.99, 0.99, 0.95),
  alpha = c(0.10, 0.01, 0.01, 0.05),
  n_r = c(3L, 3L, 2L, 3L),
  n_s = c(25L, 25L, 40L, 20L),
  delta = c(4.0, 4.0, 4.0, 1.0),
  rho = c(0.60, 0.60, 0.60, 0.02),
  floor = c(0.88, 0.98, 0.98, 0.93),
  n_rep = c(1000L, 2000L, 2000L, 1000L),
  # `role` keeps the two questions separate, because only ONE of them is about
  # interpolation. D1-D3 sit at an off-node S, so their kappa_m is interpolated and
  # they are the interpolation probe. D4's S = 20 IS an s_grid node, so approx()
  # returns the node value and NO interpolation happens: D4 tests the sub-grid-floor
  # rho posture at the shipped level, and says nothing about interpolated S there.
  # Aggregating the two would claim interpolation evidence at 0.95 that no cell
  # produced (M91 review finding F1, scored 93).
  role = c("interp", "interp", "interp", "subgrid_rho"),
  stringsAsFactors = FALSE
)
s_nodes_shipped <- c(10L, 15L, 20L, 30L, 50L, 100L)
stopifnot(
  # The role labels must match the geometry, not the author's intent.
  identical(!(cells$n_s %in% s_nodes_shipped), cells$role == "interp")
)
if (smoke) {
  cells$n_rep <- 60L
}

eps_lo <- 1e-6 # lower endpoint counts as clamped-to-0
eps_hi <- 0.999 # upper endpoint counts as clamped-to-1

# Seeding: a per-cell stride strictly larger than any n_rep, so no two cells
# share an RNG state (M90 review finding F2, logged sub-threshold there -- fixed
# here rather than inherited).
seed_base <- 20260724L
seed_stride <- 1000000L

summ <- list()
raw <- list()
fail_log <- mpl_failure_log()
cat("\n== M91 interpolated-S confirmation sweep ==\n")
for (ci in seq_len(nrow(cells))) {
  cc <- cells[ci, ]
  km <- kappa_lookup(cc$level, cc$n_r, cc$n_s)
  lo <- up <- numeric(cc$n_rep)
  for (r in seq_len(cc$n_rep)) {
    set.seed(seed_base + seed_stride * ci + r)
    y <- mpl_simulate(cc$rho, cc$delta, cc$n_r, cc$n_s)
    ms <- mpl_anova(y)
    iv <- mpl_interval_counted(
      ms,
      kappa = km,
      alpha = cc$alpha,
      side = "two",
      log = fail_log,
      cell = cc$id,
      rep_i = r
    )
    lo[r] <- unname(iv["lower"])
    up[r] <- unname(iv["upper"])
  }
  # M96: a failed fit is recorded, never scored -- abort (naming the cell)
  # before any summary stat or fixture write can see an NA endpoint.
  mpl_assert_no_failures(fail_log, out_path)
  covered <- (lo <= cc$rho) & (cc$rho <= up)
  width <- up - lo
  cp <- stats::binom.test(sum(covered), cc$n_rep)$conf.int
  row <- data.frame(
    id = cc$id,
    level = cc$level,
    conf = cc$conf,
    role = cc$role,
    n_r = cc$n_r,
    n_s = cc$n_s,
    delta = cc$delta,
    rho = cc$rho,
    kappa_m = km,
    n_rep = cc$n_rep,
    coverage = mean(covered),
    cp_lo = cp[1],
    cp_hi = cp[2],
    miss_below = sum(cc$rho < lo),
    miss_above = sum(cc$rho > up),
    width_med = stats::median(width),
    width_p90 = stats::quantile(width, 0.90, names = FALSE),
    p_lower0 = mean(lo <= eps_lo),
    p_upper1 = mean(up >= eps_hi),
    vacuous = mean(lo <= eps_lo & up >= eps_hi),
    failures = mpl_cell_failures(fail_log, cc$id),
    floor = cc$floor,
    adequate = mean(covered) >= cc$floor,
    stringsAsFactors = FALSE
  )
  summ[[cc$id]] <- row
  raw[[cc$id]] <- data.frame(lower = lo, upper = up, covered = covered)
  cat(sprintf(
    "  %s @%s (R=%d,S=%d,d=%g,rho=%.2f) km=%.4f: cov=%.4f [%.4f,%.4f] floor %.2f %s  miss -/+ %d/%d  w50=%.3f\n",
    cc$id,
    cc$level,
    cc$n_r,
    cc$n_s,
    cc$delta,
    cc$rho,
    km,
    row$coverage,
    row$cp_lo,
    row$cp_hi,
    cc$floor,
    if (row$adequate) "PASS" else "FAIL",
    row$miss_below,
    row$miss_above,
    row$width_med
  ))
  saveRDS(
    list(
      summary = do.call(rbind, summ),
      raw = raw,
      cells = cells,
      done = cc$id
    ),
    out_path
  )
}

summary_df <- do.call(rbind, summ)
rownames(summary_df) <- NULL
# M96 (AC3): total failures across cells must be zero before the fixture is
# written -- a run with any failure produces no fixture at all.
mpl_assert_no_failures(fail_log, out_path)
stopifnot(sum(summary_df$failures) == 0L)

# Apply the frozen floors. A failing cell restricts ITS level to exact s_grid S
# nodes (the pre-registered consequence) -- never a loosened floor, never a
# change to another level.
verdict <- lapply(split(summary_df, summary_df$level), function(d) {
  ip <- d[d$role == "interp", ]
  list(
    level = d$level[1],
    cells = d$id,
    min_coverage = min(d$coverage),
    failed_cells = d$id[!d$adequate],
    all_adequate = all(d$adequate),
    # interp_ok is NA where the level has no off-node cell -- absence of an
    # interpolation probe is not confirmation of interpolation (finding F1).
    interp_cells = ip$id,
    interp_ok = if (nrow(ip) == 0L) NA else all(ip$adequate)
  )
})
cat("\n== verdict (frozen floors, § M91 pre-registration) ==\n")
for (v in verdict) {
  cat(sprintf(
    "  %s: %d/%d cells adequate (min coverage %.4f%s); interpolated S %s\n",
    v$level,
    sum(summary_df$adequate[summary_df$level == v$level]),
    sum(summary_df$level == v$level),
    v$min_coverage,
    if (length(v$failed_cells)) {
      sprintf("; failed: %s", paste(v$failed_cells, collapse = ", "))
    } else {
      ""
    },
    if (is.na(v$interp_ok)) {
      "NOT PROBED at this level (no off-node cell)"
    } else if (v$interp_ok) {
      sprintf("CONFIRMED (%s)", paste(v$interp_cells, collapse = ", "))
    } else {
      "NOT confirmed"
    }
  ))
}

saveRDS(
  list(
    summary = summary_df,
    raw = raw,
    cells = cells,
    verdict = verdict,
    meta = list(
      generator = "data-raw/m91-mpl-interp-sweep.R",
      kappa_sources = list(
        "0.90" = tbl_new,
        "0.95" = tbl_095,
        "0.99" = tbl_new
      ),
      kappa_rule = "linear-in-S interpolation under test (mirrors R/ci-mpl.R mpl_kappa_lookup)",
      preregistration = "cairn/references/mpl-twoway-random-comparison.md § M91 pre-registration",
      seed_base = seed_base,
      seed_stride = seed_stride,
      smoke = smoke,
      date = "2026-07-24"
    )
  ),
  out_path
)
cat(sprintf("\nsaved %s%s\n", out_path, if (smoke) "  (SMOKE)" else ""))
