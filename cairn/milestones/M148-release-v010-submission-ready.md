# M148: v0.1.0 is submission-ready, and the upload is handed off

- **Status:** planned
- **Priority:** high
- **Depends on:** M147
- **Driving RR:** —
- **Principles touched:** GP2, GP3
- **Branch/PR:** —

## Goal

Close the v0.1.0 release the maintainer declared open: a tarball that checks
clean, a `cran-comments.md` in which every environment named carries a result,
and an ordered handoff checklist for the acts ADR-022 reserves to the
maintainer.

## Scope

Surface tier: **user-facing** — the deliverable is the source tarball a CRAN
reviewer receives and the submission record they read alongside it.

**In:** a fresh `R CMD check --as-cran` on the built tarball; the six-config
matrix result read from the check-runs API at a pinned SHA, with the tarball
manifest establishing that the matrix tested the content being submitted;
`cran-comments.md` rewritten so it claims nothing unrun; `urlchecker`;
`cairn/RELEASE-HANDOFF.md`.

**Out:** the win-builder and R-hub round-trips and `devtools::submit_cran()` —
ADR-022 records them as "the maintainer's, not this milestone's ... deferred",
and they land as numbered steps of `cairn/RELEASE-HANDOFF.md`, whose execution
is out of band; `usethis::use_github_release()` and `use_dev_version()`, same
checklist, after CRAN accepts; the `type = "both"` chooser change → M147; any
version bump or NEWS consolidation, both already done (`DESCRIPTION:4`,
`NEWS.md:1`).

## Acceptance criteria

- [ ] AC1. `R CMD check --as-cran` on the tarball `R CMD build` produces from
      the release head reports `Status: OK` — 0 errors, 0 warnings, 0 notes —
      read off the check output's own `Status:` line, never `devtools::check()`'s
      0/0/0 summary, which hides the `spelling.Rout.save` NOTE (M127, corrected
      M128 and M145). `cran-comments.md` reports that run's R version,
      platform, OS and date, taken from the run's own header.
- [ ] AC2. `cran-comments.md`'s *Test environments* section reports, at a
      pinned commit SHA, that every configuration in
      `.github/workflows/check-standard.yaml:38`'s push-event matrix — six of
      them — is `completed` with conclusion `success` in
      `gh api repos/jmgirard/intraclass/commits/<SHA>/check-runs`; and every
      path listed by `git diff --name-only <SHA>..<release head>` is absent
      from `tar tzf` on the AC1 tarball, so the matrix tested the package
      content being submitted.
- [ ] AC3. Every environment named in `cran-comments.md`'s *Test environments*
      section is followed, in that same section, by a reported result for
      version 0.1.0; the "Scheduled before submission, not yet run against this
      version" block is gone.
- [ ] AC4. `cairn/RELEASE-HANDOFF.md` exists and lists, in execution order,
      each act ADR-022 reserves to the maintainer, with the exact command to
      run: the win-builder R-devel and R-release round-trips, R-hub,
      `devtools::submit_cran()`, confirming the CRAN email,
      `usethis::use_github_release()`, `usethis::use_dev_version()`.
- [ ] AC5. `urlchecker::url_check()` reports no broken URL across the package
      sources.

## Coverage

- AC1 → T2, T4
- AC2 → T1, T3, T4
- AC3 → T4
- AC4 → T5
- AC5 → T2

## Tasks

- [ ] T1. After M147 merges, read
      `gh api repos/jmgirard/intraclass/commits/<M147 merge SHA>/check-runs`
      and confirm all six push-event configurations completed successfully.
      Pin the head with `gh pr view --json headRefOid`; `gh` 2.98 rejects a
      bare SHA as a `gh pr checks` argument, and app-posted statuses land
      minutes late, so read the API rather than an early `gh pr checks` (M48).
- [ ] T2. Branch. `R CMD build`, then `R CMD check --as-cran` on the resulting
      tarball; transcribe the raw `Status:` line and the run's own header.
      `urlchecker::url_check()`.
- [ ] T3. `tar tzf intraclass_0.1.0.tar.gz` against
      `git diff --name-only <pinned SHA>..HEAD`; confirm the diff touches only
      `.Rbuildignore`d paths (`cran-comments.md` and `cairn/` both are), and
      record both lists.
- [ ] T4. Rewrite `cran-comments.md`: AC1's run header and result, AC2's
      matrix reading with its SHA, and the *Test environments* section with no
      unrun environment left in it.
- [ ] T5. Write `cairn/RELEASE-HANDOFF.md` from `cairn/PROFILE.md:76-81`'s
      release-walk handoff list plus ADR-022's deferred round-trips.
- [ ] T6. Gate: `air format .`, `devtools::document()` no-diff, the `data-raw/`
      checkers with `--self-test`, `devtools::test()`. Open the PR and read its
      check-runs against the pinned head SHA.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: the maintainer declared the v0.1.0 release window open at this plan's question gate, so the release-shaped tripwire is satisfied and this lands `planned` at high priority rather than as a candidate row. The window was first declared 2026-08-26 at the M138 review close (recorded at `aec71d2`).
- 2026-08-28: plan-gate criteria audit ran in FULL mode (user-facing tier), in-session rather than in a fresh-context [O] subagent — agent delegation is not authorized this session, the same departure M145 and M146 recorded. Two findings, both fixed at the gate. (a) A draft AC promised the six-config matrix green on the release PR; unreachable as written, since `check-standard.yaml:38` runs six configurations only on `push` to the default branch and three on `pull_request`, so no state during the milestone satisfies it — the M114 class the audit exists to catch. Repaired into AC2's pinned-SHA reading plus the tarball-manifest identity clause. (b) A draft AC bound "each command's output transcribed into the milestone's evidence", an instrument-and-recording property rather than a deliverable property (D-118, D-120); the transcription moved into T2 and T3.
- 2026-08-28: collision check found M48 (`release-v010`) done and archived, its descoped AC3 already landed as M140; no `planned` or `blocked` release row, and no candidate row or live D-entry rejecting a release. ADR-022's deferral of the win-builder/R-hub round-trips and `submit_cran()` is a scope fence, honoured by AC4 rather than superseded.
- 2026-08-28: plan gate chose pinning M147's merge SHA plus a tarball-manifest identity check over re-running the six-config matrix on this milestone's own merge commit, because the six-config matrix runs only post-merge and a criterion resting on it could not be verified at the review gate; falsified by this milestone's PR needing to touch a path that enters the built tarball, which would break the identity clause.

## Decisions

## Review
- 2026-08-28: the maintainer re-declared the v0.1.0 release window open at the M147 review close, in answer to `cairn_validate`'s `release window` advisory (D-050). M148 stays `planned` and is the next action; nothing on it started here.
