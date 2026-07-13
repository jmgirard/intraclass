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
- 2026-07-12: T1+T2 — probed the surface oracle-first (corrected the stale
  inline dispatch comment `R/icc.R:551`; roxygen `R/icc.R:230` is authoritative).
  8 principal cells: lme4 agrees on all (1e-4 single / 1e-3 multilevel); lavaan
  on the four two-way cells (consistency exact, agreement asymptotic per the SEM
  small-sample term) and aborts on one-way + multilevel; brms in the roster
  guard, live parity in test-icc-brms.R. Asset green (73 assertions).
- 2026-07-12: T3 — matrix documented in DESIGN.md § Architecture; wart marked
  RESOLVED; lintr clean.
- 2026-07-12: T4 — AC4 `check(--as-cran, NOT_CRAN=false, manual=TRUE)` 0/0/0;
  AC5 installed `check(NOT_CRAN=true, CI=true)` (skip_on_cran active) Status OK
  0/0/0; air clean.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-07-12 (same-session). PR #55.

**AC evidence (fresh):**
- AC1 PASS — asset enumerates 8 principal-variant cells; every frequentist
  engine appears per cell as `agree`/`na`, brms in the roster guard — nothing
  silently absent. N/A cells carry an inline reason (added at review); a
  spec-coverage comment maps cells to M1/M2/M3/M36/M6/M5/M27/M8 + deferred corners.
- AC2 PASS — 73 assertions green. Tolerances calibrated/sourced: lme4↔glmmTMB
  1e-4/1e-3 (REML); lavaan consistency 1e-4/3e-3, agreement 1e-2/2e-2 (SEM
  small-sample term; ADR-002/ADR-012). Header states disagreement stops for a gate.
- AC3 PASS — asset header "add a row" rule; DESIGN § Architecture documents it;
  wart marked RESOLVED; candidate row consumed at plan time.
- AC4 PASS (tree byte-identical since; only `^cairn$`-ignored files changed) —
  `check(--as-cran, NOT_CRAN=false, manual=TRUE)` 0/0/0; installed
  `check(NOT_CRAN=true, CI=true)` Status OK 0/0/0.

**Consistency gate:** `cairn_validate` exit 0; `document()` no diff;
`check_pkgdown()` clean; Coverage complete (AC1→T1,T2 · AC2→T2 · AC3→T3 ·
AC4→T4); GP4 definition unchanged (no impact reconciliation); README.Rmd
untouched; diff confined to `cairn/` + `tests/`.

**Independent review (three lenses, inline — not spawned):** diff-bug: no
correctness findings (assertion loop, N/A loop, and roster guard all
non-vacuous; A/C tolerance dispatch + level-keying correct). Blame/history:
resolves a design-interview wart, no decision contradicted. Prior-PR: no-op
(new file; PR #54 raised nothing reintroduced). Scored <80 (logged): (1) lavaan
agreement tolerance has headroom over the calibrated gap — intentional
cross-platform robustness, consistency cells stay tight; (2) M27 cell name says
"subject level" but compares all returned indices — harmless. Method note: lenses
run inline (harness discourages unprompted subagents; test+docs only) — full
multi-agent pass available on request.
