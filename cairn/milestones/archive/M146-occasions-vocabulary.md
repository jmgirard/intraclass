# M146: The occasion vocabulary says which quantity each surface reports

**Status:** done (2026-08-28, PR #157 https://github.com/jmgirard/intraclass/pull/157)

**Goal:** Close the documentary gap D-044 left open: every surface reporting an occasion count says whether it counts ratings averaged or occasions observed.

**Outcome:** `?icc`'s `tidy.icc()` column list states the rule the code guarantees — `occasions` is the per-rater occasion divisor the row's coefficient applies to pure error, 1 wherever the row averages no occasions, the fitted per-cell count where it does, `NA` on a fit that splits none — with the ratings denial (`ICC(*,k)` averages `k` raters at that count each) and the `glance()$n_o` contrast. `?d_study`'s list states the projected count per axis. `autoplot()` legend keys read `occasions: <value>`, never `n_o`. `glossary.Rmd` gains *Occasion (within-cell replicate)* and *`occasions` vs. `n_o`*; the replicate vignette names the column instead of mimicking a call `validate_occasions()` rejects. `test-occasions-grid.R` generates 60 design-class cases over both projection axes and holds every row to the documented rule; `test-occasions-vocabulary.R` pins the sentences on every rendered Rd surface present. No exported name, type or column changed.

**Decisions:** two milestone-local: the `Occasions averaged` legend title is unreachable (`type` is always a curve-identity column), and the Rd pin asserts on every surface present, not the first found.

**Review:** three rounds, three-lens fan-out each. Rounds 1-2 returned on AC1 (2 defect returns) plus 1 amendment return on AC1, whose per-family wording was false on every `ICC(*,k)` row — the shape `LESSONS.md:47` names. AC1 and AC4 were rewritten through the gated protocol after four fresh-context criteria audits. Round 3 passed every criterion; its 7 findings were fixed at the gate (a false cluster-placeholder generalization in `?d_study`, two over-wide glossary sentences, a vignette ratings count, two stale comments, a task checkbox), 1 rejected. Round 2 finding 6 and round 1 finding 12 went to a candidate row at hygiene. Nothing retired or graduated.
