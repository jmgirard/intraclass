# M91: Export conf_level ∈ {0.90, 0.99} for ci_method = "mpl"

- **Status:** review
- **Priority:** normal
- **Depends on:** M90
- **Driving RR:** —
- **Principles touched:** IP1, GP5, GP7
- **Branch/PR:** `m91-mpl-conf-level-export` / https://github.com/jmgirard/intraclass/pull/98

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

- [x] AC1: `icc(..., ci_method = "mpl", conf_level = c)` for c ∈ {0.90, 0.99}
      returns an ICC(A,1) interval on the balanced-complete two-way random
      absolute-agreement cell whose endpoints equal `mpl_interval` at the κ_m
      committed in `m90-kappa-tables.rds` for that (R, S, c) — a table→endpoint
      wiring identity; the κ_m values themselves are validated in M90 by BC1's
      published oracle and the coverage sweep, not here (test).
- [x] AC2: ICC(A,k) and ICC(A,m) at the new levels equal the `npb_sb()`
      Spearman-Brown image of the ICC(A,1) endpoints at that level — inheritance
      identity + a mutation guard that diverges on a wrong divisor (M82
      anti-tautology lesson) (test).
- [x] AC3: conf_level outside {0.90, 0.95, 0.99} aborts with a classed
      `intraclass_unsupported` error whose message names the supported set
      (test) — mirrors the off-grid abort.
- [x] AC4: no 0.95 regression — the shipped 0.95 κ_m slice equals
      `m88-kappa-table.rds` exactly (tolerance 0), and 0.95 endpoints on a fixed
      dataset equal the pre-M91 values recorded before the schema change (test).
- [x] AC5: the confirmation sweep clears the floors frozen **before** it runs
      (GP5), at δ=4, ρ=0.60 — M90's tightest configuration (C4/C6) — for **D1**
      (R=3, S=25) @ 0.90 (floor ≥ 0.88, n_rep ≥ 1000); **D2** (3, 25) @ 0.99
      (≥ 0.98, n_rep ≥ 2000); **D3** (2, 40) @ 0.99 (same floor/n_rep — the dip
      large enough in absolute κ_m to move an endpoint: −0.154 over S 30→50, from
      κ_m 0.970 to 0.816, while most dips sit under 0.30); plus **D4**,
      M90's C8 geometry (3, 20, δ1, ρ=0.02) @ 0.95 (≥ 0.93 — M87's frozen
      nominal−2 pp floor, `references/mpl-twoway-random-comparison.md` § M87).
      Exact binomial CI per cell. Pre-registered consequence of a shortfall: the
      affected level is restricted to exact `s_grid` S nodes (interpolated S
      aborts at that level only) — never a loosened floor, never a change to the
      other levels.
- [x] AC6: `@param conf_level` and the `"mpl"` `@param` note state the supported
      set; the D-017 beyond-brief items documented (non-equal-tailed; 0.99 width);
      the `R/ci-mpl.R` interpolation comment corrected with the measured
      per-level worst downward step (GP7); NEWS entry.
- [x] AC7: `devtools::check()` Status OK; `cairn_validate` exit 0; the
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
- [x] T3: Assemble the conf_level-keyed κ_m table — 0.95 verbatim from
      `m88-kappa-table.rds`, 0.90/0.99 from `m90-kappa-tables.rds` — and
      regenerate `R/sysdata.rda` from a `data-raw/` generator carrying
      provenance `meta` (source fixture + level per slice).
- [x] T4: Key `mpl_kappa_lookup` (`R/ci-mpl.R:204`) on (n_r, n_s, conf_level),
      keeping per-level S-interpolation; confirm `mpl_ci` (already receives
      conf_level) selects the right slice.
- [x] T5: Lift the `R/icc.R:1465` fence to conf_level ∈ {0.90, 0.95, 0.99};
      abort otherwise via a classed `intraclass_unsupported` error listing the
      set (mirror the `mpl_kappa_lookup` off-grid abort).
- [x] T6: Tests — new-level endpoints vs `mpl_interval` at the fixture κ_m; SB
      inheritance at new levels + mutation guard; off-level classed abort +
      message; 0.95 slice equality + endpoint no-regression.
- [x] T7: Docs (`@param conf_level` + `"mpl"` `@param`; the corrected
      interpolation comment; non-equal-tailed + 0.99-width notes), NEWS, and the
      references/lint consistency sweep (AC7's three gates); run the verify slot
      clean.

## Work log

- 2026-07-24: created by /milestone-plan (with M90); depends on M90's per-level GO; lineage D-015 → this.
- 2026-07-24: M90's RR03/D-017 gates this export (BC7 — 0.99 exportable only if BC1–BC6 pass; a NO-GO level stays a candidate). Folded the RR03 beyond-brief doc duties into Scope/T5. BCs are ingested verbatim in M90 (Driving RR there), not re-ingested here.
- 2026-07-24: re-planned against shipped M90 (`/milestone-plan M91`). Both levels GO, so the 0.99 hedge is gone. Measured the falsified interpolation comment: non-monotone in S at ALL levels (worst step −0.046/−0.068/−0.162 at 0.90/0.95/0.99) — a correction, not a softening. Found M90's 8 coverage cells all on `s_grid` nodes, so interpolated κ_m is unvalidated at the new levels; BC1's S=25 κ_m cannot fill it (published ρ grid, not the extended production grid — interp 0.777 vs BC1 0.535 at R=3 is the deliberate extended-range margin). Gate: raw calibrated values, +3 confirmation cells (2 off-node + the absorbed 0.95 sub-grid-floor candidate), vignette gap → candidate. AC 6→7, T 5→7.
- 2026-07-24: T1 — pre-registered the four confirmation cells D1–D4 in `references/mpl-twoway-random-comparison.md` § M91 (floors, n_rep, interpolated-κ_m rule, shortfall consequence) and froze it BEFORE any run (GP5). Gate: shortfall → restrict that level to exact `s_grid` S nodes; added D3 (2, 40) @ 0.99 for the −0.154 dip where κ_m ≈ 0.82–0.97 — AC5 gate-amended 3→4 cells (128/149 lines). 6 new generalizing claims triaged `OUT-oracle-pin`; both references gates green.
- 2026-07-24: T2 — `data-raw/m91-mpl-interp-sweep.R` → `m91-interp-sweep.rds`: all four cells clear their frozen floors (D1 0.934, D2 0.9995, D3 1.0000, D4 0.996), so interpolated S is confirmed at all three levels and the pre-registered restriction does not fire. Two doc consequences: D1's misses are 65/1 (one-sidedness reconfirmed off-node), and D3's median width 0.905 is the FIRST cell to cross BC6's ≥0.90 near-vacuity trigger (M90's widest was 0.852). D4 closes the RR03 rec-#9 sub-grid-floor gap at 0.95. Fixed M90's logged F2 (cross-cell RNG overlap) in the new script's seed stride.
- 2026-07-24: T3–T5 — `data-raw/m91-mpl-kappa-sysdata.R` assembles the conf_level-keyed table (162 rows = 3 levels × 54 nodes; 0.95 copied verbatim from `m88-kappa-table.rds`, asserted identical in the generator); `mpl_kappa_lookup` keyed on (n_r, n_s, conf_level) with per-slice S-interpolation + a defensive classed abort; `icc()` fence lifted to the table's own level set. Neutralized M88's now-stale `use_data()` call — re-running it would have overwritten sysdata with the pre-M91 3-column schema and broken every mpl lookup.
- 2026-07-24: T6 — tests for the level-keyed wiring, SB inheritance at the new levels + wrong-divisor mutation guard, the classed off-level abort (0.80/0.975/0.995/0.999) with the set named, the 0.95 κ_m slice pins, and 0.95 endpoint no-regression against literals recorded pre-change (incl. off-node S=25). Mutation-checked: forcing the lookup back to the 0.95 slice reds 4 assertions in the wiring test and nothing else — the ordering test is honestly scoped as a sanity property (it survives the mutation, as its comment says).
- 2026-07-24: T7 — corrected my OWN new prose twice before commit (M72 lesson): the dips' κ_m range was written ≈0.10–0.27 in four places when the 18 dips span 0.102–0.970 (5 above 0.27), and the M87 max width was written 0.698 when the table shows 0.744. Both re-derived from the fixtures and fixed; the references-page paragraph carries a marked in-place correction.
- 2026-07-24: all tasks done; verify slot clean on the final tree — `devtools::test()` FAIL 0 / PASS 4206 (2 pre-existing lavaan negative-variance WARNs, 23 skips), `devtools::document()` no diff, `lintr::lint_package()` clean, `pkgdown::check_pkgdown()` clean, `cairn_validate` exit 0, both references gates green. `devtools::check()` running for AC7. Status → review.
- 2026-07-25: review gate — PR #98 CI caught a defect the local gate structurally cannot see: T1's settling directive called `Rscript`, but the `check-references` job is Python-only, so the claim could never settle there (`Rscript: command not found` → falsified). Rewrote it as a text-only python3 check over the note's own frozen-cells table, mutation-verified (drop 100 from the node set → exit 1). No other `check: Rscript` directive exists in the corpus.
- 2026-07-25: 3-lens review + scorer — 2 findings, both actioned (F1 93, F2 88), none sub-threshold. F1 is the substantive one: D4's S=20 is an `s_grid` NODE, so the "interpolated S confirmed at all three levels" claim was false at the shipped 0.95 — fixed at the root (per-cell `role`, geometry-asserted; `interp_ok = NA` where unprobed) plus all four prose sites, and the residual 0.95 gap filed as a candidate. Seeded re-run reproduced every measured column identically.

## Decisions

## Review

**Gate run 2026-07-24 on `m91-mpl-conf-level-export` @ ae67880, PR #98.**
`origin/main` had not moved since the branch was cut (no merge needed).

Acceptance criteria — fresh evidence, one line each:

- **AC1** — at (R=4, S=20), `icc(..., conf_level = c)` endpoints equal
  `mpl_interval()` at the κ_m committed in `m90-kappa-tables.rds` with
  **max |diff| = 0.00e+00** at both new levels (0.90: κ 0.4531423 →
  [0.4946612344, 0.8450400826]; 0.99: κ 0.4801807 → [0.2287657997,
  0.9028120184]). Mutation-verified: forcing the lookup back to the 0.95 slice
  reds exactly these assertions (4) and nothing else.
- **AC2** — ICC(A,k)/ICC(A,m) equal an *independently recomputed* Spearman-Brown
  image, max |diff| **0.00e+00** over m ∈ {2, 3.5, 4, 8} at both new levels; the
  wrong-divisor guard separates by ≥ 0.0113 (0.90) and ≥ 0.0240 (0.99), so the
  equality pins the divisor rather than mere monotonicity.
- **AC3** — conf_level 0.80 / 0.975 / 0.995 / 0.999 each abort with class
  `intraclass_unsupported`; the message names the set (`"0.90"`, `"0.95"`, and
  `"0.99"`). 0.995/0.999 cover D-017's no-deeper-than-0.99 boundary.
- **AC4** — the shipped 0.95 κ_m slice is `identical()` to
  `m88-kappa-table.rds` (54 rows, tolerance 0), and 0.95 endpoints reproduce the
  pre-change literals exactly: ICC(A,1) [0.42467599012062407,
  0.86530180057602046], ICC(A,k) [0.74700222803863625, 0.96254122832062028].
- **AC5** — `m91-interp-sweep.rds` (seeded, `smoke=FALSE`, seed_base 20260724,
  per-cell stride 1e6): D1 0.9340 [0.9168, 0.9486] ≥ .88 · D2 0.9995 [0.9972,
  1.0000] ≥ .98 · D3 1.0000 [0.9982, 1.0000] ≥ .98 · D4 0.9960 [0.9898, 0.9989]
  ≥ .93 — all `adequate = TRUE`, Clopper–Pearson per cell, floors frozen in a
  commit (f848057) that precedes the run, so no cell triggers the pre-registered
  `s_grid` restriction. Interpolation itself is confirmed at 0.90 (D1) and 0.99
  (D2, D3) only — D4's S=20 is a node, so the fixture records `interp_ok = NA`
  at 0.95 (finding F1). A seeded re-run reproduced every measured column
  `identical()`.
- **AC6** — `man/icc.Rd` carries the level set, `not equal-tailed`, and the
  `near-vacuous` 0.905 width; NEWS.md likewise; `R/ci-mpl.R` states `NOT
  monotone` with the per-level worst steps (−0.046 / −0.068 / −0.162) and the
  falsified "roughly concave" text is gone (0 occurrences). No milestone numbers
  leak into user-facing text.
- **AC7** — `devtools::check()` **0 errors, 0 warnings, 0 notes**;
  `devtools::test()` at `NOT_CRAN=true CI=true` FAIL 0 / PASS 4206 (2
  pre-existing lavaan negative-variance WARNs, 23 skips) — both bases run, so
  `skip_on_cran` tests are not hidden behind the CRAN-parity check;
  `cairn_validate` exit 0; `enumerate-generalizing-claims.py --check` and
  `check-reference-observations.py` both green (0 unmarked, 0 falsified, 0
  orphan rows — after fixing a directive CI caught that local runs could not, see
  the work log for 2026-07-25); `lintr::lint_package()` and
  `pkgdown::check_pkgdown()` clean.

**Consistency gate.** `cairn_validate` exit 0 — all 16 PASS checks including
`coverage complete`, `binding criteria`, `weight caps`, and `principles slot
valid`. Two advisories: `dangling id tokens` (321) is pre-existing stale
milestone-ids in `COVERAGE.md`/`estimand-specs` and fell by one over this
milestone; `record density` flagged the ROADMAP hygiene stamp at 528 chars and
was fixed by rewriting it, not appending. No principle text changed, so
`cairn_impact` does not apply (the `Principles touched` slot records IP1/GP5/GP7
as *worked under*). Profile `consistency-gate` slot: `document()` no diff,
README.md in sync with README.Rmd, pkgdown clean, NEWS entry present,
`data-raw/` covered by `.Rbuildignore`, full `check()` clean.
**Independent review — three lenses + scorer.** [O] diff-bug (Opus, full diff vs the
criteria, DECISIONS and conventions): 2 findings, both documentation. [S]
blame-history (Sonnet, `git log`/`blame` on the modified lines): no findings — it
independently established that RR03 had already flagged the interpolation comment as
false, so correcting it restores a claim rather than removing a safeguard, and that
the removed M88 `use_data()` call leaves the fixture→sysdata chain intact via the new
generator. [S] prior-review (Sonnet): no findings; its probe found the GitHub inline
comment surface empty (`pulls/comments` → `[]`), so archived `## Review` sections and
`LESSONS.md` were the evidence base. Nothing scored below 80, so nothing was logged
sub-threshold.

Actioned findings, verbatim:

- **F1 (93)** — `R/ci-mpl.R:211`: the comment claimed "M91's cells D1-D4 sweep
  off-node S at all three levels ... every one clears its frozen floor (0.934 at
  0.90, 0.9995/1.000 at 0.99, 0.996 at 0.95)". The 0.996 comes from D4, whose S=20
  is an exact `s_grid` node, so no interpolation occurs there — interpolated S at the
  **default** 0.95 has no coverage evidence, and 0.95's worst dip (−0.068 at R=10,
  S 30→50) is unprobed. The overclaim had propagated to the references-page verdict
  heading and body, the sweep script's per-level printout, and a ROADMAP candidate
  row. **Fixed at the root, not just in prose:** the sweep script now carries a
  per-cell `role` (`interp` vs `subgrid_rho`) asserted against the geometry, and
  reports `interp_ok = NA` where a level has no off-node cell — absence of a probe is
  no longer reportable as confirmation. All four prose sites corrected; the residual
  0.95 gap is now a candidate row. (Fixing this exposed a second-order bug in my own
  fix — `role` was missing from the summary row, so the first re-run reported "NOT
  PROBED" at *every* level; caught by reading the output, corrected, and the seeded
  re-run reproduced all measured numbers identically.)
- **F2 (88)** — `R/icc.R:1429` and `R/icc.R:2098`: two comments accurate before this
  diff and falsified by it, neither updated — "only at the default 95% two-sided
  level its kappa_m table is calibrated for" and "conf_level 0.95 upstream" — now
  contradicting the fence three lines below. A maintainer auditing the fence could
  read them as evidence that 0.90/0.99 reaching `mpl_ci` is a guard leak and revert
  the milestone's purpose. Both corrected to name the calibrated set and its source.

Also fixed during the gate: PR CI's `check-references` job failed where local runs
could not — T1's settling directive called `Rscript` and that job is Python-only
(`Rscript: command not found` → falsified). Rewritten as a text-only `python3` check
over the note's own frozen-cells table and mutation-verified; no other
`check: Rscript` directive exists in the corpus.

**PR #98 CI: green 9/9** on d3523e3 — `check-references`, `format-check`, `lint`, `pkgdown`, `test-coverage`, `ubuntu-latest (release)`, `windows-latest (release)`, `codecov/patch`, `codecov/project`; `mergeable=MERGEABLE`, `mergeStateStatus=CLEAN`. (The heavy jobs on the preceding commit were cancelled by the findings push — the documented `cancel-in-progress` behavior, M78 — so this run is the authoritative one.)
