# Fable review response — Bayesian ragged nested Design-3 credible-interval coverage (M32 Slice 2)

**Reviewer:** Claude Fable 5 (gated statistical review, PRINCIPLE #19), 2026-07-10.
**Brief:** `../../project/fable-brief-m32-s2.md`.
**Verification harness (this review's, seeded, committed):** `fable-check-m32s2.R` (same
directory) — three arms: a high-precision frequentist contrast (6,000 shipped-`icc()`
glmmTMB + MC-interval fits, no Stan), and two live-Stan arms (680 brms fits through the
shipped `fit_brms_nested_subjects()` → `brms_component_draws()` → `posterior_summary()`
recipe) with per-rep mechanism diagnostics (PIT of the population value in the posterior,
posterior sd, convergence) and a **paired** glmmTMB interval on the identical dataset.
Per-rep results committed as `fable-check-m32s2-results.rds`. I independently reconstructed
the fixture's seeded incidence (deterministic; k_eff = 30/7 ≈ 4.2857, accepted seed 32203)
and confirmed the brief's §2 table cell-for-cell against the committed fixture before
re-running anything.

---

## 0. Verdict

**The ragged Design-3 undercoverage does not replicate. There is no calibration shortfall
to correct — the fixture's .8625 cell was a Monte-Carlo tail event at n_rep = 80, not a
property of the estimator.** On the brief's §4 dichotomy: **(A) with an empty correction** —
no correction is warranted or admissible (any adjustment would be tuned to noise, #4), and
**(B) deferral is not supported by the evidence**. M32 Slice 2 should **ship unchanged**,
with the committed coverage fixture **regenerated at n_rep ≥ 240 under per-rep seeding**
(pre-registered protocol in §5, so the regeneration is a precision upgrade, not
seed-shopping) — the pins themselves stay exactly as written, including ragged ≥ .88.

The quantified coverage of the shipped Bayesian percentile interval on ragged Design-3
data, with fresh randomness throughout:

| evidence arm | n reps | ICC(1)=ICC(k) coverage | Wilson 95% CI |
|---|---|---|---|
| **original fixture incidence, re-run** | **240** | **.9458** | [.910, .968] |
| four fresh incidences (80 each) | 320 | .9500 | [.920, .969] |
| pooled fresh ragged evidence | 560 | .9482 | [.927, .964] |
| pooled **including** the fixture's 69/80 | 640 | .9375 | [.916, .954] |
| frequentist arm, same original incidence | 2,000 | .9555 | [.946, .964] |

Under a true coverage of .8625, observing 227/240 on the very same incidence is a
z ≈ +3.8 event — the fixture's number is decisively excluded. Under nominal ~.95, the
fixture's 69/80 has one-sided P ≈ .002–.003: rare, but it is the *only* observation out
of ~6,700 verification fits that shows any shortfall, and even pooling it in, the combined
estimate (.9375, CI [.916, .954]) is compatible with nominal.

## 1. What I verified before re-running (all claims in the brief's §2 hold)

- The committed fixture matches §2 cell-for-cell (coverage .975/.975 complete,
  .8625/.8625 ragged; MAP rel-bias ≈ 0; convergence .975/.95; k_eff 4.2857).
- The oracle script is a clean seeded coverage study: DGP correct for ten Hove Eq. 10–11,
  estimand transcribed from Table 3 (right column) via `icc_estimand(oneway = TRUE,
  multilevel = TRUE, level = "subject")` — signal σ²_{s:c}, error the confounded residual,
  cluster variance correctly excluded as nuisance; fixture written before the pins;
  `brms`/`rstan` never touch R's RNG (checked in the installed namespaces), so the 80 reps
  are valid iid Bernoulli trials.
- The Slice-2 working-tree diff is pure guard-narrowing in `icc()` (no fit-side change),
  and the committed test fails only on pin (3), as intended (#18).
- The reconstructed incidence is **mild**: ratings/subject = 5/4/3 for 50/40/10 subjects,
  k_eff = 30/7. Nothing adversarial in its structure.

## 2. Identical ICC(1)/ICC(k) coverage is structural, not evidence

One §2 "feature to confirm" dissolves on derivation: ICC(k_eff) is a strictly monotone
per-draw transform of ICC(1) (both are σ²_s/(σ²_s + σ²_res/d), d = 1 vs k_eff, with the
population values under the same map), and percentile intervals are equivariant under
monotone transforms — so the two coverage indicators are **identical by construction** in
every rep, in every cell, in both engines. The .8625/.8625 pairing carried no information
beyond one number.

## 3. Every proposed mechanism is rejected

- **The brief's k_eff under-propagation hypothesis** fails a priori and empirically:
  ICC(1) takes **no divisor** — k_eff never enters the undercovering ICC(1) interval —
  yet ICC(1) undercovered identically (necessarily, §2). Empirically the interval is
  calibrated (below).
- **Adversarial single incidence:** rejected. The *same* incidence covers .9458 (Bayes,
  n = 240) and .9555 (frequentist, n = 2,000); four fresh incidences cover
  .950/.925/.9625/.9625 (Bayes) and .960/.941/.937/.946 (frequentist, n = 1,000 each).
- **Reflected-KDE MAP / percentile interacting with a skewed one-way posterior:**
  rejected. The pooled PIT of the population value across 560 ragged posteriors is
  indistinguishable from uniform (KS D = .028, p = .76) — no under-dispersion U-shape,
  no displacement skew. MAP rel-bias ≈ −.005.
- **Genuine finite-sample miscalibration that would shrink with N:** rejected at this N —
  there is nothing to shrink. Mean posterior sd of the ICC(1) draws (.0486 on the original
  incidence) matches both the empirical sampling sd of the MAP (.0509) and the frequentist
  sampling sd (.0482); the mild raggedness costs almost no information (frequentist
  empirical sd .0475 complete → .0482 ragged). This is the Bernstein–von Mises regime
  (100 subjects, 340 residual df), where a real 9-point coverage collapse from 12%
  missingness in a correctly specified model has no room to exist.
- **Convergence contamination is real but tiny:** coverage conditional on the shipped
  convergence flag is .9510 (n = 551); the 9 non-converged ragged fits covered at .778.
  It cannot move a cell by more than ~a point and is already surfaced to users via the
  classed warning.

Two live demonstrations of the actual mechanism — n ≈ 100 cell noise — fell out of the
paired design: my own complete-cell anchor ran at .9083 (Bayes) / .9167 (paired glmmTMB,
identical data) over 120 reps, while the 2,000-rep frequentist arm pins that same cell at
.960; and the fixture's own complete cell ran *high* (.975). The Bayes and frequentist
indicators move together because they share the data draws — cells this size swing ±.05
routinely, in both directions, in both engines.

## 4. Why the pin fired, and what it implies for the oracle protocol

At n_rep = 80 and true coverage .95, the ragged ≥ .88 pin false-alarms with
P(X ≤ 70) ≈ .0065 per cell. Across the growing family of committed n_rep-80 coverage
cells (M23–M32), an eventual firing was close to expected — this one happened to be a
~.002 draw. At n_rep = 240 the same pin under a nominal method false-alarms at ~1e-5.
Two protocol notes for the regeneration (both about the oracle *script*, not the
estimator):

1. **Per-rep seeding.** The shipped script draws all data from one continuous RNG stream
   seeded once, so a cell cannot be extended without changing every downstream rep
   (`set.seed(base_seed)` before the complete loop means bumping n_rep re-deals the ragged
   cell entirely). Seed each rep as `set.seed(cell_offset + r)` (as `fable-check-m32s2.R`
   does) so cells are extendable and individually reproducible.
2. **The frequentist gap is now closed in passing:** M19 committed no ragged nested
   Design-3 *coverage* evidence (its oracle pinned point reductions/recovery only). The
   6,000-fit frequentist arm here (.9555/.960/.937–.960) is that evidence; the results
   object is committed with this review.

## 5. Recommended disposition (advisory, #19 — the maintainer records and implements)

1. **Ship M32 Slice 2 unchanged** — guard-narrowing, fit, reducers, gates all verified
   correct; the estimator needs no correction and the design needs no deferral.
2. **Regenerate `bayesian-incomplete-nested-subjects-oracle.rds` with n_rep = 240 per
   cell and per-rep seeding, keeping every pin exactly as committed** (ragged ≥ .88,
   within .06 of complete, convergence ≥ .90, rel-bias bounds). Pre-registered
   prediction, so this is confirmation rather than tuning (#4): complete and ragged both
   land in [.92, .975]; a ragged result below .90 at n_rep = 240 would falsify this
   review and reopen it. Do not drop the original run from the record — the follow-up
   ADR-042 amendment should state that the n_rep-80 cell read .8625 and why.
3. **Adopt n_rep ≥ 240 (or pooled ≥ 200 with a documented false-alarm budget) for future
   ragged coverage cells** — at n_rep = 80 the ≥ .88 pin carries a ~0.7% per-cell
   false-alarm rate that will keep firing as the family grows.
4. Optional, cheap: record the frequentist ragged-D3 coverage evidence (§4.2) in the
   O-NML/incomplete registry entry so the M19 estimator's interval is no longer
   coverage-unevidenced.

**Falsifiability of this verdict:** the single committed artifact that would overturn it
is a regenerated fixture (item 2) with ragged coverage < .90 at n_rep = 240 — probability
~1e-5 under this review's estimate of the truth, ~.55 under the fixture's .8625.
