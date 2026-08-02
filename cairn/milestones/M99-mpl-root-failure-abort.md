<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M99: MPL interval — distinguish a true boundary limit from a root-finding failure

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP2   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m99-mpl-root-failure-abort · https://github.com/jmgirard/intraclass/pull/107   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Make `mpl_interval()` return a boundary endpoint only on evidence of no
deviance crossing, and raise a classed abort on a genuine root-finding
failure instead of silently reporting 0/1.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the sign-test rewrite of both `tryCatch(uniroot, error = <endpoint>)`
sites in `R/ci-mpl.R` (two-sided and one-sided paths); the classed
`intraclass_engine_error` abort (message names MPL root-finding, not an
engine); the mockable root-finding seam and its tests; the same decision
logic in the offline twin `data-raw/m86-mpl-lib.R` (plain `stop()` idiom);
the four shipped "interval exists on every dataset" claim surfaces + NEWS;
the narrowing D-entry and the DESIGN.md boundary-table mpl row.

**Out:** the saturated `p_lower0` diagnostic in the sweep fixtures →
unchanged (a re-sweep is not needed; the fix is unreachable for the seeded
sweeps' data, per the plan-gate audit); the κ_m monotone envelope/smoother →
its standing candidate row; any change to the MC default's boundary abort →
the classical fallback-on-abort candidate row; regenerating committed
calibration fixtures → not owed (behavior identical in every reachable
region).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `mpl_interval()` in `R/ci-mpl.R` decides boundary-vs-failure by an
      explicit sign test on each side (two-sided and one-sided paths alike):
      the boundary endpoint (0 lower / 1 upper) is returned only when the
      profile deviance at that side's outer bracket edge is finite and does
      not exceed the critical value (no crossing on that side); when a
      crossing is indicated (deviance at the outer edge exceeds the critical
      value, or is non-finite) and root-finding still fails, a classed
      `intraclass_engine_error` abort via `abort_intraclass()` — its message
      naming MPL root-finding, not an engine — is raised instead of an
      endpoint. No `tryCatch(stats::uniroot(...), error = function(e)
      <endpoint>)` pattern remains in `R/ci-mpl.R`.
- [ ] AC2: Tests exercise both branches against the interval machinery
      directly (not only through `icc()`): a real-data no-crossing input
      returns the boundary endpoint, and still returns it with root-finding
      mocked to fail (proving the short-circuit precedes the seam); the abort
      paths are exercised three ways — the mocked seam on the lower side, the
      mocked seam on the upper side, and a real degenerate-fit input (perfect
      rater agreement) that reaches an abort without any mock — each
      asserting the classed error, with at least one assertion pinning the
      MPL-specific message text.
- [x] AC3: Behavior in the legitimate-boundary case is unchanged: every
      existing MPL test (including the pinned κ_m constants and the
      near-zero-ρ boundary cell in `test-ci-mpl.R`) passes with no assertion
      changed, and review evidence records endpoint identity on a seeded
      near-zero-ρ boundary dataset between the pre-change and post-change
      code.
- [x] AC4: The four shipped claim surfaces stating the MPL interval exists on
      every dataset are updated to the narrowed contract — the `R/ci-mpl.R`
      interval comment (lines 159–161), the roxygen sentence "returns an
      interval on every dataset" in `R/icc.R` (with `man/` regenerated), the
      `test-ci-mpl.R:163` comment, and a NEWS entry — with the reworded
      roxygen sentence re-triaged in `data-raw/mpl-doc-claims.tsv` (stale row
      removed, replacement row added for any new trigger-bearing sentence);
      `python3 data-raw/check-mpl-doc-claims.py` passes locally, and the
      other two data-raw checkers (`enumerate-generalizing-claims.py
      --check`, `check-reference-observations.py`) are also run locally and
      pass.
- [x] AC5: `data-raw/m86-mpl-lib.R`'s `mpl_interval()` carries the same
      sign-test decision logic on both sides and both `side=` modes, with
      plain `stop()` as its failure idiom (the classed-abort layer governs
      package code only), keeping the reference implementation and the
      shipped code in decision-logic lockstep.
- [x] AC6: The contract narrowing is recorded before merge: a new
      `DECISIONS.md` entry states that a genuine root-finding failure in the
      MPL interval now aborts classed (`intraclass_engine_error`) while the
      boundary clamp — the case D-014 actually measured — is unchanged, and
      an mpl row is added to DESIGN.md's interval-time boundary table.
      Neither D-014 nor D-015 is edited.
- [x] AC7: The active profile's verify slot is clean: `devtools::document()`
      no delta, `air format --check`, `lintr::lint_package()`, and the full
      suite green against the installed package with `NOT_CRAN=true CI=true`
      (failed + error sum = 0).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2
- AC2 → T1
- AC3 → T1, T6
- AC4 → T4
- AC5 → T3
- AC6 → T5
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Tests first in `test-ci-mpl.R`: (a) a seeded near-zero-ρ two-way
      dataset whose lower side has no crossing returns lower = 0 via the sign
      test (direct `mpl_interval()` call, M84 lesson); (b) the failure branch
      via `local_mocked_bindings()` on the new root-finding wrapper, asserting
      `intraclass_engine_error`; both red against current code where they
      should be.
- [x] T2: Rewrite `R/ci-mpl.R:178-189`: extract the per-side `uniroot` call
      into a package-internal wrapper (the mockable seam), evaluate the sign
      condition explicitly, return the boundary only on no-crossing, abort
      classed otherwise.
- [x] T3: Mirror the sign-test decision logic in
      `data-raw/m86-mpl-lib.R:131-158` (both sides, both `side=` modes,
      `stop()` idiom).
- [x] T4: Update the four claim surfaces + NEWS; regenerate `man/`; re-triage
      `data-raw/mpl-doc-claims.tsv`; run all three data-raw checkers locally
      (M85/M97 lessons).
- [x] T5: Author the narrowing D-entry and the DESIGN.md boundary-table mpl
      row (durable-record preview before the commit that lands them).
- [x] T6: Full local verify per the r-package profile (document/air/lintr +
      installed-package suite at `NOT_CRAN=true CI=true`), and record
      pre-vs-post endpoint identity on the seeded boundary dataset (run the
      snippet on the default branch and on the milestone branch).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-01: created by /milestone-plan (promotes the MPL boundary-vs-failure candidate; declined for M96 at the 2026-07-25 plan gate as shipped-behavior change; lineage M86 lib → M88 port → M95/M96 plan gate).
- 2026-08-01: criteria audit ([O], fresh context) returned 6 findings: AC2 mock-seam ambiguity, AC4 missing tsv re-triage + line-wrapped claim surface + two untriggered checkers, AC5 idiom ambiguity (all fixed in wording), AC3/AC1 joint-satisfiability confirmed clean, and a cross-cutting CONFLICTS (silent narrowing of the D-014/D-015 exists-on-every-dataset contract) → became the gate's failure-mode question and AC6; re-audit of the changed wording returned all-SATISFIABLE with two nits (AC3 "no assertion changed", abort message not "engine"), both applied.
- 2026-08-01: plan gate chose classed abort over warning+boundary-value because a wrong endpoint would still reach downstream code (#5 fail-loudly); falsified by evidence a classed abort breaks a legitimate downstream workflow a warning would serve.
- 2026-08-01: plan gate chose reusing `intraclass_engine_error` over a new dedicated class because the branch is unreachable with real data and a new class grows exported vocabulary for it; falsified by a user need to discriminate root-finding failure from engine failure in `tryCatch()`.
- 2026-08-01: plan gate chose fixing the offline twin in lockstep over shipped-only because the twin is the IP1 reference implementation and committed fixtures are unaffected (failure region unreachable for the seeded sweeps); falsified by a calibration re-run whose accounting shows the twin aborting where the shipped code does not.

- 2026-08-01: T1 done — two M99 tests appended to test-ci-mpl.R; mocked-seam abort test red as intended (no mpl_uniroot binding yet), no-crossing boundary test green (value-identical to the swallow until T2 removes the pattern); suite otherwise 181 pass.
- 2026-08-01: checkpoint (T2–T5 code + records drafted, verification pending) — sign-test rewrite in R/ci-mpl.R with mpl_uniroot seam + classed abort; twin mirrored (stop() idiom); 4 claim surfaces + NEWS + man/ + tsv re-triage done, all three data-raw checkers green; D-019 appended + DESIGN.md interval-time MPL row added (previewed in chat); MPL test file green (183); full suite + lintr running in background — tasks stay unticked until the verify slot is green.
- 2026-08-01: T2-T6 done, verify green — installed-pkg suite NOT_CRAN=true CI=true: failed 0 / error 0 / passed 5433 / skipped 23; lintr 0; air --check clean; document() no delta; endpoint identity pre-vs-post bit-exact on 3 geometries (boundary-lo clamp, interior, high-rho), both interval paths (evidence for review). Status -> review.
- 2026-08-01: review return #1 — [O] diff-bug lens falsified the sign test's premise (f(rho_hat) < 0 fails on degenerate fits: perfect-agreement 20x3 reaches the abort via icc(), where main returned a vacuous [0,1]); actioned >=80: F1 95, F2 95, F3 90, F8 82, F11 88, F12 90, F13 80; 12 sub-80 logged in Review. Status back to in-progress for the fix cluster + gated AC2 amendment.
- 2026-08-01: gated amendment (review return #1, user-approved): AC2 reworded — falsified "unreachable with real non-degenerate data" clause replaced by the three-way abort-path test obligation (mocked lower, mocked upper, real degenerate-fit input) + message-text pin; AC2 unticked pending fresh evidence. Gate also chose: degenerate fit aborts with a fit-degeneracy diagnosis (over preserving the vacuous [0,1]), and the abort names no alternative method (D-018 run-before-naming; over wiring hint machinery).
- 2026-08-01: review fix cluster landed — degenerate-fit sanity guard (f(rho_hat) check) with fit-naming message, no method named in either abort (D-018); side-aware upper mock + message regexps + real-data degenerate test + short-circuit mock proof (amended AC2); NEWS/roxygen/boundary-hint (5th surface) reworded; D-019 draft corrected (reachability, fixture evidence, sweep hard-stop consequence); tsv re-keyed 2cde0f315ee3; mpl file 185 green, targeted lintr 0, checkers OK.

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->

Evidence gathered 2026-08-01 on branch m99-mpl-root-failure-abort (PR #107), by command.

- AC1: `grep -n "error = function(e)" R/ci-mpl.R` → one hit, the classed abort handler (line 204); no endpoint-returning handler remains; sign test present (`f_outer <= 0`, both sides via `side_root`); abort message names "modified-profile-likelihood … root-finding", class `intraclass_engine_error`. ✔
- AC2: fresh `test_file("tests/testthat/test-ci-mpl.R")` → failed 0 / error 0 / passed 183, including the two M99 tests (real-data no-crossing boundary on both paths; mocked `mpl_uniroot` seam aborting classed on both paths). ✔
- AC3: diff of test-ci-mpl.R vs main removes comment lines only (0 non-comment deletions — assertions untouched); endpoint identity pre-vs-post: bit-exact (`identical()` TRUE) on 3 geometries (near-zero-ρ clamp, interior, high-ρ), two-sided and one-sided, old code sourced from `main:R/ci-mpl.R`. ✔
- AC4: all four surfaces updated (R/ci-mpl.R comment, R/icc.R roxygen + man/icc.Rd regenerated, test-ci-mpl.R:163 comment, NEWS bullet); tsv row eb69ce6b0e01 replaced by 76d9b57e857a; fresh runs: check-mpl-doc-claims.py OK (30 candidates, 0 failures), enumerate-generalizing-claims.py --check OK, check-reference-observations.py 0 unmarked / 0 falsified. ✔
- AC5: twin carries `side_root`/sign test (m86-mpl-lib.R:151-176), `stop()` idiom, both sides and both `side=` modes; smoke-run: interior interval sane, boundary lower = 0. ✔
- AC6: D-019 appended (DECISIONS.md:634); DESIGN.md interval-time table gains the MPL row citing D-019; `git diff main..HEAD -- cairn/DECISIONS.md` shows 0 removed lines (pure append — D-014/D-015 unedited). ✔
- AC7: `devtools::document()` no delta (git status clean after run); `air format --check` exit 0; `lintr::lint_package()` → 0 lints; installed-package suite (`R CMD INSTALL` + `test_local(load_package="installed")` at `NOT_CRAN=true CI=true`) → failed 0 / error 0 / passed 5433 / skipped 23. ✔

Consistency gate: `cairn_validate` exit 0 (all checks PASS; pre-existing `dangling id tokens` WARN is advisory, legacy COVERAGE.md ids); no IP/GP changed → `cairn_impact` skipped; `pkgdown::check_pkgdown()` no problems; NEWS entry present, no milestone numbers user-facing; no new top-level files; README.Rmd untouched by the diff; `devtools::check()` and independent review recorded below.

Driving RR: — (no numeric projections to juxtapose).
