# M85: Unbalanced one-way transformed bootstrap-t — ICC(k) via re-derived Spearman-Brown map

- **Status:** review
- **Priority:** normal
- **Depends on:** M84
- **Driving RR:** —
- **Principles touched:** IP1, GP7
- **Branch/PR:** m85-unbalanced-npbootstrap-icck / [PR #92](https://github.com/jmgirard/intraclass/pull/92)

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

- [x] AC1 (analysis, GO/NO-GO): the pole/support alignment is derived — whether
      `g(ρ) = k_eff·ρ/(1 + (k_eff − 1)ρ)` is finite and strictly monotone on the
      ρ interval attainable under the `n₀`-transform support `(−1/(n₀−1), 1)`. The
      verdict (aligned = GO / pole intrudes = NO-GO) is recorded with its derivation
      and a numeric check on a worst-case unbalanced design (GP7).
- [x] AC2 (GO branch): the unbalanced ICC(k) interval is the SB image of the M84
      ICC(1) endpoints, and coverage inheritance holds as an event identity —
      the M84 sweep, extended with an ICC(k) coverage column against the true
      `k_eff·ρ/(1 + (k_eff − 1)ρ)`, equals the ICC(1) coverage indicator rep-by-rep
      (tolerance 0).
- [x] AC3 (NO-GO branch): if the pole intrudes, a D-entry records it and the
      shipped behavior — truncation at the pole or a loud classed abort on
      `unit = "average"` unbalanced with a `montecarlo` fallback — never a silent
      ±∞ or sign-flipped endpoint.
- [x] AC4 (identity cross-check, GO): a second independent construction of the
      ICC(k) endpoints (the re-derived unbalanced identity — note `g(ρ̂) = 1 − 1/F`
      no longer holds when `k_eff ≠ n₀`, so it must be re-derived, not carried from
      RR02 BC2) agrees with the shipped endpoints to ≤ 1e-10.
- [x] AC5: `unit = "average"` unbalanced no longer aborts (GO) or aborts per AC3
      (NO-GO); the default `icc(unit = c("single", "average"))` on unbalanced
      npbootstrap behaves per the branch, with a directed test.
- [x] AC6: `@param ci_method`/@details/`ORACLES.md`/NEWS updated;
      `devtools::test()` clean; `devtools::check()` 0 errors / 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2, T4
- AC3 → T2, T3
- AC4 → T4
- AC5 → T3
- AC6 → T5

## Tasks

- [x] T1 (RB tripwire: no-oracle): re-derive the SB pole/support alignment for the
      unbalanced transform (`n₀` vs harmonic-mean `k_eff`); numeric check on a
      worst-case unbalanced design; record GO (aligned) or NO-GO (pole intrudes)
      with the derivation. Fable escalation only if contested.
- [x] T2: implement the branch in `R/ci-npbootstrap.R`/`R/icc.R` — GO: SB image of
      the M84 endpoints; NO-GO: the recorded fallback. Tests-first on the
      coverage-inheritance identity (GO) or the fallback abort (NO-GO).
- [x] T3: drop/adjust the `unit = "average"` unbalanced abort (`R/icc.R:1321`);
      directed tests for the default two-unit call on unbalanced data.
- [x] T4: ICC(k) oracle — extend the M84 sweep with the ICC(k) coverage column
      (rep-by-rep identity, tolerance 0) and the re-derived identity cross-check
      (≤ 1e-10).
- [x] T5: docs — `@param ci_method`/@details, the `ORACLES.md` O-NPBoot ICC(k)
      basis, NEWS; `devtools::document()`, `devtools::check()`.

## Work log

- 2026-07-23: created by /milestone-plan (with M84, the ICC(1) predecessor).
- 2026-07-23: set in-progress; branch `m85-unbalanced-npbootstrap-icck` cut from main.
- 2026-07-23: T1 — AC1 GO verdict (MD-1): proved k_eff ≤ n₀ (AM-GM on triples), so the SB pole never intrudes; numeric check + re-derived AC4 identity in `test-ci-npbootstrap-unbalanced-icck.R` (2013 pass). Not escalated (maintainer accepted the proof at the gate).
- 2026-07-23: T2/T3 — GO branch: lifted the `unit="average"` unbalanced npbootstrap abort (`R/icc.R`), so the shipped `npbootstrap_ci` (already `npb_sb(ρ, k_eff)`) serves the unbalanced ICC(k); numeric `unit=m` stays deferred (not pole-safe). Tests: shipped SB-image identity (AC5), rep-by-rep coverage inheritance in-suite (AC2), flipped the old average-aborts test. Verified `std.error` robustly finite over 1977 near-zero designs (heavy-tailed near boundary → doc). Affected test files pass; full `devtools::test()` at completion.
- 2026-07-23: T5 (docs) — `@param`/@details (pole-safe SB map, numeric-unit balanced-only, near-boundary `std.error`), ORACLES O-NPBoot unbalanced ICC(k) basis, NEWS; `document()` regenerated `man/icc.Rd`.
- 2026-07-23: T4 — extended the M84 unbalanced sweep generator with the ICC(k) coverage column; regenerated the n_rep=2000 fixture (ICC(1) columns byte-identical to the committed M84 values; `n_discrepant=0` and `coverage_icck==coverage_icc1` on all 4 cells). Coverage-test asserts the full-sweep event identity (AC2). All npbootstrap test files pass.
- 2026-07-23: completion — `devtools::test()` (`NOT_CRAN=true CI=true`) FAIL 0 / 4041 pass (2 pre-existing WARN captures in `test-vignette-claims.R`, unrelated); `lintr::lint_package()` 0; `devtools::check()` (NOT_CRAN=false) 0 errors / 0 warnings / 0 notes. Status → review.

## Decisions

- **MD-1 (2026-07-23, T1 — AC1 GO/NO-GO: GO).** The unbalanced ICC(k) interval is
  the Spearman-Brown image `g(ρ) = k_eff·ρ/(1+(k_eff−1)ρ)` of the ICC(1) endpoints,
  `ρ` on the transform support `(−1/(n₀−1), 1)` (`n₀` = ohyama eq. 3). `g`'s pole
  `−1/(k_eff−1)` intrudes on the attainable range **iff `k_eff > n₀`**. **Verdict GO:**
  `k_eff` (harmonic mean of `nᵢ`, the package divisor) `≤ n₀` for every one-way design,
  so the pole sits at or below the support boundary and never intrudes — `g` is finite
  and strictly monotone on all attainable `ρ`, and coverage inheritance holds as an exact
  event identity unbalanced (AC2), as it did balanced (M84/RR02). **Proof:** writing
  `n₀ = 2Σ_{i<j}nᵢnⱼ/(N(k−1))`, `k_eff ≤ n₀ ⟺ 2Σ_{i<j}nᵢnⱼ·Σ(1/n_l) ≥ k(k−1)N`; expanding
  and grouping the residual triple sum by unordered triples, each gives
  `2(n_an_b/n_c + n_an_c/n_b + n_bn_c/n_a) ≥ 2(n_a+n_b+n_c)` by AM-GM, summing to
  `(k−1)(k−2)N`. Equality iff all `nᵢ` equal (k≥3) / always k=2 — the balanced
  pole-on-boundary case. Numeric: `min(n₀−k_eff) = −1.4e−14` over 2×10⁵ random +
  adversarial designs (`test-ci-npbootstrap-unbalanced-icck.R`). The
  `(RB tripwire: no-oracle)` resolved by the closed-form proof + numeric check
  (maintainer accepted at the implement gate, 2026-07-23), not escalated to Fable.
  **Consequence:** the GO branch ships — the abort at `R/icc.R:1352` (unbalanced
  `unit="average"`) is lifted; the shipped `npbootstrap_ci` already realizes `g` via
  `npb_sb(ρ, k_eff)`. AC4 identity re-derived (`k_eff≠n₀`):
  `g(ρ)=k_eff(F−1)/(k_eff(F−1)+n₀)`, `F=exp(logf)` — reduces to `1−1/F` balanced (RR02 BC2).

## Review

**PR:** [#92](https://github.com/jmgirard/intraclass/pull/92) (draft). Default branch
(`main`) unmoved since branch cut (merge-base = origin/main); no re-merge needed.
No `Driving RR` → projection-vs-outcome no-ops.

### Acceptance-criteria evidence (fresh)

- **AC1 (GO/NO-GO analysis) — GO, verified.** MD-1 records the derivation
  `k_eff ≤ n0` for every one-way design (AM-GM on unordered triples), so the SB pole
  `−1/(k_eff−1)` sits at or below the support boundary `−1/(n0−1)` and never intrudes;
  `g` is finite + strictly monotone on the attainable ρ. Numeric check
  (`test-ci-npbootstrap-unbalanced-icck.R`, fresh F=0): `min(n0−k_eff) ≥ −1e−12` over
  2×10⁵ random designs + 5 adversarial worst-cases (many singletons + one huge group);
  balanced + k=2 equality cases confirmed.
- **AC2 (coverage inheritance, event identity) — verified.** The n_rep=2000 unbalanced
  sweep, extended with the ICC(k) column against truth `k_eff·ρ/(1+(k_eff−1)ρ)`, records
  `n_discrepant = 0` and `coverage_icck == coverage_icc1` (byte-identical) on all four
  cells (A_10_2 .9356, A_25_5 .9400, A_50_5 .9465, D_10_10 .9220); the ICC(1) columns
  reproduce the committed M84 fixture byte-for-byte. In-suite rep-by-rep identity test
  also passes (tolerance 0). `test-ci-npbootstrap-unbalanced-coverage.R` F=0.
- **AC3 (NO-GO branch) — not taken (vacuously satisfied).** GO was proved, so the pole
  never intrudes: no D-entry, truncation, or abort is owed. The affirmative safety half
  ("never a silent ±∞ or sign-flipped endpoint") holds — endpoints are pole-safe by AC1
  and every AC5 interval is finite, ordered, and ≤ 1; `std.error` verified finite over
  1977 near-zero designs (large but finite near the boundary, documented).
- **AC4 (identity cross-check, GO) — verified.** The re-derived unbalanced identity
  `g(ρ) = k_eff(F−1)/(k_eff(F−1)+n0)` (F=exp(logf)) — a second path using `k_eff` and
  `n0` separately — matches the shipped SB route to ≤ 1e−10 over 2000 draws, and collapses
  to `1 − 1/F` balanced (RR02 BC2). `test-ci-npbootstrap-unbalanced-icck.R` F=0.
- **AC5 (dispatch) — verified.** Unbalanced `unit="average"` and the bare default
  `unit=c("single","average")` now ship a well-formed ordered ICC(k) interval (SB image
  of ICC(1), equal to `npb_sb(ICC(1) endpoint, k_eff)` to 1e−12); numeric `unit=m` still
  aborts `intraclass_unsupported` (not pole-safe). `test-ci-npbootstrap.R` F=0.
- **AC6 (docs + checks).** `@param`/@details, ORACLES O-NPBoot ICC(k) basis, NEWS updated;
  `devtools::document()` no-diff; `pkgdown::check_pkgdown()` clean; `lintr::lint_package()`
  0; full `devtools::test()` (NOT_CRAN=true CI=true) FAIL 0 / 4041 pass (2 pre-existing
  WARN captures in `test-vignette-claims.R`, unrelated). `devtools::check()` at the review
  HEAD (NOT_CRAN=false): **0 errors / 0 warnings / 0 notes**.

### Consistency gate

- `cairn_validate` exit 0 (all checks passed; 322 advisories are pre-existing historical
  `M<NN>`-citation warnings, none from M85). No DESIGN.md principle text changed → no
  `cairn_impact` run. Toolchain gate (r-package): `document()` no-diff, `pkgdown` clean,
  NEWS entry present, no new top-level files needing `.Rbuildignore`.
