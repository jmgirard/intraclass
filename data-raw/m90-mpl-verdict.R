# data-raw/m90-mpl-verdict.R
#
# M90 T4 (RR03/D-017): apply the frozen pre-registration criterion to the T3
# coverage sweep and render a per-level GO/NO-GO verdict for conf_level 0.90 / 0.99.
# This script applies the criterion; it measures nothing (GP5 separation).
#
# Criterion (frozen in cairn/references/mpl-twoway-random-comparison.md):
#   BC3  per-cell floor: empirical coverage >= 0.88 at 0.90; >= 0.98 at 0.99.
#        Over-coverage passes.
#   BC4  n_rep as run; report exact Clopper-Pearson 95% CI per cell.
#   BC7  GO at a level iff the floor holds at EVERY cell C1-C8 AND BC1 (T2) passed
#        AND BC2 (T2, 0.99 only) passed. A level's NO-GO routes it to a candidate
#        row without blocking the other. No level deeper than 0.99 authorized.
#   BC6  flag any cell whose median 0.99-interval width >= 0.90 (M91 doc duty).
#
# Run: Rscript data-raw/m90-mpl-verdict.R  (fast; reads fixtures)
# Writes data-raw/m90-verdict.rds.

sweep_path <- "data-raw/m90-coverage-sweep.rds"
tbl_path <- "data-raw/m90-kappa-tables.rds"
out_path <- "data-raw/m90-verdict.rds"
for (p in c(sweep_path, tbl_path)) {
  if (!file.exists(p)) stop(sprintf("missing fixture %s -- run T2/T3 first.", p), call. = FALSE)
}
sw <- readRDS(sweep_path)$summary
fx <- readRDS(tbl_path)

floors <- c("0.90" = 0.88, "0.99" = 0.98)
sw$floor <- floors[sw$level]
sw$cell_pass <- sw$coverage >= sw$floor

cat("== M90 verdict: per-cell coverage vs BC3 floor ==\n")
for (i in seq_len(nrow(sw))) {
  cat(sprintf("  %s %s: cov=%.4f [%.4f,%.4f] floor=%.2f  %s%s\n",
    sw$level[i], sw$id[i], sw$coverage[i], sw$cp_lo[i], sw$cp_hi[i], sw$floor[i],
    if (sw$cell_pass[i]) "PASS" else "FAIL",
    if (sw$level[i] == "0.99" && sw$width_med[i] >= 0.90)
      sprintf("  [BC6 wide: w50=%.2f]", sw$width_med[i]) else ""))
}

bc1_pass <- isTRUE(fx$bc1_pass)
bc2_pass <- isTRUE(fx$bc2_pass)

verdict <- lapply(names(floors), function(lv) {
  cells_lv <- sw[sw$level == lv, ]
  cover_ok <- all(cells_lv$cell_pass)
  # BC7: 0.90 gates on BC1 + its own coverage; 0.99 also on BC2.
  go <- cover_ok && bc1_pass && (lv == "0.90" || bc2_pass)
  wide <- cells_lv[lv == "0.99" & cells_lv$width_med >= 0.90, "id"]
  list(
    level = lv, go = go, cover_ok = cover_ok,
    failed_cells = cells_lv$id[!cells_lv$cell_pass],
    bc1_pass = bc1_pass, bc2_pass = if (lv == "0.99") bc2_pass else NA,
    wide_cells = if (length(wide)) wide else character(0),
    min_coverage = min(cells_lv$coverage)
  )
})
names(verdict) <- names(floors)

cat("\n== GO/NO-GO (BC7) ==\n")
for (lv in names(verdict)) {
  v <- verdict[[lv]]
  cat(sprintf("  conf_level %s: %s  (coverage_ok=%s, BC1=%s%s; min cov %.4f%s)\n",
    lv, if (v$go) "GO" else "NO-GO",
    v$cover_ok, v$bc1_pass,
    if (lv == "0.99") sprintf(", BC2=%s", v$bc2_pass) else "",
    v$min_coverage,
    if (length(v$failed_cells)) sprintf("; failed: %s", paste(v$failed_cells, collapse = ",")) else ""))
}
cat("  (No level deeper than 0.99 is authorized by RR03/D-017.)\n")

saveRDS(list(verdict = verdict, sweep = sw, bc1_pass = bc1_pass, bc2_pass = bc2_pass,
  floors = floors, meta = list(generator = "data-raw/m90-mpl-verdict.R", date = "2026-07-24")),
  out_path)
cat(sprintf("\nsaved %s\n", out_path))
