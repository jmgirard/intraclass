<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M67: Source notes — the ICC-equality-testing cluster

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ingest the four ICC-equality-testing papers as short source notes that also
document *why* hypothesis tests comparing ICCs sit outside the contract boundary.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** four `<citekey>.md` source notes read from `cairn/references/pdf/`:
`donner2002` (testing equality of dependent ICCs), `konishi1989` (testing
equality of several ICCs), `naik2007` (equality under unequal family sizes),
`young1998` (equality under unequal family sizes). Deliberately **short** notes:
citation, the test statistic and its design assumptions with anchors, and an
explicit IP2 line stating that comparing ICCs across groups is not the
interrater-ICC estimation contract. Together they become the citable record for
that boundary, so the question does not get re-litigated from memory.

**Out:** implementing, exporting, or prototyping any equality test → refused;
this cluster is ingested *as evidence of a boundary*, and adopting it would
take an IP2 constitutional amendment (D-entry + user decision). The other
tier-C papers → M66; the interval-methods cluster → M65.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Four `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields;
      each test statistic and its design assumptions carry a page anchor.
- [ ] AC2: Each note carries an explicit IP2 boundary line stating that
      ICC-equality testing is outside the package's contract, and that adopting
      it would require an IP2 amendment — not a feature request.
- [ ] AC3: Each note's "what traces to it" field states plainly that nothing in
      the package traces to it, and that this is by design.
- [ ] AC4: `DESIGN.md`'s IP2 statement gains a one-line cross-reference to this
      cluster as the citable record for the boundary (a pointer only — the
      substance stays in the notes).
- [ ] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [ ] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
      failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Notes for the general-case pair — `konishi1989` (several ICCs),
      `donner2002` (dependent ICCs).
- [ ] T2: Notes for the unequal-family-size pair — `young1998`, `naik2007`;
      note the overlap between them rather than duplicating the derivation.
- [ ] T3: Add the one-line IP2 cross-reference in `cairn/DESIGN.md`.
- [ ] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [ ] T5: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the tier-C candidate row's
  out-of-contract half; framed as boundary documentation rather than
  capability ingestion, since IP2 permanently excludes ICC-equality testing).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
