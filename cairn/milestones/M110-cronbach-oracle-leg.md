# M110: Close the Cronbach (1972) leg of the O-Bayes-Rep co-citation

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1
- **Branch/PR:** `m110-cronbach-oracle-leg` · [PR #119](https://github.com/jmgirard/intraclass/pull/119)

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

- [x] AC1: `cronbach1972` — Cronbach, Gleser, Nanda & Rajaratnam (1972), *The
      Dependability of Behavioral Measurements*, supplied whole — is on the
      `cairn/references/sources/` shelf, its identity verified against its own
      title page (a gitignored working-copy fact: review evidence is a local
      observation, D-009's `check: none` disposition); `BIBLIOGRAPHY.md`
      carries a new Cronbach et al. (1972) entry whose bibliographic fields
      are verified against the book itself and which records supplier and
      date; and `INDEX.md`'s shelf inventory records the arrival, mirroring
      the `burch2011`/M72 arrival paragraphs. No `cronbach1972.md` source note
      appears in this milestone's diff (gate decision 2026-08-08).
- [x] AC2: the `ORACLES.md` Source-leg table's Cronbach et al. (1972) row
      carries a dated verification outcome with a page anchor and a stated
      pagination basis: `verified`, citing the passage in the source's own
      design taxonomy that supports the co-citation — the
      replicates-within-cell `i:(p×o)` design O-Bayes-Rep fits where the
      source presents it, otherwise the crossed two-facet decomposition or the
      closest form the source states, the row saying which passage and form
      was found — or, where the reading falsifies or cannot support the
      co-citation, the implicated entries corrected in place with the
      correction cited (D-008's posture), never a softened status.
- [x] AC3: the O-Bayes-Rep registry entry's Sources bullet replaces "Cronbach
      et al. (1972) is still off the shelf, so that half of the co-citation
      remains unverified" with the dated reading outcome and its citation (the
      supporting passage's anchor in the verified branch, the cited correction
      otherwise), and the `ORACLES.md` `Extraction:` header no longer
      describes an outstanding Source-leg row.
- [x] AC4: the consistency sweep passes: every hit of `git grep -in -i
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

- [x] T1: Ingest the maintainer-supplied book: place it on the shelf as
      `cronbach1972.pdf`, verify identity against its own title page, state
      the pagination basis, and locate the two-facet decomposition passage(s)
      in the source's design taxonomy — reading to the end of the relevant
      material before any absence claim (LESSONS 2026-07-18/M65). If the file
      has not arrived at implement start, park the milestone `blocked`.
- [x] T2: Close the leg in `ORACLES.md`: the Source-leg row (line 57), the
      pagination-basis paragraph (lines 59–69), the O-Bayes-Rep Sources
      bullet (~line 1233), and the `Extraction:` header (line 5) — then
      re-read every header that summarizes the table (LESSONS 2026-07-19/M72).
- [x] T3: Record the arrival: the `BIBLIOGRAPHY.md` entry (fields verified
      against the book); the `INDEX.md` inventory paragraph plus the
      full-file re-read correcting every claim the arrival falsifies, its
      D-009 `check:` directives updated in lockstep.
- [x] T4: Consistency sweep: re-read every `git grep -in -i cronbach` hit;
      grep this milestone's own new prose for bare counts and universals
      (LESSONS 2026-07-19/M72); run the three `data-raw` checkers to exit 0
      and `cairn_validate` clean.

## Work log

- 2026-08-08: created by /milestone-plan; scope set at the gate — whole book to be supplied by the maintainer; no source note (M72 precedent).
- 2026-08-08: criteria audit ([O] fresh reader) ran twice — pass 1 returned 8 findings (6 fixed in the AC wording, 2 routed to the gate); the post-gate re-audit returned 2 minor wording fixes (branch exhaustiveness on AC2, citation asymmetry on AC3), both applied, and noted AC1/AC4 must ship together (held by the Coverage map).
- 2026-08-08: plan gate chose the no-note M72 precedent over a full `cronbach1972.md` source note because the ask is one co-citation leg and the sibling half (`brennan2001_ch3`) is recorded the same way; falsified by the repo taking a dependency on Cronbach extractions beyond this leg, which would owe the note.
- 2026-08-08: plan chose a procedure-enumerated sweep (the named `git grep` plus a full `INDEX.md` re-read) over a hand-list of known stale sites because a hand-list ships every site it omits stale; falsified by a stale Cronbach claim surviving the sweep on a surface neither procedure enumerates.
- 2026-08-08: /milestone-implement start — `cronbach1972.pdf` found already on the shelf (ctime 2026-08-08 10:44, supplied during this session; mtime Jul 19 is the copy's preserved original — the M63 ctime check); no blocker, branch `m110-cronbach-oracle-leg` cut. Question gate skipped: the plan gate settled both open choices, no RB tripwires tagged.
- 2026-08-08: T1 done — identity verified against the title/copyright pages (Wiley 1972, all four authors, ISBN 0-471-18850-6; whole-book library scan); pagination basis PDF = printed + 20; leg closes on the AC2 verified branch's stronger arm — Design IV-A `j:(i × p)` (Fig. 2.4 p. 38, Table 2.1 p. 40, Lord–Novick "replications" reading p. 42) is Brennan's `i:(p × o)`, plus the crossed Eq. (1.3) p. 28.
- 2026-08-08: T2 done — ORACLES.md Source-leg row, pagination-basis note, O-Bayes-Rep Sources bullet, and Extraction header all updated; header sweep (grep outstanding/off-shelf/Source-leg) found no other summary asserting the leg open (line 34 is the standing off-shelf rule, kept).
- 2026-08-08: T3 done — BIBLIOGRAPHY.md gains the Cronbach entry (fields against the book's own title/copyright pages); INDEX.md full-file re-read: corrected 38→39 entries (a stale count the grep would have missed — the AC4 full-read procedure earning its keep), 34→35 PDFs, three→four note-less members, the closed-leg sentence, an M110 arrival paragraph with its own check directive, and the note-less check directive extended to cronbach1972.md.
- 2026-08-08: T4 done — every grep hit re-read (archive/data-raw hits are then-state or alpha-1951, none assert the leg open); the new "every row verified" universal confirmed against the table (19 verified rows, no unverified); check-reference-observations 0 falsified, mpl-doc-claims OK; the new ORACLES row tripped the generalizing-claims gate exactly as LESSONS/M85 predicts — triaged OUT-quote — then --check green; cairn_validate all checks passed. Profile verify slot (testthat) not run per the plan's Out: no runtime surface in the diff; review's consistency gate covers toolchain checks.
- 2026-08-08: all tasks done → status review; checkpoint pushed.

## Decisions

## Review

Evidence gathered fresh at review, 2026-08-08, PR #119.

- AC1: `cronbach1972.pdf` present on the shelf (7,621,153 bytes, local observation per the criterion's D-009 `check: none` disposition), identity read against its title/copyright pages this session (Wiley 1972, four authors, ISBN 0-471-18850-6); `grep` finds the new Cronbach BIBLIOGRAPHY entry (1 hit) and the INDEX "One arrival during M110" paragraph (1 hit); `git diff --name-only main..HEAD` lists 6 files, no `cronbach1972.md`.
- AC2: ORACLES.md:57 is the verified branch — Design IV-A `j:(i × p)` named as the replicates-within-cell design (which passage and form: stated in the row), anchors `printed pp. 38/40/42 · 28`, status `verified — observed 2026-08-08 (M110)`; the pagination-basis paragraph (line ~69) states the whole-book-scan basis and the +20 offset.
- AC3: the replaced sentence ("still off the shelf") greps 0 hits in ORACLES.md; the Sources bullet (line 1235) opens "**Cronbach et al. (1972) verified against the whole book 2026-08-08 (M110)**" with the Fig. 2.4/Table 2.1/p. 42/Eq. (1.3) anchors; the Extraction header now reads "closed at **M110 (2026-08-08)**" and describes no outstanding row.
- AC4: fresh runs — check-reference-observations.py: 0 unmarked, 0 falsified; enumerate-generalizing-claims.py --check: in sync (295/295); check-mpl-doc-claims.py: OK, 0 failures; `git grep -il cronbach` = 12 committed files, all re-read at T4 (work log), history files assert only then-state.

Consistency gate: `cairn_validate` exit 0 (all checks pass); no principle changed → `cairn_impact` skipped. Toolchain slot: `document()` no diff; diff touches no generated files (`NAMESPACE`/`man/`/`data/` absent from the 6-file diff); README/pkgdown unaffected, `check_pkgdown()` no problems; NEWS — no user-visible change (references-only diff), no entry owed; no new top-level files; `devtools::check(NOT_CRAN=false)` run at review (result recorded below).
