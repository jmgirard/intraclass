<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M124: Demonstrate the exported surface no vignette shows

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m124-undemonstrated-surface` · https://github.com/jmgirard/intraclass/pull/133   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: `summary()` on an `icc` object is called in an evaluated vignette
      chunk with its output shown. ("Evaluated" throughout means under the
      chunk guard the vignette already uses for its engine/ggplot2
      dependencies — e.g. `vignettes/d-studies-and-replicates.Rmd:61` — since
      GP1's light-install path keeps those in `Suggests`.)
- [x] AC2: `tidy()` and `glance()` are each called on a `d_study()` result in
      an evaluated chunk of `vignettes/d-studies-and-replicates.Rmd`, and the
      prose accompanying that chunk identifies `m`, the rater-count column, as
      a column the D-study tidy carries that `tidy()` on the `icc` fit does
      not.
- [x] AC3: `plot()` on a `d_study()` result is shown in the D-study vignette
      without rendering a second copy of the figure `autoplot()` already
      renders at `d-studies-and-replicates.Rmd:62` — `plot.icc_dstudy` is
      `print(autoplot(...)); invisible(x)` (`R/autoplot.R:132-136`), so the
      demonstration is a note or an unevaluated call, not a duplicate figure.
- [x] AC4: `autoplot.icc_dstudy()` carries an Rd example guarded by the same
      `@examplesIf rlang::is_installed(...)` form used at `R/autoplot.R:150`,
      and `man/d_study.Rd` shows both it and the existing unguarded block.
- [x] AC5: `d_study()`'s `seed` is passed in an evaluated chunk of
      `vignettes/d-studies-and-replicates.Rmd`; `conf_level` and `mc_samples`
      are named in that vignette's prose.
- [x] AC6: every vignette this milestone edits builds under
      `devtools::check()` with no new warning, and the suite run against the
      **installed** package (`testthat::test_dir("tests/testthat", package =
      "intraclass", load_package = "installed")`, M116) reports 0 new skips.
- [x] AC7: `cairn/PROFILE.md`'s verify slot clean, plus `air format --check`,
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

- [x] T1: Add the `summary()` demonstration — `getting-started.Rmd` is the
      natural home, after the `tidy()`/`glance()` pair at `:87-89`; show the
      interpretive notes `R/icc-methods.R:302-345` produces.
- [x] T2: Add the `tidy()`/`glance()` chunk on a `d_study()` result in
      `d-studies-and-replicates.Rmd`, with prose naming a D-study-only column.
- [x] T3: Add the `plot()` note per AC3's no-duplicate-figure rule.
- [x] T4: Add the `@examplesIf` example to `autoplot.icc_dstudy`
      (`R/autoplot.R:8-15`); `devtools::document()`; confirm `man/d_study.Rd`
      renders both blocks.
- [x] T5: Thread `seed` through a `d_study()` call in an evaluated chunk; name
      `conf_level` and `mc_samples` in the surrounding prose.
- [x] T6: Full gate — `devtools::check()`, the installed-package test run with
      0 new skips, profile verify, `air`, `lintr`, the four `data-raw`
      checkers; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-16: created by /milestone-plan (assessment run over documentation and vignettes; two [S] audits + one [O] criteria audit).
- 2026-08-16: criteria audit ran in FULL mode (user-facing tier) and returned findings F8-F11 against this milestone; fixed into the criteria before the gate — F8(i) the title and scope no longer call `summary()` "undemonstrated", since `R/data.R:58-59` already demonstrates it in a shipped Rd example, so the gap is vignette-only; F9 "live chunk" is defined against the vignettes' existing `requireNamespace` guard rather than as an unconditional chunk (ggplot2 is Suggests under GP1's light-install path), and `plot()` is fenced against rendering a duplicate figure; F10 the per-S3-method `\value` criterion was cut to a candidate row rather than shipped as a universal over (Rd page × alias) that no named procedure enumerates and that `man/reexports.Rd` cannot satisfy at all; F11 the demonstrate-or-describe disjunction was split, so `seed` must be executed and only `conf_level`/`mc_samples` may be prose.
- 2026-08-17: /milestone-review — three-lens fan-out (user-facing tier). Two [S] lenses clean; the [O] diff-bug lens returned F1-F9, all verified before triage. Maintainer triaged F1-F8 fix-now and F9 rejected; fixes committed on the branch and the gate re-run against them. F4's `seed`-inherits-NULL half was falsified by measurement and is recorded as such.
- 2026-08-17: PR #133 opened. CI at last read: `format-check`, `lint`, `check-references`, `checkpoint-guard`, `pkgdown` all pass; `ubuntu-latest (release)`, `windows-latest (release)` and `test-coverage` still queued at 0s. The blocking watch ended on an `HTTP 503` from the GitHub GraphQL API, not on a check result; nothing left watching — re-derive with `gh pr checks 133`.
- 2026-08-17: T6 gate — `devtools::check()` 0 errors / 0 warnings / 1 NOTE (the pre-existing `Running 'testthat.R' [20m/13m]` runtime NOTE; both edited vignettes re-built OK). `devtools::test()` FAIL 0 | SKIP 2 | PASS 8221. Installed-package leg (M116 form): branch SKIP 110 | PASS 6413 | FAIL 0, against a same-command `main` baseline (`git archive main` into a scratch dir, installed and run there) of SKIP 110 | PASS 6413 | FAIL 0 — 0 new skips. `air format --check` clean, `lintr::lint_package()` 0 lints, and the four CI `data-raw` checkers (`check-reference-observations.py`, `check-mpl-doc-claims.py`, `check-record-claims.py`, `check-checkpoint-sites.R`) all pass. NEWS.md gains three Documentation bullets for the added demonstrations.
- 2026-08-17: T4 — `autoplot.icc_dstudy` gains an `@examplesIf rlang::is_installed(c("ggplot2", "glmmTMB"))` example; `document()` regenerates `man/d_study.Rd` with the guarded block (`\dontshow{...withAutoprint...}`) followed by the pre-existing unguarded `d_study(fit, m = 1:8)` block. Example executed: returns a built ggplot.
- 2026-08-17: T2/T3/T5 — `d-studies-and-replicates.Rmd` gains a "The projection as data" subsection (`tidy(proj)`/`glance(proj)` evaluated, prose identifying `m` per the amended AC2), `seed = 7` on the existing `d_study()` call with `conf_level`/`mc_samples`/`seed` named in the surrounding prose, and an `eval = FALSE` `plot(proj)` chunk. Rendered: the `plot()` call appears as code (block `cb5`) and the figure count stays at 3, so no duplicate curve.
- 2026-08-17: T1 — `summary(fit)` demonstrated in `getting-started.Rmd` after the tidy/glance pair; prose derived from the executed output (report reprinted, then one interpretive note per error definition present plus the single-rating-per-cell note). Vignette renders clean.
- 2026-08-17: substantive amendment at the implement question gate — AC2's parenthetical (`type`, `level`, `occasions`) was falsified: by enumeration of `tidy.icc` (`R/icc-methods.R:349`) and `tidy.icc_dstudy` (`R/d-study.R:640`), `m` is the only column the D-study tidy carries that the icc tidy does not — `type`/`level` are unconditional in `tidy.icc` (built at `R/icc.R:2397`) and `occasions` is gated on the same `isTRUE(x$design$replicates)` predicate on both sides; confirmed across 11 fit/projection configurations.
- 2026-08-17: amended AC2 audited in FULL mode (user-facing tier) by a fresh-context [O] reader that did not author it; it returned findings on satisfiability (my draft was vacuous — the vignette already names `m` five times as a math symbol), bounded promise, probe variation (the gloss "projected rater count" is false on the occasion axis, where `m` is held constant), instrument-vs-deliverable and proportionality (the dated-measurement parenthetical bound the package's column sets, not the shipped vignette). All five fixed into the wording: the binding clause names its vignette and ties the naming to the chunk's tidy output, and the measurement moved here as rationale.
- 2026-08-17: /milestone-implement opened; status in-progress on branch `m124-undemonstrated-surface`, cut from `main` at 9d2f8d2 (M123 merged, so the merge-conflict falsification logged below is moot).
- 2026-08-16: plan gate chose a separate milestone from M123 over one combined scope because M123 fixes verified falsehoods and this adds absent demonstrations, so a review return on one need not block the other; falsified by the two proving to touch the same vignette lines and forcing a merge conflict.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Evidence (2026-08-17, branch `m124-undemonstrated-surface` at 8 commits ahead of
`origin/main`, which has not moved since the branch was cut).** Both edited
vignettes were re-rendered fresh for this review; the `main` copy of
`d-studies-and-replicates.Rmd` was rendered from a `git archive main` extraction
under the same loaded package for the AC3 baseline.

- AC1 — `getting-started.Rmd` chunk `summary` calls `summary(fit)` unguarded,
  matching its neighbouring `fit`/`tidy` chunks. Rendered HTML carries the call
  and the interpretive-notes output (the "Absolute agreement counts the rater
  main effect…" line `R/icc-methods.R:316-318` emits).
- AC2 — chunk `dstudy-tidy` (`:61`) runs `tidy(proj)` and `glance(proj)` under
  the vignette's existing `requireNamespace("glmmTMB")` guard; rendered output
  shows the 8-row tidy through `ICC(A,8)` and the one-row glance. Prose at
  `:67-71` identifies **`m`**, the rater-count column, as the one column the
  D-study tidy carries that `tidy()` on the fit does not. Claim re-verified by
  execution: `setdiff(names(tidy(proj)), names(tidy(fit)))` is exactly `"m"`.
- AC3 — chunk `dstudy-plot-wrapper` (`:93`) is `eval = FALSE`, so `plot(proj)`
  renders as highlighted code with no figure. Figure count is 3 in the rendered
  branch vignette and 3 in the rendered `main` vignette — no second copy of the
  `autoplot()` curve (that chunk is now at `:82-85`; the criterion's `:62`
  locator predates this milestone's insertions).
- AC4 — `R/autoplot.R:10` carries `@examplesIf rlang::is_installed(c("ggplot2",
  "glmmTMB"))`, byte-identical to the form at `R/autoplot.R:153` (the
  `autoplot.icc` example the criterion points at). `man/d_study.Rd`'s `\examples`
  block holds the guarded block (`\dontshow{if (…) withAutoprint(\{`) followed by
  the pre-existing unguarded `d_study(fit, m = 1:8)` block.
- AC5 — `d_study(fit, m = 1:8, seed = 1)` in the evaluated `dstudy` chunk
  (`:40-43`); `conf_level`, `mc_samples` and `seed` all named in the prose at
  `:51-56`. (`seed = 7` at the pre-gate state; changed to the fit's own seed by
  the F1 fix below, which leaves the argument executed and the AC met.)

**Findings — [O] diff-bug, [S] blame-history, [S] prior-PR-comments (all
fresh-context).** The two [S] lenses returned nothing: blame-history confirmed
`autoplot.icc_dstudy` never carried an example that was later removed (the
sibling `autoplot.icc` got one at M11, commit 3368299, so this reaches parity)
and that no touched line undoes a past milestone; the prior-review lens diffed
the new NEWS bullets against `test-doc-skew-caveat.R`'s `claim_patterns` and
found no withdrawn M123 spelling reused, and its `gh api …/pulls/comments`
probe returned `[]`, so the PR-thread walk was skipped. The [O] lens returned
nine findings; all were verified against the implementation before triage.

- F1 (fixed now) — `seed = 7` made the `m = 4` row's *interval* `[0.175, 0.907]`
  against the fit's `[0.177, 0.908]`, so the comparison the anchor prose invites
  no longer matched column-for-column. The anchor's literal claim (Φ(m) equals
  `ICC(A,k)`) held — the estimate was 0.620 either way. Fixed by passing the
  fit's own `seed = 1`, verified byte-identical to inheriting it
  (`all.equal(tidy(d_study(fit, m = 1:8)), tidy(d_study(fit, m = 1:8, seed = 1)))`
  TRUE) and the anchor now exact in estimate and interval.
- F2 (fixed now) — "a second copy of the curve above" was false: the figure above
  is `m = 1:12` and `proj` is `m = 1:8`. Reworded to "another reliability curve
  just like the one above".
- F3 (fixed now) — the new `### The projection as data` heading was the only
  `###` in the vignette and swallowed the rest of the section. Heading dropped;
  the prose flows, and the rendered file now has 0 `<h3>`.
- F4 (fixed now, half falsified) — "each default to the value stored on the fit"
  is false for `mc_samples`: on a one-way `searle` fit `ci$samples` is `NA` and
  the projection reports the hard-coded 10000 (`R/d-study.R:305-317`). The
  reviewer's companion claim that `seed` inherits `NULL` is FALSE — a fit seeded
  3 yields a projection seeded 3. Vignette and NEWS both narrowed to "whenever
  the fit carries them".
- F5 (fixed now) — "can and cannot separate" overstated: the emitted note has
  only the negative half (`R/icc-methods.R:333-336`). "can and" dropped in the
  vignette and NEWS.
- F6 (fixed now) — the NEWS bullet's "an interpretive note for each error
  definition present" is false off the one-way branch, which emits one design
  note and none per definition (verified by running `summary()` on a one-way
  fit). Scoped to "for the default two-way fit shown there".
- F7 (fixed now) — NEWS listed the `plot()` wrapper among what the vignette
  "shows" beside two executed items, while its chunk is `eval = FALSE`. Split
  into its own "It also describes…" sentence.
- F8 (fixed now) — the guarded Rd example shadowed the unguarded block's `fit`
  and re-ran an identical projection. Renamed to `fit_ag` and changed to
  `m = 1:12`, so `?d_study` now shows two distinct examples.
**Gate (re-run against the fixed tree, commit `3e8a9f9`).**

- AC6 — local `devtools::check()`: Status 1 NOTE, 0 errors, 0 warnings; the NOTE
  is the pre-existing `Running 'testthat.R' [21m/13m]` runtime NOTE, and both
  edited vignettes re-built. CI on the same commit is green on every job,
  including `ubuntu-latest (release)` (21m22s) and `windows-latest (release)`
  (24m51s), which run `R CMD check` on two platforms. Installed-package leg
  (M116 form) SKIP 110 | PASS 6413 | FAIL 0, matching the `main` baseline of
  SKIP 110 | PASS 6413 | FAIL 0 measured the same day by the same command on an
  unmoved `main` — 0 new skips.
- AC7 — profile `verify` slot clean (`devtools::document()` produces no diff;
  `devtools::test()` FAIL 0 | SKIP 2 | PASS 8221 at the pre-gate state, and the
  suite ran clean again inside the final `check()`); `air format --check` clean;
  `lintr::lint_package()` 0 lints; all four `data-raw` checkers pass
  (`check-reference-observations.py`, `check-mpl-doc-claims.py`,
  `check-record-claims.py`, `check-checkpoint-sites.R`).

**Consistency gate.** `cairn_validate` all 16 checks PASS, 7 advisories OK.
Toolchain slot: `document()` no-diff verified; `NAMESPACE`/`man/` regenerate
cleanly; `README.Rmd`/`README.md` untouched by this milestone;
`pkgdown::check_pkgdown()` "No problems found"; NEWS.md carries three
Documentation bullets for the user-visible changes; no new top-level files.

- F9 (rejected) — the new `summary()` chunk carries no `eval =` guard. AC1's
  gloss defines "evaluated" as the guard "the vignette already uses";
  `getting-started.Rmd` uses none on any chunk, including the pre-existing
  `icc()` call at `:64`, so the gloss is vacuous there while AC1's binding
  clause — called in an evaluated chunk with its output shown — is met, and a
  guard would make this the file's only guarded chunk. Accepted as met at the
  maintainer's triage; the criterion text is untouched.
