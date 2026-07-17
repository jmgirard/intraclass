# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-07-17 (M57 shipped + archived — lavaan fixed-rater crossed multilevel at both levels, PR #65; M59 rotated out under terminal-row retention; M58 sibling + fixed-bootstrap/plotting-polish candidates remain)_

Pre-migration history (M1–M47, ADR-001..058): see `cairn/legacy/` and git log.

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M48 | v0.1.0 release consolidation — CRAN submission-ready | planned | M49, M50, M51, M53, M54, M55 | high | milestones/M48-release-v010.md |
| M58 | Multilevel SEM (lavaan) — incomplete / unbalanced random design | in-progress | — | normal | milestones/M58-lavaan-multilevel-incomplete.md |
| M57 | Multilevel SEM (lavaan) — fixed-rater crossed design | done | — | normal | milestones/archive/M57-lavaan-multilevel-fixed.md |
| M60 | Freeze the lavaan multilevel recovery sweep | done | — | normal | milestones/archive/M60-freeze-lavaan-recovery.md |
| M55 | gtheory-reference docs audit — historical-citation framing | done | — | normal | milestones/archive/M55-gtheory-docs-audit.md |
| M54 | Multilevel SEM (lavaan) — engine implementation | done | — | high | milestones/archive/M54-lavaan-multilevel-engine.md |
| M53 | Multilevel SEM (lavaan) — estimand/oracle pass | done | — | high | milestones/archive/M53-multilevel-sem-pass.md |
<!-- terminal-row retention: M59 rotated out (M57 shipped); M53/M54/M55 pinned by M48 Depends-on, so M60 rotates out at the next terminal transition (5 most recent kept) -->
<!-- rows grouped by status; keep only the 5 most recent terminal (done/dropped)
     rows — older history in cairn/legacy/ + git. -->

## Candidates

- Companion software/methods paper (JOSS or similar) — after the v0.1.0 release; the M42 comparison article is the seed; venue/framing decided against the released package (design interview + plan gate, 2026-07-12; ADR-022 deferral) — cairn/DESIGN.md § Commitments
- Statistical-extension parking lot (grouped; see `cairn/legacy/ROADMAP.md` for the full descriptions + readiness/status per item): the `d_study()` cluster-level / occasion-ragged projection; the occasion-averaged coefficient on ragged replicates (research); incomplete/unbalanced **fixed** cluster-level `ICC(c,k)` (still blocked by ten Hove's small-`k` estimator). Promote individually via `/milestone-plan` — migrated 2026-07-12 — cairn/legacy/ROADMAP.md
- Incomplete/unbalanced fixed-rater **subject**-level multilevel lavaan — the SEM sibling that compounds two-level FIML with the Case-3A fixed correction; low priority, promote only on a concrete need. Split off from the lavaan-multilevel-siblings candidate at the M56–M58 plan gate (2026-07-17); the fixed **cluster** level stays double-blocked (parking-lot candidate above). Lineage: ADR-027 → M53 GO (D-005) → M54 → M56–M58
- Plotting polish — beautify and improve the plotting methods (`R/autoplot.R`: `autoplot.icc` coefficient/component views, `autoplot.icc_dstudy` reliability curves, and their `plot()` wrappers): visual design, labeling/theming, and possible new views (e.g. level-faceted multilevel displays). ggplot2 stays in Suggests (ADR-010 light-install). Added conversationally 2026-07-17
- Fixed-rater multilevel lavaan bootstrap CI — thread the per-refit Case-3A θ²_r correction through the M56 two-level bootstrap factory (`lavaan_ml_simulate_refit` / `lavaan_multilevel_components`, currently random-only) so the crossed fixed multilevel cell gets a parametric bootstrap alongside its MC interval. Deferred at the M57 gate (2026-07-17): MC-only ships; bootstrap parity is nice-to-have and inherits M56's cluster-level cross-platform flake. Lineage: M56 factory → M57.
- lavaan + within-cell replicates — the SEM engine on replicated (σ²_sr/σ²_e-split) data. Niche, low value: would need both a lavaan replicate parameterization and the M20 replicate machinery to intersect. Promote only if a concrete need appears. Reclassified from M21 (ADR-027); promoted from the parking lot 2026-07-13 — cairn/legacy/ROADMAP.md
- d_study() CI-width precision planning ("how many subjects for a ±.1-wide interval?") — scope boundary resolved by the design interview (2026-07-12): a legitimate future direction, **gated on finding an oracle strategy**; subject-count-for-power as such stays out of scope (`M4.5-d-study.md` §6; DESIGN.md contract boundary) — cairn/estimand-specs/M4.5-d-study.md
