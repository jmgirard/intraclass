# Fable review response — frequentist nested fixed-rater θ²_{r:c} MC-interval calibration (M28 Slice 2)

**Reviewer:** Claude Fable 5 (gated statistical-derivation review, PRINCIPLE #19), 2026-07-09.
**Brief:** `fable-review-m28-nested-fixed-interval-brief.md` (same directory).
**Verification script (this review's, seeded, committed):** `fable-check-nfi.R` (same directory) —
conjugate-normal check, no model fitting; valid for the same reason as the M27 review's §3: on
balanced nested Design 2 the per-cluster rater cell means satisfy *exactly*
β̂_c ~ N(μ_c, V), V = (σ²_{s:c}/n_s)J + (σ²_res/n_s)I, and the MC draws are β* ~ N(β̂, V̂), so every
identity the derivation rests on is exact in this reduction and the interval arithmetic can be
verified at n_rep = 500 in seconds. I also re-read the committed O-NFI fixture
(`nested-fixed-interval-oracle.rds`) and confirmed the brief's §2 table cell-for-cell (worst cell
k=2, n_s=3, C_n=80, θ²=0: 0.36).

---

## 0. Verdict

**Ship the proposed interval: subtract 2·b_c per cluster per draw, no per-cluster floor, floor the
per-draw average.** The derivation in the brief's §3–§4 is correct and complete; the factor 2 is
derived, not tuned (#4), and my independent check confirms it with no free parameter. The point
estimator's **1b correction stays** — the 2b on the draws is not a double-correction (§2, Q2).
Unify the crossed and nested frequentist draws into one shared 2b/average-floor helper (§2, Q5).

**One finding beyond the brief (§3):** the shipped POINT's *flooring placement* — `pmax(0, ·)` per
cluster before averaging — has a boundary bias that does **not** vanish as clusters accrue
(E[point] ≈ 0.05–0.08 at θ² = 0, constant in C_n), and once the interval is fixed, the point falls
**outside its own 95% interval** in up to ~40% of boundary replications at C_n = 80 (containment
0.59–0.61 at k = 4). Moving the point's floor to the average — `max(0, mean_c(q(β̂_c) − b_c))`,
keeping 1b exactly as-is — restores containment to 1.000 and shrinks the boundary bias to
~0.001–0.02 (vanishing in C_n). This is a boundary-only change: whenever every cluster clears the
floor (any interior θ²), the two are numerically identical, so the O-FNML pins should be unmoved;
re-run them as confirmation. I recommend making this change in the same slice. The 1b *correction*
itself is untouched either way.

Predicted O-NFI re-run outcome under the §0 interval (ICC level, n_rep = 100): boundary rows
~0.97–1.00 (conservative, boundary-aware), interior rows ~0.93–0.99 with mean ≈ 0.95; no cell
below ~0.90. This is confirmation of derived constants, not calibration.

---

## 1. The derivation is correct — and both "obvious" alternatives fail, in opposite directions

Fix a cluster; drop the subscript. θ = q(μ), q(x) = xᵀCx/(k−1), point θ̂ = q(β̂) − b̂ (unfloored),
b̂ = tr(C V̂)/(k−1). Two exact facts:

1. **Push-forward (exact conditional on the data):** the draws are generated from N(β̂, V̂), so
   E_draw[q(β*)] = q(β̂) + b̂ with the *same* b̂ the code subtracts. Subtracting 2b̂ therefore centers
   the draws at q(β̂) − b̂ = θ̂ **exactly**, by construction — no approximation enters here at all.
2. **Plug-in bias (sampling):** E_sampling[q(β̂)] = θ + tr(CV)/(k−1), which is why the point
   subtracts its one b, and why draws centered at q(β̂) (the shipped construction) sit one b above
   an unbiasedly-estimated θ.

On balanced data b = σ²_res/n_s exactly (C annihilates the J block of V), independent of k and
C_n: the displacement per cluster is fixed while the interval width shrinks ~1/√C_n, so relative
miscalibration grows with C_n — the brief's §3 mechanism, confirmed cell-for-cell by O-NFI and by
my check (θ²-level shipped coverage: boundary mean 0.142, interior mean 0.568; lower than the
ICC-level oracle because the ICC interval gets extra width from the σ² draws — same ranking).

**The right CI target (brief Q1's closing question).** A percentile-type MC interval for a fixed
value covers when its draws are centered on an unbiased estimate with the estimator's sampling
spread. The check tested all three candidates head-to-head (`fable-check-nfi.R`, 24 cells):

- **Shipped (1b, per-cluster floor)** = the parametric-bootstrap-percentile of the recomputed
  estimator: centered at q(β̂) = θ̂ + b → displaced **+b** → coverage → 0 as C_n grows.
- **Basic/pivotal reflection of that same bootstrap** (2·θ̂ − quantiles): the bootstrap-world
  estimand is q(β̂), so the reflection's implicit bias estimate (+b) double-counts a bias the point
  does not have → centered at θ̂ − b, displaced **−b** → also collapses (observed interior coverage
  as low as **0.006** at k=4, C_n=80). Reflection is *not* a safe alternative here.
- **Proposed (2b shift, average floor):** centered at θ̂ exactly → 0.942–1.000 across all 24 cells
  (interior mean 0.974, boundary 1.000 — mildly conservative, see Q4).

The 2b construction *is* the mean-recentered percentile interval — the minimal, principled repair
of the percentile bootstrap for a functional whose push-forward is biased. Of the brief's other
Q1 alternatives: a delta-method interval is degenerate at the boundary (∇q(μ) = 0 when the rater
means are equal; the limit is a χ̄² mixture, not a normal); a profile-likelihood interval faces the
same nonstandard-boundary problem and is new machinery for no coverage gain; the "proper
finite-population posterior" is the hierarchical-shrinkage route already scoped as a future
alternative in the M27 response (Q1) — right long-term idea, own ADR, not this slice.

## 2. Answers to the six questions

**Q1 — Is 2·b_c the correct calibration?** Yes (§1). The first b is removed exactly (identity 1 is
conditional on the data, with the same V̂ that generates the draws); the second b is the plug-in
bias of the center, estimated by the same b̂ (consistent; second-order error only). The two
plausible alternatives — percentile of the recomputed estimator, and its pivotal reflection — are
displaced +b and −b respectively and both empirically collapse in the nested regime. The right
target for a CI of the fixed value is draws centered on the unbiased point; 2b achieves exactly
that. Ship it.

**Q2 — Point untouched at 1b.** Confirmed, and it is not a double correction: the point is
computed once from β̂ and carries one inflation (identity 2), so it subtracts one b; the draws
carry both inflations (identities 1 + 2), so they subtract two. The M27 note "the frequentist
subtracts only 1b because its point is unbiased" was, as the brief says, a statement about the
point. One amendment to "untouched": the point's *flooring placement* should move to the average
(§3) — the 1b arithmetic is unchanged.

**Q3 — Average floor, confirmed.** The mechanism is identical to the M27 response's Q3: with the
honest 2b correction, per-cluster draws near θ² = 0 are negative about half the time; per-cluster
`pmax(0, ·)` turns that noise into strictly positive contributions in every cluster, the average's
lower endpoint is bounded away from 0, and boundary coverage collapses (O-NFI 0.36–0.57 shipped;
the M27 check measured exactly 0.000 for 2b + per-cluster floor). Flooring the average lets
negative per-cluster draws cancel and the interval reach the boundary. Residual Jensen bias from
flooring the average: it binds only when the *average* draw goes negative — i.e., only within
~a few interval-widths of θ² = 0 — where it piles draw mass at 0 and makes the interval
*conservative* (my check: 0.998–1.000 at the boundary; interior floor never binds, bias exactly
zero there). That is the correct boundary-aware direction (#3): characterize in the oracle note,
do not correct.

**Q4 — Residual ~.93 cells are noise, not undershoot.** At n_rep = 60 the MC standard error is
√(.95·.05/60) ≈ 2.8 points; 0.93 is within one SE of nominal. My n_rep = 500 check shows interior
coverage 0.942–0.996 (mean 0.974) — the construction runs slightly *conservative*, not under. The
mechanism for the mild conservatism: the draws' quadratic spread is evaluated at the noisy center
β̂ (E[β̂ᵀCVCβ̂] = μᵀCVCμ + tr((CV)²)), so the interval is marginally over-wide — second-order,
harmless, opposite in sign to an undershoot. There is no M27-style −.017 analog to chase here
because the frequentist point is not read off the draws. Accept interior cells ≥ ~0.92 at
n_rep = 100 as nominal-within-MC-error (#18).

**Q5 — Unify, yes.** Recommend one shared frequentist helper (the analog of
`brms_theta2r_moment_draws()`: per-group mean-draw matrices + per-group b, subtract 2b, no
per-group floor, average, floor the average), used by both the nested path
(`theta2r_nested_draws()` — already shared by the glmmTMB and lme4 engines, so one change fixes
both) and the crossed paths (flat + multilevel-fixed `to_components` in both engines, which
currently inline the 1b/floor construction). In the crossed regime b ≈ 0 (whole-sample means), so
the change is a negligible shift — M3 O6 (0.950/0.947) re-runs as confirmation, and committed
interval snapshots will move by ~b (mechanical churn). Unification retires `theta2r_fixed()`'s
"deliberate displacement" note, which the M27 review §6 already flagged as true-in-regime rather
than true — exactly the kind of regime-conditional exception that would otherwise need re-deciding
at every extension (replicates, imbalance). If wall-time forces staging, a documented split is
*tolerable* short-term (crossed is pinned healthy), but the split should not survive the
milestone. Two notes: (a) the frequentist helper should take b from the engine's V̂ (exact), not
the empirical draw covariance — the draws are generated from V̂, so identity 1 then holds exactly;
(b) the **lavaan** fixed MC path (engine-lavaan.R, `pmax(0, raw_draws - bias)`) is the same 1b
construction — flat/crossed only, so benign, but add it to the unification (or at minimum the
audit list) so no engine carries the old form silently.

**Q6 — Robustness confirmed, no over-correction found.** b = σ²_res/n_s exactly, independent of k
and C_n, so the correction cannot blow up in k or C_n. Probed corners beyond the Q6 grid
(n_rep = 500 each): k=10 (1.000 boundary / 0.956 interior), k=20 with C_n=10 (0.946), C_n=2
(0.998 / 0.964), θ² just above 0 in the worst regime (0.020 and 0.005 at C_n=80: 1.000 — the
near-boundary zone inherits the boundary's conservatism, it does not fall into a coverage hole
between boundary and interior), mid-interior worst regime (0.972). Nothing below 0.942 anywhere.
The only systematic deviation is boundary/near-boundary conservatism, which is the documented
average-floor behavior.

## 3. Finding beyond the brief: the POINT's per-cluster floor breaks containment once the interval is fixed

The shipped point is `mean_c pmax(0, q(β̂_c) − b_c)` (theta2r_fixed_nested(), engine-glmmtmb.R:618).
At θ² = 0 each cluster's `max(0, q̂_c − b_c)` has positive mean (≈ b·E[max(0, χ²_{k−1}/(k−1) − 1)]),
and averaging over clusters reduces its variance but **not** this bias — measured E[point] at the
boundary: 0.051–0.082 for n_s = 3, constant across C_n (the M27 response §6 saw the same +0.03 in
its DGP). Meanwhile the corrected interval tightens ~1/√C_n around 0. Consequence, measured
(seeded, §0 check): at C_n = 80 the point lies outside its own 95% interval in 13–14% (k=2) to
39–41% (k=4) of boundary replications. A reported estimate above its own upper confidence limit is
a user-visible incoherence, and it is produced by the floor, not by the 1b correction.

Fix: floor the point at the **average** too — `max(0, mean_c(q(β̂_c) − b_c))` — the same
boundary-aware projection the interval (and the M27 Bayesian path, whose MAP is read off
average-floored draws) already uses. Measured: containment 1.000 in every probed cell; boundary
bias falls to 0.001–0.021 and now *vanishes* as C_n grows (the average concentrates at 0 from
below and the floor binds less). Interior behavior is *identical* whenever every cluster clears
the floor — for the O-FNML interior pins the change is a no-op, so the point's oracle heritage is
preserved; re-run O-FNML as confirmation, and note the flat single-cluster reduction is unaffected
(with one cluster, average floor ≡ per-cluster floor). If the maintainer prefers strict M28 scope,
shipping the interval fix alone is defensible — but then the boundary containment caveat must be
documented in the oracle note, and I'd expect it to resurface as a bug report; the one-line change
now is cheaper. The crossed `theta2r_fixed()` point needs no change (one group: the two floors
coincide).

## 4. What to ship (consolidated)

1. `theta2r_nested_draws()`: per cluster `q(β*_c) − 2·b_c` with the subtraction written as two
   named terms (`bias_pushforward + bias_plugin`, both = b_c, comment pointing at the two
   identities per the M27 §5 convention); **no** per-cluster floor; average over clusters;
   `pmax(0, ·)` the average. (Shared by glmmTMB and lme4 — one change, both engines.)
2. `theta2r_fixed_nested()` point: `max(0, mean(per_raw − per_bias))` (§3). 1b unchanged.
3. Unify the crossed draws (flat + multilevel fixed, glmmTMB + lme4, and lavaan's MC path) into
   the same 2b/average-floor helper, b from the engine's V̂ per group; re-run M3 O6 and the O-FML
   containment checks as confirmation; regenerate the touched snapshots (Q5).
4. Re-run O-NFI (same committed script/grid) as **confirmation** of derived constants: expect
   boundary ~0.97–1.00, interior mean ≈ 0.95, no cell below ~0.90; update the fixture and the
   oracle header's WHY to record the before/after. Spot-check crossed coverage once (predicting
   ~nominal already, per O6) so the ADR can state the crossed regime was verified, not assumed.
5. ADR-038: cite this response; record the interval recentering (2b), the average-floor (both
   interval and point), the rejection of the pivotal-reflection alternative (it over-corrects by
   b — §1), and scope `theta2r_fixed()`'s old "deliberate displacement" note as
   regime-conditional, now retired by unification.
