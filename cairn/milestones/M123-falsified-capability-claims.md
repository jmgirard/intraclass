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

- [ ] AC1: `README.Rmd` states no Bayesian engine as unshipped or forthcoming,
      and its engine enumeration names `brms` beside `glmmTMB`, `lme4` and
      `lavaan` (GP4's closed roster). `README.md` is re-knitted from it in the
      same commit; re-knitting on the same toolchain leaves `README.md`
      byte-identical.
- [ ] AC2: the README's base-install sentence names exactly the **non-base**
      packages in `DESCRIPTION`'s `Imports:` field, verified by a recorded
      command that reads both and subtracts
      `rownames(installed.packages(priority = "base"))` — today
      `cli`, `generics`, `glmmTMB`, `lifecycle`, `rlang`, `tibble`.
- [ ] AC3: `vignettes/multilevel-designs.Rmd` no longer claims the design is
      never declared; it states inference-by-default and names `design =` as
      the disambiguator on incomplete data, agreeing with the `@param design`
      roxygen at `R/icc.R:243-249` and with the vignette's own `:198`.
- [ ] AC4: `cairn/DESIGN.md:69` and `CLAUDE.md:65` carry the AC2 install set,
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
- [ ] AC7: `cairn/PROFILE.md`'s verify slot clean, plus
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

## Decisions
<!-- owner: implement / review · append-only -->

## Review
<!-- owner: review · exclusive -->
