# Estimand specification — M5: Multilevel ICCs (subject- vs. cluster-level)

**Scope of this document.** The precise population quantities the multilevel
estimators target when the objects of measurement are **nested in clusters**
(pupils in classrooms, patients in clinics): a **subject-level (within-cluster)**
interrater ICC and a **cluster-level (between-cluster)** interrater ICC. It builds
on [`M1-twoway-random-agreement.md`](M1-twoway-random-agreement.md) and
[`M2-consistency-and-fixed.md`](M2-consistency-and-fixed.md); the Monte-Carlo CI
(ADR-003) and the agreement/consistency and single/average knobs are inherited
unchanged. Read those first.

**Source of the estimand.** ten Hove, D., Jorgensen, T. D., & van der Ark, L. A.
(2022). Interrater reliability for multilevel data: A generalizability theory
approach. *Psychological Methods, 27*(4), 650–666 (advance online publication
2021). The ICC **equations** in §3 are transcribed verbatim from that paper
(Eqs. 6–7, 12–13 and **Table 3**); no term is paraphrased or guessed
(PRINCIPLES.md #1, #2, #4).

**What is transcribed vs. what is our engineering (be explicit, #18).** The paper
estimates the components with **MCMC** (Stan) and never writes an lme4/glmmTMB
formula. Two things below are therefore *our* translation, **to be established by
oracle, not assumed**:
- the random-effects **model formula** (§2) that maps the paper's Eq. 7
  decomposition onto glmmTMB/lme4;
- that **MLE-RE recovers the paper's components** at all. The paper notes MLE (via
  a hierarchical linear model) is *available* to estimate these components (p. 4,
  Marcoulides 1990) but does not demonstrate MLE ≡ MCMC numerically. Establishing
  that our fit reproduces the intended components is exactly the job of the O-ML
  oracles (§5). The oracle is the shared **model/estimand** (lme4 + simulation),
  not the paper's posterior summaries.

M5 ships on branch `m5-multilevel`, two CI-green slices (§6).

---

## 1. Design scope (locked with the maintainer; ADR-011)

The paper defines four multilevel designs (its Table 2). M5 targets **Design 1 —
raters crossed with clusters** (each rater rates each subject in each cluster),
which is the only design for which **both** a subject- and a cluster-level ICC are
defined (the paper: for cluster-level IRR "only Design 1 … is sufficient").

| Dimension | M5 scope | deferred |
|---|---|---|
| Design | **Design 1: raters crossed with clusters** | Designs 2/3 (raters nested in clusters/subjects) → ROADMAP |
| Balance | **balanced / complete** | incomplete multilevel (reuse M3 `k_eff`/connectedness) |
| Raters mode | `raters = "random"` (paper's default; p. 4) | fixed-rater multilevel → ROADMAP |
| Error set | agreement / consistency (`type`, both levels) | — |
| Averaging | single / average (`unit`, both levels) | subject-count projection → ROADMAP |

---

## 2. Measurement model and variance components

Design 1 decomposes a rating `Y_{(s:c)r}` (subject `s` nested in cluster `c`, rated
by rater `r`) into a grand mean plus cluster, subject-in-cluster, rater, and
cluster×rater effects, with the highest-order (subject-in-cluster)×rater
interaction confounded with error (paper Eqs. 6–7):

```
Y_{(s:c)r} = μ + μ_c + μ_{s:c} + μ_r + μ_{cr} + residual

σ²_Y = σ²_c + σ²_{s:c} + σ²_r + σ²_{cr} + σ²_{(s:c)r}
```

The engine (glmmTMB default, lme4 oracle per ADR-005) fits

```
score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)
```

**This formula is our translation of Eq. 7, not stated by the paper (which fits in
Stan).** Slice 1's first task is to confirm it recovers the five components on a
hand-built balanced dataset — matched to a method-of-moments computation and to
lme4 — *before* any ICC is read off it. The `cluster:subject` term assumes subject
labels are unique within cluster (otherwise the nesting must be made explicit).

Giving **five** components (residual variance = the confounded highest-order term):

| Component | Paper symbol | Internal name | Meaning |
|---|---|---|---|
| cluster | σ²_c | `cluster` | between-cluster true-score variance |
| subject-in-cluster | σ²_{s:c} | `subject` | between-subject-within-cluster true-score variance |
| rater | σ²_r | `rater` | rater main-effect variance |
| cluster × rater | σ²_{cr} | `cluster_rater` | cluster-level rater disagreement |
| residual | σ²_{(s:c)r} | `residual` | (subject:cluster)×rater + error (confounded) |

`vcov(fit, full = TRUE)` supplies the joint covariance the Monte-Carlo sampler
already draws from (ADR-003) — **no new CI machinery**. The `cluster:rater` term is
the one new random effect; everything else mirrors M1.

Design constants surfaced: `n_clusters`, subjects-per-cluster, raters (`k`). In a
fully crossed balanced Design 1, raters-per-subject = raters-per-cluster = the
total rater count, so the averaging divisor is a **single scalar `k`** at both
levels (= the existing `k_eff`).

---

## 3. The two estimands (paper Table 3, Design 1 "raters crossed")

Each ICC is `signal / (signal + error / k)` — the **existing scalar-divisor**
`icc_point()` form (M1 §2). Only the signal component and the error set change with
`level` and `type`; the divisor `k` is 1 (single) or the rater count (average).

### 3a. Subject-level (within-cluster) — paper Eq. 12, Table 3 top-left

Signal = σ²_{s:c}. **No cluster-related variance appears** (σ²_c, σ²_{cr}): the
ordering of subjects *within* clusters is independent of cluster effects.

| | agreement | consistency |
|---|---|---|
| single `ICC_s(·,1)` | σ²_{s:c} / (σ²_{s:c} + σ²_r + σ²_{(s:c)r}) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}) |
| average `ICC_s(·,k)` | σ²_{s:c} / (σ²_{s:c} + (σ²_r + σ²_{(s:c)r})/k) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}/k) |

Error set = `{rater, residual}` (agreement) or `{residual}` (consistency) — the
**same structure as the single-level M1/M2 estimand**, now with σ²_{s:c} as the
de-confounded subject signal and σ²_{(s:c)r} as residual.

### 3b. Cluster-level (between-cluster) — paper Eq. 13, Table 3 bottom-left

Signal = σ²_c. **No subject-related variance appears** (σ²_{s:c}, σ²_{(s:c)r}): the
ordering of clusters across raters is independent of subject effects. The rater
disagreement relevant to clusters is the **cluster×rater** term σ²_{cr}.

| | agreement | consistency |
|---|---|---|
| single `ICC_c(·,1)` | σ²_c / (σ²_c + σ²_r + σ²_{cr}) | σ²_c / (σ²_c + σ²_{cr}) |
| average `ICC_c(·,k)` | σ²_c / (σ²_c + (σ²_r + σ²_{cr})/k) | σ²_c / (σ²_c + σ²_{cr}/k) |

Error set = `{rater, cluster_rater}` (agreement) or `{cluster_rater}`
(consistency). `k` is raters-per-cluster (paper's simplification, p. 6). **The
cluster-level coefficient does not average over subjects** — an earlier planning
assumption the paper corrects.

---

## 4. What this adds to the estimand abstraction

M1 fixed the representation as `(signal, {error set}, scalar divisor)`. M5
generalizes **only the two lookups**, keeping the divisor scalar:

| Slot | prior | M5 |
|---|---|---|
| signal | always `subject` (σ²_s) | `subject` (σ²_{s:c}) or `cluster` (σ²_c), by `level` |
| error set | by `type` | by `type` **and** `level` (four rows in §3) |
| divisor | scalar `k` | scalar `k` — **unchanged** |

`icc_point()` and `resolve_divisor()` are untouched (no per-component divisor —
that earlier idea is dropped). The only additions are two components in the fit
(`cluster`, `cluster_rater`) and a `level`-keyed signal/error-set map. Both
estimands are read off **one shared five-component fit**: Slice 1 consumes the
subject-level rows, Slice 2 the cluster-level rows.

**Conflated (single-level) contrast (paper Eq. 14).** Ignoring clusters conflates
σ²_c into σ²_{s:c} and σ²_{cr} into σ²_r, biasing IRR — this is the motivating
error the package now avoids. It is a natural teaching point for the vignette
(Slice 2), computed as `(σ²_c + σ²_{s:c}) / (σ²_c + σ²_{s:c} + (σ²_r + σ²_{cr} +
σ²_{(s:c)r})/k)`. **Promoted to a shipped, selectable coefficient
`level = "conflated"` in M17 Slice 1 (ADR-026)** — agreement-only, labeled a
diagnostic contrast, never a recommended coefficient; see
[`M17-conflated-icc.md`](M17-conflated-icc.md).

---

## 5. Oracles (PRINCIPLES.md #1 — ≥2 independent) and provenance

No Shrout–Fleiss-style textbook worked example exists for the multilevel IRR
estimand (as with O5, M3). Verified in `tests/testthat/test-icc-multilevel.R`,
regenerated by `data-raw/oracle-multilevel.R` (seeded, `stopifnot` tolerances):

- **O-ML/lme4** — `lme4::lmer` fits the identical five-component model on a balanced
  Design-1 dataset and reproduces **both** ICC families' point values (all four
  §3 estimands × single/average) to < 1e-4. Independent implementation of the same
  LMM (ADR-005 role).
- **O-ML/sim** — a seeded simulation with **known** components (the paper's own
  data-generating regime is a ready template: σ²_{s:c} = 1, σ²_{cr} = 0.16,
  σ²_{(s:c)r} = 0.50, σ²_c and σ²_r varied over {0.16, moderate}; N_c ∈ {20, 40},
  N_s/cluster ∈ {10, 30}, k ∈ {2, 5, 10}) recovers both families' points within
  tolerance, and the boundary-aware Monte-Carlo interval covers the population
  values (PRINCIPLES.md #12).
- **O-ML/reduction** — the subject-level estimand (§3a) is *algebraically
  identical* to the single-level M1/M2 estimand once the error set matches, so the
  reduction is asserted two honest ways: **(a) algebraic** — a code-level invariant
  that the subject-level `(signal, error set, divisor)` equals the single-level one
  component-for-component (no fit); **(b) numerical** — on a balanced dataset
  generated with **zero cluster and cluster×rater variance and many clusters**
  (≥ ~20; a *single* cluster is **degenerate** — `(1 | cluster)` / `(1 |
  cluster:rater)` cannot be fit), the fitted subject-level ICCs match a single-level
  `icc()` fit on the same ratings (ignoring cluster) to < 1e-4, also vs. lme4.
  **Dropped:** the earlier claim that this reproduces the exact Shrout & Fleiss
  values 0.290/0.620/0.715/0.909 — that holds only if a dataset actually yielding
  them is built and committed, which is not assumed here.

**Regression guard:** the full existing suite — M1–M3 oracles and the M4.5
`d_study` oracles (O-DS) — must stay green (the scalar-divisor path is untouched,
§4, so this should hold trivially).

`psych`/`gtheory` are **not** multilevel-IRR oracles (they do not target this
estimand). A Bayesian/MCMC cross-check against the paper's own Stan estimator is a
*future* third oracle, deferred with the M6 engine work. If any §3 coefficient
cannot be pinned by both required oracles, it is **not shipped** and a Fable review
is *recommended*, then work pauses (PRINCIPLES.md #1, #19).

---

## 6. Slices

- **Slice 1 — subject-level (within-cluster).** `cluster` (tidy-eval selector,
  default `NULL` → backward-compatible single-level path) + `level` (validated /
  iterated like `unit`) args; glmmTMB engine extended to the five-component Design-1
  fit with component extraction; identifiability guards (§7); the subject-level
  signal/error map (§3a) — reuses the scalar `icc_point()`. `print`/`tidy`/`glance`
  surface `level` + `n_clusters`. Oracles O-ML/lme4, O-ML/sim, O-ML/reduction for
  the subject-level coefficient. End-to-end thin slice.
- **Slice 2 — cluster-level (between-cluster) + docs.** The cluster-level
  signal/error map (§3b) off the **same fit** (σ²_c, σ²_{cr}); MC-CI verified for
  the cluster-level coefficient; O-ML extended to it. Then the conflated-ICC
  teaching contrast (§4): fill `advanced.Rmd`'s multilevel section on real code,
  turn `choosing-an-icc.Rmd`'s "fifth choice" preview into a worked subject-vs-
  cluster example, and add `test-vignette-claims.R` invariants (e.g. average ≥
  single at each level; subject-level reduces to single-level when σ²_c → 0).

---

## 7. Identifiability and boundaries (PRINCIPLES.md #5)

- **≥ 2 raters** are required — this one **is** from the paper (minimum k = 2;
  multiple raters per subject are needed to identify rater-related variance).
- The remaining guards are **derived from standard variance-component
  identifiability, not cited to the paper**, and their exact thresholds are an
  **open design question for the maintainer** (flagged, not settled): cluster level
  plausibly needs ≥ 2 clusters (and enough for a stable σ²_c — the paper's own
  simulations used N_c ∈ {20, 40}); σ²_{s:c} needs ≥ 2 subjects in some clusters; a
  `cluster` that is 1:1 with `subject` leaves σ²_c and σ²_{s:c} unidentified →
  classed abort (`abort_unidentified`, new guard). Confirm the thresholds (hard
  error vs. warning; minimum viable N_c) before coding the guards.
- **Few clusters** ⇒ σ²_c (and σ²_{cr}) are poorly estimated and their Monte-Carlo
  intervals are wide — the paper found small numbers of raters/clusters the main
  source of bias and inefficiency. This is honest boundary-aware behavior (ADR-003):
  documented, guarded by a minimum-cluster check, not suppressed.
- Requesting `level = "cluster"` with no `cluster` column is a classed usage error
  (`abort_intraclass`).

---

## 8. Out of scope (recorded for forward-compatibility)

Designs 2/3 (raters nested within clusters and/or subjects — the paper's Eqs. 8–11,
Table 3 middle/right columns); incomplete multilevel (reuse M3
`k_eff`/connectedness); fixed-rater multilevel; a Bayesian/MCMC cross-engine (M6,
the paper's own estimator); a three-facet `d_study()` projecting subject-per-cluster
counts; exposing the conflated ICC (Eq. 14) as a shipped coefficient.
