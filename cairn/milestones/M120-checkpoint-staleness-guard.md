# M120: Refuse a stale resume cache in the data-raw harnesses

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m120-checkpoint-staleness-guard` / https://github.com/jmgirard/intraclass/pull/129

## Goal

Make every declared `data-raw/` resume harness refuse a checkpoint that was not
computed under the current design, and make each declared site's coverage —
which functions and values its cache depends on, and whether its reads route
through the guard — computed by reachability rather than by a hand-listed set.
Which harnesses are declared sites stays an enumeration; the run-time watcher
covers an undeclared one only while it runs.

## Scope

**In:** the guard shared by the five declared resume harnesses
(`m111-fallback-sweep.R` and the four `oracle-bayesian-*.R` sites): its spec and
staleness refusal, its `readRDS` watcher, and the static check over the declared
sites. Within a site, what a cache depends on and whether its reads route
through the guard are computed by walking its parsed source; every list that
weakens a check — exemptions, appliers, entry-point idioms — is recorded with a
stated reason and is itself probed.

**Out:** running the four oracle scripts to completion or re-baselining their
fixtures (the re-run programme owns that, under the escalate-never-re-baseline
policy). Out: any write to a committed fixture (AC5). Out: deserialization
functions outside AC2's declared list, and reads through a connection — a
candidate row carries these, and AC2's own probe is what would surface a site
adopting one. Out: harnesses that write a checkpoint but never read one back.

## Acceptance criteria

- [ ] AC1 For each of the five declared sites, the static check walks, from that
      site's declared entry points, every symbol appearing in the walked bodies,
      following transitively those resolving to functions the site's own source
      defines, and reports a failure naming the symbol when a walked symbol
      resolves to a top-level binding of that site and is neither hashed, nor
      among that site's declared parameters or declared values, nor among its
      declared exemptions — each exemption carrying a stated reason in
      `checkpoint-sites.tsv`, and the exemption column empty on any site with no
      compiled-object determinant. That static walk is this criterion's
      procedure; `ckpt_spec()` implements the same rule at run time, and the two
      are shown to return an identical symbol set on a synthetic site exercising
      a captured value, a captured function, a shadowed local and an exempted
      object. Demonstrated on that synthetic site: editing a determinant reached
      by variable capture rather than by a call changes the hash, and removing
      its declaration is reported by name. Nothing is claimed about a
      determinant reached other than as a symbol in a walked body.

- [ ] AC2 For each of the five declared sites, no call to `readRDS`, `load`,
      `unserialize` or `readr::read_rds` — the deserialization list, recorded in
      `checkpoint-sites.tsv` and required to contain at least those four —
      occurs in that site's own source or in any non-package file it `source()`s
      other than the guard. Verified by planting one call to each listed name in
      each site in turn and observing the check report it. This is an
      enumeration, not a discovery procedure: it claims nothing about a
      deserialization function outside the list, and neither does AC3.

- [ ] AC3 During a run in which the guard has been sourced, a `readRDS()` call
      taking a length-one character path naming a registered checkpoint, that
      did not go through the guard, aborts at the read in the process that
      sourced the guard or any process forked from it, and is reported by the
      end-of-run assertion even when the process that performed it swallowed the
      abort. Demonstrated for a bare call, a namespace-qualified call, a
      caller-bound alias, a call inside a forked worker, a call inside a forked
      worker whose abort that worker swallows, a swallowed call in the parent
      following a legitimate guarded read of the same path, and a bare call
      after the guard has been sourced a second time in that process — the
      re-source leaving registrations and recorded bypasses intact. Outside this
      claim: a process that did not inherit the trace by forking, a `readRDS()`
      given a connection, and every deserialization function other than
      `readRDS`, which AC2 covers statically within the declared sites.

- [ ] AC4 The static check decides whether a guard call is reached by the
      declared rule — called from live top-level code, transitively, or handed
      by name to a function in the declared applier list — where live excludes
      anything under a condition neither literally true nor among the declared
      entry-point idioms, each idiom carrying a stated reason in
      `checkpoint-sites.tsv`. Its mutation self-test plants, on every declared
      site and once per name in that site's declared `api` column, each form in
      its declared mutation list, which includes at least: the guard call
      deleted; present but reached from nothing; under a non-literal false
      condition; under a declared idiom inside a function nothing calls; the
      pre-write assertion moved after that site's first output write, on each
      site performing one, a site with none being reported rather than skipped;
      and the registration given a non-path argument. Each planted form is
      detected on each site and on each of its declared guard calls, and each
      unmutated site passes. The check, run on a tree carrying one planted form,
      is observed to exit non-zero, and CI invokes it as a step that is not
      `continue-on-error`. Coverage of the listed forms only is claimed.

- [ ] AC5 `git diff --name-only main...HEAD -- '*.rds' '*.rda' '*.RData'
      'tests/testthat/_snaps/**' 'tests/testthat/fixtures/**'` is empty,
      `git status --porcelain` is empty, and `git diff --name-only main...HEAD`
      shows no path outside the most recent file list this milestone declares in
      its work log.

- [ ] AC6 The profile's `verify` slot is clean, and `air format --check`,
      `lintr::lint_package()`, and every checker matched by `data-raw/check-*.R`
      and `data-raw/check-*.py` exit 0. Every such checker declares in
      `data-raw/record-claims.tsv` whether it has a `--self-test`; each that
      does exits 0 under it and prints one PASS line per planted mutation, and
      each that does not is listed there with a stated reason.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T6, T7
- AC4 → T4, T5
- AC5 → T8, T9
- AC6 → T8, T9

## Tasks

- [x] T1 Walk every symbol in the walked bodies, not only call heads; classify
      each as hashed, declared parameter, declared value, or declared exemption,
      and abort naming an unclassified one. Add the exemption column with
      reasons.
- [x] T2 Give the static check the same walk over parsed source, and pin the two
      against each other on a synthetic site exercising a captured value, a
      captured function, a shadowed local and an exempted object.
- [x] T3 Add the deserialization-call check over each site and the files it
      sources, with the required-minimum list; plant one call of each listed
      name in each site and observe it reported.
- [x] T4 Implement the reachability and liveness rules — declared appliers,
      declared entry-point idioms with reasons — including a guard call under a
      declared idiom inside a function nothing calls.
- [x] T5 Quantify the mutation self-test per site, per form, and per declared
      guard call.
- [x] T6 Make sourcing the guard twice in one process leave registrations and
      recorded bypasses intact.
- [x] T7 Extend the watcher demonstration to the seventh case and scope its
      claim to `readRDS`.
- [x] T8 Switch the fixture fence to the diff-based enumeration; declare each
      checker's self-test status in `record-claims.tsv`.
- [x] T9 Full local gate; re-confirm the AC5 diff and re-declare the file list.

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
- 2026-08-14: return-1 gate chose hashing declared VALUES alongside function bodies (over comparing them as parameters) and a store file that records only its site (over a file-level design spec restricted to shared parameters, and over dropping per-entry checking); both are recorded in the Decisions section above.
- 2026-08-14: F1 — the trace now records the BYPASS as an event rather than recording paths and subtracting the guarded ones; verified against the pre-fix guard that the demo's new case (a guarded read, then a swallowed bare read of the same path, no reset between) reported nothing there and aborts here.
- 2026-08-14: F25 — the fork case now plants a bare `readRDS` of a VALID registered checkpoint inside an `mclapply` worker, so nothing but the trace can refuse it; isolated by mutation (suppressing the abort when the reading process is not the parent reds that case and no other). The pre-existing unspecced-cell case is retained and relabelled as what it is, the spec check reaching inside a worker.
- 2026-08-14: F14/F15 — the routing checker strips R comments (quote-aware) before matching, and `checkpoint-sites.tsv` gained an `api` column declaring the guard calls each site must make, ALL of which are required; the self-test now probes every declared site and plants a reversion per declared call plus two comment-outs — the mutations `--self-test` prints, each detected.
- 2026-08-14: F3 — declared block names resolve without inheriting past `globalenv()`, so a renamed block function aborts as "not found" instead of resolving to a same-named function on the search path; demonstrated on `simulate`, the name two sites share with `stats::`.
- 2026-08-14: F4 — the four oracle sites now name their base formula, prior and sampler arguments (and their seed offsets, `est_occ` and `kc_of`) and declare them in the block; the base fits are compiled from the named objects, so the fit and the hashed declaration cannot drift apart.
- 2026-08-14: F10/F11 — `ckpt_store_save()`/`ckpt_store_load()` replace the file-level design spec on all four store sites; the per-entry check is now the only design check on those files, and the partial-staleness form is exercised on a store the demo writes under the guard's own store API.
- 2026-08-14: return-1 gate re-run green — `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 7564 ]` (unchanged, as expected: every changed R file is under `data-raw/`), `air format --check` clean, `lintr::lint_package()` no lints, `cairn_validate` all checks passed, all six data-raw checkers and their self-tests exit 0, and the demonstration script exits 0. The AC5 declared file list is unchanged — this return adds no file.
- 2026-08-14: re-review — all six criteria re-executed with fresh evidence and the consistency gate green (`devtools::test()` 7564 passing, `devtools::document()` no diff, `pkgdown::check_pkgdown()` clean, `cairn_validate` 24 checks, CI green on `12bc264` including `R CMD check` on both platforms); AC1, AC3, AC5, AC6 hold.
- 2026-08-14: review return 2 (defect) — AC2 fails on two new mechanisms: a checkpoint registered before it exists is never matched by the trace, because `normalizePath(mustWork = FALSE)` leaves a non-existent path relative while a later read resolves absolute (D3, 90), and a bypass a forked worker swallows with `tryCatch` reaches no assertion, the parent's state being a different process (D13, 90). AC4 fails because the routing checker's token test misses three reversions of a site's guard call — an assertion moved after the fixture write, `ckpt_trace_register(NULL)`, and a live per-entry read replaced while a dead one remains (D7, 92), the last being the F15 class again. AC2 and AC4 unticked; status in-progress. D2, D10, D5 and D11 (87/85/82/82) are actioned alongside; 18 findings are logged below the action bar.
- 2026-08-14: thrash trigger (b) fired on both AC2 and AC4 — each has now failed twice by a new mechanism of the same shape. The plan gate's recorded falsifiers have both fired: "a checkpoint read the trace cannot observe" (D3, D13, D4) and "a generator change the declared block does not cover" (D11); the remedy is to reconsider those recorded alternatives rather than patch the next mechanism.
- 2026-08-14: return-2 gate reconsidered both recorded alternatives and chose, for the trace, a structural rebuild over adding the rejected source scan beside it (the scan's own weakness — it knows only remembered spellings — is what just failed the other criterion); for the routing check, parsing the R source over hardening the text match; and for the block, deriving the function set from the call closure of declared entry points over hand-listing it. Discovered tasks T8–T13 added (minor amendment).
- 2026-08-14: T8 — the trace installs when the guard is sourced (so a caller cannot bind an untraced alias, and cannot omit the install; the five sites' install calls are removed and their comments are now true), resolves a path's identity through its deepest existing ancestor after absolute-izing (so a relative path registered before its first write still matches), and records a bypass to a run-scoped marker directory (so a forked worker's swallowed abort still reaches the parent's assertion). Each of the three is demonstrated and each demonstration was shown to red when its own fix is reverted — the relative-path case only after it was moved outside the already-registered tempdir, where it had been passing for the wrong reason.
- 2026-08-14: T9 — `data-raw/check-checkpoint-sites.R` replaces the Python checker and parses the sources it checks: dead `if (FALSE)` branches are dropped before anything is counted, `ckpt_trace_register()` must get a real argument, `ckpt_trace_assert()` must precede the site's first output write, and the declared parameters must appear in declared ORDER. The three reversions that walked past the old checker are each detected on every site by `--self-test`, and the retired checker was re-run on the dead-copy mutation and observed to exit 0, so the improvement is measured rather than assumed.
- 2026-08-14: T9 — the routing check moves from the R-free `check-references` job to the `checkpoint-guard` job, which already has R; `data-raw/README.md` and `record-claims.tsv` are re-derived in the same commit (five stdlib-only python3 checkers, eight invocations) and `check-record-claims.py` returns 0 failures.
- 2026-08-14: T10 — the hashed block is now the call closure of declared entry points: `ckpt_spec()` takes `roots` (functions, walked transitively through the site's own definitions) plus `values` (the non-function determinants, still declared, because following data references would drag in the compiled model object). m111's two missing estimator legs are covered without being named, and the demo shows an undeclared helper's edit invalidating a cache.
- 2026-08-14: T11 — `rerun-oracle.R` now redirects at the checkpoint PATH via the sites' own env-var overrides, rather than relying on shadowed `readRDS`/`saveRDS` bindings the guard's globalenv-scoped functions never saw; a fresh re-run can no longer reach a real checkpoint through the guard's own I/O.
- 2026-08-14: T12 — `n_rep` is dropped from the three sites whose entry is one rep, since a rep's payload depends only on its seed; the nested site keeps it, its entry being a whole cell. Raising `n_rep` there now extends the cache instead of discarding it.
- 2026-08-14: two walkers hit R's empty-argument marker (the blank in `d[keep, , drop = FALSE]`), which errors on every touch once a `for` loop binds it; both iterate by index now. Found by the demo failing on the real M111 site, not by inspection.
- 2026-08-14: `cairn_validate` advisory — M120 now carries 13 tasks, over the 10-task split tripwire. Not split: the added tasks are one deliverable's repair under a review return, and splitting mid-return would strand the criteria that fail on the branch that no longer owns them.
- 2026-08-14: T13 — full local gate green after the return-2 redesign: `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 7564 ]`, `air format --check` clean, `lintr::lint_package()` no lints, `cairn_validate` all checks passed (one advisory, the 13-task tripwire, answered above), the guard demonstration and the routing check and its self-test all exit 0, the five python checkers exit 0, and `m112-harness-demo.R` — which drives the changed `run_cell` read/write path and was missing from the earlier gate list — passes.
- 2026-08-14: AC5 declared file list, the whole of what this branch changes, unchanged in shape but with two entries turned over: `.github/workflows/lint.yaml`, `cairn/ROADMAP.md`, `cairn/milestones/M120-checkpoint-staleness-guard.md`, `data-raw/README.md`, `data-raw/check-checkpoint-sites.R` (replacing the retired `.py`), `data-raw/checkpoint-guard.R`, `data-raw/checkpoint-sites.tsv`, `data-raw/m111-fallback-sweep.R`, `data-raw/m120-checkpoint-guard-demo.R`, the four `data-raw/oracle-bayesian-*.R` sites, `data-raw/record-claims.tsv`, and `data-raw/rerun-oracle.R` (newly declared, for T11). Nothing under `tests/testthat/fixtures/`, `tests/testthat/_snaps/`, `R/sysdata.rda`, or any `.rds` is touched, and the working tree is clean.
- 2026-08-14: review return 3 (defect) — AC4 fails because a guard call parked in a function nobody calls, or under any non-literal dead condition, satisfies the parsing checker (E1 95, E15 85); AC2 fails because re-sourcing the guard wipes every registration and orphans recorded bypasses (E3 88) and a connection-argument read is not traced at all (E2 85); AC1 fails because the derived block misses a determinant reached by variable capture rather than by a call, so editing `est_occ()` leaves the hash identical on two oracle sites and `kc_of` on a third (E4 90). AC1, AC2 and AC4 unticked; status in-progress. 15 findings logged below the action bar. Thrash: third return reached, and trigger (b) has fired on AC2 and AC4 in all three reviews with both recorded plan alternatives now spent.
- 2026-08-14: re-cut by /milestone-plan after the third defect return. Goal, Scope, acceptance criteria, Coverage and Tasks are superseded; the branch, its work, and the two prior Decisions entries stand. The diagnosis the re-cut acts on: every criterion that failed made a universal claim no procedure it named could enumerate, so each is now either scoped to a recorded enumeration that is itself probed, or replaced by a claim a stated procedure settles.
- 2026-08-14: re-cut criteria audit, round 1 ([O], fresh context) — 18 findings, no criterion clean. Eleven fixed here: AC5 gained a clean-worktree clause and a git-enumerated fixture domain (the hand list omitted `data/ratings.rda` and `data-raw/reviews/*.rds`); AC6 enumerates checkers by glob rather than by a count that drifted four to six to five-plus-one across three reviews; AC3 narrowed to the sourcing process and its forks and regained the return-1 case that pins `ckpt_mark_bypass()`; AC4 requires an observed non-zero exit rather than a workflow step existing; AC2 stopped quantifying over 'that site's checkpoint', which needs data-flow on a path built from `Sys.getenv()` and `sprintf()`; and the Goal's coverage promise was narrowed to what the criteria deliver. Three became gate questions.
- 2026-08-14: re-cut gate chose a declared-exemption channel over hashing a summary of unhashable dependencies and over the silent skip that shipped, because the compiled model object cannot be deparsed stably and the milestone's own Decisions entry forbids following data references into it; falsified by an exemption list growing to cover a determinant that could have been hashed.
- 2026-08-14: re-cut gate chose reachability as call-position closure plus a declared applier list over any-mention and over direct-calls-only, because any-mention reopens the parked-call hole and direct-calls-only goes vacuous on m111, whose `ckpt_read` is reached only through `mclapply(cells, run_cell)`; falsified by a handoff form outside the applier list appearing in a declared site. Liveness likewise allows only literally-true conditions plus declared entry-point idioms, m111's `sys.nframe() == 0L` being indistinguishable by parse from a disabling condition; falsified by an idiom entry admitting a condition that disables a guard call.
- 2026-08-14: re-cut gate chose one re-cut milestone over splitting the static check or the watcher out, because all three pieces need the same reachability machinery and splitting would duplicate it across two branches; falsified by the re-cut exceeding the sizing tripwires again.
- 2026-08-14: re-cut criteria audit, round 2 ([O], fresh context, over the amended wording) — all six still defective, and one counterexample was executed rather than argued: `load()` and `unserialize()` of a registered checkpoint return silently, so AC2's handoff to the watcher was false and AC3's 'plain-path read' universal was falsified by a call the watcher never traces. Adopted in full: AC2 names a required-minimum deserialization list and probes it by planting each name; AC3 is scoped to `readRDS` and gains the re-source case; AC1 is anchored on the static walk with the run-time rule pinned against it on a synthetic site, since four of five sites can never be run; AC4 quantifies per declared guard call, not per site, and probes the idiom list itself; AC5 uses a diff-based enumeration that also catches a deleted fixture; AC6 requires each checker's self-test status declared, `check-abort-remedy-verdicts.R` having been found to accept `--self-test` and exit 0 without having one.
- 2026-08-14: the round-2 audit's cross-cutting finding shaped every fix — a declared list that WEAKENS a check must not be expandable at will by the author whose recall already failed, so each such list is now tied to something checkable: exemptions empty unless a compiled-object determinant exists, the deserialization list carrying four required names, and the idiom list itself probed by a planted mutation.
- 2026-08-14: re-cut in-progress on the existing branch; T1 — the walk collects every symbol in a walked body, not only call heads, subtracts the function's own locals (formals, assignments, loop variables) so a shadowing local is not read as a dependency, and classifies each remaining site-defined symbol as hashed, declared parameter, declared value, or declared exemption, refusing to build a spec while any is unclassified.
- 2026-08-14: T1 — run against the five sites, the walk named exactly the class that had been silently uncovered: `single_est`, `average_est`, `pop_single`, `pop_average`, `spec_frep` on fixed-replicates; `inc`, `k_eff_ragged`, `spec_ow` on incomplete-oneway; `spec_sr` on incomplete-fixed-nested; `single_est`, `average_est`, `pop_single`, `pop_average` on multilevel-replicates. Each is now a declared value. `base_fit` is the only exemption, on the three sites that capture it, with its reason recorded in the TSV; the fourth passes it as an argument, so it is a formal there and never reaches the walk. m111 needs neither.
- 2026-08-14: T1 — three demonstrations added and the fix shown to discriminate: reverting the walk to call-heads-only reds the uncovered-determinant case and no other. A local shadowing a top-level binding is not reported (the false positive the first run surfaced on `out` in incomplete-oneway, which is both an output path at top level and a data frame inside `one_rep`).
- 2026-08-14: T2 — `data-raw/check-checkpoint-sites.R` gained the static counterpart of the guard's walk (top-level bindings, every symbol rather than call heads, locals subtracted, `f <- g` alias chains followed) and reports by name any determinant it reaches that is neither hashed nor declared; four of the five sites can never be run here, so this is the only walk that ever reaches them.
- 2026-08-14: T2 — the two walks are pinned on `data-raw/m120-synthetic-site.R`, which carries one instance of each class the walk must classify (captured value, captured function, shadowed local, exempted object, declared parameter): identical hashed-function sets and identical uncovered sets, both with the declarations in place and with them withdrawn. The pin discriminates — dropping the static walk's locals subtraction, and reverting it to call-heads-only, each red it, while the checker over the five real sites still exits 0 under the second.
- 2026-08-14: T2 — editing the captured determinant's argument, and editing the generator it is computed from, each change the block hash (the source is edited and re-sourced, which is the shape the shipped hole survived); a comment added inside the entry point does not. The checker's `--self-test` gained a per-site mutation that withdraws a declared determinant from the DECLARATION rather than from the script: 42 checks, no failures.
- 2026-08-14: T2 — that mutation surfaced a bound worth stating: `base_formula`, `base_prior`, `brm_args` and `cell_offset` are declared values no walk reaches, being referenced only at top level where the base fit is compiled. They are hashed all the same, but withdrawing their declaration is invisible to the check, and AC1 claims nothing about a determinant reached other than as a symbol in a walked body; the mutation is therefore aimed at one the walk does reach.
- 2026-08-14: T3 — the deserialization list lives in `checkpoint-sites.tsv` as a `#@deserializers` directive, and the checker refuses to run unless it contains the four names AC2 requires, so it cannot be quietly shortened to whatever the sites happen not to use. No site, and no file a site sources, calls any of them today.
- 2026-08-14: T3 — the check follows `source()` transitively and excludes only the guard; the self-test plants one live call of each declared name on every site (20 plants) plus one in `m76-classical-oneway-prototype.R`, which m111 sources, and each is detected. The self-test now copies the whole `data-raw` R tree into its tempdir, since a tree holding only the mutated file made every sourced file silently absent.
- 2026-08-14: T4 — the checker now asks whether a guard call is REACHED rather than whether its text is present: the walk starts at live top-level code, follows calls, and follows a function handed by name to a declared applier (m111's `ckpt_read` is reachable only through `mclapply(cells, run_cell)`). Checks 2–5 all moved onto reached calls; `calls_to()` survives only to say "the call is in the file, but parked".
- 2026-08-14: T4 — liveness admits a branch only under a literally-true condition or a declared idiom, so `if (0)`, `if (FALSE || FALSE)` and `if (getOption("x", FALSE))` all park a call rather than make it. The idiom list is two entries with their reasons in the TSV — `sys.nframe() == 0L` and `file.exists(ckpt)` — read off the sites' actual guard-call contexts rather than composed.
- 2026-08-14: T4 — the ordering check now compares execution position, not line number: m111 performs its output write and its assertion inside one `if (sys.nframe() == 0L)` expression, so both carried that block's line and a line comparison was blind on exactly the site whose assertion matters most. `parse_live()` now filters srcrefs together with the expressions, so dropping a dead top-level expression no longer shifts every later line number.
- 2026-08-14: T4 — a defect found by the self-test rather than by inspection: the first cut recorded every visited call as reached, liveness flag ignored, so all 18 `parked-false-cond` mutations passed undetected. The flag is now part of what "reached" means.
- 2026-08-14: T5 — the mutation forms are themselves declared (`#@mutations` in `checkpoint-sites.tsv`, ten forms with the reason each exists), and the self-test refuses to run unless the list holds the six AC4 requires, so the probe cannot shrink to the forms that happen to pass. 130 mutations planted over five sites, ten declared forms and every declared guard call; each detected, none reported as not applying.
- 2026-08-14: T5 — AC4's own procedure run on disk: parking `oracle-bayesian-incomplete-oneway.R`'s `ckpt_store_get()` in a function nothing calls makes `Rscript data-raw/check-checkpoint-sites.R` exit 1 naming the site and the reason, and restoring returns exit 0 with an empty diff. The `checkpoint-guard` job runs the demonstration, the check and its self-test as three steps, none `continue-on-error`.
- 2026-08-14: T6 — the trace's state environment is built once per PROCESS rather than once per `source()`, so re-sourcing the guard no longer discards every registration and orphans every recorded bypass. The re-source is not hypothetical: the demonstration sources the guard and then sources `m111-fallback-sweep.R`, which sources it again, and `rerun-oracle.R` runs several guarded scripts in one process.
- 2026-08-14: T7 — AC3's seventh case added: a swallowed bypass, then a second `source()` of the guard, then a bare read — registrations and the recorded bypass both survive, the read aborts, and the earlier bypass is still reported. Reverting the T6 fix alone reds exactly that case and nothing before it.
- 2026-08-14: T7 — the guard's header claimed a read is caught "whatever spelling it was written in", which is false; it now states the claim as `readRDS` with a path argument, and names the three things outside it — a connection-argument read, every other deserialization function (covered statically within the declared sites instead), and a process that did not fork from the one that sourced the guard.
- 2026-08-14: T8 (part) — `record-claims.tsv` gained `checker-self-test-status`, re-derived by `data-raw/record-claims-checker-self-tests.py`, pinning per checker whether it carries a `--self-test`. `check-abort-remedy-verdicts.R` is the one that does not: it parses no arguments, so it accepts the flag and exits 0 having planted nothing, which reads exactly like a self-test that passed. `data-raw/README.md`'s "sixth checker" framing was stale — two of the checkers are R, not one — and is corrected in the same commit.
- 2026-08-14: T8 (part) — [S] delegation: the four python checkers' self-tests now print one PASS line per planted mutation rather than a single summary line, so their coverage is counted rather than asserted. All four exit 0 plain and under `--self-test`; the diff is not yet reviewed by this session and the per-checker mutation counts are not yet reconciled against what each self-test plants.
- 2026-08-14: CHECKPOINT, work in hand: T1–T7 complete; T8 partly done as above; T9 (full gate, AC5 diff and re-declared file list) not started. `devtools::test()` was still running at this commit and its result is not yet recorded — the changed R files are all under `data-raw/`, which `.Rbuildignore` excludes, so the suite is expected unaffected, but that is an expectation and not an observation.
- 2026-08-14: T8 — the [S] delegation's diff was reviewed here: additive `else:` branches only, one per planted mutation, with every failure message, final summary line and exit path untouched. Two of the four print few lines because they plant few mutations (`check-oracle-registry.py` two, `check-reference-observations.py` one), which is what those self-tests actually do rather than a shortfall in the edit.
- 2026-08-14: T8 — AC5's fixture fence is now the diff-based enumeration the criterion states, run rather than eyeballed: `git diff --name-only main...HEAD` filtered to `*.rds`, `*.rda`, `*.RData`, `tests/testthat/_snaps/**` and `tests/testthat/fixtures/**` returns nothing, and `git status --porcelain` is empty.
- 2026-08-14: T9 — full local gate green on the final tree: `air format --check` clean, `lintr::lint_package()` no lints, `devtools::document()` leaves `NAMESPACE`/`man/` unchanged, `pkgdown::check_pkgdown()` no problems, `cairn_validate` all checks passed with no advisory, all six `data-raw` checkers exit 0 and the five with a self-test exit 0 under it, the routing check and its 130-mutation self-test exit 0, the guard demonstration exits 0 over 47 cases, and `m112-harness-demo.R` passes. The milestone's plan-owned body is 143/149 lines.
- 2026-08-14: AC5 declared file list, the whole of what this branch changes — 21 files: `.github/workflows/lint.yaml`, `cairn/ROADMAP.md`, `cairn/milestones/M120-checkpoint-staleness-guard.md`, `data-raw/README.md`, `data-raw/check-checkpoint-sites.R`, the four python checkers `check-mpl-doc-claims.py`, `check-oracle-registry.py`, `check-record-claims.py` and `check-reference-observations.py` (newly declared, for T8), `data-raw/checkpoint-guard.R`, `data-raw/checkpoint-sites.tsv`, `data-raw/m111-fallback-sweep.R`, `data-raw/m120-checkpoint-guard-demo.R`, `data-raw/m120-synthetic-site.R` (newly declared, for T2), the four `data-raw/oracle-bayesian-*.R` sites, `data-raw/record-claims-checker-self-tests.py` (newly declared, for T8), `data-raw/record-claims.tsv` and `data-raw/rerun-oracle.R`. Nothing under `tests/testthat/fixtures/`, `tests/testthat/_snaps/`, `R/sysdata.rda`, `data/`, or any `.rds` is touched, and the working tree is clean.
- 2026-08-14: CHECKPOINT — T9 stays unticked: every gate check above has been run and is green on the final tree EXCEPT `devtools::test()`, whose re-run on that tree was still in flight at this commit. The preceding run, on the tree at commit 1e6c965, was `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 7564 ]`, and every R file changed since is under `data-raw/`, which `.Rbuildignore` excludes from the build — but that is a reason to expect the result, not the result.
- 2026-08-14: T9 — the held-open gate check landed on the final tree: `devtools::test()` `[ FAIL 0 | WARN 3 | SKIP 2 | PASS 7564 ]`, exit 0. The gate is now green in full and the checkpoint line above is settled by observation rather than by the expectation it recorded. Status to review.
- 2026-08-14: audit finding 10 — the records-apparatus door needs a trigger in what the package computes; this milestone's deliverable guards numeric harness output, which that door's own carve-out leaves untouched ("guards that pin a NUMERIC result", "repairs to existing checkers surfaced as ordinary work"), and four of the five sites write committed oracle fixtures, so it is oracle discipline under #1 — no stale cache has yet produced a wrong shipped value, and the plan does not claim one.

## Decisions

### 2026-08-14: A multi-entry store file records which site wrote it, never a design spec

The four oracle sites checkpoint one file holding many entries. Until now that
file was stamped with a full design spec — necessarily *some* entry's spec, and
in the nested-fixed site literally cell 1's. Two costs, both realized: editing
one entry discarded every valid sibling (~720 Stan refits there), and the
file-level check always fired before the per-entry check could discriminate, so
the per-entry machinery was inert on all four sites and its only demonstration
ran on a stand-in.

Alternatives weighed: a file-level spec restricted to entry-invariant
parameters (on these sites nearly every parameter is invariant, so the file
check would still pre-empt the entry check), and dropping per-entry checking
altogether (whole-file staleness, the expensive-to-be-wrong option).

Chosen: the file records only its site name and a container format version, and
every design comparison happens per entry. The file-level check answers the one
question a file-level record can answer — is this cache ours — and `ckpt_store_load()`
refuses a foreign or non-store file on that basis alone.

Falsified by a staleness class that is genuinely a property of the file rather
than of any entry; the file record would then have to carry it.

### 2026-08-14: The generating-block hash covers declared values, not only function bodies

Four of the five sites have things that decide their cached numbers and are not
functions: the seed-offset vectors, the sampler argument lists, and the formula
and prior each base fit is compiled from. Hashing function bodies alone left all
of them able to change with every cache still considered current.

Alternative weighed: declare them as compared *parameters* instead, which gives
a by-name refusal message. Rejected because it makes the parameter lists carry
structured objects (a prior, a formula, a list of sampler settings) whose
equality is less predictable under `all.equal` than deparsed text is under a
hash, and because it splits one question — did the generating recipe change —
across two mechanisms.

Chosen: a declared block name may resolve to a function (its body is hashed) or
to any other object (its value is hashed), and the four oracle sites name their
formula, prior and sampler arguments so the guard can see them. Resolution stops
at the global environment, so a renamed block entry is "not found" rather than
silently resolving to a same-named function on the search path.

Falsified by a generator whose determinant cannot be deparsed stably, which
would need a value-specific digest rather than deparsed text.

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

## Re-review (2026-08-14, after return 1)

Second review pass, on `m120-checkpoint-staleness-guard` at PR #129. `main` is
level with origin and the branch is not behind it, so no merge preceded this
evidence. Every criterion below is re-executed from scratch; review 1's evidence
above is superseded for AC2 and AC4 and re-derived for the rest.

**AC1 — spec recorded, mismatch names the earliest differing entry.** Fresh run
of `Rscript data-raw/m120-checkpoint-guard-demo.R`, exit 0 over 28 passing
cases. A matching cache returns the cached payload; a changed `rho` and a
changed `dist` are each refused by name; with two parameters differing at once
the message names the earlier in declared order, shown both ways round (`dist`
before `base_seed`, `rho` before `dist`). `ckpt_spec()` refuses an empty
parameter list at construction, so the null guard AC1's last sentence forbids
cannot be built. New this pass: a declared block entry that is a value rather
than a function is hashed the same way and its change refused, and a declared
block name that no longer exists aborts as "not found" instead of resolving to
`stats::simulate`, the name two sites share.

**AC2 — no unguarded deserialization survives.** Same run. A guarded run passes
the trace; a bare `readRDS` and a `base::readRDS` of a registered checkpoint each
abort at the read; a read outside any registered location is not flagged. The two
failures review 1 found are gone and each is now demonstrated on the mechanism
that was missing:

- *A swallowed bypass after a legitimate read of the same path.* The demo now
  performs a guarded `ckpt_read()` first and does not reset the trace before the
  swallowed bare read, so the case reproduces a real run's ordering. It aborts.
  The pre-fix guard (`git show HEAD~2:data-raw/checkpoint-guard.R`, sourced
  standalone) was driven through that sequence — a guarded read, then a
  swallowed bare read of the same registered path, then the assertion — and
  reported nothing, so the defect is confirmed and the case discriminates.
- *A bare read inside a forked worker.* The demo plants a bare `readRDS` of a
  **valid** registered checkpoint (the spec check accepts that file, verified in
  the same script) inside `parallel::mclapply`, and the worker aborts with the
  bypass message while the sibling worker that read nothing is untouched.
  Isolated by mutation: suppressing the abort when the reading process is not
  the parent reds this case and no other in the script.

**AC3 — every planted-defect form.** Same run, each form on a cache the demo
writes itself: two parameters mismatching individually; a spec absent entirely; a
cache written by another site (refused naming `other-site`); a partially stale
multi-entry store (the current-design entry served, its superseded sibling
refused); and a generating-block hash differing with every parameter matching.
The partial-staleness form now runs through the guard's own store API rather than
a file-level spec, so the per-entry check is what serves and refuses. The
counterweight cases pass — a comment inside a block function, an edit to a
function outside the declared block, and restoring a changed declared value all
leave the cache usable. Clean resume is shown in the same script on the real M111
site.

**AC4 — the five sites route through the guard, and reverting one reds.**
`python3 data-raw/check-checkpoint-sites.py` exits 0 over the five declared
sites. Two reversions were planted on disk and each made it exit 1 naming the
site: replacing `oracle-bayesian-incomplete-oneway.R`'s per-entry
`ckpt_store_get()` with direct payload access while its file-level load stayed
("never calls ckpt_store_get()"), and commenting out the `source()` of the guard
in `m111-fallback-sweep.R` ("does not source data-raw/checkpoint-guard.R").
Both are the review-1 holes: an "any of these calls" test and raw-text matching.
Restoring returned exit 0 with an empty `git diff`. Its `--self-test` plants a
reversion per declared guard call plus two comment-outs on every one of the five
sites and confirms each is detected and each unmutated site passes. The CI job
runs both the check and the self-test as separate steps
(`.github/workflows/lint.yaml`), so either exiting 1 fails the job.

**AC5 — nothing outside the declared file list.** `git diff --name-only
main...HEAD` filtered for `tests/testthat/fixtures/`, `tests/testthat/_snaps/`,
`R/sysdata.rda` and `*.rds` returns nothing, and the working tree is clean. The
14 changed files are exactly the list the work log declares; the return added no
file.

**AC6 — verify slot and the toolchain gate.** `devtools::test()` `[ FAIL 0 |
WARN 3 | SKIP 2 | PASS 7564 ]`; `air format --check` exit 0;
`lintr::lint_package()` no lints; all six `data-raw` checkers and every self-test
exit 0. Toolchain gate: `devtools::document()` produces no diff under
`NAMESPACE`/`man/`; `pkgdown::check_pkgdown()` reports no problems;
`cairn_validate` exit 0 across all 24 checks. No NEWS entry is owed — every
changed R file is under `data-raw/`, which `.Rbuildignore` excludes from the
build, so nothing user-visible changed.

**`devtools::check()`** — 0 errors, 0 warnings, 1 NOTE locally. The NOTE is a
`spelling.Rout` / `spelling.Rout.save` comparison over words in `icc.Rd`,
`NEWS.md` and the vignettes — none of which this branch touches — and no
`.Rout.save` is tracked in the repo, so it is a local check-directory artifact.
The authoritative reading is CI on this exact commit
(`12bc2640f4f659cecd4bd7f236fa4a730c636f0b`), where `R CMD check` passes on both
ubuntu-latest and windows-latest.

**CI on PR #129** — every check green on the head commit: `R CMD check` on both
platforms, `test-coverage`, `check-references`, `checkpoint-guard`, `lint`,
`format-check`, `pkgdown` and both codecov legs.

### Independent review — three lenses, then a scorer (re-review)

The blame-history lens (Sonnet) and the prior-review lens (Sonnet) each reported
no findings: no regression of a prior milestone's intent, no contradiction of a
recorded decision or lesson, and no reintroduction of a point a past review
raised. Both independently confirmed the four oracle rewrites preserve iteration
order, seed derivation, base-fit compile-once placement, output positions and
fixture contents, and that each of review 1's eight actioned findings is fixed in
substance rather than moved. The diff-bug lens (Opus) reported 25 candidates,
scored by a fresh Sonnet scorer holding the diff, this file and the plan.

**Actioned (score >= 80), seven findings.** Three demonstrate an acceptance
criterion failing as written and force the return; four are severe verified gaps
that no criterion's literal text reaches.

- **D7 (92, AC4 fails).** The routing checker tests only that a required token
  appears somewhere in the file. Three reversions of a site's guard call were
  verified undetected: moving `ckpt_trace_assert()` from its pre-write position
  to end of file (the checker's own message says "before writing output", but
  position is never checked); `ckpt_trace_register(ckpt` → `ckpt_trace_register(NULL`
  on all five sites; and replacing a live `ckpt_store_get(...)` with direct
  payload access while a dead `if (FALSE) { ckpt_store_get(a, b, c) }` remains.
  The third is a live reproduction of the F15 class this return claimed to close.
- **D3 (90, AC2 fails).** `normalizePath(..., mustWork = FALSE)` returns a
  non-existent path unchanged and an existing one as an absolute path, so a
  checkpoint registered before it exists is never matched by
  `ckpt_under_registered()`. All four oracle sites register before the store
  file exists. Verified: register a relative non-existent path, create it, then
  bare-`readRDS` it — no abort, and `ckpt_trace_assert()` passes.
- **D13 (90, AC2 fails).** `ckpt_trace_state$bypassed` is per-process and dies
  with a fork, so a bare read whose abort a worker swallows with `tryCatch` is
  invisible to the parent's assertion. Reproduced under `mclapply`. The guard's
  own comment — that the end-of-run assertion is retained for a swallowed
  bypass — is true only outside a fork.
- **D2 (87).** The guard is sourced with `source()`'s default `local = FALSE`,
  so its functions land in `globalenv()` and their internal `saveRDS`/`readRDS`
  resolve to base — bypassing the `readRDS`/`saveRDS`/`file.exists` shadowing
  `data-raw/rerun-oracle.R` installs in its `run_env`. Verified the shadow is
  never called. A "fresh" re-run now writes the real on-disk checkpoint, which
  is what that shadowing exists to prevent.
- **D10 (85).** `n_rep` is a compared parameter of every per-entry spec, but each
  rep's payload depends only on its seed, so raising `n_rep` refuses every
  cached rep. The most common edit to these scripts still pays the mass-discard
  cost the store decision above says it eliminated.
- **D5 (82).** Five site comments state that sourcing the guard installs the
  trace. It does not — every site calls `ckpt_trace_install()` explicitly, and
  the milestone's own work log records self-install as the chosen design over
  the per-harness opt-in that shipped.
- **D11 (82).** m111's declared block omits `searle_f_ci_balanced()` and
  `burch_reml_ci_balanced()`, both called by `one_rep()` and both determining
  cached rows. F4 was actioned on the four oracle sites only; m111 has the same
  gap.

**Logged below the action bar (score < 80), 18 findings** — surfaced, not
dropped: D1 install-removal undetected by the checker (78); D14 `all.equal`
tolerance accepts a small-variance change (74); D18 the partial-staleness form
is still demonstrated only on a stand-in site (72); D4 a pre-install alias is
untraced (68); D12 the "M111 sweep end to end" claim overstates a one-cell run
(62); D17 `in_guard` exempts a lazily-forced argument (55); D23 the AC6 checkbox
was unticked despite its evidence — fixed in this pass (55); D16 the trace is
never removed and registrations accumulate (52); D24 `m112-harness-demo.R` was
not in the gate list, though it passes when run (52); D9 nothing pins the site
count (45); D8 the bare-read regex is anchored to the name `ckpt` (42); D19
`ckpt_store_get` conflates absent with NULL payload (38); D21 `strip_comments`
resets quote state per line, failing safe (35); D15 reordering `params` reports a
misleading message (32); D25 the multilevel site declares `designs` rather than a
`base_formula` (30); D22 the spec-block regex is coupled to air's indentation
(28); D20 mismatch messages elide values longer than four (22); D6 the false fork
claim is left standing (15) — scored false, the correction below already stands.

### Return (second defect return)

AC2 and AC4 fail again and are unticked; AC1, AC3, AC5 and AC6 keep the evidence
recorded above. D3 and D13 fail AC2 — a checkpoint registered before it exists is
never watched, and a swallowed bypass inside a forked worker reaches no
assertion. D7 fails AC4 — the routing checker's token test misses three
reversions of a site's guard call, one of them the F15 class. D2, D10, D5 and D11
are actioned in the same pass.

**Thrash rule (return 2).** This is defect return 2 of this milestone; the third-return
threshold has not been reached. Trigger (b) has fired, on both criteria: AC2
failed in review 1 (F1, F25) and fails here (D3, D13), and AC4 failed in review 1
(F14, F15) and fails here (D7) — each time by a new mechanism of the same shape,
a hole in a scenario nobody demonstrated and a text match that admits a mutation
it cannot see. The remedy is to reconsider the alternatives the plan gate
recorded against, both of which the work log names with their falsifiers: the
run-time trace was chosen over a source scan, falsified by "a checkpoint read the
trace cannot observe" (D3, D13, D4 are three), and the narrow generating-block
hash was chosen over a whole-file fingerprint, falsified by "a generator change
the declared block does not cover" (D11). Both falsifiers have now fired.

**Correction to review 1's record.** Review 1's AC2 paragraph above states that
the fork case was "exercised directly" by an unspecced `cell-02.rds`. That claim
was false — the planted file aborts through the spec check, not the trace — and
its own work-log line said it had been corrected in the Review section when the
section had not been touched. It is superseded here rather than edited: the fork
evidence AC2 rests on is the bare-read-inside-a-worker case recorded in this
block, and the unspecced-cell case stands only as evidence that the spec check
also reaches inside a worker.

## Third review (2026-08-14, after return 2)

Third pass, on `m120-checkpoint-staleness-guard` at PR #129. `main` is level with
origin and the branch not behind it, so no merge preceded this evidence. Every
criterion is re-executed from scratch against the redesigned guard; the evidence
above is superseded wherever it disagrees.

**AC1 — spec recorded, mismatch names the earliest differing entry.** Fresh run
of `Rscript data-raw/m120-checkpoint-guard-demo.R`, exit 0 over 34 passing cases.
A matching cache returns its payload; a changed `rho` and a changed `dist` are
each refused by name; with two differing at once the message names the earlier in
declared order, shown both ways round. `ckpt_spec()` still refuses an empty
parameter list at construction. New this pass: the generating block is derived
rather than listed, and the demo shows an undeclared helper — reached only
through the declared entry point — invalidating a cache when it is edited, while
a comment inside a block function, an edit to a function outside the closure, and
a restored declared value all leave the cache usable.

**AC2 — no unguarded deserialization survives.** Same run. Each of the three
reads that defeated the trace at return 2 now has its own case, and each case was
verified to red when its own fix alone is reverted, and no other case with it:

- *A relative path registered before it exists* (the first-run case on all four
  oracle sites). Rooted outside any already-registered directory, because the
  first version of this case passed for the wrong reason — the enclosing tempdir
  was itself registered. Reverting the path resolver to plain `normalizePath()`
  reds exactly this case.
- *A bypass swallowed inside a forked worker.* The worker catches its own abort
  and returns an ordinary value; the parent's assertion still reports the bypass,
  read from the on-disk markers. Making the assertion read memory instead reds
  exactly this case.
- *An alias to `readRDS` bound by the caller*, bound at the top of the demo
  before any install call it makes. Removing the guard's source-time install reds
  exactly this case.

The earlier cases still hold: a guarded run passes; bare and `base::`-qualified
reads abort at the read; a swallowed bypass after a legitimate guarded read of
the same path is still reported; a read outside any registered location is not
flagged; and a bare read inside a forked worker, on a checkpoint the spec check
would have accepted, aborts in that worker.

**AC3 — every planted-defect form.** Same run, each on a cache the demo writes
itself: two parameters mismatching individually; a spec absent entirely; a cache
written by another site; a partially stale multi-entry store served and refused
entry by entry through the store API; and a generating-block hash differing with
every parameter matching. Clean resume is shown on the real M111 site, which
computes a cell, resumes it, and then refuses it after `rho` is edited.

**AC4 — the five sites route through the guard, and reverting one reds.**
`Rscript data-raw/check-checkpoint-sites.R` exits 0 over the five declared sites.
AC4's own procedure was run on a site neither earlier pass had reverted:
replacing `oracle-bayesian-multilevel-replicates.R`'s per-entry
`ckpt_store_get()` with direct payload access makes it exit 1 naming that file,
and restoring returns exit 0 with an empty `git diff`. Its `--self-test` plants,
on every one of the five sites, the three reversions that walked past the retired
text-matching checker — an assertion moved after the output write, a
`ckpt_trace_register(NULL)`, and every live call replaced while a dead
`if (FALSE)` copy remains — plus a commented-out `source()` and one reversion per
declared guard call: 38 checks, no failures. The retired Python checker was
re-run on the dead-copy mutation and exits 0, so the replacement's advantage is
measured rather than asserted. In CI the `checkpoint-guard` job runs the
demonstration, the routing check and its self-test as three steps, so any of them
exiting 1 fails the job; that job passes on this commit.

**AC5 — nothing outside the declared file list.** `git diff --name-only
main...HEAD` filtered for `tests/testthat/fixtures/`, `tests/testthat/_snaps/`,
`R/sysdata.rda` and `*.rds` returns nothing, and the working tree is clean. The
15 changed files are the list the work log declares, which this round turned over
two entries of: `check-checkpoint-sites.py` retired for
`check-checkpoint-sites.R`, and `rerun-oracle.R` newly declared.

**AC6 — verify slot and the toolchain gate.** `devtools::test()` `[ FAIL 0 |
WARN 3 | SKIP 2 | PASS 7564 ]`; `air format --check` exit 0;
`lintr::lint_package()` no lints; the five python `data-raw` checkers and
`check-record-claims.py` exit 0, and `m112-harness-demo.R` — which drives the
changed `run_cell` read/write path — passes. Toolchain gate:
`devtools::document()` produces no diff, `pkgdown::check_pkgdown()` reports no
problems, `cairn_validate` passes every check with one advisory (the 13-task
split tripwire, answered in the work log).

**CI on PR #129** — every check green on the code commit `7a6f063`:
`R CMD check` on ubuntu-latest and windows-latest, `test-coverage`,
`check-references`, `checkpoint-guard`, `lint`, `format-check`, `pkgdown` and
both codecov legs.

### Independent review — three lenses, then a scorer (third pass)

The blame-history lens (Sonnet) and the prior-review lens (Sonnet) each reported
no defect. Both confirmed the four oracle rewrites still preserve iteration
order, seed derivation, base-fit compile-once placement, output positions and
fixture contents; that `rerun-oracle.R`'s pre-existing shadowing is untouched and
the path redirection is additive; that dropping `n_rep` is sound on the three
per-rep sites and correctly retained on the per-cell one; and that all eight
review-1 findings and all three review-2 criterion failures are fixed at their
stated mechanism rather than moved. The diff-bug lens (Opus) reported 25
candidates, every one verified by running code, scored by a fresh Sonnet scorer
holding the diff, this file and the plan.

**Actioned (score >= 80), five findings — all five fail a criterion.**

- **E1 (95, AC4 fails).** The routing checker's "live call" test is defeated by
  parking the call in a function nobody calls: `calls_to()` finds a call anywhere
  in the parsed source and `drop_dead()` removes only `if (FALSE)` branches, but
  a function *definition* is live code. Three mutations on real sites each
  returned zero failures — a bare `readRDS(ckpt)` in `m111` with `ckpt_read`
  parked in an unused helper; `oracle-bayesian-incomplete-oneway.R`'s per-entry
  `ckpt_store_get()` replaced by direct payload access with the call parked; and
  `ckpt_trace_assert()` replaced by `invisible(TRUE)` with the call parked
  earlier in the file, which also passes the ordering check.
- **E4 (90, AC1 fails).** The derived block misses any determinant reached by
  variable capture rather than by a call. `ckpt_called_names()` collects only
  names in call position, so `single_est <- est_occ("single")` at top level,
  referenced inside `one_rep()`, is invisible: `est_occ` is outside the closure
  on two oracle sites and `kc_of` on a third. Editing `est_occ()` from
  `type = "agreement"` to `"consistency"` leaves the block hash byte-identical,
  every parameter matching, and the committed oracle fixture written from rows
  computed under the old estimand. This is review 1's actioned F4 silently
  reintroduced by T10.
- **E3 (88, AC2 fails).** Sourcing the guard a second time re-executes
  `ckpt_trace_state <- new.env(...)` and re-installs, wiping every registration
  and orphaning every recorded bypass. The re-source is not hypothetical: the
  demo sources the guard, then sources `m111-fallback-sweep.R`, which sources the
  guard again — the demo survives only because it re-registers immediately
  afterwards, and `rerun-oracle.R` runs several guarded scripts in one process.
- **E2 (85, AC2 fails).** A connection-argument read is not traced at all:
  `ckpt_trace_note()` returns early unless the argument is a length-one
  character, so `readRDS(gzfile(p))` on a registered checkpoint returns its
  payload silently and the assertion stays clean. The guard's own header claims
  a read is caught "whatever spelling it was written in"; that is false.
- **E15 (85, AC4 fails).** `drop_dead()` recognizes only literal `TRUE`/`FALSE`,
  so a guard call parked under `if (0)`, `if (FALSE || FALSE)` or
  `if (getOption("x", FALSE))` counts as live — a cheaper variant of E1,
  verified separately.

**Logged below the action bar (score < 80), 15 findings** — surfaced, not
dropped: E5 the checker never checks a declared parameter is bound to the site's
design object, so `rho = 0.05` passes (78); E10 AC4's text says "the CI job that
already runs the repo's standalone `data-raw` checkers" but T9 moved the routing
check into the new `checkpoint-guard` job (68); E11 a registration normalizing to
`NA` makes the next unrelated `readRDS` abort (65); E16 AC3's partial-staleness
form is still shown only on a stand-in site (60); BH2 `rerun-oracle.R` re-sources
the guard once per script in one process (58); E7 m111 registers only under
`sys.nframe() == 0L`, so a sourced-harness path is unwatched (55); E9 the demo
still cites the retired `.py` checker (52); E17 the CI job installs the full
Suggests closure (48); E12 `in_guard` exempts a lazily-forced argument and does
not restore (45); BH1 `M111_CKPT_DIR` in `rerun-oracle.R`'s redirection is inert
(45); E6 `line_of()` misattributes lines when a dead top-level expression is
filtered, a wrong diagnostic rather than a false pass (42); E8 the marker-file
comment claims hash naming and one file per path, neither true (42); E13
`ckpt_store_get` conflates absent with NULL payload (38); E14 `ckpt_store_has()`
is dead code (35); E18 the trace stats the filesystem on every `readRDS` (32).

### Return (third defect return)

AC1, AC2 and AC4 fail and are unticked; AC3, AC5 and AC6 keep the evidence
recorded above. E1 and E15 fail AC4, E3 and E2 fail AC2, E4 fails AC1.

The scorer was asked, per finding, whether the failure lands inside or outside
the domain of the procedure the criterion names as its own evidence. E1 is
inside AC4's — AC4's procedure is reverting a site's guard call and observing the
job red, and E1 reverts a site's guard call. E3 is inside AC2's, the re-source it
exploits happening within the AC3 run itself and masked only by a local
workaround. So this is a defect return, not a criterion amendment. E2 and E4
fall outside their criteria's named procedures and are actioned as defects
without changing that disposition.

**Correction to a work-log claim.** The return-1 work log states that the four
oracle sites "now name their base formula, prior and sampler arguments (and their
seed offsets, `est_occ` and `kc_of`) and declare them in the block." That was
true when written and was falsified by T10, which replaced the hand-listed block
with a derived closure and dropped `est_occ` and `kc_of` without saying so; E4 is
the consequence. The work log is history and is not edited — the claim is
superseded here.

**Thrash rule (return 3).** The third-return threshold is reached, and once
reached it holds: no further retry is queued under the current plan. Trigger (b)
has also fired again — AC2 has now failed in all three reviews (F1/F25, then
D3/D13, now E3/E2) and AC4 in all three (F14/F15, then D7, now E1/E15), each time
by a new mechanism of the same shape: a read the watcher cannot see, and a
routing check whose test admits a form nobody thought of. Both alternatives the
plan gate recorded against have now been tried — the source scan was rejected at
plan time, and the parse-the-source checker that replaced the text match is what
E1 and E15 defeat. No recorded alternative remains to fall back on, which is the
condition under which the rule offers escalation.
