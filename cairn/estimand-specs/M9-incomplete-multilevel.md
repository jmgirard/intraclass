# Estimand specification — M9: incomplete / unbalanced multilevel ICCs (Design 1)

**Scope of this document.** The precise population quantities and the identifiability
+ divisor rules for the multilevel interrater ICCs when the **crossed** multilevel
design (ten Hove et al. 2022, **Design 1** — raters crossed with clusters) is
**ragged**: subjects within clusters are rated by different, overlapping subsets of
raters (missing subject×rater cells). M9 is the **intersection of two shipped
machineries** and introduces *no new estimand*:

1. the **M5 Design-1 fit and estimand map** (`estimand-specs/M5-multilevel.md`,
   ADR-011) — five-component fit, subject- and cluster-level `(signal, {error set},
   scalar divisor)` — inherited **unchanged as population definitions**; and
2. the **M3 incompleteness handling** (`estimand-specs/M3-incomplete-designs.md`,
   ADR-008) — a connectedness identifiability guard and the `k_eff` averaging divisor
   — **generalized** from the flat subject×rater layout to the multilevel structure.

Read M5 and M3 first. As in M3 relative to M1/M2, M9 changes the *data regime*, not
the coefficient: the signal is still σ²_{s:c} (subject level) or σ²_c (cluster level)
and the error sets are exactly M5's. What changes is **when they are identified** and
**how the average-`k` divisor is defined** on ragged multilevel data.

**Locked scope (ADR-018, maintainer-approved this session, 2026-07-07):**
- **Design 1 (crossed) only.** Incomplete **nested** designs (Designs 2/3) are
  deferred to their own later slice — the ragged nested-vs-crossed inference problem
  (§4) is resolved for the crossed base first, mirroring the M5(D1) → M8(D2/3)
  progression.
- **Random raters.** Fixed-rater multilevel stays deferred (reuse the M3 real
  fixed-effect fit path — ADR-008; its own later slice).
- **glmmTMB engine** (lme4 as the cross-engine oracle, ADR-002/012).
- Both **subject- and cluster-level** IRR, exactly as M5 ships for Design 1, each
  gated by its own identifiability condition (§3, §7).

**What is inherited vs. what is M9's engineering (be explicit, #18).** The estimands
(§3) are **verbatim M5** — not re-derived. M9's genuinely new, **oracle-pinned-not-
asserted** content is (a) the **multilevel identifiability / connectedness condition**
(§4) — materially more layered than M3's single bipartite graph — and (b) the
**multilevel `k_eff`** (§5). Neither is asserted from a formula alone; both are
established by oracle (§6) before shipping, and if either cannot be cleanly pinned a
Fable review is *recommended* and work pauses (#1, #19).

M9 ships on branch `m9-incomplete-multilevel`, in CI-green slices (§6).

---

## 1. What M9 adds to the abstraction

M5 fixed the multilevel estimand as `(signal, {error set}, scalar divisor)` keyed on
`level` and `type`, over a **balanced/complete** Design-1 fit. M9 drops the balance
assumption and, as a consequence, two things that balance had been hiding become live
— exactly the M3 story, now one structural level up:

| Concern | Balanced multilevel (M5) | Incomplete multilevel (M9) |
|---|---|---|
| Identifiability of the components | automatic (orthogonal) | requires a **connected** multilevel design (§4) |
| Averaging divisor `k` for `ICC(*,k)` | unambiguous (= raters/subject) | **ill-defined** on ragged counts → `k_eff` (§5) |
| Design detection (crossed vs nested) | unambiguous from a complete pattern | **ambiguous under missing cells** → declared/guarded (§4) |

The fit, `icc_point()`, `resolve_divisor()`, and the boundary-aware Monte-Carlo CI
(ADR-003) are **untouched** — the mixed model consumes ragged multilevel data
natively by (RE)ML, the package's core differentiator over ANOVA/mean-square tools
(M3 §2; ten Hove et al. 2024).

Notation extends M3: `n_c` clusters; within cluster `c`, subjects `s` and raters;
`n_{s}` = raters that actually rated subject `s` (≤ the raters available to `s`'s
cluster); balanced ⇔ every subject in a cluster rated by that cluster's full rater
set, one rating per cell.

---

## 2. The fit is unchanged; multilevel imbalance is native

The Design-1 random-rater model is exactly M5's five-component fit, by REML:

```r
score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)
```

estimating σ²_c, σ²_{s:c}, σ²_r, σ²_cr, σ²_res (= σ²_{(s:c)r}). A mixed model
estimates these from the likelihood, not from balanced ANOVA mean-square identities,
so it consumes ragged multilevel data directly. **No new engine or CI machinery.**
What imbalance costs is the same two things as M3 — the exact-oracle equivalence
(so M9 oracles are simulation / cross-engine / reduction based, §6) and the free
identifiability and free `k`, addressed in §4–§5 — plus one new thing unique to the
multilevel case: **the design is no longer self-evident from the pattern (§4).**

---

## 3. The estimands — verbatim M5 (population definitions unchanged)

Each ICC is `signal / (signal + error / k)` — the existing scalar-divisor
`icc_point()` form. **Nothing in this table is new to M9**; it is reproduced from
`M5-multilevel.md §3` so the divisor rule (§5) and identifiability rule (§4) have a
concrete referent. Only *when* each is identified and *what `k` is* change under
imbalance.

### 3a. Subject-level (within-cluster) IRR — signal σ²_{s:c}

| | agreement | consistency |
|---|---|---|
| single `ICC_s(·,1)` | σ²_{s:c} / (σ²_{s:c} + σ²_r + σ²_{(s:c)r}) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}) |
| average `ICC_s(·,k)` | σ²_{s:c} / (σ²_{s:c} + (σ²_r + σ²_{(s:c)r})/k) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}/k) |

**σ²_cr (cluster×rater) is *not* in the subject-level error** (paper Eq. 12, Table 3
top-left; M5 spec §3a) — a cluster×rater effect shifts every subject in a cluster
equally, so it does not affect *within-cluster* subject discrimination even for
agreement. Error set = `{rater, residual}` (agreement) or `{residual}` (consistency),
the **same structure as the single-level M1/M2 estimand**. (Confirmed against the
shipped M5 `icc_point()` and an lme4 cross-check on ragged data this session —
matches to ~1e-4; an earlier draft of this table wrongly included σ²_cr, corrected
before code per #1.)

### 3b. Cluster-level (between-cluster) IRR — signal σ²_c

The M5 cluster-level estimand map, inherited unchanged (see `M5-multilevel.md §3`):
signal σ²_c; agreement error `{σ²_r, σ²_cr}`, consistency error `{σ²_cr}`.
Cluster-level identifiability under imbalance has its **own** condition (§4b, Slice 2)
and is returned only when met; otherwise a classed abort points the user at the
subject level.

**Slice 2 ships the single-rater `ICC(c,1)` only** (maintainer decision this session,
recorded in ADR-018). `ICC(c,1)` needs **no divisor** — it is unambiguous. The
averaging divisor for `ICC(c,k)` under imbalance is a **separate, genuinely open
modeling question**: the effective number of raters behind a ragged *cluster* mean is
a **per-cluster** quantity (raters that rated in each cluster), *not* the per-subject
`k_eff` of §5 — on complete data they coincide (why M5 shipped one divisor), but on
ragged data they diverge, and there are several defensible definitions (harmonic mean
of distinct raters per cluster; an inverse-Simpson effective count weighted by
ratings-per-rater; …) with **no textbook worked example** to pin one. Rather than
assert an unvalidated divisor (#1), `ICC(c,k)` on incomplete data is **deferred**
(§9) — a good candidate for a focused simulation-oracle study or a Fable review — and
requesting it raises a classed abort. Complete data is unaffected (M5 ships both).

---

## 4. Identifiability under incompleteness (PRINCIPLES.md #5) — M9's core

M3's identifiability rule was one clean graph-theoretic condition (connectedness of
the subject×rater bipartite graph). The multilevel Design-1 fit has **five** variance
components tied together through a richer crossing structure, so identifiability is
**layered** and — per #18 — the exact conditions below are **oracle-pinned, not
asserted** (§6): each is confirmed to gate real (un)identifiability against lme4's
rank/convergence signals and seeded recovery before the guard is trusted.

### 4a. Design detection under missing cells — declared, not guessed

`detect_multilevel_design()` (`R/design.R`) currently infers crossed vs nested from
the observed pattern: a rater confined to a single cluster reads as *nested*. **Under
missing cells this is ambiguous** — a genuinely crossed (Design 1) rater that simply
*happened* to rate in only one cluster is indistinguishable from a nested rater, and
the estimand differs (crossed separates σ²_r and σ²_cr; nesting confounds them into
σ²_{r:c}). Resolution (ADR-018):

- **Unambiguous pattern** (every rater spans ≥2 clusters ⇒ crossed; every rater
  confined ⇒ nested) → infer as today.
- **Ambiguous pattern** (some raters span clusters, some confined — what M8 today
  calls "mixed" and aborts) → **do not guess.** `icc()` gains an **optional
  `design` argument** (name TBD in Slice 1; e.g. `design = c("crossed", …)`) by which
  the user *asserts* the intended design. When the pattern is ambiguous and `design`
  is unset, abort via `abort_unidentified()` naming the ambiguity and the argument.
  When `design = "crossed"` is asserted, fit the crossed model and let §4b decide
  whether σ²_r vs σ²_cr is actually identified.
- The argument is **validated against the data**, never used to override a structural
  impossibility (e.g. `design = "crossed"` when *no* rater bridges clusters leaves
  σ²_r/σ²_cr confounded → §4b abort, not a silent nesting).

This keeps #6 (small API) honest — the argument appears only for the genuinely
ambiguous ragged case — while satisfying #5 / #2 (never silently switch the estimand).

### 4b. Component identifiability for the crossed fit

The two subject-level coefficients need **different** components separated (§3a: σ²_cr
is *not* in either error set, so it never needs isolating *for the subject level* —
but σ²_r, which enters the agreement error, must be cleanly separated *from* σ²_cr):

- **Consistency** (error `{σ²_res}`) needs only **σ²_{s:c} vs σ²_res** — within each
  cluster the subject×rater sub-design must be **connected** (the M3 condition, applied
  per cluster over that cluster's observed cells; reuse `design_connected()` on each
  cluster's incidence submatrix).
- **Agreement** additionally needs **σ²_r separated from σ²_cr** — the rater main
  effect (which *is* in the agreement error) is distinguishable from the cluster×rater
  interaction (which is *not*) only if enough raters **bridge clusters**: the
  cluster×rater bipartite graph (clusters vs raters, an edge per cluster a rater rated
  in) must be connected. A design where every rater is confined to one cluster confounds
  σ²_r into σ²_cr — i.e. it *is* nested (Design 2), not incomplete-crossed → classed
  abort pointing at the nested (M8) path. So the bridging condition **gates agreement
  specifically**; consistency can still be reported when only §4b's first bullet holds.
- **Cluster level (§3b, Slice 2)** needs σ²_c estimable *and* the cluster×rater linkage
  (σ²_cr is the cluster-level rater-disagreement error there); when unmet, cluster-level
  IRR aborts and points at the subject level (M5 §7 posture).

**These conditions are the spec's hypothesis, pinned in Slice 1 (§6) — not shipped on
assertion.** If a stated condition does not match where lme4/glmmTMB actually loses
rank (false accept *or* false reject), the condition is corrected against the oracle
before the guard ships; an unresolved case triggers a recommended Fable review (#19).

---

## 5. The `ICC(*,k)` divisor under multilevel imbalance — `k_eff`

`ICC(*,1)` is always well-posed. For the average, M9 reuses the M3 decision (ADR-008):
`k` = the **effective number of raters behind the observed subject means**,
`k_eff = 1 / mean(1/n_{s})`, the harmonic mean of the per-subject rater counts `n_{s}`
— now counted **within the multilevel structure** (raters that rated subject `s` in
its cluster). It reduces to the balanced rater count when complete (recovering M5),
and `icc()` surfaces `k_eff` so the divisor is transparent.

The M3 agreement-vs-consistency caveat carries over: `k_eff` is exact for
**consistency** (error = σ²_res only). For **agreement** the error carries **two**
rater-side terms (σ²_r *and* σ²_cr) beyond σ²_res. Using a single `k_eff` for the whole
error applies one consistent effective rater count. **Pinned by oracle in Slice 1**
(define `Φ(k_eff)` from known components + the realized design and check recovery), not
asserted.

**Note (M46, ADR-057 Am.1 — the "approximation" hedge rescoped).** An earlier draft called
the agreement average an *effective-`k` approximation*. The M46 Fable review established
that harmonic pooling *is* per-unit error-variance averaging **exactly** (the mean marginal
absolute error of the observed means is `(σ²_r + σ²_res)·mean(1/n_s) = error/k_eff`), so
`ICC(A, k_eff)` is **exact for the mean marginal absolute agreement error**, not an
approximation. What remains true is only that a single `k_eff` summarizes the *average*
per-unit error (not each unit's own), and that the marginal (universe) reading differs from
a conditional "these particular raters" reading — a distinction that exists on complete data
too. The cluster level is *cleaner still* and exact (§10); the "approximation" language is
retired and must not propagate to the cluster-level docs.

---

## 6. Oracles (PRINCIPLES.md #1 — ≥2 independent) and slices

No textbook worked example exists for ragged multilevel IRR (as with O5/O-ML/O-NML).
Correctness rests on the **M3 × M5 combined oracle template**, in
`tests/testthat/test-icc-incomplete-multilevel.R` (name TBD), regenerated by
`data-raw/oracle-incomplete-multilevel.R` (seeded, `stopifnot` tolerances):

- **O-IML/lme4** — `lme4::lmer` fits the identical five-component model on the same
  ragged data and reproduces every §3 coefficient (defined type × single/average ×
  level) to < 1e-4. Independent engine (ADR-005 role).
- **O-IML/sim** — a seeded incomplete-multilevel simulation with **known** components
  (M5 §5 data-generating regime + MCAR/MAR cell deletion) recovers the points within
  tolerance and the boundary-aware MC interval covers the population values (#12).
- **O-IML/reduction** — two clean reductions to already-pinned estimators, asserted
  numerically:
  - **→ complete M5 Design 1.** On complete data every M9 path reproduces the M5
    numbers exactly (regression guard + balanced reduction; `k_eff = k`).
  - **→ M3 flat incomplete two-way.** With a single cluster (σ²_c ≡ 0, σ²_cr folds
    into σ²_r) the subject-level agreement/consistency equal the M3 incomplete
    `ICC(A,·)`/`ICC(C,·)` on the same ragged ratings to < 1e-4 — M9 *is* M3 with a
    cluster layer. (A single cluster is degenerate for σ²_c; used only as the
    reduction limit, per M5's O-ML/reduction note.)
- **Identifiability oracle (§4).** Seeded designs constructed to be (i) connected,
  (ii) within-cluster disconnected, (iii) cluster×rater disconnected (all raters
  confined) confirm the §4 guards accept/abort exactly where lme4 gains/loses rank.

**Regression guard:** the full existing suite — M1–M8 oracles incl. M5 O-ML and M8
O-NML — stays green (the fit, scalar divisor, and complete paths are untouched).

If any §3 coefficient or §4 guard cannot be pinned by both required oracles it is
**not shipped**, a Fable review is *recommended*, and work pauses (#1, #19).

### Slices

- **Slice 1 — incomplete Design-1 fit + identifiability + divisor.** Generalize
  `summarize_design()`/connectedness to the multilevel structure (§4b); the optional
  `design` argument + ambiguity abort (§4a); `k_eff` within the multilevel layout
  (§5); route the incomplete crossed path off the existing five-component fit (remove
  the `nested_design_balanced()` abort for the *crossed* case only). Subject-level
  agreement/consistency, single/average. Oracles O-IML/lme4, O-IML/sim, O-IML/reduction
  (→ M3), identifiability oracle. End-to-end thin slice.
- **Slice 2 — cluster level + boundaries.** Cluster-level IRR under imbalance with its
  §4b identifiability gate and abort-to-subject-level; the full boundary/guard matrix
  (§7) with snapshots. Oracles extended (→ complete M5 reduction at both levels).
- **Slice 3 — docs.** Extend `advanced.Rmd`'s multilevel section to ragged Design-1
  data on real code; `print`/`glance` surface incomplete-vs-complete, n_clusters /
  n_cells / `k_eff`, and the (declared or inferred) design; `test-vignette-claims.R`
  invariants (average ≥ single; complete reduction; single-cluster → M3).

---

## 7. Identifiability and boundaries (PRINCIPLES.md #5)

- **Ambiguous ragged design + no `design` argument** → `abort_unidentified()` (§4a).
- **Within-cluster disconnected** (some cluster's subject×rater graph splits) →
  `abort_unidentified()` naming the cluster/blocks (§4b), generalizing the M3 guard.
- **All raters confined to one cluster each** → the design is nested, not
  incomplete-crossed; abort pointing at the nested path (M8) — do not fit a crossed
  model with confounded σ²_r/σ²_cr.
- **Cluster level unidentified** (too few clusters / no cluster×rater linkage) →
  classed abort pointing at the subject level (M5 §7).
- **Near-degenerate but identified** (a rater linked by a single bridging cell, a
  subject rated once) → identified but wide intervals; the boundary-aware MC CI reports
  that honestly rather than the code refusing (M3 §3 posture).
- **Within-cell replicates** remain out of scope (reported unsupported, not folded
  into residual) — a ROADMAP item, unchanged from M3.

---

## 8. Acceptance criteria (this estimand → code)

- **Design declaration/guard:** an ambiguous ragged crossed/nested pattern aborts
  unless `design` is asserted; the argument is validated against the data; snapshots
  cover accept/abort (§4a).
- **Identifiability:** within-cluster-disconnected, cluster×rater-disconnected, and
  all-raters-confined designs abort with the right classed error and message; a
  connected ragged Design-1 design returns estimates (§4b). Pinned by the
  identifiability oracle.
- **Subject-level, incomplete data:** agreement + consistency, single + average, with
  boundary-aware MC CIs; recover known components on O-IML/sim within tolerance; match
  lme4 to < 1e-4 (O-IML/lme4) and the M3 single-cluster reduction to < 1e-4.
- **Cluster level, incomplete data:** returned when identified, else abort-to-subject;
  matches the complete-M5 reduction.
- **Divisor:** `ICC(*,1)` always reported; `ICC(*,k)` uses the multilevel `k_eff`
  (§5), surfaced in the report.
- **Balanced reduction:** every path reproduces the M5 Design-1 numbers on complete
  data (regression + correctness).
- **Reporting:** `print`/`summary`/`glance` surface incomplete-vs-complete,
  n_clusters/n_cells, `k_eff`, and the declared/inferred design.
- **Docs:** the "which ICC / when" note extends to complete-vs-incomplete multilevel;
  every path names its (inherited) estimand (PRINCIPLES.md #2, #13).

---

## 9. Out of scope for M9 (recorded for forward-compatibility)

- **Averaged cluster-level `ICC(c,k)` on incomplete data** — was an open modeling
  question here (§3b); **RESOLVED by M46 (ADR-057) → §10** with the inverse-Simpson
  harmonic divisor `k_c^eff`, for glmmTMB/lme4 (brms deferred). Single-rater
  `ICC(c,1)` ships in Slice 2; complete-data `ICC(c,k)` is unaffected (M5).
- **Incomplete nested multilevel (Designs 2/3)** — its own later slice; needs the
  ragged nested-vs-crossed inference (§4a) extended to the nested sub-designs
  (ADR-018).
- **Fixed-rater multilevel** — reuse the M3 real fixed-effect fit path (ADR-008);
  scheduled as **M10** (ADR-017).
- **lme4 for the multilevel fit** as a selectable engine (oracle-only here) — its own
  later slice (ADR-012/016).
- **Within-cell replicates** — split σ²_{(s:c)r} from pure error via
  `(1 | cluster:subject:rater)` (ROADMAP).
- **A Bayesian/MCMC cross-engine** (the paper's own estimator); a three-facet
  `d_study()` over subject-per-cluster counts; exposing the conflated single-level ICC
  (Eq. 14). (ROADMAP / M5 §8.)

---

## 10. Resolution — the averaged cluster-level `ICC(c,k)` divisor (M46, ADR-057)

M46 lifts the §3b/§9 deferral. The fit and the cluster error sets are unchanged (M5/§3b:
signal σ²_c; agreement error {σ²_r, σ²_cr}, consistency {σ²_cr}); the only new object is
the averaging divisor under imbalance.

**The divisor.** The reported cluster coefficient describes each cluster's **observed,
cells-pooled mean**, in which rater `r` carries weight `w_{c,r} =` (observed cells of `r`
in cluster `c`) / (observed cells in `c`). The effective number of raters behind that
mean is the **inverse-Simpson** count, and a single reported divisor is their harmonic
mean across clusters:

```
m_c^IS = 1 / Σ_r w_{c,r}²           (per-cluster effective rater count; = distinct raters when weights equal)
k_c^eff = 1 / mean_c(1 / m_c^IS)    (the reported averaging divisor)
```

This reduces to the rater count `k` on complete/uniform-weight data (recovering M5). It is
implemented as `cluster_k_eff()` (`R/design.R`) and surfaced on the object as `k_c_eff`.

**The general identity (name the target).** For *any* linear cluster score with weights
`w` summing to 1, the marginal per-cluster error is `(σ²_r + σ²_cr)·Σw²` (agreement) /
`σ²_cr·Σw²` (consistency), so the effective count is always `1/Σw²`. **Every candidate
divisor is exact for *some* score** — the cell-pooled mean gives inverse-Simpson; a
rater-balanced mean (average each rater's cluster-mean, then average raters) gives the
distinct-count harmonic. No simulation can adjudicate the *target*; it is a commitment.
The package reports the **cell-pooled** target (matching §5's "observed subject means" and
ADR-057's "realized cluster means"; GT decision-study logic; ten Hove et al. 2022 p. 14
*bracket* k = 3/5 under this exact imbalance, and inverse-Simpson = 4.5 sits inside their
bracket). A future score variant is a weight swap, not a re-derivation.

**Exactness — both types (resolves §5's hedge at the cluster level).** `k_c^eff` is
**exact for agreement as well as consistency**: the agreement (absolute) coefficient
averages each cluster's *marginal* absolute error, into which cross-cluster rater-sharing
covariance does not enter. There is **no** effective-`k` approximation at the cluster level
(cf. §5 — that hedge is over-cautious; see the §5 note).

**Oracles (#1, Fable-blessed — ADR-057 Am.1).** No textbook worked example, so ≥2
independent legs (`data-raw/oracle-cluster-ck-incomplete.R`): **O-cluster-score** — a
score-based, **weight-free** empirical reliability (paired fresh-rater replicates, plain
cluster cell means; the T1 `mc_truth` alone is tautological for the target) that the
inverse-Simpson plug-in recovers, with distinct-count **refuted** (> 0.1 Φ bias under
extreme imbalance); **O-cluster-fit** — ship-path glmmTMB REML fit + plug-in at `k_c^eff`
from estimated components; **O-cluster-lme4** — cross-engine components < 1e-4;
**O-cluster-reduction** — complete data → `k_c^eff = k` exact. **Coverage** (#12,
`data-raw/oracle-cluster-ck-coverage.R`, n_rep = 240): the boundary-aware MC interval is
nominal across a C_n = {8, 20, 60} axis + heterogeneous-`m_c` + extreme-imbalance +
boundary σ²_c ≈ 0 cells (min coverage ≈ .91, no C_n decay); target defined per frozen
realized design.

**Ragged-consistency ordering caveat (documentation, not a divisor bug).** On ragged data,
rater main effects do **not** fully cancel from the *observed ordering* of cluster means
(they cancel only under identical rater weight profiles): the leftover ≈ `σ²_r·mean_c Σ_r
(w_{c,r} − w̄_r)²` measures ~2× the entire consistency error on typical ragged designs.
`ICC_c(C, k_c^eff)` remains correct **as the inherited component-based estimand** (rater
disagreement σ²_cr only); users comparing observed ragged cluster means should prefer
`ICC_c(A, k_c^eff)`, whose error term bounds the ordering contamination. (Same
distinction-family as M45's conflation caveat.)

**Scope.** Crossed Design 1, random raters, glmmTMB/lme4 (variance ratio — no θ²
correction). **brms deferred** (its variance-ratio push-forward would fold in but is not
yet oracle-validated — a candidate). Incomplete/unbalanced cluster-level **fixed**
`ICC(c,k)` stays double-blocked, but M46 removes one of its two blocks (this divisor).

---

## References

- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater reliability
  for multilevel data: A generalizability theory approach. *Psychological Methods,
  27*(4), 650–666. (Design 1 estimands, inherited unchanged; see M5 spec.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines on
  selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979. (Model-based ICCs for incomplete designs.)
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
  (Estimability under missing cells; connectedness of a classification.)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of connectedness
  in an N-way cross classification. *Technometrics, 6*(3), 319–324.
- (Full provenance for any asserted numeric value is registered in `REFERENCES.md`
  when the O-IML oracle values are committed, Slices 1–2.)
</content>
</invoke>
