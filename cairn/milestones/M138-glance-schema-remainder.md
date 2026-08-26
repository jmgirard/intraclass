# M138: Exported-schema remainder — `glance()` gains a rater accessor before the one-way door closes

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2

## Goal

Land the three exported-schema corrections descoped from M48 while GP2's one-way door is still open, so no post-submission change to `glance()` or `tidy()` needs a deprecation cycle.

## Scope

**Surface tier: user-facing** — the deliverable is the columns and ptypes user code reads off `glance()` and `tidy()`.

**In:** (a) `glance.icc()` gains a `raters` column (the fit's rater treatment) and a `replicates` logical, per the plan gate; (b) `tidy()$occasions` gets one ptype across all fits, currently `integer` on a plain fit and `numeric` on a replicate fit; (c) `?icc`'s false sentence that `tidy()`/`glance()` "return the same information" as the object (`R/icc.R:668`, `man/icc.Rd:472`) is replaced.

**Out:** a `type` column on `glance()` — refused at the plan gate, `type` being a per-coefficient report-all axis `tidy()` already carries per row (D-037), recorded in this milestone's D-entry. Freezing `glance()`'s column *order* as contract → candidate row; the plan gate declined to promote order to a GP2-bound promise. The remaining M48 remainder items → M140.

## Acceptance criteria

- [ ] AC1. `glance()` on an `icc` fit returns a `raters` column holding the fit's rater treatment as a character scalar, and a `replicates` logical column holding whether the design has within-cell replicates. `raters` is `NA_character_` on a `model = "oneway"` fit, which has no rater facet.
- [ ] AC2. `names(glance(fit))` is the same character set on every fit the AC1 test constructs — the design families being one-way, two-way random-rater, two-way fixed-rater, multilevel, and within-cell-replicate — so a `glance()` row from any of them row-binds with a row from any other.
- [ ] AC3. `typeof(tidy(x)$occasions)` is `"integer"` for each of: a plain fit, a within-cell-replicate fit, a `d_study()` projection of the plain fit, and a `d_study()` projection of the replicate fit; and `rbind()` over all four tidied frames returns `nrow()` equal to the sum of the four.
- [ ] AC4. No line matched by `grep -rn "same information" R/ man/ NEWS.md README.md vignettes/` claims that `tidy()` or `glance()` reproduces the `icc` object's contents.
- [ ] AC5. `devtools::check()`'s raw `Status:` line reports 0 errors, 0 warnings, 0 notes, and `devtools::test()` at `NOT_CRAN=true CI=true` reports FAIL 0.

## Coverage

- AC1 → T2, T3
- AC2 → T2, T3
- AC3 → T4, T5
- AC4 → T6
- AC5 → T7

## Tasks

- [ ] T1. Write the failing tests first in `tests/testthat/test-exported-contract.R`: the five design families for AC1/AC2 and the four ptype probes for AC3. Red before any source edit.
- [ ] T2. Add `raters` and `replicates` to `glance.icc()` (`R/icc-methods.R:376-410`), sourcing `raters` from `x$design$raters` with `NA_character_` on `model == "oneway"`, and `replicates` from `isTRUE(x$design$replicates)`.
- [ ] T3. Update the `glance.icc()` bullet in `R/icc.R:677-683` and re-roxygenize; add a NEWS bullet under the 0.1.0 changelog.
- [ ] T4. Cast `tidy.icc()$occasions` to integer in both branches (`R/icc-methods.R:357-361`).
- [ ] T5. Do the same for the `d_study()` projection path (`R/d-study.R:524`, `R/d-study.R:704`), whose `occasions` column feeds `tidy.icc_dstudy()`.
- [ ] T6. Replace the `R/icc.R:668` sentence; re-roxygenize so `man/icc.Rd:472` follows; run the AC4 grep.
- [ ] T7. Append a D-entry recording what `glance()` gained, that `type` was refused and why, and that column order is deliberately not contract. Run `air format .`, the four `data-raw/` checkers with `--self-test`, then `devtools::check()`.

## Work log

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on 4 of 5 drafted criteria. Fixed at the gate: the "every fit the suite constructs" universal narrowed to the enumerated probes (bounded-promise); the "no shipped sentence" universal replaced with a named grep (bounded-promise); the exact-names test pin and the D-entry moved from criteria to tasks (instrument-bound, D-118). One finding posed at the question gate (what `glance()` gains).
- 2026-08-26: plan gate chose adding `raters` + `replicates` over `raters` alone because `n_o` is also `NA` on ragged replicates, so replicate status is not losslessly inferable from the shipped columns; falsified by a user reading `replicates` off `n_o` correctly on a ragged design.
- 2026-08-26: plan gate chose freezing `glance()`'s column NAMES as a set over freezing their ORDER because GP2 would make any later reordering a deprecation-cycle item for no user-visible gain; falsified by a consumer that indexes `glance()` positionally.
