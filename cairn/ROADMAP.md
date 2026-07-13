# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-07-12 (M49 shipped, archived; M50 workable next)_

Pre-migration history (M1–M47, ADR-001..058): see `cairn/legacy/` and git log.

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M48 | v0.1.0 release consolidation — CRAN submission-ready | planned | M49, M50, M51 | high | milestones/M48-release-v010.md |
| M49 | Standing cross-engine parity matrix | done | — | high | milestones/archive/M49-parity-matrix.md |
| M50 | Boundary-fit convergence policy consolidation | in-progress | — | high | milestones/M50-boundary-policy.md |
| M51 | Statistical-corner guard audit | planned | M50 | high | milestones/M51-corner-guard-audit.md |
<!-- rows grouped by status; keep only the 5 most recent terminal (done/dropped)
     rows — older history in cairn/legacy/ + git. -->

## Candidates

- Companion software/methods paper (JOSS or similar) — after the v0.1.0 release; the M42 comparison article is the seed; venue/framing decided against the released package (design interview + plan gate, 2026-07-12; ADR-022 deferral) — cairn/DESIGN.md § Commitments
- Statistical-extension parking lot (grouped; see `cairn/legacy/ROADMAP.md` for the full descriptions + readiness/status per item): the `d_study()` cluster-level / occasion-ragged projection; the occasion-averaged coefficient on ragged replicates (research); incomplete/unbalanced **fixed** cluster-level `ICC(c,k)` (still blocked by ten Hove's small-`k` estimator); multilevel SEM (lavaan); lavaan + within-cell replicates. Promote individually via `/milestone-plan` — migrated 2026-07-12 — cairn/legacy/ROADMAP.md
- d_study() CI-width precision planning ("how many subjects for a ±.1-wide interval?") — scope boundary resolved by the design interview (2026-07-12): a legitimate future direction, **gated on finding an oracle strategy**; subject-count-for-power as such stays out of scope (`M4.5-d-study.md` §6; DESIGN.md contract boundary) — cairn/estimand-specs/M4.5-d-study.md
- brms/Stan verification hardening — consolidate and document the offline committed-fixture verification strategy for the brms engine (live-Stan can't run on CI, MCMC flake, ~2h coverage sweeps) into a standing, documented asset; largely inherent, so "address" = mitigate + document. Deferred here per plan gate ("address known issues" run, 2026-07-12); promote via `/milestone-plan` — cairn/DESIGN.md § Known issues
