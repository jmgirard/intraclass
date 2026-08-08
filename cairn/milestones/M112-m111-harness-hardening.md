<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M112: Harden the M111 fallback-sweep harness

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Close the M111 harness's three recorded defects — silent lost-worker cell
drop, abort-classification conflation, and the mis-implemented tie-break
near-miss — without touching the committed M111 evidence.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** guards in `data-raw/m111-fallback-sweep.R` so a killed parallel
worker fails the run loudly before any fixture write; an explicit abort
status in its `mc_ci()`/`one_rep()` so the MC leg's `aborted` flag records
only the classed `intraclass_singular_fit` abort; correction of
`data-raw/m111-fallback-verdict.R`'s near-miss count to the frozen
failing-side definition for F2 and F3, with an output-path override so a
re-run cannot dirty the committed ledger; a milestone-local decision
recording F1/F5 as inexpressible under the frozen tie-break text and the
count's vacuity-when-live (criteria audit, 2026-08-08).

**Out:** regenerating `m111-fallback-results.rds` / `m111-fallback-rules.rds`
— the committed evidence behind D-026 stays byte-identical (AC4); amending
the frozen tie-break definition for F1/F5 → rejected at the plan gate
(recorded in the work log), reopen only via an explicit maintainer decision;
the MC default's skew under-coverage → M113; any `R/` change → none needed.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: After the parallel map, the sweep driver asserts the result list
      has exactly one entry per cell, every entry is a data frame, and the
      bound raw table has `n_rep × 3` rows for each of the 64 cells, all
      before any fixture write; in a small-`n_rep` mutation run using a
      checkpoint directory distinct from the full run's, forcing one cell's
      result to `NULL` exits with an error, and the unmutated small-`n_rep`
      run passes the same assertions.
- [ ] AC2: The MC leg's `aborted` flag is set only from an explicit status
      `mc_ci()` returns on catching a condition of class
      `intraclass_singular_fit` (the classical legs' finiteness-based flags
      are unchanged; the divergence is stated in the script header); a
      stubbed MC leg returning non-finite endpoints without signalling that
      class errors loudly rather than counting as an abort, and a stub
      signalling the class counts as aborted.
- [ ] AC3: The verdict script's near-miss count implements the frozen
      failing-side definition for F2 and F3 (binding statistic within 0.005
      below the 0.93 floor), demonstrated on a synthetic ledger holding one
      constructed near-miss per rule plus clear passes and clear failures
      outside the window, counted exactly; F1 and F5 are recorded as
      inexpressible under the frozen text (no applicable window / no single
      binding statistic), not implemented.
- [ ] AC4: `git diff` is empty for `data-raw/m111-fallback-results.rds` and
      `data-raw/m111-fallback-rules.rds`; the corrected verdict script, run
      with its output-path override against the committed fixture,
      reproduces the shipped per-rule pass/fail outcomes with only the
      near-miss columns differing, and the corrected F2/F3 near-miss counts
      are recorded in the work log.
- [ ] AC5: `air format --check`, `lintr::lint_package()`, and all four
      `data-raw` checkers pass locally before the PR push (M62/M85 lessons).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3, T4
- AC4 → T3
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Add the post-`mclapply` guards (`m111-fallback-sweep.R:276-279`):
      length == cell count, all data frames, per-cell row counts; run the
      NULL-injection mutation and the clean pass at small `n_rep` with an
      isolated checkpoint dir; record both outcomes in the work log.
- [ ] T2: Return an explicit ok/abort status from `mc_ci()` (`:67-85`), set
      the MC leg's `aborted` from it in `one_rep()` (`:134`), turn the
      finiteness test into a should-never-fire loud error for the MC leg,
      and demonstrate both stub behaviors at small `n_rep`.
- [ ] T3: Correct `f2_near_miss` to the failing side, add the F3 window,
      add the output-path override (`m111-fallback-verdict.R:55,158`); run
      the synthetic-ledger demonstration and the committed-fixture dry run;
      log the corrected counts.
- [ ] T4: Record the F1/F5 inexpressibility + vacuity-when-live finding as
      a milestone-local decision (lineage: M111 review D6 → M112 criteria
      audit).
- [ ] T5: Run air, lintr, and the four `data-raw` checkers; fix what reds.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-08: created by /milestone-plan (promotes the m111-harness-hardening candidate row; plan gate 2026-08-08).
- 2026-08-08: criteria audit ([O], fresh-context) returned: AC1 checkpoint-dir hazard (fixed in wording), AC2 semantics-divergence note (fixed), AC3 unsatisfiable as drafted — F1 has no applicable 0.005 window and F5 no single binding statistic under the frozen text, and the failing-side count is vacuously 0 whenever the tie-break is live; AC4 self-contradiction via the hardcoded ledger path (fixed: output-path override, "verdict" claim dropped since the script only measures).
- 2026-08-08: plan gate chose fixing F2+F3 to the frozen failing-side definition over (a) amending the frozen definition for F1/F5 and (b) dropping the tie-break task, because a pre-registered criterion is not redefined after results are known and the two well-defined rules are cleanly correctable; falsified by a future sweep needing a live tie-break, which would require a newly frozen definition regardless.
- 2026-08-08: plan gate chose planning M112 independent of M113 over sequencing them, because M113 derives entirely from the committed fixture and never runs this harness; falsified by M113's derivation finding the fixture lacks per-rep leg rows (it would then need a re-run through this harness).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
