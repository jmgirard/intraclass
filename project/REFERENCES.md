# References & oracle registry

Bibliography plus the registry of oracle values used in tests. **Every oracle
value in the test suite must trace back to an entry here** with provenance — a
citation or a committed, seeded script (PRINCIPLES.md #4, #12). No unsourced
reference values, ever.

---

## Oracle registry

### Oracle O1 — Shrout & Fleiss (1979) worked example
- **Used by:** `tests/testthat/test-icc-twoway-agreement.R`
  (data + values in `tests/testthat/helper-shrout-fleiss.R`).
- **Primary source:** Shrout, P. E., & Fleiss, J. L. (1979). Intraclass
  correlations: uses in assessing rater reliability. *Psychological Bulletin,
  86*(2), 420–428.
- **Design:** balanced, complete; 6 subjects × 4 raters, integer ratings.
- **Independent cross-checks (identical to printed precision):** `psych::ICC()`
  (Revelle) and `DescTools::ICC()` (Signorell et al.).
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
  1e-4). ICC(1)/ICC(k) recorded for later milestones.

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

### Oracle O4 — fixed ≡ random raters on balanced data (M2)
- **Status:** **asserted (M2)** in `tests/testthat/test-icc-consistency.R`
  ("fixed and random raters give identical estimates and CIs"): for both
  agreement and consistency, `raters = "fixed"` reproduces `raters = "random"`
  point estimates and the seeded Monte-Carlo interval exactly (same shared fit,
  ADR-006).
- **Provenance (engine-level derivation):** `data-raw/oracle-fixed-vs-random.R`
  fits raters as a random intercept vs. as fixed effects (`lmer`) and shows
  identical σ²_s/σ²_res on the balanced SF data (|Δσ²_s| ≈ 7e-6), matching ANOVA
  MoM and `psych::ICC` ICC3/ICC3k. The same script demonstrates the equivalence
  **breaks under imbalance** (drop 4 of 24 cells ⇒ ΔICC(C,1) ≈ 0.0095), the M3
  caveat behind ADR-006. Reproducible; nothing hardcoded.

### Cross-engine oracle — lme4 (independent implementation)
- **Status:** **asserted (M1)** in `tests/testthat/test-icc-engine-oracle.R`:
  `lme4::lmer` fit directly reproduces the glmmTMB engine's point ICCs to 1e-4 on
  the balanced O1 data (ADR-002/005 — lme4 is oracle-only in M1).

---

## Bibliography

- Brennan, R. L. (2001). *Generalizability Theory.* Springer.
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400.
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979.
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of
  connectedness in an N-way cross classification. *Technometrics, 6*(3), 319–324.
