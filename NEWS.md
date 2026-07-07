# intraclass 0.0.0.9000

* `icc()` gains **multilevel** ICCs for subjects nested in clusters (pupils in
  classrooms, patients in clinics). Supply a `cluster` column and it reports the
  **subject-level** (within-cluster) and **cluster-level** (between-cluster)
  coefficients -- ten Hove, Jorgensen & van der Ark's (2022) generalizability-theory
  decomposition -- selectable via `level`. The five-component model is fit with the
  usual glmmTMB engine and boundary-aware Monte-Carlo intervals; correctness is
  verified against an lme4 cross-engine fit, a seeded population-recovery
  simulation, and a reduction to the single-level coefficients. This release
  covers crossed random raters on balanced data. See the **Advanced** article.
* New `d_study()` projects the reliability of a fitted `icc()` to the mean of an
  arbitrary number of raters `m` -- a generalizability-theory **decision (D-)
  study**, answering "how many raters do I need?". It returns a tidy `icc_dstudy`
  table of Phi(m) with boundary-aware Monte-Carlo intervals and reuses the stored
  fit (no refit); `autoplot()` draws the reliability curve (needs ggplot2, in
  Suggests). `icc()`'s `unit` now also accepts numbers (`unit = c("single", 3)`)
  for one-off projections, adding an `ICC(A,3)` row. Projection is refused for
  fixed-rater absolute agreement (ill-posed) and is verified against Spearman-Brown
  (consistency), the GT dependability form (agreement), `psych::ICC`, and a seeded
  simulation. Experimental.
* New datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout the
  docs and examples. A new **Choosing an ICC** article walks through the whole
  decision -- agreement vs. consistency, single vs. average, random vs. fixed,
  and complete vs. incomplete -- with a decision-tree diagram.
* `icc()` handles **imbalanced and incomplete** subject-by-rater designs
  (missing cells) via the mixed model: it detects the design, uses the effective
  number of ratings `k_eff` (the harmonic mean of the per-subject counts) as the
  `ICC(*,k)` divisor, and aborts loudly on a disconnected (unidentified) design.
  `raters = "fixed"` now fits raters as fixed effects, so it differs from
  `"random"` on incomplete data (the two still coincide when balanced).
* `icc()` gains **consistency** coefficients `ICC(C,1)`/`ICC(C,k)` via
  `type = "consistency"` (drops the rater main effect from the error) and a
  `raters = c("random", "fixed")` argument. On balanced data, fixed raters is a
  labelling layer over the same fit (two-way mixed, Shrout & Fleiss `ICC(3,*)`);
  it is opt-in and warns, since random is the recommended default for interrater
  reliability. `print`/`summary` now report the design and the Shrout & Fleiss
  equivalent. Verified against the published `ICC(3,*)` values, `psych::ICC`, and
  a fixed-vs-random equivalence check.
* `icc()` computes two-way random, absolute-agreement intraclass correlation
  coefficients `ICC(A,1)` and `ICC(A,k)` from a `glmmTMB` linear mixed model, with
  boundary-aware Monte-Carlo confidence intervals, `print`/`summary`/`format`
  methods and `tidy()`/`glance()`. Verified against the Shrout & Fleiss (1979)
  worked example, `psych::ICC`, a package-independent ANOVA mean-squares oracle,
  a seeded simulation, and an lme4 cross-check.
* Project scaffolding: package skeleton, `project/` tracking system (principles,
  milestones, decisions, oracle registry), custom skills and agent, CI workflows
  (R-CMD-check, coverage, lint, format, pkgdown, scheduled reference-values), and
  a pkgdown site.
