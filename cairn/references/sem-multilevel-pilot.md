# Synthesis note — two-level SEM (lavaan) route to the Design-1 multilevel components (M53)

**Provenance.** Ingested 2026-07-16 by M53 from its own two-level lavaan pilot runs together with `tenhove2022.md` (the estimand) and `jorgensen2021.md` (the mean-structure device).
Pagination: —.
Extraction: derived — no external source of its own, only as current as its inputs, none re-read since 2026-07-16 — observed 2026-07-18.

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
  n_rep=100 the mean's rel SE ≈ .071, so the .05 pin sat at 0.71σ, a literal
  coin flip — ≈52% pass probability under zero bias; the observed +.0995 is
  1.4σ; failed-run checkpoint preserved) — and **re-centred per review
  finding F1**: the rater slot's raw quadratic-form estimator carries a
  *deterministic structural inflation* **E = σ²_r + τ², τ² = (σ²_{cr} +
  σ²_{(s:c)r}/n_s)/N_c** — the multilevel generalization of the single-level
  raw estimator's omitted "−σ²_res/n" term (engine header; raw by design,
  ADR-014). REML does not carry it, so the signed SEM−REML rater parity *is*
  τ², matching to ≤1e-4 across the B/C/D geometries (.0053/.0010/.0074 vs
  predicted .00525/.00105/.00742). Run 1's "shared sampling noise" diagnosis
  was incomplete: noise dominates the small cells (hence the sign flips), but
  the τ² offset sits under it and the tight cell D measured it.
  Final pins — cluster/subject-governed components: rel bias < .10 (A/B/D),
  < .05 (C). Rater: the τ² law itself (signed mean parity within .005 of
  predicted τ² — an invariant-type check) plus rel bias within
  3·√(2/(k−1))/√n_rep **of the predicted inflation τ²/σ²_r** on every cell
  (tightest at cell D: ±.0707 around +.0464).
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
  4 dp (subject 1.0364, residual .4971); cluster-level covariance components
  below REML per the ML N-divisor (cluster .4049 vs .4180; cluster_rater
  .2049 vs .2115); rater *above* REML by ≈τ² (.1597 vs .1531, gap .0066 ≈
  predicted .00525) — two distinct documented mechanisms (F1). All four
  **consistency** ICCs identical to 4 dp across engines; **agreement**
  |Δ| ≤ .008 (M49 index-class split confirmed in the multilevel case).
- **Reduction** (σ²_c = σ²_{cr} = 0, N_c=50, k=4): two-level subject-level
  ICC(A,1)/(C,1) = .606/.629 vs the shipped single-level lavaan engine's
  .614/.636 — within the .02 pin.
- **Recovery** (cells A–D): cluster/subject/cluster_rater/residual rel-bias
  ≤ .085 small cells, ≤ .011 at N_c=200. Rater: observed deviations
  (−.009/−.056/+.099/+.039) are the predicted structural inflation τ²/σ²_r
  (+.066/+.033/+.007/+.046) plus k-governed sampling noise — cell D, the
  tight cell, lands 0.3σ from prediction; the signed parity equals τ² to
  ≤1e-4 (B/C/D). Note the sign structure: the ML N-divisor story pulls the
  *cluster-level covariance* components below REML (cluster .4049 vs .4180),
  while the rater slot sits *above* REML by exactly τ² — two different,
  both-documented mechanisms, not one "ML-vs-REML budget". **Zero fit
  failures in 450 two-level fits**; one Heywood (cell A, N_c=20), matching
  the documented boundary posture.
- **Parity shrinks on the cluster axis**: cluster |Δ| .0248 → .0121 → .0025
  (A→B→C) — the ML-vs-REML gap closes as it must if the two routes estimate
  the same decomposition.
- **MC probe**: 4000 log-SD-scale draws off the two-level `vcov`, all finite;
  95% intervals s_agr_1 [.562, .655] and c_agr_1 [.365, .678] contain their
  point estimates (.612, .526). The existing delta/log-SD MC machinery ports
  unchanged; the between intercepts feed the σ²_r quadratic form per draw as
  in the single-level engine.

## Go/no-go

**GO** (2026-07-16, diagnosis sharpened by review F1). The two-level CFA is
numerically established as an estimation-route parameterization of the
ten Hove (2022) Design-1 decomposition (D-005): exact consistency-ICC
agreement, cluster-axis parity shrinking with N_c, clean reduction to the
shipped single-level engine, recovery matching prediction on every
component's own axis — where for σ²_r "prediction" includes the
**deterministic raw-estimator inflation τ² = (σ²_{cr} + σ²_{(s:c)r}/n_s)/N_c**
(the multilevel analog of the single-level engine's documented,
deliberately-uncorrected "−σ²_res/n" term, ADR-014) — and a feasible
boundary-aware MC interval at both levels. The inflation is *named and
predictable*, not absorbed into tolerance (D-005's own standard).
Implementation notes for the engine milestone: (a) lavaan two-level is
ML-only — document the small-sample REML delta as the M7/M49 posture already
does; (b) **document the τ² inflation in the engine roxygen exactly as the
single-level header documents its "−σ²_res/n" analog, and centre any
rater-parity test on τ², never on zero** — a zero-centred parity pin < .02
breaks structurally at few clusters (e.g. N_c=10, n_s=5 → τ² ≈ .026), which
is where multilevel users live (paper's own N_c ∈ {20,40}); (c) between-level
Heywood incidence at few clusters → the existing `intraclass_singular_fit`
abort toward glmmTMB; (d) parity tolerances split by index class
(consistency tight, agreement asymptotic) and budget the ML/REML gap at
small N_c.

## M58 extension — incomplete (FIML) + unequal cluster sizes (Stages 3–4)

**Question.** Does the same two-level CFA route (D-005) extend to (a) incomplete
subject×rater cells via two-level FIML (`missing = "fiml"`), and (b) unequal
per-cluster subject counts — and if so, how does the documented τ² rater
inflation generalize under imbalance? Two stages added to the pilot script
(`data-raw/pilot-sem-multilevel.R`, seeded, checkpoint before pins; full run
`PILOT PASS`, 2026-07-17).

**Stage 3 — incomplete (FIML).** One balanced C=60, n_s=10, k=5 dataset, ~18%
of cells deleted MCAR keeping every subject ≥2 raters (2460 of 3000 cells kept),
fit by two-level FIML vs a REML glmmTMB fit of the same reduced long data. The
components recover with Stage-1's index-class split intact: subject 1.0083 vs
1.0084 and residual 0.4736 vs 0.4736 (near-exact within components); cluster
0.1821 vs 0.1870 and cluster_rater 0.1481 vs 0.1517 (the ML-N-divisor gap);
rater 0.0723 vs 0.0687 (SEM above REML by τ²). Consistency ICCs |Δ| < .001, all
ICCs |Δ| ≤ .0066 — the M49 split holds on incomplete data exactly as complete.

**Stage 4 — unequal cluster sizes, τ² harmonic-mean law.** Imbalance sweep at
C=60, k=5, 60 reps per level (none/mild/severe), measuring the signed SEM−REML
rater parity (= τ², since REML carries no inflation) against two candidate laws.
The balanced τ² = (σ²_{cr} + σ²_res/n_s)/N_c **generalizes by replacing n_s with
the HARMONIC MEAN H of the per-cluster subject counts**:

  **τ² = (σ²_{cr} + σ²_res / H) / C,  H = C / Σ_c (1/m_c)**

reducing exactly to the balanced law when all m_c are equal. Observed parity vs
the harmonic law vs the size-weighted "grand" law (τ²_grand = σ²_{cr}·Σm²/N² +
σ²_res/N):

| imbalance | H | mean parity | τ²(harmonic) | τ²(grand) |
|---|---|---|---|---|
| none | 10.00 | .00355 | .00350 | .00350 |
| mild | 8.40 | .00370 | .00366 | .00393 |
| severe | 6.43 | .00385 | **.00396** | .00485 |

The harmonic law holds on every level (|parity − τ²_harm| < .005, pinned) and
**strictly beats the grand law under severe imbalance** (a discriminating pin):
lavaan's between-level mean structure weights clusters equally, not by size, so
the size-weighted grand law is wrong. Cluster/subject-governed components track
glmmTMB within the ML-N-divisor gap (< .05 relative); zero fit failures across
180 two-level fits.

**GO** (2026-07-17). Both extensions are numerically faithful under the D-005
oracle discipline — the estimand and method are unchanged, only the data shape.
Implementation notes for the engine milestone: (a) pass `missing = "fiml"` when
any wide cell is NA (the two-level analog of the single-level incomplete path);
unequal cluster sizes fit natively (nothing to change in the extraction). (b)
Document the τ² **harmonic-mean** generalization in the engine header alongside
the balanced law, centred on τ² never zero (GP5/GP7). (c) The parametric
bootstrap stays refused on incomplete data (resamples cannot reproduce the
missingness pattern, ADR-031) — MC only. (d) Connectedness/identifiability and
the averaged-cluster k_c^eff inverse-Simpson divisor (M46/ADR-057) are the
engine-agnostic crossed-multilevel guards, already shared with the mixed
engines.
