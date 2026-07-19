# tenhove2025b — MLE-RE + Monte-Carlo CIs for ICCs from planned incomplete data

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/tenhove2025b.pdf` (gitignored).
Pagination: printed journal pages 1042–1061 — the Taylor & Francis cover sheet is file page 1, so PDF page = printed page − 1040 (verified M69: PDF p. 2 carries the running head "2025, VOL. 60, NO. 5, 1042–1061"; M64 wrote "− offset" here, made concrete M69).
Extraction: verified 2026-07-18 against the source (M69) — all 21 PDF pages (printed 1042–1061; references end p. 1061, no appendix) re-read; the p. 1057 real-data output confirmed digit-for-digit, Table 1's six cells transcribed at 700 DPI, six prose/anchor claims corrected (including MLE-CF's bias direction for ICC(C,1)) and five observations added — observed 2026-07-18.

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2025). "How to Estimate
Intraclass Correlation Coefficients for Interrater Reliability from Planned
Incomplete Data." *Multivariate Behavioral Research* 60(5):1042–1061.
DOI 10.1080/00273171.2025.2507745. Open Access (CC BY-NC-ND 4.0), published
online 16 Jun 2025.

**Role.** The simulation source cited by **ADR-002** (MLE random-effects engine)
and **ADR-003** (Monte-Carlo CIs as the default interval method). This is the
paper that establishes the package's *estimation route + interval method* as the
externally preferred pair; it is not an oracle-value source.

> **Pagination.** All anchors in this note are **printed journal pages
> 1042–1061**, which are visible in the running heads. The PDF file has a
> Taylor & Francis cover sheet as file page 1, so **PDF page = printed page −
> 1040** (printed 1042 = file page 2, printed 1061 = file page 21).

> **Citekey trap.** This is the MBR **60(5)** planned-incomplete paper. The
> sibling `tenhove2025a` is the MBR 60(3) interdependent-social-network-data
> paper — a different work. Title page verified: authors, journal, volume/issue,
> pages, and DOI all match the citation above exactly as printed (p. 1042).

## Estimand context (pp. 1044–1046)

Two-way crossed model, Eq. 1 (p. 1044): `y_sr = μ + μ_s + μ_r + μ_sr`, with
`μ_sr` the subject×rater interaction confounded with random error. Orthogonal
decomposition, Eq. 2 (p. 1045): `σ²_y_sr = σ²_s + σ²_r + σ²_sr`. One-way
(nested) special case, Eqs. 3–4 (p. 1045): `y_r:s = μ + μ_s + μ_r:s`,
`σ²_y_r:s = σ²_s + σ²_r:s` — described as "a special case of an incomplete
two-way design" (p. 1045).

Coefficients: `ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_sr)`, Eq. 5 (p. 1045);
`ICC(C,1) = σ²_s / (σ²_s + σ²_sr)`, Eq. 6 (p. 1045); one-way
`ICC(1) = σ²_s / (σ²_s + σ²_r:s)`, Eq. 7 (p. 1045).

**Table 1 (p. 1046)** is the two-way grid (agreement/consistency ×
complete/incomplete × single/average). Load-bearing for incomplete designs: the
average-rating forms for incomplete designs divide the rater-related components
by the **harmonic-mean number of raters per subject `k̂`** rather than `k`, and
the incomplete *consistency* coefficient adds a **portion `q` of `σ²_r`** to the
denominator — hence written `ICC(Q, ·)` rather than `ICC(C, ·)`. Table 1's note
defines `q` as the proportion of non-overlapping raters across subjects and `k̂`
as the harmonic mean of raters per subject.

The six cells as printed (read at 700 DPI; superscripts are Table 1's own
attributions — <sup>a</sup> Shrout & Fleiss 1979, <sup>b</sup> McGraw & Wong
1996, <sup>c</sup> Putka et al. 2008, <sup>d</sup> ten Hove et al. 2024):

| Type | Design | Single ratings | Average ratings |
|---|---|---|---|
| Agreement | Complete | `ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_sr)` <sup>a,b</sup> | `ICC(A,k) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/k)` <sup>a,b</sup> |
| Agreement | Incomplete | `ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_sr)` <sup>a,b</sup> | `ICC(A,k̂) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/k̂)` <sup>d</sup> |
| Consistency | Complete | `ICC(C,1) = σ²_s / (σ²_s + σ²_sr)` <sup>b</sup> | `ICC(C,k) = σ²_s / (σ²_s + σ²_sr/k)` <sup>b</sup> |
| Consistency | Incomplete | `ICC(Q,1) = σ²_s / (σ²_s + qσ²_r + σ²_sr)` <sup>d</sup> | `ICC(Q,k̂) = σ²_s / (σ²_s + qσ²_r + σ²_sr/k̂)` <sup>c</sup> |

Table 1's note prints `q = 1/k − [Σ_s Σ_s' (k_{s,s'}/(k_s k_s'))] / (S(S−1))`
and `k̂ = ((k_1^−1 + k_2^−1 + … + k_S^−1)/S)^−1`.

> **Cross-reference (M69).** The `ICC(A,k̂)` cell divides **both** rater-related
> components by `k̂` — `(σ²_r + σ²_sr)/k̂` — confirmed glyph-by-glyph at 700 DPI,
> hat included. This is exactly the cell that `tenhove2024`'s Table 2 misprints
> (σ²_r left undivided; see `tenhove2024.md` and M69's work log), so this paper's
> Table 1 independently corroborates that `tenhove2024` Eq. 18, not its Table 2
> cell, is the correct form — and that the package follows the correct one. Only
> `qσ²_r` in the `ICC(Q,·)` cells is undivided, and there by definition.

## The three methods compared (pp. 1046–1048, named as the paper names them)

- **MCMC-HL** — Markov chain Monte Carlo estimation of Bayesian hierarchical
  linear models (LoPilato et al. 2015); yields posterior *SD*s and **Bayesian
  credible intervals (BCIs)** (p. 1047).
- **MLE-RE** — maximum likelihood estimation of random-effects models
  (Marcoulides 1990); same underlying model as MCMC-HL, Eqs. 1–2 (p. 1047; the
  section opens in the right column of p. 1047 and runs onto p. 1048 — M64 gave
  p. 1048, corrected M69).
- **MLE-CF** — maximum likelihood estimation of common-factor models (SEM;
  Marcoulides 1996, Jorgensen 2021), Eq. 8 + Figure 2 (pp. 1047–1048); raters
  are indicators, data in wide format, rater effects are **fixed** intercepts.
- **ANOVA** — traditional random-effects one-way ANOVA (R package `irr`) with
  least-squares estimates and a 95% CI via an inverted *F* test, used **as the
  benchmark**, not as a candidate (p. 1050).

CI constructions crossed with the ML methods (p. 1047, p. 1050): **delta-method
(Wald) CIs** and **Monte-Carlo CIs** for both MLE-RE and MLE-CF;
**percentile-based BCIs** for MCMC-HL; inverted-*F* for ANOVA. The two ML arms
got their delta-method CIs by different routes (p. 1050, corrected M69 — M64
attached `car::deltaMethod()` to both): MLE-RE via `car::deltaMethod()` fed the
`merDeriv` covariance matrix, MLE-CF via `lavaan`'s own user-defined parameters
(the ICCs were "specified … as user-defined parameters in the `lavaan` model so
that the program readily provided delta-method CIs", p. 1050). Monte-Carlo CIs
came from `semTools::monteCarloCI()` for both. Figure 7 (p. 1054) labels these
`MLE-RE-DM` / `MLE-RE-MC` / `MLE-CF-DM` / `MLE-CF-MC`. Nonparametric
bootstrapping is named but *not* run — "computationally intensive" (p. 1047).

## The Monte-Carlo CI construction (the method the package implements)

- **What it is (p. 1047).** Monte-Carlo CIs are described as "a parametric
  bootstrap technique" citing Preacher & Selig (2012). They "may be more robust
  than delta-method CIs" because they "only assume a normal sampling
  distribution for the estimated parameters, but not for the ICCs that are
  functions of those parameters" (p. 1047). The ICC CIs "are based on
  percentiles of the empirical sampling distribution" (p. 1047).
- **What is drawn from what (p. 1050, MLE-RE paragraph).** MLE-RE was fit with
  `lme4`; the **`merDeriv` package supplied a robust asymptotic covariance matrix
  of the variance components**, which "served as input for the `monteCarloCI()`
  function of the `semTools` package" (p. 1050). The *same* covariance matrix
  also fed the delta-method CIs. So: draw variance-component vectors from their
  estimated joint (normal) distribution → recompute the ICC per draw → take
  percentiles.
- **Explicitly *not* a random-effects bootstrap (p. 1057).** Contrasting with
  Jiang et al. (2022): "the Monte Carlo CI that we considered only resamples the
  variance components from their estimated joint distribution" (p. 1057),
  whereas Jiang et al. "resampled the random effects and residuals for every
  case" (p. 1057). The paper's rationale for preferring the MC route on
  incomplete data (p. 1058): bootstrapping requires refitting per sample and
  "the bootstrapping algorithm might need to be adapted to respect the
  ignorability assumption with incomplete data"; Monte Carlo CIs "avoid either
  complication" (p. 1058). **No transformation is described** — the draws are of
  the variance components on their own scale, not a log/Cholesky scale.
- **Complete data too (p. 1058, added M69).** The paper's scope is planned-
  *incomplete* data, but it states the MC result covers the complete case as
  well: "our results in Figure 7 indicate they perform just as accurately with
  complete or incomplete data when using MLE-RE" (p. 1058) — the 0%-missing cell
  (`R = 3`, `R_s = 3`) is a complete crossed design. This is what lets ADR-003
  lean on the paper for the package's *default* interval method rather than only
  for its ragged paths.
- **Scaling of other ICCs (p. 1050).** Only `ICC(A,1)` and `ICC(C,1)` were
  studied; the other Table 1 definitions "scale the error variance by means of
  `k` or `k̂` and `q`" (verbatim, corrected M69 — M64 quoted "`k`, `k̂` or `q`"),
  so they "only proportionally influence the computational accuracy of the ICCs"
  (p. 1050).

## Simulation design (pp. 1049–1050)

- **DGP (p. 1049).** Three steps: (1) build a design matrix by randomly assigning
  `R_s` unique raters out of a pool of `R` to each subject; (2) generate normal
  subject, rater, and interaction effects from Eq. 2's parameters; (3) form `y_sr`
  via Eq. 1. Fixed: `μ = 0`, `σ²_s = 2`.
- **Factors (p. 1049).** Rater pool `R ∈ {3, 5, 10}`; raters per subject
  `R_s ∈ {2, 3}`; subjects `S ∈ {30, 200}`; `σ²_r ∈ {½, 1}`;
  `σ²_sr ∈ {1, 2}`. Fully crossed → **3 × 2 × 2 × 2 × 2 = 48 conditions ×
  1,000 replications = 48,000 data sets** (p. 1049).
- **Missingness (Table 2, p. 1049).** Planned-missing proportion `1 − R_s/R`
  ranged 0.00–0.80, at the six (R, R_s) cells: (3,2) 33%, (3,3) 0%, (5,2) 60%,
  (5,3) 40%, (10,2) 80%, (10,3) 70%.
- **Population ICCs (p. 1049).** `ICC(A,1) = 0.40–0.57` and `ICC(C,1) =
  0.50–0.67` across conditions — "These are the lowest possible ICCs" (p. 1049),
  since average-rating forms are higher by definition.
- **Software (pp. 1049–1050).** MCMC-HL: `brms`/`rstan`, half-*t*(df = 3, μ = 0,
  σ = 2.5) hyperpriors on the intercept and random-effect *SD*s, 3 chains × 1,000
  iterations (half burn-in) → 1,500 draws, convergence `0.90 < R̂ < 1.10`,
  posterior **modes** as point estimates and percentile BCIs. MLE-RE: `lme4` +
  `merDeriv` + `car` + `semTools`. MLE-CF: `lavaan` + `semTools`.
- **Criteria (p. 1050).** Relative bias of point estimates (minor > .05,
  substantial > .10); *SE* bias = `SE̅/SD_θ̂ − 1` (minor > .10, substantial >
  .20); RMSE; 95% coverage, with **coverage < 90% called "insufficient"**
  (p. 1050); convergence rate and estimation time.
- **Reporting scope (p. 1051).** Figures 3–8 show only the low-error-variance
  conditions (`σ²_r = 0.50`, `σ²_sr = 1.00`); the complete result set is in
  Supplementary Tables 1–2, which are not in the shelf PDF (— observed
  2026-07-18; see Open Question 4).

## Key results (pp. 1051–1054)

- **Point-estimate bias (Fig. 3, p. 1051; Fig. 4, p. 1052).** "Across all
  conditions, MLE-RE yielded the most accurate ICC estimates" (p. 1051); MLE-RE
  accurately estimated ICC(A,1), ICC(C,1) *and* all variance components in all
  conditions. MCMC-HL was accurate except with small numbers of subjects (it
  underestimated `σ²_s` and `σ²_r`, hence ICC(A,1)). MLE-CF was accurate for
  ICC(A,1) but **over**estimated ICC(C,1) at 80% missing (M64 recorded
  "underestimated", **corrected M69**): the paper's mechanism is that MLE-CF's
  *under*estimation of `σ²_sr` grew with missingness, "which resulted in the
  overestimation of the ICC(C,1)" (p. 1051) — `σ²_sr` sits in that ICC's
  denominator, so the two directions are opposite by construction. In the same
  cells `σ²_r` was overestimated, and the opposing biases "seemed to balance each
  other out", leaving ICC(A,1) accurate (p. 1051). ANOVA "consistently
  underestimated the ICC(C,1)" while accurately estimating ICC(A,1) (p. 1051), as
  predicted (p. 1050) because it cannot separate `σ²_r` from `σ²_sr`.
- **Variability (SE) bias (Figs. 5–6, pp. 1052–1053).** "Across conditions,
  MLE-RE yielded the most accurate variability estimates of the ICCs" (p. 1053);
  MLE-RE *SE*s were accurate for both ICCs in all conditions. MCMC-HL
  "substantially overestimated the variability in `σ²_r`" (p. 1052) — Fig. 6
  shows relative bias of the `σ²_r` variability estimate peaking at roughly +500%
  to +600% in the *low*-missingness cells (0% and 33%) and falling to roughly
  +100% at 70–80% missing (plot-read, approximate; re-read at 300 DPI, M69).
  MLE-CF substantially *under*estimated the variability of `σ²_r` (roughly −60%
  to −90%, plot-read). MLE-RE's points sit inside the negligible-bias band for
  all three variance components in every plotted cell.
- **Coverage (Fig. 7, p. 1054).** "Across conditions, MLE-RE with Monte-Carlo
  CIs yielded coverage rates closest to the nominal level of 95%" (p. 1053).
  MLE-CF "yielded extremely low 95% CI coverage rates for both delta-method and
  Monte-Carlo CIs" (p. 1053) — **for `ICC(A,1)`** (scope restored M69; M64 read
  the sentence as unqualified). It sits inside the paper's ICC(A,1) paragraph;
  for `ICC(C,1)` the next sentence puts MLE-CF *with Monte-Carlo CIs* among the
  methods with "acceptable (but not perfect)" coverage "in nearly all
  conditions" (p. 1053). ANOVA coverage was too low for both ICCs, improving
  for ICC(A,1) as missingness decreased. For ICC(C,1), only at the highest
  missingness did coverage fall too low — as it also did for both ML methods with
  **delta-method** CIs (p. 1053).
- **Convergence / time (Fig. 8, p. 1054).** MLE-RE showed "the highest (near
  100%) convergence rates" (p. 1053) and converged "within a few seconds in all
  conditions" (p. 1054). MCMC-HL had the lowest convergence, ~1–1.5 min per fit;
  MLE-CF ranged from seconds to "several hours" at high missingness (p. 1054).

## Follow-up simulations (pp. 1055–1056) — the boundary-relevant one

- **Follow-up 1 (anchor-rater PMD, Fig. 9, p. 1055).** An anchor-rater design
  (all subjects rated by one initial rater plus `R_s − 1` randomly sampled) was
  run at the two worst main-simulation conditions (`R = 10`, `R_s = 2`, `N = 30`,
  `S²_s = 2`, `S²_r = 0.5`, `S²_sr ∈ {1, 2}`). Performance "differed negligibly"
  from the random-rater design; "MLE-RE (with Monte-Carlo CIs) still outperformed
  MLE-HL and MLE-CF based on all criteria" (p. 1055; the "MLE-HL" there appears
  to be a typo for MCMC-HL). MLE-CF's convergence "dropped greatly" (p. 1055).
- **Follow-up 2 (near-zero rater variance, pp. 1055–1056) — the boundary case.**
  Built on the worst condition (`R = 10`, `k_s = 2`, `N = 30`, `σ²_s = 2`), with
  `σ²_r ∈ {0.50, 0.10, 0.01}` and `σ²_sr ∈ {1.00, 0.10}` → 6 conditions
  (**source typo, M69**: p. 1055 prints "The interaction variance had two levels:
  `σ²_r` = 1.00 or 0.10", repeating the `σ²_r` subscript where the interaction
  component `σ²_sr` is meant — the sentence directly above already assigned
  `σ²_r` its own three levels);
  resulting population `ICC(A,1) = .57–.95`, `ICC(C,1) = .67–.95` (p. 1055).
  Result (p. 1056): MLE-RE accurately estimated both ICCs and their variability
  in all conditions — including near-zero `σ²_r` (0.10 or 0.01) "in which the
  rater variance was substantially overestimated (up to 200%)" (p. 1056). The
  paper's own resolution: the low rater variance relative to subject variance
  "rendered the effect of this bias negligible for the accuracy of the ICC
  estimates" (p. 1056). Details are in Supplementary B Figs. 1–3 (not in PDF).
- **Small rater samples (p. 1057, Discussion).** "The coverage rates of ICCs for
  interrater agreement were considerably lower for small samples of raters, than
  those for larger samples of raters" (p. 1057, verbatim — M64's quotation
  dropped "ICCs for" and the comparison clause, corrected M69) — because ICC(A,·) carries `σ²_r` in the denominator and it is
  estimated from only 3–10 raters. This is the paper's stated failure axis, and
  it is a *few-raters* axis, not a few-subjects axis.

## Headline recommendation

Abstract (p. 1042): "Maximum likelihood estimation of random-effects models with
Monte-Carlo confidence intervals is preferred based on all criteria."

Discussion (p. 1057): "MLE-RE yielded accurate estimates and was practically
feasible … We recommend to complement this method with Monte-Carlo CIs which had
almost nominal coverage rates." And (p. 1057): "we found the MLE-RE method the
single preferred method to estimate ICCs for IRR."

## Real-data demonstration (pp. 1056–1057) — candidate reference values

ACP-CAT communication-skill ratings (Yuen et al. 2020): incomplete two-way PMD,
**29 subjects × 2 raters each, rater pool 6, partly overlapping** (p. 1056);
`estICCs(..., estimator = "MLE")` from the OSF `ICCfunctions.R`. Printed output
(p. 1057), est [ci.lower, ci.upper] (SE):

| Coefficient | est | 95% CI | SE |
|---|---|---|---|
| ICCa1 | 0.7164607 | [0.4650343, 0.9004636] | 0.09756677 |
| ICCak | 0.9381230 | [0.8391454, 0.9819406] | 0.02787953 |
| ICCakhat | 0.8348117 | [0.6348443, 0.9476252] | 0.06623144 |
| ICCc1 | 0.8162174 | [0.6060506, 0.9225133] | 0.06609010 |
| ICCck | 0.9638301 | [0.9023993, 0.9862444] | 0.01535940 |
| ICCqkhat | 0.8536545 | [0.6722265, 0.9433816] | 0.05613101 |

Variance components (p. 1057): `S_s = 6.395159` [2.5493364, 10.197685],
SE 1.9318809; `S_r = 1.090926` [**−0.5495179**, 2.732752], SE 0.8399057;
`S_sr = 1.439958` [0.6267899, 2.261192], SE 0.4146040. Rater design:
`k = 6.000`, `khat = 2.000`, `Q = 0.345`. Note the **negative lower limit on the
rater variance** as printed — the interval is not floored at zero.

## Traces to

- **ADR-002** (glmmTMB/lme4 MLE random-effects engine as the default) — the
  paper's MLE-RE arm, and its use of an explicit covariance matrix of the
  variance components (via `merDeriv` on `lme4`, p. 1050) as the CI input.
  ADR-002's argument that a joint variance-component covariance is *the* thing an
  MC CI samples from matches this paper's construction.
- **ADR-003** (Monte-Carlo CIs as the default interval method) — the abstract
  sentence (p. 1042) and the MLE-RE + MC coverage result (Fig. 7, p. 1054).
- The package's **delta-method scepticism** (PRINCIPLES #3): the paper's own
  statement that delta-method CIs assume normality of the ICC itself (p. 1047)
  and that both ML methods with delta-method CIs under-covered at the highest
  missingness (p. 1053).
- The **incomplete-design `k̂` (harmonic mean) and `q` scaling** in Table 1
  (p. 1046) — the incomplete-data ICC forms the package's ragged paths compute.
- The **few-raters failure axis** (p. 1057), matching `tenhove2022.md`'s finding
  and the package's GP6 posture.

## Open questions

1. **ADR-003's decision text says draws are taken "on the engine's internal
   (boundary-respecting) scale" — this paper does not say that.** What p. 1047 /
   p. 1050 / p. 1057 describe is resampling the **variance components from their
   estimated joint distribution**, with no transformation named, and the
   published example prints a **negative lower CI limit for `S_r`** (p. 1057).
   The package's log-SD-scale, non-negative variant is therefore a *departure
   from*, not a restatement of, the sourced method. Flagging as a sourcing-honesty
   finding for review; no oracle value is implicated and none is proposed here.
   Re-confirmed at M69 against ADR-003 in `cairn/legacy/DECISIONS.md`, whose
   decision text does read "on the engine's internal (boundary-respecting) scale"
   — observed 2026-07-18. Still standing.
2. **ADR-003's quoted sentence is accurate** but is attributed simply to "the
   abstract"; the exact printed location is p. 1042 (abstract), and the paper's
   phrase for the comparison set is MCMC-HL / MLE-RE / MLE-CF with ANOVA as
   benchmark — worth pinning in the ADR if precision matters at review.
   Re-confirmed at M69: ADR-003 attributes the sentence to "(abstract)" and the
   sentence is printed verbatim in the abstract on p. 1042 — observed 2026-07-18.
3. **No boundary-fit policy is stated in this paper.** The nearest thing is
   follow-up simulation 2 (p. 1056): near-zero `σ²_r` is *estimated* badly (up to
   200% overestimation) but the ICC is unaffected because `σ²_s` dominates. The
   package's boundary-fit policy is therefore not sourced here; this paper
   supports only the weaker claim that near-zero rater variance does not spoil the
   ICC point/variability estimates in the tested cells.
4. **Supplementary Materials A and B are not in the shelf PDF** — observed
   2026-07-18 (re-confirmed M69: the article file is 21 pages, ending with the
   reference list on printed p. 1061). The complete
   result tables (Tables 1–2, all 48 conditions), the anchor-rater Table 3, the
   full data example (Table 4), and follow-up 2's Figures 1–3 are cited (pp. 1051,
   1055, 1056) but unavailable — so no full-grid values can be extracted. OSF:
   ten Hove et al. (2022a), doi:10.17605/OSF.IO/TMD3X (p. 1049).
5. **Figures 3–8 are graphical only**; every number I report from them is
   plot-read and marked approximate. No table of coverage rates is printed in the
   article body, so this paper supplies **no committable oracle values** for
   coverage — unlike `ukoumunne2003.md`'s Table I. The p. 1057 real-data output is
   the only fully printed numeric block.
6. `ORACLES.md` does not cite this paper as an oracle for any entry — grep for
   "ten Hove" returns only 2020, 2022 and Eq.-14 entries, re-run and still true
   **— observed 2026-07-18** (M69) — which is consistent with its ADR-only role.
   No disagreement found.
