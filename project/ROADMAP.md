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

Each item now carries a **Status** line — last reviewed 2026-07-11 — so readiness is
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
  the paper**. **Status: SCHEDULED as M45** (ADR-056, planned 2026-07-12). The plan-gate
  investigation resolved the #1/#4 oracle question: the conflated collapse is definitionally
  "treat the data as flat two-way" (M17 §2; M18 §6a proved agreement-conflated ≡ flat two-way
  *agreement* ICC), so the consistency form is the **flat two-way *consistency* ICC** — the
  sourced McGraw & Wong (1996) ICC(C,1)/ICC(C,k), dropping σ²_r — read off the multilevel fit,
  not a guessed formula (#4). Full scope in [`MILESTONES.md`](MILESTONES.md) M45; ships on an
  attempt-then-degrade posture (ADR-028) with the abort retained if the oracle unexpectedly fails.
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
- **Clarity/accessibility rewrite of the teaching vignettes.** The **vignette *reassessment***
  (Update + Split) **shipped as M35** (ADR-045, PR #40): `advanced.Rmd` was retired into four
  focused articles (`multilevel-designs`, `engines`, `interval-methods`, `d-studies-and-replicates`)
  and the M23–M34 Bayesian engine documented — shipped detail lives in
  [`MILESTONES.md`](MILESTONES.md), not here (ADR-015). **What stays parked** is the third,
  set-aside M35 option: a **clarity/accessibility rewrite** of `getting-started` /
  `choosing-an-icc` — reduce jargon, add a from-scratch worked path, make the *Choosing an ICC*
  tree and the estimand vocabulary approachable to applied users, not just methodologists.
  **Status: SCHEDULED as M40** (ADR-050, planned 2026-07-11) — the rewrite ships **in place** (both
  front-door articles, no split), adds a **sourced, caveated interpretation-band guide** (Koo & Li 2016 /
  Cicchetti 1994 — #4: cited, not invented), and stays a pure docs milestone (cf. M4/M13/M35 — no new
  estimand or oracle risk; every displayed number computed live + claim-tested, #1/#4/#12). Full scope is in
  [`MILESTONES.md`](MILESTONES.md) M40 (ADR-015 — not re-narrated here). The **clarity pass over the other four
  articles** (`engines`, `interval-methods`, `multilevel-designs`, `d-studies-and-replicates`) plus a standalone
  **glossary page** then **shipped as M41** (ADR-051, PR #47, squash-merged at `3e00999`) — same docs-milestone
  posture as M40 (no new estimand/engine/dependency; live-computed + claim-tested numbers; no Fable); shipped
  detail in [`MILESTONES.md`](MILESTONES.md) M41 (ADR-015), not re-narrated here. **What remains parked** after
  M41 is a clarity pass over any *further* material and per-term worked examples beyond first-use glosses — later
  docs passes, not scheduled. (M41 + M42 were the two release-strengthening milestones the 2026-07-11 retro
  sequenced before **0.2.0**; both shipped — M41 clarity/glossary at ADR-051, M42 the benchmark-vs-prior-art
  comparison article at ADR-052 — so the **next step is the v0.2.0 consolidation** (ADR-022), then the release.)
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
  estimand/oracle pass before it is schedulable. **Blocks** the lavaan cluster-level-fixed and
  incomplete-fixed-nested siblings noted in the (C) sequence below — those cannot ship as engine
  parity until this two-level SEM lift lands.
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
- **`d_study()` ragged-replicate occasion projection** — the **rater-count** projection off a within-cell
  replicate fit **shipped as M22** (PR #27, ADR-032), and the **occasion-count** projection off a **balanced**
  replicate fit **shipped as M39** (PR #45, ADR-049; the new `n_o` argument — occasion averaging rescales only
  σ²_e, so a finite ceiling and a fixed-agreement lift; shipped detail in [`MILESTONES.md`](MILESTONES.md), not
  here per ADR-015). What **remains parked** is projecting `n_o` off a **ragged** replicate fit. **Status: 🟣
  blocked.** It needs the effective-`n_o` divisor that is itself open research (the *occasion-averaged
  coefficient on ragged replicates* 🟣 item above, M20/ADR-030) — the single-occasion ragged family ships, but
  averaging unequal per-cell replicate counts across projected occasions has no sourced divisor. Promote only
  once that divisor question resolves.
- **Bayesian engine** (`brms`) + `ci_method = "posterior"` (half-*t* hyperpriors, ten Hove, Jorgensen &
  van der Ark 2020), deferred out of M7 (ADR-014). **Shipped as the M23–M32 arc** (see
  [`MILESTONES.md`](MILESTONES.md)): two-way random (M23), multilevel crossed (M24) + nested Designs 2/3
  (M25), single-level one-way + fixed-rater (M26), fixed-rater multilevel (M27), and the **conflated
  diagnostic + single-level within-cell replicates (M29, ADR-039, PR #34)**; then the incomplete/ragged
  extensions — random (M30), fixed (M31), and nested random (M32). Backend resolved to
  `brms` (rstanarm parked — its `decov` prior can't express the per-SD half-*t*). The M27 gated Fable
  review (#19, ADR-037) established the **2b moment correction** for the finite-population θ² functional
  (the raw posterior push-forward undercovers the nested per-cluster variance; the "posterior integrates
  the bias" rationale holds only when `tr(C·Σ) ≈ 0`, i.e. single-level/crossed); its **frequentist sibling
  shipped as M28** (ADR-038, PR #33), unifying all engines onto one boundary-aware `theta2r_moment_draws()`
  ([[fixed-rater-interval-2b-moment-correction]]). M29's conflated + replicate follow-ons are **variance
  ratios**, so they need none of that correction (a clean push-forward). **Incomplete/ragged random-rater**
  then **shipped as M30** (ADR-040, PR #35): two-way random single-level + crossed (Design 1) multilevel
  random, narrowing the one `!balanced` brms guard so the shipped M3/M9 `k_eff`/connectedness thread per
  posterior draw — a variance-ratio push-forward, so the ragged-data coverage that was flagged as the risk
  came back **nominal** at the subject level (no Fable review; O-Bayes-Incomplete / O-Bayes-IML). Incomplete/ragged
  **fixed-rater** then **shipped as M31** (ADR-041, PR #36): two-way fixed single-level + crossed (Design 1)
  fixed multilevel subject level, narrowing the same `!balanced` brms guard. Here the θ² **2b moment
  correction** (shipped `brms_theta2r_moment_draws()`) went **live at the single level for the first time**
  (`b ≠ 0` once the fixed rater means are estimated from unequal cell counts, invisible on balanced data);
  the flagged `k_eff` × 2b interaction risk resolved **nominal** for both slices (O-Bayes-IFixed .965/.965,
  O-Bayes-IFML-fixed .91/.91 tracking their complete cells → no Fable review). Incomplete/ragged **nested
  random** then **shipped as M32** (ADR-042, PR #37): both nested designs at the subject level — Design 2
  (`fit_brms_nested_clusters`) and Design 3 (`fit_brms_nested_subjects`, the multilevel one-way) — narrowing
  the same `!balanced` brms guard's nested clause; random → variance ratios → no 2b (the M30 regime). Scoped
  **random-only** by an oracle-first catch: incomplete *fixed* nested has **no frequentist oracle** (deferred
  all engines, ADR-029), so a Bayesian fixed-nested slice is research, not parity. Slice 1 (Design 2) was
  nominal; **Slice 2 (Design 3) fired the milestone's one gated Fable review** (#19) when the first n_rep-80
  ragged coverage cell drew .8625 — **verdict (ADR-042 Amendment 2): a Monte-Carlo tail event, no estimator
  shortfall** (same incidence at n=240 → .9458, 2,000-fit frequentist → .9555, uniform PIT), fixture
  regenerated at n_rep 240 with pins unchanged, and **n_rep ≥ 240 adopted as the convention for future ragged
  coverage cells** (the ≥ .88 pin false-alarms ~0.7%/cell at n_rep 80). **Still parked**, now grouped and
  *sequenced* (planning discussion 2026-07-10 — a recorded direction, not yet an ADR). **(A) — the Bayesian
  parity mop-up — SHIPPED as M33** (ADR-043, PR #38): incomplete single-level one-way + fixed-rater &
  multilevel within-cell replicates, every oracle nominal (no Fable); its entry is removed here per ADR-015.
  **(B) — the Bayesian customization milestone — SHIPPED as M34** (ADR-044, PR #39): user `prior=` override
  (classed footgun warning) + HPDI credible intervals (`posterior_summary = c("percentile","hpdi")`); reduction
  oracles, no coverage claim, no Fable review; its detailed scope is removed here per ADR-015.
  The remaining sequence:
    - **(C) research / blocked.** **Incomplete fixed nested Design 2 — SHIPPED as M36** (ADR-046, PR #41): the
      ragged per-cluster Case-3A θ²_{r:c} (generalized to unequal k_c) for glmmTMB/lme4, subject level, **both
      single and average** `ICC_s(·,k)` — pinned by a non-circular finite-population recovery oracle (no
      Fable). The averaged coefficient's divisor turned out to be the well-defined subject-level `k_eff` (the
      M19 random-nested divisor), **not** the open per-cluster `ICC(c,k)` divisor — so it shipped, not
      deferred. Shipped detail in [`MILESTONES.md`](MILESTONES.md), not here (ADR-015). **Cluster-level fixed
      (balanced crossed) — SHIPPED as M37** (ADR-047, PR #43): the **balanced/complete crossed Design-1** cell
      reads `{σ²_c | θ²_r, σ²_cr}` off the *shipped* M10 fit (the cluster-level sibling of M10, **no new fit**;
      the estimand map keys the cluster error set on `level` not `raters`), glmmTMB/lme4. A feasibility spike
      settled the σ²_cr question (fixing raters doesn't bias the interaction) → exact reduction to the M5
      random cluster-level ICC, **Outcome A, no Fable**. Shipped detail in [`MILESTONES.md`](MILESTONES.md)
      (ADR-015). **brms cluster-level-fixed + brms incomplete-fixed-nested siblings — SHIPPED as M38**
      (ADR-048, PR #44): engine parity (each a lift of one shipped brms guard, checked against the glmmTMB
      M37/M36 frequentist oracle), both clean guard-lifts. The ragged-fixed-nested-brms coverage gate
      (O-Bayes-IFNML) came back **nominal** (C_n=80 boundary .970, no decay), so the no-Fable stop-and-replan
      branch did not fire. Shipped detail in [`MILESTONES.md`](MILESTONES.md), not here (ADR-015).
      **Still parked / genuinely open:** **incomplete/unbalanced** cluster-level fixed (🟣 double-blocked —
      ten Hove's open small-*k* estimator *and* the M9 §9 open cluster-level `ICC(c,k)` divisor; its own later
      milestone); the **lavaan** cluster-level-fixed **and** incomplete-fixed-nested siblings (**blocked on the
      multilevel-SEM lift** — lavaan multilevel is unsupported (`R/icc.R` aborts every multilevel/one-way SEM
      path), so these are *not* cheap parity; they become reachable only once two-level SEM-GT ships, the
      "Multilevel SEM (lavaan)" parking-lot item below); **selectable** `posterior` coupling (MC/bootstrap on a
      Bayesian fit), low priority. **Design 3 fixed** is **not future work** — it is already closed in code by
      the ADR-029 by-design abort (fixed raters are undefined when raters nest in subjects; the classed abort
      ships and is tested), so it is no longer listed as parked.
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
