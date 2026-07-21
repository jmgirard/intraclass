# fleiss1973 — Weighted kappa ≡ the intraclass correlation coefficient

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/fleiss1973.pdf` (gitignored).
Pagination: printed journal pages 613–619.
Extraction: verified 2026-07-18 against the source (all 7 PDF pages = printed 613–619, read through the reference list) by M69; every equation (1–15), page anchor, and quoted phrase confirmed with no correction needed, including the "no worked example anywhere in the paper" claim — observed 2026-07-18.

**Citation.** Fleiss JL, Cohen J (1973). "The equivalence of weighted kappa and
the intraclass correlation coefficient as measures of reliability."
*Educational and Psychological Measurement* 1973, 33, 613–619. (The title page
runner prints only volume and pages — no issue number and no DOI appear on the
PDF.)

**Role.** Shelf / background evidence for the categorical-scale boundary of the
ICC — the bridge between kappa-family agreement indices and the ICC. Not an
oracle source.

## Weighted kappa as defined here (p. 614, Eqs. 1–3)

Two raters A and B each classify the same *n* subjects into *m* categories.
`n_ij` = count assigned to *i* by A and *j* by B; `n_i.`, `n_.j` the marginals;
`v_ij` the **disagreement** weight, with `v_ii = 0` and `v_ij > 0` for `i ≠ j`.

- Observed mean disagreement (Eq. 1): `D̄_o = (1/n) ΣΣ n_ij v_ij`
- Chance-expected mean disagreement (Eq. 2): `D̄_e = (1/n²) ΣΣ n_i. n_.j v_ij`
- Weighted kappa (Eq. 3): `κ_w = (D̄_e − D̄_o) / D̄_e`

Unweighted kappa is the special case `v_ij = 1` for all `i ≠ j` (p. 614). The
disagreement-weight formulation is stated to be harmless because weighted kappa
is invariant under linear transformations of the weights (p. 614, crediting
Cohen 1968a).

## The equivalence result (p. 615)

Prior results the paper builds on (p. 615): for a 2×2 table **with the same
marginal distributions**, kappa equals the phi coefficient (Cohen 1960); for a
general `m × m` table **with identical marginals** (`n_i. = n_.i`) and
`v_ij = (i − j)²`, weighted kappa equals the product-moment correlation when
categories are scored 1, 2, …, *m* (Cohen 1968a) — valid "only when the
categories may be ordered" (p. 615).

The paper's own, more general claim (p. 615), stated in its terms: if
`v_ij = (i − j)²` and the categories are scaled 1, 2, …, *m*, then
**irrespective of the marginal distributions**, weighted kappa is identical with
the intraclass correlation coefficient "in which the mean difference between the
raters is included as a component of variability" (p. 615). That last clause is
the key qualifier: it is an **agreement**-type ICC, not a consistency one.

Krippendorff (1970) is credited with "essentially the same result" (p. 614).

## The two-way ANOVA derivation (pp. 615–617)

With `X_k1`, `X_k2` the numerical category scores for subject *k* by raters A and
B, and `v_ij = (i − j)²`:

- `D̄_o = (1/n) Σ_k (X_k1 − X_k2)²` (p. 616, Eq. 4)
- `D̄_e = (1/n) Σ X_k1² + (1/n) Σ X_k2² − 2 X̄_1 X̄_2` (p. 616, Eq. 5)

With `SS_s`, `SS_r`, `SS_e` the subject, rater, and error sums of squares of the
two-way ANOVA on the *X*'s: `D̄_o = (2/n)(SS_r + SS_e)` (Eq. 6) and
`D̄_e = (1/n)(SS_s + 2SS_r + SS_e)` (Eq. 7), hence the closed form

  `κ_w = (SS_s − SS_e) / (SS_s + 2SS_r + SS_e)`   (p. 616, Eq. 8)

**Conditions attached to the population reading** (p. 616): the *n* subjects are
a random sample from a universe of subjects with variance `σ_s²`; **the two
raters are a random sample from a universe of raters** with variance `σ_r²`; the
ratings carry squared standard error of measurement `σ_e²`. Under these, citing
Scheffé (1959, ch. 7): `E(SS_r) = σ_e² + n σ_r²` (Eq. 9),
`E(SS_s) = (n−1)σ_e² + 2(n−1)σ_s²` (Eq. 10), `E(SS_e) = (n−1)σ_e²` (Eq. 11), so
`E(SS_s − SS_e) = 2(n−1)σ_s²` (p. 617, Eq. 12) and
`E(SS_s + 2SS_r + SS_e) = 2(n−1)(σ_s² + σ_r² + σ_e²) + 2(σ_r² + σ_e²)` (Eq. 13).

Therefore Eq. 8 estimates — "although not unbiasedly" (p. 617) —

  `ρ' = σ_s² / (σ_s² + σ_r² + σ_e² + (1/(n−1))(σ_r² + σ_e²))`   (p. 617, Eq. 14)

and for large *n* it in effect estimates

  `ρ = σ_s² / (σ_s² + σ_r² + σ_e²)`   (p. 617, Eq. 15)

described (p. 617) as the ICC between the ratings given a randomly selected
subject by the randomly selected raters — covariance `σ_s²`, single-rating
variance `σ_s² + σ_r² + σ_e²` (crediting Burdock, Fleiss & Hardesty 1963). So the
target is **two-way random, single-rating, agreement** (rater variance in the
denominator), with exactly **two raters**, and the identity is exact only "aside
from a term which goes to zero as *n* becomes large" (p. 617).

## Caveats the paper attaches (pp. 617–618)

- The development covers **ordinal** scales only, and **only** squared-difference
  weights; the squaring is called "admittedly arbitrary" (p. 617).
- Generalizing the ICC reading to **nominal** scales is held to be "more or less
  valid" provided `v` for two categories increases more rapidly than the
  qualitative difference between them (pp. 617–618).
- Reversed framing (p. 618): the ICC is the special case of weighted kappa "when
  the categories are equally spaced points along one dimension"; general `v_ij`
  viewed as squared distances implies a space of up to `m−1` dimensions
  (Shepard 1962).

## Numerical values printed (p. 618, Application)

No worked example, data table, or ANOVA table appears anywhere in the paper. The
only numbers in the Application section are typical-magnitude ranges quoted from
other work: weighted kappa for agreement on psychiatric diagnosis "in the
interval .4 to .6" (Spitzer & Endicott 1968, 1969), versus ICC reliabilities of
.7 to .9 for numerical scales of psychopathology (Spitzer, Fleiss, Endicott &
Cohen 1967) — from which the paper concludes diagnostic agreement is poorer.

## Traces to

Nothing in the package traces to this source. A repo-wide grep for
`fleiss1973` / "Fleiss & Cohen" / "weighted kappa" over `R/`, `tests/`,
`vignettes/`, `man/`, `NEWS.md`, and `cairn/references/ORACLES.md` returned no
hits — observed 2026-07-18 <!-- check: ! git grep -qiE 'fleiss1973|Fleiss & Cohen|weighted kappa' -- R tests vignettes man NEWS.md cairn/references/ORACLES.md --> (M64, re-run and still true at M69); the only
references are the tracking/bibliography ones M64 created
(`BIBLIOGRAPHY.md`, `INDEX.md`, and the M64 milestone file). It is
shelf/background evidence for the kappa–ICC relationship and the categorical
boundary of the package's scope, not an oracle and not a test dependency.

## Open questions

- ~~**No `BIBLIOGRAPHY.md` entry.**~~ *Resolved within M64 (T5): the source had
  an `INDEX.md` line but no `BIBLIOGRAPHY.md` entry, so T5 added one rather than
  trimming an existing entry.*
- **Form-label mapping is inference, not text.** The paper never uses
  Shrout–Fleiss or McGraw–Wong labels (it predates both). The mapping of Eq. 15
  onto the package's `ICC(A,1)` follows from its stated ingredients (two-way,
  random raters, single rating, rater variance in the denominator) but is not
  asserted in the paper; anyone citing the note should carry that caveat.
- **`k = 2` only.** Every step from Eq. 4 onward is written for exactly two
  raters. The paper says nothing about whether the identity extends to `k > 2`;
  do not assume it does.
- **Estimator vs. parameter.** Eq. 8 is an exact algebraic identity for the
  sample statistic, but Eq. 14 shows it is a *biased* estimator of the population
  ICC, coinciding with Eq. 15 only as `n → ∞`. Any future use of this paper as a
  cross-check must decide which of the two it is checking against.
- **Sums-of-squares convention unstated.** Eqs. 9–11 are given for sums of
  squares (not mean squares) with no df table printed, so the normalization is
  taken on the paper's word via the Scheffé (1959, ch. 7) citation; it is not
  independently verifiable from this PDF.
