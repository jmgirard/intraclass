<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M109: Re-run the 19 remaining oracle-bayesian-*.R scripts through the harness

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M108   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP5   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m109-bayesian-oracle-reruns · https://github.com/jmgirard/intraclass/pull/118   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: `data-raw/oracle-rerun-ledger.tsv` carries a row with run_date on
      or after this milestone's branch date for every script enumerated by
      `ls data-raw/oracle-bayesian-*.R` (the glob excludes
      `oracle-bayesian.R` itself), each with a D-024 verdict and captured
      engine versions.
- [x] AC2: At review, `git diff --stat origin/main -- tests/testthat/fixtures/`
      is empty — the committed fixtures tree is unchanged vs origin/main.
- [x] AC3: Each escalated verdict (`diverged-escalated` /
      `pins-fail-escalated`), if any, has a ROADMAP candidate row created in
      the same commit as its ledger row; and the ledger's git history on the
      milestone branch shows each escalated row persisting unreplaced from
      its escalation commit to review (the harness replaces a script's row
      on re-run, so an unreplaced row IS the evidence no post-escalation
      re-run happened — D-024 clause 3).
- [x] AC4: `oracle-bayesian-cluster-ck.R` and
      `oracle-bayesian-incomplete-fixed-nested.R` express their
      published-findings pins outside `stopifnot` (a `check()` helper and an
      `in_band` verdict loop), which the harness's `stopifnot` recorder does
      not see; their ledger rows' notes field records those pin outcomes
      from the run transcript.
- [x] AC5: Each batch task's work-log entry records elapsed minutes per
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
- [x] T2: Batch 2 (~1,340 fits): `-fixed`, `-incomplete-fixed-multilevel`,
      `-incomplete-multilevel`, `-multilevel`, `-nested`, `-oneway`.
- [x] T3: Batch 3 (~1,760 fits): `-incomplete-fixed`, `-incomplete`,
      `-incomplete-nested-subjects`, `-incomplete-oneway`.
- [x] T4: Batch 4 (~1,680 fits): `-cluster-ck`, `-incomplete-fixed-nested`;
      capture both scripts' non-`stopifnot` pin outcomes from the run
      transcripts into their ledger notes (AC4).
- [x] T5: Escalation sweep: candidate rows for any escalated verdicts
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
- 2026-08-08: T2 complete (pre-launch concurrent-R check: a circumplex devtools::check session active — contention expected; it also explains T1's glmmTMB reinstall window): fixed 2.8m drift-within-noise 1/1, incomplete-fixed-multilevel 14.8m reproduced 4/4, incomplete-multilevel 22.6m reproduced 5/5, multilevel 48.2m reproduced 4/4, nested 35.8m drift-within-noise 3/3, oneway 3.4m drift-within-noise 4/4. Batch 2 totals: 6/6 rows, zero escalations — the k=2 cells in -multilevel and -oneway both cleared their pins.
- 2026-08-08: T3 complete (pre-launch concurrent-R check: none active): incomplete-fixed 4.8m reproduced 4/4, incomplete 6.7m reproduced 4/4, incomplete-nested-subjects 49.8m reproduced 3/3, incomplete-oneway 5.2m reproduced 5/5. Batch 3 totals: 4/4 rows, all reproduced at max_abs_delta 0, zero escalations.
- 2026-08-08: T4 complete (pre-launch concurrent-R check: none active): cluster-ck 111.0m reproduced 2/2, incomplete-fixed-nested 280.6m reproduced 1/1, both max_abs_delta 0. AC4 notes captured from the run transcript into both ledger rows: cluster-ck's check() pins 5/5 PASS (min coverage A=0.942 C=0.946), incomplete-fixed-nested's in_band verdicts 4/4 PASS (worst cell mod_boundary coverage 0.9542).
- 2026-08-08: T5 complete — ledger scan shows zero escalated verdicts (AC3 vacuous: no candidate rows owed, no persistence check applicable); `git diff --stat origin/main -- tests/testthat/fixtures/` empty; all 19 oracle-bayesian-*.R scripts carry rows dated 2026-08-07/08. Verify slot: devtools::test() 6116 pass, 0 fail, 0 error, 0 skip (live-Stan brms tests ran). Status → review.
- 2026-08-08: review F6 disposition — the plan-gate falsifier ("a batch's measured wall-clock exceeding a working session") arguably fired: batch 4 ran ~6.5 h continuous and the sweep totalled ~12.5 h vs the 4–10 h estimate. The decision (one milestone, four batches) stands — the work completed within the milestone and background launches made no batch block a sitting — but the M107 500-fits/13.8-min anchor understates heavier per-fit geometries ~2–5×; the next multi-script Stan sweep should anchor per design family, not per fit count.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

Review 2026-08-08 (PR #118). Acceptance-criteria evidence, fresh by command:

- AC1: glob-driven sweep — all 19 `data-raw/oracle-bayesian-*.R` scripts have a ledger row dated 2026-08-07/08 with a D-024 verdict (11 reproduced, 8 drift-within-noise) and captured engine versions (R 4.6.1, glmmTMB 1.1.14, brms 2.23.0, rstan 2.32.7). PASS.
- AC2: `git diff --stat origin/main -- tests/testthat/fixtures/` → 0 lines. PASS.
- AC3: ledger verdict scan → 0 escalated verdicts; vacuously satisfied (no candidate rows owed, no persistence check applicable). PASS.
- AC4: both rows' notes fields carry the transcript pin outcomes — cluster-ck "non-stopifnot check() pins … 5/5 PASS", incomplete-fixed-nested "non-stopifnot in_band verdicts … 4/4 PASS". PASS.
- AC5: work log carries 5 batch lines (T1 ×2 spanning the glmmTMB interruption, T2–T4), each with per-script elapsed minutes and the pre-launch concurrent-R check. PASS.

Consistency gate 2026-08-08: cairn_validate exit 0 (all checks pass); devtools::document() no diff; pkgdown::check_pkgdown() clean; devtools::check(NOT_CRAN=false) 0 errors / 0 warnings / 0 notes; no principle changed (cairn_impact skipped); no user-visible change, so no NEWS entry owed. devtools::test() full suite: 6116 pass / 0 fail / 0 error / 0 skip.

Independent review (3 lenses + scorer, PR #118): blame-history — no findings (pre-existing ledger rows byte-identical, growth strictly additive, no escalated-then-replaced row); prior-review — no regression (1 candidate, self-cleared); diff-bug — deep positive verification (pins denominators, n_compared_leaves, and AC4 note values independently reproduced from scripts and fixtures; work-log elapsed figures corroborated by commit timestamps) + 10 candidate findings. Scorer: 0 of 11 findings reached the 80 action threshold — actioned list empty. Logged (id, score, one line):
- PR1 28: drift rows lack unseeded-template attribution — D-024 defines the verdict by outcome; scope put script fixes Out.
- F1 35: reproduced/drift split correlates with the D-025 seeding pattern, unrecorded — D-025's Consequences already document the precedent.
- F2 55: fixed-replicates has no set.seed at all (largest delta 3.26e-02) — real, but script fixes are scoped Out and the verdict follows D-024 mechanically.
- F3 22: drift-within-noise has no magnitude bound — a D-024/harness design critique predating this diff.
- F4 12: AC4 pins live in notes prose, not the pins column — the Scope's explicitly chosen tradeoff.
- F5 42: a future harness re-run replaces the two AC4 rows and cannot regenerate their notes — M107 harness behavior, untouched here.
- F6 62: the plan-gate wall-clock falsifier arguably fired (batch 4 ≈6.5 h; sweep ≈12.5 h vs est. 4–10 h) with no disposition — dispositioned by work-log line this review.
- F7 15: Goal "close the gap" vs measured-not-closed for drift rows — unmodified line.
- F8 66: the T1 recovery relaunch has no separate pre-launch concurrent-R check line — AC5's unit is the batch task and T1's entry records the check; the relaunch was gated on the install completing and the same-version landing is recorded.
- F9 32: AC4 transcript citations not independently checkable — values verified to match fixtures.
- F10 18: AC4 notes break the elapsed_min-last segment convention — no consumer parses the field.
