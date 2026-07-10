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
- Active milestone: **M31 — Bayesian engine (brms) incomplete/ragged FIXED-rater, two-way single level +
  crossed Design-1 multilevel** — **ACTIVE** (ADR-041; branch `m31-bayes-incomplete-fixed`; **plan approved,
  no slice code yet**). The first deferred sibling ADR-040 named — the Bayesian sibling of the frequentist
  **M3** (single-level fixed θ²_r under imbalance) / **M18 Slice 1** (fixed crossed multilevel). **Engine/
  interval parity, not new estimand work** (#6): reuses the shipped M3 `theta2r_fixed()` + `k_eff` and the M18
  fixed path, read off posterior draws; **no new fit** (`fit_brms_fixed()` / `fit_brms_multilevel_fixed()` run
  on ragged data unchanged), **no new θ² helper** (`brms_theta2r_moment_draws()` ships), no new argument/
  dependency — narrows the same `!balanced` brms guard M30 touched (`icc.R:1128`). **The genuine risk (why the
  fixed corner was held back from the random-only M30):** on ragged data the fixed rater means come from
  unequal cell counts, so `b = tr(C·Σ_post)/(k−1) ≠ 0` **for the first time in the single-level regime** — the
  2b moment correction goes live where it has never been exercised (balanced single-level/crossed had `b ≈ 0`).
  The one unknown is empirical: does the percentile credible interval still cover nominally? A gated Fable
  review is **conditional** (#19) — recommend-and-stop only if the seeded ragged coverage oracle undercovers.
  Slices ordered by oracle-risk: **Slice 1** incomplete two-way fixed (single level), **Slice 2** incomplete
  crossed (Design 1) fixed multilevel (subject level). The M31 DoD board is the live task list
  ([`MILESTONES.md`](MILESTONES.md), ADR-015).
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
- Active task: **M31 — both slices DONE; cross-cutting DoD + finish-task/PR pending.** **Slice 1**
  (incomplete two-way fixed, single level, committed `91f0502`): guard narrowed so single-level ragged fixed
  dispatches to `fit_brms_fixed()`; O-Bayes-IFixed coverage **NOMINAL** (ragged .965/.965 vs complete
  .955/.955); live glmmTMB M3 containment (0.450 vs 0.448, 0.734 vs 0.722). **Slice 2** (incomplete crossed
  Design-1 fixed multilevel, subject level): removed the `(raters == "fixed" && multilevel)` guard clause so
  ragged crossed fixed dispatches to `fit_brms_multilevel_fixed()` (nested stays refused via
  `ml_design != "crossed"`); subject level only (fixed cluster-level IRR deferred all engines). O-Bayes-IFML-fixed
  coverage **NOMINAL** (ragged .91/.91 tracks complete .95/.95 within MC error, SE≈.022; conv .94/.98) →
  **no Fable review**; live glmmTMB M18 containment (0.594 in [0.381, 0.763], 0.835 in [0.681, 0.918]).
  Committed fixtures `bayesian-incomplete-fixed{,-ml}-oracle.rds` + `data-raw/oracle-bayesian-incomplete-fixed{,-multilevel}.R`.
  **No new fit, no new θ² helper (`brms_theta2r_moment_draws()` ships), no new argument/dependency** (#6).
  Tracking (ADR-041, MILESTONES board both slices checked, REFERENCES O-Bayes-IFixed/-IFML-fixed, NEWS,
  COVERAGE, ROADMAP) updated in-commit (#16). **Full local gate GREEN:** `R CMD check --as-cran` 0/0/0
  (spelling "undercovered" whitelisted); `devtools::test()` 0 failures (all live Stan fits ran);
  installed-pkg both ragged fixed fits verified (glmmTMB M3/M18 containment); `air`/`lintr` clean. **Next:
  push branch + open PR; on green CI + merge, reconcile "Last green CI" and compress the M31 board.** Other
  candidates remain
  parked in [`ROADMAP.md`](ROADMAP.md): Bayesian **nested** fixed / replicate / cluster-fixed incomplete
  corners, **categorical/ordinal GLMM** (needs an estimand pass), **multilevel SEM**, the Wave-3 `ICC(c,k)`
  divisor, occasion/ragged `d_study()`, the **vignette reassessment** (docs), and the out-of-band **CRAN
  upload** (ADR-022).
- Last green CI: **PR #35 (M30) — full CI matrix green (9/9), squash-merged to `main` at `9d2f0ed`.**
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed. Locally before the PR: `R CMD check --as-cran` **0/0/1** (New
  submission only); installed-pkg both new ragged fits driven through `library(intraclass)` (posterior CI,
  glmmTMB M3/M9 containment, ICC(c,k) dropped); full suite (CI mode) **1030/0/40**; `air`/`lintr` clean. Prior
  green: **PR #34 (M29)** at `be4e25f`.
  format-check / lint / pkgdown / test-coverage / `R CMD check` on macOS, Windows, and Ubuntu
  release·oldrel·**devel** all passed. Locally before the PR: `R CMD check --as-cran` **0/0/1** (full
  build, only "New submission"); installed `test-icc-brms.R` `NOT_CRAN=true` **266/0/0** (all live Stan
  fits ran, incl. O-Bayes-Conflated-agree + O-Bayes-Rep-agree); full suite (CI mode) **1089/0/10**;
  `lintr`/`air` clean; coverage ~85% (below 90% by design — [[coverage-baseline]]). Prior green: **PR #33
  (M28)** at `e6ce64d`.
- Blockers: —
- Updated: 2026-07-10 by main session (Opus) — **M31 opened (ADR-041) + BOTH slices shipped, in one session.**
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

**M31 (ADR-041) ACTIVE — both slices DONE; cross-cutting DoD + finish-task/PR next.** `engine = "brms"` +
`raters = "fixed"` now fits incomplete/ragged data at the **two-way single level** (Slice 1, `fit_brms_fixed`,
committed `91f0502`) and the **crossed (Design 1) fixed multilevel subject level** (Slice 2,
`fit_brms_multilevel_fixed`). Both were narrowings of the one `!balanced` brms guard (`icc.R:1128`) — **no new
fit, no new θ² helper** (`brms_theta2r_draws()` / `brms_theta2r_moment_draws()` ship), no new
argument/dependency (#6). The milestone's genuine risk — the **2b θ² moment correction going live for the
first time on ragged fixed data** (`b ≠ 0`) — resolved **NOMINAL** for both: O-Bayes-IFixed ragged .965/.965
vs complete .955/.955; O-Bayes-IFML-fixed ragged .91/.91 vs complete .95/.95 (within MC error) → **no Fable
review** (ADR-041's conditional escalation not triggered). Live -agree containment verified against glmmTMB
M3 (single) / M18 Slice 1 (multilevel). Committed fixtures + seeded `data-raw` scripts; tracking in-commit
(#16); `air`/`lintr` clean. **Next: cross-cutting DoD** — installed-pkg both ragged fixed fits with
`NOT_CRAN=true`, `R CMD check --as-cran`, full suite, `_pkgdown.yml` no-op — then `/finish-task` and the PR.
Other candidates stay parked in [`ROADMAP.md`](ROADMAP.md): Bayesian **nested** fixed / replicate /
cluster-fixed incomplete corners, **categorical/ordinal GLMM** (needs an estimand pass), **multilevel SEM**,
the Wave-3 `ICC(c,k)` divisor, occasion/ragged `d_study()`, the **vignette reassessment**, and the
out-of-band **CRAN upload** (ADR-022). Arc history: M18–M21 (PR #23–#26); M22 (PR #27), M23 (PR #28), M24
(PR #29), M25 (PR #30), M26 (PR #31), M27 (PR #32), M28 (PR #33), M29 (PR #34), M30 (PR #35); M31 in flight.

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
