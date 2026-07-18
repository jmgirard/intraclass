<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M64: Source notes — the ten load-bearing primary sources

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m64-source-notes-loadbearing` · PR #70   <!-- owner: implement (branch) / review (PR URL) · create -->

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
- [x] T2: Notes for the ten Hove family — `tenhove2020` (O-Bayes hyperprior
      DGP), `tenhove2022` (M5 multilevel estimand, Eqs. 6–7/12–13, Table 3),
      `tenhove2024` (selection guidelines), `tenhove2025b` (planned-incomplete;
      the ADR-002/003 engine + MC-CI basis), and `tenhove2025a` (network data).
      Note the metadata trap: `tenhove2022.pdf` carries a 2021 copyright
      line but is the 2022 *Psychological Methods* 27(4):650–666 paper.
- [x] T3: Notes for `koo2016` — the IP3-sensitive interpretation-band source;
      capture the "judge against the CI, not the point" guidance the
      `getting-started.Rmd` caveat rests on — and `jorgensen2021`, the O-SEM
      absolute-error source (Eq. 6 defines σ²_i as the raw variance of the
      effects-coded indicator intercepts).
- [x] T4: Cross-check each note's extracted values against the corresponding
      `ORACLES.md` entries; log agreements, escalate any disagreement.
- [x] T5: Trim the ten `BIBLIOGRAPHY.md` annotations to citation + pointer;
      add the `INDEX.md` lines.
- [x] T6: Run `cairn_validate` + the profile `verify` slot; open the PR and
      drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (gate: full extraction with a fresh PDF re-read, over a text-only migration).
- 2026-07-18: minor amendment by /milestone-implement M63 — `tenhove2025` becomes the `tenhove2025a`/`tenhove2025b` pair.
- 2026-07-18: amended by /milestone-review M63 — `jorgensen2021.pdf` present after all, so the O-SEM source joins: nine → ten notes, unblocked.
- 2026-07-18: /milestone-implement — status in-progress, branch `m64-source-notes-loadbearing` cut from main.
- 2026-07-18: implement gate — maintainer chose hybrid delegation (oracle anchors in-session, rest by [O] subagents), ukoumunne2003-depth notes, citation + one-clause role + pointer for the trim.
- 2026-07-18: T1 done — `shrout1979` in-session; `mcgraw1996`, `fleiss1973` by [O] subagents, diffs verified against the PDFs.
- 2026-07-18: T2 done — `tenhove2022` in-session; `tenhove2020`, `tenhove2024`, `tenhove2025a`, `tenhove2025b` by [O] subagents, diffs verified against the PDFs.
- 2026-07-18: T3 done — `jorgensen2021` in-session; `koo2016` by [O] subagent, verified against p. 161.
- 2026-07-18: T4 done — every note cross-checked against `ORACLES.md`; **no oracle value disagrees with any re-read source**, verified mechanically (`git diff main` on `ORACLES.md` and `tests/` is empty). Confirmed as printed: O1 Table 2/3/4 values, Case 3A `θ²_c = Σc²_j/(k−1)`, O-SEM Eq. 6 (raw, ÷ k−1, no bias correction), O-Bayes half-*t*(4,0,1) on SDs + DGP, and the tenhove2022 Eqs. 6–7/12–13 estimand.
- 2026-07-18: T4 escalations (AC3) — all attribution/citation-hygiene, no value change; substance in each note's `## Open questions`: `shrout1979` (Table 4 prints 2 dp, not the 3 dp the O1 helper header attributes to the paper) · `mcgraw1996` (possible uncorrected typo, Table 8 `MS_W` vs Appendix A `MS_E`) · `tenhove2020` (`ORACLES.md` cites §4.1.1–4.1.3, absent from the shelf manuscript; prior spec is §4.1/p. 7 not "§3.3/§4.1"; relative bias printed signed, not absolute; per-cell population ICCs 0.4950/0.4808 are repo-derived) · `tenhove2025b` (**ADR-003 sourcing gap** — it claims a boundary-respecting MC scale the paper does not describe; the paper's own example prints a negative variance CI limit, p. 1057) · `tenhove2024` (Figure 2's crossed-unbalanced cell prints a nested error term — confirmed independently at 300 dpi) · `koo2016` (band inclusivity ambiguous as printed; no issue number; Table 3 one-way row prints `(k+1)MS_W`) · `tenhove2025a` (round-robin designs out of scope by structure, though IP2's wording does not exclude them on its face).
- 2026-07-18: T4 coverage gap (tenhove2024) — the package implements no `ICC(Q,·)` and no `q` term; Figure 2 routes incomplete + relative there, while the package computes `ICC(C,k̂)`. Candidate milestone material, raised at the review gate, out of scope here.
- 2026-07-18: T5 done — the ten `BIBLIOGRAPHY.md` entries trimmed to citation + one-clause role + note pointer; **two were missing entirely and were added** (`fleiss1973`, and the 60(3) `tenhove2025a`), the ten Hove block reordered and given `2025a`/`2025b` suffixes; ten `INDEX.md` lines added and the shelf inventory updated (18 bibliography entries, 12 ingested).
- 2026-07-18: T6 done — `cairn_validate` all 15 checks pass (292 pre-existing dangling-id advisories, none in the new files); `NOT_CRAN=true CI=true devtools::test()` = FAIL 0 | WARN 2 | SKIP 23 | PASS 1802. PR #70 opened; all 11 CI checks green. Status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
