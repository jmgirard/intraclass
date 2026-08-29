## Submission

This is the first submission of intraclass (0.1.0), a new package.

## R CMD check results

Local `R CMD check --as-cran` on the built `intraclass_0.1.0.tar.gz`, run
2026-08-29 03:25:39 UTC (the run's own clock) under R 4.6.1 (2026-06-24) on
platform `aarch64-apple-darwin23`, running under macOS Tahoe 26.6.2, with
`NOT_CRAN=false`, returned:

    Status: 1 NOTE

    0 errors | 0 warnings | 1 note

The one NOTE is the incoming-feasibility NOTE every first submission gets:

    * checking CRAN incoming feasibility ... NOTE
    Maintainer: 'Jeffrey Girard <jeffgirard@gmail.com>'

    New submission

Re-running the same check with `_R_CHECK_CRAN_INCOMING_=FALSE` returns
`Status: OK`, so that NOTE is the only one the package produces.

If CRAN's incoming checks report "possibly misspelled words in DESCRIPTION",
the words are correct: the surnames ten Hove, Jorgensen, and van der Ark, and
the `doi:` token in the reference.

## Test environments

Every environment below has been run against version 0.1.0, and its result is
reported with it.

- Local: macOS Tahoe 26.6.2 on `aarch64-apple-darwin23`, R 4.6.1 — the
  `--as-cran` run reported above. **0 errors, 0 warnings, 1 note** (the new
  submission NOTE).

- GitHub Actions `R CMD check`, at commit
  `0d651437c5e01ed76551c729be9e5ee456caa999` on the default branch — the full
  six-configuration push matrix. All six **completed with conclusion
  `success`** on 2026-08-29:

  | Configuration | Result |
  |---|---|
  | macos-latest, R release | success |
  | windows-latest, R release | success |
  | ubuntu-latest, R devel | success |
  | ubuntu-latest, R release | success |
  | ubuntu-latest, R oldrel-1 | success |
  | ubuntu-latest, R 4.5.0 (the declared floor) | success |

  Every path changed between that commit and the submitted source is excluded
  from the built tarball by `.Rbuildignore` — seven under `cairn/` or
  `data-raw/`, plus this file, which has its own entry — so the matrix ran
  against the package content submitted here.

## Downstream dependencies

There are no downstream dependencies; this is a new package.

## Notes

The declared R floor is `R (>= 4.5.0)`, the lowest R release on which the
Imports chain installs, measured across R 4.0.0-4.5.1 on CI rather than read
off a `Depends` field: glmmTMB requires pbkrtest (R >= 4.2.0), which requires
doBy and Deriv, and Deriv 4.3.0 does not compile before R 4.5.0. A CI job runs
`R CMD check` on exactly 4.5.0.

The base install depends only on glmmTMB, cli, rlang, generics, tibble,
stats, and lifecycle. The alternate estimation engines (lme4, lavaan, brms) and
the plotting layer (ggplot2) are optional and live in Suggests, gated behind
`rlang::check_installed()`, so they are not required to install or use the
package's core functionality. Examples and tests that need a Suggested package
skip gracefully when it is absent.

The full test suite also passes against the installed package with
`NOT_CRAN=true CI=true`, which runs the longer engine and simulation tests that
are skipped on CRAN.
