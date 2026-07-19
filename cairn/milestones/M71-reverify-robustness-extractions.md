<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M71: Re-verify the robustness and interval-methods extractions (7 notes)

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m71-reverify-robustness-extractions`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Extend M69's dated-verified extraction bar to M65's seven robustness and
interval-methods notes, closing the last of the source-note backlog.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** seven `cairn/references/<citekey>.md` notes (115 PDF pages) re-read
against their shelf PDFs: `bhandary2006`, `bobak2018`, `mehta2018`,
`saha2005`, `saha2012`, `xiao2009`, `xiao2013`. Anchors, quotations and
values corrected in place; each `Extraction:` line upgraded to a dated
verified status; `INDEX.md`'s M65 paragraph updated to match. Also in: the
two `bhandary2006` claims that `young1998.md` currently marks *inherited,
not verified* (M70's hand-off) — resolved in place once `bhandary2006` is
verified.

**Out:** the six M62/M67 notes → M70. `ORACLES.md` and `BIBLIOGRAPHY.md` →
M72. The `xiao2013` profile-likelihood GO/NO-GO assessment stays a
candidate row — this milestone verifies what the note claims, it does not
act on it. Any change to R code, tests, or oracle values.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] Each of the seven notes has been read against its shelf PDF **to that
      source's final page** — `mehta2018` in particular, whose Appendices
      A–C sit at pp. 2750–2752 *after* the reference list and were once
      falsely recorded absent (LESSONS 2026-07-18/M65).
- [ ] Every quoted string in **every one of the seven notes** has been
      re-read against its source and confirmed verbatim or corrected. The
      sweep is mechanical and per-note, not driven by prior findings
      (LESSONS 2026-07-19/M67).
- [ ] Every page/table anchor resolves to the claimed page in the shelf PDF,
      with the pagination basis stated wherever the PDF is not the version of
      record.
- [ ] Every absence claim is settled by a rendered page image at high DPI,
      never the text layer alone, or else is stated as "not checked" and
      asserts nothing further.
- [ ] No note asserts anything time-relative that is false at merge.
- [ ] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [ ] `cairn_validate` passes and the seven notes no longer appear in the
      `references staleness` advisory — achieved by re-reading the sources,
      with no status line reworded to clear it (LESSONS 2026-07-18/M68).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3, T4, T5, T6, T7
- AC2 → T8
- AC3 → T1, T2, T3, T4, T5, T6, T7
- AC4 → T1, T2, T3, T4, T5, T6, T7, T8
- AC5 → T9
- AC6 → T1, T2, T3, T4, T5, T6, T7, T10
- AC7 → T10

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: `xiao2013` (25 pp) — the largest, and the one a live candidate row
      (profile-likelihood sibling) would rest on; verify the modified-PL
      claims and the documented naive-PL under-coverage especially.
- [x] T2: `saha2012` (21 pp).
- [x] T3: `mehta2018` (19 pp) — read past the reference list to the
      appendices at pp. 2750–2752; they hold the tables behind the paper's
      central safeguard claim.
- [x] T4: `saha2005` (16 pp) — reconcile against `saha2012`, its sibling.
- [x] T5: `bhandary2006` (14 pp) — INDEX.md places it in the M67
      equality-testing cluster by subject; confirm the cross-references that
      fence names actually hold. Then clear the two inherited-marker claims
      in `young1998.md` against this source.
- [x] T6: `bobak2018` (11 pp).
- [x] T7: `xiao2009` (9 pp).
- [x] T8: mechanical quotation sweep — enumerate every quoted string in all
      seven notes and re-check each against its source; record the count
      swept per note as the evidence.
- [x] T9: grep the seven notes for time-relative phrasing (`at the time of
      writing`, `not yet`, `today`, `must be checked`, `not retrieved`) plus
      the `Traces to` lead sentence, and re-resolve every hit.
- [x] T10: update `INDEX.md`'s M65 paragraph and the backlog narrative; run
      `cairn_validate` and the r-package `verify` slot; confirm docs-only.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (absorbs the M65 seven from the "remaining nine source extractions" candidate row, whose other two went to M70; plan gate: low priority — nothing in the package traces to these seven and five are outside the IP2 contract boundary).
- 2026-07-19: gated Scope amendment at the implement question gate — `young1998.md`'s two `bhandary2006` claims, marked inherited-not-verified by M70's T6 hand-off, are resolved in place under T5 (an eighth file, M70-owned). Also gated: notes re-read in the main session, not delegated; a correction falsifying the profile-likelihood candidate row's premise is fixed in the note and escalated as a review finding, never a silent ROADMAP rewrite.
- 2026-07-19: T1 `xiao2013` verified (25 pp, all read; Appendix pp. 2258–2264 and References p. 2265 confirmed as the final page with nothing after; every quoted string swept). **The load-bearing claims all hold**: all four Table 4 anchor cells and all three Table 6 cells reproduce cell-by-cell, Eqs. (37)–(40)/(44)/(64)/(65) confirmed, and the ROADMAP candidate row's two premises (two-way random with random raters; naive PL under-covers) are correct — no escalation needed. Corrections: Table 2 is `R = 3, S = 50` ONLY (the paper's worst PL geometry), not a sweep — the note read its 731–862 range as general; the under-coverage result was pinned at "stated four times" when it recurs in six places, now count-free (Introduction p. 2243 and §6 p. 2257 added); the AL quotation was altered ("is computed" for the source's "are computed"); the random-raters quotation was double-anchored to pp. 2241 and 2242 where only the Abstract prints it; Eq. (65) is on p. 2264, only its closing remark on p. 2265; Eq. (7)'s constant is `c`, not `c′`; `κ_corr` quotation silently lowercased the source's leading "A"; "pp. 2258" → p. 2258. Additions: a **source erratum** — Table 9's `κ_m` for `R = 5, S = 10` prints 0.23 where its own footnote's source (Table 3, one-sided `δ_U = 16`) gives 0.33, the only one of six cells that disagrees; a second, harmless one — Eq. (66)'s closing sentence calls `D` a determinant where it is `ln|V|`; the issue number `28(5)` is nowhere in the PDF and is now marked as publisher-record-only; Example 3's "nine (`S = 18`)" resolved as legs-not-children, not an erratum; `bartko1966.md`'s inbound cross-reference added. No package value affected.
- 2026-07-19: T2 `saha2012` verified (21 pp, all read; Appendices A/B on PDF p. 20 sit BEFORE the reference list, which ends the document on p. 21; 30 quoted strings swept). **Two substantive extraction defects, both in this note's own transcriptions.** (a) Of the three transcribed Table I `m = 73` rows, two were cross-contaminated between adjacent `φ` rows: the `π = 0.1, φ = 0.2` row took its MLE `0.676 (0.140)` and EQL `0.381 (0.122)` from the `φ = 0.3` row (true: `0.735 (0.121)`, `0.524 (0.099)`), and the `φ = 0.5` row took DEQL's length from the `φ = 0.4` row (`0.630 (0.205)` → printed `0.630 (0.232)`). All five `m = 19` rows and the third `m = 73` row were correct. (b) The transcribed log-likelihood silently ADDED an `ln` the source does not print on its third sum — settled by a 300-DPI render, not the text layer (M66); the `ln` is mathematically required by Eq. (1), so it is a source typo, but the note now transcribes as printed and says so. Also corrected: the note repeated §3's **inverted** "conservative"/"liberal" labels — §3 calls under-covering "conservative" and over-covering "liberal" while §5 uses the standard convention ("very liberal behavior" for the same under-coverers), so the note's "FZT-MLE … stays conservative" read as the opposite of what the paper measured (FZT-MLE under-covers, Table I); the Figure 1 plot-read grouped QEE with the under-coverers and omitted FZT-MLE — a 200-DPI render shows QEE sitting AT nominal with the tightest box of the four asymptotics; config (v)'s TNBD is truncated below 1 **and above 15**; the Table I caption quotation had altered comma placement. Additions: the paper says "six methods" in §3 and §5 while tabulating seven (FZT-MLE is the one dropped); its prose cites Eqs. (6) and (7), which do not exist — only (1)–(3) are numbered; Table I's `m = 73, π = 0.5` block carries visible source defects (EQL/DEQL duplicating MLE/QEE at `φ = 0.1`, FZT-MLE lengths of 0.813/0.834 among neighbours of ≈ 0.1); the caption's method order differs from the column order; and §5 names a live R implementation (`plkhci`) plus a SAS route, so unlike `xiao2013` an independent-implementation oracle is reachable. Applications Tables IV–VI re-checked value by value, including the negative lower limits, which the printed interval lengths confirm. No package value affected.
- 2026-07-19: T3 `mehta2018` verified (19 pp, all read; **the appendices were reached** — the reference list ends at ref 37 part-way down p. 2750, then the how-to-cite box, then Appendices A–C run to p. 2752, the final page, exactly as the M65 lesson demanded; 31 quoted strings swept). Every Appendix A/B row the note transcribes is correct, as are all of Tables 5, 6, 7 and 9 and 29 of 30 Table 4 cells. Corrections: Table 4's extreme-convex `N = 300` Case 2 interdecile range is 0.04, not 0.03; "the spread is consistently 2–3x wider at `N = 80`" overstated it (checked pair by pair: 1–2.5x, most often 2x); §3.2 spans pp. 2740–2743, not 2740–2741. Three **substantive qualifications**, each a case where the note stated a conclusion more broadly than the paper supports: (a) "sampling moves ICC toward uniform from both sides" holds unconditionally only for the MODE — mean and median REVERSE for concave populations at severe disagreement (extreme concave Case 5: 0.39 full → 0.56 mean, away from uniform's 0.34), which the paper states and is the actual reason the mode is recommended; (b) the mode-is-best claim was cited to one page when the paper establishes it separately for concave (p. 2745) and convex (p. 2746) and combines them only in §6 (p. 2748); (c) the safeguard claim was called "confirmed with its own numbers" on the strength of Case 1 alone — at Cases 5–6 rater error moves materially (extreme concave 1.44 → 1.13 mean; extreme convex 1.19 → 1.39 mode), so the honest form of the claim is DIRECTIONAL (rater error moves toward the uniform value, upward in the convex case, which is the direction that argues against artificial inflation) rather than "unchanged". Additions: the note's "four of five cross a koo2016 band" is right for koo2016's bands but the paper judges against Landis & Koch, under which THREE of five change classification — both counts now carry their band system; two DGP rules stated only in running text (master grades 1–3 have zero chance of a 4-point difference; a non-unique mode resolves to the maximum tied mode); and `PROC MIANALYZE` partially resolves the under-specified bootstrap-recombination step for the application. Appendix C's mid-sentence capitals confirmed as printed by a 250-DPI render, not a transcription slip. No package value affected.
- 2026-07-19: T4 `saha2005` verified (16 pp, all read; Appendix A pp. 3510–3511, references end at ref 25 on p. 3512 with nothing after; 26 quoted strings swept). **Every transcribed number reproduces exactly** — Tables I, III, IV, VI, VII re-read cell by cell, including the cross-paper SE-discrepancy table against `saha2012` (all eight values and all four percentages correct, medium dose 9.5%). The corrections are to READINGS. Biggest: **Table I's rejection counts are U-shaped in `φ`, not monotone.** The note (following the paper's own summary sentence) recorded rejection as concentrating at small `φ`, which is true of the `π = 0.1` rows it transcribed; the `π = 0.4` rows blow up at the UPPER boundary too (BB/ED `m = 50`: 4683 at `φ = 0.85`; BB/TNBD `m = 50`: 5635), so the phenomenon is boundary proximity, not smallness — a strictly stronger form of the D-006 support this note exists to provide. Second: Figure 1's bias is **positive at small `φ`** (≈ +0.10 to +0.15 at 0.05, crossing zero near 0.3–0.4), where the note said only "increasingly negative as the true ICC rises"; the near-zero region is where these estimators are biased UPWARD. DEQL's floor re-read at ≈ −0.31, not −0.35 (300-DPI render). Also corrected: "PNB does not clear up at `m = 50`" overstated it (PNB/ED falls 6609 → 2442; only PNB/TNBD fails to improve, 6600 → 6903); the PNB-vs-BB ratio is 1.7–4x, not 3–4x, and the paper's own sentence now carries the claim; the discard rules span pp. 3503–3504, not 3504. Additions: the counts survive a **100-start** multi-start strategy (p. 3504), which is what makes them evidence about the estimand rather than the optimizer; the DEQL efficiency exception has an exact published fence (`π = 0.1`, `φ < 0.3`, TNBD); the ambiguous "this estimator" in §7 is settled by the same sentence on p. 3507 naming DEQL outright, so that anchor replaces p. 3510; §5 and §7 state the BCML-vs-Q₂ result at different strengths; and §7 mis-cites "Section 5" for the Section 6 data analysis. No package value affected.
- 2026-07-19: T5 `bhandary2006` verified (14 pp, all read; references end the document on p. 778 with nothing after; 19 quoted strings swept). All 54 transcribed Table 2 values, all 30 transcribed Table 1 values, and the worked example's estimates, both statistics and all six critical values reproduce exactly. Two corrections. (a) **Table 1 has 75 rows, not 81, and prints a deliberately selected high-`ρ` subset** — `ρ₁ ∈ {0.7, 0.8, 0.9}` × `ρ₂ ∈ {0.5…0.9}` × `ρ₃ ∈ {0.1, 0.3, 0.5, 0.7, 0.9}`, which §3 calls "a sample combinations" of the 0.1–0.9 design grid. So the note's "`F_max` matches or beats the LRT in essentially every row" is a claim about rows where `ρ₁` never drops below 0.7; the abstract fences it the same way ("for higher intraclass correlation values"), and NO published row shows the power comparison at low `ρ₁` — the region this package cares about. Same class of scope error as T2's Table 2. (b) **Eq. (2.17) prints `F_{α/6; ppk,rr}`** — a stray `k`, confirmed against a 400-DPI render — which the note had silently corrected to `pp,rr`; now transcribed as printed with the correction argued from Eq. (2.16), same treatment as T2's missing `ln`. Added: the paper generates "using R program" but quotes negative-binomial parameters as a FORTRAN IMSL subroutine setting, never saying which produced the family sizes. **Gated `young1998.md` cleanup discharged**: both claims M70 flagged inherited-not-verified are now verified against this source — the three estimates 0.8804/0.9567/0.8508 plus pooled 0.85847 and the 5/5/4 split on its p. 777, and the 0.4089 size inflation as Table 2's `ρ = 0.1`, `K = 5` cell on its p. 774; the markers are removed and a caveat added that the two papers test two- vs three-population hypotheses, so it corroborates rather than replicates. No package value affected.
- 2026-07-19: T6 `bobak2018` verified (11 pp, all read; references end the document on p. 11; 25 quoted strings swept). All 13 Table 3 rows, all 3 Table 2 rows and every Table 4/5 value reproduce exactly. **Every page anchor confirmed by per-page extraction** — a whole-document `pdftotext -layout` dump interleaves BMC's two columns across page breaks and made the table anchors look off by one when they are correct; the `Page N of 11` footers make per-page checking cheap and it is the only reliable method here. Additions: the abstract carries **two** pooling penalties and the note had only the second — pooling "without accounting for the variability between studies" inflates by "approximately 0.02", separately from the 0.066–0.072 figure; a **source erratum** in the Results text, which attributes 0.072/0.066 to "(Table 3) or ignored (Table 4)" when the arithmetic is Table 4 (0.681−0.609) and Table 5 (0.706−0.640) and Table 3 has no pooled `ICCb*` row at all; Table 2's last column is printed `p-value` though its caption defines it as a posterior probability (the body reads it correctly, 1−0.056 = 0.944); and the `ω` vs `ω²` open question extends to **`τ`**, tabulated as `τ²` in Table 3 but bare `τ` in Tables 4–5. Also fixed one inherited markup-inside-quotation (`**consistency**`). **Cross-note markup sweep** run over all eight touched notes: two more inherited instances found and fixed in `mehta2018.md` (abstract quote) and `saha2012.md` (the §3 boundary block) — both now carry the emphasis in the framing prose, per the M70 lesson. No package value affected.
- 2026-07-19: T7 `xiao2009` verified (9 PDF pages, all read; 24 quoted strings swept). **The cleanest note of the seven** — all 72 Table 1 values, all 8 Table 2 values, the simulation design (zero-truncated NB, `m = 2.84`, `P = 0.93`, plus one, truncated at 15; 5,000 samples; 5,000 pivots) and the worked example's four group sizes (62/36/75/45, summing to 218) reproduce exactly, and every page anchor resolves. Three defects, all cosmetic-to-provenance rather than numeric: **the shelf PDF has 9 pages because its first is a Taylor & Francis cover sheet**, so `PDF page N` = `journal page 109 + N` — an unrecorded conversion of exactly the kind that produces mis-anchors, now in Provenance; two markup-inside-quotation instances (`**2010**` in the copyright-line quote, `**95 %**` in the Table 1 caption, the latter also spacing a percent sign the source prints unspaced); and a **spurious ellipsis** in the p. 117 quote, inserted where the source runs continuously. Added: the low-`ρ` superiority claim is now backed by the table rather than only the prose — GP's worst cell is 0.913 (`K = 3`, 25 families, `ρ = 0.1`) and its four lowest cells are all at `ρ ∈ {0.1, 0.2}`, against PL's floor of 0.931 — plus the Summary's tempering line that GP's high-`ρ` wins do not make PL "perform less well". No package value affected.
- 2026-07-19: T8 consolidated quotation sweep — **193 quoted strings across the eight touched notes** (xiao2013 35, saha2012 30, mehta2018 29, bobak2018 26, saha2005 25, bhandary2006 19, young1998 15, xiao2009 14), every one re-read against its source during T1–T7 and re-checked mechanically here; all quote marks balanced, **0 markup-inside-quotation remaining**. The end-of-milestone re-run earned its keep exactly as the M70 corollary predicts: it found three inherited markup-in-quote instances that per-task checks had passed over (`bobak2018`'s `**consistency**`, `mehta2018`'s abstract clause, `saha2012`'s §3 boundary block), two more in `xiao2009` (`**2010**`, `**95 %**`), and a spurious ellipsis in `xiao2009`'s p. 117 quote. **Correction to my own T7 work-log line, which is history and so superseded rather than edited: it claims "24 quoted strings swept" for `xiao2009`; the mechanical count is 14.** I asserted that number instead of counting it — the precise failure the M70 lesson names, committed in the act of recording compliance with it. The counts above are machine-produced.
- 2026-07-19: T9 time-relative sweep across the seven notes plus the `Traces to` lead sentences. Seven of eight leads rewritten to dated observations carrying the grep that settles them; `young1998.md`'s lead is left as M70 wrote it — undated, but M70-owned and outside this milestone's gated amendment, so **noticed and deliberately not touched** rather than missed. Substantive find: three claims across `bobak2018` (×2) and `mehta2018` (×1) asserted membership of a **"GP6 list" of known-failure axes that does not exist** — GP6 is a practice ("sweep whatever axis the known failure mode grows") naming cluster count, incidence and raggedness only as examples, and neither `DESIGN.md` nor `PRINCIPLES.md` carries an enumerated axis registry. A standing claim about the repo's own state, read as durable and false; all three rewritten to say what is checkable, and both notes given a clarifier under the inherited "GP6 known-failure axes" heading. Also dated `bhandary2006`'s bidirectional cross-reference claim, re-verified by count (cited by donner2002 x2, konishi1989 x1, naik2007 x3, young1998 x5).
- 2026-07-19: T10 done. `INDEX.md` updated — the shelf census now reads **all 30 notes dated-verified** and the source-note re-verify backlog is recorded as CLOSED (M72 keeps `ORACLES.md` + `BIBLIOGRAPHY.md`); an M71 findings block added, per note, plus the cross-cutting observation that three notes had silently repaired their source and now transcribe as printed. Gates: `cairn_validate` **15/15 PASS**, all remaining advisories judgment calls (293 dangling pre-migration id tokens, expected) — and the **`references staleness` advisory fell 9 → 2**, the two survivors being exactly `ORACLES.md` and `BIBLIOGRAPHY.md`, i.e. the seven notes cleared by re-reading their sources, not by rewording a status line (AC7, LESSONS 2026-07-18/M68). `devtools::test()` under `NOT_CRAN=true CI=true`: **FAIL 0 | WARN 2 | SKIP 23 | PASS 1802**, the unchanged M69/M70 baseline. Diff confirmed **docs-only**: 11 files, all under `cairn/`, no R code, test, fixture or oracle value touched. Milestone status -> review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
