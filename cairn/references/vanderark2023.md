# vanderark2023 — optimizing a planned-missing observational design for IRR on a fixed budget

**Provenance.** Ingested 2026-07-19 (post-M66, direct correction) from `cairn/references/sources/vanderark2023.pdf` (gitignored).
Pagination: printed chapter pages 1–15; the 15 PDF pages map one-to-one onto printed 1–15. This copy **is** the version of record (publisher-set, full series/volume/DOI printed).
**Supersedes the `jorgensen2019` note**, which was written from `sources/jorgensen2019.pdf` — an author manuscript of this same study. See "Relationship to the preprint" below; that note is deleted, this one replaces it.
Extraction: verified 2026-07-19 against the source (all 15 PDF pages read to the final page — the **Appendix at pp. 11–13 carries annotated R *and Stan* source** and sits before the References); the population ICC 0.636 and the follow-up ICCs .42/.70 were recomputed from the printed variance components, and the paper's aggregate coverage and width claims were recomputed from the Table 2 per-cell values and agree — observed 2026-07-19.

**Citation.** van der Ark, L. A., Jorgensen, T. D., & ten Hove, D. (2023). "Factors
Affecting Efficiency of Interrater Reliability Estimates from Planned Missing Data
Designs on a Fixed Budget." In M. Wiberg, D. Molenaar, J. González, J.-S. Kim, &
H. Hwang (Eds.), *Quantitative Psychology. IMPS 2022* (Springer Proceedings in
Mathematics & Statistics, Vol. 422, pp. 1–15). Springer, Cham.
DOI 10.1007/978-3-031-27781-8_1. "© The Author(s), under exclusive license to
Springer Nature Switzerland AG 2023." Affiliations: Universiteit van Amsterdam
(van der Ark, Jorgensen); Universiteit van Amsterdam and Vrije Universiteit
Amsterdam (ten Hove). Supplementary materials: `https://osf.io/g5hvs/`.

**Sourcing of the volume metadata.** The chapter PDF itself prints only
"M. Wiberg et al. (eds.), Quantitative Psychology, Springer Proceedings in
Mathematics & Statistics 422" and the DOI (p. 1) — it names **no** meeting, no
full editor list, and no publisher city. The meeting (**IMPS 2022**), the five
editors, and "Springer, Cham" come from the publisher's own citation for this
chapter, supplied by the maintainer 2026-07-19 — recorded as maintainer-supplied
publisher metadata rather than as something read off the shelf copy.

**⚠ Do not copy the publisher's rendering of the two Dutch surnames.** Springer's
citation generator emits "Ark, L.A.v.d." and "Hove, D.t.", splitting the
tussenvoegsels *van der* and *ten* off the surnames. The chapter's own byline
(p. 1) prints "L. Andries van der Ark" and "Debby ten Hove", and the running
header prints "L. A. van der Ark et al." The correct alphabetization is under
**V** (van der Ark) and **t/H** (ten Hove) as this repo files them — the citekey
`vanderark2023` follows the byline, not the generator. Flagged because the
generator's form is what a reader copying from the publisher page will land on,
and it would wrongly suggest a citekey of `ark2023`.

## Relationship to the preprint (why the citekey changed)

`sources/jorgensen2019.pdf` is an author manuscript of this same study, and M66
ingested it as `jorgensen2019.md` under a citekey whose year the manuscript itself
contradicted (it printed no year, cited works from 2021–2022, and was typeset
2022-09-27). The published chapter resolves that, and changes one thing a citekey
cannot absorb quietly:

- **The first author differs.** The manuscript lists *Jorgensen, van der Ark, ten
  Hove*; the published chapter lists **van der Ark, Jorgensen, ten Hove**. A
  citekey built from the preprint's byline is therefore unfindable from the
  published record — which is why the note is renamed rather than re-dated.
- **Same study, verified.** Identical population values (`σ²_s = 0.70`,
  `σ²_r = 0.15`, `σ²_sr = 0.25` → `ICC(A,1) = 0.636`), identical budget
  (`N_Ratings = 384`), identical missingness range (83.33 %–98.96 %), and
  identical effect sizes (`η²_p` = 14.74 / 11.38 / 15.64 / 2.74 %).
- **The published version adds material the preprint lacked**: a per-cell results
  table (Table 2), two BCI-width figures with empirical-interval overlays
  (Figs. 1–2), and an Appendix containing the R data-generation functions and the
  Stan model. Anchors below are to the published chapter throughout.

The preprint PDF was still on the gitignored shelf when this note was written — observed 2026-07-19 — but nothing depends on it: no committed page reads that path, and this note's account of the manuscript rests on the reading done at M66, not on the file's continued presence. It can be deleted freely. <!-- check: none — an explicit write-time claim about the gitignored shelf (cairn/references/sources/); the note itself states nothing depends on the file and it can be deleted freely, so there is no committed state to settle -->

**Role.** Design-planning evidence, not an estimator source. **No oracle value
traces here**, and no test, vignette, or `ORACLES.md` entry reads it — observed
2026-07-19. <!-- check: ! git grep -qiF 'vanderark' -- R tests vignettes cairn/references/ORACLES.md --> Its interest to this package is that it validates MCMC estimation of
exactly the package's `ICC(A,1)` estimand under extreme planned missingness, now
with per-cell coverage rather than an aggregate, and that it is the closest thing
on the shelf to a sourced answer for "how should I allocate raters and subjects?"

## The model and estimand — the package's own

Two-way model, Eq. (1), p. 3: `Y_sr = μ + μ_s + μ_r + μ_sr`, with `μ_sr` the
subject × rater interaction "confounded with any other source of measurement
error". Decomposition, Eq. (2), p. 3: `σ²_Y = σ²_s + σ²_r + σ²_sr`.

Eq. (3), p. 3 — **identical to this package's crossed two-way absolute-agreement
single-rater coefficient**:

`ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_sr)`

"interpreted as the degree to which subjects' absolute scores can be generalized
over raters". The average-of-`k` form is given in the same paragraph: reliability
is increased "by dividing the rater-related variance components in the denominator
of Equation (3) by the number of raters `(σ²_r + σ²_sr)/k`" — the package's
`unit = "average"` divisor.

Ordinal outcomes via a latent response variable / probit formulation, Eq. (4),
p. 3: `X_sr = c if τ_c < Y_sr ≤ τ_{c+1}`, under `σ²_sr = 1`. Footnote 1 (p. 3):
there are `C + 2` thresholds with `τ_0 = −∞`, `τ_{C+1} = +∞`.

## Planned-missing-design vocabulary (§ 1.2, p. 4; Table 1, p. 5)

- **budget** — total ratings, `N_Ratings`; **workload** — subjects per rater,
  `N_{S/R}`; **team size** — raters per subject, `N_{R/S}`; pools `N_S`, `N_R`.
- Budget identity (Table 1 note): `N_Ratings = N_R × N_{S/R} = N_S × N_{R/S}`,
  "assuming equal team sizes across subjects and equal workload across raters";
  block design gives `block size = N_{S/R} × N_{R/S}`,
  `N_Blocks = N_Ratings / block size`.

Table 1 is now laid out as **Reduction → Consequence**: a smaller pool of subjects
requires larger teams; a smaller pool of raters requires greater workload;
assigning fewer raters per subject requires a larger subject pool; assigning fewer
subjects per rater requires a larger rater pool. Conversion formulas in footnotes
a–d, e.g. `N_S = N_R × (N_{S/R}/N_{R/S})`.

Worked illustration, p. 4 (Yuen et al. 2020): `N_R = 2` raters observing all
`N_S = 29` subjects gives workload 29; holding `N_Ratings = 58` and
`N_{R/S} = 2` but drawing from `N_R = 6` raters cuts workload to 9 or 10 —
"reduced the workload by `N_{R/S}/N_R = 1/3`". The study's own consequence
(p. 4): the results "led Van der Ark et al. (2018) to evaluate the LIJ by
assigning teams of `N_R = 4` raters to evaluate `N_{S/R} = 2` subjects each".

## Simulation design (§ 2, pp. 5–6)

Population values, p. 5: `σ²_s = 0.70`, `σ²_r = 0.15`, `σ²_sr = 0.25`, "implied a
population `ICC(A,1) = 0.636`, denoted `ρ`"; ordinal thresholds `τ_1 = −0.5`,
`τ_2 = 0.5` giving `C = 3`; fixed budget `N_Ratings = 384`.
**Recomputed (this note):** `0.70/1.10 = 0.6364` ✓.

Core factors, p. 6: team size `N_{R/S} ∈ {2, 4, 8}` × workload
`N_{S/R} ∈ {1, 2, 4, 8}` × model (linear vs. probit) = **24 conditions**.
Missingness "varied from 83.33 % … to 98.96 %". Design boundary, p. 6: at
`N_{S/R} = 1` "there is no 'missing-data problem' because raters are nested in
(rather than crossed with) subjects", so `μ_r` and `σ²_r` are dropped and a
one-way model used — "Thus, Eq. (3) still represents `ICC(A,1)`".

Estimation, § 2.2, p. 6: MCMC "with uninformative priors, implemented in the Stan
software", 2000 replications per condition; posterior mean as point estimate;
central 95 % BCIs; criteria are relative bias `(ρ̄ − ρ)/ρ`, coverage, and — "our
primary criterion for choosing an optimal design" — average BCI width.

## Results

**Table 2 (p. 7)** is the per-cell record the preprint lacked: bias, coverage, and
width for each of the 24 core conditions. Observed ranges as printed:

| Scale | Bias | Coverage | Width |
|---|---|---|---|
| Continuous | −0.024 … −0.010 | 0.934 … 0.951 | 0.173 … 0.225 |
| Ordinal | +0.002 … +0.012 | 0.934 … 0.956 | 0.211 … 0.252 |

Note the sign split, visible only in this table: continuous conditions are
uniformly *negatively* biased and ordinal conditions uniformly *positively*
biased. Coverage never leaves `[0.934, 0.956]` in any of the 24 cells.

**Aggregates recomputed from Table 2 (this note, not the paper's arithmetic).**
Mean coverage over all 24 cells = **0.9438** (paper: `M_cov = 0.94`); mean width
0.1915 continuous / 0.2297 ordinal (paper: 0.19 / 0.23); mean width by team size
0.2016 / 0.1983 / 0.2319 for `N_{R/S}` = 2 / 4 / 8 (paper: 0.20 / 0.20 / 0.23).
All reproduce. ✓

Stated core findings, p. 9: bias negligible (`M_bias = −0.01, SD = 0.01`),
coverage nominal (`M_cov = 0.94, SD = 0.01`), with no design factor explaining
more than 0.05 % of variance in bias or deviance in coverage. Precision was
affected only by scale (`η²_p = 14.74 %`) and team size (`η²_p = 11.38 %`).
Explanation, p. 9: smaller teams maximize `N_S` at a fixed budget, and "because
`σ²_s` should be expected to be the largest component of an ICC in practice …, a
more efficiently estimated `σ²_s` could lead to a more efficiently estimated `ρ`".

**Figs. 1–2 (p. 8)** plot BCI width by workload, team size, and true ICC, for
continuous and ordinal data. They overlay the *empirical* interval width (2.5–97.5
percentiles of posterior means across replications): p. 9 notes these are
"included for comparison; similarity with BCIs indicates accurate estimates of
uncertainty" — i.e. the figures are a calibration check, not just a precision plot.

**Magnitude of ICC (§ 3.2, p. 9).** Varying `σ²_r ∈ {0.05, 0.25, 0.70}` extends
the design to **72 conditions**, implying `ρ = .70`, `.636`, `.42` —
**recomputed:** `0.70/1.00 = 0.70` and `0.70/1.65 = 0.4242` ✓. Bias
`M = −0.002, SD = 0.014`; coverage `M = 0.94, SD = 0.01`; efficiency driven by `ρ`
(`η²_p = 15.64 %`), widths 0.19 / 0.21 / 0.25 at `ρ` = 0.70 / 0.64 / 0.42.

Explicit anti-generalization, p. 9 — worth quoting because it fences the headline
result: "This was consistent with our explanation for why smaller teams yielded
more precise estimates under a fixed budget; **it is not a general rule that fewer
raters (per subject) yield more precision** (Ten Hove et al., 2021)."

**Overlapping teams (§ 3.3, p. 10).** 36 conditions comparing block assignment to
unstructured random assignment. Bias `M = −0.005, SD = 0.013`; coverage
`M = 0.94, SD = 0.01`; overlap explained only `η²_p = 2.74 %` of additional width
variability. Conclusion, p. 11: "Overlapping raters does not seem to have any
(dis)advantage."

**Discussion, § 4, p. 10:** "MCMC estimation of MLMs and GLMMs can provide accurate
point and interval estimates of ICCs across a variety of population values, scales
of measurement, and planned missing observational designs, even when the vast
majority of observations of a conventional (fully crossed) two-way design are
missing."

## The Appendix (pp. 11–13) — what the preprint did not carry

Four annotated R functions (p. 11–12): `simcon()` (continuous data from the
random-effects model, with the printed defaults `subj = 0.7`, `rater = 0.15`,
`error = 0.25`, `nS = 16`, `nR = 32`), `simord()` (thresholds −0.5 / 0.5),
`pokeHoles()` (imposes the PMD pattern, random or block), and `trans()`
(wide→long).

The **Stan model (p. 13)** makes "uninformative priors" concrete — relevant to
this package's Bayesian path, where `tenhove2020.md` is the **O-Bayes** source for
half-*t*(4,0,1) hyperpriors on SDs. As printed here:

- `real<lower=0, upper=rangeRatings/2> sigmaS;` (likewise `sigmaR`, `sigmaE`)
- `Intercept ~ normal(0, rangeRatings/2);` and `eS ~ normal(0, sigmaS);`,
  `eR ~ normal(0, sigmaR);`
- the SD hyperprior line is present but **commented out** (`//sigmaS ~`), so the
  SDs carry only the bounded-uniform implied by their declared range
- `icc = sigmaS*sigmaS / (sigmaS*sigmaS + sigmaR*sigmaR + sigmaE*sigmaE);`

So the prior specification is a bounded uniform on each SD, **not** the half-*t*
of `tenhove2020` — a different specification reaching comparable coverage, which
is why this paper is corroboration rather than an oracle (below).

## What this could source

Nothing is proposed here — this note is a source-record correction, not a change
of scope.

- **Corroborating evidence for the Bayesian engine under incomplete designs.**
  Table 2 now gives **per-cell** coverage on the package's own `ICC(A,1)` estimand
  under 83–99 % missingness, never leaving `[0.934, 0.956]` across 24 cells. That
  is materially stronger than the preprint's aggregate. It is still **not an
  oracle**: the prior is a bounded uniform on the SDs (Appendix p. 13), whereas
  the package's **O-Bayes** entry traces to `tenhove2020`'s half-*t*(4,0,1)
  hyperpriors — a different specification, so the numbers cross-check the *design*
  conclusion, not the package's estimator.
- **A sourced design-allocation result** for the crossed incomplete case (Table 1
  algebra + the smaller-teams finding), whose criterion **is** interval width.
  Closer than `shieh2015`'s point-estimator MSE result to what the parked
  `d_study()` CI-width precision-planning candidate is gated on
  (`cairn/ROADMAP.md:39`, restated at `cairn/DESIGN.md:41`), though still not that
  oracle.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page —
observed 2026-07-19. <!-- check: ! git grep -qiF 'vanderark' -- R tests vignettes cairn/references/ORACLES.md -->

- `cairn/references/jorgensen2021.md` — the *other* Jorgensen paper, cited here
  (p. 3) on SEM being problematic for sparse PMD data. Distinct work; the
  preprint-era confusion this note used to warn about is now moot, since the
  citekeys no longer share a surname-year shape.
- `cairn/references/tenhove2022.md` — cited here as "Ten Hove et al. (2021),
  *Psychological Methods*, 27(4), 650–666" (p. 14), i.e. **with** the volume and
  pages the repo's own shelf copy lacks; the repo files it under `tenhove2022`
  after its version-of-record year.
- `cairn/references/tenhove2024.md` — cited here as "Ten Hove et al. (2023),
  Updated guidelines …" (p. 14); the repo files it under `tenhove2024`.
- `cairn/references/tenhove2020.md` — the **O-Bayes** hyperprior source, cited
  here (p. 14) and contrasted under the Appendix above.
- `cairn/references/shieh2015.md` — the one-way design-allocation sibling.
- `cairn/references/BIBLIOGRAPHY.md` (entry) and `INDEX.md`.

## Open questions

- *(Resolved 2026-07-19.)* The chapter does not name its meeting, so this note
  first recorded none. The maintainer supplied the publisher's citation, which
  gives **IMPS 2022**, the five editors, and Springer Cham; these are now in the
  Citation block, marked as publisher metadata rather than read off the shelf copy.
- Three different year conventions now coexist for the two ten Hove papers this
  chapter cites (its 2021/2023 vs. the repo's `tenhove2022`/`tenhove2024` vs. the
  preprint's 2021/2022). All four labels denote two works. Recorded so the drift
  is not mistaken for four separate sources.
