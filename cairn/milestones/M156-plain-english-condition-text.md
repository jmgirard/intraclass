<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M156: Plain-English pass over the condition text, and NEWS under R7/R8

- **Status:** review
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

- [x] AC1: For every call the parse of `R/*.R` finds to the eleven condition functions or to `rlang::check_installed()`, the message text (the string literals reaching its message argument, or its `reason` for `check_installed()`, with helper functions defined in `R/` resolved), and every bullet the hint builders in `R/boundary-hint.R` emit over every branch they take, interpolated values held as placeholders, as `Rscript data-raw/condition-text-profile.R` assembles them, contain no dash used as punctuation (R1) and no sentence over 25 words (R2), one `{…}` markup span counting as one word and a `\\` line continuation as a space.
- [x] AC2: The same assembled text, swept with the seven `grep -E` markers R8 of `cairn/doctrine/prose-style.md` lists, shows no hit.
- [x] AC3: Each reworded message and hint states the same claim as the text it replaced, never wider or narrower (R6's rule line), judged per hunk of `git diff main -- R/`; and the prose beside each rendered condition in the built articles (found by searching `docs/articles/*.html` output blocks for `Error` and `Warning` lines after `pkgdown::build_site()`) and in `README.md` still describes the condition it sits beside.
- [x] AC4: The pass changes what conditions say, never which conditions fire or how: the `utils::getParseData()` token stream of each `R/*.R` file differs from `main`'s only in the string-literal tokens AC1 assembles, the tokens joining them into a message (commas, parentheses, `c`, `paste0`, `paste`, cli bullet names) and `if`/`else` tokens whose condition expression is unchanged; the `{…}` expressions inside each literal are unchanged; and `test-boundary-abort-hint.R`, `test-reducer-abort-hint.R` and `test-abort-remedy-truthfulness.R` pass with each test's asserted set of named methods unchanged.
- [x] AC5: `cairn/doctrine/prose-style.md` names condition text as a governed surface under R1–R6 and R8, states why R7 does not apply to it, names the `condition-text-profile.R` procedure, no longer says it does not reach `cli` condition text, and stays within its stated budget (< 120 lines, < 8,000 bytes by `wc -l -c`).
- [x] AC6: In `NEWS.md`, each glossary term's first prose use carries its gloss verbatim, as `python3 data-raw/prose-terms.py NEWS.md` reports with `grep -n 'glossary.html' NEWS.md` finding no link (R7); the R8 markers find no hit; and per hunk of `git diff main -- NEWS.md` no claim widens or narrows (R6).
- [x] AC7: `NEWS.md` carries one Documentation bullet saying the messages were reworded and nothing computed changed; `devtools::test()` reports 0 failures and 0 warnings, `R CMD check`'s Status line reads OK, and `air format --check .` and `lintr::lint_package()` are clean.

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
- [x] T8: Read the whole extract for R3–R5. Audit every hunk of `git diff main -- R/ NEWS.md` for R6. Build the site and check the prose beside each rendered condition. Run the ruler and `--compare-tokens main` until both report zero.
- [x] T9: Gate: `air format .`, `devtools::document()`, `devtools::test()`, `devtools::check()` with its raw Status line read, `lintr::lint_package()`, and every `data-raw/check-*.py --self-test`.
- [x] T10: Apply the review's fix-now items (Review section O9, O10, O11, O12, O14, O15, O16 and B2). In the `NEWS.md` brms bullet, put the forced-method reason back on the Bayesian engine. Then re-run the ruler, `--compare-tokens main`, `prose-terms.py NEWS.md` and the affected tests.
- [x] T11: Add two candidate rows to `cairn/ROADMAP.md`, searching first. One is for the ruler blind spots (O1 to O5). The other is for the glossary glosses narrower than the package (O6, O7, O8, B1), with the NEWS bullet growth (P1).

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
- 2026-09-23: T8 done. R3–R5 read over the whole extract: no stacked leading clauses; 2 semicolons remain, both citation separators; the multi-parenthetical sentences carry short design and citation labels already present on `main`, left. R6 per hunk of `git diff main -- R/ NEWS.md`: one narrowing found and fixed (`R/design.R` lost the "or" that made the nested-design remedy an alternative; restored). Site built after a correct install: 5 package conditions render (fixed-rater warning in choosing and multilevel, disconnected-design error, fixed-rater projection error, custom-prior warning), each still described by the prose beside it; README.md renders none. The T7 NEWS tests had read a stale install (`upgrade = "never"` is not a valid `devtools::install()` value, so the install failed silently); re-run after a correct install, they pass. Ruler 0/0/0, `--compare-tokens main` 0.
- 2026-09-23: T9 done. `air format --check .` clean; `devtools::document()` no drift; `lintr::lint_package()` 0 after renaming the ruler's upper-case constants (lintr reads `data-raw/`); every `data-raw/check-*.py --self-test` OK; `check-mpl-doc-claims.py` 64/0 and `check-record-claims.py` 7/0. Full suite FAIL 0 / WARN 0 / SKIP 2; `devtools::check()` raw Status line: OK (0/0/0). NEWS-reading tests re-run on a fresh install after the claim-audit fixes: pass.
- 2026-09-23: claim audit: 105 claims read, 4 corrected — NEWS.md, data-raw/condition-text-profile.R
- 2026-09-23: claim-audit corrections: NEWS article title "Interval methods" → "Confidence-interval methods"; the D-study gloss sentence whose "each a share…" attached to the wrong noun, rewritten; the ruler header's R1 exceptions stated in full; `--compare-tokens` masked every literal, so a changed class string went unseen: it now masks only message literals (`is_message_literal()`), with self-test cases for a changed class string, a changed `grepl()` pattern and reworded `if`/`paste0` literals, and its remaining limit (a code literal inside `c()`) stated in the header. Re-run: 0 differences against `main`.
- 2026-09-23: status → review.
- 2026-09-23: review return (defect return 1): AC6 fails its R6 clause, because the `NEWS.md` brms bullet's "For that reason" now points at the credible-interval gloss (O9). The user chose return and fix at the gate and accepted the proposed dispositions. T10 and T11 were added. AC1 to AC5 and AC7 stay ticked against their evidence. Status → in-progress.
- 2026-09-23: T10 edits made, tests pending (checkpoint). O9: the brms bullet now reads "Because both come from the posterior, `ci_method = "posterior"` is forced." O10, O11, O12 and B2 were reworded in `R/icc.R` and `R/engine-brms.R`. The O14 claim now says "except between citations", and a dump shows the two remaining semicolons separate references. O15 was rewrapped. O16 added the ruler to `data-raw/README.md`, with its `--compare-tokens` limit stated. Ruler 0/0/0, `--compare-tokens main` 0, `prose-terms.py NEWS.md` clean, R8 0, NEWS over 25 words 13 (unchanged), `air` clean, record-claims 7/0, mpl-doc-claims 64/0.
- 2026-09-23: T11 done. Search-first found no overlap. Three candidate rows were added: glossary glosses narrower than the package, the `condition-text-profile.R` blind spots, and internal record IDs in the `R/d-study.R` message. The third was found during T10 and goes beyond T11's two rows. ROADMAP 55 lines, 22,653 bytes.
- 2026-09-23: claim audit: 16 claims read, 2 corrected — NEWS.md
- 2026-09-23: claim-audit corrections, re-read once by the same reader and judged true. "except between citations" became "except between references", because "(M20; ADR-030)" is not a citation. The brms reason became "Because the interval comes from the posterior draws", because the lock in `R/icc.R` rests on the credible interval, not the point estimate. `test-news-brms-claims.R` passes on a fresh install.
- 2026-09-23: T10 done. The full suite at 975c5c1 shows FAIL 0, WARN 0, SKIP 2, and `lintr` finds 0 lints. The later commit changed only NEWS, and its brms test passes. `air` is clean. Status → review.

## Review

Sync: `origin/main` = `main` = merge base (badf2a6), no merge needed. No PR exists (resume route d).

- AC1 evidence: `Rscript data-raw/condition-text-profile.R`: sites 208, lines 437, sentences 574, R1 dashes 0, R2 over 25 words 0, exit 0. The 7 unresolved sites leave only `hint`, and the 24 `(bullet)` lines in `--dump` cover the builder branches, each 0/0. `--self-test` OK. A separate `grep` for em dash, en dash and spaced `--` over the `--dump` text finds none.
- AC2 evidence: the seven R8 `grep -E` markers over the `--dump` text: no hit (exit 1). The ruler's own R8 count is 0.
- AC4 evidence: `--compare-tokens main`: 24 files, 0 differences. The ruler cannot see a code literal inside `c()`, as its header says. So a `grep` over `git diff main -U0 -- R/` looked for changed code lines. It matched `class =`, `<-`, `%in%`, `grepl`, `inherits`, `if (` and `function(`, and found none. `devtools::test()`: `test-boundary-abort-hint.R` 1331 expectations, `test-reducer-abort-hint.R` 182, `test-abort-remedy-truthfulness.R` 29, all 0 failures. `git diff main` on the three files changes only two message pins and one comment in `test-reducer-abort-hint.R`, so no asserted method set changed.
- AC5 evidence: `cairn/doctrine/prose-style.md` lines 7 to 18 name condition text under R1 to R6 and R8, give the R7 reason and name `condition-text-profile.R`. A `grep` for "reach" or "cli" finds no exclusion. `wc -l -c`: 118 lines, 7,036 bytes.
- AC7 evidence: `NEWS.md` lines 20 to 24 hold the Documentation bullet on reworded messages and unchanged computation. `devtools::test()`: FAIL 0, WARN 0, SKIP 2. `devtools::check()`: Status: OK, 0 errors, 0 warnings, 0 notes. `air format --check .` exit 0. `lintr::lint_package()` 0 lints.
- AC3 evidence: `pkgdown::build_site()` after a fresh install. Five package conditions render: the fixed-rater warning in *Choosing an ICC* and *Multilevel designs*, the disconnected-design error, the fixed-rater projection error and the custom-prior warning. The prose beside each still describes it. `README.md` renders none. The other rendered warnings are a local `TMB`/`glmmTMB` version mismatch, not package text. R6 per hunk of `git diff main -- R/`: the fresh reviewer and this review found no widened or narrowed claim. Four wording findings (O10 to O13 below) are edge cases that keep the claim, and they are triaged at the gate.
- AC6 FAILS: `prose-terms.py NEWS.md` reports every first use glossed, `grep glossary.html` finds no link, and the R8 markers find no hit. But the R6 clause fails on one hunk. In the brms bullet, "For that reason, `ci_method = "posterior"` is forced" now follows the credible-interval gloss. So the stated reason became the 95% share, not the Bayesian engine (finding O9).
- Gate: `devtools::document()` leaves no diff. `pkgdown::check_pkgdown()`: no problems. `README.Rmd` is not in the diff. `cairn_validate.py`: all checks passed. No `DESIGN.md` principle changed, so `cairn_impact.py` does not apply.

Findings. [O] is the diff reviewer, [B] the blame-history reviewer, [P] the prior-review reviewer (PR-comment probe empty). Each carries its proposed disposition for the gate.

- O9 (AC6 failure): `NEWS.md` brms bullet, "For that reason" points at the credible-interval gloss. Proposed: fix now, by moving the gloss after the forced-method sentence.
- O11: `R/icc.R` numeric-unit abort. The split lost the dash that made the pole claim the reason for the refusal. Proposed: fix now, with "because".
- O10: `R/icc.R` brms incomplete-data abort adds the count "four design families". Proposed: fix now, by dropping the count.
- O12: `R/icc.R` fixed-rater projection abort, "That term has no 'average…'" reads oddly. Proposed: fix now, as "There is no 'average…' to project to."
- B2: `R/engine-brms.R` convergence hint, the added "For reference" softens the thresholds. Proposed: fix now, by dropping the two words.
- O14: `NEWS.md` says "semicolons become full stops", but two remain as citation separators. Proposed: fix now, by narrowing the claim.
- O15: `NEWS.md` line 96 is 122 characters wide. Proposed: fix now, by rewrapping.
- O16: `data-raw/README.md` does not list the new ruler. Proposed: fix now.
- O13: `R/ci-montecarlo.R`, the replicate parenthetical became "this means". Proposed: reject, because the old text stated the same case, not an example.
- O1 to O5: ruler blind spots. `--compare-tokens` misses code literals in `c()`, `if` and `paste` branches. A self-assigned message recurses forever, and "(e.g." splits a sentence. `=` assignments go unresolved, and bullet-name changes fold away. Proposed: follow-up candidate row for ruler hardening. This pass was checked by an independent `grep` of the R diff.
- O6, O7, O8, B1: `NEWS.md` glosses copied verbatim from `data-raw/glossary-terms.tsv` are narrower than or at odds with the package (D-study counts, Monte-Carlo method, two-way, cluster level). Proposed: follow-up candidate row to revise those glossary glosses.
- P1: two `NEWS.md` bullets grew to 875 and 842 bytes, over the old 500-byte guide. Proposed: follow-up, joined to the glossary row, because the glosses caused the growth.
- O17, P2, P3: tests keep their method sets, the hint tense holds, and the `R/design.R` "or" is intact. Noted, no action.

### Re-review (2026-09-23, after T10)

Sync: `origin/main` = `main` = merge base (badf2a6), no merge needed. No PR exists (resume route d). Every criterion was re-run on HEAD fb6bee2, because T10 changed `R/icc.R`, `R/engine-brms.R` and `NEWS.md`.

- AC1 evidence (fresh): ruler sites 208, lines 437, sentences 574, R1 0, R2 0, R8 0, exit 0. `--self-test` OK. `--dump` has 24 `(bullet)` lines. A `grep` for em dash, en dash and spaced `--` over the dump finds none.
- AC2 evidence (fresh): each of the seven R8 markers over the dump: 0 hits.
- AC3 evidence (fresh): fresh install, then `pkgdown::build_site()`. The same five package conditions render, with the T10 text of the fixed-rater projection error. The prose beside each still describes it. `README.md` renders none. R6 per hunk of `git diff main -- R/`: findings R2-O1 and R2-O2 below each show a sentence split that dropped a limiting phrase. Both messages fire only in the limited case (fixed raters, and a fit with no replicates), so the claim a user reads there is unchanged. This review judges them wording fixes, not an AC3 failure, and the gate decides.
- AC4 evidence (fresh): `--compare-tokens main` 24 files, 0 differences. The [O] reviewer found no class, field, `if`-condition, glue or bullet-name change. `test-boundary-abort-hint.R` 1331, `test-reducer-abort-hint.R` 182, `test-abort-remedy-truthfulness.R` 29 expectations, 0 failures.
- AC5 evidence (fresh): the scope paragraph names condition text, the R7 reason and the ruler, and has no "does not reach" exclusion. `wc -l -c`: 118 lines, 7,036 bytes.
- AC6 evidence: `python3 data-raw/prose-terms.py NEWS.md` reports every first use glossed or linked, exit 0. `grep -c glossary.html NEWS.md` is 0. The seven R8 markers find 0 hits in `NEWS.md`. R6 per hunk: the brms bullet now gives the reason "Because the interval comes from the posterior draws", which matches the lock in `R/icc.R`. The [O] and [B] reviewers found no other claim widened or narrowed by a rewrite. The Monte-Carlo gloss (R2-O3) is verbatim glossary text that O7 already deferred.
- AC7 evidence (fresh): the Documentation bullet is at `NEWS.md` lines 20 to 25. `devtools::test()`: FAIL 0, WARN 0, SKIP 2. `devtools::check()`: raw `Status: OK`, 0 errors, 0 warnings, 0 notes. `air format --check .` exit 0. `lintr::lint_package()` 0 lints.
- Gate: `cairn_validate.py` all checks passed (one advisory: 11 tasks over the 10-task tripwire). `devtools::document()` leaves no diff. `check-mpl-doc-claims.py` 64/0, `check-record-claims.py` 7/0. No `DESIGN.md` principle changed.

Round-2 findings, most severe first within each reviewer. [B] found no new regressions and confirmed O9, O10, O11, O12, B2 and O14 against the code.

- R2-O1: `R/icc.R` fixed-rater projection abort. The O12 split leaves "There is no 'average of m freshly sampled raters' to project to." without its "so" link to the fixed-rater frame. Proposed: fix now, "So there is no…".
- R2-O2: `R/d-study.R` occasion abort. The split leaves "Pure error and the subject-by-rater interaction are confounded." without the "Without replicated ratings" condition. Proposed: fix now, "…are then confounded."
- R2-O3: `NEWS.md` Monte-Carlo gloss "built by simulating from the fitted model" reads like the parametric bootstrap. Proposed: follow-up, already in the glossary-gloss candidate row (O7).
- R2-O4: `NEWS.md` Documentation bullet. "The errors… the package raises" also covers forwarded third-party text, and "are reworded" implies every message changed. Proposed: fix now, "The package's own errors, warnings, notes and install prompts now use plainer English."
- R2-O5: `NEWS.md` "…to other rater counts, each component a share of the total variation…" reads as a fragment. Proposed: fix now, "…, and each component is a share…", keeping both glosses in the sentence.
- R2-O6: `NEWS.md` "it adds a cluster level": "it" can point to the column or to the ICC. Proposed: fix now, "the column also adds a cluster level".
- R2-O7: `R/boundary-hint.R` unseeded tail lost its "as" reason link. Proposed: fix now, "Pass the same to reproduce it, because an unseeded call draws differently…". No test pins the text.
- R2-O8: `R/icc.R` "This is because its Spearman-Brown pole…" is wordy. Proposed: reject, because the claim is right and O11 fixed it.
- R2-O9: `R/icc.R` brms abort "…the following designs so far. They are…". Proposed: reject, because one sentence runs past 25 words and "They are" names the designs.
- R2-O10: the hint bullets mix "was run" with "returns". Proposed: reject, as P2 judged in round 1.
- R2-O11: `R/icc.R` mpl abort, no comma before "use". Proposed: fix now.
- R2-O12: no class, field or condition change. Noted.
- R2-O13: `test-reducer-abort-hint.R` comment has a broken wrap, no commit, and calls an abort info line a "bullet". Proposed: fix now, rewrapped, citing b8600cb.
- R2-O14: `cairn/doctrine/prose-style.md` later sections name only `prose-profile.py` as the R1/R2 gate, and the scope rewrite dropped the pointer to `check-abort-remedy-verdicts.R`. Proposed: fix now, within the 120-line budget.
- R2-O15: the ruler's 64-variant cap is silent, and the header does not say `hint_bullets()` covers one argument set. Proposed: follow-up, added to the ruler blind-spots candidate row.
- R2-O16: `data-raw/README.md` line 77 is 93 characters, doctrine line 11 is 81, and `NEWS.md` lines 63 to 66 wrap raggedly. Proposed: fix now.
- R2-O17: tests and vignettes that quote messages are consistent. Noted.
- R2-P1: the `NEWS.md` brms bullet grew to 668 bytes at T10. Proposed: follow-up, joined to the glossary row with P1.
- R2-P2: AC3 was not re-checked after T10. Resolved by this round's site rebuild. Noted.
- R2-P3: the credible-interval gloss hard-codes "usually 95%". Proposed: follow-up, the glossary row.

Gate outcome (2026-09-23): the user chose "Fix, then merge" and accepted the proposed dispositions. Fixed: R2-O1, R2-O2, R2-O4, R2-O5, R2-O6, R2-O11, R2-O13, R2-O14 and R2-O16. The doctrine is now 119 lines and 7,133 bytes. Follow-up: R2-O3, R2-P1 and R2-P3 extend the glossary-gloss candidate row, and R2-O15 extends the ruler blind-spots row. Rejected: R2-O8, R2-O9 and R2-O10 as proposed. R2-O7 changed from fix now to reject. The ruler reads the seed placeholder as an initial, so it joins the seed sentence to the "because" sentence. The joined count is 27 words, which fails AC1 as the frozen ruler assembles it. The edit was reverted. Noted: R2-O12, R2-O17, R2-P2. After the fixes: ruler R1 0, R2 0, R8 0. `--compare-tokens main` reports 0 differences. `prose-terms.py NEWS.md` finds every first use glossed. The R8 sweep of `NEWS.md` finds 0 hits, and `air format --check .` exit 0.
