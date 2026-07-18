# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-07-18 (M63–M67 planned — the references migration + full source-note ingestion of all 27 un-noted PDFs; the references-split and tier-C candidates both graduated; the Jorgensen 2021 PDF gap seeded as a candidate)_

Pre-migration history (M1–M47, ADR-001..058): see `cairn/legacy/` and git log.

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M63 | References migration — ORACLES.md + BIBLIOGRAPHY.md, citekey reconciliation | review | — | high | milestones/M63-references-migration.md |
| M48 | v0.1.0 release consolidation — CRAN submission-ready | planned | M49, M50, M51, M53, M54, M55, M61 | high | milestones/M48-release-v010.md |
| M64 | Source notes — the nine load-bearing primary sources | planned | M63 | normal | milestones/M64-source-notes-loadbearing.md |
| M65 | Source notes — the interval-methods and robustness cluster | planned | M63 | normal | milestones/M65-source-notes-interval-methods.md |
| M66 | Source notes — the foundational and interpretation shelf | planned | M63 | low | milestones/M66-source-notes-foundational.md |
| M67 | Source notes — the ICC-equality-testing cluster | planned | M63 | low | milestones/M67-source-notes-equality-testing.md |
| M62 | Non-parametric bootstrap CI pass — one-way ICC (GO/NO-GO) | done | — | normal | milestones/archive/M62-npbootstrap-oneway-pass.md |
| M61 | Plotting polish — cohesive theme, palette, and labels | done | — | normal | milestones/archive/M61-plotting-polish.md |
| M58 | Multilevel SEM (lavaan) — incomplete / unbalanced random design | done | — | normal | milestones/archive/M58-lavaan-multilevel-incomplete.md |
| M55 | gtheory-reference docs audit — historical-citation framing | done | — | normal | milestones/archive/M55-gtheory-docs-audit.md |
| M54 | Multilevel SEM (lavaan) — engine implementation | done | — | high | milestones/archive/M54-lavaan-multilevel-engine.md |
<!-- terminal-row retention: M62 done (2026-07-18) → M53 rotated out (its archive file + M48's Depends-on still resolve). Kept: M62, M61, M58, M55, M54 (5 most recent terminal). -->
<!-- rows grouped by status; keep only the 5 most recent terminal (done/dropped)
     rows — older history in cairn/legacy/ + git. -->

## Candidates

- Profile-likelihood CI pass — two-way random ICC (GO/NO-GO) — the sibling to M62, split off at the 2026-07-17 implement gate once the sources proved design-specific. Assess the **modified profile likelihood** of xiao2013 (Comput Stat 28:2241-2265; two-way random interrater, random raters) as the candidate, with naive profile-likelihood as a reference point (xiao2013 documents naive PL as under-covering). Same shape as M62: coverage-band+width criterion, GO/NO-GO, no exported method. Promote via `/milestone-plan`. Lineage: legacy candidate (`cairn/legacy/ROADMAP.md:81`) → M62 gate split.
- Exported one-way transformed-bootstrap-t `ci_method` — **GO confirmed (M62 + RR01, D-006):** implement ukoumunne2003's `log F` variance-stabilized bootstrap-t as an exported one-way interval method. Conditions (D-006): balanced-only; the milestone's coverage validation must include a C4-type corner at n_rep ≥ 2000, track lower/upper tail-error, and pre-specify a below-floor fallback (GP5). Its harness must also fix the M62 review findings (all scored sub-threshold there, deferred here): **distinct per-cell seed bases** (M62's collided on the cell name's first char, coupling C1/C2 and C3/C4), **per-replicate `seed` into `icc()`** (M62 fixed it at 1L, making incumbent resampling noise common across reps), **classed guards** on degenerate resamples (SSA=0) and missing-row extraction, and **truncated-vs-untruncated width reported on a common scale**. percentile/BCa are NO-GO (D-006). Promote via `/milestone-plan`. Lineage: legacy candidate → M62 GO.
- Boundary-robust classical CI for the one-way default — M62/RR01 found the glmmTMB MC default **aborts** (`intraclass_singular_fit`) on 28–39 % of near-zero-ICC one-way datasets and under-covers (0.85–0.88 conditional); a classical **SEARLE exact-F** (balanced) or **Burch REML** CI would likely dominate on normal cells and fix the *default itself* — distinct from the bootstrap-t, which does not. Assess/adopt as a one-way interval option. Lineage: M62 RR01 Q3/rec 3.
- Exported profile-likelihood `ci_method` — GO-gated on the PL sibling pass (above); a NO-GO there is a recorded D-entry rejection, not re-litigated. Lineage: legacy candidate → M62 PL sibling.
- Companion software/methods paper (JOSS or similar) — after the v0.1.0 release; the M42 comparison article is the seed; venue/framing decided against the released package (design interview + plan gate, 2026-07-12; ADR-022 deferral) — cairn/DESIGN.md § Commitments
- Statistical-extension parking lot (grouped; see `cairn/legacy/ROADMAP.md` for the full descriptions + readiness/status per item): the `d_study()` cluster-level / occasion-ragged projection; the occasion-averaged coefficient on ragged replicates (research); incomplete/unbalanced **fixed** cluster-level `ICC(c,k)` (still blocked by ten Hove's small-`k` estimator). Promote individually via `/milestone-plan` — migrated 2026-07-12 — cairn/legacy/ROADMAP.md
- Incomplete/unbalanced fixed-rater **subject**-level multilevel lavaan — the SEM sibling that compounds two-level FIML with the Case-3A fixed correction; low priority, promote only on a concrete need. Split off from the lavaan-multilevel-siblings candidate at the M56–M58 plan gate (2026-07-17); the fixed **cluster** level stays double-blocked (parking-lot candidate above). Lineage: ADR-027 → M53 GO (D-005) → M54 → M56–M58
- Plotting: exported user-facing `theme_intraclass()` — a composable, exported ggplot2 theme users can add to their own plots. Deferred at the M61 plan gate (2026-07-17) in favor of internal-only styling; promote on a concrete request. Lineage: M61.
- Plotting: new view types beyond the three current views (e.g. a stacked variance-share / proportion chart). Deferred at the M61 plan gate (2026-07-17); multilevel views are already level-faceted, so a genuinely new display needs a concrete proposal. Lineage: M61.
- Multilevel lavaan bootstrap CI beyond balanced/complete random — two parked cells: (a) the crossed **fixed** cell (thread the per-refit Case-3A θ²_r correction through the M56 factory `lavaan_ml_simulate_refit`/`lavaan_multilevel_components`, currently random-only); (b) the **random incomplete/unbalanced** cells (the factory takes an unequal `cluster_sizes` vector, but coverage is validated only on balanced data — needs an unbalanced coverage oracle; incomplete can't bootstrap at all, ADR-031). Both MC-only ship; bootstrap parity is nice-to-have and inherits M56's cluster-level cross-platform flake. Lineage: M56 factory → M57 (fixed) → M58/MD-1 (random incomplete/unbalanced).
- lavaan + within-cell replicates — the SEM engine on replicated (σ²_sr/σ²_e-split) data. Niche, low value: would need both a lavaan replicate parameterization and the M20 replicate machinery to intersect. Promote only if a concrete need appears. Reclassified from M21 (ADR-027); promoted from the parking lot 2026-07-13 — cairn/legacy/ROADMAP.md
- d_study() CI-width precision planning ("how many subjects for a ±.1-wide interval?") — scope boundary resolved by the design interview (2026-07-12): a legitimate future direction, **gated on finding an oracle strategy**; subject-count-for-power as such stays out of scope (`M4.5-d-study.md` §6; DESIGN.md contract boundary) — cairn/estimand-specs/M4.5-d-study.md
