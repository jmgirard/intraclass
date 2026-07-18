<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M65: Source notes — the interval-methods and robustness cluster

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m65-source-notes-interval-methods`   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Ingest the seven one-way-ICC interval-method and distributional-robustness
papers that the two open CI candidates will need as primary sources.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** seven `<citekey>.md` source notes, read cold from
`cairn/references/pdf/`: `xiao2013` (modified profile likelihood — already the
named source for the PL sibling candidate, cited 3× in tracking), `xiao2009`
(profile-likelihood CIs, common ICC), `saha2012` (profile-likelihood-based CI),
`saha2005` (bias-corrected MLE), `bhandary2006` (small-sample ICC inference),
`mehta2018` (ICC performance under various distributions), `bobak2018` (ICC
under common assumption violations). Each note states explicitly **which design
it covers** (one-way vs two-way, random vs fixed raters) — M62's implement gate
split off the PL sibling precisely because the sources proved design-specific.

**Out:** deciding GO/NO-GO on any interval method, or writing prototype code →
the "Profile-likelihood CI pass" and "Boundary-robust classical CI" candidate
rows, which this milestone feeds; the foundational + equality-testing papers →
the tier-C candidate row; the load-bearing sources → M64.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: Seven `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields and
      page/table anchors on every extracted value.
- [ ] AC2: Each note names its **design applicability** in a dedicated line —
      one-way vs two-way, random vs fixed raters, balanced vs unbalanced — so a
      later milestone cannot misapply a design-specific method (the M62 gate
      split).
- [ ] AC3: Each note whose paper reports coverage results extracts at least one
      citable reference table (coverage and/or width, with its cell definition)
      usable as a future frozen oracle, or states explicitly that the paper
      reports none.
- [ ] AC4: The `xiao2013` note is sufficient to plan the PL sibling pass
      without re-opening the PDF: the modified-profile-likelihood definition,
      the naive-PL under-coverage finding it documents, and its simulation
      design are all extracted with anchors.
- [ ] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [ ] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
      failed + error = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T1
- AC5 → T4
- AC6 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Notes for the profile-likelihood trio — `xiao2013`, `xiao2009`,
      `saha2012`. `xiao2013` first and in most depth; it is the named candidate
      source for the PL sibling pass.
- [x] T2: Notes for the estimator-bias pair — `saha2005`, `bhandary2006`.
- [ ] T3: Notes for the distributional-robustness pair — `mehta2018`,
      `bobak2018`; connect each to the GP6 known-failure axes the package
      already sweeps (near-zero ICC, few subjects, non-normality).
- [ ] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [ ] T5: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (the newly-added PDFs cluster hard on
  one-way-ICC interval methods — the direct feedstock for the two open CI
  candidates, so they were split out ahead of the foundational shelf).
- 2026-07-18: /milestone-implement started; branch
  `m65-source-notes-interval-methods` cut from `main`; all seven PDFs confirmed
  present on the shelf.
- 2026-07-18: T1 done — `xiao2013`, `xiao2009`, `saha2012` notes written cold
  from the PDFs. Headline: the three cover **three different designs**
  (two-way random interrater / familial multi-sample common ICC / binary
  beta-binomial), and naive PL under-covers only in `xiao2013` — so
  "PL under-covers for ICCs" is design-specific, vindicating the M62 gate split.
  `xiao2013`'s `κ_m` is calibrated only over ρ ∈ [0.6, 0.9], with no near-zero
  evidence at all.
- 2026-07-18: T2 done — `saha2005` (binary beta-binomial BCML; **no coverage
  results**, per AC3; §4-vs-Appendix-A contradiction on `var(φ̂_ML)` recorded,
  Appendix A correct) and `bhandary2006` (Gaussian familial `F_max`
  **equality test**, not an estimator-bias paper — belongs to the M67 cluster by
  subject; recorded in the note, no scope change). Table I of `saha2005` is
  per-cell published evidence that near-boundary non-convergence is
  estimand-intrinsic (~15 % acceptance at the worst cell).

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
