# hedges2012 — large-sample variances of ICCs in three- and four-level models

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/hedges2012.pdf` (gitignored).
Pagination: printed journal pages 893–909; the 17 PDF pages map one-to-one onto printed 893–909. This copy is the version of record (full volume/issue/pagination and DOI printed); its footer records a SAGE download stamp from 2016.
Extraction: verified 2026-07-19 against the source (all 17 PDF pages read to the final page — the **Appendix sits at pp. 906–907**, after the software section and before the References, and carries the delta-method derivations behind every formula); the two-level worked example was recomputed from the Table 1 components and reproduces the printed variance and standard error exactly, while both three-level examples reproduce only up to the paper's own displayed intermediate rounding (documented in the note) — observed 2026-07-19.

**Citation.** Hedges, L. V., Hedberg, E. C., & Kuyper, A. M. (2012). "The Variance
of Intraclass Correlations in Three- and Four-Level Models." *Educational and
Psychological Measurement* 72(6), 893–909. DOI 10.1177/0013164412445193.
© The Author(s) 2012. Affiliations: Northwestern University (Hedges, Kuyper) and
NORC at the University of Chicago (Hedberg).

**Role.** **Largely outside this package's contract boundary (IP2)** — see the
boundary note below — and included on the shelf as design/uncertainty
background for the multilevel estimand. It supplies standard-error formulas for
*variance-share* ICCs in nested sampling designs. **No oracle value traces here**
and no test, vignette, or `ORACLES.md` entry reads it — its only in-repo
citations are the `BIBLIOGRAPHY.md` entry and `INDEX.md` line added by M66 itself.

## Boundary note (IP2) — a different ICC family

The ICCs in this paper have **no rater facet**. They are proportions of total
variance attributable to a level of a purely hierarchical sampling design —
students in teachers in schools in districts (p. 901) — used "to summarize the
variance decomposition in populations with multilevel hierarchical structure"
and "to provide design parameters for planning future large-scale randomized
experiments" (Abstract, p. 893). That is the clustering/design-effect tradition,
not interrater reliability: there is no `σ²_r`, no rater × subject interaction,
and no agreement-vs-consistency distinction anywhere in the article.

This package's multilevel estimand (subjects nested in clusters, rated by raters;
`tenhove2022.md`, Eqs. 12–13) is a *different* decomposition that happens to share
the phrase "multilevel ICC". The overlap is real but partial, and the shared
vocabulary is a trap worth naming: Hedges's `ρ_2`, `ρ_3`, `ρ_4` index *levels of
nesting*, whereas ten Hove's subject- and cluster-level ICCs index *what is being
generalized over*. Nothing here is a competing definition of the package's
estimand.

## The formulas

**Two-level** (p. 895). With `σ²_1`, `σ²_2` the Level 1 and 2 components and
`σ²_T = σ²_1 + σ²_2`: `ρ = σ²_2/(σ²_1 + σ²_2)`, estimated by
`r = s²_2/(s²_1 + s²_2)`. Because Level 1 has so many units, `s²_1 ≈ σ²_1` is
treated as fixed, so `v_1 = 0` (p. 895). Eq. (1), p. 896 — the large-sample
variance of `r` in a balanced design:

`Var(r) = (1 − ρ)² v_2 / σ⁴_T`

where `v_2` is the variance of `s²_2`. Estimated by substituting sample values:
`(1 − r)² v_2 / (s²_1 + s²_2)²`; "The standard error of `r` is just the square
root of its estimated variance."

The paper reconciles this with the classical results: Fisher's (1925) expression,
Eq. (2), is `2(1 − ρ)²[1 + (n−1)ρ]²/[n(n−1)(m−1)]`, and Donner and Koval's (1980)
unbalanced form is Eq. (3). Eq. (1) and Eq. (2) "differ only in terms of order
`n²`, which implies that they are equivalent in large samples" (p. 896).

**Three-level** (pp. 897–899). `ρ_2 = σ²_2/σ²_T` and `ρ_3 = σ²_3/σ²_T` with
`σ²_T = σ²_1 + σ²_2 + σ²_3`; `p` is the number of Level 2 units per Level 3 unit.
The key structural fact (p. 897): the component estimates are **not** independent
across levels — "the covariance between `s²_2` and `s²_3` is `−v_2/p`" in the
balanced case — which is why the ICC variances mix `v_2` and `v_3`:

- Eq. (4): `Var(r_2) = [p(1−ρ_2)² + 2ρ_2(1−ρ_2)]v_2/(pσ⁴_T) + ρ²_2 v_3/σ⁴_T`
- Eq. (5): `Var(r_3) = [pρ²_3 + 2ρ_3(1−ρ_3)]v_2/(pσ⁴_T) + (1−ρ_3)²v_3/σ⁴_T`
- Eq. (6): the covariance `Cov(r_2, r_3)`

For unbalanced designs, Eq. (7) gives the covariance `c_23` from Searle (1970),
and Eqs. (8)–(9) the corresponding variances. Practical finding, p. 899: "unless
there is extreme imbalance, the value of the variances of `r_2` and `r_3`
computed from (8) and (9) … are remarkably similar to those obtained by using the
mean of the `p_i` in (4) and (5)". Guidance for imbalance (p. 897): "use an
average value (such as the mean or harmonic mean) in place of `p`".

**Four-level** (pp. 899–901). Eqs. (10)–(15) give `Var(r_2)`, `Var(r_3)`,
`Var(r_4)` and the three pairwise covariances, with `q` the number of Level 3
units per Level 4 unit. Balanced-case covariances (p. 899): between `s²_3` and
`s²_4` it is `−v_3/q + v_2/(qp²)`, and "the covariance between `s²_2` and `s²_4`
is zero".

Derivations are by the (multivariate) delta method — Appendix, pp. 906–907,
citing Rao (1973).

## The worked example (pp. 901–904)

Data: 2009–2010 Kentucky Core Content Test reading scores, "46,849 fifth
graders … spread across 173 districts, 715 schools, and 2,142 teachers"
(p. 901). Scores 0–33 on 39 multiple-choice items, mean 27.01, variance 27.51.
Harmonic mean teachers per school `p = 2.042`; harmonic mean schools per district
`q = 1.818` (Table 1 note, p. 902).

Table 1 (p. 902), variance components and ICC estimates with their variances:

| | Two-level | Three-level | Four-level |
|---|---|---|---|
| District | — | — | 0.314 (v 0.008) |
| School | 2.409 (v 0.024) | 1.557 (v 0.030) | 0.957 (v 0.021) |
| Teacher | — | 3.190 (v 0.040) | 3.160 (v 0.039) |
| Student | 25.241 | 23.835 | 23.834 |
| Total variance | 27.650 | 28.582 | 28.265 |
| ICC District | — | — | 0.011 (var 0.0000101) |
| ICC School | 0.087 (var 0.00003) | 0.054 (var 0.000032) | 0.034 (var 0.00003101) |
| ICC Teacher | — | 0.112 (var 0.0000405) | 0.112 (var 0.00004007) |

Table 1 footnote `a`: the Student-level variance of the variance "We assume this
variance to be 0.000" — the `v_1 = 0` simplification.

Worked arithmetic as printed, two-level (p. 902):
`var(r) = (1 − 0.087)²(0.024)/27.650² = 0.020/764.523 = 0.00003`, so
`SE = √0.00003 = 0.005`. The paper adds that "Donner's formula gave approximately
the same result for the standard error, also rounding to 0.005."

**Independent recomputation (M66).** Two-level: `0.913² × 0.024 = 0.020005`,
`27.650² = 764.5225`, quotient `2.616 × 10⁻⁵`, `SE = 0.00512` ✓. Three-level
`Var(r_2)`: `[2.042(0.888²) + 2(0.112)(0.888)] × 0.040 = 0.07236`, divided by
`2.042 × 816.931 = 1668.17` gives `4.34 × 10⁻⁵`; plus
`0.112²(0.030)/816.931 = 4.6 × 10⁻⁷`; total `4.38 × 10⁻⁵`, `SE = 0.0066`. **This
does not match the printed 0.0000405 / 0.006 exactly** — it is ~8 % high, and
`0.0066` rounds to `0.007`, not the printed `0.006`. The gap is the paper's own
displayed rounding: p. 903 rounds the numerator to `0.072` and the first term to
`0.00004` before summing, and `0.00004 + 0.0000005 = 0.0000405` is what it
prints. Three-level `Var(r_3)` behaves the same way — full precision gives
`3.55 × 10⁻⁵` against the printed `3.2 × 10⁻⁵`. So **both** three-level examples
reproduce only up to the paper's intermediate rounding, and neither is an error
in the formulas; the two-level example reproduces exactly.

Figure 1 (p. 905) reproduces the same quantities from the authors' Stata
`ICCVAR` program at five decimals — two-level school ICC `0.08714`
(SE `0.00507`, 95 % CI `0.07720`–`0.09707`); three-level `0.05447` /
`0.11162`; four-level `0.01111` / `0.03385` / `0.11179`. The unbalanced
three-level option changes the standard errors only in the fourth decimal
(`0.00593` → `0.00586`), which is the p. 899 claim made concrete.

## What this could source

Nothing is proposed here — M66 writes notes, not code (Scope). Recorded for
completeness, with the boundary caveat above attached to both:

- **A closed-form cross-check on multilevel component uncertainty.** Eqs. (1),
  (4), (5), (10)–(12) are explicit, hand-computable delta-method variances, and
  the Kentucky example supplies inputs and outputs at five decimals (Figure 1).
  If the package ever wants a deterministic sanity check on a multilevel ICC's
  *sampling* variance, this is a citable closed form. It is **not** a candidate
  interval method for the package — see the next point.
- **A worked contrast with the package's interval doctrine.** These are
  symmetric large-sample Wald intervals: Figure 1's four-level district interval
  `0.00500`–`0.01722` is exactly `0.01111 ± 1.96 × 0.00312` (M66 recomputation).
  `PRINCIPLES.md` #3 requires boundary-aware intervals, and this construction is
  the archetype of what it rules out — at the small ICCs this literature routinely
  reports (0.011 here), a symmetric Wald interval crosses zero as soon as the
  point estimate falls below about twice its standard error. The paper's own
  scope sentence concedes the limitation from the other direction (p. 905): the
  expressions "are suitable … when the sampling designs are balanced or nearly
  so". Useful as *contrast*, not as a method to adopt.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page — observed 2026-07-19.

- `cairn/references/tenhove2022.md` — the package's actual multilevel estimand
  source; see the boundary note above for why these two "multilevel ICCs" are
  different quantities.
- `cairn/references/BIBLIOGRAPHY.md` (Hedges, Hedberg, & Kuyper entry) and
  `INDEX.md`.

## Open questions

- The `ICCVAR` Stata program (p. 904) is cited to two URLs at Northwestern and
  RePEc. Neither was retrieved — it is Stata code, outside this package's
  toolchain, and nothing here depends on it, so no live independent
  implementation was obtained from it — observed 2026-07-19.
