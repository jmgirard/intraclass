# RR05: The `occasions` / `n_o` naming pair — review report

- **Date:** 2026-08-28
- **Brief:** `cairn/reviews/RB05-occasions-column-naming.md`
- **Status:** advisory (binding criteria not requested)

All file references were read as shipped: `R/icc-methods.R` (format/print
header and table, `tidy.icc`, `glance.icc`), `R/estimand.R:37-173`,
`R/design.R:43-51`, `R/icc.R` (the `occasions` argument, `validate_occasions`,
`design$n_o` assembly at :2515-2533), `R/d-study.R` (argument, `validate_n_o`,
the grid fork at :408-418, `format.icc_dstudy`, `tidy.icc_dstudy`,
`glance.icc_dstudy`), `R/autoplot.R:24-73`, `man/icc.Rd`, `man/d_study.Rd`,
`vignettes/d-studies-and-replicates.Rmd`, `vignettes/glossary.Rmd`.

## 1. Real defect, or documentation gap?

For the two data-frame columns: a documentation gap, not a naming defect. For
one plotted surface — the `autoplot` legend — a real, localized defect.

The columns hold different quantities, and different quantities should carry
different names; the trap would have been giving them the same one. Judged in
row context, each name is defensible for its role:

- `tidy()$occasions` sits among `term`, `type`, and `level` — all
  coefficient-identity columns. In that family it reads as "which coefficient
  is this row": the number of ratings averaged into it. It is also the
  resolved numeric value of the `icc(occasions = )` argument that produced the
  row (`"single"` → 1, `"average"` → n_o, `R/estimand.R:56-60`), so the column
  echoes the argument the user typed. `occasions = 1` beside `occasions = 3`
  in the same table reinforces the per-row reading.
- `glance.icc()$n_o` sits in a row that opens `n_subjects, n_raters,
  n_clusters, n_obs, n_cells` and has `replicates` immediately in context — a
  family of observed design counts. Its documentation (`man/icc.Rd:494-500`)
  is the one piece of this mechanism that is already complete and unambiguous.

The shipped `print.icc` surface is evidence the vocabulary split works when it
is carried through: the header calls the design count "3 replicates"
(`R/icc-methods.R:82-90`) and the table column `occasions` holds the divisor
(:174-194). A user reading that one screen sees two words for two quantities
and is not misled.

Where a competent user *is* actually misled, no documentation required, is the
`autoplot` legend on a rater-axis replicate projection (`R/autoplot.R:56-70`):
curves are keyed `"n_o = 1"` and `"n_o = 3"` under the title `"Averaging
(n_o)"`. On that fit `glance()$n_o` is 3, full stop. The label `"n_o = 1"`
asserts, in the design-count symbol, something false about the design. This is
the only shipped surface where the two vocabularies collide in one breath, and
it is a label, not a column.

The remaining gap is documentary: `man/icc.Rd:482-485` never says what
`tidy()$occasions` holds; the glossary vignette has no entry for either
quantity; and the vignette prose writes `` `occasions = 1` `` / ``
`occasions = 3` `` (`vignettes/d-studies-and-replicates.Rmd:177,179`) in a
form indistinguishable from call syntax that `validate_occasions()`
(`R/icc.R:2729-2742`) would reject.

## 2. Was RR04 right?

Yes, on both of its calls, and its conclusions survive the three-way overload
— with one caveat.

Keeping `n_o` as the `d_study()` argument name remains correct under the
fuller picture. `n_o` is the symbol every replicate formula in the docs uses
(`m * n_o`, the ceiling formula at `R/d-study.R:88-89`), and the alternative —
`d_study(occasions = )` — would create a genuinely worse overload: the same
argument name with disjoint types across two exported signatures
(`icc(occasions = "average")` character-only, `d_study(occasions = 1:5)`
numeric-only). The current split at least assigns each surface one name.

The side-by-side comparison RR04 never made does not overturn it either: as
argued under Q1, the two columns are different quantities and the divergent
names are the correct outcome, not the accident. RR04's addition of
`glance()$n_o` also still earns its place independently — the
`var_residual`-means-something-different argument (`R/icc-methods.R:434-441`)
is about statistical honesty of the glance row and is untouched by any naming
concern.

The caveat: "the docs carrying the load" presupposed docs that carry it. For
the argument, they do (`man/d_study.Rd:45-49` is clear). For
`tidy()$occasions`, the load-bearing sentence was never written — RR04 made
the column unconditional and nobody documented what it holds. And RR04
reasoned only about names and columns; it never looked at the plotted labels,
which is where the actual cross-wiring lives (Q1). So: right conclusion,
unfinished execution, one surface unexamined.

## 3. What, if anything, to rename

**(b) Documentation only — no column or argument rename** — plus label fixes
on the plotted/printed surfaces, which are not renames of anything in the
D-035 contract.

Against (a), renaming `tidy()$occasions` to an "occasions averaged" name: the
self-describing gain is real but modest, and one documentation sentence buys
the same clarity. The costs are not modest: `tidy.icc_dstudy()` carries the
same column with the same meaning (`R/d-study.R:725`), so both must move
together or the name means two things across the tidy pair; the `print.icc`
table header (`R/icc-methods.R:179`) and the d-study print header must follow;
and the column stops echoing the `icc(occasions = )` argument that produces it
— the current echo (ask for `"single"`/`"average"`, read back 1/3 under the
same name) is a coherence worth keeping. No candidate name
(`occasions_averaged`, `occ_avg`, `n_averaged`) is enough better to pay that.

Against (c) and against renaming `glance()$n_o` in any form: this is the one
column whose documentation is already complete and unambiguous, and its name
is the formula symbol the docs lean on throughout. There is one honest
counterargument, which I weighed and set aside: within its own row, `n_o` is
the only abbreviated member of the spelled-out `n_subjects … n_cells` family,
so `n_occasions` would fit the family better. But `n_occasions` looks *more*
like `tidy()$occasions`, not less — it would sharpen the very side-by-side
collision this review exists to defuse — and it severs the symbol linkage to
every formula. Reject.

On the brief's parallelism premise, a correction (also under Beyond the
brief): `glance.icc_dstudy()$n_m` is `length(unique(x$m))` — the number of
distinct swept grid points, with `m_min`/`m_max` beside it (`R/d-study.R:742-744`)
— not an observed design count. The true family for `n_o` is `glance.icc()`'s
own `n_*` columns, not `n_m`. Neither name appears in both glance methods, so
D-038's one-meaning-across-methods rule is satisfied as shipped and by every
option considered here.

What should change (labels, not names):

- `R/autoplot.R:58` — legend keys `paste0("n_o = ", df$occasions)` →
  `paste0("occasions = ", df$occasions)`, matching the column the value comes
  from; `R/autoplot.R:69-70` — legend title `"Averaging (n_o)"` → `"Occasions
  averaged"`. The x-axis label at :30 is correct as shipped (on the occasion
  axis, x *is* the swept `n_o`) and should not change.
- `R/d-study.R:667` (consider, minor) — the rater-axis printed header `"occ"`
  could read `"occasions"` to match the tidy column it prints; the
  occasion-axis header `"n_o"` is correct as shipped (that column holds the
  swept counterfactuals the `n_o` argument supplied).

## 4. Should `tidy()$occasions` be removed?

No, plainly. The column is the sole disambiguator between rows that are
otherwise identical. On a fit with `occasions = c("single", "average")`, the
single and averaged coefficients share the same `term` (the index label does
not encode occasion count — it cannot: the occasion-averaged coefficient has
no Shrout–Fleiss form, `R/estimand.R:138`, and no literature label to borrow),
the same `type`, and the same `level`. Remove `occasions` and `tidy()` returns
two rows with identical identity columns and different estimates — a broken
table. The same duplication argument holds for `tidy.icc_dstudy()`, where
`occasions` separates one curve per occasion setting at every `m`.

The brief's recoverability premise ("from the row's index label together with
`glance()$n_o` on many fits") fails exactly where the column matters: it works
only when a fit requests a single occasion setting, and the vectorized
`occasions` argument exists precisely so one fit reports both. Removal would
be the better answer only under conditions the package has deliberately
rejected — one occasion setting per call, or a `term` vocabulary extended to
encode the occasion count. Neither is on the table, and the second would be a
larger and stranger surface change than the rename this review already
declines.

## 5. Printed header and plot labels after a rename

No rename is chosen, so this is moot as a decision; answered hypothetically as
asked. The rule that resolves it is: each surface should follow the *quantity*
it displays, not chase uniformity of token. Had the tidy column been renamed,
the rater-axis printed header and the legend keys/title display the divisor
and should follow the new column name; the occasion-axis printed header and
the x-axis label display the swept counterfactual and should keep echoing the
`n_o` argument that produced it. That is the same rule behind the shipped
`"n_o"`/`"occ"` header fork at `R/d-study.R:666-667` and behind the label
fixes recommended in Q3, which apply it to the one surface that currently
violates it.

## 6. Does the D-042 one-way-door argument transfer?

The reasoning transfers to the *escalation*; it does not transfer to an
*override*, because the override's premise fails on the merits.

D-042's structure was: the candidate row's promotion condition (a user
actually misled) can only be met after the harm, and post-submission the fix
costs a deprecation cycle, so decide before the door closes. That structure
applies here identically — a column rename is exactly the class of change the
door makes expensive, and "wait for a misled user" is a policy of paying the
deprecation price whenever the concern turns out real. Convening this review
now, including re-examining RR04's momentum, was therefore proportionate, not
excessive: the door makes the *question* urgent even when the answer turns out
to be "keep".

But D-042 ended in an override because the change was judged correct on its
merits; here the review finds the names correct and the gap documentary. A
documentation fix, a glossary entry, and plot-label text have no meaningful
one-way-door cost — they remain freely improvable after submission — so the
door supplies no reason to act on the naming, only the reason to have asked.
The roadmap's own diagnosis ("a doc gap, not a computation error") stands,
now with a twice-reviewed pedigree instead of unearned momentum, and its
promotion condition can stay in place for the columns themselves.

## Beyond the brief

- **B1.** The brief's Materials assert `glance.icc()$n_o` "is parallel to"
  `glance.icc_dstudy()$n_m`. As shipped this is loose: `n_m` counts distinct
  swept grid points (`R/d-study.R:742`), a projection-grid fact, while `n_o`
  is an observed design count. The premise did not affect any conclusion here
  (no name appears in both glance methods), but it should not be relied on in
  a future naming argument.
- **B2.** The design count itself has two public names across surfaces:
  `print.icc` calls it "replicates" (`R/icc-methods.R:83-88`) and `glance()`
  calls it `n_o`. As argued in Q1 this split is currently load-bearing (the
  print screen is the clearest surface shipped), but a glossary entry should
  state the equivalence explicitly: the per-cell replicate count *is* the
  occasion count n_o.
- **B3.** `man/d_study.Rd:162-175` (source roxygen `R/d-study.R:73-86`) uses
  `n_o` in two roles inside one bulleted section — the fitted count being held
  ("holding the number of occasions `n_o` at the fitted value") and the swept
  argument ("supply the `n_o` argument"). Both are occasion counts, so this is
  mild, but G-theory's own convention (n_o vs n'_o) exists because the two
  roles differ; a wording pass ("the fitted occasion count" for the held one)
  removes the double duty without introducing primes.
- **B4.** Internal only, no action under D-035: `icc_estimand()` accepts a
  numeric `occasions` (`R/estimand.R:56`) that the public `icc()` refuses
  (`validate_occasions`, `R/icc.R:2729-2742`); the numeric path is reached via
  `d_study()`. Noted so a future reader does not mistake the internal
  signature for public latitude.

## Recommendations

1. **Apply** — Document `tidy()$occasions` at its source (the roxygen behind
   `man/icc.Rd:482-485`): one sentence stating it is the number of ratings
   averaged into that row's coefficient — 1 for a single-rating coefficient,
   the fitted per-cell replicate count for an occasion-averaged one, `NA`
   when the design has no within-cell replicates — and add the explicit
   contrast to `glance()$n_o` (the observed design count) on one side or
   both. Mirror the sentence in `tidy.icc_dstudy()`'s column list where the
   same column appears.
2. **Apply** — Fix the `autoplot` labels: `R/autoplot.R:58` legend keys
   `"n_o = "` → `"occasions = "`; `R/autoplot.R:69-70` legend title
   `"Averaging (n_o)"` → `"Occasions averaged"`. Leave the x-axis label at
   `R/autoplot.R:30` unchanged.
3. **Apply** — Rephrase `vignettes/d-studies-and-replicates.Rmd:177,179` so
   the backticked text no longer mimics invalid call syntax — e.g. "the rows
   where the `occasions` column is 1" / "the occasion-averaged rows
   (`occasions` column: 3 here)".
4. **Consider** — Glossary entries in `vignettes/glossary.Rmd` for
   *occasion / within-cell replicate* (stating the equivalence in B2) and for
   the pair *occasions averaged (tidy) vs n_o (glance)*.
5. **Consider** — The B3 wording pass in the `d_study()` roxygen, and the
   rater-axis printed header `"occ"` → `"occasions"` at `R/d-study.R:667`.
6. **Reject — rename of `tidy()$occasions`** (option a or c): the clarity
   gain is purchasable with one documented sentence, while the rename must
   move two tidy methods, the print header, and the plot labels together, and
   severs the column's echo of the `occasions` argument that produces it.
7. **Reject — rename of `glance()$n_o`** (including `n_occasions`): its
   documentation is already complete and unambiguous, the name is the formula
   symbol used throughout the docs, and the spelled-out variant would
   *increase* visual collision with `tidy()$occasions`.
8. **Reject — removal of `tidy()$occasions`**: it is the sole disambiguator
   between same-`term` rows on any fit or projection carrying both occasion
   settings; recoverability from `term` plus `glance()$n_o` fails exactly
   there.
