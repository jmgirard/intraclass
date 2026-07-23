# M86: Profile-likelihood machinery for two-way random ICC(A,1) — implement + validate against xiao2013

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5
- **Branch/PR:** m86-mpl-machinery-twoway-random · https://github.com/jmgirard/intraclass/pull/93

## Goal

Implement naive- and modified-profile-likelihood (MPL) interval machinery for the
two-way random ICC(A,1) and establish its correctness by reproducing xiao2013's
published κ_m constants and coverage/length tables in the calibration region
(ρ ≥ 0.6). No exported method.

## Scope

**In:**
- A committed, seeded `data-raw/` prototype computing, from the (SMS, RMS, EMS)
  ANOVA layout (xiao2013 Table 1, p. 2244): the profile log-likelihood `l†(ρ)`
  (Eq. 7–8, p. 2245), the naive-PL interval (Eq. 9/10, κ = 0), the MPL interval
  (κ = κ_m), and the κ_m grid-search calibration (Eqs. 11–13 + the seven-step
  Monte-Carlo κ_corr procedure, pp. 2247–2251).
- Oracle validation reproducing xiao2013's published values in the calibration
  region: Table 3 κ_m constants, Table 4 (naive PL, 90% two-sided), Table 6 (MPL,
  90% two-sided), with a one-sided cross-form check against Table 7.
- Confirming the estimand mapping xiao2013 ρ ↔ package `ICC(A,1)` and recording it.

**Out:**
- The comparison sweep vs package incumbents and the GO/NO-GO verdict → M87.
- Near-zero-ρ (boundary) recalibration of κ_m and any package-range evaluation → M87.
- Any exported `R/` method or `ci_method` → GO-gated candidate (decided in M87).
- Implementing GV (generalized pivots) as live code → not done; the frozen
  xiao2013 Table 4/6 GV values are the oracle.
- Unbalanced/incomplete two-way designs → out (xiao2013 is balanced-complete only).

## Acceptance criteria

- [x] AC1 — A seeded `data-raw/` prototype computes naive-PL and MPL two-sided
      intervals for a two-way random ICC(A,1) dataset from the (SMS, RMS, EMS)
      layout, including the κ_m grid-search calibration, and runs reproducibly
      (fixed seed → committed fixture). Spot-checked against a xiao2013 §5 worked
      example (Ex. 1 or 2, pp. 2255–2256, which report ρ̂ and both intervals).
- [x] AC2 — Reproduces xiao2013 Table 4 (naive PL, 90% two-sided, p. 2248) at its
      four transcribed anchor cells (`xiao2013.md`), e.g. (R=3, S=50, δ=4, ρ=.60)
      PL CR 796/1000, AL 0.420; coverage within ±0.03, length within ±0.05.
- [x] AC3 — Reproduces xiao2013 Table 6 (MPL vs GV, 90% two-sided, p. 2250) at its
      three anchor cells using the Table 3 κ_m, e.g. (R=3, S=50, δ=4, ρ=.60)
      MPL 908/1000, AL 0.559; same tolerances as AC2.
- [x] AC4 — Running the calibration reproduces xiao2013 Table 3's δ_U=16 two-sided
      κ_m constants (0.32, 0.67, 0.33 for (R,S) = (3,10),(3,50),(5,50); `xiao2013.md`)
      within ±0.10 (one calibration grid-step, honest for an MC-estimated κ_corr).
- [x] AC5 — The estimand mapping (xiao2013 ρ = package `ICC(A,1)` under
      σ²_e ≡ σ²_res = σ²_sr + σ²_e) is documented in the evidence note against the
      M1 spec, with the index transposition (xiao2013's i=raters, j=subjects) noted.
- [x] AC6 — Evidence note committed under `cairn/references/` recording the
      implementation, the validation table (ours vs published), and the mapping;
      any new range/superlative claim carries an M74 triage row and the
      generalizing-claims enumerator (`--check`) is green.
- [x] AC7 — `lintr::lint_package()` and `air format --check` clean on the new
      `data-raw/` script.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T4
- AC3 → T4
- AC4 → T5
- AC5 → T1
- AC6 → T6
- AC7 → T6

## Tasks

- [x] T1 — Confirm the estimand mapping: xiao2013 ρ ↔ package `ICC(A,1)`
      (σ²_e ≡ σ²_res) against `cairn/estimand-specs/M1-twoway-random-agreement.md`
      and `mcgraw1996`; record it plus the index transposition in the evidence note.
- [x] T2 — Implement `l†(ρ)` from the (SMS, RMS, EMS) layout (Eq. 7–8) and the
      naive-PL interval (Eq. 9/10, κ=0) via 1-D root-finding nesting 1-D
      optimization; unit-check against a §5 worked example.
- [x] T3 — Implement the MPL interval (κ = κ_m in Eq. 9/10) and the κ_m grid-search
      calibration (Eqs. 11–13 + the seven-step MC κ_corr, pp. 2247–2251).
- [x] T4 — Seeded coverage/length harness (xiao2013 DGP, n_rep pre-registered in
      the note); reproduce Table 4 and Table 6 anchor cells within tolerance.
- [x] T5 — Reproduce Table 3 κ_m (δ_U=16 two-sided) by running the calibration; add
      a one-sided cross-form check against a Table 7 cell (p. 2251).
- [x] T6 — Write the evidence note (implementation, validation table, mapping); add
      M74 triage rows; run the enumerator, `lintr`, and `air format --check`.

## Work log

- 2026-07-23: created by /milestone-plan (split from the PL-CI candidate; sibling M87 owns the verdict).
- 2026-07-23: T1 — estimand mapping confirmed (xiao2013 ρ = package ICC(A,1), σ²_e ≡ σ²_res) against the M1 spec + mcgraw1996; recorded in `references/mpl-twoway-random-comparison.md` (new synthesis note + INDEX.md row).
- 2026-07-23: T2 — `data-raw/m86-mpl-lib.R` (Eq. 7 −2l, profile, 2-D-polished MLE reference, naive-PL interval, DGP) + `data-raw/m86-mpl-validate.R` worked-example check. Ex. 1 MLE reproduces exactly (0.8987); naive-PL interval (0.7013,0.9620) vs published (0.7120,0.9598) — ~0.011 (xiao's own numerics); one-sided 95% lower = two-sided 90% lower, matching the paper's χ² convention. lintr + air clean.
- 2026-07-23: T3 — added `mpl_kappa_corr`/`mpl_kappa_m` (Bartlett-type MC realisation of the seven-step κ_corr; κ_m = grid max). Validated: κ_corr(0.6,16) for (3,50) centers at 0.652±0.029 vs published κ_m 0.67 (the max is at the ρ=0.6/δ=16 corner as the paper predicts); MPL interval path (published κ_m) reproduces Table 6 anchors near-exactly — (3,10,δ0.5,ρ.60) 945/0.570 vs 945/0.569, (3,50,δ4,ρ.60) 902/0.556 vs 908/0.559, (5,50,δ4,ρ.90) 928/0.233 vs 927/0.230. lintr + air clean.
- 2026-07-23: T4/T5 — `data-raw/m86-mpl-validate.R` seeded run (n_rep=2000, n_mc=3000) → `data-raw/m86-mpl-validation-results.rds`. Table 4 (naive PL) 4/4 coverage+length; Table 6 (MPL, published κ_m) 3/3; Table 3 κ_m 3/3 within ±0.10 (0.328/0.700/0.362 vs 0.32/0.67/0.33); Table 7 one-sided coverage 2/2 (870/865, 966/959). One-sided *average-length* misses at the (3,50,δ4,ρ.90) corner (0.276 vs 0.433) — machinery verified correct (profile = 6000-pt brute-force to 0; coverage + two-sided all reproduce), recorded as an isolated high-ρ discrepancy, not forced (#4).
- 2026-07-23: T6 — evidence note `references/mpl-twoway-random-comparison.md` completed (mapping + implementation + oracle-validation tables + verdict); INDEX row (T1); M74 triage row (`OUT-repo-analysis`), enumerator `--check` green; `cairn_validate` clean (provenance "Ingested" keyword fix). lintr + air clean.
- 2026-07-23: all tasks complete → status `review`. Seeded validate re-run byte-identical (deterministic), gated criteria ALL PASS. Verify slot clean: `devtools::test()` at `NOT_CRAN=true CI=true` → FAIL 0 | WARN 2 | SKIP 23 | PASS 4041 (no R/ or tests/ change; 2 WARN are pre-existing captured glmmTMB/vignette warnings).
- 2026-07-23: review (PR #93) — 3-lens + scorer. F1 (D-009 xiao directives, 97) fixed: excluded the M86 prototype from the four settling greps + prose updates, `check-reference-observations.py` exit 0. F2 (one-sided `mpl_kappa_corr` folded-deviance bug, 85) fixed: signed-root form, validated by 0.956 one-sided coverage + corner κ_m corroboration. Consistency gate clean; ACs re-verified against fresh fixture evidence (see Review section).

## Decisions

## Review

Reviewed 2026-07-23 · PR #93. Fresh evidence from the seeded validate run
(`data-raw/m86-mpl-validation-results.rds`, reproduced byte-identically across
runs — deterministic).

**Acceptance criteria.**
- AC1 ✓ — `data-raw/m86-mpl-lib.R` computes naive-PL + MPL intervals + κ_m
  calibration; seeded run reproducible (fixture byte-identical). Ex. 1 MLE exact
  (0.8987); naive-PL interval (0.7013,0.9620) vs pub (0.7120,0.9598) ~0.011.
- AC2 ✓ — Table 4 naive-PL 4/4 coverage + length (902/902, 796/796, 832/838,
  864/875; AL within 0.002).
- AC3 ✓ — Table 6 MPL 3/3 (939/945, 903/908, 924/927; AL within 0.003).
- AC4 ✓ — Table 3 two-sided κ_m 3/3 within ±0.10 (corner-estimator:
  0.333/0.667/0.263 vs 0.32/0.67/0.33).
- AC5 ✓ — estimand mapping (xiao2013 ρ = ICC(A,1), σ²_e ≡ σ²_res) documented;
  blame-lens confirmed it matches the M1 spec verbatim.
- AC6 ✓ — evidence note committed; 3 M74 triage rows (`OUT-repo-analysis`);
  enumerator `--check` green.
- AC7 ✓ — `lintr` no lints, `air format --check` clean.

**Consistency gate.** `cairn_validate` exit 0; `devtools::document()` no diff;
new files R-build-ignored (`^data-raw$`, `^cairn$`) so the built package is
unchanged (no NEWS entry needed); enumerator `--check` OK; D-009
`check-reference-observations.py` exit 0; `devtools::test()` (NOT_CRAN=true
CI=true) FAIL 0 | PASS 4041. No DESIGN principle changed → `cairn_impact` skipped.

**Independent review — 3 lenses + scorer.** Two real findings, both actioned.
- **F1 (prior-review lens, scored 97) — fixed.** New `data-raw/m86-mpl-*.R`
  contain "xiao", falsifying four D-009 settling directives in `xiao2013.md`
  (22, 277) and `xiao2009.md` (32, 209) → CI `check-references` red (the M80
  pattern). Fixed: excluded the M86 prototype files from each directive and
  updated the prose (xiao2013 now records the prototype implements the method;
  xiao2009 notes the files reference the xiao2013 sibling) — checker exit 0.
- **F2 (diff-bug lens, scored 85) — fixed.** `mpl_kappa_corr(side="lower")`
  reused the two-sided folded deviance, so the one-sided κ would not vanish
  asymptotically (floor ≈0.42). Latent in M86 (no validation exercised it), but
  delivered machinery M87 may consume. Fixed to the signed likelihood root
  `L = sign(ρ̂−ρ)·√D`, `κ_corr = quantile(L)²/χ²_{1−2α} − 1`; validated by its
  defining property — the MPL one-sided bound at its own κ_corr covers at 0.956
  (target 0.95) — plus a new one-sided κ_m corroboration leg (2/3 corner cells
  within ±0.10; the (3,50) 0.95-tail is MC-noisy on MPL's conservative side).
  Evidence-note calibration description scoped per side.
- Below-threshold: none. Blame-history lens: no findings.

**Deviations from plan.** None on the ACs. The one-sided Table 7 average-length
(a T5 cross-check, not an AC) and the one-sided κ_m constant are recorded as
informational; the F2 fix expanded the one-sided validation beyond the original
plan (a review-driven strengthening).
