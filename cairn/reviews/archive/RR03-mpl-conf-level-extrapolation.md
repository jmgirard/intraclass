# RR03: Soundness of MPL κ_m extrapolation to conf_level 0.99 (α=0.01) and the sub-0.6 ρ region (M90)

- **Date:** 2026-07-24
- **Brief:** `cairn/reviews/RB03-mpl-conf-level-extrapolation.md`
- **Reviewer:** Fable (independent statistical review)
- **Materials read:** `cairn/references/xiao2013.md`, `data-raw/m86-mpl-lib.R`,
  `data-raw/m88-mpl-kappa-table.R`, `data-raw/m88-kappa-table.rds` (shipped-table
  nodes + argmaxes), `R/ci-mpl.R`, `cairn/references/mpl-twoway-random-comparison.md`,
  `cairn/DECISIONS.md` (D-014/D-015/D-016), `cairn/milestones/M90-mpl-conf-level-calibration.md`.

## Review evidence (fresh, seeded simulations)

All numerical claims below marked **[E]** come from simulations run for this
review with the committed reference library `data-raw/m86-mpl-lib.R` (unmodified),
seed 20260724, `RNGkind("L'Ecuyer-CMRG")`, n = 12,000 profile-deviance draws
`D(ρ_true)` per cell at five cells:

| cell | ρ | δ | R | S | role |
|---|---|---|---|---|---|
| A | 0.60 | 16 | 3 | 50 | xiao2013 oracle-anchor geometry |
| B | 0.05 | 16 | 3 | 50 | near-zero boundary, large S |
| C | 0.05 | 16 | 3 | 10 | near-zero boundary, few subjects |
| D | 0.05 | 16 | 2 | 10 | minimal geometry (largest shipped κ_m) |
| E | 0.60 | 0.5 | 10 | 100 | large geometry, κ→0 regime |

Sanity anchor: cell A gives κ_corr(α=0.10) = 0.658 against the published 0.67 —
inside the M86 ±0.10 tolerance, so the review harness reproduces the external
oracle before probing the tail. These are review evidence, not frozen reference
values (#4): where a number below binds M90, the binding criterion requires M90 to
re-derive it inside its own committed, seeded fixtures.

## Answers

### 1. Deep-tail validity of the MPL adjustment

**Yes, the true correction is shape-, not just scale-, dependent in the tail —
but the practical magnitude is small, and M90's design (recalibrating κ per α)
is exactly the right response to it.**

Theory first. For a smooth interior model, the profile-likelihood ratio is
Bartlett-correctable: the O(n⁻¹) error term of the deviance distribution is
proportional to the χ² density itself, so a *single* multiplicative constant
corrects all quantiles simultaneously to second order. If that held here, κ_corr
would be α-invariant. It does not hold exactly for these geometries, for two
reasons: (i) at R = 2–3 the higher-order (skewness-type) terms are not
negligible, so the deviance is not a scaled χ²₁ and the required scale factor
depends on which quantile you match; (ii) near the σ²_s→0 boundary the χ²₁
reference itself is the wrong shape, and the distortion is tail-dependent.

Measured magnitude **[E]** — κ_corr(α) per cell (empirical 1−α quantile of
12,000 draws over χ²₁ quantile, minus 1):

| cell | α=0.10 | α=0.05 | α=0.02 | α=0.01 | α=0.005 |
|---|---|---|---|---|---|
| A (interior) | 0.658 | 0.577 | 0.479 | 0.458 | 0.417 |
| B (ρ=.05, S=50) | 0.876 | 0.825 | 0.742 | 0.744 | 0.739 |
| C (ρ=.05, S=10) | 0.365 | 0.321 | 0.319 | 0.357 | 0.452 |
| D (ρ=.05, R=2) | 0.314 | 0.305 | 0.373 | 0.363 | 0.390 |
| E (large) | 0.051 | 0.050 | 0.048 | 0.046 | 0.026 |

Two regimes: at interior/large cells (A, E) the deviance tail is *lighter* than
its mid-tail scaling implies (κ_corr falls as α→0 — a mid-tail κ reused in the
deep tail errs conservative); at the near-zero, small-S cells (C, D) the deep
tail is *heavier* (κ_corr is non-monotone and rises again past α≈0.02, and keeps
rising at 0.005). So a single κ across α would be wrong in a cell-dependent
direction — but M90 never does that: it recalibrates κ_m *at* the 0.99 deviance
quantile. The only "extrapolation" is of the machinery, not of any constant.

Coverage-units bound on the shape effect **[E]**: deliberately reusing the
α=0.05-calibrated κ_corr with the χ²_{1,0.99} critical value gives coverage
0.9879–0.9929 across A–E (worst −1.2 pp of tail mass ≡ −0.21 pp of coverage, at
cell D). That is the worst case of *not* recalibrating; the recalibrated
per-cell constant is exact by construction up to MC error, and the grid-max
κ_m ≥ κ_corr adds conservatism on top. Conclusion: the parameterization does not
break at α=0.01; what degrades is the *MC estimability* of the calibration
target (question 2). The rising trend at α=0.005 in cells C/D is a warning
against ever going deeper than 0.99 without revisiting this analysis, not
against 0.99 itself.

### 2. MC estimation of a 0.99 tail quantile

**(a) Sizes and bias-correction.** Bootstrap resampling of the review samples to
n_mc = 6000 **[E]** gives SE(κ̂_corr):

| cell | SE at α=0.05 | SE at α=0.01 |
|---|---|---|
| A | 0.028 | 0.042 |
| B | 0.036 | 0.064 |
| C | 0.030 | 0.065 |
| D | 0.037 | 0.043 |
| E | 0.024 | 0.038 |

So at M88's n_mc_final = 6000 the α=0.01 calibration is ~1.5–2.2× noisier in κ
units than the shipped α=0.05 table. In *coverage* units the ±1 SE band on the
calibrated critical value moves coverage by ±0.11–0.16 pp at 0.99 — i.e. 11–15 %
of the 1 % tail mass, versus 5–6 % of the 5 % tail mass at α=0.05 **[E]**. The
noise is tolerable in absolute terms but roughly 2.5× worse in relative-tail
terms, and it feeds two places: the exported table's node values (the shipped
α=0.05 table already shows MC wiggles of ~±0.05, e.g. non-monotone κ_m(S) at
R ≥ 8 in `data-raw/m88-kappa-table.rds`) and the winner's-curse selection. At
α=0.01 with the M88 sizes unchanged, the scan (n_mc = 1500, SE ≈ 0.08–0.13)
would select the top-3 less reliably and the final max-of-3 at 6000 would carry
an upward bias of up to ~+0.05 when candidates are near-tied (conservative
direction, but it degrades the table's meaning as a per-geometry constant).

Recommendation: for α=0.01, **n_mc_scan ≥ 3000, top_k ≥ 5, n_mc_final ≥ 12000**.
At 12000 the SE halves to ≈ 0.02–0.033 — at or below the α=0.05 table's own
noise — and top-5 protects the argmax location against the noisier scan. The
grid-max structure degrades gracefully (when the surface is flat enough for the
scan to mis-rank cells, the near-ties make the mis-ranking immaterial), so
top-5 at 12000 is sufficient; more than that buys little. Compute cost per
geometry ≈ 60×3000 + 5×12000 = 240k fits vs M88's 108k — about 2.2× the M88 job
(~5 h background), consistent with the milestone's own "larger n_mc at α=0.01"
plan. α=0.10 may keep the M88 sizes (1500/3/6000): its quantile is *easier*
than the shipped 0.05 one.

**(b) Empirical quantile vs tail model.** Keep the raw empirical 0.99 quantile
as the estimator. At n_mc = 12000 it rests on ~120 tail exceedances — noisy but
unbiased to first order, and assumption-free. A modeled tail (GPD fit, or a
scaled-χ² fit to the upper deviance CDF) would reduce variance only by
importing a shape assumption that question 1's evidence directly undermines in
the region that dominates the grid max: cells C/D show the deep tail is *not*
scaled-χ²-shaped (κ_corr rising past α=0.02), and a χ²-scale fit anchored on
the mid-tail would bias κ̂ low there — the anti-conservative direction. A tail
model is acceptable as a *diagnostic cross-check* (e.g. report the fitted-tail
κ alongside the empirical one at the argmax cell), not as the estimator.

### 3. Coverage-only validation adequacy

**Adequate as the primary gate; not sufficient alone. Three specific things can
be wrong while coverage lands at nominal, all observed in this review, and all
closable with cheap recorded diagnostics.**

The M86 doctrine (validate a calibration constant by the interval it builds
covering at nominal) is the right primary criterion — κ_m has no meaning apart
from the coverage it delivers, and reproducing the constant itself is
impossible without an external table. But the sweep as currently framed would
not see:

1. **Systematic mis-location.** The two-sided MPL interval's misses are almost
   entirely one-sided **[E]**: at cell A, α=0.05 (the *shipped* level), the
   miss split is 4.86 % (true ρ below the interval) vs 0.14 % (above); at
   α=0.01 it is 0.97 % vs 0.03 %. Only the large geometry E approaches balance
   (3.2/1.8). Total coverage is exactly as advertised while the interval
   behaves nothing like an equal-tailed one. This is inherent to folded-deviance
   calibration (it controls the total miss, not its split) and xiao2013 never
   claims equal-tailedness, so it is a documentation/diagnostic matter, not a
   defect — but a sweep that records only total coverage would certify a 99 %
   interval whose 1 % risk is ~100 % concentrated on one side, which a user
   reading "99 % CI" may not expect.
2. **Near-vacuous width.** At small geometries the 0.99 interval is technically
   valid and nearly uninformative **[E]**: at (R=2, S=10, ρ=0.6, δ=1, κ≈0.85)
   the median width is 0.95, with the lower endpoint clamped to 0 on 85 % of
   datasets (coverage 1.000). Fully vacuous [0,1] intervals do not occur (the
   deviance diverges as ρ→1, so the upper root exists), but "coverage ≥ c−0.02"
   is trivially satisfiable by width. This needs to be *recorded and surfaced*,
   not gated — a 99 % interval from 20 observations should be huge — but M91's
   documentation must say so.
3. **Table-level noise artifacts.** Non-monotone κ_m(S) wiggles (already ±0.05
   at α=0.05 for R ≥ 8) interact with the runtime's linear-in-S interpolation;
   coverage at the swept nodes cannot see an interpolated-κ undershoot between
   nodes. Bounding the node noise (question 2's n_mc floor) is the fix; a
   monotonicity check against 2×SE is a cheap recorded diagnostic.

Required additions (binding, BC6): per-cell miss-below/miss-above counts, median
and 90th-percentile width, endpoint clamp rates P(lower = 0) and
P(upper ≥ 0.999), and the vacuous fraction. All are free by-products of the
sweep loop. None should gate GO/NO-GO except through the documentation duty.

### 4. Sub-0.6 ρ / near-zero boundary

**No disqualifying failure mode; two real, quantified effects — grid-max
domination by the near-zero corner (already true at 0.95, slightly stronger at
0.99) and larger calibration noise exactly there.**

Mechanics: ρ_true = 0.05 is an interior point, not the boundary. The deviance
D(ρ_true) stays continuous and well-defined; the MLE pile-up at ρ̂ ≈ 0 exists
(P(ρ̂ < 10⁻⁴) = 2.5 % at C, 7.4 % at D, 0 % at S = 50 **[E]**) but does not put
an atom into D at the true ρ, and the fold absorbs it: the calibration machinery
has no structural blind spot at ρ = 0.05 that the ρ ≥ 0.6 oracle "hides". What
the ρ ≥ 0.6 oracle genuinely does not exercise:

- **The grid max is a near-zero constant.** In the shipped α=0.05 table, 47/54
  geometry argmaxes sit at ρ ≤ 0.2 and 49/54 at δ ≥ 8 (`m88-kappa-table.rds`).
  The exported κ_m is thus effectively calibrated *by* the near-zero corner and
  applied everywhere — which is why interior cells over-cover (M87: 0.963–0.995)
  and run wide. At α=0.01 this sharpens slightly: interior κ_corr falls with
  deeper α while the S=50 near-zero cell stays high (B: 0.744 vs A: 0.458
  **[E]**), so the max diverges further from interior needs → *more* interior
  over-coverage and width at 0.99, no under-coverage mechanism. Direction is
  safe; cost is width, which BC6 makes visible.
- **The near-zero cells are the noisiest to calibrate** (SE 0.064–0.065 at
  α=0.01, n_mc = 6000 — the largest in the table above), and the same cells
  dominate the max. This is the α=0.10 vs α=0.01 difference the question asks
  about: at α=0.10 the boundary cells' quantile is estimated ~1.7× more
  precisely and their κ_corr is more moderate; at α=0.01 the unstable-cell-
  dominates-the-max concern is real and is precisely what BC2's n_mc floor
  addresses. The deep-tail heavying at small S (C: 0.357→0.452 from α=0.01 to
  0.005) also means the near-zero regime is the first place a deeper-than-0.99
  level would break; at 0.99 it is measurable and controlled.
- **One genuine gap:** the calibration grid's own floor, ρ_L = 0.05, is a fence
  of the same kind as xiao2013's 0.6 fence. The exported method cannot fence on
  true ρ (unknowable), and no sweep cell has ever probed ρ_true < 0.05. The
  max-over-grid *should* transfer (κ_corr's growth toward small ρ is what the
  corner cell captures), but "should" is the word this package's principles
  exist to delete: add one sub-grid-floor coverage cell (ρ_true = 0.02) to the
  sweep at both levels (BC5). Note this exposure exists for the shipped 0.95
  level too — see Beyond the brief.

### 5. Criterion sufficiency

**Sound in shape, insufficient in two particulars: the additive −2 pp floor is
scale-inappropriate at c = 0.99, and the cell set misses the two stress axes
the new levels actually add.**

- **The floor.** "Coverage ≥ c − 0.02" allows non-coverage of 3× nominal at
  c = 0.99 (0.03 vs α = 0.01) — proportionally far laxer than the same band at
  0.95 (1.4×) or 0.90 (1.2×). A method that failed its defining property by a
  factor of 3 would still pass; at that point the sweep is a rubber stamp.
  Require **coverage ≥ 0.98 at c = 0.99** (non-coverage ≤ 2α — the same
  order of laxity as the incumbent floors) and keep 0.88 at c = 0.90. Since
  MPL's grid-max construction makes it genuinely conservative (M87 observed
  0.963–0.995 against 0.95; the reuse experiment above never dropped below
  0.988 even with a deliberately wrong constant), a correctly calibrated 0.99
  MPL will clear 0.98 comfortably; the tighter floor only bites if something is
  actually broken. Over-coverage passing is correct (it is the method's
  documented character, D-014) provided BC6 surfaces the width cost.
- **n_rep.** At c = 0.99 with n_rep = 1000 the sweep expects 10 misses per
  cell; a truly-0.975 (broken) method passes a 0.98 floor ~15 % of the time.
  Require **n_rep ≥ 2000 at 0.99** (MC-SE ≈ 0.0031 at the floor; false-pass of
  a 0.975 method ≈ 8 %, of a 0.97 method ≈ 2 %; a true-0.99 method fails with
  probability < 0.1 %). n_rep ≥ 1000 remains adequate at 0.90. Report exact
  Clopper–Pearson 95 % CIs per cell so the verdict note carries the MC
  uncertainty rather than a bare point.
- **Cells.** C1–C5 span R ∈ {3,5}, S ∈ {10,20,50} — but the shipped grid goes
  to R = 2 (the largest κ_m, 1.47–1.62 at α=0.05, and the near-vacuity regime)
  and S = 100 (the far end of the S↑ axis on which naive PL *worsens*, xiao2013
  §4 — the documented failure direction). Neither extreme is exercised. Add
  two decisive cells: **(R=3, S=100, δ=4, ρ=0.60)** (the S-axis grid edge,
  extending C4's known stress direction) and **(R=2, S=15, δ=1, ρ=0.05)**
  (minimal-information × boundary, the geometry whose κ_m is largest), plus the
  sub-grid-floor cell **(R=3, S=20, δ=1, ρ=0.02)** from question 4. Three extra
  cells ≈ 60 % more sweep compute; still a background job.
- MPL-only (no incumbent re-comparison) is right — D-014 settled the
  method-level comparison, and re-running incumbents at 0.99 would answer a
  question nobody is asking.

### 6. Go / no-go on 0.99

**Conditional GO: 0.99 is exportable on simulated-coverage evidence alone,
under the binding criteria below. Do not hold it back categorically; do let
0.90 proceed on its own (stronger) footing regardless of 0.99's outcome.**

Reasoning. The D-014(i) posture — an extrapolated κ_m may be established by its
defining coverage property where no oracle exists — survives examination for
α=0.01 because the extrapolation is *thinner than the brief's framing
suggests*: nothing numeric is extrapolated in α. The machinery re-runs the same
Bartlett-type MC calibration at a different quantile; the α-specific
ingredients are (a) the χ² critical value (exact), and (b) an empirical tail
quantile of a simulated distribution (noisier, but quantifiably so — question
2 — and controllable with n_mc). The two structural risks that could have made
0.99 different in kind, not degree — shape-dependence of the correction
(question 1) and a boundary failure mode invisible above ρ=0.6 (question 4) —
both measure out as bounded, conservative-direction effects for this machinery.
What remains is exactly what the 0.95 precedent already accepted, plus a
deeper-tail MC-noise burden, and the review can price that burden precisely.

Three things distinguish an adequately validated 0.99 from a rubber-stamped
one, and they are the export conditions: (1) the α-parametrized pipeline must
first re-earn the *published* oracle at α=0.10 — a same-code external check
that the parametrization change itself is right (this is 0.90's oracle doing
double duty for 0.99's machinery); (2) the calibration MC must be sized for
the 0.99 tail (BC2), not inherited from the 0.05 tuning; (3) the coverage
validation must be a real test — scale-appropriate floor, adequate n_rep, the
stress cells the new level actually adds, and the diagnostics that catch
nominal-coverage-wrong-interval failure modes (BC3–BC6). If any of those
fails, 0.99 goes to a candidate row and 0.90 ships alone; there is no
coupling in the other direction.

One boundary on the claim: this clears conf_level 0.99 specifically. The
κ_corr trend below α=0.01 (cells C/D rising at 0.005) means nothing here
authorizes deeper levels (0.995, 0.999) by analogy; each would need its own
review of tail estimability, and the practical answer may differ.

## Beyond the brief

- **AC1's oracle geometries are off the shipped S grid.** xiao2013's published
  two-sided κ_m sextet is at (R,S) ∈ {3,5} × {10, **25**, 50}; the shipped
  `s_grid` is {10,15,20,30,50,100} — S = 25 is not a node. The AC1 reproduction
  must evaluate S = 25 explicitly (a six-geometry oracle run, not a subset of
  the production grid run). Folded into BC1.
- **The runtime interpolation comment is already falsified at R ≥ 8.**
  `R/ci-mpl.R` (κ_m lookup, ~lines 195–203) justifies linear-in-S interpolation
  by "kappa_m(S) is increasing and roughly concave"; the shipped table is
  non-monotone in S at R ≥ 8 (e.g. R=9: 0.172 at S=20 → 0.140 at S=30; R=10:
  0.157 → 0.102 → 0.087 → 0.186) — MC noise of ~±0.05, harmless in coverage
  terms (the values are small and the method conservative) but the comment's
  premise is wrong as stated. Worth softening when M91 touches the file; the
  new tables should reduce the wiggles via BC2's n_mc floor.
- **The miss-side asymmetry characterizes the shipped 0.95 level too** (cell A,
  α=0.05: 97 % of misses on one side **[E]**). Nothing in the exported
  documentation currently says the two-sided MPL interval is far from
  equal-tailed. A one-line documentation note (`@param ci_method` detail or the
  reference note) would close the gap for all levels at once.
- **The ρ_L = 0.05 calibration-grid fence also applies to 0.95.** The
  sub-grid-floor sweep cell (BC5's C8) has never been run at the shipped level;
  if M90's C8 passes at 0.90/0.99 the result substantially de-risks 0.95 by
  analogy, but a cheap 0.95 backfill cell in some later maintenance sweep would
  make the posture uniform (consider; not part of M90).
- **Review-evidence provenance.** The [E] numbers come from two scratchpad
  scripts (deviance sampling at cells A–E, n=12,000, seed 20260724,
  L'Ecuyer-CMRG; and a 400-dataset width check) using `m86-mpl-lib.R`
  unmodified. They are review evidence for this RR's judgments, not frozen
  reference values; every number that binds M90 is re-derived inside M90's own
  committed fixtures by the BCs below.

## Recommendations

1. **Apply** — Recalibrate κ_m per α (as planned); never reuse or interpolate a
   κ across α (question 1's shape evidence).
2. **Apply** — α=0.01 calibration sizes: scan ≥ 3000, top-k ≥ 5, final ≥ 12000
   (BC2). Keep M88 sizes at α=0.10.
3. **Apply** — Keep the raw empirical 0.99 quantile as the κ_corr estimator;
   **reject** tail-model estimation (GPD / scaled-χ² fit) as the primary
   estimator — the deep tail is demonstrably non-χ²-shaped exactly where the
   grid max lives, and model bias there points anti-conservative. Acceptable as
   a reported diagnostic only.
4. **Apply** — Tighten the 0.99 floor to 0.98 (non-coverage ≤ 2α) and raise the
   0.99 sweep to n_rep ≥ 2000 with exact binomial CIs (BC3, BC4).
5. **Apply** — Add the three sweep cells: (3,100,δ4,ρ.60), (2,15,δ1,ρ.05),
   (3,20,δ1,ρ.02) — decisive at both levels (BC5).
6. **Apply** — Record per-side misses, width quantiles, clamp rates, vacuous
   fraction in the sweep fixture; surface the small-geometry near-vacuity in
   M91's documentation (BC6).
7. **Apply** — Run the six-geometry (incl. S=25) α=0.10 published-κ_m oracle
   reproduction before any α=0.01 production run (BC1).
8. **Consider** — Document the two-sided interval's non-equal-tailed character
   (applies to the shipped 0.95 as well).
9. **Consider** — A later 0.95 backfill of the sub-grid-floor coverage cell,
   for posture uniformity across levels.
10. **Reject** — Holding 0.99 back categorically while 0.90 proceeds: the
    review found no failure mode different in kind from what the shipped 0.95
    already carries, and the BCs price the difference in degree. (Reject-reason:
    the extrapolation is of machinery, not of any constant; its two structural
    risks measured out bounded and conservative-direction.)
11. **Reject** — Extending the same authorization to levels deeper than 0.99
    (0.995, 0.999) by analogy: κ_corr is still rising at α=0.005 in the
    boundary cells; each deeper level needs its own tail-estimability review.

## Binding criteria

- **BC1 (α-parametrization oracle, precondition).** Before any α=0.01
  production calibration, the α-parametrized pipeline, run at α=0.10 two-sided
  over ρ ∈ [0.6, 0.9] × δ = 2^(−1..4) with n_mc ≥ 6000, reproduces all six
  published two-sided κ_m values — 0.32, 0.52, 0.67 at (R=3, S=10/25/50) and
  0.13, 0.23, 0.33 at (R=5, S=10/25/50) — each within ±0.10 (the M86
  tolerance). S = 25 is evaluated explicitly (it is off the shipped `s_grid`).
- **BC2 (α=0.01 calibration MC sizes).** The α=0.01 table generator uses
  n_mc_scan ≥ 3000, top_k ≥ 5, n_mc_final ≥ 12000. The fixture records, for at
  least one representative geometry per R ∈ {2, 3, 10}, a bootstrap SE of the
  final κ̂_m (resampling the final-cell deviance sample); each recorded SE
  ≤ 0.05. The α=0.10 generator may retain M88's sizes (1500/3/6000).
- **BC3 (coverage floors).** Per-cell pass floor: empirical coverage ≥ 0.88 at
  conf_level 0.90; ≥ **0.98** at conf_level 0.99 (supersedes the proposed
  c − 0.02 = 0.97). Over-coverage passes at both levels.
- **BC4 (sweep replication).** n_rep ≥ 2000 per cell at 0.99 (coverage MC-SE at
  the 0.98 floor ≤ 0.0032); n_rep ≥ 1000 per cell at 0.90. The verdict fixture
  reports an exact (Clopper–Pearson) 95 % CI for coverage at every cell.
- **BC5 (cell set).** The decisive set at each level is M87's C1–C5 **plus**
  C6 = (R=3, S=100, δ=4, ρ=0.60), C7 = (R=2, S=15, δ=1, ρ=0.05), and
  C8 = (R=3, S=20, δ=1, ρ=0.02). All eight are decisive: the floor (BC3) must
  hold at every one.
- **BC6 (diagnostics recorded).** The sweep fixture records per cell:
  miss-below and miss-above counts; median and 90th-percentile interval width;
  P(lower endpoint = 0); P(upper endpoint ≥ 0.999); vacuous fraction (both
  clamps simultaneously). These do not gate the verdict, except: the M91
  documentation (or the references note if 0.99 is NO-GO) must state the
  small-geometry width finding wherever a decisive cell's median 0.99-interval
  width ≥ 0.90.
- **BC7 (export gating).** M91 may export conf_level 0.99 only if BC1–BC6 all
  pass at that level; conf_level 0.90 gates only on BC1 and on BC3–BC6 at its
  own level. A BC failure at one level routes that level to a candidate row
  (NO-GO) without blocking the other. No level deeper than 0.99 is authorized
  by this review.
