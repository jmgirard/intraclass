# Milestones

Ordered milestones with Definition of Done and status. **Shipped milestones
(M0–M7) are fully specified; the remaining ones (M8–M9) are provisional**
one-liners, detailed only at the start of their milestone after a short retro on
the previous one (founding brief §7). The arc is a hypothesis, not a contract —
reorders get a [`DECISIONS.md`](DECISIONS.md) entry (the M6–M9 sequence was set by
ADR-013; ADR-014 detailed M7).

Definition of Done references are to `CLAUDE_CODE_KICKOFF.md` §8.

---

## M0: Scaffolding
- Goal: A green, well-tracked, empty-but-real package that others can build on.
- Definition of Done:
  - [x] Package skeleton (`DESCRIPTION`, `NAMESPACE`, `R/`, license, README, NEWS).
  - [x] `project/` tracking system populated (this file + siblings).
  - [x] `.claude/` skills (`status`, `start-task`, `finish-task`, `verify-estimator`,
        `new-estimator`, `add-decision`) and the `doc-polisher` (Sonnet) agent.
  - [x] CI workflows (R-CMD-check matrix, coverage, lint, pkgdown, scheduled
        reference-values) + pkgdown config; stub site builds.
  - [x] Lean `CLAUDE.md` pointing at `project/` and the routing policy.
  - [x] `devtools::check()` clean (0 errors / 0 warnings; notes justified).
  - [x] Public `jmgirard/intraclass` repo created; first push; CI green.
  - [x] air formatter + CI format check (ADR-004).
- Status: done (commit 0d81e34, pushed, CI green)

## M1: Two-way random, absolute agreement — `ICC(A,1)` / `ICC(A,k)`
- Goal: One estimator working end-to-end (fit → estimate → MC CI → print/tidy →
  tested → documented → CI green), proving the whole pipeline before widening.
- Estimand: see [`estimand-specs/M1-twoway-random-agreement.md`](estimand-specs/M1-twoway-random-agreement.md).
  ICC(A,1) = σ²_s / (σ²_s + σ²_r + σ²_res); ICC(A,k) = σ²_s / (σ²_s + (σ²_r + σ²_res)/k).
- Definition of Done (per-estimator bar, §8):
  - [x] Public `icc()` API per the seed test signature; classed `icc` object.
  - [x] glmmTMB engine (only selectable engine in M1); lme4 oracle-only (ADR-005).
  - [x] Boundary-aware Monte-Carlo CIs from `vcov(fit, full = TRUE)` (ADR-003).
  - [x] `print` / `summary` / `format` / `tidy` / `glance` methods.
  - [x] Oracle tests — ≥2 independent types, actually 5:
        (a) Shrout & Fleiss (1979) worked values ICC(A,1)=0.290, ICC(A,k)=0.620;
        (b) `psych::ICC` on the balanced case to 1e-4;
        (c) package-independent ANOVA mean-squares (base `aov`);
        (d) seeded simulation with known population variance components;
        (e) lme4-vs-glmmTMB cross-check.
  - [x] Boundary/error-path tests; `cli` messaging + classed errors; print snapshot.
  - [x] Roxygen "which ICC / when" note incl. the single-rating identifiability caveat.
  - [x] *Getting started* vignette knits.
  - [x] `REFERENCES.md` + `DECISIONS.md` updated; coverage 94% (statistical paths
        100%); `devtools::check()` 0/0/0 locally. Full CI matrix confirmed on push.
- Status: done (code at 77e8ab0, pushed, full CI matrix green; marked done in 37f59c0)

## M2: Consistency variants + fixed-vs-random raters
- Goal: add `ICC(C,1)`/`ICC(C,k)` and a `raters = random|fixed` interpretation
  dimension, generalizing the estimand abstraction — **no new fit, no new CI
  machinery**. Balanced/complete data only (incomplete designs are M3).
- Estimand: see [`estimand-specs/M2-consistency-and-fixed.md`](estimand-specs/M2-consistency-and-fixed.md).
  Consistency drops the rater main effect from the error set:
  ICC(C,1) = σ²_s / (σ²_s + σ²_res); ICC(C,k) = σ²_s / (σ²_s + σ²_res / k).
  Fixed vs. random raters is a **label/interpretation layer** over the shared
  random-effects fit — verified numerically identical on balanced data (ADR-006).
- Definition of Done (per-estimator bar, §8):
  - [x] `type = "consistency"` unlocked → `ICC(C,1)`/`ICC(C,k)`; `unit` unchanged.
  - [x] New public arg `raters = c("random", "fixed")` (default `"random"`);
        `"fixed"` opt-in, returns valid estimates via the shared fit.
  - [x] Estimand abstraction generalized: consistency error set {residual} + a
        `raters`/design dimension used for labeling only. `icc_point()`/`mc_ci()`
        unchanged (consistency omits the rater draw per the existing error set).
  - [x] Classed warning layer (`warn_intraclass()`, PRINCIPLES.md #8) + a loud
        `intraclass_fixed_raters` best-practice warning when `raters = "fixed"`.
  - [x] `print`/`summary`/`format` surface the design (two-way random vs mixed)
        and the Shrout–Fleiss equivalent (ICC(2,·) vs ICC(3,·)); snapshots updated.
  - [x] Boundary-aware Monte-Carlo CIs verified for consistency (rater term absent
        per draw); `raters="fixed"` CI equals `raters="random"` CI (balanced).
  - [x] Oracle tests — ≥2 independent types (5, per M1):
        (a) Shrout & Fleiss ICC(C,1)=0.715, ICC(C,k)=0.909;
        (b) `psych::ICC` ICC3/ICC3k on balanced data to 1e-4;
        (c) package-independent ANOVA mean-squares (existing helper);
        (d) lme4 cross-check;
        (e) fixed≡random point/CI equivalence on balanced data (encodes ADR-006).
  - [x] Warning-path tests: `expect_warning(class="intraclass_fixed_raters")` for
        `"fixed"`; `"random"` silent; warning-text snapshot.
  - [x] Roxygen "which ICC / when" extended to consistency and fixed-vs-random,
        stating random is recommended and fixed forgoes generalization; *Getting
        started* vignette gains a consistency-vs-agreement note.
  - [x] `REFERENCES.md` (O1 rows C1/Ck promoted to asserted; new O4 fixed≡random
        oracle) + `DECISIONS.md` (ADR-006) updated; coverage 94.8% (statistical
        paths 100%); `devtools::check()` 0/0/0 locally.
  - [x] Full CI matrix confirmed green on PR #1 (all 9 checks); merged to `main`.
- Deferred to their own slices (not M2): lme4 as a *selectable* engine + bootstrap
  CI (supersedes ADR-005's "defer to M2"); D-study projection to arbitrary k.
- Status: done (merged to `main` via PR #1 at 334a48a; full CI matrix green)

## M3: Imbalanced & incomplete designs
- Goal: correct ICCs from the mixed model on **ragged** subject×rater designs
  (missing cells) — the package's core differentiator vs. ANOVA/balanced-only
  tools. **Statistical core only:** the flagship "Choosing an ICC" vignette is
  promoted to its own milestone (M4 below) so it can demonstrate the
  complete-vs-incomplete decision on working code (ADR-007). Resolves the ADR-006
  fixed-raters debt with a **real fixed-effect fit path**.
- Estimand: see [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md)
  (to be written first, PRINCIPLES.md #2). Builds on M1/M2; the fit already handles
  imbalance, so the additions are identifiability guards, the fixed-effect fit path
  + its CI variant, the `ICC(*,k)` divisor rule under imbalance, and unbalanced-data
  oracles.
- Definition of Done (per-estimator bar, §8) — two internal slices, each CI-green:
  - [x] **Slice 1 — incomplete random raters (default path).** Connectedness /
        identifiability guard (`abort_unidentified()` on a disconnected
        subject–rater graph, PRINCIPLES.md #5); balance detection; `k_eff`
        divisor per the spec; `ICC(*,1)` always well-posed. `mc_ci()` unchanged
        for the random path.
  - [x] **Slice 2 — real fixed-effect fit path** (`score ~ 1 + rater +
        (1 | subject)`) for `raters = "fixed"`, returning correct (and genuinely
        different) estimates on incomplete data; agreement error set gains the
        bias-corrected rater-effect spread θ²_r (McGraw–Wong Case 3A); a fixed-path
        MC-CI sampler. Balanced data reduces to the M2 numbers (θ²_r = σ²_r = 5.2444;
        extends O4). `raters` roxygen note corrected.
  - [x] Oracles per path — ≥2 independent types: seeded unbalanced simulation +
        lme4 cross-check + balanced-reduction regression (full SF still returns
        0.290/0.620/0.715/0.909); O5 (random) and O6 (fixed, incl. 95% CI
        coverage) in `REFERENCES.md`. `irrNA`/`gtheory` not needed — lme4 + sim met
        the ≥2-oracle bar (#1); no coefficient required a Fable review.
  - [x] `print`/`glance` surface balanced-vs-incomplete, n_cells, and `k_eff`;
        snapshots updated.
  - [x] Roxygen "which ICC / when" extended to complete-vs-incomplete and the fixed
        real-fit; `DECISIONS.md` ADR-008 (fixed real-fit path + divisor convention);
        `devtools::check()` 0 errors/0 warnings locally (1 pre-existing CRAN-incoming
        NOTE); full CI matrix green on PR #2.
- Deferred out of M3 (recorded so they aren't rediscovered): the flagship vignette
  (M4); replicate ratings within a cell; one-way designs; lme4 as a *selectable*
  engine; D-study projection API (ROADMAP).
- Status: done (Slices 0–2; merged to `main` via PR #2 at 11ab1b2; full CI matrix
  green — tests 118/0/0, check 0/0/1 justified, coverage 93.8%)

## M4: "Choosing an ICC" flagship vignette
- Goal: the decision-framework teaching article — agreement vs. consistency,
  single vs. average, fixed vs. random, complete vs. incomplete — demonstrated on
  the now-shipped M3 code, with a decision-tree diagram and a shipped teaching
  dataset. Split out of the old M3 by ADR-007; scoped by ADR-009. **No new
  estimator, no new estimand spec.** The `choose_icc()` helper stays in ROADMAP.
- Guiding discipline: this is a teaching artifact, but PRINCIPLES still bind.
  Every coefficient displayed is **computed by `icc()` at knit time with a fixed
  seed** (#4 no fabricated values, #12 seeded/sourced) — never a hand-typed number
  that can drift — and the numeric relationships the prose asserts are backed by a
  test (#1 oracle-first). A flagship article that silently states a false
  relationship violates the constitution as surely as a bad estimator.
- Definition of Done (per-milestone §8, adapted — no per-estimator bar) — two
  internal slices, each CI-green:
  - [x] **Slice 1 — teaching dataset + balanced core + diagram.** Ship `ratings`
        (balanced Shrout & Fleiss 1979 6×4, `@source`-cited) and
        `ratings_incomplete` (a curated *connected-but-incomplete* variant derived
        from `ratings`, `@details` documenting the missing cells, connectedness,
        and `k_eff`), built by a deterministic `data-raw/make-ratings.R`;
        `LazyData: true`, `R/data.R` docs, pkgdown reference entry, WORDLIST.
        Then `choosing-an-icc.Rmd`'s balanced core: worked examples for the three
        balanced axes (`type`, `unit`, `raters`) returning the pinned
        0.290/0.620/0.715/0.909; the decision-tree figure (dependency-free static
        SVG under `man/figures/`, **no new Imports**); the McGraw–Wong ↔
        Shrout–Fleiss naming crosswalk. `test-vignette-claims.R` asserts
        agreement ≤ consistency and `ICC(*,k)` ≥ `ICC(*,1)` on the dataset so no
        prose claim is unbacked.
  - [x] **Slice 2 — incomplete-design payoff + close-out.** The complete-vs-
        incomplete section on M3 code using `ratings_incomplete`: surface `k_eff`,
        the connectedness abort, and **fixed ≢ random on incomplete data** (the
        reason this vignette waited for M3), with the claims test extended to
        these invariants. Subject-vs-cluster axis previewed conceptually with a
        forward-pointer to M5 (not demonstrated — multilevel isn't built). Wire
        the article into a pkgdown `articles:` grouping; update
        `getting-started.Rmd` to `data(ratings)` and link the now-real article;
        refresh `advanced.Rmd`'s placeholder note. **README refresh**: rewrite the
        stale NOTE (it still says M1 is current) to reflect actual state, make the
        Example block a real runnable `icc()` call on `data(ratings)`
        (`eval = TRUE`), link the flagship article, and rebuild `README.md` from
        `README.Rmd` (commit both in sync).
  - [x] Every displayed coefficient computed by `icc()` at knit time, seeded.
  - [x] `devtools::check()` 0 errors/0 warnings/0 notes locally (vignettes knit;
        the prior CRAN-incoming NOTE is gone); coverage floor held (no statistical
        code added). `air`/`lintr` clean; spell advisory tidy (WORDLIST +=
        `connectedness`). Full CI matrix confirmed on the PR.
  - [x] `DECISIONS.md` ADR-009 (M4 scope); `MILESTONES.md`/`STATUS.md`/`TASKS.md`
        updated same-commit (#16). Shipped on the `m4-choosing-icc` branch,
        merged via PR #5.
- Deferred out of M4 (recorded so they aren't rediscovered): the `choose_icc()`
  decision helper (ROADMAP); filling `advanced.Rmd` (incomplete/multilevel/engine
  sections — M5+); a `DiagrammeR`/`mermaid`-rendered diagram (adds a dep for zero
  teaching gain vs. static SVG); migrating the oracle tests off inline data (they
  pin numeric values — left untouched deliberately).
- Status: done (Slices 1–2; merged via PR #5 at 4d4b2ba; full CI matrix green —
  9/9, `devtools::check()` 0/0/0 local, 133 tests pass). Ships the flagship
  "Choosing an ICC" article, the decision-tree diagram, and the
  `ratings`/`ratings_incomplete` datasets.

## M4.5: D-study projection — reliability at other rater counts (ADR-010)
- Goal: project the reliability of a fitted `icc()` to the mean of an arbitrary
  number of raters `m` (a generalizability-theory decision study), the deferred
  ROADMAP item, shipped as its own slice before M5. The projection is a change of
  the averaging **divisor** in the existing `(signal, {error set}, divisor)`
  estimand — reuse, not new machinery (estimand-spec `M4.5-d-study.md`).
- Definition of Done:
  - [x] **Slice 1 — projection core + numeric `unit` + oracles.** Estimand carries
        a resolved numeric `divisor` (`resolve_divisor()`); `icc_point()` drops its
        `k` arg. `icc()`'s `unit` accepts numbers (`unit = c("single", 3)` →
        `ICC(A,3)`, no SF label); the fixed-rater absolute-agreement projection is
        refused (`abort_unidentified`, #5). `icc()` stores the engine's
        `estimate`/`vcov`/`to_components` (`x$mc`) so `d_study(x, m = …)` reuses the
        fit with no refit; `mc_components()`/`mc_interval()` factored out of
        `mc_ci()` and the MC sample is drawn once, evaluated at every `m`. Oracles
        (O-DS): Spearman–Brown (consistency), GT dependability (agreement),
        `psych::ICC` average-measure at `m = n_raters`, seeded simulation;
        `data-raw/oracle-d-study.R`; `test-d-study.R`.
  - [x] **Slice 2 — reliability curve + docs.** `autoplot.icc_dstudy()` (ggplot2,
        `check_installed`-guarded, lazily registered in `zzz.R` via a vendored
        `s3_register()` — light install preserved); `plot.icc_dstudy()` forwards to
        it. `print`/`tidy`/`glance` methods. NEWS, roxygen (experimental badge),
        `_pkgdown` reference group, and a D-study section in `advanced.Rmd` with a
        backing `test-vignette-claims.R` assertion.
  - [x] `devtools::check()` 0/0/0 local; `air`/`lintr` clean; spell advisory tidy
        (non-gating). Full CI matrix on the PR.
  - [x] ADR-010; estimand-spec `M4.5-d-study.md`; oracle O-DS in REFERENCES;
        tracking updated same-commit (#16). Ships on `m4.5-d-study`, merged via PR.
- Deferred (recorded so they aren't rediscovered): cost/optimal-design helpers
  ("cheapest `m` for Φ = 0.8"), two-facet D-studies, and subject-count projection
  (ROADMAP; M4.5 spec §6).
- Status: done (Slices 1–2; merged via PR #6 at 9be03a0; full CI matrix green —
  9/9, `devtools::check()` 0/0/0 local). Ships `d_study()`, the numeric-`unit`
  projection, and the `autoplot()` reliability curve.

## M5: Multilevel ICCs — subject-level vs. cluster-level
- Goal: add subject-level (within-cluster) and cluster-level (between-cluster)
  interrater ICCs for designs where subjects are nested in clusters (ten Hove,
  Jorgensen & van der Ark 2022), the "fifth choice" the flagship vignette
  previews. **Crossed raters, balanced/complete, random raters** in M5; the
  agreement/consistency and single/average knobs work at both levels.
- Estimand: see [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md)
  (written first, PRINCIPLES.md #2; equations transcribed verbatim from ten Hove
  Table 3, Design 1). First estimand where the **signal component changes** (σ²_{s:c}
  subject vs. σ²_c cluster). Each coefficient is still `signal / (signal + error /
  k)` — the **scalar divisor and `icc_point()` are unchanged** (an earlier plan
  assumption of a subject×rater two-facet average was wrong: the cluster-level ICC
  drops all subject variance, Eq. 13). Model `score ~ 1 + (1 | cluster) + (1 |
  cluster:subject) + (1 | rater) + (1 | cluster:rater)`; **five** components
  σ²_c/σ²_{s:c}/σ²_r/σ²_{cr}/σ²_res; both levels read off **one shared fit**; the
  Monte-Carlo CI (ADR-003) is inherited unchanged.
- Scope decisions (ADR-011): Design 1 (raters crossed with clusters) only;
  balanced/complete first; random raters only; API adds a `cluster` selector + a
  `unit`-style `level = c("subject","cluster")` knob that returns both levels by
  default. Designs 2/3, incomplete, and fixed-rater multilevel are deferred (spec §8).
- Definition of Done (per-estimator bar, §8) — two internal CI-green slices:
  - [x] **Slice 1 — estimator (both levels).** `cluster` (tidy-eval selector,
        default `NULL` → backward-compatible single-level path) + `level`
        (validated/iterated like `unit`) args; glmmTMB engine extended to the
        five-component Design-1 fit (`fit_glmmtmb_multilevel()`, adds
        `(1 | cluster:rater)`) with component extraction; identifiability guards
        (spec §7: ≥2 raters, ≥2 clusters, subject not 1:1 with cluster,
        subject-spans-cluster, out-of-scope fixed/numeric-unit). Both the
        subject-level (§3a) and cluster-level (§3b) signal/error maps read the
        **same fit** via the unchanged scalar `icc_point()`. `print`/`tidy`/`glance`
        surface `level` + `n_clusters` + the five components; single-level output
        byte-identical (snapshots unchanged); `d_study()` aborts on multilevel.
        Oracles O-ML: lme4 cross-engine (<1e-4), seeded population recovery (<0.05)
        + MC coverage, single-level reduction (algebraic + zero-cluster-variance).
        Committed `0089d9a`. (The plan split subject/cluster across two slices, but
        the paper's scalar divisor made both trivially the same fit — done together.)
  - [x] **Slice 2 — docs.** `advanced.Rmd` multilevel section on real code (seeded
        pupils-in-classrooms example, cluster > subject); `choosing-an-icc.Rmd`
        "fifth choice" updated to shipped + **citation fixed** (was the wrong paper
        dated 2021 → ten Hove et al. 2022); `test-vignette-claims.R` multilevel
        invariant; NEWS; roxygen "Multilevel designs" section + ten Hove 2022 ref.
  - [x] Oracles per PRINCIPLES.md #1 — lme4 + seeded simulation + single-level
        reduction (O-ML in `REFERENCES.md`); no external worked example exists for
        this estimand (as with O5). `psych`/`gtheory` are not oracles here; a
        Bayesian/MCMC cross-check remains deferred (a future Bayesian engine;
        ROADMAP — it was tied to the old "M6 = optional engines" slot, which the
        ADR-013 renumber moved to M7, where the Bayesian backend is itself deferred).
        Any coefficient unpinnable by both required oracles is not shipped (Fable
        review recommended, then pause — #1/#19).
  - [x] `DECISIONS.md` ADR-011 (M5 scope + `level` API + Design-1 five-component fit);
        `air`/`lintr` clean; vignettes knit; full local suite green (no snapshot
        drift). Ships on `m5-multilevel`; `devtools::check()` 0/0/0 + full CI matrix
        confirmed on the PR.
- Deferred out of M5 (recorded so they aren't rediscovered): the paper's Designs
  2/3 (raters nested in clusters and/or subjects); incomplete multilevel (reuse M3
  `k_eff`/connectedness); fixed-rater multilevel; a Bayesian/MCMC cross-engine
  (the paper's own estimator — a future Bayesian engine, ROADMAP; was the old "M6"
  optional-engines slot, renumbered by ADR-013); a three-facet `d_study()` projecting
  subject-per-cluster counts; exposing the conflated single-level ICC (Eq. 14) as
  a shipped coefficient. (See spec §8.)
- Status: done (Slices 1–2; merged via PR #8 at `87b4588`; full CI matrix green —
  9/9, `devtools::check()` 0/0/0 local, 188 tests pass). Ships `icc(cluster =, level
  =)` for subject- and cluster-level multilevel ICCs off one five-component
  Design-1 fit, oracles O-ML (lme4 + seeded sim + single-level reduction), and the
  advanced-vignette multilevel section.

## M5.5: lme4 as a selectable engine (pre-optional-engines interface slice, ADR-012)
- Goal: promote **lme4 from oracle-only to a selectable `engine = "lme4"`** for the
  default random two-way path, returning the same six-field engine contract so the
  whole downstream pipeline (`icc_point`/`mc_ci`/`d_study`) is untouched. Resolves
  the ADR-005 deferral (lme4-selectable, deferred since M2) and builds the
  **engine × design dispatch seam** the optional-engines milestone (now M7,
  ADR-013) plugs brms/lavaan into — de-risking that work by proving the interface
  with an engine already trusted as the cross-check oracle.
  **No new estimand, no estimand-spec** (cf. M4); scope decisions in ADR-012.
- Definition of Done (one CI-green slice):
  - [x] `engine = "lme4"` selectable for the random two-way path; `R/engine-lme4.R`
        `fit_lme4()` fits `lmer(score ~ 1 + (1|subject) + (1|rater), REML = TRUE)`
        and returns `list(fit, engine, components, estimate, vcov, to_components)`
        on a **boundary-safe (log-SD) scale**; the hardcoded glmmTMB if/else in
        `icc()` becomes an engine × design lookup.
  - [x] CI via **merDeriv** (new `Suggests`) reusing the existing `montecarlo`
        path — no new `ci_method` value; `check_installed()` for both `lme4` and
        `merDeriv`; light install preserved. (The SD-scale merDeriv covariance is
        delta-transformed to log-SD; verified to reproduce glmmTMB's internal
        `vcov(full = TRUE)` to ~1e-4 in every entry.)
  - [x] `engine = "lme4"` with `raters = "fixed"` or a multilevel design →
        classed `abort_unsupported()` (deferred, recorded so not rediscovered).
  - [x] Oracles O-LME (≥2 independent, extending the existing lme4-oracle tests):
        (a) point lme4 ≡ glmmTMB ≤ 1e-4 on SF `ratings` (0.290/0.620/0.715/0.909);
        (b) **interval** lme4 MC CI ≈ glmmTMB MC CI ~1e-2 (new cross-engine
        interval oracle — the payoff of merDeriv over bootstrap; observed ≤9.4e-3);
        (c) boundary — near-zero (non-singular) rater variance emits no
        negative-variance draws; a **singular** fit aborts loudly (see below);
        (d) seeded-sim coverage of the lme4 MC CI at nominal.
  - [x] `print`/`glance` surface `engine = "lme4"`; lme4 print snapshot; roxygen
        `@param engine` corrected (drops "Only glmmTMB"); NEWS; short advanced.Rmd
        engine-choice note with a backing `test-vignette-claims.R` line.
  - [x] `merDeriv` → `Suggests`; `devtools::check()` 0/0/0 local; `air`/`lintr`
        clean; tests 219/0/0; ADR-012; MILESTONES/STATUS/TASKS same-commit (#16).
        Ships on `m5.5-lme4-engine`, merged via PR; full CI matrix on the PR.
- **Discovered during the slice (recorded, ADR-012):** merDeriv cannot form the
  parameter covariance for a **singular fit** (a variance component pinned to
  exactly zero), where glmmTMB's log-SD scale stays finite. `fit_lme4()` detects
  `lme4::isSingular()` and raises a classed `intraclass_singular_fit` error
  directing the user to `engine = "glmmTMB"` (#5/#8) — a narrow, well-defined
  engine asymmetry, not a silent wrong answer.
- Deferred out of M5.5 (recorded so not rediscovered): lme4 for the fixed-effect
  (Case 3/3A) and multilevel fits (→ M8, ADR-013); the parametric-bootstrap
  `ci_method` (bootMer) → M7/ROADMAP; a boundary-robust lme4 interval for singular
  fits (glmmTMB covers it today); merDeriv edge cases beyond the two-way random model.
- Status: done (one slice; merged via PR #9 at `edd9d88`; full CI matrix green —
  9/9 incl. Windows, `devtools::check()` 0/0/0 local, tests 219/0/0, lintr clean).
  Ships selectable `engine = "lme4"` for the random two-way path via a
  merDeriv-backed Monte-Carlo interval on glmmTMB's log-SD scale, oracles O-LME
  (point + interval cross-engine, boundary + singular-fit abort, seeded-sim
  coverage), and the advanced-vignette engine-choice section.

## M6: One-way random ICC(1) / ICC(1,k)
- Goal: the last member of the classic Shrout–Fleiss family — **one-way random
  effects** (SF Case 1), where subjects are not crossed with a fixed set of raters,
  so rater identity is not modeled. `ICC(1) = σ²_s / (σ²_s + σ²_res)`; `ICC(1,k)`
  averages the error over `k`. First milestone to change the **fitted model** itself
  (`score ~ 1 + (1 | subject)`, no rater term) rather than re-reading the two-way
  fit — one-way ≠ consistency despite identical algebra (the confounded residual
  carries the rater spread; SF ICC(1)=0.166 vs ICC(C,1)=0.715). Promoted from
  ROADMAP by ADR-013.
- Estimand: see [`estimand-specs/M6-oneway.md`](estimand-specs/M6-oneway.md)
  (written first, PRINCIPLES.md #2; estimand + all four oracles verified live before
  code). Adds a `model = "oneway"` knob; `type`/`raters="fixed"`/`cluster` do not
  apply (documented / aborted); numeric `unit` (D-study) supported for free via the
  inherited `resolve_divisor()`; `rater` still required but its identity is ignored
  (defines `k` only — documented clearly). API decisions pinned in spec §5.
- Definition of Done (per-estimator bar, §8) — one CI-green slice:
  - [x] Public `model = "oneway"` unlocked → `ICC(1)`/`ICC(k)` (+ `ICC(m)` for
        numeric `unit`); `model` validated via `validate_choice` (`twoway`/`oneway`).
  - [x] `fit_glmmtmb_oneway()` + `fit_lme4_oneway()` (`~ 1 + (1 | subject)`)
        returning the shared six-field contract (`subject`/`residual`, no rater
        term); `icc_point()`/`resolve_divisor()`/`mc_ci()` reused unchanged; MC CI
        boundary-aware (ADR-003). Balance / `k_eff` reused from M3
        (`summarize_design()`); rater identity ignored; two-way-only guards
        (n_raters≥2, connectedness, replicates) skipped, replaced by a one-way
        replication guard.
  - [x] Guards (#5/#8): `raters = "fixed"` + oneway → classed `abort_unsupported()`;
        `cluster` + oneway → classed abort; `type` ignored (documented, not aborted);
        one-rating-per-subject → `abort_unidentified`.
  - [x] Oracles O-OW (5 independent): SF `0.166`/`0.443` (`sf_oracle_all`, absolute
        gap); `psych::ICC` ICC1/ICC1k ≤1e-4; package-independent one-way ANOVA mean
        squares; glmmTMB↔lme4 cross-engine (point + interval); seeded simulation
        (recovery + 95% CI coverage). Absolute tolerances on CI bounds (M5.5 lesson).
  - [x] `print`/`summary`/`format`/`tidy`/`glance` surface the one-way design +
        `ICC(1)`/`ICC(k)` label + SF crosswalk (`ICC(1,1)`/`ICC(1,k)`); `glance`
        `var_rater` = NA; print snapshot.
  - [x] Roxygen `@param model`/`@param type` extended to one-way (rater-identity-
        ignored + type-not-applicable notes); `choosing-an-icc.Rmd` "are the raters
        crossed?" prior-question section + `getting-started` note, backed by a
        `test-vignette-claims.R` line; NEWS.
  - [x] `REFERENCES.md` O-OW row (O1 one-way values promoted to asserted);
        `devtools::check()` 0/0/0 local; `air`/`lintr` clean; tests 247/0/0.
        MILESTONES/STATUS/TASKS same-commit (#16). Ships on `m6-oneway`, merged via
        PR; full CI matrix on the PR.
- Deferred out of M6 (recorded so not rediscovered): within-cell replicates
  (`(1 | subject:rater)`); one-way *fixed* (not meaningful); categorical/ordinal
  one-way (GLMM). (Spec §10.)
- Status: done (one slice; merged via PR #10 at `eb7102d`; full CI matrix green —
  9/9 incl. Windows on first try, `devtools::check()` 0/0/0 local, tests 247/0/0,
  lintr clean). Ships `model = "oneway"` (ICC(1)/ICC(k), + numeric-unit projection)
  on both engines, oracles O-OW (textbook + psych + ANOVA + cross-engine + sim),
  and the choosing-an-icc "are the raters crossed?" section.

## M7: SEM engine (lavaan) — optional Bayesian/SEM backends, SEM first
- Goal: promote **lavaan (SEM / common-factor GT) to a selectable
  `engine = "lavaan"`** for the two-way random path, plugging a third
  engine into the M5.5 engine × design dispatch seam behind
  `rlang::check_installed()` (Suggests, never Imports; light install preserved). It
  leads the "optional engines" milestone; the Bayesian backend is deferred to a
  later slice/milestone (ADR-014). **No new estimand, no estimand-spec** — an engine
  for existing estimands (cf. M4/M5.5); scope in ADR-014.
  *(was M6 → M7 per ADR-013; was M5 before)*
- Chosen shape (ADR-014, maintainer-approved this session): **SEM leads over
  Bayesian** because it (1) reuses the existing Monte-Carlo CI path (lavaan exposes
  `vcov()` → **no new `ci_method`**), (2) installs light (no Stan compilation → CI
  stays fast/green on all platforms), and (3) can be pinned to a **textbook oracle**
  (Jorgensen 2021, which also argues for MC CIs — corroborating ADR-003). Design
  scope = **two-way random** (planning said "+ one-way"; one-way SEM was deferred
  during implementation — no faithful sourced route, ADR-014).
- Key references (pin when they back code, PRINCIPLES.md #12): the SEM/lavaan
  engine's primary source is **Jorgensen (2021), "How to Estimate Absolute-Error
  Components in Structural Equation Models of Generalizability Theory," *Psych* 3,
  113–133** (doi:10.3390/psych3020011) — defines absolute-error components via
  mean-structure constraints and independently argues **Monte-Carlo CIs** over the
  delta method (corroborates ADR-003); plus **lavaan** (Rosseel 2012, *JSS* 48(2)).
  For the deferred Bayesian slice: ten Hove, Jorgensen & van der Ark (2020),
  "Comparing Hyperprior Distributions to Estimate Variance Components for IRR
  Coefficients" (half-*t* over uniform). PDFs are in the maintainer's Zotero; add to
  `REFERENCES.md` when they back code.
- Definition of Done (per-engine bar, §8) — two internal CI-green slices:
  - [ ] **Slice 1 — lavaan two-way random.** `engine = "lavaan"` selectable for
        `model = "twoway"`, `raters = "random"`; `R/engine-lavaan.R::fit_lavaan()`
        reshapes long → wide and fits a one-factor SEM (consistency:
        σ²_s/(σ²_s+σ²_res); absolute agreement: σ²_r = Σν²/(k−1) from the effects-coded
        indicator intercepts, Jorgensen 2021 Eq. 6 — the **raw** indicator-mean
        estimator, no bias correction), returning the shared six-field engine
        contract. `vcov(fit)` feeds the existing `montecarlo` path (**no new
        `ci_method`**); σ²_s/σ²_res on the log-SD scale so draws stay positive (#3);
        a Heywood fit (σ² ≤ 0) aborts loudly (classed → glmmTMB). Dispatch seam gains
        lavaan rows; `check_installed("lavaan")`; lavaan → `Suggests`. Guards:
        `raters="fixed"`, `cluster`, incomplete/unbalanced + lavaan →
        `abort_unsupported()` (deferred, recorded). Oracles O-SEM: **consistency** ≡
        glmmTMB ≤1e-4 + `psych` ICC3/ICC3k (exact); **agreement** = the SEM estimator
        (0.284 on SF, **not** 0.290), pinned by the exact Σν²/(k−1) formula + a
        large-N lavaan→population & lavaan≈glmmTMB convergence sim + the Vispoel et
        al. (2022) GENOVA/`gtheory` external check; interval vs glmmTMB *fixed*
        (agreement) / *random* (consistency), absolute gap. `data-raw/oracle-sem.R`;
        `test-icc-lavaan.R`.
  - [ ] **Slice 2 — docs (no new estimator).** `print`/`glance` surface
        `engine = "lavaan"`; lavaan print snapshot; NEWS; `advanced.Rmd` SEM-engine
        section (when to prefer SEM; the indicator-mean absolute-error estimator and
        its small-sample difference from the mixed model; the MC-CI corroboration)
        with a backing `test-vignette-claims.R` line; REFERENCES O-SEM rows
        (Jorgensen 2021, Vispoel et al. 2022, Lee & Vispoel 2024). (`@param engine`
        already updated in Slice 1.)
  - [ ] Oracles per PRINCIPLES.md #1 — asserted by oracle, never by the formula.
        Consistency is pinned exactly (lavaan ≡ glmmTMB + psych); absolute agreement
        is a **distinct, asymptotically-equivalent** estimator (Jorgensen Eq. 6),
        pinned by its exact formula + large-N convergence + the Vispoel et al. (2022)
        external validation, **not** by the mixed-model number. Any component
        unpinnable is not shipped (Fable review recommended, then pause — #1/#19).
        CI-bound assertions use **absolute** tolerances (M5.5 lesson).
  - [ ] `devtools::check()` 0/0/0 local; `air`/`lintr` clean; full suite green (no
        snapshot drift beyond the new lavaan snapshot); coverage floor held with the
        new statistical paths oracle-covered. `DECISIONS.md` ADR-014;
        MILESTONES/STATUS/TASKS same-commit (#16). Ships on `m7-sem-engine`, merged
        via PR; full CI matrix on the PR.
- Deferred out of M7 (recorded so not rediscovered): the **Bayesian engine**
  (rstanarm preferred over brms for CI-install sanity) + a new
  `ci_method = "posterior"` (credible intervals) + half-*t* hyperpriors (ten Hove et
  al. 2020) — a later slice or follow-on milestone; **one-way random via SEM** (no
  faithful sourced route — ADR-014; parked in ROADMAP); **incomplete/unbalanced SEM**
  (FIML); **fixed-rater and multilevel SEM**.
- Status: done (merged via PR #11 at fe76f5c; full CI matrix green). Ships
  `engine = "lavaan"` for the two-way random path (Jorgensen 2021 SEM-GT), oracles
  O-SEM (consistency ≡ glmmTMB; agreement = the exact indicator-mean estimator +
  large-N convergence + Vispoel et al. 2022 external check), and the advanced-vignette
  SEM-engine section. One-way SEM deferred to ROADMAP (ADR-014).
  `devtools::check()` 0/0/0 local; full suite incl. snapshots green.

## M8: Multilevel & incomplete-design extensions *(provisional)*
- Goal: extend the multilevel estimator beyond M5's Design 1 by working through the
  deferrals grouped from the M5 spec §8 (ADR-013):
  - the paper's **Designs 2/3** — raters nested within clusters and/or subjects
    (ten Hove, Jorgensen & van der Ark 2022, Eqs. 8–11, Table 3 middle/right);
  - **incomplete multilevel** designs, reusing the M3 `k_eff`/connectedness
    machinery;
  - **fixed-rater multilevel**, reusing the M3 real fixed-effect fit path (ADR-008);
  - **lme4 for the fixed and multilevel fits** (deferred out of M5.5, ADR-012).
- Likely split into thin per-design slices (#15); each estimand transcribed from
  the paper and pinned by ≥2 oracles before shipping (#1/#2). Detail at start.
- Status: provisional

## M9: Release polish *(provisional)*
- Goal: pkgdown site, advanced vignette, CRAN submission prep. *(was M7 → M9 per
  ADR-013; was M6 before)*
- Status: provisional
