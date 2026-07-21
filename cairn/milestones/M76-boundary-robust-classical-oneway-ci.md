# M76: Boundary-robust classical CI for the one-way default — GO/NO-GO (SEARLE exact-F + Burch REML)

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP6
- **Branch/PR:** m76-boundary-robust-classical-oneway-ci

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

- [ ] AC1 — Each prototype (SEARLE exact-F; Burch REML) reproduces its source's
      worked/reference limits to ≥2-oracle agreement within a pre-registered
      tolerance: SEARLE-F against `mcgraw1996` Table 7 and `ukoumunne2003`'s
      exact-F; Burch REML against the supplied source's reference value.
- [ ] AC2 — Across every sweep cell each classical method returns a finite
      interval on 100% of datasets (0 aborts), where the MC default aborts
      (`intraclass_singular_fit`) on 28–39% of near-zero cells; per-method
      `n_ok`/abort counts reported.
- [ ] AC3 — On Gaussian cells the classical CI meets the pre-registered coverage
      band AND median width ≤ the MC default's on the incumbent's non-aborted
      reps (i.e. dominates MC on normal data).
- [ ] AC4 — On the non-normal cluster-effect cells, coverage is measured and
      compared to bootstrap-t and MC against the pre-registered non-normal
      decision rule (how much loss is GO-tolerable) — binding, not descriptive.
- [ ] AC5 — Coverage is reported decomposed into lower/upper tail-miss rates per
      method × cell, so an asymmetric two-sided pass is caught (RR01 Q5).
- [ ] AC6 — A D-entry records GO/NO-GO per method against the frozen criterion
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
- [ ] T3 — Burch REML CI: **acquire the primary Burch (2011) source** (maintainer
      supplies the PDF to `cairn/references/sources/`; write its `BIBLIOGRAPHY.md`
      + source note) — the eq. 9 construction (non-obvious `κ̂` parameterization)
      cannot be built from `ohyama2025`'s secondhand form (IP1/#1). Then prototype
      and validate against `ohyama2025` §4 REML limits (AC1). **Blocks T4–T5.**
- [ ] T4 — Build the paired coverage/width/tail harness: Gaussian + non-normal
      cells, per-cell distinct seeds + per-method condition-class logging (RR01
      findings 1–2), incumbents MC/pboot/npbootstrap; **pre-register the full
      criterion (coverage band, width rule, non-normal decision rule) before any
      run** (GP5).
- [ ] T5 — Run the sweep (a near-zero corner cell at n_rep ≥ 2000), save the
      results fixture with `n_ok`/abort + tail-error columns (AC2–AC5).
- [ ] T6 — Write the comparison note + `ORACLES.md` entry for the new oracle(s);
      author the GO/NO-GO + default-recommendation D-entry (AC6).

## Work log

- 2026-07-21: created by /milestone-plan.
- 2026-07-21: in-progress; branch m76-boundary-robust-classical-oneway-ci cut from main.
- 2026-07-21: amendment (minor) — found ohyama2025 §4 prints deterministic SEARLE+REML limits for two ANOVA tables, so the no-oracle tripwire is resolved for both legs; split T1 (SEARLE-F sourcing, done) from the Burch primary-source acquisition (moved into T3).
- 2026-07-21: T1+T2 done — SEARLE exact-F prototype in data-raw/m76-classical-oneway-prototype.R reproduces ohyama2025 §4 Ex.1 SEARLE (0.600,0.891) and matches the mcgraw1996 Table 7 ICC(1) form to 1e-9 (2 independent oracle types). Unbalanced Ex.2 is a documented non-match (own eq.6 construction, out of scope).
