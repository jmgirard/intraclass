<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M150: The test suite's condition handling is exact

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate -->
- **Surface tier:** internal — edits to the test suite's own condition handling; nothing the package computes or reports changes   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m150-test-suite-condition-handling` · https://github.com/jmgirard/intraclass/pull/168   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Every warning a test provokes is asserted at its site and the disposition
grid's condition renderer never re-interpolates text a condition has already
rendered, so `devtools::test()` reports `WARN 0` and a braced message cannot
error the grid file.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the two defects the ROADMAP candidate row "Two test-suite defects,
neither a defect in what the package computes" names. (a) `render_condition()`
in `tests/testthat/test-n-o-disposition-grid.R` feeds `conditionMessage(cnd)`
— text cli formatted when the condition was created (LESSONS 2026-08-21, M129)
— back through `cli::format_message()`, which interpolates braces, so a message
holding a literal `{` errors the file instead of failing its case. (b) The
three warnings `devtools::test()` reports on the default branch (M143 review,
2026-08-27; the first two re-measured at this plan, the third from that review): the package's lavaan fitting-warning
re-signal past an `expect_error()` in `test-icc-lavaan-multilevel.R`, its
glmmTMB fitting-warning re-signal past an `expect_message()` in
`test-icc-type-vector.R`, and the classed `intraclass_fixed_raters` advisory
from an unwrapped glmmTMB `raters = "fixed"` call in `test-icc-brms.R`. Each is
asserted by identity at its site — the advisory by class, the two re-signals by
the package's own frame sentence — never suppressed.

**Out:** any change under `R/` — the warnings are the package's own conditions
and stay as shipped. A NEWS entry — none is owed for a tests-only change (NEWS
is a user surface). The three doctrine-module budgets — landed as a trivial
direct commit with this plan (`cairn/doctrine/*.md` headers), not milestone
work. A fourth standing warning, should one appear — a new candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `render_condition()` (`tests/testthat/test-n-o-disposition-grid.R`)
      returns the text of a condition whose message contains a literal `{` or
      `}` with those characters intact, pinned by a test in that file over a
      condition raised with a braced message.
- [x] AC2: Every abort-substring and bullet expectation that
      `test-n-o-disposition-grid.R` makes through `render_condition()` passes
      against the changed renderer, `devtools::test(filter =
      "n-o-disposition-grid")` being the run that enumerates them.
- [x] AC3: `devtools::test()` on the milestone branch reports `WARN 0`, and
      each of the three warnings it reports on the default branch at the plan
      commit — the lavaan fitting-warning re-signal in
      `test-icc-lavaan-multilevel.R`, the glmmTMB fitting-warning re-signal in
      `test-icc-type-vector.R`, and the `intraclass_fixed_raters` advisory in
      `test-icc-brms.R` — is asserted, not suppressed, at its own site.
- [x] AC4: `devtools::test()` reports `FAIL 0`, and `lintr::lint_package()`
      reports no lint in `test-n-o-disposition-grid.R`,
      `test-icc-lavaan-multilevel.R`, `test-icc-type-vector.R`, or
      `test-icc-brms.R`.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1
- AC3 → T2, T3, T4, T5
- AC4 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: In `test-n-o-disposition-grid.R`, add a test that raises a condition
      whose message holds a literal `{x}` and passes it through
      `render_condition()`; run it red against the shipped renderer and record
      the error text in the work log. Then change the renderer to
      `cli::ansi_strip()` and whitespace-normalize `conditionMessage(cnd)`
      without `cli::format_message()`; re-run the file green (AC1, AC2).
- [x] T2: `test-icc-lavaan-multilevel.R`, the "between-level Heywood fit"
      test: wrap the `expect_error()` in an `expect_warning()` matching "The
      lavaan engine reported a fitting warning." (`fixed = TRUE`), so the
      boundary diagnostic is asserted as the reason the abort fires (AC3).
- [x] T3: `test-icc-type-vector.R`, the "connectedness: non-bridging raters"
      test: wrap the `expect_message()` in an `expect_warning()` matching "The
      glmmTMB engine reported a fitting warning." (`fixed = TRUE`) (AC3).
- [x] T4: `test-icc-brms.R`, the glmmTMB `raters = "fixed"` containment fit:
      wrap it in `expect_warning(class = "intraclass_fixed_raters")` (AC3).
- [x] T5: Verify: `devtools::test()` `FAIL 0 / WARN 0`; `lintr::lint_package()`
      over the four edited files (LESSONS 2026-08-27, M141: CI lints `tests/`);
      state in the work log that no NEWS entry is owed (AC3, AC4).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap. -->

- 2026-09-10: `devtools::test()` on main at 972e635 re-measured during planning: the lavaan re-signal at `test-icc-lavaan-multilevel.R:402` and the glmmTMB re-signal at `test-icc-type-vector.R:286` observed; the run had not reached `test-icc-brms.R` at the plan commit, so the third site is taken from the M143 review (2026-08-27).
- 2026-09-10: created by /milestone-plan from the candidate row "Two test-suite defects, neither a defect in what the package computes" (lineage M141 review [O] 1; M141 hygiene). Collision sweep: no planned or archived milestone, no D-entry, no open issue or PR overlaps; D-021 does not reach a change to tests of the package's own conditions.
- 2026-09-10: criteria audit ran in REDUCED mode (internal tier), fresh [O] reader. Two findings, both fixed at the gate: AC3 had bound the assertion form (class-or-frame, no `suppressWarnings()`), an instrument property — narrowed to the outcome, the form moved to T2–T4; AC4 quantified over "the three test files this milestone edits" where four are edited — the four now named.
- 2026-09-10: plan gate chose asserting each warning by identity over `suppressWarnings()` at the three sites because each warning is the package's own condition and the fixture's reaching it is the premise the test rests on; falsified by an assertion going red on an engine upgrade while the fixture still reaches the boundary.
- 2026-09-10: plan gate chose one milestone over two (renderer / warnings) because both change only test files and fit one session; falsified by either half needing its own review round.
- 2026-09-10: T1 — braced-message test run red against the shipped renderer: `Error in lapply(text, glue_cmd, .envir = .envir): Could not evaluate cli {} expression: x / object 'x' not found` at `test-n-o-disposition-grid.R:344`; renderer now `cli::ansi_strip()` + whitespace collapse over `conditionMessage()` alone; `devtools::test(filter = "n-o-disposition-grid")` green.
- 2026-09-10: T2–T4 — the three sites now assert their warning (lavaan and glmmTMB re-signals by frame sentence with `fixed = TRUE`, the brms-file glmmTMB fixed-rater fit by class `intraclass_fixed_raters`); `devtools::test(reporter = "summary")` over the whole suite: 54 files, no Warnings or Failed section, `icc-brms` ran unskipped; `lintr::lint_package()` reports 0 lints in the four edited files.
- 2026-09-10: T5 — `devtools::test()` on the branch at b3989ef: `[ FAIL 0 | WARN 0 | SKIP 2 | PASS 9471 ]` (the two skips are the uninstalled-vignette guards, unchanged from main); lint over the four edited files: 0. No NEWS entry is owed: every change is under `tests/`, a surface users never see.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: all tasks checked; status → review; no deviation from plan.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. -->
- 2026-09-10: the planning-time suite run on main at 972e635 finished after the plan commit: FAIL 0 / WARN 3 / SKIP 2 / PASS 9467; the third warning is the `intraclass_fixed_raters` advisory at `test-icc-brms.R:2425`, so all three sites are now measured, not taken from the M143 review.
- 2026-09-10 AC1: `devtools::test(filter = "n-o-disposition-grid")` on the branch at 5d3e466 green, the file's "render_condition() keeps a literal brace in a condition's message" test (`test-n-o-disposition-grid.R:341`) among its passing expectations; the diff shows the renderer now strips ANSI and collapses whitespace over `conditionMessage()` alone, with no `cli::format_message()` call — verified.
- 2026-09-10 AC2: the same filtered run reports no failure across the file, so every abort-substring and bullet expectation routed through `render_condition()` (`run_n_o_case` at lines 385–440 and the shared-message checks at 535–564) passes against the changed renderer — verified.
- 2026-09-10 AC3: `devtools::test(reporter = "summary")` on the branch at b08927c over all 54 files: no Warnings section (WARN 0) and `icc-brms` ran unskipped; the diff shows each of the three sites asserting its warning — `test-icc-lavaan-multilevel.R:402` and `test-icc-type-vector.R:286` by the engine's frame sentence with `fixed = TRUE`, `test-icc-brms.R:2431` by class `intraclass_fixed_raters` — with no `suppressWarnings()` added; the [O] reviewer independently confirmed each site emits exactly one warning — verified.
- 2026-09-10 AC4: the same run has no Failed section (FAIL 0; 2 skips are the vignette guards, unchanged from main); `lintr::lint_package()` filtered to the four edited files reports 0 lints — verified.
