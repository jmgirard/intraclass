# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-07-12 (cairn-init migration; IDs continue from legacy max M47)_

Pre-migration history (M1–M47, ADR-001..058): see `cairn/legacy/` and git log.

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
<!-- no live milestones at migration: M47 shipped, nothing in-progress. New IDs
     continue from M48. Rows grouped by status; keep only the 5 most recent
     terminal (done/dropped) rows — older history in cairn/legacy/ + git. -->

## Candidates

- v0.1.0 release consolidation (legacy ADR-022 / ADR-055) — the biggest deliberate open call; `main` stays on `0.0.0.9000`. An open decision, not yet a scoped milestone (no acceptance criteria/tasks), so a candidate, not `planned` — promote via `/milestone-plan` when ready — migrated 2026-07-12 — cairn/legacy/STATUS.md, cairn/legacy/ROADMAP.md
- Statistical-extension parking lot (grouped; see `cairn/legacy/ROADMAP.md` for the full descriptions + readiness/status per item): the `d_study()` cluster-level / occasion-ragged projection; the occasion-averaged coefficient on ragged replicates (research); incomplete/unbalanced **fixed** cluster-level `ICC(c,k)` (still blocked by ten Hove's small-`k` estimator); multilevel SEM (lavaan); lavaan + within-cell replicates. Promote individually via `/milestone-plan` — migrated 2026-07-12 — cairn/legacy/ROADMAP.md
- d_study() CI-width precision planning ("how many subjects for a ±.1-wide interval?") — scope boundary resolved by the design interview (2026-07-12): a legitimate future direction, **gated on finding an oracle strategy**; subject-count-for-power as such stays out of scope (`M4.5-d-study.md` §6; DESIGN.md contract boundary) — cairn/estimand-specs/M4.5-d-study.md
- Standing engine×estimator parity matrix — make cross-engine parity gaps visible (a committed matrix or test asset, instead of milestone-by-milestone parity), addressing the silent-drift wart — design interview 2026-07-12 — cairn/DESIGN.md § Known issues
- Boundary-fit convergence policy consolidation — replace the accumulated per-milestone case law for near-zero variance components with one principled, documented policy — design interview 2026-07-12 — cairn/DESIGN.md § Known issues
