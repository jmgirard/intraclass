<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. -->
# M123: Correct the falsified capability claims in the shipped documentation

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** GP1, GP4   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** `m123-falsified-capability-claims` · https://github.com/jmgirard/intraclass/pull/132   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Withdraw the four capability claims the shipped documentation makes that the
package's own code falsifies, and pin each withdrawal so it cannot return.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**Surface tier: user-facing.** `README.md` ships in the tarball and is the
pkgdown home page; `multilevel-designs.Rmd` ships as an article. D-029 governs:
correcting a false statement the package makes to its users plans normally, and
D-021 is not quoted at it.

**In:** the brms-on-the-roadmap sentence (`README.Rmd:45-46`); the engine
enumeration that omits brms (`README.Rmd:42`); the base-install list naming 4 of
6 non-base Imports (`README.Rmd:57`); the "you never declare it" design claim
(`vignettes/multilevel-designs.Rmd:110-111`), which the same vignette
contradicts at `:198`. The identical install falsehood and an unbacked
`augment` method claim in our own records (`cairn/DESIGN.md:69,72`;
`CLAUDE.md:65`) are corrected in place here, per D-021's correct-in-place
clause. Pins extend `tests/testthat/test-doc-skew-caveat.R`.

**Out:** refreshing the README's feature blurb to name the opt-in `ci_method`s,
replicates/occasions, or `tidy()`/`glance()` → plan-gate choice, minimal-diff;
those are absences, not falsehoods, and become part of M124's remit where they
touch demonstration. Per-S3-method `\value` prose and `icc()`'s example
shadowing the `ratings` dataset → candidate row, promoted at M48. The version
stamp, NEWS consolidation and `cran-comments.md` → M48.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets -->

- [x] AC1: `README.Rmd` states no Bayesian engine as unshipped or forthcoming,
      and its engine enumeration names `brms` beside `glmmTMB`, `lme4` and
      `lavaan` (GP4's closed roster). `README.md` is re-knitted from it in the
      same commit; re-knitting on the same toolchain leaves `README.md`
      byte-identical.
- [x] AC2: on every surface either walk reaches except `R/*.R` (source code, not
      prose), each sentence — cut by the pin file's `width_split()` — naming
      three or more non-base entries of `DESCRIPTION`'s `Imports:` names exactly
      that set and carries, case-sensitively, `Imports` or `non-base` in the
      same sentence. One recorded command enumerates them from the walk's own
      output, reports the count (an empty enumeration fails), and asserts both,
      run after `devtools::install()` so the installed leg reads this branch's
      build. Non-base = `Imports:` minus
      `rownames(installed.packages(priority = "base"))` — today `cli`,
      `generics`, `glmmTMB`, `lifecycle`, `rlang`, `tibble`. What this does and
      does not establish: MD-1.
- [x] AC3: `vignettes/multilevel-designs.Rmd` no longer claims the design is
      never declared; it states inference-by-default and names `design =` as
      the disambiguator on incomplete data, agreeing with the `@param design`
      roxygen at `R/icc.R:243-249` and with the vignette's own `:198`.
- [x] AC4: `cairn/DESIGN.md:69` and `CLAUDE.md:65` carry the AC2 install set,
      and `cairn/DESIGN.md:72` no longer lists `augment` among the shipped tidy
      S3 methods (`git grep -n augment -- NAMESPACE R/` returns nothing).
- [ ] AC5: `source_doc_surfaces()` gains `README.Rmd` and `README.md`, and
      `installed_doc_surfaces()` gains `system.file("README.md")`; every site
      the extended walk reports for the claim patterns this milestone adds is
      corrected or recorded in the work log as correct-as-written. The
      anti-vacuity floor asserts, on each leg that runs, that the leg is
      non-empty, and asserts of each of `README.Rmd` and `README.md` present in
      the layout the run executes in that the walk reached it and read it
      non-empty. What exits to the ROADMAP apparatus candidate row: MD-2.
- [ ] AC6: each claim pattern this milestone adds — AC1–AC4's nine and AC8's two
      — joins that file's existing `claim_patterns` machinery as new
      `test_that()` blocks; no second instrument (D-029). Every claim carries at
      least one backtick-free spelling (why, and the measurement: MD-2). Each of
      AC1–AC4's four claims is mutation-verified red on ≥2 spellings, AC8's two
      on one spelling each; every spelling reds at ≥2 distinct surfaces on the
      source leg in each of the four wrap forms the harness declares, the
      guarantee bounded to those four; and on the installed leg at `README.md`,
      `NEWS.md` and one installed vignette in the blockquote form, planted into
      a real install and never shadowed by `load_all`'s `system.file()`
      fallback. What exits to the ROADMAP apparatus candidate row: MD-2.
- [ ] AC7: `cairn/PROFILE.md`'s verify slot clean, plus `air format --check`,
      `lintr::lint_package()`, and all four `data-raw` checkers
      (`check-references`'s set) run locally before push; and
      `devtools::check()`, run locally on this branch and on `main` under the
      same toolchain, reports 0 errors, 0 warnings, and no NOTE on this branch
      that `main` does not also report.
- [x] AC8: the changelog's "every non-base package the install pulls" is
      withdrawn from `NEWS.md` and pinned as a spelling in the same
      `claim_patterns` vector; the README's transitive clause is withdrawn and
      pinned by its misleading part — the singular "that one" beside "light" —
      never by its true clause about what the default engine brings. The
      guarantee is bounded to the spellings in that vector and nothing wider;
      what no criterion here reaches: MD-1. Each pinned spelling is
      mutation-verified red under AC6's procedure.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T5
- AC2 → T2, T5, T14
- AC3 → T3
- AC4 → T4
- AC5 → T6, T17, T21, T22
- AC6 → T7, T16, T20, T21, T22, T23
- AC7 → T8, T18
- AC8 → T15

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1-T5 (shipped, first pass): rewrite `README.Rmd`'s engine enumeration and
      roadmap sentence and its install list; rewrite
      `vignettes/multilevel-designs.Rmd:110-111` against `R/icc.R:243-249`;
      correct `cairn/DESIGN.md:69,72` and `CLAUDE.md:65`; `build_readme()`
      byte-identical on a second run.
- [x] T6-T8 (shipped, first pass): extend both walk legs with the README
      surfaces and the anti-vacuity floor; add the claim patterns and their
      `test_that()` blocks with a mutation matrix; full gate, PR, CI green.
- [x] T9-T13 (shipped, return-1 fix round): strip the blockquote marker per line
      on both legs; merge the capability spellings into `claim_patterns`;
      tarball-safe README floor; withdraw the "installed only if you ask" clause
      and re-knit; commit `data-raw/m123-capability-claim-mutations.R` and run
      its matrix; re-verify against the installed package.
- [x] T14-T20 (shipped, return-2 fix round; detail in the work log and in git):
      attribute the README install list to `Imports:` and add AC2's
      enumerate-and-assert test; withdraw and pin the two transitive-install
      phrasings; restore a backtick-free spelling per claim and correct two
      false comments against measurement; plant at `README.md` and run the
      installed leg against a real install; resolve the spelling NOTE and run
      the `check()` differential against `main`; simplify the pin; full gate,
      CI green.
- [x] T21: descope amendment — narrow AC5/AC6 to the demonstrated evidence;
      supersede MD-1's AC6 paragraphs; carry the exits into the apparatus
      candidate row; log the README disclosure gap as its own candidate row.
- [x] T22: correct the false reachability comment at
      `test-doc-skew-caveat.R:278-279`; restore the unconditional installed-
      vignette floor the glob rewrite made vacuous under `R CMD check`; drop the
      duplicated floor `stopifnot` in the harness.
- [x] T23: re-run the mutation matrix from the committed harness and the full
      gate; push; drive CI green.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates -->

- 2026-08-16: created by /milestone-plan (assessment run over documentation and vignettes; two [S] audits + one [O] criteria audit).
- 2026-08-16: criteria audit ran in FULL mode (user-facing tier) and returned 12 findings; 7 with one clear right answer were fixed into these criteria before the gate (F1 install set scoped to non-base Imports; F2 `cairn/DESIGN.md` added to the correction set; F3 AC4's hand-list of paths replaced by the existing walk; F4 mutation probes widened to ≥2 spellings × ≥2 surfaces; F5 `README.Rmd`/`README.md` legs added, the installed walk cannot see an `.Rbuildignore`d file; F7 "new `test_that()` blocks in that file" made explicit against D-029; F8(ii) the unbacked `augment` claim added to AC4). F6 and F12 resolved autonomously: AC1's knit clause is scoped to the same toolchain since `README.Rmd:70,105` evaluate live glmmTMB fits, and AC5's `R/` leg reads internal comments, which are recorded correct-as-written rather than treated as user-facing sites.
- 2026-08-16: plan gate chose the minimal-diff README correction over also refreshing the feature blurb because every changed byte then traces to a verified falsehood; falsified by a user report that the README's omissions (opt-in `ci_method`s, replicates, tidy methods) mislead as much as its false sentences did.
- 2026-08-16: plan gate chose a mutation-verified pin over a plain correction recorded in the work log because M115 recorded a claim criterion-met on a `fixed = TRUE` false negative against a line-wrapped sentence and shipped a sixth stale site; falsified by the pin costing a review return without ever having reddened on a real reintroduction.
- 2026-08-16: plan gate chose extending `test-doc-skew-caveat.R` over a second checker because D-029's consequences clause bars a new doc-claim instrument absent D-021's trigger; falsified by that file's walk proving unable to carry the README surfaces.
- 2026-08-16: T1-T4 — the four false claims withdrawn and the two records corrected; `git grep -n augment -- NAMESPACE R/` exits 1, so AC4's second clause holds.
- 2026-08-16: T2 — AC2's comparing command run: `Imports` is `cli, generics, glmmTMB, lifecycle, rlang, stats, tibble`; subtracting `rownames(installed.packages(priority = "base"))` removes `stats` alone, leaving the six the README now names. The prior sentence named four of the six.
- 2026-08-16: T6 — both walk legs extended: `source_doc_surfaces()` gains `README.Rmd` and `README.md`, `installed_doc_surfaces()` gains `system.file("README.md")`. Census over the extended walk: 35 source surfaces, 9 installed, both README legs confirmed reached and non-empty, and 0 hits for any capability pattern — so no site needed a correct-as-written entry. The legacy numeric patterns now sweep the READMEs too and stay green there.
- 2026-08-16: T7 — mutation matrix, 27 plants, all RED against a 0-failure baseline: 9 spellings (3 for the Bayesian-roadmap claim, 2 each for the engine enumeration, the install list, and the design claim) × 3 surfaces (`README.Rmd`, `R/icc.R` roxygen, `vignettes/multilevel-designs.Rmd`), with the `R/icc.R` and vignette plants WRAPPED across two lines — the M115 false-negative shape, which `squash()` reconstructs. Every claim therefore has ≥2 spellings and every spelling ≥2 surfaces, one wrapped. Harness restored the tree after each plant.
- 2026-08-16: T8 — full suite green against the working tree: FAIL 0, PASS 8030, SKIP 2 (the two known dev-session installed-vignette skips), WARN 3 (the expected fixed-rater teaching warnings in the brms tests). `air format --check` clean, `lintr::lint_package()` clean, all four `data-raw` checkers OK, `cairn_validate` all checks passed.
- 2026-08-16: T8 — full CI matrix green on 79ee887: all 10 checks success, including both R-CMD-check runners (ubuntu-latest release, windows-latest release), check-references, checkpoint-guard, lint, format-check, pkgdown and test-coverage. An earlier tracking-only push cancelled the in-flight run on 8033a0a (the M78 cancel-in-progress behaviour), so the green matrix is read off the current head.
- 2026-08-16: T5 — `devtools::build_readme()` run twice; the second knit is byte-identical, so AC1's same-toolchain clause holds. The knit also moved four interval endpoints (e.g. `ICC(A,1)` upper 0.715 to 0.714) with every point estimate unchanged: the committed `README.md` was last knitted 2026-07-17 and predates the interval code shipped in M104-M119, so the rendered file was stale on main. This milestone's edits touch prose only and cannot move a number.

- 2026-08-16: review attempt 1 RETURNED to `in-progress` (defect return 1). Two floor findings: the claim pin returns FALSE against the real pre-correction sentence because `squash()` leaves the markdown blockquote `>` mid-sentence, so the primary guarded claim is unguarded and AC6's 27-plant matrix never exercised that wrap; and the rewritten install sentence's new "installed only if you ask for them" clause is false, `glmmTMB` importing `lme4` unconditionally. AC1-AC4 and AC7 verified and ticked; AC5 and AC6 unticked. F3-F7 (tarball-layout floor failure, load_all masking the installed leg, the forked instrument against D-029, the uncommitted mutation harness, two unreachable spellings) ride the same fix round.

- 2026-08-16: T9-T10 — F1 closed: both walk legs now strip `^\s*>+\s?` per line BEFORE the join, so a `> [!NOTE]` callout no longer leaves the marker mid-sentence; restoring `main`'s `README.Rmd` verbatim now reds with 6 failures across 2 blocks where it was green. F5 closed: `capability_claim_patterns` and `expect_no_capability_claim` deleted, the nine spellings merged into the existing `claim_patterns` vector and `expect_no_withdrawn_claim`. F7 closed: `engines_omit_brms_bare`/`install_four_bare` replaced by `engines_omit_brms_and` (connective swap) and `install_four_alpha` (same four names alphabetized) — both reachable re-edits, neither present on any corrected surface. F3 closed: the README floor asserts per file against what is on disk and requires at least one README leg, so an unpacked tarball skips the `.Rbuildignore`d `README.Rmd` instead of hard-failing.
- 2026-08-16: T11 partial — F2's false clause withdrawn from `README.Rmd`, `cairn/DESIGN.md` and `CLAUDE.md`. `glmmTMB` declares `Imports: lme4 (>= 1.1-18.9000)` (read from the installed DESCRIPTION), so the prose now says intraclass never requires the `Suggests` engines and notes that `lme4` arrives with the default engine regardless. The `README.md` re-knit is still owed.
- 2026-08-16: T12 in progress — `data-raw/m123-capability-claim-mutations.R` committed: 9 spellings × 3 surfaces × 4 wrap forms = 108 plants, the wrap forms including two blockquote shapes, with a control run and a floor requiring every plant RED. Control clean at 0 failures and the first 4 plants RED; the run was interrupted for this checkpoint and the full matrix has not yet completed.
- 2026-08-16: T12 — full matrix run to completion from the committed harness: 108 plants, 108 RED, 0 GREEN, against a 0-failure control. Every spelling now reds at all three surfaces in all four wrap forms, the two blockquote shapes included — the form F1 showed unguarded and the first pass's 27-plant matrix never wore.
- 2026-08-16: T11 — `devtools::build_readme()` re-run twice after the F2 correction; the second knit is byte-identical (md5 1564aa262e1ad45d17cc047812f52526 both times), so AC1's same-toolchain clause still holds. The diff is 6 insertions / 4 deletions, prose only: no point estimate and no interval endpoint moved, the endpoint refresh having already landed in the earlier T5 knit.
- 2026-08-16: T13 — F4 closed. `devtools::install(build_vignettes = TRUE)` then `test_dir(..., load_package = "installed")` on the pin file: FAIL 0, ERROR 0, **SKIP 0**, PASS 2252 — the two dev-session skips are gone, so the installed vignette and README legs genuinely ran rather than re-reading the source tree through `load_all`'s `system.file()` (the M116 lesson). Discriminating control: appending the blockquote-wrapped roadmap sentence to the INSTALLED `README.md` reds exactly the two installed-leg blocks (FAIL 2), and the installed copy was restored after.
- 2026-08-16: T13 — local gate: `devtools::document()` no diff, `air format --check` clean, `lintr::lint_package()` clean, all four `data-raw` checkers OK, full suite FAIL 0 / WARN 3 / SKIP 2 / PASS 8118 (the same known skips and teaching warnings as the first pass), `cairn_validate` all checks passed with one advisory — 13 tasks against the >10 split tripwire, which is a fix round appended to an already-shipped plan rather than a milestone wanting a split.

- 2026-08-16: T13 — full CI matrix green on b192efd: all 10 checks pass, including both `R CMD check` runners (ubuntu-latest release, windows-latest release), check-references, checkpoint-guard, lint, format-check, pkgdown, test-coverage and both codecov reports. The covr and `.Rcheck` layouts are the two F3 named as the reason the tarball floor failure went unseen, and both are green under the per-file floor. Fix round complete; status to `review` (defect return 1 answered).
- 2026-08-16: review attempt 2 RETURNED to `in-progress` (defect return 2). Four floor findings: the fix round deleted the only spellings reaching the Rd surface and wrote a false rationale for doing so (flattened Rd carries 0 backticks); the "installed walk" block's comment claims a `load_all` skip that does not happen, so the committed 108-plant matrix never exercised the real installed leg; the new NEWS bullet repeats the transitive "the install pulls" framing F2 was returned for; and the corrected README sentence says "imports only" over six of seven `Imports:` entries while naming one extra arrival against a 63-package closure. AC1-AC5 and AC7 verified and ticked; AC6 unticked (mutation half not freshly re-run). F13-F15 (no README.md plant, no vignette presence floor, a new spelling NOTE from the NEWS bullet) ride the same fix round; F18-F20 are follow-ups.
- 2026-08-16: amendment (substantive) after defect return 2 — AC2, AC5, AC6 and AC7 amended and AC8 added, because every finding of both returns fell OUTSIDE the domain of the procedure its nearest criterion named: AC2 subtracted base packages and could not see the word "only", AC6 required >=2 surfaces and could not see the Rd leg, and no criterion reached changelog prose or code comments at all. AC2 now binds attribution, not just the name set; AC5's floor is glob-derived and cross-checks the harness's plant targets; AC6 replaces "2 distinct surfaces" with a computed per-pattern reachability report and requires the installed leg to be planted into a real install; AC7 compares check() against `main`; AC8 pins the two transitive-install phrasings. Amended AC2/AC5/AC7 un-ticked — the wording they were verified against no longer stands.
- 2026-08-16: criteria audit ran in FULL mode (user-facing tier) over the amended wording, twice, each round a fresh-context [O] reader that authored none of it. Round 1 returned 10 findings: AC2 as first drafted was unsatisfiable (8 `R/*.R` code blobs tripped it, zero prose), its sentence unit was unnamed, its qualifier test was case-ambiguous so the lowercase "imports only" would have survived untouched, "surface class" was undefined although the definition decides the Rd answer, the comment-consistency clause missed the harness, and "0 NOTEs" bound a whole-package global to a prose milestone; 7 had one clear right answer and were fixed before the gate, 3 went to it. Round 2 returned 12 over the gate-fixed text: AC2's token test admitted a sentence carrying `non-base` AND "the install pulls" (the returned F16 sentence itself), AC5's new plant-target clause had no existence gate and would have reproduced attempt 1's tarball hard-fail, AC2 did not say its command runs after a fresh install, and AC6's "each claim pattern" read over the whole legacy vector; 5 fixed directly, 4 disposed with the obvious reading, 3 to the gate.
- 2026-08-16: measured at the round-2 audit — AC2's rule over the real walk catches 3 sentences (all the same README sentence, on `README.Rmd`, `README.md` and the installed `README.md`), and the token property FAILS on all three, so AC2 as amended is currently unmet. Including `R/*.R` would add 8 hits, every one source code and none prose, which is why the exclusion is drawn there.
- 2026-08-16: gate decisions on the three judgment calls — pin the README's transitive clause by its misleading part ("that one" beside "light") rather than its true clause, since the sentence is incomplete and not false; state the rewording gap inside AC8 rather than lowering AC2's threshold into source code; and require a backtick-free spelling per `Rd:*`-reachable claim rather than merely disclosing the inertness.
- 2026-08-16: attempt 2's F20 is DEFERRED explicitly rather than left silent — `design_never_declare = "you never declare it"` is four words of ordinary English swept over `R/` internal comments, an internal surface below this milestone's user-facing tier; no amended criterion covers it and a ROADMAP candidate row carries it.
- 2026-08-16: the amendment takes the plan-owned body to 170 lines against the <150 cap. One compression pass on the heaviest section ran as the remedy prescribes — AC2/AC6/AC8's rationale moved verbatim into MD-1 and cross-referenced, promises unchanged — taking Acceptance criteria 85 to 68 and the body 187 to 170. Still 21 over, and all three split tripwires now fire (8 criteria, 19 tasks, no hope of the cap). Further compression would cut audited promises rather than prose, so the cap failure is left standing for a split decision rather than nibbled at. Committed in this state deliberately: `cairn_validate` FAILs `weight caps` until it is resolved.
- 2026-08-16: split decided at the sizing gate — M123 keeps the corrections and the pins that demonstrably catch the real sentences; the proof apparatus (per-class reachability reporting, installed-leg planting at one reinstall per spelling, the `Rd:*` wrap sweep, the harness plant-target cross-check) goes to M125, `Depends on: M123`. AC5 and AC6 narrowed accordingly — the backtick-free spelling per claim stays here, since it is a spelling and not machinery. Plan-owned body back to under the cap after compressing the completed T1-T13 into three done-lines (their detail is in this work log and in git); `cairn_validate` green, one sizing advisory left.
- 2026-08-16: F15 settled by command against the round-2 audit's refutation of it. `R CMD check` on this branch reports `Status: 1 NOTE` — reproducible on a second full run — from the `spelling.Rout` vs `spelling.Rout.save` comparison, whose flagged-word list now includes `README`/`README's` from this branch's new NEWS bullet (`main`'s NEWS.md contains no occurrence of the word). The audit's ground for refusing F15 was that no `.Rout.save` exists in the repo, which is true of the checkout — `git ls-files tests/` lists only `spelling.R` and `testthat.R` — and does not settle the check environment, where the comparison demonstrably runs. `devtools::check()`'s own summary line filters that NOTE class and prints `0 notes`, which is why the two reports disagree. Whether the branch INTRODUCED it is what amended AC7's differential against `main` exists to decide; T18 runs it.
- 2026-08-16: amendment — AC6's deferral pointer changed from `M125's` to the ROADMAP candidate row, executing the plan gate's refusal to plan that milestone: D-021 bars a milestone whose deliverable is a guard over this repo's own records absent a trigger in what the package computes, and D-029's consequences clause declines to exempt apparatus. The promise is unchanged; only the destination of the deferred work moved. T20 added for the simplification the same gate chose.
- 2026-08-16: T14/T15 — README install sentence rewritten to attribute the list to the `Imports:` field and to say plainly that an installation retrieves the full closure of those declarations; the NEWS bullet's "every non-base package the install pulls" and the README's "so that one arrives with the default engine" both withdrawn, and both pinned as spellings. AC2's enumerate-and-assert test added: it drops `R/*.R`, `width_split()`s every remaining surface on both legs, selects sentences naming >=3 of the non-base Imports, fails on an empty enumeration, and requires each to name exactly the set and carry `Imports` or `non-base` case-sensitively.
- 2026-08-16: T16/T20 — every claim now carries a backtick-free spelling, `engines_omit_brms_bare` and `install_four_bare` restored for the reason the second pass got backwards: `rd_flat()` discards `\code{}`, so the flattened help database has 0 backticks (measured against a roxygen source that has them) and a backticked-only pattern is inert on the one class a built package's walk reads. Two false comments corrected against measurement — the Rd-markup claim, and the "skips under `load_all`" claim on the installed-README block, which does not skip because pkgload's `system.file()` falls back to the package root. Simplification: `install_four_alpha` dropped (it encoded a package set, so dropping `lifecycle` or `tibble` from `Imports:` would have made the CORRECTED sentence read as a withdrawn claim) and `design_never_declare` narrowed from four words of ordinary English to the clause it actually shipped in.
- 2026-08-16: T17 — AC5's vignette floor derived from the `vignettes/*.Rmd` glob instead of a two-name hand list, which had left `multilevel-designs.Rmd` — the sole home of one withdrawn claim — unfloored on both legs. Harness reworked: source surfaces cut to the two distinct markup regimes, `README.md`/`NEWS.md`/an installed vignette planted in the LIBRARY TREE for the installed leg, byte-faithful `readBin`/`writeBin` restore, and the installed cells run in a fresh subprocess with a pre-flight assertion that `system.file()` resolves outside the checkout — because this process has already called `load_all()`, under which an in-process installed cell would re-read the source and report coverage it does not have.
- 2026-08-16: T18 (partial) — `README`/`README's` added to `inst/WORDLIST` (the first occurrence of the word in `NEWS.md` came from this branch's own bullet; `Revelle`/`Revelle's` show the file lists possessives separately). `spelling::spell_check_package()` no longer flags either. The `devtools::check()` differential against `main` that AC7 now requires runs at the gate.
- 2026-08-16: process note — a `git stash` run while the mutation harness held a plant in `README.Rmd` captured the planted line into the stash and the pin caught it on the next run (`bayes_planned` present in `README.Rmd`). Removed, README re-knitted, suite green. Nothing touches the tree while that harness runs.
- 2026-08-16: T17 — mutation matrix complete on both legs against 0-failure controls: source leg 88 plants (11 spellings × 2 markup regimes × 4 wrap forms) 88 RED; installed leg 33 plants (11 spellings × `README.md`, `NEWS.md`, an installed vignette, blockquote wrap) 33 RED. The installed leg SKIPPED on its first run and the harness said so rather than reporting coverage: `installed_targets()` resolved the library path in-process, where `load_all()` had already shimmed `system.file()` to the checkout, and the guard refused the source tree. Fixed by resolving that path in the subprocess too — the same defect the leg exists to detect, caught by its own pre-flight.
- 2026-08-16: T18 — AC7's differential run: `devtools::check()` on this branch and on `origin/main` in a detached worktree, same toolchain. It found a real ERROR in the new AC2 test, which read `../../DESCRIPTION`; under `R CMD check` the tests run from `.Rcheck/tests/testthat` and the package sits at `.Rcheck/intraclass/`, so the read failed and errored the whole check while every other layout stayed green — the same layout-blindness class as return 1's F3. Now reads `packageDescription("intraclass")` first and falls back to the source path.
- 2026-08-16: T18 — and the differential falsified return 2's F15. `main` reports the `spelling.Rout`/`.Rout.save` NOTE as well, so this branch did not introduce it; F15 attributed a pre-existing NOTE to the new NEWS bullet on the strength of the word `README` appearing in the flagged list. The `inst/WORDLIST` entries stay (they remove two genuine flags) but they fix nothing this milestone broke. `main`'s second NOTE, `.git` under hidden files, is an artifact of checking from a worktree and is not a property of `main`.
- 2026-08-16: T18 — re-run after the layout fix: `devtools::check()` on this branch reports 0 errors, 0 warnings and `Status: 1 NOTE`, that NOTE being the `spelling.Rout` comparison `main` also reports, so AC7's differential holds (no NOTE here that `main` does not also report). `main`'s extra `.git` hidden-files NOTE is a worktree artifact and does not bear on the branch. Gate: `air format --check` clean, `lintr::lint_package()` clean after fixing two `quotes_linter` hits in the harness, all four `data-raw` checkers OK, `cairn_validate` all checks passed (1 sizing advisory), `pkgdown::check_pkgdown()` clean, `document()` no diff. Worktree removed.
- 2026-08-16: T19 — profile verify slot clean (FAIL 0, WARN 3, SKIP 2, PASS 8221 — the same known dev-session skips and fixed-rater teaching warnings as every prior pass), and the full CI matrix green on d4a397d, all 10 checks. Fix round for defect return 2 complete; status to `review`.

- 2026-08-16: review attempt 3 RETURNED to `in-progress` (defect return 3). Two floor findings, each an acceptance criterion failing inside its own named procedure: AC6's comment clause, against `test-doc-skew-caveat.R:278-279` claiming `Rd:*` is the only class running under `R CMD check` when the installed leg also reads `NEWS.md`, `README.md` and 8 `doc/*.Rmd`; and AC5's floor-gating clause, against the new glob-derived vignette floor, which gates on a source `vignettes/` dir absent from `.Rcheck` and so skips entirely in the layout CI runs, where `main` asserted unconditionally. AC1-AC4 and AC8 verified and ticked; AC5, AC6 and AC7 unticked (AC7's `check()` differential against `main` not re-run this attempt). F24, F26, F27 would ride a fix round; F25, F28-F31 are follow-ups. Thrash rule fires on both triggers — third return, and AC6 failing twice by a new mechanism of the same shape — with a split already spent, so the disposition goes to the maintainer.
- 2026-08-17: maintainer disposition at the return-3 thrash gate — DESCOPE. Keep AC1-AC4 and AC8 as written; narrow AC5 and AC6 to the evidence already demonstrated (the corrected surfaces, and the mutation plants that ran RED), dropping AC5's vignette-floor gating clause and AC6's comment-consistency clause; both exit to the existing per-class-reachability apparatus candidate row. The false comment at `test-doc-skew-caveat.R:278-279` is fixed only if a kept criterion still reads it, else it rides that row too. Amendment via /milestone-implement step 6, then re-review the narrowed set.
- 2026-08-17: amendment (substantive), executing the maintainer's return-3 descope. AC5 and AC6 narrowed to the evidence already demonstrated: AC5 keeps the walk extension, the correct-or-record duty and the README non-emptiness floor, and exits the vignette/README floor enumeration and its layout coverage; AC6 keeps the single-instrument requirement, the backtick-free spelling per claim and the mutation matrix as it actually ran, and exits the comment-consistency clause, `Rd:*` mutation verification in any form, per-class reachability reporting and the harness plant-target cross-check. AC1-AC4, AC7 and AC8 unchanged. Amended AC5/AC6 un-ticked.
- 2026-08-17: criteria audit ran in FULL mode (user-facing tier) over the amended wording, by a fresh-context [O] reader that authored none of it. It returned 12 findings; 9 with one clear right answer were fixed before the gate (AC6's "≥2 spellings" incoherent against its own definition of a pattern and unmet for AC8's two, now stated per claim; `vignette:*` narrowed to one installed vignette, the harness planting `vig[1]` only; the `Rd:*` exit widened from a wrap sweep to verification in any form, the harness planting no Rd surface at all; the backtick clause attributed to measurement; AC5's "both legs non-empty" corrected to "each leg that runs", the source leg skipping rather than asserting; the exit widened to cover the README floor's identical layout gap; the wrap-form bounding sentence restored; AC5's duty widened to all patterns this milestone adds; the candidate row amended to actually carry the exits, having carried none of them). 3 went to the gate. 1 was a no-finding (proportionality).
- 2026-08-17: gate decisions on the three markers — fix the false reachability comment now rather than let it ride the candidate row, the milestone's own subject being withdrawn false claims; log the README `lme4` disclosure gap as a candidate row rather than reword the page here; and restore the unconditional installed-vignette floor rather than rename the glob-derived one, removing the coverage regression without taking back the descoped promise.
- 2026-08-17: T22 — the false reachability comment at `test-doc-skew-caveat.R:278-279` corrected against measurement (0 backticks across all seven flattened Rd pages, 846 in `R/icc.R`; under `R CMD check` the installed leg is the only leg and reads `Rd:*`, `NEWS.md`, `README.md` and the installed vignettes). The installed-vignette floor restored to the unconditional two-name list `main` carried: the glob-derived form read as a widening but was a narrowing, `.Rcheck` having no `vignettes/`, so it skipped in the one layout CI runs. Duplicated floor `stopifnot` dropped from the harness.
- 2026-08-17: T23 — mutation matrix re-run from the committed harness after a fresh `devtools::install(build_vignettes = TRUE)`: source leg 88 plants / 88 RED, installed leg 33 plants / 33 RED, both against 0-failure controls, tree restored clean. Gate: full suite FAIL 0 / ERROR 0 / WARN 3 / SKIP 2 / PASS 8221 (the known teaching warnings and dev-session skips), `air format --check` clean, `lintr::lint_package()` 0 lints, all four `data-raw` checkers OK, `cairn_validate` all checks passed (1 sizing advisory). Descope round complete; status to `review`.

## Decisions
<!-- owner: implement / review · append-only -->

### MD-1 (2026-08-16): what the amended criteria establish, and what they do not

Moved here verbatim from AC2, AC6 and AC8 when the amendment took the plan-owned
body past the 150-line cap; the criteria cite this entry rather than restate it.
The promises themselves are unchanged from the audited wording.

**AC2.** What this establishes is that the list is a complete and correct
enumeration of the non-base entries this package *declares*, labelled as such;
it does not establish that the sentence makes no further claim about what an
installation retrieves — that is AC8's, bounded to the spellings named there and
nothing wider.

**AC6 — the surface classes.** `R/*.R`, `vignettes/*.Rmd`, `NEWS.md`,
`README.Rmd` and `README.md` on the source leg; `Rd:*`, `vignette:*`, `NEWS.md`
and `README.md` on the installed leg.

**AC6 — the wrap-form gap.** The wrap-form sweep runs on the plain-text
installed surfaces (`vignette:*`, `NEWS.md`, `README.md`) only. `Rd:*` is
therefore exercised in a single wrap form. That class is also the one whose join
differs most from the others — `rd_flat()` concatenates with `collapse = ""` and
no blockquote strip runs on it — so this procedure makes no wrap-form guarantee
for `Rd:*`, and a wrap-dependent false negative there would not be caught.

**AC8 — what no criterion reaches.** No criterion here reaches a reworded
transitive claim naming fewer than three packages: AC2 fires only at three or
more names, AC8 only at the literal spellings it lists. Review is the net for one.

### MD-2 (2026-08-17): supersedes MD-1's two AC6 paragraphs

MD-1's "AC6 — the surface classes" and "AC6 — the wrap-form gap" paragraphs
were written for the pre-descope AC6, which no longer cites MD-1. The wrap-form
paragraph is also false against the committed harness: it states that `Rd:*` is
"therefore exercised in a single wrap form", where the harness plants at no Rd
surface in any form — `data-raw/m123-capability-claim-mutations.R` declares
`README.Rmd` and `R/icc.R` on the source leg and `README.md`, `NEWS.md` and one
installed vignette on the installed leg, and never runs `document()`, so a
roxygen plant never reaches Rd. Amended AC6 states its own bounds and names
`Rd:*` mutation verification in any form among what exits to the ROADMAP
candidate row. MD-1's AC2 and AC8 paragraphs stand.

**AC6 — the backtick-free spelling.** `rd_flat()` is `rapply(as.character)` over
the parsed Rd and discards `\code{}`, so a backticked-only pattern is inert on
the one class a built package's help database renders. Measured at T16 and again
here: 0 backticks across all seven flattened Rd pages, against 846 in `R/icc.R`.

**AC5/AC6 — what exits to the candidate row.** The vignette and README floor
enumeration and the layouts in which those floors must not be vacuous; whether a
comment in the pin file or the committed harness states a reachability a probe
confirms; mutation verification of the `Rd:*` class in any form; per-class
reachability reporting; and the harness plant-target cross-check. All six are
carried as (a)-(f) of the ROADMAP row "Per-class reachability proof for the
doc-claim pin", amended in the same commit as this entry.

**AC6 — the four wrap forms.** The harness declares `flat`, `wrapped`,
`blockquote` and `blockquote_indented`; the guarantee is bounded to those four.

## Review
<!-- owner: review · exclusive -->

### Attempt 1 (2026-08-16) — RETURNED to `in-progress`, defect return 1

**Criteria evidence.** AC1 met: no roadmap/not-yet/forthcoming string in
`README.Rmd`; `:42` names all four engines, matching `R/icc.R`'s validated set;
a fresh `build_readme()` left `README.md` byte-identical. AC2 met: the install
sentence's six backticked names are set-identical to `Imports:` minus base
(`cli, generics, glmmTMB, lifecycle, rlang, tibble`), by command. AC3 met: no
"never declare" string; `:110-113` names `design` and cross-references
`#incomplete-ragged-multilevel-designs`, which resolves to the heading at
`:149`. AC4 met: both records carry the AC2 set (verified whitespace-collapsed,
since the DESIGN.md list wraps); `git grep -n augment -- NAMESPACE R/` and
`-- cairn/DESIGN.md` both exit 1. AC7 met: `cairn_validate` all checks passed,
`document()` no diff, README knit in sync, `pkgdown::check_pkgdown()` clean,
`air` and `lintr` clean, four `data-raw` checkers OK, local suite FAIL 0 /
PASS 8030, full CI matrix green on 79ee887. **AC5 and AC6 not ticked** — see
F1 and F4.

**Findings** (3 reviewers: [O] diff-bug, [S] blame-history, [S] prior-review).

- **F1 — floor return. The pin does not match the sentence it exists to
  catch.** `squash()` strips `#`/`#'` but not the markdown blockquote `>`, and
  the withdrawn sentence lives in a `> [!NOTE]` block wrapping as
  `A Bayesian engine` / `> is on the roadmap`. Reproduced: the two verbatim
  pre-correction lines from `main` squash to `... A Bayesian engine > is on the
  roadmap ...`, against which **all nine patterns return FALSE**. A maintainer
  restoring that exact sentence to `README.Rmd` passes green — the precise
  scenario the added comment says the `README.Rmd` leg exists to catch. The
  27-plant matrix never exercised a blockquote wrap, so AC6's verification is
  hollow where it matters. Fix: strip `^\s*>+\s?` before the join, on both
  legs, and add the blockquote form to the mutation matrix.
- **F2 — floor return. The milestone introduces a new falsehood of the class
  it exists to withdraw.** The rewritten install sentence ends "engines live in
  `Suggests`, installed only if you ask for them". `glmmTMB` `Imports:
  lme4 (>= 1.1-18.9000)` (verified against the installed DESCRIPTION), so the
  documented install path pulls `lme4` unconditionally; the reviewer resolved
  the full closure at 60 non-base packages. AC2 holds as written — the clause
  is new prose no criterion covers, and a defect inside an intentional change
  is still a defect. Same "pulls only" framing now in `cairn/DESIGN.md:69` and
  `CLAUDE.md:65`.
- **F3 — fix now. The new anti-vacuity floor hard-fails in an unpacked source
  tarball.** `source_doc_surfaces()` gates only on `R/*.R` existing; in a
  tarball `R/` and `vignettes/` are present but `README.Rmd` is
  `.Rbuildignore`d, so `expect_true(all(c("README.Rmd","README.md") %in%
  names(surfaces)))` fails rather than skips. Reproduced in a synthetic tarball
  layout. Green on CI only because `R CMD check` runs from `.Rcheck` (no `R/`)
  and covr from a built package.
- **F4 — fix now. Verification never exercised the real installed leg.** Every
  local evidence run used `devtools::load_all()`, under which `system.file()`
  resolves to the source tree (the M116 lesson), so the installed leg re-read
  source. Running without `load_all` surfaced the stale installed copy
  immediately. Re-verify with `test_dir(..., load_package = "installed")`.
- **F5 — fix now. A forked instrument where D-029 asks for an extension.**
  M115-M119 each appended into the one `claim_patterns` vector and reused
  `expect_no_withdrawn_claim()`; this branch adds a parallel
  `capability_claim_patterns` plus a parallel `expect_no_capability_claim()`.
  The stated reason ("domain differs") does not hold — both sets sweep the same
  walk, and a numeric pattern simply would not match README prose. Merge into
  the existing vector and helper.
- **F6 — fix now. No committed mutation harness, against clear precedent.**
  `data-raw/m95-mutation-check.R`, `m117-width-pin-mutations.R` and
  `m118-dgp-fence-mutations.R` are committed and auditable; M123's 27-plant
  matrix ran from a throwaway script and leaves nothing re-runnable.
- **F7 — fix now. Two spellings guard no reachable surface, on unbacked
  rationales.** `engines_omit_brms_bare` and `install_four_bare` are justified
  by comments claiming the Rd database and the knitted README strip the markup;
  neither sentence appears in any `.Rd`, and the knitted `README.md` keeps its
  backticks. They also inflate AC6's spelling count with unreachable forms.
- **F8 — follow-up. `design_never_declare = "you never declare it"`** is four
  words of ordinary English swept over all of `R/` including internal comments;
  a future true sentence about any other inferred argument would red.
- **F9 — reject (out of scope, disclosed).** The re-knit moved four interval
  endpoints; correct, caused by the render predating M104-M119, and recorded in
  the work log. No AC covers them, which the reviewer asks be acknowledged
  rather than silently accepted — acknowledged here.
- **F10 — reject.** The AC4 record sites are unpinned by either walk. True, and
  AC5 does not require covering them; the install falsehood could return to
  `CLAUDE.md`/`cairn/DESIGN.md` uncaught. Noted for the fix round, not a defect
  in what shipped.
- **[S] prior-review lens: no regressions.** Checked against M94/M102/M106/
  M115-M119 findings and the four named lessons; the diff complies with each
  (squash-based matching, ≥2 spellings, `skip_if` outside the loop, no ROADMAP
  terminal-row rotation so `record-claims.tsv` correctly untouched). The GitHub
  inline-comment probe returned empty, so that surface was skipped.

**Disposition:** F1 and F2 qualify under the return floor — F1 as a
load-bearing defect in the milestone's central deliverable, F2 as a false
user-facing claim. Status to `in-progress`; F3-F7 ride the same fix round.

### Attempt 2 (2026-08-16) — RETURNED to `in-progress`, defect return 2

**Criteria evidence** (all fresh, by command, on `a1ad8c7`).

- **AC1 met.** `grep -nEi "roadmap|not yet|forthcoming|planned|coming soon"` over
  `README.Rmd` returns nothing; `:42` names `glmmTMB`, `lme4`, `brms`, `lavaan`,
  set-identical to the validated engine roster at `R/icc.R:689`. A second
  `build_readme()` left `README.md` byte-identical (md5 unchanged). The
  `README.Rmd` edit and the `README.md` re-knit sit in different checkpoint
  commits on the branch (`d9ab307`, `b192efd`); the squash-merge delivers both
  in one commit, which is what "the same commit" governs — recorded here rather
  than glossed.
- **AC2 met.** By command: `Imports:` minus `installed.packages(priority = "base")`
  is `cli, generics, glmmTMB, lifecycle, rlang, tibble`; the six backticked names
  in the install sentence are set-identical, in `README.Rmd` and in the knitted
  `README.md`. (The sentence's surrounding prose is a separate matter — F16, F17.)
- **AC3 met.** No "never declare" string in the vignette; `:110-113` names the
  `design` argument and cross-references `#incomplete-ragged-multilevel-designs`,
  which resolves to the heading at `:149`; the prose agrees with `@param design`
  at `R/icc.R:243-249`.
- **AC4 met.** Both records carry the AC2 six; `git grep -n augment` exits 1
  against `NAMESPACE R/` and against `cairn/DESIGN.md`. The blame lens confirmed
  via `git log --all` that no `augment` method ever existed, so this withdraws an
  unbacked claim rather than a shipped feature.
- **AC5 met.** The walk, called directly: 35 source surfaces, 9 installed;
  `README.Rmd` and `README.md` present on the source leg (5473 / 7489 chars),
  `README.md` present on the installed leg; every surface non-empty on both legs;
  **0 hits** for all nine capability patterns across both legs, so no site is
  owed a correct-as-written entry.
- **AC6 NOT ticked — fresh evidence incomplete.** The instrument half is verified:
  one `claim_patterns` vector, one `expect_no_withdrawn_claim` helper, no second
  instrument, two new `test_that()` blocks. The mutation half was not re-run this
  attempt; the [O] reviewer independently reproduced `main`'s real pre-correction
  sentences reddening on both legs for four patterns, which is one spelling per
  claim, short of AC6's "≥2 spellings". The recorded 108-plant matrix stands in
  the work log but is not fresh evidence, and F11-F13 below show it does not
  cover the leg CI actually runs.
- **AC7 met.** `cairn_validate` all checks passed (1 advisory: 13 tasks vs the
  >10 split tripwire); `air format --check` exit 0; `lintr::lint_package()` clean;
  all four `data-raw` checkers OK. Consistency gate: `document()` no diff, README
  in sync, `pkgdown::check_pkgdown()` clean, NEWS entry present,
  `devtools::check()` 0 errors / 0 warnings / **1 NOTE introduced by this branch**
  (F15).

**Findings** (3 fresh-context reviewers: [O] diff-bug, [S] blame-history,
[S] prior-review; plus two found at the gate). [S] blame-history: no regressions
— the shared blockquote strip cannot alter any interior substring an older
`fixed = TRUE` pin depends on, and `README.Rmd` is the only blockquoted surface
in the tree. [S] prior-review: no prior-review evidence of a regression, zero
findings; the GitHub inline-comment probe returned empty.

- **F11 — floor return. The fix round removed real Rd-surface coverage on a
  rationale that is false, and wrote that rationale into the file.**
  `tests/testthat/test-doc-skew-caveat.R:275-284` states that the backtick-free
  variant "guarded nothing, since no surface either walk reaches renders this
  sentence without its markup". Verified false: `rd_flat()` is
  `rapply(as.character)` over the parsed Rd, which discards `\code{}`, and the
  flattened `man/icc.Rd` contains **0 backticks** while the roxygen source at
  `R/icc.R:251` carries them. So `engines_omit_brms`, `engines_omit_brms_and`,
  `install_four_marked` and `install_four_alpha` cannot match any `Rd:*` surface
  — and under `R CMD check` the source leg returns `list()` and skips, making the
  installed leg the only leg. Four of nine patterns are inert in CI outside
  `README.md`, vignettes and NEWS. F7's repair deleted the two spellings that did
  reach Rd.
- **F12 — floor return. The "installed walk" block does not do what its comment
  says.** `:483-484` claims the block skips under `load_all` because there is no
  inst tree. Verified false: `system.file("README.md", package = "intraclass")`
  under `load_all` returns `/Users/jmgirard/github/intraclass/README.md` —
  pkgload falls back to the package root — so the block runs and re-reads the
  **source** file the source leg already swept. This is attempt 1's F4 defect
  reproduced one file over. It matters concretely because the committed harness
  runs under `pkgload::load_all`, so no cell of the 108-plant matrix ever
  exercised the real installed leg; only T13's uncommitted hand-run did.
- **F13 — fix now. The committed matrix never plants at `README.md`.** The
  harness declares three surfaces — `README.Rmd`, `R/icc.R`,
  `vignettes/multilevel-designs.Rmd` — omitting the one file that ships in the
  tarball and is the only README surface visible under `R CMD check`. With F12,
  "every planted claim reds at every surface" proves nothing about the leg CI runs.
- **F14 — fix now. The vignette carrying claim (4) has no presence floor on
  either leg.** `design_never_declare`/`_alt` live only in
  `vignettes/multilevel-designs.Rmd`; `legacy_source_paths` and the installed
  vignette floor both name `interval-methods.Rmd` and `glossary.Rmd` and not it.
  Rename or drop that vignette and pattern (4) guards nothing, green throughout.
  Related: CI's only README pin is `skip_if`-guarded with no floor, so if
  `README.md` were ever `.Rbuildignore`d both README pins vanish silently.
- **F15 — fix now. The branch introduces an `R CMD check` NOTE.** The new NEWS
  bullet is the first occurrence of "README" in `NEWS.md` (`main` has none), and
  `inst/WORDLIST` has no entry for it, so `spelling.Rout` no longer matches
  `spelling.Rout.save`. CI does not see this — `tests/spelling.R` uses
  `skip_on_cran = TRUE` — but the local consistency gate does.
- **F16 — floor return. The NEWS bullet repeats the framing F2 was returned
  for.** It reads: "it now names every non-base package the install pulls
  (`lifecycle` and `tibble` were missing)". Installing intraclass pulls `lme4`
  and its closure through `glmmTMB`, so "every non-base package the install
  pulls" is the same transitive over-claim, in a user-facing file, uncovered by
  any claim pattern.
- **F17 — floor return. The corrected README sentence is itself imprecise in
  two ways.** (i) "intraclass itself imports only `cli`, `generics`, `glmmTMB`,
  `lifecycle`, `rlang`, and `tibble`" — `DESCRIPTION`'s `Imports:` field has
  **seven** entries including `stats`; the records say "non-base Imports" and the
  user-facing sentence dropped that qualifier. (ii) "note that `glmmTMB` imports
  `lme4` itself, so that one arrives with the default engine either way" names
  one extra arrival beside the word "light", where the recursive non-base closure
  of the six is **63** packages (`tools::package_dependencies(..., recursive =
  TRUE)`), including ggplot2, dplyr, forecast and Matrix.
- **F18 — follow-up. `install_four_alpha` encodes a package set, not a
  falsehood.** If `lifecycle` or `tibble` ever leaves `Imports`, the corrected
  README sentence becomes exactly this string and the pin reds on a true
  statement while reporting a "withdrawn claim".
- **F19 — follow-up. Three hardening gaps in the committed harness.** Its
  pin-file sync check greps only four name prefixes, so a future pattern under a
  new prefix is silently never planted; its RED verdict is total suite failures
  rather than attribution to the claim pin, so an unrelated assertion firing
  would be recorded as "guarded"; and its restore path is `readLines`/`writeLines`,
  which is not byte-faithful (trailing newline, line endings, locale re-encoding
  of the em dashes these surfaces carry) and not crash-safe below the R level.
- **F20 — follow-up, carried from attempt 1.** F8 stands unaddressed and
  undisclosed by any task: `design_never_declare = "you never declare it"` is
  four words of ordinary English swept over all of `R/` including internal
  comments.
- **F21 — reject.** AC5 and AC6 were unticked while status read `review`. That is
  the correct state — attempt 1 unticked them, and ticking is review's act
  against fresh evidence, not implement's.

**Disposition:** F11, F12, F16 and F17 qualify under the return floor as
load-bearing defects in what this milestone delivers to users — the milestone
exists to stop the docs saying things the code falsifies, and the branch still
carries a false NEWS sentence, an imprecise README sentence, and two false
comments that mis-document the pin's own coverage. F11 and F12 additionally
remove or overstate coverage the pin is the deliverable for. Status to
`in-progress`; F13, F14 and F15 ride the same fix round; F18-F20 are follow-ups.

**Note for the attempt-2 fix round.** Every finding here falls *outside* the domain of the
procedure its nearest criterion names — AC2 subtracts base packages from
`Imports:` and cannot see the word "only"; AC6 requires ≥2 surfaces and cannot
see the Rd leg; no criterion reaches NEWS prose or code comments at all. The
recurring shape across both attempts is un-criterioned prose next to a verified
clause. Consider whether the repair is an acceptance-criterion amendment
(widening what the criteria bind) rather than another round of spot fixes.

### Attempt 3 (2026-08-16) — RETURNED to `in-progress`, defect return 3

**Criteria evidence** (all fresh, by command, on `ecd8dec`; the branch is level
with `origin/main`, tree clean).

- **AC1 met.** `grep -nEi "roadmap|not yet|forthcoming|planned|coming soon"` over
  `README.Rmd` returns nothing; `:42` names `glmmTMB`, `lme4`, `brms`, `lavaan`,
  set-identical to the validated roster at `R/icc.R:689`. A fresh
  `build_readme()` left `README.md` byte-identical (md5 `61fe0850…` before and
  after) with the tree clean, so the same-toolchain clause holds.
- **AC2 met.** Enumeration run in a fresh subprocess after
  `devtools::install(build_vignettes = TRUE)`, with `system.file()` verified to
  resolve into the library tree rather than the checkout: 52 surfaces, 28 after
  dropping `R/*.R`, **3 sentences** naming three or more non-base Imports
  (`README.Rmd`, source `README.md`, installed `README.md`) — a non-empty
  enumeration. Every one is set-identical to `cli, generics, glmmTMB,
  lifecycle, rlang, tibble` and every one carries `Imports` case-sensitively.
- **AC3 met.** No "never declare" string in the vignette; `:107-113` states that
  `icc()` infers the layout and names the `design` argument as the disambiguator
  on incomplete data, cross-referencing `#incomplete-ragged-multilevel-designs`
  (heading at `:149`); agrees with `@param design` at `R/icc.R:243-249`.
- **AC4 met.** `cairn/DESIGN.md:69` and `CLAUDE.md:65` both carry the AC2 six;
  `git grep -n augment` exits 1 against `NAMESPACE R/` and against
  `cairn/DESIGN.md`.
- **AC5 NOT met — F23.** The walk itself is correct (both README legs reached and
  non-empty, 0 capability hits, pin file green against the installed package:
  FAIL 0, ERROR 0, **SKIP 0**, PASS 2377, so the installed legs genuinely ran).
  But the installed-vignette floor is vacuous in the layout CI runs — see F23.
- **AC6 NOT met — F22.** The mutation half is fresh and complete: the committed
  harness ran to completion, source leg 88 plants / 88 RED, installed leg 33
  plants / 33 RED, both against 0-failure controls, tree restored. Every claim
  carries a backtick-free spelling. The criterion's comment clause fails — F22.
- **AC7 partially fresh, NOT ticked.** Fresh and clean: profile verify slot
  (FAIL 0, ERROR 0, WARN 3, SKIP 2, PASS 8221 — the known teaching warnings and
  dev-session skips), `air format --check` exit 0, `lintr::lint_package()` 0
  lints, all four `data-raw` checkers OK, `document()` no diff,
  `cairn_validate` all checks passed (1 sizing advisory: 8 criteria vs the >7
  tripwire), full CI matrix green on `ecd8dec` — all 10 checks. Not re-run this
  attempt: the `devtools::check()` differential against `main`, recorded at T18.
- **AC8 met.** Neither withdrawn phrasing survives: `grep` for "the install
  pulls" and "that one arrives" over `NEWS.md`, `README.Rmd` and `README.md`
  returns nothing. Both are pinned in the one `claim_patterns` vector
  (`install_pulls_news`, `install_arrives_readme`), and both were
  mutation-verified RED on both legs in this attempt's matrix — the README
  spelling takes the singular clause, not the true statement about what the
  default engine brings.

**Findings** (3 fresh-context reviewers: [O] diff-bug, [S] blame-history,
[S] prior-review). [S] blame-history: **no regressions** — the blockquote strip
is a no-op on every other pinned surface (`README.Rmd`'s callout is the tree's
only blockquoted line), the README endpoint drift is a stale-render fix with no
oracle pin disturbed, and the `augment` deletion is accurate. [S] prior-review:
**no prior-review evidence of a regression, zero findings**; the GitHub
inline-comment probe returned empty, so that surface was skipped.

- **F22 — floor return. A false reachability comment in the pin file, which AC6
  forbids by name.** `tests/testthat/test-doc-skew-caveat.R:278-279` reads
  "under `R CMD check` the source leg returns `list()`, making `Rd:*` the only
  class that runs." Verified false: the installed library tree carries
  `NEWS.md`, `README.md` and 8 `doc/*.Rmd`, so under `R CMD check` the installed
  leg reads four classes, not one. The file contradicts itself 210 lines later
  at `:512`. This is return 2's F11 in a new mechanism — a false claim about the
  pin's own coverage, written into the file, for the third attempt running.
- **F23 — floor return. The new glob-derived vignette floor is vacuous in the
  layout CI runs.** `:443-464` now enumerates from
  `list.files(test_path("..","..","vignettes"))` and `skip_if`s when that is
  empty. Under `R CMD check` `test_path("..","..")` is `<pkg>.Rcheck`, which
  carries no `vignettes/` — the same fact `source_doc_surfaces()`'s own gate
  rests on — so the whole `test_that` skips. `main` asserted two vignette names
  there unconditionally, so this is a coverage regression, and the block's
  comment claims it widens the floor. AC5 requires each assertion gated on *that
  file* existing; the installed vignettes do exist under check, and the gate is
  on a different file. Third instance of the layout-blindness class (return 1
  F3, return 2 F13).
- **F24 — fix now. The README no longer discloses that `lme4` arrives
  regardless, while the internal records still do.** `README.Rmd:58-59` says the
  alternate engines "are in `Suggests`, so intraclass does not require them";
  `glmmTMB` `Imports: lme4 (>= 1.1-18.9000)`, so an install retrieves `lme4`
  unconditionally. T15 withdrew the clause that disclosed this and did not
  replace it, leaving `cairn/DESIGN.md:70-72` and `CLAUDE.md:65-67` more accurate
  than the user-facing page. The following closure sentence mitigates but does
  not name `lme4`. A replacement must not restore the pinned spelling verbatim.
- **F25 — reject (criterion's own domain boundary).** AC2's "sentence" unit is
  not a sentence: `width_split()` splits on `(?<=[.!?]) `, and the README install
  section has no such boundary before the list, so the matched unit is a blob
  spanning a heading, a code chunk and two paragraphs — the `Imports` token could
  in principle come from a different paragraph. AC2 names `width_split()` as the
  cutter, so the procedure that ran is the procedure the criterion specifies.
  Recorded as a follow-up rather than a defect.
- **F26 — fix now.** `data-raw/m123-capability-claim-mutations.R:277-286`
  duplicates its source-leg floor `stopifnot` verbatim — dead code in a harness
  whose value is auditability.
- **F27 — fix now.** `:443`'s test name still reads "the installed surfaces
  include both vignettes" while the block now enumerates all eight; the name is
  what a failure report prints.
- **F28 — follow-up, carried from F19.** `run_pins()` still returns total suite
  failures rather than attribution to the claim pin, and this branch widened the
  bite: the `install_four_*` plants now trip the new AC2 test as well, so two
  spellings have a second independent path to RED.
- **F29 — follow-up.** `vignettes/multilevel-designs.Rmd` — the sole home of
  claim (4) — is planted on neither leg (the installed leg plants `vig[1]`,
  alphabetically `choosing-an-icc.Rmd`). Within AC6-as-narrowed's ≥2 surfaces,
  but F14's underlying concern is answered only by the floor F23 shows vacuous.
- **F30 — follow-up.** The installed leg runs one wrap form where the harness
  declares four; MD-1 discloses a wrap-form gap for `Rd:*` only.
- **F31 — reject (out of scope).** `cairn/PRINCIPLES.md:54` and
  `CLAUDE_CODE_KICKOFF.md:47,80` still list `augment` among the tidy generics.
  Both are worded aspirationally ("where sensible") and neither is in AC4's set.

**Disposition:** F22 and F23 qualify under the return floor — each demonstrates
an acceptance criterion failing inside the domain of the procedure it names
(AC6's comment clause; AC5's floor-gating clause). Status to `in-progress`.
F24, F26 and F27 would ride a fix round; F25 and F28-F31 are follow-ups.

**Thrash rule fires, both triggers.** This is defect return 3, so trigger (a)
holds: no further retry is queued under the current plan, and the disposition
goes to the maintainer. Trigger (b) also fires on **AC6**, which has now failed
twice, each time by a new mechanism of the same shape — a false statement about
the pin's own reachability written into the pin file (return 2 F11, return 3
F22). The work log already records a **split** spent on this milestone at the
sizing gate, so a same-objective re-cut leaves the menu; descope-or-park is the
recommended disposition, with `/milestone-brief` escalation offered per instance.
