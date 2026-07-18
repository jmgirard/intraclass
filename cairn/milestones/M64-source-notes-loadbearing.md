<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M64: Source notes — the ten load-bearing primary sources

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m64-source-notes-loadbearing` · PR #70   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Give each primary source the test suite already depends on its own
`<citekey>.md` source note, re-read from the PDF with page/table anchors.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** ten `<citekey>.md` source notes, each re-read from
`cairn/references/pdf/` per the maintainer's plan-gate choice (migrate **and**
deepen, not text-shuffle): `shrout1979`, `mcgraw1996`, `fleiss1973`, `koo2016`,
`jorgensen2021` (the O-SEM SEM absolute-error source), `tenhove2020`,
`tenhove2022`, `tenhove2024`, `tenhove2025a` (network data) and
`tenhove2025b` (planned incomplete) — the citekey pair assigned by M63/T1. Each carries the validation-doctrine fields: full
citation, extracted values with page/table anchors, verbatim-critical values
quoted exactly, what traces to it, open questions. `BIBLIOGRAPHY.md` entries
shrink to citation + pointer as their annotations move into the notes;
`INDEX.md` gains a line per note.

**Out:** the interval-methods / robustness cluster → M65; the foundational
shelf → M66; the ICC-equality-testing cluster → M67; **any change to an
oracle value** — a note that disagrees with `ORACLES.md` is a finding to
escalate, never a silent correction. Note `jorgensen2019` (planned-missing
efficiency) is a *different* paper and belongs to M66, not here.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: Ten `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with all five validation-doctrine fields
      populated and every extracted value carrying a page or table anchor.
- [x] AC2: Every value quoted in a note is verified against the PDF at the
      cited page — spot-checked at review against at least one value per note,
      with the check recorded in the Review section.
- [x] AC3: No oracle value in `ORACLES.md` changes. Any disagreement found
      between a re-read source and the registry is recorded in the work log and
      escalated at the review gate, not silently reconciled. (RB tripwire:
      no-oracle)
- [x] AC4: `BIBLIOGRAPHY.md` entries for the ten are reduced to citation +
      a pointer to the note (no duplicated extraction text), and `INDEX.md`
      carries one line per new note.
- [x] AC5: `cairn_validate` passes; the profile `verify` slot is clean
      (`NOT_CRAN=true CI=true`, failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Notes for the classical trio — `shrout1979`, `mcgraw1996`,
      `fleiss1973`. `shrout1979` is the O1 worked-example anchor
      (`tests/testthat/helper-shrout-fleiss.R`); anchor its table values
      exactly.
- [x] T2: Notes for the ten Hove family — `tenhove2020` (O-Bayes hyperprior
      DGP), `tenhove2022` (M5 multilevel estimand, Eqs. 6–7/12–13, Table 3),
      `tenhove2024` (selection guidelines), `tenhove2025b` (planned-incomplete;
      the ADR-002/003 engine + MC-CI basis), and `tenhove2025a` (network data).
      Note the metadata trap: `tenhove2022.pdf` carries a 2021 copyright
      line but is the 2022 *Psychological Methods* 27(4):650–666 paper.
- [x] T3: Notes for `koo2016` — the IP3-sensitive interpretation-band source;
      capture the "judge against the CI, not the point" guidance the
      `getting-started.Rmd` caveat rests on — and `jorgensen2021`, the O-SEM
      absolute-error source (Eq. 6 defines σ²_i as the raw variance of the
      effects-coded indicator intercepts).
- [x] T4: Cross-check each note's extracted values against the corresponding
      `ORACLES.md` entries; log agreements, escalate any disagreement.
- [x] T5: Trim the ten `BIBLIOGRAPHY.md` annotations to citation + pointer;
      add the `INDEX.md` lines.
- [x] T6: Run `cairn_validate` + the profile `verify` slot; open the PR and
      drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (gate: full extraction with a fresh PDF re-read, over a text-only migration).
- 2026-07-18: minor amendment by /milestone-implement M63 — `tenhove2025` becomes the `tenhove2025a`/`tenhove2025b` pair.
- 2026-07-18: amended by /milestone-review M63 — `jorgensen2021.pdf` present after all, so the O-SEM source joins: nine → ten notes, unblocked.
- 2026-07-18: /milestone-implement — status in-progress, branch `m64-source-notes-loadbearing` cut from main.
- 2026-07-18: implement gate — maintainer chose hybrid delegation (oracle anchors in-session, rest by [O] subagents), ukoumunne2003-depth notes, citation + one-clause role + pointer for the trim.
- 2026-07-18: T1 done — `shrout1979` in-session; `mcgraw1996`, `fleiss1973` by [O] subagents, diffs verified against the PDFs.
- 2026-07-18: T2 done — `tenhove2022` in-session; `tenhove2020`, `tenhove2024`, `tenhove2025a`, `tenhove2025b` by [O] subagents, diffs verified against the PDFs.
- 2026-07-18: T3 done — `jorgensen2021` in-session; `koo2016` by [O] subagent, verified against p. 161.
- 2026-07-18: T4 done — every note cross-checked against `ORACLES.md`; **no oracle value disagrees with any re-read source**, verified mechanically (`git diff main` on `ORACLES.md` and `tests/` is empty). Confirmed as printed: O1 Table 2/3/4 values, Case 3A `θ²_c = Σc²_j/(k−1)`, O-SEM Eq. 6 (raw, ÷ k−1, no bias correction), O-Bayes half-*t*(4,0,1) on SDs + DGP, and the tenhove2022 Eqs. 6–7/12–13 estimand.
- 2026-07-18: T4 escalations (AC3) — all attribution/citation-hygiene, no value change; substance in each note's `## Open questions`: `shrout1979` (Table 4 prints 2 dp, not the 3 dp the O1 helper header attributes to the paper) · `mcgraw1996` (possible uncorrected typo, Table 8 `MS_W` vs Appendix A `MS_E`) · `tenhove2020` (`ORACLES.md` cites §4.1.1–4.1.3, absent from the shelf manuscript; prior spec is §4.1/p. 7 not "§3.3/§4.1"; relative bias printed signed, not absolute; per-cell population ICCs 0.4950/0.4808 are repo-derived) · `tenhove2025b` (**ADR-003 sourcing gap** — it claims a boundary-respecting MC scale the paper does not describe; the paper's own example prints a negative variance CI limit, p. 1057) · `tenhove2024` (Figure 2's crossed-unbalanced cell prints a nested error term — confirmed independently at 300 dpi) · `koo2016` (band inclusivity ambiguous as printed; no issue number; Table 3 one-way row prints `(k+1)MS_W`) · `tenhove2025a` (round-robin designs out of scope by structure, though IP2's wording does not exclude them on its face).
- 2026-07-18: T4 coverage gap (tenhove2024) — the package implements no `ICC(Q,·)` and no `q` term; Figure 2 routes incomplete + relative there, while the package computes `ICC(C,k̂)`. Candidate milestone material, raised at the review gate, out of scope here.
- 2026-07-18: T5 done — the ten `BIBLIOGRAPHY.md` entries trimmed to citation + one-clause role + note pointer; **two were missing entirely and were added** (`fleiss1973`, and the 60(3) `tenhove2025a`), the ten Hove block reordered and given `2025a`/`2025b` suffixes; ten `INDEX.md` lines added and the shelf inventory updated (18 bibliography entries, 12 ingested).
- 2026-07-18: T6 done — `cairn_validate` all 15 checks pass (292 pre-existing dangling-id advisories, none in the new files); `NOT_CRAN=true CI=true devtools::test()` = FAIL 0 | WARN 2 | SKIP 23 | PASS 1802. PR #70 opened; all 11 CI checks green. Status → review.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

**Reviewed 2026-07-18.** Branch `m64-source-notes-loadbearing`, PR #70. `main`
had not moved since the branch was cut (`git log HEAD..origin/main` empty).

### Acceptance-criteria evidence

- **AC1 — ten notes, five doctrine fields, every value anchored. VERIFIED.**
  All ten `cairn/references/<citekey>.md` exist, exactly the ten named in Scope
  (checked by name against the Scope list; no substitution or omission). Each
  carries `**Citation.**`, `## Traces to`, `## Open questions`, and page/table/
  equation anchors — 37 (`shrout1979`) to 117 (`tenhove2020`) anchor tokens per
  note. Verbatim-critical values are quoted with page attribution throughout.
- **AC2 — every quoted value verified against the PDF at the cited page.
  VERIFIED**, at least one value per note, all ten: `shrout1979` Tables 2/3/4
  (pp. 423–424, full read) · `mcgraw1996` Table 1 Case 3 + the 1(4):390
  correction page · `fleiss1973` Eqs. 4–15 (pp. 615–617) · `koo2016` the p. 161
  boxed bands + the "not the ICC estimate itself" sentence · `jorgensen2021`
  Eq. 6 (p. 117) · `tenhove2020` the half-*t*(4,0,1)-on-SDs sentence and DGP
  (pp. 6–7) · `tenhove2022` Eqs. 6–7/12–13 + Table 3 (full read) ·
  `tenhove2024` Figure 2 (p. 8, re-rendered at 300 dpi) · `tenhove2025a`
  Eq. 16 + Table 2 + Eq. 19 (p. 449) · `tenhove2025b` the p. 1057 output block
  and p. 1050 MC-CI construction. The independent [O] reviewer re-verified the
  load-bearing subset against the PDFs and concurred.
- **AC3 — no oracle value changes. VERIFIED two ways.** *Mechanically:*
  `git diff main..HEAD -- cairn/references/ORACLES.md` and `-- tests/` are both
  empty; the diff touches only `cairn/`. *Substantively:* the [O] reviewer
  cross-read each note's asserted values against the corresponding registry
  entries and found no note asserting a value that contradicts one — including
  recomputing O2's mean-square chain and O-Bayes's per-cell population ICCs
  (0.4950 = 0.5/1.01, 0.4808 = 0.5/1.04, inside the paper's printed 0.48–0.83
  range). All seven T4 escalations are written as findings with explicit
  "not reconciled here" language; no silent correction was made.
- **AC4 — bibliography trimmed, INDEX complete. VERIFIED.** `BIBLIOGRAPHY.md`
  has exactly 18 top-level entries (matching the INDEX claim); all ten sources
  carry a note pointer; every one of the 17 non-`INDEX` pages in
  `cairn/references/` has an `INDEX.md` line; all relative markdown links in
  both files resolve to files that exist; the "12 ingested" claim matches disk.
  Extraction text was relocated into the notes, not duplicated.
- **AC5 — validation and verify slot clean. VERIFIED.** `cairn_validate` exit 0,
  15/15 PASS (292 dangling-id advisories, all pre-existing in `estimand-specs/`
  and `archive/`, none in the new files). `NOT_CRAN=true CI=true devtools::test()`
  = FAIL 0 | WARN 2 | SKIP 23 | PASS 1802. Consistency gate: `devtools::document()`
  produces no diff; no `R/`, `man/`, `NAMESPACE`, `DESCRIPTION`, `NEWS`, or
  `_pkgdown` file is touched, so the NEWS/pkgdown/`.Rbuildignore` clauses are
  N/A (`cairn/` is `.Rbuildignore`d). No `DESIGN.md` principle changed, so
  `cairn_impact` was correctly skipped.

### Independent review — three lenses + scorer

[O] diff-bug (4 findings) · [S] blame-history (1 finding) · [S] prior-PR-comments
(0 findings; clean no-op — PRs #68/#69 carry only codecov bot comments, and this
repo's review record lives in archived milestone files). Scored by a fresh [S]
agent that did not generate the findings.

**Actioned (score ≥ 80) — all three fixed on the branch:**

- **F1 (90) — `tenhove2022.md` self-contradicted on pagination.** "Traces to"
  said the nested Design-2 `ORACLES.md` entries "cite p. 6 of the journal
  pagination" while "Open questions" said the same citations use AOP pagination.
  Both cannot hold, and the journal runs pp. 650–666, so "journal p. 6" cannot
  exist. **Fixed:** both passages now state the AOP reading, with the
  verification recorded inline. This note is the pagination authority M65–M67
  will read, so the contradiction was load-bearing.
- **F2 (90) — `fleiss1973.md` shipped an open question its own milestone had
  already closed.** It escalated "No `BIBLIOGRAPHY.md` entry" as a tracking gap,
  but T5 added that entry in commit `5018cd5`; its "Traces to" grep claim was
  stale for the same reason. **Fixed:** the open question is struck through and
  marked resolved-within-M64; the grep claim now scopes to code/oracle paths.
- **F3 (88) — `tenhove2025a.md` had the identical defect.** Its "Sibling-key
  hygiene" question asked for the `2025a`/`2025b` disambiguation that T5 had
  already carried into `BIBLIOGRAPHY.md`, and its "zero matches" grep claim was
  stale. **Fixed:** same treatment as F2.

**Below threshold (score < 80) — logged, not actioned:**

- **F4 (74) — `shrout1979.md` rounding claim is imprecise.** "Every printed value
  is the correct 2-dp rounding of the corresponding registry value" holds against
  the unrounded 0.71484 (O2) but not against the registry's 3-dp 0.715, which
  rounds half-up to .72 where the paper prints .71. The conclusion ("no oracle
  value is contradicted") survives via the unrounded chain. Real but narrow;
  surfaced to the maintainer at the approval gate as an optional tightening.
- **F5 (32) — the "wrong-paper/year" breadcrumb was dropped, not migrated.** The
  pre-M64 `BIBLIOGRAPHY.md` ten Hove (2022) entry recorded that
  `choosing-an-icc.Rmd`'s "fifth choice" had been corrected in M5 Slice 2 from a
  wrong-paper reference; the trim removed it and it survives nowhere. The two
  reviewers split on this: blame-history called it lost institutional memory,
  diff-bug called it the intended consequence of AC4. The scorer sided with
  diff-bug — AC4 explicitly mandated removing exactly this kind of annotation,
  the vignette cites 2022 correctly today, and the underlying hazard (the
  © 2021 / 2022 metadata trap) is preserved more actionably in
  `tenhove2022.md`'s callout.

### Findings raised by the work itself (AC3 escalations)

Seven attribution/citation-hygiene findings and two source-internal errors are
recorded in the work log and in each note's `## Open questions`. Two warrant
maintainer attention beyond this milestone and are surfaced at the approval
gate: the **ADR-003 sourcing gap** (it describes a boundary-respecting MC scale
`tenhove2025b` does not describe) and the **`ICC(Q,·)`/`q` coverage gap** against
`tenhove2024`'s Figure 2. Neither is actionable inside M64's scope.
