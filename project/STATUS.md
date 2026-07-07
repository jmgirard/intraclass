# Project status

- Milestone: **M13 — release polish (docs, site, CRAN submission-ready)** — active;
  detailed by ADR-022 on branch `m13-release-polish`. Final milestone of the ADR-017 arc.
- Active task: **M13 — open the release PR.** All three slices done locally; awaiting the
  `m13-release-polish` PR to go green on the full matrix and merge.
- Last green CI: PR #16 (M12) full matrix green incl. Windows and R-devel; merged to
  `main` at 20f9afc
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M13 detailed (ADR-022 + DoD); branch cut

## Where we are

**Shipped M0–M12** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
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
emits the exact `icc()` call — teaching/API, no new estimand (M12).

## Next action

**Open the M13 release PR** from `m13-release-polish` and get the full matrix (Windows +
R-devel) green, then merge. All Slice 3 work is done locally: version **0.1.0**, NEWS
consolidated, `cran-comments.md` + `inst/WORDLIST` authored, US-spelling fixes,
`R CMD check --as-cran` **0/0/0** in CRAN mode *and* with `NOT_CRAN=true`, `lintr` clean.
Per ADR-022 the milestone ends at **submission-ready** — the actual CRAN upload +
win-builder/R-hub round-trips are the maintainer's out-of-band step (deferred). After
merge, reconcile `project/` on `main` (finish-task policy) and this closes the ADR-017
arc (M0–M13 all shipped).

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
