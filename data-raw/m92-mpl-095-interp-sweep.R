# data-raw/m92-mpl-095-interp-sweep.R
#
# M92 T2: the off-node-S confirmation sweep at the SHIPPED conf_level 0.95,
# pre-registered (and committed, GP5) in
# cairn/references/mpl-twoway-random-comparison.md § M92 pre-registration.
#
# Why it exists. M91's D1-D3 confirmed mpl_kappa_lookup's linear-in-S
# interpolation at conf_level 0.90 and 0.99. Its D4 sat at S = 20, an s_grid
# node, so the DEFAULT level 0.95 -- the one almost every call uses -- still
# carried no interpolation evidence at all. All three cells here are at 0.95
# and at an off-node S, so every one of them probes interpolation and none is a
# mixed-role aggregate (M91 review finding F1, scored 93).
#
# Frozen cells and floors (from the committed pre-registration -- this script
# APPLIES a bar already on disk in an earlier commit, it does not set one):
#   E1 (R=3,  S=25, d=4, rho=.60) @ 0.95  floor >= 0.93  n_rep 1000
#   E2 (R=10, S=40, d=4, rho=.60) @ 0.95  floor >= 0.93  n_rep 1000
#   E3 (R=2,  S=40, d=4, rho=.60) @ 0.95  floor >= 0.93  n_rep 1000
# E1 is the exact twin of M91's D1 (0.90) and D2 (0.99), completing the level
# triple at one geometry. E2 crosses the largest 0.95 downward step (kappa_m
# 0.1858 -> 0.1177 over S 30->50), where the error is largest RELATIVE to the
# 1 + kappa_m factor scaling the deviance critical value. E3 crosses a LARGE-kappa_m
# CONCAVE bracket (1.2670 -> 1.4657 over the same nodes): the slope falls across it,
# so the chord sits BELOW the curve -- an under-estimated kappa_m narrows the
# interval, the under-covering direction -- and kappa_m is large enough there for the
# absolute error to move an endpoint. E3 is NOT the slice's largest kappa_m: the
# (R=2, S 50->100) bracket is higher (1.4657 -> 1.6245) and the slice maximum is
# 1.6245 at (2, 100). S = 40 is M91's D3 geometry at the shipped level, which is why
# it was chosen. (An earlier draft of this header, and of four other sites, said
# "the largest 0.95 kappa_m"; corrected 2026-07-25 -- M92 review finding F3.)
#
# kappa_m is taken through the interpolation rule UNDER TEST, never a
# directly-evaluated value: the interpolated constant is the object of the test.
#
# Two rules are implemented, because the pre-registered consequence of a
# shortfall is a rule change, not a floor change:
#   "linear"     -- the SHIPPED rule (R/ci-mpl.R mpl_kappa_lookup): linear in S.
#   "bracketmax" -- the frozen consequence: an off-node S takes max() of its two
#                   bracketing node values. It is >= the chord everywhere, so
#                   the interval only ever widens, and node lookups are
#                   untouched. A shortfall re-run is THIS script with
#                   M92_RULE=bracketmax, so both runs stay traceable to one
#                   generator.
#
# Run (~10-20 min; the MPL interval is a deterministic closed form, ~ms/rep):
#   Rscript data-raw/m92-mpl-095-interp-sweep.R
# Smoke: M92_SMOKE=1 Rscript ... (few reps, all cells).
# Shortfall re-run: M92_RULE=bracketmax Rscript ...
# Writes data-raw/m92-interp-sweep.rds (per-rep endpoints + per-cell summary +
# the applied verdict; seeded, provenance in `meta`).

source("data-raw/m86-mpl-lib.R")

smoke <- Sys.getenv("M92_SMOKE") == "1"
rule <- Sys.getenv("M92_RULE")
if (!nzchar(rule)) {
  rule <- "linear"
}
if (!rule %in% c("linear", "bracketmax")) {
  stop(
    sprintf("M92_RULE must be 'linear' or 'bracketmax', got '%s'", rule),
    call. = FALSE
  )
}
out_path <- if (rule == "linear") {
  "data-raw/m92-interp-sweep.rds"
} else {
  "data-raw/m92-interp-sweep-bracketmax.rds"
}
tbl_095 <- "data-raw/m88-kappa-table.rds" # the shipped 0.95 slice (M88, D-015)

if (!file.exists(tbl_095)) {
  stop(sprintf("kappa_m fixture not found: %s", tbl_095), call. = FALSE)
}

kappa_095 <- readRDS(tbl_095)$kappa_m_table[, c("n_r", "n_s", "kappa_m")]

# The interpolation rules. Both take an exact node value unchanged; they differ
# only strictly between nodes, and neither extrapolates (rule = 1 -> NA outside).
kappa_lookup <- function(n_r, n_s, rule) {
  col <- kappa_095[kappa_095$n_r == n_r, c("n_s", "kappa_m")]
  if (nrow(col) == 0L) {
    stop(sprintf("no kappa_m for R=%d at 0.95", n_r), call. = FALSE)
  }
  col <- col[order(col$n_s), ]
  if (rule == "linear") {
    return(
      stats::approx(
        col$n_s,
        col$kappa_m,
        xout = n_s,
        method = "linear",
        rule = 1
      )$y
    )
  }
  # bracketmax: exact node -> that node; strictly between -> max of the bracket;
  # outside the grid -> NA, never an extrapolation.
  hit <- which(col$n_s == n_s)
  if (length(hit)) {
    return(col$kappa_m[hit])
  }
  j <- which(col$n_s < n_s)
  k <- which(col$n_s > n_s)
  if (!length(j) || !length(k)) {
    return(NA_real_)
  }
  max(col$kappa_m[max(j)], col$kappa_m[min(k)])
}

# Frozen cells (pre-registration § M92). Every one is at 0.95 and off-node.
cells <- data.frame(
  id = c("E1", "E2", "E3"),
  level = c("0.95", "0.95", "0.95"),
  conf = c(0.95, 0.95, 0.95),
  alpha = c(0.05, 0.05, 0.05),
  n_r = c(3L, 10L, 2L),
  n_s = c(25L, 40L, 40L),
  delta = c(4.0, 4.0, 4.0),
  rho = c(0.60, 0.60, 0.60),
  floor = c(0.93, 0.93, 0.93),
  n_rep = c(1000L, 1000L, 1000L),
  # `role` is asserted against the geometry below, never trusted from the label
  # (M91 finding F1: a per-level aggregate over mixed-role cells manufactures
  # confirmation no cell produced).
  role = c("interp", "interp", "interp"),
  stringsAsFactors = FALSE
)
s_nodes_shipped <- c(10L, 15L, 20L, 30L, 50L, 100L)
stopifnot(
  # The role labels must match the geometry, not the author's intent.
  identical(!(cells$n_s %in% s_nodes_shipped), cells$role == "interp"),
  # M92's whole point: no cell here may sit on a node, and all are at 0.95.
  !any(cells$n_s %in% s_nodes_shipped),
  all(cells$level == "0.95")
)
if (smoke) {
  cells$n_rep <- 60L
}

eps_lo <- 1e-6 # lower endpoint counts as clamped-to-0
eps_hi <- 0.999 # upper endpoint counts as clamped-to-1

# Seeding: a per-cell stride strictly larger than any n_rep, so no two cells share
# an RNG state (the M90 review F2 defect M91 fixed; inherited here).
#
# The base ALSO has to be disjoint from M91's, which is a separate hazard and was
# missed the first time round (M92 review finding F1, scored 87). The first M92 run
# used base 20260725 against M91's 20260724 at the SAME stride and cell ordering,
# so M92 cell `ci` rep `r` drew the same integer seed as M91 cell `ci` rep `r + 1`.
# Two of the three cells share a geometry with an M91 cell -- E1 with D1 (R=3, S=25)
# and E3 with D3 (R=2, S=40) -- and `mpl_simulate` depends only on
# (rho, delta, n_r, n_s), so those cells re-simulated M91's datasets bit-for-bit and
# were not an independent second look at all. That run is kept at
# data-raw/m92-interp-sweep-run1-collided.rds; this base is disjoint from every M91
# seed, and the assertion below is the mechanical guard so it cannot recur silently.
seed_base <- 20920725L
seed_stride <- 1000000L

# M91's seed span, recomputed from ITS committed constants rather than restated:
# base 20260724, same stride, 4 cells, max n_rep 2000.
m91_seed_base <- 20260724L
m91_seeds <- unlist(lapply(
  1:4,
  function(ci) {
    (m91_seed_base + seed_stride * ci + 1L):(m91_seed_base +
      seed_stride * ci +
      2000L)
  }
))
# Guard the FROZEN n_rep (1000), not `cells$n_rep`, which the smoke branch above has
# already shrunk to 60 -- a guard that relaxes in smoke mode is the one that would let
# a collision through on the cheap run and only bite on the expensive one.
m92_seeds <- unlist(lapply(
  seq_len(nrow(cells)),
  function(ci) {
    (seed_base + seed_stride * ci + 1L):(seed_base + seed_stride * ci + 1000L)
  }
))
stopifnot(
  # No M92 rep may reuse an M91 rep's seed, at any cell or geometry.
  length(intersect(m91_seeds, m92_seeds)) == 0L
)

summ <- list()
raw <- list()
cat(sprintf(
  "\n== M92 off-node-S sweep at conf_level 0.95 (rule: %s) ==\n",
  rule
))
for (ci in seq_len(nrow(cells))) {
  cc <- cells[ci, ]
  km <- kappa_lookup(cc$n_r, cc$n_s, rule)
  if (is.na(km)) {
    stop(
      sprintf(
        "%s: no bracketing kappa_m nodes for R=%d, S=%d",
        cc$id,
        cc$n_r,
        cc$n_s
      ),
      call. = FALSE
    )
  }
  lo <- up <- numeric(cc$n_rep)
  for (r in seq_len(cc$n_rep)) {
    set.seed(seed_base + seed_stride * ci + r)
    y <- mpl_simulate(cc$rho, cc$delta, cc$n_r, cc$n_s)
    ms <- mpl_anova(y)
    iv <- tryCatch(
      mpl_interval(ms, kappa = km, alpha = cc$alpha, side = "two"),
      error = function(e) c(lower = 0, upper = 1, rho_hat = NA_real_)
    )
    lo[r] <- unname(iv["lower"])
    up[r] <- unname(iv["upper"])
  }
  covered <- (lo <= cc$rho) & (cc$rho <= up)
  width <- up - lo
  cp <- stats::binom.test(sum(covered), cc$n_rep)$conf.int
  row <- data.frame(
    id = cc$id,
    level = cc$level,
    conf = cc$conf,
    role = cc$role,
    rule = rule,
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
      rule = rule,
      done = cc$id
    ),
    out_path
  )
}

summary_df <- do.call(rbind, summ)
rownames(summary_df) <- NULL

# Apply the frozen floors. A failing cell triggers the pre-registered
# consequence -- switch conf_level 0.95 to the bracketmax rule and re-run this
# cell against the SAME floor -- never a loosened floor, never a change to
# another level.
verdict <- lapply(split(summary_df, summary_df$level), function(d) {
  ip <- d[d$role == "interp", ]
  list(
    level = d$level[1],
    rule = rule,
    cells = d$id,
    min_coverage = min(d$coverage),
    failed_cells = d$id[!d$adequate],
    all_adequate = all(d$adequate),
    # interp_ok is NA where the level has no off-node cell -- absence of an
    # interpolation probe is not confirmation of interpolation (M91 finding F1).
    interp_cells = ip$id,
    interp_ok = if (nrow(ip) == 0L) NA else all(ip$adequate)
  )
})
cat(sprintf(
  "\n== verdict (frozen floors, § M92 pre-registration; rule: %s) ==\n",
  rule
))
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
      "NOT confirmed -- apply the pre-registered bracketmax consequence"
    }
  ))
}

saveRDS(
  list(
    summary = summary_df,
    raw = raw,
    cells = cells,
    verdict = verdict,
    rule = rule,
    meta = list(
      generator = "data-raw/m92-mpl-095-interp-sweep.R",
      kappa_source = tbl_095,
      kappa_rule = sprintf("%s interpolation under test (0.95 slice)", rule),
      preregistration = "cairn/references/mpl-twoway-random-comparison.md § M92 pre-registration",
      seed_base = seed_base,
      seed_stride = seed_stride,
      smoke = smoke,
      date = "2026-07-25"
    )
  ),
  out_path
)
cat(sprintf("\nsaved %s%s\n", out_path, if (smoke) "  (SMOKE)" else ""))
