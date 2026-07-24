# M89: Numeric `unit` (ICC(A,m)) for `ci_method = "mpl"` — pole-safe Spearman-Brown projection

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M88
- **Driving RR:** —
- **Principles touched:** IP1, GP7
- **Branch/PR:** —

## Goal

Enable a numeric `unit` (D-study projection `ICC(A,m)`, any `m >= 1`) under `ci_method = "mpl"` for balanced-complete two-way random absolute agreement, as the exact pole-safe Spearman-Brown image of the M88-validated `ICC(A,1)` MPL endpoints.

## Scope

**In:** Lift the numeric-`unit` abort ([R/icc.R:1454-1462](R/icc.R:1454)) so a numeric `unit` (random-rater agreement) reaches `mpl_ci`, which already maps any `est$divisor` through `npb_sb()` ([R/ci-mpl.R:252-259](R/ci-mpl.R:252)). Accept any `m >= 1` (integer or not), matching `validate_unit`/the montecarlo path. The reported point is the engine (glmmTMB REML) `ICC(A,m)` point already produced by `icc_point()` (verified live for montecarlo). Vectorized units in one call (e.g. `unit = c("single", "average", 6)`). Roxygen + NEWS + O-MPL registry note + a `D-016` recording the pole-safety justification.

**Out:** On-the-fly `κ_m` / off-grid `(R,S)` geometries → candidate (unchanged). `conf_level != 0.95`, consistency `ICC(C,m)`, fixed-rater agreement projection, one-way/multilevel/replicate/unbalanced → still abort (fences unchanged). Numeric-`unit` npbootstrap unbalanced (SB pole not guaranteed interior when `m > n0`, [R/icc.R:1382-1385](R/icc.R:1382)) stays its own candidate (D-010) — a genuinely distinct, not-pole-safe case.

## Acceptance criteria

- [ ] AC1: For balanced-complete two-way random, `icc(..., ci_method = "mpl", unit = m)` returns an `ICC(A,m)`-labeled interval whose `(conf.low, conf.high)` **equal** `npb_sb()` of the `ICC(A,1)` MPL endpoints at divisor `m` to tolerance 0, for `m in {1, 2, 3.5, R, 8}` — `m = 1` reduces to `ICC(A,1)`, `m = R` reproduces `ICC(A,k)`. (`npb_sb(rho,m) = m*rho/(1+(m-1)*rho)`, McGraw & Wong 1996 Table 4.)
- [ ] AC2: The averaging divisor is mutation-proven (M82 anti-tautology): perturbing `m` moves the endpoints — the `ICC(A,m)` interval is not recoverable from a wrong divisor.
- [ ] AC3: The reported point equals the engine `ICC(A,m)` point (`icc_point` SB image); `std.error` and `samples` are `NA` (deterministic, #4); endpoints lie in `[0,1]` and `conf.low` is monotone increasing in `m` at fixed data (pole-safe: SB pole `rho = -1/(m-1) < 0`, MPL endpoints in `[0,1]`).
- [ ] AC4: Fences preserved under a numeric `unit` — an explicit consistency request aborts and an unset `type` narrows to agreement with a `cli_inform` (ADR-054); `conf_level != 0.95`, one-way, fixed, multilevel, replicate, and unbalanced each still abort (#5/#8). Regression-tested.
- [ ] AC5: Docs — the `icc()` roxygen mpl paragraphs (the `@param unit` note and the mpl sections near [R/icc.R:278](R/icc.R:278)/[305](R/icc.R:305)/[406](R/icc.R:406)/[455](R/icc.R:455)) state numeric `unit` is supported via pole-safe SB inheritance; a NEWS entry; the O-MPL entry ([cairn/references/ORACLES.md:1801](cairn/references/ORACLES.md:1801)) notes the `ICC(A,m)` numeric projection shares the inheritance leg (no new oracle); `check-references` + `enumerate-generalizing-claims.py --check` pass (any new generalizing claim carries a triage row, `OUT-oracle-pin`).
- [ ] AC6: The active profile's `verify` slot is clean — full suite at `NOT_CRAN=true CI=true`, `lintr::lint_package()`, `air format --check`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T4

## Tasks

- [ ] T1: Write failing tests in `tests/testthat/test-ci-mpl.R` — numeric-`unit` `ICC(A,m)` endpoints equal `npb_sb()` of the `ICC(A,1)` endpoints for `m in {1, 2, 3.5, R, 8}`; `m = R` reproduces `ICC(A,k)`; mutation-proof the divisor (AC2); point equals the engine `ICC(A,m)`; `std.error`/`samples` `NA`; `conf.low` monotone in `m`; plus the preserved-fence regressions (AC4).
- [ ] T2: Replace the numeric-`unit` abort block ([R/icc.R:1454-1462](R/icc.R:1454)) so numeric-`unit` random-rater agreement estimands flow to `mpl_ci`; add a GP7 code comment recording the pole-safety argument. Make T1 green.
- [ ] T3: Docs — update the `icc()` roxygen mpl paragraphs and `@param unit`; add a NEWS entry; append the `ICC(A,m)` inheritance note to O-MPL; add any needed `generalizing-claims-triage.tsv` row and run `enumerate-generalizing-claims.py --check` + `check-references` locally.
- [ ] T4: Full verify (`NOT_CRAN=true CI=true`, lintr, `air format --check`); draft `D-016` (pole-safe numeric-`unit` `ICC(A,m)` via SB inheritance, no new oracle; lineage D-015→M88) in this file's Decisions for promotion at review.

## Work log

- 2026-07-24: created by /milestone-plan.

## Decisions

## Review
