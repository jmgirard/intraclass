# Project status

- Milestone: **M19 — Multilevel completeness II (nested Designs 2/3: incomplete + fixed-rater)** —
  **shipped** (PR #24, ADR-029; second milestone of the M18–M21 arc, ADR-027). Two slices:
  **(1)** incomplete nested Designs 2/3 (ragged `k_eff` divisor reduces *exactly* to the pinned
  M3/M6 incomplete divisor; ambiguous ragged requires explicit `design=`); **(2)** fixed-rater
  nested Design 2, both engines (new `theta2r_fixed_nested()` — θ²_{r:c} = mean over clusters of
  each cluster's finite-population rater variance). **Oracle-first catch:** fixed ≢ random even
  balanced for nested (per-cluster finite population; the M10 crossed identity does not carry
  over) — pinned by per-cluster + single-cluster reduction to flat M3 fixed θ²_r, cross-engine,
  consistency≡random. Design 3 fixed ⚫ by-design; incomplete fixed-nested deferred. Completeness,
  not new estimand work; no new dependency, no new argument. M0–M19 shipped; package at v0.1.0.
  No milestone in flight.
- Active task: — (no milestone in flight; **M20 — Within-cell replicate completeness** is next in
  the arc, ADR-027, and gets its own start-of-milestone scoping ADR.)
- Last green CI: PR #24 (M19) full matrix green incl. Windows and R-devel; merged to
  `main` at 53c9f5e
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M19 merged (PR #24, ADR-029)**: both slices;
  `R CMD check --as-cran` 0/0/0, 813 tests, full CI matrix green. Post-merge `project/` reconcile
  done (M19 compressed in MILESTONES; COVERAGE #10/#11 → ✅). M20 next.

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

**M18 & M19 shipped (PR #23/#24, ADR-028/029) — no milestone in flight.** The
**M18–M21 completeness arc** (ADR-027) closes every 🔵 *not yet* gap in
[`COVERAGE.md`](COVERAGE.md). Next code work is **starting M20** (its own start-of-milestone
scope pass + ADR).

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027):**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** ✅ shipped (PR #24) — incomplete
  nested + fixed-rater nested Design 2.
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
