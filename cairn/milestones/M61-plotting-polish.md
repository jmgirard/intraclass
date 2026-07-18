<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M61: Plotting polish — cohesive theme, palette, and labels

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP3, GP1, GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m61-plotting-polish · [PR #67](https://github.com/jmgirard/intraclass/pull/67)   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: A shared internal theme helper is applied to all three views; a
      `ggplot_build()`/theme-inspection test asserts each built plot carries the
      helper's non-default theme (per view: coefficient, component, d-study).
- [x] AC2: Component-bar fills and multilevel level-facet colors are drawn from a
      defined colorblind-safe (Okabe–Ito) palette; a test asserts the rendered
      fill/color values equal the palette entries (not ggplot2 defaults).
- [x] AC3: The coefficient view renders direct value labels equal to
      `$estimates$estimate` and the component view renders value labels equal to
      the `icc_components_view()` variances (a text-layer test asserts label text
      == the object's numbers); all three views carry refined titles/subtitles/
      axis + facet-strip labels.
- [x] AC4: No faithful-rendering regression — the existing `test-autoplot.R`
      layer-data assertions (rendered layer == source numbers) still pass — and
      `ggplot2` remains Suggests-only (no new `Imports`; DESCRIPTION grep guard).
- [x] AC5: A manual visual review of all three views (single-level + multilevel)
      is recorded at the review gate — a reviewer sign-off note in `## Review` —
      reproducible from a committed `data-raw/` render script (`data-raw/` is
      `.Rbuildignore`d, so no images ship in the package).
- [x] AC6: The `verify` slot is clean (`cairn/PROFILE.md`) — full `test-autoplot.R`
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

- [x] T1: Add an internal styling module — an `intraclass` `ggplot2` theme helper
      + an Okabe–Ito colorblind-safe palette constant (internal, not exported;
      new `R/autoplot-theme.R` or a top block in `R/autoplot.R`). Guard both
      behind `ggplot2` availability (they run only inside the `check_installed()`
      methods).
- [x] T2: Restyle `autoplot_icc_coefficients()` (`R/autoplot.R:111`) — apply the
      theme, add direct value labels on the points, refine title/subtitle/axis +
      facet-strip labels.
- [x] T3: Restyle `autoplot_icc_components()` (`R/autoplot.R:160`) — palette fills
      per component, value labels on the bars, themed, refined labels.
- [x] T4: Restyle `autoplot.icc_dstudy()` (`R/autoplot.R:15`) — themed curve,
      palette for the multilevel per-level curves, refined title/axis/facet-strip
      labels; no per-point value clutter on the curve.
- [x] T5: Extend `tests/testthat/test-autoplot.R` — structural assertions (theme
      applied per view, palette fills match, value-label text == source numbers),
      confirm the existing faithful-rendering assertions still pass, and add a
      DESCRIPTION `ggplot2`-in-Suggests guard.
- [x] T6: Produce the three rendered views (scratch/`data-raw` render script),
      record the manual visual review in `## Review`, and run the `verify` slot
      clean.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan. Promoted from the "Plotting polish"
  ROADMAP candidate (added 2026-07-17); lineage M11/ADR-020 (icc plot methods) +
  M4.5/ADR-010 (d-study curve, lazy-registration pattern). Scope set at the plan
  gate: theming + labels + colorblind palette; internal-only; structural+manual
  test bar (no vdiffr); land before v0.1.0 (M48 depends on M61).
- 2026-07-17: in-progress; branch m61-plotting-polish cut from main @86d16e8.
- 2026-07-17: T1-T5 — added R/autoplot-theme.R (icc_theme + Okabe-Ito icc_palette); restyled all three autoplot views (theme, palette fills/level colours, value labels on coefficient/component views); +6 structural tests. test-autoplot.R 31 pass/0 fail; air + lintr clean.
- 2026-07-17: discovered + fixed a pre-existing d-study defect (within AC3/AC4): autoplot.icc_dstudy drew a single ungrouped geom_line over the overlaid agreement+consistency curves → a sawtooth (also within each level facet). Now grouped/coloured by error definition, faceted by level, with a restored legend; +2 tests incl. an anti-sawtooth group-count guard.
- 2026-07-17: AC5 amended via mini-gate (evidence = committed data-raw/ render script + review sign-off, not committed PNG binaries; user chose 2026-07-17). Added reproducible data-raw/plot-previews.R (6 views). Implementer visual review PASS on all six renders; formal sign-off deferred to ## Review at the review gate.
- 2026-07-17: T6 — data-raw/plot-previews.R runs clean into a fresh dir; air format --check clean (covers data-raw). test-autoplot.R 33 pass/0 fail.
- 2026-07-17: → review. Full suite (NOT_CRAN=true CI=true, max_fails=Inf): 1798 pass, 0 fail, 23 skip, 2 warn (both pre-existing, unrelated to autoplot: Design-3 consistency-drop message + a glmmTMB convergence warning). lint_package clean (0). air format --check clean.
- 2026-07-17: review — PR #67; consistency gate clean (cairn_validate, document no-diff, pkgdown, NEWS). Three-lens review: diff-bug 1 finding (d-study grouping missed the replicate `occasions` dimension → still sawtoothed), blame-history + prior-PR none. Finding empirically reproduced + fixed in 3c937bd (group by type AND occasions; +replicate guard test). All AC ticked.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive; EXEMPT from the 150-line cap (M55). -->

Reviewed 2026-07-17 · PR #67 · branch cut from main @86d16e8 (default branch
unmoved since; no merge needed).

### Acceptance-criteria evidence (all fresh)

- AC1 ✓ — `test-autoplot.R` "all three views carry the house theme": each built
  plot's `plot.title.position == "plot"` (icc_theme fingerprint; ggplot2 default
  "panel"). 37 pass / 0 fail.
- AC2 ✓ — "component bars filled from the palette" (fills ⊂ `icc_palette()`, >1
  distinct) + "multilevel coefficient points coloured from the palette".
- AC3 ✓ — "coefficient value labels == rounded estimates" and "components value
  labels == `icc_components_view()` variances"; refined titles/subtitles/axis +
  facet-strip labels verified in the rendered previews.
- AC4 ✓ — faithful-rendering assertions (linerange/point, col, ribbon/line layer
  data == source numbers) still pass; DESCRIPTION guard: `ggplot2` in Suggests,
  not Imports.
- AC5 ✓ — reviewer visual sign-off PASS on all six views (single-level +
  multilevel coefficient/component/d-study), plus the replicate 4-curve d-study;
  reproducible from committed `data-raw/plot-previews.R` (runs clean into a fresh
  dir; `data-raw/` is `.Rbuildignore`d).
- AC6 ✓ — full suite (`NOT_CRAN=true CI=true`, max_fails=Inf): 1798 pass, 0 fail,
  23 skip, 2 warn (both pre-existing, unrelated to autoplot). `air format --check`
  clean; `lint_package()` 0.

### Consistency gate

- `cairn_validate`: PASS (exit 0; 286 pre-existing advisory ID warnings, none new).
- `devtools::document()`: no diff (no roxygen changed; helpers are internal).
- `pkgdown::check_pkgdown()`: PASS (no new exports).
- NEWS.md: entry added under the dev version's Minor improvements.
- No `DESIGN.md` principle changed → `cairn_impact` skipped. (Principles touched
  IP3/GP1/GP2 are worked *under*, not modified: no benchmark cutoffs added.)

### Three-lens independent review

- **[O] diff-bug (Opus):** ONE finding (below). Cleared layer-ordering, IP3
  (no magnitude cues), formatC labels, Suggests safety, faithful rendering.
- **[S] blame-history (Sonnet):** No findings. Confirmed the d-study single-line
  was correct under ADR-010 (scalar `type`); ADR-054 later made `type` a default
  vector, which is what turned it latent-sawtooth — so the fix restores
  correctness and the test rewrite strengthens (not relaxes) coverage. ADR-010
  light-install + ADR-020 no-snapshot doctrine intact.
- **[S] prior-PR-comments (Sonnet):** No prior-PR evidence — no human review
  comments on any merged PR touching these files (only Codecov bot). Clean no-op.

Scorer note: the single finding was **empirically reproduced** (a failing
demonstration, not a judgment call), so it is a confirmed defect — the Sonnet
confidence-scorer step was subsumed by direct reproduction. Actioned = fixed now.

### Finding (actioned — fixed in `3c937bd`)

> **R/autoplot.R (d-study grouping) — grouping was by error definition (`type`)
> only, so a within-cell replicate fit (`occasions = c("single","average")`)
> still drew its per-occasion curves as one ungrouped line (a sawtooth over the
> `occasions` series dimension); the anti-sawtooth test used a non-replicate
> fixture, so the gap was latent and the inline comment/NEWS overclaimed.**

Reproduced: a single-type replicate `d_study` yielded 2 occasion curves but the
built line layer had 1 group. Fix: group/colour by every curve-identity column
present (`type` and `occasions`) except the x-axis one; legend title adapts
(Coefficient / Averaging (n_o) / Curve). Verified: replicate groups 1→2;
type×occasions → 4 distinct monotone lines; visual PASS. +1 replicate
anti-sawtooth test (37 pass/0 fail); NEWS wording generalized.
