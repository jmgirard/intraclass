# Estimand specification — M37: fixed-rater **cluster-level** multilevel ICC (Design 1, balanced)

**Scope of this document.** The precise population quantity the multilevel
**cluster-level** (between-cluster) interrater ICC targets when the raters are
treated as **fixed** (the observed raters are the entire population of interest —
McGraw & Wong 1996, Case 3 / 3A) rather than a random sample, in the **crossed**
multilevel design (ten Hove et al. 2022, Design 1 — raters crossed with clusters),
**balanced / complete**. This is the **cluster-level sibling of M10** (which shipped
the fixed-rater *subject* level) and the last unshipped frequentist cell of the
crossed Design-1 fixed family. Read `M5-multilevel.md §3b` (the random cluster-level
estimand this specializes), `M10-fixed-multilevel.md` (the fixed-rater θ²_r machinery
and its §7 forward note naming this corner), and `M3-incomplete-designs.md §6` (the
Case-3A θ²_r bias correction) first.

**Why this cell was parked as (C) research/blocked, and what actually gates it.**
The ROADMAP classed "cluster-level fixed" as blocked ("no scaffolding; ten Hove flag
the estimator itself as open"). Investigation (2026-07-11) splits that into two
distinct claims:
- **The *balanced/complete crossed* cell is structurally well-defined** and its fit is
  already shipped — the M10 fixed multilevel fit
  (`score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)`)
  produces every component this coefficient needs (σ²_c, σ²_cr, θ²_r). M37 reads a
  **different coefficient off the same validated fit** — no new fit function.
- **The genuinely open part is *incomplete/small-k*** (ten Hove's flagged estimator
  question), which is **double-blocked** here (it also hits the M9 §9 open cluster-level
  `ICC(c,k)` effective-rater divisor). Incomplete cluster-level fixed is **out of scope**
  for M37 (deferred, §7).

**The one genuinely new derivation M37 must validate (§4).** At the *subject* level
(M10) the cluster×rater term σ²_cr is **not** in the error set, so treating raters as
fixed was clean — only the rater main effect changed (σ²_r → θ²_r), which on balanced
data are **equal** (M3 §6), giving M10 its exact "balanced fixed ≡ random" reduction
oracle. At the *cluster* level σ²_cr **is** the error term (§2). So the open question
is precisely: **when raters are fixed, is the standard random `(1|cluster:rater)`
variance σ²_cr still the correct cluster-level rater-disagreement error, or does the
interaction also need a finite-population treatment (as the main effect does)?** This
is what M10 §7 meant by "needs the fixed-rater treatment of the cluster×rater term
validated." M37 **does not assume** the clean reduction holds — a **feasibility spike
settles it before any shipping code** (§4a), and the maintainer has **pre-authorized a
gated Fable review (#19)** to confirm the corrected error term **only if** the spike
shows the reduction fails.

M37 ships on branch `m37-fixed-cluster-level`, in CI-green slices (§5).

---

## 1. What M37 adds to the abstraction

M5 fixed the multilevel estimand as `(signal, {error set}, scalar divisor)` keyed on
`level` and `type`. M10 showed the **rater slot carries θ²_r** (not random σ²_r) when
raters are fixed, leaving `icc_estimand()` / `icc_point()` / `mc_ci()` untouched. M37
combines the two at the **cluster** level: signal σ²_c, and the error set that at the
cluster level includes the cluster×rater term.

| Slot | M5 cluster (random) | M10 subject (fixed) | **M37 cluster (fixed)** |
|---|---|---|---|
| fit | 5-component random | `1 + rater + (1\|cluster) + (1\|cluster:subject) + (1\|cluster:rater)` | **same M10 fit — unchanged** |
| signal | σ²_c | σ²_{s:c} | σ²_c |
| `rater` slot | random σ²_r | **θ²_r** (Case 3A) | **θ²_r** (Case 3A) |
| interaction in error | σ²_cr | *(absent at subject level)* | **σ²_cr** — the term to validate (§4) |
| divisor | scalar `k` | scalar `k` | scalar `k` (raters-per-cluster) — **unchanged** |

---

## 2. The fit and the estimand

### 2a. Fit — the shipped M10 fit, no new function

The fit is **M10's, verbatim** (raters fixed; cluster, subject-in-cluster, and the
random cluster×rater interaction retained):

```r
score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)
```

θ²_r (Case-3A finite-population variance of the k fitted rater level means) is computed
exactly as in M3/M10 and placed in the **`rater` component slot**; σ²_c, σ²_cr, σ²_res
are the random components as in M5. M37's engineering is **reading the cluster-level
`(signal, {error set}, divisor)` off this fit**, not fitting anything new.

### 2b. Cluster-level estimand (M5 §3b map, with θ²_r in the rater slot)

The **provisional** map (validated / possibly corrected by §4 — the σ²_cr treatment):

| | agreement | consistency |
|---|---|---|
| single `ICC_c(·,1)` | σ²_c / (σ²_c + θ²_r + σ²_cr) | σ²_c / (σ²_c + σ²_cr) |
| average `ICC_c(·,k)` | σ²_c / (σ²_c + (θ²_r + σ²_cr)/k) | σ²_c / (σ²_c + σ²_cr/k) |

σ²_{s:c} and σ²_{(s:c)r} are **not** in the cluster-level error (M5 §3b — cluster
ordering is independent of subject effects). **Consistency is identical to the
random-rater M5 cluster-level case** (it never uses the rater main effect); only
**absolute agreement** differs, by θ²_r vs σ²_r — equal on balanced data (§4) — **and
by whatever §4 concludes about σ²_cr**. `k` is raters-per-cluster (ten Hove 2022 p. 6).
The cluster-level coefficient **does not average over subjects** (M5 §3b).

Fixed raters emit the existing classed `intraclass_fixed_raters` warning, as M2/M3/M10.

---

## 3. Guardrails (PRINCIPLES.md #5)

- **≥ 2 raters** to form θ²_r; **≥ 2 clusters** and **≥ 2 subjects in some cluster**
  for the multilevel fit (as M5/M10).
- **Balanced / complete only.** Incomplete/unbalanced fixed-rater cluster-level aborts
  (deferred, §7): it is double-blocked — ten Hove's open small-k estimator **and** the
  M9 §9 open cluster-level `ICC(c,k)` divisor.
- **Crossed Design 1 only.** Nested Designs 2/3 have **no cluster-level ICC** (⚫
  by-design, M5/M8 — the cluster-level coefficient is defined only for Design 1); the
  existing structural aborts stay.
- **Absolute-agreement D-study projection** for fixed raters stays refused (M4.5 —
  θ²_r is the finite-population variance of *these* raters, no projection).

---

## 4. Oracles (PRINCIPLES.md #1 — ≥2 independent) and the spike gate

No textbook worked example exists for fixed-rater cluster-level IRR (the paper is a
random-effects framework). Correctness rests on the **established multilevel oracle
pattern** — reduction + cross-engine + committed seeded population recovery — **but
only after a feasibility spike settles whether the reduction is exact.**

### 4a. Feasibility spike (Slice 1, no shipping code) — settles the σ²_cr question

A seeded spike (`data-raw/reviews/m37-feasibility-spike-{point,coverage}.R`,
committed as provenance, the M36 precedent) answers, on **balanced/complete** data:

1. **Does the provisional §2b map reduce to the M5 random cluster-level ICC?** Because
   θ²_r = σ²_r exactly on balanced data (M3 §6), the reduction holds **iff** the random
   σ²_cr is the correct fixed-rater cluster-level interaction error. Compare the §2b
   coefficients to the shipped M5 `level = "cluster"` coefficients on the same data.
2. **Non-circular finite-population recovery.** Against a **known** finite-population
   truth for cluster-mean reliability (the fraction of between-cluster-mean variance
   attributable to σ²_c vs the finite-population rater disagreement in the k realized
   raters — a *deterministic function of the fixed design*, not a sampled parameter, so
   a genuine independent oracle, M36 pattern), does the point recover the truth
   (interior + boundary σ²_c → 0) and does the MC interval cover it (n_rep ≥ 240,
   [[ragged-coverage-nrep-240]])?

**Two outcomes:**
- **Outcome A — reduction exact, recovery nominal.** σ²_cr as-is is correct; ship §2b
  with a **reduction oracle** (balanced fixed ≡ random cluster-level) + lme4 cross-engine
  + seeded recovery. **No Fable review** (the M10 posture lifted to the cluster level).
- **Outcome B — reduction fails.** The interaction needs a finite-population treatment
  (a θ²-style correction on σ²_cr, or a different cluster-level error composition).
  Derive the corrected error term from first principles, pin it with the non-circular
  recovery oracle, **and fire the pre-authorized gated Fable review (#19)** to confirm
  the derivation before shipping. The point estimator is **never tuned to force
  coverage** (#4); if it cannot be pinned it degrades to 🟣 research and M37 ships
  nothing for this cell.

### 4b. Shipping oracles (O-FCL), whichever §4a outcome

- **O-FCL/reduction.** Outcome A: §2b equals M5 random cluster-level (agreement +
  consistency, single + average) to < 1e-4. Outcome B: the derived-and-Fable-confirmed
  relationship, pinned to the recovery truth.
- **O-FCL/lme4.** An independent lme4 fit of the identical M10 model reproduces σ²_c,
  σ²_cr, σ²_res and (same θ²_r) every §2b coefficient to < 1e-4.
- **O-FCL/recovery.** Committed seeded finite-population recovery against the known
  cluster-mean-reliability truth (interior + boundary σ²_c = 0), MC-CI coverage at
  n_rep ≥ 240, regenerated from a committed `data-raw/oracle-fixed-cluster-level.R`
  (the spike scripts are its seed), fixture committed (#4).
- **Regression guard:** the full M1–M36 suite stays green (the M10 subject-level path,
  the M5 random cluster-level path, and the flat fixed path are untouched).

**MC CI** reuses the **M10 fixed-rater sampler branch** (ADR-008/ADR-038): each draw
samples β̂ from `vcov(fit, full = TRUE)` alongside the variance components and recomputes
θ²_r with the multilevel components. Consistency needs only σ²_c and σ²_cr per draw
(θ²_r unused). Whether the interaction needs the 2b moment treatment (M28) is part of
the §4a determination — the crossed θ²_r itself carries b ≈ 0 (M28's crossed-path
unification), but the cluster-level interaction error is new territory the spike probes.

---

## 5. Slices

- **Slice 1 — feasibility spike (no shipping code).** The §4a scripts; decide Outcome
  A vs B; record the σ²_cr verdict. If Outcome B, prepare the Fable brief (#19, the
  pre-authorized review) and pause for the review before Slice 2.
- **Slice 2 — cluster-level fixed estimand + fit path.** Lift the `level = "cluster"` +
  `raters = "fixed"` abort (`R/icc.R`, the M10 subject-only guard) for the
  **balanced/complete crossed Design-1** case only (incomplete stays refused); read the
  cluster-level `(signal, {error set}, divisor)` off the M10 fit with θ²_r (and the
  §4a-settled interaction term) in the rater slot; route in `icc()`; `print`/`glance`
  surface fixed-rater cluster-level. Oracles O-FCL/reduction, O-FCL/lme4, O-FCL/recovery.
- **Slice 3 — docs.** Extend the `multilevel-designs` article + the "which ICC / when"
  note to fixed-rater cluster level on real knit-time code; `test-vignette-claims.R`
  invariants (Outcome A: balanced fixed ≡ random cluster-level; consistency identical,
  agreement differs only by θ²_r — or the §4a-corrected statement).

---

## 6. Acceptance criteria (this estimand → code)

- **Spike:** the §4a scripts commit; Outcome A/B recorded with the σ²_cr verdict; on
  Outcome B the gated Fable review is run and its verdict adopted before shipping code.
- **Fit/route:** `raters = "fixed"` + `level = "cluster"` + balanced crossed Design 1
  reads §2b off the M10 fit (no new fit function); the `intraclass_fixed_raters` warning
  fires.
- **Cluster level:** agreement + consistency, single + average, with boundary-aware MC
  CIs; **equal the random-rater M5 cluster-level ICCs on balanced data** to < 1e-4
  (Outcome A) *or* the Fable-confirmed relationship (Outcome B); match lme4.
- **Consistency ≡ random** exactly (the rater main effect is unused).
- **Guards:** incomplete/unbalanced cluster-level fixed, and nested Designs 2/3
  cluster-level, abort with classed errors (§3, §7); balanced random + M10 subject
  paths untouched.
- **Docs:** the "which ICC / when" note extends to fixed-rater cluster level; the
  estimand is named (#2, #13).

---

## 7. Out of scope for M37 (recorded for forward-compatibility)

- **Incomplete / unbalanced fixed-rater cluster-level** — double-blocked (ten Hove's
  open small-k estimator + the M9 §9 open cluster-level `ICC(c,k)` divisor); its own
  later milestone, likely needing a simulation-oracle study + Fable review.
- **brms and lavaan cluster-level fixed siblings** — engine parity, unblockable once
  M37 ships the frequentist oracle (the M27 brms note left crossed fixed cluster level
  "an unshipped frequentist cell too"); later milestones.
- **Nested Designs 2/3 cluster-level** — ⚫ by-design (no cluster-level ICC for nested
  raters, M5/M8).
- **Design 3 fixed** — ⚫ by-design (multilevel one-way, no separable rater effect).
- **Absolute-agreement `d_study()` for fixed cluster-level raters** — refused (M4.5).

---

## References

- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46. (Case 3 / 3A; the
  fixed-rater θ²_r term — inherited from M3 §6 / M10.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater reliability
  for multilevel data: A generalizability theory approach. *Psychological Methods,
  27*(4), 650–666. (Design 1 cluster-level decomposition, Eq. 13 / Table 3 — inherited
  from M5 §3b; the paper is a random-effects framework and does not define a fixed-rater
  cluster-level coefficient, and flags the incomplete/small-k estimator as open.)
- (Full provenance for any asserted numeric value is registered in `REFERENCES.md` when
  the O-FCL oracle values are committed, Slice 2.)
