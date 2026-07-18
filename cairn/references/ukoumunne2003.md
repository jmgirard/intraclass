# ukoumunne2003 — Non-parametric bootstrap CIs for the ICC (one-way)

**Citation.** Ukoumunne OC, Davison AC, Gulliford MC, Chinn S (2003).
"Non-parametric bootstrap confidence intervals for the intraclass correlation
coefficient." *Statistics in Medicine* 22(24):3805–3821. DOI 10.1002/sim.1643.
PDF: `cairn/references/pdf/ukoumunne2003.pdf` (gitignored).

**Role.** M62 primary source (IP1) for the non-parametric bootstrap CI candidate.

## Model / estimand (p. 3806, eq. 4)

One-way random effects, balanced: `Y_ij = μ + a_i + e_ij`, `i = 1…k` clusters
(subjects), `j = 1…n` per cluster; `a_i ~ N(0, σ²_a)`, `e_ij ~ N(0, σ²_e)`
independent. `ρ = σ²_a / (σ²_a + σ²_e)`. This is the one-way ICC — package
`ICC(1,1)`-family, single facet.

## Procedure (what the prototype must implement)

- **Resampling scheme (§3.1, p. 3808).** For clustered data, **resample entire
  clusters/subjects with replacement, retaining all observations within each
  selected cluster** ("strategy 1"). Resampling individuals *within* clusters is
  wrong — it breaks the correlation structure. Decisive for the prototype: the
  unit of resampling is the subject, not the row.
- **Variance-stabilizing transform (§4, p. 3809, eq. 6).** `ρ̂` is *not* a pivot
  (its variance grows with `ρ`, Fig. 1a). Use
  `f(ρ) = log{[1 + (n−1)ρ] / (1 − ρ)}` (= `log F`, the ANOVA F-statistic on the
  log scale), which has stable variance for clustered normal data (Fig. 1b).
- **Interval methods compared (§3.2).** basic, bootstrap-t, percentile,
  bias-corrected (BC), bias-corrected-accelerated (BCa) — each applied to `ρ̂`
  directly and (basic, bootstrap-t) to the `log F` transform.
- **Bootstrap-t SE via infinitesimal jackknife (§4, p. 3811, eq. 7)**, avoiding a
  nested bootstrap:
  `SE_IJ(log F) = sqrt( Σ_{i=1}^k [ n_i(ȳ_i·−ȳ··)²/SSA − (Σ_j (y_ij−ȳ_i·)²)/SSE ]² )`
  with `SSA`, `SSE` the between/within-cluster sums of squares. The transformed
  bootstrap-t interval is formed on `log F`, then back-transformed to `ρ`.

## Simulation + key findings (§5, pp. 3811–3815)

- Design: 3×4×2 factorial — clusters `k ∈ {10, 30, 50}`, `ρ ∈ {0.001, 0.01,
  0.05, 0.3}`, normal vs non-normal; **n = 10 subjects/cluster**, balanced. 2000
  data replications × 2000 bootstrap resamples; equal-tailed 95% CIs; negatives
  not truncated. Coverage SE just under 0.5% (p. 3812).
- **Standard (untransformed) bootstrap methods under-cover badly at k = 10** —
  e.g. Fig. 2 (normal), ρ=0.001, k=10: bootstrap-t ≈ 0.87, BCa ≈ 0.82 (plot-read,
  approximate); they reach ~nominal only near k = 50.
- **The `log F`-transformed bootstrap-t is ≈ nominal (0.95) across k**, including
  k = 10 (Fig. 2, ×-marker). It is the paper's recommended method.

## Traces to (M62)

- The prototype non-parametric bootstrap (subject-resampling + transformed
  bootstrap-t + IJ SE) — the primary candidate to assess.
- The GP6 few-subjects / near-zero-ρ failure axis (k=10, ρ→0 under-coverage).
- Cross-checked against ohyama2025's independent NBOOT coverage (same method).
