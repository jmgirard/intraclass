# M107: Oracle-script reproducibility — the re-run harness and the first sixteen re-runs

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP5
- **Branch/PR:** m107-oracle-script-reproducibility

## Goal

Establish whether the seeded oracle scripts still reproduce their committed
values: a compare-don't-overwrite re-run harness under a pre-declared
divergence policy, run over the 15 non-Bayes `oracle-*.R` scripts plus the
motivating `oracle-bayesian.R`.

## Scope

**In:** the divergence-policy D-entry (pins are the bar; escalate, never
re-baseline; fixtures never overwritten by a re-run); the harness
(`data-raw/rerun-oracle.R`: writes redirected outside the worktree, pins
evaluated non-fatally, engine/package versions captured, one ledger row per
run); save-first hardening of the five pin-before-save legacy scripts
(`data-raw/README.md` list); sixteen re-runs and their committed ledger
`data-raw/oracle-rerun-ledger.tsv`; the in-place dated-observation correction
of the O-Bayes "not re-run" note in `cairn/references/ORACLES.md`.

**Out:** re-running the 19 remaining `oracle-bayesian-*.R` live-Stan scripts →
the rewritten ROADMAP candidate row (batch promotion through this harness);
adjudicating any divergence a re-run surfaces → escalation per the D-entry,
sized as its own follow-on work (D-008: a discrepancy is escalated, never
silently re-run); CI automation of re-runs → nowhere (live-Stan re-runs are
offline background jobs by design).

## Acceptance criteria

- [ ] AC1: `data-raw/oracle-rerun-ledger.tsv` is committed with one row per
      re-run script — script name, run date, engine/package versions of that
      run, and a verdict: for a fixture-writing script one of {reproduced,
      drift-within-noise, diverged-escalated}; for a script committing no
      fixture, {pins-pass, pins-fail-escalated} — and its script set equals
      the files matched by `ls data-raw/oracle-*.R` excluding
      `oracle-bayesian-*.R` (a set that includes `oracle-bayesian.R`). The
      set equality and the fixture-writing partition are each checked by a
      command recorded at review (partition via bare-`saveRDS` grep, per
      D-008 Amendment 1; a pin failure on a fixture-writing script records
      `diverged-escalated`).
- [ ] AC2: After each of the sixteen harness runs (the set AC1 enumerates),
      `git status --porcelain -- ':(exclude)data-raw/oracle-rerun-ledger.tsv'
      ':(exclude)cairn'` is literally empty — the harness sends script writes
      to a scratch directory outside the worktree (`tempdir()`) so committed
      fixtures are compared, never modified; the per-run command output is
      the review evidence.
- [ ] AC3: Each of the five scripts `data-raw/README.md`'s pin-before-save
      list names — `oracle-bayesian.R`, `oracle-bayesian-fixed.R`,
      `oracle-bayesian-incomplete.R`, `oracle-bayesian-incomplete-fixed.R`,
      `oracle-bayesian-oneway.R` — writes its fixture before its
      published-findings pins run (save-first; adding only a checkpoint does
      not satisfy this), so a marginal pin can no longer abort a run with
      nothing written. Four of the five are live-Stan siblings this milestone
      does not execute, so their verification is by reading each script at
      review.
- [ ] AC4: A D-entry records the divergence policy — the qualitative pins are
      the reproducibility bar; a divergence escalates and is never silently
      re-baselined; committed fixtures are not overwritten by a re-run;
      numeric drift and engine-version deltas are recorded — and no ledger
      row's run date is earlier than that entry's date.
- [ ] AC5: The fresh `oracle-bayesian.R` run's pin outcomes — its four
      `stopifnot` blocks (`data-raw/oracle-bayesian.R:226-247`; block 1 the
      convergence guard, blocks 2–4 the published findings) evaluated
      non-fatally by the harness, block-level pass/fail recorded for all
      four — are in the ledger row, and the O-Bayes entry's re-run
      observation in `cairn/references/ORACLES.md` (the parenthetical at
      ~lines 822–831 containing "The script was **not** re-run to
      adjudicate") is corrected in place to a dated observation of this run.
- [ ] AC6: The active profile's verify slot is clean, and after the edits
      these pass locally: `python3 data-raw/enumerate-generalizing-claims.py
      --check` (the checker that scans ORACLES.md; any new dated numeric
      observation gets its `generalizing-claims-triage.tsv` row),
      `python3 data-raw/check-reference-observations.py` (guards any new
      `data-raw/` file that names a citekey), and
      `python3 data-raw/check-oracle-registry.py` (registry-label integrity).

## Coverage

- AC1 → T3, T5, T6, T7
- AC2 → T3, T5, T6
- AC3 → T2
- AC4 → T1
- AC5 → T4, T6
- AC6 → T6, T7

## Tasks

- [x] T1: Commit the divergence-policy D-entry (gate-decided 2026-08-06):
      pins are the bar; escalate, never re-baseline; fixtures never
      overwritten by a re-run; drift and engine-version deltas recorded in
      the ledger.
- [x] T2: Save-first hardening of the five `data-raw/README.md`
      pin-before-save scripts (move fixture `saveRDS` ahead of the
      published-findings pins, minimal diff, same seed/flow); update the
      README note.
- [x] T3: Build `data-raw/rerun-oracle.R`: source a named oracle script with
      writes redirected to `tempdir()`, evaluate pins non-fatally, compare a
      fixture-writing script's fresh values to its committed fixture, capture
      R/glmmTMB/lme4/brms/rstan/StanHeaders versions, append the
      `data-raw/oracle-rerun-ledger.tsv` row.
- [x] T4: Launch the `oracle-bayesian.R` harness run in the background early
      in the session (~2 h live Stan; expect contention to double per-fit
      time).
- [ ] T5: Re-run the 15 non-Bayes scripts through the harness (the long
      `oracle-cluster-ck-coverage.R` at its committed n_rep, in background);
      record ledger rows and the per-run AC2 probe outputs.
- [ ] T6: Harvest the `oracle-bayesian.R` run: ledger row with block-level
      pin outcomes; correct the O-Bayes observation in `ORACLES.md` in place
      as a dated observation; add any generalizing-claims triage rows; run
      the three AC6 checkers locally.
- [ ] T7: Rewrite the ROADMAP reproducibility candidate row to the 19-script
      remainder; record AC1's set-equality and partition commands; full
      verify gate (`NOT_CRAN=true CI=true` suite, lintr, air).

## Work log

- 2026-08-06: created by /milestone-plan (from the D-008 → M72 T4 candidate row).
- 2026-08-06: criteria audit ([O] fresh reader, two passes) returned 5 then 4 findings — an AC2×AC5 write conflict, the no-fixture verdict gap, fatal-`stopifnot` per-pin unreachability, a same-day "postdates" failure, mislabeled AC6 checkers, an undecidable "tracking files" allowlist, a probe covering 6/16 runs, an in-worktree scratch dir, and a judgment-only fixture partition — all fixed in the AC wording as written; the second pass confirmed the fixes and re-verified the anchors.
- 2026-08-06: plan gate chose the 16-script scope over oracle-bayesian-only and all-35 because the non-Bayes runs are cheap and the 19 Stan re-runs are a multi-day job the harness unblocks; falsified by the harness proving unusable for a batched Stan re-run.
- 2026-08-06: plan gate chose escalate-never-re-baseline over re-baseline-on-drift because re-baselining erases provenance and makes every re-run self-certifying; falsified by a pin-level divergence traced to a benign engine-version change where the published finding still holds.
- 2026-08-06: D-021 collision disposed at the gate — the maintainer confirmed this scope proceeds under its untouched oracle-discipline clause; no superseding entry.
- 2026-08-06: T1 done — D-024 (divergence policy) appended; branch cut, status in-progress. Implement question gate skipped: no genuinely open choices (plan gate settled scope/policy/D-021; no dependency or API changes).
- 2026-08-06: T2 done — all five pin-before-save scripts reordered (Commit block ahead of pins), parse + air + lintr clean; README caveat rewritten (save-first everywhere; the five still lack checkpoints). Noted: `oracle-bayesian.R`'s "Observed" comment carries the pre-M72 numbers, matching the old ORACLES prose, not the fixture — T4/T6 will adjudicate.
- 2026-08-06: T3 done — harness built (shadowed non-fatal `stopifnot` recorder + `saveRDS` redirect to tempdir; leaf-wise fixture compare; replace-on-rerun ledger); bench-tested on oracle-sem.R (pins 2/2) and oracle-fixed-vs-random.R (pins 0/0, honest); air+lintr clean, ref-observations checker green.
- 2026-08-06: T4 done — `oracle-bayesian.R` fresh run (13.8 min, brms 2.23.0/rstan 2.32.7): diverged-escalated, pins 3/4 — block 1 (convergence guard) fails at k=2 conv .864 < .90 (fixture: .904); blocks 2–4 (published findings) all hold; max_abs_delta .040 = the k=2 convergence gap; AC2 probe literally empty. Escalation to the maintainer at the completion gate per D-024.
- 2026-08-07: T5 batch done (12 scripts overnight; every AC2 probe empty): 3 reproduced at delta 0 (incomplete-fixed-nested, nested-fixed-interval, sem-multilevel-recovery), 8 pins-pass, oracle-fixed-cluster-level drift-within-noise pins 3/3 (219.6 min; delta=Inf traced to structural NAs in the committed fixture's boundary cell — comparator artifact, row annotated), oracle-incomplete pins-fail-escalated 1/2 — diagnosed: its Oracle-2 pin assumes one-row `tidy()`, which now returns single+average rows, so scalar comparisons vectorize; the single-unit row itself is within every bound (est .5790 vs pop .5714). Stale script expectation, not statistical divergence; to the gate per D-024.
- 2026-08-07: comparator made NA-aware (positional compare; differing NA patterns → structural Inf); `oracle-cluster-ck-coverage.R` (the 15th non-Bayes script) launched in background at committed n_rep=240.

## Decisions

## Review
