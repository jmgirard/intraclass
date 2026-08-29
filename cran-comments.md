## Submission

This is the first submission of intraclass (0.1.0), a new package.

## R CMD check results

Local `R CMD check --as-cran` on the built `intraclass_0.1.0.tar.gz`, run
2026-08-29 23:08:32 UTC (the run's own clock) under R 4.6.1 (2026-06-24) on
platform `aarch64-apple-darwin23`, running under macOS Tahoe 26.6.2, with
`NOT_CRAN=false`, returned:

    Status: 1 NOTE

    0 errors | 0 warnings | 1 note

The one NOTE is the incoming-feasibility NOTE every first submission gets:

    * checking CRAN incoming feasibility ... NOTE
    Maintainer: 'Jeffrey Girard <me@jmgirard.com>'

    New submission

Re-running the same check with `_R_CHECK_CRAN_INCOMING_=FALSE` returns
`Status: OK`, so that NOTE is the only one the package produces.

Both win-builder runs attached a "possibly misspelled words in DESCRIPTION"
list to that same NOTE, the two lists identical:

    ICCs (8:19)
    Intraclass (2:15)
    Jorgensen (16:62)
    der (17:9)
    interrater (7:24)
    intraclass (7:47)

All six are correct as written. `Intraclass`, `intraclass`, `interrater` and
`ICCs` are the field's own terms, and appear in the Title and Description for
that reason. `Jorgensen` and `der` are parts of the cited authors' surnames --
ten Hove, Jorgensen and van der Ark, the authors of the multilevel method the
Description references.

## Test environments

Every environment below has been run against version 0.1.0, and its result is
reported with it.

- Local: macOS Tahoe 26.6.2 on `aarch64-apple-darwin23`, R 4.6.1 -- the
  `--as-cran` run reported above. **0 errors, 0 warnings, 1 note** (the new
  submission NOTE).

- win-builder, R-devel: Windows Server 2022 x64 (build 20348) on
  `x86_64-w64-mingw32`, R Under development (unstable) (2026-08-27 r90452
  ucrt), run 2026-08-29 23:19:20 UTC. **`Status: 1 NOTE`** -- 0 errors, 0
  warnings, the incoming-feasibility NOTE above.

- win-builder, R-release: the same platform, R 4.6.1 (2026-06-24 ucrt), run
  2026-08-29 23:10:14 UTC. **`Status: 1 NOTE`** -- 0 errors, 0 warnings, the
  same NOTE.

- GitHub Actions `R CMD check`, at commit
  `84abf5d78ebedcc97d4ce4cd09a7bc58cf476367` on the default branch -- the full
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

  The tarball checked above was built from that same commit with a clean
  working tree, so the matrix, both win-builder runs and the local check all
  describe one package content. The only path changed on the default branch
  after that commit is this file, which `.Rbuildignore` excludes and which
  appears nowhere in the tarball's 198-entry manifest.

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
