# Project status

- Milestone: M5.5 — lme4 as a selectable engine (in progress; pre-M6 interface slice, ADR-012)
- Active task: M5.5 slice 1 — `fit_lme4()` + engine × design dispatch + merDeriv MC CI + oracles O-LME
- Last green CI: PR #8 (M5) full matrix green (9/9); merged to `main` at 87b4588
- Blockers: —
- Updated: 2026-07-07 by main session (Opus)

## M5 plan (detailed this session, maintainer-approved)

M5 adds **subject-level (within-cluster)** and **cluster-level (between-cluster)**
interrater ICCs for subjects nested in clusters (ten Hove, Jorgensen & van der Ark
2022), the flagship vignette's "fifth choice". Equations transcribed verbatim
from the paper's Table 3 (Design 1). Scope (ADR-011): **Design 1 = raters crossed
with clusters, balanced/complete, random raters**; agreement/consistency and
single/average work at both levels. API adds a `cluster` selector + a `unit`-style
`level = c("subject","cluster")` knob (both levels by default). Each coefficient is
still `signal / (signal + error / k)` — **scalar divisor and `icc_point()`
unchanged** (a planning-stage "two-facet subject×rater average" idea was wrong: the
cluster-level ICC drops all subject variance). Model `score ~ 1 + (1|cluster) +
(1|cluster:subject) + (1|rater) + (1|cluster:rater)`; **five** components
σ²_c/σ²_{s:c}/σ²_r/σ²_{cr}/σ²_res; both levels read off **one shared fit**; MC CI
(ADR-003) inherited. Oracles O-ML: lme4 cross-engine + seeded simulation +
single-level reduction (no textbook worked example, as with O5). Two CI-green
slices — Slice 1 subject-level, Slice 2 cluster-level + docs — on branch
`m5-multilevel`, merged via PR. Detail in
[`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md),
[`MILESTONES.md`](MILESTONES.md) M5, ADR-011.

## Next action

M4.5 shipped and merged (PR #6, `9be03a0`, full CI matrix green — 9/9). It is the
deferred D-study projection (ADR-010), shipped as its own slice before M5. Slice 1
(projection core): the estimand carries a resolved numeric `divisor`
(`resolve_divisor()`); `icc()`'s `unit` accepts numbers (`ICC(A,3)` rows);
`d_study(x, m = …)` returns an `icc_dstudy` table of Φ(m) reusing the stored fit
(no refit; `x$mc`), drawing the MC sample once and evaluating every `m`; fixed-rater
absolute-agreement projection is refused (#5). Oracles O-DS: Spearman–Brown, GT
dependability, `psych` at `m = n_raters`, seeded simulation
(`data-raw/oracle-d-study.R`). Slice 2: `autoplot.icc_dstudy()` (ggplot2, lazily
registered via `zzz.R` for oldrel), `plot`/`print`/`tidy`/`glance`, NEWS, `_pkgdown`
entry, and an `advanced.Rmd` D-study section with a backing claims test.
Estimand-spec `M4.5-d-study.md`. `devtools::check()` 0/0/0.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).

**Next action:** M5 shipped and merged (PR #8, `87b4588`, full CI matrix green —
9/9). `icc()` now takes a `cluster` column and a `level = c("subject","cluster")`
knob, reporting subject- and cluster-level ICCs off one five-component Design-1 fit
(ten Hove et al. 2022; scalar divisor unchanged). Oracles O-ML (lme4 <1e-4, seeded
recovery + MC coverage, single-level reduction). Also merged: the citation audit
(ADR-002/003 pinned to ten Hove 2025 MLE-RE+MC-CI; DescTools/irrNA fixes) and the
choosing-an-icc.Rmd multilevel-citation fix.

Deferred (spec §8, recorded so they aren't rediscovered): Designs 2/3 (nested
raters), incomplete multilevel, fixed-rater multilevel, multilevel D-study.

**Current milestone:** M5.5 — lme4 as a selectable engine (ADR-012). A pre-M6
take-stock (this session) reviewed the deferred/ROADMAP inventory; the maintainer
promoted the ADR-005 lme4-selectable debt as the natural interface-building slice
before M6's heavier optional-engine work. Two design questions resolved this
session: (1) CI via **merDeriv** reusing the existing Monte-Carlo path (not
parametric bootstrap) → a cross-engine *interval* oracle, no new `ci_method`;
(2) **random two-way path only** (fixed/multilevel lme4 deferred). `fit_lme4()`
returns the shared six-field engine contract so `icc_point`/`mc_ci`/`d_study` are
unchanged (no new estimand). Key technical risk: merDeriv's covariance is on the
variance/SD scale, so `to_components` must map onto a boundary-safe log-SD scale
(#3). DoD in MILESTONES M5.5; scope in ADR-012. Ships on `m5.5-lme4-engine`.

**Next milestone:** M6 — optional engines (Bayesian `brms`/`rstanarm`, SEM
`lavaan`) behind `Suggests`; references already gathered (Jorgensen 2021 SEM,
ten Hove 2020 hyperpriors — see MILESTONES M6). M6 now extends the engine × design
dispatch seam M5.5 establishes. Detail M6's DoD at its start after a short retro
(founding brief §7).
