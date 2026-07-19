# shieh2015 — ICC(2) is a biased, MSE-suboptimal index of the average-score ICC

**Provenance.** Ingested 2026-07-19 by M66 from `cairn/references/sources/shieh2015.pdf` (gitignored).
Pagination: printed journal pages 994–1003; the 10 PDF pages map one-to-one onto printed 994–1003.
Extraction: verified 2026-07-19 against the source (all 10 PDF pages read to the final page — note the **Appendix sits after the Acknowledgments**, on pp. 1002–1003, and carries Eqs. A1–A5, the derivations the whole paper rests on); Eq. 5 was re-derived from Appendix Eq. A2 and agrees, which is how the A2 notation slip below was found — observed 2026-07-19.

**Citation.** Shieh, G. "Choosing the best index for the average score intraclass
correlation coefficient." *Behavior Research Methods* 48(3), 994–1003. DOI
10.3758/s13428-015-0623-y. The masthead prints "Behav Res (2016) 48:994–1003"
while the copyright line reads "© Psychonomic Society, Inc. 2015" and
"Published online: 17 July 2015" — **the citekey's `2015` is the online/copyright
year; the version of record is 2016** (see Open questions). Affiliation:
Department of Management Science, National Chiao Tung University, Hsinchu,
Taiwan.

**Role.** The sharpest published critique of the conventional average-score ICC
estimator. It matters to this package because `icc()` exposes
`unit = "average"`, and this paper argues the *standard* way of computing that
quantity is both biased and MSE-suboptimal. **No oracle value traces here** and
no test, vignette, or `ORACLES.md` entry reads it — its only in-repo citations
are the `BIBLIOGRAPHY.md` entry and `INDEX.md` line added by M66 itself. Its
bearing on `choose_icc()` is analysed under
AC3 below, where the decisive point is that the package does **not** use the
estimator Shieh criticises.

## Setting and the two estimands

One-way random effects model, Eq. (1), p. 996: `Y_ij = μ + γ_i + ε_ij`,
`i = 1…N` groups, `j = 1…K` per group, with `γ_i ~ N(0, σ²_γ)` and
`ε_ij ~ N(0, σ²_ε)` independent. The two population quantities (p. 994):

- **single score** `ρ = σ²_γ/(σ²_γ + σ²_ε)`
- **average score** `ρ* = σ²_γ/(σ²_γ + σ²_ε/K)`

The conventional estimators (p. 995), with `F* = MSB/MSW`:

- `ICC(1) = (MSB − MSW)/[MSB + (K−1)MSW] = (F* − 1)/(F* + K − 1)`
- `ICC(2) = (MSB − MSW)/MSB = 1 − 1/F*`

Naming, p. 995: `ICC(2)` "follows the notation of Bartko (1976), Bliese (2000),
and James (1982). However, it has also been referred to as `ICC(k)` in McGraw and
Wong (1996) and as `ICC(1, k)` in Shrout and Fleiss (1979)." — i.e. Shieh's
`ICC(2)` is this package's one-way `unit = "average"` coefficient, *as
conventionally estimated*.

Spearman–Brown link, Eq. (2), p. 996: `Ψ(ρ) = Kρ/[1 + (K−1)ρ]`, and
"`ICC(2) = Ψ{ICC(1)}` for any value `K > 1`" — exact, not asymptotic ("more
precise than the asymptotic equivalence … demonstrated in Bliese (1998)").

## The unified class of estimators

Eq. (3), p. 996: `ρ̂(c) = (F* − c)/(F* + cK − c)`, so `ρ̂(1) = ICC(1)`.
Applying Spearman–Brown, Eq. (4), p. 996:

`ρ̂*(c) = Ψ{ρ̂(c)} = 1 − c/F*`

so `ICC(2) = ρ̂*(1)`, i.e. `c_AV = 1`. The whole paper is then a question about
which constant `c` to use. The seven members (p. 997 and Appendix):

| Index | `c` | Basis |
|---|---|---|
| `ρ̂*_MS` | `c_MS = N(N−5)(K−1)/[(N−1){N(K−1)+2}]` | minimum MSE (Eq. A5) |
| `ρ̂*_MO` | `c_MO = N(N−3)(K−1)/{(N−1)[N(K−1)+2]}` | mode of `F{N−1, N(K−1)}` |
| `ρ̂*_UB` | `c_UB = (N−3)/(N−1)` | unbiased (Eq. A3) |
| `ρ̂*_ME` | `c_ME = F_{(N−1), N(K−1), 0.5}` | median of the `F` distribution |
| `ICC(2)` | `c_AV = 1` | the conventional index |
| `ρ̂*_EF` | `c_EF = N(K−1)/{N(K−1)−2}` | expected value of the `F` distribution |
| `ρ̂*_ML` | `c_ML = N/(N−1)` | maximum likelihood |

Ordering, p. 999, holding "for all four settings of `N` and `K`":
`c_MS < c_MO < c_UB < c_ME < c_AV < c_EF < c_ML`.

## The analytic result

Bias and MSE of the conventional index, Eq. (5), p. 997:

`Bias{ICC(2)} = −2(1 − ρ*)/(N − 3)` and `MSE{ICC(2)} = (1 − ρ*)²M_1`, where
`M_1 = 1 − 2(N−1)/(N−3) + (N−1)²{N(K−1)+2}/[N(N−5)(N−3)(K−1)]`.

Verbatim consequence, p. 997: "This implies that `ICC(2)` is generally a
negatively biased estimator of `ρ*`, and the absolute bias and MSE become
decreasing as the parameter ICC increases for fixed values of `N` and `K`."

Note the bias depends on `N` (number of groups) and **not on `K`** — a point the
numerical tables bear out and which matters for the design-planning result below.

Relative criteria, Eqs. (6)–(7), p. 998:
`RAB{ρ̂*(c)} = |c(N−1) − N + 3|/2` and `RMSE{ρ̂*(c)} = M_c/M_1`. Both are free of
`ρ*`: "the two relative indices … do not depend on the underlying population
`ρ*`" (p. 998), so they rank the estimators once and for all given `N, K`.

## Numerical study (Tables 1–8, pp. 998–1000)

Design (p. 997): `N ∈ {10, 50}`, `K ∈ {10, 50}` → four `(N, K)` cells;
`ρ*` from 0 to 0.90 in steps of 0.1, plus 0.99. Bias in Tables 1–4, MSE in
Tables 5–8. Computation was by "one-dimensional numerical integration with
respect to an `F` probability distribution function", "theoretically exact
provided that the auxiliary function can be evaluated exactly" — not simulation.

Selected values, `N = 10, K = 10` (Table 1, p. 998), `c` then `RAB`:

| | `ρ̂*_MS` | `ρ̂*_MO` | `ρ̂*_UB` | `ρ̂*_ME` | `ICC(2)` | `ρ̂*_EF` | `ρ̂*_ML` |
|---|---|---|---|---|---|---|---|
| `c` | 0.5435 | 0.7609 | 0.7778 | 0.9339 | 1.0000 | 1.0227 | 1.1111 |
| `RAB` | 1.0543 | 0.0761 | 0.0000 | 0.7027 | 1.0000 | 1.1023 | 1.5000 |
| bias at `ρ* = 0` | 0.3012 | 0.0217 | 0.0000 | −0.2008 | −0.2857 | −0.3149 | −0.4286 |

Rankings. Bias, `K = 10` (p. 1000):
`RAB{ρ̂*_UB} < RAB{ρ̂*_ME} < RAB{ρ̂*_MO} < RAB{ICC(2)} < RAB{ρ̂*_MS} < RAB{ρ̂*_EF} < RAB{ρ̂*_ML}`;
at `K = 50` "only the relative absolute biases between `ρ̂*_ME` and `ρ̂*_MO` are
switched". MSE, identical across all four cells (p. 1001):
`RMSE{ρ̂*_MS} < RMSE{ρ̂*_MO} < RMSE{ρ̂*_UB} < RMSE{ρ̂*_ME} < RMSE{ICC(2)} < RMSE{ρ̂*_EF} < RMSE{ρ̂*_ML}`.

Direction of the biases, p. 1000: "`ρ̂*_MS` and `ρ̂*_MO` are positively biased,
while `ρ̂*_ME`, `ICC(2)`, `ρ̂*_EF`, and `ρ̂*_ML` tend to underestimate `ρ*`", and
`RAB{ρ̂*_ML} = 1.5` for every `N` and `K`.

Verdicts, p. 1001: "the four measures `ρ̂*_MS`, `ρ̂*_MO`, `ρ̂*_UB`, and `ρ̂*_ME`
dominate `ICC(2)` in terms of MSE"; "The conventional use of `ICC(2)` for the
estimation of mean rating ICC was not supported both analytically and
empirically." `ρ̂*_UB` "is unbiased for all `N > 3`, `K > 1`, and `0 ≤ ρ < 1`".
Validity fence, Appendix p. 1003: "the prescribed estimation results are valid
for the values of `N > 5` and `K > 1`".

## Two results that reach beyond the estimator choice

**Design allocation — groups beat judges at a fixed budget** (p. 1001).
`(N, K) = (10, 50)` and `(50, 10)` have "the identical total sample size 500", but
"the accuracy and efficiency of the seven estimators in Tables 3 and 7 with
`(N, K) = (50, 10)` are consistently better than the corresponding results in
Tables 2 and 6 with `(N, K) = (10, 50)`". Conclusion as printed: "an increase in
the number of group `N`, rather than the number of judges in each group `K`,
yields more pronounced improvement in estimation for a given total sample size."
Confirmed additionally at `(20, 25)` vs. `(25, 20)`, also totalling 500.

**Truncation at zero** (p. 1001): "A potential deficiency of `ICC(2)` and other
average score ICC estimators is that they can assume negative values even though
ICC is defined as a non-negative parameter. In practice, the estimate is often
set equal to zero when this occurs. Although this simple and intuitive adjustment
is of practical meaning, the fundamental behavior of the estimator is inherently
altered and a single simple formula of bias and MSE cannot be obtained." Shieh
reports that the bias/MSE conclusions are "essentially unchanged unless the
population individual rating ICC is extremely small", and that truncation "occurs
less often for the average score ICC indices than the corresponding individual
rating ICC estimators", so the details "are not reported here".

## Bearing on `choose_icc()` (AC3)

**The decisive fact: the package does not use the estimator this paper
criticises.** Shieh's entire class `ρ̂*(c) = 1 − c/F*` is a plug-in on the one-way
ANOVA ratio `F* = MSB/MSW`. This package forms the average-score ICC by applying
an averaging divisor `k_eff` to mixed-model variance components
(`R/estimand.R:182`, `switch(unit, single = 1, average = k_eff)`), estimated by
REML through the engine layer — not `1 − 1/F*`. So:

1. **No `choose_icc()` change follows.** `choose_icc()` selects *which estimand*
   (type / unit / raters / design); Shieh's question is *which estimator* of a
   fixed estimand. They are orthogonal axes, and the paper offers no evidence
   bearing on the selection tree.
2. **The critique does not transfer automatically to the package's estimator.**
   Shieh's bias formula `−2(1−ρ*)/(N−3)` is a property of the ANOVA plug-in under
   the Eq. (1) balanced one-way normal model. Whether the REML component-ratio
   estimator shares that bias is **not established by this paper** and is not
   asserted here. It is a live question, not a known defect — recorded in the
   work log as a finding for a separate milestone (Scope forbids acting here).
3. **The naming caution is worth keeping.** p. 995 establishes that Shieh's
   `ICC(2)` is Shrout & Fleiss's `ICC(1,k)` and McGraw & Wong's `ICC(k)` — a
   collision with ten Hove/`irr` usage where `ICC₂` means the *two-way* model
   (`tenhove2018.md` Table 3). `shrout1979.md` and `mcgraw1996.md` own the
   canonical mapping; this paper adds a third labelling convention to the pile.

**Divergence recorded, not acted on** — see the work log.

## What this could source

Nothing is proposed here — M66 writes notes, not code (Scope).

- **A closed-form oracle for one-way average-score bias.** Eq. (5) and Appendix
  Eqs. A2/A4 give exact bias and MSE for every member of the class in closed
  form, with `F`-distribution moments — deterministic, hand-checkable, and
  independent of simulation. If the REML-vs-ANOVA question in point 2 above is
  ever taken up, this is the reference curve to check against.
- **Sourced support for a subject-vs-rater allocation claim.** The p. 1001
  design-allocation result is a *published* statement that groups dominate judges
  at fixed total `N·K` for the one-way design. The parked "`d_study()` CI-width
  precision planning" candidate is explicitly **gated on finding an oracle
  strategy** (`cairn/estimand-specs/M4.5-d-study.md` §6); this is adjacent
  evidence but **not** that oracle — Shieh's criterion is point-estimator bias
  and MSE, not interval width, and `d_study()` varies raters `m` only
  (`R/d-study.R:38`). Recorded so the distinction is on file rather than
  rediscovered.

## Traces to

Nothing in `R/`, `tests/`, `vignettes/`, or `ORACLES.md` reads this page.

- `cairn/references/shrout1979.md` and `cairn/references/mcgraw1996.md` — the
  two naming conventions p. 995 reconciles against Bartko/Bliese/James.
- `cairn/references/bartko1976.md` — the source of the `ICC(2)` label Shieh
  adopts; its Eq. (2) is Shieh's `ICC(2)`.
- `cairn/references/tenhove2018.md` — uses `ICC₂` for the *two-way* ICC, the
  colliding convention noted above.
- `cairn/references/BIBLIOGRAPHY.md` (Shieh entry) and `INDEX.md`.

## Open questions

- **Citekey year vs. version of record.** The article is *Behavior Research
  Methods* **48**(3), 994–1003, **2016**; the citekey `shieh2015` follows the
  online-publication and copyright year 2015. Both appear on the shelf PDF's
  first page. The citekey is left alone (renaming it would break the M66 plan's
  Scope list and `INDEX.md`), but `BIBLIOGRAPHY.md`'s entry should carry the
  2016 issue year — flagged for the maintainer — observed 2026-07-19.
- **Notation slip in Appendix Eq. A2** (p. 1002): the bias is printed as
  `Bias{ρ̂*(c)} = E[ρ̂*(c) − ρ] = (1 − ρ)B_c`, using `ρ` (the single-score ICC)
  where `ρ*` is meant. Confirmed by derivation: p. 1002 gives
  `E[ρ̂*(c)] = 1 − c(N−1)(1−ρ*)/(N−3)`, so the bias is `(1 − ρ*)B_c`, and setting
  `c = 1` reproduces Eq. (5)'s `−2(1−ρ*)/(N−3)` exactly. A typographical slip;
  no result depends on it.
