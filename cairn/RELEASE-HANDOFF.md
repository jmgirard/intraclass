# v0.1.0 release handoff — the maintainer's steps

Scope: the acts ADR-022 reserves to the maintainer, performed out of band after
M148 merges. cairn never runs these (D-050: release timing is user-declared;
`/cairn-release` never self-submits). This file is the checklist, not a record
of execution — nothing here is claimed done by its presence.

Run every step from the repo root on the default branch, with the working tree
clean and synced with `origin`.

## 1. win-builder, R-devel

```r
devtools::check_win_devel()
```

Sends the built tarball to win-builder. The result arrives by email at the
`Maintainer:` address in `DESCRIPTION` (jeffgirard@gmail.com), typically within
30 minutes. Read the emailed `00check.log`; 0 errors / 0 warnings is the bar,
and a new-submission NOTE is expected.

## 2. win-builder, R-release

```r
devtools::check_win_release()
```

Same round trip against the current R release. Wait for both win-builder
results before step 4.

## 3. R-hub

`rhub` is not installed locally (checked 2026-08-29). rhub 2.x runs the checks
as GitHub Actions workflows in this repo, so it needs a one-time setup commit
before the first check:

```r
install.packages("rhub")
rhub::rhub_setup()   # commits .github/workflows/rhub.yaml; push it
rhub::rhub_doctor()  # confirms the token and workflow are in place
rhub::rhub_check()   # pick the platforms at the prompt
```

If `rhub_setup()` adds a workflow file, give it an `.Rbuildignore` entry only if
`^\.github$` does not already cover it (it does today), and let the workflow run
green before step 4.

## 4. Add the step 1-3 results to `cran-comments.md`, then submit

`cran-comments.md` names only environments already run, each with its result
(M148 AC3), so win-builder and R-hub are absent from it today. Add them to the
*Test environments* section with their outcomes before submitting, and commit
that edit — it is a `.Rbuildignore`d file, so a docs-only commit to the default
branch is the right home.

```r
devtools::submit_cran()
```

Reads `cran-comments.md` and uploads the tarball. Confirm the version and the
comments text at the prompt before answering yes.

## 5. Confirm the CRAN submission email

CRAN emails the `Maintainer:` address a confirmation link. Nothing enters the
queue until that link is followed. Do this within the window the email states.

## 6. Tag the GitHub release — after CRAN accepts

```r
usethis::use_github_release()
```

Drafts a GitHub release from the `NEWS.md` 0.1.0 section against the merge
commit. Run it only once CRAN's acceptance email has arrived, so the tag names
the version CRAN actually took.

## 7. Open the development version

```r
usethis::use_dev_version()
```

Bumps `DESCRIPTION` to `0.1.0.9000` and opens a development heading in
`NEWS.md`. Commit and push the result to the default branch.

## If CRAN sends back a request

A reviewer's change request is a `/hotfix` or a new milestone, not an edit made
in this checklist: fix on a branch, merge through the normal gate, bump the
version, then resume at step 4.
