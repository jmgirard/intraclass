# Milestones

Ordered milestones with status and the deferrals each one recorded. **Shipped
milestones (M0–M7) are compressed** to Goal / Status / Deferred + spec-and-ADR
pointers — the full blow-by-blow DoD lives in its ADR (`DECISIONS.md`), its
estimand-spec, and git history (ADR-015, single-source; don't restate it here). The
**active** and **next** milestones are detailed in full. Remaining milestones (M8–M9)
are provisional one-liners, detailed at the start of their milestone after a short
retro on the previous one (founding brief §7). The arc is a hypothesis, not a
contract — reorders get a [`DECISIONS.md`](DECISIONS.md) entry (the M6–M9 sequence was
set by ADR-013; ADR-014 detailed M7).

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
  **nested-rater designs** — raters nested within clusters (Design 2) and/or subjects
  (Design 3) — **balanced/complete, random raters** (ten Hove, Jorgensen & van der Ark
  2022, Eqs. 8–11, Table 3 middle/right). The direct analog of M5's Design-1 thin
  scope (#15): ships the novel nested-rater estimand from the paper in hand, records
  the combinatorial variants. Extends the M5 `cluster`/`level` API and five-component
  fit (ADR-011); no new engine, no new `ci_method`. Estimand-spec required (changes
  the fitted model): `estimand-specs/M8-nested-multilevel.md` (equations transcribed
  from the paper, held pending the PDF). Oracles = the M5 O-ML pattern (lme4
  cross-engine + seeded population recovery + reduction check; no textbook worked
  example). Level coverage per design (subject-only vs. both) read off Table 3 at spec
  time, not asserted.
- Slices (mirror M5): **Slice 1 = Design 2**, **Slice 2 = Design 3**, **Slice 3 =
  docs**. Each estimand pinned by ≥2 oracles before shipping (#1/#2).
- Estimand: [`estimand-specs/M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md)
  (written — Eqs. 8–11 + Table 3 transcribed); ADR-016.
- Deferred out of M8 (recorded so not rediscovered): **incomplete multilevel** (reuse
  M3 `k_eff`/connectedness); **fixed-rater multilevel** (reuse the M3 real fixed-effect
  fit path, ADR-008); **lme4 for the fixed (Case 3/3A) and multilevel fits** — its own
  later slice (engine parity, not multilevel estimand work; glmmTMB already covers
  these paths, ADR-012); the **Bayesian/MCMC cross-engine** (the paper's own
  estimator); a three-facet `d_study()` over subject-per-cluster counts; exposing the
  conflated single-level ICC (Eq. 14).
- Status: detailed + estimand-spec written (ADR-016); not started. Resolved from the
  paper: **subject-level only** (cluster level undefined for nested designs), **Design
  3 agreement-only** → six coefficients (D2 agreement/consistency × single/average, D3
  agreement × single/average). Next: Slice 1 (Design 2).

## M9: Release polish *(provisional)*
- Goal: pkgdown site, advanced vignette, CRAN submission prep. *(was M7 → M9 per
  ADR-013; was M6 before)*
- Status: provisional
