<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M132: Make the two prose-only `icc()` argument values reachable from the docs

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m132-prose-only-icc-arguments`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Turn two exported `icc()` argument values a reader can reach only by inference
or backticked prose into calls they can run and see.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable is runnable vignette content.

**In:** promotes the ROADMAP candidate **"Two `icc()` argument values reachable
only by inference or prose"** (lineage: M124 plan gate, 2026-08-16). (a)
`design = "nested_in_subjects"` (`R/icc.R:2671`): `grep -rn 'nested_in_subjects'
vignettes/ README.md` returns nothing — the layout is described at
`vignettes/multilevel-designs.Rmd:120-123` but only ever reached by
auto-inference. (b) The numeric-`unit` D-study projection (`normalize_unit`,
`R/icc.R:2701`), shown only in backticks at
`vignettes/d-studies-and-replicates.Rmd:49` and never run, together with its
`abort_fixed_agr_projection()` fence (`R/icc.R:2724`), undocumented in any
vignette. The sibling `design = "nested_in_clusters"` rides along under AC3.

**Out:** any change to inference, to the `design` values themselves, or to the
fence's behaviour → out; this milestone demonstrates and documents what ships.
The wider multilevel/D-study vignette rewrite the candidate row offers as an
alternative home → not attempted; these two values are the whole scope.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: An evaluated chunk in `vignettes/multilevel-designs.Rmd` passes
      `design = "nested_in_subjects"` explicitly to `icc()` and shows its
      output, and the description at `:120-123` is checked against what that
      call actually does and corrected where it disagrees.
- [ ] AC2: An evaluated chunk in `vignettes/d-studies-and-replicates.Rmd`
      demonstrates the numeric-`unit` projection in the
      `unit = c("single", "average", 6)` form shown at `:49`, and the vignette
      documents `abort_fixed_agr_projection()`'s fence with the condition that
      triggers it, stated as the user meets it.
- [ ] AC3: `design = "nested_in_clusters"` is passed by an evaluated chunk in
      the same vignette as AC1, or the work log records why not. Today it is
      reachable in the docs only at `man/icc.Rd:134`, `man/icc.Rd:519`, and
      inside a printed message at `README.md:152` — never as a call a reader
      can run.
- [ ] AC4: For each call AC1–AC3 add, a planted perturbation of each of these
      forms reds the test backing it in
      `tests/testthat/test-vignette-claims.R`: a changed expected numeral, a
      changed `design` (or `unit`) argument, and a removed argument. Each
      planted run is recorded in the work log.
- [ ] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `R CMD check`'s raw `Status:` line no worse
      than main's; `pkgdown::check_pkgdown()` and `build_site()` clean;
      `cairn_validate` exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T2
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Build (or reuse) a Design-3 fixture the vignette can show, and run
      `icc(..., design = "nested_in_subjects")` against it; compare the result
      to what auto-inference returns on the same data.
- [x] T2: Write the AC1 and AC3 chunks into `multilevel-designs.Rmd`; reconcile
      the `:120-123` bullet against the evaluated output.
- [x] T3: Write the numeric-`unit` chunk into `d-studies-and-replicates.Rmd`
      and document the fixed-agreement projection fence beside it.
- [x] T4: Add the backing tests to `tests/testthat/test-vignette-claims.R`,
      RED-first; run the three planted-perturbation forms per call.
- [ ] T5: Full gate-lite sweep.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate; user selected this item at the plan gate). Promotes the "Two `icc()` argument values reachable only by inference or prose" candidate row, whose promotion condition is "on a user reporting either as unclear, or fold into the next multilevel or D-study vignette pass" — the plan gate promoted it as pre-CRAN doc-completeness work instead, on the maintainer's stated goal, and records that here rather than claiming the row's own condition fired.
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader. Round 1 found AC1 citing `vignettes/multilevel-designs.Rmd:117`, which is inside the *nested-in-clusters* bullet, not the nested-in-subjects one (that opens `:120`); AC3's premise false twice — the printed message is at `README.md:152` not `:130`, and "only inside a printed message" is falsified by `man/icc.Rd:134` and `:519`; AC2's `abort_fixed_agr_projection()` line off by one (`:2724`, not `:2723`); AC4 varying probe location but not form. Round 2 returned no further findings on this milestone; all four fixes verified against the files.
- 2026-08-21: plan gate chose demonstrating both values in the existing vignettes over adding Rd examples for them, because the candidate row frames both as vignette-reachability gaps and `man/icc.Rd` already names `nested_in_clusters` twice without making it runnable; falsified by a Design-3 demonstration proving too costly to evaluate at knit time.
- 2026-08-22: question gate — user chose the live `error = TRUE` chunk for the fixed-rater projection refusal (the idiom `choosing-an-icc.Rmd:197` already uses) and chose to widen the "`design` is for missing-cell ambiguity" framing to name the label-convention case too; the demonstration-data question was returned as "decide for me" and settled on the recommendation (the shipped `school` table).
- 2026-08-22: T1 — reused the vignette's existing `school_d3` relabelling rather than building a Design-3 fixture. Measured on the branch tip: `icc(school_d3, ..., design = "nested_in_subjects", seed = 1)` returns a `tidy()` identical to the same call without `design`, so a chunk there would show syntax only. The demonstration therefore runs on the shipped `school` table, whose rater labels 1-4 repeat in every classroom: inference reports Design 1, `design = "nested_in_clusters"` reports Design 2 (`ICC(A,1)` 0.429), `design = "nested_in_subjects"` reports Design 3 (`ICC(1)` 0.412).
- 2026-08-22: T2 — `multilevel-designs.Rmd` gains a "Declaring the design when the labels are ambiguous" subsection carrying the two explicit-`design` chunks (AC1 + AC3), and the framing paragraph above the Design 2/3 bullets now names both occasions for `design` instead of missing-cell ambiguity alone. Every prose claim in the new subsection was checked against a `knitr::knit()` of the edited vignette. The `:120-123` Design 3 bullet was checked against that output and needed no correction: the fit reports `ICC(1)` / `ICC(k)`, an agreement-only header, and `residual 0.609 (rater confounded)`.
- 2026-08-22: T3 — `d-studies-and-replicates.Rmd` gains a "One projected value, without a projection object" subsection: an evaluated `unit = c("single", "average", 6)` call on `ratings` (adds the `ICC(A,6)` row, 0.710 [0.245, 0.937]) and an `error = TRUE` chunk showing the fixed-rater agreement refusal live. The backticked-only mention at the old `:49` is removed, the subsection replacing it. Claims checked against a `knitr::knit()` of the edited vignette; the `d_study(fit, m = 6, seed = 1)` equality of estimate and interval was measured separately and is pinned by the T4 test rather than asserted in the article.
- 2026-08-22: T4 — two tests added to `tests/testthat/test-vignette-claims.R`: one pinning the declared-`design` section (inference reads the reused labels as crossed with both levels; `nested_in_clusters` gives subject-only with a rater component and `ICC(A,1)` 0.429; `nested_in_subjects` gives `ICC(1)`/`ICC(k)` 0.412 with no rater component; the three readings differ; and a matching declaration on the pupil-unique relabelling returns a `tidy()` equal to inference's), one pinning the numeric-`unit` section (`ICC(A,6)` row 0.710, estimate and both endpoints equal to `d_study(fit, m = 6, seed = 1)`) and one pinning the refusal (classed `intraclass_unidentified`, both named remedies return a number, and the default two-type call drops the agreement projection with a message while keeping `ICC(C,6)`). Suite for the file: 0 failures, 240 passing, 3 skipped.
- 2026-08-22: AC4 — 12 perturbations planted one at a time and reverted, each run through `testthat::test_file()`; every one red. Three forms per call for the three value-returning calls: changed numeral / changed `design` or `unit` argument / removed argument (`nested_in_clusters` 1/4/4 failures, `nested_in_subjects` 1/5/4, numeric `unit` 1/5/5). The `error = TRUE` refusal call returns no number, so the numeral form is inapplicable there and the changed-expectation form was planted as a changed expected condition class instead (`intraclass_unidentified` -> `intraclass_unsupported`, 1 failure), alongside changed `raters` (1) and removed `unit` (1).
- 2026-08-22: T5 — `air format` rewrote the new test calls to one-argument-per-line, so all 12 perturbations were planted and run again against the formatted text that ships; every one red, with the same failure counts as the first pass except P10 (234 passing vs 235, the formatted file's own count). NEWS.md gains two Documentation bullets, one per article.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
