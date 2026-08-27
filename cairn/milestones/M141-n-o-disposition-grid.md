# M141: The `n_o` disposition grid is pinned, and the fixed-rater replicate abort names the right condition

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP7, GP8, #5, #8
- **Branch/PR:** —

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
      design defines but the data omits), never as a hand-written row list
      (GP8). Combinations the argument grammar makes infeasible are dropped by
      a rule stated beside the call, among them `ml_design =
      "nested_in_clusters"` with `"conflated"`, which `R/icc.R:1291` overrides
      to `"subject"` before the dispatch is reached. Every surviving case
      declares the exact disposition it expects — `expect_identical(glance(fit)$n_o,
      <int>)`, `expect_identical(glance(fit)$n_o, NA_integer_)`, or an abort
      identified by a message substring, never by the `intraclass_unsupported`
      class alone, since guards outside the dispatch abort with that same class
      (`R/icc.R:1232`) — together with the condition stream expected ahead of
      it, derived per case from the advisory's own rule at `R/icc.R:1042`
      (`raters == "fixed" && !(multilevel && "conflated" %in% level)`) rather
      than asserted uniformly. Every case's assertion passes.
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
- [ ] AC6 — `Rscript -e 'devtools::test()'` reports 0 failures, 0 errors and 0
      warnings; `Rscript -e 'devtools::check()'` reports 0 errors and 0
      warnings on `R CMD check`'s own `Status:` line.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7

## Tasks

- [ ] T1 — Measure the whole grid before asserting any of it (M140 lesson):
      build a fixture per replicate shape, run every feasible axis combination,
      and record the observed disposition per case — reported value, or the
      abort's opening line — in the work log. The measurement decides the
      expectations; nothing is predicted from reading the branches.
- [ ] T2 — Write `tests/testthat/test-n-o-disposition-grid.R`: the
      `expand.grid()` call, the stated infeasibility rule, the per-shape
      fixture constructors, and one assertion block per case carrying its exact
      value or message substring and its expected condition stream.
      `devtools::test()` clean.
- [ ] T3 — Add AC2's branch-count assertion over `deparse(body(icc))`; run both
      probes, one temporary `abort_unsupported()` and one raised through a
      different `abort_` helper, and record each red in the work log before
      reverting.
- [ ] T4 — Apply AC3's five planted defects one at a time, each reverted before
      the next; record which named case went red for each, verbatim, in the
      work log.
- [ ] T5 — Reword the abort at `R/icc.R:1459-1465` and the block comments at
      `R/icc.R:1447-1458` that carry the same ragged/missing-cell conflation;
      add the three-bullet rendered-message pins for both fixed-rater shapes.
      (RB tripwire: ip-touching)
- [ ] T6 — Append the superseding entry to `cairn/DECISIONS.md`.
- [ ] T7 — Gate: `devtools::document()` produces no diff; every `data-raw/`
      checker run with `--self-test` (M130 lesson — a tracking edit re-keys
      them); `R CMD check`'s raw `Status:` line read and transcribed into the
      Review section, with any NOTE and its justification recorded there.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: plan-gate criteria audit ran in FULL mode (declared surface tier user-facing), two [O] passes over the drafted wording. Pass 1 returned findings on five of six criteria: a `covr` 100%-line gate conflicting with PRINCIPLES.md #11 and enumerating a proxy range, a self-satisfying "a row per design shape", two probes sharing one location and one mutation form, a hand-pinned grid duplicated into `DECISIONS.md` against GP8, and an undefined "clean". Pass 2 over the repaired wording returned six more: a condition stream false for the multilevel-fixed-conflated case, abort cases identified by class alone that pre-dispatch guards also satisfy, a branch-count equality that cannot hold row-for-row, a probe blind to a differently-named `abort_` helper, a `readLines("R/icc.R")` implementation that errors under `R CMD check`, and two wrong line ranges. All disposed at the gate; one finding — whether the grid carries a mechanical completeness check at all — went to the question gate and became AC2.
- 2026-08-27: plan gate chose a mechanical abort-branch count over a snapshot grid because a later-added branch would otherwise ship unpinned, the shape the standing merDeriv-guard candidate row records as recurring; falsified by a branch-count assertion reddening on a change that adds no new disposition.
- 2026-08-27: plan gate chose mirroring the multilevel sibling's "Ragged or incomplete" wording over a condition-first rewrite because the two aborts guard the same condition and should read alike; falsified by a user reading the shared phrase as naming only the ragged shape.

## Decisions

## Review
