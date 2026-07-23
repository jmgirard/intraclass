# M85: Unbalanced one-way transformed bootstrap-t — ICC(k) via re-derived Spearman-Brown map

- **Status:** planned
- **Priority:** normal
- **Depends on:** M84
- **Driving RR:** —
- **Principles touched:** IP1, GP7
- **Branch/PR:** —

## Goal

Extend `ci_method = "npbootstrap"` to `unit = "average"` (ICC(k)) on unbalanced
one-way designs, **re-deriving** the Spearman-Brown endpoint map's pole/support
alignment now that the transform's `n₀` differs from the harmonic-mean `k_eff`.

## Scope

**In:** the unbalanced one-way ICC(k) interval as the monotone Spearman-Brown
image of the M84 ICC(1) endpoints, using the package's harmonic-mean `k_eff`
divisor for one-way ragged data (`R/icc.R:1022`). The load-bearing re-derivation
(RR02 finding 2, `RR02...:181-185`): for balanced data the SB pole `−1/(k_eff−1)`
sits exactly on the support boundary `−1/(n₀−1)` (`k_eff = n = n₀`), so the map is
finite and monotone on all attainable ρ; unbalanced, `k_eff ≠ n₀` in general, so
the pole may fall **inside** the attainable range and break the clean event-identity
coverage inheritance. **GO/NO-GO** on that alignment. Drops the `unit = "average"`
unbalanced npbootstrap abort per the branch taken.

**Out:** classical `"searle"`/`"burch"` unbalanced ICC(k); non-normal robustness.

## Acceptance criteria

- [ ] AC1 (analysis, GO/NO-GO): the pole/support alignment is derived — whether
      `g(ρ) = k_eff·ρ/(1 + (k_eff − 1)ρ)` is finite and strictly monotone on the
      ρ interval attainable under the `n₀`-transform support `(−1/(n₀−1), 1)`. The
      verdict (aligned = GO / pole intrudes = NO-GO) is recorded with its derivation
      and a numeric check on a worst-case unbalanced design (GP7).
- [ ] AC2 (GO branch): the unbalanced ICC(k) interval is the SB image of the M84
      ICC(1) endpoints, and coverage inheritance holds as an event identity —
      the M84 sweep, extended with an ICC(k) coverage column against the true
      `k_eff·ρ/(1 + (k_eff − 1)ρ)`, equals the ICC(1) coverage indicator rep-by-rep
      (tolerance 0).
- [ ] AC3 (NO-GO branch): if the pole intrudes, a D-entry records it and the
      shipped behavior — truncation at the pole or a loud classed abort on
      `unit = "average"` unbalanced with a `montecarlo` fallback — never a silent
      ±∞ or sign-flipped endpoint.
- [ ] AC4 (identity cross-check, GO): a second independent construction of the
      ICC(k) endpoints (the re-derived unbalanced identity — note `g(ρ̂) = 1 − 1/F`
      no longer holds when `k_eff ≠ n₀`, so it must be re-derived, not carried from
      RR02 BC2) agrees with the shipped endpoints to ≤ 1e-10.
- [ ] AC5: `unit = "average"` unbalanced no longer aborts (GO) or aborts per AC3
      (NO-GO); the default `icc(unit = c("single", "average"))` on unbalanced
      npbootstrap behaves per the branch, with a directed test.
- [ ] AC6: `@param ci_method`/@details/`ORACLES.md`/NEWS updated;
      `devtools::test()` clean; `devtools::check()` 0 errors / 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2, T4
- AC3 → T2, T3
- AC4 → T4
- AC5 → T3
- AC6 → T5

## Tasks

- [ ] T1 (RB tripwire: no-oracle): re-derive the SB pole/support alignment for the
      unbalanced transform (`n₀` vs harmonic-mean `k_eff`); numeric check on a
      worst-case unbalanced design; record GO (aligned) or NO-GO (pole intrudes)
      with the derivation. Fable escalation only if contested.
- [ ] T2: implement the branch in `R/ci-npbootstrap.R`/`R/icc.R` — GO: SB image of
      the M84 endpoints; NO-GO: the recorded fallback. Tests-first on the
      coverage-inheritance identity (GO) or the fallback abort (NO-GO).
- [ ] T3: drop/adjust the `unit = "average"` unbalanced abort (`R/icc.R:1321`);
      directed tests for the default two-unit call on unbalanced data.
- [ ] T4: ICC(k) oracle — extend the M84 sweep with the ICC(k) coverage column
      (rep-by-rep identity, tolerance 0) and the re-derived identity cross-check
      (≤ 1e-10).
- [ ] T5: docs — `@param ci_method`/@details, the `ORACLES.md` O-NPBoot ICC(k)
      basis, NEWS; `devtools::document()`, `devtools::check()`.

## Work log

- 2026-07-23: created by /milestone-plan (with M84, the ICC(1) predecessor).

## Decisions

## Review
