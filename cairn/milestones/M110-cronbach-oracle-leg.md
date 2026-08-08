# M110: Close the Cronbach (1972) leg of the O-Bayes-Rep co-citation

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1
- **Branch/PR:** —

## Goal

Acquire Cronbach, Gleser, Nanda & Rajaratnam (1972) onto the source shelf and
verify the last outstanding Source-leg row in `ORACLES.md` — the Cronbach half
of the O-Bayes-Rep two-facet-decomposition co-citation, whose Brennan half M72
closed against Ch. 3.

## Scope

**In:** shelf ingestion of the maintainer-supplied whole book; a new
`BIBLIOGRAPHY.md` entry; the `INDEX.md` arrival record plus a full-file
re-read correcting what the arrival falsifies; the `ORACLES.md` Source-leg
row, pagination-basis paragraph, O-Bayes-Rep Sources bullet, and `Extraction:`
header; the repo-wide Cronbach consistency sweep and the three
`check-references` checkers.

**Out:** a `cronbach1972.md` source note — declined at the plan gate
(2026-08-08), following the M72 verification-only precedent
(`brennan2001_ch3`/`lee2024a`/`vispoel2022b` carry none); promote only if a
later milestone takes a dependency on Cronbach extractions beyond this leg.
Oracle-script re-runs → shipped at M107–M109. Package code, tests, or any
runtime surface → nothing here touches one, so no testthat scope; the three
checkers and `cairn_validate` are the mechanical gate.

## Acceptance criteria

- [ ] AC1: `cronbach1972` — Cronbach, Gleser, Nanda & Rajaratnam (1972), *The
      Dependability of Behavioral Measurements*, supplied whole — is on the
      `cairn/references/sources/` shelf, its identity verified against its own
      title page (a gitignored working-copy fact: review evidence is a local
      observation, D-009's `check: none` disposition); `BIBLIOGRAPHY.md`
      carries a new Cronbach et al. (1972) entry whose bibliographic fields
      are verified against the book itself and which records supplier and
      date; and `INDEX.md`'s shelf inventory records the arrival, mirroring
      the `burch2011`/M72 arrival paragraphs. No `cronbach1972.md` source note
      appears in this milestone's diff (gate decision 2026-08-08).
- [ ] AC2: the `ORACLES.md` Source-leg table's Cronbach et al. (1972) row
      carries a dated verification outcome with a page anchor and a stated
      pagination basis: `verified`, citing the passage in the source's own
      design taxonomy that supports the co-citation — the
      replicates-within-cell `i:(p×o)` design O-Bayes-Rep fits where the
      source presents it, otherwise the crossed two-facet decomposition or the
      closest form the source states, the row saying which passage and form
      was found — or, where the reading falsifies or cannot support the
      co-citation, the implicated entries corrected in place with the
      correction cited (D-008's posture), never a softened status.
- [ ] AC3: the O-Bayes-Rep registry entry's Sources bullet replaces "Cronbach
      et al. (1972) is still off the shelf, so that half of the co-citation
      remains unverified" with the dated reading outcome and its citation (the
      supporting passage's anchor in the verified branch, the cited correction
      otherwise), and the `ORACLES.md` `Extraction:` header no longer
      describes an outstanding Source-leg row.
- [ ] AC4: the consistency sweep passes: every hit of `git grep -in -i
      cronbach` over the committed tree is re-read and left consistent with
      the closed leg (for history files — `milestones/archive/`, work logs —
      "consistent" means the text does not assert the leg is open *now*;
      history is never edited); the whole of `INDEX.md` is re-read with every
      claim the arrival falsifies corrected and its dated observations
      re-dated where touched (the full-file re-read is the enumerating
      procedure); and `python3 data-raw/check-reference-observations.py`,
      `python3 data-raw/enumerate-generalizing-claims.py --check`, and
      `python3 data-raw/check-mpl-doc-claims.py` all exit 0 locally.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2
- AC3 → T2
- AC4 → T3, T4

## Tasks

- [ ] T1: Ingest the maintainer-supplied book: place it on the shelf as
      `cronbach1972.pdf`, verify identity against its own title page, state
      the pagination basis, and locate the two-facet decomposition passage(s)
      in the source's design taxonomy — reading to the end of the relevant
      material before any absence claim (LESSONS 2026-07-18/M65). If the file
      has not arrived at implement start, park the milestone `blocked`.
- [ ] T2: Close the leg in `ORACLES.md`: the Source-leg row (line 57), the
      pagination-basis paragraph (lines 59–69), the O-Bayes-Rep Sources
      bullet (~line 1233), and the `Extraction:` header (line 5) — then
      re-read every header that summarizes the table (LESSONS 2026-07-19/M72).
- [ ] T3: Record the arrival: the `BIBLIOGRAPHY.md` entry (fields verified
      against the book); the `INDEX.md` inventory paragraph plus the
      full-file re-read correcting every claim the arrival falsifies, its
      D-009 `check:` directives updated in lockstep.
- [ ] T4: Consistency sweep: re-read every `git grep -in -i cronbach` hit;
      grep this milestone's own new prose for bare counts and universals
      (LESSONS 2026-07-19/M72); run the three `data-raw` checkers to exit 0
      and `cairn_validate` clean.

## Work log

- 2026-08-08: created by /milestone-plan; scope set at the gate — whole book to be supplied by the maintainer; no source note (M72 precedent).
- 2026-08-08: criteria audit ([O] fresh reader) ran twice — pass 1 returned 8 findings (6 fixed in the AC wording, 2 routed to the gate); the post-gate re-audit returned 2 minor wording fixes (branch exhaustiveness on AC2, citation asymmetry on AC3), both applied, and noted AC1/AC4 must ship together (held by the Coverage map).
- 2026-08-08: plan gate chose the no-note M72 precedent over a full `cronbach1972.md` source note because the ask is one co-citation leg and the sibling half (`brennan2001_ch3`) is recorded the same way; falsified by the repo taking a dependency on Cronbach extractions beyond this leg, which would owe the note.
- 2026-08-08: plan chose a procedure-enumerated sweep (the named `git grep` plus a full `INDEX.md` re-read) over a hand-list of known stale sites because a hand-list ships every site it omits stale; falsified by a stale Cronbach claim surviving the sweep on a surface neither procedure enumerates.

## Decisions
