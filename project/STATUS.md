# Project status

- Milestone: M6 — one-way random ICC(1)/ICC(k) (done; merged via PR #10)
- Active task: — (next: retro + detail M7 — optional engines)
- Last green CI: PR #10 (M6) full matrix green (9/9); merged to `main` at eb7102d
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

**Just shipped:** M5.5 — lme4 as a selectable engine (ADR-012), merged via PR #9
(`edd9d88`, full CI matrix green 9/9 incl. Windows; `devtools::check()` 0/0/0 local,
tests 219/0/0). A pre-M6 take-stock (this session) reviewed the deferred/ROADMAP
inventory; the maintainer promoted the ADR-005 lme4-selectable debt as the natural
interface-building slice before M6's heavier optional-engine work. Two design
questions resolved: (1) CI via **merDeriv** reusing the existing Monte-Carlo path
(not parametric bootstrap) → a cross-engine *interval* oracle, no new `ci_method`;
(2) **random two-way path only** (fixed/multilevel lme4 deferred). `fit_lme4()`
returns the shared six-field engine contract so `icc_point`/`mc_ci`/`d_study` are
unchanged (no new estimand). The SD-scale merDeriv covariance is delta-transformed
to glmmTMB's log-SD scale — verified to reproduce glmmTMB's `vcov(full = TRUE)` to
~1e-4, so the lme4 MC CI matches glmmTMB's to ≤9.4e-3 absolute (oracle O-LME).
**Discovered: merDeriv fails on a singular fit** (variance component pinned to
exactly zero); `fit_lme4()` detects `isSingular()` and aborts
(`intraclass_singular_fit`) pointing to the boundary-robust glmmTMB engine (#5/#8).
Scope + the singular-fit note in ADR-012. (CI-only wrinkle, now fixed: the
interval oracle first used `expect_equal`'s *relative* tolerance, which tripped on
small `conf.low` bounds on Windows; switched to an absolute-gap assertion.)

**Backlog scheduled (ADR-013).** A post-M5.5 take-stock (this session) confirmed
**nothing mandatory blocks the optional-engine work** — M5.5 built the dispatch
seam it needed — then reordered the provisional tail. New arc: **M6 = one-way
random ICC(1)/ICC(1,k)** (next), **M7 = optional engines** (was M6), **M8 =
multilevel & incomplete-design extensions** (grouped from M5 spec §8 + lme4
fixed/multilevel fits), **M9 = release polish** (was M7). Everything else
(categorical/ordinal GLMM, within-cell replicates, general `autoplot()`,
`choose_icc()`, benchmark suite, bootstrap/profile CIs, D-study cost/two-facet/
subject-count, Eq. 14) stays parked in ROADMAP.

**Just shipped:** M6 — one-way random ICC(1)/ICC(k), the last member of the
classic Shrout–Fleiss family. `model = "oneway"` fits `score ~ 1 + (1 | subject)`
(no rater term) on both engines → ICC(1)/ICC(k) (+ numeric-unit `ICC(m)` D-study
projection). First milestone to change the fitted model (one-way ≠ consistency: the
confounded residual carries the rater spread). Estimand + all five oracles verified
live before code (estimand-spec `M6-oneway.md`); O-OW = SF 0.166/0.443 + `psych`
ICC1/ICC1k + one-way ANOVA + glmmTMB↔lme4 + seeded sim. `rater` still supplied but
identity ignored (counts k only); `type`/fixed/`cluster` abort or n/a. Ships the
choosing-an-icc "are the raters crossed?" prior-question section. Merged via PR #10
(`eb7102d`, full CI matrix green 9/9 incl. Windows on first try; `devtools::check()`
0/0/0 local, tests 247/0/0).

**Next milestone:** M7 — optional engines (Bayesian `brms`/`rstanarm`, SEM
`lavaan`) behind `Suggests`, extending the M5.5 engine × design dispatch seam and
generalizing the `ci_method` layer for native posterior samples (references
gathered — see MILESTONES M7). Detail its DoD at start after a short retro
(founding brief §7).
