# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-07-16 (M52 shipped + archived; scaffold repaired earlier same day: PROFILE.md backfilled, gitignore marker entry, references INDEX line; M48 release workable next)_

Pre-migration history (M1–M47, ADR-001..058): see `cairn/legacy/` and git log.

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M48 | v0.1.0 release consolidation — CRAN submission-ready | planned | M49, M50, M51 | high | milestones/M48-release-v010.md |
| M52 | brms/Stan verification hardening | done | — | normal | milestones/archive/M52-brms-verification-hardening.md |
| M49 | Standing cross-engine parity matrix | done | — | high | milestones/archive/M49-parity-matrix.md |
| M50 | Boundary-fit convergence policy consolidation | done | — | high | milestones/archive/M50-boundary-policy.md |
| M51 | Statistical-corner guard audit | done | M50 | high | milestones/archive/M51-corner-guard-audit.md |
<!-- rows grouped by status; keep only the 5 most recent terminal (done/dropped)
     rows — older history in cairn/legacy/ + git. -->

## Candidates

- Companion software/methods paper (JOSS or similar) — after the v0.1.0 release; the M42 comparison article is the seed; venue/framing decided against the released package (design interview + plan gate, 2026-07-12; ADR-022 deferral) — cairn/DESIGN.md § Commitments
- Statistical-extension parking lot (grouped; see `cairn/legacy/ROADMAP.md` for the full descriptions + readiness/status per item): the `d_study()` cluster-level / occasion-ragged projection; the occasion-averaged coefficient on ragged replicates (research); incomplete/unbalanced **fixed** cluster-level `ICC(c,k)` (still blocked by ten Hove's small-`k` estimator). Promote individually via `/milestone-plan` — migrated 2026-07-12 — cairn/legacy/ROADMAP.md
- Multilevel SEM (lavaan) — two-level SEM-GT for the multilevel designs (`engine = "lavaan"` with `cluster`). A research-flavored lift, not a mechanical extension of the M7 two-way SEM engine: ten Hove et al. (2022)'s multilevel estimator is Bayesian, not a plain lavaan common-factor model, so a faithful two-level SEM formulation needs its own estimand/oracle pass before it is schedulable. **Blocks** the lavaan cluster-level-fixed and incomplete-fixed-nested siblings (they can't ship as engine parity until this lands). Reclassified from the M21 SEM-parity plan (ADR-027); promoted from the parking lot 2026-07-13 — cairn/legacy/ROADMAP.md
- lavaan + within-cell replicates — the SEM engine on replicated (σ²_sr/σ²_e-split) data. Niche, low value: would need both a lavaan replicate parameterization and the M20 replicate machinery to intersect. Promote only if a concrete need appears. Reclassified from M21 (ADR-027); promoted from the parking lot 2026-07-13 — cairn/legacy/ROADMAP.md
- d_study() CI-width precision planning ("how many subjects for a ±.1-wide interval?") — scope boundary resolved by the design interview (2026-07-12): a legitimate future direction, **gated on finding an oracle strategy**; subject-count-for-power as such stays out of scope (`M4.5-d-study.md` §6; DESIGN.md contract boundary) — cairn/estimand-specs/M4.5-d-study.md
