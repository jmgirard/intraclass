# Project status

- Milestone: **M15 — incomplete/ragged lme4 (full incomplete engine parity)** —
  **active**, detailed at start (ADR-024). Extends M14's balanced lme4 parity to every
  incomplete design glmmTMB fits (incomplete random two-way, incomplete fixed-rater
  two-way, incomplete crossed random multilevel), closing the last ADR-023 deferral.
  No new estimand/spec/`ci_method`/dependency. M0–M14 all shipped; package at v0.1.0.
- Active task: **M15 finish-task / PR** — all three slices done. Incomplete random
  two-way (already ungated), incomplete fixed-rater two-way, and incomplete crossed
  random multilevel lme4 all ship, each pinned with an O-LME2 ragged oracle; the
  multilevel singular→glmmTMB degrade is characterized and pinned. Remaining: installed-
  package check (`NOT_CRAN=true`), push, PR, CI matrix, post-merge `project/` reconcile.
  See the M15 DoD checklist in [`MILESTONES.md`](MILESTONES.md).
- Branch: `m15-incomplete-lme4` (created; ADR-024 + M15 board entry committed here).
- Last green CI: PR #18 (M14) full matrix green incl. Windows and R-devel; merged to
  `main` at 474e0c1
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M15 scoped & detailed (ADR-024), branch
  created

## Where we are

**Shipped M0–M14** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam, and **lme4 now has full balanced design parity with glmmTMB —
two-way random/fixed, one-way, and every multilevel design (M14)**; the multilevel
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

**Open the M15 PR from `m15-incomplete-lme4`.** All three slices + the local gate are
done (roxygen, NEWS, `air`, `lintr` clean, full suite 572/0/0; installed-package check
in this finish pass). Push the branch, `gh pr create`, and once the full CI matrix is
green and merged, reconcile the pending markers (STATUS "Last green CI" → merge commit;
M15 Status line → merged; compress the M15 entry to summary form preserving the
"Deferred out of M15" list) in a direct commit to `main`. Scope in ADR-024.

**Out-of-band thread (unchanged): CRAN submission (ADR-022).** The package is
submission-ready. Before uploading, run **win-builder** (R-devel + release) and
**R-hub**, then update the "will be run immediately before submission" line in
`cran-comments.md` with the results. `intraclass` does not (and cannot) submit for you.
*(Note: M14 — and now M15 — fold their changes into the existing `0.1.0` NEWS section
rather than bumping to a dev version, on the basis that 0.1.0 has not yet been uploaded
— revisit if 0.1.0 is frozen for submission.)*

Parked after M15 (not scheduled): the **Bayesian engine** (rstanarm +
`ci_method = "posterior"`); the M9 **averaged cluster-level `ICC(c,k)` on incomplete
data** (open divisor, spec §3b — a simulation-oracle/Fable candidate); the
**parametric-bootstrap `ci_method`** (bootMer); **one-way / general ICC(1) via SEM** (no
faithful sourced route — ADR-014); **replicate ratings within cell**. All in
[`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
