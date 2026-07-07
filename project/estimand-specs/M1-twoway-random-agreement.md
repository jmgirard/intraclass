# Estimand specification — M1: two-way random, absolute agreement

**Scope of this document.** The precise population definitions the Milestone 1
estimators must target: `ICC(A,1)` and `ICC(A,k)` for a **two-way random**
design, **absolute agreement**, computed from a linear mixed model. This is the
spec that the M1 oracle tests (`test-icc-twoway-agreement.R`) encode; the code
must satisfy both. Consistency ICCs, fixed raters, and incomplete designs are
**out of M1 scope** and appear here only for contrast and forward-compatibility.

Everything below is verified two ways: (a) the population definitions reduce
algebraically to the Shrout & Fleiss (1979) sample estimators, and (b) the
hand-computed ANOVA of the Shrout–Fleiss worked example reproduces the published
values 0.290 and 0.620. The worked numbers are in §6.

---

## 1. Measurement model

For subject (target) *i* = 1…*n* rated once by rater (judge) *j* = 1…*k*, the
observed rating is decomposed as

```
x_ij = μ + s_i + r_j + (sr)_ij + e_ij
```

| Term | Meaning | Distribution |
|---|---|---|
| μ | grand mean (fixed) | — |
| s_i | subject (object-of-measurement) effect — the signal | s_i ~ N(0, σ²_s) |
| r_j | rater main effect (a rater's overall leniency/severity) | r_j ~ N(0, σ²_r) |
| (sr)_ij | subject × rater interaction | (sr)_ij ~ N(0, σ²_sr) |
| e_ij | residual measurement error | e_ij ~ N(0, σ²_e) |

All effects are mutually independent. **Two-way random** means both s_i and r_j
are random: the *k* raters are a sample from a rater universe we wish to
generalize to. (Contrast: two-way *mixed* treats raters as the entire fixed set
of interest — same point-estimate formula, different generalization and
inference. That distinction is an M2+ concern; M1 is explicitly the random case,
matching Shrout–Fleiss Case 2.)

### Identifiability (critical)

With a **single rating per subject×rater cell** — the M1 data shape — the
interaction σ²_sr and the pure error σ²_e are **not separately identified**.
Only their sum is estimable:

```
σ²_res  ≡  σ²_sr + σ²_e        (the residual / "within-cell" variance)
```

The M1 mixed model therefore estimates exactly three components: σ²_s, σ²_r,
σ²_res. Separating σ²_sr from σ²_e requires replicate ratings within a cell
(a `(1 | subject:rater)` term), which is deferred. The estimand definitions in
§2 are written with all four components for clarity, then given in the estimable
(three-component) form the code actually uses.

---

## 2. Estimands (population definitions)

Both are ratios of the subject (signal) variance to signal-plus-error, where
**absolute agreement** counts the rater main effect σ²_r as error (disagreement
in absolute level is unreliability), unlike consistency, which does not.

### ICC(A,1) — single rater, absolute agreement

Reliability of **one** randomly chosen rater's rating as a measure of the
subject's universe score:

```
                       σ²_s
ICC(A,1) = ───────────────────────────────
            σ²_s + σ²_r + σ²_sr + σ²_e

                       σ²_s
         = ───────────────────────────      (estimable, single-rating design)
            σ²_s + σ²_r + σ²_res
```

### ICC(A,k) — mean of k raters, absolute agreement

Reliability of the **mean** of *k* randomly chosen raters. Averaging over *k*
raters divides every error component (rater, interaction, error) by *k*; the
signal σ²_s is unchanged:

```
                          σ²_s
ICC(A,k) = ─────────────────────────────────────
            σ²_s + (σ²_r + σ²_sr + σ²_e) / k

                          σ²_s
         = ──────────────────────────────       (estimable form)
            σ²_s + (σ²_r + σ²_res) / k
```

Equivalently, in generalizability-theory terms, the denominator's second term is
the **absolute error variance** of a *k*-rater decision study,
σ²_Δ = (σ²_r + σ²_sr + σ²_e) / k. `ICC(A,k)` is the dependability coefficient Φ
for absolute decisions. This GT reading is the one the package teaches.

### Range

With REML (the M1 engine) all variance components are constrained ≥ 0, so both
coefficients lie in **[0, 1]** and can equal 0. (Method-of-moments/ANOVA
estimates can go negative and are conventionally truncated at 0; the mixed-model
engine avoids this, which is one reason it is the default.)

---

## 3. Estimation via the mixed model

Fit, by REML:

```r
score ~ 1 + (1 | subject) + (1 | rater)
```

Extract the variance components (e.g. from `lme4::VarCorr()` /
`glmmTMB::VarCorr()`):

| Component | Source in the fitted model |
|---|---|
| σ²_s | `subject` random-intercept variance |
| σ²_r | `rater` random-intercept variance |
| σ²_res | residual variance (= σ²_sr + σ²_e, confounded in single-rating data) |

Then apply the §2 estimable formulas. **Do not** hand-build ANOVA mean squares;
the whole point of the mixed-model engine is that the same three components are
estimated correctly for unbalanced/incomplete data, where the §4 ANOVA identities
no longer hold. (If replicate ratings exist, add `(1 | subject:rater)` to split
σ²_sr from σ²_e; the estimand is unchanged because absolute-agreement error still
sums them.)

---

## 4. Relationship to the classical ANOVA estimators

For **balanced, complete** data the REML components equal the ANOVA
method-of-moments components, so the M1 estimates coincide **exactly** (to
numerical precision) with the Shrout & Fleiss (1979) sample formulas. With
BMS = between-subjects, JMS = between-raters, EMS = residual mean squares:

```
σ²_s   = (BMS − EMS) / k
σ²_r   = (JMS − EMS) / n
σ²_res = EMS
```

Substituting these into §2 recovers, algebraically,

```
ICC(A,1) = (BMS − EMS) / [ BMS + (k−1)·EMS + (k/n)·(JMS − EMS) ]   = SF ICC(2,1)
ICC(A,k) = (BMS − EMS) / [ BMS + (JMS − EMS)/n ]                   = SF ICC(2,k)
```

This equivalence is the reason the M1 oracle test can assert a near-exact match
to `psych::ICC` on balanced data — a loose match there is a bug, not tolerance.

---

## 5. Out of scope for M1 (recorded for forward-compatibility)

The estimator's internal representation should make these a change of which
components enter the denominator, not a rewrite:

- **Consistency**, ICC(C,·): drop the rater main effect from the error.
  `ICC(C,1) = σ²_s / (σ²_s + σ²_res)`;
  `ICC(C,k) = σ²_s / (σ²_s + σ²_res / k)`. *(M2)*
- **Fixed raters** (two-way mixed): same point estimate as the random case for a
  given form, but different generalization and interval. *(M2)*
- **One-way** ICC(1)/ICC(k): raters not crossed; error is everything non-subject
  pooled. *(later)*
- **Incomplete / unbalanced** designs: the §4 ANOVA identities fail; only the
  mixed-model path is valid. This is the framework's central advantage. *(M3)*

Design implication: represent an ICC as `(signal component, {error components})`
plus an averaging factor (1 or k), so A vs C and single vs average are choices of
the error set and the divisor — not separate code paths.

---

## 6. Worked verification (Shrout & Fleiss 1979 data)

Data: 6 subjects × 4 raters, one rating per cell (`sf_ratings_wide()`). Note the
raters differ sharply in mean level (J1≈7.67, J2=2.5, J3≈4.33, J4≈6.67), so the
rater variance is large and absolute agreement is much lower than consistency — a
good teaching case.

Hand-computed ANOVA (n = 6, k = 4):

| Quantity | Value |
|---|---|
| BMS (between subjects, df=5) | 11.24167 |
| JMS (between raters, df=3) | 32.48611 |
| EMS (residual, df=15) | 1.01944 |

Method-of-moments variance components (what REML should return on this balanced
set):

| Component | Value |
|---|---|
| σ²_s | 2.55556 |
| σ²_r | 5.24444 |
| σ²_res (= σ²_sr + σ²_e) | 1.01944 |

Resulting coefficients:

```
ICC(A,1) = 2.55556 / (2.55556 + 5.24444 + 1.01944) = 2.55556 / 8.81944 = 0.28976   → 0.290 ✓
ICC(A,k) = 2.55556 / (2.55556 + (5.24444 + 1.01944)/4) = 2.55556 / 4.12153 = 0.62017 → 0.620 ✓
```

Cross-check (contrast form, consistency): σ²_s/(σ²_s + σ²_res) = 2.55556/3.575 =
0.71484 → 0.715, matching the published ICC(C,1). This confirms σ²_r (=5.24) is
exactly the term absolute agreement adds to the error and consistency omits.

These three mean squares are the promised **third, package-independent oracle**
(hand-derived from the ANOVA identity, not another R package). They can be added
to `helper-shrout-fleiss.R` and asserted directly against the mixed model's
`VarCorr()` on balanced data.

---

## 7. Acceptance criteria (this estimand → code)

- On `sf_ratings_long()`: `ICC(A,1)` rounds to 0.290 and `ICC(A,k)` to 0.620,
  and matches `psych::ICC` to tolerance 1e-4 (balanced ⇒ near-exact).
- `VarCorr()` on the fit yields σ²_s ≈ 2.556, σ²_r ≈ 5.244, σ²_res ≈ 1.019.
- Both coefficients lie in [0, 1]; `ICC(A,k) > ICC(A,1)` (Spearman–Brown).
- The estimand (signal, error set, divisor) is documented in the function's
  roxygen "which ICC / when" note, including the single-rating identifiability
  caveat.

---

## 8. Decision guidance (teaching note for the docs/vignette)

- Use **absolute agreement** (A) when the *value* matters — raters must agree on
  the actual number (e.g. clinical scores, measurements). Use **consistency**
  (C) when only rank order matters and a constant rater offset is acceptable.
- Use **ICC(A,1)** to report the reliability of a *single* rater's score; use
  **ICC(A,k)** when the *mean* of your *k* raters is the score you will actually
  use downstream.
- A large gap between ICC(C,·) and ICC(A,·) (as here, 0.715 vs 0.290) signals big
  systematic rater differences in level — a rating-procedure problem worth fixing
  before using the ratings.

---

## References

- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in
  assessing rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines
  on selecting an ICC for interrater reliability… *Psychological Methods, 29*(5),
  967–979.
