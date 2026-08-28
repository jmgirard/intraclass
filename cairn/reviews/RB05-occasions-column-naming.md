# RB05: The `occasions` / `n_o` naming pair before the v0.1.0 door closes (no milestone — convened at a plan gate)

- **Date:** 2026-08-28
- **Output required:** write findings to `cairn/reviews/RR05-occasions-column-naming.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package that estimates interrater-reliability intraclass
correlation coefficients inside the generalizability-theory framework, fitting
a mixed model (default engine `glmmTMB`) and forming coefficients from
estimated variance components rather than ANOVA mean squares. Version 0.1.0 is
finished but **not yet submitted to CRAN**. The repo treats submission as a
one-way door: exported behaviour may change with just a recorded decision
until submission, and afterwards a rename costs a lifecycle deprecation cycle.

The package supports designs with **within-cell replicates** — more than one
rating per subject-rater cell, called *occasions*. Two exported columns report
occasion counts, and they hold **different quantities**:

- `tidy()$occasions` — the **averaging divisor**: how many occasions are
  averaged into the coefficient on that row. It is `1` on a single-occasion
  row and the fitted occasion count on an averaged row, so on a replicated fit
  with 3 occasions its values are `{1, 3}`.
- `glance()$n_o` — the **observed design count**: how many occasions the
  fitted design actually has per cell. On the same fit it is `3`.

Neither column's documentation says which of the two it holds, so a user
reading both sees one apparent fact contradicting itself.

The token is overloaded a third way, as an **argument name**, with different
types on each side:

- `icc(occasions = )` takes the **strings** `"single"` / `"average"`, while the
  column it produces holds **numbers**.
- `d_study(n_o = )` takes **counterfactual numeric counts** to project to
  (non-integers allowed), while `glance()$n_o` is an observed integer count.

**This is the second review of this mechanism.** RB04 (2026-08-25, the
exported-API last call) asked whether the returned column names were right and
whether `n_o` and `m` were named as a reader will read them. RR04 answered,
and its answers created the present pair: it directed that `n_o` be **added**
to `glance.icc()`, and it explicitly considered and rejected renaming. Its
reasoning is quoted verbatim in Materials below. You are not bound by it, but
you must engage with it: say plainly whether it was right, and if you depart
from it, say what it missed. An advisory conclusion from a prior review at
this fluency can acquire momentum it has not earned, which is part of why this
second review exists.

Because this is a second escalation of the same mechanism, **removing the
`tidy()$occasions` column outright** is on the table and is put to you as
Question 4. Do not treat it as a formality.

## Materials

### The two columns, as built

- `R/icc-methods.R:378-379` — `tidy.icc()` fills `occasions` from
  `x$estimates$occasions`, coerced to double.
- `R/icc-methods.R:441` — `glance.icc()` fills `n_o` from `x$design$n_o` when
  the design has replicates, else `NA_integer_`.
- `R/estimand.R:56-59` — where the two collapse into one number:
  `n_o_val <- if (is.numeric(occasions)) occasions else switch(occasions,
  single = 1, average = n_o)`.
- `R/estimand.R:153-157` — `n_o_val` divides the **residual (pure-error) term
  only**; `R/estimand.R:171` — the value that becomes the public column.
- `R/design.R:43-51` — where the observed count is measured.
- `R/icc.R:2532` — `design$n_o` set, or `NA_integer_` when unreplicated.

### The arguments

- `R/icc.R:246-252`, validated `R/icc.R:2729-2741` — `occasions` accepts only
  `"single"` and/or `"average"`.
- `R/d-study.R:172`, validated `R/d-study.R:594-612` — `n_o` accepts a
  non-empty numeric vector, finite, `>= 1`, **non-integers permitted**
  (`R/d-study.R:592-593`).

### The printed and plotted surfaces

- `R/icc-methods.R:179,189` — `format.icc()` heads the column `occasions` when
  printing a replicated fit.
- `R/icc-methods.R:80-90` — the same fit's header prints the design count as
  `"%d cells x %d replicates"`, i.e. the word *replicates*, not `n_o`.
- `R/d-study.R:666-667` — the printed d-study header for **one column** is
  `"n_o"` on an occasion sweep and `"occ"` on a rater sweep.
- `R/d-study.R:411-416` — the fork that makes that one column hold either the
  user's swept counts or the fitted divisor.
- `R/autoplot.R:30` — x-axis label `"Number of occasions (n_o)"` (swept count).
- `R/autoplot.R:56-58,69-70` — legend keys `paste0("n_o = ", df$occasions)` and
  legend title `"Averaging (n_o)"`, both labelling the **divisor**.

### Documentation

- `man/icc.Rd:119-121` — the `occasions` argument, "the mean of the `n_o`
  replicates".
- `man/icc.Rd:482-485` — the `tidy()` column; does not say it holds 1-or-n_o.
- `man/icc.Rd:494-499` — the `glance()` column; unambiguously the design count.
- `man/d_study.Rd:45-47`, `:66,74,77`, `:162-165`, `:169-175` — the argument
  and the column; `:169-175` uses `n_o` in both senses in one bullet.
- `vignettes/d-studies-and-replicates.Rmd:177,179` — prose writes
  `occasions = 1` / `occasions = 3`, a call syntax that would error.
- `vignettes/glossary.Rmd` — has **no entry** for either quantity.

### Related shape facts

- `glance.icc_dstudy()` (`R/d-study.R:740-760`) has **no `n_o` column**; its
  rater-count sibling is `n_m`, so `glance.icc()$n_o` is parallel to it.
- The `glance()` name set is 24 columns, identical across five design
  families, so any two rows bind.
- `tidy()$occasions` is `double` on every fit and projection, deliberately:
  `d_study()` admits a non-integer occasion count for symmetry with `m`.

### What the previous review concluded (RR04, 2026-08-25)

On the `d_study()` argument name — quoted verbatim:

> `n_o` — cryptic in isolation, but the honest choice: `occasions` is taken
> (character-valued, in `icc()`), and `n_o` is the symbol every replicate
> formula in the docs uses. Keep, with the docs carrying the load as they do.

On adding the `glance()` column — quoted verbatim:

> A within-cell replicate fit estimates a `subject_rater` interaction
> component ... and on that fit `var_residual` is *pure error only*.
> `glance()` has no `var_subject_rater` column, so the interaction variance is
> invisible and — worse — `var_residual` silently means a different quantity
> than on a single-rating-per-cell fit, with `n_o` nowhere in the row to flag
> it. ... Add `var_subject_rater` (NA when confounded) and `n_o` (NA when
> unreplicated) to `glance.icc()`. **Apply.**

On the `tidy()` column's shape — quoted verbatim:

> Make `occasions` unconditional in `tidy.icc()` (NA when no replicates). ...
> **Apply** — this is a shape decision that is free before release and a
> breaking change after.

Note what RR04 did **not** address: it reasoned about the argument name and
about each column's presence, but nowhere compared `tidy()$occasions` against
`glance()$n_o` as two columns a user reads side by side.

### The standing record on this repo's own roadmap

The tracked candidate row for this issue reads, verbatim:

> **`tidy()$occasions` and `glance()$n_o` disagree numerically under
> near-identical names** — the design's per-cell count against the estimand's
> averaging divisor ... A doc gap, not a computation error. ... Promote on a
> user reading the two columns as one quantity or reaching an `NA` count on
> such a design, never on the naming alone.

A rename would act on the naming alone, overriding that condition. The repo
has one live precedent for such an override (D-042): a `glance()` cell was
changed inside the v0.1.0 window because "the trigger is the one-way door
closing at submission, in place of the candidate row's unmet promotion
condition: after v0.1.0 this cell costs a deprecation cycle to change, while
the row's condition can only be met once a user has already been misled."

## Questions

1. **Is there a real defect here, or only a documentation gap?** Judge whether
   a competent user of this package, reading `tidy()` and `glance()` output
   from the same fit, is actually misled by the present names — or whether the
   names are each defensible for their role and only the documentation is
   missing. Answer against the shipped surfaces listed in Materials, not
   against the abstraction.

2. **Was RR04 right to keep `n_o` and let the docs carry the load?** It
   reasoned from a two-way overload (`occasions` taken by a character-valued
   argument). Does its conclusion survive the three-way overload documented
   here — argument, column, and printed/plotted label — and the side-by-side
   column comparison it never made? If you depart from it, name what it missed.

3. **If a rename is warranted, what exactly should be renamed, and to what?**
   Adjudicate among: (a) rename the `tidy()` column to something meaning
   *occasions averaged*, leaving `glance()$n_o` and both argument names; (b)
   documentation only, no rename; (c) rename both columns as a matched pair;
   (d) a naming you propose. Weigh that `n_o` is parallel to `n_m` in
   `glance.icc_dstudy()`, that the name must mean one thing across both
   `glance()` methods, and that renaming a column desynchronizes it from an
   identically-named argument unless the signature moves too.

4. **Should the `tidy()$occasions` column be removed instead?** RR04 made it
   unconditional; nobody has since asked whether it should exist. Its value is
   recoverable from the row's index label together with `glance()$n_o` on many
   fits. Weigh removal against both keeping and renaming, and say under what
   conditions removal would be the better answer. If removal is wrong, say so
   plainly and why.

5. **Only if a rename is chosen:** on an occasion-axis `d_study()` projection
   the printed header currently echoes the `n_o` argument that produced it
   (`R/d-study.R:666-667`). After a rename the header and the argument stop
   matching. Should the printed header follow the new column name on both
   axes, or keep echoing the argument? Consider also the plot labels at
   `R/autoplot.R:30,58,70`, where `n_o` currently labels the divisor on one
   axis and the swept count on the other.

6. **Does the one-way-door argument genuinely transfer from D-042 to this
   case?** D-042 overrode an unmet promotion condition because a user could
   only meet that condition after already being misled. Say whether that
   reasoning applies here, or whether the roadmap's own "doc gap, not a
   computation error" diagnosis should stand and this should never have been
   escalated. A finding that the escalation itself was disproportionate is a
   legitimate and useful answer.

## Constraints

Fixed; flag disagreement explicitly rather than working around it.

- **D-035 clause 2** — the public surface is what `tidy()`, `glance()`,
  `summary()` and `print()` return, plus `$fit` and `$call`; the rest of the
  fitted object's list interior is internal and may change freely. Do not
  propose changes whose only effect is on internal list elements.
- **D-038** — column *order* is deliberately not contract; the promise is the
  set of names. `tidy()$occasions` is `double` on every fit and projection,
  and unifying on `integer` was rejected because non-integer occasion counts
  are admitted on purpose. A name must mean one thing across `glance.icc()`
  and `glance.icc_dstudy()`.
- **D-041** — the condition under which `n_o` reports a number rather than
  `NA` is *uniform and complete*, not merely *unragged*. That condition is
  settled and is not reopened by this brief.
- **GP2** — CRAN submission is the one-way door. Pre-submission, exported
  behaviour may change with a recorded decision; post-submission it takes a
  deprecation cycle.
- Under this repo's history rule, existing decision entries are **superseded
  by a new entry, never edited**. Do not propose editing D-038 or D-041.
- Release timing is the maintainer's to declare. Do not recommend submitting,
  delaying, or scheduling the release; confine yourself to the naming question.

## Output format

In `RR05-occasions-column-naming.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under "Beyond
the brief"; end with concrete recommendations, each marked apply / consider /
reject-with-reason. Your report is advisory: this brief's header slot says
`not requested`, so do **not** emit a `## Binding criteria` section.
