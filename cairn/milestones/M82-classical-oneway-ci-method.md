# M82: Export classical boundary-robust one-way CIs as opt-in `ci_method` (SEARLE exact-F + Burch REML)

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1
- **Branch/PR:** —

## Goal

Export the two M76-validated classical one-way random-ICC intervals as opt-in
`ci_method = "searle"` and `ci_method = "burch"`.

## Scope

**In:** Port the SEARLE exact-F and Burch (2011) REML reducers from the
validated prototype `data-raw/m76-classical-oneway-prototype.R` into exported
`ci_method` values `"searle"` (near-normal, exact under normality) and
`"burch"` (kurtosis-robust), mirroring the sibling `"npbootstrap"` (M75, D-010):
balanced one-way random only, engine (glmmTMB REML) point via `icc_point()`,
`unit = "average"` (ICC(k)) via the monotone Spearman-Brown endpoint map, and
loud classed aborts on every other design. Suite-assert the O-Classical-OW
oracles now shipped only as `data-raw` `stopifnot`.

**Out:** A classical **fallback-on-abort default** (MC aborts → classical) — a
`#3`/ADR-003 contract change fenced by D-012 → candidate row. **Unbalanced**
SEARLE-F / Burch (`n₀` harmonic-mean derivation) → existing unbalanced-classical
candidate. A `d_study()` classical projection **band** → out; a classical-CI fit
carries no resample components, so `d_study()` follows the existing
components-absent (vcov) reprojection path unchanged.

## Acceptance criteria

- [ ] AC1 — `icc(..., ci_method = "searle")` and `"burch"` return finite ICC(1)
      intervals on balanced one-way random data, reproducing the O-Classical-OW
      published oracles **in the test suite**: ohyama2025 §4 Ex.1 PMOC — SEARLE
      (0.600, 0.891) and Burch REML (0.620, 0.885) within 0.002; burch2011 §4
      arsenic — SEARLE (0.81, 0.94) and Burch (0.73, 0.95) within 0.005 (≥2
      independent published sources per method — IP1).
- [ ] AC2 — the two self-checks assert in the suite: the mcgraw1996 Table 7
      algebraic-identity cross-check (SEARLE ≡ Table 7 F-form, ≤ 1e−9) and the
      Burch eq.13/14/15 raw-data kurtosis-pipeline self-consistency
      (bias-corrected κ̂̂ ≈ 0 under normality).
- [ ] AC3 — both methods abort loudly (classed `abort_*`, #5/#8) on any
      non-one-way or unbalanced design, message pointing to `montecarlo`,
      mirroring the `npbootstrap` guards (`R/icc.R:1277`).
- [ ] AC4 — the `unit = "average"` (ICC(k)) endpoints equal the monotone
      Spearman-Brown image of the ICC(1) endpoints, and a committed identity
      cross-check confirms that image equals the direct classical ICC(k) F-form
      (`1 − 1/F_limit`) for both methods (exact, tol 1e−9); ORACLES records the
      ICC(k) basis as inheritance, not an independent anchor (D-010 precedent).
- [ ] AC5 — the reported **point** for both estimands and both methods is the
      engine (glmmTMB REML) point via `icc_point()`, identical to every other
      frequentist `ci_method`; `ci$method` records `"searle"`/`"burch"` and
      `ci$samples` is `NA` (deterministic closed form — no resampling, `seed`,
      or draw count), surfaced correctly in `print()`/`glance()`.
- [ ] AC6 — `@param ci_method` documents both strings with their precision
      (exact-F near-normal vs kurtosis-robust REML) per D-010/RR02 BC1; NEWS
      records the two new opt-in methods; ORACLES.md O-Classical-OW status flips
      prototype-validated → suite-asserted.
- [ ] AC7 — the active profile's `verify` slot is clean (and its named
      pre-review check), including `lintr::lint_package()` and
      `air format --check`.

## Coverage

- AC1 → T1, T3
- AC2 → T3
- AC3 → T2
- AC4 → T4
- AC5 → T1, T2
- AC6 → T5
- AC7 → T1, T2, T3, T4, T5

## Tasks

- [ ] T1 — Add `R/ci-classical.R`: `searle_ci()` and `burch_ci()` reducers
      ported from the validated prototype, each returning the per-estimand
      `list(conf.low, conf.high, std.error)` shape that `mc_ci()`/
      `npbootstrap_ci()` return so dispatch consumes them identically.
- [ ] T2 — Wire dispatch in `R/icc.R`: add `"searle"`, `"burch"` to
      `validate_choice` (`R/icc.R:445`); add the dispatch branch (`R/icc.R:1863`);
      add the balanced-one-way abort guards (mirror `R/icc.R:1277`); set
      `ci$samples = NA` for the closed-form methods (`R/icc.R:1961`).
- [ ] T3 — Migrate the O-Classical-OW oracles from `data-raw` `stopifnot` into
      `tests/testthat/test-ci-classical.R`: both published worked examples per
      method + the Table 7 identity + the Burch kurtosis self-consistency check.
- [ ] T4 — Implement `unit = "average"` via the shared Spearman-Brown map and
      add the committed identity cross-check (SB image ≡ direct ICC(k) F-form)
      for both methods; keep endpoints on the estimator's own support.
- [ ] T5 — Docs: extend `@param ci_method` (`R/icc.R:283`), add a NEWS entry,
      flip ORACLES.md O-Classical-OW to suite-asserted, confirm `print()`/
      `glance()` surface the method; run `air format` + `lintr`.

## Work log

- 2026-07-22: created by /milestone-plan. Promoted from the ROADMAP candidate (lineage D-006 → M76/D-012). Gate decisions: ship both methods; strings `"searle"`/`"burch"` decided now under D-010's family-naming doctrine (no fresh RB); ICC(k) via the SB map (algebraic identity to the direct F-form proven for both methods at plan — IP1 by proof + committed cross-check); fallback-on-abort default fenced out to a candidate row.

## Decisions

## Review
