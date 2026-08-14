# M120: Refuse a stale resume cache in the data-raw harnesses

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Make every instrumented `data-raw/` harness refuse a checkpoint that was not
computed under the current design instead of silently resuming from it.

## Scope

**In:** a shared guard sourced by the five resume-from-checkpoint harnesses
(`m111-fallback-sweep.R:285`; `oracle-bayesian-fixed-replicates.R:205`,
`-incomplete-oneway.R:214`, `-incomplete-fixed-nested.R:238`,
`-multilevel-replicates.R:218`). Each cached payload is written beside a spec
recording the site's declared design parameters and a hash of its declared
generating block; a read whose recorded spec differs from the current one
aborts. A run-scoped trace fails the run if any checkpoint deserialization
bypassed the guard. A CI leg exercises the guard on fast synthetic harnesses
and on `m111` at `n_rep = 2`.

**Out:** running the four oracle scripts to completion, and any re-baselining
of their committed fixtures — the re-run programme owns that, under the
escalate-never-re-baseline policy. Out: the M104 containment-sweep guards →
existing candidate row. Out: any write to a committed fixture (AC5).
Out: harnesses that write a checkpoint but never read one back — they cannot
serve a stale row, and the trace reports them as unread rather than guarding
them.

## Acceptance criteria

- [ ] AC1 The guard writes, beside each checkpoint payload, a spec carrying
      the site's declared parameter set in a declared order — for `m111`
      exactly `rho`, `k`, `n`, `dist`, `n_rep`, and the cell's base seed — plus
      a hash over that site's declared generating block, and a read whose
      recorded spec differs from the current one signals an error naming the
      earliest differing entry in that declared order. A spec recording no
      entries is a failure of this criterion, not a satisfaction of it.
- [ ] AC2 During any run in which the guard's trace is installed, every
      deserialization of a checkpoint path either went through the guard or
      aborts the run before the harness writes any output. Evidence is the
      trace's own report over the runs AC3 and AC4 perform — this criterion
      claims nothing about a run in which the trace was not installed.
- [ ] AC3 Each of these planted-defect forms is demonstrated at least once, on
      a cache the demonstration writes itself: each declared parameter
      mismatching individually (at least two different parameters, showing the
      naming rule); a spec absent entirely (the pre-existing on-disk case); a
      cache whose early rows predate a design change and whose later rows do
      not; a cache written by a different site at the same path; and a spec
      matching on every parameter but differing in the generating-block hash.
      Each aborts, and a matching cache resumes normally in the same script.
- [ ] AC4 The five sites in the Scope table source the guard, and the CI job
      that already runs the repo's standalone `data-raw` checkers fails when a
      listed site's cache read bypasses it. Verified by reverting one site's
      guard call and observing that job red.
- [ ] AC5 `git diff --stat main...HEAD` over the whole tree shows no change
      outside the file list this milestone declares in its work log — in
      particular no change under `tests/testthat/fixtures/`,
      `tests/testthat/_snaps/`, `R/sysdata.rda`, or any `data-raw/*.rds`.
- [ ] AC6 The profile's `verify` slot is clean, and `air format --check`,
      `lintr::lint_package()` and all four existing `data-raw` checkers pass.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T5
- AC4 → T4, T6
- AC5 → T7
- AC6 → T7

## Tasks

- [ ] T1 Record the site table: for each of the five sites, its checkpoint
      path expression, its declared parameter set and order, and the functions
      whose bodies form its declared generating block.
- [ ] T2 Write `data-raw/checkpoint-guard.R` — spec construction, the
      base-R-only block hash (deparsed bodies via `tools::md5sum`; no new
      dependency), guarded write, and guarded read with the ordered mismatch
      message. Tests first.
- [ ] T3 Add the run-scoped trace that records every checkpoint
      deserialization and aborts on an unguarded one, before any output write.
- [ ] T4 Route all five sites through the guard, adding a path override to the
      four oracle scripts so no test run can reach a committed fixture path.
- [ ] T5 Write the mutation demonstration covering every AC3 form, on the
      `m112-harness-demo.R` pattern with tempdir overrides throughout.
- [ ] T6 Wire T5 plus a fast `m111` `n_rep = 2` run into the existing
      `data-raw` checker CI job; verify red by reverting one guard call.
- [ ] T7 Full local gate; confirm the AC5 whole-tree diff and record the
      declared file list in the work log.

## Work log

- 2026-08-14: created by /milestone-plan.
- 2026-08-14: plan-time criteria audit ran ([O], fresh context), returning 10 findings — none of AC1–AC5 clean as first drafted; findings 3, 4, 7 and 9 (working-tree-only diff; fixture enumeration missing `R/sysdata.rda` and `_snaps/`; one mutation exemplar standing for a family; an empty spec satisfying AC1) were fixed here, findings 1, 2, 5, 6 and 8 became the four gate questions, and finding 10 is answered below.
- 2026-08-14: audit finding 1 — the oracle scripts' clean-resume leg would run to completion and overwrite committed oracle fixtures, whose payloads carry `generated = Sys.Date()` and so change bytes even under exact numeric reproduction; AC3's clean leg is therefore scoped to tempdir-redirected runs and T4 adds the path override that makes that possible.
- 2026-08-14: plan gate chose watching deserialization at run time over a source scan for cache reads, because a scan is a list of remembered spellings and the repo already contains reads it would miss (`base::readRDS` and rebound aliases in `rerun-oracle.R:175,199,216-217`), the M118 failure shape; falsified by a checkpoint read the trace cannot observe.
- 2026-08-14: plan gate chose settings plus a narrow generating-block hash over settings alone and over a whole-file fingerprint, because settings alone miss a changed generator (the M112 re-run case) while a whole-file hash marks every cache stale after any edit, including this milestone's own; falsified by a generator change the declared block does not cover.
- 2026-08-14: plan gate chose CI wiring over the hand-run demonstration idiom, because a hand-run guard is asserted once at review and never again; falsified by the CI leg's runtime proving unaffordable.
- 2026-08-14: audit finding 10 — the records-apparatus door needs a trigger in what the package computes; this milestone's deliverable guards numeric harness output, which that door's own carve-out leaves untouched ("guards that pin a NUMERIC result", "repairs to existing checkers surfaced as ordinary work"), and four of the five sites write committed oracle fixtures, so it is oracle discipline under #1 — no stale cache has yet produced a wrong shipped value, and the plan does not claim one.

## Decisions

## Review
