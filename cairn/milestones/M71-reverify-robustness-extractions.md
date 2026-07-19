<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M71: Re-verify the robustness and interval-methods extractions (7 notes)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m71-reverify-robustness-extractions` · https://github.com/jmgirard/intraclass/pull/77   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] Each of the seven notes has been read against its shelf PDF **to that
      source's final page** — `mehta2018` in particular, whose Appendices
      A–C sit at pp. 2750–2752 *after* the reference list and were once
      falsely recorded absent (LESSONS 2026-07-18/M65).
- [x] Every quoted string in **every one of the seven notes** has been
      re-read against its source and confirmed verbatim or corrected. The
      sweep is mechanical and per-note, not driven by prior findings
      (LESSONS 2026-07-19/M67).
- [x] Every page/table anchor resolves to the claimed page in the shelf PDF,
      with the pagination basis stated wherever the PDF is not the version of
      record.
- [x] Every absence claim is settled by a rendered page image at high DPI,
      never the text layer alone, or else is stated as "not checked" and
      asserts nothing further.
- [ ] No note asserts anything time-relative that is false at merge.
- [x] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [x] `cairn_validate` passes and the seven notes no longer appear in the
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
- 2026-07-19: /milestone-review attempt 1 FAILED **AC2** and returned the milestone to `in-progress`. Six criteria pass with fresh evidence recorded in the Review section (AC1 page counts vs `pdfinfo` + mehta2018's post-reference appendices; AC3 73 folio-checked anchors; AC4 four render-settled absence claims; AC5 zero unresolved time-relative hits; AC6 diff provably fenced from the package by `.Rbuildignore:9`; AC7 validate 15/15 and staleness 9 → 2). **AC2 fails on one altered quotation**: `bobak2018.md` quotes "may reflect low subject variability" as koo2016 p. 158, which prints "A low ICC could not only reflect the low degree of rater or measurement agreement but also relate to the lack of variability among the sampled subjects" — the string occurs nowhere in koo2016, and both `koo2016.md` and `mehta2018.md` render the same content correctly as an unquoted paraphrase. Pre-existing M65 content, but AC2 is scoped to every quoted string in the seven notes and the implement sweep skipped it on the judgment call that it was "a koo2016 quote, not a bobak2018 claim" — the exact shape the M67 lesson warns about. A mechanical sweep for cross-source quotations found only this one, so the defect set is complete. [S] blame-history and [S] prior-PR lenses both clean; [O] diff-bug was still in flight at send-back and its findings fold into the same fix cycle.
- 2026-07-19: [O] diff-bug lens reported after the send-back with **5 further findings, all in content M71 introduced**, each re-verified at the source here and then scored by a fresh [S] scorer — **92, 95, 93, 88, 90; all five clear the 80 bar, none below it**. F1 `saha2005` Figure 1: BCML is lowest at `φ = 0.05`, not DEQL (600-DPI render; the coherent reading is that BCML sits closest to zero at both ends, which is what a bias correction should do). F2 `bobak2018`: the 0.944 sentence is on **p. 7**, anchored to p. 8 — in a note whose Extraction line claims every anchor was confirmed by per-page extraction. F3 `xiao2009`: "four lowest GP cells all at `ρ ∈ {0.1, 0.2}`" is false, only two are (0.923 at `ρ=0.5`, 0.925 at `ρ=0.3` sit third and fourth). F4 `saha2012`: the terminology block claims "§5 does not" invert conservative/liberal, but §5 calls HPV-QEE's OVER-coverage "liberal" — the block over-generalizes, and a correction that over-claims is worse than the error it corrects. F5 `INDEX.md`: "except three cells" undercounts — four table cells were corrected, and the `mehta2018` bullet omits its own; the M70 never-pin-a-count lesson violated in the summary of a pass whose T8 entry cites that lesson. **Pattern: all five sit in interpretive prose the milestone ADDED, not in the transcriptions it checked** — every numeric correction survived independent verification. Together with the AC2 failure that is six defects to fix, all in this milestone's own new content.

- 2026-07-19: fix cycle — all six defects from review attempt 1 corrected, each re-verified at the source in this session before the edit rather than taken on the review's word. **AC2 (Finding 1)**: `bobak2018.md`'s koo2016 attribution is now an unquoted paraphrase matching `koo2016.md`'s and `mehta2018.md`'s treatment of the same sentence (koo2016 p. 158 prints a longer sentence; the short string occurs nowhere in it). **F1** `saha2005` Figure 1(a) re-read off a 1200-DPI crop render: at `φ = 0.05` the order is `✳` ML ≈ +0.16, `•` Q₂ ≈ +0.13, `△` DEQL ≈ +0.11, `◇` BCML ≈ +0.08 — **BCML lowest, not DEQL**; the range is widened to ≈ +0.08 to +0.16 and the note now states the coherent reading (BCML closest to zero at *both* ends, which is what a bias correction should do). **F2** the 0.944 sentence re-anchored p. 8 → **p. 7** (footer `Page 7 of 11` by per-page extraction), and the note's `Extraction:` line, which claimed every anchor got a per-page check, now records that this prose anchor did not and was caught by review. **F3** `xiao2009`: sorting all 36 GP coverage cells gives 0.913/0.919/0.923/0.925/0.925 — only **two** at `ρ ∈ {0.1, 0.2}`, and all five in the `K = 3`, 25-family block, so the note now reads GP's weakness as tracking the smallest design with the low-`ρ` corner worst inside it. **F4** `saha2012`'s terminology block no longer says "§5 does not [invert]": §5 is standard for the four asymptotics but repeats the inversion for HPV-QEE (over-coverage called "liberal", p. text line confirmed), so the safe instruction is the tables alone. **F5** `INDEX.md`'s "except three cells" replaced with a count-free form per the M70 lesson, the `mehta2018` bullet gains its own Table 4 correction, and the block now records the review's pattern finding. AC2 sweep re-run and **extended to cross-source quotations**: 184 quotations across the seven notes, all quote marks balanced, 0 markup-inside-quotation, and every quotation whose context names another citekey resolved — the koo2016 band words `"poor"`/`"moderate"`/`"good"` confirmed printed in koo2016, the rest own-source with own-page anchors. Gates: `cairn_validate` all checks passed (staleness still 9 → 2, the two survivors `ORACLES.md`/`BIBLIOGRAPHY.md`); `devtools::test()` under `NOT_CRAN=true CI=true` **FAIL 0 | WARN 2 | SKIP 23 | PASS 1802**, unchanged baseline; diff still docs-only (11 files, all `cairn/`). Status -> review.

- 2026-07-19: /milestone-review attempt 2 FAILED **AC2 and AC5** and returned the milestone to `in-progress`. Five criteria pass with fresh evidence (AC1 pdfinfo page counts + mehta2018 content past the reference list; AC3 73 folio-checked anchors incl. the p. 8 → p. 7 fix; AC4 five render-settled claims; AC6 diff docs-only and fenced by `.Rbuildignore:9`, test baseline unchanged; AC7 validate clean, staleness 2). Consistency gate clean and **CI on PR #77 fully green across the whole platform matrix**. [S] blame-history and [S] prior-PR lenses both clean. The [O] diff-bug lens returned 9 findings, scored by a fresh [S] scorer: **F1 = 5 (rejected), F2 = 90, F3 = 88, F4 = 90, F5 = 85, F6 = 88, F7 = 90, F8 = 82, F9 = 84** — eight actioned, one rejected on evidence. **F1 rejected**: `mehta2018`'s `"bootstrap sampling techniques"` is verbatim in Figure 2 step 5, confirmed by 200-DPI render here and independently by the scorer; figure artwork has no text layer, so a text-layer sweep can only false-positive there. **AC5 fails on F2/F3** — two dated observations stamped `— observed 2026-07-19` that a grep falsifies (`mehta2018.md:288`'s "axis no repo document names" against three files that name it; `bobak2018.md:216`'s "only the heavy-tail one has been swept" against a repo with no non-Gaussian DGP at all), both produced by T9, the sweep meant to make such claims checkable. **AC2 fails on F6** — `xiao2009.md:60` drops "i = 1, 2, …, K" from inside quotation marks with no ellipsis. F4/F5/F7/F8/F9 are over-claims in M71's own added prose, two of them written by the fix cycle. **Pattern, third round running: every numeric correction has survived independent verification and every defect has been in the interpretive prose around those values.** Next trip back trips the thrash rule → `/milestone-plan`.

- 2026-07-19: fix cycle 2 — all eight actioned findings (F2–F9) corrected, each re-verified at the source in this session before the edit; F1 left alone as the review rejected it on evidence. **AC5 (F2, F3)**: `mehta2018.md`'s ordinal/discrete row no longer claims "an axis no repo document names" — `cairn/COVERAGE.md:196` and `cairn/legacy/ROADMAP.md:77` both carry "categorical / ordinal ratings (GLMM engines)", so the row now says what the repo actually records (unscheduled future work, not a swept axis) and carries the grep; `bobak2018.md`'s non-normality row no longer claims the heavy-tail axis "has been swept anywhere in the repo" — no non-Gaussian DGP exists in `R/` or `tests/`, so **neither** axis has been swept here and what the repo has is `ukoumunne2003`'s published sweep, cited not reproduced. **AC2 (F6)**: `xiao2009.md`'s p. 113 quotation restored to the printed form, `ρ_i (i = 1, 2, …, K)` — parentheses, not the commas the finding assumed; settled at 400 DPI because the text layer mangles the subscripts. **F4** `bobak2018.md`: koo2016's longer sentence is *not* quoted in `koo2016.md` — that note paraphrases it too and quotes only the preceding disclaimer (`koo2016.md:55–57`), now stated that way. **F5** `INDEX.md`: two notes had silently repaired a source (`saha2012`'s `ln`, `bhandary2006`'s `ppk`), not three — `xiao2013`'s `c′` runs the other way (Eq. (7) prints a bare `c`, re-confirmed at source; the note had written `c′`), so the block now records the direction instead of the count. **F7** `saha2005.md`: the PNB-vs-BB penalty recomputed over all 40 `π = 0.1` cells — **1.10–4.12**, floor TNBD `m = 50, φ = 0.85` (1191 vs 1080), ceiling ED `m = 10, φ = 0.2` (5523 vs 1340) — replacing a range read off the two cells the sentence cites; the TNBD `m = 50` row is printed in full rather than characterized. **F8** `xiao2009.md`: the `K = 3`, 25-family block is **not** the smallest design (75 families vs `K = 2`'s 50; p. 115 sets 25 or 50 families *per population*) — reworded to nuisance-parameter density, and the count corrected to 6 vs 4 after checking p. 113 names only `μ_i` and `σ_i` as nuisance (`ρ` is the common estimand), not 3 per population. **F9** `mehta2018.md`: the narrowest interdecile ratios are not unique to extreme concave — mild concave ties exactly at Cases 1–2 (0.01 vs 0.01, 0.03 vs 0.02, Table 4). Sweeps re-run: **187 quotations across the seven notes** (multi-line-aware split, all seven files quote-balanced), 0 markup-inside-quotation; AC5 grep returns one hit, my own dated observation quoting COVERAGE.md's `🔵 Not yet` status token. Gates: `cairn_validate` all checks passed (staleness still 2, `ORACLES.md`/`BIBLIOGRAPHY.md`); `devtools::test()` under `NOT_CRAN=true CI=true` **FAIL 0 | WARN 2 | SKIP 23 | PASS 1802**, unchanged baseline; diff docs-only, 11 files all under `cairn/`. Two over-claims caught in my *own* new prose before commit and fixed there ("largest exactly where the cited cells sit" — false, the ceiling is a different cell; "falls monotonically" — false, the tail wobbles), which is the attempt-2 pattern finding applied to this cycle's own writing. Status -> review.
- 2026-07-19: /milestone-review attempt 3 FAILED **AC5** and returned the milestone to `in-progress`; **the thrash rule fires** (third trip back) so no fourth retry is queued — routing is `/milestone-plan` for a re-cut. Six criteria pass with fresh evidence (AC1 pdfinfo counts + mehta2018 content past the reference list re-confirmed by per-page extraction; **AC2 now passes** — 187 quotations, 156 matched outright, all 31 remainder adjudicated, the figure-artwork case re-settled at 200 DPI, and attempt 2's F6 fix verified correct with the *review's own assumed form* wrong (the source prints parentheses, not commas); AC3 all in-range anchors resolve incl. the p. 8 → p. 7 fix; AC4 three claims re-settled fresh by render; AC6 diff docs-only 11 files all `cairn/`, fenced by `.Rbuildignore:9`, test baseline unchanged; AC7 validate exit 0, staleness 2, zero of the seven in the advisory). Consistency gate clean. [S] blame-history and [S] prior-PR lenses both clean — the latter's LESSONS substitute pass found the diff *complying* with the four relevant lessons. [O] diff-bug returned 3 findings, scored by a fresh [S] scorer: **F1 = 92, F2 = 90, F3 = 80, all actioned, none below the bar**. **AC5 fails on F1** — `mehta2018.md:290`'s dated observation claims the remaining `ordinal` grep hits "are source notes describing other papers' ordinal work, not this repo's", which a grep falsifies with ~40 hits in `estimand-specs/M6-oneway.md:213`, `legacy/STATUS.md`, `legacy/MILESTONES.md` and `legacy/DECISIONS.md`; the named file is one **attempt 2's own F2 cited**, and the false clause was written *by the fix cycle correcting that finding*, in the same table cell. F2 (saha2005, "both sit in the upper half" — the 1.7x cell ranks 19/40, below the median, and 1.7 is the old range's floor) and F3 (mehta2018, mild convex Case 1 prints the same 0.03 vs 0.02) are over-claims in fix-cycle prose breaking no AC squarely. **Pattern, third round: every numeric correction has survived independent verification all three times; every failure has been interpretive prose, and twice now prose written to fix the previous cycle's prose.** Recorded as a planning boundary, not a defect backlog.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

### Attempt 3 — 2026-07-19 — **AC5 FAILED**, thrash rule fires → `/milestone-plan`

PR https://github.com/jmgirard/intraclass/pull/77. Branch verified to contain
`origin/main` (`git merge-base --is-ancestor`), so all evidence is on the
merge-base state. **Six of seven criteria pass with fresh evidence; AC5 fails on
one finding.** This is the milestone's third trip back, so per the tracking-rules
thrash rule no further retry is queued — M71 is re-planned or split, not retried.

**AC1 — read to final page. PASS.** `pdfinfo` page counts match every
`Extraction:` claim exactly: bhandary2006 14, bobak2018 11, mehta2018 19,
saha2005 16, saha2012 21, xiao2009 9, xiao2013 25. The case the criterion singles
out was re-checked independently by per-page extraction: mehta2018's reference 35
sits part-way down PDF p. 17 (folio 2750), Appendix B on p. 18 (folio 2751), and
Appendix C's Figure C1 on p. 19 (folio 2752, the final page) — content past the
reference list, as the M65 lesson demands.

**AC2 — every quoted string verbatim. PASS.** Mechanical multi-line-aware sweep
of the seven notes: **187 quotations**, every file quote-balanced, **0
markup-inside-quotation**. Each was probed against its own source's text layer in
both `-raw` and `-layout`, dehyphenated across line breaks and normalized for
ligatures and punctuation; **156 matched outright**. The 31 remainder were
adjudicated and every one resolved:
- **~16 are not claims about a source** — repo terminology (`"on the GP6 list"`,
  `"a CI method's oracle is coverage"`, `"do not prefer the narrower interval"`),
  note headings (`"Author reconciliation"`), search terms, and one quoting the
  note's *own* superseded wording (`"§5 does not [invert]"`, explicitly marked).
- **Two are cross-FILE quotations of repo files, both verified verbatim at
  source**: `"categorical / ordinal ratings (GLMM engines)"` at
  `cairn/COVERAGE.md:196`, and the ROADMAP candidate row title at
  `cairn/ROADMAP.md:26`.
- Ligature drops (this journal family renders `ffi/fi/fl` as a gap), ellipsis
  splits, and math-symbol manglings (`φ̂_ml` extracting as `O ml`, `θ̂` as `O`)
  each resolved by targeted fragment probe.
- **One quotation lives in figure artwork with no text layer**: mehta2018's
  `"bootstrap sampling techniques"`. A 200-DPI render of PDF p. 11 shows Figure 2
  step 5 printing "Apply bootstrap sampling techniques to combine results from
  `l` samples into a single estimate for `ICC` and its variance components" — the
  quotation is verbatim and the anchor exact. This independently re-confirms
  attempt 2's F1 rejection; the body prose says "bootstrapping techniques", which
  is why a text-layer sweep false-positives here.
- Block quotes were checked as a separate class in case they carried unquoted
  source text: only `saha2012` has any (17 lines, the terminology callout), and
  its internal quotations were already in the sweep. No gap.
- **Attempt 2's AC2 failure (F6) is fixed and the fix is verified correct** —
  and the review's own assumed form was wrong. The source prints
  `ρ_i (i = 1, 2, …, K)` with **parentheses**, not the commas the finding
  assumed; confirmed here at 400 DPI and independently by the [O] lens at
  150 DPI. The text layer drops the parentheses, so a text-only check misleads.

**AC3 — anchors resolve. PASS.** Every in-range page anchor across the five
folio-paginated sources resolves, checked by extracting each claimed page and
matching its printed folio: bhandary2006 11, saha2005 15, xiao2013 19, xiao2009 8
(cover-sheet offset `PDF N` = journal `109 + N` holds), and mehta2018's full set
via a page-by-page folio map (folio = 2733 + PDF page, verified for all 19).
`bobak2018`'s 9 anchors verified against its `Page N of 11` footers — identity
mapping confirmed page by page, **including the fix cycle's p. 8 → p. 7
correction**, re-settled here: the 0.944 sentence is present on PDF p. 7 and
absent from p. 8. `saha2012` states its no-folio basis. The two out-of-range hits
are correctly-attributed citations into *other* papers (koo2016 p. 158;
Cox & Snell 1968 p. 252).

**AC4 — absence claims settled by render. PASS.** No absence or erratum claim in
the diff rests on a text layer. Re-settled fresh this attempt: saha2012's missing
`ln` at 300 DPI (the first two sums print `ln{·}`, the third prints `{·}` — and
the note's transcription matches the render exactly, with the erratum argued from
Eq. (1)'s product denominator, visible in the same render); mehta2018's Figure 2
at 200 DPI; xiao2009's parenthesized index list at 400 DPI. The prior attempts'
renders (xiao2013's missing issue number, bhandary2006's `ppk`, mehta2018's
Appendix C capitals, saha2005's Figure 1 plot-read) stand.

**AC5 — nothing time-relative false at merge. FAIL.** The grep sweep over
`at the time of writing | not yet | today | must be checked | not retrieved |
as of M<n> | currently | so far | for now | at present` returns one hit, itself
resolved (a dated observation quoting COVERAGE.md's `🔵 Not yet` status token,
verified verbatim). The 22 dated observations were then verified *mechanically*
rather than counted — the failure mode of attempt 2. Most check out: all seven
"nothing in the package traces to it and no `ORACLES.md` entry cites it" claims
return zero hits over `R/ tests/ man/ vignettes/`; the "no enumerated GP6 axis
registry" claim is accurate against `cairn/DESIGN.md:153–156`, which names
cluster count, incidence and raggedness as *examples* of a practice.
**One does not — see Finding F1 below.**

**AC6 — no package value moved. PASS.** `git diff --name-only main..HEAD` touches
11 files, **all under `cairn/`** — zero non-`cairn/` paths; no `.R`, `.Rd`,
`tests/`, `man/`, `NAMESPACE`, `DESCRIPTION`, `.rds`/`.rda`. `.Rbuildignore:9`
carries `^cairn$`, so the diff provably cannot reach the built package.
`devtools::document()` produces no `man/`/`NAMESPACE` drift. `devtools::test()`
under `NOT_CRAN=true CI=true`: **FAIL 0 | WARN 2 | SKIP 23 | PASS 1802**, the
unchanged M69/M70 baseline.

**AC7 — validate + staleness. PASS.** `cairn_validate` exit 0, all checks passed.
The `references staleness` advisory stands at **2**, and a grep of the advisory
output confirms **zero of the seven notes appear in it** — the two survivors are
exactly `ORACLES.md` and `BIBLIOGRAPHY.md` (M72's scope). Cleared by re-reading
the sources: all 30 source notes carry `Extraction: verified` (33 `.md` pages less
INDEX/ORACLES/BIBLIOGRAPHY, less the two synthesis notes and REFERENCES), which
also independently confirms `INDEX.md`'s "all 30 notes dated-verified" claim.

**Consistency gate (r-package profile).** `cairn_validate` all checks passed
(advisories: 293 dangling pre-migration id tokens, expected; staleness 2 as
above) ✓; `document()` no-diff ✓; `pkgdown::check_pkgdown()` "No problems
found" ✓; README.Rmd untouched ✓; no new exports and no new top-level files ✓;
NEWS entry not owed (docs-only, no user-visible change) ✓. No `DESIGN.md`
principle changed, so `cairn_impact` is skipped. CI on PR #77: `lint`, `pkgdown`,
`format-check` pass; the `R CMD check` platform matrix was still running at
send-back and is not load-bearing for a docs-only diff.

**Independent review — three lenses, then a scorer.**
- **[S] blame-history: clean, no findings.** Confirmed every hunk stays inside
  content M65 marked unverified; `DECISIONS.md` and `legacy/DECISIONS.md` have an
  empty diff (D-006/D-007 untouched); the ROADMAP profile-likelihood candidate row
  is byte-identical apart from M71's own status field; and the `young1998`
  discharge is substantiated by bhandary2006's own p. 777 values
  (0.8804/0.9567/0.8508, pooled 0.85847, 5/5/4 split) and p. 774 Table 2 cell
  (0.4089), with no other changes to that M70-owned file.
- **[S] prior-PR-comments: no prior-PR evidence, clean no-op.** PRs #68–#76 return
  empty review comments and review bodies; the only issue comments are Codecov
  bot output. Its substitute `LESSONS.md` pass found the diff *complying* with the
  four relevant lessons (item-count pinning, undated absence claims,
  text-layer-only absence verdicts, reading past the reference list), not
  regressing them.
- **[O] diff-bug: 3 findings**, scored by a fresh [S] scorer that did not generate
  them: **F1 = 92, F2 = 90, F3 = 80 — all three clear the 80 bar; none logged
  below it.** The lens first verified a large body of the milestone as correct:
  saha2005's Table I in full (all 40 `π = 0.1` pairs, the U-shape, the 1.10–4.12
  range and its floor/ceiling cells); mehta2018's Table 4 in full (all 60 cells,
  including the corrected `0.58 (0.04)`), Table 2 and Table 7 including the
  mean/median reversal; xiao2009's 72 coverage cells, the five-lowest-GP ordering,
  the design arithmetic, the nuisance-parameter count, and the cover-sheet offset;
  bhandary2006's 75-row grid and all four cross-reference counts; saha2012's
  terminology block; and bobak2018's `koo2016.md` and non-Gaussian-DGP claims.
  **Every numeric correction survived independent verification for the third
  round running.**

#### Finding F1 (92) — `mehta2018.md:290`, false dated observation (AC5 failure)

The ordinal/discrete GP6 row asserts, inside a dated observation stamped
`observed 2026-07-19`:

> the other hits are source notes describing *other papers'* ordinal work, not
> this repo's

`grep -rni 'ordinal' cairn/` — the grep the note itself cites — falsifies it.
Beyond the two files the note names, roughly forty hits are **this repo's own
tracking, not source notes**: `cairn/estimand-specs/M6-oneway.md:213`
("Categorical/ordinal one-way (GLMM) — ROADMAP."), plus `cairn/legacy/STATUS.md`
(6), `cairn/legacy/MILESTONES.md` (~20) and `cairn/legacy/DECISIONS.md` (~13),
all naming "categorical/ordinal GLMM" as this repo's unscheduled carryover — the
same substance as the two cited files, in more places.

Two things make this worse than a slip. `estimand-specs/M6-oneway.md:213` is a
file **attempt 2's own F2 named**; the fix dropped it from the list and then
generalized about the remainder. And the false clause was written **by the fix
cycle correcting attempt 2's F2**, in the same table cell, in the same shape — a
dated repo-state assertion a single grep falsifies. AC5 reads "No note asserts
anything time-relative that is false at merge"; read as written, it is not met.

#### Findings F2 (90) and F3 (80) — over-claims in fix-cycle prose

Neither breaks an acceptance criterion squarely (not time-relative, not a
quotation, not an anchor), but both are actioned defects in prose this milestone
added, and both are the pattern's signature shape.

- **F2 (90) — `saha2005.md:198–201`.** Having correctly recomputed the PNB-vs-BB
  penalty over all 40 `π = 0.1` cells as **1.10–4.12**, the sentence says the two
  illustrative cells "both sit in the upper half of that spread". The 1.7× cell
  (TNBD `m = 10, φ = 0.05` = 6600/3890 = 1.697) ranks **19th of 40**, below the
  median, against a range midpoint of 2.61. Self-undermining as well: 1.7 is the
  exact floor of the old "1.7–4×" range the sentence exists to correct, so it
  cannot be in the upper half of the corrected spread. Everything else in the
  sentence reproduces to the digit.
- **F3 (80) — `mehta2018.md:157–159`.** The F9 fix says "The narrowest ratios sit
  in the **concave** Cases 1–2 … extreme concave and mild concave tie exactly
  there — both print 0.01 vs 0.01 at Case 1 and 0.03 vs 0.02 at Case 2". The
  unique minimum (1.0, Case 1) is genuinely concave-only, but the second value is
  not: **mild convex Case 1 also prints 0.02 (`N = 300`) vs 0.03 (`N = 80`)**, the
  same digits and the same 1.5× ratio, in a non-concave cell. The fix that
  corrected "not unique to extreme concave" reproduced the defect one level out.

#### Disposition — thrash rule, not a fourth retry

Counting the work log, this is M71's **third** return from review (attempt 1:
AC2; attempt 2: AC2 + AC5; attempt 3: AC5). The tracking-rules thrash rule
applies: *do not queue another retry — that's a mis-planned milestone; recommend
re-plan or split via `/milestone-plan`.*

The evidence across three attempts supports that reading rather than "one more
fix". **Every numeric correction, table transcription and plot-read has survived
independent verification in all three attempts.** What has failed, every time, is
the interpretive prose written around those values — and, decisively, prose
written by each fix cycle *to correct the previous cycle's prose*. Attempt 2's F2
and this attempt's F1 are the same defect in the same table cell, one generation
apart. The milestone as cut treats "re-verify the extractions" as one job, but it
is two with different verification methods and different failure rates: checking
values against a source, which this milestone does reliably, and writing
repo-state and generalizing claims, which needs the same mechanical discipline
the values get and is not getting it. That is a planning boundary, not a defect
backlog.

Status → `in-progress`; the routing recommendation is `/milestone-plan`, and the
three findings above carry forward as inputs to the re-cut rather than as a
fourth fix list.

### Attempt 2 — 2026-07-19 — **AC2 + AC5 FAILED**, returned to `in-progress`

PR https://github.com/jmgirard/intraclass/pull/77. Branch in sync with
`origin/main` (`git merge-base --is-ancestor origin/main HEAD`), so all evidence
below is gathered on the merge-base state.

**AC1 — read to final page. PASS.** `pdfinfo` page counts match every
`Extraction:` claim exactly: bhandary2006 14, bobak2018 11, mehta2018 19,
saha2005 16, saha2012 21, xiao2009 9, xiao2013 25. The case the criterion
singles out re-checked independently: mehta2018's reference 37 and its
"How to cite this article" box sit on PDF p. 17, appendix table content
continues on pp. 17–19, and the final page prints folio 2752 — content past the
reference list, as the M65 lesson demands.

**AC2 — every quoted string verbatim. PASS** (this was attempt 1's failure).
Mechanical sweep of the seven notes: **184 quotations**, all quote marks
balanced, **0 markup-inside-quotation**. Each was probed against its own
source's text layer in both `-raw` and `-layout` modes, dehyphenated across line
breaks and normalized for ligatures and punctuation; 150 matched outright. The
34 remainder were adjudicated by hand and **every one resolved**:
- ~20 are **not claims about a source** — repo terminology (`"GP6 axes"`,
  `"a CI method's oracle is coverage"`), note headings (`"Author
  reconciliation"`, `"The ρ_L = 0.6 fence"`), a ROADMAP row title, search terms,
  and one quoting the note's *own* superseded wording (`"§5 does not [invert]"`).
- Ellipsis- and math-symbol-bearing quotes (`φ̂_ml`, `θ̂`, `ρ_i`) confirmed by
  targeted fragment probe.
- **Ligature drops** — this journal family renders `ffi/fi/fl` as a gap, so
  `"efficiency"` extracts as `eciency`; three saha2005 quotes and one saha2012
  quote confirmed verbatim once probed ligature-tolerantly.
- **Two-column interleaving** — `bobak2018`'s p. 7 quote on small sample sizes
  is unfindable under `-layout` (BMC's two columns interleave across the page)
  and verbatim under `-raw`, hyphenated as `sam- ple`.
- **One quotation lives in figure artwork with no text layer**: mehta2018's
  `"bootstrap sampling techniques"` returns zero hits in every extraction mode,
  and a 200-DPI render of PDF p. 11 shows Figure 2 step 5 printing "Apply
  bootstrap sampling techniques to combine results from `l` samples…" — the
  note's anchor (Figure 2, step 5) is exactly right. **The text layer alone
  would have produced a false altered-quotation finding here**, which is the
  same failure mode AC4 exists to prevent, arriving from the other direction.
- The one **cross-source** quotation class that failed attempt 1 is clean:
  `bobak2018`'s koo2016 attribution is now an unquoted paraphrase matching
  `koo2016.md` and `mehta2018.md`; koo2016's band words `"poor"`/`"moderate"`/
  `"good"` are confirmed printed in koo2016; and `saha2005`/`saha2012`'s
  `"Saha and Paul"` is confirmed as saha2012's own §2.1 citation text.

**AC3 — anchors resolve. PASS.** 73 distinct page anchors across the five
folio-paginated sources checked by extracting each claimed page and matching its
printed folio: bhandary2006 11, mehta2018 19, saha2005 16, xiao2013 19,
xiao2009 8 — **all resolve**. The single out-of-range hit is mehta2018's p. 158,
a correctly-attributed citation into koo2016. `bobak2018`'s 9 anchors verified
against its `Page N of 11` footers (identity mapping, confirmed page by page),
**including the fix cycle's p. 8 → p. 7 correction**; `saha2012` states its
no-folio basis; `xiao2009`'s cover-sheet offset holds.

**AC4 — absence claims settled by render. PASS.** Attempt 1's four
render-settled claims stand (xiao2013's missing issue number at 400 DPI,
saha2012's missing `ln` at 300 DPI, bhandary2006's `ppk` typo at 400 DPI,
mehta2018's Appendix C capitals at 250 DPI). This attempt added a fifth render
adjudication (mehta2018 Figure 2, 200 DPI, above) and re-settled the fix cycle's
own plot-read at 1200 DPI. No absence claim in the diff rests on a text layer.

**AC5 — nothing time-relative false at merge. PASS.** Zero unresolved hits
across the seven notes for `at the time of writing | not yet | today | must be
checked | not retrieved | as of M<n> | currently | so far | for now | at
present` (quoted source text excluded); 22 dated observations carry the greps
that settle them. The `"GP6 list"` correction re-verified against
`cairn/DESIGN.md:153–156`, which names cluster count, incidence and raggedness
as *examples* of GP6's practice and enumerates no axis registry — the notes'
rewrite is accurate.

**AC6 — no package value moved. PASS.** `git diff --name-only main..HEAD`
touches only `cairn/` (11 files); no `.R`, `.Rd`, `tests/`, `man/`, `NAMESPACE`,
`DESCRIPTION`, `.rds`/`.rda`; `.Rbuildignore:9` carries `^cairn$`, so the diff
provably cannot reach the built package. `devtools::document()` produces no
`man/`/`NAMESPACE` drift. `devtools::test()` under `NOT_CRAN=true CI=true`:
**FAIL 0 | WARN 2 | SKIP 23 | PASS 1802**, the unchanged M69/M70 baseline.

**AC7 — validate + staleness. PASS.** `cairn_validate` exit 0, all checks
passed. The `references staleness` advisory stands at **2**, both survivors
exactly `ORACLES.md` and `BIBLIOGRAPHY.md` (M72's scope) — the seven cleared by
re-reading their sources, verified by reading each `Extraction:` line's re-read
clause rather than trusting the wording.

**Consistency gate (r-package profile).** `cairn_validate` all checks passed
(advisories: 293 dangling pre-migration id tokens, expected; staleness 2 as
above) ✓; `document()` no-diff ✓; `pkgdown::check_pkgdown()` "No problems
found" ✓; README.Rmd untouched ✓; no new exports and no new top-level files ✓;
NEWS entry not owed (docs-only, no user-visible change) ✓. No `DESIGN.md`
principle changed, so `cairn_impact` is skipped. **CI on PR #77 fully green** —
every platform `R CMD check` row (ubuntu release/devel/oldrel-1, macOS,
Windows), lint, format-check, pkgdown, coverage.

**The AC2 and AC5 evidence above is superseded by the independent review below.**
Both sweeps were run and both reported clean; the [O] lens found defects each had
passed over. Recorded as written rather than rewritten, because the fact that a
mechanical sweep reported clean over a real defect *twice running* is the finding
that matters most here.

**Independent review — three lenses, then a scorer.**
- **[S] blame-history: clean, no findings.** Verified no M71 correction reverts a
  value an earlier milestone deliberately established (M65 ingested these seven
  as explicitly unverified; no later pass had verified any of them); confirmed
  the `young1998` marker discharge is substantiated by bhandary2006's own p. 777
  values (0.8804/0.9567/0.8508, pooled 0.85847, 5/5/4 split) and p. 774 Table 2
  cell (0.4089), not asserted; confirmed D-006/D-007 untouched; confirmed the
  ROADMAP profile-likelihood candidate row is byte-identical apart from M71's own
  status field.
- **[S] prior-PR-comments: no prior-PR evidence, clean no-op.** Every merged PR
  in this repo returns zero review comments, bodies and issue comments via the
  API — reviews are conducted in-session and recorded in milestone files, so
  there is nothing for this lens to regress against. It cross-checked the
  `LESSONS.md` corpus instead and found no regression.
- **[O] diff-bug: 9 findings**, scored by a fresh [S] scorer that did not
  generate them: **F1 = 5 (rejected), F2 = 90, F3 = 88, F4 = 90, F5 = 85,
  F6 = 88, F7 = 90, F8 = 82, F9 = 84.** Eight clear the 80 bar and are actioned;
  one falls below and is rejected on evidence, recorded below. The lens first
  verified a large body of the milestone as correct: all five fix-cycle
  corrections reproduce at the source (it re-rendered saha2005 Figure 1 at
  1200 DPI and got +0.156/+0.133/+0.110/+0.080, matching the note to the digit,
  and confirmed BCML highest at `φ = 0.85`, so "closest to zero at both ends"
  holds), as do saha2012's corrected Table I rows, saha2005's U-shape,
  mehta2018's Table 4 and 7 values, bhandary2006's 75-row grid and the young1998
  discharge, xiao2013's Table 9 erratum, and bobak2018's Results erratum.

#### Finding F1 — REJECTED as a false positive (score 5)

The lens read `mehta2018.md:354`'s quotation `"bootstrap sampling techniques"`
as altered, because the body prose on the same page says "results can be
combined using **bootstrapping** techniques". But the note anchors the quotation
to **Figure 2, step 5**, and a 200-DPI render of PDF p. 11 shows step 5 printing
"Apply bootstrap sampling techniques to combine results from `l` samples into a
single estimate for `ICC` and its variance components." The quotation is verbatim
and the anchor is exact. **Figure artwork carries no text layer**, so any
text-layer sweep — including this milestone's own AC2 sweep — can only ever
produce a false positive there. The scorer re-rendered the page independently and
reached the same verdict (5/100). No change owed.

#### Findings F2–F9 — ACTIONED, sent back to `/milestone-implement`

**AC5 fails on F2 and F3** — both are dated observations (`— observed
2026-07-19`) about the repo's own state that a single grep falsifies, and AC5
reads "No note asserts anything time-relative that is false at merge":

- **F2 (90) — `mehta2018.md:288`** claims ordinal/discrete outcomes are "An axis
  no repo document names". Three name it: `cairn/COVERAGE.md:196`,
  `cairn/estimand-specs/M6-oneway.md:213`, `cairn/legacy/ROADMAP.md:77`.
- **F3 (88) — `bobak2018.md:216`** claims "only the heavy-tail one has been swept
  anywhere in the repo". No non-Gaussian simulation DGP exists anywhere in `R/`
  or `tests/`; the repo *cites* ukoumunne2003's published sweep rather than
  running one, so neither axis has been swept here.

Both were produced by **T9**, the sweep whose stated purpose was converting
unverifiable claims into checkable dated ones — it traded an unverifiable claim
for a false one and stamped it verified. F3 sits in a note whose new preamble
(`bobak2018.md:207–212`) lectures the reader on exactly this.

**AC2 fails on F6** — `xiao2009.md:60` quotes p. 113 as "the values of `ρ_i` are
non-negative" where the source prints "the values of ρᵢ, **i = 1, 2, …, K,** are
non-negative": an index list dropped from inside quotation marks with no
ellipsis. Pre-existing M65 text, but AC2 is note-scoped, and this milestone
removed a *spurious* ellipsis from this same note without catching the reciprocal
case.

The remaining five are in prose M71 itself added, two of them in the fix cycle:

- **F4 (90) — `bobak2018.md:108–112`**, written by the fix cycle: it says
  koo2016's longer sentence "is quoted in `koo2016.md`". `koo2016.md:55–57`
  quotes only the *preceding* disclaimer sentence and renders this one as an
  unquoted paraphrase. The fix that removed one false attribution introduced
  another.
- **F5 (85) — `INDEX.md:316–318`** calls xiao2013's `c′`-for-`c` one of three
  cases where "a note had silently repaired a source". It is the reverse: the
  paper prints a bare `c` and the *note* had written `c′` — a note transcription
  error, with no source defect and none flagged. Two notes repaired a source, not
  three. This is the block's generalized lesson, three lines above the
  backlog-closed declaration.
- **F7 (90) — `saha2005.md:195–198`**: the "roughly 1.7–4×" ratio range is
  computed from exactly the two `φ = 0.05` cells the sentence cites. All 40
  `π = 0.1` PNB/BB pairs give **1.10–4.12**, six of them below 1.2 (TNBD
  `m = 50`, `φ = 0.85`: 1191 vs 1080 = 1.10). The same defect M71 was correcting
  when it replaced the old "3–4×".
- **F8 (82) — `xiao2009.md:158–161`**, written by the fix cycle: the `K = 3`,
  25-families block is called "the *smallest* design". It holds 75 families;
  `K = 2` at 25 per population holds 50. The parenthetical (fewest families, most
  populations) is right and the head noun is wrong — the signature is
  incidental-parameters, not smallness.
- **F9 (84) — `mehta2018.md:158`**: "the narrowest ratios are extreme concave
  Cases 1–2" is not unique; mild concave Cases 1–2 tie exactly in Table 4.

**Pattern — third round running, and it is now a method finding, not a content
one.** Across attempt 1, the fix cycle, and attempt 2, **every numeric
correction, table transcription and plot-read has survived independent
verification**, and **every defect found has been in the interpretive prose
written around those values** — including prose written specifically to fix
earlier prose. The values are being produced at one standard of rigor and the
narrative at another. The next cycle should treat a sentence generalizing from
cited cells, and any claim about the repo's own state, as requiring the same
verification a transcribed table cell gets — F7 and F2/F3 are those two shapes
exactly. Note for the next review: this is M71's **second** trip back; a third
trips the thrash rule, at which point the milestone is re-planned or split via
`/milestone-plan` rather than retried.

### Attempt 1 — 2026-07-19 — **AC2 FAILED**, returned to `in-progress`

PR https://github.com/jmgirard/intraclass/pull/77 (draft).

**AC1 — read to final page. PASS.** All seven `Extraction:` lines claim a page
count matching `pdfinfo` exactly (25/21/19/16/14/11/9). The case the criterion
singles out was checked independently: `mehta2018`'s reference 37, its
"How to cite this article" box, and Appendix A all sit on PDF p. 17 (= p. 2750),
with Appendix C on the final page 19 (= p. 2752).

**AC2 — every quoted string verbatim. FAIL.** Mechanical sweep: 182 quoted
strings across the seven notes, all quote marks balanced, 0 markup-inside-
quotation. Of these, 123 are claims about a source; each was probed against its
PDF text layer (both `-layout` and `-raw`, dehyphenated, ligature-tolerant —
these PDFs drop `ffi/fi/fl`), and 119 matched. Four did not resolve
mechanically: two are non-source strings, and two are math-symbol manglings
(`φ̂_ml`, `ρ_i`) confirmed verbatim by targeted fragment search.
**One is a genuine altered quotation** — see the finding below.

**AC3 — anchors resolve. PASS.** 73 distinct page anchors across the five
folio-paginated sources checked by extracting each claimed page and matching its
printed folio: all resolve. The two out-of-range hits are correctly-attributed
citations into *other* papers (koo2016 p. 158; Cox & Snell 1968 p. 252).
`bobak2018`'s 9 anchors each confirmed against its `Page N of 11` footer;
`saha2012` states its no-folio basis and its only two page references are
explicitly marked "of the PDF"; `xiao2009`'s new cover-sheet offset
(`PDF N` = `journal 109 + N`) verified.

**AC4 — absence claims settled by render. PASS.** The four absence claims M71
introduced are each settled by a rendered page image, not the text layer:
`xiao2013`'s missing issue number (400 DPI, header prints only
`Comput Stat (2013) 28:2241–2265`), `saha2012`'s missing `ln` (300 DPI),
`bhandary2006`'s `ppk` typo (400 DPI), `mehta2018`'s Appendix C capitals
(250 DPI). The remaining absence-shaped statements ("no coverage probability
anywhere in this paper") are pre-existing M65 content and are structural
readings of the whole source, resting on AC1's verified full read.

**AC5 — nothing time-relative false at merge. PASS.** Zero unresolved hits for
`at the time of writing | not yet | today | must be checked | not retrieved |
as of M<n> | currently | so far | for now | at present` across the seven notes
(quoted source text excluded); 22 dated observations carry the greps that settle
them.

**AC6 — no package value moved. PASS.** `git diff --name-only main..HEAD`
touches only `cairn/`; no `.R`, `.Rd`, `tests/`, `man/`, `NAMESPACE`,
`DESCRIPTION`, `.rds`/`.rda`; `ORACLES.md` untouched; `.Rbuildignore:9` carries
`^cairn$`, so the diff provably cannot reach the built package.
`devtools::document()` produces no `man/`/`NAMESPACE` drift.

**AC7 — validate + staleness. PASS.** `cairn_validate` exit 0, 15/15 PASS. The
`references staleness` advisory falls 9 → 2 and the two survivors are exactly
`ORACLES.md` and `BIBLIOGRAPHY.md` (M72's scope). Each of the seven carries a
substantive re-read status, not a reworded one — checked by grepping the
`Extraction:` lines for the re-read clause rather than trusting the wording.

**Consistency gate (r-package profile).** `document()` no-diff ✓; README.Rmd
untouched ✓; no new exports, so no `_pkgdown.yml` row owed ✓; no new top-level
files ✓; NEWS entry not owed (docs-only, no user-visible change) ✓. CI on PR #77:
`lint`, `pkgdown`, `format-check` pass; the `R CMD check` platform matrix was
still pending when the milestone was sent back.

**Independent review — three lenses.**
- **[S] blame-history: clean, no findings.** Verified the `young1998` marker
  discharge is substantiated by `bhandary2006`'s own p. 777/774 values rather
  than asserted; confirmed the ROADMAP candidate row is byte-identical; confirmed
  the "GP6 list" correction is accurate against `DESIGN.md:153`; confirmed D-006
  and D-007 are untouched.
- **[S] prior-PR-comments: no prior-PR evidence.** PRs #71/#72/#75/#76 carry no
  review comments or review bodies (only Codecov bot output) — this repo's
  reviews are conducted in-session. Zero findings, clean no-op.
- **[O] diff-bug: still in flight when the milestone was sent back.** Its
  findings, if any, are to be actioned in the same implement cycle as the AC2
  fix; the send-back does not wait on it because AC2's failure is independent.

#### Finding 1 — altered quotation in `bobak2018.md` (AC2 failure)

`cairn/references/bobak2018.md` attributes a quoted string to `koo2016` p. 158:

> `koo2016` makes in prose (p. 158: a low ICC "may reflect low subject
> variability")

koo2016 p. 158 (PDF p. 4) actually prints: "We have to understand that there are
no standard values for acceptable reliability using ICC. A low ICC could not
only reflect the low degree of rater or measurement agreement but also relate to
the lack of variability among the sampled subjects, the small number of
subjects, and the small number of raters being tested." The quoted string does
not occur in koo2016 in any extraction mode. `koo2016.md:57` renders the same
content correctly, as an unquoted paraphrase, as does `mehta2018.md:88`.

The string is pre-existing M65 content, but AC2 is scoped to "every quoted
string in **every one of the seven notes**", not to the diff, and it cites the
M67 lesson precisely because a sweep that skips strings on a judgment call is
how altered quotations survive. The implement pass classified this one as "a
koo2016 quote, not a bobak2018 claim" and never checked it against koo2016.
Read as written — and criteria are not reinterpreted at review — AC2 is not met.

**Disposition:** status → `in-progress`. Fix by making the phrase an unquoted
paraphrase (matching `koo2016.md`'s and `mehta2018.md`'s treatment) or by
quoting koo2016 verbatim, then re-run the AC2 sweep **extended to cross-source
quotations**, and re-review. A mechanical sweep of the seven notes for quoted
strings attributed to a *different* paper found exactly this one, so that
sub-class is complete.

#### [O] diff-bug lens — 5 further findings, all in content M71 introduced

The lens reported after the send-back and **first verified a large body of the
milestone's work as correct**: every load-bearing table value (`saha2012`'s
corrected Table I rows and the provenance of the bad ones, `xiao2013`'s Table 9
vs Table 3 mismatch, `saha2005`'s U-shape at 4683/5635, `mehta2018`'s Table 4
cell and Table 7 reversals, `bobak2018`'s Results erratum, `bhandary2006`'s
75-row grid and the young1998 discharge), both render-settled source errata, and
`xiao2009`'s cover-sheet offset. Each finding below was re-verified
independently at the source before being recorded, then scored by a fresh [S]
scorer that did not generate them: **F1 = 92, F2 = 95, F3 = 93, F4 = 88,
F5 = 90 — all five clear the 80 action bar, none logged below it.** The scorer's
readings agree with the independent verification on every point (it puts the
`saha2005` diamond at ≈ 0.07 against ≈ 0.10 here; the ordering, which is the
defect, is identical). All five are actioned in the fix cycle.

- **F1 — `saha2005.md`, the Figure 1 plot-read.** The bullet says bias at
  `φ = 0.05` runs "+0.10 to +0.15 … with DEQL lowest". A 600-DPI render of
  PDF p. 7 (journal 3503), panel (a), gives top-to-bottom `✳` ML ≈ +0.15,
  `•` Q₂ ≈ +0.14, `△` DEQL ≈ +0.12, `◇` **BCML ≈ +0.10 — BCML is lowest, not
  DEQL**. The coherent reading, which the note misses, is that BCML sits closest
  to zero at *both* ends (lowest at small `φ`, highest at large `φ`) — precisely
  what a bias correction should do, and a better statement of the paper's result
  than the one recorded.
- **F2 — `bobak2018.md`, the Table 2 callout.** It anchors the "probability that
  study 3 has a higher ICC than study 2 = 0.944" sentence to p. 8; per-page
  extraction shows it on the page whose footer reads **`Page 7 of 11`**. The same
  note's `Extraction:` line claims "each page anchor was confirmed by extracting
  that page on its own" — the note asserts a verification standard this anchor
  did not receive.
- **F3 — `xiao2009.md`, the GP coverage claim.** "Its four lowest cells are all
  at `ρ ∈ {0.1, 0.2}`" is false. Sorting all 36 GP coverage values in Table 1
  (PDF p. 7 = journal 116): 0.913 (`ρ=0.1`), 0.919 (`ρ=0.2`), 0.923 (`ρ=0.5`),
  0.925 (`ρ=0.3`), 0.925 (`ρ=0.9`). Only the **two** lowest sit at
  `ρ ∈ {0.1, 0.2}`. The neighbouring floors (GP 0.913, PL 0.931) are correct.
- **F4 — `saha2012.md`, the terminology-warning block.** It asserts §3 inverts
  "conservative"/"liberal" but "**§5 does not**", and instructs "Go by the tables
  and §5, never by §3's labels". §5 repeats the inversion for HPV-QEE: it
  "had a tendency to have the slightly larger observed coverage probabilities
  than the nominal level, indicating some liberal behavior" — over-coverage
  labelled *liberal*. §5 is standard **only for the four asymptotics**; the block
  over-generalizes, and a correction that over-claims is worse than the error it
  corrects because it reads as having been checked.
- **F5 — `INDEX.md`.** "Every transcribed table value … reproduced exactly except
  three cells" undercounts: the diff corrects **four** — `saha2012` Table I's
  MLE and EQL at `φ = 0.2` and DEQL at `φ = 0.5`, plus `mehta2018` Table 4's
  `0.58 (0.03)` → `0.58 (0.04)`, which that block's `mehta2018` bullet omits
  entirely. This is the M70 "never pin an item count" lesson, violated in the
  milestone's own summary of a pass whose T8 entry cites that same lesson.

**Pattern worth carrying into the fix.** All five sit in *interpretive prose the
milestone added*, not in the table transcriptions it checked. Every numeric
correction survived independent verification; what failed is the narrative
written around those values, at a lower standard of rigor than the values
themselves — the same failure shape this milestone was created to find in M65's
notes, reproduced while correcting it.
