<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M63: References migration — ORACLES.md + BIBLIOGRAPHY.md, citekey reconciliation

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m63-references-migration`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Convert `cairn/references/` from the single pre-migration `REFERENCES.md` to the
cairn file family — a declared oracle registry, a bibliography, and a reconciled
citekey namespace — without changing any oracle value.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** split `REFERENCES.md` (1346 lines) into `ORACLES.md` (the ~40-entry
registry, lines 1–1277) and `BIBLIOGRAPHY.md` (lines 1278–1346), retiring the
`REFERENCES.md` name; update the ~13 live cross-referencing files; add the
validation-doctrine **registry-pointer** line to `DESIGN.md` Conventions and
close the `DESIGN.md:205` Known-issues wart; a D-entry adopting `ORACLES.md`
(reconciling the open cairn-side D-024 question); reconcile the `pdf/` citekey
namespace against actual PDF content (`hove2025` is misnamed; the Jorgensen 2021
source has no PDF); rebuild `INDEX.md`.

**Out:** writing any `<citekey>.md` source note → M64 (load-bearing sources),
M65 (interval-methods cluster), and the tier-C candidate row; re-reading any
PDF for extraction → same; editing `cairn/legacy/**` or
`CLAUDE_CODE_KICKOFF.md` (entombed/founding documents, kept verbatim — their
`REFERENCES.md` mentions are historical record, not stale links).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `cairn/references/ORACLES.md` and `cairn/references/BIBLIOGRAPHY.md`
      exist; `REFERENCES.md` is reduced to a ≤6-line pointer stub naming both
      successors and the adopting D-entry (retained so the deliberately
      un-edited links in `cairn/legacy/**`, `CLAUDE_CODE_KICKOFF.md`, and
      `data-raw/reviews/` still resolve — implement gate 2026-07-18). Every one
      of the ~40 oracle entries and every bibliography entry is present in
      exactly one of the two successors, with **no numeric value, `Status`
      line, or citation text altered** — verified by a diff of the
      concatenated split against the original file.
- [ ] AC2: No live file *substantively* references `REFERENCES.md` as a content
      home:
      `grep -rn "REFERENCES.md" --include="*.R" --include="*.md" --include="*.Rmd" .`
      returns hits only under `cairn/legacy/`, `CLAUDE_CODE_KICKOFF.md`,
      `data-raw/reviews/`, the stub itself, and the stub's `INDEX.md` line. The
      stale `project/REFERENCES.md` path at
      `tests/testthat/test-vignette-claims.R:8` is corrected too.
- [ ] AC3: `cairn/DESIGN.md` Conventions carries a one-line oracle **registry
      pointer** naming `cairn/references/ORACLES.md`
      (validation-doctrine "Registry pointer"), and the "No cairn-canonical
      oracle-registry home yet" Known-issues bullet (`DESIGN.md:205`) is struck
      as resolved.
- [ ] AC4: A D-entry in `cairn/DECISIONS.md` records the `ORACLES.md` adoption,
      the split rationale, and the reconciliation with the cairn-side D-024
      open question.
- [ ] AC5: Citekey reconciliation recorded in the work log: `hove2025.pdf` is
      ten Hove, Jorgensen & van der Ark (2025) *Interrater Reliability for
      Interdependent Social Network Data*, MBR 60(3):444–459,
      doi:10.1080/00273171.2024.2444940 → `tenhove2025a`; the former
      `tenhove2025.pdf` (*Planned Incomplete Data*, MBR 60(5):1042–1061) →
      `tenhove2025b` (letter suffixes ordered by issue; implement gate
      2026-07-18);
      and the absence of a PDF for the load-bearing Jorgensen (2021) *Psych*
      3(2):113–133 SEM absolute-error source (O-SEM) is recorded as an open
      gap with the maintainer asked for it.
- [ ] AC6: `INDEX.md` has exactly one line per committed page in
      `cairn/references/`; `python3 .../cairn_validate.py` passes with no new
      warnings attributable to this milestone.
- [ ] AC7: The profile `verify` slot is clean — `NOT_CRAN=true CI=true` test
      run with failed + error summing to 0 (this milestone touches two test
      files' comments only, but the slot is non-negotiable).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T1
- AC6 → T6
- AC7 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Citekey reconciliation pass over `cairn/references/pdf/` — confirm each
      filename against the PDF's own title page, rename `hove2025.pdf`, and
      record the Jorgensen 2021 gap. Ask the maintainer for the missing PDF;
      do not substitute a secondary description (validation-doctrine
      primary-sources hard stop).
- [ ] T2: Mechanical split of `REFERENCES.md` → `ORACLES.md` (registry, its
      preamble adapted) + `BIBLIOGRAPHY.md`; verify by concatenation-diff that
      nothing but the headers changed, then `git rm` the original.
- [ ] T3: Update the ~13 live cross-references (`CLAUDE.md`,
      `cairn/DESIGN.md`, `cairn/PRINCIPLES.md`, `cairn/ROADMAP.md`, the six
      `cairn/estimand-specs/*.md`, `data-raw/README.md:5,75`,
      `tests/testthat/test-icc-anova-oracle.R:2`,
      `tests/testthat/test-vignette-claims.R:8`) — pointing registry mentions
      at `ORACLES.md` and bibliography mentions at `BIBLIOGRAPHY.md`.
- [ ] T4: Add the DESIGN.md Conventions registry-pointer line; strike the
      resolved Known-issues bullet.
- [ ] T5: Append the D-entry (adoption + D-024 reconciliation).
- [ ] T6: Rebuild `INDEX.md` for the new page set; run `cairn_validate`.
- [ ] T7: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the "REFERENCES.md →
  cairn-style split" candidate; plan gate: maintainer superseded the candidate's
  "sequence after M48" note — `cairn/` is not in the R package build, so this
  touches no release surface).
- 2026-07-18: implement gate — citekeys `tenhove2025a` (network data, MBR 60(3))
  / `tenhove2025b` (planned incomplete, MBR 60(5)), letter suffixes ordered by
  issue; AC1+AC2 amended (gated) to retain a ≤6-line `REFERENCES.md` pointer
  stub so the deliberately un-edited entombed links still resolve.
- 2026-07-18: minor amendment to M64/T2 (renaming `tenhove2025` →
  `tenhove2025b` churns a citekey its plan names).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
