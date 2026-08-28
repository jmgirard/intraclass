# M143: Design 3 stops reporting a rater treatment for a facet it does not have

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** `m143-design3-rater-facet` / https://github.com/jmgirard/intraclass/pull/154

## Goal

On a multilevel Design 3 fit (raters nested in subjects), the public surfaces stop
naming a rater treatment for a rater facet the model does not estimate.

## Scope

Surface tier: **user-facing** — the deliverable changes `glance()`, `print()`,
`format()` and `summary()` output, which D-035 clause 2 makes the `icc` object's
public contract.

**In:** `glance()$raters` becomes `NA_character_` on a fit whose `ml_design` is
`"nested_in_subjects"`, and on a `d_study()` projection of one — both producers,
`glance.icc()` (`R/icc-methods.R:397-402`) and `icc_raters` (`R/d-study.R:546`).
The header rendered by `format.icc()`'s multilevel branch (`R/icc-methods.R:46-57`)
drops the treatment word for that design only. `summary()` stops emitting the
`type_line("agreement")` sentence (`R/icc-methods.R:315-319`), which attributes
error to a rater main effect this design cannot separate, and says instead what the
nesting does. `?icc`'s `raters`-column sentence (`R/icc.R:683`) gains the new
condition. A D-entry supersedes D-038 clause 1's Design 3 sentence.

**Out:** `design$type` and `design$model`, which report `"agreement"` and
`"twoway"` on this design — internal under D-035 clause 2, changeable without a
deprecation cycle, so not door-bound → candidate row. `n_raters`, which counts
nested rater ids and is a true count → candidate row. The `NEWS.md` *What ships*
capability gap → M144.

## Acceptance criteria

- [x] AC1. On a fit whose `design$ml_design` is `"nested_in_subjects"`, and on a
      `d_study()` projection of such a fit, `glance()$raters` is `NA_character_`.
      `tests/testthat/test-exported-contract.R:513`, which pins `"random"` for a
      Design 3 projection today, is re-pinned in the same commit.
- [x] AC2. For a Design 3 fit, the header `format.icc()` renders — captured with
      `cli::cli_fmt()` (M129) — contains `sprintf("Raters: %d", x$n$raters)` and
      contains neither `"(random)"` nor `"(fixed)"`. A Design 1 (multilevel
      crossed) and a Design 2 (`nested_in_clusters`) fit, which render through the
      same multilevel branch, each still contain their treatment word.
- [x] AC3. `summary()` on a Design 3 fit does not contain the
      `type_line("agreement")` sentence at `R/icc-methods.R:315-319`, and does
      contain a sentence stating that raters nested in subjects leave no separable
      rater main effect. A crossed two-way agreement fit still contains the
      `type_line("agreement")` sentence.
- [x] AC4. The sentence at `R/icc.R:683` documenting `glance()`'s `raters` column,
      as rendered into `man/icc.Rd`, states the `nested_in_subjects` condition
      beside the `model = "oneway"` one.
- [x] AC5. On a Design 3 fit, none of the five renderers of the `icc` object's
      public surface (D-035 clause 2) — `tidy()`, `glance()`, `print()`,
      `format()`, `summary()` — yields `"random"` or `"fixed"` as a rater
      treatment. `$fit` and `$call`, that enumeration's other two members, are
      excluded by name: the engine's own object and the user's literal call.
- [x] AC6. `devtools::test()` and `R CMD check --as-cran` are clean, and the six
      `data-raw/` checkers pass.

## Coverage

- AC1 → T2, T3
- AC2 → T4
- AC3 → T5
- AC4 → T6
- AC5 → T7
- AC6 → T8

## Tasks

- [x] T1. Append the superseding D-entry: D-038 clause 1's Design 3 sentence rests
      on a sibling `glance()$type` column that D-038 itself refuses and that does
      not exist, and on `tidy()$type`, which already reports `NA` on Design 3
      (measured 2026-08-27). The pair it deferred is therefore not two cells, so
      `raters` is severable; GP2's door closing at submission is the trigger, in
      place of the row's unmet "a user reading either cell as a facet that exists".
- [x] T2. Failing test first: `glance()$raters` on the `design3_frame()` fixture
      (`tests/testthat/test-exported-contract.R:372`) and on the three
      `sim_design3()` fixtures (`test-icc-nested-multilevel.R:173, :194, :207`).
- [x] T3. `glance.icc()` (`R/icc-methods.R:397-402`) and `icc_raters`
      (`R/d-study.R:546`); re-pin `test-exported-contract.R:513`.
- [x] T4. Failing test, then edit, for the multilevel-branch header
      (`R/icc-methods.R:46-57`), with the Design 1 and Design 2 controls.
- [x] T5. Failing test, then edit, for the `summary()` interpretation sentence
      (`R/icc-methods.R:315-319`), with the crossed-agreement control.
- [x] T6. `R/icc.R:683`; `devtools::document()`.
- [x] T7. The five-renderer sweep test.
- [x] T8. Gate: full suite, `--as-cran`, the six `data-raw/` checkers,
      `cairn_validate`.

## Work log

- 2026-08-27: merge gate — maintainer approved fixing four findings before the merge. F1 (`?d_study` still documented the one-way-only rule), F2 (D-042's rationale overclaimed about the projection row), F5 (D-035 clause 2 mis-cited as five renderers) and F7 (a false clause in a retained `R/d-study.R` comment) fixed on the branch; F3 and F4 recorded without a code change; F9 filed as a follow-up; F6 and F8 rejected.
- 2026-08-27: created by /milestone-plan.
- 2026-08-27: implement gate chose the one-way-parallel nesting sentence for `summary()` and one shared internal predicate over per-site conditions, the duplication having been why D-038's one-way rule reached `glance.icc()` and not `icc_raters`.
- 2026-08-27: T8 gate — `R CMD check --as-cran` 0 errors / 0 warnings / 0 notes (13m 31s, R 4.6.1, aarch64-apple-darwin23); `devtools::test()` FAIL 0 / WARN 3 / SKIP 2 / PASS 9107, the three warnings the default branch also reports (candidate row); all six `data-raw/` checkers pass; `cairn_validate` all checks passed.
- 2026-08-27: no NEWS entry is owed. The 0.1.0 notes are first-release notes for an unreleased version, and M142's rewrite left them describing no `glance()` column, so this milestone corrects no NEWS sentence and no released behavior. Checked against `NEWS.md` on this branch.
- 2026-08-27: T7 — the five-renderer sweep. Its first pattern, `\\b(random|fixed)\\b`, matched nothing under either regex engine, so the Design 3 side passed vacuously; the discriminating control caught it, and the pattern is now the plain alternation. The control asserts the measured set rather than all five: `glance()`, `print()`, `format()` and `summary()` carry the word on a crossed random fit, `tidy()` carries no rater treatment at all. Planting `design_has_rater_facet() == TRUE` reds 8 assertions in the file, the sweep among them. Full suite FAIL 0 / WARN 3 / SKIP 2 / PASS 9107.
- 2026-08-27: T6 — the `glance()$raters` sentence in `R/icc.R` now names both conditions, `model = "oneway"` and `design = "nested_in_subjects"`, in the user-facing argument spellings. The roxygen edit itself rode into T5's commit; this one carries the regenerated `man/icc.Rd`, whose only diff is that paragraph.
- 2026-08-27: T5 — failing test then edit for `summary()`. Red on the Design 3 column alone (agreement note present, nesting note absent); the crossed-agreement control was already correct before the edit. `summary.icc()` gains a third top-level branch, keyed on the shared predicate, returning the nesting note in the shape the one-way note uses. Full suite FAIL 0 / WARN 3 / SKIP 2 / PASS 9100.
- 2026-08-27: T4 — failing test then edit for the multilevel header. Red on the treatment word alone (`"random" "random" "random"` against `"random" "random" NA`), the rater-count and Design 1/2 control assertions green before the edit; `format.icc()`'s multilevel branch now builds the rater segment through the shared predicate. No snapshot or vignette transcript pins a Design 3 header. Full suite FAIL 0 / WARN 3 / SKIP 2 / PASS 9098.
- 2026-08-27: T3 — added `design_has_rater_facet()` (`R/design.R`), the one predicate both producers now read (implement gate choice); `glance.icc()` and `d-study.R`'s `icc_raters` wired to it; `test-exported-contract.R`'s Design 3 projection pin re-pinned to `NA_character_`. Full suite FAIL 0 / WARN 3 / SKIP 2 / PASS 9092 -- the same three warnings the default branch reports (candidate row).
- 2026-08-27: T2 — failing tests first: one new block in `test-icc-nested-multilevel.R` over four Design 3 geometries (the three `sim_design3()` fits plus the ragged one), fit and `d_study()` projection each; `design3` added to `test-exported-contract.R`'s per-design `glance()` block. Red before any source edit: 9 failures, all of them the `raters` cell reading `"random"` where the design has no rater facet (8 in the new matrix, 1 in the exported-contract block); the rest of both files green.
- 2026-08-27: T1 — appended D-042, superseding D-038 clause 1's Design 3 sentence.
- 2026-08-27: /milestone-implement started; branch `m143-design3-rater-facet` cut from `main` at 2fac62d.
- 2026-08-27: criteria audit ran in FULL mode (user-facing tier). Returned a finding on all five drafted criteria: AC1 forbidden by live D-038 clause 1 and blind to the second `raters` producer at `R/d-study.R:546` plus its pin at `test-exported-contract.R:513`; AC2 asserting the fixture constant `Raters: 480` and controlling on `format.icc()`'s single-level branch rather than the multilevel one it edits; AC3 and AC4 making universals ("no sentence", "names no third") no named procedure enumerates; AC5 promising over `d_study()`'s projection table, which D-035 clause 2 does not cover. All six fixed at the gate; none became a question.
- 2026-08-27: plan gate chose changing `raters` alone over deciding the `raters`/`type` pair together (D-038's framing) because the pair does not exist: D-038 refuses a `glance()$type` column and `tidy()$type` already reports `NA` here, so the split it feared is already the shipped state. Falsified by a public surface reporting an agreement/consistency label for Design 3 that this milestone leaves standing.
- 2026-08-27: plan gate chose `NA_character_` over documenting the nominal cell in place because GP2 makes the schema a one-way door at submission while documentation amends freely. Falsified by a consumer relying on `glance()$raters` being non-`NA` on every multilevel fit.

## Decisions

- 2026-08-27: measured on the `design3_frame()` fixture (seed 7): `tidy()$type` is `NA` on both rows, `glance()$raters` is `"random"`, `design$type` is `"agreement"`, `design$model` is `"twoway"`. This is the measurement D-042 cites.

## Review

Reviewed 2026-08-27 on `m143-design3-rater-facet` @ 366b563, PR #154.
Evidence run fresh in this phase against a `devtools::load_all()` of the branch;
fixture functions loaded from the two test files without executing their
`test_that()` blocks, so each figure is a new fit, not a test's own report.

### Acceptance criteria

- **AC1 — PASS.** `glance()$raters` measured on five Design 3 fits and on a
  `d_study(m = 1:3)` projection of each: the `design3_frame()` fixture and the
  four geometries `test-icc-nested-multilevel.R` fits (oracle 30x8x6,
  reduction 50x20x6 at zero cluster variance, detection 20x6x4, and the ragged
  25%-dropped one). All ten cells read `NA` and all five fits report
  `design$ml_design == "nested_in_subjects"`. The `test-exported-contract.R`
  Design 3 projection pin was re-pinned from `"random"` to `NA_character_` in
  commit 4243a65, the same commit that changed both producers.
- **AC2 — PASS.** Header captured with `cli::cli_fmt(print(x))`. Design 3
  (`Raters: 480`) contains `sprintf("Raters: %d", x$n$raters)` and neither
  `"(random)"` nor `"(fixed)"`. The two controls through the same multilevel
  branch keep their treatment word: Design 1 (`crossed`) renders
  `Raters: 3 (random)`, Design 2 (`nested_in_clusters`) renders
  `Raters: 15 (random)`.
- **AC3 — PASS.** `summary()` on the Design 3 fit contains no
  `"Absolute agreement counts the rater main effect"` sentence and does contain
  "Raters nested in subjects: each subject is rated by its own set of raters, so
  systematic rater differences cannot be separated and are absorbed into the
  residual (a conservative ICC)." The control, a crossed two-way agreement fit,
  still carries the agreement sentence and not the nesting one.
- **AC4 — PASS.** `man/icc.Rd:487-492` (rendered from `R/icc.R:683-687`) states
  both conditions in the user-facing argument spellings: `NA` where the design
  estimates no separable rater main effect -- a `model = "oneway"` fit and a
  `design = "nested_in_subjects"` fit. `devtools::document()` on the branch
  leaves no diff.
- **AC5 — PASS.** Match counts for the pattern `random|fixed` over a Design 3
  fit: `tidy()` 0 of 10 character cells, `glance()` 0 of 4, `print()` 0 of 9
  lines, `format()` 0 of 9, `summary()` 0 of 13. The same sweep over a crossed
  random-rater fit, where the treatment is defined, hits on four of the five --
  `glance()` 1, `print()` 2, `format()` 2, `summary()` 2, `tidy()` 0 -- so the
  sweep is shown able to red rather than passing on an empty domain. `$fit` and
  `$call` excluded by name per the criterion.
- **AC6 — PASS.** `R CMD check --as-cran`: Status OK, 0 errors / 0 warnings /
  0 notes (13m 52.9s, R 4.6.1, aarch64-apple-darwin23). `devtools::test()`:
  FAIL 0 / WARN 3 / SKIP 2 / PASS 9107. The three warnings are the three the
  ROADMAP candidate row already names on the default branch, re-identified here
  by site and message: a lavaan negative-latent-variance warning past an
  `expect_error()` (`test-icc-lavaan-multilevel.R:402`), a glmmTMB
  non-positive-definite-Hessian warning past an `expect_message()`
  (`test-icc-type-vector.R:286`), and the fixed-rater advisory from an unwrapped
  `icc()` call (`test-icc-brms.R:2425`). All six `data-raw/` checkers pass.

### Consistency gate

Universal cairn-file checks: `cairn_validate.py` exit 0, all checks passed
(`coverage complete` and `scaffold present` among them); the `release window`
advisory did not fire. No `DESIGN.md` principle changed on this branch, so
`cairn_impact.py` does not apply -- GP2 is *touched*, not amended.

Toolchain checks, from the `r-package` profile's `consistency-gate` slot:
`devtools::document()` leaves no diff; `NAMESPACE`, `man/` and `data/*.rda` are
generated and the no-diff `document()` run covers them; `README.Rmd` and
`README.md` share a last-touching commit (5c274fc), so they are in sync;
`pkgdown::check_pkgdown()` reports no problems; no top-level file is added, so
no `.Rbuildignore` entry is owed, and the `--as-cran` run reports 0 notes;
`devtools::check()` clean, recorded under AC6. `air format --check` is clean on
every file this branch touches (its two hits are pre-existing files under
`tests/testthat/_problems/`, untouched here).

**NEWS.md.** The slot asks for an entry covering this milestone's user-visible
changes. None is owed and none was added: v0.1.0 is unreleased, so its notes
describe the shipping behavior rather than a change from a prior release, and
the `glance()` bullet (`NEWS.md:25-28`) describes no column values. Nothing in
NEWS is made false by this branch. Checked against `NEWS.md` on this branch.

### Independent fresh-context review

The diff touches `R/` and `tests/`, so the full three-lens fan-out ran, each
lens on its own evidence base and none having seen the implementation.

- **[S] blame-history:** no conflicting finding. D-038 clause 1 is superseded
  through D-042 rather than silently overridden; `design$type`/`design$model`/
  `n_raters` are left untouched, matching the Out scope and D-035 clause 2; the
  M8 §3b citation in the new comment checks out against the estimand spec. It
  raised the `icc_design_phrase()` legacy fallback (F9 below) and one
  terminology nit (F6).
- **[S] prior-review record:** no regression finding. It read the archived
  `## Review` sections touching these files and `LESSONS.md`, and probed
  `gh api repos/jmgirard/intraclass/pulls/comments?per_page=1`, which returned
  `[]` -- so the GitHub thread surface was skipped, as the M91 measurement
  predicts. It records that M138's duplicated-predicate root cause is what
  `design_has_rater_facet()` fixes, that M140's "measure the whole grid first"
  lesson is honoured by the four-geometry test, and that M129's cli-capture
  lesson is honoured by the `cli::cli_fmt()` captures. It raised F9
  independently.
- **[O] diff-bug:** nine findings, ranked. All nine are logged and triaged
  below; five were re-measured here against the implementation rather than
  accepted on the reviewer's account.

### Findings and disposition

Ranked as the [O] lens ranked them; F-numbers are this section's. No finding
demonstrates an acceptance criterion failing: all six were measured passing
above.

- **F1. `R/d-study.R:139-145` and `man/d_study.Rd:80-86` still document the old
  rule.** `?d_study` describes `glance.icc_dstudy()`'s rater treatment as "`NA`
  on a projection of a one-way fit, whose interchangeable raters carry no
  facet". AC1 made that column `NA` on Design 3 projections too, and T6 updated
  only `?icc`. Verified on disk: the sentence is unchanged at
  `R/d-study.R:141-142`. A user consulting `?d_study` after reading `NA` there
  concludes the fit was one-way -- the same inaccuracy AC4 removed from `?icc`,
  left standing on the sibling table.
- **F2. D-042's stated reason is incomplete about the surface it governs.**
  D-042 argues the `type`/`raters` pair D-038 declined to split "does not
  exist". Measured here on a Design 3 projection: `glance(d_study(d3))$type` is
  `"agreement"` and `$raters` is `NA`; `tidy(d_study(d3))$type` is `"agreement"`
  as well. `glance.icc_dstudy()` carries both columns (`R/d-study.R:742-752`),
  so the pair does exist on the projection row, and it now reads split. The
  outcome is defensible -- absolute agreement IS defined for Design 3, and the
  package says so in its own dropped-`"consistency"` message, while the rater
  treatment is not -- but the recorded rationale asserts more than holds.
- **F3. `summary()` on Design 3 also loses the cell note.** On `origin/main` a
  Design 3 fit printed the agreement note plus "A single rating per cell
  confounds the subject-by-rater interaction with residual error." The branch
  returns the nesting sentence alone, so both are gone. Verified by reading
  `origin/main:R/icc-methods.R:295-340` against the branch's rendered output.
  AC3 authorized removing the `type_line("agreement")` sentence only. Dropping
  the cell note parallels what the one-way branch already does and is right on
  the merits (Design 3 has no separable subject-by-rater interaction), but it is
  an unrecorded change to a public renderer.
- **F4. The five-renderer sweep discriminates for four renderers, not five.**
  Verified by planting: with `summary.icc()`'s new branch disabled and every
  other edit intact, the dedicated T5 test reds (2 failures, at
  `test-exported-contract.R:656` and `:665`) but the sweep stays green. On the
  crossed control the `summary = TRUE` cell is satisfied by the
  `Raters: N (random)` line `summary()` inherits from `format()`, and on the
  Design 3 side the pre-T5 agreement note contains neither word. Coverage is not
  lost; the sweep's own claim is weaker for `summary()` than its comment reads.
  The work log records the `tidy()` half of this, not the `summary()` half.
- **F5. D-035 clause 2 is cited as a five-member enumeration.** Read at
  `cairn/DECISIONS.md:1530-1532`: clause 2 names `tidy()`, `glance()`,
  `summary()` and `print()`, plus `$fit` and `$call` -- four methods, not five;
  `format()` is not in it. The test comment at
  `test-exported-contract.R:632-636` and AC5's parenthetical both attribute the
  five-member list to it. Substantively harmless (`print()` delegates to
  `format()`, and AC5 enumerates its own five by name, all five measured), but
  it attributes to a change-controlled decision an enumeration it does not
  contain.
- **F6. `?icc` states the condition in argument spelling.** "a
  `design = "nested_in_subjects"` fit" names an `icc()` argument value the user
  need not pass -- every Design 3 fixture on this branch is auto-detected --
  while the observable sibling in the same `glance()` row is `ml_design`. AC4 is
  met as written; this is precision, not accuracy.
- **F7. The retained `R/d-study.R:541-543` comment is false.** "The local
  `raters` still carries the fitted value into `make_estimand()` above": for a
  Design 3 fit `ml_oneway` is TRUE (`R/d-study.R:205`) and that branch
  (`:377-378`) never reads `raters`; the `oneway` branch (`:392-393`) does not
  either. Verified by reading both branches. The clause was already inaccurate
  on `origin/main`; this branch reworded the comment around it and carried it
  forward.
- **F8. The `summary()` branch is keyed more broadly than its prose.**
  `!design_has_rater_facet()` is also TRUE for a one-way fit; only the preceding
  branch's ordering keeps a one-way fit from being told "Raters nested in
  subjects". Correct today; a reordering or a third no-facet design would emit
  prose naming the wrong reason.
- **F9. `icc_design_phrase()`'s `is.na(raters)` maps to the literal
  `"one-way random"` (`R/estimand.R:229`).** Raised independently by all three
  lenses. Design 3 projections now carry `icc_raters = NA`, so a legacy
  `icc_dstudy` object with no `icc_design_label` attribute would render
  "one-way random" through the fallbacks at `R/d-study.R:620-623` and
  `R/autoplot.R:38-43`. Unreachable for anything this version builds: every
  `d_study()` output sets that attribute, and the current header measures as
  `# D-study projection: multilevel (raters nested in subjects) absolute
  agreement`. On `origin/main` the same legacy object rendered "two-way random,
  absolute agreement", also wrong for Design 3.

Recommended disposition, put to the maintainer at the merge gate: fix F1, F5
and F7 on the branch now (one doc sentence plus `document()`, one test comment,
one stale code comment); amend D-042's rationale for F2 before the squash, the
entry never having reached the default branch; record F3 and F4 here and in the
work log with no code change, both being correct as implemented; absorb F9 into
the standing Design 3 remainder candidate row; reject F6 and F8 -- F6 as
precision on a criterion met as written, F8 as correct under the branch ordering
it has.

**Disposition applied at the merge gate (2026-08-27), maintainer-approved.**
F1 fixed: the `glance.icc_dstudy()` sentence in `R/d-study.R` now names both
no-rater-facet conditions in the user-facing argument spellings, matching the
`?icc` sentence AC4 covers; `man/d_study.Rd` regenerated, its only diff that
paragraph. F2 fixed: D-042's "Why the deferral no longer holds" paragraph now
separates the fit from the `d_study()` projection, states that the projection
row does carry both columns and now reads `type = "agreement"` beside
`raters = NA`, and gives the reason that split is deliberate -- absolute
agreement is defined for Design 3 and the rater treatment is not, so no shared
convention across the two cells can leave both true. The entry had not reached
the default branch, so it is corrected in place rather than superseded. F5
fixed: the test comment now names clause 2's four methods and says why
`format()` is swept alongside them. F7 fixed: the stale clause is replaced by
what is actually true -- neither no-facet case reaches a `make_estimand()`
branch that reads `raters`. F3 and F4 recorded above with no code change, both
being correct as implemented. F9 filed as a follow-up, absorbed into the
standing Design 3 remainder candidate row at the post-merge hygiene pass. F6
and F8 rejected: F6 is precision on a criterion met as written, F8 is correct
under the branch ordering it has.

Re-verified after the fixes: `devtools::document()` leaves no diff beyond the
regenerated `man/d_study.Rd` paragraph, `air format --check` is clean on every
touched file, and `test-exported-contract.R` passes with no failures.
