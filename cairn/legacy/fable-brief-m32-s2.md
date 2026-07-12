# Fable review brief — M32 Slice 2: ragged nested Design-3 credible-interval undercoverage

**Status:** gated Fable review, recommended and approved 2026-07-10 (PRINCIPLE #19).
Milestone M32 Slice 2 is **stopped** pending this review. This brief is the record of
*what Fable is asked*; the ADR-042 amendment in [`DECISIONS.md`](DECISIONS.md) records
*what was found*; the verdict will be recorded as a follow-up ADR-042 amendment.

**You are the Fable statistical reviewer.** Your job is not to trust this brief. Your
job is to **independently reproduce and inspect the artifacts named below**, re-derive
the estimand and the interval construction, and rule on the finding. Where this brief
states a number, treat it as a claim to verify against the committed fixture and the
seeded oracle script — not as ground truth. Where it proposes a mechanism, treat it as
a hypothesis to confirm or reject. Do **not** tune anything to make a pin pass (#4); the
failing test is an intended honest signal, not a bug to silence.

---

## 1. What M32 is, and where Slice 2 sits

`intraclass` computes interrater-reliability ICCs from mixed-model variance components,
with **boundary-aware Monte-Carlo / posterior credible intervals** (PRINCIPLE #3). A
CI method's oracle is **coverage** (#1). The Bayesian engine (`engine = "brms"`,
`ci_method = "posterior"`, forced) fits under a half-*t*(4,0,1) prior on every random-
effect SD (ten Hove, Jorgensen & van der Ark 2020), reports the posterior **mode (MAP)**
as the point and a **percentile credible interval**.

M32 (ADR-042) extends `engine = "brms"` to **incomplete/ragged NESTED random** designs
at the subject level — the Bayesian sibling of the frequentist M19:

- **Slice 1 — Design 2** (raters nested in **clusters**): **SHIPPED, nominal.** Ragged
  coverage .925/.925 vs complete .95/.95 (seed 32100, n_rep 80). Committed `7b8b60c`.
- **Slice 2 — Design 3** (raters nested in **subjects**; the multilevel **one-way**,
  agreement-only): **BLOCKED — this review.**

Both slices are pure engine parity: the shipped M25 nested fits
(`fit_brms_nested_clusters` / `fit_brms_nested_subjects`) run **unchanged** on ragged
data; the M3/M9 harmonic-mean `k_eff` + connectedness / per-subject identifiability gates
run **pre-dispatch** (engine-agnostic). Random raters → each ICC is a **ratio of variance
components**, so there is **no θ² finite-population functional** and the M27/M28 **2b
moment correction is not involved** here.

## 2. The finding (verify against the fixture)

Design 3 is the multilevel one-way: `score ~ 1 + (1|cluster) + (1|cluster:subject)`, with
the rater main effect **confounded into the residual** (ten Hove 2022 p. 6). Each subject
carries its **own** raters. Subject-level agreement-only:

- ICC(1) = σ²_{s:c} / (σ²_{s:c} + σ²_r + σ²_res)   (divisor-free)
- ICC(k) = σ²_{s:c} / (σ²_{s:c} + (σ²_r + σ²_res)/k)

Seeded coverage oracle (seed 32200, n_rep 80), population ICC(1) = 0.6024:

| cell | k_eff | coverage ICC(1) / ICC(k) | MAP rel-bias | conv |
|------|-------|--------------------------|--------------|------|
| complete | 5.00 | **0.975 / 0.975** (nominal) | +.009 / +.003 | .975 |
| ragged   | 4.29 | **0.8625 / 0.8625**         | −.001 / +.0004 | .95  |

Key features to confirm:

1. **Complete cell is nominal** → the fit/reduce/interval pipeline is correct at balance;
   the shortfall is specific to raggedness.
2. **The MAP is unbiased** on ragged data (rel-bias ≈ 0) — so the **interval is too
   narrow**, not the point displaced. (Contrast M27/M28, where the *point* functional
   needed a 2b correction; that mechanism does not apply here — no θ² functional.)
3. **Real, not MC noise**: 0.8625 = 69/80 is **≈ 3.6 SD below** the .95 nominal
   (binomial SD at p=.95, n=80 ≈ 1.95). But n_rep = 80 **cannot** cleanly separate
   "true coverage ≈ .86" from "≈ .90" (≈ 1.1 SD below .90) — a precision limit you should
   address (see §4).
4. **Design-3-specific**: the crossed random path (M30) and nested Design 2 (Slice 1)
   ragged cells were all nominal. Only Design 3 undercovers.

## 3. Hypothesis to adjudicate (confirm or reject)

Proposed mechanism, **not** established: in Design 3 the rater variance is confounded
into the residual and each subject has its **own** raters, so under imbalance the
**per-subject effective information varies**, and the scalar `k_eff` (harmonic mean of
ratings/subject) plus the posterior push-forward may **under-propagate** that
between-subject variability into the credible interval — a **calibration** shortfall
distinct from the M27/M28 finite-population θ² **2b** displacement.

Alternative explanations you should weigh:
- an **adversarial single ragged incidence** (the oracle fixes one seeded incidence, as
  M30/Slice 1 do) rather than a systematic effect;
- the **reflected-KDE `posterior_mode()` MAP** or the **percentile** interval interacting
  with a skewed one-way ragged posterior;
- genuine finite-sample miscalibration of the half-*t* one-way model on unbalanced data
  that would shrink with N.

## 4. Your charge

1. **Confirm and quantify** the ragged Design-3 undercoverage — its **magnitude** and
   **robustness** across (a) **higher n_rep** (e.g. 200–400, to tighten the .86-vs-.90
   estimate) and (b) **multiple independent ragged incidences** (to rule out an
   adversarial single draw). Report honestly (#18); do not tune (#4).
2. **Rule** on the disposition:
   - **(A) a calibration correction is warranted** — specify exactly what (and derive/
     justify it; it must be oracle-checkable, #1), then M32 Slice 2 ships with it; **or**
   - **(B) no faithful correction is in reach** — then incomplete nested **Design 3** is
     **deferred as research** (the multilevel-one-way sibling of the open M9 `ICC(c,k)`
     incomplete divisor), Slice 2 is reverted, and M32 ships as **Design 2 only**.

Do **not** propose loosening the coverage pin to make Slice 2 pass. Either a correction
brings coverage to nominal, or the design is deferred.

## 5. Artifacts — read and re-run these; do not trust §2

- **Coverage oracle (Design 3, the finding):**
  [`data-raw/oracle-bayesian-incomplete-nested-subjects.R`](../data-raw/oracle-bayesian-incomplete-nested-subjects.R)
  → committed `tests/testthat/fixtures/bayesian-incomplete-nested-subjects-oracle.rds`
  (seed 32200, n_rep 80). This is a **live-Stan** run (~1 hr at n_rep 80); a higher-n_rep
  / multi-incidence re-run is the core of charge #1.
- **Contrast oracle (Design 2, nominal):**
  [`data-raw/oracle-bayesian-incomplete-nested.R`](../data-raw/oracle-bayesian-incomplete-nested.R)
  → `bayesian-incomplete-nested-oracle.rds` (seed 32100). Compare the two to localize the
  Design-3-specific effect.
- **The fit under review:** `fit_brms_nested_subjects()` in
  [`R/engine-brms.R`](../R/engine-brms.R); reducers `brms_component_draws()` /
  `posterior_summary()` / `posterior_mode()` (the reflected-KDE MAP) / `brms_convergence()`
  in the same file; guard/dispatch at [`R/icc.R`](../R/icc.R) (~L1158 guard, ~L1232
  dispatch), identifiability gates ~L723–777.
- **Estimand:** [`estimand-specs/M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md)
  (Design 3 subject-level, Eq. 11 / Table 3 right); `k_eff` under imbalance from
  [`estimand-specs/M9-incomplete-multilevel.md`](estimand-specs/M9-incomplete-multilevel.md)
  / [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md) §6.
- **The finding record:** ADR-042 + its 2026-07-10 amendment in
  [`DECISIONS.md`](DECISIONS.md); oracle registry entry **O-Bayes-INML-subjects** in
  [`REFERENCES.md`](REFERENCES.md).
- **The honest signal:** the committed test in
  [`tests/testthat/test-icc-brms.R`](../tests/testthat/test-icc-brms.R)
  (`O-Bayes-INML-subjects`) asserts ragged coverage ≥ .88 and **fails** on the fixture.
  It is intended to fail until this review resolves; do not edit it to pass.

## 6. Principles binding this review

#1 oracle-first (coverage is the oracle; verify independently) · #3 boundary-aware
intervals · #4 no tuning to the oracle / no fabricated reference · #18 report the run
honestly (characterize, don't assert) · #19 Fable is manual, gated, recommend-and-stop —
your verdict is advisory input the maintainer adopts; you do not edit shipping code
autonomously. Deliver a written verdict (A or B, with the derivation/evidence); the
maintainer records it as the follow-up ADR-042 amendment and I implement it.
