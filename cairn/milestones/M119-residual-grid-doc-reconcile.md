# M119: Reconcile the shipped width claims with M118's third grid

- **Status:** review
- **Priority:** normal
- **Depends on:** M118
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m119-residual-grid-doc-reconcile` / https://github.com/jmgirard/intraclass/pull/128

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

- [x] T1 Add the residual-invariance walk to `test-doc-skew-caveat.R`; run it
      red first to freeze the exact site set M118 falsified.
- [x] T2 Reword each site the walk returns, and `devtools::document()` the
      `man/icc.Rd` mirrors.
- [x] T3 Bind each new figure to a canonical shape and to its fixture cell.
- [x] T4 Install with `build_vignettes = TRUE`; run the installed-surface suite
      and confirm zero skips; check the run floors.
- [x] T5 Extend the M117 mutation harness with the four break forms per claim.
- [x] T6 NEWS entry; re-triage the `mpl-doc-claims.tsv` rows; run `verify`, the
      four checkers, `air format .`, lintr.

## Work log

- 2026-08-13: created by /milestone-plan.
- 2026-08-13: plan-gate criteria audit ([O], fresh context) found the drafted site list was `width_expected_runs`' nine width-margin keys rather than the residual-invariance sites; a grep put the real set at four source surfaces plus the generated Rd, and AC1 now names a walk rather than any list.
- 2026-08-13: plan gate chose four break forms per claim over the single restore-the-old-wording probe because the audit measured three consecutive review rounds where each round closed the mutations it found and left the next open; falsified by a shipped claim surviving all four breaks yet later found wrong.
- 2026-08-13: plan chose extending `test-doc-skew-caveat.R` over a new instrument, following D-029's M116 precedent; falsified by the existing file proving unable to carry a residual-invariance walk.
- 2026-08-14: /milestone-implement on branch `m119-residual-grid-doc-reconcile`; question gate chose the shared clause to carry one fixture-pinned figure, and the changelog's falsified clause to be corrected in place (the release is unshipped, so a second contradicting entry would be the only alternative).
- 2026-08-14: T1 walk added and run red first: it returned 6 source statements (`R/icc.R` x2, `R/ci-classical.R`, both vignettes, `NEWS.md`) plus the two `Rd:icc.Rd` mirrors, and 8 withdrawn-claim assertions failed across them. Two seed predicates were measured and rejected first — burch-plus-error reached the abort-remedy prose, and grid-plus-subject-effect split the NEWS bullet on a corrected M117 scope clause.
- 2026-08-14: T2/T3 reworded all 6 sites plus the M117 scope qualifiers, `devtools::document()`ed the Rd mirrors, and bound the new figures: `ratio_family` (checked against the M118 fixture's t(5) cell at 100 subjects) and `n_grids` extended to "three"; the clause's qualitative direction is recomputed per family from the fixture's decision block.
- 2026-08-14: T5/T6 content landed with the T1-T3 checkpoint (`f5ab149`, one `git add -A`); this line records their check-off rather than a second commit of the same work.
- 2026-08-14: T5 extended the M117 harness to a second mutated surface (the `?icc` roxygen, which carries the scope claim the article does not) and added eight mutations — four break forms each for the residual clause and the scope claim; all eight red, both controls clean. The harness's prose scan now mirrors three more suite scans: withdrawn claims, the scope refusal, and the residual template over residual runs.
- 2026-08-14: T6 re-triaged the two `mpl-doc-claims.tsv` rows the reworded `@param ci_method` sentences restaled (`873819a29ffd` → `a64f246e63cc`, `354d6f11619c` → `11bf5404facf`); the checker enumerates 46 candidates with 0 failures. All four `data-raw/` checkers pass, `air format .` and `lintr::lint_package()` clean.
- 2026-08-14: T4 installed with `build_vignettes = TRUE` and ran the installed-surface suite under `NOT_CRAN=true`: FAIL 0 | WARN 5 | SKIP 0 | PASS 7786. The five warnings are in `test-icc-lavaan-multilevel.R`, `test-ci-bootstrap.R`, `test-icc-type-vector.R` and `test-icc-brms.R`, none a surface this milestone touches. `width_expected_runs` is unedited on the branch, so every floor is at its pre-milestone value.
- 2026-08-14: corrected `cairn/references/classical-width-reversal-comparison.md`'s forward reference, which said M119 restates the surfaces that "currently" tell users no measured grid varies the residual — false once this branch merges; now dated and pointed at the walk.
- 2026-08-13: plan corrected AC3 from "the count the surfaces actually carry" to a floor, the apparatus enforcing `>=` (`:1666-1670`) and its own comment (`:570-573`) calling floors deliberate, so the drafted wording was unverifiable; and added the `build_vignettes = TRUE` precondition without which five vignette legs skip silently.

## Decisions

## Review
