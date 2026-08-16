<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M124: Demonstrate the exported surface no vignette shows

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Give the exported methods that no vignette currently shows — `summary()` on an
icc, and the whole tidy/plot path off `d_study()` — a worked demonstration.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing.** The deliverable is shipped vignette prose and an
Rd example that applied users read. Nothing here is a defect: every method is
documented and every argument has a `@param`; what is missing is a place a
reader sees the method used.

**In:** `summary.icc`'s interpretive-notes output (`R/icc-methods.R:302-345`),
which appears in no vignette; `tidy.icc_dstudy` and `glance.icc_dstudy`
(`R/d-study.R:640,668`), which no vignette calls — including their
`type`/`level`/`occasions` columns; `plot.icc_dstudy` (`R/autoplot.R:132-136`);
an Rd example for `autoplot.icc_dstudy` (`R/autoplot.R:8-15`), the D-study
reliability curve, which has none while `autoplot.icc` does
(`R/autoplot.R:150-153`); and `d_study()`'s `seed` argument.

**Out:** per-S3-method `\value` prose and `icc()`'s example shadowing the
exported `ratings` dataset → candidate row, promoted at M48. The four falsified
capability claims → M123 (independent; either may land first).
`design = "nested_in_subjects"` reached by argument rather than by inference,
and a runnable numeric-`unit` projection → candidate row, this plan.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `summary()` on an `icc` object is called in an evaluated vignette
      chunk with its output shown. ("Evaluated" throughout means under the
      chunk guard the vignette already uses for its engine/ggplot2
      dependencies — e.g. `vignettes/d-studies-and-replicates.Rmd:61` — since
      GP1's light-install path keeps those in `Suggests`.)
- [ ] AC2: `tidy()` and `glance()` are each called on a `d_study()` result in
      an evaluated vignette chunk, and the prose names at least one column the
      D-study tidy adds over the icc tidy (`type`, `level`, or `occasions`).
- [ ] AC3: `plot()` on a `d_study()` result is shown in the D-study vignette
      without rendering a second copy of the figure `autoplot()` already
      renders at `d-studies-and-replicates.Rmd:62` — `plot.icc_dstudy` is
      `print(autoplot(...)); invisible(x)` (`R/autoplot.R:132-136`), so the
      demonstration is a note or an unevaluated call, not a duplicate figure.
- [ ] AC4: `autoplot.icc_dstudy()` carries an Rd example guarded by the same
      `@examplesIf rlang::is_installed(...)` form used at `R/autoplot.R:150`,
      and `man/d_study.Rd` shows both it and the existing unguarded block.
- [ ] AC5: `d_study()`'s `seed` is passed in an evaluated chunk of
      `vignettes/d-studies-and-replicates.Rmd`; `conf_level` and `mc_samples`
      are named in that vignette's prose.
- [ ] AC6: every vignette this milestone edits builds under
      `devtools::check()` with no new warning, and the suite run against the
      **installed** package (`testthat::test_dir("tests/testthat", package =
      "intraclass", load_package = "installed")`, M116) reports 0 new skips.
- [ ] AC7: `cairn/PROFILE.md`'s verify slot clean, plus `air format --check`,
      `lintr::lint_package()`, and the four `data-raw` checkers.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Add the `summary()` demonstration — `getting-started.Rmd` is the
      natural home, after the `tidy()`/`glance()` pair at `:87-89`; show the
      interpretive notes `R/icc-methods.R:302-345` produces.
- [ ] T2: Add the `tidy()`/`glance()` chunk on a `d_study()` result in
      `d-studies-and-replicates.Rmd`, with prose naming a D-study-only column.
- [ ] T3: Add the `plot()` note per AC3's no-duplicate-figure rule.
- [ ] T4: Add the `@examplesIf` example to `autoplot.icc_dstudy`
      (`R/autoplot.R:8-15`); `devtools::document()`; confirm `man/d_study.Rd`
      renders both blocks.
- [ ] T5: Thread `seed` through a `d_study()` call in an evaluated chunk; name
      `conf_level` and `mc_samples` in the surrounding prose.
- [ ] T6: Full gate — `devtools::check()`, the installed-package test run with
      0 new skips, profile verify, `air`, `lintr`, the four `data-raw`
      checkers; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-16: created by /milestone-plan (assessment run over documentation and vignettes; two [S] audits + one [O] criteria audit).
- 2026-08-16: criteria audit ran in FULL mode (user-facing tier) and returned findings F8-F11 against this milestone; fixed into the criteria before the gate — F8(i) the title and scope no longer call `summary()` "undemonstrated", since `R/data.R:58-59` already demonstrates it in a shipped Rd example, so the gap is vignette-only; F9 "live chunk" is defined against the vignettes' existing `requireNamespace` guard rather than as an unconditional chunk (ggplot2 is Suggests under GP1's light-install path), and `plot()` is fenced against rendering a duplicate figure; F10 the per-S3-method `\value` criterion was cut to a candidate row rather than shipped as a universal over (Rd page × alias) that no named procedure enumerates and that `man/reexports.Rd` cannot satisfy at all; F11 the demonstrate-or-describe disjunction was split, so `seed` must be executed and only `conf_level`/`mc_samples` may be prose.
- 2026-08-16: plan gate chose a separate milestone from M123 over one combined scope because M123 fixes verified falsehoods and this adds absent demonstrations, so a review return on one need not block the other; falsified by the two proving to touch the same vignette lines and forcing a merge conflict.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
