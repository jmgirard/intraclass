# M118 AC4 -- the two validation anchors, asserted.
#
# The frozen page makes these a PRECONDITION: the W1-W3 rules are read only if
# the grid clears both, and a failure here is a defect in this grid rather than
# a finding about Burch (classical-width-reversal-comparison.md, Validation
# preconditions).
#
# Leg 1, against the source: burch2011 (p. 1027) prints coverages and an
# expected-length ratio for one both-components cell. It is the only published
# figure that exercises the condition this whole milestone varies, so it is what
# stands between a mis-scaled DGP and a grid whose leptokurtic cells nobody
# should believe.
#
# Leg 2, against this repo: the gaussian cells have a normal residual either
# way, so M118 and the committed M111 grid are two independent Monte-Carlo
# estimates of the SAME quantity. Disagreement beyond noise would mean the
# shipped reducers and M111's prototypes diverge -- which is the falsifier the
# plan gate named when it chose the shipped reducers.
#
# Two things this script does NOT do, both deliberate:
#   - it compares the MEDIAN OF PER-REP RATIOS, not the ratio of medians. They
#     differ by more than the discrepancy being bounded (~0.008 at cell 222 vs a
#     ~0.005 typical discrepancy), and the median of ratios is the statistic W1
#     is read against.
#   - it combines BOTH runs' bootstrap SEs. The reference is itself an estimate,
#     so a one-sample SE understates the error of the difference by sqrt(2),
#     turning a nominal 3-sigma bound into an effective 2.12 sigma -- about a
#     42% chance that at least one of 16 cells trips a precondition that means
#     "this grid is defective".
#
# Run: Rscript data-raw/m118-anchor-checks.R

stopifnot("run this from the repo root" = file.exists("DESCRIPTION"))
suppressMessages(source("data-raw/m118-width-reversal-sweep.R"))

tab <- readRDS("data-raw/m118-width-reversal-results.rds")$table
set.seed(118L)
n_boot <- 2000L
boot_se_median <- function(x) {
  stats::sd(replicate(
    n_boot,
    stats::median(x[sample.int(length(x), replace = TRUE)])
  ))
}

# --- leg 1: burch2011 p. 1027 -------------------------------------------------
a <- tab[tab$block == "anchor", ]
printed <- c(ratio = 0.88, burch_cov = 0.95, searle_cov = 0.97)
measured <- c(
  ratio = a$mean_ratio,
  burch_cov = a$burch_coverage,
  searle_cov = a$searle_coverage
)
tol <- c(ratio = 0.01, burch_cov = 0.015, searle_cov = 0.015)

cat(
  "Leg 1 -- burch2011 (p. 1027): k=100, n=5, rho=0.25, uniform both components\n"
)
cat(sprintf(
  "%-14s %10s %10s %10s %8s\n",
  "quantity",
  "measured",
  "printed",
  "gap",
  "tol"
))
for (q in names(printed)) {
  cat(sprintf(
    "%-14s %10.4f %10.4f %10.4f %8.3f\n",
    q,
    measured[[q]],
    printed[[q]],
    abs(measured[[q]] - printed[[q]]),
    tol[[q]]
  ))
}
stopifnot(
  "the burch2011 anchor is outside tolerance" = all(
    abs(measured - printed) <= tol
  )
)

# Burch's eq. 18 is a ratio of EXPECTED lengths, so the mean ratio is the
# comparable statistic here -- not the median one W1 uses.
cat("\n")

# --- leg 2: the committed M111 grid -------------------------------------------
cells <- build_cells()
g <- cells[cells$block == "m111" & cells$dist == "gaussian", ]
stopifnot("expected 16 gaussian M111-block cells" = nrow(g) == 16L)

wide <- readRDS("data-raw/m111-fallback-results.rds")$wide

cat(
  "Leg 2 -- gaussian M111-block cells vs data-raw/m111-fallback-results.rds\n"
)
cat(
  "median per-replicate burch/searle width ratio; SE is two-sample bootstrap\n\n"
)
cat(sprintf(
  "%5s %4s %2s %10s %10s %10s %9s %7s\n",
  "rho",
  "k",
  "n",
  "M118",
  "M111",
  "diff",
  "2s SE",
  "x SE"
))

z <- numeric(nrow(g))
for (i in seq_len(nrow(g))) {
  cell <- g[i, ]
  rr <- numeric(n_rep)
  for (rep in seq_len(n_rep)) {
    gr <- gen_oneway(
      cell$k,
      cell$n,
      cell$rho,
      cell$dist,
      cell$id * 1000000L + rep
    )
    ep <- endpoints_both(gr)
    rr[rep] <- (ep$burch[["upper"]] - ep$burch[["lower"]]) /
      (ep$searle[["upper"]] - ep$searle[["lower"]])
  }
  ref <- wide[
    wide$rho == cell$rho &
      wide$k == cell$k &
      wide$n == cell$n &
      wide$dist == "gaussian",
  ]
  rr_ref <- ref$burch_width / ref$searle_width
  rr_ref <- rr_ref[is.finite(rr_ref)]
  stopifnot("no matching M111 replicates for a cell" = length(rr_ref) > 0L)

  d <- stats::median(rr) - stats::median(rr_ref)
  se <- sqrt(boot_se_median(rr)^2 + boot_se_median(rr_ref)^2)
  z[i] <- d / se
  cat(sprintf(
    "%5.2f %4d %2d %10.4f %10.4f %+10.4f %9.4f %7.2f\n",
    cell$rho,
    cell$k,
    cell$n,
    stats::median(rr),
    stats::median(rr_ref),
    d,
    se,
    abs(z[i])
  ))
}

cat(sprintf("\nworst cell: %.2f SE (bound 3)\n", max(abs(z))))
# Reported, not asserted: the sign split is a weaker signal than any single
# cell's magnitude, and this grid cannot resolve an offset this small. Stating
# it beats claiming "no directional bias" from 16 cells.
cat(sprintf(
  "sign split: %d of %d negative, mean z = %+.2f\n",
  sum(z < 0),
  length(z),
  mean(z)
))
stopifnot(
  "a gaussian cell exceeds three two-sample bootstrap SEs" = all(abs(z) <= 3)
)

cat("\nOK: both anchors clear; the frozen W1-W3 rules may be read.\n")
