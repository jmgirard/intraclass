# Fable review brief — Bayesian nested fixed-rater θ²_{r:c} bias correction (M27 Slice 2, ADR-037)

**Status:** gated statistical-derivation review (PRINCIPLE #19). Requested by the maintainer
after the main session (Opus) surfaced an undercoverage finding and prototyped a fix. **No code
is committed for Slice 2**; the corrected estimator is NOT yet implemented in the package. Fable
is asked to review the *derivation* and recommend the estimator to ship. Do not tune to the
oracle (#4); characterize honestly (#18).

---

## 1. Context and the estimand

M27 extends the brms (Bayesian) engine to **fixed-rater multilevel** ICCs, subject level,
balanced/complete. Slice 1 (crossed Design 1) shipped. Slice 2 is **nested Design 2** (raters
nested in clusters): fit `score ~ 0 + rater + (1 | cluster:subject)` under the sourced
half-*t*(4,0,1) prior on the single random-effect SD; the rater cell means are population-level
fixed effects (flat prior).

The **estimand** (no new spec; reuses the frequentist M19 Slice 2 / ADR-029): the rater slot
carries **θ²_{r:c}**, the within-cluster finite-population variance of each cluster's `k` FIXED
rater means, averaged over clusters (McGraw & Wong 1996 Case 3A per cluster; ten Hove et al. 2022
Design 2):

    θ²_{r:c} = mean_c [ Σ_j (μ_{cj} − μ̄_c)² / (k − 1) ]     with C = I − J/k (centering)

where μ_{cj} are the TRUE (fixed) rater means in cluster c. Subject-level agreement error set is
{rater, residual} (M8 §3a), so ICC(A,1) = σ²_{s:c} / (σ²_{s:c} + θ²_{r:c} + σ²_res). Raters are a
FIXED per-cluster finite population; coverage is of this fixed value.

**The shipped frequentist estimator** (`theta2r_fixed_nested()`, R/engine-glmmtmb.R:582; oracle
O-FNML in M19, cross-engine + single-cluster reduction to flat M3). Per cluster it BIAS-CORRECTS:

    θ̂²_c = max(0, q(β̂_c) − tr(C · V_c)/(k − 1)),   q(x) = xᵀ C x /(k−1)

with β̂_c the fitted rater cell means and V_c their sampling covariance (`vcov`). The `− tr(C·V)/(k−1)`
removes the sampling-variance inflation of the quadratic form (a plug-in q(β̂) over-estimates
q(μ_true)). Then averaged over clusters. The Monte-Carlo interval recomputes q from β draws minus
the same per-cluster bias (`theta2r_nested_draws()`, R/engine-glmmtmb.R:633).

## 2. The Bayesian question and the finding

ADR-036 (M26, single-level fixed) resolved to read θ²_r **RAW** per posterior draw — NO frequentist
bias correction — arguing "a posterior already integrates the parameter uncertainty the `− bias`
removes." That held for M26 (single-level) and M27 Slice 1 (crossed): coverage ~nominal, because
the rater means are estimated from the WHOLE sample so their posterior spread is tiny (bias ≈ 0).

For **nested** Design 2, each cluster's `k` rater means come from only that cluster's data (~5
subjects), so their posterior spread is material. The RAW per-draw push-forward
`q(μ^(draw)) = Σ_j(μ_{cj}^(d) − μ̄_c^(d))²/(k−1)` then has posterior mean

    E[q(μ^(d))] = q(μ̄_c) + tr(C · Σ_post,c)/(k − 1)

i.e. biased HIGH by the same quadratic-inflation term, with the **posterior covariance** Σ_post in
place of the sampling V. This biases θ²_{r:c} high → ICC low → undercoverage.

**Seeded evidence** (DGP: n_clusters=20, n_subj/cluster=5, k=4, σ²_{s:c}=1, σ²_res=0.5, fixed
per-cluster centered rater means with θ²_{r:c}=0.6616, pop ICC(A,1)=0.4626; half-*t*(4,0,1) prior;
MAP = reflected-KDE posterior mode; percentile 95% credible interval; n_rep=100, seed 20271):

| estimator | coverage(pop ICC) | MAP rel-bias | containment(glmmTMB REML in CI) |
|---|---|---|---|
| RAW (shipped M26 posture)         | 0.86 | −0.106 | 1.00 |
| BIAS-CORRECTED (proposed)         | 0.92 | −0.065 | 1.00 |

Crossed Slice 1 for contrast (raw): coverage 0.96, MAP −0.004, containment 1.00.

## 3. The proposed corrected estimator (to review)

Per posterior draw, per cluster c (rows `ix` = that cluster's rater cell means):

    Σ_post = cov(t(β_draws))                       # empirical posterior covariance of ALL cell means
    bias_c = tr(C · Σ_post[ix, ix]) / (k − 1)      # constant across draws
    q_c^(d) = colSums(m · (C m)) / (k − 1)         # m = β_draws[ix, ], per draw
    θ_c^(d) = pmax(0, q_c^(d) − bias_c)            # floored at 0 per cluster
    θ_{r:c}^(d) = mean_c θ_c^(d)

This mirrors `theta2r_nested_draws()` exactly, with Σ_post (posterior covariance) substituted for
the sampling V. It is NOT a novel estimator — it is the Bayesian analog of the already-oracle-pinned
frequentist bias correction.

## 4. Specific questions for Fable

1. **Is `− tr(C·Σ_post)/(k−1)` the correct bias correction** for the posterior push-forward of the
   finite-population variance functional q(μ_true), treating the μ as fixed unknowns with a
   hierarchical posterior? Or is there a more principled Bayesian estimator (e.g. the posterior of
   q evaluated on posterior-mean-shrunken means; a fully-Bayesian finite-population-variance
   functional)?
2. **Per-draw constant subtraction vs a marginal/point correction.** We need a credible INTERVAL,
   not just a point. Subtracting the constant bias_c from every draw shifts the whole posterior of
   θ down. Is that the right way to get a calibrated interval, or does the interval need the
   posterior of q(μ_true) constructed differently (the residual MAP −6.5% suggests a small residual
   bias)?
3. **Per-cluster flooring `pmax(0, q − bias)` before averaging.** Does flooring at 0 per cluster
   reintroduce upward bias (Jensen, when q − bias < 0 for a cluster)? Is flooring-then-averaging
   vs averaging-then-flooring vs no-floor preferable? (The frequentist path floors per cluster.)
4. **Crossed consistency.** Slice 1 (crossed, `brms_theta2r_draws`, R/engine-brms.R:313) ships RAW,
   where bias ≈ 0. Should the crossed helper be UNIFIED to the same corrected form (numerically
   ~identical there, ~0.002 per M26) for one estimator correct in both regimes — or is the
   raw/corrected split (documented by regime) acceptable? Note M26 single-level fixed is shipped as
   raw (out of scope to change here, but relevant to the reasoning's consistency).
5. **Empirical posterior covariance adequacy.** `cov(t(β_draws))` from the MCMC sample — sampling
   error in Σ_post, and whether the cross-cluster blocks (ignored; only within-cluster `[ix,ix]`
   used) matter.
6. **Robustness.** Does the correction preserve coverage across other regimes (k ∈ {2,3,4,...},
   n_subj/cluster, θ² magnitude, n_clusters), or does it over/under-correct at the boundary
   (small k per cluster, θ² near 0)?

## 5. Reproduction

- Package branch `m27-bayes-multilevel-fixed` (Slice 1 committed at 6a304b5; Slice 2 uncommitted).
- Frequentist estimator: `theta2r_fixed_nested()` / `theta2r_nested_draws()` (R/engine-glmmtmb.R).
- Proposed Bayesian fit (uncommitted local): `fit_brms_nested_fixed()` +
  `brms_theta2r_nested_draws()` (R/engine-brms.R) — currently RAW.
- Diagnostic scripts (scratchpad, not committed): `diag-fnml-biascorr.R` (raw vs corrected, 40 rep),
  `diag-fnml-100.R` (100 rep, the table above); raw fixture written by
  `data-raw/oracle-bayesian-nested-fixed.R`.

## 6. Deliverable requested from the review

A recommendation on: the estimator to ship for nested θ²_{r:c} (raw / the proposed correction / a
better-justified alternative), the flooring and interval-construction choices, and whether to unify
the crossed helper — with the reasoning, so the ADR-037 amendment and the estimand note can cite it.
