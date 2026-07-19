# bartko1966 — the ICC as reliability: one-way vs. two-way, and why the model choice is not cosmetic

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/bartko1966.pdf` (gitignored).
Pagination: printed journal pages 3–11; the 9 PDF pages map one-to-one onto printed 3–11.
Extraction: verified 2026-07-19 against the source (all 9 PDF pages read through the reference list and the closing "Accepted March 14, 1966" line); every mean square and all four printed ICCs were additionally recomputed from the Table 3A raw data and agree exactly — observed 2026-07-19.

**Citation.** Bartko, J. J. (1966). "The Intraclass Correlation Coefficient as a
Measure of Reliability." *Psychological Reports* 19, 3–11. Running header printed
as "Psychological Reports, 1966, 19, 3-11. © Southern Universities Press 1966".
**No DOI and no issue number are printed anywhere in the article**; the author
affiliation is given only as "National Institute of Mental Health".

**Role.** The package's intellectual prehistory for the one-way / two-way
distinction, and the origin of the argument that an ICC is only interpretable as
a *correlation* when the denominator carries the full variance of an observation
under the assumed model. **No oracle value traces here** — nothing in
`ORACLES.md` cites it, and no test reads it. It is a guidance/provenance source,
cited by three sibling notes (see Traces to). What it *could* source is recorded
under "What this could source" below.

## The three models and their ICC formulas

Bartko's thesis, stated p. 3: the ICC formula "most frequently and commonly used
is correct only for the case where the underlying model assumed is the one-way
random effects model", and for the two-way classification "the assumptions of the
underlying model and the use of the ICC formula are frequently violated".

**One-way random** (model [1], p. 3): `x_ij = μ + p_i + e_ij`, `i = 1…n`
persons, `j = 1…k` raters. ANOVA in Table 2 (p. 4) — Persons `n−1`, `MSP`,
`EMS = σ_e² + kσ_p²`; Error `n(k−1)`, `MSE`, `EMS = σ_e²`; Total `nk−1`.

- `ρ = σ_p²/(σ_p² + σ_e²)` — Eq. [2], p. 4.
- `R = (MSP − MSE)/[MSP + (k−1)MSE]` — Eq. [3], p. 4.
- Interpretable as a correlation coefficient via Eqs. [4]–[7], pp. 4–5:
  `Cov(x_ij, x_il) = σ_p²` and `Var(x_ij) = σ_p² + σ_e²`, so the ratio [7] *is*
  the correlation between two observations on the same person.
- **Unequal numbers of ratings per person** are handled by replacing `k` in [3]
  with `k_0 = 1/(n−1) · [Σk_i − Σk_i²/Σk_i]` — Eq. [8], p. 5.
- Significance: `F = MSP/MSE` with `n−1` and `n(k−1)` df — Eq. [9], p. 5; for
  unequal numbers the df become `n−1` and `N−n`, `N` the total observations.

**Two-way random** (model [10], p. 6): `x_ij = μ + p_i + r_j + (pr)_ij + e_ij`.
ANOVA in Table 4 (p. 7) — Persons `n−1`, `EMS = σ_e² + σ_i² + kσ_p²`; Raters
`k−1`, `EMS = σ_e² + σ_i² + nσ_r²`; Error `(n−1)(k−1)`, `EMS = σ_e² + σ_i²`.

- `ρ = σ_p²/(σ_p² + σ_r² + σ_i² + σ_e²)` — Eq. [13], p. 7. Interpretable as a
  correlation "only, however, when all of the denominator variance components are
  considered" (p. 7).
- Component estimates, Eq. [14], p. 7: `σ̂_p² = (MSP − MSE)/k`,
  `σ̂_r² = (MSR − MSE)/n`, `σ̂_e² + σ̂_i² = MSE`.
- `R = (MSP − MSE)/[MSP + MSE(k−1) + k(MSR − MSE)/n]` — Eq. [15], p. 7.
- Bartko notes (p. 7) that this model "need not make any assumption about the
  presence or absence of interaction" to estimate the components, and the `F`
  test `MSP/MSE` on `n−1`, `(n−1)(k−1)` df needs no such assumption either.

**Two-way mixed** (model [16], p. 8), raters fixed. ANOVA in Table 6 (p. 9) —
Persons `EMS = σ_e² + kσ_p²`; Raters `EMS = σ_e² + σ_i² + nΣr_j²/(k−1)`; Error
`EMS = σ_e² + σ_i²`.

- `ρ = σ_p²/(σ_p² + σ_i² + σ_e²)` — Eq. [19], p. 9. An unconfounded estimate is
  available "only if interaction is absent" (p. 9).
- `R = (MSP − MSE + σ_i²)/[MSP + MSE(k−1) + σ_i²]` — Eq. [20], p. 9, which
  requires a value for `σ_i²` that a one-observation-per-cell design cannot
  supply.
- Bounds, Eqs. [21]–[24], pp. 9–10: `R[21] = (MSP − MSE)/[MSP + MSE(k−1)]`
  (interaction negligible) is a **lower** bound, `R[22] = MSP/(MSP + kMSE)`
  (obtained by substituting `MSE` for `σ_i²`, since `σ̂_i² ≤ MSE`) an **upper**
  bound, and `R[21] ≤ R[20] ≤ R[22]`. The monotonicity argument is Eq. [23]:
  `f(x) = (A − B + x)/[A + B(k−1) + x]` has `df(x)/dx ≥ 0`.

## The worked example (Ebel's data) — a hand-computable fixture

The same 4-subject × 2-rater data set is carried through all three models. Raw
data, Table 3A (p. 6): subject ratings `(3,3)`, `(1,5)`, `(5,6)`, `(4,7)`; rater
column sums 13 and 21; grand total 34.

| Analysis | Source | df | SS | MS | Anchor |
|---|---|---|---|---|---|
| One-way | Persons | 3 | 12.5 | 4.167 | Table 3B, p. 6 |
| One-way | Error | 4 | 13.0 | 3.250 | Table 3B, p. 6 |
| Two-way | Persons | 3 | 12.5 | 4.167 | Table 5B, p. 8 |
| Two-way | Raters | 1 | 8.0 | 8.000 | Table 5B, p. 8 |
| Two-way | Error | 3 | 5.0 | 1.667 | Table 5B, p. 8 |
| both | Total | 7 | 25.5 | — | Tables 3B/5B |

Resulting coefficients, quoted as printed:

- **One-way**, p. 6: "`R = (4.167 − 3.250)/(4.167 + 3.250) = 0.1236`"; `F = 1.28`,
  "nonsignificant (`p > 0.25`)".
- **Two-way random**, p. 8: "`R = (4.167 − 1.667)/[4.167 + 1.667 + 2(8.000 −
  1.667)/4] = 0.2778`"; `F = 2.50`, "nonsignificant (`p > 0.10`)".
- **Two-way mixed lower bound** `R[21]`, p. 10: `(4.167 − 1.667)/(4.167 + 1.667)
  = 0.4286`; upper bound `R[22] = 0.5555`.

Bartko observes (p. 10) that `R[21] = 0.4286` "is the same value obtained by Ebel
(1)" — Ebel reached it by running a two-way ANOVA and then applying the *one-way*
formula [3], i.e. dropping the `k(MSR − MSE)/n` term. Bartko's objection (pp. 7–8)
is not that 0.4286 is arithmetically wrong but that under a two-way *random*
model its denominator "does not reflect the true and total variance of the
observation", so it "cannot be interpreted as a correlation coefficient".

**Independent recomputation (M66, not the paper's arithmetic).** From the Table 3A
raw data: `ΣX² = 170`, correction `34²/8 = 144.5`, so `SST = 25.5`; person means
`3, 3, 5.5, 5.5` give `SSP = 12.5`; rater means `3.25, 5.25` give `SSR = 8.0`;
residual `13.0 − 8.0 = 5.0`. All four printed coefficients reproduce to the
printed precision. Recorded because it establishes the example is exactly
reconstructible from the printed data — see below.

## What this could source

Nothing in the package traces here today. Two things in this paper are
*available* to be sourced, and neither is claimed by any current oracle:

- **A closed-form / hand-computed oracle fixture.** The 4×2 example above yields
  one-way `0.1236`, two-way-random `0.2778`, and two-way-fixed `0.4286` from nine
  integers, all reconstructible by hand (verified above). It is far smaller than
  the `shrout1979` Table 2 example that currently backs **O1**, which makes it a
  candidate *second* deterministic fixture rather than a replacement — its value
  would be as an independent small-`n` check, and its weakness is that at
  `n = 4, k = 2` it exercises no boundary behavior.
- **The unequal-`k` adjustment `k_0`** (Eq. [8], p. 5) for the one-way design.
  The package's one-way path handles unbalanced data through the mixed-model
  engines rather than a moment adjustment, so this is a cross-check on that path,
  not a specification of it.

Neither is proposed here — M66 writes notes, not code (Scope).

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page. Three
sibling `references/` notes cite the paper:

- `cairn/references/tenhove2024.md:95–97` — quotes Bartko's advice that ICC use
  "should be restricted by the underlying model which most adequately describes
  the experimental situation", which ten Hove et al. (2024) invoke against
  treating incomplete data as complete. **Verified verbatim here, p. 3.**
- `cairn/references/xiao2013.md:52–54` — attributes the moment estimator of
  Xiao's Eq. (4) jointly to Rajaratnam (1960) and Bartko (1966).
- `cairn/references/shrout1979.md:163` — cites Bartko's *1976* position (the
  sibling paper, `bartko1976.md`), not this one.
- `cairn/references/BIBLIOGRAPHY.md` (Bartko 1966 entry) and `INDEX.md`.

## Open questions

- The paper's `σ_i²` (interaction) and `σ_e²` (error) are **not separately
  identified** in any of its designs — Table 4 and Table 6 both give the error
  line `EMS = σ_e² + σ_i²`, and Bartko works with the sum throughout. A reader
  mapping this notation onto the package's components should treat Bartko's
  "error" line as the residual, not as a pure measurement error term.
