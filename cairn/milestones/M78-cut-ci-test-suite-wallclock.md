# M78: Cut CI test-suite wall-clock — parallelism + residual boot_samples (GO/NO-GO)

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3, GP5, GP6
- **Branch/PR:** m78-cut-ci-test-suite-wallclock · https://github.com/jmgirard/intraclass/pull/84

## Goal

Cut CI wall-clock by shrinking the testthat suite — the measured cost (13m ubuntu / 18m Windows), not the already-cached dependency install — without weakening any oracle.

## Scope

**In:**
- Correct the record: the M77 lesson blamed CI wall-clock on the `needs: check`
  dependency install; the measured cost is the `check-r-package` testthat suite
  (install is a cached ~33–52s). Supersede via a `DECISIONS.md` entry + a
  `LESSONS.md` correction.
- Profile the testthat suite under R CMD check conditions; name the heaviest
  files with per-file elapsed evidence.
- Lever A — parallelism (rigor-free): raise the testthat worker count to the
  runner core count on the ubuntu + Windows check jobs, and make Windows engage
  parallelism at all (it prints one `[18m]`, no CPU/elapsed split vs ubuntu's
  `[24m/13m]`). GO/NO-GO on runner-memory stability.
- Lever B — residual structural `boot_samples`: cut to the B=99 reproducibility
  floor in STRUCTURAL cells only (well-formed / monotone / coherence /
  reproducible), never a coverage or agreement cell.
- Measure the wall-clock on the PR's own R-CMD-check run vs the 13m/18m baseline.

**Out:**
- Any O1/O2 coverage/agreement `n_rep`/`boot` count — load-bearing per GP5/GP6;
  stays untouched.
- Dependency caching / `needs:` narrowing — falsified (install already
  ~33–52s cached); dropped, recorded in the D-entry (AC1).
- brms live-Stan tests — already `skip_on_ci` (25 skipped); untouched.
- Example (~1s) and vignette (~70s) runtime — negligible; → candidate if needed.

## Acceptance criteria

- [ ] AC1: A `cairn/DECISIONS.md` entry records the measured breakdown (install
      33–52s cached; testthat 13m ubuntu / 18m Windows) and supersedes the M77
      install-cost claim; the M77 `LESSONS.md` line is corrected in place.
      Evidence: the D-entry + the diff.
- [ ] AC2: The testthat suite is profiled per-file under R CMD check conditions
      (`NOT_CRAN=true`), heaviest files named with elapsed in the work log.
      Evidence: the profiling command + its output.
- [ ] AC3: The ubuntu + Windows check jobs run testthat at the runner core count
      (worker count set explicitly), OR a D-entry records a NO-GO with the
      memory/stability evidence. Evidence: the workflow diff + the PR run's
      testthat CPU/elapsed split (or the NO-GO entry).
- [ ] AC4: The PR's own R-CMD-check run shows a measured testthat wall-clock
      reduction vs the 13m/18m baseline, OR a D-entry records the NO-GO with
      per-lever evidence. Evidence: the PR run's per-step timing vs baseline.
- [ ] AC5: `git diff` shows no O1/O2 coverage/agreement count changed — only
      structural `boot_samples` (→99 floor) and CI config; the full suite still
      reports `FAIL 0`. Evidence: the diff + the PR run's summary line.
- [ ] AC6: All PR checks green (R-CMD-check matrix, lint, format, coverage); the
      profile `verify` slot clean (`devtools::test()` with `NOT_CRAN=true`,
      `CI=true`, `max_fails=Inf`). Evidence: `gh pr checks` + verify output.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T3, T4, T5
- AC5 → T4, T5
- AC6 → T5

## Tasks

- [x] T1: Correct the record — add a `cairn/DECISIONS.md` entry with the measured
      breakdown superseding the M77 install-cost claim; correct the M77
      `cairn/LESSONS.md` line (2026-07-21). Docs-only.
- [x] T2: Profile the testthat suite per-file under R CMD check conditions
      (`NOT_CRAN=true`, testthat parallel); record heaviest files + elapsed in
      the work log; confirm the parallel ceiling (ubuntu ~1.85×, Windows serial).
- [x] T3: Lever A — set the testthat worker count to the runner core count in
      `.github/workflows/check-standard.yaml` (ubuntu + Windows) via
      `Ncpus`/`TESTTHAT_CPUS` or `Config/testthat`; verify Windows engages
      parallelism. GO/NO-GO on OOM/flake → D-entry if NO-GO.
- [x] T4: Lever B — cut `boot_samples` to the B=99 floor in STRUCTURAL cells only
      (`test-ci-bootstrap.R`, `test-ci-npbootstrap.R`, `test-d-study.R`,
      `test-replicates.R`), updating asserted `samples` literals; leave every
      coverage/agreement count. Verify `FAIL 0` locally.
- [ ] T5: Open the PR; measure the testthat wall-clock on its own R-CMD-check run
      vs the 13m/18m baseline; record the NO-GO D-entry if no safe lever helped.
      Confirm all checks green.

## Work log

- 2026-07-21: created by /milestone-plan. Scope pivoted from the M77-lineage
  "cache CI R dependencies" candidate after investigation falsified its premise:
  dep install is a cached ~33–52s; the real CI wall-clock is the testthat suite
  (ubuntu 13m/24m CPU, Windows 18m). Disposition (user): full test-suite
  reduction, both levers in one milestone, any-safe-reduction + NO-GO valve.
- 2026-07-21: T1 — added D-011 (CI wall-clock is the testthat suite, not the dep
  install) superseding the M77 install-cost claim; corrected the M77 LESSONS line
  in place with the measured breakdown. Docs-only.
- 2026-07-21: T2 — profiled the suite per-file (local, serial, `NOT_CRAN=true
  CI=true`, testthat 3e; scratchpad `profile-suite.R`). Total 434s; heaviest:
  ci-bootstrap 118s, icc-lavaan-multilevel-incomplete 110s, icc-lavaan-multilevel
  65s, d-study 61s, icc-multilevel 25s. Parallel floor = the single longest file
  (ci-bootstrap 118s), whose cost is O1/O2 coverage refits (load-bearing, GP5/GP6
  — Lever B cannot touch it). Root cause of the 2× ceiling: testthat
  `default_num_cpus()` returns `getOption("Ncpus")` → `TESTTHAT_CPUS` → hard
  default 2, so workers never exceed 2 regardless of runner cores (explains
  ubuntu's 24m CPU / 13m elapsed ≈ 1.85×). CI absolute numbers deferred to the PR
  run (AC4); local macOS is ~3× faster per fit than CI ubuntu.
- 2026-07-21: T3 — added a `Scale testthat parallel workers to the runner core
  count` step to `check-standard.yaml` setting `TESTTHAT_CPUS=$(getconf
  _NPROCESSORS_ONLN)` (nproc/2 fallbacks; portable across the Linux/macOS/Windows
  matrix) before `check-r-package`. actionlint clean. Confirmed locally:
  `default_num_cpus()` = 2 unset → 4 with `TESTTHAT_CPUS=4`. Windows/OOM GO/NO-GO
  resolves on the PR run (AC3/AC4). Coverage job left untouched (covr is not the
  wall-clock concern; runs tests sequentially).
- 2026-07-21: T4 — Lever B is nearly exhausted. Minor amendment to the plan's
  file guess: the named files (ci-bootstrap/npbootstrap/d-study/replicates) were
  already floored by M59 — their structural cells sit at/below B=99 and every
  heavy cell is load-bearing O1/O2. The only above-floor STRUCTURAL cells are
  `test-boundary-policy.R:83` (completes-at-boundary) and `test-icc-lavaan.R:521`
  (fixed-rater serves-the-bootstrap); cut both 199→99 (neither asserts a `samples`
  literal; FAIL 0 on both files, air-clean). Deliberately LEFT `npbootstrap`
  L34/L168 (199): the file is 1.1s, L34 hard-asserts `ci$samples == 199L` under an
  M75 AC, and cutting saves ~nothing (cheap MoM resamples, not refits). Net: Lever
  B cannot touch the parallel floor (ci-bootstrap's O1/O2 refits, GP5/GP6), so the
  reduction rests on Lever A; the two cuts are floor-alignment, not the driver. No
  O1/O2 count changed (AC5).

## Decisions

## Review
