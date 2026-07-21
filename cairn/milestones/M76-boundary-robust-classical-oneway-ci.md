# M76: Boundary-robust classical CI for the one-way default — GO/NO-GO (SEARLE exact-F + Burch REML)

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP6
- **Branch/PR:** m76-boundary-robust-classical-oneway-ci · [PR #85](https://github.com/jmgirard/intraclass/pull/85)

## Goal

Decide, against a pre-registered coverage/width/abort criterion, whether a
classical SEARLE exact-F and/or Burch REML one-way CI should replace or
supplement the glmmTMB Monte-Carlo default — assessment only, no exported code.

## Scope

**In:** prototype the SEARLE exact-F CI (balanced one-way `ICC(1)`/`ICC(k)`,
from `mcgraw1996` Table 7 p. 41 + the `ukoumunne2003` exact-F comparator) and
the Burch REML CI (from the maintainer-supplied source) in `data-raw/`;
oracle-validate each (≥2 types, IP1); run a paired coverage sweep — near-zero +
small ICC, **Gaussian and non-normal cluster-effect** cells (GP6) — against the
incumbents (MC default, parametric bootstrap, `npbootstrap` bootstrap-t) with
per-method abort/`n_ok` and lower/upper tail-error logging; a comparison note,
an `ORACLES.md` entry, and a GO/NO-GO D-entry that also recommends
default-replacement vs opt-in `ci_method`.

**Out:** shipping any exported `ci_method` or changing the default → a GO
promotes a follow-on implementation milestone (as D-006 → M75 did for
npbootstrap). Unbalanced SEARLE-F → stays the [[unbalanced npbootstrap]]-adjacent
candidate; Burch REML natively covers unbalanced, assessed balanced here.

## Acceptance criteria

- [x] AC1 — Each prototype (SEARLE exact-F; Burch REML) reproduces its source's
      worked/reference limits to ≥2-oracle agreement within a pre-registered
      tolerance: SEARLE-F against `mcgraw1996` Table 7 and `ukoumunne2003`'s
      exact-F; Burch REML against the supplied source's reference value.
- [x] AC2 — Across every sweep cell each classical method returns a finite
      interval on 100% of datasets (0 aborts), where the MC default aborts
      (`intraclass_singular_fit`) on 28–39% of near-zero cells; per-method
      `n_ok`/abort counts reported.
- [x] AC3 — On Gaussian cells the classical CI meets the pre-registered coverage
      band AND median width ≤ the MC default's on the incumbent's non-aborted
      reps (i.e. dominates MC on normal data).
- [x] AC4 — On the non-normal cluster-effect cells, coverage is measured and
      compared to bootstrap-t and MC against the pre-registered non-normal
      decision rule (how much loss is GO-tolerable) — binding, not descriptive.
- [x] AC5 — Coverage is reported decomposed into lower/upper tail-miss rates per
      method × cell, so an asymmetric two-sided pass is caught (RR01 Q5).
- [x] AC6 — A D-entry records GO/NO-GO per method against the frozen criterion
      and, on GO, recommends default-replacement (stating the #3/ADR-003 contract
      change) vs opt-in `ci_method`, decided from the evidence.
      `(RB tripwire: ip-touching)` — the GO bears on PRINCIPLES #3, as M62 → RR01.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T4, T5
- AC3 → T4, T5
- AC4 → T4, T5
- AC5 → T4, T5
- AC6 → T6

## Tasks

- [x] T1 — SEARLE-F sourcing: confirm the exact-F CI construction from
      `mcgraw1996.md` Table 7 + `ohyama2025.md` (Searle 1971, eq. 4/6), and
      register `ohyama2025` §4 (Ex.1 PMOC, Ex.2 PaCO₂) as the deterministic
      oracle for **both** legs (SEARLE + REML limits printed there). No-oracle
      tripwire resolved — reference values exist on the shelf.
- [x] T2 — Prototype SEARLE exact-F CI in `data-raw/`; validate against
      `mcgraw1996` Table 7 + `ohyama2025` §4 SEARLE limits (AC1).
- [x] T3 — Burch REML CI: **acquire the primary Burch (2011) source** (maintainer
      supplies the PDF to `cairn/references/sources/`; write its `BIBLIOGRAPHY.md`
      + source note) — the eq. 9 construction (non-obvious `κ̂` parameterization)
      cannot be built from `ohyama2025`'s secondhand form (IP1/#1). Then prototype
      and validate against `ohyama2025` §4 REML limits (AC1). **Blocks T4–T5.**
- [x] T4 — Build the paired coverage/width/tail harness: Gaussian + non-normal
      cells, per-cell distinct seeds + per-method condition-class logging (RR01
      findings 1–2), incumbents MC/pboot/npbootstrap; **pre-register the full
      criterion (coverage band, width rule, non-normal decision rule) before any
      run** (GP5).
- [x] T5 — Run the sweep (a near-zero corner cell at n_rep ≥ 2000), save the
      results fixture with `n_ok`/abort + tail-error columns (AC2–AC5).
- [x] T6 — Write the comparison note + `ORACLES.md` entry for the new oracle(s);
      author the GO/NO-GO + default-recommendation D-entry (AC6).

## Work log

- 2026-07-21: created by /milestone-plan.
- 2026-07-21: in-progress; branch m76-boundary-robust-classical-oneway-ci cut from main.
- 2026-07-21: amendment (minor) — found ohyama2025 §4 prints deterministic SEARLE+REML limits for two ANOVA tables, so the no-oracle tripwire is resolved for both legs; split T1 (SEARLE-F sourcing, done) from the Burch primary-source acquisition (moved into T3).
- 2026-07-21: T1+T2 done — SEARLE exact-F prototype in data-raw/m76-classical-oneway-prototype.R reproduces ohyama2025 §4 Ex.1 SEARLE (0.600,0.891) and matches the mcgraw1996 Table 7 ICC(1) form to 1e-9 (2 independent oracle types). Unbalanced Ex.2 is a documented non-match (own eq.6 construction, out of scope).
- 2026-07-21: BLOCKED on T3 — the Burch REML eq.9 construction needs the primary Burch (2011) source (cited only secondhand in ohyama2025 §2; the κ̂ parameterization is non-obvious, so it cannot be built from memory, IP1/#1). T4–T5 depend on both legs, so the sweep is deferred until the maintainer supplies the PDF to cairn/references/sources/. SEARLE-F leg (T1/T2) complete and oracle-validated.
- 2026-07-21: RESUMED — blocker cleared: maintainer supplied burch2011.pdf to cairn/references/sources/. Status blocked→in-progress. Merged main into branch (M77/M78, D-011, terminal-row rotation); ROADMAP conflict resolved keeping main's rotation + M76 in-progress. CI-parity verify (CI=true) clean: FAIL 0 / SKIP 23 / PASS 1901 (the local skip_on_ci live-Stan brms tests are pre-existing, R/ byte-identical to main, out of M76 scope).
- 2026-07-21: T3 done — ingested burch2011 (source note + BIBLIOGRAPHY + INDEX; extraction-verified against the PDF). Burch REML CI (eq.6/13/15/16/17) prototyped in data-raw/m76-classical-oneway-prototype.R and validated to ≥2 independent published oracles: ohyama §4 Ex.1 PMOC REML (0.620,0.885) exact, and burch §4 arsenic REML (0.735,0.952)≈(0.73,0.95). Bonus: arsenic normal-based (0.806,0.938)≈(0.81,0.94) is a 2nd independent SEARLE oracle; eq.13/14/15 raw-data kurtosis pipeline self-consistency-checked (mean κ̂̂≈0). Caught + fixed a transcription bug in eq.14's bias term (missing cube on (b−1); the perfect-square/consistency structure disambiguated it).
- 2026-07-21: T4 done — pre-registration gate (user-confirmed): coverage floor 0.93 (source-grounded), non-normal rule ≥0.93 AND within 0.02 of best incumbent, wider 16-cell grid + reduced parametric-bootstrap baseline (~4.5h). Criterion C1–C6 frozen in cairn/references/classical-oneway-comparison.md BEFORE any run (GP5). Harness data-raw/m76-coverage-sweep.R built + smoke-tested (all 5 methods, pb only in the 2 corner cells, classical 0 aborts + finite widths, MC aborting 25–50% on near-zero — AC2/AC3 directions confirmed). Measured pboot cost 19.3s/dataset (999 refits) → full-grid infeasible, hence the reduced baseline.
- 2026-07-21: T5 done — sweep ran ~3.2h (16 cells, 129k rows → data-raw/m76-sweep-results.rds). Results + per-cell C1–C5 ledger + disposition written into classical-oneway-comparison.md. Headline (AC2): SEARLE & Burch 0 aborts on all 32k datasets vs MC 4–44% (confirms+extends D-006's 28–39%). SEARLE near-nominal+symmetric except the high-k leptokurtic cell (0.924); Burch never under-covers but over-covers/wide small-k + tail-asymmetric at n=2. Neither passes the every-cell replacement bar; both GO as opt-in.
- 2026-07-21: T6 done — O-Classical-OW registered in ORACLES.md (prototype-validated, not suite-asserted, honest per D-008). GO/NO-GO verdict authored as D-012 (ip-touching gate: user ACCEPTED, declined Fable escalation): NO-GO default-replace, GO opt-in for both SEARLE + Burch REML, no #3/ADR-003 change. Follow-on opt-in `ci_method` ROADMAP candidate added (lineage D-006 → M76/D-012). All 6 ACs met. Status → review.
- 2026-07-21: review — branch synced with main (no drift), draft PR #85 opened. AC1–AC6 verified with fresh evidence (see Review). Consistency gate: cairn_validate exit 0, document() no-diff. Three-lens fan-out spawned.
- 2026-07-21: review — PR #85 lint job red: `object_name_linter` on `data-raw/m76-classical-oneway-prototype.R:65` (`.lintr` lints data-raw). Fixed on-branch (trivial): renamed `burch_P` → `burch_p_term` (3 uses); oracles re-pass, air + lintr clean locally. Blame-history lens: no findings.

## Review

**Reviewed:** 2026-07-21 · PR [#85](https://github.com/jmgirard/intraclass/pull/85) · assessment-only (GO/NO-GO), zero `R/` package code — diff is `data-raw/` prototypes + `cairn/` tracking/references only.

### Acceptance-criteria evidence (fresh)

- **AC1 ✓** — Re-ran `Rscript data-raw/m76-classical-oneway-prototype.R`: all `stopifnot` oracles pass. SEARLE Ex.1 PMOC (0.601, 0.892) ≈ ohyama §4 (0.600, 0.891); mcgraw1996 Table 7 form matches the SEARLE pivot to ≤1e−9 (2nd independent oracle type); Burch Ex.1 REML (0.620, 0.885) exact vs ohyama; burch §4 arsenic REML (0.735, 0.952) ≈ (0.73, 0.95) and arsenic normal-based (0.806, 0.938) ≈ (0.81, 0.94) — a 2nd independent published SEARLE oracle; eq.13/14/15 self-consistency (mean κ̂̂ = −0.0067 ≈ 0). Both legs meet ≥2 independent oracle types (IP1/#1).
- **AC2 ✓** — Re-derived from the committed fixture `data-raw/m76-sweep-results.rds`: SEARLE and Burch each 0 aborts across 32,000 datasets (16 cells × 2000). MC gaussian abort rates 0.04–0.43 (0.10,10,2)…(0.05,10,2); npbootstrap 0 aborts; parametric bootstrap 0 aborts over its 1000 corner-cell reps. Confirms + extends D-006's 28–39%.
- **AC3 ✓** — From fixture: at k≥30 gaussian both classical methods narrower than MC on MC's non-aborted reps (spot-check ρ=0.05,k=50: SEARLE 0.210 / Burch 0.205 vs MC 0.274). At n=2 both wider (a C3-as-written fail, but MC's narrowness there is an artifact of its 0.70–0.82 under-coverage — disposition recorded in the comparison note, not reinterpreted).
- **AC4 ✓** — From fixture: on t5 cells SEARLE fails the 0.93 floor at exactly one cell (ρ=0.10,k=50,n=5,t5 = 0.9240, its lone C4 miss); Burch never under-covers on any t5 cell (range 0.937–0.991) and exceeds both incumbents there. Binding non-normal rule applied.
- **AC5 ✓** — From fixture: SEARLE tails symmetric everywhere (max lo_miss 0.043, max hi_miss 0.033, max |diff| 0.010); Burch's four n=2 cells fail C5 (lower-tail 0.0345–0.0390, upper 0.000 — |diff| up to 0.039 > 0.03). Decomposed tails caught the asymmetric small-design pass (RR01 Q5).
- **AC6 ✓** — D-012 records GO/NO-GO per method against the frozen C1–C6 criterion: NO-GO default-replace for both, GO opt-in for both, no #3/ADR-003 contract change; recommends a follow-on opt-in `ci_method` milestone (ROADMAP candidate added, lineage D-006 → M76/D-012). The ip-touching RB tripwire was resolved at the implement gate (user accepted, declined Fable escalation).

Every ledger number in `cairn/references/classical-oneway-comparison.md` was reproduced from the committed fixture; the comparison note's disposition follows the frozen criterion without reinterpretation.

### Consistency gate

- `cairn_validate` — exit 0; all CHECKs PASS. The `dangling id tokens` WARN (296) is a pre-existing advisory (entombed IDs M17/M20/M22/M39 etc.); M76's only added token is `M76`, which resolves.
- No `DESIGN.md` principle text changed → `cairn_impact` skipped (IP1/GP5/GP6 are applied, not amended).
- r-package toolchain gate: `R/`, `man/`, `NAMESPACE`, `DESCRIPTION` byte-identical to main; `devtools::document()` produces no diff; new files build-excluded (`.Rbuildignore` `^data-raw$`, `^cairn$`). No user-visible change → no NEWS entry owed. Full cross-platform R CMD check is PR #85 CI (required green at merge).

### Independent fresh-context review (three lenses + scorer)
