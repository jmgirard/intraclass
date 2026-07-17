<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M53: Multilevel SEM (lavaan) — estimand/oracle pass

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m53-multilevel-sem-pass · https://github.com/jmgirard/intraclass/pull/59   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Establish whether a faithful two-level lavaan SEM formulation of the ten Hove
et al. (2022) Design-1 five-component decomposition exists (sourced or as an
IP1-fenced parameterization) and numerically recovers the components, ending
in a recorded go/no-go for the engine implementation.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** primary-source hunt for multilevel SEM-GT (Vispoel/Jorgensen/ten Hove
lineage; DOI/publisher/OSF) with ingestion on a hit; the two-level mapping
note (within: subject factor σ²_{s:c} + equal residuals σ²_{(s:c)r}; between:
cluster factor σ²_c + equal residuals σ²_{cr} + effects-coded intercepts →
σ²_r), including lavaan two-level estimation constraints (ML-only — no
wishart likelihood, so N-divisor small-sample deltas vs REML are expected and
documented); a committed seeded pilot script (balanced Design-1: component
recovery vs glmmTMB, reduction to the single-level engine at zero cluster
variances, known-population recovery incl. a high-cluster cell, MC-interval
feasibility probe on the two-level vcov); a committed synthesis note with the
go/no-go. Research only — docs + `data-raw/` scripts, no package code.

**Out:** the engine implementation (`engine = "lavaan"` + `cluster`) → the
ROADMAP candidate row reworded by this plan, schedulable via `/milestone-plan`
on a go; fixed-rater / incomplete-FIML / nested-Design-2/3 / bootstrap
siblings → stay parked candidates behind that implementation; one-way SEM →
stays 🔴 blocked (ADR-014), untouched.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Source-hunt disposition recorded in the work log: either a primary
      source ingested per the validation doctrine (PDF in
      `cairn/references/pdf/`, committed `<citekey>.md` + `INDEX.md` line), or
      a recorded "none found" **with the maintainer's explicit IP1
      disposition** (parameterization under the M5 precedent vs blocked)
      obtained before any pilot conclusion is drawn. (RB tripwire:
      ip-touching)
- [ ] AC2: A committed, seeded pilot script fits the two-level formulation on
      balanced Design-1 data and recovers all five components against a
      glmmTMB fit of the same data, with stated tolerances split by index
      class (consistency tight, agreement asymptotic — M49 lesson), and shows
      the reduction: zero cluster variances → the current single-level lavaan
      engine's estimates.
- [ ] AC3: The pilot recovers injected known-population components (ten Hove
      DGP template, M5 spec §5) within stated tolerance across ≥3 cells
      including a high-cluster-count cell (GP6), and records an MC-interval
      feasibility finding (log-SD delta route on the two-level vcov, both
      levels).
- [ ] AC4: A committed `cairn/references/` synthesis note records the mapping,
      estimation constraints, pilot results with script pointers, boundary/
      Heywood observations, and the go/no-go; its `INDEX.md` line exists.
- [ ] AC5: ROADMAP candidate row + `COVERAGE.md` row 162 updated to cite
      M53's verdict (go → schedulable; no-go → re-tagged blocked with
      rationale).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T3
- AC3 → T4
- AC4 → T2, T5
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Source hunt (DOI/publisher/OSF; multilevel SEM-GT in the
      Vispoel/Jorgensen/ten Hove lineage). Hit → ingest (references page +
      INDEX line). Miss → **stop and ask the maintainer** for the IP1
      disposition before proceeding. (RB tripwire: ip-touching)
- [x] T2: Draft the two-level mapping in the synthesis note: model string,
      parameter↔component table, identification (effects-coded between-level
      intercepts), lavaan two-level estimation constraints (ML-only, complete
      data, meanstructure), expected small-sample deltas vs REML.
- [x] T3: Pilot part 1 (`data-raw/pilot-sem-multilevel.R`, seeded,
      checkpointed): balanced Design-1 simulation → two-level lavaan fit →
      five components vs glmmTMB; reduction check at σ²_c = σ²_{cr} = 0 vs
      the shipped single-level engine.
- [x] T4: Pilot part 2: known-population recovery sweep (4 cells incl. a
      high-N_c cell and a k=25 cell) + MC-interval feasibility probe (extract
      two-level vcov, log-SD transform, per-draw ICCs at both levels; note
      Heywood/boundary behavior).
- [x] T5: Finalize the synthesis note (results, go/no-go), log the
      disposition, update the ROADMAP candidate row + COVERAGE.md row.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-16: created by /milestone-plan (promotes the multilevel-SEM
  candidate's research half; plan gate: split research-first, sequenced ahead
  of M48, Design-1 base scope, search-first sourcing with ask-on-miss).
- 2026-07-16: in-progress on m53-multilevel-sem-pass by /milestone-implement;
  no open implementation choices (T1's ip-touching gate fires on its outcome).
- 2026-07-16: T1 done — source hunt MISS (Jorgensen 2021 single-level only;
  ten Hove 2022 MCMC; Vispoel arc single-level; 2026 MDPI paper is multigroup).
  Maintainer disposition at the ip-touching gate: proceed under the M5
  parameterization precedent → D-005.
- 2026-07-16: T2 done — synthesis note drafted (mapping + constraints + pilot
  design; results pending) at cairn/references/sem-multilevel-pilot.md, INDEX
  line added.
- 2026-07-16: pilot run 1 — Stage 1/reduction/MC-probe pins all hold; one
  Stage-2 pin failed (rater rel-bias +.0995 vs .05 at N_c=200) → diagnosed as
  a mis-set pin (k-governed noise, parity .001), GP5 correction recorded in
  Decisions; pins split + k=25 cell D added; re-run launched.
- 2026-07-16: T3+T4 done — pilot run 2 PASS, all pins hold (450 fits, 0
  failures; cell D rater rel-bias +.039 < .071 tol, parity ≤ .0088; MC probe
  feasible both levels). T5 done — synthesis-note Results + GO verdict;
  ROADMAP candidate row and COVERAGE.md row updated to cite M53.
- 2026-07-16: verify — full suite 1896 passed; 13 fail + 1 error, ALL in
  test-icc-brms.R's live-Stan tier, which passes clean in isolation; branch
  runtime surface identical to origin/main (docs + data-raw only), Stan stack
  unchanged since 2026-07-08 → pre-existing suite-order/environment condition
  on main, out of M53 scope; flagged to the maintainer for separate diagnosis
  (blocks M48 AC5 if unresolved). Status → review.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-07-16 (implement, GP5): the Stage-2 `.05` rel-bias pin at N_c=200 was
  mis-set for the rater component — σ²_r's sampling noise is governed by k
  (df = k−1), not N_c: at k=5, n_rep=100 the mean's rel SE is √(2/4)/10 ≈ .071,
  so a .05 pin was a ~1.4σ coin flip (observed +.0995 with SEM↔REML parity
  .001 — shared sampling noise, sign-flipping across cells, not an SEM
  artifact). Corrected prospectively before any re-run: rater pins split from
  the four cluster/subject-governed components — (a) per-rep REML-parity pins
  (the D-005 faithfulness quantity) and (b) a noise-floor-derived 3σ bias
  tolerance stated in-script; plus a new k=25 cell sweeping σ²_r's own axis
  (GP6). Failed-run checkpoint preserved in the synthesis-note ledger.

## Review
<!-- owner: review · exclusive -->
