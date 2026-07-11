# Estimand specification — M36: incomplete/ragged fixed-rater nested (Design 2), single-rater

**Scope of this document.** The precise population quantity the **nested Design-2**
subject-level interrater ICC targets when raters are treated as **fixed** (McGraw &
Wong 1996, Case 3/3A) and the data are **incomplete / ragged** — missing subject×rater
cells and/or **unequal per-cluster rater counts** k_c. This is the **ragged
generalization of M19 Slice 2** (`M10-fixed-multilevel.md` is the crossed sibling; read
M19's ADR-029 catch and `M8-nested-multilevel.md §3a` first). Like M9/M15/M18/M19, M36
is an **intersection of shipped machineries** and introduces *no new estimand concept*:

1. the **M19 nested fixed-rater θ²_{r:c}** (`theta2r_fixed_nested()`, ADR-029) — the
   per-cluster bias-corrected finite-population rater variance, averaged over clusters;
2. the **M3/M9 `k_eff`/connectedness + `design`-escape-hatch** machinery on ragged data
   (ADR-008/018), engine-agnostic, running *before* fit dispatch; and
3. the **M8 §3a nested subject-level estimand map** and the **M28 2b moment-corrected
   MC interval** (`theta2r_moment_draws()`, ADR-038), both inherited.

**Locked scope (ADR-046, maintainer-approved 2026-07-11; averaged-coefficient outcome
recorded below):**
- **Design 2 (raters nested in clusters) only, subject level only** (agreement +
  consistency). The headline deliverable is **single-rater `ICC_s(·,1)`** (the strongly
  pinned, non-circular finite-population recovery oracle). The **averaged `ICC_s(·,k)`
  ships too**: the ADR "attempt, else degrade" clause resolved to **ship** — its divisor
  is the per-subject harmonic `k_eff` (ratings/subject), which is the well-defined M19
  random-nested divisor and **reduces to flat M3 fixed EXACTLY at a single cluster** (both
  single and average, |diff| ~1e-16, §4). It is **NOT** the open per-cluster `ICC(c,k)`
  divisor (M9 §9) — ADR-046's "degrade to research" was a conflation of the two; the
  subject-level averaged divisor was never the open one.
- **Design 3 fixed** stays ⚫ by-design (raters nested in subjects = the multilevel
  one-way; no separable rater effect — M19/ADR-029); **cluster-level fixed** and the
  **lavaan/brms** engines are out of scope (deferred).
- **glmmTMB engine** (lme4 cross-engine oracle + selectable engine, ADR-002/012/024).

---

## 1. The one new derivation: ragged per-cluster Case-3A θ²_{r:c}

M19 fixed θ²_{r:c} = the **mean over clusters** of each cluster's within-cluster
bias-corrected finite-population rater variance (Case 3A *per cluster*), off the
cell-mean fit

```r
score ~ 0 + rater + (1 | cluster:subject)
```

M19 required **equal k per cluster** (`theta2r_fixed_nested()` guards it). The Case-3A
finite-population variance is defined for **any k_c ≥ 2**, so the ragged generalization
simply lets each cluster carry its own k_c. Per cluster c with rater cell means
μ_c (length k_c) and their covariance block V_c (from the fit's `vcov`):

- center_c = I_{k_c} − J/k_c  (removes the within-cluster grand mean)
- raw_c    = μ_cᵀ center_c μ_c / (k_c − 1)
- bias_c   = tr(center_c V_c) / (k_c − 1)   (mean sampling variance of the centred means)
- **θ²_{r:c} = max(0,  mean_c( raw_c − bias_c ))**   — floor the **average**, not each
  cluster (M28/ADR-038: per-cluster flooring gives every cluster a strictly-positive
  mean at θ²=0 → boundary bias + point-outside-own-CI; averaging first restores
  containment and is a no-op interiorly).

**Missing cells vs. unequal k_c.** When rater sets stay intact (missing subject×rater
cells only), k_c is still constant and this reduces to `theta2r_fixed_nested()` verbatim
— only V_c reflects the unequal cell information. When clusters lose whole raters, k_c
varies and the per-cluster generalization is load-bearing. Both are covered.

**Why cross-engine does not validate this (#18).** glmmTMB and lme4 agree on μ_c / V_c
(the raw fit) to < 1e-4, but the finite-population *correction* above is the **same
authored formula** in both — so cross-engine pins the extraction, **not** the
correction. The load-bearing oracle is therefore the seeded finite-population truth (§4).

---

## 2. The estimand (M8 §3a, θ²_{r:c} in the rater slot)

Subject-level components {σ²_{s:c} (signal), θ²_{r:c} (rater slot), σ²_{(s:c)r}
(residual)}; σ²_c is absorbed by the cell-mean fit (nested designs define only the
subject level). Single and average both ship (§Locked scope):

| | agreement | consistency |
|---|---|---|
| single `ICC_s(·,1)` | σ²_{s:c} / (σ²_{s:c} + θ²_{r:c} + σ²_{(s:c)r}) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}) |
| average `ICC_s(·,k_eff)` | σ²_{s:c} / (σ²_{s:c} + (θ²_{r:c} + σ²_{(s:c)r})/k_eff) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}/k_eff) |

with `k_eff` the per-subject harmonic mean of ratings/subject (the M19 random-nested
divisor). The **single-rater** row carries the load-bearing finite-population recovery
oracle (§4); the **average** row is pinned by the exact single-cluster reduction to flat
M3 (§4) — the same basis on which the random nested M19 Slice 1 ships its average.

Consistency is **identical to the random-rater case** (the rater term is unused); only
absolute agreement uses θ²_{r:c}. Fixed raters emit the classed `intraclass_fixed_raters`
warning (M2/M3/M10/M19). **Fixed ≢ random even on balanced data** here (the nested finite
population is per-cluster — the M19 finding, unchanged); on ragged data they diverge
further, so the pins are reductions to the flat M3 fixed estimand, not fixed≡random.

**Averaged `ICC_s(·,k_eff)` (§4) — ships.** The effective-rater divisor is the per-subject
harmonic `k_eff` (ratings/subject), the same divisor the random nested M19 Slice 1 ships;
it reduces to flat M3 fixed **exactly** at a single cluster (§4, |diff| ~1e-16), so the
"attempt, else 🟣 research" clause resolved to ship. This is the well-defined subject-level
divisor, **distinct from the open per-cluster `ICC(c,k)` divisor** (M9 §9, still deferred).

*Multi-cluster identity (Fable review 2026-07-11, RR §4a; the derivation behind the
single-cluster reduction).* The average-unit error is the mean per-subject error variance of
the averaged score, mean_s[(θ²_{c(s)} + σ²_res)/m_s] (each subject's own cluster's rater
variance, own rating count m_s — the M3/McGraw–Wong Case-3A averaging convention). Under
**homogeneous** per-cluster variance (θ²_c ≡ θ̄² = θ²_{r:c}), harmonic pooling of rating
counts *is* per-subject error-variance averaging:

    err = (θ̄² + σ²_res)·mean_s(1/m_s) = (θ̄² + σ²_res)/k_eff   — exactly the shipped denominator.

So the pooled `k_eff` is coherent for the cross-cluster mixture, not a convenience. *Caveat
(RR §4b):* under **heterogeneous** θ²_c the shipped form omits a second-order term
Cov_s(θ²_{c(s)}, 1/m_s) — zero when θ²_c is constant or rating counts are exchangeable across
clusters, ~.03 of ICC under deliberately stark heterogeneity (noisy rater sets co-occurring
with thin rating counts). This is a **definitional** choice of which single summary to report
(the random-nested model cannot even express it — one σ²_{r:c} by assumption), not an
estimation bug; we do **not** move to per-cluster/weighted divisors, which would inject the
noisiest, individually-unfloorable per-cluster θ̂²_c into the headline average (RR §4).

---

## 3. The interval (inherited M28 2b, generalized per-cluster)

Boundary-aware MC (ADR-003/038). Per draw, the joint parameter vector (rater cell-mean
betas natural-scale + log-SD subject + log-σ residual) is drawn from `vcov(fit, full =
TRUE)`; θ²_{r:c} is recomputed via `theta2r_moment_draws()` — per cluster
q_c = colSums(m_c ∘ (center_c m_c))/(k_c−1) − **2 b_c**, averaged over clusters, then the
average floored. The 2b (two equal inflations: undo the Gaussian push-forward + remove
the plug-in bias of the centre) is what made M28's nested interval cover; b_c comes from
the engine `vcov` that generates the draws (not the empirical draw covariance).

*Why 2b survives raggedness (Fable review 2026-07-11, RR §1).* The two inflations are
**Gaussian quadratic-form identities** (E[xᵀCx] = μᵀCμ + tr(CV), any V), not balanced-data
facts — the balanced closed form `b = σ²_res/n_s` was only an *analytic evaluation* of the
trace. On ragged data b_c is a consistent **plug-in estimate** read from the engine V̂_c
(which carries the subject-mean leakage the naive diagonal misses by up to ~12%); its error
enters the interval centre only at **second order** (measured mean_c(b̂_c − b_c^true) ≈ +6e-4
vs a mean b of .117) and is o(1) while the interval shrinks as C_n^{−1/2}, so no
incidental-parameters displacement rebuilds as clusters accrue. **REML is load-bearing** here
(`fit_glmmtmb_ml_model()`, `REML = TRUE`): the fixed-effect count grows ∝ C_n, so an ML fit's
Neyman–Scott bias in σ̂²_res would feed every b̂_c systematically — REML closes that channel.

---

## 4. Oracles (PRINCIPLES.md #1 — ≥2 independent) and provenance — **O-IFNML**

No textbook worked example (as M8–M10/M15/M18/M19). Correctness rests on, in
`tests/testthat/test-icc-fixed-multilevel.R` (or a sibling), regenerated by seeded
`data-raw/oracle-incomplete-fixed-nested.R` (`stopifnot`; the feasibility-spike scripts
are its seed):

- **O-IFNML/recovery (load-bearing, non-circular).** A seeded ragged Design-2 fixed
  simulation with **known fixed rater effects** → the finite-population θ²_{r:c} truth is
  the deterministic within-cluster variance of those effects → the estimator recovers it
  and `ICC_s(·,1)`. Spike: ICC bias **+0.1%** (equal k_c, 25% missing) / **−1.0%**
  (unequal k_c, 20% missing). MC-CI coverage **nominal** at n_rep ≥ 240 — spike **.964
  interior / .960 at the boundary θ²_{r:c}=0**, point-in-own-CI 1.00
  ([[ragged-coverage-nrep-240]]).
- **O-IFNML/reduction → M19 (balanced).** With k_c constant and complete, θ²_{r:c} and
  every §2 coefficient equal the shipped balanced M19 nested-fixed values **bit-identically**.
- **O-IFNML/reduction → M3 (per-cluster / single-cluster).** θ²_{r:c} == mean of the flat
  M3 fixed θ²_r fit on each cluster's data alone (ties to the sourced McGraw–Wong Case 3A);
  a single-cluster nested-fixed design's σ²_{s:c}/σ²_res reduce to the flat M3 components.
- **O-IFNML/lme4.** An independent lme4 fit reproduces σ²_{s:c}, σ²_res and (same θ²
  computation) every §2 coefficient to < 1e-4; lme4 degrades to glmmTMB at the boundary (M15).
- **Consistency ≡ random** exact; **regression guard:** the full M1–M19 suite stays green.

If `ICC_s(·,1)` cannot be pinned by recovery **and** a reduction, it is **not shipped**,
a Fable review is *recommended* (#19, the ADR-046 conditional posture), and work pauses.

---

## 5. Guardrails (PRINCIPLES.md #5)

- **≥ 2 raters per cluster** for θ²_{r:c}; **≥ 2 clusters**, and the M8 §7 minimum-viable
  N_c / raters-per-cluster identifiability thresholds, reused unchanged under imbalance.
- **Connectedness** (M3/M9): a disconnected ragged nested design aborts.
- **Ambiguous crossed-vs-nested pattern on ragged data:** explicit `design =
  "nested_in_clusters"` required — never guessed (#5, the M9 escape hatch).
- **`level = "cluster"`, Design 3 fixed, cluster-level fixed** all abort with classed
  errors (§scope; ADR-046). The **Bayesian** engine (`brms`) on ragged fixed-nested aborts
  with a case-naming message (mixed-model engines only this milestone).

---

## 6. Acceptance criteria (this estimand → code)

- Ragged Design-2 + `raters = "fixed"` + `design = "nested_in_clusters"` fits §1 and
  returns θ²_{r:c} (per-cluster, ragged-generalized) in the rater slot; the
  `intraclass_fixed_raters` warning fires.
- Single-rater **and average** agreement + consistency with boundary-aware MC CIs;
  **reduces to balanced M19 bit-identically** (k_c constant → the helper is bit-identical)
  and to the M3 per-cluster/single-cluster fixed estimand (both single and average); matches
  lme4 < 1e-3 on ragged data; consistency ≡ random exact.
- Seeded single-rater recovery + coverage (interior + boundary) committed at n_rep ≥ 240;
  the average rides the exact single-cluster reduction (its divisor is the M19 `k_eff`).
- Guards (§5) fire; complete/balanced and random paths untouched (regression green).

---

## 7. Out of scope for M36 (recorded for forward-compatibility)

- **Cluster-level fixed** raters (crossed or nested) — the other (C) corner; no scaffolding,
  ten Hove et al. 2022 flag the small-*k* estimator as open. Its own later milestone.
- **Design 3 fixed** (⚫ by-design — multilevel one-way, no separable rater effect).
- **lavaan / brms** incomplete-fixed-nested (engine parity; brms was random-only in M32 for
  the same no-oracle reason — now unblockable given M36's frequentist oracle).

---

## References

- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater reliability for
  multilevel data: A generalizability theory approach. *Psychological Methods, 27*(4),
  650–666. (Nested Design 2 subject-level decomposition — Eqs. 8–11, Table 3 middle;
  inherited from M8. The paper is a random-effects framework and defines no fixed-rater
  coefficient.)
- McGraw, K. O., & Wong, S. P. (1996). *Psychological Methods, 1*(1), 30–46. (Case 3/3A —
  the finite-population θ² generalized here to ragged per-cluster k_c.)
- ADR-046 (scope + feasibility spike); ADR-029 (M19 balanced nested fixed — the deferral
  this lifts); ADR-038 (M28 — the 2b `theta2r_moment_draws()` this generalizes); ADR-008
  (M3 `k_eff`/Case-3A); ADR-018 (M9 incomplete crossed + `design` escape hatch); ADR-024
  (M15 incomplete lme4 parity). Full provenance for asserted O-IFNML values is registered
  in `REFERENCES.md` when the oracle is committed (Slice 1).
