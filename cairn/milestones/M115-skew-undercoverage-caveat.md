<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M115: Document the default interval's skew/kurtosis under-coverage — and withdraw the falsified `"burch"` advice

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m115-skew-undercoverage-caveat` / https://github.com/jmgirard/intraclass/pull/124   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ship D-028's `document` disposition: name the default Monte-Carlo interval's
measured under-coverage under skewed/heavy-tailed subject effects where users
meet it, and withdraw the `"burch"` never-under-covers claim the same
measurement falsified — including the hint the package prints at runtime.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a caveat in `R/icc.R`'s `@section Confidence intervals:` block
(unswept by every data-raw checker) naming the failure surface — skewed or
heavy-tailed subject effects at moderate-to-high ρ with several raters per
subject — with its figures derived from the committed
`data-raw/m113-skew-response-coverage.tsv` and the held-out
`data-raw/m114-warn-trigger-stats.tsv`; a dedicated "when the default
under-covers" subsection in `vignettes/interval-methods.Rmd` under the
Monte-Carlo section, cross-linked from `vignettes/glossary.Rmd`'s Monte-Carlo
entry; correction of the falsified `"burch"` claim at all five sites
(`R/icc.R:377`, `R/boundary-hint.R:500` — the runtime hint —
`R/ci-classical.R:13`, `vignettes/interval-methods.Rmd:106-108`,
`NEWS.md:143-152`, an unreleased bullet); a new
`tests/testthat/test-doc-skew-caveat.R` pinning every figure and every
withdrawn claim; the `data-raw/mpl-doc-claims.tsv` re-key the `@param
ci_method` edit forces; a NEWS bullet; regenerated `man/`.

**Out:** any runtime warning or trigger statistic — D-028 degraded that to
`document`, and its reopening path is the existing "cluster-effect-direct
trigger statistic family" candidate row. Any default-method change (the
D-001 fence stands; nothing cleared S1 at D-027). Extending the measured
battery to `"npbootstrap"`, `"bootstrap"`, `"posterior"` or `"mpl"` → new
candidate row added by this plan; the caveat therefore claims nothing about
a method absent from the fixture. Any new checker, ledger or guard whose
subject is this repo's own doc prose → barred by D-021; existing ledgers are
updated only as their existing checkers mechanically require.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `R/icc.R`'s `@section Confidence intervals:` block states the
      distributional condition (skewed or heavy-tailed subject effects), the
      geometry measured worst, and the worst measured non-abort coverage;
      `tests/testthat/test-doc-skew-caveat.R` reads that section from the
      **installed** package (`tools::Rd_db("intraclass")[["icc.Rd"]]`),
      extracts every numeric token from it, and requires each to equal a value
      in the committed fixture `tests/testthat/fixtures/skew-undercoverage.tsv`
      or to appear in the test's committed non-fixture allowlist.
- [ ] AC2: The same test asserts that for every cell in that fixture whose
      `mc` row has abort rate (`n_abort / n_rep`) at most 0.1 and
      `coverage_nonabort` below 0.93, both the `searle` and `burch` rows for
      that cell have `coverage_uncond` below 0.93 — 10 such cells — and that
      every quoted method token in the caveat section is one of
      `"montecarlo"`, `"searle"`, `"burch"`, the test enumerating the
      section's quoted tokens rather than a hand list.
      `data-raw/make-skew-undercoverage-fixture.R` derives the fixture from
      `data-raw/m113-skew-response-coverage.tsv` and
      `data-raw/m114-warn-trigger-stats.tsv`, and a source-tree provenance
      test asserts the fixture matches those sources.
- [ ] AC3: The withdrawn claim (`never under-cover`, however its line wraps)
      is absent from `R/icc.R`, `R/boundary-hint.R`, `R/ci-classical.R`,
      `vignettes/interval-methods.Rmd` and `NEWS.md`, verified over
      whitespace-collapsed text by `tests/testthat/test-doc-skew-caveat.R`
      ("no source file still claims it either, however the line wraps") rather
      than by a line-based grep, which returns 0 against a wrapped occurrence;
      and the test asserts, against the installed package, the same absence in
      `icc.Rd`, the shipped `inst/doc/interval-methods.Rmd` and the installed
      `NEWS.md`, that the rendered `boundary_method_hint()` blurb for
      `"burch"` no longer claims it never under-covers, and that the Rd, the
      vignette and the hint each name the measured heavy-tail exception
      (`burch` worst `coverage_uncond` 0.6655 at rho = 0.60, k = 30, n = 5,
      chisq1).
- [ ] AC4: `data-raw/check-mpl-doc-claims.py`, `check-record-claims.py`,
      `check-reference-observations.py` and `enumerate-generalizing-claims.py`
      each exit 0 on the branch tip, including any `mpl-doc-claims.tsv` row
      re-keyed or added by the `@param ci_method` edit — which must be `out`
      rows whose reason names `tests/testthat/test-doc-skew-caveat.R`, the
      checker settling only against `data-raw/m92-interp-sweep.rds`.
- [ ] AC5: `NEWS.md`'s development-version section carries a bullet stating
      the caveat (naming the worst measured cell and its figure) and
      withdrawing the `"burch"` never-under-covers and heavy-tail-preference
      advice; the figures it names are ones the AC1 test recomputes.
- [ ] AC6: `devtools::document()` leaves no uncommitted diff under `man/`, and
      the r-package profile's verify + consistency gate is clean — full suite
      at `NOT_CRAN=true CI=true` with 0 failures and 0 errors, `air format
      --check` and `lintr::lint_package()` clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T4, T5, T6
- AC4 → T4, T8
- AC5 → T7
- AC6 → T7, T8

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Write `data-raw/make-skew-undercoverage-fixture.R`, generate
      `tests/testthat/fixtures/skew-undercoverage.tsv` from the two M113/M114
      sources, and add the source-tree provenance test asserting they agree.
- [x] T2: Write `tests/testthat/test-doc-skew-caveat.R` — the installed-Rd
      numeric-token extractor, the quoted-method-token enumerator, the
      10-cell paired assertion, the absence assertions and the rendered-hint
      assertion. Red before any doc edit.
- [x] T3: Author the `@section Confidence intervals:` caveat in `R/icc.R`
      (`:150-154`), figures taken from the fixture.
- [x] T4: Correct the `"burch"` sentence at `R/icc.R:377` inside `@param
      ci_method`; re-triage `data-raw/mpl-doc-claims.tsv` row `d25a8b790ea6`
      (stale key) in the same commit, and add a row for any new
      trigger-token sentence.
- [x] T5: Correct the runtime hint blurb at `R/boundary-hint.R:500` and the
      internal comment at `R/ci-classical.R:13`.
- [x] T6: Add the "when the default under-covers" subsection to
      `vignettes/interval-methods.Rmd` under the Monte-Carlo section, replace
      the preference sentence at `:106-108`, cross-link from
      `vignettes/glossary.Rmd:181-187`.
- [x] T7: NEWS bullet in the development-version section; amend the
      unreleased `:143-152` bullet; run `devtools::document()`.
- [x] T8: Run all four data-raw checkers, then the full gate; fix fallout.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-08: created by /milestone-plan (promotes the D-028 `document` candidate row; plan gate: docs + runtime hint, test-pinned figures, dedicated vignette subsection).
- 2026-08-08: plan-time criteria audit ([O], fresh context) returned six repairs — AC2's method-token clause unsatisfiable (forbade naming `"montecarlo"`), AC2's cell filter a comma-splice admitting a false universal, AC1/AC3/AC5 each unbounded over prose, AC4 missing the forced ledger re-key — all applied before the gate; it also found `R/boundary-hint.R:500` and `NEWS.md:143-152` carrying the falsified claim, which the gate folded into scope.
- 2026-08-08: plan gate chose correcting all five falsified-claim sites in this milestone over a separate follow-on fix because the caveat directs users at a method the same measurement shows failing the same cells; falsified by a measurement showing `burch` clearing the 0.93 floor on the low-abort skew cells.
- 2026-08-08: plan gate chose test-pinned numeric figures in the user docs over a qualitative-only caveat because an unquantified caveat leaves a user unable to judge exposure; falsified by the figures proving unmaintainable against fixture regeneration.
- 2026-08-08: plan chose `@section Confidence intervals:` as the caveat's roxygen home over `@param ci_method` because the section is outside every data-raw checker's sweep while the param block is keyed sentence-by-sentence; falsified by the caveat needing to be read at the point of choosing a method rather than at the point of reading about intervals.
- 2026-08-08: T0 started by /milestone-implement on `m115-skew-undercoverage-caveat`; status in-progress.
- 2026-08-08: substantive amendment at the implement gate — AC1/AC2/AC3 re-aimed from source-tree reads at the installed package (`tools::Rd_db()`, `inst/doc/`, installed `NEWS.md`, rendered hint) plus a committed `tests/testthat/fixtures/skew-undercoverage.tsv`, because a source-reading test skips under `R CMD check` (`.Rbuildignore ^data-raw$`) and would leave AC1-AC3 with no PR-CI evidence; tasks resplit 7 -> 8 and Coverage remapped.
- 2026-08-08: T1 done — `data-raw/make-skew-undercoverage-fixture.R` derives `tests/testthat/fixtures/skew-undercoverage.tsv` (202 rows: 192 M113 grid + 10 M114 held-out cells); provenance tests re-derive both legs from the sources and assert the text round trip, source-tree-gated; 89 assertions pass.
- 2026-08-08: T2 done — installed-surface assertions written and RED before any doc edit: 9 failures, 0 errors (caveat absent; `never under-cover` still in the Rd and NEWS; the rendered hint still promises it). `icc_rd()` reads the installed help DB, falling back to source `man/icc.Rd` under load_all where `Rd_db()` errors.
- 2026-08-08: T3 done — caveat authored in `@section Confidence intervals:`; AC1/AC2 assertions now green (every numeral in the block traces to the fixture, quoted method tokens are exactly `"searle"`/`"burch"`), 5 failures remain and all belong to T4-T7.
- 2026-08-08: T4 done — `@param ci_method`'s burch description now states the measured limit (worst 0.6655) instead of never-under-covering; ledger row `d25a8b790ea6` deleted rather than re-keyed because the new sentences carry no trigger token and are not claim candidates; `check-mpl-doc-claims.py` OK (40 candidates, 0 failures).
- 2026-08-08: T5 done — runtime hint blurb and the `R/ci-classical.R` header comment now state the measured limit; the full existing `test-boundary-abort-hint.R` suite passes unchanged against the new blurb.
- 2026-08-08: T6 done — vignette gains a `### When the default under-covers` subsection under the Monte-Carlo section, the closed-forms preference sentence is replaced, and the glossary Monte-Carlo entry cross-links the new subsection.
- 2026-08-08: T7 done — two NEWS bullets under Minor improvements (the caveat, and an explicit Correction withdrawing the burch claim across help/article/runtime message); the unreleased searle/burch feature bullet amended in place; `document()` leaves no `man/` diff; the caveat test file is fully green.
- 2026-08-08: T8 — all four data-raw checkers exit 0; `air format --check` clean; `lintr::lint_package()` 0 lints; full suite at NOT_CRAN=true CI=true 0 failures / 0 errors / 25 skips.
- 2026-08-08: added a vignette-side numeral assertion (same bar as the help-page block, source-tree fallback for dev sessions) beyond what AC1 requires; the caveat file is green.
- 2026-08-08: `devtools::check()` (--no-manual, NOT_CRAN=false) Status OK — 0 errors / 0 warnings / 0 notes, vignettes built.
- 2026-08-08: verified the amendment's purpose against a real install (`devtools::install(build_vignettes = TRUE)`): the caveat file runs 124 assertions with 0 failures, 0 errors and **0 skips** — the installed-Rd, installed-NEWS and shipped-vignette branches all execute rather than skipping, which is what the source-tree design would have done.
- 2026-08-08: all tasks done; status review.
- 2026-08-08: review return 1 — AC3 FAILED. `R/icc.R:555-556` still ships "never / under-covering" for `"burch"` in the Details block, a sixth site the Scope's five-site enumeration missed; the line-wrap defeated both the AC3 grep and the test's fixed-string match, so AC3's recorded evidence was a false negative (F1, scored 96). Also actioned: F4 (88) the gaussian/uniform "no such shortfall" claim is false (0.7210/0.7247), and F2 (82) the "grows with raters" claim is reversed by the data. Status back to in-progress.
- 2026-08-08: amendment return: AC3 — "The withdrawn claim (`never under-cover`, however its line wraps) is absent from ... verified over whitespace-collapsed text by `tests/testthat/test-doc-skew-caveat.R` ... rather than by a line-based grep, which returns 0 against a wrapped occurrence"; the original procedure was shown blind by mutation — reintroducing the wrapped sentence left `git grep -c` at 0 while the new guard failed on two assertions and named the file.
- 2026-08-08: return-1 fixes — F1 sixth site corrected at `R/icc.R:555`; F2/F3 trend sentence rewritten to what the fixture supports (coverage falls with subject count at 5 raters once ICC is moderate/high; 2 raters worse in all 16 paired cells but abort more often); F4 restored D-027's high-abort qualifier; F5 held-out claim scoped to the (50,5) geometry; F6 the unbacked "steadier under mild non-normality" recommendation replaced across four sites by the measured comparison (searle closer to nominal in most cells of every family; burch below-nominal in fewer cells), pinned by a new test and two `out` ledger rows; F13 provenance test gains the `coverage_uncond` re-derivation; an attribution pin added, mutation-verified against the reviewer's fabricated-cell mutation.
- 2026-08-08: all six criterion checkboxes un-ticked — their recorded evidence predates the return-1 fixes; re-review re-gathers all of it.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Evidence gathered 2026-08-08 on `m115-skew-undercoverage-caveat` @ c7bdcb2+,
PR #124. Every figure below was produced by running the command named, never
recalled.

- **AC1 — met.** `tests/testthat/test-doc-skew-caveat.R` run against the
  INSTALLED package (`devtools::install(build_vignettes = TRUE)`, then
  `test_file(..., package = "intraclass")`): 124 assertions, 0 failures,
  0 errors, **0 skips** — so the installed-Rd branch executed rather than
  falling back. The block's numeral extractor accepts only fixture values or
  the two-entry allowlist; it also asserts the block is non-empty of numerals,
  so it cannot pass on a caveat with no figures.
- **AC2 — met.** Same run. The 10-cell paired assertion holds (and asserts the
  count is exactly 10, not merely non-zero); the quoted-token enumerator finds
  only `"searle"` and `"burch"` in the block and cross-checks the allowlist
  against the fixture's own `method` column. The source-tree provenance test
  re-derives both fixture legs from `data-raw/m113-skew-response-coverage.tsv`
  and `data-raw/m114-warn-trigger-stats.tsv` and passes.
- **AC3 — FAILED (return, 2026-08-08).** The recorded grep evidence below is a
  false negative; see the findings block. Original evidence line kept for the
  record: `git grep -c "never under-cover" -- R/icc.R R/boundary-hint.R
  R/ci-classical.R vignettes/interval-methods.Rmd NEWS.md` exits 1 with no
  output (no match on any of the five paths). The installed-surface absence
  assertions and the rendered-hint assertion are in the same 0-failure run;
  the hint is rendered via `cli::format_message()` per the M93 lesson. The
  full pre-existing `test-boundary-abort-hint.R` suite passes unchanged
  against the new blurb.
- **AC4 — met.** `check-mpl-doc-claims.py`, `check-record-claims.py`,
  `check-reference-observations.py` and `enumerate-generalizing-claims.py
  --check` each exit 0. No ledger row was added: the replacement sentences
  carry none of the checker's trigger tokens and are therefore not claim
  candidates, so the stale row was deleted rather than re-keyed.
- **AC5 — met.** Two bullets under `## Minor improvements` — the caveat
  (naming 0.6725 at the worst cell) and an explicit **Correction.** bullet
  withdrawing the `"burch"` claim and recommendation across help page,
  article and runtime message. Both figures they name (0.6725, 0.6655) are
  ones the AC1 test recomputes from the fixture.
- **AC6 — met.** `devtools::document()` leaves 0 changed paths under `man/`
  and `NAMESPACE`. Full suite at `NOT_CRAN=true CI=true`: 0 failures,
  0 errors, 25 skips. `air format --check .` exit 0; `lintr::lint_package()`
  0 lints.

**Consistency gate.** `cairn_validate` — all checks passed, no advisories.
`cairn_impact` skipped: `cairn/DESIGN.md` is untouched, so no principle
changed. Toolchain slot (`r-package`): `document()` no-diff confirmed above;
`devtools::check(args = "--no-manual", env_vars = c(NOT_CRAN = "false"))`
Status OK — 0 errors, 0 warnings, 0 notes, vignettes built;
`pkgdown::check_pkgdown()` no problems; README.Rmd/README.md untouched, so no
re-knit owed; no new top-level files, so no `.Rbuildignore` entry owed.

**Independent review — three lenses + scorer (2026-08-08).** Blame-history:
no findings. Prior-review/lessons: no findings (PR-thread probe returned `[]`,
so the thread walk was skipped). Diff-bug lens: 20 candidate findings, scored
by a fresh scorer against the diff and this plan. Three scored >= 80 and are
actioned; 17 scored below 80 and are logged, not actioned:
F3 78 (same sentence as F2, fixed with it), F5 62, F13 62, F10 58, F9 55,
F6 50, F15 50, F11 45, F14 45, F16 40, F17 35, F7 30, F8 30, F18 30, F21 30,
F12 25, F19 15, F20 10.

Actioned findings, verbatim:

- **F1 (96).** `R/icc.R:555-556` (rendered at `man/icc.Rd:648-649`), in the
  Details block: "kurtosis-adjusted `log(1 + n*theta-hat)` limits (Burch
  2011), so its width tracks the data's tail weight -- wider but robust to
  non-normality, and never / under-covering." This is the exact claim D-027
  falsified, on the same help page the caveat was added to, at a sixth site
  the Scope's "all five sites" never enumerated. It wraps across two lines,
  so AC3's `git grep -c` and the test's `fixed = TRUE` match over the
  flattened Rd both miss it. AC3 was recorded met on a false negative.
- **F4 (88).** "near-normal and uniform subject effects showed no such
  shortfall" (`R/icc.R:165-166`, `vignettes/interval-methods.Rmd:80-81`) is
  false: gaussian reaches `coverage_nonabort` 0.7210 and uniform 0.7247 (both
  at rho 0.05, k 10, n 2). D-027's true statement carries the qualifier the
  docs dropped -- every failing gaussian/uniform cell is in the high-abort
  bucket.
- **F2 (82).** "The shortfall grows with the number of raters per subject"
  (`R/icc.R:163-165`, `vignettes/interval-methods.Rmd:79`) is contradicted by
  the fixture: at k = 10, chisq1, the n = 2 cells cover worse than the n = 5
  cells at every rho (0.7322 vs 0.8701 at rho 0.05). The claim was composed
  from the abort-filtered subset, where 9 of 10 failing cells happen to be
  n = 5 -- a selection artifact read back as a trend.

All three verified independently against
`data-raw/m113-skew-response-coverage.tsv` before actioning.

**Disposition: return to `in-progress`.** F1 demonstrates AC3 failing inside
its named procedure's domain, which is the return floor. AC3 is un-ticked;
AC1, AC2, AC4-AC6 stand on their recorded evidence.

**Returns.** Defect return 1 of this milestone (first review pass). One
amendment return was taken at the implement gate (AC1-AC3) and runs on its
own track.

