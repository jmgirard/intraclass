# M49: Standing cross-engine parity matrix — DONE

- **Shipped:** 2026-07-12 · PR #55 · Principles: GP4 · Depends: — (M48 needs it)

## Outcome

`tests/testthat/test-engine-parity-matrix.R` replaces the milestone-by-milestone
parity checks (silent-drift wart). It enumerates the (estimand × engine) grid as 8
principal-variant cells and each run pins frequentist point-estimate agreement vs
glmmTMB (lme4 tight REML; lavaan two-way — consistency exact, agreement to the
sourced SEM small-sample tolerance), asserts every documented engine refusal fires
(`intraclass_unsupported`), and reads `icc()`'s engine roster from its own body so
a 5th engine breaks it (GP4). Test + docs only (brms parity stays in
`test-icc-brms.R`); DESIGN.md § Architecture documents it, wart marked RESOLVED.

## Key decisions

In-file matrix test; cross-reference (not migrate) ad-hoc tests; N/A cells assert
the classed abort; one principal variant per spec. Tolerances calibrated and split
by index class (lavaan agreement only asymptotically REML-equal; consistency exact).

## Evidence

AC1–AC4 PASS. `check(--as-cran)` 0/0/0; installed `check(NOT_CRAN=true,CI=true)`
OK 0/0/0; 73 assertions + full CI matrix green. Review: no correctness findings.
