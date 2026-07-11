# Fable review brief — INCOMPLETE/ragged fixed-rater nested θ²_{r:c} (M36, ADR-046)

**Status:** gated statistical review (PRINCIPLE #19), requested by the maintainer **after** the main
session (Opus) shipped M36 and concluded it did **not** need a Fable review. **The code is committed and
merged to `main`** (PR #41, `f5a19e8`) — unlike the M27/M28 briefs, this is a **post-hoc** review of
shipped work. Fable is asked to independently interrogate the derivations and scope decisions Opus made
*without* escalating. If Fable finds a shortfall, we open a follow-up fix (as M28 was the corrective
follow-up to M27). **Do not tune to the oracle (#4); characterize honestly (#18).** If the derivations
hold, say so plainly.

This is the **ragged sibling** of the M28 review (`fable-review-m28-nested-fixed-interval-{brief,response}.md`,
ADR-038), which fixed the **balanced** nested-fixed interval by moving to a **2b** moment correction with a
boundary-aware **average-floor**. M36 generalizes that construction to **incomplete/ragged** data with
**unequal per-cluster rater counts k_c**. The central question is whether the M28 fix survives that
generalization — and, honestly, whether Opus's coverage evidence was even positioned to detect the failure
mode M28 found.

---

## 1. Context and the estimand

Nested Design 2 (raters nested in clusters), raters **fixed**, on **ragged** data (missing subject×rater
cells and/or unequal k_c across clusters). Fit `score ~ 0 + rater + (1 | cluster:subject)`, REML (glmmTMB;
lme4 cross-engine). Subject-level agreement error set {rater, residual} (M8 §3a):

    ICC_s(A,1) = σ²_{s:c} / (σ²_{s:c} + θ²_{r:c} + σ²_res)

**θ²_{r:c}** is the mean over clusters of each cluster's within-cluster finite-population rater variance,
now with **each cluster's own k_c**:

    θ²_{r:c} = mean_c q_{k_c}(μ_c),   q_k(x) = xᵀ C_k x /(k−1),   C_k = I_k − J/k

**Shipped POINT** (`theta2r_fixed_nested()`, generalized in M36):

    θ̂²_c = q_{k_c}(β̂_c) − b_c,   b_c = tr(C_{k_c} · V_c)/(k_c − 1),   θ̂²_{r:c} = max(0, mean_c θ̂²_c)   # 1b, average floor

**Shipped MC INTERVAL** (`theta2r_nested_draws()`, generalized in M36): draw β^(d) ~ N(β̂, V) on the natural
scale; per cluster

    θ_c^(d) = q_{k_c}(β^(d)_c) − 2 b_c,   θ_{r:c}^(d) = max(0, mean_c θ_c^(d))                            # 2b, average floor

β̂_c = the fitted rater cell means in cluster c (from `score ~ 0 + rater`); V_c = the corresponding block of
`vcov(fit)$cond`. **The per-cluster generalization is: `C`, `k`, and `b` are per-cluster (a list of centers,
a vector of k_c) instead of shared scalars.** On balanced/equal-k data this is **bit-identical** to the
M28-shipped construction (verified |diff| = 0), so M28's O-NFI is unmoved. The shared
`theta2r_moment_draws()` (flat/crossed/lavaan) is untouched.

## 2. What Opus decided WITHOUT escalating — the review targets

**(Q1) Is the 2b moment correction still exact under ragged, unequal-k V_c?** M28's derivation (its §1 /
`fable-check-nfi.R`) rested on the **balanced** identity β̂_c ~ N(μ_c, V) with V = (σ²_{s:c}/n_s)J +
(σ²_res/n_s)I, giving b = tr(CV)/(k−1) = σ²_res/n_s **exactly** (C annihilates J). The "two equal
inflations" (push-forward of the draws + plug-in of the center) are each exactly b there. **On ragged data
none of that closed form holds:** cell counts differ within a cluster, β̂_c has a non-scalar covariance
(the J-block is no longer rank-1 with equal loadings; there is subject-mean leakage across the unequal
cells), and b_c is read from the engine's `vcov`. Opus asserted the same "2b + average-floor" construction
carries over "per cluster with its own k_c" and treated b_c from `vcov` as still the right single inflation.
**Is E_draw[q(β^(d)_c)] = q(β̂_c) + b_c and E[q(β̂_c)] = θ²_c + b_c both still exact (or adequately
approximate) when V_c is the ragged `vcov` block?** Or does ragged imbalance break the equality of the two
inflations, so 2b over- or under-corrects?

**(Q2) — the honest gap — was the coverage evidence positioned to see the M28 pathology at all?** The M28
finding was an **incidental-parameters collapse**: boundary coverage **decayed with cluster count**
(.95/.86/.57 as C_n = 5/20/80; worst ≈.37 at C_n=80). **Opus's O-IFNML grid used only ~6 clusters** (kc
vectors of length 6) at n_rep 240, and reported boundary θ²=0 coverage **.942**. A single low-cluster cell
is exactly where M28's *pre-fix* interval also looked fine (.95 at C_n=5) — the collapse only appeared as
clusters accrued. **So the .942 Opus cites does not, on its own, rule out a cluster-count decay under the
ragged 2b.** Fable is asked to run the coverage over a **cluster-count sweep** (e.g. C_n ∈ {5, 20, 80},
mixing equal and unequal k_c, θ² ∈ {0, interior}) and report whether boundary coverage holds or decays.
This is the single most important check; Opus should have run it in O-IFNML and did not.

**Preliminary sweep (committed, `fable-check-m36.R`, N_REP=120 — below the ≥240 verdict bar, so
indicative not authoritative):** equal-k_c=4, n_s=4, p_keep=0.8, boundary θ²=0 coverage **C_n=5/20/80 =
1.000/.958/.950**; interior .983/.950/.958. **No decay** — coverage settles to nominal ~.95 at C_n=80 (mild
boundary-aware conservatism at low C_n), the M28 *post*-fix signature, NOT the pre-fix collapse
(.95/.86/.57). This is reassuring for Q2, but Fable should (a) confirm at N_REP≥240, (b) push n_s down and
k_c to unequal/mixed regimes where the incidental-parameters effect is strongest, and (c) still adjudicate
Q1/Q3 on the derivation, not just the empirical coverage.

**(Q3) Does the averaged ICC_s(A,k_eff) divisor hold for a fixed per-cluster population under
cross-cluster imbalance?** Opus shipped the average with divisor `k_eff` = per-subject harmonic mean of
ratings/subject (pooled over all clusters), arguing it is the M19 random-nested divisor and **not** the open
per-cluster ICC(c,k) divisor. Evidence = an **exact** single-cluster reduction to flat M3 fixed (|diff|
~1e-16, both units). But a single cluster cannot exhibit cross-cluster mixing: when clusters have different
k_c (say 2 vs 5), subjects in different clusters have systematically different rating counts, and the pooled
harmonic k_eff blends them. **Is ICC_s(A, k_eff) with this pooled k_eff a coherent reliability for a fixed
per-cluster rater population, or does the fixed-population averaging require a per-cluster / weighted
divisor (the θ²_{r:c} the average divides is itself a cross-cluster mean)?** Opus has no multi-cluster
oracle for the average — only the single-cluster reduction + the (unequal-k) single-rater recovery.

**(Q4) Is the "non-circular recovery" oracle logic sound?** Opus's load-bearing oracle is seeded recovery
of a KNOWN finite-population θ²_{r:c} (raters fixed across replications), argued to be non-circular because
θ²_{r:c} is a deterministic function of the fixed rater means, and cross-engine (glmmTMB↔lme4) is argued to
validate only the raw fit, not the authored correction. **Is that reasoning valid** — in particular, does
recovering the truth at low bias actually certify the *bias correction* b_c (as opposed to being
insensitive to it at the sample sizes used)?

## 3. Evidence Opus committed (for Fable to reproduce / stress)

- Oracle **O-IFNML**: `data-raw/oracle-incomplete-fixed-nested.R` → committed fixture
  `tests/testthat/fixtures/incomplete-fixed-nested-oracle.rds`. Grid: {equal-k (k_c=4×6), unequal-k
  (k_c ∈ {2,3,4,5})} × {boundary θ²=0, interior θ²=0.5}; σ²_{s:c}=1, σ²_res=0.5; raters fixed across
  n_rep=240; subjects/residuals/missingness resampled per rep; single-rater ICC(A,1) coverage of the fixed
  value + point bias. **Reported:** coverage interior .967/.967, boundary .942/.942; |bias| ≤ .018;
  single-cluster reduction to flat M3 ~1e-16; cross-engine 2.6e-6. **All ~6 clusters.**
- Feasibility spike: `data-raw/reviews/m36-feasibility-spike-{point,coverage}.R` (8 clusters).
- Implementation: `R/engine-glmmtmb.R` `theta2r_fixed_nested()` (per-cluster k_c) + `theta2r_nested_draws()`
  (per-cluster 2b, average-floor); guard at `R/icc.R` (~L775, narrowed to refuse brms only).
- A starter harness `data-raw/reviews/fable-check-m36.R` (conjugate-normal + a glmmTMB cluster-count sweep
  skeleton) is committed alongside this brief for Fable to extend.

## 4. What a verdict should deliver

1. **Q2 first:** a cluster-count sweep verdict — does ragged boundary coverage hold to high C_n, or decay
   (the M28 pathology reborn under ragged 2b)? If it decays, the M36 interval is under-covering and needs a
   corrective follow-up (the M36 analog of M28), and O-IFNML must be regenerated over a cluster-count grid.
2. **Q1:** whether the 2b construction is exact/adequate under ragged unequal-k V_c, or needs a corrected
   inflation term.
3. **Q3:** whether the averaged-coefficient k_eff divisor is defensible for the fixed per-cluster population,
   or should be restricted (single-rater only) / re-derived.
4. **Q4:** whether the recovery oracle certifies the correction.

A clean bill on all four confirms Opus's "no Fable needed" call (belatedly). Any shortfall on Q1/Q2 is a
shipped-interval correctness bug (the point estimator is likely unaffected, as in M28). Recommend the fix;
do not tune to the fixture (#4).

## References
- ADR-046 (M36 scope); ADR-038 / `fable-review-m28-*` (the balanced 2b construction this generalizes);
  ADR-037 / `fable-review-m27-*` (the original nested-fixed finite-population finding).
- ten Hove, Jorgensen & van der Ark (2022) Design 2; McGraw & Wong (1996) Case 3/3A.
- `project/estimand-specs/M36-incomplete-fixed-nested.md`; `project/REFERENCES.md` (O-IFNML entry).
