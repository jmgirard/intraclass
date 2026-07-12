# Fable review response — averaged cluster-level ICC(c,k) divisor on incomplete data (M46, ADR-057)

**Reviewer:** Claude Fable 5 (gated statistical review, PRINCIPLE #19, maintainer-requested **pre-ship** at the
T1 decision point), 2026-07-12.
**Brief:** `fable-review-m46-cluster-ck-divisor-brief.md` (same directory).
**Reproduction:** the T1 spike (`m46-cluster-ck-divisor-spike.R`) re-run this review; output diffs **exactly**
against the committed `-out.txt`.
**Verification script (this review's, seeded, committed):** `fable-check-m46.R` (+
`fable-check-m46-results.rds`) — three legs the spike does not have: **(CHK-A)** a score-based, weight-free
error measurement (paired fresh-rater replicates, plain observed cell means, halved squared differences — no
`w` anywhere in the measurement); **(CHK-A2)** the rater-balanced score formed from the *same* draws, checked
against the distinct-count divisor; **(CHK-A3)** the score-based *relative* error vs the component-based
consistency error; **(CHK-B)** the end-to-end ship path (glmmTMB five-component REML fit → plug-in at k_c^eff)
against the empirical truth.

---

## 0. Verdict

**Inverse-Simpson harmonic k_c^eff is confirmed on the ship path — proceed to T2**, with one estimand
commitment to record, one documentation caveat this review newly quantifies, and oracle requirements for
T2/T3. Nothing here re-opens the degrade branch: the target question (Q1) is decidable from commitments the
package has already made, and the divisor is exact — not approximately, but as an instance of a general
identity — for that target.

1. **(Q1) The target is the observed cell-mean cluster score; inverse-Simpson ships.** The choice is
   **definitional, not empirical** — no simulation can adjudicate it, including Opus's and mine — but it is
   not open: ADR-057 itself commits the oracle target to "the population reliability of the **realized** ragged
   cluster means," and the realized cluster mean is the pooled mean over observed cells. The sources are
   genuinely silent (ten Hove et al.'s own illustrative example *brackets* the unbalanced-cluster k as
   "conservative and liberal" k = 3 / k = 5 rather than committing a divisor — and inverse-Simpson on their
   published design equals **4.5**, inside their bracket). Required: the spec and the report must **name the
   score** the coefficient describes (§1).
2. **(Q2) C-A is certified: agreement is exact at the cluster level** — and M9 §5's "effective-k
   approximation" hedge is **over-cautious at the subject level too**, by the same one-line algebra. The
   cluster level is not genuinely different in kind; recommend scoping (not deleting) §5's hedge (§2).
3. **(Q3) The brief's tautology suspicion is correct as aimed at Q1** — `mc_truth` simulates exactly the
   weighted sums L1 integrates analytically, so its < 0.003 agreement re-verifies L1's algebra for the assumed
   target. It is *not* worthless (it independently pins the harmonic aggregation and refutes the other
   candidates), but it cannot certify the target. This review supplies the independent legs (CHK-A: measured
   without `w`; CHK-B: through the fitted model), both of which confirm the divisor; T2's committed oracle
   should include both patterns (§3).
4. **(New finding, CHK-A3 — documentation, not a divisor bug.)** On ragged data the **observed ordering** of
   cluster means picks up a rater-main-effect term σ²_r · Σ_r(w_{c,r} − w̄_r)² that the component-based
   consistency error excludes — measured at **~2× the entire consistency error** on both test designs (C4:
   0.132 vs 0.076; C6: 0.303 vs 0.153), matched by an exact expectation to < 0.5%. ICC_c(C, k_c^eff) remains
   correct *as the inherited component-based estimand*, but a doc sentence is required (§4).
5. **(Q4) No divisor→interval interaction is expected** — k_c^eff is a deterministic design constant with no
   draw dependence (nothing like M27/M28's draw-dependent 2b correction). T3's sweep must still include an
   extreme-imbalance cell and a heterogeneous-m_c cell alongside the C_n axis, and must define the coverage
   target per realized design (§5).

## 1. Q1 — the estimand: cell-mean target, and why this is a commitment rather than a discovery

**The general identity first, because it reframes the question.** For *any* linear cluster score
m̂_c = Σ_r w_{c,r} (rater-r contribution) with Σ_r w_{c,r} = 1 and fixed design weights, the marginal error
variances are exactly σ²_cr Σw² (consistency) and (σ²_r + σ²_cr) Σw² (agreement): the effective rater count
is **always 1/Σw²**, whatever the weights. Opus's L1 is the cell-weight instance; the "distinct-count
harmonic" candidate is the uniform-weight instance; a subject-means-first cluster score (average each
subject's mean, then average subjects — arguably as common in practice as the pooled mean) is a third
instance with w_r = (1/S_c) Σ_{s∋r} 1/n_s. **Every candidate in the spike is the exact divisor for some
score.** CHK-A2 shows this empirically from one set of draws: the cell-mean score's measured Φ is 0.7273
(plug-in at k_IS = 2.143: 0.7282) while the rater-balanced score's measured Φ is 0.8813 (plug-in at
k_distinct = 6: 0.8824) — *on the same simulated data*. So the divisor question is really: **which observed
score does the reported coefficient describe?** No simulation adjudicates that; the brief's reading of the
MC's conditionality is exactly right.

**Ruling: the cell-mean (pooled observed mean) target, hence inverse-Simpson.** Grounds, in order of force:

- **The package already committed to it.** ADR-057's oracle strategy defines the target as "the population
  reliability of the **realized** ragged cluster means" — the realized mean of a ragged cluster is its pooled
  cell mean. M9 §5 defines the subject-level k_eff as "the effective number of raters behind the **observed
  subject means**." The uniform principle — *the coefficient describes the score a user actually forms from
  the observed data* — is the package's existing posture; the cluster level should not silently switch to a
  counterfactual score.
- **GT decision-study logic (Brennan; McGraw & Wong's average-ratings reading).** ICC(·,k) is the reliability
  of the composite entering subsequent analysis/decisions. On ragged data users form pooled cluster means
  (`mean(score)` by cluster, or a mixed-model BLUP that shrinks toward it); nobody forms the rater-balanced
  mean — it is a construct that up-weights the sparsest raters (and in doing so maximizes their
  subject-sample leakage, invisible only because the cluster estimand conditions subjects out).
- **The sources do not contradict it — they punt.** Eq. 13's k is defined under an explicit "same number of
  raters per cluster" simplification. Decisively, ten Hove et al.'s own illustrative example (p. 14) has
  exactly M46's problem — per teacher, one rater rated all drawings and four rated half, "not perfectly
  balanced" — and the authors **bracket** k = 3 (conservative) / k = 5 (liberal) rather than name a divisor.
  On that design the cell weights are (1/3, 1/6, 1/6, 1/6, 1/6), so m^IS = 1/(Σw²) = **4.5** — inside their
  bracket, with distinct-count (5) sitting at their liberal end. Shipping inverse-Simpson operationalizes,
  with a principled single number, precisely what the source authors could only bracket.
- **Error direction under misuse is safe.** If the shipped k were distinct-count and a user's score is the
  pooled mean (the common case), the report would **overstate** reliability by up to +0.15 Φ (C6). Shipping
  inverse-Simpson, a hypothetical rater-balanced-score user is told a *conservative* number. The asymmetric
  loss favors inverse-Simpson.

**Required (ship condition, documentation-level):** the M9/M46 spec and the user-facing report must state the
target in one sentence — *"k_c^eff is the effective number of raters behind each cluster's observed
(cells-pooled) mean; a rater-balanced cluster mean has a different (higher) effective count"* — and the spec
should record the general 1/Σw² identity above, so any future score variant (e.g. subject-means-first) is a
weight swap, not a re-derivation. With the target named, this is a clean commitment, not an open estimand
(#18 satisfied; degrade branch not triggered).

## 2. Q2 — C-A certified: agreement is exact; and the M9 §5 hedge was over-cautious all along

The absolute (agreement) error in the GT/Brennan sense — and the sense in which ten Hove's Eq. 13 carries
σ²_r — is the **marginal** expected squared deviation of the observed score from the cluster's universe
score, E[(Σ_r w_{c,r}(r_r + cr_{c,r}))²] = (σ²_r + σ²_cr) Σw². Cross-cluster covariance from shared global
raters (σ²_r Σ_r w_{c,r} w_{c′,r} ≠ 0) is real but **enters no term of the estimand**: σ²_Δ is a
per-cluster-marginal quantity averaged over clusters, and expectation is unaffected by covariance between
clusters. CHK-A measures this with no weights anywhere in the measurement — per-cluster agreement deviations
are at MC noise (max ~5% relative at R = 6000, exactly the expected max of |N(0, √(2/R))| over 60 clusters),
aggregate Φ within 0.0015 — and CHK-B confirms it through the fitted model. **C-A holds: exact, not
effective-k.**

**Reconciling with M9 §5 — the honest answer is that §5 is over-cautious, not that the cluster level is
special.** At the subject level the same algebra gives E[e_s²] = (σ²_r + σ²_res)/n_s exactly, and averaging
over subjects gives (σ²_r + σ²_res) · mean(1/n_s) = error/k_eff **exactly** — harmonic pooling *is*
per-unit error-variance averaging (the identity this review's M36 sibling recorded as §4(a) there). So
ICC_s(A, k_eff) is already exact for the mean marginal absolute error of the observed subject means; the
"fresh raters" worry in §5 does not track a k-approximation. What it *does* track — worth keeping, rescoped —
are two true statements: (a) a single k describes the **average** error across units, not each unit's own
(per-unit heterogeneity in 1/m is averaged; note that unlike M36 §4(b) there is **no covariance slippage**
here, because the error components σ²_r, σ²_cr are global model parameters, homogeneous across clusters by
construction — the cluster case is *cleaner* than the fixed-rater case); and (b) the marginal (universe)
reading differs from the conditional "these particular raters" reading for agreement — but that distinction
exists on complete data too and has nothing to do with raggedness or k. **Recommendation:** amend §5 (and the
M46 spec text) to state the exactness identity and rescope the hedge to (a)+(b); do not propagate
"approximation" language into the cluster-level docs — it is wrong for the shipped estimand.

## 3. Q3 — the MC oracle is semi-circular as the brief suspects; the independent legs now exist

`mc_truth` constructs a_c = Σw·r and b_c = Σw·cr from the same cell weights that define m^IS and never
simulates the subject/residual facets into the means (the leakage is asserted by "large n_s", not measured),
then compares moments L1 computes analytically. As certification of the **target** it is tautological
(conceded above — nothing could be otherwise); as certification of the **divisor given the target** it is an
arithmetic re-verification of L1 plus two things of genuine value: the harmonic aggregation across
heterogeneous clusters, and the **discrimination** claim C-B (the competing candidates fail against the same
truth — that part stands and is confirmed).

The two independence gaps are closed by this review's committed checks, and **T2's committed oracle
(`data-raw/oracle-cluster-ck-incomplete.R`) should adopt both patterns**:

- **Score-based truth, no `w` in the measurement (CHK-A pattern).** Paired replicates sharing
  cluster/subject effects with fresh rater-side draws; plain `mean()` per cluster; halved squared replicate
  differences. Subject terms cancel *exactly* (no "large n_s" assertion), and the only leakage is the
  indisputable iid-mean term σ²_res/n_cells, subtracted analytically. Agreement: fresh raters per replicate.
  Consistency: shared rater mains, fresh cluster×rater draws.
- **Ship-path recovery (CHK-B pattern).** Full five-component data on the frozen design, the actual glmmTMB
  REML fit, plug-in at k_c^eff from *estimated* components. Result: C6 mean fitted Φ = 0.7268 vs empirical
  0.7273 (n_fit = 120); ρ = 0.8725 vs 0.8776; C4 Φ = 0.8472 vs 0.8386 (n_fit = 50) — residual gaps are
  small-sample plug-in (Jensen) noise of the component estimates at C_n = 60, ~1–2 MC SE, not divisor error;
  interval calibration of exactly this noise is T3's job.
- If T2 measures a literal score-MSE truth from full data instead, it must control the finite-n_s leakage
  (σ²_sc Σ_s w_s² + σ²_res/n_cells) explicitly rather than by assertion — the Eq. 13-style estimand is
  component-based and contains no subject terms, so an unadjusted score-MSE truth is biased *against* the
  correct divisor at small n_s.

And to say it plainly per the brief's ask: there is **no** empirical check that discriminates cell-mean vs
rater-balanced *as targets* — CHK-A2 shows both are exactly recoverable from the same data by their own
divisors. Q1 is settled by commitment (§1), not by simulation; T2 should cite §1, not re-run candidates.

## 4. New finding — on ragged data, rater mains contaminate the *observed ordering* of cluster means (doc caveat)

The component-based consistency estimand (error {σ²_cr}/k, inherited, correctly not under review) is
motivated on complete data by exact cancellation: rater main effects shift every cluster equally, so they
cannot affect ordering. **On ragged data that cancellation is broken by weight-profile heterogeneity**: the
centered rater contribution to cluster c is Σ_r (w_{c,r} − w̄_r) r_r, contributing
≈ σ²_r · mean_c Σ_r (w_{c,r} − w̄_r)² to the cross-cluster variance of observed means. CHK-A3 measures the
score-based relative error (per-replicate sample variance of error-only observed cell means) and matches an
exact expectation tr(HVH)/(C−1), V = σ²_r WW′ + σ²_cr diag(Σw²) + diag(leak):

| design | measured | exact expectation | component-based σ²_cr/k_IS (+leak) |
|---|---|---|---|
| C4 structured MAR | 0.1322 | 0.1327 | 0.0759 |
| C6 extreme imbalance | 0.3031 | 0.3034 | 0.1533 |

So on both a garden-variety ragged design (different rater *subsets* per cluster suffice — C4) and the
extreme one, the realized ordering of observed cluster means carries roughly **as much rater-main variance
again** as the entire consistency error. This is **not** a divisor bug and does not touch agreement (which
charges the full σ²_r Σw² and remains exact); it is the ragged-data gap between "consistency as a
component-based coefficient" and "reliability of the relative standing of the observed means" — the same
family of distinction as M45's conflation caveat. **Required: one honest sentence** in the M46 spec/docs,
e.g.: *"On ragged data, rater main effects do not fully cancel from comparisons of observed cluster means
(they cancel only under identical rater weight profiles); ICC_c(C, k_c^eff) quantifies rater disagreement
(σ²_cr) only — users comparing observed ragged cluster means should prefer ICC_c(A, k_c^eff), whose error
term bounds the ordering contamination."* No code change; the estimand is inherited as-is.

## 5. Q4 — intervals: no new interaction; what T3's sweep must contain

k_c^eff is a deterministic function of the observed cell pattern — component-free (C7), draw-independent,
entering the MC interval only as a fixed scalar on the error sum. There is no analog of the M27/M28
draw-dependent moment correction, so no channel for the divisor itself to destabilize coverage; calibration
is inherited from the component-draw machinery. Four things T3 must nonetheless do:

1. **Sweep C_n** ([[coverage-oracle-cluster-count-axis]]) — σ²_c and σ²_cr are cluster-indexed; the known
   failure mode is invisible at few clusters. n_rep ≥ 240 per [[ragged-coverage-nrep-240]].
2. **Include a C6-style extreme-imbalance cell**, not only MCAR: small k_c^eff (≈ 2.1) makes the error term
   dominant, pushing the coefficient toward the low/boundary regime where the boundary-aware machinery is
   actually exercised — MCAR cells (k_c^eff ≈ k) would test the divisor where it does no work.
3. **Include a C4-style heterogeneous-m_c cell**, where the harmonic aggregation is active (m_c^IS spanning
   ~2–8), plus the boundary σ²_c ≈ 0 rows as usual.
4. **Define the coverage target per realized design.** If missingness is resampled across reps, the
   population ICC_c(·, k_c^eff) *itself* changes per rep (the divisor is a design property); either freeze
   the cell pattern across reps (M36's pattern) or check coverage against each rep's own realized-design
   population value — never a single pooled "truth" across heterogeneous patterns. And if the truth is
   score-based, apply the §3 leakage control.

## 6. What to take up (consolidated)

1. **T2 proceeds with inverse-Simpson harmonic k_c^eff** (§0/§1). Wire `R/estimand.R` error_divisors + the
   `R/icc.R` ~L1188 abort replacement as planned; surface k_c^eff (and, ideally, the per-cluster m_c^IS range)
   in the report.
2. **Spec/docs (with T2, same commit):** (a) name the target score (§1, required); (b) record the general
   1/Σw² identity (§1); (c) the ragged-consistency ordering caveat (§4, required); (d) rescope M9 §5's
   agreement hedge per §2 (recommended; at minimum do not propagate it to the cluster level).
3. **T2's committed oracle:** adopt the CHK-A score-based truth and CHK-B ship-path patterns (§3); do not
   re-litigate Q1 by simulation.
4. **T3 coverage:** the four requirements of §5.
5. **ADR-057 follow-up entry:** record this review's outcome — divisor blessed, target committed, the §4
   caveat, and that the degrade branch is not triggered.

## References
- Brief + ADR-057 (M46 scope); ADR-018/M9 §3b/§5/§9; ADR-030 (occasion sibling); ADR-046/`fable-review-m36-*`
  (harmonic pooling ≡ error-variance averaging, §4(a) there; the per-unit-heterogeneity caveat pattern).
- ten Hove, Jorgensen & van der Ark (2022), *Psychological Methods, 27*(4): Eq. 13 + its "same number of
  raters per cluster" simplification (p. 6); the illustrative example's k = 3/5 conservative–liberal bracket
  under per-cluster rater imbalance (p. 14) — the published design's cell weights give m^IS = 4.5.
- McGraw & Wong (1996), *Psychological Methods, 1*(1) (average-ratings reading); Brennan (2001),
  *Generalizability Theory* (absolute vs relative error; D-study decision-score logic).
- This review's script + results: `fable-check-m46.R`, `fable-check-m46-results.rds`; spike reproduction
  verified exact against `m46-cluster-ck-divisor-spike-out.txt`.
