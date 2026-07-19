# mehta2018 — ICC performance under various subject distributions

**Provenance.** Ingested 2026-07-18 by M65 from `cairn/references/sources/mehta2018.pdf` (gitignored).
Pagination: printed journal pages 2734–2752.
Extraction: verified — every value, anchor and quoted string re-read against the
shelf PDF, all 19 pages. The reference list ends at reference 37 part-way down
p. 2750, followed by the "How to cite this article" box, and **Appendices A–C
then run to p. 2752, the final page** — confirmed, not assumed (M65 once
recorded them absent; LESSONS 2026-07-18) — observed 2026-07-19 (M71).

**Citation.** Mehta S, Bastero-Caballero RF, Sun Y, Zhu R, Murphy DK, Hardas B,
Koch G (2018). "Performance of intraclass correlation coefficient (ICC) as a
reliability index under various distributions in scale reliability studies."
*Statistics in Medicine* 37(18):2734–2752. DOI 10.1002/sim.7679. Received 6
September 2017; Revised 23 January 2018; Accepted 20 March 2018. **Open Access**
under CC BY-NC (the copyright line "was changed on 10 September 2018 after
original online publication", p. 2734). Allergan plc (Irvine CA); University of
Maryland Baltimore County; University of North Carolina at Chapel Hill. Funded
by Allergan Inc.

**Role.** Ingested by M65 as half of the distributional-robustness pair.
**Squarely inside the package's contract** — it studies the two-way random
`ICC(2,1)` the package computes, with the classical Shrout–Fleiss estimator.
Nothing in the package traced to it and no `ORACLES.md` entry cited it —
observed 2026-07-19 (grep for `mehta` over `R/`, `tests/`, `man/`, `vignettes/`,
`data-raw/`, `NAMESPACE`, `DESCRIPTION` and `ORACLES.md`: no hits).

## Design applicability (AC2)

| Axis | What the paper covers |
|---|---|
| Design | **Two-way, crossed, balanced** — `k` raters each judging every one of `n` subjects (§2, p. 2736) |
| Raters | **Random** — "the expected reliability of a single rater's grade is of interest, and the results from the study usually need to be generalized to a larger population of raters" (p. 2736) |
| Interaction | **Present.** Eq. (1) is `X_ij = μ + a_i + b_j + (ab)_ij + ε_ij` — a genuine interaction term, unlike `xiao2013`'s additive model |
| Coefficient | **Single-rating absolute agreement**, `ρ = σ²_a/(σ²_a + σ²_b + σ²_ab + σ²_ε)` (Eq. 2). Eq. (3) is **exactly Shrout–Fleiss `ICC(2,1)`** |
| Outcome scale | **Ordinal, 5-point** (grades 0–4) — Likert-type photonumeric aesthetic scales. Note the paper's own caveat that normality "is not necessary for the valid estimation of `ICC`" (p. 2737) |
| Balance | Balanced; `σ²_ab` and `σ²_ε` are not separately identified (`σ̂²_ab + σ̂²_ε = EMS`, p. 2737) |
| What varies | The **distribution of subjects across grades** — the paper's whole subject |

**This is the estimand the package computes.** Eq. (3), p. 2737:

```
ρ̂ = (BMS − EMS) / [BMS + (k−1)EMS + (k/n)(JMS − EMS)]
```

with `BMS` (Eq. 4), `JMS` (Eq. 5), and `EMS` (Eq. 6) the between-subjects,
between-raters, and residual mean squares. That is the textbook `ICC(2,1)` /
`ICC(A,1)` formula — the same coefficient the package estimates by mixed-model
variance components rather than mean squares. **The paper's findings therefore
apply to package output directly**, which is not true of any other M65 source
except `bobak2018`.

## The central finding: ICC is a property of the sample, not just the instrument

Five subject distributions over the five grades are compared (Figure 1,
p. 2736): **convex** (mass in the middle grades), **concave** (mass in the
extremes), **uniform**, and left/right **skewed**. Table 2 (p. 2739) gives the
exact percentages, e.g. extreme concave = 33.0 / 16.7 / 4.0 / 14.0 / 32.3 %
across grades 0–4; extreme convex = 2.3 / 28.7 / 42.7 / 22.7 / 3.6 %.

**The ordering, stated in the abstract and confirmed in Table 4: `ICC` from the
convex distribution < uniform < concave.** At identical rater quality. The
mechanism (§3.2, which runs pp. 2740–2743) is decomposed and this is the part
that transfers:

- **Subject variance `σ̂²_a` drives the whole effect** (Table 5, p. 2742): it is
  highest under concave distributions (2.43 at Case 1, extreme concave,
  `N = 300`) and lowest under convex (0.70), with uniform in between (1.70).
- **Rater error variance is essentially unchanged across distributions**
  (Table 6, p. 2743): 0.18 / 0.19 / 0.20 at Case 1 for extreme-concave /
  uniform / extreme-convex. The scale is equally good in all three.
- Hence, verbatim from the abstract: "the dissimilarity of `ICC` among
  distributions is attributed to the study design (ie, distribution of subjects)
  component of subject variability and **not the scale quality component of rater
  error variability**."

The interpretation consequence is stated bluntly (p. 2741): under Case 2, the
same instrument reads as "almost perfect" agreement under the extreme concave
distribution, "substantial" under uniform, and "moderate" under extreme convex.
And p. 2743: convex distributions "tend to understate reliability … with
`ICC` = 0.30 to 0.39, while based on the concave distributions the scale has
substantial reliability with `ICC` = 0.68 to 0.70."

**This is the strongest published statement in the M65 cluster of the point IP3
protects** — that a qualitative reliability label is not a property of the
instrument alone. It converges from a completely different direction with
`bobak2018`'s pooling inequality (its Eq. 11) and with `koo2016`'s prose remark
(p. 158) that a low ICC may reflect low subject variability.

## AC3: no coverage or interval-width results

Stated explicitly as the criterion requires. **There is no confidence interval,
no nominal level, and no coverage probability anywhere in this paper.** It is a
point-estimate behaviour study. What it reports instead is the **mean `ICC` and
its interdecile range across 10 000 simulations** — a sampling-variability
measure, *not* an interval width, and it must not be compared against a CI width
from `xiao2013` or `saha2012`.

Tables 4–7 are nonetheless well-specified enough to serve as **frozen
point-estimate oracles** (a deterministic recomputation target for a `ICC(2,1)`
implementation under a stated data-generating process), which is a different and
weaker use than a coverage oracle. See Open questions for why even that is not
straightforward.

## Simulation design (§3.1, pp. 2738–2740)

**10 000 simulations** per cell; `k = 8` raters; 5-point ordinal scale (0–4);
`N ∈ {300, 80}` subjects (`N = 70` also run, same behaviour). Data are generated
from a **master grade** (the subject's true grade) plus a prescribed pattern of
rater disagreement — **the number of subjects per grade is fixed, so "there is no
random component involved when defining the population structure of the
subjects"** (p. 2739).

Disagreement is defined by **six cases** (Table 3, p. 2740), from mild (Case 1:
20 % of subjects get a 1-point disagreement from all 8 raters) to severe
(Case 6: 30 % 1-point, 10 % 2-point, 10 % 3-point and 10 % 4-point differences
for half the raters, and a second, heavier pattern for the rest). Movement
direction is random and symmetric, except at the boundary grades 0 and 4 where a
1-point difference can only move inward (p. 2739) — **an explicit floor/ceiling
mechanism**, and the stated reason concave distributions gain: measurement error
at the extremes "implies movement only in 1 direction (ie, towards the middle)"
(p. 2741).

Because disagreements are symmetric and random, `σ²_b` is "expected to be almost
null" (p. 2739) and `σ̂²_b` is confirmed near zero (p. 2742) — so the simulated
rater main effect is negligible even though the estimator is the two-way one.

### Table 4 (p. 2741) — the headline reference table

"Mean `ICC` (and interdecile range) across 10 000 simulations":

| Distribution | N | Case 1 | Case 2 | Case 3 | Case 4 | Case 5 | Case 6 |
|---|---|---|---|---|---|---|---|
| Extreme concave | 300 | 0.93 (0.01) | 0.85 (0.02) | 0.77 (0.02) | 0.69 (0.02) | 0.39 (0.05) | 0.19 (0.04) |
| Extreme concave | 80 | 0.93 (0.01) | 0.85 (0.03) | 0.78 (0.04) | 0.70 (0.05) | 0.40 (0.10) | 0.20 (0.09) |
| Mild concave | 300 | 0.93 (0.01) | 0.84 (0.02) | 0.76 (0.02) | 0.68 (0.03) | 0.38 (0.05) | 0.19 (0.04) |
| **Uniform** | **300** | **0.90 (0.01)** | **0.79 (0.02)** | **0.68 (0.03)** | **0.58 (0.03)** | **0.34 (0.05)** | **0.16 (0.04)** |
| **Uniform** | **80** | **0.90 (0.02)** | **0.79 (0.04)** | **0.68 (0.06)** | **0.58 (0.06)** | **0.35 (0.10)** | **0.17 (0.09)** |
| Mild convex | 300 | 0.82 (0.02) | 0.65 (0.03) | 0.51 (0.04) | 0.39 (0.04) | 0.26 (0.06) | 0.11 (0.04) |
| Extreme convex | 300 | 0.78 (0.02) | 0.58 (0.04) | 0.43 (0.04) | 0.30 (0.04) | 0.22 (0.06) | 0.08 (0.04) |
| Extreme convex | 80 | 0.78 (0.04) | 0.58 (0.07) | 0.43 (0.08) | 0.31 (0.08) | 0.23 (0.11) | 0.09 (0.08) |

Companion tables: **Table 5** (p. 2742) mean subject variance `σ̂²_a`; **Table 6**
(p. 2743) mean rater error variance `σ̂²_b + σ̂²_ab + σ̂²_ε`. Together the three
give the full variance decomposition per cell.

### Sample size: `N = 80` is as good as `N = 300` for the point estimate

Table 4's `N = 300` and `N = 80` rows agree to **0.00–0.01 in every one of the 30
cells** (5 distributions × 6 cases; checked pair by pair at M71, p. 2740). The
abstract's conclusion: "any increase in the number of subjects beyond a
moderately large specification such as `n = 80` does not have a major impact on
`ICC`."

**But read the interdecile ranges, not the means.** At `N = 80` the spread
**roughly doubles** — about 1–2.5× across the 30 cells, most often almost exactly
2× (Case 5, uniform: 0.10 vs 0.05; Case 4, extreme convex: 0.08 vs 0.04; the
narrowest ratios are extreme concave Cases 1–2, 0.01 vs 0.01 and 0.03 vs 0.02). And the spread grows sharply with
disagreement: uniform `N = 80` goes from 0.02 at Case 1 to 0.10 at Case 5. The
paper says this ("as the number of subjects decreases, more variability in the
estimates is realized particularly for higher levels of disagreement", p. 2740),
but its abstract-level claim is about the *mean* only. **Unbiasedness of the
point estimate at `N = 80` says nothing about interval width** — which is the
quantity this package actually reports.

## The proposed sampling method (§4, pp. 2743–2746)

Since a uniform subject distribution is often infeasible, the paper proposes
**subsampling toward uniformity**. Procedure (Figure 2, p. 2744): (1) all `N`
subjects rated by `k` raters; (2) categorize each subject into a unique grade by
the rounded **mean, median, or mode** of its `k` ratings; (3) select `m` subjects
per grade where `m` is the minimum across-grade frequency, with a documented
top-up rule when some grade is too thin; (4) repeat `l` times; (5) **combine the
`l` `ICC` estimates by bootstrap techniques**.

Results (**Table 7**, p. 2745): sampling moves `ICC` toward the
uniform-distribution value from both sides — up for convex, down for concave.

**That direction claim holds unconditionally only for the mode.** At severe
disagreement the mean and median *reverse* for concave populations: extreme
concave Case 4 goes 0.69 (full) → 0.72 (mean), and Case 5 goes 0.39 → 0.56,
both moving **away** from uniform's 0.58 and 0.34. The paper says so itself —
"as the levels of disagreement increase, sampling based on mean and median can
produce higher `ICC` values when compared with those from the population"
(p. 2745). Mode-sampled values track uniform at every case (Case 5: 0.35 against
uniform's 0.34; Case 6: 0.18 against 0.16).

**The mode is therefore the best categorizer**, and the paper establishes this in
two separate places rather than one: for concave populations "the mode provides
the smallest absolute difference from the uniform distribution across all 6
levels of disagreement" (p. 2745), and for convex ones "the `ICC` does not exceed
that of the standard uniform paradigm across all cases when median and mode are
used. The mean, on the other hand, tends to produce higher `ICC` for severe
levels of disagreement" (p. 2746). §6 states the combined conclusion: "as the
levels of disagreement increase in concave and convex distributions, the sampling
method via the mode is a better measure to categorize" (p. 2748).

The safeguard claim is that rater error variance is essentially unchanged by
sampling, so the procedure "does not make an unreliable scale look reliable"
(p. 2746).

### Appendices A–C (pp. 2750–2752) — the variance decomposition under sampling

The reference list ends part-way down p. 2750 and the appendices follow it in the
same PDF. **Appendix A** (p. 2750) gives mean `σ̂²_a` (subject variance) and
**Appendix B** (p. 2751) mean `σ̂²_b + σ̂²_ab + σ̂²_ε` (rater error variance), both
with interdecile ranges, for the full distribution *and* each of the three
sampling methods. They are what substantiates the §4 safeguard claim. Selected
`σ̂²_a` rows from Appendix A, Case 1 / Case 6:

| Initial distribution | Spec | Case 1 | Case 6 |
|---|---|---|---|
| Extreme concave | full, `N = 300` | 2.43 (0.06) | 0.39 (0.09) |
| Extreme concave | sampling, Mode | 1.85 (0.07) | 0.33 (0.09) |
| **Uniform** | full, `N = 300` | **1.70 (0.05)** | **0.27 (0.08)** |
| Extreme convex | full, `N = 300` | 0.70 (0.04) | 0.11 (0.05) |
| Extreme convex | sampling, Mode | 1.24 (0.10) | 0.22 (0.14) |

Sampling pulls `σ̂²_a` toward the uniform value from both sides — down from 2.43
to 1.85 (concave) and up from 0.70 to 1.24 (convex), against uniform's 1.70 —
which is the mechanism behind the Table 7 `ICC` convergence.

**The safeguard claim checks out at Case 1, but *unchanged* is the wrong word at
severe disagreement.** At Case 1 the Appendix B rater-error rows barely move
(extreme concave 0.18 full vs 0.19 sampled; extreme convex 0.20 vs 0.19–0.20,
against uniform's 0.19). At Cases 5–6 they move materially: extreme concave
Case 5 goes 1.44 (full) → 1.13 (mean) / 1.26 (mode), and extreme convex Case 6
goes 1.19 → 1.39 (mode), against uniform's 1.20 and 1.46. The paper flags the
mean exception ("except for the mean with higher levels of disagreement",
p. 2746) but not the mode's.

So the accurate statement of the safeguard is **directional, not static**: rater
error moves *toward the uniform-distribution value* rather than staying put, and
in the convex case that means it moves **up** — which is the direction that
argues against artificial inflation, since a higher rater-error estimate lowers
`ICC`. The claim survives; its usual shorthand — *rater error variance is
unchanged* — does not.

**Appendix C** (p. 2752, Figure C1) plots `ICC` across the six cases for the full
extreme-concave and extreme-convex populations against their `n = 80` samples and
the uniform reference.

## Application (§5, pp. 2746–2748)

The motivating study (Table 1, p. 2735): five photonumeric severity scales
(fine lines, forehead lines, hand volume deficit, skin roughness, temple
hollowing), `N = 313` enrolled, all with **convex-shaped** subject distributions;
published `ICC` from **0.61 to 0.82**.

**Table 9** (p. 2747) — all subjects vs the sampling method (`n` = 80–115,
mean-based categorization, `l = 20` repetitions, combined with SAS 9.3 PROC
MIANALYZE):

| Scale | ICC (all) | Subj var | Rater err | **ICC (sample)** | Subj var | Rater err |
|---|---|---|---|---|---|---|
| Fine lines | 0.61 | 1.09 | 0.39 | **0.76 (0.02)** | 1.72 (0.10) | 0.53 (0.06) |
| Forehead lines | 0.82 | 1.14 | 0.21 | **0.86 (0.03)** | 1.47 (0.13) | 0.24 (0.05) |
| Hand volume deficit | 0.73 | 0.65 | 0.23 | **0.82 (0.02)** | 1.14 (0.09) | 0.25 (0.03) |
| Skin roughness | 0.68 | 0.77 | 0.29 | **0.81 (0.02)** | 1.57 (0.09) | 0.36 (0.03) |
| Temple hollowing | 0.68 | 0.68 | 0.29 | **0.81 (0.03)** | 1.41 (0.10) | 0.32 (0.05) |

Every scale's `ICC` rises, by up to 0.15 (fine lines, 0.61 → 0.76), and four of
five cross a `koo2016` band boundary (moderate → good; forehead lines starts and
ends in *good*).

**Mind whose bands.** The paper judges against Landis & Koch (its reference 30),
not `koo2016`, and under *those* thresholds only **three** of five change
classification — the paper states that fine lines and forehead lines show "no
change in qualitative classification" while hand volume deficit, skin roughness
and temple hollowing gain one (p. 2747). Both counts are correct for their own
band system; cite the count with the system attached, or the note will look like
it contradicts the paper.

## Connection to the GP6 known-failure axes (T3's explicit requirement)

| GP6 axis | What this paper says |
|---|---|
| **Non-normality** | **Directly and centrally.** But of the *subject* distribution, not the error distribution — the axis is the shape of the true-score distribution across the scale (convex/concave/uniform/skewed), which is distinct from the heavy-tailed *error* non-normality `ukoumunne2003` studies and from `bobak2018`'s bounded-scale heteroscedasticity. **Three M65/M62 sources, three different things all called "non-normality".** Worth keeping straight |
| **Few subjects** | Addressed and partly reassuring: the point estimate is stable down to `N = 80` and, per §5, `N = 50`. But interval-relevant spread is not — see the caveat above |
| **Near-zero ICC** | Reached, at last. Case 6 produces `ICC` = 0.08 (extreme convex, `N = 300`), the **lowest true value anywhere in the M65 cluster**. The paper reports no estimation difficulty there — unsurprising, since it uses closed-form mean squares that cannot fail to converge, unlike the package's mixed-model fits |
| **Ordinal / discrete outcomes** | An axis the package does not currently list. Every value here is an integer grade 0–4 treated as continuous — common practice, endorsed by the paper, and not something the package warns about |

## Traces to

- Nothing in the package — see the grep recorded under **Role** above
  (observed 2026-07-19).
- `cairn/references/shrout1979.md` — Eq. (3) here is `ICC(2,1)`; Shrout & Fleiss
  is this paper's reference 1.
- `cairn/references/fleiss1973.md` — cited here as reference 29 (the
  weighted-kappa/ICC equivalence), the same result M64 recorded.
- `cairn/references/koo2016.md` — the band-crossing observations above are direct
  material for that note's IP3 open question; Landis & Koch (ref. 30) supplies
  the threshold the paper judges against.
- `cairn/references/bobak2018.md` — the sibling robustness source. **They agree
  on the mechanism from opposite directions**: widening the subject distribution
  inflates `ICC` (bobak2018 Eq. 11, pooling), narrowing it deflates `ICC`
  (mehta2018 Table 4, convex). Read the two together.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **Would this reproduce against the package?** In principle yes — the estimator
  is `ICC(2,1)`, the DGP is fully specified (Tables 2 and 3), and the package
  computes the same coefficient. In practice the package uses **mixed-model
  variance components, not ANOVA mean squares**, and at Case 6 the true `ICC` is
  0.08, where REML/ML and the method of moments diverge (moments can go negative;
  REML cannot). So a reproduction would be a *comparison of estimators*, not a
  pure oracle check, and disagreement would not be evidence of a package defect.
  **No candidate proposed**; recorded because Table 4 looks more directly usable
  than it is.
- **The disagreement cases are not a parameterized DGP.** Table 3 describes six
  disagreement patterns in prose ("20 % subjects with 1-point disagreement for
  75 % of the raters (`k = 6`)"), with the boundary-reflection rule stated
  separately in the text (p. 2739). Reimplementing them exactly is possible but
  fiddly, and any mismatch would silently change the target. If Table 4 is ever
  used as a frozen oracle, the DGP transcription is the risk, not the arithmetic.
  Two further rules a reimplementation must not miss, both stated only in running
  text: master grades 1, 2 and 3 have **zero** chance of a 4-point difference
  (p. 2739), and when a subject's mode is non-unique **the maximum** of the tied
  modes is taken as `G_mode` (p. 2744) — the latter matters because the mode is
  the categorizer the paper ends up recommending.
- **Skewed distributions are described but never tabulated.** Figure 1 defines
  left- and right-skewed cases and §3.1 says they were simulated, but "results
  for the skewed distributions are not shown" (p. 2739); conclusions about them
  appear in prose only (pp. 2742, 2748). Do not cite numbers for skewed cases —
  there are none.
- **Appendix C's error bars are the only dispersion measure given for the
  sampling comparison** (p. 2752): Figure C1's note says they "represent the
  standard deviation OF THE 10 000 `ICC` estimates", where every table in the
  paper reports an *interdecile range* instead. The two are not interchangeable
  and the figure is the only place an SD appears. Minor, recorded so the two
  spread measures are not conflated. (The mid-sentence capitals are **printed
  that way** — confirmed against a 250-DPI render at M71, not a transcription
  slip; the appendix headings are set in caps and the run bled into the note.)
- **Sponsor interest.** The work is funded by Allergan plc, six of seven authors
  are Allergan-affiliated, and the application is to Allergan's own aesthetic
  scales — where the proposed method **raises** every reported reliability
  estimate (Table 9). The paper's safeguard argument (rater error variance is
  unchanged) is sound as far as it goes and is exactly the right check. Recorded
  as context for weighting the recommendation, not as an allegation: the
  simulation results stand on their own and are separable from the
  recommendation.
- **The sampling method discards data.** Subsampling 80 of 313 subjects to
  achieve uniformity throws away three-quarters of the sample to change a
  descriptive property of the design. The paper does not discuss the efficiency
  cost, and the `l = 20`-repetition bootstrap recombination (Figure 2, step 5) is
  described only as "bootstrap sampling techniques" with no stated estimator for
  the combined variance. Recorded as an under-specified step — **partially
  resolved for the application**, where §5 names SAS 9.3's `PROC MIANALYZE`
  (a multiple-imputation combining procedure, i.e. Rubin's rules) as what
  actually combined the 20 samples (p. 2747). The *simulation* chapters still
  say only "bootstrap".
