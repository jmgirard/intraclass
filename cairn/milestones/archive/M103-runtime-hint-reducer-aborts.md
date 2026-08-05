# M103: Reducer-stage degeneracy aborts name a `ci_method` verified on the caller's own data

**Status:** done (2026-08-05, PR #111 https://github.com/jmgirard/intraclass/pull/111)

**Goal:** Every CI-reducer degeneracy abort names an alternative `ci_method` only after
running that method on the caller's own data, or names none.

**Outcome:** All six `intraclass_singular_fit` guards under `R/ci-*.R` take a lazy `hint`, so a
successful call never pays for verification. `boundary_method_usable()` gained `bootstrap` and
`montecarlo` rows (they take the engine fit, not `df`); `boundary_method_hint()` gained
self-exclusion and two tiers, design-fenced methods first and the engine-fit pair only when none
serves. `hint_screen_samples` (25) screens the expensive candidate, `hint_verify_boot_cap` (199)
caps its full run, and the bullet names that count so the promised call is the verified one.
`icc()` threads the fit to every guard, the default included. Evidence:
`data-raw/sweep-abort-remedies.R` + `tests/testthat/fixtures/abort-remedy-sweep.tsv`, plus
`check-abort-remedy-verdicts.R`, which runs each accepted bullet's promised call.

**Decisions:** Bullets are tiered by cost, fenced methods first. The default path gets the
engine-fit tier with verification bounded at both ends — superseding a withholding decision whose
"no such dataset" premise this milestone's own AC6 fixture falsified.

**Review:** Three defect returns: pass 1 actioned F5/F11 (95), F8, F7, F1; pass 2 G1 (93), G5 (85),
G2, G7. Pass 3 passed — 30 candidates, 3 at >= 80 (D1/D2/D18, `@param` and NEWS prose the branch
falsified), fixed in session, prior-review lens zero. Also fixed: a Linux/Windows-only test defect,
and a suite-cost regression (~40 -> ~19 min per CI job).
