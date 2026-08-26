# M138: Exported-schema remainder — `glance()` gains a rater accessor before the one-way door closes

- **Status:** in-progress
- **Branch:** `m138-glance-schema-remainder`
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2

## Goal

Land the three exported-schema corrections descoped from M48 while GP2's one-way door is still open, so no post-submission change to `glance()` or `tidy()` needs a deprecation cycle.

## Scope

**Surface tier: user-facing** — the deliverable is the columns and ptypes user code reads off `glance()` and `tidy()`.

**In:** (a) `glance.icc()` gains a `raters` column (the fit's rater treatment) and a `replicates` logical, per the plan gate; (b) `tidy()$occasions` gets one ptype across all fits, currently `integer` on a plain fit and `numeric` on a replicate fit; (c) `?icc`'s false sentence that `tidy()`/`glance()` "return the same information" as the object (`R/icc.R:668`, `man/icc.Rd:472`) is replaced. (d) `glance()` on a `d_study()` projection of a `model = "oneway"` fit reports `raters` as `NA_character_` rather than the untouched `"random"` default, so the `raters` column reads the same on both exported tables for that design. Designs with no rater facet other than `model = "oneway"` — the multilevel nested-rater Design 3 — deliberately keep their nominal `"random"`, matching the sibling `type` column's convention there.

**Out:** a `type` column on `glance()` — refused at the plan gate, `type` being a per-coefficient report-all axis `tidy()` already carries per row (D-037), recorded in this milestone's D-entry. Freezing `glance()`'s column *order* as contract → candidate row; the plan gate declined to promote order to a GP2-bound promise. The remaining M48 remainder items → M140.

## Acceptance criteria

- [ ] AC1. `glance()` on an `icc` fit returns a `raters` column holding the fit's rater treatment as a character scalar, and a `replicates` logical column holding whether the design has within-cell replicates. `raters` is `NA_character_` on a `model = "oneway"` fit, which has no rater facet.
- [ ] AC2. `names(glance(fit))` is the same character set on every fit the AC1 test constructs — the design families being one-way, two-way random-rater, two-way fixed-rater, multilevel, and within-cell-replicate — so a `glance()` row from any of them row-binds with a row from any other.
- [ ] AC3. `typeof(tidy(x)$occasions)` is `"double"` for each of: a two-way random-rater fit with one rating per cell; a single-level balanced within-cell-replicate fit; a `d_study()` rater-axis projection of each of those two; a `d_study()` rater-axis projection of a multilevel within-cell-replicate fit; an occasion-axis `d_study(n_o = 1:3)` projection of the single-level replicate fit; and an occasion-axis `d_study(n_o = c(1, 1.5, 2))` projection of that same fit, whose `sort(unique(tidy(.)$occasions))` is `c(1, 1.5, 2)`. `rbind()` over the two tidied fit frames, and separately `rbind()` over the five tidied projection frames, each returns `nrow()` equal to the sum of its inputs.
- [ ] AC4. No line matched by `grep -rn "same information" R/ man/ NEWS.md README.md vignettes/` claims that `tidy()` or `glance()` reproduces the `icc` object's contents.
- [ ] AC5. `devtools::check()`'s raw `Status:` line reports 0 errors, 0 warnings, 0 notes, and `devtools::test()` at `NOT_CRAN=true CI=true` reports FAIL 0.
- [ ] AC6. `glance(d_study(fit, m = 1:3))$raters` is `NA_character_` when `fit` is a `model = "oneway"` fit. It is `"random"` on a two-way random-rater fit, `"fixed"` on a two-way `raters = "fixed", type = "consistency"` fit, and `"random"` on a multilevel `ml_design = "nested_in_subjects"` (Design 3) fit — which has no rater facet but is not `model = "oneway"`. On an occasion-axis `d_study(fit, n_o = 1:3)` projection of a balanced `raters = "fixed", type = "agreement"` within-cell-replicate fit it is `"fixed"`.

## Coverage

- AC1 → T2, T3
- AC2 → T2, T3
- AC3 → T4, T5
- AC4 → T6
- AC5 → T7
- AC6 → T8

## Tasks

- [x] T1. Write the failing tests first in `tests/testthat/test-exported-contract.R`: the five design families for AC1/AC2 and the four ptype probes for AC3. Red before any source edit.
- [x] T2. Add `raters` and `replicates` to `glance.icc()` (`R/icc-methods.R:376-410`), sourcing `raters` from `x$design$raters` with `NA_character_` on `model == "oneway"`, and `replicates` from `isTRUE(x$design$replicates)`.
- [x] T3. Update the `glance.icc()` bullet in `R/icc.R:677-683` and re-roxygenize; add a NEWS bullet under the 0.1.0 changelog.
- [x] T4. Make `tidy.icc()$occasions` double in both branches (`R/icc-methods.R:357-361`): `as.numeric()` on the replicate branch, `NA_real_` replacing `NA_integer_` on the other.
- [x] T5. Do the same for the `d_study()` projection path: coerce the column at `R/d-study.R:524` (an integer `n_o` reaches it uncoerced) and fill with `NA_real_` at `R/d-study.R:704`.
- [ ] T6. Replace the `R/icc.R:668` sentence; re-roxygenize so `man/icc.Rd:472` follows; run the AC4 grep.
- [ ] T8. Set `d_study()`'s `icc_raters` attribute to `NA_character_` on a `model = "oneway"` fit (`R/d-study.R:531`), keying on `oneway` and not on `ml_oneway`; check `icc_design_phrase()`'s NA path stays unreached. Probe the four AC6 fits.
- [ ] T7. Append a D-entry recording what `glance()` gained, that `type` was refused and why, and that column order is deliberately not contract. Run `air format .`, the four `data-raw/` checkers with `--self-test`, then `devtools::check()`.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on 4 of 5 drafted criteria. Fixed at the gate: the "every fit the suite constructs" universal narrowed to the enumerated probes (bounded-promise); the "no shipped sentence" universal replaced with a named grep (bounded-promise); the exact-names test pin and the D-entry moved from criteria to tasks (instrument-bound, D-118). One finding posed at the question gate (what `glance()` gains).
- 2026-08-26: plan gate chose adding `raters` + `replicates` over `raters` alone because `n_o` is also `NA` on ragged replicates, so replicate status is not losslessly inferable from the shipped columns; falsified by a user reading `replicates` off `n_o` correctly on a ragged design.
- 2026-08-26: plan gate chose freezing `glance()`'s column NAMES as a set over freezing their ORDER because GP2 would make any later reordering a deprecation-cycle item for no user-visible gain; falsified by a consumer that indexes `glance()` positionally.
- 2026-08-26: implement question gate — measured `tidy()$occasions` across five probes and chose `double` everywhere over `integer`, because `validate_n_o()` (`R/d-study.R:570`) documents non-integer occasion counts as allowed and `as.integer()` would report a projected 1.5 as 1; falsified by a caller for whom a whole-number occasion column is load-bearing. AC3 amended (see below).
- 2026-08-26: implement question gate — chose fixing `glance.icc_dstudy()$raters` on a one-way projection inside M138 over filing it, because after submission the change is a deprecation-cycle item; falsified by a consumer relying on that cell reading `"random"`. Scope In gains clause (d), plus AC6.
- 2026-08-26: implement gate — chose `model = "oneway"` alone as the `NA_character_` predicate over "every design with no rater facet", because the sibling `type` column reports `"agreement"` on a Design 3 fit where the agreement/consistency distinction is undefined, so widening `raters` alone would split the two columns' convention; falsified by a user reading Design 3's `raters` as a rater facet that exists. Design 3 → candidate row.
- 2026-08-26: amendment return: AC3 — "`typeof(tidy(x)$occasions)` is `"double"` for each of: a two-way random-rater fit with one rating per cell; a single-level balanced within-cell-replicate fit; a `d_study()` rater-axis projection of each of those two; a `d_study()` rater-axis projection of a multilevel within-cell-replicate fit; an occasion-axis `d_study(n_o = 1:3)` projection of the single-level replicate fit; and an occasion-axis `d_study(n_o = c(1, 1.5, 2))` projection of that same fit, whose `sort(unique(tidy(.)$occasions))` is `c(1, 1.5, 2)`."
- 2026-08-26: amendment audit ran in FULL mode (user-facing tier) over the amended AC3 and the new AC6, twice, each with a fresh-context [O] reader that authored neither. Round 1 returned 7 findings: the cross-family `rbind()` clause was unsatisfiable (differing column sets), the occasion-axis probe named a fit that aborts, the "values are still `c(1, 1.5, 2)`" clause was false under per-curve recycling, the probes missed the multilevel construction path, AC6's two-way half was under-specified, and Design 3's carve-out was unpinned. Round 2 returned 7 more (ambiguous antecedents, an undefined "plain fit", an unstated "unchanged" baseline, T4/T5 contradicting the amended AC3). All fixed; one round-1 finding went to the user as the Design 3 predicate question.
- 2026-08-26: round 2's ground claim that the only integer sites are the two NA fills is false — measured `typeof(tidy(d_study(rep_fit, n_o = 1:3))$occasions)` as `"integer"`, an integer `n_o` reaching the column uncoerced. T5 amended to coerce at `R/d-study.R:524`, and AC3 gained the integer-`n_o` probe that sees it.
- 2026-08-26: T4/T5 amended from "cast to integer" to the double coercion above (minor task edit executing the AC3 amendment); T8 added for AC6.
- 2026-08-26: T1 — tests written first in `test-exported-contract.R` section 4 (three test_that blocks, two new fixture frames). Run red: 10 failures, all in the new blocks, the rest of the file green. The three `occasions` failures locate the integer sites as the plain fit, the plain rater-axis projection, and the integer-`n_o` occasion axis.
- 2026-08-26: T2 — `glance.icc()` gains `raters` (NA on a one-way fit) and `replicates`, placed beside `balanced`. AC1 and AC2 tests go green; the suite's only remaining reds are the four the occasions and projection criteria own.
- 2026-08-26: T3 — `?icc`'s `glance.icc()` bullet and the NEWS "Reading a fit" bullet name both new columns; the NEWS sentence saying the row cannot tell a random-rater from a fixed-rater `var_rater` is now false and was rewritten in place. Re-roxygenized; `man/icc.Rd` follows.
- 2026-08-26: T4-T5 — `occasions` is double on both `tidy()` methods: `as.numeric()` on the replicate branch, `NA_real_` on the other, `as.numeric(row_occ)` at the projection's `add_column()` (the site an integer `n_o` reaches uncoerced) and `NA_real_` at the projection fill. NEWS gains the ptype sentence. AC3 green; AC6's is the suite's only remaining red.
