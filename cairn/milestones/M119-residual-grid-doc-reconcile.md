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

- [x] AC1 The residual-invariance site set is enumerated by a standing walk in
      `test-doc-skew-caveat.R` over the source and installed doc surfaces the
      file already walks (`:238-243`'s convention), not by a list recorded in
      this milestone; every site the walk returns states what the three grids
      jointly measure, and the walk fails on a site that still asserts no grid
      varies the residual.
- [x] AC2 The reworded claims are consistent with both
      `tests/testthat/fixtures/classical-width-by-cell.tsv` and M118's
      `tests/testthat/fixtures/width-reversal-by-cell.tsv`, each figure stated
      in one of the file's canonical shapes (`width_canonical_shapes()`,
      `:886-1059`) and checked against the fixture cell it names.
- [x] AC3 Every `width_expected_runs` floor (`:669-679`) is at or above its
      pre-milestone value, and the suite passes with zero skips under
      `testthat::test_dir("tests/testthat", package = "intraclass",
      load_package = "installed")` against a package installed with
      `build_vignettes = TRUE`.
- [x] AC4 Each claim this milestone adds or rewords is mutation-verified
      through `data-raw/m117-width-pin-mutations.R`, extended so every such
      claim faces four break forms — restore the pre-milestone wording,
      paraphrase it, negate it, drop its hedge — and each break reds the suite.
- [x] AC5 The `r-package` profile's `verify` slot is clean, and all four
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
- 2026-08-14: /milestone-review — three-lens fan-out plus scorer produced 16 findings, 3 actioned at >=80 (D4 82, D7 80, D13 80), all three fixed on the branch at `f452c8c`; 13 logged below the bar. None demonstrated an acceptance criterion failing and none scored >=90, so the return floor was not tripped. The blame lens's headline finding (four dead withdrawn-claim patterns) was refuted by re-measuring against whitespace-squashed surfaces, which is what the instrument matches.
- 2026-08-14: reinstalled with `build_vignettes = TRUE` after the review fixes and re-ran the installed-surface suite: FAIL 0 | WARN 5 | SKIP 0 | PASS 7788.
- 2026-08-13: plan corrected AC3 from "the count the surfaces actually carry" to a floor, the apparatus enforcing `>=` (`:1666-1670`) and its own comment (`:570-573`) calling floors deliberate, so the drafted wording was unverifiable; and added the `build_vignettes = TRUE` precondition without which five vignette legs skip silently.

## Decisions

## Review

Reviewed 2026-08-14 on `m119-residual-grid-doc-reconcile` at `f452c8c`, PR #128.

**AC1.** The walk `residual_runs_leg()` returns 6 source statements — `R/ci-classical.R #1`, `R/icc.R #1`, `R/icc.R #2`, `vignettes/glossary.Rmd #1`, `vignettes/interval-methods.Rmd #1`, `NEWS.md #1` — plus the `Rd:icc.Rd` mirrors on the installed leg, from the surfaces `width_legs()` enumerates; no path list is recorded anywhere. Every returned run carries `residual_template()` verbatim (checked TRUE per run). The walk's failure on a site still asserting residual invariance is exercised by the `m119_residual_restored` mutation, which reds. Re-measured the eight withdrawn patterns against whitespace-squashed surfaces at `c0a7500` and at HEAD: each has 1-2 hits pre-milestone and 0 now.

**AC2.** Recomputed from `width-reversal-by-cell.tsv`: fig2 t5/k=100 `median_ratio` = 1.2963, matching the shipped figure; all 10 cells of t10, laplace and t5 above 1 and all 10 of uniform, powexp and gaussian below 1, matching the shipped direction. From `classical-width-by-cell.tsv`: 2 distinct grids, so `n_grids`' "two"/"three" both check out. The figure is stated only in the `ratio_family` shape, whose `ok` closure reads the fixture cell the prose names; the shape test rejects the right number at the wrong family (Laplace, whose k=100 median is 1.2998), the right family at the wrong subject count, and an unmapped family name.

**AC3.** `width_expected_runs` is untouched on the branch (`git diff main..HEAD` shows no hunk over it), so every floor is at its pre-milestone value. Reinstalled with `build_vignettes = TRUE` after the three review fixes and re-ran `testthat::test_dir("tests/testthat", package = "intraclass", load_package = "installed")` under `NOT_CRAN=true`: FAIL 0 | WARN 5 | SKIP 0 | PASS 7788. Zero skips means both installed vignettes were on the walk. The five warnings sit in `test-icc-lavaan-multilevel.R`, `test-ci-bootstrap.R`, `test-icc-type-vector.R` and `test-icc-brms.R`, none a surface this milestone touches.

**AC4.** `Rscript data-raw/m117-width-pin-mutations.R`: both controls clean, every prose mutation refused, including the eight M119 forms — `m119_residual_restored/paraphrased/negated/hedge_dropped` on the article and `m119_scope_restored/paraphrased/negated/dropped` on the `?icc` roxygen.

**AC5.** `devtools::test()` filter clean; `cairn_validate` all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; `air format --check .` and `lintr::lint_package()` clean. All four `data-raw/` checkers pass: mpl-doc-claims 46 candidates / 0 failures (three rows re-triaged — two at implement, one at review for the narrowed pointer), record-claims 5/0, oracle-registry 0 gaps, reference-observations 0 unmarked / 0 falsified, abort-remedy 52 cells / 0 broken promises.

**Consistency gate.** `cairn_validate` clean (16 CHECK, 8 advisory). No principle changed, so `cairn_impact` was skipped. Toolchain slot: `document()` no-diff, generated files untouched by hand, pkgdown clean, NEWS carries the user-visible change, no new top-level files. `devtools::build_readme()` produces a diff on this machine — a glmmTMB/TMB version-mismatch warning and Monte-Carlo digit drift, neither from this branch — so README.md was left as committed.

**Fan-out.** Three fresh-context lenses, then a Sonnet scorer holding the diff and the plan. 16 findings; 3 actioned at >=80, 13 logged below the bar.

Actioned:
- D4 (82) — `R/ci-classical.R` restated a figure directly under its own comment forbidding that. Fixed: the rationale now states the M119 verbatim-clause exception and names which leg pins that copy.
- D7 (80) — `?icc` pointed at the article for "the measured figures" when the third grid's per-family figures are not tabulated there. Fixed: the pointer is scoped to the two subject-effect-only grids; ledger row re-keyed to `6522bd809a20`.
- D13 (80) — a duplicated lead-in in the article and NEWS, and "His" left ~14 lines from "Burch (2011)". Fixed: lead-in dropped, NEWS clause moved after the sentence carrying the pronoun.

Logged below the bar, not actioned: D1 (52) and D2 (50) — the walk's residual vocabulary is a three-token list and its runs must name Burch, so a synonym or a searle-only phrasing escapes; both are documented tradeoffs, and the enumeration they bound is fixed by author recall, which is the shape a future widening would repair. D3 (53) — `residual_scope_violations` matches three literal spellings of the grid pair. D5 (52) — the direction test's anti-vacuity assertion is a pairwise count equality, weaker than its comment claims. D6 (40) — the reference page's settling directive asserts only that the variable exists. D8 (56) — "the normal included" groups the gaussian with the lighter-tailed families. D9 (68) — "on what the residual is drawn from most of all" is a comparative-importance claim no fixture ranks. D10 (65) — the four break forms per claim funnel through two detectors. D11 (15), D12 (28), D14 (45), B1 (5, refuted by re-measurement), B2 (35).

The prior-PR-comments lens found no reintroduced finding across the seven previously-taught regression classes and recorded that `gh api .../pulls/comments` returns empty — this repo's review record lives in `cairn/milestones/archive/`.
