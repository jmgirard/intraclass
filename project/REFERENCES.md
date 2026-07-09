# References & oracle registry

Bibliography plus the registry of oracle values used in tests. **Every oracle
value in the test suite must trace back to an entry here** with provenance — a
citation or a committed, seeded script (PRINCIPLES.md #4, #12). No unsourced
reference values, ever.

---

## Oracle registry

An oracle's **asserted-state is single-sourced to its test file** (ADR-015): the
`Status` line names the test that asserts it, which is the grep-verifiable truth.
This registry carries **no independent planned→asserted lifecycle** — an oracle is
listed here once it is asserted; a not-yet-written oracle is planned in its
estimand-spec, not here, so there is no "planned" status in this file to fall stale.

### Oracle O1 — Shrout & Fleiss (1979) worked example
- **Used by:** `tests/testthat/test-icc-twoway-agreement.R`
  (data + values in `tests/testthat/helper-shrout-fleiss.R`).
- **Primary source:** Shrout, P. E., & Fleiss, J. L. (1979). Intraclass
  correlations: uses in assessing rater reliability. *Psychological Bulletin,
  86*(2), 420–428.
- **Design:** balanced, complete; 6 subjects × 4 raters, integer ratings.
- **Independent cross-checks:** `psych::ICC()` (Revelle) is the **live in-suite
  cross-check** — a `skip_if_not_installed("psych")` assertion runs on every test
  pass (psych is in `Suggests`). `DescTools::ICC()` (Signorell et al.) was a
  **one-time manual confirmation** recorded in `helper-shrout-fleiss.R`'s header
  comment only; DescTools is **not** a dependency and is **not** exercised by any
  test — do not read it as a standing oracle. The values themselves trace to the
  Shrout & Fleiss (1979) textbook (the primary source, #4), so this does not affect
  provenance.
- **Values (3 dp):**

  | Package label | This package | SF form | Value |
  |---|---|---|---|
  | ICC1  | ICC(1)   | one-way random, single            | 0.166 |
  | ICC2  | ICC(A,1) | two-way random, absolute, single  | 0.290 |
  | ICC3  | ICC(C,1) | two-way, consistency, single      | 0.715 |
  | ICC1k | ICC(k)   | one-way random, average           | 0.443 |
  | ICC2k | ICC(A,k) | two-way random, absolute, average | 0.620 |
  | ICC3k | ICC(C,k) | two-way, consistency, average     | 0.909 |

- **Notation bridge:** McGraw & Wong (1996) ICC(A,·) two-way random ≡ Shrout &
  Fleiss ICC(2,·); ICC(C,·) two-way mixed ≡ ICC(3,·).
- **Asserted:** ICC(A,1)=0.290, ICC(A,k)=0.620 (M1,
  `test-icc-twoway-agreement.R`); ICC(C,1)=0.715, ICC(C,k)=0.909 (M2,
  `test-icc-consistency.R`, cross-checked against `psych::ICC` ICC3/ICC3k to
  1e-4). ICC(1)=0.166, ICC(k)=0.443 **asserted (M6)** for the one-way path
  (`test-icc-oneway.R`, cross-checked against `psych::ICC` ICC1/ICC1k to 1e-4 and
  one-way ANOVA mean squares); see O-OW.

### Oracle O2 — ANOVA mean-squares (package-independent, hand-derived)
- **Status:** **asserted (M1)** in `tests/testthat/test-icc-anova-oracle.R`: the
  mean squares are recomputed with base `stats::aov()`, the method-of-moments
  components derived, and the glmmTMB engine's `VarCorr` + reported ICCs matched
  to them (tolerance 1e-4). Reproducible; nothing hardcoded.
- **Source:** the ANOVA identity applied to the O1 dataset, derived in
  [`estimand-specs/M1-twoway-random-agreement.md`](estimand-specs/M1-twoway-random-agreement.md)
  §6 (not another R package). Must be recomputed and checked in R before use — do
  not hardcode until reproduced (PRINCIPLES.md #4).
- **Mean squares (n = 6, k = 4):** BMS = 11.24167 (df 5), JMS = 32.48611 (df 3),
  EMS = 1.01944 (df 15).
- **Method-of-moments variance components** (what REML returns on this balanced
  set): σ²_s = 2.55556, σ²_r = 5.24444, σ²_res = 1.01944.
- **Resulting coefficients:** ICC(A,1) = 2.55556 / 8.81944 = 0.28976 → 0.290;
  ICC(A,k) = 2.55556 / 4.12153 = 0.62017 → 0.620. (Consistency cross-check:
  σ²_s/(σ²_s+σ²_res) = 0.71484 → 0.715.)

### Oracle O3 — seeded simulation with known population components
- **Status:** **asserted (M1)** in `tests/testthat/test-icc-simulation.R`
  (`set.seed(2024)`, n = 100, k = 8, σ²_s = 4, σ²_r = 1, σ²_res = 2). The point
  ICCs recover the population values within 0.05 and the Monte-Carlo interval
  covers them. Seeded per PRINCIPLES.md #12.

### Oracle O4 — fixed ≡ random raters on balanced data (M2; superseded by ADR-008)
- **Status:** **asserted** in `tests/testthat/test-icc-consistency.R` ("fixed
  raters reproduce random point estimates on balanced data"). Originally (M2) a
  shared-fit label layer gave *identical* point estimates and CIs (ADR-006).
  **ADR-008 (M3) superseded this:** `raters = "fixed"` now has its own
  fixed-effect fit, so on balanced data the **point** estimates still match random
  (bias-corrected θ²_r = σ²_r), but the intervals genuinely differ for absolute
  agreement (fixed-vs-random inference differs). The test now asserts point
  equivalence (< 1e-3) + valid intervals; the fixed fit's own oracles are O6.
- **Provenance (engine-level derivation):** `data-raw/oracle-fixed-vs-random.R`
  fits raters as a random intercept vs. as fixed effects (`lmer`) and shows
  identical σ²_s/σ²_res on the balanced SF data (|Δσ²_s| ≈ 7e-6), matching ANOVA
  MoM and `psych::ICC` ICC3/ICC3k. The same script demonstrates the equivalence
  **breaks under imbalance** (drop 4 of 24 cells ⇒ ΔICC(C,1) ≈ 0.0095), the M3
  caveat behind ADR-006. Reproducible; nothing hardcoded.

### Oracle O5 — incomplete/imbalanced random-rater ICCs (M3 Slice 1)
- **Status:** **asserted (M3 Slice 1)** in `tests/testthat/test-icc-incomplete.R`.
  Two independent oracles for the ragged two-way random-rater path, since no
  textbook worked example exists for arbitrary unbalanced data (M3 spec §8):
  1. **lme4 cross-engine** — on an incomplete, connected Shrout & Fleiss subset
     (drop cells (S1,J1),(S2,J2) ⇒ per-subject counts 3,3,4,4,4,4; k_eff = 3.6),
     `lme4::lmer` reproduces the glmmTMB engine's ICC(A,1)/(A,k)/(C,1)/(C,k) to
     < 1e-4. Pins the extraction and the `k_eff` divisor plumbing (ADR-008).
  2. **Seeded simulation** — `set.seed(20260706)`, 120 subjects × 30 raters,
     ~25% MCAR deletion, σ²_s = 4, σ²_r = 1, σ²_res = 2 (k = 30 so σ²_r is
     identified in a single draw; few-rater σ²_r is honestly noisy). Recovers the
     components (≈ 4.14 / 1.01 / 2.01) and ICC(A,1) = 0.579 (pop 0.571),
     ICC(C,1) = 0.674 (pop 0.667) within 0.05; the boundary-aware Monte-Carlo
     intervals cover both population values.
- **Provenance:** `data-raw/oracle-incomplete.R` (seeded; reproduces both oracles
  with `stopifnot` tolerance checks). Reproducible; nothing hardcoded.
- **Not oracles here:** `psych::ICC` (ANOVA / listwise-deletion — cannot compute
  the incomplete-data estimand, so it stays the *balanced*-only oracle O1);
  `irrNA`/`gtheory` are **not** dependencies and **no test references them** —
  they remain candidate future cross-checks that would be `skip_if_not_installed`-
  guarded *if added*, not something exercised today. The lme4 + simulation pair
  already meets the ≥2-independent-oracle bar (PRINCIPLES.md #1), so they are not
  required.

### Oracle O6 — fixed-effect fit path, two-way mixed (Case 3 / 3A) (M3 Slice 2)
- **Status:** **asserted (M3 Slice 2)** in `tests/testthat/test-icc-fixed-fit.R`.
  The real fixed-effect fit `score ~ 1 + rater + (1 | subject)` for
  `raters = "fixed"` (resolves the ADR-006 debt), pinned by three oracles:
  1. **Balanced reduction** — on complete SF the fixed fit reproduces
     ICC(A,1)=0.290, ICC(A,k)=0.620, ICC(C,1)=0.715, ICC(C,k)=0.909, and the
     bias-corrected θ²_r equals the random-fit σ²_r (5.2444). Extends O4 from a
     shared fit to an **independent** fixed-effect fit. (Raw variance fails:
     θ²_r ≈ 5.41 → ICC(A,1) = 0.284 ≠ 0.290 — the bias correction is load-bearing.)
  2. **lme4 cross-engine** — on an incomplete SF subset lme4's fixed fit
     reproduces σ²_s/σ²_res and, via the same θ²_r formula, the fixed ICCs to <1e-4.
  3. **Coverage simulation** — with **known** fixed rater effects (known true θ²_r
     and ICCs), 300 seeded MCAR-incomplete reps give ~unbiased points (ICC(A,1)
     bias −0.005) and nominal Monte-Carlo interval coverage (0.950 / 0.947 at 95%).
     This is the gate the estimand spec (§6) deferred for the Case 3A θ²_r CI.
- **Decision:** θ²_r = bias-corrected finite-population variance of the k rater
  level means (ADR-008); the per-draw θ²_r applies the same correction, clamped
  at 0 (boundary-aware).
- **Provenance:** `data-raw/oracle-fixed-incomplete.R` (seeded; `stopifnot`
  checks; the 300-rep coverage run kept here and in the scheduled reference-values
  job, not the unit suite). Reproducible; nothing hardcoded.

### Oracle O-DS — D-study projection Φ(m) (pre-M5 slice, ADR-010)
- **Status:** **asserted** in `tests/testthat/test-d-study.R`. Projection of a
  fitted `icc()` to an arbitrary rater count `m` (`d_study()` and numeric `unit`),
  pinned by closed-form and independent oracles:
  1. **O-SB (Spearman–Brown)** — consistency projection equals
     `Φ_C(m) = m·ρ / (1 + (m−1)·ρ)` with `ρ = ICC(C,1)` (closed form, independent of
     the estimator's arithmetic).
  2. **O-GT (dependability)** — agreement projection equals
     `Φ_A(m) = σ²_s / (σ²_s + (σ²_r + σ²_res)/m)` from the fitted components.
  3. **O-psych** — at `m = n_raters` the projection equals `icc()`'s own
     average-measure estimate **and** `psych::ICC`'s average-measure ICC (ICC2k /
     ICC3k) on the balanced SF data (a third, independent implementation).
  4. **O-sim** — a seeded simulation with known components recovers the population
     Φ(m) for an m **not run** (project `m = 12` from `k = 6`) and the MC interval
     covers it.
  Invariants: the curve is increasing in `m` and stays in `[0, 1]`; seeded
  projections are reproducible and RNG-neutral (#9, #12).
  5. **Multilevel rater-count projection asserted (M17 Slice 2)** — `d_study()` on a
     multilevel fit projects `m` at the subject and cluster levels (ten Hove Eq.
     12/13; spec `M4.5-d-study.md` §7): at `m = observed k` each level equals the
     fitted `ICC(*,k)` (<1e-4), the curve matches an independent `lme4` five-component
     fit, a seeded sim recovers a projected value not run with MC coverage, and
     consistency projection is Spearman–Brown per level. Subjects-per-cluster is
     **not** projected (Eq. 13 has no subject facet; ADR-026 amendment).
- **Decision:** projection is a change of the averaging divisor (ADR-010; estimand
  spec `M4.5-d-study.md`); fixed-rater absolute agreement is refused as ill-posed.
- **Provenance:** `data-raw/oracle-d-study.R` (seeded; regenerates the analytic and
  simulation values). Reproducible; nothing hardcoded.

### Oracle O-ML — multilevel ICCs, subject- & cluster-level (M5)
- **Status:** **asserted (M5)** in `tests/testthat/test-icc-multilevel.R`
  (ADR-011; spec `M5-multilevel.md` §5). The four (level × type) estimand equations
  are transcribed verbatim from ten Hove Table 3 (Design 1). Three oracles for the
  subject-level (within-cluster) and cluster-level (between-cluster) IRR ICCs, since
  no textbook worked example exists for the multilevel IRR estimand (as with O5):
  1. **lme4 cross-engine** — `lme4::lmer` fits the identical five-component Design-1
     model `score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) +
     (1 | cluster:rater)` on a balanced multilevel dataset and reproduces both ICC
     families' points to <1e-4.
  2. **Seeded simulation** — known σ²_c/σ²_s/σ²_r/σ²_res; both families' points
     recovered within tolerance and the boundary-aware Monte-Carlo interval covers
     the population values. Seeded per PRINCIPLES.md #12.
  3. **Single-level reduction** — the subject-level estimand is algebraically
     identical to the single-level M1/M2 estimand once the error set matches
     (asserted as a code-level invariant); and, numerically, a balanced dataset
     generated with **zero cluster and cluster×rater variance and many clusters**
     (a single cluster is degenerate) yields subject-level ICCs equal to a
     single-level `icc()` fit on the same ratings to <1e-4 (also vs. lme4). Guards
     the new five-component fit. (No claim that it reproduces the exact Shrout &
     Fleiss 0.290/0.620/0.715/0.909 unless a dataset yielding them is committed.)
- **Decision:** signal is σ²_{s:c} (subject level) or σ²_c (cluster level); each ICC
  is `signal / (signal + error / k)` with a scalar rater divisor `k`, error sets per
  ten Hove Table 3 / spec §3 (ADR-011). `psych`/`gtheory` are **not** oracles here
  (they do not target this estimand); a Bayesian/MCMC cross-check (ten Hove's own
  method) remains deferred (ROADMAP).
- **Provenance:** `data-raw/oracle-multilevel.R` (seeded; `stopifnot` tolerance
  checks), committed. Reproducible; nothing hardcoded.

### Oracle O-Conflated — conflated single-level ICC, Eq. 14 (M17 Slice 1)
- **Status:** **asserted (M17 Slice 1)** in `tests/testthat/test-icc-multilevel.R`
  (ADR-026; spec `M17-conflated-icc.md`). `level = "conflated"` targets ten Hove et
  al. (2022) **Eq. 14** — the biased single-level ICC obtained by ignoring the
  cluster structure — off the M5 five-component fit; agreement-only, a diagnostic
  contrast. Three oracles: **O-lme4** (Eq. 14 from an independent `lmer` fit, <1e-4);
  **O-Eq14** (closed-form Eq. 14 on the object's reported components, ~1e-10); and
  **O-population** (seeded recovery with MC-interval coverage + resemblance to the
  flat single-level `icc()` — a *population-level*, not finite-sample, equivalence,
  #18).
- **Decision:** signal σ²_c + σ²_{s:c} over error {σ²_r, σ²_cr, σ²_{(s:c)r}}, divisor
  `k`; surfaced only as a diagnostic contrast, never recommended (ADR-026).
  Consistency-conflated is unsourced and parked (ROADMAP).

### Oracle O-Rep — within-cell replicates, two-way random (M17 Slice 3)
- **Status:** **asserted (M17 Slice 3)** in `tests/testthat/test-replicates.R`
  (ADR-026; spec `M17-within-cell-replicates.md`). Replicated cells split the residual
  into σ²_sr (interaction) and σ²_e (pure error) via `(1 | subject:rater)`; the
  `occasions` knob averages pure error over replicates. Three oracles, no `gtheory`
  dependency: **O-ANOVA** (the balanced two-way-with-replication ANOVA mean squares
  give all four components by method of moments — independent of REML — and every
  single-occasion and occasion-averaged ICC matches to <1e-4); **O-lme4** (identical
  interaction fit, <1e-4); **O-sim** (seeded recovery + MC coverage). Both
  `ci_method`s exercised.
- **Decision:** per-component error divisors (σ²_e divides by raters × occasions,
  σ²_r/σ²_sr by raters only); `k_eff` counts distinct raters. Two-way random,
  balanced/complete replicates (M17 Slice 3); fixed / multilevel / ragged replicates
  shipped in M20 (below); one-way replicates stay ⚫ by design.
- **Provenance:** seeded generator `sim_replicates()` in the test file; ANOVA MoM via
  `stats::aov`. Reproducible; nothing hardcoded.

### Oracle O-FRep / O-MLRep / O-RagRep — within-cell replicate completeness (M20)
- **Status:** **asserted (M20)** (ADR-030; extends spec `M17-within-cell-replicates.md`
  §7 into the shipped map). Three slices extend O-Rep beyond two-way-random /
  single-level / balanced:
  - **O-FRep** (fixed-rater, `tests/testthat/test-replicates.R`): θ²_r (shared
    `theta2r_fixed()`, McGraw & Wong Case 3A) in the rater slot of the interaction fit.
    Exact **balanced fixed ≡ random** (<1e-4), consistency ≡ random (~1e-8), reduction
    to the single-occasion fixed fit via cell-mean aggregation, glmmTMB↔lme4 <1e-4, SF
    labels (fixed agreement NA / consistency ICC(3,·)), the balanced fixed ANOVA mean
    squares, seeded recovery + MC coverage, both `ci_method`s. Balanced/complete only.
  - **O-MLRep** (multilevel, `tests/testthat/test-icc-multilevel.R`): crossed Design 1
    (six-component) and nested Design 2 (five) add `(1|cluster:subject:rater)`. The
    **occasion-averaged coefficient equals the M5/M8 fit on the replicate cell means**
    (~1e-8) and σ²_{csr}+σ²_e/n_o == that cell-mean residual; glmmTMB↔lme4 <1e-4;
    seeded recovery + MC coverage; cluster level single-occasion; both `ci_method`s.
    Balanced/complete random only. (N_c=1→M17 is unreachable — multilevel needs ≥2
    clusters — so cross-engine + reduction-via-cell-means are the independent oracles.)
  - **O-RagRep** (ragged single-occasion, `tests/testthat/test-replicates.R`): the
    replicate analogue of M3 — harmonic-mean `k_eff` (distinct raters/subject) +
    connectedness. glmmTMB↔lme4 <1e-4 on unequal counts **and** incomplete crossing;
    `k_eff = n_raters` on complete-crossing ragged counts; the ICC(A,1)-from-components
    identity; seeded recovery + MC coverage; both `ci_method`s.
- **Decision (attempt-then-degrade, #1/#4):** the **occasion-averaged coefficient on
  ragged data is 🟣 research, not shipped** — unequal per-cell counts give no single
  scalar effective-n_o divisor and no independent oracle to pin one; `occasions =
  "average"` on ragged data aborts loudly. Ragged×fixed, ragged×multilevel, Design 3
  replicate-split, and `d_study()` off a replicate fit are deferred/⚫ (COVERAGE §②).
- **Provenance:** seeded generators `sim_replicates()`/`sim_multilevel_rep()`/
  `sim_nested_rep()`/`sim_ragged_rep()` in the test files; glmmTMB the independent
  oracle for lme4 (and vice versa). Reproducible; nothing hardcoded.

### Oracle O-OW — one-way random ICC(1)/ICC(k) (M6)
- **Status:** **asserted (M6)** in `tests/testthat/test-icc-oneway.R` (spec
  `M6-oneway.md` §7). Unlike O-ML, a textbook worked example **does** exist (SF
  Case 1), so five oracles pin the estimand:
  1. **Shrout & Fleiss (1979) textbook** — ICC(1) = 0.166, ICC(1,k) = 0.443 (the
     staged O1 values), asserted on the absolute gap (published to 3 dp).
  2. **`psych::ICC` ICC1/ICC1k** — live in-suite cross-check to 1e-4.
  3. **One-way ANOVA mean squares** — `(MSB−MSW)/(MSB+(k−1)MSW)` and
     `(MSB−MSW)/MSB` from base `stats::aov(score ~ subject)`, package-independent,
     to 1e-4.
  4. **glmmTMB ↔ lme4 cross-engine** — both one-way fits agree on point (≤1e-4)
     and interval (absolute ≤0.02).
  5. **Seeded simulation** — known σ²_s and a single confounded within-subject
     error (no rater effect); points recovered within tolerance and the
     Monte-Carlo interval covers the population values (#12).
- **Decision:** signal σ²_s, error {confounded residual σ²_res = σ²_r + σ²_e},
  divisor 1/k/m; read off `score ~ 1 + (1 | subject)` (no rater term). One-way ≠
  consistency despite identical algebra (different fit; M6 spec §3). Verified live
  (2026-07-07) before code.
- **Provenance:** SF (1979) textbook + reproducible in-suite computation; nothing
  hardcoded beyond the published 0.166/0.443 (already in `sf_oracle_all`).

### Oracle O-SEM — lavaan (SEM) engine, two-way (M7 random; M21 fixed/incomplete/bootstrap)
- **Status:** **asserted (M7 + M21)** in `tests/testthat/test-icc-lavaan.R` and
  `tests/testthat/test-ci-bootstrap.R`. The lavaan engine fits the generalizability
  model as a common-factor SEM (Jorgensen 2021). It is oracled in **two regimes**,
  because absolute agreement is a *different estimator* than the mixed model while
  consistency is not:
  1. **Consistency ≡ glmmTMB (exact).** σ²_s / (σ²_s + σ²_res) is a ratio, so lavaan
     reproduces the glmmTMB REML estimate to ≤1e-4 and the published SF ICC(3,·)
     (0.7148/0.9093). The N−1 (Wishart) likelihood makes the SEM variances match REML
     on balanced data.
  2. **Agreement = SEM indicator-mean estimator (Jorgensen 2021, Eq. 6).**
     σ²_r = Σν²/(k−1), the **raw** variance of the effects-coded indicator intercepts
     (no bias correction — confirmed by Lee & Vispoel 2024, Eqs. 8/25). Pinned by:
     (a) the **exact Eq. 6 formula** reproduced independently in-test
     (`components$rater` = Σ(mean_j − grand)²/(k−1) = 5.4144 on SF); (b) a **large-N
     seeded simulation** where lavaan → the known population and lavaan ≈ glmmTMB
     (their asymptotic equivalence, tol 0.02/0.05, #12); (c) **external validation** —
     Vispoel, Hong, Lee & Xu (2022) show the SEM indicator-mean method matches GENOVA
     / `gtheory` / SAS / SPSS to ≤ .001 (G-coef) / ≤ .005 (D-coef) across 24 real
     scales. On the 6-subject SF data this estimator gives ICC(A,1)=0.284 (not the
     mixed-model 0.290) — a documented small-sample difference, regression-pinned.
  - **Interval:** consistency vs glmmTMB *random* MC CI, agreement vs glmmTMB *fixed*
    MC CI (the SEM recovers the rater effect from a finite set of intercepts —
    Case 3A inference), absolute gap ≤0.02. Boundary: a Heywood/degenerate fit raises
    a classed `intraclass_singular_fit` → glmmTMB.
  - **M21 additions (ADR-031), all vs glmmTMB the independent engine:**
    - **Bootstrap (Slice 1, O2).** `ci_method = "bootstrap"` runs a parametric bootstrap
      (simulate from the fitted SEM's implied moments → refit → recompute the ICC per
      resample). Oracled by coverage of the known population on the estimator-invariant
      **consistency** ratio (agreement's population-coverage is *not* a valid oracle —
      the SEM estimator targets the finite-rater quantity), bootstrap ≈ lavaan MC (same
      estimand, ≤0.06), and cross-engine lavaan ≈ glmmTMB consistency bootstrap (≤0.06).
    - **Fixed raters (Slice 2, O-FSEM).** The SEM *fit* is unchanged (rater effects are
      always mean-structure intercepts); fixed raters read the **McGraw & Wong Case-3A
      bias-corrected θ²_r = max(0, raw − bias)**, bias = tr(center·V_ν)/(k−1) from the
      intercept vcov (theta2r_fixed()'s correction with the identity contrast). A
      **distinct** estimator, not the raw M7 σ²_r — pinned by reduction to **both**
      glmmTMB Case-3A fixed **and** random σ²_r on balanced data (SF ≤1e-2 small-sample:
      0.291 vs 0.290; large-N ≤1e-3), θ²_r < raw, consistency ≡ random exactly.
    - **Incomplete/FIML (Slice 3, O-FIML).** Missing cells estimated by FIML (`missing =
      "fiml"`); consistency vs glmmTMB ≤8e-3, agreement vs glmmTMB ≤1.5e-2 (the same raw
      SEM small-sample bias as complete data, shrinking with n — attempt-then-degrade
      **resolved to SHIPS**, no research degrade). Disconnected ragged designs still hit
      the engine-agnostic connectedness abort; the parametric bootstrap is gated on
      incomplete data (resamples cannot reproduce the missingness pattern).
- **Decision:** signal σ²_s, error {rater σ²_r, residual σ²_res} (agreement) or
  {residual} (consistency), divisor 1/k/m; σ²_s/σ²_res read off the covariance
  structure, σ²_r off the mean structure (Eq. 6). **An earlier unsourced bias
  correction was removed** (#1/#4; ADR-014). Two-way random only; one-way SEM has no
  faithful sourced route and is deferred (ROADMAP).
- **Provenance:** `data-raw/oracle-sem.R` (seeded; `stopifnot` checks; documents the
  Jorgensen 2021 / Vispoel et al. 2022 / Lee & Vispoel 2024 sources). Reproducible;
  the only committed constants are the regression pins 0.284/0.614 (the SEM
  estimator's SF values, reproducible from Eq. 6).

### Cross-engine oracle — lme4 (independent implementation)
- **Status:** **asserted (M1)** in `tests/testthat/test-icc-engine-oracle.R`:
  `lme4::lmer` fit directly reproduces the glmmTMB engine's point ICCs to 1e-4 on
  the balanced O1 data (ADR-002/005 — lme4 is oracle-only in M1). **M3 extends this
  cross-check to incomplete data** — see O5.

---

## Bibliography

- Brennan, R. L. (2001). *Generalizability Theory.* Springer.
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400.
- Jorgensen, T. D. (2021). How to estimate absolute-error components in structural
  equation models of generalizability theory. *Psych, 3*(2), 113–133.
  doi:10.3390/psych3020011. (M7 lavaan engine — the SEM absolute-error method; Eq. 6
  defines σ²_i as the raw variance of the effects-coded indicator intercepts.)
- Lee, H., & Vispoel, W. P. (2024). A robust indicator mean-based method for
  estimating generalizability theory absolute error and related dependability indices
  within structural equation modeling frameworks. *Psych, 6*(1), 401–425.
  doi:10.3390/psych6010024. (Confirms the raw indicator-mean formula, Eqs. 8/25;
  "robust" = an ordinal scale-coarseness correction, not a bias correction.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- Rosseel, Y. (2012). lavaan: An R package for structural equation modeling.
  *Journal of Statistical Software, 48*(2), 1–36. (M7 SEM engine.)
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater
  reliability for multilevel data: A generalizability theory approach.
  *Psychological Methods, 27*(4), 650–666 (advance online publication 2021;
  doi:10.1037/met0000391). (M5 multilevel estimand — subject- and cluster-level IRR
  ICCs. `choosing-an-icc.Rmd`'s "fifth choice" cites this entry, corrected in M5
  Slice 2 from an earlier wrong-paper/year reference.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2025). How to estimate
  intraclass correlation coefficients for interrater reliability from planned
  incomplete data. *Multivariate Behavioral Research, 60*(5), 1042–1061.
  doi:10.1080/00273171.2025.2507745. (Simulation comparison concluding MLE of
  random-effects models with **Monte-Carlo CIs** is preferred — the engine + CI
  basis for ADR-002/ADR-003.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979.
- Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022). Accuracy of absolute error
  estimates within a G-theory SEM framework. Paper presented at the meeting of the
  National Council on Measurement in Education (NCME), April 9, 2022. (Conference
  paper — validates the SEM indicator-mean absolute-error method against GENOVA /
  `gtheory` / SAS / SPSS: G-coefs agree to ≤ .001, D-coefs to ≤ .005 across 24 real
  scales. External corroboration for O-SEM, M7.)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of
  connectedness in an N-way cross classification. *Technometrics, 6*(3), 319–324.
