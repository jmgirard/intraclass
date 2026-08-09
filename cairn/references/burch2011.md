# burch2011 — REML-based CI for the one-way ICC under non-normality (oracle)

**Provenance.** Ingested 2026-07-21 by M76 from `cairn/references/sources/burch2011.pdf` (gitignored).
Pagination: printed journal pages 1018–1028 (11 PDF pages, PDF p. 1 = printed
p. 1018; the version of record). The issue number is not printed in the PDF —
the running foot gives only `55 (2011) 1018–1028` — so any issue number is
carried from an external record, not from the source.
Extraction: verified 2026-08-08 against the source (all 11 PDF pages read to the final page); the eq. 6/13/15/16/17 REML-CI construction and the §4 arsenic worked example (Table 3, p. 1027) were confirmed and the REML ρ interval (0.73, 0.95) reproduced from the printed ANOVA in-session at the 2026-07-21 first pass, and the M116 re-read added the §3/§5 expected-length section below with every quotation re-checked verbatim against the p. 1023/1024/1027 text — observed 2026-08-08.

**Citation.** Burch BD (2011). "Assessing the performance of normal-based and
REML-based confidence intervals for the intraclass correlation coefficient."
*Computational Statistics and Data Analysis* 55(2011):1018–1028. DOI
10.1016/j.csda.2010.08.007. Received 24 November 2009, revised 11 August 2010,
accepted 13 August 2010, available online 20 August 2010. Single-authored
(Brent D. Burch, Northern Arizona University).

**Role.** M76 primary source (IP1) for the **REML-based** boundary-robust
classical CI leg — the construction ohyama2025 labels "REML (Burch 2011)" and
cites only secondhand. Supplies the eq. 17 CI and, in §4, a self-contained
worked REML ρ interval that is a second published oracle alongside ohyama2025 §4.

## Notation (an error trap — Burch swaps the repo's letters)

Burch uses `a` = number of **classes/subjects** and `b` = **observations per
class**, the opposite lettering to the rest of this repo (and to ukoumunne2003 /
ohyama2025), which use `k` subjects and `n` per subject. Map on entry:
**Burch `a` ↔ repo `k`**, **Burch `b` ↔ repo `n`** (= the balanced group size
`n₀`). `σ²_1` is the between/subject variance, `σ²_2` the within/error variance;
`θ = σ²_1/σ²_2`, `ρ = σ²_1/(σ²_1+σ²_2) = θ/(1+θ)` (§2, p. 1019).

## Model + ANOVA (§2, eq. 1; Table 1, p. 1020)

Balanced one-way random effects `Y_ij = μ + A_i + e_ij`, `i = 1…a`, `j = 1…b`,
`n = ab`. `MSA = SSA/(a−1)`, `MSE = SSE/(a(b−1))`; df between `a−1`, within
`a(b−1)`. Pivot for θ under normality (eq. 2, p. 1019):
`(MSE/σ²_2)/(MSA/(σ²_2 + bσ²_1)) ~ F(a(b−1), a−1)`.

## REML-based CI construction (the prototype target)

- **REML point (eq. 6, p. 1020):** `θ̂ = (1/b)(MSA/MSE − 1)` if `MSA ≥ MSE`, else
  `0`. Note `1 + bθ̂ = MSA/MSE`.
- **Asymptotic law (eq. 11–12, p. 1021):**
  `log(1+bθ̂) ~ N(log(1+bθ), 2[κ/(ab) + (ab−1)/(a(b−1)(a−1))])`, where `κ` is the
  kurtosis of the `Y_ij` (eq. 10) — the asymptotic variance **depends on the
  kurtosis**, which is the whole point of the method under non-normality. The
  `log(1+bθ̂)` transform (Slutsky) reins in the right-skew of `θ̂` and is
  "essentially Fisher's z-transformation" (p. 1021).
- **Kurtosis plug-in (eq. 13, p. 1021):**
  `κ̂ = (1/ab) Σ_i Σ_j [ (Y_ij − Ȳ_i.)/√MSE + (Ȳ_i. − Ȳ_..)/√MSA ]⁴ − 3`.
  Needs the **raw data**, not just the ANOVA summary.
- **Bias correction (eq. 14–15, p. 1021):** with
  `P(a,b) = a³(b−1)³/(a(b−1)+2) + 2a(b−1)(a−1) + (a−1)³/(a+1)` — the three terms
  are the perfect square `(b−1)² + 2(b−1) + 1 = b²` in the leading `a²`
  coefficient, so `E(κ̂) → 0` as `a → ∞` (the estimator is consistent); the cube
  on `(b−1)` is easy to miss at render resolution and matters —
  `E(κ̂) = 3P/(a²b²) − 3` under normality (eq. 14), and
  `κ̂̂ = κ̂ + 3(1 − P/(a²b²))` (eq. 15) — i.e. `κ̂̂ = κ̂ − E(κ̂)`, so `E(κ̂̂) = 0`
  exactly under normality.
- **Empirical variance-inflation `g` (eq. 16, §3, p. 1022):**
  `V̂ar(log(1+bθ̂)) = 2[ g(κ̂̂)/(ab) + (ab−1)/(a(b−1)(a−1)) ]` with the
  **empirically fitted** `g(κ̂̂) = 2.0·κ̂̂ + 0.5·κ̂̂²`. This quadratic was fit "for
  the case a = 10 and b = 5" at ρ = 0.25 (p. 1022) to correct κ̂̂'s over/under-
  estimation of κ for platy/leptokurtic distributions; Burch applies it across all
  cells regardless. **Not a universal identity — an empirical calibration.**
- **REML CI (eq. 17, p. 1022):** for θ,
  `( (1/b)[(1+bθ̂) e^(−Z_{1−α/2}√V̂ar) − 1],  (1/b)[(1+bθ̂) e^(+Z_{1−α/2}√V̂ar) − 1] )`;
  convert to ρ by `(L, U) → (L/(L+1), U/(U+1))` (p. 1020, the θ→ρ map).
- **Normal-based comparator (eq. 3, p. 1019):** the exact-F interval
  `(1/b)[MSA/MSE · F_{α/2} − 1] ≤ θ ≤ (1/b)[MSA/MSE · F_{1−α/2} − 1]`,
  `F_· = ` quantiles of `F(a(b−1), a−1)`. This is the **same exact-F pivot as the
  SEARLE leg** (mcgraw1996 / ohyama2025 SEARLE), so §4's normal-based interval
  doubles as an independent SEARLE oracle.

## §4 worked example — the REML oracle (Table 3, p. 1027)

Arsenic concentration in oyster tissue (Willie & Berman 1995, NOAA): a balanced
one-way model, **a = 28 labs, b = 4 replicates**. Table 3 (p. 1027): between labs
df 27, SS 773.33, MS 28.64; within labs df 84, SS 76.88, MS 0.92; total df 111.
The distributions of `Â_i` / `ê_ij` fail Shapiro–Wilk (leptokurtic; `g(κ̂̂) = 7.75`,
⇒ `κ̂̂ ≈ 2.42`), so REML is preferred (p. 1027).

| quantity | printed value |
|---|---|
| REML `ρ̂` | 0.88 |
| REML `θ̂` | 7.57 |
| `g(κ̂̂)` used in eq. 16 | 7.75 |
| **REML-based 95% CI for ρ** | **(0.73, 0.95)** |
| normal-based (exact-F) 95% CI for ρ | (0.81, 0.94) |

**Rounding note.** The printed within-labs `MS = 0.92` is rounded; the ANOVA
`SS/df = 76.88/84 = 0.91524` gives `θ̂ = (1/4)(28.6419/0.91524 − 1) = 7.574 ≈ 7.57`
(the printed 0.92 gives 7.53). Reproduce from the **SS**, not the rounded MS —
the same source-rounding subtlety flagged for ohyama2025 §4.

## Simulation findings (§3, pp. 1022–1026)

- **REML-based CI holds coverage near nominal across symmetric and asymmetric
  distributions** including heavy kurtosis, where the normal-based interval
  under-covers badly (Figs 1, 3–5, 7–8). It is the recommended method "for the
  vast majority of the parameter space" (§5, p. 1028).
- **Design:** `b = 5` fixed, `a ∈ {5, 10, 25, 50, 100}`, 11 distributions
  (Table 2), 100 000 MC samples; the REML method's asymptotics need `a → ∞` at
  fixed `b`, so it degrades at small `a` (§5).
- **Boundary caveat (§5, p. 1028), material to M76's GO/NO-GO:** "If ρ is close to
  zero, then the normal-based procedure is preferred." At ρ = 0.05 the REML
  method's lowest coverage over 55 scenarios was "just under 0.93" (a = 100,
  χ²(1)). So near-zero ρ is exactly where REML's advantage narrows — the M76
  near-zero sweep cells must measure this, not assume dominance.
- **Non-normality:** kurtosis `κ > 0` (leptokurtic) is where the normal-based
  interval fails and REML earns its keep; `κ < 0` (platykurtic) the normal-based
  interval over-covers and REML ≈ nominal (Fig. 1).

## Expected length vs the normal-based interval (§3, eq. 18, pp. 1023–1024; §5, p. 1027), extracted by M116

The comparison the package's own width claim needed and never had. Burch
compares **his interval against the exact-F one directly** — his "normal-based"
comparator is eq. 3, the same pivot the package ships as `"searle"` (see the
construction section above) — so eq. 18's ratio is a burch-vs-searle
expected-length ratio, not a comparison against some third interval:

> "E (Length of REML-based interval) / E (Length of Normal-based interval)" (eq. 18, p. 1023)

**The direction is kurtosis-conditional, not one-way.** Fig. 2's setup draws
**both** effects from the studied family — "assuming that the `A_i`'s and
`e_ij`'s depend on the uniform(0,1), power exponential(0,1,2.78), t(10),
Laplace(0,1), or t(5) distributions given in Table 2, where `b = 5` and the
values of `a` range from 10 to 100 in increments of 10 for `ρ = 0.5`" (p. 1023).
Its findings (p. 1024):

> "For symmetric platykurtic distributions, the REML-based intervals are
> approximately equal to the nominal coverage probability and have average
> lengths that are less than those of the normal-based intervals. For symmetric
> leptokurtic distributions, the REML-based intervals, on average, are wider
> than their normal-based counterparts. The REML-based intervals, unlike the
> normal-based intervals, have coverage probabilities that are close to the
> nominal level of 0.95 and thus wider intervals are warranted."

And in the Discussion (p. 1027), with the one printed ratio figure:

> "The REML-based confidence interval procedure yields intervals that are closer
> to the nominal coverage probability (of 0.95) for non-normal distributions and
> are shorter in expected length than the normal-based confidence intervals for
> the platykurtic distributions under study."

> "if `a = 100`, `b = 5`, `ρ = 0.25`, and one considers the case where the
> between class and within class effects are based on the uniform(0,1)
> distribution, then the simulated coverage probabilities for the REML-based and
> normal-based intervals are 0.95 and 0.97, respectively, and the expected length
> of the REML-based interval is **88%** of that of the normal-based interval."

**What Burch does NOT say.** Nowhere does he call the normal-based (exact-F)
interval the narrower or the shortest of the two. For the platykurtic families
he reports the opposite, and the widening he does report is confined to
symmetric leptokurtic data with **both** `A_i` and `e_ij` non-normal — a
condition neither committed repo grid tests, since both draw the non-normal
family for the subject effect alone (`data-raw/m76-coverage-sweep.R` lines
33–38). So this source neither supports the withdrawn "burch is wider" claim nor
refutes the repo's own measurement; it bounds where each applies.

Quotations above are de-hyphenated across line breaks ("nom- inal" → "nominal",
"normal- based" → "normal-based"); the parenthesized figures are printed
`uniform(0,1)` without a space, as rendered here — read from the p. 1023/1024/1027
text layer and each re-checked verbatim against it — observed 2026-08-08.
<!-- check: none — a statement about how this section was authored; the source PDF is gitignored, so no committed artifact can settle it -->

## Table 2 — the non-normal battery (p. 1021), extracted by M111

Kurtosis values `κ = E[(X−μ)⁴]/σ⁴ − 3` for the 11 §3 simulation distributions
(Table 2, p. 1021, verbatim):

| class | distribution | κ |
|---|---|---|
| symmetric | Uniform(0, 1) | −1.2 |
| symmetric | Power exponential(0, 1, 2.78) | −0.5 |
| symmetric | Normal(0, 1) | 0.0 |
| symmetric | t(10) | 1.0 |
| symmetric | Laplace(0, 1) | 3.0 |
| symmetric | t(5) | 6.0 |
| asymmetric | Beta(0.4, 0.6) | −1.33 |
| asymmetric | Weibull(3.36, 1) | −0.29 |
| asymmetric | Gamma(2, 1) | 3.0 |
| asymmetric | Exponential(1) | 6.0 |
| asymmetric | χ²(1) | 12.0 |

**Located-and-scaled convention (§3, p. 1022):** each variate is centered and
scaled to mean 0 and the target variance — worked example printed for χ²(1):
`A_i = σ₁(X_i − 1)/√2` with `X_i ~ χ²(1)`. The same convention applies to any
Table 2 family.

This section's extraction was read directly from the p. 1021 table render at
ingestion (M111), separate from the M76 blanket pass above — observed
2026-08-08. <!-- check: none — a statement about how this section was authored; git history (commit 643f0f0) is the record -->

## Traces to (M111)

- The M111 fallback-on-abort sweep's two new non-normal arms are chosen from
  Table 2: **Uniform(0, 1)** (κ = −1.2, platykurtic) and **χ²(1)** (κ = 12.0,
  skewed, the battery's largest kurtosis) — χ²(1) is also the distribution the
  §5 boundary caveat names at ρ = 0.05 (coverage "just under 0.93" at a = 100),
  making it the stress case for exactly the near-zero region where the MC
  default aborts. Generators in `data-raw/` (M111) follow the
  located-and-scaled convention above.

## Traces to (M76)

- `data-raw/m76-classical-oneway-prototype.R` — the `burch_reml_ci*()` prototype
  implements eq. 6/13/15/16/17 and asserts against the two §4 oracles below.
- **Oracle for the REML leg (AC1):** the arsenic REML ρ CI (0.73, 0.95) above
  (this source), cross-checked with ohyama2025 §4 Ex.1 PMOC REML (0.620, 0.885)
  — two independent published sources for the same eq. 17 construction.
- **Second SEARLE oracle:** the arsenic normal-based ρ CI (0.81, 0.94) is an
  independent published exact-F value for the SEARLE leg.
- The non-normal / near-zero coverage expectations set the GP6 sweep design and
  the non-normal decision rule (T4).
- The `?icc` `@references` entry cites this paper by its verified title and
  journal; a wrong title, journal, and page range (the *JSCS* rendering the
  M106 review's F4 corrected in the glossary) was still live there — observed
  2026-08-06. <!-- check: git grep -qF 'Computational Statistics and Data Analysis' -- R/icc.R && ! git grep -qiF 'Journal of Statistical Computation and Simulation' -- R -->

