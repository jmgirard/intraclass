<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M72: Verify the oracle registry and the bibliography

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M70, M71   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m72-verify-oracle-registry-bibliography`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Define and apply a verification bar for the repo's two index pages —
`ORACLES.md` (39 entries, the declared registry home per D-007) and
`BIBLIOGRAPHY.md` — whose entries mostly trace to committed seeded scripts
rather than to pages of a PDF.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a D-entry defining a **bar split by entry kind** — *source-traceable*
entries re-read against their cited source; *script-derived* entries confirmed
against what their committed script actually commits, *without* re-running;
*mixed* entries (both legs, e.g. O1, O-OW, O-SEM) verified on each leg by its
own rule — then applied to all 39 `ORACLES.md` entries and to all 38
`BIBLIOGRAPHY.md` entries at a depth set by provenance: field-by-field for the
16 that moved as text at the D-007 split and were never read against sources,
a lighter consistency pass over the 22 authored from shelf PDFs by M64–M67.
Absorbs the Shrout & Fleiss three-decimal attribution candidate:
`ORACLES.md`'s O-OW ("published to 3 dp") and O1 ("Values (3 dp)"),
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

- [ ] A D-entry in `cairn/DECISIONS.md` defines the bar for all three kinds,
      states why re-running the seeded scripts was refused, and names what a
      script-derived entry's "verified" status does and does not assert.
- [ ] All 39 `ORACLES.md` entries are classified as source-traceable,
      script-derived, or mixed, and the classification is recorded in the
      file itself so a later reader can tell which assurance each entry
      carries.
- [ ] Every source-traceable entry's values — and the source leg of every
      mixed entry — are confirmed against the cited source at the cited
      page, or corrected in place with the correction cited.
- [ ] Every script-derived entry — and the script leg of every mixed entry —
      names a committed script that exists, and the entry's values are
      confirmed against what the repo actually commits: an inline expected
      value in the script source (hardcoded constant, tolerance target, or
      trailing comment) or a committed fixture under
      `tests/testthat/fixtures/`. An entry whose script commits neither is
      recorded as **script-attested, values not independently confirmed**,
      naming that confirmation would require re-running (Out of scope) —
      never stamped confirmed. The count of entries in each state is not
      pinned in the record (LESSONS 2026-07-19/M70).
- [ ] The Shrout & Fleiss values are attributed to what the source actually
      prints: Table 4 prints **two** decimals, so O-OW, O1, and
      `helper-shrout-fleiss.R:72–73` no longer call the six three-decimal
      values published. No oracle value changes — all six round to the
      printed figure (M69 AC4).
- [ ] All 38 `BIBLIOGRAPHY.md` entries are checked at a depth set by
      provenance — field-by-field against sources for the 16 D-007 split
      entries, a consistency pass over the 22 authored from shelf PDFs by
      M64–M67 — with any field the source does not print recorded as
      withheld rather than invented (#4).
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

- [ ] T1: draft the D-entry defining the bar for all three kinds; it governs
      the rest of the milestone, so it lands first.
- [ ] T2: classify all 39 `ORACLES.md` entries as source-traceable,
      script-derived, or mixed (`cairn/references/ORACLES.md`; entries span
      M1–M39), and record the kind per entry.
- [ ] T3: verify the source-traceable entries — and the source leg of each
      mixed entry — against their cited sources: O1, O2 (hand-derived),
      O-OW, O-SEM and any others T2 surfaces. Where the source now has a
      verified `<citekey>.md` note from M69/M70/M71, check against the
      source itself, not the note.
- [ ] T4: for each script-derived entry and the script leg of each mixed
      entry, confirm the named script exists under `data-raw/` (all 28
      referenced scripts were confirmed present at the implement gate) and
      that the entry's values match an inline expected value or a committed
      fixture; where the script commits neither, record the honest
      script-attested status. Escalate any mismatch rather than re-running.
- [ ] T5: fix the Shrout & Fleiss three-decimal attribution in `ORACLES.md`
      (O-OW, O1) and in `tests/testthat/helper-shrout-fleiss.R:72–73` —
      that file's *top* provenance header is already accurate and must be
      left alone (LESSONS 2026-07-18/M69).
- [ ] T6: check all 38 `BIBLIOGRAPHY.md` entries — field-by-field for the 16
      D-007 split entries, a consistency pass over the 22 from M64–M67;
      record withheld fields as withheld.
- [ ] T7: update both `Extraction:` lines and `INDEX.md`; run
      `cairn_validate`, `lintr::lint_package()`, `air format --check`, and
      the r-package `verify` slot (T5 touches a test helper, so this is not
      a docs-only milestone).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (plan gate: bar split by entry kind, re-running the seeded scripts refused as multi-hour background work; absorbs the Shrout & Fleiss three-decimal attribution candidate from M69's AC4 escalation; depends on M70/M71 so BIBLIOGRAPHY is checked once against a settled shelf).
- 2026-07-19: /milestone-implement started; branch `m72-verify-oracle-registry-bibliography` cut from main.
- 2026-07-19: gated amendment (implement gate, 3 questions) — AC4 rewritten: no committed script output exists to verify against (data-raw holds zero csv/txt, one rds; `data-raw/.oracle-*-checkpoint.rds` is gitignored; 35 scripts assert via stopifnot, only 4 write a committed fixture), so AC4 now verifies against inline expected values or committed fixtures and records "script-attested, values not independently confirmed" where neither exists. All 28 scripts named in ORACLES.md confirmed present on disk at the gate.
- 2026-07-19: gated amendment — a third entry kind "mixed" added (AC2/AC3/AC4, Scope, T2–T4): O1, O-OW, O-SEM and their like carry both a source and a script leg, and each leg is verified by its own rule; classifying a mixed entry as one kind would leave half its values unverified.
- 2026-07-19: gated amendment — AC6/T6 scope set to all 38 BIBLIOGRAPHY entries at a depth set by provenance (field-by-field for the 16 D-007 split entries, consistency pass over the 22 from M64–M67); the plan's "starting with the 16" left the remainder's disposition unstated.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
