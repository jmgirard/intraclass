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
- [x] AC2: the README's base-install sentence names exactly the **non-base**
      packages in `DESCRIPTION`'s `Imports:` field, verified by a recorded
      command that reads both and subtracts
      `rownames(installed.packages(priority = "base"))` — today
      `cli`, `generics`, `glmmTMB`, `lifecycle`, `rlang`, `tibble`.
- [x] AC3: `vignettes/multilevel-designs.Rmd` no longer claims the design is
      never declared; it states inference-by-default and names `design =` as
      the disambiguator on incomplete data, agreeing with the `@param design`
      roxygen at `R/icc.R:243-249` and with the vignette's own `:198`.
- [x] AC4: `cairn/DESIGN.md:69` and `CLAUDE.md:65` carry the AC2 install set,
      and `cairn/DESIGN.md:72` no longer lists `augment` among the shipped tidy
      S3 methods (`git grep -n augment -- NAMESPACE R/` returns nothing).
- [ ] AC5: `source_doc_surfaces()` gains `README.Rmd` and `README.md`, and
      `installed_doc_surfaces()` gains `system.file("README.md")`; every site
      the extended walk reports for the AC1–AC4 claim patterns is corrected or
      recorded in the work log as correct-as-written, with an anti-vacuity
      floor asserting both legs are non-empty.
- [ ] AC6: each claim pattern is added to that file's existing `claim_patterns`
      machinery as new `test_that()` blocks — no second instrument (D-029) —
      and each is mutation-verified red on **≥2 spellings, one of them
      line-wrapped, at ≥2 distinct surfaces** (M115's wrapped-sentence false
      negative; M118's four-spellings lesson).
- [x] AC7: `cairn/PROFILE.md`'s verify slot clean, plus
      `air format --check`, `lintr::lint_package()`, and all four `data-raw`
      checkers (`check-references`'s set) run locally before push.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T5
- AC2 → T2, T5
- AC3 → T3
- AC4 → T4
- AC5 → T6
- AC6 → T7
- AC7 → T8

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Rewrite `README.Rmd:42` and `:45-46` — engine enumeration gains
      `brms`; the roadmap sentence is withdrawn (brms ships:
      `R/engine-brms.R`, `R/icc.R:689`, `ci_method = "posterior"`).
- [x] T2: Rewrite `README.Rmd:57`'s install list to AC2's non-base set; record
      the comparing command and its output in the work log.
- [x] T3: Rewrite `vignettes/multilevel-designs.Rmd:110-111` against
      `R/icc.R:243-249`.
- [x] T4: Correct `cairn/DESIGN.md:69,72` and `CLAUDE.md:65`.
- [x] T5: `devtools::build_readme()`; confirm the re-knit is byte-identical on
      a second run.
- [x] T6: Extend both walk legs in `test-doc-skew-caveat.R` with the README
      surfaces; add the anti-vacuity floor; run the walk and log every hit.
- [x] T7: Add the claim patterns and their `test_that()` blocks; run the
      mutation matrix (≥2 spellings × ≥2 surfaces per pattern) and record the
      red/green table.
- [x] T8: Full gate — profile verify, `air`, `lintr`, the four `data-raw`
      checkers; open the PR and drive CI green.
- [x] T9: F1/F5/F7 — strip the markdown blockquote marker per line on both walk
      legs before the join; merge the capability spellings into the existing
      `claim_patterns`/`expect_no_withdrawn_claim`; replace the two unreachable
      bare-markup spellings with reachable re-edits.
- [x] T10: F3 — make the README anti-vacuity floor tarball-safe: assert per file
      against what is on disk, requiring at least one README leg.
- [x] T11: F2 — withdraw the "installed only if you ask for them" clause from
      `README.Rmd`, `cairn/DESIGN.md` and `CLAUDE.md`; re-knit `README.md`.
- [x] T12: F6 — commit `data-raw/m123-capability-claim-mutations.R` and run the
      full matrix (spellings × surfaces × wrap forms) to a clean floor.
- [x] T13: F4 — re-verify both walk legs against the INSTALLED package, not
      `load_all`; full gate; drive CI green.

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

## Decisions
<!-- owner: implement / review · append-only -->

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
