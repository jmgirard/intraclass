<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M68: References provenance backfill + shelf rename to `sources/`

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; no DESIGN.md IP/GP — the governing principles are PRINCIPLES.md #4 (no fabricated reference values) and #12 (seeded and sourced), the other home under D-001 -->
- **Branch/PR:** `m68-references-provenance` · https://github.com/jmgirard/intraclass/pull/72   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: All 24 pages carry a `**Provenance.**` block naming an ingested date,
      a source pointer, a pagination basis, and an `Extraction:` status;
      `cairn_validate`'s `references index<->disk` check PASSes.
- [x] AC2: Every ingested date and ingesting milestone is derived from evidence,
      not asserted — the work log names the derivation command and records the
      complete page→(date, milestone) mapping, grouped by ingesting milestone
      and readable as one-line work-log entries (#4 applied to provenance).
- [x] AC3: Pagination basis is stated per page, and the three shelf PDFs that
      are not the version of record — `tenhove2022`, `tenhove2024`
      (advance-online), `tenhove2020` (author manuscript) — each say so in their
      block, consistent with `INDEX.md` and the M64 lesson.
- [x] AC4: No page claims a verification this milestone did not perform, and
      every `Extraction:` status is honest about what was and was not read.
      Each status sits on one physical line and carries its own
      `— observed YYYY-MM-DD` stamp. The form a page uses (`unverified —`,
      `derived —`, `first-hand record —`) follows from that page's actual
      situation and is never assigned in advance — a criterion that fixes the
      form breaks whenever a fact is corrected, which is backwards.
- [x] AC5: `cairn/references/sources/` replaces `pdf/` — directory, `.gitignore`,
      `INDEX.md`, `LESSONS.md`, and all 19 note pointers; no live file names
      `references/pdf/` outside the never-edited archives (`cairn/legacy/`,
      `milestones/archive/`, `reviews/archive/`), and the `scaffold
      deprecations` advisory clears.
- [x] AC6: M66 and M67 each carry a gated amendment requiring a conforming
      provenance block on every note they author and naming the `sources/` path,
      each with its own work-log line.
- [x] AC7: `cairn_validate` exits 0, and the profile `verify` slot is clean
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
- 2026-07-18: PR #72 opened; CI at checkpoint time — format-check, lint, pkgdown all success; the six platform/coverage jobs still in_progress after a ~9 min blocking wait, so nothing is left watching (re-derive with `gh api repos/jmgirard/intraclass/commits/<sha>/check-runs`, per the stateless-resume rule).
- 2026-07-18: REVIEW SEND-BACK (1st) — two criteria fail as written, no charitable reading applied. AC4 says every Extraction status "reads unverified-first-pass"; 5 of 24 pages correctly read `derived —`/`first-hand record —` (no shelf source to re-read, per the synthesis template) — its substantive clause (no page claims an unperformed verification) DOES hold, 0/24. AC2 requires the work log to "show the derived page→(date, milestone) table"; the command and full mapping are recorded but as a one-line grouped entry, because work-log entries must be one physical line — a one-line entry cannot literally be a table. Both are plan-time drafting errors (criteria assuming a format the rules forbid, and assuming every page is shelf-ingested). Evidence for AC1/AC3/AC5/AC6 and cairn_validate exit 0 all clean. Back to in-progress for a gated amendment.
- 2026-07-18: gated amendment (user approved at the send-back chip) — AC2 now asks for the derivation command plus the complete page→(date, milestone) mapping grouped by milestone and readable as one-line entries (was: a "table", which the one-line work-log rule forbids); AC4 now leads with the substantive protection (no unperformed verification claimed) and states both legitimate status forms — unverified-first-pass for the 19 shelf notes, `derived —`/`first-hand record —` for the 5 with no shelf source. No deliverable changed; no file on the branch differs. Status → review for a fresh pass.
- 2026-07-18: REVIEW SEND-BACK (2nd) — the three actioned review fixes (F1 BIBLIOGRAPHY, F2 sem-multilevel-pilot, F3 ORACLES) changed what is true about two pages, so AC4's enumeration clause is false again: ORACLES and BIBLIOGRAPHY now correctly read `unverified —`, not `derived —`. Substantive clauses still hold (0/24 claim a verification; 24/24 one-line dated). Same drafting error as round 1 — the criterion specifies the SURFACE FORM a status must take instead of the PROPERTY it must have, so it breaks every time a fact is corrected. Amending to specify honesty + format and to stop pre-assigning forms.
- 2026-07-18: gated amendment 2 (user approved at the 2nd send-back chip) — AC4 now specifies the PROPERTY (no unperformed verification claimed; honest about what was read; one physical line; dated) and explicitly refuses to pre-assign a status form, so correcting a fact can no longer falsify it. Root cause of both send-backs recorded. Status → review, round 3.
- 2026-07-18: CORRECTION to the T6 line above — it recorded `references staleness` WARNing on "exactly 20 pages". After review finding F3 made ORACLES.md's extraction status honest, the count is **21** (the 19 shelf notes + BIBLIOGRAPHY + ORACLES). The 20 was correct when written and is superseded, not edited (D-045).
- 2026-07-18: CI at the merge gate — format-check, lint, pkgdown, macos-latest (release) success; test-coverage + the four remaining platform jobs still in_progress after a ~10 min blocking wait, so nothing is left watching. Green CI is required at merge, not at approval.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Round 3.** Round 1 sent back on AC2/AC4 wording; round 2 sent back on AC4
again after the actioned findings corrected two pages. Both send-backs were the
same plan-time drafting error — criteria specifying a surface FORM rather than
the PROPERTY — now fixed at the root in AC4.

### Acceptance-criteria evidence (fresh, by command, 2026-07-18)

- **AC1** — 24/24 pages carry `**Provenance.**` with an ISO ingested date, source pointer, `Pagination:`, `Extraction:`; `references index<->disk` PASSes.
- **AC2** — work log names the derivation command and the complete mapping, six groups summing to 24. Independently re-derived by the [O] reviewer, who confirmed all 24 including the two that only resolve correctly *without* `--follow` (ORACLES/BIBLIOGRAPHY) and REFERENCES, where `--follow` would wrongly report 2026-07-06/M0.
- **AC3** — 24/24 carry `Pagination:`; the three non-version-of-record PDFs carry explicit conversion warnings. [O] reviewer cross-checked every page's anchor range against its stated basis (tenhove2020 anchors 1–13 ⊂ 1–14; tenhove2022 1–15 ⊂ 1–17; tenhove2024 1–13; saha2012 zero page anchors; bobak2018 3–10, incompatible with `18:93` as a page).
- **AC4** — 0/24 claim a verification; 24/24 statuses are one physical line ending `— observed 2026-07-18.`; each form matches its page's real situation after findings F1/F3 corrected two of them.
- **AC5** — 0 live dangles; `.gitignore:12` names `sources/`; all 30 PDFs present under `sources/`; `scaffold deprecations` OK. All 19 pointer folds read by hand and by two reviewers — no prose damaged.
- **AC6** — M66/M67 each name `references/sources/`, each require a provenance block in AC1, each carry a dated amendment work-log line. [S] blame reviewer confirmed both were still `planned`, so nothing was overridden mid-implementation.
- **AC7** — `cairn_validate` exit 0, 15/15 PASS; `verify` slot 1802 pass, 0 fail, 0 error. `cairn/` is `.Rbuildignore`d and the review fixes touched only cairn markdown, so the R-side evidence is unaffected by them.

### Consistency gate

- Universal: `cairn_validate` exit 0. No DESIGN.md principle changed → `cairn_impact` skipped.
- Toolchain (`r-package` `consistency-gate`): 0 R/NAMESPACE/man/data/DESCRIPTION/README files in the diff; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; README current; no user-visible change so no NEWS entry owed; `devtools::check()` **0 errors, 0 warnings, 0 notes**.

### Independent review — three lenses + scorer

- **[O] diff-bug (Opus):** 3 findings, all verified against git before triage.
- **[S] blame-history (Sonnet):** no findings. D-007's byte-identical property intact; M64/M65 pagination traps faithfully restated; LESSONS.md corrected in place per the corrections rule; amend-via-gate used correctly for M66/M67; no IP4 archive touched.
- **[S] prior-PR-comments (Sonnet):** no findings. Method note worth keeping: PRs #69/#70/#71 carry **zero** GitHub inline review comments — this repo's review record lives in `LESSONS.md` and archived milestone `## Review` sections, which is where this lens must look.
- **[S] scorer (Sonnet), fresh agent:** F1 = 92, F2 = 85, F3 = 74.

**Actioned — F1 (92), BIBLIOGRAPHY.md provenance factually wrong.** Claimed citations were carried over unchanged at the D-007 split and never re-checked. Git: 16 entries at the split, 18 after M64, 27 after M65, with corrections to survivors (mcgraw1996 errata, tenhove2024 DOI). **Fixed** — block records the real three-milestone history and an extraction status splitting the 16 moved-as-text entries from the 11 authored from PDFs.

**Actioned — F2 (85), sem-multilevel-pilot.md anachronistic inputs.** Named `tenhove2022.md`/`jorgensen2021.md` as inputs to a 2026-07-16 ingestion; M64 created both on 2026-07-18. **Fixed** — block now names the *papers* and states the page is not downstream of those notes.

**Actioned — F3 (74), ORACLES.md claimed an unperformed read.** "none re-read since 2026-07-18" implied a read D-007 says never happened (the split moved text byte-identically), and that wording let the registry escape the staleness WARN its twin correctly received. **Actioned despite scoring below 80:** the scorer's 74 rested solely on being unable to verify the author's intent from git (the pre-commit draft was never committed); the author confirms the wording was changed to silence a validator message, and the defect stands on D-007 alone without that claim. **Fixed** — staleness list correctly goes 20 → 21.

No finding was excluded or dropped. Two lenses reported clean.

