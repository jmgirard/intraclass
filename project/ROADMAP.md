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

Each item now carries a **Status** line — reviewed 2026-07-08 — so readiness is
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
replicates*. Two M20 corners degraded/deferred to the parking lot below: the *occasion-averaged
coefficient on ragged replicates* (🟣 research) and *`d_study()` projection off a replicate fit*.

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
- **`d_study()` projection off a within-cell replicate fit** — a rater- (or occasion-) count
  projection off a replicate fit. **Status: 🔵 not yet (M20).** Needs the per-component error
  divisors threaded into the projection estimand (the interaction divides by raters, pure error by
  raters × occasions); `d_study()` currently refuses loudly on replicate fits rather than silently
  drop the interaction. Schedulable once the projection estimand carries `error_divisors`.
- **Bayesian engine** (`brms`) behind `Suggests`, with a new `ci_method = "posterior"`
  (credible intervals from native posterior draws) and half-*t* hyperpriors (ten Hove,
  Jorgensen & van der Ark 2020). Deferred out of M7 (ADR-014). **Status: the two-way random
  path is now SCHEDULED as M23 (ADR-033) — in flight; per ADR-015 it lives in
  [`MILESTONES.md`](MILESTONES.md), not here.** Backend resolved to **`brms`** (not rstanarm:
  rstanarm's `decov` prior cannot express ten Hove's per-SD half-*t*, forfeiting the
  source-faithful prior the oracle depends on; rstanarm parked as a future alternate). What
  **remains parked here** are the parity follow-ons M23 defers: Bayesian **fixed-rater**,
  **one-way**, **multilevel** (Designs 1–3 — ten Hove's native turf, the highest-value
  follow-on), **incomplete/ragged**, and **within-cell replicates** — for the incomplete/small-k
  corners ten Hove et al. (2022) flag the best estimator as an open research question, so schedule
  them leaning on coverage calibration. Plus **selectable** `posterior` coupling (MC/bootstrap on a
  Bayesian fit), **HPDI** intervals, and a **user-exposed `prior=`** API.
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
