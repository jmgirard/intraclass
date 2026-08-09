<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M115: Document the default interval's skew/kurtosis under-coverage — and withdraw the falsified `"burch"` advice

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

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
      `tests/testthat/test-doc-skew-caveat.R` extracts every numeric token
      from that block (bounded by the `@section` tag and the next `@` tag) and
      requires each to equal a value derived from
      `data-raw/m113-skew-response-coverage.tsv` or
      `data-raw/m114-warn-trigger-stats.tsv`, or to appear in the test's
      committed non-fixture allowlist.
- [ ] AC2: The same test asserts that for every cell whose `mc` row has abort
      rate (`n_abort / n_rep`) at most 0.1 and `coverage_nonabort` below 0.93,
      both the `searle` and `burch` rows for that cell have `coverage_uncond`
      below 0.93 — 10 such cells on the committed fixture — and that every
      quoted method token in the caveat block is one of `"montecarlo"`,
      `"searle"`, `"burch"`, the test enumerating the block's quoted tokens
      rather than a hand list.
- [ ] AC3: The literal string `never under-cover` is absent from `R/icc.R`,
      `R/boundary-hint.R`, `R/ci-classical.R`, `vignettes/interval-methods.Rmd`
      and `NEWS.md` (one `git grep -c` over those five paths returns 0), the
      preference sentence at `vignettes/interval-methods.Rmd:106-108` is
      replaced, and each of `R/icc.R`, `R/boundary-hint.R` and
      `vignettes/interval-methods.Rmd` names the measured heavy-tail exception
      (`burch` worst `coverage_uncond` 0.6655 at ρ = 0.60, k = 30, n = 5,
      chisq1) — all four pinned by the AC1 test.
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

- AC1 → T1, T2
- AC2 → T1, T2, T5
- AC3 → T1, T3, T4, T5
- AC4 → T3, T7
- AC5 → T6
- AC6 → T6, T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Write `tests/testthat/test-doc-skew-caveat.R` first — fixture
      readers, the numeric-token extractor over the `@section Confidence
      intervals:` block, the quoted-method-token enumerator, the 10-cell
      paired assertion, and the five-path absence assertion. Red before any
      doc edit.
- [ ] T2: Author the `@section Confidence intervals:` caveat in `R/icc.R`
      (`:150-154`), figures derived from the two fixtures.
- [ ] T3: Correct the `"burch"` sentence at `R/icc.R:377` inside `@param
      ci_method`; re-triage `data-raw/mpl-doc-claims.tsv` row `d25a8b790ea6`
      (stale key) in the same commit, and add a row for any new
      trigger-token sentence.
- [ ] T4: Correct the runtime hint blurb at `R/boundary-hint.R:500` and the
      internal comment at `R/ci-classical.R:13`.
- [ ] T5: Add the "when the default under-covers" subsection to
      `vignettes/interval-methods.Rmd` under the Monte-Carlo section, replace
      the preference sentence at `:106-108`, cross-link from
      `vignettes/glossary.Rmd:181-187`.
- [ ] T6: NEWS bullet in the development-version section; amend the
      unreleased `:143-152` bullet; run `devtools::document()`.
- [ ] T7: Run all four data-raw checkers, then the full gate; fix fallout.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-08: created by /milestone-plan (promotes the D-028 `document` candidate row; plan gate: docs + runtime hint, test-pinned figures, dedicated vignette subsection).
- 2026-08-08: plan-time criteria audit ([O], fresh context) returned six repairs — AC2's method-token clause unsatisfiable (forbade naming `"montecarlo"`), AC2's cell filter a comma-splice admitting a false universal, AC1/AC3/AC5 each unbounded over prose, AC4 missing the forced ledger re-key — all applied before the gate; it also found `R/boundary-hint.R:500` and `NEWS.md:143-152` carrying the falsified claim, which the gate folded into scope.
- 2026-08-08: plan gate chose correcting all five falsified-claim sites in this milestone over a separate follow-on fix because the caveat directs users at a method the same measurement shows failing the same cells; falsified by a measurement showing `burch` clearing the 0.93 floor on the low-abort skew cells.
- 2026-08-08: plan gate chose test-pinned numeric figures in the user docs over a qualitative-only caveat because an unquantified caveat leaves a user unable to judge exposure; falsified by the figures proving unmaintainable against fixture regeneration.
- 2026-08-08: plan chose `@section Confidence intervals:` as the caveat's roxygen home over `@param ci_method` because the section is outside every data-raw checker's sweep while the param block is keyed sentence-by-sentence; falsified by the caveat needing to be read at the point of choosing a method rather than at the point of reading about intervals.

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
