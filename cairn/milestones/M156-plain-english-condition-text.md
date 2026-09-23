<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M156: Plain-English pass over the condition text, and NEWS under R7/R8

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Resolves:** —
- **Surface tier:** user-facing — users read these errors, warnings, install prompts and release notes
- **Branch/PR:** m156-plain-english-condition-text

## Goal

Bring the text of every condition the package raises, and `NEWS.md`, under the house prose rules of `cairn/doctrine/prose-style.md`.

## Scope

**In:** The message text of every call in `R/*.R` to the eleven condition functions. These are `abort_intraclass`, `abort_unsupported`, `abort_unidentified`, `abort_inapplicable`, `abort_fixed_agr_projection`, `warn_intraclass`, `warn_fixed_raters`, `warn_dropped_rows`, `cli::cli_abort`, `cli::cli_warn` and `cli::cli_inform`. A `getParseData()` parse on 2026-09-23 found 173 such sites in 14 files. Also in: the `reason` of every `rlang::check_installed()` call, and the method-hint bullets that `R/boundary-hint.R` builds. The pass applies R1–R6 and R8 to that text. It updates the tests and vignette prose that quote or describe the text. It applies R7 and R8 to all of `NEWS.md`, which absorbs the NEWS candidate row. It adds a new hand-run ruler, `data-raw/condition-text-profile.R`, and rewrites the doctrine's scope paragraph.

**Out:** The `choose_icc()` walkthrough and the `summary()` and `print()` notes are printed output, not conditions. They go to a new candidate row. R7 does not apply to condition text, because a message is read alone and has no file in which a first use occurs. The doctrine records this reason. Out also: any change to which condition fires, its class or its fields. Hardening `prose-profile.py` stays in the "Three prose-apparatus deferrals" row (b).

## Acceptance criteria

- [ ] AC1: For every call the parse of `R/*.R` finds to the eleven condition functions or to `rlang::check_installed()`, the message text (the string literals reaching its message argument, or its `reason` for `check_installed()`, with helper functions defined in `R/` resolved), and every bullet the hint builders in `R/boundary-hint.R` emit over every branch they take, interpolated values held as placeholders, as `Rscript data-raw/condition-text-profile.R` assembles them, contain no dash used as punctuation (R1) and no sentence over 25 words (R2), one `{…}` markup span counting as one word and a `\\` line continuation as a space.
- [ ] AC2: The same assembled text, swept with the seven `grep -E` markers R8 of `cairn/doctrine/prose-style.md` lists, shows no hit.
- [ ] AC3: Each reworded message and hint states the same claim as the text it replaced, never wider or narrower (R6's rule line), judged per hunk of `git diff main -- R/`; and the prose beside each rendered condition in the built articles (found by searching `docs/articles/*.html` output blocks for `Error` and `Warning` lines after `pkgdown::build_site()`) and in `README.md` still describes the condition it sits beside.
- [ ] AC4: The pass changes what conditions say, never which conditions fire or how: the `utils::getParseData()` token stream of each `R/*.R` file differs from `main`'s only in the string-literal tokens AC1 assembles, the tokens joining them into a message (commas, parentheses, `c`, `paste0`, `paste`, cli bullet names) and `if`/`else` tokens whose condition expression is unchanged; the `{…}` expressions inside each literal are unchanged; and `test-boundary-abort-hint.R`, `test-reducer-abort-hint.R` and `test-abort-remedy-truthfulness.R` pass with each test's asserted set of named methods unchanged.
- [ ] AC5: `cairn/doctrine/prose-style.md` names condition text as a governed surface under R1–R6 and R8, states why R7 does not apply to it, names the `condition-text-profile.R` procedure, no longer says it does not reach `cli` condition text, and stays within its stated budget (< 120 lines, < 8,000 bytes by `wc -l -c`).
- [ ] AC6: In `NEWS.md`, each glossary term's first prose use carries its gloss verbatim, as `python3 data-raw/prose-terms.py NEWS.md` reports with `grep -n 'glossary.html' NEWS.md` finding no link (R7); the R8 markers find no hit; and per hunk of `git diff main -- NEWS.md` no claim widens or narrows (R6).
- [ ] AC7: `NEWS.md` carries one Documentation bullet saying the messages were reworded and nothing computed changed; `devtools::test()` reports 0 failures and 0 warnings, `R CMD check`'s Status line reads OK, and `air format --check .` and `lintr::lint_package()` are clean.

## Coverage

- AC1 → T1, T3, T4, T5, T6, T8
- AC2 → T1, T8
- AC3 → T3, T4, T5, T6, T8
- AC4 → T1, T6, T8
- AC5 → T2
- AC6 → T7
- AC7 → T7, T9

## Tasks

- [x] T1: Write `data-raw/condition-text-profile.R`, a hand-run ruler that CI does not run (D-021). It finds the call sites with `getParseData()` and assembles each message and each `boundary-hint.R` bullet branch. It counts R1 and R2, sweeps R8, and with `--verbose` prints each offender with file:line. Its `--self-test` plants a spaced dash and a 26-word sentence and sees both fail. Its `--compare-tokens <ref>` reports the AC4 token and `{…}` differences against a ref read by `git show`, never by a checkout. Record the baseline in the work log. The ruler stays frozen for the pass.
- [x] T2: Rewrite the scope paragraph of `cairn/doctrine/prose-style.md` (lines 13–16). Add the condition-text surface, its R7 reason and its ruler. Compress other text so the file stays under its budget.
- [x] T3: Reword the messages in `R/icc.R` (82 sites). Update each test that quotes them in the same commit.
- [x] T4: Reword the messages and `check_installed()` reasons in `R/engine-*.R`, `merderiv_reason()` included. Update their tests.
- [x] T5: Reword the messages in `R/abort.R`, `R/choose-icc.R`, `R/ci-*.R`, `R/d-study.R`, `R/design.R` and `R/autoplot*.R`. Update their tests and `tests/testthat/_snaps/`.
- [x] T6: Reword the hint bullets in `R/boundary-hint.R`, and split sentences only inside the existing branches. Re-freeze the `ac5_expected` and `lead` pins in `test-reducer-abort-hint.R` at the new text, and update their "frozen at" comments. Re-read each absence assertion in `test-abort-remedy-truthfulness.R` (lines 115, 173–174, 201) against the new wording, so that the excluded claim stays absent in any words.
- [x] T7: In `NEWS.md`, gloss each first-use glossary term verbatim, clear the R8 markers and add the Documentation bullet. Run `test-news-brms-claims.R` and `python3 data-raw/check-mpl-doc-claims.py --self-test`, and re-key any ledger row the edit makes stale.
- [ ] T8: Read the whole extract for R3–R5. Audit every hunk of `git diff main -- R/ NEWS.md` for R6. Build the site and check the prose beside each rendered condition. Run the ruler and `--compare-tokens main` until both report zero.
- [ ] T9: Gate: `air format .`, `devtools::document()`, `devtools::test()`, `devtools::check()` with its raw Status line read, `lintr::lint_package()`, and every `data-raw/check-*.py --self-test`.

## Work log

- 2026-09-23: created by /milestone-plan. The user chose to promote two candidate rows: the `cli` abort-and-hint prose pass, and `NEWS.md` under R7/R8. The NEWS row's own trigger also fires, because this milestone edits NEWS.
- 2026-09-23: criteria audit in full mode, by a fresh [O] reader over two rounds. Round 1 returned 12 findings. 8 were fixed in the draft, 3 went to the gate, and 1 is the ruler choice below. Round 2 returned 6. 5 were fixed (hint branches, rendered-condition search, unchanged `if`/`else`, `{…}` guard, verbatim NEWS gloss). The whole-file NEWS scope stands on the gate answer.
- 2026-09-23: plan gate chose conditions plus `check_installed()` reasons over also covering the printed `choose_icc()` and `summary()` text, because that text is not a condition and would push the milestone past its split limits. Falsified by a reader who finds the printed guidance harder to follow than the reworded conditions.
- 2026-09-23: plan chose a new R ruler over a condition-text mode in `prose-profile.py`, because assembling the hint bullets needs R to run the builders. D-029's extend-first note was about M116's test. Falsified by a Python mode that reaches the same assembled text.
- 2026-09-23: implement gate skipped, nothing left open by the plan.
- 2026-09-23: T1 done. `data-raw/condition-text-profile.R` written, `--self-test` OK (planted 26-word sentence, em dash via assignment, spaced `--` via `paste0`, R8 marker, bullet split folds, class and glue changes caught). Baseline: sites 208, lines 437, sentences 455, R1 dashes 12, R2 over 25 words 45, R8 0; 7 sites leave only `hint` unresolved, which the 23 enumerated bullets cover; largest variant count per site 2. `--compare-tokens main` 0 differences over 24 files.
- 2026-09-23: T2 done. The doctrine scope paragraph now names condition text, its ruler and the R7 reason; 118 lines, 7,036 bytes by `wc -l -c`, so no other compression was needed.
- 2026-09-23: T3 done. `R/icc.R`: the 11 ruler offenders and 22 semicolon joins split into sentences, no claim changed. Pins updated: `test-n-o-disposition-grid.R` fixed-rater bullet; `engines.Rmd` pasted warning; the custom-prior warning field of `bayesian-vignette-oracle.rds` re-captured by running the generator's own capture block (it unwinds before any Stan fit), other fields untouched. Full suite before the fixture refresh: FAIL 1 (that transcript) / WARN 0 / SKIP 2; the affected files pass after it.
- 2026-09-23: T4 done. `merderiv_reason()` split in two sentences (its `test-icc-lme4-engine.R` pin updated); the seven identical lme4 singular-fit hints split, the parenthetical reason becoming a colon clause; the brms convergence hint's semicolon became a sentence. Ruler: no engine offender left; `--compare-tokens main` 0 differences; lme4/brms/engine tests pass.
- 2026-09-23: T5 done. `R/abort.R`, `R/ci-*.R`, `R/d-study.R`, `R/design.R`: 3 dashes, 3 long sentences and 16 semicolon joins split; `R/choose-icc.R` and `R/autoplot*.R` had no offender. `ac5_expected` npbootstrap pin moved in step (its comment is T6). Ruler fix, before any count moved: `glue_exprs()` compared names that carry the literal text, so `--compare-tokens main` reported 3 false differences on reworded files; now unnamed, with a self-test case, and it reports 0. R1/R2 counting unchanged, so the baseline stands. Full suite FAIL 0 / WARN 0 / SKIP 2.
- 2026-09-23: T6 done. `R/boundary-hint.R`: each bullet now opens "was run on your data and returns an interval where X cannot.", names its method in a second sentence ("It is" / "One is" … "The other is", via the `collapse` literal), and splits the seed tail; the burch blurb's `-- but measured to under-cover` became its own "But it was measured…" sentence. All 23 enumerated bullets: 0 dashes, 0 over 25 words; `--compare-tokens main` 0 differences. Tests: `ac5_expected` comment re-frozen (the npbootstrap bullet moved in T5; the `lead` pins are unchanged, so their 703fc1b comment stays true); "both run under your" pin became "Both were run under your". Absence assertions in `test-abort-remedy-truthfulness.R` (115, 173–174, 201) re-read: they exclude the method name `montecarlo` and "variance is exactly zero", and no reworded text states either. The three hint test files pass.
- 2026-09-23: T7 done. `NEWS.md`: the 13 terms `prose-terms.py` reported unglossed now carry their verbatim gloss at first use (0 failures), no `glossary.html` link, R8 sweep empty. Where a title carried the first use, a short glossing sentence now precedes it; the `icc()` family sentence and the brms bullet split so that each gloss fits, keeping the `test-news-brms-claims.R` pins in order. New top Documentation bullet for the reworded messages. Ruler at `--limit 25`: 15 over on `main`, 13 now, none added. `check-mpl-doc-claims.py` OK (64 candidates, 0 failures) and its self-test OK; `news-brms`, `doc-skew`, `vignette-claims` tests pass on a fresh install.
