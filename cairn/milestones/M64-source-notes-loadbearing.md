<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M64: Source notes — the ten load-bearing primary sources

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m64-source-notes-loadbearing`   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [ ] AC1: Ten `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with all five validation-doctrine fields
      populated and every extracted value carrying a page or table anchor.
- [ ] AC2: Every value quoted in a note is verified against the PDF at the
      cited page — spot-checked at review against at least one value per note,
      with the check recorded in the Review section.
- [ ] AC3: No oracle value in `ORACLES.md` changes. Any disagreement found
      between a re-read source and the registry is recorded in the work log and
      escalated at the review gate, not silently reconciled. (RB tripwire:
      no-oracle)
- [ ] AC4: `BIBLIOGRAPHY.md` entries for the ten are reduced to citation +
      a pointer to the note (no duplicated extraction text), and `INDEX.md`
      carries one line per new note.
- [ ] AC5: `cairn_validate` passes; the profile `verify` slot is clean
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
- [ ] T4: Cross-check each note's extracted values against the corresponding
      `ORACLES.md` entries; log agreements, escalate any disagreement.
- [ ] T5: Trim the ten `BIBLIOGRAPHY.md` annotations to citation + pointer;
      add the `INDEX.md` lines.
- [ ] T6: Run `cairn_validate` + the profile `verify` slot; open the PR and
      drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (plan gate: maintainer chose full
  extraction with a fresh PDF re-read for the load-bearing sources, over a
  text-only migration of the existing bibliography annotations).
- 2026-07-18: minor amendment by /milestone-implement M63 — `tenhove2025`
  becomes the `tenhove2025a`/`tenhove2025b` pair (M63 implement gate).
- 2026-07-18: amended by /milestone-review M63 — `jorgensen2021.pdf` is present
  after all (M63's "no PDF" record was wrong), so the O-SEM source joins this
  milestone: nine → ten notes, no longer blocked.
- 2026-07-18: /milestone-implement — status in-progress, branch
  `m64-source-notes-loadbearing` cut from main.
- 2026-07-18: implement gate — maintainer chose: hybrid delegation (oracle
  anchors read in-session, the rest by [O] subagents), ukoumunne2003-depth
  notes, and citation + one-clause role + pointer for the BIBLIOGRAPHY trim.
- 2026-07-18: T1 done — `shrout1979` (read in-session), `mcgraw1996`,
  `fleiss1973` (both [O] subagents, diffs verified against the PDFs).
- 2026-07-18: T4 finding (shrout1979) — Table 4 (p. 424) prints the six ICCs to
  **two** decimals; O1 and `helper-shrout-fleiss.R` carry three and the helper
  header calls them "the published Shrout & Fleiss numbers to three decimals".
  Values agree at the paper's precision; the third decimal traces to
  `psych`/`DescTools`, not the paper. No oracle value changes — attribution
  wording only, escalated to the review gate per AC3.
- 2026-07-18: T4 finding (mcgraw1996) — Case 3A `θ²_c = Σc²_j/(k−1)` confirmed
  verbatim (Table 1, p. 32); agrees with the repo's `θ²_r` (symbol differs,
  quantity and divisor identical). Published correction (1(4):390) present as
  the PDF's final page and extracted. No ORACLES.md disagreement.
- 2026-07-18: T4 finding (mcgraw1996) — possible **uncorrected** typo in the
  paper: Table 8 (p. 42) Type-C Type-k F renders `MS_W` where Appendix A §A4
  (p. 44) derives `MS_E`. Not in the published correction. Package impact
  believed nil (no test cites Table 8); recorded for the review gate, not
  reconciled.
- 2026-07-18: T3 done — `jorgensen2021` (read in-session) and `koo2016` ([O]
  subagent, verified against p. 161).
- 2026-07-18: T2 done — `tenhove2022` read in-session; `tenhove2020`,
  `tenhove2025b`, `tenhove2025a`, `tenhove2024` by [O] subagents, diffs verified
  against the PDFs.
- 2026-07-18: T4 finding (tenhove2024) — **source-internal discrepancy,
  confirmed independently** by re-rendering Figure 2 (p. 8) at 300 dpi: the
  crossed·absolute·average·**unbalanced** terminal cell prints the error term
  `σ²_r:s/k̂` — the *nested* component — where its balanced sibling prints
  `(σ²_r + σ²_sr)/k`, and Table 2 / Eq. 18 give a `σ²_r`/`σ²_sr` form. That cell
  also carries the paper's footnote e ("ICC has not been defined in the
  literature"). The package follows Eq. 18; no oracle value affected. Escalate,
  do not reconcile.
- 2026-07-18: T4 finding (tenhove2024) — **coverage gap, not a defect.** The
  paper's updated flowchart routes incomplete + relative to `ICC(Q,k̂)` (with the
  nonoverlap proportion `q`, Eq. 17); the package implements no `ICC(Q,·)` and no
  `q` term anywhere in `R/` or the estimand specs, computing `σ²_res/k_eff` —
  i.e. `ICC(C,k̂)`, a cell Figure 2 does not offer for incomplete data. Candidate
  milestone material; raised at the review gate, out of scope here.
- 2026-07-18: T4 note (tenhove2024) — the paper *supports* the package's
  no-verdict posture (it proposes no cut-offs, p. 2) and demotes fixed raters
  ("rarely—if ever—appropriate", p. 3), which `R/abort.R::warn_fixed_raters()`
  already cites. One recommendation the package may not meet: report **all**
  variance components, not only the ICC (p. 11) — flagged for review against
  `print()`/`tidy()` output.
- 2026-07-18: T4 finding (jorgensen2021) — Eq. 6 (p. 117) confirmed verbatim:
  `σ̂²_i = (1/(n_i−1))·Σν̂²_i`, the **raw** variance of the effects-coded
  intercepts, no bias correction anywhere in the paper. Matches O-SEM exactly.
  Bonus: p. 124 documents the SEM-vs-mixed-model discrepancy-function gap that
  explains O-SEM's recorded 0.284-vs-0.290 agreement difference.
- 2026-07-18: T4 finding (tenhove2025b) — **ADR-003 sourcing gap, escalate.**
  ADR-003 describes the MC draws as taken "on the engine's internal
  (boundary-respecting) scale"; the paper names **no** transformation (pp. 1047,
  1050, 1057) and its own printed example gives a **negative** lower CI limit for
  the rater variance (`S_r` CI [−0.5495179, 2.732752], p. 1057). The package's
  log-SD-scale non-negative variant is a *departure from* the sourced method, not
  a restatement of it. No oracle value implicated; no change proposed here.
- 2026-07-18: T4 finding (tenhove2020) — half-*t*(4,0,1) on random-effect **SDs**
  (not variances) confirmed verbatim (p. 7); DGP N=30, σ²_r ∈ {.01,.04},
  k ∈ {2,3,5} confirmed. Corrections to repo wording, all escalate-not-edit:
  (a) `ORACLES.md` anchors §4.1.1/§4.1.2/§4.1.3, which **do not exist** in the
  shelf PDF (an author manuscript with only §4.1/§4.2) — content matches,
  numbering unattested; (b) the prior spec lives at §4.1/p. 7, not
  `BIBLIOGRAPHY.md`'s "§3.3/§4.1"; (c) `ORACLES.md` writes relative bias as
  `|θ̄−θ|/θ`, the paper prints the signed `(θ̄−θ)/θ` (p. 9); (d) the per-cell
  population ICCs 0.4950/0.4808 are repo-derived, not printed (the paper gives
  only the range 0.48–0.83, p. 7) — they fall inside it, so no disagreement.
  Also: inverse-gamma is *discussed and rejected* (§3.2), never simulated.
- 2026-07-18: T4 finding (koo2016) — the CI-not-point guidance confirmed verbatim
  (p. 161): the 95% interval "should be used as the basis to evaluate the level of
  reliability", not the point estimate. Bands confirmed as printed, with an
  **inclusivity ambiguity the paper never resolves**: poor is strict `< 0.5`,
  excellent strict `> 0.90`, but moderate/good are only "between 0.5 and 0.75" /
  "between 0.75 and 0.9" — so an ICC of exactly 0.90 falls in no band as written.
  Also: the paper prints no issue number (repo cites "15(2)"); Table 3's one-way
  single-rater row prints `(k+1)MS_W` where every sibling row has `(k−1)`
  (nothing in the repo cites it); Fig. 1's one-way branch dead-ends. All escalate,
  none reconciled.
- 2026-07-18: T4 finding (tenhove2025a) — the network paper's RESRM is a
  **seven**-component decomposition (Eq. 16, p. 449) splitting the subject facet
  into actor/partner/relationship, with consistency-only ICCs (Table 2, p. 449);
  agreement and fixed raters explicitly discarded. Nothing in the repo traces to
  it — shelf evidence only. Its own authors warn the ICCs "cannot be trusted for
  designs with few raters and small subgroups of subjects" (p. 455). Contract
  boundary: out of scope by design *structure*, though IP2's wording does not on
  its face exclude it — logged as a boundary question for the review gate.
- 2026-07-18: T5 input (tenhove2025a) — `BIBLIOGRAPHY.md`'s single "ten Hove …
  (2025)" entry is the 60(5) paper; the 60(3) network paper has no entry at all.
  T5 must add one and carry the `2025a`/`2025b` disambiguation into the file.
- 2026-07-18: T5 input (fleiss1973) — the source has an `INDEX.md` line but **no**
  `BIBLIOGRAPHY.md` entry; T5 must add one rather than trim. Nothing in `R/`,
  `tests/`, `vignettes/`, or `ORACLES.md` traces to it (shelf evidence only).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
