# intraclass 0.0.0.9000

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
