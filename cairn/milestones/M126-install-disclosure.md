<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M126: Disclose what an installation actually retrieves

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP8   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m126-install-disclosure` / https://github.com/jmgirard/intraclass/pull/135   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Restore, across the three shipped surfaces that discuss dependencies, the
disclosure that `lme4` arrives with any installation while `merDeriv` does not.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing** — every edited surface ships (`README.md` is in the
tarball and is the pkgdown home page; `NEWS.md` and the vignettes install).

**In:** the Installation section of `README.Rmd` and its regenerated `README.md`;
`NEWS.md`'s "so the base install stays light" clause (:502, inside the unreleased
`# intraclass 0.1.0` section) plus a development-version bullet recording the
README change; the mixed-model passage of `vignettes/engines.Rmd` (:30–58).
Extending `claim_patterns` in `tests/testthat/test-doc-skew-caveat.R` with the
spellings this milestone withdraws — the extension form D-029 requires, not a
second instrument.

**Out:** any NEW doc-claim checker, ledger or audit → barred by D-021, which
D-029 confirms this scope does not otherwise meet; per-class reachability probes
for the pin → the standing `Per-class reachability proof` candidate row, still
barred. `\value`/example nits on `man/*.Rd` → M48. Explicit `design=` and
numeric-`unit` demonstrations → their own candidate row.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [ ] AC1: `README.Rmd`'s Installation section discloses that `lme4` arrives with an
      installation regardless of its `Suggests` placement, attributing that to
      `glmmTMB`'s own `Imports:` rather than asserting it as a bare fact about the
      install. Evidence: the section quoted verbatim in the work log.
- [ ] AC2: The same section discloses that `merDeriv` — which the lme4 engine requires
      (`fit_lme4()`'s entry `rlang::check_installed("merDeriv")`, documented at
      `R/icc.R:310`) — does not arrive, attributed to its `Suggests` placement in this
      package's `DESCRIPTION`. Evidence: the quoted section, plus T1's three
      measurements work-logged — `tools::package_dependencies()` over the non-base
      entries of the `Imports:` field read from `DESCRIPTION`, recursive, `which =
      c("Depends","Imports","LinkingTo")`; `pak::pkg_deps("jmgirard/intraclass")` at its
      default; and `packageDescription("glmmTMB")$Imports` — the first two showing
      `lme4` present and `merDeriv` absent, the third naming `lme4`, each stamped with
      the R version and the date.
- [ ] AC3: None of the four edited files states a count of retrieved packages, and the
      README's declared-set sentence states its members without a numeral (rationale:
      the Decisions entry below; the pin rule at T2). Evidence: a numeral sweep over the
      four edited files, its hits quoted and adjudicated in the work log.
- [ ] AC4: `README.md` is regenerated from `README.Rmd` in the same commit and carries
      the same disclosure; a second render leaves `git status` clean. Evidence: the
      rendered section quoted beside `README.Rmd`'s, and the `git status` output.
- [ ] AC5: `claim_patterns` in `tests/testthat/test-doc-skew-caveat.R` gains five
      spellings for the three clauses this milestone withdraws: `README.Rmd`'s "so
      intraclass does not require them" and `NEWS.md`'s "so the base install stays
      light", each anchored through the adjacent `Suggests` token in a backticked and a
      backtick-free form; and `vignettes/engines.Rmd`'s "it is the one required
      dependency" in one form. Each of the five is mutation-verified RED against a green
      control across the source leg's 2 markup regimes × 4 wrap forms and the installed
      leg's `README.md`, `NEWS.md` and one installed vignette, by
      `data-raw/m123-capability-claim-mutations.R`. Evidence: the harness run.
- [ ] AC6: `NEWS.md:502`'s clause no longer characterizes the install's footprint from
      the `Suggests` placement alone, and a development-version bullet records the
      README change, the unreleased `0.1.0` section being corrected in place with no
      bullet of its own (rationale: the work log). Evidence: both passages quoted before
      and after.
- [ ] AC7: `vignettes/engines.Rmd`'s mixed-model section discloses that `lme4` arrives
      with `glmmTMB` and that `merDeriv` is the dependency an installation may lack, and
      its "it is the one required dependency" clause (`:53`) no longer reads as a claim
      about what an installation retrieves. Evidence: the section quoted before and
      after; the vignette knits.
- [x] AC8: The milestone's Decisions section records why membership claims (`lme4`
      arrives, `merDeriv` does not) are shippable on a user-facing surface where a
      cardinality claim is not. Evidence: the entry.
- [ ] AC9: `cairn/PROFILE.md`'s verify slot is clean, and the full suite is green
      against the **installed** package via `testthat::test_dir(load_package =
      "installed")` with **0 skips** across that run (`doc-claim-pins.md`, M116).
      Evidence: both outputs.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T5
- AC2 → T1, T2
- AC3 → T2, T3, T4, T5, T13
- AC4 → T5
- AC5 → T6
- AC6 → T3
- AC7 → T4
- AC8 → T8
- AC9 → T7

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Measure — `tools::package_dependencies()` over the `Imports:` field read from
      `DESCRIPTION`, `pak::pkg_deps("jmgirard/intraclass")`, and
      `packageDescription("glmmTMB")$Imports`, `repos` set explicitly (a bare `Rscript`
      with no mirror errors). Record `lme4` present / `merDeriv` absent, the R version
      and the date in the work log.
- [x] T2: Rewrite `README.Rmd`'s Installation paragraph. No count of retrieved packages
      and no numeral on the declared set; the paragraph MUST retain a sentence naming
      exactly `cli`, `generics`, `glmmTMB`, `lifecycle`, `rlang`, `tibble` and carrying
      `Imports` or `non-base` — its only supplier for the `expect_gt(length(hits), 0L)`
      anti-vacuity floor in `test-doc-skew-caveat.R`'s "a dependency list on any swept
      surface is attributed to Imports" rule, across `NEWS.md`, both READMEs and all nine
      vignettes; check the draft against `claim_patterns` on whitespace-collapsed,
      blockquote-stripped text, never a raw grep (`doc-claim-pins.md`).
- [x] T3: Rewrite `NEWS.md:501–502`'s clause in place; write the
      development-version bullet.
- [x] T4: Rewrite the `vignettes/engines.Rmd` mixed-model passage, including the `:53`
      clause; leave the `:39` chunk gate correct for `merDeriv`.
- [x] T5: `devtools::build_readme()`; verify a second render is a no-op.
- [x] T6: Append the three withdrawn spellings to `claim_patterns` (backticked + bare
      per claim) and commit the mutation matrix — each spelling reintroduced across 2
      markup regimes × 4 wrap forms, red required, then removed.
- [x] T7: `devtools::spell_check()` (any new word → `inst/WORDLIST`); knit the
      vignettes; profile verify; `test_dir(load_package = "installed")` at 0 skips.
- [x] T8: Record the membership-vs-cardinality asymmetry in the Decisions section.
- [x] T9 (return 1): Correct the engine-availability claim on all three surfaces (F1,
      F2), with the NEWS defects riding the same bullets (F6, F8, F9); regenerate
      `README.md`.
- [x] T10 (return 1): Re-anchor `install_not_required_*`, `install_light_*` and
      `install_one_required_dep` to the contiguous clause each shipped in (F3, F4, F5),
      correct the entry-index comment (F10), update the harness plants, re-run the matrix.
- [x] T11 (return 1): Amend AC2 and AC3 at the mini gate (F7 and the carried AC2
      finding); correct T2's stale line citation.
- [x] T12 (return 1): Re-run the T7 gate against the corrected prose.
- [x] T13 (return 2): Repair the deliverable and pin defects the return names (F2-F8) —
      the vignette's `:53` clause and its merDeriv covariance scope, NEWS's engine/helper
      misclassification and its short line, and the pin file's `install_light_*`
      over-match, hand-counted index and claim/spelling parenthetical; update the harness
      plants, re-run the mutation matrix, re-run the AC3 numeral sweep.
- [ ] T14 (return 2): Compress the Acceptance criteria under the cap at a mini gate (G1),
      record the lme4 abort-message framing as a candidate row (F10), re-run the T12 gate.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-08-17: created by /milestone-plan; promotes the standing `README no longer discloses that lme4 arrives` candidate row (lineage: M123 review attempt 3 F24 → descope gate 2026-08-17), scope widened at the gate to NEWS.md:502 and vignettes/engines.Rmd.
- 2026-08-17: criteria audit ran in FULL mode (user-facing tier), two passes, fresh-context [O] reader both times. Pass 1 returned 8 findings: AC5 self-scoping ("the legs its own walk reaches" cannot fail; source leg early-returns list() at test-doc-skew-caveat.R:395 under .Rcheck/covr), AC5 evidence not producible (the pin prints no counts on a pass), AC5 inferring a deliverable property from an instrument one, AC1's attribution half having no procedure, AC6 sequenced after the only run citing it, AC6 binding instrument properties (D-118), AC2's pak modeling unverified, and the unnamed :2334 constraint. Pass 2 on the revised draft returned 7 more: AC3 hand-pinning "63 vs 60" in the very criterion banning hand-pinned counts (GP8), AC3's domain three passages against four edited files, AC5 near-vacuous (24 of 28 claim_patterns entries unreachable by any M126 rewrite) and pinning none of the spellings this milestone withdraws, AC5's raw-file grep reproducing the blockquote false negative doc-claim-pins.md exists to defeat, T6's zero-skip scoped to two blocks where M116 doctrine scopes it to the whole installed run, AC7 citing :56 for a clause at :53, and T8 mapping to no criterion. All disposed here: AC5 replaced with the pin-extension + mutation-matrix criterion, AC3 de-numeralized and widened to four files, AC8 added for T8, AC9 widened to the whole installed run, AC7's line corrected, T2 given the :2401 anti-vacuity constraint explicitly.
- 2026-08-17: plan gate chose extending `claim_patterns` in the existing test over authoring a second doc-claim instrument, because D-029 (2026-08-09) settles that a user-facing doc correction plans normally while apparatus still needs D-021's trigger, and names extension as the form M116 used; falsified by a measurement showing the extension cannot pin one of the three withdrawn spellings without a new instrument.
- 2026-08-17: plan gate chose a qualitative footprint clause over naming a figure, because `tools::package_dependencies()` and `pak::pkg_deps()` disagree on this package today (63 vs 60) and nothing in the repo re-derives either; falsified by a procedure landing in the repo that re-derives a closure count on every run.
- 2026-08-17: `cairn_validate` sizing advisory (9 acceptance criteria > 7) accepted, not split. The only natural cut line is AC5 — the `claim_patterns` extension and its mutation matrix — and a milestone whose sole deliverable is a doc-claim pin is apparatus D-021 bars outright, which D-029 confirms by requiring the extension to ride along in the milestone that withdraws the spellings. The remaining criteria are one per shipped surface plus the record and the gate, none of which stands alone. Merging the audited criteria to clear an advisory was refused as shrink-to-fit.
- 2026-08-17: plan gate chose correcting `NEWS.md`'s 0.1.0 clause in place with no bullet of its own, over a correction bullet for it, because 0.1.0 is unreleased (DESCRIPTION 0.0.0.9000, M48 blocked, no tags) so no user ever read it; falsified by 0.1.0 shipping before this milestone lands.
- 2026-08-17: T1 measured on R 4.6.1 against the CRAN cloud mirror — `tools::package_dependencies()` over the six non-base `Imports:` read from `DESCRIPTION` gives a 63-package recursive closure with `lme4` present and `merDeriv` absent; `pak::pkg_deps("jmgirard/intraclass")` at its default gives 60 with the same two verdicts, and `brms`/`lavaan` absent too; `packageDescription("glmmTMB")$Imports` names `lme4 (>= 1.1-18.9000)`. The two procedures disagree on size, agree on membership — the AC3 rationale, measured rather than assumed.
- 2026-08-17: T2 rewrote README.Rmd's Installation paragraph — the declared set now states its members with no numeral, `glmmTMB`'s own `Imports:` carries the lme4 disclosure, and `merDeriv` is named beside the `Suggests:` engines as the piece the lme4 interval needs. Checked against all 28 `claim_patterns` spellings parsed from the test file and matched on squashed, blockquote-stripped text: 0 hits. `test-doc-skew-caveat.R` green under `load_all` (2 vignette-install skips, covered at T7); the `:2334` dependency-list rule and its `:2401` anti-vacuity floor both pass on the new sentence.
- 2026-08-17: T3 replaced the unreleased 0.1.0 section's "so the base install stays light" clause in place — it now names `brms`/`lavaan`/`merDeriv` as request-only and `lme4` as arriving via `glmmTMB` — and added a Documentation bullet to the development-version section recording the README change, beside M123's own README bullet. No bullet for the 0.1.0 clause: that section has never shipped. 0 `claim_patterns` hits across the four files.
- 2026-08-17: T4 rewrote the engines vignette's mixed-model opening to say lme4 arrives with glmmTMB and merDeriv is the piece that may be absent, and replaced the `:53` "it is the one required dependency" clause — true of the DESCRIPTION, misleading about the install — with what it actually meant: glmmTMB is the declared engine and needs nothing an installation does not already bring. The `:39` chunk gate is left as-is; it is correct for merDeriv. 0 `claim_patterns` hits across the four files.
- 2026-08-17: T5 regenerated README.md via `devtools::build_readme()`; the diff is 11 insertions / 6 deletions confined to the Installation paragraph, with no drift in any printed `icc()` output. A second render left `git diff README.md` empty — the no-op AC4 asks for.
- 2026-08-17: AC5 amended at a mini gate (substantive; user-facing tier, so the amended wording went to a fresh-context [O] reader first, which returned 10 findings and judged the first draft a net widening). The planned "each in a backticked and a backtick-free form" is unsatisfiable for `vignettes/engines.Rmd`'s clause, which carries no markup — the two forms would be byte-identical. Amended to name the forms concretely per clause and to state the installed leg's probe domain as what the harness plants (README.md, NEWS.md, one vignette) rather than more. A conditional "where its clause carries markup" draft was rejected as self-scoping, and a clause binding the harness's internal name check was dropped under D-118. User selected the narrowed wording over widening the probe to all nine vignettes.
- 2026-08-17: T6 ran `data-raw/m123-capability-claim-mutations.R` to completion. Source leg 128 plants / 128 RED, installed leg 48 plants / 48 RED, both controls green, 0 GREEN cells; 55 of those cells are M126's five spellings (40 source = 5 x 2 surfaces x 4 wrap forms, 15 installed = 5 x README.md/NEWS.md/one vignette). Attribution checked per pin before the run: each of the five plant sentences trips its own pattern and no other, so the harness's aggregate failure count cannot credit one pin's RED to another. `air format --check .` clean.
- 2026-08-17: T8 recorded the membership-vs-cardinality asymmetry in the Decisions section — the plan gate's answer and the plan-time audit's standing objection to it, settled on what each claim is set by rather than on how stale each could go.
- 2026-08-17: T7 gate green. `devtools::document()` produces no diff; `air format --check .` clean; `devtools::spell_check()` flags the same 28 words on this branch as on main, none of them introduced here (`merDeriv`, `glmmTMB`, `lavaan`, `brms`, `lme` were already in `inst/WORDLIST`), so no WORDLIST entry was needed; vignettes knit during the `build_vignettes = TRUE` install the installed leg requires. Installed-package suite via `test_dir(load_package = "installed")` measured in three environments: default 0/0 with 7010 passing and 108 `skip_on_cran` skips; `NOT_CRAN=true CI=true` 0/0 with 8551 passing and 23 `skip_on_ci` skips, all in `test-icc-brms.R`; and `NOT_CRAN=true` (CI unset, live Stan running) **0 failed, 0 error, 0 skipped, 8813 passing** — the run AC9 asks for. `test-doc-skew-caveat.R` reported 0 skips in all three.
- 2026-08-17: AC9 amendment drafted and WITHDRAWN before it was written. The draft pinned the run to `NOT_CRAN=true CI=true` and narrowed the 0-skip promise to `test-doc-skew-caveat.R`, on the premise that a 0-skip full run was unsatisfiable by design. The fresh-context [O] reader falsified that premise: `skip_on_ci()` fires only on the `CI=true` the draft itself added, and M119's archive records this repo reaching 0 skips at `NOT_CRAN=true` with CI unset. AC9 stands as planned, satisfied by measurement rather than by narrowing. The reader's other findings stand recorded: the vignette sentinel names two vignettes and not `engines.Rmd`, so a build dropping that vignette would yield neither skip nor failure — the deferred installed-side floor on the per-class reachability candidate row, not closed here.
- 2026-08-17: review attempt 1 RETURNED to in-progress (defect return 1). What failed: the corrected prose on all three surfaces tells users the lme4 ENGINE is usable on a stock install, when only the lme4 PACKAGE arrives — `fit_lme4()` calls `check_installed("merDeriv")` unconditionally at entry (`R/engine-lme4.R:51`, all 12 fitters), so `icc(engine = "lme4")` aborts without merDeriv for every `ci_method`. F1 and F2 are load-bearing defects in what the deliverable tells users, judged so by the maintainer at the gate; nine further findings triaged fix-now, one rejected as pre-existing. Full findings and dispositions in the Review section. PR #135 stays open as a draft.
- 2026-08-17: the `devtools::check()` launched during review attempt 1 finished after the return — 0 errors, 0 warnings, 1 NOTE on the testthat step's elapsed time (13m 27s), which devtools' own summary reports as 0 notes. Recorded for context only: it ran against the prose the return invalidates, so re-review must run it again. PR #135 CI on the returned head: format-check, check-references, pkgdown and lint green; the R CMD check matrix and coverage still in flight when the return landed.

- 2026-08-17: return 1, T11 — AC2 and AC3 amended at a mini gate (substantive; user-facing tier, so the amended wording went to a fresh-context [O] reader first). AC2 dropped the false parenthetical "requires to form an interval" and now cites `fit_lme4()`'s entry `check_installed("merDeriv")` by symbol rather than a line; the reader's load-bearing finding — that AC2's promise binds only the non-arrival disclosure, so no criterion in the set pins the engine-availability accuracy the return was about — was put to the user with the widening explicitly non-recommended per D-118, and the user selected the strictly-narrowing amendment. AC3 replaced the `:2334` citation (moved to `:2362` by this branch's own pin additions) with the rule's `test_that` description, verified verbatim and unique, and replaced its evidence clause with the numeral sweep review attempt 1 actually ran, so the four-file claim names a procedure that enumerates it. T2's `:2401` citation replaced the same way. The reader's remaining findings (AC2's Option B evidence gap, the `fit_lme4_ml_model()` counter-example to "each lme4 fitter") applied only to the option not taken.
- 2026-08-17: return 1, T9 — the engine-availability defect (F1, F2) corrected on all three surfaces. Verified first by reading the code: `rlang::check_installed("merDeriv")` opens at `R/engine-lme4.R:52, 197, 324, 566, 590, 622, 647, 672, 705, 747, 882, 1013` — the entry of each of the 12 `fit_lme4*` entry points, before any `ci_method` branching. All three surfaces now say the lme4 PACKAGE arrives while the lme4 ENGINE still waits on `merDeriv`, and each names `glmmTMB` as the only engine a plain install leaves ready to use. Riding the same edits: the new NEWS bullet reframed so it extends M123's adjacent bullet instead of appearing to reverse it (F6), the vignette named *Estimation engines* per `NEWS.md:617` and the surrounding convention (F8), and every added NEWS line brought to ≤80 characters against a file wrapping at ~76–84 (F9). `README.md` regenerated via `devtools::build_readme()`. All four edited surfaces re-checked against all 33 `claim_patterns` spellings on squashed, blockquote-stripped text: 0 hits.
- 2026-08-17: return 1, T10 (checkpoint) — the three over-broad pins re-anchored to the contiguous clause each shipped in, the `design_never_declare` precedent this file already sets. `install_not_required_*` now carries the `lme4`/`brms`/`lavaan` enumeration, without which the sentence is TRUE (F3); `install_light_*` carries the "Optional engines" scope that covers lme4 (F5); `install_one_required_dep` runs on to "and it is robust" so a future declaration-scoped true clause after the em dash cannot red it (F4). The recall cost — a reworded return of the same falsehood escapes — is recorded in the pin file's own comment. F10's entry-index comment corrected: the five are entries 29–33 of a 33-entry vector, measured by parsing the vector. Harness plants lengthened to carry the new patterns. Matrix re-run pending at this checkpoint.
- 2026-08-17: return 1, T10 complete — mutation matrix re-run against the re-anchored pins: source leg 128 plants / 128 RED, installed leg 48 / 48 RED, both controls 0 failures, 0 GREEN cells; 55 of those cells are M126's five (40 source = 5 x 2 surfaces x 4 wrap forms, 15 installed = 5 x README.md/NEWS.md/one vignette). Attribution re-checked by parsing both vectors: each of the five plant sentences trips its own pattern and no other, so the lengthened patterns did not start matching each other. The pin vector is 33 entries and M126's five sit at 29-33, measured rather than counted by hand — the figure F10's comment now states.
- 2026-08-17: return 1, AC3 evidence — numeral sweep over the four edited files. Every digit-bearing token is example code (`set.seed(1)`, `rnorm(12, ...)`, `rnorm(60, ...)`, `1:5`/`1:12`/`1:4`), printed `icc()` output (`95%`, `10000`, `4000`), markup or metadata (`height="139"`, `"100%"`, `%\VignetteEncoding{UTF-8}`, list markers `(1)`-`(4)`), design/reference names (`Design-3`, `Case-3A`, `chi-square(1)`, `t(5)`), interval supports (`[0, 1]`) or prior specifications (`half-t(4, 0, 1)`, `normal(0, ...)`). None is a count of retrieved packages, and the declared-set sentence carries no numeral.
- 2026-08-17: return 1, T12 gate green against the corrected prose. `devtools::document()` no diff; `air format --check .` clean; `devtools::test()` FAIL 0 / SKIP 2 / PASS 8461 (the two vignette-install skips the installed run covers); installed-package suite at `NOT_CRAN=true` **FAIL 0, SKIP 0, PASS 8813** — the run AC9 asks for; `devtools::check()` 0 errors, 0 warnings, 0 notes in 12m 52s, R CMD check's own single NOTE being the testthat step's elapsed time as at T7. The first installed attempt exited 1 on `library("")` in the parallel workers — `test_dir()` invoked without `package = "intraclass"`, an invocation defect in the command, not the package; re-run named and green. Vignettes knit during the `build_vignettes = TRUE` install the installed leg requires.
- 2026-08-18: review attempt 2 RETURNED to in-progress (defect return 2). Two independent reasons. (1) Consistency-gate failure: `cairn_validate` FAILs `weight caps` — the plan-owned body is 154 lines against the <150 cap, grown past it by the T9-T12 return tasks without the step-6 re-check; all 16 other checks PASS. (2) AC7 fails as literally written: it bans the `:53` clause reading as a claim about what an installation retrieves, and the replacement "it needs nothing beyond what an installation already brings" is precisely such a claim — true, but the criterion bans the form, and criteria are not reinterpreted at review. Eight further findings triaged fix-now (F3 a fresh inaccuracy this diff introduced on a shipped surface, F4-F8 pin and NEWS defects), one fixed at review (F1, the superseded evidence block), one not-a-finding (F9), one follow-up (F10, the 12 abort `reason` strings, out of scope in `R/`), one rejected (F11). Both [S] lenses returned zero findings. Full findings and dispositions in the Review section. PR #135 stays open as a draft.
- 2026-08-18: return 2, question gate — two choices settled. (1) The lme4 `merDeriv` abort message (F10) is recorded as a ROADMAP candidate row rather than folded in: `R/` is outside this milestone's Scope, and the review's own sweep established the row is distinct from the standing abort-remedy-truthfulness row. (2) `install_light_*` (F4) is repaired by extending the pattern to the withdrawn sentence's full stop AND recording the residual hazard in the pin comment, rather than by comment alone.
- 2026-08-18: return 2, T13 — deliverable and pin defects repaired. `vignettes/engines.Rmd`: the `:53`-origin clause is now declaration-scoped ("it is the engine this package declares in `Imports:`"), so it no longer states what an installation retrieves (F2), and the merDeriv covariance claim is scoped to the default Monte-Carlo interval, `R/engine-lme4.R:31` recording that the bootstrap forms none (F3). `NEWS.md`: `merDeriv` is no longer classed as an engine — the sentence names the three `Suggests` packages directly — and the paragraph is rewrapped with no short line left mid-paragraph (F6, F8). `tests/testthat/test-doc-skew-caveat.R`: `install_light_*` now ends at the withdrawn sentence's full stop, measured to still red the real withdrawn NEWS sentence and no longer to red "...stays lighter than a Bayesian stack" (F4); the hand-counted "entries 29-33" index is replaced by naming the five spellings (F5), and the claim/spelling parenthetical reads "three claims, in five spellings" (F7). Harness plants lengthened to carry the new patterns with text on both sides. Mutation matrix re-run: source leg 128 plants / 128 RED, installed leg 48 / 48 RED, both controls 0 failures, 0 GREEN; 55 cells are M126's five, and each of the five plants trips its own pattern and no other, checked by parsing both vectors. AC3 numeral sweep re-run over the four edited files: every digit-bearing token is example code, printed `icc()` output, a citation year, a coefficient or design name, a prior specification, or markup/metadata, and a whole-file sweep for a package-or-dependency count construction across all four returns no hits.
- 2026-08-18: return 2, T14 — Acceptance criteria compressed at a mini gate (substantive; user-facing tier, so the amended wording went to a fresh-context [O] reader first, which ran the criteria audit in FULL mode and returned 7 findings, verdict "a hold on the criteria set — no criterion added, removed, or widened"). Two findings applied before the gate: AC5's quantifier restored to "Each of the five" (the draft's bare "Each" had three candidate antecedents), and AC3's pointer widened to name both places its dropped rationale lives — the Decisions entry and T2's `test_that` description, the anchor installed at the return-1 gate. The section sheds 8 lines by dropping rationale prose only (AC3's staleness argument, AC6's "surface users read today" clause, AC8's "the gate's answer" aside, AC5's no-markup reason, AC2's "the installer the section recommends") and by stating AC2's three measurements as T1's with every option and both verdicts kept; criterion lines wrap at 88 rather than the file's usual 85, recorded here because the reader found wrap width, not content, was carrying the earlier draft. Coverage amended to `AC3 → T2, T3, T4, T5, T13`, the reader having found AC3's numeral sweep produced by no task — review had been running it. The user selected the compression over restoring the rationale sentences and shedding the lines from finished task entries instead. T1, T2, T4, T6 and T9-T12 were compressed in the same pass (implement-owned; their detail is in this log). Plan-owned body now 145 against the <150 cap; `cairn_validate` passes every check.
- 2026-08-18: return 2 — F10 recorded as a ROADMAP candidate row (the lme4 `merDeriv` abort message's interval-method-specific framing); F11 needs nothing, the review having rejected it as already recorded and met as written.

## Decisions
<!-- owner: implement / review · append-only -->

### 2026-08-17 — Membership is shippable on a user-facing surface; a count is not

The plan gate asked the README to name both facts — that `lme4` arrives and that
`merDeriv` does not — while AC3 forbids any count of what an installation
retrieves. The plan-time criteria audit objected that this is asymmetric: nothing
in this repo re-derives either kind of claim, and both move with CRAN, so AC3's
staleness argument appears to reach the membership claims too. It does not, and
the difference is what each claim is *set by*.

- `lme4`'s arrival is set by one declaration in one file: `glmmTMB`'s own
  `Imports:`. The README states it as a consequence of that declaration rather
  than as a fact about the install, so the sentence goes false only if glmmTMB
  drops lme4 — a visible, attributable upstream event, not drift.
- `merDeriv`'s non-arrival is set by this repo's own `DESCRIPTION`, where it sits
  in `Suggests:`. That is a file we control; moving it is our own edit.
- A count is set by neither. It is the size of a transitive closure over the whole
  dependency graph, changing whenever any package anywhere in it gains or drops a
  dependency, with no event this repo could notice. T1 measured the two obvious
  procedures disagreeing on it today — 63 by `tools::package_dependencies()`, 60
  by `pak::pkg_deps()` — so there is not even a single number to be right about.

Pinning the membership claims would need apparatus D-021 bars, and this milestone
adds none: `claim_patterns` guards *withdrawn wording* from returning to a shipped
surface, which is a guard over user-facing prose, not a ledger over the repo's own
records (D-029).

## Review
<!-- owner: review · exclusive -->

### Review attempt 1 — RETURNED 2026-08-17 (defect return 1)

Three fresh-context lenses ran. **[S] blame-history: no concerning findings** — it
traced every candidate to a sanctioned origin and confirmed the five new pins anchor
on claim-bearing prose rather than a package enumeration, so they do not repeat the
mistake that got `install_four_marked` deleted. **[S] prior-PR-comments: clean
no-op** — its existence probe returned `[]` (no real inline threads), and the
archives show M123's return-3 descope explicitly deferred this disclosure to a
follow-up row, so the diff executes that decision rather than contradicting it.
**[O] diff-bug: 11 findings**, logged below with disposition. It also re-derived the
recursive closure as **71** packages against the 63 measured at T1 — same procedure,
days apart — which corroborates AC3's no-count rule more strongly than AC3's own
argument.

- **F1 — FIX (floor-qualifying; the reason for this return).** The corrected prose
  says the lme4 *engine* is usable on a stock install; only the lme4 *package*
  arrives. `fit_lme4()` calls `rlang::check_installed("merDeriv")` unconditionally at
  entry (`R/engine-lme4.R:51`, and identically in all 12 fitters) before any
  `ci_method` branching, so `icc(engine = "lme4")` aborts without merDeriv for every
  interval method. Verified at review by reading the call sites. The framing "the
  difference decides which engines you can use without installing anything further"
  is false about the one engine the paragraph exists to discuss. The milestone
  corrected an understatement of the footprint and shipped an overstatement of engine
  availability — the same failure class it was convened to fix.
- **F2 — FIX (floor-qualifying).** "which the `lme4` engine needs before it can form
  an interval" (README) and "What an lme4 fit can additionally need is **merDeriv**"
  (engines.Rmd) both imply a merDeriv-free lme4 path. There is none;
  `R/engine-lme4.R:31` concedes it. Both corrected surfaces are now less accurate
  than the untouched `?icc` (`R/icc.R:310`), which says the engine requires both.
- **F3 — FIX.** `install_not_required_{marked,bare}` is not scoped to lme4, so the
  true sentence "brms, lavaan and merDeriv are in `Suggests`, so intraclass does not
  require them" would red. The `Suggests` anchor does not cure this — it is present
  in the true sentence too. This is the "ordinary English" hazard the file's own
  `design_never_declare` comment records.
- **F4 — FIX.** `install_one_required_dep` pins a sentence literally true of
  `DESCRIPTION`; it was withdrawn for being misleading about the install, not false.
  Its anchor "the recommended default —" survives verbatim in the corrected vignette,
  so a future declaration-scoped true clause after that em dash reds the pin.
- **F5 — FIX.** `install_light_{marked,bare}` carries the same hazard, smaller: a
  future sentence scoped only to brms/lavaan would red on a qualitative claim
  nothing in the repo can adjudicate.
- **F6 — FIX.** The two adjacent NEWS development-version bullets read as reversing
  each other: M123's says the README now names what the package *declares* rather
  than what an install *retrieves*; M126's, immediately below, says it now says what
  an installation *retrieves*, not only what it declares.
- **F7 — FIX, needs the amendment gate.** AC3 and T2 cite `:2334` and `:2401`; this
  diff's own +29 lines to `claim_patterns` moved them to `:2362` and `:2429`. AC3 is
  criterion text, so its correction goes through `/milestone-implement` step 6; T2 is
  a task edit. Work-log citations are append-only history and stay.
- **F8 — FIX.** The new NEWS bullet says "The *Engines* article"; the vignette is
  titled "Estimation engines" and `NEWS.md:617` already uses that name, as the
  surrounding convention does for every other vignette.
- **F9 — FIX.** `NEWS.md:509` is 92 chars against a file wrapping at ~76–84.
- **F10 — FIX.** The comment at `test-doc-skew-caveat.R:313` says "twelfth through
  sixteenth spellings"; these are entries 29–33 of `claim_patterns` (12–16 is true
  only of the harness's `spellings` list).
- **F11 — REJECT (out of scope: pre-existing, not introduced by this diff).**
  `CLAUDE.md:65` still heads its section "Light-install path". It is immediately
  qualified in place, CLAUDE.md is not a swept surface, and the diff did not touch
  it. Recorded here rather than actioned.

**Also carried into the return, from the AC9 amendment audit at implement:** AC2's
own parenthetical characterizes merDeriv as what the lme4 engine "requires to form an
interval" — the same understatement as F2, inside criterion text. Correcting it needs
the amendment gate alongside F7's AC3 fix.

**Criterion boxes.** AC1–AC7 were ticked against evidence recorded earlier in this
section; that evidence is stale for every surface this return will change, so those
boxes are unticked and re-verified at re-review. AC8 (the Decisions entry) stands.
AC9 was never ticked — `devtools::check()` and a fresh installed-suite run did not
complete before the return, and both must run against the corrected prose anyway.

### Evidence per criterion — review attempt 1, SUPERSEDED (see attempt 2 below)

_Left readable as history (IP4). Every quotation below is attempt-1 prose the
return withdrew; AC2's quotation is the F2 defect itself. Nothing here may be
read as current evidence, and no criterion may be ticked from it._

- **AC1 — met.** `README.Rmd:55-63` reads: "intraclass declares `cli`, `generics`,
  `glmmTMB`, `lifecycle`, `rlang`, and `tibble` as its non-base `Imports:`. ...
  `glmmTMB` names `lme4` in its own `Imports:`, so the alternate mixed-model engine
  is already present once the default engine is, whatever its `Suggests:` placement
  here implies." The disclosure is stated as a consequence of glmmTMB's declaration,
  not as a bare fact about the install.
- **AC2 — met.** Same section: "`merDeriv` — which the `lme4` engine needs before it
  can form an interval — all in this package's `Suggests:`, fetched only if you ask
  for them." Measurement re-run at review on R 4.6.1: `tools::package_dependencies()`
  over the `Imports:` field read from `DESCRIPTION` gives a 63-package recursive
  closure, `lme4` TRUE / `merDeriv` FALSE; `pak::pkg_deps()` at its default gives 60
  with the same verdicts and `brms`/`lavaan` also absent;
  `packageDescription("glmmTMB")$Imports` names `lme4 (>= 1.1-18.9000)`.
  `R/engine-lme4.R:52` and `R/icc.R:310` confirm the merDeriv requirement.
- **AC3 — met.** Swept the four edited files for a count of retrieved packages: the
  only numerals matching are `rnorm(60, ...)` and "Subjects: 60 in 12 clusters" in
  the unrelated multilevel example. The declared-set sentence names its members with
  no numeral ("six" was removed at T2).
- **AC4 — met.** `README.md` regenerated from `README.Rmd`; the branch diff is
  confined to the Installation paragraph with no drift in any printed `icc()` output.
  A second `devtools::build_readme()` at review left `git status --porcelain
  README.md` empty.
- **AC5 — met.** `tests/testthat/test-doc-skew-caveat.R:336-340` carries the five
  spellings: `install_not_required_{marked,bare}` anchored through the adjacent
  `Suggests` token, `install_light_{marked,bare}` likewise, and
  `install_one_required_dep` in one form (its shipped sentence carried no markup).
  `data-raw/m123-capability-claim-mutations.R` carries five matching plants. Matrix
  result: source leg 128 plants / 128 RED, installed leg 48 plants / 48 RED, both
  controls green, 0 GREEN cells; 55 cells are M126's five. `git diff 787d637..HEAD`
  over the pin and harness is empty, so the matrix ran against the shipped content.
- **AC6 — met.** `NEWS.md:507-509` now reads "Optional engines live in `Suggests`:
  `brms`, `lavaan` and `merDeriv` are fetched only on request, while `lme4` arrives
  regardless as a dependency of `glmmTMB`." — replacing "so the base install stays
  light" in place, inside the unreleased `# intraclass 0.1.0` section. A
  development-version Documentation bullet records the README change.
- **AC7 — met.** `vignettes/engines.Rmd:32-37` discloses that installing the package
  retrieves lme4 via glmmTMB's `Imports:` and that merDeriv sits in `Suggests:`; the
  `:53` clause now reads "it is the engine this package declares, it needs nothing
  beyond what an installation already brings" in place of "it is the one required
  dependency". The vignette knits (built during the `build_vignettes = TRUE` install).
- **AC8 — met.** The Decisions section carries the 2026-08-17 entry settling the
  membership-vs-cardinality asymmetry the plan-time audit raised.

### Review attempt 2 — RETURNED 2026-08-18 (defect return 2)

**Consistency gate.** `cairn_validate` FAILED `weight caps`: this file's plan-owned
body is **154 lines against the <150 cap** (Acceptance criteria 58 · Tasks 44 ·
Scope 20 · Coverage 13 · Goal 6). The T9–T12 return tasks grew the Tasks section
past the cap and `/milestone-implement` step 6's re-check was not run. All 16
other checks PASS; two advisory WARNs (9 criteria, 12 tasks) are not gate
failures. Toolchain half clean: `document()` no diff, `air format --check` clean,
`pkgdown::check_pkgdown()` no problems, `README.md` in sync, `devtools::check()`
0/0/0, NEWS entry present.

**Three fresh-context lenses ran.** **[S] prior-PR-comments: zero findings** — the
inline-comment probe returned `[]`, and against the archives it independently
confirmed every F1–F10 fix landed and F11 was correctly left untouched, and that
M126 executes M123's recorded descope rather than contradicting it. **[S]
blame-history: no concerning findings** — it established from history that M123
shipped a membership-anchored pin and had to drop it precisely because such a
fragment reds on a future true sentence, so this branch's re-anchoring applies
that lesson rather than reversing it; it also verified the merDeriv claim against
`R/engine-lme4.R` and confirmed `# intraclass 0.1.0` is unreleased draft, so
editing it in place is not rewriting shipped history. **[O] diff-bug: 11
findings**, below with disposition. It independently verified the return-1 fixes:
the 12 `check_installed("merDeriv")` entry points, 0 pattern hits across the four
files, all five plants containing their patterns with no cross-attribution, the
33-entry vector with M126's five at 29–33, and `README.md` normalized-identical
to `README.Rmd`.

- **G1 — FIX (gate failure; a reason for this return).** The `weight caps` failure
  above. Remedy is the stated one: compress the single heaviest plan-owned section
  in one rewrite, never a nibble-and-recount loop.
- **F2 — FIX (floor-qualifying; the other reason for this return).** AC7 as
  literally written is not satisfied. It requires the `:53` clause to "no longer
  read as a claim about what an installation retrieves"; the replacement at
  `vignettes/engines.Rmd:59` is "it needs nothing beyond what an installation
  already brings", which is precisely such a claim. True, but AC7 bans the form,
  not the falsity, and criteria are never reinterpreted at review. Verified at
  review by reading the line. Repair is on the deliverable, not the criterion: a
  declaration-scoped clause ("it is the engine this package declares in
  `Imports:`").
- **F3 — FIX.** `vignettes/engines.Rmd:35-36` says merDeriv "supplies the parameter
  covariance the interval is built from" as an engine-wide claim; `R/engine-lme4.R:31`
  records that merDeriv is not needed for the bootstrap, where no covariance is
  formed. A fresh inaccuracy introduced on a shipped surface by the edit meant to
  remove one. Repair: scope it to the default Monte-Carlo interval.
- **F4 — FIX.** `install_light_*` is only partly cured. `fixed = TRUE` matching means
  "…so the base install stays light" still reds "…stays lighter than a Bayesian
  stack" — verified at review by running the match, which returns TRUE — and reds the
  clause even when a following sentence qualifies it. The pin's own comment claims
  the "Optional" anchor cures this; it does not, since nothing appended after the
  matched span changes it. Repair: a sentence-final anchor, or record the residual
  hazard in the comment, which currently records only the recall cost.
- **F5 — FIX.** `tests/testthat/test-doc-skew-caveat.R:313` re-pins a hand-counted
  index ("entries 29-33"). Correct today and append-safe, but it breaks on any
  insertion — exactly how "twelfth through sixteenth" went stale, which is what F10
  was raised about. Repair: name the five spellings, or state the deriving procedure.
- **F6 — FIX.** `NEWS.md:509-510` classes `merDeriv` as an engine ("Optional engines
  live in `Suggests`: `brms`, `lavaan` and `merDeriv`"); it is the lme4 engine's
  helper, as the next clause says. Repair: "Optional engines and their helpers".
- **F7 — FIX.** `test-doc-skew-caveat.R:311` pairs a claim count with a spelling
  range in one parenthetical ("M126's three claims (entries 29-33)"), reading as an
  off-by-two. Repair: "three claims, in five spellings".
- **F8 — FIX.** `NEWS.md:513` leaves a ~28-char line mid-paragraph after the rewrap,
  against a file wrapping at ~76–84. Cosmetic; `air` does not format Markdown.
- **F1 — FIXED AT REVIEW.** The attempt-1 "Evidence per criterion (**fresh**…)"
  block read as current while quoting withdrawn prose — AC2's quotation is the F2
  defect itself. Retitled SUPERSEDED in place with an explicit do-not-tick note,
  rather than deleted (IP4). The Review section is review-exclusive, so this needed
  no return.
- **F9 — NOT A FINDING.** The lens flagged that it had not re-run the mutation
  harness or `build_readme()` because both write. Both were run this session:
  matrix 128/128 and 48/48 RED with clean controls, and a second `build_readme()`
  left `git status --porcelain README.md` empty. Recorded so the gap is closed, not
  carried.
- **F10 — FOLLOW-UP (out of scope: `R/`, outside this milestone's Scope).**
  `R/engine-lme4.R:52` and its 11 siblings give `reason = "to compute lme4
  Monte-Carlo confidence intervals."` — the last surface still implying the merDeriv
  requirement is interval-method-specific, the exact framing this milestone withdrew
  from the docs, and user-visible as an error message. Swept ROADMAP first: the
  standing `abort-remedy truthfulness` row is about a ledger and CI checker (barred
  by D-021) and its trigger is a misleading *remedy bullet*, so this is distinct.
  Needs a candidate row, or a scope amendment if the user wants it folded in here.
- **F11 — REJECT (already recorded; met as written).** The harness plants only
  `vig[1]`, so `engines.Rmd` is swept by the pin but never planted on the installed
  leg. Recorded on the standing `Per-class reachability proof` candidate row, and
  AC5 as amended promises only "one installed vignette".

**Criterion boxes.** None ticked this attempt. AC7 fails as written (F2); AC1–AC6
and AC9 have evidence that would need re-gathering after the F2/F3/F6 prose
changes; AC8 (the Decisions entry) stands from attempt 1 and is unaffected.

