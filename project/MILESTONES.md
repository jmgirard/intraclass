# Milestones

Ordered milestones with status and the deferrals each one recorded. **Shipped
milestones are compressed** to Goal / Status / Deferred + spec-and-ADR pointers — the
full blow-by-blow DoD (slices, oracle-by-oracle detail) lives in its ADR
(`DECISIONS.md`), its estimand-spec, and git history (ADR-015, single-source; don't
restate it here). The **M18–M21 completeness arc (ADR-027) is complete** (M21 SEM parity
shipped, PR #26), closing every arc 🔵 *not yet* gap in `COVERAGE.md`; **M22 (ADR-032) —
`d_study()` projection off a within-cell replicate fit — then shipped** (PR #27), a small
standalone milestone promoting the one deferred `d_study()` corner (M17 §7). **M23 (ADR-033) —
the first Bayesian milestone (brms engine + `ci_method = "posterior"`, two-way random) — then
shipped** (PR #28), opening the cross-cutting Bayesian carryover deferred at M7 (ADR-014). **M24
(ADR-034) — Bayesian multilevel (brms, Design 1 crossed) — then shipped** (PR #29), extending the
Bayesian engine to the crossed multilevel path (subject + cluster levels), the highest-value Bayesian
follow-on. **M25 (ADR-035) — Bayesian multilevel (brms) nested Designs 2/3 — then shipped** (PR #30),
the M8 analog of M24: the Bayesian engine now covers both nested-rater designs at the subject level,
completing brms coverage of every subject-level multilevel design. **M26 (ADR-036) — Bayesian one-way +
fixed-rater, two-way, balanced/complete — then shipped** (PR #31), the two lowest-risk single-level
follow-ons (M6 one-way / M2·M10 fixed-rater analogs); with M26 the Bayesian engine also covers the
single-level one-way and fixed-rater designs. **M27 (ADR-037) — Bayesian multilevel fixed-rater (brms),
crossed Design 1 + nested Design 2, subject level — then shipped** (PR #32), the brms sibling of the
frequentist M10 / M19 Slice 2 fixed paths (multilevel one-way was already shipped as Design 3 in M25);
its Slice-2 oracle-first fork (the raw θ²_{r:c} push-forward undercovers the nested finite population) was
resolved by a gated Fable review (#19) adopting a 2b moment correction + boundary-aware average-floor
(ADR-037 amendment). **M28 (ADR-038) — frequentist nested-fixed MC-interval coverage — then shipped**
(PR #33), the spun-off M27 corollary: the shipped `theta2r_nested_draws()` interval undercovered the
nested finite population (per-cluster floor + 1b), fixed by the shared `theta2r_moment_draws()` (2b +
boundary-aware average-floor) unified across glmmTMB/lme4/lavaan after a second gated Fable review (#19).
**M29 (ADR-039) — Bayesian conflated diagnostic + within-cell replicates, two-way random,
balanced/complete — then shipped** (PR #34), continuing the Bayesian arc with its two remaining low-risk
parity follow-ons (both variance-ratio push-forwards → no θ² moment correction, no Fable review): the
conflated Eq. 14 reads off the shipped M24 crossed fit, and `fit_brms_replicates()` splits the residual
with an `occasions` per-draw divisor. **M30 (ADR-040) — Bayesian incomplete/ragged, two-way random +
crossed multilevel random — then shipped** (PR #35), the Bayesian sibling of the frequentist M3/M9: narrowing
the one `!balanced` brms guard so the shipped `k_eff`/connectedness machinery threads through the posterior
push-forward (random-only → no θ² moment correction). Its one unknown — ragged-data coverage of the credible
interval through `k_eff` — came back **nominal** at the subject level for both slices, so no Fable review.
**M31 (ADR-041) — Bayesian incomplete/ragged FIXED-rater, two-way single level + crossed multilevel — then
shipped** (PR #36), the first deferred sibling ADR-040 named: the Bayesian sibling of the frequentist M3
(single-level fixed) / M18 Slice 1 (crossed-multilevel fixed), narrowing the same `!balanced` brms guard for
the fixed-rater paths. Here the 2b θ² moment correction (`brms_theta2r_moment_draws()`) went **live
single-level for the first time** (`b ≠ 0` on ragged fixed data), and the flagged risk — ragged
fixed-rater credible coverage — resolved **nominal** for both slices, so no Fable review. **M32 (ADR-042) —
Bayesian incomplete/ragged NESTED random, Designs 2 & 3, subject level — then shipped** (PR #37), completing
the "brms × incomplete × random" row: the Bayesian sibling of the frequentist M19, narrowing the same
`!balanced` brms guard's nested clause so the shipped M25 nested fits run on ragged data unchanged (random →
no 2b, the M30 regime). Scoped **random-only** by an oracle-first catch — incomplete *fixed* nested has no
frequentist oracle (deferred all engines, ADR-029), so it cannot ship as parity. Slice 1 (Design 2) was
nominal; **Slice 2 (Design 3) fired a gated Fable review** (#19) when the first n_rep-80 ragged coverage cell
drew .8625 — **verdict: a Monte-Carlo tail event, no estimator shortfall** (n=240 .9458, 2,000-fit
frequentist .9555, PIT uniform; ADR-042 Amendment 2), fixture regenerated at n_rep 240 with pins unchanged,
and n_rep ≥ 240 adopted as the convention for future ragged coverage cells. **M33 (ADR-043) — the Bayesian
parity mop-up (incomplete single-level one-way + fixed-rater & multilevel within-cell replicates) — then
shipped** (PR #38), closing the last clean-oracle estimand gaps on the brms ledger: each of its three corners
had a frequentist oracle (the gate), so all shipped as parity, not research (`fit_brms_oneway()` reused +
`fit_brms_replicates_fixed()` / `fit_brms_ml_replicates()` / `fit_brms_nested_replicates()` added), and
**every oracle came back nominal — no Fable review** (the M30 variance-ratio regime). **M34 (ADR-044) — the
Bayesian customization milestone (user `prior=` override + HPDI credible intervals) — then shipped** (PR #39):
interface/customization work, not new estimand (cf. M5.5/M7/M11/M16), with **reduction oracles** (defaults
reproduce shipped M23+ bit-identically) and guardrails (a classed `intraclass_custom_prior` footgun warning;
documented caveats) in place of a coverage claim — so **no Fable review**; the local `R CMD check` before the
PR caught an over-aggressive `posterior_summary` guard + an undeclared `coda` (→ `Suggests`), both fixed.
**M35 (ADR-045) — the vignette-reassessment milestone (docs: update stale claims, split `advanced.Rmd`, add
Bayesian coverage) — then shipped** (PR #40, squash-merged to `main` at `d69f39e`): a docs milestone (cf.
M4/M13, no new estimand/engine/CI machinery/dependency) fixing five materially false "planned for later"
claims, retiring the overloaded 504-line `advanced.Rmd` into four focused articles (`multilevel-designs`,
`engines`, `interval-methods`, `d-studies-and-replicates`), and documenting the M23–M34 Bayesian engine for
the first time (genuine committed brms output; no Fable review).
Each milestone is scoped by an ADR at its start
after a short retro (founding brief §7) and detailed in full here until it ships.
The arc is a hypothesis, not a contract — reorders get a
[`DECISIONS.md`](DECISIONS.md) entry (the M9–M13 tail was set by ADR-017; ADR-018
detailed M9, ADR-019 M10, ADR-020 M11, ADR-021 M12, ADR-023 M14, ADR-024 M15,
ADR-025 M16, ADR-026 M17; the M18–M21 completeness arc by ADR-027, with ADR-028 detailing
M18, ADR-029 M19, ADR-030 M20, and ADR-031 M21; ADR-032 detailed M22, ADR-033 M23, ADR-034 M24,
ADR-035 M25, ADR-036 M26, ADR-037 M27, ADR-038 M28, ADR-039 M29, ADR-040 M30, ADR-041 M31, ADR-042 M32,
ADR-043 M33, ADR-044 M34, ADR-045 M35, ADR-046 M36, ADR-047 M37, ADR-048 M38, ADR-049 M39).
**M39 (ADR-049, `d_study()` occasion-count projection) is in flight** — opened after a short retro of the
M23–M38 arc; the board is below. It is the symmetric sibling of the M22 (ADR-032) rater-count projection:
projecting the occasion count `n_o` off a balanced within-cell replicate fit (holding raters at the fitted
count), a thin projection slice, not new estimand work (#6). Prior milestone **M38** (ADR-048, brms engine
parity for the fixed multilevel cells) shipped (PR #44, squash-merged to `main` at `4124297`); it closed the
**brms** half of the (C) research/blocked corner — Cell 1 balanced fixed cluster level (M37 sibling) + Cell 2
incomplete/ragged fixed-nested Design 2 (M36 sibling), both clean guard-lifts; the Cell 2 coverage gate
(O-Bayes-IFNML) came back **NOMINAL** (C_n=80 boundary .970, no decay), so the ADR-048 stop-and-replan branch
did not fire and **no Fable** was needed. The residual (C) work is now only the genuinely-open **incomplete
cluster-level fixed** (🟣 double-blocked) and the **lavaan** siblings (blocked on the multilevel-SEM lift — the
M38 ROADMAP edit corrected the earlier "unblockable" wording); **Design 3 fixed** is already closed in code (the
ADR-029 by-design abort). Cross-cutting: cluster-signal-zero (σ²_c→0) interval coverage (M5/M9/M37 alike).

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
  Four thin vertical slices, each lifting a single shipped abort guard: **Slice 1 — incomplete
  fixed-rater crossed** (COVERAGE #9): the M9 identifiability gates + shipped
  `fit_{glmmtmb,lme4}_multilevel_fixed` with the M3 `k_eff` divisor and M10 `theta2r_fixed()` read
  from the ragged rater-contrast vcov (no fit change); balanced fixed≡random, ragged genuinely
  differs (θ²_r ≠ σ²_r), as the single-level M3 fixed path. **Slice 2 — incomplete conflated ICC**
  (COVERAGE #8): opened the question `M17-conflated-icc.md §6` left closed — Eq. 14 *lumps*
  σ²_r+σ²_cr+σ²_res into one error and σ²_c+σ²_{s:c} into one signal, so it is the flat two-way ICC
  off the five-component fit with the same flat `k_eff`; **well-posed on ragged data** (the
  attempt-then-degrade posture resolved to *ships*, no reclassification; spec §6a). **Slice 3 —
  incomplete subject-level `d_study()`** (COVERAGE #13): level-aware guard — the subject level
  projects (projection moves only the divisor `m`), the cluster level is dropped-with-note (bounded
  by the open M9 `ICC(c,k)` divisor). **Slice 4 — bootstrap-projected `d_study()` bands** (COVERAGE
  #14, the M16 deferral, package-wide): `bootstrap_ci()` exposes its resample components, a
  bootstrap fit stores them on `x$boot`, and `d_study()` reprojects them across `m` — deterministic,
  and at `m = k_eff` equal to the fitted `ICC(A,k)` bootstrap interval exactly. No new estimand
  (Slice 2 is the only spec-touching slice), no new dependency, no new argument.
- Reference: ADR-028 (scope + maintainer decisions: Slice 2 attempt-then-degrade; Slice 3/4
  split); estimand-spec `M17-conflated-icc.md §6a` (Slice 2), `M4.5-d-study.md §7.2` (Slices 3/4).
  Oracles (#1, no textbook worked example, as M8–M10/M15): O-IFML / O-conflated-incomplete /
  O-IDS / O-Boot-DS — glmmTMB↔lme4 cross-engine <1e-4 + reduction to the shipped balanced/complete
  case + seeded recovery; in `test-icc-fixed-multilevel.R`, `test-icc-multilevel.R`,
  `test-d-study.R`.

- Deferred out of M18 (record so not rediscovered): incomplete **nested** Designs 2/3 and
  **fixed-rater nested** (M19); ragged/fixed/multilevel **replicates** (M20); **SEM parity**
  (M21); the **cluster-level `ICC(c,k)` incomplete divisor** (🟣 Wave-3 research, M9 §9 — bounds
  Slice 3); `consistency`/`fixed` **conflated** (⚫/🟣, COVERAGE §④). Arc carry-overs stay in
  `ROADMAP.md`: Bayesian engine + `ci_method = "posterior"`; categorical/ordinal GLMM; one-way
  via SEM (blocked, ADR-014); non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge
  cases.
- Status: **done** (Slices 1–4 + cross-cutting DoD; merged via PR #23 at 7dffbb2; full CI matrix
  green incl. Windows and R-devel, 779 tests). Incomplete fixed-rater crossed multilevel,
  incomplete conflated ICC, incomplete subject-level `d_study()`, and bootstrap-projected
  `d_study()` bands all ship; `R CMD check --as-cran` 0/0/0. First milestone of the M18–M21 arc.

## M19: Multilevel completeness II — nested Designs 2/3 (incomplete + fixed-rater) (ADR-029)
- Goal: bring the **nested** designs (Design 2, raters nested in clusters; Design 3, raters nested
  in subjects) up to the incomplete + fixed-rater parity the crossed Design 1 reached in M9/M10/M18
  — second milestone of the M18–M21 arc (ADR-027). **Completeness, not new estimand work** (cf.
  M14/M15/M18): each slice lifts a single shipped abort guard. **Slice 1 — incomplete nested**
  (COVERAGE #10): ragged Designs 2/3 fit; the averaged `k_eff` divisor reduces *exactly* to the
  pinned M3 two-way / M6 one-way incomplete divisor (decision B — shipped, no research degrade);
  ambiguous ragged data requires an explicit `design=` (decision A). **Slice 2 — fixed-rater nested
  Design 2** (COVERAGE #11, decision C): new `fit_{glmmtmb,lme4}_nested_fixed`
  (`score ~ 0 + rater + (1|cluster:subject)`) + new engine-agnostic `theta2r_fixed_nested()`
  (θ²_{r:c} = mean over clusters of each cluster's finite-population rater variance), both engines.
  **Oracle-first catch:** unlike crossed M10, fixed ≢ random even on balanced data for nested
  (per-cluster finite population) — pinned by per-cluster + single-cluster reduction to flat M3
  fixed θ²_r, cross-engine, consistency≡random. Design 3 fixed ⚫ by-design. No new dependency, no
  new argument.
- Reference: ADR-029 (scope + maintainer decisions A/B/C + the oracle-first catch); no new
  estimand-spec. Oracles O-NML/incomplete (`test-icc-nested-multilevel.R`), O-FNML
  (`test-icc-fixed-multilevel.R`); provenance `data-raw/oracle-{nested,fixed}-multilevel.R`.
- Deferred out of M19 (record so not rediscovered): the averaged crossed cluster-level `ICC(c,k)`
  incomplete divisor (🟣 Wave-3 research, M9 §9 — **not** M19); Design 3 fixed-rater (⚫ by-design,
  decision C); nested cluster-level IRR (⚫ undefined for nested raters, ten Hove p. 6);
  ragged/fixed/multilevel **replicates** (M20); **SEM parity** (M21). Arc carry-overs stay in
  `ROADMAP.md`: Bayesian engine + `ci_method = "posterior"`; categorical/ordinal GLMM; one-way via
  SEM (blocked, ADR-014); non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–2; merged via PR #24 at 53c9f5e; full CI matrix green incl. Windows
  and R-devel, 813 tests). `R CMD check --as-cran` 0/0/0. Second milestone of the M18–M21 arc.

## M20: Within-cell replicate completeness — fixed-rater, multilevel, ragged (ADR-030)
- Goal: extend the M17 Slice 3 within-cell replicate estimand (residual σ²_res split into the
  subject×rater interaction σ²_sr and pure error σ²_e via `(1|subject:rater)`, the per-component
  `error_divisors`, the `occasions` knob) beyond its **two-way random, single-level,
  balanced/complete** scope to the three corners M17 §7 deferred — third milestone of the M18–M21
  completeness arc (ADR-027). **Completeness, not new estimand work** (cf. M14/M15/M18/M19): each
  slice lifts a **single shipped abort guard** onto machinery oracle-pinned elsewhere. Additive,
  non-breaking (#6) — no new argument, no new dependency, only new valid combinations of the
  shipped `raters` / `cluster` / `design` / `occasions` args and data balance. Three thin vertical
  slices, **reordered from ADR-027's tentative ragged→fixed→multilevel to oracle-risk order**
  (maintainer decision, as M18 reordered): **Slice 1 — fixed-rater replicates** (COVERAGE §② #5,
  lowest risk): new `fit_{glmmtmb,lme4}_replicates_fixed` (`score ~ 1 + rater + (1|subject) +
  (1|subject:rater)`) puts the M10 bias-corrected finite-population **θ²_r** (shipped
  `theta2r_fixed()`) in the rater slot; consistency ≡ random exactly, **balanced fixed ≡ random**
  (exact reduction pin, M10 crossed identity); balanced/complete, single-level. **Slice 2 —
  multilevel replicates** (COVERAGE §② #6, **crossed Design 1 + nested Design 2**, maintainer
  decision): add `(1|cluster:subject:rater)` to the M5/M8 fits (Design 1 → six components, Design
  2 → five), new `fit_{glmmtmb,lme4}_multilevel_replicates` reusing the generic `*_ml_contract`;
  the `occasions` facet reduces only pure error by n_o. **Design 3 replicate-split ⚫ by-design**
  (multilevel one-way, no separable subject:rater interaction) — classed abort. Balanced/complete.
  **Slice 3 — ragged/incomplete replicates** (COVERAGE §② #4, the one genuine characterization,
  two-way random single-level): the **single-occasion** family extends via the shipped `k_eff`
  (distinct raters per subject) + M3 connectedness; the **occasion-averaged** coefficient needs an
  **effective-n_o divisor** — **attempt, degrade to 🟣 research** if no #1/#4-strong oracle holds
  (maintainer decision, matching M18 S2 / M19 S1). No estimand-spec file (extends
  `M17-within-cell-replicates.md` §2/§4/§7).
- Reference: ADR-030 (scope + maintainer decisions: oracle-risk reorder; crossed D1 + nested D2 for
  Slice 2; attempt-then-degrade for the ragged averaged divisor); no new estimand-spec (extends
  `M17-within-cell-replicates.md`). Oracles (#1, no textbook worked example, as M8–M10/M15/M18/M19):
  O-FRep / O-MLRep / O-RagRep — glmmTMB↔lme4 cross-engine <1e-4 + reduction to the shipped M17
  balanced/complete replicate case and (via aggregation to cell means) to the single-occasion
  parent (M10/M3 fixed for S1; M5/M8 multilevel for S2; M3 incomplete two-way for S3) + seeded
  recovery with MC-CI coverage + the σ²_sr + σ²_e ≈ σ²_res invariant; in `test-replicates.R`
  (+ `test-icc-multilevel.R` for S2).

- Deferred out of M20 (record so not rediscovered): **ragged × fixed** and **ragged ×
  multilevel** replicates (compound imbalance — later corners, as ragged×fixed nested was for M19);
  **Design 3 / one-way replicate-split** (⚫ by-design — no separable interaction); the **occasion
  `d_study()`** projecting n_o (M17 §7 — the per-component divisor supports it, projection stays
  deferred); **SEM ∩ replicates** (ROADMAP unscheduled, reclassified out of the arc, ADR-027).
  Arc carry-overs stay in `ROADMAP.md`: the Wave-3 averaged crossed cluster-level `ICC(c,k)`
  incomplete divisor (🟣 research, M9 §9); **SEM parity** (M21); Bayesian engine + `ci_method =
  "posterior"`; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014);
  non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases. Two corners degraded
  at close: the **occasion-averaged coefficient on ragged replicates** (🟣 research — no validated
  effective-`n_o` divisor, Slice 3 attempt-then-degrade) and **`d_study()` projection off a
  replicate fit** (needs per-component error divisors; refused loudly).
- Status: **done** (Slices 1–3 + finish-task fix; merged via PR #25 at 137fb98; full CI matrix
  green incl. Windows and R-devel, 894 tests). `R CMD check --as-cran` 0/0/0. Slice 1 fixed-rater
  (`fit_{glmmtmb,lme4}_replicates_fixed`, θ²_r); Slice 2 multilevel (`fit_{glmmtmb,lme4}_ml_replicates`
  crossed + `_nested_replicates`, `multilevel_replicate_facts()`) + a `d_study()`-on-replicate
  correctness guard; Slice 3 ragged single-occasion (no new fit). Occasion-averaged-ragged degraded
  to 🟣 research. Third milestone of the M18–M21 arc; only M21 (SEM parity) remains.

## M21: SEM (lavaan) engine parity — bootstrap, fixed-rater, incomplete/FIML (ADR-031)
- Goal: bring the **lavaan (SEM) engine** up toward the design parity lme4 reached over
  M5.5→M14→M15 — the **last** milestone of the M18–M21 completeness arc (ADR-027). M7 (ADR-014)
  shipped lavaan for the random two-way, balanced/complete path only; M21 promoted the three
  lavaan deferrals ADR-014 recorded, **engine parity not new estimand work** (cf. M5.5/M7/M14/M15):
  additive, non-breaking (#6) — no new argument/dependency/estimand-spec, only new valid
  combinations of `engine = "lavaan"`. **Slice 1 — bootstrap:** `ci_method = "bootstrap"` via the
  M16 `simulate_refit` seam (`lavaan_simulate_refit` — parametric bootstrap from the fitted SEM's
  implied moments → refit → recompute the ICC per resample). **Slice 2 — fixed raters:** the SEM fit
  is unchanged (rater effects always live in the mean structure as k intercepts); fixed raters read
  the McGraw & Wong **Case-3A bias-corrected θ²_r = max(0, raw − bias)** (theta2r_fixed()'s
  correction with the identity contrast) — a **distinct** estimator from M7's raw σ²_r that reduces
  to **both** glmmTMB Case-3A fixed **and** random σ²_r on balanced data (the M10 identity). **Slice
  3 — incomplete/FIML:** missing cells estimated by FIML (`missing = "fiml"`); attempt-then-degrade
  **resolved to ships** (consistency ≤8e-3, agreement ≤1.5e-2 vs glmmTMB — the same raw-SEM
  small-sample bias as complete data, not a FIML artifact); bootstrap gated on incomplete data.
  Multilevel SEM and one-way SEM stayed out (reclassified/blocked, ADR-027/014).
- Reference: ADR-031 (scope + maintainer decisions: keep slice order; FIML attempt-then-degrade);
  no new estimand-spec (engine, not estimand — cf. M5.5/M7/M14/M15). Oracles glmmTMB-as-independent-
  oracle (as M7): O2 bootstrap (coverage on the estimator-invariant consistency ratio + bootstrap ≈
  MC + cross-engine consistency), O-FSEM (distinct-from-raw + reduction to glmmTMB fixed AND random),
  O-FIML (cross-engine consistency + agreement on ragged data + population recovery + gated
  incomplete-bootstrap + disconnected-ragged abort); asserted in `test-ci-bootstrap.R` and
  `test-icc-lavaan.R`, O-SEM row extended in `REFERENCES.md`.
- Deferred out of M21 (record so not rediscovered): **fixed × incomplete SEM** and any compound
  corner (one dimension at a time, as M10 was to M9); **multilevel SEM** (COVERAGE #12 — cross-cutting
  "later" bucket beside Bayesian, ADR-027); **SEM ∩ within-cell replicates** (#7 — ROADMAP
  unscheduled, ADR-027); **one-way / general ICC(1) via SEM** (🔴 blocked, no faithful sourced route,
  ADR-014). Arc carry-overs stay in `ROADMAP.md`: the Wave-3 averaged crossed cluster-level
  `ICC(c,k)` incomplete divisor (🟣 research, M9 §9); Bayesian engine + `ci_method = "posterior"`;
  categorical/ordinal GLMM; non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–3 + cross-cutting DoD; merged via PR #26 at ee81e6f; full CI matrix
  green incl. Windows and R-devel, 925 tests). `R CMD check --as-cran` 0/0/0. Slice 1 bootstrap
  (`lavaan_simulate_refit`); Slice 2 fixed-rater (`fit_lavaan(raters=)`, Case-3A θ²_r); Slice 3
  incomplete/FIML (`missing = "fiml"`, ships — no research degrade). **Final milestone of the
  M18–M21 arc — every 🔵 not-yet gap in `COVERAGE.md` is closed.**

## M22: `d_study()` projection off a within-cell replicate fit (ADR-032)
- Goal: promote the one deferred `d_study()` corner (M17 §7 / M20; the COVERAGE `d_study()`
  table's last 🔵) — projecting the rater count `m` off a within-cell replicate fit. A small
  standalone milestone after the M18–M21 arc; **completeness, not new estimand work** (cf.
  M14/M15/M18–M21): additive, non-breaking (#6) — no new argument, dependency, or estimand-spec
  file. A replicate fit splits the residual into the subject×rater interaction σ²_sr and pure
  error σ²_e, so projection needs **per-component error divisors** (rater and interaction ÷ the
  projected `m`, pure error ÷ `m·n_o`) — which `icc_estimand()` already carries from M17, so the
  ROADMAP's stated blocker was already resolved and the work is confined to `d_study()` (which
  previously refused every replicate fit). Two thin slices: **Slice 1 — single-level** two-way
  replicate projection (random agreement/consistency; **fixed consistency** via Spearman–Brown;
  **fixed absolute agreement** still refused — θ²_r is a finite population), emitting one curve
  per occasion setting on the fit (a new `occasions` column, paralleling the multilevel `level`
  column), holding `n_o` fixed; **Slice 2 — multilevel** (crossed Design 1 + nested Design 2)
  projecting the subject level across occasion settings and the cluster level single-occasion
  (occasion averaging touches only pure error, absent from the cluster error set). The occasion
  count projection and ragged-replicate projection stay deferred (the ragged occasion-averaged
  divisor is 🟣 research, M20/ADR-030).
- Reference: ADR-032 (scope + the maintainer's do-both-in-two-slices decision); no new
  estimand-spec — extends `M17-within-cell-replicates.md §7` and `M4.5-d-study.md §7`. Oracles
  **O-RepDS** (glmmTMB the independent oracle, as M8–M10/M15/M18–M21): reduction — at `m = k_eff`
  each level/occasion curve equals the fitted `ICC(*,k)` (< 1e-4); cross-engine glmmTMB↔lme4
  (< 1e-4); Spearman–Brown for consistency; seeded-coverage recovery at an `m` not run;
  monotone/[0,1] and occasion-averaged ≥ single-occasion invariants; in `test-d-study.R`.
- Deferred out of M22 (record so not rediscovered): the **occasion `d_study()`** projecting `n_o`
  (M17 §7 — the per-component divisor supports it, projecting occasions stays out); **ragged ×
  replicate** projection (bounded by the 🟣 research occasion-averaged ragged divisor, M20/ADR-030);
  **fixed × multilevel** replicate fits (never fitted, M20 Slice-1 scope-out); **SEM ∩ replicates**
  (ROADMAP unscheduled, ADR-027). Arc carry-overs stay in [`ROADMAP.md`](ROADMAP.md): the Wave-3
  averaged crossed cluster-level `ICC(c,k)` incomplete divisor; Bayesian engine + `ci_method =
  "posterior"`; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014).
- Status: **done** (Slices 1–2; merged via PR #27 at `8375184`; full CI matrix green incl. Windows
  and R-devel — all 9 jobs). `d_study()` projects the rater count off single-level and multilevel
  (crossed D1 + nested D2) within-cell replicate fits, one curve per occasion setting; occasion
  projection and ragged-replicate projection stay deferred. Standalone milestone after the M18–M21
  arc; no new estimand/dependency.

## M23: Bayesian engine (brms) + `ci_method = "posterior"` — two-way random (ADR-033)
- Goal: the **first Bayesian milestone** — promote `brms` to a selectable `engine = "brms"` for the
  two-way random path and add a native **`ci_method = "posterior"`** (percentile credible intervals
  from posterior draws), opening the cross-cutting Bayesian carryover deferred at M7 (ADR-014). A
  **thin two-way-random slice** mirroring the first engine milestones M5.5 (lme4) and M7 (lavaan);
  **engine + interval method, not new estimand work** (cf. M5.5/M7/M16): additive, non-breaking (#6)
  — no new estimand-spec file, new *values* of the shipped `engine`/`ci_method` args only. Backend
  **brms** (rstan, new `Suggests` behind `check_installed()` — ADR-002 light install; rstanarm
  parked). Prior **half-*t*(4, 0, 1) on all random-effect SDs**, sourced to ten Hove et al. (2020)
  §3.3/§4.1 (#12). **Point estimate = MAP** (mode of each estimand's ICC draws — both point and
  interval from one draw matrix, since `MAP(ICC) ≠ icc_point(MAP components)`), via a hand-rolled
  boundary-aware `posterior_mode()` (reflected KDE, a-priori-fixed bandwidth; **no new dependency**);
  the EAP/mean is not used (biased, ten Hove 2020 §4.2). **Interval = percentile** credible interval,
  reusing M16's `bootstrap_interval()` reduction. **Coupling: `"posterior"` forced-default &
  Bayesian-only** (classed aborts otherwise; selectable coupling parked). Soft `cli` note at k = 2
  (bias/undercoverage caveat, #13). Corroborated by ten Hove et al. (2022): its companion software
  uses brms, reports MCMC ≈ MLE point estimates, and endorses MC-CIs for non-normal ICCs.
- Reference: ADR-033 (scope + all maintainer decisions from the planning session); no new
  estimand-spec (engine + interval method — cf. M5.5/M7/M16); the coefficients are the M1/M2 family
  (`estimand-specs/M1-twoway-random-agreement.md`, `M2-consistency-and-fixed.md`). Oracles **O-Bayes**
  (a CI method's oracle is coverage, #1; no worked-example point — ten Hove 2020 is a simulation
  study): coverage ~nominal + MAP unbiased + percentile-BCI nominal at k > 2 reproducing ten Hove
  2020's reported findings (committed seeded reference vs OSF `shkqm`, #4); cross-implementation
  (our brms vs their rstan); MAP ≈ glmmTMB/lme4 REML within a stated tolerance; 100% convergence.
- Deferred out of M23 (record so not rediscovered): Bayesian **fixed-rater** (Case-3A θ²_r) and
  **one-way** (single-level parity — a follow-on, the M14 analog); Bayesian **multilevel** Designs
  1–3 (the highest-value follow-on — ten Hove's native turf) and Bayesian **incomplete/ragged** and
  **within-cell replicates** (per ten Hove 2022 the estimator choice there is an open research
  question → lean on coverage calibration when scheduled); **rstanarm** alternate backend;
  **selectable** `posterior` coupling (MC/bootstrap on a Bayesian fit for method comparison); **HPDI**
  intervals; a **user-exposed `prior=`** API; `modeest`/`bayestestR` mode estimators. Untouched
  carry-overs stay in [`ROADMAP.md`](ROADMAP.md): the Wave-3 averaged crossed cluster-level
  `ICC(c,k)` incomplete divisor; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014);
  non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #28 at `a6b8467`; full CI matrix
  green incl. Windows and R-devel — all 9 jobs). `R CMD check --as-cran` 0/0/1 (only the expected
  "New submission" NOTE); installed-pkg suite 308/0/0 incl. the live brms fit. First Bayesian
  milestone: `engine = "brms"` + `ci_method = "posterior"` (half-*t*(4,0,1) prior, MAP point +
  percentile credible interval) on the two-way random path; `brm_args` passthrough (ADR-033
  amendment); `brms_convergence()` + the parallel-`cores` nudge; O-Bayes coverage oracle
  (`data-raw/oracle-bayesian.R` + committed `tests/testthat/fixtures/bayesian-oracle.rds`,
  reproducing ten Hove 2020's findings with two reported divergences). The live Stan fit is
  `skip_on_ci()` (CI has no Stan toolchain); CI covers the Bayesian path via the committed fixture.

## M24: Bayesian multilevel (brms) — Design 1 crossed, balanced/complete, random (ADR-034)
- Goal: the **highest-value Bayesian follow-on** — extend `engine = "brms"` + `ci_method =
  "posterior"` from M23's two-way random path to the **five-component crossed (Design 1) multilevel**
  fit (ten Hove's *native turf*). The most source-faithful coefficient in the package: ten Hove,
  Jorgensen & van der Ark's **own** multilevel IRR estimator (2020/2022) **is** the half-*t*-hyperprior
  Bayesian model M23 built, so M24 fits the paper's estimator on the paper's flagship design. A **thin
  vertical slice** standing to M23 as **M5 stood to M1/M2**: same engine + interval method, extended
  fit. **Engine/interval parity, not new estimand work** (cf. M5.5/M7/M16/M23) — the shipped M5
  subject/cluster coefficients (`M5-multilevel.md` §3, ten Hove 2022 Eqs. 12–13, Table 3) read off
  posterior draws; additive, non-breaking (#6): a new valid `engine = "brms"` × multilevel
  combination, **no new estimand-spec, no new argument, no new dependency** (`brms` already a
  `Suggests`). Scope = the M5 box: **Design 1 crossed, balanced/complete, `raters = "random"`, subject
  + cluster levels, agreement/consistency, single/average.** The fit is M5's
  `score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | rater) + (1 | cluster:rater)` under
  half-*t*(4, 0, 1) on **all five** random-effect SDs (the M23 prior generalizes verbatim — literally
  ten Hove 2020 §3.3/§4.1's spec for this model). MAP point + percentile credible interval, `posterior`
  forced-default & Bayesian-only, all unchanged from M23. Few clusters is where the half-*t* prior
  earns its keep — it regularizes the boundary-prone σ²_c / σ²_{cr} (#3).
- Reference: ADR-034 (scope + the maintainer's *multilevel-first, thin* decision); no new
  estimand-spec — `estimand-specs/M5-multilevel.md` (§1 scope, §2 fit, §3 estimands, §5 oracles/DGP,
  §7 identifiability) is the estimand of record. Oracles **O-Bayes-ML** (a CI method's oracle is
  coverage, #1; no textbook worked point — as M5/M23): O-Bayes-ML-coverage (seeded coverage ~nominal
  at ten Hove's multilevel DGP, off a committed fixture, #4); O-Bayes-ML-reduction (single-cluster /
  σ²_c → 0 collapses to the M23 two-way Bayesian fit within tolerance + the algebraic subject≡single
  invariant); O-Bayes-ML-agree (MAP ≈ M5 glmmTMB/lme4 REML within a stated tolerance — the inverted
  M5 oracle relationship); O-Bayes-ML-converge.

- Deferred out of M24 (record so not rediscovered): Bayesian **nested Designs 2/3** (M8/M19 analog),
  **fixed-rater** multilevel (Case-3A θ²_r from the posterior of rater contrasts — M10 analog),
  **one-way** (M6 analog), **incomplete/ragged** multilevel (M9 analog), **within-cell replicates**
  (M17/M20 analog), and the **conflated** diagnostic (Eq. 14) — each a later thin slice; per ten Hove
  2022 the incomplete/small-k estimator choice is an open research question → those lean on coverage
  calibration when scheduled. Plus the M23 carry-overs: **rstanarm** backend, **selectable**
  `posterior` coupling, **HPDI** intervals, a **user-exposed `prior=`** API. Untouched carry-overs
  stay in [`ROADMAP.md`](ROADMAP.md): the Wave-3 averaged crossed cluster-level `ICC(c,k)` incomplete
  divisor; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014);
  non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–2 + all cross-cutting DoD; merged via PR #29 at `6566057`; full CI matrix
  green incl. Windows and R-devel — all 9 jobs). Local `R CMD check --as-cran` 0/0/1 (only the expected
  "New submission" NOTE); full suite `NOT_CRAN=true` 1041/0/0/0 incl. both live brms fits + merDeriv
  lme4 multilevel. `engine = "brms"` + `ci_method = "posterior"` now covers the **crossed (Design 1)
  multilevel** path (subject + cluster levels) under the half-*t*(4,0,1) prior — ten Hove's own
  estimator on the paper's flagship design. **Slice 1** `fit_brms_multilevel()` (+ `fit_brms_common()`
  refactor; `spec`-generalized draws/convergence; guard narrowing + dispatch) + O-Bayes-ML-agree;
  **Slice 2** cluster-level + O-Bayes-ML-coverage (new `data-raw/oracle-bayesian-multilevel.R` +
  committed `bayesian-ml-oracle.rds`) + O-Bayes-ML-reduction. Findings reproduced honestly (#18):
  subject-level nominal (rel-bias −1.5%, cover .94 at k = 5), cluster-level few-cluster MAP-low caveat
  (−16%/−25% at N_c = 20, wide intervals still ~nominal). Live Stan fits `skip_on_ci()`; CI covers via
  the committed fixture.

## M25: Bayesian multilevel (brms) — nested Designs 2/3, subject level (ADR-035)
- Goal: continue the Bayesian arc — extend `engine = "brms"` + `ci_method = "posterior"` from M24's
  crossed (Design 1) multilevel path to the paper's two **nested-rater** designs at the **subject
  level** (raters nested in clusters, Design 2, four-component; raters nested in subjects, Design 3,
  three-component / multilevel one-way, agreement-only), the **M8 analog of M24**. Engine/interval
  parity, not new estimand work (cf. M5.5/M7/M16/M23/M24) — the shipped M8 subject-level coefficients
  read off posterior draws; additive, non-breaking (#6), no new estimand-spec/argument/dependency.
  With M25, `engine = "brms"` covers **every multilevel design the frequentist engines fit at the
  subject level.** Balanced/complete, random, half-*t*(4,0,1) prior verbatim; MAP + percentile credible
  interval. **Slice 1** Design 2 (`fit_brms_nested_clusters()`; σ²_{r:c} in the internal `rater` slot;
  brms guard narrowed + dispatch) + O-Bayes-NML-agree. **Slice 2** Design 3 (`fit_brms_nested_subjects()`,
  agreement-only; `ICC(1)`/`ICC(k)`) + O-Bayes-NML-reduction (→ flat one-way as σ²_c→0) + the committed
  coverage fixture via companion `data-raw/oracle-bayesian-nested.R`. **Honest finding (#18):** the
  nested subject level is ~unbiased even at k=2 (rel-bias < .01, nominal coverage, 100% convergence) —
  no boundary-prone cluster estimand is exposed (nested = no cluster ICC); the a-priori "k=2 more
  biased low" pin imported from M24 didn't hold and was corrected to the run, not tuned (#4).
- Reference: ADR-035 (scope + the maintainer's *both-designs, one milestone* decision); no new
  estimand-spec — `estimand-specs/M8-nested-multilevel.md` is the estimand of record. Oracles
  **O-Bayes-NML** (coverage #1; no textbook point — as M8/M24): -agree (MAP ≈ M8 glmmTMB/lme4 REML),
  -coverage/-converge (committed `tests/testthat/fixtures/bayesian-nested-oracle.rds`), -reduction
  (Design 3 → flat one-way), asserted in `tests/testthat/test-icc-brms.R` (`REFERENCES.md`).
- Deferred out of M25 (record so not rediscovered): Bayesian **fixed-rater** multilevel (crossed M10 /
  nested M19 analogs), **one-way** (M6 analog), **incomplete/ragged** multilevel (M9/M19 analog),
  **within-cell replicates** (M17/M20 analog), and the **conflated** diagnostic (Eq. 14) — each a later
  thin slice; per ten Hove 2022 the incomplete/small-k estimator choice is an open research question →
  those lean on coverage calibration. Plus the M23 carry-overs: **rstanarm** backend, **selectable**
  `posterior` coupling, **HPDI** intervals, a **user-exposed `prior=`** API. Untouched carry-overs stay
  in [`ROADMAP.md`](ROADMAP.md): the Wave-3 averaged crossed cluster-level `ICC(c,k)` incomplete divisor;
  categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014); non-parametric/profile-likelihood CIs;
  lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–2 + all cross-cutting DoD; merged via PR #30 at `2ff081b`; full CI matrix
  green incl. Windows and R-devel — all 9 jobs). `R CMD check` 0/0/0; `test-icc-brms.R` 120/0/0 with
  live Stan. `engine = "brms"` + `ci_method = "posterior"` now covers the nested Designs 2/3 at the
  subject level (Design 2 agreement/consistency; Design 3 agreement-only, the multilevel one-way) under
  the half-*t*(4,0,1) prior — completing brms coverage of every subject-level multilevel design.
  **Slice 1** `fit_brms_nested_clusters()` + guard narrowing/dispatch + O-Bayes-NML-agree; **Slice 2**
  `fit_brms_nested_subjects()` + O-Bayes-NML-reduction + the committed coverage fixture (companion
  `data-raw/oracle-bayesian-nested.R`, n_rep 80) driving O-Bayes-NML-coverage/-converge on CI.
  Findings reproduced honestly (#18): nested subject level ~unbiased even at k=2, nominal coverage;
  no cluster-level estimand exposed. Live Stan fits `skip_on_ci()`; CI covers via the committed fixture.

## M26: Bayesian engine (brms) — one-way + fixed-rater, two-way, balanced/complete (ADR-036)
- Goal: continue the Bayesian arc with its two lowest-risk **single-level** follow-ons — extend
  `engine = "brms"` + `ci_method = "posterior"` to **one-way random** (M6 analog) and **fixed-rater**
  two-way (M2/M3/M10 analog; the brms sibling of the lavaan fixed path M21 shipped). Engine/interval
  parity, not new estimand work (cf. M5.5/M7/M16/M21/M23/M24/M25) — the shipped one-way (SF Case 1)
  and fixed-rater finite-population (McGraw & Wong Case-3A θ²_r) coefficients read off posterior
  draws; additive, non-breaking (#6), no new estimand-spec/argument/dependency. **Slice 1**
  `fit_brms_oneway()` (`score ~ 1 + (1|subject)`, a strict subset of `fit_brms_twoway()`; one-way brms
  abort removed + dispatch) + O-Bayes-OW. **Slice 2** `fit_brms_fixed()` (`score ~ 1 + rater +
  (1|subject)`; θ²_r read **raw** per posterior draw from the rater fixed-effect draws, injected as the
  `rater` `draws` row; fixed brms abort narrowed to fixed×multilevel + dispatch) + O-Bayes-Fixed.
  **Oracle-first resolution (Slice 2, the ADR-gated step):** brms has a prior, so (a) **no** frequentist
  bias correction on the posterior draws (it moves MAP ICC(A,1) by ~0.002 and double-counts the
  uncertainty the posterior already integrates), and (b) the balanced `fixed ≡ random` identity (exact
  under REML/FIML in M10/M21) holds only **approximately** — so O-Bayes-Fixed pins **containment**
  (glmmTMB fixed inside the credible interval), not pointwise equality (#18). **Honest finding (Slice 1,
  #18):** contrary to the a-priori guess, the one-way `ICC(1)` MAP **is** biased low ~−12% at k=2 (same
  skewed-small-sample mechanism as two-way), coverage nominal — so the `icc()` k=2 caveat note fires for
  one-way too (an earlier gate reverted).
- Reference: ADR-036 (scope + both-slices/oracle-risk-order/attempt-then-degrade decisions + the
  oracle-first catch); no new estimand-spec — one-way reuses `estimand-specs/M6-oneway.md`, fixed-rater
  reuses `M3-incomplete-designs.md §6` / `M10-fixed-multilevel.md §2` (θ²_r). Oracles **O-Bayes-OW**
  (one-way: committed coverage fixture `bayesian-oneway-oracle.rds`, convergence 1.00, k=5 cover .94;
  live SF `ICC(1)=0.166`/`ICC(1,k)=0.443` inside the credible interval) / **O-Bayes-Fixed** (fixed:
  committed `bayesian-fixed-oracle.rds`, n_rep 200, cover .935, MAP rel-bias −.050; live SF ICC2
  0.290/0.620 via the M10 identity + ICC3 0.715/0.909 inside the credible interval), asserted in
  `tests/testthat/test-icc-brms.R` (`REFERENCES.md`).
- Deferred out of M26 (record so not rediscovered): Bayesian **fixed-rater & one-way at the multilevel
  level** (crossed M10 / nested M19 / Design-3 analogs), Bayesian **incomplete/ragged** (M9/M19
  analog), **within-cell replicates** (M17/M20 analog), the **conflated** diagnostic (Eq. 14), and
  Bayesian **numeric-unit `d_study()`** — each a later thin slice. Plus the M23 carry-overs: **rstanarm**
  backend, **selectable** `posterior` coupling, **HPDI** intervals, a **user-exposed `prior=`** API.
  Untouched carry-overs stay in [`ROADMAP.md`](ROADMAP.md): the Wave-3 averaged crossed cluster-level
  `ICC(c,k)` incomplete divisor; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014);
  non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.
- Status: **done** (Slices 1–2 + all cross-cutting DoD; merged via PR #31 at `c02bc38`; CI green).
  `R CMD check --as-cran` **0/0/1** (only the expected "New submission" NOTE); test suite
  `FAIL 0 | WARN 0 | SKIP 34 | PASS 949`; all 7 live Stan fits pass locally (`skip_on_ci` — CI has brms
  but no Stan toolchain, committed fixtures cover the Bayesian path). `engine = "brms"` now covers the
  single-level one-way and fixed-rater designs alongside the two-way + multilevel random paths. Both
  oracle-first findings reproduced honestly (#18): one-way k=2 MAP-low (k=2 note ungated for one-way);
  raw θ²_r + approximate balanced `fixed ≡ random` (containment oracle). `air`/`lint_package` clean.

## M27: Bayesian multilevel (brms) — fixed-rater, crossed Design 1 + nested Design 2, subject level (ADR-037)
- Goal: continue the Bayesian arc with its remaining well-scoped follow-on — extend `engine = "brms"` +
  `ci_method = "posterior"` to **fixed-rater at the multilevel level**, the brms sibling of the
  frequentist M10 (crossed Design 1 fixed) and M19 Slice 2 (nested Design 2 fixed). Engine/interval
  parity, not new estimand work (cf. M5.5/M7/M16/M21/M23/M24/M25/M26) — the shipped fixed-rater
  finite-population (McGraw & Wong Case-3A) θ²_r placed in the M5/M8 multilevel subject-level
  decomposition, now read off posterior draws; additive, non-breaking (#6), no new
  estimand-spec/argument/dependency. **Subject level only**, balanced/complete. **Disambiguation
  (ADR-037):** Bayesian multilevel *one-way* is **already shipped** — it is Design 3 (raters nested in
  subjects), shipped as brms in M25 Slice 2; `model = "oneway"` + `cluster` is ⚫ by-design. So M27 is
  **fixed-rater only**, and corrects the stale "fixed/one-way at the multilevel level" deferral wording in
  the tracking files. **Slice 1** `fit_brms_multilevel_fixed()` (`score ~ 1 + rater + (1|cluster) +
  (1|cluster:subject) + (1|cluster:rater)`; θ²_r read **raw** per posterior draw from the rater
  fixed-effect draws, injected as the `rater` `draws` row; brms crossed-D1 guard narrowed to admit
  `raters = "fixed"` + dispatch) + O-Bayes-FML. **Slice 2** `fit_brms_nested_fixed()` (`score ~ 0 + rater
  + (1|cluster:subject)`; θ²_{r:c} = mean over clusters of each cluster's finite-population rater variance,
  per posterior draw; brms nested-D2 guard narrowed + dispatch) + O-Bayes-FNML.
  **Oracle-first resolution (both slices, the ADR-gated step, #1/#18):** brms has a prior, so (a) **no**
  frequentist bias correction on the posterior θ²_r / θ²_{r:c} draws (the posterior already integrates the
  uncertainty the correction removes from a point estimate), and (b) the balanced fixed-vs-random
  relationship holds only **approximately** under the prior — crossed `fixed ≡ random` (exact in REML M10)
  approximately, nested `fixed ≢ random` (the M19 catch) persists — so the oracle is **containment**
  (glmmTMB fixed inside the credible interval) + coverage, **not** pointwise equality. **Attempt-then-
  degrade** (matching M18 S2 / M19 S1 / M26 S2): slices are independent; Slice 1 ships even if Slice 2's
  oracle fails to resolve.
- Reference: ADR-037 (scope + both-slices/oracle-risk-order/attempt-then-degrade decisions + the
  one-way disambiguation + the oracle-first catch); no new estimand-spec — crossed fixed reuses
  `estimand-specs/M10-fixed-multilevel.md §2` (θ²_r), nested fixed reuses the M19 nested-fixed θ²_{r:c}
  estimand. Oracles **O-Bayes-FML** (crossed D1) / **O-Bayes-FNML** (nested D2), asserted in
  `tests/testthat/test-icc-brms.R`; committed coverage fixtures via `data-raw/oracle-bayesian-multilevel-fixed.R`
  (`REFERENCES.md`). Brief §8 per-milestone DoD.

- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #32 at `0a93fe6`; full CI matrix
  green incl. Windows and R-devel). **Slice 1 — crossed D1 fixed** (`fit_brms_multilevel_fixed()`; shared
  `brms_theta2r_draws()`) shipped with O-Bayes-FML (coverage .95, containment 1.00). **Slice 2 — nested D2
  fixed** (`fit_brms_nested_fixed()` = `score ~ 0 + rater + (1|cluster:subject)`) hit the ADR-anticipated
  oracle-first FORK — the **raw** θ²_{r:c} push-forward undercovers the nested finite population (coverage
  .86, →0 as clusters accrue, an incidental-parameters pathology) — resolved by a **gated Fable review
  (#19, ADR-037 amendment):** subtract **2b** per draw (`b = tr(C·Σ_post)/(k−1)` = σ²_res/n_s; **two**
  inflations — push-forward + plug-in of the center — the Bayesian MAP reads off the draws so needs both,
  the frequentist point removes one), **floor the per-draw cluster AVERAGE** not each cluster (per-cluster
  flooring → zero boundary coverage, #3), and **unify** the crossed/single-level helper to the same path
  (`brms_theta2r_moment_draws()`; 2b ≈ 0 there). Regenerated oracles match Fable's derived predictions:
  O-Bayes-FNML interior coverage **.95**/MAP −.017, boundary(θ²=0) **1.00**; O-Bayes-FML **.95**. Scopes
  ADR-036's "posterior integrates it" rationale (true for linear functionals, false for the convex
  quadratic variance functional). Multilevel one-way was already brms (Design 3, M25) — the stale deferral
  wording corrected. `R CMD check --as-cran` 0/0/1; full suite 1175 pass / 0 fail; all 9 live Stan fits
  pass locally (`skip_on_ci`); `air`/`lint_package` clean. Corollary spun off (background task): the
  frequentist nested-fixed MC interval (`theta2r_nested_draws()`) likely shares an attenuated 1b
  displacement + per-cluster floor → its own ADR (the frequentist point estimator is unaffected). Fable
  review committed at `data-raw/reviews/fable-review-m27-nested-fixed-{brief,response}.md`.

- Deferred out of M27 (record so not rediscovered): Bayesian **cluster-level** fixed (⚫ nested has none;
  crossed fixed cluster level unshipped for all engines), Bayesian **Design 3 fixed** (⚫ by-design —
  multilevel one-way), Bayesian **incomplete/ragged** fixed multilevel (M18 S1 / M19 analog), Bayesian
  **within-cell replicates** (M17/M20 analog), the **conflated** diagnostic (Eq. 14), Bayesian
  **numeric-unit `d_study()`** — each a later thin slice. Plus the M23 carry-overs: **rstanarm** backend,
  **selectable** `posterior` coupling, **HPDI** intervals, a **user-exposed `prior=`** API. Untouched
  carry-overs stay in [`ROADMAP.md`](ROADMAP.md): the Wave-3 averaged crossed cluster-level `ICC(c,k)`
  incomplete divisor; categorical/ordinal GLMM; one-way via SEM (blocked, ADR-014);
  non-parametric/profile-likelihood CIs; lme4 singular/merDeriv edge cases.

## M28: Frequentist nested-fixed MC-interval coverage (ADR-038)
- Goal: fix the coverage of the shipped **frequentist** nested-fixed θ²_{r:c} Monte-Carlo interval
  (`theta2r_nested_draws()`, M19 Slice 2) — the corollary spun off from the M27 gated Fable review
  (ADR-037). Interval-method work, not new estimand work (cf. M16/M21/M23–M27); the **point** estimator is
  out of scope (unbiased). Chosen **characterize-then-decide** (#1/#18): Slice 1 pinned the shipped
  interval **undercovering** (per-cluster floor + 1b subtraction → boundary coverage .95/.86/.57 as
  C_n=5/20/80, worst ~.37, interior .95/.92/.80 — an incidental-parameters displacement), which triggered
  Slice 2 under a second gated Fable review (#19). Adopted in full: a **shared `theta2r_moment_draws()`**
  (subtract **2b** — two equal inflations, push-forward + plug-in of the center — and floor the per-draw
  **AVERAGE**) now backs **every** fixed-rater MC interval across **glmmTMB/lme4/lavaan** (nested + crossed;
  lavaan random has b=0 → reduces to raw Jorgensen Eq. 6); the nested **point** floor also moved to the
  average (fixing point-outside-its-own-CI at the boundary, containment .59→1.00); the crossed paths were
  unified (b≈0, coverage stays nominal) and the regime-conditional "deliberate displacement" note retired.
  The pivotal-reflection alternative was tested and rejected (over-corrects by −b). Post-fix O-NFI nominal
  (interior .962/boundary .958, every cell ≥.91, C_n collapse gone).
- Reference: ADR-038 (scope + characterize-then-decide + the gated-Fable-review amendment); no new
  estimand-spec (interval method — cf. M16). Oracle **O-NFI** (nested-fixed-interval **coverage**, #1):
  `data-raw/oracle-nested-fixed-interval.R` → committed fixture across the Fable Q6 grid, asserted in
  `tests/testthat/test-icc-fixed-multilevel.R`, registered in [`REFERENCES.md`](REFERENCES.md). Gated
  Fable review + independent conjugate-normal check in `data-raw/reviews/fable-*-m28-*` / `fable-check-nfi.R`.

- Deferred out of M28 (record so not rediscovered): the Fable-recommended **fully-Bayesian alternative**
  (hierarchical half-*t* prior on the within-cluster rater effects, θ² read off realized η draws — leaves
  the fixed-effects parity contract with `fit_glmmtmb_nested_fixed()`; own future ADR); a boundary-robust
  rework of the **crossed** `theta2r_fixed()` interval beyond the negligible-`v` spot-check. Untouched
  carry-overs stay in [`ROADMAP.md`](ROADMAP.md): remaining Bayesian follow-ons (incomplete/ragged,
  replicates, conflated, cluster-level fixed); the Wave-3 averaged cluster-level `ICC(c,k)` incomplete
  divisor; categorical/ordinal GLMM; multilevel SEM; one-way via SEM (blocked, ADR-014).
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #33 at `e6ce64d`; full CI matrix green
  incl. Windows and R-devel, 9/9). `R CMD check --as-cran` 0/0/1; installed brms 29/0/0; non-brms suite
  295/0/0; `air`/`lint` clean. The frequentist nested-fixed MC interval is now moment-corrected and
  nominal; all fixed-rater intervals share one boundary-aware helper.

## M29: Bayesian engine (brms) — conflated diagnostic + within-cell replicates (ADR-039)
- Goal: extend `engine = "brms"` + `ci_method = "posterior"` to the two remaining low-risk parity
  follow-ons — the **conflated** diagnostic (`level = "conflated"`, ten Hove Eq. 14, Slice 1: no new fit —
  Eq. 14 reads off the shipped M24 `fit_brms_multilevel()` five-component draws) and **within-cell
  replicates** (σ²_res → σ²_sr + σ²_e, Slice 2: new `fit_brms_replicates()`; `occasions` divides pure
  error by n_o per draw) — two-way **random**, balanced/complete, single level. **Engine/interval parity,
  not new estimand work** (cf. M23–M27): both reuse *shipped* M17 estimands (ADR-026), read off posterior
  draws; no new estimand-spec, argument, or dependency. Both are **variance-ratio push-forwards**, so
  neither exposes the θ² functional that forced the M27/M28 2b moment correction — no Fable review.
- Reference: ADR-039 (scope + oracle posture); no new estimand-spec — reuses
  [`M17-conflated-icc.md`](estimand-specs/M17-conflated-icc.md) and
  [`M17-within-cell-replicates.md`](estimand-specs/M17-within-cell-replicates.md). Oracles
  **O-Bayes-Conflated** (Eq-14 identity + coverage .95 + glmmTMB containment 1.00 + conflated > subject)
  / **O-Bayes-Rep** (per-draw occasion divisor + coverage .94/.93 + glmmTMB containment 1.00 + average >
  single) off committed seeded fixtures (`data-raw/oracle-bayesian-{conflated,replicates}.R`), registered
  in [`REFERENCES.md`](REFERENCES.md).

- Deferred out of M29 (record so not rediscovered): Bayesian **incomplete/ragged** (M30 — leans on
  coverage calibration, likely a gated Fable review, #19); Bayesian **fixed-rater × replicates** and
  **multilevel × replicates** (the M20 Slice 1/2 frequentist deferrals' siblings); **conflated ×
  consistency** (🟣 research, unsourced) and **conflated × fixed** (⚫ by design); Bayesian
  **numeric-unit `d_study()`** projection; the M23 carry-overs — **rstanarm**, **selectable** `posterior`
  coupling, **HPDI** intervals, **user-exposed `prior=`**. All stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #34 at `be4e25f`; full CI matrix green
  9/9). `engine = "brms"` now covers the conflated diagnostic and single-level two-way random within-cell
  replicates alongside the two-way/one-way/multilevel random + fixed paths. `R CMD check --as-cran` 0/0/1;
  installed-pkg brms 266/0/0 (all live Stan fits ran); full suite (CI mode) 1089/0/10; `air`/`lint` clean.
  Both slices are variance-ratio push-forwards (no θ² moment correction). Bayesian incomplete/ragged is the
  isolated next milestone (M30).

## M30: Bayesian engine (brms) — incomplete/ragged, two-way random + crossed multilevel random (ADR-040)
- Goal: extend `engine = "brms"` + `ci_method = "posterior"` from balanced/complete to **incomplete/ragged**
  data for the **random**-rater paths — the isolated remaining random-rater gap and the Bayesian sibling of
  the frequentist M3 (incomplete two-way) / M9 (incomplete crossed multilevel). **Engine/interval parity, not
  new estimand work** (cf. M15/M21/M23–M29): reuses the *shipped* M3 `k_eff`/connectedness (ADR-008) and M9
  (ADR-018) estimands, read off posterior draws; **no new fit function** — `fit_brms_twoway()` /
  `fit_brms_multilevel()` run on ragged data unchanged (the work is narrowing the one `!balanced` brms guard;
  the engine-agnostic `k_eff` divisor + connectedness run pre-dispatch and thread into `posterior_summary()`).
  Both slices are **random → variance ratios**, so no θ² functional and no M27/M28 2b moment correction (the
  M29 clean-push-forward regime).
- Reference: ADR-040 (scope + Fable posture); no new estimand-spec — reuses
  [`M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md) and
  [`M9-incomplete-multilevel.md`](estimand-specs/M9-incomplete-multilevel.md). Oracles **O-Bayes-Incomplete**
  / **O-Bayes-IML** — reduction to shipped M23/M24 on complete data + MAP-containment vs the M3/M9 glmmTMB REML
  points on ragged data + seeded coverage off committed fixtures
  (`data-raw/oracle-bayesian-incomplete{,-multilevel}.R`), registered in [`REFERENCES.md`](REFERENCES.md).
- Deferred out of M30 (record so not rediscovered): Bayesian incomplete **fixed-rater** (two-way + crossed
  multilevel — pairs the M3 `k_eff` divisor with the M27/M28 θ² **2b moment correction under imbalance**;
  higher-risk, its own slice); Bayesian incomplete **nested** Designs 2/3 (M19 Slice 1 analog); Bayesian
  incomplete **within-cell replicates** (imbalance × replicates, M20 corner); the averaged cluster-level
  **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, open for all engines, M9 §9); Bayesian **numeric-unit
  `d_study()`**; the M23 carry-overs — **rstanarm**, **selectable** `posterior` coupling, **HPDI**,
  **user-exposed `prior=`**. All stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #35 at `9d2f0ed`; full CI matrix green 9/9).
  `engine = "brms"` now fits incomplete/ragged **random**-rater ICCs at the two-way single level (Slice 1) and
  the crossed Design-1 multilevel subject + cluster-`ICC(c,1)` levels (Slice 2), the averaged cluster `ICC(c,k)`
  dropped-with-note on ragged data. Both were narrowings of the one `!balanced` brms guard — no new fit. **The
  milestone's one unknown — ragged-data credible-interval coverage through `k_eff` — resolved NOMINAL at the
  subject level for both** (two-way .965/.965, crossed-ml .97/.97 for ICC(A,1)/ICC(A,k_eff) vs complete
  .945/.945 and .95/.95; cluster ICC(c,1) .95 tracks complete .92, characterized per the M24 few-cluster
  caveat), confirming the variance-ratio regime — **no Fable review** (ADR-040's conditional escalation not
  triggered). Oracles O-Bayes-Incomplete / O-Bayes-IML (committed fixtures) + live -agree fits (glmmTMB M3/M9
  containment; `skip_on_ci`). `R CMD check --as-cran` 0/0/1; installed-pkg both ragged fits verified; full
  suite (CI mode) 1030/0. Bayesian incomplete **nested / fixed / replicates** and the `ICC(c,k)` divisor stay
  deferred.

## M31: Bayesian engine (brms) — incomplete/ragged FIXED-rater, two-way single level + crossed multilevel (ADR-041)
- Goal: extend `engine = "brms"` + `ci_method = "posterior"` from balanced/complete to **incomplete/ragged
  fixed-rater** ICCs — the Bayesian sibling of the frequentist **M3** (single-level fixed θ²_r, Case-3A under
  imbalance) / **M18 Slice 1** (fixed crossed multilevel, subject level). **Engine/interval parity, not new
  estimand work** (cf. M15/M21/M23–M30): both slices narrow the same `!balanced` brms guard M30 touched so
  `fit_brms_fixed()` (Slice 1) / `fit_brms_multilevel_fixed()` (Slice 2) run on ragged data unchanged — **no
  new fit, no new θ² helper** (`brms_theta2r_moment_draws()` ships), no new argument or dependency. The 2b θ²
  moment correction goes **live for the first time on ragged fixed data** (`b ≠ 0` from unequal cell counts;
  ≈ 0 balanced); the milestone's one unknown — ragged credible-interval coverage — came back **nominal** for
  both slices (O-Bayes-IFixed .965/.965, O-Bayes-IFML-fixed .91/.91 tracking their complete cells), so **no
  Fable review** (ADR-041's conditional escalation not triggered).
- Reference: ADR-041 (scope + Fable posture); no new estimand-spec — reuses
  [`M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md) §6 (Case-3A θ²_r under imbalance) and
  [`M10-fixed-multilevel.md`](estimand-specs/M10-fixed-multilevel.md) / M18 Slice 1. Oracles **O-Bayes-IFixed**
  (single level) / **O-Bayes-IFML-fixed** (crossed multilevel) — reduction to the shipped balanced fixed brms
  fit (M26 / M27 Slice 1) + MAP-**containment** vs the M3 / M18 Slice 1 glmmTMB REML points on ragged data +
  committed seeded ragged coverage fixtures; registered in [`REFERENCES.md`](REFERENCES.md).
- Deferred out of M31 (record so not rediscovered): Bayesian incomplete **nested** fixed (Design 2, M19 Slice 2
  analog on ragged data); Bayesian **cluster-level fixed** rater ICC (deferred all engines); Bayesian incomplete
  **within-cell replicates** (imbalance × replicates, M20 corner); Bayesian **one-way** incomplete (M6 analog,
  low value); the averaged cluster-level **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, open all engines, M9 §9);
  Bayesian **numeric-unit `d_study()`**; the M23 carry-overs — **rstanarm**, **selectable** `posterior`
  coupling, **HPDI**, **user-exposed `prior=`**. All stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #36 at `5d6848e`; full CI matrix green 9/9).
  `engine = "brms"` + `raters = "fixed"` now fits incomplete/ragged data at the two-way single level and the
  crossed (Design 1) fixed multilevel subject level — both narrowings of the one `!balanced` brms guard, no
  new fit. **The milestone's one unknown — ragged coverage of the credible interval once the 2b θ² moment
  correction goes live single-level — resolved NOMINAL for both** (O-Bayes-IFixed .965/.965 vs complete
  .955/.955; O-Bayes-IFML-fixed .91/.91 vs .95/.95 within MC error), so **no Fable review**. Oracles
  O-Bayes-IFixed / O-Bayes-IFML-fixed (committed fixtures) + live -agree fits (glmmTMB M3/M18 containment;
  `skip_on_ci`). `R CMD check --as-cran` 0/0/0; installed-pkg both fixed fits verified; full suite (CI mode)
  1148/0. Bayesian incomplete **nested** fixed / **cluster-level** fixed / **replicates** / **one-way** stay
  deferred.

## M32: Bayesian engine (brms) — incomplete/ragged NESTED random, Designs 2 & 3, subject level (ADR-042)
- Goal: extend `engine = "brms"` + `ci_method = "posterior"` from balanced/complete to **incomplete/ragged
  NESTED random** ICCs — the Bayesian sibling of the frequentist **M19**. Completes the "brms × incomplete ×
  random" row: M30 shipped two-way single level + crossed (Design 1) multilevel, M32 adds both **nested**
  designs (raters nested in clusters, Design 2; raters nested in subjects, Design 3 / multilevel one-way,
  agreement-only), subject level. **Engine/interval parity, not new estimand work** (cf. M15/M21/M23–M31):
  both slices narrow the same `!balanced` brms guard's `ml_design != "crossed"` clause so the shipped M25
  fits `fit_brms_nested_clusters()` / `fit_brms_nested_subjects()` run on ragged data **unchanged** — no new
  fit, no θ² helper (random → variance ratios, no 2b, the M30 regime), no new argument/dependency. **Scope
  RANDOM-only by an oracle-first catch:** incomplete *fixed* nested has no frequentist oracle (deferred all
  engines, ADR-029, `icc.R:685`) — research, deferred below.
- Reference: ADR-042 (scope + random-only oracle-first bound + Fable posture + Amendment 2 verdict); no new
  estimand-spec — reuses [`M8-nested-multilevel.md`](estimand-specs/M8-nested-multilevel.md) with
  [`M9-incomplete-multilevel.md`](estimand-specs/M9-incomplete-multilevel.md) /
  [`M3-incomplete-designs.md`](estimand-specs/M3-incomplete-designs.md) §6. Oracles **O-Bayes-INML-clusters**
  (Design 2) / **O-Bayes-INML-subjects** (Design 3) — reduction ≡ M25 at balance + MAP-containment vs the M19
  glmmTMB REML point + committed seeded ragged coverage fixtures (`REFERENCES.md`).
- Deferred out of M32 (record so not rediscovered): Bayesian incomplete **fixed** nested (Designs 2/3) —
  **no frequentist oracle** (deferred all engines, ADR-029, `icc.R:685`); it is *research*, needs the
  frequentist incomplete-fixed-nested estimand (k_eff × per-cluster θ²_{r:c}) built first — the nested
  sibling of the M9 `ICC(c,k)` divisor. Bayesian **cluster-level** ICC for nested designs (undefined —
  cluster level needs crossed raters); Bayesian incomplete **within-cell replicates** (M20 corner);
  Bayesian incomplete single-level **one-way** (M6 analog, low value); the averaged cluster-level
  **`ICC(c,k)` incomplete divisor** (🟣 Wave-3, not reachable — nested designs report no cluster level);
  Bayesian **numeric-unit `d_study()`**; the M23 carry-overs — **rstanarm**, **selectable** `posterior`
  coupling, **HPDI**, **user-exposed `prior=`**. All stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (Slices 1–2 + cross-cutting DoD; merged via PR #37, squash-merged to `main` at `dd8e3e2`;
  full CI matrix green 9/9). `engine = "brms"` now fits incomplete/ragged **nested random** ICCs at the
  subject level for both designs — Design 2 (`fit_brms_nested_clusters`, Slice 1) and Design 3
  (`fit_brms_nested_subjects`, the multilevel one-way, Slice 2) — narrowing the same `!balanced` brms guard,
  no new fit. **Slice 1 (Design 2) ragged coverage NOMINAL** (.925/.925 vs complete .95/.95). **Slice 2
  (Design 3) triggered a gated Fable review** (#19): the first committed n_rep-80 ragged cell drew **.8625**
  (below the ≥ .88 pin) — the pin was NOT loosened (#4), Fable NOT auto-invoked, the finding characterized
  honestly (#18). **Fable verdict (ADR-042 Amendment 2): a Monte-Carlo tail event (P ≈ .002), no estimator
  shortfall** — same incidence at n=240 → .9458, four fresh incidences → .9500, a 2,000-fit frequentist arm
  → .9555, PIT uniform (calibrated). Adopted: ship unchanged, regenerate the fixture at **n_rep = 240 +
  per-rep seeding** (pins unchanged; regenerated .9375 complete / .9417 ragged), and **adopt n_rep ≥ 240 for
  future ragged coverage cells** (the ≥ .88 pin false-alarms ~0.7%/cell at n_rep 80). The Fable brief +
  response + seeded harness are committed under `project/` + `data-raw/reviews/` as the #19 provenance.
  `R CMD check --as-cran` 0/0/0; installed-pkg both nested fits verified; full suite (CI mode) 1175/0.

## M33: Bayesian engine (brms) — parity mop-up: incomplete one-way + fixed & multilevel replicates (ADR-043)
- Goal: close the **last clean-oracle estimand gaps** on the brms parity ledger — the corners the
  balanced/complete and incomplete arcs left behind — in one milestone (the recorded direction **(A)**,
  `ROADMAP.md`). Three thin slices, each a *shipped* frequentist coefficient read off posterior draws:
  **(1)** incomplete/ragged single-level **one-way**, **(2)** **fixed-rater** within-cell replicates,
  **(3)** **multilevel** within-cell replicates (crossed Design 1 + nested Design 2). **Engine/interval
  parity, not new estimand work** (cf. M15/M21/M23–M32): no new estimand-spec (reuses
  [`M6-oneway.md`](estimand-specs/M6-oneway.md) /
  [`M17-within-cell-replicates.md`](estimand-specs/M17-within-cell-replicates.md)), no new argument, no new
  dependency; two brms guards narrowed (`icc.R:1122`, `icc.R:1158`) + reuse of shipped fits/helpers. **Gate
  met (#1):** every corner has a frequentist oracle — Slice 1 → glmmTMB/lme4 incomplete one-way (M6 + M3
  `k_eff`); Slice 2 → M20 Slice 1 (balanced fixed replicates); Slice 3 → M20 Slice 2 (crossed D1 + nested D2).
- Reference: ADR-043 (scope + gate + per-slice regime + Fable posture). Oracles **O-Bayes-IOneway** (Slice 1)
  / **O-Bayes-FRep** (Slice 2) / **O-Bayes-MLRep** (Slice 3) — reduction to the shipped balanced brms fit +
  glmmTMB/lme4 MAP-containment + committed seeded coverage (`REFERENCES.md`).
- Deferred out of M33 (record so not rediscovered): **ragged / `occasions = "average"`** replicates (🟣
  research, no scalar effective-`n_o` divisor, ADR-030) and ragged×fixed / ragged×multilevel replicate
  compounds; incomplete **fixed** nested + **cluster-level** fixed (research, no frequentist oracle —
  direction (C), ADR-029/042); averaged cluster-level **`ICC(c,k)`** incomplete divisor (🟣 Wave-3, M9 §9);
  Bayesian **numeric-unit `d_study()`**; the **(B)** customization milestone — **`prior=`** API, **HPDI**
  intervals, **selectable** `posterior` coupling (next); **rstanarm** backend. All stay in
  [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (all three slices + cross-cutting DoD; merged via PR #38, squash-merged to `main` at
  `34cb974`; full CI matrix green 9/9). `engine = "brms"` now covers the last clean-oracle estimand gaps —
  **Slice 1** incomplete/ragged single-level one-way (`fit_brms_oneway()` reused, narrowed the `!balanced`
  guard's `oneway` clause; O-Bayes-IOneway ragged .9458/.9458, n_rep 240); **Slice 2** fixed-rater within-cell
  replicates (new `fit_brms_replicates_fixed()`, θ²_r per draw, 2b ≈ 0 on balanced data → θ²_r = σ²_r;
  O-Bayes-FRep .9625/.9625, containment 1.00); **Slice 3** multilevel within-cell replicates (new
  `fit_brms_ml_replicates()` crossed D1 6-component + `fit_brms_nested_replicates()` nested D2 5-component,
  variance-ratio push-forward; O-Bayes-MLRep crossed .9500/.9500, nested .9625/.9500, containment 1.00). Two
  brms guards narrowed + one removed + three new fits; no new estimand-spec/argument/dependency. **Every
  oracle nominal — no Fable review anywhere** (the M30 variance-ratio regime held, exactly as ADR-043
  predicted). `R CMD check --as-cran` 0/0/1; installed-pkg all three new paths driven through
  `library(intraclass)`; full suite (CI mode) 0 failures.

## M34: Bayesian engine (brms) — customization: user `prior=` override + HPDI credible intervals (ADR-044)
- Goal: the recorded direction **(B)** (`ROADMAP.md`) — a **customization** milestone, "let users deviate from
  a sourced default *with guardrails*." With M33 the brms **estimand** surface is complete; M34 adds a
  **customization interface**, **not** new estimand work (cf. M5.5/M7/M11/M16 — no estimand-spec). Two thin
  slices: **(1)** a user `prior=` override; **(2)** HPDI credible intervals as a post-fit alternative to
  percentile. Additive, non-breaking (#6): two **optional** arguments whose defaults reproduce shipped M23+
  results **bit-identically**. The oracle is a **REDUCTION oracle** (defaults ≡ shipped); arbitrary-prior /
  HPDI **coverage is deliberately NOT oracle-claimed** (#4) — a classed footgun warning + documented caveats
  carry the honesty (#18), so **no Fable review**.
- Reference: ADR-044 (scope + the two ADR-time API decisions). Oracles **O-PriorReduce** / **O-HPDI**
  (`REFERENCES.md`); no estimand-spec (interface milestone); no new dependency in `Imports` (`coda` added
  test-only to `Suggests` as the HPDI oracle).
- Deferred out of M34 (record so not rediscovered): **selectable `posterior` coupling** (MC/bootstrap
  `ci_method` on a Bayesian fit — low-priority (B) tail, `ROADMAP.md`); **BCa / HDI-of-transform** and other
  credible-interval flavors beyond percentile/HPDI; **per-component / per-SD distinct priors** beyond the
  single `class = "sd"` override; a **prior on the residual `sigma`** (ten Hove folds the interaction there —
  `engine-brms.R:24`); the **(C) research/blocked** corners (incomplete fixed nested, cluster-level fixed —
  need a frequentist estimand first, ADR-029/042); **rstanarm** backend; the **vignette reassessment** (docs).
  All stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** (both slices; merged via PR #39, squash-merged to `main` at `3fc133c`; full CI matrix green
  9/9). **Slice 1** — `icc(prior = NULL)` (brms-only; default = sourced half-*t*(4,0,1)) threaded through
  `fit_brms_common()` via an injected `brm_args$prior` (**no `fit_brms_*` wrapper changes**; `prior` stays
  reserved in `brm_args`), with a classed `intraclass_custom_prior` footgun warning; O-PriorReduce (reduction +
  bit-identical round-trip + override-takes-effect + classed guards). **Slice 2** —
  `posterior_summary = c("percentile","hpdi")` (default percentile) under `ci_method = "posterior"`;
  dependency-free `hpdi_interval()` (index arithmetic ≡ `coda::HPDinterval`), `(HPDI)` header label +
  `ci$posterior_summary` field; O-HPDI (percentile default bit-identical + `coda` agreement ≤ 1e-8 + same MAP /
  no wider than percentile + classed guard). **Reduction oracles throughout — no coverage claim, no Fable
  review.** The local `R CMD check` caught (before the PR) an over-aggressive `posterior_summary` guard
  (explicit `"percentile"` off-brms should be a no-op; only `"hpdi"` needs the posterior path) and an
  undeclared `coda`, both fixed. `R CMD check --as-cran` 0/0/1; full suite (CI mode) 1227/0/21; installed-pkg
  both new paths driven.

## M35: Vignette reassessment — update stale claims, split `advanced.Rmd`, add Bayesian coverage (ADR-045)
- Goal: bring the pkgdown vignettes in line with the shipped feature set for the first time since M13. A
  **docs milestone** — no new estimand, engine, fit, CI machinery, or dependency (cf. M4/M13); additive to the
  docs surface, no code behavior change. Three problems, per the retro triage: (1) `advanced.Rmd` carries
  **five materially false "planned for a later milestone" claims** (docs bugs misstating shipped behavior,
  #18); (2) the entire **Bayesian engine (M23–M34)** is undocumented in every vignette; (3) the 504-line
  `advanced.Rmd` is **overloaded**. Maintainer chose **Update + Split** (over update-only / full rewrite /
  minimal patch). Correctness is the docs contract (cf. M4): every displayed number **computed live** at knit
  time + numeric relationships **claim-tested** (`test-vignette-claims.R`, #1/#4/#12); no fabricated output
  (#4). **No Fable review** (#19 — no coverage claim).
- Reference: ADR-045 (scope + the article structure + the brms-chunk `eval=FALSE` decision). No estimand-spec
  (docs — cf. M4/M13); no oracle registry entry (no numerical oracle). Shipped in three slices: **S1**
  corrected five materially false "planned for a later milestone" claims in `advanced.Rmd` (M14/M15, M18, M19,
  M20/M33, M21 all shipped the "later" work) against `COVERAGE.md`; **S2** retired the overloaded 504-line
  `advanced.Rmd` into four self-contained articles — `multilevel-designs`, `engines`, `interval-methods`,
  `d-studies-and-replicates` (the multilevel forest plot + `choose_icc()` closer went to `multilevel-designs`
  by data-locality; all cross-links + external refs + `_pkgdown.yml` + `test-vignette-claims.R` labels + NEWS
  updated); **S3** documented the **Bayesian (brms) engine** for the first time — `engines.Rmd` (half-*t*(4,0,1)
  prior, `engine = "brms"`, the M34 `prior=` override + footgun warning) and `interval-methods.Rmd`
  (`ci_method = "posterior"`, MAP + percentile/HPDI `posterior_summary`), brms chunks `eval=FALSE` illustrative
  with **genuine committed output from a local live rstan run** (#4; [[brms-live-fit-skip-on-ci]]).
- Deferred out of M35 (record so not rediscovered): a **clarity/accessibility rewrite** of `getting-started` /
  `choosing-an-icc` (the set-aside "Rewrite" option — those articles are already good); a
  **benchmark-vs-prior-art** article and a **JOSS/software paper**; **live brms chunks** (blocked by the CI
  Stan toolchain — revisit only under a precomputed-cache mechanism); the **CRAN upload** (out of band,
  ADR-022); and every non-docs carryover — the **(C) research/blocked** brms corners (incomplete fixed
  nested, cluster-level fixed), **categorical/ordinal GLMM**, **multilevel SEM**, the Wave-3 `ICC(c,k)`
  incomplete divisor, occasion/ragged `d_study()` — all stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done** — merged via PR #40 (squash-merged to `main` at `d69f39e`; full CI matrix green 9/9,
  including `ubuntu-latest (devel)` with no flake). Local gate before the PR: `devtools::test()` 1471 pass / 0
  fail / **0 skip** (live brms Stan fits ran), `R CMD check --as-cran` **0/0/0** (all six vignettes build +
  re-build OK), `air` / `lintr` / spell / `pkgdown::check_pkgdown()` clean. Docs milestone — no new estimand,
  engine, fit, CI machinery, or dependency; correctness = live-computed + claim-tested numbers plus genuine
  committed brms output; no Fable review.

## M36: Incomplete/ragged fixed-rater nested (Design 2), subject level (ADR-046)
- Goal: fill the **incomplete/ragged fixed-rater nested Design-2** corner ADR-029 (M19) deferred for *every*
  engine — the first parked **(C) research/blocked** item, unblocked by a feasibility spike that showed it is
  **parity-shippable, not open research**. Generalizes the balanced M19 `theta2r_fixed_nested()` (per-cluster
  Case-3A finite-population rater variance) to **unequal per-cluster k_c** (ragged data), for glmmTMB/lme4 at
  the subject level; brms stays refused (no Bayesian path). Completeness, not new estimand work (cf.
  M9/M15/M18/M19): additive, non-breaking (#6), no new argument/dependency. Both **single and average**
  `ICC_s(·,k)` ship — the "attempt, else 🟣 research" clause **resolved to ship**: the averaged divisor is the
  per-subject harmonic `k_eff` (the M19 random-nested divisor), pinned by the **exact single-cluster reduction
  to flat M3** (|diff| ~1e-16) — it is **not** the open per-cluster `ICC(c,k)` divisor (ADR-046/the board had
  conflated the two, #18). Design 3 fixed ⚫ by-design; cluster-level fixed deferred.
- Reference: ADR-046 (scope + feasibility-spike provenance); estimand-spec `M36-incomplete-fixed-nested.md`.
  Oracle **O-IFNML** (asserted in `test-icc-fixed-multilevel.R`; `data-raw/oracle-incomplete-fixed-nested.R` +
  committed fixture, n_rep 240) — the finite-population θ²_{r:c} truth is a deterministic function of the fixed
  rater means, so **non-circular** seeded recovery is load-bearing (cross-engine validates only the raw fit):
  coverage interior **.967**, boundary θ²=0 **.942**, |bias| ≤ .018, reductions ~1e-16, cross-engine 2.6e-6;
  the 2b-under-imbalance risk resolved **nominal → no Fable review**. `theta2r_fixed_nested()` is bit-identical
  to the shipped helper on balanced data (O-FNML pins unmoved); the shared `theta2r_moment_draws()` (flat/
  crossed/lavaan) is untouched.
- Deferred out of M36 (record so not rediscovered): **cluster-level fixed** raters (the other (C)
  corner — no scaffolding, ten-Hove open question, its own later milestone); **Design 3 fixed** (⚫ by-design);
  **lavaan/brms** incomplete-fixed-nested (engine parity, later — M32 was random-only for the same
  no-oracle reason, now unblockable given M36's frequentist oracle); the genuinely-open **per-cluster
  `ICC(c,k)` incomplete divisor** at the *cluster* level (M9 §9, 🟣 Wave-3 — distinct from M36's subject-level
  `k_eff`, which shipped); the untouched carryovers — **categorical/ordinal GLMM**, **multilevel SEM**,
  occasion/ragged `d_study()`, the CRAN upload — stay in [`ROADMAP.md`](ROADMAP.md). (The averaged
  subject-level `ICC_s(·,k)` was expected to possibly defer but **shipped** — see the board.)
- Status: **done — merged, CI green** (PR #41, squash-merged to `main` at `f5a19e8`; full CI matrix green 9/9,
  including `ubuntu-latest (devel)` with no flake). Local gate before the PR: `devtools::test()` 1483/0/0 (live
  brms Stan fits ran), `devtools::check()` 0/0/0, `air`/`lintr` clean, installed-pkg M36 path driven. Averaged
  `ICC_s(·,k)` shipped (pinned by the exact single-cluster reduction to flat M3).

## M37: Fixed-rater **cluster-level** multilevel ICC (crossed Design 1, balanced) (ADR-047)
- Goal: ship the **last** parked **(C) research/blocked** corner — the fixed-rater **cluster-level**
  (between-cluster) ICC for the crossed Design 1, balanced/complete, glmmTMB + lme4. The **cluster-level
  sibling of M10** (which shipped the fixed subject level) and the last unshipped frequentist cell of the
  crossed fixed family. Investigation split the ROADMAP's blanket "blocked": the **balanced cell reads a new
  coefficient off the *shipped* M10 fit** (`1 + rater + (1|cluster) + (1|cluster:subject) + (1|cluster:rater)`
  already yields σ²_c, σ²_cr, θ²_r) — **no new fit function**; the genuinely-open *incomplete* cell is
  deferred (§7). Completeness, not new estimand work (cf. M9/M10/M18/M19/M36): additive, non-breaking (#6),
  no new argument/dependency. Estimand (M5 §3b map, θ²_r in the rater slot): signal σ²_c, agreement error
  `{θ²_r, σ²_cr}`, consistency `{σ²_cr}`, divisor `k` (raters/cluster); consistency ≡ random exactly.
  A **feasibility spike** (Slice 1) settled the one genuinely-open question (M10 §7 — at the subject level
  σ²_cr isn't in the error set, so M10 fixed≡random was clean; at the cluster level it **is** the error):
  fixing the rater main effect does **not** bias the `(1|cluster:rater)` interaction (`s2cr_fixed = s2cr_random`,
  |d| ~1e-7), so the **random σ²_cr is the correct fixed cluster-level error** and the coefficient reduces to
  the M5 random cluster-level ICC **exactly** (|Δ| ~1e-6) → **Outcome A, no Fable** (the pre-authorization did
  not fire).
- Reference: ADR-047 (scope + spike gate); estimand-spec `M37-fixed-cluster-level.md`. Oracle **O-FCL**
  (`test-icc-fixed-multilevel.R`; `data-raw/oracle-fixed-cluster-level.R` + committed fixture): reduction to
  M5 random cluster-level (balanced fixed≡random) **2.1e-6**, lme4 cross-engine **1.7e-5**, committed
  **non-circular** seeded finite-population recovery (interior coverage **.975/.925**, |bias| ≤ .008). The
  σ²_c=0 boundary interval under-covers **identically to M5-random** (parity |Δ| .000) — the pre-existing
  cluster-signal-zero loss (no moment correction for the signal variance), a candidate follow-up, **not an
  M37 defect** (#18). No new fit function; the default call now returns **both** levels for balanced fixed.
- Deferred out of M37 (record so not rediscovered): **incomplete/unbalanced cluster-level fixed** (🟣
  Wave-3, double-blocked — ten Hove open small-k estimator + the M9 §9 open `ICC(c,k)` divisor; its own later
  milestone); **brms/lavaan cluster-level fixed** siblings (engine parity, unblockable once M37 ships the
  frequentist oracle — the M27 note left crossed fixed cluster level "an unshipped frequentist cell too");
  **nested Designs 2/3 cluster-level** and **Design 3 fixed** (⚫ by-design); fixed cluster-level `d_study()`
  (refused, M4.5); the untouched carryovers — **categorical/ordinal GLMM**, **multilevel SEM**,
  occasion/ragged `d_study()`, the CRAN upload — stay in [`ROADMAP.md`](ROADMAP.md); improving
  cluster-signal-zero (σ²_c→0) interval coverage is a cross-cutting candidate (M5/M9/M37 alike).
- Status: **done — merged, CI green** (PR #43, squash-merged to `main` at `f0b29b7`; full CI matrix green 9/9,
  incl. `ubuntu-latest (devel)`). Local gate: `devtools::check` 0/0/0 (`--no-manual`; full suite + vignettes,
  live brms ran), `air`/`lintr` clean, installed-pkg cluster-fixed path driven (ICC(A,1) .363 / ICC(A,k) .695).
  Shipped in one session (plan/ADR-047 → Slice 1 spike Outcome A → Slices 2–3 → gate → PR #43); **no Fable review**.

## M38: brms engine parity — fixed multilevel cells (cluster-level fixed + incomplete/ragged fixed-nested Design 2) (ADR-048)
- Goal: close the **brms** half of the (C) research/blocked corner — `engine = "brms"` reaches parity with
  glmmTMB on the two shipped frequentist fixed multilevel cells: **Cell 1** balanced fixed **cluster level**
  (crossed Design 1, M37 sibling) and **Cell 2** incomplete/ragged fixed-rater **nested** Design 2 (M36
  sibling). Engine/interval parity, not new estimand work (cf. M27/M30/M31/M32): additive, non-breaking (#6),
  no new estimand-spec/argument/dependency. Both cells shipped as **clean guard-lifts** — the estimand
  machinery already keys the cluster error set on `level` (Cell 1 reads off the M27 fit) and the 2b moment
  machinery already reads a per-cluster `k` (Cell 2's ragged path) — **no new fit code**.
- Reference: ADR-048; estimand-specs unchanged (`M37-fixed-cluster-level.md`, `M36-incomplete-fixed-nested.md`,
  `M5-multilevel.md §3b`). Oracles **O-Bayes-FCL** (Cell 1 — reduction to the M24 brms random cluster level +
  glmmTMB M37 containment; `b ≈ 0`, no coverage claim, no Fable) and **O-Bayes-IFNML** (Cell 2 — glmmTMB M36
  containment + committed seeded coverage, n_rep 240, 4 cells {C_n 20, 80} × {interior, boundary θ²=0}: all
  nominal, .975/.954/.983/**.970**, the C_n=80 boundary showing **no incidental-parameters decay**). The
  milestone's genuine risk — the 2b-under-imbalance correction going nested-brms — resolved NOMINAL, so the
  ADR-048 **stop-and-replan** branch did not fire (no Fable pre-authorized).
- Deferred out of M38 (record so not rediscovered): **lavaan cluster-fixed + lavaan incomplete-fixed-nested**
  siblings (candidate, **blocked on the multilevel-SEM lift** — NOT unblockable; the M38 ROADMAP edit corrects
  that wording); **incomplete/unbalanced cluster-level fixed** (🟣 Wave-3, double-blocked — ten Hove open
  small-*k* + the M9 §9 `ICC(c,k)` divisor; stays a candidate); **Design 3 fixed** (⚫ already closed in code by
  the ADR-029 by-design abort — ROADMAP hygiene, not future work); the untouched carryovers — categorical/
  ordinal GLMM, multilevel SEM proper, occasion/ragged `d_study()`, the teaching-vignette clarity rewrite, the
  CRAN upload (ADR-022) — stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **done — merged, CI green** (PR #44, squash-merged to `main` at `4124297`; full CI matrix green 9/9,
  incl. `ubuntu-latest (devel)`). Local gate: `devtools::check` (CI-parity) 0/0/0, full CI-mode suite 1175/0,
  `air`/`lintr` clean, installed-pkg both new brms paths driven. Shipped in one session (retro → plan/ADR-048 →
  T1 Cell 1 → T2 Cell 2 code → T3 coverage gate NOMINAL → T4 docs/gate → PR #44); **no Fable review**.

## M39: `d_study()` occasion-count projection off a within-cell replicate fit (ADR-049)
- Goal: give `d_study()` a **second projection axis** — project the **occasion count `n_o`** off a balanced
  within-cell replicate fit (holding raters at the fitted count), the symmetric sibling of the **rater-count**
  projection M22 shipped (ADR-032). Projection machinery, **not new estimand work** (#6): additive,
  non-breaking; the only spec change is a new §9 in `M4.5-d-study.md`. Occasion averaging rescales **only pure
  error σ²_e** — a variance-ratio / dependability push-forward with the M22 Monte-Carlo interval reused (no θ²
  moment correction, no coverage pathology) → **low risk, no Fable**.
- Reference: ADR-049; estimand-spec **`M4.5-d-study.md` §9 (new)**. Oracles **O-OccDS**
  (reduction at `n_o` = fitted → shipped `ICC(*,k)` < 1e-4; cross-engine lme4; analytic GT dependability form;
  the `n_o → ∞` ceiling invariant; seeded-sim recovery + MC coverage; monotone/[0,1]; cluster level flat;
  fixed-agreement now projects on this axis). Three structural facts drive scope (ADR-049): occasion averaging
  touches only σ²_e; the curve has a **finite ceiling** (`σ²_s / (σ²_s + (σ²_r + σ²_sr)/m)`, not → 1) — the
  honest caveat (#18); and it is **well-posed for fixed raters incl. absolute agreement** (the M22 §4 abort is
  axis-specific — refused for `m`, permitted for `n_o`).
- DoD (the live board — check off in the same commit as the work, #16):
  - [ ] **T1 — Slice 1: single-level two-way occasion projection.** New `n_o` argument
    (`d_study(x, m = NULL, n_o = NULL, ...)`, exactly one of `m`/`n_o`, both → abort; `n_o` valid only on a
    balanced replicate fit); occasion projection for random + fixed raters, agreement + consistency (fixed
    absolute agreement now projects — lift the §4 abort for the `n_o` axis only); `occasions` column / print /
    tidy / glance / autoplot carry the projected axis. O-OccDS single-level (reduction, lme4, GT form, ceiling,
    sim). Classed aborts: both-axes, non-replicate, ragged (#5/#8).
  - [ ] **T2 — Slice 2: multilevel occasion projection.** Crossed Design 1 + nested Design 2 + Design 3 (the
    multilevel one-way, agreement-only). **Subject** level projects across `n_o`; **cluster** level is
    occasion-invariant → returned as a **flat curve with a documented note** (its error set has no pure-error
    term). O-OccDS multilevel (per-level reduction, lme4, sim; cluster-flat invariant).
  - [ ] **T3 — docs + spec + finish-task gate → PR.** Write `M4.5-d-study.md` §9; extend the
    `d-studies-and-replicates` vignette (the finite-ceiling caveat + the axis-specific fixed-agreement rule) +
    a claim test; NEWS / COVERAGE / REFERENCES (register O-OccDS) in-commit; `devtools::document` / `air format
    --check` / `lintr` / full CI-mode suite / `devtools::check` (CI-parity) all green; installed-pkg both new
    `n_o` paths driven through `library(intraclass)`; open the PR.
- Deferred out of M39 (record so not rediscovered): **ragged-replicate occasion projection** (blocked on the
  🟣 effective-`n_o` divisor — the *occasion-averaged coefficient on ragged replicates* research item,
  M20/ADR-030; the `R/d-study.R` ragged-replicate abort stays); **brms/posterior occasion projection**
  (`d_study()` projects off frequentist components + MC interval, not posterior draws — an engine-parity item);
  the **2-D `m × n_o` joint surface** (one axis per call — aborts); the untouched carryovers (categorical/
  ordinal GLMM, multilevel SEM proper, benchmark suite, teaching-vignette clarity rewrite, CRAN upload ADR-022)
  stay in [`ROADMAP.md`](ROADMAP.md).
- Status: **planned — no code yet (plan before code, #14).** ADR-049 written, board live, spec §9 pending in
  T3. On branch `m39-occasion-dstudy`. Next: `/start-task` T1.
