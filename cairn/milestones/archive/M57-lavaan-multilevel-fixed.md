# M57: Multilevel SEM (lavaan) — fixed-rater crossed design (done 2026-07-17)

Shipped `icc(engine="lavaan", cluster=, raters="fixed")` for the crossed
(Design 1) multilevel SEM at both subject and cluster levels on balanced/complete
data. PR #65.

**Outcome:** the between-level rater intercepts give the McGraw & Wong Case-3A
finite-population θ²_r = max(0, raw − bias), bias = tr(C·V_ν)/(k−1) on the `~1.l2`
between-intercept vcov block; per-draw 2b + average-floor via the shared
`theta2r_moment_draws()`. MC-only (`simulate_refit = NULL` for fixed). The icc()
dispatch guard was narrowed so the crossed/balanced/complete/equal-size cell falls
through; fixed nested/replicate/incomplete/unbalanced still abort
`intraclass_unsupported`.

**Oracle evidence:** lavaan fixed ≈ glmmTMB fixed both levels (subject Δ≈6e-5,
cluster Δ≈1.8e-3); consistency identical to random (rater omitted); the
fixed−random component gap == the τ² `bias` deterministically. New
`test-icc-fixed-lavaan-multilevel.R` (21 pass) + a deterministic 1b/2b/floor guard;
engine-parity matrix cell moved lavaan refusal→agreement.

**Key decision:** AC2 corrected at the gate — lavaan's random σ²_r is the raw
τ²-inflated estimator (ADR-014), so lavaan fixed ≠ lavaan's own random (differs by
the finite-population correction), unlike glmmTMB's REML M37 identity; validated
against glmmTMB fixed instead. Fixed bootstrap deferred to a candidate. No
principle changed. Three-lens review clean; CI green all platforms.
