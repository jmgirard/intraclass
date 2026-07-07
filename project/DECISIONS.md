# Decision log (ADRs)

Dated statistical and architectural decisions with rationale and references
(PRINCIPLES.md #6, #12, #14). Newest at the bottom. Format: context → decision →
consequences → references.

---

## ADR-001: MIT license
- Date: 2026-07-06
- Status: accepted
- Context: The founding brief left the license to be confirmed. A permissive,
  CRAN-friendly license lowers adoption friction for an applied-research audience.
- Decision: License under **MIT** (`MIT + file LICENSE`), copyright Jeffrey Girard,
  2026. Confirmed by the maintainer at bootstrap.
- Consequences: Maximum reuse freedom; no copyleft obligations on downstream users.
  Rules out GPL-style share-alike guarantees.
- References: `CLAUDE_CODE_KICKOFF.md` §3, §7 step 2.

## ADR-002: Default estimation engine is glmmTMB (lme4 supported + as oracle)
- Date: 2026-07-06
- Status: accepted
- Context: The brief specifies `lme4` and/or `glmmTMB` as the default MLE-RE engine.
  The maintainer noted lme4's frequent convergence warnings and leaned toward
  glmmTMB. lme4's warnings on simple models like `score ~ 1 + (1|subject) +
  (1|rater)` are often false positives (a twitchy relative-gradient check), so
  "quieter" alone is a weak justification — but two stronger reasons tie directly
  to PRINCIPLES.md #3 (boundary-aware Monte-Carlo CIs):
    1. `glmmTMB::vcov(fit, full = TRUE)` returns the joint covariance of *all*
       parameters including the variance-component parameters, exactly what MC CIs
       sample from. lme4 does not expose this off the shelf (needs `merDeriv` or a
       parametric bootstrap via `bootMer`, slower and heavier).
    2. glmmTMB parameterizes variances on an internal log-SD / Cholesky scale, so
       MC draws back-transform to variances that stay ≥ 0 — the correct behavior at
       the near-zero-rater-variance boundary that is the common case.
  Verified live this session on the Shrout & Fleiss (1979) data: both engines give
  ICC(A,1) = 0.2898 → 0.290 and ICC(A,k) = 0.6201 → 0.620 (agreeing with the
  published oracle and each other); `vcov(m, full = TRUE)` returned the expected
  4×4 joint covariance.
- Decision: **glmmTMB is the default engine** and the one hard engine dependency
  (Imports). **lme4** is in Suggests and serves two roles: an alternative engine
  and an independent numerical oracle (its balanced-data point estimate must match
  glmmTMB to ~1e-4).
- Consequences: One hard engine dep keeps the base install light. The seed test's
  provisional adapter default `engine = "lme4"` flips to `"glmmTMB"` in M1 (the file
  designates that adapter its single editable binding point; no oracle *value*
  changes), with an lme4-vs-glmmTMB cross-check test retained so both stay verified.
- References: `CLAUDE_CODE_KICKOFF.md` §1 (estimation engines), PRINCIPLES.md #3;
  glmmTMB (Brooks et al. 2017); ten Hove, Jorgensen & van der Ark (2024/2025).

## ADR-003: Monte-Carlo CIs are the default interval method
- Date: 2026-07-06
- Status: accepted
- Context: The ICC is a non-normal ratio of variance components; the delta method
  is unreliable near the zero-rater-variance boundary (the common case). The
  framework's own 2025 simulation work favors MLE-RE with Monte-Carlo CIs.
- Decision: Default interval = **Monte-Carlo**, simulated from the fitted parameter
  covariance matrix (`vcov(fit, full = TRUE)`), on the engine's internal
  (boundary-respecting) scale, back-transformed to variance components, with the
  ICC recomputed per draw and quantiles taken. Seeded in tests (PRINCIPLES.md #12).
  The method used is always reported (PRINCIPLES.md #3). Alternative CI methods
  (bootstrap, profile) are roadmap items, not the default.
- Consequences: Intervals are boundary-aware and engine-agnostic in spirit; requires
  storing/threading a seed and the parameter covariance. Adds a stochastic element
  that must be seeded for reproducibility.
- References: PRINCIPLES.md #3, #12; `CLAUDE_CODE_KICKOFF.md` §1, §2.

## ADR-004: air is the code formatter (lintr keeps only semantic linters)
- Date: 2026-07-06
- Status: accepted
- Context: The brief (§3) calls for a formatter alongside the linter ("`lintr` +
  `air` (or `styler`)"). lintr only *flags*; nothing auto-fixed layout. The
  maintainer chose air over styler.
- Decision: **air** (Posit's Rust formatter) owns code layout, configured in
  `air.toml` (line width 80, 2-space indent, LF). lintr (`.lintr`) keeps only the
  semantic linters and **disables** the ones air owns (`line_length_linter`,
  `indentation_linter`) to avoid conflicting or unfixable reports. A CI
  `format.yaml` job runs `air format --check .` via `posit-dev/setup-air`. The
  hand-aligned Shrout & Fleiss data matrix in `helper-shrout-fleiss.R` is excluded
  from air (it would explode the 6×4 grid to one number per line); lintr still
  checks it.
- Consequences: Deterministic, fast formatting matching the package's "modern
  tooling" ethos; adds a standalone binary dependency for local dev (install via
  the air installer or `posit-dev/setup-air` in CI). Contributors run
  `air format .` before committing (the `finish-task` skill runs it).
- References: `CLAUDE_CODE_KICKOFF.md` §3; https://posit-dev.github.io/air/.

## ADR-005: M1 `icc()` API, estimand representation, and lme4-oracle-only scope
- Date: 2026-07-06
- Status: accepted
- Context: M1 needed a concrete public API and an internal representation that
  would not require a rewrite when M2 adds consistency ICCs and fixed raters.
- Decision:
  - **Public API** `icc(data, score, subject, rater, model = "twoway", type =
    "agreement", unit = c("single", "average"), engine = "glmmTMB", conf_level =
    0.95, ci_method = "montecarlo", mc_samples = 10000, seed = NULL)`; columns
    captured with tidy-eval; returns a classed `icc` object with
    `print`/`summary`/`format`/`tidy`/`glance`.
  - **Estimand representation** = (signal component, {error component set},
    averaging divisor) (estimand-spec §5). Agreement error = {rater, residual};
    consistency (M2) drops `rater`; average divides the error sum by k. So the
    family's knobs are data, not code paths.
  - **Scope**: glmmTMB is the only selectable engine in M1 with covariance-based
    Monte-Carlo CIs; **lme4 is oracle-only** (a test fits `lmer` directly and
    cross-checks point estimates to 1e-4). This narrows ADR-002's "alternative
    engine" for M1; lme4 as a selectable engine (with a bootstrap CI) is deferred
    to M2. Every not-yet-implemented knob value aborts via the classed
    `abort_unsupported()`/`abort_unidentified()` layer (PRINCIPLES.md #5).
- Consequences: One engine end-to-end (thin vertical slice, #15). The seed test's
  provisional adapter default flipped `engine = "lme4"` -> `"glmmTMB"` (sanctioned
  by that file). `withr`/`tibble`: `tibble` promoted to Imports (tidy/glance return
  tibbles); RNG seeding uses a dependency-free save/restore helper rather than
  adding `withr` to Imports (keeps the light-install path).
- References: PRINCIPLES.md #2, #5, #7, #15; estimand-spec §5; ADR-002/003.

## ADR-006: M2 — consistency ICCs, and fixed raters as a balanced-data label layer
- Date: 2026-07-06
- Status: accepted
- Context: M2 adds the consistency coefficients `ICC(C,1)`/`ICC(C,k)` and the
  fixed-vs-random rater distinction. Consistency is a clean change of the M1 error
  set (drop the rater main effect). Fixed-vs-random needed a statistical decision:
  McGraw & Wong (1996) show Case 2 (random) and Case 3 (fixed) share a
  point-estimate *formula* for a given A/C definition, but that result is derived
  in the **ANOVA** framework, and our engine is a **mixed model**. The maintainer
  asked to confirm the equivalence survives REML before relying on it. It was
  verified live this session (seeded script, glmmTMB + lme4 + `psych`, SF data):
  fitting raters as a random intercept vs. as fixed effects returns identical σ²_s
  and σ²_res on **balanced, complete** data (|Δσ²_s| ≈ 4e-5), hence identical
  ICC(C,·) and ICC(A,·). It **breaks under imbalance** (dropping 4 of 24 cells:
  ΔICC(C,1) ≈ 0.0095), because random-rater partial pooling shifts σ²_s once the
  design is non-orthogonal.
- Decision:
  - **Consistency** unlocked via `type = "consistency"` → error set {residual}
    (drops `rater`); labels `ICC(C,1)`/`ICC(C,k)`. No new fit or CI machinery.
  - **Fixed raters** exposed via a new `raters = c("random", "fixed")` argument
    (default `"random"` = M1/Case 2). On M2's balanced data it is a
    **label/interpretation layer over the shared random-effects fit** — it changes
    the reported design (two-way *mixed* vs *random*) and the Shrout–Fleiss
    equivalent (ICC(3,·) vs ICC(2,·)), **not** the number. Justified by the
    verified balanced-data equivalence above.
  - **Best-practice guardrail:** `raters = "fixed"` is opt-in and emits a loud,
    classed `cli` **warning** (`intraclass_fixed_raters`) that random is
    recommended and fixed forgoes generalization; the value is still returned
    (fixed raters is well-posed, so a warning, not `abort_*`). Adds a classed
    warning helper (`warn_intraclass()`) mirroring the `abort_*` layer
    (PRINCIPLES.md #8 — no bare `warning()`), suppressible by class.
  - **Scope guard (load-bearing):** the label-layer shortcut is valid **only for
    balanced data**. **M3 MUST revisit fixed raters** with a real fixed-effect fit
    path (or guard the layer to balanced designs), because the equivalence fails on
    incomplete data. Recorded in the estimand-spec §3/§6 so the M3 author inherits
    it.
  - **Deferred out of M2** (kept lean, PRINCIPLES.md #14/#15/#17): lme4 as a
    *selectable* engine + bootstrap CI (this **supersedes ADR-005's** "deferred to
    M2" note — it becomes its own slice), and D-study projection to arbitrary k.
- Consequences: M2 is a thin estimand-family slice — no new engine, no new CI
  method, the fit is untouched. `icc_estimand()` gains the consistency error set
  and a `raters`/design dimension used for labeling only; `icc_point()`/`mc_ci()`
  are unchanged. New public arg `raters`; `type = "consistency"` unlocked. A new
  classed warning path and its tests. The balanced-only validity of the fixed
  layer is a documented debt for M3.
- References: PRINCIPLES.md #1, #2, #5, #8, #14, #15, #17; McGraw & Wong (1996);
  Shrout & Fleiss (1979); ten Hove et al. (2024);
  [`estimand-specs/M2-consistency-and-fixed.md`](estimand-specs/M2-consistency-and-fixed.md);
  ADR-002/003/005.

## ADR-007: M3 scope — incomplete-design statistical core; flagship vignette split out
- Date: 2026-07-06
- Status: accepted
- Context: The provisional M3 (founding brief §7 arc) bundled two large,
  loosely-coupled deliverables: (a) correct ICCs on imbalanced/incomplete
  subject×rater designs, and (b) the flagship "Choosing an ICC" teaching vignette.
  M3 also inherits the load-bearing ADR-006 debt (fixed raters must stop reusing the
  balanced-only label layer). Bundling all of this violates thin-vertical-slices
  (PRINCIPLES.md #15) and would make M3 hard to land green; and the vignette reads
  better *after* incomplete-design support exists, since its whole point is to
  demonstrate the complete-vs-incomplete decision on working code.
- Decision: **M3 is the statistical core only** — imbalanced/incomplete designs
  (random raters) plus resolving the ADR-006 fixed-raters debt via a **real
  fixed-effect fit path** (not a balanced-only guard; maintainer decision this
  session). The flagship **"Choosing an ICC" vignette becomes its own milestone
  (new M4)**; the prior M4–M6 (multilevel, optional engines, release polish)
  renumber to **M5–M7**. M3 runs as two internal CI-green slices: (1) incomplete
  random raters, (2) the fixed-effect fit path. The `ICC(*,k)` averaging-divisor
  convention under imbalance is deferred to the M3 estimand spec (to be pinned with
  citations; recommendation: project to the design's rater count, the GT D-study
  Φ(k) reading) and recorded there and in a forthcoming ADR-008.
- Consequences: M3 stays a focused, shippable statistical milestone with a clear
  Definition of Done; the teaching artifact gets its own deliberate treatment.
  Renumber touches `MILESTONES.md` only (no code depends on milestone numbers). The
  arc remains a hypothesis (MILESTONES.md preamble); this reorder is the sanctioned
  way to change it. ADR-008 will record the fixed real-fit estimand + divisor
  convention once the spec pins them.
- References: PRINCIPLES.md #14, #15, #17; `CLAUDE_CODE_KICKOFF.md` §7 (arc is a
  hypothesis, not a contract); ADR-006 (the inherited debt);
  approved plan `moonlit-mixing-pinwheel`.

## ADR-008: M3 estimands — connectedness guard, `ICC(*,k)` divisor, fixed real-fit
- Date: 2026-07-06
- Status: accepted
- Context: The M3 estimand spec must pin three things left open when incomplete data
  breaks the balanced assumptions M1/M2 relied on: how σ²_s and σ²_r stay
  identified, what the averaging divisor `k` means when subjects have unequal rating
  counts, and how `raters = "fixed"` is estimated now that the ADR-006 label-layer
  shortcut is invalid. Decisions confirmed with the maintainer this session.
- Decision:
  - **Identifiability (connectedness).** A two-way ICC is reported only on a
    **connected** subject×rater design (the observed-cell bipartite graph is a single
    component). A disconnected design aliases σ²_s with σ²_r and aborts via
    `abort_unidentified()` (PRINCIPLES.md #5). Standard estimability condition for
    crossed designs with empty cells (Searle, Casella & McCulloch 2006; Weeks &
    Williams 1964).
  - **`ICC(*,k)` divisor.** `ICC(*,1)` is always reported; for the average, use the
    **effective number of ratings `k_eff` = harmonic mean of the per-subject counts
    `n_i`** (`k_eff = 1/mean(1/n_i)`) — the standard effective-sample-size at which
    `error/k_eff` equals the average per-subject error variance, so `ICC(*,k)`
    describes the ragged averages actually computed. Reduces to `k` when complete;
    `k_eff` is surfaced in the report. Exact for consistency; an effective-`k`
    approximation for agreement (the `σ²_r` term divides by `m` only under the GT
    "average over `m` fresh raters" reading). Both candidate rules are the GT
    dependability `Φ(m)` at different `m`; **projecting to any other `m`** (the
    complete design's `n_raters`, or a reliability curve) is a distinct D-study
    *extrapolation* kept out of the plain "average" and housed in a future
    `d_study()`/`project_raters()` where the user names `m` (ROADMAP). Rationale: the
    descriptive question ("what precision did I get") stays separate from the
    inferential one, and an extrapolation to an un-run design is never reported
    silently. `k_eff`'s exact use is oracle-pinned in Slice 1 (hand calc + O5
    simulation), not assumed to match `irrNA` (PRINCIPLES.md #1). (Supersedes the
    project-to-`n_raters` default first drafted in the spec; maintainer decision.)
  - **Fixed raters get a real fit.** `raters = "fixed"` fits
    `score ~ 1 + rater + (1 | subject)` (raters as fixed effects). Consistency error
    = {σ²_res} (McGraw & Wong Case 3 / SF ICC(3,·)); absolute agreement error =
    {σ²_res, θ²_r} with θ²_r = Σ(α̂_j − ᾱ)²/(k−1), the finite-population variance of
    the k estimated rater effects (Case 3A). The MC CI samples α̂ from
    `vcov(fit, full = TRUE)` and recomputes θ²_r per draw. **θ²_r's exact
    normalization and CI propagation are asserted by oracle in Slice 2, not by the
    formula** (PRINCIPLES.md #1); if unpinnable by ≥2 oracles the coefficient is not
    shipped and a Fable review is recommended (#19). Balanced data still reduces to
    the M2 numbers (extends O4).
- Consequences: the random path is unchanged apart from the connectedness guard and
  the divisor rule; the fixed path gains its own fit, an agreement error term, and a
  CI sampler branch (keyed on `design$raters`). New oracle rows O5 (unbalanced
  simulation) and O6 (`irrNA`/incomplete) to be registered when asserted. The
  `raters` roxygen note is corrected (fixed ≠ random on incomplete data).
- References: PRINCIPLES.md #1, #2, #5, #18, #19;
  [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md);
  ADR-006 (the debt this resolves); McGraw & Wong (1996); Brennan (2001); ten Hove et
  al. (2024); Searle, Casella & McCulloch (2006); Weeks & Williams (1964).

## ADR-010: D-study projection — `d_study()` + numeric `unit` + `autoplot()` (pre-M5 slice)
- Date: 2026-07-07
- Status: accepted
- Context: D-study projection (reliability at an arbitrary rater count `m`) was
  deferred through M1–M4 and parked in ROADMAP with the exposure shape left
  explicitly open ("resolve at the milestone's start"). The maintainer scheduled it
  as its own slice **before M5 (multilevel)**. The projection is a change of the
  averaging *divisor* in the existing `(signal, {error set}, divisor)` estimand, so
  `icc_point()` already evaluated Φ at an arbitrary divisor and the Monte-Carlo CI
  already recomputed per draw — the estimator is reuse, not new machinery. Three
  shapes were on the table (numeric `unit` sugar; a downstream `d_study()` table; a
  reliability-curve plot); the surface, plot backend, and framing were confirmed with
  the maintainer this session.
- Decision:
  - **Ship all three surfaces.** Numeric `unit` in `icc()` (`unit = c("single", 3)` →
    an `ICC(A,3)` row) for one-off `m`; `d_study(x, m = 1:20)` returning an
    `icc_dstudy` tidy table for scanning a range; and `autoplot.icc_dstudy()` for the
    curve. `d_study()` **reuses the stored fit** — `icc()` now keeps the engine's
    `estimate`/`vcov`/`to_components` on the object (`x$mc`) — so projection needs no
    refit. The MC sample is drawn **once** and evaluated at every `m` (coherent curve
    + band); `mc_components()`/`mc_interval()` were factored out of `mc_ci()` to share
    that step.
  - **Divisor generalized, not special-cased.** The estimand carries a resolved
    numeric `divisor` (`resolve_divisor(unit, k_eff)`); `icc_point()` dropped its `k`
    argument. Numeric-`m` labels are `ICC(A,m)` with **no** Shrout & Fleiss form
    (`sf_label()` returns `NA` outside index "1"/"k").
  - **Fixed-rater absolute-agreement projection is refused** (`abort_unidentified`,
    PRINCIPLES.md #5): θ²_r is the finite-population variance of exactly the observed
    raters, so "average of `m` fresh raters" is undefined. Consistency (fixed or
    random) and random-rater agreement project freely. See M4.5 spec §4.
  - **Plot via ggplot2 `autoplot()`, light-install preserved.** ggplot2 is
    Suggests-only; the method is `check_installed()`-guarded and registered **lazily**
    in `zzz.R` via a vendored `s3_register()` (no vctrs/ggplot2 in Imports; robust for
    the declared R ≥ 3.5, where native `S3method(pkg::generic, class)` is not
    available). A `plot.icc_dstudy()` forwards to it.
  - **Oracle bar met (PRINCIPLES.md #1).** Closed-form Spearman–Brown (consistency)
    and GT dependability (agreement) oracles, a `psych::ICC` average-measure
    cross-check at `m = n_raters`, and a seeded simulation; provenance in
    `data-raw/oracle-d-study.R`, estimand in `estimand-specs/M4.5-d-study.md`.
- Consequences: `d_study()`/`autoplot()`/`plot()` and numeric `unit` are new public
  API (#6); `d_study` and the numeric-`unit` projection carry a `lifecycle`
  "experimental" badge. Ships on `m4.5-d-study` via PR. Cost/optimal-design helpers
  and subject-count projection stay in ROADMAP (M4.5 spec §6).
- References: PRINCIPLES.md #1, #2, #3, #5, #6, #9, #12, #14, #16; ROADMAP
  ("D-study projection"); estimand-specs `M1`/`M3`/`M4.5`; ADR-002 (light install),
  ADR-003 (MC CIs), ADR-008 (θ²_r fixed fit); Brennan (2001); McGraw & Wong (1996).

## ADR-009: M4 scope — flagship vignette + a teaching dataset; `choose_icc()` deferred
- Date: 2026-07-06
- Status: accepted
- Context: M4 was split out of M3 by ADR-007 as the flagship "Choosing an ICC"
  teaching article, to be detailed at its start after an M3 retro (founding brief
  §7). The retro confirmed the statistical core the article teaches is shipped and
  green (PR #2: incomplete designs, `k_eff`, connectedness guard, real fixed-effect
  fit), so the complete-vs-incomplete decision can now be demonstrated on working
  code. Three scope questions were open: (a) whether to also ship the exported
  `choose_icc()` decision helper (ROADMAP); (b) how the vignette obtains its example
  data (inline vs. a shipped dataset); (c) whether M4 also fills `advanced.Rmd` and
  refreshes the README. Decisions confirmed with the maintainer this session.
- Decision:
  - **Vignette-only for exported code — `choose_icc()` stays in ROADMAP.** An
    exported helper triggers the full per-estimator bar (API design, oracle/behavior
    tests, S3 methods) and would materially enlarge a documentation milestone; it
    gets its own later milestone. M4 adds **no new estimator and no new estimand
    spec.**
  - **Ship a teaching dataset** rather than building example data inline. Ship
    `ratings` (balanced Shrout & Fleiss 1979 6×4, `@source`-cited) and
    `ratings_incomplete` (a curated *connected-but-incomplete* variant of `ratings`,
    `@details` documenting the missing cells, connectedness, and `k_eff`), built by a
    deterministic `data-raw/make-ratings.R`; `LazyData: true`. Rationale: the example
    data is currently triplicated (getting-started, oracle tests, and now the
    flagship); a hand-verified incomplete design is a far cleaner teaching object than
    one assembled in prose; and `data(ratings)` lets readers and `@examples` follow
    along — fitting the package's teaching mission (brief §1). Cost acknowledged: a
    dataset is public API (#6) and adds `LazyData`, `R/data.R`, WORDLIST, and a
    pkgdown reference entry — a deliberate, bounded expansion, not scope creep. The
    dataset is used in the vignettes and `@examples`; the **oracle tests keep their
    explicit inline data** (they pin numeric values and are not perturbed for a
    refactor).
  - **Decision-tree diagram as a dependency-free static SVG** (embedded via
    `knitr::include_graphics()`), not a `DiagrammeR`/`mermaid`-rendered chunk — the
    latter adds a dependency and a build-time render step for zero teaching gain and
    fights the light-install principle. (Implementation refinement: the SVG lives at
    `vignettes/choosing-icc-tree.svg`, the canonical build-robust location for a
    vignette figure, rather than the `man/figures/` first suggested here — a path
    detail, not a change of substance.)
  - **README brought current in M4.** The README is stale (its NOTE still says M1 is
    the current milestone; the Example block is `eval = FALSE` "lands in M1"). M4
    rewrites the NOTE to actual state, makes the Example a real runnable `icc()` call
    on `data(ratings)`, links the flagship article, and rebuilds `README.md` from
    `README.Rmd`. Filling `advanced.Rmd` (incomplete/multilevel/engine sections)
    stays deferred to M5+ where multilevel and optional engines exist to demonstrate.
  - **Teaching claims are oracle-backed (PRINCIPLES still bind).** Every coefficient
    displayed is computed by `icc()` at knit time with a fixed seed (#4, #12); the
    numeric relationships the prose asserts (agreement ≤ consistency; `ICC(*,k)` ≥
    `ICC(*,1)`; fixed ≢ random on incomplete data) are asserted in
    `test-vignette-claims.R` (#1). No hand-typed reference number in the article.
- Consequences: M4 stays a focused, shippable documentation milestone with a clear
  Definition of Done, plus one bounded public-API addition (the dataset). The
  per-milestone §8 bar applies; the per-estimator bar does not (no estimator added).
  `choose_icc()` and the advanced vignette remain scheduled work in ROADMAP/M5+.
- References: PRINCIPLES.md #1, #2, #4, #6, #12, #15, #16, #17;
  `CLAUDE_CODE_KICKOFF.md` §1 (teaching mission), §7 (detail a milestone at its
  start), §8 (Definition of Done); ADR-007 (the split that created M4);
  Shrout & Fleiss (1979).
