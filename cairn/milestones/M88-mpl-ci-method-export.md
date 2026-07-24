# M88: Exported profile-likelihood `ci_method = "mpl"` — two-way random ICC(A,1)/ICC(A,k)

- **Status:** planned
- **Priority:** normal
- **Depends on:** M86, M87
- **Driving RR:** —
- **Principles touched:** IP1, GP2, GP7
- **Branch/PR:** —

## Goal

Export the M86/M87-validated modified-profile-likelihood interval as an opt-in
`ci_method = "mpl"` for the balanced-complete two-way random ICC(A,1) (and ICC(A,k)
by Spearman-Brown inheritance), per the D-014 GO-for-opt-in.

## Scope

**In:** port the deterministic MPL interval machinery (`data-raw/m86-mpl-lib.R`) into
`R/ci-mpl.R`; ship a seeded precomputed κ_m table (`R/sysdata.rda`) with lookup +
bilinear interpolation; wire `ci_method = "mpl"` into `icc()` for the two-way random
absolute-agreement cell, `unit = "single"` (ICC(A,1)) and `"average"` (ICC(A,k) via
the shared `npb_sb()` SB map). Point = engine (glmmTMB REML) point; deterministic
(no draws/SE), mirroring `"searle"`/`"burch"` (D-013).

**Out:** on-the-fly κ_m calibration (κ_m is table-only) → candidate; numeric `unit`
(D-study projection to m≠R raters) → candidate; consistency ICC(C,·), fixed raters,
one-way/cluster/multilevel designs, unbalanced/incomplete data, non-Gaussian — all
abort loudly (#5), each unchanged by this milestone; a classical boundary-robust
two-way *default* (contract change) stays the separate `#3` candidate.

## Acceptance criteria

- [ ] AC1: The ported MPL ICC(A,1) core in `R/ci-mpl.R` reproduces xiao2013 Tables
      3/4/6/7 within their published tolerances in `test-ci-mpl.R` (IP1; #1).
- [ ] AC2: `icc(x, model="twoway", raters="random", type="agreement", unit="single",
      ci_method="mpl")` on balanced-complete Gaussian data returns a finite interval
      whose point is the engine (glmmTMB REML) point, with `std.error = NA`,
      `ci$samples = NA`, and a `print()` label naming a modified-profile-likelihood
      interval (D-013 conventions).
- [ ] AC3: `unit="average"` returns `npb_sb()` applied to the ICC(A,1) MPL endpoints;
      a committed identity cross-check asserts endpoint-equality to the direct
      McGraw-Wong ICC(A,k) form built from raw statistics and mutation-proves
      divergence under a wrong divisor (D-013; M82 anti-tautology lesson). ORACLES
      basis = inheritance.
- [ ] AC4: κ_m is supplied from the shipped table by lookup + bilinear interpolation
      within the (R,S) grid; an off-grid (R,S) and every out-of-scope estimand
      (consistency, fixed raters, non-two-way, unbalanced/incomplete, numeric `unit`)
      aborts with a classed `intraclass_*` error naming the supported cell (#5/#8).
- [ ] AC5: On a near-zero-ρ boundary cell where the two-way random Monte-Carlo
      default aborts (`intraclass_singular_fit`), `ci_method="mpl"` returns an
      interval — the M87/D-014 residual-value behavior — asserted in the suite.
- [ ] AC6: `@param ci_method` documents `"mpl"` and carries D-014 conditions (i) the
      sub-ρ=0.6 κ_m is oracle-less (simulated-coverage basis only) and (iii)
      balanced-complete + Gaussian only; the κ_m table's seeded provenance is recorded.
- [ ] AC7: Gates clean — profile `verify` (test + lint), `air format --check`, and the
      `check-references` generalizing-claims + reference-observations gates (xiao2013
      exclude directives updated for any new `data-raw/` file; M85/M86 lessons).

## Coverage

- AC1 → T1, T2
- AC2 → T1, T6
- AC3 → T5
- AC4 → T3, T4, T6
- AC5 → T6, T7
- AC6 → T8
- AC7 → T8, T9

## Tasks

- [ ] T1: Port `mpl_anova/neg2l/prof_neg2l/fit/deviance/interval` from
      `data-raw/m86-mpl-lib.R` into `R/ci-mpl.R` as an `mpl_ci()` reducer (point from
      `icc_point()` upstream; classed aborts; lint-clean snake_case).
- [ ] T2: Move the xiao2013 Tables 3/4/6/7 oracle checks from
      `data-raw/m86-mpl-validate.R` into `tests/testthat/test-ci-mpl.R` (IP1).
- [ ] T3: Author the seeded κ_m table generator in `data-raw/` — extended-range
      ρ∈[0.05,0.9] argmax-corner (ρ=0.05, δ=16) **unbiased** estimator (M86 lesson,
      not the grid max) over an (R,S) grid spanning common designs; run as a
      background job; commit the table to `R/sysdata.rda`.
- [ ] T4: κ_m lookup + bilinear interpolation over the grid; off-grid (R,S) aborts
      loudly (#5/#8) rather than extrapolating an uncalibrated κ_m.
- [ ] T5: ICC(A,k) via the shared `npb_sb()` image of the ICC(A,1) endpoints, plus the
      committed anti-tautology identity + mutation cross-check (T5 builds the direct
      McGraw-Wong side from raw statistics).
- [ ] T6: Wire `"mpl"` into `icc()` — add to the `ci_method` vocabulary
      (`R/icc.R:503`), add the two-way-random-agreement guard (counterpart of the
      one-way guard at `R/icc.R:1334`), add the dispatch branch (mirror `searle_ci`
      at `R/icc.R:1966`), set samples/std.error `NA` + the print label.
- [ ] T7: Boundary-behavior test — `ci_method="mpl"` returns an interval on a cell
      where the two-way MC default aborts (`test-ci-mpl.R`).
- [ ] T8: Docs + references — `@param ci_method`, D-014 conditions (i)/(iii), κ_m
      provenance; update `references/mpl-twoway-random-comparison.md`, add any
      generalizing-claims triage rows, and append `xiao2013.md` exclude directives for
      the new `data-raw/` generator (M85/M86 lessons; `_pkgdown.yml` if a new export).
- [ ] T9: Full gate — `devtools::check` at CI parity (`NOT_CRAN` per the profile),
      `lintr::lint_package()`, `air format --check`, and `check-references` locally.

## Work log

- 2026-07-23: created by /milestone-plan. Scope settled by D-015 — precomputed κ_m table, ICC(A,k) via `npb_sb()` SB inheritance (exact event identity, no new oracle), name `"mpl"`.

## Decisions

## Review
