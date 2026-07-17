<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M54: Multilevel SEM (lavaan) — engine implementation

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M53 is done -->
- **Principles touched:** IP1, GP5, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m54-lavaan-multilevel-engine · https://github.com/jmgirard/intraclass/pull/60   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: `icc(..., engine = "lavaan", cluster = ...)` on complete/balanced
      Design-1 data returns all eight Table-3 ICCs plus conflated, with
      montecarlo intervals at both levels; print output snapshot-tested.
- [x] AC2: oracle agreement (#1, ≥2 independent): (a) cross-engine parity vs
      glmmTMB REML on a fixed seeded dataset — consistency ICCs ≤ 1e-3,
      agreement ≤ .01 at the pilot Stage-1 geometry (index-class split per
      M49; sem-multilevel-pilot § Results); (b) seeded population recovery on
      ≥2 cells with pins split by governing axis and sized ≥3·√(2/df)/√n_rep
      (GP5; LESSONS 2026-07-16), the rater pin centred on the predicted
      inflation τ²/σ²_r, never zero; (c) reduction: σ²_c = σ²_cr = 0 data →
      subject-level ICCs within .02 of the shipped single-level lavaan engine.
- [x] AC3: the τ² law pinned as an invariant-type GP7 guard — signed
      SEM−REML rater-component parity within .005 of predicted τ² on a
      tight-k cell — with a source comment citing D-005 + the pilot ledger.
- [x] AC4: MC interval evidence — all draws finite and positive, both-level
      intervals bracket their point estimates, and endpoint parity vs the
      glmmTMB montecarlo interval on the same data (index-class-split
      tolerances).
- [x] AC5: classed aborts pinned for every Out combination (fixed, nested,
      incomplete/unbalanced, bootstrap, replicates × multilevel lavaan), and
      a between-level Heywood fixture → `intraclass_singular_fit` where the
      test pins that the boundary was actually reached (LESSONS 2026-07-13).
- [x] AC6: `test-engine-parity-matrix.R` multilevel cells flip lavaan from
      `na` to `agree`; roster-coverage test green.
- [x] AC7: `devtools::document()` + `devtools::test()` clean (profile verify
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
- [x] T2: implement `fit_lavaan_multilevel()` per the pilot mapping —
      syntax build, `.l2` intercept extraction, five components,
      Heywood/convergence guards, six-field contract.
- [x] T3: dispatch — narrow `R/icc.R:564`, add the multilevel lavaan branch
      gated to Design 1 + random + complete + balanced; conflated guard
      check; classed-abort tests for every Out combination.
- [x] T4: MC interval feasibility + endpoint-parity tests; the τ² invariant
      GP7 guard test with hand-computed τ² (LESSONS 2026-07-13: direct
      deterministic check, not a coverage sim).
- [x] T5: seeded recovery cells (reuse pilot geometries, e.g. N_c=40/k=5 and
      the tight-k N_c=30/k=25 cell), `skip_on_cran`, noise-floor-sized pins.
- [x] T6: flip the parity-matrix cells; verify installed package with
      `NOT_CRAN=true`; `lintr::lint_package()`.
- [x] T7: docs — engine-header τ² block, `@param engine` roxygen, NEWS,
      vignette sections; `devtools::document()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-16: created by /milestone-plan (promoted from the ROADMAP
  candidate; lineage ADR-027 → M53 GO → D-005; plan gate: before-release
  sequencing, conflated in, parity+feasibility CI bar, balanced-only).
- 2026-07-16: T1 done — oracle test file written (pilot-traced pins; MC/
  conflated pins to be calibration-sized in T2/T4), all paths fail on the
  current blanket abort as expected.
- 2026-07-16: T2–T5 done — engine + dispatch in; oracle file green incl. the τ² GP7 pin; snapshot reproduces the pilot Stage-1 numbers (Heywood re-seed + MC-pin sizing rationale in the test-file comments).
- 2026-07-16: T6+T7 done — two stale refusal pins updated, parity-matrix M5 cell flipped (calibrated), suite green loaded and installed (1712 pass, 0 fail), lint 0, docs updated; status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive; EXEMPT from the 150-line cap (M55) -->

Reviewed 2026-07-16/17 · PR https://github.com/jmgirard/intraclass/pull/60

### Acceptance-criteria evidence (fresh, by command)

- AC1: oracle file fresh run 47 pass / 0 fail (NOT_CRAN) — parity test asserts
  8 estimate rows at both levels; conflated test asserts the 4 conflated rows;
  print snapshot committed (mask_ci transform) and reproduces the committed
  pilot Stage-1 checkpoint numbers exactly.
- AC2: (a) cross-engine parity green — consistency ≤1e-3, agreement ≤.01 at the
  pilot Stage-1 geometry, components within pilot budgets; (b) recovery cells B
  (N_c=40, n_rep=60, cluster-axis components rel bias <.10, floor .088) and D
  (k=25, n_rep=40, rater rel bias centred on predicted τ²/σ²_r ±.137) green;
  (c) reduction to the shipped single-level engine <.02 green (re-seeded
  20260724 — at a true-zero cluster variance the shipped engine Heywood-aborts
  ~half of seeds by design, D-004; logged in the test comments).
- AC3: τ² GP7 invariant green — signed SEM−REML rater parity within .005 of
  predicted τ²=.00742 (20 parity reps, cell D); source comments cite D-005 +
  the pilot ledger in the engine header and the test.
- AC4: MC test green — draws finite, endpoints in [0,1], both-level bracketing;
  endpoint parity: consistency ≤.01 (observed .0033), agreement upper ≤.06 /
  lower ≤.15 — the lower-endpoint delta is the ESTABLISHED single-level engine
  signature (σ²_r quadratic-form vs log-normal draws; benchmark ~.12 on
  comparable single-level data), documented in the test; d_study() smoke green.
- AC5: six classed aborts pinned (fixed / nested / incomplete / unbalanced
  clusters / replicates / bootstrap → intraclass_unsupported) + Heywood fixture
  → intraclass_singular_fit with boundary-reached evidence (glmmTMB cluster
  <.01 on the same data).
- AC6: parity matrix fresh run 81 pass / 0 fail — M5 cell agrees at calibrated
  c(A=4e-2, C=5e-3) (observed .020/.0017 at N_c=15); roster test green.
- AC7: devtools::document() no diff; full suite 1712 pass, 0 fail loaded AND
  against the installed package (NOT_CRAN=true); lintr::lint_package() 0;
  air format --check clean.

### Consistency gate

- cairn_validate: exit 0 (after fixing two review-time mechanical fails it
  itself caught: over-long work-log entries → compressed to one line each;
  '1712/0/0' parsed as a non-ISO date → reworded).
- cairn_impact: skipped — no DESIGN.md principle changed.
- Toolchain (r-package slot): document() no-diff ✓; generated files clean ✓;
  README.Rmd rebuilt, no drift ✓; pkgdown::check_pkgdown() no problems ✓;
  NEWS entry present, no milestone numbers ✓; no new top-level files ✓;
  devtools::check(NOT_CRAN=false): 0 errors / 0 warnings / 0 notes ✓.

### Independent review (three lenses + scorer)

- [O] diff-bug: NO findings. Verified the mapping against the pilot verbatim,
  re-derived τ², traced every unsupported combination to its classed abort (no
  silent glmmTMB fallback path), checked contract conformance and pin sizing.
  Two near-findings dropped as the accepted single-level pattern (raw
  conditionMessage into cli_warn; Heywood guard without is.finite).
- [S] blame-history: NO findings. The removed blanket abort is superseded by
  D-005, not silently deleted; both rewritten tests preserve everything still
  legitimately pinned. FYI (not a finding): the print snapshot vs the M10-retro
  "don't snapshot multilevel prints" lesson — mitigated by the mask_ci
  transform (the fragile MC-CI digits are masked) and mandated by AC1 at the
  plan gate.
- [S] prior-PR: no prior-PR evidence (only codecov bot comments on merged
  PRs); zero findings — clean no-op.
- [S] scorer: not spawned — zero surviving findings to score. Sub-80 log: none.

### Triage

No actioned findings. No follow-ups spawned.
