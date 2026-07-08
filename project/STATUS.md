# Project status

- Milestone: **M15 — incomplete/ragged lme4 (full incomplete engine parity)** —
  shipped (PR #19, ADR-024). `engine = "lme4"` now matches glmmTMB across every
  incomplete design it fits too (incomplete random two-way, incomplete fixed-rater
  two-way, incomplete crossed random multilevel), degrading loudly to glmmTMB only at
  the variance boundary. M0–M15 all shipped; package at v0.1.0, submission-ready.
- **Milestone: M16 — parametric-bootstrap `ci_method`** (ADR-025, in flight): a second
  interval method (`ci_method = "bootstrap"`), both engines via a `simulate_refit()`
  contract. Scope pass + Slice 1 (glmmTMB two-way random) done this session (working tree).
- Active task: **M16 Slice 1 — done in working tree** (not yet committed/CI'd):
  `ci_method = "bootstrap"` for the glmmTMB two-way random design via the
  `simulate_refit()` engine contract; O1 (coverage of known population ICC) + O2
  (agreement with the MC interval within 0.06 on interior data) + reproducibility/RNG-
  hygiene oracles green (`test-ci-bootstrap.R`); full suite 588 pass / 0 fail, lint + `air`
  clean. Next code action: **Slice 2** — lme4 `bootMer` parity through the same contract.
- Last green CI: PR #19 (M15) full matrix green incl. Windows and R-devel; merged to
  `main` at b0dd492
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — non-Bayesian carryover sequencing recorded;
  M16 (bootstrap `ci_method`) scope pass (ADR-025) + Slice 1 (glmmTMB) done in working tree

## Where we are

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

**M16 in flight — parametric-bootstrap `ci_method` (ADR-025).** The first genuinely new
`ci_method`, and the multi-`ci_method` dispatch seam the eventual Bayesian `"posterior"`
method reuses. Chosen from the non-Bayesian carryovers as the lowest-estimand-risk item
with the highest infra ROI. Scope pinned (both engines via a `simulate_refit()` contract,
percentile interval, `d_study` stays MC-only). **Slice 1 (glmmTMB two-way random) is
implemented + oracle-tested in the working tree**; Slices 2 (lme4 `bootMer` parity) and 3
(design-family + refit-failure policy) remain.

**Agreed non-Bayesian carryover sequencing (this session).** Ordered by oracle-risk
(#1) — bank the clean-oracle wins before the open research question. Each promotion still
gets its own start-of-milestone scope pass + ADR; nothing beyond M16 is pre-committed:

- **Wave 1 (low-risk, clean oracle):** **M16 = parametric-bootstrap `ci_method`** (bootMer /
  glmmTMB `simulate` — in flight); + the **conflated single-level ICC (Eq. 14, ten Hove
  2022 — sourced)** as a thin slice.
- **Wave 2 (new estimand, attainable oracle):** **M17 = within-cell replicates**
  (split σ²_sr from σ²_e via `(1 | subject:rater)`; classical-GT / `gtheory` oracle); +
  **three-facet `d_study()`** as an adjacent feature slice.
- **Wave 3 (research):** **M18 = M9 averaged cluster-level `ICC(c,k)` on incomplete data**
  (open per-cluster divisor — a focused simulation-oracle study, likely a Fable review).
- **Deprioritized (opportunistic parity only):** boundary-robust lme4 interval for singular
  fits + merDeriv edge cases — glmmTMB covers these today.
- **Blocked, stays parked:** one-way / general ICC(1) via SEM — no faithful sourced route
  (ADR-014); not schedulable until a source appears.

The **Bayesian engine** (`ci_method = "posterior"`) is the remaining arc carry-over,
sequenced after these per the maintainer's current non-Bayesian focus.

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
