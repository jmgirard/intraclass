# M139: The declared R floor is a measured number CI runs (GP3)

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Branch:** `m139-r-floor-ci-tested`
- **PR:** https://github.com/jmgirard/intraclass/pull/150

## Goal

Replace the inferred `R (>= 4.0.0)` floor with the oldest R release that actually installs the Imports chain and passes `R CMD check`, and put a CI job on that exact version, closing GP3's recorded tension before submission.

## Scope

**Surface tier: user-facing** — the deliverable is `DESCRIPTION`'s declared floor, which decides who can install the package; the DESIGN.md and Known-issues edits are the record of that same change.

**In:** measuring the true floor across an enumerated candidate set; setting `DESCRIPTION`'s `Depends:` to the measured version; adding a CI job pinned to that numeric version; correcting GP3's parenthetical, which reads `release/oldrel-1/devel x macOS/Windows/Ubuntu` (`cairn/DESIGN.md:157-159`) where the matrix runs devel and oldrel-1 on Ubuntu only; retiring the Known-issues entry at `cairn/DESIGN.md:257-267` with a superseding D-entry.

**Out:** win-builder and R-hub runs — the maintainer's own pre-submission acts, listed as scheduled in `cran-comments.md:24-31`; M140 records their results. A standing checker over the CI matrix or the required-check set → stays a ROADMAP candidate row, refused at the plan gate under D-021.

## Acceptance criteria

- [ ] AC1. `DESCRIPTION`'s declared floor is the measured floor: the lowest member of the candidate set {4.0.0, 4.1.3, 4.2.3, 4.3.3, 4.4.0, 4.4.3, 4.5.1} at which the package's `Depends`/`Imports`/`LinkingTo` chain installs and `R CMD check` passes on CI, with every member above it also passing. Two outcomes are recorded but never raise the floor: an R version the runner cannot provision, and a failure confined to the wider dependency set `R CMD check` needs (Suggests included). Where the lowest passing and the highest failing member are not adjacent in the r-project release list, the gap is bisected until they are. Evidence: the per-version outcome quad from the `r-floor-sweep.yaml` run, cited by run id and transcribed into the work log.
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
- AC5 → T4, T5, T7
- AC6 → T6

## Tasks

- [x] T1. Measure the floor with the temporary `.github/workflows/r-floor-sweep.yaml`, which runs the candidate set on one fixed `ubuntu-22.04` runner and records four outcomes per version (`setup-r`, Imports-chain install, check-dependency install, `R CMD check`) so a provisioning failure and a Suggests-only failure are each distinguishable from a package floor. Transcribe the quad table into the work log; delete the workflow at T6.
- [x] T2. Set `DESCRIPTION`'s `Depends:` to the measured version; add a NEWS bullet stating the raise and its reason.
- [x] T3. Add the pinned-version job to the matrix at `.github/workflows/check-standard.yaml:38`, on the `push` event at minimum.
- [x] T4. Rewrite GP3's parenthetical per-event; resolve the Known-issues entry.
- [x] T5. Append the superseding D-entry to `cairn/DECISIONS.md`; run `python3 /Users/jmgirard/github/cairn/scripts/cairn_impact.py --changed`, GP3 being edited, and record its output in the work log.
- [ ] T6. `air format .`, the four `data-raw/` checkers with `--self-test`, `devtools::check()`; open the PR and read the check-runs API against the pinned head SHA.
- [x] T7. Register the measured floor in `data-raw/record-claims.tsv` as a `cited` row whose command reads the literal out of `DESCRIPTION`, and carry its `[claim:<id>]` marker on the `cairn/DESIGN.md` figure; delete `.github/workflows/r-floor-sweep.yaml`.

## Work log
- 2026-08-26: the maintainer declared the v0.1.0 release window open at the M138 review close, so M139 stays `planned` rather than parking as `blocked` under D-050.

- 2026-08-26: created by /milestone-plan.
- 2026-08-26: plan-gate criteria audit ran in FULL mode (user-facing tier); a fresh-context [O] reader that authored none of the criteria returned findings on all three drafted criteria. Fixed at the gate: the two-branch AC1 split into a measurement criterion and a separate DESCRIPTION criterion, its (a) branch having been unreachable (Matrix 1.7-5 needs R >= 4.4) and its (b) branch resting on the moving label `oldrel-1`; "matching check-standard.yaml line by line" given a referent by naming the event, the matrix being a single-line conditional ternary; the `cairn_impact.py` criterion moved to a task (instrument-bound, D-118) and its path corrected, `cairn/scripts/cairn_impact.py` not existing. One finding posed at the question gate (how to close GP3).
- 2026-08-26: plan gate chose measuring the true floor over raising it to oldrel-1's current number because `oldrel-1` is a moving label whose numeric value drifts out of truth at each R release, and over a 4.0.0 container job because a date-pinned snapshot would check archived dependency versions rather than the shipped Imports chain; falsified by the candidate sweep finding no version between 4.0.0 and oldrel-1 that installs, which would make the measurement and the raise the same act.
- 2026-08-26: `cairn_validate`'s release-window advisory fired on this file (the phrase "at the next R release" in its Scope). The release-shaped tripwire is answered, not deferred: the user declared the window in their own words at the plan gate — "can we do 1 and 2 before i submit to cran?" — so M138-M140 are the work queued ahead of a submission the maintainer performs out of band (ADR-022). No milestone here ships a version, so none is parked as `blocked`.
- 2026-08-26: plan gate declined a standing checker over the CI matrix and required-check set (M48's AC7 defect), keeping it a ROADMAP candidate under D-021; falsified by a user reaching a platform claim the vanished matrix cell made false.
- 2026-08-26: implement question gate — measure on GitHub CI (Docker's daemon is down locally and older `rocker/r-ver` tags lack arm64 builds); add 4.4.0 to the candidate set (AC1 amendment, pending the criteria audit); the pinned floor job runs on both `push` and `pull_request`, which AC3 requires. Local CRAN-metadata derivation over the 63-package recursive Imports closure puts the hard floor at R >= 4.4.0 (`MASS` 7.3-66, `Matrix` 1.7-6, `mgcv` 1.9-4); the sweep measures rather than assumes it.
- 2026-08-26: T1 in progress — temporary `.github/workflows/r-floor-sweep.yaml` runs the candidate set on a fixed `ubuntu-22.04` runner so the R version is the only varying axis; each job records setup-r, dependency-install, and `R CMD check` outcomes separately so an infrastructure failure is not recorded as a dependency failure.
- 2026-08-26: sweep run 1 (id 33003639356) is void as floor evidence — `setup-r-dependencies` defaults to installing every dependency including Suggests, so its install step measured the check-dependency set, not the Imports chain, and it failed on 4.0.0-4.4.3 while succeeding on 4.5.1. Every step carrying `continue-on-error` also makes each job conclude green regardless, so the job conclusion carries no information; the recorded outcomes are the evidence. Instrument rebuilt to install the Imports chain (`dependencies: '"hard"'`) separately from the check-dependency set and to record four outcomes per version.
- 2026-08-26: AC1 amendment audit — a fresh-context [O] reader that authored none of the wording ran the full audit (user-facing tier) twice: once on the plain `4.4.0` insertion, once on the deliverable-bound rewrite the mini gate chose. Round 1 returned seven findings, round 2 eight. Fixed without a gate: the failure clause presuming an install failure; the missing re-derivable artifact; the unchecked monotonicity assumption; the untested 4.4.1/4.4.2 gap. Round 2's remaining findings go to the user, this criterion having already had its one post-gate reader pass.
- 2026-08-26: AC1 amended (substantive, mini gate 2026-08-26). The criterion now binds `DESCRIPTION`'s declared floor rather than the existence of a record; 4.4.0 joins the candidate set; a provisioning failure and a Suggests-only failure are named as outcomes that never raise the floor; adjacency is anchored to the r-project release list; the evidence quad is transcribed into the work log because the sweep workflow is deleted at T6 and Actions logs expire. T1 restated to the rebuilt instrument; T7 added for the claim-ledger row; AC5 coverage extended to T7.
- 2026-08-26: blocked. `test-doc-skew-caveat.R:2494`'s anti-vacuity floor (`expect_gt(length(hits), 0L)`, the dependency-list-attributed-to-Imports test) fails under `R CMD check` on R 4.4.x and 4.5.1 and passes on 4.6.1 and 4.7.0; it is red on the default branch (`check-standard.yaml` run 33002388932, `ubuntu-latest (oldrel-1)`, commit 0a99f9ed) and reproduced at 4.5.1 in sweep run 33003639356. AC3 and AC6 cannot be met until it is fixed. Gate chose the hotfix route over folding the repair into this milestone.
- 2026-08-26: resumed. The blocker is cleared — the `test-doc-skew-caveat.R` anti-vacuity floor was repaired on the default branch (PR #149) and merged into this branch; status back to `in-progress`.
- 2026-08-26: sweep run 33007089056 (rebuilt instrument, commit 2e8e5e9) recorded the quad for all seven candidates: `setup-r` succeeded on every version, so no candidate is a provisioning failure. Imports-chain install failed on 4.0.0, 4.1.3, 4.2.3, 4.3.3, 4.4.0 and 4.4.3 and succeeded on 4.5.1; at 4.4.3 the named failure is `Deriv` (a transitive dependency of `glmmTMB`), whose current source uses `R_ClosureFormals` — `derive_simplif.cpp:376:28: error: 'R_ClosureFormals' was not declared in this scope`. That run's `R CMD check` at 4.5.1 failed on the anti-vacuity floor since repaired, so the check leg is re-measured after the merge. 4.4.3 and 4.5.1 are not adjacent in the r-project release list, so AC1's bisection clause adds 4.5.0 to the matrix.
- 2026-08-26: T1 done. Sweep run 33016177595 (eight versions, commit a94e5ef, after the default-branch merge) — `setup-r` / imports-install / check-deps-install / `R CMD check`: 4.0.0 success/failure/skipped/skipped (`pbkrtest: Needs R >= 4.2.0`, via `glmmTMB`); 4.1.3 same; 4.2.3 success/failure/skipped/skipped (`Failed to build Deriv 4.3.0`); 4.3.3 same; 4.4.0 same; 4.4.3 same, the compiler line being `derive_simplif.cpp:376:28: error: 'R_ClosureFormals' was not declared in this scope`; 4.5.0 success/success/success/success; 4.5.1 success/success/success/success. `setup-r` succeeded on all eight, so no cell is a provisioning failure and no failure is confined to the check-dependency set. The measured floor is 4.5.0, adjacent to the highest failing member 4.4.3 in the r-project release list. `Deriv` reaches the chain as `glmmTMB` -> `pbkrtest` -> `doBy` -> `Deriv`.
- 2026-08-26: implement question gate — the maintainer chose to declare the measured 4.5.0, the sweep having put the floor five minor releases above the 4.4.0 the plan's local metadata derivation predicted. Alternatives offered and declined: recording the lowering condition in the decision entry (written in anyway, since it costs nothing that ships), and returning the milestone to planning on the ground that a transitive dependency setting the floor may mean the goal was cut wrong.
- 2026-08-26: T2-T5, T7 done. `DESCRIPTION` declares `R (>= 4.5.0)`; NEWS gains a Requirements section; the 4.5.0 job joins `check-standard.yaml` on both events, the matrix staying on line 38 so AC4's locator still resolves; GP3's parenthetical is rewritten per event; the stale five-config Platforms bullet (`DESIGN.md:53-58`) and `cran-comments.md`'s 4.0.0 floor note are corrected in place, both having been made false by this milestone's own edit; D-039 appended. `cairn_impact.py --changed` reported GP3 with 13 references, none stale. The `r-floor-declared` ledger row was proved able to fail: planting `R (>= 4.4.0)` in `DESCRIPTION` reds it with `match-mismatch`, and the row is green on the real literal.
- 2026-08-26: T7's deletion of `.github/workflows/r-floor-sweep.yaml` moved ahead of T6 (minor amendment) so the final `devtools::check()` runs on the tree that ships.
- 2026-08-26: the cairn merge guard denies `git merge <anything>` naming the default branch whatever the direction, so merging `origin/main` into this branch needed the branch checked out in its own prior Bash call; the guard reads the branch before the command runs.
