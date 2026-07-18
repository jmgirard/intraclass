# M58: Multilevel SEM (lavaan) — incomplete / unbalanced random design (done)

- done · normal · Principles IP1, GP5, GP6, GP7 · PR #66 (squash-merged 2026-07-17)

## Goal
Extend the crossed (Design 1) random-rater multilevel lavaan engine to incomplete
data (two-level FIML) and unequal cluster sizes, gated by a feasibility spike.

## Outcome
- `icc(..., engine = "lavaan", cluster = ...)` random raters now fit incomplete
  cells (`missing = "fiml"`) and unequal cluster sizes natively, matching glmmTMB
  within the M49 index-class split; averaged cluster ICC uses the shared `k_c^eff`
  (M46). FIXED raters stay complete/balanced (parked candidate).
- The τ² rater-inflation law generalizes under imbalance to the HARMONIC MEAN of
  per-cluster subject counts: τ² = (σ²_cr + σ²_res/H)/C, H = C/Σ(1/m_c) — reduces
  to the balanced law when equal; beats the size-weighted grand law (lavaan weights
  clusters equally), pinned as a discriminating invariant.
- MC-only on incomplete/unbalanced (MD-1: `simulate_refit = NULL`; bootstrap can't
  reproduce missingness/coverage balanced-only — oracle-first); balanced random
  keeps the M56 bootstrap. Balance guard narrowed to fixed-only; connectedness +
  `k_c^eff` are shared engine-agnostic guards.
- T1 spike: pilot Stages 3–4, PILOT PASS, GO in synthesis note. Review: AC1–AC5
  verified; 3 lenses clean (diff-bug/blame/prior-PR); F1 (vacuous imbalance assert,
  scored 85) fixed. CI green (6 platforms + lint/pkgdown/cov). New test file, 34 assn.
