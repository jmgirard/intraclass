# ukoumunne2003 — Non-parametric bootstrap CIs for the ICC (one-way)

**Provenance.** Ingested 2026-07-18 by M62 from `cairn/references/sources/ukoumunne2003.pdf` (gitignored).
Pagination: printed journal pages 3805–3821 (17 PDF pages, PDF p. 1 = printed
p. 3805; the version of record).
Extraction: verified 2026-07-19 against the source (all 17 PDF pages read to the
final page — **Appendix A sits at pp. 3818–3820**, after the Discussion and
before the References, and carries the Eq. (7) derivation); Table I's ρ = 0.05
block was re-read cell by cell and every coverage recomputed, the Appendix A
derivation was re-run and reproduces Eq. (7) exactly, and six prose/anchor claims
were corrected — including one that inverted a paper finding — observed
2026-07-19.

**Citation.** Ukoumunne OC, Davison AC, Gulliford MC, Chinn S (2003).
"Non-parametric bootstrap confidence intervals for the intraclass correlation
coefficient." *Statistics in Medicine* 22(24):3805–3821. DOI 10.1002/sim.1643.
Received November 2002, accepted July 2003; presented at the Twenty-third Annual
Conference of the International Society for Clinical Biostatistics, Dijon, 9–13
September 2002. The **issue number `(24)` is not printed anywhere in the PDF** —
the running foot gives only `22:3805–3821` — so it is carried from an external
record, not from the source.

**Role.** M62 primary source (IP1) for the non-parametric bootstrap CI candidate.

## Model / estimand (ρ at p. 3806 eq. 1; the model at p. 3807 eq. 4)

One-way random effects, balanced: `y_ij = μ + a_i + e_ij` (eq. 4, **p. 3807**),
`i = 1…k` clusters (subjects), `j = 1…n` per cluster. `ρ = σ²_a / (σ²_a + σ²_e)`
is eq. (1), **p. 3806**. This is the one-way ICC — package `ICC(1,1)`-family,
single facet.

The paper requires only that `a_i` and `e_ij` be i.i.d. with means 0 and
variances `σ²_a`, `σ²_e` and independent of each other; normality is an
*additional* assumption it flags as optional — p. 3807 says it "is not essential
for point estimation of ρ". It *is* essential for the exact analytical interval
(eq. 5, p. 3807), which the paper says "will only provide correct intervals when
both the a_i and the e_ij are normally distributed".

## Procedure (what the prototype must implement)

- **Resampling scheme (§3.1, p. 3808).** For clustered data, **resample entire
  clusters/subjects with replacement, retaining all observations within each
  selected cluster** — what the paper calls "the first strategy" of the two it
  names (not "strategy 1"; the source uses no such label). Resampling individuals
  *within* clusters is inappropriate because "it would break the correlation
  structure"; Davison and Hinkley are cited (`[8, pp. 100–102]`) as showing the
  cluster-level strategy preferable. Decisive for the prototype: the unit of
  resampling is the subject, not the row.
- **Variance-stabilizing transform (§4, p. 3809, eq. 6).** `ρ̂` is *not* a pivot
  (its variance grows with `ρ`, Fig. 1a — 61 simulated data sets, 100 clusters ×
  100 subjects/cluster, `ρ` from 0 to 0.3 in steps of 0.005). Use
  `f(ρ) = log{[1 + (n−1)ρ] / (1 − ρ)}` (= `log F`, the ANOVA F-statistic on the
  log scale), which has stable variance for clustered normal data (Fig. 1b).
  The paper notes that `½ log(F)` is the quantity with "both variance stabilizing
  and normalizing properties" and that it deliberately used **the simpler
  `log(F)`** instead — the halving is a monotone rescaling, so the interval is
  unaffected.
- **Interval methods compared (§3.2).** basic, bootstrap-t, percentile,
  bias-corrected (BC), bias-corrected-accelerated (BCa) — each applied to `ρ̂`
  directly and (basic, bootstrap-t) to the `log F` transform.
- **Bootstrap-t SE via infinitesimal jackknife (§4, p. 3811, eq. 7)**, avoiding a
  nested bootstrap:
  `SE_IJ(log F) = sqrt( Σ_{i=1}^k [ n_i(ȳ_i·−ȳ··)²/SSA − (Σ_j (y_ij−ȳ_i·)²)/SSE ]² )`
  with `SSA`, `SSE` the between/within-cluster sums of squares. The transformed
  bootstrap-t interval is formed on `log F`, then back-transformed to `ρ`.
  **Derived in Appendix A (pp. 3818–3820)**, which the body points to at p. 3811.
  Re-derived here and it reproduces eq. (7) exactly: the empirical influence value
  is `U(x_i; Ĝ) = k·[ n_i(ȳ_i·−ȳ··)²/SSA − Σ_j(y_ij−ȳ_i·)²/SSE ]` (eq. A10), and
  substituting into `SE_IJ(θ̂) = (m⁻² Σ_i U²(x_i; Ĝ))^{1/2}` (eq. A1) with
  **`m = k`** — the resampling unit is the cluster, not the observation — makes
  the `k²` cancel against `m⁻²`, leaving the bare `sqrt(Σ_i [·]²)` of eq. (7).
  Note the constant term `C` of eq. (A3) drops out (eqs. A4–A5) because equal
  cluster sizes make `C• = C`; that cancellation is what makes the IJ SE cheap.

## Simulation + key findings (§5, pp. 3811–3815)

- Design: 3×4×2 factorial — clusters `k ∈ {10, 30, 50}`, `ρ ∈ {0.001, 0.01,
  0.05, 0.3}`, normal vs non-normal; **n = 10 subjects/cluster**, balanced. 2000
  data replications × 2000 bootstrap resamples; equal-tailed 95% CIs; negatives
  not truncated. Coverage SE just under 0.5% (p. 3812).
- **Standard (untransformed) bootstrap methods under-cover badly at k = 10** —
  normal outcomes, ρ = 0.001, k = 10: bootstrap-t **0.8805**, BCa **0.8280**.
  These are *exact*, recomputed from the Table I error rates on p. 3815
  (`100 − lower − upper`), not read off Fig. 2 — Table I tabulates the same
  design cells the figure plots, so no plot-read is needed here. They reach
  ~nominal only near k = 50.
- **The `log F`-transformed bootstrap-t is close to nominal across k, but not
  uniformly so.** At its worst tabulated normal cell — ρ = 0.001, **k = 30** — it
  is **0.9310**, not ≈ 0.95; the ρ = 0.001, k = 10 cell (0.9320) sits just above
  it. Recomputed as `coverage = 100 − lower − upper` over all **12** transformed
  bootstrap-t normal cells of Table I (`k ∈ {10, 30, 50}` × `ρ ∈ {0.001, 0.01,
  0.05, 0.3}`, p. 3815): the minimum is 0.9310 (k = 30) then 0.9320 (k = 10),
  both at ρ = 0.001. (An earlier version of this note gave the worst as 0.9320 at
  k = 10; corrected at M74 — the k = 30 cell is fractionally worse.) p. 3814 flags
  exactly this and names both, saying the method "generally provided close to 95
  per cent coverage with only a slight deviation from this level when ρ was 0.001
  and there were just 10 or 30 clusters". It is
  still the paper's recommended method, and the only one whose error is spread
  roughly evenly across the two tails.
- **Caveat the paper itself raises (p. 3816), material to D-006's width
  condition:** the transformed bootstrap-t's "intervals produced are quite wide
  relative to the exact analytical method for normal balanced data even in
  scenarios where the latter is known to provide correct coverage". Coverage is
  bought with width — which is why D-006 requires truncated-vs-untruncated width
  reported on a common scale.

## Table I reference values (p. 3815) — the M62 oracle anchor

Table I reports **error rates** (% beyond each bound) for 95 % intervals, normal
outcomes, n = 10 subjects/cluster. **Coverage is derived as
`100 − lower − upper`** (stated here so the derivation is explicit, not implied).
Extracted for ρ = 0.05, the M62 oracle-check cells:

| k | method | lower % | upper % | ⇒ coverage |
|---|---|---|---|---|
| 10 | transformed bootstrap-t | 3.25 | 2.95 | **0.938** |
| 10 | bias-corrected accelerated | 2.4 | 14.2 | **0.834** |
| 10 | bootstrap-t (untransformed) | 8.1 | 2.3 | 0.896 |
| 10 | analytical (exact F) | 2.2 | 2.85 | 0.9495 |
| 30 | transformed bootstrap-t | 3.2 | 2.4 | **0.944** |
| 30 | bias-corrected accelerated | 2.2 | 5.8 | **0.920** |
| 50 | transformed bootstrap-t | 3.45 | 2.6 | **0.9395** |
| 50 | bias-corrected accelerated | 2.7 | 5.2 | **0.921** |

Note the *tail* asymmetry Table I exposes and two-sided coverage hides: at k=10,
ρ=0.05 BCa misses 14.2 % on the upper tail vs 2.4 % lower; only the transformed
bootstrap-t distributes error roughly evenly (3.25/2.95) — p. 3814 states this as
a finding. Percentile is not tabulated in Table I (its four methods are
analytical, BCa, bootstrap-t, transformed bootstrap-t); Table II, p. 3817, is the
non-normal counterpart.

**Scope of the paper's "3 per cent" claim (p. 3816) — corrected.** The sentence
is *conditional on non-normal data*, not a global statement: "Even for data
simulated to exhibit a marked degree of non-normality at the cluster level, the
coverage of the transformed bootstrap-t method was never lower than 3 per cent
below the nominal 95 per cent level." A previous version of this note quoted it
truncated at "the nominal 95" and labelled it the paper's *global* claim, which
overstated its reach. Read as written it is a **floor for the harder case**: if
the method holds within 3 points under marked non-normality, the normal case is
no worse — and Table I's minimum, 0.9310 (k = 30, ρ = 0.001), is consistent with
that floor.

## Traces to (M62)

- The prototype non-parametric bootstrap (subject-resampling + transformed
  bootstrap-t + IJ SE) — the primary candidate to assess.
- The GP6 few-subjects / near-zero-ρ failure axis (k=10, ρ→0 under-coverage).
- Cross-checked against ohyama2025's independent NBOOT coverage (same method).

## Notes for the D-006 implementation

Two things this re-verification sharpened, both bearing on the exported
bootstrap-t milestone whenever it is planned:

- **The method's own worst tabulated cell is 0.9310** (normal, ρ = 0.001,
  k = 30; the k = 10 cell is 0.9320 — see the full-table recomputation above).
  A coverage pin set at "≈ nominal" against this source would be
  pinning a value the source does not claim; the paper's own floor is the
  p. 3816 non-normality sentence, not a point claim of 0.95.
- **Width is the paid cost** (p. 3816) — the source expects wider intervals than
  the exact analytical method even where the analytical one is correct, so a
  width regression against the analytical baseline is an expected finding, not a
  defect.
