# M146: The occasion vocabulary says which quantity each surface reports

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** `m146-occasions-vocabulary` / https://github.com/jmgirard/intraclass/pull/157

## Goal

Close the documentary gap D-044 left open: every surface reporting an occasion
count says whether it counts ratings averaged or occasions observed.

## Scope

Surface tier: **user-facing** — reference-manual prose, plot labels and
vignette prose a user reads. No exported name, type or column set changes;
D-044 settled that the columns ship as they are.

**In:** the `tidy()$occasions` meaning sentence and its contrast with
`glance()$n_o`; the `autoplot()` legend labels that currently name the
averaging divisor with the design-count symbol; the vignette prose that mimics
a call `validate_occasions()` rejects; glossary entries for both quantities;
the `d_study()` roxygen wording that uses `n_o` for held and swept counts in
one bullet.

**Out:** the printed d-study header fork `occ`/`n_o` (`R/d-study.R:667`) stays
as shipped — RR05 §5 holds it correct, each surface naming the quantity it
displays, and it is `print()` surface D-044 does not reach. Not deferred work;
a decided non-change, revisitable before submission at no cost. Renaming or
removing either column → refused, D-044.

## Acceptance criteria

- [ ] AC1. The `tidy.icc()` column list in `R/icc.R`'s roxygen (rendered into
      `man/icc.Rd`) states that `occasions` reports the per-rater occasion
      divisor the row's coefficient applies to pure error: on a fit that splits
      within-cell replicates, 1 wherever the row averages no occasions — every
      single-occasion row, and every row whose error set carries no pure-error
      term to average — and the fitted per-cell occasion count where it does
      average; `NA` on a fit that splits none. It states that this is not in
      general the number of ratings the coefficient averages, since it counts
      occasions per rater: an occasion-averaged `ICC(*,k)` row averages `k`
      raters at that occasion count each. It states that `glance()$n_o` reports
      the observed per-cell occasion count of the fitted design instead — `NA`
      under the condition the `glance.icc()` bullet on the same page states,
      which a ragged replicate fit meets while `occasions` still reads 1. The
      `tidy.icc_dstudy()` column list states that its own `occasions` is the
      occasion count the row is projected at, which may be non-integer, and
      that it divides pure error, so a row whose error set carries no
      pure-error term does not move with it; it names the value the column
      takes on each projection axis — on the rater axis every distinct value
      the fit's own `occasions` column carries, on the occasion axis the swept
      `n_o` — and what the cluster rows of a multilevel projection take on
      each. It carries no `glance()` contrast, which has no referent there.
- [x] AC2. Over the plots `autoplot()` draws from a replicated fit — the cells
      enumerated by crossing the fit's `type` set (one or both definitions),
      its `occasions` set (one or both settings), and the two `icc_dstudy`
      projection axes — no legend title and no legend key text contains the
      string `n_o`. Where `occasions` is the only curve-identity column the
      legend title reads `Occasions averaged` and each key reads
      `occasions: <value>`; where it is not, the criterion asserts only the
      absence above. The occasion-axis x-axis label (`R/autoplot.R:30`) is
      unchanged.
- [x] AC3. No prose in `vignettes/`, `README.Rmd`, `NEWS.md` or the roxygen
      under `R/` writes the `occasions` argument with a numeric value, in any
      spacing or quoting, measured over whitespace-collapsed text by a test
      that sweeps those paths. The paragraphs describing the single-occasion
      and occasion-averaged rows in `vignettes/d-studies-and-replicates.Rmd`
      name the `occasions` column rather than a call.
- [x] AC4. `vignettes/glossary.Rmd` carries an entry for occasion / within-cell
      replicate stating that the per-cell count `print()` reports on the design
      line as `N cells x N replicates` is the same quantity as `glance()$n_o`,
      and an entry stating that `tidy()$occasions` counts ratings averaged into
      a coefficient while `glance()$n_o` counts occasions observed per cell.
- [x] AC5. The `d_study()` roxygen at `R/d-study.R:73-86` calls the held count
      "the fitted occasion count" and uses `n_o` only for the swept argument.
- [x] AC6. `R CMD check`'s raw Status line reports no ERROR, WARNING or NOTE;
      `air format --check .` clean; `lintr::lint_package()` clean.

## Coverage

- AC1 → T1, T2, T15, T16, T17
- AC2 → T3, T4
- AC3 → T5
- AC4 → T6
- AC5 → T7
- AC6 → T8

## Tasks

- [x] T1. Write the meaning sentence and the `glance()$n_o` contrast into the
      `tidy.icc()` column list (`R/icc.R:675-680`); mirror the meaning sentence
      alone into `tidy.icc_dstudy()`'s list, stating the projection's own
      `NA` rule (outside a replicate projection, `R/d-study.R:136`). Document.
- [x] T2. Pin the AC1 sentences on the installed surface per
      `cairn/doctrine/doc-claim-pins.md`: read via `tools::Rd_db()`, search
      whitespace-collapsed text, pin a backtick-free spelling, and
      mutation-verify each pin red.
- [x] T3. `R/autoplot.R:58` keys → `occasions: <value>`; `:69-70` title →
      `Occasions averaged`; leave `:30`.
- [x] T4. Extend `tests/testthat/test-autoplot.R` over AC2's cells, using that
      file's existing build-based idiom (`built_layer()`), asserting legend
      title and key text; include the suppressed-legend and `"Curve"`-branch
      cells as cases that assert only the `n_o` absence.
- [x] T5. Rephrase the two paragraphs at
      `vignettes/d-studies-and-replicates.Rmd:177,179`; add the AC3 sweep to
      `tests/testthat/test-vignette-claims.R`, skipping on `dir.exists()` as
      that file already does for source-tree paths (M129).
- [x] T6. Add the two `vignettes/glossary.Rmd` entries.
- [x] T7. Wording pass on `R/d-study.R:73-86`. Document.
- [x] T8. Run every `data-raw/` checker with `--self-test` before pushing — a
      roxygen edit inside the `ci_method` doc scope re-keys the MPL
      doc-claims ledger (M130) — then the gate: `air format .`,
      `lintr::lint_package()`, `R CMD check` raw Status line.

Repair tasks (the 2026-08-28 defect return; see the Review section's findings):

- [x] T9. Make `tidy.icc_dstudy()`'s `occasions` sentence true on every
      projection it covers (finding 2), and state `n_o`'s own `NA` case in the
      `tidy.icc()` contrast (finding 6, roxygen half). Re-pin both in
      `test-occasions-vocabulary.R` and mutation-verify. Document.
- [x] T10. Repair the pin's surface selection so a source-tree run cannot
      validate a stale installed copy (finding 5), and correct the
      `R/autoplot.R` curve-identity comment, which is false of the occasion
      axis (finding 7).
- [x] T11. Correct the rater-axis bullet's pure-error divisor (finding 4),
      keeping AC5's "the fitted occasion count" where it is accurate.
- [x] T12. Qualify the glossary's *Occasion* entry, whose `print()` claim is
      false on a multilevel replicate fit (finding 1), and add `n_o`'s `NA`
      case to the `occasions` vs. `n_o` entry (finding 6, glossary half).
- [x] T13. Take the `d-studies-and-replicates.Rmd` dash count back to zero
      (finding 3).
- [x] T14. Re-run the T8 gate.

Repair tasks (the second 2026-08-28 defect return, and the AC1 amendment):

- [x] T15. Measure what `occasions` reads across every design class and both
      projection axes, and record the grid in the work log. Every clause of the
      amended AC1 is derived from it, none from recall.
- [ ] T16. Rewrite both roxygen column lists to the amended AC1 (`R/icc.R`'s
      `tidy.icc()` list, `R/d-study.R`'s `tidy.icc_dstudy()` list). Document.
- [ ] T17. Re-pin the amended sentences in `test-occasions-vocabulary.R` and
      mutation-verify each pin red; add a GENERATED design-axis grid
      (`model`, `cluster`, `design`, replicate shape, `occasions` request,
      projection axis) asserting the documented rule on every row of every
      case, in the `test-n-o-disposition-grid.R` idiom (case set generated,
      joined to expectations by axis values, both directions asserted).
- [ ] T18. Round-2 findings 4, 7 and 8: correct `d_study()`'s occasion-curve
      bullet (`R/d-study.R:76-79`), whose curve set is the fit's own distinct
      `occasions` values and whose pure-error divisor is `m` times the curve's
      setting, and the `R/autoplot.R:50-51` comment finding 4 falsifies.
      Document.
- [ ] T19. Round-2 finding 10: the glossary's "wherever the design line carries
      one" is imprecise — a ragged replicate fit prints `60 cells x NA
      replicates`, so the slot is always there and it is the count that is not.
- [ ] T20. Re-run the T8 gate.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: plan-gate criteria audit ran in FULL mode (user-facing tier);
  returned 17 findings. Ten repaired before writing: AC2's enumeration named
  cells that do not exist (`what` is not an argument of the method that emits
  the legend) and its second clause was false on two reachable plots; AC1's
  `tidy.icc_dstudy()` half demanded a contrast with no referent; AC3 was
  phrased as a grep command, lacked `-r`, and its regex missed spacing,
  quoting and wrapped forms; AC4 misdescribed `print()`'s design line as a
  header; AC1 and AC5 mis-cited line ranges. Two went to the user.
- 2026-08-28: plan gate chose leaving the printed d-study header fork over
  changing `occ` to `occasions`, because RR05 §5 argues the fork is correct on
  its own governing rule and the header is `print()` surface D-044 does not
  reach; falsified by a user reading the rater-axis header as the swept count.
- 2026-08-28: plan gate chose legend keys reading `occasions: <value>` over
  RR05 rec 2's `occasions = <value>`, because the milestone removes that same
  call-mimicking form from vignette prose in AC3 and installing it on a plot
  would treat one string two ways; falsified by a reader taking the colon form
  as a typo rather than a label. Both changed criteria narrow their promise
  rather than widen it, so they were not re-audited.
- 2026-08-28: rename and removal were settled before planning by RR05/D-044,
  not weighed at this gate.
- 2026-08-28: T1 done. `tidy.icc()`'s column list now states the ratings-averaged
  meaning (1 / fitted per-cell count / `NA`) and contrasts it with `glance()$n_o`;
  `tidy.icc_dstudy()` states the meaning alone. Values derived from a live 15x4x3
  replicated fit. `devtools::test()`: FAIL 0, WARN 3 (the pre-existing
  default-branch count), SKIP 2, PASS 9122.
- 2026-08-28: T2 done. `tests/testthat/test-occasions-vocabulary.R` pins the AC1
  sentences over whitespace-collapsed, backtick-free `Rd_db()` text (source
  `man/*.Rd` fallback under `load_all`, no skip branch). Mutation matrix: seven
  planted defects (meaning verb, contrast naming the wrong column, each of the
  three divisor/`NA` clauses, the d-study meaning, the contrast copied onto
  `d_study.Rd`) each red at FAIL 1; a mid-phrase rewrap control stayed green.
- 2026-08-28: T3 and T4 done. Legend keys read `occasions: <value>`; the title
  branch reads `Occasions averaged`. `test-autoplot.R` walks AC2's eight cells
  asserting the `n_o` absence on every one, the `occasions: <count>` key form on
  the four rater-axis cells, and both x-axis labels. Four planted defects red
  (FAIL 12 / 5 / 4 / 2) against a green baseline of 79.
- 2026-08-28: T4 found the `Occasions averaged` title branch unreachable; the
  milestone-local decision below records it. AC2 is satisfied as written.
- 2026-08-28: T5 done. The two `d-studies-and-replicates.Rmd` paragraphs name the
  `occasions` column (reads 1 / 3 here) instead of `occasions = 1` / `= 3`. The
  AC3 sweep in `test-vignette-claims.R` collapses whitespace over
  `vignettes/*.Rmd`, `README.Rmd`, `NEWS.md` and roxygen-only lines of `R/*.R`,
  with anti-vacuity floors on each group. Five plants tested: the original prose,
  a line-wrapped form, NEWS, roxygen -- all red; a non-roxygen `R/` comment
  stayed green. `devtools::test()`: FAIL 0, WARN 3, SKIP 2, PASS 9191.
- 2026-08-28: T6 and T7 done. `glossary.Rmd` gains *Occasion (within-cell
  replicate)*, naming the printed design line and `glance()$n_o` as one
  quantity, and *`occasions` vs. `n_o`*, separating the averaging divisor from
  the observed per-cell count. `d_study()`'s roxygen now calls the held count
  the fitted occasion count; every remaining `n_o` in that block is the swept
  argument. `devtools::test()`: FAIL 0, WARN 3, SKIP 2, PASS 9191.
- 2026-08-28: T8 done. All six `data-raw/` checkers self-test OK and pass in
  check mode, the MPL doc-claims ledger included (60 candidates, 12 settled, 0
  failures). `air format --check .` clean; `lintr::lint_package()` 0 lints;
  `R CMD check` raw Status line `Status: OK`. The T2 pin was additionally run
  against an installed copy (`test_dir(load_package = "installed")`): FAIL 0,
  PASS 11, SKIP 0, with `Rd_db()` resolving 7 pages -- so the installed branch
  is exercised, not silently skipped (M116).
- 2026-08-28: no NEWS entry: `NEWS.md` holds first-release notes for 0.1.0, so
  there is no released behavior these changes alter.

- 2026-08-28: review returned M146 to in-progress. AC1 fails: the sentence T1 added to `tidy.icc_dstudy()` -- "`occasions` reports the number of ratings averaged into that row's coefficient" -- is false on the cluster rows of a multilevel replicate occasion-axis projection, which read `occasions` 1..4 at one unchanged estimate. AC2-AC6 verified with fresh evidence; six further findings triaged fix-now, seven rejected, in the Review section. Defect returns: 1. PR #157 open as a draft.
- 2026-08-28: repair tasks T9-T14 added to the plan (minor amendment), one per
  fix-now finding of the return. No criterion or scope text changes: every
  finding is a false or imprecise sentence under a criterion as written.
- 2026-08-28: T9 done. `tidy.icc_dstudy()`'s `occasions` now reads as the
  per-cell occasion count the row is projected at, the averaging divisor only
  where occasion averaging applies, with the multilevel cluster rows named as
  the case where it does not; `tidy.icc()`'s contrast adds that `n_o` is `NA`
  on a design defining no single per-cell count, where `occasions` still reads
  1. Both measured on live fits (an 8x4x3x3 multilevel replicate fit reads
  `occasions` 1..4 at estimate 0.9774618 on every cluster row; a ragged
  15x4 replicate fit reads `n_o` `NA` and `occasions` 1). Pins extended: six
  plants red (the old d-study sentence at FAIL 5, the carve-out dropped at
  FAIL 1, the contrast copied onto `d_study.Rd` at FAIL 2, the `n_o` `NA`
  clause dropped in `man/icc.Rd` alone at FAIL 1), two rewrap controls green.
  `devtools::test()`: FAIL 0, WARN 3, SKIP 2, PASS 9196.
- 2026-08-28: T10 done. `man_pages()` now collects every surface that is
  present, the source `man/*.Rd` and `tools::Rd_db()` both, and asserts each
  claim on all of them, so a source-tree run reads the branch's own page rather
  than whatever copy `find.package()` resolves; that half landed with T9's
  commit and its discrimination is the `man/icc.Rd`-only plant recorded there.
  `R/autoplot.R`'s curve-identity comment now says the `occasions` column is
  the averaging divisor on the rater axis and the swept `n_o` on the occasion
  axis, instead of denying the second. `test-autoplot.R`: FAIL 0, PASS 79.
- 2026-08-28: T11 done. The rater-axis bullet now divides pure error by `m`
  times the curve's own occasion setting, naming `"single"` as `m` alone and
  `"average"` as the fitted occasion count, so the divisor clause matches the
  one-curve-per-setting clause that follows it. AC5's "the fitted occasion
  count" is retained there and at the swept-axis bullet. Verified on a 15x4x3
  replicate fit: at `m` = 4 the rater projection reads 0.8844439 on the
  `occasions` 1 curve and 0.9216645 on the `occasions` 3 curve, matching the
  fitted `ICC(A,k)` at each setting. `prose-profile.py R/d-study.R`: over-35
  sentences 4 -> 3, dash 0.
- 2026-08-28: T12 done. The glossary's *Occasion* entry now names `glance()$n_o`
  as the per-cell count and the printed design line as the same count wherever
  that line carries one, with the multilevel case named: verified on a crossed
  8x4x3x3 fit and a raters-nested-in-clusters fit, both of which print
  `Subjects: 32 in 8 clusters | Raters: N (random) | Observations: 288
  (complete)` and no per-cell count, at `n_o` 3. The *`occasions` vs. `n_o`*
  entry gains `n_o`'s `NA` case and the ragged fit that separates the columns.
  `prose-profile.py vignettes/glossary.Rmd` unchanged against `origin/main`
  (over-35 1, dash 0).
- 2026-08-28: T13 done. The two rewritten `d-studies-and-replicates.Rmd`
  paragraphs carry their appositives as commas rather than dashes, so
  `prose-profile.py` on that file reports dash 0, back to the `origin/main`
  figure the T5 rewrite had taken to 4. Meaning unchanged: the paragraphs still
  name the `occasions` column and no call. `test-vignette-claims.R` under
  `NOT_CRAN=true`: FAIL 0, PASS 422.
- 2026-08-28: T14 done. All six `data-raw/` checkers self-test OK and pass in
  check mode (MPL doc-claims 60 candidates / 12 settled / 0 failures; record
  claims 7 re-derived; generalizing claims 367 in sync; observations 0
  falsified; oracle registry 0 gaps). `air format --check .` exit 0;
  `lintr::lint_package()` no lints; `R CMD check` raw Status line `Status: OK`.
  Installed-surface leg re-run for the changed pin: the test file alone in a
  directory with no `man/`, `test_dir(load_package = "installed")` after
  installing the branch, FAIL 0 / PASS 18 / SKIP 0 with `Rd_db()` resolving 7
  pages. The same leg against the pre-branch library copy was red at the
  `d_study.Rd` claim, which is the stale-copy case finding 5 named.
- 2026-08-28: repair complete; status returns to review. AC1's `tidy.icc_dstudy()`
  half now states a sentence true on the projection rows the review falsified it
  on; findings 1, 3, 4, 5, 6 and 7 are fixed. No criterion or scope text changed.
- 2026-08-28: second review round returned M146 to `in-progress`. AC1 fails on
  three row classes the round-1 repair did not reach: `occasions` is not the
  ratings-averaged count on any `ICC(*,k)` row (12 ratings at `occasions` 3 on
  the 15x4x3 fit); `?icc`'s trichotomy misreads the multilevel cluster
  placeholder `occasions` 1; and `?d_study`'s "the setting held fixed on a
  rater projection" is false on those same cluster rows, which read 1 at every
  `m`. AC2-AC6 verified with fresh evidence. Findings 4, 7, 8 and 10 triaged
  fix-now, 6 to a candidate row, 9 rejected. Defect returns: 2.
- 2026-08-28: amendment return: AC1 -- "reports the number of ratings averaged
  into that row's coefficient -- 1 for a single-rating coefficient, the fitted
  per-cell replicate count for an occasion-averaged one" -- false on every
  `ICC(*,k)` row, so no repair satisfies the criterion as written; the house
  term for that family is *single-occasion*, not *single-rating*. Amendment
  returns naming AC1: 1.
- 2026-08-28: the thrash rule's same-criterion trigger fired -- AC1 failed
  twice, each time by a doc sentence composed per design family and falsified
  by an unenumerated family, the shape `LESSONS.md:47` already names. The plan
  gate recorded no alternative to that approach, so the escalation offer is the
  remaining remedy; disposition put to the maintainer.
- 2026-08-28: maintainer chose the criterion rewrite over the offered
  escalation: amend AC1's wording through the gated protocol and derive its
  replacement sentence by measuring what `occasions` reads across every design
  class, pinned by a test over that grid, rather than describing families from
  recall (`LESSONS.md:47`; M141's `n_o` grid is the precedent instrument).

- 2026-08-28: T15 done. `occasions` MEASURED across every design class on this
  branch, both tidy surfaces. `tidy.icc()`: `NA` exactly where
  `glance()$replicates` is `FALSE` (`R/icc-methods.R:378`), a one-way fit OF
  replicated data included; 1 on every `occasions = "single"` row, on every row
  of a ragged replicate fit (where `n_o` is `NA`), and on every cluster row of a
  multilevel replicate fit at either setting, the placeholder `R/d-study.R:393`
  calls a no-op; the fitted per-cell count on occasion-averaged subject rows
  (crossed and nested-in-clusters, random and fixed raters, numeric `unit`).
  `occasions = "average"` is refused on ragged and on missing-cell data, and
  every multilevel ragged/incomplete replicate fit is refused, so no averaged
  row can read `NA`. `tidy.icc_dstudy()`: `NA` outside a replicate projection;
  on the rater axis every distinct value the fit's own column carries
  (`proj_occ`, `R/d-study.R:422`), cluster rows the smallest of them; on the
  occasion axis the swept `n_o` on every row, non-integer sweeps carried
  verbatim (M138), cluster rows flat across it.
- 2026-08-28: AC1 amendment gate. Three fresh-context [O] criteria audits ran in
  FULL mode over successive drafts before any byte was written, each verifying
  every clause by running R rather than by reading: round 1 returned four
  findings (the d-study half inheriting a meaning false on occasion-axis cluster
  rows and on non-integer sweeps; a per-axis claim whose free axes are axis x
  level; the head clause and the `ICC(*,k)` clause disagreeing on the counted
  unit; an `n_o` `NA` gloss weaker than D-041's uniform-and-complete condition),
  round 2 three (the `ICC(*,k)` clause false on cluster rows, the head clause
  likewise, the rater-axis curve set), round 3 three (a cluster-placeholder
  appositive false on every subject-level-only multilevel fit; the trichotomy's
  `wherever` colliding with its own `NA` case; the ratings denial false on every
  `ICC(*,1)` row, where column and ratings count coincide). All ten repaired
  before the gate.
- 2026-08-28: amendment adopted at the mini gate — AC1's wording replaced, the
  criteria set held (same criterion, same two roxygen surfaces, no criterion
  added), the promise narrowed from "the number of ratings averaged into that
  row's coefficient" to the per-rater occasion divisor the code guarantees, and
  the per-family trichotomy replaced by the invariant. The maintainer's grid pin
  lands as T17, a task, not a criterion clause: D-118's instrument question
  keeps a test property out of the promise. The widening alternative (binding
  grid truth into AC1) was offered non-recommended under D-118's
  return-adjacent direction rule and not taken; the escalation offer standing
  from the thrash rule was declined in favour of the audited rewrite.

## Decisions

### The `Occasions averaged` legend title is unreachable (2026-08-28, T4)

`autoplot.icc_dstudy()` selects that title only when `identical(id_cols,
"occasions")`, where `id_cols` is `setdiff(intersect(c("type", "occasions"),
names(df)), x_col)`. `type` is an unconditional column of every `icc_dstudy`
object (`R/d-study.R:517`) and is never the x column, so it is always in
`id_cols`; the branch is dead on every object this version builds. None of
AC2's eight cells reached it at T4.

AC2 anticipates the case ("where it is not, the criterion asserts only the
absence"), so the criterion holds and T4 asserts the absence on all eight
cells. T3 corrected the branch's wording regardless, so it is right if it ever
becomes reachable. Removing it would be a code change with no user-facing
effect, outside this milestone's user-facing surface tier.

### The Rd pin asserts on every surface present, not the first one found (2026-08-28, T10)

`man_pages()` used to prefer `tools::Rd_db("intraclass")` and fall back to the
source `man/*.Rd`. `Rd_db()` reads whatever copy `find.package()` resolves, so
from a source tree it can return a library copy older than the branch, and a
regression in `R/icc.R` plus `man/icc.Rd` would pass green (review finding 5).

Inverting the preference would have traded one blind spot for another: under
`test_dir(load_package = "installed")` the source `man/` is present, so an
installed page that does not carry the branch's docs would never be read. So
the helper collects both surfaces where both exist, requires at least one, and
asserts every claim on each, naming the surface in the failure. Under
`devtools::load_all()` `Rd_db()` returns zero pages here, so a dev with an
unrelated older `intraclass` installed sees only the `man/` surface and no
false red; under `R CMD check`, where `../../man` does not exist, only the
installed surface is read, which is what the doctrine asks for.

## Review

### Round 1 (2026-08-28)

Reviewed 2026-08-28 on `m146-occasions-vocabulary` at PR #157, branch level with
`origin/main` (no merge needed). Diff: 12 files, +447/-46.

### Acceptance-criterion evidence

- **AC1 — FAILED.** The `tidy.icc()` half holds: `man/icc.Rd` states the
  ratings-averaged meaning with all three clauses and the `glance()$n_o`
  contrast, and `test-occasions-vocabulary.R` pins both pages green (2 tests,
  13 passes, 0 fail, 0 skip). The `tidy.icc_dstudy()` half does not: the
  sentence it adds ("`occasions` reports the number of ratings averaged into
  that row's coefficient", `R/d-study.R:137-138`) is false on the cluster rows
  of a multilevel replicate occasion-axis projection. Measured on an 8-cluster
  x 4-subject x 3-rater x 3-replicate fit: `tidy(d_study(fit, n_o = 1:4))`
  cluster rows read `occasions` 1, 2, 3, 4 with an identical estimate
  (0.9468553 at every setting) -- nothing is averaged, so the column is not
  counting ratings averaged into that row's coefficient. See finding 2.
- **AC2 — verified.** `test-autoplot.R` green (20 tests, 79 passes, 0 fail, 0
  skip), including the added `no D-study legend spells the averaging divisor as
  n_o`, which walks the eight enumerated cells asserting the `n_o` absence on
  every one, the `occasions: <count>` key form on the four rater-axis cells,
  and both x-axis labels unchanged.
- **AC3 — verified.** `test-vignette-claims.R` green under `NOT_CRAN=true`; the
  two added tests report 0 fail / 5 passes and 0 fail / 9 passes, the second
  asserting the pattern against five caught spellings and four passed ones. The
  two `d-studies-and-replicates.Rmd` paragraphs name the `occasions` column
  (reads 1 / `occasions` 3 here) rather than a call.
- **AC4 — verified.** `vignettes/glossary.Rmd` carries *Occasion (within-cell
  replicate)*, naming the printed design line `N cells x N replicates` and
  `glance()$n_o` as one quantity, and *`occasions` vs. `n_o`*, separating the
  averaging divisor from the observed per-cell count. The criterion as written
  is met; the first entry's claim is false on one design class -- finding 1.
- **AC5 — verified.** `R/d-study.R:73` and `:86` call the held count "the
  fitted occasion count"; all four `n_o` occurrences in lines 73-86 name the
  swept argument (`the swept occasion count n_o`, `the n_o argument`,
  `m * n_o`, `the swept n_o`).
- **AC6 — verified.** `R CMD check` raw Status line `Status: OK` (no ERROR,
  WARNING or NOTE); `air format --check .` exit 0; `lintr::lint_package()` 0
  lints.

### Consistency gate

`cairn_validate.py` exit 0, all checks passed, 48 advisory `work-log format`
warnings (wrapped continuation lines, the repo's standing convention).
`cairn_impact.py` not run -- `DESIGN.md` carries no principle change in this
diff. Toolchain slot: `devtools::document()` leaves no diff; `NAMESPACE`,
`man/` and `data/` regenerate clean; `pkgdown::check_pkgdown()` reports no
problems; README.Rmd/README.md untouched by the branch; no new top-level
files. No NEWS entry, justified in the work log: `NEWS.md` holds first-release
0.1.0 notes and no released behavior changes here.

### Findings and disposition

Three fresh-context lenses ran in parallel (diff-bug [O]; blame-history [S];
prior-review [S]). Ranked, most severe first.

1. **[O] The glossary's *Occasion* entry states a `print()` claim that is false
   on multilevel replicate fits** (`vignettes/glossary.Rmd:220-228`).
   `format.icc()` tests the multilevel branch before the replicate branch, so a
   crossed multilevel design with 3 ratings per cell prints `Subjects: 32 in 8
   clusters | Raters: 3 (random) | Observations: 288 (complete)` and no
   per-cell count anywhere, while `glance()$n_o` is 3. Verified by running the
   fit. *Fix now* -- a qualifier keeps AC4 met.
2. **[O] `tidy.icc_dstudy()`'s new meaning sentence is false on cluster rows**
   (`R/d-study.R:137-138`, rendered `man/d_study.Rd`). Evidence under AC1 above.
   *Return floor* -- demonstrates AC1 failing inside its own domain.
3. **[S prior-review] The vignette rewrite reintroduces the dash-as-punctuation
   shape M135 drove to zero in this same file.**
   `data-raw/prose-profile.py vignettes/d-studies-and-replicates.Rmd` reports
   `dash = 4` on the branch against `dash = 0` on `main` (both measured
   2026-08-28); `prose-style.md` R1 bars a standalone `--` as a sentence-level
   break. Not a deliberate exemption -- the milestone never names the ruler.
   *Fix now.*
4. **[O] The rater-axis bullet is inconsistent after the AC5 rewording**
   (`R/d-study.R:73-79`). "holding the fitted occasion count fixed: ... pure
   error by `m` times that count" is followed by "one reliability curve per
   occasion setting on the fit"; on the single-occasion curve pure error
   divides by `m * 1`, not by `m` times the fitted count. *Fix now* -- AC5's
   phrase is retained where it is accurate.
5. **[O] The Rd pin can validate a stale installed package**
   (`test-occasions-vocabulary.R:27-33`). `man_page()` prefers
   `tools::Rd_db("intraclass")`, which succeeds under `devtools::load_all()`
   whenever any `intraclass` is installed, so a source-tree run reads the
   installed page rather than the branch's `man/*.Rd` and a regression in
   `R/icc.R` + `man/icc.Rd` would pass green. *Fix now.*
6. **[O] The new sentences describe `glance()$n_o` without its `NA` case**
   (`R/icc.R:683-685`, `vignettes/glossary.Rmd:235-236`). On a ragged replicate
   fit `n_o` is `NA` while `tidy()$occasions` reads 1 -- the case the entry
   exists to resolve. The caveat lives one bullet later, so this is imprecision,
   not contradiction. *Fix now.*
7. **[O] The reworded comment at `R/autoplot.R:51` is false of the occasion
   axis** -- "the averaging divisor, not the design's `n_o`" is wrong there,
   where the `occasions` column carries the swept `n_o`. *Fix now.*
8. **[O] The AC3 sweep does not run under `R CMD check`, and its regex matches
   identifiers ending in `occasions`.** *Rejected* -- the source-tree skip is
   the M129 tier T5 planned and AC3 measures by test, not by CI; the
   false-positive shape has no current hit.
9. **[O] AC2's positive legend-title half is unreachable and so unpinned.**
   *Rejected* -- recorded as a milestone-local decision at T4, and AC2
   anticipates the case in its own text.
10. **[O] The new autoplot test refits duplicate models and leaves cli notes
    unsuppressed.** *Rejected* -- a linter/style class item, no defect.
11. **[O] D-044 cites `R/autoplot.R:58,69-70`, stale after the edit.**
    *Rejected* -- `DECISIONS.md` is append-only (IP4); hygiene only.
12. **[O] `format.icc()` prints two multilevel replicate rows that differ only
    in occasion setting as indistinguishable** (same `level`, same `index`, no
    occasion column). Verified on the fit above. *Rejected as out of scope* --
    pre-existing, on `print()` surface this milestone does not touch; proposed
    as a candidate row instead.
13. **[S prior-review] The `occasions` vs. `n_o` glossary heading contains a
    period, which pkgdown renders as `vs--` in the anchor (M130's bug).**
    *Rejected* -- nothing links to that anchor, so M130's actual defect (a dead
    link) is not reproduced.
14. **[S blame-history] No findings.** Every hunk traces to D-044, which
    authorizes exactly these replacements; the `autoplot()` legend strings it
    replaces entered incidentally at M61 and were never a considered naming
    choice.

### Outcome

Finding 2 demonstrates AC1 failing inside its domain, so the return floor
fires: status returns to `in-progress` for repair and re-review. Defect returns
on this milestone: 1.

Finding 12's candidate row is held for the post-merge hygiene pass, where the
search-first sweep and the records-hygiene disposition rule apply; the nearest
existing home is the `glance()$n_o` remainder row, which already carries the
absorbed `occasions`/`n_o` family. The finding is recorded above in the
meantime.
### Round 2 (2026-08-28, after the T9-T14 repair)

Re-reviewed on `m146-occasions-vocabulary` at PR #157 (draft), branch level with
`origin/main` (0 behind, nothing to merge). Diff: 12 files, +760/-53.

#### Acceptance-criterion evidence

- **AC1 -- FAILED again, by a new mechanism.** The `tidy.icc_dstudy()` half the
  round-1 return falsified is repaired for the case it named: on an 8x4x3x3
  multilevel replicate fit, `tidy(d_study(fit, n_o = 1:4))` cluster rows read
  `occasions` 1..4 at an unchanged estimate (0.9307878 agreement, 1.0000000
  consistency), which the carve-out T9 added now covers. But the sentence AC1
  mandates for `tidy.icc()` is false on two further row classes. (a) On the
  balanced 15x4x3 fit, `ICC(A,k)` at `occasions` 3 (0.9555260) is the
  reliability of a mean of 4 raters x 3 occasions = 12 ratings, so `occasions`
  is not "the number of ratings averaged into that row's coefficient" on any
  `ICC(*,k)` row -- half the rows of every replicate fit (finding 2). (b) On a
  multilevel fit made with `occasions = "average"` alone, `tidy(fit)` cluster
  rows read `occasions` 1 while subject rows read 3; AC1's "1 for a
  single-rating coefficient" reads those as single-occasion coefficients when
  `oc = 1` there is the no-op `R/d-study.R:393` documents (finding 1). AC1's
  d-study half also still fails on the rater axis: cluster rows read
  `occasions` 1 at every `m` on that same fit, not "the setting held fixed"
  (finding 3).
- [x] **AC2 -- verified.** `test-autoplot.R` green (20 tests, 79 passes, 0 fail,
  0 skip). Independently rebuilt all eight enumerated cells and read the legend
  scales: no `n_o` in any legend title or key; keys read `Absolute agreement,
  occasions: 1` / `occasions: 3` on the four rater-axis cells; x-axis labels
  `Number of raters (m)` and `Number of occasions (n_o)` unchanged.
- [x] **AC3 -- verified.** Independent whitespace-collapsed sweep of
  `vignettes/*.Rmd`, `README.Rmd`, `NEWS.md` and roxygen-only lines of `R/*.R`
  for `occasions =` followed by a digit in any spacing or quoting: 0 hits. The
  two `d-studies-and-replicates.Rmd` paragraphs name the `occasions` column.
  `test-vignette-claims.R` green under `NOT_CRAN=true` (422 passes).
- [x] **AC4 -- verified.** `vignettes/glossary.Rmd` carries both entries. The
  *Occasion* entry's `print()` claim now holds where checked: the balanced
  replicate fit prints `60 cells x 3 replicates` at `n_o` 3, and the multilevel
  fit prints `Subjects: 32 in 8 clusters | Raters: 3 (random) | Observations:
  288 (complete)` with no per-cell count, which the entry names.
- [x] **AC5 -- verified.** `R/d-study.R:78` calls the held count "the fitted
  occasion count"; every `n_o` in lines 73-86 names the swept argument.
- [x] **AC6 -- verified.** `R CMD check` raw Status line `Status: OK`, no
  ERROR/WARNING/NOTE anywhere in the log; `air format --check .` exit 0;
  `lintr::lint_package()` 0 lints.

#### Consistency gate

`cairn_validate.py` exit 0, all 17 checks PASS (`coverage complete` among them),
101 advisory warnings (100 `work-log format`, the repo's wrapped-line
convention; 1 `sizing`). `release window` advisory did not fire.
`cairn_impact.py` not run -- no `DESIGN.md` principle change in this diff.
Toolchain slot: `devtools::document()` leaves no diff in `man/`, `NAMESPACE` or
`data/`; `pkgdown::check_pkgdown()` no problems; README untouched by the branch;
no new top-level files; no NEWS entry, justified in the work log. All six
`data-raw/` checkers pass self-test and check mode (MPL doc-claims 60/12/0;
record claims 7 re-derived; oracle registry 0 gaps; observations 0 falsified;
abort-remedy 52 cells, 24 accepted, 0 broken promises).

Prose ruler against `origin/main`: `d-studies-and-replicates.Rmd` dash 0 (was 4
on the branch at round 1, the M135 regression finding 3 named); `R/d-study.R`
over-35 sentences 4 -> 3; `glossary.Rmd` and `R/icc.R` unchanged.

#### Findings and disposition

Three fresh-context lenses ran in parallel. Ranked, most severe first; every
[O] finding below re-verified here against live fits, not against the lens's
account of them.

1. **[O] `occasions` does not count the ratings averaged into an `ICC(*,k)`
   row's coefficient** (`R/icc.R:679-680`, `R/d-study.R:141-142`,
   `vignettes/glossary.Rmd:233-234`, all three pinned verbatim in
   `test-occasions-vocabulary.R`). On the 15x4x3 fit `ICC(A,k)` at `occasions`
   3 averages 4 raters x 3 occasions = 12 ratings; the column reads 3, the
   per-rater occasion divisor D-044 itself calls "the averaging divisor". The
   sentence is false on half the rows of every replicate fit. *Amendment
   return* -- AC1 mandates this wording verbatim, so no repair satisfies the
   criterion as written.
2. **[O] `?icc`'s trichotomy is unqualified where `?d_study`'s was carved out**
   (`R/icc.R:679-687`). On a multilevel fit made with `occasions = "average"`
   alone, `tidy(fit)` cluster rows read `occasions` 1 and subject rows 3; "1
   for a single-rating coefficient" misreads the cluster placeholder
   (`R/d-study.R:393`: "projected single-occasion (oc = 1, a no-op there)").
   *Return floor* -- AC1's `tidy.icc()` half failing inside its domain.
3. **[O] "the setting held fixed on a rater projection" is false on multilevel
   cluster rows** (`R/d-study.R:139-141`). The cluster level is projected at
   `min(proj_occ)` (`R/d-study.R:430-432`): on that same fit,
   `tidy(d_study(fit, m = 1:3))` cluster rows read `occasions` 1 at every `m`,
   not the held setting 3. T9's carve-out covers only the ratings-averaged
   clause, and its justification ("flat across the column") describes the
   occasion axis, not this one. *Return floor* -- AC1's `tidy.icc_dstudy()`
   half failing inside its domain, by a mechanism the round-1 repair did not
   reach.
4. **[O] "one reliability curve per occasion setting on the fit" is false on a
   multilevel replicate fit** (`R/d-study.R:76-79`, rewritten by T11).
   `proj_occ` is `sort(unique(x$estimates$occasions))` (`R/d-study.R:422`), so
   it picks up the cluster placeholder: a fit made with `occasions = "average"`
   only yields subject curves at `occasions` 1 *and* 3, the `occasions` 1 curve
   reporting `ICC(A,1)` = 0.6974904 at `m` = 1, a coefficient the fit never
   reports. *Fix now* -- a defect inside an intentional change.
5. **[O] `single-rating` is a third term for a family the package already names
   twice** (`R/icc.R:680`, `vignettes/glossary.Rmd:235`). The house term for
   the `occasions = 1` family is *single-occasion* (`R/d-study.R:99,393`,
   `R/icc.R:143,156`, `d-studies-and-replicates.Rmd:176`), while
   *single-rating* elsewhere in the same file means one rating per cell
   (`R/icc.R:139,581`, `R/estimand.R:12`, `NEWS.md:26`). A vocabulary milestone
   imports a collision and pins it. *Fold into the amendment* -- AC1 mandates
   the phrase.
6. **[O] The legend on a multilevel rater projection labels the cluster
   facet's only curve `occasions: 1`** (`R/autoplot.R:64`). Verified by
   building the plot: scale labels are `Absolute agreement, occasions: 1` and
   `..., occasions: 3`, the cluster facet carrying only the first. AC2 asks
   only for the `n_o` absence, so the criterion holds, but the new label
   commits to an averaging reading where the old `n_o = 1` was ambiguous.
   *Follow-up* -- outside AC2's promise; candidate row at hygiene.
7. **[O] "`"average"`, which divides it at the fitted occasion count" restates
   the divisor loosely** (`R/d-study.R:77-78`); the true divisor is `m` times
   that count, which the preceding clause states correctly. *Fix now.*
8. **[O] The `R/autoplot.R:50-51` comment says the rater-axis settings "are the
   fit's own"**, which finding 4's evidence falsifies on a multilevel fit.
   Internal comment, no user surface. *Fix now.*
9. **[O] `vignettes/glossary.Rmd:228` is 106 characters**, the only line over
   90 in a file whose next longest is 90. *Rejected* -- pure style, and the
   out-of-scope taxonomy covers formatting a tool would own.
10. **[O] "wherever the design line carries one" is imprecise**
    (`vignettes/glossary.Rmd:225-227`): a ragged replicate fit prints `60 cells
    x NA replicates`, so the line always carries the slot and it is the count
    that is absent. Verified. *Fix now.*
11. **[S prior-review] The cluster carve-out is a per-design-family prediction
    of the shape `LESSONS.md:47` (M140, trimmed M141, extended M143) names** --
    "a doc claim about WHEN a field is `NA` must state the condition the code
    GUARANTEES, never predict what each design family does -- M140's per-family
    prediction failed review twice, each time falsified by an unenumerated
    family." The lens rated it a near-miss because the cluster-flat behaviour
    is a code-guaranteed invariant. Findings 1-3 make it a hit: this
    milestone's claims were composed per family and fell to unenumerated ones
    twice. *Accepted, and it is the diagnosis behind the disposition below.*
12. **[S blame-history] No findings.** Every hunk traces to D-044; the
    `autoplot()` strings replaced entered incidentally at M61
    (`1e5c729c0`); no repair contradicts a recorded decision, and `man/*.Rd`
    is in lockstep with the roxygen it renders.

#### Outcome

AC1 fails on three independent row classes. Findings 2 and 3 demonstrate it
failing inside its domain -- a defect return. Finding 1 shows AC1's own
mandated wording ("the number of ratings averaged into that row's coefficient",
"1 for a single-rating coefficient") cannot be made true, since it is false on
every `ICC(*,k)` row: that is evidence about the promise, so it routes to the
gated criterion-amendment protocol. Finding 5 folds into the same amendment.

Status returns to `in-progress`. Defect returns on this milestone: 2.
Amendment returns naming AC1: 1.

The thrash rule's same-criterion trigger fires: AC1 has now failed twice, each
time by a new mechanism of the same shape -- a documentation sentence composed
per design family and falsified by a family nobody enumerated. `LESSONS.md:47`
already named that shape before this milestone was planned. The plan gate
recorded three alternatives (the printed header fork, the legend key form,
rename/removal), none of them an alternative to composing these claims from
recall, so the recorded-alternative remedy has nothing to spend and the
escalation offer is what remains. Disposition goes to the maintainer.

Finding 6's candidate row is held for whichever pass next reaches hygiene.
