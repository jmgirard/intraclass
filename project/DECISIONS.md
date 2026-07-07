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

## ADR-014: M7 scope — SEM (lavaan) as an optional engine, two-way + one-way random
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
  - **Design scope = two-way random + one-way random** (maintainer choice). The
    lavaan engine supports `model = "twoway"` (agreement + consistency × single/
    average) and `model = "oneway"` (ICC(1)/ICC(1,k)); numeric `unit` (D-study) is
    inherited for free via `resolve_divisor()` (as in M6). `raters = "fixed"`,
    multilevel (`cluster`), and **incomplete/unbalanced** designs → classed
    `abort_unsupported()` for lavaan, deferred and recorded (SEM handles missing via
    FIML, but that is its own slice). Wider than M5.5's twoway-only slice, still
    excluding the fixed real-fit and multilevel fits (#15).
  - **SEM parameterization (to be oracle-pinned, not assumed).** lavaan wants **wide
    data** (one row per subject; columns = raters for twoway, k exchangeable ratings
    for oneway), so `fit_lavaan()` reshapes the long `icc()` data to wide. Two-way: a
    one-factor model where the subject factor loads on the rater-indicators;
    **consistency** reads σ²_s / (σ²_s + σ²_res) off the factor and residual
    variances; **absolute agreement** adds the rater main-effect spread via
    **mean-structure (intercept) constraints** (Jorgensen 2021). One-way random: a
    **parallel** one-factor model (equal loadings, residual variances, and
    intercepts) over k exchangeable columns → ICC(1)/ICC(1,k). The engine returns the
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
  - **Oracles O-SEM (≥2 independent, targeting 4–5):** (a) **Jorgensen (2021) worked
    SEM-GT values** (textbook); (b) **point lavaan ≡ glmmTMB** on balanced SF
    `ratings` (0.290/0.620/0.715/0.909 twoway; 0.166/0.443 oneway) to a tolerance
    appropriate to REML-vs-ML/SEM (target ≤1e-3, **pinned during the slice, not
    assumed 1e-4**); (c) **`psych::ICC`** on the balanced case (twoway ICC2/ICC3,
    oneway ICC1/ICC1k); (d) **interval** lavaan MC CI ≈ glmmTMB MC CI (**absolute**
    gap on bounds — the M5.5 Windows lesson); (e) seeded simulation (recovery + 95% CI
    coverage). Provenance in `data-raw/oracle-sem.R`; O-SEM row in REFERENCES when
    asserted.
  - **Dispatch:** the M5.5 engine × design lookup gains lavaan rows for
    `{twoway, oneway} × random`; every other cell aborts `abort_unsupported()`.
    `check_installed("lavaan")` guards the path (light install preserved; lavaan →
    `Suggests`, **no companion package** since lavaan exposes `vcov()` natively —
    lighter than the lme4 + merDeriv pair).
  - **Bayesian engine deferred out of M7's first pass** (recorded so not
    rediscovered): the Bayesian backend (**rstanarm** preferred over brms for
    CI-install sanity — precompiled Stan, no toolchain) with a new
    `ci_method = "posterior"` (credible intervals from native draws) and half-*t*
    hyperpriors (ten Hove, Jorgensen & van der Ark 2020), scheduled as a **later
    slice of M7 or its own follow-on milestone** after the SEM slice lands. Also
    deferred: incomplete/unbalanced SEM (FIML); fixed-rater and multilevel SEM.
- Consequences: M7 ships the **SEM/lavaan engine** for the twoway + oneway random
  paths as two CI-green slices — Slice 1 twoway (congeneric/mean-structure), Slice 2
  oneway (parallel) + docs — extending the dispatch seam, adding lavaan to
  `Suggests`, and a `data-raw/oracle-sem.R`. `engine` gains a third value (additive,
  not breaking, #6; `@param engine` roxygen updated). No estimand-spec (engine, not
  estimand). The Bayesian engine and the wider designs stay deferred and recorded.
  `advanced.Rmd` gains an SEM-engine note with a backing `test-vignette-claims.R`
  line. Ships on `m7-sem-engine`, merged via PR; full CI matrix on the PR.
- References: PRINCIPLES.md #1, #2, #3, #5, #6, #8, #12, #15, #16, #17, #19; ADR-002
  (glmmTMB default + why an alternative engine needs its own vcov route), ADR-003 (MC
  CIs — corroborated by Jorgensen 2021), ADR-012 (the engine × design seam + the
  reuse-the-MC-path pattern this follows), ADR-013 (the arc that scheduled M7);
  Jorgensen (2021, *Psych* 3:113–133, doi:10.3390/psych3020011); lavaan (Rosseel
  2012, *J. Stat. Softw.* 48(2)); ten Hove, Jorgensen & van der Ark (2020, hyperprior
  guidance — for the deferred Bayesian slice); `CLAUDE_CODE_KICKOFF.md` §1 (optional
  engines in Suggests), §7 (detail a milestone at its start), §8.
