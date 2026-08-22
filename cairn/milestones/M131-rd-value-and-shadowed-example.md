<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M131: Say what each documented method returns, and stop shadowing the shipped dataset

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m131-rd-value-and-shadowed-example` · https://github.com/jmgirard/intraclass/pull/140   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

Close the two CRAN-reviewer documentation nits held as a candidate row since the
M123/M124 plan gate, both on the Rd surface a reviewer reads first.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — the deliverable is the shipped Rd surface.

**In:** promotes the ROADMAP candidate **"CRAN-reviewer documentation nits,
promoted at M48"** (lineage: M123/M124 plan gate, 2026-08-16) ahead of M48 rather
than inside it. (a) `man/icc.Rd`'s single `\value` at `:431` covers eight
aliased topics — `icc`, `autoplot.icc`, `plot.icc`, `format.icc`, `print.icc`,
`summary.icc`, `tidy.icc`, `glance.icc` — without saying what any method
returns; `man/d_study.Rd` (7 aliases) and `man/choose_icc.Rd` (3) are the same
shape. (b) `man/icc.Rd`'s example rebuilds `ratings` by hand with identical
values, so the shipped dataset is never exercised by the example that appears to
use it.

**Out:** any change to what a method actually returns → out; this documents the
existing contract and nothing else, GP2's one-way door being M48's business.
Argument names, order and defaults → M48 T1's last-call API audit. Vignette
prose → M129/M130/M132.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: For every `man/*.Rd` page containing a `\usage` block and more than
      one `\alias`, the page's `\value` section names each topic in that page's
      `\alias` set and says what that topic returns. The page set and each
      page's alias set are enumerated by parsing `\alias` and `\usage` from
      `man/*.Rd`; the enumeration is recorded in the work log. (Today the filter
      selects exactly `man/choose_icc.Rd`, `man/d_study.Rd`, `man/icc.Rd`;
      `man/reexports.Rd` and `man/intraclass-package.Rd` carry aliases but no
      `\usage`, so the filter never selects them.)
- [x] AC2: No `\examples` block in `man/*.Rd` binds a name the package exports
      as data. The domain is enumerated by `parse()`-ing each `\examples` block
      and collecting every name bound by a top-level `<-`, `=`, or `assign()`
      call, intersected with `data(package = "intraclass")$results[, "Item"]`
      (`"ratings"`, `"ratings_incomplete"`); `icc()`'s example uses the shipped
      `ratings` object directly.
- [x] AC3: `R CMD check --as-cran` reports no ERROR, no WARNING, and no NOTE
      heading on the branch that `origin/main`'s run does not also report. A
      NOTE heading is the `* checking <...>` label of a check whose result line
      ends in `NOTE`; NOTE bodies are not compared. Both runs use `R CMD build`
      tarballs -- the branch tip and the branch's merge-base with `origin/main`
      (53f77a1 as cut) -- invoked back-to-back as
      `_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual
      <tarball>`, with no intervening toolchain change. One work-log line
      summarizes that command, `R.version.string`, the two commit ids, both
      `Status:` lines and both heading sets -- summarized, never pasted output.
- [x] AC4: `devtools::run_examples()` completes with no error, and each changed
      example's output is recorded in the work log.
- [x] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
      `air format --check .` clean; `devtools::document()` leaves no delta;
      `pkgdown::check_pkgdown()` clean; `cairn_validate` exit 0.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T4
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Parse `\alias` and `\usage` across `man/*.Rd`; record the selected
      page set and each page's alias set before writing any prose.
- [x] T2: Write per-topic `@return` prose in the roxygen behind each selected
      page (`R/icc.R`, `R/d-study.R`, `R/choose-icc.R`, `R/icc-methods.R`,
      `R/autoplot.R`), then re-document.
- [x] T3: Enumerate example-bound names against the exported data; rewrite
      `icc()`'s example to use the shipped `ratings`, checking the printed
      output is unchanged in value.
- [x] T4: `run_examples()`; `R CMD check --as-cran` on `R CMD build` tarballs of
      the branch tip and of the merge-base with `origin/main`, recording both
      `Status:` lines and their NOTE headings, and noting as a dated observation
      whether any check heading mentions `\value`; the gate-lite sweep.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate; user selected this item at the plan gate). Promotes the "CRAN-reviewer documentation nits, promoted at M48" candidate row, whose stated promotion condition is "Promote at M48, or on a CRAN reviewer raising either" — the plan gate chose ahead of M48 so the fix is not competing with the release checklist.
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader. Round 1 found AC1's `reexports.Rd` exclusion clause inert (that page has no `\usage`, so the stated filter never selects it) and AC2's "object names assigned in each `\examples` block" enumerated by no procedure. Round 2 confirmed the page set and alias counts (3/7/8), confirmed the data intersection returns exactly `ratings` and `ratings_incomplete`, noted `man/intraclass-package.Rd` missing from AC1's parenthetical, and flagged AC3's `checking Rd \value sections` heading as unconfirmable on this machine's R 4.6.1 — AC3 was rewritten to quote the real heading from an actual run rather than assert one. All fixed before writing.
- 2026-08-21: plan gate chose documenting the existing return contract over changing any return shape to make it uniform, because GP2's one-way door closes at submission and a shape change is M48 T1's escalation, not a doc milestone's; falsified by a method whose return shape cannot be described honestly without changing it.
- 2026-08-22: /milestone-implement opened on branch `m131-rd-value-and-shadowed-example`, cut from `origin/main` at 53f77a1; status set to in-progress.
- 2026-08-22: T1 — `tools::parse_Rd()` over `man/*.Rd`, selecting pages with a `\usage` block and >1 `\alias`, selects exactly three, with these alias sets: `man/choose_icc.Rd` (3) `choose_icc`, `format.icc_recommendation`, `print.icc_recommendation`; `man/d_study.Rd` (7) `autoplot.icc_dstudy`, `plot.icc_dstudy`, `d_study`, `format.icc_dstudy`, `print.icc_dstudy`, `tidy.icc_dstudy`, `glance.icc_dstudy`; `man/icc.Rd` (8) `autoplot.icc`, `plot.icc`, `format.icc`, `print.icc`, `summary.icc`, `tidy.icc`, `glance.icc`, `icc`. Non-selected: `man/intraclass-package.Rd` (2 aliases, no `\usage`), `man/reexports.Rd` (3, no `\usage`), `man/ratings.Rd` and `man/ratings_incomplete.Rd` (1 alias each).
- 2026-08-22: T2 — one `@return` list per page in the primary roxygen block (`R/icc.R`, `R/d-study.R`, `R/choose-icc.R`), the main function's return first and one bullet per method, each bullet naming the alias verbatim (`format.icc()`, `tidy.icc_dstudy()`, …); implement gate chose this over a `@return` tag on each method's own block, having measured that roxygen2 merges such tags in source-file collation order, which put a probe `@return` on `print.icc` above `icc()`'s own paragraph. Each bullet's text was written against an observed call: `format.*` character vectors of 14/12/17 lines, `print`/`summary`/`plot` returning their object invisibly, `tidy.icc()` a 10-column tibble, both `glance` methods one-row tibbles, both `autoplot` methods `ggplot` objects. Re-check over `man/*.Rd`: all 18 aliases across the three selected pages appear as `<alias>()` in their page's `\value`. `devtools::document()` stable on a second run; `air format .` clean; `NOT_CRAN=true CI=true devtools::test()` 0 failures / 8500 passing / 25 skipped.
- 2026-08-22: T3 — enumerating top-level `<-`/`=`/`assign()` bindings in every `man/*.Rd` `\examples` block against `data(package = "intraclass")$results[, "Item"]` (`ratings`, `ratings_incomplete`) found exactly one shadowing binding, `ratings` in `man/icc.Rd`; the hand-built frame was `identical()` to the shipped `ratings`. `icc()`'s example now calls the shipped object directly, with a two-line comment naming it as the Shrout & Fleiss (1979) worked example. Printed output before and after the rewrite `diff`s empty (both captured this session under `seed = 1`); the enumeration now returns 0 shadowing bindings. `man/d_study.Rd`'s `fit` binding is outside the domain (not exported data).
- 2026-08-22: amendment (substantive, mini gate) — AC3 and T4 amended together, the Coverage row AC3 → T4 unchanged. Motivation: AC3 required quoting the heading of `R CMD check --as-cran`'s `\value`-section check, and no such heading exists — the run's Rd-related headings are `checking Rd files`, `Rd metadata`, `Rd line widths`, `Rd cross-references`, `for missing documentation entries`, `for code/documentation mismatches`, `Rd \usage sections`, `Rd contents`, all OK, and none mentions `\value` (observed 2026-08-22 on R 4.6.1). Amended AC3 narrows: it drops that unsatisfiable clause and replaces the `Status:`-line comparison with per-NOTE-heading set containment against the merge-base run, defining `NOTE heading` and pinning the invocation. No criterion was added and no existing promise extended. Two fresh-context [O] readers audited the wording in FULL mode before it was written: the first rejected an earlier draft as widening (an inert heading-census clause, `Rd-related` enumerated by no procedure, `no worse than main's` indeterminate, T4 left contradicting AC3); the second cleared the direction and caught one widening the draft still carried (an absolute no-WARNING bar where the original was relative to main), fixed before writing. Subagent use was user-approved at the gate, this session otherwise being told not to spawn agents unattended.
- 2026-08-22: `run_examples()` left a stray `Rplots.pdf` in the repo root and the T4 amendment commit's `git add -A` swept it in; the AC3 comparison caught it as a `checking top-level files` NOTE present on the branch and absent from the merge-base. Removed from the index and the tree, and added to `.gitignore` and `.Rbuildignore` so a future example run cannot reintroduce it.
- 2026-08-22: T4 (AC3) — `_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual <tarball>` on `R CMD build` tarballs, run back-to-back under R version 4.6.1 (2026-06-24): branch tip c4f3414 `Status: 1 NOTE`, merge-base 53f77a1 `Status: 1 NOTE`; the sole NOTE heading on both sides is `checking CRAN incoming feasibility` (maintainer name plus the 0.0.0.9000 version-components line), no WARNING heading on either, so the branch adds no heading the base does not have. No `--as-cran` check heading mentions `\value` — observed 2026-08-22 on R 4.6.1.
- 2026-08-22: T4 (AC4) — `devtools::run_examples(document = FALSE)` exit 0. The one changed example, `?icc`'s, prints the same report as before the rewrite: `two-way random, absolute agreement & consistency`, 6 subjects / 4 random raters / 24 of 24 cells, glmmTMB REML, 95% montecarlo, ICC(A,1) 0.290 [0.051, 0.712], ICC(A,k) 0.620 [0.177, 0.908], ICC(C,1) 0.715 [0.337, 0.926], ICC(C,k) 0.909 [0.670, 0.980], components subject 2.556 / rater 5.244 / residual 1.019. No other example was changed.
- 2026-08-22: T4 (AC5) — `NOT_CRAN=true CI=true devtools::test()` 0 failures / 8500 passing / 25 skipped; `air format --check .` clean; `devtools::document()` leaves no delta; `pkgdown::check_pkgdown()` no problems found; `cairn_validate` exit 0, all checks passed. The four python `data-raw/` checkers also exit 0 (`check-mpl-doc-claims.py`, `check-oracle-registry.py`, `check-record-claims.py`, `check-reference-observations.py`); `check-abort-remedy-verdicts.R` was not run here (it refits models and exceeded the session command timeout) and is left to review.
- 2026-08-22: NEWS.md gains two Documentation bullets — the per-method Value sections on `?icc` / `?d_study` / `?choose_icc`, and `?icc`'s example now calling the shipped `ratings`. Every `R/` line this branch changes is a roxygen comment line (`git diff origin/main -- R/` has zero non-roxygen changed lines), so no computed value moves.
- 2026-08-22: review fix-now round on PR #140 — six [O] diff-review findings repaired on the branch (a false `glance.icc_dstudy()` claim, two lost generics cross-references, an overreaching NEWS sentence, two column-order ambiguities) plus `head(ratings)` added to `?icc`'s example at the maintainer's selection; one finding rejected with reason, one already answered. No status change: no criterion failed after repair.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Fresh evidence, 2026-08-22, PR #140, branch tip re-verified this session.**

- AC1 — `tools::parse_Rd()` over `man/*.Rd` selects the three pages with a `\usage` block and >1 `\alias`, and every alias in each page's set appears as `<alias>()` in that page's `\value`: `choose_icc.Rd` 3/3, `d_study.Rd` 7/7, `icc.Rd` 8/8, 18 of 18 overall, no misses. Script exit 0.
- AC2 — `parse()`-ing every `man/*.Rd` `\examples` block and intersecting its top-level `<-`/`=`/`assign()` bindings with `data(package = "intraclass")$results[, "Item"]` (`ratings`, `ratings_incomplete`) returns 0 shadowing bindings; the only remaining example binding anywhere is `fit` in `man/d_study.Rd`, which is not exported data.
- AC3 — `_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual <tarball>` on `R CMD build` tarballs, back-to-back under R version 4.6.1 (2026-06-24): branch tip 426fa02 `Status: 1 NOTE`, merge-base 53f77a1 `Status: 1 NOTE`; sole NOTE heading on both `checking CRAN incoming feasibility`, no WARNING heading on either, so the branch adds no heading the base lacks. No `--as-cran` check heading mentions `\value` — observed 2026-08-22 on R 4.6.1. Re-run at the post-fix tip below.
- AC4 — `devtools::run_examples(document = FALSE)` re-run at the branch tip, exit 0, no error in the 180-line log. The one changed example, `?icc`'s, prints the same report as before the rewrite: 6 subjects / 4 random raters / 24 of 24 cells, glmmTMB REML, 95% montecarlo, ICC(A,1) 0.290 [0.051, 0.712], ICC(A,k) 0.620 [0.177, 0.908], ICC(C,1) 0.715 [0.337, 0.926], ICC(C,k) 0.909 [0.670, 0.980], components subject 2.556 / rater 5.244 / residual 1.019.
- AC5 — `NOT_CRAN=true CI=true devtools::test()` 0 failures / 8500 passing / 25 skipped; `air format --check .` clean; `devtools::document()` leaves the tree unchanged apart from this tracking file; `pkgdown::check_pkgdown()` no problems found; `cairn_validate` exit 0, all checks passed.

**Consistency gate (r-package profile).** `cairn_validate` exit 0 (coverage complete, binding criteria, weight caps all PASS); no `DESIGN.md` principle changed, so `cairn_impact` is skipped. `document()` no diff; `NAMESPACE`, `man/`, and `data/*.rda` regenerate; README.Rmd/README.md untouched by this diff and last knitted together in 6d51207; `pkgdown::check_pkgdown()` clean; NEWS.md carries two Documentation bullets for the user-visible change, with no milestone number in the user-facing text; the diff adds no new top-level file (it adds `.gitignore` and `.Rbuildignore` entries for a stray `Rplots.pdf`).

**Independent review, 2026-08-22 — three fresh-context reviewers, none having seen the implementation.** The [S] blame-history lens traced `R/icc.R` to its origin and reported no conflict: the removed "Use tidy()/glance()/…" pointer sentences date to M1 and are superseded rather than lost, the hand-built example frame predates the shipped datasets (added M4, `e1227083`) and no commit ever kept it hand-built deliberately, and `Rplots.pdf` was never tracked before. The [S] prior-review lens found no prior-review evidence on the touched files: no archived `## Review` finding concerns `\value` prose, example data shadowing, or ignore entries, and `gh api .../pulls/comments` returned `[]`, so the per-PR walk was skipped. It also checked and cleared the M130 lesson about roxygen edits re-keying `check-mpl-doc-claims.py` — that checker's scope is the `@param conf_level`/`@param ci_method` blocks, which this diff does not touch. The [O] diff-bug lens reported nine ranked findings, triaged at the gate:

- F1 (fix now, fixed) — `glance.icc_dstudy()`'s new bullet said "the number of projected points and their range", but the columns are `n_m = length(unique(x$m))`, `m_min`, `m_max`: on a both-definition fit `d_study(fit, m = 1:4)` has 8 rows against `n_m = 4` (measured this session), and an occasion sweep holds `m` at the observed rater count. The bullet now says "the distinct projected rater counts `m` and their range (held at the observed rater count when the sweep is over occasions, so this is not a row count)".
- F2 (fix now, fixed) — the diff removed `?icc`'s and `?d_study`'s only `\link[generics:tidy]`/`\link[generics:glance]` cross-references. Both pages now close their `\value` with a linked sentence naming the two generics the methods implement.
- F3 (fix now, fixed) — the NEWS sentence "never touched it" was false: the same page's `\examplesIf` autoplot block already ran against the shipped `ratings`. Reworded to "shadowing the shipped object for the rest of the page".
- F4 (fix now at the maintainer's selection, fixed) — after the swap no `man/*.Rd` example showed `icc()`'s expected input layout. `?icc`'s example now runs `head(ratings)` before the fit, printing the six-row subject/rater/score head.
- F5 (fix now, fixed) — both `tidy.*` bullets read as column orders while `occasions`/`type`/`level` are inserted mid-frame. Each bullet now names the insertion point and says the list is not a column order.
- F6 (fix now, fixed) — `d_study()`'s object paragraph omitted the `occasions` column its own `tidy` bullet named. The paragraph now names it beside `level`.
- F7 (already answered) — AC3 was unticked and its recorded evidence predated the tip. Re-run at 426fa02 and again at the post-fix tip; ticked against the AC3 line above.
- F8 (rejected, records point) — the `Rplots.pdf` ignore entries sit outside the stated Scope. Kept: they remove a stray artifact this milestone's own `run_examples()` produced and the AC3 comparison caught, and the work log records the provenance. No Scope amendment convened for a two-line ignore fix.
- F9 (fix now, fixed) — blank line inserted between the two NEWS bullets.

No finding demonstrated an acceptance criterion failing after repair, and none was a load-bearing defect in what the package computes (every `R/` line this branch changes is a roxygen comment line), so the return floor did not fire. Post-fix re-verification: AC1 18/18 aliases named, AC2 0 shadowing bindings, `run_examples()` exit 0 with the new `head(ratings)` output, `NOT_CRAN=true CI=true devtools::test()` 0 failures / 8500 passing / 25 skipped, `air format --check .` clean, `pkgdown::check_pkgdown()` no problems.
