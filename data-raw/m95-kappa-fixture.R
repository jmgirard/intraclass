# data-raw/m95-kappa-fixture.R
#
# M95 T1: write the committed whole-table fixture behind the kappa_m pin in
# tests/testthat/test-ci-mpl.R (M95 AC1-AC3).
#
# This script CALIBRATES NOTHING and never reads R/sysdata.rda as its source.
# Every kappa_m it writes is copied from the COMMITTED CALIBRATION fixtures --
# the same provenance chain the shipped table was assembled from
# (data-raw/m91-mpl-kappa-sysdata.R):
#   conf_level 0.95  <- data-raw/m88-kappa-table.rds   (M88; D-015, GO at D-014)
#   conf_level 0.90  <- data-raw/m90-kappa-tables.rds  (M90; BC1 external oracle)
#   conf_level 0.99  <- data-raw/m90-kappa-tables.rds  (M90; simulated coverage)
# The shipped table (R/sysdata.rda) enters only as the thing VERIFIED: each
# level slice assembled here is stopifnot()-identical() to the shipped slice,
# so the fixture traces to the calibration evidence rather than to a copy of
# the object it pins (M95 AC3).
#
# Output: tests/testthat/fixtures/kappa-m-table.txt -- a human-readable TSV,
# one row per (n_r, n_s, conf_level) node. kappa_m is carried twice: as a C99
# hex float (%a, the column the pin reads -- R's decimal parser R_strtod can
# land 1 ulp off a 17-digit decimal, measured on 31 of these 162 values, while
# the hex representation is the double's bits verbatim) and as %.17g decimal
# for the human reader (informational only). conf_level is %.2f (the three
# levels are the doubles nearest 0.90/0.95/0.99, which %.2f re-parses to the
# same bits). The round trip is not assumed: the script re-reads the file it
# wrote and stopifnot()s identical() on every column (M95 AC1).
# data-raw/ is .Rbuildignore'd, which is why the fixture lives under tests/
# rather than being read from the calibration fixtures in place.
#
# Run (seconds -- pure assembly):
#   Rscript data-raw/m95-kappa-fixture.R

src_095 <- "data-raw/m88-kappa-table.rds"
src_new <- "data-raw/m90-kappa-tables.rds"
out_path <- "tests/testthat/fixtures/kappa-m-table.txt"

for (p in c(src_095, src_new)) {
  if (!file.exists(p)) {
    stop(sprintf("kappa_m calibration fixture not found: %s", p), call. = FALSE)
  }
}

fx_095 <- readRDS(src_095)
fx_new <- readRDS(src_new)

slices <- list(
  list(conf = 0.90, tbl = fx_new$tables[["0.90"]]),
  list(conf = 0.95, tbl = fx_095$kappa_m_table),
  list(conf = 0.99, tbl = fx_new$tables[["0.99"]])
)

fixture <- do.call(
  rbind,
  lapply(slices, function(s) {
    data.frame(
      n_r = as.integer(s$tbl$n_r),
      n_s = as.integer(s$tbl$n_s),
      conf_level = s$conf,
      kappa_m = as.numeric(s$tbl$kappa_m),
      stringsAsFactors = FALSE
    )
  })
)
fixture <- fixture[order(fixture$conf_level, fixture$n_r, fixture$n_s), ]
rownames(fixture) <- NULL

# --- AC3: each assembled level slice is identical() to the SHIPPED slice ------
# Loaded from R/sysdata.rda for verification only; the values written above
# never pass through it.
shipped_env <- new.env()
load("R/sysdata.rda", envir = shipped_env)
shipped <- shipped_env$kappa_m_table
shipped <- shipped[order(shipped$conf_level, shipped$n_r, shipped$n_s), ]
rownames(shipped) <- NULL
for (lv in c(0.90, 0.95, 0.99)) {
  fx_slice <- fixture[abs(fixture$conf_level - lv) < 1e-8, ]
  sh_slice <- shipped[abs(shipped$conf_level - lv) < 1e-8, ]
  rownames(fx_slice) <- NULL
  rownames(sh_slice) <- NULL
  stopifnot(
    nrow(fx_slice) > 0L,
    identical(fx_slice$n_r, sh_slice$n_r),
    identical(fx_slice$n_s, sh_slice$n_s),
    identical(fx_slice$conf_level, sh_slice$conf_level),
    identical(fx_slice$kappa_m, sh_slice$kappa_m)
  )
}
stopifnot(identical(nrow(fixture), nrow(shipped)))

# --- Write the fixture ---------------------------------------------------------
header <- c(
  "# kappa-m-table.txt -- whole-table pin fixture for the shipped kappa_m_table",
  "# (M95 AC1). Source: data-raw/m88-kappa-table.rds (0.95) and",
  "# data-raw/m90-kappa-tables.rds (0.90/0.99), the committed calibration",
  "# fixtures; generator: data-raw/m95-kappa-fixture.R (deterministic assembly,",
  "# no seed). kappa_m is the bit-exact value (C99 hex float, what the pin",
  "# reads); kappa_m_dec is the same double printed %.17g for the human reader",
  "# (informational only -- R's decimal parser lands 1 ulp off on 31 of these",
  "# 162 values). The generator",
  "# asserts a bit-identical write->read round trip and that every level slice",
  "# is identical() to the shipped table. Do not hand-edit: any change to any",
  "# cell of the shipped table goes through recalibration (D-015/D-017), then",
  "# this file is regenerated.",
  paste("n_r", "n_s", "conf_level", "kappa_m", "kappa_m_dec", sep = "\t")
)
rows <- sprintf(
  "%d\t%d\t%.2f\t%s\t%.17g",
  fixture$n_r,
  fixture$n_s,
  fixture$conf_level,
  sprintf("%a", fixture$kappa_m),
  fixture$kappa_m
)
writeLines(c(header, rows), out_path)

# --- AC1: bit-identical write -> read round trip --------------------------------
reread <- utils::read.table(
  out_path,
  header = TRUE,
  sep = "\t",
  comment.char = "#",
  colClasses = c("integer", "integer", "numeric", "character", "character")
)
stopifnot(
  identical(reread$n_r, fixture$n_r),
  identical(reread$n_s, fixture$n_s),
  identical(reread$conf_level, fixture$conf_level),
  identical(as.numeric(reread$kappa_m), fixture$kappa_m)
)

# The "31 of these 162 values" in the headers above is measured, never
# asserted from memory (the first draft said 10, which was the 0.95 slice
# alone -- M95 review finding 2): count the values whose %.17g decimal does
# not survive R's parser, and fail loudly if the headers have gone stale.
n_drift <- sum(as.numeric(sprintf("%.17g", fixture$kappa_m)) != fixture$kappa_m)
stopifnot(identical(n_drift, 31L))

cat(sprintf(
  "wrote %s: %d rows, %d per level; round trip identical() on all columns\n",
  out_path,
  nrow(fixture),
  nrow(fixture) / 3L
))
