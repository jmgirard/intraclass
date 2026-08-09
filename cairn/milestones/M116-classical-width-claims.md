# M116: Correct the falsified `"searle"`/`"burch"` width claims

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m116-classical-width-claims`

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
      makes any interval-length claim. `searle1971.md` locates the exact-F
      interval at Ch. 9 §9d / Table 9.14 / eq. (60), and the `Searle 1971
      eq. 4/6` citation at `R/ci-classical.R:10` — which attributes ohyama2025's
      own equation numbers to Searle — is corrected to it.
      `cairn/references/ohyama2025.md:33` keeps ohyama's numbering, which is
      faithful to that source, disambiguated to say the numbers are ohyama's and
      that his eq. 6 is the Thomas & Hultquist (1978) unbalanced variant rather
      than Searle's.
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

- [x] T1: Read the sources and write the provenance. Burch (2011) §4 (Fig. 2
      expected-length ratios) and §5; `mcgraw1996.pdf` for any length claim
      (none found at plan time); `searle1971.epub` per the work-log findings
      below, including the equation-citation correction. Settle every quotation
      with a high-DPI crop where the text layer is doubtful (LESSONS M66) —
      Searle's equations are `.gif` images, so quote its prose only and read
      Table 9.14 from the image.
- [x] T2: Write `data-raw/m116-classical-width-comparison.R` and its committed
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

- 2026-08-08: maintainer supplied `cairn/references/sources/searle1971.epub` (Wiley Classics Library Edition 1997, a verbatim reprint of the 1971 text — same LC card number 70-138919 — so equation and table numbering match the original). T1's Searle leg is unblocked.
- 2026-08-08: plan-time read of Searle (1971). The exact-F interval is Ch. 9 §9d "Confidence intervals", Table 9.14 ("Confidence intervals on variance components and functions thereof, in the 1-way classification, random model, balanced data"), built on eq. (60) for `F = MSA/MSE`; Searle credits the σ²e/(σ²α+σ²e) interval to Graybill (1961, p. 379) and the σ²α/σ²e one to Scheffé (1959, p. 229). No interval-length or narrowness claim attaches to it anywhere in Ch. 9. The book's only shortest-length optimality result is in Ch. 3 §5 and concerns the symmetric t-interval on a regression coefficient in the full-rank model — a different object; T1 records it as the candidate provenance for "narrowest" without asserting it is the actual origin. Three sources now checked (Burch 2011, McGraw & Wong 1996, Searle 1971) and none supports the shipped claim.
- 2026-08-08: gated amendment — AC1 and T1 gain the `Searle 1971 eq. 4/6` citation correction at `R/ci-classical.R:10` and `cairn/references/ohyama2025.md:33`, found by the plan-time source read (the interval is Table 9.14 / eq. (60); the reprint is verbatim, so the numbering is not an edition artifact). Maintainer chose folding it in over a candidate row, per D-021's correct-in-place clause.

- 2026-08-08: branched `m116-classical-width-claims` from main at cbb6da0; status in-progress.

- 2026-08-08: T1 done. burch2011.md gains an expected-length section (§3 eq. 18 p. 1023, Fig. 2 findings p. 1024, §5 p. 1027) — Burch's direction is kurtosis-conditional (REML shorter for platykurtic, wider for symmetric leptokurtic, "thus wider intervals are warranted") and measured with BOTH A_i and e_ij non-normal; four quotations re-checked verbatim, de-hyphenated across line breaks. searle1971.md written: the interval is Ch. 9 §9d Table 9.14 row 3 + eq. (60), matching searle_endpoints() term for term (g = F/F_U, rho = (g-1)/(g+n-1)), credited onward to Graybill (1961, p. 379); NO interval-length claim in Ch. 9. mcgraw1996.md records the same absence, settled two ways per LESSONS M66 (whole-text vocabulary sweep over 51,534 chars = 0 interval-size hits; printed p. 41 re-read at 150 DPI, render matches the text layer so the source is born-digital not OCR). Both Extraction lines re-stamped 2026-08-08.
- 2026-08-08: T1 correction to a plan-gate finding — "eq. 4/6" are ohyama2025's OWN equation numbers (his eq. 4 is the balanced Searle interval verbatim; his eq. 6 is the Thomas & Hultquist 1978 unbalanced variant), not Searle's. So R/ci-classical.R:10 was genuinely wrong (it read ohyama's numbers as Searle's) and is corrected to Ch. 9 Table 9.14; ohyama2025.md:33 was NOT wrong and keeps its numbering, gaining a note above the table saying whose numbers they are. Correcting it as AC1 first directed would have falsified a verified extraction.
- 2026-08-08: amendment gate — AC1's citation clause amended to the split above (maintainer chose "amend as proposed" over dropping the ohyama half or the whole citation fix).
- 2026-08-08: the whole-book length-vocabulary search over Searle's eleven chapter files returned a hit in Ch. 2 as well as Ch. 3; the Ch. 2 one is "the much shorter proof of Banerjee (1964)" — about a proof, not an interval. The note was corrected before commit to say "two chapters", not the "Chapter 3 only" first drafted (LESSONS 2026-07-19/M72: do not ship an unverified universal in the prose that records a lesson).
- 2026-08-08: M74 gate caught six new generalizing-claim candidates and one orphan row, as LESSONS 2026-07-21/M76 predicts for any references/ edit. Rows added programmatically via the enumerator's own key function (no hand-transcribed hashes): burch2011:1e38e8e767 OUT-quote; mcgraw1996:cafe812bae OUT-provenance (replacing the staled cedef8f67b); mcgraw1996:236dda51d7, searle1971:5d42925a3a, searle1971:41b8940b0c, searle1971:16af2c708c OUT-repo-analysis. Enumerator, observations checker and both self-tests green; devtools::test() FAIL 0 PASS 6027 SKIP 25.

- 2026-08-08: T2 done. `data-raw/m116-classical-width-comparison.R` + committed `.tsv`: burch median width below searle's in 16/16 M76 cells (8/8 gaussian, 8/8 t5) and 59/64 M113 cells (gaussian 14/16, uniform 16/16, t5 15/16, chisq1 14/16); every family's median ratio is below 1 on both grids (0.9424-0.9648), so NO family reverses and the docs must not state a kurtosis-conditional direction. Nine count pins plus an all-families-below-1 pin are asserted in-script. Comparator fenced to {searle, burch} — both abort in 0 cells; the MC leg is excluded because its widths are conditioned on non-aborted reps (764/2000 at one cell).
- 2026-08-08: T2's DGP fence took three attempts and the first two shipped green while being wrong — worth a LESSONS line. (1) A lexical search for the t-generator matches `sqrt(`, which contains `rt(`, so the guard reported a dependence that does not exist. (2) A positional rule ("no non-gaussian generator at or below the error-draw line") passed the mutation test: hoisting the offending draw into a variable one line above defeats it. Only the third, which walks the PARSED function body and requires every RNG call to belong either to the subject-effect RHS or to the error RHS (rnorm only), reds. Mutation-verified three ways — hoisted draw, inlined draw, and a de-branched subject effect — each redding a distinct assertion.

## Decisions

## Review
