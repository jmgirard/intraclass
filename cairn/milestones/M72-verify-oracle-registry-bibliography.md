<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M72: Verify the oracle registry and the bibliography

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M70, M71   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m72-verify-oracle-registry-bibliography`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Define and apply a verification bar for the repo's two index pages —
`ORACLES.md` (39 entries, the declared registry home per D-007) and
`BIBLIOGRAPHY.md` — whose entries mostly trace to committed seeded scripts
rather than to pages of a PDF.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a D-entry defining a **bar split by entry kind** — *source-traceable*
entries re-read against their cited source; *script-derived* entries confirmed
against what their committed script actually commits, *without* re-running;
*mixed* entries (both legs, e.g. O1, O-OW, O-SEM) verified on each leg by its
own rule — then applied to all 39 `ORACLES.md` entries and to all 38
`BIBLIOGRAPHY.md` entries at a depth set by provenance: field-by-field for the
16 that moved as text at the D-007 split and were never read against sources,
a lighter consistency pass over the 22 authored from shelf PDFs by M64–M67.
Absorbs the Shrout & Fleiss three-decimal attribution candidate:
`ORACLES.md`'s O-OW ("published to 3 dp") and O1 ("Values (3 dp)"),
plus `tests/testthat/helper-shrout-fleiss.R:72–73`, which makes this
milestone touch code.

**Out:** re-running the seeded scripts. The Bayesian sweeps are multi-hour
background jobs and the gate chose confirmation-against-recorded-output
instead; a discrepancy found there is escalated, and re-running that script
becomes its own milestone. The 13 source notes → M70, M71.

**Depends on M70/M71** because a note's re-verification can correct a
bibliographic field, and `BIBLIOGRAPHY.md` should be checked once against a
settled shelf rather than twice.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] A D-entry in `cairn/DECISIONS.md` defines the bar for all three kinds,
      states why re-running the seeded scripts was refused, and names what a
      script-derived entry's "verified" status does and does not assert.
- [ ] All 39 `ORACLES.md` entries are classified as source-traceable,
      script-derived, or mixed, and the classification is recorded in the
      file itself so a later reader can tell which assurance each entry
      carries.
- [ ] Every source-traceable entry's values — and the source leg of every
      mixed entry — are confirmed against the cited source at the cited
      page, or corrected in place with the correction cited.
- [ ] Every script-derived entry — and the script leg of every mixed entry —
      names a committed script that exists, and the entry's values are
      confirmed against what the repo actually commits: an inline expected
      value in the script source (hardcoded constant, tolerance target, or
      trailing comment) or a committed fixture under
      `tests/testthat/fixtures/`. An entry whose script commits neither is
      recorded as **script-attested, values not independently confirmed**,
      naming that confirmation would require re-running (Out of scope) —
      never stamped confirmed. The count of entries in each state is not
      pinned in the record (LESSONS 2026-07-19/M70).
- [ ] The Shrout & Fleiss values are attributed to what the source actually
      prints: Table 4 prints **two** decimals, so O-OW, O1, and
      `helper-shrout-fleiss.R:72–73` no longer call the six three-decimal
      values published. No oracle value changes — all six round to the
      printed figure (M69 AC4).
- [ ] All 38 `BIBLIOGRAPHY.md` entries are checked at a depth set by
      provenance — field-by-field against sources for the 16 D-007 split
      entries, a consistency pass over the 22 authored from shelf PDFs by
      M64–M67 — with any field the source does not print recorded as
      withheld rather than invented (#4).
- [ ] The r-package `verify` slot is clean and `cairn_validate` passes, with
      both pages' `Extraction:` lines reflecting work actually done — no
      wording change made to clear an advisory (LESSONS 2026-07-18/M68).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: draft the D-entry defining the bar for all three kinds; it governs
      the rest of the milestone, so it lands first.
- [x] T2: classify all 39 `ORACLES.md` entries as source-traceable,
      script-derived, or mixed (`cairn/references/ORACLES.md`; entries span
      M1–M39), and record the kind per entry.
- [ ] T3: verify the source-traceable entries — and the source leg of each
      mixed entry — against their cited sources: O1, O2 (hand-derived),
      O-OW, O-SEM and any others T2 surfaces. Where the source now has a
      verified `<citekey>.md` note from M69/M70/M71, check against the
      source itself, not the note.
- [ ] T4: for each script-derived entry and the script leg of each mixed
      entry, confirm the named script exists under `data-raw/` (all 28
      referenced scripts were confirmed present at the implement gate) and
      that the entry's values match an inline expected value or a committed
      fixture; where the script commits neither, record the honest
      script-attested status. Escalate any mismatch rather than re-running.
- [x] T5: fix the Shrout & Fleiss three-decimal attribution in `ORACLES.md`
      (O-OW, O1) and in `tests/testthat/helper-shrout-fleiss.R:72–73` —
      that file's *top* provenance header is already accurate and must be
      left alone (LESSONS 2026-07-18/M69).
- [ ] T6: check all 38 `BIBLIOGRAPHY.md` entries — field-by-field for the 16
      D-007 split entries, a consistency pass over the 22 from M64–M67;
      record withheld fields as withheld.
- [ ] T7: update both `Extraction:` lines and `INDEX.md`; run
      `cairn_validate`, `lintr::lint_package()`, `air format --check`, and
      the r-package `verify` slot (T5 touches a test helper, so this is not
      a docs-only milestone).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-07-19: created by /milestone-plan (plan gate: bar split by entry kind, re-running the seeded scripts refused as multi-hour background work; absorbs the Shrout & Fleiss three-decimal attribution candidate from M69's AC4 escalation; depends on M70/M71 so BIBLIOGRAPHY is checked once against a settled shelf).
- 2026-07-19: /milestone-implement started; branch `m72-verify-oracle-registry-bibliography` cut from main.
- 2026-07-19: gated amendment (implement gate, 3 questions) — AC4 rewritten: no committed script output exists to verify against (data-raw holds zero csv/txt, one rds; `data-raw/.oracle-*-checkpoint.rds` is gitignored; 35 scripts assert via stopifnot, only 4 write a committed fixture), so AC4 now verifies against inline expected values or committed fixtures and records "script-attested, values not independently confirmed" where neither exists. All 28 scripts named in ORACLES.md confirmed present on disk at the gate.
- 2026-07-19: gated amendment — a third entry kind "mixed" added (AC2/AC3/AC4, Scope, T2–T4): O1, O-OW, O-SEM and their like carry both a source and a script leg, and each leg is verified by its own rule; classifying a mixed entry as one kind would leave half its values unverified.
- 2026-07-19: gated amendment — AC6/T6 scope set to all 38 BIBLIOGRAPHY entries at a depth set by provenance (field-by-field for the 16 D-007 split entries, consistency pass over the 22 from M64–M67); the plan's "starting with the 16" left the remainder's disposition unstated.
- 2026-07-19: T1 done — D-008 appended, defining the three-kind bar and recording that a script-derived "verified" is a provenance claim, not a reproducibility claim (the seeded scripts are not re-run; that gap stays separately plannable under #12).
- 2026-07-19: CORRECTION (D-008 Amdt 1) — the implement-gate claim "only 4 write a committed fixture" was false; 25 committed git-tracked fixtures exist under `tests/testthat/fixtures/`, written by 27 scripts. The gate grep matched only `saveRDS(x, "literal")` and missed `saveRDS(out, fixture)` with a variable destination. AC4's text is unaffected (it already names committed fixtures as a target); the honest fallback status now applies to a smaller residual — the six non-Bayes scripts that write no fixture.
- 2026-07-19: T2 in progress — [S] Explore subagent ran mechanical per-entry extraction over all 39 entries (cited source / script / numeric values / test file / provenance) plus a `data-raw/` script audit; every script path named by an entry confirmed present. Extraction is fact-only; classification calls kept in the main session (LESSONS 2026-07-19/M71 — interpretive prose is where verification fails).
- 2026-07-19: T2 done — a `- **Kind:**` bullet inserted after each of the 39 headings naming the kind, the D-008 citation, and the legs. Applied by a committed scratch script that asserts the keyed line numbers exactly equal the set of `### ` headings before writing, so no entry could be mislabelled by drift. Split: 25 mixed, 10 script-derived, 4 source-traceable.
- 2026-07-19: T2 finding for T3/T5 — O6's entry re-derives the SF values 0.290/0.620/0.715/0.909 and `data-raw/oracle-fixed-incomplete.R:79-82` hardcodes them, but neither cites Shrout & Fleiss; the attribution belongs with the T5 three-decimal fix.
- 2026-07-19: T5 done — SF Table 4 (p. 424) read directly from `cairn/references/sources/shrout1979.pdf` and confirmed to print TWO decimals (.17/.29/.71/.44/.62/.91). Settled by a 400-dpi crop render, not the text layer, which is OCR-damaged here (renders `JCC`/`/CC` for `ICC`) — LESSONS 2026-07-19/M66. The `ICC(1,4)` cell's second digit is ink-blotted and not cleanly legible at render; the text layer reads `.44` and the computed 0.4428 rounds to `.44`, and the two-decimal claim does not depend on that digit.
- 2026-07-19: T5 sweep found FOUR sites beyond the three AC5 names, all calling the 3-dp values published — `test-icc-oneway.R:16`, `test-icc-consistency.R:35`, `test-icc-twoway-agreement.R:51` and `:62`. Fixed: AC5 protects the property (the six values are no longer called published), not the enumeration (LESSONS 2026-07-18/M68), so the extra sites are in scope, not a scope expansion. The mechanical per-file sweep is what surfaced them (LESSONS 2026-07-19/M67).
- 2026-07-19: T5 verify — `devtools::test()` with NOT_CRAN=true CI=true: 1802 pass, 0 fail, 0 error, 23 skip (all skip_on_ci brms). `air format --check .` clean; `lintr::lint_package()` no lints. No oracle value changed — the fix is prose attribution only.
- 2026-07-19: T3 partial — three distinct source claims verified against the shelf PDFs at the page, each confirmed by crop render where the text layer is OCR-damaged. (a) Shrout & Fleiss Table 4, p. 424: two decimals (recorded under T5). (b) Jorgensen (2021) Eq. 6, printed p. 117 (PDF p5): `σ̂²_i = 1/(n_i − 1) · Σν̂²_i`, the raw sample variance of the effects-coded intercepts — matches O-SEM's `Σν²/(k−1)` with items→raters, and confirms the no-bias-correction reading. (c) McGraw & Wong (1996) Table 1, printed p. 32 (PDF p3): `θ² = Σc_j²/(k − 1)`, "the parameter corresponding to σ²_c in Case 2", with `Σc_j = 0`; Case 3A is Case 3 without the interaction. Matches the registry's `θ²_r = Σ(μ_rj − μ̄_r)²/(k−1)`, since Σc_j = 0 makes c_j = μ_rj − μ̄_r. Pagination basis for both: journal pagination printed on the page.
- 2026-07-19: T3 BLOCKER — five works cited by `ORACLES.md` source legs are not on the shelf: Lee & Vispoel (2024) Eqs. 8/25, Vispoel, Hong, Lee & Xu (2022), Cronbach et al. (1972), Brennan (2001). Two are load-bearing for O-SEM: Vispoel et al. (2022) is cited as its **external validation** pin (GENOVA/gtheory/SAS/SPSS agreement across 24 scales) and Lee & Vispoel (2024) as what *confirms* the uncorrected raw σ²_r that ADR-014 rests on. Their source legs cannot be verified without the PDFs; maintainer asked rather than guessed (memory: ask for inaccessible sources).
- 2026-07-19: CORRECTION to the T3 BLOCKER line above — it says "five works" and then lists **four**. Four is right: Lee & Vispoel (2024), Vispoel/Hong/Lee/Xu (2022), Cronbach et al. (1972), Brennan (2001). The grep returned five unique strings because the Vispoel 2022 chapter is cited under two renderings. The M70 don't-pin-a-count lesson, hit again in the same milestone that cites it.
- 2026-07-19: T3 remaining — the ten Hove legs (2022 Table 3 / Eqs. 8–14 / p. 6; 2020 §3.3/§4.1 half-t(4,0,1) prior, §4.2 percentile BCIs, §4 DGP) and McGraw & Wong Case 1, spanning ~20 entries. Note LESSONS 2026-07-18/M64: `tenhove2022.pdf` is advance-online with no journal pagination, so a "p. 6" anchor needs its basis stated.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
