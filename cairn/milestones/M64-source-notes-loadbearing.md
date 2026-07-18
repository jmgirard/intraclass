<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M64: Source notes — the nine load-bearing primary sources

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Give each primary source the test suite already depends on its own
`<citekey>.md` source note, re-read from the PDF with page/table anchors.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** nine `<citekey>.md` source notes, each re-read from
`cairn/references/pdf/` per the maintainer's plan-gate choice (migrate **and**
deepen, not text-shuffle): `shrout1979`, `mcgraw1996`, `fleiss1973`, `koo2016`,
`tenhove2020`, `tenhove2022`, `tenhove2024`, `tenhove2025a` (network data) and
`tenhove2025b` (planned incomplete) — the citekey pair assigned by M63/T1. Each carries the validation-doctrine fields: full
citation, extracted values with page/table anchors, verbatim-critical values
quoted exactly, what traces to it, open questions. `BIBLIOGRAPHY.md` entries
shrink to citation + pointer as their annotations move into the notes;
`INDEX.md` gains a line per note.

**Out:** the interval-methods / robustness cluster → M65; the eleven
foundational + ICC-equality-testing papers → the tier-C candidate row; the
Jorgensen 2021 SEM source → blocked on the maintainer supplying the PDF (M63/AC5),
recorded as an open gap rather than written from memory; **any change to an
oracle value** — a note that disagrees with `ORACLES.md` is a finding to
escalate, never a silent correction.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Nine `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with all five validation-doctrine fields
      populated and every extracted value carrying a page or table anchor.
- [ ] AC2: Every value quoted in a note is verified against the PDF at the
      cited page — spot-checked at review against at least one value per note,
      with the check recorded in the Review section.
- [ ] AC3: No oracle value in `ORACLES.md` changes. Any disagreement found
      between a re-read source and the registry is recorded in the work log and
      escalated at the review gate, not silently reconciled. (RB tripwire:
      no-oracle)
- [ ] AC4: `BIBLIOGRAPHY.md` entries for the nine are reduced to citation +
      a pointer to the note (no duplicated extraction text), and `INDEX.md`
      carries one line per new note.
- [ ] AC5: `cairn_validate` passes; the profile `verify` slot is clean
      (`NOT_CRAN=true CI=true`, failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Notes for the classical trio — `shrout1979`, `mcgraw1996`,
      `fleiss1973`. `shrout1979` is the O1 worked-example anchor
      (`tests/testthat/helper-shrout-fleiss.R`); anchor its table values
      exactly.
- [ ] T2: Notes for the ten Hove family — `tenhove2020` (O-Bayes hyperprior
      DGP), `tenhove2022` (M5 multilevel estimand, Eqs. 6–7/12–13, Table 3),
      `tenhove2024` (selection guidelines), `tenhove2025b` (planned-incomplete;
      the ADR-002/003 engine + MC-CI basis), and `tenhove2025a` (network data).
      Note the metadata trap: `tenhove2022.pdf` carries a 2021 copyright
      line but is the 2022 *Psychological Methods* 27(4):650–666 paper.
- [ ] T3: Note for `koo2016` — the IP3-sensitive interpretation-band source;
      capture the "judge against the CI, not the point" guidance the
      `getting-started.Rmd` caveat rests on.
- [ ] T4: Cross-check each note's extracted values against the corresponding
      `ORACLES.md` entries; log agreements, escalate any disagreement.
- [ ] T5: Trim the nine `BIBLIOGRAPHY.md` annotations to citation + pointer;
      add the `INDEX.md` lines.
- [ ] T6: Run `cairn_validate` + the profile `verify` slot; open the PR and
      drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (plan gate: maintainer chose full
  extraction with a fresh PDF re-read for the load-bearing sources, over a
  text-only migration of the existing bibliography annotations).
- 2026-07-18: minor amendment by /milestone-implement M63 — `tenhove2025`
  becomes the `tenhove2025a`/`tenhove2025b` pair (M63 implement gate).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
