# M134: Vignette prose pass — the reader path, and the house style standard

- **Status:** in-progress
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
  table rules, dashes flanked by digits (page and numeric ranges), dashes
  joining capitalized proper nouns (`Spearman--Brown`).
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

- [ ] AC1 `data-raw/prose-profile.py` is committed, implements R1's counted
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

- AC1 → T1
- AC2 → T1, T3, T4, T5
- AC3 → T2
- AC4 → T6
- AC5 → T7

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

