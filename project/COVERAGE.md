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
**2026-07-08**, after M17 (PR #22, ADR-026).

**Scheduling:** the 🔵 *not yet* gaps below (excluding the cross-cutting section) are
planned as the **M18–M21 arc** (ADR-027) — each gap's target slice is noted in its reason
cell. Order: M18 crossed-incomplete → M19 nested → M20 replicates → M21 SEM parity. Two
former 🔵 items were reclassified (multilevel SEM and lavaan+replicates → ROADMAP); see below.

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
| `engine` | `glmmTMB`, `lme4`, `lavaan` | |
| `ci_method` | `montecarlo`, `bootstrap` | |
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

**Gaps**

| Case | Reason |
|---|---|
| `unit = m` (D-study) with `raters = "fixed"` + `type = "agreement"` | ⚫ **By design** — θ²_r is the finite-population variance of exactly the observed raters; there is no "average of *m* freshly sampled raters" to project to (`icc.R` `abort_fixed_agr_projection`, M4.5 spec). Use `raters = "random"` or `type = "consistency"`. |
| `engine = "lavaan"` + `raters = "fixed"` | 🔵 **Not yet → M21 Slice 2** — SEM fixed-rater estimator deferred out of M7 (ADR-014). |
| `engine = "lavaan"` + incomplete data | 🔵 **Not yet → M21 Slice 3** — incomplete-design SEM (FIML) deferred out of M7 (ADR-014). |
| `engine = "lavaan"` + `ci_method = "bootstrap"` | 🔵 **Not yet → M21 Slice 1** — lavaan supports `montecarlo` only (M16, ADR-025). |

---

## ② Single-level two-way with within-cell replicates (>1 rating/cell)

Supported **only** for two-way **random**, single-level, **balanced/complete**
replicated data (every cell present, equal replicate count). Splits σ²_res →
σ²_sr + σ²_e; `occasions = "average"` reports the reliability of the replicate mean.

| Choice | Status |
|---|---|
| `occasions` = single, average | ✅ |
| `engine` = glmmTMB, lme4 | ✅ |

**Gaps** (all M17 Slice 3 deferrals — `M17-within-cell-replicates.md` §7)

| Case | Reason |
|---|---|
| ragged / non-uniform replicates | 🔵 **Not yet → M20 Slice 1** |
| `raters = "fixed"` with replicates | 🔵 **Not yet → M20 Slice 2** |
| multilevel (`cluster`) with replicates | 🔵 **Not yet → M20 Slice 3** |
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
| `ci_method` = montecarlo, bootstrap | ✅ |

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
| **Design 1** crossed (5-component) | subject, cluster, conflated | agreement, consistency | random (both levels); fixed (subject only, balanced only) | balanced ✅; incomplete ✅\* | glmmTMB, lme4 |
| **Design 2** nested-in-clusters (4-component) | subject only | agreement, consistency | random only | balanced/complete only | glmmTMB, lme4 |
| **Design 3** nested-in-subjects (3-component; multilevel one-way) | subject only | agreement only | random only | balanced/complete only | glmmTMB, lme4 |

\* On **incomplete** Design 1: subject level is fully supported; cluster level is
`ICC(c,1)` only (averaged `ICC(c,k)` rows are dropped — see gaps); conflated and
fixed-rater are not available on ragged data.

- `unit` in multilevel `icc()`: ✅ single, average. Numeric `m` (rater-count
  projection) is done through **`d_study()`** (both levels, M17 Slice 2), **not**
  through `icc(unit = m)` — see the `d_study()` note below.
- `ci_method`: ✅ montecarlo, bootstrap (glmmTMB + lme4).

**Gaps**

| Case | Reason |
|---|---|
| Design 1 incomplete, averaged cluster-level `ICC(c,k)` | 🟣 **Research (Wave 3)** — the per-cluster effective-rater divisor behind a ragged cluster mean is an open modeling question with no textbook oracle; needs a simulation-oracle study, likely a Fable review (#19). `ICC(c,1)` ships; complete-data `ICC(c,k)` is unaffected (`M9-incomplete-multilevel.md` §9). |
| Design 1 incomplete, `level = "conflated"` | 🔵 **Not yet → M18 Slice 2** — the conflated ICC targets the complete five-component fit; its behaviour on ragged data is not yet established (`M17-conflated-icc.md` §6). |
| Design 1 incomplete, `raters = "fixed"` | 🔵 **Not yet → M18 Slice 1** — θ²_r under imbalance is deferred (M10 spec §3/§7). |
| `level = "conflated"` + `type = "consistency"` | 🟣 **Research** — ten Hove Eq. 14 publishes only the *agreement* conflated ICC; a consistency form (drop σ²_r from the error set) is the natural symmetric extension but is **not in the paper**. Investigate whether a sourced/faithfully-derivable form with a #1/#4-strong oracle exists before exposing it; do not ship a guessed formula (ROADMAP, ADR-026). |
| `level = "conflated"` + `raters = "fixed"` | ⚫ **By design** — Eq. 14 treats the rater effect as a variance component (random raters); a fixed-rater conflated diagnostic is not defined by the source. |
| Design 2 / 3, cluster level | ⚫ **By design** — cluster-level IRR needs raters crossed with clusters; with nested raters only the subject level is defined (ten Hove et al. 2022, p. 6). |
| Design 3, `type = "consistency"` | ⚫ **By design** — with raters nested in subjects the rater main effect is confounded into residual, so only absolute agreement is defined (ten Hove et al. 2022, p. 6). |
| Design 2 / 3, incomplete data | 🔵 **Not yet → M19 Slice 1** — incomplete nested multilevel deferred (M8 spec §8; ragged nested-vs-crossed inference). |
| Design 2 / 3, `raters = "fixed"` | 🔵 **Not yet → M19 Slice 2** — fixed-rater nested multilevel deferred (M10). |
| any multilevel, `engine = "lavaan"` (multilevel SEM) | 🔵 **Not yet (reclassified → ROADMAP "later", ADR-027)** — a research-flavored two-level SEM-GT lift (the paper's multilevel estimator is Bayesian, not a plain lavaan model); sits beside the Bayesian engine, not in the M18–M21 arc. |
| any multilevel, `icc(unit = m)` numeric projection | ⚫ **By design (routed elsewhere)** — use `d_study()` for multilevel rater-count projection (M17 Slice 2); `icc()` aborts a numeric multilevel `unit` on purpose. |

---

## `d_study()` — reliability projection across rater counts

| Case | Status |
|---|---|
| two-way (random) rater-count projection | ✅ |
| multilevel rater-count projection, subject + cluster levels | ✅ (M17 Slice 2) |
| fixed-rater **absolute-agreement** projection | ⚫ **By design** — refused (same reason as ①: no "average of *m* fresh raters" for a fixed population). |
| **incomplete-data** multilevel projection | 🔵 **Not yet → M18 Slice 3 (subject level only)** — the subject level is definable on ragged data; the cluster level stays bounded by the 🟣 Wave-3 `ICC(c,k)` incomplete divisor, so M18 does subject-level only (ADR-026 / M17 deferral, ADR-027). |
| **subjects-per-cluster** ("three-facet") projection | ⚫ **By design (not a d_study facet)** — ten Hove Eq. 13's cluster ICC has no subject facet; the subjects-per-cluster count is an efficiency/sample-size dimension, folded into the parked *design/power helpers* item, not a reliability projection ([[cluster-icc-no-subject-facet]], ADR-026 amendment). |
| bootstrap-projected `d_study()` bands | 🔵 **Not yet → M18 Slice 3** — the reliability band reuses shared MC draws across *k*; a bootstrap version reprojects each refit (M16 deferral, ADR-025). |

---

## Cross-cutting (all designs)

| Case | Reason |
|---|---|
| `ci_method = "posterior"` (Bayesian credible intervals) | 🔵 **Not yet** — the Bayesian engine (`rstanarm`/`brms`) + `ci_method = "posterior"` is the remaining arc carry-over; the engine × design dispatch seam is already built for it, so it is *ready to schedule*, just sequenced after the non-Bayesian carryover (ROADMAP; deferred out of M7, ADR-014). |
| categorical / ordinal ratings (GLMM engines) | 🔵 **Not yet** — unscheduled; needs its own estimand pass (link/family choice + oracle registry) before it is schedulable (ROADMAP). |
| non-parametric bootstrap / profile-likelihood CIs | 🔵 **Not yet** — method-comparison nice-to-have; the *parametric* bootstrap shipped in M16 (ADR-025), the rest is unscheduled. |
| lme4 boundary-robust interval for singular fits / merDeriv edge cases | 🔵 **Not yet (deprioritized)** — glmmTMB covers the singular-fit case today via the degrade-to-glmmTMB handoff; opportunistic parity only (ROADMAP). |
