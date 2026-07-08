# Project status

- Milestone: **M15 — incomplete/ragged lme4 (full incomplete engine parity)** —
  shipped (PR #19, ADR-024). `engine = "lme4"` now matches glmmTMB across every
  incomplete design it fits too (incomplete random two-way, incomplete fixed-rater
  two-way, incomplete crossed random multilevel), degrading loudly to glmmTMB only at
  the variance boundary. M0–M15 all shipped; package at v0.1.0, submission-ready. No
  milestone in flight.
- Active task: — (M15 shipped; next code work is another maintainer-chosen backlog
  promotion — see Next action.)
- Last green CI: PR #19 (M15) full matrix green incl. Windows and R-devel; merged to
  `main` at b0dd492
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M15 merged (PR #19) + `project/` reconciled

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

**No milestone is in flight — M15 is shipped.** Two independent threads remain, both
maintainer-initiated:

1. **Next code milestone = another backlog promotion** (no pre-planned M16). Each needs
   a start-of-milestone scope pass + ADR. The strongest remaining candidates: the
   **Bayesian engine** (rstanarm + `ci_method = "posterior"` — the ten Hove estimator's
   own method, and the first genuinely new `ci_method`); the M9 **averaged cluster-level
   `ICC(c,k)` on incomplete data** (open divisor — a simulation-oracle/Fable candidate);
   **replicate ratings within cell**; the **parametric-bootstrap `ci_method`** (bootMer).
2. **CRAN submission (out of band, ADR-022).** See below.

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

Parked after M15 (not scheduled): the **Bayesian engine** (rstanarm +
`ci_method = "posterior"`); the M9 **averaged cluster-level `ICC(c,k)` on incomplete
data** (open divisor, spec §3b — a simulation-oracle/Fable candidate); the
**parametric-bootstrap `ci_method`** (bootMer); **one-way / general ICC(1) via SEM** (no
faithful sourced route — ADR-014); **replicate ratings within cell**. All in
[`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
