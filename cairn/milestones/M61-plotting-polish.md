<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M61: Plotting polish — cohesive theme, palette, and labels

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP3, GP1, GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Make the three `R/autoplot.R` views (coefficient forest, component bars, d-study
curve) read as one polished system — a shared internal theme, a colorblind-safe
palette, and clearer labels — without exporting new API or adding a hard dependency.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** an internal styling helper (an `intraclass`-flavoured `ggplot2` theme) +
a colorblind-safe palette (Okabe–Ito) applied across all three existing views
(`autoplot.icc` coefficient + component views, `autoplot.icc_dstudy`, and their
`plot()` wrappers); direct numeric value labels on the coefficient points and
component bars (rendering the object's exact numbers); refined titles/subtitles/
axis + facet-strip labels. Styling stays **internal-only** (no new export;
`s3_register` lazy pattern and ggplot2-in-Suggests unchanged, ADR-010). Verified
by `ggplot_build()` structural + faithful-rendering assertions (ADR-020) plus one
recorded manual visual review — not image snapshots.

**Out:**
- An **exported** user-facing `theme_intraclass()` → candidate row (plan gate
  2026-07-17 chose internal-only; promote on a concrete need).
- **New view types** beyond the current three (e.g. stacked variance-share) →
  candidate row. Multilevel views are *already* level-faceted (`facet_wrap` by
  level in both `autoplot.icc` and `autoplot.icc_dstudy`); this milestone themes
  them, it does not add a new display.
- **Benchmark / threshold reference lines** (e.g. reliability 0.7/0.8/0.9 as
  poor/good/excellent) → **refused permanently**, not deferred: IP3 ("which, not
  how good") bars qualitative-magnitude cues in output, not even opt-in.
- **`vdiffr` visual-regression snapshots** → not adopted: image snapshots are
  platform/font/version-fragile and cut against the ADR-020 test doctrine; a new
  Suggests dependency is not warranted for cosmetic polish (plan gate 2026-07-17).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A shared internal theme helper is applied to all three views; a
      `ggplot_build()`/theme-inspection test asserts each built plot carries the
      helper's non-default theme (per view: coefficient, component, d-study).
- [ ] AC2: Component-bar fills and multilevel level-facet colors are drawn from a
      defined colorblind-safe (Okabe–Ito) palette; a test asserts the rendered
      fill/color values equal the palette entries (not ggplot2 defaults).
- [ ] AC3: The coefficient view renders direct value labels equal to
      `$estimates$estimate` and the component view renders value labels equal to
      the `icc_components_view()` variances (a text-layer test asserts label text
      == the object's numbers); all three views carry refined titles/subtitles/
      axis + facet-strip labels.
- [ ] AC4: No faithful-rendering regression — the existing `test-autoplot.R`
      layer-data assertions (rendered layer == source numbers) still pass — and
      `ggplot2` remains Suggests-only (no new `Imports`; DESCRIPTION grep guard).
- [ ] AC5: A manual visual review of all three rendered views is recorded at the
      review gate (committed example renders + a reviewer sign-off note in
      `## Review`).
- [ ] AC6: The `verify` slot is clean (`cairn/PROFILE.md`) — full `test-autoplot.R`
      green, `air format --check` clean, `lintr` clean on `R/autoplot.R`.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number. Review reads to fence evidence. -->

- AC1 → T1, T2, T3, T4, T5
- AC2 → T1, T3, T4, T5
- AC3 → T2, T3, T4, T5
- AC4 → T5
- AC5 → T6
- AC6 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate -->

- [ ] T1: Add an internal styling module — an `intraclass` `ggplot2` theme helper
      + an Okabe–Ito colorblind-safe palette constant (internal, not exported;
      new `R/autoplot-theme.R` or a top block in `R/autoplot.R`). Guard both
      behind `ggplot2` availability (they run only inside the `check_installed()`
      methods).
- [ ] T2: Restyle `autoplot_icc_coefficients()` (`R/autoplot.R:111`) — apply the
      theme, add direct value labels on the points, refine title/subtitle/axis +
      facet-strip labels.
- [ ] T3: Restyle `autoplot_icc_components()` (`R/autoplot.R:160`) — palette fills
      per component, value labels on the bars, themed, refined labels.
- [ ] T4: Restyle `autoplot.icc_dstudy()` (`R/autoplot.R:15`) — themed curve,
      palette for the multilevel per-level curves, refined title/axis/facet-strip
      labels; no per-point value clutter on the curve.
- [ ] T5: Extend `tests/testthat/test-autoplot.R` — structural assertions (theme
      applied per view, palette fills match, value-label text == source numbers),
      confirm the existing faithful-rendering assertions still pass, and add a
      DESCRIPTION `ggplot2`-in-Suggests guard.
- [ ] T6: Produce the three rendered views (scratch/`data-raw` render script),
      record the manual visual review in `## Review`, and run the `verify` slot
      clean.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan. Promoted from the "Plotting polish"
  ROADMAP candidate (added 2026-07-17); lineage M11/ADR-020 (icc plot methods) +
  M4.5/ADR-010 (d-study curve, lazy-registration pattern). Scope set at the plan
  gate: theming + labels + colorblind palette; internal-only; structural+manual
  test bar (no vdiffr); land before v0.1.0 (M48 depends on M61).

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive; EXEMPT from the 150-line cap (M55). -->
