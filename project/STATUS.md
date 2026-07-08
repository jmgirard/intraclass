# Project status

- Milestone: **M18 — Multilevel completeness I (crossed Design 1, incomplete corners)** —
  **shipped** (PR #23, ADR-028; first milestone of the M18–M21 arc, ADR-027). Four slices, each
  lifting a single shipped abort guard: **(1)** incomplete fixed-rater crossed (M3 `k_eff` + M10
  θ²_r under imbalance); **(2)** incomplete conflated ICC (Eq. 14 well-posed on ragged data — the
  attempt-then-degrade posture resolved to *ships*, no reclassification; spec §6a); **(3)**
  incomplete **subject-level** `d_study()` (cluster level bounded by the Wave-3 `ICC(c,k)` divisor,
  dropped-with-note); **(4)** bootstrap-projected `d_study()` bands (M16 deferral, package-wide).
  Completeness, not new estimand work; no new dependency, no new argument. M0–M18 shipped; package
  at v0.1.0. No milestone in flight.
- Active task: **M19 finish-task** (both slices done; ready to close the milestone). On
  `m19-nested-completeness`: **Slice 1** (incomplete nested Designs 2/3) + **Slice 2** (fixed-rater
  nested Design 2, both engines) shipped. Next: `R CMD check --as-cran` + installed-pkg check +
  open the PR.
- Slice-2 highlight (**oracle-first catch**): fixed ≢ random even balanced for *nested* Design 2 —
  the finite population is per-cluster (θ²_{r:c} = mean over clusters of each cluster's
  finite-population rater variance), so the M10 crossed "balanced fixed≡random" identity does NOT
  carry over. New fit `score ~ 0 + rater + (1|cluster:subject)` + new engine-agnostic
  `theta2r_fixed_nested()`; pinned by per-cluster + single-cluster reduction to the flat M3 fixed
  θ²_r (exact), cross-engine (<1e-4), consistency≡random (exact). Design 3 fixed ⚫ by-design;
  incomplete fixed-nested deferred. Full suite 813 pass / 0 fail; `air` + `lintr` clean.
- Last green CI: PR #23 (M18) full matrix green incl. Windows and R-devel; merged to
  `main` at 7dffbb2
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M19 Slices 1 & 2 implemented** on
  `m19-nested-completeness`. Slice 1: incomplete nested Designs 2/3 (k_eff divisor pinned by exact
  reduction to M3/M6). Slice 2: fixed-rater nested Design 2, both engines, new
  `theta2r_fixed_nested()` (oracle-first catch: fixed ≢ random for nested). Full suite 813 pass /
  0 fail, `air` + `lintr` clean. Next: milestone finish-task (`R CMD check` + PR).

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

**M18 shipped (PR #23, ADR-028); M19 implemented (ADR-029) — awaiting its PR.** The
**M18–M21 completeness arc** (ADR-027) closes every 🔵 *not yet* gap in
[`COVERAGE.md`](COVERAGE.md). Next code work after the M19 PR merges is **starting M20** (its
own start-of-milestone scope pass + ADR).

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027):**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** incomplete nested (Slice 1) +
  fixed-rater nested Design 2 (Slice 2) — **implemented on `m19-nested-completeness`, PR pending.**
- **M20 — Within-cell replicate completeness:** ragged (Slice 1), fixed-rater (Slice 2),
  multilevel (Slice 3) replicates. Extends M17 Slice 3. **Next.**
- **M21 — SEM (lavaan) engine parity:** lavaan bootstrap (Slice 1), fixed-rater SEM
  (Slice 2), incomplete/FIML SEM (Slice 3). The lavaan analog of the lme4 M5.5→M15 arc.

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
