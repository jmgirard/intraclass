# Derive the committed fixture behind the documented skew/kurtosis caveat.
#
# PROVENANCE. The caveat shipped by M115 states figures a user reads in
# `?icc`, the interval-methods vignette and NEWS. Those figures were MEASURED
# by two earlier assessments, whose per-cell artifacts already live here:
#
#   data-raw/m113-skew-response-coverage.tsv  (M113; 64 cells x 3 methods,
#       n_rep = 2000) -- one row per (rho, k, n, dist, method) with the
#       abort count and both coverage readings.
#   data-raw/m114-warn-trigger-stats.tsv      (M114; per-rep) -- the
#       held-out battery, whose `source == "heldout"` rows carry the
#       lognormal/laplace cells the M113 grid does not.
#
# Neither ships in the built package (`.Rbuildignore` excludes `data-raw`), so
# a test reading them directly is skipped under `R CMD check` and the caveat's
# figures would go unpinned on every pull request. This script reduces both to
# ONE small fixture under `tests/testthat/fixtures/`, which does ship, so
# `tests/testthat/test-doc-skew-caveat.R` can hold the documented figures to
# the measurement wherever it runs.
#
# It derives; it measures nothing new. Every value it writes is either copied
# from an M113 row or counted from M114 per-rep rows. `test-doc-skew-caveat.R`
# re-derives it from these same two sources when the source tree is present,
# so a hand edit to the fixture fails.
#
# Re-run (from the repo root; ~1 s):
#   Rscript data-raw/make-skew-undercoverage-fixture.R

m113_path <- "data-raw/m113-skew-response-coverage.tsv"
m114_path <- "data-raw/m114-warn-trigger-stats.tsv"
out_path <- "tests/testthat/fixtures/skew-undercoverage.tsv"

stopifnot(file.exists(m113_path), file.exists(m114_path))

m113 <- utils::read.delim(m113_path, stringsAsFactors = FALSE)

# Leg 1 -- the M113 grid, carried through unchanged but narrowed to the
# columns the caveat and its test actually read. `abort_rate` is derived here
# rather than in the test so the fixture is self-describing.
grid <- data.frame(
  source = "m113",
  rho = m113$rho,
  k = m113$k,
  n = m113$n,
  dist = m113$dist,
  method = m113$method,
  n_rep = m113$n_rep,
  abort_rate = m113$n_abort / m113$n_rep,
  coverage_uncond = m113$coverage_uncond,
  coverage_nonabort = m113$coverage_nonabort,
  stringsAsFactors = FALSE
)

# Leg 2 -- the M114 held-out battery, counted from per-rep rows. Only the
# Monte-Carlo default was run there, so `method` is "mc" throughout and
# `coverage_uncond` counts a covering non-aborted rep against every rep.
m114 <- utils::read.delim(m114_path, stringsAsFactors = FALSE)
heldout <- m114[m114$source == "heldout", , drop = FALSE]
stopifnot(nrow(heldout) > 0L)

cell_key <- interaction(
  heldout$rho,
  heldout$k,
  heldout$n,
  heldout$dist,
  drop = TRUE,
  sep = "\r"
)
held <- do.call(
  rbind,
  lapply(split(heldout, cell_key), function(cell) {
    aborted <- cell$mc_aborted %in% c("TRUE", TRUE)
    covered <- cell$mc_covered %in% c("TRUE", TRUE)
    n_rep <- nrow(cell)
    n_ok <- sum(!aborted)
    data.frame(
      source = "m114-heldout",
      rho = cell$rho[1],
      k = cell$k[1],
      n = cell$n[1],
      dist = cell$dist[1],
      method = "mc",
      n_rep = n_rep,
      abort_rate = sum(aborted) / n_rep,
      coverage_uncond = sum(covered & !aborted) / n_rep,
      coverage_nonabort = sum(covered[!aborted]) / n_ok,
      stringsAsFactors = FALSE
    )
  })
)

fixture <- rbind(grid, held)
fixture <- fixture[
  order(
    fixture$source,
    fixture$dist,
    fixture$rho,
    fixture$k,
    fixture$n,
    fixture$method
  ),
]
rownames(fixture) <- NULL

# Hex floats would be overkill here: every value the caveat quotes is a
# ratio of small integers and round-trips through `%.10g` exactly. The
# provenance test asserts the round trip rather than assuming it.
utils::write.table(
  fixture,
  out_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

message("wrote ", out_path, ": ", nrow(fixture), " rows")
