<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M72: Verify the oracle registry and the bibliography

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M70, M71   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Define and apply a verification bar for the repo's two index pages —
`ORACLES.md` (39 entries, the declared registry home per D-007) and
`BIBLIOGRAPHY.md` — whose entries mostly trace to committed seeded scripts
rather than to pages of a PDF.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a D-entry defining a **bar split by entry kind** — source-traceable
entries re-read against their cited source; script-derived entries confirmed
against their committed script's recorded output *without* re-running — then
applied to all 39 `ORACLES.md` entries and to `BIBLIOGRAPHY.md`'s entries,
starting with the 16 that moved as text at the D-007 split and were never
read against sources. Absorbs the Shrout & Fleiss three-decimal attribution
candidate: `ORACLES.md`'s O-OW ("published to 3 dp") and O1 ("Values (3 dp)"),
plus `tests/testthat/helper-shrout-fleiss.R:72–73`, which makes this
milestone touch code.

**Out:** re-running the seeded scripts. The Bayesian sweeps are multi-hour
background jobs and the gate chose confirmation-against-recorded-output
instead; a discrepancy found there is escalated, and re-running that script
becomes its own milestone. The 13 source notes → M70, M71.

**Depends on M70/M71** because a note's re-verification can correct a
bibliographic field, and `BIBLIOGRAPHY.md` should be checked once against a
settled shelf rather than twice.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] A D-entry in `cairn/DECISIONS.md` defines the split bar, states why
      re-running the seeded scripts was refused, and names what a
      script-derived entry's "verified" status does and does not assert.
- [ ] All 39 `ORACLES.md` entries are classified by kind, and the
      classification is recorded in the file itself so a later reader can
      tell which assurance each entry carries.
- [ ] Every source-traceable entry's values are confirmed against the cited
      source at the cited page, or corrected in place with the correction
      cited.
- [ ] Every script-derived entry names a committed script that exists, and
      the entry's recorded values match that script's recorded output.
- [ ] The Shrout & Fleiss values are attributed to what the source actually
      prints: Table 4 prints **two** decimals, so O-OW, O1, and
      `helper-shrout-fleiss.R:72–73` no longer call the six three-decimal
      values published. No oracle value changes — all six round to the
      printed figure (M69 AC4).
- [ ] `BIBLIOGRAPHY.md` entries are checked field-by-field against their
      sources, with any field the source does not print recorded as withheld
      rather than invented (#4).
- [ ] The r-package `verify` slot is clean and `cairn_validate` passes, with
      both pages' `Extraction:` lines reflecting work actually done — no
      wording change made to clear an advisory (LESSONS 2026-07-18/M68).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: draft the D-entry defining the split bar; it governs the rest of
      the milestone, so it lands first.
- [ ] T2: classify all 39 `ORACLES.md` entries as source-traceable or
      script-derived (`cairn/references/ORACLES.md`; entries span M1–M39),
      and record the kind per entry.
- [ ] T3: verify the source-traceable entries against their cited sources —
      O1, O2 (hand-derived), O-OW and any others T2 surfaces. Where the
      source now has a verified `<citekey>.md` note from M69/M70/M71, check
      against the source itself, not the note.
- [ ] T4: for each script-derived entry, confirm the named script exists
      under `data-raw/` and that the entry's values match its recorded
      output; escalate any mismatch rather than re-running.
- [ ] T5: fix the Shrout & Fleiss three-decimal attribution in `ORACLES.md`
      (O-OW, O1) and in `tests/testthat/helper-shrout-fleiss.R:72–73` —
      that file's *top* provenance header is already accurate and must be
      left alone (LESSONS 2026-07-18/M69).
- [ ] T6: check `BIBLIOGRAPHY.md` field-by-field, prioritizing the 16
      D-007 split entries; record withheld fields as withheld.
- [ ] T7: update both `Extraction:` lines and `INDEX.md`; run
      `cairn_validate`, `lintr::lint_package()`, `air format --check`, and
      the r-package `verify` slot (T5 touches a test helper, so this is not
      a docs-only milestone).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (plan gate: bar split by entry kind, re-running the seeded scripts refused as multi-hour background work; absorbs the Shrout & Fleiss three-decimal attribution candidate from M69's AC4 escalation; depends on M70/M71 so BIBLIOGRAPHY is checked once against a settled shelf).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
