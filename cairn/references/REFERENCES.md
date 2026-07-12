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
  6. **O-RepDS — projection off a within-cell replicate fit asserted (M22, ADR-032)** —
     `d_study()` on a replicate fit projects `m` with per-component divisors (rater and
     interaction ÷ `m`, pure error ÷ `m·n_o`), one curve per occasion setting (spec
     `M17-within-cell-replicates.md` §7): at `m = k_eff` each level/occasion curve
     equals the fitted `ICC(*,k)` (<1e-4), the curve matches an independent `lme4`
     replicate fit (cross-engine), consistency projection is Spearman–Brown, a seeded
     sim recovers a projected value not run with MC coverage, and the curve is
     monotone/[0,1] with occasion-averaged ≥ single-occasion. Single-level (Slice 1) +
     multilevel crossed D1 / nested D2 (Slice 2, subject across occasions, cluster
     single-occasion). Occasion projection and ragged-replicate projection deferred.
  7. **O-OccDS — occasion-count projection off a within-cell replicate fit asserted
     (M39, ADR-049)** — `d_study(n_o = )` projects the occasion count, holding raters at
     k_eff; only pure error σ²_e divides by `m·n_o` (spec `M4.5-d-study.md` §9). At
     `n_o ∈ {1, observed}` each curve equals the fitted single-/average-occasion
     `ICC(*,k)` (<1e-4, both types, single- & multi-level); the curve equals the
     dependability form from the components (a generalized Spearman–Brown); it is
     monotone/[0,1] and bounded above by the **finite ceiling**
     `σ²_s/(σ²_s+(σ²_r+σ²_sr)/m)` (< 1); **fixed absolute agreement projects** on this
     axis (the rater axis's abort is axis-specific); the curve matches an independent
     `lme4` replicate fit (cross-engine); a seeded sim recovers a projected `n_o` not
     run with MC coverage. Multilevel: subject rises, cluster is occasion-invariant
     (flat); nested D2 subject-level only. **Ragged**-replicate occasion projection
     stays deferred (🟣 effective-`n_o` divisor).
- **Decision:** projection is a change of the averaging divisor (ADR-010; estimand
  spec `M4.5-d-study.md`); fixed-rater absolute agreement is refused as ill-posed **on
  the rater axis**, but projects on the occasion axis (occasions are a random facet;
  ADR-049 §9.3).
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
  "average"` on ragged data aborts loudly. Ragged×fixed, ragged×multilevel, and Design 3
  replicate-split are deferred/⚫ (COVERAGE §②). `d_study()` off a replicate fit **now
  ships** (M22, ADR-032; Oracle O-RepDS under O-DS above).
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

### Oracle O-Bayes — Bayesian engine + `ci_method = "posterior"` (M23, ADR-033)
- **Status:** Slice 1 **shipped** (wiring); **O-Bayes coverage oracle is M23 Slice 2**
  (in progress). A CI method's oracle is **coverage** (#1; M16 precedent), and the
  source is a **simulation study**, so there is no single worked-example point to
  reproduce — the oracle is that our brms + half-*t*(4,0,1) + MAP/percentile pipeline
  reproduces ten Hove et al. (2020)'s reported simulation findings.
- **Source & DGP (ten Hove, Jorgensen & van der Ark 2020, §4; OSF `shkqm`).** Model
  `Y_sr = μ + μ_s + μ_r + μ_sr` (Eq. 1; interaction+error confounded into σ²_sr).
  Data generation (§4.1.1): **N = 30** subjects, **μ = 0**, **σ²_s = σ²_sr = 0.5**,
  **σ²_r ∈ {.01, .04}**, **k ∈ {2, 3, 5}**. Evaluated coefficient **ICC(A,1)** (and
  ICC(A,k), which resembles it) — population ICC(A,1) = σ²_s/(σ²_s+σ²_r+σ²_sr) =
  **0.4950** (σ²_r=.01) / **0.4808** (σ²_r=.04). Prior (half-*t* condition, §4.1.2):
  **half-*t*(4, 0, 1)** on every random-effect SD (σ_s, σ_r, σ_sr) — our engine's
  exact prior. MCMC (§4.1.3): 3 chains × 1000 iter (500 warmup → 1500 draws), R̂ <
  1.10, N_eff > 100, **1000 replications** per cell.
- **Reproducible findings (the pins; §4.2, Figs 1–4).** (1) **Convergence 100%** at
  the half-*t* DGP across all k. (2) **MAP is unbiased for σ_r at k > 2** (relative
  bias |θ̄−θ|/θ within their ≤.05 minor-bias band) while the **EAP severely
  overestimates σ_r** (large positive relative bias, decreasing in k but always ≫ the
  MAP). (3) For **ICC(A,1)**, MAP is **unbiased at k = 5** (≤.05) and biased low
  (~−0.3 relative) at k = 2; MAP and EAP of ICC(A,1) are comparable. (4) **Percentile
  95% BCI coverage is ~nominal (≈95–97%)** at k > 2 (HPDI is too wide for σ_r — we use
  percentile, ADR-033). **Guardrail (#4):** our MAP estimator (reflected-KDE) is
  *independent* of their `modeest` tool, so convergence on their numbers is a stronger
  cross-implementation check than re-running their code; the mode bandwidth/boundary
  spec is fixed a-priori and validated, not tuned to these targets.
- **Reproduced (n_rep = 250/cell, σ²_r = .01, seed 20200; committed
  `tests/testthat/fixtures/bayesian-oracle.rds`).** k = 5: convergence .992, MAP
  ICC(A,1) rel bias **−.040** (unbiased), coverage **.948** (nominal), EAP σ_r rel bias
  **+.741** vs MAP σ_r **−.147**. k = 2: convergence .924, MAP ICC(A,1) rel bias
  **−.243** (biased low), coverage .912 (undercovers), EAP σ_r rel bias **+3.60** vs
  MAP σ_r −.318. The four findings replicate. **Two reported divergences (#4/#18, not
  tuned):** (a) convergence is high but not their 100% — they adaptively *doubled*
  warmup until R̂ < 1.10, we use a fixed budget, so a minority of the near-boundary
  k = 2 reps fall short; (b) our reflected-KDE σ_r MAP is modestly *negative*-biased
  where their `modeest` MAP was ~unbiased — an independent-estimator difference at a
  tiny near-boundary σ_r that barely moves the ICC (σ²_r is a small denominator term).
  So the σ_r pin is the robust **EAP-overestimates-far-more-than-MAP** contrast, not our
  MAP's absolute bias.
- **Provenance:** `data-raw/oracle-bayesian.R` (Slice 2) — seeded reproduction of the
  DGP applying the shipped reduction (`brms_component_draws` / `posterior_summary` /
  `posterior_mode` / `brms_convergence`) to `update()`-refit brms fits (the model is
  compiled once, then the same half-*t* prior + MAP/percentile recipe runs per rep);
  **commits** the per-cell reference statistics (#4) and `stopifnot`-checks them against
  the published findings above. O-Bayes tests read the committed reference (fast, no
  fitting); a single tiny live brms fit exercises the wiring (`skip_on_cran` +
  `skip_if_not_installed("brms")`).

### Oracle O-Bayes-Fixed — Bayesian fixed-rater two-way (M26 Slice 2, ADR-036)

- **Role:** the fixed-rater sibling of O-Bayes. A CI method's oracle is **coverage** (#1); the
  shipped brms recipe on the fixed-rater fit `score ~ 1 + rater + (1 | subject)` — with θ²_r
  (McGraw & Wong Case-3A finite-population variance of the k fixed rater means) read **raw** per
  posterior draw — covers the fixed-population ICC(A,1), and via the live fit reduces to the
  Shrout & Fleiss anchors.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) — the prior/MAP/percentile recipe;
  McGraw & Wong (1996) Case 3A — the fixed-rater finite-population θ²_r (reused
  `M3-incomplete-designs.md §6` / `M10-fixed-multilevel.md §2`, no new spec).
- **Oracle-first resolution (ADR-036, #18).** Two REML/FIML facts do **not** transfer verbatim to a
  Bayesian fit, resolved empirically at build: (a) **no bias correction** — `theta2r_fixed()`
  subtracts the sampling variance of a *point* estimate, but the posterior already integrates that
  uncertainty, so the raw per-draw finite-population variance is the proper posterior draw of θ²_r;
  confirmed negligible (the correction moves MAP ICC(A,1) by ~0.002). (b) The balanced
  `fixed ≡ random` identity (exact under REML in M10 / FIML in M21) holds only **approximately** for
  brms — flat prior on the rater fixed effects vs half-*t*(4,0,1) on σ_r — so the oracle is
  **containment** (glmmTMB fixed inside the brms credible interval), not pointwise equality, and the
  MAP tracks glmmTMB within the standard MAP-below-plug-in skew (ADR-033).
- **DGP:** `Y_sr = μ_s + μ_rj + e`, k = 4 **fixed** rater means `c(−0.6,−0.2,0.2,0.6)`
  (θ²_r = 0.2667), N = 30, σ²_s = σ²_res = 0.5 → population fixed-rater **ICC(A,1) = 0.3947**.
- **Committed reference (`tests/testthat/fixtures/bayesian-fixed-oracle.rds`; n_rep = 200,
  seed 20261):** convergence **1.00**, MAP ICC(A,1) rel-bias **−.050** (mild low skew), coverage
  of the fixed-population ICC(A,1) **.935** (nominal).
- **Pins (qualitative, #4/#18):** (1) convergence ≥ .90; (2) percentile coverage of the
  fixed-population ICC(A,1) ~nominal (≥ .88, ≤ .99); (3) the MAP is biased **low** (the
  right-skewed-ICC-draws mode sits below the population plug-in) — characterized, not asserted
  unbiased.
- **Provenance:** `data-raw/oracle-bayesian-fixed.R` (companion to `oracle-bayesian.R`) — the same
  compile-once/`update()`-per-rep recipe, **replicating** `fit_brms_fixed()`'s raw-θ²_r reduction
  (b_rater draws → finite-population variance → the `rater` `draws` row → `posterior_summary`);
  **commits** the reference and `stopifnot`-checks it. The `test-icc-brms.R` **O-Bayes-Fixed** test
  reads the committed reference (fast, no fitting, runs on CI); **O-Bayes-Fixed-agree** is the live
  fit on the Shrout & Fleiss data — with raters fixed and balanced data, glmmTMB agreement = the
  two-way random **SF ICC2** (0.290 / 0.620, the M10 identity) and consistency = **SF ICC3**
  (0.715 / 0.909), each inside the brms credible interval (`skip_on_ci`).

### Oracle O-Bayes-ML — Bayesian crossed multilevel (M24, ADR-034)

- **Role:** the multilevel companion to O-Bayes. A CI method's oracle is **coverage**
  (#1); the source is a simulation study, so the oracle is that the shipped brms +
  half-*t*(4, 0, 1) recipe, extended to the M5 **five-component crossed (Design 1)** fit,
  reproduces the source's bias/coverage/convergence behaviour at the **subject** level and
  honestly exposes the **few-cluster** caveat at the cluster level.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) — the prior/MAP/percentile recipe;
  and (2022, *Psychological Methods* 27(4):650–666) — the crossed subject/cluster estimands
  (Eqs. 12–13, Table 3) and the multilevel simulation regime (N_c ∈ {20, 40}, N_s/cluster,
  k; σ²_{s:c}=1, σ²_{cr}=0.16, σ²_res=0.5, σ²_c/σ²_r varied), transcribed in
  `estimand-specs/M5-multilevel.md` §5.
- **Committed reference (`tests/testthat/fixtures/bayesian-ml-oracle.rds`; n_rep = 100,
  seed 20240, DGP N_c = 20, N_s/cluster = 5, σ²_c = 0.5, k ∈ {5, 2}):** k = 5 **subject**
  conv .97, MAP rel-bias −.015, coverage .94; k = 2 subject conv .94, MAP rel-bias −.037,
  coverage .96; k = 5 **cluster** MAP rel-bias −.159, coverage .93; k = 2 cluster MAP
  rel-bias −.249, coverage .93.
- **Pins (qualitative, #4/#18):** (1) convergence ≥ .90 at all cells; (2) subject-level MAP
  ~unbiased (|rel-bias| < .10) + nominal coverage at k = 5 (ten Hove 2022's MCMC ≈ MLE);
  (3) subject-level MAP biased more low at k = 2, coverage ~nominal at both k (100 subjects
  → well-powered even at k = 2); (4) **cluster-level few-cluster caveat** — at N_c = 20 the
  single-rater cluster MAP is biased low relative to the subject level (a diffuse
  near-boundary σ²_c posterior → the mode of the cluster ICC draws sits below the
  population, while the wide percentile interval still covers ~nominally). The MAP-vs-plug-in
  divergence is a genuine property (MAP = mode of the ICC draws ≠ `icc_point()` of the modal
  components, ADR-033), reported not tuned away.
- **Provenance:** `data-raw/oracle-bayesian-multilevel.R` (companion to `oracle-bayesian.R`,
  leaving the M23 fixture untouched) — the same compile-once/`update()`-per-rep recipe on the
  five-component fit, checkpointed per cell; **commits** the per-(cell × level) reference and
  `stopifnot`-checks it. The `test-icc-brms.R` **O-Bayes-ML-coverage** test reads the committed
  reference (fast, no fitting, runs on CI); **O-Bayes-ML-reduction** pins that the subject-level
  composition equals the two-way one deterministically (no fit); **O-Bayes-ML-agree** is the
  live crossed-multilevel fit (MAP ≈ glmmTMB REML at the subject level; `skip_on_ci`).

### Oracle O-Bayes-NML — Bayesian nested multilevel Designs 2/3 (M25, ADR-035)

- **Role:** the nested companion to O-Bayes-ML. A CI method's oracle is **coverage** (#1);
  the source is a simulation study, so the oracle is that the shipped brms + half-*t*(4, 0, 1)
  recipe, extended to the M8 **nested** fits — Design 2 (raters nested in clusters,
  four-component) and Design 3 (raters nested in subjects, three-component / multilevel
  one-way) — reproduces the source's bias/coverage/convergence behaviour at the **subject**
  level. There is **no cluster-level cell** (nested designs define no cluster-level IRR —
  ten Hove 2022 p. 6), so the M24 few-cluster caveat is not exposed here: σ²_c is a fitted
  nuisance.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) — the prior/MAP/percentile recipe;
  and (2022, *Psychological Methods* 27(4):650–666) — the nested Design 2/3 subject-level
  estimands (Eqs. 8–11, Table 3 middle/right) and the multilevel simulation regime,
  transcribed in `estimand-specs/M8-nested-multilevel.md` §5.
- **Committed reference (`tests/testthat/fixtures/bayesian-nested-oracle.rds`; n_rep = 80,
  seed 20250, DGP N_c = 20, N_s/cluster = 5, σ²_c = 0.5, σ²_{s:c} = 1, σ²_r = 0.16,
  σ²_res = 0.5; pop ICC .6024):** Design 2 k = 5 conv 1.00, MAP rel-bias −.010, coverage
  .975; Design 3 k = 5 conv 1.00, MAP rel-bias +.002, coverage .950; Design 3 k = 2 conv
  1.00, MAP rel-bias +.006, coverage .963.
- **Pins (qualitative, #4/#18):** (1) convergence ≥ .90 at all cells; (2) Design 2 subject
  level (the two-way analog) MAP ~unbiased (|rel-bias| < .10) + nominal coverage at k = 5;
  (3) Design 3 subject level (the multilevel one-way) MAP ~unbiased + nominal coverage at
  **both** k = 5 and k = 2. **The honest finding (#18):** unlike the crossed **cluster**
  level (M24, MAP biased low at few clusters), the nested **subject** level is well-powered
  (100 subjects) and stays ~unbiased even at k = 2 (both |rel-bias| < .01) — there is no
  boundary-prone cluster estimand exposed (nested designs define no cluster ICC), so the
  M24-style "k = 2 more biased low" ordering is deliberately **not** asserted here. No
  cluster-level pin (undefined for nested).
- **Provenance:** `data-raw/oracle-bayesian-nested.R` (companion to
  `oracle-bayesian-multilevel.R`, leaving the M23/M24 fixtures untouched) — the same
  compile-once/`update()`-per-rep recipe on the nested fits, checkpointed per cell;
  **commits** the per-(design × k) reference and `stopifnot`-checks it. The `test-icc-brms.R`
  **O-Bayes-NML-coverage** test reads the committed reference (fast, no fitting, runs on CI);
  **O-Bayes-NML-reduction** pins Design 3 → flat M6 one-way as σ²_c → 0 on REML fits;
  **O-Bayes-NML-agree** is the live nested fit (MAP ≈ glmmTMB/lme4 REML at the subject level;
  `skip_on_ci`).

### Oracle O-Bayes-OW — Bayesian one-way random (M26 Slice 1, ADR-036)

- **Role:** the one-way (single-level) sibling of O-Bayes. A CI method's oracle is
  **coverage** (#1); the shipped brms + half-*t*(4, 0, 1) recipe on the M6 **one-way**
  component structure (subject + confounded residual, **no rater term**) reproduces the
  bias/coverage/convergence behaviour of a seeded one-way DGP, and — via the live fit —
  reduces to the Shrout & Fleiss anchor.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) — the prior/MAP/percentile recipe;
  Shrout & Fleiss (1979) / McGraw & Wong (1996) Case 1 — the estimand ICC(1) =
  σ²_s/(σ²_s+σ²_res), ICC(1,k) = σ²_s/(σ²_s+σ²_res/k) (reused `estimand-specs/M6-oneway.md`,
  no new spec).
- **DGP:** `Y_sr = μ + μ_s + e_sr`, N = 30 subjects, σ²_s = σ²_res = 0.5 (population
  **ICC(1) = 0.5**, an interior ratio), k ∈ {2, 5} ratings/subject; half-*t*(4, 0, 1) on σ_s.
- **Committed reference (`tests/testthat/fixtures/bayesian-oneway-oracle.rds`; n_rep = 150,
  seed 20260):** k = 5 conv **1.00**, MAP ICC(1) rel-bias **−.008**, coverage **.94**,
  ICC(1,k) rel-bias **+.002**, coverage **.94**; k = 2 conv **1.00**, MAP ICC(1) rel-bias
  **−.118**, coverage **.95**, ICC(1,k) rel-bias **−.089**, coverage **.95**. (Parallel-MCMC
  cross-run variation of a few tenths of a percent is ordinary noise and leaves every pin
  intact — as the sibling `oracle-bayesian.R` notes.)
- **Pins (qualitative, #4/#18):** (1) convergence ≥ .90 at all cells; (2) MAP of ICC(1) and
  ICC(1,k) ~unbiased (|rel-bias| < .10) at k = 5; (3) percentile coverage ~nominal at k = 5,
  both units. (4) **The honest finding (#18):** the a-priori hypothesis — that the one-way
  ICC, lacking a near-boundary rater variance, would be **spared** the two-way k = 2 bias —
  was **falsified** by the seeded run: the one-way MAP of ICC(1) is biased **low at k = 2**
  (−.128) and more so than at k = 5, the **same** skewed small-sample variance-ratio
  mechanism as the two-way ICC(A,1) (M23). Coverage stays ~nominal (the point moves, the
  percentile interval still brackets). Consequently the `icc()` **k = 2 caveat note fires for
  the one-way path too** (not gated off, as first drafted).
- **Provenance:** `data-raw/oracle-bayesian-oneway.R` (companion to `oracle-bayesian.R`,
  leaving the M23–M25 fixtures untouched) — the same compile-once/`update()`-per-rep recipe on
  the two-component one-way fit; **commits** the per-k reference and `stopifnot`-checks it. The
  `test-icc-brms.R` **O-Bayes-OW** test reads the committed reference (fast, no fitting, runs
  on CI); **O-Bayes-OW-agree** is the live one-way fit on the Shrout & Fleiss data — glmmTMB
  one-way REML = the published **ICC(1) = 0.166 / ICC(1,k) = 0.443**, inside the brms credible
  interval, lme4 the second REML oracle (`skip_on_ci`).

---

### Oracle O-Bayes-FML — Bayesian crossed fixed-rater multilevel (M27 Slice 1, ADR-037)

- **Role:** the crossed (Design 1) fixed-rater sibling of O-Bayes-ML. A CI method's oracle is
  **coverage** (#1). The shipped brms recipe on the M10 five-component crossed fit with a **fixed**
  `rater` effect (θ²_r read per posterior draw, **moment-corrected** — see below) reproduces the
  coverage/containment/convergence behaviour of a seeded crossed fixed DGP. The **primary** pin is
  **containment** — the glmmTMB M10 REML point inside the brms credible interval — *not* equality,
  since the balanced `fixed ≡ random` identity holds only approximately under the prior (#18).
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) prior/recipe + (2022) Design-1 estimands;
  McGraw & Wong (1996) Case 3A θ²_r (reused `estimand-specs/M10-fixed-multilevel.md §2`, no new spec).
- **DGP:** crossed Design 1, N_c = 20 clusters × 5 subjects, k = 4 **fixed** rater means
  (θ²_r = 0.2667), σ²_{s:c} = 1, σ²_res = 0.5 → pop subject **ICC(A,1) = 0.5660**; half-*t*(4,0,1)
  on the random-effect SDs.
- **Committed reference (`tests/testthat/fixtures/bayesian-multilevel-fixed-oracle.rds`; n_rep = 100,
  seed 20270):** converged **.98**, **containment 1.00**, coverage **.95**, MAP rel-bias **≈ +.01**
  (≈ unbiased; crossed b ≈ 0, so the 2b moment correction is ~a no-op and roughly cancels the small
  mode-below-mean skew; regenerated after the ADR-037 helper unification).
- **Pins (#4/#18):** convergence ≥ .90; containment ≥ .90; coverage of the fixed-population ICC(A,1)
  ~nominal; MAP ~unbiased (|rel-bias| < .05, either sign), characterized not asserted to a direction.
- **Provenance:** `data-raw/oracle-bayesian-multilevel-fixed.R`; `test-icc-brms.R` **O-Bayes-FML**
  (committed reference, on CI) + **O-Bayes-FML-agree** (live crossed fixed fit, glmmTMB inside the CI
  for agreement + consistency, lme4 the second REML oracle; `skip_on_ci`).

### Oracle O-Bayes-FNML — Bayesian nested fixed-rater multilevel (M27 Slice 2, ADR-037)

- **Role:** the nested (Design 2) fixed-rater sibling of O-Bayes-NML. The rater slot carries
  θ²_{r:c} = the within-cluster finite-population rater variance averaged over clusters. A CI
  method's oracle is **coverage** (#1); the primary pin is **containment** of the glmmTMB M19 REML
  point — and here containment is the *only* identity available, since for nested designs fixed ≢
  random even balanced (per-cluster finite population; the M19/ADR-029 catch).
- **THE 2b MOMENT CORRECTION (ADR-037 amendment, gated Fable review #19):** the naïve **raw**
  per-draw push-forward of θ²_{r:c} **undercovers** the fixed-population value (interior coverage
  **.86**, MAP **−.106**, seed 20271) and its coverage → 0 as clusters accrue (an incidental-parameters
  pathology from the flat prior on the C_n·k cell means). The shipped estimator subtracts **2b** per
  draw (`b = tr(C·Σ_post)/(k−1) = σ²_res/n_s`; **two** equal inflations — push-forward + plug-in — the
  frequentist point removes one because its point is separate/unbiased, the Bayesian MAP is read off
  the draws so needs both) and floors only the per-draw cluster **AVERAGE** (per-cluster flooring →
  **zero** coverage at θ²=0, #3). Derived not tuned (#4): a Stan-free conjugate check hits θ+2b, θ+b,
  θ to ≲.003, and the brms raw→1b step is exactly one `b`.
- **Sources:** ten Hove et al. (2020) prior/recipe + (2022) Design-2 estimands; McGraw & Wong (1996)
  Case 3A per cluster (the M19 nested θ²_{r:c}, no new spec).
- **DGP:** nested Design 2, N_c = 20 × 5 subjects, k = 4 fixed per-cluster rater means; **interior**
  cell θ²_{r:c} = 0.6616 (pop ICC(A,1) = 0.4626) and **boundary** cell θ²_{r:c} = 0 (pop 0.6667).
- **Committed reference (`tests/testthat/fixtures/bayesian-nested-fixed-oracle.rds`; seed 20271):**
  **interior** (n_rep 100) converged **1.00**, containment **1.00**, coverage **.95**, MAP rel-bias
  **−.017**; **boundary** (n_rep 80) coverage **1.00**, containment **1.00** — the average-floor keeps
  the boundary at/above nominal (the pin per-cluster flooring would fail). Matches Fable's derived
  predictions (≈.95 / ≈−.02) with no free parameter.
- **Pins (#4/#18):** convergence ≥ .90 both cells; interior containment ≥ .90 and coverage ~nominal;
  interior MAP only mildly low (> −.06, the skew); **boundary coverage ≥ .90** (the #3 boundary-aware
  pin). Corollary (Fable §6, out of scope): the frequentist nested-fixed **MC interval**
  (`theta2r_nested_draws()`) is 1b-corrected + per-cluster-floored and likely shares an attenuated
  displacement — spun off as its own task/ADR (the point estimator is unaffected).
- **Provenance:** `data-raw/oracle-bayesian-nested-fixed.R` (interior + boundary cells);
  `test-icc-brms.R` **O-Bayes-FNML** (committed reference, on CI) + **O-Bayes-FNML-agree** (live nested
  fixed fit, glmmTMB inside the CI for agreement + consistency, lme4 the second REML oracle; `skip_on_ci`).

### Oracle O-NFI — frequentist nested-fixed MC-interval coverage (M28, ADR-038)

- **Role:** the **frequentist** sibling of O-Bayes-FNML — coverage of the shipped nested (Design 2)
  fixed-rater θ²_{r:c} **Monte-Carlo interval** (`theta2r_nested_draws()`, R/engine-glmmtmb.R). A CI
  method's oracle is **coverage** (#1). This is the ADR-037 **corollary** (spun off from the M27 Fable
  review) made concrete: the interval was never coverage-pinned. The **point** estimator is separate,
  bias-corrected, and pinned by O-FNML — out of scope here.
- **DGP:** nested Design 2, raters FIXED (per-cluster centered rater means held fixed across
  replications; only subjects + residuals resampled — coverage is of the fixed value). σ²_{s:c} = 1,
  σ²_res = 0.5; the **Fable Q6 grid** k ∈ {2,4} × n_s ∈ {3,5,20} × C_n ∈ {5,20,80} × θ²_{r:c} ∈
  {0 (boundary), σ²_res/n_s, 0.66} — 54 cells × n_rep 100.
- **The finding + fix (M28 Slice 1 → 2, gated Fable review #19,
  `data-raw/reviews/fable-review-m28-nested-fixed-interval-{brief,response}.md`).** Slice 1 pinned the
  **shipped** (1b, per-cluster-floor) interval **UNDERCOVERING**, worsening with cluster count (an
  incidental-parameters pathology — the per-cluster 1b correction + **per-cluster floor** displace each
  cluster's contribution, and averaging over many clusters narrows the interval faster than it removes the
  displacement): boundary (θ²=0) coverage **C_n=5/20/80 = .95/.86/.57**, worst cell (C_n=80, n_s=3)
  **.36–.38**; interior means **.95/.92/.80** — the M27 Bayesian finding confirmed on the frequentist path.
  Slice 2 replaced it with the shared `theta2r_moment_draws()` (subtract **2b**, floor the per-draw
  AVERAGE) and moved the POINT floor to the average (Fable §3, fixing point-outside-its-own-CI at the
  boundary).
- **Committed reference (`tests/testthat/fixtures/nested-fixed-interval-oracle.rds`; seeds 203800 + i·1000)
  — POST-FIX:** interior coverage **mean .962** (range .91–.99), boundary **mean .958** (range .94–.99);
  the C_n collapse is gone (boundary **.957/.965/.953** across C_n=5/20/80), worst pre-fix cell
  **.37 → .95–.98**, every cell ≥ .91. Confirms Fable's derived prediction (boundary conservative-nominal,
  interior mean ≈ .95) with no free parameter (#4).
- **Pins (#4/#18):** min cell coverage > .87, overall mean > .93; boundary coverage ≥ .90 at every C_n
  (the regression guard — no incidental-parameters collapse); worst cell (C_n=80, n_s=3, θ²=0) > .88; a
  live point-in-own-CI containment check > .85 at the boundary. Asserted in `test-icc-fixed-multilevel.R`
  **O-NFI** + **O-NFI/point**.
- **Provenance:** `data-raw/oracle-nested-fixed-interval.R` (standalone, seeded; header records the
  before/after; writes the fixture). Fable's independent conjugate-normal check:
  `data-raw/reviews/fable-check-nfi.R`.

### Oracle O-IFNML — INCOMPLETE/ragged fixed-nested (Design 2) single-rater (M36, ADR-046)

- **Role:** correctness of the **incomplete/ragged** fixed-rater nested Design-2 subject-level
  single-rater ICC_s(A,1) — the ragged generalization of the balanced M19 fixed-nested θ²_{r:c}
  (`theta2r_fixed_nested()`) to unequal per-cluster rater counts k_c, with the 2b moment-corrected MC
  interval (`theta2r_nested_draws()`) per cluster. The **point estimand is NON-CIRCULAR**: a
  finite-population θ²_{r:c} is a deterministic function of the specific fixed rater means, so recovering
  a **known** value from ragged data is a genuine independent oracle — cross-engine (glmmTMB↔lme4)
  validates only the raw fit, **not** the authored ragged correction (both engines run the same formula),
  so seeded recovery is the **load-bearing** oracle (#1/#18).
- **DGP:** ragged nested Design 2, raters FIXED (per-cluster centered rater means held fixed across
  replications so θ²_{r:c} is exact; subjects, residuals, and the missing-cell pattern resampled per rep;
  subjects with < 2 remaining ratings dropped). σ²_{s:c} = 1, σ²_res = 0.5. Grid {equal-k (k_c=4),
  unequal-k (k_c ∈ {2..5})} × {boundary θ²=0, interior θ²=0.5} at n_s=8, **plus** a C_n=80 boundary
  cluster-count sentinel and a n_s=4 interior certification cell (Fable RR §3/§5), **n_rep 240** (the ≥ .88
  pin false-alarms ~0.7%/cell at n_rep 80 — [[ragged-coverage-nrep-240]]). Single-rater needs no averaging
  divisor, so its population value vsc/(vsc+θ²+vres) is fixed and coverage is clean.
- **Committed reference (`tests/testthat/fixtures/incomplete-fixed-nested-oracle.rds`; seeds 360000 + i·1000):**
  6 cells. The four n_s=8 cells: coverage **interior .967/.967, boundary θ²=0 .942/.942**, |bias| ≤ .018.
  **Plus two Fable-review sentinels (RR §3/§5, ADR-046 Amendment 1):** a **C_n=80 boundary** cluster-count
  sentinel (coverage **.967** — no incidental-parameters decay, the M28 *post*-fix signature; |bias| shrinks
  to −.005 as clusters accrue) and a **n_s=4 interior** low-information cell (coverage .979, 1b |bias| .015 —
  so the |bias| < .03 pin actively rejects a 2b over-correction, which sits at +.037 there). All ≥ .90,
  boundary-aware (#3); 0 fit failures. The 2b-under-imbalance risk resolved **nominal**; a **post-hoc gated
  Fable review** (#19, maintainer-requested) subsequently **confirmed the construction is sound** — the M28
  inflation identities are Gaussian quadratic-form facts (not balanced-data facts), REML closes the growing-β̂
  channel, and the cluster-count sweep is flat to C_n=80 (`fable-review-m36-*`).
- **Reductions (deterministic, committed as an attribute + re-checked live):** ragged **single-cluster**
  fixed-nested ≡ flat M3 fixed for **both** single and average (|diff| ~1e-16 — a single-cluster
  nested-fixed design IS a flat two-way fixed design; ties θ²_{r:c} to the sourced McGraw–Wong Case 3A AND
  pins the **average** ICC(A,k_eff) divisor, which is the per-subject harmonic `k_eff` — the M19
  random-nested divisor, **not** the open per-cluster `ICC(c,k)` divisor of M9 §9); cross-engine ragged
  glmmTMB↔lme4 |ΔICC(A,1)| < 1e-3 (M15 ragged tolerance). On balanced/equal-k data the generalized helper
  is **bit-identical** to the shipped M19 helper (|diff| = 0), so the O-FNML pins are unmoved.
- **Pins (#4/#18):** min cell coverage > .90, overall mean > .93, boundary min > .90; max |bias| < .03;
  reductions single/average < 1e-8, cross-engine < 1e-3. Asserted in `test-icc-fixed-multilevel.R`
  **O-IFNML** + **O-IFNML/reduction**.
- **Provenance:** `data-raw/oracle-incomplete-fixed-nested.R` (standalone, seeded; writes the fixture),
  seeded from the feasibility spike `data-raw/reviews/m36-feasibility-spike-{point,coverage}.R`.

### Oracle O-FCL — fixed-rater CLUSTER-level ICC, crossed Design 1, balanced (M37, ADR-047)

- **Role:** correctness of the **balanced/complete crossed Design-1 fixed-rater CLUSTER-level** ICC — signal
  σ²_c, agreement error {θ²_r, σ²_cr}, consistency {σ²_cr}, divisor k (M5 §3b map with θ²_r in the rater
  slot), read off the shipped M10 fixed fit (`fit_glmmtmb_multilevel_fixed()`; the estimand map keys the
  error set on `level`, not `raters`). No new fit, no new estimand concept. The recovery is **NON-CIRCULAR**:
  θ²_r is a deterministic function of the k fixed rater means, so recovering the known cluster-level
  population value σ²_c/(σ²_c + θ²_r + σ²_cr) is a genuine independent oracle.
- **The open question the feasibility spike settled (M10 §7):** at the subject level σ²_cr is not in the
  error set, so M10's balanced fixed≡random reduction was clean; at the cluster level σ²_cr **is** the error.
  The spike (`data-raw/reviews/m37-feasibility-spike-{point,coverage,boundary-parity}.R`) showed fixing the
  rater main effect does **not** bias the `(1|cluster:rater)` interaction (`s2cr_fixed = s2cr_random`,
  |d| ~1e-7), so the **random σ²_cr is the correct fixed-rater cluster-level error** (no finite-population
  correction) and the coefficient reduces to the M5 random cluster-level ICC **exactly** in all regimes
  (|Δ| ~1e-6). **Outcome A → no Fable review** (the ADR-047 pre-authorization did not fire).
- **DGP:** balanced crossed Design 1, k=4 fixed rater means ρ = (−0.8, −0.2, 0.3, 0.7) held fixed across
  reps (θ²_r = 0.42 exact), σ²_{s:c} = 0.8, σ²_cr = 0.25, σ²_res = 1.0, n_s = 6; clusters/subjects/
  interaction/residual resampled per rep. n_rep 240, mc_samples 3000 ([[ragged-coverage-nrep-240]],
  [[coverage-oracle-cluster-count-axis]]).
- **Committed reference (`tests/testthat/fixtures/fixed-cluster-level-oracle.rds`; seeds 370100/370200/370300):**
  three cells. **Interior** recovery of the known cluster-level ICC(A,1): coverage **.975 (C_n=20) / .925
  (C_n=80)**, |bias| ≤ **.008** — unbiased, boundary-aware. **Boundary σ²_c = 0** (pop ICC = 0): coverage
  **.000 for BOTH fixed AND M5-random** (parity |Δ| = **.000**). The cluster-level ICC is a ratio floored at
  0 in its numerator with **no moment correction for the signal variance** (unlike the rater θ² boundary of
  M28), so it under-covers at the exact boundary — but **identically for fixed and random**, a pre-existing
  shared M5/M9/M37 property, **not an M37 defect** (#18). Improving cluster-signal-zero coverage is a
  cross-cutting candidate follow-up (`M37-fixed-cluster-level.md` §7). n_fit at the boundary is reduced
  (~113/240) by singular fits at the exact variance boundary.
- **Reductions (committed as an attribute + re-checked live):** balanced fixed cluster-level ≡ M5 random
  cluster-level (point) |Δ| = **2.1e-6**; glmmTMB↔lme4 cross-engine |Δ| = **1.7e-5** (both < 1e-4). The MC
  *interval* differs between fixed and random by construction (β-sampling vs σ²_r-sampling — the documented
  M10 agreement-interval behavior), so the reduction pin is on the **point** (#18).
- **Pins (#4/#18):** interior min coverage > .90, max |bias| < .05; boundary parity |fixed − random| < .06;
  reduction < 1e-4, cross-engine < 1e-4. Asserted in `test-icc-fixed-multilevel.R` **O-FCL/reduction**,
  **O-FCL/lme4**, **O-FCL/recovery**.
- **Provenance:** `data-raw/oracle-fixed-cluster-level.R` (standalone, seeded; writes the fixture), seeded
  from the feasibility spike `data-raw/reviews/m37-feasibility-spike-*.R`.

### Oracle O-Bayes-Conflated — Bayesian conflated diagnostic (M29 Slice 1, ADR-039)

- **Role:** the Bayesian sibling of the frequentist conflated oracle (M17 Slice 1). The conflated
  single-level ICC (ten Hove et al. 2022, **Eq. 14**) is the biased ignore-the-clustering coefficient
  composed off the crossed Design-1 five-component posterior draws — signal = cluster + subject, error =
  rater + cluster_rater + residual. It is a **variance-ratio push-forward** (like every random-rater
  Bayesian coefficient), so **none** of the θ² 2b moment correction (O-Bayes-FNML/O-NFI) applies —
  `posterior_summary()` → `icc_point()` composes it exactly as the subject/cluster levels.
- **Oracles (≥2 independent, #1):** **O-Eq14** (wiring, no Stan) — `posterior_summary()` reproduces the
  closed-form Eq. 14 per draw to floating-point, independent of the estimator's own ICC path;
  **O-population** (coverage) — the credible interval covers the known Eq. 14 value ~nominally (the point
  may be biased by the few-cluster σ²_c, so coverage is the honest pin, M17 §5); **O-glmmTMB containment**
  — the frequentist glmmTMB conflated point (the same Eq. 14, differing only by the prior) falls inside
  the brms credible interval (the M26 containment posture); **distinctness** — the conflated MAP sits
  visibly above the subject level (Eq. 14 folds the between-cluster variance into the signal).
- **Sources:** ten Hove et al. (2020) prior/recipe + (2022) Eq. 14 (the conflated estimand); estimand-spec
  `M17-conflated-icc.md` (no new spec — M29 gives the shipped estimand the brms engine).
- **DGP:** crossed Design 1, N_c = 20 × 5 subjects, k = 5, **large** σ²_c = 1.5 (so the conflated clearly
  overstates); pop conflated = (σ²_c + σ²_{s:c})/(σ²_c + σ²_{s:c} + σ²_r + σ²_cr + σ²_res) = 0.7530, pop
  subject = 0.6024.
- **Committed reference (`tests/testthat/fixtures/bayesian-conflated-oracle.rds`; seed 20290):** per-run
  convergence / coverage-of-Eq14 / glmmTMB-containment / conflated-minus-subject gap (values recorded by
  the generator run; pins are qualitative, #4/#18).
- **Pins (#4/#18):** convergence ≥ .90; coverage ∈ [.90, .99]; glmmTMB containment ≥ .90; conflated−subject
  gap > .05 (distinctness). Asserted in `test-icc-brms.R` **O-Eq14** (wiring, no Stan) +
  **O-Bayes-Conflated** (committed reference, on CI) + **O-Bayes-Conflated-agree** (live crossed fit,
  glmmTMB inside the CI, conflated > subject; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-conflated.R` (seeded; writes the fixture before the hard pins).

### Oracle O-Bayes-Rep — Bayesian within-cell replicates (M29 Slice 2, ADR-039)

- **Role:** the Bayesian sibling of the frequentist replicate oracle (M17 Slice 3). The
  within-cell-replicate ICC splits σ²_res → σ²_sr (subject:rater interaction) + σ²_e (pure error) via
  `fit_brms_replicates()` (`score ~ 1 + rater + (1|subject) + (1|subject:rater)`), and `occasions =
  "average"` divides **pure error** (not the interaction) by n_o. Like every random-rater Bayesian
  coefficient it is a **variance-ratio push-forward** — the estimand's per-component `error_divisors` are
  applied per posterior draw by `posterior_summary()` → `icc_point()`, so **none** of the θ² moment
  correction applies.
- **Oracles (≥2 independent, #1):** **O-Bayes-Rep-wiring** (no Stan) — `posterior_summary()` reproduces the
  closed-form occasion-averaged ratio per draw (pure error ÷ n_o, interaction undivided) and average >
  single draw-for-draw; **O-population** (coverage) — the single- and average-occasion credible intervals
  cover their known population values ~nominally; **O-glmmTMB containment** (the M17 §6 reduction) — the
  frequentist glmmTMB replicate points fall inside the brms credible intervals (differing only by the
  prior; the M26 containment posture).
- **Sources:** ten Hove et al. (2020) prior/recipe; generalizability theory two-facet (rater × occasion)
  decomposition (Cronbach et al. 1972; Brennan 2001); estimand-spec `M17-within-cell-replicates.md` (§1-2
  measurement model + per-component divisors — no new spec, M29 gives the shipped estimand the brms engine).
- **DGP:** two-way random with within-cell replicates, N_s = 25, k = 4, n_o = 3, σ²_s = 1.0, σ²_r = 0.16,
  σ²_sr = 0.5, σ²_e = 0.7; pop single ICC(A,1) = s²_s/(s²_s+s²_r+s²_sr+s²_e), pop average = the same with
  s²_e/n_o.
- **Committed reference (`tests/testthat/fixtures/bayesian-replicates-oracle.rds`; seed 20291):** per-run
  convergence / single+average coverage / glmmTMB containment / average-above-single fraction (values
  recorded by the generator run; pins qualitative, #4/#18).
- **Pins (#4/#18):** convergence ≥ .90; single and average coverage ∈ [.90, .99]; single and average
  glmmTMB containment ≥ .90; average > single in ≥ .95 of reps. Asserted in `test-icc-brms.R`
  **O-Bayes-Rep-wiring** (no Stan) + **O-Bayes-Rep** (committed reference, on CI) + **O-Bayes-Rep-agree**
  (live replicate fit, glmmTMB inside the CI, average > single; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-replicates.R` (seeded; writes the fixture before the hard pins).

### Oracle O-Bayes-Incomplete — Bayesian incomplete/ragged two-way random (M30 Slice 1, ADR-040)

- **Role:** the incomplete/ragged sibling of O-Bayes. `engine = "brms"` now fits **incomplete/ragged
  two-way random single-level** data — `fit_brms_twoway()` (`score ~ 1 + (1|subject) + (1|rater)`) run on
  ragged data unchanged, with the engine-agnostic M3 harmonic-mean `k_eff` divisor + connectedness (ADR-008)
  threaded per posterior draw by `posterior_summary()` → `icc_point()`. Random raters make each ICC a
  **variance-ratio push-forward** — no θ² finite-population functional, so **none** of the M27/M28 2b moment
  correction applies (the M29 clean-push-forward regime). Every mechanical piece is reused, oracle-pinned
  code; the milestone's one genuine unknown is **coverage on ragged data** (a CI method's oracle is coverage,
  #1) — in particular for ICC(A, k_eff), whose error is divided by the harmonic-mean k_eff.
- **Oracles (≥2 independent, #1):** **O-Bayes-Incomplete** (committed reference, no Stan) — a **reduction
  cell** (complete 30×5 grid, k_eff = k) covers ~nominally, reproducing the shipped M23 behaviour, and a
  **ragged cell** (fixed connected incidence, ~20% cells deleted, constant k_eff < 5) covers ICC(A,1) and
  ICC(A, k_eff) within Monte-Carlo error of the complete cell; **O-Bayes-Incomplete-agree** (live ragged
  fit) — the glmmTMB REML **M3** points (the independent incomplete-data oracle, ADR-008) fall inside the
  brms credible intervals (containment, not equality — the MAP-below-REML skew + prior gap, the M26/M29
  posture).
- **Sources:** ten Hove et al. (2020) prior/recipe/DGP (their study is balanced; the **ragged extension is
  not in the source**, so the independent oracle for the ragged point is the shipped glmmTMB M3 estimator,
  ADR-008); estimand-spec `M3-incomplete-designs.md` (k_eff/connectedness — no new spec, M30 gives the
  shipped incomplete estimand the brms engine).
- **DGP:** two-way random, N_s = 30, k = 5, σ²_s = σ²_sr = 0.5, σ²_r = 0.04; complete cell (k_eff = 5) and a
  fixed ragged incidence (120 of 150 cells kept, **k_eff = 3.78**); pop ICC(A,1) = s²_s/(s²_s+s²_r+s²_sr) =
  0.481, pop ICC(A,m) = s²_s/(s²_s+(s²_r+s²_sr)/m).
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-oracle.rds`; seed 30100, n_rep = 200):**
  per-cell (complete, ragged) convergence / ICC(A,1) + ICC(A,k_eff) coverage / MAP relative bias (pins
  qualitative, #4/#18). **Observed:** complete — conv .995, coverage .945/.945 (ICC(A,1)/ICC(A,k)), MAP
  relbias −.052/−.010; ragged — conv .995, coverage **.965/.965**, MAP relbias −.060/−.015. **The one
  unknown is resolved: ragged coverage is nominal** (even marginally above the complete cell, within MC
  error), so the variance-ratio push-forward through `k_eff` needs **no** correction and **no Fable review**
  (the M29 regime). Had the ragged cell undercovered, the finding would have been reported (#18) and gated a
  Fable review (#19) — never tuned away (#4).
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell ICC(A,1) & ICC(A,k) coverage ∈ [.90, .99]
  (the reduction baseline); ragged coverage ≥ complete − .05 and ≥ .90 for both units; |MAP relbias| < .10
  (complete) / < .12 (ragged). Asserted in `test-icc-brms.R` **O-Bayes-Incomplete** (committed reference, on
  CI) + **O-Bayes-Incomplete-agree** (live ragged fit, glmmTMB inside the CI; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete.R` (seeded; writes the fixture before the hard pins).

### Oracle O-Bayes-IML — Bayesian incomplete/ragged crossed multilevel random (M30 Slice 2, ADR-040)

- **Role:** the incomplete crossed (Design 1) **multilevel** sibling of O-Bayes-Incomplete. `engine =
  "brms"` now fits **incomplete/ragged crossed multilevel random** data — the shipped M5/M24
  `fit_brms_multilevel()` five-component fit run on ragged data unchanged, with the engine-agnostic M9
  harmonic-mean `k_eff` divisor + crossed-multilevel connectedness (ADR-018) threaded per posterior draw.
  Random raters → **variance-ratio push-forward**, no θ² functional, no 2b correction (the M29/Slice-1
  regime). Subject level (ICC(A,1), ICC(A,k_eff)) + single-rater cluster **ICC(c,1)** ship; the averaged
  cluster **ICC(c,k)** is undefined on incomplete data (the open per-cluster divisor, M9 §9) and is
  **dropped-with-note**.
- **Oracles (≥2 independent, #1):** **O-Bayes-IML** (committed reference, no Stan) — a **reduction cell**
  (complete grid, k_eff = k) covers ~nominally (the shipped M24 behaviour), and a **ragged cell** (fixed
  connected incidence, ~12% cells deleted, constant k_eff < 5) covers subject-level ICC(A,1) & ICC(A,k_eff)
  within Monte-Carlo error of the complete cell; **O-Bayes-IML-agree** (live ragged fit) — the glmmTMB REML
  **M9** points fall inside the brms credible intervals (containment, not equality), and the cluster rows
  are single-rater only (ICC(c,k) dropped).
- **Sources:** ten Hove et al. (2022) crossed Design 1 five-component decomposition; ten Hove et al. (2020)
  prior/recipe (the ragged extension is **not in the source**, so the independent oracle for the ragged
  point is the shipped glmmTMB M9 estimator, ADR-018); estimand-spec `M9-incomplete-multilevel.md` (k_eff /
  connectedness / cluster ICC(c,1) ships / ICC(c,k) open — no new spec, M30 gives the shipped incomplete
  estimand the brms engine).
- **DGP:** crossed Design 1, N_c = 15 clusters, N_s = 4/cluster, k = 5, σ²_c = 0.50, σ²_{s:c} = 1.00,
  σ²_r = 0.16, σ²_cr = 0.16, σ²_res = 0.50; complete cell (k_eff = 5) and a fixed ragged incidence (264 of
  300 cells kept, k_eff = 4.30); pop subject ICC(A,1) = s²_{s:c}/(s²_{s:c}+s²_r+s²_res), ICC(A,m) with the
  {rater, residual} error ÷ m; pop cluster ICC(c,1) = s²_c/(s²_c+s²_r+s²_cr).
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-ml-oracle.rds`; seed 30200, n_rep =
  100):** per-cell convergence / subject ICC(A,1)+ICC(A,k_eff) & cluster ICC(c,1) coverage / subject MAP
  relative bias (pins qualitative, #4/#18). **Observed:** complete — conv .98, subject coverage .95/.95
  (ICC(A,1)/ICC(A,k)), cluster ICC(c,1) coverage .92, subject MAP relbias −.043/−.009; ragged — conv .97,
  subject coverage **.97/.97**, cluster ICC(c,1) coverage .95, subject MAP relbias −.028/−.005. **The
  Slice-2 unknown is resolved: ragged SUBJECT-level coverage is nominal** through the k_eff divisor. The
  cluster level inherits the M24 few-cluster caveat (cluster MAP biased low ~−24% to −28% at N_c = 15), so
  cluster ICC(c,1) is **characterized** (ragged .95 tracks complete .92; the wide credible interval still
  covers despite the biased point), not pinned nominal (#18).
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell subject ICC(A,1) & ICC(A,k) coverage ∈
  [.90, .99] (reduction baseline); ragged subject coverage ≥ complete − .06 and ≥ .88 for both units; ragged
  cluster ICC(c,1) coverage ≥ complete − .06 (characterized); |subject MAP relbias| < .10 (complete) / < .12
  (ragged). Asserted in `test-icc-brms.R` **O-Bayes-IML** (committed reference, on CI) + **O-Bayes-IML-agree**
  (live ragged fit, glmmTMB inside the CI, ICC(c,k) dropped; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-multilevel.R` (seeded; writes the fixture before the
  hard pins).

### Oracle O-Bayes-IFixed — Bayesian incomplete/ragged two-way fixed-rater (M31 Slice 1, ADR-041)

- **Role:** the incomplete/ragged **FIXED-rater** sibling of O-Bayes-Incomplete (random) and O-Bayes-Fixed
  (balanced). `engine = "brms"` + `raters = "fixed"` now fits **incomplete/ragged two-way fixed-rater** data —
  the shipped M26 `fit_brms_fixed()` (`score ~ 1 + rater + (1|subject)`) run on ragged data unchanged, with the
  McGraw & Wong Case-3A finite-population θ²_r read per posterior draw through the shipped
  `brms_theta2r_draws()` → `brms_theta2r_moment_draws()` (the **2b** moment correction + boundary-aware
  average-floor, ADR-037/038) and the engine-agnostic M3 harmonic-mean `k_eff` divisor + connectedness
  (ADR-008) threaded per draw. **The genuine unknown (#1):** unlike the random incomplete path (a clean
  variance-ratio push-forward, no θ² functional — M30), the fixed θ²_r is a **convex quadratic functional**
  whose 2b correction is invisible on balanced data (b = tr(C·Σ_post)/(k−1) ≈ 0, rater means from the whole
  sample) but goes **live at the single level for the first time on ragged data** (b ≠ 0 once the rater means
  are estimated from unequal cell counts). Whether the percentile credible interval still covers nominally is
  the question this oracle answers.
- **Oracles (≥2 independent, #1):** **O-Bayes-IFixed** (committed reference, no Stan) — a **reduction cell**
  (complete grid, k_eff = k, b ≈ 0) covers ~nominally (the shipped M26 behaviour), and a **ragged cell** (fixed
  connected incidence, ~20% cells deleted, constant k_eff < 5, b ≠ 0) covers the fixed-population ICC(A,1) &
  ICC(A,k_eff) within Monte-Carlo error of the complete cell; **O-Bayes-IFixed-agree** (live ragged fit) — the
  glmmTMB REML **M3** incomplete fixed point falls inside the brms credible intervals (containment, not
  equality — the ADR-036 flat-rater-prior posture, here on ragged data).
- **Sources:** McGraw & Wong (1996) Case 3A (fixed-rater finite-population θ²_r); ten Hove et al. (2020)
  prior/recipe (half-*t*(4,0,1) on σ_s, MAP + percentile; the ragged extension is **not in the source**, so the
  independent oracle for the ragged point is the shipped glmmTMB M3 estimator, ADR-008); estimand-specs
  `M3-incomplete-designs.md` §6 (Case-3A θ²_r under imbalance) / `M10-fixed-multilevel.md` — **no new spec**
  (M31 gives the shipped incomplete fixed estimand the brms engine).
- **DGP:** two-way fixed raters, N_s = 30 subjects, k = 5 **fixed** rater means μ_r = (−0.6, −0.3, 0, 0.3, 0.6)
  (θ²_r = 0.225, not redrawn), σ²_s = σ²_res = 0.50; complete cell (k_eff = 5) and a fixed ragged incidence
  (120 of 150 cells kept, k_eff = 3.854); pop fixed ICC(A,1) = σ²_s/(σ²_s+θ²_r+σ²_res) = 0.408, ICC(A,m) with
  the {θ²_r, residual} error ÷ m.
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-fixed-oracle.rds`; seed 31100, n_rep =
  200):** per-cell convergence / ICC(A,1) & ICC(A,k_eff) coverage / MAP relative bias (pins qualitative,
  #4/#18). **Observed:** complete — conv 1.00, coverage **.955/.955** (ICC(A,1)/ICC(A,k)), MAP relbias
  −.020/+.001; ragged — conv 1.00, coverage **.965/.965**, MAP relbias −.042/−.010. **The milestone's one
  unknown is resolved: ragged fixed-rater coverage is NOMINAL** through the k_eff divisor even with the 2b
  moment correction active single-level — so **no Fable review** (ADR-041's conditional escalation not
  triggered). The MAP is biased low (the mode of the right-skewed ICC draws sits below the population plug-in,
  the M23/M26 posture) — characterized, not asserted unbiased.
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell ICC(A,1) & ICC(A,k) coverage ∈ [.88, .99]
  (reduction baseline); ragged coverage ≥ complete − .05 and ≥ .88 for both units; MAP relbias < .02 (biased
  low) both cells. Asserted in `test-icc-brms.R` **O-Bayes-IFixed** (committed reference, on CI) +
  **O-Bayes-IFixed-agree** (live ragged fit, glmmTMB inside the CI; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-fixed.R` (seeded; drives the SHIPPED
  `brms_theta2r_draws()` so it validates the exact 2b path, not a hand recipe).

### Oracle O-Bayes-IFML-fixed — Bayesian incomplete/ragged crossed fixed multilevel (M31 Slice 2, ADR-041)

- **Role:** the crossed (Design 1) **multilevel** FIXED-rater sibling of O-Bayes-IFixed (single-level fixed)
  and O-Bayes-IML (crossed multilevel random). `engine = "brms"` + `raters = "fixed"` now fits
  **incomplete/ragged crossed Design-1 fixed multilevel** data at the **subject level** — the shipped
  M10/M27-Slice-1 `fit_brms_multilevel_fixed()` five-component fit run on ragged data unchanged, with the
  Case-3A θ²_r read per posterior draw through the shipped `brms_theta2r_draws()` → `brms_theta2r_moment_draws()`
  (the **2b** correction + boundary-aware average-floor) and the engine-agnostic M9 `k_eff` divisor +
  crossed-multilevel identifiability (ADR-018) threaded per draw. As in Slice 1, the 2b correction goes **live
  on ragged data** (b ≠ 0). **Subject level only** — fixed cluster-level IRR is deferred for all engines (the
  M10 deferral), so `icc()` produces only the subject rows (no cluster `ICC(c,1)`/`ICC(c,k)`).
- **Oracles (≥2 independent, #1):** **O-Bayes-IFML-fixed** (committed reference, no Stan) — a **reduction cell**
  (complete grid, k_eff = k, b ≈ 0) covers ~nominally (the shipped M27-Slice-1 behaviour), and a **ragged cell**
  (fixed connected incidence, ~12% cells deleted, constant k_eff < 5, b ≠ 0) covers subject-level ICC(A,1) &
  ICC(A,k_eff) within Monte-Carlo error of the complete cell; **O-Bayes-IFML-fixed-agree** (live ragged fit) —
  the glmmTMB REML **M18 Slice 1** subject point falls inside the brms credible intervals (containment, not
  equality — the ADR-036 flat-rater-prior posture, here on ragged crossed data).
- **Sources:** ten Hove et al. (2022) crossed Design 1 five-component decomposition; McGraw & Wong (1996)
  Case 3A (fixed-rater finite-population θ²_r); ten Hove et al. (2020) prior/recipe (the ragged extension is
  **not in the source**, so the independent oracle for the ragged point is the shipped glmmTMB M18 Slice 1
  estimator, ADR-028); estimand-specs `M10-fixed-multilevel.md` / `M9-incomplete-multilevel.md` — **no new
  spec** (M31 gives the shipped incomplete fixed crossed-multilevel estimand the brms engine).
- **DGP:** crossed Design 1, N_c = 15 clusters, N_s = 4/cluster, k = 5 **fixed** rater means
  μ_r = (−0.6, −0.3, 0, 0.3, 0.6) (θ²_r = 0.225, not redrawn), σ²_c = 0.50, σ²_{s:c} = 1.00, σ²_cr = 0.16,
  σ²_res = 0.50; complete cell (k_eff = 5) and a fixed ragged incidence (264 of 300 cells kept, k_eff = 4.286);
  pop subject ICC(A,1) = σ²_{s:c}/(σ²_{s:c}+θ²_r+σ²_res) = 0.580, ICC(A,m) with the {θ²_r, residual} error ÷ m.
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-fixed-ml-oracle.rds`; seed 31200, n_rep =
  100):** per-cell convergence / subject ICC(A,1)+ICC(A,k_eff) coverage / subject MAP relative bias (pins
  qualitative, #4/#18). **Observed:** complete — conv .94, subject coverage **.95/.95**, MAP relbias
  −.016/−.003; ragged — conv .98, subject coverage **.91/.91**, MAP relbias −.000/+.001. **The Slice-2 unknown
  is resolved: ragged subject-level coverage is NOMINAL** — .91/.91 tracks complete .95/.95 within Monte-Carlo
  error (n_rep = 100, SE(coverage) ≈ .022; the ~.04 gap is < 2 SE and within the .06 tolerance the M30
  multilevel oracle used) even with the 2b correction active in the multilevel fixed regime — so **no Fable
  review** (ADR-041's conditional escalation not triggered). The MAP is ~unbiased/slightly low (the M23/M26
  posture) — characterized, not asserted unbiased.
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell subject ICC(A,1) & ICC(A,k) coverage ∈
  [.88, .99] (reduction baseline); ragged subject coverage ≥ complete − .06 and ≥ .88 for both units; |subject
  MAP relbias| < .10 (complete) / < .12 (ragged). Asserted in `test-icc-brms.R` **O-Bayes-IFML-fixed**
  (committed reference, on CI) + **O-Bayes-IFML-fixed-agree** (live ragged fit, glmmTMB inside the CI, subject
  level only; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-fixed-multilevel.R` (seeded; drives the SHIPPED
  `brms_theta2r_draws()` + `fit_brms_multilevel_fixed()` recipe; writes the fixture before the hard pins).

---

### Oracle O-Bayes-INML-clusters — Bayesian incomplete/ragged nested Design 2 random (M32 Slice 1, ADR-042)

- **Role:** the incomplete/ragged **nested** Design 2 (raters nested in clusters) **random** sibling of
  O-Bayes-IML (crossed) and the ragged extension of O-Bayes-NML (balanced nested). `engine = "brms"` now fits
  **incomplete/ragged nested Design-2 random** data at the subject level — the shipped M8/M25
  `fit_brms_nested_clusters()` four-component fit run on ragged data unchanged, with the engine-agnostic M3/M9
  harmonic-mean `k_eff` divisor + within-cluster connectedness gates (ADR-018, run pre-dispatch) threaded per
  posterior draw. Random raters → **variance-ratio push-forward**, no θ² functional, no 2b correction (the
  M30 regime). Subject level only (nested designs define no cluster-level IRR). Scoped **random-only**:
  incomplete *fixed* nested has no frequentist oracle (deferred all engines, ADR-029/ADR-042).
- **Oracles (≥2 independent, #1):** **O-Bayes-INML-clusters** (committed reference, no Stan) — a **reduction
  cell** (complete grid, k_eff = k) covers ~nominally (the shipped M25 Slice 1 behaviour), and a **ragged
  cell** (fixed connected incidence, ~12% cells deleted, constant k_eff < 5) covers subject-level ICC(A,1) &
  ICC(A,k_eff) within Monte-Carlo error of the complete cell; **O-Bayes-INML-clusters-agree** (live ragged
  fit) — the glmmTMB REML **M19** incomplete nested random point falls inside the brms credible intervals
  (containment, not equality).
- **Sources:** ten Hove et al. (2022) nested Design 2 four-component decomposition (Eqs. 8–11, Table 3
  middle); ten Hove et al. (2020) prior/recipe (the ragged extension is **not in the source**, so the
  independent oracle for the ragged point is the shipped glmmTMB M19 estimator, ADR-029); estimand-spec
  `M8-nested-multilevel.md` with `M9-incomplete-multilevel.md` / `M3-incomplete-designs.md` §6 (k_eff /
  connectedness under imbalance — no new spec).
- **DGP:** nested Design 2, N_c = 20 clusters, N_s = 5/cluster, k = 5 raters/cluster (nested in cluster),
  σ²_c = 0.50 (nuisance — no cluster ICC), σ²_{s:c} = 1.00, σ²_{r:c} = 0.16, σ²_res = 0.50; complete cell
  (k_eff = 5) and a fixed ragged incidence (440 of 500 cells kept, k_eff = 4.24); pop subject
  ICC(A,1) = s²_{s:c}/(s²_{s:c}+s²_{r:c}+s²_res), ICC(A,m) with the {rater, residual} error ÷ m.
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-nested-oracle.rds`; seed 32100, n_rep =
  80):** per-cell convergence / subject ICC(A,1)+ICC(A,k_eff) coverage / subject MAP relative bias (pins
  qualitative, #4/#18). **Observed:** complete — conv 1.00, coverage **.95/.95** (ICC(A,1)/ICC(A,k)), MAP
  relbias +.001/+.001; ragged (k_eff 4.24) — conv .99, coverage **.925/.925**, MAP relbias −.005/−.001. **The
  one unknown is resolved: ragged subject-level coverage is nominal** (.925/.925 tracks complete .95/.95
  within Monte-Carlo error, SE ≈ .028 at n_rep 80) through the k_eff divisor — as expected for a random-rater
  variance-ratio push-forward (no 2b), so **no Fable review** (ADR-042's conditional escalation not
  triggered).
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell subject ICC(A,1) & ICC(A,k) coverage ∈
  [.90, .99] (reduction baseline); ragged subject coverage ≥ complete − .06 and ≥ .88 for both units; |subject
  MAP relbias| < .10 (complete) / < .12 (ragged). Asserted in `test-icc-brms.R` **O-Bayes-INML-clusters**
  (committed reference, on CI) + **O-Bayes-INML-clusters-agree** (live ragged fit, glmmTMB inside the CI,
  subject level only; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-nested.R` (seeded; drives the SHIPPED
  `fit_brms_nested_clusters()` recipe; writes the fixture before the hard pins).

---

### Oracle O-Bayes-INML-subjects — Bayesian incomplete/ragged nested Design 3 random (M32 Slice 2, ADR-042)

- **Role:** the incomplete/ragged **nested** Design 3 (raters nested in subjects, the multilevel **one-way**,
  agreement-only) **random** sibling of O-Bayes-INML-clusters (Design 2). `engine = "brms"` now fits
  **incomplete/ragged nested Design-3 random** data at the subject level — the shipped M8/M25
  `fit_brms_nested_subjects()` three-component fit run on ragged data unchanged, with the engine-agnostic
  M3/M9 harmonic-mean `k_eff` divisor + the per-subject ≥ 2 raters identifiability gate (ADR-018, run
  pre-dispatch) threaded per posterior draw. In Design 3 the rater main effect is **confounded into the
  residual** (ten Hove 2022 p. 6), so there is no consistency coefficient and no cluster level. Random raters
  → **variance-ratio push-forward**, no θ² functional, no 2b correction (the M30 regime). Scoped
  **random-only** (fixed nested is not defined for Design 3 — no separable rater effect, ADR-029/ADR-042).
- **Oracles (≥2 independent, #1):** **O-Bayes-INML-subjects** (committed reference, no Stan) — a **reduction
  cell** (complete grid, k_eff = k) covers ~nominally (the shipped M25 Slice 2 behaviour), and a **ragged
  cell** (fixed connected incidence, ~12% cells deleted, constant k_eff < 5) covers subject-level one-way
  ICC(1) & ICC(k_eff) within Monte-Carlo error of the complete cell; **O-Bayes-INML-subjects-agree** (live
  ragged fit) — the glmmTMB REML **M19** incomplete nested random point falls inside the brms credible
  intervals (containment, not equality).
- **Sources:** ten Hove et al. (2022) nested Design 3 three-component decomposition (Eq. 11, Table 3 right);
  ten Hove et al. (2020) prior/recipe (the ragged extension is **not in the source**, so the independent
  oracle for the ragged point is the shipped glmmTMB M19 estimator, ADR-029); estimand-spec
  `M8-nested-multilevel.md` with `M9-incomplete-multilevel.md` / `M3-incomplete-designs.md` §6 (k_eff /
  per-subject identifiability under imbalance — no new spec).
- **DGP:** nested Design 3, N_c = 20 clusters, N_s = 5/cluster, k = 5 raters/subject (nested in subject),
  σ²_c = 0.50 (nuisance — no cluster ICC), σ²_{s:c} = 1.00, σ²_r = 0.16 (confounded into residual),
  σ²_res = 0.50; complete cell (k_eff = 5) and a fixed ragged incidence (440 of 500 cells kept,
  k_eff = 4.29); pop subject one-way ICC(1) = s²_{s:c}/(s²_{s:c}+s²_r+s²_res), ICC(m) with the confounded
  residual ÷ m.
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-nested-subjects-oracle.rds`; seed
  32200, n_rep = 240, per-rep seeding):** per-cell convergence / subject one-way ICC(1)+ICC(k_eff) coverage /
  subject MAP relative bias (pins qualitative, #4/#18). **Observed (n_rep 240):** complete — conv .98,
  coverage **.9375/.9375**, MAP relbias ≈ 0; ragged (k_eff 4.29) — conv .98, coverage **.9417/.9417**, MAP
  relbias −.007/−.002. Both cells sit within ~1 MC SE of nominal .95 and inside Fable's pre-registered
  [.92, .975]; the ragged ≥ .88 pin passes comfortably (the n_rep-80 .8625 tail did not recur — same
  incidence, now .9417). **The one unknown is resolved: ragged subject-level coverage is nominal** through
  the k_eff divisor — a
  random-rater variance-ratio push-forward (no 2b). **History (#18/#19):** the first committed run (n_rep 80)
  drew a ragged cell of **.8625** — a ~.002 Monte-Carlo tail event that fired the ragged ≥ .88 pin and
  triggered a **gated Fable review** (ADR-042 Amendment 2). Fable re-ran the SAME incidence at n = 240 →
  **.9458** [Wilson .910–.968], four fresh incidences → **.9500**, and a **2,000-fit frequentist arm** on the
  same incidence → **.9555** [.946–.964], with a **uniform PIT** (KS D = .028, p = .76 — the percentile
  interval is calibrated) and posterior sd ≈ empirical sampling sd (Bernstein–von Mises regime). Verdict:
  **no estimator shortfall**; the fixture was regenerated at n_rep = 240 with per-rep seeding (a pre-registered
  precision upgrade, not tuning, #4) and the pins are UNCHANGED. Fable's frequentist arm (`fable-check-m32s2.R`)
  also supplies the first committed **ragged nested Design-3 coverage** evidence for the glmmTMB M19 estimator
  (M19 pinned point reductions only).
- **Pins (#4/#18):** convergence ≥ .90 both cells; complete-cell subject ICC(1) & ICC(k) coverage ∈
  [.90, .99] (reduction baseline); ragged subject coverage ≥ complete − .06 and ≥ .88 for both units; |subject
  MAP relbias| < .10 (complete) / < .12 (ragged). Asserted in `test-icc-brms.R` **O-Bayes-INML-subjects**
  (committed reference, on CI) + **O-Bayes-INML-subjects-agree** (live ragged fit, glmmTMB inside the CI,
  subject level only, one-way labels; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-nested-subjects.R` (seeded; drives the SHIPPED
  `fit_brms_nested_subjects()` recipe; writes the fixture before the hard pins).

### Oracle O-Bayes-IOneway — Bayesian incomplete/ragged single-level one-way random (M33 Slice 1, ADR-043)

- **Role:** the incomplete/ragged **single-level one-way** (Shrout & Fleiss Case 1) sibling of
  O-Bayes-Incomplete (two-way). `engine = "brms"` now fits **incomplete/ragged one-way** data
  (`ICC(1)`/`ICC(1,k)`) — the shipped M26 Slice 1 `fit_brms_oneway()` two-component
  `score ~ 1 + (1 | subject)` fit run on ragged data unchanged, reached by narrowing the `!balanced` brms
  guard's `oneway` clause; the engine-agnostic M3/M6 harmonic-mean `k_eff` divisor (ratings per subject) is
  threaded per posterior draw. Random raters → **variance-ratio push-forward**, no θ² functional, no 2b
  correction (the M30 regime). The first of the M33 Bayesian parity-mop-up slices.
- **Oracles (≥2 independent, #1):** **O-Bayes-IOneway** (committed reference, no Stan) — a **reduction cell**
  (complete grid, k_eff = k = 5) covers ~nominally (the shipped M26 Slice 1 behaviour), and a **ragged cell**
  (fixed incidence, ~20% of rating slots deleted, constant k_eff < 5) covers ICC(1) & ICC(1, k_eff) within
  Monte-Carlo error of the complete cell; **O-Bayes-IOneway-agree** (live ragged fit) — the glmmTMB/lme4 REML
  **M6+M3** incomplete one-way point falls inside the brms credible intervals (containment, not equality —
  the MAP-below-REML skew + prior gap).
- **Sources:** Shrout & Fleiss (1979) Case 1 / McGraw & Wong (1996) one-way random (estimand); ten Hove et al.
  (2020) prior/recipe (the ragged extension is **not in the source**, so the independent oracle for the ragged
  point is the shipped glmmTMB/lme4 M6+M3 estimator, ADR-008); estimand-spec `M6-oneway.md` with
  `M3-incomplete-designs.md` §6 (harmonic-mean `k_eff` under imbalance — no new spec).
- **DGP:** one-way, N = 30 subjects, k = 5 ratings/subject at balance, σ²_s = σ²_res = 0.5 (population
  ICC(1) = 0.5, an interior ratio past the k = 2 caveat); complete cell (k_eff = 5) and a fixed ragged
  incidence (120 of 150 slots kept, k_eff = 3.7344); pop ICC(1, m) = σ²_s/(σ²_s + σ²_res/m).
- **Committed reference (`tests/testthat/fixtures/bayesian-incomplete-oneway-oracle.rds`; seed 33100,
  n_rep = 240, per-rep seeding):** per-cell convergence / ICC(1)+ICC(1,k_eff) coverage / MAP relative bias
  (pins qualitative, #4/#18). **Observed (n_rep 240):** complete — conv 1.00, coverage **.9375/.9375**, MAP
  relbias −.027/−.004; ragged (k_eff 3.73) — conv 1.00, coverage **.9458/.9458**, MAP relbias −.040/−.009.
  **The one unknown is resolved: ragged one-way coverage is NOMINAL** through the k_eff divisor — a
  random-rater variance-ratio push-forward (no 2b), the M30 regime — so **no Fable review** (the pin's
  conditional escalation was not triggered). Both cells sit within ~1 MC SE of nominal .95 and inside the
  [.92, .975] band; the ragged ≥ .88 pin passes comfortably.
- **Pins (#4/#18):** convergence ≥ .90 both cells; k_eff shrinks under imbalance; complete-cell ICC(1) & ICC(k)
  coverage ∈ [.90, .99] (reduction baseline); ragged coverage ≥ complete − .06 and ≥ .88 for both units;
  |MAP relbias| < .10 (complete) / < .12 (ragged). Asserted in `test-icc-brms.R` **O-Bayes-IOneway** (committed
  reference, on CI) + **O-Bayes-IOneway-agree** (live ragged fit, glmmTMB inside the CI; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-incomplete-oneway.R` (seeded; drives the SHIPPED
  `fit_brms_oneway()` recipe; writes the fixture before the hard pins).

### Oracle O-Bayes-FRep — Bayesian fixed-rater within-cell replicates (M33 Slice 2, ADR-043)

- **Role:** the **fixed-rater** sibling of O-Bayes-Rep (M29 Slice 2, random replicates) and the Bayesian
  sibling of the frequentist **M20 Slice 1** (`fit_glmmtmb_replicates_fixed`). `engine = "brms"` +
  `raters = "fixed"` now fits **single-level within-cell replicates** — `fit_brms_replicates_fixed()` fits
  `score ~ 1 + rater + (1 | subject) + (1 | subject:rater)`, splits the residual into the interaction σ²_sr
  and pure error σ²_e, and reads the Case-3A finite-population **θ²_r per posterior draw** from the rater
  fixed-effect draws (the shared `brms_theta2r_draws()`), injecting it into the rater slot. The `occasions`
  per-draw divisor (pure error ÷ n_o) composes off these draws exactly as the random path. On **balanced**
  replicated data the rater means come from the whole sample, so the **2b moment correction ≈ 0** (the
  M26/M27-S1 regime, not the ragged M31 regime) and θ²_r = σ²_r — fixed reproduces the random coefficients.
- **Oracles (≥2 independent, #1):** **O-Bayes-FRep** (committed reference, no Stan) — single-/average-occasion
  fixed-population ICC(A,1) **coverage** ~nominal, **containment** of the glmmTMB fixed replicate points (the
  M20 §6 reduction; = the fixed==random reduction on balanced data), and **average > single**;
  **O-Bayes-FRep-agree** (live fit) — the glmmTMB REML fixed replicate points fall inside the brms credible
  intervals (containment, `skip_on_ci`).
- **Sources:** McGraw & Wong (1996) Case 3A (θ²_r = Σ(μ_rj − μ̄_r)²/(k−1)); GT two-facet replicate
  decomposition (`M17-within-cell-replicates.md`); ten Hove et al. (2020) prior/recipe; the independent point
  oracle is the shipped glmmTMB M20 Slice 1 estimator (no new spec).
- **DGP:** single-level two-way fixed-rater with within-cell replicates, N_s = 25, **k = 4 FIXED raters**
  μ_r = (−0.6, −0.2, 0.2, 0.6) → θ²_r = 0.8/3 = 0.2667, n_o = 3, σ²_s = 1.00, σ²_sr = 0.50, σ²_e = 0.70;
  pop single = 1/(1 + 0.2667 + 0.5 + 0.7) = 0.4054, average = 1/(1 + 0.2667 + 0.5 + 0.7/3) = 0.5000. The
  rater means are FIXED across replications (a fixed finite population); subjects/interactions/error redrawn.
- **Committed reference (`tests/testthat/fixtures/bayesian-fixed-replicates-oracle.rds`; seed 33200,
  n_rep = 80):** convergence / single+average coverage / glmmTMB containment / average>single / MAP relbias
  (pins qualitative, #4/#18). **Observed:** conv 1.00, coverage **.9625/.9625** (single/average, both ∈
  [.90, .99] — nominal), containment **1.00/1.00**, average>single **1.00**, MAP relbias −.056/−.024 (mode
  below the plug-in, the standard MAP skew — characterized, not tuned). **Balanced → 2b ≈ 0, so no
  θ²-functional undercoverage** → **no Fable review**.
- **Pins (#4/#18):** convergence ≥ .90; θ²_r = 0.8/3; single/average coverage ∈ [.90, .99]; containment
  ≥ .90 both; average>single ≥ .95. Asserted in `test-icc-brms.R` **O-Bayes-FRep** (committed reference, on
  CI) + **O-Bayes-FRep-agree** (live fit, glmmTMB inside the CI; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-fixed-replicates.R` (seeded; drives the SHIPPED
  `fit_brms_replicates_fixed()` recipe; writes the fixture before the hard pins).

### Oracle O-Bayes-MLRep — Bayesian multilevel within-cell replicates (M33 Slice 3, ADR-043)

- **Role:** the **multilevel** sibling of O-Bayes-Rep (single-level random replicates) and the Bayesian
  sibling of the frequentist **M20 Slice 2** (`fit_glmmtmb_{ml,nested}_replicates`). `engine = "brms"` now
  fits **multilevel within-cell replicate** ICCs for **both** replicate multilevel designs, subject level,
  random raters: crossed **Design 1** (`fit_brms_ml_replicates()`, `+ (1|cluster:subject:rater)` on the M5
  five-component fit → **six components**) and nested **Design 2** (`fit_brms_nested_replicates()`, the same
  split on the M8 four-component fit → **five components**). The (1|cluster:subject:rater) term splits the
  subject-level residual into the interaction σ²_{csr} ("subject_rater") and pure error σ²_e ("residual");
  `occasions` divides only pure error by n_o. Random raters → **variance-ratio push-forward**, no θ²
  functional, no 2b (a plain `fit_brms_common()` call, the M30 regime). Design 3 replicate-split is ⚫ by
  design (multilevel one-way, no separable interaction); fixed-rater / conflated / ragged multilevel
  replicates stay deferred (all engines).
- **Oracles (≥2 independent, #1):** **O-Bayes-MLRep** (committed reference, no Stan) — per-design (crossed /
  nested) subject-level single-/average-occasion ICC(A,1) **coverage** ~nominal, **containment** of the
  frequentist glmmTMB replicate points (the M20 §6 reduction), and **average > single**;
  **O-Bayes-MLRep-agree** (live fits, both designs) — the glmmTMB REML replicate points fall inside the brms
  credible intervals (containment, `skip_on_ci`).
- **Sources:** ten Hove et al. (2022) Table 3 (multilevel estimand) + GT two-facet replicate split
  (`M17-within-cell-replicates.md`); ten Hove et al. (2020) prior/recipe; the independent point oracle is the
  shipped glmmTMB M20 Slice 2 estimator (no new spec). The subject-level agreement error set is
  {rater, subject_rater, residual} — **excluding** cluster_rater, which is a cluster-level phenomenon
  (estimand.R; matches the M24 subject-level definition).
- **DGP:** replicate multilevel, N_c = 15 clusters, N_s = 4 subjects/cluster, k = 3 raters, n_o = 2, σ²_c =
  0.50, σ²_{s:c} = 1.00, σ²_r = 0.16 (D1 rater main / D2 rater-in-cluster σ²_{r:c}), σ²_{cr} = 0.16 (D1 only,
  cluster-level), σ²_{csr} = 0.40, σ²_e = 0.50; pop subject single = 1.0/(1.0+0.16+0.40+0.50) = 0.4854,
  average = 1.0/(1.0+0.16+0.40+0.50/2) = 0.5525 (same for both designs; σ²_r = σ²_{r:c}).
- **Committed reference (`tests/testthat/fixtures/bayesian-multilevel-replicates-oracle.rds`; seed 33300,
  n_rep = 80 per design):** per-design convergence / single+average coverage / glmmTMB containment /
  average>single / MAP relbias (pins qualitative, #4/#18). **Observed:** crossed D1 — conv .96, coverage
  **.9500/.9500**, containment 1.00/1.00, avg>single 1.00, MAP relbias −.074/−.063; nested D2 — conv .99,
  coverage **.9625/.9500**, containment 1.00/1.00, avg>single 1.00, MAP relbias +.029/+.024. **Both designs
  NOMINAL** — random-rater variance-ratio push-forward (no 2b) → **no Fable review**.
- **Pins (#4/#18):** per design — convergence ≥ .90; single/average coverage ∈ [.90, .99]; containment ≥ .90
  both; average>single ≥ .95. Asserted in `test-icc-brms.R` **O-Bayes-MLRep** (committed reference, on CI) +
  **O-Bayes-MLRep-agree** (live fits both designs, glmmTMB inside the CI; `skip_on_ci`).
- **Provenance:** `data-raw/oracle-bayesian-multilevel-replicates.R` (seeded; compiles one model per design,
  drives the SHIPPED `fit_brms_{ml,nested}_replicates()` recipes; the glmmTMB point comes from
  `icc_point()` on the shipped replicate fit's components — bypassing `mc_ci()`, which can overflow on an
  unstable small-multilevel fit; writes the fixture before the hard pins).

### Oracle O-PriorReduce — Bayesian user `prior=` override (M34 Slice 1, ADR-044)

- **Role:** the customization oracle for the new user **`prior=`** argument on `engine = "brms"`. This is a
  **REDUCTION oracle, not a coverage oracle** — the whole point of `prior=` is to let users leave the sourced
  regime (prior-sensitivity / method-comparison / simulation work), so no coverage is claimed under a custom
  prior (#4). Correctness is established by three checks: the default and an *explicit* sourced prior agree
  bit-identically (the override path is faithful and the default path is unchanged), and a *different* prior
  demonstrably changes the fit. The sourced half-*t*(4, 0, 1) on every random-effect SD (ten Hove et al.
  2020 §3.3/§4.1) stays the `prior = NULL` default.
- **Oracles (#1):** **(a) reduction** — `prior = NULL` reproduces the shipped M23+ MAP/credible-interval
  results at a fixed seed (the default path is structurally unchanged: the sourced prior is set only when the
  user supplies none); **(b) round-trip** — passing the sourced half-*t* *explicitly*
  (`brms::set_prior("student_t(4, 0, 1)", class = "sd")`) reproduces the `NULL` result **bit-identically**
  (`expect_identical` on `$estimates$estimate` and `$components`), proving the injection into the `brms::brm`
  call is faithful; **(c) override-takes-effect + footgun warning** — a deliberately tight SD prior
  (`normal(0, 0.5)`) shrinks the random-effect SDs, moving `ICC(A,1)` **down** vs the sourced prior, and fires
  the classed `intraclass_custom_prior` warning; **(d) classed guards** — `prior` off `engine = "brms"` →
  `intraclass_unsupported`; a non-`brmsprior` value on brms → `intraclass_error`; `prior` set through
  `brm_args` → `intraclass_error` routing the user to the dedicated argument.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) §3.3/§4.1 (the half-*t*(4, 0, 1) SD prior that is the
  *sourced default* the override departs from), §4.2 (why the coverage claims are prior-specific). No new
  estimand-spec (interface milestone). No committed fixture / no Stan needed for the guard checks (they fire
  before the fit, run on every CI job); the reduction/round-trip/override checks are a **live** fit
  (`skip_on_ci` — a CI runner has brms but no Stan toolchain).
- **Pins (#4/#18):** no coverage claim under a custom prior. Asserted in `test-icc-brms.R`: the `prior=` guard
  tests (`intraclass_unsupported` / `intraclass_error`, on CI) + **O-PriorReduce** (live: round-trip
  `expect_identical`, tight-prior `expect_lt` + classed warning; `skip_on_ci`).

### Oracle O-HPDI — Bayesian HPDI credible intervals (M34 Slice 2, ADR-044)

- **Role:** the customization oracle for the new **`posterior_summary = c("percentile", "hpdi")`** argument,
  which selects how `ci_method = "posterior"` reduces the posterior ICC draws to a credible interval. Like
  O-PriorReduce this is a **REDUCTION oracle, not a coverage oracle**: percentile stays the default (ten Hove
  et al. 2020 §4.2 found percentile — not HPD — intervals give nominal coverage at k > 2; percentile is
  transform-invariant and boundary-graceful, HPDI is neither), so **no coverage is claimed for HPDI** (#4). The
  HPDI is the narrowest interval covering the credible mass, computed by a dependency-free internal helper
  `hpdi_interval()` whose index arithmetic matches `coda::HPDinterval` exactly (light install preserved).
- **Oracles (#1):** **(a) reduction** — `posterior_summary = "percentile"` (and the default) reproduces the
  shipped M23+ intervals **bit-identically** (`expect_identical` on `$estimates`); threading the choice through
  does not disturb the default path. **(b) definitional agreement** — `hpdi_interval()` ≡ `coda::HPDinterval`
  (the independent oracle, `skip_if_not_installed("coda")`) to ≤ 1e-8 on a fixed skewed-toward-zero draw
  vector (a boundary-ICC mimic). **(c) narrower-or-equal + same point** — on a live brms fit the HPDI is no
  wider than the percentile interval on the same draws (the defining HPDI property) and the **MAP point is
  unchanged** (only the interval reduction differs); the printed header names the `(HPDI)` variant. **(d)
  classed guard** — `posterior_summary` set for a non-`posterior` `ci_method` → `intraclass_unsupported`.
- **Sources:** ten Hove, Jorgensen & van der Ark (2020) §4.2 (percentile BCIs nominal at k > 2, the reason
  percentile stays default); `coda::HPDinterval` (the independent HPDI reference; Suggests-only, test-time).
  No new estimand-spec (interface milestone). No committed fixture: the reduction/agreement/guard checks need
  no Stan (run on CI); the live narrower-or-equal / label check is a fit (`skip_on_ci`).
- **Pins (#4/#18):** no coverage claim for HPDI. Asserted in `test-icc-brms.R`: the `posterior_summary` guard
  test (`intraclass_unsupported`, on CI) + the `hpdi_interval` ≡ `coda` + narrower-than-percentile unit test
  (on CI where coda is present) + **O-HPDI** (live: reduction `expect_identical`, HPDI same MAP + no wider +
  `(HPDI)` header; `skip_on_ci`).

### Oracle O-Bayes-FCL — Bayesian fixed-rater CLUSTER-level ICC, crossed Design 1, balanced (M38 Cell 1, ADR-048)

- **Role:** the brms sibling of **O-FCL** (frequentist) and the cluster-level companion of **O-Bayes-FML**
  (brms crossed fixed subject level). Engine/interval **parity, not new estimand work**: removing the
  brms cluster-drop guard routes the cluster-level (σ²_c | {θ²_r, σ²_cr}, k) push-forward off the shipped M27
  `fit_brms_multilevel_fixed()` five-component draws — no new fit, since `icc_estimand()` keys the cluster
  error set on `level` not `raters` and the injected `rater` draw row is θ²_r.
- **Why reduction, not coverage (the M34/M27 posture):** M37's Outcome A (on balanced data θ²_r = σ²_r and
  σ²_cr is unbiased under fixing) makes this a **variance-ratio push-forward** with `b ≈ 0` — the brms fixed
  cluster level reduces to the brms **random** cluster level (M24). So the oracle is (a) reduction + (b)
  containment, with **no coverage claim and no Fable** (the risk is entirely in Cell 2's ragged 2b path).
- **Oracles (#1):** **(a) reduction** — the brms fixed cluster-level ICC(A,1)/ICC(A,k) tracks the brms random
  cluster level (M24) on the same seeded balanced crossed Design 1 (~20 clusters so σ²_c is identified) within
  Monte-Carlo error; verified live |Δ|max **.0215** (tol .06). **(b) containment** — the glmmTMB M37 fixed
  cluster point sits inside the brms credible interval for every cluster row (the engines differ only by the
  prior, #18). Plus a fast CI-runnable guard: the INCOMPLETE fixed cluster level still aborts
  (`intraclass_unsupported`) at the engine-agnostic balance gate, so the guard removal did not open the
  deferred cell.
- **Sources:** ten Hove, Jorgensen & van der Ark (2022) Eq. 13 / Table 3 (cluster-level decomposition);
  McGraw & Wong (1996) Case 3/3A. No new estimand-spec (references `M37-fixed-cluster-level.md`,
  `M5-multilevel.md §3b`). No committed fixture (reduction + containment are live; `skip_on_ci`).
- **Pins:** `test-icc-brms.R` — **O-Bayes-FCL** (live: both levels returned, containment, fixed≈random
  reduction; `skip_on_ci`) + the fast incomplete-boundary guard (on CI).

### Oracle O-Bayes-IFNML — Bayesian INCOMPLETE/ragged fixed-nested (Design 2) single-rater (M38 Cell 2, ADR-048)

- **Role:** the brms sibling of the frequentist **O-IFNML** (M36) and the ragged sibling of **O-Bayes-FNML**
  (balanced nested fixed). Removing the brms incomplete-fixed-nested guard lets `fit_brms_nested_fixed()`
  (`score ~ 0 + rater + (1|cluster:subject)`) fit ragged data unchanged; `brms_theta2r_nested_draws()` →
  `brms_theta2r_moment_draws()` reads a **per-cluster** k (nrow of each cluster's rater-mean matrix), so
  unequal per-cluster counts k_c and the **2b-under-imbalance moment correction** (b ≠ 0) + boundary-aware
  average-floor fall out per cluster with no new code. Subject level, single + average ICC_s (divisor = the
  well-defined per-subject k_eff, the M19/M36 divisor — **not** the open per-cluster ICC(c,k), M9 §9).
- **The milestone's genuine risk (#1/#18):** the 2b moment correction going **nested-brms for the first time**
  on ragged data. The recovery is **NON-CIRCULAR**: θ²_{r:c} is a deterministic function of the fixed
  per-cluster rater means, so the single-rater population value vsc/(vsc + θ² + vres) is fixed and its
  credible-interval coverage is a genuine independent oracle.
- **The gate (ADR-048):** nominal in [.90, .99] interior AND boundary (θ²=0) at BOTH cluster counts → Cell 2
  ships; under-coverage would have been **STOP-and-replan** (no pin-loosening #4, no tuning, no Fable #19).
- **DGP + committed reference (`tests/testthat/fixtures/bayesian-incomplete-fixed-nested-oracle.rds`;
  base_seed 38200):** the M36 `sim_ragged_d2_fixed()` (cluster-unique fixed rater means scaled to an exact
  per-cluster θ²; ~15% cells dropped; unequal k_c ∈ {3,4}; subjects with <2 ratings dropped), vsc=1.0,
  vres=0.5, n_rep **240** ([[ragged-coverage-nrep-240]]). Compile-once + `update(recompile=FALSE)` over a
  **4-cell grid** crossing {C_n 20, C_n 80} × {interior θ²=.30, boundary θ²=0}
  ([[coverage-oracle-cluster-count-axis]] — the C_n=80 cell is the incidental-parameters probe). **Result:
  NOMINAL — coverage .975 / .954 / .983 / .970**, |bias| ≤ .008; the C_n=80 boundary (.970) shows **no decay**,
  so the per-cluster 2b correction does not suffer the M28-style collapse through the posterior. 7/240 fits at
  C_n=80 errored and were discarded + counted (#18).
- **Sources:** ten Hove et al. (2022) p. 6 (nested Design 2); McGraw & Wong (1996) Case 3A. Regenerate with
  `data-raw/oracle-bayesian-incomplete-fixed-nested.R` (~960 live Stan refits; the fixture, not the sim, is
  what CI checks — [[brms-live-fit-skip-on-ci]]). No new estimand-spec (references `M36-incomplete-fixed-nested.md`).
- **Pins:** `test-icc-brms.R` — **O-Bayes-IFNML** (committed fixture: all four cells in [.90,.99] + the
  C_n=80-boundary no-collapse pin + |bias|<.02 + n_fail<10%, fast/CI-runnable) + **O-Bayes-IFNML-agree** (live:
  ragged fit end-to-end, glmmTMB M36 containment; `skip_on_ci`).

---

## Bibliography

- Brennan, R. L. (2001). *Generalizability Theory.* Springer.
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400.
- Cicchetti, D. V. (1994). Guidelines, criteria, and rules of thumb for evaluating
  normed and standardized assessment instruments in psychology. *Psychological
  Assessment, 6*(4), 284–290. doi:10.1037/1040-3590.6.4.284. (Interpretation-band
  source for `getting-started.Rmd`, M40 — the older sibling rule of thumb: ICC < 0.40
  poor, 0.40–0.59 fair, 0.60–0.74 good, 0.75–1.00 excellent. Cited as one convention
  among several, with caveats; the package computes no verdict — #4/#18.)
- Jorgensen, T. D. (2021). How to estimate absolute-error components in structural
  equation models of generalizability theory. *Psych, 3*(2), 113–133.
  doi:10.3390/psych3020011. (M7 lavaan engine — the SEM absolute-error method; Eq. 6
  defines σ²_i as the raw variance of the effects-coded indicator intercepts.)
- Koo, T. K., & Li, M. Y. (2016). A guideline of selecting and reporting intraclass
  correlation coefficients for reliability research. *Journal of Chiropractic
  Medicine, 15*(2), 155–163. doi:10.1016/j.jcm.2016.02.012. (Primary
  interpretation-band source for `getting-started.Rmd`, M40: ICC < 0.5 poor,
  0.5–0.75 moderate, 0.75–0.90 good, > 0.90 excellent — and, load-bearing for the
  vignette's caveat, the guideline is to **judge against the 95% CI of the estimate,
  not the point** (§ "Interpretation"). Cited as one convention among several; the
  package deliberately computes no verdict — #4/#18.)
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
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2020). Comparing hyperprior
  distributions to estimate variance components for interrater reliability
  coefficients. In M. Wiberg et al. (Eds.), *Quantitative Psychology* (Springer
  Proceedings in Mathematics & Statistics, Vol. 322, pp. 79–93). Springer.
  doi:10.1007/978-3-030-43469-4_7. OSF: `shkqm` (companion code/materials). **The M23
  Bayesian source (O-Bayes):** fixes the half-*t*(4, 0, 1) prior on random-effect SDs
  (§3.3/§4.1), the two-way crossed-random DGP (§4.1.1: N = 30, σ²_s = σ²_sr = 0.5,
  σ²_r ∈ {.01, .04}, k ∈ {2, 3, 5}), and reports MAP unbiased / EAP biased for σ_r and
  percentile-BCI nominal coverage at k > 2 (§4.2, Figs 1–4). Open-access PDF via UvA
  DARE / pure.uva.nl.
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
