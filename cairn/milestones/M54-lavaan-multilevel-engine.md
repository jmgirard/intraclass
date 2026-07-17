<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M54: Multilevel SEM (lavaan) — engine implementation

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M53 is done -->
- **Principles touched:** IP1, GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m54-lavaan-multilevel-engine   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Ship `engine = "lavaan"` with `cluster =` for the Design-1 (raters-crossed)
multilevel estimand — both levels, complete/balanced, random raters,
montecarlo CI — as the oracle-established two-level CFA parameterization from
M53 (D-005; pilot ledger `cairn/references/sem-multilevel-pilot.md`).

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**
- `fit_lavaan_multilevel()` in `R/engine-lavaan.R`: two-level CFA per the
  pilot mapping (within: subject factor + equal residuals; between: cluster
  factor + equal residuals + free intercepts, within intercepts 0; ML-only);
  five components `cluster/subject/rater/cluster_rater/residual`; σ²_r via
  the grand-mean-centred quadratic form on the `.l2` between intercepts
  (LESSONS 2026-07-16: grep `~1\.l2$`); standard six-field engine contract —
  `estimate`/`vcov` log-SD for the four variances + identity for intercepts,
  `to_components` feeding `theta2r_moment_draws()` (bias = 0, random raters)
  so the shared MC machinery works unmodified.
- Dispatch: narrow the guard at `R/icc.R:564-572` and add the lavaan branch
  to the multilevel dispatch chain — Design 1 + random raters + complete +
  balanced only; every other multilevel×lavaan combination keeps a classed
  `intraclass_unsupported` abort.
- `level = "conflated"` works off the same fit via the generic composition
  (verify the guard at `R/icc.R:751-773`).
- Boundary posture per D-004: between-level Heywood / non-convergence →
  classed `intraclass_singular_fit` / `intraclass_engine_error` toward
  glmmTMB (the single-level lavaan posture, `R/engine-lavaan.R:264-274`).
- Docs: the τ² inflation law (E = σ²_r + τ², τ² = (σ²_cr + σ²_res/n_s)/N_c)
  in the engine module header exactly as the single-level header documents
  its "−σ²_res/n" analog, + a qualitative `@param engine` roxygen note;
  ML-vs-REML small-sample delta documented (M7/M49 posture); NEWS entry;
  short sections in `vignettes/engines.Rmd` + `multilevel-designs.Rmd`.

**Out:**
- Fixed-raters multilevel × lavaan → candidate "lavaan multilevel siblings"
  (this milestone unblocks it).
- Incomplete / unbalanced-cluster × lavaan → same siblings candidate row.
- Nested Designs 2/3 × lavaan → abort retained; no candidate (promote if a
  need appears).
- Bootstrap CI for multilevel lavaan → `simulate_refit = NULL`, loud abort
  (the M21 incomplete-data posture); revisit with the siblings.
- lavaan + within-cell replicates → existing candidate row (unchanged).
- One-way × lavaan → stays blocked (ADR-014).
- Seeded MC coverage sweep for lavaan-fed intervals → declined at the plan
  gate 2026-07-16 (parity + feasibility bar chosen; shared MC machinery is
  already coverage-validated on the glmmTMB multilevel path).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `icc(..., engine = "lavaan", cluster = ...)` on complete/balanced
      Design-1 data returns all eight Table-3 ICCs plus conflated, with
      montecarlo intervals at both levels; print output snapshot-tested.
- [ ] AC2: oracle agreement (#1, ≥2 independent): (a) cross-engine parity vs
      glmmTMB REML on a fixed seeded dataset — consistency ICCs ≤ 1e-3,
      agreement ≤ .01 at the pilot Stage-1 geometry (index-class split per
      M49; sem-multilevel-pilot § Results); (b) seeded population recovery on
      ≥2 cells with pins split by governing axis and sized ≥3·√(2/df)/√n_rep
      (GP5; LESSONS 2026-07-16), the rater pin centred on the predicted
      inflation τ²/σ²_r, never zero; (c) reduction: σ²_c = σ²_cr = 0 data →
      subject-level ICCs within .02 of the shipped single-level lavaan engine.
- [ ] AC3: the τ² law pinned as an invariant-type GP7 guard — signed
      SEM−REML rater-component parity within .005 of predicted τ² on a
      tight-k cell — with a source comment citing D-005 + the pilot ledger.
- [ ] AC4: MC interval evidence — all draws finite and positive, both-level
      intervals bracket their point estimates, and endpoint parity vs the
      glmmTMB montecarlo interval on the same data (index-class-split
      tolerances).
- [ ] AC5: classed aborts pinned for every Out combination (fixed, nested,
      incomplete/unbalanced, bootstrap, replicates × multilevel lavaan), and
      a between-level Heywood fixture → `intraclass_singular_fit` where the
      test pins that the boundary was actually reached (LESSONS 2026-07-13).
- [ ] AC6: `test-engine-parity-matrix.R` multilevel cells flip lavaan from
      `na` to `agree`; roster-coverage test green.
- [ ] AC7: `devtools::document()` + `devtools::test()` clean (profile verify
      slot), installed-package suite clean with `NOT_CRAN=true`,
      `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T3
- AC2 → T1, T2, T5
- AC3 → T4
- AC4 → T4
- AC5 → T3
- AC6 → T6
- AC7 → T6, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: tests first — cross-engine parity, reduction, and recovery-cell
      skeletons (new `test-icc-lavaan-multilevel.R`), failing against the
      current abort.
- [ ] T2: implement `fit_lavaan_multilevel()` per the pilot mapping —
      syntax build, `.l2` intercept extraction, five components,
      Heywood/convergence guards, six-field contract.
- [ ] T3: dispatch — narrow `R/icc.R:564`, add the multilevel lavaan branch
      gated to Design 1 + random + complete + balanced; conflated guard
      check; classed-abort tests for every Out combination.
- [ ] T4: MC interval feasibility + endpoint-parity tests; the τ² invariant
      GP7 guard test with hand-computed τ² (LESSONS 2026-07-13: direct
      deterministic check, not a coverage sim).
- [ ] T5: seeded recovery cells (reuse pilot geometries, e.g. N_c=40/k=5 and
      the tight-k N_c=30/k=25 cell), `skip_on_cran`, noise-floor-sized pins.
- [ ] T6: flip the parity-matrix cells; verify installed package with
      `NOT_CRAN=true`; `lintr::lint_package()`.
- [ ] T7: docs — engine-header τ² block, `@param engine` roxygen, NEWS,
      vignette sections; `devtools::document()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-16: created by /milestone-plan (promoted from the ROADMAP
  candidate; lineage ADR-027 → M53 GO → D-005; plan gate: before-release
  sequencing, conflated in, parity+feasibility CI bar, balanced-only).
- 2026-07-16: T1 done — oracle test file written (pilot-traced pins; MC/
  conflated pins to be calibration-sized in T2/T4), all paths fail on the
  current blanket abort as expected.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive; EXEMPT from the 150-line cap (M55) -->
