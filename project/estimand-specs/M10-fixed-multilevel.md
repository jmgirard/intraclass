# Estimand specification — M10: fixed-rater multilevel ICCs (Design 1, balanced)

**Scope of this document.** The precise population quantities the multilevel
**subject-level** interrater ICCs target when the raters are treated as **fixed**
(the observed raters are the entire population of interest — McGraw & Wong 1996, Case
3 / 3A) rather than a random sample, in the **crossed** multilevel design (ten Hove et
al. 2022, Design 1 — raters crossed with clusters), **balanced / complete**. Like M9,
M10 is an **intersection of two shipped machineries** and introduces *no new estimand
concept*:

1. the **M3 real fixed-effect fit + finite-population θ²_r** (`estimand-specs/M3-incomplete-designs.md §6`,
   ADR-008 — McGraw & Wong Case 3A), inherited unchanged; and
2. the **M5 Design-1 multilevel fit and subject-level estimand map**
   (`estimand-specs/M5-multilevel.md`, ADR-011), inherited unchanged.

Read M3 §6 and M5 first. M10 is to M5 what M3's fixed path is to M1/M2: the rater
term stops being a random-sample variance σ²_r and becomes the finite-population
variance **θ²_r** of the specific raters observed. Nothing else in the subject-level
decomposition changes.

**Locked scope (ADR-019, maintainer-approved this session, 2026-07-07):**
- **Crossed (Design 1) only, balanced / complete, subject level only.** The M5-analog
  thin scope for a genuinely **new fitted model** (raters move from a random intercept
  to fixed effects). Fixed + incomplete, fixed + nested, and the fixed **cluster**
  level are deferred (§7), mirroring M5 → M9.
- **glmmTMB engine** (lme4 as cross-engine oracle, ADR-002/012).

**What is inherited vs. what is M10's engineering (be explicit, #18).** θ²_r — the
**bias-corrected** finite-population variance of the k rater level means — is **M3's,
verbatim** (`fit_glmmtmb_fixed()`, ADR-008; sourced to McGraw & Wong 1996 Case 3A). The
subject-level `(signal, {error set}, divisor)` map is **M5's, verbatim** (σ²_cr is *not*
in the subject-level error — M5/M9 §3a). M10's only new engineering is **placing θ²_r
into the multilevel fit** — raters fixed, the rest of the M5 random structure retained
— which is **oracle-pinned, not asserted** (§4): there is **no textbook worked example**
for fixed-rater multilevel (the paper is a random-effects framework), so the fit is
validated by its reduction to the pinned M5 (balanced) and M3 (single-cluster)
estimands before it ships. If it cannot be pinned, a Fable review is *recommended* and
work pauses (#1, #19).

M10 ships on branch `m10-fixed-multilevel`, in CI-green slices (§5).

---

## 1. What M10 adds to the abstraction

M5 fixed the multilevel estimand as `(signal, {error set}, scalar divisor)` keyed on
`level` and `type`, over a **random-rater** Design-1 fit. M3 §6 showed that treating
raters as **fixed** replaces the random σ²_r with the finite-population θ²_r in the
*same* `{rater, residual}` agreement error set, leaving `icc_estimand()` / `icc_point()`
/ `mc_ci()` untouched — only *what fills the `rater` component slot* changes (θ²_r vs
σ²_r). M10 combines the two: the **rater slot carries θ²_r** while the signal and
residual come from the **multilevel** decomposition.

| Slot | M5 (random multilevel) | M3 (fixed flat) | **M10 (fixed multilevel)** |
|---|---|---|---|
| fit | 5-component random | `1 + rater + (1\|subject)` | `1 + rater + (1\|cluster) + (1\|cluster:subject) + (1\|cluster:rater)` |
| signal (subject) | σ²_{s:c} | σ²_s | σ²_{s:c} |
| `rater` slot | random σ²_r | **θ²_r** (Case 3A) | **θ²_r** (Case 3A) |
| residual | σ²_{(s:c)r} | σ²_res | σ²_{(s:c)r} |
| divisor | scalar `k` | scalar `k` | scalar `k` — **unchanged** |

---

## 2. The fit and the estimand

### 2a. Fit (our translation; oracle-pinned, §4)

Raters enter as **fixed effects**; the rest of the M5 Design-1 random structure is
retained (cluster, subject-in-cluster, and the cluster×rater interaction — the latter
stays **random**, being a random-cluster × fixed-rater interaction, the standard mixed-
model convention):

```r
score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)
```

θ²_r is the **bias-corrected finite-population variance of the k fitted rater level
means** — computed exactly as in M3 (`rater_mean_contrast()` + the sampling-variance
bias term, ADR-008) — and returned in the **`rater` component slot**. There is no
random σ²_r. σ²_cr, σ²_c, σ²_{s:c}, σ²_res are the random components as in M5.

### 2b. Subject-level estimand (inherited M5/M9 §3a, with θ²_r in the rater slot)

| | agreement | consistency |
|---|---|---|
| single `ICC_s(·,1)` | σ²_{s:c} / (σ²_{s:c} + θ²_r + σ²_{(s:c)r}) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}) |
| average `ICC_s(·,k)` | σ²_{s:c} / (σ²_{s:c} + (θ²_r + σ²_{(s:c)r})/k) | σ²_{s:c} / (σ²_{s:c} + σ²_{(s:c)r}/k) |

σ²_cr is **not** in the subject-level error (M5/M9 §3a — a cluster×rater effect shifts
every subject in a cluster equally). Consistency is **identical to the random-rater
case** (it never used the rater term); only **absolute agreement** differs, and only
by θ²_r vs σ²_r — which on balanced data are equal (§4).

Fixed raters emit the existing classed `intraclass_fixed_raters` warning (random is the
recommended default; fixed forgoes generalization), as in M2/M3.

---

## 3. Guardrails (PRINCIPLES.md #5)

- **≥ 2 raters** to form θ²_r (as M3); **≥ 2 clusters** and **≥ 2 subjects in some
  cluster** for the multilevel signal (as M5 §7).
- **Balanced / complete only.** An incomplete or unbalanced fixed-rater multilevel
  design aborts (deferred, §7) rather than using an unvalidated θ²_r-under-imbalance —
  the fixed θ²_r bias correction and the `k_eff` divisor interact and need their own
  oracle work (M3 §6 caveat + M9 §5), out of M10's thin scope.
- **`level = "cluster"`** with fixed raters aborts (subject level only in M10, §7).
- **Absolute-agreement D-study projection** for fixed raters stays refused (M4.5;
  θ²_r is the finite-population variance of *these* raters — no projection).

---

## 4. Oracles (PRINCIPLES.md #1 — ≥2 independent) and provenance

No textbook worked example exists for fixed-rater multilevel. Correctness rests on
**reductions to the already-pinned M5 and M3 estimands** plus a cross-engine and a
seeded sim, in `tests/testthat/test-icc-fixed-multilevel.R`, regenerated by
`data-raw/oracle-fixed-multilevel.R` (seeded, `stopifnot`):

- **O-FML/reduction → M5 (balanced fixed ≡ random).** *The primary pin.* On balanced
  complete data the bias-corrected θ²_r equals the random-fit σ²_r (M3 §6, verified on
  SF), and σ²_{s:c} / σ²_res are unaffected by fixing the rater main effect, so the
  **fixed-rater subject-level ICCs equal the random-rater M5 subject-level ICCs** on the
  same data (agreement + consistency, single + average) to < 1e-4. This is the M2 O4
  equivalence lifted to the multilevel fit — a strong, self-contained oracle.
- **O-FML/reduction → M3 (single cluster).** With one cluster the multilevel fixed
  model reduces to M3's `1 + rater + (1|subject)`: θ²_r, σ²_s, σ²_res match M3's
  fixed-path values. Checked at the fit level (a one-cluster design is refused by
  `icc()`), mirroring the M9 single-cluster reduction.
- **O-FML/lme4.** An independent lme4 fit of the identical fixed-rater multilevel model
  reproduces σ²_{s:c}, σ²_cr, σ²_res and (with the same θ²_r computation) every §2b
  coefficient to < 1e-4.
- **O-FML/sim.** A seeded balanced simulation with **known** components recovers the
  subject-level points within tolerance and the boundary-aware MC interval covers the
  population values (#12); the fixed MC sampler (below) is exercised.

**MC CI.** The interval reuses the **M3 fixed-rater sampler branch** (ADR-008): each
draw samples the fixed rater effects β̂ from `vcov(fit, full = TRUE)` alongside the
variance components and recomputes θ²_r, now with the multilevel components in the draw.
Consistency needs only σ²_{s:c} and σ²_res per draw (θ²_r unused), as today.

**Regression guard:** the full existing suite — M1–M9 oracles incl. M3 fixed, M5 O-ML,
M9 O-IML — stays green (the flat fixed path and the random multilevel path are
untouched).

If any §2b coefficient cannot be pinned by both required oracles it is **not shipped**,
a Fable review is *recommended*, and work pauses (#1, #19).

---

## 5. Slices

- **Slice 1 — fixed-rater multilevel fit + subject-level estimand.** Lift the
  `raters = "fixed"` + multilevel abort (icc.R); add the fixed-rater multilevel fit
  (§2a — raters fixed, θ²_r via the reused M3 machinery, multilevel random structure)
  returning the six-field engine contract with θ²_r in the `rater` slot; route it in
  `icc()`. Subject-level agreement/consistency, single/average, reusing `icc_point()`
  and the M3 fixed MC sampler. Oracles O-FML/reduction (→ M5 balanced, → M3 single
  cluster), O-FML/lme4, O-FML/sim. `print`/`glance` surface fixed-rater multilevel.
- **Slice 2 — docs.** Extend `advanced.Rmd`'s multilevel section to fixed raters on
  real knit-time code; `test-vignette-claims.R` invariants (balanced fixed ≡ random at
  the subject level; consistency identical, agreement differs only by θ²_r).

---

## 6. Acceptance criteria (this estimand → code)

- **Fit:** `raters = "fixed"` + `cluster` fits §2a and returns θ²_r in the `rater`
  slot; the `intraclass_fixed_raters` warning is emitted.
- **Subject level:** agreement + consistency, single + average, with boundary-aware MC
  CIs; **equal the random-rater M5 subject-level ICCs on balanced data** to < 1e-4
  (O-FML/reduction → M5); match lme4 (O-FML/lme4) and the M3 single-cluster reduction.
- **Consistency ≡ random** exactly (the rater term is unused); **agreement** differs
  from random only by θ²_r vs σ²_r (zero on balanced data).
- **Guards:** incomplete/unbalanced, `level = "cluster"`, and nested fixed-rater
  designs abort with classed errors (§3, §7); complete balanced random paths untouched.
- **Docs:** the "which ICC / when" note extends to fixed-rater multilevel; the estimand
  is named (#2, #13).

---

## 7. Out of scope for M10 (recorded for forward-compatibility)

- **Fixed-rater cluster-level IRR** (signal σ²_c, error {θ²_r, σ²_cr}) — its own later
  slice; needs the fixed-rater treatment of the cluster×rater term validated.
- **Incomplete / unbalanced fixed-rater multilevel** — reuse M9's connectedness + the
  M3 θ²_r-under-imbalance path; deferred (the two bias/divisor interactions need their
  own oracles).
- **Fixed-rater nested designs** (Designs 2/3) — fixed raters nested in clusters/
  subjects is a further combination, deferred.
- **lme4 for the fixed/multilevel fits** as a selectable engine (oracle-only here) —
  its own later slice (ADR-012).
- The **averaged cluster-level `ICC(c,k)` on incomplete data** (open divisor, M9 §3b),
  a Bayesian/MCMC cross-engine, a three-facet `d_study()`, and the conflated
  single-level ICC (Eq. 14) — as in M9 (ROADMAP / M5 §8).

---

## References

- McGraw, K. O., & Wong, S. P. (1996). Forming inferences about some intraclass
  correlation coefficients. *Psychological Methods, 1*(1), 30–46. (Case 3 / 3A; the
  fixed-rater θ²_r term — inherited from M3 §6.)
- ten Hove, D., Jorgensen, T. D., & van der Ark, L. A. (2022). Interrater reliability
  for multilevel data: A generalizability theory approach. *Psychological Methods,
  27*(4), 650–666. (Design 1 subject-level decomposition — inherited from M5; the paper
  itself is a random-effects framework and does not define a fixed-rater coefficient.)
- (Full provenance for any asserted numeric value is registered in `REFERENCES.md`
  when the O-FML oracle values are committed, Slice 1.)
</content>
