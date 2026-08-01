# data-raw/m96-sentinel-audit.R
#
# M96 T1 (AC1): retrospective audit of the four committed MPL sweep fixtures for
# the covering-sentinel defect this milestone removes. Before M96, the three
# sweep generators (m90-mpl-coverage-sweep.R, m91-mpl-interp-sweep.R,
# m92-mpl-095-interp-sweep.R) mapped a FAILED mpl_interval() fit to
# c(lower = 0, upper = 1) -- an interval that covers any rho in [0, 1], so a
# failed rep would have been scored as a covered replication and inflated the
# recorded coverage.
#
# This script scans the raw per-rep endpoints in each committed fixture for the
# sentinel signature `lower <= 0 & upper >= 1` and reports a count per fixture.
# The signature is an UPPER BOUND on handler hits: mpl_interval() itself clamps
# an endpoint to 0/1 when uniroot finds no crossing (the boundary-limit case,
# see the "uniroot boundary/failure conflation" candidate row in
# cairn/ROADMAP.md), so a rep where BOTH endpoints were genuinely clamped would
# also match. A count of zero therefore establishes that NO rep -- handler hit
# or double clamp -- was scored via the sentinel, which is what the
# frozen-fixtures decision (M96 plan gate, 2026-07-25) rests on.
#
# A non-zero count anywhere invalidates that decision: this script then exits
# non-zero, and the milestone stops for a gate amendment rather than absorbing
# the finding (AC1).
#
# Run (seconds, read-only):
#   Rscript data-raw/m96-sentinel-audit.R

fixtures <- c(
  "data-raw/m90-coverage-sweep.rds",
  "data-raw/m91-interp-sweep.rds",
  "data-raw/m92-interp-sweep.rds",
  "data-raw/m92-interp-sweep-run1-collided.rds"
)

total_reps <- 0L
total_sentinel <- 0L
cat("== M96 sentinel audit: lower <= 0 & upper >= 1 per committed fixture ==\n")
for (p in fixtures) {
  if (!file.exists(p)) {
    stop(sprintf("fixture not found: %s", p), call. = FALSE)
  }
  fx <- readRDS(p)
  stopifnot(is.list(fx$raw), length(fx$raw) > 0L)
  n_rep <- 0L
  n_sent <- 0L
  for (cell in names(fx$raw)) {
    r <- fx$raw[[cell]]
    stopifnot(all(c("lower", "upper") %in% names(r)))
    hit <- r$lower <= 0 & r$upper >= 1
    n_rep <- n_rep + nrow(r)
    n_sent <- n_sent + sum(hit)
    if (any(hit)) {
      cat(sprintf(
        "  !! %s cell %s: %d sentinel rep(s) at rows %s\n",
        p,
        cell,
        sum(hit),
        paste(which(hit), collapse = ", ")
      ))
    }
  }
  cat(sprintf(
    "  %-45s cells %2d  reps %5d  sentinel %d\n",
    basename(p),
    length(fx$raw),
    n_rep,
    n_sent
  ))
  total_reps <- total_reps + n_rep
  total_sentinel <- total_sentinel + n_sent
}
cat(sprintf(
  "== total: %d reps scanned, %d sentinel hits ==\n",
  total_reps,
  total_sentinel
))
if (total_sentinel > 0L) {
  stop(
    "sentinel reps found: the frozen-fixtures decision (M96 plan gate, ",
    "2026-07-25) is invalidated -- stop for a gate amendment (AC1).",
    call. = FALSE
  )
}
cat("clean: no committed fixture scored a rep via the covering sentinel.\n")
