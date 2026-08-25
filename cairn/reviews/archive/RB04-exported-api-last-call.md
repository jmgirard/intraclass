# RB04: Exported-API last call before the first CRAN release (M48)

- **Date:** 2026-08-25
- **Output required:** write findings to `cairn/reviews/RR04-exported-api-last-call.md`
- **Binding criteria:** not requested   <!-- "requested" only on the maintainer's explicit choice at authoring (advisory-by-default, M145); this slot is what the Output format's ONLY-if clause reads -->

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

`intraclass` is an R package that estimates interrater-reliability intraclass
correlation coefficients (ICCs) inside the generalizability-theory framework.
It fits a linear mixed model (default engine `glmmTMB`; alternates `lme4`,
`lavaan`, `brms`) and forms coefficients from the estimated variance
components, rather than from classical ANOVA mean squares. It covers the ICC
family along four axes — absolute agreement vs. consistency (`type`), single
vs. average rating (`unit`), random vs. fixed raters (`raters`), one-way vs.
two-way (`model`) — plus multilevel (raters nested in or crossed with
clusters) designs, imbalanced and incomplete data, decision-study projection
to other numbers of raters (`d_study()`), and an interactive helper that
recommends which coefficient to use (`choose_icc()`). Confidence intervals
default to a boundary-aware Monte-Carlo method, with several opt-in
alternatives selected by `ci_method`.

Milestone M48 is consolidating the package into a CRAN-submission-ready
v0.1.0. Nothing has ever been released: the current version is `0.0.0.9000`,
so **every name, argument, default, and returned shape is still free to
change at zero cost to users, and is fixed the moment the release goes out.**
The project's own design principle GP2 records this as a one-way door that
closes at submission. Milestone task T1 is a deliberate last-call audit of
the exported surface, and it was escalated to this independent review rather
than settled in the implementing session.

The maintainer's expectation is "no changes". Your job is to test that
expectation adversarially, not to confirm it. A finding that would be
awkward to fix after release is worth more here than a stylistic preference.

## Materials

Read these; they are the whole exported surface and its documentation.

- `NAMESPACE` — the complete export list. Three exported functions
  (`icc`, `d_study`, `choose_icc`), two re-exported generics from
  `generics` (`tidy`, `glance`), and thirteen registered S3 methods.
- `R/icc.R` — `icc()`; the signature is at line 712, the body runs to the end
  of the file. This is the package's primary entry point.
- `R/d-study.R` — `d_study()`; signature at line 157.
- `R/choose-icc.R` — `choose_icc()` at line 83; the recommendation object it
  builds (`new_icc_recommendation()`, line 549) and its `format`/`print`
  methods (lines 584, 654).
- `R/icc-methods.R` — the `icc` object's methods: `format` (36), `print`
  (293), `summary` (302), `tidy` (349), `glance` (375). `tidy.icc()` and
  `glance.icc()` define the tabular contract most downstream code will use.
- `R/d-study.R` — the `icc_dstudy` methods (`format`, `print`, `tidy`,
  `glance`) live alongside the constructor.
- `R/autoplot.R` and `R/zzz.R` — `plot.icc`, `plot.icc_dstudy`, and the two
  `autoplot` methods, which are registered lazily against ggplot2 (a
  Suggests dependency) via a vendored `s3_register()` in `.onLoad()`.
- `man/icc.Rd`, `man/d_study.Rd`, `man/choose_icc.Rd`, `man/reexports.Rd`,
  `man/intraclass-package.Rd` — the rendered documentation. Note there are
  only seven `.Rd` files: the S3 methods carry no separate documentation
  pages.
- `DESCRIPTION` — dependency surface. `Imports` is `cli`, `generics`,
  `glmmTMB`, `lifecycle`, `rlang`, `stats`, `tibble`; everything else,
  including the alternate engines and `ggplot2`, is in `Suggests` behind
  `rlang::check_installed()`.
- `vignettes/` and `README.Rmd` — how the surface is presented to a new user.
- `tests/testthat/` — in particular the files exercising `icc()` argument
  validation and the method outputs, for what the current contract is
  actually pinned to.

To run the package: `Rscript -e 'devtools::load_all(); print(icc(ratings,
score, subject, rater))'` from the repo root. `ratings` and
`ratings_incomplete` are shipped datasets.

## Questions

1. **`icc()`'s argument list.** The signature takes twenty-one arguments:
   `data`, `score`, `subject`, `rater`, `cluster`, `model`, `type`,
   `raters`, `unit`, `occasions`, `level`, `design`, `engine`, `conf_level`,
   `ci_method`, `mc_samples`, `boot_samples`, `seed`, `brm_args`, `prior`,
   `posterior_summary`. Assess the names, the order, and the defaults. In
   particular: is the grouping and ordering (data/columns, then design axes,
   then engine, then interval control, then engine-specific extras) the one
   a user will predict? Are any two names confusable with each other
   (`raters` the rater-mode axis vs. `rater` the column; `model` vs.
   `design`; `level` vs. `unit`)? Does any default silently choose
   something a naive caller would not want?

2. **Defaults that changed late.** `type` defaults to the vector
   `c("agreement", "consistency")`, so a default two-way call returns four
   coefficients rather than two. `unit` and `level` are vectorized the same
   way. Is a vector-valued default the right shipping choice for a first
   release, given that it makes the default `print()` and `tidy()` output
   wider and makes positional indexing of `tidy()` rows fragile?

3. **Argument-shape asymmetry.** Most axis arguments are
   `match.arg`-style character vectors (`type`, `raters`, `unit`, `level`),
   but `model` defaults to the scalar `"twoway"`, `occasions` to the scalar
   `"single"`, and `engine` and `ci_method` to scalars as well. Is that
   asymmetry defensible, or should the whole axis set take one shape?

4. **The `design` argument.** `design = NULL` coexists with `model`,
   `cluster`, and `level`. Determine from the code what `design` actually
   controls, whether it is redundant with, or capable of contradicting, the
   other three, and whether it earns a place in the first released
   signature.

5. **Returned shapes.** `tidy.icc()` returns columns `index`, `type`,
   `level`, `sf_index`, `estimate`, `std.error`, `conf.low`, `conf.high`,
   `conf.level`, `method`, and conditionally inserts `occasions` after
   `index` when the fit has within-cell replicates. `glance.icc()` returns
   roughly twenty columns of design and variance-component summaries. Judge
   these against the broom conventions the `generics` re-export invokes: are
   the column names right, is the conditional column a problem for code that
   binds several tidied fits together, and is anything missing that a user
   will need and cannot recover?

6. **The `icc` object itself.** `tidy()`/`glance()` read a list with
   `$estimates`, `$components`, `$design`, `$ci`, `$n`, `$engine`, `$k_eff`
   and more. Is that internal structure effectively part of the public
   contract once released — and if so, should it be documented, given a
   constructor, or explicitly disclaimed as internal?

7. **`d_study()` and `choose_icc()`.** `d_study(x, m, n_o, conf_level,
   mc_samples, seed)` inherits its settings from the fitted object when its
   arguments are `NULL`. `choose_icc(model, type, unit, raters, multilevel,
   level)` walks the user through questions interactively and otherwise
   resolves from supplied answers. Assess both signatures on the same terms
   as question 1, and say whether `n_o` and `m` are named as a reader will
   understand them.

8. **Should anything be withheld?** An export that has never shipped costs
   nothing to remove; a shipped one is effectively permanent. Considering
   the whole surface — the three functions, the two re-exported generics,
   the `plot`/`autoplot` methods, the `summary.icc` method, the interactive
   `choose_icc()` helper — name anything that would be better held back
   from v0.1.0 and released later once its shape has settled, and say why.
   Treat this as a live option, not a formality.

9. **Extension headroom.** The roadmap holds planned extensions: cluster-
   level and occasion-ragged D-study projection, occasion-averaged
   coefficients on ragged replicates, incomplete/unbalanced fixed-rater
   cluster-level coefficients, and further `ci_method` values. Which of
   these, if any, would force a breaking change to the signatures as they
   now stand — and is there a cheap change now that would avoid that?

10. **`lifecycle` in Imports.** `DESCRIPTION` imports `lifecycle` and
    `NAMESPACE` has `importFrom(lifecycle, deprecated)`, but no call to
    `deprecated()` or `deprecate_warn()` exists anywhere in `R/`. Should
    the dependency be dropped before the first release, kept as scaffolding
    for the deprecation cycle the project has committed to, or handled some
    other way?

11. **Undocumented methods.** Thirteen S3 methods are registered and none
    has its own `.Rd` page. Confirm whether that is acceptable for a CRAN
    submission and whether it is acceptable for users, and say which
    methods, if any, need documentation before release.

## Constraints

Fixed; do not relitigate. Flag disagreement explicitly rather than working
around a constraint silently.

- The package's estimation approach — mixed-model variance components rather
  than ANOVA mean squares — is settled and out of scope here. So is the
  correctness of any numeric result: this review is about the shape of the
  interface, not the values it returns.
- The default confidence-interval method stays Monte-Carlo and
  boundary-aware; alternates stay opt-in via `ci_method`. Recorded in
  D-004, D-006, D-012, D-026.
- The dependency split — `glmmTMB` in Imports as the default engine, every
  other engine and `ggplot2` in Suggests behind `rlang::check_installed()` —
  is settled (ADR-002). Question 10 is about `lifecycle` only.
- `ci_method` string values already fixed by decision: `"npbootstrap"`
  (D-010, D-013), `"mpl"` (D-015), `"searle"`/`"burch"` (D-013). Naming of
  future methods is open; renaming these is not.
- The two-level SEM route to the multilevel estimand is a fenced
  parameterization (D-005) and its exposure is settled.
- Whether to release at all, and when, is the maintainer's decision, already
  made. Do not opine on release timing.
- Any change you recommend has to be worth making *before* a first release
  under time pressure. Rank accordingly, and separate "must fix before the
  door closes" from "would be nicer".

## Output format

In `RR04-exported-api-last-call.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: emit a
`## Binding criteria` section ONLY if this brief's header slot says
`requested` — it does not, so do not emit one.
