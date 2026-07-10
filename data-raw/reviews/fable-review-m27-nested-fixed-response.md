# Fable review response — Bayesian nested fixed-rater θ²_{r:c} bias correction (M27 Slice 2)

**Reviewer:** Claude Fable 5 (gated statistical-derivation review, PRINCIPLE #19), 2026-07-09.
**Brief:** `FABLE-REVIEW-fnml-biascorrection.md` (same directory).
**Verification scripts (this review's, seeded):** `fable-check-fnml.R`, `fable-check-floor.R`
(same directory; conjugate-normal check, no Stan — see §3 for why that is valid).

---

## 0. Verdict

**Do not ship the proposed 1× correction. It is exactly half of the correct correction.**
Ship instead, per posterior draw:

    b_c        = tr(C · Σ_post[ix, ix]) / (k − 1)          # as proposed
    q_c^(d)    = colSums(m · (C m)) / (k − 1)              # as proposed
    θ_c^(d)    = q_c^(d) − 2·b_c                           # NOT floored per cluster
    θ_{r:c}^(d) = max(0, mean_c θ_c^(d))                   # floor the AVERAGE only

Three changes from the brief's §3: the factor **2** on the bias term (§1 — two distinct
inflations, each equal to b_c), **no per-cluster floor** inside the draw, and the floor applied
to the per-draw cluster **average** (§5 — per-cluster flooring gives *zero* interval coverage at
the θ² = 0 boundary; the average-floor is unbiased near the boundary and boundary-aware in the
#3 sense). The factor 2 is **derived, not tuned** (#4): it follows from an exact identity plus
the flat-prior posterior, and the brief's own table confirms it to three decimals (§4).

Predicted outcome for the brief's 100-rep DGP under this estimator: coverage ≈ 0.95, MAP
rel-bias ≈ −0.02 (the residual is the mode-below-mean skew already documented in ADR-033, not
remaining inflation). Run the confirmation sim before shipping; it is confirmation of a derived
constant, not calibration.

---

## 1. The derivation: there are two inflations, and the proposal removes one

Fix a cluster c; drop the subscript. Let μ be the k true (fixed) rater means, q(x) = xᵀCx/(k−1),
θ = q(μ) the estimand. Let β̄ and Σ be the posterior mean and covariance of the cell means, and
β̂, V their GLS estimate and sampling covariance.

**Identity (exact, no approximation).** For any draw distribution with mean β̄ and covariance Σ:

    E_post[ q(β^(d)) ] = q(β̄) + tr(CΣ)/(k−1)                                   (1)

This is the *push-forward* inflation — the one the brief identifies. Subtracting
b = tr(CΣ)/(k−1) centers the draws at q(β̄). So far so good.

**But q(β̄) is not θ.** Under the model's flat prior on the cell means, and conditionally on the
variance components, the posterior of β is *exactly* N(β̂, V) — so β̄ = β̂ and Σ = V (with VC
uncertainty, β̄ ≈ β̂ and Σ ⪆ V; Bernstein–von Mises). And q(β̂) is the *un-bias-corrected*
frequentist plug-in, whose sampling expectation is the standard quadratic-form result:

    E_freq[ q(β̂) ] = q(μ) + tr(CV)/(k−1) = θ + v,   v ≈ b                       (2)

This is precisely the inflation the shipped frequentist **point** estimator removes
(`theta2r_fixed_nested()`: point = q(β̂) − v). So the raw per-draw posterior mean sits at
θ + 2v; subtracting one b lands at θ + v — the corrected draws are still centered one full
plug-in bias above the estimand. The full correction is 2b: one b for the push-forward
(identity (1), uses Σ_post exactly), one b for the plug-in bias of the center (identity (2),
uses Σ_post as the BvM-consistent estimate of V).

**Why "mirrors `theta2r_nested_draws()` exactly" is true but not sufficient.** The frequentist
helper subtracts 1×v from its N(β̂, V) draws — and its draws are therefore centered at
q(β̂) = point + v. That displacement is *documented as deliberate* in `theta2r_fixed()`'s
interval note, and is tolerable there because the frequentist **point estimate is computed
separately** and is unbiased; only the interval carries the displacement, and in the flat/crossed
regime v is negligible (M3 O6: coverage 0.950/0.947). The Bayesian engine has no separate point:
**the MAP is read off the same draws**, so any displacement of the draw distribution is inherited
by the reported coefficient. That structural asymmetry is why copying the frequentist interval
construction — the brief's proposal — under-serves the Bayesian pipeline. (It also means the
shipped frequentist nested *interval* shares a 1×v displacement; see §6.)

**Why raw was fine in M26/Slice 1 and is not fine here.** In crossed designs the k rater means
are estimated from all N subjects, so v ~ σ²_res/N → both inflations are negligible (the ~0.002
observed at M26 build). In the nested design v_c = tr(C·V_c)/(k−1) = **σ²_res/n_s exactly** on
balanced data (the σ²_{s:c}·J part of V_c is annihilated by the centering C) — it depends only on
the *per-cluster* subject count and **does not shrink as clusters accrue**, while the posterior
of the cluster-average tightens as 1/√C_n. So the raw (and half-corrected) intervals are
displaced by a constant while their width shrinks: coverage *degrades toward zero as C_n grows*
(§3 table — 0.17 → 0.00 raw, 0.73 → 0.17 half, at C_n 20 → 80). This is the incidental-parameters
pathology (flat priors on C_n·k cell means, a convex functional of all of them); it is a
consistency failure, not a small-sample refinement. ADR-036's rationale — "a posterior already
integrates the parameter uncertainty the − bias removes" — should be scoped in the ADR-037
amendment: it is correct for functionals *linear* in β and numerically harmless whenever
tr(CΣ_post) ≈ 0, but for a convex quadratic functional the push-forward is inflated per identity
(1) *and* its center per (2). It was the right call in M26's regime for the wrong general reason.

## 2. Answers to the six questions

**Q1 — Is `− tr(C·Σ_post)/(k−1)` the correct correction?** It is the correct *push-forward*
correction and exactly half of the correct *total* correction; subtract it twice (§1). Among
"more principled" alternatives: evaluating q at posterior-mean-*shrunken* means alone is worse
(it removes neither inflation exactly and adds shrinkage distortion under a flat prior there is
no shrinkage anyway). The genuinely principled fully-Bayesian route is a **hierarchical prior on
the within-cluster rater effects** (μ_cj = α_c + η_cj, η ~ N(0, τ²), half-t(4,0,1) hyperprior on
τ — the ten Hove 2020 posture the engine already uses for SDs), with θ²_{r:c} read per draw from
the *realized* η draws. That posterior is calibrated by construction (shrinkage replaces the
subtraction) and handles the boundary gracefully (τ → 0 concentrates q at 0). I recommend it as
a **scoped future alternative** (own ADR, own validation), not the Slice-2 ship: it changes the
model formula away from the fixed-effects parity contract with `fit_glmmtmb_nested_fixed()` and
introduces a new prior-sourcing decision. The moment-corrected push-forward recommended here is
the Bayesian analog of the already-pinned frequentist pipeline and stays inside ADR-037's scope.

**Q2 — Constant subtraction as an interval device.** Subtracting a per-cluster constant is the
right *shape* of fix: to first order the posterior spread of q(β^(d)) already matches the
sampling spread of the frequentist estimator (the linear terms 2εᵀCβ̄/(k−1) dominate and agree
under BvM), so the interval only needs recentering, and a constant shift is exactly that. The
residual −6.5% MAP bias the brief flags is quantitatively explained as: −4.4 points of *remaining
plug-in inflation* (the missing second b: v = 0.1 on θ² maps to −4.4% on the ICC in this DGP)
plus ≈ −2 points of mode-below-mean skew (ADR-033). With 2b the prediction is ≈ −2% and ~nominal
coverage. No differently-constructed posterior of q(μ_true) is needed at this scope; the
percentile read of the recentered draws has the usual (mild) skew-direction caveat of percentile
intervals — characterize in the validation sim (#18), don't correct.

**Q3 — Flooring.** Change it: **do not floor per cluster; floor the per-draw average.** Verified
head-to-head (§4, `fable-check-floor.R`, full 2b correction, C_n = 20):

| true θ²_{r:c} | per-cluster floor: mean / coverage | average floor: mean / coverage |
|---|---|---|
| 0.6616 (interior) | 0.661 / 0.973 | 0.659 / 0.973 |
| 0.10 (= v, near boundary) | 0.137 (+37%) / 0.910 | 0.099 (unbiased) / 0.985 |
| 0 (boundary) | 0.061 / **0.000** | 0.015 / 0.998 |

The mechanism: with the honest 2b correction, per-cluster draws near the boundary are negative
about half the time; `pmax(0, ·)` per cluster converts that noise into strictly positive
contributions in *every* cluster, so every draw of the average is strictly positive, the interval
lower endpoint is bounded away from 0, and coverage of θ² = 0 is *identically zero* — the exact
opposite of boundary-aware (#3). Letting negative per-cluster draws cancel across clusters and
flooring only the average is unbiased at θ² = v, correctly conservative at θ² = 0 (mass at 0, so
the interval reaches the boundary), and indistinguishable in the interior. Jensen's-inequality
intuition in the brief's Q3 is right, and the effect is not small. (The frequentist path floors
per cluster; that is a parity break to *document*, and a follow-up question for the frequentist
engine — §6 — not a reason to copy it.)

**Q4 — Unify the crossed helper.** Yes, unify. With the correction written as
2·tr(CΣ_post)/(k−1), the crossed case is the C_n = 1, whole-sample-V regime where the term is
~0 (the observed ~0.002); unification gives one estimator that is correct in both regimes and
retires a regime-split that would otherwise need its own documentation and a "which regime am I
in" judgment at every future extension (replicates, imbalance). Re-run the O-Bayes-FML checks
after unifying — containment tolerances will hold. M26 single-level stays shipped as-is (out of
scope per the brief), but amend ADR-037 to scope ADR-036's rationale as in §1, so the next
Bayesian fixed-rater slice doesn't re-inherit the unscoped version of the argument.

**Q5 — Empirical Σ_post adequacy.** Sound. For the push-forward term, identity (1) needs the
*marginal* posterior covariance of the cell means, and the empirical covariance of the draws is
exactly that (MC error on the trace at 4000 draws is ~2% of b — negligible against the effects at
stake). For the plug-in term, Σ_post is the BvM-consistent stand-in for V; with VC-posterior
mixing Σ_post ⪆ V, so the second subtraction slightly *over*-corrects — second-order,
conservative, visible (if at all) as a slightly-low posterior mean in the confirmation sim.
Ignoring cross-cluster blocks is exactly right: q_c depends only on cluster c's means, so only
`Σ_post[ix, ix]` enters (1); cross-cluster posterior correlations (shared VC uncertainty) affect
joint spread mildly and bias not at all. Optional refinement, not required: on the declared
balanced/complete scope b_c has the closed form σ²_res^(d)/n_s, computable *per draw*, which
propagates VC uncertainty into the correction and removes the MC error; keep the trace form for
parity with the engine-agnostic frequentist helper unless the sim shows it matters (it won't at
these sizes).

**Q6 — Robustness.** The correction's magnitude is σ̂²_res/n_s regardless of k and C_n, so:
large n_s → all variants converge (raw becomes acceptable); growing C_n → the correction becomes
*essential* (§1; raw coverage → 0); small k → the χ²_{k−1}-type quadratic term is most skewed at
k = 2, where the percentile skew caveat and the boundary flooring interact most — include k = 2
in the validation grid. Recommended confirmation grid before ship (seeded, committed, #4):
k ∈ {2, 4}, n_s ∈ {3, 5, 20}, C_n ∈ {5, 20, 80}, θ²_{r:c} ∈ {0, σ²_res/n_s, 0.66}. Expect
~nominal coverage everywhere with the §0 estimator, mild conservatism at the boundary rows and
possibly mild percentile-skew deviation at k = 2 — characterize and document (#18), do not tune.

## 3. Why a conjugate-normal check is valid evidence here

The brms model differs from "flat-prior normal posterior on cell means given VCs" only through
the weak half-t(4,0,1) prior on the single random-effect SD and the VC-posterior mixing — neither
touches the two identities in §1, which are exact in the conjugate case and BvM-consistent
otherwise. So the displacement arithmetic can be verified in seconds without Stan
(`fable-check-fnml.R`, seed 20271, 500 reps × 2000 draws, brief's DGP; θ²-level coverage —
narrower than the brief's ICC-level intervals, which get extra width from the σ²_{s:c} posterior,
so these coverages read lower than the brms table but rank identically):

| estimator | posterior mean (predicted) | coverage C_n=20 | coverage C_n=80 |
|---|---|---|---|
| raw | 0.8616 (0.8616 = θ+2v) | 0.174 | 0.000 |
| proposed 1×b | 0.7621 (0.7616 = θ+v) | 0.730 | 0.167 |
| full 2×b | 0.6641 (0.6616 = θ) | 0.962 | 0.963 |

The predictions are hit to ≲ 0.003 with no free parameter.

## 4. Reconciliation with the brief's brms table (independent confirmation of the factor 2)

With v = σ²_res/n_s = 0.1: θ² inflated by 2v gives ICC = 1/2.3616 → rel-bias −8.5%; by 1v gives
1/2.2616 → −4.4%. Predicted raw → 1×b improvement: **4.1 points**. Observed in the brief's
100-rep brms sim: −10.6% → −6.5% = **4.1 points**, exactly the one-v step; the common ≈ −2.1
extra in both rows is the MAP mode-below-mean skew. The brief's own data therefore confirm that
one more v of inflation remains after the proposed correction — the observed residual the brief's
Q2 asks about *is* the missing second b.

## 5. What to ship (consolidated)

In `brms_theta2r_nested_draws()`: compute `b <- tr(C Σ̂[ix,ix])/(k−1)` per cluster from the
empirical draw covariance; per draw take `q_c − 2*b_c` **without** flooring; average over
clusters; `pmax(0, ·)` the average. Implement the subtraction as two named terms
(`bias_pushforward + bias_plugin`, both equal to `b`) with a comment pointing at the two
identities, so the factor 2 is legible and not a magic constant. Unify `brms_theta2r_draws()`
(crossed) to the same code path (Q4). Rerun the brief's 100-rep sim (expect ≈ 0.95 / ≈ −0.02)
plus the Q6 grid, as *confirmation* of derived constants. Amend ADR-037 (and scope ADR-036's
rationale) citing this review.

## 6. Corollary finding, out of scope for this slice (frequentist engine)

The shipped frequentist nested-fixed **interval** (`theta2r_nested_draws()`) is the 1×-corrected
construction: its draws are centered v above the (unbiased) point, and it floors per cluster, so
it shares — attenuated by one v — the displacement documented here, and its interval cannot reach
θ² = 0 at all. `theta2r_fixed()`'s note explicitly accepts the displacement on the grounds that
"bias is small relative to the sampling SE", which is true in the flat/crossed case it was
written for (M3 O6) but not in the nested regime (v = σ²_res/n_s), and I could not find a
committed coverage sim for the *nested-fixed interval* specifically (O-FNML pins the point via
reductions and cross-engine). Recommend a separate task: seeded coverage sim for the frequentist
nested-fixed MC interval across the Q6 grid; if it undercovers, that is its own ADR (recentering
was explicitly deferred as "a separate decision" in the theta2r_fixed note — this is that
decision arriving). The point estimator is unaffected (it is unbiased as shipped, apart from the
same per-cluster-flooring boundary bias, +0.03 at θ² = 0 in this DGP).
