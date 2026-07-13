<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M49: Standing cross-engine parity matrix

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP4   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m49-parity-matrix   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Establish a single committed cross-engine parity asset so a new estimator or an
upstream engine update surfaces a silent agreement gap as a test failure instead
of drifting unnoticed (DESIGN.md § Known issues, wart confirmed 2026-07-12).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** one standing, committed parity asset that enumerates every
(estimator, engine) cell across the estimand-spec surface
(`cairn/estimand-specs/`) and the four engines (glmmTMB, lme4, brms, lavaan —
GP4); each cell is either a numerical-agreement assertion (stated tolerance,
against an independent engine) or an explicit `N/A` with a one-line reason
(engine can't reach that estimand, e.g. lavaan not for multilevel/oneway at
`R/icc.R:564`, brms fixed-rater only). Fold in / cross-reference the existing
ad-hoc parity checks (`tests/testthat/test-icc-engine-oracle.R`,
`test-icc-lme4-engine.R`). A doc note (asset header + DESIGN.md § pointer)
states the agreement policy and the "add a row when you add an estimator or
engine" rule. Promotes and resolves the "Standing engine×estimator parity
matrix" ROADMAP candidate row.

**Out:** adding new estimators or engines (GP4 roster is closed at four → out
permanently, IP2/GP4); the brms/Stan verification-strength wart → ROADMAP
candidate (KI-2, added by this plan); the boundary-fit policy → M50; the
statistical-corner guard audit → M51. A *genuine* disagreement the matrix
surfaces is a bug, not a tolerance to relax (PRINCIPLES.md #1) — it stops for a
gate and is fixed as its own hotfix/milestone, never papered over here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: A committed standing parity asset enumerates every (estimator,
      engine) cell across the estimand-spec surface × the four engines; each
      cell is either an agreement assertion (with tolerance) or an explicit
      `N/A` carrying a one-line reachability reason. No estimator×engine pair
      is silently absent.
- [ ] AC2: Every must-agree cell passes to a stated tolerance against an
      independent engine (glmmTMB↔lme4 for the frequentist estimators; brms↔
      frequentist where an existing parity tolerance governs, e.g. legacy M38);
      each tolerance cites the governing ADR/D-entry where one exists
      (ADR-002/ADR-012 for the lme4 oracle). A surfaced genuine disagreement
      stops for a gate.
- [ ] AC3: The matrix is documented — an asset header + a DESIGN.md § note
      state the agreement policy and the extension rule (guarding GP4's
      per-estimator parity-cost cap and the silent-drift wart); the ROADMAP
      candidate row is resolved.
- [ ] AC4: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
      NOTEs only); full suite green against the **installed** package with
      `NOT_CRAN=true CI=true` (failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Inventory the estimator×engine surface — the 13 estimand specs in
      `cairn/estimand-specs/` × {glmmTMB, lme4, brms, lavaan}; mark each cell
      reachable / `N/A(reason)` from the `icc.R` dispatch rules (lavaan guard
      `R/icc.R:564`; brms fixed-rater path; the double-blocked cluster-level
      `ICC(c,k)` at `R/icc.R:809`). Output the disposition table.
- [ ] T2: Author the standing parity asset asserting agreement for every
      must-agree cell against an independent engine, folding in / cross-
      referencing the ad-hoc checks in `test-icc-engine-oracle.R` and
      `test-icc-lme4-engine.R`; tolerances cite ADR-002/ADR-012 where
      governing. A genuine disagreement stops for a gate (bug per #1).
- [ ] T3: Document the matrix + extension rule (asset header + DESIGN.md §
      note); resolve the "Standing engine×estimator parity matrix" candidate
      row and update the DESIGN.md § Known-issues note to reference M49.
- [ ] T4: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs in
      the work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues" run; promotes
  the parity-matrix candidate row). Plan gate: three separate hardening
  milestones (M49/M50/M51), all sequenced before the M48 release.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
