# M84: Unbalanced one-way transformed bootstrap-t — ICC(1)

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP6, GP7
- **Branch/PR:** —

## Goal

Extend `ci_method = "npbootstrap"` to the **single-rating ICC(1)** on unbalanced
one-way random designs — the unequal-`n_i` IJ SE and the `n₀` transform —
validated against the balanced limit and ohyama2025.

## Scope

**In:** the unbalanced one-way ICC(1) transformed bootstrap-t interval — unbalanced
ANOVA MoM with the effective group size `n₀`, the `log F` transform under `n₀`,
and the eq. 7 infinitesimal-jackknife SE **re-derived for unequal `n_i`** (the
balanced eq. 7 drops Appendix-A's constant `C` only because equal sizes give
`C• = C`, `ukoumunne2003.md:73`). Drops the `!balanced` abort for
`unit = "single"` npbootstrap (`R/icc.R:1321-1328`); `ORACLES.md`/@param/@details/
NEWS updated for the new envelope.

**Out:** `unit = "average"` / ICC(k) unbalanced → M85 (depends on M84; the
`unit = "average"` unbalanced abort stays until M85 re-derives the Spearman-Brown
pole/support). Classical `"searle"`/`"burch"` unbalanced (stays balanced-only;
candidate untouched). Non-normal robustness (ohyama tests normal only).

## Acceptance criteria

- [ ] AC1: `icc(model = "oneway", ci_method = "npbootstrap", unit = "single")` on
      an unbalanced dataset returns a finite, ordered ICC(1) interval; the
      `!balanced` abort (`R/icc.R:1321`) no longer fires for `unit = "single"`.
- [ ] AC2 (oracle, exact): fed **equal** `n_i`, the unbalanced reducer reproduces
      the M75 balanced `npbootstrap_ci()` ICC(1) endpoints to ≤ 1e-10 under the
      same seed (reduces-to-balanced; the M75 code is the oracle).
- [ ] AC3 (oracle, deterministic): the unbalanced MoM point
      `ρ̂ = (MSA − MSE)/(MSA + (n₀ − 1)MSE)` reproduces ohyama2025 §4 Example 2
      (PaCO₂: MSA = 2.198, MSE = 0.272, `n₀ ≈ 5.02`) `ρ̂ = 0.585` to 3 dp — pinning
      the `n₀` definition (`ohyama2025.md:117-134`).
- [ ] AC4 (oracle, coverage): an `n_rep ≥ 2000` unbalanced coverage sweep in
      `data-raw/` (ohyama Fig. 2 design cells, MCAR 0.1) lands within a plot-read
      band (± .02) of the Fig. 2 NBOOT coverage at 2–3 cells; the fixture is
      committed (GP6).
- [ ] AC5 (RB tripwire: no-oracle): the unequal-`n_i` IJ SE carries an in-code
      derivation note (Appendix-A `C`-term treatment and/or the ohyama method
      recovered by T1), and the no-direct-oracle basis is recorded in `ORACLES.md`
      (GP7). Fable escalation only if the re-derivation is contested.
- [ ] AC6: degenerate unbalanced input aborts loudly classed (#5/#8) — `SSA = 0`,
      `SSE = 0`, or a resample too small to studentize — never a silent `NaN`
      interval.
- [ ] AC7: `@param ci_method`/@details/`ORACLES.md`/NEWS updated;
      `devtools::test()` clean; `devtools::check()` 0 errors / 0 warnings.

## Coverage

- AC1 → T3
- AC2 → T2, T4
- AC3 → T1, T4
- AC4 → T5
- AC5 → T1, T2
- AC6 → T3
- AC7 → T6

## Tasks

- [ ] T1 (RB tripwire: no-oracle): investigate — recover ohyama2025 §2's unbalanced
      NBOOT method (IJ SE vs nested bootstrap) from the shelf PDF; pin `n₀` (ANOVA
      `n₀` vs harmonic mean) by reproducing Example 2's `ρ̂ = 0.585`. Record findings
      in `ukoumunne2003.md`/`ohyama2025.md` (+ a D-entry if the SE basis is a choice).
- [ ] T2: re-derive the eq. 7 IJ SE for unequal `n_i` from ukoumunne Appendix A
      (A1–A10, the `C` term); implement in `R/ci-npbootstrap.R` — generalize
      `npb_anova()` to per-subject `n_i` and `npb_logf_to_rho()` to `n₀`.
      Tests-first: the reduces-to-balanced equality (AC2).
- [ ] T3: drop the `!balanced` abort for `unit = "single"` npbootstrap
      (`R/icc.R:1321-1328`); keep `unit = "average"` unbalanced aborting (→ M85).
      Guard degenerate unbalanced input (AC6). Directed unit tests.
- [ ] T4: deterministic oracle tests — Example 2 `ρ̂` recovery (AC3) and the
      reduces-to-balanced parity (AC2).
- [ ] T5: unbalanced coverage sweep in `data-raw/` (`n_rep ≥ 2000`, ohyama Fig. 2
      cells, MCAR 0.1); commit the fixture; assert the plot-read band (AC4).
- [ ] T6: docs — `@param ci_method`/@details, the `ORACLES.md` O-NPBoot entry
      (unbalanced basis: reduces-to-balanced + ohyama Fig. 2 plot-read + Example-2
      point), NEWS; `devtools::document()`, `devtools::check()`.

## Work log

- 2026-07-23: created by /milestone-plan (with M85, the ICC(k) follow-on).

## Decisions

## Review
