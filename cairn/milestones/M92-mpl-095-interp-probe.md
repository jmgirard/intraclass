# M92: Off-node S coverage probe for `ci_method = "mpl"` at the shipped `conf_level = 0.95`

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6, GP7

## Goal

Close the one interpolated-S evidence gap M91 left: give `mpl_kappa_lookup()`'s
linear-in-S interpolation coverage evidence at the DEFAULT `conf_level = 0.95`,
where every cell ever swept has sat on an `s_grid` node.

## Scope

**In:** three frozen off-node-S coverage cells at 0.95 (E1–E3 below), pre-registered
before any run (GP5) into `cairn/references/mpl-twoway-random-comparison.md`; a
seeded `data-raw/` sweep script + committed fixture, per-cell `role` asserted against
geometry; the frozen verdict APPLIED, including the shortfall consequence; the
`R/ci-mpl.R` interpolation comment and the `ci_method`/`conf_level` docs restated to
the measured status; both affected ROADMAP candidate rows resolved.

**Out:** re-probing 0.90/0.99 (M91's D1–D3 confirmed those; no new evidence here
changes them) · a monotone smoother over the whole κ_m table, or a bracket-max rule at
0.90/0.99 → stays the ROADMAP envelope candidate, promoted only on evidence at those
levels · re-calibrating any κ_m value → M90's tables are frozen inputs · off-grid
(R,S) extrapolation → still aborts, D-015 · on-the-fly calibration → candidate row.

## Acceptance criteria

- [ ] AC1 (GP5): the E1–E3 pre-registration — geometry, floor, `n_rep`, role, and the
      shortfall consequence — is committed to
      `cairn/references/mpl-twoway-random-comparison.md` in a commit strictly EARLIER
      than the one adding any result, demonstrable from `git log` on the two paths.
- [ ] AC2: a committed seeded script writes a fixture in which each cell's `role` is
      asserted against its geometry (a `stopifnot` mirroring
      `data-raw/m91-mpl-interp-sweep.R:94-98`), and the 0.95 verdict reports
      `interp_ok` as a measured value — never an aggregate over mixed-role cells
      (M91 finding F1).
- [ ] AC3 (GP6): E1, E2 and E3 each report coverage with an exact binomial CI against
      the frozen floor, and the recorded verdict is the frozen rule applied — no floor
      moved after seeing a result.
- [ ] AC4: the frozen shortfall consequence is executed as written — if any cell falls
      below its floor, `mpl_kappa_lookup()` uses the bracket-max rule for off-node S at
      0.95 only, every 0.95 NODE lookup stays bit-identical to today, and the failing
      cell re-runs above its floor; if none falls short, the lookup is unchanged.
- [ ] AC5 (GP7): every in-repo statement about interpolated-S evidence at 0.95 —
      `R/ci-mpl.R`'s interpolation comment, the `@param ci_method`/`conf_level` text,
      and the comparison note — matches what the shipped fixture carries, with a
      test pinning the property the code relies on.
- [ ] AC6: the ROADMAP "off-node S coverage probe at 0.95" candidate is absorbed, and
      the "κ_m monotone envelope / smoother" candidate is updated with this
      milestone's evidence (or dropped, if superseded by the applied consequence).
- [ ] AC7: `devtools::test()`, `devtools::check()`, `lintr::lint_package()` and
      `air format --check` clean; `devtools::document()` no-diff; and both
      references-CI checkers green — `enumerate-generalizing-claims.py --check` and
      `check-reference-observations.py` (M85/M86: `cairn_validate` runs neither, and a
      `check:` directive must settle with python3/shell/git, never `Rscript`).

**Frozen cells** (δ = 4, ρ = 0.60, level 0.95, floor ≥ 0.93, `n_rep` 1000 each — the
0.95 posture M91 used for D4; κ_m from the shipped table):

| cell | R | S | bracket κ_m | why this geometry |
|---|---|---|---|---|
| E1 | 3 | 25 | 0.632 → 0.786 (20→30) | the exact twin of M91's D1 (0.90) / D2 (0.99) — completes the level triple |
| E2 | 10 | 40 | 0.186 → 0.118 (30→50) | the worst 0.95 dip (−0.068); largest RELATIVE error in the `1 + κ_m` scaling the deviance critical value |
| E3 | 2 | 40 | 1.267 → 1.466 (30→50) | largest ABSOLUTE κ_m at 0.95, locally concave so the chord sits below the curve — the under-covering direction |

**Frozen shortfall consequence:** a cell below its floor switches
`mpl_kappa_lookup()` at conf_level 0.95 to the **bracket-max rule** — an off-node S
takes `max()` of its two bracketing node values instead of the linear chord, which is
≥ the chord everywhere so the interval only ever widens, and leaves every node lookup
untouched (preserving M91's bit-identical 0.95 node property). The failing cell then
re-runs at the same `n_rep` against the same floor.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T3, T4, T5, T6

## Tasks

- [ ] T1: Write and commit the E1–E3 pre-registration into
      `cairn/references/mpl-twoway-random-comparison.md` (mirroring the § M91 block at
      line 433) — cells, floors, `n_rep`, roles, the criterion, and the bracket-max
      shortfall consequence — as a standalone docs commit BEFORE any script runs. Any
      settling directive uses python3/shell/git only.
- [ ] T2: Add `data-raw/m92-mpl-095-interp-sweep.R`, modelled on
      `data-raw/m91-mpl-interp-sweep.R` — same `m86-mpl-lib.R` machinery, κ_m taken
      through the interpolation rule under test, per-cell seed stride, the role
      `stopifnot`, and `interp_ok = NA` where a level has no off-node cell. Smoke-run
      it first (`M92_SMOKE=1`).
- [ ] T3: Run the sweep (~15 min), commit `data-raw/m92-interp-sweep.rds`, and record
      the applied verdict per cell in the work log.
- [ ] T4: Execute the frozen consequence. No shortfall → add a test pinning that a
      0.95 off-node lookup equals the linear chord. Shortfall → implement bracket-max
      for 0.95 off-node S in `R/ci-mpl.R`, add tests that every 0.95 node lookup is
      unchanged and off-node values only widen, re-run the failing cell, and add a
      NEWS entry for the widened interpolated intervals.
- [ ] T5: Restate the interpolated-S evidence status at every site that claims it —
      `R/ci-mpl.R`'s interpolation comment, `@param ci_method` / `@param conf_level` in
      `R/icc.R`, and the comparison note — then `devtools::document()`.
- [ ] T6: Resolve both ROADMAP candidate rows, run the full AC7 gate (including the
      two references checkers), and open the PR.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the M91-review-F1 candidate; plan gate froze three cells — the D1/D2 twin, the worst 0.95 dip, and the largest-κ_m geometry — and chose the bracket-max rule over node-restriction as the shortfall consequence, so no currently-working call breaks).

## Decisions

## Review
