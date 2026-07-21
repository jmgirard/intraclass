# M75: Exported one-way transformed bootstrap-t `ci_method = "npbootstrap"`

- **Status:** blocked
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5
- **Branch/PR:** m75-npbootstrap-oneway

## Goal

Ship the `log F` variance-stabilized transformed bootstrap-t (M62 GO, D-006) as
an exported, oracle-validated one-way `ci_method`, balanced-only, with a
pre-specified corner-cell fallback.

## Scope

**In:** a new `ci_method = "npbootstrap"` for the balanced one-way random ICC —
the reducer (whole-subject resample → one-way ANOVA → eq. 6 `log F` transform +
eq. 7 infinitesimal-jackknife SE + studentized interval + monotone
back-transform), ported from the RR01-verified prototype
(`data-raw/m62-npbootstrap-prototype.R`); dispatch wiring + one-way/balanced
guards; classed guards on degenerate resamples and missing-row extraction; a
fresh n_rep ≥ 2000 coverage validation over C1–C4 + U10/U30/U50 with lower/upper
tail-error tracking, distinct per-cell seed bases, per-replicate seeding into
`icc()`, and truncated-vs-untruncated width on a common scale; an ORACLES.md
registry entry; docs/NEWS.

**Out:**
- percentile & BCa variants — NO-GO (D-006), recorded rejected, not shipped.
- unbalanced `n_i` (eq. 7) / `n₀` (transform) support → candidate row (design
  work), deferred at this plan gate.
- the SEARLE-F / Burch-REML boundary-robust classical default → separate tracked
  candidate; it does not fix the MC default's one-way boundary defect and this
  milestone does not attempt that (D-006 framing).
- two-way / cluster / multilevel designs — npbootstrap is one-way-only here.

## Acceptance criteria

- [ ] AC1: `ci_method = "npbootstrap"` is a valid choice that returns a
      boundary-aware two-sided `ICC(1)` interval on the balanced one-way random
      design; an explicit `npbootstrap` request on any non-one-way or unbalanced
      design aborts with a classed error (#5/#8), not a silent fallback.
- [ ] AC2 (oracle #1, parity): the exported reducer reproduces the RR01-verified
      prototype to ≥ 4 dp on the committed M62 datasets — identical eq. 6
      transform (`f(ρ̂) = log F`), eq. 7 IJ SE, studentized endpoints, and
      back-transform.
- [ ] AC3 (oracle #2, external): on the ukoumunne2003 Table I cells
      (k ∈ {10,30,50}, n = 10, ρ = .05) the method's coverage matches the exact
      transformed-bootstrap-t values (0.938 / 0.944 / 0.9395) within ±0.03
      (pre-registered), from the fresh n_rep ≥ 2000 sweep.
- [ ] AC4: the n_rep ≥ 2000 sweep (C1–C4) records two-sided coverage AND
      lower/upper tail-error per cell; the transformed bootstrap-t's tail split at
      the near-zero cells is roughly balanced (tracking Table I's ~even 3.25/2.95
      at U10, not a BCa-style skew), and truncated-vs-untruncated endpoint widths
      are reported on a common scale.
- [ ] AC5: degenerate resamples (SSA = 0 → `log F = −Inf`, SE = 0) and missing-row
      extraction raise classed errors (#5/#8), not silent NA or a crash; the
      harness uses distinct per-cell seed bases and passes a distinct per-replicate
      `seed` into `icc()` (both M62 harness defects, RR01 findings 1–2).
- [ ] AC6 (GP5, pre-specified before the sweep): if the n_rep ≥ 2000 C4 corner
      lands below the 0.93 floor, `?icc` @details documents the small-k ×
      near-zero-ρ corner under-coverage and the export ships anyway (never
      withheld); if ≥ 0.93, the work log records the corner clears the floor. The
      branch is fixed here, not after the data.
- [ ] AC7: ORACLES.md carries an npbootstrap interval-oracle entry (Table I anchor
      + prototype-parity fixture); `@param ci_method`/@details, NEWS updated; the
      active profile's `verify` slot is clean and `lintr::lint_package()` passes
      (incl. `data-raw/`).

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2
- AC3 → T1, T4
- AC4 → T4
- AC5 → T1, T2
- AC6 → T5
- AC7 → T6

## Tasks

- [ ] T1: Write the failing tests first — prototype-parity on committed M62
      datasets (AC2), the Table I coverage-oracle assertions (AC3), and the
      dispatch + classed-guard tests (AC1, AC5).
- [ ] T2: Implement the reducer in a new `R/ci-npbootstrap.R` — `oneway_anova()`
      (balanced), `f`/inverse `log F` transform, eq. 7 IJ SE, studentized interval
      with resample SE + quantile reversal, monotone back-transform; classed
      guards on SSA = 0 and missing rows. Port from
      `data-raw/m62-npbootstrap-prototype.R`. (AC2, AC5)
- [ ] T3: Add `"npbootstrap"` to the `ci_method` `validate_choice` set and the
      dispatch at `R/icc.R:~1800`; route the raw one-way data to the reducer and
      abort (classed) on non-one-way or unbalanced input. (AC1)
      (RB tripwire: irreversible-api — D-006 fixed the exported string
      `"npbootstrap"`; confirm at implement before it ships.)
- [ ] T4: Build the validation harness in `data-raw/` (full C1–C4 + U10/U30/U50 at
      n_rep ≥ 2000; two-sided + lower/upper tail-error; distinct per-cell seeds;
      per-rep `seed` into `icc()`; truncated/untruncated width on a common scale);
      run it and commit the fixture. (AC3, AC4)
- [ ] T5: Apply the pre-specified corner branch from the T4 result — add the
      @details corner limitation if C4 < 0.93, else record the clear in the work
      log. (AC6)
- [ ] T6: Write the ORACLES.md entry, update roxygen `@param ci_method`/@details
      and NEWS, then run the `verify` slot + `lintr::lint_package()` clean. (AC7)

## Work log

- 2026-07-21: created by /milestone-plan (promotes the M62-GO bootstrap-t
  candidate; gate: below-floor fallback = ship + document corner limitation, never
  withhold (GP5); validation = full n_rep ≥ 2000 sweep of the exported method over
  all seven cells; unbalanced support → candidate).
- 2026-07-21: status → in-progress; branch m75-npbootstrap-oneway cut from origin/main.
- 2026-07-21: pre-implementation question gate → two tripwire hits routed to Fable.
  (1) exported API string `npbootstrap` (irreversible-api, T3): user chose Escalate.
  (2) ICC(k)/unit="average" support: user chose extend via monotone Spearman-Brown of
  the ρ endpoints — ships an ICC(k) interval with no independent oracle (no-oracle
  tripwire). (3) point-estimate source: user asked for a recommendation; session
  recommends the engine REML point (≥0, package-consistent), folded into the RB.
  Routing to /milestone-brief for a single RB covering all three; milestone paused.
- 2026-07-21: blocked on RB02 (npbootstrap exported-API scope — public string,
  ICC(k) support, reported point). Awaiting RR02.

## Decisions

## Review
