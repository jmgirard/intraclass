# Estimand specification — M2: consistency variants + fixed-vs-random raters

**Scope of this document.** The precise population definitions the Milestone 2
estimators must target: the **consistency** coefficients `ICC(C,1)` / `ICC(C,k)`
for a two-way design, and the **fixed-vs-random rater** distinction, both built on
the M1 mixed-model pipeline. M2 stays within **balanced, complete** data (one
rating per subject×rater cell); incomplete/unbalanced designs are M3. This spec is
what the M2 oracle tests encode; the code must satisfy it.

It builds directly on
[`M1-twoway-random-agreement.md`](M1-twoway-random-agreement.md); the measurement
model (§1), identifiability caveat, and the mixed-model estimation of σ²_s, σ²_r,
σ²_res are inherited unchanged and not repeated. Read that first.

Everything numeric below is verified two ways: (a) the population definitions
reduce algebraically to the McGraw & Wong (1996) / Shrout & Fleiss (1979)
estimators, and (b) a committed, seeded R script reproduces the values from the SF
worked example against `psych::ICC`, ANOVA mean squares, and both engines — see §6.

---

## 1. What M2 adds to the M1 abstraction

M1 fixed the internal representation of an ICC as
`(signal component, {error component set}, averaging divisor)` so that widening the
family is a change of *data*, not code paths (M1 spec §5). M2 exercises two of
those knobs:

| Knob | M1 value | M2 adds |
|---|---|---|
| Error set (**type**) | agreement = {rater, residual} | **consistency = {residual}** |
| Design interpretation (**raters**) | random (Case 2) | **fixed (Case 3)** |
| Averaging divisor (**unit**) | 1, k | (unchanged) |

The signal is always the subject variance σ²_s. The `unit` divisor is unchanged.
`type` and `raters` are the M2 additions.

---

## 2. Consistency estimands (population definitions)

Consistency asks whether raters *rank order* subjects the same way, tolerating a
constant per-rater offset. It therefore **drops the rater main effect σ²_r from
the error** — the one term absolute agreement adds. Everything else is as in M1.

### ICC(C,1) — single rater, consistency

```
                     σ²_s
ICC(C,1) = ─────────────────────      (estimable, single-rating design)
               σ²_s + σ²_res
```

### ICC(C,k) — mean of k raters, consistency

```
                     σ²_s
ICC(C,k) = ─────────────────────      (estimable form)
             σ²_s + σ²_res / k
```

Averaging over k raters divides the (now single-term) error by k; the signal is
unchanged, exactly as for agreement.

### Relationship to agreement

`ICC(C,·) ≥ ICC(A,·)` always, with equality iff σ²_r = 0 (no systematic rater
level differences). The gap `ICC(C,·) − ICC(A,·)` is a direct read-out of how much
systematic rater disagreement is present — a large gap is a rating-procedure
problem worth fixing (teaching note, §8 of the M1 spec). On the SF data the gap is
large (0.715 vs 0.290) because the raters differ sharply in mean level.

### Range

With REML all components are ≥ 0, so `ICC(C,·) ∈ [0, 1]`.

---

## 3. Fixed vs. random raters — a label/interpretation layer (balanced data)

`raters = "random"` (M1 default, Case 2) treats the k raters as a sample from a
rater universe we generalize to. `raters = "fixed"` (Case 3) treats them as the
entire population of interest.

### The key result (verified, not assumed)

McGraw & Wong (1996) derived, in the **ANOVA** framework, that for a *given*
definition (A or C) the Case 2 and Case 3 point-estimate formulas are identical —
random-vs-fixed is interpretive, and it is the A-vs-C choice that changes the
arithmetic. Because our engine is a **mixed model**, not ANOVA, this equivalence
had to be re-verified for REML estimation, including the case where raters are
actually modeled as *fixed effects* (`score ~ 1 + rater + (1 | subject)`) rather
than a random intercept. On **balanced, complete** data it holds **exactly** (to
optimizer tolerance): fitting raters random vs fixed returns the same σ²_s and
σ²_res, hence the same ICC(C,·) and ICC(A,·). Numbers in §6.

**Consequence for M2:** `raters = "fixed"` does **not** require a separate fit. M2
fits the single random-effects model from M1 and treats `fixed` as a
**label/interpretation layer**: it changes the reported design (two-way *mixed*
vs *random*), the Shrout–Fleiss equivalent label (Case 3 vs Case 2), and the
generalization statement in the docs/interpretation — **not** the number.

### Critical scope boundary — this breaks under imbalance (M3)

The equivalence is a **balanced-data** phenomenon: it rests on the orthogonality
that also gives REML ≡ ANOVA method-of-moments (M1 spec §4). On **unbalanced /
incomplete** data it **fails** — random-rater partial pooling shifts σ²_s, so a
random-effects fit and a fixed-effects fit give genuinely different ICCs (§6 shows
ΔICC(C,1) ≈ 0.01 after dropping 4 of 24 cells; it grows with sparsity and
rater-mean spread). Therefore:

> **M3 MUST revisit fixed raters.** When incomplete designs arrive, `raters =
> "fixed"` can no longer reuse the random-effects fit; it needs its own
> fixed-effect fit path (`+ rater`), or the label layer must be guarded to balanced
> designs and abort/warn otherwise. The M2 label-layer decision is valid **only
> because M2 is balanced**, and this boundary is recorded so the M3 author inherits
> it rather than rediscovering it. See ADR-006.

### Best practice — random is recommended, fixed is opt-in

Random-effects treatment of raters is the recommended default for interrater
reliability: it is what lets you generalize a reliability estimate beyond the
specific raters in the study (ten Hove et al. 2024; McGraw & Wong 1996 Case 2).
Fixed raters answer a narrower question ("how reliable are *these* raters, with no
generalization"), which is rarely the intended one. M2 therefore:

- keeps `raters = "random"` the default;
- **allows** `raters = "fixed"` (opt-in, well-posed, returns a valid number);
- emits a **loud, classed `cli` warning** (`intraclass_fixed_raters`) whenever
  `"fixed"` is chosen, stating that random is best practice and fixed forgoes
  generalization. The warning is suppressible by class for the genuine fixed-rater
  user. This is a *warning*, not an `abort_*` — fixed raters is not an ill-posed
  design (PRINCIPLES.md #5 governs ill-posed designs), just usually not what the
  analyst wants.

---

## 4. Estimation via the mixed model (unchanged fit, wider read-out)

Fit, by REML, exactly the M1 model:

```r
score ~ 1 + (1 | subject) + (1 | rater)
```

Extract σ²_s, σ²_r, σ²_res as in M1. Then the four M2 coefficients are choices of
the error set and divisor over the *same* components:

| Coefficient | Signal | Error set | Divisor |
|---|---|---|---|
| ICC(A,1) | σ²_s | {σ²_r, σ²_res} | 1 |
| ICC(A,k) | σ²_s | {σ²_r, σ²_res} | k |
| ICC(C,1) | σ²_s | {σ²_res} | 1 |
| ICC(C,k) | σ²_s | {σ²_res} | k |

`raters ∈ {random, fixed}` multiplies each of these into the McGraw–Wong Case
2/Case 3 interpretation **without changing the value** (balanced data, §3). The
Monte-Carlo CI is unchanged: consistency simply omits the `rater` draw from the
error sum per draw, which the `(signal, {error}, divisor)` representation already
supports (M1 `icc_point()` operates element-wise over the error set).

---

## 5. Labeling — McGraw & Wong ↔ Shrout & Fleiss

The reported `index` label stays in McGraw & Wong notation (`ICC(A/C, 1/k)`), which
is design-agnostic. The **design** and the Shrout–Fleiss equivalent are surfaced in
`print`/`summary` so the random-vs-fixed choice is visible even though the number
is shared:

| type | raters | McGraw–Wong | Shrout–Fleiss | Design phrase |
|---|---|---|---|---|
| agreement | random | ICC(A,1)/(A,k) | ICC(2,1)/(2,k) | two-way random, absolute agreement |
| consistency | random | ICC(C,1)/(C,k) | ICC(2,1)*/… | two-way random, consistency |
| agreement | fixed | ICC(A,1)/(A,k) | — (unusual) | two-way mixed, absolute agreement |
| consistency | fixed | ICC(C,1)/(C,k) | ICC(3,1)/(3,k) | two-way mixed, consistency |

\* Shrout & Fleiss label the random-rater consistency case ICC(2,·) only loosely;
the canonical ICC(3,·) is the **mixed** (fixed-rater) consistency coefficient — the
single most commonly reported "ICC3". This is precisely why exposing `raters` is
worth the small surface: it names the difference between ICC(2,·) and ICC(3,·)
without changing the balanced-data arithmetic.

---

## 6. Worked verification (Shrout & Fleiss 1979 data)

Data as in the M1 spec §6 (6 subjects × 4 raters, one rating per cell). ANOVA:
BMS = 11.24167, JMS = 32.48611, EMS = 1.01944; MoM components σ²_s = 2.55556,
σ²_r = 5.24444, σ²_res = 1.01944.

### Consistency coefficients

```
ICC(C,1) = 2.55556 / (2.55556 + 1.01944)       = 2.55556 / 3.575   = 0.71484 → 0.715 ✓
ICC(C,k) = 2.55556 / (2.55556 + 1.01944/4)     = 2.55556 / 2.81042 = 0.90932 → 0.909 ✓
```

Both match `psych::ICC` ICC3 = 0.71484 and ICC3k = 0.90932 to 5 dp.

### Fixed ≡ random on balanced data (the M2-specific check)

A committed seeded script fits raters random (`(1|rater)`) and fixed (`+ rater`)
via `lme4`/`glmmTMB` and compares:

| Fit | σ²_s | σ²_res | ICC(C,1) | ICC(A,1) |
|---|---|---|---|---|
| ANOVA MoM | 2.55556 | 1.01944 | 0.71484 | 0.28976 |
| Random raters (glmmTMB) | 2.55560 | 1.01944 | 0.71484 | 0.28977 |
| Random raters (lme4) | 2.55556 | 1.01944 | 0.71484 | 0.28976 |
| **Fixed raters (lme4)** | 2.55556 | 1.01944 | 0.71484 | 0.28976 |

|σ²_s random − σ²_s fixed| ≈ 4e-5, |σ²_res random − σ²_res fixed| ≈ 4e-7 — optimizer
tolerance, i.e. exact. **The equivalence survives REML estimation on balanced
data.**

### The boundary — imbalance breaks it (records the M3 caveat, not asserted in M2)

Dropping 4 of 24 cells and refitting:

| Fit | σ²_s | ICC(C,1) |
|---|---|---|
| Random raters | 2.658 | 0.68436 |
| Fixed raters | 2.573 | 0.67485 |

ΔICC(C,1) ≈ 0.0095 — the label layer is no longer valid. M2 does not touch
incomplete data, so this is documentation for M3, not an M2 test assertion.

---

## 7. Acceptance criteria (this estimand → code)

- On the SF data: `ICC(C,1)` rounds to 0.715 and `ICC(C,k)` to 0.909; both match
  `psych::ICC` ICC3/ICC3k to 1e-4 (balanced ⇒ near-exact).
- `raters = "fixed"` returns the **same** point estimates and CIs as
  `raters = "random"` for the matching `type` (balanced-data equivalence,
  asserted directly as an oracle test).
- `raters = "fixed"` emits a classed `intraclass_fixed_raters` warning; `raters =
  "random"` is silent.
- `ICC(C,·) ≥ ICC(A,·)` on the SF data, strictly (σ²_r > 0).
- Both consistency coefficients lie in [0, 1]; `ICC(C,k) > ICC(C,1)`.
- The estimand (signal, error set, divisor, design) and the random-vs-fixed
  guidance are documented in the roxygen "which ICC / when" note.

---

## 8. Decision guidance (teaching note for the docs/vignette)

- **Consistency vs agreement.** Use **agreement (A)** when the *value* matters and
  raters must agree on the actual number (clinical scores, measurements); a
  constant rater offset counts against you. Use **consistency (C)** when only rank
  order matters and a fixed per-rater offset is acceptable (e.g. downstream
  analysis uses only relative standing).
- **Random vs fixed raters.** Prefer **random** — it is what lets you generalize a
  reliability estimate to raters beyond those in the study, which is almost always
  the point of a reliability study. Use **fixed** only when the raters in hand are
  the entire population you will ever use and you will never generalize; the
  package warns when you choose it.
- **The C−A gap** is a diagnostic: large gap ⇒ big systematic rater level
  differences ⇒ fix the rating procedure before trusting the ratings.

---

## 9. Out of scope for M2 (recorded for forward-compatibility)

- **Incomplete / unbalanced designs** — where the fixed≡random equivalence breaks
  (§3, §6); fixed raters will need a real fixed-effect fit path. *(M3)*
- **One-way** ICC(1)/ICC(k) — raters not crossed. *(later)*
- **lme4 as a selectable engine + bootstrap CI** — engine work orthogonal to the
  estimand family; its own slice (was parked at "M2" by ADR-005, now deferred by
  ADR-006).
- **D-study projection** to arbitrary k (numeric `unit` / `d_study()` / reliability
  curve) — supported by the abstraction but its own slice (ROADMAP).

---

## References

- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46 (+ errata p. 390).
- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin, 86*(2), 420–428.
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2024). Updated guidelines on
  selecting an ICC for interrater reliability. *Psychological Methods, 29*(5),
  967–979.
