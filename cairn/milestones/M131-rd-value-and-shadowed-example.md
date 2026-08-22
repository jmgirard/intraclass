<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M131: Say what each documented method returns, and stop shadowing the shipped dataset

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m131-rd-value-and-shadowed-example`   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: For every `man/*.Rd` page containing a `\usage` block and more than
      one `\alias`, the page's `\value` section names each topic in that page's
      `\alias` set and says what that topic returns. The page set and each
      page's alias set are enumerated by parsing `\alias` and `\usage` from
      `man/*.Rd`; the enumeration is recorded in the work log. (Today the filter
      selects exactly `man/choose_icc.Rd`, `man/d_study.Rd`, `man/icc.Rd`;
      `man/reexports.Rd` and `man/intraclass-package.Rd` carry aliases but no
      `\usage`, so the filter never selects them.)
- [ ] AC2: No `\examples` block in `man/*.Rd` binds a name the package exports
      as data. The domain is enumerated by `parse()`-ing each `\examples` block
      and collecting every name bound by a top-level `<-`, `=`, or `assign()`
      call, intersected with `data(package = "intraclass")$results[, "Item"]`
      (`"ratings"`, `"ratings_incomplete"`); `icc()`'s example uses the shipped
      `ratings` object directly.
- [ ] AC3: `R CMD check --as-cran`'s raw `Status:` line is no worse than main's,
      and the heading of its `\value`-section check is quoted verbatim in the
      work log from an actual run (the heading's exact wording is
      version-dependent and was not confirmable at plan time).
- [ ] AC4: `devtools::run_examples()` completes with no error, and each changed
      example's output is recorded in the work log.
- [ ] AC5: `NOT_CRAN=true CI=true devtools::test()` 0 failures;
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
- [ ] T2: Write per-topic `@return` prose in the roxygen behind each selected
      page (`R/icc.R`, `R/d-study.R`, `R/choose-icc.R`, `R/icc-methods.R`,
      `R/autoplot.R`), then re-document.
- [ ] T3: Enumerate example-bound names against the exported data; rewrite
      `icc()`'s example to use the shipped `ratings`, checking the printed
      output is unchanged in value.
- [ ] T4: `run_examples()`, the `--as-cran` check with its `Status:` line and
      the `\value` check heading quoted, and the gate-lite sweep.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-21: created by /milestone-plan (pre-M48 CRAN-readiness slate; user selected this item at the plan gate). Promotes the "CRAN-reviewer documentation nits, promoted at M48" candidate row, whose stated promotion condition is "Promote at M48, or on a CRAN reviewer raising either" — the plan gate chose ahead of M48 so the fix is not competing with the release checklist.
- 2026-08-21: criteria audit ran in FULL mode (user-facing tier), two rounds, fresh-context [O] reader. Round 1 found AC1's `reexports.Rd` exclusion clause inert (that page has no `\usage`, so the stated filter never selects it) and AC2's "object names assigned in each `\examples` block" enumerated by no procedure. Round 2 confirmed the page set and alias counts (3/7/8), confirmed the data intersection returns exactly `ratings` and `ratings_incomplete`, noted `man/intraclass-package.Rd` missing from AC1's parenthetical, and flagged AC3's `checking Rd \value sections` heading as unconfirmable on this machine's R 4.6.1 — AC3 was rewritten to quote the real heading from an actual run rather than assert one. All fixed before writing.
- 2026-08-21: plan gate chose documenting the existing return contract over changing any return shape to make it uniform, because GP2's one-way door closes at submission and a shape change is M48 T1's escalation, not a doc milestone's; falsified by a method whose return shape cannot be described honestly without changing it.
- 2026-08-22: /milestone-implement opened on branch `m131-rd-value-and-shadowed-example`, cut from `origin/main` at 53f77a1; status set to in-progress.
- 2026-08-22: T1 — `tools::parse_Rd()` over `man/*.Rd`, selecting pages with a `\usage` block and >1 `\alias`, selects exactly three, with these alias sets: `man/choose_icc.Rd` (3) `choose_icc`, `format.icc_recommendation`, `print.icc_recommendation`; `man/d_study.Rd` (7) `autoplot.icc_dstudy`, `plot.icc_dstudy`, `d_study`, `format.icc_dstudy`, `print.icc_dstudy`, `tidy.icc_dstudy`, `glance.icc_dstudy`; `man/icc.Rd` (8) `autoplot.icc`, `plot.icc`, `format.icc`, `print.icc`, `summary.icc`, `tidy.icc`, `glance.icc`, `icc`. Non-selected: `man/intraclass-package.Rd` (2 aliases, no `\usage`), `man/reexports.Rd` (3, no `\usage`), `man/ratings.Rd` and `man/ratings_incomplete.Rd` (1 alias each).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
