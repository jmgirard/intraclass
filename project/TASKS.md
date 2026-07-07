# Task board

Current-milestone task board. One owner-agent each; check off in the **same
commit** as the work (PRINCIPLES.md #16). Completed milestones' boards are
condensed to a single line once done.

## M0 — scaffolding — **done** (commit 0d81e34, pushed, CI green)

- [x] Package skeleton: `DESCRIPTION`, `NAMESPACE`, `R/` package doc + `abort` layer — Opus
- [x] License (MIT), README.Rmd, NEWS.md, lifecycle badge, spell check + WORDLIST — Opus
- [x] Move seed tests to `tests/testthat/`; add self-removing M1 skip guard — Opus
- [x] `project/` tracking system (PRINCIPLES, STATUS, MILESTONES, TASKS, ROADMAP, DECISIONS, REFERENCES) — Opus
- [x] Fold seed docs into `project/` (REFERENCES-seed, M1 estimand spec) — Opus
- [x] `.claude/skills/` (status, start-task, finish-task, verify-estimator, new-estimator, add-decision) — Opus
- [x] `.claude/agents/doc-polisher.md` (Sonnet) — Opus
- [x] CI workflows (R-CMD-check, coverage, lint, pkgdown, scheduled reference-values) — Opus
- [x] pkgdown config (`_pkgdown.yml`) + stub vignettes; grouped reference index deferred to M1 (no exports yet) — Opus
- [x] Lean `CLAUDE.md` — Opus
- [x] air formatter (`air.toml`, `format.yaml` CI, lintr reconciliation); ADR-004 — Opus
- [x] Codecov upload gated on `CODECOV_TOKEN` so CI stays green until secret added — Opus
- [x] `devtools::document()` + `devtools::check()` clean (0/0/0); `air`/`lintr` clean; pkgdown builds — Opus
- [x] Create public `jmgirard/intraclass` repo; first push; confirm CI green (commit 0d81e34) — Opus
- [x] Update STATUS.md "Last green CI"; commit — Opus

## M1 — two-way random, absolute agreement — **done** (commit 77e8ab0, CI green)

`icc()` for `ICC(A,1)`/`ICC(A,k)`: glmmTMB engine, boundary-aware MC CIs,
`print`/`summary`/`format`/`tidy`/`glance`, 5 oracles, vignette. See MILESTONES M1.

## M2 — consistency variants + fixed-vs-random raters — **done** (PR #1, merged at 334a48a, CI green)

`icc()` gains `type = "consistency"` (`ICC(C,1)`/`ICC(C,k)`) and
`raters = c("random","fixed")` (fixed = balanced-data label layer, SF `ICC(3,*)`,
warns). Classed warning layer; design + SF-equivalent in print/summary; oracles
SF 0.715/0.909, `psych` ICC3/ICC3k, fixed≡random equivalence (O4). See MILESTONES M2.

## M3 — imbalanced & incomplete designs — **done** (Slices 0–2; local gate green, pending PR CI + merge)

Ragged subject×rater designs (missing cells). Slice 0: estimand spec + ADR-008
(arc reordered by ADR-007; vignette → M4). Slice 1: `summarize_design()` (union-find
connectedness, `k_eff` harmonic-mean divisor, replicate guard) + incomplete
random-rater path; oracle O5 (lme4 cross-engine + MCAR simulation). Slice 2: real
fixed-effect fit (`+ rater`) — Case 3 consistency + Case 3A absolute agreement with
bias-corrected θ²_r + fixed-path MC-CI; oracle O6 (balanced reduction, lme4, 95% CI
coverage). Resolves the ADR-006 debt. See MILESTONES M3.
