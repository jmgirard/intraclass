# ohyama2025 — CI methods for the one-way ICC, a comparison (oracle)

**Provenance.** Ingested 2026-07-18 by M62 from `cairn/references/sources/ohyama2025.pdf` (gitignored).
Pagination: printed journal pages 587–602.
Extraction: unverified — first pass, values not yet re-read against the source — observed 2026-07-18.

**Citation.** Ohyama T (2025). "A comparison of confidence interval methods for
the intraclass correlation coefficient based on the one-way random effects
model." *Japanese Journal of Statistics and Data Science* 8:587–602. DOI
10.1007/s42081-025-00292-3.

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
bootstrap data sets. Results in Figs 1–2 (coverage + tail error vs ρ) — plotted,
not tabled.

## Key findings (§3.2, p. 595 + abstract)

- **REML best overall** — excellent coverage across cells; at k=10, n≥5 slightly
  below nominal but still better than SEARLE. Best on coverage, tail-error
  balance, and mean width (abstract, p. 587).
- **NBOOT ≈ SEARLE, slightly worse** — "Method NBOOT showed similar trends to
  method SEARLE, but overall, method SEARLE performed slightly better" (p. 595).
- SEARLE: excellent at k=10,n=2 and k=25; drops to ≈0.90 at k=10, n≥5.
- SMITH: strongly ρ-dependent; good only at k=50.

## Traces to (M62)

- **Oracle for the NBOOT prototype:** our transformed-bootstrap-t coverage at
  comparable cells should track ohyama's NBOOT curve (Figs 1–2; plot-read
  tolerance) — a real implementation check.
- **Prior on the verdict:** NBOOT is *not better* (slightly worse) than the
  F/REML family → a strong NO-GO prior for "not worse than incumbents", to be
  confirmed by the M62 paired comparison, not assumed.
