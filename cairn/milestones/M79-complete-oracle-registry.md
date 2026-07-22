# M79: Complete the oracle registry — an entry for every asserted oracle + a census gate (D-007 invariant)

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
<!-- No DESIGN.md IP/GP added or changed; governed by PRINCIPLES.md #4 (no
     unsourced reference values) and #12 (oracle registry), and by
     D-007 (registry home) / D-008 + Amd 1 (three-kind verification bar) /
     D-009 (dated-observation directives) — cited in Scope. -->
- **Branch/PR:** `m79-complete-oracle-registry`

## Goal

Make the D-007 registry invariant ("every oracle value traces to an entry here")
true again and machine-checked: write an `ORACLES.md` entry for every oracle
family the suite asserts but the registry omits, correct the M46/M47-stale
cluster-`ICC(c,k)` language, and ship a checker that fails when an asserted
oracle has no entry.

## Scope

**In:**
- A committed census checker `data-raw/check-oracle-registry.py`: it parses every
  `O-*` label asserted in `tests/testthat/*.R` and every entry (and inline
  sub-oracle) in `ORACLES.md`, and exits non-zero when a test-asserted family is
  neither entried nor in a documented alias/sub-label allowlist; a `--self-test`
  mode injects a known gap and asserts the run goes red. Built **first** (RED,
  enumerating the gap), green at the end. Match the style of
  `data-raw/check-reference-observations.py` (D-009) and `enumerate-generalizing-claims.py` (M74).
- New `ORACLES.md` entries to the **D-008** bar (a `**Kind:**` bullet;
  script-derived legs confirmed against the named committed fixture under
  `tests/testthat/fixtures/` or an inline expected value **without re-running**;
  source legs anchored to M72's verified *Source-leg verification* table or
  re-read only if genuinely new; honest status, no pinned counts, no
  time-relative phrasing) for the census gap: the **frequentist multilevel**
  family (`O-FML` M10, `O-IFML` M18/ADR-028, `O-IML`, `O-NML`, and the
  lme4-**engine** oracle `O-LME`/`O-LME2` M5.5/ADR-012, distinct from the M1
  cross-engine `O-lme4`); the
  **d-study / cluster / misc** set (`O-IDS`, `O-Boot-DS`, `O-cluster-ck`
  M46/ADR-057, `O-cc` M45/ADR-056, `O-invariance` ADR-053); the
  **lavaan-multilevel** family (`O-SEM-ML` M53/54/56/60, `O-SEM-ML-BOOT` M56,
  `O-SEM-ML-FIXED` M57, `O-SEM-ML-INC` M58); and **Bayesian** `O-Bayes-cluster-ck`
  M47/ADR-058.
- Corrections: the stale "open"/"dropped" cluster-`ICC(c,k)`-on-incomplete-data
  characterizations (`ORACLES.md` ~L995–996/1002/1006/1025) now that M46/M47
  closed them, cited to those milestones; INDEX.md + the registry-invariant
  header reconciled (drop the false "M1–M39 scope", drop the pinned "39 entries",
  resolve "the invariant does not currently hold").
- Alias reconciliation via the allowlist (e.g. `O-conflated`→ existing
  `O-Conflated`, a case mismatch; `O-LME`/`O-WAY`; the `O-ML-*` sub-labels).

**Out:**
- Re-running any seeded / live-Stan script to re-establish reproducibility → the
  standing "re-run the oracle scripts" candidate (D-008 scopes re-running out).
- Acquiring Cronbach et al. (1972) → its own candidate row.
- Any change to test code, estimators, or oracle **values** — this milestone
  documents provenance; it does not alter what is asserted or how.
- BIBLIOGRAPHY.md completeness → out of scope (this is the oracle registry).

## Acceptance criteria

- [ ] AC1 — `data-raw/check-oracle-registry.py` exits 0 with every `O-*` family
      asserted in `tests/testthat/*.R` either matched to an `ORACLES.md` entry or
      listed in its documented alias/sub-label allowlist; `--self-test` injects a
      known gap and the run goes red. Evidence: both command runs.
- [ ] AC2 — every family in the census gap has an `ORACLES.md` entry carrying a
      `**Kind:**` bullet (source-traceable / script-derived / mixed, D-008), a
      `Used by` test, and provenance; each script-derived leg is confirmed against
      its named committed fixture or an inline expected value **without a re-run**
      (D-008), and no entry states a status stronger than what was done
      (LESSONS M65/M68/M70). Evidence: the entries + AC1 green.
- [ ] AC3 — the "open"/"dropped" characterizations of cluster `ICC(c,k)` on
      incomplete data are corrected to reflect the M46/M47 closure, cited to those
      milestones/ADRs (ADR-057/058). Evidence: grep before/after + diff.
- [ ] AC4 — INDEX.md and the `ORACLES.md` registry-invariant header carry no
      "M1–M39 scope" claim and no pinned entry count, and the "invariant does not
      currently hold" note is resolved; characterizations avoid pinned counts
      (LESSONS M70). Evidence: grep.
- [ ] AC5 — any repo-state observation added to INDEX.md carries a D-009
      `<!-- check: … -->` directive (or `check: none — reason`); and
      `data-raw/check-reference-observations.py`, `enumerate-generalizing-claims.py
      --check` (M74), and `air format --check .` all pass. Evidence: the three runs.
- [ ] AC6 — `Rscript -e 'devtools::test()'` is unaffected (no R behavior changed;
      docs + one Python checker only). Evidence: test summary.

## Coverage

- AC1 → T1, T5
- AC2 → T2, T3, T4
- AC3 → T5
- AC4 → T5
- AC5 → T1, T5
- AC6 → T5

## Tasks

- [x] T1 — Write `data-raw/check-oracle-registry.py` (parser + diff + alias
      allowlist + `--self-test`); run it RED to freeze the exact gap and alias set.
- [ ] T2 — Frequentist multilevel + lme4-engine entries: `O-FML`, `O-IFML`,
      `O-IML`, `O-NML`, `O-LME`/`O-LME2` (glmmTMB↔lme4 cross-engine + reduction;
      confirm against committed fixtures / inline values per D-008).
- [ ] T3 — d-study / cluster / misc entries: `O-IDS`, `O-Boot-DS`, `O-cluster-ck`
      (`cluster-ck-coverage-oracle.rds`), `O-cc`, `O-invariance`; and Bayesian
      `O-Bayes-cluster-ck` (`bayesian-cluster-ck-oracle.rds`).
- [ ] T4 — lavaan-multilevel entries: `O-SEM-ML` (`sem-multilevel-recovery-oracle.rds`),
      `O-SEM-ML-BOOT`, `O-SEM-ML-FIXED`, `O-SEM-ML-INC` (note the D-005 IP1-fenced
      parameterization sourcing).
- [ ] T5 — Corrections (stale open/dropped language, AC3), INDEX.md + header
      reconciliation (AC4), finalize the allowlist; then all gates green — census
      checker, D-009 checker, M74 `--check`, `air format --check`, `devtools::test()`.

## Work log

- 2026-07-21: created by /milestone-plan. Gate: one milestone (tasks by family); census-gate checker built first as the acceptance oracle + regression guard; new entries verified to the full D-008 bar against committed fixtures (no re-run).
- 2026-07-21: census diff found ~14 un-entried families — larger than the candidate row's 7 (it collapsed the SEM-ML family and missed O-FML/O-IFML/O-IML/O-NML/O-cc); the "M1–M39 header scope" claim (INDEX.md) was falsified — the header has no such scope.
- 2026-07-21 (T1): shipped `data-raw/check-oracle-registry.py` (exact base-ID coverage, curated sub-check-suffix strip, ALIASES allowlist, `--self-test` harness bite); RED baseline = 16 gaps, self-test green (exit 0).
- 2026-07-21 (T1, minor amendment): the checker surfaced `O-LME`/`O-LME2` (lme4 as a selectable ENGINE, M5.5/ADR-012) as a genuine un-entried oracle distinct from the M1 cross-engine `O-lme4` — folded into T2 (was provisionally an alias at plan time). `O-WAY` confirmed a regex artifact of "TWO-WAY", excluded by the label left-boundary.

## Decisions

## Review
