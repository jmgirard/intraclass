## Resubmission

This is a resubmission. The previous submission was returned with:

    Flavor: r-devel-windows-x86_64
    Check: Overall checktime, Result: NOTE
      Overall checktime 11 min > 10 min

Package behaviour is unchanged. Eight long-running tests, plus one file of
engine-comparison tests, now call `skip_on_cran()`; they continue to run in
this package's continuous integration and locally. On win-builder,
`checking tests` fell from 427s to 245s (R-devel) and 435s to 241s
(R-release).

## Test environments

- Local: macOS Tahoe 26.6.2, aarch64-apple-darwin23, R 4.6.1
- win-builder: R-devel (2026-08-27 r90452) and R-release (4.6.1)
- GitHub Actions: macOS, Windows and Ubuntu, R-devel / release / oldrel-1,
  and R 4.5.0 (the declared minimum)

## R CMD check results

0 errors | 0 warnings | 1 note

The note is the one every first submission gets:

    New submission
    Maintainer: 'Jeffrey Girard <me@jmgirard.com>'

It also lists possibly misspelled words in DESCRIPTION. All are correct:
`ICCs`, `Intraclass`, `intraclass`, `interrater` and `generalizability` are
standard terms in this field, and `Jorgensen` and `der` are parts of the cited
authors' surnames (ten Hove, Jorgensen and van der Ark).

## Downstream dependencies

There are none; this is a new package.
