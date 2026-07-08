# Project status

- Milestone: **M17 — variance-decomposition trio** — **shipped** (PR #22, ADR-026). Three
  slices: **(1)** conflated single-level ICC via `level = "conflated"` (ten Hove Eq. 14, a
  diagnostic contrast off the M5 fit; agreement-only); **(2)** multilevel rater-count
  `d_study()` at subject + cluster levels (retargeted from the original subjects-per-cluster
  plan — the cluster ICC has no subject facet, ADR-026 amend); **(3)** within-cell replicates
  splitting σ²_res → σ²_sr + σ²_e via `(1 | subject:rater)`, plus an occasion-averaged
  coefficient (`occasions` knob, per-component error divisors). No new dependency (`gtheory`
  proved unnecessary). M0–M17 all shipped; package at v0.1.0, submission-ready. No milestone
  in flight.
- Active task: — (M17 shipped; next code work is a maintainer-chosen backlog promotion — see
  Next action for the sequencing.)
- Last green CI: PR #22 (M17) full matrix green incl. Windows and R-devel; merged to
  `main` at a915256
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — M17 merged (PR #22) + `project/` reconciled
  (MILESTONES board + ROADMAP promotion)

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

**M17 shipped (PR #22, ADR-026) — no milestone in flight.** The variance-decomposition trio
is merged: conflated single-level ICC (`level = "conflated"`), multilevel rater-count
`d_study()`, and within-cell replicates + occasion-averaged coefficient. Next code work is a
maintainer-chosen backlog promotion from the sequencing below (each needs its own
start-of-milestone scope pass + ADR).

**Still to sequence (non-Bayesian carryover):**

- **Wave 3 (research):** **M9 averaged cluster-level `ICC(c,k)` on incomplete data** (open
  per-cluster divisor — a focused simulation-oracle study, likely a Fable review).
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
