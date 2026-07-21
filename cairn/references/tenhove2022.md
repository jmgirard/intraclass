# tenhove2022 — Interrater reliability for multilevel data (the M5 estimand)

**Provenance.** Ingested 2026-07-18 by M64 from `cairn/references/sources/tenhove2022.pdf` (gitignored).
Pagination: advance-online (AOP) PDF pages 1–17 — NOT the journal pages of the version of record, 27(4):650–666.
Extraction: verified 2026-07-18 against the source (M69) — all 17 PDF pages re-read; Tables 4 and 5 confirmed digit-for-digit at 300 DPI, nine prose/anchor claims corrected — observed 2026-07-18.

**Citation.** ten Hove D, Jorgensen TD, van der Ark LA (2022). "Interrater
reliability for multilevel data: A generalizability theory approach."
*Psychological Methods* 27(4):650–666. DOI 10.1037/met0000391.

**Role.** The primary source (IP1) for the package's **multilevel estimand** —
the subject-level and cluster-level IRR ICCs for subjects nested in clusters.
Milestone M5 and everything downstream of it (M8, M10, M17, M19, M36–M38,
M53–M58) trace their estimand here.

> **Two metadata traps on this PDF — read before citing a page.**
> 1. The file is the **advance-online (AOP) version**: its copyright line reads
>    © 2021 and it carries no volume/issue/journal pagination. The paper of
>    record is the 2022 *Psychological Methods* 27(4):650–666 issue version.
>    Cite the 2022 paper; the 2021 line on the PDF is not a different work.
> 2. **All page anchors in this note are AOP PDF pages 1–17**, not journal pages
>    650–666. To convert approximately, add 649. Anchors are given as AOP pages
>    because that is what the shelf copy shows.

## Single-level baseline (pp. 2–4)

Crossed (two-way) design, Eq. 1 (p. 3): `Y_sr = μ + μ_s + μ_r + μ_sr`, where
`μ_sr` is the inseparable Subject × Rater interaction plus random error.
Variance decomposition, Eq. 3 (p. 3): `σ²_Ysr = σ²_s + σ²_r + σ²_sr`.

Nested (one-way) design, Eq. 2 (p. 3): `Y_r:s = μ + μ_s + μ_r:s`; Eq. 4:
`σ²_Yr:s = σ²_s + σ²_r:s`.

The most elaborated single-level coefficient, **Eq. 5 (p. 3)**:

  `ICC(A, k) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/k)`

Table 1 (p. 3) gives the full single-level grid: a two-way panel
(agreement/consistency × average/single) and a one-way panel with the same two
columns, whose consistency cells are `—` because `σ²_r` and `σ²_r:s` cannot be
disentangled in a one-way design (M64 recorded a one-way *agreement column*;
the consistency column is printed, just inestimable — corrected M69). Two
framing points the package's docs lean on:

- **Agreement vs. consistency** (p. 3): `σ²_r` sits in the denominator of the
  agreement coefficients, treating main-rater effects as a nuisance; removing it
  gives consistency, which "is generally higher than ICC(A, k)" (p. 3).
- **Division by k** (p. 4): the rater-related components are divided by *k* for
  the average-rating forms, on the sample-mean rationale; `k = 1` recovers the
  single-rating forms.
- **Raters random by default** (p. 4): the authors "do not consider fixed rater
  effects because most observational studies … use a sample of raters" (p. 4).
  The package's fixed-rater path is therefore *not* sourced here — it reads
  McGraw & Wong Case 3A (see `mcgraw1996.md`).

## The four multilevel designs (Table 2, p. 5)

Table 2 illustrates: **fully crossed**; **Design 1** = raters crossed with
clusters (subjects nested in clusters); **Design 2** = raters nested within
clusters; **Design 3** = raters nested within both subjects and clusters.

> **Erratum in Table 2's own Note (p. 5).** The table note glosses "Design 1 =
> raters *and subjects* nested within clusters" — which is Design 2's
> description, not Design 1's. The body-text heading (p. 4) reads "Design 1:
> Raters Crossed With Clusters", and Table 2's Design-1 columns show all eight
> raters rating subjects in both clusters (raters crossed with clusters,
> subjects nested). Read the body text, not the table note. Found M69 at 300
> DPI; uncorrected in the published paper as far as this repo has checked.

**Design 1 — the package's multilevel design.** Eq. 6 (p. 5):

  `Y_(s:c)r = μ + μ_c + μ_s:c + μ_r + μ_cr + μ_(s:c)r`

**Eq. 7 (p. 5)** — the five-component decomposition:

  `σ²_Y(s:c)r = σ²_c + σ²_s:c + σ²_r + σ²_cr + σ²_(s:c)r`

Design 2 (Eqs. 8–9, p. 5): `μ_cr` is confounded with cluster-level error, giving
`σ²_(sr):c = σ²_c + σ²_s:c + σ²_r:c + σ²_(sr):c`. Design 3 (Eqs. 10–11, p. 5):
`μ_r` also becomes inestimable, giving `σ²_r:s:c = σ²_c + σ²_s:c + σ²_r:s:c`.

## The two estimands (Eqs. 12–13, p. 6) — load-bearing

**Subject-level, Eq. 12 (p. 6):**

  `ICC_s(A, k) = σ²_s:c / (σ²_s:c + (σ²_r + σ²_(s:c)r)/k)`

**Cluster-level, Eq. 13 (p. 6):**

  `ICC_c(A, k) = σ²_c / (σ²_c + (σ²_r + σ²_cr)/k)`

The **facet-omission rule** each coefficient obeys is stated explicitly and is
the reason the package's cluster-level `d_study()` has no subject axis:

- `ICC_s(A, k)` "does not contain any cluster-related variance components (i.e.,
  σ²_c or σ²_cr) because the ordering of subjects *within* clusters is
  independent of cluster-related effects" (p. 6).
- `ICC_c(A, k)` "does not contain any subject-related variance components (i.e.,
  σ²_s:c or σ²_(s:c)r) because the ordering of clusters across raters is
  independent of subject-related effects" (p. 6).

Also load-bearing for scope: **only Design 1 supports a cluster-level ICC** —
"Designs 2 and 3 are not interesting" for cluster-level IRR (p. 6). And for
Design 1 the *k* in Eq. 13 "represents the number of raters per cluster rather
than the total number of unique raters" (p. 6).

**Table 3 (p. 6)** is the full grid — subject-level (top panel) and cluster-level
(bottom panel) ICCs × {agreement, consistency} × {average, single} × {raters
crossed, raters nested in clusters, raters nested in subjects}, with `—` marking
the inestimable cells. This table is the package's coverage map for the
multilevel family.

**Conflated ICC, Eq. 14 (p. 7)** — what a single-level coefficient computes on
clustered data:

  `ICC_conf(A, k) = (σ²_s:c + σ²_c) / (σ²_s:c + σ²_c + (σ²_r + σ²_(s:c)r + σ²_cr)/k)`

The paper's verdict (p. 7): the conflated approach "should therefore be avoided
when working with multilevel data" — it yields biased estimates at each level.

## Estimation (pp. 7–8)

Three routes are named (p. 7): ANOVA mean squares, MLE (hierarchical linear
model), and MCMC. The paper "focus[es] only on MCMC and ignore[s] the ANOVA and
MLE approaches" (p. 7) because MCMC supplies uncertainty measures without
asymptotic normality assumptions — under MLE the delta method "may be
problematic as the normality assumption may be violated, and the Wald-based CIs
need not be range preserving" (p. 4). (M64 rendered the second clause as "not
parameterization-preserving"; the paper's term is *range* preserving — the
limits need not respect the coefficient's [0, 1] range — corrected M69.)

MCMC specifics (p. 8): Stan via `rstan` 2.18.2 (NUTS). The program is
parameterized on random-effect **SDs**, with **weakly informative half-*t*
(df = 4, location = 0, scale = 1)** hyperpriors on them, citing ten Hove et al.
(2020) (see `tenhove2020.md`). Point estimates are **MAP** (via `modeest`), not
EAP: "Because for ICCs, maximum a posteriori (MAP) estimates typically have less
bias than expected a posteriori (EAP) estimates (Ten Hove et al., 2020), we used
the MAP estimates as point estimates" (p. 8; M64's paraphrase dropped the
ICC-specific "Because for ICCs" qualifier — corrected M69). 95% BCIs use
**percentiles** as limits. Convergence:
three chains × 1,000 iterations (half burn-in) → 1,500 retained; R̂ < 1.10;
N_eff > 100.

## Simulation 1 (pp. 8–9)

**DGP (p. 8), Design 1.** Fixed: `σ²_s:c = 1`, `σ²_cr = 0.16`,
`σ²_(s:c)r = 0.50`. Varied at two levels each: `σ²_c` and `σ²_r` ∈ {0.16, 0.50}
("a relatively small value (.16) and a moderate value (.50)", p. 8). Also varied:
`N_c` ∈ {20, 40}, `N_s` ∈ {10, 30}, `k` ∈ {2, 5, 10}. Fully crossed → **48
conditions × 1,000 replications**; total N from 200 to 1,200. Resulting
population ICCs ranged **.50–.95 (subject level)** and **.20–.97 (cluster
level)** (p. 8, Online Supplement S1).

**Findings (pp. 9–11).**
- Convergence 100% in 36 conditions; 33 replications discarded overall, leaving
  **47,967** (p. 9).
- Subject-level ICCs showed negligible bias; **cluster-level ICCs were
  under-estimated**, most severely for agreement coefficients with few raters,
  improving as *k* rose (p. 9; Fig. 1 itself is on p. 10 — corrected M69).
- **Few raters, not few subjects, is the failure axis:** "small numbers of raters
  were the main source of bias and inefficiency" (Abstract, p. 1). The number of
  clusters and of subjects per cluster "affected the efficiency only negligibly"
  (p. 9). Among random-effect SDs, `σ_r` showed the largest under-estimation
  (**up to 30%**, p. 9).
- 95% BCI coverage (p. 9) — three departures, all "significantly (but not
  practically significant)": **low** coverage for subject- *and* cluster-level
  agreement ICCs in most two-rater conditions; **low** coverage for subject-level
  agreement ICCs in a few five-rater conditions; and **high** coverage for
  cluster-level *consistency* ICCs with minimal raters and few clusters. Nearly
  nominal in all other conditions and for all other ICCs. (M64 recorded only the
  two-rater agreement case — the five-rater and the high-coverage consistency
  departures were missing — corrected M69.)

## Simulation 2 — planned missing data (pp. 9–11)

Same DGP with `σ²_c = σ²_r = 0.16`, smallest sample only (`N_c = 20`,
`N_s = 10`); rater **pool** k ∈ {5, 10}, raters **per subject** k_s ∈ {2, 3}, with
each subject's raters randomly drawn from the pool (p. 10). Nonconvergence < 2%;
3,968 converged replications (p. 10).

Result (p. 11): 95% BCI coverage rates of both subject- and cluster-level ICCs
"were nominal in all conditions" — an improvement
over Simulation 1 — and bias/efficiency "improved substantially when as few as
two raters per subject were sampled from a larger pool of raters, rather than
assigning the same two raters to each subject" (p. 11). Residual defect:
cluster-level agreement ICCs stayed substantially under-estimated.

## Illustrative example (pp. 12–15) — candidate reference values

Data: N = 789 upper-elementary students drawing themselves with their teacher;
`N_C = 35` teachers; 8 ≤ N_s ≤ 29 (M = 21.83, SD = 4.19); 8 relationship
dimensions on a 7-point Likert scale; K = 8 raters, Design 1 with planned
missing. The rater allocation is **per teacher**: each drawing was assessed by
three raters, and each teacher's drawings were rated by **five** raters in total
— for each teacher, one rater rated all of that teacher's drawings and four each
rated half (p. 13). (M64 read this as one rater rating *all* drawings in the
study and dropped the five-raters-per-teacher fact — corrected M69.)

The OSF subsample analyzed is **35 × 8 = 280** students on the *emotional
distance* dimension only; ≈15% of total variance was at the teacher level —
which per footnote 3 (p. 13) counts **both** the teacher variance and the
Rater × Cluster variance, so it is not `σ²_c` alone.

For the cluster-level ICCs of average ratings, the unbalanced rater counts were
handled by reporting two values: `k = 3` as a **conservative** and `k = 5` as a
**liberal** estimate (p. 14) — Table 5's caption reads "for k = 3, and k_c = 3 or
k_c = 5". (M64 called both counts "conservative" and recorded only `k_c = 5` —
corrected M69.) OSF: https://osf.io/bwk5t/

**Table 4 (p. 14)** — variance decomposition, MAP [95% BCI]:

| Component | Conflated | MLM |
|---|---|---|
| Student | 1.63 [1.37, 1.95] | 1.38 [1.16, 1.76] |
| Teacher | — | 0.17 [0.07, 0.53] |
| Rater | 0.24 [0.12, 1.20] | 0.24 [0.12, 1.16] |
| Student × Rater | 0.48 [0.42, 0.54] | 0.45 [0.39, 0.51] |
| Teacher × Rater | — | 0.03 [0.01, 0.07] |

**Table 5 (p. 15)** — IRR of average ratings, MAP [95% BCI]:

| Level | ICC(A, k) | ICC(C, k) |
|---|---|---|
| Conflated (k = 3) | .87 [.74, .90] | .91 [.89, .93] |
| Student level (k = 3) | .85 [.72, .89] | .91 [.88, .93] |
| Teacher level (k = 3) | .71 [.24, .86] | .96 [.83, .98] |
| Teacher level (k = 5) | .80 [.35, .91] | .98 [.89, .99] |

Note the very wide cluster-level agreement BCI (.24–.86 at k = 3) — the paper's
own illustration of the few-raters failure axis, and a useful sanity target for
any multilevel interval work.

Interpretation in the paper uses the Koo & Li (2016) benchmarks (p. 14), while
stating a preference for practical-implication interpretation over fixed
benchmarks — the same posture as the package's no-verdict rule (see
`koo2016.md`).

**A second reader's disambiguation of the Koo & Li bands (p. 14).** Worth
recording because `koo2016.md` flags the original bands' inclusivity as
ambiguous: ten Hove et al. restate them with every cut point resolved —
"ICC ≤ .50 is poor, .50 < ICC ≤ .75 is moderate, .75 < ICC ≤ .90 is good, and
ICC > .90 is excellent" (p. 14). This is these authors' reading of Koo & Li, not
Koo & Li's own wording, so it settles nothing about the source; it does show a
downstream reader closing the same gap upper-bound-inclusive, which leaves no
value unbanded. Added M69.

## Traces to

- **The M5 multilevel estimand** — Eqs. 6–7 (decomposition) and 12–13
  (coefficients), Table 3 (the coverage grid). Cited by
  `cairn/estimand-specs/M5-*.md` and the multilevel oracle entries in
  `ORACLES.md` (Design-1 five-component decomposition; the nested Design-2
  entries cite "p. 6", which is the **AOP** pagination this note uses — Eqs.
  12–13, the facet-omission passages, and Table 3 all sit on AOP p. 6).
- The **facet-omission rule** behind the cluster-level `d_study()` having a
  rater-count axis and no subject-count axis.
- The **conflated-ICC** framing (Eq. 14) in `choosing-an-icc.Rmd`'s multilevel
  discussion.
- The half-*t*(4, 0, 1) hyperprior the Bayesian engine uses — sourced here and,
  in more detail, in `tenhove2020.md`.
- `cairn/references/sem-multilevel-pilot.md` (the D-005 two-level-SEM
  parameterization of this same Design-1 decomposition).

## Open questions

- **Page-anchor basis.** As flagged above, this note's anchors are AOP pages
  1–17. Existing repo citations of "ten Hove et al. (2022) p. 6" (e.g.
  `ORACLES.md`) use the same AOP pagination — verified at the M64 review gate by
  confirming Eqs. 12–13 and Table 3 sit on AOP p. 6, and that the journal
  version's pages run 650–666 (so a bare "journal p. 6" cannot exist). Worth a
  one-time sweep at review to
  confirm the repo cites one pagination throughout; not an oracle-value issue.
- **No estimation route the package uses is validated here — with one
  qualification M64 missed (corrected M69).** The *simulations* are MCMC only;
  ANOVA and MLE are explicitly set aside (p. 7). But the *illustrative example*
  additionally fit MLE point estimates for all random-effect SDs and ICCs "using
  the R software package lme4" (p. 14), and the paper reports diverting them to
  Online Supplement S4 "because they resembled the MCMC estimates" (p. 14). That
  is a qualitative agreement statement about one dataset, with no numbers in the
  article body — Online Supplement S4 is not on the shelf (checked, no supplement
  file present — observed 2026-07-18) <!-- check: none — the shelf (cairn/references/sources/) is gitignored, so "Supplement S4 not on the shelf" is a claim about local working state, not reproducibly settleable across clones --> — so it is **not** an oracle and does not
  validate the package's route. The package's default glmmTMB/lme4 REML route to
  Eqs. 12–13 remains an estimation-route choice established by numerical oracle,
  not by this source — the same posture D-005 records for the two-level SEM
  route. No disagreement with `ORACLES.md`; noted so the sourcing boundary stays
  honest. If S4 is ever retrieved it is a candidate lme4-vs-MCMC reference point.
- The paper's `k` for cluster-level ICCs is raters **per cluster** (p. 6); worth
  confirming at review that the package's cluster-level `d_study()` labels this
  axis unambiguously.
