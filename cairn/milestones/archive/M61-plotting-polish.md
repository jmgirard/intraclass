# M61: Plotting polish — cohesive theme, palette, labels (done 2026-07-17)

**Goal:** the three autoplot/plot views (coefficient forest, component bars, d-study
curve) read as one polished system — theme, palette, labels — no new export or dep.

**Shipped (PR #67, squash 1e5c729):**
- `R/autoplot-theme.R`: internal `icc_theme()` (minimal base, bold plot-aligned
  title, no minor grid, suppressed redundant legends) + Okabe–Ito `icc_palette()`,
  applied to all three views. Internal-only; ggplot2 stays Suggests (ADR-010).
- Value labels on coefficient points + component bars; palette component fills;
  multilevel views colour/facet by level.
- Bug fix: `autoplot.icc_dstudy` drew overlaid curves as one ungrouped line (a
  sawtooth — latent since ADR-054 made `type` a default vector). Now grouped by
  every curve-identity column (type AND, for replicates, occasions) except the
  x-axis, faceted by level, with a legend.
- +11 structural/guard tests (theme fingerprint, palette fills, label==source,
  Suggests guard, anti-sawtooth group-counts); ADR-020 no-snapshot doctrine kept.
  Reproducible previews: `data-raw/plot-previews.R`.

**Decisions:** internal-only (exported `theme_intraclass()` → candidate); no
vdiffr (ADR-020); AC5 = render script + sign-off, not PNGs. Under IP3 (no
magnitude cues), GP1, GP2.

**Review:** three-lens; 1 finding (replicate-occasions sawtooth) reproduced +
fixed in-review (3c937bd). Suite 1798 pass/0 fail; CI green all platforms.
