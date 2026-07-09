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
