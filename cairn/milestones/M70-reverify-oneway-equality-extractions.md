<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M70: Re-verify the one-way and equality-testing extractions (6 notes)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m70-reverify-oneway-equality`   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] Each of the six notes has been read against its shelf PDF **to that
      source's final page** (appendices can follow the reference list —
      LESSONS 2026-07-18/M65), and its `Extraction:` line records a dated
      verified status naming what was checked.
- [ ] Every quoted string in **every one of the six notes** has been re-read
      against its source and confirmed verbatim or corrected. The sweep is
      mechanical and per-note — enumerating all quotations in each note, not
      only those a prior finding named (the M67 recurrence, LESSONS
      2026-07-19).
- [ ] Every page/table anchor resolves to the claimed page in the shelf PDF,
      with the pagination basis stated wherever the PDF is not the version of
      record.
- [ ] Every absence claim ("not in the paper", "prints no DOI") is settled by
      a rendered page image at high DPI, never the text layer alone, or else
      is stated as "not checked" and asserts nothing further.
- [ ] No note asserts anything time-relative that is false at merge.
- [ ] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [ ] `cairn_validate` passes and the six notes no longer appear in the
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
- [ ] T7: mechanical quotation sweep — enumerate every quoted string in all
      six notes and re-check each against its source; record the count swept
      per note as the evidence.
- [ ] T8: grep the six notes for time-relative phrasing (`at the time of
      writing`, `not yet`, `today`, `must be checked`, `not retrieved`) plus
      the `Traces to` lead sentence, and re-resolve every hit.
- [ ] T9: update `INDEX.md`'s backlog narrative and the M67 paragraph; run
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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
