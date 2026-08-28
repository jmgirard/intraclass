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

- [ ] AC1. The roxygen at `R/icc.R:675-680` (rendered `man/icc.Rd:482-485`)
      states that `tidy.icc()`'s `occasions` reports the number of ratings
      averaged into that row's coefficient — 1 for a single-rating
      coefficient, the fitted per-cell replicate count for an occasion-averaged
      one, `NA` when the design has no within-cell replicates — and states that
      `glance()`'s `n_o` reports the observed per-cell count instead. The
      `tidy.icc_dstudy()` column list states what its own `occasions` column
      reports on a projection, without the `glance()` contrast, which has no
      referent there (`glance.icc_dstudy()` carries no `n_o`).
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

- AC1 → T1, T2
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
- [ ] T10. Repair the pin's surface selection so a source-tree run cannot
      validate a stale installed copy (finding 5), and correct the
      `R/autoplot.R` curve-identity comment, which is false of the occasion
      axis (finding 7).
- [ ] T11. Correct the rater-axis bullet's pure-error divisor (finding 4),
      keeping AC5's "the fitted occasion count" where it is accurate.
- [ ] T12. Qualify the glossary's *Occasion* entry, whose `print()` claim is
      false on a multilevel replicate fit (finding 1), and add `n_o`'s `NA`
      case to the `occasions` vs. `n_o` entry (finding 6, glossary half).
- [ ] T13. Take the `d-studies-and-replicates.Rmd` dash count back to zero
      (finding 3).
- [ ] T14. Re-run the T8 gate.

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

## Review

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
