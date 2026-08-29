# M147: `choose_icc()` answers the type question with "both"

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2
- **Branch/PR:** `m147-choose-icc-type-both`

## Goal

Let `choose_icc()`'s `type` axis take `"both"`, the value its own `unit` and
`level` axes already take, so a user who wants the agreement/consistency pair
gets a recommendation for the pair instead of being made to choose one.

## Scope

Surface tier: **user-facing** — `choose_icc()` is exported and `type` is
documented in `?choose_icc`, the *Choosing an ICC* article, and `NEWS.md`.

**In:** `choose_icc(type = "both")` resolves; `recommendation_rows()` loops the
type axis the way it already loops `unit` and `level`; the emitted `icc()` call
omits `type =` when both are wanted, matching how it already omits
`unit = "both"`; the rationale and notes gain their both-type sentence; every
surface stating the `type` axis's accepted values is swept.

**Out:** any change to `icc()`'s own `type` vocabulary — it already reports both
by default (`R/icc.R:760`) and D-035/D-036 fix it as a report-all axis; the
`fit=`/data-in path and a `tidy`/`glance` method on the recommendation, both
still deferred by ADR-021; the v0.1.0 submission itself → M148.

## Acceptance criteria

- [ ] AC1. `choose_icc(type = "both", ...)` returns an `icc_recommendation`
      whose `$rows` holds one row per (type x unit x level) combination the
      other answers select, each row's `index` and `sf_index` read from
      `icc_estimand()` as the single-type rows already are
      (`R/choose-icc.R:401-434`). On a two-way, random-rater, single-unit,
      non-multilevel design that is exactly two rows: `ICC(A,1)`, whose
      Shrout & Fleiss equivalent is `ICC(2,1)`, and `ICC(C,1)`, for which the
      crosswalk names no Shrout & Fleiss equivalent (`sf_index` is `NA`) --
      `ICC(3,1)` is the *fixed*-rater consistency label, not this one.
- [ ] AC2. `choose_icc(type = "both", ...)$call` omits `type =` from the
      emitted `icc()` call, and evaluating that call on the shipped `ratings`
      data returns exactly the coefficients AC1's rows name — ADR-021's
      round-trip oracle, extended to the new value. Established over every
      valid axis combination the existing round-trip grid at
      `tests/testthat/test-choose-icc.R:55-95` enumerates, with `"both"` added
      to its `type` vector.
- [ ] AC3. `choose_icc(model = "oneway", type = "both", ...)` aborts with the
      same classed inapplicable condition `type = "agreement"` raises on a
      one-way design today (`R/choose-icc.R:291`) — the one-way design has no
      type axis, and `"both"` does not become an exception to that.
- [ ] AC4. `grep -rn 'choose_icc' R/ man/ vignettes/ README.Rmd NEWS.md`
      returns no hit that states the `type` axis's accepted values without
      `"both"`, and no hit claiming the chooser resolves to a single
      coefficient — the claim `R/choose-icc.R:447-450` makes today, already
      false for `unit = "both"` with `level = "both"`.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T1, T2
- AC4 → T4

## Tasks

- [x] T1. Tests first, run red: extend the round-trip grid's `type` vector at
      `tests/testthat/test-choose-icc.R:55-95` with `"both"`; add the row-set
      expectation (AC1's named two-row case), the emitted-call omission, and
      the one-way inapplicability case beside the existing `type = "agreement"`
      one.
- [x] T2. `resolve_*` validates `type` against
      `c("agreement", "consistency", "both")` (`R/choose-icc.R:312-320`);
      `recommendation_rows()` gains a `types` loop mirroring its `units` and
      `levels` switches (`R/choose-icc.R:401-412`).
- [ ] T3. `build_icc_call()` omits `type =` when `type == "both"`, the shape
      it already uses for `unit` (`R/choose-icc.R:447-461`); correct the stale
      one-coefficient comment there; `recommendation_rationale()` and
      `recommendation_notes()` gain their both-type sentence.
- [ ] T4. Roxygen `@param type` states `"both"` in the shape `@param unit`
      already uses (`R/choose-icc.R:41-46`); `devtools::document()`; a
      `NEWS.md` bullet under *What ships*. Then run AC4's grep, record the
      command and its full hit list in the work log, and disposition every hit.
- [ ] T5. Gate: `air format .`, `devtools::document()` no-diff,
      `devtools::test()`, the `data-raw/` checkers with `--self-test` (a
      roxygen prose edit re-keys the doc-claim ledgers — M130), then
      `devtools::check()` read off the raw `Status:` line (M127/M128/M145).
      Open the PR.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: plan-gate criteria audit ran in FULL mode (user-facing tier). It ran in-session rather than in a fresh-context [O] subagent — agent delegation is not authorized this session, the same departure M145 and M146 recorded. Three findings, all fixed at the gate. (a) A draft AC4 hand-listed the surfaces to update (roxygen, NEWS); a hand-list is not a procedure and every site it omits ships stale (M118, recurring at M140 and M146), so the criterion now quantifies over a grep's hit set. (b) A draft clause promised the grep command and hit list were recorded in the milestone; that binds a recording instrument, not the deliverable (D-118, extended to recording acts by D-120), so it moved into T4. (c) A draft AC restated the consistency gate's own `devtools::test()`/`check()` runs; dropped as redundant, the shape M145's review rejected as "one restatement AC1 required".
- 2026-08-28: collision check found no standing rejection. `R/choose-icc.R:447-450` asserts "choose_icc() resolves to ONE coefficient (ADR-021)", but ADR-021's own text promises "the recommended coefficient label(s)" and the claim is already false — `unit = "both"` with `level = "both"` yields four rows. This milestone therefore supersedes no decision; it corrects a stale comment, which AC4 covers.
- 2026-08-28: absorbs the ROADMAP candidate row "`choose_icc()` accepts `type = \"both\"`" (lineage: RR04 rec. 8 -> M48 ingest 2026-08-25), removed from Candidates in this commit. The row triaged it out of M48 as "additive after release"; the maintainer chose at this plan's question gate to land it before the CRAN door closes instead.
- 2026-08-28: T1 tests written, run red: 6 failures at `test-choose-icc.R:64,139,164,177,384,385`, every one the `validate_choice()` abort ``` `type` must be one of "agreement" and "consistency". ``` reached from `R/choose-icc.R:313`. AC3's one-way case (`test-choose-icc.R:208`) passes already and is discriminating: `choose_icc(model = "oneway", unit = "single", type = "both")` raises `intraclass_inapplicable/intraclass_error` from `reject_inapplicable()`, while the invalid-value path raises `intraclass_error` without that subclass, so the asserted class cannot be satisfied by a rejected value.
- 2026-08-28: implement question gate, both answered as recommended: the interactive `type` question gains a third choice `"both"` (its `unit` and `level` siblings already offer one), and a both-type recommendation carries a note saying the emitted call omits `type =` because `icc()` reports both error definitions by default. Row order was settled in-session without a gate: `recommendation_rows()` loops type outermost, matching the order `icc()` itself builds its estimate table in (`R/icc.R:2243`, `R/icc.R:2330`).
- 2026-08-28: T2 done. `validate_choice()` accepts `"both"` for `type`; `recommendation_rows()` loops type outermost, then level, then unit, matching the order `icc()` builds its estimate table in. The interactive walkthrough's type question gained its third choice. AC1's row expectations now pass; the remaining 6 failures are all the emitted-call and display work T3 owns.
- 2026-08-28: AC1 amended at a mini gate (substantive). Its named case claimed `ICC(C,1)` pairs with Shrout & Fleiss `ICC(3,1)` under random raters; the crosswalk names no Shrout & Fleiss equivalent there, and `ICC(3,1)` is the fixed-rater consistency label -- `test-choose-icc.R:122` has asserted the `NA` since M12. Unsatisfiable as written. The maintainer chose correcting the labels over switching the example to fixed raters; the row-set promise is unchanged and no criterion was added or widened.
- 2026-08-28: the amended AC1 wording went through the full criteria audit (user-facing tier) before it was written. It ran in-session rather than in a fresh-context [O] subagent -- agent delegation is not authorized this session, the same departure the plan gate and M145/M146 recorded. No findings: the named case is reachable (run against the branch), no IP or D-entry blocks it, "one row per (type x unit x level) combination the other answers select" quantifies over the domain `recommendation_rows()`'s own three expanded vectors enumerate, the promise binds `choose_icc()`'s returned object rather than any test or recording instrument, its domain is the exported function's return value at the declared user-facing tier, and the criterion cites no mutation or planted-defect probe. The `R/choose-icc.R:401-434` cite predates this branch's edits and was left rather than re-churned.
- 2026-08-28: plan gate chose the string `"both"` over `icc()`'s vector vocabulary `c("agreement", "consistency")` because D-037 classifies arguments per (function, argument) pair and `choose_icc()`'s own `unit` and `level` axes already spell the pair `"both"`; falsified by evidence that a user reads the two functions' `type` vocabularies as one contract.

## Decisions

## Review
