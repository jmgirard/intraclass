<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M66: Source notes — the foundational and interpretation shelf

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m66-source-notes-foundational`   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: Seven `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields,
      page/table anchors on every extracted value, and a conforming
      `**Provenance.**` block (ingested date, source pointer, pagination basis,
      dated `Extraction:` status) per M68. Each source is read to its final page
      and its note ships a dated *verified* extraction status — these seven do
      not join the standing re-verify backlog.
- [ ] AC2: Each note's "what traces to it" field is honest — for a source
      nothing currently traces to, it states that explicitly and names what it
      *could* source, rather than manufacturing a connection.
- [ ] AC3: The `shieh2015` and `tenhove2018` notes each state, with anchors,
      what they imply for `choose_icc()`'s selection logic — and any divergence
      from the package's current guidance is recorded in the work log as a
      finding for a separate milestone, not acted on here.
- [ ] AC4: No note introduces a qualitative ICC band into package-facing
      material; interpretation content stays in the note and is marked as
      IP3-fenced (`trevethan2017` and `bartko1976` both carry such content).
- [ ] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [ ] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
      failed + error = 0).
- [ ] AC7: No shipped note carries a claim about the repo's own state that is
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
- [ ] T5: Staleness sweep, after T4 lands (M64/M65 lessons — this cost a review
      send-back on both sibling milestones). Grep the seven notes for
      time-relative and absence phrasing (`at the time of writing`, `not yet`,
      `must be checked`, `not retrieved`, `not present`) and re-resolve each hit
      against the repo as it now stands; date any claim that survives.
- [ ] T6: Run the profile `verify` slot; open the PR and drive CI green.

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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
