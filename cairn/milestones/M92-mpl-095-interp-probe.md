# M92: Off-node S coverage probe for `ci_method = "mpl"` at the shipped `conf_level = 0.95`

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5, GP6, GP7
- **Branch/PR:** `m92-mpl-095-interp-probe` · https://github.com/jmgirard/intraclass/pull/99

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
| E3 | 2 | 40 | 1.267 → 1.466 (30→50) | large-κ_m CONCAVE bracket, so the chord sits below the curve — the under-covering direction; D3's geometry at the shipped level (corrected T6: not the slice's largest κ_m — R=2, S 50→100 is higher) |

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

- [x] T1: Write and commit the E1–E3 pre-registration into
      `cairn/references/mpl-twoway-random-comparison.md` (mirroring the § M91 block at
      line 433) — cells, floors, `n_rep`, roles, the criterion, and the bracket-max
      shortfall consequence — as a standalone docs commit BEFORE any script runs. Any
      settling directive uses python3/shell/git only.
- [x] T2: Add `data-raw/m92-mpl-095-interp-sweep.R`, modelled on
      `data-raw/m91-mpl-interp-sweep.R` — same `m86-mpl-lib.R` machinery, κ_m taken
      through the interpolation rule under test, per-cell seed stride, the role
      `stopifnot`, and `interp_ok = NA` where a level has no off-node cell. Smoke-run
      it first (`M92_SMOKE=1`).
- [x] T3: Run the sweep (~15 min), commit `data-raw/m92-interp-sweep.rds`, and record
      the applied verdict per cell in the work log.
- [x] T4: Execute the frozen consequence. No shortfall → add a test pinning that a
      0.95 off-node lookup equals the linear chord. Shortfall → implement bracket-max
      for 0.95 off-node S in `R/ci-mpl.R`, add tests that every 0.95 node lookup is
      unchanged and off-node values only widen, re-run the failing cell, and add a
      NEWS entry for the widened interpolated intervals.
- [x] T5: Restate the interpolated-S evidence status at every site that claims it —
      `R/ci-mpl.R`'s interpolation comment, `@param ci_method` / `@param conf_level` in
      `R/icc.R`, and the comparison note — then `devtools::document()`.
- [x] T6: Resolve both ROADMAP candidate rows, run the full AC7 gate (including the
      two references checkers), and open the PR.

## Work log

- 2026-07-25: created by /milestone-plan (promotes the M91-review-F1 candidate; plan gate froze three cells — the D1/D2 twin, the worst 0.95 dip, and the largest-κ_m geometry — and chose the bracket-max rule over node-restriction as the shortfall consequence, so no currently-working call breaks).
- 2026-07-25: T1 done — § M92 pre-registration frozen in `mpl-twoway-random-comparison.md` (E1–E3, floors, criterion, bracket-max consequence + why it departs from § M91's node-restriction for the shipped level); its dated observation carries a python3-only settling directive, mutation-verified to exit 1 when D4's S is changed off-node; 5 generalizing-claim candidates triaged `OUT-repo-analysis` by generated rows; both references checkers green.
- 2026-07-25: T2 done — `data-raw/m92-mpl-095-interp-sweep.R` added; mirrors the M91 generator (m86-mpl-lib machinery, per-cell seed stride, role `stopifnot`) and adds two extra assertions (no cell on an `s_grid` node, every cell at 0.95) plus an `M92_RULE=linear|bracketmax` switch so the pre-registered shortfall re-run uses the same generator. Smoke run clean; air + lintr clean; no citekey named, so no D-009 directive is re-tripped.
- 2026-07-25: T3 done — sweep run, `data-raw/m92-interp-sweep.rds` committed. All three cells clear the frozen 0.93 floor under the SHIPPED linear rule, so the pre-registered bracket-max consequence is NOT triggered: E1 (R=3,S=25) κ_m 0.7089 cov 0.9680 [0.9551, 0.9780] miss 32/0; E2 (R=10,S=40, the worst 0.95 dip) κ_m 0.1517 cov 0.9530 [0.9380, 0.9653] miss 34/13; E3 (R=2,S=40, largest κ_m) κ_m 1.3663 cov 1.0000 [0.9963, 1.0000] miss 0/0. `interp_ok = TRUE` at 0.95 on three off-node cells, no mixed-role aggregation.
- 2026-07-25: T4 done — no-shortfall branch taken, so `mpl_kappa_lookup()` is UNCHANGED and bracket-max is not adopted. Added the M92 AC5 pin in `tests/testthat/test-ci-mpl.R`: the three coverage-validated 0.95 constants (0.7089067 / 0.1517143 / 1.3663359) plus an assertion that S = 25 and S = 40 are genuinely off-grid. Checked the pin discriminates the two rules rather than only a table edit — bracket-max would give 0.7862854 / 0.1857780 / 1.4656788 at the same geometries, so all three literals red under the alternative. No NEWS entry for a behaviour change: none happened.
- 2026-07-25: T5 done — restated the evidence status at five sites: `R/ci-mpl.R`'s GP7 interpolation comment (0.95 now confirmed, with the three cells and the untriggered consequence named), `@param ci_method` in `R/icc.R` (adds the interpolated-path guarantee), `NEWS.md` (same, user-facing), the note's new § M92 verdict, and § M91's now-false standing claim that 0.95 remains unprobed — corrected in place and marked superseded, not rewritten (D-045). Also narrowed the one-sidedness wording everywhere it appeared: E2 measured 34/13 at R = 10 against D1's 65/1 at R = 3, so the blanket reading was wrong. `document()` re-run (man/icc.Rd), ledger refreshed (1 orphan row dropped, 5 added), both references checkers + cairn_validate green, 169 mpl tests pass.
- 2026-07-25: correction (supersedes the "largest κ_m" wording in the plan-gate and T3 entries above, which are history and stay as written). Ran the M72 self-check — grep own new prose for counts and universals, re-derive each against the source — over everything this milestone wrote. E2's "worst 0.95 downward step" holds (−0.0681 at R=10, S 30→50 is the most negative in the slice). **E3's "largest κ_m at 0.95" does not**: `(R=2, S 50→100)` is higher at 1.4657 → 1.6245 and the slice maximum is 1.6245 at `(2, 100)`. E3 is the largest-κ_m cell THIS pass sweeps, on a concave bracket, at D3's geometry — which is the real reason it was chosen. Corrected at all four live sites (pre-registration bullet + cells row, § M92 verdict, `R/ci-mpl.R`, the AC table), marked in place per D-045; cells, floors and `n_rep` untouched, so the frozen bar is unchanged (GP5).
- 2026-07-25: T6 done — envelope candidate row updated with M92's evidence (two passes now find no coverage cost to the dips; promote only on a NEW failure); the probe candidate was already absorbed at the plan gate. Gate: `devtools::check(env_vars = c(NOT_CRAN = "false"), manual = FALSE)` → Status OK, 0 errors / 0 warnings / 0 notes; full suite at `NOT_CRAN=true CI=true` → FAIL 0, PASS 4210, SKIP 23, WARN 2 (pre-existing glmmTMB convergence warnings on the multilevel path — verified not ours: `git diff main..HEAD -- R/` changes zero non-comment lines); air + lintr clean; `document()` no-diff; both references checkers and cairn_validate green. AC1 ordering verified from git log: pre-registration da10025 (08:55:23) precedes the first result 2b984af (08:58:08). Manual built with `--no-manual` locally (known TinyTeX Courier font gap, not an Rd problem); CI builds it.
- 2026-07-25: all tasks done, gate clean; PR #99 opened, status -> review.

## Decisions


## Review
