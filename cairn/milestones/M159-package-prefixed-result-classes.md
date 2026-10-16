# M159: Result classes take the package prefix, so performance cannot replace their methods

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** user-facing — users see the result class through `class()`, `inherits()` and the help pages
- **Branch/PR:** m159-package-prefixed-result-classes, https://github.com/jmgirard/intraclass/pull/178

## Goal

The results of `icc()`, `d_study()` and `choose_icc()` carry the classes `"intraclass_icc"`, `"intraclass_dstudy"` and `"intraclass_recommendation"`, and no method that another package registers on `"icc"` changes them.

## Scope

**In:** rename the three result classes and every S3 method on them (`R/icc.R:2660`, `R/d-study.R:577`, `R/choose-icc.R:604`, `R/icc-methods.R`, `R/autoplot.R`, `R/zzz.R:12-13`). Change the class check and message in `d_study()` (`R/d-study.R:210-211`). Update roxygen, regenerated `man/` and `NAMESPACE`, tests, the vignettes and README where they name a class. Add a regression test for the performance clash, a NEWS entry, a D-entry for the GP2 exception, and the old names in `cairn/DESIGN.md`.

**Out:** the masking of one `icc()` function by the other when both packages are attached. A class change cannot fix it, so the NEWS entry only states it. An `as.data.frame()` method for intraclass results stays out, because no request names one. Results saved under 0.1.0 keep the old class and are not converted; the NEWS entry says to re-run `icc()`. The `parameters::model_parameters()` method is the candidate row "easystats model_parameters method". `cairn/estimand-specs/M4.5-d-study.md` keeps the old names, because it is a historical spec.

## Acceptance criteria

- [x] AC1: `icc()` returns an object whose class vector is exactly `"intraclass_icc"`. `choose_icc()` returns an object whose class vector is exactly `"intraclass_recommendation"`. `d_study()` returns an object whose first class is `"intraclass_dstudy"` and whose class vector contains none of `"icc"`, `"icc_dstudy"` and `"icc_recommendation"`. A test asserts each of these three class vectors.
- [x] AC2: A test registers, on class `"icc"`, a method that returns a fixed marker value for each of `print`, `format`, `summary`, `tidy` and `glance`. With those methods registered, none of these five generics called on an `icc()` result returns the marker. With them registered, `format()`, `tidy()` and `glance()` on that result return values identical to the values computed before the registration, and the output that `print()` writes is identical to the output it wrote before.
- [x] AC3: The command `` grep -rnE '\bicc_(dstudy|recommendation)\b|['"'"'"]icc['"'"'"]|[a-z]\.icc\b|S3method\([a-z.]+,icc\)|\}\{icc\}|\{\.cls icc\}|`icc`|\\code\{icc\}' R/ NAMESPACE tests/ man/ vignettes/ README.Rmd | grep -v -e '^tests/testthat/test-class-names.R:' -e 'exists("icc", mode = "function")' ``, run from the repo root in `zsh` or `bash`, prints no lines.
- [x] AC4: With ggplot2 loaded, `ggplot2::autoplot()` on an `icc()` result and on a `d_study()` result each returns a `ggplot` object, and a test asserts both.
- [x] AC5: The development section of `NEWS.md` carries an entry that names each of the three old class names with its new name. It says that code testing for an old class name must change to the new one, and that the change was made without a deprecation period. It also says that attaching both intraclass and performance still masks one of the two `icc()` functions.
- [x] AC6: The `verify` slot of `cairn/PROFILE.md` is clean: `devtools::document()` leaves no diff, and `devtools::test()` reports no failures.

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
- 2026-10-16: step-7 approval: m159-package-prefixed-result-classes approved for merge

## Decisions

## Review

Pass 1 (2026-10-16), on branch head `37b8c0e`, main not moved since the branch was cut.

- AC1 evidence: fresh `devtools::test()` ran `test-class-names.R` with 0 failures. Its first test asserts `class(icc(...))` is exactly `"intraclass_icc"`, `class(choose_icc(...))` is exactly `"intraclass_recommendation"`, and `d_study()`'s first class is `"intraclass_dstudy"` with none of the three old names. The diff-bug reviewer confirmed all three class vectors directly.
- AC2 evidence: the same run passed the second test in `test-class-names.R`. It registers marker methods on `"icc"` for `print`, `format`, `summary`, `tidy` and `glance`, then asserts that no generic returns the marker, that `format()`, `tidy()` and `glance()` are identical to their values before the registration, and that the `cli::cli_fmt()` capture of `print()` is identical. On the pre-rename code (T1, `c23fbd0`) every marker assertion failed, so the foreign methods did reach an `"icc"` object.
- AC3 evidence: the AC3 command, run from the repo root in `zsh`, prints 0 lines. The same pattern over `main` (`git grep -nE` on the same paths) finds 68 lines, so the search reaches old-name uses when they exist.
- AC4 evidence: the fresh run passed `test-autoplot.R` with ggplot2 installed and 0 skips there. It asserts `expect_s3_class(p, "ggplot")` on `autoplot()` of an `icc()` result and of a `d_study()` result. The diff-bug reviewer also called both through the lazy registration and got ggplot objects.
- AC5 evidence: `NEWS.md` "## Breaking changes" under the development heading names `icc` → `intraclass_icc`, `icc_dstudy` → `intraclass_dstudy` and `icc_recommendation` → `intraclass_recommendation`. It says code testing an old name must use the new one, that the change has no deprecation period, and that the package attached last masks the other's `icc()`. The masking was observed in fresh sessions in both attach orders, and the claim audit verified each sentence.
- AC6 evidence: `devtools::document()` leaves `git status` empty. Fresh `devtools::test()`: 0 failed, 0 errors, 9994 passed, 4 skipped (vignettes not installed, and glmmTMB's point fit dying on reducer-hint frames, as on main).

Consistency gate: `cairn_validate.py` all checks passed. `devtools::document()` no diff. README.Rmd and README.md unchanged. `pkgdown::check_pkgdown()` no problems. NEWS entry present with no milestone numbers. No new top-level files. `devtools::check()` Status OK (0 errors, 0 warnings, 0 notes). `air format --check .` clean. `cairn_impact.py --changed` is run after the GP2 annotation below.

spawned: diff-bug, blame-history, prior-review

- diff-bug #1: AC2's test has no positive control, so a foreign registration that silently failed would leave every "not the marker" assertion passing — fix now, fixed 648d3c8.
- diff-bug #2: the DESIGN.md Known issues entry speaks of a legacy `intraclass_dstudy` object with no `icc_design_label`, which no version can build, so the fallbacks are unreachable — fix now (reword the entry), fixed 648d3c8.
- diff-bug #3: DESIGN.md GP2 does not point to D-050's class-name exception — fix now, fixed 648d3c8.
- diff-bug #4: DESIGN.md Conventions does not record that result classes take the `intraclass_` prefix — fix now, fixed 648d3c8.
- diff-bug #5: "## Breaking changes" sits after two ungrouped feature bullets in NEWS — reject (style).
- diff-bug #6: the test cleanup's `rm()` would warn if something removed the entry first — reject (false: no code path removes it, and the reviewer found none).
- diff-bug #7: `d[, 1:2]` on a `d_study()` result keeps the class and `format()` then fails with "subscript out of bounds", the same on main — follow-up (new candidate row "M159 review follow-ups on the renamed result classes").
- blame-history #1: the fixture was edited in place, against the script-output rule and D-024 clause 4 — reject (false: D-024 governs re-runs that replace values, and this edit replaced no value; every element except the two class attributes is `identical()` to main, and a rerun now writes the same class).
- blame-history #2: `d_study()` rejects a saved 0.1.0 `icc` object with no hint to re-run `icc()` — follow-up (same new row: a hint needs the old class string in R/, which AC3 forbids in this milestone).
- blame-history #3: the foreign-method test changes S3 tables and relies on withr — reject (false: cleanup restores the replaced entry, and withr is in Suggests at `DESCRIPTION:46`).
- blame-history #4 to #9: reflow lost no words, vocabulary pins match, the lint suppressions and `R/zzz.R` are intact, kept names are intact, GP2 and D-050 agree — noted, no change.
- prior-review #1: old method names stay in `cairn/doctrine/prose-style.md:10-11`, the ROADMAP display-surfaces row and `cairn/LESSONS.md:29`, the stale-rename shape of M48 P5 — fix now, fixed 648d3c8.
- prior-review #2: `test-class-names.R` compares two `cli::cli_fmt()` captures with no non-empty check (LESSONS M129) — fix now, with diff-bug #1, fixed 648d3c8.

After the fixes: full `devtools::test()` on `648d3c8` gave 0 failed, 0 errors, 10000 passed, 4 skipped (the 6 added expectations are the positive control and the non-empty check). `cairn_validate.py` all checks passed. `cairn_impact.py --changed` reports no changed principles (GP2 gained a pointer to D-050, its rule text unchanged). The linter count on `cairn/doctrine/prose-style.md` is 36 before and after the edit.
