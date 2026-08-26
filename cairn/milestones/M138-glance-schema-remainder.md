# M138: Exported-schema remainder — `glance()` gains a rater accessor before the one-way door closes

- **Status:** review
- **Branch:** `m138-glance-schema-remainder`
- **PR:** https://github.com/jmgirard/intraclass/pull/148
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

- [x] AC1. `glance()` on an `icc` fit returns a `raters` column holding the fit's rater treatment as a character scalar, and a `replicates` logical column holding whether the design has within-cell replicates. `raters` is `NA_character_` on a `model = "oneway"` fit, which has no rater facet.
- [x] AC2. `names(glance(fit))` is the same character set on every fit the AC1 test constructs — the design families being one-way, two-way random-rater, two-way fixed-rater, multilevel, and within-cell-replicate — so a `glance()` row from any of them row-binds with a row from any other.
- [x] AC3. `typeof(tidy(x)$occasions)` is `"double"` for each of: a two-way random-rater fit with one rating per cell; a single-level balanced within-cell-replicate fit; a `d_study()` rater-axis projection of each of those two; a `d_study()` rater-axis projection of a multilevel within-cell-replicate fit; an occasion-axis `d_study(n_o = 1:3)` projection of the single-level replicate fit; and an occasion-axis `d_study(n_o = c(1, 1.5, 2))` projection of that same fit, whose `sort(unique(tidy(.)$occasions))` is `c(1, 1.5, 2)`. `rbind()` over the two tidied fit frames, and separately `rbind()` over the five tidied projection frames, each returns `nrow()` equal to the sum of its inputs.
- [x] AC4. No line matched by `grep -rn "same information" R/ man/ NEWS.md README.md vignettes/` claims that `tidy()` or `glance()` reproduces the `icc` object's contents.
- [x] AC5. `devtools::check()`'s raw `Status:` line reports 0 errors, 0 warnings, 0 notes, and `devtools::test()` at `NOT_CRAN=true CI=true` reports FAIL 0.
- [x] AC6. `glance(d_study(fit, m = 1:3))$raters` is `NA_character_` when `fit` is a `model = "oneway"` fit. It is `"random"` on a two-way random-rater fit, `"fixed"` on a two-way `raters = "fixed", type = "consistency"` fit, and `"random"` on a multilevel `ml_design = "nested_in_subjects"` (Design 3) fit — which has no rater facet but is not `model = "oneway"`. On an occasion-axis `d_study(fit, n_o = 1:3)` projection of a balanced `raters = "fixed", type = "agreement"` within-cell-replicate fit it is `"fixed"`.

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
- [x] T6. Replace the `R/icc.R:668` sentence; re-roxygenize so `man/icc.Rd:472` follows; run the AC4 grep.
- [x] T8. Set `d_study()`'s `icc_raters` attribute to `NA_character_` on a `model = "oneway"` fit (`R/d-study.R:531`), keying on `oneway` and not on `ml_oneway`; check `icc_design_phrase()`'s NA path stays unreached. Probe the four AC6 fits.
- [x] T7. Append a D-entry recording what `glance()` gained, that `type` was refused and why, and that column order is deliberately not contract. Run `air format .`, the four `data-raw/` checkers with `--self-test`, then `devtools::check()`.

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
- 2026-08-26: T8 — `icc_raters` is `NA_character_` on a one-way projection, keyed on `oneway` and not `ml_oneway`; `icc_design_phrase()` gained an NA guard so the legacy-object fallback in `format.icc_dstudy()` cannot return `character(0)` if it is ever reached. Suite: FAIL 0, PASS 8624, WARN 2 (both pre-existing). The three new fixed-rater fits wrap in `suppressWarnings()`, the file's existing idiom for the teaching warning.
- 2026-08-26: T6 — the `?icc` sentence now says `tidy()`/`glance()` are the stable tables rather than a re-export of the list. `man/icc.Rd` re-roxygenized. AC4 grep returns nothing; a control pattern over the same five paths returns hits, so the domain is non-empty. `README.Rmd` carries no match either.
- 2026-08-26: T7 — D-038 appended. `air format .` clean; the six `data-raw/` checkers pass (the four Python ones under `--self-test`, each reporting every mutation red on a green baseline); `cairn_validate` passes, its single advisory being M139's release window, not this milestone. First `devtools::check()` came back `Status: 1 NOTE` on an unlisted NEWS word; reworded rather than extending the wordlist, and the re-run reports `Status: OK`. Final `devtools::test()` at `NOT_CRAN=true CI=true`: FAIL 0, WARN 2 (both pre-existing), SKIP 26, PASS 8624.
- 2026-08-26: all tasks done; status to review.
- 2026-08-26: review — six criteria verified with fresh evidence; `devtools::check()` `Status: OK` (0/0/0), `devtools::test()` FAIL 0 / PASS 8624; `cairn_validate` and the `r-package` consistency-gate slot clean; three fresh-context lenses ran, two reporting nothing and the [O] lens returning nine findings, none reaching the return floor.

## Review

Reviewed 2026-08-26 on PR #148, branch at `3fae1f9`. `origin/main` had not moved since the branch was cut (`git rev-list --left-right --count origin/main...HEAD` → `0 7`), so no merge was needed and the evidence below is fresh against the merge base. No `Driving RR:`, so the projection-vs-outcome record no-ops.

### Acceptance-criteria evidence

- **AC1 — verified.** A standalone probe (not the suite) built the five families and glanced each. `raters` is `character`, length 1 on every fit, reading `NA, random, fixed, random, random` across one-way / two-way random / two-way fixed / multilevel / replicate; `identical(glance(oneway)$raters, NA_character_)` is `TRUE`. `replicates` is `logical`, reading `FALSE, FALSE, FALSE, FALSE, TRUE` over the same order.
- **AC2 — verified.** Same probe: `setequal()` of `names(glance(fit))` against the first family holds for all five; the shared set is the 24 columns `n_subjects … ess_bulk`. `nrow(do.call(rbind, gls))` is 5 for 5 inputs.
- **AC3 — verified.** `typeof(tidy(x)$occasions)` is `"double"` on both named fits and on all five named projections (rater-axis of the two-way, of the single-level replicate, and of the multilevel replicate fit; `n_o = 1:3`; `n_o = c(1, 1.5, 2)`). `identical(sort(unique(.)), c(1, 1.5, 2))` is `TRUE` on the fractional sweep. `rbind()` over the two fit frames returns `nrow()` 8 against a sum of 8; over the five projection frames, 28 against 28.
- **AC4 — verified.** `grep -rn "same information" R/ man/ NEWS.md README.md vignettes/` returns no lines (exit 1). Two control patterns over the same five paths return hits — `glance` across `R/`, `man/`, and `vignettes/`, and `tidy` inside `NEWS.md`/`README.md` — so no path in the domain is silently empty.
- **AC6 — verified.** Same probe: `identical(glance(d_study(oneway, m = 1:3))$raters, NA_character_)` is `TRUE`; the two-way random projection reads `"random"`, the `raters = "fixed", type = "consistency"` projection `"fixed"`, and the Design 3 fit (measured `ml_design = "nested_in_subjects"`, `model = "twoway"`) `"random"`. The occasion-axis `d_study(n_o = 1:3)` projection of the balanced `raters = "fixed", type = "agreement"` replicate fit reads `"fixed"`.
- **AC5 — verified.** `devtools::check()` on the branch: raw `Status: OK`, reported as `0 errors | 0 warnings | 0 notes`, duration 23m. `devtools::test()` at `NOT_CRAN=true CI=true`: `FAIL 0 | WARN 2 | SKIP 26 | PASS 8624`; both warnings are the pre-existing teaching warnings (a Design 3 fit dropping `"consistency"`, and `ci_method = "mpl"` doing the same) already present on `main`.

### Consistency gate

Universal cairn-file checks: `cairn_validate.py` exits 0 — 16 PASS, 6 OK, one advisory (`release window`, naming M139, not this milestone). The branch changes no `DESIGN.md` principle, so `cairn_impact.py` does not apply.

Toolchain checks from the `r-package` profile's `consistency-gate` slot: `devtools::document()` leaves no diff; `NAMESPACE`, `man/`, and `data/*.rda` are unmodified apart from the roxygen-regenerated `man/icc.Rd` in the diff; `README.Rmd`/`README.md` are untouched by the branch and last committed together; `pkgdown::check_pkgdown()` reports no problems, and the branch exports nothing new so no reference-index row is owed; `NEWS.md` carries entries for all four user-visible changes; no top-level file is added, so no `.Rbuildignore` entry is owed; the full `devtools::check()` is the AC5 line above. `air format --check .` is clean.

### Findings

Three fresh-context lenses ran, none having authored the implementation. The [S] blame-history lens reported no findings after tracing every modified line to its originating commit. The [S] prior-review-record lens reported no findings: the archived `## Review` record shows this diff resolves M48's three deferred rows (P3/P4/P6) rather than contradicting them, and the GitHub inline-comment probe returned `[]`, so that surface holds no evidence. The [O] diff-bug lens ran every AC probe itself and found no wrong value, returning nine findings on documentation accuracy, coverage, and scope, ranked below as it ranked them.

1. **`?icc`'s replacement sentence contradicts the stability rule three lines above it.** `R/icc.R:670-671` (and `man/icc.Rd:474-475`) now say "Anything in the object that neither one gives a column is exactly what this rule calls internal." Neither `tidy()` nor `glance()` gives a column for `$fit` or `$call`, which the same paragraph has just named as the two elements a user may depend on. A reader following the new sentence literally concludes `$fit` — the documented hand-off to `predict()`/`emmeans` — is internal. AC4 greps only for `"same information"`, so nothing catches the replacement being false in a new way. Verified against `R/icc.R` as shipped on the branch.
2. **The `replicates` column's documented meaning is false on a one-way fit of replicated data.** `R/icc.R:683-685`, the code comment at `R/icc-methods.R:387-391`, and the NEWS bullet all define it as "whether the design holds more than one rating per subject-by-rater cell". `icc()` sets `replicates <- FALSE` unconditionally on the one-way path (`R/icc.R:1372`, deliberate — rater identity is ignored), so a one-way fit of data with two ratings in every cell reports `FALSE`. The column reports whether the fitted design took the replicate split, not what the data holds. AC1 probes one-way only on `ratings`, which has no replicates, so it cannot discriminate this.
3. **`?d_study`'s `glance.icc_dstudy()` bullet was not updated for scope clause (d).** `R/d-study.R:139-141` and `man/d_study.Rd` still say the projection glance "carries … the rater treatment", with no note that it is `NA` on a one-way projection — while the sibling `?icc` bullet did get exactly that note. AC6 pins the behavior; no criterion pins its documentation.
4. **The new `is.na(raters)` branch in `icc_design_phrase()` is unreachable by any shipped path and untested.** `R/estimand.R:225-229`. Its call sites are `R/choose-icc.R:588` (one-way takes a separate branch) and the legacy-object fallbacks at `R/d-study.R:616` / `R/autoplot.R:39-42`, which fire only for objects predating `icc_design_label` — objects that never carried `NA` in `icc_raters`.
5. **`glance.icc()` on a Design 3 fit is unpinned, though the D-entry makes a claim about it.** The new test pins `glance(d_study(d3, m = 1:3))$raters` but never `glance(d3)$raters`; AC1's "multilevel" family is Design 1. Measured `glance(d3)$raters` as `"random"`, so the two tables agree today, but a later widening of the `glance.icc()` predicate would split them with no red.
6. **AC3's `rbind()` clauses do not discriminate the change.** `rbind()` over data frames with an `integer` column and a `double` column succeeds and returns the summed `nrow()`, so both `rbind` assertions pass unchanged on `main`; only the `typeof()` loop reds on revert. A criterion-strength observation, not a defect in the code.
7. **NEWS's "instead of rounding it" describes a rounding that never occurred.** On `main` a fractional sweep already reached `tidy()` as `1.5`; the pre-change integer sites were the two `NA` fills and the integer-`n_o` pass-through. The contrast is with the rejected `as.integer()` design, not with anything the package did.
8. **Redundant coercion in `tidy.icc()`'s replicate branch.** `R/icc-methods.R:359`: `x$estimates$occasions` is built by `vapply(..., numeric(1), ...)` at `R/icc.R:2491`, so it is already double and `as.numeric()` is a no-op. Only the `NA_real_` fill on the other branch changes behavior.
9. **Unrelated prose edits to two ROADMAP candidate rows rode in on `d35476f`.** The "checkpoint guard's known blind spots" and "M104's deferred remainder" rows were reworded (en-dash → hyphen, "vacuously true" → "vacuous", clause trims) in a commit whose subject is the AC3/AC6 amendment. Nothing is factually wrong; the edits are outside M138's scope and unlogged. Verified against `git diff main..HEAD -- cairn/ROADMAP.md`.

**Return floor.** No finding demonstrates an acceptance criterion failing. Finding 2 is the closest: AC1 promises a `replicates` column "holding whether the design has within-cell replicates", and on a one-way fit the column does report the fitted design's own `replicates` field, which is `FALSE` because a one-way design has no subject-by-rater cells; what is false is the prose in `?icc` and NEWS, which describes the column as a fact about the data layout. So the milestone does not return under the floor, and every finding takes ordinary triage at the gate.
