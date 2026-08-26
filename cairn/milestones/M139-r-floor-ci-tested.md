# M139: The declared R floor is a measured number CI runs (GP3)

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch:** `m139-r-floor-ci-tested`

## Goal

Replace the inferred `R (>= 4.0.0)` floor with the oldest R release that actually installs the Imports chain and passes `R CMD check`, and put a CI job on that exact version, closing GP3's recorded tension before submission.

## Scope

**Surface tier: user-facing** — the deliverable is `DESCRIPTION`'s declared floor, which decides who can install the package; the DESIGN.md and Known-issues edits are the record of that same change.

**In:** measuring the true floor across an enumerated candidate set; setting `DESCRIPTION`'s `Depends:` to the measured version; adding a CI job pinned to that numeric version; correcting GP3's parenthetical, which reads `release/oldrel-1/devel x macOS/Windows/Ubuntu` (`cairn/DESIGN.md:157-159`) where the matrix runs devel and oldrel-1 on Ubuntu only; retiring the Known-issues entry at `cairn/DESIGN.md:257-267` with a superseding D-entry.

**Out:** win-builder and R-hub runs — the maintainer's own pre-submission acts, listed as scheduled in `cran-comments.md:24-31`; M140 records their results. A standing checker over the CI matrix or the required-check set → stays a ROADMAP candidate row, refused at the plan gate under D-021.

## Acceptance criteria

- [ ] AC1. For each R version in the enumerated candidate set {4.0.0, 4.1.3, 4.2.3, 4.3.3, 4.4.3, 4.5.1}, a recorded run states whether the package's Imports chain installs and `R CMD check` passes, with the failing dependency named where it does not. The lowest passing version is the measured floor.
- [ ] AC2. `DESCRIPTION`'s `Depends: R (>= X)` names the AC1 measured floor as a literal three-part version, not a moving label.
- [ ] AC3. A CI job in `.github/workflows/check-standard.yaml` runs `R CMD check` at that same literal version and is green on this milestone's pull request, verified by reading `gh api repos/jmgirard/intraclass/commits/<head-sha>/check-runs` against the SHA from `gh pr view <n> --json headRefOid`.
- [ ] AC4. GP3's parenthetical in `cairn/DESIGN.md` states, for the `push` event and for the `pull_request` event separately, which R versions run on which OS, agreeing with `.github/workflows/check-standard.yaml:38`.
- [ ] AC5. The Known-issues entry at `cairn/DESIGN.md:257-267` is resolved or removed, and a `cairn/DECISIONS.md` entry supersedes the M48 review gate's recorded decision not to raise the floor, quoting its reason and saying what measurement changed it.
- [ ] AC6. `devtools::check()`'s raw `Status:` line reports 0 errors, 0 warnings, 0 notes, and `devtools::test()` at `NOT_CRAN=true CI=true` reports FAIL 0.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3, T6
- AC4 → T4
- AC5 → T4, T5
- AC6 → T6

## Tasks

- [ ] T1. Measure the floor: run `R CMD check` in a `rocker/r-ver:<v>` container for each candidate version, oldest first, recording the outcome and the blocking dependency per version. `Matrix` 1.7-5 declares `Depends: R (>= 4.4)` and glmmTMB is ABI-coupled to TMB/Matrix, so 4.0.0-4.3.3 are expected to fail on Matrix; record what actually happens rather than assuming it.
- [ ] T2. Set `DESCRIPTION`'s `Depends:` to the measured version; add a NEWS bullet stating the raise and its reason.
- [ ] T3. Add the pinned-version job to the matrix at `.github/workflows/check-standard.yaml:38`, on the `push` event at minimum.
- [ ] T4. Rewrite GP3's parenthetical per-event; resolve the Known-issues entry.
- [ ] T5. Append the superseding D-entry to `cairn/DECISIONS.md`; run `python3 /Users/jmgirard/github/cairn/scripts/cairn_impact.py --changed`, GP3 being edited, and record its output in the work log.
- [ ] T6. `air format .`, the four `data-raw/` checkers with `--self-test`, `devtools::check()`; open the PR and read the check-runs API against the pinned head SHA.

## Work log
- 2026-08-26: the maintainer declared the v0.1.0 release window open at the M138 review close, so M139 stays `planned` rather than parking as `blocked` under D-050.

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on all three drafted criteria. Fixed at the gate: the two-branch AC1 split into a measurement criterion and a separate DESCRIPTION criterion, its (a) branch having been unreachable (Matrix 1.7-5 needs R >= 4.4) and its (b) branch resting on the moving label `oldrel-1`; "matching check-standard.yaml line by line" given a referent by naming the event, the matrix being a single-line conditional ternary; the `cairn_impact.py` criterion moved to a task (instrument-bound, D-118) and its path corrected, `cairn/scripts/cairn_impact.py` not existing. One finding posed at the question gate (how to close GP3).
- 2026-08-26: plan gate chose measuring the true floor over raising it to oldrel-1's current number because `oldrel-1` is a moving label whose numeric value drifts out of truth at each R release, and over a 4.0.0 container job because a date-pinned snapshot would check archived dependency versions rather than the shipped Imports chain; falsified by the candidate sweep finding no version between 4.0.0 and oldrel-1 that installs, which would make the measurement and the raise the same act.
- 2026-08-26: `cairn_validate`'s release-window advisory fired on this file (the phrase "at the next R release" in its Scope). The release-shaped tripwire is answered, not deferred: the user declared the window in their own words at the plan gate — "can we do 1 and 2 before i submit to cran?" — so M138-M140 are the work queued ahead of a submission the maintainer performs out of band (ADR-022). No milestone here ships a version, so none is parked as `blocked`.
- 2026-08-26: plan gate declined a standing checker over the CI matrix and required-check set (M48's AC7 defect), keeping it a ROADMAP candidate under D-021; falsified by a user reaching a platform claim the vanished matrix cell made false.
- 2026-08-26: implement question gate — measure on GitHub CI (Docker's daemon is down locally and older `rocker/r-ver` tags lack arm64 builds); add 4.4.0 to the candidate set (AC1 amendment, pending the criteria audit); the pinned floor job runs on both `push` and `pull_request`, which AC3 requires. Local CRAN-metadata derivation over the 63-package recursive Imports closure puts the hard floor at R >= 4.4.0 (`MASS` 7.3-66, `Matrix` 1.7-6, `mgcv` 1.9-4); the sweep measures rather than assumes it.
- 2026-08-26: T1 in progress — temporary `.github/workflows/r-floor-sweep.yaml` runs the candidate set on a fixed `ubuntu-22.04` runner so the R version is the only varying axis; each job records setup-r, dependency-install, and `R CMD check` outcomes separately so an infrastructure failure is not recorded as a dependency failure.
