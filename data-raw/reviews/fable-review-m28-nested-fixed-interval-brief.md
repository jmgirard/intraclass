# Fable review brief — frequentist nested fixed-rater θ²_{r:c} MC-INTERVAL coverage (M28 Slice 2, ADR-038)

**Status:** gated statistical-derivation review (PRINCIPLE #19). Requested by the maintainer after the
main session (Opus) ran a committed coverage sim (M28 Slice 1) that confirmed an under-coverage finding
and prototyped a fix. **No code is committed for Slice 2**; the corrected interval is NOT yet implemented
in the package. Fable is asked to review the *derivation* and recommend the interval construction to ship.
Do not tune to the oracle (#4); characterize honestly (#18).

This is the **corollary** of the M27 gated Fable review (`fable-review-m27-nested-fixed-{brief,response}.md`,
ADR-037 amendment), which fixed the **Bayesian** sibling. That review's §6 flagged that the frequentist
interval "likely shares an attenuated displacement." M28 Slice 1 pinned it: it does, materially.

---

## 1. Context and the estimand

The frequentist path (M19 Slice 2, ADR-029) fits nested Design 2 (raters nested in clusters) with raters
**fixed**: `score ~ 0 + rater + (1 | cluster:subject)`, REML. The rater slot carries **θ²_{r:c}**, the
within-cluster finite-population variance of each cluster's `k` FIXED rater means, averaged over clusters
(McGraw & Wong 1996 Case 3A per cluster; ten Hove et al. 2022 Design 2):

    θ²_{r:c} = mean_c [ Σ_j (μ_{cj} − μ̄_c)² / (k − 1) ] = mean_c q(μ_c),   q(x) = xᵀ C x /(k−1),  C = I − J/k

with μ_{cj} the TRUE (fixed) rater means in cluster c. Subject-level agreement error set is {rater,
residual} (M8 §3a): ICC(A,1) = σ²_{s:c} / (σ²_{s:c} + θ²_{r:c} + σ²_res). Raters are a FIXED per-cluster
finite population; coverage is of this fixed value.

**The shipped POINT estimator** (`theta2r_fixed_nested()`, R/engine-glmmtmb.R:582; oracle O-FNML in M19 —
cross-engine + per-cluster/single-cluster reduction to flat M3 Case 3A). Per cluster it bias-corrects:

    θ̂²_c = max(0, q(β̂_c) − b_c),   b_c = tr(C · V_c)/(k − 1),   θ̂²_{r:c} = mean_c θ̂²_c

with β̂_c the fitted rater cell means and V_c = `vcov(fit)` their sampling covariance. The −b_c removes the
plug-in inflation (E[q(β̂_c)] = q(μ_c) + b_c). **This point is unbiased and is NOT under review** — it is
out of M28 scope and stays as-is.

**The shipped MC INTERVAL** (`theta2r_nested_draws()`, R/engine-glmmtmb.R:633). The Monte-Carlo CI draws
β^(d) ~ N(β̂, V) on the natural scale (ADR-003) and per cluster computes, then averages:

    θ_c^(d) = pmax(0, q(β^(d)_c) − b_c),         θ_{r:c}^(d) = mean_c θ_c^(d)          # SHIPPED

i.e. it subtracts **one** b_c and floors **per cluster** before averaging.

## 2. The finding (M28 Slice 1, committed)

Oracle **O-NFI** (`data-raw/oracle-nested-fixed-interval.R`, committed fixture
`tests/testthat/fixtures/nested-fixed-interval-oracle.rds`): a seeded coverage sim over the Fable Q6 grid
`k ∈ {2,4}` × `n_s ∈ {3,5,20}` × `C_n ∈ {5,20,80}` × `θ²_{r:c} ∈ {0, σ²_res/n_s, 0.66}`, σ²_{s:c}=1,
σ²_res=0.5, rater means held FIXED across n_rep=100 replications (only subjects + residuals resampled).
Coverage of the 95% subject-level ICC(A,1) interval of the population value:

| C_n | boundary (θ²=0) coverage | interior coverage |
|---|---|---|
| 5  | .95 | .95 |
| 20 | .86 | .92 |
| 80 | **.57** | .80 |

Worst cell (C_n=80, n_s=3, θ²=0): coverage **.36–.38**. The shortfall **grows with the number of
clusters** and **eases with subjects-per-cluster** (C_n=80 boundary: n_s=3 → .37, n_s=5 → .51, n_s=20 →
.83) — the incidental-parameters signature.

## 3. The derivation (why it undercovers)

The MC push-forward of the quadratic through the Gaussian draws re-inflates the mean:

    E_draw[ q(β^(d)_c) ] = q(β̂_c) + b_c.

So the shipped per-cluster draw `q(β^(d)_c) − b_c` has draw-mean `q(β̂_c)` — which is **b_c ABOVE the point
estimate's per-cluster term** `θ̂²_c = q(β̂_c) − b_c`. The MC distribution of θ²_{r:c} is therefore centered
~b_c too high per cluster → the whole θ² interval sits high → the ICC interval sits **low** → it undercovers
a true value the (correct) point estimates well. The displacement is exactly one b_c per cluster; it grows
as b_c grows (n_s↓ → V_c↑ → b_c↑) and, because averaging over clusters narrows the interval (~1/√C_n) while
the per-cluster displacement does not vanish, the **relative** miscalibration grows with C_n — matching
O-NFI cell-for-cell. This is the frequentist mirror of the M27 Bayesian finding (Σ_post → V).

## 4. The proposed corrected interval (to review)

Re-center each draw on the POINT estimate by subtracting **2·b_c**, and floor the per-draw **AVERAGE** (not
each cluster):

    θ_c^(d) = q(β^(d)_c) − 2·b_c                                   # NO per-cluster floor
    θ_{r:c}^(d) = pmax( 0, mean_c θ_c^(d) )                        # floor the AVERAGE

Then E_draw[θ_c^(d)] = q(β̂_c) − b_c = θ̂²_c (the point) per cluster — the draws are centered on the estimate
with the right spread. This is **identical to the M27 Bayesian resolution** (`brms_theta2r_moment_draws()`),
with the sampling covariance V in place of the posterior covariance Σ_post. **The point estimator is
unchanged** (it keeps 1b, is separate, and is O-FNML-pinned); only the interval draws move to 2b.

Why 2b and not 1b, restated in the M27 vocabulary: there are **two** equal inflations — the push-forward
`E[q(β^(d))] = q(β̂) + b` and the plug-in of the center `q(β̂) = θ² + b`. The frequentist POINT removes one
(its −b_c), because the point is computed once from β̂. The INTERVAL draws must remove **both** to sit on the
point: one to undo the push-forward, one because the center they push forward from (β̂) is itself the biased
plug-in. (M27's note "the frequentist subtracts only 1b because its point is unbiased" was about the POINT;
it did not address the interval's calibration, which O-NFI now shows needs 2b.)

**Prototyped evidence** (scratch, not committed; `rmvn(β̂, V)` draws, shipped vs proposed, n_rep=60):

| cell | pop ICC | shipped (1b, per-cluster floor) | proposed (2b, average floor) |
|---|---|---|---|
| k=4 n_s=3 C_n=80 θ²=0    | .667 | 0.42 | **0.95** |
| k=2 n_s=3 C_n=80 θ²=0    | .667 | 0.47 | 1.00 |
| k=4 n_s=3 C_n=80 θ²=.167 | .600 | 0.53 | 0.93 |
| k=4 n_s=5 C_n=80 θ²=0    | .667 | 0.44 | 0.97 |
| k=4 n_s=5 C_n=80 θ²=.66  | .463 | 0.88 | 0.98 |
| k=4 n_s=3 C_n=20 θ²=0    | .667 | 0.73 | 0.95 |
| k=4 n_s=20 C_n=5 θ²=.66 (healthy) | .463 | 1.00 | 0.97 |

The correction recovers nominal coverage where it was broken and does **not** degrade already-healthy cells
(1.00 → 0.97). At the boundary it is slightly conservative (→ 1.00), like the M27 average-floor.

## 5. Specific questions for Fable

1. **Is subtracting 2·b_c the correct calibration** for the MC interval of this convex quadratic
   finite-population functional — i.e. re-centering the Gaussian push-forward on the (1b-corrected) point —
   or is a more principled interval construction preferable (delta-method on a transformed scale, a profile
   / parametric-bootstrap-of-the-estimator that recomputes θ̂²_c per draw, a proper finite-population
   posterior)? Note the parametric-bootstrap-of-the-estimator would compute `q(β^(d)_c) − b_c` and is
   centered at `q(β̂_c)` — i.e. it reproduces the SHIPPED (undercovering) interval; the 2b form instead
   centers on the estimate. Which is the right target for a CI of the fixed value?
2. **Point untouched.** Confirm the POINT should stay at 1b (unbiased, O-FNML) and only the interval draws
   move to 2b — i.e. this is not a double-correction of the estimator.
3. **Average-floor vs per-cluster floor.** Per-cluster `pmax(0, ·)` keeps every cluster's contribution
   strictly positive near θ²=0 → the average cannot reach 0 → zero boundary coverage (O-NFI: .36). Flooring
   the AVERAGE lets negative per-cluster draws cancel and is boundary-reaching (proto: ~.95–1.00). Confirm,
   and address any residual Jensen bias from flooring the average.
4. **Residual calibration.** Proto shows a few cells at ~.93 (mildly under) and some at 1.00 (conservative
   at the boundary). Is <.95 interior (e.g. .93) acceptable MC/finite-sample noise, or a sign the 2b form
   slightly under-shoots interiorly (the M27 Bayesian residual was MAP −.017)?
5. **Crossed sibling + unification.** The crossed M10 interval (`theta2r_fixed()` /
   `theta2r_fixed_draws`, R/engine-glmmtmb.R) estimates rater means from the WHOLE sample, so b ≈ 0 and the
   displacement → 0 (a spot-check should confirm coverage ~nominal there already). Should the crossed +
   nested frequentist draws be **unified** into one shared 2b/average-floor helper (mirroring how M27
   unified `brms_theta2r_moment_draws()`), so one construction is correct in both regimes — or is a
   documented regime split acceptable?
6. **Robustness.** Does 2b + average-floor preserve coverage across the whole Q6 grid without over-
   correcting (proto suggests yes: healthy cells stay ~nominal, boundary becomes conservative), or does it
   over/under-correct in a regime not yet probed (very large k, very small C_n, θ² just above 0)?

## 6. Reproduction

- Package `main` (M28 Slice 1 committed uncommitted-locally): `theta2r_fixed_nested()` /
  `theta2r_nested_draws()` (R/engine-glmmtmb.R); `mc_components()`/`rmvn()` (R/ci-montecarlo.R).
- Oracle + fixture: `data-raw/oracle-nested-fixed-interval.R` →
  `tests/testthat/fixtures/nested-fixed-interval-oracle.rds`; asserted by O-NFI in
  `tests/testthat/test-icc-fixed-multilevel.R`.
- Prototype (scratchpad, not committed): shipped vs 2b/average-floor, the §4 table.
- Prior review: `data-raw/reviews/fable-review-m27-nested-fixed-{brief,response}.md` (the Bayesian sibling
  + its Q6 grid).

## 7. Deliverable requested from the review

A recommendation on: the interval construction to ship for the frequentist nested θ²_{r:c} MC interval (the
proposed 2b + average-floor / a better-justified alternative), the flooring choice, whether the point stays
untouched, and whether to unify the crossed + nested draws — with the reasoning, so the ADR-038 amendment
and the O-NFI oracle note can cite it.
