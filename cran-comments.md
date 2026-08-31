## Resubmission

This is a resubmission of intraclass 0.1.0. The previous submission was
returned with:

    Flavor: r-devel-windows-x86_64
    Check: Overall checktime, Result: NOTE
      Overall checktime 11 min > 10 min

The check was too slow. Nothing about the package's behaviour has changed;
what changed is how much of the test suite runs on CRAN.

The suite's cost is concentrated in a few tests that fit the same model with
two engines (glmmTMB and lme4) over ragged multilevel designs, and in a few
exhaustive sweeps. Eight such tests, plus one file that is nothing
but glmmTMB/lme4 parity across 27 tests, now call `skip_on_cran()`. They
still run in this package's continuous integration on six configurations --
macOS, Windows and Linux across R-devel, release, oldrel-1 and the declared
floor -- and locally, where `NOT_CRAN` is set. Only CRAN's own re-running of
them is given up, on platforms that CI already covers.

Measured on win-builder R-devel, the flavor that reported the NOTE:
`checking tests` fell from **427s to 245s**. On win-builder R-release it
fell from **435s to 241s**. Locally, under `R CMD check --as-cran` with
`NOT_CRAN=false`, it fell from **243s/124s to 81s/42s**.

No exported behaviour, documentation or dependency changed in this
resubmission.

## R CMD check results

Local `R CMD check --as-cran` on the built `intraclass_0.1.0.tar.gz`, run
2026-08-30 21:46:43 UTC (the run's own clock) under R 4.6.1 (2026-06-24) on
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

That NOTE also carries a "possibly misspelled words in DESCRIPTION" list. The
Windows flavors report six words; the Debian flavor reported those six plus
`generalizability`, its dictionary differing:

    ICCs (8:19)
    Intraclass (2:15)
    Jorgensen (16:62)
    der (17:9)
    generalizability (8:36)   [Debian only]
    interrater (7:24)
    intraclass (7:47)

All seven are correct as written. `Intraclass`, `intraclass`, `interrater`,
`ICCs` and `generalizability` are the field's own terms, and appear in the
Title and Description for that reason. `Jorgensen` and `der` are parts of the
cited authors' surnames -- ten Hove, Jorgensen and van der Ark, the authors of
the multilevel method the Description references.

## Test environments

Every environment below has been run against this version, and its result is
reported with it.

- Local: macOS Tahoe 26.6.2 on `aarch64-apple-darwin23`, R 4.6.1 -- the
  `--as-cran` run reported above. **0 errors, 0 warnings, 1 note** (the new
  submission NOTE).

- win-builder, R-devel: Windows Server 2022 x64 (build 20348) on
  `x86_64-w64-mingw32`, R Under development (unstable) (2026-08-27 r90452
  ucrt), run 2026-08-30 21:34:16 UTC. **`Status: 1 NOTE`** -- 0 errors, 0
  warnings, the incoming-feasibility NOTE above. `checking tests` 245s;
  `re-building of vignette outputs` 115s.

- win-builder, R-release: the same platform, R 4.6.1 (2026-06-24 ucrt), run
  2026-08-30 22:55:40 UTC. **`Status: 1 NOTE`** -- 0 errors, 0 warnings, the
  same NOTE. `checking tests` 241s; `re-building of vignette outputs` 111s.

- GitHub Actions `R CMD check`, at commit
  `6500715` on the default branch -- the full six-configuration push matrix.
  All six **completed with conclusion `success`** on 2026-08-30:

  | Configuration | Result |
  |---|---|
  | macos-latest, R release | success |
  | windows-latest, R release | success |
  | ubuntu-latest, R devel | success |
  | ubuntu-latest, R release | success |
  | ubuntu-latest, R oldrel-1 | success |
  | ubuntu-latest, R 4.5.0 (the declared floor) | success |

  These runs set `NOT_CRAN=true`, so they execute the full suite, including
  every test skipped on CRAN.

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
