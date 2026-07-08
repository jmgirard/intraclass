# Project status

- Milestone: **M20 — Within-cell replicate completeness (fixed-rater, multilevel, ragged)** —
  **shipped** (PR #25, ADR-030; third milestone of the M18–M21 arc, ADR-027). Extended the M17
  within-cell replicate estimand beyond two-way-random/single-level/balanced: **Slice 1** fixed-rater
  (θ²_r via shipped `theta2r_fixed()`; balanced fixed≡random exact pin); **Slice 2** multilevel,
  crossed D1 + nested D2 (`(1|cluster:subject:rater)`; Design 3 ⚫ by-design) + a `d_study()`-on-
  replicate correctness guard; **Slice 3** ragged single-occasion (extends via `k_eff`;
  occasion-averaged **degraded to 🟣 research** — no validated effective-`n_o` divisor). Plus a
  finish-task fix: `rmvn()` aborts classed on a non-finite MC covariance. Completeness, not new
  estimand work; no new dependency/argument/estimand-spec. M0–M20 shipped; package at v0.1.0.
  **No milestone in flight** — M21 (SEM parity) next, scoped by its own start-of-milestone ADR.
- **M21 — SEM (lavaan) engine parity — IN FLIGHT** (arc's last, ADR-027; scoped by ADR-031,
  2026-07-08). Promotes the M7 lavaan deferrals toward lme4-style parity, engine parity not new
  estimand work: **Slice 1** lavaan bootstrap `ci_method` (reuse M16 `simulate_refit` seam;
  lowest risk); **Slice 2** fixed-rater SEM (oracle-first catch: does fixed agreement need a
  distinct θ²_r or coincide with M7's finite-intercept estimator?); **Slice 3** incomplete/FIML SEM
  (consistency exact; agreement **attempt-then-degrade to 🟣 research**, maintainer decision).
  Multilevel SEM + one-way SEM stay out (reclassified/blocked, ADR-027/014). Board = the M21 DoD
  checklist in MILESTONES.md.
- Active task: **M21 Slice 2 — fixed-rater SEM** (next). **Slice 1 (lavaan bootstrap) ✅ done** on
  branch `m21-sem-parity`: `lavaan_simulate_refit` factory (parametric bootstrap from the fitted
  SEM's implied moments) + shared `lavaan_components()`; `ci_method = "bootstrap"` now works for
  `engine = "lavaan"` on the random two-way path. Oracles: O1 consistency population-coverage, O2
  bootstrap≈MC (same estimand) + cross-engine consistency, well-formed/reproducible. Not yet
  committed/merged. See the DoD checklist in MILESTONES.md.
- Last green CI: **PR #25 (M20) full matrix green incl. Windows and R-devel; merged to `main` at
  137fb98** (the codecov upload flaked once on a bad GPG signature — re-ran green; infra, not the
  diff).
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M21 Slice 1 (lavaan bootstrap) landed on
  `m21-sem-parity`** (not yet committed at time of writing; air + lintr clean, docs regenerated;
  test-ci-bootstrap.R + test-icc-lavaan.R green under `load_all` + `NOT_CRAN`). Prior: **M21 scoped
  and opened (ADR-031); in flight.**
  Short retro (M20 landed clean in one arc-consistent shot) → scoping ADR fixing three slices
  (bootstrap → fixed → incomplete/FIML, order kept per maintainer), estimand posture (engine
  parity, no new estimand-spec — only a FIML-SEM oracle note), and per-slice oracles (glmmTMB the
  independent oracle, consistency exact / agreement at the SEM estimator's bar). Two scope
  questions confirmed: keep ADR-027 slice order; FIML agreement attempt-then-degrade to 🟣 research.
  M21 DoD checklist set live in MILESTONES.md. No code yet — Slice 1 (lavaan bootstrap) is next.
  Prior line: M20 merged (PR #25, ADR-030), 894 tests, `--as-cran` 0/0/0, full matrix green.

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

**M18, M19 & M20 shipped and merged (PR #23/#24/#25, ADR-028/029/030); M21 scoped and
now in flight (ADR-031).** The **M18–M21 completeness arc** (ADR-027) closes every 🔵
*not yet* gap in [`COVERAGE.md`](COVERAGE.md). Next code work is **M21 Slice 1 — lavaan
bootstrap `ci_method`** (reuse the M16 `simulate_refit` seam; DoD checklist in
[`MILESTONES.md`](MILESTONES.md)). Only M21 remains in the arc.

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027):**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** ✅ shipped (PR #24) — incomplete
  nested + fixed-rater nested Design 2.
- **M20 — Within-cell replicate completeness:** ✅ shipped (PR #25) — fixed-rater · multilevel
  (crossed D1 + nested D2) · ragged single-occasion replicates. Occasion-averaged-ragged degraded
  to 🟣 research (no validated effective-`n_o` divisor). Extends M17 Slice 3.
- **M21 — SEM (lavaan) engine parity:** 🚧 **in flight** (ADR-031) — lavaan bootstrap (Slice 1,
  next), fixed-rater SEM (Slice 2), incomplete/FIML SEM (Slice 3, agreement attempt-then-degrade).
  The lavaan analog of the lme4 M5.5→M15 arc.

**Reclassified out of the arc (ADR-027):** multilevel SEM → cross-cutting "later" bucket
(research-flavored, sits beside Bayesian); lavaan + replicates → ROADMAP unscheduled (niche).

**Still to sequence (excluded from the M18–M21 arc, later):**

- **Wave 3 (research):** **M9 averaged cluster-level `ICC(c,k)` on incomplete data** (open
  per-cluster divisor — a focused simulation-oracle study, likely a Fable review). *Bounds
  M18 Slice 3 to the subject level.*
- **Cross-cutting, later:** the **Bayesian engine** (`ci_method = "posterior"`);
  **categorical/ordinal GLMM ratings**; **multilevel SEM**; non-parametric/profile-likelihood
  CIs; boundary-robust lme4 singular-fit + merDeriv edge cases (glmmTMB covers these today).
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
