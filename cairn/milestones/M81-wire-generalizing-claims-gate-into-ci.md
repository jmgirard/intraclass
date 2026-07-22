# M81: Wire the M74 generalizing-claim completeness gate into CI + harden its vacuity

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** m81-wire-generalizing-claims-gate-into-ci

## Goal

Make `enumerate-generalizing-claims.py --check` run in CI so an un-triaged
generalizing claim on a references page can never sit red on main unnoticed.

## Scope

**In:** Add `--check` and `--self-test` steps for
`data-raw/enumerate-generalizing-claims.py` to M80's existing R-free
`check-references` job in `.github/workflows/lint.yaml` (the sibling gate to the
D-009 checker M80 wired). Extend the script's `--self-test` to also guard the
`--check` completeness comparison against becoming vacuous. Demonstrate the gate
reds on an un-triaged candidate before merge (M79 "run RED first" lesson).

**Out:** No change to claim-truth semantics — `--check` gates *enumeration
completeness* only, never a claim's correctness (D-009 scope fence). No new
references-page content, no ledger re-triage (the ledger is in sync today: 258
candidates / 258 rows). A `cairn_validate` plugin-side enforcement of the same
convention is the cairn repo's, not this one's (D-009).

## Acceptance criteria

- [ ] AC1: The `check-references` job in `.github/workflows/lint.yaml` runs
      `python3 data-raw/enumerate-generalizing-claims.py --check` as a step; it
      exits 0 on the current corpus (`un-triaged: 0   orphan rows: 0`), shown
      green in the CI run log.
- [ ] AC2: The same job runs
      `python3 data-raw/enumerate-generalizing-claims.py --self-test` as a step;
      it exits 0, shown green in the CI run log.
- [ ] AC3: The job stays R-free — no R setup step is added; the new steps use
      only `python3` + `git`.
- [ ] AC4: `self_test()` is extended to assert the `--check` completeness
      comparison returns a failure when a candidate key is absent from the
      ledger and success when every key is classified — a vacuity guard on the
      gate; `--self-test` still exits 0.
- [ ] AC5: The live gate is demonstrated RED before merge — a synthetic
      un-triaged candidate (or a dropped ledger row) makes `--check` exit
      non-zero — then reverted; the RED run output is recorded in the work log.
- [ ] AC6: R build unaffected — `Rscript -e 'devtools::test()'` clean and the
      built package byte-identical to pre-change (only `.Rbuildignore`d
      `data-raw/` + `.github/` paths changed); the full CI matrix is green.

## Coverage

- AC1 → T2, T5
- AC2 → T2, T5
- AC3 → T2
- AC4 → T1
- AC5 → T3
- AC6 → T4, T5

## Tasks

- [x] T1: Extend `self_test()` in
      `data-raw/enumerate-generalizing-claims.py` to exercise the completeness
      comparison on synthetic inputs — an un-triaged key yields a failure, a
      fully-classified set yields success (factor the set-diff out of
      `cmd_check` if that keeps it clean). Run `--self-test`; confirm exit 0.
- [x] T2: Add two steps to the `check-references` job in
      `.github/workflows/lint.yaml` (`--check`, then `--self-test`), and update
      the job comment to cover both D-009 and M74. Keep the job R-free.
- [x] T3: Demonstrate the gate is live — introduce a synthetic un-triaged
      generalizing claim (or drop a ledger row), run `--check`, capture the
      non-zero exit + stderr, revert; record in the work log.
- [x] T4: Verify R build unaffected — `devtools::test()` clean; confirm the
      built package is byte-identical (`data-raw/` + `.github/` are
      `.Rbuildignore`d).
- [ ] T5: Open the PR, drive the full CI matrix green, confirm the new steps
      ran and passed in the run log.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-21: created by /milestone-plan (promotes the M74-enumerator-CI candidate; lineage M74 → M80 *Out* → M81. Gate: add steps to M80's existing `check-references` job; also harden the `--check` vacuity guard in `self_test()`).
- 2026-07-21: T1 done — factored the completeness set-diff into `completeness_diff()` and extended `self_test()` to assert it reds on an un-triaged candidate + on an orphan ledger row, passes when fully classified. `--self-test` exit 0; `--check` still exit 0 (258/258 in sync).
- 2026-07-21: T2 done — added `--check` + `--self-test` steps for the enumerator to the `check-references` job in `.github/workflows/lint.yaml`; broadened the job comment to cover D-009 + M74. `actionlint` clean; job stays R-free (no `setup-r`).
- 2026-07-21: T3 done — live-gate demo: injected an un-triaged generalizing claim into `cairn/references/INDEX.md`; `--check` went RED (`un-triaged: 1`, exit 1) naming the line; `git checkout --` restored it and `--check` returned green (258/258). Tree clean; nothing committed.
- 2026-07-21: T4 done — R build unaffected: only R files changed are none (diff is `.github/` + `data-raw/*.py` + this tracking file, all `.Rbuildignore`d); `R CMD build` on branch vs `origin/main` gave byte-identical payloads bar the `Packaged:` timestamp. `NOT_CRAN=true CI=true devtools::test()`: FAIL 0 | WARN 2 | SKIP 23 | PASS 1901 (the 2 WARN are the pre-existing near-singular-Hessian annotations in test-icc-type-vector.R, unchanged from main).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
