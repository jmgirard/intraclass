# Estimand specification — M17 Slice 1: conflated single-level ICC (Eq. 14)

**Scope of this document.** The precise population quantity targeted by
`level = "conflated"` — the interrater ICC a naive analyst obtains by **ignoring
the cluster structure** of a multilevel design and treating it as a flat two-way
subject×rater design. It is the *biased* single-number summary the package exists
to expose, shipped as a **selectable diagnostic contrast, not a recommended
coefficient**. It builds directly on
[`M5-multilevel.md`](M5-multilevel.md) (the five-component multilevel fit and the
subject/cluster estimand maps) — read that first. Nothing in the fit, the
Monte-Carlo / bootstrap CI, or `icc_point()` changes; this adds only a new
component-selection map read off the **existing** M5 fit.

This slice **promotes** M5 §4's "conflated (single-level) contrast", which until
now was computed only as a vignette teaching point, into a first-class
`level = "conflated"` value (ADR-026, M17 Slice 1). Ships on branch
`m17-varcomp-trio`.

**Source of the estimand.** ten Hove, D., Jorgensen, T. D., & van der Ark, L. A.
(2022). Interrater reliability for multilevel data: A generalizability theory
approach. *Psychological Methods, 27*(4), 650–666. The conflated ICC is the
paper's **Eq. 14** — the absolute-agreement reliability obtained when the
multilevel (nested) structure is collapsed. Transcribed, not paraphrased or
guessed (PRINCIPLES.md #1, #2, #4).

---

## 1. What this adds to the estimand abstraction

M1 fixed the internal representation of an ICC as
`(signal component set, {error component set}, averaging divisor)`. M5 keyed the
signal/error map by `level ∈ {subject, cluster}` off a **five-component** fit
(σ²_c, σ²_{s:c}, σ²_r, σ²_{cr}, σ²_{(s:c)r}). This slice adds **one more `level`
value** — `"conflated"` — with its own signal/error map. The divisor
(`resolve_divisor(unit, k_eff)`, single = 1 / average = k) and `icc_point()` are
**untouched**.

| Knob | prior values | this slice adds |
|---|---|---|
| Design interpretation (**level**) | `subject`, `cluster` | **`conflated`** — collapse the nesting |
| Signal | `{s:c}` (subject) / `{c}` (cluster) | **`{c, s:c}`** — cluster + within-cluster subject variance both treated as "true score" |
| Error set (**type**) | agreement / consistency | **agreement only** (see §4) |
| Divisor (**unit**) | 1 (single), k (average) | (unchanged) |

---

## 2. Population definition (paper Eq. 14)

Collapsing the cluster level folds the between-cluster variance σ²_c into the
object-of-measurement ("true score") and the cluster×rater variance σ²_{cr} into
rater error. From the five components of the M5 Design-1 fit:

```
signal = σ²_c + σ²_{s:c}
error  = σ²_r + σ²_{cr} + σ²_{(s:c)r}

                          σ²_c + σ²_{s:c}
ICC_conflated(k) = ─────────────────────────────────────────
                    σ²_c + σ²_{s:c} + (σ²_r + σ²_{cr} + σ²_{(s:c)r}) / k
```

At `k = 1` this is the single-rating conflated ICC; at `k = k_eff` the
average-rating conflated ICC. In the estimand triple:
`(signal = {c, s:c}, error = {r, cr, (s:c)r}, divisor = 1 | k)`.

**Interpretation.** This is *not* a competing "correct" coefficient — it is the
number the M5 subject- and cluster-level ICCs decompose. It conflates two
substantively different sources (between-cluster and within-cluster subject
variation) into one signal and two different rater-error sources into one error
term, which is exactly why it is biased for nested data. Its value in the package
is **diagnostic / didactic**: it quantifies *how much* ignoring the nesting
distorts the reliability, right next to the correctly-partitioned estimates.

---

## 3. Applicability and boundaries (PRINCIPLES.md #5, #8)

- **Requires a multilevel design.** `level = "conflated"` is only defined off the
  five-component fit — it needs `cluster` (Design 1). Requesting it on a
  single-level design is a classed usage error (`abort_intraclass`): on flat data
  the "conflated" ICC *is* the ordinary two-way ICC, so the value would be
  vacuous. Fail loudly rather than return a redundant number.
- **Design 1 (crossed) only in this slice.** Eq. 14 is stated for the crossed
  Design 1 (the only design with both subject- and cluster-level IRR, M5 §1). The
  nested Designs 2/3 (M8) have no cluster level and no published Eq. 14 analogue →
  out of scope (§6).
- **Agreement only.** Eq. 14 is the absolute-agreement form; the paper publishes
  no consistency-conflated formula. `type = "consistency"` + `level = "conflated"`
  is a classed abort pointing at the ROADMAP investigation item — **no guessed
  formula** (#4).

---

## 4. Why it must never read as a recommended coefficient

The whole point of this coefficient is that it is the **wrong** answer for nested
data. Surfacing it as a peer of `subject`/`cluster` risks a user selecting it by
mistake. Therefore:

- `print`/`summary` render it under a **diagnostic-contrast** heading, explicitly
  noting it ignores the cluster structure and is for comparison only.
- `tidy`/`glance` carry a flag / label distinguishing it from the correctly-
  partitioned rows (never an unmarked additional `estimates` row that reads as a
  third valid level).
- **`choose_icc()` never recommends it.** The decision helper may *name* it as the
  anti-pattern ("ignoring clustering gives …") but its recommended call is always a
  correctly-partitioned `level`.

---

## 5. Oracles (PRINCIPLES.md #1 — ≥2 independent) and provenance

Verified in `tests/testthat/` (test file TBD at implementation — likely
`test-conflated.R` or an addition to `test-icc-multilevel.R`), seeded fixtures
regenerated by the M5 oracle script (`data-raw/oracle-multilevel.R`) as needed:

- **O-lme4** *(primary, independent implementation)* — the same five components
  (hence the same conflated value) recovered by `lme4::lmer` on the same data,
  plugged into Eq. 14, cross-engine to < 1e-4 (the M5 O-ML role).
- **O-Eq14** *(formula wiring)* — the shipped value equals the closed-form Eq. 14
  computed *directly* from the fitted five components the object reports (an exact
  identity to ~1e-10; independent of the estimator's own ICC arithmetic path). The
  paper anchor for the formula transcription.
- **O-population** *(independent DGP)* — on a seeded simulation with **known**
  components the conflated ICC recovers the population Eq. 14 value; because σ²_c is
  estimated from few clusters the point estimate is noisy, so the honest recovery
  check is that the **boundary-aware MC interval covers** the known value (the
  O-ML/sim pattern), with a generous point sanity floor. It also **tracks the flat
  single-level agreement `icc()`** (cluster dropped) — the operational meaning of
  "conflated". *Note (#18):* this last equivalence is **population-level, not a
  finite-sample identity** — the flat two-way fit and the five-component fit are
  *different models* (the flat residual absorbs σ²_c and σ²_cr), so they agree only
  in expectation on balanced data, checked at a loose tolerance, not < 1e-4.

**Invariants also asserted:** conflated ∈ [0, 1]; average ≥ single; a conflated row
carries no Shrout & Fleiss label; conflated can be requested alongside the correct
levels without displacing them; the CI is present (MC default + bootstrap), never a
bare point (#3).

**Regression guard:** the full M5/M8/M9/M10 multilevel suites stay green — this
slice adds a `level` value and touches no fit or CI path.

---

## 6. Out of scope (recorded for forward-compatibility)

- **Consistency-conflated ICC** — dropping σ²_r from the error set. Not in the
  paper; deferred to the ROADMAP investigation item (find a sourced or faithfully-
  derivable form with an oracle strong enough for #1/#4 before shipping). Aborts
  today.
- **Conflated ICC for nested Designs 2/3** — no cluster level, no Eq. 14 analogue.
- **Incomplete-data conflated ICC** — ~~a later question, not opened here~~ **resolved
  and shipped in M18 Slice 2 (ADR-028); see §6a.**

---

## 6a. Incomplete-data conflated ICC (M18 Slice 2 — resolved)

M17 Slice 1 left open "whether the conflated value is well-posed on ragged
multilevel data." M18 Slice 2 opened it under the maintainer's *attempt-then-degrade*
posture (ADR-028): attempt the natural extension, and if no #1/#4-strong oracle holds,
reclassify to 🟣 research rather than ship a guessed formula. **The oracle held — it
ships.**

**Why it is well-posed.** Eq. 14 collapses the five components into **one** signal
(σ²_c + σ²_{s:c}) and **one** error (σ²_r + σ²_{cr} + σ²_{(s:c)r}) — it never needs
those five terms *separately*, only their two sums. So the conflated ICC is exactly
the **flat two-way agreement ICC** read off the multilevel fit, and its averaging
divisor is the **same flat `k_eff`** (the harmonic mean of ratings per subject, which
is cluster-agnostic) the subject level already uses (M3 §5, ADR-008). Nothing in
`icc_point()`, the CI, or the component map changes; the ragged five-component fit
(M9) supplies the components.

**Identifiability (§3, extended).** On ragged data the conflated path flows through
the **same** crossed-multilevel gates as subject-level agreement (M9 §4b):
within-cluster connectedness and ≥1 subject rated more than once (for σ²_{s:c}), and
the agreement rater-bridging gate (which is what makes the *flat* subject×rater design
connected across clusters). This is **conservative** — the conflated lump strictly
needs only the r+cr *sum*, not their separation — but a stricter guard is safe for a
never-recommended diagnostic (#5), and it aligns the refusal set with "the flat
two-way ICC is identified."

**Oracles (M18 Slice 2, in `test-icc-multilevel.R`):**
- **O-conflated/incomplete-Eq14** — the ragged estimate equals the closed-form Eq. 14
  on the reported components to ~1e-10 (formula wiring; divisor `k_eff < k`).
- **O-conflated/incomplete-lme4** — cross-engine glmmTMB ≡ lme4 to < 1e-4 on ragged
  data.
- **O-conflated/incomplete-population** — tracks the flat incomplete two-way agreement
  `icc()` (cluster dropped) at a loose population tolerance (~0.02; different models),
  and stays **visibly biased** away from the correctly-partitioned subject level — the
  diagnostic's whole point, preserved on ragged data.

**Still out (unchanged):** consistency-conflated (not in the paper), fixed-rater
conflated (Eq. 14 is a random-rater formula), and nested Designs 2/3 conflated — all
classed aborts on both balanced and ragged data.
