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

## M2 — consistency variants + fixed-vs-random raters (planned)

- [x] Plan M2 (scope, fixed≡random verification, API) and get sign-off — Opus
- [x] Estimand-spec `M2-consistency-and-fixed.md` + ADR-006 — Opus
- [x] `icc_estimand()`: consistency error set {residual}; `raters`/design dimension (labeling only) — Opus
- [x] `icc.R`: unlock `type = "consistency"`; add `raters = c("random","fixed")` arg + labeling — Opus
- [x] Classed warning layer `warn_intraclass()` + `warn_fixed_raters()` (`intraclass_fixed_raters`) — Opus
- [x] `print`/`summary`/`format`: surface design (random vs mixed) + SF-equivalent (ICC(2,·)/ICC(3,·)); snapshots — Opus
- [x] Oracle tests: SF 0.715/0.909, `psych` ICC3/ICC3k (1e-4), ANOVA identity, lme4 cross-check, fixed≡random equivalence — Opus
- [x] Warning-path tests: `intraclass_fixed_raters` fires on `"fixed"`, silent on `"random"`, text snapshot — Opus
- [x] Roxygen "which ICC / when" for consistency + fixed/random; vignette consistency-vs-agreement note — Opus
- [x] Commit the seeded fixed≡random script under the reference-values path (O-registry provenance, #4) — Opus
- [x] REFERENCES.md (promote O1 C-rows; new equivalence oracle); verify; check 0/0/0 locally (94.8% cov) — Opus
- [ ] Push branch, open PR, confirm full CI matrix green; reconcile STATUS last-green-CI — Opus
