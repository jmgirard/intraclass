# Task board

Current-milestone task board. One owner-agent each; check off in the **same
commit** as the work (PRINCIPLES.md #16). Completed milestones' boards are
condensed to a single line once done.

## M0 — scaffolding (in progress)

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

## M1 — two-way random, absolute agreement (done locally, pending push + sign-off)

- [x] Plan M1 (API shape, estimand abstraction, MC-CI design) and get sign-off — Opus
- [x] `icc()` core: parse args (tidy-eval), fit `score ~ 1 + (1|subject) + (1|rater)` (glmmTMB) — Opus
- [x] Variance-component extraction → estimand (signal, error set, divisor) — Opus
- [x] Monte-Carlo CI from `vcov(fit, full = TRUE)` (boundary-aware, seeded) — Opus
- [x] Engine dispatch scaffolding; lme4 as oracle-only in M1 (ADR-005) — Opus
- [x] S3 methods: `print`/`summary`/`format`/`tidy`/`glance` — Opus
- [x] Oracle tests: ANOVA mean-squares, seeded simulation, lme4 cross-check, errors — Opus
- [x] Roxygen "which ICC / when" note; *Getting started* vignette — Opus
- [x] Flip seed test `engine` default to glmmTMB; repoint skip guards — Opus
- [x] Verify vs all oracles; coverage 94%; check 0/0/0 — Opus
- [ ] Push; confirm full CI matrix green; update STATUS last-green-CI — Opus
