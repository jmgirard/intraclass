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

## M3 — imbalanced & incomplete designs — **planned** (arc reordered by ADR-007)

Statistical core only (vignette split to M4). Two CI-green slices; see MILESTONES M3
and the approved plan `moonlit-mixing-pinwheel`.

### Slice 0 — spec + tracking (do first, PRINCIPLES.md #2, #16)
- [x] Write `project/estimand-specs/M3-incomplete-designs.md`: identifiability
      (connectedness) rule; random + fixed(Case 3/3A) estimands; balanced-reduction
      guard; **pin the `ICC(*,k)` divisor convention** (ADR-008: `k_eff` = harmonic
      mean of per-subject counts; projection to other `m` = future D-study) — Opus

### Slice 1 — incomplete random raters (default path) — **done**
- [x] `summarize_design()` (connectedness via union-find + balance/`k_eff`/replicate
      detection) in `R/design.R`; guards wired into `icc()`: `abort_unidentified()`
      on disconnected graphs, `abort_unsupported()` on within-cell replicates — Opus
- [x] `k_eff` divisor for `unit = "average"` (harmonic mean; = k on balanced data);
      `ICC(*,1)` always well-posed — Opus
- [x] `print`/`glance` surface completeness (`N of M cells`), `n_cells`, `k_eff`,
      `balanced`; snapshots updated — Opus
- [x] Oracles (O5, `/verify-estimator`): lme4 cross-engine on incomplete data
      (< 1e-4) + seeded MCAR simulation (recovers components; CIs cover) +
      balanced-reduction regression; provenance `data-raw/oracle-incomplete.R`,
      `REFERENCES.md` O5. `irrNA`/`gtheory` deferred — not needed, lme4+sim meet
      the ≥2-oracle bar (#1) — Opus

### Slice 2 — real fixed-effect fit path (resolves ADR-006 debt)
- [ ] Fixed-effect fit `score ~ 1 + rater + (1|subject)` in the engine; read-out for
      the fixed-raters error set (consistency: residual; agreement: + rater-effect
      spread, Case 3A) — Opus
- [ ] Extend `icc_estimand()`/`icc_point()` for the fixed agreement error; branch on
      `design$raters`; fixed-path MC-CI sampler in `mc_ci()` — Opus
- [ ] Correct the `raters` roxygen note (fixed now differs from random on incomplete
      data); warning text reviewed — Opus
- [ ] Oracles: unbalanced Case 3 / SF `ICC(3,*)` + lme4 fixed-fit cross-check +
      balanced reduction to M2 (O6) — Opus (`/verify-estimator`)
