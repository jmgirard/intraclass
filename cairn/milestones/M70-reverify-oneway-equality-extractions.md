<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M70: Re-verify the one-way and equality-testing extractions (6 notes)

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m70-reverify-oneway-equality` · PR https://github.com/jmgirard/intraclass/pull/76   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Extend M69's dated-verified extraction bar to the six unverified notes that
carry a live dependency or arrived newest: M62's `ukoumunne2003` and
`ohyama2025`, and M67's `donner2002`, `konishi1989`, `naik2007`, `young1998`.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** six `cairn/references/<citekey>.md` notes (83 PDF pages) re-read
against their shelf PDFs in `cairn/references/sources/`; anchors, quotations
and values corrected in place; each `Extraction:` line upgraded to a dated
verified status; `INDEX.md`'s backlog narrative updated to match.
`ukoumunne2003` leads — it backs D-006's bootstrap-t GO and must be sound
before that `ci_method` is implemented.

**Out:** the seven M65 robustness notes → M71. `ORACLES.md` and
`BIBLIOGRAPHY.md` → M72. Any change to R code, tests, or oracle values —
a correction that would move a package value is escalated as a finding,
not applied here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] Each of the six notes has been read against its shelf PDF **to that
      source's final page** (appendices can follow the reference list —
      LESSONS 2026-07-18/M65), and its `Extraction:` line records a dated
      verified status naming what was checked.
- [x] Every quoted string in **every one of the six notes** has been re-read
      against its source and confirmed verbatim or corrected. The sweep is
      mechanical and per-note — enumerating all quotations in each note, not
      only those a prior finding named (the M67 recurrence, LESSONS
      2026-07-19).
- [x] Every page/table anchor resolves to the claimed page in the shelf PDF,
      with the pagination basis stated wherever the PDF is not the version of
      record.
- [x] Every absence claim ("not in the paper", "prints no DOI") is settled by
      a rendered page image at high DPI, never the text layer alone, or else
      is stated as "not checked" and asserts nothing further.
- [x] No note asserts anything time-relative that is false at merge.
- [x] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [x] `cairn_validate` passes and the six notes no longer appear in the
      `references staleness` advisory — achieved by re-reading the sources,
      with no status line reworded to clear the advisory (LESSONS
      2026-07-18/M68).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3, T4, T5, T6
- AC2 → T7
- AC3 → T1, T2, T3, T4, T5, T6
- AC4 → T1, T2, T3, T4, T5, T6, T7
- AC5 → T8
- AC6 → T1, T2, T3, T4, T5, T6, T9
- AC7 → T9

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: `ukoumunne2003` (17 pp) — leads; D-006's GO rests on its `log F`
      bootstrap-t. Note is thin at 81 lines; expect additions, not just
      corrections.
- [x] T2: `ohyama2025` (16 pp) — 61-line note, the thinnest on the shelf.
- [x] T3: `donner2002` (13 pp) — the only cluster member inside the
      interrater setting; its IP2 fence is stated twice and both must hold.
- [x] T4: `konishi1989` (13 pp).
- [x] T5: `naik2007` (13 pp) — the p. 6503 negative-LRT finding is
      load-bearing for INDEX.md's "must not be cited as a concordant pair".
- [x] T6: `young1998` (11 pp) — its Eq. (2.6) quotation was already corrected
      once at M67 review; re-read the whole page.
- [x] T7: mechanical quotation sweep — enumerate every quoted string in all
      six notes and re-check each against its source; record the count swept
      per note as the evidence.
- [x] T8: grep the six notes for time-relative phrasing (`at the time of
      writing`, `not yet`, `today`, `must be checked`, `not retrieved`) plus
      the `Traces to` lead sentence, and re-resolve every hit.
- [x] T9: update `INDEX.md`'s backlog narrative and the M67 paragraph; run
      `cairn_validate` and the r-package `verify` slot; confirm docs-only.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (absorbs part of the "remaining nine source extractions" candidate — `ukoumunne2003`, `ohyama2025` — and takes M67's four, which INDEX.md:243 records as backlog members not exempt from re-verification; plan gate: 3-way split, normal priority because `ukoumunne2003` backs D-006).
- 2026-07-19: T1 `ukoumunne2003` verified (17 pp, all read; Appendix A pp. 3818–3820 found and its Eq. 7 derivation re-run, reproduces exactly; Table I ρ=0.05 block confirmed cell-by-cell; 12 quotations swept, all verbatim). Six corrections, one substantive: the note claimed the transformed bootstrap-t "≈ nominal (0.95) across k, including k=10" when Table I on the page it already cited gives **0.9320** at ρ=0.001/k=10 — and the paper flags that deviation itself (p. 3814). Also: the p. 3816 "3 per cent" sentence was quoted truncated and labelled a *global* claim when it is conditional on non-normal data; eq. 4's anchor was p. 3806, actually p. 3807; normality asserted where p. 3807 calls it inessential for point estimation; a Fig. 2 plot-read replaced by exact Table I values (bootstrap-t 0.8805, BCa 0.8280); "strategy 1" was not the source's label. No package value affected.
- 2026-07-19: T2 `ohyama2025` verified (16 pp, all read; §3.2 settings confirmed value by value; 9 quotations swept, all verbatim). Largest find: **§4's two worked examples (pp. 599–600) were never reached by the first pass**, which recorded the paper as plot-only — they print all five methods' 95% limits from a published ANOVA table, recomputed here and reproducing both printed ICCs (0.786, 0.585) to 3 dp; NBOOT's Example-2 lower limit is negative (−0.058), a published instance of the boundary case D-006 needs a fallback for. Also: **Figs 3–4 (width) omit NBOOT entirely**, so no NBOOT width claim can trace here; Figs 1/2 split balanced/unbalanced (Fig. 1 is the oracle panel), not by quantity; the SEARLE finding had dropped `k = 50`; §5's normality-only fence added — ohyama does not test the non-normal axis that is ukoumunne2003's whole claim. No package value affected.
- 2026-07-19: T3 `donner2002` verified (13 pp, all read; References end p. 379, no appendix; 21 quotations swept, all verbatim; the "nothing traces to this note" absence claim re-grepped, still zero hits). One correction: the simulated-`ρ` enumeration "0.4, 0.6, 0.8, 0.95 (Tables 1–3)" is right for Tables 1–2 but wrong for Table 3, which is a POWER table and so uses unequal pairs — (0.4,0.6), (0.4,0.7), (0.6,0.8) — so ρ=0.7 occurs there and ρ=0.95 does not. The load-bearing property (floor 0.4, no near-zero cell, highest floor of the five cluster papers) is unaffected: a form was stated where a property was meant (the M68 lesson). Also: two quotations carried markdown inside the quote marks, now outside; §3.4's "Alsawalmeh and Feld" source typo recorded; both worked examples' printed results added so the note stands alone. No package value affected.
- 2026-07-19: T4 `konishi1989` verified (13 pp, all read; references end p. 105, no appendix; 15 quotations swept, all verbatim; the absence claims — no admissible-`ρ` bound anywhere, nothing in the package citing it — both re-checked). One correction, a **false illegibility claim**: the `q = 2` scale `c` (p. 99) had been left untranscribed because the scan was "unreliable at that line", but it renders cleanly at 400 DPI and is now transcribed as `c = {√2(1−ρ)}⁻²(a²₁h₂ + a²₂h₁)(φ²₁ + φ²₂)`. The scan's actual defect is its TEXT LAYER, which returns the AMS classification as `62Hl5`/`62HIO` — the note's separate OCR claim, confirmed. Also: the running head carries authors plus truncated title, not the title alone. No package value affected.
- 2026-07-19: T5 `naik2007` verified (13 pp, all read; references end p. 6510, no appendix; 20 quotations swept, all verbatim; absence claim re-grepped, still zero hits). The load-bearing p. 6503 negative-LRT finding and its 25% figure are confirmed exactly, so INDEX.md's "must not be cited as a concordant pair" stands. Two corrections: (a) the score-vs-`T₀` verdict is stated TWICE with different outcomes — score "consistently better" at g=3 (p. 6505) but "essentially indistinguishable" with `T₀` sometimes better at g=2 (p. 6507) — and only the first was recorded; (b) the pooled `ρ̂_S` standard error was called intractable where the paper says an approximate expression exists but is "very complicated". Also recorded: a §6 source erratum (p. 6504 says `χ²` with `g` df where every test definition says `g−1`), the paper's own "limited simulation study" caveat, and its k/g notation split. Six quotations had markdown or backticks inside the quote marks — five of them mine, introduced this session — now all markup-free. No package value affected.
- 2026-07-19: T6 `young1998` verified (11 pp, all read; references end p. 1373 with the publication dates BELOW them and the French Résumé on p. 1372; 15 quotations swept, all verbatim; absence claim re-grepped, zero hits). The M67 review's restoration of `−2 log Λ` to the Eq. (2.6) quotation is confirmed correct. Additions: the paper RAN all (ρ₁,ρ₂) combinations but Table 1 PRINTS only a subset, so an absent cell means unprinted not unsimulated; Figs. 1–4 label the `Z*` test `STAR05` where Table 1 calls it `NORM*05`; the recommendation recurs at least four times, not three. **Scope flag:** two claims in this note assert `bhandary2006` content (its 0.8804/0.9567/0.8508 estimates and the 0.4089 size inflation at K=5) — that note is unverified and belongs to M71, so both are now marked as inherited rather than verified here; the young1998 halves (negative estimates −0.2917/−0.2504/−0.2682, two samples of seven, k=30 only) are confirmed against this source. Two quotations had backticks inside the quote marks, now outside. No package value affected.
- 2026-07-19: T7–T9 done. T7 consolidated quotation sweep: 93 quotations across the six notes (ukoumunne2003 13, ohyama2025 9, donner2002 21, konishi1989 15, naik2007 20, young1998 15), all verbatim and markup-free — the sweep caught one residual markup-in-quote in ukoumunne2003 from T1, since T1 predated the markup check. T8 time-relative sweep: 0 hits across all six. T9: INDEX.md updated — the M67 four moved from backlog to dated-verified with per-note findings, the backlog narrative now names the seven M65 notes (M71) and points ORACLES/BIBLIOGRAPHY at M72, the ohyama2025 entry notes the recovered §4 examples and NBOOT width exclusion, and a mechanically-counted 23-verified/7-unverified shelf census added. `cairn_validate` green; `devtools::test()` FAIL 0 / PASS 1802 (M69 baseline, unchanged); diff is docs-only under cairn/.

- 2026-07-19: reviewed by /milestone-review (PR #76). Three lenses: [O] diff-bug confirmed every load-bearing correction against the PDFs and raised 2 findings; [S] blame-history and [S] prior-PR both clean. Scored: Finding 1 (96) — ukoumunne2003's width-caveat quotation mis-anchored to p. 3818 twice, actually p. 3816 — FIXED (re-confirmed against the PDF text layer; the two other p. 3818 refs are the genuine Appendix A location); Finding 2a (88) — ohyama2025 Extraction said "single quotation" for a 9-quotation note — FIXED; 2b (75) and 2c (58) below the action bar, same class, fixed opportunistically by making all three count phrasings count-free. Post-fix: 93 quotations, 0 markup; cairn_validate exit 0.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-07-19 by /milestone-review. PR
https://github.com/jmgirard/intraclass/pull/76. Docs-only, all changes under
`cairn/` (6 notes + INDEX.md + ROADMAP + this file).

### Acceptance-criteria evidence (fresh)

- **AC1** (read to final page, dated status naming what was checked) — all six
  `Extraction:` lines read `verified 2026-07-19` and name a PDF page count that
  matches `pdfinfo` exactly: ukoumunne2003 17, ohyama2025 16, donner2002 13,
  konishi1989 13, naik2007 13, young1998 11. Appendices confirmed reached where
  present (ukoumunne2003 App. A pp. 3818–3820, konishi §5 refs to p. 105).
- **AC2** (per-note quotation sweep, verbatim or corrected) — mechanical sweep
  over all six: **93 quotations** (13/9/21/15/20/15), every one verbatim against
  its source and **0 carrying markdown inside the quote marks**.
- **AC3** (anchors resolve; pagination basis where not version of record) — every
  anchor re-checked during the reads. None of the six is a preprint/advance-online
  copy — all are published versions of record with journal pagination — so the
  pagination-basis clause is vacuously satisfied; each note states its
  PDF-page↔printed-page correspondence regardless.
- **AC4** (absence claims settled by high-DPI render, never text layer) —
  konishi1989's false illegibility claim was overturned with a 400-DPI crop of
  p. 99 and the expression transcribed; the four "nothing traces to this note"
  grep claims (donner2002, konishi1989, naik2007, young1998) were **re-grepped
  fresh at review — 0 package hits each**.
- **AC5** (no false time-relative assertion) — sweep for `at the time of
  writing` / `not yet` / `today` / `must be checked` / `not retrieved` /
  `has not been read` across the six: **0 hits**.
- **AC6** (no package value changes) — branch diff is docs-only under `cairn/`;
  `git diff --name-only main...HEAD` lists no file outside it. No oracle value,
  test fixture, or documented behavior touched.
- **AC7** (`cairn_validate` passes; six gone from the advisory by re-reading) —
  `cairn_validate` exit 0, all checks PASS; `references staleness` advisory
  **15 → 9** (the nine remaining are M65's seven + ORACLES.md + BIBLIOGRAPHY.md,
  M71/M72 scope). Cleared by re-reading sources, no status line reworded.

### Consistency gate

- `cairn_validate.py` — exit 0, all checks PASS (302 advisory WARNs, none a gate
  failure); `coverage complete` PASS.
- Principle impact — IP2 is in the slot but M70 works *under* IP2, it does not
  change its text; `cairn_impact --changed` not applicable.
- Toolchain (`r-package` `consistency-gate`) — diff is docs-only under `cairn/`
  (`.Rbuildignore`d); no R/man/DESCRIPTION/NEWS/README/pkgdown file changed, so
  `document()`-no-diff, pkgdown, NEWS-entry, and `R CMD check` checks are no-ops.
  `devtools::test()` at implement: FAIL 0 / PASS 1802, identical to the M69
  baseline.

### Independent review — three lenses + scorer

Three fresh-context reviewers, distinct evidence bases:

- **[O] diff-bug (Opus):** spot-checked every load-bearing correction against the
  shelf PDFs (ukoumunne2003 0.9320, ohyama2025 §4 examples 0.786/0.585/−0.058,
  naik2007 25%, konishi1989 scale `c`, donner2002 Table 3 pairs) — all confirmed
  correct. Raised two findings (below).
- **[S] blame-history (Sonnet):** no surviving findings — confirmed the M67
  `−2 log Λ` restoration is preserved byte-identical, no prior M67/M69 correction
  reverted, and D-006/D-007/the M68 anti-rewording lesson all consistent.
- **[S] prior-PR-comments (Sonnet):** no-op — the prior PRs touching these files
  (#68/#72/#75) carry zero human review comments, only Codecov bot output.

**Scored findings** (fresh [S] scorer):

- **Finding 1 (score 96, FIXED)** — *"`ukoumunne2003.md`: the width-caveat
  quotation is anchored to p. 3818 in two places (the caveat bullet and the D-006
  Notes 'Width is the paid cost' line); the sentence is actually printed on
  p. 3816."* Introduced by this diff; independently re-confirmed against the PDF
  text layer (PDF p. 12 = printed 3816 holds the sentence; p. 3818 holds only the
  minimum-length discussion and Appendix A). Both anchors corrected to p. 3816;
  the two *other* p. 3818 refs are the genuine Appendix A location and stay.
- **Finding 2a (score 88, FIXED)** — *"`ohyama2025.md`: the Extraction line says
  'the single quotation confirmed verbatim' but the note now carries 9 quoted
  strings."* Reworded to "every quoted string confirmed verbatim".
- **Finding 2b (score 75, logged; fixed opportunistically)** — `naik2007.md`'s
  "all 12 quotations" undercounts the T7 tally of 20. Below the 80 action bar,
  but the same class as 2a and touched in the same coherence pass: reworded to
  "every quoted string … confirmed verbatim".
- **Finding 2c (score 58, logged; fixed opportunistically)** — `young1998.md`'s
  "all 11 quotations" vs T7's 15; the scorer judged this plausibly a
  counting-convention artifact. Reworded to "every quoted string re-checked" for
  consistency with 2a/2b, not because it was a confirmed defect.

The three per-note count phrasings (2a/2b/2c) were all made count-free so the
Extraction lines cannot drift against the mechanical T7 sweep. Post-fix
regression check: 93 quotations across the six, still 0 with markup; the only
remaining p. 3818 references are Appendix A's true location.
