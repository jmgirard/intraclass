# Milestones

Ordered milestones with status and the deferrals each one recorded. **Shipped
milestones (M0–M11) are compressed** to Goal / Status / Deferred + spec-and-ADR
pointers — the full blow-by-blow DoD lives in its ADR (`DECISIONS.md`), its
estimand-spec, and git history (ADR-015, single-source; don't restate it here). The
**active** and **next** milestones are detailed in full. The remaining milestone (M13)
is a provisional one-liner, detailed at its start after a short retro on the previous
one (founding brief §7). The arc is a hypothesis, not a contract — reorders get a
[`DECISIONS.md`](DECISIONS.md) entry (the M9–M13 tail was set by ADR-017; ADR-018
detailed M9, ADR-019 detailed M10, ADR-020 detailed M11, ADR-021 detailed M12).

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

### Deferred out of M12 (record so not rediscovered)
- A **`fit=`/data-in path** that runs `icc()` and returns the fitted object (helper is
  advice-only by ADR-021); a **`tidy`/`glance`** method on `icc_recommendation`;
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

### Deferred out of M13 (record so not rediscovered)
- The **actual CRAN upload** + win-builder / R-hub / `devtools::submit_cran` round-trips
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

## M14: lme4 for the fixed & multilevel fits — engine parity (ADR-023) — **next**
- Goal: promote `engine = "lme4"` from the two-way/one-way random paths (M5.5/M6) to
  **full design parity** with glmmTMB across every **balanced/complete** design —
  the fixed-rater (Case 3/3A) and all multilevel fits — retiring the ADR-012 engine
  debt deferred four times (M5.5, M8, M9, M10). **Engine parity, not estimand work:**
  no new estimand, estimand-spec, `ci_method`, or dependency (lme4 + merDeriv stay
  `Suggests`; light install preserved). Each new `fit_lme4_*` returns the same
  six-field engine contract as its glmmTMB twin, so `icc_point()`/`mc_ci()`/`d_study()`
  are untouched; the merDeriv → log-SD delta-transform + singular-fit → glmmTMB abort
  (ADR-012) are reused per shape. The one new derivation is the fixed-rater **θ²_r**
  Monte-Carlo draw (from the fixed rater contrasts via merDeriv's fixed-effect
  covariance, not a random SD). Balanced/complete only — incomplete falls through to a
  loud abort toward glmmTMB. *(Chosen from the post-ADR-017 backlog over the Bayesian
  engine and the M9 `ICC(c,k)` divisor; scope confirmed with the maintainer.)*
- Reference: ADR-023 (scope); no estimand-spec (engine, not estimand — cf.
  M5.5/M7/M4). Oracles **O-LME2** per shape: (a) point lme4 ≡ glmmTMB ≤1e-4; (b)
  interval lme4 MC-CI ≈ glmmTMB ~1e-2; (c) boundary/singular-fit oracle; (d) seeded-sim
  coverage at nominal.

### Slices (DoD board — check off in the same commit as the work, #16)
- [x] **Slice 1 — `fit_lme4_fixed`** (two-way fixed, Case 3/3A, subject level, balanced).
  The θ²_r derivation: `to_components` maps fixed rater-contrast draws (merDeriv joint
  fixed+random covariance) through the shared `theta2r_fixed()` (ADR-008); reuses the
  log-SD delta-transform for the random components. `icc()` guard narrowed so the
  balanced fixed lme4 path is supported; incomplete/one-way-fixed still abort. O-LME2
  (a)–(d) pinned vs `fit_glmmtmb_fixed`. **Done** — `theta2r_fixed()` generalized to
  `(beta, vbeta, k)` (engine-agnostic; both glmmTMB callers updated); O-LME2 green on SF
  `ratings`: point ≡ glmmTMB ~1e-10, interval gap ≤4.6e-3 (<0.02), balanced fixed≡random
  ~5e-7, singular-fit abort + seeded-sim coverage. 504 tests, lintr + `air` clean.
- [ ] **Slice 2 — `fit_lme4_multilevel`** (Design 1 crossed random, five-component,
  balanced). Multi-grouping-factor merDeriv vcov + column alignment; delta-transform
  template extended to five components. `engine == "lme4"` branch added in the
  `engine_fit` dispatch block. O-LME2 (a)–(d) vs `fit_glmmtmb_multilevel`.
- [ ] **Slice 3 — nested + multilevel-fixed** (`fit_lme4_nested_clusters` Design 2,
  `fit_lme4_nested_subjects` Design 3, `fit_lme4_multilevel_fixed` Design 1 fixed),
  reusing Slices 1–2 machinery. Dispatch branches completed; the blanket lme4 guard is
  now incomplete-only. O-LME2 (a)–(d) per shape vs the matching `fit_glmmtmb_*`.
- [ ] **Cross-cutting DoD:** `@param engine` roxygen design-coverage updated; NEWS
  bullet; `air format` + `lintr::lint_package()` clean; `R CMD check` + full test suite
  green on the installed package with `NOT_CRAN=true` (memory
  `verify-against-installed-package`); tracking (`STATUS.md`/this board) updated
  in-commit; ships on `m14-lme4-parity`, merges via PR.

### Deferred out of M14 (record so not rediscovered)
- **Incomplete/ragged lme4** for every new shape (the M9 `k_eff`/connectedness × merDeriv
  singular-fit interaction — a follow-up slice); the **parametric-bootstrap `ci_method`**
  (bootMer); a **boundary-robust lme4 interval for singular fits** (glmmTMB covers it
  today); merDeriv edge cases beyond these models. Untouched arc carry-overs stay in
  [`ROADMAP.md`](ROADMAP.md): the **Bayesian engine** + `ci_method = "posterior"`; the
  **M9 averaged cluster-level `ICC(c,k)` incomplete divisor**; **one-way via SEM**;
  within-cell replicates; three-facet `d_study()`; the conflated single-level ICC (Eq. 14).
