## Submission

This is the first submission of intraclass (0.1.0), a new package.

## R CMD check results

Local `R CMD check --as-cran` on 2026-08-27 (the run's own clock, UTC), under
R 4.6.1 (2026-06-24) on platform `aarch64-apple-darwin23`, running under
macOS Tahoe 26.6.2, with `NOT_CRAN=false` and `manual = TRUE`, returned:

    0 errors | 0 warnings | 0 notes

CRAN's incoming checks will additionally flag this as a new submission. Any
"possibly misspelled words in DESCRIPTION" it reports are correct: the surnames
ten Hove, Jorgensen, and van der Ark, and the `doi:` token in the reference.

## Test environments

Checked so far:

- Local: macOS Tahoe 26.6.2 on `aarch64-apple-darwin23`, R 4.6.1 — the
  `--as-cran` run reported above.
- GitHub Actions, on the release pull request: ubuntu-latest R-release,
  windows-latest R-release, and ubuntu-latest R 4.5.0 (the declared floor).

Scheduled before submission, not yet run against this version:

- GitHub Actions, on the merge commit: the full workflow matrix — ubuntu-latest
  R-devel / R-release / R-oldrel-1 / R 4.5.0, windows-latest R-release,
  macos-latest R-release. (The six-config matrix runs on push to the default
  branch; a pull request runs the three configurations listed above.)
- win-builder (R-devel and R-release) and R-hub.

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
