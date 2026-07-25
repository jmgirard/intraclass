# M91: Export conf_level ∈ {0.90, 0.99} for ci_method = "mpl"

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M90
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP7
- **Branch/PR:** `m91-mpl-conf-level-export`

## Goal

Enable `icc(..., ci_method = "mpl", conf_level = c)` for c ∈ {0.90, 0.99} to
return a validated two-way random ICC(A,1)/ICC(A,k)/ICC(A,m) interval, extending
the shipped 0.95-only support to the M90-calibrated levels.

## Scope

**In:** Wire M90's **both-levels GO** (`m90-verdict.rds`: 0.90 min coverage 0.915,
0.99 min 0.997, no failed cells) into the exported method, per D-017. Extend the
internal κ_m table (`R/sysdata.rda`) to carry a conf_level key, assembled from the
committed fixtures — 0.95 **verbatim** from `m88-kappa-table.rds`, 0.90/0.99 from
`m90-kappa-tables.rds`. Ship the **raw calibrated values**: they are exactly what
M90's coverage validated, so every shipped number traces to a fixture (plan gate
2026-07-24). Key `mpl_kappa_lookup` (`R/ci-mpl.R:204`) on (n_r, n_s, conf_level),
keeping the per-level S-interpolation; thread conf_level through `mpl_ci`. Lift the
`conf_level == 0.95`-only fence (`R/icc.R:1465`) to {0.90, 0.95, 0.99}, aborting
loudly otherwise (classed, message names the set — #5/#8; D-017 authorizes no level
deeper than 0.99). One **interpolation-confirmation sweep**: M90's 8 cells all sat on
`s_grid` nodes, so interpolated κ_m has no coverage evidence at the new levels — add
off-node S cells at both new levels (incl. the one geometry whose dip is large enough
to move an endpoint), plus the 0.95 sub-grid-floor (ρ=0.02) cell that makes the
below-grid posture uniform across levels (absorbs that candidate row).
Tests, `@param` doc updates, NEWS, and the D-017 beyond-brief documentation: the
two-sided interval's non-equal-tailed character (all levels, incl. 0.95), the
near-vacuous small-geometry 0.99 width (BC6), and **correcting** — not merely
softening — the `R/ci-mpl.R` "increasing and roughly concave" comment: the table is
non-monotone in S at every level (worst downward step −0.046 at 0.90 / −0.068 at the
shipped 0.95 / −0.162 at 0.99), so its claim that linear interpolation is
conservatively biased is false in both directions.

**Out:** Calibration/coverage evidence for the levels themselves → M90 (consumed here
as fixtures + GO). A monotone envelope or smoother over the dips → candidate row
(would ship numbers no calibration run produced, breaking traceability to M90's
sweep). Levels off {0.90, 0.95, 0.99}, and any level deeper than 0.99 → abort
(D-017); arbitrary continuous conf_level via α-interpolation → candidate. Off-grid
(R, S) + design fences → unchanged. A vignette section for the opt-in `ci_method`
values → candidate row (none of the four is documented there; a method-wide job).

## Acceptance criteria

- [ ] AC1: `icc(..., ci_method = "mpl", conf_level = c)` for c ∈ {0.90, 0.99}
      returns an ICC(A,1) interval on the balanced-complete two-way random
      absolute-agreement cell whose endpoints equal `mpl_interval` at the κ_m
      committed in `m90-kappa-tables.rds` for that (R, S, c) — a table→endpoint
      wiring identity; the κ_m values themselves are validated in M90 by BC1's
      published oracle and the coverage sweep, not here (test).
- [ ] AC2: ICC(A,k) and ICC(A,m) at the new levels equal the `npb_sb()`
      Spearman-Brown image of the ICC(A,1) endpoints at that level — inheritance
      identity + a mutation guard that diverges on a wrong divisor (M82
      anti-tautology lesson) (test).
- [ ] AC3: conf_level outside {0.90, 0.95, 0.99} aborts with a classed
      `intraclass_unsupported` error whose message names the supported set
      (test) — mirrors the off-grid abort.
- [ ] AC4: no 0.95 regression — the shipped 0.95 κ_m slice equals
      `m88-kappa-table.rds` exactly (tolerance 0), and 0.95 endpoints on a fixed
      dataset equal the pre-M91 values recorded before the schema change (test).
- [ ] AC5: the confirmation sweep clears the floors frozen **before** it runs
      (GP5), at δ=4, ρ=0.60 — M90's tightest configuration (C4/C6) — for **D1**
      (R=3, S=25) @ 0.90 (floor ≥ 0.88, n_rep ≥ 1000); **D2** (3, 25) @ 0.99
      (≥ 0.98, n_rep ≥ 2000); **D3** (2, 40) @ 0.99 (same floor/n_rep — the sole
      dip large enough in absolute κ_m to move an endpoint: −0.154 over S 30→50
      where κ_m ≈ 0.82–0.97, vs ≈0.10–0.27 at the large-R dips); plus **D4**,
      M90's C8 geometry (3, 20, δ1, ρ=0.02) @ 0.95 (≥ 0.93 — M87's frozen
      nominal−2 pp floor, `references/mpl-twoway-random-comparison.md` § M87).
      Exact binomial CI per cell. Pre-registered consequence of a shortfall: the
      affected level is restricted to exact `s_grid` S nodes (interpolated S
      aborts at that level only) — never a loosened floor, never a change to the
      other levels.
- [ ] AC6: `@param conf_level` and the `"mpl"` `@param` note state the supported
      set; the D-017 beyond-brief items documented (non-equal-tailed; 0.99 width);
      the `R/ci-mpl.R` interpolation comment corrected with the measured
      per-level worst downward step (GP7); NEWS entry.
- [ ] AC7: `devtools::check()` Status OK; `cairn_validate` exit 0; the
      `check-references` job green — including
      `check-reference-observations.py` for the new `data-raw/` files naming
      `xiao2013` (M86 lesson) and a triage row for any new generalizing claim
      (M85 lesson); lintr (incl. `data-raw/`, M62) + pkgdown clean.

## Coverage

- AC1 → T3, T4, T6
- AC2 → T6
- AC3 → T5, T6
- AC4 → T3, T6
- AC5 → T1, T2
- AC6 → T7
- AC7 → T7

## Tasks

- [x] T1: Pre-register the four confirmation cells D1–D4 in
      `references/mpl-twoway-random-comparison.md` § M91 — geometries, floors,
      n_rep, verdict rule, shortfall consequence — and commit it **before** any
      run (GP5, mirroring M90's § M90 pre-registration).
- [x] T2: Seeded `data-raw/m91-mpl-interp-sweep.R` running D1–D4 (reuse
      `m86-mpl-lib.R` + M90's sweep harness), κ_m via the interpolation path
      under test → committed fixture; apply the frozen floors and append the
      verdict to the references page.
- [ ] T3: Assemble the conf_level-keyed κ_m table — 0.95 verbatim from
      `m88-kappa-table.rds`, 0.90/0.99 from `m90-kappa-tables.rds` — and
      regenerate `R/sysdata.rda` from a `data-raw/` generator carrying
      provenance `meta` (source fixture + level per slice).
- [ ] T4: Key `mpl_kappa_lookup` (`R/ci-mpl.R:204`) on (n_r, n_s, conf_level),
      keeping per-level S-interpolation; confirm `mpl_ci` (already receives
      conf_level) selects the right slice.
- [ ] T5: Lift the `R/icc.R:1465` fence to conf_level ∈ {0.90, 0.95, 0.99};
      abort otherwise via a classed `intraclass_unsupported` error listing the
      set (mirror the `mpl_kappa_lookup` off-grid abort).
- [ ] T6: Tests — new-level endpoints vs `mpl_interval` at the fixture κ_m; SB
      inheritance at new levels + mutation guard; off-level classed abort +
      message; 0.95 slice equality + endpoint no-regression.
- [ ] T7: Docs (`@param conf_level` + `"mpl"` `@param`; the corrected
      interpolation comment; non-equal-tailed + 0.99-width notes), NEWS, and the
      references/lint consistency sweep (AC7's three gates); run the verify slot
      clean.

## Work log

- 2026-07-24: created by /milestone-plan (with M90); depends on M90's per-level GO; lineage D-015 → this.
- 2026-07-24: M90's RR03/D-017 gates this export (BC7 — 0.99 exportable only if BC1–BC6 pass; a NO-GO level stays a candidate). Folded the RR03 beyond-brief doc duties into Scope/T5. BCs are ingested verbatim in M90 (Driving RR there), not re-ingested here.
- 2026-07-24: re-planned against shipped M90 (`/milestone-plan M91`). Both levels GO, so the 0.99 hedge is gone. Measured the falsified interpolation comment: non-monotone in S at ALL levels (worst step −0.046/−0.068/−0.162 at 0.90/0.95/0.99) — a correction, not a softening. Found M90's 8 coverage cells all on `s_grid` nodes, so interpolated κ_m is unvalidated at the new levels; BC1's S=25 κ_m cannot fill it (published ρ grid, not the extended production grid — interp 0.777 vs BC1 0.535 at R=3 is the deliberate extended-range margin). Gate: raw calibrated values, +3 confirmation cells (2 off-node + the absorbed 0.95 sub-grid-floor candidate), vignette gap → candidate. AC 6→7, T 5→7.
- 2026-07-24: T1 — pre-registered the four confirmation cells D1–D4 in `references/mpl-twoway-random-comparison.md` § M91 (floors, n_rep, interpolated-κ_m rule, shortfall consequence) and froze it BEFORE any run (GP5). Gate: shortfall → restrict that level to exact `s_grid` S nodes; added D3 (2, 40) @ 0.99 for the −0.154 dip where κ_m ≈ 0.82–0.97 — AC5 gate-amended 3→4 cells (128/149 lines). 6 new generalizing claims triaged `OUT-oracle-pin`; both references gates green.
- 2026-07-24: T2 — `data-raw/m91-mpl-interp-sweep.R` → `m91-interp-sweep.rds`: all four cells clear their frozen floors (D1 0.934, D2 0.9995, D3 1.0000, D4 0.996), so interpolated S is confirmed at all three levels and the pre-registered restriction does not fire. Two doc consequences: D1's misses are 65/1 (one-sidedness reconfirmed off-node), and D3's median width 0.905 is the FIRST cell to cross BC6's ≥0.90 near-vacuity trigger (M90's widest was 0.852). D4 closes the RR03 rec-#9 sub-grid-floor gap at 0.95. Fixed M90's logged F2 (cross-cell RNG overlap) in the new script's seed stride.

## Decisions

## Review
