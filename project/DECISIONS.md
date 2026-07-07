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
