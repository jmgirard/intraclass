# mcgraw1996 — The ICC(A,·)/ICC(C,·) naming and Case 3A

**Citation.** McGraw KO, Wong SP (1996). "Forming inferences about some
intraclass correlation coefficients." *Psychological Methods* 1(1):30–46.
Correction: *Psychological Methods* 1(4):390 — **included as the final page of the
PDF** and extracted below. PDF: `cairn/references/sources/mcgraw1996.pdf` (gitignored).

**Role.** Source of the package's public coefficient labels (`ICC(1)`, `ICC(k)`,
`ICC(A,1)`, `ICC(A,k)`, `ICC(C,1)`, `ICC(C,k)`) and of **Case 3A** — the
fixed-rater finite-population variance θ²_c that the whole fixed-rater family in
`ORACLES.md` rests on.

## The five models (Table 1, p. 32)

Data matrix (Table 2, p. 33): `x_ij`, rows `i = 1…n` are the randomly chosen
objects of measurement, columns `j = 1…k` the measurements. The case labels 1, 2,
3 are taken from Shrout and Fleiss (1979), who "did not formally consider Cases
2A and 3A" (p. 31). "The *A* extension to case numbers indicates that the
interaction component is absent from the model" (p. 32).

| Case | Model (Table 1) | Column effect |
|---|---|---|
| 1 | `x_ij = μ + r_i + w_ij` | — (one-way random) |
| 2 | `x_ij = μ + r_i + c_j + rc_ij + e_ij` | random, with interaction |
| 2A | `x_ij = μ + r_i + c_j + e_ij` | random, interaction absent |
| 3 | `x_ij = μ + r_i + c_j + rc_ij + e_ij` | **fixed**, with interaction |
| 3A | `x_ij = μ + r_i + c_j + e_ij` | **fixed**, interaction absent |

### Case 3 / Case 3A — the fixed-column finite-population variance

Table 1 (p. 32), Case 3 assumptions, **verbatim**: "Same as for Case 2 except
that the `c_j` are fixed so that `Σc_j = 0`, `Σ_{j=1}^{k} rc_ij = 0`, and the
parameter corresponding to `σ²_c` in Case 2 is `θ²_c = Σc²_j/(k−1)`."

Case 3A (Table 1, p. 32): "Same as for Case 3 except that there is no interaction
effect." So θ²_c carries over unchanged into Case 3A.

**The `(k−1)` divisor is as printed** — `θ²_c = Σc²_j/(k−1)`, not `/k`. Because
`Σc_j = 0`, `c_j` is the deviation of column mean *j* from the grand column mean,
which is exactly the repo's `θ²_r = Σ(μ_rj − μ̄_r)²/(k−1)`.

## Consistency (C) vs. absolute agreement (A) — the naming (pp. 33–34)

"For consistency measures, column variance is excluded from denominator variance;
and for absolute agreement measures, it is not" (p. 33). Column variance is
excluded from consistency denominators "because it is deemed to be an irrelevant
source of variance" (p. 33). Hence "Type C" and "Type A", with designations
`(C,1)`, `(C,k)`, `(A,1)`, `(A,k)` for two-way models (p. 34). "For one-way
models, there are no C-type coefficients because only absolute agreement is
measurable in this context" (p. 34) — the one-way forms are just `ICC(1)` and
`ICC(k)`. Type 1 = single measurement (Table 4), Type k = average of k
measurements (Table 5) (p. 33). Illustrations: paired scores (2,4), (4,6), (6,8)
give `ICC(C,1) = 1.00` but `ICC(A,1) = .67` (p. 34); (0,4), (5,5), (10,6) give
Pearson `r = 1.00` but `ICC(C,1) = .38` (p. 37).

## Table 3 — mean-square expectations (p. 34)

Sources: between rows (`MS_R`, df `n−1`), within rows (`MS_W`, df `n(k−1)`),
between columns (`MS_C`, df `k−1`), error (`MS_E`, df `(n−1)(k−1)`).
Case 3 carries the `k/(k−1)` factor: `E(MS_C) = nθ²_c + [k/(k−1)]σ²_rc + σ²_e`,
`E(MS_E) = [k/(k−1)]σ²_rc + σ²_e`. Case 3A: `E(MS_C) = nθ²_c + σ²_e`,
`E(MS_E) = σ²_e`.

## Tables 4 and 5 — ICCs as variance components *and* as mean squares

Table 4, single score (p. 35) — the rows the package reports:

| Case | ρ (variance components) | ρ̂ (mean squares) | Designation |
|---|---|---|---|
| 1 | `σ²_r/(σ²_r + σ²_w)` | `(MS_R − MS_W)/(MS_R + (k−1)MS_W)` | ICC(1) |
| 2 | `σ²_r/(σ²_r + (σ²_rc + σ²_e))` | `(MS_R − MS_E)/(MS_R + (k−1)MS_E)` | ICC(C,1) |
| 2A | `σ²_r/(σ²_r + σ²_e)` | (same as above) | ICC(C,1) |
| 2 | `σ²_r/(σ²_r + σ²_c + (σ²_rc + σ²_e))` | `(MS_R − MS_E)/(MS_R + (k−1)MS_E + (k/n)(MS_C − MS_E))` | ICC(A,1) |
| 3 | `(σ²_r − σ²_rc/(k−1))/(σ²_r + (σ²_rc + σ²_e))` | `(MS_R − MS_E)/(MS_R + (k−1)MS_E)` | ICC(C,1) |
| 3A | `σ²_r/(σ²_r + σ²_e)` | (same as above) | ICC(C,1) |
| 3 | `(σ²_r − σ²_rc/(k−1))/(σ²_r + θ²_c + (σ²_rc + σ²_e))` | `(MS_R − MS_E)/(MS_R + (k−1)MS_E + (k/n)(MS_C − MS_E))` | ICC(A,1) |
| **3A** | **`σ²_r/(σ²_r + θ²_c + σ²_e)`** | (same as above) | **ICC(A,1)** |

The bolded Case-3A row is the package's fixed-rater ICC(A,1) estimand: θ²_c sits
additively in the denominator exactly where σ²_c sits under Case 2.

Table 5, average score (p. 36): `ICC(k) = (MS_R − MS_W)/MS_R` for Case 1;
`ICC(C,k) = (MS_R − MS_E)/MS_R` (Cases 2/2A with ρ = `σ²_r/(σ²_r + (σ²_rc +
σ²_e)/k)`, and Case 3A with ρ = `σ²_r/(σ²_r + σ²_e/k)`);
`ICC(A,k) = (MS_R − MS_E)/(MS_R + (MS_C − MS_E)/n)`, with Case 3A population
value **`σ²_r/(σ²_r + (θ²_c + σ²_e)/k)`**. Under **Case 3** both `ICC(C,k)` and
`ICC(A,k)` are printed as "**Not estimable**" (Table 5, p. 36; restated p. 37 and
in Appendix A, Eqs. A12/A14, pp. 45–46).

Table 4/5 footnote a: if column variance is zero (`σ²_c = 0` or `θ²_c = 0`) "a
one-way model should be used" (pp. 35–36). Interpretation labels in Tables 4/5:
`ICC(C,1)` = norm-referenced reliability / Winer's anchor-point adjustment;
`ICC(A,1)` = criterion-referenced reliability; `ICC(C,k)` for Cases 2/2A "Known
as Cronbach's alpha in psychometrics" (pp. 35–36).

## Confidence intervals (Table 7, p. 41)

- `ICC(1)`, and `ICC(C,1)` for Cases 2, 2A, 3, 3A: `(F_L − 1)/(F_L + k − 1)` and
  `(F_U − 1)/(F_U + k − 1)`, with `F_L = F_obs/F_tabled`, `F_U = F_obs × F_tabled`
  and `F_obs` the row-effects F. Degrees of freedom `n−1` and `n(k−1)` (one-way)
  or `n−1` and `(n−1)(k−1)` (two-way); `F_tabled` is the `(1 − α/2)×100`th
  percentile (p. 41).
- `ICC(k)` for Case 1, and `ICC(C,k)` for Cases 2, 2A, and 3A **but not 3**:
  `1 − 1/F_L`, `1 − 1/F_U`.
- `ICC(A,1)` for Cases 2, 2A, 3, 3A:
  lower `n(MS_R − F_*MS_E)/(F_*[kMS_C + (kn − k − n)MS_E] + nMS_R)`,
  upper `n(F*MS_R − MS_E)/(kMS_C + (kn − k − n)MS_E + nF*MS_R)`, with
  Satterthwaite `v = (aMS_C + bMS_E)²/[(aMS_C)²/(k−1) + (bMS_E)²/((n−1)(k−1))]`,
  `a = kρ̂/(n(1−ρ̂))`, `b = 1 + kρ̂(n−1)/(n(1−ρ̂))` (p. 41).
- `ICC(A,k)` for Cases 2, 2A, and 3A **but not 3**:
  lower `n(MS_R − F_*MS_E)/(F_*(MS_C − MS_E) + n MS_R)`,
  upper `n(F*MS_R − MS_E)/(MS_C − MS_E + nF*MS_R)` (p. 41) — **see the erratum**.

Test statistics for `H₀: ρ = ρ₀` are in Table 8 (p. 42), derived in Appendix A
(pp. 44–46). Appendix B (p. 46) gives Fisher's transform *for* ICCs:
`z_I = ½ log[(1 + (k−1)r)/(1 − r)]` with variance `σ² = k/[2(n−2)(k−1)]`.

## Worked/reference values (Table 6, p. 39, as corrected)

Three mother–child IQ data sets (10 pairs each) differing only in mean difference
(d = 0.20, 0.60, 1.00), all SD = 15. **As printed:** `r = 0.670`,
`ICC(C,1) = 0.670` for each set; `ICC(A,1) = 0.679, 0.584, 0.457`. **As
corrected** (p. 390): `r = .714` and `ICC(C,1) = .714` for each set;
`ICC(A,1) = .720, .620, .485` for columns 1, 2, 3. The qualitative point survives
either way: ICC(A,1) declines as the fixed-group mean difference grows, while
ICC(C,1) and *r* do not (p. 38).

## The correction (Psych. Methods 1(4):390 — final PDF page)

Three errors: (1) the Table 6 values above; (2) in Table 7, the ICC(A,k)
degrees-of-freedom `v` must be computed with `c = ρ̂/(n(1−ρ̂))` in place of `a`
and `d = 1 + ρ̂(n−1)/(n(1−ρ̂))` in place of `b` — i.e. ICC(A,k) does *not* reuse
the ICC(A,1) `a`/`b`; (3) on pp. 44–46 "Equations A3, A4, and so forth" should
read "Sections A3, A4".

## Traces to

- The public labels `ICC(1)`/`ICC(k)`/`ICC(A,1)`/`ICC(A,k)`/`ICC(C,1)`/`ICC(C,k)`
  and the `ORACLES.md` notation bridge (line 48) to Shrout & Fleiss's
  `ICC(1,·)`/`ICC(2,·)`/`ICC(3,·)`; see `shrout1979.md`.
- **Case 3A θ²_c** — the fixed-rater finite-population variance behind
  `theta2r_fixed()` and the fixed-rater oracles O-Bayes-Fixed, O-Bayes-IFixed,
  O-Bayes-FRep and the nested/cluster fixed families (`ORACLES.md` lines ~261,
  343, 423–430, 574, 685, 878, 893, 1111, 1244, 1273); estimand-specs
  `M10-fixed-multilevel.md §2`, `M3-incomplete-designs.md §6`.
- The Case-3 "Not estimable" verdict for `ICC(C,k)`/`ICC(A,k)`, relevant to which
  fixed-rater average-score forms the package may define.
- The consistency-vs-agreement framing in `choosing-an-icc.Rmd`.

## Open questions

- **The notation bridge is inferential, not printed.** The paper never writes
  "ICC(A,1) = ICC(2,1)". It states only that the case labels 1, 2, 3 come from
  Shrout & Fleiss (p. 31) and that `ICC(A,1)` for mixed models and `ICC(C,1)`,
  `ICC(C,k)` for random-effects models "were not among the ICCs that Shrout and
  Fleiss defined" (p. 37). The bridge in `ORACLES.md` line 48 therefore rests on
  matching *cases* (Case 2 → SF Case 2, Case 3 → SF Case 3) plus identical
  mean-square formulas, not on a statement in this paper. No value is affected;
  flagged so the attribution is not overstated.
- **Symbol mismatch (naming only, no value affected).** The paper's fixed-column
  variance is `θ²_c` (columns); the repo writes `θ²_r` (raters). Same quantity,
  same `(k−1)` divisor — recorded so a future reader does not read the two as
  different parameters.
- **Possible uncorrected typo in Table 8 (p. 42), to escalate — not reconciled
  here.** In the "Cases 2 and 2A, 3 and 3A" / "Type C ICCs" row, the Type-k F
  statistic renders as `(MS_R/MS_W)(1 − ρ₀)`, but Appendix A Eq. A4 (p. 44)
  derives it by "Replacing σ²_w and MS_W in Equation A2 with σ²_e and MS_E",
  giving `F = (MS_R/MS_E)(1 − ρ₀)`. The `MS_W` in that Table 8 cell appears
  inconsistent with the appendix; the published correction does not mention it.
  Reported as a finding only — no oracle or code change proposed.
- **No rater/judge worked example.** Table 6 is mother–child IQ pairs (k = 2), so
  this paper gives no independent numeric check on the O1 coefficients. Nor does
  it give an *estimator* for θ²_c beyond the Table 3 mean-square identities — the
  bias correction in `theta2r_fixed()` is not sourced here.
