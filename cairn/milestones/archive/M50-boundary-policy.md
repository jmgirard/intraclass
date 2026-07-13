# M50: Boundary-fit convergence policy consolidation — DONE

- **Shipped:** 2026-07-13 · PR #56 · Principles: GP7 · Depends: — (M48 needs it)

## Outcome

Replaced scattered per-milestone boundary-fit case law (near-zero / singular
variance components) with one documented policy — no behavior change (no `R/`
edits). `DESIGN.md § Boundary-fit policy` maps every engine (fit-time) and CI
method (interval-time) to one of three behaviors — *smooth* (log-SD / brms
natural-scale positive), *classed deferral* (`intraclass_singular_fit`), and
*reach-zero* (boundary draw kept, or fixed-rater θ²_r average floored at 0) — each
cell citing its ADR. D-004 records it; `test-boundary-policy.R` pins each cell with
one non-vacuous guard. Known-issues wart marked RESOLVED.

## Key decisions & evidence

D-004 consolidates the governing set (002/003/012/014/023/024/025/031/033/037/038/
044) without superseding any ADR. lme4 `isSingular` guard originates in ADR-012
(two-way random), *reused per shape* via ADR-023/024. AC1–AC4 PASS: both checks
0/0/0, guards 14/14, CI matrix green. Three-lens review caught real doc/test gaps
(missing ADR-023/024, under-documented bootstrap warning, vacuous guards) — all
fixed on branch, 0 deferred.
