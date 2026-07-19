# jorgensen2019 — optimizing a planned-missing observational design for IRR on a fixed budget

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/jorgensen2019.pdf` (gitignored).
Pagination: **chapter-internal manuscript pages 1–10**. The shelf copy is an author manuscript — no publisher, volume, issue, or journal page range appears anywhere in it, and its page numbers restart at 1 — so every anchor below is a manuscript page, written `ms. p. N`.
Extraction: verified 2026-07-19 against the source (all 10 manuscript pages read through the closing Bibliography); the population ICC 0.636 and the two follow-up ICCs .42/.70 were recomputed from the printed variance components and agree; the citekey-year problem below was found by reading the Bibliography — observed 2026-07-19.

**Citation.** Jorgensen, T. D., van der Ark, L. A., & ten Hove, D. "Factors
Affecting Efficiency of Interrater Reliability Estimates from Planned Missing
Data Designs on a Fixed Budget." Affiliations as printed: Universiteit van
Amsterdam (all three) and Vrije Universiteit Amsterdam (ten Hove). ORCIDs are
printed for all three authors. Supplementary materials: `https://osf.io/g5hvs/`.
**No year, venue, volume, or pages are printed on this copy** — see the citekey
warning immediately below.

> **⚠ The citekey year is not corroborated and is contradicted by internal
> evidence.** This copy carries no publication year of its own, and two facts put
> it well after 2019: its Bibliography cites **ten Hove et al. (2021)** and **ten
> Hove et al. (2022)** (ms. pp. 9–10), and the PDF was typeset by pdfTeX on
> **2022-09-27** (file metadata). The citekey `jorgensen2019` is therefore a
> label, not a sourced year, and `BIBLIOGRAPHY.md` must not state 2019 as the
> publication year on this evidence — flagged for the maintainer — observed
> 2026-07-19.

**Not to be confused with `jorgensen2021`.** Different paper, different first-author
role, different subject: `jorgensen2021.md` is Jorgensen, T. D. (2021), "How to
estimate absolute-error components in structural equation models of
generalizability theory", *Psych* 3(2):113–133 — the sole-authored **O-SEM**
source backing the M7 lavaan engine. This one is a three-author simulation study
about *observational design efficiency* and sources no estimator. Confusingly,
this paper **cites** that one (ms. p. 3, on SEM being "problematic for sparse
data from PMD designs").

**Role.** Design-planning evidence, not an estimator source. **No oracle value
traces here**, and no test, vignette, or `ORACLES.md` entry reads it — its only
in-repo citations are the `BIBLIOGRAPHY.md` entry and `INDEX.md` line added by
M66 itself. Its interest to this package is
that it validates MCMC estimation of exactly the package's `ICC(A,1)` estimand
under extreme planned missingness (83–99 % missing), and that it is the closest
thing on the shelf to a sourced answer for "how should I allocate raters and
subjects?" — the question the parked `d_study()` precision-planning candidate
asks.

## The model and estimand — the package's own

Two-way model, Eq. (1), ms. p. 2: `Y_sr = μ + μ_s + μ_r + μ_sr`, where `μ_s` and
`μ_r` are "main subject and rater effects, respectively, and `μ_sr` is the
subject × rater interaction (confounded with any other source of measurement
error)". Variance decomposition, Eq. (2), ms. p. 2:
`σ²_Y = σ²_s + σ²_r + σ²_sr`.

Eq. (3), ms. p. 3 — **identical to this package's crossed two-way
absolute-agreement single-rater coefficient**:

`ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_sr)`

described as "the degree to which subjects' absolute scores can be generalized
over raters (relevant when evaluating whether a subject meets an absolute
criterion)". The average-of-`k` form is given in the same paragraph: averaging
over `k > 1` raters increases reliability "by reducing rater-related error:
`(σ²_r + σ²_sr)/k`" — the package's `unit = "average"` divisor.

Ordinal outcomes are handled by a latent response variable / probit
formulation, Eq. (4), ms. p. 3: `X_sr = c if τ_c < Y_sr ≤ τ_{c+1}`, under the
identification constraint `σ²_sr = 1`. Footnote 3 (ms. p. 3): there are `C + 2`
thresholds, with `τ_0 = −∞` and `τ_{C+1} = +∞`.

## Planned-missing-design vocabulary (§ 1.2, ms. p. 3, and Table 1, ms. p. 4)

Four quantities, all defined explicitly:

- **budget** — total number of ratings, `N_Ratings`
- **workload** — subjects per rater, `N_{S/R}`
- **team size** — raters per subject, `N_{R/S}`
- pool sizes `N_S` (subjects) and `N_R` (raters)

Budget identity (Table 1 note): `N_Ratings = N_R × N_{S/R} = N_S × N_{R/S}`,
"assuming equal team sizes across subjects and equal workload across raters".
For a block design, `block size = N_{S/R} × N_{R/S}` and
`N_Blocks = N_Ratings / block size`.

Table 1 states the trade-off in both directions: a smaller pool of **subjects**
requires assigning more raters per subject (larger teams); a smaller pool of
**raters** requires more subjects per rater (greater workload); assigning fewer
raters per subject requires a larger subject pool; assigning fewer subjects per
rater requires a larger rater pool. The four conversion formulas are given in the
table footnotes, e.g. `N_S = N_R × (N_{S/R} / N_{R/S})`.

Worked illustration, ms. p. 4 (Yuen et al. 2020): with `N_R = 2` raters observing
all `N_S = 29` subjects, each rater's workload is 29. Holding the budget at
`N_Ratings = 58` and the team size at `N_{R/S} = 2` but drawing from `N_R = 6`
raters cuts the workload to 9 or 10 — "reduced the workload by `N_{R/S}/N_R = 1/3`".

## Simulation design (§ 2, ms. pp. 5–6)

Population values, ms. p. 5: `σ²_s = 0.70`, `σ²_r = 0.15`, `σ²_sr = 0.25`,
"implied a population `ICC(A,1) = 0.636`, denoted `ρ`". Ordinal conditions used
thresholds `τ_1 = −0.5`, `τ_2 = 0.5` giving `C = 3` categories. Fixed budget
`N_Ratings = 384`. Missingness in the two-way designs "varied from 83.33 % … to
98.96 %".

**Independent recomputation (M66).** `0.70/(0.70 + 0.15 + 0.25) = 0.70/1.10 =
0.6364` ✓ matches the printed 0.636.

Core factors (ms. p. 5): team size `N_{R/S} ∈ {2, 4, 8}` × workload
`N_{S/R} ∈ {1, 2, 4, 8}` × model (linear vs. probit) = **24 conditions**. Note
the design boundary: "When `N_{S/R} = 1`, we used an one-way model by removing
`μ_r` from Equation 1 and its variance component `σ²_r` from Equation 2 because
when raters are nested in subjects, `μ_r` is confounded with the rater × subject
interaction. Thus, Eq. 3 still represents `ICC(A,1)`."

Estimation (§ 2.2, ms. p. 6): MCMC "with uninformative priors, implemented in the
Stan software (Carpenter et al., 2017)", 2000 replications per condition.
Posterior mean as the point estimate; central 95 % Bayesian credible intervals.
Criteria: relative parameter bias `(ρ̄ − ρ)/ρ`, BCI coverage, and — "our primary
criterion for choosing an optimal design" — average BCI **width**.

## Results

**Core conditions (§ 3.1, ms. p. 6).** Bias negligible: `M_bias = −0.01,
SD = 0.01`, "no design factors explained more than 0.05 % of variance in bias".
Coverage nominal: `M_cov = 0.94, SD = 0.01`, again with no design factor
explaining more than 0.05 % of deviance. Precision was affected only by scale
(`η²_p = 14.74 %`) and team size (`η²_p = 11.38 %`):

| Factor | Level | Mean 95 % BCI width | SD |
|---|---|---|---|
| Scale | continuous | 0.19 | 0.03 |
| Scale | ordinal | 0.23 | 0.02 |
| Team size | `N_{R/S} = 2` | 0.20 | 0.03 |
| Team size | `N_{R/S} = 4` | 0.20 | 0.03 |
| Team size | `N_{R/S} = 8` | 0.23 | 0.02 |

Stated explanation (ms. p. 6): smaller teams maximize `N_S` at a fixed budget,
and "because `σ²_s` should be expected to be the largest component of an ICC in
practice…, a more efficiently estimated `σ²_s` could lead to a more efficiently
estimated `ρ`".

**Magnitude of ICC (§ 3.2, ms. p. 7).** Varying `σ²_r ∈ {0.05, 0.25, 0.70}`
extended the 24 core conditions to **72**. The three implied population ICCs are
`ρ = .70` (`σ²_r = 0.05`), `ρ = .636` (core), and `ρ = .42` (`σ²_r = 0.70`) —
**recomputed and confirmed (M66)**: `0.70/1.00 = 0.70` and `0.70/1.65 = 0.4242`.
Bias `M = −0.002, SD = 0.014`; coverage `M = 0.94, SD = 0.01`. Efficiency was
driven by `ρ` itself (`η²_p = 15.64 %`): mean BCI widths 0.19 (`ρ = 0.70`), 0.21
(`ρ = 0.64`), 0.25 (`ρ = 0.42`).

**An explicit anti-generalization, ms. p. 7** — worth quoting because it fences
the headline result: "This was consistent with our explanation for why smaller
teams yielded more precise estimates under a fixed budget; **it is not a general
rule that fewer raters (per subject) yield more precision** (Ten Hove et al.,
2021)."

**Overlapping teams (§ 3.3, ms. p. 7).** A 3 × 3 × 2 × 2 = 36-condition follow-up
comparing block assignment to unstructured random assignment. Bias
`M = −0.005, SD = 0.013`; coverage `M = 0.94, SD = 0.01`; overlap explained only
`η²_p = 2.74 %` of additional BCI-width variability. Conclusion (ms. p. 8):
"Overlapping raters does not seem to have any (dis)advantage."

**Discussion (§ 4, ms. pp. 7–8).** "MCMC estimation of MLMs and GLMMs can provide
accurate point and interval estimates of ICCs across a variety of population
values, scales of measurement, and planned missing observational designs, even
when the vast majority of observations of a conventional (fully crossed) two-way
design are missing." Practical caveat (§ 4.1, ms. p. 8): in the LIJ study
"smaller teams (larger `N_S`) only improved precision by a few decimal places,
and workload had no discernible effect", so the recommendation was to assign
fewer subjects to larger teams.

## What this could source

Nothing is proposed here — M66 writes notes, not code (Scope).

- **Corroborating evidence for the Bayesian engine under incomplete designs.**
  Coverage of 95 % BCIs held at `M_cov = 0.94` across all three studies (24, 72,
  and 36 conditions) with 83–99 % missingness, on the package's own `ICC(A,1)`
  estimand. This is directionally supportive of the brms/posterior-interval path
  on incomplete data. It is **not usable as an oracle**: the figures are means
  aggregated over conditions with no per-cell table in this copy, the priors are
  described only as "uninformative", and the package's Bayesian oracle **O-Bayes**
  traces to `tenhove2020.md` (half-*t*(4,0,1) hyperpriors on SDs) — a different
  prior specification. Recorded as corroboration, not as a pin.
- **A sourced design-allocation result.** The team-size/workload/budget algebra
  of Table 1 and the "smaller teams at fixed budget" finding are published,
  citable design guidance for the *crossed incomplete* case. Note it points the
  **opposite way** from `shieh2015`'s one-way result only superficially: Shieh
  says more groups beat more judges at fixed `N·K`, and this paper says smaller
  teams (hence more subjects) at fixed `N_Ratings` — the same direction, reached
  in two different designs by two different criteria (point-estimator MSE vs.
  BCI width). Neither is the oracle the parked `d_study()` CI-width
  precision-planning candidate is gated on
  (`cairn/ROADMAP.md:39`, restated at `cairn/DESIGN.md:41`), but this one is closer, because
  its criterion **is** interval width. Recorded for whoever picks that candidate up.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page — observed 2026-07-19.

- `cairn/references/jorgensen2021.md` — the *other* Jorgensen paper, cited by
  this one (ms. p. 3); see the confusion warning above.
- `cairn/references/tenhove2022.md` — the M5 multilevel estimand source, cited
  here (ms. pp. 3, 10) as "Ten Hove et al. (2022)"; this paper's Eqs. 1–3 are the
  single-level case of that decomposition.
- `cairn/references/tenhove2020.md` — the **O-Bayes** hyperprior source, cited
  here (ms. pp. 6, 9) for evaluating posterior means as point estimates.
- `cairn/references/tenhove2025b.md` — the ADR-002/ADR-003 basis for preferring
  MLE with Monte-Carlo CIs on planned incomplete data; same design family.
- `cairn/references/shieh2015.md` — the one-way design-allocation sibling.
- `cairn/references/BIBLIOGRAPHY.md` (entry) and `INDEX.md`.

## Open questions

- **Publication year and venue are unknown from this copy** (see the citekey
  warning above). Resolving them needs a source not on the shelf; not guessed
  here (`PRINCIPLES.md` #4) — observed 2026-07-19.
- *(Resolved during T3, kept because it is a standing trap.)* Both ten Hove
  citations in this paper's Bibliography point at works the repo already holds
  under **later** citekeys, because this manuscript cited them before their
  versions of record appeared. Checked against the sibling notes:
  "Ten Hove et al. (2021), *Interrater reliability for multilevel data: A
  generalizability theory approach*" (ms. p. 10) is the repo's **`tenhove2022`**
  (*Psychological Methods* 27(4):650–666), and "Ten Hove et al. (2022), *Updated
  guidelines on selecting an intraclass correlation coefficient…*" (ms. p. 10) is
  the repo's **`tenhove2024`** (*Psychological Methods* 29(5):967–979). Neither is
  an uningested source. Recorded so a later reader does not chase two phantoms.
