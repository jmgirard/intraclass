# M141: The `n_o` disposition grid is pinned, and the fixed-rater replicate abort names the right condition

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7, GP8, #5, #8
- **Branch/PR:** `m141-n-o-disposition-grid`

## Goal

Put every disposition of `icc()`'s within-cell-replicate dispatch under a
standing grid test, and correct the two records that misstate it — one abort
message, one `DECISIONS.md` clause.

## Scope

Surface tier: **user-facing** — the deliverable includes an abort message users
read at runtime, so D-029 places it outside D-021's records-apparatus door.

**In:** a grid test over `glance()$n_o` and the aborts of the dispatch block at
`R/icc.R:1393-1474`; a mechanical check that the grid covers every abort branch
in that block; the reworded fixed-rater abort at `R/icc.R:1459-1465`; a
`DECISIONS.md` entry superseding D-038 clause 2.

**Out:** what `glance()$raters` and `type` should report on a multilevel Design 3
fit → the standing candidate row on that pair. The numeric disagreement between
`tidy()$occasions` and `glance()$n_o` → its own standing candidate row. A NEWS
entry for the reworded abort → not needed, the message is new in the unreleased
0.1.0. Widening any abort's support, rather than its wording → unchanged here.

## Acceptance criteria

- [ ] AC1 — `tests/testthat/test-n-o-disposition-grid.R` builds its cases with
      `expand.grid()` over the axes it names in place (`multilevel`,
      `ml_design`, `raters`, whether `level` includes `"conflated"`, and the
      replicate shape: uniform-and-complete / unequal counts / a cell the
      design defines but the data omits), every unnamed `icc()` argument held
      at its default, never as a hand-written row list (GP8). The rule stated
      beside the call drops the rows on which an axis does not apply: without
      a `cluster` column an `ml_design` or a `"conflated"` level has no
      argument to ride on, so such a row's call is identical to the plain
      single-level row's and is not a distinct case (the refusals those
      arguments would draw, `R/icc.R:944-956`, are pre-dispatch and out of
      scope). A nested `ml_design` with `"conflated"` is not dropped: it
      reaches `icc()` and is refused at the fixed-rater guard (`R/icc.R:1204`)
      or the non-crossed guard (`R/icc.R:1212`), so the grid carries it.
      Each generated case is joined to its expectation by its axis values,
      never by row position, and the file asserts the generated set and the
      expectation set differ in neither direction, so an added axis value
      fails loudly rather than re-aligning silently. Every surviving case
      declares the exact disposition it expects —
      `expect_identical(glance(fit)$n_o, <int>)`,
      `expect_identical(glance(fit)$n_o, NA_integer_)`, or an abort identified
      by a message substring, never by a condition class alone, since guards
      outside the dispatch abort with the same class (`R/icc.R:1232`) —
      together with the conditions raised ahead of it, captured and compared
      as a whole set rather than asserted uniformly. Every case's assertion
      passes.
- [ ] AC2 — the same file asserts that the number of distinct dispatch branches
      its abort cases identify equals the number of `abort_*()` calls inside
      the within-cell-replicate dispatch block, the calls matched by a pattern
      admitting any `abort_` helper (not `abort_unsupported(` alone) and the
      block located by anchoring on its own code strings within
      `deparse(body(icc))`, never by reading `R/icc.R` from disk, which is
      absent under `R CMD check`. Two probes turn the assertion red:
      temporarily adding a sixth `abort_unsupported()` call inside the block,
      and adding one raised through a different helper.
- [ ] AC3 — five planted defects, applied and reverted one at a time, each
      turning a NAMED grid case red: (i) `R/design.R:49`, drop
      `n_cells == ns * nr` — a single-level random missing-cell case reports a
      number where it must report `NA`; (ii) `R/design.R:50`, drop
      `length(unique(as.integer(observed))) == 1L` — a single-level random
      ragged case reports a number; (iii) `R/design.R:51`, return
      `length(observed)` instead of `observed[[1L]]` — a reported-value case
      reports the wrong count; (iv) `R/design.R:215-228`, force
      `multilevel_replicate_facts()`'s `complete` to `TRUE` — a multilevel
      incomplete replicate case fits where it must abort; (v) `R/icc.R:1456`,
      restrict the fixed-rater guard to unequal counts alone — the fixed-rater
      missing-cell case fits where it must abort. (i) and (ii) are separable
      only if the grid's unequal-counts case keeps a full cell grid and its
      missing-cell case keeps equal counts in the cells it has; both cases are
      built that way.
- [ ] AC4 — the fixed-rater abort at `R/icc.R:1459-1465` opens "Ragged or
      incomplete within-cell replicates are not supported for fixed raters
      yet.", mirroring the multilevel sibling at `R/icc.R:1436-1443`, and its
      two `i =` hints are reworded so the deferral clause and the remedy
      clause each cover the missing-cell shape as well as the unequal-count
      one. All three bullets of the rendered message are pinned by substring
      against the real abort, rendered with `cli::cli_fmt()` /
      `format_message()` (M93 lesson), on both a ragged fixed-rater design and
      a missing-cell fixed-rater design. (RB tripwire: ip-touching)
- [ ] AC5 — `cairn/DECISIONS.md` gains an entry superseding D-038 clause 2's
      under-statement that `n_o` is "`NA` on a ragged replicate design as well
      as on an unreplicated one": it is `NA` on a design missing a cell it
      defines too. The entry states the condition `replicates_uniform`
      (`R/design.R:48-50`) and `multilevel_replicate_facts()`
      (`R/design.R:215-228`) guarantee, and names
      `tests/testthat/test-n-o-disposition-grid.R` as the grid's home.
      D-038 is not edited.
- [ ] AC6 — `Rscript -e 'devtools::test()'` reports `FAIL 0` and no warning whose
      rendered message text is absent from the set the same `devtools::test()`
      invocation reports at this milestone's merge-base, both runs made in this
      session and both sets recorded in the work log. `Rscript -e
      'devtools::check()'` reports 0 errors and 0 warnings on `R CMD check`'s own
      `Status:` line, and any NOTE it reports is justified in the Review section.

## Coverage

- AC1 → T1, T2, T2b
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7

## Tasks

- [x] T1 — Measure the whole grid before asserting any of it (M140 lesson):
      build a fixture per replicate shape, run every feasible axis combination,
      and record the observed disposition per case — reported value, or the
      abort's opening line — in the work log. The measurement decides the
      expectations; nothing is predicted from reading the branches.
- [x] T2 — Write `tests/testthat/test-n-o-disposition-grid.R`: the
      `expand.grid()` call, the stated infeasibility rule, the per-shape
      fixture constructors, and one assertion block per case carrying its exact
      value or message substring and its expected condition stream.
      `devtools::test()` clean.
- [x] T2b — Probe the condition-stream comparison: temporarily raise an extra
      `cli::cli_inform()` ahead of the dispatch, record in the work log which
      named case reddens, and revert.
- [x] T3 — Add AC2's branch-count assertion over `deparse(body(icc))`; run both
      probes, one temporary `abort_unsupported()` and one raised through a
      different `abort_` helper, and record each red in the work log before
      reverting.
- [x] T4 — Apply AC3's five planted defects one at a time, each reverted before
      the next; record which named case went red for each, verbatim, in the
      work log.
- [x] T5 — Reword the abort at `R/icc.R:1459-1465` and the block comments at
      `R/icc.R:1447-1458` that carry the same ragged/missing-cell conflation;
      add the three-bullet rendered-message pins for both fixed-rater shapes.
      (RB tripwire: ip-touching)
- [x] T6 — Append the superseding entry to `cairn/DECISIONS.md`.
- [x] T7 — Gate: `devtools::document()` produces no diff; every `data-raw/`
      checker run with `--self-test` (M130 lesson — a tracking edit re-keys
      them); `R CMD check`'s raw `Status:` line read and transcribed into the
      Review section, with any NOTE and its justification recorded there.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: plan-gate criteria audit ran in FULL mode (declared surface tier user-facing), two [O] passes over the drafted wording. Pass 1 returned findings on five of six criteria: a `covr` 100%-line gate conflicting with PRINCIPLES.md #11 and enumerating a proxy range, a self-satisfying "a row per design shape", two probes sharing one location and one mutation form, a hand-pinned grid duplicated into `DECISIONS.md` against GP8, and an undefined "clean". Pass 2 over the repaired wording returned six more: a condition stream false for the multilevel-fixed-conflated case, abort cases identified by class alone that pre-dispatch guards also satisfy, a branch-count equality that cannot hold row-for-row, a probe blind to a differently-named `abort_` helper, a `readLines("R/icc.R")` implementation that errors under `R CMD check`, and two wrong line ranges. All disposed at the gate; one finding — whether the grid carries a mechanical completeness check at all — went to the question gate and became AC2.
- 2026-08-27: plan gate chose a mechanical abort-branch count over a snapshot grid because a later-added branch would otherwise ship unpinned, the shape the standing merDeriv-guard candidate row records as recurring; falsified by a branch-count assertion reddening on a change that adds no new disposition.
- 2026-08-27: plan gate chose mirroring the multilevel sibling's "Ragged or incomplete" wording over a condition-first rewrite because the two aborts guard the same condition and should read alike; falsified by a user reading the shared phrase as naming only the ragged shape.
- 2026-08-27: branch `m141-n-o-disposition-grid` cut from `main`; status in-progress.
- 2026-08-27: T1 measured the whole grid by executing `icc()`, nothing predicted from reading branches. 42 grammatical combinations, not the 30 the plan implied: 36 multilevel (3 `ml_design` x 2 `raters` x 2 conflated x 3 replicate shapes) + 6 single-level (2 `raters` x 3 shapes). Dispositions: `n_o = 2L` on the four uniform-and-complete fitting cases (single-level random/fixed, multilevel crossed and nested_in_clusters random, plain levels); `NA_integer_` on the single-level random ragged and missing-cell cases; the other 36 abort, across seven distinct messages. The measurement is transcribed into the grid test as its expectations.
- 2026-08-27: T1 measurement falsified two AC1 clauses. Nested `ml_design` with `"conflated"` is not overridden to `"subject"` at `R/icc.R:1291` as AC1 stated — it never reaches there, aborting at `R/icc.R:1204` (fixed) or `R/icc.R:1212` (random). And the conditions raised ahead of a disposition come from two sites, not the one `R/icc.R:1042` advisory AC1 named: the Design 3 consistency-drop `cli_inform()` at `R/icc.R:1308-1312` fires on every nested_in_subjects random case.
- 2026-08-27: amendment (substantive, mini gate, user selected): AC1 rewritten. The infeasibility clause and its false justification are replaced by a drop rule covering only the single-level rows whose `ml_design`/`"conflated"` value has no argument to ride on; nested-with-conflated joins the grid (30 cases -> 42); the condition stream is compared as a whole set instead of derived from one named advisory rule; expectations are keyed to each case's axis values with set equality asserted in both directions. Criteria set widened by no new criterion; AC1's promise domain grew from 30 cases to 42 and its GP8 clause from construction to lookup.
- 2026-08-27: criteria audit ran in FULL mode (surface tier user-facing) over the amended AC1, two [O] fresh-reader passes, neither reader the author. Pass 1 returned four findings: the exclusion clause's justification false, a hand-pinned two-site condition-stream enumeration against GP8, an instrument-vs-deliverable question on "every case's assertion passes", and a citation off by one (`R/icc.R:1211` is a closing brace; the guard is 1212). Pass 1's own proposed replacement rationale was itself falsified by execution — `icc()` does not silently ignore `design=`/`level=` without a `cluster`, it aborts at `R/icc.R:944-956`. Pass 2 over the repaired wording returned three more: the drop rationale a non sequitur, an untested sensitivity claim, and positional expectations defeating the generated grid. Instrument finding disposed as no-change (the grid test is this milestone's deliverable, and AC3's plants falsify the recorded behaviour); the sensitivity claim disposed at the user's selection as a task (T2b), not a criterion; the rest fixed in the amended text.
- 2026-08-27: T2b added to Tasks and to AC1's Coverage row — the condition-stream comparison is probed by a temporary extra `cli_inform()`, so the check is shown able to fail without widening the criteria set.
- 2026-08-27: checkpoint (T2, T6 written, neither checked off). `tests/testthat/test-n-o-disposition-grid.R` written and passing on its own file (42 cases, 179 expectations); `cairn/DECISIONS.md` gained D-041. Two fixture defects found and fixed during T2: the fixed-rater advisory and the Design 3 consistency-drop inform were pinned on invented substrings, and the first multilevel fixtures carried no cluster, rater or interaction variance, so the nested_in_clusters uniform case died in the Monte-Carlo interval (`intraclass_singular_fit`, 49% non-finite draws) instead of fitting. Both fixtures now draw all five components and seed from their own arguments, so a case's data does not depend on the order the grid is walked. T2/T6 stay unchecked until the full `devtools::test()` run completes — it was still running at the checkpoint.
- 2026-08-27: full `devtools::test()` after T2: `FAIL 0 | WARN 3 | SKIP 2 | PASS 9077`. All three warnings are fixed-rater advisories leaking from unwrapped `icc(raters = "fixed", ...)` calls in `tests/testthat/test-icc-brms.R` (last touched at M48), none from this branch; AC6's 0-warnings clause is carried to T7 with the exact sites in hand. T2 and T6 checked off.
- 2026-08-27: T2b probe — a temporary `cli::cli_inform()` raised immediately ahead of `if (design_info$has_replicates)` reddened the named case `single/random/uniform` on the condition-set comparison (expected 0 conditions, got 1: "M141 T2b probe: a stray condition ahead of the dispatch."). Reverted.
- 2026-08-27: T3 — the branch-count assertion locates the dispatch block in `deparse(body(icc))` between the trimmed lines `if (design_info$has_replicates) {` and the first following `replicates <- TRUE`, never by reading `R/icc.R` from disk, and counts 5 `abort_` calls against the 5 distinct branches the grid's abort cases name. Both probes red at 5 vs 6: a sixth `abort_unsupported()` inside the block, and one raised through `abort_unidentified()`. Reverted.
- 2026-08-27: T4 — five planted defects, applied and reverted one at a time, each reddening a named case. (i) drop `n_cells == ns * nr`: `single/random/missing_cell` reports a number where it must report `NA`. (ii) drop the equal-counts clause: `single/random/ragged` reports a number. (iii) return `length(observed)`: `single/random/uniform` and `single/fixed/uniform` report the wrong count. (iv) force `multilevel_replicate_facts()`'s `complete` to `TRUE`: `ml/crossed/random/plain/missing_cell` fits where it must abort. (v) restrict the fixed-rater guard to unequal counts alone: `single/fixed/missing_cell` fits where it must abort. (i) and (ii) reddened different named cases, so the two clauses of `replicates_uniform` are separably pinned.
- 2026-08-27: T5 — the fixed-rater replicate abort now opens "Ragged or incomplete within-cell replicates are not supported for fixed raters yet.", the same phrase its multilevel sibling opens with, and both `i =` hints name the missing-cell shape beside the unequal-count one. The block comment above it, which called the corner "Ragged x fixed" and the shipped scope "BALANCED only", now says ragged-or-incomplete and balanced-and-complete, and points at the guard `!replicates_uniform` it describes. All three rendered bullets are pinned by substring on both a ragged and a missing-cell fixed-rater design, plus the shared opener against the multilevel sibling; reverting `R/icc.R` to the pre-M141 message turns all three bullet pins red on both shapes.
- 2026-08-27: T7 (partial) — `devtools::document()` produces no diff. All six `data-raw/` checkers pass `--self-test`: `check-abort-remedy-verdicts.R` (52 cells, 24 accepted, 0 broken promises), `check-checkpoint-sites.R` (130 mutations over 5 sites and 10 declared forms, each detected), `check-mpl-doc-claims.py`, `check-oracle-registry.py`, `check-record-claims.py`, `check-reference-observations.py`. `Rscript -e 'devtools::check()'` raw `Status:` line: `Status: OK` — 0 errors, 0 warnings, 0 notes, duration 14m 1.1s. No NOTE to justify.
- 2026-08-27: SUPERSEDES the T2 work-log line above that read "All three warnings are fixed-rater advisories leaking from unwrapped `icc(raters = "fixed", ...)` calls in `tests/testthat/test-icc-brms.R` ... none from this branch". That line is false on both counts and its "none from this branch" rested on no measurement. The full captured run puts the three in three different files: `test-icc-lavaan-multilevel.R:402` (lavaan reporting negative latent variances, escaping an `expect_error()` that asserts a different class), `test-icc-type-vector.R:286` (glmmTMB reporting a non-positive-definite Hessian, escaping an `expect_message()`), and `test-icc-brms.R:2425` (the fixed-rater advisory, from an unwrapped `icc()` call at 2430-2439 — the reporter attributes it to 2425). Only the third is a fixed-rater advisory. Whether the set predates the branch is being measured, not inferred: a `devtools::test()` run at the merge-base in a separate git worktree.
- 2026-08-27: amendment (substantive, mini gate, user selected): AC6 narrowed. It promised 0 warnings, which the suite does not deliver and which this milestone's diff (`R/icc.R` plus one new test file) does not control. It now promises `FAIL 0` and no warning whose rendered message text is absent from the merge-base set, both sets measured this session and recorded here. The criteria set gains no criterion; AC6's promise domain narrows from every warning to the warnings this branch adds, and picks up the NOTE-justification half of the profile's full-check slot, which the original omitted.
- 2026-08-27: criteria audit ran in FULL mode over the amended AC6, two [O] fresh-reader passes, neither reader the author. Pass 1 returned four findings: "the three that predate this branch" quantified over a set no named procedure enumerated; the criterion pinned testthat srcref line numbers, which are reporter attribution artifacts rather than deliverable properties; a shared causal clause ("each reaching the reporter because its test asserts a different condition") false for the brms warning, which comes from an unwrapped call; and the stale T2 work-log line, superseded above. Pass 2 confirmed the first three resolved and returned three more, all fixed in the accepted text: no stated identity relation for two warnings being "the same" (now rendered message text), "the same suite" false at the merge-base since this branch adds a test file (now the same `devtools::test()` invocation), and "0 errors" unreadable off testthat 3e's `FAIL | WARN | SKIP | PASS` line, which folds errors into FAIL (now `FAIL 0`).
- 2026-08-27: AC6 defines the profile's `verify` slot word "clean" as "no warning the branch adds", not "no warning at all" — a deliberate relaxation of the slot's literal text, flagged here for the review gate rather than left implicit.
- 2026-08-27: T7 complete. Merge-base measurement, `devtools::test()` on `main` (3abc2a4) in a separate git worktree: `FAIL 0 | WARN 3 | SKIP 2 | PASS 8896`. Branch: `FAIL 0 | WARN 3 | SKIP 2 | PASS 9091`. The two warning sets are identical by rendered message text — "The lavaan engine reported a fitting warning.", "The glmmTMB engine reported a fitting warning.", "Modeling raters as fixed restricts inference to exactly these raters; you cannot generalize to other raters." — so the set difference (branch minus merge-base) is empty and AC6 holds. The 195 added passes are the grid file's. Worktree removed.
- 2026-08-27: ROADMAP gained a candidate row for the three escaping suite warnings (search-first: no overlapping row). `cairn/ROADMAP.md` is 57 lines / 24,707 bytes — inside the 60-line cap, over the 24,000-byte budget, which it already was at 24,200 before this milestone touched it. Compressed what M141 owns: the `tidy()$occasions` / `glance()$n_o` row's second half, now held by D-041 and the grid test, became a cross-reference (-246 bytes). The remaining overage is unrelated rows and belongs to the post-merge hygiene pass. `cairn/LESSONS.md` sits at exactly 20,000 bytes against its <20,000 budget, untouched by this milestone.
- 2026-08-27: note for review, no amendment sought — AC4 and the Scope line cite the fixed-rater abort at `R/icc.R:1459-1465`, its location when the plan was written. T5's rewording moved it to `R/icc.R:1463-1472`; the multilevel sibling AC4 cites at `R/icc.R:1436-1443` is unmoved. The criterion is read as written; only the line numbers are stale.
- 2026-08-27: status review; all tasks checked.

## Decisions

## Review
