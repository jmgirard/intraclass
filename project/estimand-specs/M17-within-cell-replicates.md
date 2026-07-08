# Estimand specification — M17 Slice 3: within-cell replicates

**Scope of this document.** The population quantities targeted when a subject×rater
cell is rated **more than once** — *within-cell replicates* — which let the
single-rating residual σ²_res split into the **subject×rater interaction σ²_sr**
and **pure within-cell error σ²_e**. It builds on
[`M1-twoway-random-agreement.md`](M1-twoway-random-agreement.md) /
[`M2-consistency-and-fixed.md`](M2-consistency-and-fixed.md) (the two-way random
estimand and the agreement/consistency, single/average knobs) and
[`M4.5-d-study.md`](M4.5-d-study.md) (the divisor generalization) — read those
first. Ships on branch `m17-varcomp-trio` (M17 Slice 3, ADR-026).

**Design decisions (ADR-026 deferred these to spec time; resolved with the
maintainer 2026-07-08):**
- **Occasions are nested / exchangeable within a cell** (not a crossed third
  facet): replicates are repeated ratings that identify pure error; there is **no
  occasion main effect and no occasion column**. Multiple rows in a cell *are* the
  replicates (the data API — §5).
- **Coefficients:** the standard ICC family, now fit with the interaction
  explicitly modeled and σ²_sr / σ²_e reported separately, **plus** an
  **occasion-averaged** generalizability coefficient (reliability of the mean of
  `n_o` replicates), exposed by a new **`occasions`** knob parallel to `unit`.
- **Scope:** two-way **random** raters, single-level, **balanced/complete
  replicated** data (every cell rated the same number of times `n_o ≥ 1`, complete
  crossing). Fixed-rater, one-way, multilevel, and **ragged/incomplete** replicates
  are deferred (§7). Stays M17 (not spun into M18).

**Source (#1, #2, #4).** The two-way random-effects model **with interaction and
replication** is standard: Shrout & Fleiss (1979) describe the two-way model;
McGraw & Wong (1996) name the interaction-in-error choice for random raters; the
occasion-averaged (two-facet decision-study) form is generalizability theory
(Brennan 2001). Oracles are the balanced ANOVA mean-squares closed form, an
independent `lme4` fit, and a seeded simulation (§6) — **no `gtheory` dependency**.

---

## 1. Measurement model

With `n_o ≥ 2` ratings in (enough) cells, fit

```
score ~ 1 + (1 | subject) + (1 | rater) + (1 | subject:rater)
```

giving **four** variance components (the single-rating residual σ²_res of M1 is
`σ²_sr + σ²_e`):

| component (this spec) | symbol | meaning |
|---|---|---|
| `subject`        | σ²_s  | between-subject true score (signal) |
| `rater`          | σ²_r  | rater main effect (leniency) |
| `subject_rater`  | σ²_sr | subject×rater interaction (stable disagreement) — **new** |
| `residual`       | σ²_e  | pure within-cell error (rating noise) — now *not* confounded |

`n_o = 1` (no replicates) is the M1 design and still aborts to that path — this
spec engages only when replicates are present.

---

## 2. Two averaging facets → per-component error divisors

The reliability of the mean of **`n_r` raters × `n_o` occasions** is
`σ²_s / (σ²_s + error)`, where averaging reduces each error component by the facets
that average it out:

| error component | reduced by | divisor |
|---|---|---|
| σ²_r (rater main effect, **agreement only**) | raters | `n_r` |
| σ²_sr (interaction) | raters | `n_r` |
| σ²_e (pure error) | raters **and** occasions | `n_r · n_o` |

```
Φ(n_r, n_o) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/n_r + σ²_e/(n_r·n_o))      (agreement)
Eρ²(n_r,n_o)= σ²_s / (σ²_s + σ²_sr/n_r + σ²_e/(n_r·n_o))               (consistency)
```

At `n_o = 1` these reduce to the ordinary ICC(A,·)/ICC(C,·) with a confounded
residual σ²_res = σ²_sr + σ²_e — so **the single-occasion ICC family is numerically
unchanged** from a correct one-rating-per-cell analysis; the replicate model just
(a) fits it correctly and (b) exposes σ²_sr and σ²_e.

**Estimand representation change (the load-bearing generalization).** M1 stored one
scalar `divisor` shared by the whole error set; `icc_point()` did
`signal/(signal + sum(error)/divisor)`. Because σ²_e now divides by `n_r·n_o` while
σ²_r, σ²_sr divide by `n_r`, the estimand gains **`error_divisors`** — a numeric
vector parallel to `error`, one divisor per component. `icc_point()` becomes
`signal / (signal + Σ_c error_c / error_divisor_c)`. For **every existing
estimand** all divisors are equal (`resolve_divisor(unit, k_eff)`), so this is a
backward-compatible refactor (verified: M1–M16 suites stay green). This is the
per-component divisor M5 §4 shelved — now required by the occasion facet.

---

## 3. The `occasions` knob (API)

A new argument to `icc()`, **parallel to `unit`** (which averages raters):

- `occasions = "single"` (**default**): `n_o = 1`. The standard single-occasion
  ICC family. Every non-replicated call is unchanged.
- `occasions = "average"`: `n_o =` the (balanced) replicate count per cell. Reports
  the occasion-averaged Φ / Eρ² above.
- `occasions = c("single","average")`: both, as `unit` allows.

The estimates table gains an **`occasions` column** (the `n_o` behind each row),
exactly as the multilevel path added a `level` column — the McGraw–Wong index label
(`ICC(A,k)`) is shared across occasion counts and the column disambiguates.
Occasion-averaged rows carry **no Shrout & Fleiss label** (SF is single-occasion).
`occasions = "average"` requires replicated data (else a classed usage error) and
balanced replicates (§7).

---

## 4. Identifiability and boundaries (#5, #8)

- **Replicates required** for this path — `n_o = 1` everywhere is the M1 estimand
  (no interaction identifiable).
- **σ²_e** needs cells with `> 1` rating; **σ²_sr** needs `> 1` rater and the
  subject×rater graph connected (inherited M3 connectedness). A boundary fit
  (σ²_sr → 0 or σ²_e → 0) is a valid, kept draw (ADR-003), not an error.
- **Balanced/complete replicates** are required in this slice: every cell present
  and rated the same number of times. Ragged replicates abort with a forward
  pointer (§7). This keeps `n_o` well defined and the ANOVA oracle exact.
- `occasions = "average"` on non-replicated data → classed usage error.
- `k_eff` (the ICC(*,k) rater divisor) counts **distinct raters per subject**, not
  total ratings — replicates must not inflate it. (A correctness fix to
  `summarize_design()`.)

---

## 5. Data API

**Bare within-cell row multiplicity** — no new `occasion`/`replicate` column. If a
subject×rater cell has `n_o` rows, those are its `n_o` exchangeable replicates
(consistent with the nested/exchangeable decision). This is how replicated data
naturally arrives (one row per rating) and needs no new user input.

---

## 6. Oracles (#1 — ≥2 independent) and provenance

Balanced two-way random with `n_o` replicates. Verified in a new
`tests/testthat/test-replicates.R`; seeded fixtures via a committed generator.

- **O-ANOVA** *(primary, independent method)* — the balanced two-way-with-
  replication **ANOVA mean squares** give the four components by method of moments,
  independent of REML: σ²_e = MS_e; σ²_sr = (MS_sr − MS_e)/n_o;
  σ²_r = (MS_r − MS_sr)/(n_o·n_s); σ²_s = (MS_s − MS_sr)/(n_o·k). The ICCs (single
  and occasion-averaged, agreement and consistency) computed from them match
  `icc()` to < 1e-4 on balanced data (REML ≡ ANOVA there).
- **O-lme4** — `lme4::lmer` fits the identical interaction model and reproduces all
  four components and every coefficient to < 1e-4 (cross-engine, ADR-005 role).
- **O-sim** — a seeded simulation with **known** σ²_s/σ²_r/σ²_sr/σ²_e recovers the
  components and the population Φ(n_r, n_o), and the Monte-Carlo interval covers
  them (PRINCIPLES.md #12).
- **Invariants** — σ²_sr + σ²_e (replicate fit) ≈ σ²_res (a single-rating fit on
  the cell means), so the single-occasion ICC family matches the pre-averaged
  computation; occasion-averaged ≥ single-occasion at the same `n_r`; every ICC in
  [0,1]; both `ci_method`s present (#3).

---

## 7. Out of scope for M17 Slice 3 (recorded for forward-compatibility)

- **Ragged / incomplete replicates** (unequal `n_o` per cell, missing cells) — the
  fit tolerates them but `n_o` and the ANOVA oracle do not; deferred (the replicate
  analogue of M3). The single-occasion ICC family would extend first; the
  occasion-averaged coefficient needs an effective-`n_o` divisor study.
- **Fixed-rater replicates** (θ²_r with an interaction) — **shipped in M20 Slice 1**
  (ADR-030): `fit_{glmmtmb,lme4}_replicates_fixed` fits
  `score ~ 1 + rater + (1|subject) + (1|subject:rater)` and places the shared
  `theta2r_fixed()` θ²_r in the rater slot; the estimand map / occasion divisor here
  are unchanged (only θ²_r replaces σ²_r). Balanced/complete single-level only; θ²_r =
  σ²_r on balanced data, so fixed reproduces the random coefficients (oracle
  O-FRep). Ragged × fixed replicates stay deferred (M20 Slice 3 scope-out).
- **One-way replicates** (rater identity ignored — replicates already fold into the
  one-way residual, no change) and **multilevel replicates** (the
  `(1 | cluster:subject:rater)` case noted in M9's deferrals) — multilevel is M20
  Slice 2.
- **Occasion D-study** (`d_study()` projecting `n_o`) — the divisor supports it, but
  projecting occasions is deferred to keep this slice bounded; the `occasions`
  knob covers single/average of the observed count.
