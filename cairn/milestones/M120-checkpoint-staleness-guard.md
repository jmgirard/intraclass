# M120: Refuse a stale resume cache in the data-raw harnesses

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m120-checkpoint-staleness-guard` / https://github.com/jmgirard/intraclass/pull/129

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

- [x] AC1 The guard writes, beside each checkpoint payload, a spec carrying
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
- [x] AC3 Each of these planted-defect forms is demonstrated at least once, on
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
- [x] AC5 `git diff --stat main...HEAD` over the whole tree shows no change
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

- [x] T1 Record the site table: for each of the five sites, its checkpoint
      path expression, its declared parameter set and order, and the functions
      whose bodies form its declared generating block.
- [x] T2 Write `data-raw/checkpoint-guard.R` — spec construction, the
      base-R-only block hash (deparsed bodies via `tools::md5sum`; no new
      dependency), guarded write, and guarded read with the ordered mismatch
      message. Tests first.
- [x] T3 Add the run-scoped trace that records every checkpoint
      deserialization and aborts on an unguarded one, before any output write.
- [x] T4 Route all five sites through the guard, adding a path override to the
      four oracle scripts so no test run can reach a committed fixture path.
- [x] T5 Write the mutation demonstration covering every AC3 form, on the
      `m112-harness-demo.R` pattern with tempdir overrides throughout.
- [x] T6 Wire T5 plus a fast `m111` `n_rep = 2` run into the existing
      `data-raw` checker CI job; verify red by reverting one guard call.
- [x] T7 Full local gate; confirm the AC5 whole-tree diff and record the
      declared file list in the work log.

## Work log

- 2026-08-14: created by /milestone-plan.
- 2026-08-14: in-progress on `m120-checkpoint-staleness-guard`; implement gate chose a new R CI job for the runtime leg plus an R-free routing check in the existing checker job, over folding into the lint job or dropping the runtime leg; env-var path overrides follow the existing `M111_CKPT_DIR` idiom, and the trace installs itself when the guard is sourced rather than per-harness opt-in, an opt-in being the recall trap this milestone exists to close.
- 2026-08-14: plan-time criteria audit ran ([O], fresh context), returning 10 findings — none of AC1–AC5 clean as first drafted; findings 3, 4, 7 and 9 (working-tree-only diff; fixture enumeration missing `R/sysdata.rda` and `_snaps/`; one mutation exemplar standing for a family; an empty spec satisfying AC1) were fixed here, findings 1, 2, 5, 6 and 8 became the four gate questions, and finding 10 is answered below.
- 2026-08-14: audit finding 1 — the oracle scripts' clean-resume leg would run to completion and overwrite committed oracle fixtures, whose payloads carry `generated = Sys.Date()` and so change bytes even under exact numeric reproduction; AC3's clean leg is therefore scoped to tempdir-redirected runs and T4 adds the path override that makes that possible.
- 2026-08-14: plan gate chose watching deserialization at run time over a source scan for cache reads, because a scan is a list of remembered spellings and the repo already contains reads it would miss (`base::readRDS` and rebound aliases in `rerun-oracle.R:175,199,216-217`), the M118 failure shape; falsified by a checkpoint read the trace cannot observe.
- 2026-08-14: plan gate chose settings plus a narrow generating-block hash over settings alone and over a whole-file fingerprint, because settings alone miss a changed generator (the M112 re-run case) while a whole-file hash marks every cache stale after any edit, including this milestone's own; falsified by a generator change the declared block does not cover.
- 2026-08-14: plan gate chose CI wiring over the hand-run demonstration idiom, because a hand-run guard is asserted once at review and never again; falsified by the CI leg's runtime proving unaffordable.
- 2026-08-14: T1 — `data-raw/checkpoint-sites.tsv` declares the five resume sites, each with its compared parameters in declared order, the functions forming its generating-block hash, and whether one entry covers a cell or a rep; the four oracle sites' parameter sets were read off each script's own Config block rather than composed.
- 2026-08-14: T2/T3 — `data-raw/checkpoint-guard.R` ships spec construction, the base-R block hash, guarded write/read, per-entry stores, and the run-scoped `readRDS` trace; both landed in one file and one commit, and `data-raw/m120-checkpoint-guard-demo.R` was written first and observed to fail with the guard absent before any of it existed.
- 2026-08-14: the demo's first clean-case claim was wrong as written — it asserted a comment-only edit leaves the hash alone but actually re-braced the body, which is a body change; the case now tests the property that holds (a comment inside a block function, and an edit to a function outside the declared block) and passes.
- 2026-08-14: the trace catches `base::readRDS` as well as the bare call, verified in the demo — `trace()` rebinds in the base namespace, so the qualified spelling is not a hole.
- 2026-08-14: T4 — all five sites route through the guard: M111 per cell, the four oracle harnesses per rep/cell entry via `ckpt_store_*`, each with a `Sys.getenv()` override on BOTH its checkpoint path and its committed-fixture path so no demonstration run can reach either default. Each also registers its checkpoint with the trace and calls `ckpt_trace_assert()` before its fixture write.
- 2026-08-14: the four oracle scripts are wired but not executed — each needs brms/Stan and hours of refits, and running one to completion would overwrite the committed fixture AC5 fences. Their wiring is evidenced by parse, format, lint and the T6 routing check; the guard behaviour they share is evidenced on the demo site and on M111. No claim is made here that an oracle re-run was observed to abort.
- 2026-08-14: M111 smoke test — compute a cell at `n_rep = 2`, resume it (identical rows, trace clean), then re-run the same cell id with `rho` edited to 0.60: refused with "rho changed: recorded 0.05, current 0.6". That is the candidate row's exact scenario, now failing loudly.
- 2026-08-14: T5 — the demonstration covers every AC3 form and ends by running the M111 sweep itself at `n_rep = 2` with both paths redirected into a tempdir, so the guard is exercised on the harness the defect was found in and not only on a stand-in.
- 2026-08-14: T6 — `data-raw/check-checkpoint-sites.py` (stdlib-only) joins the R-free `check-references` job with its own mutation self-test; a new R `checkpoint-guard` job runs the demonstration. AC4's revert check was run on disk: reverting M111's `ckpt_read()` to `readRDS(ckpt)` makes the checker exit 1 naming both failures, and restoring it returns exit 0.
- 2026-08-14: the checker's own recall is bounded and says so in its output — it covers the sites `checkpoint-sites.tsv` declares and cannot see a sixth harness that starts resuming; the run-time trace is what covers that case, and neither surface claims the other's reach.
- 2026-08-14: adding a sixth `data-raw` checker staled two registered record claims (`data-raw-checker-inventory`, `lint-checker-invocations`); `data-raw/README.md` and `data-raw/record-claims.tsv` are corrected in the same commit as the change that staled them, per the M111/M114 lesson, and `check-record-claims.py` returns 0 failures.
- 2026-08-14: found and fixed a hole in the trace before review: M111 maps its cells with `parallel::mclapply`, so a forked worker's trace state dies with the worker and the parent's `ckpt_trace_assert()` was blind to every read a worker performed — vacuous on exactly the harness this guard was written for. The trace now aborts AT the read, in whichever process performed it; the end-of-run assertion is retained for a bypass a caller swallowed with `tryCatch`. Both are demonstrated, the fork case by planting an unspecced `cell-02.rds` and observing the worker fail and surface as `cells errored: 2`.
- 2026-08-14: the same fix exposed a second defect it depended on — the tracer wrapped its callback in `try(..., silent = TRUE)`, which swallowed the new abort, so the first run of the fork case passed a bare `readRDS` silently. The tracer now calls the note directly and the note ignores a connection argument, which is the only reason the `try` was there.
- 2026-08-14: T7 — full local gate green: `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 7564 ]`, `air format --check` clean, `lintr::lint_package()` no lints, `cairn_validate` all checks passed, all six data-raw checkers and their self-tests exit 0. The suite is unaffected by design — every changed R file is under `data-raw/`, which `.Rbuildignore` excludes.
- 2026-08-14: AC5 declared file list, the whole of what this branch changes: `.github/workflows/lint.yaml`, `cairn/ROADMAP.md`, `cairn/milestones/M120-checkpoint-staleness-guard.md`, `data-raw/README.md`, `data-raw/check-checkpoint-sites.py`, `data-raw/checkpoint-guard.R`, `data-raw/checkpoint-sites.tsv`, `data-raw/m111-fallback-sweep.R`, `data-raw/m120-checkpoint-guard-demo.R`, the four `data-raw/oracle-bayesian-*.R` sites, and `data-raw/record-claims.tsv`. Nothing under `tests/testthat/fixtures/`, `tests/testthat/_snaps/`, `R/sysdata.rda`, or any `.rds` is touched.
- 2026-08-14: status review.
- 2026-08-14: review return 1 (defect) — AC2 fails on two counts: the trace's `guarded` set is permanent, so a swallowed bypass after any legitimate read is subtracted out and never reported (F1, 80); and the fork demonstration exercises the spec check, not the trace, so the bare-read-inside-a-worker scenario the trace fix was written for is demonstrated nowhere (F25, 85). AC4 fails because the routing checker matches raw text with no comment stripping (F14, 82) and accepts `ckpt_read` OR `ckpt_store_get` anywhere in the file, so an oracle site can drop its per-entry guard undetected (F15, 80). AC2 and AC4 unticked; status in-progress. F3, F4, F10 and F11 (85/82/85/85) are actioned alongside.
- 2026-08-14: the AC2 evidence line recorded earlier in this same review claimed the fork case demonstrates the trace surviving `mclapply`; that claim was false and is corrected in the Review section rather than left standing.
- 2026-08-14: audit finding 10 — the records-apparatus door needs a trigger in what the package computes; this milestone's deliverable guards numeric harness output, which that door's own carve-out leaves untouched ("guards that pin a NUMERIC result", "repairs to existing checkers surfaced as ordinary work"), and four of the five sites write committed oracle fixtures, so it is oracle discipline under #1 — no stale cache has yet produced a wrong shipped value, and the plan does not claim one.

## Decisions

## Review

Reviewed 2026-08-14 on `m120-checkpoint-staleness-guard` at PR #129. `main` was
level with origin and the branch not behind it, so no merge preceded this
evidence.

**AC1 — spec recorded, mismatch names the earliest differing entry.** Fresh run
of `Rscript data-raw/m120-checkpoint-guard-demo.R`. A matching cache returns the
cached payload; a changed `rho` and a changed `dist` are each refused by name;
with two parameters differing at once the message names the earlier in declared
order, shown both ways round (`dist` before `base_seed`, `rho` before `dist`),
so the rule is order-sensitive rather than set-sensitive. `ckpt_spec()` refuses
an empty parameter list at construction, so the null guard AC1's last sentence
forbids cannot be built.

**AC2 — no unguarded deserialization survives.** Same run. A guarded run passes
the trace; a bare `readRDS` and a `base::readRDS` of a registered checkpoint each
abort at the read; a bypass swallowed by a caller's `tryCatch` still fails the
end-of-run assertion; a read outside any registered location is not flagged. The
fork case is exercised directly: an unspecced `cell-02.rds` planted under
`mclapply` makes the worker refuse and surface to the parent as `cells errored:
2`, before any fixture write.

**AC3 — every planted-defect form.** Same run, each form on a cache the demo
writes itself: two parameters mismatching individually; a spec absent entirely;
a cache written by another site (refused naming `other-site`); a partially stale
multi-entry store (the current-design entry served, its superseded sibling
refused); and a generating-block hash differing with every parameter matching.
The counterweight case passes too — a comment inside a block function and an
edit to a function outside the declared block both leave the cache usable, so
the hash is not so wide that every cache is permanently stale. Clean resume is
shown in the same script on the real M111 site.

**AC4 — the five sites route through the guard, and reverting one reds.**
`python3 data-raw/check-checkpoint-sites.py` exits 0 over the five declared
sites. Reverting the `source()` of the guard in
`oracle-bayesian-multilevel-replicates.R` makes it exit 1 naming that file;
restoring returns exit 0 with an empty diff. Its `--self-test` plants three
separate reversions and confirms each is detected, and that the unmutated site
passes.

**AC5 — nothing outside the declared file list.** `git diff --name-only
main...HEAD` filtered for `tests/testthat/fixtures/`, `tests/testthat/_snaps/`,
`R/sysdata.rda` and `*.rds` returns nothing. The 14 changed files are exactly
the list the work log declares.

**AC6 — verify slot and the toolchain gate.** `devtools::test()` `[ FAIL 0 |
WARN 3 | SKIP 2 | PASS 7564 ]`; `air format --check` exit 0;
`lintr::lint_package()` no lints; `devtools::document()` produces no diff under
`NAMESPACE`/`man/`; `cairn_validate` exit 0 across all 24 checks; all six
`data-raw` checkers and every self-test exit 0. `devtools::check()` recorded
below. No NEWS entry is owed — every changed R file is under `data-raw/`, which
`.Rbuildignore` excludes from the build, so nothing user-visible changed.

**`devtools::check()`** — 0 errors, 0 warnings, 0 notes (13m 33s).

**CI on PR #129** — `check-references`, `checkpoint-guard`, `lint`,
`format-check` and `pkgdown` all pass; `R CMD check` on both platforms and
coverage were still running at the return.

### Independent review — three lenses, then a scorer

The blame-history lens (Sonnet) and the prior-review lens (Sonnet) each reported
no findings: no regression of a prior milestone's intent, no contradiction of a
recorded decision, no regression of a LESSONS entry. Both independently
confirmed the four oracle rewrites preserve iteration order, output positions,
seed derivation and fixture contents. The diff-bug lens (Opus) reported 31
candidates, scored by a fresh Sonnet scorer holding the diff and this file.

**Actioned (score >= 80), eight findings.** Four demonstrate an acceptance
criterion failing as written and force the return; four are severe verified
gaps that do not violate a criterion's literal text.

- **F1 (80, AC2 fails).** `ckpt_read()` unions the path into the trace's
  `guarded` set permanently, and `ckpt_trace_assert()` is
  `setdiff(observed, guarded)`. After any legitimate guarded read of a path, a
  later bare `readRDS` of that same path whose abort a caller swallows is
  subtracted out and never reported. The demo's swallowed-bypass case passes
  only because `ckpt_trace_reset()` precedes it, which no real site calls.
- **F25 (85, AC2 fails).** The fork demonstration does not exercise the trace.
  The planted `cell-02.rds` carries no spec, so it aborts through the ordinary
  spec check; the bare-`readRDS`-inside-a-forked-worker scenario the trace fix
  was written for is demonstrated nowhere. AC2's fork evidence is missing, and
  this file's own earlier claim to the contrary was wrong.
- **F14 (82, AC4 fails).** `check-checkpoint-sites.py` matches raw file text
  with no comment stripping, so `# source("data-raw/checkpoint-guard.R")` and
  `# ckpt_trace_assert()` both pass. Commenting the guard out during debugging
  is invisible to CI.
- **F15 (80, AC4 fails).** The routing regex accepts `ckpt_read` OR
  `ckpt_store_get` anywhere in the file. Replacing an oracle site's
  `ckpt_store_get(...)` with direct payload access leaves `ckpt_read` present
  and the checker silent — restoring the pre-M120 defect on the four sites CI
  can never run.
- **F3 (85).** `get0(..., mode = "function")` inherits, so a renamed block
  function resolves to a same-named function up the search path. Two sites
  declare a block function named `simulate`, which shadows `stats::simulate`:
  rename it and the hash tracks the generic forever.
- **F4 (82).** Four of five declared blocks under-cover their generators —
  `est_occ()`, `cell_offset`, `kc_of()` and the brms `base_fit` all determine
  cached numbers and sit outside the hashed block.
- **F11 (85).** The per-entry store is inert on all four oracle sites: file-level
  and entry-level checks use the same spec, so the file check always fires first
  and the entry check can never discriminate. AC3's partial-staleness form holds
  only on the stand-in, which writes under a different site name.
- **F10 (85).** `file_spec()` uses cell 1's parameters as the whole file's spec,
  so editing cell 1 discards valid cells 2-4 (~720 Stan refits).

**Logged below the action bar (score < 80), 23 findings** — surfaced, not
dropped: F2 formals excluded from the block hash (75); F19 self-test probes only
site 1 (65); F6 re-sourcing the guard resets trace state while `readRDS` stays
traced (65); F24 five site comments claim the trace self-installs when it does
not (65); F12 raising `n_rep` now discards the whole cache (60); F16 the checker
never enforces the declared parameter ORDER (60); F23 the CI comment overstates
"end to end" (60); F22 the job installs the full Suggests closure (55); F8 the
trace fires on every `readRDS` process-wide (50); F5 `all.equal` accepts a type
change (40); F7 `in_guard` does not restore (40); F17 the bare-read regex is
anchored to the name `ckpt` (40); F26 the smoke case mutates a cell rather than
`build_cells()` (40); F28 the TSV overclaims what the hash invalidates (40);
F13 `ckpt_store_get` conflates absent with NULL payload (35); F27 the "whatever
spelling" framing overstates (35); F9 `deparse` is not stable across R releases
(30); F20 the `site` string is unvalidated (30); F29 the new checker is arguably
records apparatus needing its own decision entry (30); F30 the TSV row count is
unpinned (30); F18 the spec-block regex is coupled to air's indentation (25);
F31 bare `stop()`/`cat()` in `data-raw` (20); F21 the claim that the CI job
would fail for a missing `devtools` (5) — empirically false, that job passes.

### Return

Returned to `in-progress` at the first defect return for this milestone. F1 and
F25 fail AC2; F14 and F15 fail AC4. AC2 and AC4 are unticked; AC1, AC3, AC5 and
AC6 keep their recorded evidence. F3, F4, F10 and F11 are actioned in the same
pass.
