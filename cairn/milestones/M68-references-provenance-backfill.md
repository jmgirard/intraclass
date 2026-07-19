<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M68: References provenance backfill + shelf rename to `sources/`

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; no DESIGN.md IP/GP — the governing principles are PRINCIPLES.md #4 (no fabricated reference values) and #12 (seeded and sourced), the other home under D-001 -->
- **Branch/PR:** `m68-references-provenance`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Give every committed `cairn/references/` page a conforming `**Provenance.**`
block and rename the shelf from `pdf/` to `sources/`, turning `cairn_validate`
green before M48's consistency gate depends on it.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a `**Provenance.**` block — ingested date, source pointer, pagination
basis, dated `Extraction:` status — on all 24 committed pages: the 19 shelf-
ingested notes, the 2 derived synthesis notes (`sem-multilevel-pilot`,
`npbootstrap-oneway-comparison`), and the 3 registry/infra pages (`ORACLES.md`,
whose existing block names neither date nor pointer; `BIBLIOGRAPHY.md`;
`REFERENCES.md`). Blocks are authored from
`skills/shared/templates/source-note.md` and `templates/synthesis-note.md`.
Every date and ingesting milestone is **derived** — `git log --diff-filter=A`
on the page, plus `INDEX.md`'s per-page record — never invented (#4). Also: the
`pdf/` → `sources/` rename across the directory, `.gitignore`, `INDEX.md`,
`LESSONS.md`, the 19 note pointers, and M66/M67's Scope lines; and a gated
amendment to M66/M67 requiring provenance blocks on the 11 notes they author.

**Out:** re-reading any extraction against its source — the load-bearing ten →
M69, the other nine → a ROADMAP candidate row; this milestone records extraction
status honestly as unverified and never claims a check it did not perform.
Authoring new notes → M66/M67. Any correction to a *value* → M69, since finding
one requires the re-read this milestone excludes. Changing the provenance shape
itself (a cairn-upstream question) → out entirely; this repo conforms.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: All 24 pages carry a `**Provenance.**` block naming an ingested date,
      a source pointer, a pagination basis, and an `Extraction:` status;
      `cairn_validate`'s `references index<->disk` check PASSes.
- [ ] AC2: Every ingested date and ingesting milestone is derived from evidence,
      not asserted — the work log names the command and shows the derived
      page→(date, milestone) table (#4 applied to provenance).
- [ ] AC3: Pagination basis is stated per page, and the three shelf PDFs that
      are not the version of record — `tenhove2022`, `tenhove2024`
      (advance-online), `tenhove2020` (author manuscript) — each say so in their
      block, consistent with `INDEX.md` and the M64 lesson.
- [ ] AC4: Every `Extraction:` status reads unverified-first-pass and carries
      its own `— observed YYYY-MM-DD` stamp on one physical line; no page claims
      a verification this milestone did not perform.
- [ ] AC5: `cairn/references/sources/` replaces `pdf/` — directory, `.gitignore`,
      `INDEX.md`, `LESSONS.md`, and all 19 note pointers; no live file names
      `references/pdf/` outside the never-edited archives (`cairn/legacy/`,
      `milestones/archive/`, `reviews/archive/`), and the `scaffold
      deprecations` advisory clears.
- [ ] AC6: M66 and M67 each carry a gated amendment requiring a conforming
      provenance block on every note they author and naming the `sources/` path,
      each with its own work-log line.
- [ ] AC7: `cairn_validate` exits 0, and the profile `verify` slot is clean
      (`NOT_CRAN=true CI=true`, failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T3, T4, T5
- AC2 → T2, T3, T4, T5
- AC3 → T2
- AC4 → T2, T3, T4, T5
- AC5 → T1
- AC6 → T1
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Rename the shelf. `mv cairn/references/pdf cairn/references/sources`
      (gitignored, so no `git mv`); update `.gitignore:12`, `INDEX.md:97`,
      `LESSONS.md:44` (in-place correction, marked per the corrections rule),
      and the Scope lines at `M66-source-notes-foundational.md:21` and
      `M67-source-notes-equality-testing.md:21` — the latter two as gated
      amendments that also add the provenance requirement (AC6).
- [x] T2: Provenance blocks on M64's ten load-bearing notes (`fleiss1973`,
      `jorgensen2021`, `koo2016`, `mcgraw1996`, `shrout1979`, `tenhove2020`,
      `tenhove2022`, `tenhove2024`, `tenhove2025a`, `tenhove2025b`), folding each
      existing `PDF: …` prose line into the block and carrying the three
      pagination-basis callouts.
- [x] T3: Provenance blocks on M65's seven notes (`bhandary2006`, `bobak2018`,
      `mehta2018`, `saha2005`, `saha2012`, `xiao2009`, `xiao2013`).
- [x] T4: Provenance blocks on the M62/M53 pages — `ukoumunne2003`,
      `ohyama2025` (shelf pointers); `npbootstrap-oneway-comparison`,
      `sem-multilevel-pilot` (synthesis: derivation pointer, `Pagination: —`).
- [x] T5: Provenance blocks on the three registry/infra pages — repair
      `ORACLES.md`'s existing block (add ingested date, source pointer,
      extraction status), and author `BIBLIOGRAPHY.md`'s and `REFERENCES.md`'s,
      all derived from M63's split of the pre-migration `REFERENCES.md`.
- [x] T6: Run `cairn_validate` to exit 0; confirm `references staleness` WARNs
      for exactly the pages left unverified and nothing else; run the profile
      `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan, from the /milestone audit's `references index<->disk` FAIL; gate chose honest-unverified extraction status, absorbing the `sources/` rename, and amending M66/M67; the load-bearing-ten re-verification split off as M69.
- 2026-07-18: T1 done — shelf renamed `pdf/`→`sources/` (30 PDFs), `.gitignore`, `INDEX.md`, `LESSONS.md` (in-place path correction) and all 19 note pointers updated; M66/M67 amended (Scope path + AC1 provenance requirement), each with its own work-log line.
- 2026-07-18: minor amendment — AC5 named only `legacy/` and `milestones/archive/` as exempt archives; `reviews/archive/RB01` also cites the old path and is equally never-edited (IP4), so the exemption now names all three. No deliverable changed.
- 2026-07-18: T2–T5 done — Provenance blocks on all 24 pages. Dates/milestones DERIVED with `git log --diff-filter=A --format='%ad|%s' --date=short -- <page>`, never asserted: cairn-init/2026-07-12 → REFERENCES; M53/2026-07-16 → sem-multilevel-pilot; M62/2026-07-18 → ukoumunne2003, ohyama2025, npbootstrap-oneway-comparison; M63/2026-07-18 → ORACLES, BIBLIOGRAPHY; M64/2026-07-18 → the ten load-bearing; M65/2026-07-18 → the seven interval-methods.
- 2026-07-18: pagination basis derived per page from the note's own callout where it had one, else its anchor range cross-checked against its printed citation — four non-standard: tenhove2020 (manuscript pp. 1–14, not Springer 79–93), tenhove2022 (AOP pp. 1–17), tenhove2024 (AOP pp. 1–13), saha2012 (Early View, no folios at all — anchors are section/equation/table only). bobak2018 is BMC per-article pagination (`18:93` is an article number).
- 2026-07-18: finding — ORACLES.md had NO provenance block; what cairn_validate matched was a false positive, a hard-wrapped prose line inside oracle O1 beginning with the word "provenance" (ORACLES.md:36). Real block added and the decoy line rewrapped.
- 2026-07-18: each source note's existing `PDF: …` prose pointer folded into its block rather than duplicated; every seam re-read by hand (the pointer sat mid-sentence or line-wrapped in 8 of 19).
- 2026-07-18: cairn_validate exit 0, all 15 checks PASS (references index<->disk and scaffold deprecations both clear). `references staleness` now WARNs on exactly 20 pages — the 19 shelf notes + BIBLIOGRAPHY, all "no verified re-check" — which is AC4's intended honest signal; M69 clears ten of them.
- 2026-07-18: T6 in flight — cairn_validate already exit 0 (15/15 PASS); the profile `verify` slot is running in the background at checkpoint time, so T6 stays unchecked until its result is recorded.
- 2026-07-18: T6 done — profile `verify` slot clean: 1802 pass, 0 fail, 0 error, 23 skip, 2 warn (both pre-existing engine conditions — a glmmTMB non-positive-definite Hessian inside the test that asserts that message, and the Design-3 drop message; this branch touches no R file). cairn_validate exit 0, 15/15 PASS. All tasks done; status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
