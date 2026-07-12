# Fable review brief — averaged cluster-level ICC(c,k) divisor on incomplete data (M46, ADR-057)

**Status:** gated statistical review (PRINCIPLE #19), requested by the maintainer at the M46 **T1 decision
point** — **before** any code is wired. Unlike the M36 brief (post-hoc), this is a **pre-ship** review: the
proposed divisor is committed only as a feasibility spike (`data-raw/reviews/m46-cluster-ck-divisor-spike.R`
+ `-out.txt`); the shipped estimator (`R/estimand.R` error_divisors, the `R/icc.R` ~L1188 abort) is **not yet
touched** and T2 is gated on this verdict. Opus's T1 study concluded the divisor is **validated on the ship
path** and that a Fable review is *optional*; the maintainer escalated anyway to bless a **novel divisor**
before it ships. **Do not tune to the spike (#4); characterize honestly (#18).** If the derivation holds, say
so plainly; if the estimand framing is wrong, the whole ship path changes (→ abort stays, degrade branch).

---

## 1. Context and the estimand

Crossed Design 1 (raters **crossed** with clusters, GLOBAL rater labels), raters **random**, on **ragged**
data (missing subject×rater cells). Fit (M5, oracle-pinned):

    score ~ 1 + (1|cluster) + (1|cluster:subject) + (1|rater) + (1|cluster:rater)

giving σ²_c, σ²_{s:c}, σ²_r, σ²_cr, σ²_res. The **cluster-level** ICC (between-cluster reliability, signal
σ²_c) has error sets (M5/M9 §3b, inherited unchanged — NOT under review):

    agreement:    ICC_c(A,k) = σ²_c / (σ²_c + (σ²_r + σ²_cr) / k)
    consistency:  ICC_c(C,k) = σ²_c / (σ²_c +  σ²_cr        / k)

σ²_{s:c} and σ²_res are **absent** from the cluster error set (they average out over the cluster's subjects —
the cluster estimand conditions on the subject sample, M5 §3). On **complete** data k = the rater count and
the average ships (M5). On **ragged** data the single-rater ICC_c(·,1) ships (M9 Slice 2, ADR-018), but the
**average was deferred** behind a classed abort (`R/icc.R` ~L1188) because **the effective divisor k for a
ragged cluster mean has no textbook worked example** (M9 §3b/§9). M46 resolves it. **The only object under
review is that divisor.**

## 2. What Opus proposes (the ship-path claim to interrogate)

**Proposed divisor — inverse-Simpson harmonic mean.** For cluster c, let rater r contribute weight
w_{c,r} = (# observed cells of rater r in c) / (# observed cells in c). Define the per-cluster
**inverse-Simpson effective rater count**

    m_c^IS = 1 / Σ_r w_{c,r}²        (= # distinct raters when weights are equal; < it otherwise)

and aggregate across clusters by **harmonic mean**:

    k_c^eff = 1 / mean_c(1 / m_c^IS).

**Analytic leg (L1), Opus's derivation.** The observed cluster mean is the mean over its cells,
m̂_c = Σ_cells score / n_cells = c_c + Σ_r w_{c,r} r_r + Σ_r w_{c,r} cr_{c,r} + (subject/residual leakage → 0
for many subjects). Since r_r and cr_{c,r} are iid with variances σ²_r, σ²_cr:

    Var(Σ_r w_{c,r} cr_{c,r}) = σ²_cr Σ_r w_{c,r}² = σ²_cr / m_c^IS       (consistency error of cluster c)
    E[(Σ_r w_{c,r} r_r + Σ_r w_{c,r} cr_{c,r})²] = (σ²_r + σ²_cr)/m_c^IS   (absolute error of cluster c)

A single reported divisor k must satisfy error/k = mean_c(error/m_c^IS) ⇒ **k_c^eff = 1/mean_c(1/m_c^IS)**,
which is then **exact, closed-form, for BOTH agreement and consistency** and **component-free** (depends only
on the design weights). Reduces to the balanced rater count on complete data (recovering M5).

**Two claims Opus rests on that a review should certify:**

- **(C-A) Agreement is EXACT, not approximate.** This **contradicts M9 §5**, which hedges that at the SUBJECT
  level the agreement divisor is only an "effective-k approximation" because the error carries the global
  σ²_r. Opus argues the cluster-level absolute (agreement) coefficient uses each cluster's **marginal** error
  E[(·)²], into which the cross-cluster covariance of σ²_r (shared raters) does **not** enter — so there is no
  approximation at the cluster level. (Note the subject level has no analogous ambiguity: each subject×rater
  is ONE cell, so cell-weighting = rater-weighting and m^IS = distinct count trivially; the divergence is
  genuinely new at the cluster level, where a rater spans many subjects.)
- **(C-B) The divisor discriminates sharply.** Under extreme within-cluster weight imbalance (one rater rates
  every subject, others rate ~3 → m_c^IS ≈ 2.14 while distinct count = 6), inverse-Simpson stays exact while
  **distinct-count harmonic** over-states Φ by +0.15 / ρ by +0.075 and **arithmetic mean** likewise; the
  **subject-level k_eff** is refuted throughout (wrong quantity, §3b confirmed).

## 3. The honest gap — is the ESTIMAND the cell-mean? (the load-bearing question)

**Q1 (central). Does the reported cluster-level reliability target the ratings-weighted cluster mean, or a
rater-balanced one?** Opus's L1 and MC both define the cluster score as the mean over **observed cells**,
which weights a rater by how many of the cluster's subjects it rated. **Inverse-Simpson is exact for THAT
target by construction.** But an equally-defensible universe score is the **rater-balanced** cluster mean —
average each rater's within-cluster mean first, then average those over the distinct raters — under which the
effective count is the **distinct-rater harmonic mean**, not inverse-Simpson. The two coincide on complete /
uniform-weight data and diverge exactly in the ragged regime M46 exists to serve. **Which target matches the
ten Hove (2022) multilevel cluster estimand and the McGraw & Wong (1996) generalizability reading the package
commits to?** This is not settled by any simulation Opus ran — the MC "truth" *assumes* the cell-mean target,
so it certifies the divisor **conditional on** that target and cannot adjudicate the target itself. If the
intended universe score is rater-balanced, the shipped divisor should be distinct-count harmonic and Opus's
"inverse-Simpson" recommendation is wrong (though still a small effect except under severe weight imbalance).

**Q2. Is the L1 marginal-error argument for agreement (C-A) valid**, or does a correct cluster-level agreement
(absolute) coefficient — as ten Hove/Brennan define the absolute error variance for a decision on cluster
means — actually pick up a term that the per-cluster marginal E[(·)²] misses (making M9 §5's "approximation"
hedge correct after all)? Reconcile the apparent contradiction with §5 explicitly: is §5 over-cautious, or is
the cluster level genuinely different?

**Q3. Is the MC oracle (L2) non-circular enough to certify anything beyond internal consistency?** Opus's
`mc_truth` draws r_r, cr_{c,r} and forms a_c = Σ w r_r, b_c = Σ w cr_{c,r} with the **same weights w** that
define m_c^IS, then reports Φ_true = σ²_c/(σ²_c + mean_c(a_c+b_c)²). Since both the "truth" and the candidate
use the cell-weighting, agreement to <0.003 may be **tautological for the cell-mean target** and merely
re-expresses L1. Is there an *independent* check (e.g. fit the actual glmmTMB model on ragged data and compare
the reported ICC_c(·,k_c^eff) to a brute-force reliability defined WITHOUT reference to w — e.g. split-half
over raters, or the correlation of two disjoint-rater cluster means) that would discriminate the cell-mean vs
rater-balanced targets and thereby test Q1 empirically rather than assuming it?

**Q4. Interval interaction (forward-looking, T3).** k_c^eff is a fixed design constant fed into the
boundary-aware MC interval (draws are on the variance components; the divisor multiplies the error sum). Any
reason the ragged divisor would destabilize coverage of ICC_c(·,k) — or is coverage inherited cleanly from
the shipped component-draw machinery once the point divisor is right? (Opus has not yet run cluster-level
ICC(c,k) coverage; T3 will, over a swept C_n per [[coverage-oracle-cluster-count-axis]]. Flag if the divisor
choice changes what that sweep must test.)

## 4. Evidence Opus committed (for Fable to reproduce / stress)

- **T1 spike:** `data-raw/reviews/m46-cluster-ck-divisor-spike.R` (+ `-out.txt`). Two legs (L1 analytic in the
  header comment; L2 MC in `mc_truth`), candidates in `candidates()`, battery C1–C7 (C_n 6→80, MCAR,
  structured MAR, extreme weight imbalance, component-invariance). Known components vc=1.0, vsc=0.8, vr=0.5,
  vcr=0.3, vres=0.6 (C7 re-runs vc=0.4, vr=1.2, vcr=0.9). Deterministic, seeded, standalone-runnable.
- **Reported:** inverse-Simpson harmonic recovers Φ and ρ to <0.003 across all 7 cells; distinct-count exact
  only under uniform weights (+0.15 Φ under extreme imbalance); arithmetic and subject-k_eff refuted;
  divisor is design-only (component-invariant, C7).
- **Not yet built** (gated on this verdict): the committed oracle generator `data-raw/oracle-cluster-ck-incomplete.R`,
  the estimator wiring, and cluster-level ICC(c,k) coverage — all T2/T3.

## 5. What a verdict should deliver

1. **Q1 first (estimand):** rule on the **cell-mean (ratings-weighted → inverse-Simpson) vs rater-balanced
   (→ distinct-count harmonic)** cluster universe score, against the ten Hove / McGraw & Wong definitions the
   package commits to. This decides *which* divisor ships. A wrong target here is a ship-path estimand bug, not
   a tuning detail.
2. **Q2:** certify or refute (C-A) — agreement exact vs approximate at the cluster level — and reconcile with
   M9 §5.
3. **Q3:** say whether the MC oracle is independent enough to certify, or is tautological for its assumed
   target; propose the independent check if so.
4. **Q4:** flag any divisor→interval interaction T3 must test.

A clean bill confirms Opus's ship-path call and the inverse-Simpson divisor (proceed to T2). A ruling for the
rater-balanced target swaps the shipped divisor to distinct-count harmonic (still ships — re-derive the spike
oracle). A finding that neither target is defensible without a further modeling commitment sends M46 to the
**degrade branch** (abort stays, negative finding documented — ADR-057's attempt-then-degrade). **Do not tune
to the spike (#4); if the estimand target is genuinely open, say so (#18).**

## References
- ADR-057 (M46 scope); ADR-018 (M9 — ICC(c,1) shipped, ICC(c,k) deferred); ADR-008 (subject-level k_eff);
  ADR-030 (the occasion-averaged sibling's ship-or-abort precedent); ADR-046/`fable-review-m36-*` (the
  fixed-nested divisor review, which found k_eff not the open per-cluster divisor).
- ten Hove, Jorgensen & van der Ark (2022), *Psychological Methods, 27*(4), Design 1 cluster level (Eq. 12 /
  Table 3); McGraw & Wong (1996), *Psychological Methods, 1*(1), the two-way ICC family generalized.
- `project/estimand-specs/M9-incomplete-multilevel.md` §3b/§5/§9; `project/DECISIONS.md` ADR-057.
- [[coverage-oracle-cluster-count-axis]], [[cluster-icc-no-subject-facet]].
