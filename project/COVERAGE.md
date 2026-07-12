# Coverage map — what `icc()` supports today, and why the gaps are gaps

A current-state stock-take of the primary `icc()` / `d_study()` argument space:
which combinations are supported **right now**, and for each unsupported one, a
**reason category** so a gap is never mistaken for a bug (or for a decided
direction).

**This file is derived, not authoritative.** It is a convenience index over the
shipped code and the deferral lists. The sources of truth are the argument guards
in [`../R/icc.R`](../R/icc.R), the per-milestone *Deferred out of M<n>* lists in
[`MILESTONES.md`](MILESTONES.md), the parking lot in [`ROADMAP.md`](ROADMAP.md),
and the estimand-specs. **Refresh this file whenever a milestone ships** (it drifts
silently — no CI gate reads it, same hazard as `REFERENCES.md`). Last synced:
**2026-07-11**, during **M38** (ADR-048, branch `m38-brms-fixed-multilevel-parity`) — brms engine parity for
the two shipped frequentist fixed multilevel cells, closing the **brms** half of the (C) corner. **Cell 1**:
the Bayesian **fixed-rater cluster level** (crossed Design 1, balanced) — removing the brms cluster-drop guard
routes the cluster-level `(σ²_c | {θ²_r, σ²_cr}, k)` push-forward off the shipped M27
`fit_brms_multilevel_fixed()` draws (no new fit; `icc_estimand()` keys the cluster error set on `level` not
`raters`); M37's Outcome A (`b ≈ 0`, θ²_r = σ²_r) makes it a variance-ratio parity reducing to the M24 random
cluster level, so **O-Bayes-FCL** pins reduction + glmmTMB M37 containment (no coverage claim, no Fable).
**Cell 2**: the Bayesian **incomplete/ragged fixed-rater nested** (Design 2, subject level) — removing the
brms incomplete-fixed-nested guard lets `fit_brms_nested_fixed()` fit ragged data unchanged, with
`brms_theta2r_nested_draws()` → `brms_theta2r_moment_draws()` reading a **per-cluster** `k` so the
2b-under-imbalance moment correction (`b ≠ 0`) fires per cluster with the boundary-aware average-floor. The
milestone's genuine risk (the 2b going nested-brms for the first time) resolved **NOMINAL**: O-Bayes-IFNML
committed coverage .975/.954/.983/**.970** across {C_n 20, C_n 80} × {interior, boundary θ²=0}, the C_n=80
boundary showing **no incidental-parameters decay** — so Cell 2 shipped (the ADR-048 stop-and-replan branch
did not fire; no pin-loosening, no Fable). The **lavaan** cluster-fixed / incomplete-fixed-nested siblings are
**not** parity here — lavaan multilevel is unsupported (blocked on the multilevel-SEM lift); incomplete
cluster-level fixed stays 🟣 double-blocked.
Prior: during **M33** (ADR-043, branch `m33-bayes-parity-mopup`) Slice 1 — the Bayesian parity
mop-up: the engine now fits **incomplete/ragged single-level one-way** data (`ICC(1)`/`ICC(1,k)`), reusing
`fit_brms_oneway()` (M26 S1) unchanged by narrowing the `!balanced` brms guard's `oneway` clause; the M3/M6
harmonic-mean `k_eff` divisor threads per posterior draw — a variance-ratio push-forward (no θ² functional,
no 2b — the M30 regime). O-Bayes-IOneway pins reduction-to-M26 + ragged coverage of ICC(1) & ICC(1,k_eff) +
glmmTMB/lme4 M6+M3 containment. Slice 2 adds **fixed-rater within-cell replicates**
(`fit_brms_replicates_fixed()`, θ²_r per draw into the rater slot, 2b ≈ 0 on balanced data → θ²_r = σ²_r);
O-Bayes-FRep pins coverage .9625 + glmmTMB M20 S1 containment + average > single. Slice 3 adds **multilevel
within-cell replicates** — crossed Design 1 (`fit_brms_ml_replicates()`, six-component) + nested Design 2
(`fit_brms_nested_replicates()`, five-component), random raters, subject level; O-Bayes-MLRep pins coverage
(.95–.9625 both designs) + glmmTMB M20 S2 containment + average > single. **All three slices came back
nominal — no Fable review** (the M30 variance-ratio regime). The Bayesian parity mop-up is complete.
Prior: during **M32** (ADR-042, branch `m32-bayes-incomplete-nested`) — the Bayesian engine now
fits **incomplete/ragged nested random**-rater data at the subject level for **both** nested designs:
Design 2 (raters nested in clusters, Slice 1, `fit_brms_nested_clusters()`) and Design 3 (raters nested in
subjects, the multilevel one-way, agreement-only, Slice 2, `fit_brms_nested_subjects()`) — narrowing the one
`!balanced` brms guard's nested clause so the shipped M3/M9 harmonic-mean `k_eff` + connectedness /
per-subject identifiability (pre-dispatch, engine-agnostic) thread through, and — random raters being
variance ratios — no θ² moment correction engages. O-Bayes-INML-clusters / -subjects pin reduction (≡ M25 at
balance) + committed ragged coverage + live glmmTMB M19 containment. Scoped **random-only**: incomplete
*fixed* nested has no frequentist oracle (deferred all engines, ADR-029).
Prior: **M30/M31** (ADR-040/041) — Bayesian incomplete/ragged crossed random then fixed; **M29** (ADR-039,
branch `m29-bayes-conflated-replicates`) — Slice 1: the Bayesian
**conflated** diagnostic (`engine = "brms"` + `level = "conflated"`) composes ten Hove Eq. 14 off the
crossed five-component posterior draws; O-Bayes-Conflated pins Eq-14 identity + coverage + glmmTMB
containment. Slice 2: Bayesian **within-cell replicates** (`fit_brms_replicates()`, single-level two-way
random) — the σ²_sr/σ²_e split with the `occasions` per-draw divisor; O-Bayes-Rep pins single/average
coverage + glmmTMB containment + average > single. Both variance-ratio push-forwards, no θ² moment
correction. Prior: **M27** (ADR-037) — Bayesian **multilevel fixed-rater**: `engine = "brms"` +
`raters = "fixed"` covers the crossed Design 1 (Slice 1) and nested Design 2 (Slice 2) subject level,
balanced; θ²_r/θ²_{r:c} per posterior draw, **moment-corrected (2b + boundary-aware average-floor** per the
ADR-037 Fable review). Multilevel one-way was already brms (Design 3, M25). **M26** (ADR-036) — Bayesian single-level one-way + fixed-rater; **M25** (ADR-035) — Bayesian
**nested multilevel** (Designs 2/3, subject level); **M24** (ADR-034) — Bayesian **crossed (Design 1)
multilevel** (subject + cluster levels); **M23** (ADR-033, PR #28, the first Bayesian milestone — two-way random), **M22**
(PR #27, `d_study()` off a replicate fit), **M21** (PR #26, SEM parity), **M20** (PR #25, replicate
corners), M18/M19 (PR #23/#24).

**Scheduling:** the 🔵 *not yet* gaps below (excluding the cross-cutting section) were
planned as the **M18–M21 arc** (ADR-027) — each gap's target slice is noted in its reason
cell. **M18 (crossed-incomplete), M19 (nested), M20 (replicates), and M21 (SEM parity —
fixed-rater, incomplete/FIML, bootstrap) are done**, so **every arc 🔵 gap is closed**. Two
former 🔵 items were reclassified (multilevel SEM and lavaan+replicates → ROADMAP); see below.
One M20 item degraded to 🟣 research (occasion-averaged coefficient on ragged data — no
validated effective-n_o divisor).

## Reason taxonomy (why an unsupported case is unsupported)

| Tag | Meaning | Can it ever ship? |
|---|---|---|
| ✅ **Supported** | Works today. | — |
| 🔵 **Not yet** | Implementable with a known route; just not built/scheduled. | Yes — schedule a milestone. |
| 🟣 **Research** | Open modeling question with **no sourced/derivable oracle yet**; needs a simulation-oracle study (likely a Fable review, #19) before it *can* be built. | Maybe — only after the oracle question is settled. |
| 🔴 **Blocked** | Needs an external **source or decision that does not exist yet**; guessing a method is forbidden (#4, `ask-for-inaccessible-sources`). | Not until a source appears. |
| ⚫ **By design** | Structurally not a valid/identified coefficient (or reachable a different way). Not a gap to fill. | No — undefined by construction. |

## Primary axes

| Axis | Values | Scope |
|---|---|---|
| `model` | `twoway`, `oneway` | structural |
| `cluster` | absent / present | present ⇒ multilevel |
| within-cell replicates | inferred from data (>1 rating per subject×rater cell) | structural |
| `type` | `agreement`, `consistency` | two-way only |
| `raters` | `random`, `fixed` | two-way only |
| `unit` | `single`, `average`, numeric `m` | `m` = D-study projection |
| `occasions` | `single`, `average` | replicates only |
| `d_study(n_o = )` | numeric `n_o` | occasion D-study; replicates only, one axis per call |
| `level` | `subject`, `cluster`, `conflated` | multilevel only |
| `design` | inferred / `crossed` / `nested_in_clusters` / `nested_in_subjects` | multilevel only |
| `engine` | `glmmTMB`, `lme4`, `lavaan`, `brms` | `brms` = two-way random (single-level, balanced **and incomplete/ragged**) **+ fixed** (single-level, balanced **and incomplete/ragged**) **+ one-way** (single-level, balanced **and incomplete/ragged**, M33 S1) + multilevel: crossed D1 random (balanced **and incomplete**; subject + cluster `ICC(c,1)`) & fixed (subject balanced **and incomplete**; **+ cluster level balanced, M38 Cell 1**), nested D2 random (balanced **and incomplete/ragged**, M32 S1) & fixed (balanced **and incomplete/ragged, M38 Cell 2**), nested D3 random (balanced **and incomplete/ragged**, M32 S2, agreement-only) |
| `ci_method` | `montecarlo`, `bootstrap`, `posterior` | `posterior` = brms only (forced) |
| `brm_args` | list forwarded to `brms::brm()` | brms only |
| `prior` | `NULL` (sourced half-*t*(4,0,1)) / a \pkg{brms} prior object | brms only; custom = footgun-warned, voids coverage oracle (M34 S1, ADR-044) |
| `posterior_summary` | `percentile` (default) / `hpdi` | `posterior` only; HPDI = comparison alternative, no coverage claim (M34 S2, ADR-044) |
| data balance | balanced / incomplete (ragged) | |

---

## ① Single-level two-way (`model = "twoway"`, no `cluster`, one rating/cell)

| Choice | Status |
|---|---|
| `type` = agreement, consistency | ✅ |
| `raters` = random | ✅ (balanced **and** incomplete) |
| `raters` = fixed | ✅ (balanced **and** incomplete; incomplete genuinely differs from random) |
| `unit` = single, average, numeric `m` | ✅ |
| balance | ✅ balanced, ✅ incomplete/ragged |
| `engine` = glmmTMB, lme4 | ✅ (both, on balanced + ragged; ragged lme4 degrades to glmmTMB at the variance boundary) |
| `ci_method` = montecarlo, bootstrap | ✅ (glmmTMB + lme4) |
| `engine = "brms"` + `ci_method = "posterior"` | ✅ **Shipped (M23, ADR-033; incomplete M30 Slice 1, ADR-040)** — two-way **random** (agreement/consistency, single/average), **balanced/complete and incomplete/ragged**; half-*t*(4,0,1) prior, MAP point + percentile credible interval, `brm_args` passthrough. On ragged data the harmonic-mean `k_eff` divisor + connectedness (M3, ADR-008) thread per posterior draw (a variance-ratio push-forward — no θ² correction); O-Bayes-Incomplete pins reduction-to-M23 (complete cell) + ragged coverage of ICC(A,1) & ICC(A,k_eff) + glmmTMB M3 containment. |
| `engine = "brms"` + `raters = "fixed"` | ✅ **Shipped (M26 Slice 2, ADR-036; incomplete M31 Slice 1, ADR-041)** — `score ~ 1 + rater + (1\|subject)`; θ²_r (McGraw & Wong Case-3A finite-population variance) read per posterior draw from the rater fixed-effect draws, moment-corrected (2b) with a boundary-aware average-floor. **Balanced and incomplete/ragged**, single level. On balanced data the 2b correction is negligible (rater means from the whole sample); on **ragged** data the rater means come from unequal cell counts, so the 2b correction goes **live at the single level** and the M3 `k_eff` divisor + connectedness thread per draw. Honest catch: balanced `fixed ≡ random` holds only **approximately** for brms (prior on σ_r vs flat on rater effects), so O-Bayes-Fixed / O-Bayes-IFixed pin **containment** (glmmTMB fixed inside the credible interval) + coverage, not pointwise equality. The crossed (Design 1) fixed-rater **multilevel** subject level ships incomplete/ragged too (M31 Slice 2, O-Bayes-IFML-fixed); the crossed fixed **cluster** level ships balanced (M38 Cell 1, O-Bayes-FCL: reduction to the M24 random cluster level + glmmTMB M37 containment — `b ≈ 0`, a variance-ratio parity); and the **nested Design 2 fixed** subject level ships incomplete/ragged (M38 Cell 2, O-Bayes-IFNML: the 2b-under-imbalance moment correction per cluster, committed coverage nominal at C_n 20 & 80 incl. the θ²=0 boundary). Numeric-`unit` D-study brms and the **incomplete/unbalanced fixed cluster level** (all engines, 🟣 double-blocked) stay deferred (cross-cutting section). |

**Gaps**

| Case | Reason |
|---|---|
| `unit = m` (D-study) with `raters = "fixed"` + `type = "agreement"` | ⚫ **By design, RATER axis only** — θ²_r is the finite-population variance of exactly the observed raters; there is no "average of *m* freshly sampled raters" to project to (`icc.R` `abort_fixed_agr_projection`, M4.5 spec §4). Use `raters = "random"` or `type = "consistency"`. **The occasion axis (`d_study(n_o = )`) lifts this** (M39, ADR-049 §9.3): occasions are a random facet however raters are treated, so fixed absolute agreement projects freely over `n_o`. |
| `engine = "lavaan"` + `raters = "fixed"` | ✅ **Shipped (M21 Slice 2, ADR-031)** — SEM fixed-rater agreement is the McGraw & Wong Case-3A bias-corrected θ²_r (reduces to glmmTMB fixed AND random on balanced data). |
| `engine = "lavaan"` + incomplete data | ✅ **Shipped (M21 Slice 3, ADR-031)** — incomplete-design SEM via FIML (`missing = "fiml"`); consistency ≤8e-3 and agreement ≤1.5e-2 vs glmmTMB. Bootstrap gated on incomplete data (montecarlo only). |
| `engine = "lavaan"` + `ci_method = "bootstrap"` | ✅ **Shipped (M21 Slice 1, ADR-031)** — parametric bootstrap on complete data (simulate from the fitted SEM's implied moments → refit). |

---

## ② Single-level two-way with within-cell replicates (>1 rating/cell)

Supported **only** for two-way **random**, single-level, **balanced/complete**
replicated data (every cell present, equal replicate count). Splits σ²_res →
σ²_sr + σ²_e; `occasions = "average"` reports the reliability of the replicate mean.

| Choice | Status |
|---|---|
| `occasions` = single, average | ✅ |
| `engine` = glmmTMB, lme4 | ✅ |
| `engine = "brms"` + `ci_method = "posterior"` | ✅ **Shipped (M29 Slice 2, ADR-039; fixed-rater M33 Slice 2 + multilevel M33 Slice 3, ADR-043)** — `score ~ 1 + [rater +] (1\|subject/cluster terms) + (1\|…:subject:rater)` under the half-*t*(4,0,1) SD prior; the σ²_sr/σ²_e split and the `occasions` per-draw divisor (pure error ÷ n_o, interaction not divided) compose off the posterior draws exactly as the frequentist estimand. **Single-level two-way random** (M29) **and fixed-rater** (M33 S2, `fit_brms_replicates_fixed()`: θ²_r read per draw into the rater slot, 2b ≈ 0 on balanced data → θ²_r = σ²_r), plus **multilevel random** (M33 S3, `fit_brms_ml_replicates()` crossed Design 1 six-component + `fit_brms_nested_replicates()` nested Design 2 five-component, subject level) — all balanced. O-Bayes-Rep / O-Bayes-FRep / O-Bayes-MLRep: coverage + glmmTMB containment + average > single. **Fixed-rater** multilevel replicates stay deferred (the compound corner). |

**Gaps** (all M17 Slice 3 deferrals — `M17-within-cell-replicates.md` §7)

| Case | Reason |
|---|---|
| `raters = "fixed"` with replicates | ✅ (M20 Slice 1, balanced) — θ²_r (shared `theta2r_fixed()`) in the rater slot of `fit_{glmmtmb,lme4}_replicates_fixed`; θ²_r = σ²_r on balanced data, so fixed reproduces the random coefficients (O-FRep). Ragged×fixed and multilevel×fixed stay deferred. |
| multilevel (`cluster`) with replicates | ✅ (M20 Slice 2, balanced; **brms M33 Slice 3, ADR-043**) — crossed Design 1 (`(1\|cluster:subject:rater)`, six components) and nested Design 2 (five); the residual splits into the interaction σ²_{csr} and pure error at the subject level. glmmTMB/lme4 (M20 S2) **and brms** (M33 S3: `fit_brms_ml_replicates()` / `fit_brms_nested_replicates()`, random raters → variance-ratio push-forward, no θ²; O-Bayes-MLRep coverage + glmmTMB containment). Design 3 replicate-split ⚫ by-design (multilevel one-way, no separable interaction); fixed×multilevel, conflated×replicates, and ragged×multilevel replicates deferred (all engines). Cross-engine + reduction (occasion-averaged == M5/M8 on cell means) oracles. |
| ragged / non-uniform replicates, **single-occasion** | ✅ (M20 Slice 3) — two-way random, the replicate analogue of M3: the shipped interaction fit + harmonic-mean `k_eff` (distinct raters/subject) + connectedness gate. Cross-engine + seeded-recovery oracles. Ragged×fixed and ragged×multilevel stay deferred (compound corners). |
| ragged replicates, **`occasions = "average"`** | 🟣 **Research** — with unequal per-cell counts the reliability of the mean of `n_o` replicates has no single scalar effective-`n_o` divisor (GT averaging weights are per-cell) and no textbook/independent oracle pins one; needs a simulation-oracle study before it can ship (M20 attempt-then-degrade, ADR-030; M17 §7). |
| `d_study()` **rater-count** projection off a replicate fit | ✅ (M22, ADR-032) — single-level two-way + multilevel crossed D1 / nested D2, one curve per occasion setting; see the `d_study()` table below. |
| `d_study(n_o = )` **occasion-count** projection off a replicate fit | ✅ (M39, ADR-049) — the symmetric axis: hold raters at k_eff, sweep `n_o`; only pure error σ²_e divides by `m·n_o`, so the curve has a **finite ceiling** (< 1) and is well-posed for **fixed absolute agreement** (the rater axis's ⚫ abort is axis-specific). Single-level two-way (random + fixed, agreement + consistency) + multilevel (subject rises, cluster occasion-invariant/flat; crossed D1 + nested D2). O-OccDS (reduction / GT form / ceiling / fixed-agr lift / lme4 / seeded-sim coverage). **Ragged**-replicate occasion projection stays 🟣 (the effective-`n_o` divisor, next row). |
| `engine = "lavaan"` with replicates | 🔵 **Not yet (reclassified → ROADMAP unscheduled, ADR-027)** — SEM ∩ replicates is niche/low-value; not milestoned. |
| one-way with replicate-split components | ⚫ **By design** — one-way ignores rater identity, so the σ²_sr interaction is undefined; one-way already *uses* repeated ratings as its design (not a within-cell split). |

---

## ③ One-way (`model = "oneway"`)

Raters are interchangeable — `type` does not apply; coefficients are `ICC(1)` / `ICC(k)`.

| Choice | Status |
|---|---|
| `raters` = random | ✅ |
| `unit` = single, average, numeric `m` | ✅ |
| balance | ✅ balanced, ✅ incomplete |
| `engine` = glmmTMB, lme4 | ✅ |
| `engine = "brms"` | ✅ **balanced and incomplete/ragged** (M26 Slice 1, ADR-036; incomplete M33 Slice 1, ADR-043) — `ICC(1)`/`ICC(1,k)` (`score ~ 1 + (1\|subject)`) under the half-*t*(4,0,1) prior, MAP + percentile credible interval. On ragged data the M3/M6 harmonic-mean `k_eff` divisor threads per posterior draw — a variance-ratio push-forward (no θ² functional, no 2b correction — the M30 regime), reusing `fit_brms_oneway()` unchanged by narrowing the `!balanced` brms guard. O-Bayes-IOneway pins reduction-to-M26 (complete cell) + ragged coverage of ICC(1) & ICC(1,k_eff) + glmmTMB/lme4 M6+M3 containment. Numeric-`m` (D-study) brms deferred. |
| `ci_method` = montecarlo, bootstrap | ✅ (glmmTMB + lme4); ✅ **posterior** (brms, balanced **and incomplete/ragged**) |

**Gaps**

| Case | Reason |
|---|---|
| `raters = "fixed"` | ⚫ **By design** — one-way treats raters as interchangeable; a fixed rater set is not meaningful (`icc.R` one-way guard, M6 spec §5). |
| `cluster` (multilevel one-way via `model = "oneway"`) | ⚫ **By design** — the multilevel one-way *is* supported, but it is reached as Design 3 (raters nested in subjects) with `model = "twoway"` + nested data, not via `model = "oneway"` + `cluster`. |
| `engine = "lavaan"` (one-way via SEM) | 🔴 **Blocked** (ADR-014) — the SEM-GT literature covers crossed facet designs only; a wide-column parallel model gives *consistency*, not one-way, and an equal-intercept approximation is unsourced and inexact (0.157 vs 0.166 on SF). Not schedulable until a faithful source appears. |

---

## ④ Multilevel (`cluster` present, `model = "twoway"`)

Design inferred from the crossing pattern (or declared via `design`).

| Sub-design | `level` | `type` | `raters` | balance | `engine` |
|---|---|---|---|---|---|
| **Design 1** crossed (5-component) | subject, cluster, conflated | agreement, consistency | random (both levels); fixed (subject balanced **and** incomplete; **cluster balanced — M37, ADR-047**) | balanced ✅; incomplete ✅\* | glmmTMB, lme4, **brms** (random subject+cluster — balanced M24, **incomplete/ragged M30 Slice 2**; **fixed subject — balanced M27 Slice 1, incomplete/ragged M31 Slice 2**; **conflated — M29 Slice 1**) |
| **Design 2** nested-in-clusters (4-component) | subject only | agreement, consistency | random (balanced+incomplete); **fixed** (balanced M19 Slice 2, **incomplete/ragged M36**) | balanced ✅; incomplete ✅ (random M19 Slice 1, **fixed M36 Slice 1**) | glmmTMB, lme4 (random+fixed, balanced+incomplete), **brms** (balanced only; random subject — M25 Slice 1; **fixed subject — M27 Slice 2**) |
| **Design 3** nested-in-subjects (3-component; multilevel one-way) | subject only | agreement only | random only | balanced ✅; incomplete ✅ (M19 Slice 1) | glmmTMB, lme4, **brms** (balanced random, subject — M25 Slice 2) |

\* On **incomplete** Design 1: subject level is fully supported (random **and**
fixed-rater — M18 Slice 1); cluster level is `ICC(c,1)` only (averaged `ICC(c,k)` rows
are dropped — see gaps); the conflated diagnostic is not yet available on ragged data.

- `unit` in multilevel `icc()`: ✅ single, average. Numeric `m` (rater-count
  projection) is done through **`d_study()`** (both levels, M17 Slice 2), **not**
  through `icc(unit = m)` — see the `d_study()` note below.
- `ci_method`: ✅ montecarlo, bootstrap (glmmTMB + lme4); ✅ **posterior** (brms — crossed
  Design 1 random, subject + cluster levels, balanced (M24, ADR-034); nested Designs 2/3 random,
  subject level, balanced (M25, ADR-035); **and fixed-rater subject level, balanced — crossed Design 1
  (M27 Slice 1) + nested Design 2 (M27 Slice 2), ADR-037** — θ²_r/θ²_{r:c} read per posterior draw,
  **moment-corrected (2b + boundary-aware average-floor)** per the ADR-037 Fable review). **Multilevel
  one-way is Design 3, already brms since M25.** The **conflated** diagnostic is brms since **M29 Slice 1
  (ADR-039)** — Eq. 14 composed off the crossed five-component draws (a variance-ratio push-forward, no θ²
  moment correction). Bayesian **incomplete, replicates**, and **cluster-level / Design-3 fixed** stay
  deferred (cross-cutting section / ⚫ by design); single-level Bayesian fixed-rater and one-way shipped in
  M26 (ADR-036).

**Gaps**

| Case | Reason |
|---|---|
| Design 1 incomplete, averaged cluster-level `ICC(c,k)` | 🟣 **Research (Wave 3)** — the per-cluster effective-rater divisor behind a ragged cluster mean is an open modeling question with no textbook oracle; needs a simulation-oracle study, likely a Fable review (#19). `ICC(c,1)` ships; complete-data `ICC(c,k)` is unaffected (`M9-incomplete-multilevel.md` §9). |
| Design 1 **balanced**, cluster-level `raters = "fixed"` | ✅ (M37 Slice 2, ADR-047) — signal σ²_c, agreement error {θ²_r, σ²_cr}, read off the M10 fixed fit; a feasibility spike confirmed exact reduction to the M5 random cluster-level ICC (θ²_r = σ²_r AND σ²_cr unbiased under fixing). O-FCL reduction + lme4 cross-engine + non-circular seeded recovery. glmmTMB/lme4. |
| Design 1 **incomplete**, cluster-level `raters = "fixed"` | 🟣 **Research** — double-blocked: ten Hove (2022) flag the small-*k* estimator as open AND the averaged `ICC(c,k)` divisor is unresolved on incomplete data (the row above). Balanced cluster-fixed ships (M37); incomplete deferred to a later milestone (`M37-fixed-cluster-level.md` §7). |
| Design 1 incomplete, `level = "conflated"` | ✅ (M18 Slice 2) — well-posed on ragged data: Eq. 14 lumps the rater terms into one error, so it is the flat two-way ICC off the multilevel fit with the same flat `k_eff`. Cross-engine + Eq-14-identity + flat-tracking oracles; stays visibly biased vs the subject level (`M17-conflated-icc.md` §6a). |
| Design 1 incomplete, `raters = "fixed"` | ✅ (M18 Slice 1) — θ²_r read from the ragged rater-contrast fit; subject level; differs from random under imbalance (as single-level M3). Cross-engine + seeded-recovery oracles; lme4 degrades to glmmTMB at the boundary. |
| `level = "conflated"` + `type = "consistency"` | 🟣 **Research** — ten Hove Eq. 14 publishes only the *agreement* conflated ICC; a consistency form (drop σ²_r from the error set) is the natural symmetric extension but is **not in the paper**. Investigate whether a sourced/faithfully-derivable form with a #1/#4-strong oracle exists before exposing it; do not ship a guessed formula (ROADMAP, ADR-026). |
| `level = "conflated"` + `raters = "fixed"` | ⚫ **By design** — Eq. 14 treats the rater effect as a variance component (random raters); a fixed-rater conflated diagnostic is not defined by the source. |
| Design 2 / 3, cluster level | ⚫ **By design** — cluster-level IRR needs raters crossed with clusters; with nested raters only the subject level is defined (ten Hove et al. 2022, p. 6). |
| Design 3, `type = "consistency"` | ⚫ **By design** — with raters nested in subjects the rater main effect is confounded into residual, so only absolute agreement is defined (ten Hove et al. 2022, p. 6). |
| Design 2 / 3, incomplete data | ✅ (M19 Slice 1) — the fit formulas are ragged-safe and the averaged divisor is the harmonic-mean `k_eff`, which reduces **exactly** to the pinned M3 two-way / M6 one-way incomplete divisor (single-cluster Design 2 → ragged two-way, diff 0; Design 3 → ragged one-way). On **ambiguous** ragged data (missing cells blur crossed-vs-nested) an explicit `design=` is required (never guessed, decision A); Design 2 gains a within-cluster connectedness gate. Subject-level `d_study()` projects on ragged nested data too (M18 path). |
| Design 2, `raters = "fixed"` | ✅ (M19 Slice 2, balanced; **M36 incomplete/ragged, ADR-046**) — θ²_{r:c} is the mean over clusters of each cluster's finite-population rater variance (per-cluster McGraw–Wong Case 3A), via `score ~ 0 + rater + (1\|cluster:subject)`. **Fixed ≢ random even balanced** (per-cluster finite population; unlike crossed M10) — pinned by per-cluster + single-cluster reduction to the flat M3 fixed θ²_r, cross-engine, consistency≡random. **Incomplete/ragged (M36):** the per-cluster Case-3A center/(k_c−1) is generalized to each cluster's own **k_c** (unequal rater counts) + the 2b moment-corrected interval (`theta2r_nested_draws()`) per cluster; mixed-model engines (glmmTMB/lme4), subject level, single-rater + average. The **single-rater** ICC(A,1) has the load-bearing **non-circular finite-population recovery** oracle (O-IFNML: seeded truth recovery + boundary-aware MC coverage nominal — interior .967, boundary θ²=0 .942, |bias|≤.018, n_rep 240); the **average** ICC(A,k_eff) rides the exact single-cluster reduction to flat M3 (per-subject `k_eff` — the M19 random-nested divisor, **not** the open per-cluster `ICC(c,k)` divisor). The **brms** engine ships incomplete/ragged fixed-nested too (M38 Cell 2, O-Bayes-IFNML: the same per-cluster 2b moment correction on posterior draws; committed coverage nominal at C_n 20 & 80 incl. the θ²=0 boundary). |
| Design 3, `raters = "fixed"` | ⚫ **By design** — raters nested in subjects is the multilevel one-way (rater confounded into residual); no separable rater effect to treat as fixed (cf. one-way fixed, M6 §10). |
| any multilevel, `engine = "lavaan"` (multilevel SEM) | 🔵 **Not yet (reclassified → ROADMAP "later", ADR-027)** — a research-flavored two-level SEM-GT lift (the paper's multilevel estimator is Bayesian, not a plain lavaan model); sits beside the Bayesian engine, not in the M18–M21 arc. |
| any multilevel, `icc(unit = m)` numeric projection | ⚫ **By design (routed elsewhere)** — use `d_study()` for multilevel rater-count projection (M17 Slice 2); `icc()` aborts a numeric multilevel `unit` on purpose. |

---

## `d_study()` — reliability projection across rater counts

| Case | Status |
|---|---|
| two-way (random) rater-count projection | ✅ |
| multilevel rater-count projection, subject + cluster levels | ✅ (M17 Slice 2) |
| fixed-rater **absolute-agreement** projection | ⚫ **By design** — refused (same reason as ①: no "average of *m* fresh raters" for a fixed population). |
| **incomplete-data** multilevel projection | ✅ subject level (M18 Slice 3, crossed; **nested** Designs 2/3 via M19 Slice 1); cluster level dropped-with-note (bounded by the 🟣 Wave-3 `ICC(c,k)` incomplete divisor; nested designs have no cluster level). Projection moves only the divisor `m`, so the ragged subject fit projects unchanged (reduction to `ICC(A,k)` at `m = k_eff`; cross-engine; monotone/[0,1]). |
| **subjects-per-cluster** ("three-facet") projection | ⚫ **By design (not a d_study facet)** — ten Hove Eq. 13's cluster ICC has no subject facet; the subjects-per-cluster count is an efficiency/sample-size dimension, folded into the parked *design/power helpers* item, not a reliability projection ([[cluster-icc-no-subject-facet]], ADR-026 amendment). |
| bootstrap-projected `d_study()` bands | ✅ (M18 Slice 4) — the band follows the fit's `ci_method`: a bootstrap fit stores its resample components and `d_study()` reprojects them across *m* (at *m* = observed count the band equals the fitted `ICC(*,k)` bootstrap interval exactly). Package-wide (two-way, multilevel, incomplete), no new argument (ADR-025/028). |
| rater-count projection off a **within-cell replicate** fit | ✅ (M22, ADR-032) — uses the per-component `error_divisors` (rater/interaction ÷ `m`, pure error ÷ `m·n_o`); one curve per occasion setting (an `occasions` column). Slice 1 single-level two-way (fixed consistency via Spearman–Brown; fixed agreement refused); Slice 2 multilevel (crossed D1 + nested D2 — subject across occasions, cluster single-occasion). Reduction (`m=k_eff` → fitted `ICC(*,k)`) + cross-engine + Spearman–Brown + seeded-coverage oracles. |
| **occasion** (`n_o`) projection, and projection off a **ragged** replicate fit | 🔵 **Not yet** — the per-component divisor supports an occasion projection but it stays deferred (M17 §7); ragged-replicate projection is bounded by the 🟣 research occasion-averaged ragged divisor (M20/ADR-030). Both refused loudly (M22). |

---

## Cross-cutting (all designs)

| Case | Reason |
|---|---|
| `engine = "brms"` + `ci_method = "posterior"` (Bayesian credible intervals) | ✅ **Shipped (M23, ADR-033; M24, ADR-034; M25, ADR-035; M26, ADR-036; M27, ADR-037; M29, ADR-039)** — the Bayesian engine: two-way **random** (M23), **crossed (Design 1) multilevel random** (M24 — subject + cluster levels, ten Hove's native turf), **nested Designs 2/3 multilevel random** (M25 — subject level; Design 2 agreement/consistency, Design 3 agreement-only / multilevel one-way), agreement/consistency, single/average, balanced/complete; half-*t*(4,0,1) prior on every random-effect SD (ten Hove et al. 2020), MAP point + percentile **credible** interval, `posterior` forced/Bayesian-only, `brm_args` passthrough. Plus single-level **one-way** (`ICC(1)`/`ICC(1,k)`) and **fixed-rater** two-way, balanced (M26, ADR-036); **and fixed-rater multilevel subject level — crossed Design 1 (M27 Slice 1) + nested Design 2 (M27 Slice 2), balanced (ADR-037)**: θ²_r/θ²_{r:c} per posterior draw, **moment-corrected (2b + boundary-aware average-floor** — the ADR-037 Fable review; the naïve raw push-forward undercovers the nested finite population). **And the conflated diagnostic — `level = "conflated"`, Eq. 14 composed off the crossed five-component draws (M29 Slice 1, ADR-039) — plus single-level two-way random within-cell replicates (M29 Slice 2): the σ²_sr/σ²_e split with the `occasions` per-draw divisor; both variance-ratio push-forwards, no θ² moment correction.** Oracles O-Bayes (two-way) + O-Bayes-ML (crossed ml) + O-Bayes-NML (nested) + O-Bayes-OW (one-way) + O-Bayes-Fixed (single-level fixed) + **O-Bayes-FML (crossed fixed ml) + O-Bayes-FNML (nested fixed ml, interior + boundary cells) + O-Bayes-Conflated (Eq-14 identity + coverage + glmmTMB containment) + O-Bayes-Rep (single/average coverage + glmmTMB containment + average > single)** — committed coverage references. **And incomplete/ragged RANDOM-rater fits (M30, ADR-040): two-way random single-level (Slice 1, `fit_brms_twoway()` on ragged data + the M3 `k_eff` divisor per draw) and crossed (Design 1) multilevel random (Slice 2, `fit_brms_multilevel()` on ragged data + the M9 `k_eff`/connectedness; subject + cluster ICC(c,1), averaged ICC(c,k) dropped-with-note) — variance-ratio push-forwards, no θ² correction; O-Bayes-Incomplete / O-Bayes-IML pin reduction-to-M23/M24 + ragged coverage (subject-level nominal .965 / .97; cluster ICC(c,1) tracks complete) + glmmTMB M3/M9 containment.** Bayesian **incomplete nested** (Designs 2/3) and **incomplete fixed-rater**, **fixed-rater / multilevel replicates**, **Design-3 fixed** (⚫ by design), incomplete/unbalanced **cluster-level fixed** (🟣 double-blocked — the *balanced* cluster-level fixed and incomplete/ragged fixed-nested both ship in **M38** (ADR-048), O-Bayes-FCL / O-Bayes-IFNML), the averaged cluster-level `ICC(c,k)` incomplete divisor (🟣 Wave-3), `rstanarm`, and selectable coupling stay deferred (follow-ons; ROADMAP). **And a user `prior=` override (M34 Slice 1, ADR-044): any \pkg{brms} prior object replaces the sourced half-*t*(4,0,1) via a dedicated `icc(prior=)` argument — brms-only, injected into the `brms::brm` call (the `brm_args` guard still forbids setting `prior` there), for prior-sensitivity / method-comparison / simulation work. Correctness is a REDUCTION oracle (O-PriorReduce: `prior = NULL` and an explicit sourced prior agree bit-identically; a tight prior moves the estimate), NOT a coverage claim — a custom prior VOIDS the coverage guarantees, announced by a loud classed `intraclass_custom_prior` warning.** **And a `posterior_summary` choice (M34 Slice 2, ADR-044): `"percentile"` (default) vs `"hpdi"` credible interval under `ci_method = "posterior"` — the HPDI is the narrowest interval covering the credible mass (a dependency-free helper, index arithmetic matching `coda::HPDinterval`), offered for comparison only (percentile stays the default: transform-invariant, boundary-graceful, and nominal at small k per ten Hove 2020 §4.2). O-HPDI is a REDUCTION oracle (percentile default reproduces shipped intervals bit-identically; HPDI ≡ `coda::HPDinterval`, no wider than percentile, same MAP point), NOT a coverage claim. Setting `posterior_summary` off the posterior method aborts.** Selectable `posterior` coupling (MC/bootstrap on a Bayesian fit) stays deferred (ROADMAP). |
| categorical / ordinal ratings (GLMM engines) | 🔵 **Not yet** — unscheduled; needs its own estimand pass (link/family choice + oracle registry) before it is schedulable (ROADMAP). |
| non-parametric bootstrap / profile-likelihood CIs | 🔵 **Not yet** — method-comparison nice-to-have; the *parametric* bootstrap shipped in M16 (ADR-025), the rest is unscheduled. |
| lme4 boundary-robust interval for singular fits / merDeriv edge cases | 🔵 **Not yet (deprioritized)** — glmmTMB covers the singular-fit case today via the degrade-to-glmmTMB handoff; opportunistic parity only (ROADMAP). |
