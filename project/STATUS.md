# Project status

- Milestone: **M13 — release polish** — shipped (PR #17). **The ADR-017 arc is complete;
  M0–M13 are all shipped and the package is at v0.1.0, submission-ready.**
- Active task: — (no milestone in flight; next code work is a maintainer-chosen ROADMAP
  promotion — see Next action. The CRAN upload itself is a maintainer out-of-band step.)
- Last green CI: PR #17 (M13) full matrix green incl. Windows and R-devel; merged to
  `main` at 54c0947
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M13 merged (PR #17) + `project/` reconciled

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

**No milestone is in flight — the ADR-017 arc (M0–M13) is complete.** Two independent
threads remain, both maintainer-initiated:

1. **CRAN submission (out of band, ADR-022).** The package is submission-ready. Before
   uploading, run **win-builder** (R-devel + release) and **R-hub**, then update the
   "will be run immediately before submission" line in `cran-comments.md` with the
   results. `intraclass` does not (and cannot) submit for you.
2. **Next code milestone = a ROADMAP promotion** (there is no pre-planned M14). The
   strongest candidates, each needing a start-of-milestone scope pass + ADR:
   the **Bayesian engine** (rstanarm + `ci_method = "posterior"`); **lme4 for the
   fixed/multilevel fits** (engine parity, ADR-012); the M9 **averaged cluster-level
   `ICC(c,k)` on incomplete data** (open divisor — a simulation-oracle/Fable candidate).

Open deferral from M9 (recorded): averaged cluster-level `ICC(c,k)` on incomplete data
— the per-cluster effective-rater divisor is an open modeling question (spec §3b), a
candidate for a simulation-oracle study or Fable review.

Still deferred (not scheduled): **lme4 for the fixed/multilevel fits** (engine parity,
ADR-012 — glmmTMB covers these paths); the **Bayesian engine** (rstanarm + a new
`ci_method = "posterior"`); **one-way / general ICC(1) via SEM** (no faithful sourced
route — ADR-014). All in [`ROADMAP.md`](ROADMAP.md).

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
