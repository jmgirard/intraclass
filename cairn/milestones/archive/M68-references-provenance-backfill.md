# M68: References provenance backfill + shelf rename to `sources/` (done 2026-07-18)

**Goal.** Give every committed `cairn/references/` page a conforming
`**Provenance.**` block and rename the shelf `pdf/` → `sources/`, turning
`cairn_validate` green before M48's consistency gate depends on it.

**Outcome.** All 24 pages carry an ingested date, source pointer, pagination
basis, and dated `Extraction:` status; `cairn_validate` went from a failing
`references index<->disk` check to 15/15 PASS. Shelf renamed across the
directory, `.gitignore`, `INDEX.md`, `LESSONS.md`, and 19 note pointers.
M66/M67 amended at the gate so the 11 notes they author cannot reopen the gap.
Docs/tracking only. The milestone re-read nothing: 21 standing `references
staleness` advisories are the deliverable, not debt (M69 clears the load-bearing
ten; nine → candidate). Facts derived, not asserted (#4) — dates from
`git log --diff-filter=A` *without* `--follow`; pagination basis from each note's
own callout or its anchor range cross-checked against its citation.

**Review.** Two send-backs, both on criteria specifying a surface *form* rather
than the *property* (AC2; AC4 twice) — fixed at the root. Three findings actioned,
all asserting a provenance fact instead of deriving it: BIBLIOGRAPHY's post-split
history (16→18→27 entries, not "unchanged"); sem-multilevel-pilot naming input
notes postdating its own ingestion by two days; ORACLES claiming a read D-007 says
never happened, which had hidden it from the staleness WARN. F3 scored 74, actioned
anyway. Other two lenses clean. Evidence: 15/15 · `check()` 0/0/0 · `verify` 1802
pass, 0 fail · CI green, 5 platforms. PR: https://github.com/jmgirard/intraclass/pull/72
