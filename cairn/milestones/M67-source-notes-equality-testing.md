<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M67: Source notes — the ICC-equality-testing cluster

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m67-source-notes-equality-testing` · https://github.com/jmgirard/intraclass/pull/75   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ingest the four ICC-equality-testing papers as short source notes that also
document *why* hypothesis tests comparing ICCs sit outside the contract boundary.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** four `<citekey>.md` source notes read from `cairn/references/sources/`:
`donner2002` (testing equality of dependent ICCs), `konishi1989` (testing
equality of several ICCs), `naik2007` (equality under unequal family sizes),
`young1998` (equality under unequal family sizes). Deliberately **short** notes:
citation, the test statistic and its design assumptions with anchors, and an
explicit IP2 line stating that comparing ICCs across groups is not the
interrater-ICC estimation contract. Together they become the citable record for
that boundary, so the question does not get re-litigated from memory.

**Out:** implementing, exporting, or prototyping any equality test → refused;
this cluster is ingested *as evidence of a boundary*, and adopting it would
take an IP2 constitutional amendment (D-entry + user decision). The other
tier-C papers → M66; the interval-methods cluster → M65.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Four `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields and a
      conforming `**Provenance.**` block (ingested date, source pointer,
      pagination basis, dated `Extraction:` status) per M68; each test statistic
      and its design assumptions carry a page anchor.
- [ ] AC2: Each note carries an explicit IP2 boundary line stating that
      ICC-equality testing is outside the package's contract, and that adopting
      it would require an IP2 amendment — not a feature request.
- [ ] AC3: Each note's "what traces to it" field states plainly that nothing in
      the package traces to it, and that this is by design.
- [ ] AC4: `DESIGN.md`'s IP2 statement gains a one-line cross-reference to this
      cluster as the citable record for the boundary (a pointer only — the
      substance stays in the notes).
- [ ] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [ ] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
      failed + error = 0).
- [ ] AC7: No shipped note carries a claim about the repo's own state that is
      false at merge time: every time-relative phrase and every absence
      assertion in the four notes is re-resolved after the last file-editing
      task lands, absences rest on a read to the source's final page, and any
      surviving repo-state claim is written as a dated observation. The
      young1998/naik2007 overlap claim (T2) counts as such an assertion.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4
- AC6 → T6
- AC7 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Notes for the general-case pair — `konishi1989` (several ICCs),
      `donner2002` (dependent ICCs).
- [x] T2: Notes for the unequal-family-size pair — `young1998`, `naik2007`;
      note the overlap between them rather than duplicating the derivation.
- [x] T3: Add the one-line IP2 cross-reference in `cairn/DESIGN.md`.
- [x] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [ ] T5: Staleness sweep, after T3/T4 land (M64/M65 lessons — this cost a
      review send-back on both sibling milestones). Grep the four notes for
      time-relative and absence phrasing (`at the time of writing`, `not yet`,
      `must be checked`, `not retrieved`, `not present`) and re-resolve each hit
      against the repo as it now stands, including each note's claim about the
      `DESIGN.md` IP2 cross-reference T3 adds; date any claim that survives.
- [x] T6: Run the profile `verify` slot; open the PR and drive CI green.
- [ ] T7: **(review send-back, finding 1)** `young1998.md` — the `bhandary2006`
      comparison says "a different estimator"; it is the *same* Srivastava (1984)
      estimator. Correct the claim (the real difference is the sample split) and
      reconcile it with this note's own "reuses this paper's estimator…" line.
- [ ] T8: **(review send-back, finding 2)** `konishi1989.md` and the matching
      `INDEX.md` line — "`χ²₁` recovered only at `q = 2` **or** equal dimensions"
      is wrong on both disjuncts. Restate: exact `χ²₁` needs normality **and**
      equal `p` **and** `q = 2`; at `q = 2` in the general case the limit is
      `c·χ²₁` with an unknown-parameter scale (p. 99), and equal `p` under
      normality only makes the weights parameter-free (p. 100).
- [ ] T9: **(review send-back, findings 3 and 5)** Citation-field accuracy:
      `konishi1989.md`'s AMS secondary is **62H10**, not 62H20; drop the
      unprinted issue numbers from `konishi1989` (`21(1)`) and `young1998`
      (`54(4)`) in `BIBLIOGRAPHY.md` or annotate them as not printed; add the
      "(No DOI is printed…)" annotation to `donner2002`; and correct the
      provenance census from "three" to "four".
- [ ] T10: **(review send-back, finding 6)** Restore the two altered quotations
      to verbatim — `young1998.md` "In real world research, **having** families
      of equal size is artificial" (p. 1363), and `naik2007.md` "**thus**
      modified (negative two times **the**) likelihood ratio" (p. 6503).
- [ ] T11: **(review send-back, AC7 failure)** Date the absence assertions.
      Every "Nothing in the package … no `ORACLES.md` entry cites it" claim — in
      both `## Traces to` and the `**Role.**` echo, all four notes — takes an
      inline `— observed YYYY-MM-DD`, matching the convention already used by
      `trevethan2017.md` and `fleiss1973.md`. Then re-run T5 to completion.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the tier-C candidate row's out-of-contract half; framed as boundary documentation rather than capability ingestion, since IP2 permanently excludes ICC-equality testing).
- 2026-07-18: gated amendment by M68 — Scope names `references/sources/` (shelf renamed) and AC1 now requires a conforming Provenance block on each note.
- 2026-07-19: gated amendment at a /milestone-plan re-run — new AC7 + T5 make the M64/M65 staleness sweep mechanical (old T5 becomes T6); M66's verified-extraction bar deliberately NOT applied, since AC3 makes these notes non-load-bearing by design.
- 2026-07-19: in-progress by /milestone-implement on branch `m67-source-notes-equality-testing`; all four shelf PDFs present (donner2002, konishi1989, naik2007, young1998).
- 2026-07-19: implement question gate — notes stay short per Scope (no transcribed simulation tables or worked-example reproductions, unlike M65's `bhandary2006`); `bhandary2006` gets a two-way cross-reference as a fifth cluster member, answering the request in its own note without reopening M65's shipped text. No RB tripwire: M67 documents the IP2 fence rather than moving it.
- 2026-07-19: T1 done — `konishi1989.md` (approximate LRT, `q` populations, non-`χ²` null) and `donner2002.md` (dependent ICCs, same subjects, two observer panels), both read to the final page.
- 2026-07-19: T2 done — `young1998.md` and `naik2007.md`, both read to the final page; the overlap is carried once, as a difference table in `naik2007.md` (the generalizing paper), and cross-referenced from `young1998.md`. Finding: the pair reach opposite recommendations (LRT vs score/`T₀`), because naik2007 p. 6503 reports young1998's Srivastava-into-LRT substitution yielding a negative `−2 log Λ` on up to 25 % of simulated data sets — the notes must not be cited as agreeing.
- 2026-07-19: `bhandary2006.md` gains the reciprocal cluster cross-reference its M65 cluster-reassignment finding asked for (per the implement question gate); its own framing and extracted values are untouched.
- 2026-07-19: T3 done — `DESIGN.md` IP2 gains a pointer sentence naming the cluster as the citable record for the hypothesis-testing side of the boundary; the principle's own wording is unchanged, so this is a cross-reference, not an IP amendment.
- 2026-07-19: T4 done — 4 `BIBLIOGRAPHY.md` entries (34 → 38, verified by count; three withhold a field the source does not print) + 4 `INDEX.md` source-note lines and an M67 cluster paragraph; `cairn_validate` passes (15 PASS, exit 0), with `references staleness` 11 → 15 as the four unverified notes join the backlog by design.
- 2026-07-19: T4 also retired two stale INDEX claims found while editing — the shelf is 30 PDFs, not 31 (`jorgensen2019.pdf` has since been deleted, as the M66 correction anticipated, so "still on the shelf" was false), and "five shelf PDFs with no note" is now zero: 30 notes / 30 PDFs, no orphan either way.
- 2026-07-19: T5 done — staleness sweep clean. The time-relative/absence grep leaves only the four dated `Extraction:` lines; no note makes a `DESIGN.md` claim (that claim lives in `INDEX.md`, where T3 makes it true). The "nothing traces to it" absences were verified by command, not asserted: neither the four citekeys nor any author surname (konishi/gupta/donner/zou/naik/helu/bhandary/srivastava) appears in `R/`, `tests/`, `man/`, `vignettes/`, `NEWS.md`, `README.md`, `data-raw/`, or `ORACLES.md`. All four sources were read to their final page.
- 2026-07-19: worked-example sections in `donner2002`/`young1998`/`naik2007` cut to the one fact each boundary claim needs (the pooled-`ρ` interval, the negative estimates, the bootstrap SE); raw data and reproduced statistics dropped as inappropriate to boundary evidence. Final lengths 107/143/131/165 lines — short against the `bhandary2006` precedent (230) and carrying only Scope/AC-named sections, but above the "~60–90 lines" the implement gate's chip quoted; that figure was invented at the chip, not planned, and is flagged at the completion gate rather than chased.
- 2026-07-19: T6 — profile `verify` slot clean (`NOT_CRAN=true CI=true`: FAIL 0, WARN 2, SKIP 23, PASS 1802; failed + error = 0); PR #75 opened.
- 2026-07-19: `main` moved under the branch (maintainer supplied trevethan2017's issue version of record, corrected there as a trivial tracking commit, `c10bf39`) — merged in per the git model, one conflict in `BIBLIOGRAPHY.md`'s provenance sentence resolved to keep both facts (M67's four new entries **and** Trevethan's now-filled year/pages); `verify` re-run clean after the merge, `cairn_validate` passes.
- 2026-07-19: **/milestone-review attempt 1 — SENT BACK to in-progress.** AC7 fails as literally written: the four notes' "Nothing in the package … no `ORACLES.md` entry cites it" absence assertions carry no `— observed YYYY-MM-DD` stamp, in both `## Traces to` and the `**Role.**` echo, so T5 is un-ticked and T11 added. AC1-AC6 pass with fresh evidence at `9516142`; consistency gate and all three review lenses' mechanical checks pass.
- 2026-07-19: review fan-out — blame-history and prior-PR lenses returned no finding; the diff-bug lens returned six, all re-verified against the shelf PDFs by an independent scorer (95/83/90/78/90/92). Five actioned as T7-T10: a false "different estimator" claim in `young1998.md`, a wrong `χ²₁` recovery condition in `konishi1989.md` + `INDEX.md`, a wrong AMS secondary class (62H20 → 62H10), a bibliography census that miscounts withheld fields in both directions, and two altered verbatim quotations. The 78 (AC7 dating) is below the action threshold as a *finding* but is recorded as a criterion failure, which is a gate determination and not threshold-gated.
- 2026-07-19: T5 sharpened two claims now that all four are read — `donner2002`'s `ρ`-floor claim is restated over the full five-paper cluster (0.4 is the highest floor; none reaches 0), and `naik2007` gains a recorded misprint: it spells Huang as "Haung" in both the intro and its reference list (p. 6510), flagged so no citekey is minted from the misspelling. No repo value affected.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

### Attempt 1 — 2026-07-19 — SENT BACK (AC7 fails; five actioned findings)

Evidence gathered at `9516142`. **AC7 fails as literally written**, and the
independent review found factual errors in shipped extraction content. Status
returned to `in-progress`; not merged.

**Criterion evidence (fresh, by command at `9516142`):**

- AC1 ✅ — all four notes carry `**Provenance.**` / `Pagination:` / `Extraction:`
  / `**Citation.**` / `**Role.**` / `## Traces to` / `## Open questions`, one each
  (counted). Page anchors per note: konishi1989 38, donner2002 40, young1998 39,
  naik2007 34. `Extraction:` is one physical line each, dated.
- AC2 ✅ — each note has a `## Boundary (IP2)` section stating the contract
  exclusion, the constitutional-amendment requirement, and "not a feature
  request" (konishi1989's is line-wrapped, verified by reading the section).
- AC3 ✅ — each `## Traces to` opens "**Nothing in the package**"; re-verified by
  command: 0 hits for the four citekeys or their author surnames across `R/`,
  `tests/`, `man/`, `vignettes/`, `NEWS.md`, `README.md`, `data-raw/`,
  `ORACLES.md`.
- AC4 ✅ — `DESIGN.md` IP2 carries the pointer sentence; the principle's own
  wording is unchanged (blame-history lens confirmed against the D-007 precedent
  that a moved path is not a substance change, so no D-entry is owed).
- AC5 ✅ — 4 `BIBLIOGRAPHY.md` entries and 4 `INDEX.md` lines present (counted);
  `cairn_validate` exit 0.
- AC6 ✅ — profile `verify` slot re-run fresh at review: FAIL 0, WARN 2, SKIP 23,
  PASS 1802; failed + error = 0.
- AC7 ❌ **FAILS** — the criterion requires "any surviving repo-state claim is
  written as a dated observation". The four notes' "Nothing in the package … no
  `ORACLES.md` entry cites it" absence assertions carry **no `— observed
  YYYY-MM-DD` stamp**, in both the `## Traces to` bullet and the `**Role.**`
  echo. The verification was genuinely performed (T5) but the shipped text does
  not surface it, and sibling notes `trevethan2017.md` / `fleiss1973.md` already
  set the dating convention. `donner2002.md`'s ρ-floor claim *is* dated, so the
  convention was applied selectively inside one milestone. Not reinterpreted:
  the criterion is right and the work misses it.

**Consistency gate (all pass):** `cairn_validate` exit 0, 15 PASS (advisories:
`dangling id tokens` legacy-by-design, `references staleness` 15 as the four
unverified notes join the backlog by plan-gate choice). Profile
`consistency-gate` slot: `devtools::document()` no diff; no generated or package
file touched (branch is `cairn/`-only); `.Rbuildignore` carries `^cairn$`;
`pkgdown::check_pkgdown()` "No problems found"; README in sync; NEWS entry not
owed (no user-visible change). Full `R CMD check` is covered by CI's five-platform
matrix on PR #75.

**Independent review — three lenses + scorer.** Blame-history: **no finding**
(confirmed `c1d7c1c`'s deletion-safe design worked as intended and the merge
resolution lost neither side). Prior-PR-comments: **no finding** (no GitHub
review-comment corpus; confirmed the diff does not regress the M64/M65 dating
lesson — though see AC7, which it partly does in a form that lens did not cover).
Diff-bug lens: six findings, all independently re-verified by the scorer against
the shelf PDFs.

**Actioned (score ≥ 80) — five, all to fix on the return trip:**

1. **(95) `young1998.md` — false "different estimator" claim.** The note says
   `bhandary2006` "uses this same data set, split three ways, and gets positive
   estimates from a different estimator." It is the *same* estimator (Srivastava
   1984, `ρ̂ = 1 − γ̂²/σ̂²`), and the claim contradicts this same note's later line
   that bhandary2006 "reuses this paper's estimator, transformation, simulation
   design, and worked data set", plus `bhandary2006.md` itself. The real
   difference is the split (2 samples of 7 vs 3 of 5/5/4).
2. **(83) `INDEX.md` + `konishi1989.md` — the `χ²₁` recovery condition is wrong.**
   Both say `χ²₁` is recovered "only at `q = 2` **or** equal dimensions". Neither
   disjunct suffices: at `q = 2` in the general/nonnormal case the limit is
   `c·χ²₁` with an unknown-parameter scale (p. 99); equal `p` under normality only
   makes the weights parameter-free (p. 100) but leaves a weighted sum. Exact
   `χ²₁` needs normality **and** equal `p` **and** `q = 2`.
3. **(90) `konishi1989.md` — wrong AMS secondary classification.** Note prints
   "62H20 (secondary)"; the title page reads Secondary **62H10** (the OCR
   `62HIO`). A field presented as "as printed" is wrong.
4. **(90) `BIBLIOGRAPHY.md:5` — the M67 provenance census miscounts, both ways.**
   It says "three of them withhold a field"; it is **four** — `donner2002` prints
   no DOI either and its entry omits it *without* the "(No DOI is printed…)"
   annotation its siblings carry. In the other direction, `konishi1989`'s `21(1)`
   and `young1998`'s `54(4)` issue numbers are **not** printed on their title
   pages (JSPI prints "21 (1989) 93-105"; Biometrics prints "BIOMETRICS 54,
   1363-1373"), so two entries supply an unprinted field while `naik2007`
   explicitly refuses to.
5. **(92) Two altered verbatim quotations.** `young1998.md` quotes "…assuming
   families of equal size is artificial"; p. 1363 reads "In real world research,
   **having** families of equal size is artificial." `naik2007.md`'s blockquote
   reads "the modified (negative two times) likelihood ratio"; p. 6503 reads
   "**thus** modified (negative two times **the**) likelihood ratio". Both sit
   inside quotation marks, where the template requires verbatim.

**Logged, below threshold (1):** the AC7 dating gap scored **78** as a *finding*
— the scorer judged it a documentation-completeness issue since the underlying
check was really performed. It is nonetheless recorded above as a **criterion
failure**, which is a gate determination and not subject to the finding
threshold.

**Reviewer judgment recorded, no action:** the diff-bug lens noted that AC4's
pointer phrase "the hypothesis-testing side of this boundary" characterizes IP2
along an axis (inferential target) that IP2's own enumeration (rival *coefficient
families*) does not use. Its assessment, which this review accepts: an
application of IP2, not a widening of it — no D-entry owed, but the sentence a
future reader would point at to argue IP2 grew silently.

**Also noted for the return trip (not a numbered finding):** the four notes run
107/143/131/165 lines against the "~60–90 lines each" quoted at the implement
question gate. That figure originated in the chip text, not the plan; Scope says
only "deliberately short". Flagged for the maintainer to rule on rather than
silently kept or cut.
