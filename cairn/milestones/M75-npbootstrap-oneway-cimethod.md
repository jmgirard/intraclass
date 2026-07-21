# M75: Exported one-way transformed bootstrap-t `ci_method = "npbootstrap"`

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** RR02
- **Principles touched:** IP1, GP5
- **Branch/PR:** m75-npbootstrap-oneway / [#81](https://github.com/jmgirard/intraclass/pull/81)

## Goal

Ship the `log F` variance-stabilized transformed bootstrap-t (M62 GO, D-006) as
an exported, oracle-validated one-way `ci_method`, balanced-only, with a
pre-specified corner-cell fallback.

## Scope

**In:** a new `ci_method = "npbootstrap"` for the balanced one-way random ICC —
`ICC(1)` and, via the monotone Spearman-Brown endpoint map, `ICC(k)`
(`unit = "average"`), both reporting the engine REML point (D-010/RR02). The
reducer (whole-subject resample → one-way ANOVA → eq. 6 `log F` transform + eq. 7
IJ SE + studentized interval + monotone back-transform) ports from the
RR01-verified prototype (`data-raw/m62-npbootstrap-prototype.R`); dispatch wiring
+ one-way/balanced guards; classed guards on degenerate resamples / missing rows;
a fresh n_rep ≥ 2000 coverage validation over C1–C4 + U10/U30/U50 (lower/upper
tail-error, distinct per-cell seeds, per-rep seeding, truncated-vs-untruncated
width); an ORACLES.md entry; docs/NEWS.

**Out:**
- percentile & BCa variants — NO-GO (D-006), recorded rejected, not shipped.
- unbalanced `n_i` (eq. 7) / `n₀` (transform) support → candidate row (design
  work; the SB pole/support alignment is balanced-only and needs re-derivation
  under `n₀`, RR02 beyond-brief 2).
- the SEARLE-F / Burch-REML boundary-robust classical default → separate candidate
  (it does not fix the MC default's one-way boundary defect, D-006 framing).
- two-way / cluster / multilevel designs — npbootstrap is one-way-only here.

## Acceptance criteria

- [x] AC1: `ci_method = "npbootstrap"` returns a boundary-aware two-sided `ICC(1)`
      interval on the balanced one-way random design; an explicit request on any
      non-one-way or unbalanced design aborts classed (#5/#8), not a silent fallback.
- [x] AC2 (oracle #1, parity): the exported reducer reproduces the RR01-verified
      prototype to ≥ 4 dp on the committed M62 datasets (eq. 6 transform
      `f(ρ̂) = log F`, eq. 7 IJ SE, studentized endpoints, back-transform).
- [x] AC3 (oracle #2, external): on ukoumunne2003 Table I (k ∈ {10,30,50}, n = 10,
      ρ = .05) coverage matches the exact values 0.938 / 0.944 / 0.9395 within ±0.03
      (pre-registered), from the fresh n_rep ≥ 2000 sweep.
- [x] AC4: the sweep (C1–C4) records two-sided coverage AND lower/upper tail-error
      per cell; the tail split at the near-zero cells is roughly balanced (Table I
      ~3.25/2.95 at U10, not a BCa skew); truncated-vs-untruncated widths reported
      on a common scale.
- [x] AC5: degenerate resamples (SSA = 0 → `log F = −Inf`, SE = 0) and missing-row
      extraction raise classed errors (#5/#8), not silent NA/crash; the harness uses
      distinct per-cell seed bases + a distinct per-rep `seed` into `icc()` (RR01
      findings 1–2).
- [x] AC6 (GP5, pre-specified before the sweep): if the C4 corner lands below the
      0.93 floor, `?icc` @details documents the small-k × near-zero-ρ under-coverage
      and the export ships anyway (never withheld); if ≥ 0.93, the work log records
      the clear. Branch fixed here, not after the data.
- [x] AC7: ORACLES.md carries the npbootstrap entry; `@param ci_method`/@details +
      NEWS updated; the `verify` slot is clean and `lintr::lint_package()` passes
      (incl. `data-raw/`).

### Binding criteria (RR02, ingested verbatim)

- [x] AC8 (BC1): The exported string is `"npbootstrap"`, and the `@param ci_method`
  roxygen entry names the exact variant — subject (cluster) resampling with
  the `log F` variance-stabilized **transformed bootstrap-t** and
  infinitesimal-jackknife SE, citing Ukoumunne et al. (2003) — and states
  explicitly that it is **not** a percentile bootstrap (percentile and BCa
  were assessed and rejected, D-006).
- [x] AC9 (BC2): A committed test verifies, on the M62 parity datasets, that the
  ICC(k)/`unit = "average"` interval endpoints computed via the shipped
  Spearman-Brown route equal `1 − exp(−(log F endpoint))` computed directly
  from the studentized log-F endpoints, with max absolute deviation
  ≤ 1e−10.
- [x] AC10 (BC3): The n_rep ≥ 2000 sweep records ICC(k) coverage per cell against the
  true `kρ/(1 + (k−1)ρ)` and asserts the ICC(k) coverage indicator equals the
  ICC(1) coverage indicator **rep-by-rep** (tolerance: exact equality, zero
  discrepant reps); any discrepancy halts the sweep as an implementation bug.
- [x] AC11 (BC4): `?icc` @details states that the npbootstrap ICC(k) interval is the
  exact monotone Spearman-Brown image of the ICC(1) interval (coverage
  identical by construction), that its endpoints are untruncated with support
  `(−∞, 1)`, and that the lower endpoint can be markedly negative near the
  boundary; the ORACLES.md entry records the ICC(k) validation basis as
  "exact monotone-map inheritance from the ICC(1) Table I anchor + the BC2
  identity cross-check", not as an independent external anchor.
- [x] AC12 (BC5): The reported point estimate under `ci_method = "npbootstrap"` is the
  engine (glmmTMB REML) point via the shared `icc_point()` path for both
  ICC(1) and ICC(k), identical to every other frequentist `ci_method` on the
  same fit; the ANOVA-MoM ρ̂ is never surfaced as a point estimate. @details
  documents that at the σ²_a = 0 boundary the point reads 0 while the
  untruncated interval may extend below 0, and that this signals boundary
  proximity.
- [x] AC13 (BC6): The sweep records, per cell, the frequency of the reported (REML)
  point lying outside the npbootstrap ICC(1) interval; at every cell with
  true ρ > 0 this rate must not exceed that cell's recorded upper-tail-error
  rate (an exact logical bound; tolerance 0), and the observed rates are
  reported in the committed fixture.

**Deviations from RR02:** none.

## Coverage

- AC1 → T1, T3 · AC2 → T1, T2 · AC3 → T1, T4 · AC4 → T4 · AC5 → T1, T2
- AC6 → T5 · AC7 → T6
- AC8 (BC1) → T6 · AC9 (BC2) → T1, T2 · AC10 (BC3) → T4 · AC11 (BC4) → T6
- AC12 (BC5) → T3, T6 · AC13 (BC6) → T4

## Tasks

- [x] T1: Failing tests first — prototype-parity on the M62 datasets (AC2), the
      Table I coverage assertions (AC3), dispatch + classed-guard tests (AC1, AC5),
      the BC2 identity cross-check, and (consider, RR02 rec 5) the off-boundary
      REML-point = internal MoM ρ̂ parity test.
- [x] T2: Reducer in a new `R/ci-npbootstrap.R` — `oneway_anova()` (balanced),
      `log F` transform + inverse, eq. 7 IJ SE, studentized interval, monotone
      back-transform; also emit the `ICC(k)` endpoints via the Spearman-Brown map
      on the two final ρ endpoints (BC2); classed guards on SSA = 0 / missing rows.
      Port from `data-raw/m62-npbootstrap-prototype.R`. (AC2, AC5)
- [x] T3: Add `"npbootstrap"` to the `ci_method` `validate_choice` set + dispatch
      at `R/icc.R:~1800`; route raw one-way data to the reducer for both estimands,
      abort classed on non-one-way/unbalanced input (not on `unit = "average"`),
      and report the engine REML point via `icc_point()` for both (BC5). (AC1)
- [x] T4: Validation harness in `data-raw/` (C1–C4 + U10/U30/U50 at n_rep ≥ 2000;
      two-sided + lower/upper tail-error; distinct per-cell seeds; per-rep `seed`;
      truncated/untruncated width on a common scale); add the `ICC(k)` rep-by-rep
      inherited-coverage assertion (BC3) and the point-outside-interval rate (BC6);
      run and commit the fixture. (AC3, AC4)
- [x] T5: Apply the pre-specified corner branch from the T4 result — add the
      @details corner limitation if C4 < 0.93, else record the clear in the work
      log. (AC6)
- [x] T6: Write the ORACLES.md entry (basis = **inheritance from the ICC(1) Table I
      anchor + the BC2 identity cross-check**, not an independent anchor — BC4);
      update roxygen `@param ci_method` (name the variant; state it is **not** a
      percentile bootstrap — BC1) and @details (ICC(k) SB image + untruncated
      support + boundary-point picture — BC4/BC5) and NEWS; run the `verify` slot
      + `lintr::lint_package()` clean. (AC7)

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
- 2026-07-21: ingested RR02 (concur on all three) → D-010; six binding criteria
  BC1–BC6 ingested verbatim into AC (Driving RR: RR02); ICC(k) added to scope;
  RB02/RR02 archived; status → in-progress. Tasks T1–T6 + Coverage amended for
  the ICC(k) map and the engine-REML-point ruling.
- 2026-07-21: T2 reducer (`R/ci-npbootstrap.R`) + T3 dispatch/guards done; parity
  fixture + generator committed; T1 unit tests (parity/guards/ICC(k) identity)
  green (28/28); T6 docs (@param/@details, O-NPBoot in ORACLES.md, NEWS) drafted.
- 2026-07-21: T4 sweep done (n_rep=2000, B=999, all 7 cells). AC3 coverage
  U10/U30/U50 = .9375/.9355/.9425 (Table I .938/.944/.9395, all within ±.03); AC4
  tail split balanced (U10 .0335/.0290) + truncated ≤ untruncated; BC3 zero
  disagreements (covk = cov1 exactly); BC6 point-outside ≤ upper-tail every cell.
  Coverage test green (68/68).
- 2026-07-21: T5 (AC6/GP5): the C4 corner CLEARS the 0.93 floor at
  coverage_icc1 = 0.9410 (every cell clears; min 0.934) — the "else" branch, so no
  @details corner limitation is added.
- 2026-07-21: T6 verify — full non-brms suite 1605 pass / 0 fail; `document()`
  no-diff; `lintr::lint_package()` 0 lints. All tasks done → status review.

## Decisions

- 2026-07-21 (RR02 ingest): all three questions resolved → **D-010** (confirms
  D-006): string kept; `ICC(k)` via the monotone Spearman-Brown map; engine REML
  point for both estimands. Basis in D-010 + `reviews/archive/RR02-…`.

## Review

**2026-07-21 — fresh evidence (PR #81).** Suites re-run from `load_all`:
`test-ci-npbootstrap.R` 28/28, `test-ci-npbootstrap-coverage.R` 68/68, both 0 fail.

- AC1 — `ci_method = "npbootstrap"` returns a finite ordered `ICC(1)` interval
  (`fit$ci$method`/`samples` set); explicit requests on a two-way design and on an
  unbalanced one-way design both abort `intraclass_unsupported`. Tests green.
- AC2 — parity: the reducer reproduces the RR01-verified prototype's transformed
  bootstrap-t `ICC(1)` endpoints on 3 committed M62 datasets (tol 1e-4; agreement is
  in fact to floating-point). Green.
- AC3 — Table I coverage (n_rep=2000): U10 .9375 (proj .938, d .0005), U30 .9355
  (proj .944, d .0085), U50 .9425 (proj .9395, d .0030) — all within ±.03.
- AC4 — per-cell two-sided coverage + lower/upper tail recorded; U10 split
  .0335/.0290 (|d| .0045, balanced, not a BCa skew); truncated ≤ untruncated widths
  reported every cell. Green.
- AC5 — degenerate (SSA=0) design aborts `intraclass_singular_fit`; missing-row
  guard classed; harness uses distinct per-cell seed bases + a distinct per-rep
  resample seed. Green.
- AC6 — GP5 pre-specified branch: C4 corner coverage .9410 ≥ 0.93 (every cell
  clears; min .9340) → "else" branch, no @details corner limitation. Recorded.
- AC7 — `O-NPBoot` in ORACLES.md; `@param`/@details + NEWS updated; man/icc.Rd
  regenerated (`document()` no-diff); verify slot 1605 pass/0 fail; `lint_package()`
  0 lints.
- AC8 (BC1) — `@param ci_method` names the variant (transformed bootstrap-*t*, IJ
  SE, Ukoumunne 2003) and states it is **not** a percentile bootstrap. Present in
  R/icc.R + man/icc.Rd.
- AC9 (BC2) — identity cross-check test: ICC(k) endpoints = `1 − exp(−logF)` to
  ≤ 1e-10 on the parity datasets (doubles as the `k_eff = n` guard). Green.
- AC10 (BC3) — ICC(k) coverage = ICC(1) coverage rep-by-rep: **0** disagreements
  across all 7 cells × 2000 reps. Green.
- AC11 (BC4) — @details states the ICC(k) SB image + untruncated support + markedly
  negative near-boundary lower bound; ORACLES records the basis as monotone-map
  **inheritance** + the BC2 cross-check, not an independent anchor. Present.
- AC12 (BC5) — dispatch reports the engine REML point via `icc_point()` for both
  estimands (the reducer returns only intervals); ANOVA-MoM ρ̂ never surfaced;
  @details documents the boundary point/interval picture. Verified in R/icc.R.
- AC13 (BC6) — reported-point-outside rate ≤ recorded upper-tail error at every
  cell (exact bound, tolerance 0): holds all cells; observed rates committed in the
  fixture.

**Driving RR02 — measured vs projected:** Table I U10/U30/U50 measured
.9375/.9355/.9425 against projected .938/.944/.9395 (all ≤ .03). BC2 identity
measured ≤ 1e-10 against projected (RR02 verified 4.6e-14). BC3 measured 0
discrepant reps against projected zero. BC6 measured ≤ upper-tail every cell
against the projected exact bound (tolerance 0). No shortfall.

**Consistency gate (by command):** `cairn_validate` exit 0; `devtools::check()`
0 errors / 0 warnings / 0 notes; `document()` no-diff; `pkgdown::check_pkgdown()`
clean; NEWS entry present.

**Independent fresh-context review (3 lenses) — 0 actioned findings.**
- [O] diff-bug (Opus): no defects; verified the studentized bootstrap-t, the
  non-circular cross-implementation parity oracle, the BC2 divisor=n identity, the
  loud classed guards, and the REML-point dispatch. Noted (not a finding): small k
  (≤ 4) can trip the degenerate-resample abort — exactly AC5's loud-classed design,
  consistent with the method's k ≥ 10 target.
- [S] blame-history (Sonnet): no findings; additive extension, brms coupling /
  lavaan refusal / choice set / `samples` slot all respected.
- [S] prior-review (Sonnet): no findings; faithfully realizes RR01/RR02 (D-006/D-010);
  GitHub PR-comment probe empty.
Scorer: no surviving findings to score (no-op). No below-threshold findings logged.
