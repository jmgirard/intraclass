# M119: Reconcile the shipped width claims with M118's third grid

- **Status:** planned
- **Priority:** normal
- **Depends on:** M118
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Restate every shipped claim that no measured grid varies the residual, which
M118 falsifies, to what the three grids now jointly measure.

## Scope

**In:** the user-facing surfaces asserting residual invariance — at plan time
`R/icc.R:413-414` and `:582-583`, `vignettes/interval-methods.Rmd:200-205`,
`vignettes/glossary.Rmd:48-49` and their generated `man/icc.Rd` mirrors, with
the site set decided at implement time by a walk, never by this list; a NEWS
entry; extension of the existing `tests/testthat/test-doc-skew-caveat.R`
instrument to M118's fixture and to the reworded claims.

**Out:** a second doc-claim instrument — the existing test is extended, per
`D-029`'s M116 precedent. Any change to what `"searle"` or `"burch"` computes,
or to which method the runtime hint recommends → not planned; M118 is a width
finding, and `D-027`'s coverage-based preference for `"searle"` is untouched.
Re-opening the width-margin wording M117 settled, beyond the residual clause →
not in scope.

## Acceptance criteria

- [ ] AC1 The residual-invariance site set is enumerated by a standing walk in
      `test-doc-skew-caveat.R` over the source and installed doc surfaces the
      file already walks (`:238-243`'s convention), not by a list recorded in
      this milestone; every site the walk returns states what the three grids
      jointly measure, and the walk fails on a site that still asserts no grid
      varies the residual.
- [ ] AC2 The reworded claims are consistent with both
      `tests/testthat/fixtures/classical-width-by-cell.tsv` and M118's
      `tests/testthat/fixtures/width-reversal-by-cell.tsv`, each figure stated
      in one of the file's canonical shapes (`width_canonical_shapes()`,
      `:886-1059`) and checked against the fixture cell it names.
- [ ] AC3 Every `width_expected_runs` floor (`:669-679`) is at or above its
      pre-milestone value, and the suite passes with zero skips under
      `testthat::test_dir("tests/testthat", package = "intraclass",
      load_package = "installed")` against a package installed with
      `build_vignettes = TRUE`.
- [ ] AC4 Each claim this milestone adds or rewords is mutation-verified
      through `data-raw/m117-width-pin-mutations.R`, extended so every such
      claim faces four break forms — restore the pre-milestone wording,
      paraphrase it, negate it, drop its hedge — and each break reds the suite.
- [ ] AC5 The `r-package` profile's `verify` slot is clean, and all four
      `data-raw/` checkers pass, including a re-triaged
      `data-raw/mpl-doc-claims.tsv` row for every reworded `R/icc.R` sentence.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6

## Tasks

- [ ] T1 Add the residual-invariance walk to `test-doc-skew-caveat.R`; run it
      red first to freeze the exact site set M118 falsified.
- [ ] T2 Reword each site the walk returns, and `devtools::document()` the
      `man/icc.Rd` mirrors.
- [ ] T3 Bind each new figure to a canonical shape and to its fixture cell.
- [ ] T4 Install with `build_vignettes = TRUE`; run the installed-surface suite
      and confirm zero skips; check the run floors.
- [ ] T5 Extend the M117 mutation harness with the four break forms per claim.
- [ ] T6 NEWS entry; re-triage the `mpl-doc-claims.tsv` rows; run `verify`, the
      four checkers, `air format .`, lintr.

## Work log

- 2026-08-13: created by /milestone-plan.
- 2026-08-13: plan-gate criteria audit ([O], fresh context) found the drafted site list was `width_expected_runs`' nine width-margin keys rather than the residual-invariance sites; a grep put the real set at four source surfaces plus the generated Rd, and AC1 now names a walk rather than any list.
- 2026-08-13: plan gate chose four break forms per claim over the single restore-the-old-wording probe because the audit measured three consecutive review rounds where each round closed the mutations it found and left the next open; falsified by a shipped claim surviving all four breaks yet later found wrong.
- 2026-08-13: plan chose extending `test-doc-skew-caveat.R` over a new instrument, following D-029's M116 precedent; falsified by the existing file proving unable to carry a residual-invariance walk.
- 2026-08-13: plan corrected AC3 from "the count the surfaces actually carry" to a floor, the apparatus enforcing `>=` (`:1666-1670`) and its own comment (`:570-573`) calling floors deliberate, so the drafted wording was unverifiable; and added the `build_vignettes = TRUE` precondition without which five vignette legs skip silently.

## Decisions

## Review
