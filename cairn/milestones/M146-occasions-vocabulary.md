# M146: The occasion vocabulary says which quantity each surface reports

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Branch/PR:** `m146-occasions-vocabulary`

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
- [ ] AC2. Over the plots `autoplot()` draws from a replicated fit — the cells
      enumerated by crossing the fit's `type` set (one or both definitions),
      its `occasions` set (one or both settings), and the two `icc_dstudy`
      projection axes — no legend title and no legend key text contains the
      string `n_o`. Where `occasions` is the only curve-identity column the
      legend title reads `Occasions averaged` and each key reads
      `occasions: <value>`; where it is not, the criterion asserts only the
      absence above. The occasion-axis x-axis label (`R/autoplot.R:30`) is
      unchanged.
- [ ] AC3. No prose in `vignettes/`, `README.Rmd`, `NEWS.md` or the roxygen
      under `R/` writes the `occasions` argument with a numeric value, in any
      spacing or quoting, measured over whitespace-collapsed text by a test
      that sweeps those paths. The paragraphs describing the single-occasion
      and occasion-averaged rows in `vignettes/d-studies-and-replicates.Rmd`
      name the `occasions` column rather than a call.
- [ ] AC4. `vignettes/glossary.Rmd` carries an entry for occasion / within-cell
      replicate stating that the per-cell count `print()` reports on the design
      line as `N cells x N replicates` is the same quantity as `glance()$n_o`,
      and an entry stating that `tidy()$occasions` counts ratings averaged into
      a coefficient while `glance()$n_o` counts occasions observed per cell.
- [ ] AC5. The `d_study()` roxygen at `R/d-study.R:73-86` calls the held count
      "the fitted occasion count" and uses `n_o` only for the swept argument.
- [ ] AC6. `R CMD check`'s raw Status line reports no ERROR, WARNING or NOTE;
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
- [ ] T2. Pin the AC1 sentences on the installed surface per
      `cairn/doctrine/doc-claim-pins.md`: read via `tools::Rd_db()`, search
      whitespace-collapsed text, pin a backtick-free spelling, and
      mutation-verify each pin red.
- [ ] T3. `R/autoplot.R:58` keys → `occasions: <value>`; `:69-70` title →
      `Occasions averaged`; leave `:30`.
- [ ] T4. Extend `tests/testthat/test-autoplot.R` over AC2's cells, using that
      file's existing build-based idiom (`built_layer()`), asserting legend
      title and key text; include the suppressed-legend and `"Curve"`-branch
      cells as cases that assert only the `n_o` absence.
- [ ] T5. Rephrase the two paragraphs at
      `vignettes/d-studies-and-replicates.Rmd:177,179`; add the AC3 sweep to
      `tests/testthat/test-vignette-claims.R`, skipping on `dir.exists()` as
      that file already does for source-tree paths (M129).
- [ ] T6. Add the two `vignettes/glossary.Rmd` entries.
- [ ] T7. Wording pass on `R/d-study.R:73-86`. Document.
- [ ] T8. Run every `data-raw/` checker with `--self-test` before pushing — a
      roxygen edit inside the `ci_method` doc scope re-keys the MPL
      doc-claims ledger (M130) — then the gate: `air format .`,
      `lintr::lint_package()`, `R CMD check` raw Status line.

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

## Decisions

## Review
