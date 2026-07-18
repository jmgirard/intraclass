<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M64: Source notes — the ten load-bearing primary sources

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m64-source-notes-loadbearing`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Give each primary source the test suite already depends on its own
`<citekey>.md` source note, re-read from the PDF with page/table anchors.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** ten `<citekey>.md` source notes, each re-read from
`cairn/references/pdf/` per the maintainer's plan-gate choice (migrate **and**
deepen, not text-shuffle): `shrout1979`, `mcgraw1996`, `fleiss1973`, `koo2016`,
`jorgensen2021` (the O-SEM SEM absolute-error source), `tenhove2020`,
`tenhove2022`, `tenhove2024`, `tenhove2025a` (network data) and
`tenhove2025b` (planned incomplete) — the citekey pair assigned by M63/T1. Each carries the validation-doctrine fields: full
citation, extracted values with page/table anchors, verbatim-critical values
quoted exactly, what traces to it, open questions. `BIBLIOGRAPHY.md` entries
shrink to citation + pointer as their annotations move into the notes;
`INDEX.md` gains a line per note.

**Out:** the interval-methods / robustness cluster → M65; the foundational
shelf → M66; the ICC-equality-testing cluster → M67; **any change to an
oracle value** — a note that disagrees with `ORACLES.md` is a finding to
escalate, never a silent correction. Note `jorgensen2019` (planned-missing
efficiency) is a *different* paper and belongs to M66, not here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Ten `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with all five validation-doctrine fields
      populated and every extracted value carrying a page or table anchor.
- [ ] AC2: Every value quoted in a note is verified against the PDF at the
      cited page — spot-checked at review against at least one value per note,
      with the check recorded in the Review section.
- [ ] AC3: No oracle value in `ORACLES.md` changes. Any disagreement found
      between a re-read source and the registry is recorded in the work log and
      escalated at the review gate, not silently reconciled. (RB tripwire:
      no-oracle)
- [ ] AC4: `BIBLIOGRAPHY.md` entries for the ten are reduced to citation +
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

- [x] T1: Notes for the classical trio — `shrout1979`, `mcgraw1996`,
      `fleiss1973`. `shrout1979` is the O1 worked-example anchor
      (`tests/testthat/helper-shrout-fleiss.R`); anchor its table values
      exactly.
- [ ] T2: Notes for the ten Hove family — `tenhove2020` (O-Bayes hyperprior
      DGP), `tenhove2022` (M5 multilevel estimand, Eqs. 6–7/12–13, Table 3),
      `tenhove2024` (selection guidelines), `tenhove2025b` (planned-incomplete;
      the ADR-002/003 engine + MC-CI basis), and `tenhove2025a` (network data).
      Note the metadata trap: `tenhove2022.pdf` carries a 2021 copyright
      line but is the 2022 *Psychological Methods* 27(4):650–666 paper.
- [ ] T3: Notes for `koo2016` — the IP3-sensitive interpretation-band source;
      capture the "judge against the CI, not the point" guidance the
      `getting-started.Rmd` caveat rests on — and `jorgensen2021`, the O-SEM
      absolute-error source (Eq. 6 defines σ²_i as the raw variance of the
      effects-coded indicator intercepts).
- [ ] T4: Cross-check each note's extracted values against the corresponding
      `ORACLES.md` entries; log agreements, escalate any disagreement.
- [ ] T5: Trim the ten `BIBLIOGRAPHY.md` annotations to citation + pointer;
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
- 2026-07-18: amended by /milestone-review M63 — `jorgensen2021.pdf` is present
  after all (M63's "no PDF" record was wrong), so the O-SEM source joins this
  milestone: nine → ten notes, no longer blocked.
- 2026-07-18: /milestone-implement — status in-progress, branch
  `m64-source-notes-loadbearing` cut from main.
- 2026-07-18: implement gate — maintainer chose: hybrid delegation (oracle
  anchors read in-session, the rest by [O] subagents), ukoumunne2003-depth
  notes, and citation + one-clause role + pointer for the BIBLIOGRAPHY trim.
- 2026-07-18: T1 done — `shrout1979` (read in-session), `mcgraw1996`,
  `fleiss1973` (both [O] subagents, diffs verified against the PDFs).
- 2026-07-18: T4 finding (shrout1979) — Table 4 (p. 424) prints the six ICCs to
  **two** decimals; O1 and `helper-shrout-fleiss.R` carry three and the helper
  header calls them "the published Shrout & Fleiss numbers to three decimals".
  Values agree at the paper's precision; the third decimal traces to
  `psych`/`DescTools`, not the paper. No oracle value changes — attribution
  wording only, escalated to the review gate per AC3.
- 2026-07-18: T4 finding (mcgraw1996) — Case 3A `θ²_c = Σc²_j/(k−1)` confirmed
  verbatim (Table 1, p. 32); agrees with the repo's `θ²_r` (symbol differs,
  quantity and divisor identical). Published correction (1(4):390) present as
  the PDF's final page and extracted. No ORACLES.md disagreement.
- 2026-07-18: T4 finding (mcgraw1996) — possible **uncorrected** typo in the
  paper: Table 8 (p. 42) Type-C Type-k F renders `MS_W` where Appendix A §A4
  (p. 44) derives `MS_E`. Not in the published correction. Package impact
  believed nil (no test cites Table 8); recorded for the review gate, not
  reconciled.
- 2026-07-18: T5 input (fleiss1973) — the source has an `INDEX.md` line but **no**
  `BIBLIOGRAPHY.md` entry; T5 must add one rather than trim. Nothing in `R/`,
  `tests/`, `vignettes/`, or `ORACLES.md` traces to it (shelf evidence only).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
