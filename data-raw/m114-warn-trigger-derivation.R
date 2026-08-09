# M114 T2/T3 — per-rep warn-trigger statistics over the regenerated M111 reps.
#
# Regenerates every (cell, rep) dataset of the committed M111 fixture from its
# seed scheme (base = cell$id * 1000000L + rep; data-raw/m111-fallback-sweep.R)
# WITHOUT refitting anything, proves the regeneration is the fixture's (the
# recomputed SEARLE interval must equal the fixture's stored endpoints per rep
# within 1e-12 — AC2), computes the two frozen candidate statistics per rep
# (kappa_bc, gamma; cairn/references/mc-skew-warn-trigger.md, frozen BEFORE
# this script existed), and writes the M111 half of the derived table
# data-raw/m114-warn-trigger-stats.tsv. The held-out half is appended by
# data-raw/m114-heldout-sweep.R; the verdict is applied only by
# data-raw/m114-warn-trigger-verdict.R (no selection logic lives here).
#
# NON-EXPORTED research harness (data-raw/, not R/); assessment only, ships no
# exported code. Statistics are computed from the SHIPPED implementations
# (intraclass:::burch_kappa_hat / :::burch_kappa_bc) so the assessed statistic
# is the one a runtime trigger would actually compute; the script's own z
# recomputation exists only to derive gamma and is pinned to the shipped
# decomposition per rep (see the kappa cross-check below).
#
# Run (foreground, single-threaded, ~minutes):
#   Rscript data-raw/m114-warn-trigger-derivation.R

suppressMessages(devtools::load_all(quiet = TRUE))
# Defines searle_f_ci_balanced(); its oracle block is behind sys.nframe() == 0L.
source("data-raw/m76-classical-oneway-prototype.R")

fixture_path <- "data-raw/m111-fallback-results.rds"
out_path <- "data-raw/m114-warn-trigger-stats.tsv"
tol_searle <- 1e-12

fixture <- readRDS(fixture_path)

# ---- platform gate (AC2) -----------------------------------------------------
# The 1e-12 endpoint-equality proof is scoped to a platform matching the
# fixture's recorded metadata: qf()'s last-ulp behavior can differ across R
# builds (M84/M105 platform-dependence lesson). Refuse to certify elsewhere.
plat <- fixture$meta$platform
here <- list(
  r_version = R.version.string,
  sysname = Sys.info()[["sysname"]],
  machine = Sys.info()[["machine"]]
)
if (!identical(plat, here)) {
  stop(
    "platform mismatch vs the fixture's meta$platform — the AC2 1e-12 ",
    "consistency proof is only certified on the recording platform.\n",
    "fixture: ",
    paste(unlist(plat), collapse = " / "),
    "\n",
    "here:    ",
    paste(unlist(here), collapse = " / ")
  )
}

# ---- gen_oneway: copied VERBATIM from data-raw/m111-fallback-sweep.R --------
# A copy can drift; the AC2 searle-endpoint proof below is the guard that
# detects any divergence (same seeds + same generator => same data => same
# closed-form interval; a drifted copy fails the 1e-12 assertion immediately).
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

# ---- per-rep statistics ------------------------------------------------------
# trigger_stats() + stats_fmt() live in data-raw/m114-trigger-stats.R, shared
# with the held-out sweep so both halves compute the identical statistic.
source("data-raw/m114-trigger-stats.R")

# ---- main loop: regenerate, prove, measure ----------------------------------
raw <- fixture$raw
searle <- raw[raw$method == "searle", ]
wide <- fixture$wide
cells <- fixture$summary[, c("cell", "rho", "k", "n", "dist")]
stopifnot(nrow(cells) == 64L, identical(cells$cell, 1:64))

n_checked <- 0L
rows <- vector("list", nrow(cells))
for (ci in seq_len(nrow(cells))) {
  cell <- cells[ci, ]
  se_cell <- searle[searle$cell == cell$cell, ]
  se_cell <- se_cell[order(se_cell$rep), ]
  wd_cell <- wide[wide$cell == cell$cell, ]
  wd_cell <- wd_cell[order(wd_cell$rep), ]
  n_rep <- nrow(se_cell)
  stopifnot(n_rep == 2000L, identical(se_cell$rep, wd_cell$rep))
  kap_bc <- gam <- rep(NA_real_, n_rep)
  defined <- logical(n_rep)
  for (r in seq_len(n_rep)) {
    base <- cell$cell * 1000000L + se_cell$rep[r]
    d <- gen_oneway(cell$k, cell$n, cell$rho, cell$dist, seed = base)
    s <- searle_f_ci_balanced(d)
    # AC2 proof: the regenerated dataset yields the fixture's own stored
    # SEARLE endpoints (aborted searle reps, if any, compared on the flag).
    if (se_cell$aborted[r]) {
      stopifnot(!is.finite(s[["lower"]]) || !is.finite(s[["upper"]]))
    } else {
      if (
        abs(s[["lower"]] - se_cell$lower[r]) > tol_searle ||
          abs(s[["upper"]] - se_cell$upper[r]) > tol_searle
      ) {
        stop(
          "AC2 consistency failure at cell ",
          cell$cell,
          " rep ",
          se_cell$rep[r],
          ": regenerated searle interval [",
          s[["lower"]],
          ", ",
          s[["upper"]],
          "] vs stored [",
          se_cell$lower[r],
          ", ",
          se_cell$upper[r],
          "]"
        )
      }
      n_checked <- n_checked + 1L
    }
    st <- trigger_stats(d, cell$k, cell$n)
    defined[r] <- st$defined
    kap_bc[r] <- st$kappa_bc
    gam[r] <- st$gamma
  }
  rows[[ci]] <- data.frame(
    cell = cell$cell,
    rho = cell$rho,
    k = cell$k,
    n = cell$n,
    dist = cell$dist,
    rep = se_cell$rep,
    source = "m111",
    mc_aborted = wd_cell$mc_aborted,
    mc_covered = wd_cell$mc_covered,
    stat_defined = defined,
    kappa_bc = kap_bc,
    gamma = gam,
    stringsAsFactors = FALSE
  )
  message(sprintf("cell %d/64 done (%s)", cell$cell, cell$dist))
}

stats <- do.call(rbind, rows)
stopifnot(nrow(stats) == 64L * 2000L)
message(sprintf(
  "AC2 proof: %d/%d non-aborted searle reps matched within %g",
  n_checked,
  sum(!searle$aborted),
  tol_searle
))
stopifnot(n_checked == sum(!searle$aborted))

fmt <- stats_fmt
out <- stats
out$rho <- sprintf("%.2f", out$rho)
out$kappa_bc <- fmt(out$kappa_bc)
out$gamma <- fmt(out$gamma)
write.table(
  out,
  out_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)
message("wrote ", out_path, " (", nrow(out), " rows, m111 half)")
