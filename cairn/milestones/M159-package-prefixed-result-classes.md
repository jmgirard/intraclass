# M159: Result classes take the package prefix, so performance cannot replace their methods

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** user-facing — users see the result class through `class()`, `inherits()` and the help pages
- **Branch/PR:** m159-package-prefixed-result-classes

## Goal

The results of `icc()`, `d_study()` and `choose_icc()` carry the classes `"intraclass_icc"`, `"intraclass_dstudy"` and `"intraclass_recommendation"`, and no method that another package registers on `"icc"` changes them.

## Scope

**In:** rename the three result classes and every S3 method on them (`R/icc.R:2660`, `R/d-study.R:577`, `R/choose-icc.R:604`, `R/icc-methods.R`, `R/autoplot.R`, `R/zzz.R:12-13`). Change the class check and message in `d_study()` (`R/d-study.R:210-211`). Update roxygen, regenerated `man/` and `NAMESPACE`, tests, the vignettes and README where they name a class. Add a regression test for the performance clash, a NEWS entry, a D-entry for the GP2 exception, and the old names in `cairn/DESIGN.md`.

**Out:** the masking of one `icc()` function by the other when both packages are attached. A class change cannot fix it, so the NEWS entry only states it. An `as.data.frame()` method for intraclass results stays out, because no request names one. Results saved under 0.1.0 keep the old class and are not converted; the NEWS entry says to re-run `icc()`. The `parameters::model_parameters()` method is the candidate row "easystats model_parameters method". `cairn/estimand-specs/M4.5-d-study.md` keeps the old names, because it is a historical spec.

## Acceptance criteria

- [ ] AC1: `icc()` returns an object whose class vector is exactly `"intraclass_icc"`. `choose_icc()` returns an object whose class vector is exactly `"intraclass_recommendation"`. `d_study()` returns an object whose first class is `"intraclass_dstudy"` and whose class vector contains none of `"icc"`, `"icc_dstudy"` and `"icc_recommendation"`. A test asserts each of these three class vectors.
- [ ] AC2: A test registers, on class `"icc"`, a method that returns a fixed marker value for each of `print`, `format`, `summary`, `tidy` and `glance`. With those methods registered, none of these five generics called on an `icc()` result returns the marker. With them registered, `format()`, `tidy()` and `glance()` on that result return values identical to the values computed before the registration, and the output that `print()` writes is identical to the output it wrote before.
- [ ] AC3: The command `` grep -rnE '\bicc_(dstudy|recommendation)\b|['"'"'"]icc['"'"'"]|[a-z]\.icc\b|S3method\([a-z.]+,icc\)|\}\{icc\}|\{\.cls icc\}|`icc`|\\code\{icc\}' R/ NAMESPACE tests/ man/ vignettes/ README.Rmd | grep -v -e '^tests/testthat/test-class-names.R:' -e 'exists("icc", mode = "function")' ``, run from the repo root in `zsh` or `bash`, prints no lines.
- [ ] AC4: With ggplot2 loaded, `ggplot2::autoplot()` on an `icc()` result and on a `d_study()` result each returns a `ggplot` object, and a test asserts both.
- [ ] AC5: The development section of `NEWS.md` carries an entry that names each of the three old class names with its new name. It says that code testing for an old class name must change to the new one, and that the change was made without a deprecation period. It also says that attaching both intraclass and performance still masks one of the two `icc()` functions.
- [ ] AC6: The `verify` slot of `cairn/PROFILE.md` is clean: `devtools::document()` leaves no diff, and `devtools::test()` reports no failures.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2
- AC3 → T2, T3, T4
- AC4 → T2, T3
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Write `tests/testthat/test-class-names.R` first: the three class-vector assertions (AC1) and the foreign-method test (AC2). Register the foreign methods with `registerS3method()` and remove them when the test ends with `withr::defer()` and `rm()` on the generic's `.__S3MethodsTable__.`. Use `skip_if_not_installed()` where a generic needs a Suggests package. See it red on the current code.
- [x] T2: Rename the `icc` class: the constructor at `R/icc.R:2660`, the methods in `R/icc-methods.R` and `R/autoplot.R` (`format`, `print`, `summary`, `tidy`, `glance`, `plot`, `autoplot`), the lazy registration at `R/zzz.R:13`, and the `d_study()` check and message at `R/d-study.R:210-211`. Update the roxygen that names the class and run `devtools::document()`.
- [x] T3: Rename `icc_dstudy` and `icc_recommendation` the same way: the constructors at `R/d-study.R:577` and `R/choose-icc.R:604`, their methods, `R/zzz.R:12`, and their roxygen. Keep the internal helper names `new_icc_recommendation()` and `resolve_icc_recommendation()`. Run `devtools::document()`.
- [x] T4: Update every remaining hit of the AC3 command in tests, comments, vignettes and README. Change the old names in `cairn/DESIGN.md`. Run the AC3 command and record its output in the work log.
- [x] T5: Append the D-entry for the GP2 exception if the plan commit did not carry it, and write the NEWS entry (AC5) under a breaking-changes heading. Before you write the masking sentence, observe it by attaching both packages in a fresh R session.
- [x] T6: Run the `verify` slot (`devtools::document()`, `devtools::test()`), then `air format .`.

## Work log

- 2026-10-16: created by /milestone-plan.
- 2026-10-16: tier check: milestone — routed by the /milestone §3 disposition the user selected (bug report from the insight session).
- 2026-10-16: question set: drop "icc" now or keep it as a second class for one release — drop it now, with a D-entry for the GP2 exception.
- 2026-10-16: question set: also prefix the `d_study()` and `choose_icc()` classes — rename both.
- 2026-10-16: plan gate chose dropping "icc" over keeping it as a second class because performance's `as.data.frame.icc` would still catch intraclass results and a class name cannot give a deprecation warning; falsified by a report of user code that breaks on the rename and that a transition class would have kept working.
- 2026-10-16: plan gate chose a simulated clash (foreign methods registered in a test) over adding performance to Suggests for a real-package test, because it needs no new dependency; falsified by a clash that the simulated methods do not reproduce.
- 2026-10-16: criteria audit (full mode, fresh Opus reader) returned 7 findings: (1) GP2, #6 and #7 block a plain rename → asked at the question set, D-entry added; (2) the regression test trips AC3 → that file excluded; (3) the count and a function-name line over-matched → count dropped, `exists("icc", mode = "function")` excluded; (4) the pattern missed NAMESPACE, Rd `\method`, `\code{}` and prose forms → pattern widened, DESIGN.md added to T4, the estimand spec left out on purpose; (5) foreign-method cleanup → moved to T1, `as.data.frame` left to AC1; (6, 7) no finding.
- 2026-10-16: inbox sweep: no open issues or PRs.
- 2026-10-16: T1: `test-class-names.R` written. On the current code both tests fail: the class vectors are the old ones, and the foreign `"icc"` methods return the marker for all five generics. The foreign-method helper restores any entry it replaced, so an `"icc"` method intraclass still has survives the test. Printed output is compared through `cli::cli_fmt()`.
- 2026-10-16: checkpoint, T2 to T5 not yet ticked (suite run pending): the rename in R/, tests and roxygen was delegated to one Sonnet subagent and the comment rewrap to a second. Verified: the AC3 command prints no lines after `devtools::document()`. The first subagent renamed the internal helpers `new_icc_recommendation()` and `resolve_icc_recommendation()` against T3, and I restored them. The fixture `bayesian-vignette-oracle.rds` stored two fits with class `"icc"`. Their class was set to `"intraclass_icc"` in place, with every other element checked identical, and the generating script's header records it. NEWS entry written (the plain-English linter reports 0 violations in it). The masking was observed in fresh sessions: the package attached last masks the `icc()` of the other. The DESIGN.md legacy-object note was corrected.
- 2026-10-16: claim audit: 46 claims read, 0 corrected — NEWS.md, data-raw/oracle-bayesian-vignette.R, tests/testthat/test-class-names.R, R/icc.R, R/d-study.R, R/choose-icc.R, R/zzz.R, R/design.R, man/, tests/testthat/test-occasions-vocabulary.R (fresh Opus reader; it also re-ran roxygen on a copy and found man/ and NAMESPACE byte-identical).
- 2026-10-16: T2 to T6 done. `devtools::test()`: 0 failed, 0 errors, 9994 passed, 4 skipped (vignettes not installed, and glmmTMB's point fit dying on two reducer-hint frames, both unrelated). `devtools::document()` leaves no diff, and `air format --check .` is clean. The D-entry (D-050) landed with the plan commit. Status set to review.

## Decisions

## Review
