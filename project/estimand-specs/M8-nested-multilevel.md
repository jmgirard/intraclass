# Estimand specification — M8: Nested-rater multilevel ICCs (Designs 2/3)

**Scope of this document.** The precise population quantities the multilevel
**subject-level** interrater ICCs target when raters are **nested** rather than
crossed with clusters/subjects: **Design 2** (raters nested within clusters — each
cluster has its own raters, crossed with that cluster's subjects) and **Design 3**
(raters nested within subjects *and* clusters — each subject has its own raters).
It builds directly on [`M5-multilevel.md`](M5-multilevel.md) (Design 1, raters
crossed with clusters) and reuses everything below the estimand map unchanged: the
five-→fewer-component fit pattern, the scalar-divisor `icc_point()`, the Monte-Carlo
CI (ADR-003), and the `cluster` / `level` API (ADR-011). Read M5 first.

**Source of the estimand.** ten Hove, D., Jorgensen, T. D., & van der Ark, L. A.
(2022). Interrater reliability for multilevel data: A generalizability theory
approach. *Psychological Methods, 27*(4), 650–666 (doi:10.1037/met0000391). The
variance decompositions in §2 are **Eqs. 8–11**; the estimands in §3 are transcribed
verbatim from **Table 3** (subject-level panel, "Raters nested in clusters" and
"Raters nested in subjects" columns). No term is paraphrased or guessed
(PRINCIPLES.md #1, #2, #4). PDF supplied by the maintainer (Zotero `M3BS8XJU`).

**What is transcribed vs. what is our engineering (be explicit, #18).** As in M5,
the paper estimates the components with **MCMC** (Stan) and never writes an
lme4/glmmTMB formula. The random-effects **model formulas** in §2 are therefore *our*
translation of Eqs. 8/10, **to be established by oracle, not assumed** — Slice 1/2's
first task is to confirm each formula recovers the paper's components on a hand-built
balanced dataset (method-of-moments + lme4) *before* any ICC is read off it.

**Locked scope (ADR-016), confirmed from the paper this session:**
- **Subject-level only.** Cluster-level IRR needs the cluster×rater term μ_cr, which
  is unestimable when raters are nested; the paper restricts cluster-level IRR to
  Design 1 ("Designs 2 and 3 are not interesting" at the cluster level, p. 6). M5
  already ships Design-1 cluster level.
- **Design 3 is agreement-only.** With σ²_r confounded into residual (Eq. 11), "only
  the ICC_s(k) and ICC_s(1) can be estimated" (p. 6) — the Table 3 consistency cells
  for Design 3 are "—".
- **Balanced/complete, random raters.** Incomplete and fixed-rater nested designs are
  deferred (§8), mirroring M5.

M8 ships on branch `m8-nested-multilevel`, in three CI-green slices (§6).

---

## 1. Design scope (locked with the maintainer; ADR-016)

The paper's Table 2 defines four designs; M5 shipped **Design 1** (raters crossed
with clusters). M8 adds the two **nested-rater** designs:

| Design | Structure | Estimable components (Eq.) | Levels defined |
|---|---|---|---|
| 1 (M5, shipped) | raters crossed with clusters | c, s:c, r, cr, (s:c)r (Eq. 7) | subject **and** cluster |
| **2 (M8)** | **raters nested in clusters** | c, s:c, **r:c**, (sr):c (Eq. 9) | **subject only** |
| **3 (M8)** | **raters nested in subjects & clusters** | c, s:c, **r:s:c** (Eq. 11) | **subject only, agreement only** |

| Dimension | M8 scope | deferred (§8) |
|---|---|---|
| Design | **2 and 3** (nested raters) | — |
| Level | **subject** (within-cluster) | cluster level (undefined for nested designs — paper) |
| Balance | **balanced / complete** | incomplete multilevel (reuse M3 `k_eff`/connectedness) |
| Raters mode | `raters = "random"` | fixed-rater multilevel (reuse M3 real fixed-effect fit) |
| Engine | glmmTMB (lme4 oracle) | lme4 for the multilevel fit → its own later slice (ADR-012/016) |

---

## 2. Measurement models and variance components (our formulas = translations)

### 2a. Design 2 — raters nested within clusters (paper Eqs. 8–9)

Each rater rates only subjects from a **single** cluster (raters nested in clusters),
but within that cluster raters are crossed with subjects. The cluster×rater
interaction μ_cr confounds with the cluster main effect, and the highest-order
interaction μ_{(sr):c} confounds with subject-level error (paper p. 5):

```
Y_{(sr):c} = μ + μ_c + μ_{s:c} + μ_{r:c} + μ_{(sr):c}                         (Eq. 8)

σ²_{Y(sr):c} = σ²_c + σ²_{s:c} + σ²_{r:c} + σ²_{(sr):c}                       (Eq. 9)
```

μ_{r:c} now bundles **three** indistinguishable effects: the rater main effect, the
rater×cluster interaction, and random cluster-level rater error (paper p. 5).

**Our translation (oracle-pinned, not assumed):**

```
score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)
```

| Component | Paper symbol | Internal name | Random effect |
|---|---|---|---|
| cluster | σ²_c | `cluster` | `(1 | cluster)` |
| subject-in-cluster | σ²_{s:c} | `subject` | `(1 | cluster:subject)` |
| rater-in-cluster | σ²_{r:c} | `rater` | `(1 | cluster:rater)` |
| residual | σ²_{(sr):c} | `residual` | (subject:cluster)×rater + error |

**Key coding point (pin in Slice 1):** because raters are *nested* in clusters, there
is **no `(1 | rater)` main-effect term** — the rater identity lives inside
`cluster:rater`. If rater IDs are reused across clusters (rater "1" in every cluster
is a *different* person), `(1 | cluster:rater)` is required and `(1 | rater)` would be
wrong; if rater IDs are globally unique the two coincide. This is the nesting analog
of M5's "subject labels unique within cluster" note.

### 2b. Design 3 — raters nested within subjects and clusters (paper Eqs. 10–11)

Each rater rates only a single subject in a single cluster (raters nested in
subjects, subjects nested in clusters — each subject has its **own** raters). The
rater main effect cannot be disentangled from error at all (paper p. 5):

```
Y_{r:s:c} = μ + μ_c + μ_{s:c} + μ_{r:s:c}                                    (Eq. 10)

σ²_{Yr:s:c} = σ²_c + σ²_{s:c} + σ²_{r:s:c}                                    (Eq. 11)
```

μ_{r:s:c} bundles **four** indistinguishable effects: rater main effect,
rater×cluster interaction, random cluster-level error, and random subject-level error
(paper p. 5). This is the **multilevel analog of a one-way design** (cf. M6): rater
variance is inseparable from residual, so consistency is undefined.

**Our translation (oracle-pinned, not assumed):**

```
score ~ 1 + (1 | cluster) + (1 | cluster:subject)
```

| Component | Paper symbol | Internal name | Random effect |
|---|---|---|---|
| cluster | σ²_c | `cluster` | `(1 | cluster)` |
| subject-in-cluster | σ²_{s:c} | `subject` | `(1 | cluster:subject)` |
| residual | σ²_{r:s:c} | `residual` | rater:(subject:cluster) + error |

No `(1 | rater)` and no `(1 | cluster:rater)` — the rater level *is* the residual
(each subject:cluster cell holds one rating per rater, multiple raters per subject).

---

## 3. The estimands (paper Table 3, subject-level panel — verbatim)

Each ICC is `signal / (signal + error / k)` — the **existing scalar-divisor**
`icc_point()` form (M1 §2, M5 §3). Signal is always σ²_{s:c} (subject-in-cluster);
**no cluster-related variance appears** (the ordering of subjects *within* clusters is
independent of cluster effects — paper p. 6). Only the error set changes with design
and `type`; the divisor `k` is 1 (single) or the rater count (average).

### 3a. Design 2 — raters nested in clusters (Table 3, subject-level, middle column)

| | agreement | consistency |
|---|---|---|
| single `ICC_s(·,1)` | σ²_{s:c} / (σ²_{s:c} + σ²_{r:c} + σ²_{(sr):c}) | σ²_{s:c} / (σ²_{s:c} + σ²_{(sr):c}) |
| average `ICC_s(·,k)` | σ²_{s:c} / (σ²_{s:c} + (σ²_{r:c} + σ²_{(sr):c})/k) | σ²_{s:c} / (σ²_{s:c} + σ²_{(sr):c}/k) |

Error set = `{rater, residual}` (agreement) or `{residual}` (consistency) — the
**same error-set structure as M1/M2/M5-Design-1**, with `rater` now holding σ²_{r:c}
and `residual` holding σ²_{(sr):c}. The paper states this substitution directly:
"σ²_r would be replaced by σ²_{r:c}, and … σ²_{(s:c)r} … change[s] to σ²_{(sr):c}"
(p. 6).

### 3b. Design 3 — raters nested in subjects (Table 3, subject-level, right column)

| | agreement | consistency |
|---|---|---|
| single `ICC_s(1)` | σ²_{s:c} / (σ²_{s:c} + σ²_{r:s:c}) | **— (undefined)** |
| average `ICC_s(k)` | σ²_{s:c} / (σ²_{s:c} + σ²_{r:s:c}/k) | **— (undefined)** |

Error set = `{residual}` where residual holds σ²_{r:s:c}. There is **no
agreement/consistency distinction** — with no separable rater main effect the two
would coincide, and the paper labels these plain `ICC_s(1)`/`ICC_s(k)` (its one-way
notation). Requesting `type = "consistency"` on a Design-3 fit is a classed usage
abort (§7), not silently equal to agreement.

---

## 4. What this adds to the estimand abstraction

M5 generalized the estimand to `(signal, {error set}, scalar divisor)` keyed on
`level` and `type`. M8 adds **two new fitted models** (Designs 2/3) and extends the
lookup, keeping the divisor scalar and `icc_point()`/`resolve_divisor()` untouched:

| Slot | M5 (Design 1) | M8 (Designs 2/3) |
|---|---|---|
| fit | 5 components | 4 (Design 2) or 3 (Design 3) components |
| signal | `subject` (σ²_{s:c}) or `cluster` (σ²_c) | `subject` (σ²_{s:c}) only |
| error set | by `type` × `level` | by `type` × **design** (§3; Design 3 = agreement only) |
| divisor | scalar `k` | scalar `k` — **unchanged** |

**Design detection.** How the design (1/2/3) is determined from the call is a
Slice-1 API decision (candidate: infer from the rater×cluster/subject crossing
pattern in the data, or an explicit `design`/`nesting` argument). Resolve the surface
at Slice 1's start; whichever is chosen, an ambiguous or mis-specified nesting aborts
loudly (§7), never guesses.

---

## 5. Oracles (PRINCIPLES.md #1 — ≥2 independent) and provenance

No Shrout–Fleiss-style textbook worked example exists for the nested-multilevel IRR
estimand (as with O5/O-ML). Verified in `tests/testthat/test-icc-nested-multilevel.R`
(name TBD), regenerated by `data-raw/oracle-nested-multilevel.R` (seeded, `stopifnot`
tolerances). The **M5 O-ML pattern**, per design:

- **O-NML/lme4** — `lme4::lmer` fits the identical Design-2 / Design-3 model on a
  balanced dataset and reproduces every §3 subject-level ICC (all defined type ×
  single/average) to < 1e-4. Independent implementation of the same LMM (ADR-005 role).
- **O-NML/sim** — a seeded simulation with **known** components (the paper's
  data-generating regime, M5 §5 template) recovers the points within tolerance, and
  the boundary-aware Monte-Carlo interval covers the population values (#12).
- **O-NML/reduction** — two clean reductions to already-pinned estimators, asserted
  numerically on generated data:
  - **Design 3 → M6 one-way.** With σ²_c → 0 (many clusters, no cluster variance),
    Design-3 `ICC_s(1)`/`ICC_s(k)` equal the M6 one-way `ICC(1)`/`ICC(1,k)` on the
    same ratings (ignoring cluster) to < 1e-4 — Design 3 *is* a multilevel one-way.
  - **Design 2 → M1/M2 two-way.** With a single cluster (σ²_c ≡ 0; r:c = r,
    (sr):c = sr), Design-2 subject-level agreement/consistency equal the M1/M2
    two-way `ICC(A,·)`/`ICC(C,·)`. (A *single* cluster is degenerate for σ²_c; use it
    only as the reduction limit, per M5's O-ML/reduction note.)

**Regression guard:** the full existing suite — M1–M7 oracles, incl. M5 O-ML — stays
green (the scalar-divisor path and Design-1 fit are untouched).

If any §3 coefficient cannot be pinned by both required oracles it is **not shipped**,
a Fable review is *recommended*, and work pauses (PRINCIPLES.md #1, #19).

---

## 6. Slices

- **Slice 1 — Design 2 (raters nested in clusters).** Design detection (§4), the
  four-component glmmTMB fit (§2a) with component extraction + identifiability guards
  (§7), the Design-2 signal/error map (§3a). `print`/`tidy`/`glance` surface the
  design. Oracles O-NML/lme4, O-NML/sim, O-NML/reduction (Design 2 → two-way). Reuses
  the scalar `icc_point()` and MC CI. End-to-end thin slice.
- **Slice 2 — Design 3 (raters nested in subjects).** The three-component fit (§2b),
  the agreement-only map (§3b) with the consistency abort, off a fit that reuses
  Slice-1 machinery. Oracles extended, incl. O-NML/reduction (Design 3 → M6 one-way).
- **Slice 3 — docs.** Extend `advanced.Rmd`'s multilevel section to the nested designs
  on real code; add the Design-2/3 rows to any decision material; `test-vignette-
  claims.R` invariants (e.g. average ≥ single; Design-3 reduces to one-way as σ²_c→0).

---

## 7. Identifiability and boundaries (PRINCIPLES.md #5)

- **≥ 2 raters per subject** (Design 3) / **per cluster** (Design 2) are required to
  identify rater-related variance — the paper's minimum (cf. M5 §7).
- **Design mis-specification aborts, never guesses.** If the data's crossing pattern
  contradicts the requested/inferred design (e.g. `design = 2` but a rater appears in
  two clusters → not nested), classed `abort_unidentified()` / `abort_intraclass()`.
- **Design 2:** needs ≥ 2 clusters for σ²_c and enough raters-per-cluster for σ²_{r:c};
  a `cluster` 1:1 with `subject` leaves σ²_c / σ²_{s:c} unidentified → classed abort.
- **Design 3:** needs ≥ 2 raters per subject (else σ²_{r:s:c} is a single point) and
  ≥ 2 clusters for σ²_c; the exact minimum-viable N_c threshold is an **open design
  question for the maintainer** (as in M5 §7 — confirm hard-error vs. warning).
- **`type = "consistency"` with a Design-3 fit** is a classed usage abort (no
  separable rater effect; §3b), not a silent equality.
- **Few clusters** ⇒ σ²_c poorly estimated, wide MC intervals — honest boundary-aware
  behavior (ADR-003), documented and guarded, not suppressed.

---

## 8. Out of scope (recorded for forward-compatibility)

Cluster-level IRR for nested designs (undefined — the paper restricts it to Design 1);
**incomplete** nested multilevel (reuse M3 `k_eff`/connectedness); **fixed-rater**
nested multilevel (reuse M3 real fixed-effect fit path); **lme4 for the multilevel
fit** (its own later slice, ADR-012/016); a Bayesian/MCMC cross-engine (the paper's
own estimator); a three-facet `d_study()` over subject-per-cluster counts; exposing
the conflated single-level ICC (Eq. 14).
