<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M49: Standing cross-engine parity matrix

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP4   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m49-parity-matrix · https://github.com/jmgirard/intraclass/pull/55   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: A committed standing parity asset enumerates every (estimator,
      engine) cell across the estimand-spec surface × the four engines; each
      cell is either an agreement assertion (with tolerance) or an explicit
      `N/A` carrying a one-line reachability reason. No estimator×engine pair
      is silently absent.
- [x] AC2: Every must-agree cell passes to a stated tolerance against an
      independent engine (glmmTMB↔lme4 for the frequentist estimators; brms↔
      frequentist where an existing parity tolerance governs, e.g. legacy M38);
      each tolerance cites the governing ADR/D-entry where one exists
      (ADR-002/ADR-012 for the lme4 oracle). A surfaced genuine disagreement
      stops for a gate.
- [x] AC3: The matrix is documented — an asset header + a DESIGN.md § note
      state the agreement policy and the extension rule (guarding GP4's
      per-estimator parity-cost cap and the silent-drift wart); the ROADMAP
      candidate row is resolved.
- [x] AC4: `devtools::check(env_vars = c(NOT_CRAN = "false"))` clean (0/0,
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

- [x] T1: Inventory the estimator×engine surface — the 13 estimand specs in
      `cairn/estimand-specs/` × {glmmTMB, lme4, brms, lavaan}; mark each cell
      reachable / `N/A(reason)` from the `icc.R` dispatch rules (lavaan guard
      `R/icc.R:564`; brms fixed-rater path; the double-blocked cluster-level
      `ICC(c,k)` at `R/icc.R:809`). Output the disposition table.
- [x] T2: Author the standing parity asset asserting agreement for every
      must-agree cell against an independent engine, folding in / cross-
      referencing the ad-hoc checks in `test-icc-engine-oracle.R` and
      `test-icc-lme4-engine.R`; tolerances cite ADR-002/ADR-012 where
      governing. A genuine disagreement stops for a gate (bug per #1).
- [x] T3: Document the matrix + extension rule (asset header + DESIGN.md §
      note); resolve the "Standing engine×estimator parity matrix" candidate
      row and update the DESIGN.md § Known-issues note to reference M49.
- [x] T4: Run `devtools::check(env_vars = c(NOT_CRAN = "false"))` + the
      installed-package suite with `NOT_CRAN=true CI=true`; record outputs in
      the work log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-12: created by /milestone-plan ("address known issues" run; promotes
  the parity-matrix candidate row). Plan gate: three separate hardening
  milestones (M49/M50/M51), all sequenced before the M48 release.
- 2026-07-12: implement gate (in-file matrix test; cross-reference existing
  ad-hoc tests; N/A cells assert the classed abort; principal-variant-per-spec
  granularity) — all four recommendations accepted.
- 2026-07-12: T1+T2 — probed the surface oracle-first (correcting the stale
  inline dispatch comment at `R/icc.R:551`; the roxygen at `R/icc.R:230` is
  authoritative). Disposition (frequentist trio, CI-asserted point estimates;
  glmmTMB = reference): lme4 agrees on ALL 8 principal cells (two-way
  random/fixed × complete/incomplete, one-way, crossed random, crossed fixed,
  nested Design 2) to 1e-4 single-level / 1e-3 multilevel; lavaan agrees on the
  four two-way cells — consistency exact (1e-4 complete, 3e-3 FIML incomplete),
  agreement asymptotic (SEM small-sample term: 1e-2 complete, 2e-2 incomplete) —
  and aborts `intraclass_unsupported` on one-way + all three multilevel cells;
  brms enumerated in the roster guard, live parity left in test-icc-brms.R
  (skip_on_ci). New asset `tests/testthat/test-engine-parity-matrix.R` green
  (73 assertions); roster guard reads icc()'s engine vector from its own body so
  a 5th engine breaks it (GP4).
- 2026-07-12: T3 — documented the matrix in DESIGN.md § Architecture + marked
  the cross-engine-parity wart RESOLVED; new-file lintr clean.
- 2026-07-12: T4 — gate green. AC4 `devtools::check(--as-cran, NOT_CRAN=false,
  manual=TRUE)`: 0 errors / 0 warnings / 0 notes. AC5 installed
  `devtools::check(NOT_CRAN=true, CI=true)` (skip_on_cran active): Status OK,
  0/0/0. air format --check clean.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-07-12 (same-session, post-checkpoint). PR #55 (draft).

**Acceptance-criteria evidence (fresh):**
- AC1 — PASS. `tests/testthat/test-engine-parity-matrix.R` enumerates 8
  principal-variant cells; every frequentist engine (glmmTMB reference + lme4 +
  lavaan) appears in each cell as an `agree` or `na` entry, brms in the roster
  guard — no (design, engine) pair silently absent. N/A cells now carry an
  inline one-line reachability reason (added at review); a spec-surface coverage
  comment maps each cell to its estimand spec (M1/M2/M3/M36/M6/M5/M27/M8) and
  names the deferred corners.
- AC2 — PASS. 73 assertions green (fresh `test_file` run). Tolerances calibrated
  and sourced: lme4↔glmmTMB 1e-4 (single) / 1e-3 (multilevel) both REML;
  lavaan↔glmmTMB consistency 1e-4 (complete) / 3e-3 (FIML), agreement 1e-2 /
  2e-2 (documented SEM small-sample term, `icc()` @param engine / ADR-002 /
  ADR-012). Genuine-disagreement-stops-for-a-gate is stated in the header.
- AC3 — PASS. Asset header carries the "add a row" extension rule + tolerance
  rationale; DESIGN.md § Architecture documents the matrix and the
  cross-engine-parity wart is struck through as RESOLVED; ROADMAP candidate row
  consumed at plan time.
- AC4 — PASS (package tree byte-identical since these ran; only `^cairn$`-ignored
  files changed since). `devtools::check(--as-cran, NOT_CRAN=false, manual=TRUE)`:
  0 errors / 0 warnings / 0 notes. Installed `devtools::check(NOT_CRAN=true,
  CI=true)` (skip_on_cran active): Status OK, 0/0/0.

**Consistency gate:** `cairn_validate` exit 0 (all 15 checks); `document()` no
diff; `check_pkgdown()` clean; Coverage map complete (AC1→T1,T2 · AC2→T2 ·
AC3→T3 · AC4→T4, all tasks exist); GP4's *definition* unchanged (no
`cairn_impact` reconciliation needed — the 8 GP4 references are consistent
citations); README.Rmd untouched; no new top-level files (diff confined to
`cairn/` + `tests/`).

**Independent review (three lenses, inline — not spawned; see note below):**
- Diff-bug: no correctness findings. Assertion loop non-vacuous
  (`expect_true(length(keys) > 0)`); N/A loop guarded (`expect_gt(fired, 0)`);
  roster guard non-vacuous (a 5th engine breaks `expect_setequal`); A/C
  tolerance dispatch and level-keying correct.
- Blame/history: DESIGN edits resolve a wart the design-interview flagged; no
  recorded decision contradicted.
- Prior-PR-comments: no-op — the test file is new; DESIGN.md's only prior PR
  (#54, cairn-init migration) raised nothing this diff reintroduces.
- Findings scored <80 (logged, not actioned): (1) lavaan agreement tolerance
  (1e-2/2e-2) has generous headroom over the calibrated gap (~3e-3/8e-3),
  making those cells a weaker drift detector — intentional for cross-platform
  robustness; consistency cells stay tight. (2) The M27 cell name says "subject
  level" while `pm_estimates` compares every returned index — harmless (keys are
  intersected; both engines agree at all levels).
- **Method note:** the three lenses were run inline by the review session rather
  than via spawned fresh-context agents (harness policy discourages unprompted
  subagents; the diff is test+docs only, zero runtime surface). A full
  multi-agent pass is available on request.
