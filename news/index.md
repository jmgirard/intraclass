# Changelog

## intraclass 0.0.0.9000

- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  objects now have
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods
  (requires ggplot2, a Suggests dependency). `autoplot(fit)`
  (equivalently `what = "coefficients"`) draws a **coefficient forest
  plot** — each ICC index as a point estimate with its Monte-Carlo
  confidence interval, faceted by level for multilevel fits.
  `autoplot(fit, what = "components")` draws the **variance-component
  decomposition** — one bar per estimated variance component (subject,
  rater, residual, plus cluster and cluster:rater for multilevel
  designs), honouring the design’s confounding (e.g. one-way and
  raters-nested-in-subjects fold the rater into the residual). Both
  plots read straight off the fitted object, so they always match the
  printed table.
- Multilevel
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) now
  supports **fixed raters** (`raters = "fixed"`) for the crossed design
  (Design 1) at the **subject level**, on balanced complete data. The
  rater main effect is treated as the finite-population variance of the
  specific raters observed (McGraw & Wong Case 3A, as in the
  single-level fixed path) rather than a random-sample variance, fitting
  `score ~ 1 + rater + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)`.
  Consistency is identical to the random-rater case; absolute agreement
  differs only by the fixed-rater term (and coincides on balanced data).
  The fixed-rater cluster level, incomplete fixed-rater designs, and
  nested fixed-rater designs are directed to a clear error. Verified by
  reduction to the random-rater multilevel estimand (balanced fixed
  equals random), an independent lme4 fit, and a seeded recovery
  simulation.
- Multilevel
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) now
  accepts **incomplete (ragged) crossed designs** (Design 1 with missing
  subject-by-rater cells), computing the subject-level ICCs by REML with
  the averaging divisor set to the effective number of ratings per
  subject (`k_eff`, the harmonic mean) — the multilevel counterpart of
  the single-level incomplete two-way ICC. Identifiability is checked
  first: each cluster’s subject-by-rater layout must be connected, and
  absolute agreement additionally requires raters that bridge clusters
  (otherwise the design is really rater-nested). A new optional
  **`design`** argument (`"crossed"`, `"nested_in_clusters"`,
  `"nested_in_subjects"`) lets you declare the design when missing cells
  make the crossing pattern ambiguous; it is validated against the data.
  The **cluster level** is available on incomplete data as the
  single-rater `ICC(c,1)` (behind an identifiability gate requiring
  raters that bridge clusters); the averaged `ICC(c,k)` on incomplete
  data is deferred (its effective-rater divisor is an open modeling
  question). Verified against independent lme4 fits, a seeded
  population-recovery simulation, and reductions to the complete-data
  multilevel and the flat incomplete two-way estimands. Incomplete
  *nested* designs and fixed-rater multilevel remain for later work.
- Multilevel
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) now
  handles **nested-rater designs** (ten Hove et al. 2022 Designs 2 and
  3), in addition to the crossed Design 1. The design is **inferred from
  the data’s crossing pattern**. When each cluster has its own raters
  (**Design 2**, raters nested in clusters), a four-component model
  (`score ~ 1 + (1 | cluster) + (1 | cluster:subject) + (1 | cluster:rater)`)
  is fit and the nested rater-within-cluster variance carries the rater
  term. When each *subject* has its own raters (**Design 3**, raters
  nested in subjects), the rater variance is confounded into the
  residual, giving a three-component multilevel *one-way* model
  reporting agreement-only `ICC(1)`/`ICC(k)`. Both nested designs define
  only the **subject** level (a cluster-level ICC needs raters crossed
  with clusters), so `level` is restricted to `"subject"` for them;
  mixed crossed/nested patterns, incomplete nested designs, and
  consistency requests on Design 3 are directed to a clear error.
  Verified against independent lme4 fits, seeded population-recovery
  simulations, and reductions to the two-way (Design 2) and one-way
  (Design 3) estimands.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  gains a selectable **`engine = "lavaan"`** for the complete, balanced
  random two-way design, fitting the generalizability model as a
  common-factor **structural equation model** (Jorgensen 2021).
  Consistency coefficients equal the mixed-model estimates exactly;
  absolute-agreement coefficients use the SEM **indicator-mean
  estimator** of the rater variance (the variance of the estimated
  indicator intercepts), which is asymptotically equivalent to the
  mixed-model estimator and matches conventional generalizability-theory
  software (GENOVA, `gtheory`) on real data (Vispoel et al. 2022), but
  differs by a small-sample amount on tiny designs (`ICC(A,1)` = 0.284
  via lavaan vs 0.290 via the mixed model on the Shrout & Fleiss
  example). `lavaan` is a new `Suggests`; one-way, fixed-rater,
  multilevel, and incomplete designs are directed to the mixed-model
  engines. Verified against the exact Jorgensen (2021) formula, a
  large-sample convergence simulation, and cross-engine interval checks.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  gains **`model = "oneway"`** for one-way random designs (Shrout &
  Fleiss Case 1), where each subject is rated by a possibly different,
  interchangeable set of raters. It reports `ICC(1)` (single) and
  `ICC(k)` (average) from a `score ~ 1 + (1 | subject)` fit with no
  rater term — so systematic rater differences are absorbed into the
  residual, giving the most conservative ICC. The `rater` column is
  still supplied but only counts the ratings per subject (its labels are
  ignored); `type`, fixed raters, and `cluster` do not apply. Numeric
  `unit` (D-study projection) works here too. Completes the classic
  Shrout & Fleiss family; verified against the published values (0.166 /
  0.443), [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html),
  one-way ANOVA mean squares, both engines, and a seeded simulation.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  gains a selectable **`engine = "lme4"`** alongside the default
  `"glmmTMB"` for the random two-way design. Both fit the variance
  components by REML and agree to numerical tolerance; the lme4
  Monte-Carlo interval is built from the parameter covariance supplied
  by **merDeriv** (a new `Suggests`), delta-transformed to the same
  boundary-aware log-SD scale glmmTMB uses – so the two engines’
  intervals coincide to ~1e-2. lme4 currently covers only the random
  two-way path; fixed-rater and multilevel designs, and singular
  (boundary) fits, are directed to the boundary-robust `"glmmTMB"`
  engine. Verified against glmmTMB point *and* interval estimates, the
  published Shrout & Fleiss values, and a seeded population-recovery
  simulation.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  gains **multilevel** ICCs for subjects nested in clusters (pupils in
  classrooms, patients in clinics). Supply a `cluster` column and it
  reports the **subject-level** (within-cluster) and **cluster-level**
  (between-cluster) coefficients – ten Hove, Jorgensen & van der
  Ark’s (2022) generalizability-theory decomposition – selectable via
  `level`. The five-component model is fit with the usual glmmTMB engine
  and boundary-aware Monte-Carlo intervals; correctness is verified
  against an lme4 cross-engine fit, a seeded population-recovery
  simulation, and a reduction to the single-level coefficients. This
  release covers crossed random raters on balanced data. See the
  **Advanced** article.
- New
  [`d_study()`](https://jmgirard.github.io/intraclass/reference/d_study.md)
  projects the reliability of a fitted
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md) to
  the mean of an arbitrary number of raters `m` – a
  generalizability-theory **decision (D-) study**, answering “how many
  raters do I need?”. It returns a tidy `icc_dstudy` table of Phi(m)
  with boundary-aware Monte-Carlo intervals and reuses the stored fit
  (no refit);
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  draws the reliability curve (needs ggplot2, in Suggests).
  [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)’s
  `unit` now also accepts numbers (`unit = c("single", 3)`) for one-off
  projections, adding an `ICC(A,3)` row. Projection is refused for
  fixed-rater absolute agreement (ill-posed) and is verified against
  Spearman-Brown (consistency), the GT dependability form (agreement),
  [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html), and a seeded
  simulation. Experimental.
- New datasets `ratings` (the complete Shrout & Fleiss 1979 example) and
  `ratings_incomplete` (a connected incomplete variant), used throughout
  the docs and examples. A new **Choosing an ICC** article walks through
  the whole decision – agreement vs. consistency, single vs. average,
  random vs. fixed, and complete vs. incomplete – with a decision-tree
  diagram.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  handles **imbalanced and incomplete** subject-by-rater designs
  (missing cells) via the mixed model: it detects the design, uses the
  effective number of ratings `k_eff` (the harmonic mean of the
  per-subject counts) as the `ICC(*,k)` divisor, and aborts loudly on a
  disconnected (unidentified) design. `raters = "fixed"` now fits raters
  as fixed effects, so it differs from `"random"` on incomplete data
  (the two still coincide when balanced).
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  gains **consistency** coefficients `ICC(C,1)`/`ICC(C,k)` via
  `type = "consistency"` (drops the rater main effect from the error)
  and a `raters = c("random", "fixed")` argument. On balanced data,
  fixed raters is a labelling layer over the same fit (two-way mixed,
  Shrout & Fleiss `ICC(3,*)`); it is opt-in and warns, since random is
  the recommended default for interrater reliability. `print`/`summary`
  now report the design and the Shrout & Fleiss equivalent. Verified
  against the published `ICC(3,*)` values,
  [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html), and a
  fixed-vs-random equivalence check.
- [`icc()`](https://jmgirard.github.io/intraclass/reference/icc.md)
  computes two-way random, absolute-agreement intraclass correlation
  coefficients `ICC(A,1)` and `ICC(A,k)` from a `glmmTMB` linear mixed
  model, with boundary-aware Monte-Carlo confidence intervals,
  `print`/`summary`/`format` methods and
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html)/[`glance()`](https://generics.r-lib.org/reference/glance.html).
  Verified against the Shrout & Fleiss (1979) worked example,
  [`psych::ICC`](https://rdrr.io/pkg/psych/man/ICC.html), a
  package-independent ANOVA mean-squares oracle, a seeded simulation,
  and an lme4 cross-check.
- Project scaffolding: package skeleton, `project/` tracking system
  (principles, milestones, decisions, oracle registry), custom skills
  and agent, CI workflows (R-CMD-check, coverage, lint, format, pkgdown,
  scheduled reference-values), and a pkgdown site.
