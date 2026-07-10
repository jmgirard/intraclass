# Project status

- Milestone: **M28 — Frequentist nested-fixed MC-interval coverage** — **shipped** (PR #33, ADR-038;
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
- Active milestone: **none** — M32 shipped (PR #37, ADR-042; squash-merged to `main` at `dd8e3e2`).
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
- Prior milestone: **none** — M31 shipped (PR #36, ADR-041; squash-merged to `main` at `5d6848e`).
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
- Active task: **none** — M32 shipped and merged (PR #37, `dd8e3e2`). The next milestone needs an ADR after a
  short retro (founding brief §7). Candidates parked in [`ROADMAP.md`](ROADMAP.md): the remaining **Bayesian
  follow-ons** — incomplete **fixed** nested
  (no frequentist oracle — research), Bayesian **replicates**/**cluster-fixed**/**one-way** incomplete,
  **categorical/ordinal GLMM** (needs an estimand pass), **multilevel SEM**, the Wave-3 `ICC(c,k)` divisor,
  occasion/ragged `d_study()`, the **vignette reassessment** (docs), and the out-of-band **CRAN upload**.
- Last green CI: **PR #37 (M32) — full CI matrix green (9/9), squash-merged to `main` at `dd8e3e2`.**
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
- Blockers: **— (cleared 2026-07-10).** The M32 Slice 2 ragged-Design-3 undercoverage finding
  (`.8625` at n_rep 80) went to a gated Fable review (#19) → **VERDICT: no shortfall, a Monte-Carlo tail
  event that does not replicate** (Fable re-ran the same incidence at n=240 → .9458; 2,000-fit frequentist
  arm → .9555; PIT uniform). Adopted in full (ADR-042 Amendment 2): **ship Slice 2 unchanged**, regenerate
  the fixture at n_rep=240 + per-rep seeding (pins unchanged, ragged ≥ .88 not loosened). **Regeneration
  DONE — verdict confirmed:** complete .9375/.9375, ragged .9417/.9417 (both ∈ the pre-registered [.92, .975];
  the .8625 tail did not recur — same incidence now .9417); all pins pass. Brief + response:
  [`fable-brief-m32-s2.md`](fable-brief-m32-s2.md) / `data-raw/reviews/fable-review-m32-s2-response.md`. Slice 2 code/oracle/fixture/tests are **staged in the working tree, UNCOMMITTED**
  (the coverage test asserts ≥ .88 and fails on the committed-evidence fixture — the honest signal, not
  loosened). Slice 1 (Design 2) is shipped/committed (7b8b60c) and unaffected.
- Updated: 2026-07-10 by main session (Opus) — **M32 shipped (PR #37, squash-merged at `dd8e3e2`); post-merge
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
brought the pkgdown site, the M9–M12 showcase in `advanced.Rmd`, and a **CRAN-submittable
v0.1.0** (`--as-cran` 0/0/0), closing the ADR-017 arc (M13).

## Next action

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
