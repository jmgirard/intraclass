<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M63: References migration — ORACLES.md + BIBLIOGRAPHY.md, citekey reconciliation

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m63-references-migration` / https://github.com/jmgirard/intraclass/pull/69   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Convert `cairn/references/` from the single pre-migration `REFERENCES.md` to the
cairn file family — a declared oracle registry, a bibliography, and a reconciled
citekey namespace — without changing any oracle value.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** split `REFERENCES.md` (1346 lines) into `ORACLES.md` (the ~40-entry
registry, lines 1–1277) and `BIBLIOGRAPHY.md` (lines 1278–1346), reducing
`REFERENCES.md` to a pointer stub (gated amendment, implement gate 2026-07-18 —
originally "retire the name"); update the ~13 live cross-referencing files; add the
validation-doctrine **registry-pointer** line to `DESIGN.md` Conventions and
close the `DESIGN.md:205` Known-issues wart; a D-entry adopting `ORACLES.md`
(reconciling the open cairn-side D-024 question); reconcile the `pdf/` citekey
namespace against actual PDF content (`hove2025` is misnamed); rebuild
`INDEX.md` incl. the 30-PDF shelf inventory.

**Out:** writing any `<citekey>.md` source note → M64 (load-bearing sources),
M65 (interval-methods cluster), and the tier-C candidate row; re-reading any
PDF for extraction → same; editing `cairn/legacy/**` or
`CLAUDE_CODE_KICKOFF.md` (entombed/founding documents, kept verbatim — their
`REFERENCES.md` mentions are historical record, not stale links).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `ORACLES.md` + `BIBLIOGRAPHY.md` exist; `REFERENCES.md` is reduced to
      a ≤6-line pointer stub naming both successors and the adopting D-entry
      (retained so the deliberately un-edited entombed links still resolve —
      implement gate 2026-07-18). Every oracle entry and bibliography entry
      appears in exactly one successor, with **no numeric value, `Status` line,
      or citation text altered** — verified by diffing the concatenated split
      against the original.
- [x] AC2: No live file *substantively* references `REFERENCES.md` as a content
      home: `grep -rn "REFERENCES.md" --include="*.R" --include="*.md" --include="*.Rmd" .`
      hits only `cairn/legacy/`, `CLAUDE_CODE_KICKOFF.md`, `data-raw/reviews/`,
      the stub, and the records documenting the migration (this file, D-007,
      the stub's `INDEX.md` line). The stale `project/REFERENCES.md` path at
      `tests/testthat/test-vignette-claims.R:8` is corrected too.
- [x] AC3: `cairn/DESIGN.md` Conventions carries a one-line oracle **registry
      pointer** naming `cairn/references/ORACLES.md`
      (validation-doctrine "Registry pointer"), and the "No cairn-canonical
      oracle-registry home yet" Known-issues bullet (`DESIGN.md:205`) is struck
      as resolved.
- [x] AC4: A D-entry in `cairn/DECISIONS.md` records the `ORACLES.md` adoption,
      the split rationale, and the reconciliation with the cairn-side D-024
      open question.
- [x] AC5: Citekey reconciliation recorded in the work log: `hove2025.pdf` →
      `tenhove2025a` (*Interdependent Social Network Data*, MBR 60(3):444–459,
      doi:10.1080/00273171.2024.2444940); the former `tenhove2025.pdf` →
      `tenhove2025b` (*Planned Incomplete Data*, MBR 60(5):1042–1061) — letter
      suffixes ordered by issue (implement gate 2026-07-18). All **30** PDFs in
      `pdf/` are enumerated with a citekey→paper mapping; in particular
      `jorgensen2019.pdf` (planned-missing efficiency, Springer proceedings)
      and `jorgensen2021.pdf` (*Psych* 3(2):113–133, the O-SEM absolute-error
      source) are recorded as the two distinct Jorgensen papers they are.
- [x] AC6: `INDEX.md` has exactly one line per committed page in
      `cairn/references/`; `python3 .../cairn_validate.py` passes with no new
      warnings attributable to this milestone.
- [x] AC7: The profile `verify` slot is clean — `NOT_CRAN=true CI=true` test
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

- [x] T1: Citekey reconciliation pass over `cairn/references/pdf/` — confirm
      every filename against the PDF's own title page, rename the misnamed
      ones, and record the full citekey→paper mapping for all 30 PDFs.
- [x] T2: Mechanical split of `REFERENCES.md` → `ORACLES.md` (registry, its
      preamble adapted) + `BIBLIOGRAPHY.md`; verify by concatenation-diff that
      nothing but the headers changed, then `git rm` the original.
- [x] T3: Update the ~13 live cross-references (`CLAUDE.md`,
      `cairn/DESIGN.md`, `cairn/PRINCIPLES.md`, `cairn/ROADMAP.md`, the six
      `cairn/estimand-specs/*.md`, `data-raw/README.md:5,75`,
      `tests/testthat/test-icc-anova-oracle.R:2`,
      `tests/testthat/test-vignette-claims.R:8`) — pointing registry mentions
      at `ORACLES.md` and bibliography mentions at `BIBLIOGRAPHY.md`.
- [x] T4: Add the DESIGN.md Conventions registry-pointer line; strike the
      resolved Known-issues bullet.
- [x] T5: Append the D-entry (adoption + D-024 reconciliation).
- [x] T6: Rebuild `INDEX.md` for the new page set; run `cairn_validate`.
- [x] T7: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the references-split
  candidate; plan gate superseded its "sequence after M48" note — `cairn/` is not
  in the R package build, so this touches no release surface).
- 2026-07-18: implement gate — citekeys `tenhove2025a`/`tenhove2025b` (letter
  suffixes by issue); AC1+AC2 amended (gated) to keep a ≤6-line stub so the
  entombed links resolve; M64/T2 minor amendment for the churned citekey.
- 2026-07-18: T1 (as run) — reported 29 PDFs checked, two DOI-confirmed renames,
  and an "open gap: Jorgensen 2021 has no PDF". **Superseded — see the correction
  below.**
- 2026-07-18: T2 — split content-preserving: both bodies byte-identical, 39
  oracle entries + 16 bibliography items before and after.
- 2026-07-18: T3–T6 — 12 cross-references retargeted; stale `project/` path fixed
  at `test-vignette-claims.R:8`; AC2 allowlist widened (gated); DESIGN.md pointer
  added + Known-issues bullet struck; D-007 appended; `INDEX.md` rebuilt.
- 2026-07-18: T7 — 1802 pass, 0 fail, 0 error, 23 skip (`NOT_CRAN=true CI=true`);
  `air`/`lintr` clean; PR #69 CI green (11 checks) after re-running the known
  `ubuntu-latest (devel)` `pak`-binary dep-install flake. PR opened via REST —
  `gh pr create` hit the GraphQL rate limit (M61 lesson).
- 2026-07-18: **T1 CORRECTION (review; supersedes the T1 entry above).** The
  directory holds **30** PDFs, not 29: `jorgensen2021.pdf` was missed, so the
  "no PDF" gap is **false** — it is present and is the *Psych* 3(2):113–133 O-SEM
  source. Caught by the diff-bug reviewer (scored 93); AC5 failed verification,
  was amended via gate, the phantom ROADMAP row dropped, M64 unblocked (9 → 10).
  The 30-PDF mapping now lives in `references/INDEX.md`.
- 2026-07-18: findings F3/F5 actioned at maintainer's direction despite scoring
  78/70 — `PRINCIPLES.md` #12 retargeted to `BIBLIOGRAPHY.md` (a citation
  obligation, not an oracle record); D-007 extended to cover it; `(#12, D-007)`
  added to the PRINCIPLES.md header exception list.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Verified 2026-07-18 (/milestone-review M63).**

- **AC1** — split verified against `origin/main:cairn/references/REFERENCES.md`
  (the original in git, not a working copy): all 39 `###` oracle entry bodies
  byte-identical, bibliography body byte-identical, 39→39 oracles, 16→16
  bibliography items, 14→14 `Status:` lines. Only deltas are structural (added
  H1/H2, dropped section-boundary `---`). Stub = 6 lines.
- **AC2** — allowlist grep returns nothing outside `cairn/legacy/`,
  `CLAUDE_CODE_KICKOFF.md`, `data-raw/reviews/`, the stub, `INDEX.md`, D-007,
  and this file. `project/REFERENCES.md` occurrences in the test: 0.
- **AC3** — `DESIGN.md:90` registry pointer present; `DESIGN.md:209` bullet
  struck as RESOLVED with the upstream cairn D-024 question explicitly fenced.
- **AC4** — D-007 present at `DECISIONS.md:130`.
- **AC5** — FAILED first pass (see work-log correction), amended via gate, then
  re-verified: 30 PDFs on disk, 30 citekeys enumerated in the `INDEX.md` shelf
  inventory, every PDF matched, `jorgensen2019`/`jorgensen2021` distinct.
- **AC6** — 7 committed pages, 7 indexed, none unindexed; `cairn_validate`
  exit 0.
- **AC7** — 1802 pass, 0 fail, 0 error, 23 skip (`NOT_CRAN=true CI=true`).

**Consistency gate.** `cairn_validate` all checks PASS (285 advisory
dangling-id warnings are pre-existing, referencing archived pre-migration
milestones). Profile `consistency-gate` slot: `devtools::document()` no diff ·
`devtools::check(--as-cran)` **0 errors / 0 warnings / 0 notes** ·
`pkgdown::check_pkgdown()` clean · `air format --check` clean ·
`lintr::lint_package()` clean · `cairn/` and `CLAUDE.md` both `.Rbuildignore`d,
no new top-level files · no `R/`, `man/`, `NAMESPACE`, or vignette changes, so
no NEWS entry is required (docs/tracking only). `cairn_impact` skipped — no
DESIGN.md IPn/GPn text changed.

**Independent review — three lenses + scorer.**

- **[O] diff-bug (Opus):** 4 findings.
- **[S] blame-history (Sonnet):** 1 finding.
- **[S] prior-PR-comments (Sonnet):** *no prior-PR evidence* — mapped every
  touched file to its merging PRs (#54 cairn-init migration, plus #40–#59);
  all review-comment arrays genuinely empty (Codecov bot noise only, no rate
  limit hit). Zero findings. Also checked LESSONS.md: no lesson violated.

**Actioned (score ≥ 80):**
- **F1 (93) — fixed.** `jorgensen2021.pdf` exists; T1's 29-PDF sweep missed it,
  making AC5's recorded "no PDF" gap false and creating a phantom blocker in the
  ROADMAP and M64. Fix: AC5 amended via gate to require an enumerated 30-PDF
  mapping; the mapping added to `INDEX.md`; phantom ROADMAP row dropped; M64
  unblocked and widened 9 → 10 notes; work-log correction appended (superseding,
  not rewriting).

**Below threshold — logged, and two actioned anyway at maintainer's direction:**
- **F3 (78) — fixed on request.** `PRINCIPLES.md` #12 retargeted to
  `BIBLIOGRAPHY.md`: #12 is a citation obligation, and the same diff sent the
  parallel case (`test-vignette-claims.R:8`) there.
- **F5 (70) — fixed on request.** D-007 extended to cover the #12 citation-path
  edit; `(#12, D-007)` added to the PRINCIPLES.md header exception list,
  satisfying that file's self-declared change-control rule.
- **F2 (74) — not actioned.** The `DESIGN.md` registry-pointer line describes
  fields ("type", asserting `test:line`) that no `ORACLES.md` entry carries. Real,
  but the finding's own census was wrong (it reported 24 `Pins:` when the actual
  split is Pins=2 / Role=24), and the doctrine leaves registry *shape* free —
  only the location must be declared, which it now is. Candidate-worthy at most.
- **F4 (55) — not actioned.** `ohyama2025.md` filed under "Synthesis notes"
  rather than "Source notes". Its own unchanged `Role` line has called it a
  "synthesis/oracle note" since M62, and no milestone lists it as pending, so
  the claimed double-write risk does not hold.

**Not reported by design** (per the false-positive taxonomy given to all three
reviewers): the `estimand-specs/` relative links inside `ORACLES.md` resolve
wrongly, but that body is byte-identical to `origin/main` — pre-existing, not
introduced here.
