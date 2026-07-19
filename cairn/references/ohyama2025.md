# ohyama2025 — CI methods for the one-way ICC, a comparison (oracle)

**Provenance.** Ingested 2026-07-18 by M62 from `cairn/references/sources/ohyama2025.pdf` (gitignored).
Pagination: printed journal pages 587–602 (16 PDF pages, PDF p. 1 = printed
p. 587; the version of record, open access).
Extraction: verified 2026-07-19 against the source (all 16 PDF pages read to the
final page); the §3.2 simulation settings were confirmed value by value, the
every quoted string confirmed verbatim, and **both §4 worked examples (pp. 599–600)
were recovered — the first pass never reached them** and recomputed from their
own ANOVA tables, reproducing the printed ICCs to three decimals — observed
2026-07-19.

**Citation.** Ohyama T (2025). "A comparison of confidence interval methods for
the intraclass correlation coefficient based on the one-way random effects
model." *Japanese Journal of Statistics and Data Science* 8:587–602. DOI
10.1007/s42081-025-00292-3. Received 28 June 2024, revised 31 October 2024,
accepted 2 January 2025, published online 19 January 2025. Open access
(CC BY 4.0), single-authored (Tetsuji Ohyama, Kurume University).

**Role.** M62 synthesis/**oracle** note — an independent published coverage/width
comparison of one-way-ICC CI methods, including Ukoumunne's non-parametric
bootstrap. Used to validate the M62 harness (oracle-first, `PRINCIPLES.md #1`).

## Model (p. 588, eq. 1–2)

Same one-way random effects model + `ρ = σ²_a/(σ²_a+σ²_e)` as ukoumunne2003.
`ρ̂ = (MSA − MSE)/(MSA + (n₀−1)MSE) = (F−1)/(F+n₀−1)`, `F = MSA/MSE`.

## Methods compared (§2), by our-package mapping

| ohyama label | Source | Mechanism | Our-package analogue |
|---|---|---|---|
| SEARLE | Searle 1971 (eq. 4/6) | exact F-distribution limits | classical ANOVA CI (not an `icc()` method) |
| SMITH | Smith 1957 (eq. 8) | large-sample normal `V(ρ̂)` | — |
| **NBOOT** | **Ukoumunne 2003** | **transformed bootstrap-t on `log F`, IJ SE, subject-resample; 2000 boot sets** | **the M62 candidate** |
| REML | Burch 2011 (eq. 9) | REML asymptotic `log(1+nθ̂)` | closest to our REML-covariance MC default (not identical) |
| BETA | Demetrashvili 2016 | beta approx. of `ρ̂` | — |

Note: our incumbents (MC = simulate from REML parameter covariance; parametric
bootstrap = simulate-from-fit + refit) are **not identical** to any ohyama method,
so ohyama validates our **NBOOT prototype** directly (same method) and gives only
a qualitative expectation for our incumbents.

## Simulation settings (§3.2, p. 595)

Balanced + unbalanced (MCAR 0.1). `k (subjects) ∈ {10, 25, 50}`,
`n (per subject) ∈ {2, 5, 10, 25}`, `ρ ∈ {0.1, 0.3, 0.5, 0.7, 0.9}`, `σ²_e = 1`,
`μ = 0`, normal random effects+errors. 95% CIs; NBOOT built from **2000**
bootstrap data sets. Every value in this paragraph was re-checked against p. 595.

**Figure map (corrected — the split is by design, not by quantity).** Each of
Figs 1–2 plots coverage *and* both tail error rates against ρ; they differ by
**design**: **Fig. 1 = balanced, Fig. 2 = unbalanced** (captions, pp. 596–597).
Since the M62 harness is balanced, **Fig. 1 is the oracle panel** — the earlier
"Figs 1–2 (coverage + tail error vs ρ)" reading obscured that.

**Width figures exclude NBOOT — decisive for oracle scope.** Figs 3–4 (mean
width, balanced and unbalanced; pp. 598–599) plot **only REML, SEARLE and BETA**.
The paper narrowed the width comparison to the three methods that "showed good
coverage probabilities" (p. 601). So this source can oracle our NBOOT prototype's
**coverage**, but supplies **no NBOOT width curve at all** — a width claim about
NBOOT cannot be traced here.

The simulation results are plotted, not tabled; the paper's only tables are the
two ANOVA tables of the §4 examples (Tables 2–3).

## Key findings (§3.2, p. 595 + abstract)

- **REML best overall** — excellent coverage across cells; at k=10, n≥5 slightly
  below nominal but still better than SEARLE. Best on coverage, tail-error
  balance, and mean width (abstract, p. 587).
- **NBOOT ≈ SEARLE, slightly worse** — "Method NBOOT showed similar trends to
  method SEARLE, but overall, method SEARLE performed slightly better" (p. 595).
- SEARLE: excellent "when k = 10 and n = 2 and when k = 25 and 50"; drops to
  about 90 % for k = 10 and n ≥ 5. The earlier reading dropped **k = 50** from the
  excellent-coverage list.
- SMITH: strongly ρ-dependent; the dependence weakens as k grows and good
  coverage is obtained at k = 50.
- BETA: good coverage at n ≥ 5, tail errors closer to nominal than SEARLE or
  REML; at n = 2 coverage is underestimated as k shrinks and the lower error rate
  in particular exceeds nominal (p. 598).
- **The recommendation is conditional, not a clean sweep (§5, p. 601):** REML is
  recommended overall, "However, method SEARLE may also be used when n = 2, and
  method BETA may also be used when n ≥ 5" — at n = 2 SEARLE "showed results equal
  to or better than method REML, regardless of the value of k" (p. 598).

**Scope fence — normality only.** §5 states "This study focused on the case
assuming a normal distribution for random effects and errors", and explicitly
notes that Ukoumunne (2002) and Burch (2011) suggest worse performance for SEARLE
and REML under non-normality, calling for further study. So ohyama and
ukoumunne2003 are **not comparable on the non-normality axis** — ukoumunne2003's
central claim is precisely about non-normal robustness, which ohyama never tests.
Do not read ohyama's NBOOT verdict as bearing on that claim.

## §4 worked examples (pp. 599–600) — recovered, directly oracle-usable

The first pass stopped before §4 and recorded this paper as plot-only. It is not:
it prints **two fully worked examples, each with all five methods' 95 % limits**
from a published ANOVA table. These are deterministic, hand-checkable reference
values — far stronger oracle material than a plot-read of Figs 1–2.

**Example 1 — PMOC** (predicted maximal oxygen consumption, 30 subjects,
test–retest; Atkinson & Nevill 1997). Table 2, p. 599: between-subjects
df 29, SS 5377, MS 185.43; within-subjects df 30, SS 665, MS 22.17; total df 59,
SS 6042. Balanced, `k = 30`, `n = 2`, so `n₀ = 2`. `ρ̂ = 0.786`.

| method | 95 % CI |
|---|---|
| SEARLE | (0.600, 0.891) |
| SMITH | (0.649, 0.924) |
| NBOOT | (0.559, 0.900) |
| REML (`κ̂ = −0.277`, `g(κ̂) = −0.515`) | (0.620, 0.885) |
| BETA (`σ̂²_a = 81.63`, `σ̂²_e = 22.17`; `a = 26.0`, `b = 7.05`) | (0.634, 0.906) |

**Example 2 — PaCO₂** (8 subjects, multiple intramural pH / PaCO₂ measurements;
Boyd et al. 1993, Blackman 2004). Table 3, p. 600: between df 7, SS 15.38,
MS 2.198; within df 38, SS 10.33, MS 0.272; total df 45, SS 25.71. **Unbalanced**,
harmonic mean `n̂ = 5.02`. `ρ̂ = 0.585`.

| method | 95 % CI |
|---|---|
| SEARLE, via eq. (6) | (0.232, 0.847) |
| SMITH | (0.224, 0.890) |
| NBOOT | **(−0.058, 0.911)** |
| REML (`κ̂ = 0.562`, `g(κ̂) = 1.282`) | (0.187, 0.822) |
| BETA (`σ̂²_a = 0.488`, `σ̂²_e = 0.274`, `ρ̂_BETA = 0.640`; `a = 6.03`, `b = 3.39`) | (0.329, 0.895) |

**Recomputed here from the printed ANOVA tables** using
`ρ̂ = (MSA − MSE)/(MSA + (n₀−1)MSE)`: PMOC gives 0.78642 (paper: 0.786) and
PaCO₂ gives 0.58515 with `n₀ = n̂ = 5.02` (paper: 0.585) — both reproduce to the
printed three decimals. Each table's SS and df also sum to its printed total. The
MS column carries the paper's own rounding: `5377/29 = 185.41` against a printed
185.43, because the SS is printed to integer precision — a source rounding
artifact, not a discrepancy.

**NBOOT's Example-2 lower limit is negative (−0.058)** — the only negative limit
anywhere in the two examples, and the paper leaves it untruncated. That is a
published instance of the boundary behavior D-006 requires a pre-specified
fallback for, on real data rather than in simulation.

## Traces to (M62)

- **Oracle for the NBOOT prototype:** our transformed-bootstrap-t coverage at
  comparable cells should track ohyama's NBOOT curve (**Fig. 1** for balanced;
  plot-read tolerance) — a real implementation check. **Prefer the §4 examples**
  where they apply: they are exact printed limits from a published ANOVA table
  and need no plot-read at all. Coverage only — Figs 3–4 omit NBOOT, so no NBOOT
  width claim traces here.
- **Prior on the verdict:** NBOOT is *not better* (slightly worse) than the
  F/REML family → a strong NO-GO prior for "not worse than incumbents", to be
  confirmed by the M62 paired comparison, not assumed.
