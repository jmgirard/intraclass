# Non-parametric bootstrap vs incumbents — one-way ICC (M62 comparison)

**Type.** Synthesis note (M62). Pre-registration first (this file, committed
*before* any results — GP5); results + verdict appended at T5.

**Question.** Is a non-parametric (cluster/subject-resample) bootstrap CI for the
one-way random ICC "not worse" than the package's incumbent interval methods
(Monte-Carlo default; parametric bootstrap)? Sources: ukoumunne2003 (method),
ohyama2025 (independent oracle). GO/NO-GO, no exported method.

---

## Pre-registration (frozen 2026-07-17, before any prototype run)

### Design

One-way random effects, balanced: `y_ij = μ + a_i + e_ij`, `i = 1…k` subjects,
`j = 1…n` ratings/subject; `a_i ~ N(0,σ²_a)`, `e_ij ~ N(0,σ²_e)`. Estimand
`ρ = σ²_a/(σ²_a+σ²_e)` (package one-way ICC, `ICC(1,1)` family). Fix
`σ²_a+σ²_e = 1`, `μ = 0`, Gaussian. `n_rep = 2000` datasets/cell (coverage
Monte-Carlo SE ≈ √(.95·.05/2000) ≈ 0.005 = 0.5 pp; matches ukoumunne/ohyama).

> **Prospective amendment (2026-07-18, before results): `n_rep` 2000 → 1000** for
> compute tractability (the incumbent parametric bootstrap is ~3.8 s/dataset).
> Coverage SE ≈ √(.95·.05/1000) ≈ 0.007 = 0.7 pp — still well within the 2 pp
> tolerance and the 1 pp incumbent slack, so the **criterion thresholds are
> unchanged** (GP5: estimation precision reduced, the bar is not moved).

### Cells

**Comparison cells** (interrater-realistic; the verdict rests on these):

| cell | k (subjects) | n (ratings) | ρ | role |
|---|---|---|---|---|
| C1 | 30 | 4 | 0.50 | interior / comfortable |
| C2 | 30 | 4 | 0.05 | near-zero-ICC boundary (σ²_a→0) |
| C3 | 12 | 4 | 0.50 | few-subjects (GP6; ukoumunne under-coverage regime) |
| C4 | 12 | 4 | 0.05 | corner: few-subjects × boundary (worst case) |

**Oracle-check cells** (validate the NBOOT *implementation*, not the verdict —
match ukoumunne2003 Fig. 2, normal): `k ∈ {10,30,50}`, `n = 10`, `ρ = 0.05`. Our
transformed bootstrap-t coverage must track their published curve (≈0.94–0.95
transformed; the untransformed bootstrap-t / BCa ≈0.82–0.90 at k=10) within a
plot-read tolerance (±0.03).

### Methods

- **Incumbents:** MC (`ci_method="montecarlo"`, glmmTMB REML covariance) and
  parametric bootstrap (`ci_method="bootstrap"`).
- **Candidate (non-parametric bootstrap):** resample whole **subjects** with
  replacement (ukoumunne2003 §3.1 "strategy 1"), refit, and form:
  - percentile (baseline), and
  - the **`log F` variance-stabilizing transformed bootstrap-t** with an
    infinitesimal-jackknife SE (ukoumunne2003 §4, eq. 6–7) — the paper's
    recommended variant and the **primary** candidate.
  - BCa reported as an additional reference point.
  `2000` bootstrap resamples/dataset.

### "Not worse" criterion (GP5 — fixed before results)

Nominal 95%. Methods evaluated on the **same** simulated datasets per cell
(paired). The candidate variant is **"not worse" at a cell** iff BOTH:

1. **Near nominal:** empirical coverage ≥ **0.93** (nominal − 2 pp; under-coverage
   is the failure — over-coverage passes (1) but is penalized on width).
2. **Not below the incumbents:** empirical coverage ≥ (min of the two incumbents'
   coverage at that cell) − **0.01** (≈ 2·SE paired slack).

**Tiebreaker (width):** among variants passing (1)+(2), prefer smaller **median
interval width**; a narrower interval that fails (1) or (2) does **not** win.

**Overall GO** iff the primary candidate (transformed bootstrap-t) is "not worse"
at **every** comparison cell — C2/C3/C4 (boundary / few-subjects) are decisive.
Otherwise **NO-GO**. The percentile/BCa variants are reported for context, not as
the GO gate.

**Prior (not the verdict).** ohyama2025 finds NBOOT slightly *worse* than the
classical F CI, with REML best; ukoumunne2003 finds untransformed bootstraps
under-cover at k≈10. Expectation is NO-GO; the pass confirms empirically (GP5 —
the evidence decides, not the prior).

---

## Results (T5, 2026-07-18)

Source: `data-raw/m62-coverage-harness.R` → `data-raw/m62-coverage-results.rds`.
`n_rep = 1000` (coverage SE ≈ 0.7 pp), incumbent parametric bootstrap `B = 199`,
prototype `B = 2000`. `boott` = transformed bootstrap-t (primary candidate).
`n_ok` = datasets on which the method returned an interval (MC defers at the
boundary via `intraclass_singular_fit`); MC coverage is *conditional* on `n_ok`.

**Oracle cross-check (prototype vs ukoumunne2003 Fig. 2, normal; PRINCIPLES.md #1) — PASS.**

| cell (k, n=10, ρ=0.05) | perc | boott | bca |
|---|---|---|---|
| U10 | 0.770 | 0.921 | 0.820 |
| U30 | 0.904 | 0.947 | 0.922 |
| U50 | 0.918 | 0.953 | 0.937 |

Reproduces the published pattern — untransformed variants under-cover at small k,
the transformed bootstrap-t stays near nominal, all converge by k=50.

**Comparison cells (coverage / median width; MC `n_ok` in parens).**

| cell | MC (default) | param. boot | **boott** | perc | bca |
|---|---|---|---|---|---|
| C1 (30,4,.50) | .956 / .358 (1000) | .933 / .362 | **.940 / .369** | .919 / .352 | .923 / .337 |
| C2 (30,4,.05) | .876 / .445 (716) | .990 / .188 | **.940 / .340** | .918 / .293 | .915 / .302 |
| C3 (12,4,.50) | .980 / .542 (995) | .922 / .564 | **.937 / .590** | .864 / .537 | .878 / .482 |
| C4 (12,4,.05) | .846 / .679 (612) | .989 / .307 | **.934 / .580** | .864 / .412 | .890 / .421 |

**Criterion applied (primary candidate = boott).** Not-worse at a cell iff
coverage ≥ 0.93 AND ≥ min(incumbents) − 0.01:

| cell | boott cov | ≥0.93? | min(MC,pboot)−.01 | ≥incumbent? | not worse? |
|---|---|---|---|---|---|
| C1 | .940 | ✓ | .923 | ✓ | ✓ |
| C2 | .940 | ✓ | .866 | ✓ | ✓ |
| C3 | .937 | ✓ | .912 | ✓ | ✓ |
| C4 | .934 | ✓ | .836 | ✓ | ✓ |

→ **transformed bootstrap-t is "not worse" at every cell.** percentile and BCa
under-cover at C3/C4 (0.86–0.89 < 0.93) → they fail. Framing (RR01): the
transformed bootstrap-t is in fact the **only** method of the five that clears
0.93 at *all four* cells (MC fails C2/C4; parametric bootstrap fails C3;
perc/BCa fail C3/C4) — the honest statement is "the only near-nominal-everywhere
method", and the frozen absolute 0.93 floor (not the incumbent-relative clause)
is what carries the verdict, which is what keeps the comparison non-circular.

**Two findings that flip the prior expectation.**
1. The prior (ohyama2025: NBOOT slightly worse than SEARLE/REML) was measured
   against boundary-robust *classical* F/REML CIs. The package's actual default
   is glmmTMB **MC, which under-covers AND defers on 28–39 % of near-zero-boundary
   datasets** (C2/C4 `n_ok` 716/612). Against *our* incumbents, the transformed
   bootstrap-t is not worse — and materially more robust at the boundary (covers
   ~0.94 where MC gives no interval a third of the time).
2. Only the **transformed** bootstrap-t clears the bar; the untransformed
   percentile/BCa under-cover (as ukoumunne2003 found) — so any GO is specifically
   for the `log F` variance-stabilized bootstrap-t, not "bootstrap" generically.

**Cost:** at the clean interior cell, boott is ~3 % wider than MC (0.369 vs 0.358)
— a small width price for boundary robustness.

**Marginality caveat (C4).** At n_rep=1000 (SE = √(.934·.066/1000) ≈ 0.0079) the
corner cell C4 is the tightest: boott 0.934 sits **~0.5 SE** above the 0.93 floor
(RR01 correction; the earlier "~1 SE" was wrong) — under a flat prior
P(true coverage < 0.93) ≈ 30 %, so genuinely marginal. A confirmatory n_rep=2000
run was launched then cut (~5–6 h, dominated by slow near-boundary
parametric-bootstrap refits; maintainer decision 2026-07-18; RR01 rec 6 concurs
the cut buys nothing this pass needs). The **qualitative GO is unaffected**: even
at a true ~0.925, boott gives a near-nominal interval where the MC default
returns *nothing* on 39 % of C4 datasets. Firming C4 is deferred to the
exported-implementation milestone, **conditional (RR01 rec 2) on** that milestone
(i) including a C4-type corner at n_rep ≥ 2000, (ii) tracking lower/upper
tail-error rates (not just two-sided coverage — ukoumunne Table I shows why),
and (iii) pre-specifying the below-floor fallback (label the limitation or
withhold the export — decided before the data, GP5).

**Parametric-bootstrap boundary rows are degenerate, not strong (RR01 rec 4).**
The pboot 0.99 coverage / narrow width at C2/C4 is genuine but *not* boundary
merit: at σ̂²_a = 0 the glmmTMB refit simulates pure noise, so (ICC being
scale-invariant) the resampling distribution of ρ* depends only on (k, n) — the
percentile interval collapses to the ρ=0 sampling spread (≈ [0, 0.28] at k=12,
n=4) and, with the harness's fixed seed, is *literally identical* across singular
datasets. It covers the small true ρ=0.05 by accident of position and would badly
miss a larger truth; pboot already fails the floor at C3 (0.922). Do not read the
.99/.19 rows as "pboot excellent at the boundary".

**Side observation (out of scope → candidate):** the MC-default boundary
abort/under-coverage suggests a boundary-robust classical CI (SEARLE F / Burch
REML) would also help the one-way default — a separate idea, not this pass.

## Verdict (T6)

**GO** for the `log F` transformed bootstrap-t on the balanced one-way ICC;
**NO-GO** for percentile/BCa. Basis: the only method near-nominal at every cell;
source-backed (ukoumunne2003) and oracle-validated (RR01 independently reproduced
C4/U10 to 4 dp; oracle within ±0.03). **RR01 (Fable, 2026-07-18) concurs.**

Framing carried into the decision (RR01 Q3): the GO does **not** claim the
bootstrap-t fixes the MC default's one-way boundary defect (28–39 % classed
aborts + 0.85–0.88 conditional coverage). A boundary-robust *classical* default
(SEARLE exact-F / Burch REML) would likely dominate on normal cells and is now a
tracked roadmap candidate; the bootstrap-t's residual value is non-normality
robustness (ukoumunne Fig. 3) and an interval that *exists* where the default
aborts. Recorded as D-006.
