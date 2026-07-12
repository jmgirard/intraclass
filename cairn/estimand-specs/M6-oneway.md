# Estimand specification — M6: one-way random ICC(1) / ICC(1,k)

**Scope of this document.** The precise population definition the Milestone 6
estimator must target: the **one-way random-effects** coefficients `ICC(1)` /
`ICC(1,k)` — the last member of the classic Shrout & Fleiss (1979) family (their
Case 1). Balanced or incomplete data (the M3 `k_eff`/connectedness machinery is
reused); random raters only. This spec is what the M6 oracle tests encode; the
code must satisfy it. Scheduled by ADR-013 (promoted from ROADMAP ahead of the
optional-engine work).

It builds on [`M1-twoway-random-agreement.md`](M1-twoway-random-agreement.md) (the
`(signal, {error set}, divisor)` representation, the Monte-Carlo CI, the
identifiability caveat) and [`M4.5-d-study.md`](M4.5-d-study.md) (the resolved
numeric `divisor`). Read those first; the pieces they define are inherited
unchanged and not repeated.

Everything numeric below is **verified live** (2026-07-07) against four
independent oracles on the SF worked example — see §7 — before any code was
written (PRINCIPLES.md #1/#4).

---

## 1. What M6 adds to the abstraction

The family's internal representation is `(signal, {error set}, averaging divisor)`
so that widening it is a change of *data*, not code paths (M1 spec §5). Every
milestone so far varied the error set (`type`), the design interpretation
(`raters`), or the divisor (`unit`) **on top of one shared two-way fit**
(`score ~ 1 + (1 | subject) + (1 | rater)`).

M6 is the first milestone to change the **fitted model itself**. It adds a new
`model` knob:

| Knob | prior value | M6 adds |
|---|---|---|
| Design (**model**) | `"twoway"` (subject × rater crossed) | **`"oneway"`** (raters not crossed) |

The `model = "oneway"` path fits

```
score ~ 1 + (1 | subject)          -- NO rater term
```

and reads the estimand off it. `type`, `raters`, and the two-way `cluster`/`level`
knobs do **not** apply (see §5). The `unit` divisor (single / average / numeric)
is inherited unchanged.

---

## 2. One-way estimands (population definitions)

In a one-way design each subject is rated by *k* raters, but the raters are **not
the same set across subjects** — rater identity carries no information and is not
modeled. The single unmodeled within-subject term therefore **confounds** the
rater main effect with residual error: `σ²_res` here is `σ²_rater + σ²_error`
together, not the two-way residual.

### ICC(1) — single rater, one-way

```
                 σ²_s
ICC(1) = ───────────────────       (estimable, single-rating design)
             σ²_s + σ²_res
```

### ICC(1,k) — mean of k raters, one-way

```
                  σ²_s
ICC(1,k) = ───────────────────     (estimable form)
             σ²_s + σ²_res / k
```

In `(signal, {error set}, divisor)` terms: **signal = σ²_s**, **error set =
{residual}**, **divisor = 1 (single) / k (average) / m (numeric projection)** —
identical bookkeeping to consistency, but read off a **different fit** (§3). A
numeric `unit = m` gives `ICC(1,m) = σ²_s / (σ²_s + σ²_res / m)` straight from the
inherited `resolve_divisor()` (M4.5), so one-way D-study projection is free.

### Range

With REML both components are ≥ 0, so `ICC(1,·) ∈ [0, 1]`.

---

## 3. Why one-way ≠ consistency (the load-bearing distinction)

`ICC(1) = σ²_s / (σ²_s + σ²_res)` has the **same algebra** as `ICC(C,1)` (M2), but
is a **different number**, because the two come from different fitted models:

| | fit | what `σ²_res` contains |
|---|---|---|
| **consistency** `ICC(C,1)` | `~ 1 + (1\|subject) + (1\|rater)` | residual **only** (rater removed to its own term σ²_r) |
| **one-way** `ICC(1)` | `~ 1 + (1\|subject)` | residual **+ rater** (confounded — no rater term) |

On the SF data the gap is large — `ICC(C,1) = 0.715` vs `ICC(1) = 0.166` — precisely
because the raters differ sharply in mean level: consistency isolates that spread
into σ²_r and discards it, whereas one-way dumps it into the error and pays for it.

**Consequence for the code:** one-way needs its **own engine fit function** (no
rater term). It is not a relabeling of the two-way read-out. The `σ²_s` estimate
itself also differs from the two-way fit (SF: 1.244 one-way vs 2.556 two-way),
because omitting the rater term repartitions the variance — so it must be a real
separate fit, not a component drop.

---

## 4. Estimation via the mixed model

`fit_glmmtmb_oneway()` (and `fit_lme4_oneway()`, since both engines are selectable
after M5.5 / ADR-012) fit `score ~ 1 + (1 | subject)` by REML and return the shared
six-field engine contract with named components `subject = σ²_s`,
`residual = σ²_res`. There is **no `rater` component**. The Monte-Carlo CI (ADR-003)
and the `icc_point()` / `resolve_divisor()` pipeline are inherited unchanged: the
draw is over the two-parameter (log-SD subject, log-dispersion) covariance,
boundary-aware by construction.

---

## 5. API decisions (pinned; maintainer-approved 2026-07-07)

- **`rater` is still required and still selects a column, but its identity is
  ignored** — it defines only the number of ratings per subject (the divisor *k*),
  reusing the M3 `summarize_design()` `k_eff`/connectedness/balance machinery. This
  keeps the `icc(data, score, subject, rater, model = "oneway")` signature
  consistent with the rest of the family and matches how Shrout–Fleiss / `psych`
  treat "k judges per target". **Must be documented clearly** (roxygen + vignette):
  under `model = "oneway"` the raters are treated as interchangeable and their
  labels do not affect the result.
- **`type` does not apply.** One-way is a single coefficient (no agreement /
  consistency distinction in McGraw–Wong / SF). `type` is ignored under
  `model = "oneway"`; the label is always `ICC(1)` / `ICC(1,k)`. Documented.
- **`raters = "fixed"` is ill-posed** for one-way (fixed raters presuppose a
  crossed, identified rater set): classed `abort_unsupported()` (#5/#8).
- **`cluster` (multilevel) + `model = "oneway"`** is out of scope: classed abort.
- **Numeric `unit` (D-study projection) is supported** — `ICC(1,m)` falls out of
  `resolve_divisor()` at no cost; the fixed-agreement projection refusal does not
  apply here (one-way has no fixed path).

---

## 6. Labeling — McGraw & Wong ↔ Shrout & Fleiss

One-way random single / average measures are Shrout & Fleiss **ICC(1)** /
**ICC(1,k)**; there is no separate McGraw–Wong A/C name (their A/C split is a
two-way concept). The package reports `ICC(1)` / `ICC(1,k)`; the print/summary
crosswalk notes "one-way random, Shrout & Fleiss ICC(1)/ICC(1,k)".

---

## 7. Worked verification (Shrout & Fleiss 1979 data)

Live check on the SF 6×4 matrix (`data-raw`/`sf_ratings`), fitting
`score ~ 1 + (1 | subject)`, k = 4. **All four oracles agree exactly** — this is
the O-OW oracle set:

| Oracle | ICC(1) | ICC(1,k) |
|---|---|---|
| glmmTMB one-way (σ²_s = 1.2444, σ²_res = 6.2639) | 0.1657 | 0.4428 |
| lme4 one-way (identical components) | 0.1657 | 0.4428 |
| one-way ANOVA mean squares `(MSB−MSW)/(MSB+(k−1)MSW)` | 0.1657 | 0.4428 |
| `psych::ICC` ICC1 / ICC1k | 0.16574 | 0.44280 |
| **Published Shrout & Fleiss (1979)** | **0.166** | **0.443** |

These 0.166 / 0.443 values are already staged in
`tests/testthat/helper-shrout-fleiss.R::sf_oracle_all` (the M1 helper reserved them
"for later milestones to grow into"). A seeded simulation with a known σ²_s and no
rater effect is the fifth oracle (recovery + MC coverage).

---

## 8. Acceptance criteria (this estimand → code)

- Public `model = "oneway"` → `ICC(1)` / `ICC(1,k)`; numeric `unit` → `ICC(1,m)`.
- `fit_glmmtmb_oneway()` + `fit_lme4_oneway()` (`~ 1 + (1|subject)`), returning the
  shared six-field contract; `subject` / `residual` components; no rater term.
- Boundary-aware MC CI inherited unchanged; `icc_point()`/`resolve_divisor()`
  untouched.
- Guards (#5/#8): `raters = "fixed"` + oneway → abort; `cluster` + oneway → abort;
  `type` ignored (documented, not aborted).
- `print`/`summary`/`format`/`tidy`/`glance` surface the one-way design + label;
  balance / `k_eff` reused from M3.
- Oracles O-OW (≥2 independent, actually 5): SF 0.166/0.443; `psych` ICC1/ICC1k to
  1e-4; one-way ANOVA mean squares; glmmTMB↔lme4 cross-engine; seeded simulation
  (recovery + 95% CI coverage).
- Roxygen "which ICC / when" extended to one-way (incl. the rater-identity-ignored
  and type-not-applicable notes); a `choosing-an-icc.Rmd` / `getting-started` note.
- `REFERENCES.md` O-OW row; `DECISIONS.md` (ADR-013 already records the scheduling;
  a new ADR only if an API-shape decision here proves contentious).

---

## 9. Decision guidance (teaching note for the docs/vignette)

Use `model = "oneway"` when **each subject is rated by a different (or
arbitrarily-assigned) set of raters**, so "rater 1" means nothing across subjects —
e.g. essays each read by whichever two graders were free, or specimens each scored
by a rotating panel. Because rater differences cannot be separated, they inflate
the error and `ICC(1)` is typically the **most conservative** coefficient. If the
same raters judge every subject, prefer the two-way `model = "twoway"` (default) so
`type = "agreement"` vs `"consistency"` can separate systematic rater bias. The
flagship article's decision tree gains "are the raters the same across subjects?"
as the first fork.

---

## 10. Out of scope for M6 (recorded for forward-compatibility)

- **Within-cell replicates** (multiple ratings per subject×rater under a two-way
  design) — a different `(1 | subject:rater)` model, stays in ROADMAP.
- **One-way *fixed*** — not meaningful (one-way presupposes interchangeable
  raters).
- Categorical/ordinal one-way (GLMM) — ROADMAP.

---

## References

- Shrout, P. E., & Fleiss, J. L. (1979). Intraclass correlations: uses in assessing
  rater reliability. *Psychological Bulletin*, 86(2), 420–428. (ICC(1) = 0.166,
  ICC(1,k) = 0.443, Case 1.)
- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods*, 1(1), 30–46. (One-way random.)
- ADR-013 (M6 scheduling), ADR-002/003 (engine + MC CI), ADR-012 (lme4 selectable),
  ADR-008 (`k_eff` under imbalance); M1/M3/M4.5 estimand specs.
