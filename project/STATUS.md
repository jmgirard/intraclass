# Project status

- Milestone: **M16 — parametric-bootstrap `ci_method`** — shipped (PR #21, ADR-025).
  `ci_method = "bootstrap"` is a second interval method (parametric bootstrap: simulate →
  refit → percentile interval) alongside the Monte-Carlo default, covering **every design
  both mixed-model engines fit** — two-way random/fixed, one-way, and all multilevel designs
  at both levels, complete and incomplete — via a shared `simulate_refit()` contract per
  engine (glmmTMB `simulate()`+refit; lme4 `bootMer`). `"lavaan"` stays Monte-Carlo-only; a
  singular lme4 fit defers to glmmTMB for either method. M0–M16 all shipped; package at
  v0.1.0, submission-ready. No milestone in flight.
- Active task: — (M16 shipped; next code work is a maintainer-chosen backlog promotion —
  see Next action for the Wave 1–3 sequencing.)
- Last green CI: PR #21 (M16) full matrix green incl. Windows and R-devel; merged to
  `main` at 0b84885
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — M16 merged (PR #21) + `project/` reconciled

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

**No milestone in flight — M16 shipped (PR #21, ADR-025).** `ci_method = "bootstrap"` is
live across every design both mixed-model engines fit; the multi-`ci_method` dispatch seam
is now in place for the eventual Bayesian `"posterior"` method. Next code work is a
maintainer-chosen backlog promotion from the sequencing below (each needs its own
start-of-milestone scope pass + ADR).

**Non-Bayesian carryover sequencing.** Ordered by oracle-risk (#1) — bank the clean-oracle
wins before the open research question:

- **Wave 1 (low-risk, clean oracle):** **M16 = parametric-bootstrap `ci_method`** — ✅
  **shipped** (PR #21); remaining Wave-1 item: the **conflated single-level ICC (Eq. 14,
  ten Hove 2022 — sourced)** as a thin slice (strongest next candidate — small, paper
  oracle).
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
