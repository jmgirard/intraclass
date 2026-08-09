# M116: Correct the falsified `"searle"`/`"burch"` width claims

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** —

## Goal

Replace the shipped claim that `"burch"` is wider than `"searle"` — falsified by
both committed classical grids and contradicted by Burch (2011) — with a bounded
statement of what this package actually measured.

## Scope

**In:** the six user-facing sites carrying the width claim (`R/icc.R` roxygen →
`man/icc.Rd`, the `R/ci-classical.R:127` header comment, the `R/boundary-hint.R:500`
runtime hint, `NEWS.md:163`, `vignettes/interval-methods.Rmd:143`,
`vignettes/glossary.Rmd:130`); a recomputation over the two committed fixtures; a
source read establishing what Burch (2011), McGraw & Wong (1996) and Searle (1971)
do and do not claim about interval length; the `D-012 Amendment 1` correction and
the M76 comparison page; and the D-entry drawing D-021's line.

**Out:** a both-components-non-normal sweep testing Burch's leptokurtic reversal
in this repo → candidate row. Any change to the coverage-based "prefer `searle`"
recommendation, which M115 established and this evidence does not touch → not
planned. A committed doc-claim checker → barred by D-021.

## Acceptance criteria

- [ ] AC1: `cairn/references/burch2011.md` records, with quotations verified
      verbatim against the PDF and its `Extraction:` line re-stamped: Burch's
      platykurtic-shorter result (88% of normal-based length at a=100, b=5,
      ρ=0.25, uniform(0,1)); his leptokurtic-wider statement; that both `A_i`
      and `e_ij` carry the studied distribution; and that his "normal-based"
      comparator is the eq. (3) exact-F pivot the package ships as `"searle"`.
      `mcgraw1996.md` and a new `searle1971.md` each record whether that source
      makes any interval-length claim.
- [ ] AC2: A committed R script recomputes from `data-raw/m76-sweep-results.rds`
      and `data-raw/m113-skew-response-coverage.tsv`, writing a committed text
      output: burch's median width below searle's in 16/16 M76 cells (8/8
      gaussian) and 59/64 M113 cells, broken out per `dist` family
      (gaussian 14/16, uniform 16/16, t5 15/16, chisq1 14/16) with each family's
      median width ratio. Comparisons are `{searle, burch}` only — both legs
      abort in 0 cells, where the MC leg's widths are conditioned on non-abort.
- [ ] AC3: The claim-pattern set in `tests/testthat/test-doc-skew-caveat.R`
      (installed-surface + source-tree legs, whitespace-collapsed) is extended
      to the width claim, and both legs pass. Each pattern is mutation-verified:
      reintroducing the exact withdrawn wording reds the test.
- [ ] AC4: `?icc`, `vignettes/interval-methods.Rmd`, `vignettes/glossary.Rmd`,
      `NEWS.md` and the `R/ci-classical.R` header comment each state the width
      relationship as measured-and-bounded — the direction on this package's
      grids, that those grids vary the subject effect only, and that Burch
      reports a leptokurtic reversal under a condition they do not test. Every
      figure traces to AC2's output or an AC1 quotation.
- [ ] AC5: The `R/boundary-hint.R` runtime hint no longer describes `"burch"` as
      wider; its replacement is pinned inside the existing hint test at
      `test-doc-skew-caveat.R:353`, whose `"heavy"` assertion still passes.
- [ ] AC6: `cairn/DECISIONS.md` carries `D-012 Amendment 1` correcting D-012's
      two width clauses (`DECISIONS.md:394`, `:399`) and a new D-entry recording
      that D-021's door governs records-verification apparatus, not corrections
      to shipped user-facing documentation and runtime messages.
      `cairn/references/classical-oneway-comparison.md` is corrected wherever the
      direction appears — the C3 narrative (`:110–116`), the ledger table
      (`:125`) and the Disposition (`:140–147`) — under a dated D-009
      observation whose `check:` directive runs on python3/shell/git alone and
      is mutation-verified.
- [ ] AC7: Green on `cairn_validate`; `check-reference-observations.py`,
      `check-mpl-doc-claims.py`, `check-record-claims.py` and
      `enumerate-generalizing-claims.py --check` with each one's `--self-test`;
      `air format --check`; `lintr::lint_package()`; and the installed-package
      suite at `NOT_CRAN=true CI=true`. The reworded sentences are listed
      explicitly in the work log with their ledger disposition, including
      re-keying `generalizing-claims-triage.tsv:274` and
      `mpl-doc-claims.tsv:72–73`, which the edits stale by hash.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T4
- AC4 → T3
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks

- [ ] T1: Read the sources and write the provenance. Burch (2011) §4 (Fig. 2
      expected-length ratios) and §5; `mcgraw1996.pdf` for any length claim
      (none found at plan time); Searle (1971) when the maintainer supplies the
      PDF — that leg alone blocks on it. Settle every quotation with a
      high-DPI crop where the text layer is doubtful (LESSONS M66).
- [ ] T2: Write `data-raw/m116-classical-width-comparison.R` and its committed
      output. The DGP fact belongs to the sweep scripts, not the fixtures —
      assert it against `data-raw/m76-coverage-sweep.R:33-38` and
      `data-raw/m111-fallback-sweep.R:57-67` (M113's tsv re-derives
      `m111-fallback-results.rds`; it runs no sweep of its own).
- [ ] T3: Rewrite the five prose sites. Numerals matched on numeric boundaries
      and attributions checked against the specific row (LESSONS M115); no
      monotonicity or comparative claim written without recomputing it over the
      unfiltered grid.
- [ ] T4: Extend the `test-doc-skew-caveat.R` pattern set and the hint text,
      mutation-verifying each. Install with `build_vignettes = TRUE` and confirm
      0 SKIPs (LESSONS M115).
- [ ] T5: Append `D-012 Amendment 1` and the D-021-line entry; correct the M76
      comparison page whole-file with its dated observation.
- [ ] T6: Ledger re-keying and the full gate; open the PR and drive CI green.

## Work log

- 2026-08-08: created by /milestone-plan (promotes the M115 re-review G1 candidate row; plan gate: D-021 proceed-with-a-line, bounded claim over a new sweep, maintainer to supply Searle 1971).
- 2026-08-08: plan gate chose bounding the doc claim to the two committed grids over running a both-components-non-normal sweep, because the existing evidence already falsifies the shipped claim and a new grid answers a different question; falsified by a user needing width advice for leptokurtic data.
- 2026-08-08: plan gate chose extending `test-doc-skew-caveat.R`'s existing M115 sweep over authoring a second instrument, because a parallel sweep is the doc-claim guard D-021 bars and the existing one already covers the same six files plus the installed help database; falsified by the existing test's legs proving unable to carry the width pattern.
- 2026-08-08: plan-time criteria audit ran ([O] fresh-context reader, 14 findings). Fixed here: AC2 could not recompute the DGP fact from the fixtures and mis-named M113's provenance; the three-way "narrowest" ranking was contaminated by the MC leg's abort-conditioned widths; AC2 gained per-family breakouts after the audit showed a kurtosis-conditional rewrite would itself be unbacked; `NEWS.md` and the `R/ci-classical.R` comment gained a positive replacement owner; the D-009 directive was constrained to python3/shell/git; AC6 widened to the whole comparison page; AC7's checkers were named with `--self-test` and its "every reworded claim" universal replaced with an explicit list, since `check-mpl-doc-claims.py`'s trigger net misses the comparative class. Routed to the gate: the D-021 collision (AC5) and the sweep-scope question.

## Decisions

## Review
