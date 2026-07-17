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
- **Stage 2 (T4):** known-population recovery, 4 cells, per-rep seeds:
  A (N_c=20, n_s=10, k=3), B (N_c=40, n_s=10, k=5), C (N_c=200, n_s=10, k=5)
  sweep the cluster axis; D (N_c=30, n_s=8, k=25, n_rep=150) sweeps k. Pins
  are **split by which axis governs a component's sampling noise** (GP5
  correction, milestone Decisions 2026-07-16 — the first run's uniform `.05
  at N_c=200` pin was mis-set for σ²_r, whose noise is df = k−1: at k=5,
  n_rep=100 the mean's rel SE ≈ .071, so .05 was a ~1.4σ coin flip; observed
  +.0995 with SEM↔REML parity .001 and cell-to-cell sign flips = shared
  sampling noise, not an SEM artifact; failed-run checkpoint preserved).
  Cluster/subject-governed components: rel bias < .10 (A/B/D), < .05 (C).
  Rater component: per-rep REML parity (mean |Δ| < .02 — the D-005
  faithfulness quantity) plus rel bias < 3·√(2/(k−1))/√n_rep on every cell
  (= .0707 at cell D, the tight test on σ²_r's own axis).
  glmmTMB parity deltas on the first 25 reps per cell must shrink with N_c.
  MC-interval feasibility probe on the Stage-1 fit: extract the two-level
  `vcov`, log-SD-transform the four variances (identity for intercepts), draw
  4000 samples, back-transform, per-draw ICCs at both levels — feasibility =
  finite positive draws, interval containing the point estimate, both levels.
- **Checkpoint:** `data-raw/.oracle-pilot-sem-multilevel-checkpoint.rds`
  (rides the committed ignore pattern), saved before any `stopifnot` pin
  (M47/M52 lessons).

## Results (run 2, corrected pins; checkpoint `.oracle-pilot-sem-multilevel-checkpoint.rds`, seeds in-script; 2026-07-16)

- **Stage 1** (N_c=40, n_s=10, k=5): within components identical to REML to
  4 dp (subject 1.0364, residual .4971); between components within the
  documented ML-vs-REML budget (cluster .4049 vs .4180; cluster_rater .2049
  vs .2115; rater .1597 vs .1531). All four **consistency** ICCs identical to
  4 dp across engines; **agreement** |Δ| ≤ .008 (M49 index-class split
  confirmed in the multilevel case).
- **Reduction** (σ²_c = σ²_{cr} = 0, N_c=50, k=4): two-level subject-level
  ICC(A,1)/(C,1) = .606/.629 vs the shipped single-level lavaan engine's
  .614/.636 — within the .02 pin.
- **Recovery** (cells A–D): cluster/subject/cluster_rater/residual rel-bias
  ≤ .085 small cells, ≤ .011 at N_c=200; rater +.039 at cell D (k=25,
  tolerance .071) with REML parity ≤ .0088 in every cell — the small-cell
  rater deviations sign-flip (−.009/−.056/+.099) exactly as the noise-floor
  analysis predicts. **Zero fit failures in 450 two-level fits**; one Heywood
  (cell A, N_c=20), matching the documented boundary posture.
- **Parity shrinks on the cluster axis**: cluster |Δ| .0248 → .0121 → .0025
  (A→B→C) — the ML-vs-REML gap closes as it must if the two routes estimate
  the same decomposition.
- **MC probe**: 4000 log-SD-scale draws off the two-level `vcov`, all finite;
  95% intervals s_agr_1 [.562, .655] and c_agr_1 [.365, .678] contain their
  point estimates (.612, .526). The existing delta/log-SD MC machinery ports
  unchanged; the between intercepts feed the σ²_r quadratic form per draw as
  in the single-level engine.

## Go/no-go

**GO** (2026-07-16). The two-level CFA is numerically established as an
estimation-route parameterization of the ten Hove (2022) Design-1
decomposition (D-005): component-level REML parity within the documented
ML-vs-REML budget and shrinking with N_c, exact consistency-ICC agreement,
clean reduction to the shipped single-level engine, unbiased recovery on
every component's own axis, and a feasible boundary-aware MC interval at both
levels. Implementation notes for the engine milestone: (a) lavaan two-level
is ML-only — document the small-sample REML delta as the M7/M49 posture
already does; (b) between-level Heywood incidence at few clusters → the
existing `intraclass_singular_fit` abort toward glmmTMB; (c) parity test
tolerances must split by index class (consistency tight, agreement
asymptotic) and budget the ML/REML gap at small N_c.
