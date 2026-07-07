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
  Fleiss ICC(2,·); ICC(C,·) ≡ ICC(3,·).
- **M1 scope:** only ICC(A,1)=0.290 and ICC(A,k)=0.620 are asserted; the rest are
  recorded for later milestones.

### Oracle O2 — ANOVA mean-squares (package-independent, hand-derived)
- **Status:** registered; to be asserted in M1 as the third oracle type.
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
- **Status:** to be authored in M1 (its own test file), seeded per PRINCIPLES.md
  #12. Draw data from a known (σ²_s, σ²_r, σ²_res), fit, and confirm recovery of
  the population ICC within tolerance across replications.

---

## Bibliography

- Brennan, R. L. (2001). *Generalizability Theory.* Springer.
- Brooks, M. E., et al. (2017). glmmTMB balances speed and flexibility among
  packages for zero-inflated generalized linear mixed models. *The R Journal,
  9*(2), 378–400.
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979.
