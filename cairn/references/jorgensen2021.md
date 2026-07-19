# jorgensen2021 — Absolute-error components in SEM-GT (the O-SEM source)

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/jorgensen2021.pdf` (gitignored).
Pagination: printed journal pages 113–133.
Extraction: unverified — first pass, values not yet re-read against the source — observed 2026-07-18.

**Citation.** Jorgensen TD (2021). "How to estimate absolute-error components in
structural equation models of generalizability theory." *Psych* 3(2):113–133.
DOI 10.3390/psych3020011. Open access (CC BY). Sole author. Received 10 April
2021; accepted 26 May 2021; published 29 May 2021.

**Role.** The **O-SEM** oracle source (`ORACLES.md`) — the primary source (IP1)
for the lavaan engine's *absolute agreement* estimator. Eq. 6 is what
`components$rater` computes.

**Pagination.** Anchors below are the **printed journal pages 113–133**, which
appear in this PDF's running header. PDF file pages run 1–21 (add 112).

## The problem the paper solves (pp. 113–114)

Prior SEM-GT work estimated only *relative* error, giving G-coefficients. Absolute
error additionally needs the variance of the **facet main effects** (e.g. σ²_i),
which "cannot be specified as SEM parameters simultaneously with relative-error
variance components" (p. 114). The prior workaround was to fit a second SEM to a
**transposed** data matrix — described as "laborious" and "cumbersome", and
infeasible when there are more subjects than measurement conditions (p. 114,
quoting Ark). The paper's contribution: get σ²_i from the **mean structure** of
the *same* SEM, as a function of estimated parameters.

## The one-facet design and its coefficients (pp. 115–116)

`p × i` decomposition, Eq. 1 (p. 115):
`Y_pi = μ + β_p + β_i + β_pi`, with total variance Eq. 2:
`σ²_Y = σ²_p + σ²_i + σ²_pi`.

- **Relative error → G-coefficient, Eq. 3 (p. 115):**
  `G-coef_{p×i} = ICC(C, n_i) = σ²_p / (σ²_p + σ²_pi/n_i)`
  — noted as equivalent to coefficient α, since Eq. 1 is consistent with
  essential tau-equivalence (p. 115).
- **Absolute error → D-coefficient, Eq. 4 (p. 115):**
  `D-coef_{p×i} = ICC(A, n_i) = σ²_p / (σ²_p + (σ²_i + σ²_pi)/n_i)`

The paper itself supplies the ICC(C,·)/ICC(A,·) mapping — this is not the repo's
interpolation. A cut-score-specific D-coef adds `(μ − cut)²` to numerator and
denominator (Eq. 5, p. 116), collapsing to Eq. 4 when `cut = μ`.

## Equation 6 (p. 117) — the load-bearing result

The CFA is specified with **effects-coding identification** on the mean
structure: the indicator intercepts are estimated under the constraint that their
average is zero (Table 1, top row, p. 117: `Σ_{m=1}^{n_i×n_o} ν_m = 0`), which
lets the factor mean be freely estimated as the grand mean μ. Consequently "an
item intercept (ν_i) is the difference between the item mean (μ_i) and the grand
mean (μ), so the intercepts are the item effects" (p. 117).

Therefore the estimated facet-main-effect variance is **the sample variance of
the estimated intercept vector ν**:

  `σ̂²_i = (1/(n_i − 1)) · Σ_{i=1}^{n_i} ν̂²_i`   **(Eq. 6, p. 117)**

Two properties the package depends on, both as printed:

- The divisor is **`n_i − 1`**, matching the repo's `σ²_r = Σν²/(k−1)`.
- It is the **raw** sample variance of the intercepts — **no bias correction is
  applied or mentioned anywhere in the paper**. (Independently corroborated by
  Lee & Vispoel 2024, Eqs. 8/25, per `BIBLIOGRAPHY.md`.)

Eq. 6 "can be used to define a new parameter in SEM software syntax such as
*Mplus* or `lavaan`" (p. 117), which is exactly how the package's engine reads it.

## Extensions (pp. 117–121)

Two-facet crossed `p × i × o`: Eq. 7 (decomposition), Eq. 8 (seven-component
variance), Eq. 9 (G-coef), Eq. 10 (cut-score D-coef) — pp. 117–118. The
mean-structure variances become Eqs. 11–13 (p. 120): σ̂²_i and σ̂²_o from the
**common-factor means** α̂ (divisors `n_i − 1`, `n_o − 1`), and σ̂²_io from the
indicator intercepts with divisor `(n_i × n_o) − 1`. Two-facet nested
`p × (i : o)`: Eqs. 14–17 (pp. 120–121).

Table 1 (p. 117) is the full grid of mean-structure identification constraints
required per design (`p × i`, `p × i × o`, `p × (i : o)`, plus the ordinal/LRV
threshold rows).

## Table 2 (p. 124) — published reference values

Simulated `semTools::exLong` data, N = 200 subjects, 3 items × 3 occasions.
Normal / observed-scale rows:

| Design | Estimator | G | D | D-Cut |
|---|---|---|---|---|
| p × i | MS | 0.834 | 0.783 | 0.966 |
| p × i | REML | 0.834 | 0.783 | 0.966 |
| p × i | ML (lavaan) | 0.834 | 0.782 | 0.968 |
| p × i × o | MS | 0.737 | 0.629 | 0.956 |
| p × i × o | REML | 0.737 | 0.629 | 0.956 |
| p × i × o | ML (lavaan) | 0.737 | 0.626 | 0.959 |
| p × (i : o) | MS | 0.794 | 0.728 | 0.970 |
| p × (i : o) | REML | 0.794 | 0.728 | 0.970 |
| p × (i : o) | ML (lavaan) | 0.794 | 0.712 | 0.969 |

**The SEM-vs-mixed-model gap is documented by the paper itself** (p. 124): the
mixed-model framework gives identical estimates under least-squares or REML "to
the 5th decimal place", and SEM gives identical estimates under least-squares or
ML; but the two *frameworks* "differ in the second or third decimal place because
the discrepancy functions differ" — mixed models minimize with respect to each
row of data (observed vs. predicted casewise scores), SEM with respect to summary
statistics (observed vs. predicted means and covariance matrix). Note in Table 2
that **G (consistency) agrees exactly across frameworks while D (agreement) does
not** — precisely the two-regime structure `ORACLES.md` O-SEM records.

## Confidence intervals (pp. 114, 124)

The paper obtains **delta-method** normal-theory CIs by defining the coefficients
as new `lavaan` parameters, but warns the delta method "relies on asymptotic
theory" and "can yield poor coverage and inflated Type I errors in small or
modest samples" (p. 114). It therefore also demonstrates **Monte Carlo CIs**
(`semTools::monteCarloCI()`), "a more robust method because it only assumes the
estimated parameters (not complex functions of parameters) have normal sampling
distributions" (p. 114), which "involves simulating a joint sampling distribution
of the parameter estimates (like a parametric bootstrap procedure)" (p. 124).

## The multirater planned-missing example (§4, pp. 125–127)

Real data: 6 physician-faculty raters, 29 first-year residents, ACP-CAT
communication skills, 2 task conditions; each subject rated by **2 of the 6**
raters ((6×5)/2 = 15 rater pairs randomly assigned) (p. 125). Coverage of the
covariance matrix was "quite low": 34.5% for diagonal cells, 6.9% for
between-rater covariances, and **0%** for between-task covariances (p. 126).

Results for the Task-1 `p × r` design (p. 126): **G-coef = 0.905, Monte Carlo 95%
CI [0.833, 0.951]** — stated to be "an IRR coefficient equivalent to ICC(C,2)";
**global D-coef = 0.821, 95% CI [0.675, 0.890]** — "equivalent to ICC(A,2) for
IRR". `gtheory`'s REML estimates were close: G-coef = 0.900, D-coef = 0.835
(p. 126, Fig. 4). The properly specified two-facet SEM **did not converge** under
FIML on these data (p. 126).

## The paper's own SEM-vs-mixed-model verdict (§5.2, pp. 128–129)

Directly relevant to the package's engine hierarchy (glmmTMB default, lavaan
alternate): sparse planned-missing designs produce estimation problems "due only
to using wide-format data with the SEM approach", and — quoted (p. 129) — "the
mixed-model approach would be preferable to estimate variance components" when
SEM becomes infeasible for modeling GT. The Conclusions repeat it (pp. 129–130):
SEM is "potentially infeasible with certain PMD designs, but the limiting factors
would be irrelevant using (generalized) linear mixed models".

## Traces to

- **O-SEM** (`ORACLES.md`) — Eq. 6 is the in-test reproduced formula
  (`components$rater` = Σ(mean_j − grand)²/(k−1)); `tests/testthat/test-icc-lavaan.R`,
  `test-ci-bootstrap.R`.
- The **two-regime** O-SEM structure (consistency ≡ glmmTMB exactly; agreement a
  distinct estimator) — sourced by the p. 124 discrepancy-function paragraph.
- The removal of the earlier **unsourced bias correction** (ADR-014): Eq. 6 is
  raw, and the paper applies no correction.
- The **Monte-Carlo-over-delta-method** posture (`PRINCIPLES.md` #3, ADR-003) —
  independently argued here at p. 114.
- The lavaan **FIML** route for incomplete data (M21 Slice 3, O-FIML) and its
  documented limits (§5.2).
- `cairn/references/sem-multilevel-pilot.md` (D-005), which composes this
  mean-structure device with two-level SEM.

## Open questions

- **The facet is items; the package's is raters.** The main development (Eqs.
  1–17) is written for items and occasions. The rater mapping is *not* the repo's
  invention — §4 applies the same machinery to a `p × r` design and names the
  results ICC(C,2)/ICC(A,2) (p. 126) — but note that §4 is the paper's
  *limitations* example, not its worked demonstration. Sourcing is sound; the
  emphasis is worth knowing.
- **No estimator for a *fixed*-rater θ²_r here.** Eq. 6 is a random-facet
  variance. The package's fixed-rater SEM path (M21 Slice 2, O-FSEM) applies a
  Case-3A bias correction that comes from `mcgraw1996`, not from this paper —
  consistent with `ORACLES.md`, recorded so the two are not conflated.
- **Table 2 is not currently an oracle.** Its published G/D values (N = 200,
  3 items × 3 occasions, `semTools::exLong`) are reproducible reference values in
  a design the package does not fit (two-facet items × occasions). Recorded as a
  *candidate* frozen oracle if a two-facet path is ever built — not proposed now,
  and no existing oracle value is affected.
- No disagreement with any `ORACLES.md` value was found; Eq. 6's `(k−1)` divisor
  and the absence of a bias correction both check out as printed.
