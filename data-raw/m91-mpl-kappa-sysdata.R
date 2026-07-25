# data-raw/m91-mpl-kappa-sysdata.R
#
# M91 T3: assemble the conf_level-keyed kappa_m table shipped as internal package
# data (R/sysdata.rda) behind ci_method = "mpl", replacing M88's 0.95-only table.
#
# This script CALIBRATES NOTHING. Every kappa_m it ships is copied verbatim from a
# committed calibration fixture, so each shipped number traces to the run whose
# coverage was validated (M91 plan gate, 2026-07-24):
#   conf_level 0.95  <- data-raw/m88-kappa-table.rds   (M88; D-015, GO at D-014)
#   conf_level 0.90  <- data-raw/m90-kappa-tables.rds  (M90; BC1 external oracle)
#   conf_level 0.99  <- data-raw/m90-kappa-tables.rds  (M90; simulated coverage)
# Rejected at the plan gate: a monotone envelope or smoother over the tables' S
# dips. It would only ever widen intervals, but the shipped numbers would then be
# values no calibration run produced and M90's coverage sweep would no longer be
# evidence about them; the dips are documented in R/ci-mpl.R instead. Promoting
# an envelope stays a ROADMAP candidate.
#
# Schema (long, one row per (R, S, conf_level) node):
#   n_r, n_s, conf_level, kappa_m
# Long format keeps one object and one lookup rule: slice by (n_r, conf_level),
# interpolate linearly in S. All three levels share the same 9 x 6 grid
# (R = 2:10 x S = {10,15,20,30,50,100}) -- asserted below, since a lookup that
# silently fell back to another level's nodes would be a calibration error.
#
# Run (seconds -- pure assembly):
#   Rscript data-raw/m91-mpl-kappa-sysdata.R
# Writes R/sysdata.rda (via usethis::use_data(internal = TRUE)) and
# data-raw/m91-kappa-table.rds (the assembled table + provenance `meta`).

src_095 <- "data-raw/m88-kappa-table.rds"
src_new <- "data-raw/m90-kappa-tables.rds"

for (p in c(src_095, src_new)) {
  if (!file.exists(p)) {
    stop(sprintf("kappa_m fixture not found: %s", p), call. = FALSE)
  }
}

fx_095 <- readRDS(src_095)
fx_new <- readRDS(src_new)

slices <- list(
  list(conf = 0.90, tbl = fx_new$tables[["0.90"]], src = src_new),
  list(conf = 0.95, tbl = fx_095$kappa_m_table, src = src_095),
  list(conf = 0.99, tbl = fx_new$tables[["0.99"]], src = src_new)
)

kappa_m_table <- do.call(
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
kappa_m_table <- kappa_m_table[
  order(kappa_m_table$conf_level, kappa_m_table$n_r, kappa_m_table$n_s),
]
rownames(kappa_m_table) <- NULL

# --- Assembly invariants (a wrong slice must not ship silently) --------------
# 1. Identical (R, S) grid at every level.
grids <- lapply(split(kappa_m_table, kappa_m_table$conf_level), function(d) {
  paste(d$n_r, d$n_s, sep = "-")
})
stopifnot(length(unique(lapply(grids, sort))) == 1L)
# 2. The 0.95 slice is byte-identical to the shipped M88 values (no regression).
old_095 <- fx_095$kappa_m_table
old_095 <- old_095[order(old_095$n_r, old_095$n_s), ]
new_095 <- kappa_m_table[kappa_m_table$conf_level == 0.95, ]
stopifnot(
  identical(new_095$kappa_m, as.numeric(old_095$kappa_m)),
  identical(new_095$n_r, as.integer(old_095$n_r)),
  identical(new_095$n_s, as.integer(old_095$n_s))
)
# 3. Every kappa_m is finite and non-negative (a correction, never a shrinkage).
stopifnot(all(is.finite(kappa_m_table$kappa_m)), all(kappa_m_table$kappa_m >= 0))

cat("== M91 T3: conf_level-keyed kappa_m table ==\n")
for (lv in sort(unique(kappa_m_table$conf_level))) {
  d <- kappa_m_table[kappa_m_table$conf_level == lv, ]
  cat(sprintf(
    "  conf_level %.2f: %d nodes, kappa_m %.3f-%.3f (source %s)\n",
    lv,
    nrow(d),
    min(d$kappa_m),
    max(d$kappa_m),
    if (lv == 0.95) src_095 else src_new
  ))
}

assembly <- list(
  kappa_m_table = kappa_m_table,
  meta = list(
    generator = "data-raw/m91-mpl-kappa-sysdata.R",
    role = "assembly only -- no calibration; every value copied from a committed fixture",
    sources = list(
      "0.90" = list(file = src_new, milestone = "M90", oracle = "BC1 published alpha=0.10 kappa_m + simulated coverage"),
      "0.95" = list(file = src_095, milestone = "M88", oracle = "simulated coverage (D-014 GO)"),
      "0.99" = list(file = src_new, milestone = "M90", oracle = "simulated coverage only (no external oracle)")
    ),
    schema = c("n_r", "n_s", "conf_level", "kappa_m"),
    lookup = "slice by (n_r, conf_level); linear interpolation in S; no extrapolation",
    interpolation_confirmed = "data-raw/m91-interp-sweep.rds (cells D1-D4)",
    date = "2026-07-24"
  )
)
saveRDS(assembly, "data-raw/m91-kappa-table.rds")
usethis::use_data(kappa_m_table, internal = TRUE, overwrite = TRUE)

cat(sprintf(
  "\nsaved data-raw/m91-kappa-table.rds + R/sysdata.rda (%d rows)\n",
  nrow(kappa_m_table)
))
