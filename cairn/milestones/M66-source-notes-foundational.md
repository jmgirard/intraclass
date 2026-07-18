<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M66: Source notes — the foundational and interpretation shelf

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** low   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, IP3   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ingest the seven historical and interpretation-oriented ICC papers that inform
the package's guidance and coefficient-selection surface but source no estimator.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** seven `<citekey>.md` source notes read from `cairn/references/pdf/`:
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
      source named in Scope, each with the five validation-doctrine fields and
      page/table anchors on every extracted value.
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

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2
- AC4 → T1, T2
- AC5 → T4
- AC6 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [ ] T1: Notes for the historical trio — `bartko1966`, `bartko1976`,
      `trevethan2017`. These are the package's intellectual prehistory; keep
      them short and anchor the definitional claims.
- [ ] T2: Notes for the selection-relevant pair — `tenhove2018`, `shieh2015`;
      record their bearing on `choose_icc()` and log any divergence from
      current guidance as a finding.
- [ ] T3: Notes for the design pair — `hedges2012` (multilevel ICC variance),
      `jorgensen2019` (planned-missing efficiency). Flag in `jorgensen2019`'s
      note that it is commonly confused with Jorgensen (2021) — the O-SEM
      source, a different paper.
- [ ] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [ ] T5: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (promotes the tier-C candidate row's
  package-relevant half; the maintainer chose at the routing chip to plan the
  shelf as milestones rather than leave it a candidate).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
