# M54: Multilevel SEM (lavaan) — engine implementation (done 2026-07-17)

**Goal:** ship `engine = "lavaan"` + `cluster` for the crossed (Design 1)
multilevel estimand — both levels + conflated, complete/balanced, random
raters, montecarlo CI — as the two-level CFA established by M53. **Done.**
PR: https://github.com/jmgirard/intraclass/pull/60 (squash 7b5deae).

- `fit_lavaan_multilevel()` (R/engine-lavaan.R): two-level CFA, five
  components, σ²_r via the grand-mean-centred quadratic form on the `.l2`
  between intercepts, standard six-field MC contract → the shared
  ci-montecarlo/d_study/print machinery works unmodified (D-005).
- The raw rater estimator carries a documented deterministic inflation
  E = σ²_r + τ², τ² = (σ²_cr + σ²_res/n_s)/N_c (multilevel analog of the
  single-level "−σ²_res/n" term); rater-parity pins centre on τ², never zero.
- Dispatch: blanket lavaan-multilevel abort narrowed to one-way; classed
  `intraclass_unsupported` for nested / fixed / replicates / incomplete /
  unbalanced-cluster × lavaan; bootstrap → NULL simulate_refit → loud guard.
- Oracle evidence: glmmTMB parity (index-class split), reduction to the
  single-level engine, seeded recovery (cluster + tight-k axes), τ² GP7
  invariant, MC feasibility + endpoint parity, boundary-reached Heywood.
- Verify: check() 0/0/0; suite 1712 pass loaded + installed; lint 0.
  Three-lens review: zero findings. ML-only (no REML), so cluster-level
  components carry small-sample ML shrinkage that shrinks with N_c.
- Follow-on: the lavaan multilevel siblings (fixed / incomplete / unbalanced,
  incl. the multilevel bootstrap) are now unblocked — candidate row.
