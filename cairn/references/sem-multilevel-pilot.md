# Synthesis note — two-level SEM (lavaan) route to the Design-1 multilevel components (M53)

**Type:** synthesis note (cross-source analysis + pilot ledger). No single
`<citekey>.md` owns this: it composes ten Hove, Jorgensen & van der Ark (2022)
(the estimand), Jorgensen (2021) (the single-level SEM-GT mean-structure
device), and generic two-level ML-SEM methodology (Muthén 1994; Rosseel's
lavaan implementation) under the D-005 IP1 disposition (estimation-route
parameterization, faithfulness established by oracle, never assumed).

**Sourcing status (M53 T1, 2026-07-16):** no primary source presents a
two-level SEM formulation of multilevel GT interrater reliability. Jorgensen
(2021, *Psych* 3(2):113–133) covers p×i, p×i×o, p×(i:o) — single-level only;
its limitations section defers to mixed-effects modeling where SEM becomes
infeasible. ten Hove et al. (2022, *Psychological Methods* 27(4):650–666)
estimates the Design-1 components by MCMC and notes MLE availability (p. 4)
without an SEM. The Vispoel SEM-GT arc (2022–2025) is single-level
(univariate/multivariate/bifactor). The mapping below is therefore **our
engineering** — D-005 fences it as a parameterization of the published
decomposition, with the pilot as the faithfulness evidence.

## The mapping (Design 1: subjects nested in clusters, raters crossed)

Wide layout: one row per subject, columns `v1..vk` (one per rater), plus the
`cluster` id; `lavaan(..., cluster = "cluster")`. The paper's Eq. 7
decomposition σ²_Y = σ²_c + σ²_{s:c} + σ²_r + σ²_{cr} + σ²_{(s:c)r} maps onto
the two-level CFA as:

| Level | lavaan parameter | Component | Paper symbol |
|---|---|---|---|
| within | common-factor variance `subj ~~ svw*subj` (loadings 1) | subject-in-cluster | σ²_{s:c} |
| within | equal indicator residuals `vj ~~ evw*vj` | residual (confounded (s:c)×r + error) | σ²_{(s:c)r} |
| between | common-factor variance `clus ~~ svb*clus` (loadings 1) | cluster | σ²_c |
| between | equal indicator residuals `vj ~~ evb*vj` | cluster × rater | σ²_{cr} |
| between | indicator intercepts ν_j (grand-mean-centred quadratic form) | rater | σ²_r = Σν̃²_j/(k−1) |

Rationale, per column j (rater j): within a cluster, subject scores on column
j share the subject factor (σ²_{s:c}) and deviate by the confounded residual
(σ²_{(s:c)r}). Cluster means of column j share the cluster factor (σ²_c),
deviate by the cluster-specific rater offset (σ²_{cr} — the between-level
residual), and carry rater j's main effect as a constant column offset — the
between-level intercept, exactly Jorgensen (2021)'s single-level device
(Eq. 6; the shipped engine's `center = I − J/k` recentring makes the quadratic
form identification-invariant). The subject- and cluster-level ICC estimands
(paper Table 3, Design 1; spec `M5-multilevel.md` §3) then read off these five
components unchanged.

## Estimation constraints (documented, not defects)

- **ML only.** lavaan's two-level estimator is full-information ML; there is
  no `likelihood = "wishart"` (N−1) analog, so components carry ML's N-divisor
  shrinkage relative to the package's REML glmmTMB spine (`REML = TRUE`,
  `R/engine-glmmtmb.R`). Parity tolerances must budget for this: exact-match
  is *not* expected at small N_c; agreement must tighten as N_c grows.
  Consistency ICCs (ratios) absorb most of it (M49 lesson: split tolerances
  by index class — tight C, looser A).
- **Complete/balanced only** for the pilot (matching the M53 scope); lavaan
  multilevel handles unbalanced cluster sizes but that is out of scope here.
- **Intercept placement:** within-level intercepts fixed at 0; between-level
  intercepts free (the rater effects live between clusters — a rater's offset
  is constant within a cluster).
- **Boundary behavior:** a near-zero σ²_c or σ²_{cr} can Heywood at the
  between level (negative variance estimates); the pilot records incidence.
  The shipped engine's posture would be the existing classed
  `intraclass_singular_fit` abort toward glmmTMB.

## Pilot design (`data-raw/pilot-sem-multilevel.R`, seeded)

- **Stage 1 (T3):** one balanced Design-1 dataset (paper-like components) →
  five components + all eight Table-3 ICCs (2 levels × 2 types × 2 units)
  from the two-level lavaan fit vs a REML glmmTMB fit of the same data;
  reduction check: data with σ²_c = σ²_{cr} = 0 (many clusters) → two-level
  subject-level ICCs vs the shipped single-level lavaan engine on the same
  ratings ignoring cluster.
- **Stage 2 (T4):** known-population recovery, 3 cells sweeping the cluster
  axis (GP6): (N_c=20, n_s=10, k=3), (N_c=40, n_s=10, k=5),
  (N_c=200, n_s=10, k=5); n_rep = 100 per cell, per-rep seeds; mean relative
  bias per component and per ICC < .10 in the small cells, < .05 at N_c=200;
  glmmTMB parity deltas on the first 25 reps per cell must shrink with N_c.
  MC-interval feasibility probe on the Stage-1 fit: extract the two-level
  `vcov`, log-SD-transform the four variances (identity for intercepts), draw
  4000 samples, back-transform, per-draw ICCs at both levels — feasibility =
  finite positive draws, interval containing the point estimate, both levels.
- **Checkpoint:** `data-raw/.oracle-pilot-sem-multilevel-checkpoint.rds`
  (rides the committed ignore pattern), saved before any `stopifnot` pin
  (M47/M52 lessons).

## Results

_Pending: filled by T5 after the pilot runs._

## Go/no-go

_Pending: recorded by T5; systematic disagreement beyond the documented
ML-vs-REML deltas is a no-go finding, never a tolerance to widen (GP5/D-005)._
