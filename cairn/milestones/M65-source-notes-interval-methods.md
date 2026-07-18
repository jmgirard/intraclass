<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M65: Source notes — the interval-methods and robustness cluster

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** M63   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** IP1, GP6   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m65-source-notes-interval-methods` · https://github.com/jmgirard/intraclass/pull/71   <!-- owner: implement (branch) / review (PR URL) · create -->

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

- [x] AC1: Seven `cairn/references/<citekey>.md` source notes exist, one per
      source named in Scope, each with the five validation-doctrine fields and
      page/table anchors on every extracted value.
- [x] AC2: Each note names its **design applicability** in a dedicated line —
      one-way vs two-way, random vs fixed raters, balanced vs unbalanced — so a
      later milestone cannot misapply a design-specific method (the M62 gate
      split).
- [x] AC3: Each note whose paper reports coverage results extracts at least one
      citable reference table (coverage and/or width, with its cell definition)
      usable as a future frozen oracle, or states explicitly that the paper
      reports none.
- [x] AC4: The `xiao2013` note is sufficient to plan the PL sibling pass
      without re-opening the PDF: the modified-profile-likelihood definition,
      the naive-PL under-coverage finding it documents, and its simulation
      design are all extracted with anchors.
- [x] AC5: `BIBLIOGRAPHY.md` gains an entry per source; `INDEX.md` carries one
      line per note; `cairn_validate` passes.
- [x] AC6: The profile `verify` slot is clean (`NOT_CRAN=true CI=true`,
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
- [x] T3: Notes for the distributional-robustness pair — `mehta2018`,
      `bobak2018`; connect each to the GP6 known-failure axes the package
      already sweeps (near-zero ICC, few subjects, non-normality).
- [x] T4: Add `BIBLIOGRAPHY.md` entries + `INDEX.md` lines; run
      `cairn_validate`.
- [x] T5: Run the profile `verify` slot; open the PR and drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-07-18: created by /milestone-plan (the newly-added PDFs cluster hard on
  one-way-ICC interval methods — the direct feedstock for the two open CI
  candidates, so they were split out ahead of the foundational shelf).
- 2026-07-18: /milestone-implement started; branch `m65-source-notes-interval-methods` cut from `main`; all seven PDFs confirmed on the shelf.
- 2026-07-18: T1 done — `xiao2013`/`xiao2009`/`saha2012` notes written cold; they cover three different designs, and naive PL under-covers only in `xiao2013`, so PL's calibration is design-specific (vindicates the M62 gate split).
- 2026-07-18: T2 done — `saha2005` (binary BCML, no coverage results; §4-vs-Appendix-A contradiction on `var(φ̂_ML)` recorded) and `bhandary2006` (Gaussian familial `F_max` equality test, M67 territory by subject; no scope change).
- 2026-07-18: T3 done — `mehta2018` and `bobak2018`, the only two M65 sources inside the contract boundary; neither reports coverage; both converge on ICC tracking subject heterogeneity rather than instrument quality.
- 2026-07-18: T4 done — 7 `BIBLIOGRAPHY.md` entries + 7 `INDEX.md` lines; shelf inventory 12 → 19 ingested; `cairn_validate` all checks passed.
- 2026-07-18: out-of-scope hygiene (logged, not swept) — `ukoumunne2003` and `ohyama2025` had M62 source notes but no `BIBLIOGRAPHY.md` entry; both added.
- 2026-07-18: MD-1 recorded — the Goal's "one-way-ICC interval-method" premise is false; Goal deliberately not edited (plan-owned), no AC changed.
- 2026-07-18: T5 done — `NOT_CRAN=true CI=true devtools::test()` `FAIL 0 | WARN 2 | SKIP 23 | PASS 1802`; PR #71 opened, CI green on all 11 checks; status → review.
- 2026-07-18: review — three-lens fan-out returned 7 findings; scorer actioned 6 (F1 95, F3 92, F7 92, F4 90, F2 88, F5 88) and logged F6 (74) below threshold. All 6 fixed on the branch; details in the Review section.
- 2026-07-18: review — work-log entries compressed to one line each after `cairn_validate` flagged 36 multi-line entries (tracking-rules "Work-log entries are one line each").

## Decisions
<!-- owner: implement / review · append-only -->

### MD-1 (2026-07-18): the Goal's "one-way-ICC interval-method" premise is false; the notes stand, the Goal is not edited

**Context.** The Goal calls these "the seven one-way-ICC interval-method and
distributional-robustness papers". Reading all seven cold refuted that on both
counts. Design: three are **two-way** (`xiao2013`, `mehta2018`, `bobak2018`), two
are **binary** beta-binomial (`saha2012`, `saha2005`), one is a **familial
multi-sample** common ICC (`xiao2009`), one is a **hypothesis test** rather than
an estimator or interval (`bhandary2006`). Inferential target: four report no
confidence interval at all (`saha2005`, `bhandary2006`, `mehta2018`, `bobak2018`).
Only `xiao2013` is a primary source either open CI candidate can actually use,
and only `mehta2018`/`bobak2018` sit inside the contract boundary.

**Decision.** The Goal is **not** edited — it is plan-owned and "a wrong goal
returns to plan, never edited in place" — and this milestone is **not** returned
to `/milestone-plan`. The Goal's *operative* intent (ingest these seven named
sources; establish what each covers) was delivered in full, and AC2 exists
precisely to surface design-specificity, so the refutation is the milestone's
intended product rather than a failure of it. The correction is recorded here,
in each note's "Design applicability" table, and in `INDEX.md`'s shelf inventory.

**Consequences.** No acceptance criterion changes; all six stand as written.
Future readers must not infer scope from the Goal sentence — `INDEX.md` and the
per-note tables are authoritative on what each source covers. The PL sibling
candidate should cite `xiao2013` only, and inherits that paper's `ρ ∈ [0.6, 0.9]`
calibration fence. `bhandary2006` should be read with the M67 cluster.

## Review
<!-- owner: review · exclusive -->

Reviewed 2026-07-18. Branch `m65-source-notes-interval-methods`, PR #71,
diffstat 11 files / +1819 −18 (docs-only, all under `.Rbuildignore`d `cairn/`).
`main` had not moved since the branch was cut — no merge needed.

### Acceptance-criteria evidence

- **AC1 (seven notes, five doctrine fields, anchors).** All seven files exist on
  disk. Each carries citation, anchored extractions, verbatim quotes, a
  "Traces to" section, and "Open questions". The [O] diff-bug reviewer
  independently spot-checked transcriptions against the PDFs — `xiao2009`
  Table 1 in full (72 cells), `bhandary2006` Table 2 in full (27 cells),
  `saha2012` Table I at m=19 and m=73, `saha2005` Tables I/III/IV, `mehta2018`
  Tables 2–7/9, `bobak2018` Tables 2–5, `xiao2013` Tables 2/3/4/6 and all five
  worked examples — and found **zero errors in the numeric transcriptions**.
  Five defects in derived prose were found and fixed (F1–F5 below). **PASS.**
- **AC2 (design applicability named).** Every note opens with a "Design
  applicability" table naming design, raters, balance, and coefficient. Reviewer
  verified the three hardest claims against the PDFs: `xiao2013` Eq. (1) truly
  has no interaction term; `mehta2018` Eq. (3) is exactly Shrout–Fleiss
  `ICC(2,1)`; `bobak2018` is genuinely fixed-rater *consistency* (β₁ rater
  contrast; p. 9 "emphasizing consistency"). **PASS.**
- **AC3 (coverage table or explicit "reports none").** `xiao2013` (Tables 4/6
  with cell definitions), `xiao2009` (Table 1 in full), `saha2012` (Tables I–III
  slices) extract coverage tables. `saha2005`, `mehta2018`, `bobak2018` each
  carry an explicit "reports **no coverage results**" statement. `bhandary2006`
  extracts Table 2 (size) and Table 1 (power) but did **not** carry the explicit
  "no coverage/width" sentence — logged as F6 (scored 74, below the action
  threshold). Judged **PASS**: the criterion's disjunction is satisfied by the
  extracted reference table; F6 is a consistency-of-presentation gap, not a
  missing criterion element.
- **AC4 (`xiao2013` sufficient to plan the PL pass).** The note carries the MPL
  definition (Eq. 11 with `κ_m`), the naive-PL under-coverage finding quoted from
  four places including the 0.796 worst cell, and the full simulation design
  (`R∈{3,5}`, `S∈{10,25,50}`, `σ²_r/σ²_e∈{0.5,1,4}`, `ρ∈{0.60,0.75,0.90}`,
  20 000 samples). Adds the load-bearing `ρ_L = 0.6` calibration fence. **PASS.**
- **AC5 (BIBLIOGRAPHY + INDEX + `cairn_validate`).** `BIBLIOGRAPHY.md` = 27
  entries by count (18 + 7 M65 + `ukoumunne2003` + `ohyama2025`); INDEX's stated
  count matches. Each of the seven citekeys appears exactly once in `INDEX.md`.
  `cairn_validate`: **all 15 checks PASS** including `references index<->disk`
  and `coverage complete`. **PASS.**
- **AC6 (profile `verify` slot clean).** `NOT_CRAN=true CI=true
  devtools::test()` → `FAIL 0 | WARN 2 | SKIP 23 | PASS 1802`; failed + error
  = 0. PR #71 CI green on all 11 checks (R CMD check macOS/Windows/ubuntu
  release+devel+oldrel-1, format-check, lint, pkgdown, test-coverage,
  codecov patch+project). **PASS.**

### Consistency gate

`cairn_validate` all 15 checks PASS. Advisory only: 292 dangling-id tokens
(pre-existing, stale milestone ids from rotated-out ROADMAP rows) and 50
work-log format warnings, 36 of them M65's own multi-line entries — those were
compressed to one line each in this review. No `DESIGN.md` principle changed, so
`cairn_impact` was skipped per the gate's conditional. Toolchain
`consistency-gate` slot: docs-only diff touches no R source, `NAMESPACE`, `man/`,
`_pkgdown.yml`, or `NEWS.md`; `document()`/pkgdown/README checks are no-ops here
and the full `R CMD check` matrix ran green on PR #71.

### Independent review — three lenses + scorer

[O] diff-bug (Opus, verified transcriptions against all seven PDFs): 6 findings.
[S] blame-history (Sonnet): **0 findings** — confirmed INDEX's 12→19 count is
arithmetically right, BIBLIOGRAPHY 18→27 correct with alphabetical order held at
every insertion point, D-006/D-007 characterizations faithful, and the one
revised premise handled on the record via MD-1 rather than silently.
[S] prior-PR-comments (Sonnet): 1 finding — a repeat of M64's F2/F3 pattern.
(No inline PR review comments exist on GitHub for #68–#71; this repo's review
record lives in archived milestone files, as M64 also recorded.)

[S] scorer (fresh agent, did not generate the findings) — **6 actioned (≥80),
1 logged (<80)**:

| # | Score | Finding | Disposition |
|---|---|---|---|
| F1 | 95 | `mehta2018.md` claimed Appendices A–C "not present in the shelf PDF … not retrieved at M65"; all three ARE present (pp. 2750–2752) | **Fixed** — false claim removed; Appendix A/B tables extracted into a new section, which turned out to substantiate the paper's safeguard claim with its own numbers |
| F3 | 92 | `saha2005.md` described the cross-paper SE discrepancy as "~1 % … in every dose group"; medium dose is **9.5 %** | **Fixed** — replaced with a per-group table; medium-dose gap called out as not rounding |
| F7 | 92 | `saha2012.md` open question "author disambiguation … PDF has not been read" was already resolved by `saha2005.md` in the same diff | **Fixed** — rewritten as a resolved pointer |
| F4 | 90 | `xiao2013.md` gave Table 2's coverage range as 734–862 twice; the minimum is **731** | **Fixed** — corrected in both places; all nine values now listed |
| F2 | 88 | `mehta2018.md` p. 2736 quote not verbatim ("results from" substituted for "the expected reliability of"); `bobak2018.md` "than **in** cases" | **Fixed** — both quotes corrected against the PDFs |
| F5 | 88 | `bhandary2006.md` attributed the family-size parameters to "Srivastava et al. 1977"; the paper credits **Rosner et al. 1977** and Srivastava & Keen 1988 | **Fixed** — corrected with the p. 774 anchor |
| F6 | 74 | `bhandary2006.md`'s AC3 section presents size/power tables without the explicit "this paper reports no coverage/width" sentence its three sibling notes carry | **Logged, not actioned** (below the 80 threshold) — presentation consistency; the reference table AC3 asks for is present |

Additional fix made during review, not from a finding: `xiao2009.md`'s open
question asking to compare simulation designs with `bhandary2006` "when that
note is written" was closable once both notes existed — resolved in place, and
it records that the two family-size parameterizations are *close but not
identical* (`m = 2.84`, `P = 0.93`, Brass/Mian–Shoukri vs mean 2.86,
Rosner/Srivastava–Keen), so results from the two must not be pooled.

**Note on F1 and F7 together:** both are failures of the same kind — a note
asserting something about what had or had not been checked, which was wrong or
went stale within the same milestone. F7 is a literal repeat of the M64 lesson
already in `LESSONS.md`. A sharpened lesson is recorded at merge.
