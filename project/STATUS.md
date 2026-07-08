# Project status

- Milestone: **M20 — Within-cell replicate completeness (fixed-rater, multilevel, ragged)** —
  **in flight** (scoped by ADR-030; third milestone of the M18–M21 arc, ADR-027). Extends the M17
  Slice 3 within-cell replicate estimand beyond two-way-random/single-level/balanced to three
  corners, **reordered to oracle-risk** (maintainer): **Slice 1** fixed-rater replicates (θ²_r via
  shipped `theta2r_fixed()`; balanced fixed≡random exact pin — lowest risk); **Slice 2** multilevel
  replicates, **crossed D1 + nested D2** (add `(1|cluster:subject:rater)`; Design 3 ⚫ by-design);
  **Slice 3** ragged replicates (single-occasion extends via `k_eff`; occasion-averaged
  **attempt-then-degrade** to 🟣 research). Completeness, not new estimand work; no new dependency,
  no new argument, no new estimand-spec (extends `M17-within-cell-replicates.md`). M0–M19 shipped;
  package at v0.1.0.
- Active task: **M20 ALL SLICES DONE** (branch `m20-fixed-replicates`; Slice 1 `7d82217`, Slice 2
  `bfc23dc`, Slice 3 staged). **Slice 1** fixed-rater replicates (`fit_{glmmtmb,lme4}_replicates_fixed`,
  M10 θ²_r; O-FRep). **Slice 2** multilevel replicates: crossed Design 1
  (`fit_{glmmtmb,lme4}_ml_replicates`, six-component) + nested Design 2
  (`fit_{glmmtmb,lme4}_nested_replicates`, five); design-aware `multilevel_replicate_facts()`;
  O-MLRep (occ-avg == M5/M8 on cell means ~1e-8, cross-engine <1e-4); + `d_study()`-on-replicate
  correctness guard (was silently dropping σ²_sr since M17). **Slice 3** ragged single-occasion
  replicates (no new fit; harmonic-mean k_eff + connectedness); O-RagRep (cross-engine, seeded
  recovery); **occasion-averaged-ragged degraded to 🟣 research** (no validated effective-n_o
  divisor, #1/#4 — maintainer-authorized attempt-then-degrade). Full suite green, `air`/`lintr`
  clean, docs regenerated. **Next: commit Slice 3; then M20 finish-task / merge; then M21 (SEM).**
- Last green CI: PR #24 (M19) full matrix green incl. Windows and R-devel; merged to
  `main` at 53c9f5e. M20 verified locally only — not yet pushed/CI'd.
- Blockers: —
- Updated: 2026-07-08 by main session (Opus) — **M20 scoped (ADR-030); all three slices built.**
  Slice 1 (fixed) `7d82217`; Slice 2 (multilevel) `bfc23dc`; Slice 3 (ragged) built + green,
  staged. Occasion-averaged-ragged degraded to 🟣 research (COVERAGE §②, M17 §7). Next: commit
  Slice 3 and run M20 finish-task / merge.

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

**M20 in flight (ADR-030); M18 & M19 shipped (PR #23/#24, ADR-028/029).** The
**M18–M21 completeness arc** (ADR-027) closes every 🔵 *not yet* gap in
[`COVERAGE.md`](COVERAGE.md). Next code work is **M20 Slice 1** (fixed-rater within-cell
replicates) — the DoD board is in [`MILESTONES.md`](MILESTONES.md).

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027):**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** ✅ shipped (PR #24) — incomplete
  nested + fixed-rater nested Design 2.
- **M20 — Within-cell replicate completeness:** 🚧 in flight (ADR-030). Oracle-risk order:
  **Slice 1** fixed-rater · **Slice 2** multilevel (crossed D1 + nested D2) · **Slice 3** ragged
  (occasion-averaged attempt-then-degrade). Extends M17 Slice 3.
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
