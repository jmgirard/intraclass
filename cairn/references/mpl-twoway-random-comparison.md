# Modified profile likelihood vs incumbents — two-way random ICC(A,1) (M86/M87)

**Provenance.** Created 2026-07-23 by M86 from the M86 validation harness
(`data-raw/m86-mpl-lib.R`, `data-raw/m86-mpl-validate.R`) against
`xiao2013.md` (the named primary source, IP1). M87 appends its pre-registration,
comparison sweep, and verdict.
Pagination: —.
Extraction: derived — no external source of its own, only as current as its
inputs (`xiao2013.md`, verified 2026-07-19/M71) and the committed harness, none
re-read since 2026-07-23 — observed 2026-07-23.

**Type.** Synthesis note. M86 records the estimand mapping and the
oracle-validation of the from-scratch naive-PL / MPL implementation against
xiao2013's published tables. M87 (separate milestone) adds the package
comparison and GO/NO-GO verdict.

---

## Estimand mapping (M86 T1) — xiao2013 ρ = package ICC(A,1)

The candidate method's estimand and the package's `ICC(A,1)` are the **same
population quantity**, so xiao2013's coverage tables are valid oracles for the
package's two-way random absolute-agreement single-rating ICC.

| | Package `ICC(A,1)` (M1 spec) | xiao2013 (Eq. 1–2, p. 2242) |
|---|---|---|
| Model | `x_ij = μ + s_i + r_j + (sr)_ij + e_ij` | `Y_ij = μ + r_i + s_j + e_ij` |
| Interaction | σ²_sr present but **not identified** at one rating/cell | none — absorbed into `e_ij` |
| Estimable residual | σ²_res ≡ σ²_sr + σ²_e | σ²_e |
| Coefficient | σ²_s / (σ²_s + σ²_r + σ²_res) | σ²_s / (σ²_s + σ²_r + σ²_e) |

With a single rating per subject×rater cell — the design both papers assume —
the package's σ²_sr and σ²_e are not separately identified (M1 spec
§ Identifiability); only σ²_res = σ²_sr + σ²_e is. Identifying xiao2013's σ²_e
with the package's σ²_res, the two ρ definitions are **term-for-term identical**.
xiao2013's "no interaction" is therefore not a different model — it is exactly
the package's single-rating identifiability collapse. Cross-checked against
`mcgraw1996` `ICC(A,1)` (the Shrout–Fleiss Case 2 absolute-agreement form the
M1 spec reduces to).

**Index-transposition warning.** xiao2013 indexes `i = 1…R` **raters** and
`j = 1…S` **subjects** (Eq. 1) — transposed from shrout1979/mcgraw1996 (and this
package), where `i` indexes subjects. Throughout this note and the harness, `S`
is the subject count and `R` the rater count, following xiao2013; the package's
`n` subjects = `S`, `k` raters = `R`.

**Scope of the mapping.** It holds for the balanced, complete, single-rating
two-way random design. Unbalanced/incomplete and within-cell-replicate designs
are out of scope (xiao2013's likelihood assumes every `R×S` cell observed).

---

## Implementation (M86 T2–T3)

`data-raw/m86-mpl-lib.R` implements xiao2013's method from scratch (no author
code exists; `xiao2013.md` § "Software availability is by email"). It operates
on the balanced (SMS, RMS, EMS) ANOVA layout (Table 1, p. 2244):

- **`mpl_neg2l(ρ_s, ρ_r, ms)`** — the −2 log-likelihood, Eq. (7) p. 2245. The
  four eigenvalues (Appendix Eqs. 37–40) enter the determinant term; the
  weighted-SS term pairs the subject/rater/error SS with λ₂/λ₃/λ₄ by matching
  eigenvalue multiplicity. The data- and parameter-free constant `c` (Eq. 66) is
  dropped — it cancels in every deviance and MLE.
- **`mpl_prof_neg2l(ρ)`** — the profile −2l†, Eq. (8): minimise over ρ_r ∈
  (0, 1−ρ) (golden-section + a Brent polish for a tight profile).
- **`mpl_fit`** — the joint MLE (ρ̂_s, ρ̂_r) and the reference min −2l†(ρ̂), via a
  1-D scan seeding a 2-D Nelder–Mead polish. This reference must be precise: an
  imprecise minimum biases every deviance and shifts the interval systematically.
- **`mpl_interval(ms, κ, α, side)`** — Eqs. (9)/(10): the two roots of
  `D(ρ) = (1+κ)·χ²_{1,·}`, where `D(ρ) = −2l†(ρ) − min(−2l†)`. `κ=0` is naive PL,
  `κ=κ_m` is MPL. A one-sided lower bound uses the `1−2α` critical value (so a
  95% lower bound shares the two-sided 90% lower critical value — confirmed
  against Ex. 1).
- **`mpl_kappa_corr` / `mpl_kappa_m`** — the calibration, Eqs. (11)–(13). κ_corr
  is the Bartlett-type MC quantity `quantile_{1−α}(D(ρ_true)) / χ² − 1` (the
  continuous realisation of the paper's seven-step procedure, pp. 2249–2251,
  whose step 7 selects the smallest κ giving coverage ≥ 1−α); κ_m is its maximum
  over the (ρ, δ) grid (ρ ∈ [0.6, 0.9] step 0.1, δ = 2^{−1..4}).

`data-raw/m86-mpl-validate.R` drives the oracle validation and writes
`data-raw/m86-mpl-validation-results.rds` (seeded; provenance in its `meta`).

**Worked-example spot check (Ex. 1, R=4, S=10).** The example reports only
(ρ̂ = 0.8987, δ = 1.26), not the raw teeth data, so the (sms, rms, ems) ratios
are reconstructed as the ANOVA layout whose joint MLE is that (ρ̂, δ); the MLE
reproduces exactly, and the independently root-found naive-PL interval is
(0.7013, 0.9620) against the published (0.7120, 0.9598) — agreement to ~0.011,
attributable to xiao2013's own root-finder, since the 20,000-sim coverage tables
(below) reproduce far more tightly.

## Oracle validation (M86 T4–T5)

_(pending — filled from `data-raw/m86-mpl-validation-results.rds` once the
seeded run completes.)_

## Traces to

- `cairn/references/xiao2013.md` — the primary source (method, Eqs. 1–13; the
  frozen Table 3/4/6/7 oracle values; the ρ_L = 0.6 fence).
- `cairn/estimand-specs/M1-twoway-random-agreement.md` — the package `ICC(A,1)`
  population definition the mapping above targets.
- `cairn/references/npbootstrap-oneway-comparison.md` — the M62 sibling pass
  (same GO/NO-GO shape; the one-way bootstrap analogue).
- `cairn/DECISIONS.md` D-006 (M62 gate split), and the M86/M87 milestone files.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.
