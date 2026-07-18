# tenhove2025a — IRR for interdependent social network data (the RESRM)

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2025). "Interrater
Reliability for Interdependent Social Network Data: A Generalizability Theory
Approach." *Multivariate Behavioral Research* 60(3):444–459.
DOI 10.1080/00273171.2024.2444940. Open Access (CC BY 4.0), published online
03 Feb 2025. PDF: `cairn/references/pdf/tenhove2025a.pdf` (gitignored).

Verified against the title page (PDF p. 1) and the running head/masthead
(PDF p. 2: "2025, VOL. 60, NO. 3, 444–459"). This is the **60(3) network-data**
paper, not its sibling `tenhove2025b` (MBR **60(5)**:1042–1061, planned
incomplete data).

**Page-anchor basis.** All anchors below are **printed journal pages 444–459**
(visible in the page headers). The shelf PDF carries one extra Taylor & Francis
cover sheet, so printed page = PDF page + 442 (printed 444 = PDF p. 2).

**Role.** Shelf evidence for the **contract boundary** (IP2), not an oracle.
It is the closest sibling of `tenhove2022.md` — same authors, same GT framing —
extended to dyadic round-robin data, i.e. a design the package does not fit.

## Why this is a different design from tenhove2022 (pp. 445–447)

The rated unit is a **dyad**, not a subject. `Y_ijk` is "the score on attribute
Y of person i while interacting with person j … rated by rater k" (p. 445,
Table 1 caption). Each subject appears both as an *actor* and as a *partner*
in many dyads, so "all dyadic observations including actor i are nested within
actor i, and all dyadic observations including partner j are nested within
partner j" (p. 445) — a cross-classification that the subject×rater and
subject-nested-in-cluster designs of ten Hove et al. (2022) do not contain.

Baseline single-level GT model, **Eq. 1 (p. 446)**: `Y_ik = M + S_i + R_k + SR_ik`,
with **Eq. 2 (p. 446)**: `σ²_Y = σ²_S + σ²_R + σ²_SR`. The independent-data
consistency ICC, **Eq. 3 (p. 447)**: `ICC(C, K) = σ²_S / (σ²_S + σ²_SR/K)`,
`K = 1` recovering the single-rating form (p. 447).

Two scope narrowings the paper makes up front: interrater **agreement** is
discarded because absolute interpretation of actor/partner/relationship effects
is "unlikely" (p. 447), and **fixed raters** are set aside — the assumption "is
rarely, if ever, justified for IRR" (p. 447, citing ten Hove et al. 2024c).

## The social relations model (SRM) layer (p. 447)

**Eq. 4 (p. 447):** `Y_ij = M + A_i + P_j + E_ij` — actor effect of person i,
partner effect of person j, relationship effect of the ordered dyad; **Eq. 5
(p. 447)** stacks the dyad's two directed scores `[Y_ij, Y_ji]`.

Two dependence parameters have no analogue in a subject×rater design:
**generalized reciprocity** `ρ_AP`, the within-person correlation between `A_i`
and `P_i` (**Eq. 6, p. 447**), and **dyadic reciprocity** `ρ_E`, the correlation
between `E_ij` and `E_ji` (**Eq. 7, p. 447**, attributed to Kenny & La Voie
1984, p. 157).

SRM variance decomposition, **Eq. 8 (p. 448)**: `σ²_Y = σ²_A + σ²_P + σ²_E`,
with dyad-level covariance `Σ_Y = Σ_AP + Σ_PA + Σ_E` (**Eq. 9, p. 448**).
Appendix A (pp. 458–459) derives this; **Eq. A.26 (p. 459)** gives the
off-diagonal `σ_YY = 2 × σ_AP + σ_RR`.

## The rater-extended SRM (RESRM) — the paper's estimand (pp. 448–449)

**Eq. 11 (p. 448), the model:**

  `Y_ijk = M + μ_k + A_i + α_ik + P_j + π_jk + E_ij + ε_ijk`

Each SRM effect gains a **rater-specific deviation**: `μ_k` around the grand
mean, `α_ik` around the actor effect, `π_jk` around the partner effect, `ε_ijk`
around the relationship effect (confounded with random error, p. 448).
`μ_k ~ N(0, σ²_μ)` (**Eq. 13, p. 448**); `(α_ik, π_ik)` bivariate normal with
correlation `ρ_απ` (**Eq. 14, p. 448**); `(ε_ijk, ε_jik)` bivariate normal with
correlation `ρ_ε` (**Eq. 15, p. 449**).

**Eq. 16 (p. 449) — the seven-component decomposition:**

  `σ²_Y = σ²_μ + σ²_A + σ²_α + σ²_P + σ²_π + σ²_E + σ²_ε`

Contrast with tenhove2022 Eq. 7 (five components, `σ²_c + σ²_s:c + σ²_r +
σ²_cr + σ²_(s:c)r`): the subject facet splits into **actor + partner +
relationship**, each with its own rater-interaction term, and the dyad-level
covariance structure (Eq. 17, p. 449) carries `ρ_AP`, `ρ_E`, `ρ_απ`, `ρ_ε`.

### The ICCs (Table 2, p. 449; Eq. 19, p. 449)

All are **interrater consistency**, `(C, K)`. Numerator = the facet of
differentiation; denominator adds only that facet's rater-interaction term,
divided by K for averaged ratings. `σ²_μ` is excluded (main rater effects do
not affect relative standing, p. 447).

**Eq. 19 (p. 449)**, the actor-effect ICC:

  `ICC_A(C, K) = σ²_A / (σ²_A + σ²_α/K)`

Table 2 (p. 449), single ratings `(C, 1)` and averaged `(C, K)`:

| Facet of interest | `(C, 1)` | `(C, K)` |
|---|---|---|
| Actor `ICC_A` | `σ²_A/(σ²_A + σ²_α)` | `σ²_A/(σ²_A + σ²_α/K)` |
| Partner `ICC_P` | `σ²_P/(σ²_P + σ²_π)` | `σ²_P/(σ²_P + σ²_π/K)` |
| Relationship `ICC_E` | `σ²_E/(σ²_E + σ²_ε)` | `σ²_E/(σ²_E + σ²_ε/K)` |
| Integrated `ICC_Y` | `(σ²_A+σ²_P+σ²_E)/(σ²_A+σ²_P+σ²_E+σ²_α+σ²_π+σ²_ε)` | `(σ²_A+σ²_P+σ²_E)/(σ²_A+σ²_P+σ²_E+(σ²_α+σ²_π+σ²_ε)/K)` |

The proposed ICCs deliberately **omit dyadic reciprocity from the denominator**,
unlike Bonito & Kenny (2010), because the target is generalization across
*external* raters who are not part of the interactions (p. 450).

## Estimation (pp. 450–451)

Bayesian **MCMC only** — NUTS/HMC via Stan and `rstan` (p. 451). ANOVA, MLE and
SEM routes are named but not used; the Bayesian route is chosen because under
small rater samples and variance components "close to the boundary of zero" it
outperformed the SEM approach of ten Hove et al. (2024a) (p. 450). Likelihood is
bivariate normal on the dyad's two scores (**Eq. 20, p. 451**), predicted values
from **Eq. 21 (p. 451)**. Parameter count for a fully crossed design:
`12 + 2N + 2D + K + 2NK`, `D = N(N−1)/2` (p. 450, footnote 6).

**Intervals: 95% Bayesian credible intervals from posterior percentiles; point
estimates are MAP** (p. 451) — the same convention as tenhove2022.
Hyperparameters are estimated on the **SD** scale and the ICC posteriors derived
from the posterior SD draws (p. 451).

## Empirical example: social mimicry (pp. 451–452)

Data from Salazar Kämpf et al. (2018), OSF `b4nvf`: N = 139 German students in
26 same-sex networks of four to six, round-robin, `D = 309` dyadic interactions,
`K = 3` raters, 6-point Likert mimicry scale (p. 451). The original conflated
estimate was `ICC(2,3) = .87` (p. 451; footnote 8 notes `ICC(2,3)` = the paper's
`ICC(C, K)` of Eq. 3).

Estimation: 3 chains × 1,000 with 500 burn-in, doubled to 3,000 post-burn-in
draws; `R̂ < 1.10`, `N_eff > 100` (p. 452). Priors: half-*t*(4, 0, 1) on all
SDs, truncated to (0, 3); uniform(−1, 1) on the four correlations (p. 452).

**Table 3 (p. 452)** — RESRM variance components (MAP [2.5%, 97.5%], % variance):
`σ²_A` 0.37 [0.26, 0.54], 27%; `σ²_P` 0.09 [0.04, 0.17], 7%; `σ²_E` 0.46
[0.37, 0.58], 34%; `σ²_μ` 0.00 [0.00, 0.39], < 1%; `σ²_α` 0.11 [0.06, 0.18],
8%; `σ²_π` 0.00 [0.00, 0.05], < 1%; `σ²_ε` 0.33 [0.30, 0.36], 24%; total 1.39
[1.27, 1.81]. The SRM columns (Salazar Kämpf et al.'s MLE) give `σ²_A` 0.32,
`σ²_P` 0.07, `σ²_E` 0.47, `σ²_error` 0.46, total 1.32.

**Table 4 (p. 452)** — RESRM-based ICC estimates:

| ICC | `(C, 1)` est. [2.5%, 97.5%] | `(C, K)` est. [2.5%, 97.5%] |
|---|---|---|
| `ICC_Conf` | 0.68 [0.65, 0.72] | 0.87 [0.85, 0.88] |
| `ICC_Y` | 0.68 [0.63, 0.72] | 0.86 [0.84, 0.89] |
| `ICC_A` | 0.79 [0.68, 0.87] | 0.92 [0.86, 0.95] |
| `ICC_P` | 0.98 [0.65, 1.00] | 0.99 [0.79, 1.00] |
| `ICC_E` | 0.59 [0.52, 0.64] | 0.81 [0.77, 0.84] |

The conflated estimate tracks `ICC_Y` but "underestimate[s] the IRR of the
actor and partner components … and overestimate[s] the IRR of the relationship
component" (p. 452).

## Simulation study (pp. 453–455)

**Design (p. 453).** 2 (design: *good* vs *poor*) × 2 (parameters: *substantial*
vs *varying*) = 4 conditions × 1,000 datasets, generated with `mvrnorm`
(`rockchalk`) from Eq. 12. *Good* = 10 subjects fully interacting (45 dyads),
10 raters, 2 ratings per interaction → 900 dyadic observations. *Poor* =
the empirical design (groups of four to six, 309 interactions, 3 raters) →
2,154 dyadic observations. *Substantial* parameters: all SDs = 1.00, all
correlations = .30. *Varying* parameters: `σ_A = 0.60`, `σ_P = 0.30`,
`σ_E = 0.70`, `σ_α = 0.30`, `σ_π = 0.10`, `σ_ε = 0.60`, `ρ_AP = .70`,
`ρ_E = .70`, `ρ_απ = −.30`, `ρ_ε = .20`. Population ICCs: .50–.90 single,
.75–.99 averaged (**Table 5, p. 453**).

**Criteria (p. 453).** Relative bias `(θ̄ − θ)/θ`; .05–.10 minor, > .10
substantial. Coverage judged against Agresti–Coull intervals (< .93 or > .96
differs significantly from .95 at 1,000 replications); coverage < .90 called
"practically too low". Convergence: `R̂ < 1.10`, doubling post-burn-in up to
8,000 iterations or discard (p. 453). Convergence ran 98%–100% (p. 454).

**Headline results (Table 6 and Table 7, p. 454; Figs. 1–2, pp. 454–455).**
Good-design conditions are near-unbiased with near-nominal coverage. The failure
cell is **poor design × substantial parameters**:

- Relative bias, Table 6 (p. 454): `ICC_A(C,1)` +0.11, `ICC_A(C,k)` +0.05 under
  substantial/good; under substantial/**poor** `ICC_A(C,1)` +0.31 and
  `ICC_A(C,k)` +0.14, while `ICC_E(C,1)` −0.26 and `ICC_E(C,k)` −0.15.
- Coverage, Table 7 (p. 454): under substantial/poor, `ICC_A` = .45 and
  `ICC_E` = .06 (both single and averaged); `ICC_Y` = .92 and `ICC_P` = .90.
  Under substantial/good, `ICC_A` = .74 and `ICC_E` = .72 — already flagged
  outside the Agresti–Coull interval.

Diagnosis (p. 455): "few raters, small groups of interacting subjects, and
highly correlated rater effects" (p. 454) cause under-estimation of `σ²_α`
(0.71 vs 1.00) and over-estimation of `σ²_ε` (1.30 vs 1.00). The authors
conclude the RESRM-based ICCs "cannot be trusted for designs with few raters
and small subgroups of subjects" (p. 455) and explicitly advise against drawing
conclusions from their own empirical example's IRR estimates (p. 455).

A practical recommendation (p. 456): run a **validation substudy** — a subsample
of subjects rated by many raters — estimate the RESRM components there, and use
them to define IRR coefficients for the full design.

## Traces to

**Nothing in the test suite currently traces to this source; it is shelf
evidence for the contract boundary.** A grep of `cairn/references/ORACLES.md`,
`cairn/DESIGN.md`, `R/`, `tests/`, and `vignettes/` for `round-robin`,
`social relations`, `network`, `dyadic`, `RESRM`, and `tenhove2025a` returned
**zero matches**. No oracle entry, no estimator, no vignette passage depends on
it. (The only references are the bibliography/index entries M64 itself created.)

Its only live use is **negative**: it documents, from the package's own primary
author lineage, a GT-framework IRR design that the package does not and (per
IP2) plausibly should not fit.

## Open questions

- **Contract boundary: this design is OUT of scope as `DESIGN.md` currently
  states it — but by structure, not by IP2's wording.** IP2 fixes the boundary
  at "the interrater ICC family" permanently. The RESRM ICCs *are* interrater
  ICCs in the strict sense — GT consistency coefficients of the same
  `σ²_facet / (σ²_facet + σ²_facet×rater/K)` shape (Eq. 19, p. 449) — so IP2 as
  written does not obviously exclude them. What excludes them is the design:
  the unit is a directed dyad, the model needs cross-classified actor/partner
  effects with generalized and dyadic reciprocity (Eqs. 6–7, p. 447), and the
  likelihood is bivariate over each dyad's two scores (Eq. 20, p. 451). None of
  that is expressible in the package's design grammar. **A wording gap to
  escalate, not to resolve here:** whether "ICC-only identity" excludes
  dyadic/network designs is a D-entry question for the maintainer.
- **Engine feasibility, if the boundary were ever revisited.** MCMC/Stan is the
  only route reported (p. 451), and SEM was outperformed under small rater
  samples and near-zero variances (p. 450). Of the four rostered engines (GP4)
  only `brms` is in the right paradigm, and the bivariate dyad-level likelihood
  with correlated actor/partner effects is not a stock formula. No action
  implied.
- **No oracle conflict.** Nothing in `ORACLES.md` covers dyadic designs, so
  there is nothing to reconcile. Table 3 / Table 4 values above are recorded as
  *read*, not proposed as oracle values.
- **Not extracted.** Figures 1–2 (pp. 454–455) were read only as far as the
  numeric tables corroborate; plotted points were not digitized. Appendix A's
  intermediate algebra (A.1–A.25) is derivation, not reference values. The
  online supplement (OSF `9az5x`, p. 456) has not been retrieved.
- ~~**Sibling-key hygiene.**~~ *Resolved within M64 (T5): `BIBLIOGRAPHY.md` had
  only the 60(5) paper under a bare "ten Hove … (2025)". T5 added this 60(3)
  paper and gave both entries the `2025a`/`2025b` suffixes, so a bare "ten Hove
  et al. (2025)" no longer appears.*
