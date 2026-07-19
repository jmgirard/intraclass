# shrout1979 — The six ICC forms and the O1 worked example

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/shrout1979.pdf` (gitignored).
Pagination: printed journal pages 420–428.
Extraction: unverified — first pass, values not yet re-read against the source — observed 2026-07-18.

**Citation.** Shrout PE, Fleiss JL (1979). "Intraclass correlations: uses in
assessing rater reliability." *Psychological Bulletin* 86(2):420–428.

**Role.** The **O1** oracle source (`ORACLES.md`) — the worked example whose data
and coefficients seed the whole ICC family in this package — and the origin of
the `ICC(1,1)`/`ICC(2,1)`/`ICC(3,1)` naming the package bridges to McGraw & Wong
labels (see `mcgraw1996.md`).

## The three cases (pp. 420–422)

A reliability (G) study of *n* targets rated by *k* judges. Three designs:

- **Case 1** (p. 421, Eq. 1): `x_ij = μ + b_j + w_ij` — each target rated by a
  *different* set of *k* judges. One-way random; judge and interaction effects
  are not separable. Package: one-way / `ICC(1)`.
- **Case 2** (p. 421, Eq. 2): `x_ij = μ + a_i + b_j + (ab)_ij + e_ij` with `a_i`
  **random**, `a_i ~ N(0, σ²_J)`. Two-way random. Package: `ICC(A,·)`.
- **Case 3** (p. 422): same Eq. 2, but `a_i` is a **fixed** effect subject to
  `Σa_i = 0`, so `σ²_J = θ²_J = Σa_i²/(k−1)`, and the interaction components
  satisfy `Σ_i (ab)_ij = 0` for each target. Two-way mixed. Package: `ICC(C,·)`.

Under Case 3 the interaction correlates *negatively* across judges on the same
target (p. 422, Eq. 3: `c = −σ²_I/(k−1)`), so the Case-3 population parameter is

  `ρ = (σ²_T − σ²_I/(k−1)) / (σ²_T + σ²_I + σ²_E)`   (p. 423)

which **can be negative** — the paper flags this explicitly (p. 422, crediting
Sitgreaves 1960). Relevant to the boundary-fit policy (`DESIGN.md`).

## Mean-square expectations (Table 1, p. 421)

| Source | df | MS | Case 1 EMS | Case 2 EMS | Case 3 EMS |
|---|---|---|---|---|---|
| Between targets | n−1 | BMS | kσ²_T + σ²_W | kσ²_T + σ²_I + σ²_E | kσ²_T + σ²_E |
| Within target | n(k−1) | WMS | σ²_W | — | — |
| Between judges | k−1 | JMS | — | nσ²_J + σ²_I + σ²_E | nθ²_J + fσ²_I + σ²_E |
| Residual | (n−1)(k−1) | EMS | — | σ²_I + σ²_E | fσ²_I + σ²_E |

with `f = k/(k−1)` for the three Case-3 entries (Table 1 footnote a, p. 421).

## Estimator formulas (pp. 423, 426)

Single-rating forms (p. 423):

- `ICC(1,1) = (BMS − WMS) / (BMS + (k−1)·WMS)`
- `ICC(2,1) = (BMS − EMS) / (BMS + (k−1)·EMS + k(JMS − EMS)/n)`
- `ICC(3,1) = (BMS − EMS) / (BMS + (k−1)·EMS)`

Average-rating forms (p. 426):

- `ICC(1,k) = (BMS − WMS) / BMS`
- `ICC(2,k) = (BMS − EMS) / (BMS + (JMS − EMS)/n)`
- `ICC(3,k) = (BMS − EMS) / BMS`

`ICC(3,k)` is noted as equivalent to Cronbach's (1951) alpha, and to KR-20 for
dichotomous ratings (p. 426).

## Confidence intervals (pp. 424, 426)

- `ICC(1,1)`: exact F. `F_o = BMS/WMS`; Eqs. 4–5 give `F_U`, `F_L`; Eq. 6 gives
  the interval `(F_L−1)/(F_L+k−1) < ρ < (F_U−1)/(F_U+k−1)`.
- `ICC(2,1)`: **approximate** — a Satterthwaite (1946) construction from Fleiss &
  Shrout (1978), with `ν` and the interval given as Eq. 7 (p. 424). The paper is
  explicit that this form is harder because the index is a function of three
  independent mean squares.
- `ICC(3,1)`: exact F on `F_o = BMS/EMS`, Eqs. 8–9 (p. 424).
- Average forms (p. 426): `1 − 1/F_L < ρ < 1 − 1/F_U` for `ICC(1,k)` and
  `ICC(3,k)`; `ICC(2,k)` via the Spearman–Brown transform of the `ICC(2,1)`
  bounds, `ρ_L** = kρ_L*/(1 + (k−1)ρ_L*)`.

## Table 2 — the O1 data (p. 423), verbatim

"Four Ratings on Six Targets" — rows are targets 1–6, columns judges 1–4:

| Target | J1 | J2 | J3 | J4 |
|---|---|---|---|---|
| 1 | 9 | 2 | 5 | 8 |
| 2 | 6 | 1 | 3 | 2 |
| 3 | 8 | 4 | 6 | 8 |
| 4 | 7 | 1 | 2 | 6 |
| 5 | 10 | 5 | 6 | 9 |
| 6 | 6 | 2 | 4 | 7 |

Matches `tests/testthat/helper-shrout-fleiss.R` `sf_ratings_wide()` exactly,
including orientation (n = 6 targets × k = 4 judges).

## Table 3 — ANOVA for the example (p. 423)

| Source | df | MS |
|---|---|---|
| Between targets | 5 | 11.24 |
| Within target | 18 | 6.26 |
| Between judges | 3 | 32.49 |
| Residual | 15 | 1.02 |

Agrees with oracle **O2** (`ORACLES.md`) to the printed precision:
BMS 11.24167 → 11.24, JMS 32.48611 → 32.49, EMS 1.01944 → 1.02. (WMS = 6.26 is
printed here but not carried in O2.)

## Table 4 — the O1 coefficients (p. 424)

"Estimates From Six Intraclass Correlation Forms", **printed to two decimals**:

| Form | Estimate (as printed) | O1 registry value | Package label |
|---|---|---|---|
| ICC(1,1) | .17 | 0.166 | ICC(1) |
| ICC(2,1) | .29 | 0.290 | ICC(A,1) |
| ICC(3,1) | .71 | 0.715 | ICC(C,1) |
| ICC(1,4) | .44 | 0.443 | ICC(k) |
| ICC(2,4) | .62 | 0.620 | ICC(A,k) |
| ICC(3,4) | .91 | 0.909 | ICC(C,k) |

Every printed value is the correct 2-dp rounding of the **underlying** quantity —
**no oracle value is contradicted**. Round from the unrounded value, not from the
registry's 3-dp figure: `ICC(3,1)` is 0.71484 (O2's mean-square chain), which is
0.715 at 3 dp and **.71** at 2 dp, whereas re-rounding the 3-dp 0.715 would give
.72. The registry's 3-dp column and the paper's 2-dp column are both roundings of
the same quantity, not of each other. See Open questions for the
precision-provenance caveat.

## Other results the package touches

- **Reliability of a mean** (p. 426): the mean-rating reliability "will always be
  greater in magnitude" than the single-rating reliability, provided the latter
  is positive.
- **Number of raters needed for a target reliability** (p. 426) — the `d_study()`
  ancestor. Given a lower bound `ρ_L` from Ineq. 6 or 7 and a minimum acceptable
  `ρ*`, take *m* as the smallest integer ≥
  `m = ρ*(1 − ρ_L) / (ρ_L(1 − ρ*))`.
- **Misuse warning** (p. 424): applying `ICC(1,1)` to Case-2/Case-3 data
  under-estimates the true correlation — on average it gives smaller values than
  `ICC(2,1)` or `ICC(3,1)`.
- **Consistency vs. agreement** (p. 425): the paper records Bartko's (1976)
  position that consistency is never an appropriate reliability concept for
  raters, Algina's (1978) objection, and rejects the blanket restriction — the
  choice turns on whether judge mean differences matter to the application.

## Traces to

- **O1** (`ORACLES.md`) — data + all six coefficients;
  `tests/testthat/helper-shrout-fleiss.R`, `test-icc-twoway-agreement.R`,
  `test-icc-consistency.R`, `test-icc-oneway.R`.
- **O2** — the Table 3 mean squares the hand-derived ANOVA oracle reproduces.
- The Case 1/2/3 vocabulary behind `choosing-an-icc.Rmd` and the
  `ICC(A,·)`/`ICC(C,·)` notation bridge (see `mcgraw1996.md`).
- The Case-3 negative-population-ICC note, relevant to `DESIGN.md
  § Boundary-fit policy`.

## Open questions

- **Precision provenance (M64/T1 finding, not an oracle change).** Table 4 prints
  only two decimals, but `ORACLES.md` O1 and `helper-shrout-fleiss.R` carry three
  (0.166, 0.290, 0.715, 0.443, 0.620, 0.909) and the helper header describes them
  as "the published Shrout & Fleiss numbers to three decimals". The 3-dp values
  are not printed anywhere in this paper; they come from the `psych::ICC()` /
  `DescTools::ICC()` recomputations also recorded in that header. The **values
  agree** at the paper's precision, so no oracle value changes; what is
  inaccurate is the attribution of the third decimal. Raised for the review gate
  (AC3) as a wording fix to the helper header, not a value correction.
