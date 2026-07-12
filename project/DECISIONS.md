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
  glmmTMB (Brooks et al. 2017); ten Hove, Jorgensen & van der Ark (2024, *Psychological
  Methods* 29(5):967–979, updated ICC-selection guidelines) and (2025, MBR
  60(5):1042–1061, which recommends MLE-RE + Monte-Carlo CIs — see ADR-003).

## ADR-003: Monte-Carlo CIs are the default interval method
- Date: 2026-07-06
- Status: accepted
- Context: The ICC is a non-normal ratio of variance components; the delta method
  is unreliable near the zero-rater-variance boundary (the common case). The
  framework's own simulation work favors this choice: ten Hove, Jorgensen & van der
  Ark (2025, *Multivariate Behavioral Research* 60(5):1042–1061) compared MCMC of
  Bayesian hierarchical models, MLE of random-effects models, and MLE of
  common-factor models on planned-incomplete data and concluded "maximum likelihood
  estimation of random-effects models with **Monte-Carlo confidence intervals** is
  preferred based on all criteria" (abstract) — exactly this package's engine + CI
  choice.
- Decision: Default interval = **Monte-Carlo**, simulated from the fitted parameter
  covariance matrix (`vcov(fit, full = TRUE)`), on the engine's internal
  (boundary-respecting) scale, back-transformed to variance components, with the
  ICC recomputed per draw and quantiles taken. Seeded in tests (PRINCIPLES.md #12).
  The method used is always reported (PRINCIPLES.md #3). Alternative CI methods
  (bootstrap, profile) are roadmap items, not the default.
- Consequences: Intervals are boundary-aware and engine-agnostic in spirit; requires
  storing/threading a seed and the parameter covariance. Adds a stochastic element
  that must be seeded for reproducibility.
- References: PRINCIPLES.md #3, #12; `CLAUDE_CODE_KICKOFF.md` §1, §2; ten Hove,
  Jorgensen & van der Ark (2025, MBR 60(5):1042–1061, doi:10.1080/00273171.2025.2507745).

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

## ADR-011: M5 scope — multilevel ICCs (`level` API, Design-1 five-component fit)
- Date: 2026-07-07
- Status: accepted
- Context: M5 (multilevel ICCs) was the provisional "subject-level vs.
  cluster-level" one-liner in the founding arc, to be detailed at its start after
  an M4/M4.5 retro (founding brief §7). The retro confirmed the single-level
  two-way machinery (M1–M3) and the D-study divisor generalization (M4.5) are
  shipped and green, so multilevel can build on a stable estimand abstraction. The
  estimand is defined by ten Hove, Jorgensen & van der Ark (2022, *Psychological
  Methods* 27(4):650–666), whose **Table 3 / Eqs. 6–7, 12–13** decompose a
  multilevel rating into cluster-, subject-, rater-, and cluster×rater components
  and read a within- and a between-cluster IRR ICC off them. This is the **first
  estimand where the signal component changes** (subject σ²_{s:c} vs. cluster σ²_c).
  Four scope questions were open and were confirmed with the maintainer this
  session; the exact equations were pinned from the paper PDF the maintainer
  supplied (Zotero `M3BS8XJU`).
- Decision:
  - **`level` API, both levels by default.** Add a `cluster` tidy-eval selector to
    `icc()` (default `NULL` → the existing single-level path, backward-compatible)
    and a `level = c("subject", "cluster")` argument **validated and iterated
    exactly like `unit`** — defaults to returning both levels (maintainer's lean),
    a single level selectable. The result object gains a `level` column; the
    estimand list becomes the cross-product of `level × unit`. Chosen over a
    separate `micc()` function (would split the API surface, against #6) and over a
    scalar `level` (the `unit`-vector mechanism already returns multiple rows, so
    "both by default" is the natural, zero-new-pattern extension).
  - **Design 1 (raters crossed with clusters), balanced/complete, random raters.**
    M5 covers the paper's Design 1 — raters crossed with subjects *and* clusters —
    on balanced data with `raters = "random"` (the only design for which both a
    subject- and a cluster-level ICC are defined). The agreement/consistency
    (`type`) and single/average (`unit`) knobs work at both levels. Designs 2/3
    (raters nested in clusters/subjects), incomplete multilevel (reuse the M3
    `k_eff`/connectedness machinery later), and fixed-rater multilevel are deferred
    (spec §8) — thin vertical slice (#15).
  - **Scalar divisor retained; the estimand map gains a `level` key.** Correcting a
    planning-stage assumption: the paper's cluster-level ICC (Eq. 13 / Table 3)
    divides error by the scalar rater count `k` and **drops all subject-related
    variance** — it does *not* average over subjects. So **no per-component divisor
    vector is needed**; `icc_point()` / `resolve_divisor()` are untouched (and the
    M4.5 `d_study` path carries no regression risk). The only structural additions
    are (a) two components in the fit — `cluster` (σ²_c) and `cluster_rater`
    (σ²_{cr}) — via a new `(1 | cluster:rater)` random effect, and (b) a signal +
    error-set lookup keyed on `level` **and** `type` (four rows; spec §3). Both
    levels are read off **one shared five-component fit**.
  - **Oracle plan: lme4 + seeded simulation + single-level reduction.** No
    Shrout–Fleiss-style textbook worked example exists for the multilevel IRR
    estimand (as with O5), so the ≥2-independent bar (#1) is met by an lme4
    cross-engine fit of the identical five-component Design-1 model, a seeded
    simulation with known components, and a reduction check (σ²_c → 0 reproduces the
    pinned single-level numbers). `psych`/`gtheory` are not oracles here; a Bayesian/MCMC cross-check
    (ten Hove's own estimator) is deferred to the M6 engine work. Registered O-ML.
  - **Estimand equations transcribed from the paper (#1/#2/#4).** The spec §3 gives
    all four (level × type) numerators/denominators verbatim from ten Hove Table 3
    (Design 1, raters crossed), each still `signal / (signal + error / k)`. No
    equation is guessed. They remain oracle-pinned before shipping (O-ML); if any
    is unpinnable by both required oracles a Fable review is recommended and work
    pauses (#19).
- Consequences: `cluster`/`level` are new public API (#6) and a `level` column on
  the object; `icc_point()`/`resolve_divisor()` are **unchanged** (scalar divisor);
  the glmmTMB engine gains a five-component Design-1 fit (adds `(1 | cluster:rater)`)
  + extraction; new identifiability guards (spec §7). Both estimands read off one
  shared fit, so Slice 2 is largely the cluster-level map + docs. Two CI-green
  slices on `m5-multilevel`, merged via PR. Deferred items recorded in the spec and
  MILESTONES so they are not rediscovered.
- References: PRINCIPLES.md #1, #2, #3, #4, #5, #6, #14, #15, #16, #17, #19;
  [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md);
  `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start), §8; ADR-002 (engine),
  ADR-003 (MC CIs), ADR-005 (estimand representation + lme4 oracle), ADR-010
  (divisor generalization); ten Hove, Jorgensen & van der Ark (2022, Table 3);
  Brennan (2001, multivariate GT).

## ADR-012: lme4 as a selectable engine via merDeriv-backed Monte-Carlo CIs (M5.5)
- Date: 2026-07-07
- Status: accepted
- Context: ADR-005 shipped M1 with glmmTMB as the only *selectable* engine and
  lme4 **oracle-only**, deferring lme4-as-selectable (with a bootstrap CI) first
  to M2, then repeatedly (out of M2 per ADR-006 notes, out of M3). M6 (optional
  Bayesian/SEM engines) needs a real **engine × design dispatch seam** that does
  not yet exist — the engine branch in `icc()` is a hardcoded glmmTMB if/else.
  Promoting lme4 to a selectable engine first builds and proves that seam with an
  engine already trusted as the cross-check oracle (lme4 ≡ glmmTMB to ~1e-4
  everywhere), de-risking M6 rather than inventing the interface and two hard new
  engines at once. Scheduled as **M5.5** (its own slice before M6, mirroring the
  M4.5 precedent) after a short M5 retro (founding brief §7). Maintainer-approved
  this session, incl. the two open design questions below.
- Decision:
  - **`engine = "lme4"` becomes selectable for the default random two-way path.**
    `fit_lme4()` fits `lmer(score ~ 1 + (1 | subject) + (1 | rater), REML = TRUE)`
    and returns the **same six-field engine contract** as `fit_glmmtmb()`
    (`fit`/`engine`/`components`/`estimate`/`vcov`/`to_components`), so
    `icc_point()`/`mc_ci()`/`d_study()` are **unchanged** — this is a second
    engine, **not a new estimand** (no estimand-spec, cf. M4).
  - **CI via `merDeriv` (new `Suggests`), reusing the existing Monte-Carlo path**
    (open question 1, maintainer chose merDeriv over parametric bootstrap).
    merDeriv recovers the joint covariance of the variance-component parameters —
    which base lme4 does not expose (ADR-002) — so lme4 populates the MC contract
    and the `montecarlo` `ci_method` gains **no new value** this slice. The payoff
    is a **cross-engine *interval* oracle**: lme4's MC CI must match glmmTMB's to
    ~1e-2, not just the point estimate. The parametric-bootstrap `ci_method`
    (bootMer) stays deferred (M6/ROADMAP).
  - **Boundary-awareness (#3):** merDeriv reports the covariance on the
    variance/SD scale, **not** glmmTMB's internal log-SD scale that keeps MC draws
    ≥ 0. `to_components` for lme4 must map draws onto a boundary-safe (log-SD)
    scale so the near-zero-rater-variance case emits no negative-variance draws.
    Pinned by an explicit boundary oracle.
  - **Scope: random two-way path only** (open question 2, maintainer chose the
    thinnest slice, #15). `engine = "lme4"` with `raters = "fixed"` or a multilevel
    (`cluster`) design → classed `abort_unsupported()`; both `check_installed()`
    for `lme4` and `merDeriv` guard the path (light install preserved).
  - **Dispatch seam:** the hardcoded glmmTMB if/else in `icc()` becomes an
    engine × design lookup — the interface M6 extends with brms/lavaan rows.
- Consequences: resolves the ADR-005 (and ADR-006-notes) deferral. `engine`
  becomes a real choice, not a stub (`@param engine` roxygen corrected; this is an
  additive API change, not breaking, #6). Base install stays light — `lme4` and
  `merDeriv` are both `Suggests` behind `check_installed()`. Oracles O-LME:
  (a) point lme4 ≡ glmmTMB ≤ 1e-4 on SF `ratings`; (b) **interval** lme4 MC CI ≈
  glmmTMB MC CI ~1e-2 (new); (c) boundary — no negative-variance draws near zero;
  (d) seeded-sim coverage at nominal. **Discovered during implementation:** merDeriv
  cannot form the parameter covariance for a **singular fit** (a variance component
  pinned to exactly zero) — the information matrix is singular — whereas glmmTMB's
  log-SD parameterization stays finite there. `fit_lme4()` therefore detects
  `lme4::isSingular()` and raises a classed `intraclass_singular_fit` error pointing
  the user to `engine = "glmmTMB"` (#5/#8), rather than returning an unsupported
  interval. This is a narrow, well-defined engine asymmetry (glmmTMB is
  boundary-robust; the lme4+merDeriv route is not at the exact boundary), recorded
  so it is a documented limitation, not a surprise. Deferred (recorded so not
  rediscovered): lme4 for the fixed (Case 3/3A) and multilevel fits; the bootstrap
  `ci_method`; a boundary-robust lme4 interval for singular fits; merDeriv edge
  cases beyond the two-way random model. Ships on `m5.5-lme4-engine`, merged via PR.
- References: PRINCIPLES.md #1, #2, #3, #5, #6, #8, #15, #16, #17; ADR-002 (glmmTMB
  default + why lme4 needs merDeriv/bootstrap for the joint vcov), ADR-003 (MC CIs),
  ADR-005 (deferred lme4-selectable + bootstrap CI), ADR-006 (fixed-rater path),
  ADR-011 (multilevel fit); `merDeriv` (Wang & Merkle 2018, *J. Stat. Softw.*);
  lme4 (Bates et al. 2015); `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its
  start), §1 (engines).

## ADR-013: Post-M5.5 milestone reorder — one-way ICC(1) before optional engines
- Date: 2026-07-07
- Status: accepted
- Context: With M5.5 merged (lme4 selectable engine, PR #9), the maintainer asked to
  take stock of the deferred/ROADMAP backlog before starting the heavy optional-
  engine work (the milestone then numbered M6). Assessment: **nothing mandatory
  blocks that engine work** — M5.5 built the engine × design dispatch seam it
  needed, and the remaining `ci_method` generalization for posterior samples belongs
  inside it. The board header requires a DECISIONS entry for any arc reorder
  (MILESTONES.md), so this ADR records the chosen resequencing.
- Decision (both points maintainer-approved this session):
  - **Promote one-way random ICC(1)/ICC(1,k) to M6**, before optional engines. It is
    the last missing member of the classic Shrout–Fleiss family (the package ships
    ICC2/ICC3 but not ICC1), self-contained (model `score ~ 1 + (1 | subject)`, no
    rater term, no engine work), and its oracle is **already staged** in
    `sf_oracle_all` (ICC(1) = 0.166, ICC(k) = 0.443, the published SF one-way
    values). A light, well-prepared slice that completes the family before the
    engine expansion.
  - **Renumber the provisional tail** by +1: optional engines **M6 → M7**; a new
    **M8 = multilevel & incomplete-design extensions** (the paper's Designs 2/3, and
    incomplete + fixed-rater multilevel, grouped from the M5 spec §8, plus lme4 for
    the fixed/multilevel fits deferred in M5.5); release polish **M7 → M9**.
  - **Everything else stays in ROADMAP** (not milestone-numbered until scheduled):
    categorical/ordinal GLMM ratings, within-cell replicates, the conflated
    single-level ICC (Eq. 14), general `autoplot()`/CI plots, `choose_icc()`, the
    benchmark suite, bootstrap/profile CIs, and the D-study cost/two-facet/
    subject-count extensions.
- Consequences: M6 becomes a small statistical slice with a staged oracle; optional
  engines (the differentiator) move one slot later but keep all their gathered
  references (M7). Future milestones stay **provisional one-liners**, detailed at
  their start after a short retro (#2, brief §7) — this ADR schedules, it does not
  pre-design them. No code or API change; a planning/tracking-only reorg.
- References: PRINCIPLES.md #2 (name the estimand first), #14 (milestone gates),
  #15 (thin slices), #17 (no scope creep); MILESTONES.md (arc-reorder rule);
  ROADMAP.md (parking lot); ADR-005/ADR-012 (engine deferrals); Shrout & Fleiss
  (1979) one-way ICC1/ICC1k (0.166/0.443); `CLAUDE_CODE_KICKOFF.md` §7.

## ADR-014: M7 scope — SEM (lavaan) as an optional engine, two-way random
- Date: 2026-07-07
- Status: accepted
- Context: M7 was the provisional "optional engines (Bayesian brms/rstanarm, SEM
  lavaan)" one-liner in the ADR-013 arc, to be detailed at its start after an M6
  retro (brief §7). The retro confirmed M6 landed green in one slice and that the
  M5.5 engine × design dispatch seam absorbed a *new fitted model* (one-way)
  cleanly, so the seam is ready to take *new engines*. Two scope questions were open
  and confirmed with the maintainer this session: which engine leads, and how wide
  the first slice's design coverage is. As in M5.5 (ADR-012), an alternative engine
  for an existing estimand is **not** a new estimand — **no estimand-spec** (cf. M4).
- Decision:
  - **Lead engine = SEM via `lavaan`** (maintainer choice over the Bayesian
    brms/rstanarm options), mirroring the successful M5.5 pattern: (1) it **reuses
    the existing Monte-Carlo CI path** — lavaan exposes `vcov(fit)` (the joint
    covariance of the estimated model parameters), so MC draws recompute the ICC per
    draw with **no new `ci_method`**, exactly as merDeriv let lme4 reuse
    `montecarlo`; (2) **light install, no Stan compilation** — lavaan is a single new
    `Suggests` needing no C++ toolchain, so the CI matrix (incl. Windows) stays fast
    and green, unlike brms; (3) **it can be pinned to a textbook oracle** — Jorgensen
    (2021, *Psych* 3:113–133) gives a worked GT-via-SEM example defining
    absolute-error components via mean-structure constraints, meeting the PRINCIPLES
    #1 textbook bar, and that paper **independently argues for Monte-Carlo CIs**,
    corroborating ADR-003. The Bayesian engine's looser oracle bar (a posterior
    summary ≈ REML only within prior/MCMC error, not 1e-4) and Stan install weight
    make it the heavier, later slice.
  - **Design scope = two-way random only** (planning said "+ one-way"; one-way was
    **deferred during implementation** — see the note below). The lavaan engine
    supports `model = "twoway"` (agreement + consistency × single/average); numeric
    `unit` (D-study) is inherited for free via `resolve_divisor()`. `model = "oneway"`,
    `raters = "fixed"`, multilevel (`cluster`), and **incomplete/unbalanced** designs
    → classed `abort_unsupported()` for lavaan, deferred and recorded (SEM handles
    missing via FIML, but that is its own slice). Same as M5.5's twoway-only scope,
    excluding the fixed real-fit and multilevel fits (#15).
  - **SEM parameterization (to be oracle-pinned, not assumed).** lavaan wants **wide
    data** (one row per subject, columns = raters), so `fit_lavaan()` reshapes the
    long `icc()` data to wide and fits a one-factor model where the subject factor
    loads on the rater-indicators; **consistency** reads σ²_s / (σ²_s + σ²_res) off
    the factor and residual variances (a ratio → equals the mixed-model estimate
    **exactly** on balanced data); **absolute agreement** recovers the rater variance
    from the **mean structure** as σ²_r = Σν²/(k−1), the sample variance of the
    effects-coded indicator intercepts (Jorgensen 2021, Eq. 6). The engine returns the
    **same six-field contract** (`fit`/`engine`/`components`/`estimate`/`vcov`/
    `to_components`) as glmmTMB/lme4, so `icc_point()`/`mc_ci()`/`d_study()` are
    unchanged. The claim that this SEM parameterization returns the *same* variance
    components is **asserted by oracle** (below), not by the formula (#1); any
    component unpinnable by ≥2 oracles is not shipped and a Fable review is
    recommended, then work pauses (#19).
  - **Boundary-awareness (#3) is a named risk.** lavaan estimates variances on the
    **raw scale** (they can go negative — Heywood cases), unlike glmmTMB's
    boundary-safe log-SD scale. `to_components` for lavaan must keep MC draws valid at
    the near-zero-variance boundary (constrain variances ≥ 0 in the fit and/or handle
    the draw scale), pinned by an explicit boundary oracle — the direct analog of the
    ADR-012 merDeriv-scale problem. A Heywood/singular fit that cannot yield a valid
    interval aborts loudly (classed), directing the user to `engine = "glmmTMB"`.
  - **Oracles O-SEM — split by type, because agreement is a *different estimator***
    (corrected during implementation; see the note below). **Consistency** is pinned
    exactly: (a) lavaan ≡ glmmTMB ≤1e-4 on balanced `ratings` (0.7148/0.9093), and
    (b) `psych::ICC` ICC3/ICC3k — the ratio is estimator-invariant. **Absolute
    agreement** uses the SEM indicator-mean estimator (Jorgensen Eq. 6), which is
    **asymptotically equivalent** to the mixed-model random-effect variance but
    differs by an O(1/n_subjects) small-sample term (on the 6-subject SF data,
    ICC(A,1) = 0.284 vs the mixed-model 0.290 — **not** forced to 0.290). It is
    pinned by (a) the **exact Σν²/(k−1) formula** reproduced independently in-test;
    (b) a **large-N seeded simulation** where lavaan → the known population and
    lavaan ≈ glmmTMB (their asymptotic agreement); (c) **external validation** —
    Vispoel, Hong, Lee & Xu (2022) show the SEM indicator-mean method matches
    GENOVA / `gtheory` / SAS / SPSS to ≤ .001 (G-coef) / ≤ .005 (D-coef) across 24
    real scales. Interval: the MC CI on bounds is checked against glmmTMB's *fixed*
    interval for agreement (the SEM treats raters as a finite set of intercepts) and
    glmmTMB's *random* interval for consistency, on an **absolute** gap (M5.5 Windows
    lesson). Provenance in `data-raw/oracle-sem.R`; O-SEM row in REFERENCES when
    asserted.
  - **Dispatch:** the M5.5 engine × design lookup gains lavaan rows for
    `{twoway} × random`; every other cell aborts `abort_unsupported()`.
    `check_installed("lavaan")` guards the path (light install preserved; lavaan →
    `Suggests`, **no companion package** since lavaan exposes `vcov()` natively —
    lighter than the lme4 + merDeriv pair).
  - **Bayesian engine deferred out of M7's first pass** (recorded so not
    rediscovered): the Bayesian backend (**rstanarm** preferred over brms for
    CI-install sanity — precompiled Stan, no toolchain) with a new
    `ci_method = "posterior"` (credible intervals from native draws) and half-*t*
    hyperpriors (ten Hove, Jorgensen & van der Ark 2020), scheduled as a **later
    slice of M7 or its own follow-on milestone** after the SEM slice lands. Also
    deferred: incomplete/unbalanced SEM (FIML); fixed-rater and multilevel SEM;
    **one-way random via SEM** (deferred during implementation — see below).
- **One-way lavaan deferred during implementation (scope narrowed from planning).**
  The plan (and the maintainer's Q2) said "two-way + one-way random." Implementation
  found no faithful, sourced SEM route for the one-way ICC(1): the SEM-GT literature
  (Jorgensen 2021; Vispoel et al. 2022; Lee & Vispoel 2024) covers **crossed** facet
  designs (p×i, p×i×o) → G-coef (consistency) and D-coef (absolute), and does **not**
  derive a one-way random ICC(1). A wide-column parallel model computes covariances
  around each column's mean (→ *consistency*, 0.715, not one-way); an equal-intercept
  parallel model approximates it but is **unsourced and inexact** (0.157 vs the ANOVA
  0.166 on SF); the only faithful route (a multilevel/random-intercept SEM on long
  data) would merely **re-implement the mixed model** with no added value. Rather than
  ship an unsourced approximation (the same trap as the removed bias term), one-way
  lavaan → `abort_unsupported()` and is **parked in ROADMAP**. Consequence: M7's lavaan
  engine is **two-way random only**, so Slice 1 is the whole estimator and Slice 2 is
  **docs only** (no new estimator). Maintainer-approved this session.
- **Corrected during implementation (Slice 1, after reading the primary sources).**
  The planning premise — "lavaan reproduces the SF values 0.290/0.620/0.715/0.909,
  agreement ≤1e-3" — was **only right for consistency**. Reading Jorgensen (2021,
  Eq. 6) and Lee & Vispoel (2024, Eqs. 8/25) established that the SEM absolute-error
  component is the **raw** variance of the indicator intercepts, Σν²/(k−1), with
  **no bias correction** (the "Robust" in Lee & Vispoel's title is an ordinal
  scale-coarseness correction, unrelated). This is a genuinely **different
  estimator** of σ²_r than the mixed model's random-effect variance — it omits the
  ANOVA "− σ²_res/n" term — so lavaan agreement ≠ glmmTMB agreement on small n
  (0.284 vs 0.290 on SF). An earlier draft of `fit_lavaan()` "corrected" the gap
  with an **unsourced** bias term (built by analogy to `fit_glmmtmb_fixed`); that
  violated #1/#4 (a formula that "looks right") and was **removed**. The faithful
  method is validated: Vispoel et al. (2022) show it matches conventional GT
  software to ≤ .005 on real large-N data. The oracle plan above was rewritten to
  match (consistency exact; agreement = the SEM estimator, oracled by formula +
  large-N convergence + the Vispoel external check). Process lesson recorded: when
  a primary source is inaccessible, obtain it before coding the method rather than
  inferring it (the source PDFs, blocked by the publisher, were supplied by the
  maintainer and reversed the plan).
- Consequences: M7 ships the **SEM/lavaan engine** for the **two-way random** path —
  Slice 1 the estimator (congeneric/mean-structure), Slice 2 docs only (one-way
  deferred) — extending the dispatch seam, adding lavaan to
  `Suggests`, and a `data-raw/oracle-sem.R`. `engine` gains a third value (additive,
  not breaking, #6; `@param engine` roxygen updated). No estimand-spec (engine, not
  estimand). Because SEM absolute agreement is a distinct (asymptotically
  equivalent) estimator, engine choice changes the small-sample agreement number —
  a documented, cited property, surfaced in `@param engine` and the Slice 2
  vignette note. The Bayesian engine and the wider designs stay deferred and
  recorded. Ships on `m7-sem-engine`, merged via PR; full CI matrix on the PR.
- References: PRINCIPLES.md #1, #2, #3, #5, #6, #8, #12, #15, #16, #17, #19; ADR-002
  (glmmTMB default + why an alternative engine needs its own vcov route), ADR-003 (MC
  CIs — corroborated by Jorgensen 2021), ADR-012 (the engine × design seam + the
  reuse-the-MC-path pattern this follows), ADR-013 (the arc that scheduled M7);
  Jorgensen (2021, *Psych* 3(2):113–133, doi:10.3390/psych3020011 — the SEM
  absolute-error method, Eq. 6); Vispoel, W. P., Hong, H., Lee, H., & Xu, G. (2022,
  "Accuracy of Absolute Error Estimates within a G-theory SEM Framework," NCME
  conference paper — validates the SEM method against GENOVA/`gtheory`/SAS/SPSS);
  Lee, H., & Vispoel, W. P. (2024, *Psych* 6(1):401–425, doi:10.3390/psych6010024 —
  confirms the raw indicator-mean formula; "Robust" = ordinal scale-coarseness);
  lavaan (Rosseel 2012, *J. Stat. Softw.* 48(2)); ten Hove, Jorgensen & van der Ark
  (2020, hyperprior guidance — for the deferred Bayesian slice);
  `CLAUDE_CODE_KICKOFF.md` §1 (optional engines in Suggests), §7 (detail a milestone
  at its start), §8.

## ADR-015: Consolidate the tracking system — single-source each fact
- Date: 2026-07-07
- Status: accepted
- Context: A tracking audit this session found `REFERENCES.md` two milestones behind
  (oracle O-ML still "planned" after M5 shipped) and `MILESTONES.md` / `ROADMAP.md`
  carrying forward-looking language ("provisional", "the next milestone", "deferred to
  M6") left stale by milestone ships and the ADR-013 renumber. The root cause was
  **not** the number of tracking files (the brief's seven) but **denormalization**:
  the same fact (a milestone's done-state, an oracle's asserted-state) was restated in
  several files, so updating one copy left the others stale. The maintainer asked
  whether consolidating would help — consolidation helps only insofar as it removes
  duplicated facts.
- Decision: **Single-source each fact; other files link rather than restate.** This is
  the primary defense against tracking lapse (the `finish-task` forward-reference sweep
  is the backstop).
  - **One home per fact.** Milestone plan + done/in-progress/provisional status →
    `MILESTONES.md`. Active task / next action / last-green-CI / blockers →
    `STATUS.md` (a volatile *pointer*, not a history). Decisions → `DECISIONS.md`
    (append-only). An oracle's asserted-state → its **test file** (the truth), named by
    `REFERENCES.md`. Future/unscheduled ideas → `ROADMAP.md`. Principles →
    `PRINCIPLES.md`. Bibliography + oracle registry → `REFERENCES.md`.
  - **Merge `TASKS.md` into `MILESTONES.md`.** The active milestone's DoD checklist
    *is* the task board (the brief's "one owner-agent each" rationale is moot — we run
    solo). `TASKS.md` is deleted; `STATUS.md` names the active task. Removes the
    biggest checklist duplication and the "condense the board to one line" step that
    just echoed the `MILESTONES` status.
  - **`ROADMAP.md` is future-only.** The "Resolved" section (which re-narrated shipped
    milestones and lapsed twice today) is deleted; a scheduled item moves to
    `MILESTONES.md`, and once shipped its ROADMAP entry is **removed**, not kept as a
    stale echo.
  - **`STATUS.md` stops restating history.** Its "Where we are" enumeration of shipped
    milestones becomes a one-line pointer to `MILESTONES.md`.
  - **`REFERENCES.md` carries no independent planned/asserted lifecycle.** An oracle is
    registered when asserted; its status line names the test file (grep-verifiable). A
    not-yet-asserted oracle lives in its estimand-spec, not here — so there is no
    "planned" state in REFERENCES to lapse.
  - **Skills updated** (`status`, `start-task`, `finish-task`, `new-estimator`,
    `verify-estimator`) to read/write the new homes and to state the one-home rule.
- Consequences: seven tracking files → six (`TASKS.md` gone). Amends the brief's (§4)
  seven-file layout; the brief stays a founding record (not rewritten, like an ADR).
  Historical done-milestone DoD text mentioning "MILESTONES/STATUS/TASKS same-commit"
  is left as an accurate record of what happened at that commit. Lower lapse surface:
  fewer copies of each fact, so fewer places to forget. Touches only `project/`,
  `.claude/`, and `CLAUDE.md` (no CI-gated path) → direct commit to `main`.
- References: PRINCIPLES.md #6 (small, deliberate surface), #16 (tracking current in
  the same commit); `CLAUDE_CODE_KICKOFF.md` §4 (the seven-file design this amends);
  ADR-013 (the renumber whose fallout exposed the duplication); this session's audit
  (REFERENCES O-ML lapse; MILESTONES/ROADMAP renumber staleness).

## ADR-016: M8 scope — nested-rater multilevel ICCs (Designs 2/3), thin first pass
- Date: 2026-07-07
- Status: accepted
- Context: M8 was the provisional "multilevel & incomplete-design extensions"
  one-liner grouped by ADR-013 from the M5 spec §8 deferrals — the paper's **Designs
  2/3** (raters nested in clusters and/or subjects), incomplete multilevel,
  fixed-rater multilevel, and lme4 for the fixed/multilevel fits (deferred out of
  M5.5, ADR-012). Detailed at its start after a short M7 retro (brief §7). The retro
  confirmed M7 (SEM/lavaan engine, PR #11) landed green and that the M5.5 engine ×
  design seam is stable; its load-bearing lesson — a primary source reversed the plan
  mid-implementation, so obtain and read it *before* coding a method (#1/#4;
  `ask-for-inaccessible-sources` memory) — carries directly into M8, whose estimands
  are transcribed from a paper. Two scope questions (breadth; where lme4 parity goes)
  were resolved with the maintainer this session.
- Decision (maintainer-approved this session):
  - **M8 = the paper's Designs 2/3 only** — raters nested in clusters (Design 2)
    and/or subjects (Design 3) — **balanced/complete, random raters.** The direct
    analog of M5's Design-1 thin scope (#15): ship the novel nested-rater estimand
    from the paper already in hand, and record the rest. Chosen over bundling
    incomplete-ML and fixed-ML into the same milestone, which would multiply the
    fit-and-oracle surface ({D1,D2,D3} × {complete,incomplete} × {random,fixed})
    before the base nested estimands are trusted.
  - **Internal slices mirror M5:** Slice 1 = Design 2, Slice 2 = Design 3, Slice 3 =
    docs. Each estimand transcribed **verbatim** from ten Hove, Jorgensen & van der
    Ark (2022, Eqs. 8–11, Table 3 middle/right) at spec time and pinned by ≥2 oracles
    before shipping (#1/#2). The **model formulas are our translation** of the paper's
    decomposition, **oracle-pinned not assumed** (the paper fits in Stan; same posture
    as M5, spec §2).
  - **Estimand-spec required** (unlike the M5.5/M7 *engine* milestones): M8 changes
    the fitted model and the signal/error map, so it gets
    `estimand-specs/M8-nested-multilevel.md`. Its equation sections are **held pending
    the paper PDF** (below).
  - **Level coverage confirmed from the paper, not asserted.** The M5 spec notes only
    Design 1 defines *both* a subject- and a cluster-level IRR; nested-rater designs
    plausibly define **subject-level IRR only**. The exact levels available per design
    are read off the paper's Table 3 at spec time, not fixed here.
    **Resolved from the paper (this session, PDF supplied):** M8 is **subject-level
    only** — cluster-level IRR needs μ_cr, so the paper restricts it to Design 1 and
    states "Designs 2 and 3 are not interesting" at the cluster level (M5 already ships
    Design-1 cluster level). Further, **Design 3 is agreement-only** — the rater
    variance is confounded into residual (Eq. 11), so only ICC_s(A,1)/ICC_s(A,k) exist
    (the Table 3 consistency cells are "—"). Design 2 keeps agreement + consistency
    (σ²_r → σ²_{r:c}; σ²_{(s:c)r} → σ²_{(sr):c}). So M8's shipped estimand set is: Design
    2 {agreement, consistency} × {single, average} + Design 3 {agreement} × {single,
    average} = **six subject-level coefficients**. Detail + Table 3 transcription in
    [`estimand-specs/M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md).
  - **Oracles: the M5 O-ML pattern** — lme4 cross-engine (identical nested model, all
    point families ≤1e-4), a seeded population-recovery simulation with known
    components, and a reduction check (a nested design collapses to a shipped estimand
    when the nesting variance → 0). No Shrout–Fleiss-style textbook worked example
    exists (as with O5/O-ML). A Bayesian/MCMC cross-check against the paper's own Stan
    estimator remains a *future* third oracle.
  - **Deferred out of M8 (recorded so not rediscovered):** incomplete multilevel
    (reuse M3 `k_eff`/connectedness); fixed-rater multilevel (reuse the M3 real
    fixed-effect fit path, ADR-008); **lme4 for the fixed (Case 3/3A) and multilevel
    fits — its own later slice** (maintainer's call this session: engine parity, not
    multilevel estimand work; glmmTMB already covers these paths, ADR-012); the
    Bayesian/MCMC cross-engine; a three-facet `d_study()` over subject-per-cluster
    counts; exposing the conflated single-level ICC (Eq. 14).
- Consequences: M8 stays a focused, shippable multilevel-estimand milestone with a
  clear DoD; the differentiator (nested-rater multilevel IRR, rare in software) ships
  first, the combinatorial variants follow as their own slices. The `cluster`/`level`
  API and the five-component fit from M5 (ADR-011) are **extended, not redesigned**;
  no new engine, no new `ci_method`. New public estimands → estimand-spec + the
  per-estimator oracle bar (#1). The spec's equation transcription is **blocked on
  obtaining the ten Hove et al. 2022 PDF** (cited for M5 but not committed) — per the
  M7 lesson, the formulas will not be reconstructed from memory; if any Design 2/3
  coefficient cannot be pinned by ≥2 oracles it is not shipped and a Fable review is
  recommended, then work pauses (#19). Ships on `m8-nested-multilevel`, merged via PR.
  Future variants stay provisional one-liners, detailed at their start (#2).
- References: PRINCIPLES.md #1, #2, #4, #5, #14, #15, #16, #17, #19;
  `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start), §8; ADR-011 (M5
  multilevel — Design 1, the fit and `level` API this extends), ADR-008 (M3
  `k_eff`/connectedness + fixed real-fit, reused by the deferred variants), ADR-012
  (lme4 engine + the deferred parity), ADR-013 (the arc that grouped M8);
  [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md) §8 (the
  deferrals this schedules); ten Hove, Jorgensen & van der Ark (2022, Designs 2/3,
  Eqs. 8–11, Table 3); the `ask-for-inaccessible-sources` memory (M7 process lesson).

## ADR-017: Post-M8 milestone reorder — four deferrals scheduled before release polish
- Date: 2026-07-07
- Status: accepted
- Context: With M8 merged (nested-rater multilevel Designs 2/3, PR #12), the
  maintainer took stock before starting release polish (the milestone then numbered
  M9). Nothing earlier is unfinished or broken — M0–M8 are all merged green and every
  deferral is recorded in a "Deferred out of M<n>" list — so the question was purely
  the **first-release cut line**: which recorded deferrals ship before a CRAN
  submission vs. post-CRAN. The maintainer is **not rushing CRAN** and judged two
  recorded items **important-missing** for a credible first release: **incomplete/
  unbalanced multilevel** (deferred out of M5 and M8) and **general `autoplot()`/
  ggplot2 methods** (ROADMAP; only the M4.5 `d_study()` reliability curve shipped).
  Two further deferrals were folded in as natural pairs: **fixed-rater multilevel**
  (deferred out of M5/M8; pairs with incomplete-ML as multilevel completion) and the
  **`choose_icc()` decision helper** (deferred out of M4; pairs with the autoplot
  teaching/viz layer). The board header requires a DECISIONS entry for any arc
  reorder (MILESTONES.md), so this ADR records the resequencing. Supersedes the M9
  slot as fixed by ADR-013.
- Decision (maintainer-approved this session, 2026-07-07):
  - **Promote four recorded deferrals ahead of release polish, estimator work first:**
    - **M9 = incomplete / unbalanced multilevel ICCs** — ragged subject×rater
      multilevel designs; reuse the M3 `k_eff`/connectedness machinery (ADR-008) on
      the M5/M8 multilevel fit. Estimator work; estimand-spec required.
    - **M10 = fixed-rater multilevel ICCs** — reuse the M3 real fixed-effect fit path
      (ADR-008) on the multilevel fit. Estimator work; estimand-spec required.
    - **M11 = general `autoplot()` / ggplot2 variance-component + CI methods** — no
      new estimand (viz over shipped estimators); lands after all estimators so it
      covers the full set.
    - **M12 = `choose_icc()` interactive decision helper** — mirrors the M4 flagship
      vignette; teaching/API, no new estimand.
  - **Release polish (pkgdown, advanced vignette, CRAN prep) renumbers M9 → M13.**
  - **Ordering rationale:** incomplete-ML first (maintainer choice) while the M8
    multilevel code is fresh; fixed-rater-ML adjacent as the multilevel-completion
    pair; the teaching/viz layer (autoplot, then `choose_icc()`) after all estimators
    exist so both cover the full estimator set; the advanced vignette (M13) can then
    show the new plots and helper. **lme4 for the fixed/multilevel fits** (engine
    parity, deferred out of M5.5/M8, ADR-012) stays in the deferral list — engine
    work, not blocking; glmmTMB already covers these paths.
  - **Everything else stays in ROADMAP** (not milestone-numbered until scheduled):
    the Bayesian engine + `ci_method = "posterior"`, one-way-via-SEM, within-cell
    replicates, the conflated single-level ICC (Eq. 14), categorical/ordinal GLMM
    ratings, the benchmark suite, bootstrap/profile CIs, and the D-study cost/
    two-facet/subject-count extensions.
- Consequences: the multilevel family completes (Designs 1–3 × {complete,incomplete}
  × {random,fixed}) and the package gains a general plotting layer and a decision
  helper before its first release — a stronger, more coherent v1 at the cost of four
  milestones before polish. Future milestones stay **provisional one-liners**,
  detailed at their start after a short retro (#2, brief §7) — this ADR schedules, it
  does not pre-design them. No code or API change lands from this ADR; a planning/
  tracking-only reorg.
- References: PRINCIPLES.md #2 (name the estimand first), #14 (milestone gates), #15
  (thin slices), #17 (no scope creep); MILESTONES.md (arc-reorder rule); ROADMAP.md
  (parking lot); ADR-008 (M3 `k_eff`/connectedness + real fixed-effect fit, reused by
  M9/M10), ADR-011 (M5 multilevel fit + `level` API), ADR-012 (lme4 fixed/multilevel
  parity, stays deferred), ADR-013 (the prior post-M5.5 reorder this supersedes for
  the M9 slot), ADR-016 (M8, which recorded these deferrals);
  [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md) §8 and
  [`estimand-specs/M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md)
  (the deferrals this schedules); `CLAUDE_CODE_KICKOFF.md` §7.

## ADR-018: M9 scope — incomplete/unbalanced multilevel ICCs, crossed (Design 1) first
- Date: 2026-07-07
- Status: accepted
- Context: M9 was scheduled by ADR-017 as "incomplete / unbalanced multilevel ICCs,"
  promoted ahead of release polish. Detailed at its start after a short M8 retro
  (brief §7). The retro's load-bearing finding: M9 is the **intersection of two
  shipped machineries** — the M5/M8 multilevel fit (`estimand-specs/M5-multilevel.md`,
  ADR-011) and the M3 incompleteness handling (connectedness + `k_eff`,
  `estimand-specs/M3-incomplete-designs.md`, ADR-008) — and it introduces **no new
  estimand** (like M3 relative to M1/M2). It surfaced one genuinely new risk, visible
  in `R/design.R::detect_multilevel_design()`: that function reads a rater confined to
  one cluster as *nested*, so a ragged **crossed** (Design 1) design whose raters each
  happened to land in one cluster would be **silently misclassified as nested**,
  switching the estimand (crossed separates σ²_r and σ²_cr; nesting confounds them into
  σ²_{r:c}) — a #5 hazard. Two scope questions were put to the maintainer this session.
- Decision (maintainer-approved this session, 2026-07-07):
  - **M9 = incomplete/ragged Design 1 (raters crossed with clusters) only.** Incomplete
    **nested** designs (Designs 2/3) are deferred to their own later slice — resolve the
    ragged nested-vs-crossed inference for the crossed base first, mirroring the
    M5(D1) → M8(D2/3) thin-slice progression (#15). Random raters, glmmTMB engine
    (lme4 oracle), both subject- and cluster-level IRR as M5 ships (each identifiability-
    gated).
  - **Ambiguous ragged designs are declared, not guessed.** When a missing-cell pattern
    is consistent with more than one multilevel design (the partial-crossing case M8
    currently aborts as "mixed"), `icc()` gains an **optional `design` argument** (name
    finalized in Slice 1) by which the user asserts the intended design; silent inference
    is kept only for the **unambiguous** patterns (every rater spans ≥2 clusters ⇒
    crossed; every rater confined ⇒ nested). Ambiguous + undeclared → `abort_unidentified()`
    naming the argument. The argument is **validated against the data**, never used to
    override a structural impossibility (asserting "crossed" when no rater bridges
    clusters still aborts on the confounded σ²_r/σ²_cr). Preserves #5/#2 (never silently
    switch the estimand) while keeping the API minimal (#6 — the argument surfaces only
    for the genuinely ambiguous ragged case).
  - **The multilevel identifiability condition (§4) and the multilevel `k_eff` (§5) are
    oracle-pinned, not asserted (#1/#18).** The connectedness rule is materially more
    layered than M3's single bipartite graph — within-cluster subject×rater connectedness
    (σ²_{s:c} vs σ²_res) *and* a cluster×rater bridging condition (σ²_r vs σ²_cr) — and is
    the spec's hypothesis, corrected against where lme4/glmmTMB actually loses rank before
    the guard ships; an unresolved case triggers a *recommended* Fable review (#19).
- Consequences: M9 reuses the M3 `design_connected()`/`k_eff` and the M5 five-component
  fit rather than adding new estimand or CI machinery; the entry point is removing the
  `nested_design_balanced()` abort for the crossed case only. The optional `design`
  argument is a **public-API addition** (hence this ADR, #6) but is inert on complete or
  unambiguous data. Incomplete nested + fixed-rater multilevel stay deferred (the latter
  is M10, ADR-017). No estimand changes: every M9 coefficient is the M5 Design-1 estimand
  estimated on ragged data.
- References: PRINCIPLES.md #1 (oracle-first), #2 (name the estimand), #5 (fail loudly),
  #6 (small/considered API), #15 (thin slices), #18 (state what's inherited vs. new),
  #19 (Fable gating); ADR-008 (M3 `k_eff`/connectedness, reused), ADR-011 (M5 multilevel
  fit + `level` API, inherited), ADR-016 (M8 nested designs + the design-inference seam),
  ADR-017 (the arc that scheduled M9); [`estimand-specs/M9-incomplete-multilevel.md`](estimand-specs/M9-incomplete-multilevel.md)
  (the full spec); [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md) §3
  (the inherited estimands); [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md)
  §3/§5 (the reused machinery); ten Hove et al. (2022 Design 1; 2024 incomplete-design
  guidelines); Searle, Casella & McCulloch (2006); Weeks & Williams (1964).

## ADR-019: M10 scope — fixed-rater multilevel ICCs, crossed (Design 1) balanced, subject level
- Date: 2026-07-07
- Status: accepted
- Context: M10 was scheduled by ADR-017 as "fixed-rater multilevel ICCs," the
  multilevel-completion pair with M9. Detailed at its start after a short M9 retro
  (brief §7). The retro's load-bearing lesson: **verify against the installed package,
  not just `devtools::load_all`** (a stale load_all state masked a guard failure that
  turned all six M9 R-CMD-check jobs red — the `verify-against-installed-package`
  memory), and do not snapshot multilevel-fit prints (platform-fragile MC-CI). Like M9,
  M10 is an **intersection of two shipped machineries** — the M3 real fixed-effect fit
  with the bias-corrected finite-population θ²_r (`estimand-specs/M3-incomplete-designs.md`
  §6, ADR-008; McGraw & Wong 1996 Case 3A) and the M5 Design-1 multilevel fit
  (ADR-011) — and introduces **no new estimand concept**: the rater slot carries θ²_r
  instead of the random σ²_r, everything else in the subject-level decomposition is M5's.
  Two scope questions were put to the maintainer this session.
- Decision (maintainer-approved this session, 2026-07-07):
  - **M10 = fixed-rater crossed (Design 1), balanced/complete, subject level only.**
    The M5-analog thin scope for a genuinely **new fitted model** (raters move from a
    random intercept to fixed effects: `score ~ 1 + rater + (1|cluster) +
    (1|cluster:subject) + (1|cluster:rater)`, θ²_r in the `rater` component slot). The
    cluster×rater interaction stays **random** (random-cluster × fixed-rater, standard
    convention). glmmTMB engine, lme4 cross-engine oracle.
  - **Fixed + incomplete, fixed + nested, the fixed cluster level, and lme4 for the
    fixed/multilevel fits are deferred** (spec §7) — each a further combination whose
    bias/divisor interactions need their own oracles; mirrors the M5 → M9 staging.
  - **The estimand is oracle-pinned, not asserted (#1/#18).** There is no textbook
    worked example for fixed-rater multilevel (the paper is a random-effects
    framework); the fit is validated by its **reduction to the pinned M5 (balanced
    fixed ≡ random — the M2 O4 equivalence lifted to the multilevel fit) and M3
    (single-cluster) estimands**, plus an lme4 cross-engine fit and a seeded-sim
    recovery, before it ships. An unresolved case triggers a *recommended* Fable
    review (#19).
- Consequences: M10 reuses M3's θ²_r machinery and the M3 fixed-rater MC sampler, and
  the M5 subject-level estimand map and `icc_point()` — the only new code is the
  fixed-rater multilevel fit and its routing (lifting the `raters = "fixed"` +
  multilevel abort). Consistency is identical to the random-rater case; absolute
  agreement differs only by θ²_r vs σ²_r (zero on balanced data), so the primary oracle
  is a clean reduction. No estimand-concept change: the subject-level coefficients are
  the M5 estimand with a finite-population rater term.
- References: PRINCIPLES.md #1 (oracle-first), #2 (name the estimand), #5 (fail
  loudly), #15 (thin slices), #18 (state what's inherited vs. new), #19 (Fable gating);
  ADR-008 (M3 real fixed-effect fit + θ²_r, reused), ADR-011 (M5 multilevel fit + level
  API, inherited), ADR-006 (the fixed-vs-random balanced equivalence, O4), ADR-017 (the
  arc that scheduled M10); [`estimand-specs/M10-fixed-multilevel.md`](estimand-specs/M10-fixed-multilevel.md)
  (the full spec); [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md)
  §6 and [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md) §3 (the
  reused machinery); McGraw & Wong (1996 Case 3A); ten Hove et al. (2022 Design 1);
  the `verify-against-installed-package` memory (M9 process lesson).

## ADR-020: M11 scope — general `autoplot()` / `plot()` methods for `icc` objects
- Date: 2026-07-07
- Status: accepted
- Context: M11 was scheduled by ADR-017 as "general `autoplot()` / ggplot2 methods,"
  detailed at its start after a short M10 retro (brief §7). The M10 retro's lesson was
  a clean one — the milestone was pure reuse (θ²_r into the M5 decomposition), oracle-
  first caught the single-cluster θ²_r degeneracy *before* code, and it was documented
  rather than shipped as a silent artifact. M11 is a **change of pace from estimator
  work**: a visualization layer over the already-shipped coefficients. It introduces
  **no new estimand, no new fit, no new CI machinery, and no new dependency** — ggplot2
  is already a `Suggests`, and the M4.5 `autoplot.icc_dstudy()` reliability curve
  (ADR-010) already established the lazy-`s3_register()` light-install pattern in
  `zzz.R`. M11 generalizes plotting from the derived `icc_dstudy` object to the `icc`
  object itself. Two facts shaped scope: (a) an `icc` object exposes exactly two things
  worth plotting — `$estimates` (index/level/estimate/conf.low/conf.high) and
  `$components` (the variance decomposition); (b) the existing `autoplot.icc_dstudy` has
  **zero tests**, so M11 also sets the testing pattern for plot methods here. Two scope
  questions were put to the maintainer this session.
- Decision (maintainer-approved this session, 2026-07-07):
  - **M11 ships both plots behind one `what` argument.** `autoplot.icc(object, what =
    c("coefficients", "components"), ...)` (`match.arg`, default `"coefficients"`):
    - `"coefficients"` — a **coefficient forest plot**, one row per estimated index
      (faceted / grouped by `level` for multilevel objects), point estimate with a
      Monte-Carlo CI band. The direct generalization of the shipped reliability curve;
      works across the full estimator set (single/average, agreement/consistency, one-
      way, multilevel subject+cluster levels).
    - `"components"` — a **variance-component decomposition** bar (subject / rater /
      residual, plus cluster and cluster:rater for multilevel; honouring the design
      variants already handled by `format.icc` — one-way's confounded rater, Design 2's
      `rater:cluster` slot, Design 3's absent rater/cluster:rater).
  - A `plot.icc()` wrapper mirrors `plot.icc_dstudy()` (prints the `autoplot`, returns
    `invisible(x)`). Both registered lazily via `s3_register("ggplot2::autoplot",
    "icc")` in `.onLoad` alongside the existing `icc_dstudy` registration.
  - **An invalid `what` fails loudly via a classed `abort_*()` (#5/#8)** — never a bare
    `match.arg` message; all user-facing text via `cli`.
  - **Correctness is established by deterministic build-data assertions, not images
    (#1 is numerically N/A — no estimand, no new numbers).** Tests build the plot
    (`ggplot2::ggplot_build()` / `layer_data()`) and assert the rendered layer data
    equals the source object's `$estimates` / `$components` — the plot *faithfully
    renders the object's already-oracle-pinned numbers*. **No `vdiffr`** — image
    snapshots are platform/font/version-fragile and add a `Suggests` (consistent with
    the "don't snapshot fits" lesson, `verify-against-installed-package` memory). The
    long-untested `autoplot.icc_dstudy` gets the same build-data coverage in passing.
  - **No estimand-spec** (M11 is a rendering layer, not an estimator — cf. M4/M5.5/M7,
    which also shipped without an estimand-spec).
- Consequences: the only new code is `autoplot.icc()` + `plot.icc()` + one `zzz.R`
  registration line + the `what` validator; the plotted numbers all pre-exist on the
  object. Because ggplot2 stays a `Suggests`, the methods are `check_installed()`-guarded
  and the light-install path is preserved. Deferred out of M11 (recorded so not
  rediscovered): **error-set shading** on the components plot (colouring signal vs. the
  index-specific error set — depends on type/averaging, its own slice); **a combined /
  patchwork multi-panel layout**; **`d_study()`-style projection overlays**; **theming /
  palette customization beyond ggplot2 defaults**; and any **non-ggplot2 (base
  `graphics`) plot method**. The M10 and M9 estimator carry-overs are untouched.
- References: PRINCIPLES.md #1 (oracle-first — here: faithful-rendering build-data
  checks, no new numbers), #2 (no code before scope — this ADR + DoD), #5/#8 (classed
  aborts + `cli`), #15 (thin slices), #17 (deferrals to ROADMAP, not scope creep);
  ADR-010 (M4.5 `autoplot.icc_dstudy` + the lazy-registration pattern, generalized),
  ADR-002 (ggplot2 as `Suggests`, light install), ADR-017 (the arc that scheduled M11);
  the `verify-against-installed-package` memory (no fragile snapshots).

## ADR-021: M12 scope — `choose_icc()` interactive decision helper (advice, not a fit)
- Date: 2026-07-07
- Status: accepted
- Context: M12 is the last of the four ADR-017 deferrals promoted ahead of release
  polish, and the second **teaching-layer, no-new-estimand** milestone (after M11's
  plotting methods). It realizes the `choose_icc()` helper deferred out of M4 — a
  runnable companion to the *Choosing an ICC* flagship vignette (M4), whose decision
  tree (`vignettes/choosing-icc-tree.svg`) it mirrors. The vignette walks six decision
  axes — a **prior** crossed-vs-interchangeable question (`model = "twoway"|"oneway"`),
  then agreement/consistency (`type`), single/average (`unit`), random/fixed (`raters`),
  a **fifth** subject-vs-cluster question for nested data (`cluster`/`level`), and
  complete-vs-incomplete which `icc()` **handles automatically** (not a coefficient
  branch — informational only). The helper turns that prose tree into code. Because
  there is **no new estimand** (cf. M4/M5.5/M7/M11), PRINCIPLES #1 is numerically N/A:
  correctness means the recommendation maps to the *right* `icc()` arguments and the
  emitted call reproduces a direct `icc()` call. Three scope questions were put to the
  maintainer this session.
- Decision (maintainer-approved this session, 2026-07-07):
  - **Dual interface — programmatic core + a guarded interactive shell.** `choose_icc()`
    takes the decision answers as arguments (each enum defaulting to `NULL` = "not yet
    answered"). When every needed answer is supplied it returns advice **non-
    interactively** (scriptable, deterministic, CI-testable). When answers are missing
    **and** `rlang::is_interactive()`, it asks the outstanding questions one at a time
    in the console, then resolves. The question-asking I/O is a **thin shell** over a
    **pure `resolve_*()` core** that takes a complete answer set and returns the advice
    object — the core is what tests exercise; the shell is `is_interactive()`-guarded so
    it never fires in CI/knitr. Missing answers in a **non-interactive** session
    `abort_*()` loudly naming the unanswered axis (#5/#8) — never a silent default.
  - **Returns a classed advice object; it does NOT fit.** `choose_icc()` returns an
    `icc_recommendation` object carrying: the recommended coefficient label(s)
    (McGraw–Wong `ICC(A/C,1)`/`ICC(1)` **and** the Shrout–Fleiss number where the
    crosswalk table names one, else `NA`), a per-axis rationale, and the **exact
    `icc(...)` call** (a `call`/deparsed string the user runs on their own data). A
    `print.icc_recommendation()` method renders all of it via `cli`. **No data argument,
    no fit** — teaching-first, fast, side-effect-free; the user copies the emitted call.
    (Reconsider a `fit=`/data path only post-release if demanded — recorded as deferred.)
  - **Covers the full six-axis tree.** `model` (crossed/one-way), `type`, `unit`,
    `raters`, and the multilevel `cluster`/`level` fifth choice; complete-vs-incomplete
    is surfaced as a **note** (connectedness + automatic `k_eff`), not a branch. Axis
    **applicability is enforced**: with `model = "oneway"` the `type`/`raters` axes do
    not exist (no rater term) — supplying them `abort_*()`s (#5); the recommendation is
    `ICC(1)`/`ICC(1,k)`. The fixed-rater + absolute-agreement caveat and the
    `raters = "fixed"` "random is recommended" note from the vignette are reproduced.
  - **Correctness (#1 N/A numerically) is established by a round-trip oracle + a label
    table:** (a) for **every** valid axis combination, the emitted call `eval`'d on a
    shipped dataset (`ratings`/`ratings_incomplete`/a multilevel fixture) reproduces the
    same coefficient a **direct** `icc()` call with those arguments produces (the helper
    cannot recommend a call that disagrees with `icc()`); (b) the recommended
    McGraw–Wong ↔ Shrout–Fleiss labels match the vignette crosswalk table verbatim;
    (c) inapplicable/underspecified selections `abort_*()` with the classed condition
    (#5). No `vdiffr`, no numeric oracle (no new numbers) — same posture as M11.
  - **No estimand-spec** (teaching/API layer, not an estimator — cf. M4/M5.5/M7/M11).
    All user text via `cli`; all errors via classed `abort_*()` (#8).
- Consequences: new code is a single `R/choose-icc.R` (the `choose_icc()` entry, the
  pure resolver, the label crosswalk, the `icc_recommendation` class + `print`), its
  tests, roxygen + a `NEWS` bullet, and a short pointer added to the M4 vignette ("or
  let the package choose: `choose_icc()`"). No new dependency, no `Imports` change, no
  touch to the fitting/CI pipeline. Deferred out of M12 (recorded so not rediscovered):
  a **`fit=`/data-in path** that runs `icc()` for you; a **`tidy`/`glance` method** on
  the recommendation; **GUI/Shiny** front-ends; **engine (`glmmTMB`/`lme4`/`lavaan`)
  and `ci_method`/`d_study()` guidance** inside the helper (out of the vignette's tree);
  a **full advanced-vignette showcase** of the helper (that is M13). All ADR-017 /
  M9–M11 estimator carry-overs are untouched.
- References: PRINCIPLES.md #1 (oracle-first — here: round-trip call-equivalence, no new
  numbers), #2 (name it / no code before scope — this ADR + DoD), #5 (fail loudly on
  ill-posed/underspecified selections), #8 (`cli` + classed aborts), #15 (thin slices),
  #17 (deferrals to ROADMAP, not scope creep); ADR-009 (M4 flagship vignette + the
  decision tree this mirrors), ADR-020 (M11, the sibling no-estimand teaching layer),
  ADR-017 (the arc that scheduled M12), ADR-011/016 (the multilevel `cluster`/`level`
  API the fifth axis targets), ADR-013 (M6 one-way `model` axis);
  `vignettes/choosing-an-icc.Rmd` (the six-axis tree + crosswalk table).

## ADR-022: M13 scope — release polish (docs, site, CRAN submission-ready)
- Date: 2026-07-07
- Status: accepted
- Context: M13 is the **final** milestone of the ADR-017 arc — the "release polish"
  slot the founding brief (§7) has carried as provisional since M0 (was M9 per ADR-017;
  M7→M9 per ADR-013; M6 originally). No new estimand, engine, fit, CI machinery, or
  dependency: the statistical package is complete (M0–M12; the classic Shrout–Fleiss
  family, three engines, the multilevel family across crossed × {complete, incomplete} ×
  {random, fixed}, D-studies, general plots, and the `choose_icc()` helper). M13's job is
  to make that body **discoverable, teachable, and CRAN-submittable**. PRINCIPLES #1 is
  numerically N/A here (no estimator ships), but #4/#12 still bind: every number a
  vignette displays is computed by `icc()`/`choose_icc()` at knit time and seeded — never
  transcribed. Four scope questions were put to the maintainer this session.
- Decision (maintainer-approved this session, 2026-07-07):
  - **Depth: submission-*ready*, not submitted.** The DoD ends when the package passes
    `R CMD check --as-cran` clean on the full CI matrix (0 errors / 0 warnings; every
    NOTE justified in `cran-comments.md`) with `cran-comments.md` + `inst/WORDLIST`
    authored. The actual upload to CRAN is a **maintainer act** performed out of band
    (win-builder / R-hub round-trips and `submit_cran` are the maintainer's, not this
    milestone's — recorded as deferred). Rationale: CRAN's queue and reviewer feedback
    are out-of-band and cannot gate a milestone's "done".
  - **Version → `0.1.0`.** First public/CRAN release carries `0.1.0` (a real but
    pre-1.0 API), not `1.0.0` (the exported surface is not declared frozen) and not the
    dev `0.0.0.9000`. Bumped in `DESCRIPTION` with the `NEWS.md` release heading.
  - **Showcase extends `advanced.Rmd`, no new article.** The M11 general `autoplot()`
    (coefficients + components) and the M12 `choose_icc()` helper are added as sections
    to the **existing** `advanced.Rmd` (which already showcases M5/M8/M9/M10 designs and
    the lavaan engine), keeping one coherent advanced guide rather than fragmenting it.
  - **Polish DoD items (all four selected):** (a) **pkgdown reference reorg** —
    `_pkgdown.yml` reference index rebuilt: stale titles/descriptions fixed (the
    "Two-way random designs / (later) consistency" wording predates one-way + multilevel),
    the `autoplot`/`plot`/`tidy`/`glance`/`summary`/`print` methods and `choose_icc`
    surfaced, grouped by design family + methods + datasets (memory
    `pkgdown-reference-index-new-exports`: a missing `@export` fails the pkgdown CI job);
    (b) **README refresh** — a current worked example spanning the shipped family
    (agreement/consistency, a multilevel fit, `choose_icc()`), badges verified;
    (c) **`cran-comments.md` + `inst/WORDLIST`** (spelling CI green);
    (d) **NEWS consolidation** — the scattered `0.0.0.9000` dev bullets consolidated
    under a clean `# intraclass 0.1.0` release changelog.
  - **No estimand-spec** (release/teaching layer, not an estimator — cf.
    M4/M5.5/M7/M11/M12). All user text via `cli`; any error via classed `abort_*()` (#8).
    Correctness is **build-green + faithful docs**: vignettes/README knit with all
    displayed numbers computed live (#4/#12); `pkgdown::build_site()` +
    `pkgdown::check_pkgdown()` clean; `R CMD check --as-cran` clean; existing 478 tests
    stay green (no test regressions from doc/site work).
- Consequences: changes are confined to docs/metadata — `vignettes/advanced.Rmd`,
  `_pkgdown.yml`, `README.Rmd`/`README.md`, `DESCRIPTION` (version), `NEWS.md`,
  new `cran-comments.md` + `inst/WORDLIST`, and any roxygen `@examples`/`\value` gaps
  `--as-cran` surfaces. No `R/` logic change, no new dependency, no `Imports` change,
  no touch to the fitting/CI/estimand pipeline. Ships on `m13-release-polish`, merges
  via PR (`milestone-branches-and-prs`). Deferred out of M13 (recorded so not
  rediscovered): the **actual CRAN upload** + win-builder/R-hub/`submit_cran` round-trips
  (maintainer, out of band); a **JOSS/paper** submission; a **`pkgdown` custom
  theme/logo/hex sticker**; **benchmark-vs-prior-art** article (ROADMAP parking lot);
  and every prior-milestone carry-over untouched (M9 averaged cluster-level `ICC(c,k)`
  incomplete divisor; lme4 for the fixed/multilevel fits; the Bayesian engine + `ci_method
  = "posterior"`; one-way-via-SEM; within-cell replicates; three-facet `d_study()`;
  the conflated single-level ICC, Eq. 14 — all in `ROADMAP.md`).
- References: PRINCIPLES.md #4 (no fabricated values — vignette/README numbers computed
  live), #12 (seeded + sourced), #6 (stable small public API — the reference index
  documents exactly the exported surface), #8 (`cli` + classed aborts), #13
  (docs-as-teaching — the advanced guide + reference site are first-class learning),
  #15 (thin slices), #16 (tracking updated in-commit), #17 (deferrals to ROADMAP);
  brief §7 (release-polish slot) and §8 (per-milestone DoD: `R CMD check` clean, pkgdown
  builds, vignette knits, tracking updated, clean tagged commit); ADR-017 (the arc that
  scheduled M13 last), ADR-021/020 (M12/M11 teaching layers this showcases), ADR-009 (M4
  flagship vignette + `test-vignette-claims.R`, the live-computation posture reused);
  memory `pkgdown-reference-index-new-exports`, `verify-against-installed-package`,
  `run-lintr-before-push`.

## ADR-023: M14 scope — lme4 for the fixed & multilevel fits (engine parity)
- Date: 2026-07-07
- Status: accepted
- Context: With the ADR-017 arc shipped (M0–M13, v0.1.0 submission-ready) and no
  pre-planned M14, the maintainer opened a backlog review of the deferred/parked
  work (STATUS "Next action" thread). The strongest frontrunners were the
  **Bayesian engine** (rstanarm + `ci_method = "posterior"`), the **M9 averaged
  cluster-level `ICC(c,k)` incomplete divisor** (an open modeling question), and
  **lme4 for the fixed/multilevel fits** (engine parity, the ADR-012 debt deferred
  four times — out of M5.5, M8, M9, M10). The maintainer chose **lme4 parity** for
  M14: the lowest-risk, smallest-scope option, it retires a long-standing debt and
  strengthens the independent *interval* oracle on the package's most complex fits
  (glmmTMB currently covers these paths as the only engine). Two scope questions were
  put to the maintainer and confirmed this session (below). Per PRINCIPLES.md #2/#14
  this ADR details the milestone at its start; ADR-012/M5.5 is the governing
  precedent (an alternative engine for an existing estimand is **not** a new
  estimand — no estimand-spec, cf. M4/M7).
- Decision:
  - **`engine = "lme4"` gains full design parity with glmmTMB, balanced/complete**,
    covering the five remaining fit shapes glmmTMB owns today, each a new
    `fit_lme4_*` returning the **same six-field engine contract** as its glmmTMB twin
    (`fit`/`engine`/`components`/`estimate`/`vcov`/`to_components`) so
    `icc_point()`/`mc_ci()`/`d_study()` are untouched:
    (1) `fit_lme4_fixed` — two-way **fixed** (Case 3/3A), subject level;
    (2) `fit_lme4_multilevel` — Design 1 crossed random, five-component;
    (3) `fit_lme4_nested_clusters` — Design 2, four-component;
    (4) `fit_lme4_nested_subjects` — Design 3, three-component one-way multilevel;
    (5) `fit_lme4_multilevel_fixed` — Design 1 crossed fixed (M10), reusing (1)'s
    θ²_r helper.
  - **Scope width = full parity, all five shapes** (open question 1; maintainer chose
    full over a thinner "fixed + Design 1 random" subset), sliced thin (#15):
    **Slice 1** `fit_lme4_fixed` (the one novel derivation — see below); **Slice 2**
    `fit_lme4_multilevel` (the delta-transform template extended to five components +
    multi-grouping-factor merDeriv vcov); **Slice 3** nested Designs 2/3 +
    `fit_lme4_multilevel_fixed`, reusing Slices 1–2.
  - **Balanced/complete only; incomplete falls through to a loud abort** (open
    question 2; maintainer chose balanced-only). The blanket lme4 guard in `icc()`
    (currently `engine == "lme4" && (multilevel || raters == "fixed")` →
    `abort_unsupported`) is **narrowed to incomplete-only**: the balanced
    fixed/multilevel lme4 paths become supported; ragged data still aborts loudly
    toward `engine = "glmmTMB"`. The four `fit_glmmtmb_*` calls in the `engine_fit`
    dispatch block gain `engine == "lme4"` branches.
  - **The θ²_r Monte-Carlo draw (Slice 1) is the one new derivation.** Fixed raters
    put a **bias-corrected finite-population θ²_r** (ADR-008, `theta2r_fixed()`) in the
    rater slot, built from the **fixed rater contrasts** — not a random SD. lme4's
    `to_components` must therefore map draws of the **fixed-effect** coefficients
    (whose joint covariance merDeriv supplies alongside the random SDs) through the
    θ²_r construction, rather than the `exp(2 · log-SD draw)` map used for random
    components. Everything else reuses the shipped merDeriv → **log-SD delta-transform**
    (Jacobian 1/sd; ADR-012) applied to more variance components.
  - **Boundary policy unchanged (#3):** multilevel and fixed fits reach the variance
    boundary more often; the shipped `lme4::isSingular()` detection → classed
    `intraclass_singular_fit` abort pointing at `engine = "glmmTMB"` (boundary-robust
    via its log-SD parameterization) is reused per shape, oracle-pinned, not asserted.
  - **No new estimand, estimand-spec, `ci_method`, or dependency.** lme4 + merDeriv
    stay `Suggests` behind `check_installed()` (light install preserved). Additive,
    non-breaking API change: `engine = "lme4"` accepts designs that previously aborted
    (#6). Correctness is the established **O-LME pattern per shape** (glmmTMB the
    independent oracle, #1): (a) point lme4 ≡ glmmTMB ≤ 1e-4; (b) **interval** lme4
    MC-CI ≈ glmmTMB MC-CI ~1e-2; (c) a boundary/singular-fit oracle; (d) seeded-sim
    coverage at nominal.
- Consequences: retires the ADR-012 (and ADR-005-lineage) engine-parity deferral —
  `engine = "lme4"` becomes a real choice across every balanced design glmmTMB fits,
  and each complex fit gains a cross-engine *interval* check, not just a point check.
  Changes are confined to `R/engine-lme4.R` (five new `fit_lme4_*` fns + the θ²_r
  helper reuse), the `icc()` dispatch/guard block (`R/icc.R`), roxygen `@param engine`
  design coverage, and tests. No `Imports` change, no estimand/CI-machinery change.
  Ships on `m14-lme4-parity`, merges via PR (`milestone-branches-and-prs`); post-merge
  `project/` reconcile is a direct commit to `main` (finish-task policy). Deferred out
  of M14 (recorded so not rediscovered): **incomplete/ragged lme4** for every new shape
  (the M9 `k_eff`/connectedness × merDeriv singular-fit interaction — a follow-up
  slice); the **parametric-bootstrap `ci_method`** (bootMer); a **boundary-robust lme4
  interval for singular fits** (glmmTMB covers it today); merDeriv edge cases beyond
  these models. Untouched arc carry-overs stay in `ROADMAP.md`: the **Bayesian engine**
  + `ci_method = "posterior"`; the **M9 averaged cluster-level `ICC(c,k)` incomplete
  divisor**; **one-way via SEM**; within-cell replicates; three-facet `d_study()`;
  the conflated single-level ICC (Eq. 14).
- References: PRINCIPLES.md #1 (oracle-first — cross-engine point + interval + sim),
  #2 (name the estimand first — none new here), #3 (boundary-aware MC intervals),
  #6 (additive, non-breaking API), #8 (`cli` + classed aborts), #14 (milestone gates),
  #15 (thin slices), #16 (tracking in-commit), #17 (deferrals to ROADMAP); ADR-002
  (glmmTMB default + why lme4 needs merDeriv for the joint vcov), ADR-003 (MC CIs),
  ADR-005 (original lme4 deferral), **ADR-012 (the M5.5 selectable-lme4 seam +
  merDeriv log-SD delta-transform + singular-fit policy this milestone extends)**,
  ADR-008 (fixed-rater bias-corrected θ²_r / `theta2r_fixed()`), ADR-011 (M5 multilevel
  fit + `level` API), ADR-016/019 (nested Designs 2/3 and fixed multilevel fits being
  mirrored); `merDeriv` (Wang & Merkle 2018, *J. Stat. Softw.*), lme4 (Bates et al.
  2015); `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start), §1 (engines);
  memory `milestone-branches-and-prs`, `verify-against-installed-package`,
  `run-lintr-before-push`.

## ADR-024: M15 scope — incomplete/ragged lme4 (full incomplete parity)
- Date: 2026-07-07
- Status: accepted
- Context: M14 (ADR-023) gave `engine = "lme4"` full **balanced/complete** design
  parity with glmmTMB but deferred incomplete/ragged data to "a follow-up slice"
  (the M9 `k_eff`/connectedness × merDeriv singular-fit interaction). With M14
  shipped (PR #18, v0.1.0 submission-ready) and no milestone in flight, the
  maintainer opened a backlog review (STATUS "Next action") and chose to
  **consolidate M14** by closing the incomplete-data gap rather than open new
  statistical surface (the Bayesian engine, the M9 `ICC(c,k)` divisor). This is the
  lower-risk of the frontrunners: engine parity on an existing estimand, not new
  estimand work. Per PRINCIPLES.md #2/#14 this ADR details the milestone at its
  start; **ADR-023/M14 is the governing precedent** (an alternative engine for an
  existing estimand is not a new estimand — no estimand-spec, cf. M4/M5.5/M7).
  A scope-width question was put to the maintainer this session (below).
- Decision:
  - **`engine = "lme4"` gains incomplete/ragged parity with glmmTMB across every
    incomplete shape glmmTMB already fits** — chosen scope width **= full incomplete
    parity** (maintainer chose full over the thinner "M9 multilevel only" or "random
    shapes only" subsets). Three targets, each an existing `fit_lme4_*` shape run on
    ragged data (**no new fit function, no structural fit change**): (1) incomplete
    **fixed-rater two-way** (M3 Case 3A, θ²_r-under-imbalance); (2) incomplete
    **crossed (Design 1) random multilevel** (M9, five-component); (3) incomplete
    **random two-way** (M3 × M5.5) — currently *ungated but untested* as a selectable
    engine, pinned here with an oracle.
  - **Key structural fact — no fit change needed.** The `k_eff` (harmonic-mean
    divisor), connectedness/identifiability, and θ²_r-under-imbalance machinery runs
    in `icc()` **before** engine-fit dispatch and is engine-agnostic; the fit
    *formulas* are identical between balanced and incomplete data (ragged data is
    just missing cells). The work is therefore: (a) **narrow/remove the two
    `!balanced` lme4 guards** (`R/icc.R` — the fixed-rater guard and the multilevel
    guard, currently aborting toward glmmTMB); (b) confirm the shipped **merDeriv →
    log-SD delta-transform** (ADR-012) and, for the fixed shape, the **θ²_r draw from
    the fixed rater-contrast βs** (ADR-023) survive ragged designs with **unequal
    rater counts**; (c) pin every shape with oracles.
  - **Scope boundary (unchanged, glmmTMB-limited).** Only shapes glmmTMB already
    fits are in scope: incomplete **nested** Designs 2/3, incomplete **fixed
    multilevel**, and the **averaged cluster-level `ICC(c,k)` incomplete divisor** are
    deferred **for all engines** (guarded before dispatch, ADR-008/016/018) — lme4
    cannot cover what glmmTMB does not. This milestone does not change that frontier.
  - **Boundary/singular policy unchanged (#3, ADR-012/023).** Ragged designs reach
    the variance boundary far more often → merDeriv's information matrix goes singular
    → the shipped `lme4::isSingular()` → classed `intraclass_singular_fit` abort
    pointing at `engine = "glmmTMB"` fires more often. This is the *intended* graceful
    degradation, not a regression: lme4 covers incomplete data **when it can** and
    **loudly hands off** to the boundary-robust engine otherwise. A material part of
    the milestone is **characterizing and oracle-pinning** that success-vs-degrade
    boundary (#1/#5/#18 — pinned, not asserted).
  - **No new estimand, estimand-spec, `ci_method`, or dependency.** lme4 + merDeriv
    stay `Suggests` behind `check_installed()` (light install preserved). Additive,
    non-breaking API change: `engine = "lme4"` accepts incomplete designs that
    previously aborted (#6). Correctness is the established **O-LME2 pattern per
    shape** (glmmTMB the independent oracle, #1): (a) point lme4 ≡ glmmTMB ≤ 1e-4 on
    ragged data; (b) interval lme4 MC-CI ≈ glmmTMB MC-CI ~1e-2; (c) a
    singular-fit-abort oracle on a ragged design that goes singular; (d) seeded-sim
    coverage at nominal.
  - **Slices (thin, #15):** **Slice 1** incomplete random two-way — narrow no guard
    (already ungated), add the O-LME2 oracle + roxygen (the cheapest, de-risks the
    merDeriv-on-ragged mechanics first); **Slice 2** incomplete fixed-rater two-way —
    narrow the `R/icc.R:637` guard, confirm θ²_r-under-imbalance from ragged
    fixed-contrast βs, oracle; **Slice 3** incomplete crossed random multilevel —
    narrow the `R/icc.R:652` guard, five-component merDeriv vcov on ragged data,
    oracle + the singular-fit-abort characterization.
- Consequences: retires the last ADR-023 engine-parity deferral — `engine = "lme4"`
  becomes a real choice on **every** design glmmTMB fits, balanced or ragged, and each
  incomplete fit gains a cross-engine *interval* check, not just glmmTMB alone.
  Changes are confined to the `icc()` guard/dispatch block (`R/icc.R` — two guards
  narrowed), roxygen `@param engine` coverage (drop the "complete, balanced only"
  caveat for lme4), `NEWS`, and tests; the `fit_lme4_*` functions are unchanged. No
  `Imports`, estimand, or CI-machinery change. Ships on `m15-incomplete-lme4`, merges
  via PR (`milestone-branches-and-prs`); post-merge `project/` reconcile is a direct
  commit to `main` (finish-task policy — no CI job reads `project/`). Deferred out of
  M15 (recorded so not rediscovered): the **parametric-bootstrap `ci_method`**
  (bootMer); a **boundary-robust lme4 interval for singular fits** (glmmTMB covers it
  today — the degrade-to-glmmTMB handoff stands); merDeriv edge cases beyond these
  models. Untouched arc carry-overs stay in `ROADMAP.md`: the **Bayesian engine** +
  `ci_method = "posterior"`; the **M9 averaged cluster-level `ICC(c,k)` incomplete
  divisor**; **one-way via SEM**; within-cell replicates; three-facet `d_study()`;
  the conflated single-level ICC (Eq. 14).
- References: PRINCIPLES.md #1 (oracle-first — cross-engine point + interval + sim),
  #2 (name the estimand first — none new here), #3 (boundary-aware MC intervals),
  #5/#18 (fail loudly / pin, don't assert — the singular-fit degrade boundary),
  #6 (additive, non-breaking API), #8 (`cli` + classed aborts), #14 (milestone gates),
  #15 (thin slices), #16 (tracking in-commit), #17 (deferrals to ROADMAP);
  **ADR-023 (M14 balanced lme4 parity this milestone extends to ragged data)**,
  ADR-012 (M5.5 selectable-lme4 seam + merDeriv log-SD delta-transform + singular-fit
  policy), ADR-008 (M3 `k_eff`/connectedness + fixed-rater θ²_r-under-imbalance),
  ADR-011 (M5 multilevel fit), ADR-018 (M9 incomplete crossed multilevel estimand this
  reuses); `merDeriv` (Wang & Merkle 2018), lme4 (Bates et al. 2015);
  `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start), §1 (engines); memory
  `milestone-branches-and-prs`, `verify-against-installed-package`,
  `run-lintr-before-push`.

## ADR-025: M16 scope — parametric-bootstrap `ci_method` (second interval method)
- Date: 2026-07-07
- Status: accepted
- Context: With M0–M15 shipped (v0.1.0 submission-ready) and no milestone in flight,
  the maintainer opened a backlog review of the **non-Bayesian carryovers** and agreed
  a sequencing plan ordered by oracle-risk (STATUS "Next action"): Wave 1 =
  parametric-bootstrap `ci_method` (this milestone) + the conflated single-level ICC
  (Eq. 14); Wave 2 = within-cell replicates + three-facet `d_study()`; Wave 3 = the M9
  averaged `ICC(c,k)` incomplete divisor (research). The parametric-bootstrap method was
  chosen as M16 because it is the **lowest-estimand-risk** substantive item (no new
  estimand) and its **multi-`ci_method` dispatch seam** is reused by the eventual Bayesian
  `ci_method = "posterior"` — infra ROI that pays forward. This is the **first genuinely
  new `ci_method`** since the Monte-Carlo default (ADR-003); until now `icc()` has hard-
  rejected any `ci_method != "montecarlo"` via `require_supported()`. Per PRINCIPLES.md
  #2/#14 this ADR details the milestone at its start. An engine-coverage scope question
  was put to the maintainer this session (below).
- Decision:
  - **Add `ci_method = "bootstrap"`: a parametric bootstrap.** Simulate response vectors
    from the fitted model → refit → recompute the ICC per replicate → **percentile**
    quantiles for `conf.low`/`conf.high` and the replicate SD for `std.error`. Unlike the
    MC default (draws from the fitted Wald covariance on the engine's log scale, ADR-003),
    each replicate is a **real refit**, so the interval does not rely on the asymptotic-
    normal approximation of the parameter covariance. **Boundary-aware by construction**
    (#3): every refit yields variances ≥ 0, and a replicate that lands on the boundary
    (a component pinned at 0) is a valid draw, kept.
  - **Both engines, via an engine-level `simulate_refit()` contract** (maintainer chose
    "both" over glmmTMB-first / lme4-first). Rationale: a `ci_method` that only works on a
    non-default `Suggests` engine (lme4) is a UX trap when **glmmTMB is the default engine**.
    The contract mirrors the M5.5/M7 engine × design dispatch seam (ADR-012): `bootMer()`
    for lme4, `simulate()` + refit for glmmTMB. Each returns a matrix of per-replicate
    variance components on the **shared component contract** so `icc_point()` maps each
    replicate to the ICC identically to the MC path — no per-engine ICC code.
  - **No new estimand, estimand-spec, or dependency.** Same coefficients, same population
    definitions — only a new *interval* method. `bootMer` is in lme4 (`Suggests`);
    glmmTMB `simulate()` is already in `Imports`. Light-install preserved (ADR-002).
    Additive, non-breaking API: `ci_method` gains a value; the default is unchanged (#6).
  - **New arg `boot_samples`** (default **999**), distinct from `mc_samples` (10000):
    the parametric bootstrap is ~1000× costlier (a full refit per replicate). Recorded on
    the `icc` object's `ci` list alongside `method`/`conf_level`/`seed`; seeded for
    reproducibility (#9/#12) via the existing `with_rng_seed()` wrapper.
  - **Percentile interval only** in M16. **BCa** (needs a jackknife acceleration estimate)
    is deferred to ROADMAP — percentile is boundary-safe and the standard first cut.
  - **`d_study()` stays MC-only** in M16. The reliability-curve band reuses the *shared MC
    draws* across projected `k` (ci-montecarlo.R) — a device specific to the MC covariance
    draw. Bootstrap CIs cover the fitted coefficients; **bootstrap-projected `d_study`
    bands are deferred** (would reproject each refit's components across `k`).
  - **Refit-failure policy (#5/#8):** discard **nonconvergent** replicates; if the discard
    fraction exceeds a threshold (default TBD in execution, ~0.10), raise a **classed `cli`
    warning** naming the count (never a silent NA interval). **Singular/boundary** refits
    are valid draws (variance pinned at 0) and are **kept** — consistent with the MC
    boundary policy (ADR-003).
  - **Correctness (#1) — a CI *method*'s oracle is coverage.** Three independent oracles:
    (O1) a **seeded simulation coverage study** at known variance components showing
    ~nominal (95%) coverage, the estimator-coverage pattern already used across the suite;
    (O2) **agreement with the MC CI** on interior (non-boundary) cases within Monte-Carlo
    tolerance — MC is the independent method, and the two should coincide where the
    asymptotics hold, diverging *predictably* toward the boundary (characterized, #18);
    (O3) a **literature anchor** for the parametric bootstrap of variance components
    (Efron & Tibshirani 1993; the ten Hove/Jorgensen/van der Ark MC-vs-bootstrap
    comparison). Bibliography + oracle-registry rows added during execution/verify.
  - **Slices (thin, #15):** **Slice 1** — the `simulate_refit()` contract + `bootstrap`
    dispatch for the **default glmmTMB engine** on the balanced two-way random ICC
    (simplest fit), with O1/O2 oracles (de-risks the refit-in-loop mechanics first);
    **Slice 2** — lme4 `bootMer` parity through the same contract, O2 cross-engine
    (bootstrap-lme4 ≈ bootstrap-glmmTMB) + O1; **Slice 3** — extend across the fitted
    design family (fixed-rater, multilevel) that both engines already cover, and the
    refit-failure/discard policy + classed warning. Cross-cutting DoD: roxygen
    (`@param ci_method`/`boot_samples`), NEWS, `advanced.Rmd` method-comparison note.
  - **Scope boundary.** Only designs the engines already *fit* are in scope (bootstrap is
    an interval method layered on existing fits) — it inherits the current design frontier,
    adds no estimand surface. Bootstrap for `d_study`, BCa intervals, and parallelized
    refits are deferred to ROADMAP.
- References: PRINCIPLES.md #1 (oracle-first — coverage + MC agreement + literature),
  #2 (name the estimand first — **none new**; this is an interval method), #3 (boundary-
  aware intervals — the refit bootstrap is boundary-aware by construction), #5/#8
  (fail loudly / classed `cli` on excess refit failure), #6 (additive, non-breaking API),
  #9/#12 (seeded, reproducible), #14 (milestone gates), #15 (thin slices), #16 (tracking
  in-commit), #17 (BCa / d-study-bootstrap / parallel deferrals to ROADMAP);
  **ADR-003 (Monte-Carlo default this adds a sibling to)**, ADR-012 (M5.5 engine dispatch
  seam the `simulate_refit()` contract mirrors), ADR-002 (glmmTMB Imports / lme4 Suggests
  light-install), ADR-023/024 (lme4 + merDeriv engine parity these bootstraps run on);
  `bootMer` (lme4, Bates et al. 2015), glmmTMB `simulate()` (Brooks et al. 2017),
  Efron & Tibshirani (1993); `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start),
  §1 (engines / light install); memory `milestone-branches-and-prs`,
  `verify-against-installed-package`, `run-lintr-before-push`.

## ADR-026: M17 scope — variance-decomposition trio (replicates, three-facet `d_study()`, conflated ICC)
- Date: 2026-07-08
- Status: accepted
- Context: With M0–M16 shipped and no milestone in flight, the maintainer promoted the
  **next backlog wave** out of the ROADMAP parking lot. The non-Bayesian sequencing set by
  ADR-025 / STATUS is: Wave 1 = parametric-bootstrap `ci_method` (shipped, M16) **+ the
  conflated single-level ICC (Eq. 14)**; Wave 2 = **within-cell replicates + three-facet
  `d_study()`**; Wave 3 = the M9 averaged `ICC(c,k)` incomplete divisor (research). The
  maintainer chose to bundle the two remaining Wave-1/Wave-2 items that are *not* research-
  risk into **one milestone, M17**, because they share a theme — **finer variance
  decomposition and its projection** — and two of the three ride machinery that already
  ships. Per PRINCIPLES.md #2/#14 this ADR details M17 at its start; the per-slice estimand
  detail is deferred to each slice's estimand-spec (Slice 1 promotes M5 §4; Slice 2 extends
  M4.5; Slice 3 is a new spec). Three scope questions were put to the maintainer this
  session (Decision below).
- Decision:
  - **One milestone, three independent vertical slices, ordered by oracle-risk / effort**
    (bank the clean-oracle wins first, #1). The three are *not* mutually dependent; the
    milestone is a container. Two ride the **existing five-component multilevel fit**
    (M5/M8/M9) and its GT machinery; the third is a **new single-level two-way fit**.
    **Slice 3 (replicates) may spin into its own M18** if the milestone runs heavy — a
    maintainer decision revisited at Slice 3 start (maintainer chose "keep as one M17" now).
  - **Slice 1 — conflated single-level ICC (Eq. 14) as a shipped, selectable coefficient.**
    The number obtained by *ignoring* the cluster structure of an M5 multilevel design —
    the motivating bias the package exists to expose. Formula and provenance already stated
    in `M5-multilevel.md §4`, computed today only as a vignette teaching contrast:
    `(σ²_c + σ²_{s:c}) / (σ²_c + σ²_{s:c} + (σ²_r + σ²_{cr} + σ²_{(s:c)r})/k)`, read off the
    same five-component fit. **Surfaced via a new `level = "conflated"` value** (maintainer
    choice) alongside `level = "subject"/"cluster"` — **labeled in `print`/`tidy`/docs as a
    diagnostic contrast, not a recommended coefficient** (its entire purpose is to be the
    *wrong* answer for multilevel data; it must never read as a peer of the correct levels).
    No new fit, no new dependency. Oracles: (O-Eq14) ten Hove et al. (2022) Eq. 14 closed
    form from the fitted components; (O-reduction) equals a plain single-level `icc()` on
    the same ratings ignoring `cluster` (promote M5 §5's vignette invariant to a real test);
    (O-lme4) same components from `lmer`.
  - **Slice 2 — multilevel rater-count `d_study()` (both levels).**
    **⚠ Retargeted 2026-07-08 (amends the original "three-facet / subjects-per-cluster"
    plan below).** On reading the source before coding (#2), the "project the
    subjects-per-cluster facet" framing was found to **contradict the paper** and was
    dropped from M17. ten Hove et al. (2022) **Eq. 13**: the cluster-level ICC
    `σ²_c / (σ²_c + (σ²_r + σ²_cr)/k)` **contains no subject-related variance** ("the ordering
    of clusters across raters is independent of subject-related effects"), and its `k` is
    *raters per cluster*. The paper's only reliability-projection facet is the **number of
    raters** (p. 4: "different values of k can be used to estimate IRR of future data gathered
    from different numbers of raters"), for both levels; the **number of subjects per cluster
    (Ns)** affects only estimation **bias / efficiency / CI width** (Simulation 1), i.e. it is
    a sample-size/design-power matter, not part of any coefficient. A subjects-per-cluster
    *reliability* curve would therefore be a fabricated formula (#1/#4); a cluster-mean
    dependability that *did* average over subjects would be a different, non-IRR general-GT
    estimand outside this package's scope. (Memory: `cluster-icc-no-subject-facet`.)
    - **The retargeted, sourced slice:** lift `d_study()`'s current blanket multilevel abort
      and project the **rater count `m`** for the **subject-level (Eq. 12)** and
      **cluster-level (Eq. 13)** multilevel ICCs — a pure change of the averaging divisor in
      the existing M5 estimand, reusing the single-level `d_study()` MC-reuse machinery. The
      `icc_dstudy` object gains a `level` column for multilevel fits; `autoplot()` facets by
      level. Agreement + consistency at each level; nested designs project the subject level
      only (Design 3 agreement-only), matching what `icc()` already reports.
    - **Scope guard:** **complete-data multilevel only.** Incomplete multilevel projection is
      deferred — the cluster level would hit the open, un-oracled M9 `ICC(c,k)` incomplete
      divisor (M9 §9, Wave 3). Fixed-rater absolute-agreement projection stays ill-posed and
      aborts (reuses `abort_fixed_agr_projection`, M4.5 §4).
    - **Oracles (#1):** (O-reduction) at `m = observed k` the projection equals the fitted
      M5 `ICC(*,k)` at each level, to < 1e-4; (O-lme4) the projected curve matches one built
      from an independent `lmer` five-component fit; (O-sim) seeded recovery of a projected
      value the design did not run, with MC-band coverage (the M4.5 O-sim pattern). **No
      `gtheory` dependency needed** (dropped with the subjects-per-cluster oracle).
    - **Subjects-per-cluster / three-facet is removed from M17**, not merely deferred: it is
      reclassified under the parked **design/power helpers** item (sample-size / CI-width),
      where Ns actually lives.

    *Original (superseded) plan:* ~~three-facet `d_study()`: project the subjects-per-cluster
    facet at the cluster level, restricted to complete-data multilevel; oracle Brennan (2001)
    two-facet / `gtheory` GENOVA.~~ Superseded by the paragraph above per the paper.
  - **Slice 3 — within-cell replicates: split σ²_sr from σ²_e.** With ≥2 ratings per
    subject×rater cell the residual splits into the **subject×rater interaction σ²_sr** and
    **pure within-cell error σ²_e** via `(1 | subject:rater)`. The detection + refusal
    **already ship** (`summarize_design()$has_replicates`, the `icc()` abort naming this
    milestone) — this slice replaces the abort with a fit path. **A new estimand → a new
    estimand-spec** (`M17-within-cell-replicates.md`). **Three design questions resolved at
    spec time, not now** (maintainer chose "decide at spec time" for the facet structure):
    (1) is the replicate/occasion facet **crossed** with rater or **nested** within it;
    (2) **which coefficients ship** — with σ²_sr separated, agreement/consistency can place
    it in/out of the error set explicitly and the divisor can average over raters and/or
    occasions (a two-facet D-study); single-*rating* point values barely move vs. today
    (σ²_sr + σ²_e were already lumped into σ²_res) — the payoff is reporting σ²_sr and
    projecting over occasions; (3) the **data API** for identifying the occasion (a
    `replicate`/`occasion` column vs. bare within-cell row multiplicity). Oracles:
    (O-gtheory) `gtheory` two-facet variance components — **`gtheory` added to `Suggests`,
    test-only, exactly like `psych`** (no `Imports` change, light-install intact, ADR-002);
    (O-MS) classical two-way-with-replication ANOVA mean squares in closed form; (O-sim)
    seeded recovery of known σ²_sr / σ²_e.
  - **Cross-cutting DoD.** Each slice is end-to-end: fit → estimand map → point → **both**
    `ci_method`s (MC + bootstrap, M16) where the fit supports them → `print`/`tidy`/`glance`
    → `choose_icc()` awareness where a new coefficient is user-selectable → roxygen + NEWS +
    vignette → ≥2 independent oracles green → full CI matrix (Windows + R-devel) green.
    Ships on `m17-<slug>` via PR (`milestone-branches-and-prs`); `project/` reconcile is the
    post-merge direct commit to `main` (finish-task policy).
  - **Scope boundary / deferrals (#17).** BCa and bootstrap-projected `d_study` bands stay
    deferred (ADR-025). The **M9 averaged `ICC(c,k)` incomplete divisor** stays Wave-3 /
    ROADMAP and must not be reached via Slice 2's complete-data restriction. **One-way via
    SEM** (blocked, ADR-014), the **Bayesian engine** + `ci_method = "posterior"`,
    **categorical/ordinal GLMM ratings**, and the **lme4 singular-fit / merDeriv edge cases**
    remain in ROADMAP untouched.
- References: PRINCIPLES.md #1 (oracle-first — ≥2 independent per slice), #2 (name the
  estimand first — Slice 3 gets a new spec; Slices 1–2 extend M5 §4 / M4.5), #3 (boundary-
  aware intervals inherited), #5/#8 (fail loudly / classed guards for replicate & cluster
  identifiability), #6 (additive, non-breaking — `level` gains a value, `d_study()` gains a
  facet arg), #14/#15 (milestone gates, thin slices), #16 (tracking in-commit), #17 (BCa /
  incomplete-`ICC(c,k)` / Bayesian / SEM / ordinal deferrals);
  **ADR-011 (five-component multilevel fit Slices 1–2 read off)**, ADR-025 (M16 bootstrap
  `ci_method` each slice must support), ADR-002 (glmmTMB Imports / `gtheory` + lme4 Suggests,
  light install), ADR-005/012 (engine roles + dispatch seam); estimand-specs
  `M5-multilevel.md §4` (Eq. 14), `M4.5-d-study.md` (projection), the forthcoming
  `M17-within-cell-replicates.md`; ten Hove, Jorgensen & van der Ark (2022, Eq. 14),
  Brennan (2001, two-facet D-studies), `gtheory` (Moore); `CLAUDE_CODE_KICKOFF.md` §7
  (detail a milestone at its start), §1 (engines / light install); memory
  `milestone-branches-and-prs`, `verify-against-installed-package`, `run-lintr-before-push`,
  `pkgdown-reference-index-new-exports`.

## ADR-027: M18–M21 arc — close the `COVERAGE.md` "not yet" completeness gaps
- Date: 2026-07-08
- Status: accepted
- Context: With M0–M17 shipped and no milestone in flight, this session built
  `project/COVERAGE.md` — a current-state stock-take of the `icc()` / `d_study()` argument
  space that tags every unsupported combination with a reason category (**not yet** /
  **research** / **blocked** / **by design**). The maintainer asked to plan a milestone (or
  several) that closes the **🔵 not yet** items — the ones with a known implementation route —
  **excluding the four cross-cutting items** (Bayesian `ci_method = "posterior"`,
  categorical/ordinal GLMM, non-parametric/profile-likelihood CIs, lme4 singular/merDeriv edge
  cases), which are explicitly sequenced for later. Fourteen non-cross-cutting "not yet" items
  were inventoried (COVERAGE.md §①/②/④/`d_study`). This ADR **sets the arc**; per
  PRINCIPLES.md #2/#14 and brief §7 each milestone below is **detailed by its own scoping ADR
  at its start** (as ADR-017 set the M9–M13 tail and ADR-018–022 detailed each). Two
  sequencing/scope questions were put to the maintainer this session (Decision below).
- Decision:
  - **Four milestones, mixed-model-mature first, SEM last** (maintainer chose "ML completeness
    first"). Order and grouping by **shared machinery + oracle-risk** (#1 — bank the
    established-oracle wins before the heavier engine arc):
    - **M18 — Multilevel completeness I: crossed (Design 1) incomplete corners.** Fills the
      ragged-data corners of the crossed five-component fit that M9/M10/M17 left open.
      *Slice 1* incomplete **fixed-rater** crossed (COVERAGE #9) — reuses M3 Case-3A +
      M10 θ²_r under imbalance (lowest risk, machinery exists). *Slice 2* incomplete
      **conflated** ICC (#8) — characterize Eq. 14 on ragged data (`M17-conflated-icc.md §6`;
      needs a new oracle characterization). *Slice 3* incomplete **subject-level `d_study()`**
      (#13, **subject level only** — the cluster level stays bounded by the Wave-3 `ICC(c,k)`
      incomplete-divisor research item, ADR-018/M9 §9) **+ bootstrap-projected `d_study()`
      bands** (#14, the M16 deferral).
    - **M19 — Multilevel completeness II: nested designs (2/3).** Brings the nested designs up
      to the incomplete + fixed parity crossed Design 1 already has. *Slice 1* **incomplete
      nested** (#10) — the M8→incomplete analog of M9. *Slice 2* **fixed-rater nested** (#11) —
      θ²_r in the nested decomposition.
    - **M20 — Within-cell replicate completeness.** Extends M17 Slice 3 beyond
      balanced-two-way-random. *Slice 1* **ragged** replicates (#4) · *Slice 2* **fixed-rater**
      replicates (#5) · *Slice 3* **multilevel** replicates (#6).
    - **M21 — SEM (lavaan) engine parity** (the lavaan analog of the lme4 M5.5→M15 arc).
      *Slice 1* lavaan **bootstrap** (#3) — reuse the M16 `simulate_refit` seam (quick, low
      risk). *Slice 2* **fixed-rater** SEM (#1). *Slice 3* **incomplete** SEM / **FIML** (#2).
  - **No new estimand for M18–M20; M21 is engine parity, not estimand work.** Like M14/M15,
    the completeness milestones extend the **existing** estimands to ragged/fixed/replicated
    data and carry **no new estimand-spec** — except the two that need real spec care:
    **incomplete-conflated** (extend `M17-conflated-icc.md §6`) and **FIML-SEM** (an oracle
    note, engine not estimand — cf. M7). Additive and non-breaking throughout (#6): no new
    top-level argument, only new *valid combinations* of the shipped arguments.
  - **Oracle posture (#1):** M18–M20 use the established mixed-model pattern — glmmTMB↔lme4
    cross-engine < 1e-4, **reduction** to the shipped complete/balanced case, and seeded
    recovery; no textbook worked example (as M8–M10/M15). M21 uses **glmmTMB as the
    independent oracle** exactly as M7 did. Each milestone's own ADR pins its per-slice
    oracles at its start.
  - **Two items reclassified out of this arc** (maintainer chose "reclassify both"):
    **multilevel SEM (COVERAGE #12)** is a research-flavored heavy lift (two-level SEM-GT; the
    paper's own multilevel estimator is Bayesian, not a plain lavaan model) — **moved to the
    cross-cutting "later" bucket beside the Bayesian engine**, not milestoned here.
    **lavaan + within-cell replicates (#7)** (SEM ∩ replicates) is niche/low-value — **dropped
    to ROADMAP unscheduled.** Both are re-tagged in COVERAGE.md and recorded in ROADMAP.md.
  - **Scope-outs preserved from the source milestones** (not rediscovered): the Wave-3
    **averaged `ICC(c,k)` incomplete divisor** (🟣 research, ADR-018/M9 §9) bounds M18 Slice 3
    to the subject level and is **not** part of this arc; **one-way via SEM** stays blocked
    (ADR-014); the four cross-cutting items stay deferred per STATUS.
- Consequences: On completion of M18–M21, every 🔵 not-yet gap in COVERAGE.md is closed and
  the only remaining unsupported combinations are the ⚫ by-design (undefined), 🟣 research
  (`ICC(c,k)` incomplete divisor), 🔴 blocked (one-way SEM), and the four cross-cutting
  "later" items — a clean, fully-annotated coverage surface. Risk is front-loaded away: M18–M20
  ride mature glmmTMB/lme4 machinery with reduction oracles; the heavier SEM parity is last and
  the heaviest SEM piece (multilevel SEM) is deliberately out. The arc is a **hypothesis, not a
  contract** (MILESTONES preamble) — reorders or a merge of M18/M19 (both mixed-model
  multilevel completeness) get a follow-up ADR. This ADR does **not** authorize code: M18 is
  scoped in full by its own ADR at its start after a short retro (brief §7).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + seeded recovery per
  slice), #2/#14 (name the estimand / detail a milestone at its start — this ADR only sets the
  arc), #5/#8 (fail-loudly classed guards for the ragged/fixed identifiability corners), #6
  (additive, non-breaking — new valid arg combinations only), #16 (tracking in-commit), #17
  (reclassified #12/#7 land in ROADMAP, not scope creep); ADR-017 (precedent: an arc-setting
  ADR with per-milestone detail ADRs to follow), ADR-008 (M3 k_eff/connectedness + Case-3A
  θ²_r under imbalance — M18/M19 reuse), ADR-011 (five-component multilevel fit), ADR-016/018
  (M8 nested / M9 incomplete crossed — M18/M19 extend), ADR-019 (M10 θ²_r multilevel),
  ADR-025 (M16 bootstrap seam — M21 Slice 1 + M18 `d_study` bands reuse), ADR-014 (M7 SEM
  engine + its fixed/incomplete/multilevel/one-way deferrals — M21 promotes fixed+incomplete,
  multilevel SEM & one-way SEM stay out), ADR-026 (M17 replicates + multilevel `d_study` +
  conflated — M18/M20 extend to incomplete/fixed/multilevel); estimand-specs
  `M17-conflated-icc.md §6`, `M17-within-cell-replicates.md §7`, `M9-incomplete-multilevel.md
  §9`, `M4.5-d-study.md`; `project/COVERAGE.md` (the inventory this arc closes),
  `project/ROADMAP.md` (parking lot for #12/#7); ten Hove, Jorgensen & van der Ark (2022);
  `CLAUDE_CODE_KICKOFF.md` §7 (detail a milestone at its start).

## ADR-028: M18 scope — Multilevel completeness I (crossed Design 1, incomplete corners)
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc was set by ADR-027; per PRINCIPLES.md #2/#14 and
  brief §7 each milestone is detailed by its own scoping ADR at its start (as ADR-018–022
  detailed the M9–M13 tail). This ADR opens **M18**, the first arc milestone: the ragged-data
  corners of the **crossed (Design 1) five-component** multilevel fit that M9/M10/M17 left open.
  Every M18 slice lands on a **single already-shipped abort guard** — the machinery to lift each
  one exists and is oracle-pinned elsewhere (M3 `k_eff`/connectedness, M10 `theta2r_fixed()`,
  M17 §7 multilevel `d_study`, M16 `simulate_refit`). This is **completeness, not new estimand
  work** (cf. M14/M15): additive, non-breaking (#6) — no new top-level argument, only new valid
  combinations of shipped arguments. Two scope decisions were put to the maintainer this session
  (Decision below).
- Decision:
  - **Four thin vertical slices** (#14), ordered by oracle-risk (bank the low-risk wins first):
    - **Slice 1 — incomplete fixed-rater crossed (COVERAGE #9).** Lift the `raters == "fixed"`
      abort in the ragged-crossed block (`R/icc.R`, ~L678). Reuses the M3 Case-3A `k_eff`
      harmonic divisor and the M10 engine-agnostic `theta2r_fixed()` bias-corrected θ²_r, now
      exercised **under imbalance** (the M10 §3/§7 deferral). No new estimand — θ²_r replaces
      σ²_r in the rater slot, on ragged data. Consistency ≡ random exactly; agreement differs by
      θ²_r. **Lowest risk** (both pieces shipped, only gated apart).
    - **Slice 2 — incomplete conflated ICC (COVERAGE #8).** Lift the `"conflated" %in% level`
      abort in the same ragged-crossed block (`R/icc.R`, ~L667). Opens the question
      `M17-conflated-icc.md §6` deliberately left closed: whether Eq. 14 (the ignore-clusters
      biased diagnostic) is well-posed on ragged data with a **flat** `k_eff` (harmonic mean of
      ratings per subject, clusters ignored — the single-level incomplete two-way divisor).
      **Risk posture (maintainer decision — "attempt, degrade to research if weak"):** attempt
      the flat-`k_eff` extension against the reduction + cross-engine oracles; **if no #1/#4-strong
      oracle holds, reclassify #8 to 🟣 research** (beside the `ICC(c,k)` incomplete divisor) and
      ship M18 without it rather than lower the oracle bar (#1). `verify-estimator` may recommend
      a Fable review (#19) if the characterization is close but unpinnable. Extends
      `M17-conflated-icc.md §6` with whatever the oracle work establishes (well-posed + divisor,
      or a recorded research deferral).
    - **Slice 3 — incomplete subject-level `d_study()` (COVERAGE #13).** Lift the incomplete-
      multilevel `d_study()` abort (`R/d-study.R`, ~L105) for the **subject level only**. Reuses
      the M17 §7 multilevel projection (moves only the averaging divisor). **Bounded to the
      subject level** (#18): the cluster level would hit the open 🟣 Wave-3 `ICC(c,k)`
      incomplete-divisor research item (ADR-018/M9 §9), so it stays deferred.
    - **Slice 4 — bootstrap-projected `d_study()` bands (COVERAGE #14).** The M16 deferral
      (ADR-025), **re-sliced out of ADR-027's Slice 3** (maintainer decision — "split"): it is
      orthogonal to crossed-incompleteness and applies **package-wide** (even simple two-way
      `d_study`). The shipped MC band reuses shared MC draws across `k`; the bootstrap band
      reprojects each M16 `simulate_refit` replicate's components at each `m`. New behaviour
      keyed off the fit's existing `ci_method`, not a new argument.
  - **No new estimand for Slices 1/3/4; Slice 2 is the only spec-touching slice** (extend
    `M17-conflated-icc.md §6`). No new estimand-spec files, no new dependency (light install
    intact).
  - **Oracle posture (#1), per slice — the established mixed-model pattern** (no textbook worked
    example, as M8–M10/M15): glmmTMB↔lme4 **cross-engine < 1e-4**, **reduction** to the shipped
    complete/balanced case (M10 balanced / M5 complete / M17 §7 at observed `k`), and **seeded
    population recovery** with MC-CI coverage. Slice 4's oracle is **coverage** + agreement with
    the MC band on interior cases within tolerance (the M16 O1/O2 pattern), diverging predictably
    at the boundary (#18).
  - **Scope-outs (preserved from source milestones, not rediscovered):** cluster-level `ICC(c,k)`
    on incomplete data stays 🟣 research (Wave 3, M9 §9) — bounds Slice 3; incomplete **nested**
    Designs 2/3 and **fixed-rater nested** are **M19**, not M18; ragged/fixed/multilevel
    **replicates** are **M20**; **SEM parity** is **M21**. `consistency`/`fixed` conflated stay
    ⚫/🟣 per COVERAGE §④.
- Consequences: On M18 close, COVERAGE #9/#13/#14 are ✅ and #8 is either ✅ or a **recorded 🟣
  research** reclassification (a clean, annotated outcome either way). The crossed Design-1 fit
  reaches full ragged parity with its balanced/complete self except the one 🟣 divisor. Risk is
  front-loaded: Slices 1/3/4 ride shipped, oracle-pinned machinery; Slice 2 is the only genuine
  characterization and is explicitly allowed to degrade rather than force an unsourced formula
  (#4). M18/M19 could still merge (both crossed/nested multilevel completeness) — a follow-up ADR
  if so. This ADR authorizes M18 code; M19 is scoped by its own ADR at its start (brief §7).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + seeded recovery per
  slice), #2/#14 (name the estimand / thin vertical slices), #4 (no guessed formula — Slice 2's
  degrade-to-research clause), #5/#8 (classed aborts for the ragged/fixed identifiability
  corners), #6 (additive, non-breaking), #16 (tracking in-commit), #18 (characterize the
  boundary — Slice 4 MC-vs-bootstrap divergence, Slice 3 subject-level bound), #19 (Fable
  recommendation path for Slice 2); ADR-027 (the arc this details; Slice 3/4 split amends its
  bundled Slice 3), ADR-008 (M3 `k_eff`/connectedness + Case-3A θ²_r — Slice 1), ADR-011
  (five-component multilevel fit), ADR-018 (M9 incomplete crossed + the `ICC(c,k)` §9 bound),
  ADR-019 (M10 `theta2r_fixed()` — Slice 1 under imbalance), ADR-025 (M16 `simulate_refit` /
  bootstrap — Slice 4), ADR-026 (M17 conflated + multilevel `d_study` — Slices 2/3 extend);
  estimand-specs `M17-conflated-icc.md §6` (Slice 2), `M4.5-d-study.md §7` (Slices 3/4),
  `M10-fixed-multilevel.md §3/§7` and `M9-incomplete-multilevel.md §9` (Slice 1 / the bound);
  `project/COVERAGE.md` §④ + `d_study` (#8/#9/#13/#14); ten Hove, Jorgensen & van der Ark (2022)
  Eqs. 12–14; McGraw & Wong (1996) Case 3/3A.

## ADR-029: M19 scope — Multilevel completeness II (nested Designs 2/3: incomplete + fixed-rater)
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc was set by ADR-027; per PRINCIPLES.md #2/#14 and brief §7
  each milestone is detailed by its own scoping ADR at its start (as ADR-028 detailed M18). This
  ADR opens **M19**, the second arc milestone: the **nested** designs' ragged and fixed-rater
  corners — bringing Designs 2/3 (raters nested in clusters / in subjects) up to the incomplete +
  fixed parity the crossed Design 1 reached in M9/M10/M18. Each slice lifts a **single shipped
  abort guard** onto machinery oracle-pinned elsewhere — the M3 `k_eff`/connectedness + M9
  identifiability gates (Slice 1) and the M10 engine-agnostic `theta2r_fixed()` (Slice 2) — as
  M18 did for the crossed corners. **Completeness, not new estimand work** (cf. M14/M15/M18):
  additive, non-breaking (#6) — no new top-level argument, only new valid combinations of the
  shipped `design` / `raters` / data-balance arguments. Three scope decisions were put to the
  maintainer this session (Decision below).
- Decision:
  - **Two thin vertical slices** (#14), ordered by oracle-risk (bank the lower-risk win first —
    but note M19 front-loads the harder characterization in Slice 1, unlike M18):
    - **Slice 1 — incomplete nested (COVERAGE #10).** Lift the `nested_design_balanced` abort in
      the nested block (`R/icc.R`, ~L596) for **Designs 2 and 3**. Reuses the M3 `k_eff`
      harmonic divisor + connectedness and the M9 identifiability gates on the shipped M8
      four-/three-component nested fits (no fit change). No new estimand — the M8 §3 signal/error
      map on ragged data. **Design detection on ragged data — explicit `design=` required
      (maintainer decision A):** when missing cells make the crossed-vs-nested pattern ambiguous
      (a rater can look cluster-confined only because its other cells are absent),
      `detect_multilevel_design()` aborts and the caller must declare
      `design = "nested_in_clusters"` / `"nested_in_subjects"` — never guessed (#5), consistent
      with the M9 crossed-vs-nested `design` escape hatch (ADR-018). **Averaged-coefficient risk
      posture — attempt, degrade if weak (maintainer decision B):** the single-rater
      `ICC_s(·,1)` rides the established reduction + cross-engine oracles; the averaged
      `ICC_s(·,k)` needs an effective-rater divisor (the subject-level ragged `k_eff` is the
      natural candidate but is unproven for the nested error structure). Attempt it against the
      reduction + cross-engine oracles; **if no #1/#4-strong oracle holds, reclassify the
      averaged nested-incomplete coefficient to 🟣 research** (beside the crossed `ICC(c,k)`
      incomplete divisor) and ship Slice 1 single-rater-only rather than lower the oracle bar
      (#1). `verify-estimator` may recommend a Fable review (#19) if close but unpinnable.
      Extends `M8-nested-multilevel.md §8` with whatever the oracle work establishes.
    - **Slice 2 — fixed-rater nested (COVERAGE #11).** Lift the `ml_design != "crossed"` abort in
      the fixed-rater multilevel branch (`R/icc.R`, ~L525) **for Design 2 only (maintainer
      decision C).** Places a finite-population **θ²_{r:c}** in the rater slot of the Design-2
      subject-level decomposition (M8 §3a). **Design 3 fixed-rater stays ⚫ by-design:** raters
      nested in subjects is the multilevel one-way (Eq. 11), the rater main effect is confounded
      into residual, so there is no separable rater effect to treat as fixed (cf. one-way fixed
      "not meaningful", M6 §10) — a classed `abort_unsupported` names it. Balanced/complete first
      (incomplete × fixed nested deferred — the M3 `k_eff` × per-cluster θ² interaction needs its
      own oracle, as M10 was to M9; guarded loudly).

      **Oracle-first catch (amends the scope assumption; #1/#18).** ADR-029 above assumed Slice 2
      would "reuse `theta2r_fixed()`" and that "consistency ≡ random, agreement differs by θ²_r vs
      σ²_{r:c} (zero on balanced data)" — the M10 crossed identity. **Two corrections established
      by oracle before shipping:** (a) `theta2r_fixed()` is *not* reused verbatim — raters nested
      in clusters have **no single common rater set**, so the fit is the cell-mean
      parameterization `score ~ 0 + rater + (1|cluster:subject)` and θ²_{r:c} is a **new helper
      `theta2r_fixed_nested()`** = the **mean over clusters** of each cluster's within-cluster
      bias-corrected finite-population rater variance (Case 3A *per cluster*; pooling all raters
      would conflate between-cluster rater location, confounded with the cluster main effect, with
      within-cluster spread). (b) **Fixed ≢ random even on balanced data** here — the nested finite
      population is per-cluster, so θ²_{r:c} (per-cluster, averaged) differs from the random pooled
      σ²_{r:c} (they coincide only as raters-per-cluster → ∞; observed |Δ| up to ~4e-3 across
      seeds). The M10 "balanced fixed ≡ random" pin therefore **does not apply**; the θ² pins are
      instead **per-cluster reduction** (θ²_{r:c} == mean of the flat M3 fixed θ²_r fit on each
      cluster's data alone — exact, ties to the sourced McGraw–Wong Case 3A estimand) and the
      **single-cluster reduction** to the flat M3 fixed components (exact). *Consistency ≡ random
      still holds exactly* (the rater term is unused). This is recorded in the fit-function
      comments and `data-raw/oracle-fixed-multilevel.R` (O-FNML).
  - **No new estimand for either slice; no new estimand-spec file** (extend the M8 §8 out-of-scope
    note into the shipped map). No new dependency (light install intact). No new argument — Slice 1
    reuses the shipped `design` arg, Slice 2 the shipped `raters = "fixed"`.
  - **Oracle posture (#1), per slice — the established mixed-model pattern** (no textbook worked
    example, as M8–M10/M15/M18): glmmTMB↔lme4 **cross-engine < 1e-4**; **reduction** to the
    shipped balanced/complete nested case (M8) and — Slice 2 — the θ² **per-cluster** and
    **single-cluster** reductions to the flat M3 fixed estimand (*not* balanced fixed≡random — see
    the catch above), with consistency ≡ random exact; **seeded population recovery** with MC-CI
    coverage; plus the M8 reductions (Design 3 → M6 one-way, Design 2 single-cluster → M1/M2
    two-way) surviving imbalance. lme4 degrades to glmmTMB at the variance boundary (ragged nested
    fits hit it more, as M15).
  - **Scope-outs (preserved, not rediscovered):** the averaged crossed cluster-level `ICC(c,k)`
    on incomplete data stays 🟣 research (Wave 3, M9 §9) and is **not** M19; Design 3 fixed-rater
    is ⚫ by-design (decision C); nested cluster-level IRR stays ⚫ (undefined for nested raters,
    ten Hove p. 6); ragged/fixed/multilevel **replicates** are **M20**; **SEM parity** is **M21**.
    The minimum-viable N_c / raters-per-cluster identifiability thresholds (M8 §7) are reused
    unchanged under imbalance.
- Consequences: On M19 close, COVERAGE #10 is ✅ (or its averaged coefficient a recorded 🟣
  research reclassification — a clean, annotated outcome either way) and #11 is ✅ (Design 2). The
  nested designs reach ragged + fixed parity with the crossed design except the same one 🟣
  divisor family. Risk is concentrated in Slice 1's averaged-nested divisor (the only genuine
  characterization, explicitly allowed to degrade rather than force an unsourced formula, #4);
  Slice 2 rides shipped M10 machinery. M18/M19 both being crossed/nested multilevel completeness,
  they could still have merged — kept separate per ADR-027/028 to keep slices thin. This ADR
  authorizes M19 code; M20 is scoped by its own ADR at its start (brief §7).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + seeded recovery per
  slice), #2/#14 (name the estimand / thin vertical slices), #4 (no guessed formula — Slice 1's
  degrade-to-research clause), #5/#8 (classed aborts for the ragged design-detection + Design-3
  fixed corners), #6 (additive, non-breaking), #16 (tracking in-commit), #18 (characterize the
  boundary — Slice 1 averaged divisor, lme4 singular degrade), #19 (Fable recommendation path for
  Slice 1); ADR-027 (the arc this details — M19 = nested completeness), ADR-028 (M18 precedent:
  guard-lift slices + attempt-then-degrade), ADR-008 (M3 `k_eff`/connectedness — Slice 1),
  ADR-011 (multilevel fit), ADR-016 (M8 nested designs — this extends), ADR-018 (M9 incomplete
  crossed + `design` escape hatch — Slice 1 reuses), ADR-019 (M10 `theta2r_fixed()` — Slice 2);
  estimand-spec `M8-nested-multilevel.md §3/§7/§8`, `M9-incomplete-multilevel.md §4a/§9`,
  `M10-fixed-multilevel.md §3`; `project/COVERAGE.md` (#10/#11); ten Hove, Jorgensen & van der
  Ark (2022) Eqs. 8–11, Table 3; McGraw & Wong (1996) Case 3/3A.

## ADR-030: M20 scope — Within-cell replicate completeness (fixed-rater, multilevel, ragged)
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc was set by ADR-027; per PRINCIPLES.md #2/#14 and brief §7
  each milestone is detailed by its own scoping ADR at its start (as ADR-028 detailed M18 and
  ADR-029 M19). This ADR opens **M20**, the third arc milestone: the within-cell replicate
  corners that **M17 Slice 3** left open. M17 shipped the two-way **random**, single-level,
  **balanced/complete** replicated design — splitting the confounded residual σ²_res into the
  subject×rater interaction σ²_sr and pure within-cell error σ²_e via `(1|subject:rater)`, with
  the per-component `error_divisors` generalization of `icc_point()` and the `occasions` knob
  (`M17-within-cell-replicates.md`). M20 extends that estimand to the three corners M17 §7
  deferred: **fixed raters**, **multilevel** data, and **ragged/incomplete** replicates. Each
  slice lifts a **single already-shipped abort guard** onto machinery oracle-pinned elsewhere —
  the M10 engine-agnostic `theta2r_fixed()` (Slice 1), the M5/M8 multilevel fits + the generic
  `*_ml_contract` (Slice 2), and the M3 `k_eff`/connectedness (Slice 3). This is **completeness,
  not new estimand work** (cf. M14/M15/M18/M19): additive, non-breaking (#6) — no new top-level
  argument, only new valid combinations of the shipped `raters` / `cluster` / `design` /
  `occasions` arguments and data balance. Three scope decisions were put to the maintainer this
  session (Decision below).
- Decision:
  - **Three thin vertical slices** (#14), **reordered from ADR-027's tentative
    ragged→fixed→multilevel listing to oracle-risk order** (maintainer decision — bank the
    established-machinery wins first, as M18 reordered its arc-tentative slices):
    - **Slice 1 — fixed-rater replicates (COVERAGE §② #5).** Lift the `raters == "fixed"` abort
      in the replicate block (`R/icc.R`, ~L680). New `fit_{glmmtmb,lme4}_replicates_fixed`
      (`score ~ 1 + rater + (1|subject) + (1|subject:rater)`) places the M10 bias-corrected
      finite-population **θ²_r** (via the shipped engine-agnostic `theta2r_fixed()`, read from the
      rater-contrast betas/vcov) in the rater slot of the M17 per-component error decomposition:
      agreement error `(θ²_r + σ²_sr)/n_r + σ²_e/(n_r·n_o)`, consistency `σ²_sr/n_r +
      σ²_e/(n_r·n_o)`. **No new estimand** — θ²_r replaces σ²_r in the M17 map. **Balanced/complete
      replicated, single-level** (ragged×fixed and multilevel×fixed replicates deferred — one
      imbalance/extension dimension at a time, as M10 was to M9). Consistency ≡ random exactly
      (rater term unused); **balanced fixed ≡ random** (θ²_r ≡ σ²_r on complete crossed data — the
      M10 single-level crossed identity applies, giving an *exact* reduction pin). **Lowest risk**
      (both pieces shipped, only gated apart).
    - **Slice 2 — multilevel replicates (COVERAGE §② #6), crossed Design 1 + nested Design 2
      (maintainer decision).** Lift the `multilevel` abort in the replicate block (`R/icc.R`,
      ~L672) for **Design 1 and Design 2**. Add the within-cell replicate term
      `(1|cluster:subject:rater)` to the shipped multilevel fits, splitting the M5/M8 residual
      σ²_res into the cluster:subject:rater interaction σ²_{csr} and pure error σ²_e (Design 1 →
      six components; Design 2 → five). New `fit_{glmmtmb,lme4}_multilevel_replicates` reusing the
      generic `*_ml_contract` (as the M17 single-level replicate fits do, ADR-026). The
      `occasions` facet reduces only the pure-error component by n_o; the M17 per-component
      `error_divisors` carry it. **Design 3 fixed ⚫ by-design does not arise, and Design 3
      replicate-split stays ⚫ by-design:** raters nested in subjects is the multilevel one-way
      (Eq. 11), rater confounded into residual, so there is **no separable subject:rater
      interaction to split** (cf. one-way replicate-split ⚫, COVERAGE §②; M6 §5) — a classed
      `abort_unsupported` names it. **Balanced/complete** (ragged×multilevel replicates deferred to
      Slice 3's ragged scope-out). Fixed×multilevel replicates deferred (Slice-1 scope-out).
    - **Slice 3 — ragged/incomplete replicates (COVERAGE §② #4).** Lift the `!replicates_uniform`
      abort (`R/icc.R`, ~L687) for the **two-way random, single-level** design — the replicate
      analogue of M3. The **single-occasion** ICC family extends first (the interaction fit
      tolerates ragged data; the rater divisor is the shipped `k_eff` = harmonic mean of *distinct*
      raters per subject; σ²_sr needs the M3-connected subject×rater graph, already gated). **The
      occasion-averaged coefficient — attempt, degrade to research (maintainer decision, matching
      M18 Slice 2 / M19 Slice 1):** `occasions = "average"` on ragged data needs an **effective-n_o
      divisor** (the harmonic mean of ratings per cell is the natural candidate but is unproven);
      attempt it against the reduction (uniform ragged → M17 balanced) + cross-engine oracles, and
      **if no #1/#4-strong oracle holds, ship the single-occasion ragged family only and reclassify
      occasion-averaged-ragged to 🟣 research** (beside the crossed `ICC(c,k)` incomplete divisor)
      rather than lower the oracle bar (#1). `verify-estimator` may recommend a Fable review (#19)
      if close but unpinnable. **Scope-out:** ragged × {fixed, multilevel} replicates stay deferred
      (compound imbalance — its own later corner, as ragged×fixed nested was for M19).
  - **No new estimand for any slice; no new estimand-spec file.** M20 extends the shipped M17
    estimand (`M17-within-cell-replicates.md`) to the deferred corners; the ragged
    occasion-averaged §7 note is extended with whatever the Slice-3 oracle work establishes
    (effective-n_o divisor, or a recorded 🟣 research deferral). **No new dependency** (light
    install intact). **No new argument** — Slices reuse the shipped `raters = "fixed"` (S1),
    `cluster`/`design` (S2), and data balance + `occasions` (S3).
  - **Oracle posture (#1), per slice — the established mixed-model pattern** (no textbook worked
    example, as M8–M10/M15/M18/M19): glmmTMB↔lme4 **cross-engine < 1e-4**; **reduction** to the
    shipped M17 balanced/complete replicate case and — via aggregation to cell means — to the
    single-occasion parent (M3 incomplete two-way for S3; M10/M3 fixed for S1; M5/M8 multilevel
    for S2); **seeded population recovery** with MC-CI coverage; the invariant σ²_sr + σ²_e ≈
    σ²_res (and σ²_{csr} + σ²_e ≈ the M5/M8 residual for S2). Slice 1 adds the **exact balanced
    fixed ≡ random** pin and, where balanced, the two-way-with-replication ANOVA mean-squares as
    an independent method; Slice 3's averaged divisor is the one genuine characterization,
    explicitly allowed to degrade (#4). lme4 degrades to glmmTMB at the variance boundary (ragged
    replicate fits hit it more, as M15).
  - **Scope-outs (preserved, not rediscovered):** ragged × fixed and ragged × multilevel
    replicates (compound imbalance — later corners); **Design 3 replicate-split** ⚫ by-design
    (multilevel one-way, no separable interaction); **one-way replicate-split** stays ⚫
    (COVERAGE §②); the **occasion `d_study()`** projecting n_o (M17 §7 — the per-component divisor
    supports it, but projecting occasions stays deferred); **SEM ∩ replicates** stays ROADMAP
    unscheduled (reclassified out of the arc, ADR-027); **SEM parity** is **M21**. The Wave-3
    averaged crossed `ICC(c,k)` incomplete divisor (🟣 research, M9 §9) is untouched.
- Consequences: On M20 close, COVERAGE §② is fully annotated — fixed-rater, multilevel (crossed
  Design 1 + nested Design 2), and single-occasion ragged replicates ✅ (with the occasion-averaged
  ragged form either ✅ or a recorded 🟣 research reclassification — a clean outcome either way),
  and only the compound-imbalance corners + Design-3/one-way ⚫ by-design + SEM (ROADMAP) remain.
  Risk is front-loaded away: Slice 1 rides shipped M10 θ²_r with an exact reduction pin, Slice 2
  is a new fit shape but with clean reductions to M17/M5/M8, and the one genuine characterization
  (Slice 3's effective-n_o divisor) is last and explicitly allowed to degrade rather than force an
  unsourced formula (#4). The arc is a **hypothesis, not a contract** (MILESTONES preamble). This
  ADR authorizes M20 code; M21 (SEM parity) is scoped by its own ADR at its start (brief §7).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + seeded recovery per
  slice), #2/#14 (name the estimand / thin vertical slices), #4 (no guessed formula — Slice 3's
  degrade-to-research clause), #5/#8 (classed aborts for the Design-3 replicate-split + ragged
  compound corners), #6 (additive, non-breaking — new valid arg combinations only), #16 (tracking
  in-commit), #18 (characterize the boundary — Slice 3 averaged divisor, lme4 singular degrade),
  #19 (Fable recommendation path for Slice 3); ADR-027 (the arc this details — M20 = replicate
  completeness), ADR-028/029 (M18/M19 precedent: guard-lift slices + attempt-then-degrade +
  oracle-risk reorder), ADR-026 (M17 replicates + per-component `error_divisors` + `occasions` +
  the `*_ml_contract` reuse — this extends), ADR-019 (M10 `theta2r_fixed()` — Slice 1), ADR-011
  (M5 five-component multilevel fit — Slice 2), ADR-016 (M8 nested Design 2 fit — Slice 2),
  ADR-008 (M3 `k_eff`/connectedness — Slice 3); estimand-spec `M17-within-cell-replicates.md`
  §2/§4/§7 (the deferrals this closes), `M3-incomplete-designs.md` (Slice 3 parent),
  `M10-fixed-multilevel.md` §3 (Slice 1 θ²_r), `M5-multilevel.md`/`M8-nested-multilevel.md` §3
  (Slice 2); `project/COVERAGE.md` §② (#4/#5/#6); Shrout & Fleiss (1979), McGraw & Wong (1996)
  Case 3/3A, Brennan (2001) two-facet decision study.

## ADR-031: M21 scope — SEM (lavaan) engine parity (bootstrap, fixed-rater, incomplete/FIML)
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc was set by ADR-027; per PRINCIPLES.md #2/#14 and brief §7
  each milestone is detailed by its own scoping ADR at its start (as ADR-028/029/030 detailed
  M18/M19/M20). This ADR opens **M21**, the arc's **last** milestone: bringing the **lavaan (SEM)
  engine** up toward the design parity the **lme4** engine reached over M5.5→M14→M15. M7 (ADR-014)
  shipped lavaan for the **random two-way, balanced/complete** path only — **consistency** ≡
  glmmTMB exactly (a variance ratio off the one-factor fit), **absolute agreement** via the
  Jorgensen (2021, Eq. 6) SEM indicator-mean estimator σ²_r = Σν²/(k−1) (a *distinct*,
  asymptotically-equivalent estimator, externally validated by Vispoel et al. 2022), reusing the
  Monte-Carlo `ci_method` through lavaan's native `vcov()`; every other design cell aborts
  `abort_unsupported()`. M21 promotes the three lavaan deferrals ADR-014 recorded — bootstrap
  intervals, fixed raters, and incomplete/FIML — leaving multilevel SEM and one-way SEM out (both
  reclassified/blocked below). This is **engine parity, not new estimand work** (cf. M5.5/M7/M14/
  M15): additive, non-breaking (#6) — no new top-level argument, only new *valid combinations* of
  the shipped `engine = "lavaan"` with the shipped `ci_method` / `raters` / data-balance arguments.
  Risk is deliberately last in the arc (ADR-027): the SEM engine estimates variances on the **raw
  scale** (Heywood/negative-variance boundary, unlike glmmTMB's log-SD safety, #3) and its
  agreement estimator is a different estimator from the mixed-model σ²_r, so the oracle bar is
  cross-engine-asymptotic, not ≤1e-4-exact, for agreement. Two scope questions were put to the
  maintainer this session (Decision below).
- Decision:
  - **Three thin vertical slices** (#14), **kept in ADR-027's tentative order** (maintainer
    decision — the order already matches oracle-risk: reuse the shipped bootstrap seam first, land
    the heaviest FIML oracle work last):
    - **Slice 1 — lavaan bootstrap `ci_method` (COVERAGE §③ #3).** Lift the `engine == "lavaan"`
      restriction in the M16 bootstrap dispatch so `ci_method = "bootstrap"` works for the SEM
      engine. Add a **`lavaan_simulate_refit`** factory to the M16 engine-level `simulate_refit()`
      contract (ADR-025) — a **parametric** bootstrap (simulate from the fitted lavaan model →
      refit → recompute the ICC per replicate → percentile interval), mirroring
      `glmmtmb_simulate_refit` / `lme4_bootmer_refit`; the per-replicate component extractor is the
      shipped lavaan `to_components`, so `icc_point()` maps to the ICC identically. **No new
      estimand, no new argument** (`boot_samples` is shipped). **Lowest risk** (the seam and the
      point estimator both ship — only the lavaan refit factory is new). **Random two-way only** at
      this slice (fixed/incomplete arrive in Slices 2/3).
    - **Slice 2 — fixed-rater SEM (COVERAGE §③ #1).** Lift the `raters == "fixed"` lavaan abort for
      the two-way path. Consistency ≡ random exactly (rater not in the error set). **Oracle-first
      catch (to resolve in-slice, not assumed — cf. the M19 fixed≢random catch, #1):** M7's
      *random* agreement estimator σ²_r = Σν²/(k−1) already reads the rater variance from the
      **mean structure of a finite set of indicator intercepts** — arguably already a
      finite-population quantity — so whether fixed-rater SEM agreement needs a *distinct* θ²_r
      correction (the mixed-model σ²_r→θ²_r story) or **coincides with the shipped M7 agreement
      estimator** is an open question pinned by oracle before shipping: reduction to the single-
      level M3/M10 fixed θ²_r via cell means, cross-engine vs. glmmTMB's Case-3A fit, and the
      MW/SF fixed-agreement crosswalk. If the two coincide, the slice is a label/validation layer;
      if they differ, the difference is oracle-pinned. `verify-estimator` may recommend a Fable
      review (#19) if the fixed-agreement estimator is close but unpinnable. **Balanced/complete,
      single-level.**
    - **Slice 3 — incomplete / FIML SEM (COVERAGE §③ #2).** Lift the `engine == "lavaan" &&
      !balanced` abort. lavaan handles missing subject×rater cells via **FIML** (`missing =
      "fiml"`) on the wide reshape — no new fit shape, a fit-option change plus the M3-style
      identifiability/connectedness guard reused before dispatch (#5). **Consistency** is a
      variance *ratio* → **estimator-invariant**, so it stays an **exact cross-engine pin** even on
      ragged data (asymptotically). **Absolute agreement — attempt, degrade to research (maintainer
      decision, matching M18 Slice 2 / M20 Slice 3):** FIML-SEM agreement agrees with the REML
      mixed-model only **asymptotically**, so a hard ≤1e-4 cross-engine pin on ragged data is
      unlikely; attempt full FIML agreement against the reduction (complete → M7) + seeded-recovery
      + cross-engine (≤1e-3) oracles, and **if no #1/#4-strong oracle holds, ship FIML consistency
      only and reclassify FIML absolute-agreement to 🟣 research** rather than lower the oracle bar
      (#1/#4). `verify-estimator` may recommend a Fable review (#19). **Heaviest oracle work — last
      by design.**
  - **No new estimand for any slice; no new estimand-spec file** (engine parity — cf.
    M5.5/M7/M14/M15). The one item that touches spec prose is a **FIML-SEM oracle note** appended
    to the M7 record / `REFERENCES.md` (an engine oracle, not an estimand — as ADR-027 anticipated),
    recording whatever the Slice-3 oracle work establishes (exact FIML consistency; FIML agreement
    either pinned or a 🟣 research deferral). **No new dependency** (lavaan stays `Suggests`, light
    install intact — lavaan's `simulateData`/parametric bootstrap and FIML are native, no companion
    package). **No new argument** — Slices reuse the shipped `ci_method = "bootstrap"` (S1),
    `raters = "fixed"` (S2), and data balance (S3) with `engine = "lavaan"`.
  - **Oracle posture (#1) — glmmTMB the independent oracle, exactly as M7 (no textbook worked
    example beyond Jorgensen 2021 for the base estimator):** consistency is pinned **exact**
    (≤1e-4) cross-engine at every slice (the ratio is estimator-invariant); **agreement** is pinned
    at the **SEM indicator-mean estimator's** own bar — the exact Σν²/(k−1) formula reproduced
    in-test, seeded large-N recovery where lavaan → population and lavaan ≈ glmmTMB, and (S1) the
    M16 coverage + MC-agreement oracles, (S2) the fixed reduction/crosswalk, (S3) the asymptotic
    FIML agreement (attempt-then-degrade). **Boundary-awareness (#3) is a named risk per slice:** a
    Heywood/singular/non-convergent lavaan fit that cannot yield a valid interval aborts loudly
    (classed) and directs the user to `engine = "glmmTMB"` — the shipped M7 posture, exercised
    harder by bootstrap refits (S1) and ragged FIML (S3).
  - **Scope-outs (preserved, not rediscovered):** **multilevel SEM** (COVERAGE #12) stays in the
    cross-cutting "later" bucket beside the Bayesian engine (two-level SEM-GT is research-flavored;
    the paper's own multilevel estimator is Bayesian — reclassified out of the arc by ADR-027, not
    milestoned here); **SEM ∩ within-cell replicates** (#7) stays **ROADMAP unscheduled** (niche,
    reclassified by ADR-027); **one-way / general ICC(1) via SEM** stays **🔴 blocked** — no
    faithful sourced SEM route (ADR-014); the four cross-cutting "later" items (Bayesian
    `ci_method = "posterior"`, categorical/ordinal GLMM, non-parametric/profile-likelihood CIs,
    lme4 singular/merDeriv edge cases) stay deferred per STATUS. **Fixed × incomplete SEM** and any
    compound corner are deferred (one dimension at a time — as M10 was to M9): S2 is
    balanced/complete, S3 is random.
- Consequences: On M21 close, **every 🔵 not-yet gap in COVERAGE.md is closed** and the arc
  (ADR-027) is complete — the lavaan engine covers the random two-way path with both `ci_method`s,
  fixed raters, and incomplete/FIML data (agreement possibly 🟣 for FIML), and the only remaining
  unsupported combinations across the whole package are the ⚫ by-design (undefined), 🟣 research
  (crossed `ICC(c,k)` incomplete divisor; possibly FIML agreement; occasion-averaged ragged
  replicates), 🔴 blocked (one-way SEM), and the four cross-cutting "later" items — a clean,
  fully-annotated coverage surface. Risk stayed front-loaded away (ADR-027): S1 rides the shipped
  M16 seam, S2's only genuine question (fixed vs. random SEM agreement) is oracle-pinned with a
  Fable fallback, and the one asymptotic characterization (S3 FIML agreement) is last and allowed
  to degrade rather than force an unsourced pin (#4). The arc is a **hypothesis, not a contract**
  (MILESTONES preamble) — a merge or reorder of slices gets a follow-up note. This ADR authorizes
  M21 code.
- References: PRINCIPLES.md #1 (oracle-first — cross-engine consistency-exact + agreement at the
  SEM estimator's bar + seeded recovery per slice), #2/#14 (name scope / thin vertical slices —
  this details the arc's last milestone), #3 (boundary-aware — the lavaan raw-scale Heywood risk),
  #4 (no guessed formula — S3 FIML-agreement degrade-to-research clause), #5/#8 (classed aborts for
  the fixed/incomplete identifiability + Heywood corners), #6 (additive, non-breaking — new valid
  arg combinations only), #16 (tracking in-commit), #18 (characterize the boundary — S1 bootstrap
  refits + S3 ragged FIML at the Heywood boundary), #19 (Fable recommendation path for S2/S3);
  ADR-027 (the arc this details — M21 = SEM parity, the last milestone; multilevel SEM & SEM∩
  replicates reclassified out here), ADR-014 (M7 SEM engine + its bootstrap/fixed/incomplete/
  multilevel/one-way deferrals — M21 promotes bootstrap+fixed+incomplete, leaves multilevel & one-
  way out), ADR-025 (M16 bootstrap `simulate_refit` seam — S1 reuses), ADR-012 (M5.5 lme4-parity
  precedent: promote an oracle engine to selectable across designs), ADR-008 (M3 k_eff/
  connectedness — S3 identifiability guard), ADR-019 (M10 θ²_r — S2 fixed reduction); Jorgensen
  (2021, *Psych* 3:113–133, Eq. 6), Vispoel, Hong, Lee & Xu (2022), Lee & Vispoel (2024); Efron &
  Tibshirani (1993) (S1 bootstrap); `project/COVERAGE.md` §③ (#1/#2/#3), `REFERENCES.md` O-SEM.

## ADR-032: M22 scope — `d_study()` projection off a within-cell replicate fit
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc (ADR-027) closed every 🔵 *not yet* gap in `COVERAGE.md`; no
  milestone is in flight. This ADR opens **M22**, a small standalone milestone promoting the one
  deferred `d_study()` corner recorded across M17 §7 / M20 (COVERAGE `d_study()` table, "projection
  off a replicate fit — 🔵 not yet"). Within-cell replicate fits (M17 Slice 3; M20 Slices 1–2)
  split the confounded residual σ²_res into the subject×rater interaction σ²_sr and pure within-cell
  error σ²_e via `(1|subject:rater)`, so a rater-count projection needs **per-component error
  divisors**: the rater and interaction terms divide by the projected raters `m`, pure error by
  `m · n_o` (the occasion count held at the fitted value). M17 already generalized `icc_point()` to
  carry `error_divisors` and `icc_estimand()` already resolves them for a numeric `unit = m` with
  `replicates = TRUE` (`estimand.R`), so the **projection estimand blocker the ROADMAP recorded is
  already resolved** — the remaining work is confined to `d_study()`, which currently refuses every
  replicate fit with a blanket `abort_unsupported`. **Completeness, not new estimand work** (cf.
  M14/M15/M18–M21): additive, non-breaking (#6) — no new argument, dependency, or estimand-spec
  file; only new valid inputs to `d_study()`. The maintainer chose to do **both** the single-level
  and multilevel replicate projections, **split into two slices**, tracked as a milestone with this
  scoping ADR (brief §7).
- Decision:
  - **Two thin vertical slices** (#14), single-level first (lowest risk — the estimand is the
    shipped M17 single-level replicate map at a projected divisor):
    - **Slice 1 — single-level replicate projection.** Lift the blanket replicate abort in
      `d_study()` for a **two-way, single-level, balanced/complete** replicate fit (random
      agreement/consistency; **fixed consistency** projects via Spearman–Brown; **fixed absolute
      agreement** stays refused by the shipped `abort_fixed_agr_projection`, θ²_r being a
      finite-population variance). Thread `replicates`/`occasions` into the `d_study()` estimand
      builder; the estimand is `icc_estimand(type, unit = m, raters, replicates = TRUE,
      occasions = o)` with `o` each distinct occasion setting on the fit (numeric divisor). The
      result gains an **`occasions` column** (paralleling the multilevel `level` column), one
      reliability curve per occasion setting; the rater count `m` is projected, the occasion count
      `n_o` is **held fixed** (an occasion `d_study()` is a separate deferred facet, M17 §7). Guard
      the two compound corners with classed aborts (#5): **multilevel** replicate fits (→ Slice 2)
      and **ragged/incomplete** replicate fits (the occasion-averaged ragged divisor is itself 🟣
      research, M20/ADR-030).
    - **Slice 2 — multilevel replicate projection.** Lift the Slice-1 multilevel guard for **crossed
      Design 1 and nested Design 2** balanced/complete replicate fits (the M20 Slice 2 shapes),
      projecting the **subject** level across the level × occasions × `m` grid; the **cluster** level
      is single-occasion only (occasion averaging touches pure error, which is not in the cluster
      error set — a no-op there, mirroring `icc()`), and the incomplete-cluster drop-with-note is
      unreachable (ragged replicate fits are aborted). Design 3 (multilevel one-way) has no
      replicate split, so no Design-3 replicate fit exists to project (⚫ by-design upstream).
  - **No new estimand, estimand-spec file, argument, or dependency.** M22 extends the shipped M17
    projection estimand to replicate fits (`M17-within-cell-replicates.md §7` and
    `M4.5-d-study.md §7` notes updated); the `occasions` output column reuses the existing per-fit
    `occasions` divisor.
  - **Oracle posture (#1), the established mixed-model pattern** (no textbook worked example, as
    M8–M10/M15/M18–M21): **O-RepDS-reduction** — at `m = k_eff` (the distinct-rater divisor) each
    occasion (and level) curve equals the fitted `icc()` `ICC(*,k)` row to < 1e-4; **O-RepDS-lme4**
    — the projected curve equals one from an independent `lme4` replicate fit (cross-engine);
    **O-RepDS-SB** — consistency projection equals Spearman–Brown of that fit's `ICC(C,1)`;
    **invariants** — monotone increasing in `m`, in [0, 1], occasion-averaged curve ≥ single-occasion
    at equal `m` (averaging only cuts pure error); **O-RepDS-sim** — a seeded fit recovers the
    population Φ(m) at an `m` not run and the MC band covers it.
  - **Scope-outs (preserved, not rediscovered):** the **occasion `d_study()`** projecting `n_o` (M17
    §7 — the per-component divisor supports it, but projecting occasions stays deferred); **ragged ×
    replicate** projection (the occasion-averaged ragged divisor is 🟣 research, M20/ADR-030);
    **fixed × multilevel** replicate fits (never fitted, M20 Slice-1 scope-out); **SEM ∩ replicates**
    (ROADMAP unscheduled, ADR-027). Untouched arc carry-overs stay in `ROADMAP.md`.
- Consequences: On M22 close the `COVERAGE.md` `d_study()` table's last 🔵 (projection off a
  replicate fit) becomes ✅ for the single-level and multilevel (crossed D1 + nested D2)
  balanced/complete corners, with the occasion projection and ragged-replicate projection recorded
  as deferred. Risk is front-loaded away: Slice 1 rides the shipped M17 `error_divisors` estimand
  with an exact reduction pin, and Slice 2 is the same divisor change over the M20 multilevel
  replicate fit with clean per-level/occasion reductions. This ADR authorizes M22 code.
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + Spearman–Brown + seeded
  recovery), #2/#14 (name the estimand / thin vertical slices), #5/#8 (classed aborts for the
  ragged/multilevel replicate-projection corners + fixed-agreement), #6 (additive, non-breaking —
  new valid `d_study()` inputs only), #16 (tracking in-commit), #18 (characterize the boundary —
  the occasion facet held fixed); ADR-026 (M17 replicates + per-component `error_divisors` — the
  estimand this projects), ADR-030 (M20 replicate completeness — fixed/multilevel/ragged fits this
  projects off; the ragged occasion-averaged 🟣 research it defers around), ADR-010 (M4.5 `d_study()`
  — the projection machinery this extends), ADR-028 (M18 Slice 3/4 `d_study()` guard-lift precedent
  — incomplete subject-level + bootstrap bands); estimand-spec `M17-within-cell-replicates.md §7`
  (the deferral this closes), `M4.5-d-study.md §7` (projection scope); Brennan (2001) two-facet
  decision study; `project/COVERAGE.md` `d_study()` table.

## ADR-033: M23 scope — Bayesian engine (brms) + `ci_method = "posterior"`, two-way random
- Date: 2026-07-08
- Status: accepted
- Context: The M18–M21 completeness arc (ADR-027) closed and M22 (ADR-032) shipped; no milestone is
  in flight. This ADR opens **M23**, the **first Bayesian milestone** — the largest remaining
  carryover, deferred at M7 (ADR-014) and tracked in `ROADMAP.md` as *ready to schedule whenever
  prioritized* (not blocked: the engine × design dispatch seam from M5.5/M7 and the multi-method
  `ci_method` seam from M16/ADR-025 were built for exactly this). It is a **thin two-way-random
  slice** mirroring the first engine milestones M5.5 (lme4) and M7 (lavaan): prove the engine and
  the new interval method end-to-end on the two-way random path, then defer parity (fixed, one-way,
  multilevel, incomplete, replicates) to follow-on milestones. **Engine + interval method, not new
  estimand work** (cf. M5.5/M7/M16): additive, non-breaking (#6) — no new estimand-spec file; new
  valid values of the shipped `engine` and `ci_method` arguments.
  A source review (this session) confirmed the estimation recipe against the primary Bayesian
  source. **ten Hove, Jorgensen & van der Ark (2020)** — *Comparing Hyperprior Distributions to
  Estimate Variance Components for IRR Coefficients* — is a hyperprior **simulation study** (no
  single worked-example ICC to reproduce), which fits the M23 posture since a CI method's oracle is
  **coverage** (#1). It fixes the exact prior (§4.1: **half-*t*(4, 0, 1) on every random-effect
  *SD***), the model (Eq. 1–3, two-way crossed random, interaction+error confounded into σ²_sr — the
  M1/M2 family Table 1), and reports (§4.2, Figs 1–5) that the **posterior mode (MAP) is unbiased for
  σ_r and ICC(A,1) at k > 2 while the posterior mean (EAP) severely overestimates σ_r**, and that
  **percentile** BCIs (not HPDIs) give nominal coverage at k > 2. The later **ten Hove et al. (2022)**
  *Updated Guidelines* paper corroborates the backend and philosophy without revisiting hyperpriors:
  its own companion software (OSF `8j26u`) estimates the ICCs via **`brms`** (Bürkner 2017) and lme4,
  reports MCMC and MLE yield **similar point estimates**, and endorses **Monte-Carlo CIs for ICCs**
  because they are non-normal functions of parameters (verbatim the ADR-003 / #3 rationale) — and it
  flags the best estimator for *incomplete/small-k* designs as an **open research question**
  (relevant to the deferred Bayesian-incomplete/multilevel milestones, not M23).
- Decision:
  - **Backend: `brms`** (a new `Suggests`, behind `rlang::check_installed()` — the ADR-002
    light-install pattern; base install unchanged), rstan backend for a CRAN-clean dependency.
    Chosen over rstanarm because rstanarm's `decov` prior cannot express ten Hove's per-SD
    half-*t* even in the two-way case, which would forfeit the source-faithful prior; **rstanarm**
    is parked as a possible future alternate backend (ROADMAP). Selector value **`engine = "brms"`**
    (package-named, consistent with `glmmTMB`/`lme4`/`lavaan`; leaves `engine = "rstanarm"` open).
  - **Prior (sourced, #12): half-*t*(4, 0, 1) on all random-effect SDs** —
    `brms::set_prior("student_t(4, 0, 1)", class = "sd")` (brms positive-truncates SD priors → the
    half-*t*), per ten Hove 2020 §3.3/§4.1. df = 4 is their deliberate choice for variance params
    near the zero boundary (Gelman 2019) — Principle #3's exact regime. **No user-exposed `prior=`
    control in M23** (fixed sourced default; a prior-tuning API is deferred).
  - **`ci_method = "posterior"` — a third interval method through the M16 seam.** Added to the
    `validate_choice` set in `R/icc.R`; a new `R/ci-posterior.R` derives the interval from the fit's
    native posterior draws. The **interval is the percentile credible interval**, reusing M16's
    `bootstrap_interval()` percentile reduction verbatim (sourced-optimal over HPDI per ten Hove 2020
    §4.2). **Coupling: forced-default and Bayesian-only** — a Bayesian fit defaults to and requires
    `"posterior"`; `"posterior"` on a non-Bayesian engine and `montecarlo`/`bootstrap` on a Bayesian
    fit both `abort` with a classed, teaching message (#5/#8). A **selectable** coupling (also
    allowing MC/bootstrap on a Bayesian fit for method comparison) is parked.
  - **Point estimate: MAP (posterior mode), computed from the ICC draws.** Because the mode is not
    transform-invariant (`MAP(ICC) ≠ icc_point(MAP components)`), the point is the mode of each
    estimand's posterior ICC-draw vector — so for the Bayesian engine **both point and interval come
    from the same draw matrix** (a `posterior_summary()` returning point + interval together), a
    small restructure of the `points`/`intervals` split in `R/icc.R` for this branch only; the shared
    `icc_point()` path is untouched for the other engines. The EAP (mean) is **not** used (ten Hove
    2020: biased).
  - **Mode estimator: a hand-rolled, boundary-aware `posterior_mode()`** — no new dependency
    (light-install ethos; the house style of `rmvn()`/`with_rng_seed()`). A reflected KDE
    (`stats::density` with reflection at finite bounds; one helper serving both the [0, 1] ICCs and
    the [0, ∞) variance components via `lower`/`upper`) with an **a-priori-fixed bandwidth rule**
    (stated in code). **Guardrail (#4):** the bandwidth/boundary spec is fixed *before* comparison and
    the ten Hove 2020 reproduction is treated as **validation, not a tuning target** — if the pinned
    estimator does not reproduce their MAP bias/coverage within tolerance, that is a reported finding,
    not something to tune away. An independent estimator converging on their numbers is a *stronger*
    oracle than re-running their own `modeest` tool (near-tautological); `modeest`/`bayestestR` are
    noted as validated-alternative paths, not adopted.
  - **Engine contract:** the shared six-field contract plus **one new field**, a matrix of
    internal-scale component posterior draws (`estimate`/`vcov` still filled from the posterior for
    completeness, but the interval and point come from the draws, not the normal approximation).
  - **Scope: two-way random only** — agreement + consistency, single + average (ICC(A,1)/(A,k)/
    (C,1)/(C,k), the M1/M2 family, single replicate). A **soft `cli` note when k = 2** surfaces ten
    Hove 2020's bias/undercoverage caveat (#13). `d_study()` and the M11 `autoplot()` ride the
    existing draws/`mc` slots unchanged where applicable.
  - **Two thin vertical slices** (#14/#15):
    - **Slice 1 — engine + `posterior_summary()` wired end-to-end.** `fit_brms_twoway()` returns the
      contract + draws with the sourced half-*t* prior; `posterior_mode()` + `posterior_ci()`
      (percentile) in `R/ci-posterior.R`; the `"posterior"` branch and forced-default/Bayesian-only
      coupling with classed aborts in `R/icc.R`; print/tidy report a **credible** interval,
      `ci$method = "posterior"`, `samples` = post-warmup draws; `check_installed("brms")` gating; the
      k = 2 note.
    - **Slice 2 — reproducibility + the coverage oracle (O-Bayes).** Seeded MCMC (`seed=` → Stan's
      seed) for reproducible intervals; convergence checks (R-hat < 1.10, bulk-ESS) as ten Hove did.
      A **`data-raw/` script** reproduces ten Hove 2020's DGP (N = 30, σ²_s = σ²_sr = 0.5,
      σ²_r ∈ {.01, .04}, k ∈ {2, 3, 5}) with brms + the half-*t* prior and **pins the committed
      reference values** (#4) against their published tables (OSF `shkqm`); the brms model/prior
      parameterization is cross-checked against the 2022 companion brms code (OSF `8j26u`).
  - **Oracle posture (#1), a CI method's oracle is coverage** (M16 precedent): **O-Bayes-coverage** —
    seeded-simulation coverage ~nominal at the ten Hove DGP, MAP unbiased and percentile-BCI coverage
    nominal at k > 2, reproducing their reported findings within a stated tolerance (committed
    reference, #4); **O-Bayes-crossimpl** — our brms + half-*t* reproduces the source's own rstan
    results (independent implementation, not tautology); **O-Bayes-agree** — MAP ≈ glmmTMB/lme4 REML
    point within a **stated tolerance** (corroborated by ten Hove 2022's "MCMC ≈ MLE point
    estimates"); **O-Bayes-converge** — 100% convergence at the DGP (their finding).
  - **CI test-gating (DoD):** the coverage/agreement oracle runs off the **committed seeded
    reference** everywhere (#4); a **single live `brms` fit** on one representative matrix job with
    tiny `chains`/`iter` exercises the real wiring; `skip_on_cran` + `skip_if_not_installed("brms")`
    keep per-model Stan compilation out of all nine matrix cells and off CRAN. brms is fit with its
    defaults for production; tests use reduced draws.
  - **No new estimand, estimand-spec file, or user-facing argument** (new *values* of `engine` and
    `ci_method` only). One new `Suggests` (`brms`); one new field on the engine contract; a new
    `R/ci-posterior.R` and `R/engine-brms.R`.
    - **Amendment (2026-07-08, Slice 1, maintainer decision):** M23 adds **one** new user-facing
      argument after all — **`brm_args = list()`**, a brms-scoped passthrough forwarded to
      `brms::brm()` (backend, chains, iter, cores, control, …). This supersedes the original "no
      new user-facing argument" and "rstan backend only" language: the default is still rstan and
      brms's defaults (so `brm_args` is unneeded for the common path), but the user can now override
      the **backend** (e.g. `backend = "cmdstanr"` — faster compile, no Rtools on Windows) and any
      sampler knob without us modeling backends, since nothing in the engine branches on the backend
      (`brm()` returns a `brmsfit` and every extraction is backend-agnostic). A dedicated `backend`
      argument and a raw `...` on `icc()` were both rejected — `...` on the single public entry
      would silently swallow typos for **all** engines (violates #5, fail-loudly). `brm_args` is a
      single named, greppable, brms-only argument; it aborts (classed) if set for a non-brms engine,
      and it may **not** set `formula`/`data`/`prior`/`seed` (the model, the **sourced half-*t*
      prior** #12, and the Stan seed are `intraclass`'s to own) — those collisions abort too. The
      **`prior=`** API stays deferred (the half-*t* is fixed and not user-overridable in M23).
  - **Scope-outs (preserved, not rediscovered):** Bayesian **fixed-rater** (Case-3A θ²_r) and
    **one-way** (single-level parity — a follow-on, the M14 analog); Bayesian **multilevel** Designs
    1–3 (the **highest-value** follow-on — ten Hove's native estimator is Bayesian; its own turf) and
    Bayesian **incomplete/ragged** and **within-cell replicates** (all deferred, and per ten Hove
    2022 the estimator choice there is an *open research question* → lean on coverage calibration when
    scheduled); **rstanarm** alternate backend; **selectable** `posterior` coupling (MC/bootstrap on a
    Bayesian fit); **HPDI** intervals (ten Hove found percentile better); a **user-exposed `prior=`**
    API; `modeest`/`bayestestR` mode estimators. Untouched carry-overs stay in `ROADMAP.md`.
- Consequences: On M23 close, `intraclass` gains a Bayesian estimation engine and a native posterior
  credible-interval method, validated against the Bayesian IRR literature's own source — closing the
  ADR-014 Bayesian deferral for the two-way random path and inverting the oracle relationship (the
  Bayesian engine becomes a candidate independent oracle for the deferred multilevel designs, ten
  Hove's native turf). The forced-default/Bayesian-only coupling keeps the API story clean at the
  cost of method-comparison flexibility (parked). Adopting brms adds one `Suggests` and a live-fit CI
  cost, bounded by the committed-reference + single-live-fit gating. Risk is front-loaded: Slice 1 is
  wiring through two ready seams; Slice 2's numerical risk (the MAP mode estimator at the boundary) is
  isolated in a small pinned helper whose correctness is established by reproducing the source's
  tables, not by inspection. This ADR authorizes M23 code; the MILESTONES.md M23 board entry and the
  STATUS.md flip to *in flight* are the milestone-start companions.
- References: PRINCIPLES.md #1 (oracle-first — coverage + cross-implementation + REML agreement +
  convergence), #2/#14/#15 (name the estimand / thin vertical slices), #3 (boundary-aware,
  non-normal ratio — the half-*t*'s reason for being, corroborated by ten Hove 2022's MC-CI
  endorsement), #4 (committed seeded reference values; the no-tuning-to-oracle guardrail on the mode
  estimator), #5/#8 (classed aborts for the coupling; `cli` k = 2 note), #6 (additive, non-breaking —
  new `engine`/`ci_method` values only), #12 (sourced prior), #13 (teaching the k = 2 caveat), #16
  (tracking in-commit); ten Hove, Jorgensen & van der Ark (2020) §3.3 / §4.1 (half-*t*(4,0,1) on SDs;
  DGP), §4.2 + Figs 1–5 (MAP unbiased k > 2, EAP biased, percentile nominal coverage), OSF `shkqm`;
  ten Hove et al. (2022) *Updated Guidelines* Discussion pp. 11–12 (brms companion software; MCMC ≈
  MLE point estimates; MC-CI for non-normal ICCs; incomplete/small-k estimation an open question),
  OSF `8j26u`; McGraw & Wong (1996) / Shrout & Fleiss (1979) Table 1 (the ICC(A/C, 1/k) family);
  ADR-014 (M7 SEM — where the Bayesian engine + `ci_method = "posterior"` were deferred), ADR-002
  (optional engines behind `Suggests`/`check_installed`; light install), ADR-025 (M16 — the
  multi-method `ci_method` dispatch seam + the `bootstrap_interval()` percentile reduction reused
  here), ADR-003 (Monte-Carlo boundary-aware CI — the sibling interval method), ADR-005/ADR-012 (the
  M5.5 engine × design dispatch seam this plugs into); estimand-specs `M1-twoway-random-agreement.md`,
  `M2-consistency-and-fixed.md` (the coefficients estimated; no new spec — engine + interval method);
  `project/ROADMAP.md` (Bayesian engine parking-lot entry being promoted), `project/COVERAGE.md`.

## ADR-034: M24 scope — Bayesian multilevel (brms) Design 1 crossed, balanced/complete, random
- Date: 2026-07-09
- Status: accepted
- Context: M23 (ADR-033, PR #28) shipped the **two-way random** Bayesian path (`engine = "brms"` +
  `ci_method = "posterior"`); no milestone is in flight. This ADR opens **M24**, the
  **highest-value Bayesian follow-on** — Bayesian **multilevel** (ten Hove's *native turf*). It is
  the most source-faithful extension available: ten Hove, Jorgensen & van der Ark's **own**
  multilevel IRR estimator (2020/2022) **is** the half-*t*-hyperprior Bayesian model M23 built, so
  M24 finally fits the paper's estimator on the paper's design instead of translating it to REML.
  M24 is a **thin vertical slice** standing to M23 exactly as **M5 stood to M1/M2**: the same engine
  and interval method extended from the two-way random fit to the five-component **crossed (Design 1)**
  fit. **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M16/M23): the estimands are the
  shipped M5 subject- and cluster-level coefficients (`M5-multilevel.md` §3, ten Hove 2022 Eqs. 12–13,
  Table 3), now read off posterior draws — no new estimand-spec, no new argument, no new dependency
  (`brms` is already a `Suggests`); additive, non-breaking (#6): a new valid `engine = "brms"` ×
  multilevel combination only. The maintainer chose **multilevel-first, thin** over a parity sweep
  (one-way + fixed + multilevel bundled) and over a warm-up-first ordering (one-way/fixed before
  multilevel) — highest value, most source-faithful, disciplined thin slice (#14); Bayesian one-way
  and fixed-rater become their own later thin milestones.
- Decision:
  - **Scope: Design 1 crossed only, balanced/complete, `raters = "random"`, subject + cluster levels,
    `type` ∈ {agreement, consistency}, `unit` ∈ {single, average}.** The exact M5 scope box
    (`M5-multilevel.md` §1) for the Bayesian engine. Nested Designs 2/3, fixed-rater, one-way,
    incomplete/ragged, replicates, and the conflated diagnostic all stay deferred (scope-outs below).
  - **The fit: new `fit_brms_multilevel()` fitting M5's five-component crossed model** —
    `score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)`
    (`M5-multilevel.md` §2, our translation of ten Hove Eq. 7, oracle-pinned there) — **under
    half-*t*(4, 0, 1) on every random-effect SD**, `brms::set_prior("student_t(4, 0, 1)", class =
    "sd")`, unchanged from M23. The prior **generalizes verbatim** and is *literally* ten Hove 2020
    §3.3/§4.1's specification for this model (the source estimator), so M24 is more source-faithful
    than the frequentist M5 (which had no worked posterior to match). The prior stays fixed/sourced
    (#12, not user-overridable; `brm_args` may not set it — the M23 collision guard applies).
  - **Draws + convergence generalize, not restructure.** `brms_component_draws()` extends from three
    SD columns to five — `sd_cluster__Intercept`, `sd_cluster:subject__Intercept`,
    `sd_rater__Intercept`, `sd_cluster:rater__Intercept`, `sigma` — squared to the natural variance
    scale, rows named to match the M5 component set (`cluster`, `subject`, `rater`, `cluster_rater`,
    `residual`); `brms_convergence()` checks R-hat/bulk-ESS over the same five (ten Hove 2020 §4.1.3).
    The new contract `draws` field (ADR-033) carries all five components.
  - **Point/interval unchanged from M23.** MAP = `posterior_mode()` of each estimand's ICC-draw
    vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. The
    **level-keyed signal/error map is the shipped M5 machinery** (`M5-multilevel.md` §3/§4) — the
    Bayesian branch composes each estimand's ICC draws from the five component-draw rows exactly as
    the frequentist path composes them from `icc_point()`. No new field beyond `draws`; the shared
    `icc_point()`/`mc_ci()` path is untouched for the other engines.
  - **Two thin vertical slices** (#14/#15):
    - **Slice 1 — subject-level (within-cluster), Bayesian.** `fit_brms_multilevel()` end-to-end;
      the subject-level `(signal = σ²_{s:c}, error set by `type`)` map (§3a) composed from `draws`;
      MAP + percentile credible interval; `ICC(A,1)`/`ICC(A,k)`/`ICC(C,1)`/`ICC(C,k)`; print/tidy
      report `level` + `n_clusters` + a **credible** interval; the M5 identifiability guards (§7)
      reached before dispatch. Oracles O-Bayes-ML-agree + O-Bayes-ML-reduction (subject level).
    - **Slice 2 — cluster-level (between-cluster), Bayesian + the coverage oracle.** The cluster-level
      `(signal = σ²_c, error set = {rater, cluster_rater} / {cluster_rater})` map (§3b) off the **same
      fit**; `ICC(c,1)`/`ICC(c,k)`. **Extend `data-raw/oracle-bayesian.R`** to ten Hove 2020/2022's
      multilevel DGP (`M5-multilevel.md` §5 template: σ²_{s:c} = 1, σ²_{cr} = 0.16, σ²_{(s:c)r} =
      0.50, σ²_c/σ²_r varied over {0.16, moderate}, N_c ∈ {20, 40}, k ∈ {2, 5, 10}) with brms + the
      half-*t* prior, and **commit the reference fixture** (`tests/testthat/fixtures/`, #4). Full
      O-Bayes-ML set.
  - **Oracles (#1 — a CI method's oracle is coverage; M16/M23 precedent, no textbook worked value):**
    **O-Bayes-ML-coverage** — seeded coverage ~nominal at the multilevel DGP (MAP unbiased, percentile
    credible interval nominal at k > 2), off the committed fixture; **O-Bayes-ML-reduction** — (a) a
    single-cluster / σ²_c → 0 design collapses the cluster:rater term and the fitted subject-level
    ICCs match the **M23 two-way Bayesian** fit within stated tolerance; (b) the algebraic
    subject-level ≡ single-level error-set invariant (M5 O-ML/reduction, no fit); **O-Bayes-ML-agree**
    — MAP ≈ the **M5 glmmTMB/lme4 REML** point within a stated tolerance (ten Hove 2022's "MCMC ≈ MLE
    point estimates"; glmmTMB/lme4 are the independent oracles, inverting the M5 relationship that
    named the Bayesian estimator a *future* third oracle); **O-Bayes-ML-converge** — convergence rate
    at the DGP tracked from the stored diagnostics.
  - **CI test-gating (DoD), unchanged posture from M23:** coverage/agreement oracles run off the
    **committed seeded reference** everywhere (#4); a **single live `brms` multilevel fit** (tiny
    `chains`/`iter`) exercises the real wiring, guarded `skip_on_cran()` +
    `skip_if_not_installed("brms")` + `skip_on_ci()` (CI runners have brms but no Stan toolchain —
    [[brms-live-fit-skip-on-ci]]); reduced draws in tests.
  - **Identifiability:** reuse the shipped M5 guards (≥ 2 raters; ≥ 2 clusters for σ²_c; `cluster`
    not 1:1 with `subject`; `abort_intraclass` for `level = "cluster"` with no cluster). **Few
    clusters is where the half-*t* prior earns its keep** — it regularizes the boundary-prone σ²_c /
    σ²_{cr} that make the frequentist intervals wide or singular (#3, the prior's raison d'être).
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** New engine code
    (`fit_brms_multilevel()` + generalized `brms_component_draws()`/`brms_convergence()` in
    `R/engine-brms.R`), a new multilevel branch in `R/icc.R`'s brms dispatch, and the extended
    `data-raw/oracle-bayesian.R` + fixture.
  - **Scope-outs (preserved, not rediscovered):** Bayesian **nested Designs 2/3** (M8/M19 analog),
    **fixed-rater** multilevel (Case-3A θ²_r from the posterior of rater contrasts — M10 analog),
    **one-way** (M6 analog), **incomplete/ragged** multilevel (M9 analog), **within-cell replicates**
    (M17/M20 analog), and the **conflated** diagnostic (M17 Eq. 14) — each a later thin slice; per ten
    Hove 2022 the incomplete/small-k estimator choice is an **open research question**, so those lean
    on coverage calibration when scheduled. Plus the M23 carry-overs: **rstanarm** backend,
    **selectable** `posterior` coupling (MC/bootstrap on a Bayesian fit), **HPDI** intervals, and a
    **user-exposed `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M24 close, `engine = "brms"` covers the **crossed multilevel** path with native
  posterior credible intervals — the paper's own estimator on the paper's flagship design, the
  single most source-faithful coefficient in the package. Risk is **low and front-loaded into a
  ready seam**: Slice 1 is a fit-shape + five-way prior generalization through the M23 `draws`
  contract and the shipped M5 level→signal/error map; the one numerical hazard (the boundary-aware
  mode at the σ²_c / σ²_{cr} boundary) is the M23 `posterior_mode()` helper, already pinned by
  reproducing ten Hove's tables, now exercised on more components. Adds a live-fit CI cost bounded by
  committed-reference + single-live-fit gating (no new dependency). It also **realizes the oracle
  inversion** ADR-033 anticipated — the Bayesian engine becomes a first-class cross-check for the
  multilevel designs, and the M5 REML fit becomes the independent oracle for it. This ADR authorizes
  M24 code; the MILESTONES.md M24 board entry and the STATUS.md flip are the milestone-start
  companions (M24 is opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — coverage + reduction + REML agreement + convergence),
  #2/#14/#15 (name the estimand / thin vertical slices), #3 (boundary-aware — the half-*t*'s reason
  for being, now on σ²_c/σ²_{cr}), #4 (committed seeded reference; no tuning to oracle), #5/#8
  (classed identifiability aborts; `cli` notes), #6 (additive, non-breaking — a new engine×design
  combination), #12 (sourced prior), #16 (tracking in-commit); ten Hove, Jorgensen & van der Ark
  (2020) §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile), OSF `shkqm`; ten Hove,
  Jorgensen & van der Ark (2022) Eqs. 6–7, 12–13, Table 3 (Design 1 subject/cluster estimands;
  brms companion, OSF `8j26u`; MCMC ≈ MLE; incomplete/small-k open question); ADR-011 (M5 multilevel
  estimand — the coefficients estimated), ADR-033 (M23 Bayesian engine — the seam extended),
  ADR-014 (M7 — Bayesian deferral origin), ADR-002 (optional engines behind `Suggests`); estimand-spec
  `M5-multilevel.md` (§1 scope, §2 fit, §3 estimands, §5 oracles/DGP, §7 identifiability — no new
  spec); `project/ROADMAP.md` (Bayesian multilevel follow-on being promoted), `project/COVERAGE.md`.

## ADR-035: M25 scope — Bayesian multilevel (brms) nested Designs 2/3, balanced/complete, random
- Date: 2026-07-09
- Status: accepted
- Context: M24 (ADR-034, PR #29) shipped the **crossed (Design 1)** Bayesian multilevel path
  (`engine = "brms"` + `ci_method = "posterior"`); no milestone is in flight. This ADR opens **M25**,
  the direct continuation of the Bayesian arc — Bayesian **nested Designs 2/3**. It stands to M24
  exactly as **M8 stood to M5**: the same engine, prior, and interval method extended from the crossed
  five-component fit to the paper's two **nested-rater** designs (raters nested in clusters, Design 2;
  raters nested in subjects, Design 3). **Engine/interval parity, not new estimand work** (cf.
  M5.5/M7/M16/M23/M24): the estimands are the shipped **M8 subject-level** coefficients
  (`M8-nested-multilevel.md` §3, ten Hove, Jorgensen & van der Ark 2022 Eqs. 8–11, Table 3
  middle/right), now read off posterior draws — no new estimand-spec, no new argument, no new
  dependency (`brms` already a `Suggests`); additive, non-breaking (#6): a new valid `engine = "brms"`
  × nested-design combination only. The maintainer chose **both nested designs in one milestone** (two
  slices) over Design-2-only — both fits are simple mirrors of shipped glmmTMB shapes, so bundling keeps
  the Bayesian cadence without adding estimand risk (the M8 precedent shipped both together).
- Decision:
  - **Scope: nested Designs 2 and 3, balanced/complete, `raters = "random"`, subject level only, `unit`
    ∈ {single, average}.** The exact M8 scope box (`M8-nested-multilevel.md` §1) for the Bayesian
    engine. Two constraints inherit from M8 (already guarded generically in `icc()`, not brms-specific):
    the **cluster level is undefined for nested raters** (ten Hove p. 6 — subject level only,
    `icc.R:713`), and **Design 3 is agreement-only** (multilevel one-way; no rater main effect to drop
    for a consistency form, `icc.R:729`). Crossed Design 1 (M24), fixed-rater, one-way, incomplete/
    ragged, replicates, and the conflated diagnostic stay deferred (scope-outs below).
  - **The fits: two new functions mirroring the shipped M8 glmmTMB shapes.**
    - **`fit_brms_nested_clusters()` (Design 2, four components):**
      `score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)` — no rater main effect
      (raters nested in clusters; the rater-in-cluster variance σ²_{r:c} is carried by the
      `(1 | cluster:rater)` term). Components — matching the shipped M8 glmmTMB Design-2 contract and the
      `estimand.R` subject-level map (keyed on the **internal `rater` slot**, since Design 2 has no
      separable σ²_cr): `cluster` (σ²_c, nuisance) ← `sd_cluster__Intercept`, `subject` (σ²_{s:c}) ←
      `sd_cluster:subject__Intercept`, **`rater` (σ²_{r:c}) ← `sd_cluster:rater__Intercept`** (internal
      name `rater`, *not* `cluster_rater` — that keeps the brms component set structurally identical to
      glmmTMB Design 2, so the shipped subject-level error-set `{rater, residual}` / `{residual}` map,
      print view, and reductions all apply unchanged), `residual` ← `sigma`.
    - **`fit_brms_nested_subjects()` (Design 3, three components, multilevel one-way):**
      `score ~ 1 + (1 | cluster) + (1 | cluster:subject)` — components `cluster` ← `sd_cluster__Intercept`,
      `subject` ← `sd_cluster:subject__Intercept`, `residual` ← `sigma`.
    Both under the **same sourced half-*t*(4, 0, 1) prior on every random-effect SD**, unchanged from
    M23/M24 (`brms::set_prior("student_t(4, 0, 1)", class = "sd")`; the M23 collision guard applies, #12).
    Each is a copy of `fit_brms_multilevel()` (M24) with the M8 formula + its SD→component `spec` map;
    `fit_brms_common()`, `brms_component_draws()`, and `brms_convergence()` already generalize over any
    `spec` (M24 did that work) — no restructure.
  - **Point/interval/dispatch unchanged from M24.** MAP = `posterior_mode()` of each estimand's ICC-draw
    vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. The
    subject-level signal/error map is the shipped **M8** machinery (`M8-nested-multilevel.md` §3) — the
    Bayesian branch composes each ICC's draws from the nested component rows exactly as the frequentist
    path composes them from `icc_point()`. **Narrow the single `ml_design != "crossed"` brms guard**
    (`icc.R:603`) to admit the two nested designs and dispatch to the new fits — precisely how M24
    narrowed the M23 two-way-only guard. No new field beyond `draws`; the shared `icc_point()`/`mc_ci()`
    path stays untouched for the other engines.
  - **Two thin vertical slices** (#14/#15):
    - **Slice 1 — Design 2 (raters nested in clusters), Bayesian.** `fit_brms_nested_clusters()`
      end-to-end; the four-component subject-level map composed from `draws`; MAP + percentile credible
      interval; `ICC(A,1)`/`ICC(A,k)`/`ICC(C,1)`/`ICC(C,k)`; the M8 identifiability guards reached before
      dispatch. Oracle O-Bayes-NML-agree (Design 2).
    - **Slice 2 — Design 3 (raters nested in subjects), agreement-only, + the coverage oracle.**
      `fit_brms_nested_subjects()`; the three-component agreement-only map; `ICC(1)`/`ICC(k)` (the
      multilevel one-way notation). **As built:** a companion generator
      `data-raw/oracle-bayesian-nested.R` (not an extension of the crossed
      `oracle-bayesian-multilevel.R` — a companion keeps the M24 crossed pins intact and mirrors how
      M24's script was a companion to M23's) runs the M8 nested DGP for **both** nested designs at the
      subject level (Design 2 k = 5; Design 3 k = 5 and k = 2) with brms + the half-*t* prior and
      **commits the reference fixture** `tests/testthat/fixtures/bayesian-nested-oracle.rds` (#4). Full
      O-Bayes-NML set.
  - **Oracles (#1 — coverage; M8/M24 precedent, no textbook worked value):** **O-Bayes-NML-agree** —
    MAP ≈ the **M8 glmmTMB/lme4 REML** point within a stated tolerance (ten Hove 2022's "MCMC ≈ MLE";
    glmmTMB/lme4 the independent oracles); **O-Bayes-NML-coverage** — seeded coverage ~nominal at the
    nested DGP off the committed fixture; **O-Bayes-NML-reduction** — a single-cluster Design 3 collapses
    to the one-way component structure (the algebraic subject-level invariant, no fit) and Design 2 at
    σ²_c → 0 to the flat nested structure; **O-Bayes-NML-converge** — convergence rate at the DGP from
    the stored diagnostics.
  - **CI test-gating (DoD), unchanged posture from M23/M24:** coverage/agreement oracles run off the
    **committed seeded reference** (#4); a **single live `brms` nested fit** (tiny `chains`/`iter`)
    exercises the wiring, guarded `skip_on_cran()` + `skip_if_not_installed("brms")` + `skip_on_ci()`
    ([[brms-live-fit-skip-on-ci]]); reduced draws in tests.
  - **The M24 few-cluster MAP-low caveat is largely NOT exposed here.** Nested designs define **no
    cluster-level ICC**, so σ²_c is a nuisance component, not an estimand — the boundary-prone cluster
    variance that carried M24's caveat does not enter a reported coefficient. The one numerical hazard
    (the boundary-aware mode) is the pinned M23 `posterior_mode()` helper on a **smaller** component set
    than M24 (four / three vs five).
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** New engine code
    (`fit_brms_nested_clusters()` / `fit_brms_nested_subjects()` in `R/engine-brms.R`), a narrowed brms
    multilevel guard + nested dispatch in `R/icc.R`, and the extended
    `data-raw/oracle-bayesian-multilevel.R` + fixture.
  - **Scope-outs (preserved, not rediscovered):** Bayesian **fixed-rater** multilevel (crossed M10 /
    nested M19 analogs — Case-3A θ²_r from the posterior of rater contrasts), **one-way** (M6 analog),
    **incomplete/ragged** multilevel (M9/M19 analog), **within-cell replicates** (M17/M20 analog), and
    the **conflated** diagnostic (Eq. 14) — each a later thin slice; per ten Hove 2022 the incomplete/
    small-k estimator choice is an open research question, so those lean on coverage calibration when
    scheduled. Plus the M23 carry-overs: **rstanarm** backend, **selectable** `posterior` coupling,
    **HPDI** intervals, and a **user-exposed `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M25 close, `engine = "brms"` covers **every multilevel design the frequentist engines
  fit at the subject level** — crossed Design 1 (M24) plus both nested designs — under native posterior
  credible intervals. Risk is **low and front-loaded into the M24 seam**: each slice is a fit-shape +
  `spec` map through the M23 `draws` contract and the shipped M8 subject-level signal/error map, with a
  guard narrowing that mirrors M24's. It extends the oracle inversion (the Bayesian engine cross-checks
  the nested designs; the M8 REML fits are its independent oracle). Adds a live-fit CI cost bounded by
  committed-reference + single-live-fit gating (no new dependency). This ADR authorizes M25 code; the
  MILESTONES.md M25 board entry and the STATUS.md flip are the milestone-start companions (M25 is
  opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — coverage + reduction + REML agreement + convergence),
  #2/#14/#15 (name the estimand / thin vertical slices), #3 (boundary-aware — the half-*t* prior, now on
  a smaller nested component set), #4 (committed seeded reference; no tuning to oracle), #5/#8 (classed
  identifiability aborts; `cli` notes), #6 (additive, non-breaking — a new engine×design combination),
  #12 (sourced prior), #16 (tracking in-commit); ten Hove, Jorgensen & van der Ark (2020) §3.3/§4.1
  (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile), OSF `shkqm`; ten Hove, Jorgensen & van der Ark
  (2022) Eqs. 8–11, Table 3 middle/right (nested Design 2/3 subject-level estimands; MCMC ≈ MLE;
  incomplete/small-k open question), OSF `8j26u`; ADR-016 (M8 nested estimand — the coefficients
  estimated), ADR-034 (M24 Bayesian crossed multilevel — the seam extended), ADR-033 (M23 Bayesian
  engine), ADR-011 (M5 multilevel estimand), ADR-014 (M7 — Bayesian deferral origin), ADR-002 (optional
  engines behind `Suggests`); estimand-spec `M8-nested-multilevel.md` (§1 scope, §2 fits, §3 estimands,
  §5 oracles/DGP, §7 identifiability — no new spec); `project/ROADMAP.md` (Bayesian nested follow-on
  being promoted), `project/COVERAGE.md`.

## ADR-036: M26 scope — Bayesian engine (brms) one-way + fixed-rater, two-way, balanced/complete
- Date: 2026-07-09
- Status: accepted
- Context: The Bayesian arc M23→M24→M25 (ADR-033/034/035, PRs #28/#29/#30) took `engine = "brms"` +
  `ci_method = "posterior"` from the two-way random path through every **multilevel** design at the
  subject level. No milestone is in flight. After a short retro the maintainer chose to **continue the
  Bayesian arc** with its two lowest-risk **single-level** follow-ons — **one-way random** (the M6
  analog) and **fixed-rater** two-way (the M2/M3/M10 analog, and the brms sibling of the lavaan
  fixed-rater path shipped in M21 Slice 2, ADR-031). This ADR opens **M26**. **Engine/interval parity,
  not new estimand work** (cf. M5.5/M7/M16/M21/M23/M24/M25): the estimands are the *shipped* one-way
  (SF Case 1) and fixed-rater finite-population (McGraw & Wong Case 3A) coefficients, now read off
  posterior draws — no new estimand-spec, no new user-facing argument, no new dependency (`brms`
  already a `Suggests`); additive, non-breaking (#6): new valid `engine = "brms"` × {one-way,
  fixed-rater} combinations only. Both are single-level, balanced/complete, two-way (fixed) / one-way
  (random) — the M23 box, not multilevel. The maintainer chose **both slices in one milestone** (the
  M25 precedent), ordered by oracle-risk (one-way first).
- Decision:
  - **Scope: single-level, balanced/complete, two-way.** Slice 1 — **one-way random** (`model =
    "oneway"`, `raters = "random"`, `unit` ∈ {single, average}). Slice 2 — **fixed-rater two-way**
    (`raters = "fixed"`, `type` ∈ {agreement, consistency}, `unit` ∈ {single, average}). Multilevel
    (all levels), incomplete/ragged, within-cell replicates, the conflated diagnostic, numeric-unit
    (D-study) projection, and one-way-**fixed** (not meaningful, M6 §5) all stay deferred (scope-outs
    below) — the shipped `icc()` guards already refuse one-way-fixed and one-way-multilevel for every
    engine (`icc.R:471`), so M26 inherits those.
  - **The fits: two new functions in `R/engine-brms.R`, each reusing `fit_brms_common()`.**
    - **Slice 1 — `fit_brms_oneway()` (one-way random, two components).**
      `score ~ 1 + (1 | subject)` under the SAME sourced half-*t*(4, 0, 1) SD prior (unchanged from
      M23/M24/M25) — a **strict subset** of the shipped `fit_brms_twoway()` (drop the `(1 | rater)`
      term). Components map to the M6 internal names: `subject` (σ²_s) ← `sd_subject__Intercept`,
      `residual` (σ²_res, rater confounded into error) ← `sigma`. The subject-level ICC reads
      `{subject | residual}` — the same shape the shipped Design-3 brms path (M25) already composes —
      so `brms_component_draws()` / `posterior_summary()` map `ICC(1)`/`ICC(1,k)` off the `draws`
      contract **unchanged**. Genuinely trivial: dropping a component, not adding one.
    - **Slice 2 — `fit_brms_fixed()` (fixed-rater two-way).**
      `score ~ 1 + rater + (1 | subject)` — raters enter as a **population-level fixed effect** (brms
      default prior on the rater contrasts; the half-*t*(4, 0, 1) SD prior applies **only** to the
      subject SD, as ten Hove's prior is on random-effect SDs). The variance components σ²_s ←
      `sd_subject__Intercept`, σ²_res ← `sigma` come off the standard `spec`; the **rater slot carries
      θ²_r**, the McGraw & Wong Case-3A finite-population variance of the k fixed rater means
      (estimand-spec M3 §6 / M10 §2), computed **per posterior draw** from the rater fixed-effect
      draws via the shipped engine-agnostic `rater_mean_contrast()` / centering machinery, then stacked
      as the `rater` row of `draws`. Agreement reads `{rater, residual}`, consistency `{residual}` — the
      shipped subject-level error-set map, unchanged.
  - **Oracle-first catch (Slice 2) — the bias correction and the balanced `fixed ≡ random` identity
    need NOT transfer to a Bayesian fit; resolve numerically, do not assert (#1/#18).** Two REML/FIML
    facts the frequentist (M10) and SEM (M21) fixed paths rely on may differ under a prior:
    - **Bias correction.** `theta2r_fixed()` subtracts the mean sampling variance of the β̂ rater
      means (`raw − bias`) because a *point* estimate of the finite-population variance from one fit's
      β̂ overstates the truth by the estimator's sampling variance. A **posterior** already integrates
      that parameter uncertainty, so the raw per-draw finite-population variance of the k rater means is
      a draw from the posterior of θ²_r — **no frequentist bias correction** should be applied to the
      Bayesian draws. Confirm this against the glmmTMB-fixed oracle at build; if the raw push-forward
      does not agree, characterize why before shipping (do not tune to the oracle, #4).
    - **Balanced `fixed ≡ random`.** M10 (REML) and M21 (FIML) satisfy the *exact* balanced identity
      (θ²_r = σ²_r, so fixed agreement ≡ random agreement, and consistency ≡ random) because neither
      has a prior. **brms puts a flat prior on the rater fixed effects but half-*t*(4, 0, 1) on σ_r**,
      so the fixed and random posteriors differ by construction — the identity is expected to hold only
      **approximately** (converging as N grows and the half-*t* washes out). The M26 pin is therefore
      **MAP ≈ glmmTMB fixed θ²_r on balanced data** (glmmTMB the independent oracle) plus a
      *characterized* (not exact-equality) balanced fixed-vs-random relationship — the honest analog of
      M19 Slice 2's "fixed ≢ random even on balanced for nested" catch.
    - **Attempt-then-degrade posture (maintainer decision, matching M18 S2 / M19 S1 / M20 S3):** if no
      #1/#4-strong oracle pins the Bayesian fixed path, **Slice 2 degrades to a recorded deferral** and
      M26 ships **one-way alone** (Slice 1 is unconditional). The one-way slice does not depend on
      Slice 2.
  - **Point/interval/dispatch unchanged from M23–M25.** MAP = `posterior_mode()` of each estimand's
    ICC-draw vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. Two
    shipped brms guards are **narrowed** (precisely how M24/M25 narrowed their guards): the structural
    one-way brms abort (`icc.R:460`) to admit `model = "oneway"` + dispatch to `fit_brms_oneway()` in
    the one-way branch (`icc.R:1238`); the data-dependent fixed-rater brms abort (`icc.R:1123`) to
    admit `raters = "fixed"` + dispatch to `fit_brms_fixed()` in the fixed branch (`icc.R:1250`). The
    k = 2 soft note (`icc.R:1153`) and the balance/replicate/numeric-unit brms refusals stay. No new
    field beyond the shipped `draws` contract; the shared `icc_point()`/`mc_ci()` path stays untouched
    for the other engines.
  - **Two thin vertical slices** (#14/#15), oracle-risk order:
    - **Slice 1 — Bayesian one-way random + its coverage oracle.** `fit_brms_oneway()` end-to-end;
      `ICC(1)`/`ICC(1,k)` off `draws`; MAP + percentile credible interval; the shipped one-way
      identifiability guard (a subject rated more than once, `icc.R:548`) reached before dispatch. A
      companion generator `data-raw/oracle-bayesian-oneway.R` runs the M6 one-way DGP with brms + the
      half-*t* prior and **commits the reference fixture**
      `tests/testthat/fixtures/bayesian-oneway-oracle.rds` (#4). Oracle O-Bayes-OW.
    - **Slice 2 — Bayesian fixed-rater two-way + its oracle (conditional on the oracle-first
      resolution).** `fit_brms_fixed()`; the θ²_r-from-posterior draw row; `ICC(A,1)`/`ICC(A,k)`/
      `ICC(C,1)`/`ICC(C,k)`. Oracle O-Bayes-Fixed. If it degrades, its scope-out line is recorded and
      the fixed brms abort stays.
  - **Oracles (#1 — coverage + reduction + REML agreement; M6/M23 precedent, no textbook worked
    posterior value):**
    - **O-Bayes-OW** — MAP ≈ the **M6 glmmTMB/lme4 REML** one-way point within a stated tolerance
      (ten Hove 2020's "MCMC ≈ MLE"; glmmTMB/lme4 the independent oracles); reduction to the shipped SF
      one-way values (`ICC(1) = 0.166`, `ICC(1,k) = 0.443`) as a sanity anchor; seeded coverage
      ~nominal at the one-way DGP off the committed fixture; convergence rate from the stored
      diagnostics (`brms_convergence()`).
    - **O-Bayes-Fixed** — MAP ≈ **glmmTMB fixed** θ²_r agreement on balanced data (the primary pin);
      consistency vs random *characterized* (approximate under the differing priors, not asserted
      equal); the balanced fixed-vs-random agreement relationship *characterized* (#18); seeded
      coverage of the true θ²_r-based ICC ~nominal.
  - **CI test-gating (DoD), unchanged posture from M23–M25:** coverage/agreement oracles run off the
    **committed seeded reference** (#4); a **single live `brms` fit** per slice (tiny `chains`/`iter`)
    exercises the wiring, guarded `skip_on_cran()` + `skip_if_not_installed("brms")` + `skip_on_ci()`
    ([[brms-live-fit-skip-on-ci]]); reduced draws in tests. Coverage stays ~85% by design — the two new
    fit wrappers are live-only ([[coverage-baseline]]); consented up front.
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** New engine code
    (`fit_brms_oneway()` / `fit_brms_fixed()` in `R/engine-brms.R`), two narrowed brms guards + two
    dispatch branches in `R/icc.R`, and the committed oracle generators + fixtures. One-way reuses the
    M6 estimand-spec; fixed-rater reuses M3 §6 / M10 §2 (θ²_r) — no new spec.
  - **Scope-outs (preserved, not rediscovered):** Bayesian **multilevel** fixed-rater and one-way
    (crossed M10 / nested M19 / multilevel-one-way Design 3 analogs), Bayesian **incomplete/ragged**
    (M9/M19 analog), Bayesian **within-cell replicates** (M17/M20 analog), the Bayesian **conflated**
    diagnostic (Eq. 14), Bayesian **numeric-unit `d_study()`** projection — each a later thin slice; per
    ten Hove 2022 the incomplete/small-k estimator choice is an open research question, so those lean on
    coverage calibration when scheduled. Plus the M23 carry-overs: **rstanarm** backend, **selectable**
    `posterior` coupling (MC/bootstrap on a Bayesian fit), **HPDI** intervals, and a **user-exposed
    `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M26 close, `engine = "brms"` covers the two **single-level** designs it did not —
  one-way random, and (if the oracle holds) fixed-rater two-way — alongside the two-way and multilevel
  random paths already shipped. Slice 1 is near-zero risk (a strict subset of `fit_brms_twoway()` with a
  textbook reduction oracle). Slice 2 carries the milestone's only real risk, front-loaded into an
  **oracle-first question** (does the θ²_r posterior push-forward, with no frequentist bias correction,
  agree with glmmTMB fixed on balanced data?) with an explicit **attempt-then-degrade** escape, so the
  milestone ships value (one-way) even in the worst case. It extends the oracle inversion (the Bayesian
  engine cross-checks one-way and fixed; the M6/M10 REML fits are its independent oracles) and adds a
  live-fit CI cost bounded by committed-reference + single-live-fit gating (no new dependency). This ADR
  authorizes M26 code; the `MILESTONES.md` M26 board and the `STATUS.md` flip are the milestone-start
  companions (M26 is opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — coverage + reduction + REML agreement + convergence),
  #2/#14/#15 (name the estimand / thin vertical slices; oracle-risk ordering), #3 (boundary-aware —
  the half-*t* prior; `posterior_mode()` on [0, Inf) components / [0, 1] ICCs), #4 (committed seeded
  reference; no tuning to oracle), #5/#8 (classed structural aborts for one-way-fixed/-multilevel; `cli`
  notes; the k = 2 caveat), #6 (additive, non-breaking — new engine×design combinations), #12 (sourced
  prior; sourced estimands), #16 (tracking in-commit), #18 (report the run — the balanced fixed-vs-random
  relationship characterized, not asserted); ten Hove, Jorgensen & van der Ark (2020) §3.3/§4.1
  (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile; MCMC ≈ MLE), OSF `shkqm`; McGraw & Wong (1996)
  Case 1 (one-way), Case 3A (fixed-rater finite-population θ²_r); Shrout & Fleiss (1979) ICC(1)/ICC(1,k)
  = 0.166/0.443; estimand-specs `M6-oneway.md` (one-way estimand, §5 identifiability — no new spec) and
  `M3-incomplete-designs.md §6` / `M10-fixed-multilevel.md §2` (θ²_r — no new spec); ADR-033 (M23
  Bayesian engine — the seam extended), ADR-034/035 (M24/M25 multilevel — guard-narrowing precedent),
  ADR-006 (M2 fixed-vs-random label layer), ADR-008 (M3 Case-3A θ²_r), ADR-019 (M10 fixed multilevel),
  ADR-031 (M21 Slice 2 — the lavaan fixed-rater sibling), ADR-014 (M7 — Bayesian deferral origin),
  ADR-002 (optional engines behind `Suggests`); `project/ROADMAP.md` (Bayesian fixed/one-way follow-ons
  being promoted), `project/COVERAGE.md`.

## ADR-037: M27 scope — Bayesian multilevel (brms) fixed-rater, crossed Design 1 + nested Design 2, balanced/complete, subject level
- Date: 2026-07-09
- Status: accepted
- Context: The Bayesian arc M23→M26 (ADR-033/034/035/036, PRs #28/#29/#30/#31) took `engine = "brms"` +
  `ci_method = "posterior"` from two-way random through every **multilevel** design at the subject level
  (random), and then through the two single-level follow-ons (**one-way random** + **fixed-rater
  two-way**). No milestone is in flight. After a short retro the maintainer chose to **continue the
  Bayesian arc** with its remaining well-scoped follow-on — **fixed-rater at the multilevel level**,
  the brms sibling of the frequentist M10 (crossed Design 1 fixed) and M19 Slice 2 (nested Design 2
  fixed). This ADR opens **M27**. **Disambiguation resolved at planning (recorded so it is not
  rediscovered):** the stale "fixed/**one-way** at the multilevel level" deferral wording carried in
  ADR-036's scope-outs / `COVERAGE.md §④` / `STATUS.md` is **half already shipped** — the multilevel
  one-way *is* Design 3 (raters nested in subjects, `model = "twoway"` + nested data, agreement-only;
  `model = "oneway"` + `cluster` is ⚫ by-design, `COVERAGE.md §③`), and **M25 Slice 2 already shipped
  the brms Design-3 path** (ADR-035). So Bayesian multilevel one-way is **done**; only the **fixed-rater**
  multilevel cells remain open. M27 fixes that wording in the tracking files. **Engine/interval parity,
  not new estimand work** (cf. M5.5/M7/M16/M21/M23/M24/M25/M26): the estimand is the *shipped* fixed-rater
  finite-population (McGraw & Wong Case 3A) coefficient placed in the M5/M8 multilevel subject-level
  decomposition, now read off posterior draws — no new estimand-spec, no new user-facing argument, no new
  dependency (`brms` already a `Suggests`); additive, non-breaking (#6): new valid `engine = "brms"` ×
  {crossed-D1-fixed, nested-D2-fixed} combinations only. The maintainer chose **both slices in one
  milestone** (the M25/M26 precedent), ordered by oracle-risk (crossed D1 first — its frequentist sibling
  M10 has the *exact* balanced fixed≡random identity; nested D2 does not).
- Decision:
  - **Scope: multilevel, subject level, balanced/complete, `raters = "fixed"`.** Slice 1 — **crossed
    Design 1 fixed** (`cluster` present, crossing pattern → Design 1, `raters = "fixed"`, `level =
    "subject"`, `type` ∈ {agreement, consistency}, `unit` ∈ {single, average}). Slice 2 — **nested
    Design 2 fixed** (raters nested in clusters, `raters = "fixed"`, `level = "subject"`). Cluster-level
    fixed (⚫ by-design for both — nested has no cluster level; crossed fixed cluster level is an
    unshipped frequentist cell too), **Design 3 fixed** (⚫ by-design — raters nested in subjects is the
    multilevel one-way, no separable rater effect, `COVERAGE.md §④`), incomplete/ragged brms, replicates,
    the conflated diagnostic, and numeric-unit (D-study) projection all stay deferred (scope-outs below).
  - **The fits: two new functions in `R/engine-brms.R`, each reusing `fit_brms_common()`.**
    - **Slice 1 — `fit_brms_multilevel_fixed()` (crossed Design 1 fixed, five components).**
      `score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)` — the brms
      sibling of `fit_glmmtmb_multilevel_fixed()` (M10) and of the shipped random `fit_brms_multilevel()`
      (M24) with the `(1 | rater)`/`(1 | cluster:rater)` random-rater main effect replaced by a
      **population-level fixed `rater` effect** (brms default prior on the rater contrasts). The sourced
      half-*t*(4, 0, 1) SD prior (unchanged from M23–M26) applies **only to the random-effect SDs**
      (`sd_cluster`, `sd_cluster:subject`, `sd_cluster:rater`), as ten Hove's prior is on random-effect
      SDs. Components σ²_c ← `sd_cluster__Intercept`, σ²_{s:c} ← `sd_cluster:subject__Intercept`, σ²_{cr}
      ← `sd_cluster:rater__Intercept`, σ²_res ← `sigma` come off the standard `spec`; the **rater slot
      carries θ²_r**, the Case-3A finite-population variance of the k fixed rater means, computed **per
      posterior draw** from the rater fixed-effect draws (the M26 Slice 2 pattern applied to the
      multilevel decomposition). The subject-level error set is `{rater, cluster:rater, residual}` for
      agreement / `{cluster:rater, residual}` for consistency — the *shipped* M10 subject-level error map,
      unchanged; `brms_component_draws()` composes the ICC off `draws` unchanged.
    - **Slice 2 — `fit_brms_nested_fixed()` (nested Design 2 fixed).**
      `score ~ 0 + rater + (1 | cluster:subject)` — the brms sibling of `fit_glmmtmb_nested_fixed()`
      (M19 Slice 2), `0 + rater` giving one fixed level per rater. The **rater slot carries θ²_{r:c}**,
      the mean over clusters of each cluster's finite-population rater variance (per-cluster McGraw–Wong
      Case 3A, the M19 `theta2r_fixed_nested()` estimand), computed **per posterior draw** from the
      per-cluster rater fixed-effect draws. σ²_{s:c} ← `sd_cluster:subject__Intercept`, σ²_res ← `sigma`.
      Agreement-only at the subject level (Design 2 admits consistency too — carry the shipped M19
      agreement/consistency subject-level error map unchanged).
  - **Oracle-first catch (both slices) — the frequentist bias correction and the balanced identities need
    NOT transfer to a Bayesian fit; resolve numerically, do not assert (#1/#18).** Same posture M26
    Slice 2 established, now at the multilevel level:
    - **No frequentist bias correction on the posterior θ²_r / θ²_{r:c} draws.** The REML/FIML
      `theta2r_fixed()` / `theta2r_fixed_nested()` subtract the mean sampling variance of the β̂ rater
      means because a *point* estimate overstates the finite-population variance by the estimator's
      sampling variance. A **posterior** already integrates that parameter uncertainty, so the **raw**
      per-draw finite-population variance is a draw from the posterior of θ²_r / θ²_{r:c} — no bias
      correction applied. Confirm against the glmmTMB oracle at build; characterize (don't tune, #4) if
      the raw push-forward disagrees.
    - **Balanced fixed-vs-random relationship differs by construction.** M10 (crossed, REML) satisfies
      the *exact* balanced identity θ²_r = σ²_r ⇒ fixed agreement ≡ random agreement; M19 (nested, REML)
      **does not** (per-cluster finite population ⇒ fixed ≢ random even balanced, the ADR-029
      oracle-first catch). brms puts a flat prior on the rater fixed effects but half-*t*(4, 0, 1) on the
      random-effect SDs, so under the prior **neither identity holds exactly** — the crossed identity is
      expected only **approximately** (converging as N grows), and the nested inequality persists. The
      correct oracle is therefore **containment** (glmmTMB fixed point inside the brms credible interval)
      + coverage, **not pointwise equality** — the honest analog of M26's "fixed ≡ random only
      approximately under the prior" resolution.
    - **Attempt-then-degrade posture (maintainer decision, matching M18 S2 / M19 S1 / M20 S3 / M26 S2):**
      if no #1/#4-strong oracle pins a slice's Bayesian fixed path, that slice **degrades to a recorded
      deferral**. Slices are independent (crossed D1 does not depend on nested D2); Slice 1 ships even if
      Slice 2 degrades.
  - **Point/interval/dispatch unchanged from M23–M26.** MAP = `posterior_mode()` of each estimand's
    ICC-draw vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. The
    shipped brms multilevel guards are **narrowed** exactly as M24/M25/M26 narrowed theirs: admit
    `raters = "fixed"` on the crossed-D1 and nested-D2 brms multilevel branches + dispatch to the two new
    fits. The k = 2 soft note and the balance/replicate/numeric-unit/cluster-level brms refusals stay. No
    new field beyond the shipped `draws` contract; the shared `icc_point()`/`mc_ci()` path stays untouched
    for the other engines.
  - **Two thin vertical slices** (#14/#15), oracle-risk order:
    - **Slice 1 — Bayesian crossed Design 1 fixed + its oracle.** `fit_brms_multilevel_fixed()`
      end-to-end; θ²_r-from-posterior draw row; subject-level `ICC(A,1)`/`ICC(A,k)`/`ICC(C,1)`/`ICC(C,k)`;
      MAP + percentile credible interval. A companion generator `data-raw/oracle-bayesian-multilevel-fixed.R`
      runs the M10 crossed-fixed DGP with brms + the half-*t* prior and **commits the reference fixture**
      `tests/testthat/fixtures/bayesian-multilevel-fixed-oracle.rds` (#4). Oracle O-Bayes-FML.
    - **Slice 2 — Bayesian nested Design 2 fixed + its oracle (conditional on the oracle-first
      resolution).** `fit_brms_nested_fixed()`; the θ²_{r:c}-from-posterior draw row; subject-level
      coefficients. Extends the same generator (nested-fixed DGP) + committed fixture. Oracle
      O-Bayes-FNML. If it degrades, its scope-out line is recorded and the nested-fixed brms abort stays.
  - **Oracles (#1 — containment + coverage + reduction + REML agreement; M10/M19/M26 precedent, no
    textbook worked posterior value):**
    - **O-Bayes-FML** (crossed D1) — glmmTMB M10 fixed point **contained** in the brms subject-level
      credible interval (glmmTMB the independent oracle); the balanced fixed-vs-random agreement
      relationship *characterized* (approximate under the prior, #18); MAP ≈ glmmTMB fixed within a
      stated tolerance; consistency ≡ random pinned where it holds; seeded coverage ~nominal at the M10
      DGP off the committed fixture; convergence rate from `brms_convergence()`.
    - **O-Bayes-FNML** (nested D2) — glmmTMB M19 nested-fixed point **contained** in the brms credible
      interval; the balanced **fixed ≢ random** relationship *characterized* (per-cluster finite
      population, the M19 catch, expected to persist under the prior, #18); reduction of θ²_{r:c} to the
      flat M3 fixed θ²_r at a single cluster; seeded coverage ~nominal.
  - **CI test-gating (DoD), unchanged posture from M23–M26:** coverage/containment oracles run off the
    **committed seeded reference** (#4); a **single live `brms` fit** per slice (tiny `chains`/`iter`)
    exercises the wiring, guarded `skip_on_cran()` + `skip_if_not_installed("brms")` + `skip_on_ci()`
    ([[brms-live-fit-skip-on-ci]]); reduced draws in tests. Coverage stays ~85% by design — the two new
    fit wrappers are live-only ([[coverage-baseline]]); consented up front.
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** New engine code
    (`fit_brms_multilevel_fixed()` / `fit_brms_nested_fixed()` in `R/engine-brms.R`), two narrowed brms
    guards + two dispatch branches in `R/icc.R`, and the committed oracle generator + fixture. Crossed
    fixed reuses `M10-fixed-multilevel.md §2` (θ²_r); nested fixed reuses the M19 nested-fixed θ²_{r:c}
    estimand — no new spec.
  - **Scope-outs (preserved, not rediscovered):** Bayesian **cluster-level** fixed (⚫ nested has none;
    crossed fixed cluster level unshipped for all engines), Bayesian **Design 3 fixed** (⚫ by-design —
    multilevel one-way), Bayesian **incomplete/ragged** fixed multilevel (M18 S1 / M19 analog — the
    k_eff × per-cluster θ² interaction), Bayesian **within-cell replicates**, the Bayesian **conflated**
    diagnostic (Eq. 14), Bayesian **numeric-unit `d_study()`** projection — each a later thin slice; per
    ten Hove 2022 the incomplete/small-k estimator choice is an open research question, so those lean on
    coverage calibration when scheduled. Plus the M23 carry-overs: **rstanarm** backend, **selectable**
    `posterior` coupling, **HPDI** intervals, **user-exposed `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M27 close, `engine = "brms"` covers the multilevel **fixed-rater** subject-level cells
  it did not — crossed Design 1 fixed, and (if the oracle holds) nested Design 2 fixed — alongside the
  multilevel random paths already shipped (M24/M25). Combined with M26's single-level fixed and the
  already-shipped multilevel one-way (Design 3, M25), the brms multilevel story is then **random ✓
  (M24/M25) + fixed ✓ (M27)** at the subject level. Slice 1 is low risk (a shipped fit shape with a
  well-understood glmmTMB independent oracle and the M10 balanced identity as a soft anchor). Slice 2
  carries the milestone's oracle-first question (does θ²_{r:c} push-forward, no bias correction, sit
  inside the credible interval, with the M19 fixed≢random inequality intact under the prior?) with the
  explicit **attempt-then-degrade** escape, so the milestone ships value (crossed D1) even in the worst
  case. It corrects the stale one-way deferral wording in the tracking files. This ADR authorizes M27
  code; the `MILESTONES.md` M27 board and the `STATUS.md` flip are the milestone-start companions (M27 is
  opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — containment + coverage + reduction + REML agreement +
  convergence), #2/#14/#15 (name the estimand / thin vertical slices; oracle-risk ordering), #3
  (boundary-aware — the half-*t* prior; `posterior_mode()` on [0, 1] ICCs), #4 (committed seeded
  reference; no tuning to oracle), #5/#8 (classed structural aborts for Design-3 fixed / cluster-level
  fixed; `cli` notes; k = 2 caveat), #6 (additive, non-breaking — new engine×design combinations), #12
  (sourced prior; sourced estimands), #16 (tracking in-commit), #18 (report the run — the balanced
  fixed-vs-random relationship characterized via containment, not asserted equal); ten Hove, Jorgensen &
  van der Ark (2020) §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile; MCMC ≈ MLE), OSF
  `shkqm`; ten Hove, Jorgensen & van der Ark (2022) Eqs. 8–11 (nested Design 2 subject-level components);
  McGraw & Wong (1996) Case 3A (fixed-rater finite-population θ²_r); estimand-specs
  `M10-fixed-multilevel.md §2` (crossed θ²_r — no new spec) and the M19 nested-fixed θ²_{r:c} (no new
  spec); ADR-033 (M23 Bayesian engine — the seam extended), ADR-034/035 (M24/M25 multilevel random —
  guard-narrowing precedent), ADR-036 (M26 single-level fixed — the raw-θ²-from-posterior + containment
  precedent), ADR-019 (M10 crossed fixed multilevel), ADR-029 (M19 nested fixed — the fixed≢random
  catch), ADR-008 (M3 Case-3A θ²_r), ADR-014 (M7 — Bayesian deferral origin), ADR-002 (optional engines
  behind `Suggests`); `project/ROADMAP.md` (Bayesian multilevel fixed follow-on being promoted),
  `project/COVERAGE.md`.
- **Amendment (2026-07-09, Slice 2 — Fable review of the nested θ²_{r:c} push-forward, #19).** The
  Slice-2 oracle-first fork the scope anticipated fired: the **raw** θ²_{r:c} posterior push-forward
  (the M26 posture generalized) **undercovers** the fixed-population subject-level ICC(A,1) for the
  nested design — seeded 100-rep coverage **0.86** (vs the crossed Slice-1 0.96), MAP rel-bias −.106 —
  and, per the review, its coverage **→ 0 as clusters accrue** (an incidental-parameters pathology from
  the flat prior on C_n·k cell means, a *consistency* failure, not a small-sample refinement). The
  maintainer approved a **gated Fable review** (Claude Fable 5, 2026-07-09; brief + response committed at
  `data-raw/reviews/fable-review-m27-nested-fixed-{brief,response}.md`); its verdict is adopted:
  - **Ship the 2b moment correction, not the raw push-forward.** Per posterior draw, per group (one
    group for a common rater set, one per cluster for nested): subtract **2·b**, `b = tr(C·Σ_post)/(k−1)`
    from the raw quadratic `q(μ^draw)`. There are **two** equal inflations, not one: (1) the push-forward
    `E[q(μ^draw)] = q(μ̄) + b` (uses Σ_post exactly), and (2) the plug-in bias of the center
    `E[q(μ̄)] = θ² + b` (Σ_post is the Bernstein–von Mises–consistent estimate of the sampling covariance
    `V`; on balanced data `b = σ²_res/n_s` exactly). The shipped **frequentist** `theta2r_fixed_nested()`
    subtracts only **1b** from its draws because its *point* is computed separately and is unbiased — the
    Bayesian engine reads the MAP off the same draws, so it needs the full **2b**. Derived, not tuned
    (#4): the brms table's raw→1b step is exactly one `b` (−4.1 pts), and a Stan-free conjugate-normal
    check hits θ+2b, θ+b, θ to ≲.003.
  - **Boundary-aware flooring (#3): floor the per-draw group AVERAGE, not each group.** Per-cluster
    `pmax(0,·)` makes every cluster's contribution strictly positive near θ²=0, so the interval cannot
    reach 0 → **zero** coverage at the boundary; letting negative per-cluster draws cancel and flooring
    only the average is unbiased at the boundary and boundary-reaching.
  - **Unify the crossed/single-level helper to the same 2b path** (`brms_theta2r_moment_draws()`): there
    `b ≈ 0` (means estimated from the whole sample), recovering M26/Slice-1 behaviour, so one estimator is
    correct in both regimes and retires a regime-split. `brms_theta2r_draws()` (common set) and
    `brms_theta2r_nested_draws()` (nested) now both delegate to it.
  - **Scope ADR-036's rationale.** ADR-036's "a posterior already integrates the parameter uncertainty
    the `− bias` removes" is correct for functionals **linear** in β and numerically harmless whenever
    `tr(C·Σ_post) ≈ 0` (crossed/single-level), but **not** for the convex *quadratic* finite-population
    variance functional in the nested regime, where the push-forward is inflated **and** its center is
    biased. It was the right call in M26's regime for the wrong general reason; future Bayesian
    fixed-rater slices use the moment-corrected form.
  - **Validation:** O-Bayes-FNML regenerated on the corrected estimator across an **interior** and a
    **boundary (θ²=0)** cell (Fable predicts interior coverage ≈.95, MAP ≈−.02; boundary coverage ≥
    nominal under the average-floor). Slice-1 O-Bayes-FML regenerated after unifying the crossed helper
    (2b ≈ 0 there; containment tolerances hold).
  - **Corollary spun off (out of Slice-2 scope):** the shipped **frequentist** nested-fixed *interval*
    (`theta2r_nested_draws()`) is the 1b-corrected, per-cluster-floored construction, so it shares an
    attenuated displacement and cannot reach θ²=0; no committed coverage sim pins the nested-fixed *MC
    interval* specifically. Recommended as its own task/ADR (a seeded coverage sim across the Fable Q6
    grid); the frequentist *point* estimator is unaffected. The Fable-recommended fully-Bayesian
    alternative (a hierarchical half-*t* prior on the within-cluster rater effects, θ² read off the
    realized η draws) is parked as a scoped future alternative (own ADR/validation) — it leaves the
    fixed-effects parity contract with `fit_glmmtmb_nested_fixed()`.

## ADR-038: M28 scope — Frequentist nested-fixed MC-interval coverage (characterize-then-decide)
- Date: 2026-07-09
- Status: accepted
- Context: The M27 gated Fable review (#19, ADR-037 amendment) fixed the **Bayesian** nested-fixed
  interval — the raw θ²_{r:c} push-forward undercovers the nested finite population (an
  incidental-parameters pathology: coverage 0.86 → 0 as clusters accrue) — by subtracting a **2b**
  moment correction and flooring the per-draw **average** rather than each cluster. Its **corollary**
  (ADR-037 Decision, "Corollary spun off") observed that the shipped **frequentist** sibling —
  `theta2r_nested_draws()` ([`R/engine-glmmtmb.R`](../R/engine-glmmtmb.R), the M19 Slice 2 θ²_{r:c}
  Monte-Carlo interval) — is built the *same suspect way*: per draw it does `pmax(0, raw - b)` **per
  cluster** (subtracting only **1b**) and then averages, so it likely shares an attenuated displacement
  and **cannot reach θ²=0**. No committed coverage sim pins the nested-fixed *MC interval* specifically.
  The frequentist **point** estimator (`th$point`, computed separately) is unbiased and out of scope.
  After a short retro of the M23→M27 Bayesian arc the maintainer chose this corollary as the next
  milestone (M28) and — per oracle-first (#1/#18) — the **characterize-then-decide** posture: do not
  presume the interval is broken before a sim says so.
- Decision:
  - **Slice 1 (required) — commit to characterization only.** A committed **seeded coverage sim**
    (new `data-raw/oracle-nested-fixed-interval.R` + committed fixture, #4) across the Fable Q6 grid:
    `k ∈ {2,4}`, `n_s ∈ {3,5,20}`, `C_n ∈ {5,20,80}`, `θ²_{r:c} ∈ {0, σ²_res/n_s, .66}`. Reports
    **interior and boundary (θ²=0)** coverage of the *shipped* `theta2r_nested_draws()` interval,
    honestly (#18). This is the milestone deliverable **even if coverage is already nominal** — a
    regression fixture + the first coverage pin on this interval. A CI method's oracle is coverage (#1).
    Slice 1 alone (characterizing, not changing a shipped interval) does **not** require a Fable review.
  - **Slice 2 (conditional on Slice 1 showing under-coverage) — mirror the M27 fix.** Recenter the MC
    draws + floor the per-draw **average** instead of per cluster, reusing the M27 template
    (`brms_theta2r_moment_draws()`); regenerate the sim green. Spot-check that the crossed
    `theta2r_fixed()` interval shares this only negligibly (v → 0 there, per the corollary) — confirm,
    do not rebuild machinery. Because Slice 2 **changes a shipped interval**, it is a strong candidate
    for a **gated Fable review** (#19): `verify-estimator` recommends, then **stops and waits** for
    explicit maintainer approval before Fable runs.
  - **Interval-method work, not new estimand work** (cf. M16/M21/M23–M27): no new estimand-spec, no new
    user-facing argument, no new dependency; additive, non-breaking (#6). The **point** estimator is
    unchanged by design.
- Consequences: Pins (and if warranted, fixes) the last known interval built on the pre-Fable
  per-cluster-floor pattern, closing the M27 corollary thread. Under the characterize-then-decide
  posture, if the sim shows nominal coverage the milestone ships as a characterization + committed
  regression fixture with **no code change** — a legitimate outcome, not a failure. If Slice 2 fires it
  is a **behavior change to a shipped MC interval** (the point is stable, but reported CIs near the
  boundary move and can now reach θ²=0), gated on a Fable review. Rules out (stays parked, own future
  ADR): the Fable-recommended **fully-Bayesian alternative** (hierarchical half-*t* prior on the
  within-cluster rater effects, θ² read off realized η draws) — it would leave the fixed-effects parity
  contract with `fit_glmmtmb_nested_fixed()`. Categorical/ordinal GLMM and multilevel SEM untouched.
- References: ADR-037 (M27 scope + the gated Fable-review amendment and its spun-off corollary);
  `data-raw/reviews/fable-review-m27-nested-fixed-{brief,response}.md` (Q6 grid); M19/ADR-029 (the
  shipped `theta2r_fixed_nested()` / `theta2r_nested_draws()` nested-fixed path); McGraw & Wong (1996)
  Case 3A finite-population θ²_r; ten Hove, Jorgensen & van der Ark (2022) nested Design 2. Oracle:
  O-NFI (nested-fixed-interval) coverage, `data-raw/oracle-nested-fixed-interval.R` → committed fixture,
  registered in [`REFERENCES.md`](REFERENCES.md).

- **Amendment (2026-07-09) — Slice 1 finding + Slice 2 resolution via a gated Fable review (#19).**
  Slice 1 fired: O-NFI pinned the shipped interval undercovering (boundary coverage .95/.86/.57 as
  C_n = 5/20/80; worst cell C_n=80/n_s=3 ≈ .37; interior means .95/.92/.80) — the incidental-parameters
  displacement the corollary predicted. The maintainer approved a gated Fable review; brief + response
  committed at `data-raw/reviews/fable-review-m28-nested-fixed-interval-{brief,response}.md`. Fable's
  verdict (adopted in full):
  - **Ship the moment-corrected interval: subtract 2·b_c per group per draw, no per-group floor, floor the
    per-draw AVERAGE.** Two equal inflations, so 2b not 1b (Fable §1): one undoes the Gaussian
    push-forward `E_draw[q(β*)] = q(β̂) + b` (b from the engine vcov that generates the draws — exact, not
    the empirical draw covariance), one removes the plug-in bias of the center `E[q(β̂)] = θ² + b`; the
    draws then center on the 1b-corrected point. Derived, not tuned (#4): Fable's independent
    conjugate-normal check (`data-raw/reviews/fable-check-nfi.R`) confirms it with no free parameter, and
    tested the two "obvious" alternatives head-to-head — the percentile-of-the-recomputed-estimator (= the
    shipped +b displacement) and its **pivotal reflection** (−b, interior coverage as low as .006) — both
    collapse. Delta-method / profile intervals are degenerate at the boundary (∇q = 0). The point keeps
    its **1b** correction (not a double-correction, Fable §2).
  - **Point flooring also moves to the average (Fable §3, finding beyond the brief).** The shipped POINT
    `mean_c pmax(0, q(β̂_c) − b_c)` has a boundary bias (~.05–.08 at n_s=3) constant in C_n, so once the
    interval is corrected the **point falls outside its own 95% interval** in up to ~40% of boundary reps
    at C_n=80 (a user-visible incoherence). Fix: `max(0, mean_c(q(β̂_c) − b_c))` — 1b unchanged, interior
    identical (O-FNML pins unmoved), boundary containment restored to 1.00 (verified: worst cell .59→1.00).
  - **Unify all fixed-rater MC draws onto one shared `theta2r_moment_draws()` helper** (crossed/flat +
    multilevel-fixed, glmmTMB + lme4 + lavaan; Fable §5). Crossed b ≈ 0 (whole-sample means), so the shift
    is negligible and coverage stays nominal (verified crossed flat-fixed .958; M3 O6 / O-FML pins hold);
    unification **retires** the `theta2r_fixed()` "deliberate displacement" note as a regime-conditional
    exception that should not survive the milestone. The lavaan random path is unchanged (b = 0 → reduces
    to raw Jorgensen Eq. 6 exactly).
  - **Validation:** O-NFI regenerated on the corrected estimator (same committed grid) as **confirmation
    of derived constants** — Fable predicts boundary ~.97–1.00 (conservative, boundary-aware #3), interior
    mean ≈ .95, no cell < ~.90. The pivotal-reflection alternative is recorded as tested-and-rejected so it
    is not rediscovered.
  Scope note: the fully-Bayesian hierarchical-shrinkage alternative stays parked (own future ADR); this
  amendment implements the frequentist analog of the ADR-037 (M27) Bayesian resolution, now unified so one
  construction is correct in both the crossed (b≈0) and nested (b material) regimes.

## ADR-039: M29 scope — Bayesian engine (brms) conflated diagnostic + within-cell replicates, two-way random, balanced/complete
- Date: 2026-07-10
- Status: accepted
- Context: The Bayesian arc M23→M28 (ADR-033–038, PRs #28–#33) took `engine = "brms"` +
  `ci_method = "posterior"` from the two-way random path through every design at the subject level
  (two-way random/fixed, one-way, all multilevel crossed + nested, random and fixed) on
  **balanced/complete** data, and resolved the finite-population θ² interval question (the 2b moment
  correction, unified across all engines in M28). No milestone is in flight. After a short retro the
  maintainer chose to **continue the Bayesian arc** with its two lowest-risk remaining parity
  follow-ons — the **conflated** diagnostic (`level = "conflated"`, ten Hove Eq. 14) and **within-cell
  replicates** (σ²_res → σ²_sr + σ²_e) — deferring Bayesian **incomplete/ragged** to its own later
  milestone (M30) where its coverage-calibration risk is isolated. This ADR opens **M29**.
  **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M16/M21/M23–M27): the estimands are the
  *shipped* conflated (M17 Slice 1, ADR-026) and within-cell-replicate (M17 Slice 3, ADR-026)
  coefficients, now read off posterior draws — no new estimand-spec, no new user-facing argument, no new
  dependency (`brms` already a `Suggests`); additive, non-breaking (#6): new valid `engine = "brms"` ×
  {conflated, replicates} combinations only. Both are two-way **random**, balanced/complete, single
  level. Crucially, both are **ratios of variance components** (like the whole random-rater Bayesian
  arc), so neither exposes the θ² finite-population functional that forced the M27/M28 2b moment
  correction — a clean posterior push-forward, the lowest-drama Bayesian milestone available. The
  maintainer chose **both slices in one milestone** (the M25/M26 precedent), ordered by oracle-risk
  (conflated first).
- Decision:
  - **Scope: two-way random, balanced/complete, single level.** Slice 1 — **Bayesian conflated**
    (`engine = "brms"`, `level = "conflated"`, `type = "agreement"`, `unit` ∈ {single, average}). Slice 2
    — **Bayesian within-cell replicates** (`engine = "brms"`, replicated data inferred, `raters =
    "random"`, `type` ∈ {agreement, consistency}, `occasions` ∈ {single, average}, `unit` ∈ {single,
    average}). Bayesian **incomplete/ragged** (M30), **fixed × replicates** and **multilevel ×
    replicates** brms (mirror the M20 frequentist deferrals), **conflated × consistency** (🟣 research,
    unsourced), and numeric-unit (D-study) Bayesian projection all stay deferred (scope-outs below).
  - **Slice 1 — conflated: no new fit.** `level = "conflated"` reads Eq. 14 off the *already-shipped*
    M24 `fit_brms_multilevel()` five-component draws (`icc.R:1238`) — the **flat two-way ICC** off the
    multilevel fit: signal = σ²_c + σ²_{s:c} lumped, error = σ²_r + σ²_cr + σ²_res lumped, with the same
    flat `k_eff`; **agreement-only** (Eq. 14 treats the rater effect as a variance component; a
    consistency or fixed-rater conflated form is not defined by the source — COVERAGE §④). Computed
    **per posterior draw** through the same push-forward the frequentist M17 Slice 1 / M18 Slice 2 use.
    The shipped brms conflated refusal (`icc.R:598–604`) is **narrowed** to admit `level = "conflated"`
    and route to the multilevel fit; the diagnostic-only "biased, never recommended" posture
    (`M17-conflated-icc.md §4`) is preserved verbatim.
  - **Slice 2 — within-cell replicates: one new fit function.** `fit_brms_replicates()` in
    `R/engine-brms.R`, reusing `fit_brms_common()`: `score ~ 1 + rater + (1 | subject) + (1 |
    subject:rater)` under the SAME sourced half-*t*(4, 0, 1) SD prior (unchanged from M23–M27; the prior
    now covers the σ_sr interaction SD too, as it applies to every random-effect SD). Components map to
    the M17 internal names: `subject` (σ²_s), `rater` (σ²_r), `interaction` (σ²_sr) ←
    `sd_subject:rater__Intercept`, `residual`/pure error (σ²_e) ← `sigma`. The `occasions` knob applies
    the shipped M17 **per-component error divisors** (`M17-within-cell-replicates.md §2`) **per draw**:
    `occasions = "single"` reports the single-rating reliability; `occasions = "average"` divides the
    pure-error component by `n_o` (the interaction σ²_sr is NOT divided — it is shared across the
    replicates of a cell), reporting the reliability of the replicate mean. The shipped brms replicate
    refusal (`icc.R:1124`) is **narrowed** and a dispatch branch added alongside `fit_brms_twoway()`
    (`icc.R:1304`).
  - **Point/interval/dispatch unchanged from M23–M27.** MAP = `posterior_mode()` of each estimand's
    ICC-draw vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. No new
    field beyond the shipped `draws` contract; the shared `icc_point()`/`mc_ci()` path stays untouched
    for the other engines. Both slices are random-rater **ratios of variance components** — no θ²
    finite-population functional, so the M27/M28 2b moment correction does **not** apply (a clean
    push-forward; `tr(C·Σ) ≈ 0` is not even in play). The k = 2 soft note and the balance/numeric-unit
    brms refusals stay.
  - **Two thin vertical slices** (#14/#15), oracle-risk order:
    - **Slice 1 — Bayesian conflated + its coverage oracle.** Conflated ICC off the M24 multilevel
      draws; MAP + percentile credible interval; the shipped conflated-diagnostic guards reached before
      dispatch. A companion generator `data-raw/oracle-bayesian-conflated.R` runs the M17/M5 crossed DGP
      with brms + the half-*t* prior and **commits the reference fixture**
      `tests/testthat/fixtures/bayesian-conflated-oracle.rds` (#4). Oracle O-Bayes-Conflated.
    - **Slice 2 — Bayesian within-cell replicates + its oracle.** `fit_brms_replicates()`; the
      σ²_sr/σ²_e split; `occasions` single/average per-draw divisors; agreement/consistency, single/
      average. Companion generator `data-raw/oracle-bayesian-replicates.R` commits
      `tests/testthat/fixtures/bayesian-replicates-oracle.rds` (#4). Oracle O-Bayes-Rep.
  - **Oracles (#1 — reduction + REML agreement + coverage; M23–M27 precedent, no textbook worked
    posterior value):**
    - **O-Bayes-Conflated** — the Eq-14 identity holds per draw (the conflated ICC composes from the
      five components exactly as `M17-conflated-icc.md §2` specifies); MAP ≈ the frequentist **M17/M18
      glmmTMB** conflated ICC within a stated tolerance (glmmTMB the independent oracle) — **containment**
      of the glmmTMB conflated point in the credible interval, not pointwise equality (the prior-vs-flat
      gap, the M26 O-Bayes-Fixed posture); the conflated stays **visibly biased vs. the subject level**
      (the diagnostic's whole point, `§4`); seeded coverage ~nominal off the committed fixture;
      convergence rate from `brms_convergence()`.
    - **O-Bayes-Rep** — reduction: `occasions = "average"` MAP ≈ the **M17 glmmTMB/lme4** replicate
      coefficients on the same data (the occasion-averaged coefficient == the two-way ICC on cell means,
      `M17-within-cell-replicates.md §6`); MAP ≈ glmmTMB single-occasion within tolerance (containment,
      not equality); seeded coverage ~nominal off the committed fixture.
  - **CI test-gating (DoD), unchanged posture from M23–M27:** coverage/reduction oracles run off the
    **committed seeded reference** (#4); a **single live `brms` fit** per slice (tiny `chains`/`iter`)
    exercises the wiring, guarded `skip_on_cran()` + `skip_if_not_installed("brms")` + `skip_on_ci()`
    ([[brms-live-fit-skip-on-ci]]); reduced draws in tests. Coverage stays ~85% by design — the new fit
    wrapper is live-only ([[coverage-baseline]]); consented up front.
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** New engine code
    (`fit_brms_replicates()` in `R/engine-brms.R`; conflated reads the existing multilevel fit), two
    narrowed brms guards + one new dispatch branch in `R/icc.R`, and the committed oracle generators +
    fixtures. Conflated reuses `M17-conflated-icc.md`; replicates reuse `M17-within-cell-replicates.md`
    — no new spec.
  - **Scope-outs (preserved, not rediscovered):** Bayesian **incomplete/ragged** (M9/M19 analog — its
    own milestone M30; per ten Hove 2022 the incomplete/small-k estimator choice is an open research
    question, so it leans on coverage calibration and likely a gated Fable review, #19); Bayesian
    **fixed-rater × replicates** and **multilevel × replicates** (the M20 Slice 1/2 frequentist
    deferrals' Bayesian siblings); **conflated × consistency** and **conflated × fixed** (🟣 research /
    ⚫ by design — unsourced / undefined, COVERAGE §④); Bayesian **numeric-unit `d_study()`** projection;
    plus the M23 carry-overs — **rstanarm** backend, **selectable** `posterior` coupling (MC/bootstrap on
    a Bayesian fit), **HPDI** intervals, and a **user-exposed `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M29 close, `engine = "brms"` covers the conflated diagnostic and within-cell
  replicates alongside the two-way/one-way/multilevel random and fixed paths already shipped — leaving
  Bayesian incomplete/ragged (M30) and the ⚫/🟣/infra carry-overs as the only remaining brms gaps. Both
  slices are low risk: Slice 1 adds **no new fit** (it re-reads shipped M24 draws), and Slice 2 is a
  single new fit shape with a **textbook reduction oracle** (occasion-averaged == cell-means two-way).
  Neither exposes the θ² functional, so the milestone carries **no Fable-review risk** — a deliberate
  low-drama choice after two consecutive Fable-review milestones (M27/M28). It extends the oracle
  inversion (the Bayesian engine cross-checks the conflated and replicate coefficients; the M17 REML
  fits are its independent oracles) and adds a live-fit CI cost bounded by committed-reference +
  single-live-fit gating (no new dependency). This ADR authorizes M29 code; the `MILESTONES.md` M29
  board and the `STATUS.md` flip are the milestone-start companions (M29 is opened/scoped here but **no
  slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — reduction + REML agreement + coverage + convergence),
  #2/#14/#15 (name the estimand / thin vertical slices; oracle-risk ordering — conflated first), #3
  (boundary-aware — the half-*t* prior; `posterior_mode()` on [0, Inf) components / [0, 1] ICCs), #4
  (committed seeded reference; no tuning to oracle), #5/#8 (classed brms refusals for
  incomplete/fixed-replicate/conflated-consistency; `cli` notes; the conflated "never recommended"
  posture), #6 (additive, non-breaking — new engine×design combinations), #12 (sourced prior; sourced
  estimands), #16 (tracking in-commit), #18 (report the run — containment, not asserted equality, under
  the differing priors); ten Hove, Jorgensen & van der Ark (2022) Eq. 14 (conflated single-level ICC),
  Eqs. 8–11 (the five-component crossed fit conflated reads from); ten Hove, Jorgensen & van der Ark
  (2020) §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile; MCMC ≈ MLE), OSF `shkqm`;
  estimand-specs `M17-conflated-icc.md` (conflated estimand — §2 composition, §4 never-recommended, §6
  out-of-scope — no new spec) and `M17-within-cell-replicates.md` (replicate estimand — §2 per-component
  divisors, §3 `occasions`, §6 reduction oracle — no new spec); ADR-026 (M17 — the two estimands being
  given a Bayesian engine), ADR-033 (M23 Bayesian engine — the seam extended), ADR-034/035 (M24/M25
  multilevel — the conflated fit + guard-narrowing precedent), ADR-036 (M26 — single-level parity,
  containment-not-equality oracle posture), ADR-037/038 (M27/M28 — the θ² 2b moment correction, N/A here
  as both slices are variance-ratio push-forwards), ADR-002 (optional engines behind `Suggests`);
  `project/ROADMAP.md` (Bayesian conflated/replicate follow-ons being promoted), `project/COVERAGE.md`.

## ADR-040: M30 scope — Bayesian engine (brms) incomplete/ragged, two-way random + crossed multilevel random, subject level
- Date: 2026-07-10
- Status: accepted
- Context: The Bayesian arc M23→M29 (ADR-033–039, PRs #28–#34) took `engine = "brms"` +
  `ci_method = "posterior"` across every design at the subject level — two-way random/fixed, one-way,
  all multilevel crossed + nested (random and fixed), the conflated diagnostic, and within-cell
  replicates — but only on **balanced/complete** data (every brms path is gated by a single `!balanced`
  refusal, `icc.R:1125`). Incomplete/ragged Bayesian ICCs are the **isolated remaining random-rater gap**
  and the arc's next candidate (STATUS/ROADMAP). No milestone is in flight. After a short retro the
  maintainer chose to **continue the Bayesian arc with the incomplete/ragged path**, and to take **both**
  the single-level and crossed-multilevel random slices in one milestone (the M23+M24 pairing, on ragged
  data). This ADR opens **M30**. **Engine/interval parity, not new estimand work** (cf.
  M5.5/M7/M15/M21/M23–M29): the estimands are the *shipped* frequentist incomplete two-way (M3, ADR-008)
  and incomplete crossed multilevel (M9, ADR-018) random-rater coefficients — the same `k_eff`
  harmonic-mean divisor + connectedness identifiability — now read off posterior draws. No new
  estimand-spec, no new user-facing argument, no new dependency (`brms` already a `Suggests`); additive,
  non-breaking (#6): new valid `engine = "brms"` × {incomplete two-way random, incomplete crossed
  multilevel random} combinations only.
  - **Why this is thinner than "likely a gated Fable review" (STATUS/ADR-039 framing) suggested, and
    where the real risk is.** The `k_eff` divisor and *every* connectedness/identifiability guard
    (`crossed_ml_identifiability()`, harmonic-mean `k_eff`) are computed **engine-agnostically before fit
    dispatch** (`icc.R:~1316`, `design_info$k_eff`), and the brms path composes each ICC off the shipped
    `draws` contract via `posterior_summary()` using that same estimand divisor. brms fits ragged data
    natively — **the model formulas do not change** (`fit_brms_twoway`, `fit_brms_multilevel` are
    unchanged). And because both slices are **random** raters, each ICC is a **ratio of variance
    components** — the M29 mechanism — with **no θ² finite-population functional**, so the M27/M28 **2b
    moment correction does not apply** (a clean posterior push-forward; `tr(C·Σ)` is not in play). The
    2b machinery bites only for *fixed* raters, deferred here. So the mechanical work is: narrow one
    `!balanced` brms guard, add nothing to the fit/compose path. **The remaining risk is narrow and
    empirical — coverage.** The `k_eff` harmonic-mean divisor is an *approximation* on ragged data
    (oracle-pinned in the frequentist path); whether the **percentile credible interval** covers
    nominally *through that divisor* on ragged data is a seeded-simulation question (the CI method's
    oracle IS coverage, #1). **Fable posture (#19):** proceed on the working hypothesis that coverage is
    nominal (the variance-ratio regime that was clean in M29); the seeded coverage oracle is the test.
    **If** it undercovers, **recommend a gated Fable review and stop** — never auto-invoke Fable. Fable is
    not pre-authorized by this ADR; it is a conditional escalation the maintainer approves only if the
    coverage oracle exposes a shortfall.
- Decision:
  - **Scope: two-way RANDOM raters, INCOMPLETE/ragged, subject level (+ cluster-level `ICC(c,1)` for the
    multilevel slice).** Slice 1 — **Bayesian incomplete two-way random** (`engine = "brms"`, ragged
    subject × rater, `type` ∈ {agreement, consistency}, `unit` ∈ {single, average}). Slice 2 —
    **Bayesian incomplete crossed (Design 1) multilevel random** (`engine = "brms"`, ragged, `multilevel
    = TRUE`, `level` ∈ {subject, cluster}, with `design =` available for crossed/nested-ambiguous ragged
    patterns as in M9). Bayesian incomplete **fixed** (θ²_r *under imbalance* — the k_eff × 2b-moment
    interaction), incomplete **nested** Designs 2/3, incomplete **replicates**, and the averaged
    cluster-level **`ICC(c,k)`** incomplete divisor all stay deferred (scope-outs below).
  - **Slice 1 — incomplete two-way random: no new fit.** `fit_brms_twoway()` (M23) is run on ragged data
    unchanged — brms estimates the variance components from the observed cells natively. The shipped
    `!balanced` brms refusal (`icc.R:1125`) is **narrowed** to admit incomplete two-way *random* data
    (fixed / replicates / numeric-unit / nested-incomplete stay refused). The engine-agnostic
    connectedness + harmonic-mean `k_eff` machinery (M3, ADR-008) already runs pre-dispatch and threads
    `design_info$k_eff` into `icc_estimand()`; `posterior_summary()` composes each draw's ICC with that
    divisor — the exact frequentist estimand, per draw. On complete data this reduces **identically** to
    shipped M23 (`k_eff = k`).
  - **Slice 2 — incomplete crossed multilevel random: no new fit.** `fit_brms_multilevel()` (M24,
    five-component crossed Design 1) is run on ragged crossed data unchanged. The M9 multilevel
    connectedness (`crossed_ml_identifiability()`) + `k_eff` + the `design =` disambiguation are
    engine-agnostic and already run pre-dispatch (`icc.R`); the `!balanced` guard narrowing from Slice 1
    admits the crossed-random-multilevel case. **Subject level (agreement/consistency, single/average) +
    cluster-level single-rater `ICC(c,1)`** ship; the averaged cluster-level `ICC(c,k)` row is **dropped
    with the shipped note** on incomplete data (`icc.R:1341`, the open per-cluster divisor — bounded for
    *all* engines, unaffected here). On complete data this reduces **identically** to shipped M24.
  - **Point/interval/dispatch unchanged from M23–M29.** MAP = `posterior_mode()` of each estimand's
    ICC-draw vector; percentile **credible** interval; `posterior` forced-default & Bayesian-only. No new
    field beyond the shipped `draws` contract; the shared `icc_point()`/`mc_ci()` path stays untouched for
    the other engines. Both slices are random-rater **ratios of variance components** — no θ²
    finite-population functional, so the M27/M28 2b moment correction does **not** apply. The k = 2 soft
    note and the fixed/replicate/numeric-unit brms refusals stay.
  - **Two thin vertical slices** (#14/#15), oracle-risk order (single-level before multilevel):
    - **Slice 1 — Bayesian incomplete two-way random + its coverage oracle.** Guard narrowed;
      `fit_brms_twoway()` on ragged data; `k_eff` divisor per draw. A companion generator
      `data-raw/oracle-bayesian-incomplete.R` runs a seeded ragged two-way random DGP with brms + the
      half-*t* prior and **commits the reference fixture**
      `tests/testthat/fixtures/bayesian-incomplete-oracle.rds` (#4). Oracle O-Bayes-Incomplete.
    - **Slice 2 — Bayesian incomplete crossed multilevel random + its oracle.** `fit_brms_multilevel()`
      on ragged crossed data; subject + cluster-`ICC(c,1)`; the `design =` disambiguation; the
      `ICC(c,k)`-dropped note. Companion generator `data-raw/oracle-bayesian-incomplete-multilevel.R`
      commits `tests/testthat/fixtures/bayesian-incomplete-ml-oracle.rds` (#4). Oracle O-Bayes-IML.
  - **Oracles (#1 — reduction + REML agreement + coverage; M23–M29 precedent, no textbook worked
    posterior value):**
    - **O-Bayes-Incomplete** — reduction: on complete data the ragged path composes **identically** to
      shipped M23 (same `k_eff = k`); on ragged data MAP ≈ the frequentist **M3 glmmTMB** incomplete
      two-way ICC within a stated tolerance (glmmTMB the independent oracle) — **containment** of the
      glmmTMB point in the credible interval, not pointwise equality (the MAP-below-REML skew + prior gap,
      the M26/M29 posture); **seeded coverage ~nominal** off the committed fixture (the real bar — if it
      is *not* nominal, characterize honestly and recommend a gated Fable review, #18/#19); convergence
      rate from `brms_convergence()`.
    - **O-Bayes-IML** — reduction: on complete data ≡ shipped M24 (crossed five-component); on ragged
      crossed data subject-level + `ICC(c,1)` MAP ≈ the **M9 glmmTMB** incomplete multilevel coefficients
      (containment, not equality); seeded coverage ~nominal off the committed fixture; the `ICC(c,k)`
      row is dropped-with-note (asserted, not silently absent).
  - **CI test-gating (DoD), unchanged posture from M23–M29:** coverage/reduction oracles run off the
    **committed seeded reference** (#4); a **single live `brms` fit** per slice (tiny `chains`/`iter`)
    exercises the ragged wiring, guarded `skip_on_cran()` + `skip_if_not_installed("brms")` +
    `skip_on_ci()` ([[brms-live-fit-skip-on-ci]]); reduced draws in tests. Coverage stays ~85% by design
    ([[coverage-baseline]]); consented up front.
  - **No new estimand, estimand-spec file, user-facing argument, or dependency.** The change is: two
    narrowed brms guards in `R/icc.R` (the `!balanced` refusal admits incomplete two-way random +
    incomplete crossed multilevel random), and the committed oracle generators + fixtures. No new fit
    function — `fit_brms_twoway()`/`fit_brms_multilevel()` are reused verbatim. Reuses the shipped
    estimand-specs `M3-incomplete-designs.md` and `M9-incomplete-multilevel.md` — no new spec.
  - **Scope-outs (preserved, not rediscovered):** Bayesian incomplete **fixed-rater** (two-way + crossed
    multilevel — pairs the M3 `k_eff` divisor with the M27/M28 θ² **2b moment correction under
    imbalance**; genuinely higher-risk, its own later slice); Bayesian incomplete **nested** Designs 2/3
    (the M19 Slice 1 analog); Bayesian incomplete **within-cell replicates** (imbalance × replicates, the
    M20 corner); the averaged cluster-level **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, open for all
    engines, M9 §9); Bayesian **numeric-unit `d_study()`** projection; plus the M23 carry-overs —
    **rstanarm** backend, **selectable** `posterior` coupling, **HPDI** intervals, **user-exposed
    `prior=`** API. All stay in `ROADMAP.md`.
- Consequences: On M30 close, `engine = "brms"` covers incomplete/ragged **random**-rater ICCs at the
  two-way single level and the crossed Design-1 multilevel subject + cluster-`ICC(c,1)` levels — leaving
  Bayesian incomplete **fixed** and **nested**, incomplete **replicates**, and the ⚫/🟣/infra
  carry-overs as the remaining brms gaps. The milestone is mechanically thin (two guard narrowings, no
  new fit) but carries one genuine unknown — **ragged-data coverage of the percentile credible interval
  through the `k_eff` divisor** — deliberately isolated to random raters so the θ² 2b machinery is not
  entangled. If the seeded coverage oracle is nominal, M30 ships clean with **no Fable review** (the
  variance-ratio regime, as M29); if it undercovers, the honest finding is characterized and a gated
  Fable review is **recommended, not performed** (#19). It extends the oracle inversion (the Bayesian
  engine cross-checks the M3/M9 frequentist incomplete coefficients; the REML fits are its independent
  oracles) and adds a live-fit CI cost bounded by committed-reference + single-live-fit gating (no new
  dependency). This ADR authorizes M30 code; the `MILESTONES.md` M30 board and the `STATUS.md` flip are
  the milestone-start companions (M30 is opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — reduction + REML agreement + coverage + convergence),
  #2/#14/#15 (name the estimand / thin vertical slices; oracle-risk ordering — single-level first), #3
  (boundary-aware — the half-*t* prior; `posterior_mode()`), #4 (committed seeded reference; no tuning to
  oracle), #5/#8 (classed brms refusals for incomplete fixed / nested / replicates / numeric-unit; `cli`
  notes; the `ICC(c,k)`-dropped note), #6 (additive, non-breaking — new engine×design combinations), #12
  (sourced prior; sourced estimands), #16 (tracking in-commit), #18 (report the run — containment not
  asserted equality; characterize coverage honestly), #19 (Fable never auto-invoked — conditional on a
  coverage shortfall, recommend-and-stop); ten Hove, Jorgensen & van der Ark (2022) Eqs. 8–11 (the
  five-component crossed fit) — the incomplete/small-k estimator choice flagged as an open research
  question is what motivates the coverage-calibration caution; ten Hove, Jorgensen & van der Ark (2020)
  §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile), OSF `shkqm`; estimand-specs
  `M3-incomplete-designs.md` (`k_eff`/connectedness — no new spec) and `M9-incomplete-multilevel.md`
  (incomplete crossed multilevel, `design=` disambiguation, cluster `ICC(c,1)` ships / `ICC(c,k)` open —
  no new spec); ADR-008 (M3 `k_eff`/connectedness — reused engine-agnostic), ADR-018 (M9 incomplete
  crossed multilevel — reused), ADR-033 (M23 Bayesian engine — the seam extended), ADR-034 (M24 crossed
  multilevel — the fit reused), ADR-036 (M26 — containment-not-equality oracle posture), ADR-037/038
  (M27/M28 — the θ² 2b moment correction, N/A here as both slices are variance-ratio push-forwards),
  ADR-039 (M29 — the immediately prior variance-ratio Bayesian milestone; deferred incomplete/ragged to
  M30), ADR-002 (optional engines behind `Suggests`); `project/ROADMAP.md` (Bayesian incomplete random
  follow-on being promoted), `project/COVERAGE.md`.

## ADR-041: M31 scope — Bayesian engine (brms) incomplete/ragged FIXED-rater ICCs, two-way single level + crossed Design-1 multilevel, subject level
- Date: 2026-07-10
- Status: accepted
- Context: M30 (ADR-040, PR #35) closed the incomplete/ragged **random**-rater Bayesian gap at the two-way
  single level and the crossed Design-1 multilevel subject + cluster-`ICC(c,1)` levels, and its one
  unknown — ragged coverage of the percentile credible interval through the `k_eff` divisor — came back
  **nominal** at the subject level, precisely because M30 was scoped random-only: random raters make each
  ICC a **ratio of variance components**, a clean posterior push-forward with **no θ² finite-population
  functional**, so the M27/M28 **2b moment correction never engaged**. ADR-040 named the deferred
  siblings explicitly, the first being Bayesian incomplete **fixed-rater** — flagged as "genuinely
  higher-risk" because it "pairs the M3 `k_eff` divisor with the M27/M28 θ² 2b moment correction under
  imbalance". No milestone is in flight. After a short retro the maintainer chose to **continue the
  Bayesian arc with the incomplete/ragged FIXED-rater path**, taking **both** the single-level and
  crossed-multilevel slices in one milestone (mirroring M30's two-slice structure). This ADR opens
  **M31**. **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M15/M21/M23–M30): the estimands
  are the *shipped* frequentist incomplete single-level fixed θ²_r (M3 Case-3A under imbalance, ADR-008)
  and incomplete crossed-multilevel fixed θ²_r (M18 Slice 1, ADR-028) — the same `theta2r_fixed()`
  finite-population variance + `k_eff` harmonic-mean divisor — now read off posterior draws. No new
  estimand-spec, no new user-facing argument, no new dependency (`brms` already a `Suggests`); additive,
  non-breaking (#6): new valid `engine = "brms"` × {incomplete two-way fixed, incomplete crossed
  multilevel fixed} combinations only, by narrowing the same `!balanced` brms guard M30 touched
  (`icc.R:1128`; the `raters == "fixed"` and `multilevel && ml_design != "crossed"` clauses).
  - **Where the real risk is (and why it is genuinely higher than M30's).** The shipped balanced fixed
    brms path already moment-corrects θ²_r per draw via `brms_theta2r_moment_draws()` — subtract **2b**,
    `b = tr(C·Σ_post)/(k−1)`, and floor the group **average** (ADR-037/038 amendment, the gated-Fable
    resolution). But in the balanced single-level/crossed regime the rater means are estimated from the
    **whole sample**, so `b ≈ 0` and the correction is *invisible* — the shipped balanced fixed fits
    (M26/M27 Slice 1) behave as the raw push-forward. On **incomplete/ragged** data the rater means are
    estimated from **unequal cell counts**, so **`b ≠ 0` for the first time in the single-level regime**:
    the 2b machinery goes live where it has never been exercised. That is exactly the "pairs `k_eff` with
    the 2b correction" hazard ADR-040 flagged. **The remaining risk is narrow and empirical — coverage.**
    Whether the percentile credible interval covers nominally once `b ≠ 0` single-level is a
    seeded-simulation question (the CI method's oracle IS coverage, #1). **Fable posture (#19):** proceed
    on the working hypothesis that the shipped 2b + average-floor keeps coverage nominal on ragged data
    (it was derived for exactly this displacement, just never before active single-level); the seeded
    coverage oracle is the test. **If** it undercovers, **recommend a gated Fable review and stop** —
    never auto-invoke Fable. Fable is not pre-authorized by this ADR; it is a conditional escalation the
    maintainer approves only if the coverage oracle exposes a shortfall.
- Decision:
  - **Scope: FIXED raters, INCOMPLETE/ragged, subject level.** Slice 1 — **Bayesian incomplete two-way
    fixed** (`engine = "brms"`, `raters = "fixed"`, ragged two-way): narrow the `raters == "fixed"` clause
    of the `!balanced` brms guard for the single-level two-way case; `fit_brms_fixed()` runs unchanged on
    ragged data (`brms_theta2r_draws()` reads the k rater means from `b_Intercept` + treatment contrasts,
    now with `b ≠ 0`); ICC(A,1)/ICC(A,k) compose off the same M3 `k_eff` divisor. Slice 2 — **Bayesian
    incomplete crossed (Design 1) fixed multilevel** (`fit_brms_multilevel_fixed()` on ragged data; the
    Bayesian sibling of M18 Slice 1), subject level; narrow the multilevel clause of the same guard. Both
    reuse the engine-agnostic `k_eff`/connectedness machinery that runs pre-dispatch (M3/M9), and the
    shipped `brms_theta2r_moment_draws()` (2b + boundary-aware average-floor) unchanged.
  - **Oracles (#1, no textbook worked example — as M8–M10/M18/M24–M30):** O-Bayes-IFixed (single level) /
    O-Bayes-IFML-fixed (crossed multilevel): (a) **reduction** — at balance the ragged fixed fit ≡ the
    shipped balanced fixed brms fit (M26 / M27 Slice 1); (b) **-agree** — the MAP tracks the glmmTMB
    frequentist incomplete fixed point (M3 / M18 Slice 1) by **CONTAINMENT** (glmmTMB inside the credible
    interval), not pointwise equality — the flat-prior-on-rater-effects skew (ADR-036 posture) plus the
    ragged small-sample regime; (c) **-coverage** — a committed seeded ragged-data coverage fixture (the
    one unknown), companion to the M30 `oracle-bayesian-incomplete.R` scripts, live `-agree` fits
    `skip_on_ci()`, CI covered by the committed fixture.
  - **Conditional gated Fable review (#19):** if the seeded ragged fixed-rater coverage oracle
    undercovers, characterize the finding honestly (#18) and **recommend** a Fable review of the 2b /
    average-floor interaction with `k_eff` under imbalance — **recommend-and-stop**, never auto-invoke.
  - **Deferred out of M31** (record so not rediscovered): Bayesian incomplete **NESTED** fixed (Design 2,
    the M19 Slice 2 analog on ragged data); Bayesian **cluster-level fixed** rater ICC (undefined /
    deferred for all engines); Bayesian incomplete **within-cell replicates** (imbalance × replicates, the
    M20 corner); Bayesian **one-way** incomplete (M6 analog, low value); the averaged cluster-level
    **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, open for all engines, M9 §9 — the crossed-multilevel
    fixed slice ships subject-level only, cluster `ICC(c,k)` dropped-with-note as M30); Bayesian
    **numeric-unit `d_study()`** projection; the M23 carry-overs (rstanarm backend, selectable
    `posterior` coupling, HPDI intervals, user-exposed `prior=`). All stay in `ROADMAP.md`.
- Consequences: On M31 close, `engine = "brms"` covers incomplete/ragged **fixed**-rater ICCs at the
  two-way single level and the crossed Design-1 multilevel subject level — leaving Bayesian incomplete
  **nested** fixed, **cluster-level** fixed, incomplete **replicates**, incomplete **one-way**, and the
  ⚫/🟣/infra carry-overs as the remaining brms gaps. The milestone is mechanically thin (two guard
  narrowings, no new fit, no new θ² helper — `brms_theta2r_moment_draws()` already ships) but carries one
  genuine unknown — **ragged-data coverage of the percentile credible interval once the 2b θ² moment
  correction is active single-level (`b ≠ 0`)** — the reason the fixed corner was held back from the
  random-only M30. If the seeded coverage oracle is nominal, M31 ships clean with **no Fable review**; if
  it undercovers, the honest finding is characterized and a gated Fable review is **recommended, not
  performed** (#19). It extends the oracle inversion (the Bayesian engine cross-checks the M3/M18
  frequentist incomplete fixed coefficients; the REML fits are its independent oracles) and adds a
  live-fit CI cost bounded by committed-reference + `skip_on_ci` gating (no new dependency). This ADR
  authorizes M31 code; the `MILESTONES.md` M31 board and the `STATUS.md` flip are the milestone-start
  companions (M31 is opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — reduction + glmmTMB agreement + coverage), #2/#14/#15 (name
  the estimand / thin vertical slices; oracle-risk ordering — single-level first), #3 (boundary-aware —
  the 2b average-floor; `posterior_mode()`), #4 (committed seeded reference; no tuning to oracle), #5/#8
  (classed brms refusals for incomplete nested / cluster-fixed / replicates / one-way / numeric-unit;
  `cli` notes), #6 (additive, non-breaking — new engine×design combinations), #12 (sourced estimands),
  #16 (tracking in-commit), #18 (report the run — containment not asserted equality; characterize
  coverage honestly), #19 (Fable never auto-invoked — conditional on a coverage shortfall,
  recommend-and-stop); McGraw & Wong (1996) Case 3/3A (fixed raters, finite-population θ²_r); ten Hove,
  Jorgensen & van der Ark (2020) §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile), OSF
  `shkqm`; estimand-specs `M3-incomplete-designs.md` §6 (Case-3A θ²_r under imbalance — no new spec),
  `M10-fixed-multilevel.md` / `M9-incomplete-multilevel.md` (fixed crossed multilevel incomplete — no new
  spec); ADR-008 (M3 `k_eff` + `theta2r_fixed()` under imbalance — reused engine-agnostic), ADR-019 (M10
  fixed crossed multilevel), ADR-028 (M18 Slice 1 incomplete fixed crossed multilevel — the frequentist
  sibling), ADR-033 (M23 Bayesian engine — the seam extended), ADR-036 (M26 — raw-θ² fixed brms +
  containment-not-equality oracle posture), ADR-037/038 (M27/M28 — the θ² **2b** moment correction +
  boundary-aware average-floor; `brms_theta2r_moment_draws()`, the machinery that goes live single-level
  here), ADR-040 (M30 — the immediately prior incomplete/ragged random Bayesian milestone; deferred
  incomplete fixed to a later slice, promoted here), ADR-002 (optional engines behind `Suggests`);
  `project/ROADMAP.md` (Bayesian incomplete fixed follow-on being promoted), `project/COVERAGE.md`.

## ADR-042: M32 scope — Bayesian engine (brms) incomplete/ragged NESTED random ICCs, Designs 2 & 3, subject level
- Date: 2026-07-10
- Status: accepted
- Context: M30 (ADR-040, PR #35) closed the incomplete/ragged **random**-rater Bayesian gap for the two-way
  single level and the **crossed** (Design 1) multilevel; M31 (ADR-041, PR #36) closed the incomplete
  **fixed**-rater corner for the same two designs. Both came back **nominal** on their one unknown
  (ragged coverage through `k_eff`). What remains open on the "brms × incomplete" row are the **nested**
  designs (raters nested in clusters, Design 2; raters nested in subjects, Design 3 / multilevel one-way):
  the brms engine fits them only balanced/complete (M25, ADR-035), because the `!balanced` brms guard's
  `(multilevel && ml_design != "crossed")` clause (`icc.R:1148–1152`) still refuses them on ragged data.
  No milestone is in flight. After a short retro — which noted the Bayesian arc has moved from *discovery*
  (M27/M28's 2b moment correction) into *mop-up* (M29/M30/M31 all nominal, no Fable) — the maintainer chose
  to **continue the mop-up with the incomplete/ragged nested corner**. This ADR opens **M32**.
  - **An oracle-first scoping catch bounds the milestone to RANDOM raters.** The natural instinct was to
    mirror M30→M31 (random slice, then a fixed slice). But **incomplete fixed-rater nested is deferred for
    *every* engine**, not just brms: `icc.R:685–696` (ADR-029, M19) refuses `raters = "fixed"` ×
    `nested_in_clusters` × `!balanced` for glmmTMB itself — the M3 `k_eff` divisor paired with the
    per-cluster θ²_{r:c} finite-population correction under imbalance is "two interacting corrections
    needing their own oracle", and that frequentist estimand has never been built. **With no frequentist
    incomplete-fixed-nested path, there is no independent oracle** (#1), so a Bayesian incomplete-fixed-nested
    slice cannot ship as engine parity — it would be *new research* (the frequentist version must exist
    first). M32 is therefore **random-only**; incomplete fixed nested stays deferred (below).
  - **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M15/M21/M23–M31): the estimand is the
    *shipped* frequentist incomplete nested **random** subject-level coefficient (M19, the M8/M9 machinery
    on ragged nested data — ten Hove et al. 2022 Eqs. 8–11, Table 3 middle/right), now read off posterior
    draws. No new estimand-spec, no new user-facing argument, no new dependency (`brms` already a
    `Suggests`); additive, non-breaking (#6): new valid `engine = "brms"` × {incomplete nested Design 2,
    incomplete nested Design 3} combinations only, by narrowing the same `!balanced` brms guard M30/M31
    touched (`icc.R:1148–1152`, the `ml_design != "crossed"` clause).
  - **Where the risk is (and why it is genuinely LOWER than M31's).** Random raters make each ICC a **ratio
    of variance components** — a clean posterior push-forward with **no θ² finite-population functional**, so
    the M27/M28 **2b moment correction never engages** (the M30 regime, not the M31 regime). The shipped M25
    nested fits (`fit_brms_nested_clusters` / `fit_brms_nested_subjects`) run *unchanged* on ragged data; the
    M3/M9 `k_eff` + connectedness machinery is engine-agnostic and runs **pre-dispatch**, so it protects
    brms exactly as it does glmmTMB. **The one remaining unknown is narrow and empirical — coverage.**
    Whether the percentile credible interval covers nominally once the nested fit sees ragged data through
    `k_eff` is a seeded-simulation question (the CI method's oracle IS coverage, #1). Because there is no θ²
    functional here, the working hypothesis (as M30) is that it comes back **nominal**. **Fable posture
    (#19):** the seeded coverage oracle is the test; **if** it undercovers, **recommend a gated Fable review
    and stop** — never auto-invoke. Fable is not pre-authorized by this ADR.
- Decision:
  - **Scope: RANDOM raters, INCOMPLETE/ragged, NESTED (Designs 2 & 3), subject level.** Nested designs are
    subject-level only (the cluster level is undefined for nested raters — already enforced, M8/M25). Two
    thin slices, mirroring the M25 split. **Slice 1 — Bayesian incomplete nested Design 2** (raters nested
    in clusters): narrow the `ml_design != "crossed"` guard clause for `nested_in_clusters` on ragged data;
    `fit_brms_nested_clusters()` runs unchanged; the M3 `k_eff` divisor + M9 connectedness compose the
    subject-level agreement/consistency ICCs per posterior draw. **Slice 2 — Bayesian incomplete nested
    Design 3** (raters nested in subjects, the multilevel one-way, agreement-only): narrow the same clause
    for `nested_in_subjects`; `fit_brms_nested_subjects()` unchanged. No new fit, no new θ² helper (none is
    needed — random regime).
  - **Oracles (#1, no textbook worked example — as M8–M10/M25/M30):** O-Bayes-INML-clusters (Design 2) /
    O-Bayes-INML-subjects (Design 3): (a) **reduction** — at balance the ragged nested fit ≡ the shipped
    balanced nested brms fit (M25 Slice 1 / Slice 2); (b) **-agree** — the MAP tracks the glmmTMB
    frequentist incomplete nested random point (M19, `icc.R:1068`) by **CONTAINMENT** (glmmTMB inside the
    credible interval), not pointwise equality (the half-*t* prior + ragged small-sample regime, the ADR-035
    posture); (c) **-coverage** — a committed seeded ragged-data coverage fixture (the one unknown),
    companion to the M30 `oracle-bayesian-incomplete.R` / `oracle-bayesian-incomplete-multilevel.R` scripts;
    live `-agree` fits `skip_on_ci()`, CI covered by the committed fixture.
  - **Conditional gated Fable review (#19):** if either seeded nested coverage oracle undercovers,
    characterize the finding honestly (#18) and **recommend** a Fable review of the ragged nested
    push-forward under `k_eff` — **recommend-and-stop**, never auto-invoke.
  - **Deferred out of M32** (record so not rediscovered): Bayesian incomplete **fixed** nested (Designs 2/3)
    — **has no frequentist oracle** (deferred all engines, ADR-029, `icc.R:685`); it is *research*, not
    parity, and needs the frequentist incomplete-fixed-nested estimand built first (the k_eff × per-cluster
    θ²_{r:c} interaction, likely a Fable-reviewed simulation study — the nested sibling of the M9 `ICC(c,k)`
    divisor). Bayesian **cluster-level** rater ICC for nested designs (undefined — the cluster level needs
    crossed raters). Bayesian incomplete **within-cell replicates** (imbalance × replicates, M20 corner);
    Bayesian **one-way** incomplete single-level (M6 analog, low value — distinct from the Design-3
    *multilevel* one-way shipping here); the averaged cluster-level **`ICC(c,k)` incomplete divisor** (🟣
    Wave-3, open all engines, M9 §9 — not reachable, nested designs report no cluster level); Bayesian
    **numeric-unit `d_study()`**; the M23 carry-overs (rstanarm backend, selectable `posterior` coupling,
    HPDI intervals, user-exposed `prior=`). All stay in `ROADMAP.md`.
- Consequences: On M32 close, `engine = "brms"` covers incomplete/ragged **random**-rater ICCs across the
  whole design surface it fits balanced — two-way single level, crossed (Design 1) multilevel, and now both
  **nested** designs (2/3) at the subject level — completing the "brms × incomplete × random" row. The
  remaining brms gaps become: incomplete **fixed** nested (research, no oracle), **cluster-level** fixed,
  incomplete **replicates**, incomplete single-level **one-way**, and the ⚫/🟣/infra carry-overs. The
  milestone is mechanically thin (one guard clause narrowed across two `ml_design` values, no new fit, no
  new θ² helper — the random regime needs none) and carries the *lowest* residual risk of the mop-up corners
  (no 2b functional), with the single empirical unknown — ragged-data coverage of the percentile credible
  interval for nested designs — resolved by a committed seeded oracle. If nominal, M32 ships clean with **no
  Fable review** (as M29/M30); if it undercovers, the honest finding is characterized and a gated Fable
  review is **recommended, not performed** (#19). It extends the oracle inversion (the brms nested fits
  cross-check the M19 frequentist incomplete nested random coefficients; the REML fits are its independent
  oracles) at a live-fit CI cost bounded by committed-reference + `skip_on_ci` gating (no new dependency).
  This ADR authorizes M32 code; the `MILESTONES.md` M32 board and the `STATUS.md` flip are the
  milestone-start companions (M32 is opened/scoped here but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — reduction + glmmTMB agreement + coverage; the scoping catch
  that no incomplete-fixed-nested oracle exists), #2/#14/#15 (name the estimand / thin vertical slices;
  oracle-risk ordering — Design 2 before Design 3), #3 (boundary-aware — `posterior_mode()`; MC-CI), #4
  (committed seeded reference; no tuning to oracle), #5/#8 (classed brms refusals for incomplete fixed
  nested / cluster-level / replicates / one-way / numeric-unit; `cli` notes), #6 (additive, non-breaking —
  new engine×design combinations), #12 (sourced estimands), #16 (tracking in-commit), #18 (report the run —
  containment not asserted equality; characterize coverage honestly), #19 (Fable never auto-invoked —
  conditional on a coverage shortfall, recommend-and-stop); ten Hove, Jorgensen & van der Ark (2022) Eqs.
  8–11, Table 3 middle/right (nested Designs 2/3 subject-level coefficients), (2020) §3.3/§4.1
  (half-*t*(4,0,1) on SDs; DGP), §4.2 (MAP/percentile), OSF `shkqm`; estimand-spec
  `M8-nested-multilevel.md` (nested subject-level coefficients — no new spec) with `M9-incomplete-multilevel.md`
  / `M3-incomplete-designs.md` §6 (`k_eff` + connectedness under imbalance — reused engine-agnostic); ADR-008
  (M3 `k_eff`), ADR-016 (M8 nested designs), ADR-018 (M9 incomplete crossed), ADR-029 (M19 — incomplete
  nested **random** ships / incomplete **fixed** nested deferred all engines: the reason M32 is random-only),
  ADR-033 (M23 Bayesian engine — the seam extended), ADR-035 (M25 — the balanced nested brms fits reused:
  `fit_brms_nested_clusters` / `fit_brms_nested_subjects`), ADR-040 (M30 — the incomplete/ragged **random**
  crossed Bayesian milestone this extends to nested; the variance-ratio-no-2b regime), ADR-041 (M31 — the
  incomplete fixed sibling; named incomplete nested fixed as a deferred later slice), ADR-002 (optional
  engines behind `Suggests`); `project/ROADMAP.md` (Bayesian incomplete nested follow-on being promoted),
  `project/COVERAGE.md`.
- **Amendment (2026-07-10, M32 Slice 2 — coverage finding + gated Fable recommendation, #18/#19):** the
  a-priori "random → no 2b → nominal" hypothesis **held for Slice 1 (Design 2)** — the O-Bayes-INML-clusters
  seeded oracle came back nominal (ragged coverage .925/.925 vs complete .95/.95, seed 32100, n_rep 80), so
  Slice 1 shipped clean (committed `7b8b60c`). **It did NOT hold for Slice 2 (Design 3, the multilevel
  one-way).** The O-Bayes-INML-subjects oracle (seed 32200, n_rep 80) found the **complete cell nominal
  (.975/.975)** but the **ragged cell undercovering: coverage .8625/.8625** for ICC(1)/ICC(k) — 3.6 SD below
  the .95 nominal (a real signal, not MC noise at n_rep 80), with the **point unbiased** (rel-bias ≈ 0), so
  the **credible interval is too narrow** on ragged Design-3 data, not the point biased. This is
  **Design-3-specific**: it did not appear in the crossed random (M30) or nested Design-2 (Slice 1) ragged
  paths, all nominal. Plausible mechanism (for Fable to adjudicate): in Design 3 the rater main effect is
  confounded into the residual and each subject carries its own raters, so under imbalance the per-subject
  effective information varies and the scalar `k_eff` + posterior push-forward may under-propagate that
  variability — a *calibration* shortfall distinct from the M27/M28 finite-population θ² **2b** displacement
  (there is no θ² functional here). **Per #19 the response is recommend-and-stop:** the pin is **not
  loosened** (#4 — the committed test asserts ragged coverage ≥ .88 and fails on the evidence fixture, the
  honest signal), Fable is **not auto-invoked**, and the maintainer (2026-07-10) approved **recommending a
  gated Fable review**. **Fable's charge:** confirm/characterize the ragged one-way undercoverage (magnitude,
  robustness across incidences and higher `n_rep`) and rule on whether a calibration correction is warranted
  or incomplete nested **Design 3** should be **deferred as research** (the multilevel-one-way sibling of the
  M9 `ICC(c,k)` divisor). **This amendment records the finding + recommendation; the verdict is pending the
  maintainer's manual Fable run and will be recorded as a follow-up amendment** (the M32 board Slice 2 line
  stays `[~]` blocked until then). Slice 1 (Design 2) is unaffected and shipped.
- **Amendment 2 (2026-07-10, M32 Slice 2 — Fable verdict ADOPTED: no shortfall, ship unchanged, #19):** the
  gated Fable review (Claude Fable 5; brief `project/fable-brief-m32-s2.md`, response + seeded harness
  `data-raw/reviews/fable-review-m32-s2-response.md` / `fable-check-m32s2.R` / `fable-check-m32s2-results.rds`)
  returned: **the ragged Design-3 undercoverage does NOT replicate — the n_rep-80 `.8625` cell was a
  Monte-Carlo tail event (one-sided P ≈ .002), not an estimator property.** Fable re-ran the *same* seeded
  incidence at n = 240 → coverage **.9458** [Wilson .910–.968]; four fresh incidences (Bayes) → **.9500**; a
  2,000-fit **frequentist** arm on the same incidence → **.9555**. Observing 227/240 under a true .8625 is a
  z ≈ +3.8 event (excluded). Mechanism checks: the population-value **PIT is uniform** across 560 ragged
  posteriors (KS D = .028, p = .76 — the percentile interval is calibrated, no under-dispersion); posterior
  sd (.0486) matches the empirical sampling sd (.0509) — the Bernstein–von Mises regime (100 subjects,
  ~340 residual df), where a 9-point coverage collapse from 12% missingness has no room to exist. **Every
  proposed mechanism rejected**, including my brief's `k_eff` under-propagation hypothesis — Fable noted
  ICC(1) takes **no divisor**, so `k_eff` never enters the undercovering interval, and that **ICC(1)/ICC(k)
  identical coverage is STRUCTURAL** (percentile intervals are equivariant under the monotone ICC(1)→ICC(k)
  transform), not two independent evidence points (a correction to the brief's §2 framing). **Disposition
  (advisory #19, adopted by the maintainer 2026-07-10):** (1) **ship M32 Slice 2 UNCHANGED** — estimator
  needs no correction, design needs no deferral; on the brief's §4 dichotomy, (A) with an empty correction
  and (B) deferral unsupported. (2) **Regenerate the coverage fixture at n_rep = 240 + per-rep seeding,
  keeping every pin exactly as committed** (ragged ≥ .88 NOT loosened, #4) — a pre-registered precision
  upgrade, not seed-shopping; the follow-up records that the n_rep-80 cell read .8625 and why (this
  amendment). (3) **Adopt n_rep ≥ 240 for future ragged coverage cells** — at n_rep = 80 the ≥ .88 pin
  carries a ~0.7% per-cell false-alarm rate (this firing was ~expected across the M23–M32 n_rep-80 family).
  (4) Record Fable's **frequentist** ragged-D3 coverage (.9555) in the O-NML/incomplete registry — it closes
  a real gap (M19 pinned point reductions only, no ragged-D3 *coverage* evidence). **Falsifiability:** a
  regenerated n_rep-240 fixture with ragged coverage < .90 would reopen this (P ≈ 1e-5 under the review's
  estimate). With this verdict M32 Slice 2 unblocks; the milestone ships both nested designs (2/3) random at
  the subject level — the mop-up hypothesis (random → no 2b → nominal) held after the tail-event scare.

## ADR-043: M33 scope — Bayesian engine (brms) parity mop-up: incomplete single-level one-way + fixed-rater & multilevel within-cell replicates
- Date: 2026-07-10
- Status: accepted
- Context: The incomplete/ragged brms row is closed — M30 (ADR-040) random, M31 (ADR-041) fixed, M32
  (ADR-042) nested random. A short retro read the Bayesian arc as having moved from *discovery* (M27/M28's
  2b moment correction for the finite-population θ² functional) into *mop-up* (M29–M32 all shipped without a
  corrective Fable review; M32's one gated review resolved to "no shortfall, a Monte-Carlo tail event").
  What remains on the "brms parity" ledger — the **last clean-oracle estimand gaps** the balanced/complete
  and incomplete arcs left behind — are three single corners: incomplete single-level **one-way**,
  **fixed-rater** within-cell replicates, and **multilevel** within-cell replicates (M29 Slice 2 shipped only
  *two-way random single-level* replicates). No milestone is in flight. The maintainer chose to close these
  three in one milestone (the "parity mop-up"), the recorded direction **(A)** of the 2026-07-10 planning
  discussion (`ROADMAP.md`). This ADR opens **M33**.
  - **The gate is met: every corner has an independent frequentist oracle** (#1) — the precondition the
    planning discussion set before an ADR (and the reason the M32 incomplete-*fixed*-nested corner was scoped
    *out*, ADR-029/ADR-042: it had none). Slice 1 (incomplete one-way) → the shipped frequentist glmmTMB/lme4
    **incomplete one-way** (M6 + the M3 `k_eff` divisor, `COVERAGE.md` §3). Slice 2 (fixed replicates) → the
    shipped frequentist **M20 Slice 1** (balanced fixed-rater replicates, `theta2r_fixed()` in the rater
    slot). Slice 3 (multilevel replicates) → the shipped frequentist **M20 Slice 2** (crossed Design 1
    six-component + nested Design 2 five-component, balanced). All three ship as engine parity, not research.
  - **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M15/M21/M23–M32): each estimand is a
    *shipped* frequentist coefficient now read off posterior draws. No new estimand-spec (reuses
    [`M6-oneway.md`](estimand-specs/M6-oneway.md) and
    [`M17-within-cell-replicates.md`](estimand-specs/M17-within-cell-replicates.md)), no new user-facing
    argument, no new dependency (`brms` already a `Suggests`); additive, non-breaking (#6) — new valid
    `engine = "brms"` combinations only, by narrowing two existing brms guards (`icc.R:1122`, `icc.R:1158`).
  - **Where the risk is, per slice (and why it is low).** The three corners sit in *different* regimes, and
    only one carries a genuine empirical unknown:
    - **Slice 1 — incomplete/ragged one-way, RANDOM.** Each ICC is a **ratio of variance components** — a
      clean posterior push-forward, **no θ² functional**, so the M27/M28 2b moment correction never engages
      (the M30 regime). `fit_brms_oneway()` (M26 Slice 1) runs *unchanged* on ragged data; the M3/M6 `k_eff`
      harmonic-mean divisor is engine-agnostic and runs **pre-dispatch**. **The one unknown is ragged-data
      coverage of the percentile credible interval** (the CI method's oracle IS coverage, #1). As M30, the
      working hypothesis is **nominal**. Per M32/ADR-042 Amendment 2, the seeded coverage fixture uses
      **n_rep ≥ 240** (the ≥ .88 ragged pin false-alarms ~0.7%/cell at n_rep 80).
    - **Slice 2 — balanced fixed-rater replicates.** θ²_r *is* a finite-population functional, but on
      **balanced** replicate data `b = tr(C·Σ_post)/(k−1) ≈ 0` (the rater means come from the whole sample),
      so the 2b moment correction is **negligible/invisible** — the M26/M27-S1 regime, *not* the ragged M31
      regime where 2b went live. On balanced data θ²_r = σ²_r, so fixed reproduces the random replicate
      coefficients (the M20 Slice 1 identity). Reuses the shipped `brms_theta2r_moment_draws()` — no new θ²
      helper.
    - **Slice 3 — balanced multilevel replicates, RANDOM.** Variance-ratio push-forward (no θ²); the residual
      splits into the interaction σ²_{csr} and pure error at the subject level, with the `occasions` per-draw
      divisor (M29 machinery). Balanced → coverage tracks M29 (nominal expected). The lift is *mechanical*
      (two fits mirroring the M20 Slice 2 shapes), not statistical.
  - **Fable posture (#19):** the only genuine unknown is Slice 1's ragged-data coverage; Slices 2–3 are
    balanced and expected nominal by construction. **If** the Slice 1 seeded oracle undercovers, characterize
    the finding honestly (#18) and **recommend a gated Fable review and stop** — never auto-invoke. Fable is
    not pre-authorized by this ADR.
- Decision:
  - **Scope: three thin slices, ordered by oracle risk (#15)** — Slice 1 first (the one ragged corner, the
    coverage unknown), then the two balanced replicate corners (fixed, then the larger multilevel lift).
  - **Slice 1 — Bayesian incomplete/ragged single-level one-way.** Narrow the `if (oneway || replicates)`
    clause of the `!balanced` brms guard (`icc.R:1158`) to drop `oneway` for the single-level case;
    `fit_brms_oneway()` runs unchanged; the M3/M6 `k_eff` divisor + connectedness compose ICC(1)/ICC(1,k) per
    posterior draw. No new fit. **Oracle O-Bayes-IOneway** (#1): (a) **reduction** — at balance the ragged
    one-way fit ≡ the shipped M26 Slice 1 balanced one-way; (b) **-agree** — MAP tracks the glmmTMB/lme4
    frequentist incomplete one-way point by **CONTAINMENT** (inside the credible interval), not pointwise
    equality (the ADR-036 half-*t* posture); (c) **-coverage** — a committed seeded ragged coverage fixture
    at **n_rep ≥ 240**, companion to the M30 `oracle-bayesian-incomplete.R`.
  - **Slice 2 — Bayesian fixed-rater within-cell replicates (balanced).** Narrow the
    `if (replicates && (multilevel || raters == "fixed"))` guard (`icc.R:1122`) to admit single-level
    `raters = "fixed"` replicates; a fixed-rater replicate fit
    (`score ~ 1 + rater + (1|subject) + (1|subject:rater)`) reusing the M20 Slice 1 formula + the M29
    replicate machinery, with θ²_r read per draw via the shipped `brms_theta2r_moment_draws()` (2b ≈ 0 on
    balanced data). **Oracle O-Bayes-FRep:** reduction (balanced fixed ≡ random replicate coefficients, the
    M20 identity θ²_r = σ²_r) + glmmTMB M20 Slice 1 containment + seeded coverage (balanced, standard n_rep) +
    average > single.
  - **Slice 3 — Bayesian multilevel within-cell replicates (balanced).** Narrow the same `icc.R:1122` guard's
    `multilevel` clause; crossed Design 1 (`(1|cluster:subject:rater)`, six components) and nested Design 2
    (five components) replicate fits mirroring M20 Slice 2, the residual splitting into σ²_{csr} + pure error
    at the subject level with the `occasions` per-draw divisor. Design 3 replicate-split stays ⚫ by design
    (multilevel one-way — no separable interaction, as M20). **Oracle O-Bayes-MLRep:** reduction
    (occasion-averaged ≡ M5/M8 on cell means) + glmmTMB M20 Slice 2 containment + seeded coverage.
  - **Oracles (#1, no textbook worked example — as M20/M29):** reduction + glmmTMB/lme4 agreement (containment)
    + committed seeded coverage; live `-agree` fits `skip_on_ci()`, CI covered by the committed fixtures.
  - **Conditional gated Fable review (#19):** only Slice 1's ragged coverage is a real unknown; if it
    undercovers, characterize honestly and **recommend-and-stop**.
  - **Deferred out of M33** (record so not rediscovered): **ragged / occasion-averaged** replicates
    (`occasions = "average"` on unequal cell counts — 🟣 research, no scalar effective-`n_o` divisor,
    ADR-030/M20; and ragged×fixed / ragged×multilevel replicates, the compound corners); incomplete **fixed**
    nested + **cluster-level** fixed (research, no frequentist oracle — direction **(C)**, ADR-029/ADR-042);
    the averaged cluster-level **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, M9 §9); Bayesian **numeric-unit
    `d_study()`**; the **(B) customization** milestone — user-exposed **`prior=`** API + **HPDI** intervals +
    **selectable** `posterior` coupling (the next milestone after this mop-up); **rstanarm** backend. All stay
    in [`ROADMAP.md`](ROADMAP.md).
- Consequences: On M33 close, the **Bayesian parity mop-up (direction A) is complete** — `engine = "brms"`
  covers every clean-oracle estimand gap the balanced and incomplete arcs left: single-level one-way
  (balanced M26 + now incomplete), fixed-rater replicates, and multilevel replicates (crossed D1 + nested
  D2). The remaining brms ledger reduces to **(B)** customization (`prior=`, HPDI, selectable coupling) and
  **(C)** research/blocked (incomplete fixed nested, cluster-level fixed — both need a frequentist estimand
  built first). Mechanically the milestone is two guard clauses narrowed plus one fixed and two multilevel
  replicate fits, all reusing shipped machinery (no new θ² helper, no new argument, no new dependency); it
  carries the *lowest* residual risk of the mop-up corners — only Slice 1 is ragged, Slice 2's 2b is
  negligible on balanced data, Slice 3 is a variance-ratio push-forward. If the Slice 1 coverage oracle is
  nominal, M33 ships clean with **no Fable review** (as M29/M30); if it undercovers, the honest finding is
  characterized and a gated review is **recommended, not performed** (#19). This ADR authorizes M33 code; the
  `MILESTONES.md` M33 board and the `STATUS.md` flip are the milestone-start companions (M33 is scoped here
  but **no slice work has begun**).
- References: PRINCIPLES.md #1 (oracle-first — reduction + glmmTMB/lme4 agreement + coverage; the gate that
  every corner has a frequentist oracle), #2/#14/#15 (name the estimand / thin vertical slices; oracle-risk
  ordering — ragged one-way before the balanced replicate corners), #3 (boundary-aware — `posterior_mode()`;
  MC-CI), #4 (committed seeded reference; no tuning to oracle; n_rep ≥ 240 for the ragged cell), #5/#8
  (classed brms refusals for the still-deferred corners; `cli` guard messages), #6 (additive, non-breaking —
  new engine × design combinations), #12 (sourced estimands), #16 (tracking in-commit), #18 (report the run —
  containment not asserted equality; characterize coverage honestly), #19 (Fable never auto-invoked —
  conditional on a Slice 1 coverage shortfall, recommend-and-stop); ten Hove, Jorgensen & van der Ark (2022)
  (one-way / within-cell-replicate designs), (2020) §3.3/§4.1 (half-*t*(4,0,1) on SDs; DGP), §4.2
  (MAP/percentile); estimand-specs [`M6-oneway.md`](estimand-specs/M6-oneway.md),
  [`M17-within-cell-replicates.md`](estimand-specs/M17-within-cell-replicates.md) (no new spec); ADR-008 (M3
  `k_eff`), ADR-026 (M17 replicates), ADR-030 (M20 — the frequentist fixed/multilevel replicate oracles this
  mirrors), ADR-033 (M23 Bayesian engine — the seam extended), ADR-036 (M26 — `fit_brms_oneway()` reused),
  ADR-039 (M29 — `fit_brms_replicates()` machinery reused; single-level random replicates), ADR-040 (M30 —
  the incomplete/ragged random regime: variance-ratio push-forward, no 2b), ADR-041 (M31 — 2b live on ragged
  fixed data; here balanced → negligible), ADR-042 (M32 — the n_rep ≥ 240 ragged-coverage convention),
  ADR-002 (optional engines behind `Suggests`); `project/ROADMAP.md` (direction (A) being promoted),
  `project/COVERAGE.md`.

## ADR-044: M34 scope — Bayesian engine (brms) customization: user `prior=` override + HPDI credible intervals
- Date: 2026-07-10
- Status: accepted
- Context: With M33 (ADR-043) the **Bayesian parity mop-up (direction A) is complete** — `engine = "brms"`
  covers every clean-oracle estimand gap the balanced and incomplete arcs left. A short retro read the
  Bayesian arc as having moved decisively from *discovery* (M27/M28's 2b moment correction) through *mop-up*
  (M29–M33 all shipped without a corrective Fable review; M32's one gated review resolved to a no-shortfall
  tail event → the n_rep ≥ 240 convention). **The brms estimand surface is now complete.** What remains on the
  ledger is the recorded direction **(B)** of the 2026-07-10 planning discussion (`ROADMAP.md`): a
  **customization** milestone whose theme is "let users deviate from a sourced default *with guardrails*."
  No milestone is in flight. This ADR opens **M34**. The maintainer chose direction (B) over (C)
  research/blocked (incomplete fixed nested, cluster-level fixed — both need a frequentist estimand built
  first) and over the parked docs/vignette reassessment.
  - **This is interface/customization work, NOT new estimand work** (cf. M5.5/M7/M11/M16 — engine/interval
    /interface milestones with no estimand-spec). No new estimand, no new estimand-spec, no new dependency
    (`brms` already `Suggests`; HPDI via a dependency-free internal helper — see Slice 2). Additive,
    non-breaking (#6): two new **optional** arguments whose defaults preserve current behavior bit-for-bit.
  - **The oracle character changes with the milestone (#1).** Parity milestones proved a *new coefficient*
    against a frequentist oracle. Customization has no such target — the whole point is to let users leave the
    sourced regime. So M34's oracle is a **REDUCTION oracle**: the defaults (`prior = NULL`,
    `posterior_summary = "percentile"`) must reproduce the shipped M23+ results **bit-identically** (same seed
    → same draws → same MAP/CI). **Coverage under arbitrary priors, and HPDI coverage, are deliberately NOT
    oracle-claimed** — they cannot be, and claiming them would violate #4. The guardrails (a classed footgun
    warning; documented caveats) are how the milestone stays honest about that (#18).
  - **Why guardrails, not a whitelist (the sourced-default posture, #12).** The half-*t*(4, 0, 1) on every
    random-effect SD (ten Hove, Jorgensen & van der Ark 2020 §3.3/§4.1; df = 4 deliberately for
    variance parameters near the zero boundary — Principle #3's regime) is *sourced* and is what every shipped
    coverage result depends on. The primary use case for overriding it is prior-sensitivity /
    method-comparison / simulation studies, which need **arbitrary** priors — so the escape hatch is open (a
    clean override), **not** a curated list of "approved" priors. The honesty burden is carried by a loud,
    classed `cli` warning naming the *specific* footgun, not by refusing the deviation.
- Decision:
  - **Scope: two thin slices, ordered by stakes (#15)** — Slice 1 first (the `prior=` override, higher-stakes:
    it touches the fit and voids the coverage oracle), then Slice 2 (HPDI, a post-fit summary alternative).
  - **Slice 1 — user `prior=` override, via a top-level `icc()` argument.** Add a new **`prior = NULL`**
    argument to `icc()` (brms-only; default `NULL` = the sourced half-*t*(4, 0, 1)). Thread it through
    `fit_brms_common()` to replace the hardcoded `set_prior("student_t(4, 0, 1)", class = "sd")` default when
    non-`NULL`. **API decision (ADR-time):** a **dedicated top-level `prior=` arg**, NOT `prior` inside
    `brm_args`. Rationale — `brm_args` is contractually a *blind* passthrough of sampler/backend knobs
    `intraclass` has no opinion on (`icc.R:387`, `engine-brms.R:52`); the prior is the opposite, a **sourced
    default `intraclass` deliberately owns** (#12). A named arg is discoverable in `?icc`, gives the footgun
    warning a natural home, is type-validated (a `brmsprior`/`brmsprior`-list or `NULL`), and makes the
    reduction oracle's default explicit and testable. Consequently **`prior` STAYS in the `brm_args` reserved
    set** at `icc.R:383` (one canonical path; setting it via `brm_args` still aborts loudly, #5/#8) — the
    guard is *narrowed in effect* only in that the prior is now settable, but through the dedicated arg. When
    `prior` is non-`NULL`, fire a **classed `cli` warning** (a new `intraclass_custom_prior` condition, #8)
    naming the specific footgun: leaving the sourced prior **voids the coverage oracle**, and a
    vague/flat/"non-informative" SD prior *worsens* small-*k* boundary bias (the half-*t* is weakly informative
    on purpose). Passing `prior` with a non-brms engine → classed `abort_unsupported` (as `brm_args`).
    **Oracle O-PriorReduce:** (a) **reduction** — `prior = NULL` reproduces the shipped M23+ MAP/CI
    bit-identically at a fixed seed (the default path is unchanged); (b) **round-trip** — passing the sourced
    half-*t* *explicitly* as `prior = set_prior("student_t(4,0,1)", class = "sd")` reproduces the `NULL`
    result (proves the thread is faithful); (c) **override takes effect** — a deliberately different prior
    (e.g. a tight `normal(0, 0.1)` SD prior) *moves* the estimate in the predicted direction and fires the
    warning (a live `skip_on_ci()` Stan fit); (d) the classed warning/abort conditions. **No coverage claim
    under a custom prior.**
  - **Slice 2 — HPDI credible intervals, via `posterior_summary`.** Add a new
    **`posterior_summary = c("percentile", "hpdi")`** argument (default `"percentile"`), meaningful only under
    `ci_method = "posterior"` (the brms path). **API decision (ADR-time):** a sub-choice *within*
    `ci_method = "posterior"`, NOT a new `ci_method` value — it selects how the posterior draws are summarized,
    a different axis from *which interval method* produces the draws (MC / bootstrap / posterior). Default
    stays **percentile**: ten Hove 2020 §4.2 finds percentile BCIs (not HPDIs) give nominal coverage at k > 2,
    percentile is monotone-transformation invariant and degrades gracefully as θ² → 0, whereas HPDI is neither
    and can misbehave at the variance boundary (this package's core regime). HPDI is an **alternative for
    comparison, not a strict upgrade being withheld** — documented as such. Compute the HPDI with a small
    **dependency-free internal helper** (the narrowest interval covering the credible mass, a sort-and-scan
    over the ICC draws; boundary-aware — no transform round-trip) so light install is preserved (no
    `HDInterval`/`coda`/`bayestestR` dependency). Passing `posterior_summary = "hpdi"` with a non-posterior
    `ci_method` (or non-brms engine) → classed `abort_unsupported`. **Oracle O-HPDI:** (a) **reduction** —
    `posterior_summary = "percentile"` reproduces the shipped intervals bit-identically (default unchanged);
    (b) **agreement** — the internal HPDI helper matches a reference implementation (`coda::HPDinterval`,
    `skip_if_not_installed`) to ≤ 1e-8 on a fixed draw vector; (c) **narrower-or-equal** — HPDI width ≤
    percentile width on the same draws (the defining HPDI property); (d) the classed abort conditions. **No
    coverage claim for HPDI** (it is the comparison alternative, not the recommended interval).
  - **Oracles (#1):** the milestone's correctness is **reduction + definitional agreement**, not a new
    frequentist target — parity milestones' `-agree`/coverage oracles have no analogue here (there is no
    "true" custom-prior ICC to pin). Live custom-prior/HPDI Stan fits `skip_on_ci()`; CI is covered by the
    reduction/round-trip/helper-agreement tests (no live Stan needed for the default paths).
  - **Fable posture (#19):** **no unknown of the kind Fable adjudicates.** M34 makes no coverage claim that
    could undercover — the defaults are pinned by reduction and the deviations are explicitly out-of-oracle.
    Fable is **not** authorized by this ADR.
  - **Deferred out of M34** (record so not rediscovered): **selectable `posterior` coupling** (running the MC
    or bootstrap `ci_method` on a Bayesian fit — parked low-priority, direction (B) tail in `ROADMAP.md`); a
    **BCa/HDI-of-transform** or other credible-interval flavors beyond percentile/HPDI; **per-component /
    per-SD distinct priors** beyond the single `class = "sd"` override (the sourced default is one prior on all
    SDs — a heterogeneous-prior API is a further extension); **prior on the residual `sigma`** (ten Hove's
    parameterization keeps brms's default there — see `engine-brms.R:24`); the **(C) research/blocked** corners
    (incomplete fixed nested, cluster-level fixed — need a frequentist estimand built first, ADR-029/ADR-042);
    **rstanarm** backend; the **vignette reassessment** (docs). All stay in [`ROADMAP.md`](ROADMAP.md).
- Consequences: On M34 close, `engine = "brms"` gains a **customization surface with guardrails** — users can
  supply an arbitrary `prior=` (for sensitivity / method-comparison / simulation work) and choose HPDI vs
  percentile summaries, while the sourced defaults and every shipped coverage result are preserved
  bit-identically (the reduction oracle) and every deviation is flagged loudly as out-of-oracle (#18). The
  brms ledger then reduces to **(C)** research/blocked only (both need a new frequentist estimand first) plus
  the low-priority selectable-coupling tail. Mechanically the milestone is **two new optional arguments** +
  one classed warning condition + one dependency-free HPDI helper, all additive and non-breaking (#6) — no new
  estimand, no new estimand-spec, no new dependency. It carries **no coverage risk** (nothing claims coverage
  that could undercover), so **no Fable review** is in scope. This ADR authorizes M34 code; the
  `MILESTONES.md` M34 board and the `STATUS.md` flip are the milestone-start companions (M34 is scoped here
  but **no slice work has begun** — plan before code, #14).
- References: PRINCIPLES.md #1 (oracle-first — here a *reduction* oracle: defaults reproduce shipped results
  bit-identically; deviations explicitly out-of-oracle), #2/#14/#15 (name the interface change / thin vertical
  slices; stakes ordering — the fit-touching `prior=` before the post-fit HPDI summary), #3 (boundary-aware —
  percentile is transform-invariant and boundary-graceful, the reason it stays the default; HPDI helper is
  boundary-aware but the caveat is documented), #4 (no coverage claim under a custom prior / for HPDI — do not
  assert what no oracle backs), #5/#8 (classed `cli` footgun warning `intraclass_custom_prior`; classed
  aborts for misapplied `prior`/`posterior_summary`), #6 (additive, non-breaking — two optional args, defaults
  preserved), #12 (the half-*t*(4, 0, 1) is the *sourced* default the override departs from — ten Hove et al.
  2020 §3.3/§4.1), #16 (tracking in-commit), #18 (report honestly — the warning and docs state the deviation
  voids the oracle), #19 (Fable not authorized — no coverage unknown to adjudicate); ten Hove, Jorgensen &
  van der Ark (2020) §3.3/§4.1 (half-*t* prior), §4.2 (percentile BCIs nominal at k > 2, not HPDIs); no new
  estimand-spec (interface milestone — cf. M5.5/M7/M11/M16, ADR-012/ADR-014/ADR-020/ADR-025); ADR-033 (M23 —
  the brms engine, the fixed sourced prior, percentile credible intervals this milestone makes optional),
  ADR-036 (M26 — the half-*t* posture / containment), ADR-025 (M16 — the `ci_method` dispatch seam
  `posterior_summary` sub-selects within); `project/ROADMAP.md` (direction (B) being promoted),
  `project/COVERAGE.md`.

## ADR-045: M35 scope — vignette reassessment: update stale claims, split `advanced.Rmd`, add Bayesian coverage
- Date: 2026-07-10
- Status: accepted
- Context: With M34 (ADR-044) the **Bayesian arc is complete on both parity (M23–M33) and customization
  (M34)**. A short retro over the three shipped vignettes (`getting-started`, `choosing-an-icc`, `advanced`)
  against the current feature set found the docs badly out of date. The two smaller articles are current and
  well-scoped, but `advanced.Rmd` (504 lines) — last shaped around M13 — is both **materially stale** and
  **overloaded**, and the entire Bayesian engine (M23–M34) is **undocumented in every vignette**. The
  maintainer chose the parked **vignette reassessment** (`ROADMAP.md`) as the next milestone over (C)
  research/blocked and the CRAN upload, and confirmed the **Update + Split** shape (over update-only, a full
  rewrite, or a minimal stale-claim patch). No milestone is in flight. This ADR opens **M35**.
  - **This is a docs milestone — NO new estimand, engine, fit, CI machinery, or dependency** (cf. M4 the
    flagship vignette / M13 release polish). Additive to the docs surface; no code behavior changes. The one
    code-adjacent touch is `_pkgdown.yml`'s articles index (new articles must be listed, #6 —
    [[pkgdown-reference-index-new-exports]] applies to articles too).
  - **The triage found five materially FALSE "planned for a later milestone" claims** in `advanced.Rmd` —
    each describing as unshipped a capability that has since shipped: (1) incomplete fixed-rater **multilevel**
    (≈L254 — shipped M18 Slice 1); (2) incomplete **nested** designs (≈L256–261 — shipped M19 frequentist,
    M32 brms); (3) **fixed-rater & multilevel replicates** and ragged single-occasion replicates (≈L318–320 —
    shipped M20, brms M33); (4) **lme4 for fixed-rater & multilevel** designs (≈L380–381 — shipped M14/M15);
    (5) **lavaan fixed-rater / incomplete-FIML** (≈L427–429 — shipped M21). These are correctness bugs in the
    docs (they misstate shipped behavior, #18), so their fix is **non-negotiable** and lands first.
  - **The oracle character is docs, not numerical (#1).** As with M4/M13 there is no estimand oracle; the
    correctness contract is that **every displayed number is computed live at knit time** and the prose's
    numeric relationships are **claim-tested** (`test-vignette-claims.R`, #1/#4/#12). No fabricated output
    (#4). **No Fable review** — no coverage claim is made or changed.
- Decision:
  - **Article structure (the Split).** Keep `getting-started` and `choosing-an-icc` (current, well-scoped —
    light review only). **Retire `advanced.Rmd`**, redistributing its content into four focused articles:
    - **`multilevel-designs`** — subject vs. cluster level, the conflated diagnostic (Eq. 14), nested Designs
      2/3, incomplete/ragged crossed, fixed-rater multilevel, and the multilevel rater-count D-study.
    - **`engines`** — glmmTMB/lme4, lavaan (SEM), **and brms (Bayesian)** — the half-*t*(4,0,1) prior, the
      `prior=` override (M34), when each engine's estimand differs vs. is a pure backend choice.
    - **`interval-methods`** — Monte-Carlo, parametric bootstrap, **and `ci_method = "posterior"`** — MAP +
      percentile/**HPDI** credible intervals (`posterior_summary`, M34).
    - **`d-studies-and-replicates`** — rater-count D-study, within-cell replicates (interaction vs. pure
      error), and the `autoplot()` forest / variance-component visualizations.
    Every new article is added to the `_pkgdown.yml` articles index (#6). Cross-links between articles replace
    the single-article internal anchors.
  - **Scope: three thin slices, ordered by risk (#2/#14/#15).**
    - **Slice 1 — stale-claim fixes.** Correct the five false "planned for later" statements in place (before
      the split), so `main`'s docs stop misstating shipped behavior at the earliest point. Re-audit the
      remaining "planned / later milestone / not yet supported" phrasings across all three articles against
      `COVERAGE.md` so no other claim is stale.
    - **Slice 2 — the split.** Carve `advanced.Rmd` into the four articles above (moving existing prose and
      live chunks, no new capability claims), wire `_pkgdown.yml`, fix cross-links, retire `advanced.Rmd`.
      Purely mechanical redistribution — the numbers are the already-verified M17–M22 ones.
    - **Slice 3 — add the missing Bayesian coverage.** New brms sections in `engines` and `interval-methods`
      (prior override, posterior/HPDI). This is the only genuinely new prose.
  - **Open design point — brms vignette chunks (resolved).** A live brms fit compiles a Stan model, which
    **cannot run on CRAN or CI** (no toolchain — [[brms-live-fit-skip-on-ci]]). Decision: the brms chunks are
    **`eval = FALSE` illustrative**, showing the call and a **committed, verbatim** pre-computed output block
    (clearly the real output, generated once locally and pasted, not fabricated — #4). This mirrors how the
    test suite handles Stan via `skip_on_ci()` and keeps `R CMD build`/`--as-cran` and the pkgdown CI job
    free of a Stan dependency. (Rejected: `eval = requireNamespace("brms")` gating — it would still try to
    compile on any machine that has brms, including some CI runners, and silently blank on CRAN.)
  - **Correctness / DoD (#1/#4/#12).** Every non-brms chunk stays live-evaluated; `test-vignette-claims.R`
    extended to cover any new claimed numeric relationship in the split articles; brms illustrative outputs
    are committed and spot-checked locally. `R CMD check`/`--as-cran`, pkgdown build, and the full CI matrix
    green; `air`/`lintr`/spell clean; NEWS + `_pkgdown.yml` + `COVERAGE.md` (docs row) updated in-commit (#16).
  - **Fable posture (#19):** **not authorized** — a docs milestone makes no coverage claim to adjudicate.
  - **Deferred out of M35** (record so not rediscovered): a **clarity/accessibility rewrite** of
    `getting-started` / `choosing-an-icc` (the "Rewrite" option the maintainer set aside — those articles are
    already good; a from-scratch jargon-reduced worked path is a later docs pass); a **benchmark-vs-prior-art**
    article and a **JOSS/software paper** (ROADMAP); **live brms chunks** (blocked by the CI Stan toolchain —
    revisit only if a precomputed-cache mechanism is adopted); the **CRAN upload** (out of band, ADR-022); and
    every non-docs carryover — the **(C) research/blocked** brms corners (incomplete fixed nested,
    cluster-level fixed), **categorical/ordinal GLMM**, **multilevel SEM**, the Wave-3 `ICC(c,k)` incomplete
    divisor, and occasion/ragged `d_study()` — all stay in [`ROADMAP.md`](ROADMAP.md).
- Consequences: On M35 close the pkgdown site gains four focused, navigable articles in place of one
  overloaded one; the five false capability claims are gone; and the Bayesian engine (the package's headline
  differentiator, ~12 milestones) is documented for the first time. The docs then match the shipped surface
  for the first time since M13. Cost: more articles to keep in sync going forward (mitigated by the
  claim-tested live-number contract), and the brms sections carry committed illustrative output that must be
  refreshed if the brms path's printed form changes (a maintenance note, not a correctness risk — the numbers
  are not claim-tested since they can't run in CI). Mechanically the milestone is **content redistribution +
  new prose + `_pkgdown.yml` index entries** — no new estimand, estimand-spec, engine, CI machinery, or
  dependency, and no code behavior change (#6). It carries **no coverage risk**, so **no Fable review** is in
  scope. This ADR authorizes M35 docs work; the `MILESTONES.md` M35 board and the `STATUS.md` flip are the
  milestone-start companions (M35 is scoped here but **no slice work has begun** — plan before code, #14).
- References: PRINCIPLES.md #1 (oracle-first — here the docs contract: live-computed, claim-tested numbers,
  cf. M4/M13; no numerical estimand oracle), #2/#14/#15 (name the change / thin vertical slices; stakes
  ordering — the correctness-bug stale-claim fixes before the mechanical split before the new brms prose),
  #4 (no fabricated output — brms illustrative blocks are real pre-computed output, committed), #6 (additive,
  non-breaking; new articles join the `_pkgdown.yml` index, [[pkgdown-reference-index-new-exports]]), #12
  (every displayed relationship claim-tested, #1/#12), #16 (tracking in-commit), #17 (no scope creep — the
  clarity rewrite is deferred, not smuggled in), #18 (report honestly — the stale claims were docs bugs
  misstating shipped behavior), #19 (Fable not authorized — no coverage unknown); no new estimand-spec (docs
  milestone — cf. M4/M13, ADR-009/ADR-022); ADR-009 (M4 — the flagship vignette, live-number + claim-tested
  precedent), ADR-022 (M13 — release-polish docs, `advanced.Rmd`'s last major shaping), ADR-020 (M11 —
  `autoplot()`), ADR-025 (M16 — bootstrap `ci_method`), ADR-026 (M17 — conflated/replicates/multilevel
  D-study), ADR-033 (M23 — the brms engine + `posterior`), ADR-044 (M34 — `prior=` / HPDI, the newest
  undocumented surface); the shipped-since-M13 milestones the stale claims misstate: M14/M15 (lme4 parity),
  M18 (incomplete fixed multilevel), M19 (incomplete/fixed nested), M20 (replicates completeness), M21 (lavaan
  parity), M32/M33 (brms incomplete nested / parity mop-up); `project/ROADMAP.md` (the vignette-reassessment
  item being promoted), `project/COVERAGE.md`; [[brms-live-fit-skip-on-ci]] (why brms chunks can't run in CI).

## ADR-046: M36 scope — Incomplete/ragged fixed-rater nested (Design 2), subject level, single-rater `ICC_s(·,1)`
- Date: 2026-07-11
- Status: accepted
- Context: With the M18–M21 completeness arc (ADR-027) and the M23–M34 Bayesian arc both shipped, the
  remaining parked estimand work was classed **(C) research/blocked** in `ROADMAP.md`: incomplete **fixed**
  nested (Designs 2/3) and **cluster-level fixed**. Both were deferred for *every* engine because no
  frequentist oracle was known — the ADR-029 (M19) carve-out ("incomplete × fixed nested deferred — the M3
  `k_eff` × per-cluster θ² interaction needs its own oracle") and the ten-Hove-flagged open cluster-fixed
  small-*k* estimator. After a short retro the maintainer chose direction (C) and asked whether a
  **simulation oracle** could unblock it. Before any ADR, a seeded **feasibility spike** (this session,
  committed as `data-raw/reviews/m36-feasibility-spike-{point,coverage}.R`) targeted the most tractable cell — **incomplete
  fixed nested Design 2, single-rater `ICC_s(·,1)`** — because (a) the balanced version already shipped as
  M19 Slice 2 (`theta2r_fixed_nested()`, the per-cluster Case-3A finite-population variance averaged over
  clusters), and (b) single-rater needs **no averaging divisor**, so it sidesteps the open `k_eff` question
  the averaged coefficient shares with the M9 `ICC(c,k)` divisor. **The spike is non-circular by
  construction:** a finite-population θ²_{r:c} is a *deterministic function of the specific fixed rater
  effects* (the variance of the realized rater means), not a sampled parameter, so recovering it from ragged
  data is a genuine independent oracle, not a self-calibration. **Spike verdict — the estimand pins:**
    - **Point (300 reps/regime).** A first-principles generalization of `theta2r_fixed_nested()` to unequal
      per-cluster rater counts k_c (drop the equal-k guard; per-cluster `center = I − J/k_c`, `raw`, `bias`,
      average, floor) recovers the **known** truth: ICC(A,1) bias **+0.1%** (equal k_c=4, 25% cells missing)
      and **−1.0%** (unequal k_c ∈ {2..5}, 20% missing); θ²_{r:c} bias +0.0025 / +0.0059.
    - **Cross-engine.** glmmTMB↔lme4 agree to **|ΔICC| ≤ 4.7e-5** on the identical `score ~ 0 + rater +
      (1|cluster:subject)` fit (validates the raw VC/θ² extraction, though **not** the finite-population
      correction — that math is the same authored formula in both engines, which is why the seeded-truth
      oracle is the load-bearing one, #18).
    - **Interval (250 reps/regime).** The M28/ADR-038 **2b moment correction** (`theta2r_moment_draws()`),
      generalized to per-cluster k_c with average-then-floor, gives **nominal** 95% coverage of the truth:
      **0.964 interior** (unequal k_c) and **0.960 at the boundary θ²_{r:c}=0** — the M28 danger zone —
      with point-in-own-CI containment 1.00. The `k_eff × per-cluster θ²` interaction ADR-029 flagged as the
      risk resolved nominal for single-rater.
  The honest reading (#18): this pins by the **standard multilevel oracle pattern** (reduction + cross-engine
  + seeded population recovery) that shipped M9/M15/M19 *without* a Fable review — so the cell is **more
  tractable than "research/blocked" implied; parity-shippable, not open research** — while the *averaged*
  `ICC_s(·,k)` stays genuinely open (its `k_eff` divisor). This is the M19 Slice 1 posture exactly.
- Decision:
  - **One thin vertical slice (#14): incomplete/ragged fixed-rater nested Design 2, subject level,
    single-rater `ICC_s(·,1)` (agreement + consistency).** Lift the balanced-only guard on the fixed-nested
    path (`R/icc.R`, the `nested_design_balanced` / `!balanced` refusal reached with `raters = "fixed"` ×
    `design = "nested_in_clusters"`) so ragged data dispatches to `fit_glmmtmb_nested_fixed()` reusing the
    shipped M9 `k_eff`/connectedness + `design`-escape-hatch machinery (engine-agnostic, runs pre-dispatch)
    and the M8 §3a subject-level estimand map. **No new fit function.**
  - **Estimator: generalize `theta2r_fixed_nested()` to unequal per-cluster k_c** (drop the line-590
    equal-k guard; per-cluster `center`/`raw`/`bias` with that cluster's own k_c; average then floor — the
    balanced path is the k_c-constant special case, so the shipped M19 O-FNML reductions are unmoved and the
    common missing-cells-only case with intact rater sets already flowed through unchanged). The MC interval
    reuses `theta2r_moment_draws()` (per-cluster 2b, average-floor) generalized the same way. `theta2r_nested_draws()`
    threads the per-cluster center/k.
  - **Design 3 fixed stays ⚫ by-design** (raters nested in subjects = the multilevel one-way, no separable
    rater effect — the M19/ADR-029 ruling, unchanged). **Cluster-level fixed** (the other (C) corner) is
    **out of scope** — no shipped scaffolding and the estimator itself is a ten-Hove open question; deferred
    for its own later milestone.
  - **The averaged `ICC_s(·,k)` degrades to 🟣 research** if it cannot be pinned (its effective-rater divisor
    is the M9 `ICC(c,k)` open question) — attempt against the reduction + cross-engine oracles, and reclassify
    rather than ship a guessed divisor (#4), exactly as M19 Slice 1. Ship single-rater-only on that outcome.
  - **No new estimand concept, no new top-level argument, no new dependency** (light install intact) — a new
    valid combination of the shipped `design`/`raters`/data-balance arguments (cf. M9/M15/M18/M19, #6). A
    focused estimand-spec **`M36-incomplete-fixed-nested.md`** records the ragged per-cluster Case-3A
    derivation and the 2b-under-imbalance interval (the one genuinely new derivation), extending the M8 §8 /
    M10 §7 out-of-scope notes into the shipped map.
  - **Oracle posture (#1), the established multilevel pattern:** (O-IFNML) glmmTMB↔lme4 **cross-engine
    < 1e-4**; **reduction** to the shipped balanced M19 nested-fixed (bit-identical when k_c constant and
    complete) and the **per-cluster / single-cluster reductions** to the flat M3 fixed θ²_r (with consistency
    ≡ random exact); **committed seeded population recovery** against the known finite-population truth
    (interior + boundary θ²=0) with MC-CI coverage, at **n_rep ≥ 240** ([[ragged-coverage-nrep-240]]);
    lme4 degrades to glmmTMB at the variance boundary (ragged nested fits hit it more, as M15). The seeded
    oracle regenerates from a committed `data-raw/oracle-incomplete-fixed-nested.R` (the spike scripts are its
    seed), fixture committed (#4).
  - **Fable posture (#19): conditional-and-recommend-only.** The spike came back nominal, so a Fable review is
    **not** pre-authorized. If the full committed boundary oracle (n_rep ≥ 240) undercovers below the
    pre-registered band, `verify-estimator` **recommends** a Fable review and work pauses (#1/#19) — the point
    estimator is not tuned to force coverage (#4). This is the maintainer-chosen posture ("first-principles
    derivation + Fable review").
- Consequences: On M36 close, the (C) *incomplete-fixed-nested* corner is ✅ for Design 2 single-rater (or its
  averaged coefficient a recorded 🟣 reclassification — a clean outcome either way), narrowing the (C) bucket
  to *cluster-level fixed* + Design-3-fixed (⚫) + the averaged nested/`ICC(c,k)` divisor family. The nested
  fixed design reaches ragged parity with the crossed design (M18) except the same one 🟣 divisor. Risk is
  concentrated in the averaged divisor (explicitly allowed to degrade, #4) and the 2b-under-imbalance interval
  (spike-nominal but the committed oracle is the real gate). It rules out shipping the averaged coefficient on
  a guessed divisor and shipping cluster-fixed or Design-3-fixed here (scoped out). Additive, non-breaking
  (#6) — balanced/complete and random paths untouched (regression guard: the full M1–M19 suite stays green).
  This ADR authorizes M36 code; the `MILESTONES.md` M36 board and the `STATUS.md` flip are the milestone-start
  companions — **no slice code has begun (plan before code, #14)**. Next: `/start-task` Slice 1.
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + committed seeded recovery against a
  non-circular finite-population truth; the seeded oracle is load-bearing since cross-engine cannot validate
  the authored correction), #2/#14 (name the estimand / one thin vertical slice), #3 (boundary-aware interval
  — the 2b average-floor, coverage at θ²=0), #4 (no guessed divisor — the averaged-coefficient degrade
  clause; committed seeded script), #5/#8 (classed aborts for the ragged design-detection ambiguity + the
  Design-3-fixed / cluster-fixed / averaged-divisor out-of-scope corners), #6 (additive, non-breaking; no new
  argument/dependency), #16 (tracking in-commit), #18 (characterize honestly — the spike shows parity-shippable,
  not research; cross-engine does not validate the correction; the averaged divisor stays open), #19
  (conditional Fable recommendation on a committed-oracle shortfall — the maintainer-chosen posture);
  [[ragged-coverage-nrep-240]] (n_rep ≥ 240 convention), [[fixed-rater-interval-2b-moment-correction]] (the 2b
  moment correction this generalizes), [[milestone-branches-and-prs]] (ships on `m36-incomplete-fixed-nested`
  via PR). ADR-029 (M19 — the deferral this lifts; `theta2r_fixed_nested()` / the fixed≢random-even-balanced
  nested finding), ADR-008 (M3 `k_eff`/connectedness + Case-3A θ²_r), ADR-011/016 (M5/M8 multilevel fit +
  nested designs), ADR-018 (M9 incomplete crossed + `design` escape hatch — reused), ADR-019 (M10 crossed
  fixed multilevel), ADR-038 (M28 — the `theta2r_moment_draws()` 2b correction, gated Fable review #19),
  ADR-024 (M15 — incomplete/ragged lme4 engine-parity precedent, singular degrade). Estimand-spec
  `M36-incomplete-fixed-nested.md` (Slice 1); `M8-nested-multilevel.md §3a/§8`, `M10-fixed-multilevel.md §7`,
  `M9-incomplete-multilevel.md §9` (the shared `k_eff` divisor open question). ten Hove, Jorgensen & van der
  Ark (2022) Eqs. 8–11, Table 3 (nested Design 2 subject-level decomposition); McGraw & Wong (1996) Case 3/3A
  (the finite-population θ² this generalizes to ragged per-cluster k_c). `project/COVERAGE.md` (#11 fixed
  nested, incomplete column).

### ADR-046 Amendment 1 — post-hoc Fable review (gated #19): construction confirmed, three doc/test-asset amendments
- Date: 2026-07-11
- Status: accepted
- Context: The main session (Opus) shipped M36 (PR #41, `f5a19e8`) concluding it did **not** need a Fable
  review — the ragged 2b-under-imbalance interval and the averaged-coefficient `k_eff` divisor were the
  genuine unknowns, and the committed O-IFNML oracle came back nominal. The maintainer then requested a
  **post-hoc** gated Fable review (#19) of exactly those calls. Brief + response committed:
  `data-raw/reviews/fable-review-m36-incomplete-fixed-nested-{brief,response}.md` (+ the review's own seeded
  scripts `fable-check-m36.R` cluster-count sweep at n_rep 500 and `fable-check-m36-identities.R` derivation
  check).
- Decision (Fable verdict adopted in full): **The shipped M36 construction is sound; no corrective
  follow-up milestone is needed** (contrast M28, which *was* the corrective follow-up to M27 — here the
  ragged generalization holds). Findings and their disposition:
  1. **Q1 — the 2b construction survives raggedness.** The two M28 inflation identities are **Gaussian
     quadratic-form facts** (E[xᵀCx] = μᵀCμ + tr(CV), any V), *not* balanced-data facts: the push-forward is
     exact by construction of the draws (the β-block of `vcov(fit, full=TRUE)` equals `vcov()$cond`, verified
     0.00e+00), and the plug-in identity holds for unbiased REML β̂ (Kackar–Harville). The balanced closed
     form `b = σ²_res/n_s` was only ever an *analytic evaluation* of the trace; on ragged data b_c is read
     from the engine V̂ (carrying the subject-mean leakage the naive diagonal misses by up to 12%). Residual
     center displacement mean_c(b̂_c − b_c^true) measured **+0.0006 vs a mean b of 0.117**, and it is o(1)
     while the interval shrinks as C_n^{−1/2} — **REML is load-bearing** (an ML fit's growing-β̂ Neyman–Scott
     bias would rebuild an incidental-parameters displacement; REML closes it).
  2. **Q2 — no cluster-count decay.** The C_n sweep Opus omitted (the honest process gap: a ~6-cluster grid
     cannot detect this pathology by construction) comes back **flat**: boundary coverage .951–.968 at
     C_n = 80 across four regimes (n_rep 500), the M28 *post*-fix signature, nowhere near the pre-fix
     collapse (.95/.86/.57). The "no Fable needed" conclusion was **right but under-evidenced** — a coverage
     claim for an interval whose known failure mode is cluster-count decay needs a cluster-count axis (#18).
  3. **Q3 — the pooled harmonic `k_eff` is coherent, with a recorded identity.** Under homogeneous per-cluster
     rater variance, **harmonic pooling of rating counts IS per-subject error-variance averaging**:
     err = (θ̄² + σ²_res)·mean_s(1/m_s) = (θ̄² + σ²_res)/k_eff exactly — so the multi-cluster average is a
     derivation, not merely single-cluster-pinned. Under *heterogeneous* θ²_c it drops a second-order
     covariance term Cov_s(θ²_{c(s)}, 1/m_s) (~.03 ICC at deliberately stark heterogeneity) — a *definitional*
     choice of summary, not an estimation bug. **Keep as shipped; do not move to per-cluster divisors** (they
     would inject the noisiest, individually-unfloorable per-cluster θ̂²_c into the headline average).
  4. **Q4 — the recovery oracle's non-circularity is valid; its certification power is partial.** Recovery
     certifies the correction's *presence and rough scale*, but at n_s = 8 cannot see its *exact size* (a 2b
     over-correction sits inside the |bias| < .03 pin; only at n_s ≈ 4 is it +.037, visible). The exact size
     is pinned by the boundary-coverage cells (M28's lesson) + the committed identity checks.
- Consequences (all **documentation / test-asset** amendments — no shipped-code change, the point estimator
  and interval stand): (a) O-IFNML regenerated with two Fable sentinel cells — a **C_n = 80 boundary**
  cluster-count sentinel (guards the M27/M28 incidental-parameters class) and a **n_s = 4 interior**
  low-information cell (so the |bias| pin certifies the correction's size); the prior fixture was not wrong,
  it asserted *less* than it appeared to. (b) `M36-incomplete-fixed-nested.md` records the §4(a) harmonic-pooling
  identity, the §4(b) heterogeneity caveat, and the ragged-plug-in-b / REML-load-bearing note. (c) This
  amendment. The **process lesson** (#18): a coverage claim for a per-cluster-nested interval family must
  sweep the cluster-count axis, because the known failure mode (incidental-parameters displacement) is
  invisible at few clusters — do not read a single low-C_n coverage number as sufficient.
- References: PRINCIPLE #19 (gated manual Fable, maintainer-requested; never a subagent — brief prepared,
  reviewed manually), #1/#4 (recovery oracle non-circular, not tuned), #18 (the honest process gap +
  cluster-count-axis lesson); `data-raw/reviews/fable-review-m36-incomplete-fixed-nested-{brief,response}.md`
  + `fable-check-m36{,-identities}.R`; ADR-038 (M28 — the 2b construction and its two identities, which this
  confirms generalize); Kackar & Harville (1984, *JASA* 79:853 — EGLS/REML unbiasedness).

## ADR-047: M37 scope — fixed-rater **cluster-level** multilevel ICC (crossed Design 1, balanced/complete), spike-gated
- Date: 2026-07-11
- Status: accepted
- Context: With M36 (ADR-046) shipping the incomplete/ragged fixed-rater *nested* (Design 2) corner, the
  **last** parked **(C) research/blocked** item is **cluster-level fixed** raters — the ROADMAP classed it
  "no scaffolding; ten Hove flag the estimator itself as open." After a short retro the maintainer chose to
  plan it. Investigation (this session) splits the ROADMAP's blanket "blocked" into two claims: (a) the
  **balanced/complete crossed Design-1** cell is **structurally well-defined and its fit already ships** —
  the M10 fixed multilevel fit (`score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)`)
  already produces every component this coefficient needs (σ²_c, σ²_cr, θ²_r), so M37 reads a **different
  coefficient off the same validated fit, with no new fit function** (the M10-subject → M37-cluster step, the
  cluster-level sibling M10 §7 explicitly names as "its own later slice"); (b) the **genuinely open** part is
  *incomplete/small-k* (ten Hove's flagged estimator), which is **double-blocked** here (it also hits the
  M9 §9 open cluster-level `ICC(c,k)` divisor) — **out of scope**. This is the M36 posture: the ROADMAP's
  "blocked" over-generalized; investigation carves out a parity-shippable balanced cell from a genuinely-open
  incomplete one.
  - **The one genuinely new derivation (the real risk).** At the *subject* level (M10) σ²_cr is **not** in the
    error set, so fixing raters was clean and gave M10 its exact "balanced fixed ≡ random" reduction oracle
    (θ²_r = σ²_r on balanced data, M3 §6). At the *cluster* level σ²_cr **is** the error term (M5 §3b, Eq. 13:
    error `{rater, cluster_rater}`). So the open question is exactly: **when raters are fixed, is the standard
    random `(1|cluster:rater)` variance σ²_cr the correct cluster-level rater-disagreement error, or does the
    interaction also need a finite-population treatment (as the main effect does)?** — precisely M10 §7's
    "needs the fixed-rater treatment of the cluster×rater term validated." M37 **does not assume** the clean
    reduction; a **feasibility spike settles it before any shipping code** (the maintainer chose "spike first").
- Decision (maintainer-approved this session, 2026-07-11):
  - **Scope: balanced/complete crossed Design-1 cluster-level fixed-rater ICC, frequentist glmmTMB + lme4**
    (lme4 as cross-engine oracle, ADR-002/012). Agreement + consistency, single `ICC_c(·,1)` + average
    `ICC_c(·,k)`, `k` = raters-per-cluster (ten Hove 2022 p. 6). Lift the M10 subject-only guard
    (`R/icc.R`, the `level = "cluster"` + `raters = "fixed"` abort at ~line 765) for **this cell only**;
    incomplete/unbalanced stays refused. **No new fit function** (read the cluster-level `(signal, {error set},
    divisor)` off the shipped M10 fit — signal σ²_c, error `{θ²_r, σ²_cr}` agreement / `{σ²_cr}` consistency,
    scalar `k`), no new top-level argument, no new dependency (light install intact) — a new valid combination
    of shipped `level`/`raters` arguments (cf. M9/M10/M18/M19/M36, #6).
  - **Spike-first structure (Slice 1, no shipping code):** seeded `data-raw/reviews/m37-feasibility-spike-{point,coverage}.R`
    (the M36 provenance precedent) determines, on balanced data, whether the provisional §2b map reduces to
    the shipped M5 random cluster-level ICC (holds iff random σ²_cr is the correct fixed error term, since
    θ²_r = σ²_r) **and** whether the point/interval recover a **non-circular finite-population cluster-mean
    reliability truth** (a deterministic function of the fixed design, M36 pattern; interior + boundary
    σ²_c → 0; n_rep ≥ 240, [[ragged-coverage-nrep-240]]).
    - **Outcome A — reduction exact, recovery nominal:** ship §2b with a **reduction oracle** (balanced
      fixed ≡ random cluster-level) + lme4 cross-engine + seeded recovery — **no Fable review** (the M10
      posture lifted to the cluster level).
    - **Outcome B — reduction fails (σ²_cr needs a finite-population treatment):** derive the corrected
      cluster-level error term from first principles, pin it against the non-circular recovery oracle, **and
      fire the pre-authorized gated Fable review to confirm the derivation before shipping.**
  - **Fable posture (#19): CONDITIONALLY PRE-AUTHORIZED.** Unlike M36 (recommend-only), the maintainer has
    **pre-approved a gated Fable review this session** to fire **iff** the spike yields Outcome B (the σ²_cr
    finite-population derivation needs independent confirmation). It is still gated — never a subagent, never
    auto-spawned; the RB/RR brief protocol applies (`/milestone-brief`), and it does **not** fire on Outcome A.
    The point estimator is **never tuned to force coverage** (#4); if the corrected term cannot be pinned even
    with Fable, the cell degrades to 🟣 research and M37 ships nothing for it.
  - **Out of scope (deferred, not dropped):** incomplete/unbalanced cluster-level fixed (double-blocked —
    ten Hove open small-k estimator + M9 §9 `ICC(c,k)` divisor; its own later milestone); **brms/lavaan**
    cluster-level fixed siblings (engine parity, unblockable once M37 ships the frequentist oracle — the M27
    note left crossed fixed cluster level "an unshipped frequentist cell too"); nested Designs 2/3
    cluster-level and **Design 3 fixed** (⚫ by-design — no cluster-level ICC / no separable rater effect);
    fixed cluster-level `d_study()` (refused, M4.5). Recorded in ROADMAP + `M37-fixed-cluster-level.md §7`.
- Consequences: On M37 close, the crossed Design-1 fixed family is complete at **both** levels
  (subject = M10, cluster = M37); the residual (C) bucket narrows to *incomplete* cluster-level fixed (🟣
  Wave-3, double-blocked) + the engine-parity brms/lavaan siblings + the ⚫ by-design cells. If Outcome B and
  even Fable cannot pin the corrected term, M37 records a clean 🟣 reclassification (the M19-Slice-1 posture) —
  a defensible outcome either way. Risk is concentrated in the σ²_cr fixed-treatment (spike-gated, Fable-backed)
  and the cluster-level MC interval (the recovery oracle is the real gate). Additive, non-breaking (#6) —
  balanced random + M10 subject paths untouched (regression guard: the full M1–M36 suite stays green). This
  ADR authorizes M37 planning; the `MILESTONES.md` M37 board, the estimand-spec, the ROADMAP annotation, and
  the `STATUS.md` flip are the milestone-start companions — **no slice code has begun (plan before code, #14)**.
  Next: `/start-task` Slice 1 (the feasibility spike).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + committed seeded recovery against a
  non-circular finite-population cluster-mean truth), #2/#14 (name the estimand / thin vertical slices; spike
  before shipping code), #3 (boundary-aware MC interval — coverage at σ²_c = 0), #4 (no tuned estimator; 🟣
  degrade rather than ship a guessed error term), #5/#8 (classed aborts for incomplete / nested-cluster /
  Design-3-fixed out-of-scope corners), #6 (additive, non-breaking; no new fit/argument/dependency), #16
  (tracking in-commit), #18 (characterize honestly — the balanced cell is parity-shippable, the incomplete
  cell genuinely open; the σ²_cr treatment is the honest unknown), #19 (gated Fable — conditionally
  pre-authorized on Outcome B, still brief-gated, never a subagent); [[ragged-coverage-nrep-240]],
  [[fixed-rater-interval-2b-moment-correction]], [[cluster-icc-no-subject-facet]] (the cluster-level estimand
  omits subject variance), [[milestone-branches-and-prs]] (ships on `m37-fixed-cluster-level` via PR).
  ADR-019 (M10 crossed fixed multilevel subject level — the fit reused, its §7 forward note), ADR-011 (M5
  multilevel fit + cluster-level Eq. 13 estimand this specializes), ADR-008 (M3 Case-3A θ²_r), ADR-038
  (M28 — the 2b moment correction, if the interaction needs it), ADR-046 (M36 — the spike/recovery-oracle
  pattern this reuses). Estimand-spec `M37-fixed-cluster-level.md`; `M5-multilevel.md §3b`,
  `M10-fixed-multilevel.md §7`, `M9-incomplete-multilevel.md §9`. ten Hove, Jorgensen & van der Ark (2022)
  Eq. 13 / Table 3 (cluster-level decomposition); McGraw & Wong (1996) Case 3/3A. `project/COVERAGE.md`
  (#11 fixed, cluster level).

## ADR-048: M38 scope — brms engine parity for the fixed multilevel cells (cluster-level fixed + incomplete/ragged fixed-nested Design 2)
- Date: 2026-07-11
- Status: accepted
- Context: With M36 (ADR-046, PR #41) and M37 (ADR-047, PR #43) shipping the frequentist (glmmTMB/lme4)
  **incomplete/ragged fixed-rater nested (Design 2)** and **balanced cluster-level fixed** cells, the (C)
  research/blocked corner is nearly closed. A short retro + a feasibility sweep (this session) of the
  remaining (C) pieces found three, with sharply different feasibility — a distinction the ROADMAP's
  blanket "brms/lavaan siblings … unblockable" wording elided:
  - **brms siblings of M36 + M37 — genuinely cheap parity.** Both are a lift of a single "planned for a
    later milestone" guard: `R/icc.R:781` (brms cluster-level fixed) and `R/icc.R:810` (brms incomplete
    fixed-nested). Both have a **frequentist oracle to check against** (glmmTMB M37/M36), so both are
    engine/interval **parity, not new estimand work** (#6, the M27/M30/M31/M32 posture — no new
    estimand-spec/argument/dependency). The M27 fixed multilevel fit `fit_brms_multilevel_fixed()`
    (`score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)`) already emits the
    `cluster` (σ²_c), `cluster_rater` (σ²_cr) and θ²_r posterior draws the cluster-level push-forward needs
    — **no new fit** — and `fit_brms_nested_fixed()` (`score ~ 0 + rater + (1|cluster:subject)`) is
    structurally fine on ragged data.
  - **lavaan siblings — NOT unblockable.** lavaan multilevel is entirely unsupported (`R/icc.R:546` aborts
    every multilevel/one-way SEM path), and multilevel SEM is a "research-flavored heavy lift (two-level
    SEM-GT)" (ADR-027 note; ROADMAP). The lavaan cluster-fixed / incomplete-fixed-nested siblings are
    therefore **blocked behind the multilevel-SEM lift**, not cheap parity — the ROADMAP wording was wrong.
  - **incomplete/unbalanced cluster-level fixed** stays **🟣 genuinely double-blocked** (ten Hove's open
    small-*k* estimator **and** the M9 §9 open cluster-level `ICC(c,k)` divisor — one half with no sourced
    route to resolve by reading alone).
  - **Design 3 fixed** is **⚫ already closed in code** (the by-design abort at `R/icc.R:755` ships and is
    tested, ADR-029 decision C) — ROADMAP hygiene, not future work.
- Decision (maintainer-approved this session, 2026-07-11, via the plan question gate):
  - **Scope: M38 = brms engine parity for BOTH fixed multilevel cells, one milestone** (the maintainer chose
    "both cells, one milestone" over splitting — mirrors M27's crossed+nested fixed shape). Engine/interval
    parity, not new estimand work: additive, non-breaking (#6); no new estimand-spec, no new top-level
    argument, no new dependency (brms stays `Suggests`, live Stan fits `skip_on_ci()`,
    [[brms-live-fit-skip-on-ci]]).
    - **Cell 1 — brms cluster-level fixed (M37 sibling).** Balanced/complete crossed Design 1. Lift the
      `R/icc.R:781` guard for **balanced only**; read the cluster-level `(σ²_c | {θ²_r, σ²_cr}, k)`
      push-forward off the shipped M27 `fit_brms_multilevel_fixed()` five-component draws — **no new fit**.
      M37's Outcome-A finding (fixed cluster-level ≡ M5 random cluster-level **exactly**: θ²_r = σ²_r and
      σ²_cr unbiased under fixing on balanced data) means `b ≈ 0` here — a **variance-ratio push-forward**,
      no 2b moment correction — so the brms fixed cluster level should read identically to the **shipped
      M24 brms random cluster level**. **Low risk, no Fable expected** (the M27 parity posture).
    - **Cell 2 — brms incomplete/ragged fixed-nested Design 2 (M36 sibling).** Subject level, both single
      `ICC_s(·,1)` + average `ICC_s(·,k)` (divisor = the well-defined subject-level `k_eff`, the M19/M36
      divisor — **NOT** the open per-cluster `ICC(c,k)`, M9 §9). Lift the `R/icc.R:810` guard; run
      `fit_brms_nested_fixed()` on ragged data with `brms_theta2r_moment_draws()` — the **2b-under-imbalance
      moment correction going nested-brms for the first time** (`b ≠ 0`), the milestone's genuine risk. It
      combines three shipped regimes: M31 (ragged 2b single-level brms, resolved nominal), M27 (nested-fixed
      2b balanced brms, Fable-fixed) and M32 (incomplete nested brms, random).
  - **Fable posture (#19): NONE — stop-and-replan.** The maintainer chose **no Fable pre-authorization** for
    Cell 2. Cell 2 ships **only if** the seeded coverage oracle (O-Bayes-IFNML, n_rep ≥ 240 per
    [[ragged-coverage-nrep-240]]) comes back nominal (interior + boundary θ²=0) against the committed
    fixture and the glmmTMB M36 containment holds. **If it under-covers: STOP — do not loosen the pin (#4),
    do not tune the estimator, do not spawn Fable.** M38 then ships **Cell 1 only** (main stays shippable),
    and Cell 2 spins out to a re-plan (candidate/blocked) with the honest coverage evidence recorded. The
    pins are the honest signal, never loosened to pass.
  - **Remainder dispositions (this same commit updates ROADMAP):**
    - **lavaan cluster-fixed + lavaan incomplete-fixed-nested** → **candidate rows, blocked on the
      multilevel-SEM lift**; the ROADMAP "unblockable" wording corrected. Not in M38.
    - **incomplete/unbalanced cluster-level fixed** → **stays a candidate** (🟣 Wave-3, double-blocked; the
      M9 §9 divisor half has no sourced route). Explicitly not attempted now — a ROADMAP fact, not a
      D-rejection.
    - **Design 3 fixed** → **ROADMAP hygiene note**: already closed in code by the ADR-029 by-design abort;
      removed from the "still parked / open" bucket (it is neither future work nor blocked).
  - **Out of scope of M38 (deferred, not dropped):** everything above under "Remainder"; plus the untouched
    carryovers — categorical/ordinal GLMM, multilevel SEM proper, occasion/ragged `d_study()`, the
    `ICC(c,k)` incomplete divisor, the teaching-vignette clarity rewrite, the CRAN upload (ADR-022) — all in
    [`ROADMAP.md`](ROADMAP.md).
- Consequences: On M38 close (Cell 1 + Cell 2), the **brms** half of the (C) corner is closed — brms reaches
  full parity with glmmTMB on the fixed multilevel cells at both the cluster level (crossed Design 1
  balanced) and incomplete/ragged nested Design 2 subject level. The residual (C) bucket is then only the
  genuinely-open **incomplete cluster-level fixed** (🟣) and the **lavaan siblings** (blocked on multilevel
  SEM) — both correctly parked candidates, no longer mislabelled "unblockable." If Cell 2 under-covers, M38
  ships Cell 1 and the bucket also retains a re-plan for the ragged-fixed-nested-brms interval. Risk is
  concentrated entirely in Cell 2's 2b-under-imbalance-nested-brms coverage (the committed oracle is the
  gate; no Fable, stop-and-replan). Cell 1 is low-risk variance-ratio parity. Additive, non-breaking (#6);
  all balanced random + M24/M27 subject brms + glmmTMB/lme4 paths untouched (regression guard: the full
  M1–M37 suite stays green). This ADR authorizes M38 planning; the `MILESTONES.md` M38 board, the ROADMAP
  annotations, and the `STATUS.md` flip are the milestone-start companions — **no code has begun (plan
  before code, #14)**. Next: `/start-task` Task 1 (Cell 1, brms cluster-level fixed).
- References: PRINCIPLES.md #1 (oracle-first — reduction to the shipped brms random cluster level +
  glmmTMB containment for Cell 1; committed seeded coverage + glmmTMB M36 containment for Cell 2), #2/#14
  (name the estimand / thin parity slices; plan before code), #3 (boundary-aware credible interval — Cell 2
  coverage at θ²=0), #4 (no tuned estimator / no loosened pin — stop-and-replan if Cell 2 under-covers),
  #5/#8 (classed aborts kept for the still-out-of-scope corners: incomplete cluster fixed, lavaan
  multilevel, Design 3 fixed), #6 (additive, non-breaking; no new estimand-spec/argument/dependency), #16
  (tracking in-commit), #18 (characterize honestly — Cell 1 low-risk, Cell 2 the genuine risk; lavaan
  siblings blocked not unblockable; Design 3 fixed already closed), #19 (Fable — deliberately NOT
  pre-authorized this milestone; stop-and-replan instead). [[ragged-coverage-nrep-240]],
  [[fixed-rater-interval-2b-moment-correction]], [[coverage-oracle-cluster-count-axis]] (Cell 2's coverage
  oracle sweeps a high-C_n cell), [[brms-live-fit-skip-on-ci]], [[milestone-branches-and-prs]] (ships on
  `m38-brms-fixed-multilevel-parity` via PR). ADR-047 (M37 — the frequentist cluster-level fixed oracle
  Cell 1 mirrors), ADR-046 (M36 — the frequentist incomplete-fixed-nested oracle Cell 2 mirrors), ADR-037
  (M27 — `fit_brms_multilevel_fixed()`/`fit_brms_nested_fixed()` + the 2b moment correction), ADR-041 (M31 —
  ragged 2b single-level brms), ADR-042 (M32 — incomplete nested brms). Estimand-specs (unchanged,
  referenced not extended): `M37-fixed-cluster-level.md`, `M36-incomplete-fixed-nested.md`,
  `M5-multilevel.md §3b`. `project/COVERAGE.md` (#11 fixed cluster level; incomplete fixed-nested, brms
  column).

## ADR-049: M39 scope — `d_study()` occasion-count projection off a within-cell replicate fit
- Date: 2026-07-11
- Status: accepted
- Context: A short retro after the M23–M38 arc (the Bayesian engine M23–M34 + the (C) research/blocked corner
  M36–M38) found the estimand family very complete: the remaining ROADMAP candidates split into consolidation
  (CRAN/benchmark/docs), heavy research lifts (multilevel SEM, categorical GLMM), open 🟣 research questions,
  and a few thin parked corners. The maintainer chose (plan question gate, this session) to keep the thin-slice
  cadence with a **small parked corner**, and among those the **`d_study()` occasion-count projection** — the
  symmetric sibling of the rater-count projection **M22 shipped** (ADR-032). M22 (estimand-spec `M4.5-d-study.md`
  §8) projects the rater count `m` off a within-cell replicate fit holding the occasion count `n_o` at the
  fitted value:
  `Φ(m, n_o) = σ²_s / (σ²_s + (σ²_r + σ²_sr)/m + σ²_e/(m·n_o))`. Projecting `n_o` itself — the *other* axis —
  was explicitly deferred (M4.5 §7/§8; the guard note at `R/d-study.R:120`). A feasibility read of the shipped
  machinery (this session) confirmed it is a **thin extension, not new estimand work** (#6): the replicate
  estimand already carries per-component `error_divisors` (the pure-error term is already `÷ m·n_o`), so an
  occasion projection is the same divisor change applied to the `n_o` axis instead of `m` — no new fit, no new
  θ²/moment machinery. Three structural facts settle the risk:
  - **Occasion averaging rescales ONLY pure error σ²_e.** The rater (σ²_r/θ²_r) and interaction (σ²_sr) terms
    stay at the fitted `m`. So Φ(`n_o`) is a variance-ratio / dependability push-forward of an ordinary
    variance component — **no finite-population θ² functional, no 2b moment correction, no incidental-parameters
    coverage pathology** (unlike the M27/M28 fixed-θ² intervals). **Low risk, no Fable expected.**
  - **Occasion projection has a finite ceiling, not →1.** As `n_o → ∞`,
    Φ → `σ²_s / (σ²_s + (σ²_r + σ²_sr)/m)` — more occasions wash out only pure measurement error, never rater or
    interaction variance. This is the honest caveat the docs must foreground (#18), and it yields a free
    asymptote oracle.
  - **It is well-posed for fixed raters too — including absolute agreement.** M22 §4 *refuses* rater-count
    projection for fixed-rater absolute agreement (no "m freshly sampled raters" for a finite population). That
    ill-posedness does **not** apply to the occasion axis: occasions are a random facet regardless of how raters
    are treated, and `m` is held fixed at its finite value. So M39 **lifts** the §4 fixed-agreement abort *on
    the occasion axis* (fixed-rater rater projection stays refused).
- Decision (maintainer-approved this session, 2026-07-11, via the plan question gate):
  - **Scope: M39 = occasion-count projection off a BALANCED within-cell replicate fit**, in two slices mirroring
    M22. Projection machinery, not new estimand work: additive, non-breaking (#6); no new dependency; the only
    spec change is a new **§9 in `M4.5-d-study.md`** (the estimand is the *existing* replicate estimand at a
    projected `n_o` divisor — the M22 §8 posture).
    - **Slice 1 — single-level two-way replicate fit.** Occasion projection for random + fixed raters,
      agreement + consistency (fixed absolute agreement now **projects** on this axis, §4 lifted for `n_o`).
    - **Slice 2 — multilevel replicate fit** (crossed Design 1 + nested Design 2; Design 3 = the multilevel
      one-way, agreement-only). The **subject** level projects across `n_o`; the **cluster** level has no
      pure-error term in its error set (`{σ²_r, σ²_cr}`), so it is **occasion-invariant** — returned as a
      **flat curve with a documented note** (the maintainer chose flat-with-note over omitting it, keeping
      symmetry with the M22 both-levels output).
  - **API (maintainer-approved):** a new **`n_o` argument** — `d_study(x, m = NULL, n_o = NULL, ...)` — supply
    **exactly one** of `m` / `n_o`; supplying both **aborts** (`intraclass_unsupported`; a 2-D `m × n_o` surface
    is out of scope). `n_o` projects the occasion axis holding raters at the fitted count; the default `m`
    projection is unchanged (non-breaking). `n_o` is valid **only on a replicate fit** (a non-replicate fit has
    no occasion axis — aborts pointing to replicated data), and **only on balanced** replicate data (ragged
    stays refused, below).
  - **Fable posture (#19): NONE, and none expected.** The projected facet is an ordinary variance component
    divided by a divisor with the M22 Monte-Carlo interval reused — no coverage pathology is anticipated. If the
    seeded-sim coverage oracle nonetheless under-covers, **stop and characterize honestly (#4/#18)** rather than
    tune or loosen; do not spawn Fable without explicit maintainer approval.
  - **Deferred out of M39 (record so not rediscovered):** **ragged-replicate occasion projection** (still
    blocked on the 🟣 effective-`n_o` divisor — the *occasion-averaged coefficient on ragged replicates*
    research item, M20/ADR-030; the `R/d-study.R` ragged-replicate abort stays); **brms/posterior occasion
    projection** (`d_study()` projects off the frequentist components + MC interval, not posterior draws — an
    engine-parity item, not attempted now); the **2-D `m × n_o` joint surface** (out of scope — one axis per
    call); and the untouched carryovers (categorical/ordinal GLMM, multilevel SEM, benchmark suite,
    teaching-vignette clarity rewrite, CRAN upload ADR-022) stay in [`ROADMAP.md`](ROADMAP.md).
- Consequences:
  - `d_study()` gains a second projection axis symmetric to the shipped rater-count projection; every displayed
    coefficient stays computed live with a boundary-aware Monte-Carlo interval (#3). The estimand abstraction is
    untouched (projection still moves only the averaging divisor, M4.5 §1) — the change is which per-component
    divisor the projected `unit` scales.
  - The fixed-agreement §4 abort is now **axis-specific**: refused for `m`, permitted for `n_o`. The docs and the
    classed-abort messages must state this distinction so it does not read as an inconsistency (#5/#8/#18).
  - Users must not over-read an occasion curve: its ceiling is the pure-error-removed dependability at the fitted
    `m`, **below 1**. Documented in the `d_study()` help + the `d-studies-and-replicates` vignette (#18).
  - The cluster-level flat curve on an occasion projection is a genuine (occasion-invariant) result, not a
    missing computation — noted in output + docs.
- Oracles (**O-OccDS**, PRINCIPLES.md #1, ≥2 independent), mirroring M22's O-RepDS:
  - **O-OccDS-reduction** — at `n_o =` the fitted occasion count, each level/type curve equals the fitted
    `ICC(*,k)` for that level (< 1e-4).
  - **O-OccDS-lme4** — the projected curve matches one built from an independent `lme4::lmer` replicate fit
    through the same GT dependability form (cross-engine).
  - **O-OccDS-GT** — the curve equals the dependability form `σ²_s / (σ²_s + (σ²_r + σ²_sr)/m + σ²_e/(m·n_o))`
    computed directly from the fitted components (the M4.5 O-GT role; occasion projection is a *generalized*
    Spearman–Brown — only σ²_e scales with `n_o` — so this is the direct analytic oracle, not a plain SB).
  - **O-OccDS-ceiling** — as `n_o → ∞` (large finite `n_o`) the curve approaches
    `σ²_s / (σ²_s + (σ²_r + σ²_sr)/m)` and never exceeds it (asymptote invariant; the honest-caveat pin).
  - **O-OccDS-sim** — a seeded simulation with known components recovers the population Φ(`n_o`) at an `n_o` not
    run, and the Monte-Carlo band covers it (the M4.5 O-sim pattern).
  - **Invariants** — each curve is monotone increasing in `n_o` and stays in [0, 1]; the cluster level is flat;
    fixed-rater absolute agreement now projects (well-posedness assertion, §4 lifted for `n_o`).
- References: PRINCIPLES.md #1 (oracle-first — reduction + cross-engine + analytic GT form + committed seeded
  recovery), #2/#14 (name the estimand / thin projection slice; plan before code), #3 (boundary-aware
  Monte-Carlo interval reused; the wide band when few occasions back the estimate), #4 (no guessed
  ragged-`n_o` divisor — ragged occasion projection stays refused), #5/#8 (classed aborts: both-axes,
  non-replicate, ragged; the axis-specific fixed-agreement rule), #6 (additive, non-breaking; no new
  dependency; only a spec §9), #16 (tracking in-commit), #17 (deferred corners parked, not crept), #18
  (characterize honestly — the finite ceiling, the flat cluster level, the axis-specific abort), #19 (Fable
  deliberately NOT pre-authorized; none expected). [[milestone-branches-and-prs]] (ships on
  `m39-occasion-dstudy` via PR). ADR-032 (M22 — the rater-count replicate projection this mirrors; O-RepDS),
  ADR-030 (M20 — the within-cell replicate estimand + the ragged occasion-averaged 🟣 divisor that bounds the
  deferred ragged half), ADR-026 (M17 — per-component `error_divisors`, the multilevel projection), ADR-010
  (M4.5 — the original `d_study()` estimand + the §4 fixed-agreement ill-posedness this refines).
  Estimand-spec: **`M4.5-d-study.md` §9 (new)** — occasion-count projection. `project/COVERAGE.md` (d_study
  occasion axis).

## ADR-050: M40 scope — accessibility rewrite of the two front-door vignettes (`getting-started`, `choosing-an-icc`)
- Date: 2026-07-11
- Status: accepted
- Context: A short retro after the M33–M39 run (this session) found the **clean-oracle parity engine
  exhausted**: from M23 on nearly every milestone shipped as engine/interval/projection parity because a
  frequentist or textbook oracle existed (the (C) research/blocked corner closed at M36–M38; M39 was the last
  thin projection slice). What remains in [`ROADMAP.md`](ROADMAP.md) is *qualitatively different* — genuine 🟣
  research (needs a simulation-oracle study + a gated Fable review), heavy lifts (multilevel SEM, categorical
  GLMM), docs, a scope decision, or the release itself. The package has also been **v0.1.0 "submission-ready"
  since M13** with ~15 milestones of capability added since, unreleased — flagged in the retro as a strategic
  question but **not chosen** this session. The maintainer chose (plan question gate, this session) the
  **accessibility docs rewrite** — the set-aside third M35 option (ADR-045): the two front-door teaching
  articles are feature-complete and *already good* (the ROADMAP said so), but assume a methodologist reader.
  Read for an **applied** reader (a researcher who needs an ICC but is not a methodologist), three concrete
  accessibility gaps stand out:
  - **Jargon lands before it is defined** — "estimand", "population quantities", "variance components",
    "Spearman–Brown", "harmonic mean", "connected / identified", and especially `getting-started`'s
    Monte-Carlo-CI paragraph ("simulated from the fitted parameter covariance on the model's internal scale …
    where the delta method fails") all appear cold.
  - **No from-scratch on-ramp** — `getting-started` assumes the reader already knows what an ICC is and why to
    compute one; there is no "what interrater reliability is / why an ICC / what question each number answers"
    opening for a first-timer.
  - **No "is my ICC any good?" guidance** — applied users always ask this; it is currently absent. The biggest
    single accessibility win *and* the one item carrying non-docs risk (a sourcing obligation, #4).
- Decision (maintainer-approved this session, 2026-07-11, via the plan question gate):
  - **Scope: M40 = a clarity/accessibility rewrite of `getting-started.Rmd` and `choosing-an-icc.Rmd`, in
    place.** A **docs milestone** (cf. M4/M13/M35): **no new estimand, engine, fit, CI machinery, or
    dependency** (#6). Correctness is **live-computed + claim-tested numbers** (#1/#4/#12), not a numerical
    oracle. Rewrite **in place** — the two front-door articles keep their filenames, URLs, and `_pkgdown.yml`
    entries (no split, unlike M35; no URL churn on the entry points). Jargon handled by **first-use glosses**
    (not a separate glossary page). The estimand vocabulary and the *Choosing an ICC* decision tree must read
    as approachable to applied users, not just methodologists.
  - **Interpretation benchmarks: IN, sourced + caveated (maintainer-approved).** Add an "is my ICC good?"
    cutoff-band guide (poor / moderate / good / excellent), **cited to a real reference** and framed as **one
    convention among several with explicit caveats** — never as truth, never an invented cutoff (#4). Primary
    source **Koo & Li (2016)** (the modern IRR-benchmark standard), with **Cicchetti (1994)** noted as the
    older sibling band and **ten Hove et al. (2024)** ("Updated guidelines …", already in `REFERENCES.md`) for
    the selection framing. The bands live in **one canonical place** (`getting-started`'s Interpret section) and
    are cross-linked from `choosing-an-icc` to avoid drift. The caveat must foreground that a cutoff depends on
    stakes, base rates, and the coefficient chosen — the package deliberately does not compute a verdict.
  - **Fable posture (#19): NONE.** A docs milestone with no estimand/coverage claim; no escalation.
  - **Deferred out of M40 (record so not rediscovered):** the **v0.2.0 release consolidation / CRAN upload**
    (ADR-022; the strategic release-gap question the retro raised — a separate milestone if scheduled); the
    **benchmark-vs-prior-art** article; the **clarity pass over the *other* articles** (`engines`,
    `interval-methods`, `multilevel-designs`, `d-studies-and-replicates` — M40 touches only the two front-door
    articles); a **glossary page** (glosses are inline this milestone); and every untouched carryover
    (categorical/ordinal GLMM, multilevel SEM, the 🟣 divisor research items, lavaan siblings) stays in
    [`ROADMAP.md`](ROADMAP.md).
- Consequences:
  - The two entry-point articles gain an applied-reader on-ramp, first-use glosses, a plainer Monte-Carlo-CI
    explanation (technical detail pushed to an aside or cross-linked to `interval-methods`), and a sourced,
    caveated interpretation-band guide. Every displayed coefficient stays computed live at knit time and pinned
    by `test-vignette-claims.R` (#1/#4/#12) — a rewrite must not silently change a printed number, and any that
    moves updates its claim test in the same commit (#16).
  - The interpretation bands are the one place a docs milestone can introduce unsourced content; they are
    gated on a real citation in `REFERENCES.md` + a caveat, or they do not ship (#4). This is the milestone's
    only genuine risk.
  - No `_pkgdown.yml` article-index change (in-place rewrite), but any new WORDLIST terms (e.g. "Cicchetti")
    join `inst/WORDLIST` so `spelling` stays clean ([[pkgdown-reference-index-new-exports]] applies to article
    prose too); `air` / `lintr` clean.
- Correctness (a docs milestone's "oracle" is claim-tested live computation, #1 numerically N/A — cf.
  ADR-045/M35):
  - Every numeric relationship the prose asserts is computed live and pinned in `test-vignette-claims.R`
    (relabelled per-article as needed); no hand-typed coefficient.
  - Both rewritten articles render standalone under `R CMD build` **and** pkgdown; all inter-article anchor
    links resolve against generated ids; the decision-tree SVG still resolves via `resource_files:`.
  - The interpretation bands trace to a committed `REFERENCES.md` entry (Koo & Li 2016; Cicchetti 1994), framed
    as convention-not-truth with caveats — verified by reading, not asserted.
- References: PRINCIPLES.md #1/#4/#12 (live-computed + claim-tested numbers; no fabricated/unsourced band
  cutoffs), #2/#14 (plan before code; thin docs slices), #6 (additive, non-breaking; no new estimand/engine/
  dependency — cf. M4/M13/M35), #16 (tracking + claim tests in-commit), #17 (the other articles + release
  consolidation parked, not crept), #18 (characterize honestly — the interpretation caveat, the
  finite-ceiling / boundary language kept accurate while simplified), #19 (no Fable — docs milestone).
  [[milestone-branches-and-prs]] (ships on `m40-vignette-accessibility` via PR). ADR-045 (M35 — the vignette
  *reassessment*; M40 is its set-aside clarity/accessibility third option), ADR-009 (M4 — the flagship
  *Choosing an ICC* teaching article this makes more approachable), ADR-022 (M13 — the docs/release posture;
  the v0.2.0 consolidation deferred here). New `REFERENCES.md` entries: **Koo & Li (2016)**, **Cicchetti
  (1994)**. No estimand-spec (docs, not estimand — cf. M4/M13/M35). `project/COVERAGE.md` unaffected (no new
  estimand cell).

## ADR-051: M41 scope — clarity/accessibility pass over the four secondary vignettes + a standalone glossary
- Date: 2026-07-11
- Status: accepted
- Context: A short retro this session (following the M40 ship) confirmed the two strategic facts ADR-050
  already recorded — the **clean-oracle parity engine is exhausted** (the (C) corner closed at M36–M38; M39/M40
  were the tail) and the **v0.2.0 release gap** (v0.1.0 "submission-ready" since M13, ~27 milestones of
  capability — the whole Bayesian engine, lme4/lavaan parity, multilevel fixed, `d_study()` occasions — accreted
  under an unreleased `0.1.0` NEWS heading). The maintainer chose (plan question gate, this session) to ship
  **two low-risk, release-strengthening docs/engineering milestones before cutting 0.2.0**: M41 (this ADR — the
  vignette clarity pass + glossary) then M42 (a benchmark-vs-prior-art suite), then the release at **0.2.0**.
  M40 applied an applied-reader accessibility treatment to the two *front-door* articles (`getting-started`,
  `choosing-an-icc`); the other four articles — `engines`, `interval-methods`, `multilevel-designs`,
  `d-studies-and-replicates` (all M35-era, ADR-045) — are accurate and well-structured but pre-date the M40 bar
  and assume a methodologist reader. Read for an applied reader, recurring jargon lands cold: **variance
  component, REML, posterior mode / MAP, credible vs. confidence interval, the zero-variance boundary, FIML,
  `k_eff` / harmonic mean, finite-population variance, the conflated ICC, connectedness / identification, the
  dependability coefficient, the indicator-mean estimator**. M40 handled such terms with per-article first-use
  glosses; across six articles that repeats, so a **single standalone glossary** page is the better home — each
  article deep-links a term instead of re-glossing it.
- Decision (maintainer-approved this session, 2026-07-11, via the plan question gate):
  - **Scope: M41 = a clarity/accessibility pass over the four secondary vignettes (`engines`,
    `interval-methods`, `multilevel-designs`, `d-studies-and-replicates`), plus a new standalone
    `glossary.Rmd` vignette.** A **docs milestone** (cf. M4/M13/M35/M40): **no new estimand, engine, fit, CI
    machinery, or dependency** (#6). Correctness is **live-computed + claim-tested numbers** (#1/#4/#12), not a
    numerical oracle. **No Fable** (docs milestone, #19).
  - **Per-article treatment (in place — no filename/URL/`_pkgdown.yml` churn on the four):** a warmer,
    plain-language on-ramp at the top; **first-use glosses** of the jargon above; cross-links into the glossary;
    **no change to statistical content, examples, or any printed number**. A gloss that restates a number keeps
    it live-computed; any printed value that moves updates its `test-vignette-claims.R` claim in the same
    commit (#16).
  - **Glossary form: a standalone `glossary.Rmd` article** (maintainer choice, this session) — one alphabetical
    page defining the recurring terms once, each with a stable anchor (`glossary.html#reml`, …), wired into
    `_pkgdown.yml`'s **articles** index (not the reference index — [[pkgdown-reference-index-new-exports]]).
    All **six** articles deep-link it (the two M40 front-door articles are retrofitted with glossary links in
    S1, replacing or supplementing their inline glosses where it reads better — no numbers touched).
  - **Slices (thin, #14):** **S1** — the `glossary.Rmd` page + `_pkgdown.yml` wiring + retrofit the two M40
    front-door articles to link it; **S2** — `engines` + `interval-methods` clarity pass; **S3** —
    `multilevel-designs` + `d-studies-and-replicates` clarity pass + `test-vignette-claims.R` relabel +
    finish-task gate.
  - **Sequenced before M42** (benchmark-vs-prior-art suite) **then the 0.2.0 release** — M41 first because it
    is the direct continuation of the warm M40 context, and finalizing the articles lets the M42 benchmark
    article cross-link polished docs.
- Consequences:
  - Every applied reader who lands on a secondary article now meets each technical term defined on first use or
    one click away, matching the M40 front-door bar — the pkgdown site reads as one accessible whole before
    0.2.0 goes out.
  - A new `glossary.Rmd` is a seventh article (one more `R CMD build` + pkgdown target, one more navbar entry);
    the glossary anchors become a maintenance surface (a renamed term must update every deep-link) — accepted as
    cheaper than repeating glosses across six articles.
  - Ruled out: the alternative of folding the glossary into `getting-started` (rejected — longer front door,
    shallower anchors); any statistical/estimand/example change (out of scope — this is prose only); a clarity
    pass over content the four articles do not already cover.
  - No `_pkgdown.yml` **reference**-index change and no new `@export`, so `pkgdown::check_pkgdown()` catches only
    the new article registration; new WORDLIST terms (term spellings, author names) join `inst/WORDLIST` so
    `spelling` stays clean; `air` / `lintr` clean. `project/COVERAGE.md` unaffected (no new estimand cell).
  - The other deferred docs work stays parked (#17): a clarity pass over any *further* material and per-term
    examples beyond first-use glosses are not in M41; M42 (benchmark) and the 0.2.0 consolidation are the
    sequenced follow-ons, not crept into this milestone.
- Correctness (a docs milestone's "oracle" is claim-tested live computation, #1 numerically N/A — cf.
  ADR-045/M35, ADR-050/M40):
  - Every numeric relationship the prose asserts stays computed live and pinned in `test-vignette-claims.R`
    (relabelled per-article as needed); no hand-typed coefficient, and no printed number changes silently.
  - All five (now six) articles + the glossary render standalone under `R CMD build` **and** pkgdown; every
    inter-article and glossary anchor link resolves against generated ids (verified by reading, not asserted).
  - The glossary defines terms in plain language traceable to the estimand specs / `REFERENCES.md` already in
    the package; it introduces **no** new sourced statistical claim (unlike M40's interpretation bands), so it
    carries no #4 sourcing obligation beyond spelling.
- References: PRINCIPLES.md #1/#4/#12 (live-computed + claim-tested numbers; no fabricated content), #2/#14
  (plan before code; thin docs slices), #6 (additive, non-breaking; no new estimand/engine/dependency — cf.
  M4/M13/M35/M40), #16 (tracking + claim tests in-commit), #17 (M42 + release consolidation parked, not crept),
  #18 (characterize honestly — glosses stay accurate while simplified), #19 (no Fable — docs milestone).
  [[milestone-branches-and-prs]] (ships on `m41-vignette-glossary` via PR), [[pkgdown-reference-index-new-exports]]
  (the new article is registered in `_pkgdown.yml`). ADR-050 (M40 — the front-door accessibility rewrite this
  extends to the remaining articles), ADR-045 (M35 — split that created the four secondary articles), ADR-022
  (M13 — the docs/release posture; the v0.2.0 consolidation sequenced after M42). No estimand-spec (docs, not
  estimand — cf. M4/M13/M35/M40).

## ADR-052: M42 scope — benchmark-vs-prior-art comparison article (`psych` + `irr` + `irrICC`)
- Date: 2026-07-11
- Status: accepted
- Context: A short retro this session (following the M41 ship, PR #47) confirmed the sequencing ADR-050/ADR-051
  already recorded and did not disturb it: the **clean-oracle parity engine is exhausted** (the (C) corner
  closed at M36–M38; M39/M40/M41 were the tail), and the **v0.2.0 release gap** stands (v0.1.0
  "submission-ready" since M13, ~27 milestones of capability accreted under an unreleased NEWS heading). The
  maintainer's chosen pre-release sequence is **M41 clarity ✓ → M42 benchmark → cut 0.2.0** (then the v0.2.0
  consolidation + CRAN upload, ADR-022). This ADR opens **M42**, the second release-strengthening milestone: the
  long-parked **benchmark-vs-prior-art** item ([`ROADMAP.md`](ROADMAP.md), "ready anytime, low priority"). It is
  **engineering, not new estimand or oracle work** — the package's differentiator vs. prior art is stated in the
  ROADMAP vision (classical `psych`/`irr`/`irrICC` are ANOVA/mean-squares and balanced-only; model-based
  `gtheory`/`performance` give a variance-partition coefficient, not the full boundary-aware IRR family with a
  selection framework) but has **never been shown to a reader** in one place. `psych::ICC()` is already our
  **live in-suite cross-check oracle** (`REFERENCES.md`; ICC1/2/3 + k-forms), so the *agreement* half carries no
  new oracle risk — it re-presents an equivalence the test suite already pins. A this-session smoke test on
  `irr::anxiety` confirmed the premise is real: `intraclass`, `psych`, and `irr` agree to **6 decimals** on
  ICC(1)=0.175022, ICC(A,k)=0.425499, ICC(C,k)=0.452586.
  - **A dependency constraint discovered while scoping (recorded so it is not rediscovered): `gtheory` was
    removed from CRAN (archived 2025-03-24).** It therefore **cannot** be a `Suggests` dependency of a
    CRAN-bound package (CRAN/CI install Suggests from CRAN and would fail). The package's `gtheory` agreement
    (G-coef ≤ .001 / D-coef ≤ .005 across 24 real datasets, `REFERENCES.md`) is **already committed provenance**,
    so the GT/VPC differentiator is carried by **citing that existing result** in a capability matrix, not by a
    new live dependency.
- Decision (maintainer-approved this session, 2026-07-11, via the plan question gate — deliverable form chosen
  directly; package set delegated to the maintainer-recommended default and adjusted for the `gtheory` CRAN
  constraint):
  - **Scope: M42 = one new reader-facing comparison article, `vignettes/comparison-with-other-packages.Rmd`,
    plus its claim tests.** Two halves: (1) **validation** — `intraclass` reproduces the classical tools
    (`psych`, `irr`) to numerical precision on the balanced designs where they are all defined; (2)
    **differentiation** — a worked case + a capability matrix showing where prior art cannot follow (incomplete/
    unbalanced data, multilevel subject/cluster IRR, boundary-aware Monte-Carlo intervals, the fixed-vs-random
    error framing, a selection framework).
  - **Posture: a docs milestone (cf. M4/M13/M35/M40/M41) with a bounded dependency delta.** **No new estimand,
    engine, fit, CI machinery, or public argument** (#6). Correctness is **live-computed + claim-tested numbers**
    (#1/#4/#12), not a new numerical oracle — the agreement half re-presents the existing `psych` cross-check,
    and every displayed figure is computed live and pinned in `test-vignette-claims.R`. **No Fable** (#19).
  - **Package set: `psych` + `irr` + `irrICC`** — `psych` (already in `Suggests`; classical ANOVA ICC, our
    existing oracle) + **`irr`** (the canonical classical IRR package applied users reach for) carry the
    exact-agreement validation; **`irrICC`** (Gwet; model-based, handles missing data) carries the incomplete-
    data differentiator. **`irr` and `irrICC` are added to `Suggests`** (vignette/test-only, light-install
    principle — never `Imports`; guarded by `requireNamespace()` in vignette chunks and `skip_if_not_installed()`
    in tests). **`gtheory` (archived off CRAN) and `performance`/`misty`/`irrNA`/`DescTools` are deliberately
    NOT added** (#17): `gtheory`'s agreement is cited from existing provenance, and the VPC tools' gap is stated
    in the capability matrix without a live run — no new story the three chosen packages do not already tell.
  - **Slices (thin, #14):** **S1** — the article's **validation** section (balanced ICC(1)/ICC(A,k)/ICC(C,k)
    agreement across `intraclass`/`psych`/`irr`, live-computed) + `_pkgdown.yml` **articles**-index wiring +
    `test-vignette-claims.R` agreement claims + `irr` → `Suggests`. **S2** — the **differentiation** section: an
    incomplete-data worked case (classical listwise/`NA` behavior vs. `intraclass`'s `k_eff` handling, with
    `irrICC` as the model-based foil) + the cited capability matrix + its claim tests + `irrICC` → `Suggests`.
    **S3** — WORDLIST (`irrICC`, `Gwet`, author/term spellings), NEWS bullet, cross-links from the existing
    articles/README where natural, and the finish-task gate → PR.
  - **Sequenced after M41, before the 0.2.0 release** — the benchmark article cross-links the now-polished M40/
    M41 docs, and a shown differentiator strengthens the release's positioning; the v0.2.0 consolidation +
    CRAN upload (ADR-022) follow.
- Consequences:
  - The pkgdown site gains a single page a prospective user can read to see **both** that `intraclass` agrees
    with the tools they already trust **and** what it does that those tools cannot — the differentiator moves
    from the ROADMAP vision into shown, reproducible evidence before 0.2.0 goes out.
  - Two new **test/vignette-only** `Suggests` (`irr`, `irrICC`); CRAN/CI install Suggests so the live chunks and
    `skip_if_not_installed()` claim tests run there, while the base/light install is unchanged (both stay out of
    `Imports`). A seventh… (now eighth) article is one more `R CMD build` + pkgdown target.
  - The comparison numbers become a maintenance surface: a prior-art package changing its formula would move a
    pinned claim — caught by `test-vignette-claims.R`, which is the intended tripwire (#16).
  - Ruled out: a `data-raw/` benchmark harness or a **speed** benchmark (out of scope — the maintainer chose the
    reader-facing agreement/capability article, not a timing study or provenance-only script); adding `gtheory`
    (impossible — archived off CRAN) or the broad VPC/NA sweep (`performance`/`misty`/`irrNA`/`DescTools`) as
    live deps (#17 — no distinct story, unnecessary surface); any estimand/engine/example change (this is a
    presentation milestone over shipped behavior).
  - No `_pkgdown.yml` **reference**-index change and no new `@export`, so `pkgdown::check_pkgdown()` catches only
    the new article registration ([[pkgdown-reference-index-new-exports]]); new WORDLIST terms keep `spelling`
    clean; `air` / `lintr` clean. `project/COVERAGE.md` unaffected (no new estimand cell).
- Correctness (a docs milestone's "oracle" is claim-tested live computation, #1 numerically N/A — cf.
  ADR-045/M35, ADR-050/M40, ADR-051/M41):
  - Every agreement figure the article displays is **computed live** from `intraclass` and the prior-art package
    in the same chunk and **pinned** in `test-vignette-claims.R` (`skip_if_not_installed()` on the prior-art
    package); no hand-typed coefficient, and no printed number changes silently.
  - The agreement half introduces **no new sourced statistical claim** — it re-presents the `psych` equivalence
    the suite already asserts (`REFERENCES.md`); the `gtheory` capability row **cites** the package's existing
    committed agreement (no #4 obligation beyond attribution and spelling).
  - The article renders standalone under `R CMD build` **and** pkgdown; every inter-article anchor link resolves
    against generated ids (verified by reading, not asserted).
- References: PRINCIPLES.md #1/#4/#12 (live-computed + claim-tested numbers; no fabricated/unsourced content),
  #2/#14 (plan before code; thin docs slices), #5/#8 (any new guards classed via `cli`/`rlang` — N/A here, no
  new code path), #6 (additive, non-breaking; no new estimand/engine/argument — new deps are `Suggests` only),
  #16 (tracking + claim tests in-commit), #17 (`gtheory`/VPC-sweep parked, not crept; the release parked to
  ADR-022), #18 (characterize honestly — the differentiator shows where prior art degrades, stated fairly, not
  strawmanned), #19 (no Fable — docs/engineering milestone, no coverage claim). [[milestone-branches-and-prs]]
  (ships on `m42-benchmark-comparison` via PR), [[pkgdown-reference-index-new-exports]] (the new article is
  registered in `_pkgdown.yml`), [[verify-against-installed-package]] (build/check with the new Suggests present).
  ADR-051 (M41 — the vignette clarity pass this benchmark article cross-links), ADR-045 (M35 — the articles it
  joins), ADR-022 (M13 — the docs/release posture; the v0.2.0 consolidation sequenced after M42). No
  estimand-spec (docs, not estimand — cf. M4/M13/M35/M40/M41).

## ADR-053: M43 scope — cli presentation polish (interactive `choose_icc()` tree + `print`/`summary` aesthetics)
- Date: 2026-07-11
- Status: accepted
- Context: A short retro after the M42 ship (PR #48) reaffirmed the standing sequencing — the clean-oracle parity
  engine is exhausted and the **v0.2.0 release consolidation (ADR-022) is the next big step** — and then the
  maintainer interrupted that sequence with a direct request about two **user-experience** surfaces, which this
  ADR opens as **M43, sequenced before the release** (a polished console read strengthens the same 0.2.0
  positioning the M40–M42 docs work served). The two surfaces:
  - **`choose_icc()`'s interactive walkthrough.** The maintainer expected an interactive cli **decision tree**
    and perceived the helper as "enter args → it explains them." Investigation (`R/choose-icc.R`): the
    walkthrough **already exists** (ADR-021's guarded shell) but (a) fires **only** when `rlang::is_interactive()`
    **and** a required coefficient-axis arg is missing — so a call that supplies the args always skips it — and
    (b) renders plainly: a `cli_inform` question + a numbered `cli_ol` + a `readline` numeric selection, one
    question at a time, with no sense of progress or a running decision path. That is why it does not *feel* like
    a tree. (Aside: the maintainer called it `suggest_icc()`; **no such function exists** — the name is
    `choose_icc()`.)
  - **`print.icc` / `summary.icc` output.** `format.icc()` hand-builds `sprintf`-aligned monospace lines and
    `print.icc()` emits them through `cli::cli_verbatim()`, which **deliberately bypasses all cli styling** — so
    today there is zero use of cli rules, colour, emphasis, or symbols. `format.icc()` is **shared with
    `summary.icc()`**, and its exact text is pinned by **8 snapshot files** (`_snaps/icc-methods.md` + the seven
    per-design `icc-*.md`, which mask the CI bounds to `[CI]` for MC-jitter stability) plus `test-vignette-claims.R`.
  Four scope questions were put to the maintainer at the plan gate this session; all four answered there.
- Decision (maintainer-approved this session, 2026-07-11, via the four-question plan gate):
  - **Scope: M43 = a presentation-only polish of the two console surfaces, in one milestone / two slices.** No
    new estimand, engine, fit, CI machinery, public argument, or dependency (#6); **no displayed number changes**;
    **no Fable** (#19 — no RB tripwire: no new oracle, no exported-API signature change, no IP touched).
  - **Name kept as `choose_icc()`** — the request's "`suggest_icc()`" was a misremembering. No rename and **no
    alias**: the name is documented across every vignette, the README, pkgdown, ADR-021, and the test suite;
    renaming/aliasing is doc churn and a second exported symbol for zero functional gain. (Reconsider only if a
    real naming complaint surfaces post-release.)
  - **`print`/`summary` restyle: tasteful *medium*** (not a light touch, not a full boxes/panels/colour-badge
    restyle). A `cli_rule` header replacing the `#` line; the coefficient table aligned with `cli::ansi_align`/
    `ansi_nchar` (width-correct under invisible ANSI), the **point estimate emphasized** and the **CI
    de-emphasized (dim)**; styled meta lines, the variance-components line, and the `k_eff` / Shrout–Fleiss /
    conflated-diagnostic notes. **Hard constraint — degrade cleanly:** with colour/ANSI disabled (CRAN, knitr,
    pkgdown HTML, non-colour terminals) the output must be deterministic, column-aligned, and readable at 80
    columns. cli's capability detection does this by default; the milestone must **prove** it by capturing every
    snapshot under `cli` reproducible output (ANSI stripped) and keeping the existing `[CI]` mask so MC/posterior
    interval jitter never destabilizes a *formatting* snapshot ([[verify-against-installed-package]]).
  - **Interactive tree: a styled walkthrough + breadcrumb** (no back-navigation, no restart, no
    confirm-before-resolve — those are deferred). Each outstanding question renders with a cli header/rule + a
    styled option list; a **running breadcrumb** of the choices made so far accumulates as the walk proceeds; the
    resolved object prints via a **restyled `print.icc_recommendation`** (rule header + styled Recommendation/Why/
    Run/Notes blocks). **ADR-021's dual-interface contract is preserved unchanged:** the pure
    `resolve_icc_recommendation()` core, the `is_interactive()` guard, the loud non-interactive underspecification
    aborts, and the **injectable `ask=` / `prompt_line()` test seam** all stay — this ADR enriches *rendering
    only*, and every existing `test-choose-icc.R` correctness test (crosswalk labels, round-trip
    call-equivalence, classed aborts) must pass **unmodified**.
  - **Slices (thin, #14):** **S1** — restyle `format.icc()` (shared `print`/`summary`), regenerate the 8
    `_snaps/icc-*.md` under reproducible cli output, add a claim test pinning every displayed estimate/CI-bound/
    component to `tidy()`/`glance()` (the number-invariance oracle). **S2** — restyle
    `ask_choice()`/`collect_answers_interactively()` (headers + option lists + breadcrumb) and
    `format.icc_recommendation()`; keep the resolver + seam untouched; add a reproducible-output shell snapshot
    driven through the injected responder. **S3** — this ADR, a NEWS bullet, WORDLIST if new terms, vignette/
    pkgdown re-render for any article that prints an `icc`/recommendation object, and the finish-task gate → PR.
- Consequences:
  - The two surfaces a user sees most — a fitted `icc` print and the interactive chooser — read cleanly, without
    changing a single coefficient, CI, or component (all still traceable to the object; the claim test enforces it).
  - **Correctness for a presentation milestone (#1 numerically N/A):** the "oracle" is **invariance**, not a new
    value — (a) every printed number equals `tidy()`/`glance()` to shown precision (S1 claim test), and (b) the
    `choose_icc()` round-trip call-equivalence oracle (ADR-021) is unchanged because the resolver core is
    untouched (S2). Snapshots pin *formatting* only, and only atop numbers that are already oracle-backed — never
    as the sole oracle for a value (validation doctrine).
  - Snapshot churn is expected and intended: the 8 `icc-*.md` print snapshots + the choose-icc shell snapshot are
    regenerated once under reproducible cli output; the `[CI]` mask is retained. `test-vignette-claims.R` numbers
    are unaffected (they read `tidy()`/inline values, not printed text), but any vignette that *shows* a printed
    object re-renders to the new form — checked in S3, not asserted.
  - No new `@export`, no `_pkgdown.yml` reference-index row, no `Imports`/`Suggests` change, no
    `estimand-spec`/`COVERAGE.md` touch. `cli` is already an `Imports` dependency (#8), so the richer styling
    adds no new package.
  - **Ruled out / deferred (record so not rediscovered):** a `suggest_icc()` rename or alias (name kept); a
    **full** restyle (boxes/panels/colour value-badges — plan gate chose medium); interactive **back-navigation /
    restart / confirm-before-resolve** (plan gate chose the breadcrumb walkthrough); making the walkthrough fire
    for non-interactive callers (the `is_interactive()` guard is a deliberate ADR-021 property, kept); and the
    long-parked ADR-021 deferrals (`fit=`/data-in path, `tidy`/`glance` on the recommendation, GUI/Shiny). The
    v0.2.0 consolidation / CRAN upload (ADR-022) remains the next step after M43.
- References: PRINCIPLES.md #1 (oracle-first — here number-invariance + the unchanged round-trip oracle, no new
  value), #2/#14 (plan before code; thin slices), #6 (additive, non-breaking — presentation over shipped
  behavior, no new estimand/engine/argument/dependency), #7 (explicit `print`/`summary`/`format` methods), #8
  (all user text via `cli`; classed `rlang` aborts unchanged), #16 (tracking + snapshots regenerated in-commit),
  #17 (full-restyle and back-nav parked to deferrals, not crept), #18 (the `k_eff`/Shrout–Fleiss/conflated notes
  keep characterizing honestly). ADR-021 (M12 — the `choose_icc()` dual interface, resolver core, and `ask=` seam
  this preserves and restyles), ADR-020/011/016/013 (the axes the tree walks). [[milestone-branches-and-prs]]
  (ships on `m43-cli-polish` via PR), [[verify-against-installed-package]] (snapshot discipline: reproducible cli
  output + retained `[CI]` mask; verify the installed package before the PR), [[run-lintr-before-push]] (semantic
  lint before push). No estimand-spec (presentation, not an estimator — cf. M4/M11/M13/M35/M40/M41/M42).

## ADR-054: Vectorize `type` and default to both — all defined formulations (A1/Ak/C1/Ck) from one fit
- Date: 2026-07-12
- Status: accepted
- Context: The maintainer raised a design question motivated by fit cost (a brms fit can take minutes to
  hours): should a call report **all four two-way formulations** — ICC(A,1), ICC(A,k), ICC(C,1), ICC(C,k) —
  instead of forcing a choice or a duplicate fit? Investigation confirmed the cost framing is even stronger
  than posed: **`type` never reaches any engine.** The fitted model depends only on the design, `raters`,
  and `engine`; agreement vs. consistency is post-fit arithmetic on the same variance components
  (`estimand.R` — agreement puts the rater main effect in the error set, consistency drops it; McGraw &
  Wong 1996). And the whole downstream pipeline is **already list-of-estimands**: `icc()` crosses
  `unit` × `level` × `occasions` into an estimand list, the MC interval transforms one shared draws matrix,
  the bootstrap does its refits once and loops estimands over the kept resample components
  (`ci-bootstrap.R`), and the posterior path reuses the same MCMC draws. Even the lavaan engine fits one
  `meanstructure = TRUE` model serving both types. `unit` and `level` are already **vectorized and default
  to everything defined** (`validate_unit()` keeps the whole vector, so a default call reports both
  `ICC(*,1)` and `ICC(*,k)`); **`type` is the lone scalar dimension** — the only axis where seeing the
  other coefficient means refitting an identical model. The marginal cost of the second type is
  microseconds atop a fit that is already paid for.
- Decision (maintainer-approved this session, 2026-07-12):
  - **`type` becomes vectorizable exactly like `unit`**: it accepts `c("agreement", "consistency")`, and
    that vector is the **new default** — a default two-way call reports all four defined formulations
    (A1/Ak/C1/Ck) from the single fit. A scalar `type` remains a filter for users who have named their
    estimand (#2). No engine, fit, component, or interval-method change: the estimand cross-product in
    `icc()` gains the type axis and everything downstream already consumes estimand lists.
  - **Drop-vs-abort policy for the ragged grid** (not every design defines every cell): a cell that is
    undefined **by design** and arrived via the *default* vector is **dropped with a `cli_inform`**
    (precedent: the averaged cluster-level `ICC(c,k)` drop on incomplete data); an **explicit** request
    for an undefined cell **keeps its loud teaching abort** (#5) — e.g. `type = "consistency"` on Design 3
    still aborts. Known agreement-only surfaces (unchanged, now defaulted around rather than into):
    Design 3 / the multilevel one-way (rater effect confounded), the conflated Eq. 14 diagnostic, and the
    fixed-rater numeric-`unit` agreement projection (`abort_fixed_agr_projection`, which under a defaulted
    vector drops the agreement cells instead). The single-level one-way keeps **no type axis at all**
    (ICC(1)/ICC(k) labels; `type` recorded as `NA`, as today).
  - **The estimand-first stance (#2) is enforced at the guidance layer, not by output suppression.** The
    package's existing pattern — `unit` defaults to both, the Eq. 14 conflated coefficient is computed and
    *flagged* in print — extends to type: `print.icc` groups rows by type (atop the M43/ADR-053 restyle),
    docs and `choose_icc()` keep teaching the choice, and `choose_icc()`'s contract (resolve to ONE named
    coefficient, ADR-021) is unchanged. Rationale: the variance components are printed anyway, so the
    withheld coefficients were always one line of arithmetic away — suppression taxed the diligent user
    (the A−C gap *is* the rater main-effect variance share, a systematic-bias diagnostic) without stopping
    a determined coefficient-shopper.
  - **Sequencing:** implement as its own milestone (plan gate to set slices/snapshot inventory), targeted
    at **0.2.0** — i.e. **after** the pending v0.1.0 CRAN handoff (release prep is DONE and verified;
    ADR-022 reaffirmed 0.1.0 as the first-submission number). Holding the submission to squeeze this in
    would invalidate a completed `--as-cran` verification for a change that alters no computed value; a
    documented default-shape change in 0.2.0 (NEWS behavior entry) is the cheaper path. If the maintainer
    instead chooses to hold the handoff, the release gate re-runs in full — that call stays with the
    maintainer at the milestone plan gate.
- Consequences:
  - One fit — including an expensive Bayesian one — yields every defined coefficient; the
    choose-a-subset-or-refit asymmetry between `type` and `unit`/`level` is gone.
  - **Public API change under #6, hence this ADR**: no computed value changes and every existing explicit
    call is untouched, but the *default* estimate table grows from 2 rows to (up to) 4, so default-call
    `print`/`tidy()` output changes shape. All per-design print snapshots regenerate once
    ([[verify-against-installed-package]]); a NEWS entry documents that positional indexing of default
    `tidy()` rows is not stable across this change. Multilevel × replicates default prints get large
    (level × unit × occasions × type); the print grouping must keep them readable — a presentation
    acceptance criterion for the milestone.
  - Test/oracle surface: no new oracle values needed for balanced/complete designs (all four formulations
    are already individually oracle-backed); the milestone adds coverage that the *defaulted* vector
    reproduces the scalar calls cell-for-cell (an invariance check, cf. ADR-053's number-invariance
    pattern) and pins the inform-and-drop behavior per agreement-only design.
  - **Ruled out (recorded so not rediscovered):** (a) *always-four with no filter* — the scalar filter
    stays, both for estimand-named workflows and because some cells are undefined by design; (b) a
    *post-hoc `update(x, type = ...)` recompute-from-stored-fit method* — it solves the refit cost but
    adds a second API surface the vectorized argument makes redundant (revisit only if a real
    recompute-without-refit need surfaces, e.g. changing `conf_level` on a stored brms fit); (c) keeping
    the default scalar (`"agreement"`) with vector opt-in — rejected as inconsistent with `unit`/`level`
    defaults and as preserving the suppression-as-guidance posture the Decision rejects.
- References: McGraw, K. O., & Wong, S. P. (1996), *Psychological Methods, 1*(1), 30–46 (the
  agreement/consistency families and single/average units this reports jointly). PRINCIPLES.md #2
  (estimand-first — honored via guidance, not suppression, per the Decision), #5/#8 (drop-vs-abort policy:
  defaulted-in undefined cells inform-and-drop via `cli`, explicit requests keep classed teaching aborts),
  #6 (default output contract change requires this ADR), #14 (implementation deferred to a planned
  milestone with thin slices), #16 (snapshots regenerate in-commit), #18 (print grouping must keep the
  larger default table honest and readable). ADR-021 (`choose_icc()` single-recommendation contract,
  unchanged), ADR-022 (release plan — the pending v0.1.0 handoff this does *not* hold up; targets 0.2.0),
  ADR-029 (the incomplete `ICC(c,k)`
  inform-and-drop precedent generalized here), ADR-053 (the print/summary restyle this grouping builds
  on). [[milestone-branches-and-prs]] (implementation ships on its own branch via PR);
  [[verify-against-installed-package]] (snapshot regeneration discipline).
