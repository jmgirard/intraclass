# M135: Vignette prose pass — the method articles

- **Status:** review
- **Priority:** normal
- **Depends on:** M134
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m135-vignette-prose-method-articles` / https://github.com/jmgirard/intraclass/pull/144

## Goal

Apply M134's style rules to the five method articles, the ones whose prose is
watched by five separate guards, without moving any pinned claim.

## Scope

Surface tier: **user-facing** — published articles; D-029 carve-out, as M134.

**In:** `vignettes/engines.Rmd`, `vignettes/comparison-with-other-packages.Rmd`,
`vignettes/d-studies-and-replicates.Rmd`, `vignettes/multilevel-designs.Rmd`,
`vignettes/interval-methods.Rmd`, rewritten against rules R1–R6 of
`cairn/doctrine/prose-style.md` (M134).

Baseline at `9eae24d`, measured with the `data-raw/prose-profile.py` that M134
shipped: these five hold 386 sentences, 61 over 35 words, 160 dash occurrences.
`interval-methods.Rmd` is the worst file in the package (119 sentences, 22 over
35 words, 45 dashes) and the only one fenced by four guards:
`tests/testthat/test-vignette-claims.R`, `test-vignette-transcripts.R` (M129
engine transcripts), `test-doc-skew-caveat.R`, `data-raw/check-mpl-doc-claims.py`
(`VIGNETTE = "vignettes/interval-methods.Rmd"`, `check-mpl-doc-claims.py:46`) and
`data-raw/m117-width-pin-mutations.R:330`.

**Out:** the style standard itself → M134 owns it, this milestone only applies
it. Roxygen and `README.Rmd` → M136. Numeric targets for R4/R5 → not gated
(M134 Scope). Any change to what a pinned claim asserts → refused here; a claim
found wrong goes to `/hotfix` or its own milestone, never into a style edit.

## Acceptance criteria

- [x] AC1 `python3 data-raw/prose-profile.py '<file>' --verbose` run against each
      of the five files named in Scope reports a nonzero sentence count and 0
      dash-as-punctuation occurrences. For `interval-methods.Rmd` it reports at
      most one sentence over 35 words; if one is reported, `--verbose` shows it
      is the sentence carrying the clause `residual_template()` in
      `tests/testthat/test-doc-skew-caveat.R` requires verbatim, which admits no
      sentence break because the test matches it with `fixed = TRUE` and the
      clause begins lower-case with no internal sentence end. For the other four
      it reports 0 sentences over 35 words.
- [ ] AC2 In the scope-word census over `git diff -U0 9eae24d...HEAD --
      vignettes/` — case-insensitive whole-word matching of `any`, `each`,
      `every`, `all`, `only`, `both`, `exactly`, `never`, `always` and `full`
      (`grep -iE '\b(any|each|every|all|only|both|exactly|never|always|full)\b'`)
      over the diff's added and removed content lines, a hunk being selected
      when the census matches at least one of its added or removed lines — the
      census selects at least one hunk, and in every hunk it selects, the added
      text states a claim whose domain is equal to or narrower than the removed
      text it replaced; a selected hunk with no removed lines has no replaced
      text, and the criterion certifies nothing about it. The census decides
      nothing about a claim-domain change carrying none of those ten words;
      such a change is outside what this criterion certifies.
- [x] AC3 `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live mode
      against the edited `interval-methods.Rmd`, and every
      `data-raw/mpl-doc-claims.tsv` row whose key changes carries the edited
      quote verbatim with its `assertion` and `disposition` columns unchanged,
      in the same commit as the prose edit.
- [x] AC4 `Rscript data-raw/m117-width-pin-mutations.R` exits 0 against the
      edited `interval-methods.Rmd`.
- [x] AC5 `devtools::test()` clean (including `test-vignette-claims.R`,
      `test-vignette-transcripts.R`, `test-doc-skew-caveat.R`);
      `devtools::check()` raw `Status:` line 0 errors / 0 warnings (NOTEs
      justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T2, T3, T4, T5
- AC2 → T6
- AC3 → T5, T7
- AC4 → T5, T7
- AC5 → T8

## Tasks

- [x] T1 Rewrite `vignettes/engines.Rmd` against R1–R6.
- [x] T2 Rewrite `vignettes/comparison-with-other-packages.Rmd` against R1–R6.
- [x] T3 Rewrite `vignettes/d-studies-and-replicates.Rmd` against R1–R6.
- [x] T4 Rewrite `vignettes/multilevel-designs.Rmd` against R1–R6.
- [x] T5 Rewrite `vignettes/interval-methods.Rmd` against R1–R6, holding every
      sentence the four guards quote byte-stable unless T7 re-keys it. Record
      each exempted sentence's word count and its pinned clause's in the work
      log, per the R1/R2 exemption in `cairn/doctrine/prose-style.md`.
- [x] T6 Run the AC2 census over the `vignettes/` diff and repair any widening
      it selects. Then read every prose hunk in that diff in context for
      claim-domain widening the census cannot see — scope carried by words
      outside the ten (`no`, `some`), or a dropped qualifier — and record what
      was read and repaired in the work log.
- [x] T7 Re-key `data-raw/mpl-doc-claims.tsv` for every quote T5 edited, keeping
      `assertion` and `disposition` unchanged; run both `interval-methods`
      guards live before the commit that carries the prose edit.
- [x] T8 Run the AC5 verify block.

## Work log

- 2026-08-24: return 1 complete, status back to `review`. T8 verify block re-run whole: `devtools::test()` FAIL 0 / WARN 3 (expected) / SKIP 2 / PASS 8861; `devtools::check()` `Status: 1 NOTE`, 0 errors, 0 warnings, 16m 37s, the NOTE being the testthat suite's 28m elapsed against a 16m threshold (D-011), with vignette re-building OK; `devtools::document()` no diff; `air format .` no diff; `python3 data-raw/check-record-claims.py` 6 claims re-derived, 0 failures; `cairn_validate.py` all 16 checks PASS, 7 advisories OK.
- 2026-08-24: the `tests/spelling.Rout.save` mismatch from the first pass still reproduces and is still pre-existing — 31 flagged words, every one a proper noun, a British spelling or package jargon out of `icc.Rd`, `NEWS.md`, `glossary.Rmd` and `interval-methods.Rmd`, none introduced by this return's edits. No error, warning or NOTE comes of it.
- 2026-08-24: AC1, AC3, AC4 and AC5 stay ticked from the first review pass, but the branch has moved since that evidence was taken — re-review takes fresh evidence for all five, AC2 being the amended one and unticked.
- 2026-08-24: T6 re-run under the amended AC2 — the census over `git diff -U0 9eae24d...HEAD -- vignettes/` selects 56 of 138 hunks and none of them is a pure insertion; every selected hunk read in context, no widening inside the census's own domain.
- 2026-08-24: T6 read-through leg (the criteria audit's seventh finding) — all 52 hunks of the normal-context `vignettes/` diff read in context by a fresh [O] reader that authored none of the prose. Four widenings the ten words cannot see, repaired: the resampling-noise clause at `interval-methods.Rmd:65` re-bracketed to the multilevel designs alone; the level-median claim at `:184` given back its "On the larger grid" restriction, which is the grid `argmax_cut` computes its medians on; the engines 0.284/0.290 explanation re-scoped to "here" with the carries-noise hedge kept; the Design 2 bullet's conclusion tied back to its premise. Three reported findings rejected: the "ten Hove" citation sits where the base text put it, "does not abort at the near-zero-ICC boundary" is scoped by that boundary, and the capability-matrix cells are the maintainer call already taken above.
- 2026-08-24: amendment return: AC2 — "In the scope-word census over `git diff -U0 9eae24d...HEAD -- vignettes/` — case-insensitive whole-word matching of `any`, `each`, `every`, `all`, `only`, `both`, `exactly`, `never`, `always` and `full` (`grep -iE '\b(any|each|every|all|only|both|exactly|never|always|full)\b'`) over the diff's added and removed content lines, a hunk being selected when the census matches at least one of its added or removed lines — the census selects at least one hunk, and in every hunk it selects, the added text states a claim whose domain is equal to or narrower than the removed text it replaced; a selected hunk with no removed lines has no replaced text, and the criterion certifies nothing about it. The census decides nothing about a claim-domain change carrying none of those ten words; such a change is outside what this criterion certifies." — user-selected at the mini gate; the promise narrows to what the census settles, a wider word list being inadmissible.
- 2026-08-24: criteria audit of the amended AC2 ran in FULL mode (user-facing tier) via a fresh-context [O] reader that authored none of it. Seven findings with one clear right answer each, all applied: substring matching admitted 105 added lines against whole-word matching's 76 (`small-sample`, `Reach`, `parallel`), so the regex is spelled out; a unified diff pairs hunks not lines and this prose rewraps, so the universal moved onto hunks; the anti-vacuity floor counted lines the universal did not range over, so it moved onto hunks too; the removed-line leg was inert until the hunk repair made it live; pure-insertion hunks had an undefined predicate, now given a stated verdict; `-U0` pinned because hunk boundaries depend on the context setting; `<base>` replaced by the literal `9eae24d`. The seventh finding — the widening class the ten words cannot see has no home — went to T6 rather than into the promise. Reachability, probe, instrument and proportionality questions returned nothing.
- 2026-08-24: T6 amended (minor) to carry the audit's seventh finding: the census run, then an in-context read of every prose hunk in the `vignettes/` diff for widening the ten words cannot see.
- 2026-08-24: review finding 7 (maintainer call, user-selected at the mini gate): the capability matrix's 11 `❌` cells, across its five rows, become the word `no`, matching the table's existing `partial` word-cells and keeping the emphasis off three named third-party packages. The `✅` marks and the zero dash count stand.
- 2026-08-24: return 1, consistency gate closed — `NEWS.md` gained a *Documentation* bullet naming the five rewritten articles, beside M134's bullet for its three.
- 2026-08-24: return 1, findings 1 and 9 — `cairn/ROADMAP.md:20`'s retention comment now names the M134 rotation and the terminal set M134/M130/M131/M132/M133, the correction marked in place; `data-raw/record-claims.tsv`'s `roadmap-terminal-rows` reason now dates the rotation 2026-08-23, the date the table rotated. `check-record-claims.py`: 6 claims re-derived, 0 failures.
- 2026-08-24: return 1, finding 2 — the MPL subsection's boundary-return, conservatism and near-vacuity claims are back inside `check-mpl-doc-claims.py`'s candidate net: the conservatism and opt-in clauses rejoined into one candidate sentence, the two reporting caveats rejoined into one, and the boundary-return clause rephrased so its sentence carries a trigger token. Ledger: two re-keys (`9613de486205`->`76fbf751b3cd`, `93240bdb40e9`->`d78ce12088ef`, quotes and `assertion`/`disposition` unchanged) and one added row (`0e83d1125bf2`, disposition `out`, settled by `test-ci-mpl.R`'s boundary test rather than the M92 cells). Checker 48 candidates (was 47), 12 settled, 0 failures; `--self-test` reds every mutation.
- 2026-08-24: return 1, findings 3, 4, 5 and 6 — the effective-occasion-divisor reason re-bracketed to the ragged occasion-averaged corner alone; "ten Hove" back to lower case at `interval-methods.Rmd` with its citation re-attached to the degrades-gracefully clause; the engines 0.284/0.290 gap back to the raw variance *carrying* noise the mixed model shrinks away; the interval-methods read-off enumeration finished with a matching second item. Ruler after: `engines` 68/0/0, `comparison` 71/0/0, `d-studies` 92/0/0, `multilevel` 127/0/0, `interval-methods` 164/1/0.
- 2026-08-24: return 1 guards re-run — `check-mpl-doc-claims.py` 0 failures, `Rscript data-raw/m117-width-pin-mutations.R` exit 0 with every prose mutation refused and the control clean, `test_local(filter = "vignette-claims|vignette-transcripts|doc-skew-caveat")` FAIL 0 / SKIP 2 / PASS 2764.
- 2026-08-24: review returned to in-progress (defect return 1). Consistency gate FAILED on the `r-package` profile's `NEWS.md` slot: five published articles rewritten, no NEWS entry, where M134 wrote one for its three. AC1-AC5 all verified green with fresh evidence. Six fix-now findings from the review fan-out (stale `cairn/ROADMAP.md:20` retention comment; three MPL claims dropped out of `check-mpl-doc-claims.py`'s candidate net; a widened reason clause in `d-studies-and-replicates.Rmd`; "Ten Hove" miscapitalized at `interval-methods.Rmd:359`; a softened hedge in `engines.Rmd`; the rotation date in the `roadmap-terminal-rows` row), one maintainer call (the capability matrix's `—`→`❌` cells), and an AC2 amendment owed. Detail in the Review section.
- 2026-08-24: review in progress (checkpoint) — PR #144 draft opened; AC1-AC4 verified with fresh evidence and ticked; `cairn_validate` exit 0; AC5 test/check run and the three review lenses still in flight. Consistency-gate check pending disposition: the profile's NEWS.md slot has no entry for this pass's five rewritten articles, where M134 wrote one for its three.
- 2026-08-24: T8 verify block — `devtools::test()` FAIL 0 / WARN 3 (expected) / SKIP 2 / PASS 8861; `devtools::check()` `Status: 1 NOTE`, the NOTE being the testthat suite's 23m elapsed time, which is what this suite costs (D-011); `devtools::document()` no diff; `python3 data-raw/check-record-claims.py` 6 claims re-derived, 0 failures.
- 2026-08-24: T8 discovered repair, outside this milestone's Scope and flagged for review: `check-record-claims.py` was already red on `main` before this branch was cut. Its `roadmap-terminal-rows` row still expected `M129\nM130\nM131\nM132\nM133` while the table reads `M134\nM130\nM131\nM132\nM133`, because M134's archive pass rotated the table without rotating the row; the row's prose was staler still, naming M128 and a 2026-08-22 rotation. Corrected in place with the correction marked, per the rule for a record proven false. It is a records edit with no runtime surface, and it sits on this branch rather than the default branch so the merge gate sees it.
- 2026-08-24: T8 open concern for review, not repaired: `R CMD check` reports a `tests/spelling.Rout.save` mismatch — the saved output expects "All Done!" and the run lists ~30 words. Every word listed comes from `icc.Rd`, `NEWS.md`, `glossary.Rmd` or wording this pass did not introduce, so the mismatch predates this branch; it produces no ERROR, WARNING or NOTE, and `Status:` is 1 NOTE.
- 2026-08-24: T5 `interval-methods.Rmd` rewritten — ruler 22 over-35 and 45 dashes down to 1/0 (165 sentences, max 78). The residue is the sentence beginning "What `"burch"` does against `"searle"` depends on what the residual is drawn from": 78 words, carrying the 58-word clause `residual_template()` pins with `fixed = TRUE` (R1/R2 exemption). The three remaining semicolons are two citation separators and one inside that same pinned family's `flat` width template.
- 2026-08-24: T5 kept the width block's three `width_templates()` clauses and the `grid_total` shape "59 of 64 cells of the larger grid" byte-stable, and added `"burch"` to two sentences so the margin statement stays one contiguous width run (`width_expected_runs` = 1); "by level medians" stayed lower-case so `argmax_cut` consumes it rather than `argmax_bare` firing. "A third grid now measures that case here" became "that residual case here" so the residual statement stays one run too.
- 2026-08-24: T5 side effect, disclosed: the width-neighbourhood claim count drops by one (123 → 122 assertions in `test-doc-skew-caveat.R`). The lost item is the `citation` shape "(2013)", which left run #3 when the sentence before the mpl heading was split; no measured figure lost coverage and the anti-vacuity floor (>= 10) holds at 106.
- 2026-08-24: T6 scope-word grep run over the added and removed lines of all five files, case-insensitively (wider than AC2's literal lower-case regex, which misses sentence-initial capitals such as "All three are optional" and "Every coefficient matches"). Every `any`/`each`/`every`/`all`/`only`/`both`/`exactly`/`never`/`always`/`full` is preserved one-for-one; no hunk widens its claim domain, so no repair was needed.
- 2026-08-24: T7 re-keyed three `data-raw/mpl-doc-claims.tsv` rows whose claim sentences changed (`e6451ef204bb`→`3fe46e9bfb3f`, `41e4c69d7afd`→`9613de486205`, `b6b220daac63`→`93240bdb40e9`), quotes verbatim and `assertion`/`disposition` untouched; `e50b57c2c557` was left alone because its sentence is byte-stable. `check-mpl-doc-claims.py`: 47 candidates, 12 settled, 0 failures — the same 47 as before the edit, so no candidate was created or lost.
- 2026-08-24: T7 discovered sub-task (minor amendment): `data-raw/m117-width-pin-mutations.R` carries the article line-anchor "of the larger grid, but how much narrower depends" twice as an insertion point for two mutations; the split moved it to "of the larger grid. How much narrower depends". Re-pointed both. It is a pointer, not a claim; the mutations insert at the same line in the same neighbourhood. Harness exit 0, every prose mutation refused, control clean.
- 2026-08-24: T5 verify — `devtools::test()`: FAIL 0, WARN 3 (expected), SKIP 2, PASS 8861.
- 2026-08-24: amendment (Substantive, AC1, user-selected at a mini gate): AC1 now allows `interval-methods.Rmd` at most one sentence over 35 words — the one carrying the clause `residual_template()` pins verbatim — and names `--verbose`, a nonzero sentence count, and "the other four"; the work-log recording moved from AC1 to T5. The other four files stay at 0/0.
- 2026-08-24: criteria audit of the amended AC1 ran in FULL mode (user-facing tier) via a fresh-context [O] reader that authored none of it. Six findings with one clear right answer each, all applied: the bare command names counts not identities (`--verbose` added); "exactly one" rejected strictly better outcomes ("at most one"); the work-log recording was a recording-act property bound as a criterion (moved to T5); "admits no sentence break" had the sentence as antecedent where only the clause qualifies (re-attached, with the `fixed = TRUE` reason); no anti-vacuity on the zeros (nonzero sentence count added); "in four of them" named no four ("the other four"). One two-sided finding — whether to keep the 58-word clause figure in the criterion — dissolved by the recording fix, which moves both figures to the work log.
- 2026-08-23: created by /milestone-plan.
- 2026-08-23: T4 `multilevel-designs.Rmd` rewritten — ruler 11 over-35 and 33 dashes down to 0/0 (127 sentences, max 34 words). Scope-word grep shows no widening; the 0.431/0.429 Design-2 figures are byte-stable. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T3 `d-studies-and-replicates.Rmd` rewritten — ruler 13 over-35 and 28 dashes down to 0/0 (92 sentences, max 33 words). Scope-word grep shows no widening. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T2 `comparison-with-other-packages.Rmd` rewritten — ruler 3 over-35 and 30 dashes down to 0/0 (71 sentences, max 33 words); the capability matrix's `—` "not provided" cells became `❌`, which the ruler does not count and which reads against the table's own `✅`. Scope-word grep (case-insensitive, wider than AC2's literal regex) shows no widening. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: T1 `engines.Rmd` rewritten — ruler 12 over-35 and 24 dashes down to 0/0 (68 sentences, max 31 words); scope-word grep over the added and removed lines shows every `every`/`only`/`full`/`exactly`/`any`/`both` preserved one-for-one. `devtools::test()`: FAIL 0, PASS 8862.
- 2026-08-23: plan-gate criteria audit ran in FULL mode; the record and its 13 findings are in M134's work log — this file's AC2/AC3 carry the F5 and F12 repairs, and its AC5 the F4 live-mode repair.
- 2026-08-23: amendment (Substantive, Scope, user-selected at the implement question gate): the Scope baseline is re-measured at `9eae24d` with the shipped ruler — 386 / 61 / 160 for the five, 119 / 22 / 45 for `interval-methods.Rmd`; the plan's 281 / 88 / 188 came from a draft ruler M134's review then changed.
- 2026-08-23: implement question gate chose to carry `interval-methods.Rmd` in this milestone rather than pre-split it; the plan's split trigger stands.
- 2026-08-23: plan gate chose to fold `interval-methods.Rmd` into this milestone over giving it its own because its four guards are re-run once for the whole file family rather than twice; falsified by T5 plus T7 overrunning a working session, which is the split's trigger.

## Decisions

## Review

PR: https://github.com/jmgirard/intraclass/pull/144 (draft). Base `main` at
`9eae24d`, unmoved since the branch was cut, so no merge-forward was needed.
Diffstat: 10 files, +391 / -356.

### Acceptance-criteria evidence

- AC1 (2026-08-24) `python3 data-raw/prose-profile.py '<file>' --verbose` run
  fresh on each of the five. `engines.Rmd` 68 sentences / 0 over 35 / 0 dashes
  (max 31); `comparison-with-other-packages.Rmd` 71 / 0 / 0 (max 33);
  `d-studies-and-replicates.Rmd` 92 / 0 / 0 (max 33); `multilevel-designs.Rmd`
  127 / 0 / 0 (max 34); `interval-methods.Rmd` 165 / 1 / 0 (max 78). Every count
  is nonzero and every dash count is 0. The one over-35 sentence in
  `interval-methods.Rmd` is the 78-word sentence `--verbose` names, at
  `vignettes/interval-methods.Rmd:217-224`; it carries verbatim the clause
  `residual_template()` builds at `tests/testthat/test-doc-skew-caveat.R:2265`,
  matched with `fixed = TRUE` at line 2360 of the same file. The clause begins
  lower-case ("the two grids that vary only ...") and holds no sentence-ending
  period, so no break inside it is available.
- AC2 (2026-08-24) Scope-word census run fresh over
  `git diff 9eae24d...HEAD -- vignettes/`, case-insensitively (wider than the
  criterion's lower-case regex). Per-file whole-file counts of the ten scope
  words are identical between base and head for four files; the one delta is
  `each` in `d-studies-and-replicates.Rmd`, 7 to 8. Read in context, that
  substitution replaces a plural list predicate ("`conf_level`, `mc_samples` and
  `seed` --- default to the fit's own") with a distributive one ("Each defaults
  to the fit's own") over the same three settings, so the domain is unchanged.
  Every remaining scope-word hunk in all five files was read in context; the
  four that restructure around a scope word (the Design 2 "subject level only"
  bullet, the Design 3 pupil-relative clause, the interval-methods "both project
  ICC(k)" sentence which keeps "and a numeric `unit` with it", and the
  multilevel consistency sentence) each preserve their domain. No widening; no
  repair needed.
- AC3 (2026-08-24) `python3 data-raw/check-mpl-doc-claims.py` exits 0 in live
  mode: 47 claim candidates, 12 settled against `data-raw/m92-interp-sweep.rds`,
  0 failures. Three `mpl-doc-claims.tsv` rows changed key
  (`e6451ef204bb`->`3fe46e9bfb3f`, `41e4c69d7afd`->`9613de486205`,
  `b6b220daac63`->`93240bdb40e9`); the tsv diff shows `disposition` (`out`) and
  `assertion` (empty) byte-identical on all three, only `reason` extended with
  the re-key note. All four vignette quotes bind verbatim in the checker's own
  normalized scope, checked by calling `vignette_scope()`/`normalize()` directly.
  The tsv edit and the prose edit ride the same commit, `8a6b18c`.
- AC4 (2026-08-24) `Rscript data-raw/m117-width-pin-mutations.R` exits 0 against
  the edited vignette: every prose mutation refused, control clean. `insert_after()`
  hard-stops on a missing anchor, so exit 0 also proves both re-pointed anchors land.
- AC5 (2026-08-24) Fresh run of the whole block. `devtools::test()`: FAIL 0,
  WARN 3, SKIP 2, PASS 8861. The three named guards re-run directly
  (`testthat::test_local(filter = "vignette-claims|vignette-transcripts|doc-skew-caveat")`):
  0 failed, 0 errors, 2764 passed, 2 skipped, both skips the
  `test-doc-skew-caveat.R` cases that need installed vignettes, which do run
  inside `check()`. `devtools::check()` raw `Status: 1 NOTE`, 0 errors,
  0 warnings, duration 13m 58s; the NOTE is the testthat suite's elapsed time
  (22m against a 13m threshold), which is what this suite costs (D-011).
  `devtools::document()` left the tree clean, so no diff.
  `python3 data-raw/check-record-claims.py` exit 0, 6 registered claims
  re-derived, 0 failures.

### Consistency gate

- `python3 cairn_validate.py` exit 0 — all 16 checks PASS, 7 advisories OK,
  `coverage complete` and `binding criteria` among the passes.
- `cairn_impact.py` skipped: `Principles touched: —`, no DESIGN.md principle
  changed.
- Toolchain slot (`cairn/PROFILE.md`, `r-package`): `document()` no diff, PASS.
  Generated files untouched, PASS. `README.Rmd`/`README.md` not in the diff,
  PASS. `pkgdown::check_pkgdown()` "No problems found", PASS. No new top-level
  files, so no `.Rbuildignore` entry owed, PASS. `devtools::check()` 0 errors /
  0 warnings, PASS.
- **`NEWS.md` entry for this milestone's user-visible changes — FAIL.** The
  milestone rewrote five published articles and `NEWS.md` carries no entry for
  the pass. M134, the sibling milestone over the same surface, wrote a
  *Documentation* bullet for its three articles (`NEWS.md:342`). The five titles
  were searched across `NEWS.md`; every hit is an older entry about a different
  change.

### Review fan-out

Surface tier is user-facing and the diff touches executable surface
(`data-raw/m117-width-pin-mutations.R`), so the full three-lens fan-out ran, each
lens fresh-context and none having authored the work.

Findings, ranked as the lenses reported them, with disposition:

1. [O]/[S] `cairn/ROADMAP.md:20`'s retention comment still reads
   `Kept: M129, M130, M131, M132, M133` while the table's terminal rows are
   M134, M130, M131, M132, M133. The comment carries the
   `[claim:roadmap-terminal-rows]` citation for the very ledger row T8
   corrected, so the correction landed in `record-claims.tsv` and left the cited
   prose false. Verified at `cairn/ROADMAP.md:20`. **Actioned — fix.**
2. [O] The prose split moved three substantive MPL claims out of
   `check-mpl-doc-claims.py`'s candidate net. Verified by enumerating the
   checker's own candidates over base and head: the count holds at 4 both sides,
   but the base candidate carrying "it is deliberately conservative -- it
   over-covers, and is wider than the Monte-Carlo interval at interior cells"
   plus the near-zero-boundary clause now keys only "That is why it is an opt-in
   and not the default.", and the base candidate carrying the near-vacuous
   caveat now keys only the equal-tailed clause. AC3 passes by construction
   because the checker only requires each candidate to carry a row. Guard
   coverage over user-facing MPL claims narrowed. **Actioned — fix.**
3. [O] `vignettes/d-studies-and-replicates.Rmd`: the reason clause "with unequal
   per-cell counts there is no single effective-occasion divisor with a validated
   oracle" was an em-dash parenthetical bracketed to the ragged
   occasion-averaged corner alone; as a following sentence it now reads as the
   reason for all three open corners. A widening AC2's word list cannot see
   ("no" is not in it). **Actioned — fix; also the trigger for the AC2
   amendment below.**
4. [O] `vignettes/interval-methods.Rmd:359` now reads "Ten Hove et al." The
   sentence split capitalized a lower-case Dutch surname particle; it is the
   only capitalized instance in the corpus against 15 lower-case ones across
   five vignettes. The same split also detached the citation from the
   "degrades gracefully near zero" clause it was evidence for, so it now reads
   as a general endorsement of the percentile default. **Actioned — fix.**
5. [O] `vignettes/engines.Rmd`: "The gap is small-sample noise in the raw
   variance of only four estimated rater means" identifies the whole 0.284 /
   0.290 gap as noise, where the base said the raw variance *carries*
   small-sample noise the mixed model shrinks away. A hedge softened.
   **Actioned — fix.**
6. [O] `vignettes/interval-methods.Rmd`: "Two things to read off. The first is
   the true ICC." The first thing read off is a pattern along the true-ICC axis,
   not the true ICC, and the paired "In the subject count ..." never gets a
   matching "The second is", leaving the enumeration half-built.
   **Actioned — fix.**
7. [O] `vignettes/comparison-with-other-packages.Rmd`: five capability-matrix
   `—` cells became `❌`, done to satisfy R1's dash count. The table carries no
   legend, so both glyphs read as "not provided" against the table's `✅`, but
   `❌` states it more emphatically about three named third-party packages.
   **Maintainer call at the gate — no defect established.**
8. [O] Three added lines exceed the files' ~85-column wrap and the
   interval-methods read-off region leaves short orphan lines.
   **Rejected — formatter/style nitpick, out-of-scope taxonomy.**
9. [O] The corrected `record-claims.tsv` row dates the rotation 2026-08-24 while
   the table rotated 2026-08-23. **Actioned — one-word fix in the same row.**
10. [O]/[S] "AC5 is unticked and the Review section has no AC5 entry."
    **Rejected — both lenses read the in-flight review state this session
    checkpointed at `e1c86f6`; not a property of the work under review.**
11. [S] prior-review lens: no prior-review regressions, zero findings. It
    located archived `## Review` findings for M124/M128/M132, M55/M126/M129,
    M106/M115/M130, M123/M132, M94, M102/M105/M132 on the touched files, and
    the `gh api .../pulls/comments` probe returned `[]`, so the GitHub surface
    was skipped.
12. The work log's `spelling.Rout.save` open concern: the mismatch reproduces,
    and the flagged word counts are identical between base and head
    (`labelling` 2/2, `relabelled` 1/1, `relabellings` 1/1, `unstratified` 1/1,
    `favouring` 1/1), so this pass introduced none of them. It produces no
    error, warning or NOTE. **Rejected — pre-existing, the diff did not
    introduce it.**

### Disposition

**Returned to `in-progress`.** The consistency gate failed on the profile's
`NEWS.md` slot, which takes step 4's exit. Finding 3 additionally shows AC2 is
falsified only outside the domain of the procedure it names — its scope-word
enumeration is fixed by author recall, not decided by a procedure over the
diff — so AC2 takes the gated criterion-amendment protocol rather than a
re-worded pass. Findings 1, 2, 4, 5, 6 and 9 are ordinary fix-now work for the
implement pass. Finding 7 goes to the maintainer.

AC1-AC5 all verified green on this branch as written; nothing here is a failure
of the prose work's measured targets.

