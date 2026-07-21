# M75 T1 — prototype-parity oracle fixture for the exported `npbootstrap` reducer.
#
# Regenerates `tests/testthat/fixtures/npbootstrap-parity-oracle.rds` (AC2/BC2):
# a handful of committed one-way datasets plus the RR01-verified prototype's
# transformed bootstrap-t endpoints on each, at a fixed resample seed and count.
# The exported reducer (`R/ci-npbootstrap.R`, via `icc(ci_method = "npbootstrap")`)
# must reproduce these endpoints to >= 4 dp -- it ports the same procedure, so the
# resample stream is identical given the seed. `data-raw/` is .Rbuildignore'd, so
# the committed .rds (not this script) is what the installed-package test reads.
#
# Provenance: source = the committed prototype `m62-npbootstrap-prototype.R`
# (RR01-verified) + `sim_oneway()` at the seeds below; generator = this script;
# seeds = per entry. Deterministic. Run: `Rscript data-raw/m75-npbootstrap-parity-oracle.R`.

source("data-raw/m62-npbootstrap-prototype.R")

# A small spread of cells: an interior cell, a small-k cell, and a near-zero-rho
# corner (where the transform is most exercised). Distinct data seeds per cell.
cells <- list(
  list(k = 30, n = 4, rho = 0.50, data_seed = 101L),
  list(k = 12, n = 4, rho = 0.20, data_seed = 202L),
  list(k = 10, n = 10, rho = 0.05, data_seed = 303L)
)
boot_seed <- 4242L
n_boot <- 500L

entries <- lapply(cells, function(cl) {
  d <- sim_oneway(cl$k, cl$n, cl$rho, seed = cl$data_seed)
  # The exported reducer consumes `score`; the prototype consumes `y`. Same values.
  d$score <- d$y
  out <- npboot_oneway(d, n_boot = n_boot, seed = boot_seed)
  list(
    cell = cl,
    boot_seed = boot_seed,
    n_boot = n_boot,
    data = d[, c("subject", "rater", "score")],
    # The PRIMARY oracle: the prototype's transformed bootstrap-t ICC(1) endpoints.
    boott_icc1 = out$boott_transformed
  )
})

attr(entries, "provenance") <- paste(
  "M75 T1 prototype-parity oracle. source: data-raw/m62-npbootstrap-prototype.R",
  "(RR01-verified) + sim_oneway() at per-entry data_seed; generator:",
  "data-raw/m75-npbootstrap-parity-oracle.R; boot_seed 4242, n_boot 500.",
  "Regenerate with that script."
)

saveRDS(entries, "tests/testthat/fixtures/npbootstrap-parity-oracle.rds")
cat("wrote tests/testthat/fixtures/npbootstrap-parity-oracle.rds\n")
