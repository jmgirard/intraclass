# Estimand specification — M3: imbalanced & incomplete designs

**Scope of this document.** The precise population definitions the Milestone 3
estimators must target when the subject×rater design is **ragged** — not every
subject is rated by every rater (missing cells). M3 keeps **one rating per
*observed* cell** (within-cell replicates remain a ROADMAP item) but drops M1/M2's
balanced-complete assumption. It covers two paths:

1. **random raters on incomplete data** — the default; the M1/M2 mixed-model fit
   already handles imbalance, so the additions are an identifiability guard and a
   rule for the averaging divisor; and
2. **fixed raters via a *real* fixed-effect fit** — resolving the ADR-006 debt: on
   incomplete data the M2 "label layer over the random fit" is no longer valid, so
   `raters = "fixed"` gets its own fit `score ~ 1 + rater + (1 | subject)`.

This builds directly on
[`M1-twoway-random-agreement.md`](M1-twoway-random-agreement.md) and
[`M2-consistency-and-fixed.md`](M2-consistency-and-fixed.md); the measurement model,
the estimable variance components (σ²_s, σ²_r, σ²_res), and the
`(signal, {error set}, divisor)` representation are inherited unchanged and not
repeated. Read those first.

Per PRINCIPLES.md #1/#4 this spec **names estimands and cites sources**; it does
**not** assert reference *values*. Numeric correctness for every coefficient is
established later by the Slice 1/2 oracles (§8), against ≥2 independent oracles each.

---

## 1. What M3 adds to the abstraction

M1/M2 fixed the internal representation so that widening the family is a change of
*data*, not code paths. M2 exercised the `type` (error set) and `raters` (design)
knobs on balanced data. M3 changes the **design's completeness** and, as a
consequence, two things that balance had been hiding:

| Concern | Balanced (M1/M2) | Incomplete (M3) |
|---|---|---|
| Identifiability of σ²_s vs σ²_r | automatic (orthogonal) | requires a **connected** design (§3) |
| Averaging divisor `k` for `ICC(*,k)` | unambiguous (= raters/subject) | **ill-defined** on ragged counts → a convention (§5) |
| `raters = "fixed"` | label layer over the random fit (ADR-006) | **its own fixed-effect fit** (§6) |

The signal is still σ²_s; the four coefficients' error sets and divisors are as in
M2. What changes is *when they are identified* and *how `k` and the fixed fit are
defined*.

Notation: `n` subjects, `k` = number of distinct raters in the design, `N` total
ratings, `n_i` = ratings for subject *i* (≤ k), `m_j` = ratings by rater *j*. Balanced
⇔ every `n_i = k` (so `N = nk`).

---

## 2. The fit is unchanged; imbalance is native

The random-rater model is exactly M1's, fit by REML:

```r
score ~ 1 + (1 | subject) + (1 | rater)
```

A mixed model estimates variance components by (RE)ML from the likelihood, not from
balanced ANOVA mean-square identities, so it consumes ragged data directly — this is
the package's core differentiator over ANOVA/mean-square tools (`psych`, `irr`),
which require complete data or listwise-delete to get it (ROADMAP; ten Hove et al.
2024). No new engine or CI machinery is needed for the random path; the boundary-aware
Monte-Carlo CI (ADR-003) samples the same three components. **What imbalance costs**
is (a) the ANOVA≡REML equivalence that made balanced oracles exact — so M3 oracles are
simulation/independent-package based (§8), not textbook worked values — and (b) the
free identifiability and the free definition of `k`, addressed next.

---

## 3. Identifiability under incompleteness — the connectedness rule (PRINCIPLES.md #5)

Separating the subject and rater structure (hence σ²_s and σ²_r) on a design with
missing cells requires the design to be **connected**: form the bipartite graph with
one node per subject, one per rater, and an edge for each *observed* (subject, rater)
cell. The design is connected when this graph has a **single connected component**.

- **Connected** ⇒ every subject/rater effect is tied into one estimable network;
  σ²_s and σ²_r are jointly separable and all four coefficients are identified.
- **Disconnected** (≥2 components) ⇒ between-component differences are **aliased**
  between the subject and rater classifications: a shift attributable to subjects in
  one block is indistinguishable from a shift attributable to raters, so σ²_s and
  σ²_r cannot be jointly separated. The mixed model may still return numbers (partial
  pooling regularizes the singular direction), but they are **not identified** — a
  textbook PRINCIPLES.md #5 case.

**Decision:** `icc()` detects connectedness before reporting a two-way coefficient
and, on a disconnected design, aborts via `abort_unidentified()` with a message that
names the disconnected blocks and points the user at a one-way ICC (a later
milestone) or at collecting linking ratings. This generalizes the existing M1 guards
(≥2 raters, ≥2 subjects), which are the complete-data special case.

Connectedness of a two-way classification is the standard estimability condition for
crossed designs with empty cells (Searle, Casella & McCulloch 2006; Weeks & Williams
1964). Minimum-size and near-degenerate cases (e.g. a rater linked by a single cell)
remain identified but yield wide intervals; the boundary-aware MC CI reports that
honestly rather than the code refusing.

---

## 4. Random-rater estimands under imbalance

The four coefficients are unchanged as *population* definitions (M2 §2, §4); only the
divisor `k` for the average needs a rule (§5). With REML all components are ≥ 0, so
every coefficient stays in [0, 1].

| Coefficient | Signal | Error set | Divisor |
|---|---|---|---|
| ICC(A,1) | σ²_s | {σ²_r, σ²_res} | 1 |
| ICC(A,k) | σ²_s | {σ²_r, σ²_res} | k |
| ICC(C,1) | σ²_s | {σ²_res} | 1 |
| ICC(C,k) | σ²_s | {σ²_res} | k |

`ICC(*,1)` is always well-posed (a single rating needs no divisor). `ICC(*,k)`
requires a defined `k` (§5).

---

## 5. The `ICC(*,k)` averaging divisor under imbalance (decision → ADR-008)

On ragged data subjects have unequal rating counts `n_i`, so "the reliability of the
mean of `k` raters" has no single self-evident divisor. Both candidate rules are the
**same object** — the generalizability-theory dependability
`Φ(m) = σ²_s / (σ²_s + error/m)` evaluated at some number of raters `m` — differing
only in *which* `m` the plain label "average" should default to.

**Decision (pinned):** report `ICC(*,1)` always; for the average, use the **effective
number of ratings behind the observed subject means**,
`m = k_eff = 1 / mean(1/n_i)` (the harmonic mean of the per-subject counts `n_i`).
This is the standard effective-sample-size for a mean whose backing counts vary: it
is exactly the `m` at which `error/m` equals the *average across subjects* of the
realized per-subject error variance `error/n_i` (a mean of `1/n_i` terms is
`1/`harmonic-mean). So `ICC(*,k)` describes the reliability of the ragged averages the
analyst **actually computed**, not a design they did not run. It reduces to the
balanced `k` when data are complete (all `n_i = k ⇒ k_eff = k`). `icc()` reports
`k_eff` so the divisor is transparent.

**Projection to other `m` is a separate, explicit operation — not the default.**
Asking "how reliable would the mean of `m` raters be?" for an `m` other than the one
collected — the complete `k`-rater design (`m = n_raters`), or a curve over
`m = 1…M` — is a D-study *extrapolation* (Brennan 2001; ten Hove et al. 2024). It is
deliberately kept out of the plain "average" label and housed in a future
`d_study()` / `project_raters()` function (ROADMAP) where the user names `m`. This
separates the descriptive question ("what precision did I get") from the inferential
one ("what if I ran a different design") and avoids silently reporting an
extrapolation to a design that was never run.

**Caveat banked for implementation (agreement vs. consistency).** For **consistency**
`k_eff` is exact: the error is `σ²_res` only, and `σ²_res / k_eff` matches the average
per-subject error variance by construction. For **absolute agreement** the rater
main-effect term `σ²_r` divides by `m` only under the GT reading "average over `m`
freshly sampled raters" — each subject's realized mean averages a *different* rater
subset, so a per-subject `σ²_r` reduction is not a clean `/n_i`. Using `k_eff` for
both terms applies one consistent effective number of raters: exact for C, an
effective-`k` approximation for A, which the report notes and the boundary-aware MC CI
reflects honestly.

**Oracle-first (PRINCIPLES.md #1).** The `k_eff` formula and its use in each
coefficient are pinned in Slice 1 against a hand computation and the O5 seeded
simulation (define `Φ(k_eff)` from the known components and the realized design and
check recovery); `irrNA`/`psych` are used only where they compute this same estimand,
not assumed to share the convention. Recorded in ADR-008.

---

## 6. Fixed raters via a real fixed-effect fit (resolves ADR-006)

On **balanced** data M2 showed (O4) that fitting raters as a random intercept vs. as
fixed effects returns identical σ²_s and σ²_res, so `raters = "fixed"` could reuse the
random fit as a label layer. That equivalence is a balanced-data phenomenon and
**breaks under imbalance**: random-rater partial pooling shifts σ²_s once the design
is non-orthogonal (ADR-006; M2 §6 records ΔICC(C,1) ≈ 0.0095 after dropping 4 of 24
cells, from the committed `data-raw/oracle-fixed-vs-random.R`). M3 therefore gives
`raters = "fixed"` its **own fit**:

```r
score ~ 1 + rater + (1 | subject)
```

Raters enter as **fixed effects** (`α_1, …, α_k`, one per rater, sum-to-zero or
reference-coded), so there is no σ²_r variance component; the estimable pieces are
σ²_s (subject random intercept) and σ²_res (residual), plus the estimated rater
effects `α̂_j` and their covariance.

### Fixed consistency — Case 3

Consistency conditions on the raters, so the rater main effect is excluded from the
error entirely:

```
ICC(C,1)_fixed = σ²_s / (σ²_s + σ²_res)          (McGraw & Wong 1996, Case 3; SF ICC(3,1))
ICC(C,k)_fixed = σ²_s / (σ²_s + σ²_res / k)                                    (SF ICC(3,k))
```

This is the single most commonly reported "ICC3". `k` is the §5 effective number of
ratings `k_eff`.

### Fixed absolute agreement — Case 3A

Absolute agreement counts systematic rater level differences as error. With raters
fixed, the analog of σ²_r is the **finite-population variance of the k estimated rater
effects**:

```
θ²_r = Σ_j (α̂_j − ᾱ)² / (k − 1)

ICC(A,1)_fixed = σ²_s / (σ²_s + σ²_res + θ²_r)
ICC(A,k)_fixed = σ²_s / (σ²_s + θ²_r + σ²_res / k)      (θ²_r is a per-rater level term)
```

θ²_r is the fixed-rater counterpart of σ²_r: it summarizes how far the specific raters
sit apart in level, treated as *these* raters (no super-population). Under balance,
θ²_r's method-of-moments estimator equals σ²_r's — which is exactly why fixed ≡ random
on balanced data (M2 §3, O4) and why they diverge under imbalance.

**Oracle-first caveat (PRINCIPLES.md #1, #18).** The precise normalization of θ²_r
(the `k − 1` divisor and how it enters `ICC(A,k)`), and its propagation into the MC CI,
are **asserted by oracle in Slice 2**, not by these formulas alone. Slice 2 pins them
against `psych::ICC` (which implements the McGraw–Wong coefficient formulas), `irrNA`
on incomplete data, a seeded simulation, and the balanced reduction (§7) before any
number is committed. If they cannot be pinned by ≥2 independent oracles, the fixed
absolute-agreement coefficient is **not shipped** and a Fable review is *recommended*
(#19).

### CI for the fixed path

The MC draw must sample the fixed rater effects `α̂` (from `vcov(fit, full = TRUE)`,
which now includes them) alongside σ²_s and σ²_res, recomputing θ²_r — and hence the
agreement coefficients — per draw. This is a new sampler branch keyed on
`design$raters == "fixed"`; the random path is untouched. Consistency needs only σ²_s
and σ²_res per draw (θ²_r not used), as today.

### Guardrail unchanged, wording corrected

`raters = "fixed"` still emits the classed `intraclass_fixed_raters` warning (random
is the recommended default; fixed forgoes generalization). The roxygen `raters` note
in `R/icc.R` — which currently states the point estimate and interval are "identical
either way" — is **corrected**: that holds only on balanced data; on incomplete data
the fixed fit gives genuinely different (and correct) numbers.

---

## 7. Balanced reduction (the regression guarantee)

Every M3 path must reproduce the M1/M2 results on **complete** data, which is both a
correctness check and a regression guard:

- random path on the full Shrout & Fleiss data → ICC(A,1)=0.290, ICC(A,k)=0.620,
  ICC(C,1)=0.715, ICC(C,k)=0.909 (O1–O2, unchanged);
- fixed **real fit** on the full SF data → the same four numbers (extends O4 from
  "shared fit gives the same number" to "an *independent* fixed-effect fit gives the
  same number"), matching `psych::ICC` ICC3/ICC3k and the ANOVA MoM.

Only once these hold do the incomplete-data assertions (§8) carry weight.

---

## 8. Oracle set (PRINCIPLES.md #1, #4 — the gating risk)

No textbook worked example exists for arbitrary unbalanced data, so correctness rests
on independent, reproducible oracles, assembled and run via `/verify-estimator`:

| Oracle | Role | Path(s) |
|---|---|---|
| **Seeded unbalanced simulation** (known σ²_s, σ²_r, σ²_res; MCAR/MAR missingness) → **O5** | primary; recovers population components on ragged data | random + fixed |
| **lme4 cross-check** — refit `(1\|subject)+(1\|rater)` and `+ rater` in lme4, match to ~1e-4 | independent engine | random + fixed |
| **`irrNA`** (and/or `gtheory`) on incomplete data → **O6** | established package, incomplete-data ANOVA-type ICCs incl. Case 3 | random + fixed |
| **Balanced reduction** (§7) to O1–O4 | regression + pins fixed real-fit | random + fixed |

O5/O6 are committed, seeded scripts under `data-raw/` (extending
`data-raw/oracle-fixed-vs-random.R`, which already reproduces the imbalance
divergence). Register both in `ORACLES.md` with provenance when their values are
asserted (Slices 1–2). **Availability check:** confirm `irrNA`/`gtheory` compute the
intended coefficients before relying on them; if a coefficient cannot be pinned by ≥2
independent oracles, it is not shipped and a Fable review is recommended (#19).

---

## 9. Acceptance criteria (this estimand → code)

- **Connectedness:** a disconnected subject×rater design aborts via
  `abort_unidentified()`; a connected but incomplete design returns estimates. Tested
  with snapshots (PRINCIPLES.md #5, #10).
- **Random path, incomplete data:** all four coefficients returned with
  boundary-aware MC CIs; recover known population components on the O5 simulation
  (within a stated tolerance) and match lme4 to ~1e-4 and `irrNA` on the O6 design.
- **Divisor:** `ICC(*,1)` always reported; `ICC(*,k)` uses the effective number of
  ratings `k_eff` = harmonic mean of the per-subject counts (§5), and `k_eff` is
  surfaced in the report.
- **Fixed path, incomplete data:** `raters = "fixed"` uses the real fixed-effect fit
  and returns numbers that **differ** from `raters = "random"` on the O6 incomplete
  design (asserted directly), matching lme4's fixed-effect fit and Case 3 / SF
  `ICC(3,*)` where `irrNA`/`psych` provide them.
- **Balanced reduction:** both paths reproduce O1–O4 on the complete SF data.
- **Reporting:** `print`/`summary`/`glance` surface balanced-vs-incomplete,
  n_obs/n_cells, and the divisor/projection; `raters` roxygen note corrected.
- **Docs:** the "which ICC / when" note extends to complete-vs-incomplete and the
  fixed real-fit; every new coefficient names its estimand (PRINCIPLES.md #2, #13).

---

## 10. Out of scope for M3 (recorded for forward-compatibility)

- **The flagship *Choosing an ICC* vignette** — its own milestone now (M4, ADR-007).
- **Within-cell replicates** — splitting σ²_sr from σ²_e via `(1 | subject:rater)`
  (ROADMAP).
- **One-way designs** — ICC(1)/ICC(k), raters not crossed; the natural fallback the
  connectedness abort points toward (later milestone).
- **lme4 as a *selectable* engine + bootstrap CI** — engine work, its own slice.
- **D-study projection API** — `Φ(m)` at an arbitrary or complete-design number of
  raters (`m ≠ k_eff`, e.g. `m = n_raters`) and the reliability curve; the explicit
  home for the projection question §5 keeps out of the plain "average" (ROADMAP).

---

## References

- Brennan, R. L. (2001). *Generalizability Theory.* Springer. (D-studies; projecting
  the dependability coefficient to `n'_r` raters.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
  (Cases 2 and 3; consistency vs. absolute agreement; the θ²_r fixed-rater term.)
- Searle, S. R., Casella, G., & McCulloch, C. E. (2006). *Variance Components.* Wiley.
  (Estimability under missing cells; connectedness of a two-way classification.)
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines on
  selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979. (Model-based ICCs for incomplete designs; random vs. fixed raters.)
- Weeks, D. L., & Williams, D. R. (1964). A note on the determination of connectedness
  in an N-way cross classification. *Technometrics, 6*(3), 319–324.
