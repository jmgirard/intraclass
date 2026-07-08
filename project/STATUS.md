# Project status

- Milestone: **M17 — variance-decomposition trio** — **scoped, in flight** (ADR-026); not
  yet started (no branch, no code). One milestone, three independent vertical slices, ordered
  by oracle-risk: **(1) conflated single-level ICC (Eq. 14)** via a new `level = "conflated"`
  (diagnostic contrast off the existing multilevel fit); **(2) three-facet `d_study()`**
  projecting subjects-per-cluster for complete-data multilevel at the cluster level;
  **(3) within-cell replicates** splitting σ²_sr from σ²_e via `(1 | subject:rater)` (new
  estimand → new spec; `gtheory` oracle in `Suggests`). Slice 3 may spin into M18 if the
  milestone runs heavy (decide at its start). M0–M16 shipped; package at v0.1.0,
  submission-ready.
- Active task: **M17 Slice 1 — conflated single-level ICC (Eq. 14)** — *in progress* on
  branch `m17-varcomp-trio` (started 2026-07-08). Estimand + oracle set named (below /
  ADR-026). Next: promote [`M5-multilevel.md §4`](estimand-specs/M5-multilevel.md) to a
  shipped-coefficient spec, then TDD the `level = "conflated"` path (#2 gate passed once the
  spec lands). One open scope question to confirm: agreement-only (sourced Eq. 14) vs.
  respecting the `type` knob.
- Last green CI: PR #21 (M16) full matrix green incl. Windows and R-devel; merged to
  `main` at 0b84885
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — M17 scoped (ADR-026); `project/` reconciled
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

**M17 is scoped (ADR-026) and in flight — start Slice 1.** M17 bundles the two remaining
non-research non-Bayesian carryovers (Wave-1 conflated ICC + Wave-2 three-facet `d_study()`
and within-cell replicates) into one milestone of three independent vertical slices, ordered
by oracle-risk. The DoD board is in [`MILESTONES.md`](MILESTONES.md); scope + the three API
decisions are in ADR-026.

**Slice order (start here):**

- **Slice 1 — conflated single-level ICC (Eq. 14)** — `level = "conflated"`, read off the
  existing five-component multilevel fit, labeled a diagnostic contrast (not a recommended
  coefficient). Smallest, cleanest oracle (paper Eq. 14 + reduction + lme4). Promote
  [`M5-multilevel.md §4`](estimand-specs/M5-multilevel.md) to a shipped-coefficient spec first.
- **Slice 2 — three-facet `d_study()`** — project subjects-per-cluster for **complete-data**
  multilevel at the cluster level (Brennan 2001 / `gtheory` oracle). Scope guard: refuse
  incomplete multilevel (the Wave-3 `ICC(c,k)` divisor).
- **Slice 3 — within-cell replicates** — split σ²_sr from σ²_e via `(1 | subject:rater)`;
  **write the new `M17-within-cell-replicates.md` spec first** (resolve crossed-vs-nested
  facet, coefficient set, occasion data API); `gtheory` oracle in `Suggests`. May spin into
  M18 if heavy.

**Still after M17 (unchanged sequencing):**

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
