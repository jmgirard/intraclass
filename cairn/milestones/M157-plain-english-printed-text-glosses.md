<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M157: Plain-English printed guidance, corrected glossary glosses, and no record IDs in messages

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP8
- **Resolves:** —
- **Surface tier:** user-facing — users read the printed walkthrough, the print and summary notes, the glossed docs and NEWS
- **Branch/PR:** —

## Goal

Finish three plain-English fixes that M156 left as candidate rows: the printed guidance, the narrow glossary glosses, and the record IDs in a user message.

## Scope

**In:** The printed text of `choose_icc()` in `R/choose-icc.R`: the walkthrough questions and choice labels, the rationale lines, and the notes. The notes that `format.icc()` and `summary.icc()` print in `R/icc-methods.R`. The pass applies R1–R6 and R8 of `cairn/doctrine/prose-style.md` to that text. R7 does not apply, for the reason the doctrine gives for condition text. Five glosses in `data-raw/glossary-terms.tsv` are rewritten so that each says no less than the package does: D-study, Monte-Carlo interval, credible interval, one-way vs. two-way, and subject vs. cluster level. The candidate row said "four" but names five. Every surface that quotes an old gloss carries the new one. These are roxygen and `man/`, the vignettes, both READMEs and `NEWS.md`. The npbootstrap hints at `R/boundary-hint.R:472` and `:486` contrast that method with "simulating from the fitted model". They do not quote the Monte-Carlo gloss and stay. `choose_icc()`'s two-way wording gets the same correction as the two-way gloss. The `n_o` projection message in `R/d-study.R:229` loses "(M20; ADR-030)". `NEWS.md` gets a Documentation bullet. The doctrine's scope paragraph names the printed output. This absorbs three candidate rows: "Printed guidance under the plain-English rules", "Glossary glosses narrower than the package", and "Internal record IDs in a user message".

**Out:** Which note prints on which design, and every printed number: unchanged. The header and table lines of `format.icc()` (`Subjects: …`, `Engine: …`) are labels, not prose, and stay. Plot labels in `R/autoplot.R` stay. The occasion-label defect is its own candidate row. The NEWS bullet sizes the glossary row mentions (875, 842 and 668 bytes) are dropped at the user's request (plan gate). The blind spots of `condition-text-profile.R` stay in their own candidate row. R2 over the older `NEWS.md` bullets, and the R7 misses in `R/data.R`, are new candidate rows (plan gate).

## Acceptance criteria

- [ ] AC1: No string literal in `R/choose-icc.R` or `R/icc-methods.R` contains an em dash, `---`, or a standalone `--` used as punctuation (R1, with the doctrine's exceptions). The procedure: every `STR_CONST` token that `utils::getParseData()` returns for the two files, matched against that pattern.
- [ ] AC2: No sentence in the printed prose runs over 25 words (R2), counted with `prose-profile.py`'s sentence rule. The measured text is these prose strings, each written as its own paragraph. They are the questions and choice labels that `collect_answers_interactively()` passes to its `ask` seam, and the output of `recommendation_rationale()` and `recommendation_notes()` for every accepted combination of their arguments. They are also the `summary.icc()` notes and the `k_eff`, `k_c_eff` and conflated-level notes of `format.icc()`, as printed on the fits T5 names. Header, meta, table, variance-component and Shrout & Fleiss lines are labels and are not measured.
- [ ] AC3: The change is wording only. The profile's verify slot is clean. Every hunk of a re-recorded file under `tests/testthat/_snaps/` changes printed wording only. No hunk changes which note prints for a design, the order of the sections, or a printed number. Each changed claim, in a snapshot or in a test that pins text, is equal or narrower in scope than the text it replaced (R6). The one exception is the two-way label and rationale line that AC4 widens.
- [ ] AC4: Each of the five rewritten glosses in `data-raw/glossary-terms.tsv` has the property named here, checked by reading. The D-study gloss names occasion counts as well as rater counts. The Monte-Carlo gloss describes drawing parameter values, not simulating new data. The credible-interval gloss says that `conf_level` sets the share. The one-way vs. two-way gloss is true of incomplete two-way data. The subject vs. cluster level gloss names both levels. `choose_icc()`'s two-way choice label and rationale line are true of incomplete two-way data too. The credible-interval entry of `vignettes/glossary.Rmd` no longer fixes the level at 95%.
- [ ] AC5: No old gloss survives. For each of the five replaced gloss strings, a whitespace-insensitive search over `R/`, `vignettes/`, `README.Rmd`, `README.md` and `NEWS.md` returns no match. A second run of `devtools::document()` leaves `man/` unchanged, so the Rd pages match the roxygen. The search reads each file whole with `perl -0777`. It matches each space in the string as `\s+(#'\s*)?`, so it finds a gloss wrapped across lines. `python3 data-raw/prose-terms.py` over `README.Rmd`, `NEWS.md` and every `vignettes/*.Rmd` except `glossary.Rmd` reports every first use glossed or linked, as it does on `main`. `prose-profile.py --limit 25` over the files T2 edits reports no more dashes and no more sentences over 25 words than on `main`.
- [ ] AC6: No string literal in `R/*.R` that reaches a user carries an internal record ID. The procedure matches every `STR_CONST` token that `utils::getParseData()` returns for `R/*.R` against `\b(M[0-9]{2,3}|ADR-[0-9]{3}|D-[0-9]{3}|RR[0-9]{2})\b`, and finds no match. On `main` it finds only the `n_o` projection message at `R/d-study.R:228-229`. The same ruler run without flags reports R1 0, R2 0 and R8 0.
- [ ] AC7: `NEWS.md` has a Documentation bullet saying that the printed guidance was reworded and that five glossary glosses were corrected. The procedure finds the NEWS bullets this milestone adds or edits with `git diff main -- NEWS.md`. Measured alone with `prose-profile.py --limit 25`, those bullets report 0 dashes and 0 sentences over 25 words. The doctrine's R8 grep finds none of its markers in them.

## Coverage

- AC1 → T3, T4, T5
- AC2 → T3, T4, T5
- AC3 → T3, T4, T8
- AC4 → T1, T3
- AC5 → T2
- AC6 → T6
- AC7 → T7

## Tasks

- [ ] T1: Rewrite the five glosses in `data-raw/glossary-terms.tsv` against what the package does. The sources are `d_study(n_o=)` for the D-study gloss, and the parameter draws in `R/boundary-hint.R` and `vignettes/glossary.Rmd:217` for the Monte-Carlo gloss. They are the `conf_level` argument for the credible interval, incomplete two-way data for the two-way gloss, and both levels for the subject vs. cluster gloss. Update the matching `vignettes/glossary.Rmd` entries so that each carries its new gloss. After the edit, count fields on the touched rows with `awk -F'\t' '{print NF}'` (LESSONS, M153).
- [ ] T2: Carry each new gloss to every site that quotes the old one. Find the sites with AC5's search. On 2026-09-23 a line grep found them in `NEWS.md`, `README.Rmd`, six vignettes, and `R/boundary-hint.R:486`. It also found them in the roxygen of `R/icc.R`, `R/d-study.R`, `R/autoplot.R` and `R/data.R`. Re-run `devtools::document()` and knit `README.Rmd`. Audit each hunk for R6: the widening is intended only where the gloss was narrow, and a split must not strand a frame (LESSONS, M152). Run AC5's search and `prose-terms.py`.
- [ ] T3: Rewrite `choose_icc()`'s printed text: the questions and choice labels (`R/choose-icc.R:148-213`), `recommendation_rationale()` (`:489-545`) and `recommendation_notes()` (`:548-572`). Replace every ` -- ` and split every semicolon join that can be two sentences. Make the two-way label and rationale match T1's two-way gloss. Re-record `tests/testthat/_snaps/choose-icc.md` and read every hunk.
- [ ] T4: Rewrite the notes `format.icc()` and `summary.icc()` print (`R/icc-methods.R:238-269`, `:310-357`), keeping every branch condition as it is. Re-record the snapshots under `tests/testthat/_snaps/` and read every hunk.
- [ ] T5: Measure AC1 and AC2 with a one-off script kept in the work log, not committed. It lists the `STR_CONST` tokens of the two files. It renders the `choose_icc()` combinations, and the walkthrough labels through a fake `ask`. It prints and summarizes six fits: one-way, nested raters, two-way unreplicated, two-way replicated, incomplete two-way, and an incomplete crossed multilevel fit with `level = c("subject", "cluster", "conflated")` and `unit = "both"`. That last fit prints the `k_c_eff` and conflated notes. It writes each prose string as its own paragraph to a scratch `.md` file and runs `prose-profile.py --limit 25 --verbose` on it. Do the per-hunk R6 audit over T3 and T4.
- [ ] T6: Remove "(M20; ADR-030)" from the `n_o` message at `R/d-study.R:229` without changing its meaning. Update any test that pins the text. Run AC6's grep over the ruler's dump and the ruler itself.
- [ ] T7: Add the `NEWS.md` Documentation bullet and measure it as AC7 says. Extend the scope paragraph of `cairn/doctrine/prose-style.md` to name the printed guidance under R1–R6 and R8. The module is at 119 lines against its budget of under 120, so rewrite in place and check with `wc -l -c`.
- [ ] T8: Gate: `air format .`, `devtools::document()`, the full test suite and `devtools::check()`. Run every `data-raw/` checker with `--self-test` before the push, because a roxygen edit can re-key the MPL doc-claims ledger (LESSONS, M130). Re-measure AC5–AC7 after any fix made at the gate (LESSONS, M142).

## Work log

- 2026-09-23: created by /milestone-plan. Absorbs three candidate rows from M156: printed guidance, narrow glossary glosses, and record IDs in a user message.
- 2026-09-23: criteria audit, full mode, fresh [O] reader. It returned 9 findings: AC2 unsatisfiable over label lines (blocking), T5's `k_c_eff` fit unnamed, AC5 blind to `\%` in `man/`, the `boundary-hint.R` sites not gloss quotes, AC4's opening claim unbounded, AC3 without an R6 clause, AC6 wider than the ruler's dump, and the doctrine edit and touched-file ruler runs uncovered. All 9 were fixed in the plan. AC1 and AC7 were clean.
- 2026-09-23: plan gate chose drafting the five new glosses in implement, against AC4's properties, over settling their wording in the plan, because AC4 already fixes what each must say; falsified by a review finding that a gloss meets AC4 but misstates the package.
- 2026-09-23: plan chose a one-off measurement script for AC1 and AC2 over extending `data-raw/condition-text-profile.R` to printed text, because extending that ruler widens a checker M156 shipped over the repo's own source; falsified by a printed-text defect that the one-off script cannot see and an extended ruler can.
- 2026-09-23: plan gate dropped the NEWS bullet-size part of the glossary row (no rule sets a size) and filed two new candidate rows: R2 over the older `NEWS.md` bullets, and R7 misses in `R/data.R`.

## Decisions

## Review
