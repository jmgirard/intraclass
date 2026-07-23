# M86: Profile-likelihood machinery for two-way random ICC(A,1) — implement + validate against xiao2013

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP5
- **Branch/PR:** m86-mpl-machinery-twoway-random

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

- [ ] AC1 — A seeded `data-raw/` prototype computes naive-PL and MPL two-sided
      intervals for a two-way random ICC(A,1) dataset from the (SMS, RMS, EMS)
      layout, including the κ_m grid-search calibration, and runs reproducibly
      (fixed seed → committed fixture). Spot-checked against a xiao2013 §5 worked
      example (Ex. 1 or 2, pp. 2255–2256, which report ρ̂ and both intervals).
- [ ] AC2 — Reproduces xiao2013 Table 4 (naive PL, 90% two-sided, p. 2248) at its
      four transcribed anchor cells (`xiao2013.md`), e.g. (R=3, S=50, δ=4, ρ=.60)
      PL CR 796/1000, AL 0.420; coverage within ±0.03, length within ±0.05.
- [ ] AC3 — Reproduces xiao2013 Table 6 (MPL vs GV, 90% two-sided, p. 2250) at its
      three anchor cells using the Table 3 κ_m, e.g. (R=3, S=50, δ=4, ρ=.60)
      MPL 908/1000, AL 0.559; same tolerances as AC2.
- [ ] AC4 — Running the calibration reproduces xiao2013 Table 3's δ_U=16 two-sided
      κ_m constants (0.32, 0.67, 0.33 for (R,S) = (3,10),(3,50),(5,50); `xiao2013.md`)
      within ±0.10 (one calibration grid-step, honest for an MC-estimated κ_corr).
- [ ] AC5 — The estimand mapping (xiao2013 ρ = package `ICC(A,1)` under
      σ²_e ≡ σ²_res = σ²_sr + σ²_e) is documented in the evidence note against the
      M1 spec, with the index transposition (xiao2013's i=raters, j=subjects) noted.
- [ ] AC6 — Evidence note committed under `cairn/references/` recording the
      implementation, the validation table (ours vs published), and the mapping;
      any new range/superlative claim carries an M74 triage row and the
      generalizing-claims enumerator (`--check`) is green.
- [ ] AC7 — `lintr::lint_package()` and `air format --check` clean on the new
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
- [ ] T3 — Implement the MPL interval (κ = κ_m in Eq. 9/10) and the κ_m grid-search
      calibration (Eqs. 11–13 + the seven-step MC κ_corr, pp. 2247–2251).
- [ ] T4 — Seeded coverage/length harness (xiao2013 DGP, n_rep pre-registered in
      the note); reproduce Table 4 and Table 6 anchor cells within tolerance.
- [ ] T5 — Reproduce Table 3 κ_m (δ_U=16 two-sided) by running the calibration; add
      a one-sided cross-form check against a Table 7 cell (p. 2251).
- [ ] T6 — Write the evidence note (implementation, validation table, mapping); add
      M74 triage rows; run the enumerator, `lintr`, and `air format --check`.

## Work log

- 2026-07-23: created by /milestone-plan (split from the PL-CI candidate; sibling M87 owns the verdict).
- 2026-07-23: T1 — estimand mapping confirmed (xiao2013 ρ = package ICC(A,1), σ²_e ≡ σ²_res) against the M1 spec + mcgraw1996; recorded in `references/mpl-twoway-random-comparison.md` (new synthesis note + INDEX.md row).
- 2026-07-23: T2 — `data-raw/m86-mpl-lib.R` (Eq. 7 −2l, profile, 2-D-polished MLE reference, naive-PL interval, DGP) + `data-raw/m86-mpl-validate.R` worked-example check. Ex. 1 MLE reproduces exactly (0.8987); naive-PL interval (0.7013,0.9620) vs published (0.7120,0.9598) — ~0.011 (xiao's own numerics); one-sided 95% lower = two-sided 90% lower, matching the paper's χ² convention. lintr + air clean.

## Decisions

## Review
