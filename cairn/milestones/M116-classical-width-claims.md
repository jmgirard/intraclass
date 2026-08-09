# M116: Correct the falsified `"searle"`/`"burch"` width claims

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m116-classical-width-claims` / PR #125

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

- [x] AC1: `cairn/references/burch2011.md` records, with quotations verified
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
- [x] AC2: A committed R script recomputes from `data-raw/m76-sweep-results.rds`
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
- [x] AC5: The `R/boundary-hint.R` runtime hint no longer describes `"burch"` as
      wider; its replacement is pinned inside the existing hint test at
      `test-doc-skew-caveat.R:353`, whose `"heavy"` assertion still passes.
- [x] AC6: `cairn/DECISIONS.md` carries `D-012 Amendment 1` correcting D-012's
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
- [x] T3: Rewrite the five prose sites. Numerals matched on numeric boundaries
      and attributions checked against the specific row (LESSONS M115); no
      monotonicity or comparative claim written without recomputing it over the
      unfiltered grid.
- [x] T4: Extend the `test-doc-skew-caveat.R` pattern set and the hint text,
      mutation-verifying each. Install with `build_vignettes = TRUE` and confirm
      0 SKIPs (LESSONS M115).
- [x] T5: Append `D-012 Amendment 1` and the D-021-line entry; correct the M76
      comparison page whole-file with its dated observation.
- [x] T6: Ledger re-keying and the full gate; open the PR and drive CI green.

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

- 2026-08-09: T3 done. Five prose sites rewritten to the measured-and-bounded form (?icc @param + the classical Details section, R/ci-classical.R header, vignettes/interval-methods.Rmd, vignettes/glossary.Rmd, NEWS.md), plus a new NEWS correction bullet. "narrowest" is gone from every searle description; "wider" survives only where it reports Burch's own kurtosis-conditional finding or names the wider M113 grid. One collateral fix: interval-methods.Rmd's figurative "a narrower kind of steadiness" now sat beside a real width discussion, so it reads "a more limited kind of steadiness". The NEWS bullet was reworded mid-task to stop quoting the phrases it withdraws — the test file's own header requires that, and the first draft quoted both.
- 2026-08-09: T4 done. claim_pattern (scalar) became claim_patterns (6 named) behind one expect_no_withdrawn_claim() helper, applied to the installed-help, installed-NEWS, installed-vignette and source-tree legs plus the runtime hint; glossary.Rmd added to the installed leg. Patterns are multi-word by necessity: a bare "narrowest" reds on the vignette's legitimate HPDI paragraph and a bare "wider" on Burch's own reported reversal. Each of the five new patterns has zero hits on the corrected tree and >=1 on the pre-correction tree (4cffc81), and each was mutation-verified by reintroduction: "and narrowest" 1 failure, "narrowest on near-normal" 2, "narrowest)" 1, "wider, and" 1, "wider and below-nominal" 2; baseline 0.
- 2026-08-09: the runtime hint (R/boundary-hint.R) drops both width words; its test now also asserts no "narrow"/"wider" renders at all, since the hint is where a user actually picks a method. The existing "heavy" assertion still passes.
- 2026-08-09: AC3's 0-SKIP requirement (LESSONS M115) needed a harness change, not just an install. `devtools::install(build_vignettes = TRUE)` installs the vignettes, but `testthat::test_local()` loads via pkgload so `system.file("doc", ...)` still resolves to the source tree and both installed-surface tests skip. Running `testthat::test_dir("tests/testthat", package = "intraclass", load_package = "installed")` gives the real installed-package read: doc-skew-caveat 0 skips, all pass. (`upgrade = "never"` is rejected by devtools::install — it wants TRUE/FALSE/NA.)
- 2026-08-09: M94 checker caught three new roxygen claims (its fifth recurrence per LESSONS); rows 2bdf1189679b / 354d6f11619c / d010e0f961a6 added dispositioned `out`, each naming the instrument that does settle it (the M116 tsv, the generator's AST assertion, or burch2011.md p. 1024) per the M104 rule. All four data-raw checkers and their self-tests green.

- 2026-08-09: T5 done. `D-012 Amendment 1` corrects the two width clauses against D-012's OWN fixture and names the root cause: C3 compares each classical method to MC, never to each other, and "bought with width" was carried across to a searle-vs-burch comparison the sweep never made. The GO/NO-GO verdict, scope fence and opt-in recommendation are explicitly untouched — they rest on coverage, tails and aborts. `D-029` records where D-021's door falls: it governs records-verification apparatus, not corrections to what the package tells users; M116 accordingly ships no new checker and extends M115's instrument instead.
- 2026-08-09: classical-oneway-comparison.md corrected in three places (C3 narrative, D1 SEARLE bullet, D2 Burch bullet) under one dated observation whose directive reads the M116 tsv with python3 alone (LESSONS M91) and reds when the figure is flipped. The D2 bullet also gains the grid-locality of "never under-covers" (M113 measured 0.6655, D-027). The **ledger table at :135 was left alone** — the audit expected a wrong direction there, but its C3 column counts fails against MC only and is correct as written; changing correct numbers to satisfy an expectation would have been the error.
- 2026-08-09: M74 gate again — four new candidates plus the two orphans the plan-time audit predicted (39c943d64a, the "narrowest" row, and f59492dac8). Retired both, added four OUT-repo-analysis rows naming the M116 tsv as the settling instrument. All four data-raw checkers green.

- 2026-08-09: T6 done. Full gate green: installed-package suite (vignettes built, `test_dir(package=, load_package="installed")`) 0 failed / 0 error / 6082 passed / 23 skipped, every skip a live-Stan brms test reading `On CI` and none in the doc pins; `cairn_validate`; all four data-raw checkers plus each `--self-test`; `air format --check`; `lintr::lint_package()`; `pkgdown::check_pkgdown()`. PR https://github.com/jmgirard/intraclass/pull/125 opened via REST (LESSONS M63 GraphQL budget); all 9 PR checks success — check-references, format-check, lint, pkgdown, test-coverage, both codecov, ubuntu-latest (release), windows-latest (release).
- 2026-08-09: CI scope note for review — `check-standard.yaml`'s `pull_request` matrix is ubuntu-release + windows-release only; macOS, R-devel and oldrel-1 run on push to main, so those three legs are exercised only after merge. Deliberate (M77/M78), not a gap, but it means the PR's green is narrower than the full matrix.
- 2026-08-09: `docs/` is gitignored and untracked, so the stale rendered pkgdown pages carrying the withdrawn claim are a local build artifact only and ship nowhere; no action taken.
- 2026-08-09: status -> review.
- 2026-08-09: review pass 1 returned the milestone. AC4 fails: `vignettes/interval-methods.Rmd` claims "no distribution family reverses it — not the gaussian cells, not the heavy-tailed t(5) ones, not the skewed chi-square(1) ones", but the committed tsv records five reversing cells lying in exactly those three families (gaussian 1.00075/1.00027, t5 1.00276, chisq1 1.00511/1.02110); only `uniform` has none, and it is unnamed. AC1/AC2/AC5/AC6 verified with fresh evidence and ticked; AC3/AC7 measured green but left unticked because the fix re-opens the swept prose and the gate. Also actioned: F1 "median of about 4%" traces only to the pooled 80-cell median, not to either grid's own; F19 `skip_if()` inside the vignette loop skips the whole test_that so `glossary.Rmd` goes unchecked when `interval-methods.Rmd` is absent. Status -> in-progress. Defect returns: 1.

## Decisions

## Review

### Pass 1 — 2026-08-09 (returned: AC4 fails)

Branch synced: `main` had not moved since the cut (`cbb6da0`), so no merge-forward.
PR https://github.com/jmgirard/intraclass/pull/125, all 9 checks green at
`34597ad` (the reviewed HEAD).

**AC1 — PASS.** Every quotation re-verified against the shelf sources in this
session, not from the notes. `burch2011.pdf` via `pdftotext` + de-hyphenation:
all six probes hit verbatim (the 88% sentence, "thus wider intervals are
warranted", the leptokurtic-wider sentence, the §5 platykurtic-shorter sentence,
the eq. 18 length-ratio heading, and the Fig. 2 setup naming both `A_i` and
`e_ij`). `mcgraw1996.pdf`: the recorded vocabulary sweep reproduces — 0 hits for
`narrow*`/`shortest`/`shorter`/`width`/`precise*`/`tight*`, 1 `length`, 4
`wide*` (all "widely"/"widespread"). `searle1971.epub`: the length-vocabulary
search over all 11 chapter files returns hits in exactly two — Ch. 2 (the
Banerjee proof) and Ch. 3 (the regression-coefficient t-interval) — and **zero
in Ch. 9**, and every Ch. 9 / Ch. 3 quotation hits verbatim. Table 9.14 read
from `images/414-2.gif`: row 3 and row 5 and the footnote match the note term
for term. `git grep -iE 'Searle 1971 eq\.? *4'` over `R man vignettes NEWS.md`
returns nothing; `ohyama2025.md` keeps its numbering with the disambiguating
note.

**AC2 — PASS.** `Rscript data-raw/m116-classical-width-comparison.R` re-run from
a clean tree: exits 0, all nine count pins and the all-families-below-1 pin
hold, and the committed `.tsv` is byte-identical afterwards (`git status` clean).
Figures reproduce exactly: m76 16/16 (gaussian 8/8, t5 8/8), m113 59/64
(gaussian 14/16, uniform 16/16, t5 15/16, chisq1 14/16), family median ratios
0.9424–0.9648. The comparator is fenced to `{searle, burch}` in code and both
legs' abort columns are asserted zero on both grids.

**AC3 — PASS on both legs, not ticked.** Installed-package run
(`devtools::install(build_vignettes = TRUE)` then
`testthat::test_dir(package = "intraclass", load_package = "installed")`, at
`NOT_CRAN=true CI=true`): FAIL 0 / WARN 2 / SKIP 23 / PASS 6082, and all 23
skips are `test-icc-brms.R` "On CI" — **0 skips in `test-doc-skew-caveat.R`**,
so both the installed-surface and source-tree legs actually executed.
Mutation-verified fresh, one injected sentence per pattern into a swept file:
baseline FAIL 0, and each of the six reintroductions reds (2, 4, 4, 2, 2, 2
failures); tree restored clean after each. Not ticked because the AC4 fix
re-opens the swept prose.

**AC4 — FAIL.** The measured-and-bounded shape is present at all five sites
(direction on both grids, the subject-effect-only fence, Burch's reversal named
as untested here), but one figure-claim does not trace to AC2's output:
`vignettes/interval-methods.Rmd` states "no distribution family reverses it —
not the gaussian cells, not the heavy-tailed `t(5)` ones, not the skewed
chi-square(1) ones", while the committed tsv records five reversing cells lying
in exactly those three families (gaussian 1.00075 and 1.00027, t5 1.00276,
chisq1 1.00511 and 1.02110); the one family with no reversing cell, `uniform`,
is the one not named. What AC2 supports is "no family's *median* reverses".
Finding F2 below.

**AC5 — PASS.** Both width words are gone from `boundary_fenced_hint()`; the
hint test (now `test-doc-skew-caveat.R:378`) carries the pinned replacement plus
`expect_false(grepl("narrow"|"wider"))`, and its `"heavy"` assertion still
passes in the installed run above.

**AC6 — PASS.** `D-012 Amendment 1` and `D-029` are present and correct both
width clauses and the D-021 line respectively. `classical-oneway-comparison.md`
is corrected at the C3 narrative and at both Disposition bullets. Its `check:`
directive runs on python3 alone: exit 0 as shipped, exit 1 with the m76
`burch_narrower` figure flipped to 9 (tsv restored). **Enumeration item 2 of
AC6 is vacuous on measurement:** the ledger table (`:125` pre-edit, `:135` now)
carries no searle-vs-burch direction — its C3 column counts fails against MC —
so "corrected wherever the direction appears" is satisfied with nothing to
correct there. Recorded rather than silently passed; F21 below.

**AC7 — PASS, not ticked.** `cairn_validate` 16 PASS / 8 OK, exit 0. All four
`data-raw` checkers exit 0 on both their run and their `--self-test`.
`air format --check .` exit 0. `lintr::lint_package()`, `pkgdown` and the two
`R CMD check` legs verified via the PR's green checks at the reviewed sha.
`devtools::document()` produces no diff (consistency-gate). Not ticked because
the AC4 fix re-opens the gate; the full `devtools::check()` is deferred to the
re-review rather than run twice.

### Findings

Three fresh-context reviewers ([O] diff-bug, [S] blame-history, [S] prior-review)
and an [S] scorer that did not generate them. The prior-review lens found the
archived M115 G1 and M106 F2 findings this milestone descends from and reported
**no regression**; the GitHub inline-comment probe returned empty, so the thread
walk was skipped.

Actioned (≥80), 4 of 24:

- **F2 (90) — the vignette's per-family reversal claim is false.** AC4's
  failure above. → **fix now**, next pass.
- **F1 (85) — "by a median of about 4%" at four sites.** Traces only to the
  pooled median over all 80 cells (0.96054); the m76 grid's own median is
  0.9430 = 5.7%, and no pooled figure appears in the tsv. → **fix now**: state
  each grid's median, or pin the pooled figure in the script.
- **F22 (90) — the seven ACs were still unticked at `review`.** Review's own
  job under AC fencing. → **rejected as a finding**, discharged by this section.
- **F19 (80) — `skip_if()` inside the vignette `for` loop skips the whole
  `test_that`.** If `interval-methods.Rmd` is missing, `glossary.Rmd` — the leg
  this milestone added — is never checked. → **fix now**, next pass.

Logged below the bar (20), surfaced not dropped: F21 (78) AC6's ledger-table
enumeration vacuous — recorded above; F11 (75) no median-ratio pin in the
script though five prose sites state one; F20 (75) the new positive figures are
pinned by no test; F8 (72) the DGP AST fence misses RNG calls in top-level
control flow; F14 (68) `ohyama2025.md`'s check directive is self-referential;
F7 (65) `all(logical(0))` makes the abort assertions vacuous on a renamed
column; F9 (65) the fence checks the generator's name, not the error's
distribution; F15 (62) the comparison-page directive leaves "2–10%" unguarded;
F5 (55) "that study" loses its antecedent; F3 (50) the weaker family claim is
median-level only; F4 (50) "nearly every" understates m76's 16/16; F17 (50) the
patterns guard the wording, not the claim; F10 (45) the `^r[a-z]+$` net over-
and under-matches; F16 (45) a both-grids claim cites one generator; F18 (45)
the assertion passes vacuously on empty text; F6 (40) "the wider M113 grid" is
ambiguous beside a width discussion; F12 (35) an assertion message overstates
its check; F13 (30) no CI re-runs the generator against the committed tsv;
B1 (30) `ohyama2025.md`'s table cell keeps ohyama's numbering — what AC1 asked
for; F23 (25) a long NEWS line.

**Disposition: returned to `in-progress`** under the review return floor — F2
scores 90 on a defect in what the package tells its users and demonstrates AC4
failing. Defect returns for this milestone: 1.
