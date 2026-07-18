# Non-parametric bootstrap vs incumbents — one-way ICC (M62 comparison)

**Type.** Synthesis note (M62). Pre-registration first (this file, committed
*before* any results — GP5); results + verdict appended at T5.

**Question.** Is a non-parametric (cluster/subject-resample) bootstrap CI for the
one-way random ICC "not worse" than the package's incumbent interval methods
(Monte-Carlo default; parametric bootstrap)? Sources: ukoumunne2003 (method),
ohyama2025 (independent oracle). GO/NO-GO, no exported method.

---

## Pre-registration (frozen 2026-07-17, before any prototype run)

### Design

One-way random effects, balanced: `y_ij = μ + a_i + e_ij`, `i = 1…k` subjects,
`j = 1…n` ratings/subject; `a_i ~ N(0,σ²_a)`, `e_ij ~ N(0,σ²_e)`. Estimand
`ρ = σ²_a/(σ²_a+σ²_e)` (package one-way ICC, `ICC(1,1)` family). Fix
`σ²_a+σ²_e = 1`, `μ = 0`, Gaussian. `n_rep = 2000` datasets/cell (coverage
Monte-Carlo SE ≈ √(.95·.05/2000) ≈ 0.005 = 0.5 pp; matches ukoumunne/ohyama).

### Cells

**Comparison cells** (interrater-realistic; the verdict rests on these):

| cell | k (subjects) | n (ratings) | ρ | role |
|---|---|---|---|---|
| C1 | 30 | 4 | 0.50 | interior / comfortable |
| C2 | 30 | 4 | 0.05 | near-zero-ICC boundary (σ²_a→0) |
| C3 | 12 | 4 | 0.50 | few-subjects (GP6; ukoumunne under-coverage regime) |
| C4 | 12 | 4 | 0.05 | corner: few-subjects × boundary (worst case) |

**Oracle-check cells** (validate the NBOOT *implementation*, not the verdict —
match ukoumunne2003 Fig. 2, normal): `k ∈ {10,30,50}`, `n = 10`, `ρ = 0.05`. Our
transformed bootstrap-t coverage must track their published curve (≈0.94–0.95
transformed; the untransformed bootstrap-t / BCa ≈0.82–0.90 at k=10) within a
plot-read tolerance (±0.03).

### Methods

- **Incumbents:** MC (`ci_method="montecarlo"`, glmmTMB REML covariance) and
  parametric bootstrap (`ci_method="bootstrap"`).
- **Candidate (non-parametric bootstrap):** resample whole **subjects** with
  replacement (ukoumunne2003 §3.1 "strategy 1"), refit, and form:
  - percentile (baseline), and
  - the **`log F` variance-stabilizing transformed bootstrap-t** with an
    infinitesimal-jackknife SE (ukoumunne2003 §4, eq. 6–7) — the paper's
    recommended variant and the **primary** candidate.
  - BCa reported as an additional reference point.
  `2000` bootstrap resamples/dataset.

### "Not worse" criterion (GP5 — fixed before results)

Nominal 95%. Methods evaluated on the **same** simulated datasets per cell
(paired). The candidate variant is **"not worse" at a cell** iff BOTH:

1. **Near nominal:** empirical coverage ≥ **0.93** (nominal − 2 pp; under-coverage
   is the failure — over-coverage passes (1) but is penalized on width).
2. **Not below the incumbents:** empirical coverage ≥ (min of the two incumbents'
   coverage at that cell) − **0.01** (≈ 2·SE paired slack).

**Tiebreaker (width):** among variants passing (1)+(2), prefer smaller **median
interval width**; a narrower interval that fails (1) or (2) does **not** win.

**Overall GO** iff the primary candidate (transformed bootstrap-t) is "not worse"
at **every** comparison cell — C2/C3/C4 (boundary / few-subjects) are decisive.
Otherwise **NO-GO**. The percentile/BCa variants are reported for context, not as
the GO gate.

**Prior (not the verdict).** ohyama2025 finds NBOOT slightly *worse* than the
classical F CI, with REML best; ukoumunne2003 finds untransformed bootstraps
under-cover at k≈10. Expectation is NO-GO; the pass confirms empirically (GP5 —
the evidence decides, not the prior).

---

## Results (T5 — TBD)

_Appended after the T4 harness runs. Comparison table (coverage + median width
per method × cell), the ohyama2025 / ukoumunne2003 oracle cross-check, and the
criterion applied to give the verdict._

## Verdict (T6 — TBD)

_GO / NO-GO with the D-entry reference._
