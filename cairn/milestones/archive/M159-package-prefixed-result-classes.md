# M159: Result classes take the package prefix, so performance cannot replace their methods

**Status:** done (2026-10-16, PR #178 https://github.com/jmgirard/intraclass/pull/178)

**Goal:** The results of `icc()`, `d_study()` and `choose_icc()` carry the classes `"intraclass_icc"`, `"intraclass_dstudy"` and `"intraclass_recommendation"`, and no method that another package registers on `"icc"` changes them.

**Outcome:** The three result classes and every S3 method on them were renamed: `format`, `print`, `summary`, `tidy`, `glance`, `plot` and `autoplot` for `intraclass_icc`, the same less `summary` for `intraclass_dstudy`, and `format`/`print` for `intraclass_recommendation`.
The old names are dropped with no transition class. `R/zzz.R` registers `autoplot()` lazily on the new names, and `.onLoad()` carries `# nocov`.
`d_study()` checks `inherits(x, "intraclass_icc")`. The internal helpers `new_icc_recommendation()` and `resolve_icc_recommendation()` keep their names.
`tests/testthat/test-class-names.R` asserts the three class vectors. It registers marker methods on `"icc"` for five generics, with a positive control and cleanup, and shows that none reaches a result.
`test-autoplot.R` gained a `plot()` test on a `d_study()` result.
The two fits stored in `tests/testthat/fixtures/bayesian-vignette-oracle.rds` were re-classed in place with no rerun, and the script header records it.
NEWS has a "Breaking changes" entry, including that the package attached last masks the other's `icc()`. DESIGN.md Conventions now states the `intraclass_` prefix, and GP2 points to D-050.

**Decisions:** D-050 (result classes take the `intraclass_` prefix with no deprecation period, an exception to GP2).

**Review:** One pass with the three-lens fan-out found 16 items: 6 fixed in `648d3c8`, 2 sent to the candidate row "M159 review follow-ups on the renamed result classes", 4 rejected, and the rest confirmations.
Fixes: a positive control and a non-empty capture check in the class test; the DESIGN.md legacy-object note, a GP2 pointer and a Conventions line; stale method names in `prose-style.md`, a ROADMAP row and a LESSONS line.
The claim audit read 46 claims and corrected 0. AC1 to AC6 were verified. `devtools::check()` gave Status OK, and `devtools::test()` had 0 failures.
On the PR, codecov/patch first failed at 80%. The 3 lines were untested on main too, and were covered by `f33beac`. All 11 checks then passed.
No lesson was added, because LESSONS.md is at 19,996 of 20,000 bytes.
