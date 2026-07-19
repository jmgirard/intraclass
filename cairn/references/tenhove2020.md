# tenhove2020 — Comparing hyperprior distributions for IRR variance components

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/tenhove2020.pdf` (gitignored).
Pagination: author/accepted-manuscript PDF pages 1–14 — NOT the Springer typeset pages 79–93; convert explicitly before citing.
Extraction: unverified — first pass, values not yet re-read against the source — observed 2026-07-18.

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2020). "Comparing
Hyperprior Distributions to Estimate Variance Components for Interrater
Reliability Coefficients." In M. Wiberg et al. (Eds.), *Quantitative Psychology*
(Springer Proceedings in Mathematics & Statistics, Vol. 322, pp. 79–93).
Springer. DOI 10.1007/978-3-030-43469-4_7. OSF: `shkqm`
(https://osf.io/shkqm/, p. 8).

**Role.** The **O-Bayes** source (IP1) for the package's Bayesian (brms/Stan)
engine: it fixes the half-*t*(4, 0, 1) hyperprior on random-effect SDs, the
two-way crossed-random DGP, and the MAP + percentile-BCI recipe. Every O-Bayes-*
oracle in `ORACLES.md` cites this paper for its prior/recipe.

> **Pagination trap — read before citing a page.**
> The shelf PDF is the **author/accepted manuscript**, not the Springer typeset
> chapter. Its running heads print **pages 1–14** (e.g. "3 Hyperprior
> Distributions for IRR coefficients", p. 3 header), *not* the published 79–93.
> The title page carries no publisher, volume, DOI, or proceedings line — only
> title, the three authors, the Amsterdam affiliation, and `D.tenHove@uva.nl`
> (p. 1). **All anchors in this note are PDF/manuscript pages 1–14.** To convert
> approximately to the published chapter, add 78. The citation block above is
> the *published* record; it could not be verified from this file (see Open
> questions).

## Model and estimand (§2.1, p. 3)

Two-way crossed, Eq. 1 (p. 3): `Y_sr = μ + μ_s + μ_r + μ_sr`, with `μ_sr` the
inseparable Subject × Rater interaction plus random error; effects uncorrelated,
giving Eq. 2 (p. 3): `σ²_Y = σ²_s + σ²_r + σ²_sr`. Eq. 3 (p. 3):

  `ICC(A, k) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/k)`

**Table 1 (p. 4)** is the 2 × 2 grid — {Agreement, Consistency} × {single rater,
average of *k* raters}; the consistency forms drop `σ²_r` from the denominator.
Scope (p. 3): raters nested within subjects are set aside — "`μ_r` and `μ_sr`
cannot be disentangled" (p. 3), so this paper is crossed-only.

Why `σ²_r` is the hard parameter (p. 4): few raters "vary little in the average
ratings", so its posterior "is overwhelmingly influenced by the specified
hyperprior distribution" (p. 4).

## The hyperpriors compared (§3, pp. 5–6)

Three families are *discussed* (p. 5): **uniform**, **inverse-gamma**, and
**half-*t* / half-Cauchy**.

- **Uniform (§3.1, pp. 5–6).** On random-effect SDs over `[0, (max_Y − min_Y)/2]`
  (p. 5). Data-dependent if `max_Y`/`min_Y` come from the data. Yields proper
  posteriors "only … if the number of clusters (here raters) exceeds 3 (or 4 when
  the hyperprior is specified for the random-effect variances)" (p. 6).
- **Inverse-gamma (§3.2, p. 6).** Judged "too influential" when `σ²` is small
  (p. 6) and improper-posterior-prone when very uninformative; the authors
  "consider the inverse-gamma hyperprior inappropriate for our purpose" (p. 6).
  **It was discussed but not simulated** (only three levels enter §4; see below).
- **Half-*t* / half-Cauchy (§3.3, p. 6).** Three parameters (shape, location,
  scale); half-Cauchy = half-*t* with `df = 1`. Because "for `σ²_r`, we expect
  values near zero", a half-*t* "with higher `df` = 4 is slightly more
  informative, and is recommended for variance parameters that are expected to
  have values near the lower bound of zero" (p. 6), citing Gelman (2019).

**Prior placement — SDs, not variances.** §2.2 (p. 4) says the *exposition* uses
variances "apart from when we specifically target the estimation of
random-effect *SD*s" (p. 4). The simulation is such a case: §4.1 (p. 7)
specified the hyperpriors "for the random-effect *SD*s (i.e., `σ_s`, `σ_sr`, and
`σ_r`) rather than the random-effect variances" (p. 7), and footnote 1 (p. 8)
confirms the Stan program "estimated random-effect *SD*s, from which we derived
the random-effect variances." **The prior is on SDs.**

### The verbatim prior specification (§4.1 "Independent variables", p. 7)

> "In the half-*t* conditions, we specified a half-*t*(4,0,1) hyperprior
> distributions for all random-effect *SD*s" (p. 7).

I.e. **half-*t*(df = 4, location = 0, scale = 1) on `σ_s`, `σ_r`, and `σ_sr`.**
Note the specification itself lives in **§4.1, p. 7**; §3.3 (p. 6) supplies only
the `df = 4` rationale, not the numeric spec.

The third simulated level is **mixed** (p. 7): "a uniform hyperprior
distribution for `σ_s` and `σ_sr`, and a half-*t* hyperprior distribution for
`σ_r`" (p. 7).

## Simulation DGP (§4.1 "Data generation", pp. 6–7) — verified against the repo's claims

Generated from Eq. 1 with the Eq. 2 parameters (p. 6):

| Repo's stated understanding | Printed in the PDF | Verdict |
|---|---|---|
| `N = 30` subjects | "drew `N` = 30 values of `μ_s`" (p. 6) | ✅ confirmed |
| `μ = 0` | "We fixed `μ` to 0" (p. 6) | ✅ confirmed |
| `σ²_sr = 0.5` | "30 × `k` values from `N`(0, `σ²_sr` = ½)" (p. 7) | ✅ confirmed |
| `σ²_s = 0.5` | printed as `N`(0, **`σ²_sr`** = ½) for `μ_s` (p. 6) | ⚠️ see below |
| `σ²_r ∈ {.01, .04}` | "`σ²_r` = .01 and `σ²_r` = .04" (p. 7) | ✅ confirmed |
| `k ∈ {2, 3, 5}` | "`k` = 2, 3, and 5" (p. 7) | ✅ confirmed |

⚠️ **The `σ²_s` = 0.5 line is a printed subscript slip, not a distinct value.**
The sentence generating the *subject* effects reads `N`(0, `σ²_sr` = ½) — the
same subscript used one line later for the interaction. That `σ²_s` is meant is
settled by p. 7: "The choice to keep `N`, `σ²_s`, and `σ²_sr` constant were
arbitrary" — `σ²_s` is named a fixed constant and no other value for it is
printed. The repo's `σ²_s = σ²_sr = 0.5` is consistent with the paper, but the
anchor is this reading of pp. 6–7, not a clean verbatim `σ²_s = ½`.

**Population ICCs (p. 7):** "The population ICCs of interrater agreement ranged
from 0.48 to 0.83". No per-cell values are tabulated. Consistency ICCs were
"further ignored" (p. 7) — the study reports agreement coefficients only.

**Design (p. 8):** 3 (`k`) × 2 (`σ²_r`) × 3 (hyperprior) = **18
between-replication conditions × 1000 replications**; × 2 point-estimate types ×
2 BCI types = **72 conditions in total**.

**MCMC (p. 8):** three chains × 1000 iterations, first 500 per chain burn-in,
last 500 saved → **1500 posterior draws**. `R̂` < 1.10; if violated, burn-in was
**doubled repeatedly** up to a **10,000** limit, after which the replication was
discarded. `N_eff` > 100, with iterations scaled by `120/min(N_eff)` if short.
Software: R, Stan via **`rstan`**, MAP via **`modeest`**, HPDIs via
**`HDInterval`**; OSF https://osf.io/shkqm/ (p. 8).

**Evaluation criteria (pp. 8–9):** convergence rate; **relative bias**
`(θ̄ − θ)/θ` with > .05 minor and > .10 substantial; 95% BCI coverage **< 90%
too narrow / > 97% too wide**; relative efficiency (mean posterior SD ÷ SD of
the posterior means) with < .90 / > 1.10 minor and < .80 / > 1.20 substantial.
Per footnote 1 (p. 8) the evaluated random-effect quantity is **`σ_r` (the SD)**,
not `σ²_r`.

## Findings (§4.2, pp. 9–12)

Reported for **ICC(A,1)** only — "the results for the estimated ICC(A,`k`)
resembled the results for ICC(A,1)" (p. 9) — and the mixed-hyperprior conditions
are not discussed because they were "very similar" to half-*t* (p. 9).

- **Convergence (p. 9).** "All replications in all conditions converged to a
  solution" — 18 × 1000 = 18,000 replications. (Read with the adaptive burn-in
  doubling on p. 8: convergence was *achieved*, not free.)
- **Bias, `σ_r` (text p. 9; Fig. 1, p. 10).** "EAPs severely overestimated
  `σ_r`, whereas the MAP was an unbiased estimator of this parameter in all
  conditions with `k` > 2" (p. 9). Fig. 1: EAP relative bias ≈ +2 (`σ²_r` = .01)
  to +4 (`σ²_r` = .04) at `k` = 2, falling to ≈ +0.5 at `k` = 5; MAP curves sit
  on ~0 except a small uniform-prior bump at `k` = 2 (plot-read, approximate).
- **Bias, ICC(A,1) (text p. 9; Fig. 2, p. 10).** "The MAP and EAP estimates of
  ICC(A,1) were comparable"; "Neither `σ_r` or ICC(A,1) resulted in unbiased
  estimates in any condition with `k` = 2. MAPs of both `σ_r` and ICC(A,1) were
  unbiased in all conditions with `k` = 5" (p. 9). Fig. 2: ICC(A,1) relative bias
  at `k` = 2 ≈ −0.3 (half-*t*) to −0.4 (uniform) — **biased low** — rising to
  ≈ −0.05 at `k` = 5 (plot-read). Half-*t* beat uniform for both (p. 9).
- **Coverage (text p. 9; Figs. 3–4, pp. 11–12).** "HPDIs were too wide for
  `σ_r`, but yielded nominal coverage rates for the ICC(A,1) for more than two
  raters. Percentiles yielded nominal coverage rates for `σ_r` and for the
  ICC(A,1), but only for `k` > 2" (p. 9). Fig. 3: `σ_r` HPDI coverage ≈97.5–100%
  (too wide) vs percentile ≈95–96%. Fig. 4: ICC(A,1) coverage at **`k` = 2 falls
  to ≈84–90%** (uniform worst, inside the "substantially too narrow" band),
  reaching ≈95–96% by `k` = 5 — **`k` = 2 undercovers for both interval types**
  (plot-read).
- **Efficiency (text p. 10; Fig. 5, p. 12).** Posterior SDs were "considerably
  larger than the actual sampling variability"; overestimation shrank with `k`
  "but remained severe even in conditions with `k` = 5" (p. 10), worse for `σ_r`
  (ratio ≈3–4.5 at `k` = 2) than ICC(A,1) (≈1.3–1.7) (plot-read).

## Recommendation (§5, pp. 11, 13)

"The best performing condition combined MAP point estimates, percentiles based
BCIs, half-*t* hyperprior distributions, and `k` > 2 raters" (p. 11). Half-*t*
has only "a slight advantage over uniform hyperprior distributions" (p. 11);
"the number of raters … had a larger effect … than the choice of hyperprior
distributions" (p. 11). The closing advice (p. 13) is the four-part recipe:
**half-*t* hyperprior on the random-rater-effect SD, MAP point estimates,
percentile-based BCIs, and at least three raters** — with Gelman's (2006) caveat
that any weakly-informative hyperprior is provisional and posterior propriety
should be checked (p. 13).

## Traces to

- **Oracle O-Bayes** (`ORACLES.md`, M23/ADR-033) — prior, DGP, MCMC settings,
  and the four reproducible findings.
- Every downstream Bayesian oracle that cites the "ten Hove et al. (2020)
  prior/recipe": O-Bayes-Fixed, O-Bayes-ML, O-Bayes-NML, O-Bayes-OW,
  O-Bayes-FML, O-Bayes-FNML, O-Bayes-Conflated, O-Bayes-Rep, O-Bayes-Incomplete,
  O-Bayes-IML, O-Bayes-IFixed, O-Bayes-IFML-fixed.
- The engine's **MAP + percentile** default (not EAP, not HPDI) — sourced at
  p. 9 and p. 13.
- The **few-raters failure axis** (GP6): `k` = 2 is biased low and undercovers
  (pp. 9, 11) — the same axis `tenhove2022.md` records for the multilevel case.
- The half-*t*(4, 0, 1) hyperprior cited second-hand in `tenhove2022.md` (p. 8
  of that note) resolves here.

## Open questions

- **Published-record fields are unverifiable from this file.** The manuscript PDF
  shows no publisher, editors, volume, DOI, or 79–93 pagination (p. 1); those
  fields in the citation above and in `BIBLIOGRAPHY.md` come from outside it.
  Not an oracle-value issue; flagged so the sourcing boundary stays honest.
- **`ORACLES.md` cites section numbers that do not exist in this version.** The
  O-Bayes entry anchors "§4.1.1" (data generation), "§4.1.2" (prior), "§4.1.3"
  (MCMC). This PDF has only **§4.1 Methods** with unnumbered bold paragraph
  headings and **§4.2 Results**. The *content* at each cited anchor matches;
  only the numbering is unattested. Citation hygiene — **no oracle value is
  affected and none is proposed for change.** Escalate.
- **The prior's home is §4.1, not §3.3.** `BIBLIOGRAPHY.md` places it at
  "§3.3/§4.1"; the numeric half-*t*(4,0,1) spec appears **only on p. 7 (§4.1)**,
  while §3.3 (p. 6) justifies `df = 4` without location/scale. A tightening, not
  a correction — escalate, do not edit.
- **Relative-bias sign convention.** The paper prints `(θ̄ − θ)/θ` (p. 9);
  `ORACLES.md` writes `|θ̄ − θ|/θ`. The paper's figures are signed (negative for
  ICC(A,1)), so the absolute-value form may be a transcription artifact.
  Escalate; not a value change.
- **Population ICC values are not tabulated** — only the range "0.48 to 0.83"
  (p. 7). `ORACLES.md`'s per-cell 0.4950 / 0.4808 are *derived* from Eq. 3 with
  the DGP parameters. They fall inside the printed range, so no disagreement is
  observed, but the derivation is the repo's, not the paper's.
- **No worked numeric example exists.** All results are figures (Figs. 1–5,
  pp. 10–12) with no tabulated cell values; every quantitative finding above that
  is not a quoted sentence is labelled **plot-read**. Exact per-cell numbers
  require OSF `shkqm`.
- **`σ²_s` never appears with its own subscript** (see the DGP table). A clean
  verbatim anchor for `σ²_s = 0.5` would have to come from the OSF code.
