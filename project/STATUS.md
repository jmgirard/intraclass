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
- Active task: **M19 Slice 1 — incomplete nested (Designs 2/3)** (ADR-029, COVERAGE #10). Scoping
  done: retro + ADR-029 written + M19 board added to MILESTONES.md; maintainer decisions A (explicit
  `design=` on ambiguous ragged data), B (attempt subject-level `k_eff` for the averaged
  coefficient, degrade to 🟣 research if unpinnable), C (fixed-rater = Design 2 only) locked. Next:
  start Slice 1 on branch `m19-nested-completeness` — lift the `nested_design_balanced` abort,
  single-rater first, then the averaged-divisor oracle characterization (#1/#4). No code yet.
- Last green CI: PR #23 (M18) full matrix green incl. Windows and R-devel; merged to
  `main` at 7dffbb2
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M19 scoping opened** via `/start-task M19`. M18
  shipped (PR #23, ADR-028); no code milestone in flight. Retro done; M19's planned scope
  (nested Designs 2/3 incomplete + fixed) restated from ADR-027; estimand/oracle posture named.
  Scope decisions put to the maintainer before ADR-029 is written.

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

**M17 shipped (PR #22, ADR-026) — no milestone in flight.** The **M18–M21 completeness arc
is planned** (ADR-027) to close every 🔵 *not yet* gap in [`COVERAGE.md`](COVERAGE.md).
Next code work is **starting M18** (it gets its own start-of-milestone scope pass + ADR).

**Planned arc — M18→M21, mixed-model completeness first, SEM last (ADR-027):**

- **M18 — Multilevel completeness I (crossed, incomplete):** incomplete fixed-rater crossed
  (Slice 1); incomplete conflated ICC (Slice 2); incomplete subject-level `d_study()` +
  bootstrap `d_study()` bands (Slice 3). Reuses M3 Case-3A / M10 θ²_r / M9 machinery.
- **M19 — Multilevel completeness II (nested Designs 2/3):** incomplete nested (Slice 1);
  fixed-rater nested (Slice 2). The M8→incomplete + M10-fixed analog.
- **M20 — Within-cell replicate completeness:** ragged (Slice 1), fixed-rater (Slice 2),
  multilevel (Slice 3) replicates. Extends M17 Slice 3.
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
