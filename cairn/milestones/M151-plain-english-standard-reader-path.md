# M151: The plain-English standard, and the reader path

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — the vignettes and README that users read.
- **Branch/PR:** `m151-plain-english-standard-reader-path`

## Goal

Extend the house prose standard to plain vocabulary, one idea per sentence and no mannered construction, and apply it to `getting-started.Rmd`, `choosing-an-icc.Rmd`, `glossary.Rmd` and `README.Rmd`.

## Scope

**In:** `cairn/doctrine/prose-style.md` gains R7 (plain vocabulary) and R8 (no mannered construction) and R2 tightens to 25 words. `data-raw/prose-profile.py` gains a `--limit N` flag and skips `@noRd` roxygen blocks, both before the pass baseline, then stays frozen through M153. A committed term table `data-raw/glossary-terms.tsv` maps each glossary entry to a grep pattern and a short plain gloss. The four files are rewritten under R1 to R8. `README.md` is re-rendered. One NEWS Documentation bullet.

**Out:** the five method articles → M152; the roxygen surface → M153; `NEWS.md` under R7/R8 → candidate row; `cli` abort and hint strings → existing candidate row; any CI-wired prose checker → barred by D-021, the ruler and the term table stay hand-run; a mechanical no-widening certificate → "Three prose-apparatus deferrals" candidate row (R6 stays a read-through task here).

## Acceptance criteria

- [x] AC1: `cairn/doctrine/prose-style.md` states R7 and R8. R7 says that each term in `data-raw/glossary-terms.tsv` is glossed or linked at its first prose occurrence in each file. R8 lists the lexical markers its hand-run grep sweeps and says that the list is the sweep's extent, not a claim about mannered prose in general. R2 reads 25 words. The file measures at most 120 lines and 8,000 bytes by `wc -l -c`, with the budget figures in its header unchanged from the branch base.
- [x] AC2: `python3 data-raw/prose-profile.py --limit 25 --verbose` over `vignettes/getting-started.Rmd`, `vignettes/choosing-an-icc.Rmd`, `vignettes/glossary.Rmd` and `README.Rmd` reports a nonzero `sent` count and 0 dash-as-punctuation for each file, and every sentence its listing reports over 25 words contains verbatim one clause `tests/testthat/test-doc-skew-caveat.R` pins (the clause `residual_template()` returns, or one of the three clauses `width_templates()` returns) and has at most 10 words outside that clause, counted as the ruler counts words (whitespace tokens with an alphanumeric character, after its markdown normalization).
- [x] AC3: `data-raw/glossary-terms.tsv` has one row per `## ` heading of `vignettes/glossary.Rmd` (columns `heading`, `pattern`, `gloss`, `disposition` in `term|exempt`), and for each `term` row a grep of `pattern` over the prose of `vignettes/getting-started.Rmd`, `vignettes/choosing-an-icc.Rmd` and `README.Rmd` (prose as `prose-profile.py` defines it) finds, per file, no occurrence or a first occurrence whose sentence contains the row's `gloss` text verbatim or a link to that heading's anchor.
- [x] AC4: `grep -E` for the R8 lexical markers `cairn/doctrine/prose-style.md` lists, and for `\bM[0-9]{1,4}\b`, `\bD-[0-9]{3,4}\b`, `\bADR-[0-9]{3}\b`, `\bR[BR][0-9]{2}\b`, over the four files' prose returns no match.
- [x] AC5: `Rscript -e 'devtools::test()'` reports FAIL 0; each `data-raw/` script `grep -l -- '--self-test' data-raw/*` lists exits 0 under `--self-test`; `README.md` at the branch head is byte-identical to a fresh `devtools::build_readme()` render.

## Coverage

- AC1 → T1
- AC2 → T1, T3, T4, T5, T6
- AC3 → T2, T3, T4, T5, T6
- AC4 → T1, T3, T4, T5, T6
- AC5 → T7

## Tasks

- [x] T1: Doctrine and ruler. Add `--limit N` to `data-raw/prose-profile.py` and skip `@noRd` blocks in `.R` mode; record the new baseline over all three corpora in the work log. Write R7 and R8 into `cairn/doctrine/prose-style.md`, compressing the six-blind-spot paragraph into a pointer at the script's header to stay under budget; set R2 to 25. R8's marker list starts from the survey shapes: `which is why`, `That is why`, `precisely`, `the whole rule`, `In short`, `half the job`, `not .* but`, a heading ending in `?`.
- [x] T2: Build `data-raw/glossary-terms.tsv` from the glossary headings by a short script run once; mark `References` and the compound `vs.` headings `exempt` or split them into one row per term; write each gloss under ten words.
- [x] T3: Rewrite `vignettes/getting-started.Rmd` under R1 to R8, splitting rather than deleting qualifiers (R6).
- [x] T4: Rewrite `vignettes/choosing-an-icc.Rmd` the same way; the `## In short` section becomes a plain summary heading.
- [x] T5: Rewrite `vignettes/glossary.Rmd` so each entry's first sentence defines the term in plain words and later sentences gloss any statistical term they use; the Burch, Conflated and MPL entries are the heavy ones.
- [x] T6: Rewrite `README.Rmd`, re-render `README.md`, then run the R6 hunk audit per `prose-style.md` step 5 over every hunk of T3 to T6 and repair widenings in place; re-key any `data-raw/mpl-doc-claims.tsv` row or `test-vignette-claims.R` pin the rewrite moved; add the NEWS bullet.
- [x] T7: Verify: `devtools::test()`, every `--self-test` checker, `tests/spelling.R` (new gloss words go in prose, never padded into `inst/WORDLIST`), the ruler at `--limit 25`, the AC3 and AC4 greps; check `git status` for `Rplots.pdf` and `figure/`.

## Work log

- 2026-09-16: created by /milestone-plan. Survey [S] found undefined jargon, stacked clauses and mannered constructions across every file, heaviest in `interval-methods.Rmd`, `R/icc.R` and the glossary; R1/R2 drift since M136: `R/icc.R` 5 dashes, 4 over-35; `choosing-an-icc.Rmd` 1 over-35.
- 2026-09-16: criteria audit ran in full mode ([O] fresh-context reader) and returned six findings: an undefined pinned-clause domain, glossary-gloss universals re-creating M136 AC3's shape, a self-referential doctrine budget, a numeral-diff probe, instrument-bound gate criteria, and a `@noRd` domain mismatch; all six repaired in the wording above and in M152/M153, the length bar posed at the gate.
- 2026-09-16: plan gate chose a 25-word limit over 30 and 35 because the plain-English standard sets 25 for explanatory text; falsified by a rewritten article that a reader reports as choppy or that loses a bounding qualifier to a split.
- 2026-09-16: plan gate chose a committed term table with a verbatim-gloss-or-link test over a read-and-judge "plain gloss" criterion because the latter is the shape M136 AC3 returned three times on; falsified by a glossed term a newcomer still reports as unexplained.
- 2026-09-16: plan gate chose extending the hand-run ruler (`--limit`, `@noRd`) over a new checker because D-021 bars standing prose apparatus and the ruler is the accepted precedent; falsified by the ruler change making before/after figures incomparable, which is why it lands before the baseline.
- 2026-09-16: plan gate chose three milestones over two because the survey rates the rewrite heavy and M134 to M136 split the same corpus three ways under lighter rules; falsified by M151 closing in under one session.
- 2026-09-16: implement gate: AC2 amended (substantive) because the glossary must carry the three `width_templates()` clauses verbatim and the flat one is 32 words alone; the R8 marker list drops the question-mark shape at the user's choice, headings and sentences may end in `?`; AC3 gets a hand-run `data-raw/check-glossary-terms.py` with `--self-test`.
- 2026-09-16: re-audit: AC2 (full) — three defects: the command lists no sentences without `--verbose` and truncated them at 110 characters, the exemption bounded no sentence length, and an empty file passed vacuously; wording fixed once (`--verbose`, nonzero `sent`, at most 10 words outside the clause) and the ruler prints whole sentences.
- 2026-09-16: re-audit: AC2 (full) — one defect: the outside-clause count names no counting rule; the reader also measured the bound as achievable (parity sentence must drop its trailing clause) and noted the ruler has no `--self-test`, so AC5's sweep does not cover its changes. Second line is the stop; the wording question goes to the user.
- 2026-09-16: user adopted the counting clause into AC2; no further reader for AC2.
- 2026-09-16: T1 done. Ruler gains `--limit N`, whole-sentence `--verbose` output, `@noRd` block skipping and a `--self-test` (discovered sub-task, so its changes are covered by AC5's sweep); the blind-spot paragraph moved to the script header. New baseline at the branch base content, limit 35 / limit 25: vignettes 969 sentences, 3 / 104 over, 0 dashes; `R/*.R` 571 sentences, 7 / 87 over, 5 dashes (was 615 sentences before the `@noRd` skip); `README.Rmd` 69 sentences, 0 / 1 over, 0 dashes. Doctrine at 116 lines, 6,944 bytes. The AC3 checker is named `data-raw/prose-terms.py`, not `check-*.py`, so the `record-claims.tsv` inventory rows over `check-*` stay true.
- 2026-09-16: T2 done. `glossary-terms.tsv` has 34 rows, one per heading: 31 `term`, 3 `exempt` (the Credible-interval see-also, the `occasions`/`n_o` code-name pair, References); compound headings keep one row with an alternation pattern and one gloss. `prose-terms.py` checks the rule over prose as the ruler strips it, matches patterns on normalized sentences (a code span is `code`), reads anchors as pandoc slugs, fails on heading drift, and its `--self-test` plants glossed, linked, absent, bare and code-only cases plus a drifted table. At the branch base the three files carry 30 unglossed first uses.
- 2026-09-16: T3 done. `getting-started.Rmd`: 116 sentences, 0 over 25, 0 dashes, 0 parentheticals over 15; every first term use glossed or linked; the two `which is why` / `That is why` markers rewritten; qualifiers kept by splitting (the Spearman--Brown parenthetical and the Cicchetti bands became sentences).
- 2026-09-16: T4 done. `choosing-an-icc.Rmd`: 164 sentences, 0 over 25, 0 dashes; `## In short` is now `## Summary`; `precisely` (2), `half the job` and `This is why` rewritten; the `type` and `raters` section headings became plain questions because a heading is a term's first prose use and cannot carry a gloss (nothing links to those headings); the `k_eff` gloss in the table shortened to "the harmonic mean of the rating counts" so its sentence fits 25 words.
- 2026-09-16: T5 done. `glossary.Rmd`: 259 sentences, 2 over 25, both pinned (the flat width clause, 32 of 35 words; the residual clause, 58 of 64), 0 dashes; every entry opens with a plain definition, and kurtosis, profiling, studentizing, the posterior and identification are glossed where used; the parity sentence dropped its trailing clause into its own sentence; the Burch margin and residual runs stay contiguous, and `test-doc-skew-caveat.R` passes on the source leg (2 installed-vignette skips).
- 2026-09-16: T6: `README.Rmd` rewritten (82 sentences, 0 over 25, 0 dashes; the non-base `Imports:` sentence kept verbatim for the dependency-list pin); `README.md` re-rendered by `devtools::build_readme()`, the two regenerated plot images restored since their chunks did not change; R6 hunk audit over every hunk of T3 to T6 found four repairs (consistency "asks only", the per-subject qualifier on the `k_eff` gloss, the exact-F cell sentence's grid referent, the studentize gloss), all repaired in place; no `mpl-doc-claims.tsv` row and no `test-vignette-claims.R` pin names the four files, so nothing to re-key; NEWS gains a Documentation bullet; `spelling::spell_check_package(vignettes = TRUE)` clean with no WORDLIST change.
- 2026-09-16: claim audit: 48 claims read, 5 corrected — NEWS.md, README.Rmd, README.md, vignettes/getting-started.Rmd, vignettes/choosing-an-icc.Rmd, vignettes/glossary.Rmd, data-raw/glossary-terms.tsv (the NEWS term-rule scope narrowed to the three reader-path files; the two-way gloss gains its verb; the README engine sentence de-circled and the cluster-level gloss attached to one level; the studentize gloss names the transformed scale); the reader's one re-read found all five holding. Noted, not a claim: the tsv's one-way/two-way row glosses two-way only, so a file whose first use is "one-way" would be asked for the two-way definition; no current file trips it.
- 2026-09-16: T7 done. Full `devtools::test()` (summary reporter): no failures; one new warning at `test-doc-skew-caveat.R:1974` traced to the glossary sentence "on the one grid reaching a true ICC of 0.6", which the canonical-claim scanner read as a ratio claim; reworded to "on that same grid" and the file re-runs with no warning, as do `test-vignette-claims.R` and `test-vignette-transcripts.R`. All 11 `--self-test` scripts exit 0; spelling clean; README.md byte-identical to a fresh render; AC2 ruler 0/0/2/0 over 25 (the 2 pinned), 0 dashes, all four `sent` counts nonzero; `prose-terms.py` exit 0; AC4 grep no match; no `Rplots.pdf` or `figure/` left in the tree. Status set to review.
- 2026-09-16: note: the simple-english lint hook flagged pre-existing dashes, semicolons and long sentences in `ROADMAP.md`, this file, `prose-style.md`, `data-raw/README.md` and `NEWS.md` on every edit; the tracking records are append-only history and were not rewritten.

## Decisions

## Review

- 2026-09-16 (review): default branch unchanged since the branch was cut (`git fetch`; 0 commits on `origin/main` past the merge base); no PR exists for the branch.
- AC1 — verified. `prose-style.md` states R7 (each `glossary-terms.tsv` term glossed or linked at its first prose occurrence per file, verbatim gloss or anchor link) and R8 (seven grep markers listed, with the sentence that the list is the sweep's extent); R2 reads 25 words. `wc -l -c`: 116 lines, 6,935 bytes; the budget header (< 120 lines, < 8,000 bytes) is byte-identical to `main`'s.
- AC2 — verified. `prose-profile.py --limit 25 --verbose` per file: getting-started 117 sentences, 0 over, 0 dash; choosing-an-icc 166, 0, 0; glossary 258, 2 over, 0 dash; README.Rmd 82, 0, 0. The two over-limit glossary sentences each contain one pinned clause verbatim: the flat width clause (sentence 35 words, clause 32, 3 outside) and the residual clause (64, 58, 6 outside), counted by the ruler's word rule.
- AC3 — verified. `glossary-terms.tsv`: 34 rows against 34 `## ` headings, 31 `term` and 3 `exempt`; `prose-terms.py` exits 0 with every first use reported `glossed`, `linked` or `absent` across the three files; its `--self-test` passes (glossed, linked, absent, bare-fails, code-only, heading-drift-fails, slug).
- AC4 — verified. `grep -E` over the four files for the seven R8 markers and the four id patterns (`M<n>`, `D-<n>`, `ADR-<n>`, `RB/RR<n>`): no match.

- Consistency gate: `cairn_validate.py` all checks passed; no `DESIGN.md` principle changed (`cairn_impact` skipped); `pkgdown::check_pkgdown()` no problems; NEWS carries the Documentation bullet with no milestone ids; README.md byte-identical to a fresh render; no new top-level files. `devtools::document()` rewrites `NAMESPACE`'s two `importFrom(generics, …)` lines: the file is untouched by the branch (last generated 2026-08-13 under roxygen2 8.1.0, the version DESCRIPTION records) and the local roxygen2 is 8.0.0, so the diff is a local toolchain-version artifact, not drift from the branch's roxygen; recorded, not counted as a gate failure. `devtools::check()` result recorded under AC5.
- Independent review, three lenses ([O] diff-bug, [S] blame-history, [S] prior-review record; the last found the GitHub inline-comment probe empty and read the archived reviews). Findings and dispositions, most severe first:
  - [O1] README two-way gloss "every subject is rated by the same raters" narrows two-way to the complete case while the package covers incomplete two-way data — fixed now: gloss is "the subjects share one set of raters" (table, README, getting-started, choosing-an-icc, glossary).
  - [O2] D-study gloss "projects a fitted reliability" changed the referent from the variance components — fixed now: "projects the fitted variance components to other rater counts" (table, README).
  - [O3] REML gloss "without downward bias" widens a comparative claim to unbiasedness — fixed now: "corrects maximum likelihood's downward bias" (table, glossary opener).
  - [O4] replicate gloss dropped "one of" — fixed now (table, README).
  - [O5] consistency glossed as rank agreement — fixed now: "raters agree apart from a constant offset per rater" (table, getting-started, choosing-an-icc, README, glossary; the choosing article's duplicate offset sentence dropped).
  - [O6] new getting-started sentence hard-codes 95% for a settable level — fixed now: "holds a chosen share, usually 95%, of the posterior probability" (table, getting-started).
  - [O7] NEWS "those two articles" dangles after three named, and "two sentences the suite pins" — fixed now: the three surfaces named, the two sentences described as carrying pinned clauses, refilled.
  - [O8] MPL gloss omits the small-sample correction — fixed now (table; no current first use).
  - [O15] / [S-prior 1] glossary Burch entry: "that same grid" pointed back across the subject-count sentence — fixed now: "sits on the grid where the margin reaches parity"; a first attempt that moved the sentence broke the three-clause run `test-doc-skew-caveat.R` requires and was reverted.
  - [O9] two-sided headings (`One-way vs. two-way`, `Subject level vs. cluster level`) carry one side's gloss; [O10] `Prior` and `fixed` patterns tuned to the current corpus; [O11] `prose-terms.py` splits sentences before normalizing where the ruler normalizes first; [O12] `roxygen_blocks()` merges adjacent blocks so a `@noRd` could drop a documented neighbour (none today); [O13] both self-tests use bare `assert` and the ruler's never exercises `main()` — follow-up: extend the "Three prose-apparatus deferrals" candidate row (b) at hygiene (the row already carries findings from three milestones, so the records-hygiene §7 chip is posed there). No current file trips any of them.
  - [O14] AC5's `grep -l -- '--self-test' data-raw/*` lists three non-script files — noted: the criterion says "each `data-raw/` script", the sweep runs the 11 scripts.
  - [O16] NEWS `## Documentation` subheading leaves the earlier bullet unheaded — rejected: pure structure nit, subheaded groups are the file's 0.1.0-era convention when a section grows.
  - [S-history 1–4] plainer wording for "asymptotic", the Burch numbers, the getting-started band caveat and the choosing-an-icc comparatives — all reported as preserved, no finding.
- Return floor: no finding shows an acceptance criterion failing; the gloss corrections are defects inside intentional changes, fixed on the branch before the gate (commits f9ee86b, 07c66f7); AC2–AC4 re-run clean after them (ruler 0/0/2/0 over 25, `prose-terms.py` exit 0, AC4 grep no match, spelling clean).
- AC5 — verified at the post-fix head (07c66f7 tree). `devtools::test()`: FAIL 0, 0 warnings, 2 installed-vignette skips; all 11 `data-raw/` scripts carrying `--self-test` exit 0; `README.md` byte-identical to a fresh `devtools::build_readme()`; `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- Step 6 checkpoint: all five criteria ticked against recorded evidence; gate green; ready for the approval gate.

- 2026-09-16: step-7 approval: m151-plain-english-standard-reader-path approved for merge
