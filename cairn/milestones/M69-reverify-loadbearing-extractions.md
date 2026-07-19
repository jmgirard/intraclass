<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M69: Re-verify the ten load-bearing source extractions

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M68   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; no DESIGN.md IP/GP — governed by PRINCIPLES.md #1 (oracle-first), #4 (no fabricated reference values), #12 (seeded and sourced) -->
- **Branch/PR:** `m69-reverify-loadbearing-extractions`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Re-read M64's ten load-bearing sources against their shelf PDFs, correct any
mis-extracted value in place, and upgrade each note's extraction status from
unverified to a dated verified.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the ten notes M64 authored — `fleiss1973`, `jorgensen2021`, `koo2016`,
`mcgraw1996`, `shrout1979`, `tenhove2020`, `tenhove2022`, `tenhove2024`,
`tenhove2025a`, `tenhove2025b`. For each: re-read the shelf PDF at
`cairn/references/sources/<citekey>.pdf` **to its final page** (the M65
`mehta2018` lesson — appendices can follow the reference list), confirm or
correct every extracted value against its page/table anchor, correct wrong
values in place with the correction marked, and upgrade `Extraction:` to
`verified YYYY-MM-DD against the source — observed YYYY-MM-DD`. These ten are
first because oracle values trace to them (`ORACLES.md`), so an extraction error
here is a #1/#4 problem, not a documentation one.

**Out:** the other nine notes (M65's seven, M62's `ukoumunne2003` and
`ohyama2025`) → the ROADMAP candidate row; the eleven notes M66/M67 author →
verified at authoring time by those milestones, per M68's amendment. Any change
to package **code, tests, or an `ORACLES.md` entry** that a discovered error
implies → escalated as its own milestone with the finding recorded here; this
milestone corrects notes, never the estimator surface.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Every extracted value in the ten notes is re-read against its shelf
      PDF and its page/table anchor confirmed, or corrected in place with the
      correction marked (`(M64, corrected M69)`) per the corrections rule.
- [ ] AC2: Each of the ten PDFs is read to its final page, and no note asserts
      an absence that was not actually checked; the work log records the page
      count read per source (the M65 `mehta2018` failure mode).
- [ ] AC3: Each of the ten `Extraction:` statuses is upgraded to a dated
      verified status on one physical line, and `cairn_validate`'s
      `references staleness` advisory no longer names any of the ten.
- [ ] AC4: Any discrepancy touching a value an `ORACLES.md` entry or a test
      depends on is recorded verbatim in the work log as an escalation finding,
      with the affected oracle ID and test named — never silently changed.
- [ ] AC5: `cairn_validate` exits 0, and the profile `verify` slot is clean
      (`NOT_CRAN=true CI=true`, failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T4
- AC4 → T4
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Re-verify the classical trio — `shrout1979` (the **O1** worked
      example, Tables 2–4, two-decimal printing), `mcgraw1996` (the Case-3A
      θ²_c formula and the published correction at 1(4):390), `fleiss1973`
      (squared-weight kappa ≡ the k = 2 agreement ICC).
- [ ] T2: Re-verify `jorgensen2021` (the **O-SEM** source: Eq. 6's σ²_i, the
      p. 124 SEM-vs-mixed-model gap) and `koo2016` (the interpretation bands and
      the p. 161 judge-against-the-CI guidance, whose band inclusivity the note
      records as ambiguous — confirm that reading).
- [ ] T3: Re-verify the ten Hove quartet — `tenhove2022` (Eqs. 6–7, 12–13,
      Table 3), `tenhove2024` (Figure 2 flowchart, `k̂`/`q`), `tenhove2020`
      (half-*t*(4,0,1) hyperpriors, MAP-over-EAP), `tenhove2025a`/`tenhove2025b`.
      Convert every anchor explicitly against the stated pagination basis —
      three of these are not the version of record (M64 lesson); crop figures at
      300 DPI with `pdftoppm` where a claim sits inside one.
- [ ] T4: Upgrade the ten extraction statuses; record any oracle-affecting
      discrepancy as an escalation finding (AC4); run `cairn_validate` and the
      profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan, split from M68 at the plan gate — the maintainer chose to re-verify the load-bearing ten rather than leave every extraction unverified; the remaining nine stay a candidate row.
- 2026-07-18: implement gate — maintainer chose main-session re-reading for all ten (no subagent delegation; a subagent blessing a subagent's extraction recycles M64's failure mode), and chose to record the shrout1979 helper-header attribution finding as an AC4 escalation rather than amend Scope to touch a test file.
- 2026-07-18: T1 done. shrout1979 read 9/9 pages (printed 420–428); 4 corrections — Table 1 Within-target row had Case-2/Case-3 EMS as `—` where the paper prints `σ²_J+σ²_I+σ²_E` and `θ²_J+fσ²_I+σ²_E` (the footnote's "last three entries" only parses with the cell filled), footnote paraphrase, inverted Spearman–Brown star notation, and a `σ²_J = θ²_J` equality the paper does not assert; Table 4 ICC(1,4) cell has an ink blot in the scan, `.44` confirmed arithmetically from Table 3.
- 2026-07-18: T1 — mcgraw1996 read 18/18 pages (printed 30–46 + the 1(4):390 correction); Case-3A θ²_c and the ICC(A,1) estimand confirmed verbatim; 3 corrections — Table 4 was missing the Case-2A ICC(A,1) row, Table 7's numerator/denominator df swap between lower and upper limits was unrecorded, and M64's "possible" Table 8 `MS_W`-vs-`MS_E` typo is now confirmed against Appendix A section A4 (uncorrected in the literature; package implements no Table 8 statistic).
- 2026-07-18: T1 — fleiss1973 read 7/7 pages (printed 613–619); clean, no value correction — Eqs. 1–15, all page anchors and quoted phrases confirmed, "no worked example in the paper" verified through the reference list; dated the previously-undated repo-grep absence claim in "Traces to" per the dated-observations rule (grep re-run, still no hits).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
