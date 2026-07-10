# Roadmap

Long-range vision and a parking lot for out-of-scope ideas. Nothing here is
scheduled; scheduling happens by promoting an item into
[`MILESTONES.md`](MILESTONES.md). Keeps PRINCIPLES.md #17 (no scope creep)
honest: new ideas land here, not in the current milestone.

## Vision

A coherent, well-tested R package that (1) fits variance components with modern
engines, (2) computes the *correct* ICC for a stated design with proper interval
estimation, (3) handles imbalanced / incomplete / multilevel designs, and (4)
teaches the user which ICC to choose and why. The package **and its pkgdown site**
are a first-class place to learn ICC best practices — every estimator's docs and
every vignette explains the estimand, assumptions, and tradeoffs behind each knob.

The differentiator vs. prior art: classical tools (`psych`, `irr`, `irrNA`,
`irrICC`, `ICCDesign`) are ANOVA/mean-squares based and mostly assume balanced
data; model-based tools (`performance::icc`, `gtheory`, `misty`) extract a
variance-partition coefficient but not the full interrater-reliability ICC family,
the error-variance framing, or a selection framework. This package fills that gap
with mixed-model estimation and Monte-Carlo CIs (ten Hove, Jorgensen & van der
Ark).

## Parking lot (unscheduled proposals)

Each item now carries a **Status** line — last reviewed 2026-07-09 — so readiness is
visible without re-deriving it. Updated whenever an item's readiness changes;
`STATUS.md`'s Wave 1–3 sequencing is the authoritative near-term order among the
ready ones.

**The M18–M21 arc (ADR-027):** the completeness gaps tagged **🔵 not yet** in
[`COVERAGE.md`](COVERAGE.md) were scheduled as a mixed-model-first arc; each detailed by its
own scoping ADR at its start (ADR-015). **Shipped:** incomplete/fixed **crossed** multilevel
(M18, PR #23), incomplete/fixed **nested** multilevel (M19, PR #24), ragged/fixed/multilevel
**within-cell replicates** (M20, PR #25, ADR-030), and **SEM (lavaan) engine parity** —
bootstrap, fixed-rater (Case-3A θ²_r), and incomplete/FIML (**M21**, ADR-031). **The arc is
complete: every 🔵 not-yet gap in `COVERAGE.md` is closed.** Those items live as *Deferred out of
M<n>* lines in [`MILESTONES.md`](MILESTONES.md), not here. Two items were reclassified **into**
this parking lot instead of milestoned (see below): *multilevel SEM* and *lavaan + within-cell
replicates*. Of two M20 corners sent to the parking lot below, the *occasion-averaged coefficient on ragged
replicates* stays 🟣 research; the *`d_study()` projection off a replicate fit* was then largely
resolved — its rater-count form **shipped as M22 (ADR-032)**, leaving only occasion/ragged projection
parked.

**Shipped as M17 (PR #22, ADR-026):** the *conflated single-level ICC (Eq. 14)*, a
*multilevel `d_study()`*, and *within-cell replicates* shipped as milestone M17 (see
[`MILESTONES.md`](MILESTONES.md)); per ADR-015 they are no longer parked.
**Note:** M17 Slice 2 was originally scoped as a *three-facet / subjects-per-cluster*
`d_study()` but retargeted to **rater-count projection** after the source review
(ten Hove Eq. 13's cluster ICC has no subject facet; Ns is efficiency-only —
[[cluster-icc-no-subject-facet]], ADR-026 amendment). The subjects-per-cluster idea
is **not a reliability-projection facet**; it is folded into the *design/power
helpers* item below (sample-size / CI-width), where it belongs.

- **Consistency-conflated single-level ICC** — M17 Slice 1 ships the *agreement*
  conflated ICC (`level = "conflated"`), sourced to ten Hove et al. (2022) **Eq. 14**;
  the paper publishes only the agreement form. A *consistency*-conflated number
  (drop σ²_r from the error set) is the natural symmetric extension but is **not in
  the paper**. **Status: investigate whether a sourced or faithfully-derivable
  consistency form exists** (an oracle strong enough for #1/#4 — closed form, or a
  reduction that pins it) before exposing `type = "consistency"` + `level =
  "conflated"`; today that combination aborts (ADR-026). Do **not** ship a guessed
  formula (#4).
- Design/power helpers (how many raters/subjects for a target CI width).
  **Status: not ready — needs a scope decision first.** The CI-width-target
  flavor has no independent oracle (correctness would rest on simulation
  calibration alone, in tension with #1); `M4.5-d-study.md` §6 already scoped
  cost/optimal-design helpers and subject-count projection **out** of
  `d_study()`. **This item now also absorbs the multilevel *subjects-per-cluster*
  question** (formerly miscast as a "three-facet d_study"): per ten Hove Eq. 13 the
  number of subjects per cluster is a **sample-size / efficiency** dimension, not a
  reliability facet ([[cluster-icc-no-subject-facet]]), so it lives here (with the
  power/CI-width helpers), never as a `d_study()` projection. Belongs in "Proposals
  under discussion" for a scope ruling before it can be promoted.
- Categorical/ordinal ratings (GLMM engines) beyond the Gaussian LMM.
  **Status: unscheduled, no spec drafted.** No milestone slice, ADR, or oracle
  route exists yet; needs its own estimand pass (link/family choice, oracle
  registry) before it's schedulable.
- Non-parametric bootstrap and profile-likelihood CIs as further alternatives to
  Monte-Carlo, for method comparison (the parametric-bootstrap `ci_method` shipped
  in M16, ADR-025). **Status: partially superseded; remainder unscheduled.** The
  parametric-bootstrap half of this idea is done (M16). Non-parametric bootstrap
  and profile-likelihood remain a method-comparison nice-to-have, not sequenced
  into Waves 1–3.
- Benchmark suite vs. `psych`/`gtheory`/`irrICC` across designs. **Status: ready
  anytime, low priority.** Pure engineering — no new estimand or oracle risk,
  since the comparisons already exist piecemeal in the oracle registry
  (`REFERENCES.md`) — but not yet sequenced into a wave.
- **Reassess the vignettes** (`getting-started`, `choosing-an-icc`, `advanced`). The
  three articles were written/last-shaped around **M4** (the flagship *Choosing an ICC*
  guide) and **M13** (the *Advanced: imbalanced & multilevel designs* showcase), before
  roughly fifteen feature milestones landed: the **lme4** parity (M14/M15), the
  **parametric-bootstrap** `ci_method` (M16), the variance-decomposition trio —
  conflated ICC, multilevel `d_study()`, within-cell replicates (M17), the **M18–M21
  multilevel/SEM completeness arc**, `d_study()` off a replicate fit (M22), and the
  entire **Bayesian (brms) engine arc** (M23–M28). So `advanced.Rmd` (~500 lines) is
  probably both **stale** (missing engines/methods shipped since) and **overloaded**
  (one article now straddles imbalance, multilevel, three alternate engines, two
  interval methods, replicates, and projection). **Open questions (a triage pass, not a
  decided direction):** (1) *Update* — which shipped features are undocumented or
  wrongly described? (2) *Split* — should `advanced.Rmd` break into focused articles
  (e.g. *Engines* [lme4/lavaan/brms], *Interval methods* [MC/bootstrap/posterior],
  *Multilevel designs*, *Replicates & D-studies*) so each is navigable? (3) *Rewrite for
  clarity/accessibility* — reduce jargon, add a from-scratch worked path, make the
  *Choosing an ICC* tree and the estimand vocabulary approachable to applied users, not
  just methodologists. **Status: not scheduled — needs a triage pass first.** No new
  estimand or oracle risk (docs only, cf. M4/M13); the work is a content audit +
  restructure decision. Every displayed number must stay computed live + claim-tested
  (#1/#4/#12), and any new article joins the `_pkgdown.yml` articles index
  ([[pkgdown-reference-index-new-exports]] applies to articles too). Promote to a
  docs milestone once the split/scope is decided.
- **lme4 engine edge cases** beyond the shipped M14/M15 parity: a boundary-robust
  lme4 interval for singular fits (glmmTMB covers this today via the
  degrade-to-glmmTMB handoff), and merDeriv edge cases beyond the currently fitted
  models. Includes **lme4 bootstrap on singular fits** — `lme4::bootMer` does not need
  merDeriv, so it *could* bootstrap a boundary fit, but M16 keeps the existing
  lme4→glmmTMB singular handoff for both `ci_method`s (ADR-025); lifting it for
  bootstrap needs `ci_method` threaded into the lme4 fit path and a `d_study`
  interaction (the MC machinery a bootstrap-skip fit would not build). **Status:
  deprioritized (opportunistic parity only).** glmmTMB already covers the
  singular-fit case via the degrade handoff; well-scoped if picked up, just not
  prioritized.
- One-way random ICC(1)/ICC(1,k) via the **SEM (lavaan) engine** — deferred out of
  M7 (ADR-014). The SEM-GT literature (Jorgensen 2021; Vispoel et al. 2022; Lee &
  Vispoel 2024) covers crossed facet designs only; a wide-column parallel model
  gives consistency (not one-way), and an equal-intercept approximation is unsourced
  and inexact (0.157 vs 0.166 on SF). Needs a sourced method (or a multilevel/
  random-intercept SEM, which would just re-implement the mixed-model engines)
  before it ships. **Status: blocked (ADR-014).** No faithful sourced method
  exists yet; not schedulable until a source appears (`ask-for-inaccessible-
  sources` policy — don't guess a method to unblock it).
- **Multilevel SEM (lavaan)** — two-level SEM-GT for the multilevel designs. **Status:
  reclassified here from the M21 SEM-parity plan (ADR-027); heavy, not scheduled.** A genuine
  research-flavored lift: ten Hove et al. (2022)'s own multilevel estimator is Bayesian, not a
  plain lavaan common-factor model, so a faithful two-level SEM formulation is not a
  mechanical extension of the M7 two-way SEM engine. Sits in the cross-cutting "later" bucket
  beside the Bayesian engine rather than in the M18–M21 completeness arc; needs its own
  estimand/oracle pass before it is schedulable.
- **lavaan + within-cell replicates** — the SEM engine on replicated (σ²_sr/σ²_e-split) data.
  **Status: reclassified here from M21 (ADR-027); unscheduled, low value.** SEM ∩ replicates is
  niche; would need both a lavaan replicate parameterization and the M20 replicate machinery to
  intersect. Parked rather than milestoned; promote only if a concrete need appears.
- **Occasion-averaged coefficient on ragged replicates** — `occasions = "average"` when per-cell
  rating counts are unequal (or cells are missing). **Status: 🟣 research (degraded out of M20
  Slice 3, ADR-030).** No single scalar effective-`n_o` divisor exists (the GT averaging weights
  are per-cell) and no textbook/independent oracle pins one, so it aborts loudly rather than ship a
  guessed divisor (#1/#4). Needs a simulation-oracle study (likely a Fable review, #19) — the
  replicate sibling of the M9 ragged `ICC(c,k)` divisor question. The single-occasion ragged family
  ships (M20 Slice 3).
- **`d_study()` occasion-count and ragged-replicate projection** — the **rater-count** projection off
  a within-cell replicate fit **shipped as M22** (PR #27, ADR-032; the per-component `error_divisors`
  thread the interaction ÷ `m` and pure error ÷ `m·n_o`, one curve per occasion setting). What **remains
  parked** are the two corners M22 deferred: projecting the **occasion** count `n_o` itself, and
  projecting off a **ragged** replicate fit. **Status: 🔵 not yet.** Occasion projection needs an
  occasion axis added to the projection estimand; ragged-replicate projection is additionally bounded by
  the unresolved effective-`n_o` divisor (the *occasion-averaged coefficient on ragged replicates* 🟣
  item above).
- **Bayesian engine** (`brms`) behind `Suggests`, with a new `ci_method = "posterior"`
  (credible intervals from native posterior draws) and half-*t* hyperpriors (ten Hove,
  Jorgensen & van der Ark 2020). Deferred out of M7 (ADR-014). **Status: the two-way random
  path SHIPPED as M23 (ADR-033, PR #28) — `engine = "brms"` + `ci_method = "posterior"` (half-*t*
  MAP + percentile credible interval), oracle O-Bayes.** Backend resolved to **`brms`** (not rstanarm:
  rstanarm's `decov` prior cannot express ten Hove's per-SD half-*t*, forfeiting the
  source-faithful prior the oracle depends on; rstanarm parked as a future alternate). The
  highest-value follow-on — **Bayesian multilevel Design 1 (crossed)** — **shipped as M24 (ADR-034,
  PR #29)**, the **nested Designs 2/3** follow-on **shipped as M25 (ADR-035, PR #30)**, and the
  **single-level one-way + fixed-rater** follow-ons **shipped as M26 (ADR-036)** — the Bayesian engine
  now covers every multilevel design at the subject level plus the single-level one-way and fixed-rater
  designs; and the **fixed-rater multilevel** follow-on (crossed Design 1 + nested Design 2, subject
  level) **shipped as M27 (ADR-037, PR #32)** — completing the brms multilevel story (random ✓ M24/M25,
  fixed ✓ M27; multilevel one-way = Design 3, already M25). See [`MILESTONES.md`](MILESTONES.md).
  Oracle-first findings, **scoped by the ADR-037 gated Fable review (#19):** M26's "brms reads the
  **raw** Case-3A θ²_r, the posterior integrates the bias" is correct only for functionals **linear** in
  β / when `tr(C·Σ_post) ≈ 0` (single-level, crossed); for the **nested** finite-population variance
  (a convex quadratic functional estimated per cluster from little data) the raw push-forward undercovers,
  and the shipped estimator subtracts the **2b** moment correction with a boundary-aware per-draw-average
  floor. What **remains parked here** are the *other* parity follow-ons: Bayesian **incomplete/ragged**,
  **within-cell replicates**, **conflated**, and **cluster-level fixed** — for the incomplete/small-k
  corners ten Hove et al. (2022) flag the best estimator as an open research question, so schedule them
  leaning on coverage calibration. Plus **selectable** `posterior` coupling (MC/bootstrap on a Bayesian
  fit), **HPDI** intervals, and a **user-exposed `prior=`** API.
- **Frequentist nested-fixed MC-interval coverage** — the ADR-037 Fable-review **corollary** (§6): the
  shipped `theta2r_nested_draws()` (the M19 nested-fixed θ²_{r:c} Monte-Carlo interval) subtracts only
  **1b** from its draws and floors **per cluster**, so it likely shares an attenuated version of the
  displacement the Bayesian path fixed (and cannot reach θ²=0). The frequentist **point** estimator is
  unaffected (unbiased). **Status: ready, spun off as a background task (2026-07-09).** Needs a seeded
  coverage sim across the Fable Q6 grid (k ∈ {2,4}, n_s ∈ {3,5,20}, C_n ∈ {5,20,80}, θ²_{r:c} ∈ {0,
  σ²_res/n_s, .66}); if it undercovers, recenter + average-floor the MC draws (mirroring
  `brms_theta2r_moment_draws()`), its own ADR — likely a Fable review (#19) since it changes a shipped
  interval. The crossed fixed MC interval (`theta2r_fixed`) may share it too, negligibly (v → 0 there).
- **M9 averaged cluster-level `ICC(c,k)` on incomplete data** — the per-cluster
  effective-rater divisor is an open modeling question with no textbook oracle
  (`M9-incomplete-multilevel.md` §9); single-rater `ICC(c,1)` ships in M9 Slice 2,
  complete-data `ICC(c,k)` is unaffected (M5). *(Added here 2026-07-08: tracked
  as a carryover since M9 and referenced as living in this file by
  `MILESTONES.md`, but missing from this list until now.)* **Status: open
  research question (Wave 3).** Needs a simulation-oracle study — likely with a
  Fable review (PRINCIPLES.md #19) — before it's schedulable; the open question
  itself has no sourced route to resolve by reading alone.

## Proposals under discussion (open design questions)

These are **decision points, not decided directions** — recorded so the design
is deliberate when scheduled. Resolve the chosen shape at the milestone's start.

- **Do design/power helpers belong in this package's estimand at all?** The
  parking-lot item above ("how many raters/subjects for a target CI width") is
  **not schedulable until this is answered**: `M4.5-d-study.md` §6 currently
  declares subject-count projection and cost/optimal-design helpers **out of
  scope** ("the package's estimand is rater reliability"), and the CI-width-target
  flavor has no independent oracle (#1). Resolve the scope boundary — and an
  oracle strategy if it's taken in — before promoting it. *(Note: M17's Slice 2
  adds subjects-per-cluster projection at the **cluster** level for multilevel
  designs, which is a genuine GT facet; that does not settle the **single-level**
  subject-count / power question raised here.)*

(This file is **future-only**, ADR-015: once a proposal is scheduled it moves to
[`MILESTONES.md`](MILESTONES.md); once shipped its entry here is removed — shipped
work lives in `MILESTONES.md`, not re-narrated here.)
