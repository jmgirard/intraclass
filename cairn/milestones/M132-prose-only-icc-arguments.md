<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M132: Make the two prose-only `icc()` argument values reachable from the docs

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m132-prose-only-icc-arguments` / https://github.com/jmgirard/intraclass/pull/141   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: An evaluated chunk in `vignettes/multilevel-designs.Rmd` passes
      `design = "nested_in_subjects"` explicitly to `icc()` and shows its
      output, and the description at `:120-123` is checked against what that
      call actually does and corrected where it disagrees.
- [x] AC2: An evaluated chunk in `vignettes/d-studies-and-replicates.Rmd`
      demonstrates the numeric-`unit` projection in the
      `unit = c("single", "average", 6)` form shown at `:49`, and the vignette
      documents `abort_fixed_agr_projection()`'s fence with the condition that
      triggers it, stated as the user meets it.
- [x] AC3: `design = "nested_in_clusters"` is passed by an evaluated chunk in
      the same vignette as AC1, or the work log records why not. Today it is
      reachable in the docs only at `man/icc.Rd:134`, `man/icc.Rd:519`, and
      inside a printed message at `README.md:152` — never as a call a reader
      can run.
- [x] AC4: For each call AC1–AC3 add, a planted perturbation of each of these
      forms reds the test backing it in
      `tests/testthat/test-vignette-claims.R`: a changed expected numeral, a
      changed `design` (or `unit`) argument, and a removed argument. Each
      planted run is recorded in the work log.
- [x] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
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
- [x] T5: Full gate-lite sweep.

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
- 2026-08-22: T5 sweep — `NOT_CRAN=true CI=true devtools::test()` 0 failures / 8524 passing / 25 skipped (2 warnings, both in files this branch does not touch: `test-icc-lavaan-multilevel.R:402` lavaan negative lv variances, `test-icc-type-vector.R:286`); `air format --check .` exit 0; `devtools::document()` no diff; `pkgdown::check_pkgdown()` "No problems found" and `build_site()` exit 0, with the new section's anchor resolving in `docs/articles/multilevel-designs.html`; `cairn_validate` exit 0, all checks passed. `R CMD check --as-cran` on `R CMD build` tarballs of the branch tip and of `git archive origin/main` (e086166), same command, same machine: both `Status: 1 ERROR, 1 WARNING, 3 NOTEs` with identical headings — the ERROR and WARNING are this machine's missing `pdflatex` (`checking PDF version of manual`), present on both sides, so the branch is no worse than main's. A first branch check reported a fourth NOTE (`Non-standard file/directory found at top level: 'figure'`) from a gitignored `figure/` directory my own vignette knits had left in the working tree; it was deleted and the check re-run.
- 2026-08-22: review — three fresh-context reviewers ([O] diff-bug, [S] blame-history, [S] prior-PR-comments) returned 12 findings; 9 fixed on the branch, 2 sent to candidate rows, 1 rejected as presentation, plus a gate finding fixing a stale registered record claim that was reddening `check-references` on the default branch. Every acceptance criterion passed as written on fresh evidence; no return.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Evidence gathered 2026-08-22 on branch tip `5bc1351`; PR
https://github.com/jmgirard/intraclass/pull/141.**

- AC1 — PASS. `vignettes/multilevel-designs.Rmd:174` is an evaluated chunk
  (`ml-declared-subjects`, `eval = requireNamespace("glmmTMB", ...)`) passing
  `design = "nested_in_subjects"` to `icc()`. A `knitr::knit()` of the vignette
  at review shows its output: header *multilevel (raters nested in subjects)
  absolute agree*, `ICC(1)` 0.412 [0.290, 0.546] and `ICC(k)` 0.737, components
  `cluster 0.998, subject 0.426, residual 0.609 (rater confounded)`. The
  nested-in-subjects bullet (now `:143-146` after the framing edit) was checked
  clause by clause against that output — agreement-only, `ICC(1)`/`ICC(k)`, rater
  differences inseparable from residual error — and needed no correction; the
  disagreement found and corrected was in the paragraph above it, which had said
  `design` is reached for only when missing cells make the pattern ambiguous.
- AC2 — PASS. `vignettes/d-studies-and-replicates.Rmd:102` is an evaluated chunk
  (`dstudy-unit`) running `unit = c("single", "average", 6)` on `ratings`; the
  review knit shows the added row `ICC(A,6) 0.710 [0.245, 0.937]`. The fence is
  documented at `:113-119` and `:130-136` and shown live at `:120`
  (`dstudy-unit-fixed`, `error = TRUE`), whose knitted output is the real
  `Error in \`icc()\`: Projecting absolute agreement to a different number of
  raters is not defined for "fixed" raters`. The triggering condition is stated
  as the user meets it — fixed raters, absolute agreement, a numeric unit — with
  both named remedies and the note that a default two-type call drops the
  agreement projection instead of aborting.
- AC3 — PASS. `vignettes/multilevel-designs.Rmd:162` (`ml-declared-clusters`) is
  an evaluated chunk in the same vignette passing
  `design = "nested_in_clusters"`; the review knit shows header *multilevel
  (raters nested in clusters) two-way random*, subject level only, `ICC(A,1)`
  0.429 [0.310, 0.549], and a `rater:cluster 0.128` component.
- AC4 — PASS. All 12 perturbations re-planted and re-run at review, one at a
  time, each reverted after: 12 of 12 red. Three forms per call for the three
  value-returning calls (changed numeral / changed `design` or `unit` argument /
  removed argument) and, for the `error = TRUE` refusal call, which returns no
  number, changed expected condition class / changed `raters` / removed `unit`.
  Failure counts P1-P12: 1, 4, 4, 1, 5, 4, 1, 5, 5, 1, 1, 1.
- AC5 — PASS. `NOT_CRAN=true CI=true devtools::test()` at review: 0 failures,
  8524 passing, 25 skipped (2 warnings, both in files this branch does not
  touch). `air format --check .` exit 0. `devtools::document()` no diff.
  `pkgdown::check_pkgdown()` "No problems found"; `build_site()` exit 0.
  `cairn_validate` exit 0, all checks passed. `R CMD check --as-cran` on
  `R CMD build` tarballs of the branch tip and of `git archive origin/main`
  (e086166), same command and machine: both `Status: 1 ERROR, 1 WARNING,
  3 NOTEs` with identical headings, the ERROR and WARNING being this machine's
  missing `pdflatex`; the branch is no worse than main's.

### Independent review (2026-08-22)

Three fresh-context reviewers, none having seen the implementation: [O] diff-bug,
[S] blame-history, [S] prior-PR-comments. Findings and dispositions, most severe
first per reviewer.

**[O] diff-bug — 11 findings.**

1. FIXED. The `unit`-equals-`d_study()` claim in `d-studies-and-replicates.Rmd`
   was stated unconditionally, but the *interval* half holds only because both
   calls pass the same seed; verified unseeded, estimates agree (0.710) and
   endpoints differ (`conf.low` 0.2423 vs 0.2314). The sentence now attributes
   the interval match to the shared seed and says two unseeded runs differ in
   the endpoints.
2. FIXED. "`design` … is not a claim the data can check for you" contradicted
   `man/icc.Rd:135-137` and the code: verified that
   `design = "crossed"` on raters that do not bridge clusters aborts classed
   `intraclass_unidentified` under both `type = "agreement"` and
   `type = "consistency"`. The prose now says a declaration is bounded by the
   data and that what it can do unchecked is choose among the readings the data
   admits.
3. FOLLOW-UP. `@param design` in `R/icc.R` still frames the argument as the
   incomplete-data disambiguator only, so it and the widened article disagree on
   what `design` is chiefly for; `man/icc.Rd`'s own Details section already
   covers the label case, so the Rd is internally inconsistent too. No roxygen
   was touched on this branch; a candidate ROADMAP row carries it.
4. FIXED. The `rater:cluster` assertion tested component-name membership, which
   is equally true of the crossed fit, so it could not fail on a regression to
   the crossed labelling. It now matches the printed components line: a
   `rater:cluster` term and no `cluster:rater` term for Design 2, both terms for
   the crossed fit, and `(rater confounded)` for Design 3.
5. FIXED. "a `rater:cluster` component appears in place of the crossed fit's
   rater term" ignored that the crossed fit prints its own `cluster:rater` line;
   the sentence now says one `rater:cluster` term replaces the crossed fit's two.
6. FIXED. `expect_no_error()` was weaker than its own comment ("do return a
   number") — it would pass if the projection row were silently dropped. Both
   remedies now assert the projected row itself (`ICC(A,6)`, `ICC(C,6)`).
7. FIXED. "`icc()` announces the crossed reading" was untested and, being a
   once-per-session message, appears ~90 lines earlier in the knit than the
   section relying on it. The test now re-arms the message
   (`rlang::reset_message_verbosity()`) and asserts it fires on the inferred
   call; the prose says where it printed.
8. FIXED. The no-op claim covered "the two relabelled tables" but only
   `school_d3` was pinned; the test now pins the `school_d2` half as well.
9. FIXED. "One table, three answers" oversold the divergence: crossed and
   Design 2 differ by 0.002 at `ICC(A,1)` and agree to three decimals at
   `ICC(A,k)`. The paragraph now says what actually separates the readings —
   Design 2 loses the cluster level, Design 3 loses the rater term and renames
   the coefficients — and quotes the two close subject-level numbers.
10. REJECTED (presentation, no defect). The article states the simulated
    `school` design's generating truth before positing that its labels are
    ambiguous. The fencing prose the reviewer judged adequate was strengthened
    anyway under findings 2 and 9.
11. FOLLOW-UP. The new test is the fifth verbatim copy of the `school` fixture
    in this file, with nothing tying the copies to the vignette chunk. A
    pre-existing convention (four copies on the default branch); a candidate
    ROADMAP row carries it.

The [O] reviewer also recorded that one of its own seven `test_file()` runs
reported a failure whose backtrace is impossible against this source, and
attributed it to a stale attached package in that process; six later runs were
clean, as were every run on this side.

**[S] blame-history — no conflicts.** The narrower "genuinely ambiguous" wording
came from M123 (`8f8a64c`); its widening here is the recorded question-gate
choice of 2026-08-22, and the widened text still names the missing-cell case and
links the same section. The removed backticked `unit` mention came from M35
(`d69f39e`) and is what this milestone's Scope names for promotion. The new
design test complements rather than duplicates the existing inference test.
`DECISIONS.md` holds no entry barring these values from the vignettes.

**[S] prior-PR-comments — one regression.**

1. FIXED. The diff added `glossary.html#fixed-vs.-random-raters`, but pkgdown
   renders a heading's period as a double hyphen: the built page's id is
   `fixed-vs--random-raters`, so the link resolved to nothing. This is the defect
   class M130 fixed for `#confidence-interval-vs.-credible-interval` and recorded
   in `LESSONS.md`. Corrected, and verified against a fresh `build_site()`: the
   link and the target id now match. Three further instances of the same wrong
   form are pre-existing on the default branch
   (`d-studies-and-replicates.Rmd:141`, `multilevel-designs.Rmd:251`,
   `comparison-with-other-packages.Rmd:183`) — carried to the gate.
   The GitHub inline-comment probe returned empty, so no PR-thread walk was run.

**Gate finding outside the fan-out.** `check-references` was red on PR #141 and
is red on the default branch: `data-raw/record-claims.tsv:6` still expected the
ROADMAP terminal rows `M126…M130` after M131's hygiene pass rotated them to
`M127…M131`. Reproduced on a stashed tree at `origin/main` — the same single
failure — so the branch did not cause it, but it blocks the merge. FIXED here:
the row's claim text and `expected_match` now read `M127…M131`, and
`data-raw/check-record-claims.py` re-derives all six claims with 0 failures.

**Re-verification after the fixes.** All 12 planted perturbations re-run against
the strengthened tests: 12 of 12 red, with the two `design` calls now failing
6 assertions where they failed 4-5 before. `NOT_CRAN=true CI=true
devtools::test()` 0 failures, 8530 passing, 25 skipped. `air format --check .`
exit 0. `pkgdown::build_site()` exit 0. `cairn_validate` exit 0.
No acceptance criterion failed as written, so no return under the return floor.
