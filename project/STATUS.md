# Project status

- **Active task: M45 T2 next** (branch `m45-conflated-consistency`). **T1 DONE (2026-07-12, AC1 ✓):** the
  derivation-confirmation spike (`data-raw/reviews/m45-conflated-consistency-spike.R`) confirmed
  consistency-conflated = flat two-way consistency ICC (drop σ²_r) — Route A identity + Route B tracking
  (|diff|=5e-4 vs the shipped flat `icc(type="consistency")`); attempt-then-degrade did NOT fire, sourced
  McGraw & Wong 1996. **T2 (next):** add the conflated × consistency error set (drop `"rater"`) to the
  estimand map at `R/estimand.R:87-95` — `error <- switch(type, agreement = c("rater","cluster_rater",
  "residual"), consistency = c("cluster_rater","residual"))` — remove conflated-consistency from the
  agreement-only drop/abort surface (the upstream guard + M44 inform-and-drop list), then the balanced
  glmmTMB/lme4 oracles (O-cc-Eq14-analogue / O-cc-lme4 / O-cc-population) + invariants.
- **M45 planned (2026-07-12, ADR-056):** the *consistency-conflated single-level ICC* — drop σ²_r from the
  agreement-conflated error → the **flat two-way consistency ICC** read off the multilevel fit (sourced
  McGraw & Wong 1996, the symmetric twin of the M18 §6a agreement derivation; **not a guessed formula**, #4).
  Scope: crossed Design 1, random raters, single+average, **balanced + incomplete/ragged**, glmmTMB/lme4/brms
  (variance ratio — no θ² moment correction). Oracles O-cc-Eq14-analogue / O-cc-lme4 / O-cc-population /
  O-cc-brms; **no Fable** (sourced oracle, additive, no IP). Ships on `m45-conflated-consistency` via the
  implement path (attempt-then-degrade, ADR-028 — abort stays if the oracle unexpectedly fails). No active
  milestone until started. See [`MILESTONES.md`](MILESTONES.md) M45 + ADR-056.
- **Version reverted to dev (2026-07-12, ADR-055):** `DESCRIPTION` `0.2.0 → 0.0.0.9000`; top NEWS heading
  → `# intraclass (development version)`. Real version numbers are applied **only at the actual CRAN
  release**, and the **first CRAN submission is `0.1.0`** (supersedes ADR-054/M44's 0.2.0 framing — M44
  behavior untouched; the drafted `# intraclass 0.1.0` NEWS section stays as the pending release notes).
  Docs/metadata-only, direct to `main`. The release consolidation (ADR-022) stays a later milestone.
- Active milestone: **none** — M44 (ADR-054, vectorize `type` → all four formulations A1/Ak/C1/Ck from one fit)
  shipped (PR [#50](https://github.com/jmgirard/intraclass/pull/50), squash-merged to `main` at `7aff8b3`; full CI
  matrix green 9/9). A **public-API default-shape change** (#6): `type` is now vectorized like `unit`/`level` and
  defaults to both, so a default call reports A1/Ak/C1/Ck grouped by error definition and `d_study()` projects one
  curve per definition — **no computed value changes**, every explicit single-`type` call byte-identical
  (committed number-invariance oracle). Drop-vs-abort policy for undefined cells (ADR-029 precedent, incl. the
  connectedness guard ADR-054 didn't enumerate). **DESCRIPTION bumped 0.1.0 → 0.2.0** per ADR-054's 0.2.0 framing;
  the final version + `cran-comments` remain the **ADR-022 v0.2.0 release-consolidation** step (now the natural
  next milestone). **No Fable.** Last green CI: `7aff8b3` (main, 9/9). **Next milestone to plan: the v0.2.0 release
  consolidation** (or another ROADMAP item) via `/milestone-plan`.
- Prior milestone: **none active** — M43 (ADR-053, cli presentation polish: styled `print`/`summary` + interactive
  `choose_icc()` decision tree) shipped (PR #49, squash-merged to `main` at `38e16bd`; full CI matrix green 9/9,
  devel clean). A **presentation-only** milestone (cf. M4/M11/M40): no new estimand/engine/argument/dependency,
  **no displayed number changed** (number-invariance claim test + restyle-only snapshot diffs), **no Fable**.
  Restyled `format.icc()` (rule header, aligned table with estimate bold / CI dim, muted meta/notes — degrades to
  plain text off-colour) and the `choose_icc()` walkthrough (rule intro + per-question header + numbered options +
  running "So far:" breadcrumb + sectioned recommendation), preserving the ADR-021 resolver core + `ask=`/
  `prompt_line` seam. Fixed a latent `cli_verbatim` blank-line-drop so section spacing renders.
- **Release prep DONE — v0.1.0, submission-ready, handoff pending** (2026-07-12). At the release version gate the
  maintainer **kept `0.1.0`** (ADR-022 reaffirmed — the *first* CRAN submission carries the conventional
  first-release number; the earlier "v0.2.0" framing in the M43 notes was **not** taken). No version bump
  (DESCRIPTION already `0.1.0`); NEWS already consolidated under `# intraclass 0.1.0` (one "later milestones" →
  "a future release" wording fix). Full local verification GREEN: `devtools::document` no delta, `spelling` /
  `air` / `pkgdown::check_pkgdown()` clean, `urlchecker::url_check()` all-correct, **`devtools::check` --as-cran
  with PDF manual (`NOT_CRAN=false`, `manual=TRUE`) 0/0/0** (Courier/psnfss present); full CI matrix already green
  9/9 on the merge commit; `cran-comments.md` accurate (first submission, R 4.6.1 macOS, no downstream deps).
  **Handoff to maintainer** (out of band, never self-submitted): win-builder / R-hub, then
  `devtools::submit_cran()`, confirm the CRAN email, and after acceptance tag `v0.1.0` +
  `usethis::use_dev_version()`. *(M43 detail follows.)* Scoped from a maintainer request via a four-question plan gate:
  **(S1)** restyle `format.icc()` (shared by `print.icc`/`summary.icc`) from `cli_verbatim` monospace into
  **tasteful medium** cli (rule header, aligned coefficient table, estimate emphasized / CI dimmed, styled
  notes) — degrading to plain deterministic text under no-colour/knitr/CRAN; **(S2)** turn `choose_icc()`'s
  interactive walkthrough (today a plain `cli_ol` + `readline` loop, fired only when interactive **and** a
  required arg is missing) into a **styled cli decision tree with a breadcrumb**, preserving the pure resolver
  core + `ask=`/`prompt_line` test seam (ADR-021); **(S3)** ADR-053 + NEWS + vignette/pkgdown re-render +
  finish-task gate → PR from `m43-cli-polish`. **Presentation-only** (cf. M4/M11/M40): no new estimand/engine/
  fit/CI/argument/dependency (#6); correctness = displayed numbers provably unchanged (identity vs. `tidy()`) +
  the `choose_icc()` round-trip oracle unchanged; **no Fable** (no RB tripwire). Plan-gate decisions: **name
  kept `choose_icc()`** (the request's "`suggest_icc()`" was a misremembering — no rename/alias); one milestone
  / two slices; medium restyle (not full boxes/badges); breadcrumb walkthrough (no back-nav). **v0.2.0 release
  consolidation (ADR-022) stays the next step _after_ M43.**
- **Decision recorded (2026-07-12): ADR-054** — vectorize `type` in `icc()` (accept
  `c("agreement", "consistency")`, like `unit`/`level`) and **default to both**, so a default two-way call
  reports every defined formulation (A1/Ak/C1/Ck) from ONE fit. Motivated by fit cost (brms); investigation
  confirmed `type` never reaches any engine and all three interval methods already amortize over estimand
  lists, so the second type is free. Undefined-by-design cells (Design 3, conflated Eq. 14, fixed-rater
  agreement projection) inform-and-drop when defaulted in, keep their teaching aborts when explicit (#5;
  ADR-029 precedent). **Sequencing: does NOT hold up the pending v0.1.0 handoff — targets 0.2.0.** Next
  milestone to plan (via `/milestone-plan`) after the CRAN submission/acceptance.
- Prior milestone: **none** — M42 (ADR-052, the benchmark-vs-prior-art comparison article) shipped (PR #48,
  squash-merged to `main` at `1baf7db`; full CI matrix green 9/9, devel clean). An **engineering/docs milestone**
  (cf. M4/M13/M35/M40/M41) with a bounded dependency delta: one reader-facing
  `vignettes/comparison-with-other-packages.Rmd` — a **validation** half (`intraclass` ≡ `psych` ≡ `irr` across
  the six-coefficient family on balanced `ratings`, max gap 6.7e-6, a REML-vs-ANOVA difference; Gwet's `irrICC`
  agrees too) + a **differentiation** half (on `ratings_incomplete` classical listwise deletion collapses to 2/6
  subjects while `intraclass` uses all 20 cells via `k_eff`=3.27; cited capability matrix). Two new
  test/vignette-only `Suggests` (`irr`, `irrICC`); **`gtheory` cited not depended on** (removed from CRAN
  2025-03-24); `irrICC` pinned only on the balanced case it exactly matches (#1/#4). No new estimand;
  **no Fable**. **With M42 both release-strengthening milestones are shipped (M41 clarity ✓ → M42 benchmark ✓) —
  the next step is the v0.2.0 release consolidation** (version bump + NEWS heading + cran-comments; ADR-022),
  then the CRAN upload. **The v0.2.0 consolidation needs its own milestone/ADR** (out-of-band release work,
  ADR-022) — v0.1.0 has been "submission-ready" since M13 with ~28 milestones of capability accreted under the
  unreleased `0.1.0` NEWS heading.
- Prior milestone: **M40** (ADR-050, accessibility rewrite of the two front-door vignettes
  `getting-started` + `choosing-an-icc`) shipped (PR #46, squash-merged to `main` at `e34f037`; full CI matrix
  green 9/9). A **docs milestone** (cf. M4/M13/M35): no new estimand/engine/CI machinery/dependency; correctness
  = live-computed + claim-tested numbers (#1/#4/#12); **no Fable**. Rewrote both entry-point articles for applied
  readers — a from-scratch on-ramp, plainer language for the confidence interval and the estimand vocabulary, a
  warmer "start here" framing, first-use glosses, and a sourced/caveated **interpretation-band guide** (Koo & Li
  2016 / Cicchetti 1994, "judge the interval not the point"; no verdict computed — #4/#18), cross-linked between
  the two articles. Shipped in one session (retro → ADR-050 → S1 → S2 → S3 gate → PR #46 → merge). **The next
  milestone needs an ADR after a short retro** (founding brief §7) — and this session's retro flagged two
  strategic facts for it: (1) the clean-oracle **parity engine is exhausted** (from M23 on nearly everything
  shipped as parity because an oracle existed; the (C) corner closed at M36–M38, M39/M40 were the tail), so the
  remaining ROADMAP work is qualitatively different (🟣 research + Fable, heavy lifts, docs, or the release);
  (2) the **v0.2.0 release gap** — v0.1.0 "submission-ready" since M13 with ~15 milestones added since,
  unreleased (parked to ROADMAP/ADR-022) — is the biggest deliberate open call.
- Prior milestone: **M39** (ADR-049, `d_study()` occasion-count projection) shipped
  (PR #45, squash-merged to `main` at `91e14e7`; full CI matrix green 9/9, devel clean). The symmetric sibling
  of the M22 (ADR-032) rater-count projection: a new `n_o` argument on `d_study()` (mutually exclusive with `m`)
  projects the occasion count off a **balanced** within-cell replicate fit, holding raters at `k_eff`. It landed
  as a **thin projection slice** — occasion projection reuses the existing replicate grid (hold `m`, sweep the
  `occ` axis over `n_o`) and `icc_point()`'s per-component `error_divisors`; the multilevel cluster-flat behavior
  emerged for free (its error set has no pure-error term). The one genuine estimand insight — occasion projection
  is well-posed for **fixed absolute agreement** where the rater axis is not (occasions are a random facet) — is
  sourced in spec §9.3 and tested. **No Fable** (variance-ratio push-forward, MC interval reused → no coverage
  pathology). Deferred (still parked): **ragged**-replicate occasion projection (🟣 effective-`n_o` divisor),
  brms/posterior occasion projection, the 2-D `m × n_o` surface. (Its "next milestone needs an ADR after a retro"
  note is now resolved — that retro ran this session and opened **M40/ADR-050**.)
- Prior milestone: **M38** (ADR-048, brms engine parity for the fixed multilevel cells) shipped
  (PR #44, squash-merged to `main` at `4124297`; full CI matrix green 9/9). It closed the **brms** half of the
  (C) research/blocked corner: Cell 1 balanced fixed cluster level (M37 sibling) + Cell 2 incomplete/ragged
  fixed-nested Design 2 (M36 sibling), both **clean guard-lifts** (no new fit code — the estimand machinery was
  already engine-agnostic and the 2b moment machinery already per-cluster ragged-ready). Cell 2's coverage gate
  (O-Bayes-IFNML, 4 cells × n_rep 240) came back **NOMINAL** — .975/.954/.983/**.970**, the C_n=80 boundary
  showing **no incidental-parameters decay** — so the ADR-048 stop-and-replan branch did not fire and **no
  Fable** was needed. The residual (C) work is now only the genuinely-open **incomplete cluster-level fixed**
  (🟣 double-blocked) and the **lavaan** siblings (blocked on the multilevel-SEM lift). **The next milestone
  needs an ADR after a short retro** (founding brief §7).
- Prior milestone: **M37** (ADR-047, fixed-rater cluster-level ICC, crossed Design 1, balanced)
  shipped (PR #43, squash-merged to `main` at `f0b29b7`; full CI matrix green 9/9). The last parked
  **(C) research/blocked** corner — the cluster-level sibling of M10. Investigation split the ROADMAP's blanket
  "blocked" into a **parity-shippable balanced crossed cell** (reads `{σ²_c | θ²_r, σ²_cr}` off the shipped M10
  fit — **no new fit function**, since `icc_estimand()` keys the cluster error set on `level` not `raters`) and
  a **genuinely-open incomplete cell** (double-blocked: ten Hove open small-*k* estimator + the M9 §9 `ICC(c,k)`
  divisor — deferred). A **feasibility spike settled the one open question** (Slice 1): fixing the rater main
  effect does **not** bias the `(1|cluster:rater)` interaction, so the random σ²_cr is the correct fixed
  cluster-level error and the coefficient reduces to the M5 random cluster-level ICC **exactly** → **Outcome A,
  no Fable** (the pre-authorization did not fire). O-FCL: reduction 2.1e-6, cross-engine 1.7e-5, non-circular
  recovery interior coverage .975/.925; the σ²_c=0 boundary under-covers **identically to M5-random** (the
  shared cluster-signal-zero loss, a candidate follow-up, not an M37 defect). The default call now returns
  **both** levels for balanced fixed raters. **The next milestone needs an ADR after a short retro** (founding
  brief §7); remaining (C) work is all deferred/engine-parity (incomplete cluster-fixed 🟣; brms/lavaan cluster
  siblings).
- Prior milestone: **M36** (ADR-046, incomplete/ragged fixed-rater nested Design 2) shipped
  (PR #41, squash-merged to `main` at `f5a19e8`). It generalized the balanced M19 `theta2r_fixed_nested()` to
  unequal per-cluster k_c (bit-identical on balanced), lifted the deferral for glmmTMB/lme4 (brms refused),
  and shipped **both** single and average `ICC_s(·,k)` at the subject level — the averaged coefficient's
  "attempt, else 🟣 research" clause **resolved to ship** (pinned by the exact single-cluster reduction to flat
  M3; its divisor is the per-subject `k_eff`, the M19 random-nested divisor, **not** the open per-cluster
  `ICC(c,k)` divisor — ADR-046/the board had conflated the two, #18). O-IFNML committed (non-circular
  finite-population recovery; coverage interior .967 / boundary θ²=0 .942; no Fable at ship time). A
  **post-hoc gated Fable review** (maintainer-requested, #19; `fable-review-m36-incomplete-fixed-nested-
  {brief,response}.md`) landed 2026-07-11 with a **clean bill — no corrective follow-up**: the ragged 2b
  construction's identities verified against exact GLS (`fable-check-m36-identities.R`), and the
  cluster-count sweep Opus omitted run at n_rep=500 (`fable-check-m36.R`) — boundary coverage **flat to
  C_n=80** (.951–.968 across four regimes), no M28-style decay. Three doc/test-asset follow-ups
  recommended (response §6): a C_n=80 boundary sentinel + one low-n_s cell at the next O-IFNML
  regeneration, two spec sentences (harmonic-k_eff identity + Cov(θ²_c, 1/m_s) caveat; plug-in b_c/REML
  note), and an ADR-046 amendment — **not yet ingested**. Feasibility spike
  provenance: `data-raw/reviews/m36-feasibility-spike-{point,coverage}.R`. **The next milestone needs an ADR
  after a short retro** (founding brief §7); the remaining **(C)** corner is **cluster-level fixed** raters
  (no scaffolding; ten-Hove open question).
- Prior milestone: **M35** shipped (PR #40, ADR-045; squash-merged to `main` at `d69f39e`). The
  vignette-reassessment **docs** milestone: fixed five materially false "planned for a later milestone" claims
  in `advanced.Rmd` (M14/M15, M18, M19, M20/M33, M21 all shipped the "later" work), retired the overloaded
  504-line `advanced.Rmd` into four focused articles (`multilevel-designs`, `engines`, `interval-methods`,
  `d-studies-and-replicates`), and documented the M23–M34 **Bayesian engine** (brms / `posterior` / `prior=` /
  HPDI) for the first time in any vignette. Docs milestone (cf. M4/M13) — no new estimand/engine/CI
  machinery/dependency; correctness = live-computed + claim-tested numbers plus **genuine committed brms output
  from a local live rstan run** (brms chunks `eval=FALSE`, CI has no Stan toolchain — [[brms-live-fit-skip-on-ci]]);
  **no Fable review**. **No milestone is currently in flight; the next needs an ADR after a short retro (founding
  brief §7).**
- Prior milestone: **M34** shipped (PR #39, ADR-044; squash-merged to `main` at `3fc133c`). The
  Bayesian **customization** milestone (direction (B), `ROADMAP.md`) — interface/customization work, **not**
  new estimand (cf. M5.5/M7/M11/M16, no estimand-spec); two additive, non-breaking optional args whose defaults
  reproduce shipped M23+ results **bit-identically**, each backed by a **REDUCTION oracle** (no coverage claim,
  no Fable review). **Slice 1** — `icc(prior = NULL)` (brms-only; default = sourced half-*t*(4,0,1)) threaded
  through `fit_brms_common()` via an injected `brm_args$prior` (**no `fit_brms_*` wrapper changes**; `prior`
  stays reserved in `brm_args`), classed `intraclass_custom_prior` footgun warning; O-PriorReduce (reduction +
  bit-identical round-trip + override-takes-effect + classed guards). **Slice 2** —
  `posterior_summary = c("percentile","hpdi")` (default percentile) under `ci_method = "posterior"`;
  dependency-free `hpdi_interval()` (index arithmetic ≡ `coda::HPDinterval`), `(HPDI)` header label +
  `ci$posterior_summary` field; O-HPDI (percentile default bit-identical + `coda` agreement ≤ 1e-8 + same MAP /
  no wider than percentile + classed guard). `coda` added test-only to `Suggests` (no new `Imports`). Full CI
  matrix green 9/9; `R CMD check --as-cran` 0/0/1; full suite (CI mode) 1227/0/21; installed-pkg both new paths
  driven. **No milestone is currently in flight; the next needs an ADR after a short retro (founding brief §7).**
- Prior milestone: **M33** shipped (PR #38, ADR-043; squash-merged to `main` at `34cb974`).
  `engine = "brms"` now covers the **last clean-oracle estimand gaps** on the parity ledger, in three thin
  slices, each a *shipped* frequentist coefficient read off posterior draws (engine/interval parity, not new
  estimand work, #6 — no new estimand-spec/argument/dependency; two brms guards narrowed + one removed +
  three new `fit_brms_*` helpers). **Slice 1** incomplete/ragged single-level **one-way**
  (`fit_brms_oneway()` reused; random → variance ratio, no θ² — the M30 regime); O-Bayes-IOneway coverage
  ragged **.9458/.9458** (n_rep 240). **Slice 2** **fixed-rater** within-cell replicates
  (`fit_brms_replicates_fixed()`; θ²_r per draw, 2b ≈ 0 on balanced data → θ²_r = σ²_r); O-Bayes-FRep
  **.9625/.9625**, containment 1.00. **Slice 3** **multilevel** replicates (`fit_brms_ml_replicates()`
  crossed D1 6-component + `fit_brms_nested_replicates()` nested D2 5-component; variance-ratio push-forward);
  O-Bayes-MLRep crossed **.9500/.9500**, nested **.9625/.9500**, containment 1.00. **Every oracle nominal —
  no Fable review anywhere** (the M30 variance-ratio regime held, exactly as ADR-043 predicted). Full CI
  matrix green 9/9; `R CMD check --as-cran` 0/0/1; installed-pkg all three new paths driven. **No milestone
  is currently in flight; the next needs an ADR after a short retro (founding brief §7).**
- Prior milestone: **M32** — shipped (PR #37, ADR-042; squash-merged to `main` at `dd8e3e2`).
  `engine = "brms"` now fits incomplete/ragged **nested random**-rater ICCs at the subject level for both
  designs — Design 2 (`fit_brms_nested_clusters`, Slice 1) and Design 3 (`fit_brms_nested_subjects`, the
  multilevel one-way, Slice 2) — the Bayesian sibling of the frequentist M19, completing the "brms ×
  incomplete × random" row. **Engine/interval parity** (#6): both slices narrowed the same `!balanced` brms
  guard's `ml_design != "crossed"` clause; no new fit, no θ² helper (random → variance ratios, no 2b, the M30
  regime). **Scoped RANDOM-only by an oracle-first catch** (incomplete *fixed* nested has no frequentist
  oracle, ADR-029). Slice 1 (Design 2) ragged coverage **NOMINAL** (.925/.925). **Slice 2 (Design 3)
  triggered a gated Fable review** (#19): the first n_rep-80 ragged cell drew **.8625** (below ≥ .88) — pin
  NOT loosened (#4), Fable NOT auto-invoked, characterized honestly (#18); **verdict (ADR-042 Amendment 2): a
  Monte-Carlo tail event, no estimator shortfall** (same incidence n=240 → .9458, 2,000-fit frequentist →
  .9555, PIT uniform). Fixture regenerated at **n_rep = 240 + per-rep seeding**, pins unchanged (.9375/.9417),
  and **n_rep ≥ 240 adopted for future ragged coverage cells**. Fable brief/response/harness committed as #19
  provenance. `R CMD check --as-cran` 0/0/0; full CI matrix green 9/9. **No milestone is currently in flight;
  the next needs an ADR after a short retro (founding brief §7).**
- Prior milestone: **M31** shipped (PR #36, ADR-041; squash-merged to `main` at `5d6848e`).
  `engine = "brms"` + `raters = "fixed"` now fits incomplete/ragged data at the two-way single level (Slice 1,
  `fit_brms_fixed()`) and the crossed Design-1 fixed multilevel subject level (Slice 2,
  `fit_brms_multilevel_fixed()`) — the Bayesian sibling of the frequentist M3 / M18 Slice 1. **Engine/interval
  parity, not new estimand work** (#6): both narrowed the one `!balanced` brms guard — **no new fit, no new θ²
  helper** (`brms_theta2r_draws()` / `brms_theta2r_moment_draws()` ship), no new argument/dependency. **The
  milestone's genuine risk — the 2b θ² moment correction going live single-level for the first time on ragged
  fixed data (`b ≠ 0`) — resolved NOMINAL for both** (O-Bayes-IFixed .965/.965 vs complete .955/.955;
  O-Bayes-IFML-fixed .91/.91 vs .95/.95 within MC error) → **no Fable review** (ADR-041's conditional
  escalation not triggered). Live -agree glmmTMB M3/M18 containment verified. **No milestone is currently in
  flight; the next needs an ADR after a short retro (founding brief §7).**
- Prior milestone: **M30 — Bayesian incomplete/ragged, two-way random + crossed multilevel random** — **shipped**
  (PR #35, ADR-040; squash-merged to `main` at `9d2f0ed`).
  `engine = "brms"` fits incomplete/ragged **random**-rater ICCs at the two-way single level (Slice 1) and
  the crossed Design-1 multilevel subject + cluster-`ICC(c,1)` levels (Slice 2) — the Bayesian sibling of the
  frequentist M3/M9. **Engine/interval parity, not new estimand work** (#6): both were narrowings of the one
  `!balanced` brms guard, reusing the shipped M3/M9 `k_eff`/connectedness read off posterior draws — no new
  fit, no new argument, no new dependency. Random → variance ratios, so no θ² functional and no 2b moment
  correction (the M29 regime). **The milestone's one unknown — ragged-data credible-interval coverage through
  `k_eff` — resolved NOMINAL at the subject level for both** (two-way .965/.965, crossed-ml .97/.97 for
  ICC(A,1)/ICC(A,k_eff); cluster ICC(c,1) .95 tracks complete .92, characterized per the M24 few-cluster
  caveat), so **no Fable review** (ADR-040's conditional escalation not triggered).
- Prior milestone: **M29 — Bayesian engine (brms), conflated diagnostic + within-cell replicates,
  two-way random, balanced/complete** — **shipped** (PR #34, ADR-039; squash-merged to `main` at
  `be4e25f`). The two remaining low-risk Bayesian parity follow-ons, both **variance-ratio**
  push-forwards (no θ² moment correction → no Fable review): the **conflated** diagnostic
  (`level = "conflated"`, ten Hove Eq. 14 — reads off the shipped M24 `fit_brms_multilevel()`
  five-component draws, no new fit) and **within-cell replicates** (`fit_brms_replicates()`; σ²_res →
  σ²_sr + σ²_e with an `occasions` per-draw divisor). Oracles O-Bayes-Conflated (Eq-14 identity +
  coverage + glmmTMB containment) / O-Bayes-Rep (single/average coverage + glmmTMB containment +
  average > single). No new estimand/spec/argument/dependency.
- Prior milestone: **M28 — Frequentist nested-fixed MC-interval coverage** — **shipped** (PR #33, ADR-038;
  squash-merged to `main` at `e6ce64d`). The spun-off M27 corollary (ADR-037 §6): the shipped frequentist
  nested-fixed θ²_{r:c} Monte-Carlo interval (`theta2r_nested_draws()`) undercovered the nested finite
  population, worsening with cluster count (boundary coverage .95/.86/.57 as C_n=5/20/80; worst ≈.37) — an
  incidental-parameters displacement, the frequentist sibling of the M27 Bayesian finding. Interval-method
  work, not new estimand work (#6); the point estimator is unchanged away from the boundary. **Slice 1** —
  the committed seeded coverage sim (oracle O-NFI, Fable Q6 grid) characterized the shortfall.
  **Slice 2** — a gated Fable review (#19) verdict adopted in full: a shared `theta2r_moment_draws()`
  (subtract **2b**, floor the per-draw **average**) now backs every fixed-rater MC interval across
  glmmTMB/lme4/lavaan; the nested **point** floor also moved to the average (point-in-own-CI containment
  .59→1.00); the crossed paths were unified (b≈0, coverage stays nominal) and the regime-conditional
  "deliberate displacement" note retired. Post-fix O-NFI nominal (interior .962/boundary .958, no
  collapse). `R CMD check --as-cran` 0/0/1; installed brms 29/0/0; full CI matrix green (9/9). Also this
  session, direct to `main`: the pkgdown **hex logo + favicons** (`f55682a`) and a ROADMAP
  vignette-reassessment proposal + stale-item cleanup.
- Prior milestone: **M27 — Bayesian multilevel (brms) fixed-rater, crossed Design 1 + nested Design 2,
  subject level, balanced/complete** — **shipped** (PR #32, ADR-037; squash-merged to `main` at
  `0a93fe6`). The brms siblings of the frequentist M10 (crossed fixed) / M19 Slice 2 (nested fixed);
  engine/interval parity, not new estimand work (#6). **Slice 1 — crossed D1 fixed**
  (`fit_brms_multilevel_fixed()`; θ²_r per posterior draw into the five-component `draws`) + O-Bayes-FML
  (coverage .95, containment 1.00). **Slice 2 — nested D2 fixed** (`fit_brms_nested_fixed()` =
  `score ~ 0 + rater + (1|cluster:subject)`; θ²_{r:c} per draw) + O-Bayes-FNML. **Multilevel one-way was
  already brms** (Design 3, M25) — the "fixed/one-way at the multilevel level" deferral was stale on the
  one-way half; M27 is fixed-rater only and corrected the wording. **The milestone's substance — a gated
  Fable review (#19, ADR-037 amendment):** the **raw** θ²_{r:c} push-forward undercovers the nested
  finite population (coverage 0.86, →0 as clusters accrue — an incidental-parameters pathology). Verdict
  adopted: subtract **2b** (`b = tr(C·Σ_post)/(k−1)` = σ²_res/n_s; **two** inflations — push-forward +
  plug-in of the center — the Bayesian MAP reads off the draws so needs both, the frequentist point
  removes one), **floor the per-draw cluster AVERAGE** not each cluster (per-cluster flooring → zero
  boundary coverage, #3), and **unify** the crossed/single-level helper to the same path
  (`brms_theta2r_moment_draws()`; 2b ≈ 0 there). Scopes ADR-036's "posterior integrates it" (true for
  linear functionals, false for the convex quadratic variance functional). Regenerated oracles match
  Fable's predictions: O-Bayes-FNML interior coverage **.95**/MAP −.017, boundary(θ²=0) **1.00**;
  O-Bayes-FML **.95**. `R CMD check --as-cran` 0/0/1; full suite 1175 pass / 0 fail; all 9 live Stan fits
  pass locally (`skip_on_ci`). Corollary spun off: the frequentist nested-fixed MC interval likely shares
  an attenuated 1b displacement → its own ADR (point estimator unaffected).
- Prior milestone: **M26 — Bayesian engine (brms), one-way + fixed-rater, two-way, balanced/complete** —
  **shipped** (PR #31, ADR-036; squash-merged to `main` at `c02bc38`). The two lowest-risk
  **single-level** Bayesian follow-ons, closing the arc's single-level gap: **Slice 1 — one-way random**
  (M6 analog; `fit_brms_oneway()` = `score ~ 1 + (1|subject)`, a strict subset of `fit_brms_twoway()`)
  + O-Bayes-OW; **Slice 2 — fixed-rater two-way** (M2/M3/M10 analog, the brms sibling of the lavaan
  fixed path M21 shipped; `fit_brms_fixed()` = `score ~ 1 + rater + (1|subject)`, θ²_r read **raw** per
  posterior draw from the rater fixed-effect draws) + O-Bayes-Fixed. Engine/interval parity, not new
  estimand work (#6) — no new estimand-spec/argument/dependency; two brms guards narrowed + two
  dispatch branches. **Oracle-first resolution (Slice 2, #18):** brms has a prior, so (a) **raw** θ²_r,
  no frequentist bias correction (it moves the ICC ~0.002 and double-counts), and (b) balanced
  `fixed ≡ random` holds only **approximately** → the oracle is **containment** (glmmTMB fixed inside
  the credible interval), not equality. **Honest finding (Slice 1, #18):** one-way `ICC(1)` MAP biased
  low ~−12% at k=2 (falsifying the "spared" guess) → the k=2 caveat note fires for one-way too.
  `R CMD check --as-cran` 0/0/1; test suite 949 pass / 0 fail; all 7 live Stan fits pass locally.
- Prior milestone: **M25 — Bayesian multilevel (brms), nested Designs 2/3, balanced/complete, random** —
  **shipped** (PR #30, ADR-035; squash-merged to `main` at `2ff081b`). The direct
  continuation of the Bayesian arc — the **M8 analog of M24**: same brms engine + half-*t*(4,0,1) prior
  + `ci_method = "posterior"`, extended from the crossed (Design 1) five-component fit to the paper's
  two **nested-rater** designs (raters nested in clusters, Design 2, four components; raters nested in
  subjects, Design 3, three components / multilevel one-way). **Engine/interval parity, not new estimand
  work** (#6) — the shipped **M8 subject-level** coefficients (`M8-nested-multilevel.md` §3, ten Hove
  2022 Eqs. 8–11, Table 3 middle/right) read off posterior draws; no new estimand-spec, argument, or
  dependency. Scope = the M8 box: **subject level only** (cluster level undefined for nested raters),
  **Design 3 agreement-only**, balanced/complete, random. **Slice 1** Design 2
  (`fit_brms_nested_clusters()`; brms guard narrowed + nested dispatch) + O-Bayes-NML-agree. **Slice 2**
  Design 3 (`fit_brms_nested_subjects()`) + the coverage oracle (companion `data-raw/oracle-bayesian-nested.R`;
  committed `bayesian-nested-oracle.rds`) + O-Bayes-NML-reduction/-coverage/-converge. **Honest finding
  (#18):** the nested subject level is ~unbiased even at k=2 (rel-bias < .01, nominal coverage) — no
  boundary-prone cluster estimand is exposed; the M24-style "k=2 more biased low" pin didn't hold and
  was corrected to the run, not tuned. The M24 few-cluster
  MAP-low caveat is **largely not exposed** — nested designs report no cluster-level ICC, so σ²_c is a
  nuisance component, not an estimand. Both fits are simple mirrors of the shipped M8 glmmTMB shapes;
  `fit_brms_common()`/`brms_component_draws()`/`brms_convergence()` already generalize over any `spec`
  (M24 work). Maintainer chose **both nested designs in one milestone** (two slices) over Design-2-only.
- Prior milestone: **M24 — Bayesian multilevel (brms), Design 1 crossed, balanced/complete, random** —
  **shipped** (PR #29, ADR-034; squash-merged to `main` at `6566057`). The **highest-value Bayesian
  follow-on** — ten Hove's native turf: the paper's own multilevel IRR estimator (2020/2022) *is* the
  half-*t*-hyperprior Bayesian model M23 built, so M24 fits the paper's estimator on the paper's
  flagship design. A **thin vertical slice** standing to M23 as M5 stood to M1/M2 — same engine
  (`brms`) + interval method (`posterior`), extended to the five-component crossed fit under the
  half-*t*(4,0,1) SD prior (generalized verbatim). **Engine/interval parity, not new estimand work** —
  the shipped M5 subject/cluster coefficients read off posterior draws; no new estimand-spec, argument,
  or dependency; additive, non-breaking (#6). **Slice 1** subject-level (`fit_brms_multilevel()` +
  `fit_brms_common()` refactor; `brms_component_draws()`/`brms_convergence()` generalized to a component
  `spec`; the two-way-only guard narrowed to admit crossed Design 1 — nested/conflated/fixed/incomplete/
  one-way still abort loudly; brms multilevel dispatch). **Slice 2** cluster-level + the **O-Bayes-ML**
  coverage oracle (new `data-raw/oracle-bayesian-multilevel.R`, companion to the M23 script; committed
  `tests/testthat/fixtures/bayesian-ml-oracle.rds`). Findings reproduced **honestly** (#18):
  subject-level MAP ~unbiased + nominal coverage at k = 5 (rel-bias −1.5%, cover .94); cluster-level
  **few-cluster MAP-low caveat** at N_c = 20 (−16%/−25%, wide intervals still ~nominal). Oracles
  O-Bayes-ML-agree (live, MAP ≈ M5 glmmTMB/lme4 REML at the subject level) / -coverage (committed
  fixture) / -reduction (subject-level composes identically to two-way, no fit). Live Stan fits
  `skip_on_ci()`; CI covers via the committed fixture. Bayesian nested Designs 2/3 / fixed / one-way /
  incomplete / replicates / conflated stay deferred (later thin slices).
- Prior milestone: **M23 — Bayesian engine (brms) + `ci_method = "posterior"`, two-way random** —
  **shipped** (PR #28, ADR-033; the first Bayesian milestone, promoting the cross-cutting carryover
  deferred at M7/ADR-014). A **thin two-way-random slice** mirroring M5.5 (lme4) / M7 (lavaan) —
  engine + interval method, **not** new estimand work; additive, non-breaking (#6). Backend **brms**
  (rstan default, new `Suggests` behind `check_installed()`; `brm_args` passthrough forwards
  backend/chains/iter/cores per the ADR-033 amendment; rstanarm parked). Prior **half-*t*(4,0,1) on
  all random-effect SDs** (ten Hove et al. 2020 §3.3/§4.1). **MAP** point (mode of the ICC draws via a
  boundary-aware `posterior_mode()`, no new dep) + **percentile** credible interval; `"posterior"`
  forced-default & Bayesian-only. **Slice 1** engine end-to-end; **Slice 2** seeded MCMC +
  `brms_convergence()` (R-hat/bulk-ESS) + the **O-Bayes** coverage oracle
  (`data-raw/oracle-bayesian.R` reproduces ten Hove 2020's DGP through the shipped reduction and
  commits `tests/testthat/fixtures/bayesian-oracle.rds` (#4); findings reproduced with two reported
  divergences — convergence < 100% under fixed vs adaptive warmup; reflected-KDE σ_r MAP mildly
  low vs their `modeest`). Live Stan fit `skip_on_ci()` (no CI toolchain); CI covers the Bayesian
  path via the committed fixture. Bayesian fixed/one-way/multilevel/incomplete/replicates deferred.
- Prior milestone: **M22 — `d_study()` projection off a within-cell replicate fit** — **shipped**
  (PR #27, ADR-032; small standalone milestone after the M18–M21 arc). Promoted the one deferred
  `d_study()` corner (M17 §7 / M20): projecting the rater count `m` off a replicate fit, using the
  per-component `error_divisors` M17 already delivered (rater/interaction ÷ `m`, pure error ÷
  `m·n_o`), one curve per occasion setting (a new `occasions` column). **Slice 1** single-level
  two-way (fixed consistency via Spearman–Brown; fixed agreement refused) and **Slice 2**
  multilevel (crossed D1 + nested D2, subject across occasions, cluster single-occasion). Oracle
  O-RepDS (reduction at `m = k_eff` + cross-engine + Spearman–Brown + seeded coverage +
  monotone/[0,1]). No new estimand/spec/argument/dependency. Occasion projection and
  ragged-replicate projection stay deferred.
- Prior milestone: **M21 — SEM (lavaan) engine parity (bootstrap, fixed-rater, incomplete/FIML)** —
  **shipped** (PR #26, ADR-031; the **last milestone of the M18–M21 completeness arc**, ADR-027).
  Promoted the three M7 lavaan deferrals to lme4-style parity, engine parity not new estimand work:
  **Slice 1** `ci_method = "bootstrap"` for lavaan (M16 `simulate_refit` seam; `lavaan_simulate_refit`);
  **Slice 2** fixed-rater SEM — the Case-3A bias-corrected θ²_r (distinct from M7's raw; reduces to
  glmmTMB fixed AND random on balanced data, the M10 identity); **Slice 3** incomplete/FIML SEM
  (`missing = "fiml"`; attempt-then-degrade **resolved to ships** — consistency ≤8e-3, agreement
  ≤1.5e-2 vs glmmTMB, the raw-SEM small-sample bias not a FIML artifact; bootstrap gated on
  incomplete data). No new estimand/spec/argument/dependency. **The M18–M21 arc is complete — every
  🔵 not-yet gap in `COVERAGE.md` is closed.** M0–M21 shipped; package at v0.1.0.
- Active task: **none — M44 shipped and merged (PR #50, `7aff8b3`, CI 9/9).** The next work is the **v0.2.0
  release consolidation** (ADR-022): now that main is `0.2.0` with a `# intraclass 0.2.0` NEWS heading, the
  consolidation reconciles the final version, regenerates `cran-comments.md`, and runs the release checks — its
  own milestone (the `cairn:cairn-release` skill fits this shape). Plan it via `/milestone-plan`, or pick another
  ROADMAP item. The v0.1.0 CRAN submission remains the maintainer's out-of-band act (though with main at 0.2.0 the
  first submission would naturally carry the 0.2.0 line — a maintainer call at the consolidation). Local as-cran (with manual) 0/0/0; see the Release-prep bullet at
  the top. *Superseded (M43 S3, DONE 2026-07-12):* ADR-053 + NEWS bullet + WORDLIST (`cli`/`knitr`/`walkthrough`); three static brms vignette
  blocks + `README.md` re-rendered to the new style; finish-task gate GREEN (`devtools::check` CI-parity 0/0/0,
  `lintr` 0, `air`/`spelling`/`pkgdown` clean, installed-pkg print/choose_icc driven). *Superseded (S2, DONE
  2026-07-11):* `choose_icc()` walkthrough restyled — rule intro +
  per-question pointer/bold header + numbered options + running "So far:" breadcrumb
  (`choose_icc_breadcrumb()`); `format.icc_recommendation()` restyled (rule header, sectioned, print joins `\n`);
  resolver core + `ask=`/`prompt_line` seam untouched (all existing correctness tests pass unmodified); two
  reproducible-output snapshots added (plain ASCII @ 80 cols); `air`/`lintr` clean. ADR-053 already authored at
  start. *Superseded (S1, DONE 2026-07-11):* `format.icc()` restyled (medium cli — rule header, aligned table with estimate bold /
  CI dim, muted meta+notes); fixed a latent `cli_verbatim` blank-line-drop so section spacing renders;
  7 print-format snapshots regenerated (header-rule + blank lines + 1-space shift, **every number identical**,
  `[CI]` mask kept); number-invariance claim test added; `air`/`lintr` clean; affected + autoplot/choose-icc/
  multilevel/replicate suites green. S1 detail was: **M43 S1 — `print.icc` / `summary.icc` cli restyle** (started
  2026-07-11). Retro + ADR-053 done. **Acceptance (S1 → AC1/AC2):** restyle `format.icc()` (shared by
  `print`/`summary`) to tasteful-medium cli — `cli_rule` header, coefficient table aligned via
  `cli::ansi_align`/`ansi_nchar` with the estimate emphasized + CI dimmed, styled meta/components/notes;
  **degrade to deterministic 80-col plain text with ANSI off**; regenerate the 8 `_snaps/icc-*.md` under
  reproducible cli output (keep the `[CI]` mask); add a claim test pinning every displayed estimate/CI-bound/
  component to `tidy()`/`glance()` (the number-invariance oracle). Cover all print variants (two-way agreement/
  consistency, one-way, multilevel subject/cluster/conflated, within-cell replicates, incomplete `k_eff`,
  lavaan/lme4 headers). **Principles:** #1 (oracle = number-invariance vs `tidy()`), #6 (presentation-only, no
  behavior change), #7 (explicit methods), #8 (all text via `cli`), #16 (snapshots in-commit),
  [[verify-against-installed-package]] (reproducible-output snapshots + `[CI]` mask). **No Fable.** After S1: S2
  interactive tree → S3 gate → PR. M42 shipped and merged (PR #48, `1baf7db`). After M43,
  the **v0.2.0 release consolidation** remains the next work (out-of-band release milestone, ADR-022): version
  bump `0.1.0`→`0.2.0`, add a `0.2.0` NEWS
  heading over the ~28 milestones accreted since M13, `cran-comments.md`, `R CMD check --as-cran`, then the CRAN
  upload — needs its own kickoff (the `cairn:cairn-release` skill covers this shape). *Superseded (M42, done):*
  all 3 slices shipped and the full CI matrix came back green 9/9. Gate before the PR: `air format --check` /
  `lintr` 0 lints / `spelling` clean / `devtools::document` no delta / vignette-claims tests pass (incl. the
  three new comparison claims) / `pkgdown::check_pkgdown()` clean / `devtools::check` CI-parity
  (`NOT_CRAN=false`, `manual=FALSE`) **0/0/0** with all eight vignettes built and `irr`/`irrICC` present.
  Docs/deps-only → no installed-pkg estimator paths. Retro confirmed ADR-050/051 sequencing unchanged;
  maintainer chose the **article + claim tests** deliverable (plan question gate), delegated the package set →
  `psych`+`irr`+`irrICC` (`gtheory` dropped: removed from CRAN 2025-03-24, cited instead). *Superseded (M41,
  done):* all
  three slices shipped and the full CI matrix came back green 9/9. Gate before the PR: `air format --check` /
  `lintr` 0 lints / `spelling` clean / `devtools::document` no delta / vignette-claims tests pass /
  `pkgdown::check_pkgdown()` clean / `devtools::check` CI-parity (`NOT_CRAN=false`, `manual=FALSE`) **0/0/0** with
  all seven vignettes built. Docs-only → no installed-pkg estimator paths. *Superseded (M41 S3, done):* `multilevel-designs.Rmd` + `d-studies-and-replicates.Rmd`
  got warm on-ramps + glossary pointers + first-use deep-links (7 links verified, incl. the underscore `#…-k_eff`
  + unicode `#…-θ²_r` + dotted `#fixed-vs.-random-raters` anchors); no number touched; `test-vignette-claims.R`
  needed no relabel. *Superseded (M41 S2, done):* `engines.Rmd` + `interval-methods.Rmd` got warmer on-ramps + glossary pointers +
  first-use jargon deep-linked (12 `glossary.html#…` links, all verified against generated ids, incl. the dotted
  `#confidence-interval-vs.-credible-interval`) + two inline plain glosses; no number touched; package
  spell-check clean; both render. Also fixed a latent S1 anchor bug (the glossary's
  `multilevel-designs.html#subject-level-vs.-cluster-level` link needed the "vs." dot pandoc keeps — audited all
  14 cross-article links, the rest resolve). *Superseded (M41 S1, done):* new `vignettes/glossary.Rmd` (26 alphabetical terms with
  clean anchors) registered under a new **Reference** group in `_pkgdown.yml`; the two M40 front-door articles
  retrofitted with glossary deep-links + a "see the Glossary" pointer (no numbers touched); WORDLIST +`Wiberg`,
  NEWS Glossary bullet. Verified: all three touched articles + glossary render standalone; package spell-check
  clean; `pkgdown::check_pkgdown()` clean; every referenced anchor confirmed. Then S3 (`multilevel-designs` +
  `d-studies-and-replicates` + claim-test relabel + finish-task gate → PR). *(Retro this session: parity engine
  exhausted + v0.2.0 gap → M41 clarity / M42 benchmark / release, ADR-051.)* *Superseded (M40, done):* S1 `getting-started.Rmd` (`f53165b`; on-ramp +
  plain "About the confidence interval" + glosses + the canonical "Is this a good ICC?" band guide, Koo & Li
  2016 / Cicchetti 1994, "judge the interval" illustrated live, no verdict; prose numbers → inline `r`;
  REFERENCES + WORDLIST + a claim block). S2 `choosing-an-icc.Rmd` (`6558b50`; warmer "start here" intro +
  estimand/`k_eff` glosses + new "Once you have a number" section cross-linking the S1 bands — anchor
  `#is-this-a-good-icc` verified — instead of re-tabulating; tree/crosswalk/`choose_icc()`/live numbers kept).
  S3 gate (`6163f19`; NEWS bullet; local gate **GREEN** — `devtools::check` CI-parity (`NOT_CRAN=false`)
  **0/0/0** (all six vignettes built), `lintr` **0 lints**, `spelling`/`air`/`pkgdown::check_pkgdown()` clean,
  claim tests re-pass). Docs-only → no installed-pkg estimator paths. **No Fable.** *Superseded (M39, done):* T1
  (single-level, `a23c768`) + T2
  (multilevel, `e7be0df`) + T3 (docs/spec §9/tracking/gate) complete on branch `m39-occasion-dstudy`. The
  finish-task gate is green: `devtools::document` (no delta) / `air format --check` / `lintr` (0 lints) / full
  CI-mode suite **379/0/51** / `devtools::check` CI-parity (`NOT_CRAN=false`) **0/0/0**; installed-pkg both
  `n_o` paths driven through `library(intraclass)` (single-level plateaus 0.711→0.764; multilevel subject
  rises, cluster flat 0.455 + note). **No Fable** (variance-ratio push-forward, MC interval reused).
  **Next action: open the PR from `m39-occasion-dstudy`**; on green CI + merge, reconcile M39 → done + set
  "Last green CI". Note: a first `devtools::check` at the devtools default `NOT_CRAN=true` ran the live-Stan
  suite (CI skips it via `skip_on_cran`/`skip_on_ci`) and a brms credible-interval containment live test
  (O-Bayes-FML-agree) flaked on MCMC noise — **unrelated to M39** (no brms code touched); the CI-parity run is
  clean. *Superseded (M39 T3, in progress):* docs/spec/tracking plan stated below. Lifted the T1
  `occasion_axis && multilevel` guard; the **subject** level projects across `n_o` and the **cluster** level is
  occasion-invariant → returned as a **flat curve with a documented `cli` note**. The flat behavior emerged for
  free from the estimand: sweeping `occ` over `n_o` for both levels, the cluster `error_divisors` (set
  `{rater, cluster:rater}`, no pure-error term) simply ignore `n_o`, so `icc_point()` returns a constant. Only
  new code: lift the guard, route the cluster level through the full `n_o` sweep (was `min(proj_occ)`), emit the
  note. Verified: crossed-D1 subject reduces at n_o∈{1,3} → fitted ICC(*,k), cluster flat at 0.455 (= its
  single-occasion fitted value); nested-D2 subject-only. **O-OccDS multilevel** committed (crossed-D1 per-level
  reduction, cluster-flat + subject-rising invariant, lme4 cross-engine, nested-D2 subject-only reduction +
  monotone). Design 3 replicate is N/A (not a shipped `icc()` combination). Full suite **378/0/51**,
  `air`/`lintr` (0 lints) clean, `man/d_study.Rd` regenerated. **Next: `/start-task` T3** (docs — the
  `d-studies-and-replicates` vignette + a claim test — the M4.5 §9 estimand spec, NEWS/COVERAGE/REFERENCES,
  finish-task gate → PR). *Superseded (M39 T1, done):* Slice 1 shipped (committed `a23c768`); T2 in progress
  plan stated below.
  Shipped the `n_o` argument on `d_study()` and single-level occasion projection: hold `m = k_eff`
  (`unit = "average"`), sweep the replicate grid's `occ` axis over the requested `n_o`; `icc_point()`'s
  per-component `error_divisors` do the rest (only pure error σ²_e divides by `m·n_o`). Fixed absolute
  agreement now projects on the `n_o` axis (the §4 abort is gated on `!occasion_axis`; the rater axis still
  refuses it). Verified end-to-end: reduction exact at n_o∈{1, observed} → fitted ICC(*,k); fixed-agreement
  curve → analytic ceiling 0.8228; all guards fire. **O-OccDS single-level** committed to
  `test-d-study.R` (reduction both types, GT dependability form, `n_o→∞` ceiling + monotone/[0,1], the
  fixed-agreement lift + reduction, lme4 cross-engine, seeded-sim coverage, four classed guards). Full suite
  374/0/51, `air`/`lintr` (0 lints) clean, `man/d_study.Rd` regenerated. **Next: `/start-task` T2** (Slice 2 —
  multilevel occasion projection: lift the T1 multilevel guard; subject projects, cluster is occasion-invariant
  → flat curve + note; multilevel O-OccDS). *Superseded (M39 T1, in progress):* started via `/start-task`;
  acceptance criteria + estimand + oracle plan stated below. Acceptance criteria (board T1): new `n_o` arg on
  `d_study()` (exactly one of `m`/`n_o`; both → abort; `n_o` valid only on a **balanced** replicate fit, else
  abort); occasion projection for random + fixed raters, agreement + consistency (fixed absolute agreement
  **now projects** on the `n_o` axis — the M22 §4 abort is lifted for occasions, kept for raters); print/tidy/
  glance carry the swept axis; O-OccDS single-level (reduction at `n_o` = fitted → shipped ICC(*,k); lme4
  cross-engine; analytic GT dependability form; `n_o → ∞` ceiling invariant; seeded-sim coverage; monotone/
  [0,1]); classed aborts (both-axes, non-replicate, ragged) via `cli`/`rlang` (#5/#8). Principles: #1
  (oracle-first, ≥2 independent), #2/#14 (estimand named — the existing replicate estimand at a projected
  `n_o` divisor; plan before code), #3 (boundary-aware MC interval reused), #5/#8 (classed aborts), #6
  (additive/non-breaking), #18 (finite-ceiling caveat). **Implementation insight:** occasion projection reuses
  the existing replicate grid — hold `m` at `k_eff` (`unit = "average"`) and sweep `occ` over the requested
  `n_o` (the raters axis holds `occ` and sweeps `m`); `icc_point()` is already generic over per-component
  `error_divisors`, and fixed-rater θ²_r flows through unchanged (M22 fixed-consistency + M31/M36
  fixed-agreement replicate paths already exercise it) — the only new behavior is *not* aborting fixed
  agreement on the `n_o` axis. No code written yet at this line; plan stated. The M4.5 §9 spec lands in T3
  with the docs. *Superseded (M39 planning, done):* ADR-049 + the M39 board + the ROADMAP flip (occasion-count
  → M39; ragged-replicate stays 🟣 parked) + the STATUS flip, all on branch `m39-occasion-dstudy` (committed
  `4a01ae0`). *Superseded
  active task (M38, done):* **M38 all 4 tasks done, local gate green, PR pending.** The finish-task gate is green
  (`devtools::document` / `air format --check` / `lintr` 0 lints / full CI-mode suite **1175/0** /
  `devtools::check` CI-parity **0/0/0** / installed-pkg both new brms paths driven). Next action: **open the PR
  from `m38-brms-fixed-multilevel-parity`**; on green CI + merge, reconcile M38 → done + set "Last green CI".
  *T4 (docs + gate) DONE (2026-07-11):* NEWS/COVERAGE/REFERENCES updated (O-Bayes-FCL / O-Bayes-IFNML
  registered), gate green, installed-pkg drive OK. *T3 (Cell 2 coverage oracle — the gate) DONE (2026-07-11):
  **NOMINAL, Cell 2 ships.*** The full O-Bayes-IFNML sim (4 cells, n_rep 240, ~960 live Stan refits) came back
  nominal in [.90,.99] at all cells — mod_interior .975 / mod_boundary .954 / high_interior .983 /
  **high_boundary .970** (the C_n=80 incidental-parameters probe, **no decay**); |bias| ≤ .008. Committed
  `bayesian-incomplete-fixed-nested-oracle.rds` + the O-Bayes-IFNML coverage test. The ADR-048 stop-and-replan
  branch did not fire (no pin-loosening, no Fable). *T2 (Cell 2 code)
  DONE (2026-07-11):* removed the brms incomplete-fixed-nested guard (`R/icc.R` ~800); `fit_brms_nested_fixed()`
  fits ragged data unchanged and `brms_theta2r_moment_draws()` already reads a per-cluster `k`, so the
  2b-under-imbalance correction fires per cluster with no new code; single + average `ICC_s(·,k)` subject level;
  live O-Bayes-IFNML-agree containment test (glmmTMB M36 .630/.808 contained); two stale deferral assertions
  removed; suite 1168/0. Then T4 (docs/NEWS/COVERAGE + finish-task gate). *T1 (Cell 1 — brms cluster-level
  fixed) DONE (2026-07-11):* removed the brms-specific
  cluster-drop at `R/icc.R:781` — balanced brms fixed cluster now routes through the engine-agnostic
  estimand/`posterior_summary()` path off the shipped `fit_brms_multilevel_fixed()` draws (no new fit),
  incomplete falls to the engine-agnostic balance gate (~`R/icc.R:1187`) and aborts. O-Bayes-FCL (live,
  `skip_on_ci`) + a fast incomplete-boundary guard; verified end-to-end (both levels returned, glmmTMB M37 point
  contained, brms fixed≈random cluster |Δ|max .0215); one stale test + roxygen updated; full suite 1170/0 (50
  live-Stan skipped), `air`/`lintr` clean. **T2 next:** lift the `R/icc.R:810` brms incomplete-fixed-nested
  guard; run `fit_brms_nested_fixed()` on ragged Design-2 data with `brms_theta2r_moment_draws()`
  (2b-under-imbalance); single `ICC_s(·,1)` + average `ICC_s(·,k)` at the subject level. Then T3 (Cell 2
  coverage oracle O-Bayes-IFNML — the gate: nominal → ship, under-covers → STOP-and-replan Cell 1 only), T4
  (docs/NEWS/COVERAGE + finish-task gate). Board: [`MILESTONES.md`](MILESTONES.md) M38. *Superseded active task (M37, done):* M37 shipped and merged
  (PR #43, `f0b29b7`). *Slice 3 (docs) DONE (2026-07-11):* extended
  `multilevel-designs.Rmd`'s fixed-rater section to the cluster level (the `ml-fixed` chunk now returns both
  levels) + a `test-vignette-claims.R` cluster invariant. *Slice 2 (the estimand + fit path) is DONE (2026-07-11):*
  lifted the `level="cluster"`+`raters="fixed"` abort for balanced crossed Design 1 (brms + incomplete
  refused), cluster-level `{σ²_c | θ²_r, σ²_cr}` reads off the M10 fit (no new fit); O-FCL/reduction (2.1e-6),
  /lme4 (1.7e-5), /recovery (committed fixture; interior coverage .975/.925, boundary parity with M5-random);
  full suite green after updating three stale "fixed multilevel = subject only" tests. *Slice 1 (the
  feasibility spike) is DONE — Outcome A, no Fable* (`data-raw/reviews/m37-feasibility-spike-{point,coverage,boundary-parity}.R`):
  reduction to the shipped M5 random cluster-level ICC is **exact** in all regimes (|Δ| ~ 1e-6; θ²_r=σ²_r
  **and s2cr_fixed=s2cr_random**, both |d| ~ 1e-7 — the σ²_cr verdict is that the **random σ²_cr is the correct
  fixed cluster-level error**, no finite-population correction); recovery of the non-circular finite-population
  truth is unbiased at C_n=80; the MC interval is at **exact M5 parity** (interior 0.963/0.992; the σ²_c=0
  boundary is 0.550 but **identical fixed-vs-random**, a pre-existing cluster-signal-zero loss, not an M37
  defect). Slice 2: lift the M10 `level="cluster"`+`raters="fixed"` abort (`R/icc.R` ~765) for **balanced
  crossed Design 1 only** (incomplete stays refused); read the cluster-level `(signal, {error set}, divisor)`
  off the shipped M10 fit (σ²_c signal, `{θ²_r, σ²_cr}` agreement / `{σ²_cr}` consistency, divisor `k`); route
  in `icc()`; `print`/`glance` surface it; MC CI reuses the M10 fixed sampler. Oracles **O-FCL/reduction**
  (balanced fixed ≡ M5 random cluster-level < 1e-4), **/lme4** cross-engine, **/recovery** (committed seeded,
  interior nominal + boundary parity, n_rep ≥ 240). Regression guard M1–M36 green; docs/NEWS/COVERAGE/
  REFERENCES in-commit (#16). Then Slice 3 (docs). Run via `/start-task`. *Superseded active task (M36, done):* incomplete/ragged fixed-rater nested
  Design 2 — `theta2r_fixed_nested()` generalized to unequal per-cluster k_c (bit-identical on balanced),
  guard narrowed to refuse brms only, both single + average `ICC_s(·,k)` shipped (average pinned by the exact
  single-cluster reduction to flat M3), O-IFNML committed (coverage interior .967 / boundary θ²=0 .942, no
  Fable); local gate + full PR CI matrix both green. Candidates parked in [`ROADMAP.md`](ROADMAP.md): **(C) research/blocked**
  (now just **cluster-level fixed** — no scaffolding, ten-Hove open question, likely a Fable review; the
  incomplete-fixed-nested half shipped as M36); **selectable
  `posterior` coupling**; **categorical/ordinal GLMM** (needs an estimand pass); **multilevel SEM**; the Wave-3
  `ICC(c,k)` incomplete divisor; occasion/ragged `d_study()`; the set-aside **clarity/accessibility rewrite**
  of `getting-started` / `choosing-an-icc` (deferred out of M35); and the out-of-band **CRAN upload**
  (ADR-022). *Superseded active task (M35, done):* all three slices shipped; the local finish-task gate and the
  full PR CI matrix both came back green. **Historical detail (M35 slices):**
  **Slice 3 — the Bayesian coverage — DONE**
  (committed this session): brms sections added to `engines.Rmd` (half-*t*(4,0,1) prior, `engine = "brms"`, the
  M34 `prior=` override + footgun warning) and `interval-methods.Rmd` (`ci_method = "posterior"`, MAP +
  percentile/HPDI `posterior_summary`). brms chunks are `eval=FALSE` illustrative with **committed real output**
  generated from a **local live rstan run** (#4; CI has no Stan toolchain — [[brms-live-fit-skip-on-ci]]); each
  section states the output is pre-computed. Honest findings preserved (the over-tight `normal(0,0.1)` prior
  collapses the ICC to ~0; brms MAP 0.24 < glmmTMB REML 0.29 at small *k*). All six articles render; all five
  inter-article anchor links verified against generated ids; `pkgdown::check_pkgdown()` / `air` / spell clean;
  NEWS updated. **Slice 2 — the split — DONE** (committed this session): `advanced.Rmd`
  (504 lines) retired into four self-contained articles — `multilevel-designs`, `engines`, `interval-methods`,
  `d-studies-and-replicates` — plus the two kept articles. Data-locality call: the multilevel forest plot moved
  to `multilevel-designs` (it needs `school`); the multilevel `choose_icc()` closer went there too. Fixed all
  cross-links + three external refs (README, `choosing-an-icc.Rmd`, the `choose_icc()` runtime note in
  `R/choose-icc.R`); wired `_pkgdown.yml`; relabelled `test-vignette-claims.R` per-claim article names; updated
  the 0.1.0 NEWS vignette list; `FIML` → `WORDLIST`. All six articles render self-contained;
  `pkgdown::check_pkgdown()` clean; claim tests green; `air`/spell clean. **Slice 1 — stale-claim fixes — DONE**
  (committed earlier this session). *Superseded active task (M34, done):* the next milestone needed an ADR
  after a short retro; that retro + ADR-045 opened M35 this session. Candidates parked in [`ROADMAP.md`](ROADMAP.md): **(C) research/blocked** —
  incomplete **fixed** nested and **cluster-level fixed** (no frequentist oracle; would need a simulation-oracle
  study, likely a Fable review); also parked — **selectable `posterior` coupling** (MC/bootstrap on a Bayesian
  fit), **categorical/ordinal GLMM** (needs an estimand pass), **multilevel SEM**, the Wave-3 `ICC(c,k)`
  divisor, occasion/ragged `d_study()`, the **vignette reassessment** (docs), and the out-of-band **CRAN
  upload** (ADR-022).
- Last green CI: **PR #49 (M43, cli presentation polish — styled print/summary + interactive `choose_icc()`
  tree) — full CI matrix green (9/9), squash-merged to `main` at `38e16bd`.** format-check / lint / pkgdown /
  test-coverage / `R CMD check` on macOS, Windows, and Ubuntu release·oldrel·**devel** all passed (no flakes;
  devel clean). Locally before the PR: `devtools::check` CI-parity (`NOT_CRAN=false`, `manual=FALSE`) **0/0/0**
  (all eight vignettes built), `lintr` **0 lints**, `spelling` / `air format --check` / `pkgdown::check_pkgdown()`
  clean, `devtools::document` no delta; 7 print-format + 2 `choose_icc` snapshots regenerated (restyle-only,
  numbers identical); installed-pkg `print.icc`/`choose_icc` driven. Presentation-only milestone — no estimator
  numeric paths changed. Prior green: **PR #48 (M42, benchmark-vs-prior-art comparison article) — full CI matrix
  green (9/9), squash-merged to `main` at `1baf7db`.** format-check / lint / pkgdown / test-coverage / `R CMD
  check` on macOS, Windows, and Ubuntu release·oldrel·**devel** all passed (no flakes; devel clean). Locally before the
  PR: `devtools::check` CI-parity (`NOT_CRAN=false`, `manual=FALSE`) **0/0/0** (all **eight** vignettes built,
  `irr`/`irrICC` present), full CI-mode suite **1244/0/51** (three new comparison claims pass), `lintr`
  **0 lints**, `spelling` / `air format --check` / `pkgdown::check_pkgdown()` clean, `devtools::document` no
  delta, all glossary anchors + four companion-article cross-links in the new article verified against generated
  ids. Docs/deps-only milestone — no installed-pkg estimator paths to drive. Prior green: **PR #47 (M41, clarity
  pass over the four secondary vignettes + a standalone glossary) — full CI matrix green (9/9), squash-merged to
  `main` at `3e00999`.** format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and
  Ubuntu release·oldrel·**devel** all passed; `devtools::check` CI-parity **0/0/0** (all seven vignettes built),
  `lintr` 0 lints, `spelling` / `air` / `pkgdown::check_pkgdown()` clean. Prior green: **PR #46
  (M40, accessibility rewrite of the two front-door vignettes) — full CI matrix green
  (9/9), squash-merged to `main` at `e34f037`.** format-check / lint / pkgdown / test-coverage / `R CMD check`
  on macOS, Windows, and Ubuntu release·oldrel·**devel** all passed (no flakes; devel clean). Locally before the
  PR: `devtools::check` CI-parity (`NOT_CRAN=false`) **0/0/0** (all six vignettes built), `lintr` **0 lints**,
  `spelling` / `air format --check` / `pkgdown::check_pkgdown()` clean, `test-vignette-claims.R` re-passes, the
  `getting-started#is-this-a-good-icc` cross-link anchor verified. Docs-only milestone — no installed-pkg
  estimator paths to drive. Prior green: **PR #45 (M39, `d_study()` occasion-count projection) — full CI matrix
  green (9/9), squash-merged to `main` at `91e14e7`.** format-check / lint / pkgdown / test-coverage / `R CMD
  check` on macOS, Windows, and Ubuntu release·oldrel·**devel** all passed (no flakes; devel ran clean). Locally
  before the PR: `devtools::check` CI-parity (`NOT_CRAN=false`) **0/0/0**, full CI-mode suite **379/0/51**, `air format
  --check` / `lintr` (0 lints) clean, installed-pkg both new `n_o` paths driven through `library(intraclass)`
  (single-level plateaus 0.711→0.764; multilevel subject rises, cluster flat 0.455 + note). Note: a first
  `devtools::check` at the devtools default `NOT_CRAN=true` ran the live-Stan suite (which CI skips via
  `skip_on_cran`/`skip_on_ci`) and a brms credible-interval containment live test (O-Bayes-FML-agree) flaked on
  MCMC noise — unrelated to M39 (no brms code touched); the CI-parity run is clean. Prior green: **PR #44 (M38,
  brms engine parity for the fixed multilevel cells) — full CI matrix green
  (9/9), squash-merged to `main` at `4124297`.** format-check / lint / pkgdown / test-coverage / `R CMD check`
  on macOS, Windows, and Ubuntu release·oldrel·**devel** all passed (no flakes; devel clean). Locally before
  the PR: `devtools::check` (CI-parity, `NOT_CRAN=false`) **0/0/0**, full CI-mode suite **1175/0**, `air format
  --check` / `lintr::lint_package()` (0 lints) clean, installed-pkg both new brms paths driven through
  `library(intraclass)` (Cell 1 returns both levels; Cell 2 subject single+average). Note: an initial
  `devtools::check` with the devtools default `NOT_CRAN=true` was recompiling the entire live-Stan suite
  (~40 min, which CI never runs — `skip_on_ci`); it was killed and re-run at CI-parity. Prior green: **PR #43
  (M37, fixed-rater cluster-level ICC) — full CI matrix green (9/9), squash-merged to
  `main` at `f0b29b7`.** format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and
  Ubuntu release·oldrel·**devel** all passed (no flakes; devel clean). Locally before the PR: `devtools::check`
  **0/0/0** (`--no-manual`; full suite + all six vignettes built, live brms Stan fits ran), `air format --check`
  clean, `lintr::lint_package()` 0 lints, installed-pkg cluster-fixed path driven through `library(intraclass)`
  (glmmTMB fixed cluster-level ICC(A,1) .363 / ICC(A,k) .695). Prior green: **PR #42 (M36 Fable-review
  ingestion) — full CI matrix green (9/9), squash-merged to `main`
  at `9aedfc9`.** The post-hoc gated Fable review (#19, maintainer-requested) confirmed the M36 ragged 2b
  construction sound (no corrective follow-up); ingestion applied its recommendations as doc/test-asset
  amendments — O-IFNML gained a C_n=80 cluster-count sentinel (coverage .967, no decay) + an n_s=4
  certification cell, plus ADR-046 Amendment 1 and the spec/REFERENCES notes. No shipped-code change. Prior
  green: **PR #41 (M36) — full CI matrix green (9/9), squash-merged to `main` at `f5a19e8`.**
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed (no flakes, no re-runs — devel ran clean). Locally before the PR:
  `devtools::test()` **1483 pass / 0 fail / 0 skip** (live brms Stan fits ran), `devtools::check()`
  **0 errors / 0 warnings / 0 notes** (`--no-manual` to sidestep the local TinyTeX Courier PDF-manual
  infra error, [[rcmdcheck-pdf-manual-courier]]); `air`/`lintr` (0 lints) clean; installed-pkg M36 path driven
  through `library(intraclass)` (glmmTMB ragged fixed-nested ICC(A,1) .295 / ICC(A,k) .483; lme4 single .2946;
  brms refused). Prior green: **PR #40 (M35) — full CI matrix green (9/9), squash-merged to `main` at `d69f39e`.**
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed (no flakes, no re-runs — the devel job ran clean this time). Locally
  before the PR: `devtools::test()` **1471 pass / 0 fail / 0 skip** (the live brms Stan fits ran locally),
  `R CMD check --as-cran` **0/0/0** (all six vignettes build + re-build OK, 29s), `air` / `lintr` (0 lints) /
  spell / `pkgdown::check_pkgdown()` clean; coverage unchanged (docs milestone, no new R code). Docs-only
  milestone — no installed-pkg estimator paths to drive. Prior green: **PR #39 (M34) — full CI matrix green
  (9/9), squash-merged to `main` at `3fc133c`.**
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed (no flakes, no re-runs). Locally before the PR: `R CMD check --as-cran`
  **0/0/1** (built with vignettes, only "New submission"); full suite (CI mode) **1227/0/21**; installed-pkg
  both new M34 paths driven through `library(intraclass)` (prior= default ICC(A,1) .166 / tight .284 + classed
  footgun warning; HPDI same MAP, narrower than percentile, `(HPDI)` header); `air`/`lintr`/spell clean. The
  local `R CMD check` caught (before the PR) an over-aggressive `posterior_summary` guard + an undeclared
  `coda`, both fixed (`coda` → `Suggests`). Prior green: **PR #38 (M33) — full CI matrix green (9/9),
  squash-merged to `main` at `34cb974`** — `R CMD check --as-cran` 0/0/1; installed-pkg all three new M33 paths
  driven (ragged one-way ICC(1) .556; fixed replicates ICC(A,1) .485; crossed-D1 replicates subject .313;
  nested-D2 replicates subject .538). Prior green: **PR #37 (M32) — full CI matrix green (9/9), squash-merged to `main` at `dd8e3e2`.**
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed. Locally before the PR: `R CMD check --as-cran` **0/0/0** (built with
  vignettes); `devtools::test()` full suite (CI mode) **1175/0/16** (the O-Bayes-INML-subjects coverage test
  passes against the regenerated n_rep-240 fixture); installed-pkg both ragged **nested** fits driven through
  `library(intraclass)` (Design 2 ICC(A,1) .585 + Design 3 ICC(1) .636, `ci = "posterior"`); `air`/`lintr`
  clean. Prior green: **PR #36 (M31)** at `5d6848e`.
  Superseded detail (M31): one lint-job re-run after fixing camelCase test locals `Nc`/`Ns` → snake_case
  ([[run-lintr-before-push]]); installed-pkg both ragged fixed fits driven (glmmTMB M3/M18 containment); full
  suite (CI mode) **1148/0/14**; `air`/`lintr` clean; coverage ~85% (below 90% by design —
  [[coverage-baseline]]). Prior green: **PR #35 (M30)** at `9d2f0ed`.
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed. Locally before the PR: `R CMD check --as-cran` **0/0/1** (full
  build, only "New submission"); installed `test-icc-brms.R` `NOT_CRAN=true` **266/0/0** (all live Stan
  fits ran, incl. O-Bayes-Conflated-agree + O-Bayes-Rep-agree); full suite (CI mode) **1089/0/10**;
  `lintr`/`air` clean; coverage ~85% (below 90% by design — [[coverage-baseline]]). Prior green: **PR #33
  (M28)** at `e6ce64d`.
- Blockers: **none.** M40 (ADR-050) shipped and merged (PR #46, `e34f037`), full CI matrix green 9/9; a docs
  milestone with no estimand/coverage claim and no Fable — its only risk, the interpretation bands, was met by
  real `REFERENCES.md` citations + caveats (Koo & Li 2016 / Cicchetti 1994; no verdict computed, #4). The next
  milestone needs an ADR after a short retro (founding brief §7); the retro's strategic flags (parity engine
  exhausted; the v0.2.0 release gap) are recorded on the active-milestone line above. Prior (M39, cleared): M39
  (ADR-049) shipped and merged (PR #45, `91e14e7`), full CI matrix green 9/9 (devel
  clean); the scoped (balanced) path had no research question and no Fable was needed (variance-ratio
  push-forward, MC interval reused). The ragged-replicate occasion half stays deferred, not blocking (its
  effective-`n_o` divisor is the open 🟣 item, M20/ADR-030). Prior (M38, cleared): M38 (ADR-048) shipped and
  merged (PR #44, `4124297`), full CI matrix green 9/9; the Cell 2 coverage risk
  (2b-under-imbalance-nested-brms) resolved NOMINAL (O-Bayes-IFNML C_n=80 boundary .970, no decay), so the
  stop-and-replan branch did not fire and no Fable was needed.
  Historical (M37, cleared): M37 (ADR-047) shipped and merged (PR #43, `f0b29b7`), full CI matrix green 9/9, no
  Fable review (the pre-authorization did not fire — Outcome A).
  Historical (M36,
  cleared): M36 (ADR-046) shipped and merged (PR #41, `f5a19e8`), full CI matrix green 9/9, no Fable review;
  the flagged risk (ragged 2b-under-imbalance interval) resolved nominal in the committed O-IFNML oracle
  (boundary θ²=0 coverage .942).
  Historical (M32, cleared 2026-07-10): the M32 Slice 2 ragged-Design-3 undercoverage finding
  (`.8625` at n_rep 80) went to a gated Fable review (#19) → **VERDICT: no shortfall, a Monte-Carlo tail
  event that does not replicate** (Fable re-ran the same incidence at n=240 → .9458; 2,000-fit frequentist
  arm → .9555; PIT uniform). Adopted in full (ADR-042 Amendment 2): **ship Slice 2 unchanged**, regenerate
  the fixture at n_rep=240 + per-rep seeding (pins unchanged, ragged ≥ .88 not loosened). **Regeneration
  DONE — verdict confirmed:** complete .9375/.9375, ragged .9417/.9417 (both ∈ the pre-registered [.92, .975];
  the .8625 tail did not recur — same incidence now .9417); all pins pass. Brief + response:
  [`fable-brief-m32-s2.md`](fable-brief-m32-s2.md) / `data-raw/reviews/fable-review-m32-s2-response.md`. Slice 2 code/oracle/fixture/tests are **staged in the working tree, UNCOMMITTED**
  (the coverage test asserts ≥ .88 and fails on the committed-evidence fixture — the honest signal, not
  loosened). Slice 1 (Design 2) is shipped/committed (7b8b60c) and unaffected.
- Updated: 2026-07-11 by main session (Opus) — **M39 shipped (PR #45, squash-merged at `91e14e7`); post-merge
  `project/` reconcile.** Flips STATUS to M39-shipped (active milestone none), sets "Last green CI" to the merge
  commit, compresses the MILESTONES M39 board to summary form (preserving the "Deferred out of M39" list),
  advances the MILESTONES preamble (M39 no longer in flight), and flips the ROADMAP `d_study()` entry
  (occasion-count → shipped as M39; ragged-replicate stays 🟣 parked). The whole milestone landed in one
  session on branch `m39-occasion-dstudy` (retro → ADR-049 → T1 single-level → T2 multilevel → T3 docs/gate →
  PR #45); full CI matrix green 9/9 (devel clean). Shipped as a thin projection slice reusing the M22 replicate
  grid (no new fit code); the multilevel cluster-flat behavior emerged from the estimand structure; **no
  Fable**. Local `main` fast-forwarded after the squash, merged branch deleted. Next: open the next milestone
  after a short retro — the estimand family is now very complete, so the ROADMAP candidates are mostly
  consolidation (CRAN/benchmark/docs), heavy research lifts (multilevel SEM, categorical GLMM), or the remaining
  🟣 open corners. Prior line: **retro of the M23–M38 arc + M39 planned (ADR-049,
  `d_study()` occasion-count projection).** Plan-only, no code (#14): wrote ADR-049 (context/decision/oracles
  O-OccDS + the API `n_o` decision and cluster-flat decision, both maintainer-approved via the plan question
  gate), added the M39 DoD board to MILESTONES + advanced the preamble/ADR-index (M39 in flight), flipped the
  ROADMAP `d_study()` item (occasion-count → M39; ragged-replicate stays 🟣 parked on the effective-`n_o`
  divisor), and flipped STATUS to M39-active. Branch `m39-occasion-dstudy` created off `main` @ `4124297`.
  Prior line: **M38
  shipped (PR #44, squash-merged at `4124297`); post-merge
  `project/` reconcile.** Flips STATUS to M38-shipped (active milestone none), sets "Last green CI" to the merge
  commit, compresses the MILESTONES M38 board to summary form (preserving the "Deferred out of M38" list),
  advances the MILESTONES preamble (M38 no longer in flight), and flips the ROADMAP (C) entry to "shipped as
  M38". The whole milestone landed in one session on branch `m38-brms-fixed-multilevel-parity` (retro →
  ADR-048 → T1 Cell 1 → T2 Cell 2 code → T3 coverage gate NOMINAL → T4 docs/gate → PR #44); full CI matrix
  green 9/9 (devel clean). Both cells shipped as **clean guard-lifts** (no new fit code); the Cell 2 coverage
  gate came back nominal, so the ADR-048 stop-and-replan branch did not fire and **no Fable** was needed. Local
  `main` fast-forwarded after the squash, merged branch deleted. Next: open the next milestone after a short
  retro — remaining (C) work is incomplete cluster-level fixed (🟣) + the lavaan siblings (blocked on
  multilevel SEM). Prior line: **M38 Task 4 (docs + finish-task gate) DONE — M38 tasks all
  complete, local gate green, PR pending.** NEWS/COVERAGE/REFERENCES updated for both brms fixed cells
  (O-Bayes-FCL / O-Bayes-IFNML registered). Local gate: `devtools::document` / `air format --check` /
  `lintr::lint_package` (0 lints) / full CI-mode suite **1175/0** (51 live-Stan skipped) / `devtools::check`
  (`NOT_CRAN=false`, CI-parity — a first run with `NOT_CRAN=true` was recompiling the whole live-Stan suite,
  ~40 min, and was killed) **0/0/0**; installed-pkg both new brms paths driven through `library(intraclass)`.
  M38 board flipped to **review**; next is the PR. Prior line: **M38 Task 3 (Cell 2 coverage oracle — the
  ship/stop gate) DONE: NOMINAL, Cell 2 ships.** Ran the full O-Bayes-IFNML sim (`data-raw/oracle-bayesian-incomplete-fixed-nested.R`;
  4 cells crossing {C_n 20, C_n 80} × {interior θ²=.30, boundary θ²=0}, unequal k_c, n_rep 240, ~960 live Stan
  refits, compile-once + `update(recompile=FALSE)`) in the background this session. **All four cells nominal in
  [.90,.99]:** mod_interior .975, mod_boundary .954, high_interior .983, **high_boundary .970** — the C_n=80
  boundary (the incidental-parameters probe, [[coverage-oracle-cluster-count-axis]]) shows **no decay**, so the
  2b-under-imbalance moment correction holds through the posterior on ragged nested data; |bias| ≤ .008, 7/240
  fits at C_n=80 discarded+counted (#18). Committed `bayesian-incomplete-fixed-nested-oracle.rds` + the
  O-Bayes-IFNML coverage test (7 assertions incl. the C_n=80-boundary no-collapse pin). **The ADR-048
  stop-and-replan branch did NOT fire** — no pin-loosening (#4), no tuning, no Fable (#19). Board T3 checked
  off; active task advanced to **T4** (docs/NEWS/COVERAGE + finish-task gate → PR). Next: `/start-task` T4. Prior
  line: **M38 Task 2 (Cell 2 code — brms incomplete/ragged fixed-nested Design 2) DONE.** Removed the brms incomplete-fixed-nested guard (`R/icc.R` ~800). The path needed no new
  code: `fit_brms_nested_fixed()` (`score ~ 0 + rater + (1|cluster:subject)`) fits ragged data unchanged, and
  `brms_theta2r_nested_draws()` → `brms_theta2r_moment_draws()` already reads a **per-cluster** `k` (nrow of
  each cluster's rater-mean matrix), so unequal k_c and the 2b-under-imbalance moment correction (`b≠0`) +
  boundary-aware average-floor fall out per cluster; the engine-agnostic identifiability gates + pre-dispatch
  k_eff protect the ragged fit. Single + average `ICC_s(·,k)` at the subject level. Live O-Bayes-IFNML-agree
  (`skip_on_ci`) containment test added (verified end-to-end: ragged 72/96, 12 raters; glmmTMB M36 point
  .630/.808 contained in the brms CI); removed two stale "brms incomplete-fixed-nested deferred" assertions +
  updated roxygen. Full suite 1168/0 (51 live-Stan skipped); `air`/`lintr` clean. Board T2 checked off; active
  task advanced to **T3 — the Cell 2 coverage oracle (the ship/stop gate)**. Next: `/start-task` T3. Prior
  line: **M38 Task 1 (Cell 1 — brms cluster-level fixed) DONE.** The brms sibling of M37: removed the brms-specific cluster-drop at `R/icc.R:781`, so balanced brms fixed cluster
  routes through the same engine-agnostic estimand/`posterior_summary()` path as the M24 random cluster level
  (off the shipped `fit_brms_multilevel_fixed()` draws — no new fit), while incomplete brms fixed cluster falls
  to the engine-agnostic balance gate (~`R/icc.R:1187`) and aborts identically to glmmTMB/lme4. O-Bayes-FCL
  (live, `skip_on_ci`: reduction to brms random cluster + glmmTMB M37 containment) + a fast incomplete-boundary
  guard; end-to-end verified (both levels returned, glmmTMB M37 point contained, brms fixed≈random cluster
  |Δ|max .0215 < .06). Fixed one stale "brms fixed cluster deferred" test + the roxygen. Full suite 1170/0 (50
  live-Stan skipped), `air`/`lintr` clean. Board T1 checked off; active task advanced to T2. Next: `/start-task`
  T2 (Cell 2). Prior line: **M38 planned (ADR-048): brms engine parity for the fixed
  multilevel cells — opened on branch `m38-brms-fixed-multilevel-parity`.** After a short retro + a feasibility
  sweep of the remaining (C) corner, the maintainer chose (plan question gate) to wrap up (C) via one milestone
  covering **both** brms parity cells (cluster-level fixed, M37 sibling + incomplete/ragged fixed-nested Design
  2, M36 sibling), with **no Fable pre-authorized** (Cell 2 stop-and-replan on under-coverage). The sweep found
  the ROADMAP's "brms/lavaan siblings … unblockable" wording wrong: the **brms** siblings are cheap parity (a
  guard lift each, glmmTMB oracle to check), but the **lavaan** siblings are **blocked on the multilevel-SEM
  lift** (lavaan multilevel is entirely unsupported) — reclassified as candidates; **incomplete cluster-level
  fixed** stays a 🟣 double-blocked candidate; **Design 3 fixed** is already closed in code (ADR-029 by-design
  abort), removed from the parked list. This commit writes ADR-048, adds the M38 DoD board to MILESTONES (live
  board, ADR-015), advances the MILESTONES preamble + ADR-index (M38 in flight), corrects the ROADMAP (C)
  sequence + the multilevel-SEM cross-reference, and flips STATUS to M38-active. **No code yet — plan before
  code (#14).** Next: `/start-task` Task 1 (Cell 1). Prior line: **M37 shipped (PR #43, squash-merged at
  `f0b29b7`); post-merge `project/` reconcile.** Flipped STATUS to M37-shipped (active milestone none), set
  "Last green CI" to the merge
  commit, compressed the MILESTONES M37 board to summary form (preserving the "Deferred out of M37" list),
  advances the MILESTONES preamble + ADR-index (M37 no longer in flight), and flips the ROADMAP (C)
  cluster-level-fixed entry to "shipped as M37". The whole milestone landed in one session on branch
  `m37-fixed-cluster-level` (plan/ADR-047 → Slice 1 feasibility spike **Outcome A** → Slices 2–3 → finish-task
  gate → PR #43); full CI matrix green 9/9 (devel clean). Fixed-rater cluster-level ICC now ships for balanced
  crossed Design 1 (glmmTMB/lme4), reading `{σ²_c | θ²_r, σ²_cr}` off the shipped M10 fit (no new fit; the
  estimand map keys the cluster error set on `level`); **no Fable review** (the spike confirmed exact reduction
  to the M5 random cluster-level ICC). Local `main` fast-forwarded after the squash, merged branch deleted.
  Next: open the next milestone after a short retro. Prior line: **M37 Slices 2 + 3 DONE — fixed-rater cluster-level ICC ships
  for balanced crossed Design 1 (glmmTMB/lme4).** Slice 2: lifted the `level="cluster"`+`raters="fixed"` abort
  (`R/icc.R`) for balanced crossed Design 1 (two new guards refuse brms and incomplete/unbalanced); the
  cluster-level `{σ²_c | θ²_r, σ²_cr}` reads off the **shipped M10 fit** — no new fit function, since
  `icc_estimand()` keys the cluster error set on `level` not `raters`. Default level now returns **both**
  levels for balanced fixed. Oracles **O-FCL/reduction** (fixed ≡ M5 random cluster point |Δ| 2.1e-6),
  **/lme4** (1.7e-5), **/recovery** (committed `fixed-cluster-level-oracle.rds`: interior coverage .975/.925,
  |bias| ≤ .008; boundary σ²_c=0 **parity** with M5-random — both under-cover identically, the shared
  cluster-signal-zero loss, a candidate follow-up, not an M37 defect). Roxygen/NEWS/COVERAGE/REFERENCES
  in-commit. Slice 3: `multilevel-designs.Rmd` fixed-rater section extended to the cluster level + a
  vignette-claim invariant. Full suite green after fixing **three stale "fixed multilevel = subject only"
  tests** (test-review-fixes ×2, test-icc-brms subject-level containment pins now `level="subject"`);
  `air`/`lintr` clean; brms file re-run 0 failures. Next: finish-task gate → PR. Prior line: **M37 Slice 1
  (feasibility spike) DONE — Outcome A, no Fable.**
  Committed `data-raw/reviews/m37-feasibility-spike-{point,coverage,boundary-parity}.R` (900 + 720 seeded
  glmmTMB fits). Settled the σ²_cr question (M10 §7): fixing the rater main effect does **not** bias the
  `(1|cluster:rater)` interaction (`s2cr_fixed = s2cr_random`, |d| ~ 1e-7), so the **random σ²_cr is the
  correct fixed-rater cluster-level error** — the fixed cluster-level ICC reduces to the shipped M5 random
  cluster-level ICC **exactly** in all regimes (|Δ| ~ 1e-6; θ²_r=σ²_r too). Recovery of a non-circular
  finite-population truth unbiased at C_n=80. The MC interval is at **exact M5 parity** — the σ²_c=0 boundary
  under-covers (0.550) but **identically for fixed and M5-random** (`boundary-parity.R`), a pre-existing
  cluster-signal-zero property, **not an M37 defect** (recorded as a candidate follow-up, spec §7). So M37
  ships as estimand + interval parity with M5 random cluster-level (the M10-subject posture at the cluster
  level): reduction oracle, lme4 cross-engine, seeded recovery — **the pre-authorized Fable review does not
  fire.** STATUS/board updated; Slice 1 checked off; Active task advanced to Slice 2. Next: `/start-task`
  Slice 2 (the estimand + fit path). Prior line: **M37 planned (ADR-047): fixed-rater cluster-level multilevel
  ICC (crossed Design 1, balanced), the last (C) research/blocked corner.** After a short retro + investigation
  that split the ROADMAP's blanket "cluster-level fixed is blocked" into a **parity-shippable balanced cell**
  (reads a new coefficient off the shipped M10 fit — the cluster-level sibling of M10, no new fit) and a
  **genuinely-open incomplete cell** (double-blocked: ten Hove open small-*k* estimator + the M9 §9 open
  `ICC(c,k)` divisor — deferred), the maintainer chose (via the plan question gate): **balanced crossed
  frequentist only** (glmmTMB + lme4), **spike-first structure**, and a **conditional Fable pre-authorization**
  (fires only if the spike shows the balanced fixed≡random cluster-level reduction fails — the σ²_cr
  finite-population treatment). This commit (on branch `m37-fixed-cluster-level`) writes ADR-047, adds the M37
  DoD board to MILESTONES (live board, ADR-015), advances the MILESTONES preamble + ADR-index (M37 in flight),
  adds estimand-spec `M37-fixed-cluster-level.md`, annotates ROADMAP (the (C) cluster-level-fixed corner
  promoted to M37), and flips STATUS to M37-active. **No slice code yet** — plan before code (#14). Next:
  `/start-task` Slice 1 (the feasibility spike). Prior line: **M36 shipped (PR #41, squash-merged at `f5a19e8`); post-merge
  `project/` reconcile.** This commit flips STATUS to M36-shipped, compresses the MILESTONES M36 board to the
  summary form (preserving the "Deferred out of M36" list), advances the MILESTONES preamble (M36 no longer in
  flight), sets "Last green CI" to the merge commit, and flips the ROADMAP (C) entry to "shipped as M36". The
  whole milestone landed in one session on branch `m36-incomplete-fixed-nested` (retro + feasibility spike →
  ADR-046 → Slice 1 → finish-task gate → PR #41); the full CI matrix went green 9/9 with no flakes (devel
  clean). Incomplete/ragged fixed-rater nested Design 2 now ships for glmmTMB/lme4; both single + average
  `ICC_s(·,k)` (average pinned by the exact single-cluster reduction to flat M3 — its divisor is the
  subject-level `k_eff`, not the open per-cluster `ICC(c,k)` divisor); O-IFNML committed (non-circular
  finite-population recovery, coverage interior .967 / boundary θ²=0 .942), no Fable review. Local `main`
  fast-forwarded after the squash, merged branch deleted. Next: open the next milestone after a short retro —
  the remaining (C) corner is cluster-level fixed (research/blocked). Prior line: **M36 opened (ADR-046):
  incomplete/ragged fixed-rater nested (Design 2) — the first (C) research/blocked corner, unblocked by a
  feasibility spike.** After
  the maintainer chose direction (C) and asked whether a simulation oracle could work, a seeded spike
  (`data-raw/reviews/m36-feasibility-spike-{point,coverage}.R`) confirmed the ragged per-cluster Case-3A θ²_{r:c} recovers a non-circular
  finite-population truth (ICC bias ≤ 1%, cross-engine ≤ 5e-5) with nominal 2b interval coverage interior
  (.964) and at the boundary θ²=0 (.960) — parity-shippable, not open research. This commit (on branch
  `m36-incomplete-fixed-nested`) writes ADR-046, adds the M36 DoD board to MILESTONES (live board, ADR-015),
  advances the MILESTONES preamble + ADR-index (M36 in flight), adds estimand-spec
  `M36-incomplete-fixed-nested.md`, annotates ROADMAP (the (C) incomplete-fixed-nested corner promoted), and
  flips STATUS to M36-active. **No slice code yet** — plan before code (#14). Next: `/start-task` Slice 1.
  Prior line: **M35 shipped (PR #40, squash-merged at `d69f39e`); post-merge
  `project/` reconcile.** This commit flips STATUS to M35-shipped, compresses the MILESTONES M35 board to the
  summary form (preserving the "Deferred out of M35" list), advances the MILESTONES preamble + ADR-index (M35
  no longer in flight), sets "Last green CI" to the merge commit, and flips ROADMAP's vignette item to
  "shipped as M35". The whole milestone landed in one session on branch `m35-vignette-reassessment` (retro →
  ADR-045 → S1 stale-claim fixes `61b6ec0` → S2 the split `b8b625b` → S3 brms prose `00e7bab` → finish-task
  gate `54b5246` → PR #40); the full CI matrix went green 9/9 with no flakes (devel clean). Docs milestone —
  no new estimand/engine/CI machinery/dependency; correctness = live-computed + claim-tested numbers plus
  genuine committed brms output; no Fable review. Local `main` fast-forwarded after the squash, merged branch
  deleted. Next: open the next milestone after a short retro. Prior line: **M35 Slice 3 (Bayesian coverage)
  DONE.** Added brms sections to `engines.Rmd` (half-*t*(4,0,1) prior, `engine = "brms"`, the
  M34 `prior=` override + `intraclass_custom_prior` footgun warning) and `interval-methods.Rmd`
  (`ci_method = "posterior"`, MAP + percentile/HPDI `posterior_summary`). All brms chunks are `eval=FALSE`
  illustrative with committed output generated from a **local live rstan run** (genuine, not fabricated, #4);
  each section notes the output is pre-computed (CI has no Stan toolchain). Honest findings preserved (tight
  `normal(0,0.1)` prior → ICC collapses to ~0; brms MAP 0.24 < glmmTMB REML 0.29). Fixed a cross-link anchor
  (`ci_method` underscore, not hyphen); all five inter-article anchors verified; `pkgdown::check_pkgdown()`,
  `air`, spell clean; NEWS vignette bullet updated. Prior line: **M35 Slice 2 (the
  split) DONE.** Retired the 504-line
  `advanced.Rmd` into four self-contained focused articles — `multilevel-designs`, `engines`,
  `interval-methods`, `d-studies-and-replicates` — a mechanical redistribution of the existing prose/live
  chunks (no new capability claims; brms comes in Slice 3). One data-locality call: the multilevel forest plot
  (needs `school`) went to `multilevel-designs`, keeping the two-way plots in `d-studies-and-replicates`; the
  multilevel `choose_icc()` closer went to `multilevel-designs` too. Fixed all cross-links + three external
  refs (README, `choosing-an-icc.Rmd`, the `choose_icc()` runtime note in `R/choose-icc.R`); wired the four
  articles into `_pkgdown.yml`; relabelled `test-vignette-claims.R` per-claim article names; updated the 0.1.0
  NEWS vignette list; added `FIML` to `WORDLIST`. All six articles render self-contained;
  `pkgdown::check_pkgdown()` clean; `test-vignette-claims.R` green; `air`/spell clean. Board S2 items checked
  off; STATUS Active task advanced to Slice 3 (the brms sections). Prior line: **M35 Slice 1 (stale-claim
  fixes) DONE.** Corrected the five
  false "planned for a later milestone" claims in `advanced.Rmd` against `COVERAGE.md` (incomplete fixed
  multilevel → M18; incomplete nested → M19/M32; fixed/multilevel/ragged replicates → M20/M33; lme4
  fixed/multilevel → M14/M15; lavaan fixed / incomplete-FIML → M21); re-audited all three articles (`grep`
  clean of stale "planned/later" phrasing); `test-vignette-claims.R` green, `advanced.Rmd` renders end-to-end.
  Board S1 items checked off; STATUS Active task advanced to Slice 2 (the split). Prior line: **opened M35
  (ADR-045): the vignette-reassessment docs milestone.** After a short retro that triaged all three vignettes
  against the shipped feature set (finding
  `advanced.Rmd` both stale — five false "planned for later" claims — and overloaded, and the entire Bayesian
  arc undocumented), the maintainer chose the parked vignette reassessment and confirmed the **Update + Split**
  shape and the four-article structure. This commit (on branch `m35-vignette-reassessment`) writes ADR-045,
  adds the M35 board to MILESTONES (DoD checklist = live board, ADR-015), advances the MILESTONES preamble +
  ADR-index (M35 in flight), annotates ROADMAP (the vignette item promoted), and flips STATUS to M35-active.
  **No slice code yet** — plan before code (#14). Next: `/start-task` Slice 1 (the stale-claim fixes). Prior
  line: **STATUS.md hygiene: merged the two overlapping
  milestone-history chains into one reverse-chronological list.** The top `- Milestone: **M28**` head had gone
  stale (never advanced as M29–M34 shipped) while a second chain (M34→M30) had been inserted mid-file, and the
  M29 bullet was missing entirely. Fixed: the M34→M30 chain now leads (headed by `Active milestone: none — M34
  shipped`), the old M28 head is demoted to `Prior milestone:`, a backfilled M29 bullet (ADR-039, PR #34,
  `be4e25f`) sits between M30 and M28, and the odd `Prior milestone: none — M31` label is normalized to `M31`.
  Pure STATUS.md reorder + label fixes + the M29 backfill — no other tracking file or code touched; verified
  against `MILESTONES.md` that every M21–M34 status is preserved (all shipped, none in flight) with no
  duplicated or dropped milestones. Prior line: **M34 shipped (PR #39, squash-merged at `3fc133c`); post-merge
  `project/` reconcile.** This commit flips STATUS to M34-shipped, compresses the MILESTONES M34 board to the
  summary form (preserving the "Deferred out of M34" list), advances the MILESTONES preamble + ADR-index (M34
  no longer in flight), sets "Last green CI" to the merge commit, and marks ROADMAP direction (B) shipped
  (detailed scope removed per ADR-015). The whole milestone landed in one session on branch
  `m34-bayes-customization` (retro → ADR-044 → Slice 1 `90d69ad` → Slice 2 `c3a5a45` → finish-task gate
  `8b63f24` → PR #39); the full CI matrix went green 9/9 with no flakes. **The Bayesian customization
  milestone (direction B) is complete** — `icc(prior=)` override (classed footgun warning) + HPDI
  `posterior_summary`, both **reduction oracles** (defaults reproduce shipped M23+ bit-identically), **no
  coverage claim, no Fable review**. The local `R CMD check --as-cran` before the PR caught an over-aggressive
  `posterior_summary` guard (explicit `"percentile"` off-brms should be a no-op; only `"hpdi"` needs the
  posterior path) and an undeclared `coda` (→ `Suggests`), both fixed; the O-PriorReduce "override takes
  effect" assertion was hardened to magnitude-not-sign (the direction is data/seed-dependent). Local `main`
  fast-forwarded after the squash, merged branch deleted. Next: open the next milestone after a short retro —
  remaining brms work is (C) research/blocked (incomplete fixed nested, cluster-level fixed). Prior line:
  **M34 Slice 1 (user `prior=` override).** Added a dedicated `icc(prior=)` argument (default `NULL` = sourced
  half-*t*(4,0,1)); `fit_brms_common()` honours an injected `brm_args$prior`, so no `fit_brms_*` wrapper
  changed; classed `intraclass_custom_prior` footgun warning + three classed guards. O-PriorReduce PASS
  (reduction + bit-identical round-trip + tight-prior move + warning; live `skip_on_ci`). Full suite (CI mode)
  1221/0/20; `air`/`lintr`/spell clean; docs/NEWS/COVERAGE/REFERENCES in-commit (#16). Next: Slice 2 (HPDI
  `posterior_summary`). Prior line below opened the milestone. **M34 opened (ADR-044): the Bayesian
  customization milestone.**
  After a short retro (the Bayesian arc has moved from *discovery* through *mop-up* — M29–M33 all shipped
  without a corrective Fable review; the brms **estimand** surface is now complete) the maintainer chose
  direction **(B)** and confirmed both ADR-time API decisions (Slice 1 = a dedicated top-level `prior=` arg,
  my recommendation over `prior`-in-`brm_args`; Slice 2 = `posterior_summary = c("percentile","hpdi")`). This
  commit (on branch `m34-bayes-customization`) writes ADR-044, adds the M34 active board to MILESTONES (DoD
  checklist = live board, ADR-015), advances the MILESTONES preamble + ADR-index (M34 in flight), annotates
  ROADMAP direction (B) as promoted, and flips STATUS to M34-active. **No slice code yet** — plan before code
  (#14). The oracle character is deliberately different from the parity milestones: a **reduction oracle**
  (defaults reproduce shipped M23+ bit-identically), **not** a coverage claim — arbitrary-prior / HPDI
  coverage is explicitly out-of-oracle, with a classed footgun warning + documented caveats carrying the
  honesty (#4/#18). No new estimand-spec, no new dependency, no coverage unknown → **no Fable review in
  scope**. Next: `/start-task` Slice 1 (the `prior=` override). Prior line: **M33 shipped (PR #38,
  squash-merged at `34cb974`); post-merge
  `project/` reconcile.** This commit flips STATUS to M33-shipped, compresses the MILESTONES M33 board to the
  summary form (preserving the "Deferred out of M33" list), advances the MILESTONES preamble + ADR-index (M33
  no longer in flight), and sets "Last green CI" to the merge commit. The whole milestone landed in one session
  on branch `m33-bayes-parity-mopup` (retro → ADR-043 → Slice 1 → Slice 2 → Slice 3 → finish-task gate → PR
  #38); the full CI matrix went green 9/9 with no flakes. **The Bayesian parity mop-up (direction A) is
  complete** — `engine = "brms"` now covers every clean-oracle estimand gap: incomplete single-level one-way,
  fixed-rater within-cell replicates, and multilevel within-cell replicates (crossed D1 + nested D2). Each
  slice was a shipped frequentist coefficient read off posterior draws (parity, not new estimand work); the
  gate (every corner has a frequentist oracle) was verified before the ADR. **Every oracle came back nominal**
  (O-Bayes-IOneway .9458, O-Bayes-FRep .9625, O-Bayes-MLRep .95–.9625, full glmmTMB containment) — **no Fable
  review anywhere**, the M30 variance-ratio regime held as predicted. Local `main` fast-forwarded after the
  squash, merged branch deleted. Next: open the next milestone after a short retro — recorded next-up is (B)
  the Bayesian customization milestone (`prior=` API + HPDI). Prior line: **M33 opened (ADR-043): the Bayesian
  parity mop-up.** After a
  short retro (the arc has moved from *discovery* into *mop-up* — M29–M32 all shipped without a corrective
  Fable review; M32's one gated review resolved to a no-shortfall tail event) the maintainer chose direction
  **(A)** and confirmed **all three corners in one milestone**. This commit (on branch
  `m33-bayes-parity-mopup`) writes ADR-043, adds the M33 active board to MILESTONES (DoD checklist = live
  board, ADR-015), advances the MILESTONES preamble + ADR-index (M33 in flight), annotates ROADMAP direction
  (A) as promoted, and flips STATUS to M33-active. **No slice code yet** — plan before code (#14). The gate
  was verified before the ADR (#1): every corner has a frequentist oracle (glmmTMB/lme4 incomplete one-way =
  M6 + M3 `k_eff`; M20 S1 fixed / S2 multilevel replicates), so all three ship as parity, not research — the
  key scoping difference from M32's incomplete-fixed-nested carve-out. Only Slice 1 (ragged one-way) carries
  a genuine unknown (coverage), and a Fable review is conditional-and-recommend-only there (#19). Next:
  `/start-task` Slice 1. Prior line: **M32 shipped (PR #37, squash-merged at `dd8e3e2`); post-merge
  `project/` reconcile.** This commit flips STATUS to M32-shipped, compresses the MILESTONES M32 board to the
  summary form (preserving the "Deferred out of M32" list and the Fable-review record), advances the MILESTONES
  preamble + ADR-index (M32 no longer in flight), and sets "Last green CI" to the merge commit. The whole
  milestone landed in one session on branch `m32-bayes-incomplete-nested` (retro → ADR-042 → Slice 1 → Slice 2
  → the gated Fable review → PR #37); the full CI matrix went green 9/9. **The milestone's substance was its
  one gated Fable review** (#19): Slice 2 (incomplete nested Design 3, the multilevel one-way) drew a .8625
  ragged coverage cell at n_rep 80 — below the ≥ .88 pin. The pin was NOT loosened (#4), Fable NOT
  auto-invoked; the finding was characterized honestly (#18) and a gated Fable review recommended/approved.
  **Verdict (ADR-042 Amendment 2): a Monte-Carlo tail event (P ≈ .002), no estimator shortfall** — Fable
  re-ran the same incidence at n=240 → .9458, plus a 2,000-fit frequentist cross-check (.9555) and a uniform
  PIT (calibrated). Adopted in full: ship Slice 2 unchanged, regenerate the fixture at n_rep 240 + per-rep
  seeding (pins unchanged; .9375/.9417), and adopt n_rep ≥ 240 for future ragged coverage cells (the ≥ .88 pin
  false-alarms ~0.7%/cell at n_rep 80). Slice 1 (Design 2) was nominal throughout. Local `main` fast-forwarded
  after the squash, merged branch deleted. Next: open the next milestone after a short retro, or the CRAN
  upload (ADR-022). Prior line: **M31 shipped (PR #36, squash-merged at `5d6848e`); post-merge `project/`
  reconcile.** This commit flips STATUS to M31-shipped, compresses the MILESTONES M31 board to the
  summary form (preserving the Deferred-out-of-M31 list), advances the MILESTONES preamble + ADR-index (M31 no
  longer in flight), and sets "Last green CI" to the merge commit. The whole milestone (retro → ADR-041 →
  Slice 1 → Slice 2 → finish-task gate → PR #36) landed in one session on branch `m31-bayes-incomplete-fixed`;
  the full CI matrix went green after a one-job lint re-run (camelCase test locals `Nc`/`Ns` → snake_case;
  the earlier per-file `lintr::lint()` missed them — [[run-lintr-before-push]] reinforced). Local `main`
  fast-forwarded after the squash, merged branch deleted. **The milestone's one unknown — ragged fixed-rater
  credible coverage once the 2b θ² moment correction goes live single-level — resolved NOMINAL for both
  slices** → no Fable review. Next: open the next milestone after a short retro, or the CRAN upload (ADR-022).
  Prior line: **M30 shipped (PR #35, squash-merged at `9d2f0ed`).** Earlier this session (superseded by the
  reconcile above): **M31 opened (ADR-041) + BOTH slices shipped.**
  Slice 2 (incomplete crossed Design-1 fixed multilevel, subject level): removed the
  `(raters == "fixed" && multilevel)` clause of the `!balanced` brms guard so ragged crossed fixed dispatches
  to `fit_brms_multilevel_fixed()` (nested stays refused via `ml_design != "crossed"`); subject level only.
  O-Bayes-IFML-fixed coverage NOMINAL (ragged .91/.91 vs complete .95/.95, within MC error, SE≈.022) → no Fable
  review; live glmmTMB M18 Slice 1 containment (0.594/0.835 inside the CIs). Fixture
  `bayesian-incomplete-fixed-ml-oracle.rds` (seed 31200, n_rep 100) + `data-raw/oracle-bayesian-incomplete-fixed-multilevel.R`.
  Below: **M31 Slice 1 shipped, in one session.**
  After a short retro the maintainer chose the incomplete/ragged **fixed-rater** Bayesian path (the first
  sibling ADR-040 deferred), then approved going straight into Slice 1. On branch `m31-bayes-incomplete-fixed`:
  ADR-041 written, M31 board added to MILESTONES (DoD = live board, ADR-015), preamble + ADR-index updated,
  STATUS flipped. **Slice 1 (incomplete two-way fixed, single level) DONE:** narrowed the `!balanced` brms
  guard (`icc.R:1128`, `raters == "fixed"` → `(raters == "fixed" && multilevel)`) so single-level ragged fixed
  dispatches to `fit_brms_fixed()` — **no new fit, no new θ² helper** (`brms_theta2r_draws()` /
  `brms_theta2r_moment_draws()` ship); the 2b moment correction goes live single-level for the first time on
  ragged data (`b ≠ 0`). **The one unknown resolved NOMINAL:** O-Bayes-IFixed ragged coverage .965/.965 tracks
  complete .955/.955 (k_eff 3.85, conv 1.00, MAP biased low) → **no Fable review**. Committed fixture
  `bayesian-incomplete-fixed-oracle.rds` + `data-raw/oracle-bayesian-incomplete-fixed.R` (drives the shipped
  path, 400 seeded fits); live O-Bayes-IFixed-agree glmmTMB containment verified; roxygen/NEWS/COVERAGE/
  REFERENCES updated in-commit (#16); `air` clean. Next: **Slice 2** (incomplete crossed Design-1 fixed
  multilevel, subject level) — narrow the multilevel guard clause, `fit_brms_multilevel_fixed()` on ragged
  data, O-Bayes-IFML-fixed. Prior line: **M30 shipped (PR #35, squash-merged at `9d2f0ed`); post-merge
  `project/` reconcile.** Flipped STATUS to M30-shipped,
  compressed the MILESTONES M30 board, reconciled ROADMAP; whole milestone landed in one session on branch
  `m30-bayes-incomplete`. Both slices narrowed the one `!balanced` brms guard — no new fit — with committed
  O-Bayes-Incomplete / O-Bayes-IML coverage fixtures + live -agree fits; the one unknown (ragged credible
  coverage through `k_eff`) came back **NOMINAL** at the subject level for both → no Fable review. Gates: full
  CI matrix green 9/9; `R CMD check --as-cran` 0/0/1; suite (CI mode) 1030/0. After a short retro the maintainer chose to continue the Bayesian arc with the
  incomplete/ragged random path (both single-level and crossed-multilevel slices). This commit (on branch
  `m30-bayes-incomplete`) writes ADR-040, adds the M30 active board to MILESTONES (DoD checklist = live
  board, ADR-015), updates the MILESTONES preamble + ADR-index (ADR-040 M30), and flips STATUS to
  M30-active. **No slice code yet** — plan approved before code (#14). The scope is deliberately
  random-only (no θ² functional → no 2b correction) so the one unknown — ragged-data credible-interval
  coverage — is isolated; a gated Fable review is conditional (recommend-and-stop only if the seeded
  coverage oracle undercovers, #19). Next: `/start-task` Slice 1 (narrow the `!balanced` brms guard, confirm
  `k_eff` per-draw threading, build O-Bayes-Incomplete). Prior line: **M29 shipped (PR #34, squash-merged at
  `be4e25f`); post-merge `project/` reconcile.**

## Where we are

**Support matrix** — [`COVERAGE.md`](COVERAGE.md) is the current-state stock-take of
what the `icc()` / `d_study()` argument space supports today, with a reason category
(not yet / research / blocked / by design) for every gap. Derived, not authoritative;
refresh it when a milestone ships.

**Shipped M0–M15** — see [`MILESTONES.md`](MILESTONES.md) for the record (single
source; not restated here, ADR-015). In short: the classic Shrout–Fleiss ICC family
is complete; glmmTMB, lme4, and lavaan are selectable engines through the M5.5 engine ×
design dispatch seam, and **lme4 now has full design parity with glmmTMB — two-way
random/fixed, one-way, and every multilevel design, on both balanced (M14) and
incomplete/ragged (M15) data** (degrading to glmmTMB only at the variance boundary);
the multilevel
estimator covers ten Hove et al. (2022) Designs
1–3 (crossed + both nested-rater); the crossed design handles **incomplete (ragged)**
data (subject level + cluster-level `ICC(c,1)`) with a declared-`design` disambiguation
and oracle-pinned identifiability guards (M9); and the crossed design also supports
**fixed raters** at the subject level, balanced (M10). The multilevel family is now
crossed × {complete, incomplete} × {random, fixed} at the subject level. Every fitted
`icc` object now has `autoplot()`/`plot()` methods — a coefficient forest plot and a
variance-component decomposition (M11). And `choose_icc()` turns the *Choosing an ICC*
decision tree into an interactive/programmatic helper that recommends a coefficient and
emits the exact `icc()` call — teaching/API, no new estimand (M12). And release polish
brought the pkgdown site, the M9–M12 showcase in the advanced vignette (retired and split
into four focused articles in M35), and a **CRAN-submittable v0.1.0** (`--as-cran` 0/0/0),
closing the ADR-017 arc (M13).

## Next action

**No milestone is currently in flight — the next needs an ADR after a short retro (founding brief §7).**
M37 (ADR-047, fixed-rater cluster-level ICC, crossed Design 1, balanced) shipped (PR #43, `f0b29b7`): the last
parked **(C) research/blocked** corner now ships for glmmTMB/lme4, reading `{σ²_c | θ²_r, σ²_cr}` off the
shipped M10 fit (no new fit; the estimand map keys the cluster error set on `level`). A feasibility spike
settled the σ²_cr question — fixing raters doesn't bias the interaction, so the coefficient reduces to the M5
random cluster-level ICC exactly (**Outcome A, no Fable**). Pick a direction from the parked candidates
(below / `ROADMAP.md`), run a short retro, and open the next milestone with an ADR. Remaining (C) work is all
deferred/engine-parity: **incomplete** cluster-level fixed (🟣 double-blocked — ten Hove open small-*k* + the
M9 §9 `ICC(c,k)` divisor); the **brms/lavaan** cluster-level-fixed siblings (engine parity, now unblockable);
and improving cluster-signal-zero (σ²_c→0) interval coverage (cross-cutting M5/M9/M37).

**Deferred / candidates —** With
M34 the Bayesian arc's *parity* (M23–M33) and *customization* (M34) are both complete. Remaining brms work is
**(C) research/blocked** only: incomplete **fixed** nested (Designs 2/3 — needs the frequentist
incomplete-fixed-nested estimand built first) and **cluster-level fixed** (ten Hove et al. 2022 flag the
best small-*k* estimator as an open question) — both would lean on coverage calibration, likely a Fable
review (#19). Other parked candidates in [`ROADMAP.md`](ROADMAP.md): **selectable `posterior` coupling**
(MC/bootstrap on a Bayesian fit), **categorical/ordinal GLMM** (needs an estimand pass), **multilevel SEM**,
the Wave-3 `ICC(c,k)` incomplete divisor, occasion/ragged `d_study()`, the **vignette reassessment** (docs),
and the out-of-band **CRAN upload** (ADR-022). Pick a direction, run a short retro, and open the next
milestone with an ADR.

**M34 (ADR-044) shipped (PR #39) — Bayesian engine (brms) customization: user `prior=` override + HPDI
credible intervals.** Interface/customization work, **not** new estimand (cf. M5.5/M7/M11/M16 — no
estimand-spec); two additive, non-breaking optional args whose defaults reproduce shipped M23+ results
**bit-identically**, each a **reduction oracle** (no coverage claim, no Fable review). **Slice 1** —
`icc(prior = NULL)` (brms-only) threaded through `fit_brms_common()` via an injected `brm_args$prior` (no
`fit_brms_*` wrapper changes), classed `intraclass_custom_prior` footgun warning; O-PriorReduce. **Slice 2** —
`posterior_summary = c("percentile","hpdi")` (default percentile) under `ci_method = "posterior"`;
dependency-free `hpdi_interval()` (≡ `coda::HPDinterval`), `(HPDI)` header label; O-HPDI. `coda` → `Suggests`
(no new `Imports`). `R CMD check --as-cran` 0/0/1; full CI matrix green 9/9.

**M33 (ADR-043) shipped (PR #38) — Bayesian engine (brms) parity mop-up: incomplete single-level one-way +
fixed-rater & multilevel within-cell replicates.** `engine = "brms"` now covers the last clean-oracle
estimand gaps: **Slice 1** incomplete/ragged single-level **one-way** (`fit_brms_oneway()` reused, narrowed
the `!balanced` guard's `oneway` clause; O-Bayes-IOneway coverage ragged .9458/.9458, n_rep 240); **Slice 2**
**fixed-rater** within-cell replicates (new `fit_brms_replicates_fixed()`, θ²_r per draw, 2b ≈ 0 on balanced
data → θ²_r = σ²_r; O-Bayes-FRep .9625/.9625, containment 1.00); **Slice 3** **multilevel** replicates (new
`fit_brms_ml_replicates()` crossed D1 + `fit_brms_nested_replicates()` nested D2; O-Bayes-MLRep crossed
.9500/.9500, nested .9625/.9500, containment 1.00). **Engine/interval parity, not new estimand work** (#6):
no new estimand-spec/argument/dependency. The gate was met before the ADR — every corner has a frequentist
oracle (glmmTMB/lme4 incomplete one-way = M6 + M3 `k_eff`; M20 S1 fixed; M20 S2 multilevel) — so all three
shipped as parity, not research. **Every oracle nominal — no Fable review anywhere** (the M30 variance-ratio
regime held). `R CMD check --as-cran` 0/0/1; full CI matrix green 9/9. **No milestone is currently in
flight** — the next needs an ADR after a short retro (founding brief §7). Recorded next-up is **(B) the
Bayesian customization milestone** (`prior=` API + HPDI intervals); then **(C) research/blocked** (incomplete
fixed nested, cluster-level fixed). Other parked candidates in [`ROADMAP.md`](ROADMAP.md): categorical/ordinal
GLMM, multilevel SEM, Wave-3 `ICC(c,k)`, occasion/ragged `d_study()`, the vignette reassessment, and the
out-of-band CRAN upload (ADR-022).

**M32 (ADR-042) shipped (PR #37) — Bayesian engine (brms) incomplete/ragged NESTED random, Designs 2 & 3,
subject level.** `engine = "brms"` now fits incomplete/ragged **nested random**-rater ICCs at the subject
level for both designs — Design 2 (`fit_brms_nested_clusters`, Slice 1) and Design 3
(`fit_brms_nested_subjects`, the multilevel one-way, Slice 2) — the Bayesian sibling of the frequentist M19,
completing the "brms × incomplete × random" row. Both slices narrowed the same `!balanced` brms guard's
`ml_design != "crossed"` clause; no new fit, no θ² helper (random → variance ratios, no 2b, the M30 regime).
**Scoped RANDOM-only by an oracle-first catch** (incomplete *fixed* nested has no frequentist oracle,
ADR-029). Slice 1 (Design 2) ragged coverage **NOMINAL** (.925/.925). **Slice 2 (Design 3) triggered the
milestone's one gated Fable review** (#19): the first n_rep-80 ragged coverage cell drew **.8625** (below the
≥ .88 pin) — the pin was NOT loosened (#4), Fable NOT auto-invoked, the finding characterized honestly (#18).
**Fable verdict (ADR-042 Amendment 2): a Monte-Carlo tail event (P ≈ .002), no estimator shortfall** — same
incidence at n=240 → .9458, four fresh incidences → .9500, a 2,000-fit frequentist arm → .9555, PIT uniform
(calibrated). Adopted: ship unchanged, regenerate the fixture at **n_rep = 240 + per-rep seeding** (pins
unchanged; .9375/.9417), and **adopt n_rep ≥ 240 for future ragged coverage cells**. `R CMD check --as-cran`
0/0/0; full CI matrix green 9/9. **No milestone is currently in flight** — the next needs an ADR after a short
retro (founding brief §7). Candidates stay parked in [`ROADMAP.md`](ROADMAP.md): Bayesian incomplete **fixed**
nested (research, no oracle) / **cluster-level** / **replicates** / single-level **one-way**;
**categorical/ordinal GLMM** (needs an estimand pass); **multilevel SEM**; the Wave-3 `ICC(c,k)` divisor;
occasion/ragged `d_study()`; the **vignette reassessment**; and the out-of-band **CRAN upload** (ADR-022).
Arc history: M18–M21 (PR #23–#26); M22 (PR #27), M23 (PR #28), M24 (PR #29), M25 (PR #30), M26 (PR #31),
M27 (PR #32), M28 (PR #33), M29 (PR #34), M30 (PR #35), M31 (PR #36), M32 (PR #37).

**Arc — M18→M21, mixed-model completeness first, SEM last (ADR-027) — ALL SHIPPED:**

- **M18 — Multilevel completeness I (crossed, incomplete):** ✅ shipped (PR #23).
- **M19 — Multilevel completeness II (nested Designs 2/3):** ✅ shipped (PR #24) — incomplete
  nested + fixed-rater nested Design 2.
- **M20 — Within-cell replicate completeness:** ✅ shipped (PR #25) — fixed-rater · multilevel
  (crossed D1 + nested D2) · ragged single-occasion replicates. Occasion-averaged-ragged degraded
  to 🟣 research (no validated effective-`n_o` divisor). Extends M17 Slice 3.
- **M21 — SEM (lavaan) engine parity:** ✅ shipped (PR #26, ADR-031) — lavaan bootstrap, fixed-rater
  (Case-3A θ²_r), incomplete/FIML (ships, no degrade). The lavaan analog of the lme4 M5.5→M15 arc.

**Reclassified out of the arc (ADR-027):** multilevel SEM → cross-cutting "later" bucket
(research-flavored, sits beside Bayesian); lavaan + replicates → ROADMAP unscheduled (niche).

**Still to sequence (excluded from the M18–M21 arc, later):**

- **Wave 3 (research):** **M9 averaged cluster-level `ICC(c,k)` on incomplete data** (open
  per-cluster divisor — a focused simulation-oracle study, likely a Fable review). *Bounds
  M18 Slice 3 to the subject level.*
- **Cross-cutting, later:** the **Bayesian engine** two-way random path + `ci_method =
  "posterior"` **shipped as M23** (ADR-033, PR #28); its parity follow-ons (Bayesian
  fixed/one-way/**multilevel**/incomplete/replicates) remain later — multilevel is the
  highest-value (ten Hove's native turf). **categorical/ordinal GLMM ratings**; **multilevel
  SEM**; non-parametric/profile-likelihood CIs; boundary-robust lme4 singular-fit + merDeriv
  edge cases (glmmTMB covers these today).
- **Blocked, stays parked:** one-way / general ICC(1) via SEM — no faithful sourced route
  (ADR-014); not schedulable until a source appears.

**CRAN submission (out of band, ADR-022).** See below.

**Out-of-band thread (unchanged): CRAN submission (ADR-022).** The package is
submission-ready. A max-effort code review of the statistical core (2026-07-07)
verified the estimand/CI/engine math is correct and fixed 12 edge-guard / validation /
robustness findings (PR #20, merged `cae1c33`; regression tests in
`test-review-fixes.R`). Before uploading, run **win-builder** (R-devel + release) and
**R-hub**, then update the "will be run immediately before submission" line in
`cran-comments.md` with the results. `intraclass` does not (and cannot) submit for you.
*(Note: M14 — and now M15 — fold their changes into the existing `0.1.0` NEWS section
rather than bumping to a dev version, on the basis that 0.1.0 has not yet been uploaded
— revisit if 0.1.0 is frozen for submission.)*

The full carryover inventory (Bayesian + non-Bayesian, sourced vs. blocked) lives in the
parking lot in [`ROADMAP.md`](ROADMAP.md); the near-term ordering of the non-Bayesian
items is the sequencing plan above.

Workflow: milestone work ships on a `m<N>-<slug>` branch and merges via PR
(`milestone-branches-and-prs` memory); post-merge `project/` reconciles are a
direct commit to `main` (finish-task policy — no CI job reads `project/`).
