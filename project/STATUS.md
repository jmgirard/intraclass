# Project status

- Milestone: **M14 — lme4 for the fixed & multilevel fits (engine parity, ADR-023)** —
  detailed and scheduled, **not yet started** (no branch/slice in flight). The ADR-017
  arc (M0–M13) is shipped; the package is at v0.1.0, submission-ready.
- Active task: **M14 Slice 1 — `fit_lme4_fixed` — done** (green, uncommitted on branch
  `m14-lme4-parity`). Next: **Slice 2 — `fit_lme4_multilevel`**. See MILESTONES.md M14 board.
- Last green CI: PR #17 (M13) full matrix green incl. Windows and R-devel; merged to
  `main` at 54c0947
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M14 Slice 1 landed (fixed-rater lme4, green)

## Where we are

**Shipped M0–M13** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
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

**Continue M14 with Slice 2 — `fit_lme4_multilevel`** (ADR-023; MILESTONES.md M14
board). Slice 1 (`fit_lme4_fixed`) is landed and green on branch `m14-lme4-parity`.
Slice 2 mirrors `fit_glmmtmb_multilevel` (Design 1 crossed random, five-component):
extend the merDeriv → log-SD delta-transform to five variance components with
multi-grouping-factor column alignment, and add the `engine == "lme4"` branch in the
`engine_fit` dispatch block. Then Slice 3 (nested Designs 2/3 + `fit_lme4_multilevel_fixed`),
then the cross-cutting DoD (NEWS bullet, install-verify with `NOT_CRAN=true`, PR).

Also open (maintainer-initiated, out of band): **CRAN submission (ADR-022).** The
package is submission-ready. Before uploading, run **win-builder** (R-devel + release)
and **R-hub**, then update the "will be run immediately before submission" line in
`cran-comments.md`. `intraclass` does not (and cannot) submit for you.

Deferred out of M14 and still parked (not scheduled): **incomplete/ragged lme4** for the
new shapes (follow-up); the **Bayesian engine** (rstanarm + `ci_method = "posterior"`);
the M9 **averaged cluster-level `ICC(c,k)` on incomplete data** (open divisor, spec §3b —
a simulation-oracle/Fable candidate); **one-way / general ICC(1) via SEM** (no faithful
sourced route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
