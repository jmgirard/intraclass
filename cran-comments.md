## Submission

This is the first submission of intraclass (0.1.0), a new package.

## R CMD check results

Local `R CMD check --as-cran` (R 4.6.1, macOS) returned:

    0 errors | 0 warnings | 0 notes

CRAN's incoming checks will additionally flag this as a new submission. Any
"possibly misspelled words in DESCRIPTION" it reports are correct: the surnames
ten Hove, Jorgensen, and van der Ark, and the `doi:` token in the reference.

## Test environments

- Local: macOS, R 4.6.1.
- GitHub Actions (R-CMD-check workflow, run on every push):
  - ubuntu-latest: R-devel, R-release, R-oldrel-1
  - windows-latest: R-release
  - macos-latest: R-release
- win-builder (R-devel and R-release) and R-hub will be run immediately before
  submission.

## Downstream dependencies

There are no downstream dependencies; this is a new package.

## Notes

The base install depends only on glmmTMB, cli, rlang, generics, tibble,
stats, and lifecycle. The alternate estimation engines (lme4, lavaan) and the
plotting layer (ggplot2) are optional and live in Suggests, gated behind
`rlang::check_installed()`, so they are not required to install or use the
package's core functionality. Examples and tests that need a Suggested package
skip gracefully when it is absent.
