# Project status

- Milestone: **M23 — Bayesian engine (brms) + `ci_method = "posterior"`, two-way random** —
  **in flight** (opened by ADR-033; the first Bayesian milestone, promoting the cross-cutting
  carryover deferred at M7/ADR-014). A **thin two-way-random slice** mirroring M5.5 (lme4) / M7
  (lavaan) — engine + interval method, **not** new estimand work; additive, non-breaking (#6). Backend
  **brms** (rstan, new `Suggests` behind `check_installed()`; rstanarm parked). Prior **half-*t*(4,0,1)
  on all random-effect SDs**, sourced ten Hove et al. (2020) §3.3/§4.1. **MAP** point estimate (mode
  of ICC draws via a hand-rolled boundary-aware `posterior_mode()`, no new dep; EAP is biased),
  **percentile** credible interval (reuses M16 `bootstrap_interval()`). `"posterior"` **forced-default
  & Bayesian-only** (selectable coupling parked). **Slice 1** engine + `posterior_summary()` wired
  end-to-end; **Slice 2** seeded MCMC + O-Bayes coverage oracle (reproduce ten Hove 2020's DGP, commit
  reference vs OSF `shkqm`; cross-impl vs their rstan; MAP ≈ REML; convergence). DoD board live in
  MILESTONES.md. Corroborated by ten Hove et al. (2022) — brms companion software, MCMC ≈ MLE points,
  MC-CI for non-normal ICCs.
- Prior milestone: **M22 — `d_study()` projection off a within-cell replicate fit** — **shipped**
  (PR #27, ADR-032; small standalone milestone after the M18–M21 arc). Promoted the one deferred
  `d_study()` corner (M17 §7 / M20): projecting the rater count `m` off a replicate fit, using the
  per-component `error_divisors` M17 already delivered (rater/interaction ÷ `m`, pure error ÷
  `m·n_o`), one curve per occasion setting (a new `occasions` column). **Slice 1** single-level
  two-way (fixed consistency via Spearman–Brown; fixed agreement refused) and **Slice 2**
  multilevel (crossed D1 + nested D2, subject across occasions, cluster single-occasion). Oracle
  O-RepDS (reduction at `m = k_eff` + cross-engine + Spearman–Brown + seeded coverage +
  monotone/[0,1]). No new estimand/spec/argument/dependency. Occasion projection and
  ragged-replicate projection stay deferred.
- Prior milestone: **M21 — SEM (lavaan) engine parity (bootstrap, fixed-rater, incomplete/FIML)** —
  **shipped** (PR #26, ADR-031; the **last milestone of the M18–M21 completeness arc**, ADR-027).
  Promoted the three M7 lavaan deferrals to lme4-style parity, engine parity not new estimand work:
  **Slice 1** `ci_method = "bootstrap"` for lavaan (M16 `simulate_refit` seam; `lavaan_simulate_refit`);
  **Slice 2** fixed-rater SEM — the Case-3A bias-corrected θ²_r (distinct from M7's raw; reduces to
  glmmTMB fixed AND random on balanced data, the M10 identity); **Slice 3** incomplete/FIML SEM
  (`missing = "fiml"`; attempt-then-degrade **resolved to ships** — consistency ≤8e-3, agreement
  ≤1.5e-2 vs glmmTMB, the raw-SEM small-sample bias not a FIML artifact; bootstrap gated on
  incomplete data). No new estimand/spec/argument/dependency. **The M18–M21 arc is complete — every
  🔵 not-yet gap in `COVERAGE.md` is closed.** M0–M21 shipped; package at v0.1.0.
- Active task: **M23 Slice 2 — reproducibility + the coverage oracle (O-Bayes)** (next; DoD board in
  MILESTONES.md M23). Seeded MCMC + convergence checks, `data-raw/oracle-bayesian.R` reproducing ten
  Hove 2020's DGP with committed reference values (#4) vs OSF `shkqm`, and the O-Bayes tests
  (coverage/MAP-bias at k > 2, cross-impl, MAP ≈ REML, convergence). **Slice 1 shipped** (below).
- Slice 1 (done, on branch `m23-bayesian`): Bayesian engine + `posterior_summary()` end-to-end —
  `R/engine-brms.R` (`fit_brms_twoway()`, half-*t*(4,0,1) prior, `draws` field on the natural
  variance scale), `R/ci-posterior.R` (`posterior_mode()` reflected-KDE + `posterior_summary()`),
  the `"posterior"` branch + forced-default/Bayesian-only coupling + brms-only `brm_args` passthrough
  in `R/icc.R`, `brms (MCMC)`/`posterior credible` in the print header. **Backend override resolved
  to a brms-scoped `brm_args = list()` passthrough** (default rstan; forwards backend/chains/iter/
  cores to `brm()`; guards the sourced half-*t* `prior`/formula/data/`seed` we own, #12; aborts off
  brms) — a new user-facing arg → **ADR-033 amendment** recorded in DECISIONS.md + the `icc.R` commit.
  306 pkg tests 0F/0W (incl. one live brms fit under `NOT_CRAN`); lint + spelling clean. Not yet run:
  `R CMD check --as-cran` and the full CI matrix (milestone-close gates). Remaining non-M23 work lives in `ROADMAP.md`: multilevel SEM, categorical/ordinal
  GLMM, the Wave-3 averaged cluster-level `ICC(c,k)` incomplete divisor, occasion-`d_study()`, and
  the CRAN upload (ADR-022).
- Last green CI: **PR #27 (M22) full matrix green incl. Windows and R-devel (all 9 jobs); merged to
  `main` at `8375184`.** Prior: PR #26 (M21), 925 tests, `R CMD check --as-cran` 0/0/0.
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M23 Slice 1 shipped on branch `m23-bayesian`**
  (engine + `ci_method = "posterior"` end-to-end; `brm_args` passthrough per the ADR-033 amendment;
  306 tests 0F/0W incl. a live brms fit; lint + spelling clean). Prior updates this day: Slice 1
  started (`/start-task`); M23 opened (ADR-033). Next: Slice 2 (O-Bayes coverage oracle). A source-reviewed planning session (ten Hove 2020 hyperprior paper + 2022 guidelines
  corroboration) resolved every design fork for the first Bayesian milestone: brms backend
  (`Suggests`; rstanarm parked), half-*t*(4,0,1) prior, MAP point via a hand-rolled boundary-aware
  `posterior_mode()` (no new dep), percentile credible interval, `"posterior"` forced-default &
  Bayesian-only. ADR-033 written (accepted); MILESTONES M23 board added (live DoD checklist) +
  preamble → M23 in flight; STATUS flipped. No code yet. Next: `/start-task` → M23 Slice 1 on a
  `m23-bayesian` branch. (M22 remains the last shipped: PR #27, ADR-032.)

## Where we are

**Support matrix** — [`COVERAGE.md`](COVERAGE.md) is the current-state stock-take of
what the `icc()` / `d_study()` argument space supports today, with a reason category
(not yet / research / blocked / by design) for every gap. Derived, not authoritative;
refresh it when a milestone ships.

**Shipped M0–M15** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam, and **lme4 now has full design parity with glmmTMB — two-way
random/fixed, one-way, and every multilevel design, on both balanced (M14) and
incomplete/ragged (M15) data** (degrading to glmmTMB only at the variance boundary);
the multilevel
estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); the crossed design handles **incomplete (ragged)**
data (subject level + cluster-level `ICC(c,1)`) with a declared-`design` disambiguation
and oracle-pinned identifiability guards (M9); and the crossed design also supports
**fixed raters** at the subject level, balanced (M10). The multilevel family is now
crossed × {complete, incomplete} × {random, fixed} at the subject level. Every fitted
`icc` object now has `autoplot()`/`plot()` methods — a coefficient forest plot and a
variance-component decomposition (M11). And `choose_icc()` turns the *Choosing an ICC*
decision tree into an interactive/programmatic helper that recommends a coefficient and
emits the exact `icc()` call — teaching/API, no new estimand (M12). And release polish
brought the pkgdown site, the M9–M12 showcase in `advanced.Rmd`, and a **CRAN-submittable
v0.1.0** (`--as-cran` 0/0/0), closing the ADR-017 arc (M13).

## Next action

**M23 (ADR-033) is in flight — the first Bayesian milestone.** Start **Slice 1**: the brms
engine (`R/engine-brms.R`, `fit_brms_twoway()` + half-*t*(4,0,1) prior) and the posterior
interval method (`R/ci-posterior.R`, `posterior_mode()` + percentile `posterior_summary()`),
wired through the `"posterior"` branch + forced-default/Bayesian-only coupling in `R/icc.R`.
The full DoD checklist is the live board in [`MILESTONES.md`](MILESTONES.md) M23. Run
`/start-task` to branch `m23-bayesian` and begin. The M18–M21 completeness arc (ADR-027) is
complete (PR #23/#24/#25/#26) and M22 shipped (PR #27); the remaining backlog beyond M23 is in
[`ROADMAP.md`](ROADMAP.md) (multilevel SEM, categorical/ordinal GLMM, the Wave-3 `ICC(c,k)`
divisor). The out-of-band **CRAN upload** (ADR-022) also remains.

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027) — ALL SHIPPED:**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** ✅ shipped (PR #24) — incomplete
  nested + fixed-rater nested Design 2.
- **M20 — Within-cell replicate completeness:** ✅ shipped (PR #25) — fixed-rater · multilevel
  (crossed D1 + nested D2) · ragged single-occasion replicates. Occasion-averaged-ragged degraded
  to 🟣 research (no validated effective-`n_o` divisor). Extends M17 Slice 3.
- **M21 — SEM (lavaan) engine parity:** ✅ shipped (PR #26, ADR-031) — lavaan bootstrap, fixed-rater
  (Case-3A θ²_r), incomplete/FIML (ships, no degrade). The lavaan analog of the lme4 M5.5→M15 arc.

**Reclassified out of the arc (ADR-027):** multilevel SEM → cross-cutting "later" bucket
(research-flavored, sits beside Bayesian); lavaan + replicates → ROADMAP unscheduled (niche).

**Still to sequence (excluded from the M18–M21 arc, later):**

- **Wave 3 (research):** **M9 averaged cluster-level `ICC(c,k)` on incomplete data** (open
  per-cluster divisor — a focused simulation-oracle study, likely a Fable review). *Bounds
  M18 Slice 3 to the subject level.*
- **Cross-cutting, later:** the **Bayesian engine** two-way random path + `ci_method =
  "posterior"` is now **M23, in flight** (ADR-033); its parity follow-ons (Bayesian
  fixed/one-way/multilevel/incomplete/replicates) remain later. **categorical/ordinal GLMM
  ratings**; **multilevel SEM**; non-parametric/profile-likelihood CIs; boundary-robust lme4
  singular-fit + merDeriv edge cases (glmmTMB covers these today).
- **Blocked, stays parked:** one-way / general ICC(1) via SEM — no faithful sourced route
  (ADR-014); not schedulable until a source appears.

**CRAN submission (out of band, ADR-022).** See below.

**Out-of-band thread (unchanged): CRAN submission (ADR-022).** The package is
submission-ready. A max-effort code review of the statistical core (2026-07-07)
verified the estimand/CI/engine math is correct and fixed 12 edge-guard / validation /
robustness findings (PR #20, merged `cae1c33`; regression tests in
`test-review-fixes.R`). Before uploading, run **win-builder** (R-devel + release) and
**R-hub**, then update the "will be run immediately before submission" line in
`cran-comments.md` with the results. `intraclass` does not (and cannot) submit for you.
*(Note: M14 — and now M15 — fold their changes into the existing `0.1.0` NEWS section
rather than bumping to a dev version, on the basis that 0.1.0 has not yet been uploaded
— revisit if 0.1.0 is frozen for submission.)*

The full carryover inventory (Bayesian + non-Bayesian, sourced vs. blocked) lives in the
parking lot in [`ROADMAP.md`](ROADMAP.md); the near-term ordering of the non-Bayesian
items is the sequencing plan above.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
