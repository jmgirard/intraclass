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
- [x] T3: verify the source-traceable entries — and the source leg of each
      mixed entry — against their cited sources: O1, O2 (hand-derived),
      O-OW, O-SEM and any others T2 surfaces. Where the source now has a
      verified `<citekey>.md` note from M69/M70/M71, check against the
      source itself, not the note.
- [x] T4: for each script-derived entry and the script leg of each mixed
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
- 2026-07-19: T3 blocker dispositioned (user gate) — the four off-shelf source legs marked unverified **in place**, as dated observations where a reader meets the claim (O-SEM's Lee & Vispoel confirmation and its Vispoel 2022 external-validation pin; O-Bayes-Rep's Cronbach/Brennan attribution), plus a ROADMAP candidate row to acquire the sources and close the gap. No claim was softened or deleted — the citation stands, its verification status is now stated.
- 2026-07-19: noted, not actioned — `cairn_validate` `record density` WARNs on `ROADMAP.md:4` (the accumulated hygiene-check narrative, 1,870 chars vs a <400 cap). Pre-existing and unrelated to M72's edits (confirmed by re-running against the stashed tree); the remedy is to replace that line in a hygiene pass, not to append. Left standing rather than reworded (LESSONS 2026-07-18/M68).
- 2026-07-19: session end — T1, T2, T5 done; T3 partial (3 of ~6 distinct source claims verified, 4 legs blocked and dispositioned). T4, T6, T7 not started. Branch pushed; safe to resume statelessly.
- 2026-07-19: T3 remaining — the ten Hove legs (2022 Table 3 / Eqs. 8–14 / p. 6; 2020 §3.3/§4.1 half-t(4,0,1) prior, §4.2 percentile BCIs, §4 DGP) and McGraw & Wong Case 1, spanning ~20 entries. Note LESSONS 2026-07-18/M64: `tenhove2022.pdf` is advance-online with no journal pagination, so a "p. 6" anchor needs its basis stated.
- 2026-07-19: T3 done — the remaining ten Hove and McGraw & Wong legs verified against the shelf PDFs. ten Hove (2022), AOP pages 1–17 (NOT journal 27(4):650–666 — basis now stated in the file, LESSONS 2026-07-18/M64): Eq. 7 five-component p. 5; Eqs. 8–9 Design 2 / Eqs. 10–11 Design 3 p. 5; Eqs. 12/13 + Table 3 p. 6; Eq. 14 p. 7; the "Designs 2/3 define no cluster-level IRR" and Design-3 "main rater variance cannot be estimated" claims p. 6. ten Hove (2020): half-t(4,0,1) on all random-effect SDs §4.1 p. 7; DGP/MCMC §4.1 pp. 6–8; the four reproduced findings §4.2 p. 9. McGraw & Wong (1996): Case 1 Tables 1/4/5 pp. 32/35/36; the SF notation bridge pp. 37–38.
- 2026-07-19: T3 recorded — a `## Source-leg verification` table added near the top of `ORACLES.md` listing each distinct source claim, its anchor, and its dated status, plus a pagination-basis paragraph. ~20 mixed entries share a handful of source claims, so anchoring them once beats a per-entry stamp that would trebled the file's prose; the four off-shelf legs keep their existing in-place unverified markings and appear in the table as the single not-verified row.
- 2026-07-19: T3 corrections (AC3 "corrected in place with the correction cited") — five citation defects fixed in `ORACLES.md`, no oracle value touched. (1) O-Bayes' "§4.1.1/§4.1.2/§4.1.3" anchors do not exist in this version of ten Hove (2020), which has only §4.1 Methods with unnumbered bold paragraph headings. (2) Its relative-bias form `|θ̄−θ|/θ` is printed **signed**, `(θ̄−θ)/θ` (p. 9). (3) O-PriorReduce's "§3.3/§4.1" prior anchor tightened: the numeric half-t(4,0,1) spec appears only at §4.1 p. 7; §3.3 p. 6 gives the df=4 rationale without location or scale. (4) O-Bayes-INML-clusters cited "Eqs. 8–11" for a Design-2-only entry; Eqs. 10–11 are Design 3, so the range is 8–9. (5) O-HPDI claimed the source "found percentile — not HPD — intervals give nominal coverage at k > 2", which overstates it: HPDIs were too wide for **σ_r** but nominal for ICC(A,1) at k > 2. Percentile remains the sourced default (their §5 names MAP + percentile + half-t + k>2 as best-performing) — the default is unchanged, only the reason was wrong.
- 2026-07-19: T3 finding — defects (1)–(3) and (5) were already flagged "Escalate" in the M69-verified `references/tenhove2020.md`, which owns that source but not `ORACLES.md`. Independent re-reading of the PDF confirmed all four before any edit; the source note was the pointer, never the evidence (D-008 source-traceable rule). Defect (4) and the notation-bridge verification are new to M72.
- 2026-07-19: T3 strengthening — `σ²_s = 0.5` is **not printed** in ten Hove (2020): the μ_s draw reads `N(0, σ²_sr = ½)`, an evident subscript typo. `tenhove2020.md` (M69) concluded a clean anchor "would still have to come from the OSF code". It does not: the source's own printed population-ICC range "0.48 to 0.83" (p. 7) is reproduced exactly as [0.4808, 0.8306] by σ²_s = σ²_sr = ½ over the k and σ²_r levels, and σ²_s = 1 would give a minimum of 0.649. The value is now pinned by the paper itself. Settled by 400-dpi crop render, the text layer garbling the fractions.
- 2026-07-19: T3 out-of-scope sighting (not actioned) — `cairn/estimand-specs/M36-incomplete-fixed-nested.md:212` carries the same Design-2 "Eqs. 8–11" over-cite as defect (4). Outside M72's Scope (ORACLES.md + BIBLIOGRAPHY.md + the SF helper); reported rather than swept in.
- 2026-07-19: T4 in progress — every `data-raw/` script path named by an entry re-confirmed present on disk. Of the cited scripts, most write a committed fixture under `tests/testthat/fixtures/`; the remainder are exactly the set D-008 Amdt 1 named, independently re-derived here rather than taken from the amendment. Of that remainder, `oracle-sem.R` carries an inline expected value (`stopifnot(abs(s2_r - s2_r_hand) < 1e-6) # 5.4144`, matching O-SEM's cited 5.4144) and `oracle-fixed-incomplete.R` carries hardcoded expected constants, so both clear AC4's inline-value bar; the others assert only *relationships* (cross-engine agreement, monotonicity, population recovery) or print via `cat()` with no assertion at all, so their entries take the honest **script-attested, values not independently confirmed** status. Counts deliberately not pinned (AC4, LESSONS 2026-07-19/M70).
- 2026-07-19: T4 fixture pass — every fixture-backed entry's transcribed values compared field-by-field against the committed `.rds` (DGP parameters, seed, n_rep, convergence, coverage, relative bias, containment). All agree to the displayed precision **except O-Bayes** — see the discrepancy line below. Several entries (O-Bayes-Conflated, O-Bayes-Rep) deliberately transcribe no decimals and state only qualitative pins; those have no value to falsify and are the pattern that made the O-Bayes drift possible elsewhere.
- 2026-07-19: T4 DISCREPANCY (D-008 escalation, not actioned) — O-Bayes' "Committed reference" line disagrees with `tests/testthat/fixtures/bayesian-oracle.rds` on every statistic it transcribes. Registry says k=5 conv .992 / coverage .948 / EAP σ_r +.741 / MAP σ_r −.147 and k=2 conv .924 / MAP ICC rel-bias −.243 / coverage .912 / EAP σ_r +3.60 / MAP σ_r −.318; the committed fixture holds .996 / .956 / +.746 / −.145 and .904 / −.259 / .916 / +3.67 / −.365. DGP, seed (20200) and n_rep (250) match, so this is not a different design — it reads as prose written from one run and a fixture from another. **No test fails**: `test-icc-brms.R` asserts only the qualitative pins against the fixture (converged ≥ .90, |MAP rel-bias| < .10, EAP > MAP + .10), never these decimals — which is why it went unseen. All four qualitative findings still hold on the committed numbers. D-008 forbids resolving this by re-running the script; escalated to the maintainer.
- 2026-07-19: T4 SECOND FINDING (scope question, not actioned) — the registry is **incomplete**, not merely stale. Oracles asserted in the suite have no entry at all: `O-cluster-ck` / `O-cluster-ck-cover` (M46) and `O-Bayes-cluster-ck` (M47), whose two committed fixtures (`cluster-ck-coverage-oracle.rds`, `bayesian-cluster-ck-oracle.rds`) are referenced nowhere in `ORACLES.md`; the `O-SEM-ML*` lavaan-multilevel family; and others (`O-Boot-DS`, `O-IDS`, `O-invariance`). Consistent with the file's own header, which says entries span M1–M39 — the registry stopped being maintained around M39 while oracles kept shipping. This contradicts the registry's stated invariant ("**Every oracle value in the test suite must trace back to an entry here**") and, worse, some existing entries now describe cluster `ICC(c,k)` as "open"/"dropped" on incomplete data, which M46/M47 appear to have closed. Writing the missing entries is outside M72's Scope (verify the 39 + 38 that exist) and is milestone-sized; surfaced for the maintainer rather than absorbed.
- 2026-07-19: T4 discrepancy RESOLVED (user gate) — O-Bayes' transcribed values corrected in place to the committed fixture, with the superseded figures quoted in the correction note and the reason the script was not re-run stated. The maintainer first asked whether a PDF could settle it; it cannot — the disputed digits are the repo's own brms output, and the source reports only figures with no tabulated per-cell values (`tenhove2020.md`: "exact per-cell numbers require OSF `shkqm`"). The maintainer then proposed re-running instead; declined on the argument that a run today yields a *third* set rather than adjudicating prose-vs-fixture, and that the action it leads to (overwrite fixture, rewrite prose) is the chosen option plus an expensive detour that also discards the one artifact with evidence behind it. Accepted, with the reproducibility work split to its own candidate.
- 2026-07-19: T4 second finding RESOLVED (user gate) — two ROADMAP candidate rows added, M72's scope held. (a) Complete the oracle registry: write entries for the oracles shipping without one (M46/M47 cluster-ck, the `O-SEM-ML*` family, `O-Boot-DS`, `O-IDS`, `O-invariance`) and reconcile the entries M46/M47 made stale about cluster `ICC(c,k)`. (b) Re-run the seeded scripts to re-establish reproducibility, sized per script as background work, with an engine-version delta recorded beside each fixture and the meaning of a divergence decided before running. Search-first applied: neither overlaps an existing candidate, an archived milestone, or a D-entry.
- 2026-07-19: verify slot — first `devtools::test()` invocation was made WITHOUT `CI=true`, so the `skip_on_ci` brms tests began live Stan compiles and the run was still going after ~35 min; killed and re-run as `NOT_CRAN=true CI=true` ([[brms-live-fit-skip-on-ci]], [[skip-on-cran-tests-need-not-cran-true]]). The prior session's log records the correct invocation; this session reconstructed it from memory instead of reading that line.
- 2026-07-19: T4 done — every script leg now either confirmed against a committed artifact or honestly stamped. Confirmed: the fixture-backed entries field-by-field (above); `oracle-sem.R`'s inline expecteds (`# 5.4144`, `# Expected: A1=0.2843 Ak=0.6137 C1=0.7148 Ck=0.9093`) against O-SEM's cited figures; `oracle-fixed-incomplete.R:79-82`'s hardcoded 0.290/0.620/0.715/0.909 against O6; and the in-suite legs, whose values are asserted as literals in the named test files (ADR-015 makes the test file the asserted-state authority, and T5 already stamped the SF two-decimal provenance beside them). Stamped **script-attested, values not independently confirmed** with the reason specific to each: O-DS (`cat()` only, no assertion), O-ML (every `stopifnot` checks a relationship, never a literal), O5/`oracle-incomplete.R` (targets computed from an independent lme4 fit at run time), and the O4 fixed-vs-random entry (no `stopifnot` at all).
- 2026-07-19: CORRECTION to this log's own handling — the "T3 remaining" line above was briefly rewritten in place (prefix changed to "T3 superseded") while appending the T3 results. That edits history, which IP4 and the append-only rule forbid; the line was restored verbatim to its original position and this note records the slip rather than hiding it. The same-turn nature of the mistake is why nothing downstream read the altered text.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
