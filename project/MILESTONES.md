# Milestones

Ordered milestones with status and the deferrals each one recorded. **Shipped
milestones are compressed** to Goal / Status / Deferred + spec-and-ADR pointers — the
full blow-by-blow DoD (slices, oracle-by-oracle detail) lives in its ADR
(`DECISIONS.md`), its estimand-spec, and git history (ADR-015, single-source; don't
restate it here). **No milestone is in flight** — the next one is scoped by an ADR at
its start after a short retro (founding brief §7) and detailed in full here until it
ships. The arc is a hypothesis, not a contract — reorders get a
[`DECISIONS.md`](DECISIONS.md) entry (the M9–M13 tail was set by ADR-017; ADR-018
detailed M9, ADR-019 M10, ADR-020 M11, ADR-021 M12, ADR-023 M14, ADR-024 M15,
ADR-025 M16, ADR-026 M17).

Definition of Done references are to `CLAUDE_CODE_KICKOFF.md` §8.

**This file is also the task board (ADR-015).** The **active** milestone's DoD
checklist *is* the live board — check items off here, in the same commit as the work
(#16). When a milestone ships (checklist fully checked + merged), it is compressed to
the summary form below, **preserving its "Deferred out of M<n>" list verbatim** (that
list is load-bearing — it stops deferred work being rediscovered). There is no
separate `TASKS.md`; `STATUS.md` names the active task and *points* here.

---

## M0: Scaffolding
- Goal: a green, well-tracked, empty-but-real package others can build on — skeleton
  (`DESCRIPTION`/`NAMESPACE`/`R/` + `abort` layer, MIT license, README/NEWS), the
  `project/` tracking system, `.claude/` skills + `doc-polisher` agent, the CI matrix
  (check/coverage/lint/pkgdown/scheduled reference-values), the air formatter
  (ADR-004), and a stub pkgdown site.
- Status: done (commit 0d81e34, pushed, CI green).

## M1: Two-way random, absolute agreement — `ICC(A,1)` / `ICC(A,k)`
- Goal: one estimator working end-to-end (fit → estimate → MC CI → print/tidy →
  tested → documented → CI green), proving the whole pipeline before widening.
  ICC(A,1) = σ²_s/(σ²_s+σ²_r+σ²_res); ICC(A,k) averages the error over k. glmmTMB
  engine (lme4 oracle-only, ADR-005); boundary-aware Monte-Carlo CIs (ADR-003); five
  oracles (SF 0.290/0.620, `psych`, ANOVA mean-squares, seeded sim, lme4 cross-check).
- Estimand: [`estimand-specs/M1-twoway-random-agreement.md`](estimand-specs/M1-twoway-random-agreement.md);
  API/representation in ADR-005.
- Status: done (code 77e8ab0, marked done 37f59c0; full CI matrix green).

## M2: Consistency variants + fixed-vs-random raters
- Goal: add `ICC(C,1)`/`ICC(C,k)` and a `raters = random|fixed` dimension —
  **no new fit, no new CI machinery**, balanced only. Consistency drops the rater
  main effect from the error set; fixed-vs-random is a balanced-data label layer over
  the shared random-effects fit (ADR-006). Oracles SF 0.715/0.909, `psych` ICC3/ICC3k,
  fixed≡random point/CI equivalence (O4).
- Estimand: [`estimand-specs/M2-consistency-and-fixed.md`](estimand-specs/M2-consistency-and-fixed.md);
  ADR-006.
- Deferred to their own slices (not M2): lme4 as a *selectable* engine + bootstrap
  CI (supersedes ADR-005's "defer to M2"); D-study projection to arbitrary k.
- Status: done (merged via PR #1 at 334a48a; full CI matrix green).

## M3: Imbalanced & incomplete designs
- Goal: correct ICCs from the mixed model on **ragged** subject×rater designs
  (missing cells) — the package's core differentiator — and resolve the ADR-006
  fixed-raters debt with a **real fixed-effect fit path**. Statistical core only (the
  flagship vignette split to M4, ADR-007). Connectedness guard + `k_eff` harmonic-mean
  divisor (ADR-008); Case 3A bias-corrected θ²_r; oracles O5 (random) and O6 (fixed).
- Estimand: [`estimand-specs/M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md);
  ADR-007 (scope split), ADR-008 (estimands).
- Deferred out of M3 (recorded so they aren't rediscovered): the flagship vignette
  (M4); replicate ratings within a cell; one-way designs; lme4 as a *selectable*
  engine; D-study projection API (ROADMAP).
- Status: done (Slices 0–2; merged via PR #2 at 11ab1b2; full CI matrix green —
  tests 118/0/0, coverage 93.8%).

## M4: "Choosing an ICC" flagship vignette
- Goal: the decision-framework teaching article (agreement vs consistency, single vs
  average, fixed vs random, complete vs incomplete) demonstrated on shipped M3 code,
  with a dependency-free decision-tree SVG and the shipped `ratings` /
  `ratings_incomplete` datasets. **No new estimator, no new estimand-spec** (ADR-009);
  every displayed coefficient is computed by `icc()` at knit time, seeded, and the
  prose's numeric relationships are backed by `test-vignette-claims.R` (#1/#4/#12).
- Reference: ADR-009 (scope).
- Deferred out of M4 (recorded so they aren't rediscovered): the `choose_icc()`
  decision helper (ROADMAP); filling `advanced.Rmd` (incomplete/multilevel/engine
  sections — M5+); a `DiagrammeR`/`mermaid`-rendered diagram (adds a dep for zero
  teaching gain vs. static SVG); migrating the oracle tests off inline data (they
  pin numeric values — left untouched deliberately).
- Status: done (Slices 1–2; merged via PR #5 at 4d4b2ba; full CI matrix green,
  133 tests).

## M4.5: D-study projection — reliability at other rater counts (ADR-010)
- Goal: project a fitted `icc()`'s reliability to the mean of an arbitrary rater
  count `m` (a GT decision study) — a change of the averaging **divisor** in the
  existing `(signal, {error set}, divisor)` estimand, shipped before M5. Ships
  `d_study()`, numeric `unit` (`ICC(A,m)` rows), and the `autoplot()` reliability
  curve; fixed-rater absolute-agreement projection refused (#5). Oracles O-DS
  (Spearman–Brown, GT dependability, `psych` at `m = n_raters`, seeded sim).
- Estimand: [`estimand-specs/M4.5-d-study.md`](estimand-specs/M4.5-d-study.md); ADR-010.
- Deferred (recorded so they aren't rediscovered): cost/optimal-design helpers
  ("cheapest `m` for Φ = 0.8"), two-facet D-studies, and subject-count projection
  (ROADMAP; M4.5 spec §6).
- Status: done (Slices 1–2; merged via PR #6 at 9be03a0; full CI matrix green).

## M5: Multilevel ICCs — subject-level vs. cluster-level
- Goal: subject-level (within-cluster) and cluster-level (between-cluster) interrater
  ICCs for subjects nested in clusters (ten Hove, Jorgensen & van der Ark 2022,
  Design 1) — crossed random raters, balanced/complete. Adds a `cluster` selector + a
  `level = c("subject","cluster")` knob; a **five-component** fit (`+ (1|cluster:rater)`);
  the scalar divisor and `icc_point()` are unchanged. Oracles O-ML (lme4 cross-engine
  <1e-4, seeded population recovery, single-level reduction).
- Estimand: [`estimand-specs/M5-multilevel.md`](estimand-specs/M5-multilevel.md); ADR-011.
- Deferred out of M5 (recorded so they aren't rediscovered): the paper's Designs
  2/3 (raters nested in clusters and/or subjects); incomplete multilevel (reuse M3
  `k_eff`/connectedness); fixed-rater multilevel; a Bayesian/MCMC cross-engine
  (the paper's own estimator — a future Bayesian engine, ROADMAP; was the old "M6"
  optional-engines slot, renumbered by ADR-013); a three-facet `d_study()` projecting
  subject-per-cluster counts; exposing the conflated single-level ICC (Eq. 14) as
  a shipped coefficient. (See spec §8.)
- Status: done (Slices 1–2; merged via PR #8 at 87b4588; full CI matrix green,
  188 tests).

## M5.5: lme4 as a selectable engine (pre-optional-engines interface slice, ADR-012)
- Goal: promote **lme4 from oracle-only to a selectable `engine = "lme4"`** for the
  random two-way path, returning the shared six-field engine contract so the whole
  downstream pipeline is untouched (no new estimand) — and build the **engine × design
  dispatch seam** later engines plug into. CI via **merDeriv** (new `Suggests`)
  delta-transformed to glmmTMB's boundary-safe log-SD scale; a **singular fit** aborts
  `intraclass_singular_fit` → glmmTMB (ADR-012). Oracles O-LME (point ≡ ≤1e-4;
  interval ≈ ≤9.4e-3; boundary; seeded-sim coverage).
- Reference: ADR-012.
- Deferred out of M5.5 (recorded so not rediscovered): lme4 for the fixed-effect
  (Case 3/3A) and multilevel fits (→ M8, ADR-012); the parametric-bootstrap
  `ci_method` (bootMer) → ROADMAP; a boundary-robust lme4 interval for singular fits
  (glmmTMB covers it today); merDeriv edge cases beyond the two-way random model.
- Status: done (one slice; merged via PR #9 at edd9d88; full CI matrix green incl.
  Windows, tests 219/0/0).

## M6: One-way random ICC(1) / ICC(1,k)
- Goal: the last member of the classic Shrout–Fleiss family — **one-way random**
  (SF Case 1), where rater identity is not modeled. `model = "oneway"` fits
  `score ~ 1 + (1 | subject)` (no rater term) → `ICC(1)`/`ICC(1,k)` (+ numeric-unit
  `ICC(m)`); the first milestone to change the **fitted model** itself (one-way ≠
  consistency: SF ICC(1)=0.166 vs ICC(C,1)=0.715). Oracles O-OW (SF 0.166/0.443,
  `psych` ICC1/ICC1k, one-way ANOVA, glmmTMB↔lme4, seeded sim). Promoted from ROADMAP
  by ADR-013.
- Estimand: [`estimand-specs/M6-oneway.md`](estimand-specs/M6-oneway.md).
- Deferred out of M6 (recorded so not rediscovered): within-cell replicates
  (`(1 | subject:rater)`); one-way *fixed* (not meaningful); categorical/ordinal
  one-way (GLMM). (Spec §10.)
- Status: done (one slice; merged via PR #10 at eb7102d; full CI matrix green incl.
  Windows, tests 247/0/0).

## M7: SEM engine (lavaan) — two-way random
- Goal: promote **lavaan (SEM / common-factor GT) to a selectable `engine = "lavaan"`**
  for the two-way random path — a third engine through the M5.5 dispatch seam, behind
  `check_installed()` (Suggests; light install preserved). No new estimand (ADR-014).
  **Consistency** ≡ glmmTMB exactly; **absolute agreement** = the SEM indicator-mean
  estimator σ²_r = Σν²/(k−1) (Jorgensen 2021 Eq. 6 — raw, no bias correction; a
  distinct, asymptotically-equivalent estimator, 0.284 vs 0.290 on SF, validated vs
  GENOVA/`gtheory` by Vispoel et al. 2022). An earlier *unsourced* bias correction was
  removed (#1/#4). Oracles O-SEM. *(was M6 → M7 per ADR-013)*
- References: ADR-014; Jorgensen 2021, Vispoel et al. 2022, Lee & Vispoel 2024 (in
  `REFERENCES.md`). No estimand-spec (engine, not estimand — cf. M4/M5.5).
- Deferred out of M7 (recorded so not rediscovered): the **Bayesian engine**
  (rstanarm preferred over brms) + a new `ci_method = "posterior"` (credible
  intervals) + half-*t* hyperpriors (ten Hove et al. 2020) — ROADMAP; **one-way random
  via SEM** (no faithful sourced route — ADR-014; ROADMAP); **incomplete/unbalanced
  SEM** (FIML); **fixed-rater and multilevel SEM**.
- Status: done (Slices 1–2; merged via PR #11 at fe76f5c; full CI matrix green).

## M8: Nested-rater multilevel ICCs — Designs 2/3 (ADR-016)
- Goal: extend the multilevel estimator beyond M5's Design 1 to the paper's
  **nested-rater designs** — raters nested within clusters (Design 2, four-component
  fit) and/or subjects (Design 3, three-component multilevel *one-way*, agreement-only)
  — balanced/complete random raters (ten Hove et al. 2022, Eqs. 8–11, Table 3
  middle/right). The design (1/2/3) is **inferred from the crossing pattern** (spec §4);
  mixed patterns abort (#5). Resolved from the paper: **subject-level only** (cluster
  level undefined for nested designs) and **Design 3 agreement-only** → six subject-level
  coefficients. Extends the M5 `cluster`/`level` API and fit (ADR-011); no new engine,
  no new `ci_method`. Fixed a latent bug: a `cluster` column previously forced Design 1.
- Estimand: [`estimand-specs/M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md);
  ADR-016. Oracles O-NML (lme4 cross-engine + seeded population recovery + reductions to
  the M1/M2 two-way and M6 one-way estimands; no textbook worked example).
- Deferred out of M8 (recorded so not rediscovered): **incomplete multilevel** (reuse
  M3 `k_eff`/connectedness); **fixed-rater multilevel** (reuse the M3 real fixed-effect
  fit path, ADR-008); **lme4 for the fixed (Case 3/3A) and multilevel fits** — its own
  later slice (engine parity, not multilevel estimand work; glmmTMB already covers
  these paths, ADR-012); the **Bayesian/MCMC cross-engine** (the paper's own
  estimator); a three-facet `d_study()` over subject-per-cluster counts; exposing the
  conflated single-level ICC (Eq. 14).
- Status: done (Slices 1–3; merged via PR #12 at ca2dcdb; full CI matrix green incl.
  Windows, 313 tests).

## M9: Incomplete / unbalanced multilevel ICCs — Design 1 (crossed)
- Goal: correct multilevel ICCs on **ragged** Design-1 (raters crossed with clusters)
  data — missing subject×rater cells — by generalizing the M3 connectedness +
  `k_eff` machinery (ADR-008) onto the M5 five-component multilevel fit (ADR-011).
  **No new estimand** (the M5 Design-1 coefficients on ragged data, as M3 is to
  M1/M2). Subject level (agreement/consistency, single/average) + cluster-level
  single-rater `ICC(c,1)`; a new optional **`design`** argument declares crossed vs.
  nested when missing cells make the pattern ambiguous (never guessed, #5); the
  multilevel connectedness rule (`crossed_ml_identifiability()`) and `k_eff` are
  **oracle-pinned, not asserted** (#1/#18). An oracle-first catch corrected spec §3a
  before code: σ²_cr is *not* in the subject-level error (matches shipped M5).
- Estimand: [`estimand-specs/M9-incomplete-multilevel.md`](estimand-specs/M9-incomplete-multilevel.md);
  ADR-018 (scope). Oracles O-IML (lme4 cross-engine <1e-4 + seeded recovery with MC-CI
  coverage + reductions to complete M5 and flat-incomplete M3 + an identifiability
  oracle; no textbook worked example).
- Deferred out of M9 (recorded so not rediscovered): **averaged cluster-level
  `ICC(c,k)` on incomplete data** (the per-cluster effective-rater divisor is an open
  modeling question, no textbook oracle — spec §3b; `ICC(c,1)` ships); **incomplete
  nested multilevel** (Designs 2/3 — its own later slice; ragged nested-vs-crossed
  inference); **fixed-rater multilevel** (M10, ADR-017); **lme4 for the multilevel
  fit** (engine parity, ADR-012);
  within-cell replicates via `(1 | cluster:subject:rater)` (ROADMAP); a Bayesian/MCMC
  cross-engine; three-facet `d_study()`; the conflated single-level ICC (Eq. 14).
- Status: done (Slices 1–3; merged via PR #13 at 073a51e; full CI matrix green incl.
  Windows, 348 tests).

## M10: Fixed-rater multilevel ICCs — Design 1 (crossed), balanced, subject level
- Goal: subject-level multilevel ICCs with raters treated as **fixed** (McGraw & Wong
  Case 3/3A) in the **crossed** Design-1 fit, **balanced/complete** — the fixed-rater
  pair with M9. Reuses the M3 real fixed-effect fit + bias-corrected finite-population
  **θ²_r** (ADR-008, via a shared `theta2r_fixed()` helper) placed in the M5 multilevel
  subject-level decomposition (ADR-011). **No new estimand concept** (θ²_r replaces the
  random σ²_r in the `rater` slot; `icc_point()`/`mc_ci()` unchanged). Fit
  `score ~ 1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)` via
  `fit_glmmtmb_multilevel_fixed()`. Consistency ≡ random exactly; agreement differs only
  by θ²_r vs σ²_r (zero on balanced data). No textbook oracle — **oracle-pinned, not
  asserted** (#1/#18).
- Estimand: [`estimand-specs/M10-fixed-multilevel.md`](estimand-specs/M10-fixed-multilevel.md);
  ADR-019 (scope). Oracles O-FML (primary: reduction → M5 balanced fixed≡random <1e-4;
  + reduction → M3 single-cluster signal/residual; + lme4 cross-engine; + seeded-sim
  recovery). Note: θ²_r does not reduce at a single cluster (the cluster×rater term
  collapses — a degenerate artifact, documented in spec §4).
- Deferred out of M10 (recorded so not rediscovered): **fixed-rater cluster-level IRR**
  (signal σ²_c, error {θ²_r, σ²_cr} — its own later slice); **incomplete/unbalanced
  fixed-rater multilevel** (reuse M9 connectedness + M3 θ²_r-under-imbalance);
  **fixed-rater nested designs** (2/3); **lme4 for the fixed/multilevel fits** (engine
  parity, ADR-012); and the M9 carry-overs (averaged cluster-level `ICC(c,k)`
  incomplete divisor; Bayesian/MCMC; three-facet `d_study()`; conflated single-level
  ICC, Eq. 14).
- Status: done (Slices 1–2; merged via PR #14 at 9f799d2; full CI matrix green incl.
  Windows, 371 tests).

## M11: General `autoplot()` / `plot()` methods for `icc` objects
- Goal: general plotting over the shipped estimators, generalizing the M4.5
  `autoplot.icc_dstudy()` reliability curve (ADR-010) to the `icc` object itself.
  `autoplot.icc(object, what = c("coefficients", "components"))` + a `plot.icc()`
  wrapper, lazily `s3_register()`-ed (ggplot2 stays a `Suggests`; light install
  preserved). `"coefficients"` = a coefficient forest plot (point + MC-CI band per
  `$estimates` row, faceted by `level` for multilevel); `"components"` = a
  variance-component decomposition bar per `$components` slot. **No new estimand, fit,
  CI machinery, or dependency.** Shared `icc_design_label()` + `icc_components_view()`
  extracted from `format.icc` so plots and the printed report never drift. Correctness
  is faithful-rendering (#1 numerically N/A): build-data assertions
  (`ggplot_build()` == `$estimates`/`$components`), **no `vdiffr`**; also backfilled the
  previously-untested `autoplot.icc_dstudy`.
- Reference: ADR-020 (scope); no estimand-spec (rendering layer — cf. M4/M5.5/M7).
- Deferred out of M11 (recorded so not rediscovered): **error-set shading** on the
  components plot (signal vs. index-specific error set — its own slice); a **combined /
  patchwork multi-panel** layout; **`d_study()` projection overlays**; **theming /
  palette customization** beyond ggplot2 defaults; a **base-`graphics` plot method**.
- Status: done (Slices 1–2; merged via PR #15 at 3368299; full CI matrix green incl.
  Windows and R-devel, 402 tests).

## M12: `choose_icc()` interactive decision helper
- Goal: a decision helper turning the M4 flagship vignette's six-axis tree into code —
  crossed-vs-one-way (`model`), agreement/consistency (`type`), single/average (`unit`),
  random/fixed (`raters`), and the multilevel subject/cluster fifth choice
  (`multilevel`/`level`); complete-vs-incomplete surfaced as a note (`icc()` handles it).
  Teaching/API, **no new estimand.** Returns a classed `icc_recommendation` advice object
  (recommended McGraw–Wong + Shrout–Fleiss label, per-axis rationale, and the exact
  `icc(...)` call to run) — it does **not** fit. Dual interface: programmatic when answers
  are passed, guarded interactive console Q&A (`is_interactive()`) when omitted; structural
  axes default to the common case, coefficient-selecting axes have no silent default
  (loud `intraclass_underspecified` / `intraclass_inapplicable`, #5/#8). Labels reuse
  `icc_estimand()`, so they cannot drift from `icc()`. Promoted from the M4 deferral /
  ROADMAP by ADR-017.
- Reference: ADR-021 (scope); no estimand-spec (teaching layer — cf. M4/M5.5/M7/M11).
  Correctness (#1 numerically N/A): a **round-trip oracle** (every valid axis
  combination's emitted call reproduces a direct `icc()` call's rows) + the MW↔SF
  crosswalk-label table + classed aborts; interactive shell tested via an injected
  responder + mocked `prompt_line`/`is_interactive` (no live console in CI).

- Deferred out of M12 (record so not rediscovered): A **`fit=`/data-in path** that runs
  `icc()` and returns the fitted object (helper is advice-only by ADR-021); a
  **`tidy`/`glance`** method on `icc_recommendation`;
  **GUI/Shiny** front-ends; **engine / `ci_method` / `d_study()` guidance** inside the
  helper (outside the vignette tree); the **full advanced-vignette showcase** of the
  helper (M13). ADR-017 / M9–M11 estimator carry-overs untouched.
- Status: done (Slices 1–2; merged via PR #16 at 20f9afc; full CI matrix green incl.
  Windows and R-devel, 478 tests).

## M13: Release polish — docs, site, CRAN submission-ready
- Goal: make the complete M0–M12 package **discoverable, teachable, and
  CRAN-submittable** — a docs/metadata milestone, **no new estimand, engine, fit, CI
  machinery, or dependency** (cf. M4/M5.5/M7/M11/M12). Depth is **submission-ready, not
  submitted** (the CRAN upload + win-builder/R-hub round-trips are a maintainer act, out
  of band). Release version **`0.1.0`**. Three slices: (1) `_pkgdown.yml` reference index
  rebuilt by role with every export listed (#6) + a pre-existing broken flagship-article
  image fixed via a vignette `resource_files:` entry; (2) `advanced.Rmd` gained the M11
  `autoplot()` and M12 `choose_icc()` showcase sections (all numbers computed live,
  #4/#12) + README refreshed with a multilevel worked example; (3) version bump, NEWS
  consolidated into a 0.1.0 first-release changelog, `cran-comments.md` + `inst/WORDLIST`,
  British→US spelling (`Language: en-US`), `R CMD check --as-cran` **0/0/0** in CRAN mode
  and with `NOT_CRAN=true`, `lintr` clean. Closes the ADR-017 arc (M0–M13).
  *(was M9 per ADR-017; M7 → M9 per ADR-013; M6 originally.)*
- Reference: ADR-022 (scope); no estimand-spec. Brief §8 per-milestone DoD.

- Deferred out of M13 (record so not rediscovered): The **actual CRAN upload** +
  win-builder / R-hub / `devtools::submit_cran` round-trips
  (maintainer, out of band); a **JOSS / software paper**; a **pkgdown custom
  theme / logo / hex sticker**; a **benchmark-vs-prior-art** article (ROADMAP parking
  lot). Every prior-milestone carry-over is untouched: M9 averaged cluster-level
  `ICC(c,k)` incomplete divisor; **lme4 for the fixed/multilevel fits** (ADR-012); the
  **Bayesian engine** + `ci_method = "posterior"`; **one-way via SEM** (ADR-014);
  within-cell replicates; three-facet `d_study()`; the conflated single-level ICC
  (Eq. 14). All in [`ROADMAP.md`](ROADMAP.md).
- Status: done (Slices 1–3; merged via PR #17 at 54c0947; full CI matrix green incl.
  Windows and R-devel). **Final milestone of the ADR-017 arc — M0–M13 all shipped.**
  Package at **v0.1.0**, submission-ready; the CRAN upload itself is the maintainer's
  out-of-band step.

## M14: lme4 for the fixed & multilevel fits — engine parity (ADR-023)
- Goal: promote `engine = "lme4"` from the two-way/one-way random paths (M5.5/M6) to
  **full design parity** with glmmTMB across every **balanced/complete** design — the
  fixed-rater (Case 3/3A) and all multilevel fits — retiring the ADR-012 engine debt
  deferred four times (M5.5, M8, M9, M10). **Engine parity, not estimand work:** no new
  estimand, estimand-spec, `ci_method`, or dependency (lme4 + merDeriv stay `Suggests`).
  Five `fit_lme4_*` shapes (fixed two-way; Design 1 crossed random; Designs 2/3 nested;
  Design 1 crossed fixed), each returning the shared six-field engine contract so
  `icc_point()`/`mc_ci()`/`d_study()` are untouched. `theta2r_fixed()` generalized to
  engine-agnostic `(beta, vbeta, k)`; a `lme4_ml_contract()` helper mirrors
  `glmmtmb_ml_contract` (merDeriv SD-scale covariance delta-transformed to glmmTMB's
  log-SD scale, columns aligned by exact `cov_<group>.(Intercept)` name; the singular-fit
  → glmmTMB abort reused per shape). The one new derivation is the fixed-rater **θ²_r**
  Monte-Carlo draw from the fixed rater-contrast betas. Incomplete/ragged lme4 falls
  through to a loud abort toward glmmTMB. Chosen from the post-ADR-017 backlog over the
  Bayesian engine and the M9 `ICC(c,k)` divisor.
- Reference: ADR-023 (scope); no estimand-spec (engine, not estimand — cf. M5.5/M7/M4).
  Oracles **O-LME2** per shape (glmmTMB the independent oracle): point ≡ glmmTMB ≤1e-4
  (~1e-6–1e-10 observed); interval MC-CI ≈ glmmTMB ~1e-2 (≤4.6e-3); boundary/singular-fit
  abort; seeded-sim coverage; + the balanced fixed≡random reduction.

- Deferred out of M14 (record so not rediscovered): **Incomplete/ragged lme4** for every
  new shape (the M9 `k_eff`/connectedness × merDeriv
  singular-fit interaction — a follow-up slice); the **parametric-bootstrap `ci_method`**
  (bootMer); a **boundary-robust lme4 interval for singular fits** (glmmTMB covers it
  today); merDeriv edge cases beyond these models. Untouched arc carry-overs stay in
  [`ROADMAP.md`](ROADMAP.md): the **Bayesian engine** + `ci_method = "posterior"`; the
  **M9 averaged cluster-level `ICC(c,k)` incomplete divisor**; **one-way via SEM**;
  within-cell replicates; three-facet `d_study()`; the conflated single-level ICC (Eq. 14).
- Status: done (Slices 1–3 + cross-cutting DoD; merged via PR #18 at 474e0c1; full CI
  matrix green incl. Windows and R-devel, 533 tests). `engine = "lme4"` now has full
  balanced design parity with glmmTMB.

## M15: Incomplete/ragged lme4 — full incomplete engine parity (ADR-024)
- Goal: extend `engine = "lme4"` from M14's **balanced/complete** parity to every
  **incomplete/ragged** design glmmTMB already fits — closing the last ADR-023
  engine-parity deferral (the M9 `k_eff`/connectedness × merDeriv singular-fit
  interaction). **Engine parity, not estimand work:** no new estimand, estimand-spec,
  `ci_method`, or dependency (lme4 + merDeriv stay `Suggests`). Three incomplete
  shapes, each an **existing `fit_lme4_*` shape run on ragged data** (no new fit
  function — the `k_eff`/connectedness/θ²_r-under-imbalance machinery is engine-agnostic
  and runs before fit dispatch, so the fit formulas are unchanged): (1) incomplete
  random two-way (M3 × M5.5, currently ungated-but-untested); (2) incomplete
  fixed-rater two-way (M3 Case 3A, θ²_r-under-imbalance); (3) incomplete crossed
  (Design 1) random multilevel (M9, five-component). The work is narrowing the two
  `!balanced` lme4 guards in `R/icc.R`, confirming the shipped merDeriv → log-SD
  delta-transform (and the fixed θ²_r draw from ragged rater-contrast βs) survive
  unequal rater counts, and **oracle-pinning the success-vs-degrade boundary** (ragged
  fits reach the variance boundary more often → the shipped `intraclass_singular_fit` →
  glmmTMB handoff fires more; that graceful degradation is intended, #5/#18). Scope is
  glmmTMB-limited: incomplete **nested** Designs 2/3, incomplete **fixed multilevel**,
  and the averaged cluster-level `ICC(c,k)` incomplete divisor stay deferred for **all**
  engines (lme4 can't cover what glmmTMB doesn't). Chosen to **consolidate M14** over
  the Bayesian engine and the M9 `ICC(c,k)` divisor.
- Reference: ADR-024 (scope); no estimand-spec (engine, not estimand — cf.
  M5.5/M7/M14). Oracles **O-LME2** per shape (glmmTMB the independent oracle): point ≡
  glmmTMB ≤1e-4 on ragged data; interval MC-CI ≈ glmmTMB ~1e-2; a singular-fit-abort
  oracle on a ragged design that goes singular; seeded-sim coverage at nominal. The
  multilevel **singular→glmmTMB degrade** is characterized and pinned (a σ²_cr≡0 ragged
  crossed design lands lme4 on the boundary → classed `intraclass_singular_fit` abort;
  glmmTMB still fits).
- Deferred out of M15 (record so not rediscovered): The **parametric-bootstrap
  `ci_method`** (bootMer); a **boundary-robust lme4
  interval for singular fits** (glmmTMB covers it today — the degrade-to-glmmTMB
  handoff stands); **merDeriv edge cases** beyond these models. Untouched arc
  carry-overs stay in `ROADMAP.md`: the **Bayesian engine** + `ci_method = "posterior"`;
  the **M9 averaged cluster-level `ICC(c,k)` incomplete divisor**; **one-way via SEM**;
  within-cell replicates; three-facet `d_study()`; the conflated single-level ICC
  (Eq. 14).
- Status: done (Slices 1–3 + finish-task reconcile; merged via PR #19 at b0dd492; full
  CI matrix green incl. Windows and R-devel, 572 tests). `engine = "lme4"` now has full
  design parity with glmmTMB on both balanced and incomplete/ragged data.

## M16: parametric-bootstrap `ci_method` — second interval method (ADR-025)
- Goal: add **`ci_method = "bootstrap"`**, a parametric bootstrap (simulate from the
  fitted model → refit → recompute the ICC per replicate → percentile interval), as a
  sibling to the Monte-Carlo default (ADR-003). The **first genuinely new `ci_method`**
  (until now `icc()` hard-rejects anything but `"montecarlo"`), and the **multi-method
  dispatch seam** the eventual Bayesian `"posterior"` method reuses. Chosen as Wave 1 of
  the non-Bayesian carryover sequencing (STATUS): lowest estimand-risk (no new estimand),
  highest infra ROI. **Both engines via an engine-level `simulate_refit()` contract**
  (`bootMer` for lme4, `simulate()`+refit for glmmTMB — maintainer chose "both" so the
  **default engine** works out of the box), mirroring the M5.5 engine × design seam;
  each returns per-replicate components on the shared contract so `icc_point()` maps to
  the ICC identically. New arg **`boot_samples`** (default 999, vs `mc_samples` 10000).
  **No new estimand, estimand-spec, or dependency** (`bootMer` in lme4/`Suggests`,
  glmmTMB `simulate()` in `Imports` — light install intact); additive, non-breaking (#6).
- Reference: ADR-025 (scope); no estimand-spec (an *interval method*, not an estimand —
  cf. M4.5 `d_study()`). Oracles (a CI method's oracle is **coverage**, #1): (O1) seeded
  simulation coverage ~nominal at known VCs; (O2) agreement with the MC CI on interior
  cases within MC tolerance (MC the independent method), diverging predictably at the
  boundary (characterized, #18); (O3) literature anchor (Efron & Tibshirani 1993; the
  ten Hove/Jorgensen MC-vs-bootstrap comparison).
- Deferred out of M16 (record so not rediscovered): **BCa intervals** (need jackknife
  acceleration — percentile ships first); **bootstrap-
  projected `d_study()` bands** (the reliability-curve band reuses the shared *MC* draws
  across `k` — a bootstrap version would reproject each refit's components); **parallelized
  refits** (keep dependency-light first); **lme4 bootstrap on singular fits** (bootMer
  could bootstrap a boundary fit without merDeriv, but M16 keeps the lme4→glmmTMB singular
  handoff for both `ci_method`s — maintainer decision; lifting it needs `ci_method` threaded
  into the lme4 fit path + a `d_study` interaction → ROADMAP). Untouched arc carry-overs stay in
  [`ROADMAP.md`](ROADMAP.md): the **Bayesian engine** + `ci_method = "posterior"`;
  **within-cell replicates** (Wave 2); **three-facet `d_study()`** (Wave 2); the **M9
  averaged cluster-level `ICC(c,k)` incomplete divisor** (Wave 3); the **conflated
  single-level ICC (Eq. 14)** (Wave 1 thin slice); **one-way via SEM** (blocked, ADR-014);
  the boundary-robust lme4 singular interval + merDeriv edge cases (deprioritized).
- Status: **done** (Slices 1–3 + method-neutral singular-fit message + finish-task
  reconcile; merged via PR #21 at 0b84885; full CI matrix green incl. Windows and R-devel).
  `ci_method = "bootstrap"` covers **every design both mixed-model engines fit** — two-way
  random/fixed, one-way, and the multilevel designs at both levels — via a shared
  `glmmtmb_simulate_refit` / `lme4_bootmer_refit` factory per engine (the component extractor
  DRY-shared with each fit's point estimate; θ²_r recomputed per refit for fixed raters).
  Oracles: O1 coverage, O2 MC-agreement (two-way ≤0.06; multilevel subject-level ≤0.10,
  honestly looser), cross-engine lme4≈glmmTMB (≤0.05), a deterministic refit-failure
  discard-policy test, reproducibility, and the lavaan-unsupported abort. The lme4 engine
  defers a singular fit to glmmTMB for either `ci_method` (maintainer decision; lifting it
  for bootstrap → ROADMAP). Installed-pkg check run; 591 pass / 0 fail, lint + `air` clean.

## M17: variance-decomposition trio — conflated ICC, multilevel `d_study()`, within-cell replicates (ADR-026)
- Goal: promote the next non-Bayesian wave as **one milestone of three independent vertical
  slices** (finer variance decomposition and its projection), ordered by oracle-risk.
  **Slice 1 — conflated single-level ICC** via `level = "conflated"` (ten Hove Eq. 14, the
  biased ignore-clusters coefficient off the M5 fit; agreement-only, a diagnostic contrast
  never recommended). **Slice 2 — multilevel rater-count `d_study()`** projecting the rater
  count at subject + cluster levels (Eq. 12/13); *retargeted from the original
  "three-facet / subjects-per-cluster" plan* — the paper's cluster ICC has no subject facet
  and Ns is efficiency-only, so subjects-per-cluster is not a sourced reliability projection
  (ADR-026 amendment). **Slice 3 — within-cell replicates** split σ²_res → σ²_sr + σ²_e via
  `(1|subject:rater)`, plus an occasion-averaged coefficient (`occasions` knob) built on a new
  **per-component error divisor** in the estimand; two-way random, balanced/complete only.
  Key engineering: `icc_point()` generalized (signal and per-component error divisors),
  `fit_{glmmtmb,lme4}_replicates` reuse the generic `*_ml_contract`, `k_eff` counts distinct
  raters. **No new dependency** (`gtheory` proved unnecessary — light install intact).
- Reference: ADR-026 (scope + maintainer API decisions + the Slice 2 retarget amendment);
  estimand-specs [`M17-conflated-icc.md`](estimand-specs/M17-conflated-icc.md),
  [`M4.5-d-study.md`](estimand-specs/M4.5-d-study.md) §7,
  [`M17-within-cell-replicates.md`](estimand-specs/M17-within-cell-replicates.md). Oracles
  O-Conflated / O-DS(multilevel) / O-Rep, asserted in `test-icc-multilevel.R`,
  `test-d-study.R`, `test-replicates.R` (`REFERENCES.md`).
- Deferred out of M17 (record so not rediscovered): BCa intervals and **bootstrap-projected
  `d_study` bands** (ADR-025); the **M9 averaged cluster-level `ICC(c,k)` incomplete divisor**
  (Wave 3, research — Slice 2's complete-data guard must not reach it); **incomplete-data
  multilevel `d_study()`** (subject-level projection would be definable, but bundling it with
  the cluster level's open incomplete divisor is deferred — Slice 2 is complete-data only);
  **subjects-per-cluster / three-facet projection** — *removed from M17, not merely deferred*:
  the paper's cluster ICC has no subject facet and Ns is efficiency-only (ADR-026 amendment),
  so it is reclassified under the parked **design/power helpers** item, not a d_study facet.
  Untouched arc carry-overs stay in [`ROADMAP.md`](ROADMAP.md): the **Bayesian engine** +
  `ci_method = "posterior"`; **categorical/ordinal GLMM ratings**; **one-way via SEM**
  (blocked, ADR-014); the **non-parametric bootstrap / profile-likelihood CIs** and
  **benchmark suite**; the **lme4 singular-fit / merDeriv edge cases** (deprioritized).
- Status: **done** (Slices 1–3; merged via PR #22 at a915256; full CI matrix green incl.
  Windows and R-devel, 722 tests). `level = "conflated"` (Eq. 14 diagnostic), multilevel
  rater-count `d_study()` at both levels, and within-cell replicates + occasion-averaged
  coefficient all ship; `R CMD check` 0/0/0.

## M18: Multilevel completeness I — crossed (Design 1) incomplete corners (ADR-028)
- Goal: fill the **ragged-data corners of the crossed (Design 1) five-component** multilevel
  fit that M9/M10/M17 left open — the first milestone of the M18–M21 completeness arc (ADR-027).
  **Completeness, not new estimand work** (cf. M14/M15): every slice lifts a **single shipped
  abort guard**, reusing oracle-pinned machinery (M3 `k_eff`/connectedness, M10
  `theta2r_fixed()`, M17 §7 multilevel `d_study`, M16 `simulate_refit`). Additive, non-breaking
  (#6) — no new argument, only new valid combinations. Four thin slices ordered by oracle-risk.
- Reference: ADR-028 (scope + maintainer decisions: Slice 2 attempt-then-degrade; Slice 3/4
  split). Only Slice 2 touches a spec (`M17-conflated-icc.md §6`); no new estimand-spec.
  Oracle posture (#1, all slices): glmmTMB↔lme4 cross-engine < 1e-4 + **reduction** to the
  shipped balanced/complete case + seeded population recovery (no textbook worked example, as
  M8–M10/M15). Brief §8 per-milestone DoD.

**DoD board (this is the live task board — ADR-015; check off in the same commit as the work, #16):**

- **Slice 1 — incomplete fixed-rater crossed (COVERAGE #9)** — reuse M3 Case-3A `k_eff` + M10
  θ²_r under imbalance; θ²_r replaces σ²_r in the rater slot on ragged data. Lowest risk. **Done.**
  - [x] Narrowed the `raters == "fixed"` abort in the ragged-crossed block (`R/icc.R`); the fixed
        path flows through the M9 identifiability gates (conservative for fixed) into the shipped
        `fit_{glmmtmb,lme4}_multilevel_fixed` with the M3 `k_eff` divisor — no fit change needed.
  - [x] Oracle O-IFML (`test-icc-fixed-multilevel.R`): balanced fixed≡random reduction (existing
        O-FML); ragged independent-lme4 cross-engine <1e-4 + `icc(lme4)≡icc(glmmTMB)`; genuine
        fixed≠random under imbalance (matches single-level M3); seeded consistency recovery w/
        MC-CI coverage; singular→glmmTMB degrade pinned; identifiability guards still fire.
        Seeded generators (no committed constants), so no `REFERENCES.md` change.
  - [x] Docs (`icc()` roxygen) updated; COVERAGE #9 → ✅. Suite 740 pass / 0 fail, lint + `air` clean.
- **Slice 2 — incomplete conflated ICC (COVERAGE #8)** — **attempted flat-`k_eff` Eq. 14 on
  ragged data; the oracle held → ships** (no reclassification; ADR-028 attempt-then-degrade). **Done.**
  - [x] Characterized: Eq. 14 lumps σ²_r+σ²_cr+σ²_res into one error and σ²_c+σ²_{s:c} into one
        signal, so it is the flat two-way ICC off the five-component fit with the same flat
        `k_eff` — well-posed on ragged data (spec `M17-conflated-icc.md §6a`).
  - [x] Lifted the `"conflated" %in% level` ragged abort (`R/icc.R`); the conflated path flows
        through the existing crossed-multilevel identifiability gates (conservative — matches
        flat-two-way identifiability). Extended the spec §6a; roxygen updated.
  - [x] Oracles (`test-icc-multilevel.R`): Eq-14 identity on ragged components (~1e-10);
        cross-engine glmmTMB≡lme4 <1e-4; tracks flat incomplete two-way agreement (~0.02) while
        staying visibly biased vs subject. Seeded generators. COVERAGE #8 → ✅. Suite 749 pass.
- **Slice 3 — incomplete subject-level `d_study()` (COVERAGE #13)** — subject level only; cluster
  level stays behind the 🟣 Wave-3 `ICC(c,k)` divisor (#18 bound). **Done.**
  - [x] Made the incomplete-multilevel `d_study()` abort level-aware (`R/d-study.R`): the subject
        level projects (projection moves only the divisor `m`); the cluster level is dropped with
        a one-time note (mirroring `icc()`'s cluster-on-incomplete posture) or aborts when it is
        the only requested level.
  - [x] Oracle O-IDS (`test-d-study.R`): reduction → fitted subject `ICC(A,k)` at `m = k_eff`
        (exact); independent lme4 cross-engine <1e-4; monotone/[0,1] with boundary-aware band;
        cluster-only incomplete fit aborts. Roxygen + M4.5 §7.2 spec updated. COVERAGE #13 → ✅.
        Suite 758 pass.
- **Slice 4 — bootstrap-projected `d_study()` bands (COVERAGE #14)** — the M16 deferral, package-
  wide (not just incomplete); reproject each `simulate_refit` replicate across `k`.
  - [ ] Band from bootstrap replicates when the fit's `ci_method == "bootstrap"`; MC path unchanged.
  - [ ] Oracle (a band's oracle is coverage, #1): seeded coverage ~nominal; agreement with the MC
        band on interior cases within tol, diverging at the boundary (#18). COVERAGE #14 → ✅.
- **Cross-cutting DoD:** `air format` + `lintr::lint_package()` clean; installed-pkg check
  `NOT_CRAN=true` green; `R CMD check --as-cran` 0/0/0; NEWS updated; `project/` (STATUS,
  COVERAGE, MILESTONES status line) reconciled; ships on a `m18-*` branch via PR.

- Deferred out of M18 (record so not rediscovered): incomplete **nested** Designs 2/3 and
  **fixed-rater nested** (M19); ragged/fixed/multilevel **replicates** (M20); **SEM parity**
  (M21); the **cluster-level `ICC(c,k)` incomplete divisor** (🟣 Wave-3 research, M9 §9 — bounds
  Slice 3); `consistency`/`fixed` **conflated** (⚫/🟣, COVERAGE §④). Arc carry-overs stay in
  `ROADMAP.md`: Bayesian engine + `ci_method = "posterior"`; categorical/ordinal GLMM; one-way
  via SEM (blocked, ADR-014); non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge
  cases.
- Status: **in progress** — planning done (ADR-028); **Slices 1–3 shipped** (incomplete
  fixed-rater crossed; incomplete conflated ICC; incomplete subject-level `d_study()`; 758 tests
  pass, lint/`air` clean). Slice 4 (bootstrap-projected `d_study()` bands) next. No PR yet.
