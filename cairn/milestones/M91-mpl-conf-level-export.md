# M91: Export conf_level ∈ {0.90, 0.99} for ci_method = "mpl"

- **Status:** planned
- **Priority:** normal
- **Depends on:** M90
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Enable `icc(..., ci_method = "mpl", conf_level = c)` for c ∈ {0.90, 0.99} to
return a validated two-way random ICC(A,1)/ICC(A,k)/ICC(A,m) interval, extending
the shipped 0.95-only support to the M90-calibrated levels.

## Scope

**In:** Wire the M90 GO into the exported method. Extend the internal κ_m table
(`R/sysdata.rda`) to carry a conf_level index and regenerate it from the M90
fixtures ({0.90, 0.95, 0.99}); key `mpl_kappa_lookup` (`R/ci-mpl.R:204`) on
(n_r, n_s, conf_level), keeping the per-level S-interpolation; thread conf_level
through `mpl_ci`. Lift the `conf_level == 0.95`-only fence (`R/icc.R:1467`) to
admit the calibrated set and abort loudly otherwise (classed, message lists the
supported levels — mirrors the off-grid abort, #5/#8). The exported set is
whatever M90's BC7 verdict cleared (0.90 GO; 0.99 conditional — a NO-GO level
stays a candidate, not exported). Tests, `@param` doc updates, NEWS — including
the RR03 beyond-brief documentation: the two-sided MPL interval's non-equal-tailed
character (all levels, incl. 0.95), the small-geometry near-vacuous 0.99 width
(BC6), and softening the now-falsified `R/ci-mpl.R` "increasing and roughly
concave" interpolation comment (non-monotone at R≥8).

**Out:** Calibration/coverage evidence → M90 (consumed here as fixtures + GO).
Levels off {0.90, 0.95, 0.99} → abort; arbitrary continuous conf_level via
α-interpolation → candidate. Off-grid geometry + design fences → unchanged.

## Acceptance criteria

- [ ] AC1: `icc(..., ci_method = "mpl", conf_level = c)` for c ∈ {0.90, 0.99}
      returns an ICC(A,1) interval on the balanced-complete two-way random
      absolute-agreement cell whose endpoints equal `mpl_interval` at the
      M90-calibrated κ_m for that (R, S, c) (test).
- [ ] AC2: ICC(A,k) and ICC(A,m) at the new levels equal the `npb_sb()`
      Spearman-Brown image of the ICC(A,1) endpoints at that level — inheritance
      identity + a mutation guard that diverges on a wrong divisor (M82
      anti-tautology lesson) (test).
- [ ] AC3: conf_level outside {0.90, 0.95, 0.99} aborts with a classed
      `intraclass_unsupported` error whose message names the supported set
      (test) — mirrors the off-grid abort.
- [ ] AC4: conf_level = 0.95 endpoints are byte-identical to the shipped
      behavior — no regression (test).
- [ ] AC5: `devtools::check()` Status OK; `cairn_validate` exit 0; the
      `check-references` job green (any new generalizing claim on a references
      page triaged, M74/M85 lesson); lintr + pkgdown clean.
- [ ] AC6: `@param conf_level` and the `"mpl"` `@param` note updated to state the
      supported set; NEWS entry.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T4
- AC3 → T3, T4
- AC4 → T4
- AC5 → T5
- AC6 → T5

## Tasks

- [ ] T1: Extend the internal κ_m table schema with a conf_level (α) column and
      regenerate `R/sysdata.rda` from the M90-committed fixtures ({0.90, 0.95,
      0.99}); update the `data-raw/` generator + its provenance `meta`.
- [ ] T2: Key `mpl_kappa_lookup` (`R/ci-mpl.R:204`) on (n_r, n_s, conf_level),
      keeping per-level S-interpolation; confirm `mpl_ci` (already receives
      conf_level) selects the right table slice.
- [ ] T3: Lift the `R/icc.R:1467` fence to admit conf_level ∈ {0.90, 0.95, 0.99};
      abort otherwise via a classed `intraclass_unsupported` error listing the
      set (mirror the `mpl_kappa_lookup` off-grid abort).
- [ ] T4: Tests — new-level endpoints vs `mpl_interval`; SB inheritance at new
      levels + mutation guard; off-level classed abort + message; 0.95
      regression equality.
- [ ] T5: Docs (`@param conf_level` + `"mpl"` `@param`; RR03 beyond-brief:
      non-equal-tailed note, near-vacuous small-geometry 0.99 width per BC6,
      soften the `R/ci-mpl.R` interpolation comment), NEWS, references-page
      consistency (triage any new generalizing claim); run the verify slot clean.

## Work log

- 2026-07-24: created by /milestone-plan (with M90); depends on M90's per-level GO; lineage D-015 → this.
- 2026-07-24: M90's RR03/D-017 gates this export (BC7 — 0.99 exportable only if BC1–BC6 pass; a NO-GO level stays a candidate). Folded the RR03 beyond-brief doc duties into Scope/T5. BCs are ingested verbatim in M90 (Driving RR there), not re-ingested here.

## Decisions

## Review
