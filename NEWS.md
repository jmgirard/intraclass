# intraclass 0.0.0.9000

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
