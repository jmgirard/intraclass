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
**2026-07-10**, during **M29** (ADR-039, branch `m29-bayes-conflated-replicates`) — Slice 1: the Bayesian
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
| `level` | `subject`, `cluster`, `conflated` | multilevel only |
| `design` | inferred / `crossed` / `nested_in_clusters` / `nested_in_subjects` | multilevel only |
| `engine` | `glmmTMB`, `lme4`, `lavaan`, `brms` | `brms` = two-way random (single-level, balanced **and incomplete/ragged**) **+ fixed + one-way** (single-level, balanced) + all multilevel (crossed D1 + nested D2/D3, subject level), **random and fixed** (fixed subject level, crossed D1 + nested D2) |
| `ci_method` | `montecarlo`, `bootstrap`, `posterior` | `posterior` = brms only (forced) |
| `brm_args` | list forwarded to `brms::brm()` | brms only |
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
| `engine = "brms"` + `raters = "fixed"` | ✅ **Shipped (M26 Slice 2, ADR-036)** — `score ~ 1 + rater + (1\|subject)`; **raw** θ²_r (McGraw & Wong Case-3A finite-population variance) read per posterior draw from the rater fixed-effect draws — **no** frequentist bias correction (the posterior integrates it; oracle-first resolution). Balanced/complete. Honest catch: balanced `fixed ≡ random` holds only **approximately** for brms (prior on σ_r vs flat on rater effects), so O-Bayes-Fixed pins **containment** (glmmTMB fixed inside the credible interval) + coverage, not pointwise equality. Numeric-`unit` D-study and incomplete brms stay deferred (cross-cutting section). |

**Gaps**

| Case | Reason |
|---|---|
| `unit = m` (D-study) with `raters = "fixed"` + `type = "agreement"` | ⚫ **By design** — θ²_r is the finite-population variance of exactly the observed raters; there is no "average of *m* freshly sampled raters" to project to (`icc.R` `abort_fixed_agr_projection`, M4.5 spec). Use `raters = "random"` or `type = "consistency"`. |
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
| `engine = "brms"` + `ci_method = "posterior"` | ✅ **Shipped (M29 Slice 2, ADR-039)** — `score ~ 1 + rater + (1\|subject) + (1\|subject:rater)` under the half-*t*(4,0,1) SD prior; the σ²_sr/σ²_e split and the `occasions` per-draw divisor (pure error ÷ n_o, interaction not divided) compose off the posterior draws exactly as the frequentist estimand (a variance-ratio push-forward, no θ² moment correction). Two-way random, balanced. O-Bayes-Rep: coverage + glmmTMB containment + average > single. Fixed-rater and multilevel Bayesian replicates stay deferred (the M20 Slice 1/2 siblings). |

**Gaps** (all M17 Slice 3 deferrals — `M17-within-cell-replicates.md` §7)

| Case | Reason |
|---|---|
| `raters = "fixed"` with replicates | ✅ (M20 Slice 1, balanced) — θ²_r (shared `theta2r_fixed()`) in the rater slot of `fit_{glmmtmb,lme4}_replicates_fixed`; θ²_r = σ²_r on balanced data, so fixed reproduces the random coefficients (O-FRep). Ragged×fixed and multilevel×fixed stay deferred. |
| multilevel (`cluster`) with replicates | ✅ (M20 Slice 2, balanced) — crossed Design 1 (`(1\|cluster:subject:rater)`, six components) and nested Design 2 (five); the residual splits into the interaction σ²_{csr} and pure error at the subject level. Design 3 replicate-split ⚫ by-design (multilevel one-way, no separable interaction); fixed×multilevel, conflated×replicates, and ragged×multilevel replicates deferred. Cross-engine + reduction (occasion-averaged == M5/M8 on cell means) oracles. |
| ragged / non-uniform replicates, **single-occasion** | ✅ (M20 Slice 3) — two-way random, the replicate analogue of M3: the shipped interaction fit + harmonic-mean `k_eff` (distinct raters/subject) + connectedness gate. Cross-engine + seeded-recovery oracles. Ragged×fixed and ragged×multilevel stay deferred (compound corners). |
| ragged replicates, **`occasions = "average"`** | 🟣 **Research** — with unequal per-cell counts the reliability of the mean of `n_o` replicates has no single scalar effective-`n_o` divisor (GT averaging weights are per-cell) and no textbook/independent oracle pins one; needs a simulation-oracle study before it can ship (M20 attempt-then-degrade, ADR-030; M17 §7). |
| `d_study()` projection off a replicate fit | ✅ (M22, ADR-032) — rater-count projection (single-level two-way + multilevel crossed D1 / nested D2), one curve per occasion setting; see the `d_study()` table below. Occasion projection and ragged-replicate projection stay 🔵/🟣 deferred. |
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
| `engine = "brms"` | ✅ **balanced** (M26 Slice 1, ADR-036) — `ICC(1)`/`ICC(1,k)` under the half-*t*(4,0,1) prior, MAP + percentile credible interval; incomplete/numeric-`m` brms deferred. |
| `ci_method` = montecarlo, bootstrap | ✅ (glmmTMB + lme4); ✅ **posterior** (brms, balanced) |

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
| **Design 1** crossed (5-component) | subject, cluster, conflated | agreement, consistency | random (both levels); fixed (subject only; balanced **and** incomplete) | balanced ✅; incomplete ✅\* | glmmTMB, lme4, **brms** (random subject+cluster — balanced M24, **incomplete/ragged M30 Slice 2**; **fixed subject — M27 Slice 1**; **conflated — M29 Slice 1**) |
| **Design 2** nested-in-clusters (4-component) | subject only | agreement, consistency | random (balanced+incomplete); **fixed** (balanced, M19 Slice 2) | balanced ✅; incomplete ✅ (M19 Slice 1) | glmmTMB, lme4, **brms** (balanced; random subject — M25 Slice 1; **fixed subject — M27 Slice 2**) |
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
| Design 1 incomplete, `level = "conflated"` | ✅ (M18 Slice 2) — well-posed on ragged data: Eq. 14 lumps the rater terms into one error, so it is the flat two-way ICC off the multilevel fit with the same flat `k_eff`. Cross-engine + Eq-14-identity + flat-tracking oracles; stays visibly biased vs the subject level (`M17-conflated-icc.md` §6a). |
| Design 1 incomplete, `raters = "fixed"` | ✅ (M18 Slice 1) — θ²_r read from the ragged rater-contrast fit; subject level; differs from random under imbalance (as single-level M3). Cross-engine + seeded-recovery oracles; lme4 degrades to glmmTMB at the boundary. |
| `level = "conflated"` + `type = "consistency"` | 🟣 **Research** — ten Hove Eq. 14 publishes only the *agreement* conflated ICC; a consistency form (drop σ²_r from the error set) is the natural symmetric extension but is **not in the paper**. Investigate whether a sourced/faithfully-derivable form with a #1/#4-strong oracle exists before exposing it; do not ship a guessed formula (ROADMAP, ADR-026). |
| `level = "conflated"` + `raters = "fixed"` | ⚫ **By design** — Eq. 14 treats the rater effect as a variance component (random raters); a fixed-rater conflated diagnostic is not defined by the source. |
| Design 2 / 3, cluster level | ⚫ **By design** — cluster-level IRR needs raters crossed with clusters; with nested raters only the subject level is defined (ten Hove et al. 2022, p. 6). |
| Design 3, `type = "consistency"` | ⚫ **By design** — with raters nested in subjects the rater main effect is confounded into residual, so only absolute agreement is defined (ten Hove et al. 2022, p. 6). |
| Design 2 / 3, incomplete data | ✅ (M19 Slice 1) — the fit formulas are ragged-safe and the averaged divisor is the harmonic-mean `k_eff`, which reduces **exactly** to the pinned M3 two-way / M6 one-way incomplete divisor (single-cluster Design 2 → ragged two-way, diff 0; Design 3 → ragged one-way). On **ambiguous** ragged data (missing cells blur crossed-vs-nested) an explicit `design=` is required (never guessed, decision A); Design 2 gains a within-cluster connectedness gate. Subject-level `d_study()` projects on ragged nested data too (M18 path). |
| Design 2, `raters = "fixed"` | ✅ (M19 Slice 2, balanced) — θ²_{r:c} is the mean over clusters of each cluster's finite-population rater variance (per-cluster McGraw–Wong Case 3A), via `score ~ 0 + rater + (1\|cluster:subject)`. **Fixed ≢ random even balanced** (per-cluster finite population; unlike crossed M10) — pinned by per-cluster + single-cluster reduction to the flat M3 fixed θ²_r, cross-engine, consistency≡random. Incomplete fixed-nested deferred (k_eff × per-cluster θ² interaction). |
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
| `engine = "brms"` + `ci_method = "posterior"` (Bayesian credible intervals) | ✅ **Shipped (M23, ADR-033; M24, ADR-034; M25, ADR-035; M26, ADR-036; M27, ADR-037; M29, ADR-039)** — the Bayesian engine: two-way **random** (M23), **crossed (Design 1) multilevel random** (M24 — subject + cluster levels, ten Hove's native turf), **nested Designs 2/3 multilevel random** (M25 — subject level; Design 2 agreement/consistency, Design 3 agreement-only / multilevel one-way), agreement/consistency, single/average, balanced/complete; half-*t*(4,0,1) prior on every random-effect SD (ten Hove et al. 2020), MAP point + percentile **credible** interval, `posterior` forced/Bayesian-only, `brm_args` passthrough. Plus single-level **one-way** (`ICC(1)`/`ICC(1,k)`) and **fixed-rater** two-way, balanced (M26, ADR-036); **and fixed-rater multilevel subject level — crossed Design 1 (M27 Slice 1) + nested Design 2 (M27 Slice 2), balanced (ADR-037)**: θ²_r/θ²_{r:c} per posterior draw, **moment-corrected (2b + boundary-aware average-floor** — the ADR-037 Fable review; the naïve raw push-forward undercovers the nested finite population). **And the conflated diagnostic — `level = "conflated"`, Eq. 14 composed off the crossed five-component draws (M29 Slice 1, ADR-039) — plus single-level two-way random within-cell replicates (M29 Slice 2): the σ²_sr/σ²_e split with the `occasions` per-draw divisor; both variance-ratio push-forwards, no θ² moment correction.** Oracles O-Bayes (two-way) + O-Bayes-ML (crossed ml) + O-Bayes-NML (nested) + O-Bayes-OW (one-way) + O-Bayes-Fixed (single-level fixed) + **O-Bayes-FML (crossed fixed ml) + O-Bayes-FNML (nested fixed ml, interior + boundary cells) + O-Bayes-Conflated (Eq-14 identity + coverage + glmmTMB containment) + O-Bayes-Rep (single/average coverage + glmmTMB containment + average > single)** — committed coverage references. **And incomplete/ragged RANDOM-rater fits (M30, ADR-040): two-way random single-level (Slice 1, `fit_brms_twoway()` on ragged data + the M3 `k_eff` divisor per draw) and crossed (Design 1) multilevel random (Slice 2, `fit_brms_multilevel()` on ragged data + the M9 `k_eff`/connectedness; subject + cluster ICC(c,1), averaged ICC(c,k) dropped-with-note) — variance-ratio push-forwards, no θ² correction; O-Bayes-Incomplete / O-Bayes-IML pin reduction-to-M23/M24 + ragged coverage (subject-level nominal .965 / .97; cluster ICC(c,1) tracks complete) + glmmTMB M3/M9 containment.** Bayesian **incomplete nested** (Designs 2/3) and **incomplete fixed-rater**, **fixed-rater / multilevel replicates**, **cluster-level & Design-3 fixed** (⚫ by design), the averaged cluster-level `ICC(c,k)` incomplete divisor (🟣 Wave-3), `rstanarm`, selectable coupling, and HPDI intervals stay deferred (follow-ons; ROADMAP). |
| categorical / ordinal ratings (GLMM engines) | 🔵 **Not yet** — unscheduled; needs its own estimand pass (link/family choice + oracle registry) before it is schedulable (ROADMAP). |
| non-parametric bootstrap / profile-likelihood CIs | 🔵 **Not yet** — method-comparison nice-to-have; the *parametric* bootstrap shipped in M16 (ADR-025), the rest is unscheduled. |
| lme4 boundary-robust interval for singular fits / merDeriv edge cases | 🔵 **Not yet (deprioritized)** — glmmTMB covers the singular-fit case today via the degrade-to-glmmTMB handoff; opportunistic parity only (ROADMAP). |
