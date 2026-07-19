# bobak2018 — Inter-rater ICC under heteroscedasticity and pooled heterogeneity

**Provenance.** Ingested 2026-07-18 by M65 from `cairn/references/sources/bobak2018.pdf` (gitignored).
Pagination: the article's own printed pages (BMC per-article pagination — `18:93` is an article number, not a page range).
Extraction: verified — every value, anchor and quoted string re-read against the
shelf PDF, all 11 pages; the reference list ends the document on p. 11 with
nothing after it. All 13 Table 3 rows, all 3 Table 2 rows and every Table 4/5
value reproduce exactly, and each page anchor was confirmed by extracting that
page on its own (the `Page N of 11` footers make this checkable) — observed
2026-07-19 (M71). That per-page pass initially missed one prose anchor (the
0.944 sentence, anchored to p. 8 where its footer reads `Page 7 of 11`), caught
by independent review and corrected the same day; the table anchors it did check
all hold.

**Citation.** Bobak CA, Barr PJ, O'Malley AJ (2018). "Estimation of an inter-rater
intra-class correlation coefficient that overcomes common assumption violations
in the assessment of health measurement scales." *BMC Medical Research
Methodology* 18:93. DOI 10.1186/s12874-018-0550-6. Received 23 November 2017;
Accepted 23 August 2018; Published 12 September 2018. **Open Access**, CC BY 4.0.
Departments of Quantitative Biomedical Sciences and The Dartmouth Institute,
Geisel School of Medicine, Dartmouth College. Bobak and O'Malley
"contributed equally".

**Role.** Ingested by M65 as half of the distributional-robustness pair. **This
is the first M65 source that is genuinely an inter-rater ICC paper** — the same
estimand family the package computes. Nothing in the package traced to it and no
`ORACLES.md` entry cited it — observed 2026-07-19 (grep for `bobak` over `R/`,
`tests/`, `man/`, `vignettes/`, `data-raw/` and `ORACLES.md`: no hits) — but
unlike the rest of the cluster it is *inside*
the contract boundary and its critique lands on the package's own model
assumptions.

## Design applicability (AC2)

| Axis | What the paper covers |
|---|---|
| Domain | **Inter-rater reliability** of a health measurement scale — Observer OPTION⁵, two trained raters scoring recorded clinical encounters (Abstract; "Case study design", p. 5) |
| Design | **Crossed / two-way**: "the recorded encounters from all three studies were re-rated by the same two raters" (p. 5). Subjects are *encounters*; `R = 2` raters score every encounter |
| Raters | **Fixed, and modelled as a fixed effect** — `β₁(j − 1.5)` in Eq. (5), a single rater contrast, not a random rater variance |
| Definition | **Consistency, not absolute agreement.** The Discussion states it, and the operative word is *consistency*: "The measurement we've proposed here is an inter-rater, inter-case discriminatory ICC and hence applies for forms of the ICC … emphasizing consistency of measurements" (p. 9). Systematic rater difference is absorbed by `β[Rater]`, whose 95 % credible interval (−0.073, −0.051) **excludes zero** — there is a real rater offset, and the ICC is defined to ignore it |
| Estimation | **Bayesian** — MCMC via JAGS, driven from R by `rjags` ("Evaluation of Bayesian Estimation", p. 5) |
| Outcome scale | **Bounded** `(0, 1)` and truncated — Eqs. (3)–(4) put a `Normal(·) I(0,1)` on the rescaled score. The method is aimed at bounded scales specifically |
| Balance | Balanced in raters (both raters score every encounter), unbalanced across studies (`N₁ = 201`, `N₂ = 72`, `N₃ = 38`) |

**Mapping to the package.** Eq. (1)'s `ICC = σ²_b/(σ²_b + σ²_w)` with a fixed
rater effect removed is the **two-way mixed / fixed-rater consistency
single-rating** coefficient — the package's `ICC(C,1)` family, the Case-3A
territory of `mcgraw1996`. Eq. (2), `R = σ²_b/(σ²_b + σ²_w/k)`, is its
mean-of-`k` form. So the *baseline* estimand is one the package already computes;
what the paper adds is **not a new coefficient but two model extensions** — a
variance function and a multi-study hierarchy — that the package's homoscedastic
mixed model does not have.

## The two assumption violations, and what each costs

The paper's whole argument is that the standard ICC is **inflated** by two
common practices. Both are quantified on the same data, which is what makes the
paper useful rather than merely cautionary.

### 1. Heteroscedasticity — the variance function (Eq. 6)

The model (Eqs. 3–7, pp. 3–4). With `h` indexing study, `i` encounter, `j` rater:

```
Y_hij | θ_hi, X_hi ~ Normal(μ_hij, v²_hi) I(0,1)          (3)
μ_hij = θ_hi + β₁(j − 1.5) + β₂(X_hi − X̄)                 (5)
v²_hi = σ²_h · θ_hi(1 − θ_hi)                             (6)
θ_hi | study ~ Normal(γ_h, τ²_h) I(0,1)                   (7)
```

`θ_hi` is the true amount of shared decision making in the encounter; `X` is use
of a decision aid. **Eq. (6) is the contribution**: the within-encounter
(rater) variance is not constant but a *binomial-shaped function of the true
score*, largest at `θ = 0.5` and vanishing at the ends. The stated intuition
(p. 4): "it is easier to distinguish cases against a baseline level of a trait
close to 0% or 100% than cases in which the trait is about 50% present"
(percent signs unspaced, as printed).
Figure 3 (p. 6) is the empirical justification — a smoothing spline through the
observed between-rater variance against the mean score traces an inverted U that
the binomial variance function tracks and a constant mean variance plainly does
not.

The consequence is that **the ICC is no longer a single number** (Eq. 8, p. 4):

```
ICC_h(θ*) = τ²_h / (τ²_h + σ²_h θ*(1 − θ*))
```

It depends on the true score `θ*` at which you evaluate it. Figure 6 (p. 9)
plots this as a **U-shaped curve per study** — reliability is high at both ends
of the scale and worst in the middle. Eq. (9) then defines the population-average
ICC by integrating `ICC_h(θ*)` over a distribution `π(θ*)` of encounter values,
which is what the reported summary numbers are.

### 2. Pooling across heterogeneous studies (Eqs. 10–11)

Eq. (10) gives the marginal ICC when encounters are pooled across studies,
`ICC_Marg(θ*) = (ω² + τ̄²)/(ω² + τ̄² + σ̄²θ*(1 − θ*))`, and **Eq. (11) states the
inequality that is the paper's second warning: `ICC_Marg(θ*) ≥ ICC̄(θ*)`.**
Pooling can only inflate. The reasoning (p. 5): if the intended use is to compare
subjects within a homogeneous population, the pooled figure "makes the instrument
look better in a meaningless way as it overstates the heterogeneity between the
subjects compared to the heterogeneity between the individuals in the population
that the instrument will be used to compare or discriminate between in actual
practice."

**This is a between-subject-variance argument, and it generalizes past this
paper.** Any ICC is inflated by widening the subject population — a point
`koo2016` makes in prose (p. 158, noting that a low ICC may reflect low subject
variability rather than poor agreement — a paraphrase, not a quotation; the
source's own sentence is longer and is quoted in `koo2016.md`) and this paper
makes structurally, with a model and a number.

## AC3: this paper reports **no coverage results**

Stated explicitly as the criterion requires. There is **no simulation study, no
nominal level, and no coverage probability anywhere in the paper**. It is a
methods proposal plus a single case study; all reported intervals are **95 %
symmetric posterior credible intervals (2.5 and 97.5 percentiles)** from MCMC on
one real dataset (p. 5), not repeated-sampling performance. The paper therefore
supplies **no frozen coverage oracle**. What it does supply is a set of
reproducible posterior reference values (below) plus published code.

## Reference values (Tables 2–5, pp. 8–9)

Data (Table 1, p. 5): three randomized studies comparing personal decision aids
to usual care — Study 1 (Chest Pain Choice) 101 PDA / 100 usual = 201; Study 2
(Osteoporosis Choice) 37/35 = 72; Study 3 (FRAX subgroup) 13/25 = 38;
**total 311 encounters**, each scored by the same 2 raters.

**Table 3 (p. 8) — the full heterogeneous model** (posterior median, 2.5 %,
97.5 %):

| Term | Median | 2.5 % | 97.5 % |
|---|---|---|---|
| β[0] | 0.145 | −0.087 | 0.490 |
| β[Rater] | −0.061 | −0.073 | −0.051 |
| β[Decision-aid] | 0.239 | 0.214 | 0.270 |
| (σ/100)²[Study 1] | 0.054 | 0.044 | 0.070 |
| (σ/100)²[Study 2] | 0.117 | 0.084 | 0.168 |
| (σ/100)²[Study 3] | 0.056 | 0.037 | 0.090 |
| τ²[Study 1] | 0.043 | 0.024 | 0.097 |
| τ²[Study 2] | 0.011 | 0.004 | 0.034 |
| τ²[Study 3] | 0.023 | 0.009 | 0.078 |
| ω | 0.029 | 0.003 | 0.717 |
| **ICC[Study 1]** | **0.821** | 0.655 | 0.985 |
| **ICC[Study 2]** | **0.295** | 0.119 | 0.628 |
| **ICC[Study 3]** | **0.644** | 0.359 | 0.919 |

**Table 4 (p. 9) — homogeneous variances across studies, Bernoulli variance
function retained:** ICC **0.609** (0.520, 0.745); pooled ICCb\* **0.681**
(0.568, 0.935).

**Table 5 (p. 9) — constant variance function (heteroscedasticity ignored):**
ICC **0.640** (0.568, 0.702); pooled ICCb\* **0.706** (0.614, 0.930).
`(σ/100)²` collapses to 0.008 (0.007, 0.009) here, against 0.041 in Table 4.

**Table 2 (p. 8) — between-study ICC differences:**

| Paired difference | 2.5 % | Median | Mean | 97.5 % | P(diff > 0) |
|---|---|---|---|---|---|
| Study 1 − Study 2 | 0.166 | 0.472 | 0.473 | 0.764 | 0.995 |
| Study 1 − Study 3 | −0.155 | 0.170 | 0.171 | 0.508 | 0.835 |
| Study 2 − Study 3 | −0.659 | −0.306 | −0.302 | 0.078 | 0.056 |

**The last column is printed `p-value`, which it is not.** Table 2's caption
defines it as "the posterior probability that the difference exceeds 0", and the
body reads it that way — the sentence "probability that study 3 has a higher ICC
than study 2 = 0.944" is on **p. 7** (footer `Page 7 of 11`), one page before the
table it reads, i.e. `1 − 0.056` from the last row. The header above is
therefore the *correct* label, not the printed one — flagged because a posterior
probability tabulated under `p-value` invites exactly the wrong reading, and
because the note must not look like it mis-transcribed the header.

### The headline numbers, read together

The same 311 encounters and the same two raters yield **0.821 / 0.295 / 0.644**
study-by-study, **0.609** if variances are forced equal across studies, and
**0.640** if heteroscedasticity is ignored entirely. The abstract gives **two
distinct pooling penalties**, and the note previously carried only the second:
pooling "without accounting for the variability between studies" inflates
estimates "by approximately 0.02" — call it the **0.02 penalty** — while
"formerly allowing for between study variation in the ICC inflated its estimated
value by approximately 0.066 to 0.072 depending on the model" (the abstract
prints "formerly" where it plainly means *formally*; quoted as printed).
Ignoring heteroscedasticity separately inflates the within-study estimate to
"as high as 0.640".

**Source erratum in the Results text (p. 8).** The sentence deriving those
figures reads "estimates 0.072 or 0.066 greater depending on whether
heteroscedasticity was accounted (Table 3) or ignored (Table 4)" — but both
table numbers are off by one. `0.072` is Table **4**'s `ICCb* − ICC`
(0.681 − 0.609) and `0.066` is Table **5**'s (0.706 − 0.640); Table 3 has no
pooled `ICCb*` row at all, being the per-study model. The accounted/ignored
mapping is right; only the pointers are wrong.

Note what Study 2 does to the story: its ICC is **0.295** — "poor" on
`koo2016`'s bands — while every pooled or homogenized summary lands in
0.609–0.706, i.e. "moderate" to "good". **A model simplification moved a real
instrument across two interpretation bands.** That is a concrete, citable
instance of the argument IP3 exists to protect, and a sharper one than the
vignette's current example because it is a published real-data result rather than
a constructed illustration.

## Connection to the GP6 known-failure axes (T3's explicit requirement)

**A note on "GP6 axes".** GP6 is a *practice* — sweep whatever axis the known
failure mode grows — and names cluster count, incidence and raggedness only as
examples. The repo maintains **no enumerated registry of known-failure axes**
(checked against `DESIGN.md` and `PRINCIPLES.md`, observed 2026-07-19), so
"on the GP6 list" is not a thing a claim can be true or false against. The rows
below map this paper onto the axes M65 chose to track, nothing more.

| GP6 axis | What this paper says |
|---|---|
| **Non-normality** | Addressed indirectly. The paper does not assume a heavy-tailed or skewed outcome; it assumes a *bounded* one and handles it with a truncated normal `I(0,1)` (Eqs. 3, 7) plus a mean-dependent variance. So the failure it targets is **boundedness-induced heteroscedasticity**, which is a distinct axis from the non-normality M62/`ukoumunne2003` covers (heavy tails). The package's Gaussian mixed model makes *both* assumptions, and only the heavy-tail one has been swept anywhere in the repo — observed 2026-07-19 |
| **Near-zero ICC** | Not addressed. The smallest estimate is 0.295 and there is no boundary discussion, no singular-fit analogue, and no simulation near zero. **A Bayesian fit with proper priors does not hit the frequentist boundary at all** — the D-004 "smooth" behavior — so the paper is silent on the package's hardest case by construction |
| **Few subjects** | Touched, not studied. Study 3 has `N₃ = 38` encounters and the paper attributes its wide credible intervals to "the relative small sample sizes in two of the studies and the fact that there are only three studies to inform the between-study variance component, ω" (p. 7). `ω`'s interval (0.003, 0.717) is the visible symptom — **three studies is not enough to estimate a between-study variance**, an incidental-parameters observation matching the M27/M28/M36 lesson |
| **New axis this paper adds** | **Mean-dependent within-subject variance.** Not among the axes GP6 names, and not something the package's engines can express — see Open questions |

## Traces to

- Nothing in the package — see the grep recorded under **Role** above
  (observed 2026-07-19).
- `cairn/references/koo2016.md` — this paper cites Koo & Li (its ref. 14) for
  the ten ICC forms and uses their bands; the Study-2 result above is strong
  independent material for that note's IP3 open question.
- `cairn/references/mcgraw1996.md` — the fixed-rater consistency mapping above is
  Case 3A / `ICC(C,1)`.
- `cairn/references/ukoumunne2003.md` — cited here as ref. 8; the two papers
  cover **different** robustness axes (heavy tails vs bounded-scale
  heteroscedasticity), which is worth keeping straight.
- `cairn/DECISIONS.md` D-004 (boundary-fit policy) — the Bayesian "smooth"
  behavior noted above.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **The variance function is not expressible in the package's engines.**
  Eq. (6) makes the residual variance a function of the *latent* subject score
  `θ_hi`. `glmmTMB` supports dispersion models, but on covariates, not on a
  latent random effect; `lme4` cannot do it at all. The natural home would be the
  brms engine. **No candidate is proposed** — this would be a new estimand
  (an ICC that is a function of `θ*`, Eq. 8) and therefore a contract decision
  (IP2), not an engine feature. Recorded so the option is discoverable.
- **Reproducible, unusually.** Code is on GitHub
  (`CarlyBobak/Bayesian-Framework-for-InterRater-ICC`, cited p. 10) together with
  a **structurally equivalent generated dataset** — the real data needs Mayo
  Clinic permission. This is the only M65 source with public code, so it is the
  only one that could support a **live** oracle rather than a frozen one. Not
  verified at M65: the note records the URL as printed; the repository was **not
  fetched or run**, so its current existence and contents are unconfirmed.
- **Squared-or-not is ambiguous for two parameters, not one.** Table 3 lists the
  term as `ω` while Eqs. (9)–(10) and the prior specification use `ω²` (and
  `ω⁻² ~ Gamma`); whether the tabulated 0.029 is the SD or the variance is not
  stated. **The same ambiguity hits `τ`**: Table 3 tabulates `τ²[Study h]`
  (0.043 / 0.011 / 0.023) but Tables 4 and 5 tabulate a bare `τ` (0.015, 0.014).
  Since Table 4 keeps the same variance function as Table 3 and only pools the
  variances, a `τ²` around 0.015 and a `τ` around 0.015 are very different
  claims. Do not reuse either row across tables without resolving the exponent.
- **No coverage evidence** — see the AC3 section. The method's calibration is
  entirely unvalidated: no simulation, and the case study cannot show whether the
  credible intervals have nominal frequentist coverage. For a package governed by
  "a CI method's oracle is coverage", **this paper's intervals are not oracle
  material**, however sound the modelling argument is.
- **Prior sensitivity is asserted from one perturbation.** p. 4 reports that
  `ν_l = 10⁻²` gave results "numerically almost identical" to `ν_l = 10⁻³`, and
  acknowledges inverse-Gamma variance priors "have been shown to yield
  undesirable results in some applications" (citing Gelman). One perturbation of
  one hyperparameter is thin support, and it runs against the half-*t*
  recommendation this package follows via `tenhove2020` (O-Bayes). Flagged as a
  divergence between this paper's priors and the package's, not as an error.
