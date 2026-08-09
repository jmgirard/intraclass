<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M115: Document the default interval's skew/kurtosis under-coverage — and withdraw the falsified `"burch"` advice

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m115-skew-undercoverage-caveat`   <!-- owner: implement (branch) / review (PR URL) · create -->

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
- [ ] AC3: The literal string `never under-cover` is absent from `R/icc.R`,
      `R/boundary-hint.R`, `R/ci-classical.R`, `vignettes/interval-methods.Rmd`
      and `NEWS.md` (one `git grep -c` over those five paths returns 0,
      recorded as review evidence); and the test asserts, against the
      installed package, that the string is absent from `icc.Rd`, the shipped
      `inst/doc/interval-methods.Rmd` and the installed `NEWS.md`, that the
      rendered `boundary_method_hint()` blurb for `"burch"` no longer claims
      it never under-covers, and that the Rd, the vignette and the hint each
      name the measured heavy-tail exception (`burch` worst
      `coverage_uncond` 0.6655 at ρ = 0.60, k = 30, n = 5, chisq1).
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

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
