<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M73: Make every dated observation executable

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M71   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m73-executable-dated-observations   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Make every claim a references page makes about the repo's own state settled by
a re-runnable command rather than by a reader's care.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the **87 dated observations** across the 30 source notes and
`INDEX.md` (measured 2026-07-19; only 2 currently carry a settling command).
Each is brought to a recorded convention — the claim carries inline the exact
command that settles it — or, where no command can settle it, is restated as a
standing fact about the source or removed. A **committed checker script**
re-runs every settling command and reports claim-vs-reality, exiting non-zero
on a falsified claim. A D-entry records the convention.

**Out:** `ORACLES.md` and `BIBLIOGRAPHY.md` → M72 owns those pages (if M72
lands first, it adopts this convention rather than M73 revisiting them).
Generalizing claims about a *source's* table ("the four lowest cells are all
at low `ρ`") → M74; they need a full-table recomputation, not a command.
The seven notes' source-fidelity (values, quotations, anchors) → M71.
A `cairn_validate` check enforcing the convention plugin-side → the cairn
repo, not this one.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] A `cairn/DECISIONS.md` entry defines the convention: what a dated
      observation must carry, what counts as a settling command, and what to
      do with a claim no command can settle.
- [ ] A committed checker script re-runs every settling command in the
      references corpus and reports, per claim, the command and whether the
      claim holds. It **exits non-zero on a falsified claim** — the property
      being protected is that a false claim fails a run, not that a reader
      notices it.
- [ ] The checker fails when a claim is falsified: demonstrated by mutating a
      true claim to a false one and showing the run go red, not by inspection
      (tracking-rules "a guard must fail when the rule it locks is deleted").
- [ ] Every dated observation in the 30 source notes and `INDEX.md` either
      carries a settling command, or is restated as a standing fact about its
      source, or is removed — none is left asserting repo state on a reader's
      word.
- [ ] The checker run is clean, and every claim it falsified along the way was
      corrected at its source with the correction's basis recorded.
- [ ] No package value changes: any correction that would move an oracle
      value, test fixture, or documented behavior is escalated as a review
      finding with its citation, not silently applied.
- [ ] `cairn_validate` passes and the r-package `verify` slot is clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4, T5, T6
- AC5 → T7
- AC6 → T4, T5, T6, T7
- AC7 → T8

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: draft the D-entry defining the convention; it governs the rest of
      the milestone, so it lands first. Settle there what to do with a claim
      that is true but not command-settleable (the honest options are
      restate-as-standing-fact or delete, not stamp-and-hope).
- [x] T2: write the checker script — parse the references corpus for dated
      observations, extract each settling command, run it, compare against the
      claim. Site it per repo convention alongside the other `cairn/scripts/`
      tooling or `data-raw/`, whichever the profile's layout indicates.
- [ ] T3: prove the checker bites — mutate a true claim to a false one, show
      the run go red, revert. Register the mutation so a later refactor cannot
      make the checker vacuous.
- [ ] T4: bring the seven M71 notes' 22 observations to the convention (they
      are the best-understood and the ones review already probed).
- [ ] T5: bring the M69/M70 notes' observations to the convention.
- [ ] T6: bring the remaining source notes' and `INDEX.md`'s observations to
      the convention.
- [ ] T7: run the checker over the whole corpus; correct every falsified
      claim at its source, recording the basis of each correction.
- [ ] T8: run `cairn_validate` and the r-package `verify` slot; confirm the
      diff touches no package value.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-20 (T2): committed `data-raw/check-reference-observations.py` — parses the in-scope corpus (all `references/*.md` less ORACLES/BIBLIOGRAPHY/REFERENCES), excludes `Extraction:` provenance lines, requires a `check:` directive per observation, runs each (exit 0 = holds), exits nonzero on unmarked/falsified. `--self-test` and `--list-unmarked` modes. Baseline: 62 in-scope observations, all 62 unmarked (pre-authoring); self-test passes.
- 2026-07-20 (T1): D-009 drafted and committed defining the dated-observation convention. Implement gate resolved three open choices (HTML-comment directive syntax; Python checker in `data-raw/`; provenance exempt + `check: none — reason` escape) — all recommendations accepted.
- 2026-07-19: created by /milestone-plan, re-cutting M71 after the thrash rule fired on its third review return. Plan gate: audit all 30 notes (87 observations) rather than M71's seven; mechanize with a committed checker rather than a one-off audit. Rationale from M71's three review attempts — every value-level correction survived independent verification all three times, while interpretive claims about repo state failed every time, twice in prose written to fix the previous cycle's prose; the measured cause is that only 2 of 87 dated observations carry the command that would settle them, so each review re-derives them by hand.

## Decisions
<!-- owner: implement / review · append-only -->

- 2026-07-20 (T1): convention promoted to cross-cutting D-009 (repo-side): HTML-comment
  `<!-- check: <cmd> -->` directive with exit-0-means-holds semantics; Python checker in
  `data-raw/`; provenance `Extraction:` lines exempt; `check: none — reason` for the
  genuinely un-settleable. Three implement-gate choices (syntax, siting, unsettleable
  handling) confirmed by the user.

## Review
<!-- owner: review · exclusive -->
