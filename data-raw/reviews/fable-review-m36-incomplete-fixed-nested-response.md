# Fable review response — INCOMPLETE/ragged fixed-rater nested θ²_{r:c} (M36, ADR-046)

**Reviewer:** Claude Fable 5 (gated statistical review, PRINCIPLE #19, maintainer-requested post-hoc),
2026-07-11.
**Brief:** `fable-review-m36-incomplete-fixed-nested-brief.md` (same directory).
**Verification scripts (this review's, seeded, committed):**
- `fable-check-m36.R` — the brief's starter harness, extended: the Q2 **cluster-count sweep** through the
  shipped `icc()` path at n_rep = 500 (double the ≥ 240 verdict bar), four regimes × C_n ∈ {5, 20, 80} ×
  {boundary, interior}, with one-sided miss split, point bias, width, and point-in-own-CI containment.
  Results: `fable-check-m36-results.rds`.
- `fable-check-m36-identities.R` — the Q1 **derivation check** (both identities on a frozen ragged design,
  engine `vcov` vs exact GLS vs empirical sampling covariance vs the no-leakage naive form) and the Q4
  **certification-power check** (0b/1b/2b points through the same fits vs the oracle's |bias| < .03 pin).
  Results: `fable-check-m36-identities-results.rds`.

---

## 0. Verdict

**The shipped M36 construction is sound; no corrective follow-up milestone is needed.** The 2b +
average-floor interval survives the ragged generalization — not by luck, but because the M28 derivation
never actually depended on the balanced closed form (§1). The cluster-count sweep Opus should have run
(Q2 — the brief is right to call this the honest gap) comes back **flat in C_n**: boundary coverage at
C_n = 80 is .968/.962/.951/.963 across the four regimes (minimum anywhere on the 24-cell grid: .942,
within one MC SE of nominal at n_rep = 500), misses two-sided, containment 1.000 — the M28 *post*-fix
signature, nowhere near the pre-fix collapse (.95/.86/.57). Three findings short of a clean
bill, none a shipped-correctness bug:

1. **(Q2) The evidence gap was real even though the result is favorable.** A ~6-cluster grid cannot
   detect an incidental-parameters decay by construction; the .942 Opus cited did not support the "no
   Fable needed" call on its own. The call happened to be right. Recommend one C_n = 80 boundary cell in
   O-IFNML at the next regeneration (~75 s of compute) as a permanent sentinel for this pathology class (§3).
2. **(Q3) The pooled harmonic k_eff is exactly right under homogeneous per-cluster rater variance — and
   that identity should be recorded** (one-line algebra, §4): pooled harmonic k_eff ≡ per-subject
   error-variance averaging, so the multi-cluster average is coherent, not merely single-cluster-pinned.
   What it drops under *heterogeneous* θ²_c is the covariance term Cov_s(θ²_{c(s)}, 1/m_s) — a real but
   definitional, second-order slippage (~.03 ICC under stark heterogeneity). One documenting sentence in
   the spec; no code change; do **not** move to per-cluster divisors (§4).
3. **(Q4) The recovery oracle certifies that a ≈ b-sized correction is present, but cannot see its exact
   size at n_s = 8:** 0b breaches the .03 bias pin only through the boundary cells (−.051); a 2b
   over-correction sits inside the pin (±.016) and only becomes visible at n_s = 4 (+.037). The
   non-circularity reasoning itself is valid. Recommend either one low-information (n_s ≈ 4) interior cell
   in O-IFNML or an honest sentence in the oracle header scoping what the pin certifies (§5).

---

## 1. Q1 — the 2b construction survives raggedness because it never used the balanced closed form

Fix a cluster c; the draws for the whole parameter vector are N(estimate, vcov(fit, full = TRUE))
(`rmvn()` in ci-montecarlo.R), and b_c = tr(C_c V̂_c)/(k_c − 1) with V̂_c the `vcov(fit)$cond` block. The
M28 derivation rests on two identities, and **neither is a balanced-data fact — both are Gaussian
quadratic-form facts, E[xᵀCx] = μᵀCμ + tr(CV), valid for arbitrary covariance V:**

1. **Push-forward (exact conditional on the data, any V̂):** E_draw[q_c(β*)] = q_c(β̂_c) +
   tr(C_c V̂_c)/(k_c − 1). This is exact *by construction of the draws* — raggedness cannot break it. Its
   one premise is that the β block of the full draw covariance is the same matrix that b_c is read from;
   verified: max |vcov(full)[β,β] − vcov()$cond| = **0.00e+00**, and on a fitted ragged design 200k draws
   reproduce E_draw[q_c] − q_c(β̂_c) = b̂_c to draw noise (max dev 9.3e-4).
2. **Plug-in bias (sampling, any V):** E_samp[q_c(β̂_c)] = q_c(μ_c) + tr(C_c V_c^true)/(k_c − 1), exact
   for the Gaussian, unbiased β̂ — and REML/EGLS β̂ is exactly unbiased (Kackar–Harville: plugging in any
   even, translation-invariant variance estimator, which REML is, preserves E[β̂] = μ). Verified on a frozen ragged design (mixed k_c ∈ {2..5},
   n_s = 6, 25% missing; 1000 refits): measured inflation E[q_c(β̂)] − q_c(μ_c) matches tr(C_c V_c)/(k_c−1)
   at the exact known-σ² GLS covariance within MC error (max |dev| = .0145, MC SE ≈ .016).

What the balanced closed form (b = σ²_res/n_s; C annihilates the J block) ever did in M28 was make these
traces *analytically evaluable*. On ragged data the closed form is genuinely dead — the brief's
"subject-mean leakage" is real and measurable: the naive no-leakage analog tr(C_c diag(σ²_res/n_rc))/(k_c−1)
is off by up to **12.3%** on the test design. But the shipped code never computes the closed form: b_c is
read from the engine's V̂, which carries the leakage. Measured four ways per cluster (b from exact GLS at
true σ², from the empirical covariance of 1000 fitted β̂, from the engine's V̂ averaged over fits, and the
naive diagonal), the first three agree to the third decimal; only the naive form deviates.

**So "are the two inflations still equal?" — they are equal up to V̂ vs V^true, exactly as on balanced
data** (the balanced engine V̂ was also a σ̂²-plug-in, not the known-σ² closed form). The residual
interval-center displacement is mean_c(b̂_c − b_c^true): measured **+0.0006 against a mean b of 0.117**
(0.5% of b, ≪ any interval width). Two structural facts bound it as C_n grows:

- σ²_{s:c} and σ²_res are **global** components, pooled across clusters — so V̂_c's error per cluster
  shrinks as *total* information grows even with per-cluster size fixed. The displacement is o(1) while
  width shrinks as C_n^{−1/2}: the M28 collapse mechanism (an O(1) systematic displacement per cluster
  meeting a shrinking interval) has no analog here. M28's pre-fix failure was a *constant* b never
  subtracted; the post-fix ragged residual is an *estimation error in* b that vanishes.
- The fit is **REML** (`fit_glmmtmb_ml_model()`, REML = TRUE — load-bearing and verified): the number of
  fixed effects grows ∝ C_n, so an ML fit would carry a non-vanishing Neyman–Scott relative bias in
  σ̂²_res that would feed every b̂_c systematically — the one channel that *could* have rebuilt an
  incidental-parameters displacement. REML closes it.

**Q1 verdict: the 2b construction is exact in its conditional identity and consistent in its sampling
identity under ragged, unequal-k V̂_c; no corrected inflation term is needed.** The honest caveat for the
spec: on ragged data b_c is a plug-in *estimate* whose error enters the center — second-order, measured
negligible, vanishing in C_n — rather than the balanced case's exactly-evaluable trace.

## 2. Q2 — the cluster-count sweep: no decay; the M28 pathology does not reappear

Sweep through the shipped `icc()` path (n_rep = 500 per cell, mc_samples = 3000, per-rep seeds; coverage
of the fixed population ICC_s(A,1); raters fixed across reps, subjects/residuals/missingness resampled).
Four regimes: **A** equal k_c = 4, n_s = 4, p_keep = .8 (the preliminary sweep's regime); **B** mixed
k_c ∈ {2,3,4,5} incl. k_c = 2 clusters, n_s = 4, p = .8; **C** equal k_c = 4 under heavy missingness
(p = .65, rater sets erode → k_c becomes ragged endogenously); **D** mixed k_c with n_s = 3 (the strongest
incidental-parameters stress, b ≈ 0.2; some reps abort by design when a k_c = 2 cluster loses a rater —
counted, reported).

95% coverage of the fixed population ICC_s(A,1) (MC SE ≈ .010 at nominal; n_rep = 500 per cell):

| regime | boundary C_n=5 | C_n=20 | C_n=80 | interior C_n=5 | C_n=20 | C_n=80 |
|---|---|---|---|---|---|---|
| A equal-k4, n_s=4, p=.8 | .976 | .978 | **.968** | .978 | .960 | .970 |
| B mixed-k {2..5}, n_s=4, p=.8 | .990 | .942 | **.962** | .976 | .954 | .970 |
| C equal-k4, n_s=4, p=.65 | .992 | .972 | **.951** | .984 | .970 | .964 |
| D mixed-k {2..5}, n_s=3, p=.8 | .990 | .982 | **.963** | .992 | .966 | .976 |

Interval widths shrink as expected (regime A boundary: .462/.242/.122 at C_n = 5/20/80), so the M28
mechanism — a fixed displacement meeting a shrinking interval — had every opportunity to express itself;
it does not. The one cell below .95, B's C_n = 20 boundary .942, is within one MC SE and is bracketed by
.990 (C_n = 5) and .962 (C_n = 80) — noise, not the onset of a decay (#18). Honest accounting of
discarded fits: regime C at C_n = 80 aborts 115/500 reps (heavy missingness erodes some cluster's rater
set below the ≥ 2-raters guard as clusters accrue — the classed refusal working as designed, #5), so its
coverage is conditional on accepted designs; regimes A/B ≤ 5 failures, D ≤ 9.

**Q2 verdict: boundary coverage holds to C_n = 80 in every regime** — mildly conservative at low C_n
(the average-floor's documented boundary-aware direction, as in M28 post-fix), settling toward nominal as
clusters accrue, misses two-sided throughout, containment 1.000 everywhere (the M28 §3 point-outside-own-CI
pathology is absent under the average-floored point). Point bias shrinks with C_n (regime A boundary:
−.049/−.017/−.006). This is the M28 *post*-fix signature; the pre-fix signature (.95 → .86 → .57) appears
nowhere. §1 explains why structurally.

**The honest-gap finding stands regardless.** The brief is correct that Opus's ~6-cluster O-IFNML grid was
not positioned to detect this failure mode: M28's own pre-fix interval covered .95 at C_n = 5. The .942
Opus cited was evidence of low-C_n health only; the "no Fable review needed" conclusion did not follow from
it. It happened to be true — the construction is sound (§1) — but process-wise (#18), a coverage claim for
an interval whose known failure mode is cluster-count decay needs a cluster-count axis. See §3.

## 3. Recommendation: a C_n sentinel cell in O-IFNML

At 0.31 s per C_n = 80 fit, one boundary cell (equal-k4, n_s = 4, C_n = 80, n_rep = 240) costs ~75 s in
the oracle regeneration. Recommend adding it (with a pre-registered ≥ .90 pin, [[ragged-coverage-nrep-240]])
at the **next** O-IFNML regeneration — a permanent regression sentinel for the incidental-parameters class
M27/M28 established, guarding every future touch of `theta2r_nested_draws()` / the shared moment helper.
This is a test-asset amendment, not a code fix; the current fixture stays valid (nothing it asserts is
wrong — it just asserts less than it appeared to).

## 4. Q3 — the pooled harmonic k_eff is coherent, and here is the missing multi-cluster argument

The averaged coefficient divides the *cross-cluster mean* θ̄² ≡ θ²_{r:c} by the *pooled* per-subject
harmonic mean k_eff = (mean_s 1/m_s)^{−1} (m_s = ratings on subject s). The brief asks whether that is
coherent for a fixed per-cluster population under cross-cluster imbalance, given only a single-cluster
reduction as evidence. Two parts:

**(a) The identity Opus could have cited (multi-cluster, exact).** The natural multi-cluster target for an
"average-unit reliability" summary is the **mean per-subject error variance of the averaged score**,
err ≡ mean_s[(θ²_{c(s)} + σ²_res)/m_s] (each subject's own cluster's rater variance, own rating count;
the (θ² + σ²)/m form is the M3/M&W Case-3A averaging convention M36 inherits, not something new). When the
per-cluster variances are homogeneous, θ²_c ≡ θ̄²:

    err = (θ̄² + σ²_res) · mean_s(1/m_s) = (θ̄² + σ²_res)/k_eff   — exactly the shipped denominator.

The pooled harmonic mean is not a convenient approximation here; **harmonic pooling of rating counts IS
per-subject error-variance averaging**. So under homogeneity — which includes every equal-θ²_c DGP, and is
the regime the single summary θ̄² is fit to describe — the shipped ICC_s(A, k_eff) is exactly the coherent
cross-cluster mixture, "systematically different rating counts across clusters" and all. This closes the
gap between the single-cluster reduction and the multi-cluster claim; recommend recording it in the spec
(§2) — it is one line of algebra and turns "rides the single-cluster reduction" into a derivation.

**(b) What it drops under heterogeneous θ²_c.** Generally
err = θ̄²·mean(1/m_s) + **Cov_s(θ²_{c(s)}, 1/m_s)** + σ²_res·mean(1/m_s); the shipped form omits the
covariance term. It is zero when θ²_c is constant, or when rating counts are exchangeable across clusters;
it bites when noisy rater sets co-occur with thin rating counts. Magnitude under deliberately stark
heterogeneity (σ²_{s:c} = 1, σ²_res = .5; half the subjects in a θ²_c = .9, m_s = 2 cluster, half in a
θ²_c = .1, m_s = 5 cluster): shipped .741 vs subject-averaged .709 — **~.03 of ICC at the extreme**. This
is a *definitional* choice about which single summary to report, not an estimation bug, and the
random-nested path cannot even express it (its model has one σ²_{r:c} by assumption); the fixed
finite-population estimand is simply the first place per-cluster heterogeneity is representable.

**Q3 verdict: defensible as shipped; keep it.** Recommend one documenting sentence in
`M36-incomplete-fixed-nested.md` §2 stating (a) and (b). Do **not** re-derive toward per-cluster or
weighted divisors: a mean_s[(θ̂²_{c(s)} + σ̂²)/m_s] plug-in would inject the per-cluster θ̂²_c — the
noisiest quantities in the model, (k_c − 1)-df each and individually unfloorable — into the headline
average; the pooled form deliberately routes only the well-pinned cross-cluster mean into the coefficient.
Restriction to single-rater is not warranted.

## 5. Q4 — the recovery oracle's logic is valid; its certification power is partial and should be scoped honestly

**The non-circularity argument holds.** θ²_{r:c} is a deterministic functional of the fixed rater means
held fixed across replications; the DGP's truth is set before the estimator exists; nothing in the
estimator is tuned to it (#4). And the brief's suspicion about cross-engine is *already conceded in the
shipped spec* (§1: "cross-engine pins the extraction, not the correction") — correctly.

**But "recovers the truth at low bias" certifies the correction only as far as the pin can see.** Measured
(500 fits/cell, the oracle's own regimes, 0b/1b/2b points computed from the *same* fits — pin is
max-over-cells |bias| < .03 on the ICC scale, MC SE ≈ .004):

| cell | θ² | 0b (none) | 1b (shipped) | 2b (over) |
|---|---|---|---|---|
| equal-k4, n_s = 8, p = .75 | .5 | −.035 | −.012 | +.014 |
| equal-k4, n_s = 8, p = .75 | 0 | −.051 | −.016 | −.009 |
| unequal-k, n_s = 8, p = .80 | .5 | −.029 | −.007 | +.016 |
| unequal-k, n_s = 8, p = .80 | 0 | −.052 | −.020 | −.014 |
| unequal-k, **n_s = 4**, p = .80 | .5 | −.059 | −.015 | **+.037** |

So: the committed oracle **does** reject the uncorrected estimator — but only through its boundary cells
(the interior unequal-k 0b bias, −.029, is inside the pin on its own), and it **cannot** reject a 2b
over-correction at n_s = 8. The power to certify the correction's *size* lives at low per-cluster
information (n_s ≈ 4), where b is large relative to the pin. At the oracle's n_s = 8, what actually pins
the correction's size is the *interval* evidence — boundary coverage is sensitive to center displacement
(M28's entire lesson) — plus, now, this review's direct identity checks.

**Q4 verdict: sound reasoning, honestly-limited instrument.** Recommend either (i) one n_s ≈ 4 interior
cell in O-IFNML at the next regeneration (it separates 1b from both alternatives: −.059 / −.015 / +.037),
or (ii) a sentence in the oracle header scoping the claim: the recovery pin certifies *presence and
rough scale* of the correction; its *exact size* is certified by the boundary-coverage cells and the
committed identity checks (`fable-check-m36-identities.R`).

## 6. What to take up (consolidated — all documentation/test-asset amendments, no shipped-code changes)

1. **O-IFNML, next regeneration:** add (a) a C_n = 80 boundary sentinel cell (§3) and (b) one n_s ≈ 4
   interior cell (§5). Neither invalidates the current fixture; both are cheap.
2. **Spec (`M36-incomplete-fixed-nested.md`):** record the §4(a) harmonic-pooling identity and the §4(b)
   Cov_s(θ²_c, 1/m_s) caveat in §2; note in §3 that on ragged data b_c is a consistent plug-in (not the
   balanced closed form) and that REML is load-bearing for the growing-β̂ regime (§1).
3. **ADR-046 / DECISIONS.md:** an amendment recording this review's outcome — the "no Fable needed" call
   confirmed post-hoc, with the process note that coverage claims for this interval family need a
   cluster-count axis (#18).

## References
- Brief + ADR-046 (M36 scope); ADR-038 / `fable-review-m28-*` (the 2b construction and its two
  identities); ADR-037 / `fable-review-m27-*`.
- Kackar, R. N., & Harville, D. A. (1984). *JASA, 79*(388), 853–862 (EGLS unbiasedness; the
  variance-underestimation term bounding b̂'s second-order error).
- McGraw & Wong (1996) Case 3/3A; ten Hove, Jorgensen & van der Ark (2022) Design 2.
- This review's scripts + results: `fable-check-m36.R`, `fable-check-m36-identities.R`,
  `fable-check-m36{,-identities}-results.rds` (same directory).
