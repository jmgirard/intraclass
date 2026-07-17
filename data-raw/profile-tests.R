# profile-tests.R --- per-file wall-clock profile of the testthat suite (M59).
# ===========================================================================
# A developer profiling helper, not a shipped artifact (data-raw is
# .Rbuildignore'd). It times each test file under a FIXED, reproducible
# condition so the M59 before/after comparison is meaningful:
#
#   NOT_CRAN=true  -> run the skip_on_cran heavy blocks (the whole point).
#   CI=true        -> skip the skip_on_ci live-Stan brms fits (no local Stan
#                     toolchain; those are fixture-backed and measured
#                     elsewhere).
#
# Wall-clock is machine-dependent; the RELATIVE per-file share and the
# before/after delta on ONE machine are the signal, not the absolute seconds.
# Run from the package root:  Rscript data-raw/profile-tests.R
#
# Plan-time baseline captured 2026-07-17 (M59 work log): ~415 s total, with
# test-icc-lavaan-multilevel.R (126 s), test-ci-bootstrap.R (125 s), and
# test-d-study.R (90 s) accounting for ~82% of it.

Sys.setenv(NOT_CRAN = "true", CI = "true")
suppressMessages(devtools::load_all(quiet = TRUE))

files <- list.files("tests/testthat", pattern = "^test-.*\\.R$", full.names = TRUE)
res <- data.frame(file = basename(files), sec = NA_real_)

for (i in seq_along(files)) {
  elapsed <- system.time(
    suppressMessages(suppressWarnings(
      try(testthat::test_file(files[i], reporter = "silent"), silent = TRUE)
    ))
  )[["elapsed"]]
  res$sec[i] <- round(as.numeric(elapsed), 1)
}

res <- res[order(-res$sec), ]
print(res, row.names = FALSE)
cat("TOTAL:", round(sum(res$sec), 1), "sec\n")
