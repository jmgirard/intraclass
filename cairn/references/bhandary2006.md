# bhandary2006 — Small-sample `F_max` test for equality of ICCs, unequal family sizes

**Provenance.** Ingested 2026-07-18 by M65 from `cairn/references/sources/bhandary2006.pdf` (gitignored).
Pagination: printed journal pages 765–778.
Extraction: verified — every value, anchor and quoted string re-read against the
shelf PDF, all 14 pages; the reference list ends the document on p. 778 (last
entry Young & Bhandary 1998) with nothing after it. All 54 transcribed Table 2
values and all 30 transcribed Table 1 values reproduce exactly, as do the worked
example's estimates, both statistics, and all six critical values — observed
2026-07-19 (M71).

**Citation.** Bhandary M, Fujiwara K (2006). "A Small Sample Test for the
Equality of Intraclass Correlation Coefficients Under Unequal Family Sizes for
Several Populations." *Communications in Statistics — Simulation and
Computation* 35(3):765–778. DOI 10.1080/03610910600716894. Received 9 September
2004; Accepted 6 January 2006. Department of Statistics, North Dakota State
University. Published under the journal's "Multivariate Analysis" section
header.

**Author link.** Madhusudan Bhandary is the third author of `xiao2009`, which
cites this line of work (Young & Bhandary 1998; Bhandary & Alam 2000) for the
equality-testing problem. Same research program, three years earlier.

**Role.** Ingested by M65 as the second half of the "estimator-bias pair". **It
is not an estimator-bias paper** — see below. Nothing in the package traced to
it and no `ORACLES.md` entry cited it — observed 2026-07-19 (grep for
`bhandary` over `R/`, `tests/`, `man/`, `vignettes/`, `data-raw/` and
`ORACLES.md`: no hits).

## Design applicability (AC2)

| Axis | What the paper covers |
|---|---|
| **Inferential target** | **A hypothesis test, not an estimator or an interval.** `H₀: ρ₁ = ρ₂ = ρ₃` vs `H₁: NOT H₀` across three populations (§2) |
| Domain | **Familial correlation** — "intrafamily resemblance with respect to characteristics such as blood pressure, cholesterol, weight, height, stature, lung capacity" (p. 765) |
| Distribution | **Gaussian.** `x_i ~ N_{p_i}(μ1, Σ_i)` with compound-symmetric `Σ_i = σ²[1 on diagonal, ρ off]` (Eq. 2.1, p. 767) — unlike the Saha pair, this *is* a normal-theory ICC |
| Structure | **One-way / exchangeable.** Each family is one cluster; no rater facet, no crossed design |
| Balance | **Unequal family sizes**, treated by conditional analysis "assuming family sizes fixed though unequal" (p. 766) |
| Populations | **Exactly three** in the development (Eqs. 2.4–2.6) and in every simulation, despite the title's "Several Populations" |
| `ρ` range | `max_{1≤i≤k}(−1/(p_i − 1)) ≤ ρ ≤ 1` (Eq. 2.1) — **negative `ρ` admitted**, as in the Saha papers |

**Cluster reassignment (a finding, recorded not acted on).** The M65 plan groups
this paper with `saha2005` as "the estimator-bias pair", and Scope describes it
as "small-sample ICC inference". That is true only in the loose sense that it
concerns small samples: the paper estimates nothing new (it borrows Srivastava's
1984 estimator wholesale) and corrects no bias. **Its actual subject is
equality-of-ICCs testing — the M67 cluster** (`donner2002`, `konishi1989`,
`naik2007`, `young1998`), whose ROADMAP row already places that topic outside
the contract boundary (IP2). Read this note alongside M67's when that milestone
runs; the same fence applies.

## The setup

`x_i = (x_{i1}, …, x_{ip_i})′` is the `p_i × 1` observation vector from family
`i`, `i = 1, …, k`, with the structure of Eq. (2.1), p. 767, credited to Rao
(1973). A **Helmert orthogonal transformation** `u_i = Q x_i` (Eq. 2.2) sends
each family to independent coordinates: `u_i ~ N_{p_i}(μ*_i, Σ*_i)` with
`μ*_i = (μ, 0, …, 0)′` and `Σ*_i = σ²·diag(η_i, 1−ρ, …, 1−ρ)`, where
`η_i = p_i⁻¹{1 + (p_i − 1)ρ}` (Eq. 2.7, p. 769). "The transformation used on the
data from `x` to `u` … is independent of `ρ`" (p. 767) — which is what makes the
exact test below possible.

**Srivastava's (1984) estimator, Eq. (2.3), p. 767** — used throughout as a
"good substitute for the maximum likelihood estimator" under unequal family
sizes:

```
ρ̂ = 1 − γ̂²/σ̂²
σ̂² = (k−1)⁻¹ Σᵢ (u_{i1} − μ̂)² + k⁻¹ γ̂² (Σᵢ aᵢ)
γ̂² = Σᵢ Σ_{r=2}^{p_i} u²_{ir} / Σᵢ (p_i − 1)
μ̂  = k⁻¹ Σᵢ u_{i1}
aᵢ  = 1 − p_i⁻¹
```

Note the shape: `γ̂²` is the pooled within-family variance built from the
**non-first** Helmert coordinates, and `ρ̂` is one minus its ratio to a total.
This is a moment-style estimator on transformed data, not an ML or REML fit.

## The two competing tests

**LRT (§2.1, Eq. 2.8, pp. 769–770)** — the likelihood-ratio statistic of
Bhandary & Alam (2000), a nine-line expression in the three per-population
estimates `ρ̂₁, ρ̂₂, ρ̂₃`, the pooled `ρ̂`, `σ̂²`, and the three means. Assumes
`σ²₁ = σ²₂ = σ²₃ = σ²` (stated as a Note on p. 769). `−2 log Λ` is
**asymptotically `χ²` with 2 df**, and the paper flags the cost up front: it is
"computationally complex and also used asymptotically, that is, when family
sizes are large (at least 30)" (p. 770).

**`F_max` (§2.2, Eqs. 2.9–2.18, p. 771)** — the contribution. Define three
variance ratios from the pooled within-family Helmert sums of squares:

```
F₁ = [ΣΣ u²_{ir} / Σ(p_i−1)] / [ΣΣ v²_{js} / Σ(q_j−1)]      (2.10)
F₂ = [ΣΣ u²_{ir} / Σ(p_i−1)] / [ΣΣ w²_{lt} / Σ(r_l−1)]      (2.11)
F₃ = [ΣΣ v²_{js} / Σ(q_j−1)] / [ΣΣ w²_{lt} / Σ(r_l−1)]      (2.12)
F₄ = 1/F₁,  F₅ = 1/F₂,  F₆ = 1/F₃                            (2.13)
F_max = max{F₁, …, F₆}                                       (2.9)
```

The exactness argument (Eq. 2.14): each pooled sum of squares is exactly
`σ²(1−ρ)χ²` on `pp = Σ(p_i−1)`, `qq = Σ(q_j−1)`, `rr = Σ(r_l−1)` df, so **under
`H₀` each `F_i` has an exact `F` distribution** (Eqs. 2.15–2.16) — no asymptotics
anywhere. The price is multiplicity, handled by a **Bonferroni bound over the
six statistics** (Eq. 2.17):

```
C = max{ F_{α/6; pp,qq}, F_{α/6; ppk,rr}, F_{α/6; qq,rr},
         F_{α/6; qq,pp}, F_{α/6; rr,pp}, F_{α/6; rr,qq} }
```

**Transcribed as printed — the second term's `ppk` is a source typo.** Eq. (2.17)
really does print `F_{α/6; ppk,rr}` (confirmed against a 400-DPI render, not the
text layer), where the degrees of freedom must be `pp, rr`: Eq. (2.16) gives
`F₂`'s exact null distribution as `F_{pp,rr}`, and `k` is not a df quantity
anywhere in the paper — `pp`, `qq`, `rr` are. Read it as `F_{α/6; pp,rr}`.
Recorded rather than silently repaired, so the note stays checkable against the
page.

Rejecting when `F_max > C` (Eq. 2.18). The authors note (p. 774) that a sharper
Bonferroni bound exists but is unusable here because the six `F_i` are all
correlated and their joint distribution is intractable — **so the test is
conservative by construction**, which Table 2 confirms.

## Reference tables (AC3)

Simulation design (§3, p. 774): multivariate normal vectors generated **in R**;
`K ∈ {5, 15, 30}` family vectors per population, three populations; family sizes
from a negative binomial with **mean 2.86**, truncated to a minimum of 2 and a
maximum of 15 siblings (`theta = 41.2552`, matching the success probability
0.483 determined by the previous family-size-simulation research the paper
cites — **Rosner et al. 1977 and Srivastava & Keen 1988**, p. 774);
`ρ₁, ρ₂, ρ₃` over 0.1–0.9 in steps of 0.1; **10,000 replications** per
combination; `α = 0.05`. (A reproducibility oddity worth knowing: the vectors
are generated "using R program", but the negative-binomial parameters are quoted
as the setting for a "FORTRAN IMSL negative binomial subroutine" — the paper
mixes the two toolchains in one paragraph and never says which produced the
family sizes.)

**Table 2 (p. 774), "Checking the alpha level"** — the size table, transcribed
in full. This is the paper's headline result and the most reusable thing in it:

| ρ₁=ρ₂=ρ₃ | K=5 LRT | K=5 F | K=15 LRT | K=15 F | K=30 LRT | K=30 F |
|---|---|---|---|---|---|---|
| 0.1 | **0.4089** | 0.0340 | 0.1113 | 0.0319 | 0.0493 | 0.0384 |
| 0.2 | 0.2011 | 0.0181 | 0.0633 | 0.0343 | 0.0371 | 0.0320 |
| 0.3 | 0.1350 | 0.0294 | 0.0411 | 0.0375 | 0.0397 | 0.0317 |
| 0.4 | 0.0943 | 0.0165 | 0.0331 | 0.0362 | 0.0351 | 0.0414 |
| 0.5 | 0.0874 | 0.0220 | 0.0301 | 0.0365 | 0.0301 | 0.0388 |
| 0.6 | 0.0540 | 0.0214 | 0.0281 | 0.0255 | 0.0261 | 0.0375 |
| 0.7 | 0.0368 | 0.0245 | 0.0226 | 0.0326 | 0.0203 | 0.0364 |
| 0.8 | 0.0285 | 0.0224 | 0.0215 | 0.0316 | 0.0182 | 0.0355 |
| 0.9 | 0.0150 | 0.0248 | 0.0166 | 0.0284 | 0.0155 | 0.0394 |

**The asymptotic LRT's size is catastrophically wrong in small samples at low
`ρ`: 0.4089 against a nominal 0.05 — an eightfold inflation — at `K = 5`,
`ρ = 0.1`.** It decays monotonically as `ρ` rises and as `K` grows, reaching
0.0493 only at `K = 30, ρ = 0.1`. `F_max`'s size stays in 0.0165–0.0414 in every
one of the 27 cells: conservative, never inflated, and — unlike the LRT — **with
no systematic drift along either `ρ` or `K`**.

**Note the failure direction, which is the transferable part.** The asymptotic
test degrades exactly where this package's own known-failure axes lie (GP6):
**few clusters and low ICC, jointly**. And it degrades *anti-conservatively* —
too many rejections, i.e. intervals that would be too narrow — which is the same
direction as `xiao2013`'s naive-PL under-coverage. Two independent normal-theory
ICC papers in this milestone, on different estimands, both find `χ²`-calibrated
asymptotics too liberal at small samples.

**Table 1 (pp. 772–773), "Rejection proportions for alpha = 0.05"** — the power
table: **75 rows**, each carrying all six `K × test` columns. A slice:

| ρ₁ | ρ₂ | ρ₃ | K=5 LRT | K=5 F | K=15 LRT | K=15 F | K=30 LRT | K=30 F |
|---|---|---|---|---|---|---|---|---|
| 0.7 | 0.5 | 0.1 | 0.3871 | 0.1403 | 0.8569 | 0.8548 | 0.9916 | 0.9936 |
| 0.7 | 0.9 | 0.1 | 0.8626 | 0.8455 | 0.9971 | 1.0000 | 0.9998 | 1.0000 |
| 0.8 | 0.5 | 0.1 | 0.7190 | 0.6222 | 0.9818 | 0.9927 | 0.9984 | 0.9998 |
| 0.9 | 0.5 | 0.1 | 0.7530 | 0.5657 | 0.9984 | 1.0000 | 0.9994 | 1.0000 |
| 0.9 | 0.9 | 0.9 | 0.0150 | 0.0248 | 0.0166 | 0.0284 | 0.0155 | 0.0394 |

**Table 1 prints a deliberately selected high-`ρ` subset, not the design grid.**
§3 says the `ρ` values "took combinations over the range of values from 0.1 to
0.9 at increments of 0.1" — 729 combinations — but reports rejection proportions
"for a sample combinations of `ρ₁, ρ₂`, and `ρ₃`". The 75 printed rows run
`ρ₁ ∈ {0.7, 0.8, 0.9}` × `ρ₂ ∈ {0.5, 0.6, 0.7, 0.8, 0.9}` ×
`ρ₃ ∈ {0.1, 0.3, 0.5, 0.7, 0.9}`: `ρ₁` never goes below 0.7 and `ρ₂` never below
0.5. Table 2 (the size table) is the one that sweeps 0.1–0.9 evenly, and only on
the null diagonal.

The `K = 5` power comparison is **not interpretable as a like-for-like
comparison**, because the LRT is running at a true size of up to 0.41 there —
its apparent power advantage is bought with false positives. At `K = 15` and
`K = 30`, where both tests are near size, `F_max` matches or beats the LRT in
essentially every printed row. That is the paper's claim and Table 1 supports it
*at the sample sizes where the comparison is fair* — but note that the abstract
fences the claim the same way the table does, to "higher intraclass correlation
values" (p. 765). **No published row shows the power comparison at low `ρ₁`**,
which is the region this package cares about, so the superiority claim should
never be quoted without its `ρ₁ ≥ 0.7` restriction.

Figures 1–4 (pp. 775–776) plot the same material: Figs 1–2 show the alpha level
against `ρ₁=ρ₂=ρ₃` at `K = 15` and `K = 30`; Figs 3–4 show power. Fig. 3
(`ρ₃ = 0.7, K = 15`) has the characteristic V shape, power dropping to ~0.03 at
`ρ₁ = ρ₂ = 0.7` where `H₀` is true and rising on both sides.

## Worked example (§4, pp. 777–778)

Srivastava & Katapa (1986) data — **pattern intensity on the soles of the feet
in 14 families** (Table 3, p. 777, giving mother/father/siblings values per
family), split into three samples of `k₁ = 5`, `k₂ = 5`, `k₃ = 4` families;
daughters' and sons' values are put together. Helmert-transformed per the `Q`
matrix printed on p. 777, then Srivastava's Eq. (2.3) applied.

- `ρ̂₁ = 0.8804`, `ρ̂₂ = 0.9567`, `ρ̂₃ = 0.8508`; pooled `ρ̂ = 0.85847`.
- **LRT statistic = 8.2702**; critical values `LRT₀.₀₅ = 5.9915`,
  `LRT₀.₀₁ = 9.2103`, `LRT₀.₁₀ = 4.6052`.
- **`F_max` statistic = 14.453**; critical values `F_max,₀.₀₅ = 5.0155`,
  `F_max,₀.₀₁ = 7.5862`, `F_max,₀.₁₀ = 4.1313`.
- Both reject at 5 % and 10 %; **at 1 % the LRT narrowly accepts (8.2702 <
  9.2103) while `F_max` rejects (14.453 > 7.5862)** — the paper's illustration
  that the tests can disagree on real data.

This is a complete, self-contained worked example (raw data in Table 3,
estimates, both statistics, all six critical values), so it is reproducible
without the authors — the one thing in the M65 cluster that is.

## Traces to

- Nothing in the package — see the grep recorded under **Role** above
  (observed 2026-07-19).
- `cairn/references/xiao2009.md` — shares author Bhandary; that paper's
  Eqs. (12)–(13) pose this same equality-testing problem and cite this line of
  work. The two notes together cover the familial-ICC corner of the shelf.
- The **M67 milestone** (`donner2002`, `konishi1989`, `naik2007`, `young1998`) —
  this paper belongs to that cluster by subject; see the cluster-reassignment
  finding above. Those four notes shipped 2026-07-19 and each names this page as
  a fifth cluster member under the same IP2 fence, so the cross-reference the
  finding asked for now resolves in both directions. `young1998.md` is the
  closest sibling: Bhandary co-authors it, and it shares this paper's Srivastava
  estimator, Helmert transformation, simulation design, and worked data set.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.

## Open questions

- **Outside the contract boundary (IP2)**, like the rest of the equality-testing
  cluster: `intraclass` estimates coefficients and intervals, it does not test
  hypotheses about them across populations. No candidate is proposed.
- **"Several populations" is really three.** The title and abstract say several;
  §2 develops exactly three, `F_max` is a max over the `3·2 = 6` ordered pairs
  (Eqs. 2.10–2.13), and every simulation uses three. Generalizing to `P`
  populations would make it a max over `P(P−1)` statistics with an `α/[P(P−1)]`
  Bonferroni bound — arithmetically obvious but **never stated in the paper**.
  Do not cite it for `P > 3` without saying so.
- **Conservatism is unquantified.** The Bonferroni bound is known to be loose
  here (p. 774, the correlated-`F_i` remark) and Table 2 shows realized sizes as
  low as 0.0165 against a nominal 0.05. The paper does not attempt to quantify
  the resulting power loss, and its own Table 1 `K = 5` rows cannot separate that
  loss from the LRT's size inflation.
- **The `σ²₁ = σ²₂ = σ²₃` assumption** (Note, p. 769) is stated for the LRT and
  is also implicitly required for the `F_i` to be exactly `F`-distributed under
  `H₀` — a ratio of two `σ²(1−ρ)χ²` terms only sheds `σ²` if the two `σ²` are
  equal. The paper never tests it, never states its consequence for `F_max`, and
  the worked example does not check it. Recorded as a gap in the paper, not a
  defect in the algebra.
- **No `ρ = 0` cell.** The simulation's lowest value is `ρ = 0.1`, matching
  `xiao2009` and leaving the exact boundary untested — the fifth consecutive M65
  source to stop short of it.
