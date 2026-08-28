# M143: Design 3 stops reporting a rater treatment for a facet it does not have

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** `m143-design3-rater-facet`

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

- [ ] AC1. On a fit whose `design$ml_design` is `"nested_in_subjects"`, and on a
      `d_study()` projection of such a fit, `glance()$raters` is `NA_character_`.
      `tests/testthat/test-exported-contract.R:513`, which pins `"random"` for a
      Design 3 projection today, is re-pinned in the same commit.
- [ ] AC2. For a Design 3 fit, the header `format.icc()` renders — captured with
      `cli::cli_fmt()` (M129) — contains `sprintf("Raters: %d", x$n$raters)` and
      contains neither `"(random)"` nor `"(fixed)"`. A Design 1 (multilevel
      crossed) and a Design 2 (`nested_in_clusters`) fit, which render through the
      same multilevel branch, each still contain their treatment word.
- [ ] AC3. `summary()` on a Design 3 fit does not contain the
      `type_line("agreement")` sentence at `R/icc-methods.R:315-319`, and does
      contain a sentence stating that raters nested in subjects leave no separable
      rater main effect. A crossed two-way agreement fit still contains the
      `type_line("agreement")` sentence.
- [ ] AC4. The sentence at `R/icc.R:683` documenting `glance()`'s `raters` column,
      as rendered into `man/icc.Rd`, states the `nested_in_subjects` condition
      beside the `model = "oneway"` one.
- [ ] AC5. On a Design 3 fit, none of the five renderers of the `icc` object's
      public surface (D-035 clause 2) — `tidy()`, `glance()`, `print()`,
      `format()`, `summary()` — yields `"random"` or `"fixed"` as a rater
      treatment. `$fit` and `$call`, that enumeration's other two members, are
      excluded by name: the engine's own object and the user's literal call.
- [ ] AC6. `devtools::test()` and `R CMD check --as-cran` are clean, and the six
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
- [ ] T5. Failing test, then edit, for the `summary()` interpretation sentence
      (`R/icc-methods.R:315-319`), with the crossed-agreement control.
- [ ] T6. `R/icc.R:683`; `devtools::document()`.
- [ ] T7. The five-renderer sweep test.
- [ ] T8. Gate: full suite, `--as-cran`, the six `data-raw/` checkers,
      `cairn_validate`.

## Work log

- 2026-08-27: created by /milestone-plan.
- 2026-08-27: implement gate chose the one-way-parallel nesting sentence for `summary()` and one shared internal predicate over per-site conditions, the duplication having been why D-038's one-way rule reached `glance.icc()` and not `icc_raters`.
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
