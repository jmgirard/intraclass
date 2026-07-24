# Modified profile likelihood vs incumbents — two-way random ICC(A,1) (M86/M87)

**Provenance.** Ingested 2026-07-23 by M86 from the M86 validation harness
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
- **`mpl_kappa_corr` / `mpl_kappa_m`** — the calibration, Eqs. (11)–(13), the
  continuous realisation of the paper's seven-step procedure (pp. 2249–2251,
  step 7: the smallest κ giving coverage ≥ 1−α). It is **side-specific**: the
  two-sided interval covers when the folded deviance `D ≤ crit`, giving
  `κ_corr = quantile_{1−α}(D) / χ² − 1`; a one-sided lower bound covers on a
  one-tailed event on the **signed** likelihood root `L = sign(ρ̂−ρ)·√D`, giving
  `κ_corr = quantile_{1−α}(L)² / χ²_{1−2α} − 1` (M86 review Finding 2 — the folded
  D would double-count the upper tail and κ would not vanish as the design grows).
  κ_m is the maximum over the (ρ, δ) grid (ρ ∈ [0.6, 0.9] step 0.1, δ = 2^{−1..4}).

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

Seeded reproduction of xiao2013's published tables (`data-raw/m86-mpl-validate.R`,
n_rep = 2000, n_mc = 6000 for κ_m; the published values use 20,000 sims).
Pre-registered tolerances: coverage ±30 (×1000), length ±0.05, κ_m ±0.10. All are
values our machinery produces vs xiao2013's, so this is a repo-analysis
reproduction, not a claim about the source tables (which `xiao2013.md` verified).
κ_m is the max over the Eq. 11 grid; κ_corr grows toward small ρ / large δ, so the
argmax is the (ρ=0.6, δ=16) corner (confirmed by a grid scan). Because the MC
**grid max** is an upward-biased estimator of a maximum (max of noisy per-cell
estimates), κ_m is reported as κ_corr evaluated at that identified corner.

**Table 4 — naive PL, 90% two-sided (p. 2248).** 4/4 coverage and length.

| R | S | δ | ρ | CR ours | CR pub | AL ours | AL pub |
|---|---|---|---|---|---|---|---|
| 3 | 10 | 0.5 | 0.60 | 902 | 902 | 0.498 | 0.498 |
| 3 | 50 | 4.0 | 0.60 | 796 | 796 | 0.418 | 0.420 |
| 3 | 50 | 1.0 | 0.60 | 832 | 838 | 0.339 | 0.340 |
| 5 | 50 | 4.0 | 0.90 | 864 | 875 | 0.184 | 0.186 |

**Table 6 — MPL (published κ_m), 90% two-sided (p. 2250).** 3/3 coverage and length.

| R | S | κ_m | δ | ρ | CR ours | CR pub | AL ours | AL pub |
|---|---|---|---|---|---|---|---|---|
| 3 | 10 | 0.32 | 0.5 | 0.60 | 939 | 945 | 0.571 | 0.569 |
| 3 | 50 | 0.67 | 4.0 | 0.60 | 903 | 908 | 0.556 | 0.559 |
| 5 | 50 | 0.33 | 4.0 | 0.90 | 924 | 927 | 0.232 | 0.230 |

**Table 3 — κ_m calibration (δ_U=16, corner, p. 2247).** Two-sided 3/3 within
±0.10. The one-sided leg (α=0.05; the M86-review Finding-2 signed-root fix) is
reported as corroboration: (3,10) and (5,50) reproduce within ±0.10, while the
(3,50) 0.95-tail quantile at the most-stressed corner is MC-noisy (estimates span
~1.24–1.33) and sits on MPL's deliberately conservative side (xiao2013 p. 2257).
Its **defining** validation is the exact-coverage property below, not this
noisy constant.

| R | S | two-sided ours | two-sided pub | one-sided ours | one-sided pub |
|---|---|---|---|---|---|
| 3 | 10 | 0.333 | 0.32 | 0.643 | 0.72 |
| 3 | 50 | 0.667 | 0.67 | 1.330 | 1.20 |
| 5 | 50 | 0.263 | 0.33 | 0.830 | 0.77 |

**One-sided calibration — defining property (Finding 2).** The corrected one-sided
κ_corr uses the signed likelihood root (not the folded deviance); the MPL lower
bound built at κ = κ_corr covers at **0.956** (target 0.95) on independent draws
at (R=3,S=50,δ=16,ρ=.6) — the direct confirmation that the fixed formula calibrates
a correctly-covering one-sided interval.

**Table 7 — naive PL, 95% one-sided lower (p. 2251).** Coverage 2/2 (the
calibration-relevant property — it validates the `1−2α` one-sided critical value):
(3,50,δ4,ρ.90) 870 vs 865; (3,10,δ0.5,ρ.60) 966 vs 959. The one-sided "average
length" `1 − mean(lower bound)` (xiao2013 p. 2254, "not a length") reproduces at
(3,10) (0.711 vs 0.707) but **not** at the (3,50,δ4,ρ.90) corner (0.276 vs 0.433):
our lower bounds cluster higher there. This is not an implementation defect —
`mpl_prof_neg2l` equals a 6000-point brute-force minimisation to 0 across 200
datasets, the deviance is smooth and monotone, the two-sided Tables 4/6 and the
one-sided coverage all reproduce, and the worked-example MLE is exact. It is an
isolated discrepancy with xiao2013's high-ρ one-sided bound, recorded (not forced
to agree — PRINCIPLES.md #4); it does not affect the two-sided intervals M87 uses.

**Verdict (M86).** The naive-PL and MPL machinery reproduces xiao2013's published
oracles across every two-sided coverage/length anchor (Tables 4/6), the two-sided
κ_m calibration (Table 3), and the one-sided coverage (Table 7) — establishing
correctness (PRINCIPLES.md #1) for the M87 comparison pass, which uses the
two-sided intervals. The one-sided κ_corr, corrected at review (Finding 2), is
validated by its exact-coverage property. Results:
`data-raw/m86-mpl-validation-results.rds`.

---

# M87 — the comparison pass

**Question.** Is the modified profile-likelihood (MPL) interval — with κ_m
**recalibrated over the extended range ρ ∈ [0, 0.9]** — "not worse" than the
package's incumbent interval methods (Monte-Carlo default; parametric bootstrap)
for the two-way random `ICC(A,1)`, across the full ρ range **including the
near-zero boundary** the published κ_m are not calibrated for (xiao2013's
ρ_L = 0.6 fence)? GO/NO-GO, no exported method. Naive PL (κ = 0) is carried as a
reference. Correctness of the machinery is already established (M86, above).

## Pre-registration (frozen 2026-07-23, BEFORE any comparison run — GP5)

### Design

Balanced, complete two-way random effects (xiao2013 Eq. 1):
`Y_ij = μ + r_i + s_j + e_ij`, R raters × S subjects, all mutually independent
Gaussian, total variance fixed at 1. Estimand `ρ = σ²_s / (σ²_s + σ²_r + σ²_e)` =
package `ICC(A,1)` (the term-for-term mapping above). DGP = `mpl_simulate(ρ, δ,
R, S)` with `δ = σ²_r/σ²_e`; `σ²_s = ρ`, `σ²_e = (1−ρ)/(1+δ)`, `σ²_r = δ·σ²_e`.
**Nominal 95%** two-sided (the package default and the incumbents' operating
point). Methods evaluated on the **same seeded datasets** per cell (paired).
`n_rep = 1000` for the cheap methods (MPL, naive PL, MC; coverage MC-SE ≈
√(.95·.05/1000) ≈ 0.7 pp); the parametric bootstrap runs on the **first 500
paired reps** of each cell (B = 199), the M76 precedent for an infeasibly slow
incumbent (~5 s/dataset here).

### Cells (frozen)

R = raters, S = subjects, δ = σ²_r/σ²_e, ρ = true `ICC(A,1)`. Four distinct
(R,S) geometries; C2/C3 (near-zero boundary and few-subjects corner, GP6) are the
**decisive** cells.

| cell | R | S | δ | ρ | role |
|---|---|---|---|---|---|
| C1 | 3 | 20 | 1.0 | 0.60 | interior anchor (xiao-validated ρ region; sanity) |
| C2 | 3 | 20 | 1.0 | 0.05 | **near-zero-ρ boundary (σ²_s→0; GP6) — decisive** |
| C3 | 3 | 10 | 1.0 | 0.05 | **few-subjects × boundary corner (GP6) — worst case** |
| C4 | 3 | 50 | 4.0 | 0.60 | xiao2013's worst naive-PL geometry (the S↑ stress axis) |
| C5 | 5 | 20 | 1.0 | 0.75 | breadth (more raters, mid-high ρ) |

### κ_m recalibration (extended range; T2)

Per (R,S) geometry, `κ_m = max{ κ_corr(ρ, δ) : ρ ∈ [0.05, 0.9], δ ∈ {0.5…16} }`
via M86's `mpl_kappa_corr` (side = "two", **α = 0.05**), reported as κ_corr at the
grid **argmax corner** (M86's upward-bias correction: the MC grid-max over-estimates
a maximum). A grid scan locates the argmax (expected at the (ρ_min, δ_U) corner,
per M86 — but **verified**, not assumed, since the sub-0.6 region is unvalidated).

**Continuity anchor at the fence (AC2).** For the two geometries that overlap
M86's validated Table 3 set — **(3,10) and (3,50)** — κ_corr(ρ = 0.6, δ = 16)
recomputed at **α = 0.10** (M86's only published anchor is the 90% two-sided
table) must match M86's validated values (0.32, 0.67) within ±0.10. This proves
the extended-grid recalibration reproduces the published-region κ_m at the fence;
**below 0.6 there is no external oracle** (xiao2013), so continuity at the fence
is the check the calibration gets, and any near-zero κ_m the scan produces is
recorded as extrapolation of a validated machinery, never as an oracle-backed
constant.

### "Not worse" criterion (GP5 — fixed before results)

Nominal 95%. The candidate is **MPL (recalibrated κ_m)**. MC coverage is
**conditional on non-abort**; `n_ok` and the σ²_s→0 abort rate are recorded per
cell (AC4). MPL is **"not worse" at a cell** iff BOTH:

1. **Near nominal:** empirical coverage ≥ **0.93** (nominal 0.95 − 2 pp;
   under-coverage is the failure — over-coverage passes (1) but is penalized on
   width).
2. **Not below the incumbents:** MPL coverage ≥ (min of MC and parametric-bootstrap
   coverage at that cell) − **0.01** (≈ 2·SE paired slack). Where an incumbent
   **aborts** (returns no interval on a share of datasets), its conditional
   coverage still enters the min, and the abort share is carried into the verdict
   framing (an interval that *exists* where MC does not is MPL's boundary value —
   the M62/D-006 framing).

**Tiebreaker (width):** among methods clearing (1)+(2), prefer smaller **median
interval width**; a narrower interval that fails (1) or (2) does not win.

**Overall GO** iff MPL is "not worse" at **every** cell, with C2/C3 (boundary /
few-subjects) decisive. Otherwise **NO-GO**. Naive PL and the width comparison are
reported for context, not as the GO gate.

### Prior (not the verdict — GP5)

xiao2013 shows naive PL under-covers (Tables 4/7), worsening as S grows at R = 3;
MPL is deliberately **conservative** (coverage ≥ nominal, narrower than GV). The
open risk this pass exists to measure: the extended-range κ_m — a max that now
includes the near-zero corner where κ_corr is largest — may be **much larger** than
the published-region κ_m, making MPL over-cover and run **wide** at interior cells,
even as it becomes the only method that returns an interval at the boundary where
the MC default may abort. Expectation is therefore **mixed / plausibly NO-GO on
width** even if MPL never under-covers; the pass decides empirically (the evidence
decides, not the prior).

## Results (T3, 2026-07-23)

Source: `data-raw/m87-mpl-comparison-sweep.R` → `data-raw/m87-sweep-results.rds`
(n_rep = 1000 cheap methods; parametric bootstrap B = 199 on the first 500 paired
reps/cell; ~3.85 h). Recalibrated κ_m per cell (T2): C1/C2 = 0.676, C3 = 0.501,
C4 = 0.826, C5 = 0.340. `n_ok` = datasets on which the method returned an interval;
**MC coverage is conditional on `n_ok`** (the σ²_s→0 boundary abort,
`intraclass_singular_fit`). CR = empirical coverage; MW = median interval width.

| cell | (R,S,δ,ρ) | MPL CR / MW | naive PL CR / MW | MC CR / MW (abort) | pboot CR / MW |
|---|---|---|---|---|---|
| C1 | (3,20,1,.60) | **.990 / .685** | .947 / .516 | .978 / .552 (0) | .926 / .477 |
| C2 | (3,20,1,.05) | **.995 / .383** | .965 / .297 | .934 / .512 (**.259**) | .978 / .285 |
| C3 | (3,10,1,.05) | **.994 / .508** | .983 / .410 | .953 / .698 (**.312**) | .982 / .385 |
| C4 | (3,50,4,.60) | **.963 / .744** | .880 / .568 | .904 / .606 (0) | .800 / .502 |
| C5 | (5,20,1,.75) | **.981 / .462** | .959 / .382 | .963 / .378 (0) | .942 / .341 |

**Boundary abort — AC4 (the load-bearing finding).** The two-way random MC default
aborts (classed `intraclass_singular_fit`) on **25.9 %** of C2 and **31.2 %** of C3
near-zero-ρ datasets — the M62/RR01 one-way finding (28–39 % classed aborts)
**recurs in the two-way random design**. On the non-aborting remainder MC covers
0.934 / 0.953. MPL and naive PL return an interval on **100 %** of datasets (0
aborts), the closed deviance-root always existing.

**Criterion applied (candidate = MPL).** Not-worse at a cell iff coverage ≥ 0.93
AND ≥ min(incumbents) − 0.01:

| cell | MPL CR | ≥ 0.93? | min(MC,pboot) − .01 | ≥ incumbent? | not worse? |
|---|---|---|---|---|---|
| C1 | .990 | ✓ | .916 | ✓ | ✓ |
| C2 | .995 | ✓ | .924 | ✓ | ✓ |
| C3 | .994 | ✓ | .943 | ✓ | ✓ |
| C4 | .963 | ✓ | .790 | ✓ | ✓ |
| C5 | .981 | ✓ | .932 | ✓ | ✓ |

→ **MPL is "not worse" at every cell.** As in the M62 sibling, the frozen absolute
0.93 floor (not the incumbent-relative clause) is what carries the verdict and
keeps it non-circular: MPL is in fact the **only** method of the four clearing 0.93
at *all five* cells — MC fails C4 (0.904), the parametric bootstrap fails C1
(0.926) and C4 (0.800), and naive PL fails C4 (0.880).

**Three findings.**
1. **The boundary is where MPL earns its keep** (C2/C3, the pre-designated decisive
   cells). MPL covers 0.995 / 0.994 with **zero aborts** where the MC default gives
   *no interval* on 26–31 % of datasets, and does so at a median width **narrower**
   than MC's (0.383 vs 0.512; 0.508 vs 0.698) — because MC's width is conditional on
   the non-degenerate fits that survive, while MPL floors its lower bound at 0.
2. **The S↑ stress cell C4 breaks both package incumbents, not just naive PL.** At
   (3,50,δ4,ρ.60) — xiao2013's worst naive-PL geometry — naive PL under-covers
   (0.880, reproducing the published finding), *and so do both incumbents* (MC 0.904,
   parametric bootstrap 0.800). MPL (0.963) is the sole method ≥ 0.93. The recalibrated
   κ_m = 0.826 is doing exactly the job xiao2013's MPL was designed for.
3. **The cost is over-coverage and interior width.** MPL over-covers everywhere
   (0.963–0.995 vs nominal 0.95) — expected, since it is deliberately conservative
   (xiao2013 p. 2257) and the extended-range κ_m is ~40–80 % larger than the
   published-region value. At the interior cells C1/C4 it is the **widest** method
   (~24 % wider than MC). MPL is a conservative, boundary-robust interval, not a
   tight one.

**Extrapolation caveat (recorded, GP5).** Below ρ = 0.6 the κ_m used at C2/C3 has
**no external oracle** (xiao2013's ρ_L = 0.6 fence); it is an extrapolation of the
M86-validated machinery whose fence-continuity was checked (AC2), and the C2/C3
coverage above is measured against a *known simulated truth*, which is itself the
validation. No published cell corroborates the near-zero κ_m constant; the coverage
result does.

## Verdict (T4)

**GO** for MPL (extended-range κ_m) on the balanced two-way random `ICC(A,1)`.
Basis: the only method near-nominal (≥ 0.93) at every cell; boundary-robust where
the MC default aborts on a quarter-to-a-third of near-zero datasets; the sole
method clearing 0.93 at the S↑ stress cell C4 where all three alternatives
under-cover; machinery M86-oracle-validated against xiao2013 (IP1). Recorded as
**D-014**.

Framing carried into the decision (mirroring D-006). The GO does **not** claim MPL
should replace the MC default: it over-covers and runs ~24 % wider at interior
cells, so it is an **opt-in** option, not a default (parallel to the npbootstrap /
SEARLE / Burch one-way siblings, D-006/D-010/D-012/D-013). MPL's residual value is
(a) near-nominal coverage everywhere, including the S↑ regime where the package
incumbents themselves under-cover, and (b) an interval that *exists* at the
near-zero boundary where the MC default aborts. The exported-`ci_method` sibling is
cleared to be planned, with the conditions D-014 records (the sub-0.6 κ_m
extrapolation, per-geometry κ_m calibration cost, balanced-complete + Gaussian
scope).

## Traces to

- `cairn/references/xiao2013.md` — the primary source (method, Eqs. 1–13; the
  frozen Table 3/4/6/7 oracle values; the ρ_L = 0.6 fence).
- `cairn/estimand-specs/M1-twoway-random-agreement.md` — the package `ICC(A,1)`
  population definition the mapping above targets.
- `cairn/references/npbootstrap-oneway-comparison.md` — the M62 sibling pass
  (same GO/NO-GO shape; the one-way bootstrap analogue).
- `cairn/DECISIONS.md` D-006 (M62 gate split), and the M86/M87 milestone files.
- `cairn/references/BIBLIOGRAPHY.md` and `INDEX.md`.
