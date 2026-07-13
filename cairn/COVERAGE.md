# Coverage map — what `icc()` supports today, and why the gaps are gaps

A current-state stock-take of the primary `icc()` / `d_study()` argument space:
which combinations are supported **right now**, and for each unsupported one, a
**reason category** so a gap is never mistaken for a bug (or for a decided
direction).

**This file is derived, not authoritative.** It is a convenience index over the
shipped code and the deferral lists. The sources of truth are the argument guards
in [`../R/icc.R`](../R/icc.R), the per-milestone *Deferred out of M<n>* lists in
[`legacy/MILESTONES.md`](legacy/MILESTONES.md), the candidate rows in
[`ROADMAP.md`](ROADMAP.md) + the parking-lot detail in
[`legacy/ROADMAP.md`](legacy/ROADMAP.md), and the estimand-specs. History (the
per-milestone narrative of *when* each cell shipped) lives in git + `legacy/`, not
here. **Refresh this file whenever a milestone changes the arg space** — it drifts
silently (no CI gate reads it, same hazard as `references/INDEX.md`).

**Last synced: 2026-07-13, through M47** (M44 vectorized `type`; M45 shipped
consistency-conflated; M46/M47 shipped the averaged cluster-level `ICC(c,k)` on
incomplete data, glmmTMB/lme4 then brms). Milestone/ADR ids below are provenance
tags — follow them to `legacy/` for the full story.

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
| `type` | `agreement`, `consistency` — **vectorized** (M44, ADR-054): a default two-way call returns all four ICC(A,1)/ICC(A,k)/ICC(C,1)/ICC(C,k) from one fit; a scalar filters to one. No computed value changed. | two-way only |
| `raters` | `random`, `fixed` | two-way only |
| `unit` | `single`, `average`, numeric `m` | `m` = D-study projection |
| `occasions` | `single`, `average` | replicates only |
| `d_study(n_o = )` | numeric `n_o` | occasion D-study; replicates only, one axis per call |
| `level` | `subject`, `cluster`, `conflated` | multilevel only |
| `design` | inferred / `crossed` / `nested_in_clusters` / `nested_in_subjects` | multilevel only |
| `engine` | `glmmTMB`, `lme4`, `lavaan`, `brms` | `brms` covers a wide surface — see the brms row in Cross-cutting for the exact cells |
| `ci_method` | `montecarlo`, `bootstrap`, `posterior` | `posterior` = brms only (forced) |
| `brm_args` | list forwarded to `brms::brm()` | brms only |
| `prior` | `NULL` (sourced half-*t*(4,0,1)) / a \pkg{brms} prior object | brms only; custom = footgun-warned, voids coverage oracle (M34, ADR-044) |
| `posterior_summary` | `percentile` (default) / `hpdi` | `posterior` only; HPDI = comparison alternative, no coverage claim (M34, ADR-044) |
| data balance | balanced / incomplete (ragged) | |

---

## ① Single-level two-way (`model = "twoway"`, no `cluster`, one rating/cell)

| Choice | Status |
|---|---|
| `type` = agreement, consistency | ✅ (both, and all four A1/Ak/C1/Ck from one fit — M44) |
| `raters` = random | ✅ (balanced **and** incomplete) |
| `raters` = fixed | ✅ (balanced **and** incomplete; incomplete genuinely differs from random) |
| `unit` = single, average, numeric `m` | ✅ |
| balance | ✅ balanced, ✅ incomplete/ragged |
| `engine` = glmmTMB, lme4 | ✅ (both, on balanced + ragged; ragged lme4 degrades to glmmTMB at the variance boundary) |
| `ci_method` = montecarlo, bootstrap | ✅ (glmmTMB + lme4) |
| `engine = "brms"` (`ci_method = "posterior"`), `raters = random` | ✅ balanced + incomplete/ragged (M23/M30). Half-*t*(4,0,1) prior, MAP point + percentile credible interval; ragged threads the M3 `k_eff` divisor per draw (variance-ratio push-forward, no θ² correction). |
| `engine = "brms"`, `raters = fixed` | ✅ balanced + incomplete/ragged (M26/M31). θ²_r per draw, moment-corrected (2b + boundary-aware average-floor); on ragged data the 2b goes live. Balanced `fixed ≡ random` holds only *approximately* for brms (prior on σ_r vs flat rater effects), so the oracle pins containment + coverage, not pointwise equality. |

**Gaps**

| Case | Reason |
|---|---|
| `unit = m` (D-study) with `raters = "fixed"` + `type = "agreement"` | ⚫ **By design, RATER axis only** — θ²_r is the finite-population variance of exactly the observed raters; there is no "average of *m* freshly sampled raters" to project to (`abort_fixed_agr_projection`, M4.5 §4). Use `raters = "random"` or `type = "consistency"`. **The occasion axis (`d_study(n_o = )`) lifts this** (M39): occasions are a random facet however raters are treated. |
| `engine = "lavaan"` + `raters = "fixed"` | ✅ (M21) — SEM fixed-rater agreement is the McGraw & Wong Case-3A bias-corrected θ²_r. |
| `engine = "lavaan"` + incomplete data | ✅ (M21) — FIML (`missing = "fiml"`); consistency ≤8e-3 and agreement ≤1.5e-2 vs glmmTMB. Bootstrap gated on incomplete data (montecarlo only). |
| `engine = "lavaan"` + `ci_method = "bootstrap"` | ✅ (M21) — parametric bootstrap on complete data. |

---

## ② Single-level two-way with within-cell replicates (>1 rating/cell)

Splits σ²_res → σ²_sr + σ²_e; `occasions = "average"` reports the reliability of
the replicate mean.

| Choice | Status |
|---|---|
| `occasions` = single, average | ✅ |
| `engine` = glmmTMB, lme4 | ✅ (two-way random + fixed; multilevel) |
| `engine = "brms"` (`posterior`) | ✅ (M29/M33) — single-level two-way **random** + **fixed** (θ²_r into the rater slot, 2b ≈ 0 balanced), plus **multilevel random** (crossed D1 six-component + nested D2 five-component, subject level). All balanced. |

**Gaps** (M17 Slice 3 deferrals — `M17-within-cell-replicates.md` §7)

| Case | Reason |
|---|---|
| `raters = "fixed"` with replicates | ✅ (M20, balanced) — θ²_r in the rater slot; θ²_r = σ²_r balanced, so fixed reproduces the random coefficients. Ragged×fixed and multilevel×fixed stay deferred. |
| multilevel (`cluster`) with replicates | ✅ (M20 glmmTMB/lme4; **brms M33**) — crossed D1 (six components) and nested D2 (five); residual splits into σ²_{csr} and pure error. Random raters only. Design 3 replicate-split ⚫ by design (no separable interaction); fixed×multilevel, conflated×replicates, ragged×multilevel replicates deferred (all engines). |
| ragged / non-uniform replicates, **single-occasion** | ✅ (M20) — two-way random, the replicate analogue of M3 (harmonic-mean `k_eff` + connectedness gate). Ragged×fixed and ragged×multilevel stay deferred. |
| ragged replicates, **`occasions = "average"`** | 🟣 **Research** — with unequal per-cell counts the reliability of the mean of `n_o` replicates has no single scalar effective-`n_o` divisor and no independent oracle pins one; needs a simulation-oracle study (M20 attempt-then-degrade, ADR-030; M17 §7). |
| `d_study()` **rater-count** projection off a replicate fit | ✅ (M22) — one curve per occasion setting; see the `d_study()` table. |
| `d_study(n_o = )` **occasion-count** projection off a replicate fit | ✅ (M39) — hold raters at `k_eff`, sweep `n_o`; only pure error σ²_e divides by `m·n_o`, so the curve has a **finite ceiling** (<1) and is well-posed for **fixed absolute agreement** (the rater axis's ⚫ abort is axis-specific). Single-level + multilevel. **Ragged**-replicate occasion projection stays 🟣 (the effective-`n_o` divisor above). |
| `engine = "lavaan"` with replicates | 🔵 **Not yet** — SEM ∩ replicates is niche/low-value; a **candidate row** in ROADMAP.md (reclassified from M21, ADR-027). |
| one-way with replicate-split components | ⚫ **By design** — one-way ignores rater identity, so the σ²_sr interaction is undefined. |

---

## ③ One-way (`model = "oneway"`)

Raters are interchangeable — `type` does not apply; coefficients are `ICC(1)` / `ICC(k)`.

| Choice | Status |
|---|---|
| `raters` = random | ✅ |
| `unit` = single, average, numeric `m` | ✅ |
| balance | ✅ balanced, ✅ incomplete |
| `engine` = glmmTMB, lme4 | ✅ |
| `engine = "brms"` | ✅ balanced + incomplete/ragged (M26/M33) — `ICC(1)`/`ICC(1,k)`, MAP + percentile credible interval; ragged threads the M3/M6 `k_eff` divisor per draw (variance-ratio push-forward, no 2b). Numeric-`m` (D-study) brms deferred. |
| `ci_method` = montecarlo, bootstrap | ✅ (glmmTMB + lme4); ✅ **posterior** (brms, balanced **and** ragged) |

**Gaps**

| Case | Reason |
|---|---|
| `raters = "fixed"` | ⚫ **By design** — one-way treats raters as interchangeable; a fixed rater set is not meaningful (one-way guard, M6 §5). |
| `cluster` (multilevel one-way via `model = "oneway"`) | ⚫ **By design** — the multilevel one-way *is* supported, but reached as Design 3 (raters nested in subjects) with `model = "twoway"` + nested data, not via `model = "oneway"` + `cluster`. |
| `engine = "lavaan"` (one-way via SEM) | 🔴 **Blocked** (ADR-014) — the SEM-GT literature covers crossed facet designs only; a wide-column parallel model gives *consistency*, not one-way, and an equal-intercept approximation is unsourced and inexact (0.157 vs 0.166 on SF). Not schedulable until a faithful source appears. |

---

## ④ Multilevel (`cluster` present, `model = "twoway"`)

Design inferred from the crossing pattern (or declared via `design`).

| Sub-design | `level` | `type` | `raters` | balance | `engine` |
|---|---|---|---|---|---|
| **Design 1** crossed (5-component) | subject, cluster, conflated | agreement, consistency | random (both levels); fixed (subject balanced **and** incomplete; **cluster balanced** — M37) | balanced ✅; incomplete ✅ | glmmTMB, lme4, **brms** (random subject+cluster balanced/ragged; fixed subject balanced/ragged; **conflated**; averaged cluster `ICC(c,k)` ragged — M47) |
| **Design 2** nested-in-clusters (4-component) | subject only | agreement, consistency | random (balanced+incomplete); **fixed** (balanced M19, **incomplete/ragged M36**) | balanced ✅; incomplete ✅ | glmmTMB, lme4 (random+fixed, balanced+incomplete), **brms** (random subject; fixed subject balanced M27 + **incomplete/ragged M38**) |
| **Design 3** nested-in-subjects (3-component; multilevel one-way) | subject only | agreement only | random only | balanced ✅; incomplete ✅ (M19) | glmmTMB, lme4, **brms** (balanced random, subject — M25) |

- `unit` in multilevel `icc()`: ✅ single, average. Numeric `m` (rater-count
  projection) goes through **`d_study()`** (both levels, M17), **not**
  `icc(unit = m)` — see the `d_study()` table.
- `ci_method`: ✅ montecarlo, bootstrap (glmmTMB + lme4); ✅ **posterior** (brms — see
  the Cross-cutting brms row for the exact multilevel cells).

**Gaps**

| Case | Reason |
|---|---|
| Design 1 incomplete, averaged cluster-level `ICC(c,k)` | ✅ (M46 glmmTMB/lme4; **brms M47**) — the per-cluster effective-rater divisor is the **inverse-Simpson harmonic `k_c^eff`** (Fable-blessed, ADR-057 Am.1), applied post-fit to the five-component draws; reduces to the rater count on complete data. Both types. Resolves the former 🟣 Wave-3 gap (`M9-incomplete-multilevel.md` §10). |
| Design 1 **balanced**, cluster-level `raters = "fixed"` | ✅ (M37) — signal σ²_c, agreement error {θ²_r, σ²_cr}; a feasibility spike confirmed exact reduction to the M5 random cluster-level ICC (θ²_r = σ²_r AND σ²_cr unbiased under fixing). glmmTMB/lme4. |
| Design 1 **incomplete**, cluster-level `raters = "fixed"` | 🟣 **Research** — double-blocked: ten Hove (2022)'s small-*k* fixed estimator is open, AND the *fixed* averaged `ICC(c,k)` divisor (M9 §9) is a distinct open question from the random `k_c^eff` M46 resolved. Balanced cluster-fixed ships (M37); incomplete deferred (`M37-fixed-cluster-level.md` §7). Refused for **all** engines incl. brms (M47 AC2). |
| Design 1 incomplete, `level = "conflated"` | ✅ (M18) — well-posed on ragged data: Eq. 14 lumps the rater terms into one error, so it is the flat two-way ICC off the multilevel fit with the same flat `k_eff`. Stays visibly biased vs the subject level (`M17-conflated-icc.md` §6a). |
| Design 1 incomplete, `raters = "fixed"` | ✅ (M18) — θ²_r read from the ragged rater-contrast fit; subject level; differs from random under imbalance (as single-level M3). |
| `level = "conflated"` + `type = "consistency"` | ✅ (M45, ADR-056) — the flat two-way *consistency* ICC off the five-component fit (signal σ²_c + σ²_{s:c}; error σ²_cr + σ²_{(s:c)r}, i.e. **drop σ²_r** from the agreement-conflated error). Sourced (McGraw & Wong flat consistency ICC; ten Hove Eq. 14 mirrored), a diagnostic contrast. Random raters, crossed D1, single + average, balanced **and** ragged, glmmTMB/lme4/brms. |
| `level = "conflated"` + `raters = "fixed"` | ⚫ **By design** — Eq. 14 treats the rater effect as a variance component (random raters); a fixed-rater conflated diagnostic is not defined by the source. |
| Design 2 / 3, cluster level | ⚫ **By design** — cluster-level IRR needs raters crossed with clusters; with nested raters only the subject level is defined (ten Hove et al. 2022, p. 6). |
| Design 3, `type = "consistency"` | ⚫ **By design** — with raters nested in subjects the rater main effect is confounded into residual, so only absolute agreement is defined (ten Hove et al. 2022, p. 6). |
| Design 2 / 3, incomplete data | ✅ (M19) — fit formulas are ragged-safe; the averaged divisor is the harmonic-mean `k_eff`, reducing **exactly** to the pinned M3/M6 incomplete divisor. On **ambiguous** ragged data an explicit `design=` is required (never guessed); Design 2 gains a within-cluster connectedness gate. |
| Design 2, `raters = "fixed"` | ✅ (M19 balanced; **M36 incomplete/ragged** glmmTMB/lme4; **M38 brms**) — θ²_{r:c} is the mean over clusters of each cluster's per-cluster Case-3A finite-population rater variance. **Fixed ≢ random even balanced** (per-cluster finite population). Incomplete generalizes to each cluster's own `k_c` + the per-cluster 2b moment correction; single-rater ICC(A,1) has the load-bearing non-circular finite-population recovery oracle; average ICC(A,k_eff) rides the single-cluster reduction to flat M3 (the M19 random-nested `k_eff`, **not** the open per-cluster `ICC(c,k)` divisor). |
| Design 3, `raters = "fixed"` | ⚫ **By design** — raters nested in subjects is the multilevel one-way (rater confounded into residual); no separable rater effect to fix. |
| any multilevel, `engine = "lavaan"` (multilevel SEM) | 🔵 **Not yet** — a research-flavored two-level SEM-GT lift (the paper's multilevel estimator is Bayesian, not a plain lavaan model); a **candidate row** in ROADMAP.md (reclassified from M21, ADR-027). Blocks the lavaan cluster-fixed / incomplete-fixed-nested siblings. |
| any multilevel, `icc(unit = m)` numeric projection | ⚫ **By design (routed elsewhere)** — use `d_study()` for multilevel rater-count projection (M17); `icc()` aborts a numeric multilevel `unit` on purpose. |

---

## `d_study()` — reliability projection across rater / occasion counts

| Case | Status |
|---|---|
| two-way (random) rater-count projection | ✅ |
| multilevel rater-count projection, subject + cluster levels | ✅ (M17) |
| fixed-rater **absolute-agreement** rater-count projection | ⚫ **By design** — refused (same reason as ①: no "average of *m* fresh raters" for a fixed population). The **occasion** axis lifts this (M39). |
| **incomplete-data** multilevel projection | ✅ (M18 subject, crossed; nested D2/3 via M19). Cluster level projects too — the averaged `ICC(c,k)` incomplete divisor is now the M46 `k_c^eff` (formerly dropped-with-note). Projection moves only the divisor `m`, so the ragged fit projects unchanged. |
| **subjects-per-cluster** ("three-facet") projection | ⚫ **By design (not a d_study facet)** — ten Hove Eq. 13's cluster ICC has no subject facet; subjects-per-cluster is an efficiency/sample-size dimension, folded into the parked *design/power helpers* item ([[cluster-icc-no-subject-facet]]). |
| bootstrap-projected `d_study()` bands | ✅ (M18) — the band follows the fit's `ci_method`; a bootstrap fit reprojects its resample components across *m* (at *m* = observed count the band equals the fitted `ICC(*,k)` bootstrap interval exactly). |
| rater-count projection off a **within-cell replicate** fit | ✅ (M22) — per-component `error_divisors` (rater/interaction ÷ `m`, pure error ÷ `m·n_o`); one curve per occasion setting. Single-level (fixed consistency via Spearman–Brown; fixed agreement refused) + multilevel (crossed D1 + nested D2). |
| **occasion** (`n_o`) projection off a **balanced** replicate fit | ✅ (M39) — see the ② table. |
| occasion projection off a **ragged** replicate fit | 🔵/🟣 — bounded by the 🟣 research occasion-averaged ragged divisor (M20/ADR-030); refused loudly. |

---

## Cross-cutting (all designs)

| Case | Reason |
|---|---|
| `engine = "brms"` + `ci_method = "posterior"` (Bayesian credible intervals) | ✅ **The Bayesian engine, broadly shipped.** Half-*t*(4,0,1) prior on every random-effect SD (ten Hove et al. 2020), MAP point + percentile credible interval, `posterior` forced/Bayesian-only, `brm_args` passthrough. **Supported cells:** two-way random (M23) & fixed (M26), one-way (M26), crossed D1 multilevel random subject+cluster (M24) & fixed subject (M27), nested D2/D3 multilevel random subject (M25) & D2 fixed subject balanced (M27), the conflated diagnostic (M29), within-cell replicates (M29/M33), **all balanced**; plus **incomplete/ragged**: two-way random (M30), crossed D1 multilevel random subject+cluster incl. averaged `ICC(c,k)` via M46 `k_c^eff` (M30/M47), nested D2/D3 random subject (M32), one-way (M33), single-level fixed (M31), crossed D1 fixed subject (M31), nested D2 fixed subject (M38). Fixed-rater cells use the moment-corrected (2b + boundary-aware average-floor) push-forward; random-rater cells are variance ratios (no θ² correction). User `prior=` override (M34) and `posterior_summary = "hpdi"` (M34) are reduction-oracle features, not coverage claims — a custom prior VOIDS coverage (loud `intraclass_custom_prior` warning). **Still deferred:** incomplete/unbalanced **fixed cluster-level** (🟣 double-blocked, all engines — §④ gap), fixed/conflated × replicates, Design-3 fixed (⚫), `rstanarm`, selectable `posterior` coupling (MC/bootstrap on a Bayesian fit). |
| categorical / ordinal ratings (GLMM engines) | 🔵 **Not yet** — unscheduled; needs its own estimand pass (link/family choice + oracle registry) before it is schedulable (ROADMAP). |
| non-parametric bootstrap / profile-likelihood CIs | 🔵 **Not yet** — method-comparison nice-to-have; the *parametric* bootstrap shipped in M16, the rest is unscheduled. |
| lme4 boundary-robust interval for singular fits / merDeriv edge cases | 🔵 **Not yet (deprioritized)** — glmmTMB covers the singular-fit case via the degrade-to-glmmTMB handoff; opportunistic parity only (ROADMAP). |
