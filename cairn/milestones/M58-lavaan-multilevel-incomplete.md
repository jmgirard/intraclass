<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M58: Multilevel SEM (lavaan) — incomplete / unbalanced random design

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP5, GP6, GP7   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m58-lavaan-multilevel-incomplete   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Extend the crossed (Design 1) random-rater multilevel lavaan engine to
incomplete data (two-level FIML) and unequal cluster sizes, gated by a
feasibility spike that first establishes the route holds on these shapes.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a task-1 feasibility spike (does two-level FIML recover the Design-1
components on incomplete data, and does the documented τ² rater-inflation law
generalize to unequal `n_s`?) with a recorded GO/NO-GO; on GO, extending
[`fit_lavaan_multilevel()`](../../R/engine-lavaan.R) to (a) incomplete
subject×rater cells via `missing = "fiml"` (analog of the single-level FIML
path) and (b) unequal cluster sizes (native to lavaan two-level); the averaged
cluster ICC(c,k) inverse-Simpson `k_c^eff` divisor (M46 / ADR-057) is
engine-agnostic and applies unchanged; narrowing the balance guard
([icc.R:1289](../../R/icc.R)). Crossed Design 1, **random** raters only.

**Out:** the incomplete/unbalanced fixed **cluster** level — double-blocked for
**all** engines (ten Hove's open small-`k` estimator + the M9 §9 ICC(c,k)
divisor); stays a parking-lot candidate. Incomplete/unbalanced fixed **subject**
level lavaan → a candidate row (compounds FIML with the fixed correction; low
priority). The parametric bootstrap stays refused on incomplete data (resamples
cannot reproduce the missingness pattern — single-level precedent, ADR-031);
`ci_method = "bootstrap"` routes to the loud guard, MC only. A NO-GO spike halts
the fit work at a gate (records the finding; ships nothing).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: the feasibility spike is run (seeded; extends
      `data-raw/pilot-sem-multilevel.R`) and its GO/NO-GO recorded with evidence
      in the `cairn/references/sem-multilevel-pilot.md` synthesis note —
      two-level FIML component parity vs `fit_glmmtmb_multilevel()` on incomplete
      data (index-class split) and the τ²-under-unequal-`n_s` law matching a
      predicted value to a documented tolerance. AC2–AC4 are conditional on GO.
      (RB tripwire: ip-touching)
- [ ] AC2: on incomplete (connected) data, lavaan subject- and cluster-level
      random ICCs agree with `fit_glmmtmb_multilevel()` (M15/M24) within the
      index-class-split tolerance; the averaged cluster ICC(c,k) uses the
      inverse-Simpson `k_c^eff` divisor (M46 / ADR-057). Oracle: glmmTMB
      incomplete multilevel; ten Hove et al. (2022) Eqs. 7/12–13.
- [ ] AC3: on unequal cluster sizes (complete crossing), lavaan components agree
      with glmmTMB across a sweep of the cluster-size-imbalance axis (GP6); the
      τ²-under-imbalance law is documented in the engine header and pinned as an
      invariant (rater parity centred on the generalized τ², never zero — GP5/GP7).
- [ ] AC4: the narrowed balance guard admits incomplete/unbalanced **random**
      crossed lavaan while still aborting loudly (classed) for the fixed cluster
      level, nested designs, replicates, and `ci_method = "bootstrap"` on
      incomplete data — the connectedness guard is shared with the mixed engines.
- [ ] AC5: the `verify` slot is clean (`cairn/PROFILE.md`) — `devtools::test()`
      green (installed suite, `NOT_CRAN=true CI=true`), `air format --check` and
      `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2, T3, T4
- AC3 → T2, T4
- AC4 → T3, T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Feasibility spike — extend `data-raw/pilot-sem-multilevel.R` (seeded,
      checkpoint before pins) to fit two-level FIML on incomplete cells and
      unequal-`n_s` data, compare to glmmTMB, and derive/verify the τ²
      generalization under imbalance; append a GO/NO-GO section to
      `cairn/references/sem-multilevel-pilot.md`. A NO-GO stops for a gate before
      any fit-path change. (RB tripwire: ip-touching)
- [x] T2: (on GO) Extend `fit_lavaan_multilevel()` — build the wide frame with NA
      cells (`tapply` already leaves them), pass `missing = "fiml"` when
      incomplete, confirm unequal cluster sizes fit natively, and generalize the
      τ² documentation/component reads to per-cluster `n_s`.
- [x] T3: Narrow the `icc.R:1289` balance guard to admit incomplete/unbalanced
      random crossed lavaan; keep the fixed-cluster, nested, replicate, and
      incomplete-bootstrap refusals; verify the shared connectedness guard covers
      the lavaan path.
- [ ] T4: Tests in `tests/testthat/test-icc-incomplete-multilevel.R` (or a new
      `test-icc-lavaan-multilevel-incomplete.R`) — AC2 incomplete parity + the
      `k_c^eff` divisor, AC3 unequal-`n_s` parity sweep + τ²-law guard, AC4 the
      abort/bootstrap-refusal narrowing (`skip_on_cran`,
      `skip_if_not_installed("lavaan")`).
- [ ] T5: Run the `verify` slot; update `@param` prose, the `icc()` engine roster,
      and the `fit_lavaan_multilevel()` header (lavaan crossed random multilevel
      now covers incomplete + unequal cluster sizes; bootstrap still MC-only on
      incomplete data).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-17: created by /milestone-plan (promotes the lavaan-multilevel-siblings
  candidate, part C; plan gate: 3 separate milestones, feasibility spike as T1).
- 2026-07-17: started /milestone-implement (status → in-progress, branch
  m58-lavaan-multilevel-incomplete); spike gate resolved "run the spike now"
  (ip-touching tripwire held in reserve for a NO-GO/surprise).
- 2026-07-17: T1 done. Spike Stages 3–4 added to `data-raw/pilot-sem-multilevel.R`
  (full run PILOT PASS). GO: two-level FIML recovers components on incomplete data
  (index-class split intact); the τ² rater inflation generalizes to the HARMONIC
  MEAN of per-cluster subject counts, τ² = (σ²_cr + σ²_res/H)/C, strictly beating
  the size-weighted grand law under imbalance. Evidence in the synthesis note.
- 2026-07-17: T2+T3 done. `fit_lavaan_multilevel()` passes `missing = "fiml"` on
  incomplete data, fits unequal cluster sizes natively; τ² harmonic-mean law +
  MD-1 documented in the engine header; `simulate_refit = NULL` on
  incomplete/unbalanced (MC-only). Narrowed the icc.R balance guard to fixed-only
  (random crossed incomplete/unbalanced now flows through; connectedness + the
  k_c^eff divisor are the shared engine-agnostic guards). Removed the two obsolete
  M54 abort assertions (incomplete/unbalanced random) from
  test-icc-lavaan-multilevel.R. Smoke-verified vs glmmTMB: k_c_eff 4.9194 matches,
  ICC(c,k)/ICC(s,·) parity holds, fixed + bootstrap-on-incomplete/unbalanced abort.

## Decisions
<!-- owner: implement / review · append-only -->

- MD-1 (2026-07-17): MC-only for both incomplete and unbalanced random multilevel
  lavaan. AC4 requires refusing `ci_method = "bootstrap"` on incomplete data
  (resamples cannot reproduce a missingness pattern — single-level precedent
  ADR-031). The same MC-only posture extends to unbalanced-**complete** data:
  although the M56 bootstrap factory (`lavaan_ml_simulate_refit`) natively accepts
  an unequal `cluster_sizes` vector, its coverage was validated only on balanced
  data (M56) and no unbalanced coverage oracle is in this milestone's scope —
  oracle-first (#1) says don't ship an interval whose coverage isn't established.
  So `simulate_refit = NULL` whenever the data is incomplete **or** has unequal
  cluster sizes; those cells ship the boundary-aware MC interval only. Bootstrap
  parity for the new random cells joins the parked lavaan-multilevel-bootstrap
  candidate. Balanced/complete random keeps the M56 bootstrap unchanged.

## Review
<!-- owner: review · exclusive -->
