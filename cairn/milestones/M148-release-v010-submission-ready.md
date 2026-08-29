# M148: v0.1.0 is submission-ready, and the upload is handed off

- **Status:** review
- **Priority:** high
- **Depends on:** M147
- **Driving RR:** —
- **Principles touched:** GP2, GP3
- **Branch/PR:** `m148-release-v010-submission-ready` / https://github.com/jmgirard/intraclass/pull/159

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

- [x] AC1. `R CMD check --as-cran` on the tarball `R CMD build` produces from
      the release head reports 0 errors and 0 warnings on the check output's
      own `Status:` line, and any NOTE it reports is the CRAN
      incoming-feasibility "New submission" NOTE — both read off the check
      output itself, never `devtools::check()`'s 0/0/0 summary, which hides
      the `spelling.Rout.save` NOTE (M127, corrected M128 and M145).
      `cran-comments.md` reports that run's R version, platform, OS and date,
      taken from the run's own header, and its `Status:` result including any
      NOTE.
- [x] AC2. `cran-comments.md`'s *Test environments* section reports, at a
      pinned commit SHA, that every configuration in
      `.github/workflows/check-standard.yaml:38`'s push-event matrix — six of
      them — is `completed` with conclusion `success` in
      `gh api repos/jmgirard/intraclass/commits/<SHA>/check-runs`; and every
      path listed by `git diff --name-only <SHA>..<release head>` is absent
      from `tar tzf` on the AC1 tarball, so the matrix tested the package
      content being submitted.
- [x] AC3. Every environment named in `cran-comments.md`'s *Test environments*
      section is followed, in that same section, by a reported result for
      version 0.1.0; the "Scheduled before submission, not yet run against this
      version" block is gone.
- [x] AC4. `cairn/RELEASE-HANDOFF.md` exists and lists, in execution order,
      each act ADR-022 reserves to the maintainer, with the exact command to
      run: the win-builder R-devel and R-release round-trips, R-hub,
      `devtools::submit_cran()`, confirming the CRAN email,
      `usethis::use_github_release()`, `usethis::use_dev_version()`.
- [x] AC5. `urlchecker::url_check()` reports no broken URL across the package
      sources.

## Coverage

- AC1 → T2, T4
- AC2 → T1, T3, T4
- AC3 → T4
- AC4 → T5
- AC5 → T2

## Tasks

- [x] T1. After M147 merges, read
      `gh api repos/jmgirard/intraclass/commits/<M147 merge SHA>/check-runs`
      and confirm all six push-event configurations completed successfully.
      Pin the head with `gh pr view --json headRefOid`; `gh` 2.98 rejects a
      bare SHA as a `gh pr checks` argument, and app-posted statuses land
      minutes late, so read the API rather than an early `gh pr checks` (M48).
- [x] T2. Branch. `R CMD build`, then `R CMD check --as-cran` on the resulting
      tarball; transcribe the raw `Status:` line and the run's own header.
      `urlchecker::url_check()`.
- [x] T3. `tar tzf intraclass_0.1.0.tar.gz` against
      `git diff --name-only <pinned SHA>..HEAD`; confirm the diff touches only
      `.Rbuildignore`d paths (`cran-comments.md` and `cairn/` both are), and
      record both lists.
- [x] T4. Rewrite `cran-comments.md`: AC1's run header and result, AC2's
      matrix reading with its SHA, and the *Test environments* section with no
      unrun environment left in it.
- [x] T5. Write `cairn/RELEASE-HANDOFF.md` from `cairn/PROFILE.md:76-81`'s
      release-walk handoff list plus ADR-022's deferred round-trips.
- [x] T6. Gate: `air format .`, `devtools::document()` no-diff, the `data-raw/`
      checkers with `--self-test`, `devtools::test()`. Open the PR and read its
      check-runs against the pinned head SHA.

## Work log

- 2026-08-28: created by /milestone-plan.
- 2026-08-28: the maintainer declared the v0.1.0 release window open at this plan's question gate, so the release-shaped tripwire is satisfied and this lands `planned` at high priority rather than as a candidate row. The window was first declared 2026-08-26 at the M138 review close (recorded at `aec71d2`).
- 2026-08-28: plan-gate criteria audit ran in FULL mode (user-facing tier), in-session rather than in a fresh-context [O] subagent — agent delegation is not authorized this session, the same departure M145 and M146 recorded. Two findings, both fixed at the gate. (a) A draft AC promised the six-config matrix green on the release PR; unreachable as written, since `check-standard.yaml:38` runs six configurations only on `push` to the default branch and three on `pull_request`, so no state during the milestone satisfies it — the M114 class the audit exists to catch. Repaired into AC2's pinned-SHA reading plus the tarball-manifest identity clause. (b) A draft AC bound "each command's output transcribed into the milestone's evidence", an instrument-and-recording property rather than a deliverable property (D-118, D-120); the transcription moved into T2 and T3.
- 2026-08-28: collision check found M48 (`release-v010`) done and archived, its descoped AC3 already landed as M140; no `planned` or `blocked` release row, and no candidate row or live D-entry rejecting a release. ADR-022's deferral of the win-builder/R-hub round-trips and `submit_cran()` is a scope fence, honoured by AC4 rather than superseded.
- 2026-08-28: plan gate chose pinning M147's merge SHA plus a tarball-manifest identity check over re-running the six-config matrix on this milestone's own merge commit, because the six-config matrix runs only post-merge and a criterion resting on it could not be verified at the review gate; falsified by this milestone's PR needing to touch a path that enters the built tarball, which would break the identity clause.
- 2026-08-29: T5 — wrote `cairn/RELEASE-HANDOFF.md`: seven numbered steps (win-builder devel, win-builder release, R-hub, `submit_cran()`, the CRAN confirmation email, `use_github_release()`, `use_dev_version()`), each with its command, plus a send-back route. `rhub` is absent locally (measured 2026-08-29), so step 3 carries the install and the rhub 2.x `rhub_setup()`/`rhub_doctor()` sequence. No R source touched, so the verify slot's `devtools::test()` has nothing to discriminate here; it runs at T6.

- 2026-08-29: T2 — `R CMD build` then `R CMD check --as-cran` on `intraclass_0.1.0.tar.gz`, run 2026-08-29 03:25:39 UTC under R 4.6.1 (2026-06-24) on `aarch64-apple-darwin23`, macOS Tahoe 26.6.2: `Status: 1 NOTE`, the NOTE being the CRAN incoming-feasibility "New submission" NOTE (body: the `Maintainer:` line and `New submission`). A re-run with `_R_CHECK_CRAN_INCOMING_=FALSE` returned `Status: OK`, pinning that NOTE's identity. `urlchecker::url_check(".")` fetched 15 URLs and returned 0 rows (AC5).
- 2026-08-29: substantive amendment, adopted at a mini gate. AC1 demanded `Status: OK` with 0 notes; unreachable on a networked `--as-cran` run for a package not yet on CRAN, since the incoming-feasibility check reports "New submission" for every first submission. AC1 now binds 0 errors, 0 warnings, and any reported NOTE being that one. It narrows nothing else and adds no criterion. Amended text in the Acceptance criteria section above.
- 2026-08-29: the amendment's criteria audit ran in FULL mode (user-facing tier) on the amended AC1 wording before it was written, in-session rather than in a fresh-context [O] subagent — agent delegation is not authorized this session, the same departure M145, M146 and M147 recorded. One finding, fixed before the text landed: a draft bound the new-submission NOTE as "its only NOTE", which a run reporting zero NOTEs could not satisfy; narrowed to "any NOTE it reports is". The satisfiability, reachability, bounded-promise, instrument and proportionality questions returned nothing else; the probe question does not apply, AC1 citing no mutation or planted-defect verification.
- 2026-08-29: T3 — the pinned SHA is `0d65143` (the M147 squash merge, the only recent default-branch commit carrying the six-config matrix; the two later tracking commits ran only the lighter workflows). `git diff --name-only 0d65143..HEAD` lists seven paths, all under `cairn/` or `data-raw/`: `cairn/LESSONS.md`, `cairn/RELEASE-HANDOFF.md`, `cairn/ROADMAP.md`, `cairn/milestones/M147-choose-icc-type-both.md`, `cairn/milestones/M148-release-v010-submission-ready.md`, `cairn/milestones/archive/M147-choose-icc-type-both.md`, `data-raw/record-claims.tsv`. None appears in the 197-entry `tar tzf` manifest of the AC1 tarball, which holds no `cairn/` or `data-raw/` entry at all; `DESCRIPTION`, `NAMESPACE` and `R/icc.R` were looked up the same way as passing controls. Re-run at T6 against the final head.

- 2026-08-29: T1 — all six push-event configurations at the pinned SHA `0d651437c5e01ed76551c729be9e5ee456caa999` read `completed` / `success` from `gh api repos/jmgirard/intraclass/commits/<SHA>/check-runs`, completing between 03:27:52Z and 03:46:14Z: macos-latest release, windows-latest release, ubuntu-latest devel / release / oldrel-1 / 4.5.0. The two later default-branch commits are tracking-only and ran no `R CMD check` job, so this merge commit is the newest default-branch head the six-config matrix covers.
- 2026-08-29: T4 — rewrote `cran-comments.md`. *R CMD check results* now carries the 2026-08-29 03:25:39 UTC run's own header and `Status: 1 NOTE`, quotes the NOTE, and reports the `_R_CHECK_CRAN_INCOMING_=FALSE` re-run that pins it as the only one. *Test environments* names two environments — the local run and the six-config matrix at the pinned SHA, tabulated per configuration — each with its result, plus the tarball-manifest identity sentence; the "Scheduled before submission, not yet run against this version" block is gone, and win-builder and R-hub are named nowhere in the file (0 matches). `cairn/RELEASE-HANDOFF.md` step 4 accordingly tells the maintainer to add those results to *Test environments* before submitting.

- 2026-08-29: T6 gate — `air format .` no diff; `devtools::document()` no diff; all six `data-raw/` checkers pass `--self-test` (each plants its own defect class and sees it red) and pass in normal mode; `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 9465, the three WARNs being the standing candidate-row set re-measured at the M143 review, none a new site. T3's identity check re-run at the final head: the diff from the pinned SHA is eight paths, `cran-comments.md` now joining the seven, and all eight are absent from the tarball manifest.

- 2026-08-29: PR #159 opened; all 9 checks on its head pass — the three-configuration pull-request matrix (ubuntu-latest release, ubuntu-latest 4.5.0, windows-latest release) plus check-references, checkpoint-guard, format-check, lint, pkgdown, test-coverage. Status set to review.
- 2026-08-29: review — all five criteria verified with fresh evidence at head `f280612`; consistency gate clean (`cairn_validate` exit 0, toolchain slot checks pass); three lenses run in-session (delegation not authorized this session), one finding, put to the maintainer at the gate.
- 2026-08-29: merge gate — maintainer selected fix-then-merge; finding 1's clause corrected in `cran-comments.md` on the branch before the approval marker.

## Decisions

## Review

- 2026-08-28: the maintainer re-declared the v0.1.0 release window open at the M147 review close, in answer to `cairn_validate`'s `release window` advisory (D-050). M148 stays `planned` and is the next action; nothing on it started here.

### Acceptance-criteria evidence (2026-08-29, fresh at head `f280612`)

- AC1 — verified. Fresh `R CMD build` + `R CMD check --as-cran` on `intraclass_0.1.0.tar.gz`, run 2026-08-29 05:08:56 UTC: header reads R 4.6.1 (2026-06-24), platform `aarch64-apple-darwin23`, running under macOS Tahoe 26.6.2; `Status: 1 NOTE`, that NOTE being `checking CRAN incoming feasibility ... NOTE` with body `Maintainer:` plus `New submission`, and no other NOTE, WARNING or ERROR line in the log. `cran-comments.md` reports the same R version, platform, OS and date (2026-08-29) from the run's own header, and its `Status: 1 NOTE` result with the NOTE quoted.
- AC2 — verified. `gh api repos/jmgirard/intraclass/commits/0d651437c5e01ed76551c729be9e5ee456caa999/check-runs` returns 12 runs, the six push-event matrix configurations among them (macos-latest release, windows-latest release, ubuntu-latest devel / release / oldrel-1 / 4.5.0) each `completed` / `success`, matching `.github/workflows/check-standard.yaml:38`'s push branch exactly. `git diff --name-only <SHA>..HEAD` lists eight paths; each is absent from the 197-entry `tar tzf` manifest of the AC1 tarball, which holds no `cairn/` or `data-raw/` entry at all, while `DESCRIPTION`, `NAMESPACE` and `R/icc.R` are present as passing controls.
- AC3 — verified. `cran-comments.md`'s *Test environments* section names two environments — the local `--as-cran` run and the six-configuration matrix, tabulated per configuration — each followed by its result for 0.1.0. `win-builder`, `R-hub`, "not yet run" and "Scheduled before" match 0 times in the file; the scheduled-but-unrun block is gone.
- AC4 — verified. `cairn/RELEASE-HANDOFF.md` lists seven numbered steps in execution order, each with its command: win-builder R-devel (`check_win_devel()`), win-builder R-release (`check_win_release()`), R-hub (`rhub_setup()`/`rhub_doctor()`/`rhub_check()`), `devtools::submit_cran()`, confirming the CRAN email, `usethis::use_github_release()`, `usethis::use_dev_version()`. ADR-022 reserves the win-builder/R-hub round-trips and `submit_cran()`; the remaining three come from the profile's release-walk handoff list.
- AC5 — verified. `urlchecker::url_check(".")` fetched 15 URLs and returned 0 rows: "All URLs are correct!".

### Consistency gate

- Universal: `cairn_validate.py` exits 0 — 16 PASS, 7 advisories OK, the `release window` advisory not fired. No `DESIGN.md` principle changed in this diff, so `cairn_impact.py` does not apply.
- Toolchain (`r-package` `consistency-gate` slot): `devtools::document()` leaves a clean tree; `NAMESPACE`, `man/` and `data/` are unchanged by the diff, so no generated-file drift; README.Rmd/README.md untouched and no `R/` source changed, so no knit drift; `pkgdown::check_pkgdown()` reports no problems; `NEWS.md` carries the `0.1.0` release section and this milestone adds no user-visible package behaviour; the one new top-level-adjacent file is `cairn/RELEASE-HANDOFF.md`, covered by the existing `^cairn$` `.Rbuildignore` entry, and `cran-comments.md` by `^cran-comments\.md$`; the full check is AC1's run above.

### Independent review

Declared surface tier is user-facing, so the full three-lens fan-out applies. Agent delegation is not authorized this session, so the three lenses ran in-session rather than in fresh-context subagents — the same departure M145, M146, M147 and this milestone's two criteria audits recorded.

- [S] prior-review lens: `gh api repos/jmgirard/intraclass/pulls/comments?per_page=1` returns 0, so the repo has no inline PR-thread surface. Archived `## Review` sections touching `cran-comments.md`: M48, M139, M140. One regression found (finding 1 below): M48's AC3 failed twice on "a hand-authored release-artifact fact no check the milestone runs can catch", and M139's review actioned a stale matrix description in this same file.
- [S] blame-history lens: zero findings. The removed *Checked so far* / *Scheduled before submission* structure is what AC3 requires gone; M140's run-header addition and M139's per-event matrix statement are both carried forward rather than undone; nothing a recorded D-entry settles is contradicted.
- [O] diff-bug lens: one finding, ranked below.

**Finding 1 (ranked first; the only finding).** `cran-comments.md`'s *Test environments* section says of the paths changed between the pinned SHA and the submitted source: "they are all under `cairn/` and `data-raw/`". Eight paths changed, and `cran-comments.md` itself is one of them; it is under neither directory. The sentence's conclusion still holds — that path is excluded from the tarball by its own `.Rbuildignore` entry, verified above — but the parenthetical justifying it is false, on the surface a CRAN reviewer reads. The milestone's own T6 work-log line already records `cran-comments.md` joining the seven; the prose was not updated with it. Same class as M48's twice-failing AC3 and M139's stale matrix description in this file.

Disposition: **fixed at the gate** (maintainer selection, 2026-08-29). The clause now reads "excluded from the built tarball by `.Rbuildignore` — seven under `cairn/` or `data-raw/`, plus this file, which has its own entry"; AC2's tarball-absence evidence above is unchanged by it.
