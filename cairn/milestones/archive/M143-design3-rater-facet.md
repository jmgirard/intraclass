# M143: Design 3 stops reporting a rater treatment for a facet it does not have

**Status:** done (2026-08-27, PR #154 https://github.com/jmgirard/intraclass/pull/154)

**Goal:** On a multilevel Design 3 fit (raters nested in subjects), the public surfaces stop naming a rater treatment for a rater facet the model does not estimate.

**Outcome:** `design_has_rater_facet()` (`R/design.R`) is the one predicate deciding this, replacing the independent `model == "oneway"` tests in `glance.icc()` and `d_study()`'s `icc_raters` that had let the one-way rule reach one and not the other. `glance()$raters` is `NA_character_` on a Design 3 fit and on a `d_study()` projection of one; `format.icc()`'s multilevel header renders the rater count with no treatment word for that design alone, Designs 1 and 2 keeping theirs; `summary.icc()` gains a third branch returning a nesting note in place of the absolute-agreement one; `?icc` and `?d_study` each name both no-rater-facet conditions. Design 3's `design$type`, `design$model` and `n_raters` are untouched and stay a candidate row.

**Decisions:** D-042 supersedes D-038 clause 1's Design 3 sentence.

**Review:** Three-lens fan-out (executable surface). Both [S] lenses reported no conflict and no regression; [O] returned nine findings, none showing a criterion failing. Four fixed at the merge gate: `?d_study` still documented the one-way-only rule; D-042's stated reason overclaimed about the projection row, which does carry a `type`/`raters` pair, deliberately split; D-035 clause 2 was cited as five renderers where it names four; and a retained `R/d-study.R` comment claimed a `make_estimand()` branch reads `raters` when neither no-facet branch does. Two recorded without a code change: `summary()` also drops the single-rating-per-cell note, and the five-renderer sweep does not red on `summary()` alone. One filed as a follow-up (`icc_design_phrase()` maps a `NA` treatment to the literal "one-way random", unreachable today). Two rejected. Nothing graduated or retired.
