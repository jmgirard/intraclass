# M134: Vignette prose pass — the reader path, and the house style standard

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Branch/PR:** `m134-vignette-prose-reader-path` / https://github.com/jmgirard/intraclass/pull/143

## Goal

Rewrite the three reader-path articles so no sentence runs past 35 words and no
dash stands in for punctuation, and write down the style rules the pass applies.

## Scope

Surface tier: **user-facing** — the deliverable is prose readers of the pkgdown
site and `browseVignettes()` see. Correcting what the package tells its users is
D-029's carve-out from D-021, so no trigger in what the package computes is
needed; `data-raw/prose-profile.py` stays a one-shot ruler, never wired to CI.

**In:** `vignettes/getting-started.Rmd`, `vignettes/choosing-an-icc.Rmd`,
`vignettes/glossary.Rmd`. The style standard `cairn/doctrine/prose-style.md`,
stating rules R1–R6:

- **R1 dash-as-punctuation** — no em dash, `---`, or standalone `--` used as a
  sentence-level break. Not counted: YAML front-matter delimiters, markdown
  table separator rows, dashes flanked by digits (page and numeric ranges), and
  unspaced dashes joining two capitalized words (`Spearman--Brown`). That last
  exclusion is a shape, not a part of speech: the ruler does not separate
  `Spearman--Brown` from `An ICC—Intraclass`, and separating them would need a
  hand-kept list of proper nouns. A capital that follows a capitalized word is
  indistinguishable from a proper-noun join, so a sentence-initial capital or an
  acronym in that position goes uncounted with the proper nouns. A dash with a
  space on either side is counted whatever flanks it.
- **R2 sentence length** — no prose sentence over 35 words.
- **R3 one idea per sentence** — at most one subordinate clause before the main verb.
- **R4 parentheticals** — at most one per sentence, none over 15 words (judgment, not gated).
- **R5 semicolons** — no semicolon joining clauses that could be two sentences (judgment, not gated).
- **R6 meaning is fixed** — a rewrite never widens or narrows a claim's scope (M72/M128).

Baseline over `vignettes/*.Rmd` at `72f9cc2`, measured 2026-08-23 by the
committed ruler `python3 data-raw/prose-profile.py 'vignettes/*.Rmd'`: 744
sentence-level fragments, 81 over 35 words, 226 dash-as-punctuation
occurrences, 11 parentheticals over 15 words, 55 semicolons. The three
in-scope files hold 358 of those fragments, 20 over 35 words, 66 dashes. The
figures this milestone was planned with (594 / 121 / 287 / 195 / 56) came from
a throwaway ruler that was never committed and cannot be re-run; the committed
ruler's reading of the same commit supersedes them.

**Out:** the five method articles → M135. Roxygen and `README.Rmd` → M136.
`cli` abort and hint strings in `R/abort.R`/`R/boundary-hint.R` → stay a
candidate row (same D-029 class, own guard in
`data-raw/check-abort-remedy-verdicts.R`). Numeric targets for R4 and R5 → not
gated anywhere; the read-through applies them. Any CI-wired prose checker →
refused, D-021 stands.

## Acceptance criteria

- [x] AC1 `data-raw/prose-profile.py` is committed, implements R1's counted
      class and R2's sentence rule as `cairn/doctrine/prose-style.md` defines
      them, counts `#'` lines outside `@examples` in `.R` mode, and is
      byte-identical between its baseline run at `72f9cc2` and its final run.
- [x] AC2 `python3 data-raw/prose-profile.py 'vignettes/getting-started.Rmd'`
      and the same command for `choosing-an-icc.Rmd` and `glossary.Rmd` each
      report 0 dash-as-punctuation occurrences. `getting-started.Rmd` and
      `choosing-an-icc.Rmd` each report 0 sentences over 35 words. Every
      sentence the ruler reports over 35 words in `glossary.Rmd` is prose the
      reader reads, contains verbatim a clause `residual_template()` in
      `tests/testthat/test-doc-skew-caveat.R` returns, and exceeds that
      clause's own word count by at most eight (one such sentence at this
      commit: 64 words against a 58-word clause). The clause admits no split:
      the test matches it `fixed = TRUE` across a run's joined sentences, so a
      sentence break inside it leaves a `.` the template does not carry. If it
      ever admits a split, or the test stops matching verbatim, the target for
      `glossary.Rmd` returns to 0.
- [x] AC3 `cairn/doctrine/prose-style.md` exists and states rules R1–R6 as
      listed in Scope.
- [x] AC4 For every hunk of `git diff 72f9cc2 -- vignettes/getting-started.Rmd
      vignettes/choosing-an-icc.Rmd vignettes/glossary.Rmd` whose added **or**
      removed lines match `\b(any|each|every|all|only|both|exactly|never|always|full)\b`,
      the added text's claim domain is equal to or narrower than the text it
      replaced.
- [x] AC5 `devtools::test()` clean; `devtools::check()` raw `Status:` line 0
      errors / 0 warnings (NOTEs justified); `devtools::document()` no diff;
      `python3 data-raw/check-record-claims.py` exits 0 in live mode.

## Coverage

- AC1 → T1, T8, T11, T14
- AC2 → T1, T3, T4, T5, T14
- AC3 → T2, T11, T15
- AC4 → T6
- AC5 → T7, T10, T13, T16

## Tasks

- [x] T1 Write `data-raw/prose-profile.py` (drops fenced chunks in `.Rmd`, reads
      only `#'` lines outside `@examples` in `.R`, implements R1's exclusions),
      run it at `72f9cc2`, and record the baseline table in Scope.
- [x] T2 Write `cairn/doctrine/prose-style.md` with R1–R6.
- [x] T3 Rewrite `vignettes/getting-started.Rmd` against R1–R6.
- [x] T4 Rewrite `vignettes/choosing-an-icc.Rmd` against R1–R6.
- [x] T5 Rewrite `vignettes/glossary.Rmd` against R1–R6 (167 fragments, the
      longest file; its one-sentence definitions are the R2 stress case).
- [x] T6 Run the AC4 grep over added and removed diff lines; for each hunk it
      returns, compare the added claim's domain against the removed one and
      repair any widening in place.
- [x] T7 Run the AC5 verify block; re-knit nothing (no roxygen touched).
- [x] T8 Repair the ruler's proper-noun exclusion so it requires capitalization
      on both sides of the dash, and re-run the `72f9cc2` baseline with the
      corrected bytes.
- [x] T9 Action the review findings the gate directs.
- [x] T10 Re-run the AC5 verify block.
- [x] T11 Amendment: restate R1's exclusion in the terms the ruler can decide,
      identically in `cairn/doctrine/prose-style.md` and Scope, and write the
      ruler's four documented blind spots into the doctrine's prose boundary.
- [x] T12 Action the amendment gate's other dispositions: the two R6 drifts the
      second review found, and `cairn/DESIGN.md`'s doctrine-module registry.
- [x] T13 Re-run the AC5 verify block.
- [x] T14 Repair `RE_TABLE_RULE` to recognize a pandoc separator row with the
      leading and trailing pipes optional, correct the two stale docstring
      passages in the same edit (so the ruler's bytes are final before the
      baseline run), then re-run the `72f9cc2` baseline and re-measure the
      three in-scope files.
- [x] T15 Action the gate's other dispositions: the `cairn/doctrine/`
      admission decision and `cairn/DESIGN.md`'s registry line, the doctrine's
      pinned-clause exemption, and the orphan line wraps.
- [x] T16 Re-run the AC5 verify block.

## Work log

- 2026-08-23: created by /milestone-plan.
- 2026-08-23: plan-gate criteria audit ran in FULL mode ([O] fresh-context reader, all three milestones user-facing tier) and returned 13 findings, no criterion passing all six questions. Ten fixed here before writing: F1 (dash class unreachable at literal 0 — R1 exclusions defined), F2 (hand-listed R files → glob, M136), F3 (missing live MPL-checker AC, M136), F4 (`--self-test` is an instrument property → live mode), F5 (grep missed qualifier-deletion widening → added+removed lines, promise restated over hunks), F7 (AC3 unfalsifiable → R1–R6 enumerated in Scope; before/after examples moved to the PR body), F9 (AC1 was ruler-self-consistency → byte-identity of the ruler), F10 (`.R` mode scope undefined → `#'` outside `@examples`), F12 (M135 "re-triaged" undefined), F13 (M136 "in sync" → `git diff --exit-code`). Three posed at the gate: F8 (no target for parentheticals/semicolons), F11 (M136 AC2 requires a meaning change), audit note 2 (`cli` strings uncovered).
- 2026-08-23: plan gate chose three milestones split by article family over one all-vignettes milestone because M135's files carry five separate prose guards that one review would have to fence at once; falsified by a review that finds the three-way split forced the same edit to be re-argued across milestones.
- 2026-08-23: plan gate chose measured targets for R1/R2 only over numeric targets on all four trope classes because a zero target on parentheticals and semicolons has no non-arbitrary threshold and would fight readability; falsified by a post-pass read finding stacked parentheticals substantially unreduced.
- 2026-08-23: T1 — `data-raw/prose-profile.py` committed and run at `72f9cc2`; the ruler is frozen from this commit (AC1's byte-identity clock starts here).
- 2026-08-23: implement gate chose the committed ruler's baseline over the plan's recorded figures because the planned figures came from an uncommitted throwaway ruler that cannot be re-run; Scope amended to 744 fragments / 81 over 35 / 226 dashes / 11 long parentheticals / 55 semicolons over `vignettes/*.Rmd`, the three in-scope files holding 358 / 20 / 66. Falsified by the committed ruler needing a correction that changes these figures mid-pass.
- 2026-08-23: implement gate chose counting headings and table cells as prose over body paragraphs only, so AC2's zero covers every surface a reader sees; T5's stale sentence figure corrected to the new ruler's 167 fragments.
- 2026-08-23: T2 — `cairn/doctrine/prose-style.md` written: R1–R6 verbatim from Scope, the ruler's prose boundary, the five-step pass procedure, and a stated budget of 120 lines / 8,000 bytes (at 97 / 5,162).
- 2026-08-23: T3 — `getting-started.Rmd` rewritten; ruler now reports 0 dashes, 0 sentences over 35 (longest 32), against 18 dashes and 6 long sentences (longest 53) at baseline. Semicolons 1 → 0, long parentheticals 3 → 2.
- 2026-08-23: T4 — `choosing-an-icc.Rmd` rewritten; ruler now reports 0 dashes, 0 sentences over 35 (longest 35), against 21 dashes and 3 long sentences (longest 49) at baseline. Semicolons 9 → 0, long parentheticals 2 → 0. The `## In one sentence` heading became `## In short`, since R2 forbids the one 49-word sentence it named; no cross-reference targets that anchor.
- 2026-08-23: T5 — `glossary.Rmd` rewritten; ruler now reports 0 dashes (27 at baseline) and 1 sentence over 35 words (11 at baseline), semicolons 11 → 4, long parentheticals 0 → 0. The residue is irreducible: `tests/testthat/test-doc-skew-caveat.R`'s `residual_template()` requires a 58-word clause verbatim with no internal sentence-ending punctuation, so no split preserves it. AC2 amendment posed at a mini gate.
- 2026-08-23: T5 — two first-pass splits broke the width pins (`test-doc-skew-caveat.R` failures at :1999 and :2359) by moving `burch` away from the width vocabulary in one sentence and capitalizing the residual clause's first word in the other; repaired by making the flat and parity clauses each their own hit sentence and restoring the lowercase clause after a colon. `devtools::test(filter = "doc-skew-caveat")` now clean, 2 pre-existing skips (vignettes not installed).
- 2026-08-23: amendment gate — AC2 amended, the amended wording audited first by a fresh-context [O] reader in FULL mode (six questions; findings on satisfiability, GP8 count-pinning, an unenumerated singular over a template family, an unprobed exemption with no falsifier, and an instrument-bound promise — all five folded into the wording adopted; proportionality returned nothing). The gate chose the reviewed wording over a bare one-sentence exemption and over relaxing the test harness. Verdict recorded by the reader: WIDENING, since the amendment binds a property AC2 did not previously bind while relaxing the sentence target on one file.
- 2026-08-23: T6 — AC4 grep run over added and removed lines of `git diff 72f9cc2 -- <the three files>` (42 matching lines across 18 hunks); every hunk's added claim domain compared against the removed text, all 18 EQUAL, no widening or narrowing.
- 2026-08-23: T6 — the same diff also went to a fresh-context [O] reader that authored none of the prose, which found two R6 widenings the AC4 word list cannot catch, both from splitting a restrictive clause into a standalone sentence: `getting-started.Rmd` promoted "a textbook formula *that* misbehaves when a variance is near zero" into a general claim about textbook formulas, which the glossary's own `"mpl"` and `"npbootstrap"` entries contradict; `glossary.Rmd` promoted lavaan's "a rater is a single column with no random effect" into a claim about raters generally, false of the mixed-model engines. Both repaired in place, plus four lower-severity drifts (an entailment asserted by "meaning", a causal inversion at `choose_icc()`, a referent loosened to "That", and a directional "narrower margin"/"width advantage" where the original said only "margin"). Doc pins re-run clean.
- 2026-08-23: T7 — verify block run. `devtools::document()` no diff; `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862; `python3 data-raw/check-record-claims.py --live` exit 0 (6 claims re-derived, 0 failures); `devtools::check(document = FALSE)` raw `Status: 1 NOTE`, 0 errors, 0 warnings, vignettes re-built OK in 31s. The NOTE is the `spelling.Rout` comparison and is pre-existing: `spelling::spell_check_package()` flags the same 31 words at `72f9cc2` and on this branch (proper names and en-GB spellings absent from `inst/WORDLIST`, none in text this milestone added).
- 2026-08-23: NEWS.md gained a Documentation entry for the pass, worded to describe the act rather than assert a standing prose property no test enforces. Doc-claim pins re-run clean after it.
- 2026-08-23: AC1's byte-identity holds — `data-raw/prose-profile.py` has one commit (`96b78b4`, T1) and `git diff 96b78b4 -- data-raw/prose-profile.py` is empty, so the baseline run and the final run used the same bytes.
- 2026-08-23: all tasks checked; status → review.
- 2026-08-23: review checkpoint (mid-phase) — PR #143 opened as draft; `main` unmoved since the branch was cut. AC1–AC4 verified with fresh evidence and ticked. AC5 pending: `devtools::document()` no diff and `pkgdown::check_pkgdown()` clean and `check-record-claims.py --live` exit 0 already recorded, `devtools::test()` and `devtools::check()` still running. `cairn_validate` exit 0, all checks pass. Three review lenses spawned; the prior-review lens returned no findings.
- 2026-08-23: review returned M134 to `in-progress`. Failed: **AC1** — `data-raw/prose-profile.py`'s proper-noun exclusion (`before.isalnum() and after.isalnum() and after.isupper()`) is broader than the class `cairn/doctrine/prose-style.md` defines, so the ruler does not count an unspaced dash before a capitalized word. Reproduced on a five-site probe file: three genuine sentence-level breaks, one counted. Fixing it breaks AC1's byte-identity clause, so the `72f9cc2` baseline is re-run with the corrected ruler and the Scope figures restated, per the doctrine's own frozen-ruler rule; T3-T5 reopen if the corrected ruler reports non-zero on the three files. AC2/AC3/AC4 verified and ticked before the return; AC5 incomplete. Eight further [O] findings recorded in the Review section for triage, no status change of their own. First defect return on this milestone.

- 2026-08-23: T8 — `count_dashes()` repaired: the proper-noun exclusion now requires the word left of the dash to be capitalized as well as the character right of it, so `sentence---And` and `spaces—Raters` are counted while `Spearman--Brown` and `10--20` stay excluded. Verified on a five-site probe file: 1 counted before the fix, 3 after, the two excluded sites unchanged. Re-ran the `72f9cc2` baseline with the corrected bytes over the eight `vignettes/*.Rmd` blobs: 744 fragments / 81 over 35 / 226 dashes / 11 long parentheticals / 55 semicolons, the three in-scope files holding 358 / 20 / 66 — identical to the figures Scope already records, so no Scope amendment is owed. The three in-scope files still report 0 dashes under the corrected ruler, so T3–T5 do not reopen. AC1's byte-identity clause now reads against the corrected bytes: the baseline re-run and the final run use the same file.

- 2026-08-23: T9 — review findings actioned per the gate. Fixed: the NEWS entry's second clause ("so no statement is broader or narrower than it was") dropped, leaving the act it can back; four R6 drifts restored to the original's neutral wording (`glossary.Rmd`'s estimand "so" back to "and"; the indicator-mean entry back to leading with "a genuinely different estimator … though asymptotically equivalent", matching `engines.Rmd`; `choosing-an-icc.Rmd`'s "since there is no rater term" to "where"; `choose_icc()`'s "which is why it takes no `data` argument" to a neutral "and it takes no `data` argument"); `getting-started.Rmd`'s "avoids the textbook formulas" restored to the original's indefinite, default-scoped "the default interval does not rely on a textbook formula that misbehaves…"; long source lines rewrapped, taking >88-character lines to 0 / 1 / 5 against 0 / 1 / 8 at `72f9cc2`. Accepted at the gate: the `## In short` heading keeps the new anchor (no in-repo referrer). Added: a `## The prose ruler` section to `data-raw/README.md`, kept out of the claim-pinned checker inventory since the ruler is not a checker and is wired into no CI job. Ruler re-run after the edits: still 0 dashes on all three files and 1 over-35 sentence in `glossary.Rmd`. `check-record-claims.py --live` exit 0; doc pins FAIL 0 | PASS 2752.

- 2026-08-23: T10 — verify block re-run on the repaired branch. `devtools::document()` no diff (clean `git status` after); `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862; `devtools::check(document = FALSE)` raw `Status: 1 NOTE`, 0 errors / 0 warnings, vignettes re-built OK. The NOTE is the `spelling.Rout` comparison and is pre-existing: `spelling::spell_check_package()` flags 31 words on this branch, the same count recorded at `72f9cc2` and at T7, all proper names and en-GB spellings absent from `inst/WORDLIST`. `python3 data-raw/check-record-claims.py --live` exit 0 (6 claims, 0 failures) and `pkgdown::check_pkgdown()` clean, both re-run at T9. All tasks checked; status → review.

- 2026-08-23: review second pass — `main` still unmoved (0 behind / 13 ahead), PR #143 refreshed. AC2, AC3, AC4, AC5 verified with fresh evidence at HEAD and ticked; the `72f9cc2` baseline reproduces exactly (744 / 81 / 226 / 11 / 55) under the corrected ruler; `cairn_validate` exit 0; `devtools::test()` FAIL 0 | PASS 8862; `devtools::check()` `Status: 1 NOTE` (pre-existing spelling, 31 words, unchanged from baseline). Full three-lens fan-out re-run: both `[S]` lenses clean, `[O]` returned ten findings.
- 2026-08-23: amendment return: AC1 — "implements R1's counted class and R2's sentence rule as `cairn/doctrine/prose-style.md` defines them". The doctrine's R1 excludes "dashes joining capitalized proper nouns", which no procedure over the domain can decide; the ruler's decidable approximation (both flanking words capitalized) is a strictly larger exclusion, reproduced at review on a probe file where 2 of 4 genuine sentence-level breaks went uncounted. AC1 unticked. First amendment return on this milestone; the defect-return count stays at 1. Findings 3, 4, 5 and 6-10 recorded in the Review section for the maintainer at the step-6 gate.

- 2026-08-23: amendment-gate criteria audit ran in FULL mode ([O] fresh-context reader that authored none of the wording, user-facing tier), reading AC1 and AC3 as they read with the amended R1. Eight findings. Two fixed before the gate: the draft over-described the code (it read as though any capital after an unspaced dash is excused, where the left word must be capitalized too) and it asserted that no procedure could separate the two shapes, which nothing falsifies — now a claim about this ruler. Six posed or recorded at the gate: the ruler's four boundary gaps (pipe-less separator rows, `---` thematic breaks, joined list items, comment-before-fence stripping), AC1 binding an instrument rather than the prose, and AC3 binding two records to each other. Verdict recorded by the reader: NARROWS — the exclusion grows from an undecidable subset to a decidable superset, so the counted class shrinks.
- 2026-08-23: amendment return: AC1 — "Not counted: YAML front-matter delimiters, markdown table separator rows, dashes flanked by digits (page and numeric ranges), and unspaced dashes joining two capitalized words (`Spearman--Brown`)." This line executes the review's amendment return on AC1 rather than opening a new one, so the amendment-return count on AC1 stays at 1. AC1's own wording is unchanged; its meaning moves through R1, which the amendment restates identically in `cairn/doctrine/prose-style.md` and in Scope. The gate chose the reviewed wording over dropping its explanation and over a hand-kept proper-noun list, which is the author-recall enumeration the widening test bars. Narrowing repair: the exclusion widens, so R1's counted class shrinks. No ruler bytes change, so the frozen baseline and the `72f9cc2` figures stand.
- 2026-08-23: amendment gate chose documenting the ruler's four blind spots over repairing it, because the list-fragmentation repair moves the baseline figures for all eight vignettes mid-return; a ROADMAP candidate row carries the hardening and the two criteria-shape findings forward. Falsified by M135 or M136 hitting one of the four shapes in a file it must measure.
- 2026-08-23: T11 — R1 restated in `cairn/doctrine/prose-style.md` and Scope (byte-identical text); the doctrine's `.Rmd` strip order corrected to comments-before-fences to match `strip_rmd()`, and a paragraph added naming the four boundaries. Page at 115 lines / 6,486 bytes, inside its stated 120-line / 8,000-byte budget.
- 2026-08-23: T12 — `getting-started.Rmd`'s "the raters barely disagree, so the ratings are highly reliable" restored to the original's conjoined "and"; `choosing-an-icc.Rmd`'s "as error, as when one judge scores consistently higher" restored to the appositive definition "a systematic difference between raters, one judge scoring consistently higher than another, as error". `cairn/DESIGN.md`'s doctrine-module registry gained `prose-style.md`. Ruler re-run after the edits: 0 dashes on all three files, 0 over-35 in `getting-started.Rmd` (longest 32) and `choosing-an-icc.Rmd` (longest 35), 1 in `glossary.Rmd` (64 words) — AC2 unchanged.
- 2026-08-23: T13 — verify block re-run on the amended branch. `devtools::document()` no diff (clean `git status` after); `devtools::test()` no Failed section, exit 0, 3 warnings and 2 skips, the same set as T7 and T10; `devtools::check(document = FALSE, args = "--no-manual")` raw `Status: 1 NOTE`, 0 errors / 0 warnings, vignettes re-built OK in 22s, duration 13m 24s. The NOTE is the `tests/spelling.Rout` comparison and is pre-existing: `spelling::spell_check_package()` returns 31 words on this branch, the count recorded at `72f9cc2`, T7 and T10, none introduced here. `python3 data-raw/check-record-claims.py --live` exit 0 (6 claims, 0 failures); `pkgdown::check_pkgdown()` "No problems found"; `cairn_validate` exit 0, all checks pass, one advisory (sizing tripwires). All tasks checked; status → review.
- 2026-08-23: hygiene note for the maintainer — `cairn/ROADMAP.md` is at 23,996 bytes against its 24,000-byte budget after this milestone's candidate row. The next row cannot be added without retiring one.

- 2026-08-23: review third pass returned M134 to `in-progress`. Failed: **AC1** — R1 excludes "markdown table separator rows", and `RE_TABLE_RULE` (`data-raw/prose-profile.py:93`) recognizes one only when it carries a leading **and** a trailing `|`; a legal pandoc row `|--- |---` scores 2 dash occurrences, reproduced at review on a probe file. No `vignettes/` file trips it, so AC2's zeros stand. Defect return 2 (the amendment-return count on AC1 stays at 1); the repair is a regex change, which restarts the frozen baseline. Thrash trigger (b) fires — AC1 has failed at three consecutive reviews, each by a new clause of R1's exclusion list; a `/milestone-brief` escalation is offered. AC2-AC5 verified with fresh evidence at HEAD and left ticked. Six further [O] findings recorded in the Review section: the ruler docstring's stale exclusion rule and stale strip order, DESIGN.md's D-033 graduation claim, the doctrine's unqualified "reports zero", orphan line wraps, and a stale Coverage block.

- 2026-08-23: return gate — three questions posed, all three recommendations taken. (1) AC1: repair the ruler over the offered `/milestone-brief` escalation (thrash trigger (b)) and over narrowing AC1 to drop its counted-class clause; the repair recognizes a separator row by shape, closing the no-leading-pipe gap in the same pass rather than leaving the next clause of that shape for review 4. Falsified by a fourth review finding a further R1 clause the ruler decides differently from the doctrine. (2) Finding 4: a new D-entry widening `cairn/doctrine/`'s admission plus a reworded DESIGN.md registry line, over rewording DESIGN.md alone and over delisting `prose-style.md`. (3) Finding 5: the doctrine gains a pinned-clause exemption, over leaving the absolute for M135/M136 to inherit.
- 2026-08-23: T14 — `RE_TABLE_RULE` repaired to `^(?=[^|]*\|)(?=[^-]*-)[\s:|-]+$`: a separator row is dashes, colons, pipes and spaces carrying at least one of each of `|` and `-`, with both pipes optional as pandoc allows. The two stale docstring passages (the pre-T8 proper-noun rule at the counted-classes head, and the `.Rmd` strip order) were corrected in the same edit, so the ruler's bytes were final before the baseline run and AC1's byte-identity clause reads against them. Probe file carrying `|--- |---`, `---- | ----`, `|---|---|`, `sentence---And`, `Spearman--Brown` and `10--20`: 5 dashes counted before the repair, 1 after — the one genuine sentence-level break, both proper-noun and numeric joins still excluded, all three separator rows now excluded. Re-ran the `72f9cc2` baseline with the final bytes over the eight `vignettes/*.Rmd` blobs: 744 fragments / 81 over 35 / 226 dashes / 11 long parentheticals / 55 semicolons, the three in-scope files holding 358 / 20 / 66 — identical to the figures Scope already records, so no Scope amendment is owed. The three files at HEAD still report 0 dashes each and 0 / 0 / 1 sentences over 35 (longest 32 / 35 / 64), so AC2 is undisturbed and T3–T5 do not reopen. `cairn/doctrine/prose-style.md`'s strip description and boundary paragraph restated against the repaired ruler: the separator-row gap is closed, and the fourth boundary is now the narrower one that remains, a table row splitting into cells only when it starts with `|`. Page at 118 lines / 6,752 bytes, inside its 120-line / 8,000-byte budget.
- 2026-08-23: Coverage amended (third-pass finding 7): AC1 → T1, T8, T11, T14; AC2 gains T14; AC3 gains T11 and T15; AC5 gains T10, T13, T16.
- 2026-08-23: T15 — **D-034** appended: a doctrine module may enter `cairn/doctrine/` either by graduation from `cairn/LESSONS.md` or by being authored directly as a standard the repo will hold work to, the rest of D-033 standing. `cairn/DESIGN.md`'s registry line now reads "**Doctrine modules** (`cairn/doctrine/`, transferable craft standards — D-033, D-034):", which no longer asserts a graduation `prose-style.md` does not have (third-pass finding 4). The doctrine's pinned-clause exemption (finding 5) landed with the T14 doctrine edit: R1/R2's "reports zero" now carries "The one exemption is a clause a test pins verbatim and that admits no sentence break: a pass carrying such a clause records it where it records the pass, with the clause's word count and the sentence's." Five orphan wraps reflowed (finding 6, plus the `[S]` lens's `glossary.Rmd:82`) at `choosing-an-icc.Rmd`, `getting-started.Rmd`, and three sites in `glossary.Rmd`; whitespace only, verified by the three files' whitespace-collapsed token streams diffing empty against the previous commit, and the ruler unchanged at 0 / 0 / 0 dashes and 0 / 0 / 1 over 35. Long-line counts hold at 0 / 1 / 5. The ROADMAP candidate row's blind-spot list re-pointed at the current four.
- 2026-08-23: hygiene note for the maintainer, restated — `cairn/ROADMAP.md` is at 23,999 bytes against its 24,000-byte budget. The candidate row's edit was sized to fit; the next row cannot be added without retiring one.
- 2026-08-23: T16 — verify block re-run on the repaired branch. `devtools::document()` no diff (clean `git status` after); `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862, the same figures as T7, T10 and T13; `devtools::check(document = FALSE, args = "--no-manual")` raw `Status: 1 NOTE`, 0 errors / 0 warnings, no `* checking …` line reporting WARNING or ERROR, vignettes re-built OK in 23s, duration 14m 16s. The NOTE is the `tests/spelling.Rout` comparison and is pre-existing: `spelling::spell_check_package()` returns 31 words on this branch, the count recorded at `72f9cc2`, T7, T10 and T13, none introduced here. `python3 data-raw/check-record-claims.py --live` exit 0 (6 claims, 0 failures); `pkgdown::check_pkgdown()` "No problems found"; `cairn_validate` exit 0, all checks pass, one advisory (16 tasks against the 10-task split tripwire). All tasks checked; status → review.
- 2026-08-23: review fourth pass, checkpoint (mid-phase) — `main` still unmoved (0 behind / 20 ahead), PR #143 refreshed. AC1-AC4 verified with fresh evidence at HEAD and ticked; the `72f9cc2` baseline reproduces exactly (744 / 81 / 226 / 11 / 55; in-scope 358 / 20 / 66) under the T14 ruler, and a six-shape probe confirms R1's counted class. `cairn_validate` exit 0, all checks pass, one advisory (16 tasks against the 10-task tripwire). `pkgdown::check_pkgdown()` clean; `check-record-claims.py --live` exit 0; `devtools::document()` no diff. AC5's `devtools::test()` and `devtools::check()` still running. Three lenses spawned; the prior-review lens returned no findings.
- 2026-08-23: review fourth pass — AC1-AC5 all verified with fresh evidence at HEAD; `devtools::test()` FAIL 0 | PASS 8862, `devtools::check()` `Status: 1 NOTE` (pre-existing spelling, 31 words, unchanged from baseline), `cairn_validate` exit 0. Both `[S]` lenses clean; `[O]` returned seven findings. amendment return: AC1 - "implements R1's counted class and R2's sentence rule as `cairn/doctrine/prose-style.md` defines them". R1 excludes "markdown table separator rows" unqualified while the doctrine's ruler section defines the row as carrying at least one `|`; a pandoc simple-table or grid-table separator row scores dashes, reproduced at review (30 occurrences on a probe, nil reachable in this repo). This is amendment return 2 naming AC1, so the second-occurrence stop fires: no further round convened, disposition to the maintainer at the gate. Defect-return count stays at 2; thrash trigger (b) still standing.
- 2026-08-23: gate triage — merge approved; findings 2, 3 and 4 fixed on the branch (doctrine blind-spot list to six boundaries, the 108-char line rewrapped, `data-raw/README.md`'s falsified sentence reworded), findings 5 and 6 rejected, finding 7 and AC1's shape carried on the ROADMAP candidate row. Finding 1 accepted and recorded; the `/milestone-brief` escalation and a fifth amendment round both declined. Doctrine compressed back to 119 lines / 6,900 bytes; AC3 re-checked byte-identical; ruler, claim pins and doc pins re-run clean.

## Decisions

**2026-08-23 — the glossary keeps one over-35-word sentence rather than the test
harness being relaxed.** The residual-width clause `residual_template()` requires
is matched `fixed = TRUE` against a run's joined sentences, so a sentence break
inside the clause leaves a `.` the template does not carry and the match fails.
Two ways out: bend the prose (accept one long sentence) or relax the harness
(match punctuation-normalized text, so the clause may be split). This milestone
took the first; the second changes a guard over a measured claim, which is
apparatus work needing its own plan gate, and this milestone's scope is prose
only. Falsified by a reader reporting the grids sentence as unreadable, or by
the harness being relaxed for another reason — at which point AC2's target for
`glossary.Rmd` returns to 0.

## Review

### First pass — returned to `in-progress`

Reviewed 2026-08-23 on `m134-vignette-prose-reader-path` at PR #143. Default
branch `main` had not moved since the branch was cut (`origin/main` = `3652665`,
branch 0 behind / 8 ahead), so no merge was needed before gathering evidence.

### Acceptance criteria

- **AC1 — pass.** `data-raw/prose-profile.py` is committed with exactly one
  commit touching it (`96b78b4`, T1); `git diff 96b78b4 -- data-raw/prose-profile.py`
  is empty and both blobs hash to `291d714e`, so the baseline run and the final
  run used identical bytes. Read against `cairn/doctrine/prose-style.md`: `RE_DASH`
  matches `---`/em dash/`--` longest-first, `count_dashes()` skips digit-flanked
  dashes and capitalized proper-noun joins, `strip_rmd()` removes the YAML front
  matter and the markdown table rule row, and `SENTENCE_LIMIT` is 35 counted
  strictly greater. `strip_roxygen()` keeps `#'` lines and suppresses each
  `@examples` block until the next `#' @` tag.
- **AC2 — pass.** Ruler re-run on each file: `getting-started.Rmd` 0 dashes,
  0 sentences over 35 (longest 32); `choosing-an-icc.Rmd` 0 dashes, 0 over 35
  (longest 35); `glossary.Rmd` 0 dashes, 1 over 35 (64 words). The one long
  sentence is body prose in the **Burch interval** entry. Its 58-word residual
  clause from `residual_template()` is present verbatim in `glossary.Rmd` once
  line wrapping is joined, and 64 − 58 = 6 ≤ 8.
- **AC3 — pass.** `cairn/doctrine/prose-style.md` exists (97 lines) and states
  R1–R6 with wording matching the Scope list; R1's four exclusions and R2's
  35-word limit are stated as Scope has them.
- **AC4 — pass.** `git diff 72f9cc2 -- <the three files>` is 33 hunks; the
  qualifier grep over added **and** removed lines matches 42 lines across 14
  hunks. (T6 recorded 18 hunks; the later R6 repairs merged hunk boundaries,
  and the matching-line count is unchanged.) All 14 read as EQUAL domain: every
  match is a dash, semicolon, or parenthesis converted to a sentence break with
  the quantified claim carried over verbatim. The two claims most at risk were
  checked in particular — `getting-started.Rmd` keeps the restrictive clause in
  "the textbook formulas *that misbehave when a variance is near zero*", so it
  is not a claim about textbook formulas generally, and the **Burch interval**
  entry keeps "on the two grids this package has measured that vary only the
  subject effect" attached to its narrowness claim.

- **AC5 — not established.** `devtools::document()` produced no diff (only the
  milestone file this review edits was modified). `pkgdown::check_pkgdown()`
  clean and `python3 data-raw/check-record-claims.py --live` exit 0 (6 claims
  re-derived, 0 failures). `devtools::test()` and `devtools::check()` were still
  running when the review returned on AC1; their results are not recorded here
  and AC5 stays unticked.

### Consistency gate

- `python3 cairn_validate.py` exit 0 — 16 PASS, 7 advisory OK, no FAIL.
- `cairn_impact.py` skipped: `Principles touched: —`, no DESIGN principle changed.
- Toolchain checks (`r-package` profile's `consistency-gate` slot):
  `devtools::document()` no diff; `NAMESPACE`/`man/`/`data/` untouched by the
  diff; `README.Rmd`/`README.md` untouched by the branch; `pkgdown::check_pkgdown()`
  clean; `NEWS.md` carries a Documentation entry for the pass; no new top-level
  file (`data-raw/` already carries `^data-raw$` in `.Rbuildignore`);
  `devtools::check()` incomplete at return.

### Independent review

Diff touches executable surface (`data-raw/prose-profile.py`) at a user-facing
tier, so the full three-lens fan-out ran, each lens fresh-context and none
having authored the work.

**[S] blame-history — no findings.** Traced every changed line in the three
vignettes to the commit that introduced it. The Burch/searle width paragraph
built up by M115–M118 survives verbatim (all figures, the "narrower nearly
everywhere" contrast, and the "the two grids that vary only the subject effect"
scope clause); only punctuation changed. Ran `test-doc-skew-caveat.R` (2344 pass,
0 fail) and `test-vignette-claims.R` (246 pass, 0 fail) directly as independent
confirmation. Noted that two R6 widenings appeared mid-branch and were repaired
before HEAD, so the merged diff carries neither.

**[S] prior-review record — no findings.** The GitHub inline-comment probe
returned empty, so no thread walk was paid for; archived `## Review` sections and
`LESSONS.md` were the evidence base. Cleared M130's pkgdown-anchor lesson by
rendering the four changed glossary headings through `pandoc` before and after —
all four anchor ids are stable — and confirmed no `glossary.html#…` reference in
the other six vignettes targets a changed heading.

**[O] diff-bug — nine findings, ranked.** Full text in the work log's return
line and below; dispositions are the maintainer's at the gate.

1. **The ruler's proper-noun exclusion is over-broad, so R1's counted class is
   narrower than the doctrine defines it.** `data-raw/prose-profile.py:227-233`
   skips a dash whenever `before.isalnum() and after.isalnum() and
   after.isupper()`. The doctrine excludes "dashes joining capitalized proper
   nouns"; the code requires nothing of the left side. **Reproduced at review**
   on a probe file with five dash sites: of three genuine sentence-level breaks,
   the ruler counted one — `…no spaces—Raters differ…` and `…one---And this
   too…` were both silently excluded, and only the spaced ` --- ` was counted.
   An unspaced em dash before a capitalized word is the ordinary typographic
   form of the trope R1 bans.
2. **The NEWS entry asserts a universal meaning-preservation guarantee nothing
   enforces.** `NEWS.md`: "every claim the pass touched was checked against the
   text it replaced, so no statement is broader or narrower than it was." The
   first clause describes the act; the second asserts a standing property of the
   prose, which no test enforces and which findings 4, 5, and 7 are candidate
   counterexamples to.
3. **Source line-wrapping regressed.** `getting-started.Rmd:153` (202 chars),
   `choosing-an-icc.Rmd:36` (252) and `:265` (153) are unwrapped joins;
   `glossary.Rmd` goes from 8 to 16 lines over 88 characters. Confirmed
   independently at a 90-character threshold: glossary 4 → 9, getting-started
   0 → 1, choosing-an-icc 1 → 2.
4. **`choose_icc()` gained a causal claim the original did not make.**
   "It does **not** fit anything, which is why it takes no `data` argument"
   replaces a neutral apposition, and asserts the direction backwards.
5. **Two added causal connectives.** `glossary.Rmd` turns "and picking the
   coefficient is really picking…" into "so picking…"; `choosing-an-icc.Rmd`
   turns an appositive into "since there is no rater term to reason about".
   Each converts a conjoined fact into an asserted entailment.
6. **`## In one sentence` → `## In short` moves a published anchor.** No
   in-repo referrer (confirmed by the lens and by the work log), so the break is
   external bookmarks only. The four glossary heading swaps are safe.
7. **"`icc()` avoids the textbook formulas…" is a package-level claim where the
   original described only the default.** `ci_method = "searle"`/`"burch"`/
   `"mpl"` are closed-form intervals `icc()` will use; the restrictive clause
   probably rescues it, but it is the widening shape R6 warns about.
8. **Indicator-mean entry: the concessive is flipped.** "asymptotically
   equivalent … **but** a genuinely different estimator" reverses the original's
   emphasis, and `engines.Rmd:99` still leads with the other half.
9. **`data-raw/README.md` gained no row for the new script.** No claim-pinned
   count is disturbed, but `data-raw/`'s inventory has no pointer to it.

The lens found nothing factually wrong about what the package does beyond
finding 7's overreach, and nothing contradicting D-021, D-029, D-032, D-033 or a
DESIGN principle.

### Outcome

**Returned to `in-progress` under the return floor.** Finding 1 demonstrates AC1
failing inside its own domain: AC1 promises the ruler "implements R1's counted
class … as `cairn/doctrine/prose-style.md` defines them", and it does not. This
is a defect return, not an amendment return — the criterion is right and the
implementation is wrong, and the repair is a correction to a procedure, not the
widening of an author-recalled enumeration.

The repair interacts with AC1's second clause. Fixing the exclusion breaks
byte-identity with the `72f9cc2` baseline run, so the baseline must be re-run
with the corrected ruler and the Scope figures restated — which is what
`prose-style.md`'s own closing rule already prescribes ("a correction to the
ruler restarts the pass's baseline"). The corrected ruler may also report
non-zero dashes in the three files, which would reopen T3–T5.

Findings 2–9 carry no status change of their own and go to the maintainer for
triage; they are listed above so none is silently dropped.

### Second pass

Reviewed 2026-08-23 on `m134-vignette-prose-reader-path` at PR #143, after the
T8–T10 repairs. `git fetch` then `git rev-list --left-right --count
origin/main...HEAD` reports 0 behind / 13 ahead, so `main` has still not moved
since the branch was cut and no merge was needed before gathering evidence.

#### Acceptance criteria

- **AC1 — FAIL (second clause passes, first does not).** `data-raw/prose-profile.py` now has two commits (`96b78b4` T1,
  `14e7dce` T8); `git diff 14e7dce -- data-raw/prose-profile.py` is 0 bytes, so
  the file has not moved since the T8 re-baseline. The `72f9cc2` baseline was
  re-run at review with those same bytes over the eight `vignettes/*.Rmd` blobs
  extracted from that commit: 744 fragments / 81 over 35 / 226 dashes / 11 long
  parentheticals / 55 semicolons, the three in-scope files holding 358 / 20 / 66
  — reproducing the Scope table exactly, so the baseline run and the final run
  use identical bytes. Read against `cairn/doctrine/prose-style.md`: `RE_DASH`
  matches `---`/em dash/`--` longest-first; `count_dashes()` skips digit-flanked
  dashes and skips a proper-noun join only when the word left of the dash **and**
  the character right of it are both capitalized; `strip_rmd()` drops YAML front
  matter and table rule rows; `SENTENCE_LIMIT` is 35, counted strictly greater;
  `strip_roxygen()` keeps `#'` lines and suppresses each `@examples` block until
  the next `#' @` tag. **What fails is the "implements R1's counted class … as
  `cairn/doctrine/prose-style.md` defines them" clause.** The doctrine excludes
  "dashes joining capitalized proper nouns"; the code excludes any dash whose
  flanking words are both capitalized, which is a strictly larger class.
  Reproduced at review on a five-sentence probe file: of four genuine
  sentence-level breaks the ruler counted two — `Reliability—And nothing else…`
  and the opening dash of `An ICC—Intraclass correlation—is the topic.` were
  both silently excluded, because a sentence-initial capital and a capitalized
  acronym are indistinguishable to the test from `Spearman--Brown`. The three
  in-scope files are unaffected (their only capital-flanked dashes are
  `Spearman--Brown`, `McGraw--Wong`, `Shrout--Fleiss`), so AC2's zeros stand.
  See the Outcome below: this routes as an **amendment return**, not a defect
  return.
- **AC2 — pass.** Ruler re-run per file at review: `getting-started.Rmd` 0 dashes,
  0 over 35 (longest 32); `choosing-an-icc.Rmd` 0 dashes, 0 over 35 (longest 35);
  `glossary.Rmd` 0 dashes, 1 over 35 (64 words). The one long sentence is body
  prose in the **Burch interval** entry. The 58-word clause `residual_template()`
  returns is present in `glossary.Rmd` verbatim once wrapping is joined (matched
  by exact substring at review, with the rendered `1.2963` / `100` cells in
  place), and 64 − 58 = 6 ≤ 8.
- **AC3 — pass.** `cairn/doctrine/prose-style.md` exists (97 lines, 5,162 bytes,
  inside its own stated 120-line / 8,000-byte budget) and states R1–R6 with
  wording matching the Scope list, R1's four exclusions and R2's 35-word limit
  included.
- **AC4 — pass.** `git diff 72f9cc2 -- <the three files>` is 33 hunks; the
  qualifier grep over added **and** removed lines matches 46 lines across 14
  hunks (up from 42 lines at the first pass — the T9 repairs added text carrying
  the scope words). Each of the 14 was read added-against-removed: all EQUAL
  domain, every match a dash, semicolon, or parenthesis converted to a sentence
  break with the quantified claim carried over. The three claims the first pass
  flagged were re-checked in particular and each now reads at or inside its
  original domain: `getting-started.Rmd` says "the default interval does not rely
  on a textbook formula that misbehaves when a variance is near zero" (the
  default, with the restrictive clause intact); `choose_icc()` reads "does not fit
  anything, and it takes no `data` argument" with no causal claim; the **Burch
  interval** entry keeps "on the two grids this package has measured that vary
  only the subject effect" attached to its narrowness claim.
- **AC5 — pass.** `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862.
  `devtools::check(document = FALSE)` raw `Status: 1 NOTE`, 0 errors / 0
  warnings; zero `* checking …` lines report WARNING or ERROR, and vignettes
  re-built OK in 22s. The NOTE is the `tests/spelling.Rout` comparison and is
  pre-existing: `spelling::spell_check_package()` returns 31 words on this
  branch, the same count recorded at `72f9cc2`, and every one is a proper name
  (Chinn, Davison, Gulliford, Liu, Ohyama, Okabe, Searle, Ukoumunne, Xiao) or an
  en-GB spelling absent from `inst/WORDLIST`; none is a word this milestone
  introduced. `devtools::document()` produced no diff (only the milestone file
  this review edits is modified). `python3 data-raw/check-record-claims.py
  --live` exit 0, 6 claims re-derived, 0 failures.

#### Consistency gate

- `cairn_validate.py` exit 0 — 16 PASS, 7 advisory OK, no FAIL. `coverage
  complete` and `binding criteria` both pass.
- `cairn_impact.py` skipped: `Principles touched: —`, no DESIGN principle changed.
- Toolchain checks (`r-package` profile's `consistency-gate` slot):
  `devtools::document()` no diff; `NAMESPACE`, `man/`, `data/` untouched by the
  branch diff; `README.Rmd`/`README.md` untouched; `pkgdown::check_pkgdown()`
  reports "No problems found"; `NEWS.md` carries a Documentation entry for the
  pass with no milestone number in it; no new top-level file (`data-raw/`
  already carries `^data-raw$` in `.Rbuildignore`); `devtools::check()` as
  recorded under AC5.

#### Independent review

Diff touches executable surface (`data-raw/prose-profile.py`) at a user-facing
tier, so the full three-lens fan-out ran again on the repaired branch, each lens
fresh-context and none having authored the work.

**[S] blame-history — no defect findings.** Traced the branch's modified lines
through `git log`/`git blame`. The scope-critical Burch passage in
`glossary.Rmd` (the ICC 0.3 / ICC 0.6 / 5-rater / t(5) 1.2963 figures tied to
M118 and D-030) is unchanged in substance between `main` and HEAD — punctuation
and wrapping only. Confirmed M115's withdrawn-claim wording ("`"burch"`
under-covers about as badly as the default") survives verbatim, the failure mode
M115 itself was returned on. Ran `test-doc-skew-caveat.R` directly: 2344 pass, 0
fail, 2 expected skips. One trivial note, no action: `prose-style.md` cites
"M72/M128" for R6, and M128 is squarely on point (a prose polish there
introduced a false "the interval widens accordingly" claim) while M72's link is
looser.

**[S] prior-review record — no findings.** The `gh api …/pulls/comments` probe
returned `[]`, so no thread walk was paid for; archived `## Review` sections and
`LESSONS.md` were the evidence base. Cleared M130's pkgdown-anchor lesson
independently: the four re-punctuated glossary headings were rendered through
`pandoc` before and after and all four anchor ids are byte-identical, and the
one in-repo referrer (`glossary.html#effective-number-of-ratings-k_eff`, 2 uses)
still resolves. Confirmed the first pass's directed repairs are present at HEAD.

**[O] diff-bug — ten findings, ranked.** The lens re-derived the numbers rather
than trusting the work log, and independently confirmed the baseline (744 / 81 /
226 / 11 / 55; in-scope 358 / 20 / 66), AC2's 6 ≤ 8 arithmetic, the absence of
any un-excluded dash form in the three files, and the line widths (0 / 1 / 5
against 0 / 1 / 8).

1. **The T8 repair is one class short: the ruler's exclusion is keyed on
   capitalization, not on proper-noun-hood.** Verbatim: "Probed in the
   scratchpad: `Reliability—And nothing else matters here.` scores 0, and
   `An ICC—Intraclass correlation—is the topic.` scores 1 of its 2 breaks (the
   `ICC—Intraclass` opener is excused, the closing `correlation—is` is caught) —
   sentence-initial capitals and all-caps acronyms are exactly the tokens that
   open sentences everywhere in this repo. It does not disturb this milestone's
   numbers (at `72f9cc2` and at HEAD the only capital-flanked dashes in the three
   files are `Spearman--Brown`, `McGraw--Wong`, `Shrout--Fleiss`), but AC1
   promises the counted class the doctrine defines and this is the same failure
   shape the first round returned on, one level down."
   **Verified at review** on an independent probe file: 4 genuine breaks, 2
   counted. **Disposition: the amendment return below.**
2. **Two acceptance criteria are ticked `[x]` against evidence in `## Review`
   that HEAD contradicts.** Verbatim: "AC1's recorded proof is 'exactly one
   commit touching it (`96b78b4`, T1) … both blobs hash to `291d714e`' — false
   since T8's `14e7dce` changed the bytes; AC4's proof quotes
   `getting-started.Rmd` as keeping 'the textbook formulas *that misbehave when a
   variance is near zero*', a string T9 replaced with 'the default interval does
   not rely on a textbook formula that misbehaves…'. Neither criterion has fresh
   evidence at HEAD, and AC5 is still unticked."
   **Disposition: fixed by this pass.** The stale lines are now fenced under
   `### First pass — returned to `in-progress``, where they are an accurate record
   of what that pass measured, and every criterion carries fresh HEAD evidence
   above.
3. **`cairn/DESIGN.md`'s doctrine-module registry was not updated.** Verbatim:
   "Lines 102–107 enumerate `doc-claim-pins.md`, `data-raw-checkers.md`, and
   `source-ingestion.md` as the contents of `cairn/doctrine/`; D-033 makes that
   list the registry and the branch adds a fourth page without touching it."
   **Verified at review** — `cairn/DESIGN.md:102-107` lists three modules and
   `prose-style.md` is not among them. **Disposition: maintainer's at re-review.**
4. **R6 drift left in place, of the class T9 repaired elsewhere.** Verbatim:
   "`vignettes/getting-started.Rmd`: 'the raters barely disagree --- the ratings
   are highly reliable' became 'the raters barely disagree, **so** the ratings
   are highly reliable', the same em-dash-to-causal-connective conversion T9
   reverted at three other sites (glossary's estimand 'so'→'and',
   choosing-an-icc's 'since', `choose_icc()`'s 'which is why'). The asserted
   entailment is also false outside the sentence's frame — raters can agree
   perfectly with the ICC at zero when subject variance vanishes, which the
   glossary's own zero-variance-boundary entry describes."
   **Verified at review** at `git diff 72f9cc2 -- vignettes/getting-started.Rmd`
   lines 20–21. Outside AC4's domain (the line carries no word from AC4's list),
   so it is not a criterion failure. **Disposition: maintainer's at re-review.**
5. **R6 narrowing in `choosing-an-icc.Rmd`.** Verbatim: "'treats a systematic
   difference between raters -- one judge scoring consistently higher than
   another -- as error' became 'treats a systematic difference between raters as
   error, **as when** one judge scores consistently higher than another': the
   appositive was the definition of the difference, and 'as when' demotes it to
   one illustrative case. R6 bars narrowing as well as widening."
   **Verified at review** at that diff's lines 71–73. Outside AC4's domain.
   **Disposition: maintainer's at re-review.**
6. **The ruler mis-fragments a bullet list whose items carry no terminal
   punctuation.** Verbatim: "Probed: an eight-item list collapses to a single
   33-word fragment, so a long list reads as one overlong sentence (false R2
   positive) and the fragment count under-reports. Nothing in `vignettes/` trips
   it today, but `prose-style.md` specifies fragmentation for headings and table
   cells and is silent on list items, so the behaviour is undocumented rather
   than specified — and M135/M136 will run this instrument over list-bearing
   files."
7. **Two markdown constructs the R1 exclusion list does not reach produce false
   dash hits.** Verbatim: "A pipe table whose separator row lacks a leading `|`
   (valid pandoc, e.g. `-------- | --------`) scores 6 occurrences, and a `---`
   thematic break scores 1. Neither exists in `vignettes/` now — every separator
   row leads with `|` — but the ruler has no self-test, so this would surface as
   an unexplained non-zero in a later pass."
8. **R4's parenthetical counter matches only the innermost `\([^()]*\)`,**
   verbatim: "so a long outer parenthetical wrapping a nested one is never
   counted; the reported figure is a floor. R4 carries no target, so no criterion
   is affected."
9. **Doctrine/code order mismatch.** Verbatim: "`prose-style.md` states `.Rmd`
   mode drops 'the YAML front matter, fenced code chunks, HTML comments' in that
   order; `strip_rmd()` removes HTML comments before fences. Reachable only on a
   chunk containing `<!--`, but AC1's promise is implementation-as-written."
10. **`prose-style.md` was authored fresh rather than graduated from
    `cairn/LESSONS.md`,** verbatim: "which is the route D-033 describes for a
    `cairn/doctrine/` page, and no `D-0xx` entry records the new house standard —
    the only decision written down is the local one in the milestone file about
    the glossary's long sentence. A maintainer call, not a defect."

Findings 6–10 disturb no criterion and are the maintainer's at re-review. The
lens explicitly cleared four things so they are not re-raised: the `## In short`
anchor move (accepted at the first gate, no in-repo referrer), the NEWS entry as
now worded, `prose-profile.py`'s absence from the claim-pinned
`data-raw-checker-inventory` globs, and `.R` mode's `@examples` suppression
including the `y@slot` case.

#### Outcome

**Returned to `in-progress` as an amendment return on AC1.**

Finding 1 demonstrates AC1's first clause failing, and it fails inside the
domain of the procedure AC1 names. But the criterion, not the code, is what is
wrong. AC1 (through the doctrine's R1) promises the ruler's counted class equals
"every dash except those joining capitalized proper nouns", and *proper-noun-hood
is not decidable by any procedure over that domain*: no test separates
`Spearman--Brown` from `An ICC—Intraclass` without a hand-kept list of proper
nouns, an enumeration whose membership is fixed by author recall. That is the
widening test's trigger, so this routes as an amendment return rather than a
second defect return, and it does not increment the defect-return count the
thrash rule reads. The defect-return count stands at 1; this is amendment
return 1 on AC1.

The amendment to be gated at `/milestone-implement` step 6 restates R1's
exclusion in terms the instrument can decide — the shape the ruler already
implements, "dashes with no surrounding spaces joining two capitalized words" —
in `cairn/doctrine/prose-style.md` **and** in the milestone's Scope, since AC3
binds the two together. That is the amendment; whether findings 3, 4, 5 and
6–10 are actioned in the same stint is the maintainer's call at that gate.

Everything else passes: AC2, AC3, AC4 and AC5 all verified at HEAD, both
`[S]` lenses clean, and the consistency gate green.


### Third pass — returned to `in-progress`

Reviewed 2026-08-23 on `m134-vignette-prose-reader-path` at PR #143, after the
T11–T13 amendment. `git fetch` then `git rev-list --left-right --count
origin/main...HEAD` reports 0 behind / 16 ahead, and local `main` is level with
`origin/main`, so `main` has still not moved since the branch was cut and no
merge was needed before gathering evidence. Branch re-pushed; PR #143 refreshed.

#### Acceptance criteria

- **AC1 — FAIL (byte-identity, `.R` mode and R2 pass; the counted-class clause
  does not).** `data-raw/prose-profile.py` has two commits (`96b78b4` T1,
  `14e7dce` T8); `git diff 14e7dce -- data-raw/prose-profile.py` is 0 bytes and
  the blob hashes at `14e7dce`, at HEAD and in the worktree are all
  `751b7c07`, so the re-baseline run and the final run used the same bytes. The
  `72f9cc2` baseline was re-derived at review over the eight `vignettes/*.Rmd`
  blobs extracted from that commit: 744 fragments / 81 over 35 / 226 dashes / 11
  long parentheticals / 55 semicolons, the three in-scope files holding
  358 / 20 / 66 — reproducing the Scope table exactly. `SENTENCE_LIMIT` is 35,
  counted strictly greater. `strip_roxygen()` keeps `#'` lines and suppresses
  each `@examples` block until the next `#' @` tag. R1's amended proper-noun
  clause now holds: a six-site probe scored 4 of 6 dashes, excluding exactly
  `Spearman--Brown` and `10--20` while counting `sentence---And`, the closing
  `correlation—is`, and both halves of a spaced break — which is what the
  amended R1 and its explanatory sentences say. **What fails is R1's
  table-separator-row exclusion.** R1 excludes "markdown table separator rows";
  `RE_TABLE_RULE` (`data-raw/prose-profile.py:93`, `^\s*\|[\s:|-]*\|\s*$`)
  recognizes a row only when it carries a **leading and a trailing** `|`.
  Reproduced at review: a table whose separator row is `|--- |---` — a leading
  pipe, no trailing pipe, legal pandoc — scores 2 dash occurrences. The
  doctrine's own blind-spot paragraph does not cover this shape: it says the row
  "is recognized only when it starts with `|`", which the `|--- |---` row does.
  No file in `vignettes/` trips it (every separator row there carries both
  pipes), so AC2's zeros are undisturbed. See the Outcome below.
- **AC2 — pass.** Ruler re-run per file at review: `getting-started.Rmd` 0
  dashes, 0 over 35 (longest 32); `choosing-an-icc.Rmd` 0 dashes, 0 over 35
  (longest 35); `glossary.Rmd` 0 dashes, 1 over 35 (64 words). The one long
  sentence is body prose in the **Burch interval** entry. The clause
  `residual_template()` returns is 58 words counted by the ruler's own `words()`,
  is present verbatim in `glossary.Rmd` once wrapping is joined (matched by exact
  substring at review with the rendered `1.2963` / `100` cells in place), and
  64 − 58 = 6 ≤ 8.
- **AC3 — pass.** `cairn/doctrine/prose-style.md` exists (115 lines, 6,486 bytes,
  inside its own stated 120-line / 8,000-byte budget). Its R1–R6 block was
  compared byte-for-byte against Scope's after rewrapping: identical, R1's
  amended exclusion text included.
- **AC4 — pass.** `git diff 72f9cc2 -- <the three files>` is 33 hunks; the
  qualifier grep over added **and** removed lines matches 46 lines across 14
  hunks. Each of the 14 was read added-against-removed at review: all EQUAL
  domain, every match a dash, semicolon, or parenthesis converted to a sentence
  break with the quantified claim carried over. The T12 repairs are present and
  read at their original domain — `getting-started.Rmd`'s conjoined "barely
  disagree, and the ratings are highly reliable", and `choosing-an-icc.Rmd`'s
  restored appositive "a systematic difference between raters, one judge scoring
  consistently higher than another, as error".
- **AC5 — pass.** `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862.
  `devtools::check(document = FALSE, args = "--no-manual")` raw `Status: 1 NOTE`,
  0 errors / 0 warnings, duration 15m 50s; no `* checking …` line reports
  WARNING or ERROR, and vignettes re-built OK in 23s. The NOTE is the
  `tests/spelling.Rout` comparison and is pre-existing:
  `spelling::spell_check_package()` returns 31 words on this branch, the count
  recorded at `72f9cc2`, T7, T10 and T13. `devtools::document()` produced no diff
  (`git status` clean after it). `python3 data-raw/check-record-claims.py --live`
  exit 0, 6 claims re-derived, 0 failures.

#### Consistency gate

- `cairn_validate.py` exit 0 — 16 PASS, 7 advisory OK, 1 advisory WARN (M134's
  13 tasks against the 10-task split tripwire). `coverage complete` and
  `binding criteria` both pass.
- `cairn_impact.py` skipped: `Principles touched: —`, no DESIGN principle changed.
- Toolchain checks (`r-package` profile's `consistency-gate` slot):
  `devtools::document()` no diff; `NAMESPACE`, `man/` and `data/` untouched by
  the branch diff; `README.Rmd`/`README.md` untouched;
  `pkgdown::check_pkgdown()` "No problems found"; `NEWS.md` carries a
  Documentation entry for the pass with no milestone number in it; no new
  top-level file (`data-raw/` already carries `^data-raw$` in `.Rbuildignore`);
  `devtools::check()` as recorded under AC5.

#### Independent review

Diff touches executable surface (`data-raw/prose-profile.py`) at a user-facing
tier, so the full three-lens fan-out ran again, each lens fresh-context and none
having authored the work.

**[S] blame-history — no findings.** Traced the branch's modified lines through
`git log`/`git blame`. The Burch/`"searle"` width claims built up over M115–M118
survive verbatim in `glossary.Rmd` — every figure (0.3, 0.6, t(5), 100 subjects,
1.2963, 5 raters) and the scope clause "on the two grids this package has
measured that vary only the subject effect" — punctuation and wrapping only.
`choosing-an-icc.Rmd`'s `k_eff` = 3.27 harmonic-mean figure untouched. Ran
`test-doc-skew-caveat.R` (2344 pass / 0 fail) and `test-vignette-claims.R`
(246 pass / 0 fail) directly. Confirmed no recorded decision addresses dash or
punctuation style, so R1 contradicts nothing on record. One cosmetic note, no
action: an orphaned line break at `glossary.Rmd:82`.

**[S] prior-review record — no findings.** The
`gh api repos/jmgirard/intraclass/pulls/comments?per_page=1` probe returned `[]`,
so no thread walk was paid for; archived `## Review` sections (M115, M118, M124,
M126, M128, M129, M130, M132, M133) and `LESSONS.md` were the evidence base.
Cleared M130's pkgdown-anchor lesson (no period-bearing heading introduced),
M72/M128's universal-word lesson (AC4 is that lesson mechanized), M124's
`getting-started.Rmd` overclaiming pattern, M115's withdrawn `"burch"` claim, and
D-033's registry, whose second-pass gap T12 closed.

**[O] diff-bug — seven findings, ranked.** The lens re-derived the numbers rather
than trusting the work log, independently reproducing the baseline
(744 / 81 / 226 / 11 / 55; in-scope 358 / 20 / 66), AC2's 6 ≤ 8 arithmetic, the
byte-identity, the amended R1's behaviour on a ten-site probe, and `.R` mode's
`@examples` suppression.

1. **The ruler's own module docstring still specifies the pre-T8 exclusion
   rule.** Verbatim: "`data-raw/prose-profile.py:41-43`: 'dashes flanked with no
   space by word characters whose right-hand side begins with a capital
   (proper-noun joins such as `Spearman--Brown`).' The code at line 240 requires
   the **left** word capitalized too, and T11 restated R1 in `prose-style.md` to
   match. The docstring was never touched. Under the docstring's rule,
   `break---And` is excluded; the code counts it."
   **Verified at review** by reading both records. AC1 binds the ruler's
   behaviour, which is correct, so this is not a criterion failure.
   **Disposition: fix in the return stint.**
2. **The docstring also states the wrong `.Rmd` strip order.** Verbatim:
   "`data-raw/prose-profile.py:24-26`: '`.Rmd` mode strips, in order: the YAML
   front matter, fenced code chunks, HTML comments, …'. `strip_rmd()` applies
   `RE_HTML_COMMENT` at line 113, before the fence loop at 116-121. Second-pass
   finding 9 flagged this order mismatch; T11 corrected `prose-style.md` to
   comments-before-fences but left the script's docstring, so the two records now
   disagree in the opposite direction."
   **Verified at review** by reading. **Disposition: fix in the return stint.**
3. **The doctrine's separator-row blind spot understates the ruler's actual
   gap.** Verbatim: "`cairn/doctrine/prose-style.md:75`: 'a table separator row
   is recognized only when it starts with `|`, so a pandoc-legal `---- | ----`
   row scores as dashes.' `RE_TABLE_RULE` also requires a **trailing** `|`. A
   table whose separator row is `|---|---` (leading pipe, no trailing pipe —
   legal pandoc) scores 2 dash occurrences."
   **Verified at review** on an independent probe (`|--- |---`, 2 dashes
   counted), and every separator row in `vignettes/` confirmed to carry both
   pipes. **Disposition: the defect return below.**
4. **`cairn/DESIGN.md:102` now asserts something false about `prose-style.md`.**
   Verbatim: "The registry line reads '**Doctrine modules** (`cairn/doctrine/`,
   graduated lesson families — D-033):' and T12 added `prose-style.md` to it.
   D-033 defines `cairn/doctrine/` as the home for 'transferable craft
   **graduated whole from `cairn/LESSONS.md`**'; `prose-style.md` was authored
   fresh at T2, and `cairn/LESSONS.md:14` (the M72/M128 prose-widening family,
   the closest lineage, covering R6 only) is still live in LESSONS.md rather than
   graduated out. The T12 edit converts second-pass finding 10 from an omission
   into an inaccurate statement in DESIGN.md."
   **Verified at review** against `DECISIONS.md:1483-1487` and `LESSONS.md:14`.
   **Disposition: maintainer's at re-review.**
5. **The doctrine states an absolute that the milestone introducing it does not
   meet.** Verbatim: "`cairn/doctrine/prose-style.md:40-41`: 'R1 and R2 are
   gated: `data-raw/prose-profile.py` counts them, and a pass that claims to have
   applied them reports zero.' M134 applied the pass and `glossary.Rmd` reports 1
   sentence over 35 words. The page carries no exemption for a clause pinned
   verbatim by a test that admits no split — the case AC2 was amended for and
   that the milestone's `## Decisions` section records. M135/M136 will inherit
   the unqualified wording."
   **Verified at review** — the ruler reports 1 over-35 in `glossary.Rmd` at
   HEAD. **Disposition: maintainer's at re-review.**
6. **Re-wrapping left orphan fragments (cosmetic, no rendered effect).**
   Verbatim: "`vignettes/choosing-an-icc.Rmd:217` ('a `cluster` column' alone on
   a line), `vignettes/getting-started.Rmd:41`, `vignettes/glossary.Rmd:195` and
   `:290`. Long-line counts are fine (0 / 1 / 5 against 0 / 1 / 8 at baseline),
   but several splits left two- and three-word lines mid-paragraph."
   The `[S]` blame lens independently flagged `glossary.Rmd:82`.
   **Disposition: fix in the return stint.**
7. **Coverage block is one revision behind the task list.** Verbatim: "Coverage
   maps AC1 → T1 only, though T8 (ruler repair + re-baseline) and T11 (R1
   restatement) both discharge AC1, and T11 also discharges AC3. Tracking-only."
   **Verified at review.** `cairn_validate`'s mechanical `coverage complete`
   check still passes (each AC maps to ≥1 existing task).
   **Disposition: Coverage amendment in the return stint.**

The lens re-confirmed that second-pass findings 6, 7, 8, 9 and 10 are unchanged
at HEAD; 6, 7 and 9 are carried by the ROADMAP candidate row, 8 and 10 are not.
It explicitly cleared the R6 repairs of T9 and T12 at HEAD, the Burch passage,
the `## In short` anchor, the four glossary heading swaps, and the NEWS entry as
now worded.

#### Outcome

**Returned to `in-progress` under the return floor — defect return 2.**

Finding 3 demonstrates AC1's first clause failing inside the domain of the
procedure AC1 names: R1 excludes "markdown table separator rows" and the ruler
counts the dashes in one whose trailing `|` is absent. This is a **defect**
return, not an amendment return. The widening test does not fire: the repair
available is a procedure change — `RE_TABLE_RULE` recognizing a separator row
without requiring the trailing pipe — not the widening of an author-recalled
enumeration. Adding `|--- |---` to the doctrine's four-item blind-spot list
*would* be that widening, which is why it is not the repair. Fixing the regex
changes the ruler's bytes and so restarts the frozen baseline under
`prose-style.md`'s own closing rule, exactly as T8 did; the corrected ruler may
also move the eight-file `72f9cc2` figures, and the three in-scope files must be
re-measured after it.

The amendment-return count on AC1 stays at 1. The defect-return count is now 2;
the thrash rule's threshold (a) is 3 and has not been reached.

**Thrash trigger (b) fires.** AC1 has now failed at three consecutive reviews,
each by a new mechanism of the same shape — a clause of R1's exclusion list where
the ruler's decision and the doctrine's text diverge (round 1: the proper-noun
join too broad; round 2: the proper-noun clause undecidable; round 3: the
table-separator clause too narrow). Re-cutting around the same predicate buys the
next clause, not a fix. The plan gate recorded no alternative for AC1's shape, so
the remedy under (b) is an offered `/milestone-brief` escalation — offered per
instance, never automatic. The ROADMAP candidate row already names the
diagnosis in the maintainer's own terms: "M134's AC1 binding the ruler rather
than the prose".

Findings 1, 2, 6 and 7 carry no status change and are directed into the return
stint; findings 4 and 5 are the maintainer's at re-review. AC2, AC3, AC4 and AC5
all verified at HEAD, both `[S]` lenses clean, the consistency gate green.

### Fourth pass

Reviewed 2026-08-23 on `m134-vignette-prose-reader-path` at PR #143, after the
T14–T16 repairs. `git fetch` then `git rev-list --left-right --count
origin/main...HEAD` reports 0 behind / 20 ahead, and local `main` is level with
`origin/main`, so `main` has still not moved since the branch was cut and no
merge was needed before gathering evidence. Branch re-pushed; PR #143 refreshed.

#### Acceptance criteria

- **AC1 — pass.** `data-raw/prose-profile.py` has three commits (`96b78b4` T1,
  `14e7dce` T8, `b092c3a` T14); the blob at HEAD and the worktree file both hash
  to `8a2a4cee`, so the T14 re-baseline run and the final run used the same
  bytes. The `72f9cc2` baseline was re-derived at review with those bytes over
  the eight `vignettes/*.Rmd` blobs extracted from that commit: 744 fragments /
  81 over 35 / 226 dashes / 11 long parentheticals / 55 semicolons, the three
  in-scope files holding 358 / 20 / 66 — reproducing the Scope table exactly.
  Read against `cairn/doctrine/prose-style.md` and probed rather than read:
  a probe file carrying `sentence---And`, `An ICC—Intraclass correlation—is`,
  `Spearman--Brown`, `McGraw--Wong`, `10--20`, a spaced ` --- ` break twice, and
  four separator-row shapes (`|--- |---`, `|---|`, `--- | ---`, `| :---: | ---: |`)
  scored 4 dashes — exactly the class R1 defines: the lowercase-left unspaced
  break, the closing `correlation—is`, and both spaced breaks, with every
  proper-noun join, the numeric range, and all four separator rows excluded. The
  T14 repair closes the leading- and trailing-pipe-optional gap the third pass
  returned on. `SENTENCE_LIMIT` is 35, counted strictly greater. `.R` mode probed
  independently: a file with roxygen prose in the title, `@param` and `@return`
  and a dash inside `@examples` plus two plain `#` comments scored 3 dashes —
  `#'` lines outside `@examples` only.
- **AC2 — pass.** Ruler re-run per file at review: `getting-started.Rmd` 0
  dashes, 0 over 35 (longest 32); `choosing-an-icc.Rmd` 0 dashes, 0 over 35
  (longest 35); `glossary.Rmd` 0 dashes, 1 over 35 (64 words). The one long
  sentence is body prose in the **Burch interval** entry. The clause
  `residual_template()` returns was reconstructed from
  `tests/testthat/test-doc-skew-caveat.R:2265-2283` with the rendered `1.2963`
  and `100` cells, counts 58 words by the ruler's own `words()`, and is present
  verbatim both in the reported sentence and in `glossary.Rmd`'s
  whitespace-joined text; 64 − 58 = 6 ≤ 8. `residual_expected_runs` requires the
  clause in `glossary.Rmd` and `test-doc-skew-caveat.R` passes, so the pin holds.
- **AC3 — pass.** `cairn/doctrine/prose-style.md` exists (118 lines, 6,752
  bytes, inside its own stated 120-line / 8,000-byte budget). Its R1–R6 block
  was compared against Scope's after whitespace-collapsing both: byte-identical.
- **AC4 — pass.** `git diff 72f9cc2 -- <the three files>` is 32 hunks; the
  qualifier grep over added **and** removed lines matches 52 lines across 16
  hunks (up from 46 / 14 at the third pass — T15's reflows moved hunk
  boundaries). Each of the 16 was read added-against-removed at review: all
  EQUAL domain, every match a dash, semicolon, or parenthesis converted to a
  sentence break with the quantified claim carried over. The scope-critical
  strings survive verbatim: `glossary.Rmd`'s "on the two grids this package has
  measured that vary only the subject effect", `getting-started.Rmd`'s "the
  default interval does not rely on a textbook formula that misbehaves when a
  variance is near zero", "reports every defined formulation", and
  `choosing-an-icc.Rmd`'s restored appositive.
- **AC5 — pass.** `devtools::test()` FAIL 0 | WARN 3 | SKIP 2 | PASS 8862, the
  same figures as T7, T10, T13 and T16. `devtools::check(document = FALSE,
  args = "--no-manual")` raw `Status: 1 NOTE`, 0 errors / 0 warnings, duration
  21m 51s; zero `* checking …` lines report WARNING or ERROR, and vignettes
  re-built OK in 32s. The NOTE is the `tests/spelling.Rout` comparison and is
  pre-existing: `spelling::spell_check_package()` returns 31 words on this
  branch, the count recorded at `72f9cc2`, T7, T10, T13 and T16, every one a
  proper name (Chinn, Davison, Gulliford, Liu, Ohyama, Okabe, Searle,
  Ukoumunne, Xiao), an en-GB spelling, or a technical term absent from
  `inst/WORDLIST`; none is a word this milestone introduced.
  `devtools::document()` produced no diff (`git status` clean after it).
  `python3 data-raw/check-record-claims.py --live` exit 0, 6 claims re-derived,
  0 failures.

#### Consistency gate

- `cairn_validate.py` exit 0 — 16 PASS, 6 advisory OK, 1 advisory WARN (M134's
  16 tasks against the 10-task split tripwire). `coverage complete`,
  `binding criteria` and `scaffold present` all pass.
- `cairn_impact.py` skipped: `Principles touched: —`, no DESIGN principle changed.
- Toolchain checks (`r-package` profile's `consistency-gate` slot):
  `devtools::document()` no diff; `NAMESPACE`, `man/` and `data/` untouched by
  the branch diff; `README.Rmd`/`README.md` untouched (only `data-raw/README.md`
  changed); `pkgdown::check_pkgdown()` "No problems found"; `NEWS.md` carries a
  Documentation entry for the pass with no milestone number in it; no new
  top-level file (`data-raw/` and `cairn/` both carry `.Rbuildignore` entries);
  `devtools::check()` as recorded under AC5.

#### Independent review

Diff touches executable surface (`data-raw/prose-profile.py`) at a user-facing
tier, so the full three-lens fan-out ran again, each lens fresh-context and none
having authored the work.

**[S] blame-history — no findings.** Traced the branch's 24 commits and the
modified lines through `git log`/`git blame`. The Burch-interval paragraph's
figures (0.3, 0.6, t(5), 100 subjects, 1.2963, 5 raters) are byte-identical to
`main`; the M72/M128 widening family's own failure mode occurred mid-branch and
was repaired at T6 before HEAD. Re-derived pandoc anchor ids for the four
re-punctuated glossary headings before and after: byte-identical, and the
referrers in the two untouched vignettes still resolve. Ran
`test-doc-skew-caveat.R` (2344 pass / 0 fail) and `test-vignette-claims.R`
(246 pass / 0 fail) directly, plus `check-record-claims.py` and
`check-mpl-doc-claims.py`, all clean. Confirmed D-034's account of the D-033 gap
is accurate against `LESSONS.md:14`, and that no R source, test, `DESCRIPTION`
or `NAMESPACE` file is touched.

**[S] prior-review record — no findings.** The
`gh api repos/jmgirard/intraclass/pulls/comments?per_page=1` probe returned `[]`,
so no thread walk was paid for; the three prior `## Review` passes in this file
and `cairn/milestones/archive/` were the evidence base. Every finding the three
prior passes directed into a return stint was checked at HEAD and found fixed:
third-pass findings 1, 2, 3, 6, 7, second-pass finding 6, first-pass finding 9.
Third-pass findings 4 and 5 are resolved by D-034 and the doctrine's
pinned-clause exemption. Nothing reintroduced or contradicted.

**[O] diff-bug — seven findings, ranked.** The lens re-derived every number
rather than trusting the work log, independently reproducing the `72f9cc2`
baseline (744 / 81 / 226 / 11 / 55; in-scope 358 / 20 / 66), AC2's 6 ≤ 8
arithmetic, the byte-identity, the amended R1's behaviour on an eight-site probe,
`.R` mode's `@examples` suppression, the pkgdown anchor ids, and T15's
whitespace-only claim.

1. **The T14 separator-row repair is one class short: a pandoc simple-table or
   grid-table separator row still scores as dash-as-punctuation.** Verbatim:
   "`RE_TABLE_RULE = re.compile(r\"^(?=[^|]*\\|)(?=[^-]*-)[\\s:|-]+$\")` — the
   `(?=[^|]*\\|)` lookahead requires at least one `|`. R1
   (`cairn/doctrine/prose-style.md:22`, byte-identical in Scope) excludes
   'markdown table separator rows' without qualification, and pandoc's
   `simple_tables`/`multiline_tables` separator carries no pipe at all while
   `grid_tables` uses `+---+---+`."
   **Reproduced at review** on an independent probe: a pandoc simple table, a
   grid table and a setext underline together score 30 dash occurrences; all
   four pipe-table shapes (leading-only, trailing-only, both, aligned) score 0,
   so the T14 fix does hold for the shape it was cut for.
   Reachability nil today: `grep -rnE '^\s*\+[-=+]+\+\s*$'` over `vignettes/`,
   `R/` and `README.Rmd` returns nothing, and the only bare dash-run lines in
   `vignettes/` are the eight files' YAML closing delimiters, which `RE_YAML`
   strips. **AC2's zeros are undisturbed.**
   The counter-reading the gate should weigh, in the lens's own words: "the
   doctrine's *ruler-behaviour* section (`prose-style.md:61-64`) does describe
   the rule as 'carrying at least one of each of `|` and `-`', so the page is
   internally self-consistent if R1's bare phrase is read as scoped to pipe
   tables — but AC1 names R1's counted class, and R1 says only 'markdown table
   separator rows'." **Disposition: the amendment-return stop below.**
2. **The doctrine's blind-spot paragraph asserts "Four boundaries" and
   enumerates four; at least two more exist.** Verbatim: missing are "(a) the
   simple/grid separator rows of finding 1; (b) a **setext heading underline**."
   **Reproduced at review** — `Setext heading` over `--------------` scores 5
   dash occurrences, and because `RE_HEADING` is ATX-only the heading is not
   fragmented as a heading, so heading and rule merge into one fragment.
   `cairn/ROADMAP.md`'s candidate row repeats the same four-item list and
   inherits the understatement. **Disposition: maintainer's at the gate.**
3. **A 108-character unwrapped line in `cairn/doctrine/prose-style.md:45`,** in
   a file whose every other line wraps at ~79. Verbatim: "zero on either has no
   non-arbitrary threshold and would fight readability. R3 and R6 are not
   counted at all." **Reproduced at review** — `awk 'length>88'` returns this
   line and no other. **Disposition: maintainer's at the gate.**
4. **The T9 insert falsified a sentence one paragraph above it in
   `data-raw/README.md:44-46`.** Verbatim: "the rest of this README documents
   the **brms/Stan offline verification strategy**, which does" — `## The prose
   ruler` was inserted immediately after that sentence, so "the rest of this
   README" is no longer only the brms strategy. **Reproduced at review** by
   reading `data-raw/README.md:40-62`. **Disposition: maintainer's at the gate.**
5. **R6 note, `vignettes/glossary.Rmd:45` and `:47` — "margin" became "width
   margin" at both sites.** The lens reads the domain as EQUAL ("the current
   wording is non-directional and the paragraph is explicitly about width"), and
   reports it only because a prior pass already repaired this sentence once.
   Independently read at review against the removed text: EQUAL.
   **Disposition: reject at triage, no defect.**
6. **R6 note, `vignettes/getting-started.Rmd:150` — subject narrowed from "the
   interval `icc()` reports" to "the default interval".** The lens flags it for
   completeness and identifies it as the deliberate T9 repair of first-pass
   finding 7. **Disposition: reject at triage, the repair the gate directed.**
7. **`RE_DASH` counts occurrences inside a dash run, where R1 speaks of "a
   standalone `--`".** Verbatim: a bare `----` scores 2. "Only reachable outside
   stripped regions, and it is what makes findings 1 and 2 produce inflated
   counts rather than 1 each. No criterion affected."
   **Disposition: maintainer's at the gate.**

The lens explicitly cleared, so none is re-raised: AC1's byte-identity, the
`72f9cc2` baseline, AC2 at HEAD and the 58-word pinned clause, R1's amended
proper-noun clause against an eight-site probe, R2's sentence rule, `.R` mode,
the ruler docstring / doctrine / Scope agreement, the doctrine's budget, the
pkgdown anchors, T15's whitespace-only claim, the full AC4 word-diff sweep,
line widths, `data-raw/README.md`'s claim pins, the doc pins, D-034 and
`DESIGN.md`'s registry line, the NEWS entry as now worded, and the absence of
any conflict with D-021, D-029, D-032, D-033 or a DESIGN principle.

#### Outcome

**Amendment return 2 on AC1 — and the second-occurrence stop fires, so no
further round is convened and the disposition goes to the user.**

Finding 1 demonstrates AC1's first clause failing inside the domain of the
procedure AC1 names. AC1 promises the ruler "implements R1's counted class …
as `cairn/doctrine/prose-style.md` defines them", and `prose-style.md` defines
that class two incompatible ways: R1 (line 22, byte-identical in Scope) excludes
"markdown table separator rows" unqualified, while the ruler-behaviour section
(lines 61–64) defines the recognized row as one "carrying at least one of each
of `|` and `-`". The code implements the second exactly. Since the criterion
cannot be satisfied against both readings, the promise is what is wrong, not the
implementation — and under the never-reinterpret rule the passing reading is not
available to review.

It routes as an **amendment** return, not a defect return, under the widening
test. No shape-based procedure separates a pandoc simple-table rule from a
setext heading underline or a `---` thematic break, both of which the doctrine
deliberately *counts*; the repair available is either to restate R1's table
clause in the terms the instrument can decide — T11's move, one clause down —
or to widen the doctrine's blind-spot enumeration, whose membership (which
markdown and pandoc table syntaxes exist) is fixed by author recall rather than
decided by a procedure over the domain. Third-pass finding 3 routed the other
way precisely because a clean procedure repair *did* exist there; here it does
not.

This is amendment return **2** naming AC1 on this milestone. Per the
amendment-return second-occurrence rule, review stops: no further amendment
round is convened, AC1 is left as it stands, and the disposition is the
maintainer's. The defect-return count stays at **2** (threshold (a) is 3 and is
not reached); thrash trigger (b) remains standing from the third pass — AC1 has
now diverged from the ruler at four consecutive reviews, each by a new clause of
R1's exclusion list.

Everything else passes: AC2, AC3, AC4 and AC5 all verified at HEAD with fresh
evidence, both `[S]` lenses clean, and the consistency gate green. No finding at
this pass disturbs AC2's zeros or any number the vignettes state; the ruler's
uncovered shapes are unreachable in every file in this repo today.

#### Gate triage

Presented at the gate 2026-08-23 with every finding verbatim. The maintainer
took the merge, and directed findings 2, 3 and 4 fixed on the branch first.

- **Finding 1 — accepted, recorded.** The merge proceeds with AC1's gap on
  record: the divergence is between R1's one-line shorthand and the doctrine's
  own precise ruler definition, which the code implements exactly, and no file
  in this repo reaches the uncovered shapes. The offered `/milestone-brief`
  escalation and a fifth amendment round were both declined.
- **Finding 2 — fixed.** The doctrine's blind-spot paragraph now names **six**
  boundaries, adding the setext heading underline and the pandoc simple- or
  grid-table separator row.
- **Finding 3 — fixed.** `prose-style.md:45` rewrapped; `awk 'length>88'`
  returns nothing over the file.
- **Finding 4 — fixed.** `data-raw/README.md` now reads "the **brms/Stan
  offline verification strategy** below does", so the sentence no longer claims
  the rest of the file.
- **Findings 5 and 6 — rejected.** Both are R6 notes the lens itself read as
  EQUAL domain or as the repair a prior gate directed; re-read at review against
  the removed text and confirmed.
- **Finding 7 — follow-up.** `RE_DASH` counting each occurrence inside a dash
  run goes to the existing ROADMAP candidate row with the ruler hardening.

Re-verified after the fixes: `cairn/doctrine/prose-style.md` is 119 lines /
6,900 bytes, back inside its stated 120-line / 8,000-byte budget after
compressing four paragraphs outside the R1–R6 block; AC3's byte-identity with
Scope re-checked and holds; the ruler still reports 0 / 0 / 0 dashes and
0 / 0 / 1 sentences over 35 on the three files; `check-record-claims.py --live`
exit 0; `test-doc-skew-caveat.R` + `test-vignette-claims.R` FAIL 0 | PASS 2752.
The fixes touch markdown only — no R source, no vignette — so AC5's `test()` and
`check()` results stand. `cairn_validate` exit 0; `cairn/ROADMAP.md` back to
23,931 bytes after the candidate row was rewritten and the hygiene stamp
replaced.
