# M79: Complete the oracle registry — an entry for every asserted oracle + a census gate (D-007 invariant)

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
<!-- No DESIGN.md IP/GP added or changed; governed by PRINCIPLES.md #4 (no
     unsourced reference values) and #12 (oracle registry), and by
     D-007 (registry home) / D-008 + Amd 1 (three-kind verification bar) /
     D-009 (dated-observation directives) — cited in Scope. -->
- **Branch/PR:** `m79-complete-oracle-registry` · PR #86 (https://github.com/jmgirard/intraclass/pull/86)

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

- [x] AC1 — `data-raw/check-oracle-registry.py` exits 0 with every `O-*` family
      asserted in `tests/testthat/*.R` either matched to an `ORACLES.md` entry or
      listed in its documented alias/sub-label allowlist; `--self-test` injects a
      known gap and the run goes red. Evidence: both command runs.
- [x] AC2 — every family in the census gap has an `ORACLES.md` entry carrying a
      `**Kind:**` bullet (source-traceable / script-derived / mixed, D-008), a
      `Used by` test, and provenance; each script-derived leg is confirmed against
      its named committed fixture or an inline expected value **without a re-run**
      (D-008), and no entry states a status stronger than what was done
      (LESSONS M65/M68/M70). Evidence: the entries + AC1 green.
- [x] AC3 — the "open"/"dropped" characterizations of cluster `ICC(c,k)` on
      incomplete data are corrected to reflect the M46/M47 closure, cited to those
      milestones/ADRs (ADR-057/058). Evidence: grep before/after + diff.
- [x] AC4 — INDEX.md and the `ORACLES.md` registry-invariant header carry no
      "M1–M39 scope" claim and no pinned entry count, and the "invariant does not
      currently hold" note is resolved; characterizations avoid pinned counts
      (LESSONS M70). Evidence: grep.
- [x] AC5 — any repo-state observation added to INDEX.md carries a D-009
      `<!-- check: … -->` directive, and M79 **does not regress**
      `check-reference-observations.py` (its added observation is marked and its
      directive holds — `unmarked: 0`); the 22 falsifications pre-existing on
      `origin/main` (M74's triage ledger vs source-note directives) are a separate
      defect, out of scope. `enumerate-generalizing-claims.py --check` (M74) and
      `air format --check .` pass. Evidence: the runs + the origin/main baseline.
      <!-- amended 2026-07-21 (T5): D-009 was pre-existing red on origin/main; see work log. -->
- [x] AC6 — `Rscript -e 'devtools::test()'` is unaffected (no R behavior changed;
      docs + one Python checker only). Evidence: test summary + the branch diff
      touching no `R/` or `tests/` file.

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
- [x] T2 — Frequentist multilevel + lme4-engine entries: `O-FML`, `O-IFML`,
      `O-IML`, `O-NML`, `O-FNML`, `O-LME`/`O-LME2` (glmmTMB↔lme4 cross-engine +
      reduction; confirm against committed fixtures / inline values per D-008).
- [x] T3 — d-study / cluster / misc entries: `O-IDS`, `O-Boot-DS`, `O-cluster-ck`
      (`cluster-ck-coverage-oracle.rds`), `O-cc`, `O-invariance`; and Bayesian
      `O-Bayes-cluster-ck` (`bayesian-cluster-ck-oracle.rds`).
- [x] T4 — lavaan-multilevel entries: `O-SEM-ML` (`sem-multilevel-recovery-oracle.rds`),
      `O-SEM-ML-BOOT`, `O-SEM-ML-FIXED`, `O-SEM-ML-INC` (note the D-005 IP1-fenced
      parameterization sourcing).
- [x] T5 — Corrections (stale open/dropped language, AC3), INDEX.md + header
      reconciliation (AC4), finalize the allowlist; then all gates green — census
      checker, M74 `--check`, `air format --check`, `devtools::test()` (D-009
      no-regression per the AC5 amendment).

## Work log

- 2026-07-21: created by /milestone-plan. Gate: one milestone (tasks by family); census-gate checker built first as the acceptance oracle + regression guard; new entries verified to the full D-008 bar against committed fixtures (no re-run).
- 2026-07-21: census diff found ~14 un-entried families — larger than the candidate row's 7 (it collapsed the SEM-ML family and missed O-FML/O-IFML/O-IML/O-NML/O-cc); the "M1–M39 header scope" claim (INDEX.md) was falsified — the header has no such scope.
- 2026-07-21 (T1): shipped `data-raw/check-oracle-registry.py` (exact base-ID coverage, curated sub-check-suffix strip, ALIASES allowlist, `--self-test` harness bite); RED baseline = 16 gaps, self-test green (exit 0).
- 2026-07-21 (T1, minor amendment): the checker surfaced `O-LME`/`O-LME2` (lme4 as a selectable ENGINE, M5.5/ADR-012) as a genuine un-entried oracle distinct from the M1 cross-engine `O-lme4` — folded into T2 (was provisionally an alias at plan time). `O-WAY` confirmed a regex artifact of "TWO-WAY", excluded by the label left-boundary.
- 2026-07-21 (T2): wrote `ORACLES.md` entries for `O-NML`, `O-IML`, `O-FML`, `O-IFML`, `O-FNML`, `O-LME`/`O-LME2` to the D-008 bar — script-attested numerics (no committed fixture; the assertions are cross-engine/reduction/coverage relationships), source legs anchored to the M72 Source-leg table (ten Hove Eqs. 8–12 / Table 3, McGraw & Wong Case 3A, SF published values). Checker down to 10 gaps.
- 2026-07-21 (T2, checker fix): tightened `registered` to a `###` heading or a bolded `**…**` definition, not any prose mention — a passing cross-reference is not an entry. This exposed a hidden gap, `O-FNML` (masked by the O-NFI entry's "pinned by O-FNML" prose); wrote its entry (the point sibling of the M28 O-NFI interval oracle).

- 2026-07-21 (T3): wrote entries for `O-IDS`, `O-Boot-DS` (d-study, in-suite), `O-cc`, `O-invariance` (in-suite), and — with full D-008 confirmation against their committed fixtures (not re-run) — `O-cluster-ck` (`cluster-ck-coverage-oracle.rds`, M46) and `O-Bayes-cluster-ck` (`bayesian-cluster-ck-oracle.rds`, M47). Checker down to 4 gaps (the lavaan-ML family, T4).

- 2026-07-21 (T4): wrote entries for the lavaan-multilevel family — `O-SEM-ML` (M54, D-005 IP1-fenced route; `/recovery` + `/tau2-invariant` confirmed against the M60-frozen `sem-multilevel-recovery-oracle.rds`, not re-run), `O-SEM-ML-BOOT` (M56), `O-SEM-ML-FIXED` (M57), `O-SEM-ML-INC` (M58). Checker exits 0 — the D-007 invariant now holds and is machine-checked (AC1, AC2).
- 2026-07-21 (T5): AC3 — corrected the one genuinely-stale claim (O-Bayes-IML called the AVERAGED cluster ICC(c,k) "undefined on incomplete data"; M46/M47 shipped it via inverse-Simpson k_c^eff → cross-referenced O-cluster-ck/O-Bayes-cluster-ck); the per-cluster M9 §9 divisor mentions (correctly still-open) left intact. AC4 — reconciled INDEX.md + the ORACLES.md header (dropped the false "M1–M39 scope" and the pinned "39 entries"; the invariant note now reads holds-and-machine-checked, no pinned count). AC5 — INDEX observation carries a `check:` directive running the census checker; `enumerate-generalizing-claims.py --check` regressed 3 new ORACLES claims (LESSONS M76), triaged as OUT-oracle-pin via programmatically-generated ledger rows → green.
- 2026-07-21 (T5, AC5 amendment, gated): `check-reference-observations.py` (D-009) is pre-existing red on `origin/main` — 22 falsifications from M74's triage ledger tripping unrelated source-note "nothing references me" directives; M79's own observation is marked and holds (`unmarked: 0`). AC5 amended to a no-regression bar (user-approved); the 22 tracked as a `candidate` row + background-task chip, out of M79's scope.

## Decisions

## Review

**AC evidence (fresh, 2026-07-21).**
- **AC1 ✓** — `python3 data-raw/check-oracle-registry.py` exits 0 (61 asserted base
  oracles, 65 registry tokens, 2 aliases, **0 gaps**); `--self-test` exits 0 (orphan
  flagged, real entry covered — harness bite intact).
- **AC2 ✓** — all 16 census-gap families have exactly one `### Oracle` heading
  (O-FML/IFML/IML/NML/FNML, O-LME, O-IDS/O-Boot-DS, O-cluster-ck, O-cc,
  O-invariance, O-Bayes-cluster-ck, O-SEM-ML/-BOOT/-FIXED/-INC); every new entry
  carries a `**Kind:**` bullet + `Used by` (Kind-bullet count 25→57). Fixture-backed
  entries (O-cluster-ck, O-Bayes-cluster-ck, O-SEM-ML) confirmed against their
  committed `.rds` without re-running; the rest honestly stamped script-attested.
- **AC3 ✓** — the one stale claim corrected (O-Bayes-IML: "averaged cluster ICC(c,k)
  was dropped-with-note at M30" + "M46/M47 later shipped the averaged … via
  inverse-Simpson k_c^eff"); the 3 per-cluster-M9§9 still-open mentions preserved
  (grep before/after).
- **AC4 ✓** — INDEX.md + the ORACLES.md header carry 0 hits for "M1–M39 scope" /
  "39 entries" / "does not currently hold"; the invariant note reads holds-and-
  machine-checked, no pinned count.
- **AC5 ✓ (amended)** — the INDEX observation carries a `check:` directive running
  the census checker; `check-reference-observations.py` `unmarked: 0` (M79's own
  observation marked + holding), `falsified: 22` = the `origin/main` baseline (no
  regression); `enumerate-generalizing-claims.py --check` exit 0 (3 new claims
  triaged OUT-oracle-pin); `air format --check .` exit 0.
- **AC6 ✓** — `devtools::test()` FAIL 0 | WARN 2 | SKIP 23 | PASS 1901 (the 2 WARN are
  pre-existing lavaan `cli_warn` paths); the branch diff touches no `R/` or `tests/`
  file, so package behavior is byte-identical to `origin/main`.

**Consistency gate.** `cairn_validate` exit 0 (all checks PASS; 327 advisory warnings,
all pre-existing — the dangling-id tokens are COVERAGE.md → archived milestones).
Toolchain: `devtools::document()` no diff (no roxygen drift); NAMESPACE/man untouched;
`data-raw` is `.Rbuildignore`d (no new top-level file); no `@export` change → no
user-visible change → no NEWS entry; full `R CMD check` matrix deferred to PR #86 CI
(no build-included file changed). PR CI: format-check pass, rest pending.

**Independent review — three lenses + scorer.** [O] diff-bug, [S] blame-history,
[S] prior-review, all fresh-context, ref-based.
- **[S] blame-history:** clean — the AC3 correction accurately separates the
  M46/M47 averaged case from the still-open per-cluster M9 §9 divisor; INDEX/header
  rewrite drops only a caveat M79 itself found false; entries D-005/007/008/009
  compliant.
- **[S] prior-review:** no-ops clean — no regression of the M68/M70/M72/M73/M74/M76
  lessons (re-ran each gate; GitHub threads empty, archive is the record).
- **[O] diff-bug — 1 finding, F1, scored 82 (≥80 → FIXED):** the checker's
  `normalize()` stripped the `-lme4`/`-sim` sub-check suffixes off the *standalone*
  oracles `O-lme4`/`O-sim`, collapsing both (and their bolded registry mentions) to
  the bare token `"O"` — a wildcard that would mask a *future* gap (a new
  `O-coverage`/`O-parity` with no entry would match `"O"` and report 0 gaps),
  silently regressing the very D-007 guard this checker provides. No live
  false-negative (both sides collapsed identically), but a real latent hole, and
  the in-code comment falsely called it impossible. **Fix:** guard the strip so it
  never reduces a base past `O-XX` (so `O-lme4`/`O-sim`/`O-coverage` keep their own
  identity), correct the comment, and strengthen `--self-test` to check a
  suffix-named orphan and assert no wildcard token enters the registry set. Verified:
  `"O"` no longer a registry token; `O-ML-lme4`→`O-ML` etc. still resolve; 0 gaps;
  self-test green.
- Fixture fidelity, script-attested stampings, AC3/AC4, and fabrication traps were
  all verified clean by the diff-bug lens. No sub-threshold findings logged.
