# Task board

Current-milestone task board. One owner-agent each; check off in the **same
commit** as the work (PRINCIPLES.md #16). Completed milestones' boards are
condensed to a single line once done.

## M0 — scaffolding — **done** (commit 0d81e34, pushed, CI green)

Green, well-tracked, empty-but-real package: skeleton (`DESCRIPTION`/`NAMESPACE`/
`R/` + `abort` layer), MIT license, README/NEWS/lifecycle, spell check; the
`project/` tracking system + seed docs; `.claude/` skills + `doc-polisher` agent;
CI matrix (check/coverage/lint/pkgdown/scheduled reference-values); air formatter
(ADR-004); public repo pushed, `check()` 0/0/0. See MILESTONES M0.

## M1 — two-way random, absolute agreement — **done** (commit 77e8ab0, CI green)

`icc()` for `ICC(A,1)`/`ICC(A,k)`: glmmTMB engine, boundary-aware MC CIs,
`print`/`summary`/`format`/`tidy`/`glance`, 5 oracles, vignette. See MILESTONES M1.

## M2 — consistency variants + fixed-vs-random raters — **done** (PR #1, merged at 334a48a, CI green)

`icc()` gains `type = "consistency"` (`ICC(C,1)`/`ICC(C,k)`) and
`raters = c("random","fixed")` (fixed = balanced-data label layer, SF `ICC(3,*)`,
warns). Classed warning layer; design + SF-equivalent in print/summary; oracles
SF 0.715/0.909, `psych` ICC3/ICC3k, fixed≡random equivalence (O4). See MILESTONES M2.

## M3 — imbalanced & incomplete designs — **done** (merged via PR #2 at 11ab1b2, full CI matrix green)

Ragged subject×rater designs (missing cells). Slice 0: estimand spec + ADR-008
(arc reordered by ADR-007; vignette → M4). Slice 1: `summarize_design()` (union-find
connectedness, `k_eff` harmonic-mean divisor, replicate guard) + incomplete
random-rater path; oracle O5 (lme4 cross-engine + MCAR simulation). Slice 2: real
fixed-effect fit (`+ rater`) — Case 3 consistency + Case 3A absolute agreement with
bias-corrected θ²_r + fixed-path MC-CI; oracle O6 (balanced reduction, lme4, 95% CI
coverage). Resolves the ADR-006 debt. See MILESTONES M3.

## M4 — "Choosing an ICC" flagship vignette — **in progress** (ADR-009; no new estimator)

Teaching milestone: the decision-framework article on shipped M3 code. Numbers are
computed by `icc()` at knit time and seeded; asserted relationships are tested
(PRINCIPLES #1/#4/#12). Ships on an `m4-<slug>` branch, merged via PR.

### Slice 1 — teaching dataset + balanced core + diagram

- [x] `data-raw/make-ratings.R`: deterministically build `ratings` (balanced SF
      6×4) and `ratings_incomplete` (connected incomplete variant of `ratings`) — Opus
- [x] `R/data.R` roxygen for both datasets (`@source` SF 1979; `@details` missing
      cells + connectedness + `k_eff` for the incomplete one); `LazyData: true`;
      `usethis::use_data()`; WORDLIST + pkgdown reference entry — Opus
- [x] `choosing-an-icc.Rmd` balanced core: worked examples for `type`/`unit`/`raters`
      on `data(ratings)` (returns 0.290/0.620/0.715/0.909); McGraw–Wong ↔
      Shrout–Fleiss naming crosswalk — Opus
- [x] Decision-tree figure: dependency-free static SVG at `vignettes/` (ADR-009
      refinement), embedded via `knitr::include_graphics()`; renders in vignette — Opus
- [x] `test-vignette-claims.R`: agreement ≤ consistency, `ICC(*,k)` ≥ `ICC(*,1)`,
      fixed≡random on balanced (backs the prose) — Opus
- [x] Slice-1 close: `air`/`lintr`/spell clean; vignette knits; check 0/0/0 — Opus

### Slice 2 — incomplete-design payoff + close-out

- [x] `choosing-an-icc.Rmd` incomplete section on `data(ratings_incomplete)`:
      `k_eff`, connectedness abort, **fixed ≢ random on incomplete**; claims test
      extended to these invariants — Opus
- [x] Subject-vs-cluster axis previewed conceptually, forward-pointer to M5 (not
      demonstrated) — Opus
- [x] pkgdown `articles:` grouping surfacing the flagship; `getting-started.Rmd`
      → `ratings` + link the real article; refresh `advanced.Rmd` note — Opus
- [x] README refresh: stale M1 NOTE → actual state; Example a real runnable
      `icc()` on `ratings` (`eval = TRUE`) + article link; `README.md` rebuilt.
      Also added the missing M3 + new M4 NEWS entries — Opus
- [x] Milestone close: `devtools::check()` 0/0/0 local, 133 tests, `air`/`lintr`
      clean; `MILESTONES.md`/`STATUS.md`/`TASKS.md` updated same-commit; NEWS
      (M3 + M4); PR open — Opus. *(full CI matrix + merge + tag pending on the PR)*
