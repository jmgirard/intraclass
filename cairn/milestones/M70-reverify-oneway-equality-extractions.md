<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M70: Re-verify the one-way and equality-testing extractions (6 notes)

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] T1: `ukoumunne2003` (17 pp) — leads; D-006's GO rests on its `log F`
      bootstrap-t. Note is thin at 81 lines; expect additions, not just
      corrections.
- [ ] T2: `ohyama2025` (16 pp) — 61-line note, the thinnest on the shelf.
- [ ] T3: `donner2002` (13 pp) — the only cluster member inside the
      interrater setting; its IP2 fence is stated twice and both must hold.
- [ ] T4: `konishi1989` (13 pp).
- [ ] T5: `naik2007` (13 pp) — the p. 6503 negative-LRT finding is
      load-bearing for INDEX.md's "must not be cited as a concordant pair".
- [ ] T6: `young1998` (11 pp) — its Eq. (2.6) quotation was already corrected
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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
