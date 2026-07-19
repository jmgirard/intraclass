<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M66: Source notes — the foundational and interpretation shelf

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m66-source-notes-foundational` / [#74](https://github.com/jmgirard/intraclass/pull/74)   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ingest the seven historical and interpretation-oriented ICC papers that inform
the package's guidance and coefficient-selection surface but source no estimator.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** seven `<citekey>.md` source notes read from `cairn/references/sources/`:
`bartko1966` and `bartko1976` (the foundational ICC-as-reliability papers),
`tenhove2018` (20 IRR coefficients compared on four datasets), `trevethan2017`
(cautions, extensions, requests), `hedges2012` (variance of ICCs in three- and
four-level models), `shieh2015` (choosing the best index for the average-score
ICC), `jorgensen2019` (efficiency of IRR estimates from planned-missing designs
on a fixed budget). Each note records what the paper *could* source and, where
it bears on `choose_icc()` or the vignettes' guidance, says so explicitly.

**Out:** the ICC-equality-testing cluster → M67; the load-bearing sources → M64;
the interval-methods cluster → M65; any change to `choose_icc()` behavior or
vignette text a note suggests → escalated as its own milestone, never folded in
here (this milestone writes notes, not code); any interpretation **cutoff** or
qualitative band entering package output → refused outright (IP3).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: Seven `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields,
      page/table anchors on every extracted value, and a conforming
      `**Provenance.**` block (ingested date, source pointer, pagination basis,
      dated `Extraction:` status) per M68. Each source is read to its final page
      and its note ships a dated *verified* extraction status — these seven do
      not join the standing re-verify backlog.
- [x] AC2: Each note's "what traces to it" field is honest — for a source
      nothing currently traces to, it states that explicitly and names what it
      *could* source, rather than manufacturing a connection.
- [x] AC3: The `shieh2015` and `tenhove2018` notes each state, with anchors,
      what they imply for `choose_icc()`'s selection logic — and any divergence
      from the package's current guidance is recorded in the work log as a
      finding for a separate milestone, not acted on here.
- [x] AC4: No note introduces a qualitative ICC band into package-facing
      material; interpretation content stays in the note and is marked as
      IP3-fenced (`trevethan2017` and `bartko1976` both carry such content).
- [x] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [x] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
      failed + error = 0).
- [x] AC7: No shipped note carries a claim about the repo's own state that is
      false at merge time: every time-relative phrase and every absence
      assertion in the seven notes is re-resolved after the last file-editing
      task lands, absences rest on a read to the source's final page, and any
      surviving repo-state claim is written as a dated observation.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2
- AC4 → T1, T2
- AC5 → T4
- AC6 → T6
- AC7 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Notes for the historical trio — `bartko1966`, `bartko1976`,
      `trevethan2017`. These are the package's intellectual prehistory; keep
      them short and anchor the definitional claims.
- [x] T2: Notes for the selection-relevant pair — `tenhove2018`, `shieh2015`;
      record their bearing on `choose_icc()` and log any divergence from
      current guidance as a finding.
- [x] T3: Notes for the design pair — `hedges2012` (multilevel ICC variance),
      `jorgensen2019` (planned-missing efficiency). Flag in `jorgensen2019`'s
      note that it is commonly confused with Jorgensen (2021) — the O-SEM
      source, a different paper.
- [x] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [x] T5: Staleness sweep, after T4 lands (M64/M65 lessons — this cost a review
      send-back on both sibling milestones). Grep the seven notes for
      time-relative and absence phrasing (`at the time of writing`, `not yet`,
      `must be checked`, `not retrieved`, `not present`) and re-resolve each hit
      against the repo as it now stands; date any claim that survives.
- [x] T6: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the tier-C candidate row's
  package-relevant half; the maintainer chose at the routing chip to plan the
  shelf as milestones rather than leave it a candidate).
- 2026-07-18: gated amendment by M68 — Scope names `references/sources/` (shelf renamed) and AC1 now requires a conforming Provenance block on each note.
- 2026-07-19: gated amendment at a /milestone-plan re-run — AC1 raises the bar to a dated *verified* extraction (read to final page), new AC7 + T5 make the M64/M65 staleness sweep mechanical, old T5 becomes T6.
- 2026-07-19: /milestone-implement started; status in-progress, branch m66-source-notes-foundational.
- 2026-07-19: gate — maintainer chose main-session reading of all seven PDFs (the verified bar makes extraction a first-hand claim) and depth proportionate to reliance.
- 2026-07-19: T1 done — bartko1966, bartko1976, trevethan2017 notes written, each read end-to-end and extraction-verified.
- 2026-07-19: minor amendment — INDEX.md lines are added per note-writing task, not batched into T4, so cairn_validate's references check stays green across checkpoints; T4 keeps BIBLIOGRAPHY, the shelf-inventory counts, and the final validate run.
- 2026-07-19: finding (bartko1976 Table 3, PDF p. 763) — rows 3-4 print MSW where the tabled values require MSE; found by recomputing Table 3 from Table 2. No repo value affected; nothing cites those formulas. Recorded in the note.
- 2026-07-19: finding (trevethan2017) — the shelf PDF is online-first with NO journal pagination, so anchors are PDF pages and BIBLIOGRAPHY's volume/issue/pages cannot be sourced from it; flagged for the maintainer, not filled from memory (#4).
- 2026-07-19: T2 done — tenhove2018 and shieh2015 notes written, both read end-to-end and extraction-verified; AC3 bearing-on-choose_icc sections written with anchors.
- 2026-07-19: AC3 finding (tenhove2018) — NO divergence from current guidance. Its two-way-random specification (p. 70) agrees with icc()'s raters="random" default; its consistency choice is a comparison-study specification with no stated rationale, not guidance, so nothing follows for choose_icc().
- 2026-07-19: AC3 finding (shieh2015) — FOR A SEPARATE MILESTONE. Shieh shows the conventional average-score ICC(2)=1-1/F* is negatively biased (-2(1-rho*)/(N-3)) and MSE-dominated by four alternatives (p. 997, p. 1001). It critiques an ANOVA plug-in the package does NOT use: unit="average" applies divisor k_eff to REML components (R/estimand.R:182). No choose_icc() change follows (estimand vs estimator are orthogonal axes); whether the REML estimator shares that bias is NOT established by the paper and is the open question worth its own milestone.
- 2026-07-19: finding (shieh2015 p. 1001) — published support for "groups beat judges at fixed N*K" in the one-way design; adjacent to the parked d_study() CI-width precision-planning candidate but NOT its oracle (Shieh's criterion is point bias/MSE, not interval width). Recorded in the note so the distinction is not rediscovered.
- 2026-07-19: finding (tenhove2018 Table 1) — the Vision row prints Max=3 while p. 69 states a 1-4 scale; unresolved (checking needs the irr package, not a dependency). Recorded as printed, dated, no repo value affected.
- 2026-07-19: T3 done — hedges2012 and jorgensen2019 notes written, both read end-to-end and extraction-verified; all seven M66 notes now exist.
- 2026-07-19: finding (jorgensen2019) — the citekey year is WRONG and contradicted by the source: the shelf copy is an author manuscript with no venue/year/pagination, its bibliography cites ten Hove et al. 2021 and 2022, and the PDF was typeset 2022-09-27. BIBLIOGRAPHY must not assert 2019 as a publication year; flagged for the maintainer (#4). Pagination basis is chapter-internal ms. pages 1-10.
- 2026-07-19: resolved while writing jorgensen2019 — its two ten Hove citations are works the repo already holds under LATER citekeys (its "2021 multilevel" = repo tenhove2022; its "2022 updated guidelines" = repo tenhove2024), cited pre-publication. Recorded in the note so neither is chased as an uningested source.
- 2026-07-19: finding (hedges2012) — largely OUTSIDE the contract boundary (IP2): its ICCs have no rater facet and index levels of nesting, not what is generalized over, so its "multilevel ICC" is a different quantity from tenhove2022's. Recorded in the note as boundary evidence; its symmetric Wald intervals are the contrast case for PRINCIPLES #3.

- 2026-07-19: T4 done — 7 BIBLIOGRAPHY entries (27 -> 34, both stale totals corrected), INDEX shelf inventory updated (19 -> 26 ingested, M66 paragraph rewritten with the three-way split and the source findings); cairn_validate passes.
- 2026-07-19: BIBLIOGRAPHY's Extraction status records the M66 additions but stays `unverified` overall — 16 split entries were still never read against their sources, so the page keeps its staleness WARN rather than having the wording changed to clear it (M68 lesson).

- 2026-07-19: T5 done — staleness sweep run over the seven notes; the M64 failure mode HAD recurred and was caught.
- 2026-07-19: T5 fixes — four notes (trevethan2017, hedges2012, shieh2015, jorgensen2019) claimed "nothing in the repo cites it" while T4 had added a BIBLIOGRAPHY entry and INDEX line for each hours earlier; narrowed to the precise scope (no test/vignette/ORACLES entry) naming M66's own citations.
- 2026-07-19: T5 fixes — trevethan2017 claimed to be a second source for guidance koo2016 "currently carries alone" (false once this note landed) and said INDEX records three not-version-of-record PDFs (T4 made it five, including trevethan2017 itself). Both re-resolved.
- 2026-07-19: T5 — four surviving repo-state claims verified against the repo then dated (O1's backing, the boundary-policy fixture, getting-started's band-table ordering, and bartko1976's unused data sets); zero "currently" left in the seven notes. Confirmed by grep that none of the seven citekeys or author names appears in R/, tests/, vignettes/, or ORACLES.md, so every "nothing reads this page" claim is true.

- 2026-07-19: T6 done — verify slot clean under NOT_CRAN=true CI=true: FAIL 0, WARN 2, SKIP 23, PASS 1802 (failed + error = 0, AC6). Docs-only branch: cairn/ is .Rbuildignore'd, so no test could move.
- 2026-07-19: PR #74 opened; status -> review.

- 2026-07-19: CI green on PR #74 — all 11 checks pass (9 workflow jobs + codecov project/patch).

- 2026-07-19: /milestone-review — consistency gate clean (cairn_validate exit 0; document() no-diff; pkgdown OK; devtools::check() 0/0/0; verify slot FAIL 0 PASS 1802). Three review lenses: blame-history and prior-PR both no findings; diff-bug returned 9, scored by a fresh scorer.
- 2026-07-19: review triage — 4 actioned at >=80 (F6 misquotes fixed, F3 false recomputation tick fixed, F1 REJECTED as factually wrong, F7 anchor fixed); 5 sub-threshold (F2 74, F4 78, F8 76, F5/F9 45) independently verified as real and fixed anyway rather than shipping known errors — deviation from the 80 cut, logged here.
- 2026-07-19: F1 rejection evidence — the trevethan2017 'Published online' footer IS printed on page 1 (400-DPI render); it is absent from the PDF text layer in every pdftotext mode, which misled both the reviewer and the scorer. No change to the note.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Reviewed 2026-07-19.** PR [#74](https://github.com/jmgirard/intraclass/pull/74).
Branch synced: `main` had not moved (merge-base == `origin/main`), so no merge was needed.

### Acceptance-criteria evidence (fresh, by command)

- **AC1** — all 7 notes carry the five doctrine fields, a `Pagination:` basis, and a
  dated *verified* `Extraction:` status on one physical line (checked per file). Each
  note's pagination claim was cross-checked against the actual PDF page count and all
  7 match exactly (9/4/17/9/10/17/10 pp).
- **AC2** — all 7 carry a `## What this could source` section and an explicit
  no-trace statement. Truth-checked: grep for every citekey **and** author surname
  across `R/`, `tests/`, `vignettes/`, `man/`, `ORACLES.md` returns **0** occurrences,
  so every no-trace claim is true as written.
- **AC3** — `shieh2015.md` and `tenhove2018.md` both carry an anchored
  `## Bearing on choose_icc()` section (`trevethan2017.md` carries one too, beyond
  the requirement). Findings logged in the work log: tenhove2018 = no divergence;
  shieh2015 = a separate-milestone finding (its critique targets an ANOVA plug-in the
  package does not use, `R/estimand.R:182`).
- **AC4** — IP3 fences present in `bartko1976.md`, `trevethan2017.md` (the two AC4
  names) and additionally `tenhove2018.md`. Package-facing material untouched:
  `git diff --name-only origin/main..HEAD` shows **0** files outside `cairn/`.
- **AC5** — all 7 have a `BIBLIOGRAPHY.md` back-link and an `INDEX.md` line;
  `cairn_validate` exits 0, "all checks passed".
- **AC6** — profile `verify` slot re-run fresh under `NOT_CRAN=true CI=true`:
  **FAIL 0 | WARN 2 | SKIP 23 | PASS 1802** (failed + error = 0).
- **AC7** — fresh sweep over the 7 notes returns **0** undated time-relative phrases;
  every absence claim carries an inline `— observed 2026-07-19`. Two AC7 gaps found at
  review (an undated "traces here today", and undated `Traces to` lead sentences) were
  fixed here, not reinterpreted.

### Consistency gate

Universal: `cairn_validate` exit 0, all CHECKs PASS; 318 advisories, unchanged from
pre-M66 (14 work-log-format + 293 dangling-id + 11 references-staleness, all
pre-existing). No `DESIGN.md` principle changed → `cairn_impact` correctly skipped.
Toolchain (`r-package` slot): `document()` no diff; `NAMESPACE`/`man/` clean;
README in sync; `pkgdown::check_pkgdown()` no problems; no NEWS entry (0 user-facing
files touched); no new top-level files; `devtools::check()` **0 errors, 0 warnings,
0 notes**. CI green on PR #74 (11/11 checks).

### Independent review — three lenses + scorer

Blame-history **[S]**: no findings (independently re-derived the 34/26/30 counts and
confirmed BIBLIOGRAPHY still fires the staleness advisory rather than having it worded
away — M68 lesson held). Prior-PR-comments **[S]**: no findings (no inline PR-comment
history in this repo; fell back to archived Review sections). Diff-bug **[O]**: nine
findings, scored by a fresh **[S]** scorer.

**Actioned (fixed on the branch):**

- **F6 (94) — three quotations marked verbatim were not.** `bartko1966` "commonly
  *used*" → source prints "commonly *given*"; `trevethan2017` Model 3 "produce
  *higher* ICCs" → "the *highest* ICCs", and Model 1 dropped "two" from "the other
  two models"; `tenhove2018` "behind *the IRR coefficients* … *can we* start" →
  "behind *IRR* … *we can* start". All three corrected and re-verified against the
  PDFs. The most serious finding: a verified-extraction stamp is what licenses trust
  in a verbatim quote.
- **F3 (93) — a recomputation marked ✓ that did not agree.** `hedges2012`'s
  three-level `Var(r_2)` recomputes to 4.38e-5 vs the printed 4.05e-5 (~8 %), and
  SE 0.0066 rounds to 0.007 not the printed 0.006. Replaced the false tick with the
  rounding explanation (the paper rounds intermediates before summing) and narrowed
  the Provenance claim: the two-level example reproduces exactly, both three-level
  examples only up to the paper's displayed rounding.
- **F1 (92) — REJECTED, reviewer and scorer both wrong.** Both concluded the
  `Published online:` footer line (dated 2016-08-23) is absent from
  `trevethan2017.pdf` and is only `CreationDate` metadata. It is **printed on
  page 1**, bottom-left beside the Springer logo — confirmed by a 400-DPI render of
  the footer strip. The string is
  absent from the text layer in *every* `pdftotext` mode (`-layout`, `-raw`,
  whole-document), which is what misled both agents. The note's claim stands
  unchanged.
- **F7 (82) — wrong cross-reference anchor.** `shieh2015.md` and `jorgensen2019.md`
  cited `M4.5-d-study.md` §6 for the d_study CI-width gating; §6 is the out-of-scope
  list and states no gate. Re-anchored to `ROADMAP.md:39` / `DESIGN.md:41`.

**Sub-threshold but independently verified and fixed anyway** (a deliberate deviation
from the 80 cut — these were confirmed by direct recomputation/reading, and leaving
known errors in place because a scorer said 74 would be worse than the rule protects
against):

- **F2 (74) — a source erratum reproduced without flagging.** Shieh's p. 1000
  `K = 10` ranking prints `RAB{UB} < RAB{ME} < RAB{MO}`, contradicting his own
  Tables 1–4 where `MO` precedes `ME` in all four cells. Re-derived from Eq. (6):
  `c_MO = 0.7609 → 0.0760`, `c_ME = 0.9339 → 0.7026`. The note now records the
  erratum with the arithmetic — matching how it already treats the `bartko1976`
  Table 3 misprint.
- **F4 (78) / F5 (45) — the #4 withholding was applied inconsistently.**
  `BIBLIOGRAPHY.md` asserted "Trevethan, R. (2017)" while the note states that year
  is uncorroborated by the copy. The year is now withheld there as it is for
  `jorgensen2019`, and `INDEX.md`'s "two citekeys" is now three, distinguishing
  *contradicted* (shieh, jorgensen) from *uncorroborated* (trevethan).
- **F8 (76) — band-scheme counts did not reconcile across three files.**
  `trevethan2017.md` tables three schemes (incl. Nunnally & Bernstein), so Landis &
  Koch is the sixth on the shelf, not the fifth; and "surveys four" (BIBLIOGRAPHY,
  INDEX) contradicted the note's own statement that Trevethan cites neither Koo & Li
  nor Cicchetti. Corrected to three surveyed / sixth on shelf, consistently.
- **F9 (45) — AC7 read literally.** `bartko1966`'s "traces here today" was
  time-relative and undated (T5's grep pattern lacked "today"), and the seven
  `Traces to` lead sentences were undated. All eight now carry
  `— observed 2026-07-19`.

Post-fix re-verification: all three corrected quotes match their sources word-for-word;
fresh staleness sweep returns 0; `cairn_validate` exit 0.
