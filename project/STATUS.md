# Project status

- Milestone: **M10 — fixed-rater multilevel ICCs, Design 1 (crossed) balanced, subject
  level** — detailed and active (estimand-spec + ADR-019 written; M9 retro done)
- Active task: M10 Slice 1 — fixed-rater multilevel fit + subject-level estimand (not
  started; branch `m10-fixed-multilevel` not yet cut)
- Last green CI: PR #13 (M9) full matrix green incl. Windows; merged to `main` at
  073a51e
- Blockers: —
- Updated: 2026-07-07 by main session (Opus) — M10 detailed (ADR-019, spec, DoD board)

## Where we are

**Shipped M0–M9** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam; the multilevel estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); and the crossed design now also handles **incomplete
(ragged)** data (subject level + cluster-level `ICC(c,1)`) with a declared-`design`
disambiguation and oracle-pinned identifiability guards.

## Next action

**Start M10 Slice 1** — fixed-rater multilevel fit + subject-level estimand. Cut branch
`m10-fixed-multilevel`, then (spec §5): lift the `raters = "fixed"` + multilevel abort
(icc.R ~230); add the fixed-rater multilevel fit
(`score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)`, θ²_r via
the reused M3 `fit_glmmtmb_fixed()` machinery in the `rater` slot) and route it; reuse
`icc_point()` + the M3 fixed MC sampler. Pin every §2b coefficient with **O-FML/reduction
→ M5 balanced (fixed≡random)** + → M3 single-cluster + lme4 cross-engine + seeded sim
*before* shipping (#1). Use `/start-task`.

**Verify against the INSTALLED package** (`NOT_CRAN=true`), not just `load_all`, before
the PR push (`verify-against-installed-package` memory — the M9 CI-red lesson).

Milestone arc after M10 (ADR-017): **M11** general `autoplot()`/ggplot2 → **M12**
`choose_icc()` → **M13** release polish.

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
