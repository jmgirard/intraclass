<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M71: Re-verify the robustness and interval-methods extractions (7 notes)

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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
- [ ] T3: `mehta2018` (19 pp) — read past the reference list to the
      appendices at pp. 2750–2752; they hold the tables behind the paper's
      central safeguard claim.
- [ ] T4: `saha2005` (16 pp) — reconcile against `saha2012`, its sibling.
- [ ] T5: `bhandary2006` (14 pp) — INDEX.md places it in the M67
      equality-testing cluster by subject; confirm the cross-references that
      fence names actually hold. Then clear the two inherited-marker claims
      in `young1998.md` against this source.
- [ ] T6: `bobak2018` (11 pp).
- [ ] T7: `xiao2009` (9 pp).
- [ ] T8: mechanical quotation sweep — enumerate every quoted string in all
      seven notes and re-check each against its source; record the count
      swept per note as the evidence.
- [ ] T9: grep the seven notes for time-relative phrasing (`at the time of
      writing`, `not yet`, `today`, `must be checked`, `not retrieved`) plus
      the `Traces to` lead sentence, and re-resolve every hit.
- [ ] T10: update `INDEX.md`'s M65 paragraph and the backlog narrative; run
      `cairn_validate` and the r-package `verify` slot; confirm docs-only.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (absorbs the M65 seven from the "remaining nine source extractions" candidate row, whose other two went to M70; plan gate: low priority — nothing in the package traces to these seven and five are outside the IP2 contract boundary).
- 2026-07-19: gated Scope amendment at the implement question gate — `young1998.md`'s two `bhandary2006` claims, marked inherited-not-verified by M70's T6 hand-off, are resolved in place under T5 (an eighth file, M70-owned). Also gated: notes re-read in the main session, not delegated; a correction falsifying the profile-likelihood candidate row's premise is fixed in the note and escalated as a review finding, never a silent ROADMAP rewrite.
- 2026-07-19: T1 `xiao2013` verified (25 pp, all read; Appendix pp. 2258–2264 and References p. 2265 confirmed as the final page with nothing after; every quoted string swept). **The load-bearing claims all hold**: all four Table 4 anchor cells and all three Table 6 cells reproduce cell-by-cell, Eqs. (37)–(40)/(44)/(64)/(65) confirmed, and the ROADMAP candidate row's two premises (two-way random with random raters; naive PL under-covers) are correct — no escalation needed. Corrections: Table 2 is `R = 3, S = 50` ONLY (the paper's worst PL geometry), not a sweep — the note read its 731–862 range as general; the under-coverage result was pinned at "stated four times" when it recurs in six places, now count-free (Introduction p. 2243 and §6 p. 2257 added); the AL quotation was altered ("is computed" for the source's "are computed"); the random-raters quotation was double-anchored to pp. 2241 and 2242 where only the Abstract prints it; Eq. (65) is on p. 2264, only its closing remark on p. 2265; Eq. (7)'s constant is `c`, not `c′`; `κ_corr` quotation silently lowercased the source's leading "A"; "pp. 2258" → p. 2258. Additions: a **source erratum** — Table 9's `κ_m` for `R = 5, S = 10` prints 0.23 where its own footnote's source (Table 3, one-sided `δ_U = 16`) gives 0.33, the only one of six cells that disagrees; a second, harmless one — Eq. (66)'s closing sentence calls `D` a determinant where it is `ln|V|`; the issue number `28(5)` is nowhere in the PDF and is now marked as publisher-record-only; Example 3's "nine (`S = 18`)" resolved as legs-not-children, not an erratum; `bartko1966.md`'s inbound cross-reference added. No package value affected.
- 2026-07-19: T2 `saha2012` verified (21 pp, all read; Appendices A/B on PDF p. 20 sit BEFORE the reference list, which ends the document on p. 21; 30 quoted strings swept). **Two substantive extraction defects, both in this note's own transcriptions.** (a) Of the three transcribed Table I `m = 73` rows, two were cross-contaminated between adjacent `φ` rows: the `π = 0.1, φ = 0.2` row took its MLE `0.676 (0.140)` and EQL `0.381 (0.122)` from the `φ = 0.3` row (true: `0.735 (0.121)`, `0.524 (0.099)`), and the `φ = 0.5` row took DEQL's length from the `φ = 0.4` row (`0.630 (0.205)` → printed `0.630 (0.232)`). All five `m = 19` rows and the third `m = 73` row were correct. (b) The transcribed log-likelihood silently ADDED an `ln` the source does not print on its third sum — settled by a 300-DPI render, not the text layer (M66); the `ln` is mathematically required by Eq. (1), so it is a source typo, but the note now transcribes as printed and says so. Also corrected: the note repeated §3's **inverted** "conservative"/"liberal" labels — §3 calls under-covering "conservative" and over-covering "liberal" while §5 uses the standard convention ("very liberal behavior" for the same under-coverers), so the note's "FZT-MLE … stays conservative" read as the opposite of what the paper measured (FZT-MLE under-covers, Table I); the Figure 1 plot-read grouped QEE with the under-coverers and omitted FZT-MLE — a 200-DPI render shows QEE sitting AT nominal with the tightest box of the four asymptotics; config (v)'s TNBD is truncated below 1 **and above 15**; the Table I caption quotation had altered comma placement. Additions: the paper says "six methods" in §3 and §5 while tabulating seven (FZT-MLE is the one dropped); its prose cites Eqs. (6) and (7), which do not exist — only (1)–(3) are numbered; Table I's `m = 73, π = 0.5` block carries visible source defects (EQL/DEQL duplicating MLE/QEE at `φ = 0.1`, FZT-MLE lengths of 0.813/0.834 among neighbours of ≈ 0.1); the caption's method order differs from the column order; and §5 names a live R implementation (`plkhci`) plus a SAS route, so unlike `xiao2013` an independent-implementation oracle is reachable. Applications Tables IV–VI re-checked value by value, including the negative lower limits, which the printed interval lengths confirm. No package value affected.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
