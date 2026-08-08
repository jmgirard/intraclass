<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M109: Re-run the 19 remaining oracle-bayesian-*.R scripts through the harness

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M108   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m109-bayesian-oracle-reruns   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Close the PRINCIPLES.md #12 reproducibility gap for the 19 remaining live-Stan
Bayesian oracle scripts via the M107 harness under D-024.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** all 19 `data-raw/oracle-bayesian-*.R` scripts through
`data-raw/rerun-oracle.R`, as four runtime-ordered background batches
(~5,620 total Stan fits; est. 4–10 h from M107's 500-fits/13.8-min anchor);
a ledger row per script; escalations recorded as ROADMAP candidate rows in
the same commit; ledger-notes recording of the two scripts whose
published-findings pins the harness's `stopifnot` recorder cannot see.

**Out:** adjudicating any escalation — each is its own follow-on work
(D-024 clause 3), with M108's remedy as precedent; modifying any script or
committed fixture — the harness compares, never overwrites; extending the
harness to record non-`stopifnot` pin idioms — the notes field is the record
this milestone (rejected-alternative line in the work log).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `data-raw/oracle-rerun-ledger.tsv` carries a row with run_date on
      or after this milestone's branch date for every script enumerated by
      `ls data-raw/oracle-bayesian-*.R` (the glob excludes
      `oracle-bayesian.R` itself), each with a D-024 verdict and captured
      engine versions.
- [ ] AC2: At review, `git diff --stat origin/main -- tests/testthat/fixtures/`
      is empty — the committed fixtures tree is unchanged vs origin/main.
- [ ] AC3: Each escalated verdict (`diverged-escalated` /
      `pins-fail-escalated`), if any, has a ROADMAP candidate row created in
      the same commit as its ledger row; and the ledger's git history on the
      milestone branch shows each escalated row persisting unreplaced from
      its escalation commit to review (the harness replaces a script's row
      on re-run, so an unreplaced row IS the evidence no post-escalation
      re-run happened — D-024 clause 3).
- [ ] AC4: `oracle-bayesian-cluster-ck.R` and
      `oracle-bayesian-incomplete-fixed-nested.R` express their
      published-findings pins outside `stopifnot` (a `check()` helper and an
      `in_band` verdict loop), which the harness's `stopifnot` recorder does
      not see; their ledger rows' notes field records those pin outcomes
      from the run transcript.
- [ ] AC5: Each batch task's work-log entry records elapsed minutes per
      script and the pre-launch concurrent-R-session check (the M107
      contention lesson).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3, T4
- AC2 → T5
- AC3 → T5
- AC4 → T4
- AC5 → T1, T2, T3, T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Batch 1 (~840 fits): `-conflated`, `-fixed-replicates`,
      `-replicates`, `-multilevel-fixed`, `-incomplete-nested`,
      `-multilevel-replicates`, `-nested-fixed` — one background
      `rerun-oracle.R` invocation; work-log elapsed + concurrent-R check.
- [ ] T2: Batch 2 (~1,340 fits): `-fixed`, `-incomplete-fixed-multilevel`,
      `-incomplete-multilevel`, `-multilevel`, `-nested`, `-oneway`.
- [ ] T3: Batch 3 (~1,760 fits): `-incomplete-fixed`, `-incomplete`,
      `-incomplete-nested-subjects`, `-incomplete-oneway`.
- [ ] T4: Batch 4 (~1,680 fits): `-cluster-ck`, `-incomplete-fixed-nested`;
      capture both scripts' non-`stopifnot` pin outcomes from the run
      transcripts into their ledger notes (AC4).
- [ ] T5: Escalation sweep: candidate rows for any escalated verdicts
      (same-commit as their ledger rows — verify none was authored later);
      confirm the fixtures tree is clean vs origin/main and each escalated
      ledger row persisted unreplaced.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-07: created by /milestone-plan (promotes the 19-re-runs candidate row; depends on M108 so sibling escalations inherit its remedy precedent).
- 2026-08-07: criteria audit ([O] fresh-context reader) returned 3 findings on this file's ACs — AC2's per-run universal outran its diff procedure, AC3's no-re-run clause named no enumerating procedure (and the harness's row replacement would destroy the violation's evidence), AC4's "the two scripts whose pins are not stopifnot" was a hand-list posing as exhaustive; all fixed with the auditor's repairs (diff-domain restatement; ledger git-history persistence; scoped to the two named scripts) before the gate.
- 2026-08-07: plan gate chose one milestone with four runtime-ordered batch tasks over per-batch milestones (the candidate row's framing) because M107's measured anchor (500 fits = 13.8 min) puts the ~5,620-fit sweep at hours, not days; falsified by a batch's measured wall-clock exceeding a working session.
- 2026-08-07: plan gate chose depends-on M108 over parallel execution because sibling scripts share the fixed-warmup pattern and ≥.90 pins (k=2 cells in `-multilevel` and `-oneway`), so the adjudicated remedy sets the escalation precedent; falsified by M108's remedy proving inapplicable to a sibling's divergence class.
- 2026-08-07: plan chose ledger-notes recording of the two non-`stopifnot` scripts' pins over extending the harness recorder, because the harness shipped M107-reviewed and a notes field preserves the record without reopening it; falsified by a third script adopting a non-`stopifnot` pin idiom.

- 2026-08-07: T1 batch 1 launched (pre-launch concurrent-R check: one active R session — a tidymedia devtools::test run, contention expected); 5/7 scripts ledgered: conflated 33.0m drift-within-noise 4/4, fixed-replicates 8.8m drift-within-noise 4/4, replicates 11.3m drift-within-noise 4/4, multilevel-fixed 15.8m drift-within-noise 1/1, incomplete-nested 35.8m reproduced 3/3. Run halted at the ledger-row step of -multilevel-replicates: a concurrent glmmTMB reinstall had removed the package from the site-library mid-run, so the harness's version capture errored — verified a harness/environment artifact (live R.INSTALL process + 00LOCK-glmmTMB observed), not a pin failure; -multilevel-replicates and -nested-fixed queued to re-run after the install completes.
- 2026-08-07: T1 complete — the glmmTMB reinstall landed 1.1.14 (same version, no ledger straddle); recovery re-run: multilevel-replicates 42.8m drift-within-noise 8/8, nested-fixed 17.4m reproduced 1/1. Batch 1 totals: 7/7 rows, 2 reproduced + 5 drift-within-noise, zero escalations; wall-clock ≈2.9h against the ~25m the M107 anchor implied — per-fit geometry + contention, consistent with the M107 lesson.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
